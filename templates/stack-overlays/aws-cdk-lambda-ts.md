# Stack overlay: AWS CDK + TypeScript Lambdas

Read alongside `plan.md` when `stack.yml` includes `aws-cdk-lambda-ts`.

## CDK conventions

- **CDK v2 only.** `aws-cdk-lib` package; legacy `@aws-cdk/*` v1 packages are off-limits in new code.
- **One stack per concern:** `NetworkingStack`, `DataStack`, `ApiStack`, `FrontendStack`. Don't put a Lambda, RDS, and a CloudFront distribution in the same stack.
- **Per-env stack instances:** `MyStack-dev`, `MyStack-staging`, `MyStack-prod` — distinct via `env` and `stackName`.
- **No hard-coded account/region.** Take from `process.env.CDK_DEFAULT_*` or context.
- **Snapshot tests** via `aws-cdk-lib/assertions` to catch unintended template drift.

## Tagging (enforced)

Every construct should inherit:

```ts
Tags.of(this).add('Project', '<project-name>');
Tags.of(this).add('Environment', props.env);
Tags.of(this).add('Owner', '<team>');
```

## Lambda packaging

- **esbuild via `aws-cdk-lib/aws-lambda-nodejs`** (`NodejsFunction`). No webpack, no manual zip.
- **Runtime:** `nodejs20.x` minimum. Pin explicitly — don't take the floating "latest".
- **Bundling externals:** mark large/native modules (`@aws-sdk/*`, `sharp`) as external when the runtime provides them or a Layer does.
- **Architecture:** `arm64` by default (cheaper, faster). Switch to `x86_64` only for libraries that lack arm builds.
- **Handler shape:** export a single `handler` function; one Lambda per file. Don't multiplex routes inside a Lambda — that's API Gateway's job.

## AWS SDK

- **v3 modular clients only.** `import { DynamoDBClient } from '@aws-sdk/client-dynamodb'`. Never `aws-sdk` v2 in new code.
- **Reuse clients across invocations.** Instantiate at module scope, not inside the handler.

## IAM

- **Least privilege.** Use `grantInvoke`, `grantRead`, `grantWriteData` helpers rather than hand-writing PolicyStatements.
- **No `*` in actions or resources** for production stacks.
- **One execution role per Lambda** is fine; don't share roles across Lambdas with different blast radii.

## Logging

- Structured JSON via `@aws-lambda-powertools/logger`. Include `requestId`, `traceId`, business correlation IDs.
- Log levels controlled via env var, not code changes.

## Observability

- **Powertools Tracer** (`@aws-lambda-powertools/tracer`) for X-Ray. Annotate spans with business context.
- **Metrics** via EMF (Powertools `Metrics`) — cheaper than custom metric API calls.
- **Alarms in CDK** alongside the resource they alarm on. Don't deploy infra without alarms.

## Cold start

- Bundle small; tree-shake.
- ARM64 + esbuild + minimal deps generally puts a TS Lambda under 300ms cold.
- Provisioned concurrency only for user-facing latency-sensitive paths.

## Pitfalls

- Forgetting to `addEnvironment()` after creating a resource that the Lambda needs to address (the table/queue ARN).
- IAM circular dependencies: Stack A needs Stack B's bucket; Stack B needs Stack A's role. Fix with CfnOutput → CfnParameter or a shared stack.
- `Duration.seconds(N)` confused with raw seconds — always use the helper.
- `removalPolicy` defaulting to RETAIN for stateful resources is a foot-gun if you `cdk destroy` a dev stack and orphan resources.
