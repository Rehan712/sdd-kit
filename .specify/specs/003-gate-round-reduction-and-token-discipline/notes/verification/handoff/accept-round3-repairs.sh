#!/usr/bin/env bash
# Run only after the editing/security-review barrier. Each return is accepted
# immediately after its exact Verify capture; any nonzero stops the batch.
set -uo pipefail
spec=.specify/specs/003-gate-round-reduction-and-token-discipline
for task in T030o22 T030o18 T030o19 T030o20 T030o21; do
  printf 'Capturing and accepting %s at %s\n' "$task" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  bash "$spec/notes/verification/handoff/verify-task.sh" "$task" || exit $?
done
printf 'All five round-3 follow-ups accepted.\n'
