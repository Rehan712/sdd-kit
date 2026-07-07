# Scaffold, CI/CD, and operations

## Monorepo layout (new app template)

```
<app>/
├── AGENTS.md                    # canonical agent guide — conventions, invariants, checklist
├── Cargo.toml                   # cargo workspace: members = ["services/*", "packages/shared-rust"]
├── rust-toolchain.toml          # pin stable + aarch64 targets + rustfmt/clippy
├── package.json                 # root orchestration scripts (build:*, deploy:*, cdk:*)
├── services/
│   ├── <domain>-service/        # Rust lambda per bounded context (see rust-lambda-service.md)
│   │   ├── Cargo.toml           # [[bin]] name = "bootstrap"
│   │   └── src/{main.rs, handlers/, services/, repositories/, models.rs, auth.rs, error.rs}
│   └── <worker>/                # SQS/stream/schedule workers — Rust unless ecosystem forces otherwise
├── packages/
│   └── shared-rust/             # key builders, error types, validation, cross-runtime golden tests
├── apps/
│   ├── web/                     # Next.js static export → S3 + CloudFront (no SSR lambda)
│   └── admin/                   # separate admin SPA, separate distribution
├── infrastructure/
│   ├── cdk.json                 # default app → src/app.ts
│   └── src/
│       ├── app.ts               # main app: cert + waf + main + security stacks per env
│       ├── domain-app.ts        # Route53 zones (admin-only deploy)
│       ├── iam-app.ts           # per-env deploy users (admin-only deploy)
│       ├── config.ts            # env types + resolveEnvironmentConfig (domains, retention, flags)
│       ├── constructs/          # rust-lambda, database, storage, cloudfront, auth, observability,
│       │                        # websocket-api, scheduled-tasks
│       └── helpers/
│           ├── cloudfront-behaviors.ts   # THE route table — every /api/* path lives here
│           └── ssm-params.ts             # SSM-first config loader
├── scripts/                     # deploy-frontend.sh, seed-ssm-params.sh, iam/setup-deploy-profiles.sh
├── docs/                        # ARCHITECTURE.md, API.md, DYNAMODB.md, DEPLOYMENT.md, adr/
└── .github/workflows/           # deploy.yml, cdk-diff.yml, security-scan.yml
```

Rules:
- **One lambda per bounded context** (orders, billing, profiles…), not per route. A service owns its routes, table keys, and queues. 5–15 services is the sweet spot; a new route goes in an existing service unless it's a genuinely new context.
- Shared code goes in `packages/shared-rust` only when ≥2 services need it. Keep it primitives-only (keys, errors, validation) — no business logic.
- Write `AGENTS.md` from day one: directory map, layering rule, key patterns table, operational checklist. It's the highest-leverage file in the repo.

## Naming conventions (IAM scoping depends on these — do not drift)

| Thing | Pattern |
|---|---|
| CFN stacks | `{Prefix}Stack-{env}`, `{Prefix}CertStack-{env}`, `SecurityStack-{env}` |
| DynamoDB | `{prefix}-main-{env}` |
| S3 | `{prefix}-{purpose}-{env}-{accountId}` |
| Lambda log groups | `/aws/lambda/{prefix}-{env}-{Name}` |
| SQS | `{prefix}-{name}-{env}` |
| SSM | `/{prefix}/{env}/...` (secrets SecureString) |
| Cognito pool | `{prefix}-users-{env}` |
| IAM deploy users | `{prefix}-{env}` |
| Tags (app-level) | `Environment={env}`, `Project={prefix}` |

## Environments

- Start with `dev` + `prod` (add `beta` only when a real staging need appears; removing an env later is painful).
- Same account, soft isolation: per-env IAM deploy users + naming + tags (see cdk-infrastructure.md). Document the shared cfn-exec-role gap. If compliance demands hard isolation, per-env accounts with CDK pipelines — different skill.
- Everything per-env: table, buckets, pool, distributions, log groups, SSM prefix.
- Env selection: `-c environment={env}` context flag, validated in `app.ts`.
- **Shared-env discipline**: branch deploys to a shared dev env are transient — any other deploy reverts them. Durable dev state = merge to the dev branch; merge `origin/dev` into a branch before deploying it manually.

## Root scripts (npm or just)

```jsonc
{
  "build:all": "cargo lambda build --release --arm64 --workspace",   // local sanity; CDK Docker-builds at deploy
  "cdk:diff:dev":   "cd infrastructure && npx cdk diff  --all -c environment=dev  --profile {prefix}-dev",
  "cdk:deploy:dev": "cd infrastructure && npx cdk deploy --all -c environment=dev --profile {prefix}-dev",
  "deploy:dev":  "npm run cdk:deploy:dev && ./scripts/deploy-frontend.sh dev",
  "deploy:prod": "npm run cdk:deploy:prod && ./scripts/deploy-frontend.sh prod",
  "deploy:domain": "echo 'admin-only: AWS_PROFILE=<admin> npx cdk deploy --app \"npx tsx src/domain-app.ts\"'",
  "ssm:seed:dev": "./scripts/seed-ssm-params.sh dev"
}
```

Never bake an admin profile name into scripts. Per-env profiles only; admin ops demand an explicit `AWS_PROFILE=<admin>`.

## CI/CD (GitHub Actions)

### `deploy.yml` — branch → environment

| Branch | GitHub Environment | Env |
|---|---|---|
| `dev` | dev | dev |
| `main` | prod | prod |

Jobs:
1. **test (gate)**: reject committed `.env` files (with a real gitleaks config, not a no-op); `cargo fmt --all -- --check`; `cargo clippy --workspace --all-targets -- -D warnings`; `cargo test --workspace --locked`; frontend typecheck; staleness checks for any committed build artifacts.
2. **deploy** (`needs: test`, environment-scoped secrets): configure AWS creds (prefer OIDC role-assume with the same managed policies as the deploy users; else access keys mirrored to the named profile), `cdk deploy --all -c environment={env}` (+ any one-way context flags explicitly per env), then static-site deploy scripts.
- Concurrency group per env, `cancel-in-progress: false`.
- Rust caching: `actions/cache` on `~/.cargo/registry`, `~/.cargo/git`, `target` keyed on `Cargo.lock`. CI never cross-compiles the deploy binary — the arm64 build happens in CDK Docker bundling at deploy time; use `CDK_SKIP_BUNDLING=1` stubs for synth-only jobs.

### `cdk-diff.yml` — change management

On PRs touching `infrastructure/**`: run `cdk diff` against dev, post the delta as a **sticky PR comment**, flag replacements of stateful resources (table, buckets, pool). This is the change-approval gate.

## Frontend hosting

Next.js with `output: "export"` (static) → S3 + CloudFront + invalidation. No SSR lambda: rebuild-on-deploy is fine for dashboards, and it removes a whole class of infra. Deploy script reads stack outputs (pool IDs, API URL) from CloudFormation and injects them into the build. Embeddable widgets = separate vanilla-TS bundle on the same CDN.

## Operational checklist (adapt into the new repo's AGENTS.md)

Before finishing any change:
1. Flow is `handler → service → repository`; API JSON is camelCase; errors via the service-error type; responses via the shared helpers.
2. DynamoDB keys match the documented patterns — never invent a new shape without writing it into the key table + an ADR.
3. New `/api/*` path added to `cloudfront-behaviors.ts` route tables (all affected distributions).
4. New AWS resource type → matching statements added to `iam-deploy-users-stack.ts` + admin redeploy of `IamDeployUsersStack`.
5. New secret/param → SSM seed script + loader mapping updated.
6. New queue/stream consumer → DLQ + alarm wired; stream refs two-phase-deployed.
7. `cargo fmt` / `clippy -D warnings` / `cargo test --workspace` clean.
8. `cdk diff` reviewed before deploy; no surprise replacements of stateful resources.
9. Docs updated (`AGENTS.md` invariants, `docs/API.md`, ADR for any architectural decision).
