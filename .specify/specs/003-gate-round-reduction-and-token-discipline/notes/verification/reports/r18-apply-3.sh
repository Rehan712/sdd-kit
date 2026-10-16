#!/usr/bin/env bash
# Session 20: apply r18-edits/tgc-3.pairs (tests/test-gate-contracts.sh, 2 blocks), the row matrix v6 needs for v5's
# D04 (r18-mutations-run1.note), as judged in a standalone copy by r18-fixtures-judge-3, exactly once, after checking
# the four files still hash as r18-edits/post-apply-2.sha256 and the pairs still hash as judged. The copies of the
# four files before r18-apply-1 are rebuilt by reversing r18-session.diff (the whole delta through r18-apply-2) onto
# copies of the live files and checked against r18-edits/pre-apply.sha256. Records r18-edits/post-apply-3.sha256 and
# the delta r18-session-3.diff, then r18-session.diff is rebuilt as the whole session delta against
# r18-edits/pre-apply.sha256 (session 19's apply kept as r18-session-1.diff, r18-apply-2's as r18-session-2.diff), and
# each is proven to reverse onto its hashes. Pattern: r18-apply-2.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -euo pipefail
SP="${1:?scratch}"
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
E="$r/r18-edits"
files=(scripts/verification-lib.sh templates/verification-contract.md tests/test-gate-contracts.sh tests/test-spec-gate.sh)
shasum -a 256 -c "$E/post-apply-2.sha256"
echo "a7487d4c046fa26206a617dd4370569b45c57cb1e5637b1e7c1799f80d400d5d  $E/tgc-3.pairs" | shasum -a 256 -c
rm -rf "$SP/r18-pre"; mkdir -p "$SP/r18-pre"
for f in "${files[@]}"; do mkdir -p "$SP/r18-pre/$(dirname "$f")"; cp -p "$f" "$SP/r18-pre/$f"; done
( cd "$SP/r18-pre" && patch -s -R -p1 < "$OLDPWD/$r/r18-session.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
rm -rf "$SP/r18-pre3"; mkdir -p "$SP/r18-pre3/tests"; cp -p tests/test-gate-contracts.sh "$SP/r18-pre3/tests/"
out="$(perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-3.pairs")"; echo "$out"; [[ "$out" == 'applied 2 block(s) to tests/test-gate-contracts.sh' ]]
bash -n tests/test-gate-contracts.sh
shasum -a 256 "${files[@]}" > "$E/post-apply-3.sha256"
cat "$E/post-apply-3.sha256"
diff -u --label a/tests/test-gate-contracts.sh --label b/tests/test-gate-contracts.sh "$SP/r18-pre3/tests/test-gate-contracts.sh" tests/test-gate-contracts.sh > "$r/r18-session-3.diff" || [[ $? == 1 ]]
: > "$r/r18-session.diff"
for f in "${files[@]}"; do
  diff -u --label "a/$f" --label "b/$f" "$SP/r18-pre/$f" "$f" >> "$r/r18-session.diff" || [[ $? == 1 ]]
done
# Each delta reverses exactly onto its hashes.
rm -rf "$SP/r18-rev2"; mkdir -p "$SP/r18-rev2"
for f in "${files[@]}"; do mkdir -p "$SP/r18-rev2/$(dirname "$f")"; cp -p "$f" "$SP/r18-rev2/$f"; done
( cd "$SP/r18-rev2" && patch -s -R -p1 < "$OLDPWD/$r/r18-session-3.diff" && shasum -a 256 -c "$OLDPWD/$E/post-apply-2.sha256" )
( cd "$SP/r18-rev2" && patch -s -R -p1 < "$OLDPWD/$r/r18-session-2.diff" && shasum -a 256 -c "$OLDPWD/$E/post-apply-1.sha256" )
( cd "$SP/r18-rev2" && patch -s -R -p1 < "$OLDPWD/$r/r18-session-1.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
rm -rf "$SP/r18-rev3"; mkdir -p "$SP/r18-rev3"
for f in "${files[@]}"; do mkdir -p "$SP/r18-rev3/$(dirname "$f")"; cp -p "$f" "$SP/r18-rev3/$f"; done
( cd "$SP/r18-rev3" && patch -s -R -p1 < "$OLDPWD/$r/r18-session.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
wc -l "$r/r18-session-1.diff" "$r/r18-session-2.diff" "$r/r18-session-3.diff" "$r/r18-session.diff"
echo 'r18-apply-3 done'
