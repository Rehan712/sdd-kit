Continue spec 003 in:
      /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-an
  d-token-discipline

  Read the spec's STATUS.md completely FIRST (about 640 KB: fold lines over 1800
  characters into a scratch copy,
  then read it in ~50 KB ranges). In the session-19 paragraph of Where things
  stand, replace the placeholder
  "Decisions now `<see r21-handoff-state.txt>`" with "Decisions now `b0455bae…`,
  source `a24c2230…`; no floor is
  current, FLOOR-QCFkfi historical". Then re-derive the state with
  bash .specify/specs/003-gate-round-reduction-and-token-discipline/notes/verifi
  cation/reports/r21-handoff-state.sh
  from the worktree root (bash, never sourced) and compare it to
  r21-handoff-state.txt.

  State at the stop (r21-handoff-state.txt, 2026-10-09T12:14:53Z):
  - Decisions b0455bae0533cf197bac8f7a5d40a4ba9b7e907fe9b703bb10489626f0e6ac81.
  Round 17's outcome, the user's
    choices and the rules are in Decisions; the round-18 waiver is
  2026-10-09T09:41:41Z.
  - Source a24c22304863da8124ff176f4c6ce24dbd67a9fc61c83fe1b9aec9a7c16d3688,
  HEAD 0d55c62, no lock, no pending
    reservation, 17 sealed opponent rounds.
  - No floor is current. 627 captures. Analyzer 0 errors. Tally opponent=17
  blocking=34 minor=14.
  - T030o51 (O-018 + the minor), T030o52 (O-024) and T030o53 (O-023) are present
  and unticked. The four repair
    files hash as r18-edits/post-apply-1 (applied live by r18-apply-1).
  - Round 18 is authorized (exit 0); round 19 is refused (exit 4).
  - The Mac ran down to 5% and probably slept between ~10:15Z and 12:14Z; it is
  on AC now.

  User's choices (2026-10-09): O-018 narrow further, O-024 narrow, O-023 the
  reviewer's M3 (corrected for
  soundness to check every reading's head). The invoker folded the minor into
  T030o51.

  Done in session 19 (receipts under notes/verification/reports/):
  - Reproduction: r18-repro (231 PASS). Survey: r18-grammar-survey.
  - Measurement: r18-measure (1380 PASS, full suite on D 147/147; run 1 stopped,
  with a note).
  - Fixtures: tgc-1/tsg-1 judged both ways by r18-fixtures-judge (58 PASS; run 1
  with a note).
  - Batch: r18-decisions-1 validated on scratch and written live. Repair
  applied: r18-apply-1, delta
    r18-session.diff.
  - dev1 full and full-locale: 147/147 plus ShellCheck.
  - Matrix v6 discovery: r18-discover-{a,b,c} over 76 mutants
  (r18-discover-mutants.py). 41 are killed by existing
    rows. 10 are to be argued as equivalents: G07 (the old A08), B07, H08, R03,
  R10, S04, S05, S07, S08.
    24 need rows.
  - Those rows are built as r18-edits/tgc-2.pairs (build-fixtures-2.py) and
  judged by r18-fixtures-judge-2.sh
    (rc 1 in each shard). Every named row fails under its mutant EXCEPT S03
  (ordered-number-then-image),
    S09 (break-image-outside-finding-after-id) and S10
  (image-alt-beginning-with-code-span-across-lines),
    whose rows pass under their mutants. tgc-2 is NOT applied.

  Next, in order:
  1. Re-verify the state. Check disk, swap and AC power.
  2. Find why the S03, S09 and S10 rows pass under their mutants (read
  r18-fixtures-judge-2-*-S03/S09/S10
     .asserts/.out; test each row with its mutant in a standalone copy). Correct
  each row, or re-classify its
     mutant as an argued equivalent, in build-fixtures-2.py and
  r18-fixtures-judge-2.sh. Re-judge (keep this
     run as run 2, with a note). Apply tgc-2 after a hash check against
  r18-edits/post-apply-1.sha256
     (r18-apply-2.sh from r17-apply-2.sh).
  3. dev2 full and full-locale (r15-dev.sh).
  4. Matrix v6: write r18-mutations-gen.py from r17-mutations-gen.py.
     - Re-target the v5 rows whose literals changed: G06, G06e, G07, G12–G19,
  E09, E09c, P21, D05–D07, D12–D15,
       D19. D12, D13, D14 and D19 now become kills.
     - Add the discovery rows (judges named in r18-discover-*.log and tgc-2) and
  the argued equivalents.
     - Dry run, probe, then the run of record in three shards.
  5. Freezing Decisions entry r18-decisions-2.md (scratch, then live); freeze
  point; one capture of record;
     returns and spec-gate.sh accept for T030o51–T030o53; post-accept check.
  6. One fresh floor on AC (r18-floor.sh from r17-floor.sh, nohup; cold, about 5
  h). Validate; scope against
     FLOOR-QCFkfi; worktree states; reserve round 18; brief from
  opponent-round17-brief.md; the opponent
     (persist its block from its transcript; resume after a usage limit);
  complete; tally; final audit; STATUS;
     report.

  Standing rules:
  - Never change source during a reservation, and make no STATUS edit between
  the prereserve and returned states.
  - Run no suite in the live worktree except the formal capture, floor and gate
  commands.
  - Never source from tests/; source the kernel only inside bash -c.
  - Exploratory runs go in standalone copies with a TMPDIR ending in `/` and a
  before/after status check.
  - No apostrophes inside single-quoted awk programs; never pass awk a -v value
  holding a real newline (use
    ENVIRON).
  - Read every exit back from its receipt. No foreground command over 10
  minutes. Don't edit a running script.
  - Matrix literals must match exactly once: vf_cm_dest mirrors vf_label_dest,
  so mutate inside the function's
    own text, as mf() in r18-discover-mutants.py does.
  - Check disk, swap and AC before and during long runs. Ask before reclaiming
  anything or stopping Docker.
  - Stop and ask on a choice between fixes with trade-offs.
  - No hosted CI, 002 fix, open-extent task, reality-check round 2, commits, PRs
  or bypasses without the user's
    authorization.
