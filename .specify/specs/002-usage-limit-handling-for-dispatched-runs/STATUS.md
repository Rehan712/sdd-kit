---
spec: 002-usage-limit-handling-for-dispatched-runs
phase: specify          # specify | plan | tasks | implement | review | shipped | abandoned
active_tool: none       # claude | codex | copilot | none — who currently holds the spec
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

Spec written and accepted (design settled in the 2026-07-19 session discussion;
message formats grounded in the GitHub issues cited in spec §9). Nothing
blocking — next is /sdd:plan.

## Decisions log

Append-only, newest last. Each entry: `date — decision — rationale / who decided`.

- 2026-07-19 — Spec created.
- 2026-07-19 — Accepted directly from the session design discussion — user
  asked to implement the agreed design (park by default, delegate on long
  limits, no action without on_limit opt-in); Rehan712.
- 2026-07-19 — Detection lives in the dispatch wrapper, never the model — a
  limit kills the session's turn before the model can act; session discussion.

## Open questions / blockers

(none)

## Handoff note

Kit changes land in the PUBLIC repo first (this one); port to private follows
the merge (spec CON-005). Limit-message fixtures must come from the cited
issues, not invented phrasings. The scheduler seam must be stubbable via env
override — tests never touch real launchd/cron.

## Next action

`/sdd:plan` (then tasks → implement --all → PR, chained via /sdd:go).
