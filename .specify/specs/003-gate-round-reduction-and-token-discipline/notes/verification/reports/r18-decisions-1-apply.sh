#!/usr/bin/env bash
# Session 19: insert the Decisions batch r18-decisions-1.md (with r11-insert.sh) and the T030o51, T030o52 and
# T030o53 task blocks r18-task-blocks.md (with r18-task-insert.sh), validated on a scratch copy of the live
# enumeration FIRST, then written live and validated again; the live STATUS.md and tasks.md must then be
# byte-identical to the validated scratch copy's. Pattern: r17-decisions-1-apply.sh.
# Checks: before the batch, round 18 refused (exit 4); after it, round 17 still reported completed, round 18
# authorized (exit 0), round 19 refused (exit 4), the analyzer at exit 0 with 0 errors, the three task blocks present
# and unticked, the batch the last Decisions entries; the batch holds exactly one authorization line, for round
# 18, and no placeholder.
# Usage from the worktree root: bash <this> <scratch-dir> <scratch|live>
set -uo pipefail
SP="${1:?scratch}"; MODE="${2:?mode}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
B="$WT/$r/r18-decisions-1.md"; T="$WT/$r/r18-task-blocks.md"; X="$SP/r18-dec1-scratch"
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
w() { # <root> <label> <round>
  ( cd "$1" && bash scripts/spec-gate.sh waiver "$s" opponent "$3" ) > "$WT/$r/r18-waiver1-$2-$3.log" 2>&1
  echo $? > "$WT/$r/r18-waiver1-$2-$3.rc"
}
validate() { # <root> <label>
  w "$1" "$2" 17; w "$1" "$2" 18; w "$1" "$2" 19
  ( cd "$1" && bash scripts/sdd-analyze.sh "$s" ) > "$WT/$r/r18-analyze1-$2.log" 2>&1; echo $? > "$WT/$r/r18-analyze1-$2.rc"
  check "$2 round 17 still reported completed" "0|opponent round 17 is already completed; the next round is 18" \
    "$(cat "$WT/$r/r18-waiver1-$2-17.rc")|$(cat "$WT/$r/r18-waiver1-$2-17.log")"
  check "$2 round 18 authorized" "0|authorized: opponent round 18" "$(cat "$WT/$r/r18-waiver1-$2-18.rc")|$(cat "$WT/$r/r18-waiver1-$2-18.log")"
  check "$2 round 19 refused at exit 4" 4 "$(cat "$WT/$r/r18-waiver1-$2-19.rc")"
  check "$2 analyzer exit 0 with 0 errors" "0|1 warning(s), 0 errors" "$(cat "$WT/$r/r18-analyze1-$2.rc")|$(tail -1 "$WT/$r/r18-analyze1-$2.log" | sed 's/^ *//')"
  for k in T030o51 T030o52 T030o53; do
    check "$2 the $k block present and unticked" 1 "$(grep -c -E "^- \\[ \\] \\*\\*$k\\*\\* — " "$1/$s/tasks.md")"
  done
  check "$2 the batch is the last Decisions entries" "$(awk 'NF{l=$0} END{print l}' "$B")" \
    "$(awk '/^## Open questions \/ blockers$/{print last; exit} NF{last=$0}' "$1/$s/STATUS.md")"
}
check 'the batch holds no placeholder' 0 "$(grep -c '@@' "$B")"
check 'the batch holds exactly one authorization line, for round 18' 1 \
  "$(grep -c -E '^- [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z — waiver: gate=opponent; round=18; after=17; by=Rehan712; reason=[^;]+$' "$B")"
check 'the batch holds no other authorization line' 1 "$(grep -c -E '^- [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z — (waiver|spec-revision):' "$B")"
case "$MODE" in
  scratch)
    rm -rf "$X"; mkdir -p "$X"
    ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$X" && tar -xf - ) || exit 2
    ( cd "$X" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid -c core.hooksPath=/dev/null commit -qm base ) > /dev/null || exit 2
    w "$X" scratch-pre 18
    check 'scratch before the batch: round 18 refused at exit 4' 4 "$(cat "$WT/$r/r18-waiver1-scratch-pre-18.rc")"
    bash "$WT/$r/r11-insert.sh" "$X/$s/STATUS.md" "$B" || { echo 'FAIL insert'; exit 3; }
    bash "$WT/$r/r18-task-insert.sh" "$X/$s/tasks.md" "$T" || { echo 'FAIL task insert'; exit 3; }
    validate "$X" scratch;;
  live)
    [[ -f "$X/$s/STATUS.md" && -f "$X/$s/tasks.md" ]] || { echo 'FAIL no validated scratch copy'; exit 3; }
    w "$WT" live-pre 18
    check 'live before the batch: round 18 refused at exit 4' 4 "$(cat "$WT/$r/r18-waiver1-live-pre-18.rc")"
    cp "$WT/$s/STATUS.md" "$WT/$r/r18-dec1-STATUS-before.md"; cp "$WT/$s/tasks.md" "$WT/$r/r18-dec1-tasks-before.md"
    bash "$WT/$r/r11-insert.sh" "$WT/$s/STATUS.md" "$B" || { echo 'FAIL insert'; exit 3; }
    bash "$WT/$r/r18-task-insert.sh" "$WT/$s/tasks.md" "$T" || { echo 'FAIL task insert'; exit 3; }
    check 'live STATUS.md equals the validated scratch copy' 0 "$(cmp -s "$WT/$s/STATUS.md" "$X/$s/STATUS.md"; echo $?)"
    check 'live tasks.md equals the validated scratch copy' 0 "$(cmp -s "$WT/$s/tasks.md" "$X/$s/tasks.md"; echo $?)"
    validate "$WT" live
    rm -rf "$X";;
  *) echo "unknown mode"; exit 2;;
esac
echo "r18-decisions-1-apply $MODE failures=$fails"
(( fails == 0 ))
