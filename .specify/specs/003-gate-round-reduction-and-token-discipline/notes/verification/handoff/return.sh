#!/usr/bin/env bash
set -uo pipefail
. scripts/lib.sh
. scripts/verification-lib.sh
spec=.specify/specs/003-gate-round-reduction-and-token-discipline
task="$1"; cap="$2"
mkdir -p "$spec/notes/verification/returns"
catalog="$spec/notes/verification/returns/catalog.nul"
file="$spec/notes/verification/returns/$task.txt"
vf_binding_snapshot "$spec" "$catalog" || exit 3
{
  printf 'Verification-Return: 1\nTask: %s\nCaptures: %s\nSummary: ' "$task" "$cap"
  cat "$spec/notes/captures/$cap/summary.txt"
  fields=(); rows=()
  while IFS= read -r -d '' v; do
    fields+=("$v"); (( ${#fields[@]} == 12 )) || continue
    if [[ "${fields[0]}" == binding && "${fields[2]}" == "$task" ]]; then rows+=("${fields[1]}, ${fields[7]}, $cap"); fi
    fields=()
  done < "$catalog"
  if (( ${#rows[@]} )); then printf 'Failure modes:\n'; printf '%s\n' "${rows[@]}" | LC_ALL=C sort -u
  else printf 'Failure modes: none\n'; fi
} > "$file"
rm "$catalog"
[[ "${3:-}" != --prepare ]] || exit 0
bash scripts/spec-gate.sh accept "$spec" "$task" "$file"
