Continue spec 003 in:
  /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (about 660 KB: fold lines over 1800 characters into a scratch copy, then
read it in ~50 KB ranges). Then re-derive the state with
  bash .specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/r22-handoff-state.sh
from the worktree root (bash, never sourced) and compare it to r22-handoff-state.txt (all but time, disk, power and
swap must be equal).

State at the stop (r22-handoff-state.txt, 2026-10-13T23:08:15Z):
- Source 567cb6e04411ca525cb059fc247ab7ac34b1c52718f969d3478734ee69a7228e, Decisions
  02b9cc4c234b16a29d4ae8df0f4758b849704388a39dd16647a9f29cd30b6ac5 (the freeze point r18-freeze.txt; Decisions are
  FROZEN by r18-decisions-2 through the floor and round 18's completion and tally). HEAD 0d55c62, no lock, no
  pending reservation, 17 sealed opponent rounds, 628 captures, analyzer 0 errors, tally opponent=17 blocking=34
  minor=14.
- T030o51, T030o52 and T030o53 are ACCEPTED on CAP-634-14RLF3 (returns 505b44cb…, 6289f739…, 0e8a0252…). The four
  repair files hash as r18-edits/post-apply-3.
- No floor is current: FLOOR-QCFkfi (source 54c64d83…) is historical. Round 18 is authorized (exit 0) by the
  2026-10-09T09:41:41Z waiver; round 19 is refused (exit 4).
- Session 20 stopped before the floor only because the Mac was on battery (the user unplugged it at 100%); the
  floor takes about 5 hours cold and r18-floor.sh refuses to start off AC.

Done in session 20 (receipts under notes/verification/reports/, indexed in STATUS's Handoff note):
- tgc-2's S03, S09 and S10 rows corrected (each completed its image on the next line, which no settled-test mutant
  can reach); R03, S07 and S08, listed by session 19 as equivalents, change a verdict and got rows; judge run 4 exit
  0 (29 mutants); tgc-2 applied (r18-apply-2); dev2 exit 0.
- Matrix v6 (r18-mutations.sh from r18-mutations-gen.py, 303 rows). Run 1 found D02, D04 and D11 (v5 rows the head
  bracket test changed): D04 got a row (tgc-3, r18-fixtures-judge-3, r18-apply-3), D02 is a kill by the 400-line
  timing row under a 900 s judge watchdog, D11 is an argued equivalent. dev3 exit 0 on the final tree. The run of
  record exit 0 in each shard: 213 kills and 57 over-corrections killed, 33 argued equivalents, 8 baselines.
- Freezing entry r18-decisions-2.md written (scratch, then live); freeze point; capture of record; returns; accepts;
  post-accept check.

Next, in order:
1. Re-verify the state. The Mac must be ON AC; check free disk and swap.
2. One fresh floor on AC, detached from the worktree root:
     r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
     nohup bash -c 'bash "$1/r18-floor.sh" 1 > "$1/r18-floor-1.wrapper.log" 2>&1; echo $? > "$1/r18-floor-1.wrapper.rc"' _ "$r" > /dev/null 2>&1 &
   Wait on r18-floor-1.wrapper.rc (a Monitor or a background until-loop under 2 h, re-armed), read r18-floor-1.rc
   back, watch power and disk (r18-floor-1.samples.log). About 5 hours.
3. r18-gate-step.sh validate FLOOR-<id>; r18-scope.sh FLOOR-<id> > r18-scope.log (rc to r18-scope.rc); worktree
   state prereserve (r18-worktree-state.sh prereserve); r18-gate-step.sh reserve FLOOR-<id>; worktree state reserved.
4. Finish the brief from opponent-round18-brief.draft.md (fill @@SOURCE@@, @@FLOOR@@, @@RESERVED@@ from
   ROUND-18/meta.nul, @@DISK@@, @@FLOORRUN@@ from the floor receipts, @@WRITTEN@@) as opponent-round18-brief.md, and
   dispatch the independent opponent (subagent type opponent) with it; if its file tool refuses the report, persist
   the block it returns from its transcript by script (pattern r17-persist-report.py) and check it byte-identical;
   resume it by message after a usage limit. Worktree state returned; r18-gate-step.sh complete; r18-gate-step.sh
   tally; r18-final-audit.sh (background, receipts); STATUS (neutral sections only until the next batch); the report
   to the user.
5. Under the standing instruction of 2026-10-07: on CHALLENGED, reproduce, and stop to ask on a choice between fixes
   with trade-offs; on CLEARED, stop and report.

Standing rules:
- Never change source during a reservation, and make no STATUS edit between the prereserve and returned states.
- Run no suite in the live worktree except the formal capture, floor and gate commands.
- Never source from tests/; source the kernel only inside bash -c.
- Exploratory runs go in standalone copies with a TMPDIR ending in `/` and a before/after status check.
- No apostrophes inside single-quoted awk programs; never pass awk a -v value holding a real newline (use ENVIRON).
- Read every exit back from its receipt. No foreground command over 10 minutes. Don't edit a running script.
  Anything that may run past 2 hours goes detached under nohup with receipts (tool background shells stop at 2 h).
- Check disk, swap and AC before and during long runs. Ask before reclaiming anything or stopping Docker.
- Stop and ask on a choice between fixes with trade-offs.
- No hosted CI, 002 fix, open-extent task, reality-check round 2, commits, PRs or bypasses without the user's
  authorization.
