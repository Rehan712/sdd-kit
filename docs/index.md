# SDD Kit

A portable setup for **spec-driven development** (SDD): every non-trivial change is
captured as a spec, planned, decomposed into checkable tasks, implemented in an
isolated git worktree, and blocked from shipping until **two adversarial gates**
pass. Works across all your projects from one install, and drives Claude Code,
Codex CLI, and Copilot CLI from the same canonical skill files. Cursor and
Antigravity get the same skills as single-agent adapters.

> Spec → Plan → Tasks → Implement → Retro. Specs are the durable artifact; code is
> what falls out.

## Start here

- [Install](install.md) — set the kit up on a machine and in a project
- [The workflow](workflow.md) — the five phases and the two blocking gates
- [Model tiering (which model runs each phase)](model-tiering.md) — which model and effort each phase uses
- [Skills, style and routing](skills-and-routing.md) — style guides, official skills and per-project routing
- [Dispatch, loops and usage limits](dispatch.md) — mixing providers per phase and surviving a usage limit
- [Multi-repo features (umbrella specs)](multi-repo.md) — one spec across several repositories
- [Scripts](scripts.md) — the deterministic scripts behind the skills
- [Versioned verification workflow](verification.md) — typed tests, captures and reports
- [Customizing](customizing.md) — overrides, models and your own skills
- [What's in the box](layout.md) — the kit's directory layout

## Credits

The workflow follows the spec-kit school of spec-driven development
([github/spec-kit](https://github.com/github/spec-kit)), extended with adversarial
pre-ship gates, cross-tool STATUS handoff, worktree isolation, and a retro loop.
Three rules come from
[Harness²](https://github.com/google-research/harness2) (ideas only, no code):
a lesson is opened by a cue, prose is the form a later session can skip, and
what a reviewer reads is evidence rather than instruction.
