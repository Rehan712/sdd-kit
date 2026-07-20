#!/usr/bin/env bash
# spec-resume.sh — persist and replay one bounded, machine-local resume unit.
#
# Usage:
#   spec-resume.sh park --spec <live-spec> --role <role> --kind <kind> \
#     [--reset <epoch>] [--backoff-minutes <n>] -- <original argv...>
#   spec-resume.sh run <unit-id>
#   spec-resume.sh list [--tsv]
#   spec-resume.sh cancel <unit-id>

set -euo pipefail
umask 077

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_ROOT="${SDD_RESUME_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/sdd-kit/resume}"
SCHEDULER="${SDD_RESUME_SCHEDULER:-$HUB_DIR/scripts/spec-resume-scheduler.sh}"
STATUS="$HUB_DIR/scripts/spec-status.sh"
MAX_RETRIES=3

usage() {
  sed -n '3,9p' "$0" >&2
  exit 2
}

valid_unit_id() { [[ "$1" =~ ^[a-f0-9]{64}$ ]]; }
valid_epoch() { [[ "$1" =~ ^[0-9]+$ ]]; }
valid_text() { [[ "$1" != *$'\t'* && "$1" != *$'\n'* && "$1" != *$'\r'* ]]; }

require_scheduler() {
  [[ -x "$SCHEDULER" ]] || {
    echo "resume scheduler is not executable: $SCHEDULER" >&2
    exit 1
  }
}

hash_unit() { # <cwd> <argv...>
  if command -v shasum >/dev/null 2>&1; then
    printf '%s\0' "$@" | shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s\0' "$@" | sha256sum | awk '{print $1}'
  else
    # cksum is only a last-resort identifier on hosts without SHA-256 tooling.
    printf '%s\0' "$@" | cksum | awk '{printf "%064x\n", $1}'
  fi
}

unit_dir() { printf '%s/%s\n' "$STATE_ROOT" "$1"; }
lock_dir() { printf '%s/.%s.lock\n' "$STATE_ROOT" "$1"; }

# The EXIT trap is the structural guarantee that no failure path — including a
# set -e escape between acquire and release — can leave a stale lock behind.
HELD_LOCK=""
release_held_lock() {
  [[ -z "$HELD_LOCK" ]] || rmdir "$(lock_dir "$HELD_LOCK")" 2>/dev/null || true
  HELD_LOCK=""
}
trap release_held_lock EXIT

acquire_lock() { # <unit-id>
  local lock attempts=0
  lock="$(lock_dir "$1")"
  mkdir -p "$STATE_ROOT"
  while ! mkdir "$lock" 2>/dev/null; do
    attempts=$((attempts + 1))
    if (( attempts >= 50 )); then
      echo "resume unit is busy: $1" >&2
      return 1
    fi
    sleep 0.1
  done
  HELD_LOCK="$1"
}

release_lock() {
  rmdir "$(lock_dir "$1")" 2>/dev/null || true
  [[ "$HELD_LOCK" != "$1" ]] || HELD_LOCK=""
}

metadata_reset() {
  U_STATE=""; U_LIVE_SPEC=""; U_ROLE=""; U_KIND=""; U_RESET_EPOCH=""
  U_RUN_AT_EPOCH=""; U_RETRY_COUNT=""; U_MAX_RETRIES=""; U_LAST_EXIT=""
  U_CREATED_AT=""; U_UPDATED_AT=""
}

load_metadata() { # <unit-dir>
  local key value
  metadata_reset
  [[ -f "$1/unit.tsv" ]] || return 1
  while IFS=$'\t' read -r key value; do
    case "$key" in
      state) U_STATE="$value" ;;
      live_spec) U_LIVE_SPEC="$value" ;;
      role) U_ROLE="$value" ;;
      kind) U_KIND="$value" ;;
      reset_epoch) U_RESET_EPOCH="$value" ;;
      run_at_epoch) U_RUN_AT_EPOCH="$value" ;;
      retry_count) U_RETRY_COUNT="$value" ;;
      max_retries) U_MAX_RETRIES="$value" ;;
      last_exit) U_LAST_EXIT="$value" ;;
      created_at) U_CREATED_AT="$value" ;;
      updated_at) U_UPDATED_AT="$value" ;;
    esac
  done < "$1/unit.tsv"
  [[ "$U_STATE" =~ ^(pending|running|failed)$ ]] \
    && valid_epoch "$U_RUN_AT_EPOCH" \
    && [[ "$U_RETRY_COUNT" =~ ^[0-9]+$ ]] \
    && [[ "$U_MAX_RETRIES" =~ ^[0-9]+$ ]]
}

write_metadata() { # <unit-dir>
  local dir="$1" tmp
  tmp="$(mktemp "$dir/.unit.tsv.XXXXXX")" || return 1
  {
    printf 'state\t%s\n' "$U_STATE"
    printf 'live_spec\t%s\n' "$U_LIVE_SPEC"
    printf 'role\t%s\n' "$U_ROLE"
    printf 'kind\t%s\n' "$U_KIND"
    printf 'reset_epoch\t%s\n' "$U_RESET_EPOCH"
    printf 'run_at_epoch\t%s\n' "$U_RUN_AT_EPOCH"
    printf 'retry_count\t%s\n' "$U_RETRY_COUNT"
    printf 'max_retries\t%s\n' "$U_MAX_RETRIES"
    printf 'last_exit\t%s\n' "$U_LAST_EXIT"
    printf 'created_at\t%s\n' "$U_CREATED_AT"
    printf 'updated_at\t%s\n' "$U_UPDATED_AT"
  } > "$tmp" && mv "$tmp" "$dir/unit.tsv"
}

status_event() { # <live-spec> <text>
  "$STATUS" append-decision "$1" "$2" >/dev/null 2>&1
}

jitter_for() { # <unit-id>
  local hex
  if [[ -n "${SDD_RESUME_JITTER_SECONDS:-}" ]]; then
    [[ "$SDD_RESUME_JITTER_SECONDS" =~ ^[0-9]+$ && "$SDD_RESUME_JITTER_SECONDS" -le 300 ]] || {
      echo "SDD_RESUME_JITTER_SECONDS must be an integer from 0 through 300" >&2
      return 1
    }
    printf '%s\n' "$SDD_RESUME_JITTER_SECONDS"
    return 0
  fi
  hex="${1:0:4}"
  printf '%s\n' "$((16#$hex % 301))"
}

park() {
  local live_spec="" role="" kind="" reset="" backoff=60 cwd unit_id dir now jitter run_at
  local argv=()
  while (( $# )); do
    case "$1" in
      --spec) shift; live_spec="${1:-}" ;;
      --role) shift; role="${1:-}" ;;
      --kind) shift; kind="${1:-}" ;;
      --reset) shift; reset="${1:-}" ;;
      --backoff-minutes) shift; backoff="${1:-}" ;;
      --) shift; argv=("$@"); break ;;
      *) usage ;;
    esac
    shift
  done
  [[ -n "$live_spec" && -n "$role" && -n "$kind" && ${#argv[@]} -gt 0 ]] || usage
  valid_text "$live_spec" && valid_text "$role" && valid_text "$kind" || {
    echo "resume metadata cannot contain tabs or newlines" >&2; exit 2;
  }
  [[ -z "$reset" ]] || valid_epoch "$reset" || usage
  [[ "$backoff" =~ ^[0-9]+$ && "$backoff" -ge 1 && "$backoff" -le 10080 ]] || usage
  [[ -d "$live_spec" ]] || { echo "not a live spec directory: $live_spec" >&2; exit 2; }
  require_scheduler

  cwd="$PWD"
  unit_id="$(hash_unit "$cwd" "${argv[@]}")"
  dir="$(unit_dir "$unit_id")"
  now="$(date +%s)"
  jitter="$(jitter_for "$unit_id")" || exit 2
  if [[ -n "$reset" ]]; then run_at=$((reset + jitter)); else run_at=$((now + backoff * 60 + jitter)); fi

  acquire_lock "$unit_id" || exit 1
  if [[ -d "$dir" ]]; then
    if ! load_metadata "$dir"; then
      release_lock "$unit_id"
      echo "invalid resume unit: $unit_id" >&2
      exit 1
    fi
    if [[ "$U_RETRY_COUNT" -ge "$U_MAX_RETRIES" ]]; then
      U_STATE="failed"; U_LAST_EXIT=7; U_UPDATED_AT="$now"
      write_metadata "$dir"
      release_lock "$unit_id"
      status_event "$U_LIVE_SPEC" "resume unit $unit_id failed after retry cap for $U_ROLE $U_KIND" || exit 1
      echo "resume unit retry cap reached: $unit_id" >&2
      exit 1
    fi
  else
    mkdir -p "$dir"
    U_RETRY_COUNT=0; U_MAX_RETRIES=$MAX_RETRIES; U_CREATED_AT="$now"
  fi

  U_STATE="pending"; U_LIVE_SPEC="$live_spec"; U_ROLE="$role"; U_KIND="$kind"
  U_RESET_EPOCH="$reset"; U_RUN_AT_EPOCH="$run_at"; U_LAST_EXIT=""; U_UPDATED_AT="$now"
  write_metadata "$dir"
  printf '%s\0' "${argv[@]}" > "$dir/argv.nul"
  printf '%s\0' "$cwd" > "$dir/cwd.nul"
  # Scheduler-fired replays run with the stock system PATH; the parking
  # shell's PATH is what resolves the provider CLIs, so it travels in the
  # unit payload (never the whole environment).
  printf '%s\0' "$PATH" > "$dir/path.nul"
  if ! "$SCHEDULER" add "$unit_id" "$run_at" "$STATE_ROOT"; then
    U_STATE="failed"; U_LAST_EXIT=1; U_UPDATED_AT="$(date +%s)"
    write_metadata "$dir"
    release_lock "$unit_id"
    exit 1
  fi
  release_lock "$unit_id"
  status_event "$live_spec" "parked resume unit $unit_id for $role $kind reset=${reset:-unknown} run_at=$run_at" || exit 1
  printf '%s\n' "$unit_id"
}

read_argv_file() { # <path>
  local value
  RESUME_ARGV=()
  while IFS= read -r -d '' value; do
    RESUME_ARGV+=("$value")
  done < "$1"
}

read_cwd_file() { # <path>
  local value
  RESUME_CWD=()
  while IFS= read -r -d '' value; do
    RESUME_CWD+=("$value")
  done < "$1"
}

read_path_file() { # <path>
  local value
  RESUME_PATH=()
  while IFS= read -r -d '' value; do
    RESUME_PATH+=("$value")
  done < "$1"
}

run_unit() {
  local unit_id="$1" dir now rc live_spec role kind
  valid_unit_id "$unit_id" || usage
  require_scheduler
  dir="$(unit_dir "$unit_id")"

  acquire_lock "$unit_id" || exit 1
  [[ -d "$dir" ]] && load_metadata "$dir" || {
    release_lock "$unit_id"; echo "no valid resume unit: $unit_id" >&2; exit 1;
  }
  [[ "$U_STATE" == "pending" ]] || {
    release_lock "$unit_id"; echo "resume unit is not pending: $unit_id" >&2; exit 1;
  }
  [[ -f "$dir/argv.nul" && -f "$dir/cwd.nul" && -f "$dir/path.nul" ]] || {
    release_lock "$unit_id"; echo "resume unit payload missing: $unit_id" >&2; exit 1;
  }
  if ! "$SCHEDULER" remove "$unit_id"; then
    release_lock "$unit_id"
    return 1
  fi
  U_STATE="running"; U_RETRY_COUNT=$((U_RETRY_COUNT + 1)); U_UPDATED_AT="$(date +%s)"
  write_metadata "$dir"
  release_lock "$unit_id"

  read_cwd_file "$dir/cwd.nul"
  read_argv_file "$dir/argv.nul"
  read_path_file "$dir/path.nul"
  [[ ${#RESUME_CWD[@]} -eq 1 && ${#RESUME_ARGV[@]} -gt 0 && ${#RESUME_PATH[@]} -eq 1 && -d "${RESUME_CWD[0]}" ]] || {
    acquire_lock "$unit_id" || exit 1
    load_metadata "$dir" && { U_STATE="failed"; U_LAST_EXIT=1; U_UPDATED_AT="$(date +%s)"; write_metadata "$dir"; }
    release_lock "$unit_id"
    echo "resume unit payload is invalid: $unit_id" >&2
    exit 1
  }

  if (cd "${RESUME_CWD[0]}" && export PATH="${RESUME_PATH[0]}" && "${RESUME_ARGV[@]}"); then rc=0; else rc=$?; fi

  acquire_lock "$unit_id" || exit 1
  if [[ ! -d "$dir" ]] || ! load_metadata "$dir"; then
    release_lock "$unit_id"
    return "$rc"
  fi
  now="$(date +%s)"
  if (( rc == 0 )); then
    live_spec="$U_LIVE_SPEC"; role="$U_ROLE"; kind="$U_KIND"
    rm -rf "$dir"
    release_lock "$unit_id"
    status_event "$live_spec" "resume unit $unit_id succeeded for $role $kind" || exit 1
    return 0
  fi
  if (( rc == 7 )) && [[ "$U_STATE" == "pending" ]]; then
    release_lock "$unit_id"
    return 7
  fi
  U_STATE="failed"; U_LAST_EXIT="$rc"; U_UPDATED_AT="$now"
  write_metadata "$dir"
  live_spec="$U_LIVE_SPEC"; role="$U_ROLE"; kind="$U_KIND"
  release_lock "$unit_id"
  status_event "$live_spec" "resume unit $unit_id failed exit=$rc for $role $kind" || exit 1
  return "$rc"
}

list_units() {
  local tsv="$1" dir unit_id
  [[ -d "$STATE_ROOT" ]] || return 0
  for dir in "$STATE_ROOT"/*; do
    [[ -d "$dir" ]] || continue
    unit_id="$(basename "$dir")"
    valid_unit_id "$unit_id" || continue
    load_metadata "$dir" || continue
    if (( tsv )); then
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$unit_id" "$U_STATE" "$U_RUN_AT_EPOCH" "$U_RETRY_COUNT" "$U_MAX_RETRIES" "$U_LIVE_SPEC"
    else
      printf '%s %s run_at=%s retries=%s/%s\n' "$unit_id" "$U_STATE" "$U_RUN_AT_EPOCH" "$U_RETRY_COUNT" "$U_MAX_RETRIES"
    fi
  done | sort
}

cancel() {
  local unit_id="$1" dir live_spec role kind
  valid_unit_id "$unit_id" || usage
  require_scheduler
  dir="$(unit_dir "$unit_id")"
  acquire_lock "$unit_id" || exit 1
  [[ -d "$dir" ]] && load_metadata "$dir" || {
    release_lock "$unit_id"; echo "no valid resume unit: $unit_id" >&2; exit 1;
  }
  live_spec="$U_LIVE_SPEC"; role="$U_ROLE"; kind="$U_KIND"
  if ! "$SCHEDULER" remove "$unit_id"; then
    release_lock "$unit_id"
    echo "scheduler removal failed; resume unit kept: $unit_id" >&2
    exit 1
  fi
  rm -rf "$dir"
  release_lock "$unit_id"
  status_event "$live_spec" "cancelled resume unit $unit_id for $role $kind" || exit 1
}

case "${1:-}" in
  park) shift; park "$@" ;;
  run) [[ $# -eq 2 ]] || usage; run_unit "$2" ;;
  list)
    [[ $# -eq 1 || ( $# -eq 2 && "$2" == "--tsv" ) ]] || usage
    list_units "$(( $# == 2 ))"
    ;;
  cancel) [[ $# -eq 2 ]] || usage; cancel "$2" ;;
  *) usage ;;
esac
