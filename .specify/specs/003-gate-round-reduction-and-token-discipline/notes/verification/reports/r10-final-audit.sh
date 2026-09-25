#!/usr/bin/env bash
# Final audit after opponent round 10, 2026-09-24. Read-only. Run from the worktree root.
# Identities come from the ROUND-10 reservation record, not from this text.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/r10-final.XXXXXX")"; trap 'rm -rf "$t"' EXIT
fails=0
chk() { local label="$1"; shift; if "$@"; then printf 'PASS %s\n' "$label"; else printf 'FAIL %s\n' "$label"; fails=$((fails+1)); fi; }
meta() { tr '\0' '\n' < "$1" | grep -A1 -x "$2" | tail -1; }
L="$s/notes/verification/rounds/opponent/ROUND-10"
rsrc="$(meta "$L/meta.nul" source)"; rfloor="$(meta "$L/meta.nul" floor)"; rres="$(meta "$L/meta.nul" reserved)"
printf 'ROUND-10 reservation: source=%s floor=%s reserved=%s\n' "$rsrc" "$rfloor" "$rres"
chk 'ROUND-10 reservation integrity' vf_integrity "$L" meta.nul
chk 'ROUND-10 sealed (report.sha256 present)' test -f "$L/report.sha256"
for gate in opponent reality-check; do
  vf_round_history "$s" "$gate" "$t" || { echo "FAIL history $gate"; fails=$((fails+1)); continue; }
  pending=0; for l in "$s/notes/verification/rounds/$gate"/ROUND-*; do vf_integrity "$l" meta.nul || fails=$((fails+1)); [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
  printf '%s sealed rounds=%s pending=%s\n' "$gate" "$VF_ROUND_LAST" "$pending"; [[ "$pending" == 0 ]] || fails=$((fails+1))
done
chk 'no staged .reservation-* in either gate' test -z "$(find "$s/notes/verification/rounds/opponent" "$s/notes/verification/rounds/reality-check" -mindepth 1 -maxdepth 1 -name '.*' -print)"
for n in 1 2 3 4 5 6 7 8 9 10; do
  vf_report_block "$s/notes/opponent.md" "$n" > "$t/b"
  sealed="$(cat "$s/notes/verification/rounds/opponent/ROUND-$n/report.sha256")"
  chk "opponent round $n canonical block == sealed ${sealed:0:16}" test "$(vf_hash "$t/b")" == "$sealed"
done
vf_report_block "$r/opponent-round10.md" 10 > "$t/ret"
chk 'returned report block == sealed round-10 digest' test "$(vf_hash "$t/ret")" == "$(cat "$L/report.sha256")"
vf_report_block "$s/notes/reality-check.md" 1 > "$t/b"
chk 'reality-check round 1 canonical block == sealed' test "$(vf_hash "$t/b")" == "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")"
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
chk "source == reserved source ($src)" test "$src" == "$rsrc"
chk 'source == 6c6291c2... (the authorization batch source)' test "$src" == 6c6291c2b37d35fb82c67c42c173ae042bb116c742f1c84a5dfa9c1c77c04c2d
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"; dec="$(vf_hash "$t/decisions")"
chk "Decisions digest unchanged f6722f8a... ($dec)" test "$dec" == f6722f8ab1e0dd1340eb07b1cd940d6bc1e5d935fb58987cc3ffb0869612ee44
chk "floor-latest == reserved floor ($rfloor)" test "$(cat "$s/notes/verification/floor-latest")" == "$rfloor"
chk "$rfloor validates current for the reserved source" test "$(vf_floor_validate "$s" "$rfloor" 2>/dev/null)" == "$rsrc"
chk 'no held lock' test ! -e "$s/notes/verification/lock"
chk 'no .capture.* staging anywhere under notes/' test -z "$(find "$s/notes" -name '.capture.*' -print -quit)"
chk "HEAD == 0d55c62 ($(git rev-parse --short HEAD))" test "$(git rev-parse --short HEAD)" == 0d55c62
for task in T030 T031 T032 T033 T034; do chk "$task unchecked" grep -q -F -- "- [ ] **$task**" "$s/tasks.md"; done
for task in T030o39 T030o40; do chk "$task checked" grep -q -F -- "- [x] **$task**" "$s/tasks.md"; done
bash scripts/spec-gate.sh waiver "$s" opponent 10 > "$t/w10" 2>&1; rc=$?
sed 's/^/  w10| /' "$t/w10"
chk 'round 10 reported completed at exit 0' test "$rc:$(cat "$t/w10")" == '0:opponent round 10 is already completed; the next round is 11'
bash scripts/spec-gate.sh waiver "$s" opponent 11 > "$t/w11" 2>&1; rc=$?
sed 's/^/  w11| /' "$t/w11"
chk "round 11 refused at exit 4 with 8 candidates ($(grep -c -E 'STATUS\.md:[0-9]+' "$t/w11"))" test "$rc:$(grep -c -E 'STATUS\.md:[0-9]+' "$t/w11")" == '4:8'
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; rc=$?
chk 'tally exit 0' test "$rc" == 0
chk 'tally opponent rounds=10' grep -q -x 'opponent rounds=10' "$t/tally"
sed 's/^/  /' "$t/tally"
printf 'final audit failures=%s\n' "$fails"
(( fails == 0 ))
