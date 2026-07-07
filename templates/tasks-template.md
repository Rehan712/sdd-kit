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
- *Evidence:* appended when acceptance passes — the exact command + its key
  output line + date, e.g. `` `bun test api` → 14 passed (2026-07-04) ``.
  **A box is never ticked without it.** For any check the tooling can run,
  produce the evidence with `~/.sdd/scripts/spec-run.sh <spec-dir> T### --
  <command>` — it runs the command, captures the real output (+exit +hash) into
  `notes/evidence.md`, and ticks the box from that run. A bare
  `~/.sdd/scripts/spec-task.sh done <spec-dir> T### --evidence "…"` (tick +
  evidence, one atomic edit) is for manually-verified ACs. Exemption: gate and
  Ship tasks — their evidence is the gate report in `notes/` or the PR URL, so
  no *Evidence:* line is required there.
- Tasks that can run in parallel are marked `[P]` after the ID.
- **Umbrella specs only** (spec.md with `repos:` frontmatter): every non-gate,
  non-Ship task also carries `[repo:<name>]` after the ID — the declared repo it
  lands in. `~/.sdd/scripts/spec-worktree.sh --repo <name> <spec-dir>` gives you
  that repo's worktree. `sdd-analyze.sh` rejects untagged or mis-tagged tasks.
- Use `[ ]` for not started, `[~]` for in-progress, `[x]` for done.
- Follow-up ids share ONE grammar — `T###<class><n>` under the task that
  spawned them: `o` = opponent findings, `a` = reality-check gaps (both under
  Reality Check), `s` = security findings (under the original task's stage),
  `c` = CI failures and `r` = review feedback (both under Ship, opened by
  `/sdd:review`). E.g. `T009o1`, `T010a1`, `T004s1`, `T011c1`, `T011r2`.
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

> Each test **names the AC id it proves** in its title/description (e.g.
> `it('AC-001: …')`) so the binding is checkable at the code layer —
> `~/.sdd/scripts/spec-ac-coverage.sh <spec-dir>` fails any AC no test names.

- [ ] **T005** — Integration test for happy path
  - *Files:* `tests/...`
  - *Acceptance:* CI green; test names AC-001

- [ ] **T006** — Integration test for error path
  - *Files:* `tests/...`
  - *Acceptance:* test names AC-002

## Observability

- [ ] **T007** — Add metric / log / dashboard
  - *Files:* `infra/...`, `src/...`
  - *Acceptance:* metric visible in CloudWatch (or equivalent) on next deploy

## Docs

- [ ] **T008** — Update README / API docs
  - *Files:* `README.md`, `docs/...`
  - *Acceptance:* every documented command/example in the diff actually runs (paste one); links resolve; the feature's spec ACs are reflected

## Reality Check (pre-ship gate)

> Every spec gets this stage: **two adversarial gates, both blocking, run in order.**
> Neither grades its own work — on Claude each is delegated via the Agent tool; on
> Codex/Copilot the agent adopts the persona as a distinct review pass. `/sdd:tasks`
> resolves the `Agent:` fields; `/sdd:implement` runs the opponent first, then reality-check.
>
> - **Opponent** (`agents/opponent.agent.md`) — steelmans why the implementation is *wrong*. Default verdict **CHALLENGED**.
> - **Reality-check** — verifies every AC-### has *evidence*. Runs the deterministic floor first (`spec-ac-coverage.sh` — every AC named by a test; `spec-evidence.sh` — every tick traces to real evidence), then verifies the rest by hand. Resolved by (1) the project constitution's pin, (2) any project-local `.claude/agents/reality-check*.md`, (3) the hub default `agents/reality-check.agent.md`. Default verdict **NEEDS WORK**.

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
  - *On NEEDS WORK:* open follow-up tasks here (T010a1, T010a2, …) for each fix the agent demanded; do not proceed to Ship until they're `[x]` and the gate is re-run

## Ship

> After T011, the PR lifecycle — CI triage (`T011c*`), review feedback
> (`T011r*`), rebases, the merge, worktree teardown — belongs to **/sdd:review**
> (deterministic state via `~/.sdd/scripts/spec-ci.sh`). T012 runs after merge.

- [ ] **T011** — Open PR to the base branch (stack.yml `base_branch:`, default `dev`) referencing `spec.md` and `plan.md`
  - *Files:* (none — branch + PR)
  - *Acceptance:* `~/.sdd/scripts/spec-pr.sh <spec-dir>` prints the PR URL (it writes `pr:` + `phase: review` into STATUS.md itself); both gate verdicts in the PR body; reviewer requested (`gh pr edit --add-reviewer <handle>` or ask the user who)

- [ ] **T012** — Roll out (after /sdd:review reports the PR merged)
  - *Acceptance:* feature flag flipped / deploy verified / dashboards green for 24h — with a named owner + check-back date for the 24h claim recorded in STATUS "Next action"; `STATUS.md` phase set to `shipped`; any ACs the reality-check deferred as UNVERIFIABLE now verified and noted in `notes/evidence.md`

- [ ] **T013** — Retro: harvest lessons into the hub
  - *Acceptance:* `/sdd:retro` run; `notes/retro.md` written; any cross-project lesson appended to the hub `knowledge/`; `STATUS.md` `retro:` set to `done`
  - *Refs:* `notes/opponent.md`, `notes/reality-check.md`, `notes/ci.md` (if CI failed en route), STATUS decisions log

---

*Workflow:* Once a task is done, tick its checkbox. Run `/sdd:implement` to execute the next pending task. When all tasks are `[x]`, set frontmatter `status: complete`.
