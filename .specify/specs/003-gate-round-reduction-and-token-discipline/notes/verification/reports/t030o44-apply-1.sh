#!/usr/bin/env bash
# Session 12: apply the T030o44 repair to the live files, exactly as measured (kernel-1.pairs) and as the dev runs
# t030o44-dev1-quick and t030o44-dev2-gc applied it in copies: fixtures-1.pl first (it edits by line number and
# keeps the line count), then kernel-1, tgc-1, tsg-1 and vc-1, each block matching exactly once. The four files
# must hash as recorded in t030o44-edits/pre-apply.sha256 before; the delta is written to t030o44-session1.diff.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"; s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
E="$WT/$r/t030o44-edits"; X="$SP/t030o44-apply-1"; rm -rf "$X"; mkdir -p "$X"
FILES=(scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh templates/verification-contract.md)
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
( cd "$WT" && shasum -a 256 -c "$E/pre-apply.sha256" ) > "$X/pre.log" 2>&1; check 'the four files hash as recorded before the apply' 0 "$?"
(( fails == 0 )) || { echo 'refusing: the live files moved since the pairs were generated'; exit 3; }
for f in "${FILES[@]}"; do mkdir -p "$X/before/$(dirname "$f")"; cp "$WT/$f" "$X/before/$f"; done
perl "$E/fixtures-1.pl" "$WT/tests/test-gate-contracts.sh"; check 'fixtures-1.pl applied' 0 "$?"
for p in "scripts/verification-lib.sh kernel-1 8" "tests/test-gate-contracts.sh tgc-1 3" "tests/test-spec-gate.sh tsg-1 1" "templates/verification-contract.md vc-1 1"; do
  set -- $p
  out="$(perl "$E/lit.pl" "$WT/$1" "$E/$2.pairs")"; rc=$?; echo "$out"
  check "$2 applied, $3 block(s) once each" "0|applied $3 block(s) to $WT/$1" "$rc|$out"
done
check 'the kernel parses' 0 "$(bash -n "$WT/scripts/verification-lib.sh"; echo $?)"
: > "$X/session1.diff"
for f in "${FILES[@]}"; do diff -u --label "a/$f" --label "b/$f" "$X/before/$f" "$WT/$f" >> "$X/session1.diff"; done
check 'the delta names the four files' 4 "$(grep -c '^+++ b/' "$X/session1.diff")"
cp "$X/session1.diff" "$WT/$r/t030o44-session1.diff"
( cd "$WT" && shasum -a 256 "${FILES[@]}" ) > "$E/post-apply.sha256"; cat "$E/post-apply.sha256"
rm -rf "$X"
echo "t030o44-apply-1 failures=$fails"
(( fails == 0 ))
