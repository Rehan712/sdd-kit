#!/usr/bin/env bash
set -uo pipefail
spec=.specify/specs/003-gate-round-reduction-and-token-discipline
task="$1"
mkdir -p "$spec/notes/verification/returns"
out="$spec/notes/verification/returns/$task-run.txt"
bash scripts/spec-run.sh "$spec" "$task" --from-task --no-tick --summary > "$out" 2>&1
rc=$?
cat "$out"
(( rc == 0 )) || exit "$rc"
cap="$(sed -n 's/^capture=\([^ ]*\).*/\1/p' "$out")"
[[ -n "$cap" ]] || exit 3
bash .specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/handoff/return.sh "$task" "$cap"
