---
spec: 001-test-feature
project: proj
---
# Spec: Test feature

## Goals

- REQ-001 — store the thing durably

## Success metrics

- MET-001 — p95 write latency under 100ms

## Acceptance criteria

- AC-001 — POST /thing returns 201 and persists the payload
- AC-002 — an invalid payload returns 400 with an error body
