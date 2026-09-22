#!/usr/bin/env bash
# Pre-gate sequence after T030o12 (the reopened O-002 fence class) was accepted.
# The kernel edit invalidated every earlier capture, so Backend pays a cold
# re-execution and the later stages reuse it. Re-runs T029's typed AC-016
# control on the repaired source, then seals a floor for opponent round 2.
#
# Writes only under notes/verification/, which vf_bookkeeping_path excludes from
# the input manifest, so this helper cannot change the source it seals.
# NOTHING here may edit tracked source or the STATUS Decisions log.
set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec=.specify/specs/003-gate-round-reduction-and-token-discipline
work="$spec/notes/verification/handoff/pregate-20260911-round3"
mkdir -p "$work"
step() { printf '\n=== %s :: %s ===\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }
for stage in Backend API Tests Observability Docs; do
  step "checkpoint $stage"
  bash scripts/spec-gate.sh checkpoint "$spec" "$stage" || exit $?
done
step 'snapshot bindings + inputs'
vf_binding_snapshot "$spec" "$work/bindings.nul" || exit 3
vf_snapshot "$spec" "$PWD" "$PWD" "$work/inputs.nul" > "$work/source.txt" || exit 3
cat "$work/source.txt"
step 'T029 typed AC-016 control'
cap="$(vf_task_current "$spec" T029 "$work/bindings.nul" "$work/inputs.nul" reuse)" || exit 3
printf 'T029 capture=%s\n' "$cap"
bash "$spec/notes/verification/handoff/control-t029.sh" "$cap" || exit $?
step 'floor'
bash scripts/spec-gate.sh floor "$spec" || exit $?
step 'tally'
bash scripts/spec-gate.sh tally "$spec" || exit $?
printf '\nPre-gate sequence complete. Ledger state, not this line, decides round state.\n'
