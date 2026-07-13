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
  - *Files:* `src/keys/types.ts`
  - *Acceptance:* `KeyRecord` has `expiresAt: string`; `KEY_TTL_DAYS = 90` exported (plan §4 seam — the only literal 90)
  - *Verify:* `bun run typecheck` → "0 errors"
  - *Refs:* REQ-002, plan §4

## Backend

- [ ] **T002** — Stamp expires_at at key issue
  - *Files:* `src/keys/issue.ts`, `schemas/keys.ts`
  - *Acceptance:* `POST /api/keys` returns 201 with `expires_at` = issue + 90d; zod schema updated in the same commit (plan §6)
  - *Verify:* `bun test --filter keys.issue` → "2 pass"
  - *Refs:* REQ-002, AC-001, plan §2

- [ ] **T003** [hard] — Reject expired keys in auth middleware
  - *Files:* `src/middleware/auth.ts`
  - *Acceptance:* expired key → `401 {"error":"key_expired"}` before handler dispatch; revoked-AND-expired → `key_revoked` wins (plan §4 seam ordering); valid keys unaffected; boundary `now == expires_at` counts as expired (plan R2)
  - *Verify:* `bun test --filter keys.expired` → "3 pass"
  - *Refs:* REQ-001, REQ-003, AC-002, AC-003, plan §2

- [ ] **T004** [P] — Backfill script for existing keys
  - *Files:* `scripts/backfill-key-expiry.ts`
  - *Acceptance:* dry-run against a seeded local table sets `expires_at` on every row missing it and touches nothing else (CON-001)
  - *Verify:* `bun scripts/backfill-key-expiry.ts --dry-run --table local` → "0 skipped"
  - *Refs:* REQ-001, plan §3

## Tests

- [ ] **T005** — Expiry test suite binding the ACs
  - *Files:* `test/keys.expiry.test.ts`
  - *Acceptance:* tests name AC-001, AC-002, AC-003 in their titles (spec-ac-coverage.sh checks the binding); frozen clock via the existing `withFrozenClock` helper (plan §4 seam)
  - *Verify:* `bun test test/keys.expiry.test.ts` → "6 pass"
  - *Refs:* AC-001, AC-002, AC-003

## Observability

- [ ] **T006** — Emit auth.key_expired_rejects metric
  - *Files:* `src/metrics.ts`, `src/middleware/auth.ts`
  - *Acceptance:* counter increments on every expired-key reject; a unit test asserts the emit; the live CloudWatch metric is AC-004's [DEPLOY] half, owned by T011
  - *Verify:* `bun test --filter metrics.expired` → "1 pass"
  - *Refs:* AC-004, plan §8

## Docs

- [ ] **T007** — Document key_expired error and expires_at field
  - *Files:* `docs/api.md`
  - *Acceptance:* both documented next to `key_revoked`; the doc's curl example runs as written
  - *Verify:* `manual: paste the doc's curl against the local server — the 401 body matches the doc verbatim`
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
