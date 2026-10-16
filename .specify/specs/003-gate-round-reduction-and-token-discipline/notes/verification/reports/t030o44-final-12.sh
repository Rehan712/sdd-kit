#!/usr/bin/env bash
# Session 12: the whole T030o44 delta. PRE (the pre-repair files) is the live files with t030o44-session2.diff and
# then t030o44-session1.diff reversed; it must hash as t030o44-edits/pre-apply.sha256 recorded before apply 1,
# which proves both diffs. Writes t030o44-final.diff (PRE -> live). Read-only against the live source.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"; s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
X="$SP/t030o44-final"; rm -rf "$X"; mkdir -p "$X/PRE"
FILES=(scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh templates/verification-contract.md)
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
for f in "${FILES[@]}"; do mkdir -p "$X/PRE/$(dirname "$f")"; cp "$WT/$f" "$X/PRE/$f"; done
( cd "$X/PRE" && patch -R -p1 -s < "$WT/$r/t030o44-session2.diff" ); check 'session2.diff reverses cleanly' 0 "$?"
( cd "$X/PRE" && patch -R -p1 -s < "$WT/$r/t030o44-session1.diff" ); check 'session1.diff reverses cleanly' 0 "$?"
check 'no reject or backup files' 0 "$(find "$X/PRE" -name '*.rej' -o -name '*.orig' | wc -l | tr -d ' ')"
( cd "$X/PRE" && shasum -a 256 -c "$WT/$r/t030o44-edits/pre-apply.sha256" ) > "$X/sha.log" 2>&1; check 'PRE hashes as recorded before apply 1' 0 "$?"
: > "$X/final.diff"
for f in "${FILES[@]}"; do diff -u --label "a/$f" --label "b/$f" "$X/PRE/$f" "$WT/$f" >> "$X/final.diff"; done
check 'final.diff names the four files' 4 "$(grep -c '^+++ b/' "$X/final.diff")"
cp "$X/final.diff" "$WT/$r/t030o44-final.diff"
rm -rf "$X"
echo "t030o44-final failures=$fails"
(( fails == 0 ))
