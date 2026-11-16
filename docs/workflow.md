# The workflow

From inside any registered project (including its `<repo>.worktrees/*` checkouts):

| Step | Command | Output |
|---|---|---|
| 1. Capture intent | `/sdd:specify "<feature>"` | `.specify/specs/NNN-slug/spec.md` (via interview: goals REQ-###, success metrics MET-###, acceptance criteria AC-###) |
| 2. Design approach | `/sdd:plan` | `plan.md` — stack experts consulted, codebase explored, then reviewed once by the opponent before tasking (`notes/plan-review.md`, STATUS `plan_review`) |
| 3. Break into tasks | `/sdd:tasks` | `tasks.md` — commit-sized tasks, each with files + acceptance check + refs; validated by `sdd-analyze.sh` |
| 4. Execute | `/sdd:implement` | Code changes in a `spec/NNN-slug` worktree, checkboxes ticked (`spec-task.sh` — tick + evidence atomically), gates run |
| 5. Drive the PR home | `/sdd:review` | CI watched via `spec-ci.sh`, red builds triaged into `T###c*` tasks, reviewer feedback into `T###r*`, re-gate rule applied, merge in contract order, worktree torn down |
| 6. Learn | `/sdd:retro` | `notes/retro.md` + generalizable lessons filed into `knowledge/` |

**In a hurry? `/sdd:go` — autopilot ("yolo mode").** Once a spec exists, one
command drives steps 2–4 end to end and opens the PR, without stopping for
human review of `plan.md` or `tasks.md` (each auto-acceptance is logged in the
STATUS Decisions log). What it *never* skips is the safety floor: the specify
interview (no spec → it runs `/sdd:specify` interactively first),
`[NEEDS CLARIFICATION]` markers (any unknown stops the chain instead of
guessing), the one-round plan review (an UNSOUND plan stops the chain),
`sdd-analyze.sh`, both adversarial gates at full strength (a gate
deadlock stops the chain — autopilot has no waiver authority), and the
`spec-pr.sh` gate check. The chain always ends at the open PR; `/sdd:review`
and the merge stay interactive. Umbrella specs autopilot too: implement
always runs locally there, and the chain ends once every declared repo's PR
is open.

Every spec directory also carries **`STATUS.md`** — the living handoff record
(phase, branch, worktree, PR, gate verdicts). Every tool reads it on entry and
updates it on exit, so a spec can move between Claude, Codex, Copilot, and
between sessions, without losing state.

## The two gates (both blocking, in order)

Before any PR:

1. **Opponent** (`agents/opponent.agent.md`) — steelmans why the implementation is
   *wrong*: untested inputs, races, regressions, misread requirements. Default
   verdict **CHALLENGED**; findings become `T###o*` follow-up tasks.
2. **Reality-check** (`agents/reality-check.agent.md`, or a project-local override)
   — demands observable evidence for every AC-###. Default verdict **NEEDS WORK**;
   gaps become `T###a…` follow-up tasks.

`spec-pr.sh` refuses to open a PR (exit 4) unless STATUS shows CLEARED + READY
(`--force` works only together with `--draft` — a non-draft PR can never skip
the gates), and on success writes `pr:` + `phase: review` into STATUS.md
itself. Neither gate grades its own work: on Claude they run as separate
subagents; on Codex the kit generates them as true subagents too
(`~/.codex/agents/sdd-opponent.toml` + `sdd-reality-check.toml`, built by
`build-adapters.sh` from the personas + models.yml); where no subagent is
available (Copilot today, or the TOMLs not installed) the adapter runs them
as distinct review passes. Each invocation requires a current floor and an atomic
round reservation. Rounds 1–3 are allowed per gate; round 4+ requires exact-gate,
exact-next-round authorization with an ordered UTC timestamp in STATUS Decisions.
A waiver permits one invocation and never softens a verdict. Check the entry
with `spec-gate.sh waiver <spec-dir> <gate> <round>` as soon as it is written:
it reports the exact clause that fails, reserves nothing and changes no state.

Two conventions keep the loop honest end-to-end:

- **Evidence lines.** A task checkbox is only ticked together with an
  `*Evidence:*` line (the acceptance command + its key output). Gates validate current
  proof and refresh stale checks; historical completion is preserved.
- **Clarification markers.** Unresolved decisions are written as
  `[NEEDS CLARIFICATION: <question>]`, never guessed; `sdd-analyze.sh` blocks
  tasking/implementation while any marker remains.
