Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (it is over 300 KB: read it in byte ranges). Then read, under
notes/verification/reports/:
- t030o43-handoff-state.txt (the state at the stop) and t030o43-review2-design.md (the working design,
  NOT yet measured)
- t030o43-review2.md with t030o43-review2-verify.{sh,log,rc} (review 2: 5 blocking, 3 minor, all
  reproduced) and t030o43-review.md with t030o43-review-verify.{sh,log,rc} and
  t030o43-review-measure.{sh,log,rc} (review 1, repaired)
- t030o43-parser-classes.md, t030o43-session.diff, t030o43-review-repair.diff, t030o43-edits/ (every
  literal edit as a pairs file, lit.pl, source-70c71885-inputs.nul), t030o43-pre-rebuild.{sh,log,rc}
- the last six Decisions entries (from "Opponent round 12 is recorded here now that this batch moves the
  source anyway" to the user's option-1 decision after review 2), and the T030o43 task block in tasks.md
- the prepared, not-yet-run scripts: t030o43-freeze.sh, t030o43-return.sh, r13-floor.sh,
  r13-worktree-state.sh, r13-scope.sh; t030o43-mutations.sh (56 rows on the review-1 state) and
  t030o43-dev.sh (quick|full|full-locale|suite:<file>)

Verified state at the stop (2026-09-28T06:19Z, t030o43-handoff-state.txt):
- T030o43 (O-017 repair) IN PROGRESS and unticked. The worktree's code is the review-1 repair state,
  which carries review 2's R2-F1, R2-F3 and R2-F5 regressions: nothing may be captured or accepted on it.
- The user chose option 1 after review 2: repair the class at once. Under the harness pin (LC_ALL=C) a
  byte >= 0x80 is in no character class, so every harness parser that trims or separates with
  [[:space:]] changed meaning for non-ASCII whitespace. The approach: read non-ASCII Unicode whitespace as
  whitespace inside the harness's own parsing through one shared step every author-text parser takes
  (vf_report_block stays raw: its output is a sealed digest), plus R2-F1 (a Decisions section at every
  heading beginning "## Decisions log", ended only at an unquoted heading), the manifest restructure
  (R2-F2, R2-F3), name tokens (R2-F5), key-count contract routing (R2-F6), fixture gaps (R2-F7) and
  wording (R2-F8). Details, file:line sites and the candidate fixtures are in t030o43-review2-design.md.
- Round 13 AUTHORIZED by the recorded waiver 2026-09-27T15:55:36Z (spec-gate.sh waiver ... opponent 13
  exits 0; round 14 exits 4). No floor is current: FLOOR-0334B2 is historical.
- Source c2536743df65d193c2bd9530443400b80d69923ccf6f73b72f572db06e7cadce, Decisions
  df18ccdee684b14c47ea29381dedc75788dbc171ac5fc4b49aacc7fede71621a, HEAD 0d55c62, no lock, no pending
  reservation, 514 captures, analyzer 0 errors. T030-T034 unticked; T030o39-T030o42 ticked.
- Host at the stop: free disk 8.2 GiB, on battery. The user authorized removing regenerable caches
  (r13-disk-reclaim.*); ask again before removing anything else, and never touch taxipro-backend (two
  long-running node scripts use it), sales-platform, Docker or vm_bundles.

Order, as recorded in Decisions:
1. Re-verify the state against t030o43-handoff-state.txt; check disk, swap and AC power (pmset -g batt).
2. Measure the design in a standalone copy BEFORE adopting it: every review-1 and review-2 case gives its
   intended result under C and en_US.UTF-8 (every LC_* removed), and tally for 001/002/003 and the
   snapshot, including every STATUS's semantic view, are unchanged. Correct the design where measurement
   says it is wrong.
3. Record the measured rule, and any correction, in Decisions before any code (validate that round 13
   stays authorized and round 14 refused after writing).
4. Implement, with a fixture and a matrix row for every guard (rewrite S31-S40 for the new code); dev runs
   in standalone copies: quick, full, and full under LANG=en_US.UTF-8.
5. One focused review 3 of that delta by an independent read-only reviewer (pattern:
   t030o43-review2-brief.md); reproduce and repair its blocking findings; then the matrix of record.
6. Freeze (t030o43-freeze.sh), capture T030o43's Verify (bash scripts/spec-run.sh <spec> T030o43
   --from-task --no-tick --summary, in the background, receipts t030o43-capture.*), return
   (t030o43-return.sh), accept (spec-gate.sh accept), post-accept check.
7. One fresh floor ON AC (bash r13-floor.sh 1, which refuses off AC; about 4 h, cold), validate it
   current, scope (r13-scope.sh), worktree states (r13-worktree-state.sh prereserve/reserved/returned),
   reserve round 13, dispatch the independent opponent with a path-based brief (pattern:
   opponent-round12-brief.md; the report must carry the reservation's Source/Floor and the exact
   <!-- gate-round-end: opponent:13 --> marker), complete, tally, final audit, update STATUS, stop.

Standing rules: record Decisions and task definitions BEFORE refreshing proof; never change source during
a reservation; run no suite or test function in the live worktree except the formal capture, floor and
gate commands; exploratory runs go in standalone copies with a before/after status check; read every exit
back from its receipt; never pipe suites through tail; no foreground command over 10 minutes; perl -0pi
with an exit in its code truncates the file (write substitutions through a helper that writes itself).
Check disk, swap AND AC power before and during long runs, and ask before reclaiming anything or stopping
Docker (mv-localstack has restart policy "no" and no persistence). Do not infer authorization for hosted
CI, the 002 fix, the open-extent task, reality-check round 2, round 14, commits, PRs or bypasses.
