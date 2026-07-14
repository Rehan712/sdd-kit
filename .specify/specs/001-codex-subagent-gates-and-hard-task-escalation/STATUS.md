---
spec: 001-codex-subagent-gates-and-hard-task-escalation
phase: implement          # specify | plan | tasks | implement | review | shipped | abandoned
active_tool: claude     # claude | codex | copilot | none — who currently holds the spec
branch: spec/001-codex-subagent-gates-and-hard-task-escalation            # spec/001-codex-subagent-gates-and-hard-task-escalation once cut, else none
worktree: /Users/babar/projects/sdd-kit-public.worktrees/001-codex-subagent-gates-and-hard-task-escalation          # absolute path once created, else none
pr: none                # PR URL once opened — spec-pr.sh writes this itself
opponent: not-run       # not-run | CHALLENGED | CLEARED | BLOCKED  (+ date)
reality_check: not-run  # not-run | NEEDS WORK | FAILED | READY  (+ date)
ci: not-run             # not-run | pending | green | red  (+ date) — spec-ci.sh writes this
retro: not-run          # not-run | done (+ date) — /sdd:retro after ship
updated: 2026-07-14
---

# STATUS — Codex subagent gates and hard-task escalation

## Where things stand

tasks.md written and validated (sdd-analyze: consistent, 0 warnings) — 14
tasks: 3 backend, 2 test suites, 2 empirical (codex accepts TOMLs; copilot
handoff prototype), 2 docs (gated on the empirical outcomes), gates, ship.
Next: implement (worktree cut on first run).

## Decisions log

- 2026-07-14 — Spec created from the docs reality-check (Codex subagents GA;
  kit's single-agent claims stale).
- 2026-07-14 — Subagent TOMLs install to PERSONAL scope `~/.codex/agents/`
  only, mirroring `~/.codex/sdd-<tier>.config.toml` — the kit never writes
  into user projects' `.codex/` dirs / owner.
- 2026-07-14 — TOML names prefixed `sdd-` + a kit-marker comment as the
  ownership test for pruning; user-authored TOMLs never touched / owner.
- 2026-07-14 — implement-hard has no persona file on Claude (runtime role);
  its Codex `developer_instructions` are authored inline in build-adapters.sh,
  like the existing PREAMBLE / owner.
- 2026-07-14 — Copilot stays persona-pass in ALL docs until the REQ-006
  prototype proves the `agent`-tool handoff empirically / owner.
- 2026-07-14 — Riskiest unknowns (does installed codex 0.144.1 really accept
  the TOMLs; does copilot 1.0.70 really delegate) are ACs with captured
  evidence (AC-007/AC-008), not assumptions / owner.
- 2026-07-14 — Persona bodies ship in TOML multi-line LITERAL strings (''')
  so backslashes survive; build fails loudly if a persona ever contains ''' /
  plan §3.
- 2026-07-14 — Adapter tests get hermeticity by copying the kit into $SANDBOX
  and running with HOME=$SANDBOX/home — zero script changes for testability /
  plan §4 seam.
- 2026-07-14 — AC-007 (codex accepts TOMLs) runs EARLY in the Tests stage so a
  wrong TOML shape is fixed against observed behavior before doc tasks land /
  plan R1.
- 2026-07-14 — No stack expert matches bash+markdown kit work (stacks: []);
  tasks executed by the session directly; user declined the implement→copilot
  dispatch for this spec / user + owner.
- 2026-07-14 — Empirical: codex 0.144.1 spawns kit subagents from both scopes,
  instructions load, per-agent model pin NOT honored (session model used);
  copilot 1.0.70 handoff works INCLUDING model pin. Docs phrased accordingly;
  copilot gate delegation deferred to a follow-up spec / notes/codex-subagents.md.
- 2026-07-14 — T007/T009 Files amended (+ binding tests in
  tests/test-build-adapters.sh for AC-006/007/008; COPILOT_PREAMBLE truth-fix
  in T009); T008's Verify used `grep -L` whose exit code can never be 0 —
  amended to `! grep -q` form / owner.

## Open questions / blockers

(none)

## Handoff note

Work in the public kit repo (/Users/babar/projects/sdd-kit-public); port to
the private repo after merge (CON-004). codex 0.144.1 and copilot 1.0.70 are
installed on this machine — the empirical ACs must run here.

## Next action

`/sdd:plan`
