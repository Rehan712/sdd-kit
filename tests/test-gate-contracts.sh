#!/usr/bin/env bash
# Static schema/instruction assertions; runtime contracts add executable cases
# in their owning tasks. An ID in an example is never runtime proof.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

test_instruction_contracts() {
  local contract spec plan plan_skill tasks_skill
  contract="$(cat "$KIT_DIR/templates/verification-contract.md")"
  spec="$(cat "$KIT_DIR/templates/spec-template.md")"
  plan="$(cat "$KIT_DIR/templates/plan-template.md")"
  plan_skill="$(cat "$KIT_DIR/skills/sdd-plan/SKILL.md")"
  tasks_skill="$(cat "$KIT_DIR/skills/sdd-tasks/SKILL.md")"

  # AC-001: a shared row, concrete trigger/behavior, compact exclusion and
  # planning-time family replace unbound generic risk prose.
  assert_contains "$plan" '| FM-001 | storage, handler | partial failure | Write fails after acquisition |'
  assert_contains "$plan" '| INV-001 | storage, handler | Never release an unowned connection |'
  assert_contains "$plan" 'Exclusions: formatter / concurrency/ordering'
  assert_contains "$plan" 'without future task IDs'
  assert_contains "$plan" 'tests/storage.sh::test_failed_write_releases_owned_connection'
  assert_contains "$plan" '[verification contract](verification-contract.md)'
  assert_contains "$spec" 'verification_contract: 1'
  assert_contains "$spec" '[version 1 verification contract](verification-contract.md)'
  assert_contains "$contract" 'IDs match `FM-[0-9]{3}` or `INV-[0-9]{3}`'
  assert_contains "$contract" 'Planning needs'
  assert_contains "$contract" 'no task IDs.'
  assert_contains "$contract" 'At task handoff every applicable FM/INV row has a non-gate owner'

  # AC-004: one explicit grammar admits real shell/custom checks and
  # appropriately typed observations while disallowing automated bypass.
  assert_contains "$contract" 'Exactly `test`, `assertion`, `static` or `manual`.'
  assert_contains "$contract" '`assertion` runs a'
  assert_contains "$contract" 'custom executable behavioral assertion without requiring a framework wrapper.'
  assert_contains "$contract" 'Family kinds constrain task kinds'
  assert_contains "$contract" 'static/manual to bypass execution.'
  assert_contains "$contract" 'Untyped AC checks offering only build, typecheck or'
  assert_contains "$contract" 'same task'
  assert_contains "$contract" 'Schema examples here establish authoring intent; runtime negative'

  # AC-006/AC-017: these assertions prove the authoring instructions only;
  # test_verification_bindings owns executable local-ownership validation.
  assert_contains "$plan_skill" '(../../templates/verification-contract.md)'
  assert_contains "$plan_skill" 'Define stable FM-### rows'
  assert_contains "$plan_skill" 'always/never promises into INV-### rows'
  assert_contains "$plan_skill" 'Share rows across affected components'
  assert_contains "$plan_skill" 'intended concrete locators'
  assert_contains "$plan_skill" 'Planning needs no future task IDs'
  assert_contains "$plan_skill" 'decomposition binds these families to owning tasks later'
  assert_contains "$plan_skill" 'independent review still judges their assertions'
  assert_contains "$plan_skill" '--phase plan'
  assert_contains "$tasks_skill" '(../../templates/verification-contract.md)'
  assert_contains "$tasks_skill" 'every applicable planned FM/INV row to a non-gate task through Refs'
  assert_contains "$tasks_skill" 'concrete locators from the plan'
  assert_contains "$tasks_skill" 'adds or extends its covering tests in the same task'
  assert_contains "$tasks_skill" 'and commit'
  assert_contains "$tasks_skill" 'extending an existing test family is valid'
  assert_contains "$tasks_skill" 'never an excuse to'
  assert_contains "$tasks_skill" 'defer local tests'
  assert_contains "$tasks_skill" 'Tests (integration spanning tasks or stacks only)'
  assert_contains "$tasks_skill" 'behavioral follow-ups under Reality Check or Ship still need these bindings'
  assert_contains "$tasks_skill" 'Bindings do not establish semantic coverage'
  assert_contains "$tasks_skill" '--phase tasks'
  assert_contains "$tasks_skill" 'warnings at a new task handoff'
  assert_not_contains "$tasks_skill" 'Tests (happy + error per AC)'
  # Both phases refer to the same schema rather than repeating its tables.
  assert_not_contains "$plan_skill" '| ID | Components | Category | Trigger |'
  assert_not_contains "$tasks_skill" '| ID | Components | Category | Trigger |'
}

# AC-002: each shipped default gives concrete stack scenarios, exclusions and
# distinct optional checkpoint / mandatory full-suite guidance.
defaults_contract() {
  local name text
  for name in "$@"; do
    text="$(cat "$KIT_DIR/templates/stack-overlays/$name.md")"
    assert_contains "$text" '## Failure-mode and checkpoint defaults'
    assert_contains "$text" 'explicit exclusions'
    assert_contains "$text" 'Required `gate_checks` separately cover the full suite'
    assert_contains "$text" 'Optional `checkpoints` use exact authored task-stage names'
    assert_eq 3 "$(printf '%s\n' "$text" | sed -n '/## Failure-mode and checkpoint defaults/,$p' | awk '/^- / {n++} END {print n+0}')" "$name scenario prompts"
  done
}

test_defaults_t006() { defaults_contract rust rust-aws-lambda nextjs aws-cdk-lambda-ts; }

test_defaults_t007() { defaults_contract javascript react bun-monorepo loopback4; }

test_defaults_t008() { defaults_contract expo-rn firebase-rtk-codegen python aws; }

test_defaults_t009() { defaults_contract monorepo troposphere; }

test_all_overlay_defaults() {
  local file
  for file in "$KIT_DIR"/templates/stack-overlays/*.md; do
    defaults_contract "$(basename "$file" .md)"
  done
}

# AC-014: mode instructions retain planning judgment and bound implementation
# context without removing independent gate access or higher-priority rules.
brief_contract() {
  local file text
  for file in "$@"; do
    text="$(cat "$file")"
    assert_contains "$text" '**Planning consultation:**'
    assert_contains "$text" '**Implementation:**'
    assert_contains "$text" 'Source revision:'
    assert_contains "$text" 'required FM/INV'
    assert_contains "$text" 'missing slice; only a new decision changes the plan'
    assert_contains "$text" 'Higher-priority instructions and project-local rules prevail'
    assert_contains "$text" '--from-task --no-tick --summary'
    assert_contains "$text" 'workers never tick tasks'
    assert_not_contains "$text" "Read the task's spec/plan refs, then"
  done
}

test_briefs_t010() {
  brief_contract "$KIT_DIR/agents/rust-expert.md" "$KIT_DIR/agents/rust-aws-lambda-expert.md" "$KIT_DIR/agents/aws-cdk-lambda-ts-expert.md" "$KIT_DIR/agents/nextjs-expert.md"
}

test_briefs_t011() {
  brief_contract "$KIT_DIR/agents/javascript-expert.md" "$KIT_DIR/agents/react-expert.md" "$KIT_DIR/agents/bun-monorepo-expert.md" "$KIT_DIR/agents/loopback4-expert.md"
}

test_briefs_t012() {
  brief_contract "$KIT_DIR/agents/aws-expert.md" "$KIT_DIR/agents/python-expert.md" "$KIT_DIR/agents/expo-rn-expert.md" "$KIT_DIR/agents/firebase-rtk-codegen-expert.md"
}

test_briefs_t013() {
  brief_contract "$KIT_DIR/agents/test-engineer.md"
}

test_all_brief_modes() { brief_contract "$KIT_DIR"/agents/*-expert.md "$KIT_DIR/agents/test-engineer.md"; }

report_fixture() {
  local n="$1" status="$2" verdict="$3" blocks="$4"
  cat <<EOF
## Round $n
**Round:** $n
**Timestamp:** 2026-09-06T12:00:0${n}Z
**Source:** aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
**Floor:** FLOOR-fixture
**Verdict:** $verdict
**Blocking:** $blocks · **Minor:** 0
### Finding O-001
- **Class:** lock-lifecycle
- **Status:** $status
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** failed acquisition followed by cleanup
- **Where:** scripts/run.sh:4, scripts/cancel.sh:8
- **Reproduced:** concrete trigger at listed sites
- **Root cause:** implementation-error
- **Blocks:** AC-022
<!-- gate-round-end: opponent:$n -->
EOF
}

test_reports_and_tally() {
  # AC-010/AC-012/AC-017: legacy counts stay unclassified; a new/open/resolved/
  # reopened sequence counts only the reopened class as a recurrence.
  local spec="$SANDBOX/spec" round
  mkdir -p "$spec/notes"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$KIT_DIR/.specify/specs/002-usage-limit-handling-for-dispatched-runs"
  assert_contains "$OUT" 'opponent rounds=5'
  assert_contains "$OUT" 'reality-check rounds=1'
  assert_contains "$OUT" 'blocking=6 minor=0'
  assert_contains "$OUT" 'unclassified=6'
  report_fixture 1 new CHALLENGED 1 > "$spec/notes/opponent.md"
  report_fixture 2 open CHALLENGED 1 >> "$spec/notes/opponent.md"
  report_fixture 3 resolved CLEARED 0 >> "$spec/notes/opponent.md"
  report_fixture 4 reopened CHALLENGED 1 >> "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=4'
  assert_contains "$OUT" 'locations=8'
  assert_contains "$OUT" 'class=lock-lifecycle findings=4 recurrences=1'
  cp "$spec/notes/opponent.md" "$SANDBOX/valid"
  printf '\140\140\140markdown\n## Round 99\n**Round:** 99\n\140\140\140\n> **Round:** 88\n' >> "$spec/notes/opponent.md"
  run_rc 0 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=4'
  for round in '2026-02-30T12:00:01Z' '2026-09-06T25:00:01Z'; do
    sed "s/2026-09-06T12:00:01Z/$round/" "$SANDBOX/valid" > "$spec/notes/opponent.md"
    run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
    assert_contains "$OUT" 'invalid UTC'
  done
  sed '/gate-round-end: opponent:4/d' "$SANDBOX/valid" > "$spec/notes/opponent.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'incomplete canonical identity'
  report_fixture 1 new CLEARED 1 > "$spec/notes/opponent.md"
  run_rc 3 bash "$SCRIPTS/spec-gate.sh" tally "$spec"
  assert_contains "$OUT" 'verdict disagrees'
}

test_review_scope_contracts() {
  local opponent reality
  opponent="$(cat "$KIT_DIR/agents/opponent.agent.md")"
  reality="$(cat "$KIT_DIR/agents/reality-check.agent.md")"
  assert_contains "$opponent" 'attack covered and omitted cases'
  assert_contains "$opponent" 'defect on unchanged code'
  assert_contains "$opponent" 'every established blocker'
  assert_contains "$opponent" '**Reproduced:**'
  assert_contains "$opponent" '**Class:**'
  assert_contains "$opponent" '**Blocking:**'
  assert_contains "$opponent" 'severity to meet a cost/round target'
  assert_contains "$reality" 'Every round includes every AC'
  assert_contains "$reality" 'Same filenames never suffice'
}

t_run_all
