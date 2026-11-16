# SDD Kit — spec-driven development, multi-project, multi-CLI

A portable setup for **spec-driven development** (SDD): every non-trivial change is
captured as a spec, planned, decomposed into checkable tasks, implemented in an
isolated git worktree, and blocked from shipping until **two adversarial gates**
pass. Works across all your projects from one install, and drives Claude Code,
Codex CLI, and Copilot CLI from the same canonical skill files. Cursor and
Antigravity get the same skills as single-agent adapters.

> Spec → Plan → Tasks → Implement → Retro. Specs are the durable artifact; code is
> what falls out.

**Documentation: <https://rehan712.github.io/sdd-kit/>**

## Install

```bash
git clone <this-repo> ~/sdd-kit        # anywhere you like
cd ~/sdd-kit
scripts/setup.sh
```

`setup.sh` links `~/.sdd` to the clone and wires up your CLIs; the plugin install and per-project setup are on the [Install](https://rehan712.github.io/sdd-kit/install/) page.

## Quick start

```
/sdd:specify "<feature>"   # interview → spec.md
/sdd:plan                  # plan.md, reviewed once by the opponent
/sdd:tasks                 # tasks.md — commit-sized, each with a check
/sdd:implement             # code in a spec worktree, two gates, then the PR
```

The [workflow](https://rehan712.github.io/sdd-kit/workflow/) page walks through each phase and the two gates.

## Documentation

- [Install](https://rehan712.github.io/sdd-kit/install/) — setup, the plugin, per-project setup
- [The workflow](https://rehan712.github.io/sdd-kit/workflow/) — phases, rounds and the two gates
- [Model tiering (which model runs each phase)](https://rehan712.github.io/sdd-kit/model-tiering/) — style guides, skills, routing, usage limits
- [Skills, style and routing](https://rehan712.github.io/sdd-kit/skills-and-routing/) — which skills and agents run where
- [Dispatch, loops and usage limits](https://rehan712.github.io/sdd-kit/dispatch/) — cross-CLI dispatch and recovery
- [Multi-repo features (umbrella specs)](https://rehan712.github.io/sdd-kit/multi-repo/) — one spec across several repos
- [Scripts](https://rehan712.github.io/sdd-kit/scripts/) — every script and the kit's own tests
- [Versioned verification workflow](https://rehan712.github.io/sdd-kit/verification/) — how acceptance is checked and captured
- [Customizing](https://rehan712.github.io/sdd-kit/customizing/) — make the kit yours
- [What's in the box](https://rehan712.github.io/sdd-kit/layout/) — the files and what each is for
