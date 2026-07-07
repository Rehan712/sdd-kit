# Bun Lambda service — TypeScript runtime variant

Patterns lifted from a production multi-tenant SaaS running 11 Bun services. Bun is the **dev/build/test toolchain**; the deployed artifact runs on the **Node.js Lambda runtime** (`NODEJS_24_X`) — `Bun.build` targets node.

## Monorepo layout

npm/Bun workspaces; shared packages consumed via `file:` deps:

```
packages/
├── shared-<prefix>/       # dynamo toolkit, errors, observability, validation, response, config
├── auth-<prefix>/         # JWT verification only (dependency-free, Web Crypto)
└── rate-limiter-<prefix>/
services/
└── <name>-service/
    ├── src/
    │   ├── index.ts           # Hono app + `export const handler = handle(getApp())`
    │   ├── handlers/*.ts      # router factories (createXRouter(service))
    │   ├── services/*.ts      # business logic — throw ServiceError
    │   ├── repositories/*.ts  # DynamoDB (low-level client + typed getters)
    │   ├── models/*.ts        # API + item shapes
    │   ├── middleware/auth.ts
    │   ├── utils/response.ts  # res.ok/created/badRequest/…
    │   ├── types.ts           # Hono AppEnv (typed context vars)
    │   └── local.ts           # Bun.serve local dev server
    ├── build.ts               # Bun.build → dist/index.js
    └── package.json
```

**Layering: `handler → service → repository`. Never skip layers.**

## Entry point (index.ts skeleton)

Lazy singleton so clients/repos/services are constructed once per container:

```ts
import { Hono } from "hono";
import { handle } from "hono/aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { requestLogger, errorHandler, logColdStart, createLogger } from "@<prefix>/shared";

let _app: Hono<AppEnv> | undefined;

function getApp(): Hono<AppEnv> {
  if (_app) return _app;
  const dynamo = new DynamoDBClient({});
  const repo = new WidgetRepository(dynamo);          // constructor DI
  const service = new WidgetService(repo);

  const app = new Hono<AppEnv>();
  app.options("*", (c) => corsPreflightResponse());    // 1. CORS preflight
  app.use("*", requestLogger("widget-service"));       // 2. one access-log line/request
  app.use("*", originGuardMiddleware({ skipPaths: ["/api/health"] })); // 3. edge-origin check
  app.get("/api/health", (c) => c.json({ status: "healthy" }));       // 4. public health
  app.use("*", authMiddleware);                        // 5. JWT — everything below is authed
  app.route("/", createWidgetRouter(service));         // 6. domain routers (static paths before /:param)
  app.all("*", (c) => c.json({ error: "Not Found" }, 404));
  app.onError(errorHandler("widget-service"));         // 7. central error mapping
  _app = app;
  logColdStart(createLogger({ service: "widget-service" }));
  return app;
}

export const handler = handle(getApp());
```

Route mount order is deliberate: **static segments before `/:param` routes**, public cacheable routes registered before authed wildcards (must mirror the CloudFront behavior ordering).

## build.ts (CRITICAL — every gotcha here has caused a production outage)

```ts
const result = await Bun.build({
  entrypoints: ["src/index.ts"],
  outdir: "dist",
  target: "node",          // Lambda runtime is Node, not Bun
  format: "esm",
  minify: true,
  sourcemap: "external",
  external: ["@aws-sdk/client-dynamodb", "@aws-sdk/lib-dynamodb"],  // ONLY @aws-sdk/*
});
if (!result.success) { console.error(result.logs); process.exit(1); }

// Without this, Node Lambda throws "SyntaxError: Cannot use import statement outside a module"
writeFileSync("dist/package.json", JSON.stringify({ type: "module" }));
```

Rules:
- **Externalize ONLY `@aws-sdk/*`** (provided by the runtime). Everything else (`hono`, `jsonwebtoken`, `bcryptjs`, …) MUST be bundled.
- **`dist/package.json` with `{"type":"module"}` is mandatory** for the ESM bundle.
- CDK ships the artifact as-is: `lambda.Code.fromAsset("../services/<name>/dist")` — no CDK-side bundling.

## Errors & responses

Shared `ServiceError` with a code union (`NOT_FOUND|UNAUTHORIZED|FORBIDDEN|VALIDATION|CONFLICT|RATE_LIMITED|INTERNAL|...`) and static factories (`ServiceError.notFound(...)`).

- **Duck-type the recognizers, never `instanceof`**: `isServiceError(e)` checks shape/name — the bundle boundary (each service bundles its own copy of shared code) breaks `instanceof` across transpiled copies.
- `statusForCode()` maps code → HTTP; central `errorHandler(service)` on `app.onError`: ValidationError → 400, ServiceError → mapped status (5xx logged with stack; auth/conflict/rate at warn), unknown → 500 with stack.
- Handlers return via `res.ok()/created()/badRequest()/...` helpers only. **API JSON is camelCase.**
- Keep exactly ONE ServiceError definition in the shared package — per-service copies drift (seen in production).

## Auth (shared auth package — dependency-free, Web Crypto)

- **RS256** (Cognito user tokens): JWKS by `kid`, keys cached ~1 h with one forced refresh on unknown kid; verify signature + `iss` + `aud`/`client_id` + `token_use` + `exp`/`nbf` (30 s skew).
- **HS256** (machine/secondary principals): `JWT_SECRET` from SSM; claims must carry the expected `role`.
- Claims → `AuthContext { userId, username, email, roles, permissions }` stored on Hono context (`c.set("auth", ...)`).
- Per-service `authMiddleware`: Bearer extraction → verify → **role-based path-prefix allowlist** (`ROLE_PATH_PREFIXES` in constants); explicit public paths get a synthetic guest context.

## DynamoDB repositories

- Low-level `@aws-sdk/client-dynamodb` + a shared typed toolkit: getters `str/num/bool/jsonAttr/strList`, builders `S/N/BOOL/L/SS`, wrappers `getItem/putItem/queryItems/queryGSI`.
- Per-repo `Keys` object of key-builder functions (`pk: (userId) => `USER#${userId}``) — key shapes live in one place per entity.
- Nested config objects stored as JSON-string attributes, parsed in `itemToX()` mappers.
- All single-table idioms from `data-auth-events.md` apply unchanged.

## Validation

Hand-written imperative helpers (no zod at runtime — bundle size + cold start): `requireString(v, "name", MAX_SHORT_TEXT)` throwing `ValidationError`; length caps centralized in `constants.ts`. Parse with `await c.req.json<T>()` in try/catch → `badRequest`.

## Local dev & testing

- `src/local.ts`: `Bun.serve({ fetch: getApp().fetch })` — same app object, instant local server; a root proxy-server maps `/api/*` prefixes to per-service local ports.
- Tests: **`bun test`** with co-located `*.test.ts`; typecheck via `tsc --noEmit`. Test seams via injectable clients (`setSsmForTests(...)`).
- CI gate: install workspace packages, then `tsc --noEmit && bun test` at minimum for launch-critical services; a staleness check for any committed build artifact (rebuild + diff).

## CDK declaration

```ts
new lambda.Function(this, "WidgetService", {
  runtime: lambda.Runtime.NODEJS_24_X,
  architecture: lambda.Architecture.ARM_64,
  handler: "index.handler",
  code: lambda.Code.fromAsset("../services/widget-service/dist"),
  timeout: cdk.Duration.seconds(30),
  memorySize: 256,                       // 128 for trivial services; Bun bundles are lean
  environment: { TABLE_NAME, ENVIRONMENT: env, NODE_OPTIONS: "--enable-source-maps", ... },
  logGroup: makeLogGroup("WidgetService"),
});
```

Everything else (Function URL + CloudFront behavior, alarms, IAM grants) is identical to the base architecture — see `cdk-infrastructure.md`.
