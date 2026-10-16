#!/usr/bin/env bash
# Session 16: apply r16-edits/tgc-2.pairs (the L17 isolating rows, judged by r16-fixtures-judge-2) to
# tests/test-gate-contracts.sh, exactly once (2 blocks), after checking the four files hash as
# r16-edits/pre-apply.sha256 (= r15-edits/post-apply-1). Records r16-edits/post-apply-2.sha256, keeps the first apply's
# delta as r16-session-1.diff, writes this apply's delta as r16-session-2.diff and the whole session delta against
# the files before T030o47 (the copies r16-apply-1 kept under <scratch>/r16-pre) as r16-session.diff, and proves
# that the whole delta reverses onto r15-edits/pre-apply.sha256. Pattern: r15-apply-2.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -euo pipefail
SP="${1:?scratch}"
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
E="$r/r16-edits"
files=(scripts/verification-lib.sh templates/verification-contract.md tests/test-gate-contracts.sh tests/test-spec-gate.sh)
shasum -a 256 -c "$E/pre-apply.sha256"
for f in "${files[@]}"; do [[ -f "$SP/r16-pre/$f" ]]; done
shasum -a 256 -c <(sed "s#  #  $SP/r16-pre/#" "$r/r15-edits/pre-apply.sha256")
rm -rf "$SP/r16-mid"; mkdir -p "$SP/r16-mid/tests"; cp -p tests/test-gate-contracts.sh "$SP/r16-mid/tests/"
out="$(perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-2.pairs")"; echo "$out"
[[ "$out" == 'applied 2 block(s) to tests/test-gate-contracts.sh' ]]
bash -n tests/test-gate-contracts.sh
shasum -a 256 "${files[@]}" > "$E/post-apply-2.sha256"
cat "$E/post-apply-2.sha256"
[[ -e "$r/r16-session-1.diff" ]] || cp -p "$r/r16-session.diff" "$r/r16-session-1.diff"
diff -u --label a/tests/test-gate-contracts.sh --label b/tests/test-gate-contracts.sh \
  "$SP/r16-mid/tests/test-gate-contracts.sh" tests/test-gate-contracts.sh > "$r/r16-session-2.diff" || [[ $? == 1 ]]
: > "$r/r16-session.diff"
for f in "${files[@]}"; do
  diff -u --label "a/$f" --label "b/$f" "$SP/r16-pre/$f" "$f" >> "$r/r16-session.diff" || [[ $? == 1 ]]
done
rm -rf "$SP/r16-rev"; mkdir -p "$SP/r16-rev"
for f in "${files[@]}"; do mkdir -p "$SP/r16-rev/$(dirname "$f")"; cp -p "$f" "$SP/r16-rev/$f"; done
( cd "$SP/r16-rev" && patch -s -R -p1 < "$OLDPWD/$r/r16-session.diff" && shasum -a 256 -c "$OLDPWD/$r/r15-edits/pre-apply.sha256" )
wc -l "$r/r16-session-1.diff" "$r/r16-session-2.diff" "$r/r16-session.diff"
echo 'r16-apply-2 done'
