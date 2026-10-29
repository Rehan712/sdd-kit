#!/usr/bin/env bash
# Session 10 pre-check, before any Decisions entry: the O-010 superseded-environment scan
# (tests/test-gate-contracts.sh::superseded_environment_scan, run inside the reuse-checked suite) reports
# nothing on a copy of the live enumeration with every session-10 candidate applied (helpers-1, tv-5,
# vc-6, kernel-8 and the task-block correction tasks-fix-6), and nothing on the live tree's copy.
# Read-only against the live worktree. Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"; s=.specify/specs/003-gate-round-reduction-and-token-discipline
E="$WT/$s/notes/verification/reports/t030o43-edits"; M="$SP/t030o43-o010-precheck"; rm -rf "$M"; mkdir -p "$M/tmp"
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
for k in CUR D; do
  mkdir -p "$M/$k"
  ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$M/$k" && tar -xf - ) || exit 2
  if [[ $k == D ]]; then
    for p in "tests/helpers.sh helpers-1" "tests/test-verification.sh tv-5" "templates/verification-contract.md vc-6" \
             "scripts/verification-lib.sh kernel-8" "$s/tasks.md tasks-fix-6"; do
      perl "$E/lit.pl" "$M/D/${p% *}" "$E/${p#* }.pairs" || exit 2
    done
  fi
  ( cd "$M/$k" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid commit -qm base ) > /dev/null || exit 2
  # The case file lives beside the suite (tests/), as the matrix's judge puts it, so the suite's own
  # dirname-based load of helpers.sh resolves; it is git-excluded, so the scan never enumerates it.
  printf 'tests/.one-*.sh\n' >> "$M/$k/.git/info/exclude"
  awk '$0 != "t_run_all"' "$M/$k/tests/test-gate-contracts.sh" > "$M/$k/tests/.one-gc.sh" || exit 2
  out="$( cd "$M/$k" && TMPDIR="$M/tmp/" bash -c '. tests/.one-gc.sh; superseded_environment_scan "$PWD"' 2>&1 )"; rc=$?
  check "$k scan exit 0" 0 "$rc"
  check "$k scan reports no superseded claim" '' "$out"
  [[ -z "$out" ]] || printf '%s\n' "$out" | sed 's/^/  | /'
done
rm -rf "$M"
echo "t030o43-o010-precheck failures=$fails"
(( fails == 0 ))
