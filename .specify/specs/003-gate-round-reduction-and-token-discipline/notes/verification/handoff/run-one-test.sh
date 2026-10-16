#!/usr/bin/env bash
# Run selected test functions from one suite file instead of the whole suite.
#
#   bash notes/verification/handoff/run-one-test.sh tests/test-gate-contracts.sh test_instruction_contracts
#   bash notes/verification/handoff/run-one-test.sh tests/test-spec-gate.sh test_floor test_rounds
#
# Why this exists: several suites reach another suite's fixtures by sourcing it
# (`load_gate_fixtures`), which also defines that file's test_* functions — so a
# naive `t_run_all` silently runs the borrowed suite as well. Two long probe runs
# were lost to that. This driver names the functions explicitly instead.
#
# It reproduces t_run_all's contract: fresh $SANDBOX per test, each test in its
# own subshell, $_t_fail as the verdict. Failures print their assertions.
set -uo pipefail
KIT="$(git rev-parse --show-toplevel)" || exit 1
suite="${1:?usage: run-one-test.sh <suite-file> <test_fn>...}"; shift
[[ $# -gt 0 ]] || { echo 'name at least one test function' >&2; exit 2; }
. "$KIT/tests/helpers.sh"
scratch="$(mktemp "${TMPDIR:-/tmp}/suite.XXXXXX")" || exit 1
trap 'rm -f "$scratch"' EXIT
sed '/^\. .*helpers.sh/d; /^t_run_all$/d' "$KIT/$suite" > "$scratch"
# shellcheck disable=SC1090
. "$scratch"
total=0; failed=0
for fn in "$@"; do
  total=$((total+1))
  SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")" || exit 1
  export SANDBOX
  out="$( ( _t_fail=0; "$fn"; exit "$_t_fail" ) 2>&1 )"; rc=$?
  if (( rc == 0 )); then echo "  ok   $fn"
  else failed=$((failed+1)); echo "  FAIL $fn"; printf '%s\n' "$out" | sed 's/^/       /'; fi
  rm -rf "$SANDBOX"
done
echo "  -- $((total-failed))/$total passed"
(( failed == 0 ))
