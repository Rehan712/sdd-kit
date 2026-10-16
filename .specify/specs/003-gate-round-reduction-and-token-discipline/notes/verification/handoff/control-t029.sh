#!/usr/bin/env bash
set -uo pipefail
spec=.specify/specs/003-gate-round-reduction-and-token-discipline
bash .specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/handoff/return.sh T029 "$1" --prepare || exit $?
. scripts/verification-lib.sh
before="$(vf_hash "$spec/tasks.md")"
sed '/^FM-/d' "$spec/notes/verification/returns/T029.txt" > "$spec/notes/verification/returns/T029-incomplete.txt"
rc=0
bash scripts/spec-gate.sh accept "$spec" T029 "$spec/notes/verification/returns/T029-incomplete.txt" || rc=$?
[[ "$rc" == 3 && "$before" == "$(vf_hash "$spec/tasks.md")" ]] || exit 3
printf 'Deliberately incomplete T029 control rejected; unchanged tasks digest=%s\n' "$before"
bash scripts/spec-gate.sh accept "$spec" T029 "$spec/notes/verification/returns/T029.txt"
