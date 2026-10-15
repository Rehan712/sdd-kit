#!/usr/bin/env bash
# Session 19: apply the T030o51, T030o52 and T030o53 repair recorded in Decisions (2026-10-09), each pairs file
# exactly once, after checking the four files still hash as r18-edits/pre-apply.sha256: kernel-1
# (scripts/verification-lib.sh, 13 blocks), vc-1 (templates/verification-contract.md, 1), tgc-1
# (tests/test-gate-contracts.sh, 6), tsg-1 (tests/test-spec-gate.sh, 6). Records r18-edits/post-apply-1.sha256 and
# the delta r18-session.diff (built from copies of the four files taken before the apply, kept under <scratch>), and
# proves that the delta reverses onto the pre-apply hashes. Pattern: r17-apply-1.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -euo pipefail
SP="${1:?scratch}"
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
E="$r/r18-edits"
files=(scripts/verification-lib.sh templates/verification-contract.md tests/test-gate-contracts.sh tests/test-spec-gate.sh)
shasum -a 256 -c "$E/pre-apply.sha256"
rm -rf "$SP/r18-pre"; mkdir -p "$SP/r18-pre"
for f in "${files[@]}"; do mkdir -p "$SP/r18-pre/$(dirname "$f")"; cp -p "$f" "$SP/r18-pre/$f"; done
out="$(perl "$E/lit.pl" scripts/verification-lib.sh "$E/kernel-1.pairs")"; echo "$out"; [[ "$out" == 'applied 13 block(s) to scripts/verification-lib.sh' ]]
out="$(perl "$E/lit.pl" templates/verification-contract.md "$E/vc-1.pairs")"; echo "$out"; [[ "$out" == 'applied 1 block(s) to templates/verification-contract.md' ]]
out="$(perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-1.pairs")"; echo "$out"; [[ "$out" == 'applied 6 block(s) to tests/test-gate-contracts.sh' ]]
out="$(perl "$E/lit.pl" tests/test-spec-gate.sh "$E/tsg-1.pairs")"; echo "$out"; [[ "$out" == 'applied 6 block(s) to tests/test-spec-gate.sh' ]]
for f in scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh; do bash -n "$f"; done
shasum -a 256 "${files[@]}" > "$E/post-apply-1.sha256"
cat "$E/post-apply-1.sha256"
: > "$r/r18-session.diff"
for f in "${files[@]}"; do
  diff -u --label "a/$f" --label "b/$f" "$SP/r18-pre/$f" "$f" >> "$r/r18-session.diff" || [[ $? == 1 ]]
done
# The delta reverses exactly onto the pre-apply hashes.
rm -rf "$SP/r18-rev"; mkdir -p "$SP/r18-rev"
for f in "${files[@]}"; do mkdir -p "$SP/r18-rev/$(dirname "$f")"; cp -p "$f" "$SP/r18-rev/$f"; done
( cd "$SP/r18-rev" && patch -s -R -p1 < "$OLDPWD/$r/r18-session.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
wc -l "$r/r18-session.diff"
echo 'r18-apply-1 done'
