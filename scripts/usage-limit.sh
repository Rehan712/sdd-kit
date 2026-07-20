#!/usr/bin/env bash
# usage-limit.sh — classify known provider usage-limit captures.
#
# Usage: usage-limit.sh classify <claude|codex|copilot> <capture> [--now <epoch>]
# Output: limit<TAB><short|long|unknown><TAB><reset-epoch-or-empty><TAB><detector>
#         none (with exit 1 when no table row matches)

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PATTERNS="$HUB_DIR/scripts/usage-limit-patterns.tsv"

usage() {
  echo "usage: $(basename "$0") classify <claude|codex|copilot> <capture> [--now <epoch>]" >&2
  exit 2
}

epoch_today() { # <epoch> -> YYYY-MM-DD in the local timezone
  if [[ "$(uname)" == "Darwin" ]]; then
    date -r "$1" +%Y-%m-%d
  else
    date -d "@$1" +%Y-%m-%d
  fi
}

clock_epoch() { # <now> <clock>
  local now="$1" clock="$2" today candidate
  today="$(epoch_today "$now")" || return 1
  clock="$(printf '%s' "$clock" | tr -d ' .' | tr '[:lower:]' '[:upper:]')"
  clock="$(printf '%s' "$clock" | sed -E 's/^([0-9]{1,2})(AM|PM)$/\1:00:00\2/; s/^([0-9]{1,2}:[0-9]{2})(AM|PM)$/\1:00\2/')"
  if [[ "$(uname)" == "Darwin" ]]; then
    candidate="$(date -j -f '%Y-%m-%d %I:%M:%S%p' "$today $clock" +%s 2>/dev/null)" || return 1
  else
    candidate="$(date -d "$today $clock" +%s 2>/dev/null)" || return 1
  fi
  if (( candidate <= now )); then
    candidate=$((candidate + 86400))
  fi
  printf '%s\n' "$candidate"
}

datetime_epoch() { # <datetime>, intentionally conservative: invalid/past is empty
  local value="$1" candidate
  value="${value}:00"
  if [[ "$(uname)" == "Darwin" ]]; then
    candidate="$(date -j -f '%Y-%m-%d %H:%M:%S' "$value" +%s 2>/dev/null)" || return 1
  else
    candidate="$(date -d "$value" +%s 2>/dev/null)" || return 1
  fi
  printf '%s\n' "$candidate"
}

reset_for() { # <rule> <normalized capture> <now>
  local rule="$1" text="$2" now="$3" amount unit clock value reset
  case "$rule" in
    none) return 0 ;;
    pipe_epoch)
      if [[ "$text" =~ \|([0-9]{10}) ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
      fi
      ;;
    clock)
      if [[ "$text" =~ (resets|reset[[:space:]]at|will[[:space:]]reset[[:space:]]at|try[[:space:]]again[[:space:]]at)[[:space:]]+([0-9]{1,2}(:[0-9]{2})?[[:space:]]*[ap]m) ]]; then
        clock_epoch "$now" "${BASH_REMATCH[2]}" || true
      fi
      ;;
    datetime)
      if [[ "$text" =~ (try[[:space:]]again[[:space:]]at|resets|reset[[:space:]]at)[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{1,2}:[0-9]{2}) ]]; then
        value="${BASH_REMATCH[2]}"
        reset="$(datetime_epoch "$value" 2>/dev/null || true)"
        [[ -n "$reset" && "$reset" -gt "$now" ]] && printf '%s\n' "$reset"
      elif [[ "$text" =~ (try[[:space:]]again[[:space:]]at|resets|reset[[:space:]]at|will[[:space:]]reset[[:space:]]at)[[:space:]]+([0-9]{1,2}(:[0-9]{2})?[[:space:]]*[ap]m) ]]; then
        clock_epoch "$now" "${BASH_REMATCH[2]}" || true
      fi
      ;;
    relative)
      if [[ "$text" =~ try[[:space:]]again[[:space:]]in[[:space:]]+([0-9]+)[[:space:]]+(minute|minutes|hour|hours) ]]; then
        amount=$((10#${BASH_REMATCH[1]}))
        unit="${BASH_REMATCH[2]}"
        case "$unit" in hour|hours) amount=$((amount * 3600)) ;; *) amount=$((amount * 60)) ;; esac
        printf '%s\n' "$((now + amount))"
      fi
      ;;
  esac
}

CMD="${1:-}"
[[ "$CMD" == "classify" ]] || usage
CLI="${2:-}"
CAPTURE="${3:-}"
[[ "$CLI" =~ ^(claude|codex|copilot)$ && -f "$CAPTURE" ]] || usage
shift 3
NOW="$(date +%s)"
if [[ $# -gt 0 ]]; then
  [[ "$1" == "--now" && "${2:-}" =~ ^[0-9]+$ && $# -eq 2 ]] || usage
  NOW=$((10#$2))
fi
[[ -r "$PATTERNS" ]] || { echo "missing pattern table: $PATTERNS" >&2; exit 2; }

# Strip CR and ANSI colour codes, fold case, and join wrapped output. The table
# is the only place provider message patterns live; this logic never matches a
# generic 'limit' or HTTP status by itself.
TEXT="$(LC_ALL=C awk '{ gsub(/\r/, ""); gsub(/\033\[[0-9;]*[[:alpha:]]/, ""); printf "%s ", $0 }' "$CAPTURE" | tr '[:upper:]' '[:lower:]')"

while IFS=$'\t' read -r detector pattern_cli kind_rule reset_rule ere; do
  [[ -n "$detector" && "${detector#\#}" == "$detector" ]] || continue
  [[ "$pattern_cli" == "$CLI" ]] || continue
  if [[ "$TEXT" =~ $ere ]]; then
    reset="$(reset_for "$reset_rule" "${BASH_REMATCH[0]}" "$NOW")"
    kind="$kind_rule"
    if [[ "$kind" == "horizon" ]]; then
      if [[ -z "$reset" ]]; then kind="unknown"
      elif (( reset - NOW <= 21600 )); then kind="short"
      else kind="long"; fi
    fi
    printf 'limit\t%s\t%s\t%s\n' "$kind" "$reset" "$detector"
    exit 0
  fi
done < "$PATTERNS"

echo "none"
exit 1
