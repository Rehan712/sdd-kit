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

# AC-008: no on_limit block is inert; a present block gets deterministic
# per-key defaults without silently enabling a policy when it is absent.
test_AC_008_usage_limit_policy_absent_and_present_defaults() {
  local p; p="$(sandbox_policy)"
  run_rc 0 "$MP" --file "$p" limit present
  assert_eq "false" "$OUT" "AC-008: absent block is reported separately"
  run_rc 1 "$MP" --file "$p" limit short

  run_rc 0 "$MP" --file "$p" set on_limit short park
  run_rc 0 "$MP" --file "$p" limit present
  assert_eq "true" "$OUT" "AC-008: set creates the opt-in block"
  run_rc 0 "$MP" --file "$p" limit short
  assert_eq "park" "$OUT" "AC-008: configured short action is returned"
  run_rc 0 "$MP" --file "$p" limit long
  assert_eq "delegate" "$OUT" "AC-008: present block defaults long action"
  run_rc 0 "$MP" --file "$p" limit fallback
  assert_eq "" "$OUT" "AC-008: present block defaults to no fallbacks"
  run_rc 0 "$MP" --file "$p" limit backoff_minutes
  assert_eq "60" "$OUT" "AC-008: present block defaults backoff"
}

# AC-008: set/unset writes canonical inline fallback order, normalizes a
# numeric backoff only after checking its digit shape, and restores defaults.
test_AC_008_usage_limit_policy_set_unset_round_trip() {
  local p policy; p="$(sandbox_policy)"
  run_rc 0 "$MP" --file "$p" set on_limit short delegate
  run_rc 0 "$MP" --file "$p" set on_limit long fail
  run_rc 0 "$MP" --file "$p" set on_limit fallback copilot,claude
  run_rc 0 "$MP" --file "$p" set on_limit backoff_minutes 0060
  run_rc 0 "$MP" --file "$p" limit fallback
  assert_eq "copilot,claude" "$OUT" "AC-008: ordered fallback getter"
  run_rc 0 "$MP" --file "$p" limit backoff_minutes
  assert_eq "60" "$OUT" "AC-008: getter normalizes leading zeroes"
  policy="$(cat "$p")"
  assert_contains "$policy" "fallback: [copilot, claude]" "AC-008: fallback emitted canonically"
  assert_contains "$policy" "backoff_minutes: 60" "AC-008: canonical backoff emitted"

  run_rc 0 "$MP" --file "$p" unset on_limit short
  run_rc 0 "$MP" --file "$p" limit short
  assert_eq "park" "$OUT" "AC-008: unset key returns present-block default"
  run_rc 0 "$MP" --file "$p" unset on_limit
  run_rc 0 "$MP" --file "$p" limit present
  assert_eq "false" "$OUT" "AC-008: whole-block unset restores inert state"
  run_rc 0 "$MP" --file "$p" check
  assert_contains "$OUT" "model policy valid" "AC-008: canonical round-trip validates"
}

# AC-008: setters reject invalid actions and fallback shapes before the source
# file is replaced, and check catches the same invalid hand-authored policy.
test_AC_008_usage_limit_policy_rejects_invalid_values() {
  local p before; p="$(sandbox_policy)"; before="$(cat "$p")"
  run_rc 2 "$MP" --file "$p" set on_limit short wait
  assert_contains "$OUT" "invalid on_limit short action 'wait'" "AC-008: invalid action named"
  run_rc 2 "$MP" --file "$p" set on_limit fallback claude,other
  assert_contains "$OUT" "unknown CLI 'other'" "AC-008: invalid fallback CLI named"
  run_rc 2 "$MP" --file "$p" set on_limit fallback claude,claude
  assert_contains "$OUT" "duplicate on_limit fallback CLI 'claude'" "AC-008: duplicate fallback refused"
  run_rc 2 "$MP" --file "$p" set on_limit backoff_minutes 0
  assert_contains "$OUT" "invalid on_limit backoff_minutes '0'" "AC-008: zero backoff refused"
  run_rc 2 "$MP" --file "$p" set on_limit backoff_minutes 12x
  assert_contains "$OUT" "invalid on_limit backoff_minutes '12x'" "AC-008: nonnumeric backoff refused"
  assert_eq "$before" "$(cat "$p")" "AC-008: invalid setter leaves policy untouched"

  cat >> "$p" <<'EOF'
on_limit:
  short: wait
  fallback: [claude, claude]
  backoff_minutes: 10081
EOF
  run_rc 1 "$MP" --file "$p" check
  assert_contains "$OUT" "short action 'wait'" "AC-008: check rejects hand-authored action"
  assert_contains "$OUT" "duplicate fallback CLI 'claude'" "AC-008: check rejects duplicate"
  assert_contains "$OUT" "invalid backoff_minutes '10081'" "AC-008: check rejects range"
}

# AC-008: re-running the interactive wizard retains the opt-in block and its
# ordered fallback list while it rewrites the rest of models.yml.
test_AC_008_usage_limit_policy_wizard_preserves_ordered_fallback() {
  local kit p home transcript policy
  kit="$SANDBOX/kit"; home="$SANDBOX/home"; transcript="$SANDBOX/wizard.typescript"
  cp -R "$KIT_DIR" "$kit"
  p="$kit/models.yml"
  mkdir -p "$home"
  cat > "$p" <<'EOF'
tiers:
  reasoning:
    claude_model: opus
    claude_effort: high
roles:
  opponent: reasoning
on_limit:
  short: fail
  long: delegate
  fallback: [copilot, claude]
  backoff_minutes: 90
EOF
  run_rc 0 bash -c "printf '\\n\\n\\n' | env HOME='$home' script -q '$transcript' '$kit/scripts/configure-models.sh' --no-sync"
  policy="$(cat "$p")"
  assert_contains "$policy" "short: fail" "AC-008: wizard preserves short action"
  assert_contains "$policy" "fallback: [copilot, claude]" "AC-008: wizard preserves fallback order"
  assert_contains "$policy" "backoff_minutes: 90" "AC-008: wizard preserves backoff"
  run_rc 0 "$kit/scripts/model-policy.sh" --file "$p" check
  assert_contains "$OUT" "model policy valid" "AC-008: wizard output remains valid"
}

t_run_all
