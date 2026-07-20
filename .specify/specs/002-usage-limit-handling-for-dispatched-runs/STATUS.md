---
spec: 002-usage-limit-handling-for-dispatched-runs
phase: implement          # specify | plan | tasks | implement | review | shipped | abandoned
active_tool: claude       # claude | codex | copilot | none — who currently holds the spec
branch: spec/002-usage-limit-handling-for-dispatched-runs            # spec/002-usage-limit-handling-for-dispatched-runs once cut, else none
worktree: /Users/babar/projects/sdd-kit-public.worktrees/002-usage-limit-handling-for-dispatched-runs          # absolute path once created, else none
pr: none                # PR URL once opened — spec-pr.sh writes this itself
opponent: CLEARED (2026-07-20, Round 5)       # not-run | CHALLENGED | CLEARED | BLOCKED  (+ date)
reality_check: READY (2026-07-20)  # not-run | NEEDS WORK | FAILED | READY  (+ date)
ci: not-run             # not-run | pending | green | red  (+ date) — spec-ci.sh writes this
retro: not-run          # not-run | done (+ date) — /sdd:retro after ship
updated: 2026-07-20
---

# STATUS — Usage limit handling for dispatched runs

> The living memory of this spec. **Every tool — Claude, Codex, Copilot — reads this
> on entry and updates it on exit.** It is the handoff record across tools and sessions.
> Keep it short: state and decisions, not narrative. `tasks.md` owns the checklist;
> this file owns the *why*, the *where* (branch/worktree/PR), and *what's next*.
> Scripts mutate frontmatter via `~/.sdd/scripts/spec-status.sh set` — use it too;
> it validates enum values and bumps `updated:` for you.
> Abandoning a spec: set `phase: abandoned`, note why in Decisions, then
> `spec-worktree.sh --remove --delete-branch <spec-dir>` to clean up.
>
> **Hard size rule:** "Where things stand" stays ≤ 10 lines and this file ≤ ~120 lines.
> When a gate round or session log outgrows that, move the detail to `notes/history.md`
> (append-only) and keep ONE summary line here. A STATUS nobody can skim is a STATUS
> nobody reads — frontmatter fields stay one line each (the dashboard parses them).

## Where things stand

All implementation and gate-follow-up tasks (T001–T012, T013o1–o6) are
evidenced and committed. Opponent CLEARED (Round 5, after 6 fixed findings);
reality-check READY (all 11 ACs re-run). Ship: open the PR (T015). Rollout
(T016) and retro (T017) wait for the merge.

## Decisions log

Append-only, newest last. Each entry: `date — decision — rationale / who decided`.

- 2026-07-19 — Spec created.
- 2026-07-19 — Accepted directly from the session design discussion — user
  asked to implement the agreed design (park by default, delegate on long
  limits, no action without on_limit opt-in); Rehan712.
- 2026-07-19 — Detection lives in the dispatch wrapper, never the model — a
  limit kills the session's turn before the model can act; session discussion.
- 2026-07-19 — models.yml codex model IDs were transposed (gpt-sol-5.6 /
  gpt-terra-5.6); first plan dispatch died on account 400s. Fixed to
  gpt-5.6-sol / gpt-5.6-terra via model-policy.sh after verifying both IDs
  with codex exec probes — /sdd:go autopilot.
- 2026-07-19 — `plan.md` auto-accepted (`/sdd:go` autopilot) — user
  pre-authorized the removed plan checkpoint at `/sdd:go`.
- 2026-07-19 — Absent `on_limit:` remains inert; a present block defaults to
  short=park, long=delegate, fallback=[], backoff=60m — preserves explicit
  opt-in while making long-window failover the configured happy path.
- 2026-07-19 — Resume units persist cwd + NUL-delimited original argv under the
  machine state root, use deterministic ids, 0–300s jitter, and three replay
  attempts — byte-identical replay with bounded retries and no `eval`.
- 2026-07-19 — Provider failures use one table-driven classifier and exit 7;
  fallbacks stay in one dispatch loop and rejoin the existing verifier —
  classification/delegation cannot weaken artifact checks or reach gates.
- 2026-07-20 — `tasks.md` auto-accepted (`/sdd:go` autopilot) — user
  pre-authorized the removed tasks checkpoint at `/sdd:go`; sdd-analyze
  passed (17 tasks, 11/11 ACs covered, both gates present).

- 2026-07-20 — Implementation commits reconstructed by the conducting session — the dispatched Codex sandbox denied git index-lock writes in the worktree, so per-task commits were impossible; per-task provenance lives in tasks.md evidence lines + notes/evidence.md (retro item: dispatch sandbox git access).

- 2026-07-20 — Chain stopped at opponent Round-3 arbitration per /sdd:go contract rule 4 (autopilot has no waiver authority) — T013o3 pending the user's decision: rework cancel-path lock handling or signed waiver.

- 2026-07-20 — Round-3 arbitration: user chose fix + audit. Audit of all four scheduler-call sites in spec-resume.sh: park/add and run/remove already release the lock on failure; list holds no lock; cancel/remove was the only remaining defect — fixed (T013o3) with recovery test. Opponent re-gate authorized as Round 4.

- 2026-07-20 — Opponent Round 4 CHALLENGED with three new findings; proceeded under the user's Round-3 arbitration precedent (fix, never waive) and standing continue instruction: T013o4 park-time PATH capture/replay (launchd/cron fire with stock PATH), T013o5 structural EXIT-trap lock release (the class-level fix the gate asked for), T013o6 minute-less weekly/model-bucket clocks. Round 5 is the bound — a new challenge there stops for the user.

## Open questions / blockers

(none)

## Handoff note

Kit changes land in the PUBLIC repo first (this one); port to private follows
the merge (spec CON-005). Limit-message fixtures must come from the cited
issues, not invented phrasings. The scheduler seam must be stubbable via env
override — tests never touch real launchd/cron.

## Next action

`/sdd:review` — CI triage, review feedback, merge, worktree teardown.
