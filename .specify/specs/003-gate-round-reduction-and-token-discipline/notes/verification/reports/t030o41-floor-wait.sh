#!/usr/bin/env bash
# The user's choice, 2026-09-25: start the fresh floor only when free disk
# reaches the threshold, watching for at most the window; otherwise start
# nothing and stop, with the floor left as the next session's first step.
# Nothing is deleted. Usage (worktree root): bash <this> [threshold-GiB] [window-minutes]
# Receipts: t030o41-floor-wait.log (one sample a minute, then the outcome) and
# t030o41-floor-wait.rc: 0 = the floor ran and exited 0; 1-98 = the floor's own
# nonzero exit; 97 = the threshold was never reached (floor not started).
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
need="${1:-8}" window="${2:-120}"
log="$r/t030o41-floor-wait.log"
avail() { df -k / | awk 'NR==2{printf "%.2f", $4/1048576}'; }
printf 'start=%s threshold=%sGiB window=%smin\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$need" "$window" >> "$log"
for ((m = 0; m <= window; m++)); do
  a="$(avail)"
  printf '%s avail=%sGiB swap_used=%s\n' "$(date -u +%H:%M:%SZ)" "$a" "$(sysctl -n vm.swapusage | awk '{print $6}')" >> "$log"
  if awk -v a="$a" -v n="$need" 'BEGIN {exit !(a >= n)}'; then
    printf 'threshold reached at %s (avail=%sGiB): starting floor attempt 1\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$a" >> "$log"
    bash "$r/t030o41-floor.sh" 1; rc=$?
    printf 'floor attempt 1 returned %s at %s (read t030o41-floor-1.rc)\n' "$rc" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$log"
    exit "$rc"
  fi
  (( m == window )) || sleep 60
done
printf 'threshold not reached within %s minutes: floor NOT started (%s)\n' "$window" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$log"
exit 97
