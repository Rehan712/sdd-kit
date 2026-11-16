---
spec: 004-documentation-site-on-github-pages
phase: tasks          # specify | plan | tasks | implement | review | shipped | abandoned
active_tool: claude       # claude | codex | copilot | cursor | antigravity | none — who currently holds the spec
branch: none            # spec/004-documentation-site-on-github-pages once cut, else none
worktree: none          # absolute path once created, else none
pr: none                # PR URL once opened — spec-pr.sh writes this itself
plan_review: SOUND    # not-run | SOUND | UNSOUND | BLOCKED | WAIVED  (+ date) — /sdd:plan's one-round review
opponent: not-run       # not-run | CHALLENGED | CLEARED | BLOCKED  (+ date)
reality_check: not-run  # not-run | NEEDS WORK | FAILED | READY  (+ date)
ci: not-run             # not-run | pending | green | red  (+ date) — spec-ci.sh writes this
retro: not-run          # not-run | done (+ date) — /sdd:retro after ship
updated: 2026-11-16
---

# STATUS — Documentation site on GitHub Pages

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

Spec and plan accepted; `tasks.md` written — 15 tasks (10 implementation, 2
gates, 3 Ship), `sdd-analyze.sh --phase tasks` consistent with 0 warnings.
Awaiting `/sdd:implement`; the worktree is cut on the first run.

## Decisions log

Append-only, newest last. Each entry: `date — decision — rationale / who decided`.

- 2026-11-16 — Spec created.
- 2026-11-16 — Feasible at $0: `Rehan712/sdd-kit` is public (`gh repo view`), so Pages and Actions are free; no Pages site existed yet (`gh api …/pages` → 404).
- 2026-11-16 — Content is a user guide split from the README; no reference pages — @Rehan712.
- 2026-11-16 — README is trimmed to an entry point; docs own the detail (one source) — @Rehan712.
- 2026-11-16 — Generator: Material for MkDocs — @Rehan712. Its maintenance status is an open question for the plan.
- 2026-11-16 — Success is measured by structural proxies; no analytics — @Rehan712.
- 2026-11-16 — Defaults chosen by Claude, open to override: default `github.io` URL, deploy on merge to `main`, README ≤ 150 lines, English only, no PR previews, no third-party fonts.
- 2026-11-16 — Constitution §5.2 (i18n) read as not applying to prose docs; site language set explicitly instead (CON-007) — Claude, open to override.
- 2026-11-16 — Generator changed to Zensical, pinned 0.1.1 — @Rehan712. Material for MkDocs reaches end of life on 2027-05-05 (its 9.8.1 release notes); Zensical is its authors' successor.
- 2026-11-16 — Spec accepted as written, defaults included — @Rehan712.
- 2026-11-16 — Spec edited during planning: CON-003 (Zensical); AC-008 now proved by the docs check rather than a failing pull-request run, because no PR exists until the gates pass; AC-004 gains a network log, since a file scan cannot see requests made by script; AC-009 and CON-008 reworded to match.
- 2026-11-16 — One script, `tests/docs-check.sh`, is the whole docs check for CI and for a local run, and re-proves on every run that strict mode rejects a broken link — a beta generator must not be able to stop checking silently.
- 2026-11-16 — The check never passes `--clean`: it deletes `<root>/.cache/`, where an installed kit keeps `/sdd:onboard`'s clones (measured; plan review P-002).
- 2026-11-16 — Tests follow the text: every assertion that read `README.md` reads the page that now holds the passage (plan §4.5). For the nine-topic loop the operator document is `docs/workflow.md` plus `docs/verification.md`, read as one.
- 2026-11-16 — `.specify/stack.yml` unchanged: the docs check needs Zensical, so it is not a gate check; `tests/run.sh` stays bash-only.
- 2026-11-16 — No stack expert consulted (`stacks: []` has none); exploration and a Zensical 0.1.1 probe build were done first-hand instead of by scouts.
- 2026-11-16 — Plan review: SOUND, 8 findings (P-001 to P-008), all folded into plan.md, none rejected.
- 2026-11-16 — Plan accepted by the owner's `/sdd:tasks` request; tasks written on the machine-wide (global) model policy, at the owner's request.
- 2026-11-16 — Plan corrected while tasking: readme-coverage exceptions are lines 644 and 662–665 (not 644 and 663); the docs-check tests build a self-contained sandbox kit rather than a `copy_kit`, because the real pages land in a later task.
- 2026-11-16 — Tasks: the workflow sits in an `API` stage because `.specify/stack.yml` names an `API` checkpoint and the analyzer requires every checkpoint stage to exist; stack.yml left unchanged since it is shared by every spec. The eleven pages are one task (T003): the nav needs every page, so a split leaves broken intermediate commits.
- 2026-11-16 — Project model policy added (`.specify/models.yml`): every role on the mid tier — Claude Sonnet 5.5 or Codex GPT-6.1 Terra — at high (design, gates), medium (writing code) or low (recon) effort — @Rehan712, because this spec is mostly mechanical. It applies to every spec in this repository until the file is removed.

## Open questions / blockers

- [x] Generator support status — resolved: Zensical (see Decisions).
- [x] Defaults — accepted by @Rehan712.
- [ ] (@Rehan712) Enable Pages (Settings → Pages → Source: GitHub Actions) before merging the PR — CON-006, plan §8 step 3.
- [ ] (@Rehan712) Commit this spec directory and `.specify/models.yml` on `main` before the spec branch is cut — a spec worktree only sees the model policy if the file is in its checkout (measured).

## Handoff note

The spec directory is untracked, and the checkout is on `feat/knowledge-cues`,
which is already merged (PR #32); there is no local `main`. Commit the spec
directory on `main` before the spec branch is cut. Line numbers in plan.md are
those of `README.md` at `origin/main` `b9814e6`; if `main` has moved the README
since, re-derive them from the headings. Three ACs are `[DEPLOY]` (AC-001,
AC-004, AC-007) and need an owner and a check-back date here once a deploy date
is known. Zensical is not installed locally; the plan's local command runs it
through `uv`.

## Next action

`/sdd:implement T001` (or `/sdd:implement --all`). Commit the spec directory
and `.specify/models.yml` on `main` first.
