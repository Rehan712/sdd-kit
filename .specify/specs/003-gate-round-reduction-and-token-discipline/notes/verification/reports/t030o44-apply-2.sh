#!/usr/bin/env bash
# Session 12: second T030o44 edit, before the review and the matrix. kernel-2.pairs replaces the manifest pass's
# `subheading` flag with the catch-all's own exclusion of ATX headings (no state to reset), and drops the two
# `flevel=0` assignments, which nothing reads (flevel is read only while a finding is open, and is set whenever one
# opens). tgc-2.pairs adds the fixture row that judges the catch-all after a sub-heading. The files must hash as
# t030o44-edits/post-apply.sha256 recorded after apply 1; the delta is t030o44-session2.diff.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"; s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
E="$WT/$r/t030o44-edits"; X="$SP/t030o44-apply-2"; rm -rf "$X"; mkdir -p "$X"
FILES=(scripts/verification-lib.sh tests/test-gate-contracts.sh)
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
( cd "$WT" && grep -E 'scripts/verification-lib.sh|tests/test-gate-contracts.sh' "$E/post-apply.sha256" | shasum -a 256 -c ) > "$X/pre.log" 2>&1
check 'the two files hash as recorded after apply 1' 0 "$?"
(( fails == 0 )) || { cat "$X/pre.log"; echo 'refusing: the live files moved since apply 1'; exit 3; }
for f in "${FILES[@]}"; do mkdir -p "$X/before/$(dirname "$f")"; cp "$WT/$f" "$X/before/$f"; done
for p in "scripts/verification-lib.sh kernel-2 3" "tests/test-gate-contracts.sh tgc-2 1"; do
  set -- $p
  out="$(perl "$E/lit.pl" "$WT/$1" "$E/$2.pairs")"; rc=$?; echo "$out"
  check "$2 applied, $3 block(s) once each" "0|applied $3 block(s) to $WT/$1" "$rc|$out"
done
check 'the kernel parses' 0 "$(bash -n "$WT/scripts/verification-lib.sh"; echo $?)"
check 'no subheading flag remains' 0 "$(grep -c subheading "$WT/scripts/verification-lib.sh")"
: > "$X/session2.diff"
for f in "${FILES[@]}"; do diff -u --label "a/$f" --label "b/$f" "$X/before/$f" "$WT/$f" >> "$X/session2.diff"; done
check 'the delta names the two files' 2 "$(grep -c '^+++ b/' "$X/session2.diff")"
cp "$X/session2.diff" "$WT/$r/t030o44-session2.diff"
( cd "$WT" && shasum -a 256 scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh templates/verification-contract.md ) > "$E/post-apply-2.sha256"; cat "$E/post-apply-2.sha256"
rm -rf "$X"
echo "t030o44-apply-2 failures=$fails"
(( fails == 0 ))
