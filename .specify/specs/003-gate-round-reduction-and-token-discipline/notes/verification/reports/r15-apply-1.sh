#!/usr/bin/env bash
# Session 15: apply the T030o45/T030o46 repair recorded in Decisions (2026-10-07), each pairs file exactly once,
# after checking the four files still hash as r14-edits/pre-apply.sha256: kernel-1 (scripts/verification-lib.sh),
# vc-1 (templates/verification-contract.md), tgc-1 (tests/test-gate-contracts.sh), tsg-1 (tests/test-spec-gate.sh).
# Records r14-edits/post-apply-1.sha256 and the delta r15-session.diff (built from copies of the four files taken
# before the apply, kept under <scratch>). Pattern: t030o44-apply-3.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -euo pipefail
SP="${1:?scratch}"
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
E="$r/r14-edits"
files=(scripts/verification-lib.sh templates/verification-contract.md tests/test-gate-contracts.sh tests/test-spec-gate.sh)
shasum -a 256 -c "$E/pre-apply.sha256"
rm -rf "$SP/r15-pre"; mkdir -p "$SP/r15-pre"
for f in "${files[@]}"; do mkdir -p "$SP/r15-pre/$(dirname "$f")"; cp -p "$f" "$SP/r15-pre/$f"; done
perl "$E/lit.pl" scripts/verification-lib.sh "$E/kernel-1.pairs"
perl "$E/lit.pl" templates/verification-contract.md "$E/vc-1.pairs"
perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-1.pairs"
perl "$E/lit.pl" tests/test-spec-gate.sh "$E/tsg-1.pairs"
for f in scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh; do bash -n "$f"; done
shasum -a 256 "${files[@]}" > "$E/post-apply-1.sha256"
cat "$E/post-apply-1.sha256"
: > "$r/r15-session.diff"
for f in "${files[@]}"; do
  diff -u --label "a/$f" --label "b/$f" "$SP/r15-pre/$f" "$f" >> "$r/r15-session.diff" || [[ $? == 1 ]]
done
# The delta reverses exactly onto the pre-apply hashes.
rm -rf "$SP/r15-rev"; mkdir -p "$SP/r15-rev"
for f in "${files[@]}"; do mkdir -p "$SP/r15-rev/$(dirname "$f")"; cp -p "$f" "$SP/r15-rev/$f"; done
( cd "$SP/r15-rev" && patch -s -R -p1 < "$OLDPWD/$r/r15-session.diff" && shasum -a 256 -c "$OLDPWD/$E/pre-apply.sha256" )
wc -l "$r/r15-session.diff"
echo 'r15-apply-1 done'
