#!/usr/bin/env bash
# Pre-gate sequence after the six T030o* follow-ups were accepted (2026-09-10).
# Every stage reopened when the follow-ups landed, and the kernel edits made all
# captures stale, so Backend pays a cold re-execution and later stages reuse it.
# Re-runs T029's live AC-016 control so it carries the new typed rejection class.
# NOTHING here may edit tracked source or the STATUS Decisions log.
set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec=.specify/specs/003-gate-round-reduction-and-token-discipline
work="$spec/notes/verification/handoff/pregate-20260910"
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
printf '\nPre-gate sequence complete: current floor sealed, opponent round 1 unreserved.\n'
