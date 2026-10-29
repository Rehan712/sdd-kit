#!/usr/bin/env bash
# Final audit after opponent round 21, 2026-10-16 (session 24). Read-only. Run from the worktree root.
# Pattern: r20-final-audit.sh. Identities come from the ROUND-21 reservation record and the freeze point
# r21-freeze.txt, not from this text. vf_floor_validate takes over 10 minutes: run this in the background with receipts.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/r21-final.XXXXXX")"; trap 'rm -rf "$t"' EXIT
fails=0
chk() { local label="$1"; shift; if "$@"; then printf 'PASS %s\n' "$label"; else printf 'FAIL %s\n' "$label"; fails=$((fails+1)); fi; }
meta() { tr '\0' '\n' < "$1" | grep -A1 -x "$2" | tail -1; }
L="$s/notes/verification/rounds/opponent/ROUND-21"
fz() { grep -E "^$1=" "$r/r21-freeze.txt" | head -1 | cut -d= -f2 | cut -d" " -f1; }
FSRC="$(fz source)"; FDEC="$(fz decisions)"
rsrc="$(meta "$L/meta.nul" source)"; rfloor="$(meta "$L/meta.nul" floor)"; rres="$(meta "$L/meta.nul" reserved)"
printf 'ROUND-21 reservation: source=%s floor=%s reserved=%s\n' "$rsrc" "$rfloor" "$rres"
chk 'ROUND-21 reservation integrity' vf_integrity "$L" meta.nul
chk 'ROUND-21 sealed (report.sha256 present)' test -f "$L/report.sha256"
for gate in opponent reality-check; do
  vf_round_history "$s" "$gate" "$t" || { echo "FAIL history $gate"; fails=$((fails+1)); continue; }
  pending=0; for l in "$s/notes/verification/rounds/$gate"/ROUND-*; do vf_integrity "$l" meta.nul || fails=$((fails+1)); [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
  printf '%s sealed rounds=%s pending=%s\n' "$gate" "$VF_ROUND_LAST" "$pending"; [[ "$pending" == 0 ]] || fails=$((fails+1))
done
chk 'no staged .reservation-* in either gate' test -z "$(find "$s/notes/verification/rounds/opponent" "$s/notes/verification/rounds/reality-check" -mindepth 1 -maxdepth 1 -name '.*' -print)"
for n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21; do
  vf_report_block "$s/notes/opponent.md" "$n" > "$t/b"
  sealed="$(cat "$s/notes/verification/rounds/opponent/ROUND-$n/report.sha256")"
  chk "opponent round $n canonical block == sealed ${sealed:0:16}" test "$(vf_hash "$t/b")" == "$sealed"
done
vf_report_block "$r/opponent-round21.md" 21 > "$t/ret"
chk 'returned report block == sealed round-21 digest' test "$(vf_hash "$t/ret")" == "$(cat "$L/report.sha256")"
for n in 1 2; do
  vf_report_block "$s/notes/reality-check.md" "$n" > "$t/b"
  chk "reality-check round $n canonical block == sealed" test "$(vf_hash "$t/b")" == "$(cat "$s/notes/verification/rounds/reality-check/ROUND-$n/report.sha256")"
done
chk 'reserved and returned worktree entries byte-identical' cmp -s "$r/r21-state-reserved.entries" "$r/r21-state-returned.entries"
chk 'reserved and returned state records equal (label/taken aside)' test "$(grep -v '^label=' "$r/r21-state-reserved.txt")" == "$(grep -v '^label=' "$r/r21-state-returned.txt")"
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
chk "source == reserved source ($src)" test "$src" == "$rsrc"
chk "source == frozen source ${FSRC:0:8}... ($src)" test "$src" == "$FSRC"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"; dec="$(vf_hash "$t/decisions")"
chk "Decisions digest unchanged ${FDEC:0:8}... ($dec)" test "$dec" == "$FDEC"
chk "floor-latest == reserved floor ($rfloor)" test "$(cat "$s/notes/verification/floor-latest")" == "$rfloor"
chk "$rfloor validates current for the reserved source" test "$(vf_floor_validate "$s" "$rfloor" 2>/dev/null)" == "$rsrc"
chk 'no held lock' test ! -e "$s/notes/verification/lock"
chk 'no .capture.* staging anywhere under notes/' test -z "$(find "$s/notes" -name '.capture.*' -print -quit)"
chk "HEAD == 2049f65 ($(git rev-parse --short HEAD))" test "$(git rev-parse --short HEAD)" == 2049f65
for task in T030 T031 T032 T033 T034; do chk "$task unchecked" grep -q -F -- "- [ ] **$task**" "$s/tasks.md"; done
for task in T030o39 T030o40 T030o41 T030o42 T030o43 T030o44 T030o45 T030o46 T030o47 T030o48 T030o49 T030o50 T030o51 T030o52 T030o53 T030o54 T030o55 T030o56 T031a1 T031a2 T031a3 T031a4 T031a1o1 T031a3o1 T031a4o1; do chk "$task checked" grep -q -F -- "- [x] **$task**" "$s/tasks.md"; done
chk 'prereserve and reserved worktree entries byte-identical' cmp -s "$r/r21-state-prereserve.entries" "$r/r21-state-reserved.entries"
bash scripts/spec-gate.sh waiver "$s" opponent 21 > "$t/w21" 2>&1; rc=$?
sed "s/^/  w21| /" "$t/w21"
chk "round 21 reported completed at exit 0" test "$rc:$(cat "$t/w21")" == "0:opponent round 21 is already completed; the next round is 22"
bash scripts/spec-gate.sh waiver "$s" opponent 22 > "$t/w22" 2>&1; rc=$?
sed "s/^/  w22| /" "$t/w22"
chk "round 22 refused at exit 4 ($(grep -c -E "STATUS\\.md:[0-9]+" "$t/w22") candidates)" test "$rc" == 4
chk 'round 22 refusal names no line that authorizes round=22' test "$(grep -c 'authorizes round=22' "$t/w22")" == 0
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; rc=$?
chk 'tally exit 0' test "$rc" == 0
chk "tally opponent rounds=21" grep -q -x "opponent rounds=21" "$t/tally"
chk "tally reality-check rounds=2" grep -q -x "reality-check rounds=2" "$t/tally"
sed 's/^/  /' "$t/tally"
printf 'final audit failures=%s\n' "$fails"
(( fails == 0 ))
