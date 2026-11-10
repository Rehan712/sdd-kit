---
plan_for: 001-api-key-expiry
status: accepted
created: 2026-07-10
updated: 2026-07-10
stacks: [javascript, aws]
---

# Plan: API keys expire 90 days after issue

> The implementation strategy for `spec.md`. Answers **how**, not what.

## 1. Approach

Stamp `expires_at` at issue time (REQ-002) rather than running a sweeper job:
the auth middleware already loads the key record on every request, so expiry
enforcement is a single comparison there (REQ-001, REQ-003). Existing keys get
a backfilled expiry 90 days from ship (CON-001). No new infrastructure; one
new metric feeds MET-001.

## 2. Architecture

| File | Change | Why | Pattern anchor |
|---|---|---|---|
| `src/keys/types.ts` | modified | `KeyRecord` gains `expiresAt`; export `KEY_TTL_DAYS = 90` | n/a — one-type edit in place |
| `src/keys/issue.ts` | modified | stamp `expiresAt` on create (REQ-002) | extend `buildKeyRecord()` in place — keep its field order |
| `src/middleware/auth.ts` | modified | reject expired keys before handler dispatch (REQ-001) | the `key_revoked` branch in the same file (`auth.ts:41`) — same shape: check → metric → 401 with error code |
| `src/metrics.ts` | modified | new counter `auth.key_expired_rejects` | `auth.key_revoked_rejects` two lines above — copy the declaration style |
| `scripts/backfill-key-expiry.ts` | new | one-time backfill for existing rows (CON-001) | `scripts/backfill-key-scopes.ts` — same table-scan + batch-write + `--dry-run` shape |
| `test/keys.expiry.test.ts` | new | proves AC-001/002/003 | `test/keys.revoke.test.ts` — same fixture + frozen-clock pattern; reuse its `withFrozenClock` helper |

## 3. Data model

`api_keys` table: new attribute `expires_at` (ISO-8601 string, always present
on new rows). Migration: the backfill script sets
`expires_at = <ship date> + 90d` on every row missing it. No index change —
expiry is checked on the already-fetched record, never queried by.

## 4. API / contracts

- `POST /api/keys` response gains `expires_at` (additive — no version bump).
- New error: `401 {"error":"key_expired"}` — documented in `docs/api.md` next
  to `key_revoked`.
- No other public API changes.

### Internal seams (pre-decided)

- `src/keys/types.ts`: `KeyRecord` gains `expiresAt: string`;
  `export const KEY_TTL_DAYS = 90` lives here — imported by `issue.ts` AND the
  tests; never a second literal `90` anywhere.
- `src/keys/issue.ts`: `buildKeyRecord(owner: string, now: Date): KeyRecord`
  keeps its signature; it computes `expiresAt` from `now` + `KEY_TTL_DAYS`.
- `src/middleware/auth.ts`:
  `export function isExpired(record: KeyRecord, now: Date): boolean` — pure,
  exported for the tests; the middleware calls it AFTER the revoked check
  (revoked wins when both are true — that ordering is behavior, test it).
- Tests import `withFrozenClock` from `test/helpers/clock.ts` — do not add a
  second clock mock.

## 5. Dependencies

None new. No IAM changes — the metric uses the existing `PutMetricData` grant.

## 6. Stack overlay notes

- `javascript`: the zod schema for the issue response
  (`schemas/keys.ts`) gains `expires_at`, or the contract test fails on the
  extra field. Update schema and handler in the same task.
- `aws`: metric name follows the existing `auth.*` namespace — no new
  dashboard; the alarm lands with the Observability task.

## 7. Risks, failure modes and verification

- **R1:** Backfill misses rows written between scan and deploy —
  *Mitigation:* after the 48h flag window, the middleware treats a missing
  `expires_at` as expired (fail closed); the flag covers the gap (see §8).
- **R2:** Boundary off-by-one at exactly 90 days — *Mitigation:* single
  comparison site (`isExpired`), server time only; the AC-002 test includes
  the `now == expires_at` boundary case (expired at, not after).

Use the shared [verification contract](../../verification-contract.md).
Families below are planned declarations; the behavior task creates or extends
their tests before acceptance. Planning does not assign future task IDs.

| ID | Components | Category | Trigger | Decided behavior | Test families |
|---|---|---|---|---|---|
| FM-001 | issue, response schema | boundary | Issue at a frozen server time across a month boundary | Return exactly KEY_TTL_DAYS after issue and retain the response schema | issue |
| FM-002 | auth, handler | concurrency/ordering | Key is revoked and expired, or now equals expires_at | Revoked wins; equality is expired; reject before dispatch | expiry |
| FM-003 | backfill, auth | partial failure | Backfill retries a partially updated table | Fill missing expiry only; preserve existing timestamps | backfill |
| FM-004 | auth | regression | Unexpired valid key reaches the new guard | Preserve authentication and dispatch | expiry, integration |

| ID | Scope | Promise | Enforcement sites | Test families |
|---|---|---|---|---|
| INV-001 | auth, handler | Never dispatch an expired key when enforcement is enabled | Shared isExpired guard after revocation check | expiry, integration |
| INV-002 | backfill | Never replace an existing expires_at | Conditional missing-attribute update in the backfill writer | backfill |

Exclusions: response schema / concurrency/ordering — synchronous shape
validation has no shared state; docs / partial failure — documentation assertions
make no persistent writes. Shared auth/handler cases use the same rows; existing
storage-failure handling is unchanged and remains covered by the CRUD suite.

| Family | Kind | Criteria | Concrete locators |
|---|---|---|---|
| ttl | test | AC-001 | `test/keys.expiry.test.ts::keys.ttl` |
| issue | test | AC-001 | `test/keys.expiry.test.ts::keys.issue` |
| expiry | test | AC-002, AC-003 | `test/keys.expiry.test.ts::keys.expired` |
| backfill | test | AC-002 | `test/backfill-key-expiry.test.ts::backfill.expiry` |
| integration | test | AC-001, AC-002, AC-003 | `test/keys.expiry.integration.test.ts::keys.expiry.integration` |
| metric | test | AC-004: local emission only; CloudWatch observation remains manual | `test/metrics.expiry.test.ts::metrics.expired` |
| documentation | assertion | AC-002: documented curl response | `test/docs-key-expiry.sh::assert_documented_curl` |

The local metric family proves emission, not CloudWatch delivery. The separate
deploy observation is `cloudwatch-expiry-dashboard`, backed by the real screenshot,
observer and timestamp described in AC-004; rollout owns that manual evidence.
The illustrative project declares `bun test` and `bun run typecheck` as required
gate_checks. Optional Backend checkpoints run `bun test`; they do not replace
the gate list. The golden fixture supplies that project configuration in its
sandbox; it never runs a fictional API or claims deployment evidence.

## 8. Rollout

- Order: backfill script runs BEFORE the middleware change is flag-flipped (CON-001).
- Flag `enforce_key_expiry`, default off → on after backfill verified; kill
  switch for the first 48h.
- Observability: `auth.key_expired_rejects` counter (MET-001's source); alarm
  if rejects exceed 5% of auth traffic in the first 24h.
- Reversible: flag off restores old behavior; the `expires_at` attribute is
  inert when unread.

## 9. Out of scope (deferred)

- Key renewal endpoint (`002-api-key-renewal` candidate)
- Per-customer TTL configuration

## 10. References

- Related code: `src/middleware/auth.ts`, `src/keys/`, `schemas/keys.ts`
- ADRs: none — an additive attribute is not a hard-to-reverse decision.
