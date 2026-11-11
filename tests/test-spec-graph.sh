#!/usr/bin/env bash
# test-spec-graph.sh — the task graph (spec-graph.sh) and the outer loop that
# walks it (spec-loop.sh).

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
. "$SCRIPTS/lib.sh"
GRAPH="$SCRIPTS/spec-graph.sh"
LOOP="$SCRIPTS/spec-loop.sh"

# write_tasks <spec-dir> — replace tasks.md with the body on stdin.
write_tasks() { { printf -- '---\ntasks_for: x\n---\n'; cat; } > "$1/tasks.md"; }

# tick <spec-dir> <id>
tick() { sed "s/^- \[[ ~]\] \*\*$2\*\*/- [x] **$2**/" "$1/tasks.md" > "$1/tasks.tmp" && mv "$1/tasks.tmp" "$1/tasks.md"; }

# open_followups <spec-dir> <printf-format> — insert task lines where a gate
# opens its follow-ups: at the end of the Reality Check stage.
open_followups() {
  # shellcheck disable=SC2059
  FOLLOWUPS="$(printf -- "$2")" awk '/^## Ship/ { print ENVIRON["FOLLOWUPS"]; print "" } { print }' \
    "$1/tasks.md" > "$1/tasks.tmp" && mv "$1/tasks.tmp" "$1/tasks.md"
}

ids() { printf '%s\n' "$OUT" | cut -f1 | tr '\n' ' '; }

test_stage_order_is_hard_and_plain_tasks_are_serial() {
  local spec; spec="$(make_spec_dir)"
  run_rc 0 "$GRAPH" next "$spec"
  assert_eq "T001 " "$(ids)" "only Setup is ready"
  tick "$spec" T001
  run_rc 0 "$GRAPH" next "$spec"
  assert_eq "T002 " "$(ids)" "T003 is not [P]: it waits for T002"
  assert_contains "$OUT" "$(printf 'T002\ttodo\ttask\tBackend\t-\tImplement the thing endpoint')"
}

test_parallel_siblings_batch_unless_their_files_collide() {
  local spec; spec="$(make_spec_dir)"
  write_tasks "$spec" <<'EOF'
## Backend

- [ ] **T001** [P] — a
  - *Files:* `src/a.js`
- [ ] **T002** [P] [hard] — b
  - *Files:* `src/b.js`
- [ ] **T003** [P] — same file as a
  - *Files:* `src/a.js`
- [ ] **T004** [P] — inside a directory another task owns
  - *Files:* `lib/x.js`
- [ ] **T005** [P] — owns the directory
  - *Files:* `lib`
- [ ] **T006** [P] — owns it too, spelled as the template does
  - *Files:* `lib/...`
- [ ] **T007** [P] — declares no files, so proves nothing
EOF
  run_rc 0 "$GRAPH" next "$spec"
  assert_eq "T001 T002 T004 " "$(ids)"
  assert_contains "$OUT" "$(printf 'T002\ttodo\ttask\tBackend\tP,hard\tb')"
  run_rc 0 "$GRAPH" waves "$spec"
  assert_contains "$OUT" "$(printf '2\tT003')"
  assert_contains "$OUT" "$(printf '2\tT005')"
  assert_contains "$OUT" "$(printf '3\tT006')"
  assert_contains "$OUT" "$(printf '4\tT007')"
}

test_umbrella_repos_never_collide() {
  local spec; spec="$(make_spec_dir)"
  write_tasks "$spec" <<'EOF'
## Backend

- [ ] **T001** [P] [repo:api] — a
  - *Files:* `src/a.js`
- [ ] **T002** [P] [repo:web] — b
  - *Files:* `src/a.js`
EOF
  run_rc 0 "$GRAPH" next "$spec"
  assert_eq "T001 T002 " "$(ids)"
  assert_contains "$OUT" "P,repo:web"
}

test_depends_on_adds_an_edge_in_both_spellings() {
  local spec; spec="$(make_spec_dir)"
  write_tasks "$spec" <<'EOF'
## Backend

- [ ] **T001** [P] — a
  - *Files:* `a`
- [ ] **T002** [P] — b
  - *Files:* `b`
  - *Depends on:* T001
- [ ] **T003** [P] — c
  - *Files:* `c`
  - Depends on: T001 and T002 (T003 and T099 in a reason are prose, not edges)
EOF
  run_rc 0 "$GRAPH" waves "$spec"
  assert_eq "1 2 3 " "$(printf '%s\n' "$OUT" | cut -f1 | tr '\n' ' ')" "three waves, one task each"
}

test_followups_go_first_and_a_gate_runs_alone() {
  local spec; spec="$(make_spec_dir)"
  tick "$spec" T001; tick "$spec" T002; tick "$spec" T003
  run_rc 0 "$GRAPH" next "$spec"
  assert_eq "T009 " "$(ids)" "the opponent gate, alone"
  assert_contains "$OUT" "$(printf 'T009\ttodo\tgate')"
  # CHALLENGED: follow-ups open under the gate; the gate waits for them.
  open_followups "$spec" '- [ ] **T009o1** — fix one\n  - *Files:* `src/one.js`\n- [~] **T009o2** — fix two\n  - *Files:* `src/two.js`\n'
  run_rc 0 "$GRAPH" next "$spec"
  assert_eq "T009o1 T009o2 " "$(ids)"
  assert_contains "$OUT" "$(printf 'T009o2\tdoing\tfollowup')"
  tick "$spec" T009o1; tick "$spec" T009o2
  run_rc 0 "$GRAPH" next "$spec"
  assert_eq "T009 " "$(ids)" "the gate re-runs once its follow-ups are done"
  tick "$spec" T009; tick "$spec" T010
  run_rc 0 "$GRAPH" next "$spec"
  assert_contains "$OUT" "$(printf 'T011\ttodo\tship\tShip')"
  tick "$spec" T011
  run_rc 0 "$GRAPH" next "$spec"
  assert_eq "" "$OUT" "nothing left prints nothing"
}

# A follow-up filed under a later stage (a CI fix under Ship) still holds every
# gate back: a gate never judges code a follow-up is about to change.
test_a_gate_waits_for_a_followup_in_any_stage() {
  local spec; spec="$(make_spec_dir)"
  tick "$spec" T001; tick "$spec" T002; tick "$spec" T003
  printf -- '- [ ] **T011c1** — fix CI\n  - *Files:* `src/ci.js`\n' >> "$spec/tasks.md"
  run_rc 0 "$GRAPH" next "$spec"
  assert_eq "T011c1 " "$(ids)"
  tick "$spec" T011c1
  run_rc 0 "$GRAPH" next "$spec"
  assert_eq "T009 " "$(ids)"
}

test_analyze_fails_an_invalid_graph() {
  local spec; spec="$(make_spec_dir)"
  run_rc 0 "$SCRIPTS/sdd-analyze.sh" "$spec"
  assert_contains "$OUT" "task graph ok: 6 tasks"
  printf -- '  - *Depends on:* T099\n' >> "$spec/tasks.md"
  run_rc 1 "$SCRIPTS/sdd-analyze.sh" "$spec"
  assert_contains "$OUT" "task graph invalid"
  assert_contains "$OUT" "T011 depends on T099, which is not a task"
}

test_an_invalid_graph_prints_no_batch() {
  local spec; spec="$(make_spec_dir)"
  write_tasks "$spec" <<'EOF'
## Backend

- [ ] **T001** — a
  - *Depends on:* T002
- [ ] **T002** — b
- [ ] **T003** [P] — c
  - *Depends on:* T099, T003
- [ ] **T002** — duplicate
EOF
  run_rc 1 "$GRAPH" check "$spec"
  assert_contains "$OUT" "dependency cycle among: T001 T002"
  assert_contains "$OUT" "T003 depends on T099, which is not a task"
  assert_contains "$OUT" "T003 depends on itself"
  assert_contains "$OUT" "duplicate task id T002"
  run_rc 1 "$GRAPH" next "$spec"
  assert_not_contains "$OUT" "$(printf 'T003\ttodo')"
  run_rc 0 "$GRAPH" check "$(make_spec_dir)"
  assert_contains "$OUT" "graph ok: 6 tasks, 6 open"
  run_rc 2 "$GRAPH" frobnicate "$spec"
  run_rc 1 "$GRAPH" next "$SANDBOX"
}

# The golden example every new task list is modelled on is a valid graph.
test_golden_example_is_a_valid_graph() {
  run_rc 0 "$GRAPH" check "$KIT_DIR/templates/examples/001-api-key-expiry"
  assert_contains "$OUT" "graph ok: 12 tasks"
}

# --- spec-loop.sh ---------------------------------------------------------------

# loop_fixture — a spec whose STATUS names a "worktree" holding the live copy,
# and a stub dispatcher that logs its argv and runs $STUB_ACTION on the live
# tasks.md. Echoes the spec dir; the live dir is $SANDBOX/wt/.specify/specs/…
loop_fixture() {
  local spec; spec="$(make_spec_dir)"
  mkdir -p "$SANDBOX/wt"
  cp -R "$SANDBOX/proj/.specify" "$SANDBOX/wt/.specify"
  fm_set "$spec/STATUS.md" worktree "$SANDBOX/wt"
  cat > "$SANDBOX/dispatch" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG"
live="$STUB_LIVE"; task="$4"
case "$STUB_ACTION" in
  tick) sed "s/^- \[[ ~]\] \*\*$task\*\*/- [x] **$task**/" "$live/tasks.md" > "$live/t" && mv "$live/t" "$live/tasks.md" ;;
  challenge) # a gate opens one follow-up the first time, then clears
    if grep -q "T009o1" "$live/tasks.md"; then
      sed "s/^- \[[ ~]\] \*\*$task\*\*/- [x] **$task**/" "$live/tasks.md" > "$live/t" && mv "$live/t" "$live/tasks.md"
    elif [[ "$task" == T009 ]]; then
      awk '/^## Ship/ { print "- [ ] **T009o1** — fix"; print "" } { print }' "$live/tasks.md" > "$live/t" && mv "$live/t" "$live/tasks.md"
    else
      sed "s/^- \[[ ~]\] \*\*$task\*\*/- [x] **$task**/" "$live/tasks.md" > "$live/t" && mv "$live/t" "$live/tasks.md"
    fi ;;
  nothing) exit 1 ;;
  park) exit 7 ;;
esac
EOF
  chmod +x "$SANDBOX/dispatch"
  echo "$spec"
}

run_loop() { # <expected-rc> <action> <spec> [loop args...]
  local want="$1" action="$2" spec="$3"; shift 3
  run_rc "$want" env SDD_LOOP_DISPATCH="$SANDBOX/dispatch" STUB_LOG="$SANDBOX/log" \
    STUB_LIVE="$SANDBOX/wt/.specify/specs/001-test-feature" STUB_ACTION="$action" "$LOOP" "$spec" "$@"
}

test_loop_walks_the_graph_one_task_per_session_and_stops_at_ship() {
  local spec; spec="$(loop_fixture)"
  run_loop 0 tick "$spec" --to codex
  assert_contains "$OUT" "iteration 5: T010 (gate)"
  assert_contains "$OUT" "loop done: 5/6 — next is T011"
  assert_eq "5" "$(grep -c . "$SANDBOX/log")" "one dispatch per task, none for the Ship task"
  assert_contains "$(sed -n 1p "$SANDBOX/log")" "implement $spec --task T001 --to codex --note spec-loop iteration 1"
  assert_not_contains "$(cat "$spec/tasks.md")" "[x]" "ticks land in the live worktree copy, never the base checkout"
}

test_loop_runs_a_parallel_batch_one_task_at_a_time() {
  local spec; spec="$(loop_fixture)"
  write_tasks "$SANDBOX/wt/.specify/specs/001-test-feature" <<'EOF'
## Backend

- [ ] **T001** [P] — a
  - *Files:* `a`
- [ ] **T002** [P] — b
  - *Files:* `b`
EOF
  run_loop 0 tick "$spec"
  assert_eq "T001 T002 " "$(sed 's/.*--task \([^ ]*\).*/\1/' "$SANDBOX/log" | tr '\n' ' ')"
  assert_contains "$OUT" "loop done: every task is ticked (2/2)"
}

test_loop_follows_a_challenged_gate_through_its_followup() {
  local spec; spec="$(loop_fixture)"
  run_loop 0 challenge "$spec"
  assert_eq "T001 T002 T003 T009 T009o1 T009 T010 " \
    "$(sed 's/.*--task \([^ ]*\).*/\1/' "$SANDBOX/log" | tr '\n' ' ')"
}

test_loop_stops_when_two_sessions_make_no_progress() {
  local spec; spec="$(loop_fixture)"
  run_loop 1 nothing "$spec"
  assert_contains "$OUT" "loop stalled: two sessions on T001"
  assert_eq "2" "$(grep -c . "$SANDBOX/log")"
  assert_contains "$(sed -n 2p "$SANDBOX/log")" "re-dispatch after a failed acceptance"
  assert_not_contains "$(sed -n 1p "$SANDBOX/log")" "re-dispatch after a failed acceptance"
}

test_loop_caps_iterations_and_passes_dispatcher_stops_through() {
  local spec; spec="$(loop_fixture)"
  run_loop 8 tick "$spec" --max-iterations 2
  assert_contains "$OUT" "iteration cap (2) reached at 2/6"
  run_loop 7 park "$spec"
  assert_contains "$OUT" "the dispatcher exited 7 on T003"
  run_loop 2 tick "$spec" --max-iterations 0
}

test_loop_dry_run_and_refusals_dispatch_nothing() {
  local spec; spec="$(loop_fixture)"
  run_loop 0 tick "$spec" --dry-run
  assert_contains "$OUT" "$(printf '1\tT001')"
  [[ ! -e "$SANDBOX/log" ]] || t_fail "--dry-run dispatched"
  fm_set "$spec/spec.md" repos "[api, web]"
  run_loop 5 tick "$spec"
  assert_contains "$OUT" "umbrella spec"
  [[ ! -e "$SANDBOX/log" ]] || t_fail "an umbrella spec dispatched"
}

t_run_all
