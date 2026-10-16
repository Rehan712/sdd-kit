Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (about 600 KB: fold lines longer than 1800 characters into a scratch copy
first, since the Read tool truncates long lines, then read it in ranges of about 50 KB; the Read tool's limit is 25k
tokens, and the Bash tool's output limit is about 30 KB). Then read, under notes/verification/reports/:
- r20-handoff-state.txt (the state at the stop; re-derive it with bash r20-handoff-state.sh, run from the worktree
  root with bash, never sourced into the tool's zsh)
- the round-17 record: opponent-round17.md (O-018 reopened and blocking, O-024 new and blocking, O-023 reopened and
  minor) with opponent-round17.note, r17-complete.log, r17-tally.log, r17-final-audit.log
- session 18's work, for the patterns of the next cycle: r17-decisions-1.md with r17-decisions-1-apply.sh and
  r17-decisions-fill.sh, r17-task-blocks.md with r17-task-insert.sh, r17-apply-1.sh and r17-apply-2.sh, the
  exploratory r17-discover.sh with r17-discover-mutants.py and r17-rows-probe.sh, r17-edits/build-fixtures-2.py,
  r17-fixtures-judge-2.sh, r17-mutations-gen.py (matrix v5, 227 rows), r17-decisions-2.md with
  r17-decisions-2-apply.sh, r17-freeze.sh, r17-return.sh, r17-floor.sh, r17-gate-step.sh, r17-scope.sh,
  r17-worktree-state.sh, r17-persist-report.py, opponent-round17-brief.md, r17-final-audit.sh
- STATUS's session-18 paragraphs (Where things stand), the Open questions entries for round 17, and Next action

Verified state at the stop (r20-handoff-state.txt): Decisions frozen at
b5c78e14a2ac1ae41f43ef2c2168311c1e1376e214edebaac94da1c1a4ccb6ec (round 17's outcome deliberately NOT yet in
Decisions), source 54c64d8346fe2459204e68de298f193bb5ea0abe8de86c00de159f05eac07129, HEAD 0d55c62, no lock, no
pending reservation, 17 sealed opponent rounds (round 17 f94bb2e5...), FLOOR-QCFkfi current for 54c64d83..., 627
captures, analyzer 0 errors, tally opponent=17 blocking=34 minor=14 locations=474, T030o48, T030o49 and T030o50
ticked, round 17 completed and round 18 refused at exit 4.

Round 17 (CHALLENGED, 2 blocking + 1 minor) and the choices the user must make FIRST (the standing instruction of
2026-10-07 stops on a choice between fixes with trade-offs; ask, with a recommendation, before any repair):
- O-018 reopened (wrong-result): a backtick inside an email autolink whose local part starts with a digit
  (`<1`@a.b>`), a link destination or a link title pairs with a later backtick into a code span the renderers do not
  form, so a live tag after it reads as inside a span and a visible tier seals a CLEARED round. Options: (a) place code
  spans after autolinks and link destinations and titles (the reviewer's M1: a reading that masks backticks inside
  those segments); (b) narrow further, in line with the user's 2026-10-08 decision: inside a finding refuse by name a
  backtick inside an autolink, link destination or title, and a `<` followed by any character that may start an
  autolink. The invoker's recommendation: (b), measured against the history first.
- O-024 new (wrong-result, plan-gap): a finding's extent and the lines a reader sees come from readings a renderer
  does not share: a fence opened after a list marker hides a `### x` line the passes read as closing the finding, and a
  link reference definition renders nothing yet carries a Severity field line. Options: (a) narrow (the reviewer's M2:
  refuse by name inside a finding a fence opened after a list marker and a link reference definition); (b) derive the
  finding's extent from the constructs a renderer opens. Recommendation: (a).
- O-023 reopened (degraded): one bracket quoted in a code span keeps a candidate unsettled for a whole run (42.7 s at
  200 lines, 305 s at 400). Fix (the reviewer's M3): settle on the constructs that open at or before each reading's
  first word; add a 400-line timing row. Little trade-off.
- Minor, non-blocking: the narrowed check is judged before the line's own heading opens or closes a finding (off by
  one heading at both ends). Fold in or record.

Then, under the standing instruction: reproduce round 17's findings before any repair (CUR and PRE = CUR with
r17-session.diff reversed, both passes, both locales, direct and end to end); measure the chosen rules against the
recorded history and the full suite; write ONE Decisions batch before any code (round 17's outcome, the user's
choices, the reproduction, the rules with their measurement, the task blocks T030o51 (O-018), T030o52 (O-024),
T030o53 (O-023), and the round-18 waiver stamped at writing time after round 17's completion 2026-10-09T07:55:51Z, in
byte mode: `- <UTC now> — waiver: gate=opponent; round=18; after=17; by=Rehan712; reason=user instructed on
2026-10-07 to repair the findings of a CHALLENGED round and rerun the opponent until all issues are resolved, so round
18 assesses the repairs of round 17's O-018, O-024 and O-023 against a fresh floor sealed after those repairs are
accepted`), validated on a scratch copy and live (round 18 exit 0, round 19 exit 4, analyzer 0 errors); fixtures
judged in both directions; apply after a hash check; dev runs; matrix v6 from r17-mutations-gen.py (a row per new
guard; use the discovery probe first so every row names a fixture that kills it); a freezing entry; freeze point;
capture; returns; accepts; one fresh floor on AC (this session's took 4h47m, 21 executed and 62 reused; the user
unplugged the Mac for part of it); round 18 (brief from opponent-round17-brief.md, opponent, persist from its
transcript, complete, tally, final audit, STATUS); report to the user.

Standing rules: never change source during a reservation, and make no STATUS edit between the prereserve and
returned states; run no suite or test function in the live worktree except the formal capture, floor and gate
commands; NEVER source a file from tests/; source the kernel only inside bash -c, never in the tool's zsh; exploratory
runs go in standalone copies with a before/after status check, and any dev run gives its copy a TMPDIR ending in `/`;
run any loop that uses printf '%b' escapes inside bash; inside an awk program held in single quotes, never write an
apostrophe; read every exit back from its receipt, never from a notification; never pipe into `grep -q` or `head`
under pipefail where the producer's status matters; never pipe suites through tail; no foreground command over 10
minutes (background it); do not edit a bash script while it is running (edit the generator, regenerate after). A
matrix literal must match exactly once: a new function that repeats a line makes a carried literal ambiguous (dry-run
first). Check disk, swap and AC power before and during long runs; ask before reclaiming anything or stopping Docker;
never touch taxipro-backend, sales-platform, Docker or vm_bundles. The opponent subagent's file tool refuses the
report path: persist the block it returns from its own transcript with r17-persist-report.py (adapted) and check it.
If a usage limit stops the opponent, resume the same agent after the reset. Do not infer authorization for hosted CI,
the 002 fix, the open-extent task, reality-check round 2, commits, PRs or bypasses.
