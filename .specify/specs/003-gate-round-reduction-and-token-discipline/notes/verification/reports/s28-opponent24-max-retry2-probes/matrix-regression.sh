#!/bin/bash
. "$1/tests/defs-test-gate-contracts.sh"
export SANDBOX="$2"
mkdir -p "$SANDBOX"
matrix_runtime_cases
printf 'matrix assertions failed=%s
' "$_t_fail"
exit "$_t_fail"
