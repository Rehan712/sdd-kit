#!/usr/bin/env bash
# Round-10 scope, derived mechanically: per-record diff of round 9's FLOOR-k1reWt
# input manifest, FLOOR-oejTDu's, and a read-only snapshot of the live tree.
# Read-only. Run from the worktree root.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
t="$(mktemp -d "${TMPDIR:-/tmp}/r10-scope.XXXXXX")"; trap 'rm -rf "$t"' EXIT
flat() { tr '\0' '\n' < "$1" | paste - - - - - - | LC_ALL=C sort; }
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/now.nul")"
printf 'current source=%s\n' "$src"
for f in k1reWt oejTDu; do
  printf 'FLOOR-%s source=%s\n' "$f" "$(tr '\0' '\n' < "$s/notes/verification/floors/FLOOR-$f/meta.nul" | grep -A1 -x source | tail -1)"
  flat "$s/notes/verification/floors/FLOOR-$f/inputs.nul" > "$t/$f.tsv"
done
flat "$t/now.nul" > "$t/now.tsv"
printf 'records: k1reWt=%s oejTDu=%s now=%s\n' "$(wc -l < "$t/k1reWt.tsv")" "$(wc -l < "$t/oejTDu.tsv")" "$(wc -l < "$t/now.tsv")"
for pair in 'k1reWt now' 'oejTDu now'; do
  set -- $pair
  printf '\n== FLOOR-%s -> current: differing records (- old, + new; kind path only) ==\n' "$1"
  # diff exits 1 when the manifests differ, which is the expected case; capture
  # its output first so the status that ends this script is our own.
  diff "$t/$1.tsv" "$t/$2.tsv" > "$t/d"; drc=$?
  [[ "$drc" == 0 || "$drc" == 1 ]] || { echo "diff failed rc=$drc" >&2; exit 3; }
  awk -F'\t' '/^[<>]/{k=substr($1,3); printf "%s %s %s\n", ($0 ~ /^</ ? "-" : "+"), k, $2}' "$t/d" | LC_ALL=C sort -k3 -k1
  printf '== distinct paths ==\n'
  awk -F'\t' '/^[<>]/{print $2}' "$t/d" | LC_ALL=C sort -u
done
exit 0
