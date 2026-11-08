#!/usr/bin/env bash
# Build the hosted-CI snapshot tree of the exact non-ignored worktree through a
# temporary index (real index, HEAD and spec branch untouched), then prove the
# per-file mapping to the current verification source identity.
# Usage (from the worktree root): build-snapshot.sh <out-dir>
set -euo pipefail
out="$1"
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
mkdir -p "$out"
[[ ! -e "$out/index" ]] || { echo "refusing: $out/index exists" >&2; exit 3; }

# 1. Current source identity (same call the audit and floor use).
source_id="$(vf_snapshot "$s" "$PWD" "$PWD" "$out/inputs.nul")"
printf 'source=%s\n' "$source_id"

# 2. Snapshot tree: exactly the path set vf_snapshot enumerates.
git ls-files --cached --others --exclude-standard -z > "$out/paths.nul"
[[ "$(tr -cd '\n' < "$out/paths.nul" | wc -c | tr -d ' ')" == 0 ]] || { echo "refusing: a path contains a newline" >&2; exit 3; }
GIT_INDEX_FILE="$out/index" git read-tree --empty
GIT_INDEX_FILE="$out/index" git update-index --add -z --stdin < "$out/paths.nul"
tree="$(GIT_INDEX_FILE="$out/index" git write-tree)"
printf 'tree=%s\n' "$tree"
git ls-tree -r -z "$tree" > "$out/tree.nul"
tr '\0' '\n' < "$out/tree.nul" > "$out/tree.txt"
tree_entries="$(wc -l < "$out/tree.txt" | tr -d ' ')"
listed="$(tr -cd '\0' < "$out/paths.nul" | wc -c | tr -d ' ')"
printf 'listed-paths=%s tree-entries=%s\n' "$listed" "$tree_entries"
[[ "$listed" == "$tree_entries" ]] || { echo "mapping FAIL: listed paths != tree entries" >&2; exit 1; }

# 3. Every manifest path record must match its tree entry after the same
#    semantic transform, with the same mode.
: > "$out/record-paths.txt"
checked=0 files=0 links=0 missing=0 bad=0
while IFS= read -r -d '' type && IFS= read -r -d '' p && IFS= read -r -d '' f3 &&
      IFS= read -r -d '' f4 && IFS= read -r -d '' f5 && IFS= read -r -d '' f6; do
  [[ "$type" == path ]] || continue
  checked=$((checked+1))
  printf '%s\n' "$p" >> "$out/record-paths.txt"
  entry="$(git ls-tree -z "$tree" -- "$p" | tr -d '\0')"
  case "$f3" in
    file)
      files=$((files+1))
      [[ -n "$entry" ]] || { echo "mapping FAIL: $p missing from tree"; bad=$((bad+1)); continue; }
      mode="${entry%% *}"; oid="${entry#* blob }"; oid="${oid%%$'\t'*}"
      [[ "$mode" == "$f4" ]] || { echo "mapping FAIL: $p mode tree=$mode manifest=$f4"; bad=$((bad+1)); }
      git cat-file blob "$oid" > "$out/blob"
      vf_semantic_file "$p" "$out/blob" "$out/semantic"
      [[ "$(vf_hash "$out/semantic")" == "$f5" ]] || { echo "mapping FAIL: $p content digest differs"; bad=$((bad+1)); }
      ;;
    link)
      links=$((links+1))
      mode="${entry%% *}"; oid="${entry#* blob }"; oid="${oid%%$'\t'*}"
      [[ "$mode" == 120000 && "$(git cat-file blob "$oid")" == "$f6" ]] || { echo "mapping FAIL: link $p"; bad=$((bad+1)); }
      ;;
    missing)
      missing=$((missing+1))
      [[ -z "$entry" ]] || { echo "mapping FAIL: $p is missing in the worktree but present in tree"; bad=$((bad+1)); }
      ;;
    *) echo "mapping FAIL: unknown record type $f3 for $p"; bad=$((bad+1));;
  esac
done < "$out/inputs.nul"
printf 'path-records=%s files=%s links=%s missing=%s mismatches=%s\n' "$checked" "$files" "$links" "$missing" "$bad"

# 4. Every tree entry outside the manifest path records must be bookkeeping.
cut -f2- "$out/tree.txt" | LC_ALL=C sort > "$out/tree-paths.txt"
LC_ALL=C sort "$out/record-paths.txt" > "$out/record-paths.sorted"
LC_ALL=C comm -23 "$out/tree-paths.txt" "$out/record-paths.sorted" > "$out/extras.txt"
extras="$(wc -l < "$out/extras.txt" | tr -d ' ')"
nonbk=0
while IFS= read -r p; do
  vf_bookkeeping_path "$p" "$s" || { echo "mapping FAIL: non-bookkeeping extra $p"; nonbk=$((nonbk+1)); }
done < "$out/extras.txt"
printf 'extras=%s non-bookkeeping-extras=%s\n' "$extras" "$nonbk"
awk -F/ '{ if ($1==".specify" && $2=="specs") print $3; else print "(repo)" }' "$out/extras.txt" | sort | uniq -c | sed 's/^/  extras by spec: /'
(( bad == 0 && nonbk == 0 )) || { echo 'mapping FAIL'; exit 1; }
[[ "$((files + links + extras))" == "$tree_entries" ]] || { echo 'mapping FAIL: counts do not reconcile'; exit 1; }
vf_hash "$out/inputs.nul" > "$out/inputs.sha256"
printf 'inputs.nul sha256=%s\n' "$(cat "$out/inputs.sha256")"
printf 'mapping PASS\n'
