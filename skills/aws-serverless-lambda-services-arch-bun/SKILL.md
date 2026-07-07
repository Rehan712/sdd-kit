---
name: aws-serverless-lambda-services-arch-bun
description: Architect and scaffold a new AWS serverless app as lambda services with Bun.js/TypeScript as the default runtime — Hono handlers via hono/aws-lambda, Bun.build ESM bundles on NODEJS_24_X ARM64, CDK v2 infra, CloudFront → Lambda Function URLs, single-table DynamoDB, Cognito + in-handler JWT. Use when starting a new Bun-first serverless/SaaS backend, when the user says "build this app with Bun lambdas", "scaffold Bun services", or wants the serverless lambda-services architecture with a TypeScript/Bun runtime instead of Rust. Do NOT use for existing codebases with an established architecture, or for container/ECS/EC2/Kubernetes deployments — this skill applies only when the user explicitly opts into building a NEW app on this Lambda-services architecture.
---

# AWS Serverless Lambda-Services Architecture — Bun.js default

Bun-first variant of the `aws-serverless-lambda-services-arch` skill. **Identical architecture** (CloudFront → Function URLs, one lambda per bounded context, single-table DynamoDB, Cognito + in-handler JWT, SQS/EventBridge async, per-env IAM deploy users) — only the default service runtime changes. This is the architecture running a production multi-tenant SaaS with 11 Bun services.

## Reference files

All deep material lives in the sibling base skill `aws-serverless-lambda-services-arch` — read from its directory (same skills folder as this skill; paths below are relative to this SKILL.md):

| File | Covers |
|---|---|
| `../aws-serverless-lambda-services-arch/references/bun-lambda-service.md` | **The default runtime (read first)**: Hono entry skeleton, build.ts + ESM gotchas, shared packages, duck-typed ServiceError, auth middleware, repositories, bun test, CDK declaration |
| `../aws-serverless-lambda-services-arch/references/cdk-infrastructure.md` | Stacks, cross-region cert+WAF, CloudFront behavior factory, log groups, observability, IAM deploy users, SSM config, failure lessons |
| `../aws-serverless-lambda-services-arch/references/data-auth-events.md` | DynamoDB key patterns, S3, Cognito/JWT/multi-tenancy, SQS/streams/schedules, webhooks, Bedrock |
| `../aws-serverless-lambda-services-arch/references/scaffold-cicd-ops.md` | Monorepo template, naming, environments, CI/CD, operational checklist |
| `../aws-serverless-lambda-services-arch/SKILL.md` (base) | Architecture diagram, core decisions + rationale, scaffolding order, invariants, known failure modes |

Follow the base skill's **"Scaffolding a new app — order of work"**, **Invariants**, and **Known failure modes** sections as written, with the substitutions below.

## Runtime decision table (default = Bun)

Every service is Bun/TypeScript unless a row below applies:

| Situation | Runtime |
|---|---|
| Default: CRUD, APIs, webhooks, queues, most workers | **Bun** (Hono + `hono/aws-lambda`, `Bun.build` → ESM on `NODEJS_24_X` ARM64) |
| AI/ML: Bedrock streaming, RAG, PDF/embedding ecosystem | Python + Lambda Web Adapter (`RESPONSE_STREAM`) |
| Hot path where cold start / memory cost genuinely matters (measured, not assumed) | Rust (`../aws-serverless-lambda-services-arch/references/rust-lambda-service.md`) |
| Trivial single-purpose SQS/stream workers | Plain Node single-file handler (`../aws-serverless-lambda-services-arch/references/node-lambda-service.md`, Flavor B) — or Bun for uniformity |
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
