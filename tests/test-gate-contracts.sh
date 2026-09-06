#!/usr/bin/env bash
# Static schema/instruction assertions; runtime contracts add executable cases
# in their owning tasks. An ID in an example is never runtime proof.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

test_instruction_contracts() {
  local contract spec plan
  contract="$(cat "$KIT_DIR/templates/verification-contract.md")"
  spec="$(cat "$KIT_DIR/templates/spec-template.md")"
  plan="$(cat "$KIT_DIR/templates/plan-template.md")"

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
}

t_run_all
