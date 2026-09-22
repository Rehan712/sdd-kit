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
   Open-PR task's number). Follow-ups change behavior, so they are ordinary
   implementation tasks and the Ship exemption does not reach them; an untyped
   one can be neither captured nor accepted. Give each: *Files:*, *Acceptance:*
   (the failing check command, locally re-runnable when possible),
   *Verify kind:*, *Tests:* (a locator registered in plan §7 — extend that
   registry if the fix genuinely needs a new family), *Verify:* (the executable
   command), and *Refs:* to the AC it blocks plus the FM/INV rows it covers.
3. Fix in the worktree (route via `~/.sdd/templates/stack-routing.md`), accept
   each structured no-tick return with `spec-gate.sh accept`, commit, **apply the re-gate rule
   below**, then push and re-run `spec-ci.sh watch`.

### exit 30 — changes requested

1. Read the review threads: `gh pr view <url> --comments` (and
   `gh api repos/{owner}/{repo}/pulls/<n>/comments` for line comments).
2. Every actionable comment becomes `T###r1, T###r2, …` under Ship — same
   full typed shape as c-tasks, including *Verify kind:*, *Tests:* and *Verify:*;
   a three-field task cannot produce a `--from-task` capture. Non-actionable disagreements: reply on the thread with
   the spec/AC citation; the spec is the arbiter, and changing it is
   `/sdd:specify` territory, not a code push.
3. Fix, accept each structured no-tick return with `spec-gate.sh accept`,
   commit, re-gate rule, push, reply to each thread with what
   changed, re-request review (`gh pr edit <url> --add-reviewer <handle>` or
   note it for the user).

### exit 40 — merge conflicts

Rebase the worktree onto the base branch (`git fetch origin && git rebase
origin/<base>`), resolve, `git push --force-with-lease`. Validate current proof after rebasing; every manually-resolved hunk counts as a
semantic change under the re-gate rule.

### exit 10 — pending

Report "checks still running" and either `spec-ci.sh watch` (babysitting) or
hand the next action to the user. Nothing else to do — don't guess at results.

### exit 3 — state unreadable (not a CI verdict)

No PR recorded in STATUS (Ship stage hasn't run — point back to
`/sdd:implement`), `gh` missing/unauthenticated (`gh auth status`; the user
runs `gh auth login`), or a recorded PR that can't be read. Fix the tooling
gap or hand it to the user — never infer PR state some other way; the script
is the only reader (constitution §10.6).

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

After any semantic input change, refresh the deterministic floor and obtain new
gate reservations before relying on clearance. Bookkeeping-only edits can retain
current source identity, but never skip artifact integrity checks. Opponent scope
covers changed, affected and previously unexamined surfaces, including unchanged
code with a reproduced defect. Reality-check includes every AC and carries only
runtime-validated unchanged PASS rows. Neither gate is delta-only. A pure rebase
also requires proof identity validation; commit IDs alone do not decide freshness.
Follow the protocol below, including exact-round authorization and refusal handling.

## Rules

- **The script measures; you decide.** Never hand-parse PR state — trust
  `spec-ci.sh` exit codes; re-run it after every push.
- **Follow-up grammar:** `T###c<n>` CI failures, `T###r<n>` review feedback —
  siblings of `T###o<n>` (opponent) and `T###s<n>` (security). All are normal
  implementation tasks and none inherits the Gate/Ship exemption: they carry
  Files/Acceptance/Verify kind/Tests/Verify/Refs, and deterministic acceptance
  on tick.
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
