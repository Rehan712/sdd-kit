#!/usr/bin/env bash
# O-029 reproduction (round 21), 2026-10-16 (session 24): in a standalone copy built from the live enumeration with a
# TMPDIR ending in `/`, apply each of the reviewer's three surviving mutants to the copy's kernel (r21-edits/
# mutants-o029-r21.py: the reconciled time replaced by 23:59:59Z of the history's date; the record's time clamped to
# that end of day when later; the future half of the --reconcile date guard removed), run round_legacy_reconcile_cases
# alone, and restore the kernel with cmp. The case passing under each mutant reproduces the finding. Live status
# outside notes/verification/ compared before and after. Pattern: r20-repro-o029.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"; s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
X="$SP/r21-repro"; rm -rf "$X"; mkdir -p "$X/tree" "$X/tmp"
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
before="$(livestate)"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$X/tree" && tar -xf - ) || exit 3
( cd "$X/tree" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || exit 3
cd "$X/tree" || exit 3
f=tests/test-spec-gate.sh; tail -1 "$f" | grep -qx t_run_all || exit 3
{ sed '$d' "$f"
  printf 'for _fn in $(declare -F | awk %s{print $3}%s | grep %s^test_%s); do unset -f "$_fn"; done\n' "'" "'" "'" "'"
  printf 'test_zz_focus() {\n  round_legacy_reconcile_cases\n}\nt_run_all\n'; } > tests/test-zz-focus.sh
cp scripts/verification-lib.sh "$X/lib.orig"
TMPDIR="$X/tmp/" bash tests/test-zz-focus.sh > "$X/none.log" 2>&1; printf 'unmutated: rc=%s\n' "$?"
all=0
for m in endofday clamp future; do
  python3 -I "$WT/$r/r21-edits/mutants-o029-r21.py" scripts/verification-lib.sh "$m" || exit 3
  TMPDIR="$X/tmp/" bash tests/test-zz-focus.sh > "$X/m.log" 2>&1; rc=$?
  printf 'round_legacy_reconcile_cases under the %s mutant: rc=%s (0 reproduces O-029)\n' "$m" "$rc"
  grep -E '^ *assert:' "$X/m.log" | sed 's/^/  | /'
  [[ "$rc" == 0 ]] || all=1
  cp "$X/lib.orig" scripts/verification-lib.sh; cmp -s "$X/lib.orig" scripts/verification-lib.sh || { echo 'kernel not restored'; exit 3; }
done
cd "$WT" || exit 3
after="$(livestate)"
printf 'live status outside notes/verification/: before=%s after=%s %s\n' "$before" "$after" "$([[ "$before" == "$after" ]] && echo unchanged || echo CHANGED)"
rm -rf "$X"
[[ "$all" == 0 && "$before" == "$after" ]]
