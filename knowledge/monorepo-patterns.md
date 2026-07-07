# Monorepo patterns — when, not how

The HOW (layout, workspace protocol, turbo/nx orchestration, tsconfig project
references and their footguns, shared schemas, CI caching, smells) lives in
`templates/stack-overlays/monorepo.md` (+ `bun-monorepo.md` for Bun
specifics) — one source of truth; don't restate it here. This file keeps the
judgment calls an overlay can't make for you.

## When a monorepo helps

- Multiple deployables that share types, schemas, or UI primitives.
- A single team that owns end-to-end (frontend + backend + infra).
- Atomic cross-service refactors (rename a field once, fix all callers in the same PR).

## When it hurts

- Independent release cadence for unrelated apps.
- Different sets of contributors per app, with conflicting tooling preferences.
- CI minutes blow up because every PR runs everything (mitigate with affected-package detection).

## When to split a package out

- It's published to a public registry.
- It has external contributors with independent cadence.
- It's depended on by a non-monorepo consumer that can't pull from the monorepo.

Otherwise: stay in. The merge tax is usually less than the coordination tax.

## Placement judgment (learned in production)

- Don't put infrastructure in `apps/<name>/infra` for new monorepos — it pulls
  infra reviews into application PRs.
- Code outside `rootDir` (e.g. `test/` beside `src/`) silently breaks `tsc`
  for packages CI doesn't cover — exclude it or put the package in CI.
  (learned the hard way in production)
