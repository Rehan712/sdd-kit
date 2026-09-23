#!/usr/bin/env bash
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
[[ ! -e "$r/r9-complete.rc" ]] || { echo "refusing: r9-complete.rc exists" >&2; exit 2; }
bash scripts/spec-gate.sh round "$s" opponent --complete "$r/opponent-round9.md" > "$r/r9-complete.log" 2>&1
rc=$?
printf '%s\n' "$rc" > "$r/r9-complete.rc"
printf 'round-complete exit=%s\n' "$rc"
[[ "$rc" == 0 ]] || exit "$rc"
bash scripts/spec-gate.sh tally "$s" > "$r/r9-tally.log" 2>&1
rc=$?
printf '%s\n' "$rc" > "$r/r9-tally.rc"
printf 'tally exit=%s\n' "$rc"
exit "$rc"
