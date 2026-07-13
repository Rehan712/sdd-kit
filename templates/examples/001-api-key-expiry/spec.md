---
spec_id: 001-api-key-expiry
title: API keys expire 90 days after issue
status: accepted
created: 2026-07-10
updated: 2026-07-10
owners: [example-owner]
project: acme-api
---

# API keys expire 90 days after issue

> Long-lived API keys never die: a leaked key works forever. This spec adds a
> 90-day expiry to every key, returns `expires_at` at issue time, and rejects
> expired keys with a distinct, documented error.

## 1. Problem

Today `POST /api/keys` issues keys with no expiry. A key created in 2024 and
leaked in a customer's CI logs still authenticates today; we found three such
keys during the last audit and had no mechanism besides manual deletion.

**REQ-001:** A leaked or forgotten API key remains valid forever; keys must
stop working 90 days after issue.

## 2. Goals

- **REQ-002:** Every newly issued key carries an expiry 90 days from issue,
  returned to the caller at creation time.
- **REQ-003:** Requests with an expired key are rejected with a distinct,
  documented error the caller can act on (rotate) without debugging.

## 3. Non-goals

- Key rotation/renewal endpoints (future spec — see §9)
- Configurable expiry windows per customer
- A revocation UI (keys can already be deleted via the existing endpoint)

## 4. Success metrics

- **MET-001:** 0 authenticated requests with keys older than 90 days, 14 days
  post-launch — CloudWatch metrics `auth.key_expired_rejects` vs `auth.key_ok`.

## 5. User stories

### As an API consumer

- I can see `expires_at` when I create a key so that I can schedule rotation.
- I get a clear `401 key_expired` error so that I know to issue a new key
  instead of debugging my payload.

### As a security engineer

- I can verify no key outlives 90 days so that a leaked key has a bounded
  blast radius.

## 6. Acceptance criteria

- [ ] **AC-001:** `POST /api/keys` returns 201 with `{token, expires_at}`
  where `expires_at` is exactly 90 days after issue (proves REQ-002) —
  `bun test --filter keys.issue`.
- [ ] **AC-002:** A request with an expired key returns
  `401 {"error":"key_expired"}` and never reaches the handler (proves
  REQ-001, REQ-003) — `bun test --filter keys.expired`.
- [ ] **AC-003:** A request with a valid, unexpired key still authenticates —
  no regression (proves REQ-001's guard cuts nothing else) —
  `bun test test/keys.expiry.test.ts` (the suite's valid-key control case).
- [ ] **AC-004:** `[DEPLOY]` The `auth.key_expired_rejects` metric is visible
  in CloudWatch within 24h of the flag flip — evidence is a screenshot
  committed to `notes/`, with owner + check-back date in STATUS.

## 7. Constraints

- **CON-001:** The `api_keys` DynamoDB table cannot be re-created; expiry
  lands as a new attribute plus a backfill, never a new table.

## 8. Open questions

(none — resolved during the interview; see STATUS Decisions)

## 9. References

- Related spec: `.specify/specs/000-api-key-crud/spec.md` (the original issue flow)
- Future: key renewal endpoint (`002-api-key-renewal` candidate)
