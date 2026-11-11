#!/usr/bin/env bash
# spec-loop.sh — drive a spec's implement phase, one task per fresh session.
#
# /sdd:implement --all runs every task in ONE session: by task 20 its context
# still carries 19 finished tasks. This is the outer loop instead. Each
# iteration asks spec-graph.sh for the next task, hands exactly that task to a
# fresh headless session through spec-dispatch.sh, then re-reads tasks.md.
# All state is on disk (tasks.md, STATUS.md, the spec branch), so a killed
# loop resumes by being run again.
#
# The loop stops; it never guesses:
#   - no task left, or the next task is a Ship task (the PR stays yours) — 0;
#   - two iterations in a row ticked nothing and opened nothing — 1 (stalled:
#     a failing acceptance, or a gate the round cap refuses);
#   - the iteration cap — 8;
#   - the dispatcher refused or parked the run (its exit 2/3/4/5/7) — that
#     code. After a park (7) the resume unit replays that one task; run the
#     loop again afterwards.
# A dispatcher exit 1 or 6 (verification failed, CLI crashed) is an iteration
# like any other: progress in tasks.md decides, never the exit code.
#
# Gates run inside the loop (an *Agent:* task is one iteration; its round cap
# is still enforced by spec-gate.sh). Umbrella specs are refused: the
# cross-repo run stays interactive.
#
# Usage:
#   spec-loop.sh <spec-dir> [--to <cli>] [--max-iterations N] [--dry-run]
#   spec-loop.sh --help
#
# --to               passed to spec-dispatch.sh (else the models.yml dispatch: map)
# --max-iterations   default 30
# --dry-run          print the batches the loop would walk; run nothing

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
GRAPH="$HUB_DIR/scripts/spec-graph.sh"
DISPATCH="${SDD_LOOP_DISPATCH:-$HUB_DIR/scripts/spec-dispatch.sh}"   # test seam

TO=""
MAX=30
DRY=0
SPEC_ARG=""
while (( $# )); do
  case "$1" in
    --help|-h) usage_from_header "$0"; exit 0 ;;
    --to) shift; TO="${1:?--to needs claude|codex|copilot}" ;;
    --max-iterations) shift; MAX="${1:?--max-iterations needs a number}" ;;
    --dry-run) DRY=1 ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) [[ -z "$SPEC_ARG" ]] || { echo "unexpected arg: $1" >&2; exit 2; }; SPEC_ARG="$1" ;;
  esac
  shift
done
[[ -n "$SPEC_ARG" ]] || { usage_from_header "$0" >&2; exit 2; }
[[ "$MAX" =~ ^[1-9][0-9]*$ ]] || { echo "--max-iterations needs a positive number" >&2; exit 2; }
SPEC_DIR="$(cd -- "$SPEC_ARG" 2>/dev/null && pwd)" || { echo "spec dir not found: $SPEC_ARG" >&2; exit 2; }
SLUG="$(basename "$SPEC_DIR")"
if [[ -n "$(spec_declared_repos "$SPEC_DIR")" ]]; then
  echo "umbrella spec ($SLUG): the cross-repo run stays interactive — use /sdd:implement --all" >&2
  exit 5
fi

# The live spec dir is the worktree's copy: that is where a run ticks boxes.
WT="$(fm_get "$SPEC_DIR/STATUS.md" worktree 2>/dev/null)"
if [[ -z "$WT" || "$WT" == "none" || ! -d "$WT" ]]; then
  if (( DRY )); then
    WT=""
  else
    WT="$("$HUB_DIR/scripts/spec-worktree.sh" "$SPEC_DIR" | tail -1)" \
      || { echo "spec-worktree.sh failed — cannot start the loop" >&2; exit 4; }
  fi
fi
LIVE="$SPEC_DIR"
[[ -z "$WT" ]] || LIVE="$WT/.specify/specs/$SLUG"
[[ -f "$LIVE/tasks.md" ]] || { echo "no tasks.md in $LIVE" >&2; exit 1; }

if (( DRY )); then
  "$GRAPH" waves "$LIVE" || exit 1
  exit 0
fi

# progress — "<ticked>/<tasks>": a tick or a newly opened follow-up changes it;
# a box moved to [~] does not.
progress() {
  awk '/^- \[[ xX~]\] \*\*T[0-9][0-9][0-9][a-z0-9]*\*\*/ { n++; if ($0 ~ /^- \[[xX]\]/) d++ }
       END { print (d + 0) "/" (n + 0) }' "$LIVE/tasks.md"
}

iteration=0
stalled=0
while :; do
  row="$("$GRAPH" next "$LIVE")" || { echo "task graph is invalid — fix tasks.md first" >&2; exit 1; }
  row="${row%%$'\n'*}"   # the loop is serial: the first task of the batch
  if [[ -z "$row" ]]; then
    echo "loop done: every task is ticked ($(progress))"
    exit 0
  fi
  IFS=$'\t' read -r id _ kind _ _ subject <<< "$row"
  if [[ "$kind" == "ship" ]]; then
    echo "loop done: $(progress) — next is $id ($subject), a Ship task; it stays with you (/sdd:implement $id)"
    exit 0
  fi
  if (( iteration >= MAX )); then
    echo "iteration cap ($MAX) reached at $(progress) — next would be $id; re-run to continue" >&2
    exit 8
  fi
  iteration=$((iteration + 1))

  note="spec-loop iteration $iteration: nobody is waiting on this run. When the task is accepted, commit it on the spec branch yourself (one task, one commit, the conventional message; never push)."
  (( stalled )) && note="$note The previous session on $id recorded no progress: treat this as a re-dispatch after a failed acceptance (escalate; read notes/ for what it left)."

  before="$(progress)"
  echo "iteration $iteration: $id ($kind) — $subject [$before]"
  rc=0
  "$DISPATCH" implement "$SPEC_DIR" --task "$id" ${TO:+--to "$TO"} --note "$note" || rc=$?
  case "$rc" in
    2|3|4|5|7) echo "loop stopped: the dispatcher exited $rc on $id" >&2; exit "$rc" ;;
  esac

  if [[ "$(progress)" == "$before" ]]; then
    stalled=$((stalled + 1))
    if (( stalled >= 2 )); then
      echo "loop stalled: two sessions on $id changed nothing in tasks.md (dispatcher exit $rc) — read $LIVE/notes/" >&2
      exit 1
    fi
  else
    stalled=0
  fi
done
