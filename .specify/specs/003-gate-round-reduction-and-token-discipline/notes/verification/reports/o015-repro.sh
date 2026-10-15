#!/usr/bin/env bash
# Reproduce round-10 O-015 and the round-10 isolation gap, and measure the
# sibling readers of the same class, 2026-09-24, BEFORE any repair.
# Usage: bash o015-repro.sh <scratchpad> <worktree>
#
# Read-only against the live worktree: step 0 reads its manifest enumeration
# (GIT_OPTIONAL_LOCKS=0) and tars those files into a standalone git copy under
# <scratchpad>/o015/copy. Every edit, capture, suite and mutation runs in that
# copy. Every exit code is captured from the command itself, never a pipe.
# Sections A and B are expectations (a FAIL line fails the script); section C
# records measurements whose outcome was not assumed in advance.
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/o015"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
d2=.specify/specs/002-usage-limit-handling-for-dispatched-runs
CLAIM='hosted CI green; the macOS job includes PATH and TMPDIR shims for Bash 3.2 (2026-09-24)'
fails=0
expect() { # label want got
  if [[ "$2" == "$3" ]]; then printf 'PASS %s (want=%s got=%s)\n' "$1" "$2" "$3"
  else printf 'FAIL %s (want=%s got=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi
}
note() { printf '  | %s\n' "$*"; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1 ); }
rewrite() { # <file> <awk program> [awk -v assignments...] -- keeps the file's mode
  local f="$1" prog="$2"; shift 2
  awk "$@" "$prog" "$f" > "$w/rewrite.tmp" && cat "$w/rewrite.tmp" > "$f"
}
run_one() { # <suite stem> <function> <tag> -> exit status of that one function, harness-style
  ( cd "$C" && bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$1" "$2" "$w/$2.$3.out" )
}
snap() { ( cd "$C" && HUB_DIR="$PWD" && . scripts/lib.sh && . scripts/verification-lib.sh && vf_snapshot "$s" "$PWD" "$PWD" "$1" 2> "$1.err" ); }
scan() { ( cd "$C" && bash -c '. tests/.one-gate-contracts.sh; superseded_environment_scan "$1"' _ "${1:-$C}" ); }
restore() { ( cd "$C" && git checkout -q -- . && git clean -fdq ); expect "$1: copy restored" '' "$(cd "$C" && git status --porcelain)"; }

L0="$(live_state)"; note "live worktree porcelain digest before: $L0"

echo '== 0. build the copy from the live manifest enumeration'
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul"
expect 'live enumeration rc' 0 "$?"
( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$C" && tar -xf - )
expect 'copy extraction rc' 0 "$?"
cd "$C" || exit 2
git init -q && git add -A && git -c user.name=repro -c user.email=repro@invalid commit -qm base
expect 'copy committed' 0 "$?"
printf 'tests/.one-*.sh\n' >> .git/info/exclude
for stem in gate-contracts verification sdd-analyze usage-limits; do
  expect "tests/test-$stem.sh ends in exactly one t_run_all line" 1 "$(grep -c -x 't_run_all' "tests/test-$stem.sh")"
  awk '$0 != "t_run_all"' "tests/test-$stem.sh" > "tests/.one-$stem.sh"
done
expect 'copy clean; runner copies excluded from its enumeration' '' "$(git status --porcelain)"

echo '== A0 baseline'
A="$(snap "$w/a0.nul")"; expect 'baseline snapshot rc' 0 "$?"
out="$(scan)"; expect 'baseline scan rc' 0 "$?"; expect 'baseline scan is clean' '' "$out"

echo '== A1 O-015 end to end: a capture stays reusable over a suite that now fails'
expect 'T030o38 Verify is exactly the gate-contracts suite' 1 "$(awk '/^- \[.\] \*\*T030o38\*\*/{on=1} on && /\*Verify:\*/{print; exit}' "$s/tasks.md" | grep -c -F '`bash tests/test-gate-contracts.sh`')"
bash scripts/spec-run.sh "$s" T030o38 --from-task --no-tick --summary > "$w/a1-capture.out" 2>&1
expect 'capture of bash tests/test-gate-contracts.sh rc' 0 "$?"
cap="$(grep -o -E 'CAP-[0-9]+-[A-Za-z0-9]+' "$w/a1-capture.out" | head -1)"
note "capture=$cap summary: $(tail -1 "$w/a1-capture.out" | cut -c1-220)"
bash scripts/spec-task.sh done "$s" T030 --evidence "$CLAIM" > "$w/a1-tick.out" 2>&1
expect 'spec-task.sh done T030 --evidence rc' 0 "$?"; note "$(cat "$w/a1-tick.out")"
B="$(snap "$w/a1.nul")"; expect 'snapshot after the tick rc' 0 "$?"
note "identity before=$A after=$B"
expect 'identity unchanged by the tick' "$A" "$B"
cmp -s "$w/a0.nul" "$w/a1.nul"; expect 'manifests cmp-identical' 0 "$?"
( HUB_DIR="$C"; . scripts/lib.sh; . scripts/verification-lib.sh; vf_capture_check "$s" "$cap" "$w/a1.nul" reuse ) > "$w/a1-reuse.out" 2>&1
expect "vf_capture_check $cap reuse after the tick: accepted (the wrong result)" 0 "$?"
out="$(scan)"; printf '%s\n' "$out" | sed 's/^/  | scan: /'
expect 'scan reports the verified spec tasks.md Evidence line' 1 "$(printf '%s\n' "$out" | grep -c -F "$s/tasks.md :: includes PATH")"
bash tests/test-gate-contracts.sh > "$w/a1-suite.out" 2>&1
expect 'bash tests/test-gate-contracts.sh after the tick: fails' 1 "$?"
note "$(grep -E -- '-- [0-9]+/[0-9]+ passed|FAIL test_' "$w/a1-suite.out" | tr '\n' ' ')"
expect 'the failure is the O-010 guard assertion' 1 "$(grep -c -F 'assert: AC-018: superseded fixed-environment membership survives in a current artifact' "$w/a1-suite.out")"
restore A1

echo "== A2-A4 the same sentence on other dropped lines of ANOTHER spec"
rewrite "$d2/tasks.md" '!done && /^[ ]*- \*Evidence:\*/ {print $0 "; " c; done=1; next} {print}' -v c="$CLAIM"
X="$(snap "$w/a2.nul")"; expect 'A2 002 tasks.md Evidence line: identity unchanged' "$A" "$X"
expect 'A2 scan reports 002 tasks.md' 1 "$(scan | grep -c -F "$d2/tasks.md ::")"
restore A2
rewrite "$d2/plan.md" 'NR>1 && !done && /^updated:/ {print $0 "  # " c; done=1; next} {print}' -v c="$CLAIM"
expect 'A3 edit landed on the plan.md updated: line' 1 "$(grep -c -F "# $CLAIM" "$d2/plan.md")"
X="$(snap "$w/a3.nul")"; expect 'A3 002 plan.md updated: line: identity unchanged' "$A" "$X"
expect 'A3 scan reports 002 plan.md' 1 "$(scan | grep -c -F "$d2/plan.md ::")"
restore A3
rewrite "$d2/spec.md" 'NR>1 && !done && /^status:/ {print $0 "  # " c; done=1; next} {print}' -v c="$CLAIM"
X="$(snap "$w/a4.nul")"; expect 'A4 002 spec.md status: line: identity unchanged' "$A" "$X"
expect 'A4 scan reports 002 spec.md' 1 "$(scan | grep -c -F "$d2/spec.md ::")"
restore A4

echo '== A5 control: the same sentence in the body is hashed and reported'
printf '\n%s\n' "$CLAIM" >> "$d2/tasks.md"
X="$(snap "$w/a5.nul")"; expect 'A5 body claim moves the identity' 1 "$([[ "$X" != "$A" ]] && echo 1 || echo 0)"
expect 'A5 scan reports the body claim' 1 "$(scan | grep -c -F "$d2/tasks.md ::")"
restore A5

echo '== A6 latent: a name git quotes without -z'
mkdir -p docs; printf '%s\n' "$CLAIM" > "docs/caf$(printf '\303\251').md"
X="$(snap "$w/a6.nul")"; expect 'A6 the untracked non-ASCII file moves the identity' 1 "$([[ "$X" != "$A" ]] && echo 1 || echo 0)"
expect 'A6 the manifest records the name unquoted' 1 "$(tr '\0' '\n' < "$w/a6.nul" | grep -c -x -F "docs/caf$(printf '\303\251').md")"
note "git ls-files without -z prints: $(git ls-files --others --exclude-standard docs)"
expect 'A6 scan misses the quoted name' 0 "$(scan | grep -c 'docs/caf')"
printf '%s\n' "$CLAIM" > docs/cafe.md
expect 'A6 control: the ASCII twin is reported' 1 "$(scan | grep -c -F 'docs/cafe.md ::')"
restore A6

echo '== A7 a git failure reads as an empty, clean tree'
printf '\n%s\n' "$CLAIM" >> "$d2/tasks.md"
expect 'A7 precondition: the body claim is reported' 1 "$(scan | grep -c -F "$d2/tasks.md ::")"
out="$(export GIT_DIR="$R/no-such-git-dir"; scan)"; rc=$?
expect 'A7 with git failing, the scan exits 0' 0 "$rc"
expect 'A7 with git failing, the scan prints nothing, so assert_eq "" passes over a live claim' '' "$out"
restore A7

echo '== B isolation gap: the .specify/specs/<name> layout clause in vf_bookkeeping_anchor'
CL='; [[ "$own" =~ ^\.specify/specs/[^/]+$ ]] || own='"''"
expect 'B clause present exactly once' 1 "$(grep -c -F -- "$CL" scripts/verification-lib.sh)"
export CL; rewrite scripts/verification-lib.sh '{i = index($0, ENVIRON["CL"]); if (i) $0 = substr($0, 1, i - 1) substr($0, i + length(ENVIRON["CL"])); print}'
expect 'B mutation landed' 0 "$(grep -c -F -- "$CL" scripts/verification-lib.sh)"
bash tests/test-verification.sh > "$w/b.out" 2>&1
expect 'B clause deleted: tests/test-verification.sh SURVIVES' 0 "$?"
note "$(grep -E -- '-- [0-9]+/[0-9]+ passed' "$w/b.out")"
restore B

echo '== C1 measurement: the AC-023 analyzer loop over 002 bytes the identity drops'
run_one sdd-analyze test_verification_bindings c1-base; rc=$?
expect 'C1 baseline test_verification_bindings' 0 "$rc"
for probe in agent comment untick phase; do
  case "$probe" in
    agent)   rewrite "$d2/tasks.md" '!done && /^[ ]*- \*Evidence:\*/ {print $0 "; cross-checked with *Agent:* agents/opponent-retired.md"; done=1; next} {print}';;
    comment) rewrite "$d2/tasks.md" '!done && /^[ ]*- \*Evidence:\*/ {print $0 " <!-- earlier wording kept for the record"; done=1; next} {print}';;
    untick)  rewrite "$d2/tasks.md" '{sub(/^- \[[xX]\] /, "- [ ] "); print}';;
    phase)   rewrite "$d2/STATUS.md" 'NR>1 && !done && /^phase:/ {print "phase: plan"; done=1; next} {print}';;
  esac
  note "C1 $probe: $(git diff --stat | tail -1)"
  X="$(snap "$w/c1-$probe.nul")"; expect "C1 $probe: identity unchanged" "$A" "$X"
  run_one sdd-analyze test_verification_bindings "c1-$probe"; rc=$?
  note "C1 $probe: test_verification_bindings rc=$rc"
  grep -E 'assert:|gate|✗' "$w/test_verification_bindings.c1-$probe.out" | head -4 | cut -c1-200 | sed 's/^/  |   /'
  restore "C1 $probe"
done

echo '== C2 measurement: git-ignored machine-local files and the verified spec own records'
run_one usage-limits test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models c2-base; rc=$?
expect 'C2 baseline doctor reconcile test' 0 "$rc"
printf 'repos: [unclosed\n' > system-map.yml
expect 'C2 system-map.yml is ignored' '' "$(git status --porcelain)"
X="$(snap "$w/c2a.nul")"; expect 'C2 system-map.yml alone: identity unchanged' "$A" "$X"
run_one usage-limits test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models c2-sysmap; rc=$?
note "C2 invalid system-map.yml alone: doctor reconcile test rc=$rc"
grep -E 'assert:|system-map' "$w/test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models.c2-sysmap.out" | head -3 | cut -c1-200 | sed 's/^/  |   /'
printf 'projects:\n  - [unclosed\n' > registry.yml
printf 'tiers: [unclosed\n' > models.yml
mkdir -p build briefs .cache/repos/x
printf 'junk\n' > build/junk.md; printf 'junk\n' > briefs/junk.md; printf 'junk\n' > .cache/repos/x/junk
printf '\n%s\n' "$CLAIM" >> "$s/notes/opponent.md"
printf '\n%s\n' "$CLAIM" >> "$s/notes/evidence.md"
printf '%s\n' "$CLAIM" > "$s/notes/verification/junk.md"
note "C2 porcelain now: $(git status --porcelain | tr '\n' ' ')"
X="$(snap "$w/c2.nul")"; expect 'C2 all ignored junk + own records: identity unchanged' "$A" "$X"
bash tests/run.sh > "$w/c2-suite.out" 2>&1; rc=$?
note "C2 full bash tests/run.sh over the junk: rc=$rc"
grep -E '^== |FAIL test_|-- [0-9]+/[0-9]+ passed' "$w/c2-suite.out" | paste - - | grep -v -E '([0-9]+)/\1 passed' | sed 's/^/  |   /'
grep -E 'FAIL test_' "$w/c2-suite.out" | sed 's/^/  | failing: /'
rm -f system-map.yml registry.yml models.yml; rm -rf build briefs .cache
restore C2
expect 'C2 ignored junk removed' '' "$(git status --porcelain --ignored | grep -v -E '^!! (tests/\.one-|\.DS_Store)' || true)"

L1="$(live_state)"; note "live worktree porcelain digest after: $L1"
expect 'live worktree unchanged by the whole reproduction' "$L0" "$L1"
printf 'repro failures=%s\n' "$fails"
(( fails == 0 ))
