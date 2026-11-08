#!/bin/bash
cd /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline || exit 90
export GIT_OPTIONAL_LOCKS=0
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$PWD/.specify/specs/003-gate-round-reduction-and-token-discipline"
own="$spec/notes/verification/reports/s70-o034-option-order-verification"
phase="$1"
vf_snapshot "$spec" "$PWD" "$PWD" "$own/inputs-$phase.nul" > "$own/source-$phase.txt"
rc=$?
printf '%s\n' "$rc" > "$own/snapshot-$phase.exit"
(( rc == 0 )) || exit "$rc"
vf_binding_snapshot "$spec" "$own/bindings-$phase.nul"
rc=$?
printf '%s\n' "$rc" > "$own/bindings-$phase.exit"
(( rc == 0 )) || exit "$rc"
vf_task_info "$own/bindings-$phase.nul" T031a5o1 || exit $?
printf '%s\0' "${VF_TASK[@]}" > "$own/task-$phase.nul"
printf '%s\n' "$VF_TASK_COMMAND" > "$own/task-command-$phase.txt"
if [[ "$phase" == after ]]; then
 cap="$2"
 vf_capture_check "$spec" "$cap" "$own/inputs-after.nul" current
 rc=$?
 printf '%s\n' "$rc" > "$own/capture-current.exit"
 (( rc == 0 )) || exit "$rc"
 vf_task_capture_matches "$own/bindings-after.nul" T031a5o1 "$spec/notes/captures/$cap"
 rc=$?
 printf '%s\n' "$rc" > "$own/task-capture-matches.exit"
 (( rc == 0 )) || exit "$rc"
fi
