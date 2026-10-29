#!/usr/bin/env bash
# Final audit after opponent round 15, 2026-10-07 (session 15). Read-only. Run from the worktree root.
# Pattern: r14-final-audit.sh. Identities come from the ROUND-15 reservation record, not from
# this text. vf_floor_validate takes over 10 minutes: run this in the background with receipts.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/r15-final.XXXXXX")"; trap 'rm -rf "$t"' EXIT
fails=0
chk() { local label="$1"; shift; if "$@"; then printf 'PASS %s\n' "$label"; else printf 'FAIL %s\n' "$label"; fails=$((fails+1)); fi; }
meta() { tr '\0' '\n' < "$1" | grep -A1 -x "$2" | tail -1; }
L="$s/notes/verification/rounds/opponent/ROUND-15"
rsrc="$(meta "$L/meta.nul" source)"; rfloor="$(meta "$L/meta.nul" floor)"; rres="$(meta "$L/meta.nul" reserved)"
printf 'ROUND-15 reservation: source=%s floor=%s reserved=%s\n' "$rsrc" "$rfloor" "$rres"
chk 'ROUND-15 reservation integrity' vf_integrity "$L" meta.nul
chk 'ROUND-15 sealed (report.sha256 present)' test -f "$L/report.sha256"
for gate in opponent reality-check; do
  vf_round_history "$s" "$gate" "$t" || { echo "FAIL history $gate"; fails=$((fails+1)); continue; }
  pending=0; for l in "$s/notes/verification/rounds/$gate"/ROUND-*; do vf_integrity "$l" meta.nul || fails=$((fails+1)); [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
  printf '%s sealed rounds=%s pending=%s\n' "$gate" "$VF_ROUND_LAST" "$pending"; [[ "$pending" == 0 ]] || fails=$((fails+1))
done
chk 'no staged .reservation-* in either gate' test -z "$(find "$s/notes/verification/rounds/opponent" "$s/notes/verification/rounds/reality-check" -mindepth 1 -maxdepth 1 -name '.*' -print)"
for n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  vf_report_block "$s/notes/opponent.md" "$n" > "$t/b"
  sealed="$(cat "$s/notes/verification/rounds/opponent/ROUND-$n/report.sha256")"
  chk "opponent round $n canonical block == sealed ${sealed:0:16}" test "$(vf_hash "$t/b")" == "$sealed"
done
vf_report_block "$r/opponent-round15.md" 15 > "$t/ret"
chk 'returned report block == sealed round-15 digest' test "$(vf_hash "$t/ret")" == "$(cat "$L/report.sha256")"
vf_report_block "$s/notes/reality-check.md" 1 > "$t/b"
chk 'reality-check round 1 canonical block == sealed' test "$(vf_hash "$t/b")" == "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")"
chk 'reserved and returned worktree entries byte-identical' cmp -s "$r/r15-state-reserved.entries" "$r/r15-state-returned.entries"
chk 'reserved and returned state records equal (label/taken aside)' test "$(grep -v '^label=' "$r/r15-state-reserved.txt")" == "$(grep -v '^label=' "$r/r15-state-returned.txt")"
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
chk "source == reserved source ($src)" test "$src" == "$rsrc"
chk "source == frozen T030o45/T030o46 source c9f2b616... ($src)" test "$src" == c9f2b61691a4447d28f4baaf640c3f43ec993040fda9febaf8eba82134e5b21e
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"; dec="$(vf_hash "$t/decisions")"
chk "Decisions digest unchanged 7c0c5ede... ($dec)" test "$dec" == 7c0c5ede16a40e76fb6c89001c60877c5eed3e8a4bb6b68aaebc57c96d720134
chk "floor-latest == reserved floor ($rfloor)" test "$(cat "$s/notes/verification/floor-latest")" == "$rfloor"
chk "$rfloor validates current for the reserved source" test "$(vf_floor_validate "$s" "$rfloor" 2>/dev/null)" == "$rsrc"
chk 'no held lock' test ! -e "$s/notes/verification/lock"
chk 'no .capture.* staging anywhere under notes/' test -z "$(find "$s/notes" -name '.capture.*' -print -quit)"
chk "HEAD == 0d55c62 ($(git rev-parse --short HEAD))" test "$(git rev-parse --short HEAD)" == 0d55c62
for task in T030 T031 T032 T033 T034; do chk "$task unchecked" grep -q -F -- "- [ ] **$task**" "$s/tasks.md"; done
for task in T030o39 T030o40 T030o41 T030o42 T030o43 T030o44 T030o45 T030o46; do chk "$task checked" grep -q -F -- "- [x] **$task**" "$s/tasks.md"; done
chk 'prereserve and reserved worktree entries byte-identical' cmp -s "$r/r15-state-prereserve.entries" "$r/r15-state-reserved.entries"
bash scripts/spec-gate.sh waiver "$s" opponent 15 > "$t/w15" 2>&1; rc=$?
sed "s/^/  w15| /" "$t/w15"
chk "round 15 reported completed at exit 0" test "$rc:$(cat "$t/w15")" == "0:opponent round 15 is already completed; the next round is 16"
bash scripts/spec-gate.sh waiver "$s" opponent 16 > "$t/w16" 2>&1; rc=$?
sed "s/^/  w16| /" "$t/w16"
chk "round 16 refused at exit 4 ($(grep -c -E "STATUS\\.md:[0-9]+" "$t/w16") candidates)" test "$rc" == 4
chk 'round 16 refusal names no line that authorizes round=16' test "$(grep -c 'authorizes round=16' "$t/w16")" == 0
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; rc=$?
chk 'tally exit 0' test "$rc" == 0
chk "tally opponent rounds=15" grep -q -x "opponent rounds=15" "$t/tally"
sed 's/^/  /' "$t/tally"
printf 'final audit failures=%s\n' "$fails"
(( fails == 0 ))
