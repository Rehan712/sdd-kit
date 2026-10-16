#!/usr/bin/env bash
# Fresh floor after T030o41 (session 4), 2026-09-25. No round is authorized by it.
# Pattern: r10-floor.sh. Usage from the worktree root: bash <this> <attempt-number>
# The floor's own exit code is written from inside the caffeinate wrapper, so
# no trailing command can stand in for it; read t030o41-floor-<n>.rc back after.
# A 60-second disk/swap sampler runs beside it; the wrapper stops it when the
# floor returns (whether or not an .rc was written), and it exits on its own if
# the wrapper dies, so a killed floor can never leave the wrapper waiting.
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
n="${1:?attempt number}"
[[ ! -e "$r/t030o41-floor-$n.rc" ]] || { echo "refusing: attempt $n already has a receipt" >&2; exit 2; }
{
  printf 'start=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  df -h / | tail -1
  sysctl -n vm.swapusage
  printf 'captures-before=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
  printf 'floor-latest-before=%s\n' "$(cat "$s/notes/verification/floor-latest")"
} > "$r/t030o41-floor-$n.pre" 2>&1
sample() {
  printf '%s avail=%s swap_used=%s\n' "$(date -u +%H:%M:%SZ)" \
    "$(df -k / | awk 'NR==2{printf "%.2fGiB",$4/1048576}')" \
    "$(sysctl -n vm.swapusage | awk '{print $6}')"
}
wrapper=$$
( while kill -0 "$wrapper" 2>/dev/null; do sample; sleep 60; done ) >> "$r/t030o41-floor-$n.samples.log" 2>&1 &
sampler=$!
caffeinate -i -m -s bash -c 'bash scripts/spec-gate.sh floor "$1" > "$2" 2>&1; printf "%s\n" "$?" > "$3"' \
  _ "$s" "$r/t030o41-floor-$n.log" "$r/t030o41-floor-$n.rc"
kill "$sampler" 2>/dev/null; wait "$sampler" 2>/dev/null
{ sample; printf 'floor returned; rc file: %s\n' "$(cat "$r/t030o41-floor-$n.rc" 2>/dev/null || echo MISSING)"; } >> "$r/t030o41-floor-$n.samples.log" 2>&1
{
  printf 'end=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'captures-after=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
  printf 'floor-latest-after=%s\n' "$(cat "$s/notes/verification/floor-latest")"
  df -h / | tail -1
  sysctl -n vm.swapusage
} >> "$r/t030o41-floor-$n.pre" 2>&1
rc="$(cat "$r/t030o41-floor-$n.rc" 2>/dev/null)"
printf 'floor attempt %s exit=%s\n' "$n" "${rc:-MISSING}"
[[ "$rc" =~ ^[0-9]+$ ]] || exit 99
exit "$rc"
