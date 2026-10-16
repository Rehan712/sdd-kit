#!/usr/bin/env bash
# The one dev run of T031a1 to T031a4 (reality-check round 2 gaps 1 to 4), 2026-10-15 (session 23), kept under the user's
# decisions of 2026-10-14 and 2026-10-15 that drop the invoker's repeated dev runs: a standalone copy built from the live
# enumeration and git-initialized, r20-edits/apply-code.py and apply-docs.py applied, then tests/run.sh and
# tests/shellcheck.sh with a TMPDIR ending in `/` inside the copy. Pattern: r19-dev.sh. The live status
# outside notes/verification/ is compared before and after.
# Usage from the worktree root: bash <this> <scratch-dir>
# The last line is `suites=<passed>/<total> shellcheck_rc=<rc> run_rc=<rc>`; exit 0 only when both runs pass.
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
X="$SP/r20-dev-run"; rm -rf "$X"; mkdir -p "$X/tree" "$X/tmp"
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
before="$(livestate)"
printf 'host: %s; bash on PATH: %s\nstart %s\n' "$(uname -sr)" "$(bash --version | head -1)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$X/tree" && tar -xf - ) || { echo 'copy failed'; exit 3; }
python3 -I "$WT/$r/r20-edits/apply-code.py" "$X/tree" || { echo 'apply-code failed'; exit 3; }
python3 -I "$WT/$r/r20-edits/apply-docs.py" "$X/tree" || { echo 'apply-docs failed'; exit 3; }
( cd "$X/tree" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { echo 'copy commit failed'; exit 3; }
cd "$X/tree" || exit 3
export TMPDIR="$X/tmp/"
bash tests/run.sh > "$X/run.log" 2>&1; run_rc=$?
bash tests/shellcheck.sh > "$X/shellcheck.log" 2>&1; sc_rc=$?
cd "$WT" || exit 3
printf 'run.sh rc=%s; per-suite: %s\n' "$run_rc" "$(grep -E -o -- '-- [0-9]+/[0-9]+ passed' "$X/run.log" | tr '\n' ' ')"
grep -E -- '(FAIL|not ok|-- [0-9]+/[0-9]+ (failed|FAILED))' "$X/run.log" | head -40 | sed 's/^/  | /'
printf 'shellcheck rc=%s; %s\n' "$sc_rc" "$(tail -1 "$X/shellcheck.log")"
[[ "$sc_rc" == 0 ]] || sed 's/^/  | /' "$X/shellcheck.log" | head -40
suites="$(grep -E -o -- '-- [0-9]+/[0-9]+ passed' "$X/run.log" | awk -F'[ /]' '{p += $2; t += $3} END {printf "%d/%d", p, t}')"
after="$(livestate)"
printf 'live worktree status outside notes/verification/: before=%s after=%s %s\n' "$before" "$after" "$([[ "$before" == "$after" ]] && echo unchanged || echo CHANGED)"
printf 'end %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
rm -rf "$X"
printf 'suites=%s shellcheck_rc=%s run_rc=%s\n' "$suites" "$sc_rc" "$run_rc"
[[ "$run_rc" == 0 && "$sc_rc" == 0 && "$before" == "$after" ]]
