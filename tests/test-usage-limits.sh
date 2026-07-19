#!/usr/bin/env bash
# test-usage-limits.sh — behavior coverage for provider limit classification.

set -u

. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"

CLASSIFIER="$SCRIPTS/usage-limit.sh"
SCHEDULER="$SCRIPTS/spec-resume-scheduler.sh"
FIXTURES="$KIT_DIR/tests/fixtures/usage-limits"
NOW=1704067200 # 2024-01-01 00:00:00 UTC

classify() { # <cli> <fixture>
  TZ=UTC "$CLASSIFIER" classify "$1" "$FIXTURES/$2" --now "$NOW"
}

# AC-001: every planned hard-limit message classifies to its provider kind.
test_AC_001_classifies_every_planned_provider_limit_fixture() {
  run_rc 0 classify claude claude-pipe-epoch.txt
  assert_eq $'limit\tshort\t1749924000\tclaude-pipe-epoch' "$OUT"

  run_rc 0 classify claude claude-session-clock.txt
  assert_eq $'limit\tshort\t1704123900\tclaude-session-clock' "$OUT"
  run_rc 0 classify claude claude-session-clock-no-minutes.txt
  assert_eq $'limit\tshort\t1704117600\tclaude-session-clock' "$OUT"
  run_rc 0 classify claude claude-weekly-clock.txt
  assert_eq $'limit\tlong\t1704151800\tclaude-weekly-clock' "$OUT"
  run_rc 0 classify claude claude-model-weekly.txt
  assert_eq $'limit\tlong\t1704151800\tclaude-model-weekly' "$OUT"

  run_rc 0 classify codex codex-short-clock.txt
  assert_eq $'limit\tshort\t1704072600\tcodex-usage-horizon' "$OUT"
  run_rc 0 classify codex codex-short-clock-no-minutes.txt
  assert_eq $'limit\tlong\t1704117600\tcodex-usage-horizon' "$OUT"
  run_rc 0 classify codex codex-long-datetime.txt
  assert_eq $'limit\tlong\t1704283200\tcodex-usage-horizon' "$OUT"

  run_rc 0 classify copilot copilot-premium-allowance.txt
  assert_eq $'limit\tlong\t\tcopilot-premium-allowance' "$OUT"
  run_rc 0 classify copilot copilot-premium-quota.txt
  assert_eq $'limit\tlong\t\tcopilot-premium-quota' "$OUT"
  run_rc 0 classify copilot copilot-rate-horizon.txt
  assert_eq $'limit\tshort\t1704069900\tcopilot-rate-horizon' "$OUT"
  run_rc 0 classify copilot copilot-model-rate.txt
  assert_eq $'limit\tshort\t\tcopilot-model-rate' "$OUT"
}

# AC-001: ordinary failures, including a literal "limit", remain unclassified.
test_AC_001_ordinary_failures_including_limit_word_are_none() {
  local fixture
  for fixture in ordinary-auth.txt ordinary-network.txt ordinary-test.txt ordinary-limit-word.txt; do
    run_rc 1 classify claude "$fixture"
    assert_eq "none" "$OUT" "$fixture does not false-positive"
  done
}

# AC-002: an unparseable reset is retained as unknown without accepting bad input.
test_AC_002_unparseable_horizon_is_unknown_and_bad_usage_is_refused() {
  run_rc 0 classify codex codex-unparseable.txt
  assert_eq $'limit\tunknown\t\tcodex-usage-horizon' "$OUT"
  run_rc 2 "$CLASSIFIER" classify claude "$FIXTURES/claude-pipe-epoch.txt" --now nope
}

# AC-002: the shared table is valid input and the classifier remains Bash 3.2-safe.
test_AC_002_pattern_table_is_the_only_provider_message_source_and_bash_32_safe() {
  run_rc 0 bash -n "$CLASSIFIER"
  run_rc 0 awk -F '\t' 'NF == 5 || /^#/' "$SCRIPTS/usage-limit-patterns.tsv"
  assert_not_contains "$(sed '/^[[:space:]]*#/d' "$CLASSIFIER")" "Claude AI usage limit reached"
  assert_not_contains "$(sed '/^[[:space:]]*#/d' "$CLASSIFIER")" "premium request allowance"
  assert_not_contains "$(sed '/^[[:space:]]*#/d' "$CLASSIFIER")" "usage limit"
}

# AC-003/AC-007: run the copied dispatcher against provider stubs. The real
# provider CLIs, resume scheduler, and fallback readiness probe are never in
# scope for these tests.
dispatch_fixture() { # <models.yml body> <provider stdout> <provider stderr> <exit>
  local policy="$1" provider_stdout="$2" provider_stderr="$3" provider_exit="$4"
  DISPATCH_KIT="$SANDBOX/dispatch-kit"
  DISPATCH_HOME="$SANDBOX/dispatch-home"
  DISPATCH_BIN="$SANDBOX/dispatch-bin"
  DISPATCH_LOG="$SANDBOX/dispatch-seams.log"
  DISPATCH_SCHEDULER="$SANDBOX/dispatch-scheduler"
  DISPATCH_PROVIDER_STDOUT="$provider_stdout"
  DISPATCH_PROVIDER_STDERR="$provider_stderr"
  DISPATCH_PROVIDER_EXIT="$provider_exit"
  mkdir -p "$DISPATCH_KIT" "$DISPATCH_HOME/.codex/skills/sdd-plan" "$DISPATCH_BIN"
  cp -R "$SCRIPTS" "$DISPATCH_KIT/scripts"
  printf '%s\n' "$policy" > "$DISPATCH_KIT/models.yml"
  : > "$DISPATCH_HOME/.codex/skills/sdd-plan/SKILL.md"
  cat > "$DISPATCH_BIN/provider-stub" <<'EOF'
#!/usr/bin/env bash
set -u
last_message=""
provider="$(basename "$0")"
while (( $# )); do
  case "$1" in
    --output-last-message) shift; last_message="$1" ;;
  esac
  shift
done
case "$provider" in
  codex)
    stdout="${DISPATCH_CODEX_STDOUT:-${DISPATCH_PROVIDER_STDOUT:-}}"
    stderr="${DISPATCH_CODEX_STDERR:-${DISPATCH_PROVIDER_STDERR:-}}"
    exit_code="${DISPATCH_CODEX_EXIT:-${DISPATCH_PROVIDER_EXIT:-0}}"
    write_plan="${DISPATCH_CODEX_SUCCESS_PLAN:-0}"
    ;;
  claude)
    stdout="${DISPATCH_CLAUDE_STDOUT:-}"
    stderr="${DISPATCH_CLAUDE_STDERR:-}"
    exit_code="${DISPATCH_CLAUDE_EXIT:-0}"
    write_plan="${DISPATCH_CLAUDE_SUCCESS_PLAN:-0}"
    ;;
  copilot)
    stdout="${DISPATCH_COPILOT_STDOUT:-}"
    stderr="${DISPATCH_COPILOT_STDERR:-}"
    exit_code="${DISPATCH_COPILOT_EXIT:-0}"
    write_plan="${DISPATCH_COPILOT_SUCCESS_PLAN:-0}"
    ;;
esac
printf '%s\n' "$stdout"
printf '%s\n' "$stderr" >&2
[[ -z "$last_message" ]] || printf 'provider final message\n' > "$last_message"
if [[ "$write_plan" == 1 ]]; then
  for plan in "$PWD"/.specify/specs/*/plan.md; do
    [[ -f "$plan" ]] || continue
    awk -v today="$(date +%Y-%m-%d)" '
      /^---$/ && frontmatter == 0 { frontmatter=1; print; next }
      frontmatter == 1 && /^updated:/ { print "updated: " today; updated=1; next }
      frontmatter == 1 && /^---$/ {
        if (!updated) print "updated: " today
        frontmatter_done=1
      }
      { print }
    ' "$plan" > "$plan.tmp" && mv "$plan.tmp" "$plan"
  done
fi
exit "$exit_code"
EOF
  cp "$DISPATCH_BIN/provider-stub" "$DISPATCH_BIN/codex"
  cp "$DISPATCH_BIN/provider-stub" "$DISPATCH_BIN/claude"
  cp "$DISPATCH_BIN/provider-stub" "$DISPATCH_BIN/copilot"
  cat > "$DISPATCH_KIT/scripts/spec-resume.sh" <<'EOF'
#!/usr/bin/env bash
if [[ -n "${DISPATCH_RESUME_ARGV:-}" ]]; then
  printf '%s\0' "$@" > "$DISPATCH_RESUME_ARGV"
fi
if [[ -n "${DISPATCH_RESUME_CWD:-}" ]]; then
  printf '%s\0' "$PWD" > "$DISPATCH_RESUME_CWD"
fi
printf 'resume %s\n' "$*" >> "$DISPATCH_SEAM_LOG"
printf '%s\n' "${DISPATCH_RESUME_UNIT:-stub-resume-unit}"
exit "${DISPATCH_RESUME_EXIT:-0}"
EOF
  cat > "$DISPATCH_KIT/scripts/spec-dispatch-ready.sh" <<'EOF'
#!/usr/bin/env bash
set -u
case "$1" in
  codex) exit_code="${DISPATCH_READY_CODEX_EXIT:-99}"; message="${DISPATCH_READY_CODEX_MESSAGE:-codex not ready}" ;;
  claude) exit_code="${DISPATCH_READY_CLAUDE_EXIT:-99}"; message="${DISPATCH_READY_CLAUDE_MESSAGE:-claude not ready}" ;;
  copilot) exit_code="${DISPATCH_READY_COPILOT_EXIT:-99}"; message="${DISPATCH_READY_COPILOT_MESSAGE:-copilot not ready}" ;;
esac
printf '%s\n' "$message"
exit "$exit_code"
EOF
  cat > "$DISPATCH_SCHEDULER" <<'EOF'
#!/usr/bin/env bash
printf 'scheduler %s\n' "$*" >> "$DISPATCH_SEAM_LOG"
exit 99
EOF
  chmod +x "$DISPATCH_BIN/codex" "$DISPATCH_BIN/claude" "$DISPATCH_BIN/copilot" \
    "$DISPATCH_KIT/scripts/spec-resume.sh" "$DISPATCH_KIT/scripts/spec-dispatch-ready.sh" "$DISPATCH_SCHEDULER"
  DISPATCH_SPEC="$(make_spec_dir)"
  cat >> "$DISPATCH_SPEC/STATUS.md" <<'EOF'

## Decisions log

(none)
EOF
}

run_dispatch() {
  env HOME="$DISPATCH_HOME" PATH="$DISPATCH_BIN:$PATH" \
    DISPATCH_SEAM_LOG="$DISPATCH_LOG" \
    DISPATCH_PROVIDER_STDOUT="$DISPATCH_PROVIDER_STDOUT" \
    DISPATCH_PROVIDER_STDERR="$DISPATCH_PROVIDER_STDERR" \
    DISPATCH_PROVIDER_EXIT="$DISPATCH_PROVIDER_EXIT" \
    SDD_RESUME_SCHEDULER="$DISPATCH_SCHEDULER" \
    "$DISPATCH_KIT/scripts/spec-dispatch.sh" plan "$DISPATCH_SPEC" --to codex "$@"
}

run_dispatch_to() { # <cli> [dispatcher args...]
  local cli="$1"
  shift
  env HOME="$DISPATCH_HOME" PATH="$DISPATCH_BIN:$PATH" \
    DISPATCH_SEAM_LOG="$DISPATCH_LOG" \
    DISPATCH_PROVIDER_STDOUT="$DISPATCH_PROVIDER_STDOUT" \
    DISPATCH_PROVIDER_STDERR="$DISPATCH_PROVIDER_STDERR" \
    DISPATCH_PROVIDER_EXIT="$DISPATCH_PROVIDER_EXIT" \
    SDD_RESUME_ROOT="${DISPATCH_RESUME_ROOT:-}" \
    SDD_RESUME_SCHEDULER="${DISPATCH_RESUME_SCHEDULER:-$DISPATCH_SCHEDULER}" \
    SDD_RESUME_JITTER_SECONDS="${SDD_RESUME_JITTER_SECONDS:-0}" \
    DISPATCH_RESUME_LOG="${DISPATCH_RESUME_LOG:-}" \
    DISPATCH_RESUME_JOBS="${DISPATCH_RESUME_JOBS:-}" \
    "$DISPATCH_KIT/scripts/spec-dispatch.sh" plan "$DISPATCH_SPEC" --to "$cli" "$@"
}

install_dispatch_resume_scheduler() {
  DISPATCH_RESUME_ROOT="$SANDBOX/dispatch resume state"
  DISPATCH_RESUME_SCHEDULER="$DISPATCH_KIT/scripts/dispatch-resume-scheduler"
  DISPATCH_RESUME_LOG="$SANDBOX/dispatch-resume-scheduler.log"
  DISPATCH_RESUME_JOBS="$SANDBOX/dispatch-resume-scheduler.jobs"
  cat > "$DISPATCH_RESUME_SCHEDULER" <<'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$DISPATCH_RESUME_LOG"
case "$1" in
  add)
    awk -v id="$2" '$1 != id { print }' "$DISPATCH_RESUME_JOBS" 2>/dev/null > "$DISPATCH_RESUME_JOBS.tmp" || true
    printf '%s\n' "$2" >> "$DISPATCH_RESUME_JOBS.tmp"
    mv "$DISPATCH_RESUME_JOBS.tmp" "$DISPATCH_RESUME_JOBS"
    ;;
  remove)
    awk -v id="$2" '$1 != id { print }' "$DISPATCH_RESUME_JOBS" 2>/dev/null > "$DISPATCH_RESUME_JOBS.tmp" || true
    mv "$DISPATCH_RESUME_JOBS.tmp" "$DISPATCH_RESUME_JOBS"
    ;;
  list) cat "$DISPATCH_RESUME_JOBS" 2>/dev/null || true ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$DISPATCH_RESUME_SCHEDULER"
  cp "$SCRIPTS/spec-resume.sh" "$DISPATCH_KIT/scripts/spec-resume.sh"
  chmod +x "$DISPATCH_KIT/scripts/spec-resume.sh"
  export DISPATCH_RESUME_ROOT DISPATCH_RESUME_SCHEDULER DISPATCH_RESUME_LOG DISPATCH_RESUME_JOBS
}

run_dispatch_resume() { # <unit-id>
  env HOME="$DISPATCH_HOME" PATH="$DISPATCH_BIN:$PATH" \
    DISPATCH_SEAM_LOG="$DISPATCH_LOG" \
    DISPATCH_PROVIDER_STDOUT="$DISPATCH_PROVIDER_STDOUT" \
    DISPATCH_PROVIDER_STDERR="$DISPATCH_PROVIDER_STDERR" \
    DISPATCH_PROVIDER_EXIT="$DISPATCH_PROVIDER_EXIT" \
    SDD_RESUME_ROOT="$DISPATCH_RESUME_ROOT" \
    SDD_RESUME_SCHEDULER="$DISPATCH_RESUME_SCHEDULER" \
    SDD_RESUME_JITTER_SECONDS=0 \
    DISPATCH_RESUME_LOG="$DISPATCH_RESUME_LOG" \
    DISPATCH_RESUME_JOBS="$DISPATCH_RESUME_JOBS" \
    "$DISPATCH_KIT/scripts/spec-resume.sh" run "$1"
}

dispatch_capture() {
  local f
  for f in "$DISPATCH_SPEC"/notes/dispatch-plan-*.md; do
    [[ "$f" == *attempt-* ]] || { printf '%s\n' "$f"; return 0; }
  done
  return 1
}

test_AC_003_and_AC_007_codex_attempt_capture_classifies_and_stays_manual_without_policy() {
  local capture attempt
  dispatch_fixture $'tiers:\nroles:' \
    'codex standard output' "You've hit your usage limit. Try again at 2099-01-01 00:00" 42
  export DISPATCH_PROVIDER_STDOUT DISPATCH_PROVIDER_STDERR DISPATCH_PROVIDER_EXIT

  run_rc 7 run_dispatch --note 'spaces and ; punctuation'
  assert_contains "$OUT" 'provider usage limit: cli=codex kind=long reset=' "AC-007: Codex output is classified after its true nonzero exit"
  assert_contains "$OUT" 'manual park:' "AC-003: absent policy prints a manual park command"
  assert_contains "$OUT" 'spec-resume.sh park' "AC-003: park guidance names the resume command"
  assert_contains "$OUT" '--to claude' "AC-003: shell-safe fallback guidance includes another CLI"
  assert_contains "$OUT" '--to copilot' "AC-003: shell-safe fallback guidance includes every other CLI"
  assert_contains "$OUT" 'spaces\ and\ \;\ punctuation' "AC-003: manual argv guidance shell-escapes adversarial text"
  [[ ! -s "$DISPATCH_LOG" ]] || t_fail "AC-003: absent policy invokes neither scheduler nor readiness fallback"

  capture="$(dispatch_capture)" || t_fail "AC-007: aggregate capture was written"
  attempt="$DISPATCH_SPEC/notes/$(basename "${capture%.md}")-attempt-1-codex.md"
  [[ -f "$attempt" ]] || t_fail "AC-007: per-attempt capture was written"
  assert_contains "$(cat "$capture")" 'codex standard output' "AC-007: aggregate capture receives Codex stdout"
  assert_contains "$(cat "$capture")" 'usage limit' "AC-007: aggregate capture receives Codex stderr"
  cmp -s "$capture" "$attempt" || t_fail "AC-007: aggregate and attempt captures have matching combined transcripts"
}

test_AC_003_fail_policy_is_manual_and_ordinary_dispatch_failures_keep_exit_six() {
  dispatch_fixture $'tiers:\nroles:\non_limit:\n  long: fail' \
    'codex standard output' "You've hit your usage limit. Try again at 2099-01-01 00:00" 23
  export DISPATCH_PROVIDER_STDOUT DISPATCH_PROVIDER_STDERR DISPATCH_PROVIDER_EXIT
  run_rc 7 run_dispatch
  assert_contains "$OUT" 'manual park:' "AC-003: explicit fail policy emits the same manual guidance"
  [[ ! -s "$DISPATCH_LOG" ]] || t_fail "AC-003: fail policy invokes neither scheduler nor readiness fallback"

  dispatch_fixture $'tiers:\nroles:' 'ordinary output' 'network request failed after mentioning a limit' 19
  export DISPATCH_PROVIDER_STDOUT DISPATCH_PROVIDER_STDERR DISPATCH_PROVIDER_EXIT
  run_rc 6 run_dispatch
  assert_contains "$OUT" 'codex exited 19' "AC-007: ordinary Codex failures retain exit 6 handling"
  [[ ! -s "$DISPATCH_LOG" ]] || t_fail "AC-003: ordinary failure does not invoke limit seams"
}

# T013o1: provider captures with clock-only reset wording must take a configured
# recovery path, rather than generic exit 6 or the unknown/manual-only branch.
test_T013o1_clock_only_horizons_follow_configured_park_policy() {
  local unit_count
  dispatch_fixture $'tiers:\nroles:\non_limit:\n  short: park\n  long: park\n  backoff_minutes: 1' \
    'codex standard output' "$(cat "$FIXTURES/codex-short-clock-no-minutes.txt")" 42
  install_dispatch_resume_scheduler
  export DISPATCH_PROVIDER_STDOUT DISPATCH_PROVIDER_STDERR DISPATCH_PROVIDER_EXIT
  export DISPATCH_CLAUDE_STDOUT='claude standard output'
  DISPATCH_CLAUDE_STDERR="$(cat "$FIXTURES/claude-session-clock-no-minutes.txt")"
  export DISPATCH_CLAUDE_STDERR
  export DISPATCH_CLAUDE_EXIT=42

  run_rc 7 run_dispatch_to claude
  assert_not_contains "$OUT" 'manual park:' "T013o1: Claude clock-only limit takes configured recovery"
  assert_not_contains "$OUT" 'claude exited 42' "T013o1: Claude clock-only limit avoids generic exit 6"

  run_rc 7 run_dispatch_to codex
  assert_not_contains "$OUT" 'manual park:' "T013o1: Codex clock-only horizon takes configured recovery"
  assert_not_contains "$OUT" 'codex exited 42' "T013o1: Codex clock-only horizon avoids generic exit 6"

  unit_count="$(find "$DISPATCH_RESUME_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name '.*' | wc -l | tr -d ' ')"
  assert_eq 2 "$unit_count" "T013o1: both concrete clock resets create resume units"
  assert_eq 2 "$(grep -c '^add ' "$DISPATCH_RESUME_LOG")" \
    "T013o1: both configured recovery paths schedule the parsed reset"
}

test_AC_006_delegate_uses_ordered_ready_fallback_and_preserves_verification() {
  local capture
  dispatch_fixture $'tiers:\nroles:\non_limit:\n  long: delegate\n  fallback: [codex, claude, copilot]' \
    'codex standard output' "You've hit your usage limit. Try again at 2099-01-01 00:00" 42
  export DISPATCH_PROVIDER_STDOUT DISPATCH_PROVIDER_STDERR DISPATCH_PROVIDER_EXIT
  export DISPATCH_READY_CLAUDE_EXIT=1 DISPATCH_READY_CLAUDE_MESSAGE='authentication probe failed'
  export DISPATCH_READY_COPILOT_EXIT=0 DISPATCH_READY_COPILOT_MESSAGE='copilot ready for plan'
  export DISPATCH_COPILOT_STDOUT='copilot completed plan' DISPATCH_COPILOT_STDERR=''
  export DISPATCH_COPILOT_EXIT=0 DISPATCH_COPILOT_SUCCESS_PLAN=1

  run_rc 0 run_dispatch
  assert_contains "$OUT" 'plan.md updated:' "AC-006: first ready fallback returns through the unchanged plan verifier"
  capture="$(dispatch_capture)" || t_fail "AC-006: aggregate capture was written"
  assert_contains "$(cat "$capture")" 'Fallback skipped: codex (already attempted)' \
    "AC-006: the limited CLI is skipped even when listed first"
  assert_contains "$(cat "$capture")" 'Fallback skipped: claude (authentication probe failed)' \
    "AC-006: unavailable fallback reason is retained in the aggregate capture"
  assert_contains "$(cat "$capture")" 'Fallback selected: copilot' \
    "AC-006: ordered selection reaches the first ready fallback"
  assert_contains "$(cat "$capture")" 'Dispatched plan -> copilot (attempt 2)' \
    "AC-006: selected fallback is a second provider attempt, not a nested dispatcher"
  assert_contains "$(cat "$DISPATCH_SPEC/STATUS.md")" 'delegated role=plan kind=long from=codex to=copilot reset=' \
    "AC-006: failover records its from/to decision through STATUS"
}

test_AC_006_delegate_classifies_only_the_current_attempt_slice() {
  local capture
  dispatch_fixture $'tiers:\nroles:\non_limit:\n  long: delegate\n  fallback: [copilot]' \
    'codex standard output' "You've hit your usage limit. Try again at 2099-01-01 00:00" 42
  export DISPATCH_PROVIDER_STDOUT DISPATCH_PROVIDER_STDERR DISPATCH_PROVIDER_EXIT
  export DISPATCH_READY_COPILOT_EXIT=0 DISPATCH_READY_COPILOT_MESSAGE='copilot ready for plan'
  export DISPATCH_COPILOT_STDOUT='ordinary copilot failure' DISPATCH_COPILOT_STDERR='network request failed'
  export DISPATCH_COPILOT_EXIT=31 DISPATCH_COPILOT_SUCCESS_PLAN=0

  run_rc 6 run_dispatch
  assert_contains "$OUT" 'copilot exited 31' "AC-006: later ordinary failure is not classified from an earlier limit"
  capture="$(dispatch_capture)" || t_fail "AC-006: aggregate capture was written"
  assert_contains "$(cat "$capture")" 'usage limit' "AC-006: aggregate retains the earlier limit for audit"
  assert_contains "$(cat "$capture")" 'ordinary copilot failure' "AC-006: aggregate retains the current ordinary failure"
}

test_AC_006_delegate_caps_three_attempts_and_parks_when_exhausted() {
  local capture
  dispatch_fixture $'tiers:\nroles:\non_limit:\n  long: delegate\n  fallback: [claude, copilot]' \
    'codex standard output' "You've hit your usage limit. Try again at 2099-01-01 00:00" 42
  export DISPATCH_PROVIDER_STDOUT DISPATCH_PROVIDER_STDERR DISPATCH_PROVIDER_EXIT
  export DISPATCH_READY_CLAUDE_EXIT=0 DISPATCH_READY_CLAUDE_MESSAGE='claude ready for plan'
  export DISPATCH_READY_COPILOT_EXIT=0 DISPATCH_READY_COPILOT_MESSAGE='copilot ready for plan'
  export DISPATCH_CLAUDE_STDOUT='' DISPATCH_CLAUDE_STDERR='Weekly limit reached. Your limit resets 11:30pm.' DISPATCH_CLAUDE_EXIT=43
  export DISPATCH_COPILOT_STDOUT='' DISPATCH_COPILOT_STDERR='You have exceeded your premium request allowance.' DISPATCH_COPILOT_EXIT=44

  run_rc 7 run_dispatch
  capture="$(dispatch_capture)" || t_fail "AC-006: aggregate capture was written"
  assert_eq 3 "$(grep -c '^# Dispatched plan -> ' "$capture")" \
    "AC-006: delegation makes at most three provider attempts without recursion"
  assert_contains "$(cat "$capture")" 'Dispatched plan -> claude (attempt 2)' "AC-006: second attempt uses claude"
  assert_contains "$(cat "$capture")" 'Dispatched plan -> copilot (attempt 3)' "AC-006: third attempt uses copilot"
  assert_contains "$(cat "$DISPATCH_LOG")" 'resume park' \
    "AC-006: exhausted fallbacks park the original dispatch through the resume seam"
}

future_short_clock() {
  if date -v+1H '+%I:%M %p' >/dev/null 2>&1; then
    date -v+1H '+%I:%M %p'
  else
    date -d '+1 hour' '+%I:%M %p'
  fi
}

test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry() {
  local unit reset run_at expected_argv expected_cwd expected_cwd_value short_clock
  short_clock="$(future_short_clock)"
  dispatch_fixture $'tiers:\nroles:\non_limit:\n  short: park\n  backoff_minutes: 1' \
    'codex standard output' "You've hit your usage limit. Try again at $short_clock" 42
  install_dispatch_resume_scheduler
  DISPATCH_CALL_CWD="$SANDBOX/original cwd with spaces"
  mkdir -p "$DISPATCH_CALL_CWD"
  export DISPATCH_PROVIDER_STDOUT DISPATCH_PROVIDER_STDERR DISPATCH_PROVIDER_EXIT

  run_rc 7 env HOME="$DISPATCH_HOME" PATH="$DISPATCH_BIN:$PATH" \
    DISPATCH_SEAM_LOG="$DISPATCH_LOG" \
    DISPATCH_PROVIDER_STDOUT="$DISPATCH_PROVIDER_STDOUT" \
    DISPATCH_PROVIDER_STDERR="$DISPATCH_PROVIDER_STDERR" \
    DISPATCH_PROVIDER_EXIT="$DISPATCH_PROVIDER_EXIT" \
    SDD_RESUME_ROOT="$DISPATCH_RESUME_ROOT" \
    SDD_RESUME_SCHEDULER="$DISPATCH_RESUME_SCHEDULER" SDD_RESUME_JITTER_SECONDS=0 \
    DISPATCH_RESUME_LOG="$DISPATCH_RESUME_LOG" DISPATCH_RESUME_JOBS="$DISPATCH_RESUME_JOBS" \
    bash -c 'cd -- "$1" && shift && "$@"' bash "$DISPATCH_CALL_CWD" \
    "$DISPATCH_KIT/scripts/spec-dispatch.sh" plan "$DISPATCH_SPEC" --to codex \
    --note 'verbatim ; punctuation'

  unit="$(find "$DISPATCH_RESUME_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -exec basename {} \;)"
  [[ "$unit" =~ ^[a-f0-9]{64}$ ]] || t_fail "AC-004: dispatch park creates one deterministic resume unit"
  expected_argv="$SANDBOX/expected-dispatch-argv.nul"
  expected_cwd="$SANDBOX/expected-dispatch-cwd.nul"
  printf '%s\0' "$DISPATCH_KIT/scripts/spec-dispatch.sh" plan "$DISPATCH_SPEC" --to codex \
    --note 'verbatim ; punctuation' > "$expected_argv"
  expected_cwd_value="$(cd -- "$DISPATCH_CALL_CWD" && pwd)"
  printf '%s\0' "$expected_cwd_value" > "$expected_cwd"
  cmp -s "$expected_argv" "$DISPATCH_RESUME_ROOT/$unit/argv.nul" \
    || t_fail "AC-004: park persists the untouched original dispatcher argv"
  cmp -s "$expected_cwd" "$DISPATCH_RESUME_ROOT/$unit/cwd.nul" \
    || t_fail "AC-004: park persists the untouched original dispatcher cwd"
  reset="$(awk -F '\t' '$1 == "reset_epoch" { print $2 }' "$DISPATCH_RESUME_ROOT/$unit/unit.tsv")"
  run_at="$(awk -F '\t' '$1 == "run_at_epoch" { print $2 }' "$DISPATCH_RESUME_ROOT/$unit/unit.tsv")"
  [[ -n "$reset" ]] || t_fail "AC-004: parsed reset is stored in the resume unit"
  assert_eq "$reset" "$run_at" "AC-004: zero fixture jitter schedules exactly at the parsed reset"
  assert_eq 1 "$(grep -c '^add ' "$DISPATCH_RESUME_LOG")" "AC-004: initial park registers exactly one scheduler entry"
  assert_eq 1 "$(wc -l < "$DISPATCH_RESUME_JOBS" | tr -d ' ')" "AC-004: exactly one scheduler job is pending"
  assert_contains "$(cat "$DISPATCH_SPEC/STATUS.md")" "parked resume unit $unit" "AC-004: park records its event through spec-status"

  run_rc 7 run_dispatch_resume "$unit"
  run_rc 7 run_dispatch_resume "$unit"
  run_rc 7 run_dispatch_resume "$unit"
  assert_contains "$(cat "$DISPATCH_RESUME_ROOT/$unit/unit.tsv")" $'state\tfailed' \
    "AC-005: nested exit 7 honors the resume retry cap"
  assert_eq 3 "$(grep -c '^add ' "$DISPATCH_RESUME_LOG")" \
    "AC-005: initial park plus two nested re-parks add no duplicate jobs"
  assert_eq 0 "$(wc -l < "$DISPATCH_RESUME_JOBS" | tr -d ' ')" \
    "AC-005: retry-cap failure leaves no scheduler job"
}

# AC-006/AC-009: readiness requires all three fallback seams. The stubs are
# deliberately real executables on PATH; only the authentication step is
# replaced through the documented test seam.
ready_fixture() { # <cli> <role> <auth exit>
  local cli="$1" role="$2" auth_rc="$3" home="$SANDBOX/home" bindir="$SANDBOX/bin"
  mkdir -p "$bindir" "$home"
  cat > "$bindir/$cli" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$bindir/$cli"
  case "$cli" in
    claude) mkdir -p "$home/.claude/skills/sdd-$role"; : > "$home/.claude/skills/sdd-$role/SKILL.md" ;;
    codex) mkdir -p "$home/.codex/skills/sdd-$role"; : > "$home/.codex/skills/sdd-$role/SKILL.md" ;;
    copilot) mkdir -p "$home/.copilot/agents"; : > "$home/.copilot/agents/sdd-$role.agent.md" ;;
  esac
  cat > "$SANDBOX/auth-checker" <<EOF
#!/usr/bin/env bash
exit $auth_rc
EOF
  chmod +x "$SANDBOX/auth-checker"
}

run_ready() { # <cli> <role>
  env HOME="$SANDBOX/home" PATH="$SANDBOX/bin:$PATH" \
    SDD_DISPATCH_AUTH_CHECKER="$SANDBOX/auth-checker" \
    "$SCRIPTS/spec-dispatch-ready.sh" "$1" "$2"
}

test_AC_006_and_AC_009_readiness_requires_binary_adapter_and_authentication() {
  local cli
  for cli in claude codex copilot; do
    ready_fixture "$cli" implement 0
    run_rc 0 run_ready "$cli" implement
    assert_contains "$OUT" "$cli ready for implement" "AC-006: $cli becomes fallback-ready only after every seam passes"
  done

  ready_fixture codex implement 1
  run_rc 1 run_ready codex implement
  assert_contains "$OUT" "authentication probe failed" "AC-009: failed auth has a concise reason"

  ready_fixture claude implement 0
  rm "$SANDBOX/home/.claude/skills/sdd-implement/SKILL.md"
  run_rc 1 run_ready claude implement
  assert_contains "$OUT" "missing implement adapter" "AC-009: adapter failure is named"

  mkdir -p "$SANDBOX/home/.copilot/agents"
  : > "$SANDBOX/home/.copilot/agents/sdd-implement.agent.md"
  # Invoke Bash by its resolved absolute path so PATH can contain no provider
  # binaries at all; inheriting the runner PATH can find a real `copilot`.
  mkdir -p "$SANDBOX/empty"
  run_rc 1 env HOME="$SANDBOX/home" PATH="$SANDBOX/empty" \
    SDD_DISPATCH_AUTH_CHECKER="$SANDBOX/auth-checker" \
    "$(command -v bash)" "$SCRIPTS/spec-dispatch-ready.sh" copilot implement
  assert_contains "$OUT" "binary not on PATH" "AC-009: missing binary is named"
}

test_AC_006_auth_checker_override_does_not_bypass_binary_or_adapter_checks() {
  ready_fixture codex tasks 0
  run_rc 0 run_ready codex tasks
  rm "$SANDBOX/home/.codex/skills/sdd-tasks/SKILL.md"
  run_rc 1 run_ready codex tasks
  assert_contains "$OUT" "missing tasks adapter" "AC-006: checker replaces only auth"
  run_rc 2 "$SCRIPTS/spec-dispatch-ready.sh" codex review
}

# AC-004/AC-005: the scheduler's only host-facing commands are replaced by
# executable fixtures on PATH. These tests never invoke the real scheduler.
scheduler_fixture() { # <Darwin|Linux>
  local platform="$1" bindir="$SANDBOX/scheduler-bin"
  mkdir -p "$bindir" "$SANDBOX/home"
  cat > "$bindir/uname" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$SCHEDULER_PLATFORM"
EOF
  cat > "$bindir/date" <<'EOF'
#!/usr/bin/env bash
printf 'date %s\n' "$*" >> "$SCHEDULER_LOG"
case "$1" in
  -r) printf '01 00 01 01 2024\n' ;;
  *) /bin/date "$@" ;;
esac
EOF
  cat > "$bindir/launchctl" <<'EOF'
#!/usr/bin/env bash
printf 'launchctl %s\n' "$*" >> "$SCHEDULER_LOG"
if [[ "$1" == "list" && -f "$SCHEDULER_LIST" ]]; then cat "$SCHEDULER_LIST"; fi
EOF
  cat > "$bindir/crontab" <<'EOF'
#!/usr/bin/env bash
printf 'crontab %s\n' "$*" >> "$SCHEDULER_LOG"
case "${1:-}" in
  -l) [[ -f "$SCHEDULER_CRONTAB" ]] && cat "$SCHEDULER_CRONTAB" ;;
  -) cat > "$SCHEDULER_CRONTAB" ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$bindir"/*
  export SCHEDULER_PLATFORM="$platform"
  export SCHEDULER_LOG="$SANDBOX/scheduler.log"
  export SCHEDULER_LIST="$SANDBOX/scheduler.list"
  export SCHEDULER_CRONTAB="$SANDBOX/scheduler.crontab"
  export SCHEDULER_BIN="$bindir"
}

run_scheduler() {
  env HOME="$SANDBOX/home" PATH="$SCHEDULER_BIN:$PATH" \
    SCHEDULER_PLATFORM="$SCHEDULER_PLATFORM" SCHEDULER_LOG="$SCHEDULER_LOG" \
    SCHEDULER_LIST="$SCHEDULER_LIST" SCHEDULER_CRONTAB="$SCHEDULER_CRONTAB" \
    "$SCHEDULER" "$@"
}

test_AC_004_launchd_add_list_and_remove_are_one_shot_and_idempotent() {
  local unit_id="deadbeef" root="$SANDBOX/state root" plist
  scheduler_fixture Darwin
  plist="$SANDBOX/home/Library/LaunchAgents/com.sdd-kit.resume.$unit_id.plist"

  run_rc 0 run_scheduler add "$unit_id" 1704067201 "$root"
  [[ -f "$plist" ]] || t_fail "AC-004: launchd add writes its deterministic plist"
  assert_contains "$(cat "$plist")" '<key>Minute</key><integer>1</integer>' "AC-004: launchd rounds up to the next minute"
  assert_contains "$(cat "$plist")" "$root" "AC-004: launchd preserves the state root"
  assert_contains "$(cat "$plist")" 'spec-resume.sh' "AC-005: registered job runs the resume command"
  assert_contains "$(cat "$SCHEDULER_LOG")" 'launchctl bootstrap gui/' "AC-004: fixture received launchd registration"
  assert_contains "$(cat "$SCHEDULER_LOG")" 'date -r 1704067260' "AC-004: never rounds a due time down"

  run_rc 0 run_scheduler add "$unit_id" 1704067201 "$root"
  assert_eq 1 "$(find "$SANDBOX/home/Library/LaunchAgents" -name 'com.sdd-kit.resume.*.plist' | wc -l | tr -d ' ')" "AC-004: repeat add replaces rather than duplicates"
  printf '%s\n' "0 0 com.sdd-kit.resume.$unit_id" > "$SCHEDULER_LIST"
  run_rc 0 run_scheduler list
  assert_eq "$unit_id" "$OUT" "AC-005: list emits scheduler unit ids"

  run_rc 0 run_scheduler remove "$unit_id"
  [[ ! -e "$plist" ]] || t_fail "AC-005: remove deletes the launchd entry"
  run_rc 0 run_scheduler remove "$unit_id"
}

test_AC_004_cron_add_list_and_remove_are_marked_and_idempotent() {
  local unit_id="cafe1234" root="$SANDBOX/state root"
  scheduler_fixture Linux

  run_rc 0 run_scheduler add "$unit_id" 1704067201 "$root"
  assert_contains "$(cat "$SCHEDULER_CRONTAB")" '* * * * *' "AC-004: cron checks due units each minute"
  assert_contains "$(cat "$SCHEDULER_CRONTAB")" '# sdd-kit-resume:cafe1234' "AC-004: cron entry is marked"
  assert_contains "$(cat "$SCHEDULER_CRONTAB")" 'SDD_RESUME_ROOT=' "AC-004: cron preserves the state root"
  assert_contains "$(cat "$SCHEDULER_CRONTAB")" 'date +\%s' "AC-004: cron entry compares the epoch at runtime"

  run_rc 0 run_scheduler add "$unit_id" 1704067201 "$root"
  assert_eq 1 "$(grep -c '# sdd-kit-resume:cafe1234' "$SCHEDULER_CRONTAB")" "AC-004: repeat add leaves one marked job"
  run_rc 0 run_scheduler list
  assert_eq "$unit_id" "$OUT" "AC-005: cron list emits marked unit ids"
  run_rc 0 run_scheduler remove "$unit_id"
  assert_not_contains "$(cat "$SCHEDULER_CRONTAB")" '# sdd-kit-resume:cafe1234' "AC-005: cancel backend removes the marked entry"
  run_rc 0 run_scheduler remove "$unit_id"
  assert_contains "$(cat "$SCHEDULER_LOG")" 'crontab -' "AC-004: only the crontab fixture was invoked"
}

# AC-005: resume tests replace the scheduler with this command fixture. It
# records only the documented scheduler seam and never talks to launchd/cron.
resume_fixture() {
  RESUME="$SCRIPTS/spec-resume.sh"
  RESUME_ROOT="$SANDBOX/resume state"
  RESUME_SPEC="$SANDBOX/live spec"
  RESUME_SCHEDULER="$SANDBOX/resume-scheduler"
  RESUME_LOG="$SANDBOX/resume-scheduler.log"
  mkdir -p "$RESUME_SPEC"
  cat > "$RESUME_SPEC/STATUS.md" <<'EOF'
---
spec: 001-resume-test
updated: 2026-01-01
---
# STATUS

## Decisions log

(none)
EOF
  cat > "$RESUME_SCHEDULER" <<'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$RESUME_SCHEDULER_LOG"
case "$1" in
  add)
    awk -v id="$2" '$1 != id { print }' "$RESUME_SCHEDULER_JOBS" 2>/dev/null > "$RESUME_SCHEDULER_JOBS.tmp" || true
    printf '%s\n' "$2" >> "$RESUME_SCHEDULER_JOBS.tmp"
    mv "$RESUME_SCHEDULER_JOBS.tmp" "$RESUME_SCHEDULER_JOBS"
    ;;
  remove)
    [[ "${RESUME_SCHEDULER_FAIL_REMOVE:-0}" != 1 ]] || exit 1
    awk -v id="$2" '$1 != id { print }' "$RESUME_SCHEDULER_JOBS" 2>/dev/null > "$RESUME_SCHEDULER_JOBS.tmp" || true
    mv "$RESUME_SCHEDULER_JOBS.tmp" "$RESUME_SCHEDULER_JOBS"
    ;;
  list) cat "$RESUME_SCHEDULER_JOBS" 2>/dev/null || true ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$RESUME_SCHEDULER"
  export RESUME_SCHEDULER_LOG="$RESUME_LOG"
  export RESUME_SCHEDULER_JOBS="$SANDBOX/resume-scheduler.jobs"
  export RESUME_CWD="$SANDBOX/cwd with spaces"
  mkdir -p "$RESUME_CWD"
}

run_resume() {
  env SDD_RESUME_ROOT="$RESUME_ROOT" \
    SDD_RESUME_SCHEDULER="$RESUME_SCHEDULER" \
    SDD_RESUME_JITTER_SECONDS=0 \
    RESUME_SCHEDULER_LOG="$RESUME_SCHEDULER_LOG" \
    RESUME_SCHEDULER_JOBS="$RESUME_SCHEDULER_JOBS" \
    "$RESUME" "$@"
}

park_resume() { # <program> <argv...>
  ( cd "$RESUME_CWD" && run_resume park --spec "$RESUME_SPEC" --role implement --kind short --backoff-minutes 1 -- "$@" )
}

resume_recorder() {
  local program="$SANDBOX/resume-recorder"
  cat > "$program" <<'EOF'
#!/usr/bin/env bash
printf '%s\0' "$PWD" > "$RESUME_RECORDED_CWD"
printf '%s\0' "$@" > "$RESUME_RECORDED_ARGV"
exit "${RESUME_CHILD_EXIT:-0}"
EOF
  chmod +x "$program"
  printf '%s\n' "$program"
}

test_AC_005_resume_replays_adversarial_argv_and_success_removes_unit() {
  local child unit expected_argv expected_replay_argv expected_cwd
  resume_fixture
  child="$(resume_recorder)"
  export RESUME_RECORDED_CWD="$SANDBOX/recorded-cwd.nul"
  export RESUME_RECORDED_ARGV="$SANDBOX/recorded-argv.nul"
  expected_argv="$SANDBOX/expected-argv.nul"
  expected_replay_argv="$SANDBOX/expected-replay-argv.nul"
  expected_cwd="$SANDBOX/expected-cwd.nul"

  run_rc 0 park_resume "$child" 'space arg' 'quote"arg' '*' '' $'line\nbreak'
  unit="$(printf '%s\n' "$OUT" | tail -1)"
  [[ -d "$RESUME_ROOT/$unit" ]] || t_fail "AC-005: parking creates the deterministic private unit"
  printf '%s\0' "$child" 'space arg' 'quote"arg' '*' '' $'line\nbreak' > "$expected_argv"
  printf '%s\0' 'space arg' 'quote"arg' '*' '' $'line\nbreak' > "$expected_replay_argv"
  ( cd "$RESUME_CWD" && printf '%s\0' "$PWD" ) > "$expected_cwd"
  cmp -s "$expected_argv" "$RESUME_ROOT/$unit/argv.nul" || t_fail "AC-005: unit stores argv byte-for-byte as NUL records"
  cmp -s "$expected_cwd" "$RESUME_ROOT/$unit/cwd.nul" || t_fail "AC-005: unit stores cwd as a NUL record"

  run_rc 0 env RESUME_RECORDED_CWD="$RESUME_RECORDED_CWD" RESUME_RECORDED_ARGV="$RESUME_RECORDED_ARGV" \
    SDD_RESUME_ROOT="$RESUME_ROOT" SDD_RESUME_SCHEDULER="$RESUME_SCHEDULER" \
    SDD_RESUME_JITTER_SECONDS=0 RESUME_SCHEDULER_LOG="$RESUME_SCHEDULER_LOG" \
    RESUME_SCHEDULER_JOBS="$RESUME_SCHEDULER_JOBS" "$RESUME" run "$unit"
  cmp -s "$expected_replay_argv" "$RESUME_RECORDED_ARGV" || t_fail "AC-005: replay invokes every original argv byte unchanged"
  cmp -s "$expected_cwd" "$RESUME_RECORDED_CWD" || t_fail "AC-005: replay restores the original cwd"
  [[ ! -e "$RESUME_ROOT/$unit" ]] || t_fail "AC-005: successful replay removes its unit"
  assert_contains "$(cat "$RESUME_SCHEDULER_LOG")" "remove $unit" "AC-005: runner removes the firing job before replay"
  assert_contains "$(cat "$RESUME_SPEC/STATUS.md")" "resume unit $unit succeeded" "AC-005: success records through STATUS API"
}

# AC-005: a transient scheduler failure before replay must not strand a pending
# unit behind its lock; the same unit can run once the scheduler recovers.
test_AC_005_scheduler_remove_failure_releases_lock_and_retries_same_unit() {
  local child unit expected_replay_argv
  resume_fixture
  child="$(resume_recorder)"
  export RESUME_RECORDED_CWD="$SANDBOX/remove-failure-cwd.nul"
  export RESUME_RECORDED_ARGV="$SANDBOX/remove-failure-argv.nul"
  expected_replay_argv="$SANDBOX/remove-failure-expected-argv.nul"

  run_rc 0 park_resume "$child" 'retry same unit'
  unit="$(printf '%s\n' "$OUT" | tail -1)"
  printf '%s\0' 'retry same unit' > "$expected_replay_argv"

  export RESUME_SCHEDULER_FAIL_REMOVE=1
  run_rc 1 run_resume run "$unit"
  unset RESUME_SCHEDULER_FAIL_REMOVE
  [[ -d "$RESUME_ROOT/$unit" ]] || t_fail "AC-005: remove failure leaves the unit pending for retry"
  assert_contains "$(cat "$RESUME_ROOT/$unit/unit.tsv")" $'state\tpending' \
    "AC-005: remove failure does not advance the unit state"
  [[ ! -e "$RESUME_ROOT/.$unit.lock" ]] || t_fail "AC-005: remove failure releases the unit lock"
  [[ ! -e "$RESUME_RECORDED_ARGV" ]] || t_fail "AC-005: remove failure does not execute stored argv"
  assert_contains "$(cat "$RESUME_SCHEDULER_JOBS")" "$unit" \
    "AC-005: remove failure preserves the scheduler job for retry"

  run_rc 0 run_resume run "$unit"
  cmp -s "$expected_replay_argv" "$RESUME_RECORDED_ARGV" || \
    t_fail "AC-005: recovered scheduler replays the same unit argv"
  [[ ! -e "$RESUME_ROOT/$unit" ]] || t_fail "AC-005: recovered replay removes the same unit"
  assert_eq 2 "$(grep -c "^remove $unit$" "$RESUME_SCHEDULER_LOG")" \
    "AC-005: same unit retries scheduler removal after recovery"
}

# T013o3 (AC-005): a transient scheduler remove failure during cancel must
# release the unit lock and keep the pending unit and its job, so cancel can
# retry once the scheduler recovers — never a stale lock or an orphaned job.
test_T013o3_cancel_scheduler_remove_failure_releases_lock_and_recovers() {
  local child unit
  resume_fixture
  child="$(resume_recorder)"
  export RESUME_RECORDED_CWD="$SANDBOX/cancel-failure-cwd.nul"
  export RESUME_RECORDED_ARGV="$SANDBOX/cancel-failure-argv.nul"

  run_rc 0 park_resume "$child" 'cancel recovery unit'
  unit="$(printf '%s\n' "$OUT" | tail -1)"

  export RESUME_SCHEDULER_FAIL_REMOVE=1
  run_rc 1 run_resume cancel "$unit"
  unset RESUME_SCHEDULER_FAIL_REMOVE
  [[ -d "$RESUME_ROOT/$unit" ]] || t_fail "T013o3: remove failure keeps the unit"
  assert_contains "$(cat "$RESUME_ROOT/$unit/unit.tsv")" $'state\tpending' \
    "T013o3: remove failure does not advance the unit state"
  [[ ! -e "$RESUME_ROOT/.$unit.lock" ]] || t_fail "T013o3: remove failure releases the unit lock"
  assert_contains "$(cat "$RESUME_SCHEDULER_JOBS")" "$unit" \
    "T013o3: remove failure preserves the scheduler job"

  run_rc 0 run_resume cancel "$unit"
  [[ ! -e "$RESUME_ROOT/$unit" ]] || t_fail "T013o3: recovered cancel removes the unit"
  [[ ! -e "$RESUME_ROOT/.$unit.lock" ]] || t_fail "T013o3: recovered cancel releases the unit lock"
  assert_eq 2 "$(grep -c "^remove $unit$" "$RESUME_SCHEDULER_LOG")" \
    "T013o3: cancel retries scheduler removal after recovery"
  ! grep -q "$unit" "$RESUME_SCHEDULER_JOBS" || \
    t_fail "T013o3: recovered cancel removes the scheduler job"
  assert_contains "$(cat "$RESUME_SPEC/STATUS.md")" "cancelled resume unit $unit" \
    "T013o3: recovered cancel records the STATUS event"
}

test_AC_005_generic_failure_marks_failed_and_list_cancel_reconcile_scheduler() {
  local child unit
  resume_fixture
  child="$(resume_recorder)"
  export RESUME_RECORDED_CWD="$SANDBOX/ignored-cwd"
  export RESUME_RECORDED_ARGV="$SANDBOX/ignored-argv"
  run_rc 0 park_resume "$child" failure
  unit="$(printf '%s\n' "$OUT" | tail -1)"
  run_rc 5 env RESUME_CHILD_EXIT=5 RESUME_RECORDED_CWD="$RESUME_RECORDED_CWD" RESUME_RECORDED_ARGV="$RESUME_RECORDED_ARGV" \
    SDD_RESUME_ROOT="$RESUME_ROOT" SDD_RESUME_SCHEDULER="$RESUME_SCHEDULER" SDD_RESUME_JITTER_SECONDS=0 \
    RESUME_SCHEDULER_LOG="$RESUME_SCHEDULER_LOG" RESUME_SCHEDULER_JOBS="$RESUME_SCHEDULER_JOBS" "$RESUME" run "$unit"
  assert_contains "$(cat "$RESUME_ROOT/$unit/unit.tsv")" $'state\tfailed' "AC-005: generic replay failure persists failed state"
  run_rc 0 run_resume list --tsv
  assert_contains "$OUT" "$unit" "AC-005: list shows failed units"
  run_rc 0 run_resume cancel "$unit"
  [[ ! -e "$RESUME_ROOT/$unit" ]] || t_fail "AC-005: cancel removes the private unit"
  assert_not_contains "$(cat "$RESUME_SCHEDULER_JOBS")" "$unit" "AC-005: cancel removes the scheduler entry"
}

test_AC_005_repeat_limit_reparks_via_nested_dispatcher_and_stops_at_three() {
  local child unit
  resume_fixture
  child="$SANDBOX/reparking-dispatcher"
  cat > "$child" <<'EOF'
#!/usr/bin/env bash
"$RESUME_CLI" park --spec "$RESUME_SPEC" --role implement --kind short --backoff-minutes 1 -- "$0" "$@" >/dev/null
exit 7
EOF
  chmod +x "$child"
  export RESUME_CLI="$RESUME"
  run_rc 0 park_resume "$child" 'same arg'
  unit="$(printf '%s\n' "$OUT" | tail -1)"

  run_rc 7 env RESUME_CLI="$RESUME_CLI" RESUME_SPEC="$RESUME_SPEC" SDD_RESUME_ROOT="$RESUME_ROOT" \
    SDD_RESUME_SCHEDULER="$RESUME_SCHEDULER" SDD_RESUME_JITTER_SECONDS=0 \
    RESUME_SCHEDULER_LOG="$RESUME_SCHEDULER_LOG" RESUME_SCHEDULER_JOBS="$RESUME_SCHEDULER_JOBS" "$RESUME" run "$unit"
  assert_contains "$(cat "$RESUME_ROOT/$unit/unit.tsv")" $'state\tpending' "AC-005: nested dispatcher alone reparks the limit"
  run_rc 7 env RESUME_CLI="$RESUME_CLI" RESUME_SPEC="$RESUME_SPEC" SDD_RESUME_ROOT="$RESUME_ROOT" \
    SDD_RESUME_SCHEDULER="$RESUME_SCHEDULER" SDD_RESUME_JITTER_SECONDS=0 \
    RESUME_SCHEDULER_LOG="$RESUME_SCHEDULER_LOG" RESUME_SCHEDULER_JOBS="$RESUME_SCHEDULER_JOBS" "$RESUME" run "$unit"
  run_rc 7 env RESUME_CLI="$RESUME_CLI" RESUME_SPEC="$RESUME_SPEC" SDD_RESUME_ROOT="$RESUME_ROOT" \
    SDD_RESUME_SCHEDULER="$RESUME_SCHEDULER" SDD_RESUME_JITTER_SECONDS=0 \
    RESUME_SCHEDULER_LOG="$RESUME_SCHEDULER_LOG" RESUME_SCHEDULER_JOBS="$RESUME_SCHEDULER_JOBS" "$RESUME" run "$unit"
  assert_contains "$(cat "$RESUME_ROOT/$unit/unit.tsv")" $'state\tfailed' "AC-005: third replay stops re-parking at the fixed cap"
  assert_eq 3 "$(grep -c '^add ' "$RESUME_SCHEDULER_LOG")" "AC-005: initial park plus two repeats register exactly three jobs"
  assert_eq 0 "$(wc -l < "$RESUME_SCHEDULER_JOBS" | tr -d ' ')" "AC-005: retry-cap failure leaves no scheduler job"
}

# AC-009: doctor runs against a copied kit, a private HOME, and the documented
# scheduler override. It cannot inspect a real account, credentials, or host
# scheduler while reconciling its deterministic fixture state.
doctor_fixture() {
  DOCTOR_KIT="$SANDBOX/doctor-kit"
  DOCTOR_HOME="$SANDBOX/doctor-home"
  DOCTOR_BIN="$SANDBOX/doctor-bin"
  DOCTOR_ROOT="$SANDBOX/doctor-resume-root"
  DOCTOR_SCHEDULER="$SANDBOX/doctor-resume-scheduler"
  DOCTOR_JOBS="$SANDBOX/doctor-scheduler-jobs"
  cp -R "$KIT_DIR" "$DOCTOR_KIT"
  mkdir -p "$DOCTOR_HOME" "$DOCTOR_BIN" "$DOCTOR_ROOT" "$DOCTOR_KIT/build"
  : > "$DOCTOR_KIT/registry.yml"
  : > "$DOCTOR_KIT/build/.stamp"
  cat > "$DOCTOR_SCHEDULER" <<'EOF'
#!/usr/bin/env bash
set -u
case "${1:-}" in
  list) cat "$DOCTOR_SCHEDULER_JOBS" 2>/dev/null || true ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$DOCTOR_SCHEDULER"
}

doctor_policy() { # <on_limit body>
  cat > "$DOCTOR_KIT/models.yml" <<EOF
tiers:
  implementation:
    codex_model: gpt-5.6-terra
roles:
  plan: implementation
dispatch:
  plan: codex
$1
EOF
}

doctor_unit() { # <id> <state>
  local unit_id="$1" state="$2"
  mkdir -p "$DOCTOR_ROOT/$unit_id"
  cat > "$DOCTOR_ROOT/$unit_id/unit.tsv" <<EOF
state	$state
live_spec	$SANDBOX/live-spec
role	plan
kind	long
reset_epoch	
run_at_epoch	1704067200
retry_count	1
max_retries	3
last_exit	
created_at	1704060000
updated_at	1704060000
EOF
}

run_doctor() {
  env HOME="$DOCTOR_HOME" PATH="$DOCTOR_BIN:/usr/bin:/bin" \
    SDD_RESUME_ROOT="$DOCTOR_ROOT" \
    SDD_RESUME_SCHEDULER="$DOCTOR_SCHEDULER" \
    DOCTOR_SCHEDULER_JOBS="$DOCTOR_JOBS" \
    "$DOCTOR_KIT/scripts/sdd-doctor.sh" --hub-only
}

test_AC_009_doctor_reports_invalid_limit_policy_and_unready_fallbacks() {
  doctor_fixture
  doctor_policy $'on_limit:\n  long: launch\n  fallback: [claude, copilot]'

  run_rc 1 run_doctor
  assert_contains "$OUT" "models.yml invalid" "AC-009: doctor rejects an invalid on_limit block"
  assert_contains "$OUT" "on_limit: long action 'launch'" "AC-009: parser names the invalid limit action"

  doctor_fixture
  doctor_policy $'on_limit:\n  long: delegate\n  fallback: [claude, copilot]'
  cat > "$DOCTOR_BIN/claude" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$DOCTOR_BIN/claude"

  run_rc 0 run_doctor
  assert_contains "$OUT" "on_limit fallback: claude unavailable for plan" \
    "AC-009: doctor reports a fallback with no role adapter"
  assert_contains "$OUT" "missing plan adapter" \
    "AC-009: doctor preserves the readiness reason for the adapter-missing fallback"
  assert_contains "$OUT" "on_limit fallback: copilot unavailable for plan" \
    "AC-009: doctor reports a fallback CLI missing from PATH"
  assert_contains "$OUT" "binary not on PATH" \
    "AC-009: doctor preserves the readiness reason for the missing fallback"
}

test_AC_009_doctor_reconciles_pending_failed_and_both_orphan_classes_without_models() {
  local pending="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  local failed="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  local job_only="cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
  doctor_fixture
  doctor_unit "$pending" pending
  doctor_unit "$failed" failed
  printf '%s\n%s\n' "$failed" "$job_only" > "$DOCTOR_JOBS"

  run_rc 0 run_doctor
  assert_contains "$OUT" "models.yml not configured" \
    "AC-009: missing policy does not skip resume reconciliation"
  assert_contains "$OUT" "resume: pending unit $pending" \
    "AC-009: doctor surfaces every pending unit"
  assert_contains "$OUT" "resume: failed unit $failed" \
    "AC-009: doctor surfaces every failed unit"
  assert_contains "$OUT" "resume orphan: pending unit $pending has no scheduler job" \
    "AC-009: doctor reports a unit-without-job orphan"
  assert_contains "$OUT" "resume orphan: scheduler job $job_only has no resume unit" \
    "AC-009: doctor reports a job-without-unit orphan"
}

# AC-010: public policy docs must stay aligned with the parser and preserve the
# default-off, explicitly-commented example contract.
test_AC_010_documents_exact_limit_policy_keys_and_recovery_workflows() {
  local readme example knowledge parser_contract document key
  readme="$(cat "$KIT_DIR/README.md")"
  example="$(cat "$KIT_DIR/models.example.yml")"
  knowledge="$(cat "$KIT_DIR/knowledge/usage-limit-handling.md")"
  parser_contract="$(sed -n '/require_limit_key()/,/^}/p' "$SCRIPTS/model-policy.sh")"

  for key in short long fallback backoff_minutes; do
    assert_contains "$parser_contract" "$key" "AC-010: parser accepts '$key'"
    for document in "$readme" "$example" "$knowledge"; do
      assert_contains "$document" "$key" "AC-010: every policy document names parser key '$key'"
    done
  done

  assert_contains "$readme" 'no `on_limit:` block' "AC-010: README states the default-off policy"
  assert_contains "$readme" "automatically parked" "AC-010: README explains automatic recovery"
  assert_contains "$readme" "scripts/spec-resume.sh list" "AC-010: README explains manual recovery"
  assert_contains "$example" "# on_limit:" "AC-010: example keeps the opt-in block commented out"
  assert_not_contains "$example" $'\non_limit:' "AC-010: example does not enable on_limit by default"
  assert_contains "$knowledge" "Message provenance" "AC-010: knowledge note records message provenance"
  assert_contains "$knowledge" "may change their messages" "AC-010: knowledge note warns that provider wording drifts"
  assert_contains "$knowledge" "interactive session" "AC-010: knowledge note covers interactive sessions"
  assert_contains "$knowledge" "fresh interactive session" "AC-010: knowledge note gives the manual interactive recipe"
}

t_run_all
