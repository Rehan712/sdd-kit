#!/usr/bin/env bash
# Session 25 (2026-10-17): the shell-only steps after the round-23 floor, chained so that no model turn waits on them
# (the user asked to finish the floors without running any model). Waits for r23-floor-1.wrapper.rc, then, only if the
# floor and its wrapper exit 0: r23-gate-step.sh validate FLOOR-<id> (r23-floor-validate.*), then r23-scope.sh
# FLOOR-<id> (r23-scope.{log,rc}). It reserves nothing and edits nothing outside notes/verification/reports/.
# Launch detached from the worktree root:
#   nohup bash <this> > <reports>/r23-after-floor.log 2>&1 &
# Its own exit goes to r23-after-floor.rc.
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
fin() { echo "$1" > "$r/r23-after-floor.rc"; printf '%s after-floor exit=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1"; exit "$1"; }
printf '%s waiting for the floor\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
while [[ ! -e "$r/r23-floor-1.wrapper.rc" ]]; do sleep 60; done
sleep 5
printf '%s floor rc=%s wrapper rc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(cat "$r/r23-floor-1.rc" 2>/dev/null || echo MISSING)" "$(cat "$r/r23-floor-1.wrapper.rc")"
[[ "$(cat "$r/r23-floor-1.rc" 2>/dev/null)" == 0 && "$(cat "$r/r23-floor-1.wrapper.rc")" == 0 ]] || fin 3
id="$(grep -o -E '^result=FLOOR-[A-Za-z0-9.-]+' "$r/r23-floor-1.log" | tail -1 | cut -d= -f2)"
[[ "$id" =~ ^FLOOR-[A-Za-z0-9.-]+$ ]] || fin 4
[[ "$(cat "$s/notes/verification/floor-latest")" == "$id" ]] || fin 5
printf 'floor=%s\n' "$id"
bash "$r/r23-gate-step.sh" validate "$id"
[[ "$(cat "$r/r23-floor-validate.rc")" == 0 && ! -s "$r/r23-floor-validate.err" ]] || fin 6
printf 'validate printed source=%s; frozen source=%s\n' "$(cat "$r/r23-floor-validate.out")" "$(grep -E '^source=' "$r/r23-freeze.txt" | cut -d= -f2)"
[[ "$(cat "$r/r23-floor-validate.out")" == "$(grep -E '^source=' "$r/r23-freeze.txt" | cut -d= -f2)" ]] || fin 7
bash "$r/r23-scope.sh" "$id" > "$r/r23-scope.log" 2>&1; echo $? > "$r/r23-scope.rc"
printf 'scope rc=%s\n' "$(cat "$r/r23-scope.rc")"
sed -n '/== distinct paths ==/,$p' "$r/r23-scope.log"
[[ "$(cat "$r/r23-scope.rc")" == 0 ]] || fin 8
fin 0
