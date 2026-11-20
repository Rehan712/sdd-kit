#!/usr/bin/env bash
# test-spec-dispatch.sh — spec-dispatch.sh's umbrella --repo guard.
#
# Runs against a sandboxed copy of scripts/ (the dispatcher reads models.yml
# from the kit root it lives in — the developer's real policy must never
# leak into an expectation).

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

# stage_umbrella — scripts/ copy in $SANDBOX/kit + an umbrella spec declaring
# [alpha-api, beta] at the only location the dispatcher accepts. Echoes the
# spec dir.
stage_umbrella() {
  local kit="$SANDBOX/kit" dir="$SANDBOX/kit/specs/001-demo"
  mkdir -p "$kit" "$dir"
  # The kit's scripts as the input identity enumerates them (copy_kit's directory selector), so a
  # developer's ignored entry under scripts/ never arrives (O-015 second review).
  copy_kit "$KIT_DIR" "$kit" scripts || { fixture_build_failed 'stage_umbrella kit scripts'; echo "$dir"; return 1; }
  cat > "$dir/spec.md" <<'EOF'
---
spec: 001-demo
project: hub
repos: [alpha-api, beta]
---
# Spec: Demo

## Acceptance criteria

- AC-001 — the thing works across both repos
EOF
  echo "$dir"
}

test_repo_match_is_token_exact() {
  # 'alpha' must NOT match the declared 'alpha-api' — grep -w treats '-' as a
  # word boundary and let the prefix through, so the run died later at repo
  # resolution with a misleading exit 4 instead of a clean refusal.
  local dir; dir="$(stage_umbrella)"
  run_rc 2 bash "$SANDBOX/kit/scripts/spec-dispatch.sh" implement "$dir" --repo alpha
  assert_contains "$OUT" "not declared" "prefix of a declared repo is refused"
}

# The sibling readers of --repo refuse the same prefix, before any repo lookup.
test_repo_match_is_token_exact_for_worktree_and_pr() {
  local dir; dir="$(stage_umbrella)"
  run_rc 1 bash "$SANDBOX/kit/scripts/spec-worktree.sh" --repo alpha "$dir"
  assert_contains "$OUT" "not declared" "spec-worktree.sh accepts a prefix of a declared repo"
  run_rc 1 bash "$SANDBOX/kit/scripts/spec-pr.sh" --repo alpha "$dir"
  assert_contains "$OUT" "not declared" "spec-pr.sh accepts a prefix of a declared repo"
}

test_undeclared_repo_refused_and_declared_accepted_past_the_guard() {
  local dir; dir="$(stage_umbrella)"
  run_rc 2 bash "$SANDBOX/kit/scripts/spec-dispatch.sh" implement "$dir" --repo gamma
  assert_contains "$OUT" "not declared"
  # A genuinely declared repo passes the guard: with no dispatch mapping and
  # no --to, the next stop is exit 3 (no mapping) — never the exit-2 refusal.
  run_rc 3 bash "$SANDBOX/kit/scripts/spec-dispatch.sh" implement "$dir" --repo alpha-api
  assert_contains "$OUT" "no dispatch mapping"
}

# O-015 second review: stage_umbrella copies the kit's scripts as the input
# identity enumerates them, so an ignored script in a developer's kit never
# reaches the staged dispatcher's kit.
test_stage_umbrella_copies_only_enumerated_scripts() {
  local host="$SANDBOX/host-kit"
  make_host_kit "$host" || t_fail 'cannot build the host kit'
  printf 'scripts/zz-local.sh\n' >> "$host/.git/info/exclude"
  printf 'echo local\n' > "$host/scripts/zz-local.sh"
  on_host_kit "$host" stage_umbrella > /dev/null
  [[ -f "$SANDBOX/kit/scripts/spec-dispatch.sh" ]] || t_fail 'stage_umbrella did not stage the dispatcher'
  [[ ! -e "$SANDBOX/kit/scripts/zz-local.sh" ]] || t_fail "stage_umbrella staged the host kit's ignored script"
}

# O-015 review 6: stage_umbrella's output is a path its callers use, so a
# failed copy is recorded and the sandbox path is still printed.
test_stage_umbrella_failure_is_named_and_stays_in_the_sandbox() {
  local sub="$SANDBOX/failing-sandbox" nokit="$SANDBOX/not-a-kit" printed
  mkdir -p "$sub" "$nokit"
  if printed="$(SANDBOX="$sub" on_host_kit "$nokit" stage_umbrella 2>/dev/null)"; then
    t_fail 'stage_umbrella reported success for a copy that failed'
  fi
  [[ "$printed" == "$sub"/* && "$printed" != *$'\n'* ]] \
    || t_fail "stage_umbrella handed its caller a path outside the sandbox: '$printed'"
  assert_contains "$(cat "$sub/.fixture-build-failed" 2>/dev/null)" 'stage_umbrella kit scripts' \
    'stage_umbrella left no record of the failed copy'
}

# A project's .specify/models.yml decides the CLI and the model of a
# dispatched run for that project; the same kit dispatches another project on
# the machine policy.
test_dispatch_reads_the_project_model_overlay() {
  local kit="$SANDBOX/kit" proj other
  mkdir -p "$kit" "$SANDBOX/bin"
  copy_kit "$KIT_DIR" "$kit" scripts || { fixture_build_failed 'dispatch kit scripts'; return 1; }
  cat > "$kit/models.yml" <<'EOF'
tiers:
  reasoning:
    claude_model: opus
    claude_effort: high
  implementation:
    claude_model: sonnet
    claude_effort: medium
roles:
  plan: reasoning
EOF
  printf '#!/bin/sh\nexit 0\n' > "$SANDBOX/bin/claude"; chmod +x "$SANDBOX/bin/claude"
  for proj in "$SANDBOX/proj" "$SANDBOX/other"; do
    mkdir -p "$proj/.specify/specs/001-demo"
    printf -- '---\nspec: 001-demo\n---\n# Spec: Demo\n' > "$proj/.specify/specs/001-demo/spec.md"
  done
  proj="$SANDBOX/proj"; other="$SANDBOX/other"
  printf 'roles:\n  plan: implementation\ndispatch:\n  plan: claude\n' > "$proj/.specify/models.yml"

  run_rc 0 env PATH="$SANDBOX/bin:$PATH" bash "$kit/scripts/spec-dispatch.sh" plan "$proj/.specify/specs/001-demo" --dry-run
  assert_contains "$OUT" 'dispatch:  plan -> claude' 'the project dispatch mapping was not used'
  # --dry-run prints the argv two spaces apart.
  assert_contains "$OUT" '--model  sonnet' 'the project role override did not pick the model'
  assert_contains "$OUT" '--effort  medium'
  # No overlay in the other project, and no machine dispatch map: nothing to run.
  run_rc 3 env PATH="$SANDBOX/bin:$PATH" bash "$kit/scripts/spec-dispatch.sh" plan "$other/.specify/specs/001-demo" --dry-run
  run_rc 0 env PATH="$SANDBOX/bin:$PATH" bash "$kit/scripts/spec-dispatch.sh" plan "$other/.specify/specs/001-demo" --to claude --dry-run
  assert_contains "$OUT" '--model  opus' 'another project inherited the overlay'
}

# The run prints the home — the account — it lands in, and the plan verifier
# accepts a plan stamped on the day the run started: one that crossed midnight
# used to fail as "not written today".
test_dispatch_names_the_target_home_and_accepts_a_plan_from_the_start_day() {
  local kit="$SANDBOX/kit" proj="$SANDBOX/proj" spec real_date
  spec="$proj/.specify/specs/001-demo"
  mkdir -p "$kit" "$SANDBOX/bin" "$spec"
  copy_kit "$KIT_DIR" "$kit" scripts || { fixture_build_failed 'dispatch kit scripts'; return 1; }
  printf 'tiers:\n  reasoning:\n    claude_model: opus\nroles:\n  plan: reasoning\n' > "$kit/models.yml"
  printf -- '---\nspec: 001-demo\n---\n# Spec: Demo\n' > "$spec/spec.md"
  printf -- '---\nspec: 001-demo\nplan_review: SOUND\n---\n# Status\n' > "$spec/STATUS.md"

  printf '#!/bin/sh\nexit 0\n' > "$SANDBOX/bin/claude"; chmod +x "$SANDBOX/bin/claude"
  run_rc 0 env PATH="$SANDBOX/bin:$PATH" CLAUDE_CONFIG_DIR="$SANDBOX/claude_alt" \
    bash "$kit/scripts/spec-dispatch.sh" plan "$spec" --to claude --dry-run
  assert_contains "$OUT" "home:      $SANDBOX/claude_alt" 'the dry run hides which account it would use'
  run_rc 0 env -u CLAUDE_CONFIG_DIR PATH="$SANDBOX/bin:$PATH" HOME="$SANDBOX/home" \
    bash "$kit/scripts/spec-dispatch.sh" plan "$spec" --to claude --dry-run
  assert_contains "$OUT" "home:      $SANDBOX/home/.claude" 'the default home is not named'

  # Midnight passes during the run: the provider writes the plan on day one
  # and flips the clock; the verifier then runs on day two.
  real_date="$(command -v date)"
  printf '2026-03-01\n' > "$SANDBOX/day"
  printf '#!/bin/sh\ncase "$1" in +%%Y-%%m-%%d) cat "%s/day" ;; *) exec "%s" "$@" ;; esac\n' "$SANDBOX" "$real_date" \
    > "$SANDBOX/bin/date"
  printf '#!/bin/sh\nprintf -- "---\\nupdated: 2026-03-01\\n---\\n# Plan\\n" > "%s/plan.md"\nprintf "2026-03-02\\n" > "%s/day"\n' \
    "$spec" "$SANDBOX" > "$SANDBOX/bin/claude"
  chmod +x "$SANDBOX/bin/date" "$SANDBOX/bin/claude"
  run_rc 0 env PATH="$SANDBOX/bin:$PATH" HOME="$SANDBOX/home" bash "$kit/scripts/spec-dispatch.sh" plan "$spec" --to claude
  assert_contains "$OUT" 'plan.md updated: 2026-03-01' 'a plan written before midnight was refused'
  assert_eq '2026-03-02' "$(cat "$SANDBOX/day")" 'the fixture never crossed midnight'
  # A plan from neither day is still refused.
  printf '#!/bin/sh\nprintf -- "---\\nupdated: 2025-12-31\\n---\\n# Plan\\n" > "%s/plan.md"\n' "$spec" > "$SANDBOX/bin/claude"
  run_rc 1 env PATH="$SANDBOX/bin:$PATH" HOME="$SANDBOX/home" bash "$kit/scripts/spec-dispatch.sh" plan "$spec" --to claude
  assert_contains "$OUT" "expected the day of this run" 'a stale plan passed the verifier'
}

test_umbrella_worktree_reports_partial_failure() {
  local spec name
  spec="$(stage_umbrella)"
  for name in alpha-api beta; do
    fixture_git init -q "$SANDBOX/$name"
    fixture_git -C "$SANDBOX/$name" commit --allow-empty -qm fixture
  done
  fixture_git -C "$SANDBOX/beta" branch fixture-base
  cat > "$SANDBOX/kit/scripts/system-map.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s/%s\n' "$SANDBOX" "$2"
EOF
  run_rc 1 "$SANDBOX/kit/scripts/spec-worktree.sh" --base fixture-base --all-repos "$spec"
  assert_contains "$OUT" 'FAILED to cut worktree for alpha-api'
  [[ -d "$SANDBOX/beta.worktrees/001-demo" ]] || t_fail 'healthy sibling was skipped'
  [[ ! -d "$SANDBOX/alpha-api.worktrees/001-demo" ]] || t_fail 'failed sibling reported a worktree'
}

test_concurrent_spec_numbers_are_unique() {
  local n pid pids=() dirs
  mkdir "$SANDBOX/project"
  for n in 1 2 3 4 5 6 7 8; do
    "$SCRIPTS/new-spec.sh" --project "$SANDBOX/project" "Concurrent $n" > "$SANDBOX/log-$n" 2>&1 & pids+=("$!")
  done
  for pid in "${pids[@]}"; do wait "$pid" || t_fail 'concurrent creator failed'; done
  dirs="$SANDBOX/project/.specify/specs"
  assert_eq 8 "$(cd "$dirs" && printf '%s\n' ???-*/spec.md | cut -c1-3 | sort -u | wc -l | tr -d ' ')"
}

# Run records committed by one spec are listed in every later spec's input
# manifest, so a new spec keeps them out of git and keeps its reports in.
test_new_spec_keeps_run_records_out_of_git() {
  local notes path
  git_host "$SANDBOX/ignoring" || return 1
  run_rc 0 "$SCRIPTS/new-spec.sh" --project "$SANDBOX/ignoring" 'Ignore records'
  notes=.specify/specs/001-ignore-records/notes
  for path in captures/CAP-1-a/meta.nul verification/captures/CAP-1-a verification/floors/FLOOR-a/inputs.nul verification/checkpoints/CHECKPOINT-a/inputs.nul; do
    fixture_git -C "$SANDBOX/ignoring" check-ignore -q "$notes/$path" || t_fail "run record is not ignored: $path"
  done
  for path in evidence.md opponent.md verification/accepted/T001/ACC-a/meta.nul verification/reports/opponent-findings-1.md; do
    ! fixture_git -C "$SANDBOX/ignoring" check-ignore -q "$notes/$path" || t_fail "gate record is ignored: $path"
  done
}

test_ci_readiness_and_incomplete_umbrella() {
  local spec name expected response
  spec="$(stage_umbrella)"
  mkdir "$SANDBOX/bin"
  cat > "$SANDBOX/bin/gh" <<'EOF'
#!/bin/bash
[[ "$1 $2" == 'pr view' && "$4" == --json && "$5" == *mergeStateStatus* && "$6" == --jq ]] || exit 1
cat "$SANDBOX/${3##*/}.state"
EOF
  chmod +x "$SANDBOX/bin/gh"
  export PATH="$SANDBOX/bin:$PATH"
  printf '%s\n' --- 'pr_alpha-api: https://example.invalid/a' 'pr_beta: https://example.invalid/b' --- > "$spec/STATUS.md"
  echo 'OPEN|false|APPROVED|MERGEABLE|CLEAN|SUCCESS' > "$SANDBOX/a.state"
  while IFS=' ' read -r expected response; do
    printf '%s\n' "$response" > "$SANDBOX/b.state"
    run_rc "$expected" "$SCRIPTS/spec-ci.sh" check "$spec"
  done <<'EOF'
0 OPEN|false||MERGEABLE|CLEAN|
0 MERGED|false||UNKNOWN|UNKNOWN|
10 OPEN|false|REVIEW_REQUIRED|MERGEABLE|BLOCKED|SUCCESS
10 OPEN|false||UNKNOWN|UNKNOWN|SUCCESS
10 OPEN|true||MERGEABLE|DRAFT|SUCCESS
10 OPEN|false|APPROVED|MERGEABLE|CLEAN|SUCCESS,PENDING
20 CLOSED|false||MERGEABLE|CLEAN|SUCCESS
20 OPEN|false||MERGEABLE|CLEAN|SUCCESS,FAILURE
30 OPEN|false|CHANGES_REQUESTED|MERGEABLE|BLOCKED|SUCCESS
40 OPEN|false||CONFLICTING|DIRTY|SUCCESS
40 OPEN|false|APPROVED|MERGEABLE|BEHIND|SUCCESS
3 UNKNOWN|false||UNKNOWN|UNKNOWN|
EOF
  # A settled draft stops the watch instead of polling until the timeout.
  echo 'OPEN|true||MERGEABLE|DRAFT|SUCCESS' > "$SANDBOX/b.state"
  run_rc 10 "$SCRIPTS/spec-ci.sh" --timeout 0 watch "$spec"
  assert_contains "$OUT" 'draft PR'
  # A merged single-repo PR is done, not red.
  mkdir "$SANDBOX/single"
  printf '%s\n' --- 'spec: 002-single' --- > "$SANDBOX/single/spec.md"
  printf '%s\n' --- 'pr: https://example.invalid/b' 'ci: green (2026-01-01)' --- > "$SANDBOX/single/STATUS.md"
  echo 'MERGED|false||UNKNOWN|UNKNOWN|' > "$SANDBOX/b.state"
  run_rc 3 "$SCRIPTS/spec-ci.sh" check "$SANDBOX/single"
  assert_contains "$OUT" 'already merged'
  assert_contains "$(cat "$SANDBOX/single/STATUS.md")" 'ci: green'
  for name in a b; do
    echo 'OPEN|false|APPROVED|MERGEABLE|CLEAN|SUCCESS' > "$SANDBOX/$name.state"
  done
  run_rc 0 "$SCRIPTS/spec-ci.sh" check "$spec"
  sed '/^pr_beta:/d' "$spec/STATUS.md" > "$SANDBOX/status"
  cp "$SANDBOX/status" "$spec/STATUS.md"
  run_rc 3 "$SCRIPTS/spec-ci.sh" check "$spec"
  assert_contains "$OUT" 'missing PR for beta'
  assert_contains "$(cat "$spec/STATUS.md")" 'ci: pending'
}

t_run_all
