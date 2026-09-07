---
tasks_for: 003-gate-round-reduction-and-token-discipline
status: in-progress  # draft | in-progress | complete
created: 2026-09-05
updated: 2026-09-07
---

# Tasks: Gate round reduction and token discipline

34 tasks: 29 implementation/integration/documentation, two independent gates,
three Ship tasks. The accepted single-spec decision is retained despite the
~25-task guideline; split releases would reduce run size, but this breakdown
keeps each edit task to at most five files instead of combining unrelated work.

## Execution contract

- All implementation runs in the spec worktree; creating it is the normal
  implementation entry step, not a padding task. No code, commit or worktree
  is created during task decomposition.
- Sequence follows stage order. Only T003/T004/T005 are parallel-safe after
  T002; their files are disjoint. Other tasks sharing the kernel or test files
  stay serial. Close each editing batch before serial capture/acceptance.
- Each behavior task adds/extends its named test family in the same commit.
  Every added case labels the actual AC assertion; an ID copied into a fixture
  is not sufficient behavioral proof. Text tests prove instruction/schema
  requirements only. Tests stage work composes components or checks live wiring.
- `*Tests:*` locators resolve to plan §7's registry. A family is extended across
  tasks; run the listed real command, not a future global assertion. Local
  partial cases are owned now; T027 owns the named cross-component integration,
  not deferred local coverage. No future test-file existence is required at
  task handoff; it is required when that task is accepted.
- Non-gate tasks use explicit `test` kind and local deterministic checks.
  `Reuse: local` declares eligibility only: the runtime reuse/carry switch
  remains disabled until T023's invalidation cases pass. Never apply that
  opt-in to an external/time-dependent check with unknown validity.
- Workers never tick. Before T017, use the existing runner's `--no-tick`
  capture and preserve its real legacy output; do not invent new capture IDs
  or claim summary/provenance support that has not landed. The invoker alone
  records bootstrap completion from actual captured evidence through the
  existing task tool. From T017 use `--from-task --no-tick --summary`; from
  T019 use `spec-gate.sh accept` and refresh earlier bootstrap proof/receipts
  before the first real checkpoint/floor, preserving historical completion.
- All commands below run from the repo worktree root. With the new runner,
  pass the task's Verify through `--from-task`; commands containing `&&` use
  the plan's Bash/pipefail shell contract. Expected `passed` means every
  executed suite reports all cases passed and returns 0; it is not a promised
  test count or present-tense evidence. Never pipe acceptance through bare tail.
- Return the exact required FM/INV-to-test/capture mappings from Refs, plus
  authentic summaries (plan §4.2). Use explicit none only for an empty set.
  Invalid acceptance gets one existing-tier escalation retry, then stops.
  T029's deliberate negative control is a probe, not a failed worker return.
- T021 introduces stage checkpoints; thereafter invoke them after completed
  batches, including Backend and API. An empty command list still checks
  completed/prior bindings. Gate entry always runs current floor then round.
- Gates retain configured models, distinct contexts and adversarial defaults.
  The installed Agent paths identify the roles; supply their worktree-local
  updated persona/contracts as inputs for this self-hosting change. Do not
  globally install half-built tooling or substitute a stub for the live gates.
- `(new in T...)` means a file does not exist at tasking time and is introduced
  by the named earlier task. Gate/Ship `notes/...` and `STATUS.md` paths are
  spec-relative; all other Files paths are repo-relative.
- AC-016 bootstrap: T026 owns the checker and fixtures; T029 supplies a real
  no-tick return/rejection/acceptance event; T030/T031 supply real gate identity
  observations. The reality-check probe reads its active reservation before
  its own completed report exists; round completion validates that report.
- AC-019 requires real platform evidence before READY. CI currently triggers
  on PRs/main only; if an authorized Linux/macOS executor is unavailable,
  stop for an execution route. Tasking does not authorize an early draft PR
  or relax the gate. Normal PR CI still must pass before merge.
- There is no application UI or HTTP service: Backend is the harness domain
  and API is the invoker/CLI protocol. Use these exact stage names in checkpoints.

## Setup

- [x] **T001** — Define the versioned verification authoring contract
  - *Files:* `templates/verification-contract.md` (new), `templates/spec-template.md`, `templates/plan-template.md`, `tests/test-gate-contracts.sh` (new)
  - *Acceptance:* Add AC-001/AC-004 schema assertions for the single grammar, opt-in marker, concrete FM/INV rows, exclusions and phase-correct examples; reference later runtime cases without claiming they already pass.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-004, REQ-005, AC-001, AC-004, FM-001, INV-005, plan §3.1, §4.4
  - *Integration owner:* T027
  - *Evidence:* `bash tests/test-gate-contracts.sh → -- 1/1 passed (notes/evidence.md, T001 2026-09-06T02:28:16, sha256:8d191b7cf017); FM-001 and INV-005 → tests/test-gate-contracts.sh::test_instruction_contracts; bootstrap no-tick capture` (2026-09-06)

- [x] **T002** [hard] — Validate phase-aware failure and test bindings
  - *Files:* `scripts/verification-lib.sh` (new), `scripts/sdd-analyze.sh`, `templates/tasks-template.md`, `tests/test-sdd-analyze.sh`, `tests/helpers.sh`
  - *Acceptance:* Implement vf_bindings and typed task fields with AC-001/AC-003/AC-004/AC-006/AC-023 fixtures for shared/duplicate/dangling IDs, phase boundaries, valid shell/custom/static/manual kinds, deferred local coverage, proof-required behavioral follow-ups and unchanged shipped-spec exit 0.
  - *Verify kind:* test
  - *Tests:* `tests/test-sdd-analyze.sh::test_verification_bindings`
  - *Verify:* `bash tests/test-sdd-analyze.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-004, REQ-005, AC-001, AC-003, AC-004, AC-006, AC-023, FM-001, FM-002, FM-003, INV-005, plan §3.1, §4.1
  - *Evidence:* `bash tests/test-sdd-analyze.sh → -- 18/18 passed (notes/evidence.md, T002 2026-09-06T10:41:22, sha256:20ac89cdff35); FM-001/FM-002/FM-003/INV-005 → tests/test-sdd-analyze.sh::test_verification_bindings; bootstrap no-tick worker return accepted; independent security clean (notes/history.md)` (2026-09-06)

- [x] **T003** [P] [hard] — Parse verification commands without losing arguments
  - *Depends on:* T002
  - *Files:* `scripts/verification-lib.sh` (new in T002), `scripts/sdd-analyze.sh`, `scripts/sdd-doctor.sh`, `tests/test-verification.sh` (new), `.specify/stack.yml`
  - *Acceptance:* Implement vf_config with AC-011 fixtures for lossless quoting, malformed/duplicate/unknown keys and stages, phase deferral and legacy warnings; declare the real suite/ShellCheck gate_checks and Backend/API checkpoints while keeping reuse disabled.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_config_grammar`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-007, REQ-008, AC-011, AC-023, FM-006, FM-011, plan §3.1, §4.1, §6
  - *Evidence:* `bash tests/test-verification.sh → -- 1/1 passed (notes/evidence.md, T003 2026-09-06T19:54:05, sha256:ce28c7d7bf6a); FM-006/FM-011 → tests/test-verification.sh::test_config_grammar; bootstrap no-tick capture; independent security clean (notes/history.md)` (2026-09-06)

- [x] **T003f1** — Keep authoring fixtures valid under gate configuration
  - *Files:* `tests/helpers.sh`, `tests/test-sdd-analyze.sh`, `scripts/verification-lib.sh`
  - *Acceptance:* Existing clean authoring fixtures declare their illustrative gate list; missing legacy configuration warns without failing; exact test ownership accepts supported new-file annotations while rejecting lookalike paths.
  - *Verify kind:* test
  - *Tests:* `tests/test-sdd-analyze.sh::test_verification_bindings`
  - *Verify:* `bash tests/test-sdd-analyze.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-005, REQ-007, AC-006, AC-011, AC-023, FM-002, plan §3.1, §7
  - *Notes:* Required sibling fixture adjustment discovered during T003 integration; no shipped spec rewrite or weakening of missing-configuration checks.
  - *Evidence:* `bash tests/test-sdd-analyze.sh → -- 18/18 passed (notes/evidence.md, T003f1 2026-09-06T19:56:35, sha256:20ac89cdff35); FM-002 → tests/test-sdd-analyze.sh::test_verification_bindings; configured legacy/new fixtures and exact annotated Files ownership; independent security clean` (2026-09-06)

- [x] **T004** [P] — Teach planning and task-local test ownership
  - *Depends on:* T002
  - *Files:* `skills/sdd-plan/SKILL.md`, `skills/sdd-tasks/SKILL.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-006/AC-017 instruction assertions for planning-time families, task-time bindings, same-commit behavioral tests and integration-only Tests stages without copying the grammar into both skills.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-004, REQ-005, AC-006, AC-017, FM-001, INV-005, plan §2, §3.1
  - *Evidence:* `bash tests/test-gate-contracts.sh → -- 1/1 passed (notes/evidence.md, T004, sha256:8d191b7cf017); FM-001, INV-005 → tests/test-gate-contracts.sh::test_instruction_contracts; bootstrap no-tick capture` (2026-09-06)

- [x] **T005** [P] — Refresh the calibrated verification example
  - *Depends on:* T002
  - *Files:* `templates/examples/001-api-key-expiry/spec.md`, `templates/examples/001-api-key-expiry/plan.md`, `templates/examples/001-api-key-expiry/tasks.md`, `templates/examples/001-api-key-expiry/README.md`, `tests/test-golden-example.sh`
  - *Acceptance:* Add AC-005 fixtures proving concrete FM/INV families, non-gate bindings and appropriate Verify kinds pass the updated analyzer with zero warnings in a sandbox project; shipped 001/002 remain untouched.
  - *Verify kind:* test
  - *Tests:* `tests/test-golden-example.sh::test_verification_golden`
  - *Verify:* `bash tests/test-golden-example.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-004, REQ-005, AC-005, FM-002, plan §3.1, §7
  - *Evidence:* `bash tests/test-golden-example.sh → -- 3/3 passed (notes/evidence.md, T005, sha256:c5596e4df60e); FM-002 → tests/test-golden-example.sh::test_verification_golden; bootstrap no-tick capture` (2026-09-06)

## Backend

- [x] **T006** — Add core compiled and web-stack defaults
  - *Files:* `templates/stack-overlays/rust.md`, `templates/stack-overlays/rust-aws-lambda.md`, `templates/stack-overlays/nextjs.md`, `templates/stack-overlays/aws-cdk-lambda-ts.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Extend AC-002 guidance cases for at least three relevant scenarios per listed stack, with exclusion prompts and checkpoint advice distinct from mandatory gate_checks.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-003, REQ-008, AC-002, FM-001, plan §6
  - *Integration owner:* T027
  - *Evidence:* `bash tests/test-gate-contracts.sh → -- 2/2 passed (notes/evidence.md, T006, sha256:c933ee933ed1); FM-001, → task Tests locators; bootstrap no-tick capture` (2026-09-06)

- [x] **T007** — Add JavaScript and application-stack defaults
  - *Files:* `templates/stack-overlays/javascript.md`, `templates/stack-overlays/react.md`, `templates/stack-overlays/bun-monorepo.md`, `templates/stack-overlays/loopback4.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Extend AC-002 cases for these four overlays, including JavaScript/React's three-scenario minimum, async/state/error boundaries and their appropriate stage commands.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-003, REQ-008, AC-002, FM-001, plan §6
  - *Integration owner:* T027
  - *Evidence:* `bash tests/test-gate-contracts.sh → -- 3/3 passed (notes/evidence.md, T007, sha256:2d2aa9369d48); FM-001, → task Tests locators; bootstrap no-tick capture` (2026-09-06)

- [x] **T008** — Add mobile and platform-stack defaults
  - *Files:* `templates/stack-overlays/expo-rn.md`, `templates/stack-overlays/firebase-rtk-codegen.md`, `templates/stack-overlays/python.md`, `templates/stack-overlays/aws.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Extend AC-002 cases with stack-specific boundary/state/failure prompts and useful checkpoint commands for all four overlays rather than generic copied rows.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-003, REQ-008, AC-002, FM-001, plan §6
  - *Integration owner:* T027
  - *Evidence:* `bash tests/test-gate-contracts.sh → -- 4/4 passed (notes/evidence.md, T008, sha256:12499981ed6d); FM-001, → task Tests locators; bootstrap no-tick capture` (2026-09-06)

- [x] **T009** — Finish defaults and enumerate every overlay
  - *Files:* `templates/stack-overlays/monorepo.md`, `templates/stack-overlays/troposphere.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Complete AC-002 defaults and add the directory-wide enumeration assertion so all 14 current overlays and any newly shipped overlay must satisfy the contract.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-003, REQ-008, AC-002, FM-001, FM-002, plan §6
  - *Evidence:* `bash tests/test-gate-contracts.sh → -- 6/6 passed (notes/evidence.md, T009, sha256:43e181334dbe); FM-001,FM-002, → task Tests locators; bootstrap no-tick capture` (2026-09-06)

- [x] **T010** — Separate compiled-stack expert briefing modes
  - *Files:* `agents/rust-expert.md`, `agents/rust-aws-lambda-expert.md`, `agents/aws-cdk-lambda-ts-expert.md`, `agents/nextjs-expert.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-014 assertions for planning consultation versus authoritative implementation slices, revision/binding fields, existing-slice recovery and higher-priority-rule precedence in all four personas.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-014, AC-014, FM-004, FM-005, plan §2, §6
  - *Integration owner:* T027
  - *Evidence:* `bash tests/test-gate-contracts.sh → -- 7/7 passed (notes/evidence.md, T010, sha256:1b5b3a1a0af0); FM-004,FM-005, → task Tests locators; bootstrap no-tick capture` (2026-09-06)

- [x] **T011** — Separate application expert briefing modes
  - *Files:* `agents/javascript-expert.md`, `agents/react-expert.md`, `agents/bun-monorepo-expert.md`, `agents/loopback4-expert.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Extend AC-014 cases for the four personas, preserving planning authority while requiring implementation omission/conflict reporting instead of re-deriving supplied decisions.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-014, AC-014, FM-004, FM-005, plan §2, §6
  - *Integration owner:* T027
  - *Evidence:* `bash tests/test-gate-contracts.sh → -- 8/8 passed (notes/evidence.md, T011, sha256:8d8e94845058); FM-004,FM-005, → task Tests locators; bootstrap no-tick capture` (2026-09-06)

- [x] **T012** — Separate platform expert briefing modes
  - *Files:* `agents/aws-expert.md`, `agents/python-expert.md`, `agents/expo-rn-expert.md`, `agents/firebase-rtk-codegen-expert.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Extend AC-014 mode/revision/omission cases to the remaining experts without changing their stack guidance, models or higher-priority obligations.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-014, AC-014, FM-004, FM-005, plan §2, §6
  - *Integration owner:* T027
  - *Evidence:* `bash tests/test-gate-contracts.sh → -- 9/9 passed (notes/evidence.md, T012, sha256:49e830668618); FM-004,FM-005, → task Tests locators; bootstrap no-tick capture` (2026-09-06)

- [x] **T013** — Verify test-engineer modes through generated adapters
  - *Files:* `agents/test-engineer.md`, `tests/test-gate-contracts.sh` (new in T001), `tests/test-build-adapters.sh`
  - *Acceptance:* Finish AC-014 mode examples and enumerate all expert/test personas, then regenerate through existing scripts in a sandbox and assert both modes survive adapters without editing generated files or real homes.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`, `tests/test-build-adapters.sh::test_brief_modes`
  - *Verify:* `bash tests/test-gate-contracts.sh && bash tests/test-build-adapters.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-014, AC-014, FM-002, FM-004, FM-005, plan §2, §6
  - *Evidence:* `bash -o pipefail -c bash tests/test-gate-contracts.sh && bash tests/test-build-adapters.sh → -- 8/8 passed (notes/evidence.md, T013, sha256:609e2f9c87a6); FM-002,FM-004,FM-005, → task Tests locators; bootstrap no-tick capture` (2026-09-06)

- [x] **T014** [hard] — Record class-wide reports and honest tallies
  - *Files:* `agents/opponent.agent.md`, `agents/reality-check.agent.md`, `scripts/verification-lib.sh` (new in T002), `scripts/spec-gate.sh` (new), `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-010/AC-012/AC-017 schema/tally cases for stable classes/prior findings, all locations, retained review scope and severity, canonical identities and unclassified legacy 002's five rounds/six blockers; leave carry-forward disabled.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-011, REQ-012, REQ-013, REQ-015, AC-010, AC-012, AC-017, FM-019, FM-020, INV-005, INV-006, plan §3.3, §4.3
  - *Evidence:* `bash tests/test-gate-contracts.sh → -- 13/13 passed (notes/evidence.md, T014, sha256:7dcb3a982827); FM-019,FM-020,INV-005,INV-006, → task Tests locators; bootstrap no-tick capture` (2026-09-06)

- [x] **T015** [hard] — Establish owner-only verification transaction primitives
  - *Files:* `scripts/verification-lib.sh` (new in T002), `tests/test-verification.sh` (new in T003)
  - *Acceptance:* Add AC-020/AC-022 fixtures proving failed acquisition/foreign locks survive cleanup, owned locks release on exit/signals and incomplete same-parent publications cannot appear completed.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_owned_transactions`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-009, AC-020, AC-022, FM-007, FM-008, INV-003, plan §3.2, §4.2, §4.4
  - *Evidence:* `bash tests/test-verification.sh → -- 2/2 passed (notes/evidence.md, T015, sha256:0e92dde043a9); FM-007,FM-008,INV-003, → task Tests locators; bootstrap no-tick capture` (2026-09-06)

- [x] **T016** [hard] — Fingerprint complete semantic verification inputs
  - *Files:* `scripts/verification-lib.sh` (new in T002), `tests/test-verification.sh` (new in T003), `tests/helpers.sh`
  - *Acceptance:* Implement vf_snapshot with AC-020 mutations of staged/dirty/untracked source, tests/helpers/fixtures, locks/config, ignored declarations, paths/modes/links, hashed environment/tools and semantic documents while narrowly excluding bookkeeping.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-020, FM-005, FM-007, FM-010, FM-014, plan §3.2, §4.4
  - *Evidence:* `bash tests/test-verification.sh → -- 3/3 passed (notes/evidence.md, T016, sha256:b0307d5f3643); FM-005,FM-007,FM-010,FM-014, → task Tests locators; bootstrap no-tick capture` (2026-09-07)

- [x] **T017** [hard] — Capture complete runs with bounded summaries
  - *Files:* `scripts/verification-lib.sh` (new in T002), `scripts/spec-run.sh`, `tests/test-spec-run.sh`, `tests/test-verification.sh` (new in T003)
  - *Acceptance:* Add AC-021 capture/output and transaction cases proving full logs, COMPLETE/digests, before/after identities, exact argv/from-task pipefail execution, real exits, measured output bounds and legacy key/default/no-tick compatibility.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-run.sh::test_bounded_capture`, `tests/test-verification.sh::test_owned_transactions`
  - *Verify:* `bash tests/test-spec-run.sh && bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-009, REQ-016, AC-020, AC-021, FM-006, FM-008, FM-009, INV-003, plan §3.2, §4.1, §4.4
  - *Evidence:* `CAP-1-G083Nw (notes/captures/CAP-1-G083Nw/output.log): bash tests/test-spec-run.sh && bash tests/test-verification.sh → 6/6 and 3/3 passed, exit 0; FM-006/FM-008/FM-009/INV-003 map to test_bounded_capture and test_owned_transactions; input-before equals input-after` (2026-09-07)

- [x] **T018** [hard] — Reject stale or damaged current evidence
  - *Files:* `scripts/verification-lib.sh` (new in T002), `scripts/spec-evidence.sh`, `tests/test-verification.sh` (new in T003)
  - *Acceptance:* Add AC-020/AC-023 executable cases for tampered/truncated/missing provenance, later failed same-input runs and input changes during execution, reproducing the old passing-log/failing-code gap without granting reuse or undoing historical tasks.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-020, AC-023, FM-010, FM-014, INV-001, plan §3.2, §4.4
  - *Evidence:* `CAP-2-fvXXB7 (notes/captures/CAP-2-fvXXB7/output.log): bash tests/test-verification.sh → 3/3 passed, exit 0; FM-010/FM-014/INV-001 → tests/test-verification.sh::test_capture_provenance; current and damaged evidence predicates tested` (2026-09-07)

- [x] **T019** [hard] — Accept verified returns in one transaction
  - *Files:* `scripts/verification-lib.sh` (new in T002), `scripts/spec-gate.sh` (new in T014), `scripts/spec-task.sh`, `tests/test-spec-gate.sh` (new), `tests/test-spec-task.sh`
  - *Acceptance:* Add AC-022 return/manual/atomicity fixtures covering all missing/extra/forged/stale bindings, exact tasks byte preservation, one valid/idempotent acceptance, prepared-receipt recovery and guarded done/start/undo with legacy compatibility but no gate/Ship exemption for behavioral follow-ups.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_acceptance`, `tests/test-verification.sh::test_owned_transactions`
  - *Verify:* `bash tests/test-spec-task.sh && bash tests/test-spec-gate.sh && bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-009, AC-022, FM-006, FM-010, INV-001, INV-002, INV-003, plan §3.2, §4.2
  - *Evidence:* CAP-3-F6tBsK verified by spec-gate accept; return sha256:28ba4c1dedc5aa5b508c026fd792b196804f79f5d765932ccc9e627facbfebbd

- [x] **T020** [hard] — Run the fresh deterministic gate floor
  - *Files:* `scripts/spec-gate.sh` (new in T014), `scripts/verification-lib.sh` (new in T002), `tests/test-spec-gate.sh` (new in T019)
  - *Acceptance:* Add AC-007 counters for all three checkers, every gate_check, correct existing worktree/cwd, current-evidence refresh and nonzero-before-gate refusal, recording bounded floor captures with reuse still disabled.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_floor`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-007, REQ-009, REQ-016, AC-007, FM-011, FM-012, FM-013, INV-001, INV-004, plan §3.3, §4.1, §4.3
  - *Integration owner:* T027
  - *Evidence:* CAP-4-9AgF6L verified by spec-gate accept; return sha256:f85c6d1f9363281fb9e33a338adc6c768367602c60b91e31a46fc39af8acb7cb

- [ ] **T021** [hard] — Checkpoint completed and retained coverage bindings
  - *Files:* `scripts/spec-gate.sh` (new in T014), `scripts/spec-ac-coverage.sh`, `scripts/verification-lib.sh` (new in T002), `tests/test-spec-gate.sh` (new in T019)
  - *Acceptance:* Add AC-008 cases for exact failure/pipeline exits, no-command coverage checks, lost completed/prior bindings, future ACs and explicit integration owners, with the next-stage counter unchanged on failure.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_checkpoints`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-008, REQ-009, AC-008, FM-012, FM-013, FM-015, INV-004, plan §3.3, §4.1, §4.3
  - *Integration owner:* T027

- [ ] **T022** [hard] — Enforce round reservations and scoped authorization
  - *Files:* `scripts/spec-gate.sh` (new in T014), `scripts/verification-lib.sh` (new in T002), `tests/test-spec-gate.sh` (new in T019), `tests/test-verification.sh` (new in T003)
  - *Acceptance:* Add AC-009 cases for both gates, exact rounds/UTC/calendar validation, denied fourth and subsequent runs, one-round user waivers/revisions, quoted/malformed/duplicate/legacy reports, interruption recovery and serialized reservations with recurring-class output.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`, `tests/test-verification.sh::test_owned_transactions`
  - *Verify:* `bash tests/test-spec-gate.sh && bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, REQ-015, AC-009, FM-016, FM-017, FM-018, INV-003, INV-004, plan §3.3, §4.1, §4.3

- [ ] **T023** [hard] — Enable reuse after negative provenance fixtures
  - *Files:* `scripts/verification-lib.sh` (new in T002), `scripts/spec-gate.sh` (new in T014), `tests/test-verification.sh` (new in T003), `tests/test-spec-gate.sh` (new in T019), `.specify/stack.yml`
  - *Acceptance:* Complete AC-007/AC-008/AC-020 reuse cases before enabling local opt-in: unchanged suite executes once across gates/checkpoints, source/command/cwd/tool/environment changes miss, integrity reruns after bookkeeping, and unknown/external/time checks never reuse.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`, `tests/test-spec-gate.sh::test_floor`, `tests/test-spec-gate.sh::test_checkpoints`
  - *Verify:* `bash tests/test-verification.sh && bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-007, REQ-008, REQ-009, AC-007, AC-008, AC-020, FM-010, FM-012, FM-014, INV-001, plan §3.2, §4.3, §8
  - *Integration owner:* T027

- [ ] **T024** [hard] — Validate incremental reality-check evidence matrices
  - *Files:* `agents/reality-check.agent.md`, `scripts/verification-lib.sh` (new in T002), `scripts/spec-gate.sh` (new in T014), `tests/test-verification.sh` (new in T003), `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-013 matrix fixtures that include every AC, carry only valid unchanged rows, invalidate each specified source/dependency/criterion mutation and unknown impact, and use current floor captures without treating execution as semantic PASS.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`, `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-verification.sh && bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, REQ-013, AC-013, FM-010, FM-020, INV-001, INV-005, plan §3.3, §4.3
  - *Integration owner:* T027

## API

- [ ] **T025** [hard] — Wire every invoker to deterministic acceptance
  - *Files:* `agents/sdd-orchestrator.md`, `skills/sdd-implement/SKILL.md`, `skills/sdd-go/SKILL.md`, `skills/sdd-review/SKILL.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-015 executable stub sequences plus entrypoint assertions proving no-tick/accept, one escalation retry, batch barriers, checkpoints, fresh floors and round refusal stop dispatch, replacing old cap/re-gate prose in all four invokers.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_invoker_protocol`, `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-007, REQ-008, REQ-009, REQ-012, REQ-014, REQ-016, AC-015, FM-004, FM-007, FM-013, INV-004, plan §4.2, §4.3, §8
  - *Integration owner:* T027

## Tests

- [ ] **T026** — Add the noncircular live-wiring probe checker
  - *Files:* `tests/probe-gate-contract.sh` (new), `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-016 positive/negative sandbox fixtures for genuine rejection/acceptance digests and gate/floor identities, accepting an active reality-check reservation before its completed report while rejecting missing observations without making the default suite require live reports.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_invoker_protocol`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-007, REQ-012, REQ-016, AC-016, FM-018, INV-004, plan §2, §8
  - *Notes:* This task accepts the probe's fixtures only; T029 supplies the real worker control, and T030/T031 supply the actual gate observations.

- [ ] **T027** — Exercise cross-component and portability integration
  - *Files:* `tests/test-gate-contracts.sh` (new in T001), `tests/test-build-adapters.sh`
  - *Acceptance:* Add cross-component AC-007/AC-008/AC-013/AC-015/AC-019 integration cases composing existing local tests, enumerate all overlays/personas, regenerate final adapters in sandboxes and retain actual suite/ShellCheck platform evidence without treating a local run as the remote matrix.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_invoker_protocol`, `tests/test-spec-gate.sh::test_floor`, `tests/test-spec-gate.sh::test_checkpoints`, `tests/test-verification.sh::test_capture_provenance`, `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-gate-contracts.sh::test_instruction_contracts`, `tests/test-build-adapters.sh::test_brief_modes`, `tests/test-spec-run.sh::test_bounded_capture`
  - *Verify:* `bash tests/run.sh && shellcheck -S warning -x scripts/*.sh tests/*.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-001, REQ-003, REQ-007, REQ-008, REQ-009, REQ-013, REQ-014, AC-002, AC-007, AC-008, AC-013, AC-014, AC-015, AC-019, FM-002, FM-007, FM-012, FM-013, INV-001, INV-004, plan §5, §7, §8
  - *Notes:* AC-019 needs actual Linux/macOS/Bash-3.2 execution evidence before T031 READY, plus the normal PR CI afterward; if no authorized executor is available, stop implementation and request an execution route rather than inventing a PASS.

## Observability

- [ ] **T028** — Record cost and quality without invented savings
  - *Files:* `templates/retro-template.md`, `skills/sdd-retro/SKILL.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-017 assertions for stable class versus process root cause, raw sites/reopened findings, actual-or-unknown usage/baselines, execution/reuse/byte counts and a named 14-day observation owner/check-back.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`, `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-001, REQ-015, AC-017, FM-019, FM-020, INV-006, plan §8

## Docs

- [ ] **T029** — Document and exercise the public verification workflow
  - *Files:* `README.md`, `constitution.md`, `templates/verification-contract.md` (new in T001), `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-018 fixtures that execute documented examples and all five help entries, explain compatibility/freshness/no-tick/summary/class/scope/cap rules, and preserve models, separate gates and security-review authority.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-001, REQ-007, REQ-008, REQ-009, REQ-010, REQ-011, REQ-012, REQ-015, REQ-016, AC-018, FM-001, INV-005, plan §3, §4, §8
  - *Notes:* For AC-016's real control, the invoker rejects one deliberately incomplete copy of this worker's no-tick return, records unchanged task digests, then accepts the intact original; an intentional control is not a failed worker retry.

## Reality Check (pre-ship gate)

- [ ] **T030** — Opponent review: attack classes before clearance
  - *Files:* `notes/opponent.md` (new, spec-local), `notes/evidence.md` (new, generated), `STATUS.md` (spec-local)
  - *Agent:* `~/.sdd/agents/opponent.agent.md`
  - *Inputs:* Accepted spec/plan, branch diff including dirty/untracked inputs, all completed tasks, prior findings, branch-local agents/opponent.agent.md contract and a current floor/script-granted round.
  - *Acceptance:* Independent opponent returns CLEARED in a canonical completed report with every established blocker/class/site, searched/unexamined scope and valid earlier floor/round identities; no skipped or softened verdict.
  - *Verify:* `manual: invoker runs worktree-local spec-gate floor, reserves opponent round, supplies those identities to the independent gate and completes its returned report`
  - *Refs:* REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, REQ-007, REQ-008, REQ-009, REQ-010, REQ-011, REQ-012, REQ-013, REQ-014, REQ-015, REQ-016, AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008, AC-009, AC-010, AC-011, AC-012, AC-013, AC-014, AC-015, AC-016, AC-017, AC-018, AC-019, AC-020, AC-021, AC-022, AC-023, plan §4.3, §8
  - *Notes:* On CHALLENGED, open T030o1-style class-wide follow-ups with sibling sweeps and tests, then refresh floor and obtain a new permitted round; a denied fourth round stops for explicit user authorization.

- [ ] **T031** — Reality-check every criterion against current proof
  - *Files:* `notes/reality-check.md` (new, spec-local), `notes/evidence.md` (new, generated), `STATUS.md` (spec-local)
  - *Agent:* `~/.sdd/agents/reality-check.agent.md`
  - *Inputs:* T030 CLEARED report, complete AC matrix, prior source/diff and evidence, branch-local agents/reality-check.agent.md contract, current floor and script-granted reality-check reservation.
  - *Acceptance:* Independent reality-check returns READY only after every AC has valid proof and the real AC-016 probe passes against the completed opponent plus active reality-check reservation, then its completed report validates matching identities.
  - *Verify:* `manual: reserve reality-check after a current floor, run bash tests/probe-gate-contract.sh .specify/specs/003-gate-round-reduction-and-token-discipline during the review, and validate the returned report through spec-gate round --complete`
  - *Refs:* AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008, AC-009, AC-010, AC-011, AC-012, AC-013, AC-014, AC-015, AC-016, AC-017, AC-018, AC-019, AC-020, AC-021, AC-022, AC-023, plan §3.3, §4.3, §8
  - *Notes:* On NEEDS WORK/FAILED, open T031a1-style follow-ups, refresh impacted proof and re-gate under the same cap; carry only proven unchanged PASS rows and never omit an AC.

## Ship

- [ ] **T032** — Open the guarded PR to main
  - *Files:* `STATUS.md` (spec-local; PR metadata)
  - *Acceptance:* With both current gates clear, the existing PR helper returns a PR URL targeting main with spec/plan/gate references and records phase review; /sdd:review then owns CI, feedback, re-gating and merge.
  - *Verify:* `manual: bash scripts/spec-pr.sh .specify/specs/003-gate-round-reduction-and-token-discipline; confirm the recorded PR base and both verdicts`
  - *Refs:* REQ-001, AC-019, plan §8
  - *Notes:* No default reviewer is invented; use the project's configured reviewer or request that choice when opening the PR.

- [ ] **T033** — Roll out only after verified merge
  - *Files:* `STATUS.md` (spec-local), `notes/evidence.md` (new, generated)
  - *Acceptance:* After /sdd:review confirms merge and the real existing CI matrix is green, perform the established public-to-private byte-identical port and supported regeneration/sync/doctor checks, recording any actual environment prerequisite failure instead of clearing it.
  - *Verify:* `manual: inspect actual merged PR/CI evidence, verify kit-file parity after the established port, then run the installed sync --check and doctor against their configured environment`
  - *Refs:* AC-019, AC-023, plan §5, §8
  - *Notes:* Do not invent a private-clone path or install into unrelated homes; resolve the existing post-merge target at rollout, and stop for authority if that target cannot be established.

- [ ] **T034** — Harvest the retro and assign quality follow-up
  - *Files:* `notes/retro.md` (new, spec-local), `STATUS.md` (spec-local)
  - *Acceptance:* Run /sdd:retro with real tally/usage/execution evidence, record unknown measurements honestly, name the 14-day defect-observation owner/date and next three measurement specs as available, and set retro done only after the artifact exists.
  - *Verify:* `manual: compare notes/retro.md with spec-gate tally and actual usage observations, then confirm STATUS records the quality owner/date and retro done`
  - *Refs:* REQ-001, REQ-015, AC-017, plan §8

---

Next: /sdd:implement (or /sdd:implement T001). Checkboxes remain unticked until
actual acceptance. After T032, /sdd:review owns CI/feedback/merge; T033/T034 run
after merge. Do not mark tasks complete merely because this checklist is written.
