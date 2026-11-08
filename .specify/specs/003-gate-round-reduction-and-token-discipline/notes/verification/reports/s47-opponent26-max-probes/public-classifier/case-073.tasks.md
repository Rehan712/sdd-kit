---
tasks_for: 001-test-feature
status: in-progress
created: 2026-01-01
updated: 2026-01-01
---
# Tasks: Test feature

## Setup

- [ ] **T001** — Add scaffolding
  - *Files:* `src/`
  - *Acceptance:* build succeeds
  - *Verify:* `npm run build` → "built"

## Backend

- [ ] **T002** — Implement the thing endpoint
  - *Files:* `src/thing.js`
  - *Acceptance:* unit test passes
  - *Verify:* `npm run>out.txt test -- --grep typecheck` → "pass 1"
  - *Refs:* REQ-001, AC-001

- [ ] **T003** — Validate payloads
  - *Files:* `src/validate.js`
  - *Acceptance:* invalid-payload test passes
  - *Verify:* `node --test test/validate.test.js` → "pass 2"
  - *Refs:* AC-002

## Reality Check (pre-ship gate)

- [ ] **T009** — Opponent review: steelman why this implementation is wrong
  - *Agent:* agents/opponent.agent.md
  - *Acceptance:* agent returns **CLEARED**
  - *Refs:* AC-001, AC-002

- [ ] **T010** — Reality-check the implemented spec end-to-end
  - *Agent:* agents/reality-check.agent.md
  - *Acceptance:* agent returns **READY**
  - *Refs:* AC-001, AC-002

## Ship

- [ ] **T011** — Open PR to the base branch
  - *Acceptance:* spec-pr.sh prints the PR URL
