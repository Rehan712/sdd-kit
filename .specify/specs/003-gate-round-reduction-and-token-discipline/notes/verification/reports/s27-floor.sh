#!/usr/bin/env bash
# Fresh s27 floor on the c7a82b3a frozen snapshot; no reservation is made.
# Launch detached under nohup with a wrapper receipt, after actual AC confirmation.
# Usage from the worktree root: bash <this> <attempt-number>
# The floor's own exit code is recorded inside the caffeinate wrapper.
# A 60-second disk/swap sampler runs beside it; the wrapper stops it when the
# floor returns (whether or not an .rc was written), and it exits on its own if
# the wrapper dies, so a killed floor can never leave the wrapper waiting.
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
n="${1:?attempt number}"
for suffix in rc log pre samples.log source-before.nul source-after.nul binding-before.json binding-after.json binding-before.log binding-after.log floor-id; do
  [[ ! -e "$r/s27-floorrun.$suffix" ]] || { echo "refusing: s27 floor output $suffix exists" >&2; exit 2; }
done
out="$s/notes/verification/platforms/ci-20261025-s27"
# AC power is a precondition: FLOOR-6eaaRv hibernated on battery and FLOOR-QeBcq3 ran
# most of its length on battery (2026-09-26). Refuse to start unless on AC.
pmset -g batt | head -1 | grep -q "AC Power" || { echo "refusing: not on AC power" >&2; exit 98; }
bash "$out/verify-prepublish.sh" > "$r/s27-floorrun.binding-before.log" 2>&1 || exit 97
cp "$out/inputs-after.nul" "$r/s27-floorrun.source-before.nul" || exit 97
cp "$out/verification-final.json" "$r/s27-floorrun.binding-before.json" || exit 97
before_floor="$(cat "$s/notes/verification/floor-latest")"
{
  printf 'start=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  df -h / | tail -1
  sysctl -n vm.swapusage
  printf 'captures-before=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
  printf 'floor-latest-before=%s\n' "$(cat "$s/notes/verification/floor-latest")"
} > "$r/s27-floorrun.pre" 2>&1
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
( while kill -0 "$wrapper" 2>/dev/null; do sample; sleep 60; done ) >> "$r/s27-floorrun.samples.log" 2>&1 &
sampler=$!
caffeinate -i -m -s bash -c 'bash scripts/spec-gate.sh floor "$1" > "$2" 2>&1; printf "%s\n" "$?" > "$3"' \
  _ "$s" "$r/s27-floorrun.log" "$r/s27-floorrun.rc"
kill "$sampler" 2>/dev/null; wait "$sampler" 2>/dev/null
{ sample; printf 'floor returned; rc file: %s\n' "$(cat "$r/s27-floorrun.rc" 2>/dev/null || echo MISSING)"; } >> "$r/s27-floorrun.samples.log" 2>&1
{
  printf 'end=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'captures-after=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
  printf 'floor-latest-after=%s\n' "$(cat "$s/notes/verification/floor-latest")"
  df -h / | tail -1
  sysctl -n vm.swapusage
} >> "$r/s27-floorrun.pre" 2>&1
post_rc=0
bash "$out/verify-prepublish.sh" > "$r/s27-floorrun.binding-after.log" 2>&1 || post_rc=$?
if [[ "$post_rc" == 0 ]]; then
  cp "$out/inputs-after.nul" "$r/s27-floorrun.source-after.nul" || post_rc=97
  cp "$out/verification-final.json" "$r/s27-floorrun.binding-after.json" || post_rc=97
fi
rc="$(cat "$r/s27-floorrun.rc" 2>/dev/null)"
printf 'floor attempt %s exit=%s\n' "$n" "${rc:-MISSING}"
[[ "$rc" =~ ^[0-9]+$ ]] || exit 99
[[ "$post_rc" == 0 ]] || exit 97
if [[ "$rc" == 0 ]]; then
  after_floor="$(cat "$s/notes/verification/floor-latest")"
  [[ "$after_floor" == FLOOR-* && "$after_floor" != "$before_floor" ]] || exit 97
  printf '%s\n' "$after_floor" > "$r/s27-floorrun.floor-id"
fi
exit "$rc"
