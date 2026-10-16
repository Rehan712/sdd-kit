Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (about 520 KB: fold lines longer than 1800 characters into a scratch copy
first, since the Read tool truncates long lines, then read it in ranges of about 50 KB; the Read tool's limit is 25k
tokens, and the Bash tool's output limit is about 30 KB). Then read, under notes/verification/reports/:
- r16-handoff-state.txt (the state at the stop; re-derive it with bash r16-handoff-state.sh, run from the worktree
  root with bash, never sourced into the tool's zsh)
- the round-15 record: opponent-round15.md (O-018 reopened blocking; O-020 and O-021 resolved) and
  opponent-round15-brief.md
- the session-15 work on T030o47: r15-repro.{sh,log} (the reproduction, 166 PASS), r15-measure.{sh,log} with
  r15-measure-suite.log (the candidate measured; exit 0, 975 PASS, the full suite on the candidate 147/147, the history identical; run 1, stopped on the first candidate, kept with a
  note), r15-fixtures-judge.{sh,log} (the judge of record, exit 0; runs 1 to 4 kept with notes), and the prepared,
  unapplied files: r15-edits/{kernel-1,vc-1,tgc-1,tsg-1}.pairs with r15-edits/pre-apply.sha256, r15-decisions-1.md,
  r15-decisions-1-apply.sh, r15-task-block.md, r15-task-insert.sh, and r15-mutations.sh (matrix v4, 171 rows, built by
  r15-mutations-gen.py; dry run exit 0 on a scratch copy of the repaired tree)
- STATUS's session-15 paragraphs (Where things stand), the Open questions entries and Next action

Verified state at the stop (r16-handoff-state.txt):
- Source c9f2b61691a4447d28f4baaf640c3f43ec993040fda9febaf8eba82134e5b21e, Decisions
  7c0c5ede16a40e76fb6c89001c60877c5eed3e8a4bb6b68aaebc57c96d720134, HEAD 0d55c62, no lock, no pending reservation,
  15 sealed opponent rounds (round 15 241cebc5...), 582 captures, analyzer 0 errors, tally opponent=15 blocking=30
  minor=12 locations=439, FLOOR-dCwGgb current, T030o45 and T030o46 ticked, round 16 refused at exit 4. The four
  repair files hash as r15-edits/pre-apply.sha256: NOTHING of T030o47 is applied, and NOTHING is written to Decisions
  or tasks.md.
- The user's standing instruction of 2026-10-07 (session 15), not yet written to Decisions: "I approve round 15. and if
  comes back challenged then fix the issues and rerun round 16 until all issues been resolved." The reading told to the
  user: each further round still gets its own exact-round waiver line, drafted citing this instruction and validated on
  a scratch copy and live; each repair follows the standing order; stop and ask on a choice between fixes with
  trade-offs, a spec revision, a disk or power problem that needs reclaiming, or anything not authorized; report to the
  user after each round. The round-16 waiver text is in STATUS Next action (one line, no "; " inside reason).

Order (STATUS Next action):
1. Re-verify the state (bash r16-handoff-state.sh); it must match the above. Check disk, swap AND AC power (the Mac
   was on battery at the stop; the floor refuses to start off AC).
2. Write the Decisions batch BEFORE any code: re-read every entry of r15-decisions-1.md against the receipts (its measurement
   sentence was filled from r15-measure.log at the stop); replace each @@DATE@@ with the UTC date of writing
   and @@WAIVER@@ with the round-16 line stamped at writing time (after 2026-10-07T19:07:33Z, not in the future), in
   byte mode (perl without -C: session 15's perl -CSD double-encoded an em dash taken from the environment); then
   bash r15-decisions-1-apply.sh <scratch> scratch, and only on exit 0 ... live (receipts
   r15-decisions-1-{scratch,live}.{log,rc}): round 16 exit 0, round 17 exit 4, analyzer 0 errors, T030o47 present.
3. Apply the four pairs after a hash check against r15-edits/pre-apply.sha256 (pattern r15-apply-1.sh), each block
   exactly once; record post-apply hashes and the delta.
4. Dev runs in standalone copies with a TMPDIR ending in `/` (r15-dev.sh): full and full-locale, 147/147 plus
   ShellCheck. Matrix v4: DRY=1 on the live repaired tree, probe the new and rewritten rows (ONLY=), then the run of
   record in two shards (it can run beside the dev runs).
5. Freezing Decisions entry (pattern r15-decisions-2.md and its apply script), the freeze point (pattern r15-freeze.sh
   with the new post-apply hashes), one capture of record for T030o47, the return (pattern r15-return.sh) and
   spec-gate.sh accept, post-accept check.
6. One fresh floor on AC (about 4.5 hours; detached with nohup and a wrapper rc; a new r16-floor.sh from r15-floor.sh),
   validate, scope against FLOOR-dCwGgb, worktree states, reserve round 16, the brief (pattern
   opponent-round15-brief.md), the independent opponent, complete, tally, final audit, STATUS.
7. Under the standing instruction: if round 16 is CHALLENGED, repeat the cycle (round 17's waiver in its batch) and
   report to the user; if CLEARED, stop and report.

Standing rules: never change source during a reservation, and make no STATUS edit between the prereserve and
returned states; run no suite or test function in the live worktree except the formal capture, floor and gate
commands; NEVER source a file from tests/ (a suite file ends in t_run_all) and never source anything from tests/
with the live worktree as the working directory: extract a helper with awk into a scratch file; source the kernel
only inside bash -c, never in the tool's zsh; exploratory runs go in standalone copies with a before/after status
check, and any dev run gives its copy a TMPDIR ending in `/`; run any loop that uses printf '%b' escapes inside bash,
not the tool's zsh; inside an awk program held in single quotes, never write an apostrophe, not even in a comment;
read every exit back from its receipt, never from a notification; never pipe into `grep -q` or `head` under pipefail
where the producer's status matters; never pipe suites through tail; no foreground command over 10 minutes (macOS has
no `timeout`; background it). A floor outlives a tool-managed background shell (2 hours): launch it detached with
nohup and a wrapper rc and wait on its receipt. Do not edit a bash script while it is running. The independent
opponent's file tool may refuse the report file: persist the block it returns and check it byte-identical; if a
session usage limit stops it, resume it (SendMessage) rather than starting over, after checking the worktree is
unchanged. Check disk, swap and AC power before and during long runs; ask before reclaiming anything or stopping
Docker; never touch taxipro-backend, sales-platform, Docker or vm_bundles. Reviewers may use throwaway containers of
images already on disk only within the recorded limits. Do not infer authorization for hosted CI, the 002 fix, the
open-extent task, reality-check round 2, commits, PRs or bypasses.
