# Umbrella specs (multi-repo features)

One directory per cross-repo feature: `NNN-slug/{spec.md,plan.md,tasks.md,STATUS.md,notes/}`,
created by `scripts/new-spec.sh --multi --repos a,b,c "<title>"`.

A feature that lands in ONE repo keeps its spec in that repo's
`.specify/specs/` (constitution §1.5). A feature that spans repos gets ONE
spec here instead — the hub is the team-shared repo, so the spec travels to
everyone, while each declared repo still carries its own `spec/NNN-slug`
branch, worktree, and PR.

What's different from a single-repo spec:

- `spec.md` carries `repos: [a, b, c]` frontmatter; ACs are tagged with the
  repo that proves them (`[repo:<name>]`).
- `tasks.md` tags every implementation task `[repo:<name>]`; ordering is
  contract-first (contracts → infra → providers → consumers).
- `STATUS.md` has a **Repo matrix** — branch/worktree/PR per repo. Gates stay
  spec-wide in the frontmatter and block every repo's PR.
- Worktrees: `scripts/spec-worktree.sh --repo <name> <spec-dir>` (or `--all-repos`).
- PRs: `scripts/spec-pr.sh --repo <name> <spec-dir>`, once per repo.
- Dependencies on other teams' repos never become tasks — they're recorded as
  `[EXTERNAL: <team/repo> — <what> — needed-by <date>]` in the spec and
  mirrored in STATUS blockers (`sdd-analyze.sh` checks the mirror).

The repo topology these specs plan against lives in `../system-map.yml`;
standing per-repo context lives in `../briefs/`.
