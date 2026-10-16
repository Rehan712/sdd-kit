#!/usr/bin/env bash
# T030o43 dev run, 2026-09-27 (session 7). Read-only against the live worktree:
# every suite runs in a standalone copy built from the live manifest enumeration,
# with TMPDIR inside it, and the copy's and the live status are checked unchanged.
# Usage: bash t030o43-dev.sh <scratchpad> <worktree> <quick|full|full-locale|suite:<file>>
#   quick        ShellCheck and the four changed suites, in parallel copies
#   full         bash tests/run.sh && bash tests/shellcheck.sh, plainly
#   full-locale  the same with every LC_* removed and LANG=en_US.UTF-8
set -uo pipefail
SP="$1"; WT="$2"; MODE="$3"
tag="${MODE//[:\/.]/-}"
R="$SP/t030o43-dev-$tag"
rm -rf "$R"; mkdir -p "$R"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
copystate() { ( cd "$1" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | shasum -a 256 | cut -c1-16; }
mkcopy() { # <dir>
  mkdir -p "$1/tmp" "$1/kit"
  ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$1/kit" && tar -xf - ) || return 1
  ( cd "$1/kit" && git init -q && git add -A && git -c user.name=d -c user.email=d@invalid commit -qm base ) >/dev/null || return 1
}
live_before="$(livestate)"
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
runin() { # <copy> <label> <command...>: run in the copy's kit with its TMPDIR; receipt <label>.{log,rc}
  local c="$1" label="$2" before; shift 2
  before="$(copystate "$c/kit")"
  ( cd "$c/kit" && TMPDIR="$c/tmp" "$@" ) > "$R/$label.log" 2>&1; echo $? > "$R/$label.rc"
  check "$label exit 0" 0 "$(cat "$R/$label.rc")"
  check "$label left its copy unchanged" "$before" "$(copystate "$c/kit")"
  say "  | $(LC_ALL=C grep -E -- '-- [0-9]+/[0-9]+ passed|FAIL' "$R/$label.log" | tr '\n' ' ' | cut -c1-600)"
}
case "$MODE" in
  quick)
    mkcopy "$R/c0" || { say 'FAIL copy'; exit 2; }
    runin "$R/c0" shellcheck bash tests/shellcheck.sh
    pids=()
    for suite in test-verification test-gate-contracts test-spec-gate test-sdd-analyze; do
      mkcopy "$R/$suite" || { say "FAIL copy $suite"; exit 2; }
      ( runin "$R/$suite" "$suite" bash "tests/$suite.sh" > "$R/$suite.verdict" ) & pids+=($!)
    done
    for p in "${pids[@]}"; do wait "$p"; done
    for suite in test-verification test-gate-contracts test-spec-gate test-sdd-analyze; do
      cat "$R/$suite.verdict"; fails=$((fails + $(LC_ALL=C grep -c '^FAIL' "$R/$suite.verdict")))
    done;;
  full)
    mkcopy "$R/c0" || { say 'FAIL copy'; exit 2; }
    runin "$R/c0" full bash -c 'bash tests/run.sh && bash tests/shellcheck.sh';;
  full-locale)
    mkcopy "$R/c0" || { say 'FAIL copy'; exit 2; }
    runin "$R/c0" full-locale env ${nolc[@]+"${nolc[@]}"} -u LANG LANG=en_US.UTF-8 bash -c 'bash tests/run.sh && bash tests/shellcheck.sh';;
  suite:*)
    mkcopy "$R/c0" || { say 'FAIL copy'; exit 2; }
    runin "$R/c0" "${MODE#suite:}" bash "tests/${MODE#suite:}.sh";;
  *) say "unknown mode $MODE"; exit 2;;
esac
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$(livestate)"
say "t030o43-dev $MODE failures=$fails"
# Keep failing logs for reading; the receipts the caller keeps are this output.
if (( fails == 0 )); then rm -rf "$R"; else say "kept: $R"; fi
(( fails == 0 ))
