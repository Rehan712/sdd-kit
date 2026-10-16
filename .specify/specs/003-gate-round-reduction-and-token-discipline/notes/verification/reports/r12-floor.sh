#!/usr/bin/env bash
# Fresh floor for opponent round 12, 2026-09-27, on the source that holds the accepted T030o42
# repair of O-016. It reserves nothing; the reservation follows separately.
# Pattern: r11-floor.sh (itself from t030o41-floor.sh). Usage from the worktree root: bash <this> <attempt-number>
# The floor's own exit code is written from inside the caffeinate wrapper, so
# no trailing command can stand in for it; read r12-floor-<n>.rc back after.
# A 60-second disk/swap sampler runs beside it; the wrapper stops it when the
# floor returns (whether or not an .rc was written), and it exits on its own if
# the wrapper dies, so a killed floor can never leave the wrapper waiting.
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
n="${1:?attempt number}"
[[ ! -e "$r/r12-floor-$n.rc" ]] || { echo "refusing: attempt $n already has a receipt" >&2; exit 2; }
# AC power is a precondition: FLOOR-6eaaRv hibernated on battery and FLOOR-QeBcq3 ran
# most of its length on battery (2026-09-26). Refuse to start unless on AC.
pmset -g batt | head -1 | grep -q "AC Power" || { echo "refusing: not on AC power" >&2; exit 98; }
{
  printf 'start=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  df -h / | tail -1
  sysctl -n vm.swapusage
  printf 'captures-before=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
  printf 'floor-latest-before=%s\n' "$(cat "$s/notes/verification/floor-latest")"
} > "$r/r12-floor-$n.pre" 2>&1
power() {  # e.g. "AC Power/44%"; the Mac hibernated on battery during FLOOR-6eaaRv
  local b; b="$(pmset -g batt 2>/dev/null)"
  printf '%s/%s' "$(printf '%s\n' "$b" | sed -n "1s/.*'\(.*\)'.*/\1/p")" "$(printf '%s\n' "$b" | grep -o '[0-9]*%' | head -1)"
}
sample() {
  printf '%s avail=%s swap_used=%s power=%s\n' "$(date -u +%H:%M:%SZ)" \
    "$(df -k / | awk 'NR==2{printf "%.2fGiB",$4/1048576}')" \
    "$(sysctl -n vm.swapusage | awk '{print $6}')" "$(power)"
}
wrapper=$$
( while kill -0 "$wrapper" 2>/dev/null; do sample; sleep 60; done ) >> "$r/r12-floor-$n.samples.log" 2>&1 &
sampler=$!
caffeinate -i -m -s bash -c 'bash scripts/spec-gate.sh floor "$1" > "$2" 2>&1; printf "%s\n" "$?" > "$3"' \
  _ "$s" "$r/r12-floor-$n.log" "$r/r12-floor-$n.rc"
kill "$sampler" 2>/dev/null; wait "$sampler" 2>/dev/null
{ sample; printf 'floor returned; rc file: %s\n' "$(cat "$r/r12-floor-$n.rc" 2>/dev/null || echo MISSING)"; } >> "$r/r12-floor-$n.samples.log" 2>&1
{
  printf 'end=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'captures-after=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
  printf 'floor-latest-after=%s\n' "$(cat "$s/notes/verification/floor-latest")"
  df -h / | tail -1
  sysctl -n vm.swapusage
} >> "$r/r12-floor-$n.pre" 2>&1
rc="$(cat "$r/r12-floor-$n.rc" 2>/dev/null)"
printf 'floor attempt %s exit=%s\n' "$n" "${rc:-MISSING}"
[[ "$rc" =~ ^[0-9]+$ ]] || exit 99
exit "$rc"
