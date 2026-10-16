#!/usr/bin/env bash
# Session 13: apply the T030o44 review repairs recorded in Decisions (2026-10-02), each pairs file exactly once,
# after checking the four files still hash as t030o44-edits/post-apply-2.sha256: kernel-3 (scripts/verification-lib.sh),
# tgc-3 then tgc-4 then fixtures-2.pl with refuse-diags.tsv (tests/test-gate-contracts.sh), tsg-2
# (tests/test-spec-gate.sh), vc-2 (templates/verification-contract.md). Records post-apply-3.sha256.
# Usage from the worktree root: bash <this>
set -euo pipefail
E=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/t030o44-edits
shasum -a 256 -c "$E/post-apply-2.sha256"
perl "$E/lit.pl" scripts/verification-lib.sh "$E/kernel-3.pairs"
perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-3.pairs"
perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-4.pairs"
perl "$E/fixtures-2.pl" tests/test-gate-contracts.sh "$E/refuse-diags.tsv"
perl "$E/lit.pl" tests/test-spec-gate.sh "$E/tsg-2.pairs"
perl "$E/lit.pl" templates/verification-contract.md "$E/vc-2.pairs"
for f in scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh; do bash -n "$f"; done
shasum -a 256 scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh templates/verification-contract.md > "$E/post-apply-3.sha256"
cat "$E/post-apply-3.sha256"
echo 't030o44-apply-3 done'
