Continue spec 003 in /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline (branch
spec/003-gate-round-reduction-and-token-discipline, HEAD 2049f65, draft PR https://github.com/Rehan712/sdd-kit/pull/20). Read
STATUS.md first: its Next action entry "2026-10-16 (session 23, after round 20)" and the top Open questions items are the plan.
Receipts are under r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports.

Where it stands (2026-10-16): T031a1 to T031a4 accepted (CAP-678-tyxcke); FLOOR-UeGEcf sealed; opponent round 20 CHALLENGED
(1 blocking + 3 minor, digest 8630890b…, final audit 70 PASS): O-029 (blocking) — round_legacy_reconcile_cases cannot fail when
the reconciled timestamp, the round/digest check, or all legacy binding is removed (reproduced, r20-repro-o029.*); O-030 and
O-031 minor (test-only); O-032 degraded (kernel diagnostics, follow-up spec). By my decisions of 2026-10-15/16
(r20-user-decision-2.txt, r20-user-decision-3.txt) reality-check round 3 was skipped, all 003 work was committed (2049f65) and
the draft PR opened with spec-pr.sh --force --draft. Not yet in Decisions (frozen at ff60b48b…): round 20's outcome and those
two decisions. Uncommitted: STATUS's pr: line and the r20-pr/r20-gh-accounts receipts. The commit moved the source identity
to 3e13d844…, so FLOOR-UeGEcf is historical.

I authorize opponent round 21 for this repair, and commits plus pushes of this work to the PR branch. Finish FAST: keep only
the steps the tools require; skip the invoker's extra proof steps (no mutation matrix, no two-direction fixture judging, no
separate measurement scripts, no repeated dev runs) — except that each new O-029 assertion must be shown killed by one of the
reviewer's three mutants in the one dev run, since that is the finding. Minor findings of either gate do not stop the sequence.

Steps:
1. Entry: `bash $r/r20-freeze.sh` must equal `$r/r25-handoff-state.txt` except `taken=` (and check disk, swap, AC; another
   session's builds in ~/projects/memvault filled the disk on 2026-10-15, so check free disk before and during long runs).
2. Write the fixes, test files only, in a standalone copy: O-029 (T031a4o1) in round_legacy_reconcile_cases — before the valid
   reconcile, a wrong digest, a wrong round and a timestamp before the history's date each exit 3, write no legacy-time.nul and
   leave the next round refused; after it, a waiver dated 2026-07-20 before 23:59:59Z refused with `not after the previous round
   completion at 2026-07-20T23:59:59Z`; after editing the history, neither waiver nor round authorizes or reserves. O-030
   (T031a1o1): an empty `Failure modes:` header for the no-row task refused with `empty required set must explicitly be none`,
   tasks.md byte-identical. O-031 (T031a3o1): hash each file tally reads before and after the run. Start from round 20's report
   ($r/opponent-round20.md) and r20-repro-o029.sh. One dev run there (r21-dev.*: tests/run.sh and tests/shellcheck.sh exit 0,
   plus the three O-029 mutants each killing an assertion).
3. One batch following the r20 pattern (r21-edits/{decisions-1,apply-docs,apply-code}.py, r21-batch-apply.sh), scratch then
   live: Decisions gets round 20's outcome and the reproduction, my decisions of 2026-10-15 (no hosted CI while the Actions
   limit holds; minor findings do not stop; draft PR with --force; commit and push) and 2026-10-16 (draft PR now, fix O-029 on
   the PR branch before merge), the T031a4o1/T031a1o1/T031a3o1 task blocks with the dev run, the round-21 waiver
   (gate=opponent; round=21; after=20; by=Rehan712; reason=...) and a freezing entry; tasks.md gets the three blocks.
4. Freeze point, one capture of record, returns, `spec-gate.sh accept` for the three tasks.
5. One floor on AC power, detached under nohup with receipts (about 4-5 h); validate; scope against FLOOR-UeGEcf.
6. Opponent round 21: prereserve state, reserve, brief (from opponent-round20-brief.draft.md), dispatch the `opponent`
   subagent, persist from its transcript (r20-persist-report.py pattern), returned state (byte-identical), complete, tally,
   final audit, STATUS (neutral sections only).
7. On CLEARED: check whether my GitHub Actions limit has reset (ask me if unsure). If it has, hosted CI for the exact source
   (the snapshot method in platforms/ci-20261015/ with collect-2.sh's --allow-escape-sequences, or the PR's own CI after a
   commit and push, whichever leaves the source identity matching); then the T029 control on the new floor's T029 capture
   (rc3-step.sh control, before the rc3-prereserve state), reality-check round 3 (rc3-step.sh, rc3-brief-fill.py,
   reality-check-round3-brief.draft.md, rc3-persist-report.py, rc3-final-audit.sh; no waiver needed), complete, tally, final
   audit. Then commit and push to the PR branch. On READY: ask me before marking PR #20 ready and about the merge and rollout
   (T033). T034 (retro) stays deferred. If CI is still limited: run reality-check round 3 anyway, commit and push, and stop.
   On CHALLENGED or NEEDS WORK beyond minor findings: reproduce, record neutrally, and ask me only on a real choice, with the
   fastest recommended option first.

Standing rules: never change source during a reservation, and no STATUS edit between a prereserve and returned state. Run no
suite in the live worktree except the formal capture, floor and gate commands. Never source from tests/; source the kernel only
inside bash -c. Exploratory runs go in standalone copies with a TMPDIR ending in `/` and a before/after status check. No
apostrophes inside single-quoted awk programs; never pass awk a -v value holding a newline (use ENVIRON). Read every exit back
from its receipt. No foreground command over 10 minutes; anything that may run past 2 hours goes detached under nohup with
receipts. Check disk, swap and AC before and during long runs; ask before reclaiming anything or stopping Docker or another
session's processes. Avoid rm inside bash -c strings. The Bash tool runs zsh: quote words starting with `=`, and use
/usr/bin/grep. No 002 fix, open-extent task, round-19 follow-ups F1-F4, O-032 kernel change, merge or bypass without my
authorization. Pushes and PR operations as Rehan712 only via a process-scoped GH_TOKEN="$(gh auth token -h github.com -u
Rehan712)"; never switch the active gh account; never print the token. Commit messages end with `Co-Authored-By: Claude Opus
5.5 <noreply@anthropic.com>`; PR bodies end with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
