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
  cat > "$proj/.specify/stack.yml" <<'EOF'
stacks: [javascript, aws]
gate_checks:
  - 'bun test'
  - 'bun run typecheck'
checkpoints:
  Backend:
    - 'bun test'
reuse_checks: []
verification_tools:
  - 'bun'
verification_inputs: []
EOF
  echo "adversarial reviewer stub" > "$proj/agents/opponent.agent.md"
  echo "evidence auditor stub" > "$proj/agents/reality-check.agent.md"
  sed 's|~/.sdd/agents/|agents/|g' "$spec_dir/tasks.md" > "$spec_dir/tasks.md.tmp" \
    && mv "$spec_dir/tasks.md.tmp" "$spec_dir/tasks.md"
  echo "$spec_dir"
}

test_golden_example_passes_sdd_analyze_with_zero_warnings() {
  local spec_dir; spec_dir="$(stage_example)"
  run_rc 0 "$ANALYZE" "$spec_dir" --phase tasks
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

test_verification_golden() {
  local spec_dir project catalog value count=0 definitions=0 bindings=0
  local task_tests=0 task_assertions=0 record=() actual_checks
  spec_dir="$(stage_example)"
  project="$spec_dir/../../.."
  catalog="$SANDBOX/golden-bindings.nul"
  # AC-005: validate the opted-in example, including its real task bindings,
  # without fabricating source declarations for a fictional application.
  assert_eq 1 "$(sed -n 's/^verification_contract: //p' "$spec_dir/spec.md")"
  run_rc 0 "$ANALYZE" "$spec_dir" --phase tasks
  assert_contains "$OUT" 'consistent' 'AC-005: golden task handoff has zero warnings'
  run_rc 0 bash -c '. "$1"; vf_bindings "$2" tasks "" "$3"' _ \
    "$SCRIPTS/verification-lib.sh" "$spec_dir" "$catalog"
  while IFS= read -r -d '' value; do
    record+=("$value")
    count=$((count+1))
    if [[ "${#record[@]}" -eq 12 ]]; then
      case "${record[0]}" in
        definition) definitions=$((definitions+1)) ;;
        binding) bindings=$((bindings+1)) ;;
        task)
          case "${record[5]}" in
            test) task_tests=$((task_tests+1)) ;;
            assertion) task_assertions=$((task_assertions+1)) ;;
          esac
          ;;
      esac
      record=()
    fi
  done < "$catalog"
  assert_eq 0 "$((count % 12))" 'AC-005: complete typed binding records'
  [[ "$definitions" -ge 6 ]] || t_fail 'AC-005: concrete FM/INV definitions missing'
  [[ "$bindings" -ge 6 ]] || t_fail 'AC-005: definitions must have task-family bindings'
  assert_eq 6 "$task_tests" 'AC-005: six tasks own executable test families'
  assert_eq 1 "$task_assertions" 'AC-005: docs uses a declared behavioral assertion'
  assert_contains "$(cat "$spec_dir/plan.md")" 'Exclusions: response schema / concurrency/ordering'
  [[ ! -d "$project/test" ]] || t_fail 'AC-005: authoring fixture must not fabricate test proof'
  actual_checks="$(cat "$project/.specify/stack.yml")"
  assert_contains "$actual_checks" "  - 'bun test'"
  assert_contains "$actual_checks" "  - 'bun run typecheck'"
  # Missing task ownership must be detected rather than accepted as a golden
  # example merely because its plan mentions the failure ID.
  sed 's/AC-002, FM-003, INV-002/AC-002/' "$spec_dir/tasks.md" > "$spec_dir/tasks.md.tmp" \
    && mv "$spec_dir/tasks.md.tmp" "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir" --phase tasks
  assert_contains "$OUT" 'FM-003 has no non-gate task owner' 'AC-005: missing ownership warns'
  assert_contains "$OUT" 'INV-002 has no non-gate task owner' 'AC-005: missing invariant binding warns'
}

t_run_all
