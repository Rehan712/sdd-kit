#!/usr/bin/env bash
# Exploratory: which reading of vf_label yields a label for each candidate line, on the live kernel and on L17's mutant.
set -uo pipefail
S="$(cd "$(dirname "$0")" && pwd)"
lab() { # <kernel> <line>
  bash -c 'HUB_DIR="$1"; . "$1/lib.sh"; . "$2"; LC_ALL=C awk -v s="$3" "$_VF_AWK_TEXT"'"'"' BEGIN { printf "%s", vf_label(s, "class severity") }'"'"' </dev/null' _ "$S" "$1" "$2"
}
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  printf '%s\n  cur=[%s] l17=[%s]\n' "$line" "$(lab "$S/k-cur.sh" "$line")" "$(lab "$S/k-l17.sh" "$line")"
  printf '  marked: %s\n' "$(printf '%s\n' "$line" | ( cd "$S" && node render-marked.mjs ) | tr '\n' ' ')"
  printf '  mdit:   %s\n' "$(printf '%s\n' "$line" | ( cd "$S" && node render-mdit.cjs ) | tr '\n' ' ')"
done < "$S/cases.txt"
