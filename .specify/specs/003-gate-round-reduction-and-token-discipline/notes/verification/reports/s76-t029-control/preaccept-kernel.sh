set -euo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$1"; own="$2"
vf_binding_snapshot "$spec" "$own/preaccept-bindings.nul"
vf_snapshot "$spec" "$PWD" "$PWD" "$own/preaccept-inputs.nul" > "$own/preaccept-source.txt"
vf_capture_check "$spec" CAP-867-DSKmw1 "$own/preaccept-inputs.nul" integrity
vf_capture_check "$spec" CAP-867-DSKmw1 "$own/preaccept-inputs.nul" current
vf_task_capture_matches "$own/preaccept-bindings.nul" T029 "$spec/notes/captures/CAP-867-DSKmw1"
