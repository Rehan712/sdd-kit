#!/usr/bin/env bash
# Round-17 scope, derived mechanically: per-record diff of round 16's FLOOR-UW5FIE input
# manifest against the round-17 floor named by $1 (its sealed inputs.nul, so this never
# snapshots the live tree). Pattern: r16-scope.sh. Read-only.
# Usage from the worktree root: bash <this> FLOOR-<id>
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
f="$s/notes/verification/floors"
new="${1:?round-17 floor id}"
t="$(mktemp -d "${TMPDIR:-/tmp}/r17-scope.XXXXXX")"; trap 'rm -rf "$t"' EXIT
flat() { tr '\0' '\n' < "$1" | paste - - - - - - | LC_ALL=C sort; }
src() { tr '\0' '\n' < "$f/$1/meta.nul" | grep -A1 -x source | tail -1; }
for x in FLOOR-UW5FIE "$new"; do
  [[ -f "$f/$x/inputs.nul" ]] || { echo "missing $f/$x/inputs.nul" >&2; exit 3; }
  printf '%s source=%s records=%s\n' "$x" "$(src "$x")" "$(flat "$f/$x/inputs.nul" | tee "$t/$x.tsv" | wc -l | tr -d ' ')"
done
printf '\n== FLOOR-UW5FIE -> %s: differing records (- old, + new; kind path only) ==\n' "$new"
diff "$t/FLOOR-UW5FIE.tsv" "$t/$new.tsv" > "$t/d"; drc=$?
[[ "$drc" == 0 || "$drc" == 1 ]] || { echo "diff failed rc=$drc" >&2; exit 3; }
awk -F'\t' '/^[<>]/{k=substr($1,3); printf "%s %s %s\n", ($0 ~ /^</ ? "-" : "+"), k, $2}' "$t/d" | LC_ALL=C sort -k3 -k1
printf '== distinct paths ==\n'
awk -F'\t' '/^[<>]/{print $2}' "$t/d" | LC_ALL=C sort -u
exit 0
