#!/usr/bin/env bash
# Session 14: insert the Decisions batch r14-decisions-1.md (with r11-insert.sh) and the T030o45 and T030o46 task
# blocks r14-task-blocks.md (with r14-task-insert.sh), validated on a scratch copy of the live enumeration FIRST,
# then written live and validated again; the live STATUS.md and tasks.md must then be byte-identical to the
# validated scratch copy's. Pattern: t030o44-decisions-1-apply.sh.
# Checks: before the batch, round 15 refused (exit 4); after it, round 14 still reported completed, round 15
# authorized (exit 0), round 16 refused (exit 4), the analyzer at exit 0 with 0 errors, both task blocks present
# and unticked, the batch the last Decisions entries; the batch holds exactly one authorization line, for round
# 15, and no placeholder.
# Usage from the worktree root: bash <this> <scratch-dir> <scratch|live>
set -uo pipefail
SP="${1:?scratch}"; MODE="${2:?mode}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
B="$WT/$r/r14-decisions-1.md"; T="$WT/$r/r14-task-blocks.md"; X="$SP/r14-dec1-scratch"
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
w() { # <root> <label> <round>
  ( cd "$1" && bash scripts/spec-gate.sh waiver "$s" opponent "$3" ) > "$WT/$r/r14-waiver1-$2-$3.log" 2>&1
  echo $? > "$WT/$r/r14-waiver1-$2-$3.rc"
}
validate() { # <root> <label>
  w "$1" "$2" 14; w "$1" "$2" 15; w "$1" "$2" 16
  ( cd "$1" && bash scripts/sdd-analyze.sh "$s" ) > "$WT/$r/r14-analyze1-$2.log" 2>&1; echo $? > "$WT/$r/r14-analyze1-$2.rc"
  check "$2 round 14 still reported completed" "0|opponent round 14 is already completed; the next round is 15" \
    "$(cat "$WT/$r/r14-waiver1-$2-14.rc")|$(cat "$WT/$r/r14-waiver1-$2-14.log")"
  check "$2 round 15 authorized" "0|authorized: opponent round 15" "$(cat "$WT/$r/r14-waiver1-$2-15.rc")|$(cat "$WT/$r/r14-waiver1-$2-15.log")"
  check "$2 round 16 refused at exit 4" 4 "$(cat "$WT/$r/r14-waiver1-$2-16.rc")"
  check "$2 analyzer exit 0 with 0 errors" "0|1 warning(s), 0 errors" "$(cat "$WT/$r/r14-analyze1-$2.rc")|$(tail -1 "$WT/$r/r14-analyze1-$2.log" | sed 's/^ *//')"
  check "$2 both task blocks present and unticked" 2 "$(grep -c -E '^- \[ \] \*\*T030o4[56]\*\* — ' "$1/$s/tasks.md")"
  check "$2 the batch is the last Decisions entries" "$(awk 'NF{l=$0} END{print l}' "$B")" \
    "$(awk '/^## Open questions \/ blockers$/{print last; exit} NF{last=$0}' "$1/$s/STATUS.md")"
}
check 'the batch holds no placeholder' 0 "$(grep -c '@@' "$B")"
check 'the batch holds exactly one authorization line, for round 15' 1 \
  "$(grep -c -E '^- [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z — waiver: gate=opponent; round=15; after=14; by=Rehan712; reason=[^;]+$' "$B")"
check 'the batch holds no other authorization line' 1 "$(grep -c -E '^- [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z — (waiver|spec-revision):' "$B")"
case "$MODE" in
  scratch)
    rm -rf "$X"; mkdir -p "$X"
    ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$X" && tar -xf - ) || exit 2
    ( cd "$X" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid -c core.hooksPath=/dev/null commit -qm base ) > /dev/null || exit 2
    w "$X" scratch-pre 15
    check 'scratch before the batch: round 15 refused at exit 4' 4 "$(cat "$WT/$r/r14-waiver1-scratch-pre-15.rc")"
    bash "$WT/$r/r11-insert.sh" "$X/$s/STATUS.md" "$B" || { echo 'FAIL insert'; exit 3; }
    bash "$WT/$r/r14-task-insert.sh" "$X/$s/tasks.md" "$T" || { echo 'FAIL task insert'; exit 3; }
    validate "$X" scratch;;
  live)
    [[ -f "$X/$s/STATUS.md" && -f "$X/$s/tasks.md" ]] || { echo 'FAIL no validated scratch copy'; exit 3; }
    w "$WT" live-pre 15
    check 'live before the batch: round 15 refused at exit 4' 4 "$(cat "$WT/$r/r14-waiver1-live-pre-15.rc")"
    cp "$WT/$s/STATUS.md" "$WT/$r/r14-STATUS-before-1.md"; cp "$WT/$s/tasks.md" "$WT/$r/r14-tasks-before-1.md"
    bash "$WT/$r/r11-insert.sh" "$WT/$s/STATUS.md" "$B" || { echo 'FAIL insert'; exit 3; }
    bash "$WT/$r/r14-task-insert.sh" "$WT/$s/tasks.md" "$T" || { echo 'FAIL task insert'; exit 3; }
    check 'live STATUS.md equals the validated scratch copy' 0 "$(cmp -s "$WT/$s/STATUS.md" "$X/$s/STATUS.md"; echo $?)"
    check 'live tasks.md equals the validated scratch copy' 0 "$(cmp -s "$WT/$s/tasks.md" "$X/$s/tasks.md"; echo $?)"
    validate "$WT" live
    rm -rf "$X";;
  *) echo "unknown mode"; exit 2;;
esac
echo "r14-decisions-1-apply $MODE failures=$fails"
(( fails == 0 ))
