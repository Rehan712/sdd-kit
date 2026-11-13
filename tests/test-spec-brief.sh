#!/usr/bin/env bash
# test-spec-brief.sh — the implementation brief is copied from the artifacts,
# not typed: the task block, the requirements its Refs name, and the plan
# sections and FM/INV rows they name.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

BRIEF="$SCRIPTS/spec-brief.sh"
EXAMPLE="$KIT_DIR/templates/examples/001-api-key-expiry"

example_spec() { cp -R "$EXAMPLE" "$SANDBOX/spec"; printf '%s' "$SANDBOX/spec"; }

test_brief_carries_the_task_its_requirements_and_named_plan_sections() {
  local spec; spec="$(example_spec)"
  run_rc 0 "$BRIEF" "$spec" T003 --stdout
  assert_contains "$OUT" 'Mode: implementation'
  assert_contains "$OUT" 'Source revision: '
  assert_contains "$OUT" '**T003** [hard] — Reject expired keys in auth middleware'
  assert_contains "$OUT" '*Verify:* `bun test --filter keys.expired`'
  assert_contains "$OUT" '**REQ-001:** A leaked or forgotten API key'
  assert_contains "$OUT" 'stop working 90 days after issue.' 'a requirement lost its continuation line'
  assert_contains "$OUT" '**AC-002:**'
  assert_contains "$OUT" '## 2. Architecture'
  assert_contains "$OUT" '## 7. Risks, failure modes and verification'
  assert_contains "$OUT" '| INV-001 |'
  assert_not_contains "$OUT" '**T004**' 'the brief leaked a sibling task'
  assert_not_contains "$OUT" '**REQ-002:**' 'the brief carries a requirement the task does not reference'
  assert_not_contains "$OUT" '## 3. Data model' 'the brief carries a plan section the task does not reference'
}

# Refs that name an FM/INV row but not the section it lives in still get the row.
test_brief_pulls_fm_rows_from_sections_the_task_did_not_name() {
  local spec; spec="$(example_spec)"
  sed 's/^\(  - \*Refs:\* REQ-002, AC-001, FM-001\), plan §2, §7$/\1, plan §2/' "$spec/tasks.md" > "$SANDBOX/t" \
    && mv "$SANDBOX/t" "$spec/tasks.md"
  run_rc 0 "$BRIEF" "$spec" T002 --stdout
  assert_not_contains "$OUT" '## 7. Risks' 'fixture: §7 is still referenced'
  assert_contains "$OUT" '### Failure-mode and invariant rows'
  assert_contains "$OUT" '| FM-001 |'
  assert_not_contains "$OUT" '| FM-002 |' 'the brief carries a row the task does not reference'
}

# The file is spec bookkeeping under notes/verification/, and its revision
# moves when the task block does.
test_brief_is_written_under_verification_and_revision_tracks_the_task() {
  local spec first; spec="$(example_spec)"
  run_rc 0 "$BRIEF" "$spec" T001
  assert_eq "$spec/notes/verification/briefs/T001.md" "$OUT"
  [[ -s "$OUT" ]] || t_fail 'the brief file is empty'
  first="$(grep '^Source revision:' "$OUT")"
  sed 's/90-day constant/91-day constant/' "$spec/tasks.md" > "$SANDBOX/t" && mv "$SANDBOX/t" "$spec/tasks.md"
  run_rc 0 "$BRIEF" "$spec" T001
  [[ "$first" != "$(grep '^Source revision:' "$OUT")" ]] || t_fail 'a changed task kept its source revision'
}

test_brief_usage_and_unknown_task() {
  local spec; spec="$(example_spec)"
  run_rc 1 "$BRIEF" "$spec" T999
  assert_contains "$OUT" 'task T999 not found'
  run_rc 2 "$BRIEF" "$spec"
  run_rc 2 "$BRIEF" "$spec" not-a-task
  run_rc 1 "$BRIEF" "$SANDBOX/missing" T001
}

# Writing a brief never stales a capture: acceptance still takes the return.
test_brief_does_not_change_the_input_manifest() {
  local spec repo
  spec="$(make_verification_git_dir briefmanifest)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary --return
  mkdir -p "$spec/notes/verification/returns"
  printf '%s\n' "$OUT" > "$spec/notes/verification/returns/T001.txt"
  run_rc 0 "$BRIEF" "$spec" T001
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$spec/notes/verification/returns/T001.txt"
}

# A project with its own routing table: the brief names the skill and agent
# files for the task's *Files:*, so the implementer reads them on any CLI.
test_brief_lists_the_project_skills_for_the_task_files() {
  local proj="$SANDBOX/proj" spec
  mkdir -p "$proj/.specify/specs" "$proj/.claude/skills/api-implementer" "$proj/.claude/agents"
  cp -R "$EXAMPLE" "$proj/.specify/specs/001-api-key-expiry"
  spec="$(cd "$proj/.specify/specs/001-api-key-expiry" && pwd)"; proj="$(cd "$proj" && pwd)"
  printf 'stacks: []\n' > "$proj/.specify/stack.yml"
  : > "$proj/.claude/skills/api-implementer/SKILL.md"
  printf -- '---\nname: docs-writer\nmodel: sonnet\n---\n' > "$proj/.claude/agents/docs-writer.md"
  printf '| Signal | Implement |\n|---|---|\n| `src/middleware/**` | `api-implementer`, `aws-core:aws-iam` |\n| `docs/**` | `docs-writer` |\n' \
    > "$proj/.specify/routing.md"

  run_rc 0 "$BRIEF" "$spec" T003 --stdout
  assert_contains "$OUT" 'Project routing — this project names its own skills and agents'
  assert_contains "$OUT" "- skill \`api-implementer\`: $proj/.claude/skills/api-implementer/SKILL.md"
  assert_contains "$OUT" '- plugin skill `aws-core:aws-iam`: load it with the Skill tool'
  assert_not_contains "$OUT" 'docs-writer' 'the brief lists a row the task files do not match'
  assert_contains "$OUT" '**T003** [hard] — Reject expired keys in auth middleware' 'the task block is gone'
  run_rc 0 "$BRIEF" "$spec" T007 --stdout
  assert_contains "$OUT" "- agent \`docs-writer\` (the writer this task routes to): $proj/.claude/agents/docs-writer.md"
  run_rc 0 "$BRIEF" "$spec" T001 --stdout
  assert_not_contains "$OUT" 'Project routing' 'a task no row covers got a routing header'

  # A table that cannot be trusted stops the brief instead of dropping the skill.
  printf '| Signal | Implement |\n|---|---|\n| `src/**` | `gone-skill` |\n' > "$proj/.specify/routing.md"
  run_rc 1 "$BRIEF" "$spec" T003 --stdout
  assert_contains "$OUT" 'invalid project routing table'
}

t_run_all
