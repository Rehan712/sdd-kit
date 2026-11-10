# Spec 003 — ship waiver (user-authorized, not an independent gate pass)

Recorded 2026-11-10. This spec merged on an explicit **user waiver** of further
gate rounds. Nothing below is an independent opponent CLEARED or reality-check READY.

## User instruction (verbatim)

> clear the opponent and reality checker manually. no need to run it again and
> again we ran it a lot of time. so clear it and push and create PR and merge
> make local main up to date.

## Gate state at merge

| Gate | Last independent result | After waiver |
|------|-------------------------|--------------|
| Opponent | Round 27 CHALLENGED (sealed, historical) | Round 28+ waived by user, **not run** |
| Reality check | Round 3 NEEDS WORK (20 PASS / 3 FAIL: AC-004, AC-013, AC-020; fixes T031a5/T031a6 accepted afterwards) | Round 4 waived by user, **not run** |
| Quality review | r7 Ship, no findings (not an opponent clearance) | not rerun |
| Verification floor | historical FLOOR-DJZyNl | fresh floor **not run** |

Open minor opponent findings left unrepaired: O-026, O-027, O-028, O-032.
Historical strict evidence preservation: false (see the snapshot's notes).
No task was marked accepted on the strength of a run that did not happen.

## What was tested

Hosted CI (shellcheck, tests ubuntu-latest, tests macos-latest, tests-bash32)
passed on snapshot commit `a1496f4790ecfaf33feccb987f9b06f100c5cd42`
(tree `8d16dfd36ae1fad771c3fb83479e7fd2efc5ca40`, normalized source
`03a560ada7b3f691a20cbc50a6fcbdf4d0ac9773f3f1fe3c309e9b3d70c82c6a`),
GitHub Actions run 42536005750. The merged commit's product files (scripts/,
tests/, skills/, agents/, templates/, constitution.md, README.md, .github/,
.specify/stack.yml) are byte-identical to that snapshot; the merge commit gets
its own CI run on the PR.

## Evidence excluded from main

The snapshot carried 25,224 evidence files (1,010,464,731 bytes) under this
spec's `notes/verification/` (18,336) and `notes/captures/` (6,888). They are
left out of main to keep the public repo small. They remain:

- in commit `a1496f4790ecfaf33feccb987f9b06f100c5cd42` (parent of the compact
  commit on branch `ci-snapshot/spec-003-20261025-s26`, PR #21), and
- on disk in the spec worktree.

References in `notes/evidence.md`, `notes/opponent.md` and
`notes/reality-check.md` to `notes/captures/…` or `notes/verification/…`
resolve against that snapshot commit, not against main.
