# CLI subagent delegation — what each CLI actually does

Empirical, headless probes on installed binaries; transcripts in
`sdd-kit-public/001`'s `notes/`. Update this file when a CLI version changes
the picture — every claim below is version-stamped. (learned: sdd-kit-public/001)

## Codex CLI (codex-cli 0.144.4, `multi_agent` stable+on) — 2026-07-14

**Finding: works** — with one docs delta. (The binary auto-updated mid-session:
early uncaptured probes may have run 0.144.1; the captured probe's banner says
v0.144.4, and conclusions were identical throughout.)

- Custom agents = one TOML per agent in `~/.codex/agents/` (personal) or
  `<repo>/.codex/agents/` (project). Both scopes spawn headlessly via
  `codex exec` when the prompt (or skill text) says to delegate by NAME:
  `collab: Wait` → child rollout → result relayed to the parent.
- `developer_instructions` load: a spawned kit opponent self-described as an
  independent adversarial reviewer with a default-negative verdict.
- **Docs delta:** per-agent `model` is documented but NOT honored on 0.144.4 —
  every child ran the session default (`gpt-5.6-terra`), never the pinned
  `gpt-5.6-sol`. Keep emitting the keys (harmless, future-binding), promise
  only fresh context + instructions; the model lever stays
  `codex --profile sdd-<tier>`.
- Enumeration ("which agents do you have?") is not a capability — replies
  "None"/"root" even with agents installed. Always delegate by name.

### Addendum: spawn mechanics + subagent permissions (codex-cli 0.144.4) — 2026-07-15

Probes: scratch-repo `codex exec` spawns with a marker agent
(`nickname_candidates` as the plaintext loaded-or-not observable), child
rollout `turn_context` inspected for effective `sandbox_policy` /
`approval_policy`.

- **`agent_type` selects the agent — `task_name` is only a label.** The
  `spawn_agent` schema is `message`, `task_name`, `agent_type`, `model`,
  `reasoning_effort`, `service_tier`, `fork_turns`, `fork_context`. A spawn
  with `task_name="sdd-opponent"` but no `agent_type` runs a GENERIC child
  that never loads the persona (captured: generic nickname, instructions
  ignored). The generated preambles now say `agent_type` explicitly.
- **Per-agent TOML permission keys are documented-shaped but NOT honored,
  like `model`:** an agent TOML carrying `sandbox_mode = "workspace-write"` +
  `approval_policy = "never"` parsed cleanly, loaded (nickname bound), and
  the child still ran the parent session's `read-only` / `on-request`.
- **Spawn-time permission args don't exist:** passing `approval_policy` to
  `spawn_agent` is a hard error — `unknown field 'approval_policy'`.
- **What DOES work: subagents inherit the parent session's configured
  policy.** A session launched `codex --profile permprobe` whose profile file
  set `approval_policy = "never"` + `sandbox_mode = "workspace-write"` spawned
  children running exactly that policy (child `turn_context` captured). The
  kit therefore emits `codex_sandbox` / `codex_approval` from models.yml into
  the `sdd-<tier>.config.toml` profiles — launching `codex --profile
  sdd-<tier>` is the one lever that stops per-command approval prompts in
  kit subagents. The TUI's in-session permission toggle does NOT propagate
  to subagents; only session-start config does.

## Copilot CLI (1.0.70) — 2026-07-14

**Finding: works** — including the model pin.

- Custom agents = `.github/agents/*.agent.md` (project) or
  `~/.copilot/agents/` (personal; where the SDD kit installs). Both scopes
  hand off headlessly. Abridged transcript of the captured probe (full
  capture: spec-run block `T010o1` in `sdd-kit-public/001`'s
  `notes/evidence.md`, sha256:3f5e4d23af7d) — agent profile pinned
  `model: gpt-5.6-terra`, prompt asked the plain session to hand off:

  ```text
  $ copilot -p "Hand this task off to the sdd-proto-hard custom agent:
    'confirm readiness'. Report exactly what it returned." --allow-all --no-color

  ● Sdd-proto-hard(gpt-5.6-terra) confirm readiness
    └ Agent started in background with agent_id: confirm-readiness.

  <system_notification>Background agent confirm-readiness completed</system_notification>

  ● Read (Sdd-proto-hard agent — confirm readiness)
    └ Completed

  The sdd-proto-hard agent returned:
  **`ESCALATED-BY-PROTO`**
  ```

- **Per-agent `model:` frontmatter IS honored — discriminating capture.**
  One session (spec-run block `T010o4`, sha256:ed3cb1d6e84c) handed off to
  three agents at once: pins `claude-sonnet-5`, `gpt-5.6-terra`, and an
  invalid id produced spawn lines `Sdd-proto-a(claude-sonnet-5)`,
  `Sdd-proto-b(gpt-5.6-terra)`, `Sdd-proto-x(claude-sonnet-4.6)` — two
  distinct valid pins yielded two distinct child models in the same session
  (no single session default can explain that), and the invalid pin fell
  back to `claude-sonnet-4.6`, visible in its spawn line. (An uncaptured
  first probe also printed a textual warning on the invalid-id fallback;
  treat the wording as anecdote, the fallback itself is captured.)
- Handoffs run as background agents — spawned in parallel when asked — and
  the parent waits and reports each reply.

## What this means for the kit

- Codex: gates + escalation run as true subagents (shipped by
  `sdd-kit-public/001` — `build-adapters.sh` generates the TOMLs).
- Copilot: delegation is proven end-to-end, so the persona-pass preamble is a
  choice, not a necessity — wiring the gates/escalation through
  `~/.copilot/agents/` handoffs is a ready follow-up spec. Until it ships,
  Copilot adapters keep the persona-pass with this file as the pointer.
