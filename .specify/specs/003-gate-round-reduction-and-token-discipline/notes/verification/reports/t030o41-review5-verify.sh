#!/usr/bin/env bash
# Invoker reproduction of review-5 findings R5-1 to R5-5, 2026-09-25, BEFORE any repair.
# Usage: bash t030o41-review5-verify.sh <scratchpad> <worktree> <pre-delta dir>
# Read-only against the live worktree: its manifest enumeration is tarred into a
# standalone git copy and every probe runs there. R5-2 is checked by mechanism
# only (what the failed helper prints and what its callers then resolve to); no
# caller is run past that point, so nothing is written outside the sandbox.
set -uo pipefail
SP="$1"; WT="$2"; PRE="$3"
R="$SP/v5"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
expect() { if [[ "$2" == "$3" ]]; then printf 'PASS %s (want=%s got=%s)\n' "$1" "$2" "$3"; else printf 'FAIL %s (want=%s got=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi; }
note() { printf '  | %s\n' "$*"; }
has() { grep -c -F -- "$2" "$1" | awk '{print ($1 > 0)}'; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1 ); }
sub() { local n; n="$(OLD="$2" perl -0ne 'my $c = () = /\Q$ENV{OLD}\E/g; print $c' "$1")"
  [[ "$n" == 1 ]] || { note "literal occurs $n times in $1"; return 1; }; OLD="$2" NEW="$3" perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/' "$1"; }
subn() { local n; n="$(OLD="$3" perl -0ne 'my $c = () = /\Q$ENV{OLD}\E/g; print $c' "$1")"
  [[ "$n" == "$2" ]] || { note "literal occurs $n times (want $2) in $1"; return 1; }; OLD="$3" NEW="$4" perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/g' "$1"; }
run_one() { # <stem> <function> <tag> [env assignments...]
  local stem="$1" fn="$2" tag="$3"; shift 3
  ( cd "$C" && env "$@" bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$stem" "$fn" "$w/$fn.$tag.out" )
}
enum() { ( cd "$C" && env "${@:2}" bash -c '. scripts/verification-lib.sh; vf_source_paths "$PWD" "$1"' _ "$1" ); }
mvgd() { # <helpers.sh> [env...] -> "rc=<rc> out=<stdout>"
  local h="$1"; shift
  ( cd "$C" && env "$@" bash -c '. "$1"; SANDBOX="$(mktemp -d "$TMPDIR/mv.XXXXXX")"; export SANDBOX
      spec="$(make_verification_git_dir probe 2>/dev/null)"; rc=$?
      printf "rc=%s spec=[%s] resolves=[%s] insandbox=%s author=[%s] objfmt=%s\n" "$rc" "${spec:+set}" \
        "$(cd "$spec/../../.." 2>/dev/null && pwd -P)" "$([[ -n "$spec" && "$spec" == "$SANDBOX"/* ]] && echo yes || echo no)" \
        "$(git -C "$SANDBOX/probe" log -1 --format=%an 2>/dev/null)" "$(git -C "$SANDBOX/probe" rev-parse --show-object-format 2>/dev/null)"' _ "$h" )
}

L0="$(live_state)"; note "live worktree porcelain digest before: $L0"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul"; expect 'live enumeration rc' 0 "$?"
( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$C" && tar -xf - ); expect 'copy extraction rc' 0 "$?"
cd "$C" || exit 2
git init -q && git add -A && git -c user.name=v -c user.email=v@invalid commit -qm base; expect 'copy committed' 0 "$?"
printf 'tests/.one-*.sh\n' >> .git/info/exclude
for stem in verification gate-contracts spec-ac-coverage; do awk '$0 != "t_run_all"' "tests/test-$stem.sh" > "tests/.one-$stem.sh"; done
base="$(git status --porcelain --ignored)"
cp "$PRE/tests/helpers.sh" "$w/helpers-pre.sh"
# The pre-delta helper sources nothing relative to itself but KIT_DIR; give it the copy's.
sed "s|^KIT_DIR=.*|KIT_DIR=\"$C\"|" "$w/helpers-pre.sh" > "$w/helpers-pre-kit.sh"
mkdir -p "$w/quarantine"

echo '== R5-2 a failed fixture build leaves its callers resolving to the filesystem root'
out="$(mvgd tests/helpers.sh GIT_QUARANTINE_PATH="$w/quarantine")"; note "post-delta: $out"
expect 'R5-2 post-delta: the build fails' 1 "$(printf '%s' "$out" | grep -c '^rc=1 ')"
expect 'R5-2 post-delta: the helper prints no spec' 1 "$(printf '%s' "$out" | grep -c 'spec=\[\]')"
expect 'R5-2 post-delta: a caller resolves repo to /' 1 "$(printf '%s' "$out" | grep -c 'resolves=\[/\]')"
out="$(mvgd "$w/helpers-pre-kit.sh" GIT_QUARANTINE_PATH="$w/quarantine")"; note "pre-delta:  $out"
expect 'R5-2 pre-delta: the helper still printed its sandbox spec' 1 "$(printf '%s' "$out" | grep -c 'insandbox=yes')"
n="$(grep -n -E 'spec="\$\(make_verification_git_dir [^)]*\)"' tests/*.sh | grep -v -E '\|\||fixture_repository_cases' | wc -l | tr -d ' ')"
note "callers that do not check the status: $n"; expect 'R5-2 unchecked callers exist' 1 "$([[ $n -gt 0 ]] && echo 1 || echo 0)"

echo '== R5-4 git environment still decides fixture builds'
out="$(mvgd tests/helpers.sh GIT_AUTHOR_NAME=Dev)"; note "GIT_AUTHOR_NAME=Dev: $out"
expect 'R5-4 an ambient GIT_AUTHOR_NAME replaces the fixed identity' 1 "$(printf '%s' "$out" | grep -c 'author=\[Dev\]')"
out="$(mvgd tests/helpers.sh GIT_DEFAULT_HASH=sha256)"; note "GIT_DEFAULT_HASH=sha256: $out"
expect 'R5-4 an ambient GIT_DEFAULT_HASH decides the object format' 1 "$(printf '%s' "$out" | grep -c 'objfmt=sha256')"
enum "$w/e-plain.nul"; enum "$w/e-quar.nul" GIT_QUARANTINE_PATH="$w/quarantine"
cmp -s "$w/e-plain.nul" "$w/e-quar.nul"; expect 'R5-4 the kit enumeration is identical under GIT_QUARANTINE_PATH' 0 "$?"
run_one verification fixture_repository_cases quar GIT_QUARANTINE_PATH="$w/quarantine"; expect 'R5-4 fixture_repository_cases fails under GIT_QUARANTINE_PATH' 1 "$?"
run_one verification fixture_repository_cases plain; expect 'R5-4 control: it passes without it' 0 "$?"

echo '== R5-5 unchecked init sites, and E08'"'"'s reason'
mkdir -p "$w/noinit"; printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = init ] && { echo "git: init refused (probe)" >&2; exit 128; }; done\nexec "%s" "$@"\n' "$(command -v git)" > "$w/noinit/git"; chmod +x "$w/noinit/git"
run_one spec-ac-coverage test_default_root_is_the_git_toplevel noinit PATH="$w/noinit:$PATH"
expect 'R5-5 test_default_root_is_the_git_toplevel passes with init refused' 0 "$?"
expect 'R5-5 and init really was refused' 1 "$(has "$w/test_default_root_is_the_git_toplevel.noinit.out" 'init refused (probe)')"
origins="$(env -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM HOME="$w/empty-home" XDG_CONFIG_HOME="$w/empty-home/.config" git config --list --show-origin 2>/dev/null | cut -f1 | sort -u | tr '\n' ' ')"
note "origins under the pin without GIT_CONFIG_NOSYSTEM: $origins"
expect 'R5-5 this git does read a system file' 1 "$([[ -n "$origins" ]] && echo 1 || echo 0)"

echo '== R5-3 E15 makes tree 2 vacuous for an over-correcting scan'
H="$R/hostile"; mkdir -p "$H/hooks" "$H/template/hooks" "$H/template/info"
printf '#!/bin/sh\nexit 1\n' > "$H/hooks/pre-commit"; chmod +x "$H/hooks/pre-commit"; cp -p "$H/hooks/pre-commit" "$H/template/hooks/pre-commit"
printf '*\n' > "$H/template/info/exclude"
printf '[core]\n\thooksPath = %s\n' "$H/hooks" > "$H/gitconfig"
HX=(GIT_CONFIG_GLOBAL="$H/gitconfig" GIT_TEMPLATE_DIR="$H/template")
G=tests/test-gate-contracts.sh
BARE_OLD='/^[^.]{0,40}(is|are|were|remain|remains) (always |still |also )?(hashed|included|part of the (snapshot|manifest|set))/'
BARE_NEW='/^[^.]{0,40}(hashed|included|part of the (snapshot|manifest|set))/'
sub "$G" "$BARE_OLD" "$BARE_NEW"; expect 'R5-3 over-correction mutant applied' 0 "$?"
awk '$0 != "t_run_all"' "$G" > tests/.one-gate-contracts.sh
run_one gate-contracts superseded_environment_cases bare "${HX[@]}"; expect 'R5-3 the over-correction is killed' 1 "$?"
expect 'R5-3 by tree 2' 1 "$(has "$w/superseded_environment_cases.bare.out" 'the guard flagged a sentence stating the replacement rule')"
sub "$G" 'mkdir -p "$tree"; fixture_git -C "$tree" init -q' 'mkdir -p "$tree"; git -C "$tree" init -q'; expect 'R5-3 K60 applied on top' 0 "$?"
awk '$0 != "t_run_all"' "$G" > tests/.one-gate-contracts.sh
run_one gate-contracts superseded_environment_cases bare-k60 "${HX[@]}"; note "bare+k60@hostile rc=$?"
expect 'R5-3 with K60, tree 2 no longer reports the over-correction' 0 "$(has "$w/superseded_environment_cases.bare-k60.out" 'the guard flagged a sentence stating the replacement rule')"
git checkout -q -- "$G"; awk '$0 != "t_run_all"' "$G" > tests/.one-gate-contracts.sh

echo '== R5-1 E13 is killed by configuration that reaches add and checkout'
printf '[core]\n\tautocrlf = true\n' > "$w/crlf.gitconfig"
enum "$w/e-crlf.nul" GIT_CONFIG_GLOBAL="$w/crlf.gitconfig"
cmp -s "$w/e-plain.nul" "$w/e-crlf.nul"; expect 'R5-1 the kit enumeration is identical under autocrlf' 0 "$?"
run_one verification test_capture_provenance crlf-base GIT_CONFIG_GLOBAL="$w/crlf.gitconfig"; expect 'R5-1 unmutated test_capture_provenance passes under autocrlf' 0 "$?"
T=tests/test-verification.sh
sub "$T" 'fixture_git -C "$repo" checkout -- "$path"' 'git -C "$repo" checkout -- "$path"' \
  && sub "$T" '  fixture_git -C "$repo" add src/parser.sh' '  git -C "$repo" add src/parser.sh' \
  && sub "$T" '  fixture_git -C "$repo" reset -q HEAD -- src/parser.sh' '  git -C "$repo" reset -q HEAD -- src/parser.sh' \
  && sub "$T" '  fixture_git -C "$SANDBOX/foreign" add only-in-foreign.md' '  git -C "$SANDBOX/foreign" add only-in-foreign.md' \
  && subn "$T" 2 '    fixture_git -C "$repo" add -f -- "$sibling/$path"' '    git -C "$repo" add -f -- "$sibling/$path"' \
  && sub "$T" 'fixture_git -C "$repo" rm -q -f --cached' 'git -C "$repo" rm -q -f --cached' \
  && sub "$T" '      fixture_git -C "$repo" config core.ignorecase "$ignorecase"' '      git -C "$repo" config core.ignorecase "$ignorecase"' \
  && sub "$T" '    fixture_git -C "$repo" config core.ignorecase true' '    git -C "$repo" config core.ignorecase true'
expect 'R5-1 E13 applied' 0 "$?"
awk '$0 != "t_run_all"' "$T" > tests/.one-verification.sh
run_one verification test_capture_provenance crlf-e13 GIT_CONFIG_GLOBAL="$w/crlf.gitconfig"; expect 'R5-1 E13 fails test_capture_provenance under autocrlf' 1 "$?"
note "$(grep -m2 'assert:' "$w/test_capture_provenance.crlf-e13.out" | cut -c1-120 | tr '\n' ' ')"
git checkout -q -- "$T"; awk '$0 != "t_run_all"' "$T" > tests/.one-verification.sh
expect 'copy unchanged' "$base" "$(git status --porcelain --ignored)"

cd "$SP" || exit 2
L1="$(live_state)"; note "live worktree porcelain digest after: $L1"
expect 'live worktree unchanged' "$L0" "$L1"
printf 'verify-5 failures=%s\n' "$fails"
(( fails == 0 ))
