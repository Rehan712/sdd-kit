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
authorization is required for round 4+, stop the chain instead — autopilot has no waiver
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
| `--all` · "implement the spec" · "do all of them" | **orchestrated** | Hand `tasks.md` to the `sdd-orchestrator` agent via the Agent tool. Prompt contains: `$WT`, the live spec dir path, project root + stack tags, the user's stop-point, both constitution paths. It owns steps 3–8, batches `[P]` tasks, commits per task, runs the gates with script-enforced round reservations, and reports. Resuming an aborted `--all` run is just `--all` again — it skips `[x]`, reconciles `[~]` against the worktree. |

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

Follow the deterministic protocol below: workers capture exact task Verify with
--from-task --no-tick --summary; the invoker accepts the structured return.
A failed acceptance gets one escalation retry, then stops dispatch.

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
4. **Complete** through spec-gate round --complete after the floor and reservation
   required below. Record the validated verdict in STATUS.
5. **Outcome.** CLEARED → opponent task complete; READY → reality-check complete.
   CHALLENGED / NEEDS WORK → class-wide follow-ups with sibling sweeps and tests,
   a fresh floor and another permitted reservation. BLOCKED / FAILED / empty
   response stops dispatch; never self-certify.

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

Use spec-gate accept as described below for automated and declared manual
proof; it is the only path that ticks an implementation task, and it writes the
*Evidence:* line itself. Gate and Ship administration tasks — the ones with no
*Verify kind:*/*Tests:* family, whose artifact is a gate report or a PR —
retain the legacy bookkeeping path,
`bash ~/.sdd/scripts/spec-task.sh done <spec-dir> T### --evidence "<observed>"`.
Refresh STATUS after acceptance. Mark tasks.md complete only when all tasks are [x].

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
- Only spec-gate accept ticks new-contract implementation tasks after validated proof.
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

- The task's box is `[x]` with its *Evidence:* line (written by the accepting
  script, not by hand), code matches its *Files:*, acceptance verified through
  deterministic acceptance (or the impossibility reported), a commit message proposed, and the user has the
  next action.

## Deterministic implementation and gate protocol

Use the worktree-local scripts when changing the kit itself; otherwise use the
installed scripts. Let S be that scripts directory, SPEC the live spec path.
Read the task verbatim and provide an authoritative brief: exact source revision,
decided anchors/seams, REQ/AC text, required FM/INV tests, Verify and acceptance.
Planning consultation may propose decisions; implementation requests only a
missing slice unless a new decision is required.

1. Finish all source edits in a batch before any acceptance capture. Workers
   never tick tasks. Wait for every editing worker at this batch barrier; no
   new editing batch, commit or source mutation until captures and acceptance
   finish. Refresh historical [x] proof when stale; never reopen implementation
   solely because proof aged.
2. Run `bash "$S/spec-run.sh" "$SPEC" T### --from-task --no-tick --summary`.
   Return the exact Verification-Return block in the shared
   [verification contract](../../templates/verification-contract.md): authentic
   capture IDs, canonical summaries and every required FM/INV-to-test mapping.
   Manual tasks use the declared artifact observation grammar, never a fabricated
   command exit or bare evidence text.
3. The invoker runs `bash "$S/spec-gate.sh" accept "$SPEC" T### "$R"`, with
   `R="$SPEC/notes/verification/returns/T###.txt"`: a return is spec
   bookkeeping, and a stray return.txt in the worktree changes the input
   manifest, so acceptance rejects the fresh capture as stale.
   Only its exit 0 accepts the task. Missing, forged, failed or stale returns
   leave tasks unchanged. On failure allow one escalation retry with the gap
   named and the existing implement-hard policy; a second failure stops
   dispatch. Intentional negative controls are recorded separately from retries.
   Keep full logs on disk; pass bounded summaries and referenced diagnostics.
4. After acceptance/commits at each exact authored stage boundary run
   `bash "$S/spec-gate.sh" checkpoint "$SPEC" "$STAGE"`. Nonzero stops
   next-stage dispatch, including when no stage commands exist but retained
   completed-task coverage fails.
5. Before EACH independent gate invocation run
   `bash "$S/spec-gate.sh" floor "$SPEC"`, then
   `bash "$S/spec-gate.sh" round "$SPEC" "$GATE"`.
   Nonzero from either stops gate dispatch; exit 4 is the round-cap refusal,
   never a report to reinterpret. Pass the granted round, source and floor,
   full spec/task paths, source manifests, prior reports, and staged/dirty/
   untracked diff to the gate. Valid execution can be shared; semantic verdicts
   remain independent. Opponent precedes reality-check; both keep their defaults.
6. Persist the returned report only through
   `bash "$S/spec-gate.sh" round "$SPEC" "$GATE" --complete "$P"`, with
   `P="$SPEC/notes/verification/reports/$GATE.md"` — a report left beside the
   code changes the manifest that the next capture and floor verify.
   Reconcile interrupted reservations explicitly with --reconcile; never reset
   history or infer a review completed. Rounds 1–3 are permitted for EACH gate.
   Round 4+ needs exact-gate/exact-next-round user waiver or accepted spec
   revision, UTC ordered after the prior report, in STATUS Decisions. Autopilot
   cannot authorize itself. A waiver authorizes one invocation, never clearance.
   Validate the entry when it is written with
   `bash "$S/spec-gate.sh" waiver "$SPEC" "$GATE" <round>`: same grammar and
   the same diagnostics as the reservation, reserving nothing and changing no
   state. A waiver that has never been parsed is not an authorization.
7. For CHALLENGED/NEEDS WORK, create follow-ups by stable defect Class with all
   known sites and a sibling sweep/test in the same fix; retain every established
   blocker. Re-review changed, affected and previously unexamined surfaces,
   including unchanged code with a concretely triggered defect. Never narrow
   severity or scope to hit a round/cost target. Keep security-reviewer authority,
   configured models and separate gate roles unchanged.
