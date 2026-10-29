#!/usr/bin/env bash
# Entry audit for the round-10 session, 2026-09-24. Read-only. Run from the worktree root.
# Re-derives every load-bearing handoff claim from the scripts. Tripwire is content-based
# (source digest and git status of non-bookkeeping paths), not directory mtimes, because
# vf_floor_validate creates and removes notes/verification/floor-check.XXXXXX by design.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
t="$(mktemp -d "${TMPDIR:-/tmp}/r10-entry.XXXXXX")"; trap 'rm -rf "$t"' EXIT
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
chk 'opponent ledger has exactly ROUND-1..ROUND-9' test "$(ls "$s/notes/verification/rounds/opponent" | tr '\n' ' ')" == 'ROUND-1 ROUND-2 ROUND-3 ROUND-4 ROUND-5 ROUND-6 ROUND-7 ROUND-8 ROUND-9 '
chk 'no staged .reservation-* in either gate' test -z "$(find "$s/notes/verification/rounds/opponent" "$s/notes/verification/rounds/reality-check" -mindepth 1 -maxdepth 1 -name '.*' -print)"
for n in 1 2 3 4 5 6 7 8 9; do
  vf_report_block "$s/notes/opponent.md" "$n" > "$t/b"
  sealed="$(cat "$s/notes/verification/rounds/opponent/ROUND-$n/report.sha256")"
  chk "opponent round $n block digest == sealed ${sealed:0:16}" test "$(vf_hash "$t/b")" == "$sealed"
done
vf_report_block "$s/notes/reality-check.md" 1 > "$t/b"
chk 'reality-check round 1 block digest == sealed e5f957db...' test "$(vf_hash "$t/b")" == "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")"
chk 'reality-check round 1 sealed == e5f957dbd673...' test "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")" == e5f957dbd67335502a151c5198881e32310fb4a003363c684384565c9ddaa748
chk 'opponent round 9 sealed == 2aae626e3c60...' test "$(cat "$s/notes/verification/rounds/opponent/ROUND-9/report.sha256")" == 2aae626e3c60020125ac2bab08a87d27da40ab4e63aa4f15988903feb690e83c

chk "source == 6c6291c2... ($src_before)" test "$src_before" == 6c6291c2b37d35fb82c67c42c173ae042bb116c742f1c84a5dfa9c1c77c04c2d
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"; dec="$(vf_hash "$t/decisions")"
chk "Decisions digest == f6722f8a... ($dec)" test "$dec" == f6722f8ab1e0dd1340eb07b1cd940d6bc1e5d935fb58987cc3ffb0869612ee44

chk 'floor-latest == FLOOR-oejTDu' test "$(cat "$s/notes/verification/floor-latest")" == FLOOR-oejTDu
vf_floor_validate "$s" FLOOR-oejTDu > "$t/fv.out" 2> "$t/fv.err"; rc=$?
printf '  FLOOR-oejTDu validate rc=%s stderr=%s\n' "$rc" "$(cat "$t/fv.err")"
chk 'FLOOR-oejTDu refused at exit 3 as stale' test "$rc:$(cat "$t/fv.err")" == '3:floor stale: refresh floor for current inputs'
for c in CAP-411-B8GLAC CAP-412-59sk66; do
  chk "$c input_before == d27bab53... (historical)" test "$(tr '\0' '\n' < "$s/notes/captures/$c/meta.nul" | grep -A1 -x input_before | tail -1)" == d27bab536454eead9135c5d502962488e653eef8277006b50eeb5d43b22b4466
done
chk 'no held lock' test ! -e "$s/notes/verification/lock"
chk 'no .capture.* staging anywhere under notes/' test -z "$(find "$s/notes" -name '.capture.*' -print -quit)"
chk "HEAD == 0d55c62 ($(git rev-parse --short HEAD))" test "$(git rev-parse --short HEAD)" == 0d55c62
for task in T030 T031 T032 T033 T034; do chk "$task unchecked" grep -q -F -- "- [ ] **$task**" "$s/tasks.md"; done
for task in T030o39 T030o40; do chk "$task checked" grep -q -F -- "- [x] **$task**" "$s/tasks.md"; done

bash scripts/spec-gate.sh waiver "$s" opponent 10 > "$t/w10" 2>&1; rc=$?
sed 's/^/  w10| /' "$t/w10"
chk 'round 10 authorized at exit 0' test "$rc:$(cat "$t/w10")" == '0:authorized: opponent round 10'
bash scripts/spec-gate.sh waiver "$s" opponent 11 > "$t/w11" 2>&1; rc=$?
sed 's/^/  w11| /' "$t/w11"
chk "round 11 refused at exit 4 with 8 candidates ($(grep -c -E 'STATUS\.md:[0-9]+' "$t/w11"))" test "$rc:$(grep -c -E 'STATUS\.md:[0-9]+' "$t/w11")" == '4:8'
chk 'waiver line present verbatim' grep -q -x -F -- '- 2026-09-23T17:33:27Z — waiver: gate=opponent; round=10; after=9; by=Rehan712; reason=user authorized round 10 on 2026-09-23 to assess the accepted T030o39 and T030o40 repairs of O-013 and O-014 against a fresh floor sealed on the source that records this authorization' "$s/STATUS.md"

bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; rc=$?
chk 'tally exit 0' test "$rc" == 0
sed 's/^/  /' "$t/tally"
chk 'tally opponent rounds=9' grep -q -x 'opponent rounds=9' "$t/tally"
chk 'tally blocking=23 minor=10 locations=291 unclassified=0' grep -q -x 'blocking=23 minor=10 locations=291 unclassified=0' "$t/tally"
chk 'tally severity-downgrades=5' grep -q -x 'severity-downgrades=5' "$t/tally"

src_after="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs-after.nul")"
chk 'tripwire: source unchanged by this audit' test "$src_after" == "$src_before"
chk 'tripwire: non-bookkeeping git status unchanged' test "$(gs)" == "$gs_before"
printf 'entry audit failures=%s\n' "$fails"
(( fails == 0 ))
