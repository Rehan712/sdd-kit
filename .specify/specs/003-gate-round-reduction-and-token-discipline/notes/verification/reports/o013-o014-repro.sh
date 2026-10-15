#!/usr/bin/env bash
# Reproduce round-9 O-013 and O-014 plus the two isolation gaps, 2026-09-23.
# Usage: bash repro.sh <scratchpad> <worktree>
# O-013 and both mutations run ONLY in the isolated copy <scratchpad>/repro/copy
# (a standalone git repo); O-014 runs a scratch fixture against the LIVE library,
# read-only. Every exit code is captured from the command itself.
set -uo pipefail
SP="$1"; WT="$2"
export TMPDIR="$SP/tmp"; mkdir -p "$TMPDIR"
C="$SP/repro/copy"; w="$SP/repro/work"; rm -rf "$w"; mkdir -p "$w"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
p2=.specify/specs/002-usage-limit-handling-for-dispatched-runs/notes/opponent.md
fails=0
expect() { # label want got
  if [[ "$2" == "$3" ]]; then printf 'PASS %s (want=%s got=%s)\n' "$1" "$2" "$3"; else printf 'FAIL %s (want=%s got=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi
}
strip_runner() { awk '$0 != "t_run_all"' "$C/tests/test-gate-contracts.sh" > "$C/tests/.one-gate-contracts.sh"; }
run_one() { # function -> exit status of that one test function, harness-style; assert lines to $w/<fn>.<tag>.out
  local fn="$1" tag="$2"
  ( cd "$C" && bash -c '. tests/.one-gate-contracts.sh
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$1"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$2"; exit "$rc"' _ "$fn" "$w/$fn.$tag.out" )
}
snap() { # output-manifest -> digest (in the copy)
  ( cd "$C" && HUB_DIR="$PWD" && . scripts/lib.sh && . scripts/verification-lib.sh && vf_snapshot "$s" "$PWD" "$PWD" "$1" 2> "$1.err" )
}

cd "$C" || exit 2
[[ -z "$(git status --porcelain)" ]] || { echo 'copy is not clean'; exit 2; }
strip_runner
expect 'runner copy drops only the t_run_all line' 1 "$(( $(wc -l < tests/test-gate-contracts.sh) - $(wc -l < tests/.one-gate-contracts.sh) ))"
expect 'runner copy is ignored by the copy identity' '' "$(git status --porcelain)"

echo '== O-013 V1: one-line edit to shipped 002 gate report'
a="$(snap "$w/v1-before.nul")"; expect 'snapshot before rc' 0 "$?"
run_one test_reports_and_tally v1-before; expect 'test_reports_and_tally before edit' 0 "$?"
sed -i '' '238s/\*severity:\* wrong-result/*severity:* degraded/' "$p2"
expect 'edit landed on 002 opponent.md:238' 1 "$(sed -n '238p' "$p2" | grep -c '\*severity:\* degraded')"
b="$(snap "$w/v1-after.nul")"; expect 'snapshot after rc' 0 "$?"
printf 'identity before=%s after=%s\n' "$a" "$b"
expect 'identity unchanged by the edit (O-013)' "$a" "$b"
cmp -s "$w/v1-before.nul" "$w/v1-after.nul"; expect 'manifests cmp-identical' 0 "$?"
run_one test_reports_and_tally v1-after; expect 'test_reports_and_tally after edit fails' 1 "$?"
grep -m2 'assert:' "$w/test_reports_and_tally.v1-after.out" | cut -c1-200
git checkout -q -- "$p2"; expect 'copy restored' '' "$(git status --porcelain)"

echo '== O-013 V2: a findings manifest added under 002 notes/verification/reports/'
mkdir -p .specify/specs/002-usage-limit-handling-for-dispatched-runs/notes/verification/reports
printf '### Finding O-001\n- **Class:** fixture-class\n- **Severity:** wrong-result\n' \
  > .specify/specs/002-usage-limit-handling-for-dispatched-runs/notes/verification/reports/opponent-findings-x.md
c="$(snap "$w/v2.nul")"; expect 'identity unchanged by an added 002 manifest' "$a" "$c"
( HUB_DIR="$PWD" bash scripts/spec-gate.sh tally .specify/specs/002-usage-limit-handling-for-dispatched-runs > "$w/v2-tally.out" 2>&1 ); printf '002 tally with the added manifest: rc=%s %s\n' "$?" "$(head -c 160 "$w/v2-tally.out" | tr '\n' ' ')"
rm -rf .specify/specs/002-usage-limit-handling-for-dispatched-runs/notes/verification
expect 'copy restored' '' "$(git status --porcelain)"

echo '== O-013 V3: the same path declared under verification_inputs:'
awk -v p="$p2" -v q="'" '$0=="verification_inputs: []" {print "verification_inputs:"; print "  - " q p q; next} {print}' .specify/stack.yml > "$w/stack.yml" && cat "$w/stack.yml" > .specify/stack.yml
expect 'declaration landed' 1 "$(grep -c -F "  - '$p2'" .specify/stack.yml)"
d1="$(snap "$w/v3-declared.nul")"; expect 'declared snapshot rc' 0 "$?"
sed -i '' '238s/\*severity:\* wrong-result/*severity:* degraded/' "$p2"
d2="$(snap "$w/v3-declared-edited.nul")"; expect 'declared+edited snapshot rc' 0 "$?"
expect 'declared input still blind to the edit (O-013 :1345)' "$d1" "$d2"
expect 'no identity record names the declared path' 0 "$(tr '\0' '\n' < "$w/v3-declared-edited.nul" | grep -c -F -x "$p2")"
expect 'no diagnostic printed for the dropped declaration' 0 "$(wc -c < "$w/v3-declared-edited.nul.err" | tr -d ' ')"
git checkout -q -- "$p2" .specify/stack.yml; expect 'copy restored' '' "$(git status --porcelain)"

echo '== Isolation gap 1: tally gate key at verification-lib.sh:1243'
expect 'line 1243 is the gate key' 1 "$(sed -n '1243p' scripts/verification-lib.sh | grep -c -F '{ k=$5 SUBSEP $2')"
sed -i '' '1243s/{ k=\$5 SUBSEP \$2/{ k=$2/' scripts/verification-lib.sh
expect 'mutation landed' 1 "$(sed -n '1243p' scripts/verification-lib.sh | grep -c -F '{ k=$2')"
run_one test_reports_and_tally m1; expect 'ID-only key SURVIVES test_reports_and_tally' 0 "$?"
git checkout -q -- scripts/verification-lib.sh; expect 'copy restored' '' "$(git status --porcelain)"

echo '== Isolation gap 2: multi-clause refusal at tests/test-gate-contracts.sh:1305'
run_one test_instruction_contracts m2-baseline; expect 'test_instruction_contracts baseline' 0 "$?"
expect 'line 1305 is the multi-clause refusal' 1 "$(sed -n '1305p' tests/test-gate-contracts.sh | grep -c -F 'if(body ~ /;;|;&/) fail()')"
sed -i '' '1305d' tests/test-gate-contracts.sh; strip_runner
run_one test_instruction_contracts m2; expect 'deleted refusal SURVIVES test_instruction_contracts' 0 "$?"
git checkout -q -- tests/test-gate-contracts.sh; strip_runner; expect 'copy restored' '' "$(git status --porcelain)"

echo '== O-014: manifest tier then a lower round tier, live library, scratch fixture'
cd "$WT" || exit 2
eval "$(sed -n '/^tier_round_fixture() {/,/^}/p' tests/test-gate-contracts.sh)"
spec="$w/o014-spec"; mkdir -p "$spec/notes/verification/reports"
printf '### Finding G-042\n- **Class:** tier-binding\n- **Severity:** wrong-result\n' > "$spec/notes/verification/reports/opponent-findings-fixture.md"
tier_round_fixture 1 '' G-042:tier-binding:reopened:minor > "$spec/notes/opponent.md"
bash -c '. scripts/verification-lib.sh; vf_reports "$1" opponent "$2" "$3"' _ "$spec/notes/opponent.md" "$w/o014-cleared.nul" "$spec" > "$w/o014-cleared.out" 2>&1
expect 'CLEARED round resting on the manifest-seeded downgrade is refused' 3 "$?"
expect 'refusal names the lowered tier' 1 "$(grep -c 'clearing verdict rests on 1 lowered severity tier(s) of known findings' "$w/o014-cleared.out")"
tier_round_fixture 1 '' G-042:tier-binding:reopened:minor G-043:tier-binding:new:wrong-result > "$spec/notes/opponent.md"
bash -c '. scripts/verification-lib.sh; vf_reports "$1" opponent "$2" "$3"' _ "$spec/notes/opponent.md" "$w/o014-challenged.nul" "$spec" > "$w/o014-challenged.out" 2>&1
expect 'same observation in a CHALLENGED round validates' 0 "$?"
bash scripts/spec-gate.sh tally "$spec" > "$w/o014-tally.out" 2>&1; expect 'tally rc' 0 "$?"
expect 'O-014 reproduced: tally misses the downgrade the guard just counted' 'severity-downgrades=0' "$(grep -o 'severity-downgrades=[0-9]*' "$w/o014-tally.out")"

printf 'repro failures=%s\n' "$fails"
(( fails == 0 ))
