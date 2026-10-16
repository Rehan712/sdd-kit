#!/usr/bin/env bash
# O-029 reproduction (round 20), 2026-10-16 (session 23): in a standalone copy built from the live enumeration with a
# TMPDIR ending in `/`, apply the reviewer's "timestamp ignored" mutant (VF_ROUND_TIME from the history's date at
# midnight instead of the reconciled record) and run round_legacy_reconcile_cases alone; the case passing under the
# mutant reproduces the finding. Live status outside notes/verification/ compared before and after.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"; s=.specify/specs/003-gate-round-reduction-and-token-discipline
X="$SP/r20-repro"; rm -rf "$X"; mkdir -p "$X/tree" "$X/tmp"
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
before="$(livestate)"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$X/tree" && tar -xf - ) || exit 3
( cd "$X/tree" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || exit 3
cd "$X/tree" || exit 3
python3 -I - scripts/verification-lib.sh <<'PY' || exit 3
import sys
p = sys.argv[1]; t = open(p, encoding='utf-8').read()
old = '    VF_ROUND_TIME="$(vf_meta_get timestamp)"; vf_utc_valid "$VF_ROUND_TIME" || return 3\n'
assert t.count(old) == 1
t = t.replace(old, '    VF_ROUND_TIME="${VF_ROUND_DATE}T00:00:00Z"; vf_utc_valid "$VF_ROUND_TIME" || return 3\n')
open(p, 'w', encoding='utf-8').write(t)
print('mutant applied: VF_ROUND_TIME from the history date at midnight')
PY
f=tests/test-spec-gate.sh; tail -1 "$f" | grep -qx t_run_all || exit 3
{ sed '$d' "$f"
  printf 'for _fn in $(declare -F | awk %s{print $3}%s | grep %s^test_%s); do unset -f "$_fn"; done\n' "'" "'" "'" "'"
  printf 'test_zz_focus() {\n  round_legacy_reconcile_cases\n}\nt_run_all\n'; } > tests/test-zz-focus.sh
TMPDIR="$X/tmp/" bash tests/test-zz-focus.sh; rc=$?
cd "$WT" || exit 3
after="$(livestate)"
printf 'round_legacy_reconcile_cases under the mutant: rc=%s (0 reproduces O-029)\n' "$rc"
printf 'live status outside notes/verification/: before=%s after=%s %s\n' "$before" "$after" "$([[ "$before" == "$after" ]] && echo unchanged || echo CHANGED)"
rm -rf "$X"
[[ "$rc" == 0 && "$before" == "$after" ]]
