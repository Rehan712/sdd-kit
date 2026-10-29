#!/usr/bin/env bash
# Session 10: insert the Decisions batch t030o43-decisions-10.md (with r11-insert.sh) and the task-block correction
# t030o43-edits/tasks-fix-6.pairs, validated on a scratch copy of the live enumeration FIRST, then written live and
# validated again; the live STATUS.md and tasks.md must then be byte-identical to the validated scratch copy's.
# Checks each time: round 13 authorized (exit 0), round 14 refused (exit 4), analyzer 0 errors.
# Usage from the worktree root: bash <this> <scratch-dir> <scratch|live>
set -uo pipefail
SP="${1:?scratch}"; MODE="${2:?mode}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
B="$WT/$r/t030o43-decisions-10.md"; P="$WT/$r/t030o43-edits/tasks-fix-6.pairs"; X="$SP/t030o43-dec10-scratch"
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
validate() { # <root> <label>
  ( cd "$1" && bash scripts/spec-gate.sh waiver "$s" opponent 13 ) > "$WT/$r/t030o43-waiver10-$2-13.log" 2>&1; echo $? > "$WT/$r/t030o43-waiver10-$2-13.rc"
  ( cd "$1" && bash scripts/spec-gate.sh waiver "$s" opponent 14 ) > "$WT/$r/t030o43-waiver10-$2-14.log" 2>&1; echo $? > "$WT/$r/t030o43-waiver10-$2-14.rc"
  ( cd "$1" && bash scripts/sdd-analyze.sh "$s" ) > "$WT/$r/t030o43-analyze10-$2.log" 2>&1; echo $? > "$WT/$r/t030o43-analyze10-$2.rc"
  check "$2 round 13 authorized" "0|authorized: opponent round 13" "$(cat "$WT/$r/t030o43-waiver10-$2-13.rc")|$(cat "$WT/$r/t030o43-waiver10-$2-13.log")"
  check "$2 round 14 refused at exit 4" 4 "$(cat "$WT/$r/t030o43-waiver10-$2-14.rc")"
  check "$2 analyzer exit 0 with 0 errors" "0|1 warning(s), 0 errors" "$(cat "$WT/$r/t030o43-analyze10-$2.rc")|$(tail -1 "$WT/$r/t030o43-analyze10-$2.log" | sed 's/^ *//')"
}
case "$MODE" in
  scratch)
    rm -rf "$X"; mkdir -p "$X"
    ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$X" && tar -xf - ) || exit 2
    ( cd "$X" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid commit -qm base ) > /dev/null || exit 2
    validate "$X" scratch-pre
    check 'scratch before: round 13 exit 0 (no candidate added yet)' 0 "$(cat "$WT/$r/t030o43-waiver10-scratch-pre-13.rc")"
    bash "$WT/$r/r11-insert.sh" "$X/$s/STATUS.md" "$B" || { echo 'FAIL insert'; exit 3; }
    perl "$WT/$r/t030o43-edits/lit.pl" "$X/$s/tasks.md" "$P" || { echo 'FAIL tasks-fix-6'; exit 3; }
    validate "$X" scratch
    check 'scratch: the batch holds no authorization line' 0 "$(grep -c -E '^- [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z — (waiver|spec-revision):' "$B")";;
  live)
    [[ -f "$X/$s/STATUS.md" && -f "$X/$s/tasks.md" ]] || { echo 'FAIL no validated scratch copy'; exit 3; }
    cp "$WT/$s/STATUS.md" "$WT/$r/t030o43-STATUS-before-10.md"; cp "$WT/$s/tasks.md" "$WT/$r/t030o43-tasks-before-10.md"
    bash "$WT/$r/r11-insert.sh" "$WT/$s/STATUS.md" "$B" || { echo 'FAIL insert'; exit 3; }
    perl "$WT/$r/t030o43-edits/lit.pl" "$WT/$s/tasks.md" "$P" || { echo 'FAIL tasks-fix-6'; exit 3; }
    check 'live STATUS.md equals the validated scratch copy' 0 "$(cmp -s "$WT/$s/STATUS.md" "$X/$s/STATUS.md"; echo $?)"
    check 'live tasks.md equals the validated scratch copy' 0 "$(cmp -s "$WT/$s/tasks.md" "$X/$s/tasks.md"; echo $?)"
    validate "$WT" live
    rm -rf "$X";;
  *) echo "unknown mode"; exit 2;;
esac
echo "t030o43-decisions-10-apply $MODE failures=$fails"
(( fails == 0 ))
