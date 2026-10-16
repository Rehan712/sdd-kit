Continue spec 003 in:
  /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

The user wants this spec finished QUICKLY (approved 2026-10-14, recorded in STATUS → Open questions): keep only the
steps the tools require, and do not run the invoker's extra proof steps.

Read STATUS.md first. It is about 680 KB, so fold lines over 1800 characters into a scratch copy and read it in
~50 KB ranges. Read at least:
- the frontmatter;
- "Where things stand" (session 21's paragraph);
- the newest Open questions items: the two user decisions of 2026-10-14 and the round-18 findings;
- the Handoff note's session-21 receipts index;
- Next action (the session-21 "later" entry).
Then re-derive the state from the worktree root with bash, never sourced:
  bash .specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/r23-handoff-state.sh
Compare it to r23-handoff-state-3.txt. Everything but time, disk, power and swap must be equal.

State at the stop (r23-handoff-state-3.txt, 2026-10-14T23:48:01Z):
- Source 567cb6e04411ca525cb059fc247ab7ac34b1c52718f969d3478734ee69a7228e, Decisions
  02b9cc4c234b16a29d4ae8df0f4758b849704388a39dd16647a9f29cd30b6ac5 (still frozen by r18-decisions-2).
- HEAD 0d55c62, no lock, no pending reservation, 18 sealed opponent rounds, 649 captures.
- Analyzer 0 errors; tally opponent=18 blocking=36 minor=15.
- FLOOR-OgYGoP is current for that source. It will become historical once the batch below moves the source.
- Opponent round 18: CHALLENGED, 2 blocking + 1 minor, digest aeb8c870…, sealed and audited (59 PASS).
  - O-018 reopened: a backtick inside a GFM URL literal or a reference label hides a live tag.
  - O-025 new: a table cell hides a data-loss tier.
  - O-023 reopened, minor: link-led lines are re-read, about 30 s at 100 lines.
  - Reproduced in r19-repro (196 PASS).
  - Round 19 is refused (exit 4) until the batch writes its waiver.
- The user chose (2026-10-14): O-018 → the reviewer's M1, O-025 → M2 (refuse tables), O-023 → M3 (settle on either
  test). They also approved:
  1. dropping the extra proof steps (mutation matrix, two-way fixture judging, measurement script, repeated dev runs);
  2. a REQ-011 threat-model revision: rendering tricks inside a gate report are minor, not blocking;
  3. a hosted CI run plus reality-check round 2, on the same floor as round 19;
  4. deferring the retro (T034).
- Prepared and spot-checked on a copy, NOT applied live. Everything is under
  .specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/:
  - r19-edits/apply-code.py: the kernel, contract and two test files. It refuses unless they hash as
    r18-edits/post-apply-3.
  - r19-edits/apply-docs.py: the REQ-011 revision in spec.md and the T030o54-T030o56 blocks in tasks.md.
  - r19-edits/decisions-1.py <root> <UTC now>: round 18's outcome, the user's decisions, the reproduction, the
    revision, the tasks, the round-19 waiver and the freeze. It reads r19-dev receipts and refuses without them.
  - r19-dev.sh <scratch>: one full suite plus ShellCheck on a standalone copy with both apply scripts.
  - On the copy, every member was refused by name, every positive parsed, and 400 link-led lines took 0.32 s.

Next, in order (r = that reports directory):
1. Re-verify. The Mac must be ON AC; check free disk and swap (swap was 2.1 of 3.8 GB used at the stop).
2. The one dev run, in the background with receipts (about 40 min):
     date -u +%Y-%m-%dT%H:%M:%SZ > $r/r19-dev.time; bash $r/r19-dev.sh <scratch-dir> > $r/r19-dev.log 2>&1; echo $? > $r/r19-dev.rc; date -u +%Y-%m-%dT%H:%M:%SZ >> $r/r19-dev.time
   Read r19-dev.rc back. The log's last line must be `suites=N/N shellcheck_rc=0 run_rc=0`.
   - If a row fails, fix the row or the script in a copy first.
   - Ask only if the fix is a choice with trade-offs.
3. The batch:
   - First on a scratch copy, then live, in this order: decisions-1.py, then apply-docs.py, then apply-code.py.
     Save STATUS before the batch.
   - Then check: `spec-gate.sh waiver <spec> opponent 19` exits 0, `… 20` exits 4, sdd-analyze has 0 errors, and
     apply-code's printed hashes go to r19-edits/post-apply.sha256.
4. Freeze, capture and accept:
   - Freeze point: r19-freeze.sh, copied from r18-freeze.sh (T030o54-56, round 19/20, the new hashes).
   - Capture of record: `bash scripts/spec-run.sh <spec> T030o54 --from-task --no-tick --summary` to
     r19-capture.{log,rc,start,end}.
   - Returns: r19-return.sh, copied from r18-return.sh (T030o5[456], reading r19-capture).
   - Accept T030o54, T030o55 and T030o56, in that order: `bash scripts/spec-gate.sh accept <spec> <task>
     <spec>/notes/verification/returns/<task>.txt`, with receipts `<task>-accept.{log,rc}`.
5. Round 19:
   - Copy each r18 helper to an r19 version with 18→19, scoped against FLOOR-OgYGoP: r18-floor.sh,
     r18-gate-step.sh, r18-scope.sh, r18-worktree-state.sh, r18-final-audit.sh (the final audit expects digests 1-19
     and round 20 refused), r18-brief-fill.py and r18-persist-report.py.
   - One fresh floor on AC, detached under nohup with a wrapper rc (about 5 hours); watch power and disk.
   - Validate, scope, prereserve state, reserve round 19, reserved state.
   - Write the brief from opponent-round18-brief.md, updated: scope T030o54-56, plus the REQ-011 revision, which the
     reviewer may challenge.
   - Dispatch the independent opponent (subagent type `opponent`). Resume it by message after a usage limit, and
     check or persist its returned block.
   - Returned state, complete, tally, final audit in the background, STATUS (neutral sections only).
6. On CLEARED:
   - Run hosted CI on the current source with the established snapshot method: a temporary branch and PR closed
     unmerged; never switch the gh account.
   - Run reality-check round 2 on the same floor (no waiver needed). The AC-016 live probe needs a current opponent
     round, and AC-019 needs that CI.
   - Then ask the user about the guarded PR (spec-pr.sh), merge and rollout (T033).
   On CHALLENGED: reproduce the findings and report them. Ask only on a real choice; the user prefers the fastest
   recommended option.

Standing rules:
- Never change source during a reservation, and make no STATUS edit between the prereserve and returned states.
- Run no suite in the live worktree except the formal capture, floor and gate commands.
- Never source from tests/; source the kernel only inside bash -c.
- Exploratory runs go in standalone copies with a TMPDIR ending in `/` and a before/after status check.
- No apostrophes inside single-quoted awk programs; never pass awk a -v value holding a real newline (use ENVIRON).
- Read every exit back from its receipt. No foreground command over 10 minutes. Don't edit a running script.
- Anything that may run past 2 hours goes detached under nohup with receipts (tool background shells stop at 2 h).
- Check disk, swap and AC before and during long runs. Ask before reclaiming anything or stopping Docker.
- Avoid `rm` inside `bash -c` strings (a safety check blocks it); clean up from script files or by explicit path.
- The Bash tool runs zsh: quote words starting with `=`, and do not `cd` into subdirectories (the cwd persists).
- No 002 fix, open-extent task, commits to the spec branch, guarded PR, merge or bypass without the user's
  authorization. Hosted CI and reality-check round 2 are authorized, after round 19 clears.
