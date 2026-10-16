#!/usr/bin/env bash
# Entry audit for session 8 of T030o43, 2026-09-29. Read-only. Run from the worktree root.
# Pattern: r12-entry-audit.sh. Re-derives every load-bearing claim of t030o43-handoff-state.txt.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/t030o43-entry8.XXXXXX")"; trap 'rm -rf "$t"' EXIT
fails=0
chk() { local label="$1"; shift; if "$@"; then printf 'PASS %s\n' "$label"; else printf 'FAIL %s\n' "$label"; fails=$((fails+1)); fi; }
gs() { git status --porcelain -uall | grep -v -F "$s/notes/verification/" | LC_ALL=C sort | vf_hash /dev/stdin; }
gs_before="$(gs)"
src_before="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs-before.nul")"
chk "source == c2536743... ($src_before)" test "$src_before" == c2536743df65d193c2bd9530443400b80d69923ccf6f73b72f572db06e7cadce
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"; dec="$(vf_hash "$t/decisions")"
chk "Decisions digest == df18ccde... ($dec)" test "$dec" == df18ccdee684b14c47ea29381dedc75788dbc171ac5fc4b49aacc7fede71621a
chk "HEAD == 0d55c62 ($(git rev-parse --short HEAD))" test "$(git rev-parse --short HEAD)" == 0d55c62
chk 'no held lock' test ! -e "$s/notes/verification/lock"
for gate in opponent reality-check; do
  vf_round_history "$s" "$gate" "$t" || { echo "FAIL history $gate"; fails=$((fails+1)); continue; }
  pending=0; for l in "$s/notes/verification/rounds/$gate"/ROUND-*; do vf_integrity "$l" meta.nul || fails=$((fails+1)); [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
  printf '%s sealed rounds=%s last-time=%s pending=%s\n' "$gate" "$VF_ROUND_LAST" "$VF_ROUND_TIME" "$pending"; [[ "$pending" == 0 ]] || fails=$((fails+1))
done
chk 'opponent ledger has exactly ROUND-1..ROUND-12' test "$(ls "$s/notes/verification/rounds/opponent" | LC_ALL=C sort -t- -k2 -n | tr '\n' ' ')" == 'ROUND-1 ROUND-2 ROUND-3 ROUND-4 ROUND-5 ROUND-6 ROUND-7 ROUND-8 ROUND-9 ROUND-10 ROUND-11 ROUND-12 '
chk 'reality-check ledger has exactly ROUND-1' test "$(ls "$s/notes/verification/rounds/reality-check" | tr '\n' ' ')" == 'ROUND-1 '
chk 'no staged .reservation-* in either gate' test -z "$(find "$s/notes/verification/rounds/opponent" "$s/notes/verification/rounds/reality-check" -mindepth 1 -maxdepth 1 -name '.*' -print)"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do
  vf_report_block "$s/notes/opponent.md" "$n" > "$t/b"
  sealed="$(cat "$s/notes/verification/rounds/opponent/ROUND-$n/report.sha256")"
  chk "opponent round $n block digest == sealed ${sealed:0:16}" test "$(vf_hash "$t/b")" == "$sealed"
done
chk 'floor-latest == FLOOR-0334B2' test "$(cat "$s/notes/verification/floor-latest")" == FLOOR-0334B2
vf_floor_validate "$s" FLOOR-0334B2 > "$t/fv.out" 2> "$t/fv.err"; rc=$?
chk 'FLOOR-0334B2 refused at exit 3 as stale (historical)' test "$rc:$(cat "$t/fv.err")" == '3:floor stale: refresh floor for current inputs'
chk 'no .capture.* staging anywhere under notes/' test -z "$(find "$s/notes" -name '.capture.*' -print -quit)"
caps="$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
chk "captures == 514 ($caps)" test "$caps" == 514
for task in T030 T031 T032 T033 T034 T030o43; do chk "$task unchecked" grep -q -F -- "- [ ] **$task**" "$s/tasks.md"; done
for task in T030o39 T030o40 T030o41 T030o42; do chk "$task checked" grep -q -F -- "- [x] **$task**" "$s/tasks.md"; done
bash scripts/spec-gate.sh waiver "$s" opponent 13 > "$t/w13" 2>&1; rc=$?
chk 'round 13 authorized at exit 0' test "$rc:$(cat "$t/w13")" == '0:authorized: opponent round 13'
bash scripts/spec-gate.sh waiver "$s" opponent 14 > "$t/w14" 2>&1; rc=$?
chk "round 14 refused at exit 4 ($(grep -c -E 'STATUS\.md:[0-9]+' "$t/w14") candidates)" test "$rc" == 4
bash scripts/sdd-analyze.sh "$s" > "$t/an" 2>&1; rc=$?
chk "analyzer exit 0 ($(tail -1 "$t/an"))" test "$rc" == 0
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; rc=$?
chk 'tally exit 0' test "$rc" == 0
chk 'tally byte-identical to r12-tally.log' cmp -s "$t/tally" "$r/r12-tally.log"
printf '  host: %s\n' "$(df -h / | tail -1)"
printf '  swap: %s\n' "$(sysctl -n vm.swapusage)"
printf '  power: %s\n' "$(pmset -g batt | tr '\n' ' ')"
src_after="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs-after.nul")"
chk 'tripwire: source unchanged by this audit' test "$src_after" == "$src_before"
chk 'tripwire: non-bookkeeping git status unchanged' test "$(gs)" == "$gs_before"
printf 'entry audit failures=%s\n' "$fails"
(( fails == 0 ))
