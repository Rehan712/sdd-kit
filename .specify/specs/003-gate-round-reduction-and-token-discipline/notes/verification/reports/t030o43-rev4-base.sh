#!/usr/bin/env bash
# T030o43 session 9: REVIEWED_DIR for focused review 4. B4 is the live files with
# every session-9 pairs file reversed, newest first: the files as review 3 saw
# them, tsg-7 included. It is proven as t030o43-base-9.sh proves its B: from B4,
# reversing the session-8 pairs gives B (the review-2 state), and reversing
# the two recorded diffs from B gives P, equal to the source-70c71885 records;
# the session-9 delta (B4 -> live) is written to <out-dir>/session9.diff.
# Below, the base-9 header: rebuild the files as review 2 saw them (the review-1
# repair state), two independent ways that must agree byte for byte, and
# write the session-8 delta. Read-only against the live worktree.
#   B: the live files with every session-8 pairs file reversed, newest first;
#   P: B with t030o43-review-repair.diff and then t030o43-session.diff
#      reversed, proven equal to the source-70c71885 records (so B is the
#      pre-delta files plus both recorded diffs, the state review 2 saw);
#   A: P with both diffs applied forward again, which must equal B.
# Session 9 change: tsg-7.pairs (applied after the session-8 delta was taken) is
# reversed first, and the delta is written to <out-dir>/session8-now.diff, never
# over the recorded t030o43-session8.diff.
# Usage: bash t030o43-rev4-base.sh <worktree> <out-dir>
set -uo pipefail
WT="$1"; OUT="$2"; s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$WT/$s/notes/verification/reports"; E="$r/t030o43-edits"
fails=0; say() { printf '%s\n' "$*"; }
rm -rf "$OUT"; mkdir -p "$OUT"
files=(scripts/verification-lib.sh scripts/spec-run.sh scripts/spec-task.sh scripts/spec-evidence.sh
  scripts/spec-ac-coverage.sh scripts/sdd-analyze.sh templates/verification-contract.md tests/helpers.sh
  tests/test-gate-contracts.sh tests/test-verification.sh tests/test-spec-gate.sh tests/test-sdd-analyze.sh "$s/tasks.md")
rev() { # <file> <pairs...> newest first: NEW -> OLD
  local f="$1" p; shift
  for p in "$@"; do
    perl -0pe 's/\@\@OLD\n(.*?)\n\@\@NEW\n(.*?)\n\@\@END\n/\@\@OLD\n$2\n\@\@NEW\n$1\n\@\@END\n/sg' "$E/$p" > "$OUT/.rev"
    perl "$E/lit.pl" "$OUT/B/$f" "$OUT/.rev" > /dev/null || { say "FAIL reverse $p on $f"; fails=$((fails+1)); }
  done
}
for f in "${files[@]}"; do mkdir -p "$OUT/B/$(dirname "$f")"; cp -p "$WT/$f" "$OUT/B/$f"; done
rev scripts/verification-lib.sh kernel-6.pairs
rev scripts/spec-task.sh spec-task-3.pairs
rev scripts/sdd-analyze.sh sdd-analyze-3.pairs
rev tests/test-gate-contracts.sh tgc-6.pairs
rev tests/test-sdd-analyze.sh tsa-7.pairs
rev tests/test-spec-gate.sh tsg-8.pairs
rev templates/verification-contract.md vc-4.pairs
rev "$s/tasks.md" tasks-fix-4.pairs
rm -f "$OUT/.rev"
cp -Rp "$OUT/B" "$OUT/B4"
( cd "$OUT/B4" && for f in "${files[@]}"; do diff -u --label "a/$f" --label "b/$f" "$f" "$WT/$f"; done ) > "$OUT/session9.diff"
say "session-9 delta: $(grep -c "^+++ " "$OUT/session9.diff") files, $(wc -l < "$OUT/session9.diff" | tr -d ' ') lines"
rev scripts/verification-lib.sh kernel-5.pairs
rev scripts/sdd-analyze.sh sdd-analyze-2.pairs
rev scripts/spec-evidence.sh spec-evidence-3.pairs
rev scripts/spec-run.sh spec-run-2.pairs
rev scripts/spec-task.sh spec-task-2.pairs
rev templates/verification-contract.md vc-3.pairs
rev tests/test-gate-contracts.sh tgc-5.pairs tgc-4.pairs
rev tests/test-verification.sh tv-4.pairs tv-3.pairs
rev tests/test-sdd-analyze.sh tsa-6.pairs tsa-5.pairs tsa-4.pairs tsa-3.pairs
rev tests/test-spec-gate.sh tsg-7.pairs tsg-6.pairs tsg-5.pairs tsg-4.pairs tsg-3.pairs
rev "$s/tasks.md" tasks-fix-3.pairs
rm -f "$OUT/.rev"
cp -Rp "$OUT/B" "$OUT/P"
for d in t030o43-review-repair.diff t030o43-session.diff; do
  ( cd "$OUT/P" && patch -R -p1 -s --no-backup-if-mismatch < "$r/$d" ) || { say "FAIL reverse $d"; fails=$((fails+1)); }
done
for f in "${files[@]}"; do
  want="$(tr '\0' '\n' < "$E/source-70c71885-inputs.nul" | paste - - - - - - | awk -F '\t' -v p="$f" '$1=="path" && $2==p {print $5}')"
  got="$(bash -c '. "$1/scripts/verification-lib.sh"; vf_semantic_file "$2" "$3" "$4" && vf_hash "$4"' _ "$WT" "$f" "$OUT/P/$f" "$OUT/.sem")"
  if [[ -n "$want" && "$want" == "$got" ]]; then say "PASS P $f equals its 70c71885 record"; else say "FAIL P $f: want=$want got=$got"; fails=$((fails+1)); fi
done
rm -f "$OUT/.sem"
cp -Rp "$OUT/P" "$OUT/A"
for d in t030o43-session.diff t030o43-review-repair.diff; do
  ( cd "$OUT/A" && patch -p1 -s --no-backup-if-mismatch < "$r/$d" ) || { say "FAIL forward $d"; fails=$((fails+1)); }
done
leftovers="$(find "$OUT" \( -name '*.orig' -o -name '*.rej' \) -print)"; [[ -z "$leftovers" ]] || { say "FAIL leftovers: $leftovers"; fails=$((fails+1)); }
for f in "${files[@]}"; do
  if cmp -s "$OUT/A/$f" "$OUT/B/$f"; then say "PASS $f: A == B"; else say "FAIL $f: A != B"; fails=$((fails+1)); fi
done
( cd "$OUT/B" && for f in "${files[@]}"; do diff -u --label "a/$f" --label "b/$f" "$f" "$WT/$f"; done ) > "$OUT/session8-now.diff"
say "session-8 delta: $(grep -c "^+++ " "$OUT/session8-now.diff") files, $(wc -l < "$OUT/session8-now.diff" | tr -d ' ') lines"
say "t030o43-rev4-base failures=$fails"
(( fails == 0 ))
