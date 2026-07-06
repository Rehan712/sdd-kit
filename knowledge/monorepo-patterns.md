# Monorepo patterns

Lessons from running Bun and pnpm monorepos in production.

## When a monorepo helps

- Multiple deployables that share types, schemas, or UI primitives.
- A single team that owns end-to-end (frontend + backend + infra).
- Atomic cross-service refactors (rename a field once, fix all callers in the same PR).

## When it hurts

- Independent release cadence for unrelated apps.
- Different sets of contributors per app, with conflicting tooling preferences.
- CI minutes blow up because every PR runs everything (mitigate with affected-package detection).

## Layout

```
apps/<name>            # runnable applications (web, mobile, lambda services)
services/<name>        # backend services (often one Lambda each)
packages/<name>        # shared libraries
infrastructure/        # CDK or Terraform
docs/                  # repo-wide docs
```

- Don't mix application code into `packages/`. Apps depend on packages; packages don't depend on apps.
- Don't put infrastructure in `apps/<name>/infra` for new monorepos — it pulls infra reviews into application PRs.

## Dependency hygiene

- **One version of each external dep** across the repo. Use `pnpm`'s `overrides` or Bun's `resolutions` to enforce.
- **No package depends on another via relative path** (`../../other-pkg`). Use the workspace name (`@org/other-pkg`).
- **`workspace:*`** in package.json deps; never a pinned version for in-repo packages.

## Build orchestration

- **Turbo** (`turbo.json`) for caching and pipeline. Define `pipeline.build.dependsOn = ["^build"]`.
- Use `--filter=...[origin/main]` in CI to only build changed packages.
- Persistent dev tasks: `"dev": { "cache": false, "persistent": true }`.

## TypeScript project references

- Root `tsconfig.base.json` with strict settings; per-package `tsconfig.json` extends and sets `composite: true`.
- Each package lists workspace deps in `references`.
- Incremental builds (`tsc -b`) become tractable; cold full builds are tolerable.
- **Footgun:** a package that imports a workspace dep but omits it from `references`
  often builds locally (stale `.tsbuildinfo`, loose editor resolution) and fails on CI
  or a fresh checkout. Treat "imports it ⇒ references it" as a lint rule.
- **Footgun:** code outside `rootDir` (e.g. `test/` beside `src/`) silently breaks
  `tsc` for packages CI doesn't cover — exclude it in `tsconfig.json` or put the
  package in CI. (learned the hard way in production)

## CI

- Cache: lockfile-hashed `node_modules` and `~/.bun/install/cache` (Bun) or `~/.local/share/pnpm/store` (pnpm).
- Parallelize: per-affected-package matrix.
- Always run `lint + typecheck + test + build` in a single workflow that fails fast.

## Shared types pattern

- `packages/types` exports plain TypeScript types.
- `packages/schemas` exports runtime validators (zod) that double as type sources via `z.infer`.
- API contracts: either generate from OpenAPI (preferred when the backend is the source of truth) or hand-write zod (when the frontend drives).

## Common smells

- A package that depends on everything (becomes a god-package; refactor into smaller cohesive units).
- Cyclic workspace deps (A → B → A). Catch with `madge --circular`.
- Per-package devDependencies that are actually used by the root (move to root devDependencies).
- One package re-exports another's types and adds nothing — delete the re-exporter.

## When to split out

Signs a package should leave the monorepo:

- It's published to a public registry.
- It has external contributors with independent cadence.
- It's depended on by a non-monorepo consumer that can't pull from the monorepo.

Otherwise: stay in. The merge tax is usually less than the coordination tax.
