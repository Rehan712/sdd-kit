#!/usr/bin/env bash
# Entry audit for the round-12 session, 2026-09-26. Read-only. Run from the worktree root.
# Pattern: r11-entry-audit.sh. Re-derives every load-bearing handoff claim from the scripts.
# Tripwire is content-based (source digest and git status of non-bookkeeping paths), not
# directory mtimes, because vf_floor_validate creates and removes floor-check.XXXXXX by design.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/r12-entry.XXXXXX")"; trap 'rm -rf "$t"' EXIT
fails=0
chk() { local label="$1"; shift; if "$@"; then printf 'PASS %s\n' "$label"; else printf 'FAIL %s\n' "$label"; fails=$((fails+1)); fi; }
gs() { git status --porcelain -uall | grep -v -F "$s/notes/verification/" | LC_ALL=C sort | vf_hash /dev/stdin; }
gs_before="$(gs)"
src_before="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs-before.nul")"

for gate in opponent reality-check; do
  vf_round_history "$s" "$gate" "$t" || { echo "FAIL history $gate"; fails=$((fails+1)); continue; }
  pending=0; for l in "$s/notes/verification/rounds/$gate"/ROUND-*; do vf_integrity "$l" meta.nul || fails=$((fails+1)); [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
  printf '%s sealed rounds=%s last-time=%s pending=%s\n' "$gate" "$VF_ROUND_LAST" "$VF_ROUND_TIME" "$pending"; [[ "$pending" == 0 ]] || fails=$((fails+1))
done
chk 'opponent ledger has exactly ROUND-1..ROUND-11' test "$(ls "$s/notes/verification/rounds/opponent" | LC_ALL=C sort -t- -k2 -n | tr '\n' ' ')" == 'ROUND-1 ROUND-2 ROUND-3 ROUND-4 ROUND-5 ROUND-6 ROUND-7 ROUND-8 ROUND-9 ROUND-10 ROUND-11 '
chk 'reality-check ledger has exactly ROUND-1' test "$(ls "$s/notes/verification/rounds/reality-check" | tr '\n' ' ')" == 'ROUND-1 '
chk 'no staged .reservation-* in either gate' test -z "$(find "$s/notes/verification/rounds/opponent" "$s/notes/verification/rounds/reality-check" -mindepth 1 -maxdepth 1 -name '.*' -print)"
for n in 1 2 3 4 5 6 7 8 9 10 11; do
  vf_report_block "$s/notes/opponent.md" "$n" > "$t/b"
  sealed="$(cat "$s/notes/verification/rounds/opponent/ROUND-$n/report.sha256")"
  chk "opponent round $n block digest == sealed ${sealed:0:16}" test "$(vf_hash "$t/b")" == "$sealed"
done
chk 'opponent round 11 sealed == f13a332b34a8...' test "$(cat "$s/notes/verification/rounds/opponent/ROUND-11/report.sha256")" == f13a332b34a800dae186b94b7d7a19221e468a92c91add10345da8ab5f1ef0d7
vf_report_block "$r/opponent-round11.md" 11 > "$t/ret"
chk 'returned round-11 report block == sealed round-11 digest' test "$(vf_hash "$t/ret")" == "$(cat "$s/notes/verification/rounds/opponent/ROUND-11/report.sha256")"
vf_report_block "$s/notes/reality-check.md" 1 > "$t/b"
chk 'reality-check round 1 block digest == sealed' test "$(vf_hash "$t/b")" == "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")"
chk 'reality-check round 1 sealed == e5f957dbd673...' test "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")" == e5f957dbd67335502a151c5198881e32310fb4a003363c684384565c9ddaa748

chk "source == 37cfccef... ($src_before)" test "$src_before" == 37cfccef3868bfd3939995882b5383d2f691b811cbb0dd0a754fe4bee68f16e1
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"; dec="$(vf_hash "$t/decisions")"
chk "Decisions digest == bd157c7a... ($dec)" test "$dec" == bd157c7ab9e055ddd9b976d4aa2728d303716a8c021b0e678a470e11c49f29e9

chk 'floor-latest == FLOOR-QeBcq3' test "$(cat "$s/notes/verification/floor-latest")" == FLOOR-QeBcq3
vf_floor_validate "$s" FLOOR-QeBcq3 > "$t/fv.out" 2> "$t/fv.err"; rc=$?
printf '  FLOOR-QeBcq3 validate rc=%s stderr=%s\n' "$rc" "$(cat "$t/fv.err")"
chk 'FLOOR-QeBcq3 refused at exit 3 as stale' test "$rc:$(cat "$t/fv.err")" == '3:floor stale: refresh floor for current inputs'
chk 'no held lock' test ! -e "$s/notes/verification/lock"
chk 'no .capture.* staging anywhere under notes/' test -z "$(find "$s/notes" -name '.capture.*' -print -quit)"
caps="$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
chk "captures == 492 ($caps)" test "$caps" == 492
chk "HEAD == 0d55c62 ($(git rev-parse --short HEAD))" test "$(git rev-parse --short HEAD)" == 0d55c62
for task in T030 T031 T032 T033 T034; do chk "$task unchecked" grep -q -F -- "- [ ] **$task**" "$s/tasks.md"; done
for task in T030o39 T030o40 T030o41; do chk "$task checked" grep -q -F -- "- [x] **$task**" "$s/tasks.md"; done
chk 'no T030o42 task block yet' test -z "$(grep -n -F '**T030o42**' "$s/tasks.md")"

bash scripts/spec-gate.sh waiver "$s" opponent 12 > "$t/w12" 2>&1; rc=$?
sed 's/^/  w12| /' "$t/w12"
chk 'round 12 authorized at exit 0' test "$rc:$(cat "$t/w12")" == '0:authorized: opponent round 12'
bash scripts/spec-gate.sh waiver "$s" opponent 13 > "$t/w13" 2>&1; rc=$?
sed 's/^/  w13| /' "$t/w13"
chk "round 13 refused at exit 4 with 10 candidates ($(grep -c -E 'STATUS\.md:[0-9]+' "$t/w13"))" test "$rc:$(grep -c -E 'STATUS\.md:[0-9]+' "$t/w13")" == '4:10'
chk 'round-12 waiver line present verbatim' grep -q -x -F -- '- 2026-09-26T19:06:23Z — waiver: gate=opponent; round=12; after=11; by=Rehan712; reason=user authorized round 12 on 2026-09-26 to assess the T030o42 repair of O-016 against a fresh floor sealed after that repair is accepted' "$s/STATUS.md"

bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; rc=$?
chk 'tally exit 0' test "$rc" == 0
sed 's/^/  /' "$t/tally"
chk 'tally byte-identical to r11-tally.log (opponent=11 blocking=25 minor=10 locations=348 obs=51 ids=16 reopened=25 downgrades=5 captures=492)' cmp -s "$t/tally" "$r/r11-tally.log"

printf '  host: %s\n' "$(df -h / | tail -1)"
printf '  swap: %s\n' "$(sysctl -n vm.swapusage)"
printf '  power: %s\n' "$(pmset -g batt | tr '\n' ' ')"

src_after="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs-after.nul")"
chk 'tripwire: source unchanged by this audit' test "$src_after" == "$src_before"
chk 'tripwire: non-bookkeeping git status unchanged' test "$(gs)" == "$gs_before"
printf 'entry audit failures=%s\n' "$fails"
(( fails == 0 ))
