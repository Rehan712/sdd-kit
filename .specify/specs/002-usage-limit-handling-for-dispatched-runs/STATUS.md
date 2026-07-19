---
spec: 002-usage-limit-handling-for-dispatched-runs
phase: tasks          # specify | plan | tasks | implement | review | shipped | abandoned
active_tool: codex       # claude | codex | copilot | none — who currently holds the spec
branch: none            # spec/002-usage-limit-handling-for-dispatched-runs once cut, else none
worktree: none          # absolute path once created, else none
pr: none                # PR URL once opened — spec-pr.sh writes this itself
opponent: not-run       # not-run | CHALLENGED | CLEARED | BLOCKED  (+ date)
reality_check: not-run  # not-run | NEEDS WORK | FAILED | READY  (+ date)
ci: not-run             # not-run | pending | green | red  (+ date) — spec-ci.sh writes this
retro: not-run          # not-run | done (+ date) — /sdd:retro after ship
updated: 2026-07-19
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

Tasks phase complete: 17 dependency-ordered tasks cover classifier/policy,
resume/scheduler, dispatch, doctor, tests, docs, both gates, and ship; 3 are
parallel-safe and 6 are `[hard]`. All 11 ACs have implementation coverage and
`sdd-analyze.sh` is green. No blockers or clarification markers remain.

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

## Open questions / blockers

(none)

## Handoff note

Kit changes land in the PUBLIC repo first (this one); port to private follows
the merge (spec CON-005). Limit-message fixtures must come from the cited
issues, not invented phrasings. The scheduler seam must be stubbable via env
override — tests never touch real launchd/cron.

## Next action

`/sdd:implement --all` (the spec worktree is cut on the first implement pass).
