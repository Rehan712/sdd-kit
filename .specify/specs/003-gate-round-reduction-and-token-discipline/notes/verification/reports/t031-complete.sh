#!/usr/bin/env bash
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
bash scripts/spec-gate.sh round "$s" reality-check --complete "$r/reality-check-round1.md" > "$r/t031-complete.log" 2>&1
rc=$?
printf '%s\n' "$rc" > "$r/t031-complete.rc"
printf 'round-complete exit=%s\n' "$rc"
[[ "$rc" == 0 ]] || exit "$rc"
bash scripts/spec-gate.sh tally "$s" > "$r/t031-tally.log" 2>&1
rc=$?
printf '%s\n' "$rc" > "$r/t031-tally.rc"
printf 'tally exit=%s\n' "$rc"
exit "$rc"
