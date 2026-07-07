---
name: sdd:tasks
description: Spec-driven development phase 3. Read an accepted plan.md and produce tasks.md alongside it — a numbered, dependency-ordered checklist where each task is small enough to be a single commit and has an explicit acceptance check. Use when the user types /sdd:tasks, says "break this down", "task this out", or asks for a task list for a spec that already has a plan.
---

# /sdd:tasks — Decompose a plan into tasks

Phase 3 of the SDD workflow. Reads an accepted `plan.md`, writes `tasks.md`
next to it.

**Umbrella spec?** (`repos:` in spec.md frontmatter) Read
`~/.sdd/templates/umbrella-guide.md` §Tasks for the `[repo:]` tagging and
contract-first stage ordering that override the defaults below.

## Step-by-step

### 1. Locate the plan

Same resolution as `/sdd:plan`. The spec dir must contain `spec.md` and a
`plan.md` that is more than the untouched template (new-spec.sh copies
placeholders on day 1 — a placeholder plan means `/sdd:plan` hasn't run;
stop and say so). If plan.md status is `draft`, confirm with the user it's
accepted, then `~/.sdd/scripts/spec-status.sh --file plan.md set <dir> status accepted`.

### 2. Read inputs

`STATUS.md` (decisions, open questions) → `spec.md` (REQ/AC ids) → `plan.md`
(the architecture) → both constitutions.

### 3. Decompose

Walk the plan's Architecture section; each component-level change becomes 1–5
tasks. Per task: **`T###`** (sequential, zero-padded) · **`[P]`** when
parallel-safe · **subject** (imperative, 4–10 words) · ***Files:*** (concrete
paths) · ***Acceptance:*** (the observable check — "unit test added and
passes", "integration test covers AC-###", "endpoint returns expected JSON") ·
***Refs:*** (REQ-###/AC-### + plan section).

Every AC-### must be covered by at least one **implementation** task's Refs —
gate tasks enumerate every AC by design, so they don't count
(`sdd-analyze.sh` enforces exactly this).

Stage order (template gives the skeleton): Setup → Backend/domain → API →
Frontend → Tests (happy + error per AC) → Observability → Docs → Reality
Check → Ship. Same-stage tasks on disjoint files get `[P]`.

#### Pre-ship gates (always insert both, in order)

The template ships the Reality Check stage — your job is the `Agent:` and
`Refs:` fields.

- **Gate 1 — Opponent** (adversarial correctness): fixed
  `~/.sdd/agents/opponent.agent.md`; Refs enumerate EVERY REQ + AC.
- **Gate 2 — Reality-check** (AC evidence). Resolve `Agent:` in order:
  (1) project constitution's "Reality-check agent" pin, verbatim;
  (2) exactly one `<project>/.claude/agents/reality-?check.*\.md` (several →
  list them all; `/sdd:implement` asks); (3) hub default
  `~/.sdd/agents/reality-check.agent.md`. Refs enumerate every AC. It receives
  `notes/opponent.md` — opponent runs first.

### 4. Sanity-check scale

More than ~25 tasks → recommend splitting the spec. A task spanning >~5 files
or needing a multi-sentence acceptance → split it. Inline `Depends on: T###`
notes only where ordering isn't obvious from position.

### 5. Write tasks.md

From the template. Frontmatter: `tasks_for: NNN-slug`, `status: draft`,
`created:`/`updated:` today. Tasks as `- [ ] **T###** …` so the checkbox
tooling (`spec-task.sh`) can flip them.

### 6. Validate

`bash ~/.sdd/scripts/sdd-analyze.sh <spec-dir>` — fix every error before
handing off (AC coverage, ref integrity, acceptance lines, duplicate ids,
gates resolvable, leftover placeholders, `[NEEDS CLARIFICATION]` markers —
resolve those with the user, never delete silently).

### 7. Update STATUS.md

`phase: tasks`, `active_tool: claude`; Where-things-stand / Next action →
`/sdd:implement` (worktree gets cut on first implement).

### 8. Hand off

Path, task count + parallelizable count, any tasks needing user input, next:
`/sdd:implement` (or `/sdd:implement T001`).

## Grounding rules — non-negotiable

1. Never write a path, ID, or verdict from memory — only from a file read or command run this session.
2. Re-read the exact artifact lines before acting on them.
3. Unknown → ask or write `[NEEDS CLARIFICATION: <question>]`; never guess silently.
4. Paste real command output, never "it worked".
5. Artifacts disagree → stop, reconcile (spec > plan > tasks), say what changed.

## Rules

- **No code changes** — tasks describe; `/sdd:implement` does.
- **Every task has an acceptance check.** A task without a check is a wish.
- **Refs are mandatory** — a task that can't cite a REQ/AC/plan section probably shouldn't exist.
- **No ceremony padding** — "run linter" is not a task unless the plan adds a lint rule.

## Done when

- `tasks.md` exists; all tasks have files + acceptance + refs.
- `sdd-analyze.sh <spec-dir>` exits 0 — you ran it and pasted the summary line.
- The user has the path, the counts, and the next step.
