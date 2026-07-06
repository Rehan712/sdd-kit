# AWS account conventions

Cross-project AWS norms. Override per-project only with explicit justification in `.specify/constitution.md`.

## Account structure

- **Per-environment accounts**: `dev`, `staging`, `prod` should be separate AWS accounts (Organizations). Where that's not feasible, separate VPCs + IAM boundary + tag enforcement.
- **Sandbox** account for experiments — destroy nightly via `cdk destroy` cron.
- **Shared services** account for artifact buckets, CodeArtifact, ECR (read-only from other accounts).

## Region

- Primary: `eu-west-2` (London) or `us-east-1` — set per-project. Document the choice in the project's constitution.
- Cross-region replication only when a spec calls for DR or geographic latency.

## Naming

- Resource names include `<project>-<env>-<purpose>`: e.g., `shopfront-prod-user-events`.
- Lambdas: `<project>-<env>-<handler-name>`.
- Stacks: `<Project>-<Env>-<Concern>Stack`.

## Tagging (required on every resource)

```
Project       = <project-name>
Environment   = dev | staging | prod
Owner         = <team>
CostCenter    = <where applicable>
ManagedBy     = cdk | terraform | manual
```

`ManagedBy=manual` should never appear in production.

## IAM

- **No `*` actions, no `*` resources** in production policies.
- Use **managed policies sparingly**; prefer scoped inline policies attached via CDK helpers (`grant*`).
- **Cross-account access via `sts:AssumeRole`** with a trust policy on the target side, not `Principal: "*"`.
- **Permission boundaries** on developer roles to prevent privilege escalation.

## Secrets

- **AWS Secrets Manager** for credentials, OAuth client secrets, third-party API keys.
- **SSM Parameter Store (SecureString)** for less-sensitive configuration.
- **Never** put secrets in environment variables in source code, CDK context, or commit history.

## Networking

- VPC per environment. Public subnets in 2+ AZs; private subnets for compute; isolated subnets for stateful services.
- NAT Gateway only if Lambdas need to call out to non-AWS hosts; otherwise VPC endpoints for AWS services.
- Security group rules: by reference (`sg-foo`), not CIDR, wherever possible.

## Observability

- **CloudWatch** for all logs (structured JSON), metrics (EMF), and alarms.
- **X-Ray tracing** enabled on every Lambda and API Gateway by default.
- **Cost anomaly detection** + budgets per project per environment.

## Deletion safety

- `removalPolicy: RETAIN` on databases, S3 buckets with prod data, KMS keys.
- `cdk destroy` on a prod stack should require explicit MFA + change ticket.
