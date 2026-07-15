#!/usr/bin/env bash
# test-model-policy.sh — the codex reasoning-effort whitelist matches current
# Codex docs. Every edit targets a --file sandbox policy, so the machine's
# real models.yml is never read or written (and --file skips the re-stamp).

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
MP="$SCRIPTS/model-policy.sh"

# sandbox_policy — a minimal valid policy file in $SANDBOX. Echoes its path.
sandbox_policy() {
  local p="$SANDBOX/models.yml"
  cat > "$p" <<'EOF'
tiers:
  reasoning:
    codex_model: gpt-5.5
    codex_effort: xhigh
roles:
  opponent: reasoning
EOF
  echo "$p"
}

# AC-005: the documented codex efforts are accepted by set + check.
test_documented_codex_efforts_accepted() {
  local p e; p="$(sandbox_policy)"
  for e in none minimal ultra max xhigh; do
    run_rc 0 "$MP" --file "$p" set tier reasoning codex effort "$e"
    assert_contains "$OUT" "codex_effort = $e" "AC-005: '$e' accepted"
  done
  run_rc 0 "$MP" --file "$p" check
  assert_contains "$OUT" "model policy valid" "AC-005: check green on new values"
}

# AC-005: junk is still rejected, before anything is written.
test_junk_codex_effort_rejected() {
  local p; p="$(sandbox_policy)"
  run_rc 2 "$MP" --file "$p" set tier reasoning codex effort turbo
  assert_contains "$OUT" "invalid codex effort 'turbo'" "AC-005: junk refused"
  OUT="$(cat "$p")"
  assert_contains "$OUT" "codex_effort: xhigh" "AC-005: file untouched after refusal"
}

# AC-005: the claude whitelist is unchanged — 'ultra' stays codex-only.
test_claude_effort_whitelist_unchanged() {
  local p; p="$(sandbox_policy)"
  run_rc 2 "$MP" --file "$p" set tier reasoning claude effort ultra
  assert_contains "$OUT" "invalid claude effort 'ultra'" "AC-005: claude set unchanged"
}

# codex_sandbox / codex_approval: the documented Codex values are accepted,
# junk and non-codex CLIs are refused before anything is written, and check
# validates the stored keys.
test_codex_sandbox_and_approval_policy_fields() {
  local p; p="$(sandbox_policy)"
  run_rc 0 "$MP" --file "$p" set tier reasoning codex sandbox workspace-write
  assert_contains "$OUT" "codex_sandbox = workspace-write" "sandbox accepted"
  run_rc 0 "$MP" --file "$p" set tier reasoning codex approval never
  assert_contains "$OUT" "codex_approval = never" "approval accepted"
  run_rc 0 "$MP" --file "$p" check
  assert_contains "$OUT" "model policy valid" "check green with sandbox/approval set"
  run_rc 0 "$MP" --file "$p" tier reasoning codex sandbox
  assert_eq "workspace-write" "$OUT" "tier query reads sandbox back"
  run_rc 2 "$MP" --file "$p" set tier reasoning codex sandbox everything
  assert_contains "$OUT" "invalid codex sandbox 'everything'" "junk sandbox refused"
  run_rc 2 "$MP" --file "$p" set tier reasoning claude sandbox read-only
  assert_contains "$OUT" "codex-only" "sandbox refused for non-codex CLI"
  OUT="$(cat "$p")"
  assert_contains "$OUT" "codex_sandbox: workspace-write" "file keeps the valid value"
  assert_not_contains "$OUT" "everything" "refused value never lands in the file"
}

t_run_all
