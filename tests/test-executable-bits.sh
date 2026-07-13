#!/usr/bin/env bash
# test-executable-bits.sh — every script the kit tells people to run must be
# runnable. A script tracked 644 fails with exit 126 the moment a skill or a
# doc invokes it directly (`~/.sdd/scripts/spec-task.sh ...`), so the bit is
# part of the contract, not cosmetics. Git tracks the bit — a fresh checkout
# reproduces whatever this test sees.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

test_every_kit_script_is_executable() {
  local f bad=""
  for f in "$KIT_DIR"/scripts/*.sh "$KIT_DIR"/tests/run.sh; do
    [[ -x "$f" ]] || bad="$bad ${f##*/}"
  done
  [[ -z "$bad" ]] || t_fail "tracked without the executable bit:$bad"
}

t_run_all
