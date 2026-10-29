set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$1"; own="$2"; cap=CAP-843-YAhBBt
vf_binding_snapshot "$spec" "$own/current-bindings.nul" || exit 3
vf_snapshot "$(cd "$spec" && pwd -P)" "$PWD" "$PWD" "$own/current-inputs.nul" > "$own/current-source.txt" || exit 3
vf_task_capture_matches "$own/current-bindings.nul" T031a5o1 "$spec/notes/captures/$cap"
printf 'binding_match_exit=%s\n' "$?"
for predicate in integrity current reuse; do
  vf_capture_check "$spec" "$cap" "$own/current-inputs.nul" "$predicate" > "$own/cap843-$predicate.stdout" 2> "$own/cap843-$predicate.stderr"
  printf 'capture_%s_exit=%s\n' "$predicate" "$?"
done
