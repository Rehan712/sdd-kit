#!/usr/bin/env bash
# Resume the remaining 003 implementation on macOS. Mirrors finish-remaining-linux.sh:
# refresh every stage checkpoint on the current environment manifest, accept T028,
# run T029's real rejected-copy/intact-acceptance control, then seal a current floor.
set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec=.specify/specs/003-gate-round-reduction-and-token-discipline
work="$spec/notes/verification/handoff/macos-current"
mkdir -p "$work"
step() { printf '\n=== %s :: %s ===\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }
for stage in Backend API Tests; do
  step "checkpoint $stage"
  bash scripts/spec-gate.sh checkpoint "$spec" "$stage" || exit $?
done
step 'snapshot bindings + inputs'
vf_binding_snapshot "$spec" "$work/bindings.nul" || exit 3
vf_snapshot "$spec" "$PWD" "$PWD" "$work/inputs.nul" > "$work/source.txt" || exit 3
cat "$work/source.txt"
step 'T028 accept'
cap="$(vf_task_current "$spec" T028 "$work/bindings.nul" "$work/inputs.nul" reuse)" || exit 3
printf 'T028 capture=%s\n' "$cap"
bash "$spec/notes/verification/handoff/return.sh" T028 "$cap" || exit $?
step 'checkpoint Observability'
bash scripts/spec-gate.sh checkpoint "$spec" Observability || exit $?
step 'T029 control + accept'
cap="$(vf_task_current "$spec" T029 "$work/bindings.nul" "$work/inputs.nul" reuse)" || exit 3
printf 'T029 capture=%s\n' "$cap"
bash "$spec/notes/verification/handoff/control-t029.sh" "$cap" || exit $?
step 'checkpoint Docs'
bash scripts/spec-gate.sh checkpoint "$spec" Docs || exit $?
step 'floor'
bash scripts/spec-gate.sh floor "$spec" || exit $?
printf '\nRemaining implementation tasks accepted; current floor ready for the independent opponent.\n'
