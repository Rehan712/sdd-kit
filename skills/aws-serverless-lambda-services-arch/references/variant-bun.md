# AWS Serverless Lambda-Services Architecture — Bun.js default

Bun-first variant of the `aws-serverless-lambda-services-arch` skill — read when the user asks for a Bun.js app (`/aws-serverless-lambda-services-arch bun`). **Identical architecture** (CloudFront → Function URLs, one lambda per bounded context, single-table DynamoDB, Cognito + in-handler JWT, SQS/EventBridge async, per-env IAM deploy users) — only the default service runtime changes. This is the architecture running a production multi-tenant SaaS with 11 Bun services.

## Reference files

The deep material is shared with the Rust default — the files below sit beside this one:

| File | Covers |
|---|---|
| `bun-lambda-service.md` | **The default runtime (read first)**: Hono entry skeleton, build.ts + ESM gotchas, shared packages, duck-typed ServiceError, auth middleware, repositories, bun test, CDK declaration |
| `cdk-infrastructure.md` | Stacks, cross-region cert+WAF, CloudFront behavior factory, log groups, observability, IAM deploy users, SSM config, failure lessons |
| `data-auth-events.md` | DynamoDB key patterns, S3, Cognito/JWT/multi-tenancy, SQS/streams/schedules, webhooks, Bedrock |
| `scaffold-cicd-ops.md` | Monorepo template, naming, environments, CI/CD, operational checklist |
| `../SKILL.md` (the skill itself) | Architecture diagram, core decisions + rationale, scaffolding order, invariants, known failure modes |

Follow the skill's (`../SKILL.md`) **"Code style and scope"** (style guides, ponytail, official skills, read-only scouts — here every service is TypeScript, so `~/.sdd/templates/style-guides/typescript.md` governs services and CDK alike), **"Scaffolding a new app — order of work"**, **Invariants**, and **Known failure modes** sections as written, with the substitutions below.

## Runtime decision table (default = Bun)

Every service is Bun/TypeScript unless a row below applies:

| Situation | Runtime |
|---|---|
| Default: CRUD, APIs, webhooks, queues, most workers | **Bun** (Hono + `hono/aws-lambda`, `Bun.build` → ESM on `NODEJS_24_X` ARM64) |
| AI/ML: Bedrock streaming, RAG, PDF/embedding ecosystem | Python + Lambda Web Adapter (`RESPONSE_STREAM`) |
| Hot path where cold start / memory cost genuinely matters (measured, not assumed) | Rust (`rust-lambda-service.md`) |
| Trivial single-purpose SQS/stream workers | Plain Node single-file handler (`node-lambda-service.md`, Flavor B) — or Bun for uniformity |
| Headless chromium / large native binaries | DockerImageFunction |

Record every non-Bun choice in an ADR.

## Substitutions vs the base (Rust) skill

- **Monorepo**: cargo workspace → npm/Bun workspaces; `packages/shared-rust` → `packages/shared-<prefix>` + `packages/auth-<prefix>` (TypeScript, `file:` deps).
- **Service scaffold**: crate with `bootstrap` binary → `services/<name>/` with `src/index.ts` (Hono), `build.ts`, `local.ts`.
- **CDK construct**: `RustLambda` (Docker cargo-lambda bundling) → plain `lambda.Function` with `NODEJS_24_X` + `ARM_64` + `Code.fromAsset("../services/<name>/dist")`; services are **pre-built by their own `build.ts`** before `cdk deploy` (root script builds all, CI job builds all).
- **CI gate**: `cargo fmt/clippy/test` → per-service `tsc --noEmit` + `bun test` (at minimum the launch-critical services) + committed-artifact staleness checks. Keep the env-file/secret-scan gates.
- **Memory defaults**: 256 MB typical, 128 MB for trivial services (vs Rust's 512 starting point — measure and tune either way).

## Bun-specific invariants (add to the new repo's AGENTS.md, alongside the base invariants)

- Every `build.ts` writes `{"type":"module"}` to `dist/package.json` — without it Node Lambda throws `Cannot use import statement outside a module`.
- Externalize ONLY `@aws-sdk/*`; every other dependency is bundled.
- One `ServiceError` definition in the shared package; recognizers are duck-typed (`isServiceError`), never `instanceof` — bundle boundaries break instanceof.
- `getApp()` lazy singleton: clients/repos/services constructed once per container.
- Router mount order: static segments before `/:param`; public cacheable routes before authed wildcards (mirrors CloudFront behavior order).
- Local dev: `local.ts` (`Bun.serve` on the same app) + a root proxy mapping `/api/*` prefixes to service ports.
