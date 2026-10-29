#!/usr/bin/env bash
# Final audit for the 2026-09-23 session. Run from the worktree root.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
t="$(mktemp -d "${TMPDIR:-/tmp}/final-audit.XXXXXX")"; trap 'rm -rf "$t"' EXIT
fails=0
chk() { local label="$1"; shift; if "$@"; then printf 'PASS %s\n' "$label"; else printf 'FAIL %s\n' "$label"; fails=$((fails+1)); fi; }
for gate in opponent reality-check; do
  vf_round_history "$s" "$gate" "$t" || { echo "FAIL history $gate"; fails=$((fails+1)); continue; }
  pending=0; for l in "$s/notes/verification/rounds/$gate"/ROUND-*; do vf_integrity "$l" meta.nul || fails=$((fails+1)); [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
  printf '%s sealed rounds=%s pending=%s\n' "$gate" "$VF_ROUND_LAST" "$pending"; [[ "$pending" == 0 ]] || fails=$((fails+1))
done
for n in 1 2 3 4 5 6 7 8 9; do
  vf_report_block "$s/notes/opponent.md" "$n" > "$t/b"
  [[ "$(vf_hash "$t/b")" == "$(cat "$s/notes/verification/rounds/opponent/ROUND-$n/report.sha256")" ]] || { echo "FAIL opponent round $n digest"; fails=$((fails+1)); }
done
printf 'opponent round 1-9 sealed digests checked\n'
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
chk "source == d27bab53... ($src)" test "$src" == d27bab536454eead9135c5d502962488e653eef8277006b50eeb5d43b22b4466
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"; printf 'Decisions digest=%s\n' "$(vf_hash "$t/decisions")"
chk 'FLOOR-oejTDu current' test "$(vf_floor_validate "$s" FLOOR-oejTDu 2>/dev/null)" == "$src"
chk 'no held lock' test ! -e "$s/notes/verification/lock"
chk "HEAD == 0d55c62 ($(git rev-parse --short HEAD))" test "$(git rev-parse --short HEAD)" == 0d55c62
for task in T030 T031 T032 T033 T034; do chk "$task unchecked" grep -q -F -- "- [ ] **$task**" "$s/tasks.md"; done
for task in T030o39 T030o40; do chk "$task checked" grep -q -F -- "- [x] **$task**" "$s/tasks.md"; done
bash scripts/spec-gate.sh waiver "$s" opponent 10 > "$t/w10" 2>&1; rc=$?
chk "round-10 refused at exit 4 with $(grep -c -E 'STATUS\.md:[0-9]+' "$t/w10") candidates" test "$rc" == 4
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; rc=$?
chk 'tally exit 0' test "$rc" == 0
sed 's/^/  /' "$t/tally"
printf 'final audit failures=%s\n' "$fails"
(( fails == 0 ))
