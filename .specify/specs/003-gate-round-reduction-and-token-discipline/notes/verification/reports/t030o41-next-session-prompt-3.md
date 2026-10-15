Continue spec 003 in:
  /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST, especially every 2026-09-24 Decisions entry (the last four
are this session's: the user's AC-023/push decisions, the second review pair's outcome with the user's
scope decisions, the derived repairs, and the incomplete review-3 outcome), plus "Where things stand",
"Open questions", "Handoff note" and "Next action". Then read, under notes/verification/reports/:
- t030o41-review2-pass{C,D}.md and t030o41-review2-verify{,-c}.{sh,log,rc,note} (second pair, reproduced)
- t030o41-session3.diff (this session's delta, 15 files) and t030o41-dev8-full.{log,rc} (142/142, exit 0)
- t030o41-review3-brief.md, t030o41-review3-partial.md (INCOMPLETE: reviewer hit the session limit),
  t030o41-review3-verify-r31.log and t030o41-review3-verify.{sh,log,rc} (R3-1..R3-3 reproduced)
- t030o41-mutations.sh (matrix v2, dry run only: t030o41-mutations-v2-dry.{log,rc}, 62 PASS)
- t030o41-handoff-state-3.txt

State at handoff (2026-09-24T20:46Z, read back from the scripts): source
0ab7f1236538080c432db57d65abf1d6c54c83b46ec6eff946f92595d590c4c5, Decisions
b7c824037432a9fe5c7ea839eb3a57ac81f562448a0cc8fb4bdb38118e4faedf, HEAD 0d55c62, analyzer 0 errors with the one
task-count warning, round 11 refused at exit 4, no lock, no reservation. T030 and T030o41 unticked; T030-T034
unticked. No commit, PR or round-11 authorization. Decisions is still OPEN.

User decisions already recorded in Decisions (do not re-ask): AC-023's narrowed reading is accepted (no
spec/plan change; the analyzer field-grammar defect stays open); F4 (git's repository-local environment) is
INCLUDED in T030o41; the harness-level bash startup environment (BASH_ENV/ENV/SHELLOPTS/BASHOPTS/exported
functions read by `bash -o pipefail -c`) is RECORDED, not repaired, for a later plan-level decision. The
advance hosted-CI push approval LAPSED because code changed: ASK AGAIN before pushing.

Open findings to repair first (all verified; proposals in the last Decisions entry, decide and record
BEFORE editing code):
- R3-1 (blocking regression of this session's delta): vf_snapshot clears git's local names for its whole
  subshell, so a DECLARED verification_environment name among them is hashed "unset". Proposed: clear them
  only in one inner subshell around vf_snapshot's git block, so environment records read ambient values.
  Add a fixture: a declared git-local name (e.g. GIT_PREFIX) with two values must give two identities.
- R3-3 (blocking): the XDG fixture in reuse_command_input_cases must pin all of git's global configuration
  (also GIT_CONFIG_GLOBAL and GIT_CONFIG_SYSTEM), not a subset.
- R3-2 (minor): the golden-example and dispatch host-kit fixtures cannot fail on the real pre-delta lines
  (`cp -R "$EXAMPLE" ...`, `cp -R "$SCRIPTS" ...`) because those read load-time globals; derive copy
  sources from KIT_DIR at call time; matrix K43/K44 must use the exact pre-delta lines.
- R3-4 (minor): sixth live-kit copy `cp "$SCRIPTS/"*.sh` at tests/test-gate-contracts.sh:1596
  (gate_dispatch_grammar_cases) -> copy_kit; re-derive the member set by searching every read of
  $KIT_DIR/$SCRIPTS/$EXAMPLE that names a directory or glob; correct "five sites"/contract/task wording.

Remaining order (do not skip or reorder):
1. Re-verify the state above from the scripts (not this prompt), including `spec-gate.sh waiver <spec>
   opponent 11` refused at exit 4.
2. Record the R3 repair decisions in Decisions, then repair R3-1..R3-4; re-run the affected fixtures and
   the full suite + ShellCheck in a standalone copy (pattern: t030o41-dev8.sh under a new receipt name).
3. Update matrix v2 (mutants for every new guard, exact pre-delta lines for K43/K44, the R3-1 fixture),
   dry-run it, then rerun ONE focused independent review of the final delta (read-only, private copy,
   progressive report file outside the copy). Verify every claim yourself before acting; if code changes,
   record the reason in Decisions first and repeat this step.
4. Run the matrix for real in the background with receipts (log + rc read back). Every kill/over mutant
   KILLED, every equiv SURVIVES, restores cmp-checked.
5. Record the matrix result and the review outcome in Decisions, then FREEZE Decisions.
6. Capture and accept T030o41 (spec-run.sh --from-task --no-tick --summary; assemble the
   Verification-Return block: Verification-Return: 1 / Task / Captures / Summary / Failure modes with one row
   per FM/INV against every task locator whose family covers it: FM-002 -> test_verification_bindings and
   test_instruction_contracts; FM-010, FM-014, INV-001 -> test_capture_provenance; FM-019, INV-006 ->
   test_reports_and_tally and test_instruction_contracts; validate before spec-gate.sh accept). Verify is
   `bash tests/run.sh && bash tests/shellcheck.sh`.
7. Hosted CI by the snapshot-PR route (throwaway branch on Rehan712/sdd-kit, draft do-not-merge PR, logs
   retained, PR closed and branch deleted), ONLY after asking the user again. Confirm ShellCheck 0.9 on
   Ubuntu accepts --norc, and the case-sensitive Linux branch of the new fixtures.
8. One fresh floor. Check disk and swap FIRST (at handoff: 9.3 GiB free, swap 6.8/7.2 GB used; the last
   floor bottomed at 5.41 GiB; Docker runs another project's mv-localstack). Ask before reclaiming anything.
9. Stop. Round 11 needs its own exact-round waiver approved by the user, validated before and after writing.

Standing rules: record Decisions and task definitions BEFORE refreshing proof; never change source during a
reservation; preserve sealed history; RUN NO SUITE OR TEST FUNCTION IN THE LIVE WORKTREE except the formal
capture/floor commands; use standalone copies and check their `git status --ignored` before and after; do
not write new files into reports/ while a dev run that checks the live status digest is running; never pipe
suites through tail or infer success from a trailing command or a background-task notification (twice this
session a notification said exit 0 for a receipt reading 1); read every exit back from its receipt. Until
O-015 is accepted and gated, do not tick T030 or write Evidence/frontmatter text stating the superseded
environment membership. zsh: brace "${var}:ref"; run multi-step scripts under bash. GitHub writes:
process-scoped GH_TOKEN="$(gh auth token -h github.com -u Rehan712)", never switch the active account.
Reviewers have died on the session limit twice: give them a progressive report file outside their copy.
Do not infer authorization for repairs beyond T030o41's recorded scope, additional gates, a round-11
waiver, commits, PRs or bypasses from this prompt.
