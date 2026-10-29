#!/usr/bin/env bash
# Round-11 scope, derived mechanically: per-record diff of round 10's FLOOR-qQEv7w input
# manifest against FLOOR-6eaaRv's (the post-T030o41 floor) and against the round-11 floor
# named by $1 (its sealed inputs.nul, so this never snapshots the live tree).
# Pattern: r10-scope.sh. Read-only. Usage from the worktree root: bash <this> [FLOOR-<id>]
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
f="$s/notes/verification/floors"
t="$(mktemp -d "${TMPDIR:-/tmp}/r11-scope.XXXXXX")"; trap 'rm -rf "$t"' EXIT
flat() { tr '\0' '\n' < "$1" | paste - - - - - - | LC_ALL=C sort; }
src() { tr '\0' '\n' < "$f/$1/meta.nul" | grep -A1 -x source | tail -1; }
floors=(FLOOR-qQEv7w FLOOR-6eaaRv); [[ -n "${1:-}" ]] && floors+=("$1")
for x in "${floors[@]}"; do
  [[ -f "$f/$x/inputs.nul" ]] || { echo "missing $f/$x/inputs.nul" >&2; exit 3; }
  printf '%s source=%s\n' "$x" "$(src "$x")"
  flat "$f/$x/inputs.nul" > "$t/$x.tsv"
done
printf 'records:'; for x in "${floors[@]}"; do printf ' %s=%s' "$x" "$(wc -l < "$t/$x.tsv" | tr -d ' ')"; done; printf '\n'
pairs=('FLOOR-qQEv7w FLOOR-6eaaRv')
[[ -n "${1:-}" ]] && pairs+=("FLOOR-qQEv7w $1" "FLOOR-6eaaRv $1")
for pair in "${pairs[@]}"; do
  set -- $pair
  printf '\n== %s -> %s: differing records (- old, + new; kind path only) ==\n' "$1" "$2"
  # diff exits 1 when the manifests differ, the expected case; capture its status first.
  diff "$t/$1.tsv" "$t/$2.tsv" > "$t/d"; drc=$?
  [[ "$drc" == 0 || "$drc" == 1 ]] || { echo "diff failed rc=$drc" >&2; exit 3; }
  awk -F'\t' '/^[<>]/{k=substr($1,3); printf "%s %s %s\n", ($0 ~ /^</ ? "-" : "+"), k, $2}' "$t/d" | LC_ALL=C sort -k3 -k1
  printf '== distinct paths ==\n'
  awk -F'\t' '/^[<>]/{print $2}' "$t/d" | LC_ALL=C sort -u
done
exit 0
