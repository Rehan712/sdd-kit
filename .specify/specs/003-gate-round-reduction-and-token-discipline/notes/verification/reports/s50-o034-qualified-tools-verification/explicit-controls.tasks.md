---
tasks_for: 003-verification-fixture
status: draft
---
# Tasks: Verification fixture

## Backend

- [ ] **T001** — Cover the shared shell boundary
  - *Files:* `src/parser.sh`, `tests/check.sh`
  - *Acceptance:* Add and pass the shared boundary shell test.
  - *Verify kind:* test
  - *Tests:* `tests/check.sh::test_ac_001_shared`
  - *Verify:* `bash tests/check.sh` → passed
  - *Reuse:* local
  - *Refs:* REQ-001, AC-001, FM-001
  - *Integration owner:* T005

- [ ] **T002** — Cover the shared custom assertion
  - *Files:* `src/runner.sh`, `scripts/check-contract.sh`
  - *Acceptance:* Add and pass the custom behavioral assertion.
  - *Verify kind:* assertion
  - *Tests:* `scripts/check-contract.sh::assert_ac_002_contract`
  - *Verify:* `bash scripts/check-contract.sh` → passed
  - *Refs:* REQ-002, AC-002, FM-001
  - *Integration owner:* T005

## Docs

- [ ] **T003** — Check the static schema
  - *Files:* `docs/schema.md`, `tests/static.sh`
  - *Acceptance:* Add and pass the static documentation schema check.
  - *Verify kind:* static
  - *Tests:* `tests/static.sh::test_ac_003_schema`
  - *Verify:* `bash tests/static.sh` → passed
  - *Refs:* REQ-003, AC-003, FM-002

- [ ] **T004** — Observe the release artifact
  - *Files:* `artifacts/release.txt`
  - *Acceptance:* Record the observer and digest for the release artifact.
  - *Verify kind:* manual
  - *Tests:* release-observation
  - *Verify:* `manual: inspect the release artifact and record its digest`
  - *Refs:* REQ-004, AC-004, INV-001

## Tests

- [ ] **T005** — Compose the cross-task integration
  - *Files:* `tests/integration.sh`
  - *Acceptance:* Add and pass the parser/runner integration test.
  - *Verify kind:* test
  - *Tests:* `tests/integration.sh::test_ac_001_002_integration`
  - *Verify:* `bash tests/integration.sh` → passed
  - *Refs:* REQ-001, REQ-002, AC-001, AC-002

## Reality Check (pre-ship gate)

- [ ] **T009** — Opponent review
  - *Agent:* agents/opponent.agent.md
  - *Acceptance:* agent returns CLEARED
  - *Refs:* AC-001, AC-002, AC-003, AC-004

- [ ] **T010** — Reality-check
  - *Agent:* agents/reality-check.agent.md
  - *Acceptance:* agent returns READY
  - *Refs:* AC-001, AC-002, AC-003, AC-004

## Ship

- [ ] **T011** — Open the PR
  - *Acceptance:* PR URL recorded
