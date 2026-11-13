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

# run_wizard <kit> <home> — the wizard on a pty, accepting every default.
# `script` grants the pty, but BSD (macOS) and util-linux (Linux) disagree on
# its CLI: BSD takes the command positionally, util-linux needs -c and only
# returns the child's exit code with -e. A pty never reaches end of input, so a
# prompt that re-asks would wait forever: the watchdog turns that into a failure.
run_wizard() {
  local kit="$1" home="$2" transcript="$SANDBOX/wizard.typescript" enters='\n\n\n\n\n\n\n\n\n\n\n\n' rc
  ( sleep 120; pkill -f "$kit/scripts/configure-models.sh" ) > /dev/null 2>&1 &
  if script --version 2>/dev/null | grep -q util-linux; then
    bash -c "printf '$enters' | env HOME='$home' script -q -e -c '$kit/scripts/configure-models.sh --no-sync' '$transcript'"
  else
    bash -c "printf '$enters' | env HOME='$home' script -q '$transcript' '$kit/scripts/configure-models.sh' --no-sync"
  fi
  rc=$?
  kill "$!" 2> /dev/null
  return "$rc"
}

# AC-008: re-running the interactive wizard retains the opt-in block and its
# ordered fallback list while it rewrites the rest of models.yml.
test_AC_008_usage_limit_policy_wizard_preserves_ordered_fallback() {
  local kit p home policy
  kit="$SANDBOX/kit"; home="$SANDBOX/home"
  # The kit as the input identity sees it, never the host's machine-local files (O-015).
  copy_kit "$KIT_DIR" "$kit" || t_fail 'AC-008: cannot copy the kit for the wizard fixture'
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
  run_rc 0 run_wizard "$kit" "$home"
  policy="$(cat "$p")"
  assert_contains "$policy" "short: fail" "AC-008: wizard preserves short action"
  assert_contains "$policy" "fallback: [copilot, claude]" "AC-008: wizard preserves fallback order"
  assert_contains "$policy" "backoff_minutes: 90" "AC-008: wizard preserves backoff"
  run_rc 0 "$kit/scripts/model-policy.sh" --file "$p" check
  assert_contains "$OUT" "model policy valid" "AC-008: wizard output remains valid"
}

# Reconfiguring must not drop the tier profile's permission policy, and Enter
# must accept a stored codex effort the policy itself allows (a narrower
# wizard whitelist re-asked for `ultra` until stdin ran out).
test_wizard_keeps_codex_permission_keys_and_accepts_stored_efforts() {
  local kit="$SANDBOX/kit" home="$SANDBOX/home" policy
  copy_kit "$KIT_DIR" "$kit" || t_fail 'cannot copy the kit for the wizard fixture'
  mkdir -p "$home/.codex"
  printf '%s\n' 'tiers:' '  reasoning:' '    claude_model: opus' '    claude_effort: high' \
    '    codex_model: gpt-6.1-sol' '    codex_effort: ultra' \
    '    codex_sandbox: workspace-write' '    codex_approval: never' \
    'roles:' '  opponent: reasoning' > "$kit/models.yml"
  run_rc 0 run_wizard "$kit" "$home"
  policy="$(cat "$kit/models.yml")"
  assert_contains "$policy" 'codex_effort: ultra' 'the wizard lost a stored codex effort'
  assert_contains "$policy" 'codex_sandbox: workspace-write' 'the wizard dropped codex_sandbox'
  assert_contains "$policy" 'codex_approval: never' 'the wizard dropped codex_approval'
}

# [hard] escalation on Claude passes the model's alias family to the Agent
# tool: a pinned full id must escalate as its family, not silently not at all.
test_claude_alias_maps_a_full_id_to_its_family() {
  local p; p="$(sandbox_policy)"
  run_rc 0 "$MP" --file "$p" set role implement-hard reasoning
  run_rc 1 "$MP" --file "$p" get implement-hard claude alias
  run_rc 0 "$MP" --file "$p" set tier reasoning claude model opus
  run_rc 0 "$MP" --file "$p" get implement-hard claude alias
  assert_eq opus "$OUT"
  run_rc 0 "$MP" --file "$p" set tier reasoning claude model claude-sonnet-5-5
  run_rc 0 "$MP" --file "$p" get implement-hard claude alias
  assert_eq sonnet "$OUT" 'a full model id does not map to its alias family'
  run_rc 2 "$MP" --file "$p" get implement-hard codex alias
  # No family to pass: escalation cannot work, and check says so.
  run_rc 0 "$MP" --file "$p" set tier reasoning claude model inherit
  run_rc 1 "$MP" --file "$p" get implement-hard claude alias
  run_rc 0 "$MP" --file "$p" check
  assert_contains "$OUT" "role 'implement-hard': claude_model 'inherit' has no alias family"
}

# O-015 second review: the wizard fixture copies the kit as the input identity
# enumerates it, so a developer's ignored models.yml -- here a link to a policy
# outside the kit -- neither reaches the fixture nor is written through by it.
test_AC_008_wizard_fixture_never_writes_through_a_host_models_yml() {
  local host="$SANDBOX/host-kit" target="$SANDBOX/dotfiles/models.yml" before
  make_host_kit "$host" || t_fail 'AC-008: cannot build the host kit'
  mkdir -p "$SANDBOX/dotfiles"
  cp "$KIT_DIR/models.example.yml" "$target"
  before="$(cksum < "$target")"
  ln -s "$target" "$host/models.yml"
  on_host_kit "$host" test_AC_008_usage_limit_policy_wizard_preserves_ordered_fallback
  assert_eq "$before" "$(cksum < "$target")" "AC-008: the wizard fixture wrote through the host kit's models.yml link"
}

# --- project overlay: <project>/.specify/models.yml --------------------------------

# overlay_fixture — a machine policy with three tiers and a project that
# remaps two roles and one dispatch. Sets P (policy) and PROJ (project root).
overlay_fixture() {
  P="$SANDBOX/models.yml"; PROJ="$SANDBOX/proj"
  mkdir -p "$PROJ/.specify" "$PROJ/apps/android"
  cat > "$P" <<'EOF'
tiers:
  reasoning:
    claude_model: claude-opus-5-5
    claude_effort: high
    codex_model: gpt-big
  implementation:
    claude_model: sonnet
    claude_effort: medium
    codex_model: gpt-mid
  recon:
    claude_model: haiku
roles:
  plan: reasoning
  implement: implementation
  stack-expert: implementation
  explore: recon
dispatch:
  plan: claude
EOF
  cat > "$PROJ/.specify/models.yml" <<'EOF'
# This repo's code is hard: write it on the strong tier.
roles:
  stack-expert: reasoning
  test-engineer: reasoning
dispatch:
  implement: codex
EOF
}

mp() { "$MP" --file "$P" "$@"; }

test_project_overlay_remaps_roles_and_dispatch_for_that_project_only() {
  overlay_fixture
  run_rc 0 mp get stack-expert claude alias
  assert_eq sonnet "$OUT" 'the machine policy changed'
  run_rc 0 mp --project "$PROJ" get stack-expert claude alias
  assert_eq opus "$OUT" 'the project role override was not applied'
  run_rc 0 mp --project "$PROJ" get stack-expert codex model
  assert_eq gpt-big "$OUT" 'the override must follow the tier on every CLI'
  run_rc 0 mp --project "$PROJ" get test-engineer claude effort
  assert_eq high "$OUT" 'a role only the project maps'
  run_rc 0 mp --project "$PROJ" get plan claude alias
  assert_eq opus "$OUT" 'a role the project does not mention'
  run_rc 0 mp --project "$PROJ" dispatch implement
  assert_eq codex "$OUT"
  run_rc 0 mp --project "$PROJ" dispatch
  assert_eq "plan	claude
implement	codex" "$OUT" 'the merged dispatch map'
  run_rc 1 mp dispatch implement
  # Each role once, the machine's order kept, the project's additions last.
  run_rc 0 mp --project "$PROJ" roles
  assert_eq "plan	reasoning
implement	implementation
stack-expert	reasoning
explore	recon
test-engineer	reasoning" "$OUT"
  run_rc 0 mp --project "$PROJ" show
  assert_contains "$OUT" "Project overlay: $PROJ/.specify/models.yml"
}

# The directory may be the root, a spec worktree, or anything inside the
# project; and a plain query never reads the overlay — the stamped copies and
# adapters are built from plain queries and must stay machine-wide.
test_project_overlay_is_found_from_inside_and_never_without_the_flag() {
  overlay_fixture
  printf 'stacks: []\n' > "$PROJ/.specify/stack.yml"
  run_rc 0 mp --project "$PROJ/apps/android" get stack-expert claude alias
  assert_eq opus "$OUT" 'a directory inside the project did not find its overlay'
  OUT="$(cd "$PROJ" && "$MP" --file "$P" get stack-expert claude alias 2>&1)"
  assert_eq sonnet "$OUT" 'a query without --project read the overlay of the cwd'
  mkdir -p "$SANDBOX/elsewhere"
  run_rc 0 mp --project "$SANDBOX/elsewhere" get stack-expert claude alias
  assert_eq sonnet "$OUT" 'a directory with no project changed the answer'
  run_rc 2 mp --project "$SANDBOX/missing" roles
  assert_contains "$OUT" 'not a directory'
}

# A committed overlay must not break a teammate whose machine lacks the tier:
# their own mapping stands, and check says so.
test_project_overlay_role_on_an_undefined_tier_falls_back_to_the_machine() {
  overlay_fixture
  printf 'roles:\n  stack-expert: frontier\n  explore: reasoning\n  typo-role: reasoning\n' > "$PROJ/.specify/models.yml"
  run_rc 0 mp --project "$PROJ" get stack-expert claude alias
  assert_eq sonnet "$OUT" 'a role on an undefined tier lost its machine mapping'
  run_rc 0 mp --project "$PROJ" get explore claude alias
  assert_eq opus "$OUT"
  run_rc 0 mp --project "$PROJ" check
  assert_contains "$OUT" "role 'stack-expert' names tier 'frontier', which this machine does not define"
  assert_contains "$OUT" "unknown role 'typo-role'"
  assert_contains "$OUT" 'model policy valid with project overlay'
  # show does not claim a skipped row was applied.
  run_rc 0 mp --project "$PROJ" show
  assert_contains "$OUT" 'role stack-expert -> frontier (skipped: no such tier here); role explore -> reasoning;'
  run_rc 0 mp --project "$PROJ" overrides
  assert_eq "explore	reasoning	opus	high
typo-role	reasoning	opus	high" "$OUT" 'overrides listed a role whose tier this machine lacks'
}

# overrides is what a dispatcher passes as the Agent tool's model + effort.
test_overrides_lists_what_the_project_remaps() {
  overlay_fixture
  run_rc 0 mp --project "$PROJ" overrides
  assert_eq "stack-expert	reasoning	opus	high
test-engineer	reasoning	opus	high" "$OUT"
  run_rc 0 mp overrides
  assert_eq '' "$OUT" 'overrides without a project'
  printf 'roles:\n  explore: recon\n' > "$PROJ/.specify/models.yml"
  run_rc 0 mp --project "$PROJ" overrides
  assert_eq "explore	recon	haiku	-" "$OUT" 'an unset effort prints -'
}

# Tiers and on_limit are machine-local; edits never go through an overlay.
test_project_overlay_may_only_remap_roles_and_dispatch() {
  overlay_fixture
  cat > "$PROJ/.specify/models.yml" <<'EOF'
tiers:
  reasoning:
    claude_model: haiku
roles:
  plan: reasoning
dispatch:
  review: claude
on_limit:
  short: park
EOF
  run_rc 0 mp --project "$PROJ" get plan claude alias
  assert_eq opus "$OUT" 'a project tiers: block redefined a machine tier'
  run_rc 1 mp --project "$PROJ" limit short
  run_rc 1 mp --project "$PROJ" check
  assert_contains "$OUT" 'project overlay defines tiers:'
  assert_contains "$OUT" 'project overlay sets on_limit:'
  assert_contains "$OUT" "dispatch: 'review' needs interactive judgment"

  overlay_fixture
  local before; before="$(cat "$P" "$PROJ/.specify/models.yml")"
  run_rc 2 mp --project "$PROJ" set role plan implementation
  assert_contains "$OUT" '--project is read-only'
  run_rc 2 mp --project "$PROJ" update plan sonnet
  run_rc 2 mp --project "$PROJ" unset role plan
  assert_eq "$before" "$(cat "$P" "$PROJ/.specify/models.yml")" 'a refused edit wrote a file'
  printf '# nothing yet\n' > "$PROJ/.specify/models.yml"
  run_rc 0 mp --project "$PROJ" check
  assert_contains "$OUT" 'project overlay overrides nothing'
}

t_run_all
