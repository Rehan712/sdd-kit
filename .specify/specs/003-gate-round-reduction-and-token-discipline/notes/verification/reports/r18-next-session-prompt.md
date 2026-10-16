Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (about 560 KB: fold lines longer than 1800 characters into a scratch copy
first, since the Read tool truncates long lines, then read it in ranges of about 50 KB; the Read tool's limit is 25k
tokens, and the Bash tool's output limit is about 30 KB). Then read, under notes/verification/reports/:
- r18-handoff-state.txt (the state at the stop; re-derive it with bash r18-handoff-state.sh, run from the worktree
  root with bash, never sourced into the tool's zsh)
- the round-16 record: opponent-round16.md (O-018 reopened blocking; O-022 new blocking, a regression of T030o47;
  O-023 new minor, degraded) with opponent-round16.note (how it was persisted)
- r16-floor-1.note (floor attempt 1 failed on a backward clock step during a fixture; attempt 2 sealed FLOOR-UW5FIE)
- the patterns for the next cycle: r15-repro.sh, r15-measure.sh, r15-decisions-1.md with r15-decisions-1-apply.sh,
  r15-task-block.md with r15-task-insert.sh, r16-fixtures-judge.sh, r16-apply-1.sh, r15-dev.sh, r15-mutations-gen.py,
  r16-decisions-2.md, r16-freeze.sh, r16-return.sh, r16-floor.sh, r16-gate-step.sh, r16-scope.sh,
  r16-worktree-state.sh, opponent-round16-brief.md, r16-final-audit.sh
- STATUS's session-17 paragraphs (Where things stand), the Open questions entries and Next action

Verified state at the stop (r18-handoff-state.txt, 2026-10-08T12:58:16Z):
- Source eee97354a5aa4069a44c3791db4b576486502299450a7d3a89739677ec949c12, Decisions
  29a29da2faf62450cf027155dafd416a530930edc5f2dc4103131d8a1caa823c (round 16's outcome deliberately NOT yet in
  Decisions), HEAD 0d55c62, no lock, no pending reservation, 16 sealed opponent rounds (round 16 fb9bcfb4...), 605
  captures, FLOOR-UW5FIE current for eee97354..., analyzer 0 errors, tally opponent=16 blocking=32 minor=13
  locations=455, T030o47 ticked, round 16 completed and round 17 refused at exit 4, the four repair files as
  r16-edits/post-apply-2.sha256.
- The user's standing instruction of 2026-10-07 (in Decisions): repair a CHALLENGED round's findings and rerun the
  opponent until all issues are resolved. Each further round gets its own exact-round waiver line in its repair's
  batch, validated on a scratch copy and live; stop and ask on a choice between fixes with trade-offs, a spec
  revision, a disk or power problem that needs reclaiming, or anything not authorized; report after each round.
- Session 17 asked the user how to repair round 16's findings. The user chose (STATUS Open questions, 2026-10-08):
  O-018, narrow the grammar (refuse raw HTML outside a code span, a lone CR and FF/VT lines inside a finding, in both
  readers, the code-span test on the refusing side; measured against history first, back to the user if anything
  recorded would be refused); O-023, drop settled candidates; O-022, one to six marks. Write this in the next
  Decisions batch, before any code.

Order (STATUS Next action): re-verify; reproduce round 16's members (CUR and PRE = CUR with r16-session.diff
reversed; both locales; both passes; direct and end to end; O-023 timed on runs of 50 to 200+ lines); measure the
chosen rules against the recorded history; one Decisions batch with round 16's outcome, the decision, the
reproduction, the rules, the task blocks and the round-17 waiver (text in Next action); fixtures judged both ways;
apply after a hash check; dev runs; matrix v5; freeze; capture; accept; one fresh floor on AC; round 17; report.

Standing rules: never change source during a reservation, and make no STATUS edit between the prereserve and
returned states; run no suite or test function in the live worktree except the formal capture, floor and gate
commands; NEVER source a file from tests/ (a suite file ends in t_run_all) and never source anything from tests/
with the live worktree as the working directory: extract a helper with awk into a scratch file; source the kernel
only inside bash -c, never in the tool's zsh; exploratory runs go in standalone copies with a before/after status
check, and any dev run gives its copy a TMPDIR ending in `/`; run any loop that uses printf '%b' escapes inside bash,
not the tool's zsh (zsh also aborts a whole command on an unmatched glob); inside an awk program held in single
quotes, never write an apostrophe, not even in a comment; read every exit back from its receipt, never from a
notification; never pipe into `grep -q` or `head` under pipefail where the producer's status matters; never pipe
suites through tail; no foreground command over 10 minutes (macOS has no `timeout`; background it). Do not edit a
bash script while it is running. Check disk, swap and AC power before and during long runs (a floor needs AC for
3.5 to 4.5 hours); ask before reclaiming anything or stopping Docker; never touch taxipro-backend, sales-platform,
Docker or vm_bundles. The opponent subagent's file tool refuses the report path: persist the block it returns from
its own transcript by script and check it identical. Reviewers may use throwaway containers of images already on
disk only within the recorded limits. Do not infer authorization for hosted CI, the 002 fix, the open-extent task,
reality-check round 2, commits, PRs or bypasses.
