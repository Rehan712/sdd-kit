#!/usr/bin/env bash
# spec-run.sh — run a task's acceptance check FOR REAL, capture the output, and
# tick the box from that captured run. Evidence becomes the RECORD of an
# execution, not a string a model typed.
#
# The gap this closes: spec-task.sh records whatever --evidence string it is
# handed; nothing forces that string to describe a command that actually ran. A
# model can write `bun test → 14 passed` without running anything, and only the
# (late, model-run) reality-check gate might catch it. spec-run.sh executes the
# command itself, captures stdout+stderr+exit code+a content hash into
# notes/evidence.md under `## T### — <timestamp>`, and ONLY on exit 0 hands
# spec-task.sh an evidence line quoting the real output. A ticked box then traces
# to a run that happened — for every acceptance check the tooling can execute.
# (Deploy-only / screenshot ACs stay honestly UNVERIFIABLE and are ticked by
# hand via spec-task.sh, as before.)
#
# Usage:
#   spec-run.sh <spec-dir> T### -- <command> [args...]
#   spec-run.sh <spec-dir> T### --key 'passed' -- bun test        # pick the evidence line
#   spec-run.sh <spec-dir> T### --cwd <dir>    -- <command>       # run somewhere else
#   spec-run.sh <spec-dir> T### --no-tick      -- <command>       # capture only, don't tick
#   spec-run.sh --help
#
# Everything after `--` is the command, executed as-is (no shell re-parsing).
# Default cwd is the caller's cwd — in /sdd:implement that is the worktree root.
# The evidence line quotes the last non-empty output line (or the --key match);
# the full run always lands in notes/evidence.md regardless.
#
# Exit: 0 = command passed and box ticked (or captured with --no-tick);
#       the command's own non-zero code when it fails (box left untouched, the
#       failed run still recorded); 2 = usage; 3 = tick refused by spec-task.sh.

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
SPEC_TASK="$HUB_DIR/scripts/spec-task.sh"

usage() { usage_from_header "$0"; exit 0; }

# --- arg parse: flags + positionals before `--`, command after -------------
KEY=""
RUN_CWD=""
NO_TICK=0
ARGS=()
CMD=()
seen_ddash=0
while (( $# )); do
  if (( seen_ddash )); then CMD+=("$1"); shift; continue; fi
  case "$1" in
    --help|-h) usage ;;
    --) seen_ddash=1 ;;
    --key)   shift; KEY="${1:?--key needs a pattern}" ;;
    --cwd)   shift; RUN_CWD="${1:?--cwd needs a directory}" ;;
    --no-tick) NO_TICK=1 ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done

SPEC_DIR="${ARGS[0]:-}"
TASK_ID="${ARGS[1]:-}"
[[ -z "$SPEC_DIR" || -z "$TASK_ID" ]] && { usage_from_header "$0" >&2; exit 2; }
(( seen_ddash )) || { echo "no command — put the acceptance command after \`--\`" >&2; exit 2; }
(( ${#CMD[@]} )) || { echo "empty command after \`--\`" >&2; exit 2; }
[[ -d "$SPEC_DIR" ]] || { echo "not a directory: $SPEC_DIR" >&2; exit 2; }
SPEC_DIR="$(cd "$SPEC_DIR" && pwd)"
TASKS="$SPEC_DIR/tasks.md"
[[ -f "$TASKS" ]] || { echo "no tasks.md in $SPEC_DIR" >&2; exit 1; }
grep -qE "\*\*$TASK_ID\*\*" "$TASKS" || { echo "task $TASK_ID not found in $TASKS" >&2; exit 1; }

RUN_CWD="${RUN_CWD:-$PWD}"
[[ -d "$RUN_CWD" ]] || { echo "--cwd is not a directory: $RUN_CWD" >&2; exit 2; }

# --- hashing (BSD + GNU safe): shasum -a 256, then sha256sum, then cksum ----
hash_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print "sha256:" substr($1,1,12)}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print "sha256:" substr($1,1,12)}'
  else
    cksum "$1" | awk '{print "cksum:" $1}'
  fi
}

# --- run, capturing combined output; keep the real exit code ----------------
out="$(mktemp "${TMPDIR:-/tmp}/spec-run.XXXXXX")" || exit 1
trap 'rm -f "$out"' EXIT

printf -v cmd_str '%s ' "${CMD[@]}"; cmd_str="${cmd_str% }"   # display form

ts="$(date +%Y-%m-%dT%H:%M:%S)"
echo "\$ $cmd_str" >&2
# No `set -e` in this script, so a non-zero command does not abort us — we want
# its exit code. Not a pipeline, so pipefail is irrelevant here.
( cd "$RUN_CWD" && "${CMD[@]}" ) >"$out" 2>&1
rc=$?

# Echo the captured output so the operator sees exactly what ran.
cat "$out" >&2

digest="$(hash_file "$out")"
# Key line for the one-line evidence: --key match (last), else last non-empty line.
if [[ -n "$KEY" ]]; then
  keyline="$(grep -E -- "$KEY" "$out" | tail -1 || true)"
fi
[[ -z "${keyline:-}" ]] && keyline="$(awk 'NF{last=$0} END{print last}' "$out")"
keyline="$(printf '%s' "$keyline" | sed -E 's/[[:cntrl:]]//g; s/^[[:space:]]+//; s/[[:space:]]+$//')"
[[ -z "$keyline" ]] && keyline="(no output)"

# --- append the record to notes/evidence.md --------------------------------
notes="$SPEC_DIR/notes"
mkdir -p "$notes"
evfile="$notes/evidence.md"
[[ -f "$evfile" ]] || printf '# Evidence log\n\nCaptured acceptance runs, appended by `spec-run.sh`. One block per run.\n' > "$evfile"

# Cap very long output so the log stays readable; the hash is over the FULL run.
lines="$(wc -l < "$out" | tr -d ' ')"
{
  printf '\n## %s — %s\n\n' "$TASK_ID" "$ts"
  printf -- '- **Command:** `%s`\n' "$cmd_str"
  printf -- '- **Cwd:** %s\n' "$RUN_CWD"
  printf -- '- **Exit:** %s\n' "$rc"
  printf -- '- **Captured:** %s · %s (over full output)\n\n' "$ts" "$digest"
  printf '```text\n'
  if (( lines > 400 )); then
    head -n 120 "$out"
    printf '\n… [%s lines total — trimmed; full run hashed above] …\n\n' "$lines"
    tail -n 120 "$out"
  else
    cat "$out"
  fi
  printf '```\n'
} >> "$evfile"

echo "recorded $TASK_ID run (exit $rc, $digest) → ${evfile/#$HOME/~}" >&2

# --- verdict ----------------------------------------------------------------
if (( rc != 0 )); then
  echo "✗ $TASK_ID acceptance FAILED (exit $rc) — box left unticked; failed run recorded" >&2
  exit "$rc"
fi

if (( NO_TICK )); then
  echo "✓ $TASK_ID acceptance passed (--no-tick: not ticking)" >&2
  exit 0
fi

evidence="$cmd_str → $keyline (see notes/evidence.md)"
"$SPEC_TASK" done "$SPEC_DIR" "$TASK_ID" --evidence "$evidence"
