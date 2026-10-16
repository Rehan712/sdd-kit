Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (about 530 KB: fold lines longer than 1800 characters into a scratch copy
first, since the Read tool truncates long lines, then read it in ranges of about 50 KB; the Read tool's limit is 25k
tokens, and the Bash tool's output limit is about 30 KB). Then read, under notes/verification/reports/:
- r17-handoff-state.txt (the state at the stop; re-derive it with bash r17-handoff-state.sh, run from the worktree
  root with bash, never sourced into the tool's zsh)
- the round-15 record: opponent-round15.md (O-018 reopened blocking; O-020 and O-021 resolved)
- the last two Decisions entries' companions: r15-decisions-1.md (the T030o47 batch as written, with the round-16
  waiver) and r16-decisions-2.md (the freezing entry: X12 relabelled a kill, L17's isolating footnote row)
- the prepared, unrun round-16 files: r16-floor.sh, r16-gate-step.sh, r16-scope.sh, r16-worktree-state.sh and
  opponent-round16-brief.draft.md (pattern r15-final-audit.sh for a new r16-final-audit.sh)
- STATUS's session-16 paragraph (Where things stand), the Open questions entries and Next action

Verified state at the stop (r17-handoff-state.txt, 2026-10-07T23:20:39Z):
- Source eee97354a5aa4069a44c3791db4b576486502299450a7d3a89739677ec949c12, Decisions
  29a29da2faf62450cf027155dafd416a530930edc5f2dc4103131d8a1caa823c (FROZEN through round 16's completion and tally),
  HEAD 0d55c62, no lock, no pending reservation, 15 sealed opponent rounds (round 15 241cebc5...), 583 captures,
  analyzer 0 errors, tally opponent=15 blocking=30 minor=12 locations=439, T030o47 ACCEPTED (CAP-589-ZNd9Ug, return
  2a8d2a94...), round 16 AUTHORIZED (waiver 2026-10-07T21:10:41Z) at exit 0 and round 17 refused at exit 4, the four
  repair files as r16-edits/post-apply-2.sha256. NO floor is current: FLOOR-dCwGgb belongs to c9f2b616... .
- The user's standing instruction of 2026-10-07, now in Decisions: "if comes back challenged then fix the issues and
  rerun round 16 until all issues been resolved". Each further round gets its own exact-round waiver line in its
  repair's batch, validated on a scratch copy and live; stop and ask on a choice between fixes with trade-offs, a spec
  revision, a disk or power problem that needs reclaiming, or anything not authorized; report to the user after each
  round.
- Session 16 stopped at the user's request before the floor: the Mac was going on battery overnight, and the user
  chose to run only what fitted in about 3 hours.

Order (STATUS Next action):
1. Re-verify the state (bash r17-handoff-state.sh); it must match the above but time, disk, power and swap. Check
   disk, swap AND AC power: r16-floor.sh refuses to start off AC (exit 98), and a floor takes about 4.5 hours.
2. One fresh floor on AC, launched detached from the worktree root with
   r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports:
   nohup bash -c 'bash "$1/r16-floor.sh" 1 > "$1/r16-floor-1.wrapper.log" 2>&1; echo $? > "$1/r16-floor-1.wrapper.rc"' _ "$r" > /dev/null 2>&1 &
   then wait on r16-floor-1.wrapper.rc and read r16-floor-1.rc back. Check power and disk during it.
3. Validate (r16-gate-step.sh validate FLOOR-<id>), scope against FLOOR-dCwGgb (r16-scope.sh FLOOR-<id> into
   r16-scope.{log,rc}), worktree state prereserve, reserve round 16 (r16-gate-step.sh reserve FLOOR-<id>), state
   reserved. No STATUS edit between prereserve and returned.
4. Finish the brief from opponent-round16-brief.draft.md (reservation values from ROUND-16/meta.nul, free disk, the
   acceptance evidence for @@EVIDENCE@@), dispatch the independent opponent (if its file tool refuses the report file,
   persist the block it returns and check it byte-identical; if a usage limit stops it, resume it with SendMessage
   after checking the worktree is unchanged), state returned, complete, tally, final audit, STATUS, report to the user.
5. Under the standing instruction: on CHALLENGED, repeat the cycle (round 17's waiver in its batch); on CLEARED, stop
   and report.

Standing rules: never change source during a reservation, and make no STATUS edit between the prereserve and
returned states; run no suite or test function in the live worktree except the formal capture, floor and gate
commands; NEVER source a file from tests/ (a suite file ends in t_run_all) and never source anything from tests/
with the live worktree as the working directory: extract a helper with awk into a scratch file; source the kernel
only inside bash -c, never in the tool's zsh; exploratory runs go in standalone copies with a before/after status
check, and any dev run gives its copy a TMPDIR ending in `/`; run any loop that uses printf '%b' escapes inside bash,
not the tool's zsh; inside an awk program held in single quotes, never write an apostrophe, not even in a comment;
read every exit back from its receipt, never from a notification (twice in session 16 a notification said 0 for a
receipt reading 1); never pipe into `grep -q` or `head` under pipefail where the producer's status matters; never
pipe suites through tail; no foreground command over 10 minutes (macOS has no `timeout`; background it). Do not edit
a bash script while it is running. Check disk, swap and AC power before and during long runs; ask before reclaiming
anything or stopping Docker; never touch taxipro-backend, sales-platform, Docker or vm_bundles. Reviewers may use
throwaway containers of images already on disk only within the recorded limits. Do not infer authorization for
hosted CI, the 002 fix, the open-extent task, reality-check round 2, commits, PRs or bypasses.
