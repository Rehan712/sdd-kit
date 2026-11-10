#!/usr/bin/env bash
# test-executable-bits.sh — every script the kit tells people to run must be
# runnable. A script tracked 644 fails with exit 126 the moment a skill or a
# doc invokes it directly (`~/.sdd/scripts/spec-task.sh ...`), so the bit is
# part of the contract, not cosmetics. Git tracks the bit — a fresh checkout
# reproduces whatever this test sees.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

# AC-011: every script that can be invoked directly, including the new limit
# classifier, readiness seam, and resume tools, must retain its executable bit.
# The scripts are the enumerated ones (kit_files), never a glob that would also
# judge an ignored local file: this suite is reuse-checked (O-015 review).
test_AC_011_every_kit_script_is_executable() {
  local f bad="" list="$SANDBOX/kit-scripts"
  { kit_files scripts '*.sh' && kit_files tests 'run.sh'; } > "$list" \
    || t_fail 'AC-011: cannot enumerate the kit scripts'
  [[ -s "$list" ]] || t_fail 'AC-011: no kit script was enumerated'
  while IFS= read -r -d '' f; do
    [[ -x "$KIT_DIR/$f" ]] || bad="$bad ${f##*/}"
  done < "$list"
  [[ -z "$bad" ]] || t_fail "tracked without the executable bit:$bad"
}

# O-015 sibling: an ignored, non-executable script in a developer's kit is not
# a kit script, and must not decide the check above.
test_AC_011_ignored_local_scripts_do_not_decide_the_executable_check() {
  local host="$SANDBOX/host-kit"
  make_host_kit "$host" || t_fail 'AC-011: cannot build the host kit'
  printf 'scripts/zz-local.sh\n' >> "$host/.git/info/exclude"
  printf 'echo local\n' > "$host/scripts/zz-local.sh"; chmod 644 "$host/scripts/zz-local.sh"
  on_host_kit "$host" test_AC_011_every_kit_script_is_executable
}

t_run_all
