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
  cp -R "$KIT_DIR/scripts" "$kit/scripts"
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

t_run_all
