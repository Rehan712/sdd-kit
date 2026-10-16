#!/usr/bin/env bash
# T030o42 dev run 2, 2026-09-27: after the review's wording repairs, in a standalone copy.
# ShellCheck; test_instruction_contracts (the superseded-environment scan reads the edited
# contract and kernel comment); reuse_command_locale_cases; the analyzer on the copy's 003.
# Usage: bash t030o42-dev2.sh <scratchpad> <worktree>. Read-only against the live worktree.
set -uo pipefail
SP="$1"; WT="$2"; R="$SP/t030o42-dev2"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"; rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline; fails=0
verdict() { if [[ "$2" == "$3" ]]; then echo "PASS $1 (want=$2 got=$3)"; else echo "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall | grep -v -F "$s/notes/verification/" | LC_ALL=C sort | shasum -a 256 | cut -d' ' -f1 ); }
L0="$(live_state)"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$C" && tar -xf - )
( cd "$C" && git init -q && git add -A && git -c user.name=d -c user.email=d@invalid commit -qm base && printf 'tests/.one-*.sh\n' >> .git/info/exclude ) || exit 2
S0="$(cd "$C" && git status --porcelain --ignored -uall | shasum -a 256)"
one() { # <suite stem> <function>
  ( cd "$C" && awk '$0 != "t_run_all"' "tests/test-$1.sh" > "tests/.one-$1.sh" && bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || rc=1
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$1" "$2" "$w/$2.out" )
}
( cd "$C" && bash tests/shellcheck.sh ) > "$w/sc.out" 2>&1; verdict 'bash tests/shellcheck.sh' 0 "$?"
for f in gate-contracts:test_instruction_contracts verification:reuse_command_locale_cases; do
  one "${f%%:*}" "${f#*:}"; rc=$?; verdict "${f#*:}" 0 "$rc"
  [[ "$rc" == 0 ]] || grep -E -A2 'assert:' "$w/${f#*:}.out" | head -20 | sed 's/^/  |   /'
done
( cd "$C" && bash scripts/sdd-analyze.sh "$s" ) > "$w/an.out" 2>&1; verdict "analyzer on 003 ($(tail -1 "$w/an.out"))" 0 "$?"
( cd "$C" && rm -f tests/.one-*.sh ); verdict 'copy unchanged' "$S0" "$(cd "$C" && git status --porcelain --ignored -uall | shasum -a 256)"
cd "$SP"; verdict 'live unchanged outside notes/verification/' "$L0" "$(live_state)"
rm -rf "$R"; echo "t030o42-dev2 failures=$fails"; (( fails == 0 ))
