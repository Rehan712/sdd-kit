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
# Exit: 0 = all green, 1 = failures (or a kit that cannot be enumerated),
#       2 = no test file matches the filter.

set -u
# Bash's own environment, cleared before any path is resolved: CDPATH makes a
# relative `cd` search elsewhere and print into the substitution below, and
# BASH_ENV/ENV would make every suite's shell source a file from outside the
# repository first (O-015 second review; tests/helpers.sh clears them too).
unset CDPATH BASH_ENV ENV

TESTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FILTER="${1:-}"

# The suites are tests/test-*.sh as vf_source_paths enumerates them -- the list
# the input identity hashes -- never a shell glob, which would also run an
# ignored local file and let it decide this reuse-checked command (O-015
# review, 2026-09-24).
ROOT="$(cd -- "$TESTS_DIR/.." && pwd -P)"
. "$ROOT/scripts/verification-lib.sh"
list="$(mktemp "${TMPDIR:-/tmp}/run-suites.XXXXXX")" || exit 1
if ! vf_source_paths "$ROOT" "$list"; then
  rm -f "$list"
  echo 'tests/run.sh: cannot enumerate the kit (a Git worktree is required)' >&2
  exit 1
fi
suites=()
while IFS= read -r -d '' path; do
  case "$path" in tests/*/*) ;; tests/test-*.sh) suites+=("$ROOT/$path");; esac
done < "$list"
rm -f "$list"

rc=0
files=0
for f in ${suites[@]+"${suites[@]}"}; do
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
