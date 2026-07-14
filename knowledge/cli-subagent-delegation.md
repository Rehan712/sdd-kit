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

## Copilot CLI (1.0.70) — 2026-07-14

**Finding: works** — including the model pin.

- Custom agents = `.github/agents/*.agent.md` (project) or
  `~/.copilot/agents/` (personal; where the SDD kit installs). Both scopes
  hand off headlessly. The captured probe (spec-run block `T010o1` in
  `sdd-kit-public/001`'s `notes/evidence.md`, sha256:3f5e4d23af7d) — agent
  profile pinned `model: gpt-5.6-terra`, prompt asked the plain session to
  hand off:

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

- **Per-agent `model:` frontmatter IS honored** (the transcript names the
  model in the spawn line), with a loud fallback warning when the id is
  invalid: `Warning: Custom agent "…" specifies model "…" which is not
  available; using "claude-sonnet-4.6" instead`.
- Handoffs run as background agents and the parent waits and reports.

## What this means for the kit

- Codex: gates + escalation run as true subagents (shipped by
  `sdd-kit-public/001` — `build-adapters.sh` generates the TOMLs).
- Copilot: delegation is proven end-to-end, so the persona-pass preamble is a
  choice, not a necessity — wiring the gates/escalation through
  `~/.copilot/agents/` handoffs is a ready follow-up spec. Until it ships,
  Copilot adapters keep the persona-pass with this file as the pointer.
