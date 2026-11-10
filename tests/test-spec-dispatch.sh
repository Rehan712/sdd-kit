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

t_run_all
