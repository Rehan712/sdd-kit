---
name: sdd:go
description: Spec-driven development autopilot ("yolo mode"). From an existing spec, chain plan → tasks → implement --all → open PR without stopping for human review of plan.md or tasks.md — deterministic validators and both adversarial gates still block. Use when the user types /sdd:go, or says "yolo this spec", "just build it", "go ahead and build the whole spec", "run it end to end, don't check in with me".
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
- **`sdd-analyze.sh`** after the tasks phase — exit 0 or the chain stops.
- The **opponent and reality-check gates**, at full strength — plus
  `spec-pr.sh`'s refusal to open a non-draft PR without CLEARED + READY.
- **`/sdd:review`.** The chain stops at the PR; merge decisions are interactive.

**Refuse to autopilot:** umbrella specs (`repos:` frontmatter) — their phases
are interactive by design and multi-repo blast radius needs a human on the
loop. Run their phases individually instead.

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
   phase: one fix round, re-run; still failing → stop the chain and report.
4. **Gates at full strength, no waivers.** Run exactly as `/sdd:implement`
   §5a. A waiver is the user's explicit sign-off by definition — so where the
   bounded gate loop says "from round 3 the user arbitrates", autopilot
   **stops the chain** and lays out the disagreement instead.
5. **Dispatch without the offer.** A phase whose role is mapped to another CLI
   in models.yml `dispatch:` runs there directly via
   `bash ~/.sdd/scripts/spec-dispatch.sh <role> <spec-dir>` (headless +
   artifact-verified by design) — don't pause to offer it.
6. **Every auto-decision is logged.** Autopilot is auditable, not silent:
   Decisions lines for acceptances, markers for unknowns, evidence lines and
   gate reports exactly as in normal mode.

## Step-by-step

### 1. Resolve the spec + preconditions

- Locate the spec dir like `/sdd:plan` step 1 (named slug/NNN, else the most
  recently modified non-shipped spec; project root via `project-detect.sh`).
- No spec dir and the user gave a feature description → `/sdd:specify` first
  (full interview — never abbreviated), then continue the chain.
- Umbrella spec → refuse (see above), name the per-phase commands instead.
- `grep -n "NEEDS CLARIFICATION" spec.md` — any marker → stop and list them;
  a clean spec is autopilot's input requirement.
- Read `STATUS.md`: enter the chain at the phase it shows. Autopilot is
  resumable — `/sdd:go` on a spec mid-implement just continues from there.

### 2. Announce the run — one message, no question

Tell the user in ~4 lines: which phases will run, what gets auto-accepted,
where the chain ends (open PR), and that any `[NEEDS CLARIFICATION]` or gate
deadlock stops it. Then go — the user already gave the go-ahead by invoking
this skill.

### 3. Plan

Run the plan phase exactly as its skill defines (Claude Code: invoke the
`sdd:plan` skill via the Skill tool; single-agent CLIs: follow
`~/.sdd/skills/sdd-plan/SKILL.md` inline) under the auto-mode contract.
Spec still `draft` → auto-accept (contract rule 2). When plan.md is written,
set it `accepted` immediately with its Decisions line — this is the human
checkpoint yolo removes, so the log entry is mandatory.

### 4. Tasks

Run the tasks phase the same way. Then
`bash ~/.sdd/scripts/sdd-analyze.sh <spec-dir>` must exit 0 (contract
rule 3 — one fix round). Auto-accept tasks.md.

### 5. Implement — all of it

Run `/sdd:implement --all` (orchestrated mode: the `sdd-orchestrator` agent
owns batching, per-task commits, both gates, the bounded fix round).
Stop-point for the orchestrator prompt: **through the Ship stage's "Open PR"
task** — `spec-pr.sh` opens the PR and flips STATUS to `phase: review`.
Roll-out and retro tasks stay unticked; they need a merged PR.

### 6. Hand off

Report: PR URL, gate verdicts (+ rounds), tasks done/total, where the
evidence lives (`notes/evidence.md`), anything deferred or stubbed. Next:
`/sdd:review` — interactive from here on.

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
- **One spec per run.** "Yolo all my specs" → run them one at a time,
  completing each chain (or hitting its stop) before the next.

## Done when

- The chain reached the open PR (STATUS `phase: review`, `pr:` set) — or
  stopped at a contract stop with a precise report of what's needed to resume.
- Every auto-acceptance has its STATUS Decisions line; no verdict was
  softened; all evidence is captured runs.
- The user has the PR URL (or the stop report) and the next command.
