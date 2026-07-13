#!/usr/bin/env bash
# test-sdd-analyze.sh — the deterministic spec/plan/tasks consistency gate.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
ANALYZE="$SCRIPTS/sdd-analyze.sh"

test_clean_fixture_is_consistent() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "consistent" "verdict"
  assert_contains "$OUT" "every AC is covered by an implementation task"
  assert_contains "$OUT" "6 task(s) parsed"
}

test_missing_artifact_is_an_error() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  rm "$spec_dir/plan.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "plan.md missing"
}

test_needs_clarification_blocks() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  echo "- [NEEDS CLARIFICATION: which store — DynamoDB or Postgres?]" >> "$spec_dir/spec.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "unresolved [NEEDS CLARIFICATION] marker"
}

test_uncovered_ac_fails_and_gate_refs_do_not_count() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  # AC-003 exists in the spec and in the GATE tasks' refs only — the gates
  # enumerate every AC by design, so it must still count as uncovered.
  echo "- AC-003 — deletes are idempotent" >> "$spec_dir/spec.md"
  sed 's/- \*Refs:\* AC-001, AC-002/- *Refs:* AC-001, AC-002, AC-003/' \
    "$spec_dir/tasks.md" > "$spec_dir/tasks.md.tmp" && mv "$spec_dir/tasks.md.tmp" "$spec_dir/tasks.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "AC(s) not covered by any implementation task"
  assert_contains "$OUT" "AC-003"
}

test_dangling_ref_fails() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  sed 's/- \*Refs:\* AC-002/- *Refs:* AC-002, AC-099/' \
    "$spec_dir/tasks.md" > "$spec_dir/tasks.md.tmp" && mv "$spec_dir/tasks.md.tmp" "$spec_dir/tasks.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "references id(s) missing from spec.md"
  assert_contains "$OUT" "AC-099"
}

test_duplicate_task_id_fails() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  cat >> "$spec_dir/tasks.md" <<'EOF'

- [ ] **T002** — A second task reusing the id
  - *Acceptance:* never valid
EOF
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "duplicate task id T002"
}

test_ticked_box_without_evidence_warns() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  sed 's/- \[ \] \*\*T002\*\*/- [x] **T002**/' \
    "$spec_dir/tasks.md" > "$spec_dir/tasks.md.tmp" && mv "$spec_dir/tasks.md.tmp" "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "unproven claim" "warning fires"
  assert_contains "$OUT" "warning(s), 0 errors" "warnings never block"
}

test_missing_verify_line_warns() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  grep -v 'node --test test/validate.test.js' "$spec_dir/tasks.md" > "$spec_dir/tasks.md.tmp" \
    && mv "$spec_dir/tasks.md.tmp" "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "task T003 has no *Verify:* line" "warning fires"
  assert_contains "$OUT" "warning(s), 0 errors" "warnings never block (legacy specs)"
  assert_not_contains "$OUT" "task T009" "gate tasks are exempt"
  assert_not_contains "$OUT" "task T011 has no *Verify:*" "Ship tasks are exempt"
}

test_task_without_acceptance_fails() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  grep -v 'invalid-payload test passes' "$spec_dir/tasks.md" > "$spec_dir/tasks.md.tmp" \
    && mv "$spec_dir/tasks.md.tmp" "$spec_dir/tasks.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "task T003 has no *Acceptance:*"
}

test_missing_gate_agent_file_fails() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  rm "$SANDBOX/proj/agents/reality-check.agent.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "reality-check gate agent file not found"
  assert_contains "$OUT" "opponent gate present, agent file exists" "other gate unaffected"
}

test_gate_agent_placeholder_fails() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  sed 's|agents/reality-check.agent.md|<resolved by /sdd:tasks>|' \
    "$spec_dir/tasks.md" > "$spec_dir/tasks.md.tmp" && mv "$spec_dir/tasks.md.tmp" "$spec_dir/tasks.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "still a template placeholder"
}

test_external_marker_must_be_mirrored_in_status() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  echo "- [EXTERNAL: payments-team/billing-api — needs the v2 refund endpoint — needed-by 2026-08-01]" >> "$spec_dir/spec.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "not mirrored in STATUS.md" "warning fires"
  # Mirror it; the warning must clear.
  echo "- payments-team/billing-api refund endpoint (needed-by 2026-08-01)" >> "$spec_dir/STATUS.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_not_contains "$OUT" "not mirrored"
}

# --- umbrella specs -------------------------------------------------------------

test_umbrella_untagged_tasks_fail() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  make_umbrella "$spec_dir" "[alpha, beta]"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "missing a [repo:<name>] tag"
  assert_contains "$OUT" "T001" "setup tasks need tags too"
  assert_not_contains "$OUT" "T009" "gate tasks are exempt"
}

test_umbrella_tagged_tasks_pass() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  make_umbrella "$spec_dir" "[alpha, beta]"
  tag_task "$spec_dir/tasks.md" T001 alpha
  tag_task "$spec_dir/tasks.md" T002 alpha
  tag_task "$spec_dir/tasks.md" T003 beta
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "every implementation task carries a declared [repo:] tag"
}

test_umbrella_undeclared_repo_tag_fails() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  make_umbrella "$spec_dir" "[alpha, beta]"
  tag_task "$spec_dir/tasks.md" T001 alpha
  tag_task "$spec_dir/tasks.md" T002 alpha
  tag_task "$spec_dir/tasks.md" T003 gamma
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "tagged with undeclared repo"
  assert_contains "$OUT" "T003[repo:gamma]"
}

test_umbrella_declared_repo_with_no_tasks_warns() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  make_umbrella "$spec_dir" "[alpha, beta, gamma]"
  tag_task "$spec_dir/tasks.md" T001 alpha
  tag_task "$spec_dir/tasks.md" T002 alpha
  tag_task "$spec_dir/tasks.md" T003 beta
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "declared repo 'gamma' has no tasks"
}

test_stray_repo_tags_without_umbrella_warn() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  tag_task "$spec_dir/tasks.md" T002 alpha
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "spec.md declares no repos:" "tags without umbrella are flagged"
}

t_run_all
