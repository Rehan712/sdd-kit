---
spec_id: NNN-slug
title: <One-line title>
status: draft  # draft | accepted | implementing | shipped | rejected
created: YYYY-MM-DD
updated: YYYY-MM-DD
owners: [<github-handle>]
project: <project-name from registry.yml>
---

# <Title>

> One-paragraph elevator pitch. What's changing and for whom?

## 1. Problem

What's broken, missing, or painful **today**. Write it from the user's perspective, not the system's. Include the smallest concrete example you can.

**REQ-001:** State the user-observable problem in one sentence.

## 2. Goals

Bullet list. Each goal is testable. Prefix with REQ-### so plan.md and tasks.md can reference them.

- **REQ-002:** ...
- **REQ-003:** ...

## 3. Non-goals

What this spec explicitly does **not** address. Future work, related-but-separate features, edge cases punted to v2. Be generous here — it's how scope creep gets prevented.

- ...

## 4. Success metrics

How we'll know this worked **after** it ships — product outcomes, not implementation
facts. Each metric names its measurement source (metric name, dashboard, query).
For pure refactors / internal work, write "n/a" and say why.

- **MET-001:** <target + how measured, e.g. "signup conversion ≥ 5% — analytics event `signup_completed`, 14 days post-launch">
- **MET-002:** ...

## 5. User stories

For each role that interacts with the change:

### As a <role>

- I can <action> so that <outcome>.
- I can ...

Include the "unhappy" paths too — errors, network failures, permission denials.

## 6. Acceptance criteria

Concrete, testable. Each AC names the command or observable artifact that will
verify it (a test, a curl, a screenshot, a metric) — an AC nobody can check is
an opinion, not a criterion. The feature is done when:

- [ ] **AC-001:** <observable behavior, including the exact UI text / API response shape / metric>
- [ ] **AC-002:** ...

Reference REQ-### where the acceptance proves the requirement. The test that
proves an AC **names the AC id in its title/description** (e.g.
`it('AC-001: returns 201', …)`) — that's what binds a passing test to the
criterion; `spec-ac-coverage.sh` checks the binding at the code layer.

## 7. Constraints

What we **cannot** change or must accommodate. Examples: external API rate limits, regulatory requirements, an existing schema we can't migrate yet, budget caps, deadline.

- **CON-001:** ...

## 8. Open questions

Questions that block progress. List with who can answer.

Anywhere in this spec where a decision is genuinely unresolved, write
`[NEEDS CLARIFICATION: <the question>]` inline instead of guessing — and mirror
it here. `sdd-analyze.sh` refuses to let a spec through to tasking while any
marker remains.

- [ ] (@<handle>) ...

## 9. References

- Linked spec/PRD docs, Linear/Jira tickets, design mocks, Slack threads
- Related ADRs: `docs/adr/NNN-*.md`
- Related specs in this project: `.specify/specs/NNN-*/spec.md`

---

*Workflow:* Once this spec is accepted, run `/sdd:plan` to produce `plan.md` in this same directory.
