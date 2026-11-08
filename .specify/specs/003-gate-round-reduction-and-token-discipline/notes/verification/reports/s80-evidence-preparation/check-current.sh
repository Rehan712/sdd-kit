set -euo pipefail
export GIT_OPTIONAL_LOCKS=0
. scripts/lib.sh
. scripts/verification-lib.sh
vf_binding_snapshot "$1" "$2/bindings-before.nul"
vf_snapshot "$1" "$PWD" "$PWD" "$2/inputs-before.nul" > "$2/source-before.txt"
for item in T029:CAP-867-DSKmw1 T031a5o1:CAP-868-8wFzVs; do
 task="${item%%:*}"; cap="${item#*:}"
 vf_capture_check "$1" "$cap" "$2/inputs-before.nul" integrity
 vf_capture_check "$1" "$cap" "$2/inputs-before.nul" current
 vf_task_info "$2/bindings-before.nul" "$task"
 printf '%s\0' "$(command -v bash)" -o pipefail -c "$VF_TASK_COMMAND" > "$2/$task-argv.nul"
 cmp "$2/$task-argv.nul" "$1/notes/captures/$cap/argv.nul"
 cmp "$2/bindings-before.nul" "$1/notes/captures/$cap/bindings.nul"
 vf_locators_exist "$2/bindings-before.nul" "$task" "$PWD"
done
