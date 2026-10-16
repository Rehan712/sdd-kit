Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (about 580 KB: fold lines longer than 1800 characters into a scratch copy
first, since the Read tool truncates long lines, then read it in ranges of about 50 KB; the Read tool's limit is 25k
tokens, and the Bash tool's output limit is about 30 KB). Then read, under notes/verification/reports/:
- r19-handoff-state.txt (the state at the stop; re-derive it with bash r19-handoff-state.sh, run from the worktree
  root with bash, never sourced into the tool's zsh)
- the round-16 record: opponent-round16.md (O-018 reopened, O-022 new and blocking, O-023 new and minor) with
  opponent-round16.note
- the prepared repair, NOT applied: r17-repro.log, r17-grammar-survey.log, r17-measure.log (and r17-measure-suite.log),
  r17-fixtures-judge.log, and r17-edits/ (pre-apply.sha256, kernel-1.pairs, vc-1.pairs, tgc-1.pairs, tsg-1.pairs,
  built by build-pairs.py and build-fixtures.py from the exact current text)
- the patterns for the batch and the rest of the cycle: r15-decisions-1.md with r15-decisions-1-apply.sh,
  r15-task-block.md with r15-task-insert.sh, r16-apply-1.sh, r15-dev.sh, r15-mutations-gen.py (matrix v4),
  r16-decisions-2.md, r16-freeze.sh, r16-return.sh, r16-floor.sh, r16-gate-step.sh, r16-scope.sh,
  r16-worktree-state.sh, opponent-round16-brief.md, r16-final-audit.sh
- STATUS's session-17 paragraphs (Where things stand), the Open questions entries (the user's decision of
  2026-10-08) and Next action

Verified state at the stop (r19-handoff-state.txt, 2026-10-08T16:12:16Z):
- Source eee97354a5aa4069a44c3791db4b576486502299450a7d3a89739677ec949c12, Decisions
  29a29da2faf62450cf027155dafd416a530930edc5f2dc4103131d8a1caa823c (round 16's outcome deliberately NOT yet in
  Decisions), HEAD 0d55c62, no lock, no pending reservation, 16 sealed opponent rounds (round 16 fb9bcfb4...), 605
  captures, FLOOR-UW5FIE current for eee97354..., analyzer 0 errors, tally opponent=16 blocking=32 minor=13
  locations=455, T030o47 ticked, round 16 completed and round 17 refused at exit 4, the four repair files still at
  r17-edits/pre-apply.sha256 (nothing applied).
- The user's standing instruction of 2026-10-07 (in Decisions): repair a CHALLENGED round's findings and rerun the
  opponent until all issues are resolved. Each further round gets its own exact-round waiver line in its repair's
  batch, validated on a scratch copy and live; stop and ask on a choice between fixes with trade-offs, a spec
  revision, a disk or power problem that needs reclaiming, or anything not authorized; report after each round.
- The user's decision of 2026-10-08 (STATUS Open questions): O-018, narrow the grammar inside a finding (refuse by
  name raw HTML or an autolink outside every code span, a lone carriage return, a form feed or vertical tab, in both
  readers, the code-span test on the refusing side); O-023, drop settled candidates; O-022, one to six marks. The
  candidate also stops ending runs at tracker-fenced lines (a member the invoker derived: an image split after a
  backtick line whose info string holds a backtick). Measured: every member refused, the whole history identical,
  the run reader linear; the consequences (raw HTML inside a finding refused, including T030o47's HTML positives,
  O-021's HTML blocks after a field line, a fenced tag example, a tag in a code span that spans lines) are to be
  stated in the batch.

Order (STATUS Next action): re-verify and check disk, swap and AC; write ONE Decisions batch before any code (round
16's outcome, the user's decision, the reproduction, the rule with its measurement, survey and consequences, the task
block or blocks, and the round-17 waiver, text in Next action, stamped at writing time in byte mode), validated on a
scratch copy and live (round 17 exit 0, round 18 exit 4, analyzer 0 errors); apply the four pairs after a hash check;
dev runs; matrix v5 (a row per new guard, carried rows the narrowed grammar shields re-judged); a freezing entry, the
freeze point, capture, returns, accept; one fresh floor on AC (about 3.5 to 4.5 hours); round 17 (brief, opponent,
complete, tally, final audit, STATUS); report to the user.

Standing rules: never change source during a reservation, and make no STATUS edit between the prereserve and
returned states; run no suite or test function in the live worktree except the formal capture, floor and gate
commands; NEVER source a file from tests/ (a suite file ends in t_run_all) and never source anything from tests/
with the live worktree as the working directory: extract a helper with awk into a scratch file; source the kernel
only inside bash -c, never in the tool's zsh; exploratory runs go in standalone copies with a before/after status
check, and any dev run gives its copy a TMPDIR ending in `/`; run any loop that uses printf '%b' escapes inside bash,
not the tool's zsh (zsh also aborts a whole command on an unmatched glob, and `echo ====` fails in zsh); inside an awk
program held in single quotes, never write an apostrophe, not even in a comment; read every exit back from its
receipt, never from a notification (session 17's notifications said 0 for receipts reading 1 three times); never
pipe into `grep -q` or `head` under pipefail where the producer's status matters; never pipe suites through tail; no
foreground command over 10 minutes (macOS has no `timeout`; background it); a script's own cleanup `rm -rf` inside
`bash -c` is blocked by a safety check, so write to a fresh directory instead. Do not edit a bash script while it is
running. Check disk, swap and AC power before and during long runs (a floor needs AC for 3.5 to 4.5 hours; floor
attempt 1 of session 17 failed only because macOS stepped the clock back 4 s during a fixture: r16-floor-1.note);
ask before reclaiming anything or stopping Docker; never touch taxipro-backend, sales-platform, Docker or vm_bundles.
The opponent subagent's file tool refuses the report path: persist the block it returns from its own transcript by
script and check it identical (opponent-round16.note). Reviewers may use throwaway containers of images already on
disk only within the recorded limits. Do not infer authorization for hosted CI, the 002 fix, the open-extent task,
reality-check round 2, commits, PRs or bypasses.
