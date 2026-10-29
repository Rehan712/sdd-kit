---
tasks_for: 001-api-key-expiry
status: draft
created: 2026-07-10
updated: 2026-07-10
---

# Tasks: API keys expire 90 days after issue

> Dependency-ordered checklist. Each task is small enough to be a single commit
> and has an explicit acceptance check.

## Setup

- [ ] **T001** — Add KEY_TTL_DAYS and expiresAt to KeyRecord
  - *Files:* `src/keys/types.ts`, `test/keys.expiry.test.ts`
  - *Acceptance:* Add the keys.ttl test for the exported 90-day constant and expiry record shape (plan §4 seam); typecheck remains a required static gate.
  - *Verify kind:* test
  - *Tests:* `test/keys.expiry.test.ts::keys.ttl`
  - *Verify:* `bun test --filter keys.ttl` → all tests pass
  - *Refs:* REQ-002, AC-001, plan §4

## Backend

- [ ] **T002** — Stamp expires_at at key issue
  - *Files:* `src/keys/issue.ts`, `schemas/keys.ts`, `test/keys.expiry.test.ts`
  - *Acceptance:* Extend keys.issue frozen-clock/schema tests alongside the handler: 201 with expires_at exactly issue + 90d, including a month boundary (plan §6).
  - *Verify kind:* test
  - *Tests:* `test/keys.expiry.test.ts::keys.issue`
  - *Verify:* `bun test --filter keys.issue` → "2 pass"
  - *Refs:* REQ-002, AC-001, FM-001, plan §2, §7
  - *Integration owner:* T005

- [ ] **T003** [hard] — Reject expired keys in auth middleware
  - *Files:* `src/middleware/auth.ts`, `test/keys.expiry.test.ts`
  - *Acceptance:* Extend keys.expired tests in this commit: reject before dispatch, revoked-and-expired keeps key_revoked precedence, equality is expired and valid keys dispatch (plan §4, §7).
  - *Verify kind:* test
  - *Tests:* `test/keys.expiry.test.ts::keys.expired`
  - *Verify:* `bun test --filter keys.expired` → "3 pass" (expired + boundary + valid-control)
  - *Refs:* REQ-001, REQ-003, AC-002, AC-003, FM-002, FM-004, INV-001, plan §2, §7
  - *Integration owner:* T005

- [ ] **T004** [P] — Backfill script for existing keys
  - *Files:* `scripts/backfill-key-expiry.ts`, `test/backfill-key-expiry.test.ts`
  - *Acceptance:* Add seeded-table backfill.expiry tests for missing attributes and repeated partial runs preserving existing timestamps; retain --dry-run (CON-001).
  - *Verify kind:* test
  - *Tests:* `test/backfill-key-expiry.test.ts::backfill.expiry`
  - *Verify:* `bun test --filter backfill.expiry` → all tests pass
  - *Refs:* REQ-001, AC-002, FM-003, INV-002, plan §3, §7

## Tests

- [ ] **T005** — Integrate issue and auth expiry contracts
  - *Files:* `test/keys.expiry.integration.test.ts`
  - *Acceptance:* Compose issue → authenticate → expire with the existing frozen clock; integration titles name AC-001/002/003. Local behavior tests already landed with T001–T004.
  - *Verify kind:* test
  - *Tests:* `test/keys.expiry.integration.test.ts::keys.expiry.integration`
  - *Verify:* `bun test test/keys.expiry.integration.test.ts` → all tests pass
  - *Refs:* AC-001, AC-002, AC-003, FM-004, INV-001, plan §7

## Observability

- [ ] **T006** — Emit auth.key_expired_rejects metric
  - *Files:* `src/metrics.ts`, `src/middleware/auth.ts`, `test/metrics.expiry.test.ts`
  - *Acceptance:* Add metrics.expired assertions alongside the counter for every expired-key reject; the live CloudWatch observation remains AC-004's separate [DEPLOY] half, owned by T011.
  - *Verify kind:* test
  - *Tests:* `test/metrics.expiry.test.ts::metrics.expired`
  - *Verify:* `bun test --filter metrics.expired` → "1 pass"
  - *Refs:* AC-004, plan §8

## Docs

- [ ] **T007** — Document key_expired error and expires_at field
  - *Files:* `docs/api.md`, `test/docs-key-expiry.sh`
  - *Acceptance:* Add assert_documented_curl with the docs: both fields are next to key_revoked and the documented curl runs against the seeded local server, asserting the exact 401 body.
  - *Verify kind:* assertion
  - *Tests:* `test/docs-key-expiry.sh::assert_documented_curl`
  - *Verify:* `bash test/docs-key-expiry.sh` → documented response assertions pass
  - *Refs:* REQ-003, AC-002

## Reality Check (pre-ship gate)

- [ ] **T008** — Opponent review: steelman why this implementation is wrong
  - *Agent:* `~/.sdd/agents/opponent.agent.md`
  - *Inputs:* the diff on this branch, `spec.md`, `plan.md`, every `[x]` task
  - *Acceptance:* agent returns **CLEARED** (not CHALLENGED); findings written to `notes/opponent.md`
  - *Refs:* REQ-001, REQ-002, REQ-003, AC-001, AC-002, AC-003, AC-004
  - *On CHALLENGED:* open follow-up tasks here (T008o1, T008o2, …) for each defect; fix and re-run before T009

- [ ] **T009** — Reality-check the implemented spec end-to-end
  - *Agent:* `~/.sdd/agents/reality-check.agent.md`
  - *Inputs:* every prior `[x]` task, `spec.md`, `plan.md`, `notes/opponent.md`
  - *Acceptance:* agent returns **READY** (not NEEDS WORK / FAILED); all AC-### mapped to concrete evidence in `notes/reality-check.md`
  - *Refs:* AC-001, AC-002, AC-003, AC-004
  - *On NEEDS WORK:* open follow-up tasks here (T009a1, T009a2, …); do not proceed to Ship until they're `[x]` and the gate is re-run

## Ship

- [ ] **T010** — Open PR to the base branch referencing spec.md and plan.md
  - *Files:* (none — branch + PR)
  - *Acceptance:* `~/.sdd/scripts/spec-pr.sh <spec-dir>` prints the PR URL; both gate verdicts in the PR body; reviewer requested

- [ ] **T011** — Roll out (after /sdd:review reports the PR merged)
  - *Acceptance:* backfill run before flag flip (plan §8 order); `enforce_key_expiry` on; `auth.key_expired_rejects` visible in CloudWatch within 24h — screenshot committed to `notes/` closing AC-004, owner + check-back date in STATUS; phase set to `shipped`

- [ ] **T012** — Retro: harvest lessons into the hub
  - *Acceptance:* `/sdd:retro` run; `notes/retro.md` written with the root-cause split; STATUS `retro:` set to `done`
