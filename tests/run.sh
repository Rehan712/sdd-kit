#!/usr/bin/env bash
# tests/run.sh — run the kit's own test suite.
#
# Zero dependencies beyond bash + POSIX tools + git (same floor as the kit
# itself — bash 3.2 and BSD tools are enough). Each tests/test-*.sh file is a
# self-contained suite; every test function runs in a subshell with a fresh
# $SANDBOX temp dir, so tests can't leak state into each other or the repo.
#
# Usage:
#   tests/run.sh              # all test files
#   tests/run.sh task         # only files whose name contains "task"
#
# Exit: 0 = all green, 1 = failures, 2 = no test file matches the filter.

set -u

TESTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FILTER="${1:-}"

rc=0
files=0
for f in "$TESTS_DIR"/test-*.sh; do
  [[ -f "$f" ]] || continue
  if [[ -n "$FILTER" && "$(basename "$f")" != *"$FILTER"* ]]; then continue; fi
  files=$((files+1))
  echo "== $(basename "$f")"
  # ${BASH} keeps the interpreter: `/bin/bash tests/run.sh` (macOS 3.2) must
  # not silently re-exec the suites under a newer PATH bash.
  "${BASH:-bash}" "$f" || rc=1
done

if (( files == 0 )); then
  echo "no test file matches '$FILTER'" >&2
  exit 2
fi
exit "$rc"
