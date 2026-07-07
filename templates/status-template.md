---
spec: NNN-slug
phase: specify          # specify | plan | tasks | implement | review | shipped | abandoned
active_tool: none       # claude | codex | copilot | none — who currently holds the spec
branch: none            # spec/NNN-slug once cut, else none
worktree: none          # absolute path once created, else none
pr: none                # PR URL once opened — spec-pr.sh writes this itself
opponent: not-run       # not-run | CHALLENGED | CLEARED | BLOCKED  (+ date)
reality_check: not-run  # not-run | NEEDS WORK | FAILED | READY  (+ date)
ci: not-run             # not-run | pending | green | red  (+ date) — spec-ci.sh writes this
retro: not-run          # not-run | done (+ date) — /sdd:retro after ship
updated: YYYY-MM-DD
---

# STATUS — <Spec Title>

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

One or two sentences: what phase we're in, what just happened, what (if anything) is blocking.

## Decisions log

Append-only, newest last. Each entry: `date — decision — rationale / who decided`.

- YYYY-MM-DD — Spec created.

## Open questions / blockers

- [ ] <question that blocks progress, and who can answer it>

## Handoff note

For the next tool/session picking this up: what to do first, what to avoid, any
uncommitted state, which checkout to work in (the worktree, once it exists).

## Next action

The single next command or task. e.g. `/sdd:plan`, `/sdd:implement T004`,
or "re-run gate after T010a/b are `[x]`".
