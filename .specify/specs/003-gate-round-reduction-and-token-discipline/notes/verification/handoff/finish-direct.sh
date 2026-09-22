#!/usr/bin/env bash
set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec=.specify/specs/003-gate-round-reduction-and-token-discipline
repo="$(pwd -P)"
work="$spec/notes/verification/handoff/current"
mkdir -p "$work"
vf_binding_snapshot "$spec" "$work/bindings.nul" || exit 3
vf_snapshot "$spec" "$repo" "$repo" "$work/inputs.nul" > "$work/source.txt" || exit 3
# This helper invokes the public validators; it never writes task state itself.
accept_task() {
  local task="$1" cap
  printf 'Verifying %s\n' "$task"
  cap="$(vf_task_current "$spec" "$task" "$work/bindings.nul" "$work/inputs.nul" reuse 2>/dev/null)" || cap=''
  if [[ -n "$cap" ]]; then
    printf 'Validated reusable capture %s for %s\n' "$cap" "$task"
    bash "$spec/notes/verification/handoff/return.sh" "$task" "$cap"
  else
    bash "$spec/notes/verification/handoff/verify-task.sh" "$task"
  fi
}
while IFS=$'\t' read -r task state stage subject; do
  [[ "$state" == done ]] || continue
  vf_task_info "$work/bindings.nul" "$task" >/dev/null 2>&1 || continue
  has_receipt=0
  for receipt in "$spec/notes/verification/accepted/$task"/ACC-*; do
    [[ -f "$receipt/COMMITTED" ]] || continue
    vf_integrity "$receipt" meta.nul return.txt tasks.after digests.nul || exit 3
    [[ "$(cat "$receipt/COMMITTED")" == "$(vf_hash "$receipt/COMPLETE")" ]] || exit 3
    has_receipt=1
  done
  if (( has_receipt )); then
    printf 'Preserved authentic acceptance %s; checkpoint refreshes current execution\n' "$task"
  else accept_task "$task" || exit $?; fi
done < <(bash scripts/spec-task.sh list "$spec")
printf 'Bootstrap acceptance refreshed; Backend checkpoint\n'
bash scripts/spec-gate.sh checkpoint "$spec" Backend || exit $?
accept_task T025 || exit $?
bash scripts/spec-gate.sh checkpoint "$spec" API || exit $?
accept_task T026 || exit $?
accept_task T027 || exit $?
bash scripts/spec-gate.sh checkpoint "$spec" Tests || exit $?
accept_task T028 || exit $?
bash scripts/spec-gate.sh checkpoint "$spec" Observability || exit $?
cap="$(vf_task_current "$spec" T029 "$work/bindings.nul" "$work/inputs.nul" reuse 2>/dev/null)" || exit 3
bash "$spec/notes/verification/handoff/control-t029.sh" "$cap" || exit $?
bash scripts/spec-gate.sh checkpoint "$spec" Docs || exit $?
printf 'T001-T029 accepted; ready for final floor and opponent reservation\n'
