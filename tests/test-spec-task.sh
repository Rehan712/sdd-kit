#!/usr/bin/env bash
# test-spec-task.sh — atomic tick+evidence mutations on tasks.md.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
SPEC_TASK="$SCRIPTS/spec-task.sh"

test_list_reports_id_state_stage_subject() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_TASK" list "$spec_dir"
  assert_contains "$OUT" "$(printf 'T001\ttodo\tSetup\tAdd scaffolding')"
  assert_contains "$OUT" "$(printf 'T002\ttodo\tBackend\tImplement the thing endpoint')"
  assert_eq "6" "$(printf '%s\n' "$OUT" | grep -c .)" "one row per task"
}

test_start_marks_in_progress() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_TASK" start "$spec_dir" T002
  assert_contains "$(cat "$spec_dir/tasks.md")" "- [~] **T002**"
  run_rc 0 "$SPEC_TASK" list "$spec_dir"
  assert_contains "$OUT" "$(printf 'T002\tdoing')"
}

test_done_without_evidence_is_refused() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 3 "$SPEC_TASK" "done" "$spec_dir" T002
  assert_contains "$OUT" "REFUSED"
  assert_contains "$(cat "$spec_dir/tasks.md")" "- [ ] **T002**" "box untouched"
}

test_done_with_evidence_is_one_atomic_edit() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_TASK" "done" "$spec_dir" T002 --evidence "bun test → 3 passed"
  local block; block="$("$SPEC_TASK" show "$spec_dir" T002)"
  assert_contains "$block" "- [x] **T002**"
  assert_contains "$block" '*Evidence:* `bun test → 3 passed`'
  assert_contains "$block" "($TODAY)" "evidence is dated"
  # Every mutation bumps the frontmatter updated: field.
  assert_contains "$(head -6 "$spec_dir/tasks.md")" "updated: $TODAY"
}

test_done_rerun_replaces_evidence_not_duplicates() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_TASK" "done" "$spec_dir" T002 --evidence "first run"
  run_rc 0 "$SPEC_TASK" "done" "$spec_dir" T002 --evidence "second run"
  local block; block="$("$SPEC_TASK" show "$spec_dir" T002)"
  assert_eq "1" "$(printf '%s\n' "$block" | grep -c 'Evidence')" "exactly one evidence line"
  assert_contains "$block" "second run"
  assert_not_contains "$block" "first run"
}

test_preformatted_evidence_is_not_double_wrapped() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_TASK" "done" "$spec_dir" T002 --evidence '`cargo test` → ok (2026-01-05)'
  local block; block="$("$SPEC_TASK" show "$spec_dir" T002)"
  assert_contains "$block" '*Evidence:* `cargo test` → ok (2026-01-05)'
  assert_not_contains "$block" "($TODAY)" "caller's date kept, not re-stamped"
}

test_gate_and_ship_tasks_are_exempt_from_evidence() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_TASK" "done" "$spec_dir" T009   # gate (*Agent:* line)
  run_rc 0 "$SPEC_TASK" "done" "$spec_dir" T011   # Ship stage
  local tasks; tasks="$(cat "$spec_dir/tasks.md")"
  assert_contains "$tasks" "- [x] **T009**"
  assert_contains "$tasks" "- [x] **T011**"
  assert_not_contains "$("$SPEC_TASK" show "$spec_dir" T009)" "Evidence" "no evidence line invented"
}

test_undo_unticks_but_keeps_evidence() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_TASK" "done" "$spec_dir" T002 --evidence "bun test → 3 passed"
  run_rc 0 "$SPEC_TASK" undo "$spec_dir" T002
  local block; block="$("$SPEC_TASK" show "$spec_dir" T002)"
  assert_contains "$block" "- [ ] **T002**"
  assert_contains "$block" "bun test → 3 passed" "evidence survives the undo"
}

test_follow_up_ids_never_match_their_parent() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  cat >> "$spec_dir/tasks.md" <<'EOF'

- [ ] **T011r1** — Address review feedback on naming
  - *Acceptance:* reviewer resolves the thread
EOF
  run_rc 0 "$SPEC_TASK" "done" "$spec_dir" T011   # exact match only
  local tasks; tasks="$(cat "$spec_dir/tasks.md")"
  assert_contains "$tasks" "- [x] **T011**"
  assert_contains "$tasks" "- [ ] **T011r1**" "follow-up untouched"
}

test_unknown_task_and_bad_usage() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 1 "$SPEC_TASK" show "$spec_dir" T999
  run_rc 1 "$SPEC_TASK" "done" "$spec_dir" T999 --evidence "x"
  run_rc 2 "$SPEC_TASK" frobnicate "$spec_dir"
  run_rc 2 "$SPEC_TASK" list
  assert_contains "$(cat "$spec_dir/tasks.md")" "updated: 2026-01-01" "no mutation on any failure"
}

t_run_all
