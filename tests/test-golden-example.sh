#!/usr/bin/env bash
# test-golden-example.sh — the calibration example the phase skills point at
# (templates/examples/001-api-key-expiry) must itself pass the deterministic
# gate cleanly, or it teaches the wrong shape. This is what keeps the example
# from drifting as templates/checks evolve.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
ANALYZE="$SCRIPTS/sdd-analyze.sh"
EXAMPLE="$KIT_DIR/templates/examples/001-api-key-expiry"

# Copy the example into a sandbox project and swap its kit-install agent paths
# (~/.sdd/agents/…) for sandbox stubs, so the test is hermetic on machines
# with or without a live ~/.sdd.
stage_example() {
  local proj="$SANDBOX/proj"
  local spec_dir="$proj/.specify/specs/001-api-key-expiry"
  mkdir -p "$proj/.specify/specs" "$proj/agents"
  cp -R "$EXAMPLE" "$spec_dir"
  echo "adversarial reviewer stub" > "$proj/agents/opponent.agent.md"
  echo "evidence auditor stub" > "$proj/agents/reality-check.agent.md"
  sed 's|~/.sdd/agents/|agents/|g' "$spec_dir/tasks.md" > "$spec_dir/tasks.md.tmp" \
    && mv "$spec_dir/tasks.md.tmp" "$spec_dir/tasks.md"
  echo "$spec_dir"
}

test_golden_example_passes_sdd_analyze_with_zero_warnings() {
  local spec_dir; spec_dir="$(stage_example)"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "consistent" "zero errors AND zero warnings — the example is the bar"
  assert_contains "$OUT" "every AC is covered by an implementation task"
  assert_contains "$OUT" "opponent gate present, agent file exists"
  assert_contains "$OUT" "reality-check gate present, agent file exists"
}

test_golden_example_demonstrates_the_conventions() {
  local tasks="$EXAMPLE/tasks.md" plan="$EXAMPLE/plan.md"
  # tasks.md shows every field the skills tell models to produce.
  run_rc 0 grep -q '\[hard\]' "$tasks"
  assert_eq 0 "$(grep -c 'NNN-slug' "$tasks")" "no template placeholders"
  local impl_tasks verify_lines
  impl_tasks="$(grep -cE '^- \[ \] \*\*T00[1-7]\*\*' "$tasks")"
  verify_lines="$(grep -c '\*Verify:\*' "$tasks")"
  assert_eq "$impl_tasks" "$verify_lines" "every implementation task carries a *Verify:* line"
  # plan.md shows anchors and pre-decided seams.
  run_rc 0 grep -qi 'pattern anchor' "$plan"
  run_rc 0 grep -q 'Internal seams' "$plan"
}

t_run_all
