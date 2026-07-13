---
name: sdd:implement
description: Spec-driven development phase 4. Execute tasks from tasks.md — one task (or a named T###) per pass by default, orchestrated for --all. Makes the code changes in the spec worktree, runs the acceptance check, ticks the checkbox with evidence, and proposes a conventional commit. Use when the user types /sdd:implement, /sdd:implement T###, or says "start implementing the spec", "do the next task", or similar.
---

# /sdd:implement — Execute the tasks

Phase 4 of the SDD workflow. Reads `tasks.md`, executes the next pending task
(or a named one), and marks it done — evidence and checkbox as one edit.

**Umbrella spec?** If `spec.md` has `repos:` frontmatter, read
`~/.sdd/templates/umbrella-guide.md` §Implement and follow it wherever it
overrides this file. Everything below assumes single-repo.

**Dispatched phase?** If `~/.sdd/scripts/model-policy.sh dispatch implement`
prints a CLI other than the one you are running on, offer the dispatch and
run locally only if the user declines; prints nothing → run here as normal.
Single-repo: `bash ~/.sdd/scripts/spec-dispatch.sh implement <spec-dir>
[--task T### | --all]` (it pre-cuts the worktree, runs that CLI headlessly
inside it, and verifies with `sdd-analyze.sh` + `spec-evidence.sh` on return).
Umbrella: one repo slice at a time — add `--repo <name>` (the run executes
only that repo's `[repo:]` tasks; gate and Ship tasks stay here). The
orchestrated cross-repo `--all` never dispatches — it always runs here.

**Autopilot?** Running under `/sdd:go`: apply the auto-mode contract in
`~/.sdd/skills/sdd-go/SKILL.md` — always orchestrated mode (`--all`) with the
Open-PR stop-point, never ask the user (unknown → `[NEEDS CLARIFICATION: …]`
marker and the chain stops), and where the bounded gate loop says the user
arbitrates from round 3, stop the chain instead — autopilot has no waiver
authority.

## Pre-flight (once per spec)

1. **Read `STATUS.md`** — phase, locked decisions, open questions, existing
   `branch:`/`worktree:`. If STATUS names a live worktree, operate there.
2. **Cut/reuse the worktree** (idempotent):
   `WT="$(~/.sdd/scripts/spec-worktree.sh <spec-dir> | tail -1)"` — branch
   `spec/NNN-slug` from the base branch (`--base` > stack.yml `base_branch:` > `dev`),
   worktree at `<repo>.worktrees/NNN-slug`.
3. **Switch your working root to `$WT`.** All code edits, checkbox flips, and
   STATUS updates happen under `$WT/…`; the live spec dir is
   `$WT/.specify/specs/NNN-slug`. **Worktree guard, before the first edit of
   every session:** `git -C "$WT" rev-parse --abbrev-ref HEAD` must print
   `spec/NNN-slug` — anything else: stop, re-run spec-worktree.sh, don't edit.
   An edit on the wrong checkout is this workflow's most expensive mistake.
   Also check `git -C "$WT" status`: uncommitted changes mean an interrupted
   run — reconcile them against tasks.md (a `[~]` task owns them; finish it
   from what's there) before starting anything new.
4. **Consistency check:** `bash ~/.sdd/scripts/sdd-analyze.sh $WT/.specify/specs/NNN-slug`.
   Errors = broken artifacts; fix them first. Warnings are advisory.
   *Legacy specs* missing the Reality Check stage: copy it from
   `~/.sdd/templates/tasks-template.md`, resolve Gate 2's `Agent:` per the
   `/sdd:tasks` rules, re-run the check.
5. **Update state** (`S=~/.sdd/scripts`): STATUS `phase: implement`,
   `active_tool: claude` (`$S/spec-status.sh set <dir> …`); first run only:
   `$S/spec-status.sh --file spec.md set <dir> status implementing`, same for
   plan.md, and `--file tasks.md … status in-progress`.

## Two execution modes

| User said… | Mode | Behavior |
|---|---|---|
| `/sdd:implement` · `/sdd:implement T###` · "next task" | **single-task** | You run steps 1–8 below for one task. |
| `--all` · "implement the spec" · "do all of them" | **orchestrated** | Hand `tasks.md` to the `sdd-orchestrator` agent via the Agent tool. Prompt contains: `$WT`, the live spec dir path, project root + stack tags, the user's stop-point, both constitution paths. It owns steps 3–8, batches `[P]` tasks, commits per task, runs the gates with one bounded fix round, and reports. Resuming an aborted `--all` run is just `--all` again — it skips `[x]`, reconciles `[~]` against the worktree. |

## Single-task flow

### 1–2. Pick the task; read its context

First unchecked task, or the named `T###` (skip `[x]`; a `[~]` task is yours
to finish from whatever the worktree already has). If the task is **blocked**
(waiting on `[EXTERNAL: …]`, a deploy, or user input), don't dead-end: note the
blocker in STATUS, skip to the next unblocked task, tell the user.

Read: the task block (subject/files/acceptance/verify/refs), the plan section
its *Refs:* point to — **pattern anchors and internal seams especially:
transcribe them, don't re-decide them** — the referenced REQ/AC text, sibling
`[x]` tasks (don't redo), both constitutions, the project's stack overlay(s).

### 3. Route

Gate task (under `## Reality Check` or carrying `Agent:`) → **§5a**. Ship task
→ **§5b**. Otherwise route to the matching stack expert per
**`~/.sdd/templates/stack-routing.md`** (the one shared table — includes
tie-breakers, Tests/Docs rows, and the cross-cutting security pass, whose
trigger list lives in `agents/security-reviewer.md`). After steps 4–5 on a task
matching a security trigger, run `security-reviewer`: CRITICAL/HIGH findings
block — open `T###s<n>` follow-ups under the same stage and stop; MEDIUM/LOW
get follow-ups or a note, no block.

**Model escalation.** When dispatching via the Agent tool and
`~/.sdd/models.yml` exists: for a task marked `[hard]`, for any re-dispatch
after a failed acceptance, and for gate follow-ups (`T###o*`/`T###a*`), pass
`~/.sdd/scripts/model-policy.sh get implement-hard claude model` as the
Agent tool's `model` param when it prints an alias (opus/sonnet/haiku/fable).
Escalate on retry — never repeat a failure at the tier that just produced it.
Prints nothing / no policy → dispatch normally.

### 4. Implement

Edit exactly the files the task names. Smallest change that satisfies
acceptance + AC. No drive-by refactors; no error paths the plan didn't call
for. A genuinely required sibling change = a new task, not scope creep.

### 5. Verify acceptance — run it, don't claim it

Run the acceptance check through **`spec-run.sh`** so the evidence is a captured
run, not a string you typed:

`bash ~/.sdd/scripts/spec-run.sh <spec-dir> T### --key '<line to quote>' -- <command>`

(from `$WT`). The task's ***Verify:* line is the command and the `--key`** —
run it verbatim; don't invent a different check. A `manual: …` Verify is the
hand-tick path in step 6. Legacy tasks without a *Verify:* line: derive the
command from *Acceptance:*, and write the derived command into the task's
*Verify:* line while you're there. It executes the command, records stdout+exit+hash into
`notes/evidence.md`, and **on exit 0 ticks the box with a real evidence line**
(it calls spec-task.sh for you — so skip the tick in step 6 for these). On
non-zero it records the failed run and leaves the box unticked: diagnose, fix,
re-run — never mark done. If the check can't run locally (needs a deploy/
fixture), say so and leave the box unticked or mark "ready, pending deploy" in
the task notes — never fake-pass. Truly manual acceptance (a screenshot, a
dashboard reading) is ticked by hand in step 6, evidence still required.

### 5a. Pre-ship gates (opponent, then reality-check)

Gate tasks are **never run by you** — delegate via the Agent tool. Opponent
(default CHALLENGED) first; reality-check (default NEEDS WORK) second.

1. **Resolve the persona file.** Opponent: the task's `Agent:` field
   (`~/.sdd/agents/opponent.agent.md`). Reality-check, in order: task `Agent:`
   field → project constitution's "Reality-check agent" pin → project-local
   `.claude/agents/reality-?check.*\.md` (ask if several) → hub default
   `~/.sdd/agents/reality-check.agent.md`.
2. **Assemble the dossier — paths, not pasted contents** (the gate reads files
   itself; don't burn the context twice): spec dir path (spec.md / plan.md /
   tasks.md / notes/opponent.md for reality-check), worktree path + branch +
   the exact diff command (`git -C $WT diff <base>...HEAD`), project root,
   both constitution paths, the project's stack tags, and the persona's
   verdict instruction (opponent → "CLEARED / CHALLENGED / BLOCKED, default
   CHALLENGED"; reality-check → "READY / NEEDS WORK / FAILED, default NEEDS
   WORK").
3. **Invoke.** Hub personas are registered agent types — use
   `subagent_type: opponent` / `reality-check` (persona = system prompt, model
   policy pre-stamped). Project-local personas: `subagent_type: general-purpose`
   with the persona file's full contents leading the dossier; if
   `~/.sdd/models.yml` exists, pass
   `~/.sdd/scripts/model-policy.sh get reality-check claude model` as the Agent
   tool's `model` param when it prints an alias (opus/sonnet/haiku/fable).
4. **Persist the returned report** to `<spec-dir>/notes/opponent.md` /
   `notes/reality-check.md` (append as `Round <n>` on re-runs) and record the
   verdict: `spec-status.sh set <dir> opponent "CLEARED (<date>)"` etc.
5. **Outcome.** CLEARED → tick, proceed to reality-check. READY → tick,
   proceed to Ship. CHALLENGED / NEEDS WORK → leave `[ ]`, open one follow-up
   per finding (`T###o<n>` / `T###a<n>`, each citing its AC/REQ), fix as
   normal tasks, re-invoke the gate. **Bounded:** from round 3 the user
   arbitrates (see the opponent's Escalation section); a waiver is the user's
   explicit sign-off recorded in STATUS Decisions — never a softened verdict.
   FAILED / BLOCKED / empty-or-errored Agent call → surface it and stop;
   never self-certify or write "looks fine to me".

### 5b. Ship

**Open PR** task: confirm STATUS shows CLEARED + READY (spec-pr.sh enforces
this too — exit 4; `--force` works only with `--draft`). Run
`~/.sdd/scripts/spec-pr.sh <spec-dir>` from the worktree — it pushes, opens
the PR, and writes `pr:` + `phase: review` into STATUS itself. Tick the task.
From here the PR belongs to **`/sdd:review`** (CI triage, review feedback,
merge, teardown) — tell the user that's the next command.

**Roll out** task (after /sdd:review reports merged): follow its acceptance
(flags/deploy/dashboards, incl. ACs deferred as UNVERIFIABLE), then
`phase: shipped`. **Retro** task: run `/sdd:retro`; don't skip it — it's how
the next spec starts smarter.

### 6. Mark done — tick and evidence are ONE edit

Runnable acceptance is already ticked from step 5 (spec-run.sh did it). Tick by
hand only for **manually-verified** ACs the tooling can't run (screenshot,
dashboard) — evidence is still mandatory:
`bash ~/.sdd/scripts/spec-task.sh done <spec-dir> T### --evidence "<what you observed>"`
— it flips the box, writes the `*Evidence:*` line (+date), refuses evidence-less
ticks on non-gate/non-Ship tasks, and bumps `updated:`. Then refresh STATUS
("Where things stand" / "Next action" — keep it ≤ 10 lines, file ≤ ~120;
rotate gate-round detail into `notes/history.md`). All tasks `[x]` →
`spec-status.sh --file tasks.md set <dir> status complete`.

### 7. Propose a commit (don't run it)

```
<type>(<scope>): <subject>

Implements T### of spec NNN-<slug>.

Refs: REQ-###, AC-###
```

Wait for the user — they may bundle tasks. (Orchestrated mode commits per task.)

### 8. Next

Bounded run ("next 3", "through T007") → loop. Default → stop after one,
summarize, offer the next. "Do all" → that's orchestrated mode, not a loop here.

## Grounding rules — non-negotiable

1. Never write a path, ID, or verdict from memory — only from a file read or command run this session.
2. Re-read the task's *Files:*/*Acceptance:*/*Refs:* and the AC text before implementing — satisfy exactly that.
3. Unknown → ask or surface; a silent guess is the failure mode this workflow exists to prevent.
4. Evidence is a captured run (`spec-run.sh`), never a typed "tests pass".
5. Artifacts disagree → stop; spec wins; fix downstream, tell the user, then implement.

## Rules

- One task per pass by default. Work only in `$WT` after pre-flight.
- Never tick without passing acceptance + evidence. Run it via `spec-run.sh` (captures the real output and ticks atomically); reserve a bare `spec-task.sh done` for manually-verified ACs.
- Never run a gate yourself; never expand a task's scope.
- Honor constitutions and overlays; keep STATUS current and short.
- **Hotfix escape hatch:** a genuine production emergency may bypass SDD —
  fix on a hotfix branch, then backfill: a one-page spec of what changed, a
  retro entry, and follow-up tasks for anything dirty. The bypass is logged,
  never silent.
- **Requirements changed mid-implement?** That's a spec revision: stop,
  update spec.md via `/sdd:specify` against the existing dir (new REQ/AC ids
  APPEND — never renumber shipped ones), let `/sdd:tasks` extend tasks.md,
  and note in STATUS Decisions whether passed gate verdicts are stale.

## Done when

- The task's box is `[x]` with its *Evidence:* line (via spec-task.sh), code
  matches its *Files:*, acceptance verified with pasted output (or the
  impossibility reported), a commit message proposed, and the user has the
  next action.
