# Stack overlay: React

Read alongside `plan.md` when the project's stack includes `react`.

## Conventions

- **React 18+.** Function components and hooks only; no new class components.
- **Server-first where the framework supports it:** server components by default, `"use client"` at the leaf that actually needs state/effects/browser APIs — not at the route root.
- **Hooks discipline:** unconditional, top-level, exhaustive deps honored. `useEffect` synchronizes with external systems only — derived state is computed during render (memoize if expensive), prop-driven resets use `key`, data fetching belongs to the data layer.
- **Server state vs client state:** remote data through React Query / RTK Query / the framework's loader layer — never hand-mirrored into Redux/Zustand/Context. Client stores hold genuine UI state only.
- **State placement:** as low as possible; lift to the nearest common parent; context for subtree concerns; a global store only for truly app-global state.
- **i18n from day 1:** every user-facing string through the i18n function, even single-locale. Hard-coded copy is a defect.

## Component layout

```
src/
  components/          # shared, reusable UI (design-system tier)
  features/<feature>/  # feature folders: components, hooks, queries together
    ComponentName.tsx
    ComponentName.test.tsx
    useFeatureQuery.ts
  hooks/               # shared hooks (2+ consumers)
  lib/                 # non-React utilities
```

- Components stay presentational where possible; data wiring lives in feature hooks.
- Every view defines loading, empty, error, and partial states — not just the happy path.

## Accessibility (baseline, not polish)

- Semantic HTML first: `button` for actions, `a` for navigation, `label` on every input, headings in order, landmarks (`nav`, `main`).
- Full keyboard operability; visible focus; focus managed on dialogs and route changes; ARIA only where semantics fall short.

## Performance

- Fix the dependency graph before memoizing; `memo`/`useMemo`/`useCallback` where measured or where the dep graph is non-trivial — not by reflex.
- Stable `key`s (never array index for reorderable lists); no fresh object/array/lambda props into memoized children; virtualize long lists.

## Testing expectations

- Testing Library: query by role/label/text as a user would; assert behavior, not implementation.
- Snapshots only for tiny stable presentational output — never as the primary assertion.
- MSW (or equivalent) at the network boundary; `user-event` over `fireEvent`.

## Common pitfalls / smells

- `useEffect(() => { fetch(...) }, [])` where the data layer should own the request.
- `useState` + `useEffect` pairs recomputing what render could derive directly.
- Props drilled 4+ levels — the tree needs composition (children/slots), not more plumbing.
- Div-soup: `onClick` on `div`s, unlabeled inputs, no semantic landmarks.
- Server responses copied into a client store and drifting stale.
- Effect chains where one effect sets state that triggers another effect.
- Hard-coded user-facing strings scattered outside i18n.

## Failure-mode and checkpoint defaults

Use the [verification contract](../verification-contract.md). Fill applicable
scenario prompts as concrete FM/INV rows with test families in the plan; record
explicit exclusions with a component/category and reason. Shared scenarios use
one row listing all affected components.

- Concurrency/ordering: resolve requests out of order after a dependency change; stale state must not overwrite the current selection.
- Partial failure: unmount during an effect and exercise the error boundary; assert cleanup and the visible recovery action.
- Boundary: empty/loading/error data and repeated submit events keep accessible controls and prevent duplicate mutations.

Optional `checkpoints` use exact authored task-stage names: run the focused
component tests when its stage finishes and integration after consumers land.
Start from `npm test -- --run`, adapting to existing project scripts and test scope.
Required `gate_checks` separately cover the full suite (`npm test -- --run`)
and mandatory static checks (`npm run lint; npm run typecheck`); checkpoints never replace that list.
Commands here are planning defaults, not an assertion that a project has them.
