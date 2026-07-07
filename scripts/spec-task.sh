#!/usr/bin/env bash
# spec-task.sh — tick, start, and inspect tasks in tasks.md deterministically.
#
# The kit's invariant is "a box is never ticked without its *Evidence:* line" —
# this script makes the tick and the evidence ONE atomic edit, so no session
# can forget half of it. Gate tasks (blocks with an *Agent:* line) and Ship
# tasks are exempt (their evidence is the gate report / PR URL), matching
# sdd-analyze.sh.
#
# Usage:
#   spec-task.sh list  <spec-dir>                 # TSV: id  state  stage  subject
#   spec-task.sh show  <spec-dir> T###            # the full task block
#   spec-task.sh start <spec-dir> T###            # [ ] -> [~]  (in progress)
#   spec-task.sh done  <spec-dir> T### --evidence "cmd → key output"
#                                                 # -> [x] + *Evidence:* (+ date)
#   spec-task.sh undo  <spec-dir> T###            # -> [ ]  (evidence line kept)
#
# `done` re-run on a done task updates the evidence line (idempotent).
# Also bumps the tasks.md frontmatter `updated:` field on every mutation.
#
# Exit: 0 = ok, 1 = task not found, 2 = usage, 3 = evidence required but missing.

set -euo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"

usage() { usage_from_header "$0"; exit 0; }

EVIDENCE=""
ARGS=()
while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --evidence) shift; EVIDENCE="${1:?--evidence needs text}" ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done

CMD="${ARGS[0]:-}"
SPEC_DIR="${ARGS[1]:-}"
TASK_ID="${ARGS[2]:-}"
[[ -z "$CMD" || -z "$SPEC_DIR" ]] && { usage_from_header "$0" >&2; exit 2; }
TASKS="$SPEC_DIR/tasks.md"
[[ -f "$TASKS" ]] || { echo "no tasks.md in $SPEC_DIR" >&2; exit 1; }

# task_scan — one record per task:  id \t state \t stage \t is_exempt \t subject
# state: todo|doing|done. is_exempt: 1 when gate (*Agent:* line) or Ship stage.
task_scan() {
  awk '
    function flush() {
      if (id == "") return
      exempt = (is_gate || stage == "Ship") ? 1 : 0
      printf "%s\t%s\t%s\t%d\t%s\n", id, state, stage, exempt, subj
      id=""
    }
    /^##[^#]/ { flush(); sub(/^##[[:space:]]*/,""); stage=$0 }
    /^- \[[ xX~]\] \*\*T[0-9]{3}[a-z0-9]*\*\*/ {
      flush()
      match($0, /T[0-9]{3}[a-z0-9]*/); id = substr($0, RSTART, RLENGTH)
      state = "todo"
      if ($0 ~ /^- \[[xX]\]/) state = "done"
      else if ($0 ~ /^- \[~\]/) state = "doing"
      subj = $0
      sub(/^- \[[ xX~]\] \*\*T[0-9]{3}[a-z0-9]*\*\*[[:space:]]*/, "", subj)
      while (subj ~ /^\[[^]]*\][[:space:]]*/) sub(/^\[[^]]*\][[:space:]]*/, "", subj)
      sub(/^(—|-)[[:space:]]*/, "", subj)
      is_gate = 0; next
    }
    /\*Agent:\*/ { is_gate = 1 }
    END { flush() }
  ' "$TASKS"
}

task_row() { task_scan | awk -F'\t' -v id="$1" '$1 == id { print; exit }'; }

# mutate <id> <new-box> [evidence] — rewrite tasks.md: flip the box on the
# task's header line; for done-with-evidence, set/replace the block's
# *Evidence:* field line. The whole rewrite is one tmp+mv (atomic-ish).
mutate() {
  local id="$1" box="$2" evidence="${3:-}" tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/spec-task.XXXXXX")" || exit 1
  EV_TEXT="$evidence" awk -v id="$id" -v box="$box" '
    BEGIN { ev = ENVIRON["EV_TEXT"] }
    # End of the target task block: emit pending evidence before leaving it.
    function leave_block() {
      if (in_block && ev != "" && !ev_done) { print "  - *Evidence:* " ev; ev_done=1 }
      in_block=0
    }
    /^- \[[ xX~]\] \*\*T[0-9]{3}[a-z0-9]*\*\*/ {
      leave_block()
      match($0, /T[0-9]{3}[a-z0-9]*/)
      if (substr($0, RSTART, RLENGTH) == id) {
        sub(/^- \[[ xX~]\]/, "- [" box "]")
        in_block=1; found=1
      }
      print; next
    }
    /^##[^#]/ || /^---/ { leave_block(); print; next }
    in_block && /^[[:space:]]+- \*Evidence[^*]*:\*/ {
      if (ev != "") { print "  - *Evidence:* " ev; ev_done=1 }
      else print                    # undo/start keep the old evidence line
      next
    }
    # A non-field line (blank or anything not an indented "- *" field) ends the block.
    in_block && !/^[[:space:]]+- \*/ { leave_block() }
    { print }
    END { leave_block(); exit found ? 0 : 9 }
  ' "$TASKS" > "$tmp" && rc=0 || rc=$?
  if (( rc == 9 )); then rm -f "$tmp"; echo "task $id not found in $TASKS" >&2; exit 1; fi
  (( rc != 0 )) && { rm -f "$tmp"; echo "failed to rewrite $TASKS" >&2; exit 1; }
  mv "$tmp" "$TASKS"
  fm_set "$TASKS" updated "$(date +%Y-%m-%d)" 2>/dev/null || true
}

case "$CMD" in
  list)
    task_scan | awk -F'\t' '{ printf "%s\t%s\t%s\t%s\n", $1, $2, $3, $5 }'
    ;;
  show)
    [[ -z "$TASK_ID" ]] && { echo "usage: spec-task.sh show <spec-dir> T###" >&2; exit 2; }
    awk -v id="$TASK_ID" '
      /^- \[[ xX~]\] \*\*T[0-9]{3}[a-z0-9]*\*\*/ {
        match($0, /T[0-9]{3}[a-z0-9]*/)
        in_block = (substr($0, RSTART, RLENGTH) == id)
        if (in_block) found=1
      }
      /^##[^#]/ { in_block=0 }
      in_block { print }
      END { exit found ? 0 : 1 }
    ' "$TASKS" || { echo "task $TASK_ID not found" >&2; exit 1; }
    ;;
  start)
    [[ -z "$TASK_ID" ]] && { echo "usage: spec-task.sh start <spec-dir> T###" >&2; exit 2; }
    mutate "$TASK_ID" "~"
    echo "$TASK_ID -> [~] (in progress)" >&2
    ;;
  done)
    [[ -z "$TASK_ID" ]] && { echo "usage: spec-task.sh done <spec-dir> T### --evidence \"...\"" >&2; exit 2; }
    row="$(task_row "$TASK_ID")"
    [[ -z "$row" ]] && { echo "task $TASK_ID not found in $TASKS" >&2; exit 1; }
    exempt="$(cut -f4 <<< "$row")"
    if [[ -z "$EVIDENCE" && "$exempt" != 1 ]]; then
      echo "REFUSED: $TASK_ID needs --evidence \"<command> → <key output>\"" >&2
      echo "a ticked box without evidence is an unproven claim (gate/Ship tasks are exempt)" >&2
      exit 3
    fi
    ev=""
    [[ -n "$EVIDENCE" ]] && ev="\`$EVIDENCE\` ($(date +%Y-%m-%d))"
    # If the caller already formatted (backticks/date), don't double-wrap.
    [[ "$EVIDENCE" == \`* ]] && ev="$EVIDENCE"
    mutate "$TASK_ID" "x" "$ev"
    echo "$TASK_ID -> [x]${ev:+ with evidence}" >&2
    ;;
  undo)
    [[ -z "$TASK_ID" ]] && { echo "usage: spec-task.sh undo <spec-dir> T###" >&2; exit 2; }
    mutate "$TASK_ID" " "
    echo "$TASK_ID -> [ ]" >&2
    ;;
  *)
    echo "unknown command: $CMD" >&2
    usage_from_header "$0" >&2
    exit 2
    ;;
esac
