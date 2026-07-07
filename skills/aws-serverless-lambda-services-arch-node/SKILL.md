---
name: aws-serverless-lambda-services-arch-node
description: Architect and scaffold a new AWS serverless app as lambda services with Node.js/TypeScript as the default runtime — NodejsFunction + esbuild ESM bundles on NODEJS_24_X ARM64, Hono or plain handlers, CDK v2 infra, CloudFront → Lambda Function URLs, single-table DynamoDB, Cognito + in-handler JWT. Use when starting a new Node-first serverless/SaaS backend, when the user says "build this app with Node lambdas", "scaffold Node services", or wants the serverless lambda-services architecture with a plain Node.js runtime instead of Rust or Bun. Do NOT use for existing codebases with an established architecture, or for container/ECS/EC2/Kubernetes deployments — this skill applies only when the user explicitly opts into building a NEW app on this Lambda-services architecture.
---

# AWS Serverless Lambda-Services Architecture — Node.js default

Node-first variant of the `aws-serverless-lambda-services-arch` skill. **Identical architecture** (CloudFront → Function URLs, one lambda per bounded context, single-table DynamoDB, Cognito + in-handler JWT, SQS/EventBridge async, per-env IAM deploy users) — only the default service runtime changes.

## Reference files

All deep material lives in the sibling base skill `aws-serverless-lambda-services-arch` — read from its directory (same skills folder as this skill; paths below are relative to this SKILL.md):

| File | Covers |
|---|---|
| `../aws-serverless-lambda-services-arch/references/node-lambda-service.md` | **The default runtime (read first)**: `NodejsFunction`/esbuild bundling (Flavor A), plain single-file SQS workers (Flavor B), worker authorization rule, Powertools option, vitest |
| `../aws-serverless-lambda-services-arch/references/bun-lambda-service.md` | The Hono service anatomy Flavor A reuses (entry skeleton, middleware order, ServiceError, repositories) |
| `../aws-serverless-lambda-services-arch/references/cdk-infrastructure.md` | Stacks, cross-region cert+WAF, CloudFront behavior factory, log groups, observability, IAM deploy users, SSM config, failure lessons |
| `../aws-serverless-lambda-services-arch/references/data-auth-events.md` | DynamoDB key patterns, S3, Cognito/JWT/multi-tenancy, SQS/streams/schedules, webhooks, Bedrock |
| `../aws-serverless-lambda-services-arch/references/scaffold-cicd-ops.md` | Monorepo template, naming, environments, CI/CD, operational checklist |
| `../aws-serverless-lambda-services-arch/SKILL.md` (base) | Architecture diagram, core decisions + rationale, scaffolding order, invariants, known failure modes |

Follow the base skill's **"Scaffolding a new app — order of work"**, **Invariants**, and **Known failure modes** sections as written, with the substitutions below.

## Runtime decision table (default = Node)

Every service is Node/TypeScript unless a row below applies:

| Situation | Runtime |
|---|---|
| Default: CRUD, APIs, webhooks, HTTP services | **Node** — `NodejsFunction` + esbuild, ESM, `NODEJS_24_X` ARM64, Hono (or the team's framework) inside |
| Single-purpose SQS/stream/schedule workers | **Node** — plain single-file handler (Flavor B), `reportBatchItemFailures` |
| AI/ML: Bedrock streaming, RAG, PDF/embedding ecosystem | Python + Lambda Web Adapter (`RESPONSE_STREAM`) |
| Hot path where cold start / memory cost genuinely matters (measured, not assumed) | Rust (`../aws-serverless-lambda-services-arch/references/rust-lambda-service.md`) |
| Headless chromium / large native binaries | DockerImageFunction |

Record every non-Node choice in an ADR.

## Substitutions vs the base (Rust) skill

- **Monorepo**: cargo workspace → npm workspaces; `packages/shared-rust` → `packages/shared-<prefix>` + `packages/auth-<prefix>` (TypeScript).
- **Service scaffold**: crate with `bootstrap` binary → `services/<name>/src/index.ts`; same `handlers → services → repositories` layering.
- **CDK construct**: `RustLambda` → `NodejsFunction` with `bundling: { format: ESM, target: "node24", minify, sourceMap, externalModules: ["@aws-sdk/*"], banner: <createRequire shim> }`. **CDK owns bundling — no per-service build script** (the key difference from the Bun variant).
- **CI gate**: `cargo fmt/clippy/test` → ESLint/Prettier + `tsc --noEmit` + vitest; `actions/cache` on `~/.npm`. Keep the env-file/secret-scan gates. `cdk synth` needs no Docker-skip stub (esbuild bundles without Docker when esbuild is installed).
- **Observability**: shared `requestLogger`/`errorHandler` (one JSON access-log line per request) or AWS Lambda Powertools for TypeScript — pick one per repo.
- **Memory defaults**: 256 MB typical for HTTP services; tune workers by workload.

## Node-specific invariants (add to the new repo's AGENTS.md, alongside the base invariants)

- `externalModules: ["@aws-sdk/*"]` only; every other dependency is bundled by esbuild.
- ESM output needs the `createRequire` banner shim if any bundled dep calls `require()`.
- AWS clients at module scope (once per container), `NODE_OPTIONS=--enable-source-maps` everywhere.
- Workers that fan out per-tenant effects MUST re-verify target↔tenant assignment inside the worker — never trust caller-supplied ID pairs (this was a real cross-tenant leak vector).
- One `ServiceError` definition in the shared package; duck-typed recognizers, never `instanceof` across bundle boundaries.
