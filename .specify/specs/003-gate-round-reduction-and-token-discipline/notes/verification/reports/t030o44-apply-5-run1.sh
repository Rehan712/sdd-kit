#!/usr/bin/env bash
# Session 13: apply t030o44-edits/tgc-6.pairs (the last fixture rows that isolate guards of the session-13 kernel
# found while writing the matrix) to tests/test-gate-contracts.sh, exactly once, after checking the four files hash as
# post-apply-4.sha256. Records post-apply-5.sha256.
set -euo pipefail
E=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/t030o44-edits
shasum -a 256 -c "$E/post-apply-5.sha256"
perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-6.pairs"
bash -n tests/test-gate-contracts.sh
shasum -a 256 scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh templates/verification-contract.md > "$E/post-apply-5.sha256"
cat "$E/post-apply-4.sha256"; echo 't030o44-apply-5 done'
