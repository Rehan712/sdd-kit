Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (about 400 KB: read it in line ranges; the Read tool's limit is
25k tokens, and the Bash tool's output limit is about 30 KB). Then read, under notes/verification/reports/:
- t030o43-handoff-state-10.txt (the state at the stop; re-derive it with bash t030o43-handoff-state-10.sh,
  run from the worktree root with bash, never sourced into the tool's zsh)
- the four Decisions entries of session 10 (the last four, dated 2026-09-30: the failed capture of record and
  the user's decisions; the TMPDIR rule as measured; the task-block correction; the proof, which FREEZES
  Decisions) and the T030o43 task block in tasks.md (now ticked)
- the failed capture and its repair: t030o43-capture.{log,rc,start,end} (CAP-521-Q8OdIp, rc 1; the task
  notification said 0), t030o43-tmpdir-repro.{sh,log,rc,note}, t030o43-measure-11.sh with -11a.* and
  -11full.* and t030o43-measure-11-*.log, t030o43-o010-precheck.* (-run1, -run2 kept), r13-disk-reclaim-2.*,
  t030o43-decisions-10{,b}.md with t030o43-decisions-10{,b}-{scratch,live}.*, t030o43-apply-10.*,
  t030o43-edits/ (session 10's pairs: helpers-1, tv-5, vc-6, kernel-8, tasks-fix-6), t030o43-session10.diff,
  t030o43-final.diff (session 9's kept as -9.diff) with t030o43-final-10.*
- the proof: t030o43-dev10.sh with t030o43-dev8-{full,full-locale}.* (rc 0 each, every run under a TMPDIR
  ending in `/`); matrix v5 t030o43-mutations.sh (153 rows; v4 kept as -v4.sh) with -v5-dry.*, -v5-probe.*,
  -v5-shard{0,1}.{log,rc,start,end} (exit 0 each: 142 kills, 11 argued equivalents, 8 baselines)
- the acceptance: t030o43-freeze-2.txt, t030o43-capture-2.{log,rc,start,end} (CAP-522-PgNdFn, rc 0),
  t030o43-return-2.sh with t030o43-return-validate.{log,rc}, T030o43-accept.{log,rc}, t030o43-postaccept.txt
- opponent-round13-brief.draft.md (session 9's kept as -draft-9.md): fill Source, Floor (three places), the
  reserved time and the free disk from the reservation, and check every claim in it against the receipts
- prepared, not run: r13-floor.sh, r13-scope.sh, r13-worktree-state.sh, r13-final-audit.sh

Verified state at the stop (2026-09-30T17:45Z, t030o43-handoff-state-10.txt):
- T030o43 (O-017 repair) is ACCEPTED: CAP-522-PgNdFn, `bash tests/run.sh && bash tests/shellcheck.sh` at
  147/147 over 15 suites plus ShellCheck, return 3887a0822310cd47aa4fc9611da5b51d2fadefc06fdc2cf82224ab587a5dbcd5.
  The first capture, CAP-521-Q8OdIp, failed (rc 1) because macOS's TMPDIR ends in `/` while every dev run and
  matrix copy had written it without; the user chose the class-wide repair (tests/helpers.sh exports TMPDIR as
  the physical path of its directory, with its fixture, and the contract sentence and kernel comment corrected),
  which was measured, recorded, applied and proven before the second capture.
- Decisions are FROZEN (the last 2026-09-30 entry) through the floor, and round 13's completion and tally;
  results go to the neutral STATUS sections only.
- Round 13 AUTHORIZED by the recorded waiver 2026-09-27T15:55:36Z (round 13 exits 0, round 14 exits 4).
  No floor is current: FLOOR-0334B2 is historical.
- Source 24828d54ee3b743533467e880ce81eb33deec5f1429dea750f4380a899bba145, Decisions
  debe4e6a124487d02d43fd8c4c7f81dbd2d193e6540f2892a222c2406c54a922, HEAD 0d55c62, no lock, no pending
  reservation, 516 captures, analyzer 0 errors. T030-T034 unticked; T030o39-T030o43 ticked.
- Host at the stop: ON BATTERY since 15:02:45Z (62%), free disk 16 GiB, swap 2.4/3.0 GB. The user authorized
  removing $TMPDIR/cdk.out* this session (done, r13-disk-reclaim-2.*); ask again before removing anything
  else, and never touch taxipro-backend, sales-platform, Docker or vm_bundles.

Order:
1. Re-verify the state (bash t030o43-handoff-state-10.sh); it must match the above. Check disk, swap and AC
   power (pmset -g batt). The floor needs AC: if the Mac is on battery, ask the user to plug in and wait.
2. One fresh floor ON AC: bash r13-floor.sh 1 from the worktree root, in the background (it refuses off AC;
   about 4 h, cold); read r13-floor-1.rc back and watch r13-floor-1.samples.log for power and disk. Validate
   it current in the background (vf_floor_validate <spec> <FLOOR-id>, about 12 min) with receipts
   r13-floor-validate.{out,err,rc,time}: the output must equal the source above and stderr be empty.
3. Scope: bash r13-scope.sh <FLOOR-id> (receipts r13-scope.{log,rc}).
4. bash r13-worktree-state.sh prereserve; reserve round 13 in the background
   (bash scripts/spec-gate.sh round <spec> opponent --floor <FLOOR-id>, about 12 min; receipts
   r13-reserve.{log,rc,time}); bash r13-worktree-state.sh reserved.
5. Finish opponent-round13-brief.md from the draft (values from rounds/opponent/ROUND-13/meta.nul), and
   dispatch the independent opponent with that path-based brief. Its report,
   notes/verification/reports/opponent-round13.md, must carry the reservation's Source and Floor and end with
   the exact line <!-- gate-round-end: opponent:13 -->.
6. bash r13-worktree-state.sh returned (the three states must be byte-identical); complete in the background
   (bash scripts/spec-gate.sh round <spec> opponent --complete <spec>/notes/verification/reports/opponent-round13.md;
   receipts r13-complete.{log,rc,time}); tally (r13-tally.{log,rc}); final audit in the background
   (bash r13-final-audit.sh; receipts r13-final-audit.{log,rc}); update the neutral STATUS sections; stop.

Standing rules: never change source during a reservation, and make no STATUS edit between the prereserve and
returned states; run no suite or test function in the live worktree except the formal capture, floor and gate
commands; exploratory runs go in standalone copies with a before/after status check, and any dev run gives
its copy a TMPDIR ending in `/` (t030o43-dev10.sh), as the formal commands see it; read every exit back from
its receipt, never from a notification (CAP-521's said 0, its receipt 1); never pipe suites through tail; no
foreground command over 10 minutes (macOS has no `timeout`; background it); do not edit a bash script while it
is running; perl -0pi with an exit in its code truncates the file, and perl interpolates $0 even inside
\Q...\E (use a literal replacement helper). Check disk, swap AND AC power before and during long runs, and ask
before reclaiming anything or stopping Docker. Do not infer authorization for hosted CI, the 002 fix, the
open-extent task, reality-check round 2, round 14, commits, PRs or bypasses.
