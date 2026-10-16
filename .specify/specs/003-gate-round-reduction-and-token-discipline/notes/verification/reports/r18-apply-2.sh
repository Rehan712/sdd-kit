#!/usr/bin/env bash
# Session 20: apply r18-edits/tgc-2.pairs (tests/test-gate-contracts.sh, 5 blocks), the rows matrix v6 needs that
# tgc-1 lacked, as judged in standalone copies by run 4 of r18-fixtures-judge-2 (the S03, S09 and S10 rows carrying
# one line inside their image, r18-fixtures-judge-2-run2.note; rows for R03, S07 and S08,
# r18-fixtures-judge-2-run3.note), exactly once, after checking the four files still
# hash as r18-edits/post-apply-1.sha256 and the pairs still hash as judged. Session 19's copies of the four files
# taken before r18-apply-1 are gone with its scratch directory, so they are rebuilt by reversing r18-session.diff onto
# copies of the live files and checked against r18-edits/pre-apply.sha256. Records r18-edits/post-apply-2.sha256 and
# the delta r18-session-2.diff, then r18-session.diff is rebuilt as the whole session delta against
# r18-edits/pre-apply.sha256 (session 19's kept as r18-session-1.diff), and both are proven to reverse onto their
# hashes. Pattern: r17-apply-2.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -euo pipefail
SP="${1:?scratch}"
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
E="$r/r18-edits"
files=(scripts/verification-lib.sh templates/verification-contract.md tests/test-gate-contracts.sh tests/test-spec-gate.sh)
shasum -a 256 -c "$E/post-apply-1.sha256"
echo "a48d193c82bca893a71619f435634725b0f1afba4f33e1fcb5572298be1bccae  $E/tgc-2.pairs" | shasum -a 256 -c
rm -rf "$SP/r18-pre"; mkdir -p "$SP/r18-pre"
for f in "${files[@]}"; do mkdir -p "$SP/r18-pre/$(dirname "$f")"; cp -p "$f" "$SP/r18-pre/$f"; done
( cd "$SP/r18-pre" && patch -s -R -p1 < "$OLDPWD/$r/r18-session.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
rm -rf "$SP/r18-pre2"; mkdir -p "$SP/r18-pre2/tests"; cp -p tests/test-gate-contracts.sh "$SP/r18-pre2/tests/"
out="$(perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-2.pairs")"; echo "$out"; [[ "$out" == 'applied 5 block(s) to tests/test-gate-contracts.sh' ]]
bash -n tests/test-gate-contracts.sh
shasum -a 256 "${files[@]}" > "$E/post-apply-2.sha256"
cat "$E/post-apply-2.sha256"
diff -u --label a/tests/test-gate-contracts.sh --label b/tests/test-gate-contracts.sh "$SP/r18-pre2/tests/test-gate-contracts.sh" tests/test-gate-contracts.sh > "$r/r18-session-2.diff" || [[ $? == 1 ]]
cp "$r/r18-session.diff" "$r/r18-session-1.diff"
: > "$r/r18-session.diff"
for f in "${files[@]}"; do
  diff -u --label "a/$f" --label "b/$f" "$SP/r18-pre/$f" "$f" >> "$r/r18-session.diff" || [[ $? == 1 ]]
done
# Each delta reverses exactly onto its hashes.
rm -rf "$SP/r18-rev2"; mkdir -p "$SP/r18-rev2"
for f in "${files[@]}"; do mkdir -p "$SP/r18-rev2/$(dirname "$f")"; cp -p "$f" "$SP/r18-rev2/$f"; done
( cd "$SP/r18-rev2" && patch -s -R -p1 < "$OLDPWD/$r/r18-session-2.diff" && shasum -a 256 -c "$OLDPWD/$E/post-apply-1.sha256" )
( cd "$SP/r18-rev2" && patch -s -R -p1 < "$OLDPWD/$r/r18-session-1.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
rm -rf "$SP/r18-rev3"; mkdir -p "$SP/r18-rev3"
for f in "${files[@]}"; do mkdir -p "$SP/r18-rev3/$(dirname "$f")"; cp -p "$f" "$SP/r18-rev3/$f"; done
( cd "$SP/r18-rev3" && patch -s -R -p1 < "$OLDPWD/$r/r18-session.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
wc -l "$r/r18-session-1.diff" "$r/r18-session-2.diff" "$r/r18-session.diff"
echo 'r18-apply-2 done'
