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
   phase: one fix round, re-run; still failing → stop the chain and report.
4. **Gates at full strength, no waivers.** Run exactly as `/sdd:implement`
   §5a. A waiver is the user's explicit sign-off by definition — so where the
   round controller refuses a fourth or subsequent invocation, autopilot
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
- Umbrella spec → umbrella mode (see above): read
  `~/.sdd/templates/umbrella-guide.md` before phase 3.
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
owns batching, per-task commits, both gates, script-enforced round reservations).
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
