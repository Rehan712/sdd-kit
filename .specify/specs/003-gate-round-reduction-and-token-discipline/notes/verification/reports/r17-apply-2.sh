#!/usr/bin/env bash
# Session 18: apply r17-edits/tgc-2.pairs (tests/test-gate-contracts.sh, 5 blocks), the rows matrix v5 needs that
# tgc-1 lacked, judged first in standalone copies (r17-fixtures-judge-2), exactly once, after checking the four files
# still hash as r17-edits/post-apply-1.sha256. Records r17-edits/post-apply-2.sha256 and the delta r17-session-2.diff,
# then r17-session.diff is rebuilt as the whole session delta against r17-edits/pre-apply.sha256 (session 1's kept as
# r17-session-1.diff), and both are proven to reverse onto their hashes. Pattern: r16-apply-2.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -euo pipefail
SP="${1:?scratch}"
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
E="$r/r17-edits"
files=(scripts/verification-lib.sh templates/verification-contract.md tests/test-gate-contracts.sh tests/test-spec-gate.sh)
shasum -a 256 -c "$E/post-apply-1.sha256"
( cd "$SP/r17-pre" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )  # the copies r17-apply-1 took before its apply
rm -rf "$SP/r17-pre2"; mkdir -p "$SP/r17-pre2/tests"; cp -p tests/test-gate-contracts.sh "$SP/r17-pre2/tests/"
out="$(perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-2.pairs")"; echo "$out"; [[ "$out" == 'applied 5 block(s) to tests/test-gate-contracts.sh' ]]
bash -n tests/test-gate-contracts.sh
shasum -a 256 "${files[@]}" > "$E/post-apply-2.sha256"
cat "$E/post-apply-2.sha256"
diff -u --label a/tests/test-gate-contracts.sh --label b/tests/test-gate-contracts.sh "$SP/r17-pre2/tests/test-gate-contracts.sh" tests/test-gate-contracts.sh > "$r/r17-session-2.diff" || [[ $? == 1 ]]
cp "$r/r17-session.diff" "$r/r17-session-1.diff"
: > "$r/r17-session.diff"
for f in "${files[@]}"; do
  diff -u --label "a/$f" --label "b/$f" "$SP/r17-pre/$f" "$f" >> "$r/r17-session.diff" || [[ $? == 1 ]]
done
# Each delta reverses exactly onto its hashes.
rm -rf "$SP/r17-rev2"; mkdir -p "$SP/r17-rev2"
for f in "${files[@]}"; do mkdir -p "$SP/r17-rev2/$(dirname "$f")"; cp -p "$f" "$SP/r17-rev2/$f"; done
( cd "$SP/r17-rev2" && patch -s -R -p1 < "$OLDPWD/$r/r17-session-2.diff" && shasum -a 256 -c "$OLDPWD/$E/post-apply-1.sha256" )
( cd "$SP/r17-rev2" && patch -s -R -p1 < "$OLDPWD/$r/r17-session-1.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
rm -rf "$SP/r17-rev3"; mkdir -p "$SP/r17-rev3"
for f in "${files[@]}"; do mkdir -p "$SP/r17-rev3/$(dirname "$f")"; cp -p "$f" "$SP/r17-rev3/$f"; done
( cd "$SP/r17-rev3" && patch -s -R -p1 < "$OLDPWD/$r/r17-session.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
wc -l "$r/r17-session-1.diff" "$r/r17-session-2.diff" "$r/r17-session.diff"
echo 'r17-apply-2 done'
