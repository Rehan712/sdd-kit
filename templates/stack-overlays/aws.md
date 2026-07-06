# Stack overlay: AWS

Read alongside `plan.md` when the project's stack includes `aws`.

## Conventions

- **IaC-first.** Every resource is defined in CDK or Terraform. The console is read-only in shared environments; console-created prod resources are incidents.
- **IAM least privilege:** no `*` actions or resources. Use grant helpers (`grantReadData`, `grantInvoke`) or tightly scoped statements. One role per workload; no shared roles across different blast radii.
- **Per-env isolation:** dev/staging/prod in separate accounts where possible; at minimum, separate stacks with distinct roles and zero cross-env ARN references.
- **Tagging enforced at the stack/module root** so every resource inherits: `Project`, `Environment`, `Owner`. Untagged resources fail review.
- **Secrets:** Secrets Manager or SSM Parameter Store (SecureString), referenced at deploy time. Never committed env files, never baked into images, never logged.
- **Encryption at rest everywhere** — S3, EBS, RDS, DynamoDB, SQS, CloudWatch Logs. SSE is the floor; KMS with scoped key policies for sensitive data.

## Serverless defaults

- Lambda on **arm64**; memory right-sized by profiling (memory buys vCPU).
- **SDK v3 modular clients**, instantiated once at module scope, reused across invocations.
- Small bundles for cold start; timeouts set deliberately per function.
- DLQs or `onFailure` destinations on every async invocation path; SQS consumers sized against visibility timeout.

## Observability

- Structured JSON logs with request/correlation IDs; log retention set explicitly (never "Never expire").
- Alarms defined in the same stack as the resource they watch — errors, throttles, DLQ depth, p99 latency. Infra without alarms isn't done.
- Metrics via EMF where available; tracing (X-Ray or OTel) across service hops.

## Cost awareness

- Flag anything always-on before provisioning: NAT gateways, RDS/OpenSearch instances, provisioned concurrency, idle ALBs — with a rough monthly estimate in the plan.
- Prefer scale-to-zero (Lambda, DynamoDB on-demand, Fargate Spot for batch) unless load justifies provisioned capacity.
- Budgets/alerts per account; lifecycle policies on S3 and ECR from day 1.

## Deletion safety

- Stateful resources (databases, data buckets, KMS keys): `RETAIN` / `prevent_destroy`, plus backups (PITR for DynamoDB, automated snapshots for RDS).
- Stateless dev resources: destroy-friendly policies so environment teardown is clean, not orphaning.

## Common pitfalls / smells

- `"Action": "*"` or `"Resource": "*"` anywhere, including "temporary" debugging policies.
- Secrets in plaintext Lambda env vars committed to the template.
- A resource created in the console to "unblock" and never codified — drift that bites at the next deploy.
- Missing DLQ on an async Lambda — failed events silently vanish after retries.
- Log groups with infinite retention quietly accumulating cost.
- Cross-stack circular references (A needs B's bucket, B needs A's role) — break with a shared stack or exported values.
- `cdk destroy` / `terraform destroy` on a dev stack orphaning RETAIN'd resources nobody tracks.
