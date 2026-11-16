#!/usr/bin/env bash
# One-off proof that no line of the old README was dropped (spec 004, plan 4.6).
# Run from the repository root. Exit 0 all covered, 1 missing lines, 2 baseline unreadable.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"

# Prints "<line number>\t<normalised text>" per non-blank line; fence state resets per file.
norm() {
  awk '
    FNR == 1 { fence = 0 }
    {
      t = $0
      if (t ~ /^[ \t]*```/) fence = !fence
      else if (!fence) sub(/^#+/, "", t)
      gsub(/\]\([^)]*\)/, "", t)
      gsub(/[\[*]/, "", t)
      gsub(/[ \t]+/, " ", t)
      sub(/^ /, "", t); sub(/ $/, "", t)
      if (t != "") printf "%d\t%s\n", FNR, t
    }' "$@"
}

readme_coverage() {
  local tmp base n=0 m=0 miss=0 num text
  tmp="$(mktemp -d)" || return 2
  trap 'rm -rf "$tmp"' RETURN
  base="$(git merge-base HEAD origin/main 2>/dev/null)" || { echo "readme-coverage: no merge-base with origin/main" >&2; return 2; }
  git show "$base":README.md > "$tmp/old.md" 2>/dev/null || { echo "readme-coverage: cannot read README.md at $base" >&2; return 2; }
  norm "$tmp/old.md" > "$tmp/old.txt"
  norm README.md docs/*.md | cut -f2- | sort -u > "$tmp/cur.txt"
  while IFS="$(printf '\t')" read -r num text; do
    n=$((n + 1))
    printf '%s\n' "$text" | grep -qxF -f - "$tmp/cur.txt" && continue
    if grep -q "^$num " "$HERE/readme-coverage-exceptions.txt"; then m=$((m + 1)); continue; fi
    printf 'L%s: %s\n' "$num" "$text"; miss=$((miss + 1))
  done < "$tmp/old.txt"
  [ "$miss" -gt 0 ] && return 1
  echo "readme-coverage: $n lines, $m exceptions, 0 missing"
}

readme_coverage; exit $?
