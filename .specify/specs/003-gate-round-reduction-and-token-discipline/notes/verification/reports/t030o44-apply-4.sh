#!/usr/bin/env bash
# Session 13: apply t030o44-edits/tgc-5.pairs (fixture rows that isolate guards of the session-13 kernel no
# earlier row isolated) to tests/test-gate-contracts.sh, exactly once, after checking the four files hash as
# post-apply-3.sha256. Records post-apply-4.sha256.
set -euo pipefail
E=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/t030o44-edits
shasum -a 256 -c "$E/post-apply-3.sha256"
perl "$E/lit.pl" tests/test-gate-contracts.sh "$E/tgc-5.pairs"
bash -n tests/test-gate-contracts.sh
shasum -a 256 scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh templates/verification-contract.md > "$E/post-apply-4.sha256"
cat "$E/post-apply-4.sha256"; echo 't030o44-apply-4 done'
