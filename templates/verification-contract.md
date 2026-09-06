# Verification contract, version 1

This is the authoritative authoring grammar shared by spec, plan and task
templates and their validators. Opt in with `verification_contract: 1` in
spec.md frontmatter. Legacy specs remain readable without that marker;
warnings describe missing proof without retroactively changing shipped work.
Coverage locates declarations; independent review judges their adequacy.

## Plan definitions

Define failure modes before task decomposition. Use these table headers:

| ID | Components | Category | Trigger | Decided behavior | Test families |
|---|---|---|---|---|---|
| FM-001 | storage, handler | partial failure | Write fails after validation | Return the mapped error and release the acquired connection | storage-errors |

| ID | Scope | Promise | Enforcement sites | Test families |
|---|---|---|---|---|
| INV-001 | storage, handler | Never release an unowned connection | Shared connection guard; handler's acquisition failure path | storage-errors |

IDs match `FM-[0-9]{3}` or `INV-[0-9]{3}` and have unique definitions.
Categories are boundary, concurrency/ordering, partial failure, regression,
and state/data integrity. List every affected component in shared rows.
Triggers, decided behavior, enforcement sites and test families must be concrete,
not blank, TODO, TBD or placeholders. Table cells are single-line; escape pipes.
Refs and family lists are comma-separated exact tokens, never substring matches.

Record compact **Exclusions** as component/category plus a concrete reason.
For example: formatter / concurrency/ordering — pure synchronous transformation
with no shared state. Reuse applicable stack-overlay scenarios or explain their
exclusion; do not copy every default into every plan.

Register intended test families in the plan:

| Family | Kind | Criteria | Concrete locators |
|---|---|---|---|
| storage-errors | test | AC-001 | `tests/storage.sh::test_failed_write_releases_owned_connection` |

A locator is `repo-relative-file::literal-test-name`; multiple locators in a
family are separated by semicolons. The file and literal declaration must
exist when the implementing task is accepted, not while planning future code.
The locator is not proof that an assertion tests the criterion. Planning needs
no task IDs. At task handoff every applicable FM/INV row has a non-gate owner
with a matching named test. Missing/placeholder rows or missing ownership warn;
duplicate definitions, invalid kinds and dangling references are errors.

## Task fields and verification kinds

Every new-contract implementation task uses the fields below. A behavioral
follow-up remains an implementation task even in Reality Check or Ship;
only actual gate review and shipping administration are exempt.

| Field | Grammar / meaning |
|---|---|
| `*Refs:*` | Exact comma-separated REQ/AC and required FM/INV IDs from spec/plan. |
| `*Verify kind:*` | Exactly `test`, `assertion`, `static` or `manual`. |
| `*Tests:*` | Comma-separated concrete locators from the plan registry; manual uses its registered artifact observation name. |
| `*Verify:*` | One backtick-delimited command, optionally followed by the expected-output arrow. No literal backtick or newline inside a command; put complex checks in a repository script. Manual uses `manual: <observation>`. |
| `*Reuse:*` | Optional `local` or `never`; default `never`. Local declares deterministic, complete local inputs. |
| `*Integration owner:*` | Optional real later integration task ID for named cross-task proof. Does not defer local behavioral tests. |

`test` runs executable tests, including shell test runners. `assertion` runs a
custom executable behavioral assertion without requiring a framework wrapper.
`static` proves a criterion explicitly declared static in the plan family.
`manual` records a plan-declared human observation of an actual artifact.
Family kinds constrain task kinds: a failed automated check cannot be relabeled
static/manual to bypass execution. Split mixed automated/manual proof into
separate families/checks. Untyped AC checks offering only build, typecheck or
text-presence evidence warn; new task handoff has zero such warnings.

Tests travel with behavior: add or extend the covering test in the same task
and commit, name it in Files/Acceptance and Tests, and run it in Verify.
Tests-stage tasks retain only integration spanning tasks or stacks.

```markdown
- [ ] **T001** — Map failed storage writes and release owned connections
  - *Files:* `src/storage.sh`, `tests/storage.sh`
  - *Acceptance:* Extend the failed-write and failed-acquisition assertions.
  - *Verify kind:* test
  - *Tests:* `tests/storage.sh::test_failed_write_releases_owned_connection`
  - *Verify:* `bash tests/storage.sh` → passed, exit 0
  - *Reuse:* local
  - *Refs:* REQ-001, AC-001, FM-001, INV-001
```

## Verification command configuration

The stack.yml subset for verification accepts block lists of single-quoted
scalars, doubled single quotes for a literal quote, two-space map indentation,
and `[]` for optional empty lists. Preserve spaces, `#`, arguments and pipelines
inside scalars. Reject duplicate keys, unknown verification keys, tabs, aliases,
interpolation, multiline scalars, inline nonempty lists, malformed indentation
and unknown checkpoint stages with file:line diagnostics. Unrelated stack keys
keep their existing grammar. Never eval configuration while parsing.

```yaml
gate_checks:
  - 'bash tests/run.sh'
  - 'shellcheck -S warning -x scripts/*.sh tests/*.sh'
checkpoints:
  Backend:
    - 'bash tests/run.sh'
reuse_checks: []
verification_tools:
  - 'bash'
  - 'git'
  - 'shellcheck'
verification_inputs: []
```

New contracts require nonempty gate_checks covering the actual full suite and
mandatory static checks. Optional checkpoints use exact task-stage headings;
planning defers stage membership until real task decomposition exists. Missing
legacy configuration warns and cannot automatically clear a floor.
reuse_checks opts exact command strings into local reuse; it does not replace
gate_checks. Declare all relevant resolved tools and otherwise ignored input
paths. Unknown, external or time-dependent inputs forbid reuse in version 1.

## Runtime acceptance and freshness

Workers capture with `spec-run.sh --no-tick --summary` and return authentic
capture IDs and FM/INV-to-test mappings. Only the invoker validates and ticks
through `spec-gate.sh accept`. Explicit none is valid only for an empty required
set. Missing, forged, failed or stale proof leaves task state unchanged. Manual
acceptance validates the artifact and recorded observation without inventing a
command exit. Historical completion is preserved while current proof refreshes.

Presence is not freshness: current proof requires complete log/metadata digests,
before/after source and input identity, exact command/shell/cwd, declared tools
and hashed environment. Whole-source changes invalidate potentially affected
proof; only narrowly documented generated bookkeeping is excluded. Gates reuse
valid execution, never automatic semantic PASS, and may attack covered or
previously unexamined unchanged surfaces.

The implementation plan owns runtime interfaces and their test families:
capture/provenance, acceptance, floor/checkpoints, round reservations and report
validation. Schema examples here establish authoring intent; runtime negative
fixtures must pass before execution reuse or carried PASS rows are enabled.
