#!/usr/bin/env bash
set -uo pipefail
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
[[ ! -e "$r/s28-op24-reserve.log" && ! -e "$r/s28-op24-reserve.rc" && ! -e "$r/s28-op24-reserve.time" ]] || exit 2
printf 'start=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$r/s28-op24-reserve.time"
bash scripts/spec-gate.sh round .specify/specs/003-gate-round-reduction-and-token-discipline opponent --floor FLOOR-GMlmyY > "$r/s28-op24-reserve.log" 2>&1
rc=$?
printf '%s\n' "$rc" > "$r/s28-op24-reserve.rc"
printf 'end=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$r/s28-op24-reserve.time"
cat "$r/s28-op24-reserve.log"
exit "$rc"
