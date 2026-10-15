#!/usr/bin/env bash
# T030o42 mutation matrix, 2026-09-27: every guard of the O-016 repair isolated
# in a standalone copy built from the live manifest enumeration.
# Usage: bash t030o42-mutations.sh <scratchpad> <worktree> [DRY=1 in the environment]
#
# Kinds: kill  -- the judge must FAIL and print the named diagnostic;
#        witness -- the judge must PASS: it shows which guard a kill depends on;
#        equiv -- the judge must PASS, with the argument recorded beside the row.
# The judge is reuse_command_locale_cases, run alone through a runner-less copy
# of tests/test-verification.sh, exactly as t_run_all runs a test (a fresh
# SANDBOX, the build-failure record checked). Each mutant is a literal
# replacement that must match exactly once (DRY=1 checks only that); every
# restore is checked byte-identical with cmp against a pristine copy.
set -uo pipefail
SP="$1"; WT="$2"; DRY="${DRY:-0}"
R="$SP/t030o42-matrix"; C="$R/copy"; P="$R/pristine"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$P" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
say() { printf '%s\n' "$*"; }
verdict() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul" || { say 'FAIL enumeration'; exit 2; }
for d in "$C" "$P"; do ( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$d" && tar -xf - ) || { say 'FAIL extraction'; exit 2; }; done
( cd "$C" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
printf 'tests/.one-*.sh\n' >> "$C/.git/info/exclude"

# replace <file> <old> <new>: literal, must match exactly once. Multi-line
# literals are passed with $'...'.
replace() {
  perl -e '
    my ($f, $old, $new) = @ARGV; local $/; open my $h, "<", $f or exit 3; my $t = <$h>; close $h;
    my $n = () = $t =~ /\Q$old\E/g; exit 4 if $n != 1;
    exit 0 if $ENV{DRY} eq "1";
    $t =~ s/\Q$old\E/$new/; open $h, ">", $f or exit 3; print $h $t; close $h; exit 0' "$C/$1" "$2" "$3"
}
judge() { # -> exit of reuse_command_locale_cases; output in $w/judge.out
  ( cd "$C" && awk '$0 != "t_run_all"' tests/test-verification.sh > tests/.one-verification.sh && bash -c '. tests/.one-verification.sh
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; reuse_command_locale_cases; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out"; exit "$rc"' ) > "$w/judge.out" 2>&1
}
restore() {
  ( cd "$C" && git checkout -q -- . && rm -f tests/.one-verification.sh ) || return 1
  local f; for f in tests/helpers.sh tests/run.sh tests/shellcheck.sh tests/test-verification.sh .specify/stack.yml; do
    cmp -s "$C/$f" "$P/$f" || { say "FAIL restore not byte-identical: $f"; fails=$((fails+1)); }
  done
}
row() { # <id> <kind> <diagnostic-or-empty> <file old new>...
  local id="$1" kind="$2" diag="$3" rc; shift 3
  while (( $# )); do
    replace "$1" "$2" "$3"; rc=$?
    verdict "$id literal applies once in $1" 0 "$rc"
    shift 3
  done
  [[ "$DRY" == 1 ]] && { restore; return; }
  judge; rc=$?
  case "$kind" in
    kill)
      verdict "$id KILLED (judge rc)" 1 "$([[ "$rc" != 0 ]] && echo 1 || echo 0)"
      verdict "$id diagnostic: $diag" 1 "$(grep -c -F -- "$diag" "$w/judge.out" | awk '{print ($1 > 0)}')";;
    witness|equiv)
      verdict "$id SURVIVES as argued ($kind)" 0 "$rc";;
  esac
  [[ "$rc" == 0 || "$kind" == kill ]] || grep -E 'assert:' "$w/judge.out" | head -5 | sed 's/^/  |   /'
  restore
}

say "== baseline $(date -u +%H:%M:%SZ)"
if [[ "$DRY" != 1 ]]; then
  judge; verdict 'B0 unmutated fixture passes' 0 "$?"
  ( cd "$C" && bash tests/shellcheck.sh ) > "$w/b1.out" 2>&1; verdict 'B1 unmutated ShellCheck passes' 0 "$?"
  restore
fi

PIN_H='export LC_ALL=C

KIT_DIR='
PIN_R='export LC_ALL=C

TESTS_DIR='
PIN_S='export LC_ALL=C

ROOT='
say '== kill rows'
row K1 kill 'AC-020: a suite did not export LC_ALL=C to the programs it runs (O-016)' \
  tests/helpers.sh "$PIN_H" $'\nKIT_DIR='
row K2 kill 'AC-020: a suite did not export LC_ALL=C to the programs it runs (O-016)' \
  tests/helpers.sh "$PIN_H" $'LC_ALL=C\n\nKIT_DIR='
row K3 kill "AC-020: bash tests/run.sh ran a suite under the caller's locale (O-016)" \
  tests/run.sh "$PIN_R" $'\nTESTS_DIR='
row K4 kill "AC-020: bash tests/shellcheck.sh ran ShellCheck under the caller's locale (O-016)" \
  tests/shellcheck.sh "$PIN_S" $'\nROOT='
row K5 kill 'AC-020: reuse-checked command has no locale probe: bash tests/run.sh verification' \
  .specify/stack.yml $'reuse_checks:\n' $'reuse_checks:\n  - \'bash tests/run.sh verification\'\n'
# The behaviour half kills on its own: with the export assertion gone, the
# usage-limits cases still fail the unpinned suite under both locales.
row K6 kill 'AC-020: a usage-limits case followed LANG=en_GB.UTF-8 (O-016)' \
  tests/helpers.sh "$PIN_H" $'\nKIT_DIR=' \
  tests/test-verification.sh "  assert_eq 'C LC_ALL=C' \"\$OUT\" 'AC-020: a suite did not export LC_ALL=C to the programs it runs (O-016)'" ':'
# The same row, judged on the second locale's diagnostic.
row K6b kill 'AC-020: a usage-limits case followed LANG=de_DE.UTF-8 (O-016)' \
  tests/helpers.sh "$PIN_H" $'\nKIT_DIR=' \
  tests/test-verification.sh "  assert_eq 'C LC_ALL=C' \"\$OUT\" 'AC-020: a suite did not export LC_ALL=C to the programs it runs (O-016)'" ':'
# The precondition: on macOS both locales must be live, or the behaviour half
# would pass vacuously.
row K7 kill 'AC-020: precondition: macOS ships en_GB.UTF-8 and de_DE.UTF-8, but only 0 of them changed date %p' \
  tests/test-verification.sh '[[ "$(locale_pm ${nolc[@]+"${nolc[@]}"} LANG="$l")" != "$c_pm" ]] || continue' 'continue'

# K8: removing the caller's LC_* names is what makes every probe hostile. The
# outer suite has LC_ALL=C exported by its own helpers.sh, so a probe that kept
# it would pass without the pin it judges (K3 and K4 depend on the removal).
# On macOS the precondition catches a probe environment that is not hostile.
row K8 kill 'AC-020: precondition: macOS ships en_GB.UTF-8 and de_DE.UTF-8, but only 0 of them changed date %p' \
  tests/test-verification.sh 'case "$name" in LC_*) nolc+=(-u "$name");; esac' ':'

say '== argued rows'
# E1: run.sh's pin moved after the enumeration, just before the suites run.
# Equivalent: before the loop run.sh runs only git ls-files -z (NUL-framed
# bytes, no locale-dependent output) and bash case patterns without classes or
# ranges, so nothing a locale reads precedes the pin on any path to a verdict.
row E1 equiv '' \
  tests/run.sh "$PIN_R" $'\nTESTS_DIR=' \
  tests/run.sh $'rc=0\nfiles=0\n' $'export LC_ALL=C\nrc=0\nfiles=0\n'

say "== done $(date -u +%H:%M:%SZ)"
say "t030o42-mutations failures=$fails"
(( fails == 0 ))
