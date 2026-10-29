#!/usr/bin/env bash
set -euo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec="$1"
cap="$2"
receipt="$3"
vf_capture_check "$spec" "$cap" '' integrity
printf 'capture integrity: PASS\n'
vf_binding_snapshot "$spec" "$receipt/current-bindings.nul"
vf_task_capture_matches "$receipt/current-bindings.nul" T031a5o1 "$spec/notes/captures/$cap"
printf 'current task/capture/locator binding: PASS\n'
