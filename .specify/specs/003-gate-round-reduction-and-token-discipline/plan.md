---
plan_for: 003-gate-round-reduction-and-token-discipline
status: implementing  # draft | accepted | implementing | shipped
created: 2026-09-04
updated: 2026-09-08
stacks: []
---

# Plan: Gate round reduction and token discipline

## 1. Approach

Make verification a small, versioned shell contract shared by existing scripts,
not another model stage. Define FM/INV and test bindings upstream; capture
worker checks without ticking; validate returns before acceptance; run a shared
deterministic floor before either independent gate. Give the opponent stable
class identities and a script-owned round ledger. Enable execution reuse and
reality-check carry-forward only after negative provenance fixtures pass.
Preserve Bash 3.2, legacy readable evidence, existing model tiers and separate
adversarial gates. Fewer rounds/spend remain measured hypotheses, not clearance
rules (REQ-001–REQ-016, CON-001–CON-008).

The spec and plan are accepted; task decomposition assigns task IDs and test
ownership in tasks.md. No implementation, global installation, private-clone
port, commit or PR is authorized by the planning/tasking phases.

## 2. Architecture

Use five component groups below; their failure modes are in §7. Modify existing
entry points in place. New files have explicit anchors; do not create a generic
workflow engine or duplicate capture logic.

| Group | Files / change | Responsibility and pattern anchor |
|---|---|---|
| A — Authoring | **New** `templates/verification-contract.md`; modify `templates/spec-template.md`, `plan-template.md`, `tasks-template.md` | One installed, authoritative grammar reference; templates link to it and show short examples. Anchor: `templates/umbrella-guide.md` for a cross-phase contract; grammar is new and specified in §3–4. |
| A — Validation | Modify `scripts/sdd-analyze.sh`, `sdd-doctor.sh`, `spec-ac-coverage.sh` | Share parsing; distinguish planning, task handoff and completed-through coverage. Keep syntactic coverage separate from proof. Anchors: existing analyzer task-block scan and AC test-file scan. |
| A — Guidance | Modify `skills/sdd-plan/SKILL.md`, `sdd-tasks/SKILL.md`, all `templates/stack-overlays/*.md`, and golden example spec/plan/tasks/README | FM/INV before tasks; behavioral tests travel with their task. Enumerate overlays from disk, not a six-stack allowlist (REQ-002–REQ-005). |
| B — Verification kernel | **New** `scripts/verification-lib.sh` | Source-only parsers, input snapshots, capture validation, locking and bounded rendering. Anchor: `scripts/lib.sh` for library conventions; `spec-resume.sh` for NUL argv, strict metadata and owner-only EXIT cleanup. Do not reuse lossy `yml_list` for commands. |
| B — Capture / acceptance | Modify `scripts/spec-run.sh`, `spec-evidence.sh`, `spec-task.sh` | Retain raw logs; add provenance and summary mode; distinguish historical completion from current proof; atomic validated tick. Anchors: existing command execution and AWK task mutation, with the atomicity correction in §4. |
| C/D — Gate control | **New** `scripts/spec-gate.sh`; modify `.specify/stack.yml` | Five public subcommands: floor, checkpoint, round, tally, accept. Read-only worktree discovery; no creation, model dispatch or waiver generation. Anchors: `spec-evidence.sh` CLI checks, `spec-resume.sh` persisted state, `spec-worktree.sh` porcelain resolver. |
| D — Independent gates | Modify `agents/opponent.agent.md`, `reality-check.agent.md` | Class sweeps, severity, canonical report schema, impact-aware reevaluation. Preserve default verdicts and independent source access (REQ-010–REQ-013). |
| A/C/D — Invokers | Modify `agents/sdd-orchestrator.md`, `skills/sdd-implement/SKILL.md`, `sdd-go/SKILL.md`, `sdd-review/SKILL.md` | Same no-tick → accept → checkpoint → floor → round protocol, including post-PR follow-ups. Replace contradictory two-failure/round-three prose; do not change model policy. |
| A — Brief consumers | Modify all `agents/*-expert.md` and `agents/test-engineer.md` | Explicit planning versus implementation mode; authoritative revisioned slices and omission handling. Existing persona structure is the anchor; gates are not implementation-brief consumers. |
| E — Docs / measurement | Modify `README.md`, `constitution.md`, `templates/retro-template.md`, `skills/sdd-retro/SKILL.md` | Explain compatibility and five commands; record class/site/usage/quality metrics. No billing integration or changes to security-reviewer authority. |
| Tests | **New** `tests/test-verification.sh`, `test-spec-gate.sh`, `test-gate-contracts.sh`; extend existing relevant `test-*.sh` and `tests/helpers.sh` | Executable isolated fixtures plus schema/adaptor checks. Anchors: `test-spec-run.sh`, `test-usage-limits.sh`, `test-golden-example.sh` and existing helper assertions. Preserve legacy non-Git fixtures; add a separate Git-backed helper. |
| Live probe | **New** `tests/probe-gate-contract.sh` | Read-only checker for AC-016 observations; fixture mode is called by `test-gate-contracts.sh`, live mode only after reports exist. Anchor: `spec-evidence.sh` artifact checks. Deliberately not named `test-*.sh`, so default suite cannot require its future first gate. |

Regenerate adapters through existing `apply-models.sh` / `build-adapters.sh`
in an isolated hub fixture; extend `tests/test-build-adapters.sh` as needed.
Do not edit `build/` or change adapter machinery. No change to dispatch,
resume scheduling, CI topology or `spec-pr.sh` is required: invokers establish
current clearance before the existing PR operation (CON-004, CON-005).

## 3. Data model

### 3.1 Versioned authoring and command grammar

The normative shipped definition is `templates/verification-contract.md`;
`verification-lib.sh` implements it. New spec templates set
`verification_contract: 1`. Absence is legacy; unknown explicit versions and
malformed declared fields are errors, not legacy fallbacks (AC-001–AC-006,
AC-011, AC-023).

Plan tables have exactly these semantic fields:

- Failure modes: `ID | Components | Category | Trigger | Decided behavior | Test families`.
- Invariants: `ID | Scope | Promise | Enforcement sites | Test families`.
- Exclusions: component/category plus concrete reason; no blank/placeholder
  behavior or test-family cells. Shared rows are valid.
- Verification families: name, kind, criteria, concrete test locator(s).
  A locator is `repo-relative-file::literal-test-name`; check the file and
  declared literal in source at implementation time, not an unrelated log.
  That locates a declaration; only review establishes assertion adequacy.
- IDs are `FM-[0-9]{3}` / `INV-[0-9]{3}`, unique definitions. Refs and family
  lists are comma-separated exact tokens. Planning requires no task IDs.
  Markdown table cells cannot contain unescaped pipes or multiline records.

This is the common FM/INV definition for REQ-002 and REQ-004; templates must
not grow a second, incompatible binding grammar.

New-contract non-gate/non-Ship task fields:

| Field | Contract |
|---|---|
| `*Refs:*` | AC/REQ and assigned FM/INV IDs; resolve against the spec/plan. |
| `*Verify kind:*` | Exactly `test\|assertion\|static\|manual`. Test = executable tests; assertion = custom executable behavioral check; static = an explicitly static criterion; manual = a plan-declared human observation. |
| `*Tests:*` | Comma-separated concrete locators from the plan family registry; manual uses an artifact observation name instead. A behavior task owns adding/extending these tests in its Files/Acceptance. |
| `*Verify:*` | One backtick-delimited command string, optionally followed by the existing expected-output arrow. No literal backtick/newline in the command; put a complex check in a repo script. Manual uses `manual: <observation>`. |
| `*Reuse:*` | Optional `local\|never`, default `never`; local explicitly asserts deterministic declared inputs. External/time-dependent checks remain never in v1. |
| `*Integration owner:*` | Optional task ID for a named cross-task criterion's final integration proof; must be a real later integration task. Does not excuse missing local tests. |

The plan family kind constrains task kind: a task cannot relabel an automated
criterion manual/static to evade a failed command. Mixed criteria use separate
families/checks, not the manual exception for the whole task. Untyped legacy
build/typecheck/text-only AC checks warn; recognized shell runners and declared
custom assertions are valid without framework wrappers. Tests-with-tasks
adequacy remains a warning with zero allowed at a new task handoff; malformed
data, duplicate IDs and dangling references are errors (REQ-005, REQ-006).

Extend stack.yml with the following small, lossless YAML subset:

~~~yaml
gate_checks:
  - 'bash tests/run.sh'
  - 'shellcheck -S warning -x scripts/*.sh tests/*.sh'
checkpoints:
  Backend:
    - 'bash tests/run.sh'
reuse_checks:
  - 'bash tests/run.sh'
  - 'shellcheck -S warning -x scripts/*.sh tests/*.sh'
verification_tools:
  - 'bash'
  - 'git'
  - 'shellcheck'
verification_inputs: []
verification_environment: []
~~~

`gate_checks` is required and nonempty for new contracts; checkpoints are
optional. The example Backend key is illustrative, not a stage to invent for
this repository. Actual keys must exactly match tasks.md stage headings.
`reuse_checks` opts exact gate/checkpoint strings into local deterministic
reuse; it does not replace either command list. The task-local equivalent is
`*Reuse: local*`. The tool list above is illustrative: each project must
declare the relevant external tools for its commands; include their resolved
paths/content identities. `verification_inputs` adds otherwise ignored inputs.
Missing/incomplete input/tool declarations make validity unknown, not reusable.

Accept block lists of single-quoted scalars, doubled single quotes for a quote,
two-space map indentation, and `[]` for optional empty lists. Preserve spaces,
`#`, arguments and pipeline operators inside scalars. Reject duplicate keys,
unknown verification keys, tabs, aliases, interpolation, multiline scalars,
inline nonempty lists, bad indentation and unknown checkpoint stages with
file:line diagnostics. Unrelated existing stack keys retain existing parsing.
Never `eval` configuration as shell during parsing; execute only the declared
command at the check boundary. Document this restricted subset (AC-011).
Plan mode validates syntax but defers checkpoint stage membership until the
active spec has a real task decomposition; a scaffold is not a stage inventory.

### 3.2 Captures, acceptance and input identity

Add immutable `notes/captures/CAP-<unique-id>/` directories and append readable
references to the existing `notes/evidence.md`. Historical blocks are untouched.
Use `mktemp -d` for unique staging directories inside the final parent.

| Artifact | Required contents |
|---|---|
| `meta.nul` | Version 1, capture ID, monotonic ledger sequence, kind (command/manual), start/end UTC, repo/cwd, check identity, shell identity, input-before/input-after, no-tick flag, exit (command only), output digest/bytes, freshness policy. Strict unique known key/value NUL pairs. |
| `argv.nul` | Exact NUL-separated argv for commands; no display-string reparsing. |
| `inputs.nul` | Versioned fixed-arity records for paths/content/mode/link/index state, semantic documents, environment and tool identities. Hash framing includes record kind and lengths/NUL boundaries. |
| `bindings.nul` | Exact criterion/FM/INV/test/Verify bindings derived from current plan/tasks, not submitted by the worker as claims. |
| `output.log` / `summary.txt` | Full combined stdout/stderr and the canonical bounded display. Manual observations instead name the actual artifact, its digest, observer, observed UTC and observed result; there is no invented exit 0. |
| `COMPLETE` | Schema version and SHA-256 digests of all required files. Written last before same-parent directory rename; a missing/malformed marker is never evidence. |

The serialized verification ledger under `notes/verification/` records capture
sequence, check/input identity and outcome, accepted-return receipts, floor and
checkpoint records, and their artifact digests. It is script-owned data, never
sourced as shell. Ledger/capture disagreement fails closed. This is an integrity
protocol inside the existing trusted local workspace, not protection against an
actor able to rewrite all scripts and evidence with the user's permissions.
Accept records rejection as well as success: return digest, reason, capture IDs
and before/after full tasks.md digests. AC-016 consumes these real script records,
not an invoker-written assertion that the rejected task file was unchanged.

Identity rules (REQ-009, AC-013, AC-020):

1. Use full SHA-256 via existing `shasum -a 256` or `sha256sum`. No shortened
   output hash or cksum fallback can authorize reuse; unavailable SHA-256 means
   no reusable new-contract proof and a named prerequisite failure.
2. Snapshot all tracked plus nonignored untracked source, with staged and
   working-tree content, deletion, mode and symlink identity. Also snapshot
   declared ignored inputs. Resolve repo/cwd physically; record the actual
   worktree, not merely branch/HEAD. Preserve unusual filenames using Git's
   NUL output; no line-based filename splitting or GNU-only `sort -z`.
3. Hash semantic spec/plan/tasks content, including AC text, decisions, Verify,
   kinds, bindings and integration owners. Exclude only documented bookkeeping:
   checkbox state, generated Evidence fields, status/updated fields and the
   verified spec's OWN explicitly generated capture/report/ledger paths.
   Another spec's copies of those paths are ordinary inputs (a shipped report
   is a fixture), and a declared input reaching the verified spec's own
   generated paths is refused by name. STATUS Decisions remain
   inputs. Do not exclude all Markdown, .specify, notes or ignored files.
4. Snapshot a declared environment set as hashes (never persist raw secrets).
   Membership is EXACTLY the project's `verification_environment` list of shell
   identifiers -- no fixed names beside it. Preserve present/unset distinctions
   for declared names; ignore undeclared session settings, including the LC_*
   family, whose membership must not be read from the ambient process.
   Projects must declare additional variables their checks depend on.
   Snapshot shell and declared resolved tool binaries; those records pin tool
   identity, so PATH itself is not hashed.
   Unknown external dependencies mean no reuse. No dependency-graph inference
   or external TTL policy is implemented in v1.
5. Compare snapshots before/after execution and again at acceptance/gating.
   Changed-during-run is invalid even if command exit is zero. A later failed
   capture for the same check+inputs supersedes an earlier success.
6. Recompute log/metadata integrity on every reliance. A matching filename,
   commit, output digest alone, old schema or missing provenance is insufficient.
   Whole-source is the only v1 impact mode: any semantic source/input change
   conservatively invalidates all potentially affected checks and PASS rows.

The command cache key is exact argv/command string + resolved shell + physical
repo/cwd + input identity + validity policy. Task IDs and display key selection
are not execution identity. Share a run only where its stored binding catalog
covers the required test/criterion binding; identical text in unrelated logs
does not qualify. New task bindings change semantic inputs (AC-007, AC-022).

An acceptance receipt names task ID, return digest, semantic task revision,
capture IDs and binding digest. An intact committed receipt for the exact return
and an already checked task returns `already-accepted` before currency validation,
without rewriting tasks.md or auditing drift as a rejection. This acknowledges
historical acceptance, never current proof. Stale historical
acceptance never unticks or reimplements a task: refresh current verification,
record its current proof separately, and preserve the historical receipt.

For never/unknown-policy checks, a worker capture proves only that observed
execution: it cannot satisfy a later floor, resume or review invocation. Those
invocations execute again. Initial acceptance validates the current task/input
snapshot and recorded observation; it does not claim continuing external truth.

### 3.3 Canonical gate and coverage records

Keep the familiar append-only `notes/opponent.md` and
`notes/reality-check.md` as canonical reports; use exact top-level round
blocks, not arbitrary heading counts. New blocks start `## Round <integer>` and
end `<!-- gate-round-end: <gate>:<integer> -->`. They have `**Round:** <integer>`,
`**Timestamp:** <UTC>`, `**Source:** <input-id>`, `**Floor:** <floor-id>`,
verdict and completion marker. Parse outside quoted content only, where the
quoted set is DERIVED from the CommonMark HTML-block start conditions rather
than enumerated: fences, blockquotes, indented code, and conditions 1-5
(`<script`/`<style`/`<textarea`/`<pre`, `<!--`, `<?`, `<!`+letter, `<![CDATA[`).
Conditions 6 and 7, `<details>` included, render visibly and are records.
The verification ledger reserves the granted number and records the completed
block digest; incomplete/duplicate/mismatched data stops further invocation.
The legacy reader recognizes the initial report plus later Round headings in
the shipped format, validates their verdict/date context and never rewrites them.

Opponent findings have stable finding IDs, `Class: lowercase-hyphen-slug`,
`Root cause: plan-gap|spec-gap|implementation-error`, severity,
`Reproduced:`, triggering input, all file:line locations, prior finding ID(s)
and status (`new|open|resolved|reopened`). Include blocking/minor and raw location
counts, searched sibling sites, attacked surfaces and unexamined extent.
Resolved claims require the finding's OWN ID: either that ID appeared in an
earlier round of this gate, or that same ID appears in a declared prior-review
manifest. `Prior` is recorded for the reader and never carries the claim, so no
value of it can resolve a brand-new finding -- binding to a prior ID, and then
to one of the same recorded Class, each failed because both are fields the
report's own author writes. Prior-review manifests resolve under the spec's
notes/verification/reports directory for canonical and temporary report paths
alike. Report comments respect code indentation and
raw closers; unterminated comments are errors. Any nonblank content after a
completion marker and before the next real round heading is an attribution error,
including quoted content.
Persist IDs across rechecks. Legacy reports have no inferred Class (AC-010).

Each reality-check AC row records criterion text/revision, result, evidence
capture(s), impact mapping, reviewed input identity and origin (`evaluated`
or `carried (round n)`). Every AC appears in every round. In v1 the impact
mapping is the conservative whole-source manifest; no-change rows may carry,
but any unknown/changed transitive input requires reevaluation. A valid capture
permits execution reuse, not automatic semantic PASS (AC-013).

A checkpoint ledger stores stage, completed task set, AC/FM/INV/test bindings,
acceptance references, integration owners, source and command captures. Compare
against both current completed-through requirements and the last established
binding set. A floor records its complete required-check set and captures under
`## GATE-FLOOR <id>` in evidence.md. These records are integrity-checked
bookkeeping, not substitutes for their underlying logs (AC-007, AC-008).

## 4. API / contracts

No network API, model-policy or provider API changes. The additive CLI contract
is below; errors are bounded and name a recovery action.

### 4.1 Public script seams

| Command | Behavior |
|---|---|
| `sdd-analyze.sh <spec-dir> --phase plan\|tasks` | Explicit phase override, otherwise STATUS phase. Plan mode checks spec/plan only, without task numbers or missing future tests. Tasks and later require bindings; existing full checks remain. |
| `spec-ac-coverage.sh <spec-dir> --through-stage <stage>` | Completed-through AC/FM/INV binding check using actual task ownership and prior checkpoint state. Without the flag retain full AC behavior; reuse existing repeatable `--root` for resolved worktrees. |
| `spec-run.sh <spec-dir> <task> --from-task --no-tick --summary` | Resolve exact typed Verify and its bindings; execute command through resolved Bash with pipefail. New convenience mode cannot be combined with argv after `--`. |
| `spec-run.sh <spec-dir> <task> --no-tick --summary -- <argv...>` | Existing argv execution remains as-is. A new-contract acceptance requires argv to match its declared Verify execution; no shell reparse. `--key` remains only a key selector. |
| `spec-gate.sh accept <spec-dir> <task> <return-file>` | Validate return, captures, bindings and current inputs; call `spec-task.sh done` through the validated-return path below. Reject before any checkbox/evidence change. |
| `spec-gate.sh floor <spec-dir>` | Recheck analyzer/AC coverage/evidence integrity, refresh stale required task checks, and run/reuse every gate_check. Return current floor ID only when all required proof is valid. |
| `spec-gate.sh checkpoint <spec-dir> <exact-stage>` | Run/reuse stage commands and completed-through coverage delta; no commands is explicit, not a skipped coverage check. |
| `spec-gate.sh round <spec-dir> <opponent\|reality-check> [--floor <id>]` | Validate prior canonical records and authorization; atomically reserve the next round. A fresh floor is mandatory for a new-contract reservation. This is the pre-invocation operation, not a harmless preview. |
| `spec-gate.sh round <spec-dir> <gate> --complete <report-file>` | Validate pending round identity, full report schema and floor; append atomically and close reservation. Do not require a clearing verdict: CHALLENGED/NEEDS WORK are completed reviews too. |
| `spec-gate.sh round <spec-dir> <gate> --reconcile <record-file>` | Explicit recovery only: finish a recovered valid report or record an interrupted invocation as BLOCKED/FAILED, preserving its consumed number. Never silently discard/reset it. |
| `spec-gate.sh tally <spec-dir>` | Read-only rounds/findings/sites/class/recurrence/execution/reuse counts; unclassified/unknown explicit. Cap refusal includes recurring-class summary and suggested sibling sweep. |
| `tests/probe-gate-contract.sh <spec-dir>` | Check actual AC-016 capture/rejection/acceptance/floor/round artifacts after gates exist; missing evidence fails. Fixture tests invoke it on sandboxes. |

Floor/checkpoint run commands as `<resolved-bash> -o pipefail -c <exact-string>`
in each declared repository's existing worktree; commands are not piped to tail.
Single-repo resolution checks STATUS/worktree identity. Umbrella resolution uses
the existing declared repos/system-map and read-only Git worktree porcelain
lookup; missing or ambiguous worktrees fail, never fall back to a main checkout.
Each repository supplies its own gate_checks. No model starts until command
status and source stability are known.

For gate commands: 0 = valid success, 2 = usage, 3 = contract/integrity gap,
4 = additional-round authorization denied; a command failure propagates its
actual nonzero exit from run/floor/checkpoint, with a typed reason in the summary
to disambiguate overlapping numbers. Malformed existing rounds return 3.
Do not replace a real command failure with a formatting/cleanup success.

### 4.2 Return and acceptance transaction

Automated worker returns use this bounded, parseable block; surrounding narrative
is optional and is never evidence:

~~~text
Verification-Return: 1
Task: <exact task ID>
Captures: <comma-separated capture IDs>
Summary: <canonical summary for each capture, repeated field allowed>
Failure modes:
<FM/INV ID>, <concrete test locator>, <capture ID>
~~~

Require exactly the task's assigned FM/INV set, no duplicate/extra/missing IDs;
allow several rows per ID for required cases. If that set is empty, require
`Failure modes: none`, but still validate the task's automated checks.
The normal return is 3–5 mapping lines; do not truncate a larger required set to
meet that budget. Splitting an overlarge task belongs in decomposition.

For a plan-declared manual family, use `Manual observation:` plus artifact path,
artifact digest, observer, observed UTC and observed result. The invoker validates
the artifact/observation and publishes the manual record under the same lock.
A free-form summary or failed automated capture cannot enter this branch.

`spec-task.sh done <spec-dir> <task> --return-file <file>` is the internal
validated-return seam used by accept. It acquires the shared verification lock,
calls the common return validator, rechecks current source/tasks, then stages
checkbox + Evidence + updated date in one same-directory temporary rewrite.
Publish the receipt before that one rename; on an interrupted transaction,
receipt/task mismatch is explicitly pending and reconciled on retry.
The prepared receipt stores full tasks.md before/after digests: matching before
allows a freshly revalidated retry, matching after completes bookkeeping only,
and neither matching refuses recovery until concurrent edits are reconciled.
Do not use today's TMPDIR rename followed by a second fm_set write.
New-contract non-exempt done requires this seam; legacy --evidence behavior
and gate/Ship exceptions remain compatible. Invalid returns leave tasks.md
byte-for-byte identical, including frontmatter (AC-022).

All verification writers use one spec-local mkdir lock with owner identity,
assigned only after successful acquisition and released only by its owner's
single EXIT trap. Signals exit through that cleanup. A preexisting/stale lock
is a named recovery condition, never unconditionally removed. The capture runner
publishes and releases before acceptance obtains its own lock; no nested lock
or trusted environment-variable bypass. Legacy auto-tick runs after release.
New-contract task start/undo mutations also take this lock; they cannot race an
acceptance rewrite. They do not gain a way to bypass validated done.

Parallel workers may edit independent tasks, but the invoker closes the editing
batch before serial capture/acceptance. No writer starts another source edit
until the verification barrier finishes. Locks serialize metadata, not arbitrary
editors; before/after/current snapshots detect accidental concurrent edits.
A changed snapshot rejects/refreshes proof, not silently accepts it (CON-008).

### 4.3 Floor, rounds and incremental review

For each floor, cheaply build/validate current bindings and integrity, select
stale completed-task checks without changing historical completion, execute
missing/invalid checks plus gate_checks, then validate current evidence.
Run each distinct reusable command identity once across that catalog. Do not
assume that an unrelated green full suite proves a task's custom Verify.
Analyzer, coverage and mutable evidence integrity are reevaluated before each
gate even when the suite is reused.

After each stage's last completed batch, checkpoint validates completed tasks,
retained prior bindings and explicit later integration owners. Gate/Ship task
exceptions do not exempt their behavior-changing follow-ups. Failure prevents
the next-stage dispatch. Pending future ACs are not current coverage gaps.
These are the required floor and optional checkpoint contracts respectively
(REQ-007, REQ-008); checkpoint configuration never substitutes for gate_checks.

Gate invocation order is floor → round reservation → independent model →
round completion → disposition. The two gates share valid captures, not verdicts.
On acceptance failure, supply the specific uncovered/invalid row and re-dispatch
once at the existing escalation tier; second failure stops without ticking.
On CHALLENGED, brief one task per established class where feasible, listing
all known locations and a sibling sweep. Review preserves affected consumers,
unexamined extent and expansion on new evidence, including unchanged code.
Only reproduced defects, or concrete trigger plus file:line, in data-loss,
wrong-result, regression or crash block. Other findings stay minor unless an
AC/REQ names that behavior/document/claim; then violation is wrong-result.
Missing proof still blocks through the floor/reality-check (REQ-010, REQ-011).

A Decisions authorization has exactly this single-line field grammar:

~~~text
- <YYYY-MM-DDTHH:MM:SSZ> — waiver: gate=<opponent|reality-check>; round=<n>; after=<n-1>; by=<user>; reason=<text>
- <YYYY-MM-DDTHH:MM:SSZ> — spec-revision: gate=<gate>; round=<n>; after=<n-1>; by=<user>; revision=<accepted revision ref>; reason=<text>
~~~

Fixed labels, semicolon-separated fields, no newline/semicolon inside a value.
The timestamp must be later than the preceding completed/reconciled invocation,
and the entry must record explicit user authorization. The script checks
structure/order, not the human's identity through an external service; the
invoker may never author a waiver on the user's behalf. Each entry permits only
that gate/round. Legacy date-only rounds need a timestamped reconciliation record
identifying the old report digest before ordering an authorization. Interrupted
reservations must be reconciled even below the cap. A cap is not clearance.
Validate real calendar/time values before lexical UTC ordering; malformed dates
must not become an authorization merely because their strings compare later.

Reality-check prepares the full AC matrix and prior manifest/diff, including dirty
and untracked files. Evaluate every FAIL/MISSING and invalidated/uncertain row.
A same-input PASS may carry only after criterion and capture integrity checks.
For v1 whole-source manifests, a changed shared helper can invalidate every row;
prefer this safe false miss to an unsound partial dependency guess (REQ-013).

### 4.4 Internal seams — shared library interfaces

Use functions, arrays and fixed-arity NUL files, not associative arrays, JSON
tools or shell-sourced metadata. Public constants: `VF_SCHEMA=1`,
`VF_SUCCESS_BYTES=2048`, `VF_FAILURE_BYTES=8192`, `VF_DIAGNOSTIC_LINES=20`.

| Function signature in verification-lib.sh | Result / ownership |
|---|---|
| `vf_config <stack-file> <tasks-file> <output-dir>` | Parse/validate command and stage catalogs into NUL files; never execute them. |
| `vf_bindings <spec-dir> <plan\|tasks\|through-stage> <stage-or-empty> <output-file>` | Emit exact typed binding catalog; report phase-appropriate errors/warnings. |
| `vf_snapshot <spec-dir> <repo> <cwd> <output-file>` | Write canonical whole-source manifest; print its full digest; nonzero if no reliable identity. |
| `vf_capture <spec-dir> <binding-file> <cwd> <policy> -- <argv...>` | Execute once, preserve actual exit, publish complete immutable capture and ledger entry under lock. |
| `vf_capture_check <spec-dir> <capture-id> <current-manifest> <integrity\|current\|reuse>` | Explicit predicate; return reason on mismatch. Current additionally checks freshness; reuse additionally requires local policy. |
| `vf_return_check <spec-dir> <task> <return-file> <output-receipt>` | Pure validation into a staged receipt; no task mutation. Caller holds lock and commits via spec-task. |
| `vf_lock <spec-dir>` / `vf_unlock` | Single owned lock; never release another process's lock; one cleanup trap per writer entry point. |
| `vf_summary <record-dir> <success\|failure>` | Canonical escaped display from disk; byte/line limits apply to total stdout+stderr. |

With --summary, emit one success line with capture/command/key/exit/output digest/
input/log. On failure emit that summary plus at most 20 diagnostic lines and
8 KiB total. Escape multiline/control bytes, truncate only display fields with
metadata pointers, preserve full logs. Existing default verbosity and --key
selection remain unchanged. Floor/checkpoint/accept aggregate subordinate output
to the same limits and identify execution versus cache hit (AC-021).

## 5. Dependencies

No new package, service, IAM permission or runtime dependency. Bash 3.2, Git and
existing BSD/GNU-compatible tools suffice; SHA-256 is already available through
the runner's supported tools. Missing required tools produce a named failure,
not fabricated evidence. Do not add jq, yq, Python, GNU-only utilities or a
language-independent dependency resolver (CON-001).

Verification uses the existing Linux/macOS Bash matrix and warning-level
ShellCheck command. Fixture commands use isolated sandboxes/provider stubs.
No live scheduler/provider call belongs in the regression suite (AC-019).
AC-019's platform claims need actual execution evidence before READY; the
current workflow triggers on PRs/main, so a local pass cannot stand in for a
not-yet-run remote matrix. If no authorized platform executor is available,
implementation pauses for an execution route rather than opening an unapproved
early draft PR or relaxing the criterion. Ordinary PR CI remains a merge gate.

## 6. Stack overlay notes

This project declares `stacks: []`: no overlay or matching stack expert applies
to its own Bash/Markdown implementation. Preserve that declaration and add its
real shell gate_checks; no invented Backend/API stage requirement.

Update all 14 currently shipped overlays: aws, aws-cdk-lambda-ts, bun-monorepo,
expo-rn, firebase-rtk-codegen, javascript, loopback4, monorepo, nextjs, python,
react, rust, rust-aws-lambda and troposphere. Tests enumerate the directory so a
new overlay cannot silently escape the default requirement (AC-002).
This directory-wide requirement implements REQ-003, not only its six examples.

Defaults are scenario prompts, not copied rows: Rust errors/panics/ownership;
Lambda retries/timeouts/cleanup; Next.js server-client/auth/cache boundaries;
CDK IAM/removal/environment contracts; JavaScript async errors/input handling/
state; React effects/stale state/error boundaries. The other overlays get equally
relevant failure and stage-check advice. Each of the six named core stacks has
at least three scenarios. Planning fills or explains exclusion of applicable
defaults, then selects the project's actual suite/static gate commands.
For REQ-014, each expert/test-engineer example also labels its role mode and
source revision: planning proposes decisions; implementation consumes supplied
slices, requests missing/conflicting context and follows higher-priority rules.

## 7. Risks, failure modes and verification

Highest risk is a false reusable PASS; mitigate with whole-source invalidation,
fresh integrity checks and failure-first fixtures before enabling reuse.
Next are capture/acceptance races and damaged round state; use serialized
transactions, owner-only cleanup and fail-closed recovery. Parsing drift is
contained by one grammar/library and golden fixtures. Overly conservative cache
misses are acceptable and measured; do not optimize away inputs to hit targets.

### Failure modes

Categories: boundary, concurrency/ordering, partial failure, regression, state/data
integrity. Families resolve in the verification registry below; tasks bind them
later. Shared rows list every affected component group.

| ID | Components | Category | Trigger | Decided behavior | Test families |
|---|---|---|---|---|---|
| FM-001 | A, E | boundary | Missing/duplicate IDs, placeholder rows, bogus test kind or dangling Ref | Phase-aware warning/error; no fake binding from an ID mention | authoring, guidance |
| FM-002 | A, E | regression | Legacy/golden spec or regenerated adapter loses its contract | Legacy analyzer stays green; golden/new examples have zero warnings; modes retained | authoring, guidance |
| FM-003 | A | concurrency/ordering | Plan has no tasks yet; local tests deferred to future Tests task | Planning valid without task numbers; task handoff rejects gaps and warns on deferred local proof | authoring |
| FM-004 | A | partial failure | Worker brief omits/conflicts with an existing decision | Supply missing slice first; new decision returns to plan; bounded escalation | guidance, wiring |
| FM-005 | A, B, E | state/data integrity | Spec/plan/Verify changes after briefing/capture | Refresh brief and proof; manual/static relabel cannot bypass automated criterion | provenance, acceptance, reports, guidance |
| FM-006 | B, C | boundary | Spaces/quotes/pipeline/control bytes/large output or wrong return IDs | Lossless execution; exact binding validation; bounded escaped display with raw log | capture, config, acceptance |
| FM-007 | B, C, D | concurrency/ordering | Competing writers, foreign lock, edit during verification | Owner-only lock cleanup; stable batch barrier; changed-input proof refused | provenance, transactions, wiring |
| FM-008 | B, C | partial failure | Nonzero command, signal, disk/publish failure, incomplete capture | Preserve command exit; no complete proof/tick; retain diagnosable interrupted state | capture, transactions |
| FM-009 | B | regression | Existing --key/default argv/no-tick or legacy done usage | Preserve legacy semantics; summary additive; new non-exempt tick uses acceptance | capture, acceptance |
| FM-010 | B, D | state/data integrity | Tampered/old log, stale source/tool/env, later failed run, forged return | Integrity/freshness checked independently; reject reuse/current PASS and invalid acceptance | provenance, acceptance, reports |
| FM-011 | C | boundary | Missing gate list, malformed YAML, unknown stage or wrong worktree | Named configuration failure; legacy warning does not clear floor; no main-checkout fallback | config, floor |
| FM-012 | C | concurrency/ordering | Same command across stages/gates/repos; stage not finished | Only exact valid identity deduplicates; checkpoint runs after completed batch | floor, checkpoints |
| FM-013 | C | partial failure | Checker/checkpoint/pipeline fails | Real nonzero exit, gate/next-stage invocation count remains zero | floor, checkpoints, wiring |
| FM-014 | C | regression | Bookkeeping-only updates or unknown/time-dependent input policy | Recheck integrity; reuse only local valid suite; unknown/external runs again | provenance, floor |
| FM-015 | C | state/data integrity | Completed binding removed; future AC or spanning criterion pending | Detect lost prior coverage; recognize explicit later integration owner without excusing local tests | checkpoints |
| FM-016 | D | boundary | Quoted, duplicate, malformed, date-only report or wrong authorization | Count canonical records; fail closed; require exact ordered/reconciled authorization | rounds |
| FM-017 | D | concurrency/ordering | Two round reservations or waiver for another gate/round | Serialize one reservation; deny unintended invocation including round 5 after waiver 4 | rounds, transactions |
| FM-018 | D | partial failure | Gate interrupted or first-report live observation not yet possible | Reconcile consumed round; keep live probe out of pre-gate suite; missing later proof prevents READY | rounds, wiring |
| FM-019 | D, E | regression | Class moves file/root cause; covered/unchanged surface reveals defect | Stable class/prior IDs, raw sites and retained review scope; no weakened severity | reports, guidance |
| FM-020 | D, E | state/data integrity | Old PASS, missing AC row, incomplete impact or absent spend/quality baseline | Reevaluate unsafe rows; every AC recorded; metrics unknown, never invented | provenance, reports, guidance |

Exclusions: A/E have no runtime request-serving/data-store component. E's
boundary/ordering cases use the shared authoring/adaptor schema and revision
checks (FM-001/002/005); no new publication mechanism is introduced, so E's
partial-write recovery remains the existing generation/sync behavior. Its
regression/metrics state shares FM-019/020 rather than duplicate rows.
External provider reliability is not simulated as a reusable local fact; such
checks are non-reusable. Security review is unchanged, not excluded from shipping.

### Invariants

| ID | Scope | Promise | Enforcement sites | Test families |
|---|---|---|---|---|
| INV-001 | B, C, D | A relied-on automated PASS has complete, successful, matching real evidence | Shared vf_capture_check at acceptance, floor, resume and carry evaluation | provenance, acceptance, floor, reports |
| INV-002 | B | An invalid return does not alter task state; valid retry is idempotent | spec-task validated-return transaction with one final tasks rename | acceptance, transactions |
| INV-003 | B, C, D | Cleanup releases only acquired ownership; half-writes are not completed state | vf_lock/vf_unlock and COMPLETE/pending transaction validation | transactions |
| INV-004 | C, D | No gate/next stage is invoked after failed floor/checkpoint or denied round | Common invoker sequence; stub and live observation counters | floor, checkpoints, rounds, wiring |
| INV-005 | A, D | Coverage/reuse never exempts semantic review or hides a criterion | Typed family binding plus opponent scope and full reality-check matrix | authoring, reports, guidance |
| INV-006 | E, D | Fewer grouped findings/rounds do not manufacture savings or quality | Tally counts raw sites/recurrence; retro uses actual or unknown measurements | reports, guidance |

### Verification registry and AC coverage

These are test families, not task assignments. Each locator names an intended
test function; implementers add that function and its cases alongside behavior.
All families below are executable `test` kind; source-text assertions in guidance
prove only static requirements, not runtime wiring. Runtime claims use counters,
exit/byte measurements and unchanged-file comparisons.

| Family | Kind | Criteria | Concrete locators |
|---|---|---|---|
| authoring | test | AC-001, AC-003, AC-004, AC-005, AC-006, AC-011, AC-023: phase modes, shared/excluded rows, malformed/dangling IDs, kinds, same-task tests, zero-warning golden, untouched 001/002 exit 0. | `tests/test-sdd-analyze.sh::test_verification_bindings`; `tests/test-golden-example.sh::test_verification_golden` |
| config | test | AC-011, AC-023: actual stack commands, malformed/unknown/duplicate map keys, spaces/quotes, doctor/analyzer consistency, new versus legacy. | `tests/test-verification.sh::test_config_grammar` |
| capture | test | AC-019, AC-021: actual verbose success/failure, byte/line bounds, full-log digest, argv/key/default/no-tick compatibility, real exits including pipeline. | `tests/test-spec-run.sh::test_bounded_capture` |
| provenance | test | AC-013, AC-020, AC-023: source/staged/dirty/untracked/test/fixture/lock/config/tool/env/cwd/command snapshots and capture currency; tamper/truncation/old format/later failure/during-run; unchanged hit, bookkeeping hit, volatile miss; old failing-test/sound-evidence repro. Real transitive-helper and criterion-text saved-success/PASS cases are exercised in reports. | `tests/test-verification.sh::test_capture_provenance` |
| transactions | test | AC-020, AC-022: owned/foreign/failed-acquisition cleanup, concurrent publications, interruptions before/after each commit point, retry/pending recovery, tasks byte identity. | `tests/test-verification.sh::test_owned_transactions` |
| acceptance | test | AC-022: missing/extra/duplicate/none mapping, unknown locator/capture, forged summary, failed/stale/changed-source return, valid once/idempotent, artifact-backed manual and automated-bypass refusal. | `tests/test-spec-gate.sh::test_acceptance` |
| floor | test | AC-007: all three checkers and all gate commands observed, correct repo/cwd, fresh integrity each call, one unchanged suite across gates, source/command/cwd invalidation, missing config stop. | `tests/test-spec-gate.sh::test_floor` |
| checkpoints | test | AC-008: real failure codes, no commands with delta, removed completed/prior bindings, pending future and explicit integration owner, checkpoint-to-floor reuse, next-stage counter zero. | `tests/test-spec-gate.sh::test_checkpoints` |
| rounds | test | AC-009: both gates 1–3/denied 4, same-day exact waiver/revision, reject old/unscoped/wrong gate/round, round 5 still denied, quoted headings, malformed/duplicate/pending/date-only reconciliation. | `tests/test-spec-gate.sh::test_rounds` |
| reports | test | AC-010, AC-012, AC-013, AC-017, AC-020: full schema/matrix; saved-success/PASS invalidation for consumed source/helper/fixture/lock/config and actual criterion text; stable prior IDs and class recurrence across files/root causes, open recheck not recurrence, raw sites/unknown data; untouched 002 five rounds/six blockers/unclassified, annotated copy detects clock and lock recurrence. | `tests/test-gate-contracts.sh::test_reports_and_tally` |
| guidance | test | AC-001, AC-002, AC-004, AC-006, AC-012, AC-014, AC-015, AC-017, AC-018: enumerate overlays/personas, modes/revisions/omissions, retained gate scope/severity, metrics fields, docs/help and executable examples, regenerated adapters. | `tests/test-gate-contracts.sh::test_instruction_contracts`; `tests/test-build-adapters.sh::test_brief_modes` |
| wiring | test | AC-015, AC-016, AC-019: stub workers/gates exercise actual scripts, incomplete return unchanged then accepted once, floor/cap stop counters, stage barrier, shared gate suite; live-probe positive/negative fixtures without a future-report dependency. | `tests/test-gate-contracts.sh::test_invoker_protocol` |

Cross-cutting Tests-stage work may compose these already-shipped local fixtures
and run the compatibility matrix; it must not own all local negative cases after
their behavior tasks. AC-016 additionally needs the actual observations in §8;
a green stub fixture alone never satisfies the live requirement. AC-019 runs
`bash tests/run.sh` and `shellcheck -S warning -x scripts/*.sh tests/*.sh`
under the existing CI Bash matrix; a local shell alone cannot claim that matrix.
The golden test supplies its new-contract project/config in its sandbox; do not
retrofit the shipped 001/002 artifacts to make the new example fixture pass.

## 8. Rollout

Implement in dependency order; /sdd:tasks will assign small commit-sized tasks,
not one task per large table row (CON-008):

1. Land contract/templates/bindings/analyzer/config grammar and their tests.
   Land class/report/brief changes and bounded captures with their local tests.
2. Land validated acceptance, owned transactions and floor/checkpoint/round
   mechanics with **reuse and carry-forward disabled**. Execute fresh checks;
   do not yet instruct invokers to trust a cache.
3. Land whole-source provenance/invalidation fixtures; only after they pass,
   enable local opt-in reuse in the shared validator and matching carry rules.
   `never` remains the default for undeclared/uncertain commands.
4. Wire implement/orchestrator/go/review and regenerate/test adapters. Add the
   non-gate AC-016 probe checker with fixture acceptance before any live gate.
5. Exercise this spec using its worktree-local scripts/personas and the new
   .specify/stack.yml gate_checks. Earlier bootstrap tasks may have legacy-format
   captures from tooling that did not exist yet: refresh their current checks
   and validated-return receipts using the new scripts before the first floor.
   Preserve original history; do not retick/reimplement completed work or
   pretend old captures have provenance.
6. At a real task acceptance, save an incomplete copy of the worker return,
   its deterministic rejection and before/after tasks digest, then accept the
   complete return against the no-tick capture. Run floor, reserve and complete
   the first opponent round; later give reality-check both gate/floor records
   and the live probe. If intervening fixes change inputs, rerun required
   checks; never force a cache hit for the demonstration.
   During reality-check, the probe validates the completed opponent report and
   the active script-granted reality-check reservation/current floor; it cannot
   require its own future completed reality-check report. Once that report is
   submitted, round completion validates its matching identities, and subsequent
   probe runs also validate the completed report. This refines AC-016's bootstrap
   ordering without weakening its live-evidence requirement.
7. Ship only after both independent gates, suite/static CI and existing
   sync --check/doctor environment checks pass. Use normal apply-models/build
   generation, never hand-edit generated output or globally install mid-plan.
   Port to the private clone byte-identically only in the existing post-merge
   workflow (CON-002, CON-005).

Rollback stops new-contract automation and restores code/templates together;
retain additive evidence as historical data. Never silently remove the contract
marker to regain legacy auto-clearance. A failed optimization can disable reuse
and rerun checks without weakening floor, acceptance, round caps or either gate.

Measurement wiring (REQ-001, REQ-015):

| Metric | Recorded source / treatment |
|---|---|
| MET-001 | Tally rounds plus task count/stacks for next three specs, including capped/stopped runs; median target ≤2. |
| MET-002 | New/reopened finding IDs grouped by stable Class, independently of file/root cause; target zero recurrence. |
| MET-003 | User usage-view before/after observations in STATUS Decisions, model policy and comparable baseline; missing comparison = unknown, not inferred 30% savings. |
| MET-004 | Follow-up task count alongside findings, raw locations and reopened findings; target ≤3 does not merge away unresolved sites. |
| MET-005 | Retro/Ship records name the owner and date for the 14-day escaped-defect/reopened-finding check-back; do not delay ship for that window. |
| MET-006 | Verification ledger execution/reuse events and emitted byte counts; compare across both gates on equal inputs, retain raw logs. |

## 9. Out of scope (deferred)

No model-tier changes, merged gates, softer verdicts, automatic waivers, security
policy changes, external/time-state caching, dependency graph engine, billing
collector, new umbrella workflow, scheduler changes or adapter rewrite.
No historical 001/002 retrofit or private/global installation during this phase.
A future narrower-manifest optimization requires separate proof of transitive
coverage; v1 deliberately accepts conservative reruns.

## 10. References

- Accepted `spec.md`, especially REQ-006–REQ-009, REQ-012–REQ-013 and AC-016
  bootstrap; settled choices in `STATUS.md`.
- `scripts/lib.sh`, `spec-run.sh`, `spec-task.sh`, `spec-evidence.sh`,
  `spec-ac-coverage.sh`, `sdd-analyze.sh`, `spec-resume.sh`,
  `spec-worktree.sh`: existing behavior and anchors in §2.
- `tests/helpers.sh`, `tests/run.sh`, `.github/workflows/ci.yml`,
  `templates/examples/001-api-key-expiry/`: fixture and portability contracts.
- Spec 002 canonical opponent/reality-check notes: five opponent rounds,
  six blocking findings, one final reality-check report; annotate copies only.
- Hub constitution, `knowledge/deterministic-gates.md`,
  `knowledge/nondeterministic-acceptance.md`,
  `knowledge/fix-verification-scope.md`: deterministic evidence and retained scope.
- No separate ADR or external research is needed; the versioned contract and
  this plan own the local decisions.

---

Next: review tasks.md, then /sdd:implement. Task IDs live in tasks.md; no commits
or live gate results are invented during planning/tasking.
