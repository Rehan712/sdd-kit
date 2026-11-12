# Stack overlay: Next.js

Read this alongside `plan.md` when the project's `stack.yml` includes `nextjs`.

## Style guide

New and changed TypeScript/JavaScript follows
**`~/.sdd/templates/style-guides/typescript.md`** — the kit's digest of the
[Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html).
Read it for a new file, or when the project has no linter or formatter
config; otherwise match the file. Project config (ESLint, Prettier, tsconfig) and
the file being edited win; never restyle lines the task does not touch.
Framework exception: files Next.js loads by convention (`page`, `layout`,
`loading`, `error`, `not-found`, `template`, `default`, `next.config`) keep the
default export the framework requires; everything else uses named exports.

## Official skills

- **Next.js docs, version-matched, before memory.** Read the page for the API
  you touch in `node_modules/next/dist/docs/` (Next.js 16.3+; the `AGENTS.md`
  that `next dev` writes indexes it) or `.next-docs/` on an older project.
  Neither present → name it in the plan: `npx @next/codemod@canary agents-md`
  adds them.
- **Workflow skills** (`vercel/next.js`), when listed and the task is that
  workflow: `next-cache-components-adoption` / `-optimizer`,
  `next-partial-prefetching-adoption` / `-optimizer`, `next-bundle-optimizer`,
  `next-dev-loop`. A version upgrade runs `npx @next/codemod@latest upgrade`.
- **UI work:** `ui-ux-pro-max` (`--stack nextjs`). Read the persisted
  `design-system/<project>/MASTER.md` (and its `pages/` override) first; query
  the skill only for a decision those do not cover, and close a UI task with
  its pre-delivery checklist.

Load only what the task touches — precedence and install commands are in
`~/.sdd/templates/official-skills.md`.

## Conventions

- **Router:** prefer **App Router** (`app/`) for new features. Pages Router (`pages/`) only when the existing project hasn't migrated yet — don't mix new features across both.
- **Server Components by default.** Add `"use client"` only when you need state, effects, browser APIs, or event handlers. A `"use client"` near the leaf is better than near the root.
- **Data fetching:** server actions or RSC `fetch()` with explicit cache directives (`cache: 'no-store'` or `next: { revalidate: N }`). Avoid `useEffect` for initial data.
- **Server state on the client:** RTK Query, React Query, or SWR. Don't put server data directly in Zustand/Redux client store.
- **Forms:** server actions + `useActionState` (App Router) or react-hook-form. Validate with zod on both client and server.

## File layout

- Route segments: `app/<segment>/page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, `not-found.tsx`.
- Colocate route-specific components in `app/<segment>/_components/`.
- Shared UI: `components/` at the app root.
- Server-only utilities: `app/_lib/` or `lib/server/`; client utilities: `lib/client/`.
- API routes: `app/api/<route>/route.ts` only when you need an HTTP endpoint a non-Next client will call. For Next-internal mutations, prefer server actions.

## Performance

- **Images:** `next/image` with explicit `width`/`height` or `fill`. Provide `sizes` for responsive images.
- **Fonts:** `next/font` with `display: 'swap'`. No `<link href="fonts.googleapis.com">` in `<head>`.
- **Bundles:** dynamic-import heavy components (`next/dynamic`) when they're below the fold or behind interaction.
- **Streaming:** use `<Suspense>` boundaries to ship the shell fast and stream slow data.
- **Avoid waterfalls:** `Promise.all` parallel fetches inside RSCs; don't sequence `await` calls that don't depend on each other.

## Caching pitfalls

Next.js caches aggressively. Be explicit:

- `fetch()` in RSC is cached by default. Pass `{ cache: 'no-store' }` for live data.
- `revalidatePath()` / `revalidateTag()` after mutations — not doing this is a common bug.
- `unstable_cache` for expensive computations that aren't `fetch`-able.

## Testing

- Unit: vitest or jest with `@testing-library/react`.
- E2E: Playwright. Test the routes in the production build, not just dev.

## Deployment

- **Vercel** for marketing/SaaS frontends.
- **AWS Amplify Hosting** or **CloudFront + Lambda@Edge / Lambda function URL** when the project lives entirely in AWS. SST or OpenNext for self-hosted.
- Always check the `output: 'standalone'` config for AWS deployments.

## Common smells

- `"use client"` at the top of `page.tsx` for a page that doesn't actually need it.
- `useEffect(() => { fetch(...) }, [])` instead of an RSC `await fetch(...)`.
- Inline event handlers passed from server to client (won't serialize).
- Hard-coded English strings — wrap with the project's i18n function.

## Failure-mode and checkpoint defaults

Use the [verification contract](../verification-contract.md). Fill applicable
scenario prompts as concrete FM/INV rows with test families in the plan; record
explicit exclusions with a component/category and reason. Shared scenarios use
one row listing all affected components.

- Boundary: server-only credentials never cross the server/client serialization boundary; exercise the client import path.
- State/data integrity: mutate cached data as one user, then read as another; test cache keys and invalidation without cross-user disclosure.
- Partial failure: invoke a server action directly with missing or stale authorization; reject before mutation and render the declared error state.

Optional `checkpoints` use exact authored task-stage names: run the focused
component tests when its stage finishes and integration after consumers land.
Start from `npm test -- --run`, adapting to existing project scripts and test scope.
Required `gate_checks` separately cover the full suite (`npm test -- --run`)
and mandatory static checks (`npm run lint; npm run typecheck; npm run build`); checkpoints never replace that list.
Commands here are planning defaults, not an assertion that a project has them.
