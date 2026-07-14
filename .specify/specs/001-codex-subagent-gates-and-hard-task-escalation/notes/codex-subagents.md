# Empirical: kit subagent TOMLs on installed Codex (T006 / AC-007)

**Date:** 2026-07-14 · **codex-cli 0.144.1** · `multi_agent` feature: stable,
enabled (`codex features list`). Method: TOMLs generated hermetically by this
branch's `build-adapters.sh` (policy: `codex_model: gpt-5.6-sol`,
`codex_effort: xhigh` on all three roles), staged in a scratch git repo;
headless `codex exec --sandbox read-only` probes; session rollouts inspected
under `~/.codex/sessions/2026/07/14/`.

## What was proven

1. **TOMLs parse.** No config errors or warnings across five runs.
2. **Spawn-by-name works headlessly — from BOTH scopes.** Personal
   (`~/.codex/agents/`) and project (`<repo>/.codex/agents/`):

   > user: Spawn the sdd-implement-hard agent and have it reply with exactly
   > the word READY, then report what it said.
   > codex: I'll delegate that exact readiness check now.
   > collab: Wait
   > codex: The agent said: READY

   Parent+child rollout pairs confirm real spawns (not role-play) in every
   spawn probe, including the ticking evidence run (`sdd-opponent` → READY,
   captured in `notes/evidence.md`).
3. **`developer_instructions` load.** The spawned `sdd-opponent`, asked to
   self-describe: *"I act as an independent adversarial reviewer, and my
   default verdict is 'not approved' until the proposal is evidenced,
   coherent, and safe."* — the persona's adversarial role and default-negative
   verdict, in the subagent's own words.

## What the docs promised but 0.144.1 does NOT deliver

4. **Per-agent `model` pinning is not honored.** Policy pinned
   `gpt-5.6-sol`; every child rollout ran `gpt-5.6-terra` (the session
   default). Checked via `"model":"…"` in the child session jsonl.
   (`model_reasoning_effort` unverifiable from outside; assume likewise.)
   The kit keeps emitting both keys — they are documented, harmless when
   ignored, and will bind when Codex honors them — but no kit doc may claim
   per-task model escalation on Codex today. What `sdd-implement-hard` buys
   on 0.144.1: fresh context + the escalation instructions, at the session's
   model. Running the session under `codex --profile sdd-reasoning` remains
   the model lever.
5. **Agent enumeration is not a capability.** "Which custom agents are
   available?" → "None" / "root" regardless of scope. Delegate by NAME —
   which is exactly what the generated preamble instructs.

## Consequences applied

- `CODEX_PREAMBLE` and the doc tasks (T008/T009) phrase escalation as fresh
  context + instructions, with model pinning "where the installed Codex
  honors per-agent model fields" — never as a present-tense model guarantee.
- `~/.codex/agents/` on this machine restored to its pre-probe state (absent);
  production TOMLs arrive via `setup.sh` after merge.
