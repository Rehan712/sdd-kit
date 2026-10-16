#!/usr/bin/env bash
# Invoker verification of the second review pair's claims (pass D first),
# 2026-09-24, BEFORE any repair. Usage: bash t030o41-review2-verify.sh <scratchpad> <worktree>
# Read-only against the live worktree: its manifest enumeration is tarred into
# a standalone git copy and every probe runs there. Exit codes are captured
# from the command itself, never a pipe.
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/v2"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
expect() { if [[ "$2" == "$3" ]]; then printf 'PASS %s (want=%s got=%s)\n' "$1" "$2" "$3"; else printf 'FAIL %s (want=%s got=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi; }
note() { printf '  | %s\n' "$*"; }
has() { grep -c -F -- "$2" "$1" | awk '{print ($1 > 0)}'; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1 ); }
run_one() { # <stem> <function> <tag>
  ( cd "$C" && bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$1" "$2" "$w/$2.$3.out" )
}
snap() { ( cd "$C" && HUB_DIR="$PWD" && . scripts/lib.sh && . scripts/verification-lib.sh && vf_snapshot "$s" "$PWD" "$PWD" "$1" 2> "$1.err" ); }
clean() { ( cd "$C" && git checkout -q -- . && git clean -fdq ); expect "$1: copy clean" '' "$(cd "$C" && git status --porcelain --ignored | grep -v -E '^!! tests/\.one-' || true)"; }

L0="$(live_state)"; note "live worktree porcelain digest before: $L0"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul"; expect 'live enumeration rc' 0 "$?"
( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$C" && tar -xf - ); expect 'copy extraction rc' 0 "$?"
cd "$C" || exit 2
git init -q && git add -A && git -c user.name=v -c user.email=v@invalid commit -qm base; expect 'copy committed' 0 "$?"
printf 'tests/.one-*.sh\n' >> .git/info/exclude
for stem in gate-contracts sdd-analyze executable-bits; do awk '$0 != "t_run_all"' "tests/test-$stem.sh" > "tests/.one-$stem.sh"; done
# pre-repair tests/run.sh, from the repair's own diff
awk '/^--- a\//{on=($0 == "--- a/tests/run.sh")} on' "$WT/$s/notes/verification/reports/t030o41-session2.diff" > "$w/run.patch"
cp tests/run.sh "$w/run-pre.sh" && patch -s -R "$w/run-pre.sh" < "$w/run.patch"; expect 'pre-repair run.sh reconstructed' 0 "$?"
expect 'pre-repair run.sh globs its suites' 1 "$(has "$w/run-pre.sh" 'for f in "$TESTS_DIR"/test-*.sh; do')"
A="$(snap "$w/a.nul")"; expect 'baseline snapshot rc' 0 "$?"; note "baseline identity $A"

echo '== D1 the suite-start XDG_* reset changes what git ignores inside a suite'
mkdir -p "$w/home1" "$w/xdg/git"; printf 'zz-local.sh\n' > "$w/xdg/git/ignore"
A1="$(HOME="$w/home1" XDG_CONFIG_HOME="$w/xdg" snap "$w/d1a.nul")"
printf 'echo local\n' > scripts/zz-local.sh; chmod 644 scripts/zz-local.sh
expect 'D1 the planted script is ignored under that environment' '!! scripts/zz-local.sh' "$(HOME="$w/home1" XDG_CONFIG_HOME="$w/xdg" git status --porcelain --ignored scripts | grep -v '^!! tests' )"
B1="$(HOME="$w/home1" XDG_CONFIG_HOME="$w/xdg" snap "$w/d1b.nul")"
expect 'D1 identity unchanged by the planted ignored script' "$A1" "$B1"
HOME="$w/home1" XDG_CONFIG_HOME="$w/xdg" bash tests/run.sh executable > "$w/d1.out" 2>&1; rc=$?
expect 'D1 bash tests/run.sh executable fails' 1 "$rc"
expect 'D1 on the ignored script' 1 "$(has "$w/d1.out" 'tracked without the executable bit: zz-local.sh')"
rm -f scripts/zz-local.sh
HOME="$w/home1" XDG_CONFIG_HOME="$w/xdg" bash tests/run.sh executable > "$w/d1c.out" 2>&1; expect 'D1 control: without the file it passes' 0 "$?"
clean D1

echo '== D3 a leftover cp -R of the live scripts/ feeds the README workflow snapshot'
run_one gate-contracts test_instruction_contracts base; expect 'D3 baseline test_instruction_contracts' 0 "$?"
printf 'scripts/zz-dir\n' >> .git/info/exclude; ln -s "$C/templates" scripts/zz-dir
B3="$(snap "$w/d3.nul")"; expect 'D3 identity unchanged by the ignored absolute directory link' "$A" "$B3"
run_one gate-contracts test_instruction_contracts d3; expect 'D3 test_instruction_contracts fails' 1 "$?"
expect 'D3 through the copied link' 1 "$(has "$w/test_instruction_contracts.d3.out" 'directory symlink requires explicit target files: scripts/zz-dir')"
rm -f scripts/zz-dir; sed '/^scripts\/zz-dir$/d' .git/info/exclude > "$w/ex" && cat "$w/ex" > .git/info/exclude
clean D3

echo '== D4 a case-variant spelling of the kit path'
V="${C/scratchpad/SCRATCHPAD}"
expect 'D4 the spelling differs' 1 "$([[ "$V" != "$C" ]] && echo 1 || echo 0)"
expect 'D4 and names the same directory' 1 "$([[ "$V" -ef "$C" ]] && echo 1 || echo 0)"
bash "$V/tests/run.sh" lib > "$w/d4.out" 2>&1; expect 'D4 post-repair run.sh through that spelling fails' 1 "$?"
expect 'D4 on enumeration' 1 "$(has "$w/d4.out" 'cannot enumerate the kit')"
cp "$w/run-pre.sh" tests/run-pre.sh
bash "$V/tests/run-pre.sh" lib > "$w/d4pre.out" 2>&1; expect 'D4 pre-repair run.sh through that spelling passes' 0 "$?"
note "$(grep -E -- '-- [0-9]+/[0-9]+ passed' "$w/d4pre.out" | tr '\n' ' ')"
rm -f tests/run-pre.sh
( cd "$V" && bash tests/shellcheck.sh ) > "$w/d4sc.out" 2>&1; expect 'D4 shellcheck.sh from a case-variant cwd fails' 2 "$?"
( cd "$C" && bash tests/shellcheck.sh ) > "$w/d4sc2.out" 2>&1; expect 'D4 control: shellcheck.sh from the on-disk spelling passes' 0 "$?"
clean D4

echo '== D5 a kit that is not a Git worktree'
mkdir -p "$w/nogit"; git archive HEAD | tar -x -C "$w/nogit"
bash "$w/nogit/tests/run.sh" lib > "$w/d5.out" 2>&1; expect 'D5 post-repair run.sh in an export fails' 1 "$?"
cp "$w/run-pre.sh" "$w/nogit/tests/run-pre.sh"
bash "$w/nogit/tests/run-pre.sh" lib > "$w/d5pre.out" 2>&1; expect 'D5 pre-repair run.sh in an export passes' 0 "$?"
bash "$w/nogit/tests/shellcheck.sh" > "$w/d5sc.out" 2>&1; expect 'D5 shellcheck.sh in an export exits 2' 2 "$?"
rm -rf "$w/nogit"

echo '== D7 host-kit fixtures assume a template-made .git/info'
mkdir -p "$w/home7" "$w/empty-tpl"
printf '[init]\n\ttemplateDir = %s\n' "$w/empty-tpl" > "$w/home7/.gitconfig"
B7="$(HOME="$w/home7" snap "$w/d7.nul")"; note "identity under that HOME: $B7 (baseline $A)"
HOME="$w/home7" bash tests/run.sh executable > "$w/d7.out" 2>&1; expect 'D7 bash tests/run.sh executable fails' 1 "$?"
expect 'D7 on the missing info/exclude' 1 "$(has "$w/d7.out" 'info/exclude: No such file or directory')"
clean D7

echo '== D2 the leftover-spec fixture copies from a glob of the live kit'
mkdir -p .specify/specs/002-zz-scratch
B2="$(snap "$w/d2.nul")"; expect 'D2 identity unchanged by an empty leftover directory' "$A" "$B2"
run_one sdd-analyze test_leftover_spec_directories_do_not_decide_the_shipped_loop d2; rc=$?
note "D2 fixture rc=$rc"
expect 'D2 its planting cp failed silently' 1 "$(has "$w/test_leftover_spec_directories_do_not_decide_the_shipped_loop.d2.out" 'No such file or directory')"
rmdir .specify/specs/002-zz-scratch
clean D2

echo '== D6 trap scope under set -u (minimal, /bin/bash)'
cat > "$w/d6.sh" <<'EOF'
set -u
f() ( local tmp=inner; trap 'echo "trap sees $tmp"' EXIT; echo "$undefined_name" )
tmp=CALLER
out="$(f 2>/dev/null)"; echo "substitution: $out"
f 2>/dev/null || true
EOF
/bin/bash "$w/d6.sh" > "$w/d6.out" 2>&1; note "$(tr '\n' ';' < "$w/d6.out")"
expect 'D6 the EXIT trap read the caller variable on an unbound-variable error' 1 "$(has "$w/d6.out" 'trap sees CALLER')"
note "bash under test: $(/bin/bash --version | head -1)"

cd "$SP" || exit 2
L1="$(live_state)"; note "live worktree porcelain digest after: $L1"
expect 'live worktree unchanged' "$L0" "$L1"
printf 'verify failures=%s\n' "$fails"
(( fails == 0 ))
