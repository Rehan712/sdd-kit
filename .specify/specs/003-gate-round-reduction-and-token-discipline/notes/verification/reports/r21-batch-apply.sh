#!/usr/bin/env bash
# Session 24 (2026-10-16): the T031a1o1, T031a3o1 and T031a4o1 batch, applied in the order the handoff names:
# r21-edits/decisions-1.py (Decisions: round 20's outcome and the reproduction, the user's decisions of 2026-10-15 and
# 2026-10-16 with the commit and the draft PR, the task blocks with the dev run, the round-21 waiver and the freeze),
# then r21-edits/apply-docs.py (tasks.md), then r21-edits/apply-code.py (the two suites). Validated on a scratch copy
# of the live enumeration FIRST, then written live with the same waiver timestamp and validated again; every live
# file the batch writes must then be byte-identical to the validated scratch copy's. Pattern: r20-batch-apply.sh.
# Checks: before the batch, round 21 refused (exit 4); after it, round 20 still reported completed, round 21
# authorized (exit 0), round 22 refused (exit 4), the analyzer at exit 0 with 0 errors, the three task blocks present
# and unticked, the freezing entry the last Decisions entry, exactly one authorization line for round 21.
# Usage from the worktree root: bash <this> <scratch-dir> <scratch|live> <UTC waiver timestamp>
set -uo pipefail
SP="${1:?scratch}"; MODE="${2:?mode}"; TS="${3:?timestamp}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
E="$WT/$r/r21-edits"; X="$SP/r21-batch-scratch"
FILES=("$s/STATUS.md" "$s/tasks.md" tests/test-gate-contracts.sh tests/test-spec-gate.sh)
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
w() { # <root> <label> <round>
  ( cd "$1" && bash scripts/spec-gate.sh waiver "$s" opponent "$3" ) > "$WT/$r/r21-waiver-$2-$3.log" 2>&1
  echo $? > "$WT/$r/r21-waiver-$2-$3.rc"
}
apply() { # <root> <label>
  python3 -I "$E/decisions-1.py" "$1" "$TS" > "$WT/$r/r21-batch-$2-decisions.log" 2>&1 || { echo "FAIL decisions-1 ($2)"; cat "$WT/$r/r21-batch-$2-decisions.log"; exit 3; }
  python3 -I "$E/apply-docs.py" "$1" > "$WT/$r/r21-batch-$2-docs.log" 2>&1 || { echo "FAIL apply-docs ($2)"; cat "$WT/$r/r21-batch-$2-docs.log"; exit 3; }
  python3 -I "$E/apply-code.py" "$1" > "$WT/$r/r21-batch-$2-code.log" 2>&1 || { echo "FAIL apply-code ($2)"; cat "$WT/$r/r21-batch-$2-code.log"; exit 3; }
  sed 's/^/  | /' "$WT/$r/r21-batch-$2-decisions.log" "$WT/$r/r21-batch-$2-docs.log" "$WT/$r/r21-batch-$2-code.log"
}
validate() { # <root> <label>
  w "$1" "$2" 20; w "$1" "$2" 21; w "$1" "$2" 22
  ( cd "$1" && bash scripts/sdd-analyze.sh "$s" ) > "$WT/$r/r21-analyze-$2.log" 2>&1; echo $? > "$WT/$r/r21-analyze-$2.rc"
  check "$2 round 20 still reported completed" "0|opponent round 20 is already completed; the next round is 21" \
    "$(cat "$WT/$r/r21-waiver-$2-20.rc")|$(cat "$WT/$r/r21-waiver-$2-20.log")"
  check "$2 round 21 authorized" "0|authorized: opponent round 21" "$(cat "$WT/$r/r21-waiver-$2-21.rc")|$(cat "$WT/$r/r21-waiver-$2-21.log")"
  check "$2 round 22 refused at exit 4" 4 "$(cat "$WT/$r/r21-waiver-$2-22.rc")"
  check "$2 analyzer exit 0 with 0 errors" "0|0 errors" "$(cat "$WT/$r/r21-analyze-$2.rc")|$(tail -1 "$WT/$r/r21-analyze-$2.log" | sed -E 's/^.*, (0 errors)$/\1/')"
  for k in T031a1o1 T031a3o1 T031a4o1; do
    check "$2 the $k block present and unticked" 1 "$(grep -c -E "^- \\[ \\] \\*\\*$k\\*\\* — " "$1/$s/tasks.md")"
  done
  check "$2 exactly one authorization line for round 21" 1 \
    "$(grep -c -E "^- $TS — waiver: gate=opponent; round=21; after=20; by=Rehan712; reason=[^;]+$" "$1/$s/STATUS.md")"
  check "$2 the freezing entry is the last Decisions entry" 1 \
    "$(awk '/^## Open questions \/ blockers$/{print last; exit} NF{last=$0}' "$1/$s/STATUS.md" | grep -c '^- 2026-10-16 — Decisions are FROZEN from this batch')"
  awk '/^[0-9a-f]{64}  /' "$WT/$r/r21-batch-$2-code.log" > "$SP/r21-post-apply-$2.sha256"
  check "$2 the two suites hash as apply-code printed" 2 \
    "$( (cd "$1" && shasum -a 256 -c "$SP/r21-post-apply-$2.sha256" 2>&1) | grep -c ': OK$')"
}
case "$MODE" in
  scratch)
    rm -rf "$X"; mkdir -p "$X"
    ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$X" && tar -xf - ) || exit 2
    ( cd "$X" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid -c core.hooksPath=/dev/null commit -qm base ) > /dev/null || exit 2
    w "$X" scratch-pre 21
    check 'scratch before the batch: round 21 refused at exit 4' 4 "$(cat "$WT/$r/r21-waiver-scratch-pre-21.rc")"
    apply "$X" scratch
    ( cd "$X" && git diff ) > "$WT/$r/r21-session.diff"
    validate "$X" scratch;;
  live)
    for f in "${FILES[@]}"; do [[ -f "$X/$f" ]] || { echo "FAIL no validated scratch copy of $f"; exit 3; }; done
    grep -q -E "^- $TS — waiver: gate=opponent; round=21;" "$X/$s/STATUS.md" || { echo 'FAIL the scratch copy carries another timestamp'; exit 3; }
    w "$WT" live-pre 21
    check 'live before the batch: round 21 refused at exit 4' 4 "$(cat "$WT/$r/r21-waiver-live-pre-21.rc")"
    (( fails == 0 )) || { echo 'FAIL refusing the live apply'; exit 3; }
    # The two suites need no copy: apply-code refuses unless they hash as at the frozen source.
    cp "$WT/$s/STATUS.md" "$WT/$r/r26-STATUS-before-batch.md"; cp "$WT/$s/tasks.md" "$WT/$r/r26-tasks-before-batch.md"
    apply "$WT" live
    for f in "${FILES[@]}"; do check "live $f equals the validated scratch copy" 0 "$(cmp -s "$WT/$f" "$X/$f"; echo $?)"; done
    validate "$WT" live
    cp "$SP/r21-post-apply-live.sha256" "$E/post-apply.sha256"
    rm -rf "$X";;
  *) echo "unknown mode"; exit 2;;
esac
echo "r21-batch-apply $MODE failures=$fails"
(( fails == 0 ))
