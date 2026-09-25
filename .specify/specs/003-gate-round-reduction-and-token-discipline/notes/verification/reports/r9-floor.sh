#!/usr/bin/env bash
# Floor for opponent round 9 (and, only on CLEARED, reality-check round 2).
# Usage from the worktree root: bash <this> <attempt-number>
# The floor's own exit code is written from inside the caffeinate wrapper, so
# no trailing command can stand in for it; read r9-floor-<n>.rc back after.
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
n="${1:?attempt number}"
[[ ! -e "$r/r9-floor-$n.rc" ]] || { echo "refusing: attempt $n already has a receipt" >&2; exit 2; }
{
  printf 'start=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  df -h / | tail -1
  sysctl -n vm.swapusage
  printf 'captures-before=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
} > "$r/r9-floor-$n.pre" 2>&1
caffeinate -i -m -s bash -c 'bash scripts/spec-gate.sh floor "$1" > "$2" 2>&1; printf "%s\n" "$?" > "$3"' \
  _ "$s" "$r/r9-floor-$n.log" "$r/r9-floor-$n.rc"
{
  printf 'end=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'captures-after=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
} >> "$r/r9-floor-$n.pre" 2>&1
rc="$(cat "$r/r9-floor-$n.rc" 2>/dev/null)"
printf 'floor attempt %s exit=%s\n' "$n" "${rc:-MISSING}"
[[ "$rc" =~ ^[0-9]+$ ]] || exit 99
exit "$rc"
