#!/usr/bin/env bash
# Invoker reproduction of review-4 findings F1-F4, 2026-09-25, BEFORE any repair.
# Usage: bash t030o41-review4-verify.sh <scratchpad> <worktree>
# Read-only against the live worktree: its manifest enumeration is tarred into a
# standalone git copy and every probe runs there. Exits are captured from the
# command itself, never a pipe. The last step runs the whole suite once under a
# global core.hooksPath whose pre-commit rejects, to measure F2's reach.
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/v4"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
expect() { if [[ "$2" == "$3" ]]; then printf 'PASS %s (want=%s got=%s)\n' "$1" "$2" "$3"; else printf 'FAIL %s (want=%s got=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi; }
note() { printf '  | %s\n' "$*"; }
has() { grep -c -F -- "$2" "$1" | awk '{print ($1 > 0)}'; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1 ); }
sub() { # <file> <old> <new>, exactly once
  local n; n="$(OLD="$2" perl -0ne 'my $c = () = /\Q$ENV{OLD}\E/g; print $c' "$1")"
  [[ "$n" == 1 ]] || { note "literal occurs $n times in $1"; return 1; }
  OLD="$2" NEW="$3" perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/' "$1"
}
run_one() { # <stem> <function> <tag> [env assignments...]
  local stem="$1" fn="$2" tag="$3"; shift 3
  ( cd "$C" && env "$@" bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$stem" "$fn" "$w/$fn.$tag.out" )
}
block() { # <line prefix that starts it> <substring of its last line> <tag> [env...]: a verbatim block of reuse_command_input_cases
  local start="$1" end="$2" tag="$3" text fixture; shift 3
  text="$(cd "$C" && awk -v a="$start" -v b="$end" 'index($0, a) == 1 {on=1} on {print} on && index($0, b) {exit}' tests/test-verification.sh)"
  fixture="$(cd "$C" && awk '/^snapshot_fixture\(\) \{/ {on=1} on {print} on && /^\}/ {exit}' tests/test-verification.sh)"
  [[ -n "$text" && -n "$fixture" ]] || { note "block $tag not found"; return 9; }
  ( cd "$C" && env "$@" bash -c '. tests/helpers.sh; eval "$2"
      SANDBOX="$(mktemp -d "$TMPDIR/blk.XXXXXX")"; export SANDBOX
      host="$SANDBOX/host-kit"; lib="$SCRIPTS/verification-lib.sh"
      make_host_kit "$host" || t_fail "cannot build the host kit"
      eval "$1"; rc=$_t_fail; rm -rf "$SANDBOX"; exit "$rc"' _ "$text" "$fixture" ) > "$w/block.$tag.out" 2>&1
}
snap() { ( cd "$C" && env "${@:2}" bash -c '. scripts/verification-lib.sh; vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$1" 2> "$1.err" ); }
enum() { ( cd "$C" && env "${@:2}" bash -c '. scripts/verification-lib.sh; vf_source_paths "$PWD" "$1"' _ "$1" ); }

L0="$(live_state)"; note "live worktree porcelain digest before: $L0"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul"; expect 'live enumeration rc' 0 "$?"
( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$C" && tar -xf - ); expect 'copy extraction rc' 0 "$?"
cd "$C" || exit 2
git init -q && git add -A && git -c user.name=v -c user.email=v@invalid commit -qm base; expect 'copy committed' 0 "$?"
printf 'tests/.one-*.sh\n' >> .git/info/exclude
for stem in verification; do awk '$0 != "t_run_all"' "tests/test-$stem.sh" > "tests/.one-$stem.sh"; done
base="$(git status --porcelain --ignored)"

echo '== F2 ambient global git configuration decides fixture commits; the identity is unchanged'
mkdir -p "$w/gcfg/hooks"
printf '#!/bin/sh\necho "org pre-commit policy: commit rejected" >&2\nexit 1\n' > "$w/gcfg/hooks/pre-commit"; chmod +x "$w/gcfg/hooks/pre-commit"
printf '[core]\n\thooksPath = %s\n' "$w/gcfg/hooks" > "$w/gcfg/hooks.gitconfig"
printf '[commit]\n\tgpgsign = true\n[gpg]\n\tprogram = %s\n' "$w/gcfg/no-such-gpg" > "$w/gcfg/sign.gitconfig"
enum "$w/e-plain.nul"; expect 'F2 plain enumeration rc' 0 "$?"
for cfg in hooks sign; do
  enum "$w/e-$cfg.nul" GIT_CONFIG_GLOBAL="$w/gcfg/$cfg.gitconfig"; expect "F2 $cfg enumeration rc" 0 "$?"
  cmp -s "$w/e-plain.nul" "$w/e-$cfg.nul"; expect "F2 the kit enumeration is identical under the $cfg configuration" 0 "$?"
done
A="$(snap "$w/s-plain.nul")"; B="$(snap "$w/s-hooks.nul" GIT_CONFIG_GLOBAL="$w/gcfg/hooks.gitconfig")"
expect 'F2 the input identity is identical under the hooks configuration' "$A" "$B"; note "identity $A"
for cfg in hooks sign; do
  out="$(GIT_CONFIG_GLOBAL="$w/gcfg/$cfg.gitconfig" bash -c '. tests/helpers.sh; SANDBOX="$1"; mkdir -p "$SANDBOX"
      spec="$(make_verification_git_dir probe 2>"$SANDBOX/err")"; repo="$(cd "$spec/../../.." && pwd -P)"
      git -C "$repo" rev-parse --verify -q HEAD >/dev/null && echo HEAD=present || echo HEAD=NONE; cat "$SANDBOX/err"' _ "$w/mvgd-$cfg")"
  expect "F2 make_verification_git_dir under $cfg leaves no commit, silently" 1 "$(printf '%s' "$out" | grep -c 'HEAD=NONE')"
  note "$(printf '%s' "$out" | tr '\n' ' ' | cut -c1-200)"
done
run_one verification test_capture_provenance hooks GIT_CONFIG_GLOBAL="$w/gcfg/hooks.gitconfig"; rc=$?
expect 'F2 test_capture_provenance fails under the hooks configuration' 1 "$rc"
note "$(grep -m3 -E 'invalid object name|assert:' "$w/test_capture_provenance.hooks.out" | cut -c1-160 | tr '\n' ' ')"
run_one verification test_capture_provenance plain; expect 'F2 control: test_capture_provenance passes without it' 0 "$?"
expect 'F2: copy unchanged' "$base" "$(git status --porcelain --ignored)"

echo '== F1 the HOME binding of git_config_pinned is not proven by the XDG fixture'
XS='  rm -f "$host/scripts/zz-local.sh"'; XE='rm -f "$host/scripts/zz-xdg.sh"'
mkdir -p "$w/userhome"; : > "$w/userhome/empty-ignore"
printf '[core]\n\texcludesFile = %s\n' "$w/userhome/empty-ignore" > "$w/userhome/.gitconfig"
block "$XS" "$XE" base; expect 'F1 baseline XDG block' 0 "$?"
block "$XS" "$XE" base-userhome HOME="$w/userhome"; expect 'F1 unmutated block with a replacing ~/.gitconfig' 0 "$?"
sub tests/helpers.sh 'GIT_CONFIG_SYSTEM HOME="$home" XDG_CONFIG_HOME' 'GIT_CONFIG_SYSTEM XDG_CONFIG_HOME'; expect 'F1 M-home applied' 0 "$?"
block "$XS" "$XE" mhome; expect 'F1 M-home SURVIVES with the ambient HOME' 0 "$?"
block "$XS" "$XE" mhome-userhome HOME="$w/userhome"; expect 'F1 M-home fails with a replacing ~/.gitconfig' 1 "$?"
expect 'F1 on the precondition' 1 "$(has "$w/block.mhome-userhome.out" 'precondition: the XDG ignore rule does not hide the script from the identity')"
git checkout -q -- tests/helpers.sh
sub tests/helpers.sh ' XDG_CONFIG_HOME="$xdg" GIT_CONFIG_NOSYSTEM=1 "$@"' ' XDG_CONFIG_HOME="$xdg" "$@"'; expect 'F1 M-nosys applied' 0 "$?"
block "$XS" "$XE" mnosys; expect 'F1 M-nosys SURVIVES (no system file to plant here)' 0 "$?"
note "system config origin: $(env -u GIT_CONFIG_SYSTEM git config --system --list --show-origin 2>/dev/null | head -1 | cut -f1)"
git checkout -q -- tests/helpers.sh
expect 'F1: copy unchanged' "$base" "$(git status --porcelain --ignored)"

echo '== F3 E03 is killed by the delta'"'"'s own git-environment fixture'
GS='  git_host "$SANDBOX/foreign" ||'; GE='a declared git repository-local variable was recorded as unset'
block "$GS" "$GE" gbase; expect 'F3 baseline git-environment block' 0 "$?"
sub scripts/verification-lib.sh '  vf_source_paths "$repo" "$tmp/paths" || return 3' '  git -C "$repo" ls-files --cached --others --exclude-standard -z > "$tmp/paths" || return 3'; expect 'F3 E03 applied' 0 "$?"
block "$GS" "$GE" ge03; expect 'F3 E03 fails the block' 1 "$?"
note "$(grep -m3 'assert:' "$w/block.ge03.out" | cut -c1-140 | tr '\n' ' ')"
git checkout -q -- scripts/verification-lib.sh
expect 'F3: copy unchanged' "$base" "$(git status --porcelain --ignored)"

echo '== F4 single-file copies of live-kit files outside copy_kit'
grep -n -E '^[[:space:]]*(mkdir [^;]*; )?cp ' tests/*.sh | grep -E 'KIT_DIR|SCRIPTS' > "$w/f4.txt"
note "$(wc -l < "$w/f4.txt" | tr -d ' ') single cp lines naming a kit alias:"; sed 's/^/  |   /' "$w/f4.txt"
untracked=0
for f in scripts/lib.sh scripts/verification-lib.sh tests/probe-gate-contract.sh models.example.yml scripts/spec-resume.sh; do
  git ls-files --error-unmatch "$f" > /dev/null 2>&1 || untracked=$((untracked+1))
done
expect 'F4 every copied file is a tracked file named by a literal' 0 "$untracked"

echo '== F2 reach: the whole suite once under the rejecting global hook'
start="$(date -u +%H:%M:%SZ)"
GIT_CONFIG_GLOBAL="$w/gcfg/hooks.gitconfig" bash tests/run.sh > "$w/run-hooks.out" 2>&1; rc=$?
note "run.sh under hooks $start - $(date -u +%H:%M:%SZ), rc=$rc"
expect 'F2 reach: the suite fails under the hooks configuration' 1 "$([[ $rc != 0 ]] && echo 1 || echo 0)"
grep -E '^FAIL test_' "$w/run-hooks.out" | sed 's/^/  |   /'
awk '/-- [0-9]+\/[0-9]+ passed/ {split($2, a, "/"); ok += a[1]; all += a[2]} END {printf "  | total %d/%d\n", ok, all}' "$w/run-hooks.out"
cp "$w/run-hooks.out" "$SP/v4-run-hooks.out" 2>/dev/null || true
expect 'reach: copy unchanged' "$base" "$(git status --porcelain --ignored)"

cd "$SP" || exit 2
L1="$(live_state)"; note "live worktree porcelain digest after: $L1"
expect 'live worktree unchanged' "$L0" "$L1"
printf 'verify-4 failures=%s\n' "$fails"
(( fails == 0 ))
