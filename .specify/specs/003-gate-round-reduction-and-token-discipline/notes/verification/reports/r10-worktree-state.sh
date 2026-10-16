#!/usr/bin/env bash
# Worktree-state tripwire for the round-10 reservation window. Read-only.
# Usage from the worktree root: bash <this> <label>  -> r10-state-<label>.txt
# Records the whole-source digest plus the content hash and mode of EVERY
# non-ignored path (tracked and untracked, bookkeeping included) except
# <spec>/notes/verification/, where receipts and the returned report live.
# Two states taken around the reviewer's run must be byte-identical.
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
label="${1:?label}"
out="$r/r10-state-$label.txt"
[[ ! -e "$out" ]] || { echo "refusing: $out exists" >&2; exit 2; }
t="$(mktemp -d "${TMPDIR:-/tmp}/r10-state.XXXXXX")"; trap 'rm -rf "$t"' EXIT
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")" || { echo "snapshot failed" >&2; exit 3; }
git ls-files -z --cached --others --exclude-standard | tr '\0' '\n' | grep -v -F "$s/notes/verification/" | LC_ALL=C sort -u > "$t/paths"
: > "$t/entries"
while IFS= read -r p; do
  if [[ -L "$p" ]]; then printf 'link\t%s\t%s\n' "$(readlink "$p")" "$p"
  elif [[ -f "$p" ]]; then
    m=100644; [[ -x "$p" ]] && m=100755
    printf '%s\t%s\t%s\n' "$m" "$(git hash-object --no-filters -- "$p")" "$p"
  elif [[ -e "$p" ]]; then printf 'other\t-\t%s\n' "$p"
  else printf 'absent\t-\t%s\n' "$p"; fi
done < "$t/paths" > "$t/entries"
{
  printf 'label=%s taken=%s\n' "$label" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'source=%s\n' "$src"
  printf 'paths=%s entries-digest=%s\n' "$(wc -l < "$t/paths" | tr -d ' ')" "$(vf_hash "$t/entries")"
  printf 'head=%s\n' "$(git rev-parse HEAD)"
  printf 'index-digest=%s\n' "$(git ls-files -s | vf_hash /dev/stdin)"
} > "$out"
cp "$t/entries" "$r/r10-state-$label.entries"
cat "$out"
