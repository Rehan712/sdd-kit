# Repo briefs

One file per repo in `system-map.yml`, named `<repo-name>.md`, from
`templates/brief-template.md`. A brief is the standing "what you need to know
to plan against this repo" summary — what it owns, entry points, contracts,
conventions, gotchas — so `/sdd:specify` and `/sdd:plan` don't re-explore ten
repos from scratch for every umbrella spec.

Lifecycle:

- **Seeded in bulk** by `/sdd:onboard` — fresh installs and newly-added repos.
  Local checkouts resolve via `registry.yml`; repos without one are researched
  from a cached shallow clone of the system map's `remote:` URL
  (`.cache/repos/`, gitignored). Unreachable repos are skipped with a reason,
  never invented.
- **Created** by `/sdd:plan` the first time a spec touches a repo that has no
  brief (from that pass's Explore results — verified facts only).
- **Refreshed** explicitly: `/sdd:onboard --refresh [repo…]` re-researches
  stale (or named) briefs; `/sdd:retro` refreshes the briefs of every repo a
  shipped spec touched. No phase rewrites a brief as a side effect.
- **Freshness is machine-checked**: every brief records
  `**Source:** <branch> @ <sha>` — the commit it described.
  `scripts/brief-status.sh` counts commits behind that branch and flags
  ≥ 20 (configurable `--threshold`) as **stale**; a brief without the line is
  **unknown**. Surfaced by `sdd-doctor.sh`, `sdd-status.sh`, `setup.sh`, and
  a `/sdd:plan` warning — plan never auto-refreshes.
- **Trusted but verified**: a brief is a starting map, not ground truth — the
  kit's grounding rules still require paths to be confirmed in-session before
  they're written into a plan or task.

Briefs are committed — they're team-shared context, like `knowledge/`. The
clone cache is not.
