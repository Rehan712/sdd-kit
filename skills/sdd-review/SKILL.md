---
name: sdd:review
description: Spec-driven development phase 4.5 — own the PR from open to merged. Watch CI via spec-ci.sh, triage red builds into T###c follow-ups, turn reviewer feedback into T###r follow-ups, apply the re-gate rule, rebase conflicts, merge in contract order, tear down the worktree. Use when the user types /sdd:review, says "check the PR", "CI is red", "handle the review comments", "is it safe to merge", or when a spec sits in phase review.
---

# /sdd:review — Drive the PR home

Owns `phase: review` — everything between `spec-pr.sh` and the Roll out task.
The deterministic half lives in `~/.sdd/scripts/spec-ci.sh` (it writes the
`ci:` STATUS field); your half is judgment: triage, fixes, re-gating, merging.

## Pre-flight

1. Resolve the spec dir (same resolution as `/sdd:implement`); read `STATUS.md`.
   Expect `phase: review` and a `pr:` (umbrella: `pr_<repo>:` per declared repo).
   No PR yet → stop: "run the Ship stage via /sdd:implement first."
2. If STATUS names a worktree, verify it still exists and run the worktree
   guard (`git -C $WT rev-parse --abbrev-ref HEAD` → `spec/NNN-slug`) before
   any edit. Post-PR fixes are commits on the same spec branch, made there.
3. Probe: `bash ~/.sdd/scripts/spec-ci.sh check <spec-dir>` and branch on its
   exit code below. (`watch` blocks until checks settle — use it when the user
   asks you to babysit the PR.)

## Branch on CI state

### exit 20 — checks red

1. `bash ~/.sdd/scripts/spec-ci.sh logs <spec-dir>` → writes + prints `notes/ci.md`.
2. Diagnose each failing check from the logs. For every distinct defect, append
   a follow-up task under the **Ship** stage: `T###c1, T###c2, …` (`###` = the
   Open-PR task's number), each with *Files:*, *Acceptance:* (the failing check
   command, locally re-runnable when possible), and *Refs:* to the AC it blocks.
3. Fix in the worktree (route via `~/.sdd/templates/stack-routing.md`), tick
   each with `spec-task.sh done … --evidence`, commit, **apply the re-gate rule
   below**, then push and re-run `spec-ci.sh watch`.

### exit 30 — changes requested

1. Read the review threads: `gh pr view <url> --comments` (and
   `gh api repos/{owner}/{repo}/pulls/<n>/comments` for line comments).
2. Every actionable comment becomes `T###r1, T###r2, …` under Ship — same
   shape as c-tasks. Non-actionable disagreements: reply on the thread with
   the spec/AC citation; the spec is the arbiter, and changing it is
   `/sdd:specify` territory, not a code push.
3. Fix, evidence, commit, re-gate rule, push, reply to each thread with what
   changed, re-request review (`gh pr edit <url> --add-reviewer <handle>` or
   note it for the user).

### exit 40 — merge conflicts

Rebase the worktree onto the base branch (`git fetch origin && git rebase
origin/<base>`), resolve, `git push --force-with-lease`. A pure rebase (no
manual resolution) needs no re-gate; every manually-resolved hunk counts as a
code change under the re-gate rule.

### exit 10 — pending

Report "checks still running" and either `spec-ci.sh watch` (babysitting) or
hand the next action to the user. Nothing else to do — don't guess at results.

### exit 0 — green, approved, mergeable

1. Confirm both gate verdicts in STATUS are still CLEARED/READY **for the diff
   being merged** (re-gate rule below — a PR whose gates predate its last code
   push has stale verdicts; re-run the opponent before merging).
2. Merge (ask the user first unless they already said "merge when green"):
   `gh pr merge <url> --squash` (or the repo's convention).
   *Umbrella:* merge in the plan's rollout order — **providers before
   consumers** — re-running `spec-ci.sh check --repo <next>` after each merge
   (an earlier merge can break a sibling's base).
3. After the last merge: tear down —
   `bash ~/.sdd/scripts/spec-worktree.sh --remove --delete-branch <spec-dir>`
   (umbrella: `--all-repos`). Then set artifact statuses:
   `spec-status.sh --file spec.md set <spec-dir> status shipped`, same for
   plan.md. `phase:` stays `review` until the **Roll out** task (T012) runs —
   hand back: "merged; next is /sdd:implement T012 (rollout), then /sdd:retro."

## The re-gate rule (stale verdicts are the silent failure here)

Any commit added to the PR after a gate verdict makes that verdict stale for
the delta. Bounded, not paranoid:

- **Mechanical fixes** — lint, formatting, a flaky-test rerun, a missing
  import, comment/doc edits: no re-gate. Note them in STATUS Decisions.
- **Behavioral fixes** — anything that changes what the code does under any
  input (that includes most c-/r-tasks and every manually-resolved conflict):
  re-invoke the **opponent** (per `/sdd:implement` §5a) with the dossier's diff
  scoped to the delta since the last CLEARED round; reality-check re-runs only
  if a fix invalidated an AC's recorded evidence.
- Gate escalation and waivers follow the opponent's Escalation section: from
  round 3 the user arbitrates; a waiver is the user's explicit sign-off
  recorded in STATUS Decisions (`waived by <user> — <reason> — <date>`), never
  a quietly softened verdict.

## Rules

- **The script measures; you decide.** Never hand-parse PR state — trust
  `spec-ci.sh` exit codes; re-run it after every push.
- **Follow-up grammar:** `T###c<n>` CI failures, `T###r<n>` review feedback —
  siblings of `T###o<n>` (opponent) and `T###s<n>` (security). All are normal
  tasks: Files/Acceptance/Refs, evidence on tick.
- **Never merge over a red gate, a stale gate, or with --admin.** The gates
  gate the merge, not just the PR-open.
- **Keep STATUS current**: `spec-ci.sh` owns `ci:`; you own blockers ("waiting
  on review from X"), Decisions entries, and Next action.
- **Abandoning here** (PR closed without merge): set `phase: abandoned`, note
  why in Decisions, tear down with `spec-worktree.sh --remove` (branch stays
  unless the user says delete).

## Done when

- The PR(s) merged in order, worktree(s) torn down, artifact statuses
  `shipped` — or the precise blocker (red check, awaited reviewer, escalated
  gate) is recorded in STATUS with its follow-up tasks opened, and the user
  knows the single next action.
