#!/usr/bin/env bash
# spec-brief.sh — write a task's implementation brief from the artifacts.
#
# A brief the invoker types is output tokens on its (expensive) tier, and a
# paraphrased seam is a re-negotiated seam. This script copies instead: the
# task block from tasks.md, the REQ/AC/CON text its *Refs:* name from spec.md,
# and the plan sections (`§N`) and FM/INV rows they name from plan.md — all
# verbatim. The invoker hands the implementer the file's path.
#
# When the project has a routing table (.specify/routing.md), the skills and
# agents it names for the task's *Files:* are listed by path under the header
# (project-routing.sh) — so an implementer on any CLI reads the project's own
# conventions without the invoker naming them.
#
# The brief lands in <spec-dir>/notes/verification/briefs/T###.md — spec
# bookkeeping, outside the input manifest, so writing it never stales a
# capture. `Source revision:` is the digest of spec.md, plan.md and the task
# block: it changes when any of them does, and a changed task needs a new brief.
#
# Usage:
#   spec-brief.sh <spec-dir> T###            # write the brief, print its path
#   spec-brief.sh <spec-dir> T### --stdout   # print the brief, write nothing
#   spec-brief.sh --help
#
# Exit: 0 = written; 1 = task or artifact not found; 2 = usage.
#
# shortcut: `§4.2` pulls all of section 4, and a plan whose sections are not
# `## N. Title` yields no plan text — upgrade when a plan template changes that.

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
. "$HUB_DIR/scripts/verification-lib.sh"

STDOUT=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --help|-h) usage_from_header "$0"; exit 0 ;;
    --stdout) STDOUT=1 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) ARGS+=("$arg") ;;
  esac
done
SPEC_DIR="${ARGS[0]:-}"
TASK_ID="${ARGS[1]:-}"
[[ -n "$SPEC_DIR" && "$TASK_ID" =~ ^T[0-9][0-9][0-9][a-z0-9]*$ ]] || { usage_from_header "$0" >&2; exit 2; }
[[ -d "$SPEC_DIR" ]] || { echo "not a directory: $SPEC_DIR" >&2; exit 1; }
SPEC_DIR="$(cd "$SPEC_DIR" && pwd)"
for f in spec.md plan.md tasks.md; do
  [[ -f "$SPEC_DIR/$f" ]] || { echo "no $f in $SPEC_DIR" >&2; exit 1; }
done

tmp="$(mktemp -d "${TMPDIR:-/tmp}/spec-brief.XXXXXX")" || exit 1
trap 'rm -rf "$tmp"' EXIT

# The task block: its checkbox line and the indented field lines under it.
task_block "$SPEC_DIR/tasks.md" "$TASK_ID" > "$tmp/task"
[[ -s "$tmp/task" ]] || { echo "task $TASK_ID not found in $SPEC_DIR/tasks.md" >&2; exit 1; }

# What the task's *Refs:* line names: ids, and plan sections after `§`.
refs="$(grep -E '^[[:space:]]*- \*Refs:\*' "$tmp/task" | head -1)"
ids="$(printf '%s\n' "$refs" | grep -oE '(REQ|AC|CON|MET|FM|INV)-[0-9]{3}' | sort -u | tr '\n' ' ')"
sections="$(printf '%s\n' "$refs" | grep -oE '§[0-9]+' | tr -d '§' | sort -un | tr '\n' ' ')"

# The project's own skills and agents for the task's *Files:* (its
# .specify/routing.md). An umbrella task names its repo; any other spec dir
# sits inside its project. A broken table stops the brief: a dispatch that
# went ahead would skip the project's conventions without saying so.
route_dir="$SPEC_DIR"
repo="$(head -1 "$tmp/task" | grep -oE '\[repo:[^]]+\]' | head -1 | sed -E 's/^\[repo:(.*)\]$/\1/')"
if [[ -n "$repo" ]]; then route_dir="$("$HUB_DIR/scripts/system-map.sh" path "$repo" 2>/dev/null)" || route_dir=""; fi
routing=""
if [[ -n "$route_dir" && -d "$route_dir" ]]; then
  routing="$("$HUB_DIR/scripts/project-routing.sh" match "$route_dir" implement --task "$SPEC_DIR" "$TASK_ID")" || exit 1
fi

{
  printf '# Brief: %s — spec %s\n\n' "$TASK_ID" "${SPEC_DIR##*/}"
  printf 'Mode: implementation\nSource revision: %s\nSpec dir: %s\n' \
    "$(cat "$SPEC_DIR/spec.md" "$SPEC_DIR/plan.md" "$tmp/task" > "$tmp/rev" && vf_hash "$tmp/rev" | cut -c1-16)" "$SPEC_DIR"
  if [[ -n "$routing" ]]; then
    printf '\nProject routing — this project names its own skills and agents for the files of this task.\n'
    printf 'Read each before the first edit: on its conventions it outranks the stack overlay and the\n'
    printf 'official skills; the task and the plan outrank it.\n'
    printf '%s\n' "$routing" | awk -F'\t' '
      $1 == "agent" { printf "- agent `%s` (the writer this task routes to): %s\n", $2, $3; next }
      $3 == "-"     { printf "- plugin skill `%s`: load it with the Skill tool when the session lists it\n", $2; next }
                    { printf "- skill `%s`: %s\n", $2, $3 }'
  fi
  printf '\nEverything below is copied verbatim from tasks.md, spec.md and plan.md.\n'
  printf '\n## Task\n\n'
  cat "$tmp/task"

  # A requirement is the line carrying **ID:** plus its continuation lines.
  printf '\n## Requirements (spec.md)\n\n'
  awk -v ids="$ids" '
    BEGIN { n = split(ids, a, " "); for (i = 1; i <= n; i++) want[a[i]] = 1 }
    /\*\*(REQ|AC|CON|MET)-[0-9][0-9][0-9]:\*\*/ {
      match($0, /(REQ|AC|CON|MET)-[0-9][0-9][0-9]/)
      on = (substr($0, RSTART, RLENGTH) in want)
      if (on) print
      next
    }
    /^[ \t]*$/ || /^#/ { on = 0; next }
    on { print }
  ' "$SPEC_DIR/spec.md"

  # Named plan sections whole; FM/INV rows from sections that were not named.
  printf '\n## Plan (plan.md)\n\n'
  awk -v secs="$sections" -v ids="$ids" '
    BEGIN {
      n = split(secs, a, " "); for (i = 1; i <= n; i++) sec[a[i]] = 1
      n = split(ids, b, " "); for (i = 1; i <= n; i++) want[b[i]] = 1
    }
    /^## / {
      cur = ""
      if (match($0, /^## [0-9]+/)) cur = substr($0, 4, RLENGTH - 3)
      on = (cur in sec)
    }
    on { print; next }
    /^\|[ \t]*(FM|INV)-[0-9][0-9][0-9][ \t]*\|/ {
      match($0, /(FM|INV)-[0-9][0-9][0-9]/)
      if (substr($0, RSTART, RLENGTH) in want) rows = rows $0 "\n"
    }
    END { if (rows != "") printf "\n### Failure-mode and invariant rows\n\n%s", rows }
  ' "$SPEC_DIR/plan.md"
} > "$tmp/brief"

if (( STDOUT )); then cat "$tmp/brief"; exit 0; fi
out="$SPEC_DIR/notes/verification/briefs"
mkdir -p "$out" || exit 1
cp "$tmp/brief" "$out/$TASK_ID.md" || exit 1
printf '%s\n' "$out/$TASK_ID.md"
