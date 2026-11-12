---
name: sdd:plan
description: Spec-driven development phase 2. Read an existing spec.md and produce plan.md alongside it, pulling in the relevant stack overlays from ~/.sdd/templates/stack-overlays/ and consulting the matching tech-stack subagent(s). Use when the user types /sdd:plan, says "plan this", "how would we build this", or asks for an implementation plan for a spec that already exists.
argument-hint: "[NNN-slug]"
---

# /sdd:plan — Produce an implementation plan

Phase 2 of the SDD workflow. Reads an accepted `spec.md`, designs the
implementation, writes `plan.md` next to it.

**Umbrella spec?** (`repos:` in spec.md frontmatter, lives in `~/.sdd/specs/`)
Read `~/.sdd/templates/umbrella-guide.md` §Plan and follow it wherever it
overrides this file.

**Dispatched phase?** If `~/.sdd/scripts/model-policy.sh dispatch plan` prints
a CLI other than the one you are running on, this phase is configured to run
there — offer `bash ~/.sdd/scripts/spec-dispatch.sh plan <spec-dir>` (headless
run on that CLI; output captured to notes/, artifacts verified on return;
umbrella specs dispatch too — the run is rooted at the hub with declared repos
as read-only context) and run locally only if the user declines. Prints
nothing → run here as normal.

**Autopilot?** Running under `/sdd:go`: apply the auto-mode contract in
`~/.sdd/skills/sdd-go/SKILL.md` — never ask the user (unknown →
`[NEEDS CLARIFICATION: …]` marker and the chain stops), auto-accept the
upstream artifact with a STATUS Decisions line instead of confirming, and
dispatch a mapped phase directly instead of offering it.

## Step-by-step

### 1. Locate the active spec

Named slug/NNN → `<project>/.specify/specs/NNN-*/spec.md`, else the hub's
`~/.sdd/specs/NNN-*/`. Otherwise the most recently modified spec dir in the
resolved project (`ls -t <project>/.specify/specs/ | head -1`) — but skip
specs whose STATUS shows `phase: shipped|abandoned`, and confirm with the user
on any ambiguity. Project root via `~/.sdd/scripts/project-detect.sh`.

### 2. Read the inputs

- `STATUS.md` first — phase, settled decisions (don't relitigate), open questions.
- `spec.md`. If its status is still `draft`, confirm with the user the spec is
  final, then `~/.sdd/scripts/spec-status.sh --file spec.md set <dir> status accepted`.
  Any `[NEEDS CLARIFICATION: …]` markers: resolve with the user BEFORE
  designing; remove each as answered and log it in STATUS Decisions.
- `~/.sdd/constitution.md` + `<project>/.specify/constitution.md` (if present).
- Stack tags: `<project>/.specify/stack.yml`, else the project's registry
  entry. Load `~/.sdd/templates/stack-overlays/<tag>.md` for each.
- **Official skills** — `~/.sdd/templates/official-skills.md`. For each stack
  tag and domain the spec touches (Next.js, AWS, Stripe, UI/UX), load the
  skill the table names when the session lists it — only those — before
  consulting the experts. What a skill settles is written into plan.md as a
  decision, so implementers transcribe it instead of re-deriving it. A
  feature with UI: run `ui-ux-pro-max`'s design-system step once, persist it
  (`design-system/<project>/MASTER.md`), and name that file in plan §6.
- `~/.sdd/knowledge/*.md` — skim for relevance.
- `~/.sdd/briefs/<repo>.md` when it exists. Freshness first:
  `~/.sdd/scripts/brief-status.sh repo <repo>` — on `stale`/`unknown`, warn
  and suggest `/sdd:onboard --refresh <repo>`; never auto-refresh from here.
  A brief is a starting map — grounding rules still require re-verifying paths.

### 3. Consult stack expert(s)

Pick the expert per stack tag from **`~/.sdd/templates/stack-routing.md`**
(§Planning consultation). Multi-stack work: consult each relevant expert **in
parallel** via the Agent tool — each returns its stack's considerations, file
paths, and risks. Don't bypass them even if you "already know"; the agents
encode lessons the overlay doesn't.

### 4. Explore the codebase

Agent tool, `subagent_type: sdd-scout` — the kit's read-only scout, pinned to
the `explore` role's tier by the model policy (no `model` param). One narrow
question per scout, sent in parallel in one message: existing patterns to
reuse, code this change must modify, contracts it must respect, the exact
test/lint/build commands. Don't pre-decide — let exploration inform the
design. `sdd-scout` not registered in this session → `subagent_type: Explore`.

**Scouts locate; you verify.** Scouts run on a cheaper tier —
before a file path, hook point, or "no change needed" claim from a report
becomes part of the design, re-read that code first-hand this session. A
misread inherited into plan.md poisons every downstream phase.

### 5. Draft the plan

Fill `plan.md` from the template — every section, or an explicit "n/a":

1. **Approach** — one paragraph, referencing REQ-###.
2. **Architecture** — components, file paths, what changes where, and a
   **pattern anchor** per component: the existing file the implementer should
   mimic (every NEW file names one, or says explicitly "no precedent").
3. **Data model** — schemas, migrations.
4. **API / contracts** — new/changed endpoints, event payloads, **and the
   internal seams**: pre-decided signatures/types/constants at every task
   boundary, so two implementer sessions never negotiate a function shape.
5. **Dependencies** — packages, AWS resources, IAM.
6. **Stack overlay notes** — per-tag callouts from overlays + experts.
7. **Risks, failure modes and verification** — ranked likelihood × impact,
   concrete FM/INV rows, exclusions and typed test families as described below.
8. **Rollout** — flags, deploy order, observability, how each MET-### gets measured.
9. **Out of scope** — what came up but won't ship here.
10. **References** — ADRs, code paths, links.

Name the files, the IAM actions, the metric names. Vague plans produce vague code.

**Define proof before task numbers.** Read the shared
[`verification contract`](../../templates/verification-contract.md); it owns the
FM/INV table, verification-kind and locator grammar. Define stable FM-### rows
for concrete triggering inputs/sequences and their decided behavior. Turn
always/never promises into INV-### rows naming their scope and every enforcement
site. Share rows across affected components, register typed test families with
intended concrete locators, and record inapplicable component/category pairs
with reasons. Apply the project's stack defaults or explain their exclusion.
Planning needs no future task IDs or existing future test files; task
decomposition binds these families to owning tasks later.

Decide which behavioral tests each implementation component adds or extends
alongside its behavior. Reserve the Tests stage for integration spanning tasks
or stacks; a later integration owner cannot replace local behavioral proof.
Bindings locate tests; independent review still judges their assertions and
attacks covered and omitted scenarios. Choose the project's actual full-suite
and mandatory static `gate_checks` separately from optional stage checkpoints;
checkpoint stage membership waits for real task decomposition.

Run `bash ~/.sdd/scripts/sdd-analyze.sh <spec-dir> --phase plan` before handoff.
Fix errors and authoring warnings in a new plan; do not invent task numbers to
satisfy task-phase checks. Existing legacy warnings remain advisory.

**Write for the implementation tier.** The tasks this plan spawns may be
executed by a cheaper model than you (models.yml `implement:` role). Pre-make
every decision a mid-tier implementer would fumble — names, signatures, edge
cases, the anchor file to copy — and spend no words on what any model already
knows. Calibrate against the golden example:
`~/.sdd/templates/examples/001-api-key-expiry/plan.md` is the bar for anchor
and seam specificity.

### 6. Reconcile with the spec

If planning revealed the spec is wrong or ambiguous, **stop and fix the spec
first**; tell the user what changed and why. Then resume.

### 7. Plan review — one round

A wrong approach or a missing failure mode found now costs a plan edit; found
at the pre-ship opponent gate it costs a re-implementation. So the plan gets
one adversarial read before it leaves this phase — one round, never a loop.

1. Invoke the `opponent` agent (Agent tool, `subagent_type: opponent`; Codex:
   the `sdd-opponent` subagent; no subagents: adopt
   `~/.sdd/agents/opponent.agent.md` as a distinct pass). The dossier is paths
   only: `MODE: plan-review`, the spec dir, the project root, both
   constitutions.
2. Save its report verbatim to `<spec-dir>/notes/plan-review.md`.
3. Act on the verdict (`set` below is
   `~/.sdd/scripts/spec-status.sh set <spec-dir> plan_review <VALUE>`):
   - **SOUND** — fold every finding into the plan now: a failure mode becomes
     an FM/INV row (§7), a seam gets pinned (§4), a code mismatch is fixed
     after you re-read that code, a guess becomes a spec fix (step 6) or a
     `[NEEDS CLARIFICATION]`. A finding you reject gets one STATUS Decisions
     line with the reason. Re-run `sdd-analyze.sh <spec-dir> --phase plan`,
     then `set … SOUND`. Never re-invoke the reviewer to confirm your edits.
   - **UNSOUND** — `set … UNSOUND`, show the user the approach-level finding,
     stop. A reworked plan is a new plan and gets its own single round.
   - **BLOCKED** — `set … BLOCKED`, name the missing piece, stop.
4. Only the user can skip the review: `set … WAIVED` plus a STATUS Decisions
   line quoting them.

`/sdd:tasks` and `sdd-analyze.sh` refuse a plan whose `plan_review` is not
SOUND or WAIVED.

### 8. Update STATUS.md

`phase: plan`, `active_tool: claude`, bump `updated:` (spec-status.sh does the
bump). Append load-bearing architectural calls to the Decisions log with
one-line rationale; refresh Open questions; set Where-things-stand / Next
action → `/sdd:tasks`.

### 9. Hand off

Path to `plan.md`; the plan-review verdict and how many findings were folded
in; 3 bullets (approach, biggest risk, deploy strategy); next:
`/sdd:tasks`.

## Grounding rules — non-negotiable

1. Never write a path, ID, or verdict from memory — only from a file read or command run this session.
2. Re-read the exact artifact lines before acting on them.
3. Unknown → ask or write `[NEEDS CLARIFICATION: <question>]`; never guess silently.
4. Paste real command output, never "it worked".
5. Artifacts disagree → stop, reconcile (spec > plan > tasks), say what changed.

## Rules

- **No code in this phase.** Plan only.
- **Reference REQ-### / AC-### everywhere** — every architectural choice traces to a requirement.
- **Honor the constitution**; surface any conflict explicitly.
- **Don't expand scope** — tempting refactors go to "Out of scope".

## Done when

- `plan.md` exists with all template sections completed (or "n/a").
- STATUS `plan_review` is SOUND or WAIVED — or the phase stopped on UNSOUND /
  BLOCKED and the user has the finding.
- The user has the path, the summary, and the next step.
- Any spec edits made during planning are saved.
