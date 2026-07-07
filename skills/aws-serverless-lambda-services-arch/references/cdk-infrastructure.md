# CDK infrastructure patterns

CDK v2 + TypeScript. One `infrastructure/` directory owns everything. Patterns proven across two production serverless platforms.

## App & stack topology

Three separate CDK **apps** (entry points) — deploy identities and DNS are never managed by the stack they enable:

| App | Stacks | Deployed by |
|---|---|---|
| `src/app.ts` (default, `cdk.json`) | Cert (us-east-1) + WAF (us-east-1) + Main + SecurityBaseline | per-env deploy user, CI |
| `src/domain-app.ts` | `DomainStack` (Route53 hosted zones, RETAIN) | admin only |
| `src/iam-app.ts` | `IamDeployUsersStack` (per-env deploy users) | admin only |

Per-environment wiring in `app.ts`:

```ts
const env = app.node.tryGetContext("environment") || process.env.DEPLOY_ENV || "dev";
// validate against the allowed env list — fail synth on anything else

const certStack = new CertStack(app, `PlatformCertStack-${env}`, { env: { region: "us-east-1" }, crossRegionReferences: true });
const wafStack  = new WafStack(app, `SecurityUsEast1Stack-${env}`, { env: { region: "us-east-1" }, crossRegionReferences: true });
const mainStack = new PlatformStack(app, `PlatformStack-${env}`, {
  env: { region: "eu-west-1" },
  crossRegionReferences: true,
  certificate: certStack.certificate,   // CloudFront needs us-east-1 cert
  webAclArn: wafStack.webAclArn,
});
mainStack.addDependency(certStack);
mainStack.addDependency(wafStack);
```

- **Cross-region pattern**: CloudFront requires ACM cert + WAFv2 WebACL in us-east-1; produce them in dedicated us-east-1 stacks, consume with `crossRegionReferences: true` on BOTH sides.
- **Security baseline stack** (KMS CMKs, CloudTrail WORM bucket, GuardDuty, AWS Backup) is admin-deployed and NOT a dependency of the main stack — it publishes its KMS key ARNs to SSM (`/{prefix}/{env}/security/data-key-arn`), and the main stack imports them with `kms.Key.fromKeyArn(StringParameter.valueForStringParameter(...))`. Clean decoupling of separately-deployed stacks.
- Tag every construct at app level: `Environment={env}`, `Project={prefix}` — the IAM deploy-user policies depend on these tags.

### ⚠️ Hard-won cross-region/stream lessons (do not relearn these)

1. **Never change a `crossRegionReferences` cert's SAN set mid-migration.** Changing SANs replaces the cert → the ExportsWriter custom resource fails with "Some exports have changed!" → `UPDATE_ROLLBACK_FAILED`. Keep SAN sets stable; recover with `continue-update-rollback --resources-to-skip`.
2. **New streams/consumers need two-phase deploys.** `AWS::EarlyValidation::ResourceExistenceCheck` rejects same-deploy references to a stream/function that doesn't exist yet. Gate second-phase wiring behind a context flag (`-c enableSecondPhaseWiring=true`), deploy the stream first, then the consumer.
3. **Define Lambda env/limits in exactly one place.** Duplicate definitions (monolith + "refactored" mirror) drift silently. If you decompose a stack into constructs, cut over — don't keep both alive.

## The Rust Lambda construct (default for all services)

`infrastructure/src/constructs/rust-lambda.ts` — a custom construct, no third-party dependency:

```ts
import { AssetHashType, Duration, aws_lambda as lambda, aws_logs as logs } from "aws-cdk-lib";

export interface RustLambdaProps {
  workspaceRoot: string;        // repo root — cargo needs the whole workspace for path deps
  cratePackage: string;         // cargo package name, e.g. "orders-service"
  functionName?: string;
  environment?: Record<string, string>;
  timeout?: Duration;           // default 10s
  memorySize?: number;          // default 512
  logGroup?: logs.ILogGroup;
}

export class RustLambda extends lambda.Function {
  constructor(scope: Construct, id: string, props: RustLambdaProps) {
    super(scope, id, {
      runtime: lambda.Runtime.PROVIDED_AL2023,
      architecture: lambda.Architecture.ARM_64,
      handler: "bootstrap",
      timeout: props.timeout ?? Duration.seconds(10),
      memorySize: props.memorySize ?? 512,
      tracing: lambda.Tracing.ACTIVE,
      environment: { RUST_LOG: "info", ...props.environment },
      functionName: props.functionName,
      logGroup: props.logGroup,
      code: shouldSkipBundling()
        ? provideStubBootstrap(id)   // CI synth without Docker: stub that `exit 1`s
        : lambda.Code.fromAsset(props.workspaceRoot, {
            assetHashType: AssetHashType.OUTPUT,   // cache keys on compiled binary, not workspace churn
            exclude: ["node_modules", "target", "cdk.out", ".git", "apps", "docs"],
            bundling: {
              image: DockerImage.fromRegistry("ghcr.io/cargo-lambda/cargo-lambda:latest"),
              user: "root",
              command: ["bash", "-c",
                `cargo lambda build --release --arm64 --package ${props.cratePackage} && ` +
                `cp target/lambda/${props.cratePackage}/bootstrap /asset-output/bootstrap && ` +
                `chmod 755 /asset-output/bootstrap`],
            },
          }),
    });
  }
}
```

Notes:
- Asset root = **workspace root** because service crates path-depend on `packages/shared-rust`.
- `AssetHashType.OUTPUT` — redeploy only when the binary changes.
- `CDK_SKIP_BUNDLING=1` gate + stub bootstrap lets `cdk synth --all` run Docker-free in CI; the stub exits 1 so it can never accidentally serve traffic.
- Memory: 512 MB default; bump to 1024 for embedding/search-style CPU-bound work. Rust rarely needs more.
- Wire IAM per function: `table.grantReadWriteData(fn)`, scoped `addToRolePolicy` for Bedrock/SSM/etc. Never a shared god-role.

### Non-Rust escape hatches (same factory file, different creators)

- **Python + Lambda Web Adapter** for AI/streaming: `PYTHON_3_11+`, LWA layer, `handler: "run.sh"` (gunicorn), Function URL `invokeMode: RESPONSE_STREAM`, `AWS_LWA_INVOKE_MODE=response_stream`. Streaming is a 4-part gate: LWA env + Function URL invoke mode + IAM `bedrock:InvokeModelWithResponseStream` + CloudFront `compress: false` on that behavior. Break one and the whole thing breaks.
- **Node/Bun** for npm-only SDK needs: prebuilt `dist/` via `lambda.Code.fromAsset`, `NODEJS_24_X`, ARM64, `NODE_OPTIONS: --enable-source-maps`. The bundle MUST write `{"type":"module"}` into `dist/package.json` and bundle everything except `@aws-sdk/*`.
- **DockerImageFunction** for headless-chromium/binary-heavy workers (x86_64 if the binary demands it).

## Log groups — CMK-encrypted factory

Never use the deprecated `logRetention` prop (it creates an unencrypted group via custom resource). Factory instead:

```ts
private makeLogGroup(name: string): logs.LogGroup {
  return new logs.LogGroup(this, `${name}LogGroup`, {
    logGroupName: `/aws/lambda/${prefix}-${env}-${name}`,  // fixed name → matches KMS key policy's encryption-context grant
    encryptionKey: this.logsKey,                            // CMK imported from SSM
    retention: env === "prod" ? logs.RetentionDays.ONE_WEEK : logs.RetentionDays.ONE_DAY,
    removalPolicy: RemovalPolicy.RETAIN,
  });
}
```

## Edge: CloudFront → Lambda Function URLs (no REST API Gateway)

Every HTTP service gets a Function URL with `authType: NONE` (auth is verified in-handler; CloudFront + WAF are the edge). Origin host extracted with `cdk.Fn.select(2, cdk.Fn.split("/", fn.functionUrl.url))`.

Two distributions: **main** (app + widget + public API) and **admin**. Static frontends are S3 origins via OAI/OAC on the default behavior; `/api/*` routes to Function URL origins.

### Data-driven behavior factory (the biggest dedup win)

Treat a CloudFront behavior as data, not 90 copy-pasted blocks:

```ts
export interface BehaviorRoute {
  path: string;                       // "/api/orders/*"
  domain: string;                     // Function URL host
  corsType: "admin" | "widget";       // domain-restricted vs allow-all response-headers policy
  compress?: boolean;                 // false ONLY for SSE/streaming behaviors
  cachePolicyKey?: "default" | "publicCacheable";  // TTL-0 auth-aware vs short-TTL public
  originOptions?: Partial<HttpOriginProps>;
}

export function buildBehaviors(routes: BehaviorRoute[], ctx: BehaviorContext): Record<string, BehaviorOptions> { ... }
export function getMainDistributionRoutes(d: ServiceDomains): BehaviorRoute[] { ... }
export function getAdminDistributionRoutes(d: ServiceDomains): BehaviorRoute[] { ... }
```

Rules that keep this correct:
- **Route order is load-bearing.** Public cacheable routes (e.g. `/api/resolve`) must be listed before the authed wildcard that would otherwise cover them; specific routes (`/api/x/*/invite`) before their wildcard (`/api/x/*`).
- Webhook receivers that verify raw-body HMAC (Stripe, Meta) need `ALL_VIEWER_EXCEPT_HOST_HEADER` origin-request policy so signature headers survive.
- **Every new `/api/*` path MUST be added to the behavior route table (both distributions where applicable) in the same change** — otherwise it falls through to the S3 default behavior and 403s. Make this a PR checklist item.
- CloudFront Functions (viewer-request) handle SPA URL rewrites, prefix strips, and 403/404 → `/404.html`.

## WebSocket (realtime only)

API Gateway v2 WebSocket ($connect/$disconnect/$default → one Lambda), `execute-api:ManageConnections` grant. Avoid the circular dependency (fn needs callback URL, route needs fn) by passing a **synth-time function-name literal** through SSM/env instead of a `Ref`.

## Observability construct

One `PlatformObservability` construct per stack:

- SNS topic `PlatformAlerts-{env}` (CMK-encrypted); optional email/Slack subscriptions guarded so a missing SSM value never fails synth.
- `alarmLambda(fn)` → Errors ≥1 and Throttles ≥5/5-min alarms on every function. Call it on **every** service.
- `alarmQueueDepth(dlq)` → DLQ visible-messages ≥1.
- `alarm5xx(distribution)` → CloudFront 5xx rate ≥5%.
- Rust/Bun services log structured JSON (`tracing` JSON subscriber); one access-log line per request with `status`, `duration_ms`, `user_id`.
- Optional OTEL: ADOT collector layer, endpoint-gated, never fatal on init failure.

## Scheduled tasks

EventBridge rules → Lambda targets in one `ScheduledTasks` construct (rate for sweepers, cron for daily/monthly jobs). Prod-only jobs (log export to S3 archive) gated on env.

## IAM deploy users (per-env, least privilege, one account)

Standalone `IamDeployUsersStack` (own app entry; admin-deployed only). Per env, one IAM user `{prefix}-{env}` with **two** managed policies (AWS caps a policy doc at 6144 chars): `-deploy-core` (CFN/STS/S3/DynamoDB/SSM/PassRole) and `-deploy-services` (Lambda/Logs/Cognito/SQS/Events/CloudFront/KMS-use/...).

Three-pronged scoping:
1. **ARN patterns** riding the naming conventions (`{Prefix}Stack-{env}-*`, `{prefix}-*-{env}-{account}`, `/{prefix}/{env}/*`).
2. **Tag conditions** `aws:ResourceTag/Environment={env}` where ARNs can't scope (Cognito, SQS, Events, CloudFront).
3. **Explicit Deny** on other envs' stack ARNs, on `DomainStack`/`IamDeployUsersStack`, and on all `iam:CreateUser/CreateAccessKey/Attach*` — defense in depth.

Accepted gap: all envs share the CDK bootstrap cfn-exec role (near-admin) — this scheme stops accidents, not insiders. Document it.

**Maintenance rule**: any new AWS resource type added to the infra requires the matching Action/Resource in the deploy-user policies and an admin redeploy of `IamDeployUsersStack`, or the next CI deploy fails with AccessDenied. Put this in the repo's operational checklist.

## Config: SSM-first

- All runtime config/secrets under `/{prefix}/{env}/...`; secrets as SecureString, plain config as String. No Secrets Manager (cost; SSM is enough at this scale).
- Synth-time loader: `GetParametersByPath` (recursive, WithDecryption) with a suffix→env-var mapping table; `.env.{env}` fallback for first-time bootstrap only; never overwrite already-set `process.env`.
- Per-tenant third-party credentials (e.g. per-tenant WhatsApp tokens) live in SSM SecureString paths, never in DynamoDB; grant services scoped `ssm:GetParameter` on exactly those paths.
