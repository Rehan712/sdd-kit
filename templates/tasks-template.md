---
tasks_for: NNN-slug
status: draft  # draft | in-progress | complete
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Tasks: <Spec Title>

> Dependency-ordered checklist. Each task is small enough to be a single commit and has an explicit acceptance check.

**Conventions:**

- Use the [verification contract](verification-contract.md) as the single
  grammar for typed verification, FM/INV references and plan-family locators.
  Planning defines families without task IDs; decomposition assigns the
  non-gate tasks that own each applicable row. Do not invent another grammar.
- `T###` is the task ID. Reference from commit messages and PR descriptions.
- *Files:* lists the paths the task touches.
- *Acceptance:* the observable check that says the task is done.
- *Verify kind:* declares the kind from the plan's registered family.
- *Tests:* names concrete locators from that family; *Refs:* includes every
  required FM/INV ID as well as the AC/REQ and plan section.
- **Tests travel with behavior.** Add or extend the covering test in the same
  task and commit as the implementation. Include its file in *Files:* and its
  behavioral assertion in *Acceptance:*. A later integration owner does not
  excuse missing local proof. Tests-stage tasks compose cross-task/stack work.
- *Reuse:* is optional; default `never`. Choose `local` only for deterministic
  checks with completely declared inputs. *Integration owner:* optionally
  names a real later integration task for a named spanning criterion.
- *Evidence:* appended when acceptance passes — the exact command + its key
  output line + date, e.g. `` `bun test api` → 14 passed (2026-07-04) ``.
  **A box is never ticked without it.** New-contract workers capture without
  ticking; the invoker validates their returns before attaching evidence and
  ticking through `spec-gate.sh accept` (verification contract). A manual
  criterion requires its declared artifact observation; it cannot exempt an
  automated check. Legacy captures retain their established readable format.
  Actual gate review and Ship administration use their report or PR artifact.
  Behavioral follow-ups still require typed tests, refs and captured proof,
  including tasks placed in Reality Check or Ship or given an *Agent:* field.
- *Verify:* the exact runnable command that proves the task, with the key
  output to expect — `` *Verify:* `bun test --filter keys` → "14 passed" `` —
  ready to paste into `spec-run.sh <spec-dir> T### --key '<key>' -- <command>`.
  A check no command can prove uses `manual: <what to observe>` instead.
  Required on every non-gate, non-Ship task; `sdd-analyze.sh` warns where it's
  missing. (*Acceptance:* states the outcome; *Verify:* is the exact check —
  a weaker implementer must never have to invent the command.)
  Missing ownership and untyped build/typecheck/text-only AC proof warn;
  malformed kinds, duplicate definitions and dangling refs are errors.
  A newly authored task list has zero test-ownership or Verify warnings.
- Tasks that can run in parallel are marked `[P]` after the ID.
- Tasks that need frontier reasoning are marked `[hard]` after the ID (marker
  order: `**T###** [P] [hard] [repo:name]`). Tag at decompose time: novel
  algorithms, tricky concurrency/ordering, cross-cutting changes are `[hard]`;
  CRUD, wiring, and config are not. `/sdd:implement` and the orchestrator
  dispatch `[hard]` tasks — and every failed-acceptance retry and gate
  follow-up — on the `implement-hard` model-policy role when models.yml maps
  it (escalate rather than repeat a failure at the tier that produced it).
  Escalation currently takes effect on Claude Code (Agent-tool dispatch);
  on Codex/Copilot the marker is inert metadata until the kit wires their
  subagent mechanisms — the tag itself is CLI-agnostic, so tag regardless.
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
  - *Verify kind:* assertion
  - *Tests:* <registered setup assertion locator for this criterion>
  - *Verify:* `bun install` → "done" (or the stack's equivalent)
  - *Refs:* <setup REQ/AC and applicable plan FM/INV rows>

## Backend (or "Domain layer")

- [ ] **T002** — <name>
  - *Files:* `src/...`, <covering test file>
  - *Acceptance:* behavior and its local test added or extended in this task; test passes
  - *Verify kind:* test
  - *Tests:* <repo-relative-file::literal-test-name from the plan registry>
  - *Verify:* `bun test src/...` → "<n> pass"
  - *Refs:* REQ-001, AC-001, FM-001, INV-001, plan §7 (replace with assigned rows)

- [ ] **T003** [P] — <name>
  - *Files:* `src/...`, <covering test file>
  - *Acceptance:* <behavior and same-task added/extended assertion>
  - *Verify kind:* assertion
  - *Tests:* <registered custom behavioral assertion locator>
  - *Verify:* `<command>` → "<key output>"
  - *Refs:* <AC/REQ and applicable plan FM/INV rows>

## Frontend (if applicable)

- [ ] **T004** — <name>
  - *Files:* `apps/web/...`, `tests/ui.spec.ts`
  - *Acceptance:* add/extend component assertions at 375px and 1280px in this task
  - *Verify kind:* test
  - *Tests:* `tests/ui.spec.ts::AC-001 responsive component`
  - *Verify:* `bunx playwright test tests/ui.spec.ts` → passed
  - *Refs:* <UI AC/REQ and applicable plan FM/INV rows>

## Tests

> Only integration spanning tasks or stacks remains here; each implementation
> task already owns its local happy/error/boundary tests in the same commit.
> Each test **names the AC id it proves** in its title/description (e.g.
> `it('AC-001: …')`) so the binding is checkable at the code layer —
> `~/.sdd/scripts/spec-ac-coverage.sh <spec-dir>` fails any AC no test names.

- [ ] **T005** — Integration test for happy path
  - *Files:* `tests/...`
  - *Acceptance:* CI green; test names AC-001
  - *Verify kind:* test
  - *Tests:* <registered cross-task integration locator>
  - *Verify:* `bun test tests/...` → "AC-001" in a passing test title
  - *Refs:* <integration AC/REQ and applicable plan FM/INV rows>

- [ ] **T006** — Integration test for error path
  - *Files:* `tests/...`
  - *Acceptance:* test names AC-002
  - *Verify kind:* test
  - *Tests:* <registered cross-task error integration locator>
  - *Verify:* `bun test tests/...` → "AC-002" in a passing test title
  - *Refs:* <integration AC/REQ and applicable plan FM/INV rows>

## Observability

- [ ] **T007** — Add metric / log / dashboard
  - *Files:* `infra/...`, `src/...`, <covering metric test file>
  - *Acceptance:* add/extend the local metric-emission test; name a post-deploy owner for the live observation
  - *Verify kind:* test
  - *Tests:* <registered metric-emission test locator>
  - *Verify:* `<unit test asserting the emit>` → "<n> pass" (the live metric is the [DEPLOY] half)
  - *Refs:* <metric AC/REQ and applicable plan FM/INV rows>

## Docs

- [ ] **T008** — Update README / API docs
  - *Files:* `README.md`, `docs/...`
  - *Acceptance:* every documented command/example in the diff actually runs (paste one); links resolve; the feature's spec ACs are reflected
  - *Verify kind:* manual
  - *Tests:* <plan-declared documentation artifact observation name>
  - *Verify:* `manual: record the documented example's observed result, observer, UTC and artifact digest`
  - *Refs:* <explicitly manual documentation criterion and applicable FM/INV rows>

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
