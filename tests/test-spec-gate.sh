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

test_acceptance() {
  local spec repo cap original bad before file
  spec="$(make_verification_git_dir acceptance)"
  repo="$(cd "$spec/../../.." && pwd -P)"
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
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: idempotent acceptance does not rewrite tasks'
  # Prepared-after crash recovery completes bookkeeping without another rewrite.
  for file in "$spec/notes/verification/accepted/T001"/ACC-*/COMMITTED; do rm "$file"; done
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$original"
  assert_eq "$before" "$(cat "$spec/tasks.md")"
  printf changed >> "$repo/src/parser.sh"
  run_rc 3 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$original"
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: stale return preserves historical completion'
  mkdir -p "$spec/notes/verification/lock"
  printf foreign > "$spec/notes/verification/lock/owner"
  run_rc 3 "$SCRIPTS/spec-task.sh" undo "$spec" T001
  run_rc 3 "$SCRIPTS/spec-task.sh" start "$spec" T002
  assert_eq foreign "$(cat "$spec/notes/verification/lock/owner")"
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-022: mutations serialize with acceptance'
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

t_run_all
