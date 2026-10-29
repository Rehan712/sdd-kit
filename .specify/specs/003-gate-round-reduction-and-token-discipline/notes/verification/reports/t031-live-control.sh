#!/usr/bin/env bash
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
cap="$1"
bash "$s/notes/verification/handoff/control-t029.sh" "$cap" > "$r/t031-typed-control.log" 2>&1
rc=$?
printf '%s\n' "$rc" > "$r/t031-typed-control.rc"
printf 'typed-control exit=%s\n' "$rc"
[[ "$rc" == 0 ]] || exit "$rc"
bash tests/probe-gate-contract.sh "$s" > "$r/t031-live-probe.log" 2>&1
rc=$?
printf '%s\n' "$rc" > "$r/t031-live-probe.rc"
printf 'live-probe exit=%s\n' "$rc"
exit "$rc"
