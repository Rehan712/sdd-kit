# Evidence log

Captured acceptance runs, appended by `spec-run.sh`. One block per run.

## T001 — 2026-07-14T11:39:29

- **Command:** `shellcheck -S warning -x scripts/build-adapters.sh`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/001-codex-subagent-gates-and-hard-task-escalation
- **Exit:** 0
- **Captured:** 2026-07-14T11:39:29 · sha256:e3b0c44298fc (over full output)

```text
```

## T002 — 2026-07-14T11:41:29

- **Command:** `shellcheck -S warning -x scripts/build-adapters.sh`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/001-codex-subagent-gates-and-hard-task-escalation
- **Exit:** 0
- **Captured:** 2026-07-14T11:41:29 · sha256:e3b0c44298fc (over full output)

```text
```

## T003 — 2026-07-14T11:42:41

- **Command:** `sh -c t=$(mktemp); cp models.example.yml "$t"; scripts/model-policy.sh --file "$t" set tier reasoning codex effort ultra`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/001-codex-subagent-gates-and-hard-task-escalation
- **Exit:** 0
- **Captured:** 2026-07-14T11:42:41 · sha256:d6c07b398b1b (over full output)

```text
  ✓ tier 'reasoning': codex_effort = ultra
  · stamped copies not refreshed — run scripts/apply-models.sh + build-adapters.sh when ready
```

## T004 — 2026-07-14T11:46:40

- **Command:** `bash tests/run.sh build-adapters`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/001-codex-subagent-gates-and-hard-task-escalation
- **Exit:** 0
- **Captured:** 2026-07-14T11:46:40 · sha256:7dddfca1df43 (over full output)

```text
== test-build-adapters.sh
  ok   test_codex_adapters_delegate_copilot_adapters_persona_pass
  ok   test_degrades_without_policy_or_codex_home
  ok   test_prune_respects_kit_marker_and_role_unmapping
  ok   test_subagent_tomls_carry_identity_policy_and_persona
  -- 4/4 passed
```
