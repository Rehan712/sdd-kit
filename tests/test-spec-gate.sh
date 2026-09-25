#!/usr/bin/env bash
. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

accept_return() { # spec task capture output
  local spec="$1" task="$2" cap="$3" file="$4"
  {
    printf 'Verification-Return: 1\nTask: %s\nCaptures: %s\nSummary: ' "$task" "$cap"
    cat "$spec/notes/captures/$cap/summary.txt"
    printf 'Failure modes:\nFM-001, tests/check.sh::test_ac_001_shared, %s\n' "$cap"
  } > "$file"
}

accept_event_count() { # spec outcome [reason]
  local spec="$1" outcome="$2" reason="${3:-}" file count=0
  for file in "$spec"/notes/verification/accept-events/ACCEPT-*/meta.nul; do
    [[ -f "$file" ]] || continue
    if tr '\000' '\n' < "$file" | awk -v outcome="$outcome" -v reason="$reason" '
      previous=="outcome" && $0==outcome {seen_outcome=1}
      previous=="reason" && $0==reason {seen_reason=1}
      {previous=$0}
      END {exit !(seen_outcome && (reason=="" || seen_reason))}
    '; then
      count=$((count+1))
    fi
  done
  printf '%s\n' "$count"
}

test_acceptance() {
  local spec repo cap original bad before file receipt rejected_before
  spec="$(make_verification_git_dir acceptance)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  printf "verification_environment:\n  - 'VF_ACCEPT_ENV'\n" >> "$repo/.specify/stack.yml"
  export VF_ACCEPT_ENV=initial
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  original="$SANDBOX/return.txt"
  accept_return "$spec" T001 "$cap" "$original"
  before="$(cat "$spec/tasks.md")"
  # AC-022: fabricated summaries/IDs and missing/extra mappings cannot tick.
  for bad in missing extra duplicate forged wrong-task wrong-test; do
    file="$SANDBOX/$bad.txt"
    case "$bad" in
      missing) sed '/^FM-001,/d' "$original" > "$file";;
      extra) cp "$original" "$file"; printf 'FM-999, tests/check.sh::test_ac_001_shared, %s\n' "$cap" >> "$file";;
      duplicate) cp "$original" "$file"; printf 'FM-001, tests/check.sh::test_ac_001_shared, %s\n' "$cap" >> "$file";;
      forged) sed 's/^Summary:.*/Summary: all passed/' "$original" > "$file";;
      wrong-task) sed 's/^Task:.*/Task: T002/' "$original" > "$file";;
      wrong-test) sed 's/FM-001, tests\/check.sh::test_ac_001_shared/FM-001, tests\/check.sh::imaginary/' "$original" > "$file";;
    esac
    run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$file"
    assert_eq "$before" "$(cat "$spec/tasks.md")" "AC-022: invalid $bad return changed tasks bytes"
  done
  run_rc 3 "$SCRIPTS/spec-task.sh" "done" "$spec" T001 --evidence fabricated
  assert_eq "$before" "$(cat "$spec/tasks.md")"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$original"
  assert_contains "$OUT" 'accept accepted'
  assert_contains "$(cat "$spec/tasks.md")" '- [x] **T001**'
  before="$(cat "$spec/tasks.md")"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$original"
  assert_contains "$OUT" 'already-accepted'
  assert_contains "$OUT" 'freshness=historical'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: idempotent acceptance does not rewrite tasks'
  # The receipt-first path relies on the committed marker, so its digest must
  # bind to the sealed receipt rather than treating mere marker existence as
  # proof that the transaction committed.
  for receipt in "$spec/notes/verification/accepted/T001"/ACC-*; do
    [[ -f "$receipt/COMMITTED" ]] && break
  done
  cp "$receipt/COMMITTED" "$SANDBOX/committed-marker"
  printf tampered > "$receipt/COMMITTED"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$original"
  assert_contains "$OUT" 'committed marker digest mismatch' 'AC-022: a forged receipt marker was trusted'
  cp "$SANDBOX/committed-marker" "$receipt/COMMITTED"
  # Prepared-after crash recovery completes bookkeeping without another rewrite.
  for file in "$spec/notes/verification/accepted/T001"/ACC-*/COMMITTED; do rm "$file"; done
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$original"
  assert_eq "$before" "$(cat "$spec/tasks.md")"
  rejected_before="$(accept_event_count "$spec" rejected)"
  # AC-016/AC-022: replay is historical acknowledgement once this exact return
  # has a committed receipt. Changed declared environment cannot turn it into a
  # rejection or claim current freshness, and the task file stays byte-identical.
  run_rc 0 env VF_ACCEPT_ENV=changed "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$original"
  assert_contains "$OUT" 'freshness=historical'
  assert_eq "$rejected_before" "$(accept_event_count "$spec" rejected)" \
    'AC-016: environment drift wrote a rejection audit event for an accepted return'
  [[ "$(accept_event_count "$spec" already-accepted historical-receipt)" -gt 0 ]] \
    || t_fail 'AC-016: historical replay audit omitted its receipt reason'
  assert_eq "$before" "$(cat "$spec/tasks.md")"
  printf changed >> "$repo/src/parser.sh"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$original"
  assert_contains "$OUT" 'freshness=historical'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: stale return preserves historical completion'
  printf '\nSemantic task note added after historical acceptance.\n' >> "$spec/tasks.md"
  before="$(cat "$spec/tasks.md")"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$original"
  assert_contains "$OUT" 'freshness=historical'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: historical replay rewrote a revised task file'
  mkdir -p "$spec/notes/verification/lock"
  printf foreign > "$spec/notes/verification/lock/owner"
  run_rc 3 "$SCRIPTS/spec-task.sh" undo "$spec" T001
  run_rc 3 "$SCRIPTS/spec-task.sh" start "$spec" T002
  assert_eq foreign "$(cat "$spec/notes/verification/lock/owner")"
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: mutations serialize with acceptance'
  narrative_return_cases
  followup_binding_cases
}

# AC-015/AC-022 (FM-009): a post-PR c/r follow-up is a behavior task, so the
# Ship exemption does not reach it. The shape /sdd:review prescribes must be
# capturable and acceptable; the older three-field shape must not tick.
followup_binding_cases() {
  local spec repo cap before file
  spec="$(make_verification_git_dir followup_binding)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  before="$(cat "$spec/tasks.md")"
  # The shape the skill used to prescribe: Files, Acceptance and Refs only.
  cat >> "$spec/tasks.md" <<'UNTYPED'

- [ ] **T011c2** — Fix the red lint check
  - *Files:* `src/parser.sh`
  - *Acceptance:* the failing check passes locally
  - *Refs:* AC-001
UNTYPED
  local missing
  run_rc 3 "$SCRIPTS/spec-run.sh" "$spec" T011c2 --cwd "$repo" --from-task --no-tick --summary
  for missing in 'Verify kind' Tests Verify; do
    assert_contains "$OUT" "task T011c2 has no *$missing:* field" \
      "AC-015: capture did not name the missing $missing binding"
  done
  accept_return "$spec" T011c2 CAP-none "$SANDBOX/untyped-return.txt"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T011c2 "$SANDBOX/untyped-return.txt"
  assert_contains "$OUT" 'task T011c2 has no *Verify kind:* field'
  assert_contains "$(cat "$spec/tasks.md")" '- [ ] **T011c2**' 'AC-015: untyped follow-up ticked'
  # The full typed binding the skill now prescribes captures and accepts.
  printf '%s\n' "$before" > "$spec/tasks.md"
  cat >> "$spec/tasks.md" <<'TYPED'

- [ ] **T011c1** — Fix the red shared-boundary check
  - *Files:* `src/parser.sh`, `tests/check.sh`
  - *Acceptance:* The failing check passes locally and its family keeps the shared boundary case.
  - *Verify kind:* test
  - *Tests:* `tests/check.sh::test_ac_001_shared`
  - *Verify:* `bash tests/check.sh` → passed
  - *Refs:* AC-001, FM-001
TYPED
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T011c1 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  [[ -n "$cap" ]] || t_fail 'AC-015: typed follow-up produced no capture'
  file="$SANDBOX/followup-return.txt"
  accept_return "$spec" T011c1 "$cap" "$file"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T011c1 "$file"
  assert_contains "$OUT" 'accept accepted'
  assert_contains "$(cat "$spec/tasks.md")" '- [x] **T011c1**'
}

# AC-022 / plan 4.2: prose may surround the block and is never evidence, while
# nothing inside the block is relaxed. Uses its own fixture because the caller
# has already dirtied its source and taken a foreign lock.
narrative_return_cases() {
  local spec repo cap base before file
  spec="$(make_verification_git_dir narrative_return)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  base="$SANDBOX/narrative-base.txt"
  accept_return "$spec" T001 "$cap" "$base"
  before="$(cat "$spec/tasks.md")"
  # A line that is clearly an attempted mapping — ID immediately followed by a
  # comma — stays strictly validated. A line without that comma is prose even
  # when it names a locator, because it is indistinguishable from the permitted
  # narrative in O-001; a REQUIRED row lost that way is still caught as
  # truncation below, and a well-formed extra row is still caught as an extra.
  file="$SANDBOX/narrative-short-mapping.txt"
  { cat "$base"; printf 'FM-002, tests/check.sh::test_ac_001_shared\n'; } > "$file"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$file"
  assert_contains "$OUT" 'mapping needs ID, locator, capture'
  assert_eq "$before" "$(cat "$spec/tasks.md")"
  # Header strictness is unchanged: prose before Failure modes is still an error.
  file="$SANDBOX/narrative-in-header.txt"
  {
    printf 'Verification-Return: 1\nTask: T001\n'
    printf 'I ran the suite twice to be sure.\n'
    printf 'Captures: %s\nSummary: ' "$cap"
    cat "$spec/notes/captures/$cap/summary.txt"
    printf 'Failure modes:\nFM-001, tests/check.sh::test_ac_001_shared, %s\n' "$cap"
  } > "$file"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$file"
  assert_contains "$OUT" 'unexpected field or malformed mapping'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: in-block prose is rejected'
  # A required mapping placed after the narrative is dropped, so the set is short.
  file="$SANDBOX/narrative-hides-mapping.txt"
  {
    printf 'Verification-Return: 1\nTask: T001\nCaptures: %s\nSummary: ' "$cap"
    cat "$spec/notes/captures/$cap/summary.txt"
    printf 'Failure modes:\nAll requested verification is complete.\n'
    printf 'FM-001, tests/check.sh::test_ac_001_shared, %s\n' "$cap"
  } > "$file"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$file"
  # AC-016/AC-022: a truncated envelope must NOT be reported as a missing row
  # and must not be typed as the class the live AC-016 control requires.
  assert_contains "$OUT" 'Failure modes section ended at narrative before any mapping row'
  assert_not_contains "$OUT" 'missing, extra, duplicate or unknown FM/INV test binding'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: post-narrative mapping is not evidence'
  # The same shape with prose between the section and rows that would otherwise
  # be complete: rows are dropped, so it is truncation, not a row mismatch.
  file="$SANDBOX/narrative-splits-rows.txt"
  {
    printf 'Verification-Return: 1\nTask: T001\nCaptures: %s\nSummary: ' "$cap"
    cat "$spec/notes/captures/$cap/summary.txt"
    printf 'Failure modes:\nThe rows below map every required row.\n'
    printf 'FM-001, tests/check.sh::test_ac_001_shared, %s\n' "$cap"
  } > "$file"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$file"
  assert_contains "$OUT" 'Failure modes section ended at narrative'
  assert_eq "$before" "$(cat "$spec/tasks.md")"
  # Permitted trailing narrative whose first token is an FM or INV identifier
  # is prose, not a malformed row: it must not block a complete return.
  local token
  for token in 'FM-002 was excluded for this task; see plan 4.2.' \
               'INV-002 was excluded for this task; see plan 4.2.' \
               'FM-002 tests/check.sh::test_ac_001_shared was not required here.'
  do
    file="$SANDBOX/narrative-token.txt"
    { cat "$base"; printf '%s\n' "$token"; } > "$file"
    bash -c '. "$1"; vf_return_parse "$2" "$3"' _ "$SCRIPTS/verification-lib.sh" "$file" "$SANDBOX/parsed-token" \
      || t_fail "AC-022: trailing narrative was refused: $token"
    assert_eq 1 "$(tr '\000' '\n' < "$SANDBOX/parsed-token" | grep -c '^mapping$')" \
      "AC-022: trailing narrative lost the mapping row: $token"
  done
  # A well-formed extra row is still an extra binding, not prose.
  file="$SANDBOX/narrative-extra-row.txt"
  { cat "$base"; printf 'FM-999, tests/check.sh::test_ac_001_shared, %s\n' "$cap"; } > "$file"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$file"
  assert_contains "$OUT" 'missing, extra, duplicate or unknown FM/INV test binding'
  assert_eq "$before" "$(cat "$spec/tasks.md")"
  # Leading and trailing narrative around a complete block accepts and ticks.
  file="$SANDBOX/narrative-ok.txt"
  {
    printf 'Picking up T001 now; the suite is green.\n\n'
    cat "$base"
    printf '\nAll requested verification is complete.\n'
    printf 'FM-002 was excluded for this task; see plan 4.2.\n'
  } > "$file"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$file"
  assert_contains "$OUT" 'accept accepted'
  assert_contains "$(cat "$spec/tasks.md")" '- [x] **T001**'
}

# AC-022: only a plan-declared manual family can use artifact-backed acceptance.
test_manual_acceptance() {
  local spec repo digest before
  spec="$(make_verification_git_dir manual)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  mkdir -p "$repo/artifacts"
  printf observed-release > "$repo/artifacts/release.txt"
  digest="$(shasum -a 256 < "$repo/artifacts/release.txt" | awk '{print $1}')"
  cat > "$SANDBOX/manual-return" <<EOF
Verification-Return: 1
Task: T004
Captures: none
Summary: observed release artifact
Manual observation: release-observation, artifacts/release.txt, $digest, fixture-observer, 2026-09-06T12:00:00Z, PASS: release matches expectation
Failure modes:
INV-001, release-observation, manual
EOF
  before="$(cat "$spec/tasks.md")"
  printf corrupted >> "$repo/artifacts/release.txt"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T004 "$SANDBOX/manual-return"
  assert_eq "$before" "$(cat "$spec/tasks.md")"
  printf observed-release > "$repo/artifacts/release.txt"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T004 "$SANDBOX/manual-return"
  assert_contains "$(cat "$spec/tasks.md")" '- [x] **T004**'
  sed 's/Task: T004/Task: T001/' "$SANDBOX/manual-return" > "$SANDBOX/automated-bypass"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/automated-bypass"
  assert_contains "$(cat "$spec/tasks.md")" '- [ ] **T001**'
}

test_prepared_before_recovery() {
  local spec repo cap receipt
  spec="$(make_verification_git_dir recovery)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  cp "$spec/tasks.md" "$SANDBOX/before-tasks"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  accept_return "$spec" T001 "$cap" "$SANDBOX/return"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/return"
  for receipt in "$spec/notes/verification/accepted/T001"/ACC-*; do rm "$receipt/COMMITTED"; done
  cp "$SANDBOX/before-tasks" "$spec/tasks.md"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/return"
  assert_contains "$(cat "$spec/tasks.md")" '- [x] **T001**'
  for receipt in "$spec/notes/verification/accepted/T001"/ACC-*; do rm "$receipt/COMMITTED"; done
  printf '\nconcurrent semantic edit\n' >> "$spec/tasks.md"
  cp "$spec/tasks.md" "$SANDBOX/concurrent-tasks"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/return"
  assert_contains "$OUT" 'neither prepared before nor after'
  run_rc 0 cmp "$SANDBOX/concurrent-tasks" "$spec/tasks.md"
}

# AC-007: real checkers and suite commands execute in the existing worktree.
floor_fixture() {
  local spec="$1" repo kit check counter
  repo="$(cd "$spec/../../.." && pwd -P)"
  kit="$SANDBOX/floor-kit-$(basename "$repo")"
  mkdir -p "$kit"
  # The kit's scripts as the input identity enumerates them (copy_kit's directory selector), so a
  # developer's ignored entry under scripts/ never arrives (O-015 second review).
  copy_kit "$KIT_DIR" "$kit" scripts || fixture_build_failed 'floor_fixture kit scripts'
  for check in sdd-analyze spec-ac-coverage spec-evidence; do
    mv "$kit/scripts/$check.sh" "$kit/scripts/$check-real.sh"
    counter="$SANDBOX/$check-count"
    printf '#!/usr/bin/env bash\nprintf x >> %q\nexec bash %q "$@"\n' "$counter" "$kit/scripts/$check-real.sh" > "$kit/scripts/$check.sh"
  done
  printf '\nprintf x >> %q\n' "$SANDBOX/suite-count" >> "$repo/tests/check.sh"
  printf '#!/usr/bin/env bash\n# AC-002 AC-003 AC-004\nprintf x >> %q\nprintf "static passed\\n"\n' "$SANDBOX/static-count" > "$repo/tests/static.sh"
  cat > "$repo/.specify/stack.yml" <<'EOF'
stacks: []
gate_checks:
  - 'bash tests/check.sh'
  - 'bash tests/static.sh'
reuse_checks: []
verification_tools:
  - 'bash'
verification_inputs: []
EOF
  printf '%s\n' "$kit/scripts/spec-gate.sh"
}

test_floor() {
  local spec repo gate id records check
  spec="$(make_verification_git_dir floor)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  gate="$(floor_fixture "$spec")"
  run_rc 0 bash "$gate" floor "$spec"
  assert_contains "$OUT" 'executed=5'
  id="$(printf '%s' "$OUT" | sed -n 's/^result=\([^ ]*\).*/\1/p')"
  records="$spec/notes/verification/floors/$id/commands.nul"
  for check in sdd-analyze spec-ac-coverage spec-evidence; do
    assert_eq x "$(cat "$SANDBOX/$check-count")" "AC-007: $check executed"
    assert_contains "$(tr '\000' '\n' < "$records")" "checker:$check"
  done
  assert_eq x "$(cat "$SANDBOX/suite-count")"
  assert_eq x "$(cat "$SANDBOX/static-count")"
  assert_contains "$(cat "$spec/notes/evidence.md")" '## GATE-FLOOR'
  # Commands without explicit local opt-in still rerun.
  run_rc 0 bash "$gate" floor "$spec"
  assert_eq xx "$(cat "$SANDBOX/suite-count")"
  printf '\nexit 7\n' >> "$repo/tests/static.sh"
  run_rc 7 bash "$gate" floor "$spec"
  assert_contains "$OUT" 'exit=7'
  [[ ! -e "$SANDBOX/model-called" ]] || t_fail 'AC-007: failing floor dispatched model'
  printf 'stacks: []\n' > "$repo/.specify/stack.yml"
  run_rc 3 bash "$gate" floor "$spec"
  assert_contains "$OUT" 'missing nonempty gate_checks'
  # A proper frontmatter worktree mismatch fails before any command runs.
  awk '/^branch: none$/ {print; print "worktree: /nonexistent/spec-worktree"; next} {print}' "$spec/STATUS.md" > "$SANDBOX/status"
  cp "$SANDBOX/status" "$spec/STATUS.md"
  run_rc 3 bash "$gate" floor "$spec"
  assert_contains "$OUT" 'worktree mismatch'
  rm -f "$SANDBOX/"*-count
  reuse_floor_cases
}

# AC-008: completed-through proof and retained bindings gate the next stage.
test_checkpoints() {
  local spec repo cap checkpoint observed start end
  spec="$(make_verification_git_dir checkpoint)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  cat >> "$repo/.specify/stack.yml" <<'EOF'
checkpoints:
  Backend:
    - 'false | true'
EOF
  run_rc 1 bash -c 'bash "$1" checkpoint "$2" Backend && touch "$3"' _ "$SCRIPTS/spec-gate.sh" "$spec" "$SANDBOX/next-stage"
  [[ ! -e "$SANDBOX/next-stage" ]] || t_fail 'AC-008: failing pipeline advanced stage'
  sed '/^checkpoints:/,$d' "$repo/.specify/stack.yml" > "$SANDBOX/stack"
  cp "$SANDBOX/stack" "$repo/.specify/stack.yml"
  # Future ACs, not-yet-created tests and the explicit T005 integration owner
  # do not become gaps before their stages complete.
  run_rc 0 "$SCRIPTS/spec-gate.sh" checkpoint "$spec" Backend
  assert_contains "$OUT" 'no checkpoint commands'
  # AC-008: the sealed interval includes execution, not just publication time.
  export CHECKPOINT_OBSERVATION="$SANDBOX/checkpoint-observed"
  cat > "$repo/tests/checkpoint-time.sh" <<'EOF'
date -u +%Y-%m-%dT%H:%M:%SZ > "$CHECKPOINT_OBSERVATION"
sleep 1
EOF
  cat >> "$repo/.specify/stack.yml" <<'EOF'
checkpoints:
  Backend:
    - 'bash tests/checkpoint-time.sh'
EOF
  run_rc 0 "$SCRIPTS/spec-gate.sh" checkpoint "$spec" Backend
  checkpoint="$(printf '%s' "$OUT" | sed -n 's/^result=\([^ ]*\).*/\1/p')"
  . "$SCRIPTS/verification-lib.sh"
  run_rc 0 vf_integrity "$spec/notes/verification/checkpoints/$checkpoint" meta.nul commands.nul bindings.nul inputs.nul roots.nul coverage.nul
  vf_meta_load "$spec/notes/verification/checkpoints/$checkpoint/meta.nul" 'version id kind stage start end source exit' || t_fail 'checkpoint metadata'
  start="$(vf_meta_get start)"; end="$(vf_meta_get end)"
  observed="$(cat "$CHECKPOINT_OBSERVATION")"
  [[ -n "$start" && ! "$start" > "$observed" && "$observed" < "$end" ]] || t_fail 'checkpoint interval omits command execution'
  cp "$SANDBOX/stack" "$repo/.specify/stack.yml"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  accept_return "$spec" T001 "$cap" "$SANDBOX/return"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/return"
  run_rc 0 "$SCRIPTS/spec-gate.sh" checkpoint "$spec" Backend
  assert_contains "$OUT" 'completed-task coverage checked'
  run_rc 0 "$SCRIPTS/spec-ac-coverage.sh" "$spec" --through-stage Backend
  cp "$repo/tests/check.sh" "$SANDBOX/check-before"
  sed 's/test_ac_001_shared/renamed_without_binding/g' "$repo/tests/check.sh" > "$SANDBOX/check"
  cp "$SANDBOX/check" "$repo/tests/check.sh"
  run_rc 3 "$SCRIPTS/spec-gate.sh" checkpoint "$spec" Backend
  assert_contains "$OUT" 'unknown test'
  cp "$SANDBOX/check-before" "$repo/tests/check.sh"

  sed 's/REQ-001, AC-001, FM-001/REQ-001, AC-001/' "$spec/tasks.md" > "$SANDBOX/tasks"
  cp "$SANDBOX/tasks" "$spec/tasks.md"
  run_rc 3 "$SCRIPTS/spec-gate.sh" checkpoint "$spec" Backend
  assert_contains "$OUT" 'lost prior binding'
  [[ ! -e "$SANDBOX/next-stage" ]] || t_fail 'AC-008: lost binding advanced stage'
}

round_report() { # spec gate reservation-output report-file
  local spec="$1" gate="$2" reservation="$3" file="$4" n source floor stamp id text digest tmp
  n="$(printf '%s' "$reservation" | sed -n 's/^round=\([^ ]*\).*/\1/p')"
  source="$(printf '%s' "$reservation" | sed -n 's/.* source=\([^ ]*\).*/\1/p')"
  floor="$(printf '%s' "$reservation" | sed -n 's/.* floor=\([^ ]*\).*/\1/p')"
  stamp="$(printf '%s' "$reservation" | sed -n 's/.* reserved=\([^ ]*\).*/\1/p')"
  {
    printf '## Round %s\n**Round:** %s\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n' "$n" "$n" "$stamp" "$source" "$floor"
    if [[ "$gate" == opponent ]]; then
      printf '**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 0\n### What I attacked\nFixture protocol examined; application semantics remain outside this sandbox.\n### Held up / follow-up tasks\nNothing held up; the fixture protocol cleared.\n'
    else
      printf '**Verdict:** NEEDS WORK\n### Summary\nFixture matrix only; no criterion has real evidence in this sandbox.\n### Constitution check\n- Not exercised by this fixture.\n### Re-run conditions\n- Re-invoke once the fixture supplies evidence.\n### AC matrix\n| AC | Criterion / revision | Evidence | Affected inputs | Verdict |\n|---|---|---|---|---|\n'
      tmp="$SANDBOX/round-acs"
      bash -c '. "$1"; vf_ac_catalog "$2" "$3"' _ "$SCRIPTS/verification-lib.sh" "$spec" "$tmp"
      while IFS= read -r -d '' id && IFS= read -r -d '' text && IFS= read -r -d '' digest; do
        printf '| %s | %s; sha256:%s | missing | %s | MISSING |\n' "$id" "$text" "$digest" "$source"
      done < "$tmp"
    fi
    printf '<!-- gate-round-end: %s:%s -->\n' "$gate" "$n"
  } > "$file"
}

# AC-013/AC-012/FM-019 — O-012, round-record-reparse-divergence, END TO END.
# The only semantic guard on the reality-check side is that a READY verdict may
# not stand over a MISSING or FAIL row. vf_reports parses, validates and emits
# the verdict once; vf_gate_round must hand THAT value to vf_reality_matrix
# rather than let a second parser re-derive it. These cases drive the real CLI,
# so the value under test is the one the catalog emitted and not one a caller
# supplied — a direct call to vf_reality_matrix cannot prove this half.
#
# Negatives are per DIVERGENCE CLASS, derived from what the identity production
# at verification-lib.sh:1083-1094 tolerates and a naive re-parse does not:
# surrounding whitespace that value() strips (:968), and quoted content that
# vf_quoted skips (:1066) while vf_report_block deliberately keeps. Each must
# be refused because the CATALOG says READY, whatever the text spells.
round_verdict_source_cases() {
  local spec cli reservation report insert shape
  spec="$(make_verification_git_dir rcverdict)"
  cli="$(floor_fixture "$spec")"
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" reality-check
  reservation="$OUT"
  report="$SANDBOX/rc-report.md"
  round_report "$spec" reality-check "$reservation" "$report"
  assert_contains "$(cat "$report")" '| MISSING |' 'fixture lost the unsupported rows it exists to carry'
  # Whitespace the catalog tolerates. Two spaces after the marker read as
  # " READY" to a one-space sed, and no space at all read as nothing.
  for shape in two-space no-space; do
    case "$shape" in
      two-space) sed 's/^\*\*Verdict:\*\* NEEDS WORK$/**Verdict:**  READY/' "$report" > "$SANDBOX/rc-$shape";;
      no-space)  sed 's/^\*\*Verdict:\*\* NEEDS WORK$/**Verdict:**READY/' "$report" > "$SANDBOX/rc-$shape";;
    esac
    run_rc 3 bash "$cli" round "$spec" reality-check --complete "$SANDBOX/rc-$shape"
    assert_contains "$OUT" 'matrix: READY contains unsupported row' \
      "AC-013: a $shape READY verdict cleared a matrix carrying MISSING rows"
  done
  # Quoted content. vf_reports skips the fenced line, so no duplicate-identity
  # error fires and the catalog still says READY; vf_report_block keeps it,
  # because the sealed digest must cover quoted lines. A second parser over
  # that block sees two verdicts and matches neither.
  insert="$SANDBOX/rc-fenced-verdict"
  printf '\140\140\140markdown\n**Verdict:** NEEDS WORK\n\140\140\140\n' > "$insert"
  sed 's/^\*\*Verdict:\*\* NEEDS WORK$/**Verdict:** READY/' "$report" > "$SANDBOX/rc-fenced"
  awk -v insert="$insert" '
    /^### Constitution check$/ {while ((getline line < insert) > 0) print line; close(insert)}
    {print}
  ' "$SANDBOX/rc-fenced" > "$SANDBOX/rc-fenced.tmp" && mv "$SANDBOX/rc-fenced.tmp" "$SANDBOX/rc-fenced"
  run_rc 3 bash "$cli" round "$spec" reality-check --complete "$SANDBOX/rc-fenced"
  assert_contains "$OUT" 'matrix: READY contains unsupported row' \
    'AC-013: a fenced duplicate verdict cleared a matrix carrying MISSING rows'
  # Control, not a discriminator: a verdict the catalog refuses never reaches
  # the matrix at all, so the catalog stays the single authority on the value.
  sed 's/^\*\*Verdict:\*\* NEEDS WORK$/**Verdict:** Ready/' "$report" > "$SANDBOX/rc-unknown"
  run_rc 3 bash "$cli" round "$spec" reality-check --complete "$SANDBOX/rc-unknown"
  assert_contains "$OUT" 'invalid reality-check verdict' \
    'AC-013: an unknown verdict was not refused by the catalog'
  # Control: the shipped shape still completes, so the guard refuses the
  # attack rather than the gate. The reservation survived every refusal above.
  run_rc 0 bash "$cli" round "$spec" reality-check --complete "$report"
  assert_contains "$OUT" 'round completed gate=reality-check round=1 verdict=NEEDS WORK'
}

# AC-009: both gates reserve/count canonical invocations; exact authorization
# consumes one round only. A pending invocation is never silently reset.
test_rounds() {
  round_authorization_cases
  round_preamble_cases
  round_verdict_source_cases
  local spec gate cli n reservation stamp report
  spec="$(make_verification_git_dir rounds)"
  cli="$(floor_fixture "$spec")"
  run_rc 0 bash "$cli" floor "$spec"
  report="$SANDBOX/report.md"
  for gate in opponent reality-check; do
    for n in 1 2 3; do
      run_rc 0 bash "$cli" round "$spec" "$gate"
      reservation="$OUT"
      assert_contains "$OUT" "round=$n gate=$gate"
      run_rc 3 bash "$cli" round "$spec" "$gate"
      assert_contains "$OUT" 'interrupted invocation'
      round_report "$spec" "$gate" "$reservation" "$report"
      if [[ "$n" == 1 ]]; then
        sed 's/^\*\*Floor:\*\*.*/**Floor:** FLOOR-forged/' "$report" > "$SANDBOX/bad-report"
        run_rc 3 bash "$cli" round "$spec" "$gate" --complete "$SANDBOX/bad-report"
        assert_contains "$OUT" 'identities/timestamp differ'
      fi
      if [[ "$n" == 2 ]]; then
        # Simulate interruption after canonical append but before completion digest.
        printf '\n' >> "$spec/notes/$gate.md"
        cat "$report" >> "$spec/notes/$gate.md"
      fi
      run_rc 0 bash "$cli" round "$spec" "$gate" --complete "$report"
      assert_contains "$OUT" 'round completed'
    done
    run_rc 4 bash "$cli" round "$spec" "$gate"
    assert_contains "$OUT" 'authorization denied'
  done
  # AC-009/AC-018 — O-002 round 7, through the shipped entrypoint rather than
  # the library function, because `spec-gate.sh waiver` exists precisely so the
  # operator meets this diagnostic at the moment they write the entry. The
  # reviewer reproduced the defect here: with gate=Opponent the CLI listed four
  # unrelated historical lines and never mentioned the line just written.
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  cp "$spec/STATUS.md" "$SANDBOX/status-before-waiver"
  printf '\n## Decisions log\n- %s — waiver: gate=Opponent; round=4; after=3; by=fixture-user; reason=one capitalized letter\n' "$stamp" >> "$spec/STATUS.md"
  run_rc 4 bash "$cli" waiver "$spec" opponent 4
  assert_contains "$OUT" 'gate="Opponent" names no known gate' \
    'AC-018: the waiver checker refused the line it was pointed at without naming it'
  assert_not_contains "$OUT" 'no candidate authorization line for this gate was found' \
    'AC-018: the waiver checker asserted no candidate exists while one sat in the log'
  # The same checker reports rounds that need no authorization, and an
  # already-sealed round as completed rather than denied, so a correct answer
  # is never dressed as a refusal.
  run_rc 0 bash "$cli" waiver "$spec" opponent 2
  assert_contains "$OUT" 'already completed'
  run_rc 0 bash "$cli" waiver "$spec" reality-check 3
  assert_contains "$OUT" 'already completed'
  run_rc 2 bash "$cli" waiver "$spec" not-a-gate 4
  assert_contains "$OUT" 'unknown gate'
  cp "$SANDBOX/status-before-waiver" "$spec/STATUS.md"
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '\n## Decisions log\n- %s — waiver: gate=opponent; round=4; after=3; by=fixture-user; reason=exercise scoped authorization\n' "$stamp" >> "$spec/STATUS.md"
  # The corrected line validates through the same checker, reserving nothing:
  # the round below is still reserved by `round`, against a fresh floor.
  run_rc 0 bash "$cli" waiver "$spec" opponent 4
  assert_contains "$OUT" 'authorized: opponent round 4'
  [[ ! -d "$spec/notes/verification/rounds/opponent/ROUND-4" ]] || t_fail 'AC-018: the waiver check reserved a round'
  run_rc 4 bash "$cli" round "$spec" reality-check
  run_rc 3 bash "$cli" round "$spec" opponent
  assert_contains "$OUT" 'floor stale'
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" opponent
  reservation="$OUT"
  round_report "$spec" opponent "$reservation" "$report"
  run_rc 0 bash "$cli" round "$spec" opponent --complete "$report"
  run_rc 4 bash "$cli" round "$spec" opponent
  assert_contains "$OUT" 'round 5'
  # Canonical tampering is a named recovery condition, never a count reset.
  printf '\n## Round nonsense\n' >> "$spec/notes/opponent.md"
  run_rc 3 bash "$cli" round "$spec" opponent
  assert_contains "$OUT" 'reconcile canonical records'
}

# AC-007/AC-008/AC-020: execute a local suite once across checkpoints and
# both floors; bookkeeping preserves reuse, unknown policy still executes.
reuse_floor_cases() {
  local spec repo gate cap file
  spec="$(make_verification_git_dir reuse)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  gate="$(floor_fixture "$spec")"
  sed 's/^reuse_checks: \[\]/reuse_checks:\n  - '\''bash tests\/check.sh'\''/' "$repo/.specify/stack.yml" > "$SANDBOX/reuse-stack"
  cp "$SANDBOX/reuse-stack" "$repo/.specify/stack.yml"
  printf "checkpoints:\n  Backend:\n    - 'bash tests/check.sh'\n" >> "$repo/.specify/stack.yml"
  run_rc 0 bash "$gate" checkpoint "$spec" Backend
  run_rc 0 bash "$gate" floor "$spec"
  run_rc 0 bash "$gate" floor "$spec"
  assert_eq x "$(cat "$SANDBOX/suite-count")" 'unchanged suite runs once across checkpoint and gates'
  assert_eq xx "$(cat "$SANDBOX/static-count")" 'unknown/static policy reruns'
  assert_eq xx "$(cat "$SANDBOX/spec-evidence-count")" 'integrity runs at every floor'
  assert_contains "$OUT" 'cache-hits=1'
  printf '\n# changed\n' >> "$repo/src/parser.sh"
  run_rc 0 bash "$gate" floor "$spec"
  assert_eq xx "$(cat "$SANDBOX/suite-count")"
  # AC-016/AC-020: undeclared harness environment is outside the closed input
  # identity and does not invalidate a reusable floor across invocations.
  run_rc 0 env VF_FIXTURE_ENV=changed bash "$gate" floor "$spec"
  assert_eq xx "$(cat "$SANDBOX/suite-count")"
  # A damaged candidate must cause a real refresh, not poison every later run.
  for file in "$spec"/notes/captures/CAP-*/argv.nul; do
    if tr '\000' '\n' < "$file" | grep -Fx 'bash tests/check.sh' >/dev/null; then
      cap="${file%/argv.nul}"; printf tampered >> "$cap/output.log"
    fi
  done
  run_rc 0 bash "$gate" floor "$spec"
  assert_eq xxx "$(cat "$SANDBOX/suite-count")"
}


# AC-009 (FM-016): a round-2 report that carries anything before its heading
# would be absorbed into round 1 by vf_report_block, silently changing a sealed
# digest and wedging every later reserve/complete/probe call.
round_preamble_cases() {
  local spec cli report reservation sealed canonical
  spec="$(make_verification_git_dir preamble)"
  cli="$(floor_fixture "$spec")"
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" opponent
  reservation="$OUT"
  report="$SANDBOX/preamble-round1"
  round_report "$spec" opponent "$reservation" "$report"
  run_rc 0 bash "$cli" round "$spec" opponent --complete "$report"
  sealed="$(cat "$spec/notes/verification/rounds/opponent/ROUND-1/report.sha256")"
  canonical="$(cat "$spec/notes/opponent.md")"
  run_rc 0 bash "$cli" round "$spec" opponent
  reservation="$OUT"
  round_report "$spec" opponent "$reservation" "$SANDBOX/preamble-round2"
  { printf 'Here is my report for round 2.\n'; cat "$SANDBOX/preamble-round2"; } > "$SANDBOX/preamble-bad"
  run_rc 3 bash "$cli" round "$spec" opponent --complete "$SANDBOX/preamble-bad"
  assert_contains "$OUT" 'content after the round completion marker'
  assert_eq "$canonical" "$(cat "$spec/notes/opponent.md")" 'AC-009: refused round 2 rewrote the canonical file'
  assert_eq "$sealed" "$(cat "$spec/notes/verification/rounds/opponent/ROUND-1/report.sha256")"
  # AC-009/FM-016: a totals line and a legacy review heading are consumed by
  # their own rules, so both used to reach `next` ahead of the after-marker
  # guard and were caught only by the later sealed-digest check. Every shape of
  # content after a completed marker must get the guard's own diagnostic.
  local aftermarker
  for aftermarker in totals legacy; do
    case "$aftermarker" in
      totals) printf '**Blocking:** 1 · **Minor:** 0\n' > "$SANDBOX/after-line";;
      legacy) printf '# Opponent review — quoted history\n' > "$SANDBOX/after-line";;
    esac
    cat "$SANDBOX/after-line" "$SANDBOX/preamble-round2" > "$SANDBOX/after-$aftermarker"
    run_rc 3 bash "$cli" round "$spec" opponent --complete "$SANDBOX/after-$aftermarker"
    assert_contains "$OUT" 'content after the round completion marker' "AC-009: $aftermarker line bypassed the after-marker guard"
    assert_eq "$sealed" "$(cat "$spec/notes/verification/rounds/opponent/ROUND-1/report.sha256")" "AC-009: $aftermarker shifted the sealed digest"
  done
  # Quoting does not exempt a preamble from the after-marker rule. Fenced,
  # HTML-commented and blockquoted text is still absorbed by the block
  # accumulator into the sealed round above it, so each shape must get the
  # validator's file:line diagnostic before the later digest guard.
  local shape
  for shape in fenced commented blockquoted; do
    case "$shape" in
      fenced)     printf '\140\140\140text\nHere is my report for round 2.\n\140\140\140\n' > "$SANDBOX/preamble-$shape";;
      commented)  printf '<!--\nHere is my report for round 2.\n-->\n' > "$SANDBOX/preamble-$shape";;
      blockquoted) printf '> Here is my report for round 2.\n' > "$SANDBOX/preamble-$shape";;
    esac
    cat "$SANDBOX/preamble-round2" >> "$SANDBOX/preamble-$shape"
    run_rc 3 bash "$cli" round "$spec" opponent --complete "$SANDBOX/preamble-$shape"
    assert_contains "$OUT" 'content after the round completion marker' \
      "AC-009: $shape preamble bypassed the after-marker guard"
    assert_contains "$OUT" 'round-check.' \
      "AC-009: $shape preamble diagnostic omitted its temporary file"
    assert_contains "$OUT" 'combined.md:' \
      "AC-009: $shape preamble diagnostic omitted its line-bearing report path"
    assert_eq "$canonical" "$(cat "$spec/notes/opponent.md")" "AC-009: $shape preamble rewrote the canonical file"
    assert_eq "$sealed" "$(cat "$spec/notes/verification/rounds/opponent/ROUND-1/report.sha256")"
  done
  # The reservation survives, so the corrected report still completes and the
  # round-1 digest is untouched: recovery needs no edit to sealed gate state.
  run_rc 0 bash "$cli" round "$spec" opponent --complete "$SANDBOX/preamble-round2"
  assert_contains "$OUT" 'round completed'
  assert_eq "$sealed" "$(cat "$spec/notes/verification/rounds/opponent/ROUND-1/report.sha256")" \
    'AC-009: completing round 2 moved the sealed round 1'
  # A later reserve still works, proving nothing was wedged.
  run_rc 0 bash "$cli" round "$spec" opponent
  assert_contains "$OUT" 'round=3'
}

round_authorization_cases() {
  local spec stamp
  spec="$(make_verification_git_dir authorization)"
  . "$SCRIPTS/lib.sh"
  . "$SCRIPTS/verification-lib.sh"
  printf '\n## Decisions log\n- 2026-01-02T00:00:00Z — waiver: gate=opponent; round=4; after=3; by=fixture-user; reason=test exact scope\n' >> "$spec/STATUS.md"
  run_rc 0 vf_round_authorized "$spec" opponent 4 2026-01-01T23:59:59Z
  run_rc 4 vf_round_authorized "$spec" opponent 5 2026-01-01T23:59:59Z
  run_rc 4 vf_round_authorized "$spec" reality-check 4 2026-01-01T23:59:59Z
  run_rc 4 vf_round_authorized "$spec" opponent 4 2026-01-02T00:00:00Z
  run_rc 4 vf_round_authorized "$spec" opponent 4 ''
  for stamp in 2026-02-30T00:00:00Z 9999-01-01T00:00:00Z; do
    printf '\n- %s — waiver: gate=reality-check; round=4; after=3; by=fixture-user; reason=invalid clock\n' "$stamp" >> "$spec/STATUS.md"
  done
  run_rc 4 vf_round_authorized "$spec" reality-check 4 2026-01-01T00:00:00Z
  # Exact current accepted revision can authorize one round, then expires on edit.
  sed '/^verification_contract:/a\
status: accepted
' "$spec/spec.md" > "$SANDBOX/spec-revision"
  cp "$SANDBOX/spec-revision" "$spec/spec.md"
  printf '\n- 2026-01-02T00:00:00Z — spec-revision: gate=reality-check; round=4; after=3; by=fixture-user; revision=sha256:%s; reason=accepted fixture revision\n' "$(vf_hash "$spec/spec.md")" >> "$spec/STATUS.md"
  run_rc 0 vf_round_authorized "$spec" reality-check 4 2026-01-01T00:00:00Z
  printf '\nChanged criterion\n' >> "$spec/spec.md"
  run_rc 4 vf_round_authorized "$spec" reality-check 4 2026-01-01T00:00:00Z
  # AC-009: the authorization is the exact whole line. Every variant below
  # carries valid fields for opponent round 5, so only the grammar can deny it.
  local variant
  for variant in \
    '- 2026-01-02T00:00:00Z THIS-IS-NOT-THE-GRAMMAR — ' \
    '- note 2026-01-02T00:00:00Z — ' \
    '- 2026-01-02T00:00:00Z - ' \
    '- 2026-01-02T00:00:00Z—' \
    '- 2026-1-2T00:00:00Z — ' \
    '- 2026-01-02T00:00:00Z — please apply this ' \
    '  - 2026-01-02T00:00:00Z — '
  do
    printf '\n%swaiver: gate=opponent; round=5; after=4; by=fixture-user; reason=malformed authorization\n' \
      "$variant" >> "$spec/STATUS.md"
    run_rc 4 vf_round_authorized "$spec" opponent 5 2026-01-01T23:59:59Z
    assert_contains "$OUT" 'authorization denied' "AC-009: accepted malformed line [$variant]"
  done
  # O-002 round 6: fail-closed is the safe direction, but a parser that names
  # NOTHING turns an authoring error into an unexplained refusal. The recorded
  # cost of that silence on this spec was a handoff asserting round 6 was
  # already authorized when its waiver split into six fields, and a cold floor
  # re-execution. Every refusal must name the line and the failing clause.
  local diag_spec
  diag_spec="$SANDBOX/authz-diagnostics"
  mkdir -p "$diag_spec"
  printf -- '---\nstatus: accepted\n---\n\n## Decisions log\n' > "$diag_spec/STATUS.md"
  printf -- '- 2026-01-02T00:00:00Z — waiver: gate=opponent; round=5; after=4; by=fixture-user; reason=a reason with a semicolon; and a trailing clause\n' >> "$diag_spec/STATUS.md"
  run_rc 4 vf_round_authorized "$diag_spec" opponent 5 2026-01-01T23:59:59Z
  assert_contains "$OUT" 'STATUS.md:6' 'AC-009: refusal did not name the offending line number'
  assert_contains "$OUT" 'found 6' 'AC-009: refusal did not name the field count it read'
  assert_contains "$OUT" 'inside reason= splits the entry' 'AC-009: refusal did not name the failing clause'
  # A refusal for a DIFFERENT reason names that reason instead, so the
  # diagnostic discriminates rather than printing one catch-all string.
  printf -- '- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=9; after=8; by=fixture-user; reason=wrong round entirely\n' >> "$diag_spec/STATUS.md"
  run_rc 4 vf_round_authorized "$diag_spec" opponent 5 2026-01-01T23:59:59Z
  assert_contains "$OUT" 'authorizes round=9, not round=5' 'AC-009: refusal did not distinguish a wrong-round candidate'
  # And when nothing resembling an authorization exists, say THAT rather than
  # listing candidates that were never there.
  printf -- '---\nstatus: accepted\n---\n\n## Decisions log\n- 2026-01-02T00:00:00Z — an ordinary decision entry\n' > "$diag_spec/STATUS.md"
  run_rc 4 vf_round_authorized "$diag_spec" opponent 5 2026-01-01T23:59:59Z
  assert_contains "$OUT" 'no candidate authorization line for this gate was found' \
    'AC-009: refusal claimed candidates when the log had none'

  # O-002 round 7. The obligation is derived from the production the parser
  # enforces — `- <UTC> — <kind>: gate=<g>; round=<n>; after=<n-1>; by=<b>;
  # reason=<r>[; revision=<v>]` — where EVERY clause has exactly one refusal
  # path and no refusal path may be silent. The gate clause was the one taking
  # a bare `next`, so a single capitalized letter made the tail report that NO
  # candidate exists while listing four unrelated historical lines and omitting
  # the one just written: a message that asserts the opposite of the truth.
  # The clause also needs the one DISTINCTION the grammar supplies — gate=<g>
  # ranges over the gates that exist, so another KNOWN gate is that gate's
  # record and is correctly silent, while anything else is a malformed
  # candidate for the gate being asked about. Cases below cover both sides plus
  # the kind marker written without its trailing space.
  local slip
  for slip in capitalized trailing-space spaced-equals no-kind-space; do
    printf -- '---\nstatus: accepted\n---\n\n## Decisions log\n' > "$diag_spec/STATUS.md"
    case "$slip" in
      capitalized)    printf -- '- 2026-01-02T00:00:00Z — waiver: gate=Opponent; round=5; after=4; by=fixture-user; reason=one capitalized letter\n';;
      trailing-space) printf -- '- 2026-01-02T00:00:00Z — waiver: gate=opponent ; round=5; after=4; by=fixture-user; reason=one trailing space\n';;
      spaced-equals)  printf -- '- 2026-01-02T00:00:00Z — waiver: gate = opponent; round=5; after=4; by=fixture-user; reason=spaces around the equals\n';;
      no-kind-space)  printf -- '- 2026-01-02T00:00:00Z — waiver:gate=opponent; round=5; after=4; by=fixture-user; reason=no space after the kind marker\n';;
    esac >> "$diag_spec/STATUS.md"
    run_rc 4 vf_round_authorized "$diag_spec" opponent 5 2026-01-01T23:59:59Z
    assert_contains "$OUT" 'STATUS.md:6' "AC-009: the $slip slip was refused without naming its line"
    assert_not_contains "$OUT" 'no candidate authorization line for this gate was found' \
      "AC-009: the $slip slip was reported as no candidate at all"
    case "$slip" in
      capitalized)    assert_contains "$OUT" 'gate="Opponent" names no known gate' "AC-009: $slip named the wrong clause";;
      trailing-space) assert_contains "$OUT" 'gate="opponent " names no known gate' "AC-009: $slip named the wrong clause";;
      spaced-equals)  assert_contains "$OUT" 'first field must be gate=' "AC-009: $slip named the wrong clause";;
      no-kind-space)  assert_contains "$OUT" 'must be followed by one space before gate=' "AC-009: $slip named the wrong clause";;
    esac
  done
  # The distinguishing control: a legitimately other-gate entry is that gate's
  # record, not a malformed candidate for this one, and must stay silent — or
  # every reality-check waiver becomes noise in every opponent refusal.
  printf -- '---\nstatus: accepted\n---\n\n## Decisions log\n- 2026-01-02T00:00:00Z — waiver: gate=reality-check; round=5; after=4; by=fixture-user; reason=another gate record\n' > "$diag_spec/STATUS.md"
  run_rc 4 vf_round_authorized "$diag_spec" opponent 5 2026-01-01T23:59:59Z
  assert_contains "$OUT" 'no candidate authorization line for this gate was found' \
    'AC-009: another gate authorization was listed as a refused candidate for this gate'
  # Control on the widened candidate detection: prose naming the tokens inside
  # inline code spans is documentation, not an authorization attempt. This kit's
  # own Decisions log carries exactly that line, and turning it into a refused
  # candidate would degrade every denial message this class exists to improve.
  printf -- '---\nstatus: accepted\n---\n\n## Decisions log\n- 2026-01-02 — round 4+ needs a `waiver:`/`spec-revision:` Decisions line — user chose\n' > "$diag_spec/STATUS.md"
  run_rc 4 vf_round_authorized "$diag_spec" opponent 5 2026-01-01T23:59:59Z
  assert_contains "$OUT" 'no candidate authorization line for this gate was found' \
    'AC-009: prose naming the waiver token became a refused candidate'

  # Control: the same fields on an exact line do authorize, so the denials above
  # are the grammar failing closed and not round 5 being categorically refused.
  printf '\n- 2026-01-02T00:00:00Z — waiver: gate=opponent; round=5; after=4; by=fixture-user; reason=exact grammar control\n' >> "$spec/STATUS.md"
  run_rc 0 vf_round_authorized "$spec" opponent 5 2026-01-01T23:59:59Z
  # AC-009: a byte-identical authorization reproduced inside a fence, a tilde
  # fence, a blockquote or an indented block is quoted text and authorizes
  # nothing. Round 6 has no live line, so only the grammar can deny these.
  local quoted
  for quoted in fenced tilde quote indent script style textarea pre doctype pi cdata; do
    case "$quoted" in
      fenced) printf '\n\140\140\140text\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=revoked, kept for the record\n\140\140\140\n' >> "$spec/STATUS.md";;
      tilde)  printf '\n~~~text\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=revoked, kept for the record\n~~~\n' >> "$spec/STATUS.md";;
      quote)  printf '\n> - 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=quoted for illustration\n' >> "$spec/STATUS.md";;
      indent) printf '\n    - 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=indented example\n' >> "$spec/STATUS.md";;
      # O-002 round 4: CommonMark HTML-block conditions 1, 3, 4 and 5. Their
      # content renders nowhere (script/style/<?/<!/CDATA) or renders as
      # literal quoted text (pre/textarea), so a waiver inside one is a line
      # no reader of STATUS.md can act on and must authorize nothing.
      script)   printf '\n<script>\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=revoked, hidden in a script element\n</script>\n' >> "$spec/STATUS.md";;
      style)    printf '\n<style>\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=revoked, hidden in a style element\n</style>\n' >> "$spec/STATUS.md";;
      textarea) printf '\n<textarea>\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=quoted inside a textarea\n</textarea>\n' >> "$spec/STATUS.md";;
      pre)      printf '\n<pre>\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=quoted inside a pre block\n</pre>\n' >> "$spec/STATUS.md";;
      doctype)  printf '\n<!DOCTYPE\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=hidden behind an unclosed doctype\n>\n' >> "$spec/STATUS.md";;
      pi)       printf '\n<?php\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=hidden in a processing instruction\n?>\n' >> "$spec/STATUS.md";;
      cdata)    printf '\n<![CDATA[\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=hidden in a CDATA section\n]]>\n' >> "$spec/STATUS.md";;
    esac
    run_rc 4 vf_round_authorized "$spec" opponent 6 2026-01-02T23:59:59Z
    assert_contains "$OUT" 'authorization denied' "AC-009: $quoted authorization was honored"
  done
  # Positive control for the derivation boundary: conditions 6 and 7 are
  # rendered prose a reader sees, so <details> is a record and DOES authorize.
  # Without this the suppression rule could swallow all raw HTML and still pass.
  printf '\n<details>\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=66; after=65; by=fixture-user; reason=visible inside a details block\n</details>\n' >> "$spec/STATUS.md"
  run_rc 0 vf_round_authorized "$spec" opponent 66 2026-01-02T23:59:59Z
  # An opener inside a matched inline code span is literal, exactly as for
  # comments -- otherwise documenting this rule in a Decisions entry would
  # suppress every later line of the log.
  printf '\n- prose mentioning `<script>` inline stays prose\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=67; after=66; by=fixture-user; reason=after an inline code span\n' >> "$spec/STATUS.md"
  run_rc 0 vf_round_authorized "$spec" opponent 67 2026-01-02T23:59:59Z
  # O-002 round 5: a condition-1 block ends only at the corresponding close.
  # A mismatched close is script content and cannot expose a hidden waiver.
  printf '\n<script>\n</style>\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=68; after=67; by=fixture-user; reason=hidden after a mismatched close\n</script>\n' >> "$spec/STATUS.md"
  run_rc 4 vf_round_authorized "$spec" opponent 68 2026-01-02T23:59:59Z
  assert_contains "$OUT" 'authorization denied' 'AC-009: mismatched HTML close exposed a hidden authorization'
  # Control: the same fields unquoted do authorize, so the denials above
  # are the quoting suppression and not round 6 being categorically refused.
  printf '\n- 2026-01-03T00:00:00Z — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=unquoted grammar control\n' >> "$spec/STATUS.md"
  run_rc 0 vf_round_authorized "$spec" opponent 6 2026-01-02T23:59:59Z
  # A spec-revision reproduced in a fence is suppressed on the same parser.
  printf '\n\140\140\140text\n- 2026-01-03T00:00:00Z — spec-revision: gate=opponent; round=7; after=6; by=fixture-user; revision=sha256:%s; reason=quoted revision\n\140\140\140\n' \
    "$(vf_hash "$spec/spec.md")" >> "$spec/STATUS.md"
  run_rc 4 vf_round_authorized "$spec" opponent 7 2026-01-02T23:59:59Z
  assert_contains "$OUT" 'authorization denied' 'AC-009: fenced spec-revision was honored'
  # AC-009/FM-016: one toggled flag is not the fence grammar. Markdown closes a
  # fenced block only with a run of the SAME character at least as long as the
  # opener and carrying no info string, so an inner shorter fence, another fence
  # character, a four-space-indented run or a run with an info string is all
  # content. A revoked authorization quoted inside such a nested example must
  # stay suppressed — the O-002 class reopening after T030o7's single boolean.
  local baseline nested
  baseline="$SANDBOX/status-nested.md"
  cp "$spec/STATUS.md" "$baseline"
  for nested in short-inner other-character indented-inner closer-with-info; do
    cp "$baseline" "$spec/STATUS.md"
    {
      printf '\n'
      case "$nested" in
        short-inner)      printf '\140\140\140\140markdown\n\140\140\140text\n';;
        other-character)  printf '\140\140\140markdown\n~~~text\n';;
        indented-inner)   printf '\140\140\140markdown\n    \140\140\140\n';;
        closer-with-info) printf '\140\140\140markdown\n\140\140\140 text\n';;
      esac
      printf -- '- 2026-01-04T00:00:00Z — waiver: gate=opponent; round=8; after=7; by=fixture-user; reason=revoked, quoted inside a nested example\n'
      case "$nested" in
        short-inner)      printf '\140\140\140\n\140\140\140\140\n';;
        other-character)  printf '~~~\n\140\140\140\n';;
        *)                printf '\140\140\140\n';;
      esac
    } >> "$spec/STATUS.md"
    run_rc 4 vf_round_authorized "$spec" opponent 8 2026-01-03T23:59:59Z
    assert_contains "$OUT" 'authorization denied' "AC-009: nested $nested authorization was honored"
  done
  # Control: the nested example closes, so a real unquoted line after it still
  # authorizes its exact round. Strict closing must not wedge suppression on.
  cp "$baseline" "$spec/STATUS.md"
  {
    printf '\n\140\140\140\140markdown\n\140\140\140text\n'
    printf -- '- 2026-01-04T00:00:00Z — waiver: gate=opponent; round=8; after=7; by=fixture-user; reason=revoked, kept as quoted history\n'
    printf '\140\140\140\n\140\140\140\140\n'
    printf -- '- 2026-01-04T00:00:01Z — waiver: gate=opponent; round=8; after=7; by=fixture-user; reason=live line after a closed nested example\n'
  } >> "$spec/STATUS.md"
  run_rc 0 vf_round_authorized "$spec" opponent 8 2026-01-03T23:59:59Z
  # The same tracker denies round 9: a granted round never carries forward.
  run_rc 4 vf_round_authorized "$spec" opponent 9 2026-01-04T00:00:02Z
  # AC-009/FM-016: an HTML comment is the idiom for disabling a line, and the
  # one quoting form this kit reads as data elsewhere. A commented-out waiver
  # is invisible in every rendered view of STATUS.md, so treating it as live is
  # strictly worse than the fence case. Tokens inside inline code spans are
  # prose about comments, not comments, or the canonical reports stop parsing.
  local commented
  for commented in block midline unclosed spec-revision; do
    cp "$baseline" "$spec/STATUS.md"
    {
      printf '\n'
      case "$commented" in
        block)         printf -- '<!--\n';;
        midline)       printf -- 'superseded, kept for the record <!--\n';;
        unclosed)      printf -- '<!--\n';;
        spec-revision) printf -- '<!--\n';;
      esac
      if [[ "$commented" == spec-revision ]]; then
        printf -- '- 2026-01-05T00:00:00Z — spec-revision: gate=opponent; round=10; after=9; by=fixture-user; revision=sha256:%s; reason=revoked revision\n' "$(vf_hash "$spec/spec.md")"
      else
        printf -- '- 2026-01-05T00:00:00Z — waiver: gate=opponent; round=10; after=9; by=fixture-user; reason=revoked, commented out\n'
      fi
      [[ "$commented" == unclosed ]] || printf -- '-->\n'
    } >> "$spec/STATUS.md"
    run_rc 4 vf_round_authorized "$spec" opponent 10 2026-01-04T23:59:59Z
    assert_contains "$OUT" 'authorization denied' "AC-009: $commented HTML-commented authorization was honored"
  done
  # AC-009/FM-016: comment state is the result of every transition, not the
  # first token on a line. In both shapes below the final opener stays live and
  # keeps the apparent waiver quoted.
  for commented in second-opener reopen-after-close; do
    cp "$baseline" "$spec/STATUS.md"
    if [[ "$commented" == second-opener ]]; then
      printf -- '\n<!-- first --> <!-- second\n' >> "$spec/STATUS.md"
    else
      printf -- '\n<!-- first\n--> <!-- second\n' >> "$spec/STATUS.md"
    fi
    printf -- '- 2026-01-05T00:00:00Z — waiver: gate=opponent; round=10; after=9; by=fixture-user; reason=revoked after the final opener\n-->\n' >> "$spec/STATUS.md"
    run_rc 4 vf_round_authorized "$spec" opponent 10 2026-01-04T23:59:59Z
    assert_contains "$OUT" 'authorization denied' "AC-009: $commented comment transition was ignored"
  done
  # Control: the same fields live authorize, and a line after a closed comment
  # is live again, so comment suppression neither refuses round 10 outright nor
  # wedges the rest of the log.
  cp "$baseline" "$spec/STATUS.md"
  {
    printf -- '\n<!--\n- 2026-01-05T00:00:00Z — waiver: gate=opponent; round=10; after=9; by=fixture-user; reason=revoked, commented out\n-->\n'
    printf -- '- 2026-01-05T00:00:01Z — waiver: gate=opponent; round=10; after=9; by=fixture-user; reason=live after a closed comment\n'
  } >> "$spec/STATUS.md"
  run_rc 0 vf_round_authorized "$spec" opponent 10 2026-01-04T23:59:59Z
  # Control: comment tokens inside inline code spans are prose about comments.
  # The discriminating shape is an opener with NO closer after it on the line,
  # which a scanner reading raw bytes turns into open comment state and then
  # suppresses the rest of the log. Round 2 of this kit's own review quotes
  # three openers and one closer exactly this way, so getting it wrong stops
  # the canonical report parsing at all.
  cp "$baseline" "$spec/STATUS.md"
  {
    printf -- '\n- 2026-01-05T00:00:02Z — the `<!--` opener is named here, with no closer anywhere on this line.\n'
    printf -- '- 2026-01-05T00:00:03Z — waiver: gate=opponent; round=10; after=9; by=fixture-user; reason=live beside a quoted unclosed opener\n'
  } >> "$spec/STATUS.md"
  run_rc 0 vf_round_authorized "$spec" opponent 10 2026-01-04T23:59:59Z
  # AC-009/FM-016: code-span delimiters close only on a run of exactly the
  # opener width. A single-backtick run nested inside a double-backtick span is
  # content, so the comment token remains quoted and the following live waiver
  # is visible. The former boolean toggle exposed the token and swallowed it.
  cp "$baseline" "$spec/STATUS.md"
  {
    printf -- '\n- 2026-01-05T00:00:02Z — the `` `<!--` `` token is quoted by a wider code span.\n'
    printf -- '- 2026-01-05T00:00:03Z — waiver: gate=opponent; round=10; after=9; by=fixture-user; reason=live after exact-width code span\n'
  } >> "$spec/STATUS.md"
  run_rc 0 vf_round_authorized "$spec" opponent 10 2026-01-04T23:59:59Z
  # Conversely, an unmatched delimiter is literal Markdown text. It cannot
  # hide the real mid-line comment opener that follows it or grant the waiver
  # inside that comment.
  cp "$baseline" "$spec/STATUS.md"
  {
    printf -- '\nsuperseded ` text before a real comment <!--\n'
    printf -- '- 2026-01-05T00:00:03Z — waiver: gate=opponent; round=10; after=9; by=fixture-user; reason=revoked inside comment after unmatched delimiter\n'
    printf -- '-->\n'
  } >> "$spec/STATUS.md"
  run_rc 4 vf_round_authorized "$spec" opponent 10 2026-01-04T23:59:59Z
  assert_contains "$OUT" 'authorization denied' 'AC-009: unmatched code delimiter hid a live comment opener'
  # AC-009/FM-016: only the template heading is the decisions log. A section
  # recording REFUSED decisions must not grant one.
  cp "$baseline" "$spec/STATUS.md"
  printf -- '\n## Decisions we rejected\n\n- 2026-01-05T00:00:04Z — waiver: gate=opponent; round=10; after=9; by=fixture-user; reason=asked for and refused\n' >> "$spec/STATUS.md"
  run_rc 4 vf_round_authorized "$spec" opponent 10 2026-01-04T23:59:59Z
  assert_contains "$OUT" 'authorization denied' 'AC-009: a second Decisions heading authorized a round'
}

# O-015 second review: floor_fixture stages the kit's scripts as the input
# identity enumerates them, so an ignored script in a developer's kit never
# reaches the staged kit whose checkers the floor then runs.
test_floor_fixture_stages_only_enumerated_scripts() {
  local host="$SANDBOX/host-kit" spec repo staged
  make_host_kit "$host" || t_fail 'AC-007: cannot build the host kit'
  printf 'scripts/zz-local.sh\n' >> "$host/.git/info/exclude"
  printf 'echo local\n' > "$host/scripts/zz-local.sh"
  spec="$(make_verification_git_dir floorhost)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  on_host_kit "$host" floor_fixture "$spec" > /dev/null
  staged="$SANDBOX/floor-kit-$(basename "$repo")/scripts"
  [[ -f "$staged/spec-gate.sh" ]] || t_fail 'AC-007: floor_fixture did not stage an enumerated script'
  [[ ! -e "$staged/zz-local.sh" ]] || t_fail "AC-007: floor_fixture staged the host kit's ignored script"
}

# O-015 review 6: floor_fixture runs inside a command substitution, where a
# t_fail was lost and its text captured into the returned path; a failed copy
# is now recorded, and the path returned is the sandbox path alone.
test_floor_fixture_failure_is_named_and_stays_in_the_sandbox() {
  local sub="$SANDBOX/failing-sandbox" nokit="$SANDBOX/not-a-kit" spec printed
  mkdir -p "$sub" "$nokit"
  spec="$(make_verification_git_dir floorfail)"
  printed="$(SANDBOX="$sub" on_host_kit "$nokit" floor_fixture "$spec" 2>/dev/null)"
  [[ "$printed" == "$sub"/* && "$printed" != *$'\n'* ]] \
    || t_fail "floor_fixture handed its caller something other than a sandbox path: '$printed'"
  assert_contains "$(cat "$sub/.fixture-build-failed" 2>/dev/null)" 'floor_fixture kit scripts' \
    'floor_fixture left no record of the failed copy'
}

t_run_all
