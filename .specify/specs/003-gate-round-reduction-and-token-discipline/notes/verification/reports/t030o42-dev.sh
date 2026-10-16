#!/usr/bin/env bash
# T030o42 dev run, 2026-09-26: the O-016 repair in standalone copies.
# Usage: bash t030o42-dev.sh <scratchpad> <worktree> <tag> [quick]
# Read-only against the live worktree: copies are built from its manifest
# enumeration (GIT_OPTIONAL_LOCKS=0). quick: ShellCheck, the new fixture alone
# and test_capture_provenance. full adds the whole suite three times in three
# copies, in parallel: plainly, under LANG=de_DE.UTF-8 (every LC_* removed)
# and under LC_ALL=en_GB.UTF-8. Every exit is captured from the command
# itself; each copy's `git status --porcelain --ignored -uall` must be
# unchanged by its runs, and the live worktree's status outside the spec's
# notes/verification/ (where these receipts land) is compared before and after.
set -uo pipefail
SP="$1"; WT="$2"; TAG="$3"; MODE="${4:-full}"
R="$SP/t030o42-$TAG"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
say() { printf '%s\n' "$*"; }
verdict() { if [[ "$2" == "$3" ]]; then say "PASS $1 (want=$2 got=$3)"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall | grep -v -F "$s/notes/verification/" | LC_ALL=C sort | shasum -a 256 | cut -d' ' -f1 ); }
copy_state() { ( cd "$1" && git status --porcelain --ignored -uall | shasum -a 256 | cut -d' ' -f1 ); }
totals() { awk '/-- [0-9]+\/[0-9]+ passed/ {split($2, a, "/"); ok += a[1]; all += a[2]} END {printf "%d/%d", ok, all}' "$1"; }
L0="$(live_state)"; say "  | live status outside notes/verification/ before: $L0"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul" || { say 'FAIL live enumeration'; exit 2; }
build() {
  mkdir -p "$R/$1" && ( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$R/$1" && tar -xf - ) \
    && ( cd "$R/$1" && git init -q && git add -A && git -c user.name=dev -c user.email=dev@invalid commit -qm base )
}
build c1; verdict 'copy c1 built' 0 "$?"
( cd "$R/c1" && printf 'tests/.one-*.sh\n' >> .git/info/exclude && awk '$0 != "t_run_all"' tests/test-verification.sh > tests/.one-verification.sh )
S1="$(copy_state "$R/c1")"
run_one() { # <function>
  ( cd "$R/c1" && bash -c '. tests/.one-verification.sh
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$1"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$2"; exit "$rc"' _ "$1" "$w/$1.out" )
}

say '== ShellCheck (bash tests/shellcheck.sh)'
( cd "$R/c1" && bash tests/shellcheck.sh ) > "$w/shellcheck.out" 2>&1; rc=$?
verdict 'bash tests/shellcheck.sh' 0 "$rc"; [[ "$rc" == 0 ]] || head -30 "$w/shellcheck.out" | sed 's/^/  | /'
say '== the new fixture, then its test function'
for fn in reuse_command_locale_cases test_capture_provenance; do
  start="$(date -u +%H:%M:%SZ)"; run_one "$fn"; rc=$?
  verdict "$fn ($start - $(date -u +%H:%M:%SZ))" 0 "$rc"
  [[ "$rc" == 0 ]] || grep -E -A3 'assert:|output:|build-failure' "$w/$fn.out" | head -30 | cut -c1-240 | sed 's/^/  |   /'
done
verdict 'copy c1 unchanged by the quick runs' "$S1" "$(copy_state "$R/c1")"

if [[ "$MODE" != quick ]]; then
  build c2; verdict 'copy c2 built' 0 "$?"; build c3; verdict 'copy c3 built' 0 "$?"
  S2="$(copy_state "$R/c2")"; S3="$(copy_state "$R/c3")"
  nolc=(); for n in $(compgen -e); do case "$n" in LC_*) nolc+=(-u "$n");; esac; done
  say "== full suite x3 in parallel, started $(date -u +%H:%M:%SZ)"
  ( cd "$R/c1" && bash tests/run.sh > "$w/full-plain.out" 2>&1; echo "$?" > "$w/full-plain.rc" ) & a=$!
  ( cd "$R/c2" && env ${nolc[@]+"${nolc[@]}"} LANG=de_DE.UTF-8 bash tests/run.sh > "$w/full-de_DE.out" 2>&1; echo "$?" > "$w/full-de_DE.rc" ) & b=$!
  ( cd "$R/c3" && env LC_ALL=en_GB.UTF-8 bash tests/run.sh > "$w/full-en_GB.out" 2>&1; echo "$?" > "$w/full-en_GB.rc" ) & c=$!
  wait "$a" "$b" "$c"
  say "  | returned $(date -u +%H:%M:%SZ)"
  for t in plain de_DE en_GB; do
    verdict "bash tests/run.sh ($t)" 0 "$(cat "$w/full-$t.rc" 2>/dev/null || echo MISSING)"
    say "  | $t: $(totals "$w/full-$t.out") $(grep -o -E 'FAIL test_[A-Za-z0-9_]+' "$w/full-$t.out" | tr '\n' ' ')"
  done
  grep -E -- '-- [0-9]+/[0-9]+ passed' "$w/full-plain.out" | sed 's/^/  | plain /'
  verdict 'copy c1 unchanged by the full suite' "$S1" "$(copy_state "$R/c1")"
  verdict 'copy c2 unchanged by the full suite' "$S2" "$(copy_state "$R/c2")"
  verdict 'copy c3 unchanged by the full suite' "$S3" "$(copy_state "$R/c3")"
fi
cd "$SP" || exit 2
L1="$(live_state)"; say "  | live status outside notes/verification/ after: $L1"
verdict 'live worktree unchanged outside notes/verification/' "$L0" "$L1"
say "t030o42-dev $TAG failures=$fails"
(( fails == 0 ))
