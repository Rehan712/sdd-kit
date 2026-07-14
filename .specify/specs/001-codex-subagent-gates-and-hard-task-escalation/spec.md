---
spec_id: 001-codex-subagent-gates-and-hard-task-escalation
title: Codex subagent gates and hard-task escalation
status: accepted
created: 2026-07-14
updated: 2026-07-14
owners: [Rehan712]
project: sdd-kit-public
---

# Codex subagent gates and hard-task escalation

> On Codex CLI the kit's two adversarial gates run as persona passes — the
> agent grading work it may have written — and `[hard]`-task escalation is
> inert. Codex has shipped real subagents (GA since v0.115.0; installed:
> 0.144.1) with per-agent `model` + `model_reasoning_effort`. This spec makes
> `build-adapters.sh` generate kit subagents from the model policy so gates get
> fresh-context review and `[hard]` tasks escalate on Codex, updates the
> now-stale "single-agent" documentation, and empirically prototypes the
> Copilot equivalent before promising it.

## 1. Problem

The kit's Codex adapters carry a preamble written when Codex was single-agent:
"You are running on a CLI without subagents… adopt the persona as a DISTINCT
review pass." That claim is stale (Codex docs: subagents as per-agent TOML
files under `~/.codex/agents/`, delegation triggerable from skill instructions),
and it costs real integrity: a self-grading gate is structurally weaker than a
fresh-context one, and a `[hard]` task on Codex silently runs at the
implementation tier.

**REQ-001:** On Codex, the opponent and reality-check gates must run as true
subagents with fresh context (never self-grading persona passes) whenever the
kit-generated subagents are installed, with an explicit documented fallback to
persona-pass when they are not.

## 2. Goals

- **REQ-002:** `build-adapters.sh` generates `~/.codex/agents/sdd-opponent.toml`,
  `sdd-reality-check.toml`, and `sdd-implement-hard.toml` from the canonical
  persona files + models.yml (codex model/effort of each role's tier), pruning
  stale kit-generated TOMLs the same way it prunes stale tier profiles.
- **REQ-003:** The Codex skill adapters instruct delegation: gate tasks →
  `sdd-opponent` / `sdd-reality-check`; `[hard]` tasks, failed-acceptance
  retries, and gate follow-ups → `sdd-implement-hard`.
- **REQ-004:** The stale single-agent documentation is corrected everywhere it
  appears: the adapter preamble in `build-adapters.sh`, the "Single-agent note"
  in `agents/opponent.agent.md`, a matching cross-CLI note in
  `agents/reality-check.agent.md`, constitution §10.5's phrasing, and the
  README's per-CLI model-policy section.
- **REQ-005:** `model-policy.sh` accepts the currently documented
  `model_reasoning_effort` values for Codex (adds `ultra`, `max`, `none` to
  `minimal|low|medium|high|xhigh`) in both `validate_field` and `check`.
- **REQ-006:** The Copilot `agent`-tool handoff is verified empirically on this
  machine (copilot 1.0.70, headless `-p` + `.github/agents` profile with a
  distinct `model:`); the finding — works or doesn't, with captured output — is
  written to `knowledge/`, and Copilot-facing docs promise delegation ONLY if
  the prototype succeeds.

## 3. Non-goals

- Changing any Claude-side behavior (Agent-tool dispatch already works).
- Copilot subagent gates in this spec — REQ-006 decides whether that becomes a
  follow-up spec; nothing Copilot-facing is promised here.
- Porting to the private kit repo (separate follow-up, same as prior PRs).
- Auto-installing subagents for CLIs that are absent (`~/.codex` missing →
  skip, exactly like existing adapter behavior).

## 4. Success metrics

- **MET-001:** The next Codex-dispatched spec's gate reports record subagent
  provenance (report's Agent line names the sdd-* subagent, not a persona
  pass) — checked at that spec's retro. Otherwise n/a: internal tooling with
  no runtime telemetry.

## 5. User stories

### As a kit user running a spec on Codex CLI

- I can have the opponent gate attack the diff with fresh context so that the
  verdict isn't produced by the same context that wrote the code.
- I can tag a task `[hard]` and have Codex delegate it to the reasoning-tier
  subagent so that escalation semantics match Claude.
- If I never installed the kit subagents, the gates still run (persona-pass
  fallback) rather than being skipped.

### As the kit maintainer

- I can re-run `build-adapters.sh` after a models.yml edit and the subagent
  TOMLs restamp with the new models, with stale ones pruned.
- I can read honest docs: Copilot promises only what the prototype proved.

## 6. Acceptance criteria

- [ ] **AC-001:** With `~/.codex` present and a valid models.yml,
  `build-adapters.sh` writes the three TOMLs with `name`, `description`,
  `developer_instructions` (full persona body for the gates; inline brief for
  implement-hard), `model`, and `model_reasoning_effort` matching the role's
  tier (proves REQ-002) — `tests/run.sh adapters`.
- [ ] **AC-002:** A kit-generated `sdd-*.toml` whose role/tier disappears from
  models.yml is pruned on the next run; user-authored TOMLs (no kit marker)
  are never touched (proves REQ-002) — `tests/run.sh adapters`.
- [ ] **AC-003:** With no models.yml, or `~/.codex` absent, adapter generation
  degrades exactly as today: no TOMLs written, no error (proves REQ-002) —
  `tests/run.sh adapters`.
- [ ] **AC-004:** The generated Codex skill adapters contain the delegation
  instructions (gates → sdd-opponent/sdd-reality-check with persona-pass
  fallback; [hard]/retries/follow-ups → sdd-implement-hard), and the Copilot
  adapters retain persona-pass wording (proves REQ-003) — `tests/run.sh
  adapters`.
- [ ] **AC-005:** `model-policy.sh set tier <t> codex effort ultra` (and `max`,
  `none`) is accepted; an invalid value is still rejected; `check` passes a
  policy using the new values (proves REQ-005) — `tests/run.sh model-policy`.
- [ ] **AC-006:** Every stale "no subagents on Codex" claim is gone from
  `build-adapters.sh`'s preamble, both gate personas, constitution §10.5, and
  the README; each now states the subagent path + fallback (proves REQ-004) —
  `grep` finds no stale phrasing; the updated sections name both modes.
- [ ] **AC-007:** A captured headless Codex run (`codex exec`, sandboxed
  read-only) with the generated agents installed demonstrates the CLI accepts
  the TOMLs (no config error) and can enumerate/spawn a kit subagent; output
  committed to the spec's `notes/` (proves REQ-002 end-to-end on the installed
  codex 0.144.1).
- [ ] **AC-008:** The Copilot prototype ran headlessly with a scratch
  `.github/agents/` profile; the captured transcript and a works/doesn't-work
  finding are in `knowledge/cli-subagent-delegation.md` (new file), and no
  kit doc promises Copilot delegation unless the transcript shows it working
  (proves REQ-006).

## 7. Constraints

- **CON-001:** bash 3.2 + BSD tools only (the kit's floor); zero new
  dependencies; shellcheck -S warning clean.
- **CON-002:** Personal-scope install only (`~/.codex/agents/`), mirroring the
  existing `~/.codex/sdd-<tier>.config.toml` convention — the kit never writes
  into user projects' `.codex/` directories.
- **CON-003:** Never overwrite or prune a TOML the kit didn't generate — the
  kit marker comment is the ownership test.
- **CON-004:** The two kit repos stay identical on kit files (port follows
  merge, as with prior PRs).

## 8. Open questions

(none — decisions logged in STATUS; the riskiest unknowns are covered by
empirical ACs 007/008 rather than assumptions)

## 9. References

- Codex subagents docs: https://learn.chatgpt.com/docs/agent-configuration/subagents
- Copilot custom agents reference: https://docs.github.com/en/copilot/reference/custom-agents-configuration
- Docs reality-check findings: session 2026-07-14 (this spec's origin)
- Related: public PR #11 ("write plans for the tier below") — introduced
  `[hard]` + `implement-hard` on Claude
