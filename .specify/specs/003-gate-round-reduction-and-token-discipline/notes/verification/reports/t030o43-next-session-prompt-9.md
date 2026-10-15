Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (it is over 370 KB: read it in line ranges; the Read tool's
limit is 25k tokens, and the Bash tool's output limit is about 30 KB). Then read, under
notes/verification/reports/:
- t030o43-handoff-state-9.txt (the state at the stop; re-derive it with bash t030o43-handoff-state-9.sh,
  run from the worktree root with bash, never sourced into the tool's zsh: zsh ties a variable named
  `path` to PATH and the kernel's locals then break it)
- the seven Decisions entries dated 2026-09-30 (review 3's outcome as reproduced and the user's scope
  choices; the review-3 rule as measured; the task-block correction; review 4's outcome; the review-4
  rule as measured; the second task-block correction; the matrix of record, which FREEZES Decisions)
  and the T030o43 task block in tasks.md
- t030o43-review3.md, t030o43-review3-verify.{sh,log,rc}; t030o43-review4.md, t030o43-review4-verify.{sh,log,rc};
  t030o43-measure-9.{sh,log,rc} and t030o43-measure-10.{sh,log,rc} (the measurements of record, -run1 kept);
  t030o43-r3f6-mawk.{sh,log,rc}; t030o43-edits/ (session 9's pairs: kernel-6, kernel-7, spec-task-3,
  sdd-analyze-3, tgc-6..tgc-9, tsa-7, tsg-8, vc-4, vc-5, tasks-fix-4, tasks-fix-5); t030o43-final.diff
- the dev runs t030o43-dev6-{quick,full,full-locale} and t030o43-dev7-gc (all rc 0), and the matrix of
  record t030o43-mutations.sh (v4, 147 rows) with t030o43-mutations-v4-shard{0,1}.{log,rc} (exit 0 each;
  -run1 kept)
- opponent-round13-brief.draft.md (the round-13 brief; fill in the reservation's Source, Floor, reserved
  time, the capture id and the free disk, and check every claim in it against the receipts)

Verified state at the stop (2026-09-30T13:50Z, t030o43-handoff-state-9.txt):
- T030o43 (O-017 repair) is IMPLEMENTED, reviewed four times and matrix-proven, and UNTICKED. Reviews 3 and 4
  were reproduced before any change, their repairs measured before adoption, recorded in Decisions and applied
  as pairs files; review 4 was the last focused review. Open extent recorded in Decisions for the follow-up
  task: R3-F7, R3-F10, R4-F3, R4-F5, R4-F6, R4-F8, and the residuals the 2026-09-30 entries name.
- Decisions are FROZEN (the last 2026-09-30 entry) through the capture and acceptance of T030o43, the floor,
  and round 13's completion and tally; results go to the neutral STATUS sections only.
- Round 13 AUTHORIZED by the recorded waiver 2026-09-27T15:55:36Z (round 13 exits 0, round 14 exits 4).
  No floor is current: FLOOR-0334B2 is historical.
- Source ecbca9d295a38c14e001b11fcaefcd1849ed6e8b65fb5824722a4ab565a43d0d, Decisions
  8ce4d6ec8cbd50a72b1059e9101fa4d89b99085cae4b3a85adff224ab59e8751, HEAD 0d55c62, no lock, no pending
  reservation, 514 captures, analyzer 0 errors. T030-T034 unticked; T030o39-T030o42 ticked.
- Host at the stop: on battery, free disk 14 GiB, swap 2.6/3.0 GB. The user authorized removing regenerable
  caches in earlier sessions (r13-disk-reclaim.*); ask again before removing anything else, and never touch
  taxipro-backend, sales-platform, Docker or vm_bundles. `mv-localstack` was already exited when session 9
  began; it was not touched.

Order:
1. Re-verify the state (bash t030o43-handoff-state-9.sh); check disk, swap and AC power (pmset -g batt).
2. Freeze: bash t030o43-freeze.sh > t030o43-freeze.txt (from the worktree root); it must match the state above.
3. Capture T030o43's Verify: bash scripts/spec-run.sh <spec> T030o43 --from-task --no-tick --summary, in the
   background, receipts t030o43-capture.{log,rc,start,end} (about 25 minutes; read the rc back from its file).
4. Return (bash t030o43-return.sh, receipts t030o43-return-validate.{log,rc}), accept
   (bash scripts/spec-gate.sh accept <spec> T030o43 notes/verification/returns/T030o43.txt, receipts
   T030o43-accept.{log,rc}), and a post-accept check (t030o43-postaccept.txt: the tick moves neither the
   source nor Decisions).
5. One fresh floor ON AC (bash r13-floor.sh 1, which refuses off AC; about 4 h, cold), validate it current
   (r13-floor-validate.*), scope (bash r13-scope.sh <FLOOR-id>), worktree states (r13-worktree-state.sh
   prereserve, then reserved, then returned; all three must be byte-identical), reserve round 13
   (r13-reserve.*), finish opponent-round13-brief.md from the draft, dispatch the independent opponent with
   that path-based brief (the report must carry the reservation's Source/Floor and the exact
   <!-- gate-round-end: opponent:13 --> marker), complete, tally, final audit, update STATUS, stop.

Standing rules: never change source during a reservation, and make no STATUS edit between the prereserve and
returned states; run no suite or test function in the live worktree except the formal capture, floor and gate
commands; exploratory runs go in standalone copies with a before/after status check; read every exit back from
its receipt, never from a notification; never pipe suites through tail; no foreground command over 10
minutes; do not edit a bash script while it is running; perl -0pi with an exit in its code truncates the
file, and perl interpolates $0 even inside \Q...\E (use a literal replacement helper). Check disk, swap AND
AC power before and during long runs, and ask before reclaiming anything or stopping Docker. Do not infer
authorization for hosted CI, the 002 fix, the open-extent task, reality-check round 2, round 14, commits,
PRs or bypasses.
