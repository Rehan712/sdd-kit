#!/usr/bin/env bash
set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec=.specify/specs/003-gate-round-reduction-and-token-discipline
work="$spec/notes/verification/handoff/linux-current"
mkdir -p "$work"
for stage in Backend API Tests; do
  bash scripts/spec-gate.sh checkpoint "$spec" "$stage" || exit $?
done
vf_binding_snapshot "$spec" "$work/bindings.nul" || exit 3
vf_snapshot "$spec" "$PWD" "$PWD" "$work/inputs.nul" > "$work/source.txt" || exit 3
cap="$(vf_task_current "$spec" T028 "$work/bindings.nul" "$work/inputs.nul" reuse)" || exit 3
bash "$spec/notes/verification/handoff/return.sh" T028 "$cap" || exit $?
bash scripts/spec-gate.sh checkpoint "$spec" Observability || exit $?
cap="$(vf_task_current "$spec" T029 "$work/bindings.nul" "$work/inputs.nul" reuse)" || exit 3
bash "$spec/notes/verification/handoff/control-t029.sh" "$cap" || exit $?
bash scripts/spec-gate.sh checkpoint "$spec" Docs || exit $?
bash scripts/spec-gate.sh floor "$spec" || exit $?
printf 'Remaining implementation tasks accepted; current floor ready for independent opponent.\n'
