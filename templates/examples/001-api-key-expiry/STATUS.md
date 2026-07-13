---
spec: 001-api-key-expiry
phase: tasks
active_tool: claude
branch: none
updated: 2026-07-10
---

# Status — 001-api-key-expiry

## Where things stand

Spec and plan accepted; tasks decomposed and validated (`sdd-analyze.sh` clean).
Worktree not yet cut — it appears on the first `/sdd:implement`.

## Next action

`/sdd:implement` (or `/sdd:implement T001`).

## Decisions

- 2026-07-10 — Expiry enforced at the middleware read path, not a sweeper job —
  one comparison site, no new infra (plan §1).
- 2026-07-10 — Missing `expires_at` fails CLOSED after the 48h flag window;
  the backfill + flag cover the gap (plan R1).
- 2026-07-10 — `revoked` outranks `expired` when both are true (plan §4 seam).

## Blockers

(none)
