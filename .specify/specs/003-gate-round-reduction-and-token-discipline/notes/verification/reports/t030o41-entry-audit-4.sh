#!/usr/bin/env bash
# Entry audit for the T030o41 continuation, 2026-09-24 (session 4). Read-only
# library reads only: no suite, no test function, no gate write. Run from the
# worktree root. Expected values come from t030o41-handoff-state-3.txt.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/t030o41-entry.XXXXXX")"; trap 'rm -rf "$t"' EXIT
fails=0
chk() { local label="$1"; shift; if "$@"; then printf 'PASS %s\n' "$label"; else printf 'FAIL %s\n' "$label"; fails=$((fails+1)); fi; }
state() { GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1; }
want() { grep -E "^$1=" "$r/t030o41-handoff-state-3.txt" | cut -d= -f2; }
S0="$(state)"; printf 'worktree porcelain digest before: %s\n' "$S0"

src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"; rc=$?
chk "snapshot rc 0" test "$rc" == 0
chk "source == handoff source ($src)" test "$src" == "$(want source)"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"; dec="$(vf_hash "$t/decisions")"
chk "Decisions == handoff Decisions ($dec)" test "$dec" == "$(want decisions)"
chk "HEAD == handoff HEAD ($(git rev-parse --short HEAD))" test "$(git rev-parse --short HEAD)" == "$(want head)"

bash scripts/sdd-analyze.sh "$s" > "$t/analyze" 2>&1; rc=$?
sed 's/^/  analyze| /' "$t/analyze" | tail -4
chk "analyzer exit 0 ($rc)" test "$rc" == 0
chk 'analyzer: 1 warning(s), 0 errors' grep -q -F '1 warning(s), 0 errors' "$t/analyze"

chk 'no held lock' test ! -e "$s/notes/verification/lock"
chk 'no .capture.* staging anywhere under notes/' test -z "$(find "$s/notes" -name '.capture.*' -print -quit)"
for gate in opponent reality-check; do
  pending=0; for l in "$s/notes/verification/rounds/$gate"/ROUND-*; do [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
  chk "$gate: no pending reservation" test "$pending" == 0
done
chk 'no staged .reservation-* in either gate' test -z "$(find "$s/notes/verification/rounds/opponent" "$s/notes/verification/rounds/reality-check" -mindepth 1 -maxdepth 1 -name '.*' -print)"
for task in T030 T031 T032 T033 T034 T030o41; do chk "$task unchecked" grep -q -F -- "- [ ] **$task**" "$s/tasks.md"; done
chk 'T030o41 Verify is the T027 command' test "$(awk '/^- \[.\] \*\*T030o41\*\*/{on=1} on && /\*Verify:\*/{print; exit}' "$s/tasks.md" | grep -c -F '`bash tests/run.sh && bash tests/shellcheck.sh`')" == 1
chk 'T027 Verify is the same command' test "$(awk '/^- \[.\] \*\*T027\*\*/{on=1} on && /\*Verify:\*/{print; exit}' "$s/tasks.md" | grep -c -F '`bash tests/run.sh && bash tests/shellcheck.sh`')" == 1

bash scripts/spec-gate.sh waiver "$s" opponent 11 > "$t/w11" 2>&1; rc=$?
sed 's/^/  w11| /' "$t/w11"
chk "round 11 refused at exit 4 ($rc)" test "$rc" == 4
chk "FLOOR-qQEv7w no longer current" test "$(vf_floor_validate "$s" FLOOR-qQEv7w > /dev/null 2>&1; echo $?)" != 0

S1="$(state)"; printf 'worktree porcelain digest after: %s\n' "$S1"
chk 'worktree status unchanged by this audit' test "$S0" == "$S1"
printf 'entry audit failures=%s\n' "$fails"
(( fails == 0 ))
