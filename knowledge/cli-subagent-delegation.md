# CLI subagent delegation — what each CLI actually does

Empirical, headless probes on installed binaries; transcripts in
`sdd-kit-public/001`'s `notes/`. Update this file when a CLI version changes
the picture — every claim below is version-stamped. (learned: sdd-kit-public/001)

## Codex CLI (codex-cli 0.144.1, `multi_agent` stable+on) — 2026-07-14

**Finding: works** — with one docs delta.

- Custom agents = one TOML per agent in `~/.codex/agents/` (personal) or
  `<repo>/.codex/agents/` (project). Both scopes spawn headlessly via
  `codex exec` when the prompt (or skill text) says to delegate by NAME:
  `collab: Wait` → child rollout → result relayed to the parent.
- `developer_instructions` load: a spawned kit opponent self-described as an
  independent adversarial reviewer with a default-negative verdict.
- **Docs delta:** per-agent `model` is documented but NOT honored on 0.144.1 —
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
  hand off headlessly: a plain `copilot -p "Hand this task off to the
  <name> custom agent: …"` spawned the agent —
  `● Sdd-proto-hard(gpt-5.6-terra) …` — and reported its reply verbatim.
- **Per-agent `model:` frontmatter IS honored** (the transcript names the
  model), with a loud fallback warning when the id is invalid:
  `Warning: Custom agent "…" specifies model "…" which is not available;
  using "claude-sonnet-4.6" instead`.
- Personal-scope handoffs run as background agents (`Agent started in
  background with agent_id: …`) and the parent waits and reports.

## What this means for the kit

- Codex: gates + escalation run as true subagents (shipped by
  `sdd-kit-public/001` — `build-adapters.sh` generates the TOMLs).
- Copilot: delegation is proven end-to-end, so the persona-pass preamble is a
  choice, not a necessity — wiring the gates/escalation through
  `~/.copilot/agents/` handoffs is a ready follow-up spec. Until it ships,
  Copilot adapters keep the persona-pass with this file as the pointer.
