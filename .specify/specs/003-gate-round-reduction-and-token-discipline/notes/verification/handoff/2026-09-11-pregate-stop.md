# Stop point — 2026-09-11: checkpointed through Observability; round 2 unspent

Continue directly in:

`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`

No `/sdd:implement`, no `/sdd:go`, no implementation subagents. Only the
independent opponent/reality-check gates get an agent. Read this file, STATUS.md,
and `../reports/opponent.md`; the earlier `2026-09-10-round1.md` retains the
counted round-1 history and schema traps.

## Why this is the stop point

The user first requested the full pre-gate helper, dossier regeneration, then
an explicit confirmation before reserving opponent round 2. During that run
the user changed the immediate scope to: "finish current task and stop and
update status for handoff."

At that point API and Tests had already completed and Observability was running.
The parent helper was paused while its Observability child finished normally,
then terminated before it could start Docs. The wrapper's exit 143 is the
requested stop, not a checkpoint failure or a completed pre-gate sequence.
There is no background runner left and no verification lock remains.

## Sealed proof

All four receipts carry exit 0 and the same source identity:

`e6979a100b355e5f3e87997939c215ed1f71956109823eac5e2004f6c383326a`

| Stage | Receipt | Executed | Reused |
|---|---|---:|---:|
| Backend | CHECKPOINT-h6a3g2 | 12 | 22 |
| API | CHECKPOINT-uBdMs1 | 1 | 35 |
| Tests | CHECKPOINT-TK5mFw | 2 | 38 |
| Observability | CHECKPOINT-EQfHsK | 0 | 41 |

The receipts live in `../checkpoints/<id>/`. Full runner output is
`pregate-round2-20260910.log`. Current captures were refreshed as CAP-118 through
CAP-132; no historical task acceptance was rewritten.

- CAP-129-kgKRFf: `bash tests/run.sh`, 130/130 across all 15 suites, exit 0.
- CAP-130-ivIQoG: contract + gate suites, 14/14 + 6/6, exit 0.
- CAP-131-tYz0RJ: full suite + ShellCheck, 130/130 and combined exit 0.
- CAP-132-ijHQzK: gate + contract suites, 6/6 + 14/14, exit 0.

The API and Tests stages each had uncached combined Verify commands; a cold
Backend alone did not cover those exact command identities. Their fresh
executions are real, not inferred from passing component suites.

The Tests receipt spans 2026-09-10T22:35:34Z to 2026-09-11T06:49:04Z, and
CAP-132 spans the overnight interval. Do not infer active execution time or
MET-001 savings from that wall-clock interval. Execution/reuse counts remain
usable; actual token usage and baselines remain unknown.

## Local self-attack: O-002 still reproduces

While the cold run was in progress, a local probe found that T030o7's fence
suppression still lets a quoted authorization lift the cap. A shorter inner
fence, or a different inner fence character, toggles suppression off inside a
valid outer Markdown code block. The quoted waiver/spec-revision then returns
exit 0 from the real `vf_round_authorized` instead of the required exit 4.

Read [round2-self-attack/README.md](round2-self-attack/README.md). It includes the
exact trigger, production source locations, raw fixture inputs, original
results, and a runnable Bash replay:

```sh
bash .specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/handoff/round2-self-attack/reproduce.sh "$PWD"
```

On the current source it exits 1 with `cases=20 mismatches=8`: eight erroneous
authorizations across both gates and both authorization forms. All twelve
controls behave correctly. Five sibling parsers have the same toggle pattern;
they were identified from source, not behaviorally cleared by this probe.

This is local review evidence for O-002, not a counted opponent report, a new
task, an accepted repair, or an additional gate round. No implementation source
was changed. Recommendation: repair and accept this bypass before spending
round 2, then refresh verification on the repaired source.

## Still pending

- Docs checkpoint.
- Fresh typed T029/AC-016 rejected-copy and intact-acceptance control. This run
  stopped before that control; ACCEPT-KsToLg still predates T030o8's split.
- New floor. `../floor-latest` still points to historical `FLOOR-JKSuM0`, whose
  source is stale. The new checkpoint receipts are not a floor.
- Dossier regeneration: `../dossier/source.diff`, `source-stat.txt`,
  `untracked.txt`, and its stale README still describe the older review input.
- Explicit user confirmation before reserving opponent round 2.

The existing `finish-pregate-20260910.sh` remains the full resume route: it
revalidates all checkpoints, performs the fresh control, then seals the floor.
Its final printed sentence incorrectly mentions "round 1 unreserved"; the real
ledger, not that stale helper sentence, determines round state. Use the actual
source/floor identities it seals. A new session/environment or source edit may
force cold execution; never normalize environment values to manufacture reuse.

The full AC-016 probe still waits until a reality-check reservation exists by
design. GitHub-hosted PR CI remains unrun and cannot be claimed as passing.

## Gate and preservation rules

Opponent round 1 remains completed and consumed: CHALLENGED, 5 blocking + 1
minor, canonical report-block digest
`1ac95178f408b2ae807005a0e349816477e90b4dab5afd70a536cfe798f0c9e7`.
There is only `rounds/opponent/ROUND-1`; round 2 is not reserved. Two rounds
remain before an extra-round authorization is required.

After fresh proof and dossier regeneration, **stop for the user's confirmation
before reserving round 2**. After confirmation, reserve through `spec-gate.sh`
and give the opponent that exact round/source/floor, the branch diff including
dirty/untracked inputs, `../reports/opponent.md` as `Prior:` context, and the
local probe. Require O-001 through O-007 to be resolved or reopened by ID.
The returned report must start exactly at `## Round 2`, with no preamble.

Never tick without `spec-gate.sh accept` exit 0. Run library functions under
Bash, not interactive zsh. Do not edit any tracked file or STATUS Decisions
between reserving and completing a round. The STATUS handoff update in this
pass changes only frontmatter/prose outside Decisions; no task checkboxes,
opponent reports, Decisions entries, implementation files or commits changed.

HEAD remains `0d55c62`. The existing staged/unstaged implementation is preserved.

Post-handoff validation is recorded in `handoff-validation-20260911.log`:
all four receipt seals pass integrity checks, the before/after source manifests
are byte-identical, round history still ends at 1 with its original digest, and
the verification lock is absent. Tasks, both opponent-report files and the
Decisions section were separately checked byte-for-byte unchanged.
