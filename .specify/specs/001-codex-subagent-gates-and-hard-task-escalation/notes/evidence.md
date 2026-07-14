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

## T005 — 2026-07-14T11:47:16

- **Command:** `bash tests/run.sh model-policy`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/001-codex-subagent-gates-and-hard-task-escalation
- **Exit:** 0
- **Captured:** 2026-07-14T11:47:16 · sha256:ae5cf0a11eed (over full output)

```text
== test-model-policy.sh
  ok   test_claude_effort_whitelist_unchanged
  ok   test_documented_codex_efforts_accepted
  ok   test_junk_codex_effort_rejected
  -- 3/3 passed
```

## T006 — 2026-07-14T11:52:53

- **Command:** `codex exec --sandbox read-only Spawn the sdd-opponent agent and have it reply with exactly the word READY, then report what it said.`
- **Cwd:** /private/tmp/claude-501/-Users-babar-projects-sdd-kit-public/9a8b00e2-e365-4923-8678-5b5adc87e90a/scratchpad/codex-probe/proj
- **Exit:** 0
- **Captured:** 2026-07-14T11:52:53 · sha256:287fa029fdc0 (over full output)

```text
Reading additional input from stdin...
OpenAI Codex v0.144.4
--------
workdir: /private/tmp/claude-501/-Users-babar-projects-sdd-kit-public/9a8b00e2-e365-4923-8678-5b5adc87e90a/scratchpad/codex-probe/proj
model: gpt-5.6-terra
provider: openai
approval: on-request
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 019f600b-2fa7-7ea0-9713-0a3ab0f20ce2
--------
user
Spawn the sdd-opponent agent and have it reply with exactly the word READY, then report what it said.
warning: Skill descriptions were shortened to fit the 2% skills context budget. Codex can still see every skill, but some descriptions are shorter. Disable unused skills or plugins to leave more room for the rest.
codex
I’ll delegate this exact handshake to an `sdd-opponent` agent.
collab: Wait
codex
The sdd-opponent agent said: READY
tokens used
23 724
The sdd-opponent agent said: READY
```

## T007 — 2026-07-14T11:57:53

- **Command:** `grep -icE finding: (works|does not|partial) knowledge/cli-subagent-delegation.md`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/001-codex-subagent-gates-and-hard-task-escalation
- **Exit:** 0
- **Captured:** 2026-07-14T11:57:53 · sha256:53c234e5e847 (over full output)

```text
2
```

## T008 — 2026-07-14T11:59:07

- **Command:** `sh -c grep -L "without subagents" agents/opponent.agent.md agents/reality-check.agent.md && grep -l "sdd-opponent" agents/opponent.agent.md`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/001-codex-subagent-gates-and-hard-task-escalation
- **Exit:** 1
- **Captured:** 2026-07-14T11:59:07 · sha256:b8eecd965cc3 (over full output)

```text
agents/opponent.agent.md
agents/reality-check.agent.md
```

## T008 — 2026-07-14T11:59:52

- **Command:** `sh -c ! grep -q "without subagents" agents/opponent.agent.md agents/reality-check.agent.md && grep -l "sdd-opponent" agents/opponent.agent.md && grep -l "sdd-reality-check" agents/reality-check.agent.md`
- **Cwd:** /Users/babar/projects/sdd-kit-public.worktrees/001-codex-subagent-gates-and-hard-task-escalation
- **Exit:** 0
- **Captured:** 2026-07-14T11:59:52 · sha256:b8eecd965cc3 (over full output)

```text
agents/opponent.agent.md
agents/reality-check.agent.md
```
