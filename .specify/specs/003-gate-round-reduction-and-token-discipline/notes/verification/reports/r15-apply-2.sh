#!/usr/bin/env bash
# Session 15: apply the fixture correction r14-edits/tgc-2.pairs (tests/test-gate-contracts.sh) exactly once, after
# checking the four files still hash as r14-edits/post-apply-1.sha256, and only after r15-fixtures-judge-2 exited 0.
# It adds the row that isolates the first rendered reading (matrix row L18, found passing for the wrong reason by
# r14-mutations-probe). Records r14-edits/post-apply-2.sha256 and appends the change to r15-session.diff, whose
# reversal must then give r14-edits/pre-apply.sha256 again. Pattern: r15-apply-1.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -euo pipefail
SP="${1:?scratch}"
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
E="$r/r14-edits"
files=(scripts/verification-lib.sh templates/verification-contract.md tests/test-gate-contracts.sh tests/test-spec-gate.sh)
[[ "$(cat "$r/r15-fixtures-judge-2.rc")" == 0 ]]
shasum -a 256 -c "$E/post-apply-1.sha256"
rm -rf "$SP/r15-pre-2"; mkdir -p "$SP/r15-pre-2/tests"; cp -p tests/test-gate-contracts.sh "$SP/r15-pre-2/tests/"
perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-2.pairs"
bash -n tests/test-gate-contracts.sh
shasum -a 256 "${files[@]}" > "$E/post-apply-2.sha256"
cat "$E/post-apply-2.sha256"
cp "$r/r15-session.diff" "$r/r15-session-1.diff"
diff -u --label a/tests/test-gate-contracts.sh --label b/tests/test-gate-contracts.sh \
  "$SP/r15-pre-2/tests/test-gate-contracts.sh" tests/test-gate-contracts.sh > "$r/r15-session-2.diff" || [[ $? == 1 ]]
# The whole session delta, against the pre-apply files: rebuilt from them in a scratch tree.
rm -rf "$SP/r15-whole"; mkdir -p "$SP/r15-whole"
for f in "${files[@]}"; do mkdir -p "$SP/r15-whole/$(dirname "$f")"; cp -p "$f" "$SP/r15-whole/$f"; done
( cd "$SP/r15-whole" && patch -s -R -p1 < "$OLDPWD/$r/r15-session-2.diff" && patch -s -R -p1 < "$OLDPWD/$r/r15-session-1.diff" \
  && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
: > "$r/r15-session.diff"
for f in "${files[@]}"; do
  diff -u --label "a/$f" --label "b/$f" "$SP/r15-whole/$f" "$f" >> "$r/r15-session.diff" || [[ $? == 1 ]]
done
rm -rf "$SP/r15-rev"; mkdir -p "$SP/r15-rev"
for f in "${files[@]}"; do mkdir -p "$SP/r15-rev/$(dirname "$f")"; cp -p "$f" "$SP/r15-rev/$f"; done
( cd "$SP/r15-rev" && patch -s -R -p1 < "$OLDPWD/$r/r15-session.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
wc -l "$r/r15-session-1.diff" "$r/r15-session-2.diff" "$r/r15-session.diff"
echo 'r15-apply-2 done'
