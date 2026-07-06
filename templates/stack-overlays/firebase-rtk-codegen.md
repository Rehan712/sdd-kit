# Stack overlay: Firebase + RTK Query OpenAPI codegen

Read alongside `plan.md` when `stack.yml` includes `firebase-rtk-codegen`.

## Firebase

- **Auth:** Firebase Auth as the single identity provider for the app. Don't introduce a second.
- **Custom claims** for role/permission propagation rather than reading a profile doc on every request.
- **Token refresh:** `getIdToken(true)` only on explicit role change; rely on the SDK's auto-refresh otherwise.
- **Security rules**: enforce server-side on Firestore/Storage if used. Client-side checks are UX, not security.

## RTK Query OpenAPI codegen

- **Source of truth:** the backend's OpenAPI spec (LB4 emits `/openapi.json`; FastAPI emits `/openapi.json`).
- **Codegen config** at repo root: `openapi-config.json` or `openapi-config.ts` pointing at the backend spec URL or a checked-in JSON copy.
- **Generated file** committed: `src/services/api/generated.ts` (or similar) — never hand-edit.
- **Manual enhancers** in a sibling file: `src/services/api/index.ts` extends `generated.ts` with `addTagTypes`, `providesTags`, `invalidatesTags`. Don't put cache config in the generated file.

## Tag invalidation pattern

```ts
api.enhanceEndpoints({
  addTagTypes: ['Trip', 'User'],
  endpoints: {
    listTrips:   { providesTags: (r) => [{type:'Trip', id:'LIST'}, ...r.map(t => ({type:'Trip', id:t.id}))] },
    createTrip:  { invalidatesTags: [{type:'Trip', id:'LIST'}] },
    updateTrip:  { invalidatesTags: (_r, _e, a) => [{type:'Trip', id:a.id}] },
  },
});
```

## Auth header injection

In `prepareHeaders`:

```ts
prepareHeaders: async (headers) => {
  const user = getAuth().currentUser;
  if (user) {
    const token = await user.getIdToken();
    headers.set('Authorization', `Bearer ${token}`);
  }
  return headers;
}
```

Don't try to read tokens from localStorage manually; let Firebase SDK manage refresh.

## Codegen pitfalls

- Backend changes a field → frontend `generated.ts` regenerates → app breaks at compile time. **Good.** Don't suppress with `any`.
- Codegen pulls breaking enum changes → bump a major version of the frontend package and update consumers.
- Polymorphic responses (`oneOf`) are codegen pain points; prefer discriminated unions in the OpenAPI spec.

## Local dev

- Frontend points at local backend (`http://localhost:3001/openapi.json`) for codegen; production points at the deployed URL.
- Re-run codegen as a `predev` script so working against a stale spec is rare.

## Testing

- Mock the API surface with **`msw`** + the generated types; don't mock at the `fetch` level.
- For Firebase: use the **Firebase Emulator Suite** for Auth + Firestore in CI; never test against production.
