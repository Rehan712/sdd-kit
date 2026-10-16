#!/usr/bin/env bash
# Invoker reproduction of review-6 findings R6-1 to R6-4, 2026-09-25, BEFORE any repair.
# Usage: bash t030o41-review6-verify.sh <scratchpad> <worktree>
# Read-only against the live worktree: its manifest enumeration is tarred into
# a standalone git copy and every probe runs there. R6-2 is checked by
# mechanism only (what each helper prints when its copy fails); no caller is
# run past that point. R6-1's enclosing repository is a scratch repository
# inside this script's work directory.
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/v6"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
fails=0
expect() { if [[ "$2" == "$3" ]]; then printf 'PASS %s (want=%s got=%s)\n' "$1" "$2" "$3"; else printf 'FAIL %s (want=%s got=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi; }
note() { printf '  | %s\n' "$*"; }
has() { grep -c -F -- "$2" "$1" | awk '{print ($1 > 0)}'; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1 ); }
sub() { local n; n="$(OLD="$2" perl -0ne 'my $c = () = /\Q$ENV{OLD}\E/g; print $c' "$1")"
  [[ "$n" == 1 ]] || { note "literal occurs $n times in $1"; return 1; }; OLD="$2" NEW="$3" perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/' "$1"; }
run_one() { # <stem> <function> <tag> [env assignments...]
  local stem="$1" fn="$2" tag="$3"; shift 3
  ( cd "$C" && env "$@" bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$stem" "$fn" "$w/$fn.$tag.out" )
}

L0="$(live_state)"; note "live worktree porcelain digest before: $L0"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul"; expect 'live enumeration rc' 0 "$?"
( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$C" && tar -xf - ); expect 'copy extraction rc' 0 "$?"
cd "$C" || exit 2
git init -q && git add -A && git -c user.name=v -c user.email=v@invalid commit -qm base; expect 'copy committed' 0 "$?"
printf 'tests/.one-*.sh\n' >> .git/info/exclude
for stem in verification spec-ac-coverage build-adapters golden-example spec-gate; do awk '$0 != "t_run_all"' "tests/test-$stem.sh" > "tests/.one-$stem.sh"; done
base="$(git status --porcelain --ignored)"
mkdir -p "$w/noinit"
printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = init ] && { echo "git: init refused (probe)" >&2; exit 128; }; done\nexec "%s" "$@"\n' "$(command -v git)" > "$w/noinit/git"
chmod +x "$w/noinit/git"

echo '== R6-4 K33 survives: the suite-start clearing of git-local names is unjudged'
H=tests/helpers.sh
sub "$H" 'for _t_env in $(git rev-parse --local-env-vars); do unset "$_t_env"; done' ':'; expect 'R6-4 K33 applied' 0 "$?"
for stem in verification; do awk '$0 != "t_run_all"' "tests/test-$stem.sh" > "tests/.one-$stem.sh"; done
run_one verification reuse_command_input_cases k33; expect 'R6-4 reuse_command_input_cases passes with K33' 0 "$?"
git checkout -q -- "$H"

echo '== R6-3 E19 changes a verdict under a failing init'
run_one spec-ac-coverage test_default_root_is_the_git_toplevel noinit PATH="$w/noinit:$PATH"
expect 'R6-3 unmutated: the refused init fails the test by name' 1 "$?"
expect 'R6-3 with the record naming it' 1 "$(has "$w/test_default_root_is_the_git_toplevel.noinit.out" 'build-failure record: ac-coverage-project')"
sub tests/test-spec-ac-coverage.sh ' || fixture_build_failed ac-coverage-project' ''; expect 'R6-3 E19 site literal applied' 0 "$?"
awk '$0 != "t_run_all"' tests/test-spec-ac-coverage.sh > tests/.one-spec-ac-coverage.sh
run_one spec-ac-coverage test_default_root_is_the_git_toplevel e19 PATH="$w/noinit:$PATH"
expect 'R6-3 with the check removed the test passes with no repository' 0 "$?"
git checkout -q -- tests/test-spec-ac-coverage.sh; awk '$0 != "t_run_all"' tests/test-spec-ac-coverage.sh > tests/.one-spec-ac-coverage.sh

echo '== R6-1 after a failed init, a later fixture write climbs into an enclosing repository'
E="$w/enclosing"; mkdir -p "$E/sb"; git -C "$E" init -q; printf 'x\n' > "$E/pending.txt"
git -C "$E" add pending.txt && git -C "$E" -c user.name=E -c user.email=e@invalid commit -qm one
printf 'y\n' > "$E/untracked.txt"
before="$(git -C "$E" ls-files --stage | shasum -a 256)"
( cd "$C" && PATH="$w/noinit:$PATH" bash -c '. tests/helpers.sh; SANDBOX="$1"; export SANDBOX
    spec="$(make_verification_git_dir probe 2>/dev/null)"; repo="$(cd "$spec/../../.." && pwd -P)"
    fixture_git -C "$repo" add -A > /dev/null 2>&1; echo "repo=$repo"' _ "$E/sb" ) > "$w/r61.out" 2>&1
note "$(cat "$w/r61.out")"
after="$(git -C "$E" ls-files --stage | shasum -a 256)"
expect 'R6-1 the enclosing repository index changed' 1 "$([[ "$before" != "$after" ]] && echo 1 || echo 0)"
note "enclosing index entries now: $(git -C "$E" ls-files | wc -l | tr -d ' ')"

echo '== R6-2 copy helpers on a failed copy (mechanism only)'
mkdir -p "$w/nokit"
out="$( ( cd "$C" && bash -c '. tests/.one-build-adapters.sh; SANDBOX="$1"; export SANDBOX; mkdir -p "$SANDBOX"
    printed="$(on_host_kit "$2" stage_kit 2>/dev/null)"; printf "rc=%s printed=[%s]\n" "$?" "$printed"' _ "$w/sb-kit" "$w/nokit" ) )"
note "stage_kit: $out"; expect 'R6-2 stage_kit prints nothing on a failed copy' 1 "$(printf '%s' "$out" | grep -c 'printed=\[\]')"
out="$( ( cd "$C" && bash -c '. tests/.one-golden-example.sh; SANDBOX="$1"; export SANDBOX; mkdir -p "$SANDBOX"
    printed="$(on_host_kit "$2" stage_example 2>/dev/null)"; printf "printed=[%s]\n" "$printed"' _ "$w/sb-ex" "$w/nokit" ) )"
note "stage_example: $(printf '%s' "$out" | tr '\n' ' ' | cut -c1-200)"
expect 'R6-2 stage_example captures an assert line into the path' 1 "$(printf '%s' "$out" | grep -c 'assert:')"
out="$( ( cd "$C" && bash -c '. tests/.one-spec-gate.sh; SANDBOX="$1"; export SANDBOX; mkdir -p "$SANDBOX"
    spec="$(make_verification_git_dir fl)"; printed="$(on_host_kit "$2" floor_fixture "$spec" 2>/dev/null)"; printf "printed=[%s]\n" "$printed"' _ "$w/sb-fl" "$w/nokit" ) )"
note "floor_fixture: $(printf '%s' "$out" | tr '\n' ' ' | cut -c1-200)"
expect 'R6-2 floor_fixture captures an assert line into the path' 1 "$(printf '%s' "$out" | grep -c 'assert:')"
expect 'copy unchanged' "$base" "$(git status --porcelain --ignored)"

cd "$SP" || exit 2
L1="$(live_state)"; note "live worktree porcelain digest after: $L1"
expect 'live worktree unchanged' "$L0" "$L1"
printf 'verify-6 failures=%s\n' "$fails"
(( fails == 0 ))
