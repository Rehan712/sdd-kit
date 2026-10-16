#!/usr/bin/env bash
# Session 13: apply t030o44-edits/tgc-7.pairs to tests/test-gate-contracts.sh, exactly once, after checking the four
# files hash as post-apply-5.sha256: the two image rows write `![logo](y)`, because `![x](y)` let the word reader
# skip `[x]` as a task checkbox, so matrix row L13 survived (t030o44-mutations-run1.note). Records post-apply-6.sha256.
set -euo pipefail
E=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/t030o44-edits
shasum -a 256 -c "$E/post-apply-5.sha256"
perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-7.pairs"
bash -n tests/test-gate-contracts.sh
shasum -a 256 scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh templates/verification-contract.md > "$E/post-apply-6.sha256"
cat "$E/post-apply-6.sha256"; echo 't030o44-apply-6 done'
