---
plan_for: NNN-slug
status: draft  # draft | accepted | implementing | shipped
created: YYYY-MM-DD
updated: YYYY-MM-DD
stacks: [<from project stack.yml>]
---

# Plan: <Spec Title>

> The implementation strategy for `spec.md`. Answers **how**, not what.
>
> **Write for the implementation tier.** This plan may be executed by a smaller,
> cheaper model than the one writing it. Spend words exactly where a mid-tier
> implementer would go wrong — the gotcha, the edge case, the pattern anchor,
> the pre-decided signature — and nowhere else. Vague plans produce vague code;
> bloated plans get skimmed.

## 1. Approach

One paragraph. The shape of the solution and why it's the right one. Reference the spec's REQ-### that motivated each decision.

## 2. Architecture

A diagram (ASCII or mermaid) or a tight bullet list of components. For each touched component, name:

- The file path or module
- What's changing (new / modified / deleted)
- Why
- **Pattern anchor** — the existing file to mimic (e.g. "like
  `src/handlers/refund.ts`: same validation → call → metric → response shape").
  Every NEW file names one; a file with no precedent says so explicitly
  ("no precedent — conventions defined here") so the implementer knows it is
  setting a pattern, not missing one. Anchors turn design work into
  transcription work — they are the highest-leverage line in this plan.

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

### Internal seams (pre-decided)

The signatures at task boundaries — decided **here**, not negotiated during
implementation. When two tasks meet at a function, type, or module (one task
implements it, another calls or tests it), write the seam down:

- Function signatures: name, parameters, return type
- Type/schema names and their fields
- Module boundaries: which file exports what, shared constants by name

Different implementer sessions must transcribe these, never re-derive them —
the seam is where independently-implemented tasks drift apart. If a seam turns
out wrong mid-implement, fix it here first (spec > plan > tasks), then continue.

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
