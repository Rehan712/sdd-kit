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

test_verification_bindings() {
  local spec_dir catalog value fields index record_types mapped_one=0 mapped_two=0
  local fixture shipped shipped_count=0

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

  # AC-004: real shell runners remain valid; an untyped build/text-only
  # command warns even if its displayed expected output says tests passed.
  for fixture in build text; do
    spec_dir="$(make_spec_dir)"
    if [[ "$fixture" == build ]]; then
      verification_edit_fixture "$spec_dir/tasks.md" 's/`node --test test\/thing.test.js`/`npm run build`/'
    else
      verification_edit_fixture "$spec_dir/tasks.md" 's/`node --test test\/thing.test.js`/`grep AC-001 README.md`/'
    fi
    run_rc 0 "$ANALYZE" "$spec_dir"
    assert_contains "$OUT" 'untyped AC Verify' 'AC-004: weak untyped command warns without breaking legacy'
  done
  spec_dir="$(make_spec_dir)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/`node --test test\/thing.test.js`/`bash tests\/check.sh`/'
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_not_contains "$OUT" 'untyped AC Verify' 'AC-004: shell test runners need no framework wrapper'

  # AC-023: run the actual shipped artifacts unchanged in an isolated project
  # with local persona stubs so the test does not depend on an installed hub.
  for shipped in "$KIT_DIR"/.specify/specs/001-* "$KIT_DIR"/.specify/specs/002-*; do
    [[ -d "$shipped" ]] || continue
    shipped_count=$((shipped_count+1))
    spec_dir="$(make_spec_dir)"
    for value in spec.md plan.md tasks.md STATUS.md; do cp "$shipped/$value" "$spec_dir/$value"; done
    verification_edit_fixture "$spec_dir/tasks.md" 's|~/.sdd/agents/|agents/|g'
    run_rc 0 "$ANALYZE" "$spec_dir"
    assert_contains "$OUT" 'legacy verification contract remains compatible' 'AC-023: shipped artifact compatibility is not current freshness'
  done
  assert_eq 2 "$shipped_count" 'AC-023: both shipped specs were actually checked'
}

t_run_all
