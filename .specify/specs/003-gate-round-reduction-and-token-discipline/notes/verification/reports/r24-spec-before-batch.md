---
spec_id: 003-gate-round-reduction-and-token-discipline
title: Gate round reduction and token discipline
status: implementing  # draft | accepted | implementing | shipped | rejected
verification_contract: 1
created: 2026-09-04
updated: 2026-09-15
owners: [Rehan712]
project: sdd-kit-public
---

# Gate round reduction and token discipline

> Move failure-mode planning and tests into implementation tasks, fix defect
> classes together, and share verified execution results between gates. Reduce
> repeated context and output without treating historical evidence as current
> proof or restricting reviewers to defects already anticipated. Gate models,
> separation, and adversarial defaults stay unchanged.

## 1. Problem

Spec 002 records five opponent rounds, six blocking findings, and one final
reality-check report. Rounds 2, 3 and 4 repeatedly found the lock-lifecycle
class at different sites: `run`, `cancel`, then metadata writes. The clock
grammar also recurred when its repair missed sibling pattern rows. The
opponent reports record full-suite runs in all five rounds; they do not
establish five reality-check runs. All six blocking findings were already
classified as wrong-result, so severity filtering alone would not remove them.

The user also reports a governed Rust + Next.js + CDK project reaching ten
rounds and roughly fifty findings. That is motivation to investigate, not a
measured cost baseline available in this repository. The observed lock and
clock recurrences support class-wide repairs. They do not prove a two-round
counterfactual: discovering the scheduler PATH defect in round two still
requires fixing it and obtaining clearance in a later invocation.

The current harness has several avoidable costs:

- Plans name risks without a stable mapping from failure scenarios to tests.
  Separate Tests-stage tasks can defer local behavioral coverage.
- Follow-ups can repair one site without establishing the class's extent.
- Implementers re-read decisions already supplied in their briefs.
- Gates repeat checks and consume verbose output that scripts could summarize.
- Round limits depend on prose rather than a checked invocation record.

Two existing script behaviors constrain the solution. `spec-run.sh` hashes
command output and prints that output even with `--key`; it does not currently
fingerprint source inputs or provide a quiet summary mode. `spec-evidence.sh`
checks capture/artifact presence, not whether an old successful run still
proves the current code. A review probe captured a passing test, changed its
implementation until the test failed, and still received "sound" from the
evidence checker. New reuse rules must close that gap before relying on them.

**REQ-001:** Reduce redundant verification and context through the contracts
below while preserving evidence validity and independent review. Two opponent
rounds and 30% lower spend are evaluation targets, not guarantees or reasons
to suppress findings. Re-running a check is required when its inputs or
validity are uncertain; separate gates may independently read material they
need to judge correctness.

## 2. Goals

### Plan and tasks

- **REQ-002 (failure-mode planning):** Plans define stable `FM-###` rows
  with component(s), category, triggering input/sequence, decided behavior,
  and intended test family. Categories are boundary, concurrency/ordering,
  partial failure, regression, and state/data integrity. Shared scenarios
  use one row listing all affected components; a compact exclusions list
  records inapplicable component/category pairs with reasons. Planning does
  not invent future task numbers. During task decomposition, non-gate tasks
  bind applicable FM rows through Refs and name their covering tests. The
  analyzer checks IDs, references, and missing bindings at the appropriate
  phase; it does not claim that mentioning an ID proves behavior.
- **REQ-003 (stack defaults):** Each shipped code-stack overlay supplies
  failure-mode and checkpoint defaults for its own stack, reused by the
  planner rather than copied wholesale. At minimum the defaults cover Rust
  error/panic mapping and cleanup, Rust-on-Lambda retries/timeouts, Next.js
  server/client boundaries, caching and server-action auth, CDK IAM/removal
  policy and handler environment contracts, and JavaScript/React error and
  state handling. Applicable defaults are filled or explicitly excluded.
- **REQ-004 (invariants):** Behavioral "always/never" promises become named
  `INV-###` invariants with a stated scope, enforcement mechanism, and
  covering test family. Prefer one shared enforcement mechanism where
  possible; distributed enforcement names every necessary site. Multiple
  cases may prove one invariant, including ownership and failure-before-
  acquisition cases for cleanup. Task INV references resolve against the
  plan. An invariant or FM row with tests remains reviewable attack surface.
- **REQ-005 (tests travel with the task):** A behavior-changing task adds or
  extends the test proving its AC/FM/INV in the same task and commit.
  Verify names the actual test or executable behavioral assertion; the Tests
  stage retains only integration spanning tasks or stacks. The analyzer
  warns on an untyped AC-referencing Verify that offers only build,
  typecheck, or text-presence evidence. Explicit static/manual verification
  remains valid for static/manual criteria; shell test runners and custom
  behavioral assertions must not require a fake framework wrapper. The plan
  fixes the small verification-kind grammar used by the template and
  analyzer. New tasks hand off with zero such warnings; semantic adequacy
  remains a gate responsibility.
- **REQ-006 (validate before ticking):** Implementation briefs include their
  required FM/INV rows and test bindings. Workers capture checks with
  `spec-run.sh --no-tick --summary` and return the capture ID(s), summary,
  and a compact Failure modes block mapping every required FM/INV ID to
  its named test and capture. Tasks with no assigned rows return explicit
  `none`, accepted only when the task's required set is empty.
  `spec-gate.sh accept <spec-dir> <task-id> <return-file>` validates that
  mapping against the task/plan and authentic, successful, current captures
  before calling `spec-task.sh done`. The invoker (orchestrator or single-task
  implementation entry point) alone accepts and ticks; workers do not tick
  or edit acceptance state. Missing rows, unknown
  tests/captures, failed or stale runs, and malformed returns leave task
  state unchanged. Re-dispatch once at the existing escalation tier after
  failed acceptance, then stop if it still fails. A model-written summary
  cannot substitute for a captured run. Explicit manual criteria retain
  artifact-backed acceptance: validate the referenced artifact and recorded
  observation instead of inventing a command exit. An automated criterion
  cannot use that exception merely because its check failed or was omitted.

### Deterministic verification

- **REQ-007 (shared gate floor):** `spec-gate.sh floor <spec-dir>` checks
  `sdd-analyze.sh`, `spec-ac-coverage.sh`, `spec-evidence.sh`, and the
  project's declared `gate_checks:` command list. New specs opt in with
  `verification_contract: 1` in spec frontmatter (including this spec);
  they require a nonempty gate_checks list covering the full suite and
  mandatory static checks, independent of optional stage checkpoints.
  A missing legacy configuration produces an explicit gap and disables
  automatic floor clearance until the project's verification commands are
  supplied; a no-op must not claim that tests passed.
  The floor records command identities, actual exits, key lines, capture
  references, source validity, and a result ID under `## GATE-FLOOR` in
  notes/evidence.md. It returns 0 only when every required check has valid
  passing evidence, otherwise names the failing/missing check and returns
  nonzero. Both gates receive that floor result and reuse its valid checks.
  Calling floor before each gate revalidates mutable artifact integrity but
  does not re-execute unchanged, reusable suite commands. New attacks may
  execute additional checks, and invalid evidence must be refreshed.
- **REQ-008 (stage checkpoints and coverage delta):** Optional
  `checkpoints:` maps exact task-stage names to command lists in stack.yml.
  After a stage's last completed batch, `spec-gate.sh checkpoint
  <spec-dir> <stage>` runs its commands and verifies the AC/FM/INV bindings
  and captured acceptance of completed tasks through that stage. It stops
  before the next stage if a command fails or a required binding is lost.
  Future tasks' not-yet-implemented ACs are not gaps; deliberately spanning
  criteria have explicit later integration owners. The delta also checks
  that previously established bindings were not removed. No stage commands
  means "no checkpoint commands"; the completed-task coverage check still
  runs for the new contract. Legacy missing bindings warn.
  Gate and checkpoint commands run in the correct repo worktree, preserve
  arguments and failure status (including pipelines), and deduplicate exact
  command + shell + cwd + input-state identities. A checkpoint result may
  serve a later floor only when REQ-009 permits reuse. Running every
  checkpoint command again is not a substitute for declared gate_checks.
- **REQ-009 (evidence validity and reuse):** Presence/integrity and freshness
  are separate predicates. Reuse requires a script-created, complete capture
  whose successful exit, full output digest, command/arguments, shell, repo
  and cwd, and input identity can be verified. Inputs include source content
  (staged, unstaged, and relevant untracked files), tests and fixtures,
  dependency lockfiles, build/test configuration, relevant toolchain and
  environment identity, and the referenced specification/plan/Verify text.
  A commit ID or output hash alone is insufficient.
  Historical captures without this provenance are readable but not reusable.
  Missing/altered logs, mismatches, a later failed run for the same check and
  inputs, or inputs changing during execution force fresh verification.
  Time-dependent or external-state checks are not reused without a valid,
  explicit freshness policy; unknown validity always requires a run.
  Bookkeeping-only edits (gate reports, capture logs, checkbox state) do not
  invalidate unchanged code execution, but artifact integrity is checked
  again before acceptance or gating. Distinguish those edits from changes
  to ACs, decisions, task commands, and test bindings.
  Use a conservative whole-source input set by default. Narrower dependency
  manifests may enable reuse only when their transitive coverage is known;
  shared dependency/configuration changes invalidate affected results, and
  unknown impact invalidates all potentially affected results. At resume,
  skip completed-task checks only on this validated basis. A stale capture
  is not a failed implementation: refresh verification before relying on it.

### Gates

- **REQ-010 (class-wide review with retained scope):** Each opponent round
  reports every blocking finding it can establish and groups sibling sites
  of one defect class into a finding with explicit locations. Follow-up
  briefs require fixing the class and sweeping siblings; record sites
  checked and any unexamined extent, without claiming exhaustiveness that
  was not established. Start from FM/INV rows, but inspect whether tests
  actually assert the behavior and attack both covered and omitted cases.
  Later rounds prioritize fixes, siblings, affected consumers and contracts,
  and previously unexamined surfaces. They may expand scope when new
  evidence exposes a missed assumption or defect on unchanged code.
  Closed findings need not be re-litigated without new evidence.
- **REQ-011 (severity gate):** Only reproduced findings, or findings with
  concrete triggering inputs and file:line, of severity data-loss,
  wrong-result, regression or crash make the opponent CHALLENGED.
  Degraded paths, style and documentation hygiene are minor unless an AC
  or REQ requires the affected behavior/document/claim; that violation
  blocks as wrong-result. The report keeps `Reproduced:` per finding and
  `**Blocking:** n · **Minor:** n`. Missing required evidence is handled
  by the floor/reality-check even if no reproduced behavioral defect exists.
  Severity never changes merely to meet a round or cost target.
- **REQ-012 (round cap and report identity):** Before every invocation,
  `spec-gate.sh round <spec-dir> <opponent|reality-check>` determines the
  next number from that gate's canonical reports. Both report templates use
  `**Round:**`, a UTC timestamp `YYYY-MM-DDTHH:MM:SSZ`, reviewed source
  identity, and floor result ID. Rounds 1–3 are allowed; round 4+ returns
  exit 4 unless an explicit user authorization in STATUS Decisions names
  the gate, the exact next round, the preceding completed round, author,
  reason, and a later UTC timestamp. A `spec-revision:` entry additionally
  references the accepted revision. Neither a bare date nor an unscoped
  waiver authorizes a run; a round-4 authorization does not authorize round
  5 or the other gate. Same-day authorizations work by timestamp order.
  Count canonical round records, not headings repeated inside findings or
  quoted captures; legacy date-only reports still count, but cannot prove
  authorization ordering without an explicit timestamped reconciliation.
  Malformed, duplicate or incomplete existing records fail closed with a
  named recovery action, rather than resetting the count. The orchestrator
  records the granted number and returns the completed report; it must
  reconcile an interrupted invocation before starting another. All entry
  points, including /sdd:go and post-PR /sdd:review, use the same cap.
- **REQ-013 (incremental reality-check):** Every round includes every AC,
  its text/revision, evidence references, and affected-input mapping. From
  round 2 the dossier supplies the prior reviewed source identity and a
  diff including relevant uncommitted/untracked changes. A prior PASS may
  be marked `carried (round n)` only if the criterion, its implementation
  and transitive inputs, and the evidence's validity are unchanged under
  REQ-009. Unchanged evidence filenames alone never permit carrying PASS.
  FAIL/MISSING, changed criteria, dependency-affected rows and unknown
  impact require renewed evaluation; use current floor captures for checks
  it already executed. Changed shared inputs may invalidate many or all
  rows. An uncertain or incomplete earlier review also requires inspection.

### Token discipline

- **REQ-014 (briefs by role):** Implementation briefs are authoritative
  copies of applicable spec/plan/constitution slices and carry their
  source revision plus FM/INV/test bindings. Implementation experts and
  the test-engineer read the code, supplied slices and relevant overlay
  without routinely rereading those whole documents. They report omitted
  or conflicting decisions; the orchestrator first supplies an existing
  missing slice, and only a genuinely new decision changes the plan.
  Refreshed tasks receive refreshed briefs. Planning consultations are
  explicitly different: experts examine relevant requirements and code,
  propose decisions and risks, and identify unknowns before a plan exists.
  This rule never overrides higher-priority instructions or project-local
  rules. Gates retain independent access to their source documents.
- **REQ-015 (class accounting and evaluation):** Findings keep
  `Root cause: plan-gap | spec-gap | implementation-error` for process
  diagnosis and add a separate stable `Class:` slug (e.g. lock-lifecycle),
  with all locations. `spec-gate.sh tally <spec-dir>` reports rounds per
  gate, blocking/minor findings, class totals and recurrences. Recurrence
  means a new or reopened finding in a previously reported class, even at
  another file or with a different process root cause; merely checking an
  existing open finding again does not count as a new one. Keep prior
  finding references for that distinction. Legacy findings without class
  IDs are explicitly unclassified; do not infer class from filename plus
  process category. Retro records costs, check executions/reuses, and
  quality outcomes alongside these counts. Grouping sites cannot hide
  location counts or unresolved findings.
- **REQ-016 (bounded command output):** `spec-run.sh --summary` emits one
  escaped summary line on success containing capture ID, command, key
  line, real exit, output digest, input identity and full-log reference.
  On failure it emits that summary plus at most 20 diagnostic lines,
  with total emitted output bounded to 8 KiB; success is bounded to 2 KiB.
  Truncated display fields
  refer to complete metadata on disk. Full stdout/stderr remains available
  in the captured log, with a verifiable digest. Existing `--key` only
  selects the key line; it is not a quiet flag. Default output remains
  compatible. Floor, checkpoint and accept use similarly bounded summaries
  and report cache hits explicitly. Keep the command's real exit status;
  do not use bare `command | tail` as acceptance evidence.

## 3. Non-goals

- Changing models, gate separation, adversarial defaults, or security review.
- Building a language-independent dependency graph engine. Conservative
  invalidation is acceptable where a complete dependency set is unavailable.
- Building token billing/accounting tooling or claiming savings from proxies
  alone; actual spend still comes from the user's usage view.
- Rewriting historical evidence. Existing blocks remain readable; additive
  versioned metadata and full-log sidecars are allowed for new captures.
- Rewriting adapter machinery. Persona changes regenerate through the
  existing apply-models/build-adapters flow; new Copilot delegation is separate.
- New umbrella workflows. Existing repo/worktree resolution stays in force;
  per-repo gate_checks/checkpoints run against the declared worktrees.
- Retrofitting shipped specs 001/002 or approving waivers on the user's behalf.

## 4. Success metrics

These are hypotheses evaluated after shipping, not acceptance criteria that
a gate can satisfy by lowering severity, grouping away defects, or stopping
early. Report the observation window and missing measurements explicitly.

- **MET-001:** Target median opponent rounds ≤ 2 across the next three specs
  using the kit. Record each spec's rounds, task count and affected stacks,
  including capped/stopped runs so selection cannot hide failures.
- **MET-002:** Target zero new/reopened class recurrences across those runs,
  measured by Class IDs independently of file and process root cause.
- **MET-003:** Target ≥30% lower per-spec credit spend against a recorded
  comparable baseline: similar task count/complexity, stacks and model
  policy. Capture actual usage before/after each run in STATUS Decisions.
  Missing baseline usage means "unknown", not a saving inferred from rounds.
- **MET-004:** Target ≤3 gate follow-up tasks per spec; also report findings,
  affected locations, and reopened findings so aggregation cannot game it.
- **MET-005:** Record gate-reopened findings and escaped behavioral defects
  per shipped spec over a consistent 14-day follow-up window, with a named
  owner/check-back at Ship. Compare with an available baseline; unknown is
  explicit. Reduced spend is not evidence of improvement if defect escapes
  rise. This observation does not delay shipping the harness implementation.
- **MET-006:** Record executed/reused verification commands and displayed
  output bytes. For unchanged reusable inputs, the two gates share each
  required suite execution; summary size is bounded independently of raw
  suite verbosity. Executable fixtures prove these mechanics before rollout.

## 5. User stories

- As a planner, I define compact FM/INV rows and proposed test families;
  task decomposition supplies task bindings later.
- As an implementer, I extend tests alongside behavior and return a captured
  result without changing the task's acceptance state. Missing context gets
  supplied before I make an uninformed design choice.
- As the orchestrator, I reject incomplete returns without ticking, stop on
  stage regressions, and show the failing check before invoking a gate.
- As a reviewer, I share current execution evidence while independently
  judging the assertions and attacking overlooked or affected surfaces.
  An old PASS is invalidated when its dependency or criterion changes.
- As a developer, I can authorize one additional gate round with an exact
  timestamped decision and see why any further invocation is refused.
- As a retro author, I compare actual spend and quality with a stated
  baseline instead of treating fewer report headings as proof of success.

## 6. Acceptance criteria

Tests name the AC they prove. Text checks prove instruction/template presence;
they do not prove runtime refusal, execution, invalidation or reuse. Those
behaviors require executable fixtures with counters, observed outputs and
unchanged-state assertions. Fresh model calls are not required for every
fixture; this spec's one orchestrated run supplies the live wiring probe.

### Plan and tasks

- [ ] **AC-001:** The plan template documents FM/INV grammar and compact
  exclusions. Analyzer fixtures prove missing/placeholder warnings and a
  clean shared-row plan. A planning-phase fixture is valid without task
  numbers; tasks-phase fixtures detect missing bindings. (REQ-002, REQ-004)
- [ ] **AC-002:** Every shipped code-stack overlay has failure-mode and
  checkpoint defaults relevant to its stack; text checks enumerate the
  actual overlay set. Rust, rust-aws-lambda, Next.js, aws-cdk-lambda-ts,
  JavaScript and React each cover at least three applicable scenarios.
  Documentation distinguishes stage commands from required gate_checks.
  (REQ-003, REQ-008)
- [ ] **AC-003:** Analyzer fixtures reject duplicate FM/INV definitions and
  dangling task references, accept defined/shared references, and warn on
  unassigned applicable rows at task handoff. No future task-number
  reference is required in a draft plan. (REQ-002, REQ-004)
- [ ] **AC-004:** Analyzer fixtures warn on an untyped AC Verify that is
  build/typecheck/text-presence only, accept recognized shell tests and
  declared behavioral assertions, and accept explicit static/manual checks
  for their appropriate criteria. The verification-kind grammar has one
  authoritative definition; runner substring matching alone is insufficient.
  (REQ-005)
- [ ] **AC-005:** The golden api-key-expiry example contains concrete FM/INV
  rows, exclusions where needed, and non-gate tasks binding each applicable
  row to its test family; its analyzer test passes with zero warnings.
  (REQ-002, REQ-004, REQ-005)
- [ ] **AC-006:** Task template and tasks skill require tests with behavior,
  allow extension of existing tests, and reserve Tests for cross-cutting
  integration. Fixtures distinguish a behavior task with its test binding
  from one that defers all coverage to an unrelated later test task.
  (REQ-005)

### Floor, checkpoints and reports

- [ ] **AC-007:** Floor fixtures observe execution of all three deterministic
  checkers and every required gate_checks command in the intended worktree,
  record actual exit/key/log/input identities, and return nonzero before any
  simulated gate call when a required check fails or configuration is
  missing. Two gate invocations on unchanged reusable inputs execute each
  unique suite command once; changed source or command executes it again.
  Bookkeeping changes refresh integrity checks without rerunning the suite.
  Deduplication never crosses different cwd/repo/input identities.
  (REQ-007, REQ-009)
- [ ] **AC-008:** Checkpoint fixtures cover success, exact failure-code
  propagation including a pipeline, no stage commands, and lost completed
  AC/FM/INV bindings. Future-stage ACs and declared spanning integration
  owners do not create premature gaps; removing previously established
  coverage does. A failing checkpoint leaves the next-stage invocation
  counter at zero. Matching valid checkpoint execution is reused by floor.
  (REQ-008)
- [ ] **AC-009:** For both gates, round fixtures cover absent notes, rounds
  1–3, blocked round 4, a valid same-day timestamped authorization, and
  rejection of old/unscoped/wrong-gate/wrong-round authorizations. Round-4
  permission does not permit round 5. Quoted headings do not add rounds;
  malformed/duplicate/incomplete records cannot silently reset the count.
  A legacy date-only report needs explicit timestamp reconciliation for
  authorization ordering. (REQ-012)
- [ ] **AC-010:** Tally fixtures distinguish one class across different files
  and process root causes from different classes sharing a file/root cause;
  rechecking an open finding is not a new recurrence. An untouched copy of
  002 reports five opponent rounds, six blocking findings and unclassified
  legacy classes. A separately annotated fixture binds its clock and lock
  findings to stable classes and detects both recurrences. Original shipped
  artifacts are not rewritten. (REQ-015)
- [ ] **AC-011:** Analyzer/doctor fixtures accept nonempty gate_checks command
  lists and optional checkpoint maps, reject malformed lists/maps and
  unknown checkpoint stages with named errors, and distinguish missing
  new-contract configuration from legacy warnings. This repo declares
  `bash tests/run.sh` and its required ShellCheck command as gate_checks;
  `stacks: []` does not exempt it from running the suite. The supported
  YAML/command quoting subset is documented and tested, including spaces,
  arguments and pipeline failures. (REQ-007, REQ-008, CON-001, CON-003)

### Personas, wiring and live observation

- [ ] **AC-012:** Opponent instructions/report fields include Class,
  process Root cause, all finding locations, prior finding references,
  Reproduced, blocking/minor counts, canonical round/time/source/floor
  identity, and attacked/unexamined surfaces. They permit expanding a later
  review to overlooked unchanged code and never exempt a tested FM row.
  Text tests check these rules; the live report in AC-016 uses this schema.
  (REQ-010, REQ-011, REQ-012, REQ-015)
- [ ] **AC-013:** Reality-check includes every AC and uses the carried marker
  only with matching criterion, impact mapping and valid evidence. Executable
  invalidation fixtures mutate implementation, a transitive shared helper,
  fixture, lockfile, configuration and AC text while leaving the old log
  untouched; each invalidates the affected PASS. Unknown impact triggers
  conservative reevaluation. Unchanged proven inputs permit carrying, and
  existing current floor captures avoid duplicate suite runs. Persona and
  dossier checks also require the canonical round/time/source/floor fields.
  (REQ-009, REQ-013)
- [ ] **AC-014:** All expert/test-engineer personas explicitly separate
  planning consultation from implementation briefing. Planning permits
  proposing decisions; implementation uses supplied slices and requests
  omissions/conflict resolution without routinely rereading whole artifacts.
  Planning and implementation brief examples encode the correct mode and
  revision. Regenerated adapters retain both cases. (REQ-014)
- [ ] **AC-015:** Orchestrator and implement skill use worker --no-tick,
  deterministic accept, current floor, round authorization, stage coverage
  checkpoints, and validated reuse. /sdd:go and /sdd:review invoke the same
  rules, replacing contradictory older round limits. Script fixtures
  exercise the sequence with simulated workers/gates: a failed floor or
  blocked round prevents a gate call; an incomplete return leaves the task
  unchecked; a valid return is accepted once. Assertions observe state and
  invocation counts, not merely required phrases. AC-016 observes real
  orchestrator wiring. (REQ-006, REQ-007, REQ-008, REQ-009, REQ-012)
- [ ] **AC-016:** During this spec's actual orchestrated run, at least one
  worker uses no-tick capture, and the invoker records rejection of a
  deliberately incomplete copy of that return without changing task state,
  then accepts the complete return against the real capture. The first
  opponent report references a valid earlier floor and the script-granted
  round. Both gates show valid floor references and suite reuse when their
  inputs are unchanged. The live observations are checked at reality-check,
  after the first opponent report can exist.
  Bootstrap rule: a non-gate implementation task owns the executable probe
  checker and fixture tests naming AC-016; its pre-gate acceptance verifies
  those fixtures. Actual first-gate observations belong to the gate and
  cannot be prerequisites for starting it. The floor does not run a
  full-suite assertion requiring the future report. Missing live evidence
  still prevents reality-check READY. (REQ-006, REQ-007, REQ-012, REQ-016)
- [ ] **AC-017:** Planning/task instructions bind FM/INV at the correct
  phase. Retro template/skill report class recurrence separately from
  process root cause, plus raw location counts, spend/baseline availability,
  command executions/reuses, reopened findings and the post-ship quality
  observation owner. Text tests and tally fixtures prove those fields and
  missing measurements; no savings are invented from round counts.
  (REQ-001, REQ-002, REQ-015)
- [ ] **AC-018:** README and constitution explain required gate_checks,
  optional checkpoints, verification_contract compatibility, evidence
  integrity versus freshness, no-tick acceptance, summary output, class IDs,
  scope-aware review and per-round authorization. The documented
  `spec-gate.sh --help` lists floor, checkpoint, round, tally and accept.
  All documented command examples run in fixtures. (REQ-001, REQ-015,
  REQ-016)

### Execution integrity and compatibility

- [ ] **AC-019:** `tests/run.sh` and
  `shellcheck -S warning -x scripts/*.sh tests/*.sh` pass under bash 3.2
  and the existing CI bash matrix. Capture fixtures and provider/scheduler
  stubs remain isolated from real external actions. (CON-001)
- [ ] **AC-020:** Reuse fixtures first capture a passing command, then
  independently change its source (including dirty/untracked inputs),
  command/cwd, tests, dependencies, relevant environment/toolchain identity,
  or referenced criterion. None can reuse the old success. Altered/truncated
  logs, incomplete writes, missing provenance, a later failed same-input
  run, and inputs changing during execution also reject reuse. Unchanged
  deterministic inputs reuse successfully; historical records still parse
  but are freshness-unknown. External/time-dependent checks without an
  explicit valid freshness policy run again. The review's failing-test/
  "sound evidence" scenario cannot obtain reusable or current-PASS status.
  (REQ-009)
- [ ] **AC-021:** A verbose passing fixture emits one summary line ≤2 KiB
  with --summary while the full log/digest remains verifiable; a failing
  fixture preserves its exit and displays at most 20 diagnostic lines/
  8 KiB. Multiline/control output is escaped and long fields reference full
  metadata. --key alone retains its selection semantics and default output;
  --summary --no-tick leaves the checkbox unchanged. Tests measure output
  bytes/lines and actual command executions. (REQ-016)
- [ ] **AC-022:** Accept fixtures cover missing/extra FM or INV IDs, a missing
  Failure modes block, no assigned rows with explicit none, nonexistent test
  or capture references, forged summary, failed/stale capture, and an
  implementation changed between capture and acceptance. Invalid returns
  preserve tasks.md byte-for-byte. A complete valid mapping permits exactly
  one tick and evidence attachment; repeated acceptance is idempotent.
  Declared manual criteria accept a real artifact/observation, reject a
  missing artifact, and cannot exempt an automated criterion from capture.
  Validation resolves each named test through its capture's declared
  verification binding; substring matches in unrelated logs cannot supply
  the proof. Required captures must be complete and valid at acceptance.
  (REQ-006, REQ-009)
- [ ] **AC-023:** Shipped 001/002 remain analyzer exit 0. New-contract
  integrity failures stay errors, while missing legacy FM/provenance/config
  is reported without retroactively claiming freshness. Documentation and
  fixtures explicitly distinguish analyzer compatibility from a floor that
  cannot clear without runnable verification. (CON-003, REQ-007, REQ-009)

## 7. Constraints

- **CON-001:** Bash 3.2, BSD/POSIX tools and the existing CI matrix; no new
  runtime dependency. The plan pre-decides parsable metadata/report/command
  grammars and their failure behavior before script implementation.
- **CON-002:** Kit source files stay byte-identical with the private clone
  after the existing post-merge port. This change ships here first.
- **CON-003:** Shipped specs 001/002 retain analyzer exit 0. Missing legacy
  metadata yields warnings and freshness-unknown, never an invented PASS.
  New-contract specs require full bindings/configuration at the appropriate
  handoff; malformed declared data and dangling/duplicate IDs are errors.
  Tests-with-tasks remains a warning, with zero allowed at new task handoff.
- **CON-004:** Models.yml roles/tiers, gate separation/defaults and security
  reviewer authority do not change. A round waiver permits an invocation,
  not a softened verdict or skipped criterion.
- **CON-005:** Persona edits regenerate through apply-models.sh and
  build-adapters.sh; sync --check and doctor remain clean within their
  existing environment requirements. Never edit generated build/ by hand.
- **CON-006:** This repo has stacks: [] but an executable shell suite.
  Text checks validate stack advice; runtime fixtures validate the common
  harness. Cross-stack live effects are measured in later governed specs.
- **CON-007:** Worktree guards, clarification markers and evidence-not-claims
  remain enforced. Reuse means consuming a verified matching real run,
  never trusting an implementer's prose or only a filename/hash claim.
- **CON-008:** Implement FM/test binding, class sweeps, output bounds and
  the shared floor before enabling reuse/carry-forward. Reuse remains
  disabled until provenance and invalidation fixtures pass. Acceptance and
  shared evidence mutations are serialized; source snapshots must remain
  stable through capture/validation, including parallel worker batches.

## 8. Open questions

None blocking. Existing user choices are preserved; the review corrections
are recorded in STATUS. Which governed project supplies the first later
measurement point remains a non-blocking owner choice. Missing baseline or
follow-up measurements are reported as unknown.

## 9. References

- Spec 002 notes/opponent.md and notes/reality-check.md: the recorded five
  opponent rounds, six findings, and single final evidence matrix.
- scripts/spec-run.sh, spec-evidence.sh, spec-ac-coverage.sh, spec-task.sh:
  current capture, integrity, binding and tick behavior.
- scripts/sdd-analyze.sh, sdd-doctor.sh and the proposed spec-gate.sh.
- agents/opponent.agent.md, reality-check.agent.md, sdd-orchestrator.md,
  *-expert.md and test-engineer.md.
- skills/sdd-plan, sdd-tasks, sdd-implement, sdd-go, sdd-review and sdd-retro.
- templates/plan-template.md, tasks-template.md, retro-template.md,
  stack-overlays/, and examples/001-api-key-expiry/.
- constitution.md §10 and knowledge/deterministic-gates.md.

---

*Workflow:* Review draft tasks.md, then /sdd:implement.
The spec and plan are accepted. Task decomposition is complete; no harness
implementation has begun.
