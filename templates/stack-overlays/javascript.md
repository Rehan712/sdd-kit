# Stack overlay: JavaScript / TypeScript

Read alongside `plan.md` when the project's stack includes `javascript` (or `typescript`).

## Conventions

- **Runtime:** Node 20+ or Bun, pinned via `engines` and `.nvmrc` / `.tool-versions`.
- **ESM-first:** `"type": "module"`, `import`/`export` everywhere. CommonJS only for documented interop, never in new modules.
- **TypeScript strict:** `"strict": true` + `noUncheckedIndexedAccess`. No `any` — use `unknown` and narrow. Prefer `satisfies` for checked-but-not-widened values. Variants are discriminated unions with a literal tag, not optional-field soup.
- **Boundaries:** zod schemas for every untrusted input (HTTP bodies, env, queue messages). Static types via `z.infer` — never a hand-maintained twin interface.
- **One package manager**, one committed lockfile, frozen installs in CI (`npm ci` / `pnpm install --frozen-lockfile` / `bun install --frozen-lockfile`).
- **ESLint + Prettier** in CI at zero warnings. `no-floating-promises` and `no-misused-promises` enabled and never disabled file-wide.

## Project layout

```
package.json          # engines, type: module, exports map for libraries
tsconfig.json         # strict; noEmit for app typechecking
src/
  index.ts            # entry / public surface
  <feature>/          # feature folders, not layer folders
    thing.ts
    thing.test.ts     # tests colocated
  lib/                # shared utilities (only after 2+ users)
```

- `exports` map for anything published; no deep-path imports into other packages' internals.
- Env access centralized in one validated config module (zod-parsed `process.env`) — no raw `process.env.X` scattered around.

## Testing expectations

- vitest by default (jest where entrenched). Colocated `*.test.ts`.
- Test through public APIs; mock at process/network boundaries only (MSW or injected clients), not internal modules.
- Typecheck (`tsc --noEmit`), lint, and tests all gate CI.

## Common pitfalls / smells

- `as any`, `@ts-ignore`, or a cast used to silence an error instead of fixing the type.
- Floating promises — an unawaited call whose failure vanishes into `unhandledRejection`.
- Sequential `await`s on independent operations instead of `Promise.all`.
- A second lockfile appearing in the tree (mixed package managers).
- Copy-pasted utility functions (`formatDate`, `sleep`, `chunk`) drifting apart across files.
- Hand-written interfaces duplicating a zod schema, guaranteed to desynchronize.
- `JSON.parse` results typed by assertion instead of validated by schema.
- Barrel files (`index.ts` re-exporting everything) creating import cycles and killing tree-shaking.
