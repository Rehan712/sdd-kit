#!/usr/bin/env bash
# R3-4 member derivation, 2026-09-24 (session 4). Read-only.
# Usage: bash t030o41-r34-search.sh <kit tree>
# Lists every read the suites make of live-kit content through a load-time
# alias that names a DIRECTORY or a GLOB, rather than one file. The aliases are
# derived, not assumed: every top-level assignment in tests/*.sh built from
# KIT_DIR, SCRIPTS or BASH_SOURCE. Each alias occurrence is resolved to a
# repository path; it is a candidate when the token is the bare alias, ends in
# '/', carries a glob character, or resolves to a directory in the tree.
# Variable-named members ($file, $f, ...) are printed with the loop that binds
# them so a reader can see whether the names come from a literal list.
set -uo pipefail
K="$1"; cd "$K" || exit 2
echo '== load-time aliases (top-level assignments in tests/*.sh)'
grep -n -E '^[A-Z_][A-Z0-9_]*=.*(KIT_DIR|SCRIPTS|BASH_SOURCE)' tests/*.sh
aliases="$(grep -h -o -E '^[A-Z_][A-Z0-9_]*=' tests/*.sh | tr -d = | sort -u | tr '\n' '|')"
aliases="${aliases%|}"
echo "== alias names: $aliases"
resolve() { # <alias> -> repository-relative directory it names ('' when a file or unknown)
  case "$1" in
    KIT_DIR) printf '.';; SCRIPTS) printf 'scripts';;
    EXAMPLE) printf 'templates/examples/001-api-key-expiry';; FIXTURES) printf 'tests/fixtures/usage-limits';;
    *) printf '';;
  esac
}
echo '== directory-or-glob reads (candidates), excluding comments and the alias definitions'
n=0
while IFS= read -r hit; do
  file="${hit%%:*}"; rest="${hit#*:}"; line="${rest%%:*}"; tok="${rest#*:}"
  src="$(sed -n "${line}p" "$file")"
  [[ "$(printf '%s' "$src" | sed 's/^[[:space:]]*//' | cut -c1)" != '#' ]] || continue
  printf '%s' "$src" | grep -q -E '^[A-Z_][A-Z0-9_]*=' && continue
  name="$(printf '%s' "$tok" | sed -E 's/^"?\$\{?([A-Z_][A-Z0-9_]*)\}?.*/\1/')"
  base="$(resolve "$name")"; [[ -n "$base" ]] || continue
  tail="$(printf '%s' "$tok" | sed -E 's/^"?\$\{?[A-Z_][A-Z0-9_]*\}?//; s/"//g')"
  why=''
  if [[ -z "$tail" ]]; then why=bare
  elif [[ "$tail" == */ ]]; then why=trailing-slash
  elif [[ "$tail" == *'*'* || "$tail" == *'?'* || "$tail" == *'['* ]]; then why=glob
  elif [[ "$tail" == *'$'* ]]; then why=variable-member
  elif [[ -d "$base$tail" || -d "./$base$tail" ]]; then why=directory
  fi
  [[ -n "$why" ]] || continue
  n=$((n+1)); printf '%s:%s [%s] %s\n    %s\n' "$file" "$line" "$why" "$tok" "$(printf '%s' "$src" | sed 's/^[[:space:]]*//' | cut -c1-200)"
done < <(grep -n -o -E '"?\$\{?('"$aliases"')\}?[^ ;)|&>]*' tests/*.sh | sed -E 's/^([^:]+):([0-9]+):/\1:\2:/')
echo "== candidates: $n"
