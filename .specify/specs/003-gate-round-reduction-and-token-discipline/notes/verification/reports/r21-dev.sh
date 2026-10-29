#!/usr/bin/env bash
# The one dev run of T031a1o1, T031a3o1 and T031a4o1 (round 20's O-030, O-031 and O-029), 2026-10-16 (session 24),
# kept under the user's decisions of 2026-10-14 to 2026-10-16 that drop the invoker's repeated dev runs: a
# standalone copy built from the live enumeration and git-initialized, r21-edits/apply-code.py and apply-docs.py
# applied, then tests/run.sh and tests/shellcheck.sh with a TMPDIR ending in `/` inside the copy; then, as the user
# required for O-029, each of round 20's three mutants (r21-edits/mutants-o029.py) applied to the copy's kernel,
# round_legacy_reconcile_cases run alone, the kernel restored and checked with cmp, and every new O-029 assertion
# shown killed by at least one mutant. Pattern: r20-dev.sh and r20-repro-o029.sh. The live status outside
# notes/verification/ is compared before and after.
# Usage from the worktree root: bash <this> <scratch-dir>
# The last line is `suites=<passed>/<total> shellcheck_rc=<rc> run_rc=<rc> o029_killed=<k>/<n>`; exit 0 only when
# both runs pass and every new O-029 assertion is killed.
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
X="$SP/r21-dev-run"; rm -rf "$X"; mkdir -p "$X/tree" "$X/tmp"
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
before="$(livestate)"
printf 'host: %s; bash on PATH: %s\nstart %s\n' "$(uname -sr)" "$(bash --version | head -1)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'free disk at start: %s\n' "$(df -h /System/Volumes/Data | awk 'NR==2 {print $4}')"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$X/tree" && tar -xf - ) || { echo 'copy failed'; exit 3; }
python3 -I "$WT/$r/r21-edits/apply-code.py" "$X/tree" || { echo 'apply-code failed'; exit 3; }
python3 -I "$WT/$r/r21-edits/apply-docs.py" "$X/tree" || { echo 'apply-docs failed'; exit 3; }
( cd "$X/tree" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { echo 'copy commit failed'; exit 3; }
cd "$X/tree" || exit 3
export TMPDIR="$X/tmp/"
bash tests/run.sh > "$X/run.log" 2>&1; run_rc=$?
bash tests/shellcheck.sh > "$X/shellcheck.log" 2>&1; sc_rc=$?
printf 'run.sh rc=%s; per-suite: %s\n' "$run_rc" "$(grep -E -o -- '-- [0-9]+/[0-9]+ passed' "$X/run.log" | tr '\n' ' ')"
grep -E -- '(FAIL|not ok|-- [0-9]+/[0-9]+ (failed|FAILED))' "$X/run.log" | head -40 | sed 's/^/  | /'
printf 'shellcheck rc=%s; %s\n' "$sc_rc" "$(tail -1 "$X/shellcheck.log")"
[[ "$sc_rc" == 0 ]] || sed 's/^/  | /' "$X/shellcheck.log" | head -40
printf 'free disk after the suites: %s\n' "$(df -h /System/Volumes/Data | awk 'NR==2 {print $4}')"
# The O-029 mutants, each on round_legacy_reconcile_cases alone.
f=tests/test-spec-gate.sh; tail -1 "$f" | grep -qx t_run_all || { echo 'focus runner: unexpected suite tail'; exit 3; }
{ sed '$d' "$f"
  printf 'for _fn in $(declare -F | awk %s{print $3}%s | grep %s^test_%s); do unset -f "$_fn"; done\n' "'" "'" "'" "'"
  printf 'test_zz_focus() {\n  round_legacy_reconcile_cases\n}\nt_run_all\n'; } > "$X/focus.sh"
cp "$X/focus.sh" tests/test-zz-focus.sh
cp scripts/verification-lib.sh "$X/lib.orig"
bash tests/test-zz-focus.sh > "$X/m-none.log" 2>&1; printf 'unmutated round_legacy_reconcile_cases rc=%s\n' "$?"
for m in timestamp reconcile combined; do
  python3 -I "$WT/$r/r21-edits/mutants-o029.py" scripts/verification-lib.sh "$m" || { echo "mutant $m failed to apply"; exit 3; }
  bash tests/test-zz-focus.sh > "$X/m-$m.log" 2>&1; printf 'mutant %s: rc=%s\n' "$m" "$?"
  grep -E '^ *assert: AC-009' "$X/m-$m.log" | sed 's/^ *assert: /  | /'
  cp "$X/lib.orig" scripts/verification-lib.sh
  cmp -s "$X/lib.orig" scripts/verification-lib.sh || { echo "kernel not restored after $m"; exit 3; }
done
rm -f tests/test-zz-focus.sh
# Every new O-029 assertion (its label) and the mutants that kill it.
k=0; n=0
while IFS= read -r label; do
  n=$((n+1)); by=''
  for m in timestamp reconcile combined; do grep -q -F -- "assert: $label" "$X/m-$m.log" && by="$by $m"; done
  [[ -n "$by" ]] && k=$((k+1))
  printf 'O-029 assertion killed by:%s | %s\n' "${by:- NONE}" "$label"
done <<'EOF'
AC-009: a reconcile record with a wrong digest wrote legacy-time.nul
AC-009: a reconcile record with a wrong digest left the history able to order an authorization
AC-009: a reconcile record with a wrong round wrote legacy-time.nul
AC-009: a reconcile record with a wrong round left the history able to order an authorization
AC-009: a reconcile record with a wrong timestamp wrote legacy-time.nul
AC-009: a reconcile record with a wrong timestamp left the history able to order an authorization
AC-009: a waiver dated before the reconciled completion authorized the next round
AC-009: a reconcile record outlived an edit of its history and authorized round 6
AC-009: a reconcile record outlived an edit of its history and reserved round 6
EOF
grep -q -E '^ *assert:' "$X/m-none.log" && { echo 'the unmutated focus run failed an assertion'; k=-1; }
cd "$WT" || exit 3
suites="$(grep -E -o -- '-- [0-9]+/[0-9]+ passed' "$X/run.log" | awk -F'[ /]' '{p += $2; t += $3} END {printf "%d/%d", p, t}')"
after="$(livestate)"
printf 'live worktree status outside notes/verification/: before=%s after=%s %s\n' "$before" "$after" "$([[ "$before" == "$after" ]] && echo unchanged || echo CHANGED)"
printf 'end %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
rm -rf "$X"
printf 'suites=%s shellcheck_rc=%s run_rc=%s o029_killed=%s/%s\n' "$suites" "$sc_rc" "$run_rc" "$k" "$n"
[[ "$run_rc" == 0 && "$sc_rc" == 0 && "$before" == "$after" && "$k" == "$n" ]]
