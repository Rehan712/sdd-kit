---
tasks_for: 003-gate-round-reduction-and-token-discipline
status: in-progress  # draft | in-progress | complete
created: 2026-09-05
updated: 2026-10-26
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
  - *Evidence:* CAP-13-APrAYv verified by spec-gate accept; return sha256:42a5204db5040542601f95449b108c89e3abc28cbbe63e3082e7a85cc602ce21

- [x] **T002** [hard] — Validate phase-aware failure and test bindings
  - *Files:* `scripts/verification-lib.sh` (new), `scripts/sdd-analyze.sh`, `templates/tasks-template.md`, `tests/test-sdd-analyze.sh`, `tests/helpers.sh`
  - *Acceptance:* Implement vf_bindings and typed task fields with AC-001/AC-003/AC-004/AC-006/AC-023 fixtures for shared/duplicate/dangling IDs, phase boundaries, valid shell/custom/static/manual kinds, deferred local coverage, proof-required behavioral follow-ups and unchanged shipped-spec exit 0.
  - *Verify kind:* test
  - *Tests:* `tests/test-sdd-analyze.sh::test_verification_bindings`
  - *Verify:* `bash tests/test-sdd-analyze.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-004, REQ-005, AC-001, AC-003, AC-004, AC-006, AC-023, FM-001, FM-002, FM-003, INV-005, plan §3.1, §4.1
  - *Evidence:* CAP-21-dKb6XY verified by spec-gate accept; return sha256:8cc6358199d897240a361512ad43a50adfe3d3c5770fbcdec72af11187edd9fa

- [x] **T003** [P] [hard] — Parse verification commands without losing arguments
  - *Depends on:* T002
  - *Files:* `scripts/verification-lib.sh` (new in T002), `scripts/sdd-analyze.sh`, `scripts/sdd-doctor.sh`, `tests/test-verification.sh` (new), `.specify/stack.yml`
  - *Acceptance:* Implement vf_config with AC-011 fixtures for lossless quoting, malformed/duplicate/unknown keys and stages, phase deferral and legacy warnings; declare the real suite/ShellCheck gate_checks and Backend/API checkpoints while keeping reuse disabled.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_config_grammar`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-007, REQ-008, AC-011, AC-023, FM-006, FM-011, plan §3.1, §4.1, §6
  - *Evidence:* CAP-15-4eF31Y verified by spec-gate accept; return sha256:dfd9192db5bd1246c88ab052399d8f3a99f9037e732f846a4e0c8ace0dbf6967

- [x] **T003f1** — Keep authoring fixtures valid under gate configuration
  - *Files:* `tests/helpers.sh`, `tests/test-sdd-analyze.sh`, `scripts/verification-lib.sh`
  - *Acceptance:* Existing clean authoring fixtures declare their illustrative gate list; missing legacy configuration warns without failing; exact test ownership accepts supported new-file annotations while rejecting lookalike paths.
  - *Verify kind:* test
  - *Tests:* `tests/test-sdd-analyze.sh::test_verification_bindings`
  - *Verify:* `bash tests/test-sdd-analyze.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-005, REQ-007, AC-006, AC-011, AC-023, FM-002, plan §3.1, §7
  - *Notes:* Required sibling fixture adjustment discovered during T003 integration; no shipped spec rewrite or weakening of missing-configuration checks.
  - *Evidence:* CAP-14-jVE3FM verified by spec-gate accept; return sha256:871b20e0e128cf6a974f33a235f09222aee2540a9c97c0005e597b976823af41

- [x] **T004** [P] — Teach planning and task-local test ownership
  - *Depends on:* T002
  - *Files:* `skills/sdd-plan/SKILL.md`, `skills/sdd-tasks/SKILL.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-006/AC-017 instruction assertions for planning-time families, task-time bindings, same-commit behavioral tests and integration-only Tests stages without copying the grammar into both skills.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-004, REQ-005, AC-006, AC-017, FM-001, INV-005, plan §2, §3.1
  - *Evidence:* CAP-13-APrAYv verified by spec-gate accept; return sha256:6b329efb5abc20189f6a852f76a98ba7d2f528fa206c545038d4f28cf24c8c07

- [x] **T005** [P] — Refresh the calibrated verification example
  - *Depends on:* T002
  - *Files:* `templates/examples/001-api-key-expiry/spec.md`, `templates/examples/001-api-key-expiry/plan.md`, `templates/examples/001-api-key-expiry/tasks.md`, `templates/examples/001-api-key-expiry/README.md`, `tests/test-golden-example.sh`
  - *Acceptance:* Add AC-005 fixtures proving concrete FM/INV families, non-gate bindings and appropriate Verify kinds pass the updated analyzer with zero warnings in a sandbox project; shipped 001/002 remain untouched.
  - *Verify kind:* test
  - *Tests:* `tests/test-golden-example.sh::test_verification_golden`
  - *Verify:* `bash tests/test-golden-example.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-004, REQ-005, AC-005, FM-002, plan §3.1, §7
  - *Evidence:* CAP-16-VBzeMz verified by spec-gate accept; return sha256:c135715b01ce47330666ae2393e814236c632266dfbdd257e4f33950d7c2b71a

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
  - *Evidence:* CAP-13-APrAYv verified by spec-gate accept; return sha256:99c23313db9a2a4d5fe9a4ab0d479d71968a5f96fc696b54ff202f4d57ed2d4f

- [x] **T007** — Add JavaScript and application-stack defaults
  - *Files:* `templates/stack-overlays/javascript.md`, `templates/stack-overlays/react.md`, `templates/stack-overlays/bun-monorepo.md`, `templates/stack-overlays/loopback4.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Extend AC-002 cases for these four overlays, including JavaScript/React's three-scenario minimum, async/state/error boundaries and their appropriate stage commands.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-003, REQ-008, AC-002, FM-001, plan §6
  - *Integration owner:* T027
  - *Evidence:* CAP-13-APrAYv verified by spec-gate accept; return sha256:a34bf841e79646c985a463cfcda1bc0927b7957c435e264d0a56151901bdec3c

- [x] **T008** — Add mobile and platform-stack defaults
  - *Files:* `templates/stack-overlays/expo-rn.md`, `templates/stack-overlays/firebase-rtk-codegen.md`, `templates/stack-overlays/python.md`, `templates/stack-overlays/aws.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Extend AC-002 cases with stack-specific boundary/state/failure prompts and useful checkpoint commands for all four overlays rather than generic copied rows.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-003, REQ-008, AC-002, FM-001, plan §6
  - *Integration owner:* T027
  - *Evidence:* CAP-13-APrAYv verified by spec-gate accept; return sha256:9d006c920dbdb1aca7213869aba27e6401a66d92e6b8e32a214e14ff8280cc32

- [x] **T009** — Finish defaults and enumerate every overlay
  - *Files:* `templates/stack-overlays/monorepo.md`, `templates/stack-overlays/troposphere.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Complete AC-002 defaults and add the directory-wide enumeration assertion so all 14 current overlays and any newly shipped overlay must satisfy the contract.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-003, REQ-008, AC-002, FM-001, FM-002, plan §6
  - *Evidence:* CAP-13-APrAYv verified by spec-gate accept; return sha256:cae08708a95cfbf2f8ec7060e245e5ed4d5735a7775f018862299129d714da76

- [x] **T010** — Separate compiled-stack expert briefing modes
  - *Files:* `agents/rust-expert.md`, `agents/rust-aws-lambda-expert.md`, `agents/aws-cdk-lambda-ts-expert.md`, `agents/nextjs-expert.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-014 assertions for planning consultation versus authoritative implementation slices, revision/binding fields, existing-slice recovery and higher-priority-rule precedence in all four personas.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-014, AC-014, FM-004, FM-005, plan §2, §6
  - *Integration owner:* T027
  - *Evidence:* CAP-13-APrAYv verified by spec-gate accept; return sha256:a7be45127c078316f5716b272a48db75726dfd4998604d35eea80e206f3d47c6

- [x] **T011** — Separate application expert briefing modes
  - *Files:* `agents/javascript-expert.md`, `agents/react-expert.md`, `agents/bun-monorepo-expert.md`, `agents/loopback4-expert.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Extend AC-014 cases for the four personas, preserving planning authority while requiring implementation omission/conflict reporting instead of re-deriving supplied decisions.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-014, AC-014, FM-004, FM-005, plan §2, §6
  - *Integration owner:* T027
  - *Evidence:* CAP-13-APrAYv verified by spec-gate accept; return sha256:7cb5e0c2db3cea45ffbf8ae2f4819fe7bed8b5e8b1bbfb6caee522cc9668dda0

- [x] **T012** — Separate platform expert briefing modes
  - *Files:* `agents/aws-expert.md`, `agents/python-expert.md`, `agents/expo-rn-expert.md`, `agents/firebase-rtk-codegen-expert.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Extend AC-014 mode/revision/omission cases to the remaining experts without changing their stack guidance, models or higher-priority obligations.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-014, AC-014, FM-004, FM-005, plan §2, §6
  - *Integration owner:* T027
  - *Evidence:* CAP-13-APrAYv verified by spec-gate accept; return sha256:577196358084b949f98f8e94efa0b98d3fc9b48b95e0e84d1c8e578fcd3ef278

- [x] **T013** — Verify test-engineer modes through generated adapters
  - *Files:* `agents/test-engineer.md`, `tests/test-gate-contracts.sh` (new in T001), `tests/test-build-adapters.sh`
  - *Acceptance:* Finish AC-014 mode examples and enumerate all expert/test personas, then regenerate through existing scripts in a sandbox and assert both modes survive adapters without editing generated files or real homes.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`, `tests/test-build-adapters.sh::test_brief_modes`
  - *Verify:* `bash tests/test-gate-contracts.sh && bash tests/test-build-adapters.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-014, AC-014, FM-002, FM-004, FM-005, plan §2, §6
  - *Evidence:* CAP-17-nUBCdM verified by spec-gate accept; return sha256:0539541a54d9dc82a4af35832b9e4a42ce99ba081f22b67b925dd514820bb81d

- [x] **T014** [hard] — Record class-wide reports and honest tallies
  - *Files:* `agents/opponent.agent.md`, `agents/reality-check.agent.md`, `scripts/verification-lib.sh` (new in T002), `scripts/spec-gate.sh` (new), `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-010/AC-012/AC-017 schema/tally cases for stable classes/prior findings, all locations, retained review scope and severity, canonical identities and unclassified legacy 002's five rounds/six blockers; leave carry-forward disabled.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-011, REQ-012, REQ-013, REQ-015, AC-010, AC-012, AC-017, FM-019, FM-020, INV-005, INV-006, plan §3.3, §4.3
  - *Evidence:* CAP-13-APrAYv verified by spec-gate accept; return sha256:4e95d859e2575828d35aaae58b71ce4cad25282079616ed2276ccf9812db8f6b

- [x] **T015** [hard] — Establish owner-only verification transaction primitives
  - *Files:* `scripts/verification-lib.sh` (new in T002), `tests/test-verification.sh` (new in T003)
  - *Acceptance:* Add AC-020/AC-022 fixtures proving failed acquisition/foreign locks survive cleanup, owned locks release on exit/signals and incomplete same-parent publications cannot appear completed.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_owned_transactions`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-009, AC-020, AC-022, FM-007, FM-008, INV-003, plan §3.2, §4.2, §4.4
  - *Evidence:* CAP-15-4eF31Y verified by spec-gate accept; return sha256:6d846f8ac37c320a98b53033df7a1a912bb3a456b345b04d18b568b06298a84f

- [x] **T016** [hard] — Fingerprint complete semantic verification inputs
  - *Files:* `scripts/verification-lib.sh` (new in T002), `tests/test-verification.sh` (new in T003), `tests/helpers.sh`
  - *Acceptance:* Implement vf_snapshot with AC-020 mutations of staged/dirty/untracked source, tests/helpers/fixtures, locks/config, ignored declarations, paths/modes/links, hashed environment/tools and semantic documents while narrowly excluding bookkeeping.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-020, FM-005, FM-007, FM-010, FM-014, plan §3.2, §4.4
  - *Evidence:* CAP-15-4eF31Y verified by spec-gate accept; return sha256:f1c99477275f5fe2b4babdb3106470b6f1687b357d6820c9ae75c62b7d0ad190

- [x] **T017** [hard] — Capture complete runs with bounded summaries
  - *Files:* `scripts/verification-lib.sh` (new in T002), `scripts/spec-run.sh`, `tests/test-spec-run.sh`, `tests/test-verification.sh` (new in T003)
  - *Acceptance:* Add AC-021 capture/output and transaction cases proving full logs, COMPLETE/digests, before/after identities, exact argv/from-task pipefail execution, real exits, measured output bounds and legacy key/default/no-tick compatibility.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-run.sh::test_bounded_capture`, `tests/test-verification.sh::test_owned_transactions`
  - *Verify:* `bash tests/test-spec-run.sh && bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-009, REQ-016, AC-020, AC-021, FM-006, FM-008, FM-009, INV-003, plan §3.2, §4.1, §4.4
  - *Evidence:* CAP-18-l2UUu5 verified by spec-gate accept; return sha256:2c06596c364c9d1ffd013a5d25bb77605ef424ce64ccff7e84dae95d19c5841d

- [x] **T018** [hard] — Reject stale or damaged current evidence
  - *Files:* `scripts/verification-lib.sh` (new in T002), `scripts/spec-evidence.sh`, `tests/test-verification.sh` (new in T003)
  - *Acceptance:* Add AC-020/AC-023 executable cases for tampered/truncated/missing provenance, later failed same-input runs and input changes during execution, reproducing the old passing-log/failing-code gap without granting reuse or undoing historical tasks.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-020, AC-023, FM-010, FM-014, INV-001, plan §3.2, §4.4
  - *Evidence:* CAP-19-YqoEuW verified by spec-gate accept; return sha256:206e6d6c150debc3f066dfa71c75f00064c392f9920fb1cb237b6b346ccda1ec

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

- [x] **T021** [hard] — Checkpoint completed and retained coverage bindings
  - *Files:* `scripts/spec-gate.sh` (new in T014), `scripts/spec-ac-coverage.sh`, `scripts/verification-lib.sh` (new in T002), `tests/test-spec-gate.sh` (new in T019)
  - *Acceptance:* Add AC-008 cases for exact failure/pipeline exits, no-command coverage checks, lost completed/prior bindings, future ACs and explicit integration owners, with the next-stage counter unchanged on failure.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_checkpoints`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-008, REQ-009, AC-008, FM-012, FM-013, FM-015, INV-004, plan §3.3, §4.1, §4.3
  - *Integration owner:* T027
  - *Evidence:* CAP-5-lU4jNB verified by spec-gate accept; return sha256:b6a19d62e54ddfe235cb0b8c6e4a346b6058270ae7f55d02382f8458ee9dedc0

- [x] **T022** [hard] — Enforce round reservations and scoped authorization
  - *Files:* `scripts/spec-gate.sh` (new in T014), `scripts/verification-lib.sh` (new in T002), `tests/test-spec-gate.sh` (new in T019), `tests/test-verification.sh` (new in T003)
  - *Acceptance:* Add AC-009 cases for both gates, exact rounds/UTC/calendar validation, denied fourth and subsequent runs, one-round user waivers/revisions, quoted/malformed/duplicate/legacy reports, interruption recovery and serialized reservations with recurring-class output.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`, `tests/test-verification.sh::test_owned_transactions`
  - *Verify:* `bash tests/test-spec-gate.sh && bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, REQ-015, AC-009, FM-016, FM-017, FM-018, INV-003, INV-004, plan §3.3, §4.1, §4.3
  - *Evidence:* CAP-9-FZwaR4 verified by spec-gate accept; return sha256:7385bc8a188f76ce0654da500b90d45072e6d58c9686f03544cb99a26ef17211

- [x] **T023** [hard] — Enable reuse after negative provenance fixtures
  - *Files:* `scripts/verification-lib.sh` (new in T002), `scripts/spec-gate.sh` (new in T014), `tests/test-verification.sh` (new in T003), `tests/test-spec-gate.sh` (new in T019), `.specify/stack.yml`
  - *Acceptance:* Complete AC-007/AC-008/AC-020 reuse cases before enabling local opt-in: unchanged suite executes once across gates/checkpoints, source/command/cwd/tool/environment changes miss, integrity reruns after bookkeeping, and unknown/external/time checks never reuse.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`, `tests/test-spec-gate.sh::test_floor`, `tests/test-spec-gate.sh::test_checkpoints`
  - *Verify:* `bash tests/test-verification.sh && bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-007, REQ-008, REQ-009, AC-007, AC-008, AC-020, FM-010, FM-012, FM-014, INV-001, plan §3.2, §4.3, §8
  - *Integration owner:* T027
  - *Evidence:* CAP-10-rSCipE verified by spec-gate accept; return sha256:1629bfbcb30fee1c680a080317bf9dafb69229f4e90f34a2446c77d9b74ea853

- [x] **T024** [hard] — Validate incremental reality-check evidence matrices
  - *Files:* `agents/reality-check.agent.md`, `scripts/verification-lib.sh` (new in T002), `scripts/spec-gate.sh` (new in T014), `tests/test-verification.sh` (new in T003), `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-013 matrix fixtures that include every AC, carry only valid unchanged rows, invalidate each specified source/dependency/criterion mutation and unknown impact, and use current floor captures without treating execution as semantic PASS.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`, `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-verification.sh && bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, REQ-013, AC-013, FM-010, FM-020, INV-001, INV-005, plan §3.3, §4.3
  - *Integration owner:* T027
  - *Evidence:* CAP-11-VYrZH0 verified by spec-gate accept; return sha256:55c8135c667ef0be58c5077d6cfd4712a069cefb77ea6e6e5656136e22523809

- [x] **T030o1** — Accept permitted narrative around the return envelope
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`, `templates/verification-contract.md`
  - *Acceptance:* A return whose complete `Verification-Return: 1` block is preceded or followed by ordinary prose is accepted; inside the block every field stays strictly validated, so missing, extra, duplicate, unknown or malformed mappings still reject and leave task state unchanged.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_acceptance`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, AC-022, FM-006, plan §4.2
  - *Notes:* Owns opponent finding O-001. `vf_return_parse` is the sole runtime consumer through `vf_return_check`; delimit the block rather than loosening field validation, and add leading- and trailing-narrative positives beside negatives proving in-block strictness is unchanged.
  - *Evidence:* CAP-89-0bLgSL verified by spec-gate accept; return sha256:0b9f15fef55f01885acfe1a6486efabc7bb46629dae0c909d61e0b07f95eff74

- [x] **T030o2** — Validate round authorizations against the whole line
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`, `templates/verification-contract.md`
  - *Acceptance:* Only an exact `- <UTC> — waiver:`/`spec-revision:` Decisions line authorizes a round past the cap; text inserted between timestamp and separator, leading or trailing text, altered separators and malformed timestamps all fail closed on both branches, while a valid authorization still grants exactly its named gate and round.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, FM-016, plan §3.3, §4.3
  - *Notes:* Owns opponent finding O-002. Validate the whole line instead of a permissive prefix plus a fixed 20-character substring; the waiver and spec-revision branches share one matcher, so the negatives cover the shared parser once.
  - *Evidence:* CAP-90-vaH6bG verified by spec-gate accept; return sha256:56d1ce8d16938f376be2fb1681190fe11e1b3a5cc147016812bc591517aa6a8a

- [x] **T030o4** — Enforce the full gate-report schema at completion
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* `round --complete` refuses a report omitting any required top-level section — including `### What I attacked` and the searched/unexamined scope record — or any required finding field, including `Wrong behavior` and `Class-wide fix`; a canonical report still validates and its tally is unchanged.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-012, AC-012, FM-019, plan §3.3, §4.3
  - *Notes:* Owns opponent finding O-004. `vf_reports` is the schema validator `round --complete` calls, so a scope-less CLEARED report is canonizable today; add one omission negative per required section and per required finding field.
  - *Evidence:* CAP-91-myxn7k verified by spec-gate accept; return sha256:ea37e3664b05444c53983140e181dced8e3be3c8bea52215faf79fb3756f0843

- [x] **T030o5** — Close the configuration shell-expansion grammar
  - *Files:* `scripts/verification-lib.sh`, `tests/test-verification.sh`
  - *Acceptance:* Configuration scalars reject every unescaped shell expansion the grammar forbids — `$1`, `$?`, `$$`, `$!`, `$-`, `$*`, `$@` and arithmetic expansion beside the existing `$NAME`, `${…}` and `$(…)` — with the named configuration failure; valid commands keep working across the gate, checkpoint, reuse, tool and input lists that share the parser.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_config_grammar`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-007, REQ-008, AC-011, FM-011, plan §3.1
  - *Notes:* Owns opponent finding O-005. One shared scalar parser serves every list, so the fix is single-site and the negatives enumerate the forms; execution strings are the affected consumer because Bash expands them at run time.
  - *Evidence:* CAP-92-pit8L4 verified by spec-gate accept; return sha256:b7c14e3fdecfcf12a2c955fc40dd161c2d32dc002efa0623efee433bee432d33

- [x] **T030o11** — Refuse content after a completed round marker
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* A report carrying any non-blank line after a round completion marker and before the next `## Round n` heading is refused, so a round-2 preamble can no longer be absorbed into round 1; completion additionally re-verifies every previously sealed round digest against the combined file before publishing, and a shift fails the completion instead of wedging later invocations. Legacy reports without markers keep their current behavior and round 1 keeps digest 1ac95178.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, FM-016, plan §3.3, §4.3
  - *Notes:* Owns opponent finding O-007 and closes O-004's after-marker variant. Takes the second of the two alternatives the report offered: `vf_report_block` accumulation is left alone because changing it could alter already-sealed digests, including round 1's own. Recovery needs no ledger edit — correct the report and re-run `--complete`.
  - *Evidence:* CAP-113-uM6Ym4 verified by spec-gate accept; return sha256:0196769d8e69e27b6e2ec2983dc4553aed627263a4e2dd41971bda21f17fa80f

- [x] **T030o7** — Suppress quoted round authorizations
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Only an unquoted Decisions bullet authorizes an extra round: a byte-identical authorization line inside a fenced block, a tilde-fenced block, an indented code block or a blockquote authorizes nothing, on both the waiver and spec-revision branches, while a real unquoted line still grants exactly its named gate and round.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, FM-016, plan §3.3, §4.3
  - *Notes:* Owns opponent finding O-002, reopened because T030o2 anchored the line grammar without the fence/blockquote suppression its three sibling parsers already have. Deliberately does not change `vf_semantic_file`: the manifest must keep hashing fenced Decisions content, and that asymmetry is argued in STATUS Decisions.
  - *Evidence:* CAP-114-MtMR9N verified by spec-gate accept; return sha256:67f9ae55c235c13ddf3de3a05a0f05b0ca3c13e87d69c545e0b3a0089a668df9

- [x] **T030o9** — Require real content in every report section
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* Each required report section must contain at least one non-blank, non-heading line, so a bare heading no longer satisfies the schema for either gate, and a canonical finding recorded as `Status: resolved` is refused when `Prior` is `none` or names no valid finding ID, so a report cannot keep a blocking finding and still count zero blockers.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-011, AC-012, FM-019, plan §3.3, §4.3
  - *Notes:* Owns opponent finding O-004, reopened because T030o4 only tested heading deletion. Enforces `Prior` non-none rather than the report's stricter cross-round rule, which would reject the already-canonized round 1; the reasoning is in STATUS Decisions. The after-marker shape is closed by T030o11.
  - *Evidence:* CAP-116-EEJH8Y verified by spec-gate accept; return sha256:fac5016eef3d58d6590ae3d5fbe043a35b4afec4ae89d05e1ea521c19c9cfbf7

- [x] **T030o10** — Reject backtick substitution in configuration
  - *Files:* `scripts/verification-lib.sh`, `tests/test-verification.sh`, `templates/verification-contract.md`
  - *Acceptance:* Configuration scalars reject unescaped backtick command substitution, including nested backticks, and reject word-initial tilde expansion because it depends on the caller environment; brace expansion stays permitted as deterministic, the enforced set is stated in the contract template, and a literal end anchor such as `grep -c '^ok$'` still parses byte-for-byte.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_config_grammar`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-007, REQ-008, REQ-009, AC-011, FM-011, plan §3.1
  - *Notes:* Owns opponent finding O-005, reopened because T030o5 enumerated exactly the dollar forms the prior finding named and its own comment overclaimed the coverage. A backticked check is invocation- or time-dependent yet reusable under an identity that does not record what ran, which REQ-009 forbids.
  - *Evidence:* CAP-117-hc1bP6 verified by spec-gate accept; return sha256:371ce5915065dc35e8c316afca8fec19cf45bfc79bdde9041446e596078321ee

- [x] **T030o12** [hard] — Close the fence grammar in every quoted-content parser
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`, `tests/test-gate-contracts.sh`, `tests/test-verification.sh`, `tests/test-sdd-analyze.sh`, `templates/verification-contract.md`
  - *Acceptance:* One shared tracker replaces all six single-boolean fence togglers: a block closes only on a run of the same character at least as long as its opener and carrying no info string, and an indent of four or more columns is content. A quoted round authorization, round heading, reality-check matrix row, task stage or failure-mode definition row inside a nested example then authorizes and defines nothing, on both gates and both authorization forms, while a real record after a closed example is still parsed and opponent round 1 keeps report digest 1ac95178.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`, `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-verification.sh::test_config_grammar`, `tests/test-sdd-analyze.sh::test_verification_bindings`
  - *Verify:* `bash tests/test-spec-gate.sh && bash tests/test-gate-contracts.sh && bash tests/test-verification.sh && bash tests/test-sdd-analyze.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-008, REQ-012, REQ-013, AC-003, AC-009, AC-010, AC-011, AC-013, FM-001, FM-011, FM-016, FM-020, plan §3.1, §3.3, §4.3
  - *Notes:* Owns opponent finding O-002, reopened a second time. T030o7 added the suppression but kept one toggled boolean, so an inner shorter run or the other fence character switched it off and exposed the quoted authorization. The five sibling parsers the round-1 report named from source are repaired by the same tracker and each carries its own case. The preserved local probe under `notes/verification/handoff/round2-self-attack/` went from 8 erroneous authorizations in 20 cases to 0. Six files rather than the preamble's five: a class-wide repair touches every consumer of the class, and the sixth is the contract template that now states the authority-versus-obligation rule the sweep follows.
  - *Evidence:* CAP-133-Ev1OW5 verified by spec-gate accept; return sha256:c2b28bf63ac6d0a3eeaa9be47c5533eab419b5006251631e6380fad732cf6263

- [x] **T030o13** [hard] — Suppress HTML-commented content in every authority parser
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`, `tests/test-gate-contracts.sh`, `tests/test-verification.sh`, `tests/test-sdd-analyze.sh`, `templates/verification-contract.md`
  - *Acceptance:* The shared quoted-content tracker gains HTML-comment state, so a waiver, spec-revision, `## Round` heading, reality-check matrix row, task stage, task block or plan definition row inside `<!-- ... -->` authorizes and defines nothing, on both gates and both authorization forms. Tokens inside inline code spans neither open nor close a comment, so the canonical reports still validate and round 1 keeps digest 1ac95178; the anchored `<!-- gate-round-end: gate:n -->` marker stays readable; an unclosed comment keeps suppressing; and a mid-line opener suppresses the following lines. A real record after a closed comment is still parsed.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`, `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-verification.sh::test_config_grammar`, `tests/test-sdd-analyze.sh::test_verification_bindings`
  - *Verify:* `bash tests/test-spec-gate.sh && bash tests/test-gate-contracts.sh && bash tests/test-verification.sh && bash tests/test-sdd-analyze.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-008, REQ-012, REQ-013, AC-003, AC-009, AC-010, AC-011, AC-013, FM-001, FM-011, FM-016, FM-020, plan §3.1, §3.3, §4.3
  - *Notes:* Owns opponent finding O-002, reopened a third time. T030o12 derived its enforced set from the spellings the round-1 report named; an HTML comment is the quoting form this kit itself uses for machine-read markers and was left live in all seven authority parsers. The suppression is code-span aware because a naive scan would enter comment state at the round-2 report's own O-002 text and wedge every later gate invocation. `<details>`/raw-HTML stays live by decision, recorded in STATUS: its content is rendered, so it is a visible record rather than a hidden instruction.
  - *Evidence:* CAP-157-uvthVs verified by spec-gate accept; return sha256:2e53a2eb88e7ef62ff0bea515c95937047fbc9fd1fea0c8b8d1ca5134a81ecad

- [x] **T030o14** [hard] — Require a resolved finding to name a real prior finding
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* `Status: resolved` is accepted only when the finding ID appeared in an earlier round of that gate, or `Prior` names an ID that did, or `Prior` names an ID recorded in a declared prior-review manifest under `notes/verification/reports/`. A brand-new blocking finding neutralized with a fabricated `Prior` is refused with a named diagnostic instead of tallying zero blockers, on both gates. Round 1's `O-006`, whose `Prior` refers to the uncounted 2026-09-09 provisional review, still validates from that manifest, and both sealed rounds still parse.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-011, REQ-012, AC-012, FM-019, INV-006, plan §3.3, §4.3
  - *Notes:* Owns opponent finding O-004, reopened a third time. T030o9's rule tested the shape of `Prior`, not its existence, so one fabricated token bought a zero-blocker clearance, and the repository's own fixture asserted that shape as legitimate. Takes the report's manifest alternative rather than its `prior == fid` escape hatch, which any new finding could satisfy by naming itself.
  - *Evidence:* CAP-153-FAla8S verified by spec-gate accept; return sha256:94959f0ebdf0e8f940b82a7ea7fe8df97acfc38e6c7a167713e507752d7c24b6

- [x] **T030o15** — Reject process substitution in verification configuration
  - *Files:* `scripts/verification-lib.sh`, `tests/test-verification.sh`, `templates/verification-contract.md`
  - *Acceptance:* Configuration scalars reject unescaped `<(` and `>(` in every list — gate_checks, reuse_checks, checkpoints, verification_tools and verification_inputs — with the same named diagnostic the other substitution spellings use, while a plain redirection such as `bash tests/run.sh > out.log` and the existing literal-dollar and brace positives still parse byte-for-byte. The source comment and the contract state the set that is actually enforced instead of claiming completeness.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_config_grammar`
  - *Verify:* `bash tests/test-verification.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-007, REQ-008, REQ-009, AC-011, FM-011, plan §3.1
  - *Notes:* Owns opponent finding O-005, reopened a third time. Process substitution is the third Bash spelling that runs a command and splices its result, and is as invocation- and clock-dependent as the two already rejected, so a check declared that way was reusable under an identity that does not record what ran.
  - *Evidence:* CAP-154-iPa3xR verified by spec-gate accept; return sha256:ca3262d0a8339d6bc9ad10b117288d571ddf8e1bebbfd6d137adfc4c1b3ed82e

- [x] **T030o16** — Refuse every shape of content after a completed round marker
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* A `**Blocking:**` totals line or a legacy `# Opponent review` heading placed after a round completion marker is refused by the report validator with its file:line diagnostic, like every other non-blank line there, instead of reaching the later sealed-digest guard. The clean report still completes and both sealed digests are unchanged.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, FM-016, plan §3.3, §4.3
  - *Notes:* Owns opponent finding O-008. Minor and non-blocking because T030o11's second guard already refuses the completion; the defect is that T030o11's stated acceptance was not met and the operator gets the wrong diagnostic.
  - *Evidence:* CAP-155-8dBolN verified by spec-gate accept; return sha256:2c59e7689b5e8db5dfc5aa23984b3abe7709c23305a72f68d0a33f4073ca999b

- [x] **T030o17** — Anchor the Decisions section on its exact heading
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Both the round-authorization scanner and the input manifest recognize only the template's exact `## Decisions log` heading, so a second heading such as `## Decisions we rejected` authorizes nothing and is not hashed as the decisions log; the two views stay in step and this spec's own STATUS still authorizes and hashes exactly as before.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, REQ-012, AC-009, FM-016, plan §3.3, §4.3
  - *Notes:* Owns opponent finding O-009. Minor and non-blocking because the shipped status template declares exactly one Decisions heading, so no existing artifact is affected; the manifest parser is changed in the same commit so the two views cannot disagree about what the log is.
  - *Evidence:* CAP-156-UYhU8o verified by spec-gate accept; return sha256:3376cbeb2498eb084b173c7dee41b7b1936003d6ee0228e1a61b80e077df3086

- [x] **T030o22** — Locate the prior-review manifest from the spec, not the report path
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* `vf_reports` resolves `<gate>-findings-*.md` from the spec directory supplied by its callers, so `round --complete` and `--reconcile` — which validate a temporary `combined.md` under `notes/verification/round-check.XXXX/` — see the same manifest the canonical path sees. A completed round whose only resolved finding is legitimised by the manifest seals instead of being refused, and the existing canonical/tally behaviour is unchanged.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/test-gate-contracts.sh && bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-012, AC-009, AC-012, FM-016, plan §3.3, §4.3
  - *Notes:* Found by round 3 refusing to complete. Repaired before anything else because neither `--complete` nor `--reconcile` could run until it was. Self-trapping in the worst way: repairing it changes the source identity, so the round it refused can no longer be completed as CHALLENGED, which is why round 3 is reconciled as BLOCKED with its report preserved.
  - *Evidence:* CAP-175-XuyzhE verified by spec-gate accept; return sha256:2de6a59a25f023a855314eb2ec472bf5a6776f369745143e1e766fdc2b7ad4c0

- [x] **T030o18** [hard] — Derive comment extent from the markdown, not a token scan
  - *Files:* `scripts/verification-lib.sh`, `scripts/sdd-analyze.sh`, `tests/test-spec-gate.sh`, `tests/test-gate-contracts.sh`, `tests/test-sdd-analyze.sh`, `templates/verification-contract.md`
  - *Acceptance:* `vf_comment` gains the `ind > 4` content guard `vf_fence` already has, so an indented comment opener is an indented code block — visible to every reader — and cannot swallow a finding, a task block or a definition row. The closer side stops disagreeing with what a renderer sees, an unclosed comment gets an END diagnostic beside the unclosed-fence one instead of failing silently, and the three raw tasks.md passes in `sdd-analyze.sh` use the shared tracker so a quoted example task cannot supply `Refs:` to AC coverage. A genuinely commented finding is still uncounted.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`, `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-sdd-analyze.sh::test_verification_bindings`
  - *Verify:* `bash tests/test-spec-gate.sh && bash tests/test-gate-contracts.sh && bash tests/test-sdd-analyze.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-004, REQ-010, REQ-011, REQ-015, AC-003, AC-009, AC-012, FM-001, FM-016, FM-019, INV-005, plan §3.1, §3.3, §4.3
  - *Notes:* Owns O-002, reopened a fourth time. The divergence flipped direction this round: the enforced set was still a spelling list, and an indented opener is content to a reader but a marker to the parser, so a data-loss finding tallied zero blockers. `<!DOCTYPE`/`<?`/`<![CDATA[` are recorded as extent for the same derivation rather than chased as separate spellings.
  - *Evidence:* CAP-176-Akofnw verified by spec-gate accept; return sha256:3db6e1087ed48f35b650072a340fc3fe04fd0fc7c3e59cb218e8e7827765c25e

- [x] **T030o19** [hard] — Bind a resolved claim to the finding it resolves
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`, `templates/verification-contract.md`
  - *Acceptance:* `Status: resolved` is accepted only when the finding's own ID appeared in an earlier round of that gate, or `Prior` names an ID whose recorded `Class` matches this finding's class — manifest entries carry a class for that purpose. A brand-new data-loss finding neutralised with a real but unrelated `Prior` is refused and counted, on both gates, and the fixture that certified that shape becomes a negative beside a real same-ID cross-round positive. Both sealed rounds still parse.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-011, REQ-012, REQ-015, AC-012, FM-019, INV-006, plan §3.3, §4.3
  - *Notes:* Owns O-004, reopened a fourth time, root cause plan-gap. T030o14's acceptance criterion was the wrong rule implemented faithfully: it proved that some prior finding exists, never that the claim was about that finding, and the fixture I wrote asserted the attack as correct. The cost of the attack had dropped from inventing a token to copying one printed in the same file.
  - *Evidence:* CAP-177-koEjAU verified by spec-gate accept; return sha256:4e92c6b7901ea89de8221cb3344fd20cb66a793a85be349f183c189be39534db

- [x] **T030o20** [hard] — Hash a declared environment set and decide idempotence by receipt
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `.specify/stack.yml`, `tests/test-verification.sh`, `tests/test-spec-gate.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* `vf_snapshot` hashes only a declared closed set — as first implemented by this task, the project `verification_environment:` declaration plus a fixed name list, SUPERSEDED by T030o25 under which membership is exactly the declaration and nothing beside it — so a byte-identical worktree yields the same source identity from a different process, and an undeclared variable such as the harness's own effort setting no longer invalidates a floor, a capture or the AC-016 probe. Independently, the already-accepted receipt check runs before currency validation, so re-accepting an accepted return is idempotent across a changed environment and writes no rejection audit event.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`, `tests/test-spec-gate.sh::test_acceptance`, `tests/test-gate-contracts.sh::test_invoker_protocol`
  - *Verify:* `bash tests/test-verification.sh && bash tests/test-spec-gate.sh && bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-009, REQ-012, AC-016, AC-020, AC-022, FM-010, FM-014, INV-001, INV-002, plan §3.2, §4.2
  - *Notes:* Owns O-010, new, root cause plan-gap. Resolved in favour of the implementation rather than a spec revision: AC-016 requires the live observation to be checked at reality-check, which is a separate invocation by design, so an identity no second process can reproduce is a session fingerprint rather than an input identity. Exactly one record of 2116 differed when the reviewer measured it.
  - *Evidence:* CAP-178-mpDcyA verified by spec-gate accept; return sha256:95e29e2151082c74bedbffca731af2829804c4c25fd845a07a6c2db3fe1f1b4d

- [x] **T030o21** — Refuse quoted content after a completed round marker
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* A fenced, HTML-commented or blockquoted preamble placed after a round completion marker is refused by the report validator with its file:line diagnostic, like plain prose, instead of reaching the later sealed-digest guard. The clean report still completes and both sealed digests are unchanged.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, FM-016, plan §3.3, §4.3
  - *Notes:* Owns O-008, reopened. T030o16 again covered exactly the two shapes the previous report listed; `vf_quoted` consumes the line before the after-marker guard runs. `vf_report_block` accumulation stays unchanged so sealed digests cannot move.
  - *Evidence:* CAP-179-2OoHpK verified by spec-gate accept; return sha256:2473b87bf7df3b09369058c91a014732c176213daeca4eabb33b9744e590dee1

- [x] **T030o23** [hard] — Derive suppressed extent from the markdown block grammar
  - *Files:* `scripts/verification-lib.sh`, `scripts/sdd-analyze.sh`, `tests/test-spec-gate.sh`, `tests/test-gate-contracts.sh`, `tests/test-sdd-analyze.sh`, `templates/verification-contract.md`
  - *Acceptance:* The suppressed set is DERIVED from the CommonMark HTML-block conditions (CommonMark 0.31.2 §4.6) and the contract cites that derivation instead of listing spellings. Conditions 1 (`<script`/`<style`/`<textarea`/`<pre`, ending on the matching close tag), 3 (`<?` … `?>`), 4 (`<!` + ASCII letter … `>`) and 5 (`<![CDATA[` … `]]>`) suppress beside the existing condition 2, fences, blockquotes and indented code; conditions 6 and 7 — block-level and complete-tag HTML, `<details>` included — do not, because their content renders visibly. An opener inside a matched inline code span stays literal, as for comments. All `vf_quoted` call sites and the three raw tasks.md passes in `sdd-analyze.sh` inherit the one site: a condition-1-wrapped waiver authorizes nothing, a condition-1-wrapped task block supplies no AC coverage and claims no FM/INV ownership, and a `<details>`-wrapped record still counts. Closing this closes the recorded `<!DOCTYPE`/`<?`/`<![CDATA[` residual.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`, `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-sdd-analyze.sh::test_verification_bindings`
  - *Verify:* `bash tests/test-spec-gate.sh && bash tests/test-gate-contracts.sh && bash tests/test-sdd-analyze.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-004, REQ-010, REQ-011, REQ-015, AC-003, AC-009, AC-012, FM-001, FM-016, FM-019, INV-005, plan §3.1, §3.3, §4.3
  - *Notes:* Owns O-002, reopened a FOURTH time. Every prior repair encoded the previous report's named spellings, so the next unnamed member survived: fences, then comments, then indented openers, now condition-1 raw HTML. The criterion above is deliberately written as a derivation with its source cited, because an enumerated criterion is satisfiable while the class stays open. `<pre>` and `<textarea>` suppress for the quoted-record reason a fence does, `<script>` and `<style>` because no reader sees their content; both directions agree.
  - *Evidence:* CAP-202-EJzhKK verified by spec-gate accept; return sha256:522322e6cf92e280328ce3c5ab930d1fc07f61513163f38861d9e450a0d1ec64

- [x] **T030o24** [hard] — Bind a resolved claim to its own identity, not a label
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`, `templates/verification-contract.md`
  - *Acceptance:* `Status: resolved` is accepted only when the finding's OWN ID appeared in an earlier round of that gate, or when that same ID appears in a declared prior-review manifest. The different-ID `Prior` branch is removed outright: round 1's real `O-006` passes without it, proven by re-parsing the unchanged canonical `notes/opponent.md`. A brand-new data-loss finding carrying a real ID and a copied `Class` is refused on both gates and still counted by tally. The two shipped fixtures that asserted that shape completes at rc=0 become negatives asserting the refusal, beside a same-ID cross-round positive and a same-ID manifest positive.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-011, REQ-012, REQ-015, AC-012, FM-019, INV-006, plan §3.3, §4.3
  - *Notes:* Owns O-004, reopened a FOURTH time, root cause plan-gap for the second round running. T030o19's rule was implemented faithfully and was itself the defect: `Class` is a field the finding's author chooses, so requiring it to match raised the attack cost from copying one token printed in the file to copying two. The different-ID path served no real record in this repository — it existed only for the attack.
  - *Evidence:* CAP-203-KfCQSW verified by spec-gate accept; return sha256:36961b8fee184ba84598e8c26b609412de3416cb303b28efb20ba844f553417b

- [x] **T030o25** [hard] — Take the environment set's membership from the declaration
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-verification.sh`, `tests/test-spec-gate.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* `vf_snapshot` takes the environment record MEMBERSHIP from the declaration and nothing else: the set is EXACTLY `verification_environment:`, with no fixed name list beside it. Any variable the project has not declared — `LC_CTYPE` and `LC_ALL` included, the two that macOS Terminal, OpenSSH SendEnv and most CI images export by default — leaves the source identity byte-identical, so a sealed capture still returns `current` rc=0 from a different shell. A DECLARED variable still moves identity by presence and by value, with only the value hash reaching the manifest. `PATH`, `SHELL`, `LANG` and `TMPDIR` are dropped with the reason recorded against the existing `tool`/`harness` records. A fixture re-validates a sealed capture from a subshell exporting an `LC_` name and a reordered `PATH`.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`, `tests/test-spec-gate.sh::test_acceptance`, `tests/test-gate-contracts.sh::test_invoker_protocol`
  - *Verify:* `bash tests/test-verification.sh && bash tests/test-spec-gate.sh && bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-009, REQ-012, AC-016, AC-020, AC-022, FM-010, FM-014, INV-001, INV-002, plan §3.2, §4.2
  - *Notes:* Owns O-010, reopened. T030o20 closed the set for every name except the one family it took from `compgen -e`, so the membership itself still came from the environment. AC-016 requires the live observation to be checked at reality-check — a separate invocation by design — so an identity a second shell cannot re-derive is a session fingerprint, not an input identity. ACCEPTANCE CORRECTED DURING IMPLEMENTATION: this task was first written as `the LC_* family is a closed literal list recorded present/unset`, which was drafted from the reviewer first suggested option and does NOT close the class — a fixed list records `LC_CTYPE` present in one shell and unset in another, so the digest still moves between two processes reading a byte-identical tree. Caught by probing the rule before trusting it, which is the habit round 3 and round 4 both said was missing.
  - *Evidence:* CAP-204-j1KEKV verified by spec-gate accept; return sha256:84652e833adf1b6148100f3ae43b83df3dd6909fb514f0249b76c3fdc79439e6

- [x] **T030o29** [hard] — Bind every token the count reads, not only the one a round named
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* Extent is DERIVED from what the tally and the verdict check actually read — `vf_reports`' blocking/minor increment and the CLEARED/CHALLENGED agreement check — not from the field round 6 happened to name. For every finding ID the gate has seen, in canonical rounds and in declared prior-review manifests, the first recorded severity TIER (data-loss/wrong-result/regression/crash versus minor/degraded) is history-bound, and a CLEARING verdict is refused when it rests on a non-resolved observation below that tier. A non-clearing round may still re-characterise, and `vf_tally` reports `severity-downgrades` so no downgrade is silent. Executable negatives cover the CLEARED attack; controls cover honest re-characterisation inside a CHALLENGED round, a genuine same-tier resolution, and an upgrade.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-011, REQ-012, REQ-015, AC-012, FM-019, INV-006, plan §3.3, §4.3
  - *Notes:* Owns O-004, reopened a fifth time, root cause plan-gap. Round 5 bound `Class`, which the tally never reads; `Severity` is the sole input to the blocking count, so the same outcome was reachable through the sibling field in the same statement. The report's own proposed fix was itself the wrong rule and would have rejected the round-6 report that proposed it — O-002 is recorded there at degraded after five rounds at wrong-result — so the rule binds where the attack lands instead of where the reviewer pointed. Deliberately NOT closed here: a round can still reach CLEARED by omitting a known open finding entirely, which is pre-existing model behaviour rather than this class, and the reality-check gate enforces no totals at all, so its clearing verdict has no equivalent guard.
  - *Evidence:* CAP-272-I4rOZq verified by spec-gate accept; return sha256:dfb1a6a54944b2b46d2206a4eae26fad0de89f19faf3828391a5a46f96036388

- [x] **T030o30** [hard] — Bind a superseded-rule guard to the phrase, not to one file handle
  - *Files:* `tests/test-gate-contracts.sh`, `tests/test-verification.sh`, `.specify/specs/003-gate-round-reduction-and-token-discipline/tasks.md`
  - *Acceptance:* The absent-phrase guard binds to the PHRASE across every artifact whose content the input manifest hashes as current source — the complement of `vf_bookkeeping_path` — minus `STATUS.md`, whose Decisions log is an append-only record of what was true when each entry was written. The two file-scoped `assert_not_contains "$contract"` guards are replaced rather than kept, and the scanner assembles its needle from fragments so it matches neither its own source nor needs a self-exemption. T030o20's stale acceptance line is repaired as a RECORD repair that names T030o25 as superseding it, without restating the superseded membership as current.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-012, AC-018, FM-019, INV-006, plan §3.2, §4.2
  - *Notes:* Owns O-010, reopened a third time, root cause plan-gap. Round 5 corrected one line and bound the regression guard to that one file handle, so the class closed at exactly one member while `tasks.md` still asserted the fixed list as current membership — and a stale ACCEPTED criterion is worse than stale prose, because this spec's standing rule is that the record outranks warm proof. Correction to the round-6 report, recorded rather than quietly dropped: its `Where` list names `notes/verification/dossier/README.md:66` as a second survivor, but that sentence continues "are no longer hashed" and states the CORRECT rule — the quoted fragment breaks across a line. One genuine survivor, not two.
  - *Evidence:* CAP-273-7RW12J verified by spec-gate accept; return sha256:56d3b79dbed0a9bd3b3d3aab7ad022e290d3ae0566a65ab6179858aab9ec07f5

- [x] **T030o31** — Name the line and the clause of every refused authorization
  - *Files:* `scripts/verification-lib.sh`, `scripts/spec-gate.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Every candidate authorization `vf_round_authorized` discards is reported with its `STATUS.md` line number and the specific clause that failed — field count with the reason a `"; "` inside `reason=` splits the entry, wrong round, wrong predecessor, malformed `by=`/`reason=`/`revision=`, unordered or future timestamp — and a log containing no candidate for the gate says so instead of listing none. Candidate detection is deliberately wider than the grammar, so an entry that fails before its gate field can be read is still named. `spec-gate.sh waiver <spec-dir> <gate> <round>` validates an authorization when it is written, reserves nothing and changes no state, and reports an already-completed round as completed rather than denied.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, FM-016, INV-004, plan §3.3, §4.3
  - *Notes:* Owns O-002, reopened a sixth time, root cause implementation-error, severity degraded. Fail-closed is the safe direction and the round cap held, so no gate decision was wrong; what was wrong is that the refusal named nothing, leaving the operator unable to distinguish a malformed waiver from no waiver at all. The recorded cost on this spec was a handoff asserting round 6 was already authorized when its waiver split into six fields, and one cold floor re-execution. The reviewer searched for an accept-side dual and found none; this task does not assume one exists.
  - *Evidence:* CAP-274-BdOYW1 verified by spec-gate accept; return sha256:a852b9489953f88056c720c5c184a0eeea91420a917766de6133c4dcdd316710

- [x] **T030o32** — Refuse a duplicate per-round singleton
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* Any field the round validator reduces to one value refuses a second occurrence instead of letting the last write win. The totals line carries the same `seenfield` guard its sibling identity fields already had, so a second `**Blocking:**` line inside one round is refused with a named diagnostic rather than silently replacing the totals the reader sees above the findings. The audit backing the extent is recorded: identity fields and finding fields already carried duplicate guards, and the totals line was the only per-round singleton without one.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, AC-012, FM-019, INV-006, plan §3.3, §4.3
  - *Notes:* Owns O-011, new, root cause implementation-error, severity degraded. It cannot by itself move a gate decision, because the surviving totals must still equal the real counts and the verdict check reads the real counts — but the machine-checked record and the reader-visible record could disagree inside one sealed round, which is the record-integrity property this spec exists to protect.
  - *Evidence:* CAP-275-mDGzk7 verified by spec-gate accept; return sha256:c7ebbd2c3c3e0d341dd62c97b2de4571361af164ff773ac4d0ff2652c60aa818

- [x] **T030o33** [hard] — Consume every round field from the catalog that validated it
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Extent is DERIVED from the round-record production `vf_reports` enforces, not from the field one report named. That production is the identity rule at `scripts/verification-lib.sh:1083-1094` — `value()` at :968 strips `[ ]*` and trims, `seenfield` at :1086 refuses a duplicate field, `vf_quoted` at :1066 makes it blind to quoted content — emitting `round,n,utc,source,floor,verdict,style,date` at :1063. The rule enforced: EVERY field of that record is consumed by downstream readers from the emitted catalog, and no second parser re-derives one. The sweep is the call graph of report-text readers that run after `vf_reports`, which is exactly `vf_reality_matrix` (verdict) and `vf_report_block`, whose divergence is DELIBERATE because the sealed digest must cover quoted lines and which is therefore a digest input and never a field source. `vf_reality_matrix` takes the verdict as a parameter from `vf_gate_round`, fails closed on any value the catalog could not have produced, and the second parse is deleted. Negatives are per divergence class rather than per spelling — whitespace the identity production tolerates, quoted content it skips, a verdict the catalog refuses — each asserting end to end through `spec-gate.sh round --complete` that a round carrying a `FAIL`/`MISSING` row is refused whatever the text spells, with the one-space READY positive over all-PASS rows retained.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/test-gate-contracts.sh && bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-013, AC-013, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns O-012, new, root cause implementation-error. Numbered first rather than the report own T030o34, because it is a PREREQUISITE for T031 and not merely a finding: `vf_reality_matrix:2520` is the only semantic guard on the reality-check side, that gate has run zero rounds, and the divergence disarms it with a typing slip no reviewer of rendered Markdown can see. Reproduced before repair: with `**Verdict:**  READY` (two spaces) `vf_reports` emits catalog verdict READY at rc=0 while the matrix returned 0 over a `MISSING` row; `**Verdict:**READY` and a fenced duplicate verdict behaved identically. The direct-call cases isolate the parameter in BOTH directions (text NEEDS WORK with catalog READY must refuse; text READY with catalog NEEDS WORK must permit), because a one-directional case still passes under a parser that reads the text. Deliberately NOT changed: `vf_report_block` accumulation, for the 2026-09-10 reason that altering it would move already sealed round digests.
  - *Evidence:* CAP-313-P3hRbH verified by spec-gate accept; return sha256:acd6dccaa1286560b8b0d7cb59fd0ef9d41f024fa52f2aba797604038ff7ff8b

- [x] **T030o34** [hard] — Stop an uncorroborable resolution from buying a clearing verdict
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* Extent is DERIVED from the predicate the parser evaluates, not from the field a report named. The blocking count at `scripts/verification-lib.sh:1013` is one predicate over exactly two author-written tokens, `Status` and `Severity`, and the clearance check reads that count. `Severity` is bindable to history because the gate has seen the ID before; `Status: resolved` is NOT — it asserts a repair that no data available to `vf_reports` can corroborate — so the suppression may not be worth a CLEARING verdict. "Rests on" is read off the same predicate: an observation rests on the suppression exactly when this gate own ROUND record already counted that ID, which is history the report making the claim cannot rewrite. A declared prior-review manifest is not a round and was never counted, so a first round may still resolve a manifest-recorded finding and clear. The rule is gate-neutral by derivation — `CLEARED` for opponent, `READY` for reality-check — and the refusal names the findings. The two shipped POSITIVES that certified the attack at rc=0, `tests/test-gate-contracts.sh:286-289` and `:456-458`, become negatives; the same-ID manifest positive modelled on the real round-1 O-006 is kept, on both the tally and the `--complete`/`--reconcile` paths.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-011, REQ-015, AC-012, FM-019, INV-006, plan §3.3, §4.3
  - *Notes:* Owns O-004, reopened a SIXTH time, root cause plan-gap. THE PREFERRED RULE WAS MEASURED AND REJECTED BEFORE IMPLEMENTING IT, which is the point of this batch: counting every recorded finding at its recorded tier — the option the round-7 report prefers — computes `blocking=6` for round 1 against its declared 5, `6/3` for round 2 against `3/2` and `7/3` for round 3 against `3/1`, so it rejects three sealed rounds whose digests cannot be edited without wedging every later reserve, complete and reconcile. Measured against the real recorded history in `notes/opponent.md` before any code was written. The enforced rule is therefore the report own stated minimum, and it accepts every sealed round of this gate (all seven are non-clearing) and both shipped specs (001 round 3 and 002 round 5 cleared with no findings at all). CONSEQUENCE ACCEPTED AND RECORDED: the round that announces a repair is not the round that clears — a gate clears in a round that has nothing left to list, which is the shape both shipped gates actually have. EXTENT NOT CLOSED, argued rather than skipped: a round can still reach CLEARED by omitting a known open finding entirely, which needs cross-round open-state tracking and is a spec-level change; `vf_tally:1178` carries the same `status != resolved` suppression but feeds a printf and decides nothing, so it is a metric and not this class; and the sibling totals/downgrade checks at :1079-1081 stay opponent-only because they read the opponent-only totals line, which is the recorded reality-check totals gap and belongs to T031.
  - *Evidence:* CAP-314-0FfJM3 verified by spec-gate accept; return sha256:681479bc9fba6e7c33d19d1ad1209d709b0f466201d43cd3ae7f5b5e7ab4c6fa

- [x] **T030o35** — Give every clause of the authorization grammar a diagnostic, and the checker a reader
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`, `tests/test-gate-contracts.sh`, `README.md`, `skills/sdd-implement/SKILL.md`, `skills/sdd-go/SKILL.md`, `skills/sdd-review/SKILL.md`, `agents/sdd-orchestrator.md`
  - *Acceptance:* Extent is DERIVED from the production the parser enforces — `- <UTC> — <kind>: gate=<g>; round=<n>; after=<n-1>; by=<b>; reason=<r>[; revision=<v>]` — in which every clause has exactly one refusal path and NO refusal path may be silent, so a clause added later inherits the obligation instead of needing to be listed. The gate clause is the one case needing a distinction rather than a note added blindly, and the grammar supplies it: `gate=<g>` ranges over the gates that exist, so a value naming another KNOWN gate is that gate record and is correctly skipped in silence, while any other value is a malformed candidate for the gate being asked about and must be named with its line. The gate set is read from one library constant rather than restated. Candidate detection also covers a `<kind>:` written without its trailing space, while prose naming the tokens in code spans stays a non-candidate so the refusal list remains readable. The authoring half is closed where it is open — by DOCUMENTATION: `spec-gate.sh waiver` is named in README operator command list and in the round-cap paragraph the four invoker documents share, and the guard that keeps it there DERIVES the subcommand set from the dispatcher in `scripts/spec-gate.sh` instead of enumerating verbs.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`, `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-spec-gate.sh && bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, AC-018, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns O-002, reopened a SEVENTH time, root cause implementation-error, severity degraded. No gate decision is wrong and the round cap holds; what is wrong is that `:2303` asserted the OPPOSITE of the truth, telling the operator that no candidate authorization exists while one sat a character away from valid and four unrelated historical lines were listed. Reproduced through the shipped entrypoint, not only the library, because `spec-gate.sh waiver` exists precisely so the operator meets the diagnostic when they write the entry. The documentation half was inert for a reason the previous guard could not see: `public_workflow_cases` enumerated five verbs, so `waiver` shipped with its own `--help` line and no mention in any document an operator reads. EXTENT NOT CLOSED: the round-3 residual `<!DOCTYPE`/`<?`/`<![CDATA[` suppressed extent is implemented and covered elsewhere and is unrelated to the diagnostic; and asking about round 4+ before round 3 exists still reports the date-only reconciliation message, which is a nonsensical question rather than this class.
  - *Evidence:* CAP-315-zAjbad verified by spec-gate accept; return sha256:d5b00da30d862d4f70465a4876c0ed39ff76d025ebedaea6e6c9ee5197b1dcbb

- [x] **T030o36** — Bind a superseded-rule guard to the proposition and to the manifest own file set
  - *Files:* `tests/test-gate-contracts.sh`
  - *Acceptance:* Both halves are DERIVED rather than restated. SCOPE comes from the enumeration the input manifest itself uses — `git ls-files --cached --others --exclude-standard` filtered through `vf_bookkeeping_path` (`scripts/verification-lib.sh:1320`, the same predicate `vf_snapshot` applies at :1376 and :1383), minus `STATUS.md`, whose Decisions log records what was true when each entry was written — so the guard set is the manifest set by construction and cannot drift when a new extension appears or a directory is named `captures` outside the anchored bookkeeping path. The NEEDLE matches the proposition, not one rendering of it: each candidate is normalized to a whitespace-collapsed stream with backticks and asterisks stripped, and a claim is a MEMBERSHIP predicate GOVERNING any of the names, in any order and any subset, in either direction, with no negation in the connective — the same names under the opposite claim state the current rule and must not be flagged. The live tree is asserted clean and the SAME expression is run against a constructed tree carrying every shape this class has escaped through, so the guard is not proven only on the tree it already passes.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-012, AC-018, FM-019, INV-006, plan §3.2, §4.2
  - *Notes:* Owns O-010, reopened a FOURTH time, root cause plan-gap, severity degraded. Round 6 bound the guard to one file handle and round 7 defeated the replacement literal with the shapes this repository own conventions produce. TESTING THE RULE BEFORE TRUSTING IT FOUND TWO DEFECTS IN THE PROPOSED NORMALIZATION. First: stripping underscores, which the round-7 report names, DELETES THE NEEDLE — `LC_` is one of the names searched for, and an `LC_*`-only claim escaped a normalizer that stripped it; measured, then underscores kept. Second: a bare participle is not a membership claim — this repository writes "`LC_CTYPE` and `LC_ALL` included" meaning "among them", which a normalizing matcher read as a claim, so the reverse direction requires a passive verb phrase. A third was found by mutation: the negation window began AT the predicate, so "no longer includes PATH" — how English negates this proposition in the forward shape — read as the superseded claim. Correction to the round-7 `Where` list, recorded rather than dropped: it names `tests/test-gate-contracts.sh:56-62`, which is the guard and not a surviving claim; the live tree carried no survivor at round 7 and carries none now.
  - *Evidence:* CAP-316-I1tieA verified by spec-gate accept; return sha256:c227afeec54ff1d061f3a2e5d0bb5c967164e6f9a7ba5fda126b688606467cf6

- [x] **T030o37** [hard] — Preserve the strictest observed severity tier and isolate whitespace normalization
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* Derive the comparison state from every writer consumed by `vf_reports` finding()/flush(): Severity has two tiers (`minor|degraded` versus all four blocking severities), and the history fold must retain the strictest tier for each finding ID across manifest and round observations regardless of order. A non-resolved lower-tier observation may not buy opponent CLEARED; non-clearing re-characterisation remains valid. Apply the same sticky fold to `vf_tally` canonical round observations, keyed by gate and ID. Extend the existing escalation positive through a third-round downgrade, assert the exact refusal and metric, and vary tier order, lifecycle status, and repeated downgrades. Re-measure against real 001/002/003 history before implementation. D1: derive fixtures from `superseded_environment_scan` whitespace production `[[:space:]]+`; internal whitespace in a passive predicate must collapse while a whitespace-separated negation must remain effective. Mutation-isolate permissive and over-strict variants; restore byte-identically with cmp.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-010, REQ-011, REQ-015, AC-012, AC-017, AC-018, FM-019, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-8 O-004 and the D1 fixture gap. History precheck on an isolated candidate library: 002 and 003 return 0 with byte-identical catalogs; 001 retains identical pre-existing duplicate-identity diagnostics at exit 3. No gate round is part of this task.
  - *Evidence:* CAP-366-H7QjI6 verified by spec-gate accept; return sha256:329c68620c2b2418aca93e4f25f3a3eef2546fbcb55dd0bd52f6c897cec6104a

- [x] **T030o38** — Fail closed when the dispatcher cannot be fully classified for documentation
  - *Files:* `tests/test-gate-contracts.sh`
  - *Acceptance:* Derive coverage from Bash's `case WORD in [PATTERN [| PATTERN]...) COMMANDS ;;]... esac` production (`help case`) and the command_name dispatcher in `scripts/spec-gate.sh`. Every clause must either yield all literal alternatives, be the final catch-all, or fail with an unclassifiable-dispatcher diagnostic; no line may silently vanish. Optional opening parentheses, whitespace indentation and digits in literal verbs preserve classification. Unsupported patterns, quoting, multiline/nested clauses or terminators fail closed rather than claiming a complete set. Every classified verb must appear in the help synopsis, help detail and README. Mutate each syntactic dimension and verify all three missing-documentation diagnostics; retain equivalent documented-dispatcher controls and unknown-clause refusal controls. Check the current dispatcher before implementation and retain the real report history unchanged.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-015, REQ-016, AC-018, FM-019, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-8 O-002 documentation discovery only. This is a fail-closed static subset, not a general Bash parser. No authorization, floor or gate round is part of this task.
  - *Evidence:* CAP-366-H7QjI6 verified by spec-gate accept; return sha256:fe2790a493c4a398808da47ecc0cd432ac33a51f766171121b8d6c29936b566a

- [x] **T030o39** [hard] — Anchor generated bookkeeping to the verified spec and refuse bookkeeping declared as an input
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-verification.sh`, `tests/test-gate-contracts.sh`, `.specify/specs/003-gate-round-reduction-and-token-discipline/plan.md`
  - *Acceptance:* Derive the excluded set from the 2026-09-23 Decisions reading of REQ-009: generated bookkeeping is the six path shapes (`.tasks.accept.*`, `notes/captures/`, `notes/verification/`, `notes/evidence.md`, `notes/opponent.md`, `notes/reality-check.md`) of the VERIFIED spec only, anchored to its repo-relative directory when that is `.specify/specs/<name>` inside the snapshotted repository, and otherwise empty so nothing is excluded. Every consumer takes the anchor from the spec whose capture or floor it computes: the index pass, the path pass and the declared-input pass of `vf_snapshot`, and `vf_path_record`. A `verification_inputs:` path inside that bookkeeping, exactly or as a declared directory wholly within it, is refused by name at exit 3 and never skipped silently; a declared directory's members that are the verified spec's own bookkeeping are skipped by the enumeration's rule. Location is physical: links and `..` resolve through the filesystem (`cd -P`); the anchor is string work on physical paths with no git discovery, so an exported `GIT_DIR` cannot move it; letter case folds exactly where the filesystem holding the spec folds, probed there rather than read from `core.ignorecase`; and a declared repository root is refused by name too. The O-010 scan applies the same predicate with each path anchored to the spec that contains it. Negatives in both directions, through a real capture: editing or adding another spec's gate report, findings manifest, capture or floor record changes the identity and makes `reuse` refuse with `capture stale: current inputs changed`, while the same edit to the verified spec's own records does not. Plan §3.2 step 3 and `templates/verification-contract.md` state the anchored rule and the refusal.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`, `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-verification.sh && bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-018, AC-020, FM-010, FM-014, FM-019, INV-001, INV-006, plan §3.2, §4.2
  - *Notes:* Owns round-9 O-013. The anchoring reading is the user's 2026-09-23 Decisions entry, not a spec revision. The reviewer's proposed scan scope was measured and replaced by per-path anchoring (Decisions, 2026-09-23). No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-411-B8GLAC verified by spec-gate accept; return sha256:27f3ea2c2ddc11eabf6286bf04b351107a98eada3a37e288fad06a42dfae6535

- [x] **T030o40** — Make the severity-downgrade metric the guard's own computation and kill the two unisolated guards
  - *Files:* `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* Derive the metric from the guard it measures (REQ-011, MET-002). `vf_reports` evaluates the lowered-tier predicate once per finding observation against the history its manifest and round writers share; `flush()` refuses a CLEARED verdict that rests on it; each counted observation is emitted as a `downgrade` catalog record that `vf_tally` counts per gate, and no second fold remains in `vf_tally`. A declared manifest tier followed by a lower non-resolved round tier yields `severity-downgrades=1`. The same ID on the other gate yields 0, and no manifest crosses gates. Every existing tier fixture keeps its count, and on the real record 003 reports 5 and 002 reports 0. The dispatcher reader refuses a clause line whose body holds a second clause, such as `  probe) :;; probe3) echo probe3; exit 0;;`, which bash executes as two verbs, with the named AC-018 diagnostic, so deleting that refusal fails a fixture.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-verification.sh && bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, REQ-015, AC-012, AC-017, AC-018, FM-019, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-9 O-014 and both Held-up isolation gaps. Shares T030o39's Verify command so one capture on unchanged source can serve both acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-411-B8GLAC verified by spec-gate accept; return sha256:9e9938a290947e9052071c2506952b052f323a5ccd4de9141aa1b9391ae86202

- [x] **T030o41** [hard] — Make every reuse-checked reader read what the input identity hashes
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `README.md`, `.specify/stack.yml`, `.github/workflows/ci.yml`, `.specify/specs/003-gate-round-reduction-and-token-discipline/tasks.md`, `tests/helpers.sh`, `tests/run.sh`, `tests/shellcheck.sh` (new), `tests/test-gate-contracts.sh`, `tests/test-verification.sh`, `tests/test-sdd-analyze.sh`, `tests/test-usage-limits.sh`, `tests/test-model-policy.sh`, `tests/test-build-adapters.sh`, `tests/test-executable-bits.sh`, `tests/test-spec-gate.sh`, `tests/test-spec-dispatch.sh`, `tests/test-golden-example.sh`, `tests/test-spec-ac-coverage.sh`
  - *Acceptance:* Derive the obligation from the identity (REQ-009, AC-020): a reuse-checked command's verdict is a function of the input identity, so it reads the repository only as `vf_snapshot` hashes it. Paths come from one enumeration function, `vf_source_paths` (Git worktree root required, NUL-framed `git ls-files --cached --others --exclude-standard`, a git failure is a failure), which `vf_snapshot`'s path pass also calls; content comes from `vf_path_content` (a link's target as it is, a file through `vf_semantic_file`, always from the repository-rooted path), which `vf_path_record` also calls; both leave the identity's records unchanged. The readers are derived from the production, not the reports: the reuse-checked commands' own file lists, every glob a suite makes over the live kit, whole-kit copies and the scripts run on them, spec records read in place, and the environment and configuration the programs consult. So `tests/run.sh` lists suites through `vf_source_paths`; `tests/shellcheck.sh` runs ShellCheck over the enumerated `scripts/*.sh` and `tests/*.sh` with `SHELLCHECK_OPTS` unset and `--norc`, and is the ShellCheck command everywhere; live-kit globs in suites come from a `kit_files` helper; the O-010 scan folds case where the identity does and reads every name; the AC-023 loop takes its shipped set from the enumeration and each artifact from `vf_path_content`; `copy_kit` copies the enumerated hub content without `.specify/specs/`, is used for every copy of live-kit content, whole or one directory, and never uses an EXIT trap; `stage_kit`'s writer never writes through a link; the 002 tally test reads an enumerated copy of 002's `notes/`; a reader enumerates under exactly the environment and configuration the identity enumerates under, so suites start with only the kit's own `SDD_*` and `XDG_STATE_HOME` unset, never a variable git consults for its configuration; git's repository-local variables (the names `git rev-parse --local-env-vars` prints) are unset for every git process the kernel runs, never for the snapshot's own environment records, so a declared one is hashed by its value, and they are unset when a suite starts, so a repository is named by its path alone and no fixture can write a caller's index; every git command in the suites that writes a repository, apart from the one deliberately raw negative control, runs through one helper with none of the caller's git environment and a pinned, empty git configuration and template, and a fixture repository that cannot be built fails its test by name whatever the caller does with the status, while leaving no caller a path outside its sandbox; git reads and the kit's code under test keep the ambient configuration; a fixture that plants git configuration pins all of git's global and system configuration and proves each pinned input it can plant; a host-kit fixture binds every load-time alias that names a live-kit directory in its scope to the host, so it judges whatever spelling its site reads; `tests/run.sh`, `tests/shellcheck.sh` and `tests/helpers.sh` unset `CDPATH`, `BASH_ENV` and `ENV` before resolving a path; `vf_source_paths` accepts the root by directory identity, not by spelling; host-kit repositories always have `.git/info`; README states that both commands need a Git worktree root. Each site has a fixture in both directions against a host kit or tree carrying the ignored, directory-shaped, differently-spelled or ambient input, with exact diagnostics, and an in-repository spec in a hub-style `specs/` directory, outside `.specify/specs/`, has an empty anchor.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`, `tests/test-verification.sh::test_capture_provenance`, `tests/test-sdd-analyze.sh::test_verification_bindings`, `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-010, AC-018, AC-020, AC-023, FM-002, FM-010, FM-014, FM-019, INV-001, INV-006, plan §3.2, §4.2
  - *Notes:* Owns round-10 O-015 and the round-10 Held-up isolation gap, plus the sibling readers the report did not name: two reproduced before repair (`notes/verification/reports/o015-repro.{sh,log,rc}`) and the rest found by the two independent review passes (`notes/verification/reports/t030o41-review.md`) and by the second pair (`notes/verification/reports/t030o41-review2-passC.md`, `t030o41-review2-passD.md`), including the pre-existing git-environment data loss the user chose to include, and by the focused reviews of the later repairs (`notes/verification/reports/t030o41-review3-partial.md`, `t030o41-review4.md`), including the pre-existing fixture-repository configuration the user chose to include. The harness-level bash startup environment is recorded in Decisions and is not part of this task. The user chose one task and then chose to expand it to every measured member (Decisions, 2026-09-24). Changing T027's Verify to the pinned ShellCheck command makes T027's sealed acceptance historical. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-455-RNmM6l verified by spec-gate accept; return sha256:e34f4a3d716bf37274e832308f04c3d39254e6638982d4252f9dfb9fcecf103d

- [x] **T030o42** — Pin the locale where every reuse-checked command the kit ships starts
  - *Files:* `tests/helpers.sh`, `tests/run.sh`, `tests/shellcheck.sh`, `tests/test-verification.sh`, `templates/verification-contract.md`, `scripts/verification-lib.sh` (a comment)
  - *Acceptance:* Derive the member from what the programs a reuse-checked command runs consult, not from the command's own variable reads (REQ-009, AC-020). `date` formats `%p` from `LC_TIME`; `tr`, `sed`, `cut`, `wc`, `od`, awk and grep take character classes from `LC_CTYPE`; `sort` and `find` collate by `LC_COLLATE`; git's messages follow `LC_MESSAGES`; and the input identity hashes no undeclared name. So every command in the kit's own `reuse_checks` (`tests/run.sh`, `tests/shellcheck.sh`) exports `LC_ALL=C` right after it clears `CDPATH`, `BASH_ENV` and `ENV`, before any other program runs, and `tests/helpers.sh` does the same when a suite starts, so a suite run on its own is pinned too. `LC_ALL` overrides `LANG` and every category. A fixture takes the commands from the kit's `reuse_checks` and fails by name on one it has no probe for. It runs each on a host kit from a shell with `LC_ALL` unset and `LANG=de_DE.UTF-8`, where a program the command runs must see `LC_ALL=C`; a shell that loads `tests/helpers.sh` must export it; and the three usage-limits cases round 11 saw fail pass under `LANG=en_GB.UTF-8` and `LANG=de_DE.UTF-8` on a host where those locales change `date`'s `%p`, which macOS must be. Removing any pin, or its export, fails the fixture with an exact diagnostic. The contract says no undeclared variable decides a check's verdict, names what the programs consult, and says a check pins such a name or declares it, as the kit's commands pin `LC_ALL=C`; it and the kernel comment say the harness runs under the caller's locale, pins `LC_ALL=C` where collation matters and fails closed in a locale that cannot decode the kit's bytes. The input identity's records are unchanged.
  - *Verify kind:* test
  - *Tests:* `tests/test-verification.sh::test_capture_provenance`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-020, FM-010, FM-014, INV-001, plan §3.2, §4.2
  - *Notes:* Owns round-11 O-016, reproduced before repair (`notes/verification/reports/o016-repro.{sh,log,rc,note}`), with the rule measured before adoption (`notes/verification/reports/o016-measure.{sh,log,rc}`). Option variables a program reads only when someone sets them (`UNAME_SYSNAME`, `GREP_OPTIONS` and the rest measured on 2026-09-26) belong to the recorded harness-level environment item, not to this task. Shipped 002's own locale-dependent reset parsing in `scripts/usage-limit.sh` is outside this spec and is not repaired; the pin removes only the reuse half. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-499-rKuH6Z verified by spec-gate accept; return sha256:7b457257938f719fb7401738586b6f7a8939bb87d02e3a9a0f853280264c22da

- [x] **T030o43** — Run the harness's own parsing under the C locale and never let a parse failure read as a pass
  - *Files:* `scripts/verification-lib.sh`, `scripts/spec-run.sh`, `scripts/spec-task.sh`, `scripts/sdd-analyze.sh`, `scripts/spec-ac-coverage.sh`, `scripts/spec-evidence.sh`, `templates/verification-contract.md`, `tests/helpers.sh`, `tests/test-verification.sh`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`, `tests/test-sdd-analyze.sh`
  - *Acceptance:* Derive the pin's member from the harness, not from the sites round 12 named (REQ-009, REQ-011, AC-012, AC-020): the file set the input identity records as `harness`, and every process it starts except the captured command. Every grammar the harness parses is ASCII, and under `LC_ALL=C` each byte is one character, so no byte can end a parse. A byte >= 0x80 is in no character class there, so every parser of author text reads the 19 non-ASCII Unicode White_Space characters as whitespace through one shared step before any rule of its own, mapped to a byte every class-based test reads as whitespace and no literal grammar does, so CommonMark structure and literal separators read as they did before the pin; it takes every value it passes on into a catalog or a record, to another program or into a comparison from the line as written, trimmed at its ends, and never splits a mapped line by awk's default field splitting; and a grammar token it cannot read is refused by name. `vf_report_block` alone reads the report as written, because its output is a sealed digest. `verification-lib.sh` exports `LC_ALL=C` when it loads, and each of the six harness entry scripts loads it directly after `lib.sh`, before any program reads a repository or bookkeeping byte; `lib.sh` is unchanged. The caller's `LC_ALL` (a value, empty, or unset) is kept in the exported `SDD_HARNESS_CALLER_LC_ALL` for the harness processes a harness process starts; the captured command (`vf_capture`, and `spec-run.sh`'s legacy run) gets it back exactly and never sees the record, and the record of a declared `LC_ALL` carries the caller's value. No parse failure reads as a passing result: every harness parser whose output decides a record, an identity or a verdict, and whose failure would read as an absence that passes, reads its exit status and fails closed with a diagnostic naming the parse, among them the prior-review manifest pass and the Decisions-log authorization parse (the members, derived from every text-program call in the harness, are recorded in Decisions). With every `LC_*` removed and `LANG` at `en_US.UTF-8`, `de_DE.UTF-8`, `C.UTF-8` and `ja_JP.SJIS`, a manifest carrying an undecodable byte, a Class binding and a UTF-8 manifest under Shift-JIS each refuse exactly as under C, through `vf_reports` and end to end through `spec-gate.sh round --complete`; the analyzer's clarification marker and AC inventory, and `spec-ac-coverage.sh`'s AC inventory, refuse the byte as under C; the prior-review manifest pass reads by the canonical field grammar keyed on its field lines, decides a field line by its label and takes its value after that label only, refuses by name a line not read as a heading that is a `#` run and the word Finding, and reads a Class or Severity line outside any finding as prose only while nothing since the last heading can hold a finding's record (a finding ID, a heading whose second word is Finding, or a heading deeper than the Finding heading it follows), and refuses a manifest from which it reads no finding, so every finding opened by a heading, or by a line that looks like one, is either read or refused by name; a value, field or section of only such whitespace is empty; the input identity's Decisions view covers every line the authorization scanner reads, from each line that begins `## Decisions log`, quoted or not, to the next unquoted heading; an artifact name or Agent path ends at any whitespace and a non-ASCII letter is part of it; a `verification_contract` key routes three ways by count in every reader; a matrix criterion is compared by the AC catalog's whitespace rule; a stage heading is its text trimmed at both ends in every reader that compares it; on macOS each locale must be one an unpinned awk cannot decode the byte under. Every harness entry script runs its programs under `LC_ALL=C`; the captured command sees the caller's `LC_ALL` unset, empty or set; a declared `LC_ALL` gives two identities for two caller values; and a fault injected into each member parser fails its operation closed with its exact diagnostic. The kit's suites set `TMPDIR` to the physical path of the directory it names when they start (`/tmp` when it is unset), so its spelling (a trailing or doubled slash, `.` or `..`, a symlink) cannot decide a verdict that compares a path under it, and a `TMPDIR` naming no directory stops a suite by name. Removing the pin, an entry script's early load, the restore, the caller-value record, any status read or the `TMPDIR` canonicalization fails a fixture with an exact diagnostic. The contract and the kernel comment say the harness runs its own parsing under `LC_ALL=C`, gives the caller's `LC_ALL` back to the command it captures, and never lets a parse failure read as a pass, and that the spelling of `TMPDIR` can decide a check that compares a path under it, which the kit's suites pin. The input identity's records are unchanged apart from the edited files and the harness records.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`, `tests/test-sdd-analyze.sh::test_verification_bindings`, `tests/test-verification.sh::test_capture_provenance`, `tests/test-spec-gate.sh::test_floor`, `tests/test-spec-gate.sh::test_acceptance`, `tests/test-spec-gate.sh::test_checkpoints`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, REQ-011, AC-007, AC-008, AC-009, AC-012, AC-020, AC-022, AC-023, FM-002, FM-010, FM-012, FM-014, FM-016, FM-019, INV-001, INV-004, INV-006, plan §3.2, §3.3, §4.2
  - *Notes:* Owns round-12 O-017, reproduced before repair (`notes/verification/reports/o017-repro.{sh,log,rc,time}`), with the rule measured before adoption (`notes/verification/reports/o017-measure.{sh,log,rc,time}` and `o017-measure-m3.{sh,log,rc}`); the member classification is `notes/verification/reports/t030o43-parser-classes.md`. Shipped 002's own locale-dependent reset parsing in `scripts/usage-limit.sh` stays outside this spec: 002's dispatcher sources `lib.sh`, not the kernel, so the pin does not reach it. Umbrella-only readers stay recorded extent. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-522-PgNdFn verified by spec-gate accept; return sha256:3887a0822310cd47aa4fc9611da5b51d2fadefc06fdc2cf82224ab587a5dbcd5

- [x] **T030o44** — Make both readers of finding records refuse what they cannot read, never read it as prose
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Derive the members from what a reader of the rendered Markdown reads as a record, not from the spellings round 13 or the T030o44 review named (REQ-011, AC-012). One label reader serves both readers of finding records: a line carries a Class or Severity label when the first word of its text, read as written or as rendered, is that label in any case and the line is an emphasized label or the word is not continued by a letter, digit or hyphen, so that an approximation of the rendering can only make a line refuse. The rendered reading takes inline raw HTML out by CommonMark's own productions (an open tag with its attributes, a quoted value holding `>` included, a closing tag, a comment, which `<!-->` completes, a processing instruction, a declaration, a CDATA section), takes out link destinations, reference labels and images, renders a footnote reference as its number, a numeric character reference as its character and a named one as a character that is no letter or digit; the first word follows any run of characters that are not letters or digits, ordered-list numbers and task checkboxes. The prior-review manifest pass refuses by name a finding that does not carry exactly one readable Class and one readable Severity, so a tier it does not read is refused with its finding, never dropped; a finding is the section its Finding heading opens, so a heading as shallow as that one closes it and a deeper heading is one of its lines, read or refused like any other (O-019); and a heading read as a Finding heading that the pass cannot open is refused by name. The canonical report pass refuses by name any heading read as a Finding heading other than `### Finding <ID>`, and a line not read as a heading that is a `#` run and the word Finding; closes a finding at a heading as shallow as `###`; refuses a finding field line outside any finding and, inside a finding, a line whose label is Class or Severity that is not that field's line, prose included; and keys a duplicate field by its label in a round of either style, so an indented second Severity is a duplicate. The shared quoting tracker is a line reader that does not follow CommonMark's containers, so both passes refuse by name a quoted line (fenced, blockquoted, commented or raw HTML) that is a Finding heading, or that carries a record of the finding it is in (a finding field line, a Class or Severity line), the manifest pass anywhere and the canonical pass in a canonical round before its completion marker; and the list item of a Class or Severity field line, and in a canonical finding of a Status line, holds that line only, so a line that would continue its paragraph, or other text inside the item, is refused by name unless the pass reads it as a field line of its own. The canonical rules apply to canonical rounds of either gate before the completion marker, so legacy rounds and the after-marker refusal are unchanged but for the duplicate key. The recorded history (001, 002, 003) gives the same tally, report catalogs, diagnostics and sealed round digests as before the change. Fixtures cover every reproduced member and each derived sibling in both directions with its exact diagnostic, directly under `LANG=C` and `LANG=en_US.UTF-8`, and each mechanism end to end through `round --complete`; every refusal row of the manifest table asserts its own diagnostic; a legacy round reaching every canonical rule parses with its catalog; removing any guard fails a fixture. The kernel comments and the contract say what the code does.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-13 O-018 with O-019 folded in, reproduced before repair (`notes/verification/reports/o018-repro.{sh,log,rc,time}`), with the rule measured before adoption (`notes/verification/reports/o018-measure.{sh,log,rc,time}`). A finding written in prose only, with neither a Finding heading nor a canonical field line, is the recorded O-004 omission extent. The T030o44 review (`notes/verification/reports/t030o44-review.md`, reproduced by `t030o44-review-verify.{sh,log,rc}`) is its second input, and its repairs were measured before adoption (`notes/verification/reports/t030o44-measure-2.{sh,log,rc,time}`). No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-544-cjPQ2j verified by spec-gate accept; return sha256:e7fd68649b8160f8d6e7bf0e425b40f2ed1f266af098e633c3186851f4ead372

- [x] **T030o45** — Decide a round's style before its body, so the round's own text cannot switch its rules off
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Derive the member from what decides which rules judge a line of a round, not from the spelling round 14 named (REQ-011, AC-012). A round's style is a value its own text sets: the round heading makes it canonical, a report title read before its Round and Timestamp lines makes it legacy, and a Timestamp line makes it canonical, while every canonical rule of `finding()` (the count included) and of both record readers reads the style of the line it judges and `flush()` reads the last one. So `vf_reports` decides a round's style before the round has a body: once it has one (any non-blank line but its heading, its report title and its identity fields, quoted or not), a title that would make a canonical round legacy, and a Timestamp line that would make a legacy round canonical, are each refused by name, in a round of either gate, and no line of a round sealed canonical is judged by the legacy rules. Every recorded round (003's fourteen opponent rounds and its reality-check round, 002's titled legacy rounds, 001's legacy rounds) gives the catalog, diagnostics and exit it gave before. Fixtures, under `LANG=C` and `LANG=en_US.UTF-8`: under a title and a late Timestamp, an uncounted blocking finding, a resolved claim on a finding a round counted open, an invented resolution, an unknown severity and each T030o44 member are refused with the exact diagnostic, while the same rounds without the title keep their own refusals; a round the title opens, a title after content and a reality-check round are refused the same way; a titled round whose Timestamp precedes its body parses; and the counting case and round 13's canonical member are refused end to end through `round --complete`. The mutation matrix restates row Q08's argued equivalence on the true premise.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-14 O-020, reproduced before repair with its siblings (`notes/verification/reports/r14-repro.{sh,log,rc,time}`), with the rule measured before adoption (`notes/verification/reports/r14-measure.{sh,log,rc,time}`). It predates T030o44, and every rule T030o44 added inherited it. Serial with T030o46, which edits the same files; one capture of the shared Verify on unchanged source can serve both acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-567-dtDT42 verified by spec-gate accept; return sha256:8ef4fce9e05d702bc3a55b4ad5cd562de933c815471208e68742779ba9d32bfe

- [x] **T030o46** — Read a finding record by paragraph and with nesting, as a renderer reads it
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Derive the members from what a renderer shows as the first word of a line or of a paragraph, not from the spellings round 14 named (REQ-011, AC-012). The label reader's rendered reading reduces bracket pairs innermost first, to a fixpoint (CommonMark 0.31.2 6.3, 6.4): an image becomes a character that is no letter or digit, a link or a reference link its text between two such characters, a footnote reference its number, any other pair its text, a task checkbox stays, and a bracket a backslash escapes is literal (2.4); it takes out a run of `*` between two letters or digits (6.2); and a second rendered reading also takes out every named reference, every numeric reference beyond ASCII and every byte outside ASCII, so a word a renderer shows whole across an invisible character is read whole; a label any reading yields counts. Both readers of finding records read a label from each paragraph as well as from each line: a line joins the paragraph before it unless it is blank, starts a block, follows an ATX heading or sits in a code fence, read without its block-quote markers, and a line that continues a paragraph whose joined text carries a label its first line did not is refused by name, as a Class or Severity line this grammar cannot read or, quoted, as quoted content carrying one. `vf_block_start` admits every HTML block that may interrupt a paragraph (4.6: every kind but the seventh, condition 6's block-level tag names included) and a backtick fence of three or more whose info string holds no backtick (4.5), so a Class, Severity or Status line followed directly by such a block holds its item alone (O-021), while a line a condition-7 tag opens and a backtick run whose info string holds a backtick still continue the item and are refused. Every recorded round, report and prior-review manifest, and every returned round report read as a manifest, gives the catalog, diagnostics and exit it gave before. Fixtures, under both locales: every round-14 member and each derived sibling in both passes with the exact diagnostic, one end to end per mechanism; the shipped `value-details` row becomes a positive beside a `span` refusal twin; and prose that wraps, links, images and emphasis in prose parse.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-14 O-018 (reopened) with O-021 folded in, reproduced before repair with the siblings derived from the same mechanism (`notes/verification/reports/r14-repro.{sh,log,rc,time}`), with the rules measured before adoption (`notes/verification/reports/r14-measure.{sh,log,rc,time}`); it also closes the invisible-character extent sessions 12 and 13 recorded. Serial after T030o45, which edits the same files. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-567-dtDT42 verified by spec-gate accept; return sha256:9b0a5c84193ccc8ea2bf8b0f3724c017c42b4591ad33a2d74c18fb813fff0bb2

- [x] **T030o47** — Read every candidate paragraph start, code-span syntax as inert and every rendered line start, so a boundary error can only refuse
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Derive the members from where CommonMark 0.31.2 puts a paragraph boundary and starts a rendered line, not from the spellings round 15 named (REQ-011, AC-012). Both readers of finding records keep a run of non-blank lines that only a blank line, a line in a code fence or an ATX heading ends, read each line without its indentation and block-quote markers, and take every line of the run as a candidate paragraph start; a line after which the text joined from an earlier candidate whose own line carries no label carries one is refused by name, once per run, as a Class or Severity line this grammar cannot read or, quoted, as quoted content carrying one, so a boundary the reader misses (a sibling ordered item of any number or delimiter, a setext underline, a block-quote marker: 4.3, 4.8, 5.1, 5.2) or invents (a line indented four or more spaces that begins with a block marker: 4.4) can only refuse. The label reader adds a reading that keeps the letters and digits of every code span and makes its other characters inert (6.1: a backtick string closed by a backtick string of the same length), and reads the label after each br tag and each condition-6 block-level tag outside code spans (4.6), in prose and, in the canonical pass, in the value of every field line. A label any reading yields counts. Every recorded round, report and prior-review manifest, and every returned round report read as a manifest, gives the catalog, diagnostics and exit it gave before. Fixtures, under both locales: every round-15 member and each derived sibling in both passes with the exact diagnostic, and one end to end per mechanism; prose that wraps, ordered lists, code spans holding brackets and tags, a br tag in prose and br and p tags in a field value with no tier, and a setext heading in prose parse.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-15 O-018 (reopened), reproduced before repair with the siblings derived from the same productions (`notes/verification/reports/r15-repro.{sh,log,rc,time}`), with the rule measured before adoption (`notes/verification/reports/r15-measure.{sh,log,rc,time}`) and its fixtures judged in both directions (`notes/verification/reports/r16-fixtures-judge.{sh,log,rc,time}`). Its members predate T030o46. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-589-ZNd9Ug verified by spec-gate accept; return sha256:2a8d2a944234a6a6daa9771e97f34479e46ee5bc096283385d1c4163134d4755

- [x] **T030o48** — Narrow the grammar inside a finding: refuse by name raw HTML outside every code span, a form feed or vertical tab, and a carriage return inside a line
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Narrow the grammar a finding is written in rather than approximate a renderer, as the user decided on 2026-10-08, deriving the refused constructs from the CommonMark 0.31.2 productions round 16 found the readings diverging from (2.1, 2.4, 4.6, 6.1, 6.5, 6.6), not from its spellings (REQ-011, AC-012). Inside a finding, in both readers of finding records (the manifest pass, and the canonical pass of a canonical round before its completion marker), a line is refused by name when it carries a form feed or vertical tab, or a carriage return that does not end the line, read on the line as written, or a `<` followed by a letter, `/`, `!` or `?`, which may open raw HTML or an autolink, outside every code span. Code spans are placed by 6.1 read left to right, 2.4's backslash escapes taken in pairs and a backtick run closed only by the next run of the same length, for every state a paragraph may enter the line in (no open span, or a span an earlier line of the run left open, read both as an opener and as literal text), and a `<` counts as inside a code span only when every such reading places it there; the label reader's code-span reading uses the same tokenizer. A run of lines ends only at a blank line of spaces and tabs or an ATX heading, never at a line the shared tracker calls fenced. Every recorded round, report and prior-review manifest, and every returned round report read as a manifest, gives the catalog, diagnostics and exit it gave before. Fixtures, under both locales: every round-16 O-018 member, the fenced-line member and each derived sibling in the manifest pass and one row per mechanism in the canonical pass, each with the exact diagnostic, and one end to end per mechanism; T030o47's positives that carry raw HTML inside a finding and O-021's HTML blocks after a field line become refusals by name; a four-backtick fence after a field line, code spans holding tags and brackets, and an escaped `<` parse.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-16 O-018 (reopened), reproduced before repair (`notes/verification/reports/r17-repro.{sh,log,rc,time}`), with the rule measured before adoption (`notes/verification/reports/r17-measure.{sh,log,rc,time}`), the recorded history surveyed (`notes/verification/reports/r17-grammar-survey.{py,log,rc}`) and its fixtures judged in both directions (`notes/verification/reports/r17-fixtures-judge.{sh,log,rc,time}`). Its members predate T030o47. Serial with T030o49 and T030o50, which edit the same files; one capture of the shared Verify on unchanged source can serve all three acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-612-hpySUJ verified by spec-gate accept; return sha256:4f7624e21798817d11997f35a6289a3ad245d24fdba0973de47de3c1274dc531

- [x] **T030o49** — End a run of lines only at an ATX heading of one to six marks
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Derive the heading that ends a run from the ATX heading production (CommonMark 0.31.2 4.2: one to six `#` after at most three spaces of indentation), as `vf_block_start` already spells it, not from a `#` run of any length (REQ-011, AC-012). The run reader of both readers of finding records ends a run at such a heading only, read without its block-quote markers, so a line that begins with seven or more marks, which a renderer keeps inside the paragraph, continues the run, and every candidate before it is read across it. Every recorded round, report and prior-review manifest, and every returned round report read as a manifest, gives the catalog, diagnostics and exit it gave before. Fixtures, under both locales: an image split by a line of seven marks in both passes and by a quoted line of eight in the manifest pass, each with the exact diagnostic, and the seven-mark image end to end in both passes.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-16 O-022, a regression of T030o47, reproduced before repair (`notes/verification/reports/r17-repro.{sh,log,rc,time}`: it seals on the T030o47 tree and is refused on the tree before it), with the rule measured before adoption (`notes/verification/reports/r17-measure.{sh,log,rc,time}`) and its fixtures judged in both directions (`notes/verification/reports/r17-fixtures-judge.{sh,log,rc,time}`). Serial after T030o48, which edits the same files. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-612-hpySUJ verified by spec-gate accept; return sha256:a625ec1072c3208254ca7fe9b1b8c7bbbeba4dd7258abbc901c4810cbff875d3

- [x] **T030o50** — Drop a settled candidate from the run reader, so its cost stays near linear in a run's length
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Bound the run reader's cost by what can still change a candidate's reading, as the user decided on 2026-10-08, not by a cap on a run's length (REQ-011, AC-012). The run reader stops extending and re-reading a candidate once its text is settled: every construct a reading resolves across lines (a code span, a bracket pair, a link destination, a raw-HTML construct) is closed within it, and every reading of it, and of the text after each br or block-level tag in it, already holds its first word, so no later line can change how any reading of it begins; a candidate not shown settled is kept, and a candidate whose own line carries a label is set aside at once. Every recorded round, report and prior-review manifest, and every returned round report read as a manifest, gives the catalog, diagnostics and exit it gave before, and one canonical round whose Reproduced field holds 400 sub-bullets with code spans, links and tags parses in under 30 s, doubling a run from 200 to 400 lines at most quadrupling its time. Fixtures, under both locales: every member row whose tier a candidate reaches only across lines (a split image or link) is refused with the exact diagnostic, so a candidate dropped before its construct closes loses its row; the mutation matrix gives each condition of the settled test its own row, judged by a fixture or argued equivalent beside it.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-16 O-023 (minor, fails closed), reproduced before repair (`notes/verification/reports/r17-repro.{sh,log,rc,time}`: 69 s at a 100-line run on the T030o47 tree), with the rule measured before adoption (`notes/verification/reports/r17-measure.{sh,log,rc,time}`: at most 1 s at 400 lines) and its fixtures judged in both directions (`notes/verification/reports/r17-fixtures-judge.{sh,log,rc,time}`). Serial after T030o49, which edits the same files. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-612-hpySUJ verified by spec-gate accept; return sha256:032317aa412be675613e896ad1f52e2ddcbe987c33465171781e38a8cedc6f42

- [x] **T030o51** — Narrow the finding grammar further: refuse by name a `<` that may open an autolink, and a link destination, title or label that holds a backtick or does not end on its line, judged after a line's own heading
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Narrow the grammar a finding is written in further rather than place code spans after the constructs that bind before them, as the user decided on 2026-10-09, deriving the refused constructs from the CommonMark 0.31.2 productions that consume a backtick before a code span can open (6.3, 6.5, 6.1), not from round 17's spellings (REQ-011, AC-012). Inside a finding, in both readers of finding records (the manifest pass, and the canonical pass of a canonical round before its completion marker), a line is refused by name when, outside every code span by the reading of T030o48 (every state a paragraph may enter the line in), it carries a `<` followed by a digit or a symbol an email address's local part may begin with (`an autolink outside a code span`; a `<` followed by a letter, `/`, `!` or `?` stays raw HTML), or an inline link's destination or title, or a full reference link's label, read from `](` or `][` as a renderer reads it, that holds a backtick (`a backtick inside a link destination, title or label`) or does not end on its line (`a link destination, title or label that does not end on its line`); a `](` or `][` inside a code span in every reading is literal, so a report still quotes such a construct between two backticks. The narrowed check is judged after the line's own heading has opened or closed a finding: a Finding heading carrying raw HTML is refused under the finding it opens, the first one of a round included, and a section heading that closes a finding is outside it. Every recorded round, report and prior-review manifest, and every returned round report read as a manifest, gives the catalog, diagnostics and exit it gave before. Fixtures, under both locales: every round-17 O-018 member and each derived sibling (an autolink whose local part begins with a digit, an underscore, a backtick or a plus; a destination, a title, a pointy destination and a label holding a backtick; a title, a destination and a label continued on the next line) in both passes with the exact diagnostic, `c <= d` inside a finding as the stated consequence, the minor's three cases, the round-17 members quoted inside two-backtick code spans as positives, and one end to end per mechanism.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-17 O-018 (reopened) and the round's non-blocking minor, folded in; reproduced before repair (`notes/verification/reports/r18-repro.{sh,log,rc,time}`), with the rule measured before adoption (`notes/verification/reports/r18-measure.{sh,log,rc,time}`), the recorded history surveyed (`notes/verification/reports/r18-grammar-survey.{py,log,rc}`) and its fixtures judged in both directions (`notes/verification/reports/r18-fixtures-judge.{sh,log,rc,time}`). Its members predate T030o48. Serial with T030o52 and T030o53, which edit the same files; one capture of the shared Verify on unchanged source can serve all three acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-634-14RLF3 verified by spec-gate accept; return sha256:505b44cb4aa588710334178df2fc62581063e9b70679f9132e41ca760a647eec

- [x] **T030o52** — Refuse by name inside a finding a code fence that may be inside a list item and a link reference definition
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Narrow the finding grammar to what both readers can follow rather than derive a finding's extent from the constructs a renderer opens, as the user decided on 2026-10-09, deriving the refused constructs from the CommonMark 0.31.2 containers and leaf blocks the shared fence tracker and the passes do not follow (4.5, 4.7, 5.2), not from round 17's spellings (REQ-011, AC-012). Inside a finding, in both readers of finding records, a line is refused by name when it opens a code fence (three or more backticks or tildes) anywhere but at the start of the line, after indentation or a list marker, where a list item may open one the tracker does not open, or opens at a place a renderer ends with the item (`a code fence that may be inside a list item`), and when it begins a link reference definition (its text, after indentation, list markers and block-quote markers, a bracket closed at once by `]:`) or closes by `]:` a label a bracket at the start of an earlier line of its run left open (`a link reference definition`), since a definition renders nothing and its title may carry a field line. A fence at the start of a line, link text wrapped at the start of a line and an escaped bracket still parse. Every recorded round, report and prior-review manifest, and every returned round report read as a manifest, gives the catalog, diagnostics and exit it gave before. Fixtures, under both locales: every round-17 O-024 member and each derived sibling (a fence after a list marker or an ordered marker, a fence at two spaces whose item a column-0 fence ends, a fence at four spaces in an item; a definition hiding the tier, a definition in a list item, a label across lines, an escaped label) in both passes with the exact diagnostic, a fence indented under a list item and a definition line as the stated consequences, and one end to end per mechanism.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-17 O-024 (new, plan-gap), reproduced before repair (`notes/verification/reports/r18-repro.{sh,log,rc,time}`: it seals on the tree before T030o48 too), with the rule measured before adoption (`notes/verification/reports/r18-measure.{sh,log,rc,time}`), the recorded history surveyed (`notes/verification/reports/r18-grammar-survey.{py,log,rc}`) and its fixtures judged in both directions (`notes/verification/reports/r18-fixtures-judge.{sh,log,rc,time}`). Serial after T030o51, which edits the same files. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-634-14RLF3 verified by spec-gate accept; return sha256:6289f739360690bc821bb6e579aa6cddef5b62edf2f6a9d0609d8b00be71361d

- [x] **T030o53** — Settle a run reader's candidate on what opens at or before the first word of each of its readings
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* Bound the run reader's cost by what can still change how a reading of a candidate begins, the round-17 reviewer's rule, measured before adoption and corrected for soundness (REQ-011, AC-012). A candidate is settled once every code span and raw-HTML construct in it is closed and every reading of it (as written, the inert code-span reading, the rendered readings of both, and the readings after each br or block-level tag) holds its first word with no bracket pair or link destination left open at or before that word in that reading, ordered-list numbers and task checkboxes included in what comes before it; a bracket after the first word, quoted in a code span or not, keeps nothing unsettled, while one before it does, in the rendered readings too, so a named reference and an image a later line completes still refuse. Every recorded round, report and prior-review manifest, and every returned round report read as a manifest, gives the catalog, diagnostics and exit it gave before; one canonical round whose Reproduced line quotes an opening bracket in a code span and whose field holds 400 sub-bullets with code spans, links and emphasis parses in under 30 s, doubling a run from 200 to 400 lines at most quadrupling its time. Fixtures: that 400-line run as a row that must parse within 60 s; the mutation matrix gives each condition of the settled test its own row, judged by a fixture or argued equivalent beside it.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-17 O-023 (reopened, minor, fails slow), reproduced before repair (`notes/verification/reports/r18-repro.{sh,log,rc,time}`: 41 s at a 200-line run and 300 s at 400 on the T030o50 tree), with the rule measured before adoption (`notes/verification/reports/r18-measure.{sh,log,rc,time}`) and its fixtures judged in both directions (`notes/verification/reports/r18-fixtures-judge.{sh,log,rc,time}`). Serial after T030o52, which edits the same files. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-634-14RLF3 verified by spec-gate accept; return sha256:0e8a025249f5870cb1a44a8ce6fb40936806e5082bc2d9fa27bbb2f2c1f9707e

- [x] **T030o54** — Narrow the finding grammar further: refuse by name a backtick inside a bracket pair closed on its line or inside a GFM URL literal, outside every code span
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* As the user decided on 2026-10-14 (the round-18 reviewer's M1), inside a finding, in both readers of finding records (the manifest pass, and the canonical pass of a canonical round before its completion marker), a line is refused by name when, outside every code span in some reading, it carries a bracket pair closed on its line whose label holds a backtick run the label does not close (a shortcut, collapsed or image reference's label: `a backtick inside a link destination, title or label`), or a URL literal after `http://`, `https://` or `ftp://` (the scheme ending the text before it) or after `www.`, whose text up to whitespace or `<` holds a backtick (`an autolink outside a code span`): the constructs marked binds before any code span (REQ-011, AC-012). Rows in both passes and both locales for every round-18 member (the four URL spellings and the three reference spellings); positives that parse (a URL literal before a code span, link text holding a closed code span, references with no backtick in their labels, `www.` in prose); and end to end, a URL member and a reference member in the manifest pass and a `www.` member and an image-reference member in the canonical pass, each refused at completion by name.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-18 O-018 (reopened, blocking); its members predate T030o51. Reproduced before repair (`notes/verification/reports/r19-repro.{sh,log,rc,time}`); the kernel change is the round-18 reviewer's own mutant, taken from its transcript and applied by `notes/verification/reports/r19-edits/apply-code.py`. Under the user's decision of 2026-10-14 the invoker's extra proof steps (the mutation matrix, two-direction fixture judging, a separate measurement script, repeated dev runs) are not run for this repair; one dev run in a standalone copy and the capture of record prove it. T030o54, T030o55 and T030o56 are serial, because all three edit the same four files; one capture of the shared Verify on unchanged source can serve all three acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-656-JZJTKB verified by spec-gate accept; return sha256:b8aec2da72405d432c24ef057823e140204f7aaa311a5061c4f19db8a18173a0

- [x] **T030o55** — Refuse by name inside a finding a line that may be a GFM table delimiter row
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* As the user decided on 2026-10-14 (the round-18 reviewer's M2), inside a finding, in both readers of finding records, a line whose text, spaces and tabs removed, holds a pipe and is a run of hyphen cells with optional colons separated by pipes is refused by name (`a table delimiter row`), since a renderer shows a cell's first text where the label reader, which never splits a line at a pipe, does not look (REQ-011, AC-012). Rows in both passes and both locales for a table and for a table in a list item with alignment colons; positives that parse (pipes in prose and in code spans); and end to end, a table in the manifest pass and a table after the fields of a canonical finding, each refused at completion by name.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-18 O-025 (new, blocking); its members predate T030o51, the gap dating from the label reader itself. Reproduced before repair (`notes/verification/reports/r19-repro.{sh,log,rc,time}`); the kernel change is the round-18 reviewer's own mutant, taken from its transcript and applied by `notes/verification/reports/r19-edits/apply-code.py`. Under the user's decision of 2026-10-14 the invoker's extra proof steps (the mutation matrix, two-direction fixture judging, a separate measurement script, repeated dev runs) are not run for this repair; one dev run in a standalone copy and the capture of record prove it. T030o54, T030o55 and T030o56 are serial, because all three edit the same four files; one capture of the shared Verify on unchanged source can serve all three acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-656-JZJTKB verified by spec-gate accept; return sha256:33a257ab7b3c0b5a641824c173968bc7f510344d5dd25f1c3fd310f50af4e7d4

- [x] **T030o56** — Settle a run reader's candidate when its head or its whole text balances
  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* As the user decided on 2026-10-14 (the round-18 reviewer's M3), a candidate is settled when its lead is settled and either its head's brackets balance (T030o53's rule) or its whole text's brackets balance with complete destinations (T030o50's rule), each argued sound alone (REQ-011, AC-012). A 400-line Reproduced field of sub-bullets led in turn by a link, an image and a code span holding a bracket parses within 60 s (0.32 s on the candidate; about 30 s at 100 lines on the round-18 tree), and the round-17 400-line row stays within its bound.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3
  - *Notes:* Owns round-18 O-023 (reopened, minor, degraded): T030o53's head-only rule left link-led lines unsettled. Reproduced before repair (`notes/verification/reports/r19-repro.{sh,log,rc,time}`); the kernel change is the round-18 reviewer's own mutant, taken from its transcript and applied by `notes/verification/reports/r19-edits/apply-code.py`. Under the user's decision of 2026-10-14 the invoker's extra proof steps (the mutation matrix, two-direction fixture judging, a separate measurement script, repeated dev runs) are not run for this repair; one dev run in a standalone copy and the capture of record prove it. T030o54, T030o55 and T030o56 are serial, because all three edit the same four files; one capture of the shared Verify on unchanged source can serve all three acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-656-JZJTKB verified by spec-gate accept; return sha256:606eee622e95284bbdbc27f5dbafd65d6e8d8ca22e010bb320b0d844a39acc24

## API

- [x] **T025** [hard] — Wire every invoker to deterministic acceptance
  - *Files:* `agents/sdd-orchestrator.md`, `skills/sdd-implement/SKILL.md`, `skills/sdd-go/SKILL.md`, `skills/sdd-review/SKILL.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-015 executable stub sequences plus entrypoint assertions proving no-tick/accept, one escalation retry, batch barriers, checkpoints, fresh floors and round refusal stop dispatch, replacing old cap/re-gate prose in all four invokers.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_invoker_protocol`, `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-007, REQ-008, REQ-009, REQ-012, REQ-014, REQ-016, AC-015, FM-004, FM-007, FM-013, INV-004, plan §4.2, §4.3, §8
  - *Integration owner:* T027
  - *Evidence:* CAP-25-YLM9sI verified by spec-gate accept; return sha256:0f374e981fae0459e64f6d37160f1481388730ee7863f6b28e48dfddfec3abc7

- [x] **T030o6** — Bind sdd-review CI and feedback follow-ups
  - *Files:* `skills/sdd-review/SKILL.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* The `c` and `r` follow-ups /sdd:review prescribes carry the full typed binding the validator requires — `Verify kind`, a plan-registered `Tests` locator and an executable `Verify` — and an executable fixture builds the instructed block, proves the older three-field shape can neither capture nor tick, then captures the typed one with `--from-task --no-tick --summary` and accepts it deterministically.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`, `tests/test-spec-gate.sh::test_acceptance`
  - *Verify:* `bash tests/test-gate-contracts.sh && bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-005, REQ-006, AC-015, AC-022, FM-009, plan §4.2, §4.3
  - *Notes:* Owns opponent finding O-006. The three-field shape the skill prescribes cannot produce a `--from-task` capture, so the documented post-PR fix path stalls before re-gating; keep the Ship exemption off follow-ups and update the plan registry only if a genuinely new family is needed.
  - *Evidence:* CAP-93-t1qHWF verified by spec-gate accept; return sha256:6e6e6180316b806804c996cc1cf1807e113470158c7e595550d4314d200740dd

## Tests

- [x] **T027f1** — Preserve the checkpoint execution start timestamp
  - *Files:* `scripts/verification-lib.sh`, `tests/test-spec-gate.sh`
  - *Acceptance:* A checkpoint's sealed start/end interval brackets an observed command execution; capture start before verification instead of stamping both boundaries at publication. Preserve failure and coverage behavior.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_checkpoints`
  - *Verify:* `bash tests/test-spec-gate.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-008, AC-008, FM-012, plan §3.3, §4.3
  - *Notes:* Owns the reporting defect recorded in the 2026-09-09 handoff; direct implementation continues under the user's existing instruction.
  - *Evidence:* CAP-46-MEsdpq verified by spec-gate accept; return sha256:79c09504daf672b42609c41def5ada1b1e2e05ba563cbb3f8b50dbcc19a02f68

- [x] **T026** — Add the noncircular live-wiring probe checker
  - *Files:* `tests/probe-gate-contract.sh` (new), `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-016 positive/negative sandbox fixtures for genuine rejection/acceptance digests and gate/floor identities, accepting an active reality-check reservation before its completed report while rejecting missing observations without making the default suite require live reports.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_invoker_protocol`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-007, REQ-012, REQ-016, AC-016, FM-018, INV-004, plan §2, §8
  - *Notes:* This task accepts the probe's fixtures only; T029 supplies the real worker control, and T030/T031 supply the actual gate observations.
  - *Evidence:* CAP-25-YLM9sI verified by spec-gate accept; return sha256:e6e4eefbd752292e0b7fcd9c7c482916cd5300ffe66ecdd8f84845e99d54f57e

- [x] **T027** — Exercise cross-component and portability integration
  - *Files:* `tests/test-gate-contracts.sh` (new in T001), `tests/test-build-adapters.sh`
  - *Acceptance:* Add cross-component AC-007/AC-008/AC-013/AC-015/AC-019 integration cases composing existing local tests, enumerate all overlays/personas, regenerate final adapters in sandboxes and retain actual suite/ShellCheck platform evidence without treating a local run as the remote matrix.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_invoker_protocol`, `tests/test-spec-gate.sh::test_floor`, `tests/test-spec-gate.sh::test_checkpoints`, `tests/test-verification.sh::test_capture_provenance`, `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-gate-contracts.sh::test_instruction_contracts`, `tests/test-build-adapters.sh::test_brief_modes`, `tests/test-spec-run.sh::test_bounded_capture`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-001, REQ-003, REQ-007, REQ-008, REQ-009, REQ-013, REQ-014, AC-002, AC-007, AC-008, AC-013, AC-014, AC-015, AC-019, FM-002, FM-007, FM-012, FM-013, INV-001, INV-004, plan §5, §7, §8
  - *Notes:* AC-019 needs actual Linux/macOS/Bash-3.2 execution evidence before T031 READY, plus the normal PR CI afterward; if no authorized executor is available, stop implementation and request an execution route rather than inventing a PASS.
  - *Evidence:* CAP-47-pAxlby verified by spec-gate accept; return sha256:c06ea61a688d86e89ae6ea547043ead4d9f156cc729e2d03bd48be5cf5df9fab

- [x] **T030o3** — Require the incomplete-return reason in the live probe
  - *Files:* `scripts/verification-lib.sh`, `tests/probe-gate-contract.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* The AC-016 probe passes only when the rejected control was refused for a missing required FM/INV mapping; forged-summary, wrong-task and stale-capture rejections are typed as different classes and refused as substitutes, while the ordering, unchanged-task-digest and gate-identity checks stay in force.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_invoker_protocol`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, AC-016, FM-018, plan §4.3, §8
  - *Notes:* Owns opponent finding O-003. The accept event already persists a free-text `reason`; add a typed class beside it so the probe discriminates instead of trusting any nonzero exit. Extends T026's checker, so it sits in Tests although the enabling field is kernel-side. The 2026-09-09 live control did reject for the right reason — this turns that from luck into a checked fact.
  - *Evidence:* CAP-94-JMKWcl verified by spec-gate accept; return sha256:ace274951104fdf9904194a2d7d7c7238810c2197ced010ddbc3242c4b38394d

- [x] **T030o8** — Keep mapping rows contiguous and split rejection classes
  - *Files:* `scripts/verification-lib.sh`, `tests/probe-gate-contract.sh`, `tests/test-spec-gate.sh`, `tests/test-gate-contracts.sh`
  - *Acceptance:* The Failure modes section ends only at the first non-blank line that is not a well-formed mapping row, and the parser reports that it ended early instead of silently discarding later rows; an incomplete set after an early end is typed `truncated-envelope` while a genuine missing, extra, duplicate or unknown row stays `binding-mismatch`, the AC-016 probe requires the row-level class, permitted trailing narrative beginning with an `FM-` or `INV-` token is accepted, and the capture arm separates `capture-integrity` from `stale-capture`.
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_acceptance`, `tests/test-gate-contracts.sh::test_invoker_protocol`
  - *Verify:* `bash tests/test-spec-gate.sh && bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, AC-016, AC-022, FM-006, FM-018, plan §4.2, §4.3
  - *Notes:* Owns opponent findings O-003 and O-001 — the report folds O-001 into this fix. Reopened because T030o1 and T030o3 interact: prose between `Failure modes:` and the rows dropped complete rows, rejected as "required Failure modes are missing", and typed `binding-mismatch`, which is the very class the probe requires as proof of the incomplete-copy control. The sealed control ACCEPT-KsToLg keeps `binding-mismatch` because its rows were genuinely removed, not truncated.
  - *Evidence:* CAP-115-sIpzTu verified by spec-gate accept; return sha256:558cdc23ea64f14d304bed4f2fdc1cdffdd9ecbb1d53ec4bbaeeec1ece2ad4b5

- [x] **T031a1** — Cover the acceptance cases reality-check round 2 found without a fixture
  - *Files:* `tests/test-spec-gate.sh`
  - *Acceptance:* In `test_acceptance` (`acceptance_named_cases`), each refused with its named reason and tasks.md byte-identical: a return with no `Failure modes:` block (`incomplete verification return`); `Captures:` naming a capture that does not exist (`capture integrity: missing COMPLETE or linked directory`); a capture of an unrelated explicit command whose log names the test (`do not prove this task Verify`); a capture whose command exited nonzero (`capture failed: exit 5`); a manual return whose artifact is absent (`manual artifact missing or digest mismatch`). A valid acceptance changes only its own checkbox and adds its `*Evidence:*` line (asserted against the expected file), and a task owing no rows is accepted with an explicit `Failure modes: none` (AC-022).
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_acceptance`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-009, AC-022, FM-006, FM-010, INV-002, plan §7
  - *Notes:* Owns reality-check round 2 gap 1 (AC-022). Test files only, no kernel change, as the user decided on 2026-10-15; the cases start from the reviewer's probes (`notes/verification/reports/rc2-review-probes.txt`) and are applied by `notes/verification/reports/r20-edits/apply-code.py`. Under the user's decisions of 2026-10-14 and 2026-10-15 the invoker's extra proof steps (the mutation matrix, two-direction fixture judging, a separate measurement script, repeated dev runs) are not run; one dev run in a standalone copy and the capture of record prove it. T031a1 to T031a4 share one Verify, so one capture on unchanged source can serve all four acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-678-tyxcke verified by spec-gate accept; return sha256:fc2c2d9e195cecfc663eb3551ec637d85f4e575b250697299132713138fe0848

- [x] **T031a2** — Show a changed command executes again and a capture is never reused for another argv
  - *Files:* `tests/test-spec-gate.sh`, `tests/test-verification.sh`
  - *Acceptance:* In `reuse_floor_cases` (called by `test_floor`), changing an opted-in gate_checks command string from `bash tests/check.sh` to `bash ./tests/check.sh` runs the suite again with `cache-hits=0`; in `capture_validity_cases` (called by `test_capture_provenance`), with the inputs unchanged, the floor's reuse path (`vf_gate_execute`, local policy) reuses a passing capture for its own argv and not for another command string that runs the same test (AC-007, AC-020).
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_floor`, `tests/test-verification.sh::test_capture_provenance`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-007, REQ-009, AC-007, AC-020, FM-012, FM-014, INV-001, plan §7
  - *Notes:* Owns reality-check round 2 gap 2 (AC-007, AC-020). Test files only, no kernel change, as the user decided on 2026-10-15; the cases start from the reviewer's probes (`notes/verification/reports/rc2-review-probes.txt`) and are applied by `notes/verification/reports/r20-edits/apply-code.py`. Under the user's decisions of 2026-10-14 and 2026-10-15 the invoker's extra proof steps (the mutation matrix, two-direction fixture judging, a separate measurement script, repeated dev runs) are not run; one dev run in a standalone copy and the capture of record prove it. T031a1 to T031a4 share one Verify, so one capture on unchanged source can serve all four acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-678-tyxcke verified by spec-gate accept; return sha256:fe2d66707ef88d15d384c9a3e1a401256beffdf013c10b48e08c896c3595734f

- [x] **T031a3** — Cover class recurrence across files and root causes and an annotated copy of 002
  - *Files:* `tests/test-gate-contracts.sh`
  - *Acceptance:* In `test_reports_and_tally` (`tally_class_cases`): two findings of one Class at different files with different Root causes count one recurrence; two Classes sharing a file and a Root cause count none; an annotated copy of shipped 002's opponent history (`annotate_002`, its six legacy findings as canonical findings with stable Classes) detects both its clock recurrence and its lock recurrence, while the copy and the shipped notes stay byte-identical (AC-010).
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-015, AC-010, FM-019, INV-006, plan §7
  - *Notes:* Owns reality-check round 2 gap 3 (AC-010). Test files only, no kernel change, as the user decided on 2026-10-15; the cases start from the reviewer's probes (`notes/verification/reports/rc2-review-probes.txt`) and are applied by `notes/verification/reports/r20-edits/apply-code.py`. Under the user's decisions of 2026-10-14 and 2026-10-15 the invoker's extra proof steps (the mutation matrix, two-direction fixture judging, a separate measurement script, repeated dev runs) are not run; one dev run in a standalone copy and the capture of record prove it. T031a1 to T031a4 share one Verify, so one capture on unchanged source can serve all four acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-678-tyxcke verified by spec-gate accept; return sha256:15122b565c95821bd59e65647d26ab6f5c60bb492196a3b96f208e4f8993a430

- [x] **T031a4** — Exercise the explicit reconciliation of a legacy date-only history
  - *Files:* `tests/test-spec-gate.sh`
  - *Acceptance:* In `test_rounds` (`round_legacy_reconcile_cases`): with a copy of shipped 002's date-only opponent history, the next round is refused at exit 4 with `date-only history needs timestamped digest reconciliation` and reserves nothing; `round --reconcile` records an explicit timestamp bound to the history's digest; an exact waiver written after it then authorizes round 6, which reserves on a fresh floor (AC-009).
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, FM-016, INV-004, plan §7
  - *Notes:* Owns reality-check round 2 gap 4 (AC-009). Test files only, no kernel change, as the user decided on 2026-10-15; the cases start from the reviewer's probes (`notes/verification/reports/rc2-review-probes.txt`) and are applied by `notes/verification/reports/r20-edits/apply-code.py`. Under the user's decisions of 2026-10-14 and 2026-10-15 the invoker's extra proof steps (the mutation matrix, two-direction fixture judging, a separate measurement script, repeated dev runs) are not run; one dev run in a standalone copy and the capture of record prove it. T031a1 to T031a4 share one Verify, so one capture on unchanged source can serve all four acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-678-tyxcke verified by spec-gate accept; return sha256:620f33983528672b4aa239fe725b1c852b8a6e6c24940951b7e592f561e575ae

- [x] **T031a1o1** — Refuse an empty Failure modes header for a task owing no rows
  - *Files:* `tests/test-spec-gate.sh`
  - *Acceptance:* In `test_acceptance` (`acceptance_named_cases`), before the explicit-none acceptance, a return for the no-row task T006 with an empty `Failure modes:` header is refused with `empty required set must explicitly be none`, tasks.md byte-identical (AC-022).
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_acceptance`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-006, REQ-009, AC-022, FM-006, FM-010, INV-002, plan §7
  - *Notes:* Repairs O-030 (round 20, minor). Test files only, no kernel change, as the user decided on 2026-10-16; the cases start from opponent round 20's report (`notes/verification/reports/opponent-round20.md`) and `r20-repro-o029.sh`, and are applied by `notes/verification/reports/r21-edits/apply-code.py`. Under the user's decisions of 2026-10-14 to 2026-10-16 the invoker's extra proof steps are not run, except that each new O-029 assertion is shown killed by one of round 20's three mutants in the one dev run. T031a1o1, T031a3o1 and T031a4o1 share one Verify, so one capture on unchanged source can serve all three acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-700-lvBf95 verified by spec-gate accept; return sha256:3fed316e7f5305a0f7fdad9e8967931358383703afbba530a420247b983f2388

- [x] **T031a3o1** — Hash the records the tally reads before and after it
  - *Files:* `tests/test-gate-contracts.sh`
  - *Acceptance:* In `test_reports_and_tally`, every file under each directory `tally` reads is hashed (names and bytes) before and after the run: the copy in `shipped_002_tally_case`, and the synthetic and annotated histories in `tally_class_cases`; the copy check there is labelled as proving only that `copy_kit` is faithful (AC-010).
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-015, AC-010, FM-019, INV-006, plan §7
  - *Notes:* Repairs O-031 (round 20, minor). Test files only, no kernel change, as the user decided on 2026-10-16; the cases start from opponent round 20's report (`notes/verification/reports/opponent-round20.md`) and `r20-repro-o029.sh`, and are applied by `notes/verification/reports/r21-edits/apply-code.py`. Under the user's decisions of 2026-10-14 to 2026-10-16 the invoker's extra proof steps are not run, except that each new O-029 assertion is shown killed by one of round 20's three mutants in the one dev run. T031a1o1, T031a3o1 and T031a4o1 share one Verify, so one capture on unchanged source can serve all three acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-700-lvBf95 verified by spec-gate accept; return sha256:70766114202d7752136868a5eb570d5515314fad951d1a6b6feb8e9132c8f5fc

- [x] **T031a4o1** — Assert the refusals only a reconciled legacy record decides
  - *Files:* `tests/test-spec-gate.sh`
  - *Acceptance:* In `test_rounds` (`round_legacy_reconcile_cases`), on the copy of shipped 002's date-only history: before the valid reconcile, a record naming a wrong digest, a wrong round or a timestamp before the history's date each exits 3, writes no `legacy-time.nul` and leaves the next round refused with `date-only history needs timestamped digest reconciliation`; after it, a waiver dated 2026-07-20T12:00:00Z is refused with `not after the previous round completion at 2026-07-20T23:59:59Z` and the current waiver is authorized; after an edit of the history, with a floor current for it, neither `waiver` nor `round` authorizes or reserves; with the history restored, round 6 reserves. Each new assertion is killed by one of round 20's three mutants (the reconciled timestamp ignored; the reconcile digest and round check removed; all legacy binding removed) (AC-009, REQ-012).
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, FM-016, INV-004, plan §7
  - *Notes:* Repairs O-029 (round 20, blocking). Test files only, no kernel change, as the user decided on 2026-10-16; the cases start from opponent round 20's report (`notes/verification/reports/opponent-round20.md`) and `r20-repro-o029.sh`, and are applied by `notes/verification/reports/r21-edits/apply-code.py`. Under the user's decisions of 2026-10-14 to 2026-10-16 the invoker's extra proof steps are not run, except that each new O-029 assertion is shown killed by one of round 20's three mutants in the one dev run. T031a1o1, T031a3o1 and T031a4o1 share one Verify, so one capture on unchanged source can serve all three acceptances. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-700-lvBf95 verified by spec-gate accept; return sha256:f07ee635f92439f86b44592be3dbad064ebf32f990a49af35750f125fee65cb6

- [x] **T031a4o2** — Reconcile the legacy record to a time no reading of the date yields
  - *Files:* `tests/test-spec-gate.sh`
  - *Acceptance:* In `test_rounds` (`round_legacy_reconcile_cases`), on the copy of shipped 002's date-only history: the valid record is reconciled to 2026-07-21T06:00:00Z, a later day than the history's date, so neither its midnight nor its end of day yields that time; a waiver dated 2026-07-21T05:00:00Z is refused with `not after the previous round completion at 2026-07-21T06:00:00Z`; before the valid record, one stamped 2099-01-01T00:00:00Z exits 3, writes no `legacy-time.nul` and leaves the next round refused with `date-only history needs timestamped digest reconciliation`, like the wrong-digest, wrong-round and before-the-date records. In the one dev run every mutant opponent rounds 20 and 21 ran against these fixtures is killed except the one round 21 held equivalent (the read-path round check alone), and each new assertion is killed by at least one (AC-009, REQ-012).
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, FM-016, INV-004, plan §7
  - *Notes:* Repairs O-029 as round 21 left it open (blocking). Test files only, no kernel change, as the user chose on 2026-10-16 after round 21; the cases follow round 21's report (`notes/verification/reports/opponent-round21.md`) and `r21-repro-o029.sh`, and are applied by `notes/verification/reports/r22-edits/apply-code.py`; the mutants are `r22-edits/mutants-r22.py`. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-722-hO9jDO verified by spec-gate accept; return sha256:a28b333c0671a27659813f0ebbde072ad92bfb4f804a6ec18532b3e698a340a5


- [x] **T031a4o3** — Pin both regions the reconcile guard admits, at non-round times
  - *Files:* `tests/test-spec-gate.sh`
  - *Acceptance:* In `test_rounds` (`round_legacy_reconcile_cases`), on the copy of shipped 002's date-only history: the record is reconciled first on the history's own date to 2026-07-20T15:17:43Z, a waiver dated 15:17:42Z is refused with `not after the previous round completion at 2026-07-20T15:17:43Z` and one dated 15:17:44Z is authorized; then it is reconciled again on a later day to 2026-07-21T06:17:43Z, and a waiver dated 06:17:42Z is refused with `not after the previous round completion at 2026-07-21T06:17:43Z`. Records stamped 2026-07-20T25:00:00Z (an impossible time) and at 23:59:59Z of the current UTC day (later today; skipped in the last minute of the day) each exit 3, write no `legacy-time.nul` and leave the next round refused with `date-only history needs timestamped digest reconciliation`, like the other wrong records. In the one dev run every mutant opponent rounds 20, 21 and 22 ran against these fixtures is killed except the one round 21 held equivalent (the read-path round check alone), and each new assertion is killed by at least one (AC-009, REQ-012).
  - *Verify kind:* test
  - *Tests:* `tests/test-spec-gate.sh::test_rounds`
  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-012, AC-009, FM-016, INV-004, plan §7
  - *Notes:* Repairs O-029 as round 22 left it open (blocking) and O-033 (minor). Test files only, no kernel change, as the user chose on 2026-10-17 after round 22; the cases follow round 22's report (`notes/verification/reports/opponent-round22.md`) and its prototype, and are applied by `notes/verification/reports/r23-edits/apply-code.py`; the mutants are `r23-edits/mutants-r23.py`. No gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-744-sgOYqc verified by spec-gate accept; return sha256:ccb0850adfbb58f0e9ae6a3d1e1ec1b379e22fa37746aceb45ca80f75aa33d0a


- [x] **T031a5** — Exercise both untyped typecheck-warning branches
  - *Files:* `tests/test-sdd-analyze.sh`
  - *Acceptance:* AC-004 fixtures invoke the analyzer with untyped `npm run typecheck` and `tsc --noEmit`, require exit 0 plus the `untyped AC Verify` warning, and retain build/text/shell and explicit test/assertion/static/manual controls.
  - *Verify kind:* test
  - *Tests:* `tests/test-sdd-analyze.sh::test_verification_bindings`
  - *Verify:* `bash tests/test-sdd-analyze.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-005, AC-004, FM-001, INV-005, plan §7
  - *Notes:* Closes reality-check round 3 gap 1 (`notes/verification/reports/reality-check-round3.md`). Test-only coverage of behavior the reviewer found correct; no runtime classifier change. No new gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-767-tGxtxB verified by spec-gate accept; return sha256:e40b2ee4cfe3f5b8421b16561a902d0b3a610a20388f36c0c1cbf4d278b48de8

- [x] **T031a5o1** — Classify untyped AC verification by executable and runner position
  - *Files:* `scripts/sdd-analyze.sh`, `tests/test-sdd-analyze.sh`
  - *Acceptance:* AC-004 fixtures require exit 0 plus the existing untyped AC Verify warning for build/typecheck/text-presence/file-existence commands even when arguments name tests or runners; genuine shell/node/cargo/pytest/bats and package test runners remain clean, and explicit test/assertion/static/manual family controls remain valid.
  - *Verify kind:* test
  - *Tests:* `tests/test-sdd-analyze.sh::test_verification_bindings`
  - *Verify:* `bash tests/test-sdd-analyze.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-005, AC-004, FM-001, INV-005, plan §3.1, §7
  - *Notes:* O-034, opponent round 24, verification-command-classification: repair both shared runner exemption alternatives and their warning consumer; cover the nine reproduced siblings plus search-pattern/path boundaries and genuine runners with weak-looking argument filenames. O-032 remains open. No gate/floor/hosted-CI execution or new opponent authorization is part of this task.
  - *Evidence:* CAP-791-DfeS6O verified by spec-gate accept; return sha256:1db01df45ea2f2071a5c5f057f9e8ff8c1eca4f54c21423056becc6e34331d2f

- [x] **T031a6** — Invalidate saved success and carried PASS on real input revisions
  - *Files:* `tests/test-gate-contracts.sh`, `.specify/specs/003-gate-round-reduction-and-token-discipline/plan.md`
  - *Acceptance:* AC-013/AC-020 fixtures first capture a genuinely passing check that reaches a transitive helper through implementation and consumes fixture/configuration/locked-dependency inputs. Independently mutate implementation, helper, fixture, lock, configuration and actual referenced spec AC text; reject old capture current/reuse and saved/carried PASS while its old log stays byte-identical, then restore each input and require success. Retain existing matrix omissions, unknown impact, verdict and digest-corruption controls; assign actual saved-PASS coverage to the reports family.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-013, AC-020, FM-005, FM-010, FM-020, INV-001, INV-005, plan §7
  - *Notes:* Closes reality-check round 3 gap 2 (`notes/verification/reports/reality-check-round3.md`). Adds shipped regression proof for runtime paths already checked by the reviewer; no kernel or O-032 recovery change. No new gate round, floor or hosted-CI run is part of this task.
  - *Evidence:* CAP-768-sy4sk5 verified by spec-gate accept; return sha256:7c21e5a69566b6149b058324bb8f306b8878995db80e32065e6f407a8857d690

## Observability

- [x] **T028** — Record cost and quality without invented savings
  - *Files:* `templates/retro-template.md`, `skills/sdd-retro/SKILL.md`, `tests/test-gate-contracts.sh` (new in T001)
  - *Acceptance:* Add AC-017 assertions for stable class versus process root cause, raw sites/reopened findings, actual-or-unknown usage/baselines, execution/reuse/byte counts and a named 14-day observation owner/check-back.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`, `tests/test-gate-contracts.sh::test_reports_and_tally`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-001, REQ-015, AC-017, FM-019, FM-020, INV-006, plan §8
  - *Evidence:* CAP-72-DRCsRw verified by spec-gate accept; return sha256:d20cfbec2e79468a9360cef9f48b6761a8d5e7b04e2e636876e29eb1b49a8821

## Docs

- [x] **T029** — Document and exercise the public verification workflow
  - *Files:* `README.md`, `constitution.md`, `templates/verification-contract.md` (new in T001), `tests/test-gate-contracts.sh` (new in T001), `scripts/spec-evidence.sh`, `scripts/spec-ac-coverage.sh`
  - *Acceptance:* Add AC-018 fixtures that execute documented examples and all five help entries, explain compatibility/freshness/no-tick/summary/class/scope/cap rules, and preserve models, separate gates and security-review authority.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `bash tests/test-gate-contracts.sh` → all suites `passed`, exit 0
  - *Reuse:* local
  - *Refs:* REQ-001, REQ-007, REQ-008, REQ-009, REQ-010, REQ-011, REQ-012, REQ-015, REQ-016, AC-018, FM-001, INV-005, plan §3, §4, §8
  - *Notes:* For AC-016's real control, the invoker rejects one deliberately incomplete copy of this worker's no-tick return, records unchanged task digests, then accepts the intact original; an intentional control is not a failed worker retry. Executing the published example found two defects it had to fix to run at all: a `return.txt` written into the worktree changed the input manifest and made its own fresh capture stale (returns and reports now live under `notes/verification/`), and `spec-evidence.sh`/`spec-ac-coverage.sh` overwrote a caller-exported `$SPEC`, so a reader following the documented variable names got "current evidence missing/stale" on valid proof. Both were reproduced before the fix.
  - *Evidence:* CAP-769-bZPhmg verified by spec-gate accept; return sha256:dc47e2239dc84dc47a2b080f18660c8fcde667c190c937309646049d64e48b9c

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
