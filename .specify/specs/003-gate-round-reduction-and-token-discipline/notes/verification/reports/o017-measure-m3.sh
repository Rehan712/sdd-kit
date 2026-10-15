#!/usr/bin/env bash
# O-017 measurement, M3 corrected, 2026-09-27 (session 7). Read-only against the live worktree.
# o017-measure.sh's M3 compared U's and P's snapshots while excluding only the harness records,
# so it FAILED on records that must differ: the path and index records of the eight files the
# candidate rule edits, and the untracked helper the script itself wrote into P
# (tests/.o017-spec-gate.sh). The diff it left (scratchpad m3keep/, C only) holds exactly those.
# This reruns M3 with that exclusion stated: every other record must be byte-equal, under C and
# en_US.UTF-8. P is the copy o017-measure.sh kept at <scratchpad>/o017-P; U is rebuilt here.
# Usage: bash o017-measure-m3.sh <scratchpad> <worktree>
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/o017-m3"; U="$R/U"; P="$SP/o017-P"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$U" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
[[ -d "$P/.git" ]] || { say 'FAIL the kept P copy is missing'; exit 2; }
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$U" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$U" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
edited='scripts/lib.sh|scripts/verification-lib.sh|scripts/spec-run.sh|scripts/spec-task.sh|scripts/spec-gate.sh|scripts/sdd-analyze.sh|scripts/spec-ac-coverage.sh|scripts/spec-evidence.sh'
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
for l in C en_US.UTF-8; do
  for d in U P; do
    root="$U"; [[ "$d" == P ]] && root="$P"
    ( cd "$root" && env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" bash -c '. scripts/verification-lib.sh && vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$w/$d-$l.nul" ) > "$w/$d-$l.out" 2>&1
    check "M3 $d snapshot under $l" 0 "$?"
    tr '\0' '\n' < "$w/$d-$l.nul" | paste - - - - - - | LC_ALL=C sed "s#$root#<repo>#g" > "$w/$d-$l.all"
    LC_ALL=C awk -F '\t' -v edited="^($edited)\$" '
      $1=="harness" || $1=="version" {next}
      ($1=="path" || $1=="index") && ($2 ~ edited || $2=="tests/.o017-spec-gate.sh") {next}
      {print}' "$w/$d-$l.all" > "$w/$d-$l.kept"
  done
  check "M3 under $l: every record outside the edited files equals U" same "$(cmp -s "$w/U-$l.kept" "$w/P-$l.kept" && echo same || echo differ)"
  say "  | records compared: $(wc -l < "$w/P-$l.kept" | tr -d ' ') of $(wc -l < "$w/P-$l.all" | tr -d ' '); excluded in P: $(( $(wc -l < "$w/P-$l.all") - $(wc -l < "$w/P-$l.kept") )) (8 harness, 1 version, 8 edited path, 8 edited index, 1 helper path)"
  check "M3 under $l: exactly 26 records excluded in P" 26 "$(( $(wc -l < "$w/P-$l.all") - $(wc -l < "$w/P-$l.kept") ))"
done
check 'M3: U snapshot is one digest under C and en_US.UTF-8' "$(cat "$w/U-C.out")" "$(cat "$w/U-en_US.UTF-8.out")"
check 'M3: P snapshot is one digest under C and en_US.UTF-8' "$(cat "$w/P-C.out")" "$(cat "$w/P-en_US.UTF-8.out")"
say "o017-measure-m3 failures=$fails"
cd "$SP" && rm -rf "$R"
(( fails == 0 ))
