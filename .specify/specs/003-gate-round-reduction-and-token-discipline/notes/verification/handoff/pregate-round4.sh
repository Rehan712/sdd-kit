#!/usr/bin/env bash
# Refresh proof after the final round-3 repair; never reserve a review here.
set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec=.specify/specs/003-gate-round-reduction-and-token-discipline
work="$spec/notes/verification/handoff/pregate-round4"
mkdir -p "$work"
for stage in Backend API Tests Observability Docs; do
  printf 'Refreshing checkpoint: %s\n' "$stage"
  bash scripts/spec-gate.sh checkpoint "$spec" "$stage" || exit $?
done
vf_binding_snapshot "$spec" "$work/bindings.nul" || exit 3
vf_snapshot "$spec" "$PWD" "$PWD" "$work/inputs.nul" > "$work/source.txt" || exit 3
cap="$(vf_task_current "$spec" T029 "$work/bindings.nul" "$work/inputs.nul" reuse)" || exit 3
bash "$spec/notes/verification/handoff/control-t029.sh" "$cap" || exit $?
bash scripts/spec-gate.sh floor "$spec" || exit $?
bash scripts/spec-gate.sh tally "$spec" || exit $?
git diff main -- . ':!.specify/specs/003-gate-round-reduction-and-token-discipline/notes' > "$spec/notes/verification/dossier/source.diff" || exit $?
git diff --stat main -- . ':!.specify/specs/003-gate-round-reduction-and-token-discipline/notes' > "$spec/notes/verification/dossier/source-stat.txt" || exit $?
git ls-files --others --exclude-standard > "$spec/notes/verification/dossier/untracked.txt" || exit $?
printf 'Proof refreshed; inspect floor-latest before reserving the authorized round.\n'
