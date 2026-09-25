#!/usr/bin/env bash
# Invoker reproduction of review-3 findings R3-2 and R3-3 in the dev8 copy (not the worktree).
set -uo pipefail
C="$1"; w="$2"; export TMPDIR="$w/tmp"; mkdir -p "$TMPDIR"
fails=0
expect() { if [[ "$2" == "$3" ]]; then printf 'PASS %s (want=%s got=%s)\n' "$1" "$2" "$3"; else printf 'FAIL %s (want=%s got=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi; }
run_one() { # <stem> <fn> <tag> [env...]
  local stem="$1" fn="$2" tag="$3"; shift 3
  ( cd "$C" && env "$@" bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$stem" "$fn" "$w/$fn.$tag.out" )
}
cd "$C" || exit 2
base="$(git status --porcelain --ignored)"
echo '== R3-2 the pre-delta copy lines survive their new fixtures'
perl -0pi -e 's/  copy_kit "\$KIT_DIR" "\$SANDBOX\/example-copy" "\$rel" && mv "\$SANDBOX\/example-copy\/\$rel" "\$spec_dir" \\\n    \|\| t_fail .cannot copy the example as the input identity enumerates it./  cp -R "\$EXAMPLE" "\$spec_dir"/' tests/test-golden-example.sh
perl -0pi -e 's/  copy_kit "\$KIT_DIR" "\$DISPATCH_KIT" scripts \|\| t_fail .AC-003: cannot stage the kit scripts for the dispatch fixture./  cp -R "\$SCRIPTS" "\$DISPATCH_KIT\/scripts"/' tests/test-usage-limits.sh
git diff --stat | tail -1
expect 'R3-2 golden pre-delta line restored' 1 "$(grep -c -F 'cp -R "$EXAMPLE" "$spec_dir"' tests/test-golden-example.sh)"
expect 'R3-2 dispatch pre-delta line restored' 1 "$(grep -c -F 'cp -R "$SCRIPTS" "$DISPATCH_KIT/scripts"' tests/test-usage-limits.sh)"
for stem in golden-example usage-limits; do awk '$0 != "t_run_all"' "tests/test-$stem.sh" > "tests/.one-$stem.sh"; done
run_one golden-example test_stage_example_copies_only_enumerated_files r32; expect 'R3-2 golden fixture passes over the pre-delta line (survives)' 0 "$?"
run_one usage-limits test_AC_003_dispatch_fixture_copies_only_enumerated_scripts r32; expect 'R3-2 dispatch fixture passes over the pre-delta line (survives)' 0 "$?"
git checkout -q -- tests/test-golden-example.sh tests/test-usage-limits.sh
for stem in golden-example usage-limits; do awk '$0 != "t_run_all"' "tests/test-$stem.sh" > "tests/.one-$stem.sh"; done
echo '== R3-3 GIT_CONFIG_GLOBAL with a core.excludesFile fails the XDG fixture'
mkdir -p "$w/gcg"; : > "$w/gcg/empty-ignore"; printf '[core]\n\texcludesFile = %s\n' "$w/gcg/empty-ignore" > "$w/gcg/gitconfig"
bash -c '. scripts/verification-lib.sh; vf_source_paths "$PWD" "$1"' _ "$w/enum-a.nul"
GIT_CONFIG_GLOBAL="$w/gcg/gitconfig" bash -c '. scripts/verification-lib.sh; vf_source_paths "$PWD" "$1"' _ "$w/enum-b.nul"
cmp -s "$w/enum-a.nul" "$w/enum-b.nul"; expect 'R3-3 the kit enumeration is identical under that GIT_CONFIG_GLOBAL' 0 "$?"
run_one verification reuse_command_input_cases r33 GIT_CONFIG_GLOBAL="$w/gcg/gitconfig"; expect 'R3-3 reuse_command_input_cases fails under it' 1 "$?"
grep -c 'precondition: the XDG ignore rule' "$w/reuse_command_input_cases.r33.out" | awk '{print "  | precondition assertion lines: " $1}'
run_one verification reuse_command_input_cases r33ctl; expect 'R3-3 control: passes without it' 0 "$?"
expect 'copy status unchanged' "$base" "$(git status --porcelain --ignored)"
printf 'verify-r3 failures=%s\n' "$fails"
(( fails == 0 ))
