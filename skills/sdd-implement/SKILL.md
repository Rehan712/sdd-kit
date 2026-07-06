---
name: sdd:implement
description: Spec-driven development phase 4. Execute the tasks in tasks.md sequentially (or a specific task by id), making the code changes, running the acceptance check, ticking the checkbox in tasks.md, and proposing a conventional commit. Use when the user types /sdd:implement, /sdd:implement T###, or says "start implementing the spec", "do the next task", or similar.
---

# /sdd:implement — Execute the tasks

Phase 4 of the SDD workflow. Reads `tasks.md`, executes the next pending task (or a named task), then updates `tasks.md` to mark it done.

## Pre-flight (runs once per spec, before either mode)

**Umbrella specs are different — check first.** If the spec dir's `spec.md` has `repos:` frontmatter (umbrella spec, living in `~/.sdd/specs/NNN-slug/`), use the **umbrella pre-flight** box below instead of steps 1–5.

> ### Umbrella pre-flight
>
> 1. **Read `STATUS.md`** in the hub spec dir — including the **Repo matrix** (per-repo branch/worktree/PR state).
> 2. **No single worktree.** Each task carries a `[repo:<name>]` tag; resolve its worktree lazily, right before executing the task:
>    ```
>    WT="$(~/.sdd/scripts/spec-worktree.sh --repo <name> <spec-dir> | tail -1)"
>    ```
>    (idempotent — reuses the worktree if it exists). Record branch + worktree in the STATUS Repo matrix row the first time each repo's worktree is cut.
> 3. **The spec artifacts stay in the hub.** `tasks.md`, `STATUS.md`, and `notes/` are edited in `~/.sdd/specs/NNN-slug/` directly — the hub is not a code repo and has no spec branch. Code edits happen ONLY in the task's repo worktree.
> 4. **Worktree guard, per repo** — before the first edit in any repo's worktree each session:
>    ```
>    git -C "$WT" rev-parse --abbrev-ref HEAD    # must print spec/NNN-slug
>    ```
> 5. **Run the consistency check** on the hub spec dir (`bash ~/.sdd/scripts/sdd-analyze.sh <spec-dir>`) — it additionally enforces `[repo:]` tags for umbrella specs.
> 6. **Update `STATUS.md`**: `phase: implement`, `active_tool: claude`, bump `updated:` (frontmatter `branch:`/`worktree:` stay `none` — the matrix is the per-repo truth).

On the **first** `/sdd:implement` for a single-repo spec, set up the isolated worktree:

1. **Read `STATUS.md`** in the spec dir — phase, decisions already locked, open questions, and whether a `branch:`/`worktree:` already exist.
2. **Cut the worktree** (idempotent — safe to run every pass):
   ```
   WT="$(~/.sdd/scripts/spec-worktree.sh <spec-dir> | tail -1)"
   ```
   This creates or reuses branch `spec/NNN-slug` from the project's **base branch** (`--base` flag > `.specify/stack.yml` `base_branch:` > `dev`) and a worktree at `<repo>.worktrees/NNN-slug`, printing the path.
3. **Switch your working root to `$WT`.** For the rest of this spec, **all code edits, `tasks.md` checkbox flips, and `STATUS.md` updates happen under `$WT/…`** — not the original `dev` checkout, which stays clean. The live spec dir is `$WT/.specify/specs/NNN-slug`.
   **Worktree guard — before the first edit of every session**, assert you're where you think you are:
   ```
   git -C "$WT" rev-parse --abbrev-ref HEAD    # must print spec/NNN-slug
   ```
   If it prints anything else, stop and re-run `spec-worktree.sh` — do not edit. An edit on the wrong checkout is the single most expensive mistake this workflow can make.
4. **Run the consistency check** on the live spec dir:
   ```
   bash ~/.sdd/scripts/sdd-analyze.sh $WT/.specify/specs/NNN-slug
   ```
   Errors (uncovered ACs, dangling refs, missing gates/acceptance) mean `tasks.md`
   is broken — fix the artifacts first; don't implement against a broken checklist.
   Warnings are advisory.
   **Legacy specs** (created before the gate convention) may lack the Reality Check
   stage entirely: backfill it by copying that stage from
   `~/.sdd/templates/tasks-template.md` into `tasks.md`,
   resolving Gate 2's `Agent:` per the `/sdd:tasks` rules (constitution pin →
   project-local `reality-check*.md` → hub default), then re-run the check.
5. **Update `STATUS.md`** (in the worktree): `phase: implement`, `active_tool: claude`, `branch: spec/NNN-slug`, `worktree: $WT`, bump `updated:`.

If STATUS already names an existing worktree, skip creation and operate there. The `worktree:` field is how a different tool/session finds the in-flight branch.

## Two execution modes

The skill has two modes; pick based on what the user said:

| User said... | Mode | Behavior |
|---|---|---|
| `/sdd:implement` or `/sdd:implement T###` or "do the next task" | **single-task** | You handle one task directly (steps 1–8 below). |
| `/sdd:implement --all`, "implement the spec", "do all of them", "run the whole spec" | **orchestrated** | Hand the whole `tasks.md` to the `SDDOrchestrator` agent (defined at `~/.sdd/agents/sdd-orchestrator.md`, linked into every Claude home) via the Agent tool. It plans the DAG, dispatches batches, runs cross-cuts, hits the gate, and reports back. Skip steps 3–8 — the orchestrator owns them. |

In orchestrated mode, your prompt to the Agent tool contains: the worktree path `$WT` (the working root), the live spec dir absolute path (inside `$WT`), resolved project root + stack tags, the user's stop-point (if any), and both constitutions. The orchestrator agent definition specifies the rest.

*Umbrella specs, orchestrated:* instead of one `$WT`, pass the hub spec dir absolute path (`~/.sdd/specs/NNN-slug` — where tasks.md/STATUS.md live and get edited), a table of `repo name → local path → worktree path` for every declared repo (cut them all first: `spec-worktree.sh --all-repos <spec-dir>`), and each repo's stack tags. The orchestrator routes every task to its `[repo:]` worktree.

The single-task flow continues below.

## Step-by-step (single-task mode)

### 1. Locate the task list

Same resolution as `/sdd:tasks`. The spec dir must contain `tasks.md`.

If the user passed a task id (e.g., `/sdd:implement T003`), use that. Otherwise, pick the first unchecked task.

### 2. Read the full context for that task

For the task being executed:

- The task itself (subject, files, acceptance, refs).
- The relevant section of `plan.md` (referenced via the task's `Refs:` field).
- The relevant `spec.md` REQ-### / AC-###.
- Any sibling tasks already marked done (don't redo them).
- The cross-project + project constitution.
- The stack overlay(s) for the project's stacks.
- *Umbrella tasks:* the tagged repo's worktree (`spec-worktree.sh --repo <name> <spec-dir>`, then the guard), that repo's stack tags + overlays, and its `~/.sdd/briefs/<name>.md` if present. The task's *Files:* are relative to that repo's root.

### 3. Pick the right subagent

If the task lives under the `## Reality Check` heading or carries an `Agent:` field (pointing at `opponent.agent.md` or a `reality-check*.md`) — skip the stack-routing table and jump to **§5a Pre-ship gates**. If it's a **Ship** task (PR / rollout) → **§5b**.

Otherwise, if the task is stack-specific, delegate the implementation to the matching subagent (canonical files at `~/.sdd/agents/`, surfaced to each Claude account via the `~/.claude*/agents` symlink):

| Signal | Use |
|---|---|
| `app/`, `pages/`, `components/`, `next.config.*` (Next.js) | `nextjs-expert` |
| LoopBack 4 controllers/repositories/models | `loopback4-expert` |
| `infrastructure/`, `cdk/`, `lib/*-stack.ts`, `cdk.json` | `aws-cdk-lambda-ts-expert` |
| `app/_layout.tsx`, `app.config.*`, RN screens, `eas.json` | `expo-rn-expert` |
| `turbo.json`, root `package.json`, workspace plumbing | `bun-monorepo-expert` |
| Firebase Auth wiring, RTK Query codegen config, `generated.ts` consumers | `firebase-rtk-codegen-expert` |
| `*.rs`, `Cargo.toml`, `crates/*` | `rust-aws-lambda-expert` if the project's stacks include `rust-aws-lambda`, else `rust-expert` |
| `*.ts`/`*.js`, `package.json`, Node/Bun/Deno services | `javascript-expert` |
| `*.py`, `pyproject.toml` | `python-expert` |
| IaC (`*.tf`), IAM policies, Lambda/queue/bucket config (non-CDK) | `aws-expert` |
| React components, hooks, UI routes (non-Next.js) | `react-expert` |
| Stage = Tests, OR task subject starts with "Test"/"Add test"/"Cover" | `test-engineer` (pulls fixtures from the matching stack expert if needed) |

This table mirrors the experts shipped in `~/.sdd/agents/` — extend it when you add stacks.

For multi-stack tasks, you coordinate and the specialists execute their slice. When two routing rows could both apply to the same file, prefer the expert named by the project's stack tags (`.specify/stack.yml`); among those, the more specific row wins.

#### Cross-cutting security pass

After steps 4–5 complete on a task, run the `security-reviewer` agent as a follow-up review if the task:

- adds or modifies authentication / authorization
- touches secrets, IAM, KMS, or .env
- parses user input that crosses a trust boundary
- adds an external integration / webhook receiver
- modifies CORS, CSP, or cookie configuration
- adds a new dependency

`security-reviewer` is read-only and returns either `STATUS: clean` or a list of findings. CRITICAL/HIGH findings block: open `T###s1`, `T###s2`, … follow-up tasks in `tasks.md` under the same stage with `Refs:` to the original task and the finding ID, then stop. MEDIUM/LOW findings get logged in the task notes but don't block.

### 4. Implement

- Edit the files named in the task.
- Make the smallest change that satisfies acceptance + AC.
- Don't refactor surrounding code unless the task says to.
- Don't add error handling or fallback paths the plan didn't call for.

### 5. Verify acceptance

Run the acceptance check stated in the task. Examples:

- "unit test added, passes" → write the test, then run the test command.
- "integration test covers AC-001" → write the test, run, confirm AC text matches the assertion.
- "endpoint returns expected JSON" → curl / fetch / use Bash and assert the response.
- "metric visible in CloudWatch" → if the task is post-deploy, mark as "ready, pending deploy" and note in tasks.md.

If acceptance fails, **do not mark the task done**. Diagnose, fix, re-run.

When acceptance passes, **capture the evidence**: the exact command you ran and its key output line. You'll write it into the task in step 6. If the output is long, put the full run in `<spec-dir>/notes/evidence.md` under a `## T###` heading and quote one line in tasks.md.

### 5a. Pre-ship gates (when the task is an opponent or reality-check gate)

Tasks under `## Reality Check` are **not implemented by you** — they're delegated to the agent named in the task's `Agent:` field, which has its own pass/fail semantics. There are two, run in `tasks.md` order: **Opponent** (default CHALLENGED) first, then **Reality-check** (default NEEDS WORK). The opponent's findings get fixed before reality-check confirms evidence.

For **either** gate:

1. **Resolve the agent file.**
   - *Opponent:* the task's `Agent:` field already points at `~/.sdd/agents/opponent.agent.md`.
   - *Reality-check:* resolve in order — (1) the task's `Agent:` field; (2) the project constitution's "Reality-check agent" pin; (3) project-local `<project>/.claude/agents/reality-?check.*\.md` (ask if multiple match); (4) hub default `~/.sdd/agents/reality-check.agent.md` (always exists).
2. **Read the persona file.** It defines the gate's process, fail triggers, and report template. Treat it as the spec for *how the gate runs*; do not reinterpret it.
3. **Assemble the dossier:** full `spec.md`, full `plan.md`, current `tasks.md`, the persona file contents, the worktree path + branch and the diff to read (`git -C $WT diff <base>...HEAD`, where `<base>` is the project's base branch), a pointer to the project root, both constitutions — and, **for reality-check, `notes/opponent.md`**. Add the persona's explicit verdict instruction (opponent → "return CLEARED / CHALLENGED / BLOCKED, default CHALLENGED"; reality-check → "return READY / NEEDS WORK / FAILED, default NEEDS WORK").
   *Umbrella specs:* the dossier carries **every declared repo's** worktree path + diff command (`git -C <wt> diff <that repo's base>...HEAD`, one per repo, from the STATUS Repo matrix), and instructs the gate to judge the repos TOGETHER — contract compatibility between the slices (does the mobile app actually call what the backend shipped?) is precisely what it must challenge. A gate that reviewed only one repo's diff has not run.
4. **Invoke via the Agent tool** with the dossier as the prompt. When the resolved persona is a hub file that's also a registered agent type (`Opponent`, `Reality Checker (hub default)`), use that `subagent_type` — the persona is then its system prompt, which binds harder than prompt text, and its stamped frontmatter already carries the hub's model policy. For project-local personas (e.g. a `.claude/agents/reality-check*.md` override), use `subagent_type=general-purpose` with the persona file's full contents leading the dossier — and if `~/.sdd/models.yml` exists, pass the gate's tiered model (`~/.sdd/scripts/model-policy.sh get reality-check claude model`) as the Agent tool's `model` parameter when it prints an alias (opus/sonnet/haiku), so the override persona doesn't silently run on a weaker model than the gate is configured for. Either way, do not run the checks yourself — the whole point is independence from the implementer.
5. **Persist the report** to `<spec-dir>/notes/opponent.md` or `<spec-dir>/notes/reality-check.md` (create `notes/` if needed): date, verdict, full findings/evidence.
6. **Decide outcome** and update `STATUS.md` (`opponent:` / `reality_check:` = verdict + date):
   - **CLEARED** (opponent) / **READY** (reality-check) → mark the gate task `[x]`; for the opponent, proceed to the reality-check gate; for reality-check, proceed to Ship.
   - **CHALLENGED** (opponent) → leave `[ ]`. Open `T###o1`, `T###o2`, … under Reality Check, one per defect, each citing the AC/REQ it blocks. Fix them as normal tasks, then re-invoke the opponent. Do **not** advance to reality-check until the opponent is CLEARED.
   - **NEEDS WORK** (reality-check) → leave `[ ]`. Open `T###a`, `T###b`, …, one per fix demanded, each with its AC-###. Tell the user, link the report, list the follow-ups. Do not advance to Ship.
   - **FAILED / BLOCKED** (agent couldn't run) → leave `[ ]`, surface the blocker, stop.
7. **Never self-certify.** If the Agent-tool call errors out or returns empty, treat that as FAILED/BLOCKED and stop. Do not write a "looks fine to me" verdict.

### 5b. Ship tasks (PR + rollout)

When the task is the **Open PR** task (acceptance mentions `spec-pr.sh`):

1. Confirm both gates are `[x]` with CLEARED + READY in `STATUS.md`. If not, stop — Ship depends on the gates. (`spec-pr.sh` enforces this too: it exits 4 unless STATUS shows CLEARED + READY. `--force --draft` exists for mid-flight draft PRs only.)
2. Run `~/.sdd/scripts/spec-pr.sh <spec-dir>` from the worktree. It pushes `spec/NNN-slug` and opens a PR to the project's base branch with both gate verdicts in the body, printing the URL.
3. Write the PR URL into `STATUS.md` (`pr:`), set `phase: review`, bump `updated:`, mark the task `[x]`.

*Umbrella specs:* the Ship stage has one PR task per declared repo — run `~/.sdd/scripts/spec-pr.sh --repo <name> <spec-dir>` for each (the spec-wide gates gate them all), write each URL into that repo's **Repo matrix** row, and set `phase: review` once all declared repos have PRs. Merge/deploy follows the plan's rollout order: providers before consumers.

For the **Roll out** task, follow its acceptance (flag flip / deploy / dashboards), then set `STATUS.md` `phase: shipped`.

For the **Retro** task (last in Ship), run `/sdd:retro` — it writes `notes/retro.md`, files cross-project lessons into the hub `knowledge/`, and sets `STATUS.md` `retro: done`. Don't skip it; it's how the next spec starts smarter.

### 6. Mark the task done — checkbox and evidence together, never one without the other

Edit `tasks.md` (in the worktree):

1. Change `- [ ] **T###** ...` to `- [x] **T###** ...`.
2. Append the evidence from step 5 as a task field:
   ```
   - *Evidence:* `bun test api` → 14 passed (2026-07-04)
   ```
   A `[x]` without an *Evidence:* line is an unproven claim — `sdd-analyze.sh` flags it and the reality-check gate treats it as a gap.

Update the frontmatter `updated:` field. Refresh `STATUS.md` **Where things stand** + **Next action** so the next session/tool knows exactly where to resume.

### 7. Propose a commit

Propose a conventional commit message:

```
<type>(<scope>): <subject>

Implements T### of spec NNN-<slug>.

Refs: REQ-###, AC-###
```

Where `<type>` is `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, etc. In single-task mode, don't commit yet — wait for the user to approve; they may want to bundle multiple tasks. (In orchestrated mode the orchestrator commits each passing task on the spec branch — see its definition.)

### 8. Decide next

- If the user asked for a bounded run ("next 3 tasks", "through T007"): loop to step 1 for the next unchecked task until the bound is reached.
- Default: stop after one task, summarize, ask if they want the next one.
- "Do all of them" is **orchestrated mode** (see the mode table) — don't loop single-task mode over a whole spec.

## Grounding rules — non-negotiable

1. **Never write a path, ID, or verdict from memory.** Every file path, task/AC/REQ id, and gate verdict you use must come from a file you read or a command you ran *in this session*. If you can't point at its source, resolve it before using it.
2. **Quote before you act.** Before implementing a task, re-read its *Files:* / *Acceptance:* / *Refs:* lines and the AC text they point to — satisfy exactly that, not your recollection of it.
3. **Unknown → ask or mark, never invent.** If the task/spec don't answer a question the code forces you to answer, ask — or stop and surface it. A silent guess is the failure mode this workflow exists to prevent.
4. **Paste outputs, don't paraphrase.** Acceptance results are the actual command + its key output line — never "tests pass". That's what the *Evidence:* line is.
5. **On contradiction, stop.** If spec, plan, and tasks disagree, don't silently pick one: spec wins; fix the downstream artifact, tell the user, then implement.

## Rules

- **One task per pass by default.** Easier to review, easier to recover from a mistake.
- **Never tick a checkbox without passing acceptance — and never without its *Evidence:* line.** The tick and the evidence are one atomic edit; a green box with no evidence is a promise nobody can audit.
- **Don't expand scope.** If the task says "add field X", don't also rename Y. Add a new task to tasks.md if a sibling change is genuinely required.
- **Update tasks.md every iteration.** It's the live source of truth.
- **If acceptance can't be verified locally** (e.g., requires a deploy or a third-party fixture), say so explicitly. Don't fake-pass.
- **Honor the constitution and overlays.** They constrain how you implement, not just what to plan.
- **Work in the worktree.** After pre-flight, `$WT` is your working root. Never edit code on the `dev` checkout; let the branch carry the change to its PR.
- **Umbrella: right repo, right worktree.** A task's code edits go in its `[repo:<name>]` worktree, full stop — a change that "also needs a tweak" in a sibling repo is a task for that repo, not a cross-worktree edit. The hub spec dir owns tasks.md/STATUS.md; keep the Repo matrix current as branches, worktrees, and PRs appear.
- **Keep STATUS.md current — and short.** Update it at every task/phase transition — it's the cross-tool, cross-session handoff record. A stale STATUS is worse than none. Honor the template's size rule: "Where things stand" ≤ 10 lines, file ≤ ~120 lines; rotate gate-round detail into `notes/history.md` and keep one summary line. A STATUS nobody can skim stops being read.
- **Never run a gate yourself.** Both the opponent and reality-check gates are delegated via the Agent tool. Self-grading defeats the purpose of either.

## Done when

- The named task's checkbox is ticked in `tasks.md`, with its *Evidence:* line.
- Code changes match the task's `Files:` list.
- Acceptance was verified with pasted output (or the impossibility was reported).
- A commit message was proposed (not committed).
- The user has the next-action option.
