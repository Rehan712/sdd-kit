#!/usr/bin/env bash
# T030o43, session 8: rebuild the pre-delta versions of every file the repair
# edits from the live tree, by reversing the review-1 repair
# (t030o43-review-repair.diff) and then the reviewed delta
# (t030o43-session.diff) with patch -R, and prove each byte-exact against the
# `path` record of the inputs manifest taken before any code changed (source
# 70c71885..., t030o43-edits/source-70c71885-inputs.nul). Read-only against
# the live worktree. t030o43-pre-rebuild.sh predates the review-1 repair and
# reverses the first delta only.
# Usage: bash t030o43-pre-rebuild-2.sh <worktree> <output dir>
set -uo pipefail
WT="$1"; OUT="$2"; s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$WT/$s/notes/verification/reports"; E="$r/t030o43-edits"
fails=0
say() { printf '%s\n' "$*"; }
rm -rf "$OUT"; mkdir -p "$OUT"
files=(scripts/verification-lib.sh scripts/spec-run.sh scripts/spec-task.sh scripts/spec-evidence.sh
  scripts/spec-ac-coverage.sh scripts/sdd-analyze.sh templates/verification-contract.md tests/helpers.sh
  tests/test-gate-contracts.sh tests/test-verification.sh tests/test-spec-gate.sh tests/test-sdd-analyze.sh "$s/tasks.md")
for f in "${files[@]}"; do mkdir -p "$OUT/$(dirname "$f")"; cp -p "$WT/$f" "$OUT/$f"; done
for d in t030o43-review-repair.diff t030o43-session.diff; do
  ( cd "$OUT" && patch -R -p1 -s --no-backup-if-mismatch < "$r/$d" ) || { say "FAIL reverse $d"; fails=$((fails+1)); }
done
find "$OUT" -name '*.orig' -o -name '*.rej' | while read -r x; do say "FAIL leftover $x"; done
for f in "${files[@]}"; do
  want="$(tr '\0' '\n' < "$E/source-70c71885-inputs.nul" | paste - - - - - - | awk -F '\t' -v p="$f" '$1=="path" && $2==p {print $5}')"
  got="$(bash -c '. "$1/scripts/verification-lib.sh"; vf_semantic_file "$2" "$3" "$4" && vf_hash "$4"' _ "$WT" "$f" "$OUT/$f" "$OUT/.sem")"
  if [[ -n "$want" && "$want" == "$got" ]]; then say "PASS rebuilt $f equals its 70c71885 record"; else say "FAIL rebuilt $f: want=$want got=$got"; fails=$((fails+1)); fi
done
rm -f "$OUT/.sem"
say "t030o43-pre-rebuild-2 failures=$fails"
(( fails == 0 ))
