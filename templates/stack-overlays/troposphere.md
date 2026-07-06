# Stack overlay: Troposphere (Python → CloudFormation)

Read alongside `plan.md` when the project's stack includes `troposphere` —
a dedicated infrastructure repo generating CloudFormation from Python.

## Conventions

- **Troposphere generates; CloudFormation deploys.** The Python code is a
  template *compiler* — it must be deterministic. No environment lookups, API
  calls, or timestamps at template-build time; parameterize via CFN Parameters
  or per-env config files instead.
- **One stack per deployable concern**, one module per stack. Cross-stack
  references go through `Export`/`ImportValue` (or SSM parameters), never
  hard-coded ARNs.
- **Follow the python overlay too**: uv/ruff/mypy/pytest discipline applies to
  this repo like any other Python project (`templates/stack-overlays/python.md`).
- **Generated templates are artifacts, not sources.** Either gitignore them, or
  commit them and regenerate in CI with a diff check — pick one repo-wide.
  Hand-editing an emitted `.json`/`.yaml` is a defect.
- **Naming**: logical IDs are stable identifiers — renaming one is a
  REPLACE of the resource. Treat logical-ID changes like schema migrations:
  called out in plan.md's Rollout section, never a drive-by.

## Testing expectations

- **Template snapshot tests**: render each stack with pytest and assert against
  a checked-in snapshot (or targeted assertions on Resources/Outputs). A
  refactor that changes no template must produce a zero diff.
- **Policy assertions**: tests that fail on `"Action": "*"`, missing
  encryption flags, or public S3 ACLs — the constitution's IAM/security rules,
  enforced where the template is born.
- `cfn-lint` (and `aws cloudformation validate-template` in CI) on every
  emitted template.

## Change safety

- **Always diff before deploy**: `aws cloudformation deploy --no-execute-changeset`
  (or `create-change-set` + review). The change set is the acceptance evidence
  for infra tasks — paste its summary into the task's *Evidence:* line.
- Know your **replacement triggers** (immutable properties). Anything that
  causes resource replacement gets a plan.md Risk entry with a data-migration
  story.
- **Stateful resources get DeletionPolicy Retain** (databases, buckets, tables)
  and stack-level termination protection in prod.

## Cross-repo ordering (umbrella specs)

Infra tasks in this repo land BEFORE the service/app tasks that consume the
resources (queues, tables, buckets, DNS, certs). In `tasks.md` that means the
`[repo:<infra-repo>]` tasks sit in an early stage, and consumer tasks reference
the exported names — never ARNs pasted from a console.

## Common pitfalls / smells

- Boto3 calls inside template-building code ("what subnets exist?") — that's
  drift by construction; take them as Parameters.
- One mega-module emitting one mega-stack — CFN's 500-resource limit arrives
  suddenly and the blast radius is total.
- `Ref`/`GetAtt` by string literal for a resource defined in the same module —
  use the object reference so renames are caught at build time.
- Per-environment `if env == "prod"` branches scattered through resources —
  centralize env config in one typed structure at the module edge.
