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

# Each mutation changes an authored contract, then observes the public analyzer
# or binding API. No source-text match substitutes for parser behavior.
verification_edit_fixture() {
  sed "$2" "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# AC-023/FM-002/INV-005 — O-017's analyzer sibling and T030o43. The analyzer
# reads the spec under LC_ALL=C, so a byte the caller's locale cannot decode no
# longer hides a clarification marker or an AC id; and its own searches and
# the verification parsers it runs read their status, so a read that failed is
# an error, never an absence that passes.
analyzer_locale_and_fault_cases() {
  local spec_dir f
  spec_dir="$(make_verification_spec_dir analyzerlocale)"
  run_rc 0 "$ANALYZE" "$spec_dir"
  cp "$spec_dir/spec.md" "$SANDBOX/analyzer-spec"
  if [[ "$(uname -s)" == Darwin && -n "$(printf '\222 [NEEDS CLARIFICATION: x]\n' | in_locale en_US.UTF-8 grep -n '\[NEEDS CLARIFICATION')" ]]; then
    t_fail 'AC-023: precondition: an unpinned grep under en_US.UTF-8 must miss a marker after 0x92 0x20 (O-017)'
  fi
  printf '\nA fixture line \222 [NEEDS CLARIFICATION: fixture marker]\n' >> "$spec_dir/spec.md"
  run_rc 1 in_locale en_US.UTF-8 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'unresolved [NEEDS CLARIFICATION] marker(s)' \
    'AC-023: a clarification marker after an undecodable byte read as absent under en_US.UTF-8 (O-017)'
  cp "$SANDBOX/analyzer-spec" "$spec_dir/spec.md"
  printf '\n- \222 AC-998 is a criterion no task covers\n' >> "$spec_dir/spec.md"
  run_rc 1 in_locale en_US.UTF-8 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'not covered by any implementation task' \
    'AC-023: an AC id after an undecodable byte was missed under en_US.UTF-8 (O-017)'
  assert_contains "$OUT" 'AC-998' 'AC-023: the uncovered id is named'
  cp "$SANDBOX/analyzer-spec" "$spec_dir/spec.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  f="$SANDBOX/fault-nc"; fault_bin "$f" grep '\[NEEDS CLARIFICATION'
  run_rc 1 env PATH="$f:$PATH" "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'spec.md and plan.md could not be searched for [NEEDS CLARIFICATION] markers' \
    'AC-023: a marker search that failed read as no marker (T030o43)'
  f="$SANDBOX/fault-acs"; fault_bin "$f" grep 'AC-[0-9]{3}'
  run_rc 1 env PATH="$f:$PATH" "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'spec.md could not be read for its AC ids' \
    'AC-023: an AC inventory that could not be read read as no uncovered AC (T030o43)'
  assert_contains "$OUT" 'verification contract: vf_bindings could not read the criteria and requirements of spec.md' \
    'AC-023: the binding parser read an AC inventory that failed (T030o43)'
  f="$SANDBOX/fault-ids-sort"; fault_bin "$f" sort '=-u' '=-'
  run_rc 1 env PATH="$f:$PATH" "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'ids matching AC-[0-9]{3} could not be sorted' \
    'AC-023: an id inventory that could not be sorted read as a short one (T030o43 review)'
  f="$SANDBOX/fault-refs"; fault_bin "$f" grep '(AC|REQ)-[0-9]{3}' "$spec_dir/tasks.md"
  run_rc 1 env PATH="$f:$PATH" "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'tasks.md could not be read for its AC and REQ references' \
    'AC-023: a task reference inventory that could not be read read as no dangling ref (T030o43)'
  f="$SANDBOX/fault-count"; fault_bin "$f" awk '$2=="error"'
  run_rc 1 env PATH="$f:$PATH" "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'verification contract: vf_bindings could not count its diagnostics' \
    'AC-023: a diagnostic count that failed published a catalog carrying errors (T030o43)'
  f="$SANDBOX/fault-fm-count"; fault_bin "$f" awk '# vf_fm_count'
  run_rc 1 env PATH="$f:$PATH" "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "✗ $spec_dir/spec.md: frontmatter could not be counted for verification_contract" \
    'AC-023: the configuration policy counted an unreadable frontmatter as no contract (T030o43)'
  assert_contains "$OUT" "verification contract: $spec_dir/spec.md: frontmatter could not be counted for verification_contract" \
    'AC-023: the binding parser counted an unreadable frontmatter as no contract (T030o43)'
  f="$SANDBOX/fault-fm-value"
  fault_bin "$f" awk 'key=verification_contract'; fault_bin "$f" sed '^verification_contract:'
  run_rc 1 env PATH="$f:$PATH" "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" "✗ $spec_dir/spec.md: frontmatter could not be read for verification_contract" \
    'AC-023: the configuration policy read an unreadable frontmatter as no contract (T030o43)'
  assert_contains "$OUT" "verification contract: $spec_dir/spec.md: frontmatter could not be read for verification_contract" \
    'AC-023: the binding parser read an unreadable frontmatter as no contract (T030o43)'
  # Whitespace is read as whitespace (T030o43 review 2): a manual observation
  # or a registry locator of a U+00A0 alone is empty, as an empty one is, and a
  # gate's Agent path after a U+00A0 is the path.
  local nb=$'\302\240' cmd
  cp "$SANDBOX/analyzer-spec" "$spec_dir/spec.md"; cp "$spec_dir/tasks.md" "$SANDBOX/analyzer-tasks"; cp "$spec_dir/plan.md" "$SANDBOX/analyzer-plan"
  sed "s/\`manual: inspect the release artifact and record its digest\`/\`manual: $nb\`/" "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'task T004 manual Verify must be manual: <observation>' \
    'AC-023: a manual observation of a U+00A0 alone was read as an observation (T030o43 review 2)'
  sed "s/^| manual-family | manual | AC-004 | release-observation |\$/| manual-family | manual | AC-004 | $nb |/" "$SANDBOX/analyzer-plan" > "$spec_dir/plan.md"
  sed "s/^  - \*Tests:\* release-observation\$/  - *Tests:* $nb/" "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'verification family manual-family has blank or placeholder criteria/locator' \
    'AC-023: a registry locator of a U+00A0 alone was read as a locator (T030o43 review 2)'
  assert_contains "$OUT" 'task T004 Ref INV-001 has no matching typed test-family locator' \
    'AC-023: a Tests locator of a U+00A0 alone bound a manual task (T030o43 review 2)'
  cp "$SANDBOX/analyzer-plan" "$spec_dir/plan.md"
  sed "s/^  - \*Agent:\* agents\/opponent.agent.md\$/  - *Agent:* ${nb}agents\/opponent.agent.md/" "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'opponent gate present, agent file exists' \
    'AC-023: a gate Agent path after a U+00A0 read the U+00A0 into the path (T030o43 review 2)'
  sed "s/^  - \*Agent:\* agents\/opponent.agent.md\$/  - *Agent:* see${nb}agents\/opponent.agent.md/" "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'opponent gate present, agent file exists' \
    'AC-023: a U+00A0 inside an Agent line did not end the token before the path (T030o43 review 2)'
  # Both task passes read a stage heading's whitespace alike, so an
  # Integration owner under a Tests heading written with a U+00A0 is in Tests.
  sed "s/^## Tests\$/## ${nb}Tests/" "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_not_contains "$OUT" 'Integration owner is not in the Tests stage' \
    'AC-023: an Integration owner under a Tests heading written with a U+00A0 was not in the Tests stage (T030o43 review 2)'
  # A stage heading's whitespace is read as whitespace, so a checkpoint
  # declared for Backend names the stage written "## Backend<U+00A0>".
  printf 'stacks: []\ngate_checks:\n  - %sbash tests/check.sh%s\ncheckpoints:\n  Backend: []\n' "'" "'" > "$SANDBOX/stage-stack.yml"
  sed "s/^## Backend\$/## Backend$nb/" "$SANDBOX/analyzer-tasks" > "$SANDBOX/stage-tasks.md"
  run_rc 0 bash -c '. "$1"; vf_config "$2" "$3" "$4"' _ "$SCRIPTS/verification-lib.sh" \
    "$SANDBOX/stage-stack.yml" "$SANDBOX/stage-tasks.md" "$SANDBOX/stage-catalog"
  assert_not_contains "$OUT" 'unknown checkpoint stage' \
    'AC-023: a stage heading ending in a U+00A0 was not the stage a checkpoint names (T030o43 review 2)'
  # The Verify command the harness runs and records is the one written: a
  # U+00A0 inside it stays, and one before its backticks is whitespace.
  cmd="grep -c 'a${nb}b' tests/check.sh"
  sed "s#^  - \*Verify:\* \`bash tests/check.sh\` → passed\$#  - *Verify:*$nb\`$cmd\` → passed#" "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  run_rc 0 bash -c '. "$1"; vf_bindings "$2" tasks "" "$3" 2>/dev/null && vf_task_info "$3" T001 && printf "%s" "$VF_TASK_COMMAND"' _ \
    "$SCRIPTS/verification-lib.sh" "$spec_dir" "$SANDBOX/verify-written.nul"
  assert_eq "$cmd" "$OUT" 'AC-023: the Verify command was not run as written (T030o43 review 2)'
  # Every value a parser passes on is taken from the line as written (T030o43
  # review 3, R3-F4): a Tests locator and its registry row written with a
  # U+00A0 inside the file name bind, the harness finds the file, and the
  # catalog holds the name as written; a manual observation name so written
  # equals the name a worker's return gives it.
  local proj="${spec_dir%/.specify/*}" v suffix
  sed "s#tests/check.sh::test_ac_001_shared#tests/my${nb}check.sh::test_ac_001_shared#" "$SANDBOX/analyzer-plan" > "$spec_dir/plan.md"
  sed "s#tests/check.sh::test_ac_001_shared#tests/my${nb}check.sh::test_ac_001_shared#; s#\`tests/check.sh\`#\`tests/my${nb}check.sh\`#" "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  mkdir -p "$proj/tests"; printf 'test_ac_001_shared() { :; }\n' > "$proj/tests/my${nb}check.sh"
  bash -c '. "$1"; vf_bindings "$2" tasks "" "$3" && vf_locators_exist "$3" T001 "$4"' _ "$SCRIPTS/verification-lib.sh" \
    "$spec_dir" "$SANDBOX/written.nul" "$proj" > "$SANDBOX/written.out" 2>&1 ||
    t_fail "AC-023: a Tests locator written with a U+00A0 did not bind or was not found as written (T030o43 review 3): $(head -c 300 "$SANDBOX/written.out")"
  v="$(tr '\0' '\n' < "$SANDBOX/written.nul" | grep -c -F "tests/my${nb}check.sh::test_ac_001_shared")"
  [[ "$v" -ge 2 ]] || t_fail 'AC-023: the binding catalog did not hold a Tests locator as written (T030o43 review 3)'
  rm -f "$proj/tests/my${nb}check.sh"
  sed "s#| release-observation |#| release${nb}observation |#" "$SANDBOX/analyzer-plan" > "$spec_dir/plan.md"
  sed "s#\*Tests:\* release-observation#*Tests:* release${nb}observation#" "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  printf 'Verification-Return: 1\nTask: T004\nCaptures: none\nSummary: x\nManual observation: release%sobservation, artifacts/release.txt, abc, someone, 2026-09-27T00:00:00Z, PASS: ok\nFailure modes:\nINV-001, release%sobservation, manual\n' "$nb" "$nb" > "$SANDBOX/written-return.txt"
  bash -c '. "$1"; vf_bindings "$2" tasks "" "$3" && vf_task_info "$3" T004 && vf_return_parse "$4" "$5" || exit 9
    name="$(tr "\0" "\n" < "$5" | sed -n "/^manual$/{n;p;}" | cut -d, -f1)"
    [[ -n "$name" && "$name" == "${VF_TASK[7]}" ]]' _ "$SCRIPTS/verification-lib.sh" "$spec_dir" "$SANDBOX/written.nul" \
    "$SANDBOX/written-return.txt" "$SANDBOX/written-return.nul" > "$SANDBOX/written.out" 2>&1 ||
    t_fail 'AC-023: a manual observation name written with a U+00A0 did not equal the return that names it (T030o43 review 3)'
  # A value processed further reads the same whitespace: a Refs list with a
  # U+00A0 after each comma and a plan reference written plan<U+00A0>§ are
  # its references, a Files entry ending in a U+00A0 and (new) owns its test
  # file, and a registry row after a U+00A0 is a row.
  cp "$SANDBOX/analyzer-plan" "$spec_dir/plan.md"
  perl -0pe 's/\Q  - *Refs:* REQ-001, AC-001, FM-001\E/  - *Refs:* REQ-001,\xc2\xa0AC-001,\xc2\xa0FM-001,\xc2\xa0plan\xc2\xa0\xc2\xa73.2/; s/\Q  - *Files:* `src\/parser.sh`, `tests\/check.sh`\E/  - *Files:* `src\/parser.sh`, `tests\/check.sh`\xc2\xa0(new)/' \
    "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  [[ "$(grep -c $'\302\240' "$spec_dir/tasks.md")" == 2 ]] || t_fail 'fixture: the Refs and Files edits did not apply'
  bash -c '. "$1"; vf_bindings "$2" tasks "" "$3"' _ "$SCRIPTS/verification-lib.sh" "$spec_dir" "$SANDBOX/written.nul" > "$SANDBOX/written.out" 2>&1 ||
    t_fail "AC-023: a Refs list with a U+00A0 after a comma, or a plan reference after one, was refused (T030o43 review 3): $(head -c 300 "$SANDBOX/written.out")"
  assert_not_contains "$(cat "$SANDBOX/written.out")" 'task T001 defers all local coverage' \
    'AC-023: a Files entry ending in a U+00A0 and (new) did not own its test file (T030o43 review 3)'
  cp "$SANDBOX/analyzer-tasks" "$spec_dir/tasks.md"
  sed "s/^| manual-family | manual | AC-004 | release-observation |\$/${nb}| manual-family | manual | AC-004 | release-observation |/" "$SANDBOX/analyzer-plan" > "$spec_dir/plan.md"
  bash -c '. "$1"; vf_bindings "$2" tasks "" "$3"' _ "$SCRIPTS/verification-lib.sh" "$spec_dir" "$SANDBOX/written.nul" > "$SANDBOX/written.out" 2>&1 ||
    t_fail "AC-023: a registry row after a U+00A0 was not read as that row (T030o43 review 3): $(head -c 300 "$SANDBOX/written.out")"
  cp "$SANDBOX/analyzer-plan" "$spec_dir/plan.md"
  # A stage heading is its text trimmed at both ends in every reader that
  # compares it (R3-F11): through-stage names "## Backend" written with a
  # trailing U+00A0 or space, and so does its catalog's task record.
  for suffix in "$nb" ' '; do
    sed "s/^## Backend\$/## Backend$suffix/" "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
    bash -c '. "$1"; vf_bindings "$2" through-stage Backend "$3" && vf_task_info "$3" T001 && [[ "${VF_TASK[3]}" == Backend ]]' _ \
      "$SCRIPTS/verification-lib.sh" "$spec_dir" "$SANDBOX/stage.nul" > "$SANDBOX/stage.out" 2>&1 ||
      t_fail "AC-023: a Backend heading ending in $(printf '%s' "$suffix" | od -An -tx1 | tr -d ' ') was not the stage through-stage names (T030o43 review 3): $(head -c 200 "$SANDBOX/stage.out")"
  done
  sed "s/^## Backend\$/## ${nb}Backend/" "$SANDBOX/analyzer-tasks" > "$SANDBOX/stage-tasks.md"
  run_rc 0 bash -c '. "$1"; vf_config "$2" "$3" "$4"' _ "$SCRIPTS/verification-lib.sh" \
    "$SANDBOX/stage-stack.yml" "$SANDBOX/stage-tasks.md" "$SANDBOX/stage-catalog-leading"
  assert_not_contains "$OUT" 'unknown checkpoint stage' \
    'AC-023: a stage heading with a U+00A0 after "## " was not the stage a checkpoint names (T030o43 review 3)'
  sed "s/^## Backend\$/## Backend${nb}/; s/^- \[ \] \*\*T001\*\* — Cover the shared shell boundary\$/- [ ] **T001**${nb}— Cover${nb}the shared shell boundary${nb}/" \
    "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  run_rc 0 "$SCRIPTS/spec-task.sh" list "$spec_dir"
  assert_contains "$OUT" "T001"$'\t'"todo"$'\t'"Backend"$'\t'"Cover${nb}the shared shell boundary"$'\n' \
    'AC-023: the task list did not show a stage and a subject as written (T030o43 review 3)'
  awk -v nb="$nb" '/^## Docs$/ {print "## Setup" nb; next} /^  - \*Refs:\* REQ-003, AC-003, FM-002$/ {next} {print}' \
    "$SANDBOX/analyzer-tasks" > "$spec_dir/tasks.md"
  "$ANALYZE" "$spec_dir" > "$SANDBOX/stage.out" 2>&1
  assert_not_contains "$(cat "$SANDBOX/stage.out")" 'task T003 has no *Refs:* line' \
    'AC-023: the analyzer did not read a Setup heading ending in a U+00A0 as Setup (T030o43 review 3)'
  cp "$SANDBOX/analyzer-tasks" "$spec_dir/tasks.md"
}

test_verification_bindings() {
  analyzer_locale_and_fault_cases
  local spec_dir catalog value fields index record_types mapped_one=0 mapped_two=0
  local fixture shipped_count=0

  # AC-001/AC-003/AC-004: concrete shared rows and every explicit proof kind
  # are valid at task handoff even before their planned test files exist.
  spec_dir="$(make_verification_spec_dir clean)"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'consistent' 'AC-004: shell/custom/static/manual family kinds'
  [[ ! -e "$spec_dir/../../../tests/check.sh" ]] || t_fail 'AC-001: fixture unexpectedly contains future tests'
  catalog="$SANDBOX/catalog.nul"
  run_rc 0 bash -c '. "$1"; vf_bindings "$2" tasks "" "$3"' _ \
    "$SCRIPTS/verification-lib.sh" "$spec_dir" "$catalog"
  fields=()
  while IFS= read -r -d '' value; do fields+=("$value"); done < "$catalog"
  assert_eq 0 "$((${#fields[@]} % 12))" 'AC-003: catalog records have exactly twelve fields'
  assert_eq meta "${fields[0]:-}" 'AC-003: catalog starts with schema identity'
  assert_eq 1 "${fields[1]:-}" 'AC-003: schema is versioned'
  record_types=' '
  for ((index=0; index<${#fields[@]}; index+=12)); do
    record_types="$record_types${fields[index]} "
    if [[ "${fields[index]}" == binding && "${fields[index+1]}" == FM-001 ]]; then
      case "${fields[index+2]}:${fields[index+5]}:${fields[index+6]}:${fields[index+7]}" in
        T001:test:shell-family:tests/check.sh::test_ac_001_shared) mapped_one=1 ;;
        T002:assertion:assertion-family:scripts/check-contract.sh::assert_ac_002_contract) mapped_two=1 ;;
      esac
    fi
  done
  for value in meta definition family task test binding; do
    assert_contains "$record_types" " $value " "AC-003: typed $value record"
  done
  assert_eq 1 "$mapped_one" 'AC-003: shared FM binds the actual shell family'
  assert_eq 1 "$mapped_two" 'AC-003: shared FM also binds the actual assertion family'
  run_rc 0 bash -c '. "$1"; printf "%s %s %s %s\n" "$VF_SCHEMA" "$VF_SUCCESS_BYTES" "$VF_FAILURE_BYTES" "$VF_DIAGNOSTIC_LINES"' _ "$SCRIPTS/verification-lib.sh"
  assert_eq '1 2048 8192 20' "$OUT" 'AC-004: public contract constants'

  # AC-006: one covered criterion or FM must not hide another unbound AC.
  spec_dir="$(make_verification_spec_dir partial-criteria)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/REQ-001, AC-001, FM-001/REQ-001, AC-001, AC-002, FM-001/'
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'T001 AC-002 has no declared test-family binding'
  verification_edit_fixture "$spec_dir/plan.md" 's/| shell-family | test | AC-001 |/| shell-family | test | AC-001, AC-002 |/'
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_not_contains "$OUT" 'has no declared test-family binding'

  # AC-011/AC-023: clean fixtures declare checks. A missing legacy list is an
  # explicit gap, never an error or a claim that the application suite ran.
  fixture="$(make_spec_dir)"
  run_rc 0 "$ANALYZE" "$fixture"
  assert_contains "$OUT" consistent 'AC-023: configured legacy authoring stays clean'
  rm "$fixture/../../stack.yml"
  run_rc 0 "$ANALYZE" "$fixture"
  assert_contains "$OUT" 'legacy configuration has no gate_checks' 'AC-011: missing legacy checks warn'

  # AC-001: plan-phase input has no task inventory, task IDs or files yet.
  spec_dir="$(make_verification_spec_dir planning)"
  rm "$spec_dir/tasks.md"
  verification_edit_fixture "$spec_dir/STATUS.md" 's/phase: tasks/phase: plan/'
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" consistent 'AC-001: STATUS selects planning without tasks'
  rm "$spec_dir/STATUS.md"
  run_rc 0 "$ANALYZE" "$spec_dir" --phase plan
  assert_contains "$OUT" consistent 'AC-001: explicit plan phase needs only spec and plan'
  run_rc 1 "$ANALYZE" "$spec_dir" --phase tasks
  assert_contains "$OUT" 'tasks.md missing' 'AC-003: task handoff requires decomposition'

  # AC-003: duplicate definitions and dangling refs fail, independently of
  # the well-formed surrounding shared bindings.
  for value in FM-001 INV-001; do
    spec_dir="$(make_verification_spec_dir "duplicate-$value")"
    awk -v id="$value" 'index($0,"| " id " | ")==1 {print} {print}' \
      "$spec_dir/plan.md" > "$spec_dir/plan.md.tmp" && mv "$spec_dir/plan.md.tmp" "$spec_dir/plan.md"
    run_rc 1 "$ANALYZE" "$spec_dir"
    assert_contains "$OUT" "duplicate failure/invariant definition $value" 'AC-003: duplicate definitions fail'
  done
  spec_dir="$(make_verification_spec_dir dangling-ref)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/AC-001, FM-001/AC-001, FM-099/'
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'undefined failure/invariant FM-099' 'AC-003: an ID mention cannot define a row'
  # AC-003/FM-016: a definition row reproduced inside a nested example fence is
  # quoted text, so its task reference stays undefined; rows after the closed
  # example still define, proving the tracker reopens.
  spec_dir="$(make_verification_spec_dir nested-fence-row)"
  awk -v t="$(printf '\140\140\140')" -v q="$(printf '\140\140\140\140')" \
    'index($0,"| FM-001 | ")==1 { print q "markdown"; print t "text"; print; print t; print q; next } {print}' \
    "$spec_dir/plan.md" > "$spec_dir/plan.md.tmp" && mv "$spec_dir/plan.md.tmp" "$spec_dir/plan.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'undefined failure/invariant FM-001' 'AC-003: a nested-fence row defined a failure mode'
  assert_not_contains "$OUT" 'undefined failure/invariant FM-002' 'AC-003: rows after a closed nested example were suppressed'
  spec_dir="$(make_verification_spec_dir dangling-family)"
  verification_edit_fixture "$spec_dir/plan.md" 's/| shell-family, assertion-family |/| absent-family |/'
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'undefined verification family absent-family' 'AC-003: row families must resolve'
  # AC-003/FM-016: a whole task block quoted inside a fence is not a task, so
  # it cannot claim ownership of an applicable row and silence the warning.
  spec_dir="$(make_verification_spec_dir quoted-task)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/AC-003, FM-002/AC-003/'
  {
    printf '\n\140\140\140markdown\n## Docs\n- [ ] **T098** — quoted owner\n'
    printf -- '  - *Files:* `docs/schema.md`\n  - *Acceptance:* quoted example\n'
    printf -- '  - *Verify kind:* static\n  - *Tests:* `tests/static.sh::test_ac_003_schema`\n'
    printf -- '  - *Verify:* `bash tests/static.sh` → passed\n  - *Refs:* AC-003, FM-002\n'
    printf '\140\140\140\n'
  } >> "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'FM-002 has no non-gate task owner' 'AC-003: a quoted task block claimed row ownership'
  # AC-003/FM-016: four columns of indentation is code, not a definition row.
  spec_dir="$(make_verification_spec_dir indented-row)"
  awk 'index($0,"| FM-001 | ")==1 { print "    " $0; next } {print}' \
    "$spec_dir/plan.md" > "$spec_dir/plan.md.tmp" && mv "$spec_dir/plan.md.tmp" "$spec_dir/plan.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'undefined failure/invariant FM-001' 'AC-003: an indented row defined a failure mode'
  # AC-003/FM-016: an indented HEADER must not reopen a table section either,
  # or an unindented row placed after the quoted example gets attributed to it.
  spec_dir="$(make_verification_spec_dir indented-header)"
  {
    printf '\n    | ID | Components | Category | Trigger | Decided behavior | Test families |\n'
    printf '| FM-001 | parser | boundary | duplicate smuggled behind an indented header | Reject it | shell-family |\n'
  } >> "$spec_dir/plan.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_not_contains "$OUT" 'duplicate failure/invariant definition FM-001' 'AC-003: an indented header reopened a table section'
  # AC-003/FM-016: an HTML-commented task block is quoted in the binding
  # scanners too, so it cannot claim ownership of an applicable row, and a
  # commented definition row does not define one.
  spec_dir="$(make_verification_spec_dir commented-task)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/AC-003, FM-002/AC-003/'
  {
    printf -- '\n<!--\n## Docs\n- [ ] **T093** — quoted owner\n'
    printf -- '  - *Files:* `docs/schema.md`\n  - *Acceptance:* quoted example\n'
    printf -- '  - *Verify kind:* static\n  - *Tests:* `tests/static.sh::test_ac_003_schema`\n'
    printf -- '  - *Verify:* `bash tests/static.sh` → passed\n  - *Refs:* AC-003, FM-002\n'
    printf -- '-->\n'
  } >> "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'FM-002 has no non-gate task owner' 'AC-003: a commented task block claimed row ownership'
  spec_dir="$(make_verification_spec_dir commented-row)"
  awk 'index($0,"| FM-001 | ")==1 { print "<!--"; print; print "-->"; next } {print}' \
    "$spec_dir/plan.md" > "$spec_dir/plan.md.tmp" && mv "$spec_dir/plan.md.tmp" "$spec_dir/plan.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'undefined failure/invariant FM-001' 'AC-003: a commented row defined a failure mode'
  assert_not_contains "$OUT" 'undefined failure/invariant FM-002' 'AC-003: rows after a closed comment were suppressed'
  # AC-003/FM-016: an indented opener is code, so it cannot suppress the real
  # definition table or task inventory that follows. These two fixtures make
  # the opener precede the whole relevant extent; removing the indentation
  # guard makes each analyzer run lose its authored records.
  spec_dir="$(make_verification_spec_dir indented-comment-before-definitions)"
  awk '/^## Risks, failure modes and verification$/ && !inserted {print "    <!--"; inserted=1} {print}' \
    "$spec_dir/plan.md" > "$spec_dir/plan.md.tmp" && mv "$spec_dir/plan.md.tmp" "$spec_dir/plan.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" consistent 'AC-003: indented comment opener swallowed definition rows'
  spec_dir="$(make_verification_spec_dir indented-comment-before-tasks)"
  awk '/^## Backend$/ && !inserted {print "    <!--"; inserted=1} {print}' \
    "$spec_dir/tasks.md" > "$spec_dir/tasks.md.tmp" && mv "$spec_dir/tasks.md.tmp" "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" consistent 'AC-003: indented comment opener swallowed task blocks'

  # The analyzer has three independent raw tasks.md passes: implementation AC
  # coverage, umbrella tags and per-task structure. A commented example cannot
  # satisfy the first or become a malformed/untagged task in the other two.
  spec_dir="$(make_verification_spec_dir commented-coverage-task)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/REQ-002, AC-002, FM-001/REQ-002, FM-001/'
  verification_edit_fixture "$spec_dir/tasks.md" 's/REQ-001, REQ-002, AC-001, AC-002/REQ-001, REQ-002, AC-001/'
  {
    printf -- '\n<!--\n## Example\n- [ ] **T098** — quoted AC owner\n'
    printf -- '  - *Files:* `src/example.sh`\n  - *Refs:* AC-002\n-->\n'
  } >> "$spec_dir/tasks.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'AC(s) not covered by any implementation task (gate Refs don'\''t count): AC-002' \
    'AC-003: commented example task supplied implementation AC coverage'
  assert_not_contains "$OUT" 'task T098 has no *Acceptance:*' 'AC-003: commented example entered task structure validation'

  spec_dir="$(make_verification_spec_dir commented-umbrella-task)"
  make_umbrella "$spec_dir" '[proj]'
  for value in T001 T002 T003 T004 T005; do tag_task "$spec_dir/tasks.md" "$value" proj; done
  printf -- '\n<!--\n## Example\n- [ ] **T098** — quoted untagged task\n-->\n' >> "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_not_contains "$OUT" 'T098' 'AC-003: commented example entered a raw tasks.md pass'

  # O-002 round 4: condition-1 raw HTML is the same quoting class as a fence or
  # a comment. A task block inside <script> renders nowhere -- the GitHub
  # sanitizer deletes it outright -- so it can neither claim an applicable
  # FM/INV row nor supply implementation AC coverage. Those are the two
  # analyzer passes the round-4 reviewer drove to a wrong result.
  spec_dir="$(make_verification_spec_dir script-task)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/AC-003, FM-002/AC-003/'
  {
    printf -- '\n<script>\n</style>\n## Docs\n- [ ] **T093** — hidden owner\n'
    printf -- '  - *Files:* `docs/schema.md`\n  - *Acceptance:* hidden example\n'
    printf -- '  - *Verify kind:* static\n  - *Tests:* `tests/static.sh::test_ac_003_schema`\n'
    printf -- '  - *Verify:* `bash tests/static.sh` → passed\n  - *Refs:* AC-003, FM-002\n'
    printf -- '</script>\n'
  } >> "$spec_dir/tasks.md"
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'FM-002 has no non-gate task owner' 'AC-003: a script-hidden task block claimed row ownership'

  spec_dir="$(make_verification_spec_dir script-coverage-task)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/REQ-002, AC-002, FM-001/REQ-002, FM-001/'
  verification_edit_fixture "$spec_dir/tasks.md" 's/REQ-001, REQ-002, AC-001, AC-002/REQ-001, REQ-002, AC-001/'
  {
    printf -- '\n<script>\n</style>\n## Example\n- [ ] **T098** — hidden AC owner\n'
    printf -- '  - *Files:* `src/example.sh`\n  - *Refs:* AC-002\n</script>\n'
  } >> "$spec_dir/tasks.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'AC(s) not covered by any implementation task (gate Refs don'"'"'t count): AC-002' \
    'AC-003: script-hidden example task supplied implementation AC coverage'

  # The boundary control, without which the rule above could suppress ALL raw
  # HTML and still pass: <details> is CommonMark condition 6, its content is
  # rendered prose a reader sees, so the same task block IS a record and does
  # cover AC-002.
  spec_dir="$(make_verification_spec_dir details-coverage-task)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/REQ-002, AC-002, FM-001/REQ-002, FM-001/'
  verification_edit_fixture "$spec_dir/tasks.md" 's/REQ-001, REQ-002, AC-001, AC-002/REQ-001, REQ-002, AC-001/'
  {
    printf -- '\n<details>\n## Example\n- [ ] **T098** — visible AC owner\n'
    printf -- '  - *Files:* `src/example.sh`\n  - *Refs:* AC-002\n</details>\n'
  } >> "$spec_dir/tasks.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_not_contains "$OUT" 'not covered by any implementation task (gate Refs don'"'"'t count): AC-002' \
    'AC-003: a visible <details> task block was suppressed as if it were hidden'
  spec_dir="$(make_verification_spec_dir traversing-locator)"
  verification_edit_fixture "$spec_dir/plan.md" 's|tests/check.sh::test_ac_001_shared|tests/../../outside.sh::test_ac_001_shared|'
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'malformed concrete locator' 'AC-003: locator files cannot traverse outside the repository'
  spec_dir="$(make_verification_spec_dir nul-plan)"
  {
    printf '\0'
    awk 'BEGIN { for (i=0; i<1000000; i++) printf "a" }'
    cat "$spec_dir/plan.md"
  } > "$spec_dir/plan.md.tmp" && mv "$spec_dir/plan.md.tmp" "$spec_dir/plan.md"
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'plan.md contains a NUL byte' 'AC-003: large catalog inputs cannot hide NUL via pipefail'

  # AC-004: explicit malformed schemas are not silently treated as legacy.
  spec_dir="$(make_verification_spec_dir missing-kind-column)"
  verification_edit_fixture "$spec_dir/plan.md" 's/| Family | Kind | Criteria | Concrete locators |/| Family | Criteria | Concrete locators |/'
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'malformed verification registry header' 'AC-004: kinds cannot be inferred from prose'
  spec_dir="$(make_verification_spec_dir invalid-kind)"
  verification_edit_fixture "$spec_dir/plan.md" 's/| shell-family | test |/| shell-family | build |/'
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'invalid kind' 'AC-004: only defined proof kinds are accepted'
  spec_dir="$(make_verification_spec_dir unknown-version)"
  verification_edit_fixture "$spec_dir/spec.md" 's/verification_contract: 1/verification_contract: 2/'
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'unsupported verification_contract' 'AC-023: explicit unknown version is an error'
  spec_dir="$(make_verification_spec_dir wrong-task-kind)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/Verify kind:\* test/Verify kind:* manual/'
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'conflicts with family' 'AC-004: automated proof cannot be relabeled manual'

  # AC-001/AC-003: incompleteness warns at the right phase; it never invents
  # behavioral proof or retroactively converts legacy specs into new ones.
  spec_dir="$(make_verification_spec_dir placeholder-plan)"
  verification_edit_fixture "$spec_dir/plan.md" 's/Reject the binding before execution/<decided behavior>/'
  run_rc 0 "$ANALYZE" "$spec_dir" --phase plan
  assert_contains "$OUT" 'placeholder' 'AC-001: unfinished decided behavior warns'
  run_rc 0 "$ANALYZE" "$spec_dir" --phase tasks
  assert_contains "$OUT" 'placeholder' 'AC-001: task handoff preserves the placeholder warning classification'
  assert_not_contains "$OUT" 'undefined failure/invariant FM-001' 'AC-003: a placeholder row is not a dangling ID'
  spec_dir="$(make_verification_spec_dir unassigned-row)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/AC-003, FM-002/AC-003/'
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'FM-002 has no non-gate task owner' 'AC-003: unassigned applicable row warns'

  # AC-006: retaining a later integration owner does not excuse deleting
  # all of the behavior task's local test ownership.
  spec_dir="$(make_verification_spec_dir deferred-tests)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/`src\/parser.sh`, `tests\/check.sh`/`src\/parser.sh`/'
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'defers all local coverage' 'AC-006: missing local ownership warns'
  assert_contains "$OUT" 'Integration owner does not excuse local tests' 'AC-006: later task is not a local-proof exemption'
  spec_dir="$(make_verification_spec_dir similar-test-path)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/`src\/parser.sh`, `tests\/check.sh`/`src\/parser.sh`, `tests\/check.sh.backup`/'
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'defers all local coverage' 'AC-006: Files ownership uses an exact path token'

  for value in '(new)' '(new in T002)'; do
    spec_dir="$(make_verification_spec_dir annotated-files)"
    verification_edit_fixture "$spec_dir/tasks.md" "s|\`tests/check.sh\`|\`tests/check.sh\` $value|"
    run_rc 0 "$ANALYZE" "$spec_dir"
    assert_not_contains "$OUT" 'defers all local coverage' 'AC-006: supported new-file annotation retains exact ownership'
  done

  # AC-006: neither the Ship stage nor an Agent field can exempt a defect fix.
  spec_dir="$(make_verification_spec_dir followup)"
  cat >> "$spec_dir/tasks.md" <<'EOF'

- [ ] **T009o1** — Fix the parser regression
  - *Files:* `src/parser.sh`
  - *Agent:* agents/opponent.agent.md
  - *Acceptance:* Reject the reproduced malformed binding.
  - *Refs:* AC-001, FM-001
EOF
  run_rc 1 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" 'T009o1 has no *Verify kind:*' 'AC-006: Agent-bearing follow-up requires typed proof'
  cat >> "$spec_dir/tasks.md" <<'EOF'
  - *Verify kind:* test
  - *Tests:* `tests/check.sh::test_ac_001_shared`
  - *Verify:* `bash tests/check.sh` → passed
EOF
  verification_edit_fixture "$spec_dir/tasks.md" 's/`src\/parser.sh`$/`src\/parser.sh`, `tests\/check.sh`/'
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" consistent 'AC-006: a typed follow-up with its covering test passes'

  # AC-001/AC-003: fenced/quoted examples are not definitions, and ordinary
  # table grammar does not depend on a particular section title.
  spec_dir="$(make_verification_spec_dir quoted-examples)"
  cat >> "$spec_dir/plan.md" <<'EOF'

```markdown
### Failure modes
| ID | Components | Category | Trigger | Decided behavior | Test families |
|---|---|---|---|---|---|
| FM-001 | fake | boundary | quoted example | does not define a row | missing-family |
```

> | FM-001 | fake | boundary | quoted example | does not define a row | missing-family |
EOF
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_contains "$OUT" consistent 'AC-003: quoted/fenced examples do not add definitions'

  # O-034: simple Bash 3.2 operators end words even without whitespace.
  local weak_redirect_cases=() runner_redirect_cases=() redirect prefix tool spacing
  for tool in grep rg diff; do
    for prefix in '' /usr/bin/ ./tools/ tests/; do
      for redirect in '>|out.txt' ' >|out.txt' '>| out.txt' ' >| out.txt'; do
        weak_redirect_cases+=("$prefix$tool$redirect old new")
      done
    done
  done
  for redirect in '<input.txt' '>out.txt' '>>out.txt' '>|out.txt' '<>input.txt' '<&0' '>&1' '&>out.txt'; do
    for spacing in '' ' '; do
      for fixture in 'grepREDIRECT AC-001 README.md' 'rg AC-001REDIRECT README.md' \
        'diff oldREDIRECT new' 'tscREDIRECT --noEmit' 'npm runREDIRECT typecheck' \
        'npmREDIRECT run build' 'testREDIRECT -e README.md' 'test -fREDIRECT README.md'; do
        weak_redirect_cases+=("${fixture/REDIRECT/$spacing$redirect}")
      done
      for fixture in 'bashREDIRECT tests/typecheck.sh' 'nodeREDIRECT --test test/build.js' \
        'cargo testREDIRECT --test typecheck' 'python3 -mREDIRECT pytest tests/build.py' \
        'npm runREDIRECT test -- --grep typecheck' './tests/check-typecheck.shREDIRECT /usr/bin/grep'; do
        runner_redirect_cases+=("${fixture/REDIRECT/$spacing$redirect}")
      done
    done
  done

  # AC-004/O-034: arguments and redirection targets do not become runners.
  for fixture in \
    'npm run build' 'npm run typecheck' 'tsc --noEmit' 'grep AC-001 README.md' \
    'tsc --noEmit tests/unit.ts' 'npm run typecheck -- --project tests/tsconfig.json' \
    'grep AC-001 tests/check.sh' 'npm run build -- --outDir tests/build' \
    'test -e README.md' 'test -f README.md' 'grep pytest README.md' \
    'rg bats README.md' 'diff fixtures/test.txt actual.txt' \
    'grep test README.md' 'grep tests README.md' 'grep "node --test" README.md' \
    'grep "cargo test" README.md' 'grep AC-001 scripts/test-check.sh' \
    'test -e tests/check.sh' 'test -f tests/check.sh' \
    'rg /usr/bin/pytest README.md' 'diff fixtures/bats.txt actual.txt' \
    'bash --rcfile tests/env.sh -c "npm run typecheck"' \
    '/usr/bin/grep AC-001 tests/check.sh' \
    '/usr/bin/grep<input.txt AC-001 tests/check.sh' '/usr/bin/grep <input.txt AC-001 tests/check.sh' \
    '/usr/bin/grep>output.txt AC-001 tests/check.sh' '/usr/bin/grep >output.txt AC-001 tests/check.sh' \
    '/usr/bin/rg AC-001 tests/check.sh' \
    '/usr/bin/rg<input.txt AC-001 tests/check.sh' '/usr/bin/rg <input.txt AC-001 tests/check.sh' \
    '/usr/bin/rg>output.txt AC-001 tests/check.sh' '/usr/bin/rg >output.txt AC-001 tests/check.sh' \
    '/usr/bin/diff fixtures/test.txt actual.txt' \
    '/usr/bin/diff<input.txt fixtures/test.txt actual.txt' '/usr/bin/diff <input.txt fixtures/test.txt actual.txt' \
    '/usr/bin/diff>output.txt fixtures/test.txt actual.txt' '/usr/bin/diff >output.txt fixtures/test.txt actual.txt' \
    './tools/grep AC-001 tests/check.sh' \
    './tools/grep<input.txt AC-001 tests/check.sh' './tools/grep <input.txt AC-001 tests/check.sh' \
    './tools/grep>output.txt AC-001 tests/check.sh' './tools/grep >output.txt AC-001 tests/check.sh' \
    './tools/rg AC-001 tests/check.sh' \
    './tools/rg<input.txt AC-001 tests/check.sh' './tools/rg <input.txt AC-001 tests/check.sh' \
    './tools/rg>output.txt AC-001 tests/check.sh' './tools/rg >output.txt AC-001 tests/check.sh' \
    './tools/diff fixtures/test.txt actual.txt' \
    './tools/diff<input.txt fixtures/test.txt actual.txt' './tools/diff <input.txt fixtures/test.txt actual.txt' \
    './tools/diff>output.txt fixtures/test.txt actual.txt' './tools/diff >output.txt fixtures/test.txt actual.txt' \
    'tools/grep AC-001 tests/check.sh' 'tools/rg AC-001 tests/check.sh' 'tools/diff fixtures/test.txt actual.txt' \
    '../tools/grep AC-001 tests/check.sh' '../tools/rg AC-001 tests/check.sh' '../tools/diff fixtures/test.txt actual.txt' \
    'tests/grep AC-001 tests/check.sh' 'tests/rg AC-001 tests/check.sh' 'tests/diff fixtures/test.txt actual.txt' \
    'npm<tests/test-typecheck.txt run typecheck' 'npm <tests/test-typecheck.txt run typecheck' \
    'tsc>tests/test-typecheck.log --noEmit' 'tsc >tests/test-typecheck.log --noEmit' \
    'grep<tools/pytest typecheck' 'grep <tools/pytest typecheck' \
    'grep<tools/npm test typecheck.txt' 'grep <tools/npm test typecheck.txt' \
    'npm<tests/check.txt run typecheck' 'npm <tests/check.txt run typecheck' \
    'npm>tests/check.txt run typecheck' 'npm >tests/check.txt run typecheck' \
    'npm<tests/check.txt run build' 'npm <tests/check.txt run build' \
    'npm>tests/check.txt run build' 'npm >tests/check.txt run build' \
    'tsc<input.txt --noEmit' 'tsc <input.txt --noEmit' \
    'tsc>input.txt --noEmit' 'tsc >input.txt --noEmit' \
    'grep<input.txt AC-001 README.md' 'grep <input.txt AC-001 README.md' \
    'grep>input.txt AC-001 README.md' 'grep >input.txt AC-001 README.md' \
    'rg<tools/pytest AC-001 README.md' 'rg <tools/pytest AC-001 README.md' \
    'rg>tools/pytest AC-001 README.md' 'rg >tools/pytest AC-001 README.md' \
    'diff<tools/bats actual.txt expected.txt' 'diff <tools/bats actual.txt expected.txt' \
    'diff>tools/bats actual.txt expected.txt' 'diff >tools/bats actual.txt expected.txt' \
    'test<tests/check.txt -e README.md' 'test <tests/check.txt -e README.md' \
    'test>tests/check.txt -e README.md' 'test >tests/check.txt -e README.md' \
    'grep<tools/bash tests/typecheck.sh' 'grep <tools/bash tests/typecheck.sh' \
    'grep>tools/bash tests/typecheck.sh' 'grep >tools/bash tests/typecheck.sh' \
    'grep<tests/check.sh typecheck.txt' 'grep <tests/check.sh typecheck.txt' \
    'grep>tests/check.sh typecheck.txt' 'grep >tests/check.sh typecheck.txt' \
    'tsc 2>output.txt --noEmit' 'npm2>output.txt test typecheck.txt' \
    'npm&>tests/typecheck.log run build' 'tsc>&tests/check.log --noEmit' \
    'npm 2&>out.txt test typecheck.txt' \
    "${weak_redirect_cases[@]}"; do
    spec_dir="$(make_spec_dir)"
    value="${fixture//&/\\&}"; value="${value//|/\\|}"
    verification_edit_fixture "$spec_dir/tasks.md" "s|\`node --test test/thing.test.js\`|\`$value\`|"
    run_rc 0 "$ANALYZE" "$spec_dir"
    assert_contains "$OUT" 'untyped AC Verify' "AC-004: untyped $fixture warns without breaking legacy"
    assert_contains "$OUT" 'warning(s), 0 errors' "AC-004: $fixture remains warning-only"
  done
  for fixture in \
    'bash tests/check.sh' 'sh tests/check.sh' './tests/check.sh' \
    'bash -e tests/typecheck.sh' '/bin/bash tests/typecheck.sh' './scripts/test-build.sh' \
    'node --test test/typecheck.test.js' 'cargo test --test build' \
    'pytest tests/typecheck.py' '/usr/bin/pytest tests/typecheck.py' 'bats tests/build.bats' \
    'python3 -m pytest tests/typecheck.py' \
    'npm test -- --grep typecheck' 'npm run test -- --grep typecheck' \
    '/usr/local/bin/npm test -- --grep typecheck' 'pnpm test --filter typecheck' \
    'yarn run test --grep typecheck' 'make test TARGET=typecheck' \
    'bun test tests/typecheck.test.ts' 'go test ./typecheck' \
    'bash<input.txt tests/typecheck.sh' 'bash <input.txt tests/typecheck.sh' \
    'bash>input.txt tests/typecheck.sh' 'bash >input.txt tests/typecheck.sh' \
    './tests/check-typecheck.sh<input.txt' './tests/check-typecheck.sh <input.txt' \
    './tests/check-typecheck.sh>input.txt' './tests/check-typecheck.sh >input.txt' \
    'node<input.txt --test test/typecheck.test.js' 'node <input.txt --test test/typecheck.test.js' \
    'node>input.txt --test test/typecheck.test.js' 'node >input.txt --test test/typecheck.test.js' \
    'cargo<input.txt test --test typecheck' 'cargo <input.txt test --test typecheck' \
    'cargo>input.txt test --test typecheck' 'cargo >input.txt test --test typecheck' \
    'pytest<input.txt tests/typecheck.py' 'pytest <input.txt tests/typecheck.py' \
    'pytest>input.txt tests/typecheck.py' 'pytest >input.txt tests/typecheck.py' \
    '/usr/bin/python3<input.txt -m pytest tests/typecheck.py' '/usr/bin/python3 <input.txt -m pytest tests/typecheck.py' \
    '/usr/bin/python3>input.txt -m pytest tests/typecheck.py' '/usr/bin/python3 >input.txt -m pytest tests/typecheck.py' \
    'npm<input.txt run test -- --grep typecheck' 'npm <input.txt run test -- --grep typecheck' \
    'npm>input.txt run test -- --grep typecheck' 'npm >input.txt run test -- --grep typecheck' \
    'npm 2>output.txt run test -- --grep typecheck' 'bash 0<input.txt -e tests/typecheck.sh' \
    '/bin/bash tests/check.sh /usr/bin/grep' './tests/check.sh ./tools/rg' \
    '/usr/bin/node --test test/check.js ../tools/diff' \
    'node scripts/assert-content.js /usr/bin/grep AC-001 README.md' \
    'node scripts/assert-content.js ./tools/rg AC-001 README.md' \
    'node scripts/assert-content.js ../tools/diff actual.txt expected.txt' \
    'bash&>tests/build.log tests/typecheck.sh' 'npm>&tests/typecheck.log run test' \
    'node>|tests/build.log --test test/typecheck.js' 'pytest<>tests/build.txt tests/typecheck.py' \
    'bats&>out.txt tests/build.bats' 'pnpm>|out.txt test --filter typecheck' \
    'yarn run>|out.txt test --grep typecheck' 'bun>|out.txt test tests/build.ts' \
    'go test>|out.txt ./typecheck' 'make>|out.txt test TARGET=typecheck' \
    "${runner_redirect_cases[@]}"; do
    spec_dir="$(make_spec_dir)"
    value="${fixture//&/\\&}"; value="${value//|/\\|}"
    verification_edit_fixture "$spec_dir/tasks.md" "s|\`node --test test/thing.test.js\`|\`$value\`|"
    run_rc 0 "$ANALYZE" "$spec_dir"
    assert_not_contains "$OUT" 'untyped AC Verify' "AC-004: $fixture has no weak executable"
    assert_contains "$OUT" consistent "AC-004: $fixture stays clean"
  done

  # AC-023: run the actual shipped artifacts in an isolated project with local
  # persona stubs so the test does not depend on an installed hub.
  local rel002='' root="$SANDBOX/shipped" probe diag i
  shipped_specs_case

  # O-015 sibling, round 10, both directions, built from the identity's own
  # view so the fixture cannot depend on a dropped byte: 002's tasks.md as
  # vf_path_content yields it, with the probe placed after its first task
  # header, a hashed line. On an Evidence line the identity drops the probe,
  # so the verdict cannot move; on a body line it is source, and must. Before
  # the repair an Agent field marker or an unclosed comment opener on an
  # Evidence line failed the analyzer with the identity unchanged. The RAW
  # artifact would still fail on that line, because the analyzer reads a
  # field from any line carrying its marker: a field-grammar defect recorded
  # in Decisions and deliberately left open, so this certifies the identity's
  # view and not the raw file.
  [[ -n "$rel002" ]] || t_fail 'AC-023: shipped 002 is not in the identity enumeration'
  for i in 1 2; do
    case "$i" in
      1) probe='cross-checked with *Agent:* agents/opponent-retired.md'
         diag='opponent gate agent file not found: agents/opponent-retired.md';;
      2) probe='<!-- earlier wording kept for the record'
         diag='opponent gate task not found';;
    esac
    rm -rf "$root"; mkdir -p "$root/$rel002"
    for value in spec.md plan.md tasks.md STATUS.md; do
      bash -c '. "$1/verification-lib.sh"; vf_path_content "$2" "$3" "$4"' \
        _ "$SCRIPTS" "$KIT_DIR" "$rel002/$value" "$root/$rel002/$value" \
        || t_fail "AC-023: cannot read $rel002/$value as the identity hashes it"
    done
    cp "$root/$rel002/tasks.md" "$SANDBOX/hashed-tasks"
    awk -v p="$probe" '!done && /^- \[[ xX~]\] \*\*T[0-9]/ {print; print "  - *Evidence:* " p; done=1; next} {print}' \
      "$SANDBOX/hashed-tasks" > "$root/$rel002/tasks.md"
    assert_eq 1 "$(grep -c -F -- "$probe" "$root/$rel002/tasks.md")" 'AC-023: the Evidence-line probe was not placed'
    shipped_analyzer_case "$root" "$rel002" 0
    assert_contains "$OUT" 'legacy verification contract remains compatible' \
      "AC-023: in the identity's view, text on a shipped Evidence line broke compatibility: $probe"
    assert_not_contains "$OUT" "$diag" \
      "AC-023: in the identity's view, text on a shipped Evidence line changed the analyzer verdict: $probe"
    awk -v p="$probe" '!done && /^- \[[ xX~]\] \*\*T[0-9]/ {print; print "  " p; done=1; next} {print}' \
      "$SANDBOX/hashed-tasks" > "$root/$rel002/tasks.md"
    assert_eq 1 "$(grep -c -F -- "$probe" "$root/$rel002/tasks.md")" 'AC-023: the body-line probe was not placed'
    shipped_analyzer_case "$root" "$rel002" 1
    assert_contains "$OUT" "$diag" "AC-023: the same text on a body line did not reach the analyzer: $probe"
  done
}

# AC-023: both the shipped set and each artifact are read as the input identity
# reads them: which specs exist comes from vf_source_paths, never a directory
# glob that an ignored or empty leftover would satisfy, and each file's bytes
# come from vf_path_content (shipped_analyzer_case). Counts into the caller's
# shipped_count and names shipped 002 in the caller's rel002.
shipped_spec_rels() { # -> $SANDBOX/shipped-rels, NUL-framed; names 002 in the caller's rel002
  local path name
  bash -c '. "$1/verification-lib.sh"; vf_source_paths "$2" "$3"' \
    _ "$SCRIPTS" "$(cd "$KIT_DIR" && pwd -P)" "$SANDBOX/kit-paths" \
    || t_fail 'AC-023: cannot enumerate the kit as the input identity does'
  : > "$SANDBOX/shipped-rels"
  while IFS= read -r -d '' path; do
    case "$path" in .specify/specs/001-*/tasks.md|.specify/specs/002-*/tasks.md) ;; *) continue;; esac
    name="${path#.specify/specs/}"; name="${name%/tasks.md}"
    [[ "$name" != */* ]] || continue
    printf '%s\0' ".specify/specs/$name" >> "$SANDBOX/shipped-rels"
    [[ "$name" != 002-* ]] || rel002=".specify/specs/$name"
  done < "$SANDBOX/kit-paths"
}

shipped_specs_case() {
  local rel
  shipped_spec_rels
  while IFS= read -r -d '' rel; do
    shipped_count=$((shipped_count+1))
    shipped_analyzer_case "$KIT_DIR" "$rel" 0
    assert_contains "$OUT" 'legacy verification contract remains compatible' 'AC-023: shipped artifact compatibility is not current freshness'
  done < "$SANDBOX/shipped-rels"
  assert_eq 2 "$shipped_count" 'AC-023: both shipped specs were actually checked'
}

# O-015 review: a spec directory the identity never sees -- one left empty by
# a branch switch, or one whose files git ignores -- is not a shipped spec and
# must not decide the AC-023 loop.
test_leftover_spec_directories_do_not_decide_the_shipped_loop() {
  local host="$SANDBOX/host-specs" shipped_count=0 rel002='' rel first=''
  git_host "$host" || t_fail 'AC-023: cannot build the host tree'
  # The host is built from the identity's enumeration too, never from a glob
  # of the live kit, which a leftover there would empty (second review).
  shipped_spec_rels
  while IFS= read -r -d '' rel; do
    copy_kit "$KIT_DIR" "$host" "$rel" || t_fail 'AC-023: cannot build the host tree'
    [[ -n "$first" ]] || first="$rel"
  done < "$SANDBOX/shipped-rels"
  mkdir -p "$host/.specify/specs/002-zz-scratch" "$host/.specify/specs/001-stale"
  printf '.specify/specs/001-stale/\n' >> "$host/.git/info/exclude"
  cp "$host/$first/tasks.md" "$host/.specify/specs/001-stale/tasks.md" \
    || t_fail 'AC-023: cannot plant the ignored leftover spec'
  [[ -f "$host/.specify/specs/001-stale/tasks.md" ]] \
    || t_fail 'AC-023: the ignored leftover spec holds no tasks.md, so the probe tests nothing'
  rel002=''
  KIT_DIR="$host" shipped_specs_case
}

# AC-023/O-015: the analyzer reads each shipped artifact as the input identity
# hashes it -- through vf_path_content, the function vf_path_record calls --
# because this suite is reuse-checked and a reused PASS must be a function of
# that identity. The lines the identity drops (Evidence lines, checkbox state,
# status:/updated:, STATUS outside its Decisions log) are REQ-009 bookkeeping,
# not part of the compatibility claim.
shipped_analyzer_case() { # <repository root> <repo-relative spec dir> <expected exit>; sets OUT
  local spec_dir value
  spec_dir="$(make_spec_dir)"
  for value in spec.md plan.md tasks.md STATUS.md; do
    bash -c '. "$1/verification-lib.sh"; vf_path_content "$2" "$3" "$4"' \
      _ "$SCRIPTS" "$1" "$2/$value" "$spec_dir/$value" \
      || t_fail "AC-023: cannot read $2/$value as the identity hashes it"
  done
  verification_edit_fixture "$spec_dir/tasks.md" 's|~/.sdd/agents/|agents/|g'
  run_rc "$3" "$ANALYZE" "$spec_dir"
}

t_run_all
