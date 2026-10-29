#!/usr/bin/env bash
# The one dev run of T031a4o2 (round 21's O-029), 2026-10-16 (session 24): a standalone copy built from the live
# enumeration and git-initialized, r22-edits/apply-code.py and apply-docs.py applied, then tests/run.sh and
# tests/shellcheck.sh with a TMPDIR ending in `/` inside the copy; then every mutant opponent rounds 20 and 21 ran
# against the T031a fixtures (r22-edits/mutants-r22.py, 17), each applied to the copy's kernel, its focus case run
# alone, the kernel restored and checked with cmp. Every mutant but the one round 21 held equivalent (readround) must
# be killed, and every O-029 assertion must be killed by at least one mutant. Pattern: r21-dev.sh. The live status
# outside notes/verification/ is compared before and after.
# Usage from the worktree root: bash <this> <scratch-dir>
# The last line is `suites=<p>/<t> shellcheck_rc=<rc> run_rc=<rc> mutants_killed=<k>/<n> o029_assertions_killed=<a>/<b>`.
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
X="$SP/r22-dev-run"; rm -rf "$X"; mkdir -p "$X/tree" "$X/tmp"
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
before="$(livestate)"
printf 'host: %s; bash on PATH: %s\nstart %s\n' "$(uname -sr)" "$(bash --version | head -1)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'free disk at start: %s\n' "$(df -h / | awk 'NR==2 {print $4}')"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$X/tree" && tar -xf - ) || { echo 'copy failed'; exit 3; }
python3 -I "$WT/$r/r22-edits/apply-code.py" "$X/tree" || { echo 'apply-code failed'; exit 3; }
python3 -I "$WT/$r/r22-edits/apply-docs.py" "$X/tree" || { echo 'apply-docs failed'; exit 3; }
( cd "$X/tree" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { echo 'copy commit failed'; exit 3; }
cd "$X/tree" || exit 3
export TMPDIR="$X/tmp/"
bash tests/run.sh > "$X/run.log" 2>&1; run_rc=$?
bash tests/shellcheck.sh > "$X/shellcheck.log" 2>&1; sc_rc=$?
printf 'run.sh rc=%s; per-suite: %s\n' "$run_rc" "$(grep -E -o -- '-- [0-9]+/[0-9]+ passed' "$X/run.log" | tr '\n' ' ')"
grep -E -- '(FAIL|not ok|-- [0-9]+/[0-9]+ (failed|FAILED))' "$X/run.log" | head -40 | sed 's/^/  | /'
printf 'shellcheck rc=%s; %s\n' "$sc_rc" "$(tail -1 "$X/shellcheck.log")"
[[ "$sc_rc" == 0 ]] || sed 's/^/  | /' "$X/shellcheck.log" | head -40
printf 'free disk after the suites: %s\n' "$(df -h / | awk 'NR==2 {print $4}')"
focus() { # <suite> <out> <fn>...
  local f="$1" out="$2"; shift 2
  tail -1 "$f" | grep -qx t_run_all || { echo "focus runner: unexpected tail of $f"; exit 3; }
  { sed '$d' "$f"
    printf 'for _fn in $(declare -F | awk %s{print $3}%s | grep %s^test_%s); do unset -f "$_fn"; done\n' "'" "'" "'" "'"
    printf 'test_zz_focus() {\n'; printf '  %s\n' "$@"; printf '}\nt_run_all\n'; } > "$out"
}
focus tests/test-spec-gate.sh tests/test-zz-reconcile.sh round_legacy_reconcile_cases
focus tests/test-spec-gate.sh tests/test-zz-named.sh acceptance_named_cases
focus tests/test-gate-contracts.sh tests/test-zz-tally.sh shipped_002_tally_case tally_class_cases
cp scripts/verification-lib.sh "$X/lib.orig"
for c in reconcile named tally; do
  bash "tests/test-zz-$c.sh" > "$X/none-$c.log" 2>&1; printf 'unmutated focus %s rc=%s\n' "$c" "$?"
done
k=0; n=0
for m in midnight readcheck readdigest readround reccheck recdigest recround recguard recbefore endofday clamp future combined explicitnone tallyappend tallytouch tallynewline; do
  case "$m" in explicitnone) c=named;; tally*) c=tally;; *) c=reconcile;; esac
  python3 -I "$WT/$r/r22-edits/mutants-r22.py" scripts/verification-lib.sh "$m" > /dev/null || { echo "mutant $m failed to apply"; exit 3; }
  bash "tests/test-zz-$c.sh" > "$X/m-$m.log" 2>&1; rc=$?
  cp "$X/lib.orig" scripts/verification-lib.sh
  cmp -s "$X/lib.orig" scripts/verification-lib.sh || { echo "kernel not restored after $m"; exit 3; }
  hits="$(grep -c -E '^ *assert: ' "$X/m-$m.log")"
  if [[ "$rc" != 0 && "$hits" != 0 ]]; then verdict=killed; else verdict=SURVIVED; fi
  [[ "$m" == readround ]] && verdict="$verdict (held equivalent by round 21)"
  n=$((n+1)); [[ "$verdict" == killed || "$m" == readround ]] && k=$((k+1))
  printf 'mutant %-12s focus=%-9s rc=%s %s\n' "$m" "$c" "$rc" "$verdict"
  grep -E '^ *assert: AC-0' "$X/m-$m.log" | sed -e 's/^ *assert: /    | /' -e 's/ missing substring:.*//' -e 's/ unexpectedly contains:.*//'
done
rm -f tests/test-zz-reconcile.sh tests/test-zz-named.sh tests/test-zz-tally.sh
a=0; b=0
while IFS= read -r label; do
  b=$((b+1)); by=''
  for m in midnight readcheck readdigest readround reccheck recdigest recround recguard recbefore endofday clamp future combined; do
    grep -q -F -- "assert: $label" "$X/m-$m.log" && by="$by $m"
  done
  [[ -n "$by" ]] && a=$((a+1))
  printf 'O-029 assertion killed by:%s | %s\n' "${by:- NONE}" "$label"
done <<'EOF'
AC-009: a reconcile record with a wrong digest wrote legacy-time.nul
AC-009: a reconcile record with a wrong digest left the history able to order an authorization
AC-009: a reconcile record with a wrong round wrote legacy-time.nul
AC-009: a reconcile record with a wrong round left the history able to order an authorization
AC-009: a reconcile record with a timestamp before the history's date wrote legacy-time.nul
AC-009: a reconcile record with a timestamp before the history's date left the history able to order an authorization
AC-009: a reconcile record with a future timestamp wrote legacy-time.nul
AC-009: a reconcile record with a future timestamp left the history able to order an authorization
AC-009: a waiver dated before the reconciled completion authorized the next round
AC-009: a reconcile record outlived an edit of its history and authorized round 6
AC-009: a reconcile record outlived an edit of its history and reserved round 6
EOF
bad=0; for c in reconcile named tally; do grep -q -E '^ *assert:' "$X/none-$c.log" && { echo "the unmutated $c focus run failed an assertion"; bad=1; }; done
cd "$WT" || exit 3
suites="$(grep -E -o -- '-- [0-9]+/[0-9]+ passed' "$X/run.log" | awk -F'[ /]' '{p += $2; t += $3} END {printf "%d/%d", p, t}')"
after="$(livestate)"
printf 'live worktree status outside notes/verification/: before=%s after=%s %s\n' "$before" "$after" "$([[ "$before" == "$after" ]] && echo unchanged || echo CHANGED)"
printf 'end %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
rm -rf "$X"
printf 'suites=%s shellcheck_rc=%s run_rc=%s mutants_killed=%s/%s o029_assertions_killed=%s/%s\n' "$suites" "$sc_rc" "$run_rc" "$k" "$n" "$a" "$b"
[[ "$run_rc" == 0 && "$sc_rc" == 0 && "$before" == "$after" && "$k" == "$n" && "$a" == "$b" && "$bad" == 0 ]]
