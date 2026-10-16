#!/usr/bin/env bash
# Invoker verification of pass C's new members (F3 CDPATH/BASH_ENV, F4 git's
# repo-local environment), 2026-09-24, BEFORE any repair.
# Usage: bash t030o41-review2-verify-c.sh <scratchpad> <worktree>
# Read-only against the live worktree; every probe runs in a standalone copy.
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/v2c"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
expect() { if [[ "$2" == "$3" ]]; then printf 'PASS %s (want=%s got=%s)\n' "$1" "$2" "$3"; else printf 'FAIL %s (want=%s got=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi; }
note() { printf '  | %s\n' "$*"; }
has() { grep -c -F -- "$2" "$1" | awk '{print ($1 > 0)}'; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1 ); }
run_one() { # <stem> <function> <tag> [env assignments...]
  local stem="$1" fn="$2" tag="$3"; shift 3
  ( cd "$C" && env "$@" bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$stem" "$fn" "$w/$fn.$tag.out" )
}
snap() { ( cd "$C" && HUB_DIR="$PWD" && . scripts/lib.sh && . scripts/verification-lib.sh && vf_snapshot "$s" "$PWD" "$PWD" "$1" 2> "$1.err" ); }

L0="$(live_state)"; note "live worktree porcelain digest before: $L0"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul"; expect 'live enumeration rc' 0 "$?"
( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$C" && tar -xf - ); expect 'copy extraction rc' 0 "$?"
cd "$C" || exit 2
git init -q && git add -A && git -c user.name=v -c user.email=v@invalid commit -qm base; expect 'copy committed' 0 "$?"
printf 'tests/.one-*.sh\n' >> .git/info/exclude
awk '$0 != "t_run_all"' tests/test-gate-contracts.sh > tests/.one-gate-contracts.sh
A="$(snap "$w/a.nul")"; expect 'baseline snapshot rc' 0 "$?"

echo '== F3 an exported CDPATH, or a BASH_ENV file, decides the reuse-checked commands'
bash tests/shellcheck.sh > "$w/f3a.out" 2>&1; expect 'F3 baseline shellcheck.sh' 0 "$?"
B="$(CDPATH=. snap "$w/f3.nul")"; expect 'F3 identity unchanged under CDPATH=.' "$A" "$B"
CDPATH=. bash tests/shellcheck.sh > "$w/f3b.out" 2>&1; expect 'F3 CDPATH=. bash tests/shellcheck.sh fails' 2 "$?"
expect 'F3 on enumeration' 1 "$(has "$w/f3b.out" 'cannot enumerate the kit')"
CDPATH=. shellcheck -S warning -x scripts/*.sh tests/*.sh > "$w/f3c.out" 2>&1; expect 'F3 the pre-repair ShellCheck command under CDPATH=. passes (regression)' 0 "$?"
CDPATH=. bash tests/run.sh zz-none > "$w/f3d.out" 2>&1; note "CDPATH=. bash tests/run.sh zz-none rc=$? (pre-existing TESTS_DIR derivation)"
printf 'CDPATH=.\n' > "$w/bashenv.sh"
env -u CDPATH BASH_ENV="$w/bashenv.sh" bash tests/shellcheck.sh > "$w/f3e.out" 2>&1; expect 'F3 a BASH_ENV file setting an unexported CDPATH fails shellcheck.sh' 2 "$?"
printf 'git() { echo "not git" >&2; return 1; }\n' > "$w/bashenv-fn.sh"
env BASH_ENV="$w/bashenv-fn.sh" bash -o pipefail -c 'bash tests/shellcheck.sh' > "$w/f3f.out" 2>&1; rc=$?
note "a BASH_ENV file defining a git function, under the capture harness's own bash -o pipefail -c: rc=$rc"
expect 'F3 harness class: BASH_ENV code runs in every captured command' 1 "$([[ "$rc" != 0 ]] && echo 1 || echo 0)"

echo '== F4 fixtures inherit git repo-local environment and write to a foreign index'
cp .git/index "$w/idx-scratch"; before="$(shasum -a 256 < "$w/idx-scratch")"
run_one gate-contracts test_instruction_contracts f4 GIT_INDEX_FILE="$w/idx-scratch"; rc=$?
expect 'F4 test_instruction_contracts still passes' 0 "$rc"
after="$(shasum -a 256 < "$w/idx-scratch")"
expect 'F4 the foreign index was rewritten by the suite' 1 "$([[ "$before" != "$after" ]] && echo 1 || echo 0)"
note "foreign index now lists fixture paths: $(GIT_INDEX_FILE="$w/idx-scratch" git ls-files 2>/dev/null | grep -c 'verification-fixture')"
expect 'F4 the copy own index untouched' '' "$(git status --porcelain | grep -v '^?? tests/\.one-' || true)"

cd "$SP" || exit 2
L1="$(live_state)"; note "live worktree porcelain digest after: $L1"
expect 'live worktree unchanged' "$L0" "$L1"
printf 'verify-c failures=%s\n' "$fails"
(( fails == 0 ))
