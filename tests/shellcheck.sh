#!/usr/bin/env bash
# tests/shellcheck.sh — the kit's ShellCheck check, pinned to what the input
# identity hashes, because the check is reuse-checked (O-015 review,
# 2026-09-24). The files are scripts/*.sh and tests/*.sh as vf_source_paths
# enumerates them, never an ignored local file a shell glob would add; and
# ShellCheck reads no configuration from outside the repository: --norc skips
# every .shellcheckrc (the checked file's directory up to /, ~/.shellcheckrc
# and the XDG one) and SHELLCHECK_OPTS is unset.
#
# Usage: bash tests/shellcheck.sh
# Exit: ShellCheck's own status; 2 when the kit cannot be enumerated or holds
# no script, the same code ShellCheck uses for files it could not process --
# the stderr line says which. Any non-zero status fails the check.

set -u
# CDPATH would make the relative `cd` below search elsewhere and print into the
# substitution; BASH_ENV/ENV would reach any shell this spawns (O-015 second
# review).
unset CDPATH BASH_ENV ENV

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
. "$ROOT/scripts/verification-lib.sh"

list="$(mktemp "${TMPDIR:-/tmp}/shellcheck-files.XXXXXX")" || exit 2
if ! vf_source_paths "$ROOT" "$list"; then
  rm -f "$list"
  echo 'tests/shellcheck.sh: cannot enumerate the kit (a Git worktree is required)' >&2
  exit 2
fi
files=()
while IFS= read -r -d '' path; do
  case "$path" in
    scripts/*/*|tests/*/*) ;;
    scripts/*.sh|tests/*.sh) [[ ! -f "$ROOT/$path" ]] || files+=("$path");;
  esac
done < "$list"
rm -f "$list"
(( ${#files[@]} > 0 )) || { echo 'tests/shellcheck.sh: no scripts enumerated' >&2; exit 2; }

cd "$ROOT" || exit 2
exec env -u SHELLCHECK_OPTS shellcheck --norc -S warning -x "${files[@]}"
