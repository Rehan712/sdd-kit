#!/usr/bin/env bash
# test-spec-run.sh — evidence as captured runs: execute, record, then tick.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
SPEC_RUN="$SCRIPTS/spec-run.sh"

test_passing_command_records_and_ticks() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_RUN" "$spec_dir" T002 -- echo "3 passed"
  local block; block="$("$SCRIPTS/spec-task.sh" show "$spec_dir" T002)"
  assert_contains "$block" "- [x] **T002**"
  assert_contains "$block" "echo 3 passed → 3 passed (see notes/evidence.md)"
  local ev; ev="$(cat "$spec_dir/notes/evidence.md")"
  assert_contains "$ev" "## T002 — "
  assert_contains "$ev" "**Exit:** 0"
  assert_contains "$ev" "3 passed"
}

test_failing_command_keeps_box_unticked_but_records() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 7 "$SPEC_RUN" "$spec_dir" T002 -- sh -c 'echo boom; exit 7'
  assert_contains "$OUT" "FAILED"
  assert_contains "$(cat "$spec_dir/tasks.md")" "- [ ] **T002**" "box untouched"
  local ev; ev="$(cat "$spec_dir/notes/evidence.md")"
  assert_contains "$ev" "**Exit:** 7" "failed run still recorded"
  assert_contains "$ev" "boom"
}

test_no_tick_captures_only() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_RUN" "$spec_dir" T002 --no-tick -- echo ok
  assert_contains "$(cat "$spec_dir/tasks.md")" "- [ ] **T002**"
  assert_contains "$(cat "$spec_dir/notes/evidence.md")" "**Exit:** 0"
}

test_key_flag_picks_the_evidence_line() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 0 "$SPEC_RUN" "$spec_dir" T002 --key 'passed' -- \
    sh -c 'printf "collecting\n14 passed\ncleanup done\n"'
  assert_contains "$("$SCRIPTS/spec-task.sh" show "$spec_dir" T002)" "→ 14 passed" \
    "--key match beats the last line"
}

test_usage_errors() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  run_rc 2 "$SPEC_RUN" "$spec_dir" T002            # no `--`
  run_rc 2 "$SPEC_RUN" "$spec_dir" T002 --         # empty command
  run_rc 1 "$SPEC_RUN" "$spec_dir" T999 -- echo hi # unknown task
  assert_contains "$(cat "$spec_dir/tasks.md")" "updated: 2026-01-01" "no mutation on failure"
}

# AC-021: full logs, actual argv/exits, pipeline failure and measured byte bounds.
test_bounded_capture() {
  local spec repo cap bytes before lib="$SCRIPTS/verification-lib.sh"
  spec="$(make_verification_git_dir bounded)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  before="$(cat "$spec/tasks.md")"
  run_rc 0 "$SPEC_RUN" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  assert_contains "$OUT" 'exit=0'
  assert_contains "$OUT" 'key=passed'
  assert_eq 1 "$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')" 'AC-021: one success line'
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  [[ -f "$spec/notes/captures/$cap/COMPLETE" ]] || t_fail 'AC-021: capture is incomplete'
  assert_eq "$before" "$(cat "$spec/tasks.md")" 'AC-021: no tick'
  run_rc 0 bash -c '. "$1"; vf_integrity "$2" "${VF_CAPTURE_FILES[@]}"' _ "$lib" "$spec/notes/captures/$cap"
  run_rc 0 "$SPEC_RUN" "$spec" T001 --cwd "$repo" --no-tick --summary --key passed -- bash -c 'printf "passed\n"; awk "BEGIN {for(i=0;i<4000;i++) print i, \"diagnostic line\"}"'
  assert_contains "$OUT" 'key=passed'
  bytes="$(printf '%s\n' "$OUT" | wc -c | tr -d ' ')"
  [[ "$bytes" -le 2048 ]] || t_fail 'AC-021: success exceeds 2 KiB'
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  assert_eq 4001 "$(wc -l < "$spec/notes/captures/$cap/output.log" | tr -d ' ')" 'AC-021: log never truncated'
  run_rc 7 "$SPEC_RUN" "$spec" T001 --cwd "$repo" --no-tick --summary -- bash -c 'awk "BEGIN {for(i=0;i<100;i++) print i, \"failure line\"}"; exit 7'
  assert_contains "$OUT" 'exit=7'
  bytes="$(printf '%s\n' "$OUT" | wc -c | tr -d ' ')"
  [[ "$bytes" -le 8192 ]] || t_fail 'AC-021: failure exceeds 8 KiB'
  [[ "$(printf '%s\n' "$OUT" | wc -l)" -le 21 ]] || t_fail 'AC-021: more than 20 diagnostic lines'
  sed 's/`bash tests\/check.sh`/`false | true`/' "$spec/tasks.md" > "$SANDBOX/tasks"
  cp "$SANDBOX/tasks" "$spec/tasks.md"
  run_rc 1 "$SPEC_RUN" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  assert_contains "$OUT" 'exit=1'
  run_rc 0 "$SPEC_RUN" "$spec" T001 --cwd "$repo" --no-tick --summary -- printf '%s\n' 'two  spaces' 'a*b' 'line
break'
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  printf '%s\0' printf '%s\n' 'two  spaces' 'a*b' 'line
break' > "$SANDBOX/argv"
  run_rc 0 cmp "$SANDBOX/argv" "$spec/notes/captures/$cap/argv.nul"
}

t_run_all
