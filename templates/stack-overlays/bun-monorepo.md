# Stack overlay: Bun monorepo

Read alongside `plan.md` when `stack.yml` includes `bun-monorepo`.

## Workspace structure

- `apps/<name>` — runnable applications (Next.js web, RN mobile, Lambda services).
- `services/<name>` — backend services (often Lambdas; one per directory).
- `packages/<name>` — shared libraries (UI, utils, types, schemas).
- `infrastructure/` — CDK or Terraform (kept out of `apps/`).

## Bun specifics

- **`bun install`** is the canonical install command. No `bun install --no-cache` workarounds in scripts.
- **Workspace deps:** `"workspace:*"` in package.json (or `"workspace:^"` for looser pinning).
- **`bun.lockb`** is committed; conflicts on it are resolved by rerunning `bun install`.
- **Scripts:** prefer `bun run <script>` so the workspace context is preserved. `bun <script>` works too.

## Build orchestration

- **Turbo** (`turbo.json`) for build/test pipelines across packages — caches across runs and CI.
- Define `pipeline.build.dependsOn = ["^build"]` so dependent packages build first.
- Use `--filter=<pkg>` to scope: `turbo run build --filter=@org/web`.

## TypeScript

- One root `tsconfig.base.json`; per-package `tsconfig.json` extends and sets `composite: true`.
- Project references for incremental builds: each package lists its workspace deps in `references`.
- Path aliases at the root (`paths` in `tsconfig.base.json`); avoid per-package aliases that diverge.

## Sharing types

- Types defined in `packages/types`; everything else imports from there.
- API contracts: define once (zod schemas or LB4 `@model`), infer types, share via `packages/types` or `packages/api-contracts`.

## Running

- Dev: `bun run dev` at the workspace root, ideally proxied through turbo to watch all packages.
- Single app: `bun run dev --filter=@org/web` (turbo) or `cd apps/web && bun run dev`.

## Pitfalls

- **pnpm interop:** if any package needs pnpm (some tooling assumes it), document it in the project's CLAUDE.md and don't mix package managers in the same install.
- **Hoisting surprises:** Bun hoists aggressively. If a package's `import` resolves to a hoisted version you didn't pin, lock it explicitly.
- **Node-only packages** that don't run on Bun: check before pinning. Most things work; some native modules don't.
- **Workspace cycle:** package A imports package B which imports package A → builds work in dev (TS), fail in production bundles. Catch with `madge` or a lint rule.

## CI

- Cache `~/.bun/install/cache` and `node_modules` per lockfile hash.
- `turbo run lint test build --filter=...[origin/main]` to only run on changed packages.
