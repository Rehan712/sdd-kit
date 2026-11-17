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

# Two identical captures share one manifest. A v1 capture in the same spec
# still authenticates its own sealed copies, even if the v2 store is damaged.
test_capture_manifest_storage() {
  local spec repo store dir first second digest key objects
  . "$SCRIPTS/verification-lib.sh"
  spec="$(make_verification_git_dir shared)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  store="$spec/notes/captures/manifests"
  run_rc 0 "$SPEC_RUN" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  first="${OUT#capture=}"; first="${first%% *}"
  run_rc 0 "$SPEC_RUN" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  second="${OUT#capture=}"; second="${second%% *}"
  objects=("$store"/*.nul)
  assert_eq 1 "${#objects[@]}" 'identical manifests should occupy one file'
  dir="$spec/notes/captures/$first"
  vf_meta_load "$dir/meta.nul" "$VF_CAPTURE_KEYS" || t_fail 'metadata'
  digest="$(vf_meta_get input_before)"
  assert_eq "$digest" "$(vf_hash "$store/$digest.nul")"
  [[ ! -e "$dir/inputs.nul" && ! -e "$dir/inputs-after.nul" ]] || t_fail 'duplicate inline manifest'
  run_rc 0 vf_capture_check "$spec" "$first" "$store/$digest.nul" current
  run_rc 0 vf_capture_check "$spec" "$second" "$store/$digest.nul" current

  # Rebuild the first record with the original v1 layout and ledger.
  cp "$store/$digest.nul" "$dir/inputs.nul" && cp "$dir/inputs.nul" "$dir/inputs-after.nul" || t_fail 'v1 manifests'
  {
    printf '%s\0' version 1
    for key in $VF_CAPTURE_KEYS; do
      [[ "$key" == version ]] || printf '%s\0' "$key" "$(vf_meta_get "$key")"
    done
  } > "$dir/meta.nul"
  rm "$dir/COMPLETE" && vf_seal "$dir" meta.nul argv.nul inputs.nul inputs-after.nul bindings.nul output.log summary.txt &&
    cp "$dir/COMPLETE" "$spec/notes/verification/captures/$first" || t_fail 'v1 seal'
  mv "$store/$digest.nul" "$SANDBOX/original"
  run_rc 0 vf_capture_check "$spec" "$first" "$SANDBOX/original" current
  run_rc 3 vf_capture_check "$spec" "$second" '' integrity
  ln -s "$SANDBOX/original" "$store/$digest.nul"
  run_rc 3 vf_capture_check "$spec" "$second" '' integrity
  rm "$store/$digest.nul"; echo damaged > "$store/$digest.nul"
  run_rc 3 vf_capture_check "$spec" "$second" '' integrity
  run_rc 3 "$SPEC_RUN" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  [[ "$(cat "$store/$digest.nul")" == damaged ]] || t_fail 'existing manifest overwritten'
  mv "$SANDBOX/original" "$store/$digest.nul"
  run_rc 0 vf_capture_check "$spec" "$second" '' integrity
}

# --return prints the block a worker hands back: the script builds it from the
# capture and the task's bindings, and deterministic acceptance takes it as
# printed. A failing capture prints the failure summary and no block.
test_return_flag_prints_a_block_that_accept_takes() {
  local spec repo
  spec="$(make_verification_git_dir returnblock)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  run_rc 0 "$SPEC_RUN" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary --return
  assert_contains "$OUT" 'Verification-Return: 1'
  assert_contains "$OUT" 'Task: T001'
  assert_contains "$OUT" 'Summary: capture='
  assert_contains "$OUT" 'FM-001, tests/check.sh::test_ac_001_shared, '
  mkdir -p "$spec/notes/verification/returns"
  printf '%s\n' "$OUT" > "$spec/notes/verification/returns/T001.txt"
  run_rc 0 "$SCRIPTS/spec-gate.sh" accept "$spec" T001 "$spec/notes/verification/returns/T001.txt"
  assert_contains "$(cat "$spec/tasks.md")" '- [x] **T001**'
  run_rc 7 "$SPEC_RUN" "$spec" T001 --cwd "$repo" --no-tick --summary --return -- bash -c 'echo broke; exit 7'
  assert_not_contains "$OUT" 'Verification-Return' 'a failing capture printed a return block'
  assert_contains "$OUT" 'exit=7'
}

t_run_all
