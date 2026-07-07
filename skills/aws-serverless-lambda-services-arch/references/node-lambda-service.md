# Node.js Lambda service — TypeScript runtime variant

Two flavors, both production-proven. Pick per service:

- **Flavor A — `NodejsFunction` (esbuild-in-CDK)**: the default for Node-first apps. CDK owns bundling; no per-service build script.
- **Flavor B — plain single-file worker**: for SQS/stream/schedule workers with one job and few deps (production examples: push-sender, webhook-sender).

## Flavor A: HTTP service with NodejsFunction

Same service anatomy and layering as the Bun variant (`index.ts` + `handlers/` + `services/` + `repositories/` + `middleware/` — see `bun-lambda-service.md`; the Hono skeleton is identical since `hono/aws-lambda` runs on Node). Differences are all in build/deploy:

```ts
import { NodejsFunction, OutputFormat } from "aws-cdk-lib/aws-lambda-nodejs";

new NodejsFunction(this, "OrdersService", {
  entry: "../services/orders-service/src/index.ts",
  runtime: lambda.Runtime.NODEJS_24_X,
  architecture: lambda.Architecture.ARM_64,
  handler: "handler",
  timeout: cdk.Duration.seconds(30),
  memorySize: 256,
  environment: { TABLE_NAME, ENVIRONMENT: env, NODE_OPTIONS: "--enable-source-maps" },
  logGroup: makeLogGroup("OrdersService"),
  bundling: {
    format: OutputFormat.ESM,
    target: "node24",
    minify: true,
    sourceMap: true,
    externalModules: ["@aws-sdk/*"],          // runtime provides SDK v3; bundle everything else
    // ESM banner shim — required if any bundled dep still calls require()
    banner: "import { createRequire } from 'module'; const require = createRequire(import.meta.url);",
  },
});
```

Notes:
- esbuild runs locally if installed, else in Docker — deterministic either way; asset hash keys on the bundle output.
- The `{"type":"module"}`-in-dist gotcha from the Bun variant does not apply — `NodejsFunction` handles ESM packaging (via the `.mjs` output / format handling).
- Monorepo shared packages (`packages/shared`, `packages/auth`) work via workspace resolution; esbuild follows the imports and bundles them.
- Keep `externalModules` to `@aws-sdk/*` only — same rule as Bun: a dep not in the runtime must be in the bundle.

### Observability (Node-idiomatic option)

The homegrown option (shared `requestLogger` + `errorHandler`, one JSON access-log line per request) ports as-is. Alternatively use **AWS Lambda Powertools for TypeScript** (`@aws-lambda-powertools/logger|tracer|metrics`) — idiomatic for Node-first shops; pick one approach per repo and stick with it.

## Flavor B: plain single-file worker (SQS / stream / schedule)

For senders and cleaners, skip the framework entirely — one file, module-scope client reuse:

```js
// services/push-sender/index.js  (CommonJS is fine here; no bundler needed)
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, QueryCommand } = require("@aws-sdk/lib-dynamodb");

const TABLE_NAME = process.env.TABLE_NAME;
const dynamo = DynamoDBDocumentClient.from(new DynamoDBClient({}));  // once per container

exports.handler = async (event) => {
  const failures = [];
  for (const record of event.Records) {
    try {
      await processMessage(JSON.parse(record.body));
    } catch (err) {
      console.error(`[Worker] failed messageId=${record.messageId}: ${err.message}`);
      failures.push({ itemIdentifier: record.messageId });
    }
  }
  return { batchItemFailures: failures };   // pairs with reportBatchItemFailures on the event source
};
```

Rules for workers:
- **Authorize inside the worker, not at the producer.** A worker that fans out per-tenant effects (push, email, webhooks) must re-verify the target belongs to the tenant in the message (e.g. check the AGENT↔CHATBOT assignment row) — never trust caller-supplied ID pairs. This exact gap was a real cross-tenant leak vector.
- `DynamoDBDocumentClient` (not low-level) is fine here — workers are internal, no API-shape concerns.
- Deploy: deps installed at build time (`npm ci --omit=dev` into the asset dir), `lambda.Code.fromAsset`, or use `NodejsFunction` for these too if you prefer uniform bundling.
- Outbound-webhook workers: HMAC-SHA256 sign the payload, track consecutive failures per endpoint, auto-disable after N failures. DLQ + depth alarm always (see `data-auth-events.md`).

## Testing

- **vitest** (or `node --test`) for unit tests, co-located `*.test.ts`; `tsc --noEmit` typecheck gate.
- Repository tests against DynamoDB Local as a CI sidecar when coverage matters.
- CI: same gate structure as the base architecture (fmt/lint → typecheck → test → deploy), with `actions/cache` on `~/.npm` keyed on the lockfile.

## When Node beats Bun (and vice versa)

| Prefer Node (`NodejsFunction`) | Prefer Bun toolchain |
|---|---|
| Team/CI already standardized on Node + npm | You want Bun's speed for dev/test loops |
| Want CDK-owned bundling (no build.ts per service) | Fine owning a small build.ts per service |
| Powertools-based observability desired | Homegrown shared logger suffices |
| Simple single-file workers | Many HTTP services sharing workspace packages |

Both compile to the same deploy artifact class (ESM bundle on `NODEJS_24_X`, ARM64) and share every other pattern in this skill: layering, ServiceError → RFC-7807-style mapping, camelCase JSON, single-table DynamoDB idioms, in-handler JWT auth, CloudFront behavior coupling.
