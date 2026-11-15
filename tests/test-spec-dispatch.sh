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

t_run_all
