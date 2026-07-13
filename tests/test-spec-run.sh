#!/usr/bin/env bash
# test-spec-run.sh — evidence as captured runs: execute, record, then tick.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
SPEC_RUN="$SCRIPTS/spec-run.sh"

test_passing_command_records_and_ticks() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_RUN" "$spec_dir" T002 -- echo "3 passed"
  local block; block="$("$SCRIPTS/spec-task.sh" show "$spec_dir" T002)"
  assert_contains "$block" "- [x] **T002**"
  assert_contains "$block" "echo 3 passed → 3 passed (see notes/evidence.md)"
  local ev; ev="$(cat "$spec_dir/notes/evidence.md")"
  assert_contains "$ev" "## T002 — "
  assert_contains "$ev" "**Exit:** 0"
  assert_contains "$ev" "3 passed"
}

test_failing_command_keeps_box_unticked_but_records() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 7 "$SPEC_RUN" "$spec_dir" T002 -- sh -c 'echo boom; exit 7'
  assert_contains "$OUT" "FAILED"
  assert_contains "$(cat "$spec_dir/tasks.md")" "- [ ] **T002**" "box untouched"
  local ev; ev="$(cat "$spec_dir/notes/evidence.md")"
  assert_contains "$ev" "**Exit:** 7" "failed run still recorded"
  assert_contains "$ev" "boom"
}

test_no_tick_captures_only() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_RUN" "$spec_dir" T002 --no-tick -- echo ok
  assert_contains "$(cat "$spec_dir/tasks.md")" "- [ ] **T002**"
  assert_contains "$(cat "$spec_dir/notes/evidence.md")" "**Exit:** 0"
}

test_key_flag_picks_the_evidence_line() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_RUN" "$spec_dir" T002 --key 'passed' -- \
    sh -c 'printf "collecting\n14 passed\ncleanup done\n"'
  assert_contains "$("$SCRIPTS/spec-task.sh" show "$spec_dir" T002)" "→ 14 passed" \
    "--key match beats the last line"
}

test_usage_errors() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 2 "$SPEC_RUN" "$spec_dir" T002            # no `--`
  run_rc 2 "$SPEC_RUN" "$spec_dir" T002 --         # empty command
  run_rc 1 "$SPEC_RUN" "$spec_dir" T999 -- echo hi # unknown task
  assert_contains "$(cat "$spec_dir/tasks.md")" "updated: 2026-01-01" "no mutation on failure"
}

t_run_all
