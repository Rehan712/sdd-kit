---
tasks_for: NNN-slug
status: draft  # draft | in-progress | complete
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Tasks: <Spec Title>

> Dependency-ordered checklist. Each task is small enough to be a single commit and has an explicit acceptance check.

**Conventions:**

- `T###` is the task ID. Reference from commit messages and PR descriptions.
- *Files:* lists the paths the task touches.
- *Acceptance:* the observable check that says the task is done.
- *Evidence:* appended by `/sdd:implement` when acceptance passes — the exact
  command + its key output line + date, e.g. `` `bun test api` → 14 passed (2026-07-04) ``.
  **A box is never ticked without it.** `[x]` with no *Evidence:* is an unproven
  claim: `sdd-analyze.sh` warns, and the reality-check gate treats it as a gap.
- Tasks that can run in parallel are marked `[P]` after the ID.
- **Umbrella specs only** (spec.md with `repos:` frontmatter): every non-gate,
  non-Ship task also carries `[repo:<name>]` after the ID — the declared repo it
  lands in. `~/.sdd/scripts/spec-worktree.sh --repo <name> <spec-dir>` gives you
  that repo's worktree. `sdd-analyze.sh` rejects untagged or mis-tagged tasks.
- Use `[ ]` for not started, `[~]` for in-progress, `[x]` for done.
- Follow-up ids: `T###o1, o2, …` = opponent findings and `T###a, b, …` =
  reality-check gaps (both inserted under Reality Check); `T###s1, s2, …` =
  security findings (inserted under the original task's stage).
- After editing this file, validate with `~/.sdd/scripts/sdd-analyze.sh <spec-dir>` —
  it checks AC coverage (gate refs don't count), refs, evidence, gates, and
  leftover `[NEEDS CLARIFICATION]` markers deterministically.

## Setup

- [ ] **T001** — Add dependencies and scaffolding
  - *Files:* `package.json` (or equivalent)
  - *Acceptance:* `bun install` / `pnpm install` / `cargo build` succeeds

## Backend (or "Domain layer")

- [ ] **T002** — <name>
  - *Files:* `src/...`
  - *Acceptance:* unit test added, passes
  - *Refs:* REQ-001, REQ-002 (from spec)

- [ ] **T003** [P] — <name>
  - *Files:* `src/...`
  - *Acceptance:* ...

## Frontend (if applicable)

- [ ] **T004** — <name>
  - *Files:* `apps/web/...`
  - *Acceptance:* component renders; manual smoke OK at 375px and 1280px

## Tests

- [ ] **T005** — Integration test for happy path
  - *Files:* `tests/...`
  - *Acceptance:* CI green; AC-001 covered

- [ ] **T006** — Integration test for error path
  - *Files:* `tests/...`
  - *Acceptance:* AC-002 covered

## Observability

- [ ] **T007** — Add metric / log / dashboard
  - *Files:* `infra/...`, `src/...`
  - *Acceptance:* metric visible in CloudWatch (or equivalent) on next deploy

## Docs

- [ ] **T008** — Update README / API docs
  - *Files:* `README.md`, `docs/...`
  - *Acceptance:* manual review

## Reality Check (pre-ship gate)

> Every spec gets this stage: **two adversarial gates, both blocking, run in order.**
> Neither grades its own work — on Claude each is delegated via the Agent tool; on
> Codex/Copilot the agent adopts the persona as a distinct review pass. `/sdd:tasks`
> resolves the `Agent:` fields; `/sdd:implement` runs the opponent first, then reality-check.
>
> - **Opponent** (`agents/opponent.agent.md`) — steelmans why the implementation is *wrong*. Default verdict **CHALLENGED**.
> - **Reality-check** — verifies every AC-### has *evidence*. Resolved by (1) the project constitution's pin, (2) any project-local `.claude/agents/reality-check*.md`, (3) the hub default `agents/reality-check.agent.md`. Default verdict **NEEDS WORK**.

- [ ] **T009** — Opponent review: steelman why this implementation is wrong
  - *Agent:* `~/.sdd/agents/opponent.agent.md`
  - *Inputs:* the diff on this branch, `spec.md`, `plan.md`, every `[x]` task
  - *Acceptance:* agent returns **CLEARED** (not CHALLENGED); findings written to `notes/opponent.md`
  - *Refs:* every REQ-### / AC-### in the spec
  - *On CHALLENGED:* open follow-up tasks here (T009o1, T009o2, …) for each defect; fix and re-run before T010

- [ ] **T010** — Reality-check the implemented spec end-to-end
  - *Agent:* `<resolved by /sdd:tasks — project-local path or hub default>`
  - *Inputs:* every prior `[x]` task, `spec.md`, `plan.md`, `notes/opponent.md`
  - *Acceptance:* agent returns **READY** (not NEEDS WORK / FAILED); claim-vs-evidence gaps documented in `notes/reality-check.md`; all AC-### in `spec.md` mapped to concrete evidence
  - *Refs:* every AC-### in the spec
  - *On NEEDS WORK:* open follow-up tasks here (T010a, T010b, …) for each fix the agent demanded; do not proceed to Ship until they're `[x]` and the gate is re-run

## Ship

- [ ] **T011** — Open PR to the base branch (stack.yml `base_branch:`, default `dev`) referencing `spec.md` and `plan.md`
  - *Files:* (none — branch + PR)
  - *Acceptance:* `~/.sdd/scripts/spec-pr.sh <spec-dir>` run; PR URL pasted into `STATUS.md` (`pr:`); review requested; both gate verdicts linked in the PR body

- [ ] **T012** — Roll out
  - *Acceptance:* feature flag flipped / deploy verified / dashboards green for 24h; `STATUS.md` phase set to `shipped`

- [ ] **T013** — Retro: harvest lessons into the hub
  - *Acceptance:* `/sdd:retro` run; `notes/retro.md` written; any cross-project lesson appended to the hub `knowledge/`; `STATUS.md` `retro:` set to `done`
  - *Refs:* `notes/opponent.md`, `notes/reality-check.md`, STATUS decisions log

---

*Workflow:* Once a task is done, tick its checkbox. Run `/sdd:implement` to execute the next pending task. When all tasks are `[x]`, set frontmatter `status: complete`.
