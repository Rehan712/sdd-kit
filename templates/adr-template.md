---
adr_id: NNN
title: <Decision title>
status: proposed  # proposed | accepted | superseded | deprecated
created: YYYY-MM-DD
updated: YYYY-MM-DD
deciders: [<github-handle>]
superseded_by: ~  # NNN of newer ADR if this one is replaced
---

# ADR-NNN: <Title>

> One-line summary of the decision.

## Context

What's the problem we're solving? Why does it need a decision now (as opposed to being deferred)? Include constraints that shape the option space.

## Decision

What we're going to do, stated as a clear directive. Active voice. One paragraph.
Name the single criterion that decided it ("We will use X because <criterion>") —
a Decision that only summarizes what was considered is a Context section in disguise.

## Options considered

### Option A: <name> — chosen

- **How it works:** ...
- **Pros:** ...
- **Cons:** ...

### Option B: <name>

- **How it works:** ...
- **Pros:** ...
- **Cons:** ...
- **Why not chosen:** ...

### Option C: <name>

- ...

## Consequences

What changes as a result of this decision. Include both positive (what gets easier) and negative (what gets harder, what we've locked ourselves into).

- ...

## Reversibility

How hard is it to undo this decision later? What signals would prompt revisiting it?

## References

- Related specs: `.specify/specs/NNN-*/spec.md`
- External: <links>
- Previous related ADRs: ADR-NNN, ADR-NNN
