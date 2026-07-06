# Stack overlay: Monorepo

Read alongside `plan.md` when the project is a workspace monorepo (bun / pnpm / yarn workspaces).

## Workspace layout

```
package.json           # private: true, workspaces: ["apps/*", "services/*", "packages/*"]
apps/<name>/           # deployable frontends
services/<name>/       # deployable backends
packages/<name>/       # shared libraries: types, schemas, config, ui
turbo.json | nx.json | Makefile   # task orchestration
```

- Dependency direction: apps/services → packages. Packages never import from apps or services; no package-to-package cycles.
- Each workspace has its own `package.json` with an accurate name (`@<scope>/<name>`) and declared deps — no phantom imports that only resolve via hoisting.

## Dependency discipline

- **One version of each external dep across the workspace.** Duplicate versions cause type mismatches and double bundles. Enforce with `pnpm dedupe --check`, syncpack, or a version-catalog; upgrades happen workspace-wide.
- **Internal deps use the workspace protocol** (`"@scope/pkg": "workspace:*"`) so they always resolve locally and publish with real versions.
- One lockfile at the root, frozen in CI. Per-package lockfiles are a bug.

## Task orchestration

- All tasks run through the orchestrator (turbo/nx/make) — never `cd packages/x && npm run build` in CI.
- Declare task dependencies (`"build": { "dependsOn": ["^build"] }`) so packages build before their consumers.
- Declare `outputs` for every cacheable task; wrong or missing outputs mean stale artifacts or zero cache hits.

## TypeScript project references footguns

- **Imports-it-implies-references-it:** if package A imports package B, A's `tsconfig.json` must list B in `references`, and B needs `composite: true`. A missing reference "works" in the editor and fails (or silently uses stale `.d.ts`) in CI.
- **Code outside `rootDir` breaks uncovered packages:** importing a file that no package's tsconfig covers (a stray root-level `shared.ts`, reaching into another package's `src/` instead of its build output) produces TS6059/TS6307 errors far from the cause. Every source file belongs to exactly one package.
- Import other packages by name (`@scope/pkg`), never by relative path across package boundaries (`../../packages/x/src/...`).
- Use a shared `tsconfig.base.json`; run `tsc --build` at the root to verify the reference graph.

## Shared types / schemas pattern

- One `packages/schemas` (zod or equivalent) as the source of truth for cross-boundary contracts; types derive via `z.infer`. API and clients both import it — no hand-copied interfaces drifting apart.
- Shared config (eslint, tsconfig, prettier) lives in `packages/config-*` and is extended, not copied.

## CI caching

- Cache by lockfile hash plus the orchestrator's remote/task cache; run only what changed (`turbo run build --filter=...[origin/main]`, `nx affected`).
- Cache keys must include the tool versions (node/bun/pnpm) or you'll restore incompatible artifacts.

## Common pitfalls / smells

- Two versions of the same framework in the tree (classic: two Reacts → hooks explode at runtime).
- A "shared" package that imports from an app — the dependency arrow is backwards.
- Phantom dependencies: code imports a package only hoisting made visible.
- `packages/utils` as a junk drawer with no owner and infinite dependents.
- CI green while a downstream package is broken because the task graph didn't declare the dependency.
