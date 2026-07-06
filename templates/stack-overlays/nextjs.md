# Stack overlay: Next.js

Read this alongside `plan.md` when the project's `stack.yml` includes `nextjs`.

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
