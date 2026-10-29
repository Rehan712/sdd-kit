#!/usr/bin/env bash
# Session 18: apply the T030o48, T030o49 and T030o50 repair recorded in Decisions (2026-10-08), each pairs file
# exactly once, after checking the four files still hash as r17-edits/pre-apply.sha256: kernel-1
# (scripts/verification-lib.sh, 6 blocks), vc-1 (templates/verification-contract.md, 1), tgc-1
# (tests/test-gate-contracts.sh, 7), tsg-1 (tests/test-spec-gate.sh, 4). Records r17-edits/post-apply-1.sha256 and
# the delta r17-session.diff (built from copies of the four files taken before the apply, kept under <scratch>), and
# proves that the delta reverses onto the pre-apply hashes. Pattern: r16-apply-1.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -euo pipefail
SP="${1:?scratch}"
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
E="$r/r17-edits"
files=(scripts/verification-lib.sh templates/verification-contract.md tests/test-gate-contracts.sh tests/test-spec-gate.sh)
shasum -a 256 -c "$E/pre-apply.sha256"
rm -rf "$SP/r17-pre"; mkdir -p "$SP/r17-pre"
for f in "${files[@]}"; do mkdir -p "$SP/r17-pre/$(dirname "$f")"; cp -p "$f" "$SP/r17-pre/$f"; done
out="$(perl "$E/lit.pl" scripts/verification-lib.sh "$E/kernel-1.pairs")"; echo "$out"; [[ "$out" == 'applied 6 block(s) to scripts/verification-lib.sh' ]]
out="$(perl "$E/lit.pl" templates/verification-contract.md "$E/vc-1.pairs")"; echo "$out"; [[ "$out" == 'applied 1 block(s) to templates/verification-contract.md' ]]
out="$(perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-1.pairs")"; echo "$out"; [[ "$out" == 'applied 7 block(s) to tests/test-gate-contracts.sh' ]]
out="$(perl "$E/lit.pl" tests/test-spec-gate.sh "$E/tsg-1.pairs")"; echo "$out"; [[ "$out" == 'applied 4 block(s) to tests/test-spec-gate.sh' ]]
for f in scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh; do bash -n "$f"; done
shasum -a 256 "${files[@]}" > "$E/post-apply-1.sha256"
cat "$E/post-apply-1.sha256"
: > "$r/r17-session.diff"
for f in "${files[@]}"; do
  diff -u --label "a/$f" --label "b/$f" "$SP/r17-pre/$f" "$f" >> "$r/r17-session.diff" || [[ $? == 1 ]]
done
# The delta reverses exactly onto the pre-apply hashes.
rm -rf "$SP/r17-rev"; mkdir -p "$SP/r17-rev"
for f in "${files[@]}"; do mkdir -p "$SP/r17-rev/$(dirname "$f")"; cp -p "$f" "$SP/r17-rev/$f"; done
( cd "$SP/r17-rev" && patch -s -R -p1 < "$OLDPWD/$r/r17-session.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
wc -l "$r/r17-session.diff"
echo 'r17-apply-1 done'
