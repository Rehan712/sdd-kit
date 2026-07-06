---
name: sdd:tasks
description: Spec-driven development phase 3. Read an accepted plan.md and produce tasks.md alongside it — a numbered, dependency-ordered checklist where each task is small enough to be a single commit and has an explicit acceptance check. Use when the user types /sdd:tasks, says "break this down", "task this out", or asks for a task list for a spec that already has a plan.
---

# /sdd:tasks — Decompose a plan into tasks

Phase 3 of the SDD workflow. Reads an accepted `plan.md` and writes `tasks.md` next to it.

## Step-by-step

### 1. Locate the plan

Same resolution rules as `/sdd:plan`: explicit slug → most-recent spec dir in resolved project. The spec dir must contain both `spec.md` and `plan.md`.

### 2. Read inputs

- `STATUS.md` (phase, prior decisions, open questions)
- `spec.md` (for REQ-### and AC-### references)
- `plan.md` (the architecture you're decomposing)
- The same constitutions as `/sdd:plan`

### 3. Decompose

Walk the plan's Architecture section and break each component-level change into 1-5 tasks. For each task:

- **`T###` id** — sequential, zero-padded to 3 digits.
- **`[P]` marker** — when the task can run in parallel with siblings.
- **`[repo:<name>]` tag** — umbrella specs only (spec.md has `repos:` frontmatter): every non-gate, non-Ship task names the declared repo it lands in. Tasks in different repos are `[P]` by default (disjoint checkouts); the plan's contract ordering still constrains stages.
- **Subject** — imperative, 4-10 words.
- **Files** — concrete paths (relative to project root — for umbrella tasks, relative to the tagged repo's root) the task touches.
- **Acceptance** — the observable check. Usually one of: "unit test added and passes", "integration test covers AC-###", "CLI smoke runs cleanly", "endpoint returns expected JSON", "metric visible in CloudWatch".
- **Refs** — REQ-### or AC-### from the spec, and any plan section.

Every AC-### in the spec must be covered by at least one **implementation** task's Refs — the gate tasks enumerate every AC by design, so their Refs don't count as coverage (`sdd-analyze.sh` enforces exactly this).

Suggested ordering by stage (template gives the skeleton):

1. **Setup** — dependencies, scaffolding, migrations.
2. **Backend / domain layer** — types, schemas, repository, services.
3. **API surface** — controllers, Lambda handlers, route definitions.
4. **Frontend** (if applicable) — components, hooks, page wiring.
5. **Tests** — happy + error paths covering each AC-###.
6. **Observability** — logs, metrics, alarms.
7. **Docs** — README, API docs.
8. **Reality check** — two pre-ship gates, both always inserted (see below).
9. **Ship** — PR to the project's base branch via `scripts/spec-pr.sh` (it refuses
   unless both gates passed), rollout, and the retro task (`/sdd:retro` — harvests
   lessons into the hub).

Tasks in the same stage that touch disjoint files get `[P]`.

**Umbrella ordering** (multi-repo — follows the plan's contract section and `knowledge/cross-repo-contracts.md`):

1. **Contracts** — the schema/OpenAPI/event change in each contract's source repo. Always the first stage.
2. **Infra** — resources the feature needs (`[repo:<infra-repo>]`, e.g. the troposphere repo), before the services that consume them.
3. **Providers** — backend services implementing the contract.
4. **Consumers** — web / mobile / big-screen clients (codegen regeneration is its own task per consumer repo).
5. Then Tests / Observability / Docs / Reality check / Ship as usual.

Dependencies on other teams' repos are **never tasks** — the spec's `[EXTERNAL: …]` markers cover them; add a stub-at-contract task in your own repo where needed. In Ship, create **one PR task per declared repo** (`scripts/spec-pr.sh --repo <name> <spec-dir>`), and order the *merge/deploy* expectation providers-before-consumers in the rollout task.

#### Pre-ship gates (always insert — two of them, in order)

Every spec gets the Reality Check stage between Docs and Ship — no exceptions. It contains **two blocking adversarial gates** that run in order. The template already has both; your job is to fill in their `Agent:` and `Refs:` fields.

**Gate 1 — Opponent** (adversarial correctness). Fixed agent: `~/.sdd/agents/opponent.agent.md`. It steelmans why the implementation is *wrong* (edge cases, races, regressions, misread requirements). `Refs:` enumerates **every** REQ-### and AC-###. Default verdict CHALLENGED.

**Gate 2 — Reality-check** (AC evidence). Resolve its `Agent:` field in this order:

1. **Constitution pin.** If `<project>/.specify/constitution.md` has a "Reality-check agent" line naming a path, use that path verbatim.
2. **Project-local agent.** Otherwise scan `<project>/.claude/agents/` for a file matching `reality-?check.*\.md`. If exactly one matches, use it. If multiple match, list them all on the `Agent:` line — `/sdd:implement` will ask which to use.
3. **Hub default.** Otherwise use `~/.sdd/agents/reality-check.agent.md`. This is the stack-agnostic default that ships with the hub. Every project gets a working gate even without local setup.

*Umbrella specs:* there is no single `<project>`, so skip the per-project resolution — use the hub default. Both gates run ONCE, spec-wide, reviewing every repo's diff together (cross-repo integration is exactly what a per-repo review would miss).

Write the resolved path into Gate 2's `Agent:` field exactly as resolved (absolute path for the hub default, relative for project-local). Its `Refs:` enumerates **every** AC-### in `spec.md`. The opponent runs first so its findings are fixed before reality-check confirms evidence; reality-check takes `notes/opponent.md` as an input.

### 4. Estimate scale

After drafting, sanity-check:

- If you have more than ~25 tasks, the spec is too large — recommend splitting.
- If a single task spans more than ~5 files or you can't write an acceptance check in one sentence, split that task.
- Add explicit dependency notes inline only when the ordering isn't obvious from position.

### 5. Write tasks.md

Fill from the template. Frontmatter:

```yaml
tasks_for: NNN-slug
status: draft
created: <today>
updated: <today>
```

Each task uses `- [ ] **T###** ...` so `/sdd:implement` can flip checkboxes.

### 6. Validate with sdd-analyze

Run the deterministic consistency check and fix every error it reports **before**
handing off:

```
bash ~/.sdd/scripts/sdd-analyze.sh <spec-dir>
```

It verifies: every AC-### has a covering implementation task (gate Refs don't
count), all task refs resolve, every task has an acceptance line, no duplicate
ids, both gates present with resolvable `Agent:` paths, no leftover template
placeholders, and no unresolved `[NEEDS CLARIFICATION]` markers in spec/plan.
Errors mean the decomposition is broken — don't ship a broken checklist to
`/sdd:implement`. If a `[NEEDS CLARIFICATION]` marker fails the run, resolve it
with the user (don't delete it silently).

### 7. Update STATUS.md

- `phase: tasks`, `active_tool: claude`, bump `updated:`.
- **Where things stand** / **Next action** → tasks ready, `/sdd:implement` (worktree gets cut on first implement).

### 8. Hand off

Tell the user:

- The path to `tasks.md`.
- The total task count and how many are parallelizable.
- Any tasks you're uncertain about (e.g., requires user input on a tool choice).
- Suggested next command: `/sdd:implement` (or `/sdd:implement T001` to start from a specific task).

## Grounding rules — non-negotiable

1. **Never write a path, ID, or verdict from memory.** Every file path, spec/task/AC/REQ id, and status value you use must come from a file you read or a command you ran *in this session*. If you can't point at its source, resolve it before using it.
2. **Quote before you act.** Before acting on an artifact, re-read the relevant lines and satisfy exactly what they say — not your recollection of them.
3. **Unknown → ask or mark, never invent.** If the user or the artifacts don't answer a question, ask — or write `[NEEDS CLARIFICATION: <question>]` into the artifact. A silent guess is the failure mode this workflow exists to prevent.
4. **Paste outputs, don't paraphrase.** Report any script/command result as the actual output lines, trimmed — never a summary like "it worked".
5. **On contradiction, stop.** If artifacts disagree with each other or with what the user said, don't silently pick one: surface it, reconcile (spec wins over plan, plan over tasks), and say what you changed.

## Rules

- **No code changes.** Tasks describe what to do; `/sdd:implement` does it.
- **Every task has an acceptance check.** No "do X" without a "verify Y". A task without a check is a wish.
- **Refs are mandatory.** Each task points back to at least one REQ-### / AC-### / plan section. If you can't, that task probably shouldn't exist.
- **Don't pad with ceremony.** "Run linter" is not a task unless the plan explicitly introduces a new lint rule.

## Done when

- `tasks.md` exists, all tasks have files + acceptance + refs.
- `sdd-analyze.sh <spec-dir>` exits 0 — you ran it and pasted the summary line.
- The user has the path, the count, the parallelism note, and the next step.
