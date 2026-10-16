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

# AC-022/FM-010/INV-001 — T030o43. Acceptance reads its own parsers' status:
# the required bindings, the returned bindings and the frontmatter that picks
# the contract. A sort that failed used to leave the required set empty, and a
# return owing FM rows was then accepted as `none`; a frontmatter that could
# not be read chose the legacy path, which ticks a versioned task on
# --evidence alone. And a declared LC_ALL is one identity through the exec
# chain `spec-gate.sh accept` takes (O-017): the caller's value, not the pin.
acceptance_parse_fault_cases() {
  local spec repo cap f before evidence_before
  spec="$(make_verification_git_dir acceptfault)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  { printf 'Verification-Return: 1\nTask: T001\nCaptures: %s\nSummary: ' "$cap"
    cat "$spec/notes/captures/$cap/summary.txt"
    printf 'Failure modes: none\n'; } > "$SANDBOX/none-return.txt"
  before="$(cat "$spec/tasks.md")"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/none-return.txt"
  assert_contains "$OUT" 'required Failure modes are missing' 'fixture: a return owing FM-001 claims none'
  f="$SANDBOX/fault-required"; fault_bin "$f" sort '/required'
  run_rc 3 env PATH="$f:$PATH" "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/none-return.txt"
  assert_contains "$OUT" 'the required bindings could not be sorted' \
    'AC-022: a required-binding sort that failed accepted a return owing FM rows as none (T030o43)'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a failed sort changed tasks bytes'
  accept_return "$spec" T001 "$cap" "$SANDBOX/good-return.txt"
  f="$SANDBOX/fault-got"; fault_bin "$f" sort '/got'
  run_rc 3 env PATH="$f:$PATH" "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/good-return.txt"
  assert_contains "$OUT" 'the returned bindings could not be sorted' \
    'AC-022: a returned-binding sort that failed was not refused by name (T030o43)'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a failed sort changed tasks bytes'
  # The contract read. The awk fault reaches the checked reader and the sed
  # fault reaches lib.sh's fm_get, so either reader, failing, is caught.
  f="$SANDBOX/fault-contract"
  fault_bin "$f" awk 'key=verification_contract'; fault_bin "$f" sed '^verification_contract:'
  run_rc 3 env PATH="$f:$PATH" "$SCRIPTS/spec-task.sh" "done" "$spec" T002 --evidence fabricated
  assert_contains "$OUT" 'frontmatter could not be read for verification_contract' \
    'AC-022: an unreadable frontmatter let spec-task.sh tick a versioned task on --evidence (T030o43)'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: an unreadable frontmatter changed tasks bytes'
  evidence_before="$(cat "$spec/notes/evidence.md")"
  run_rc 3 env PATH="$f:$PATH" "$SCRIPTS/spec-run.sh" "$spec" T002 --cwd "$repo" --no-tick -- true
  assert_contains "$OUT" 'frontmatter could not be read for verification_contract' \
    'AC-022: an unreadable frontmatter sent spec-run.sh down the legacy path (T030o43)'
  assert_eq "$evidence_before" "$(cat "$spec/notes/evidence.md")" 'AC-022: the legacy path recorded a run'
  # The size bound reads its count with its status (T030o43 review F3).
  { printf 'Verification-Return: 1\nTask: T001\nCaptures: %s\nSummary: s\nFailure modes: none\n' "$cap"
    head -c 70000 /dev/zero | tr '\000' 'x'; printf '\n'; } > "$SANDBOX/big-return.txt"
  run_rc 3 bash -c '. "$1"; vf_return_parse "$2" "$3"' _ "$SCRIPTS/verification-lib.sh" "$SANDBOX/big-return.txt" "$SANDBOX/big.nul"
  assert_contains "$OUT" 'return exceeds 64 KiB' 'fixture: the size bound'
  f="$SANDBOX/fault-wc"; fault_bin "$f" wc -c
  run_rc 3 env PATH="$f:$PATH" bash -c '. "$1"; vf_return_parse "$2" "$3"' _ "$SCRIPTS/verification-lib.sh" "$SANDBOX/big-return.txt" "$SANDBOX/big.nul"
  assert_contains "$OUT" 'return: its size could not be read' \
    'AC-022: a size that could not be read let a return past the 64 KiB bound (T030o43 review)'
  # A declared LC_ALL through spec-gate.sh accept, which execs spec-task.sh.
  spec="$(make_verification_git_dir acceptlocale)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  printf "verification_environment:\n  - 'LC_ALL'\n" >> "$repo/.specify/stack.yml"
  run_rc 0 in_locale C env LC_ALL=en_US.UTF-8 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  accept_return "$spec" T001 "$cap" "$SANDBOX/locale-return.txt"
  before="$(cat "$spec/tasks.md")"
  run_rc 3 in_locale C env LC_ALL=de_DE.UTF-8 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/locale-return.txt"
  assert_contains "$OUT" 'capture stale' 'AC-022: another caller LC_ALL accepted a capture its identity does not hash (O-017)'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a stale capture changed tasks bytes'
  run_rc 0 in_locale C env LC_ALL=en_US.UTF-8 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/locale-return.txt"
  assert_contains "$OUT" 'accept accepted' \
    "AC-022: through the exec chain of spec-gate.sh accept, the record of a declared LC_ALL carried the pin, not the caller's value (O-017)"
}

# AC-022/FM-006/FM-010/INV-002 — T031a1, the cases reality-check round 2 found
# no fixture for. A return with no Failure modes block, a capture that does not
# exist, a capture of an unrelated command whose log names the test, a capture
# whose command exited nonzero and a manual return whose artifact is absent are
# each refused, leaving tasks.md byte-identical. A valid return ticks its own
# task and adds its Evidence line, and changes nothing else; a task owing no
# rows is accepted with an explicit `Failure modes: none`.
acceptance_named_cases() {
  local spec repo cap other failed before digest expected
  spec="$(make_verification_git_dir acceptnamed)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  accept_return "$spec" T001 "$cap" "$SANDBOX/named-good"
  before="$(cat "$spec/tasks.md")"
  sed '/^Failure modes:/,$d' "$SANDBOX/named-good" > "$SANDBOX/named-nofm"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/named-nofm"
  assert_contains "$OUT" 'incomplete verification return' 'AC-022: a return with no Failure modes block was not refused'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a return with no Failure modes block changed tasks bytes'
  sed "s/$cap/CAP-999-zzzzzz/g" "$SANDBOX/named-good" > "$SANDBOX/named-unknown"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/named-unknown"
  assert_contains "$OUT" 'capture integrity: missing COMPLETE or linked directory' 'AC-022: a nonexistent capture was not refused'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a nonexistent capture changed tasks bytes'
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --no-tick --summary -- bash -c 'echo test_ac_001_shared passed'
  other="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  accept_return "$spec" T001 "$other" "$SANDBOX/named-unrelated"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/named-unrelated"
  assert_contains "$OUT" 'do not prove this task Verify' 'AC-022: a log naming the test proved an unrelated command'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: an unrelated capture changed tasks bytes'
  cp "$repo/tests/check.sh" "$SANDBOX/named-check"
  printf 'exit 5\n' >> "$repo/tests/check.sh"
  run_rc 5 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  failed="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  cp "$SANDBOX/named-check" "$repo/tests/check.sh"
  accept_return "$spec" T001 "$failed" "$SANDBOX/named-failed"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/named-failed"
  assert_contains "$OUT" 'capture failed: exit 5' 'AC-022: a capture whose command exited nonzero was accepted'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a failed capture changed tasks bytes'
  mkdir -p "$repo/artifacts"
  printf observed-release > "$repo/artifacts/release.txt"
  digest="$(shasum -a 256 < "$repo/artifacts/release.txt" | awk '{print $1}')"
  rm "$repo/artifacts/release.txt"
  printf 'Verification-Return: 1\nTask: T004\nCaptures: none\nSummary: observed\nManual observation: release-observation, artifacts/release.txt, %s, fixture-observer, 2026-09-06T12:00:00Z, PASS: ok\nFailure modes:\nINV-001, release-observation, manual\n' "$digest" > "$SANDBOX/named-manual"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T004 "$SANDBOX/named-manual"
  assert_contains "$OUT" 'manual artifact missing or digest mismatch' 'AC-022: a manual return whose artifact is absent was not refused'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: a manual return with no artifact changed tasks bytes'
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/named-good"
  digest="$(printf '%s' "$OUT" | sed -n 's/.* return=\([0-9a-f]*\).*/\1/p')"
  # The expected file: T001 ticked and its Evidence line added at the end of
  # its block; the frontmatter `updated:` stamp is the writer's own.
  expected="$(printf '%s\n' "$before" | awk -v ev="  - *Evidence:* $cap verified by spec-gate accept; return sha256:$digest" '
    /^- \[ \] \*\*T001\*\*/ {sub(/^- \[ \]/, "- [x]"); on=1; print; next}
    on && !/^  / {print ev; on=0}
    {print}')"
  assert_eq "$expected" "$(sed '/^updated: [0-9-]*$/d' "$spec/tasks.md")" \
    'AC-022: a valid acceptance changed more than its own checkbox and Evidence line'
  cat > "$SANDBOX/named-t006" <<'EOF'
- [ ] **T006** — Cover the shell check with no failure-mode rows
  - *Files:* `src/parser.sh`, `tests/check.sh`
  - *Acceptance:* the shell family passes
  - *Verify kind:* test
  - *Tests:* `tests/check.sh::test_ac_001_shared`
  - *Verify:* `bash tests/check.sh` → passed
  - *Refs:* REQ-001, AC-001

EOF
  awk -v insert="$SANDBOX/named-t006" '
    /^## Reality Check/ {while ((getline line < insert) > 0) print line; close(insert)}
    {print}' "$spec/tasks.md" > "$SANDBOX/named-tasks"
  cp "$SANDBOX/named-tasks" "$spec/tasks.md"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T006 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  { printf 'Verification-Return: 1\nTask: T006\nCaptures: %s\nSummary: ' "$cap"
    cat "$spec/notes/captures/$cap/summary.txt"
    printf 'Failure modes: none\n'; } > "$SANDBOX/named-none"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T006 "$SANDBOX/named-none"
  assert_contains "$OUT" 'accept accepted' 'AC-022: a task owing no rows was refused with an explicit Failure modes: none'
  assert_contains "$(cat "$spec/tasks.md")" '- [x] **T006**'
}

test_acceptance() {
  acceptance_parse_fault_cases
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
  acceptance_named_cases
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

# AC-007/FM-014/INV-001 — T030o43 and O-017's checker sibling. The floor, the
# evidence check and spec-ac-coverage.sh read their own parsers' status: a
# task list, a worktree or branch frontmatter, or a spec inventory that could
# not be read fails them by name, where each used to read as no completed
# tasks, no recorded worktree, or a spec with nothing to check. And an AC id
# after a byte the caller's locale cannot decode is still an AC id (the pin).
floor_parse_fault_cases() {
  local spec repo cli f key legacy
  spec="$(make_verification_git_dir floorfault)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  cli="$(floor_fixture "$spec")"
  f="$SANDBOX/fault-list"; fault_bin "$f" awk 'is_gate = 0; proof_kind = 0; next'
  run_rc 3 env PATH="$f:$PATH" bash "$cli" floor "$spec"
  assert_contains "$OUT" 'floor gap: the task list could not be read' \
    "AC-007: a task list that could not be read left completed tasks' Verify unrefreshed (T030o43)"
  run_rc 3 env PATH="$f:$PATH" bash "$SCRIPTS/spec-evidence.sh" "$spec"
  assert_contains "$OUT" 'current evidence: the task list could not be read' \
    'AC-007: a task list that could not be read left completed tasks unchecked (T030o43)'
  for key in worktree branch; do
    f="$SANDBOX/fault-$key"; fault_bin "$f" awk "key=$key"; fault_bin "$f" sed "^$key:"
    run_rc 3 env PATH="$f:$PATH" bash "$cli" floor "$spec"
    assert_contains "$OUT" "frontmatter could not be read for $key" \
      "AC-007: an unreadable $key skipped the gate's mismatch check (T030o43)"
  done
  f="$SANDBOX/fault-contract-evidence"
  fault_bin "$f" awk 'key=verification_contract'; fault_bin "$f" sed '^verification_contract:'
  run_rc 3 env PATH="$f:$PATH" bash "$SCRIPTS/spec-evidence.sh" "$spec"
  assert_contains "$OUT" 'frontmatter could not be read for verification_contract' \
    'AC-007: an unreadable frontmatter swapped the current-evidence check for the legacy one (T030o43)'
  # The contract routes by its key in every reader, as the kernel routes it
  # (T030o43 review 2, R2-F6): no key is legacy, one key of value 1 is
  # current, and an empty value, a quoted empty one or a second key is refused
  # by name, never read as the legacy path. A U+00A0 after the colon is
  # whitespace, so that key routes as 1 does.
  cp "$spec/spec.md" "$SANDBOX/floorfault-spec"
  local current value script
  bash "$SCRIPTS/spec-evidence.sh" "$spec" > "$SANDBOX/route-current.out" 2>&1; current=$?
  sed "s/^verification_contract: 1\$/verification_contract:$(printf '\302\240')1/" "$SANDBOX/floorfault-spec" > "$spec/spec.md"
  bash "$SCRIPTS/spec-evidence.sh" "$spec" > "$SANDBOX/route-nbsp.out" 2>&1
  assert_eq "$current:$(cat "$SANDBOX/route-current.out")" "$?:$(cat "$SANDBOX/route-nbsp.out")" \
    'AC-007: a U+00A0 after the contract colon did not route as the value 1 (T030o43 review 2)'
  for value in 'verification_contract:' 'verification_contract: ""' "verification_contract: ''" twice; do
    awk -v v="$value" '$0 == "verification_contract: 1" {print (v == "twice" ? $0 "\n" $0 : v); next} {print}' \
      "$SANDBOX/floorfault-spec" > "$spec/spec.md"
    for script in spec-evidence spec-run spec-task; do
      case "$script" in
        spec-evidence) run_rc 3 bash "$SCRIPTS/spec-evidence.sh" "$spec";;
        spec-run) run_rc 3 bash "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --no-tick -- true;;
        spec-task) run_rc 3 bash "$SCRIPTS/spec-task.sh" list "$spec";;
      esac
      assert_contains "$OUT" 'unsupported verification contract' \
        "AC-007: $script read the contract key [$value] as the legacy path (T030o43 review 2)"
    done
  done
  cp "$SANDBOX/floorfault-spec" "$spec/spec.md"
  printf '\n- \222 AC-998 is a criterion no test names\n' >> "$spec/spec.md"
  if [[ "$(uname -s)" == Darwin && -n "$(printf '\222 AC-998\n' | in_locale en_US.UTF-8 grep -oE 'AC-[0-9]{3}')" ]]; then
    t_fail 'AC-007: precondition: an unpinned grep under en_US.UTF-8 must miss an id after 0x92 0x20 (O-017)'
  fi
  run_rc 1 in_locale en_US.UTF-8 bash "$SCRIPTS/spec-ac-coverage.sh" "$spec"
  assert_contains "$OUT" 'AC-998 — no test file names it' \
    'AC-007: spec-ac-coverage.sh read no AC id after an undecodable byte under en_US.UTF-8 (O-017)'
  cp "$SANDBOX/floorfault-spec" "$spec/spec.md"
  f="$SANDBOX/fault-acs"; fault_bin "$f" grep 'AC-[0-9]{3}'
  run_rc 3 env PATH="$f:$PATH" bash "$SCRIPTS/spec-ac-coverage.sh" "$spec"
  assert_contains "$OUT" 'spec.md could not be read for its AC ids' \
    'AC-007: an AC inventory that could not be read let spec-ac-coverage.sh find nothing to check (T030o43)'
  # The legacy evidence check reads its task records and artifact names.
  legacy="$SANDBOX/legacy-evidence/.specify/specs/001-legacy"; mkdir -p "$legacy"
  printf -- '---\nspec: 001-legacy\nstatus: accepted\n---\n\n- AC-001: legacy criterion\n' > "$legacy/spec.md"
  printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — Legacy task\n  - *Acceptance:* legacy\n' > "$legacy/tasks.md"
  run_rc 1 bash "$SCRIPTS/spec-evidence.sh" "$legacy"
  assert_contains "$OUT" 'T001 is [x] with no *Evidence:* line' 'fixture: the legacy evidence check'
  # An Evidence of a U+00A0 alone is no evidence (T030o43 review 2, R2-F4).
  printf '  - *Evidence:* \302\240\n' >> "$legacy/tasks.md"
  run_rc 1 bash "$SCRIPTS/spec-evidence.sh" "$legacy"
  assert_contains "$OUT" 'T001 is [x] with no *Evidence:* line' \
    'AC-007: an Evidence of a U+00A0 alone read as evidence (T030o43 review 2)'
  printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — Legacy task\n  - *Acceptance:* legacy\n' > "$legacy/tasks.md"
  # The task list reads a stage heading's whitespace as the kernel does, so a
  # task under "## <U+00A0>Ship" is in the Ship stage for both.
  printf -- '---\nspec: 001-legacy\n---\n\n## \302\240Ship\n\n- [x] **T001** — Legacy task\n' > "$SANDBOX/ship-tasks.md"
  cp "$legacy/tasks.md" "$SANDBOX/legacy-tasks"; cp "$SANDBOX/ship-tasks.md" "$legacy/tasks.md"
  run_rc 0 bash "$SCRIPTS/spec-task.sh" list "$legacy"
  assert_eq $'T001\tdone\tShip\tLegacy task' "$OUT" \
    'AC-007: the task list kept a U+00A0 in a stage the kernel reads without it (T030o43 review 2)'
  cp "$SANDBOX/legacy-tasks" "$legacy/tasks.md"
  f="$SANDBOX/fault-records"; fault_bin "$f" awk 'is_done = ($0 ~ /^- \[[xX]\]/) ? 1 : 0'
  run_rc 1 env PATH="$f:$PATH" bash "$SCRIPTS/spec-evidence.sh" "$legacy"
  assert_contains "$OUT" 'tasks.md could not be parsed for its task records' \
    'AC-007: task records that could not be parsed read as no ticked tasks (T030o43)'
  printf '  - *Evidence:* screenshot shots/missing.png\n' >> "$legacy/tasks.md"
  run_rc 1 bash "$SCRIPTS/spec-evidence.sh" "$legacy"
  assert_contains "$OUT" "names artifact 'shots/missing.png'" 'fixture: the legacy artifact check'
  f="$SANDBOX/fault-artifacts"; fault_bin "$f" grep 'png|jpg'
  run_rc 1 env PATH="$f:$PATH" bash "$SCRIPTS/spec-evidence.sh" "$legacy"
  assert_contains "$OUT" 'T001 evidence could not be searched for artifact names' \
    'AC-007: artifact names that could not be searched read as none named (T030o43)'
  # An artifact name is a run of bytes that are neither whitespace nor
  # control: a U+00A0, a U+202F, an em space or an ideographic space ends it
  # as an ASCII space does, a non-ASCII letter is part of it, a closed set of
  # opening quotes and brackets glued to its front is not, and it is never a
  # pattern. A missing name fails and an existing one passes, in every locale
  # (T030o43 reviews 1 and 2).
  mkdir -p "$legacy/shots"; : > "$legacy/shots/écran.png"; : > "$legacy/shots/a.png"
  # From the spec directory, where a pattern would find the files it names.
  local label want evidence l here="$PWD"
  cd "$legacy" || t_fail 'fixture: the legacy spec directory'
  while IFS='|' read -r label want evidence; do
    printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — Legacy task\n  - *Acceptance:* legacy\n  - *Evidence:* %b\n' "$evidence" > "$legacy/tasks.md"
    for l in C en_US.UTF-8; do
      run_rc "$want" in_locale "$l" bash "$SCRIPTS/spec-evidence.sh" "$legacy"
      if (( want )); then
        assert_contains "$OUT" 'in its evidence, but no such file exists' \
          "AC-007: a missing artifact ($label) passed under LANG=$l (T030o43 review 2)"
      else
        assert_not_contains "$OUT" 'names artifact' \
          "AC-007: an existing artifact ($label) failed under LANG=$l (T030o43 review 2)"
      fi
    done
  done <<'NAMES'
missing-accented|1|screenshot shots/café.png
existing-accented|0|screenshot shots/écran.png
after-nbsp|0|screenshot\302\240shots/a.png
after-narrow-nbsp|0|screenshot\342\200\257shots/a.png
after-em-space|0|screenshot\342\200\203shots/a.png
after-ideographic-space|0|\346\210\252\345\233\276\343\200\200shots/a.png
curly-quoted|0|\342\200\234shots/a.png\342\200\235
guillemets|0|\302\253shots/a.png\302\273
backticked|0|`shots/a.png`
missing-curly-quoted|1|\342\200\234shots/missing.png\342\200\235
not-a-pattern|1|screenshot shots/*.png
NAMES
  cd "$here" || t_fail 'fixture: back from the legacy spec directory'
}

test_floor() {
  floor_parse_fault_cases
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

# AC-008/FM-012/INV-004 — T030o43. The completed-through coverage reads its
# inventories with their status: criteria or references that could not be
# read used to record fewer coverage bindings and skip the binding-gap check,
# and the checkpoint sealed.
checkpoint_parse_fault_cases() {
  local spec repo cap f
  spec="$(make_verification_git_dir checkpointfault)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  accept_return "$spec" T001 "$cap" "$SANDBOX/checkpoint-return"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$SANDBOX/checkpoint-return"
  f="$SANDBOX/fault-criteria"; fault_bin "$f" grep 'AC-[0-9]{3}' '=-'
  run_rc 3 env PATH="$f:$PATH" "$SCRIPTS/spec-gate.sh" checkpoint "$spec" Backend
  assert_contains "$OUT" 'checkpoint coverage: the criteria of T001 could not be read' \
    'AC-008: criteria that could not be read recorded fewer coverage bindings (T030o43)'
  f="$SANDBOX/fault-refs"; fault_bin "$f" grep '(AC|FM|INV)-[0-9]{3}' '=-'
  run_rc 3 env PATH="$f:$PATH" "$SCRIPTS/spec-gate.sh" checkpoint "$spec" Backend
  assert_contains "$OUT" 'checkpoint coverage: the references of T001 could not be read' \
    'AC-008: references that could not be read skipped the binding-gap check (T030o43)'
  run_rc 0 "$SCRIPTS/spec-gate.sh" checkpoint "$spec" Backend
  assert_contains "$OUT" 'completed-task coverage checked' 'fixture: the checkpoint seals unfaulted'
  # A contract written with a U+00A0 before its 1 is the current contract to
  # every reader, the checkpoint's own included (T030o43 review 3, R3-F9), so
  # the checkpoint judges completed coverage and refuses a lost binding.
  sed "s/^verification_contract: 1\$/verification_contract:$(printf '\302\240')1/" "$spec/spec.md" > "$SANDBOX/checkpoint-spec"
  cp "$SANDBOX/checkpoint-spec" "$spec/spec.md"
  sed 's/REQ-001, AC-001, FM-001/REQ-001, AC-001/' "$spec/tasks.md" > "$SANDBOX/checkpoint-tasks"
  cp "$SANDBOX/checkpoint-tasks" "$spec/tasks.md"
  run_rc 3 "$SCRIPTS/spec-gate.sh" checkpoint "$spec" Backend
  assert_contains "$OUT" 'lost prior binding' \
    'AC-008: a checkpoint read a contract written with a U+00A0 as legacy and skipped coverage (T030o43 review 3)'
}

# AC-008: completed-through proof and retained bindings gate the next stage.
test_checkpoints() {
  checkpoint_parse_fault_cases
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
# AC-009/AC-012/FM-016 — O-017, end to end through the shipped entrypoint. A
# CLEARED completion over a manifest line the caller's locale cannot decode is
# refused as under C; a waiver below such a line in the Decisions log still
# authorizes; and a Decisions parse that dies is refused by name, never
# reported as a log with no candidate (T030o43).
round_locale_cases() {
  local spec cli res src floor stamp status f
  spec="$(make_verification_git_dir roundlocale)"
  cli="$(floor_fixture "$spec")"
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" opponent
  res="$OUT"
  src="$(printf '%s' "$res" | sed -n 's/.* source=\([^ ]*\).*/\1/p')"
  floor="$(printf '%s' "$res" | sed -n 's/.* floor=\([^ ]*\).*/\1/p')"
  stamp="$(printf '%s' "$res" | sed -n 's/.* reserved=\([^ ]*\).*/\1/p')"
  mkdir -p "$spec/notes/verification/reports"
  printf '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n- **Scenario:** the operator\222 s key vanished\n' \
    > "$spec/notes/verification/reports/opponent-findings-review.md"
  { printf '## Round 1\n**Round:** 1\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n' "$stamp" "$src" "$floor"
    printf '**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 1\n### What I attacked\nManifest tier binding read across a locale.\n'
    printf '### Finding G-042\n- **Class:** tier-binding\n- **Status:** open\n- **Prior:** none\n- **Severity:** minor\n'
    printf -- '- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n'
    printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n'
    printf -- '- **Class-wide fix:** read the manifest under C\n### Held up / follow-up tasks\nFixture disposition recorded.\n'
    printf '<!-- gate-round-end: opponent:1 -->\n'; } > "$SANDBOX/locale-report.md"
  if [[ "$(uname -s)" == Darwin ]] && ! locale_hostile en_US.UTF-8; then
    t_fail 'AC-009: precondition: en_US.UTF-8 is not a locale an unpinned awk fails to decode 0x92 0x20 under (O-017)'
  fi
  run_rc 3 in_locale en_US.UTF-8 bash "$cli" round "$spec" opponent --complete "$SANDBOX/locale-report.md"
  assert_contains "$OUT" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' \
    'AC-009: a CLEARED completion over an undecodable manifest line sealed under en_US.UTF-8 (O-017)'
  status="$SANDBOX/waiver-locale"; mkdir -p "$status"
  printf -- '---\nspec: w\n---\n\n## Decisions log\n\n- 2026-09-06 — a note carrying a \222 byte\n- %s — waiver: gate=opponent; round=4; after=3; by=fixture; reason=fixture authorization\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$status/STATUS.md"
  run_rc 0 in_locale en_US.UTF-8 bash -c '. "$1"; vf_round_authorized "$2" opponent 4 2026-09-06T12:00:03Z' _ \
    "$SCRIPTS/verification-lib.sh" "$status"
  f="$SANDBOX/fault-waiver"; fault_bin "$f" awk 'function knowngate'
  run_rc 4 env PATH="$f:$PATH" bash -c '. "$1"; vf_round_authorized "$2" opponent 4 2026-09-06T12:00:03Z' _ \
    "$SCRIPTS/verification-lib.sh" "$status"
  assert_contains "$OUT" 'the Decisions log in STATUS.md could not be parsed' \
    'AC-009: a Decisions parse that died was not refused by name (O-017)'
  assert_not_contains "$OUT" 'no candidate authorization line for this gate was found' \
    'AC-009: a Decisions parse that died was reported as a log with no candidate (O-017)'
}

# record_line_report <reservation-output> <n> <verdict> <blocking> <minor> <heading> <class> <status> <severity lines>
# A canonical round carrying the reservation's identity; heading and severity lines through printf %b.
record_line_report() {
  local src floor stamp
  src="$(printf '%s' "$1" | sed -n 's/.* source=\([^ ]*\).*/\1/p')"
  floor="$(printf '%s' "$1" | sed -n 's/.* floor=\([^ ]*\).*/\1/p')"
  stamp="$(printf '%s' "$1" | sed -n 's/.* reserved=\([^ ]*\).*/\1/p')"
  printf '## Round %s\n**Round:** %s\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n' "$2" "$2" "$stamp" "$src" "$floor"
  printf '**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nFinding records read by both readers.\n' "$3" "$4" "$5"
  printf '%b\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%b\n' "$6" "$7" "$8" "$9"
  printf -- '- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n'
  printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n'
  printf -- '- **Class-wide fix:** read or refuse every record line\n### Held up / follow-up tasks\nFixture disposition recorded.\n'
  printf '<!-- gate-round-end: opponent:%s -->\n' "$2"
}

# record_style_report <reservation-output> <n> <verdict> <blocking> <minor> <finding>...
# The reservation's round with a report title under its heading and its Timestamp after its Held-up
# section (round 14, O-020); each <finding> is heading:class:status:severity.
record_style_report() {
  local res="$1" n="$2" verdict="$3" b="$4" m="$5" src floor stamp f h c st sv
  shift 5
  src="$(printf '%s' "$res" | sed -n 's/.* source=\([^ ]*\).*/\1/p')"
  floor="$(printf '%s' "$res" | sed -n 's/.* floor=\([^ ]*\).*/\1/p')"
  stamp="$(printf '%s' "$res" | sed -n 's/.* reserved=\([^ ]*\).*/\1/p')"
  printf '## Round %s\n# Opponent review — fixture\n**Round:** %s\n**Source:** %s\n**Floor:** %s\n' "$n" "$n" "$src" "$floor"
  printf '**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nFinding records read by both readers.\n' "$verdict" "$b" "$m"
  for f in "$@"; do
    IFS=: read -r h c st sv <<< "$f"
    printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n' "$h" "$c" "$st" "$sv"
    printf -- '- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n'
    printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n'
    printf -- '- **Class-wide fix:** read or refuse every record line\n'
  done
  printf '### Held up / follow-up tasks\nFixture disposition recorded.\n**Timestamp:** %s\n<!-- gate-round-end: opponent:%s -->\n' "$stamp" "$n"
}

# AC-009/AC-012 — O-018 and O-019 end to end (round 13, T030o44): a CLEARED
# round whose report or prior-review manifest carried a record line neither
# reader read or refused sealed through `round --complete`, with the tier lost
# from the tally. A refused completion leaves the reservation in place, so one
# fixture serves every case, and the valid report completes after them. Round
# 14's mechanisms follow, one spelling each (T030o45, T030o46): a title with a
# late Timestamp (O-020), brackets that nest, a construct that spans lines,
# emphasis and an invisible character inside the word (O-018), and a block
# after a field line that ends its item (O-021).
round_record_line_cases() {
  local spec cli res manifest report l row tail
  spec="$(make_verification_git_dir recordlines)"
  cli="$(floor_fixture "$spec")"
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" opponent
  res="$OUT"
  manifest="$spec/notes/verification/reports/opponent-findings-review.md"
  mkdir -p "$spec/notes/verification/reports"
  report="$SANDBOX/record-lines-report.md"
  record_line_report "$res" 1 CLEARED 0 1 '### Finding G-042' tier-binding open '- **Severity:** minor' > "$report"
  for row in '#### Severity: data-loss|a Severity line this grammar cannot read: #### Severity: data-loss' \
             '- <b>Severity:</b> data-loss|a Severity line this grammar cannot read: - <b>Severity:</b> data-loss' \
             '> - **Severity:** data-loss|finding G-042 has no readable Severity'; do
    printf '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n\n%s\n' "${row%%|*}" > "$manifest"
    for l in C en_US.UTF-8; do
      run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$report"
      assert_contains "$OUT" "${row#*|}" "AC-009: a CLEARED completion over a manifest tier written as ${row%%|*} was not refused under LANG=$l (O-018)"
    done
  done
  # The T030o44 review's mechanisms, one spelling each, end to end: a second
  # manifest tier the label reader reads as written or as rendered (an
  # autolink, a named reference, an empty link), and a Severity item that holds
  # more than its line. Round 15's mechanisms follow, one spelling each
  # (T030o47): a paragraph boundary the reader misses (a sibling ordered item)
  # or invents (an indented list marker), a code span that holds a bracket, and
  # a rendered line start (a br tag). Round 16's follow (O-018, O-022): raw HTML
  # inside a finding, a carriage return inside a line, a form feed, a code span
  # placed with 2.4's escapes, an image split by a line of seven marks, and an
  # image after a backtick line the tracker fences and a renderer does not.
  # Round 17's follow (O-018, O-024): a `<` that may open an autolink, a link
  # destination holding a backtick, and a fence after a list marker. Round
  # 18's follow (O-018): a backtick inside a URL literal and inside a
  # reference link's label, which marked binds before any code span.
  for row in '- <Severity:data-loss>|a second Severity line in finding G-042' \
             '- &nbsp;Severity: data-loss|a second Severity line in finding G-042' \
             '- [](x)**Severity:** data-loss|a second Severity line in finding G-042' \
             '  data-loss|a Severity field whose list item holds more than its line in finding G-042' \
             '- [![badge](y.png)](z)Severity: data-loss|a second Severity line in finding G-042' \
             $'- <b\ntitle="x">Severity: data-loss</b>|a second Severity line in finding G-042' \
             '- S*everity:* data-loss|a second Severity line in finding G-042' \
             $'- Sev\342\200\213erity: data-loss|a second Severity line in finding G-042' \
             $'\n1. a\n2. <b\ntitle="x">Severity: data-loss</b>|a second Severity line in finding G-042' \
             $'\n<b title="a\n    - b">Severity: data-loss</b>|a second Severity line in finding G-042' \
             '- [`]`](u)Severity: data-loss|a second Severity line in finding G-042' \
             '- Note<br>Severity: data-loss|a second Severity line in finding G-042' \
             '- Note<pre>Severity: data-loss</pre>|raw HTML outside a code span in finding G-042' \
             $'- Note\r\rSeverity: data-loss|a carriage return inside a line in finding G-042' \
             $'- Note\fSeverity: data-loss|a form feed or vertical tab in finding G-042' \
             '- [\\`]`](u)Severity: data-loss|a second Severity line in finding G-042' \
             $'\n![x\n####### y](u)Severity: data-loss|a second Severity line in finding G-042' \
             $'\n```a`b\n\n![x\ny](u)Severity: data-loss\n```|quoted content carries a Severity line' \
             $'\nNote <1`@a.b><br>Severity: data-loss, tick: `.|an autolink outside a code span in finding G-042' \
             $'\n[x](u`v)<br>Severity: data-loss, tick: `.|a backtick inside a link destination, title or label in finding G-042' \
             $'\nNote http://a.b/`<br>Severity: data-loss, tick: `.|an autolink outside a code span in finding G-042' \
             $'\nNote [a`b]<br>Severity: data-loss, tick: `.|a backtick inside a link destination, title or label in finding G-042' \
             $'- ```\n  ### x\n- **Severity**: data-loss|a code fence that may be inside a list item in finding G-042'; do
    printf '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n%s\n' "${row%%|*}" > "$manifest"
    for l in C en_US.UTF-8; do
      run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$report"
      assert_contains "$OUT" "${row#*|}" "AC-009: a CLEARED completion over a second manifest tier written as ${row%%|*} was not refused under LANG=$l (T030o44 review)"
    done
  done
  # Round 17 (O-024): a link reference definition renders nothing yet carries
  # a field line, so it is refused by name inside a finding at completion.
  printf '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n\n[a]: /u %s\n    - **Severity:** minor\n    - x%s\n' "'" "'" > "$manifest"
  for l in C en_US.UTF-8; do
    run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$report"
    assert_contains "$OUT" 'a link reference definition in finding G-042' \
      "AC-009: a CLEARED completion over a manifest tier hidden in a link reference definition was not refused under LANG=$l (round 17, O-024)"
  done
  # Round 18 (O-025): a table inside a finding shows a cell's first text the
  # label reader never reads, so a delimiter row is refused by name at completion.
  printf '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n| Step | Result |\n| - | - |\n| ran | **Severity:** data-loss |\n' > "$manifest"
  for l in C en_US.UTF-8; do
    run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$report"
    assert_contains "$OUT" 'a table delimiter row in finding G-042' \
      "AC-009: a CLEARED completion over a manifest tier in a table cell was not refused under LANG=$l (round 18, O-025)"
  done
  # O-019: a field line under a sub-heading of the manifest finding is read, so
  # the CLEARED completion is refused on the manifest tier itself.
  printf '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n#### Notes\nReproduced twice.\n- **Severity:** data-loss\n' > "$manifest"
  run_rc 3 bash "$cli" round "$spec" opponent --complete "$report"
  assert_contains "$OUT" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' \
    'AC-009: a manifest field line under a sub-heading was not read at completion (O-019)'
  record_line_report "$res" 1 CLEARED 0 1 '### Finding G-050' dup-binding new '- **Severity:** data-loss\n  - **Severity:** minor' > "$SANDBOX/record-lines-dup.md"
  run_rc 3 bash "$cli" round "$spec" opponent --complete "$SANDBOX/record-lines-dup.md"
  assert_contains "$OUT" 'duplicate finding field' 'AC-009: an indented second Severity lowered a new finding at completion (O-018)'
  # A second tier the quoting tracker hides after an empty comment, and a
  # Severity value continued past its line, are refused at completion (T030o44
  # review F4, F10).
  for row in '- **Severity:** minor\n\n<!-->\n\n- **Severity:** data-loss\n\nThe tier above is the one we stand by. -->|quoted content carries a Severity line' \
             '- **Severity:** minor\n  data-loss|a Severity field whose list item holds more than its line in finding G-050' \
             '- **Severity:** minor\n- <abbr title="the tier this\nfinding carries">Severity:</abbr> data-loss|a Severity line this grammar cannot read in finding G-050' \
             '- **Severity:** minor\n- <!-- a\nb --> Severity: data-loss|quoted content carries a Severity line' \
             '- **Severity:** minor\n\nA remark\n===\n<b\ntitle="x">Severity: data-loss</b>|a Severity line this grammar cannot read in finding G-050' \
             '- **Severity:** minor\n\nNote\n> <b\n> title="x">Severity: data-loss</b>|quoted content carries a Severity line' \
             '- **Severity:** minor\n\nNote<pre>Severity: data-loss</pre>|raw HTML outside a code span in finding G-050' \
             '- **Severity:** minor\n\nNote\r\rSeverity: data-loss|a carriage return inside a line in finding G-050' \
             '- **Severity:** minor\n\n![x\n####### y](u)Severity: data-loss|a Severity line this grammar cannot read in finding G-050' \
             '- **Severity:** minor\n\nNote <1`@a.b><pre>Severity: data-loss</pre>`|an autolink outside a code span in finding G-050' \
             '- **Severity:** minor\n\nNote www.a.b/x`<br>Severity: data-loss, tick: `.|an autolink outside a code span in finding G-050' \
             '- **Severity:** minor\n\nNote ![a`b]<br>Severity: data-loss, tick: `.|a backtick inside a link destination, title or label in finding G-050' \
             '- **Severity:** minor\n\n[x](u "`")<br>Severity: data-loss, tick: `.|a backtick inside a link destination, title or label in finding G-050'; do
    record_line_report "$res" 1 CLEARED 0 1 '### Finding G-050' dup-binding new "${row%%|*}" > "$SANDBOX/record-lines-dup.md"
    for l in C en_US.UTF-8; do
      run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$SANDBOX/record-lines-dup.md"
      assert_contains "$OUT" "${row#*|}" "AC-009: a CLEARED completion over a second tier written as ${row%%|*} was not refused under LANG=$l (T030o44 review)"
    done
  done
  # Round 17 (O-024): after every field of a canonical finding, a definition
  # carries the minor tier no renderer shows and a fence a list item opens
  # hides the line the passes read as closing the finding, so the data-loss
  # item after it fell outside every finding; both are refused at completion.
  tail=$'\n[a]: /u \'\n    - **Severity:** minor\n    - x\'\n\n- ```\n  ### x\n- **Severity**: data-loss\n'
  record_line_report "$res" 1 CLEARED 0 1 '### Finding G-050' tier-binding new '' |
    TAIL="$tail" awk 'index($0, "### Held up") == 1 {printf "%s", ENVIRON["TAIL"]} {print}' > "$SANDBOX/record-lines-o024.md"
  for l in C en_US.UTF-8; do
    run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$SANDBOX/record-lines-o024.md"
    assert_contains "$OUT" 'a link reference definition in finding G-050' \
      "AC-009: a CLEARED completion over a tier hidden in a link reference definition was not refused under LANG=$l (round 17, O-024)"
    assert_contains "$OUT" 'a code fence that may be inside a list item in finding G-050' \
      "AC-009: a CLEARED completion over a finding a list-item fence closed early was not refused under LANG=$l (round 17, O-024)"
  done
  # Round 18 (O-025): the same table after the fields of a canonical finding.
  tail=$'\n| Step | Result |\n| - | - |\n| ran | **Severity:** data-loss |\n'
  record_line_report "$res" 1 CLEARED 0 1 '### Finding G-050' tier-binding new '- **Severity:** minor' |
    TAIL="$tail" awk 'index($0, "### Held up") == 1 {printf "%s", ENVIRON["TAIL"]} {print}' > "$SANDBOX/record-lines-o025.md"
  for l in C en_US.UTF-8; do
    run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$SANDBOX/record-lines-o025.md"
    assert_contains "$OUT" 'a table delimiter row in finding G-050' \
      "AC-009: a CLEARED completion over a tier in a table cell was not refused under LANG=$l (round 18, O-025)"
  done
  # A title and a late Timestamp let a CLEARED round seal over a blocking
  # finding it never counted (O-020); the switch is refused at completion.
  record_style_report "$res" 1 CLEARED 0 1 '### Finding G-099:silent-loss:new:data-loss' '### Finding G-100:minor-slip:new:minor' > "$SANDBOX/record-lines-style.md"
  for l in C en_US.UTF-8; do
    run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$SANDBOX/record-lines-style.md"
    assert_contains "$OUT" 'a Timestamp line after the body of a round its title made legacy' \
      "AC-009: a CLEARED completion under a title and a late Timestamp was not refused under LANG=$l (O-020)"
  done
  record_line_report "$res" 1 CHALLENGED 1 0 '### Finding G-042' tier-binding open '- **Severity:** data-loss' > "$report"
  run_rc 0 bash "$cli" round "$spec" opponent --complete "$report"
  assert_contains "$OUT" 'round completed gate=opponent round=1 verdict=CHALLENGED'
  # Round 2 is CLEARED at 0 . 0 and re-lists G-042 at minor under a line that
  # opens a finding to a reader but is not `### Finding <ID>`.
  run_rc 0 bash "$cli" round "$spec" opponent
  res="$OUT"
  for row in '#### Finding G-042|a Finding heading this grammar cannot read' \
             '### Finding\tG-042|a Finding heading this grammar cannot read' \
             '### Finding\302\240G-042|a Finding heading this grammar cannot read' \
             '**Finding G-042**|a finding field outside any Finding'; do
    record_line_report "$res" 2 CLEARED 0 0 "${row%%|*}" tier-binding open '- **Severity:** minor' > "$report"
    for l in C en_US.UTF-8; do
      run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$report"
      assert_contains "$OUT" "${row#*|}" "AC-009: a CLEARED round 2 under ${row%%|*} was not refused under LANG=$l (O-018)"
    done
  done
  record_style_report "$res" 2 CLEARED 0 0 '#### Finding G-042:tier-binding:open:minor' > "$SANDBOX/record-lines-style.md"
  for l in C en_US.UTF-8; do
    run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$SANDBOX/record-lines-style.md"
    assert_contains "$OUT" 'a Timestamp line after the body of a round its title made legacy' \
      "AC-009: a CLEARED round 2 under a title, a late Timestamp and #### Finding G-042 was not refused under LANG=$l (O-020)"
  done
  record_line_report "$res" 2 CLEARED 0 1 '### Finding G-042' tier-binding open '- **Severity:** minor' > "$report"
  run_rc 3 bash "$cli" round "$spec" opponent --complete "$report"
  assert_contains "$OUT" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' \
    'AC-009: the canonical control at a lowered tier completed (O-018)'
  # An HTML block directly after a Severity line is raw HTML inside a finding,
  # refused by name at completion (round 16, O-018); the round that completes
  # carries a fence there, which ends that line's item (O-021).
  record_line_report "$res" 2 CHALLENGED 1 0 '### Finding G-042' tier-binding open '- **Severity:** data-loss\n<details>\nx\n</details>\n' > "$report"
  run_rc 3 bash "$cli" round "$spec" opponent --complete "$report"
  assert_contains "$OUT" 'raw HTML outside a code span in finding G-042' \
    'AC-009: a round 2 with an HTML block after a field line was not refused as raw HTML (round 16, O-018)'
  record_line_report "$res" 2 CHALLENGED 1 0 '### Finding G-042' tier-binding open '- **Severity:** data-loss\n````text\nplain output\n````\n' > "$report"
  run_rc 0 bash "$cli" round "$spec" opponent --complete "$report"
  assert_contains "$OUT" 'round completed gate=opponent round=2 verdict=CHALLENGED'
  run_rc 0 bash "$cli" tally "$spec"
  assert_contains "$OUT" 'opponent rounds=2'
  assert_contains "$OUT" 'blocking=2 minor=0'
}

# AC-009/FM-016/INV-004 — T031a4, the case reality-check round 2 found no
# fixture for. A copy of shipped 002's date-only opponent history (five rounds
# with dates and no times) cannot order an authorization, so the next round is
# refused at exit 4 until `round --reconcile` records an explicit timestamp
# bound to the history's digest; an exact waiver written after it then
# authorizes round 6, which reserves on a fresh floor.
round_legacy_reconcile_cases() {
  local spec cli rel=.specify/specs/002-usage-limit-handling-for-dispatched-runs stamp
  spec="$(make_verification_git_dir legacyround)"
  cli="$(floor_fixture "$spec")"
  copy_kit "$KIT_DIR" "$SANDBOX/legacy-002" "$rel/notes" || t_fail 'AC-009: cannot copy shipped 002 records as the identity hashes them'
  mkdir -p "$spec/notes"
  cp "$SANDBOX/legacy-002/$rel/notes/opponent.md" "$spec/notes/opponent.md"
  run_rc 4 bash "$cli" round "$spec" opponent
  assert_contains "$OUT" 'date-only history needs timestamped digest reconciliation' \
    'AC-009: date-only history ordered an authorization without reconciliation'
  [[ ! -d "$spec/notes/verification/rounds/opponent/ROUND-6" ]] || t_fail 'AC-009: a refused legacy round reserved round 6'
  printf '%s\0' round 5 timestamp 2026-07-20T23:59:59Z report_digest "$(shasum -a 256 < "$spec/notes/opponent.md" | awk '{print $1}')" > "$SANDBOX/legacy-time.nul"
  run_rc 0 bash "$cli" round "$spec" opponent --reconcile "$SANDBOX/legacy-time.nul"
  assert_contains "$OUT" 'reconciled legacy gate=opponent round=5 timestamp=2026-07-20T23:59:59Z'
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '\n## Decisions log\n- %s — waiver: gate=opponent; round=6; after=5; by=fixture-user; reason=order after the reconciled legacy history\n' "$stamp" >> "$spec/STATUS.md"
  run_rc 0 bash "$cli" waiver "$spec" opponent 6
  assert_contains "$OUT" 'authorized: opponent round 6' 'AC-009: an exact waiver after reconciliation was not authorized'
  run_rc 0 bash "$cli" floor "$spec"
  run_rc 0 bash "$cli" round "$spec" opponent
  assert_contains "$OUT" 'round=6 gate=opponent' 'AC-009: an exact waiver after reconciliation did not reserve the next round'
}

test_rounds() {
  round_locale_cases
  round_record_line_cases
  round_authorization_cases
  round_preamble_cases
  round_verdict_source_cases
  round_legacy_reconcile_cases
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
  # AC-007/AC-020 — T031a2. A changed command string is another check: the
  # same suite opted in as `bash ./tests/check.sh` runs again and reuses
  # nothing (capture_validity_cases holds the inputs fixed and varies the argv
  # alone).
  sed "s#'bash tests/check.sh'#'bash ./tests/check.sh'#" "$repo/.specify/stack.yml" > "$SANDBOX/reuse-stack"
  cp "$SANDBOX/reuse-stack" "$repo/.specify/stack.yml"
  run_rc 0 bash "$gate" floor "$spec"
  assert_eq xxxx "$(cat "$SANDBOX/suite-count")" 'AC-007: a changed gate_checks command string reused the old success'
  assert_contains "$OUT" 'cache-hits=0' 'AC-007: a changed gate_checks command string counted a cache hit'
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
