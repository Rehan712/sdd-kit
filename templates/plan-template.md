---
plan_for: NNN-slug
status: draft  # draft | accepted | implementing | shipped
created: YYYY-MM-DD
updated: YYYY-MM-DD
stacks: [<from project stack.yml>]
---

# Plan: <Spec Title>

> The implementation strategy for `spec.md`. Answers **how**, not what.

## 1. Approach

One paragraph. The shape of the solution and why it's the right one. Reference the spec's REQ-### that motivated each decision.

## 2. Architecture

A diagram (ASCII or mermaid) or a tight bullet list of components. For each touched component, name:

- The file path or module
- What's changing (new / modified / deleted)
- Why

## 3. Data model

New or changed schemas, types, database tables, S3 prefixes, queue messages. Include:

- Field names + types
- Indexes (if relevant)
- Migration strategy (if changing existing data)

## 4. API / contracts

External contracts that change:

- New endpoints (method, path, request shape, response shape, error codes)
- Modified endpoints (what's compatible, what's breaking)
- Event payloads (SNS topics, Kinesis records, EventBridge events)
- Client/SDK changes

If the contract is stable, say so explicitly: "No public API changes."

## 5. Dependencies

- New packages / crates / lambda layers
- Version pins or constraints
- New AWS resources (Lambdas, tables, queues, buckets) — name them
- IAM permissions added (be specific: action + resource)

## 6. Stack overlay notes

For each stack tag, anything stack-specific worth calling out. The hub's `templates/stack-overlays/<tag>.md` should be read alongside this plan during implementation.

- `<stack-tag>`: ...

## 7. Risks

What could go wrong, ranked roughly by likelihood × impact. For each, a mitigation.

- **R1:** ... — *Mitigation:* ...
- **R2:** ...

## 8. Rollout

How this ships. Choose what applies:

- Feature flag (name, default off, who controls)
- Deploy order (e.g., backend before frontend)
- Backfills (one-time scripts, online migrations)
- Reversibility (can we roll back without data loss?)
- Observability added (new metrics, dashboards, alarms)
- Success-metric wiring (how each MET-### from the spec gets measured — metric/dashboard/query names)

## 9. Out of scope (deferred)

Things that came up but won't land in this PR. Capture as future spec slugs or TODOs.

- ...

## 10. References

- ADRs created/touched: `docs/adr/NNN-*.md`
- Related code: `<paths>`
- External docs: `<links>`

---

*Workflow:* Once this plan is accepted, run `/sdd:tasks` to produce `tasks.md`.
