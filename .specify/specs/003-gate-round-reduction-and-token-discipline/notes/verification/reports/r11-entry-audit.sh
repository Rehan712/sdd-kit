#!/usr/bin/env bash
# Entry audit for the round-11 session, 2026-09-26. Read-only. Run from the worktree root.
# Pattern: r10-entry-audit.sh. Re-derives every load-bearing handoff claim from the scripts.
# Tripwire is content-based (source digest and git status of non-bookkeeping paths), not
# directory mtimes, because vf_floor_validate creates and removes floor-check.XXXXXX by design.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
t="$(mktemp -d "${TMPDIR:-/tmp}/r11-entry.XXXXXX")"; trap 'rm -rf "$t"' EXIT
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
chk 'opponent ledger has exactly ROUND-1..ROUND-10' test "$(ls "$s/notes/verification/rounds/opponent" | LC_ALL=C sort -t- -k2 -n | tr '\n' ' ')" == 'ROUND-1 ROUND-2 ROUND-3 ROUND-4 ROUND-5 ROUND-6 ROUND-7 ROUND-8 ROUND-9 ROUND-10 '
chk 'reality-check ledger has exactly ROUND-1' test "$(ls "$s/notes/verification/rounds/reality-check" | tr '\n' ' ')" == 'ROUND-1 '
chk 'no staged .reservation-* in either gate' test -z "$(find "$s/notes/verification/rounds/opponent" "$s/notes/verification/rounds/reality-check" -mindepth 1 -maxdepth 1 -name '.*' -print)"
for n in 1 2 3 4 5 6 7 8 9 10; do
  vf_report_block "$s/notes/opponent.md" "$n" > "$t/b"
  sealed="$(cat "$s/notes/verification/rounds/opponent/ROUND-$n/report.sha256")"
  chk "opponent round $n block digest == sealed ${sealed:0:16}" test "$(vf_hash "$t/b")" == "$sealed"
done
chk 'opponent round 10 sealed == 9a32b0929d7a...' test "$(cat "$s/notes/verification/rounds/opponent/ROUND-10/report.sha256")" == 9a32b0929d7acc5a26a929bd0e449b1233f8ef966075610133b2fdb68291e331
vf_report_block "$s/notes/reality-check.md" 1 > "$t/b"
chk 'reality-check round 1 block digest == sealed' test "$(vf_hash "$t/b")" == "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")"
chk 'reality-check round 1 sealed == e5f957dbd673...' test "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")" == e5f957dbd67335502a151c5198881e32310fb4a003363c684384565c9ddaa748

chk "source == 1fba08ed... ($src_before)" test "$src_before" == 1fba08ed13e83cbca56ef731047f39c3668dfa47c4ff81873de63ee2eea3b0b0
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"; dec="$(vf_hash "$t/decisions")"
chk "Decisions digest == 28cb38d3... ($dec)" test "$dec" == 28cb38d3140df2a7a4fd4ae21f549801dcc19a516ed27c2a1eeda605cdab2d7c

chk 'floor-latest == FLOOR-6eaaRv' test "$(cat "$s/notes/verification/floor-latest")" == FLOOR-6eaaRv
vf_floor_validate "$s" FLOOR-6eaaRv > "$t/fv.out" 2> "$t/fv.err"; rc=$?
printf '  FLOOR-6eaaRv validate rc=%s stderr=%s\n' "$rc" "$(cat "$t/fv.err")"
chk 'FLOOR-6eaaRv refused at exit 3 as stale' test "$rc:$(cat "$t/fv.err")" == '3:floor stale: refresh floor for current inputs'
chk 'CAP-455-RNmM6l input_before == e07efa81... (historical)' test "$(tr '\0' '\n' < "$s/notes/captures/CAP-455-RNmM6l/meta.nul" | grep -A1 -x input_before | tail -1)" == e07efa818886b08fd028b3a038921ae58d2774c6926a86394712014e86a50536
chk 'no held lock' test ! -e "$s/notes/verification/lock"
chk 'no .capture.* staging anywhere under notes/' test -z "$(find "$s/notes" -name '.capture.*' -print -quit)"
printf '  captures=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
chk "HEAD == 0d55c62 ($(git rev-parse --short HEAD))" test "$(git rev-parse --short HEAD)" == 0d55c62
for task in T030 T031 T032 T033 T034; do chk "$task unchecked" grep -q -F -- "- [ ] **$task**" "$s/tasks.md"; done
for task in T030o39 T030o40 T030o41; do chk "$task checked" grep -q -F -- "- [x] **$task**" "$s/tasks.md"; done

bash scripts/spec-gate.sh waiver "$s" opponent 11 > "$t/w11" 2>&1; rc=$?
sed 's/^/  w11| /' "$t/w11"
chk 'round 11 authorized at exit 0' test "$rc:$(cat "$t/w11")" == '0:authorized: opponent round 11'
bash scripts/spec-gate.sh waiver "$s" opponent 12 > "$t/w12" 2>&1; rc=$?
sed 's/^/  w12| /' "$t/w12"
chk "round 12 refused at exit 4 with 9 candidates ($(grep -c -E 'STATUS\.md:[0-9]+' "$t/w12"))" test "$rc:$(grep -c -E 'STATUS\.md:[0-9]+' "$t/w12")" == '4:9'
chk 'waiver line present verbatim' grep -q -x -F -- '- 2026-09-26T11:09:20Z — waiver: gate=opponent; round=11; after=10; by=Rehan712; reason=user authorized round 11 on 2026-09-26 to assess the accepted T030o41 repair of O-015 against a fresh floor sealed on the source that records this authorization' "$s/STATUS.md"

bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; rc=$?
chk 'tally exit 0' test "$rc" == 0
sed 's/^/  /' "$t/tally"
chk 'tally opponent rounds=10' grep -q -x 'opponent rounds=10' "$t/tally"
chk 'tally reality-check rounds=1' grep -q -x 'reality-check rounds=1' "$t/tally"
chk 'tally blocking=24 minor=10 locations=326 unclassified=0' grep -q -x 'blocking=24 minor=10 locations=326 unclassified=0' "$t/tally"
chk 'tally severity-downgrades=5' grep -q -x 'severity-downgrades=5' "$t/tally"

src_after="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs-after.nul")"
chk 'tripwire: source unchanged by this audit' test "$src_after" == "$src_before"
chk 'tripwire: non-bookkeeping git status unchanged' test "$(gs)" == "$gs_before"
printf 'entry audit failures=%s\n' "$fails"
(( fails == 0 ))
