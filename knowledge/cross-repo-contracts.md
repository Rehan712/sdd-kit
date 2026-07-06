# Cross-repo contracts

How features that span repos (umbrella specs) stay coordinated without a
shared codebase. Complements `api-versioning.md` (which covers how one API
evolves); this covers how MANY repos ship one feature.

## Contract-first is the ordering rule

For any umbrella spec, the first implementation tasks are the contract tasks:
the OpenAPI/event-schema/type change lands in the contract's `source` repo
(per `system-map.yml`) before any consumer writes code against it.

Order within `tasks.md`:

1. **Contracts** — schema change in the source repo (reviewable on its own).
2. **Infra** — queues/tables/DNS the feature needs (`[repo:<infra-repo>]`).
3. **Providers** — services implementing the contract.
4. **Consumers** — web/mobile/big-screen clients, via codegen where available.

Merge/deploy order follows the same sequence — providers before consumers,
with the additive-first rules from `api-versioning.md` so a half-shipped
feature never breaks callers.

## Consumers build against the contract, not the branch

Clients regenerate types from the contract artifact (OpenAPI codegen, schema
registry), never by importing another repo's source or hand-copying shapes.
If two repos need the same type and there's no contract for it yet, that's a
missing contract — add it to `system-map.yml`, don't paste.

## Other teams' repos: [EXTERNAL], stub at the contract

A dependency on a repo you don't own never becomes a task. Instead:

- The spec records `[EXTERNAL: <team/repo> — <what you need> — needed-by <date>]`
  in Constraints, mirrored in STATUS blockers (`sdd-analyze.sh` checks this).
- Implementation stubs **at the contract boundary** — a fake that satisfies
  the agreed schema version, clearly marked, behind an integration point you
  can flip.
- The reality-check gate accepts one of exactly two outcomes for the affected
  AC: real integration evidence, or an explicit "blocked on external —
  stubbed at contract vN" verdict in STATUS. A silent mock that ships as if
  integrated is the failure mode this convention exists to prevent.

## One spec, many PRs

Each repo ships its own PR (`spec-pr.sh --repo <name>`), all referencing the
umbrella spec in the hub. Gates run once, spec-wide, and block every PR —
a feature isn't CLEARED because one repo's slice is fine. The STATUS Repo
matrix is where per-repo branch/PR state lives; sibling PRs link each other.

## Smells

- A consumer PR merged before its provider's contract change is deployed.
- "Temporary" hand-written types mirroring another repo's response shape.
- An umbrella spec where one repo's tasks are all `[x]` and another's are
  untouched for a week — the feature is now half-shipped; either finish or
  flag off.
- An [EXTERNAL] marker that survived to Ship with no date and no contact.
