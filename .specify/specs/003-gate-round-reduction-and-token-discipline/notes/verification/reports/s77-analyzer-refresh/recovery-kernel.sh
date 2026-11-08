set -euo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$1"; own="$2"; phase="$3"; cap="${4:-}"
vf_binding_snapshot "$spec" "$own/recovery-bindings-$phase.nul"
vf_task_info "$own/recovery-bindings-$phase.nul" T031a5o1
printf '%s\n' "$VF_TASK_COMMAND" > "$own/recovery-command-$phase.txt"
vf_snapshot "$spec" "$PWD" "$PWD" "$own/recovery-inputs-$phase.nul" > "$own/recovery-source-$phase.txt"
if [[ -n "$cap" ]]; then
 vf_capture_check "$spec" "$cap" "$own/recovery-inputs-$phase.nul" integrity
 vf_capture_check "$spec" "$cap" "$own/recovery-inputs-$phase.nul" current
 vf_task_capture_matches "$own/recovery-bindings-$phase.nul" T031a5o1 "$spec/notes/captures/$cap"
fi
