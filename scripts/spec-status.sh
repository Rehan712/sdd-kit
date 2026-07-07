#!/usr/bin/env bash
# spec-status.sh — read/write spec state machine-side (STATUS.md frontmatter).
#
# The deterministic mutation path for spec state: scripts, CI hooks, and
# tracker syncs call this instead of relying on a model remembering to edit
# STATUS.md. `set` bumps `updated:` automatically and validates enum fields
# (values may carry annotations — "CLEARED (2026-07-07)" validates as CLEARED).
#
# Enum fields (leading token, case-insensitive):
#   phase          specify plan tasks implement review shipped abandoned
#   active_tool    claude codex copilot none
#   opponent       not-run CLEARED CHALLENGED BLOCKED
#   reality_check  not-run READY NEEDS FAILED       (NEEDS = "NEEDS WORK")
#   ci             not-run pending green red
#   retro          not-run done
#
# Usage:
#   spec-status.sh get  <spec-dir> <field>
#   spec-status.sh set  <spec-dir> <field> <value>
#   spec-status.sh show <spec-dir>                  # full frontmatter
#   spec-status.sh --file spec.md set <spec-dir> status accepted
#                                                   # target another artifact
#                                                   # (spec.md|plan.md|tasks.md)
#
# Exit: 0 = ok, 1 = not found / bad value, 2 = usage.

set -euo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"

usage() { usage_from_header "$0"; exit 0; }

TARGET_FILE="STATUS.md"
ARGS=()
while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --file) shift; TARGET_FILE="${1:?--file needs a filename}" ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done

CMD="${ARGS[0]:-}"
SPEC_DIR="${ARGS[1]:-}"
[[ -z "$CMD" || -z "$SPEC_DIR" ]] && { usage_from_header "$0" >&2; exit 2; }
[[ -d "$SPEC_DIR" ]] || { echo "not a directory: $SPEC_DIR" >&2; exit 2; }
case "$TARGET_FILE" in
  STATUS.md|spec.md|plan.md|tasks.md) : ;;
  *) echo "--file must be one of STATUS.md|spec.md|plan.md|tasks.md" >&2; exit 2 ;;
esac
FILE="$SPEC_DIR/$TARGET_FILE"
[[ -f "$FILE" ]] || { echo "no $TARGET_FILE in $SPEC_DIR" >&2; exit 1; }

# validate <field> <value> — enum fields accept a leading allowed token.
validate() {
  local field="$1" value="$2" allowed="" tok
  # STATUS.md enums; spec/plan/tasks `status:` get their own set.
  if [[ "$TARGET_FILE" == "STATUS.md" ]]; then
    case "$field" in
      phase)         allowed="specify plan tasks implement review shipped abandoned" ;;
      active_tool)   allowed="claude codex copilot none" ;;
      opponent)      allowed="not-run cleared challenged blocked" ;;
      reality_check) allowed="not-run ready needs failed" ;;
      ci)            allowed="not-run pending green red" ;;
      retro)         allowed="not-run done" ;;
      *) return 0 ;;
    esac
  elif [[ "$field" == "status" ]]; then
    case "$TARGET_FILE" in
      spec.md|plan.md) allowed="draft accepted implementing shipped rejected" ;;
      tasks.md)        allowed="draft in-progress complete" ;;
    esac
  else
    return 0
  fi
  tok="$(printf '%s' "$value" | awk '{print tolower($1)}')"
  for a in $allowed; do [[ "$tok" == "$a" ]] && return 0; done
  echo "invalid $field value '$value' — leading token must be one of: $allowed" >&2
  return 1
}

case "$CMD" in
  get)
    field="${ARGS[2]:-}"; [[ -z "$field" ]] && { echo "usage: spec-status.sh get <spec-dir> <field>" >&2; exit 2; }
    fm_get "$FILE" "$field"
    ;;
  set)
    field="${ARGS[2]:-}"; value="${ARGS[3]:-}"
    [[ -z "$field" || -z "${ARGS[3]+x}" ]] && { echo "usage: spec-status.sh set <spec-dir> <field> <value>" >&2; exit 2; }
    validate "$field" "$value" || exit 1
    fm_set "$FILE" "$field" "$value"
    [[ "$TARGET_FILE" == "STATUS.md" && "$field" != "updated" ]] \
      && fm_set "$FILE" updated "$(date +%Y-%m-%d)"
    echo "$TARGET_FILE: $field = $value" >&2
    ;;
  show)
    frontmatter_block "$FILE"
    ;;
  *)
    echo "unknown command: $CMD" >&2
    usage_from_header "$0" >&2
    exit 2
    ;;
esac
