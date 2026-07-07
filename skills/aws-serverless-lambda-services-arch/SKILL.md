---
name: aws-serverless-lambda-services-arch
description: Architect and scaffold a new AWS serverless app as a set of lambda services — Rust lambdas by default (cargo-lambda, provided.al2023, ARM64), CDK v2 TypeScript infra, CloudFront → Lambda Function URLs (no REST API Gateway), single-table DynamoDB, Cognito + in-handler JWT, SQS/EventBridge async, per-env IAM deploy users. Use when starting a new backend/SaaS app on AWS, when the user says "build a new app with my serverless architecture", "scaffold lambda services", "set up the AWS architecture", or asks how to structure services/infra for a new serverless project. Do NOT use for existing codebases with an established architecture, or for container/ECS/EC2/Kubernetes deployments — this skill applies only when the user explicitly opts into building a NEW app on this Lambda-services architecture.
---

# AWS Serverless Lambda-Services Architecture

Battle-tested architecture distilled from two production SaaS platforms. Use it to design and scaffold new apps: many small **lambda services** behind CloudFront, **Rust as the default runtime**, one CDK codebase, hard multi-env discipline.

## When NOT to use this skill

Bail out (and say so) if any of these hold — do not force this architecture:

- **The project already exists and has an established architecture** — follow its own `AGENTS.md`/`CLAUDE.md`, repo brief, and stack overlays instead. This skill is for greenfield apps.
- **The team deploys on containers/servers** (ECS, EKS, EC2, Fargate services, Fly, bare metal) — their Node/Rust services on those platforms are a different architecture; nothing here transfers safely.
- **In an SDD project**, the architecture choice belongs to `.specify/stack.yml` + the stack overlays consulted by /sdd:plan. Only apply this skill when the user has explicitly chosen the Lambda-services architecture for a new app.

## Reference files (read what the task needs)

| File | Covers |
|---|---|
| `references/rust-lambda-service.md` | The default service runtime: cargo workspace, crate anatomy, main.rs skeleton, `aws-lambda-router`, error boundary, DynamoDB idioms in Rust, auth, cold-start budget, testing |
| `references/bun-lambda-service.md` | Bun runtime variant (used by the `-bun` sibling skill): Hono + `handle()`, build.ts ESM gotchas, shared packages, duck-typed ServiceError, bun test |
| `references/node-lambda-service.md` | Node runtime variant (used by the `-node` sibling skill): `NodejsFunction`/esbuild bundling, plain single-file SQS workers, Powertools option, vitest |
| `references/cdk-infrastructure.md` | CDK app/stack topology, cross-region cert+WAF, the `RustLambda` construct, log-group factory, CloudFront behavior factory, WebSocket, observability, per-env IAM deploy users, SSM-first config, hard-won failure lessons |
| `references/data-auth-events.md` | Single-table DynamoDB key patterns, S3 bucket patterns, Cognito + JWT/API-key auth, multi-tenancy, SQS/DLQ workers, streams, schedules, inbound/outbound webhooks, Bedrock integration |
| `references/scaffold-cicd-ops.md` | Monorepo template, naming conventions, environments, root scripts, GitHub Actions deploy + cdk-diff gate, frontend hosting, operational checklist |

## The architecture in one diagram

```
clients (web SPA / admin SPA / widget / mobile)
        │
   CloudFront (per-env: main + admin distributions, us-east-1 ACM cert + WAF)
        │  /api/<context>/*  → Lambda Function URLs (authType NONE, auth in-handler)
        │  /*                → S3 static (Next.js export, widget bundle)
        │
   Rust lambda services (one per bounded context; provided.al2023, ARM64)
   ├── handler → service → repository (never skip layers)
   ├── API Gateway v2 WebSocket → realtime service (only if realtime needed)
   └── async: SQS+DLQ → worker lambdas · EventBridge cron → jobs · DDB stream → cleaners
        │
   DynamoDB single-table (PK/SK + 3 GSIs, TTL, PITR, CMK) · S3 buckets · SSM config
   Cognito (identity) · Bedrock (AI, via Python/LWA escape hatch when streaming)
```

Core decisions and why (defend these unless the new app truly differs):

| Decision | Why |
|---|---|
| CloudFront + Function URLs, no REST API Gateway | APIGW REST cost + config sprawl; one CDN for static+API; CORS/caching per behavior |
| One lambda per bounded context (5–15 services), not per route | Deploy independence without microservice sprawl; a router inside the lambda handles routes |
| **Rust default runtime** | Cold start + memory cost + compile-time safety; `provided.al2023` ARM64 |
| Single-table DynamoDB | Cost + latency; all access patterns via PK/SK + 3 generic GSIs |
| Auth in-handler, not edge authorizers | Function URLs stay simple; services own their public/role rules |
| SSM-first config, no Secrets Manager | Cheaper, per-env prefix scoping, tenant-scoped secret paths |
| Same-account envs + per-env IAM deploy users | Hard enough isolation for a small team without account overhead |
| Static-export frontends on S3 | No SSR lambda to run; rebuild-on-deploy is fine for dashboards |

## Runtime decision table (default = Rust)

Every service is Rust unless a row below applies:

| Situation | Runtime |
|---|---|
| Default: CRUD, APIs, workers, webhooks, queues, streams | **Rust** (`lambda_http` / `lambda_runtime`, `aws-lambda-router` crate for >3 routes) |
| AI/ML: Bedrock streaming, RAG, PDF/embedding ecosystem | Python + Lambda Web Adapter (`RESPONSE_STREAM`) |
| A required SDK exists only on npm | Node/Bun (prebuilt ESM bundle, externalize only `@aws-sdk/*`) |
| Headless chromium / large native binaries | DockerImageFunction (x86_64 if the binary demands) |

Record every non-Rust choice in an ADR — the exception must justify itself.

**Runtime-first siblings**: if the user wants a Bun-first or Node-first app (whole app, not a per-service exception), use the sibling skills `aws-serverless-lambda-services-arch-bun` / `aws-serverless-lambda-services-arch-node` — same architecture, swapped default runtime. They share this skill's reference files.

## Scaffolding a new app — order of work

1. **Name things first.** Pick `{prefix}`; write the naming-convention table into the new repo's `AGENTS.md` (see scaffold-cicd-ops.md). IAM scoping, SSM paths, and log groups all ride on it.
2. **Model the domain.** List bounded contexts → one service each. Write the DynamoDB key table (entity → PK/SK/GSI) BEFORE writing code; put it in `AGENTS.md` + `docs/DYNAMODB.md`.
3. **Scaffold the monorepo** per scaffold-cicd-ops.md: cargo workspace + `packages/shared-rust` + `infrastructure/` + one walking-skeleton service (health route) built with the `RustLambda` construct.
4. **Infra core**: app.ts (env validation, tags), cert+WAF us-east-1 stacks, main stack with table/buckets/CloudFront/behavior-factory, observability construct, Cognito. Deploy dev.
5. **IAM deploy users + DomainStack** (admin-deployed, separate apps). Then wire GitHub Actions (test gate → env deploy; cdk-diff sticky comment on infra PRs).
6. **First real service**: handlers/services/repositories layering, shared error type, JWT middleware, behavior route added. This becomes the copy-me exemplar for the rest.
7. **Async rails as needed**: SQS+DLQ+alarm per worker; EventBridge schedules; streams (two-phase deploy!).
8. **Frontends last**: Next.js static export → S3, deploy script reads stack outputs.

## Invariants (bake into the new repo's AGENTS.md)

- `handler → service → repository`; never skip layers.
- API JSON is camelCase, errors are RFC-7807 problem+json, one typed ServiceError → HTTP mapping.
- Every new `/api/*` route lands in the CloudFront behavior route table in the same PR.
- Every new AWS resource type lands in the deploy-user IAM policies in the same PR.
- Every DynamoDB key shape is documented before it's written; new shapes need an ADR.
- Every queue has a DLQ + depth alarm; every lambda gets `alarmLambda()`.
- All AWS clients init once per container (`OnceCell`); release profile keeps fat LTO.
- `clippy -D warnings` + `cargo test --workspace` gate every deploy.

## Known failure modes (learned in production — check before deploying)

1. Cross-region cert SAN changes mid-migration → ExportsWriter deadlock (`UPDATE_ROLLBACK_FAILED`).
2. New stream + consumer in one deploy → EarlyValidation rejection; use a second-phase context flag.
3. CloudFront behavior ordering: public cacheable routes before authed wildcards; signature-verified webhooks need `ALL_VIEWER_EXCEPT_HOST_HEADER`.
4. Streaming (SSE) needs all gates at once: `RESPONSE_STREAM` invoke mode + runtime env + IAM stream action + CloudFront `compress:false`.
5. Duplicate infra definitions (kept-in-lockstep mirrors) WILL drift — one source of truth per lambda's env/limits.
6. Deprecated `logRetention` prop creates unencrypted log groups — use the explicit CMK log-group factory.
7. Shared dev envs: branch deploys are transient; durable state comes from merging to the env branch.
