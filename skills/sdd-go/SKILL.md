---
name: sdd:go
description: Spec-driven development autopilot ("yolo mode"). From an existing spec, chain plan → tasks → implement --all → open PR without stopping for human review of plan.md or tasks.md — deterministic validators and both adversarial gates still block. Use when the user types /sdd:go, or says "yolo this spec", "just build it", "go ahead and build the whole spec", "run it end to end, don't check in with me".
argument-hint: "[NNN-slug | <feature description>]"
---

# /sdd:go — Autopilot from spec to PR

One human input — the spec — then the kit drives: plan, tasks, implement (all
tasks), gates, PR. The user trades the human plan/tasks checkpoints for three
hard backstops: `[NEEDS CLARIFICATION]` stops, deterministic validators, and
the two adversarial gates. Merging stays human — the chain ENDS at the open PR.

**What autopilot never skips** (this contract is what makes yolo safe):

- The **specify interview.** A spec born from a one-liner without answers is
  the one failure no downstream gate can catch. No spec yet → run
  `/sdd:specify` normally (interactive), then continue the chain from there.
- The **plan review** — one adversarial round on plan.md (`/sdd:plan` step 7),
  standing in for the human plan checkpoint autopilot removes. UNSOUND or
  BLOCKED stops the chain; autopilot cannot waive it.
- **`sdd-analyze.sh`** after the tasks phase — exit 0 or the chain stops.
- The **opponent and reality-check gates**, at full strength — plus
  `spec-pr.sh`'s refusal to open a non-draft PR without CLEARED + READY.
- **`/sdd:review`.** The chain stops at the PR; merge decisions are interactive.

**Umbrella specs** (`repos:` frontmatter, hub `specs/`) autopilot too — read
`~/.sdd/templates/umbrella-guide.md` first and apply it wherever it overrides
the phase skills. Two deltas vs single-repo: **implement never dispatches**
(contract rule 5 does not apply to umbrella implement — the orchestrator
needs the live repo table, so it always runs here; plan/tasks may still
dispatch, hub-rooted), and the chain ends when EVERY declared repo's PR is
open — `spec-pr.sh --repo` writes each `pr_<name>:` but leaves the phase to
the caller, so set `phase: review` via `spec-status.sh` after the last one.

## Auto-mode contract

Every phase run under `/sdd:go` follows its own SKILL.md **plus these
overrides** (the phase skills' "Autopilot?" blocks point back here):

1. **Never ask the user.** Where a phase skill says "confirm with the user" /
   "resolve with the user" / "ask": if the answer is derivable from files read
   this session, proceed and log it; otherwise write
   `[NEEDS CLARIFICATION: <question>]` where it belongs and **stop the
   chain** — report what is blocking and how to resume (answer the marker,
   then `/sdd:go` again; the chain re-enters at the stopped phase).
2. **Auto-accept upstream artifacts.** Where a phase would confirm
   draft → accepted (spec.md in plan, plan.md in tasks, tasks.md before
   implement), set it via `spec-status.sh` and append a STATUS Decisions line:
   `<date> — <artifact> auto-accepted (/sdd:go autopilot) — user pre-authorized at /sdd:go`.
3. **Validators are hard stops.** `sdd-analyze.sh` errors after the tasks
   phase: one fix round (Claude Code: the tasks phase agent again, handed the
   validator's output — rule 7), re-run; still failing → stop the chain and
   report.
4. **Gates at full strength, no waivers.** Run exactly as `/sdd:implement`
   §5a. A waiver is the user's explicit sign-off by definition — so where the
   round controller refuses a fourth or subsequent invocation, autopilot
   **stops the chain** and lays out the disagreement instead.
5. **Dispatch without the offer.** A phase whose role is mapped to another CLI
   in models.yml `dispatch:` runs there directly via
   `bash ~/.sdd/scripts/spec-dispatch.sh <role> <spec-dir>` (headless +
   artifact-verified by design) — don't pause to offer it. A mapped
   single-repo **implement** runs as the loop instead:
   `bash ~/.sdd/scripts/spec-loop.sh <spec-dir>` — one fresh session per task
   in `spec-graph.sh` order, gates included. Exit 0 = it reached the Ship
   stage: run the "Open PR" task here. Any other exit stops the chain
   (1 = two sessions made no progress, 8 = iteration cap, else the
   dispatcher's own code) — report it; never loop on the loop.
   Those two scripts are the only way a phase leaves this CLI — never a
   harness's own delegation tool: the script takes the model from the policy
   and verifies the artifacts on return. A run that can outlast the
   harness's shell limit (Claude Code stops a background shell at 2 h, and
   the loop usually runs longer) is launched detached, `nohup` with its exit
   code written to a file you wait on; a killed loop resumes by being run
   again.
6. **Every auto-decision is logged.** Autopilot is auditable, not silent:
   Decisions lines for acceptances, markers for unknowns, evidence lines and
   gate reports exactly as in normal mode.
7. **Every phase on its own model.** Claude Code honors a skill's `model:`
   only when the user types its command: a phase skill this chain loads with
   the Skill tool gets the effort and keeps the conductor's model. So on
   Claude Code never load `sdd:plan` or `sdd:tasks` here — run each as a
   **phase agent**, one foreground Agent call (`run_in_background: false`; a
   phase rule 5 sends to another CLI is dispatched instead):
   - `subagent_type: general-purpose`; `model` and `effort` are the outputs
     of
     `~/.sdd/scripts/model-policy.sh --project <project-root> get <phase> claude alias`
     and `… get <phase> claude effort` (umbrella: no `--project` —
     hub-rooted phases stay on the machine policy, as `spec-dispatch.sh`
     keeps them). A lookup that prints nothing → omit that param.
   - The prompt is paths, not content — the phase, the spec dir, the project
     root — and: "You are the <phase> phase agent. Read
     `~/.sdd/skills/sdd-<phase>/SKILL.md` and run that
     phase end to end under the auto-mode contract in
     `~/.sdd/skills/sdd-go/SKILL.md`. Launch the agents it calls for
     yourself, in the foreground. Return the artifact path, any review
     verdict, and any stop with its reason."
   - Its reply is a pointer, not evidence: read STATUS.md and the artifact
     before acting on a verdict or a stop.

   Implement needs none of this — its work already runs in the
   `sdd-orchestrator` agent, on that agent's own stamp. Single-agent CLIs:
   follow the phase's SKILL.md inline.

## Step-by-step

### 1. Resolve the spec + preconditions

- Locate the spec dir like `/sdd:plan` step 1 (named slug/NNN, else the most
  recently modified non-shipped spec; project root via `project-detect.sh`).
- No spec dir and the user gave a feature description → `/sdd:specify` first
  (full interview — never abbreviated), then continue the chain.
- Umbrella spec → umbrella mode (see above): read
  `~/.sdd/templates/umbrella-guide.md` before phase 3.
- `rg -n "NEEDS CLARIFICATION" spec.md` (`grep -n` when `rg` is not installed)
  — any marker → stop and list them;
  a clean spec is autopilot's input requirement.
- Read `STATUS.md`: enter the chain at the phase it shows. Autopilot is
  resumable — `/sdd:go` on a spec mid-implement just continues from there.

### 2. Announce the run — one message, no question

Tell the user in ~4 lines: which phases will run, what gets auto-accepted,
where the chain ends (open PR), and that any `[NEEDS CLARIFICATION]` or gate
deadlock stops it. Then go — the user already gave the go-ahead by invoking
this skill.

### 3. Plan

Run the plan phase exactly as its skill defines, under the auto-mode contract
— Claude Code: as a phase agent (contract rule 7), so it runs on the plan
role's model and effort; single-agent CLIs: follow
`~/.sdd/skills/sdd-plan/SKILL.md` inline.
Spec still `draft` → auto-accept (contract rule 2). When plan.md is written
and its review is SOUND (findings folded in), set it `accepted` with its
Decisions line — this is the human checkpoint yolo removes, so the log entry
is mandatory. UNSOUND or BLOCKED → stop the chain with the finding; do not
rework the approach unasked.

### 4. Tasks

Run the tasks phase the same way — its own phase agent, on the tasks role's
model and effort. Then
`bash ~/.sdd/scripts/sdd-analyze.sh <spec-dir>` must exit 0 (contract
rule 3 — one fix round). Auto-accept tasks.md.

### 5. Implement — all of it

Run `/sdd:implement --all` (orchestrated mode: the `sdd-orchestrator` agent
owns batching, per-task commits, both gates, script-enforced round reservations)
— or, when implement is mapped to another CLI, the loop of contract rule 5.
Stop-point for the orchestrator prompt: **through the Ship stage's "Open PR"
task** — `spec-pr.sh` opens the PR and flips STATUS to `phase: review`.
Roll-out and retro tasks stay unticked; they need a merged PR.

Umbrella: pre-cut every worktree (`spec-worktree.sh --all-repos <spec-dir>`)
and hand the orchestrator the hub spec dir, the repo table, and per-repo
stack tags (umbrella-guide §Implement). Stop-point: through EVERY declared
repo's "Open PR" task (`spec-pr.sh --repo <name>` each) — then set
`phase: review` yourself via `spec-status.sh`.

### 6. Hand off

Report: PR URL (umbrella: one per declared repo), gate verdicts (+ rounds),
tasks done/total, where the evidence lives (`notes/evidence.md`), anything
deferred or stubbed. Next: `/sdd:review` — interactive from here on.

## Grounding rules — non-negotiable

1. Never write a path, ID, or verdict from memory — only from a file read or command run this session.
2. Re-read the exact artifact lines before acting on them.
3. Unknown → `[NEEDS CLARIFICATION: …]` + stop the chain; never guess silently — nobody is watching to catch a guess, which doubles this rule's weight.
4. Paste real command output, never "it worked".
5. Artifacts disagree → stop, reconcile (spec > plan > tasks), log what changed, continue only if no user input was needed.

## Rules

- **Never soften a verdict, never waive a gate.** Autopilot has no waiver
  authority — deadlocks stop the chain (contract rule 4).
- **Never continue past the open PR.** CI triage, review feedback, and the
  merge belong to `/sdd:review`.
- **A stopped chain is a success mode**, not a failure: report the marker or
  deadlock precisely and how to resume.
- **A resume or handoff prompt names roles, never models.** The next session
  may be on another CLI: write "follow the model policy", not "opus/high".
- **One spec per run.** "Yolo all my specs" → run them one at a time,
  completing each chain (or hitting its stop) before the next.

## Done when

- The chain reached the open PR (STATUS `phase: review`, `pr:` set — umbrella:
  `pr_<name>:` for every declared repo) — or stopped at a contract stop with a
  precise report of what's needed to resume.
- Every auto-acceptance has its STATUS Decisions line; no verdict was
  softened; all evidence is captured runs.
- The user has the PR URL (or the stop report) and the next command.

## Deterministic implementation and gate protocol

`/sdd:implement` owns it. Captures, `spec-gate.sh accept`, stage checkpoints,
floors, round reservations and waivers are the section of the same name in
`~/.sdd/skills/sdd-implement/SKILL.md` — in context once step 5 runs that
skill (single-agent CLIs: read it there before the first task). Autopilot
adds nothing to it and removes nothing; contract rule 4 is its only delta.
