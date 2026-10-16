#!/usr/bin/env bash
# Session 22 (2026-10-15): the round-18 repair batch, applied in the order the handoff names: r19-edits/decisions-1.py
# (Decisions: round 18's outcome, the user's decisions of 2026-10-14, the reproduction, the REQ-011 revision, the task
# blocks with the dev run, the round-19 waiver and the freeze), then r19-edits/apply-docs.py (spec.md, tasks.md), then
# r19-edits/apply-code.py (the kernel, the contract and the two suites). Validated on a scratch copy of the live
# enumeration FIRST, then written live with the same waiver timestamp and validated again; every live file the batch
# writes must then be byte-identical to the validated scratch copy's. Pattern: r18-decisions-1-apply.sh.
# Checks: before the batch, round 19 refused (exit 4); after it, round 18 still reported completed, round 19
# authorized (exit 0), round 20 refused (exit 4), the analyzer at exit 0 with 0 errors, the three task blocks present
# and unticked, the freezing entry the last Decisions entry, exactly one authorization line for round 19.
# Usage from the worktree root: bash <this> <scratch-dir> <scratch|live> <UTC waiver timestamp>
set -uo pipefail
SP="${1:?scratch}"; MODE="${2:?mode}"; TS="${3:?timestamp}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
E="$WT/$r/r19-edits"; X="$SP/r19-batch-scratch"
FILES=("$s/STATUS.md" "$s/spec.md" "$s/tasks.md" scripts/verification-lib.sh templates/verification-contract.md
  tests/test-gate-contracts.sh tests/test-spec-gate.sh)
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
w() { # <root> <label> <round>
  ( cd "$1" && bash scripts/spec-gate.sh waiver "$s" opponent "$3" ) > "$WT/$r/r19-waiver-$2-$3.log" 2>&1
  echo $? > "$WT/$r/r19-waiver-$2-$3.rc"
}
apply() { # <root> <label>
  python3 -I "$E/decisions-1.py" "$1" "$TS" > "$WT/$r/r19-batch-$2-decisions.log" 2>&1 || { echo "FAIL decisions-1 ($2)"; cat "$WT/$r/r19-batch-$2-decisions.log"; exit 3; }
  python3 -I "$E/apply-docs.py" "$1" > "$WT/$r/r19-batch-$2-docs.log" 2>&1 || { echo "FAIL apply-docs ($2)"; cat "$WT/$r/r19-batch-$2-docs.log"; exit 3; }
  python3 -I "$E/apply-code.py" "$1" > "$WT/$r/r19-batch-$2-code.log" 2>&1 || { echo "FAIL apply-code ($2)"; cat "$WT/$r/r19-batch-$2-code.log"; exit 3; }
  sed 's/^/  | /' "$WT/$r/r19-batch-$2-decisions.log" "$WT/$r/r19-batch-$2-docs.log" "$WT/$r/r19-batch-$2-code.log"
}
validate() { # <root> <label>
  w "$1" "$2" 18; w "$1" "$2" 19; w "$1" "$2" 20
  ( cd "$1" && bash scripts/sdd-analyze.sh "$s" ) > "$WT/$r/r19-analyze-$2.log" 2>&1; echo $? > "$WT/$r/r19-analyze-$2.rc"
  check "$2 round 18 still reported completed" "0|opponent round 18 is already completed; the next round is 19" \
    "$(cat "$WT/$r/r19-waiver-$2-18.rc")|$(cat "$WT/$r/r19-waiver-$2-18.log")"
  check "$2 round 19 authorized" "0|authorized: opponent round 19" "$(cat "$WT/$r/r19-waiver-$2-19.rc")|$(cat "$WT/$r/r19-waiver-$2-19.log")"
  check "$2 round 20 refused at exit 4" 4 "$(cat "$WT/$r/r19-waiver-$2-20.rc")"
  check "$2 analyzer exit 0 with 0 errors" "0|0 errors" "$(cat "$WT/$r/r19-analyze-$2.rc")|$(tail -1 "$WT/$r/r19-analyze-$2.log" | sed -E 's/^.*, (0 errors)$/\1/')"
  for k in T030o54 T030o55 T030o56; do
    check "$2 the $k block present and unticked" 1 "$(grep -c -E "^- \\[ \\] \\*\\*$k\\*\\* — " "$1/$s/tasks.md")"
  done
  check "$2 exactly one authorization line for round 19" 1 \
    "$(grep -c -E "^- $TS — waiver: gate=opponent; round=19; after=18; by=Rehan712; reason=[^;]+$" "$1/$s/STATUS.md")"
  check "$2 the freezing entry is the last Decisions entry" 1 \
    "$(awk '/^## Open questions \/ blockers$/{print last; exit} NF{last=$0}' "$1/$s/STATUS.md" | grep -c '^- 2026-10-14 — Decisions are FROZEN from this batch')"
  check "$2 the REQ-011 revision present" 1 "$(grep -c -F "model (the user's revision of 2026-10-14): gate reports are" "$1/$s/spec.md")"
  awk '/^[0-9a-f]{64}  /' "$WT/$r/r19-batch-$2-code.log" > "$SP/r19-post-apply-$2.sha256"
  check "$2 the four code files hash as apply-code printed" 4 \
    "$( (cd "$1" && shasum -a 256 -c "$SP/r19-post-apply-$2.sha256" 2>&1) | grep -c ': OK$')"
}
case "$MODE" in
  scratch)
    rm -rf "$X"; mkdir -p "$X"
    ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$X" && tar -xf - ) || exit 2
    ( cd "$X" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid -c core.hooksPath=/dev/null commit -qm base ) > /dev/null || exit 2
    w "$X" scratch-pre 19
    check 'scratch before the batch: round 19 refused at exit 4' 4 "$(cat "$WT/$r/r19-waiver-scratch-pre-19.rc")"
    apply "$X" scratch
    ( cd "$X" && git diff ) > "$WT/$r/r19-session.diff"
    validate "$X" scratch;;
  live)
    for f in "${FILES[@]}"; do [[ -f "$X/$f" ]] || { echo "FAIL no validated scratch copy of $f"; exit 3; }; done
    grep -q -E "^- $TS — waiver: gate=opponent; round=19;" "$X/$s/STATUS.md" || { echo 'FAIL the scratch copy carries another timestamp'; exit 3; }
    w "$WT" live-pre 19
    check 'live before the batch: round 19 refused at exit 4' 4 "$(cat "$WT/$r/r19-waiver-live-pre-19.rc")"
    (( fails == 0 )) || { echo 'FAIL refusing the live apply'; exit 3; }
    # The four code files need no copy: apply-code refuses unless they hash as r18-edits/post-apply-3.
    cp "$WT/$s/STATUS.md" "$WT/$r/r24-STATUS-before-batch.md"
    cp "$WT/$s/spec.md" "$WT/$r/r24-spec-before-batch.md"; cp "$WT/$s/tasks.md" "$WT/$r/r24-tasks-before-batch.md"
    apply "$WT" live
    for f in "${FILES[@]}"; do check "live $f equals the validated scratch copy" 0 "$(cmp -s "$WT/$f" "$X/$f"; echo $?)"; done
    validate "$WT" live
    cp "$SP/r19-post-apply-live.sha256" "$E/post-apply.sha256"
    rm -rf "$X";;
  *) echo "unknown mode"; exit 2;;
esac
echo "r19-batch-apply $MODE failures=$fails"
(( fails == 0 ))
