#!/usr/bin/env bash
# spec-resume-scheduler.sh — one-shot scheduler backend for parked resume units.
#
# Usage:
#   spec-resume-scheduler.sh add <unit-id> <run-at-epoch> <state-root>
#   spec-resume-scheduler.sh remove <unit-id>
#   spec-resume-scheduler.sh list
#
# The resume CLI owns unit state. This script owns only the OS scheduler entry,
# keeping launchd and cron behind one interface that callers can replace.

set -euo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL_PREFIX="com.sdd-kit.resume."
MARKER_PREFIX="# sdd-kit-resume:"

usage() {
  sed -n '3,8p' "$0" >&2
  exit 2
}

valid_unit_id() {
  [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
}

valid_epoch() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

shell_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

xml_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&apos;/g"
}

round_up_minute() {
  echo $(( ($1 + 59) / 60 * 60 ))
}

launch_agents_dir() {
  printf '%s\n' "${SDD_RESUME_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
}

plist_path() {
  printf '%s/%s%s.plist\n' "$(launch_agents_dir)" "$LABEL_PREFIX" "$1"
}

launchd_calendar() { # <rounded epoch>; output minute hour day month year
  date -r "$1" '+%M %H %d %m %Y'
}

add_launchd() { # <unit-id> <run-at-epoch> <state-root>
  local unit_id="$1" run_at="$2" state_root="$3" rounded minute hour day month year dir plist tmp uid
  rounded="$(round_up_minute "$run_at")"
  read -r minute hour day month year <<EOF
$(launchd_calendar "$rounded")
EOF
  dir="$(launch_agents_dir)"
  plist="$(plist_path "$unit_id")"
  mkdir -p "$dir"
  tmp="$(mktemp "$dir/.${LABEL_PREFIX}${unit_id}.XXXXXX")" || exit 1
  cat > "$tmp" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$(xml_escape "$LABEL_PREFIX$unit_id")</string>
  <key>ProgramArguments</key>
  <array>
    <string>$(xml_escape "$HUB_DIR/scripts/spec-resume.sh")</string>
    <string>run</string>
    <string>$(xml_escape "$unit_id")</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>SDD_RESUME_ROOT</key>
    <string>$(xml_escape "$state_root")</string>
  </dict>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Minute</key><integer>$((10#$minute))</integer>
    <key>Hour</key><integer>$((10#$hour))</integer>
    <key>Day</key><integer>$((10#$day))</integer>
    <key>Month</key><integer>$((10#$month))</integer>
    <key>Year</key><integer>$((10#$year))</integer>
  </dict>
</dict>
</plist>
EOF
  mv "$tmp" "$plist"

  uid="$(id -u)"
  launchctl bootout "gui/$uid" "$plist" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$uid" "$plist"
}

remove_launchd() { # <unit-id>
  local unit_id="$1" plist uid
  plist="$(plist_path "$unit_id")"
  uid="$(id -u)"
  launchctl bootout "gui/$uid" "$plist" >/dev/null 2>&1 || true
  rm -f "$plist"
}

list_launchd() {
  launchctl list 2>/dev/null \
    | awk -v prefix="$LABEL_PREFIX" '$3 ~ ("^" prefix) { sub("^" prefix, "", $3); print $3 }' \
    | sort -u
}

update_cron() ( # unit-id [epoch state-root]
  local unit_id="$1" base lock tmp rc command tries=0 marker="$MARKER_PREFIX$1"
  umask 077
  base="$HOME/.local/state/sdd-kit"
  mkdir -p "$base" || return 1
  lock="$base/cron-write.lock"
  until mkdir "$lock" 2>/dev/null; do
    (( tries < 50 )) || { echo "cron update busy: $lock" >&2; return 1; }
    tries=$((tries+1)); sleep 0.1
  done
  trap 'rm -rf "$lock"' EXIT
  trap 'exit 1' HUP INT TERM
  tmp="$lock/current"
  if LC_ALL=C crontab -l > "$tmp" 2>"$lock/error"; then :
  else
    rc=$?
    if [[ "$rc" != 1 ]] || [[ ! "$(< "$lock/error")" =~ ^no\ crontab\ for\ [^[:space:]]+$ ]]; then
      cat "$lock/error" >&2; return 1
    fi
    : > "$tmp"
  fi
  awk -v marker="$marker" 'length($0)<length(marker) || substr($0,length($0)-length(marker)+1)!=marker' "$tmp" > "$lock/new" || return 1
  if [[ $# == 3 ]]; then
    command="now=\$(date +\%s); [ \"\$now\" -ge $2 ] && exec env SDD_RESUME_ROOT=$(shell_quote "$3") $(shell_quote "$HUB_DIR/scripts/spec-resume.sh") run $(shell_quote "$unit_id")"
    printf '* * * * * /bin/bash -c %s %s\n' "$(shell_quote "$command")" "$marker" >> "$lock/new" || return 1
  fi
  cmp -s "$tmp" "$lock/new" || crontab - < "$lock/new"
)

list_cron() {
  (crontab -l 2>/dev/null || true) \
    | sed -n "s/.*$MARKER_PREFIX\\([A-Za-z0-9._-]*\\).*/\\1/p" \
    | sort -u
}

add() {
  local unit_id="$1" run_at="$2" state_root="$3"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    add_launchd "$unit_id" "$run_at" "$state_root"
  else
    update_cron "$unit_id" "$run_at" "$state_root"
  fi
}

remove() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    remove_launchd "$1"
  else
    update_cron "$1"
  fi
}

case "${1:-}" in
  add)
    [[ $# -eq 4 ]] && valid_unit_id "$2" && valid_epoch "$3" && [[ -n "$4" ]] || usage
    add "$2" "$3" "$4"
    ;;
  remove)
    [[ $# -eq 2 ]] && valid_unit_id "$2" || usage
    remove "$2"
    ;;
  list)
    [[ $# -eq 1 ]] || usage
    if [[ "$(uname -s)" == "Darwin" ]]; then list_launchd; else list_cron; fi
    ;;
  *) usage ;;
esac
