#!/usr/bin/env bash
# Session 10: the delta receipts. S9 (the session-9 files) is rebuilt from the live files by reversing this
# session's pairs (helpers-1, tv-5, vc-6, kernel-8, tasks-fix-6); PRE (the pre-repair files) is S9 with session
# 9's t030o43-final.diff reversed, which must apply cleanly and so proves S9. Writes t030o43-session10.diff
# (S9 -> live) and a new t030o43-final.diff (PRE -> live); session 9's is kept first as t030o43-final-9.diff.
# Read-only against the live source. Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"; s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
E="$WT/$r/t030o43-edits"; X="$SP/t030o43-final-10"; rm -rf "$X"; mkdir -p "$X"
FILES=(scripts/verification-lib.sh scripts/spec-run.sh scripts/spec-task.sh scripts/spec-evidence.sh scripts/spec-ac-coverage.sh
       scripts/sdd-analyze.sh templates/verification-contract.md tests/helpers.sh tests/test-gate-contracts.sh
       tests/test-verification.sh tests/test-spec-gate.sh tests/test-sdd-analyze.sh "$s/tasks.md")
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
for f in "${FILES[@]}"; do mkdir -p "$X/S9/$(dirname "$f")"; cp "$WT/$f" "$X/S9/$f"; done
reverse() { perl -e 'local $/; my $t = <STDIN>; $t =~ s/\@\@OLD\n(.*?)\n\@\@NEW\n(.*?)\n\@\@END\n/\@\@OLD\n$2\n\@\@NEW\n$1\n\@\@END\n/sg; print $t' < "$1"; }
for p in "tests/helpers.sh helpers-1" "tests/test-verification.sh tv-5" "templates/verification-contract.md vc-6" \
         "scripts/verification-lib.sh kernel-8" "$s/tasks.md tasks-fix-6"; do
  reverse "$E/${p#* }.pairs" > "$X/${p#* }.reverse"
  perl "$E/lit.pl" "$X/S9/${p% *}" "$X/${p#* }.reverse" > /dev/null; check "S9: ${p#* } reversed once" 0 "$?"
done
cp -R "$X/S9" "$X/PRE"
( cd "$X/PRE" && patch -R -p1 -s < "$WT/$r/t030o43-final.diff" ); check "PRE: session 9's final.diff reverses cleanly onto S9" 0 "$?"
check 'PRE: no reject or backup files' 0 "$(find "$X/PRE" -name '*.rej' -o -name '*.orig' | wc -l | tr -d ' ')"
[[ -e "$WT/$r/t030o43-final-9.diff" ]] || cp "$WT/$r/t030o43-final.diff" "$WT/$r/t030o43-final-9.diff"
check 'session 9 final.diff kept as -9' 0 "$(cmp -s "$WT/$r/t030o43-final.diff" "$WT/$r/t030o43-final-9.diff"; echo $?)"
: > "$X/final.diff"; : > "$X/session10.diff"
for f in "${FILES[@]}"; do
  diff -u --label "a/$f" --label "b/$f" "$X/PRE/$f" "$WT/$f" >> "$X/final.diff"
  diff -u --label "a/$f" --label "b/$f" "$X/S9/$f" "$WT/$f" >> "$X/session10.diff"
done
check 'final.diff names 13 files' 13 "$(grep -c '^+++ b/' "$X/final.diff")"
check 'session10.diff names 5 files' 5 "$(grep -c '^+++ b/' "$X/session10.diff")"
cp "$X/final.diff" "$WT/$r/t030o43-final.diff"; cp "$X/session10.diff" "$WT/$r/t030o43-session10.diff"
grep '^+++ b/' "$X/session10.diff"
rm -rf "$X"
echo "t030o43-final-10 failures=$fails"
(( fails == 0 ))
