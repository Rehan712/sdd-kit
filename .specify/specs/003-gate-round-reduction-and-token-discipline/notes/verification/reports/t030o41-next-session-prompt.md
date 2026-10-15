Continue spec 003 in:
  /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST, especially every 2026-09-24 Decisions entry and the
"Where things stand", "Open questions" and "Next action" sections. Then read, under
notes/verification/reports/:
- o015-repro.{sh,log,rc} (reproduction before repair, exit 0, 64 checks)
- t030o41-review.md (first review pair A+B, the invoker's verification, and the stack.yml INCIDENT)
- t030o41-review2-brief.md (brief for the second review pair, which has NOT run)
- t030o41-session2.diff (every source change of this repair against the pre-repair tree, 16 files)
- t030o41-mutations.sh (the matrix of record, NOT yet run for real; its DRY=1 run passed 47/47 literals)
- t030o41-dev7.{log,rc} and t030o41-handoff-state.txt

Verified state at handoff (2026-09-24, read back from receipts and live checks):
- User decisions, all recorded in Decisions before any repair: option 1 (repair O-015 as T030o41,
  including the anchor-layout isolation fixture), then ONE task over two, then EXPAND the task to every
  measured member. T030o41's task block and T027's Verify were updated accordingly.
- Source aaba009243f3661c08769ab63b27186bdb8f8ed0b330eaec982e6bd8fafb7ea4, Decisions
  73b31d4928e2ce193e1c7d04006c24638aa734727dd77a0c4a64913cd2320e40, HEAD 0d55c62, analyzer 0 errors with
  the one task-count warning. FLOOR-qQEv7w is HISTORICAL. T030o41 unticked; T030-T034 unticked. No lock,
  no reservation, no commit, no PR, no round-11 authorization.
- Implemented (see the diff): kernel vf_source_paths and vf_path_content (identity records unchanged
  apart from edited files, measured twice); the O-010 scan rewritten (enumeration, content, case folding,
  every name shape, symlinks, named failures, no EXIT trap); the AC-023 loop over the hashed view with
  its shipped set from the enumeration; copy_kit (no trap, no spec dirs, directory selector) for every
  whole-kit copy; tests/run.sh enumerates suites; new tests/shellcheck.sh (enumerated files, --norc,
  SHELLCHECK_OPTS unset) is the ShellCheck command in stack.yml gate_checks/reuse_checks, CI, README and
  T027's Verify; kit_files for live-kit globs; stage_kit through copy_kit with a no-write-through policy
  writer; the 002 tally over an enumerated copy; suites clear SDD_* and XDG_* at start; host-kit fixtures
  for each site; the contract paragraph states the obligation.
- Dev runs, all in standalone copies with a before/after `git status --ignored` check: every suite
  passed (dev4/dev5/dev6; one dev4 failure was stale contract wrapping in that copy, since fixed and
  re-run 16/16). dev7 covers the last three fixture edits: t030o41-dev7.rc = 0 (verification 3/3,
  build-adapters 9/9, executable-bits 2/2, copy unchanged). No full `bash tests/run.sh` has run on the
  final tree in one go; the capture in step 5 is that run.
- INCIDENT (recorded in Decisions and t030o41-review.md): a dev run of this session's copy_kit in the
  LIVE worktree deleted .specify/stack.yml via an EXIT trap that read its caller's variables (bash 3.2,
  a subshell function run as the whole of $(...) and leaving by `exit`). Restored byte-exact
  (4dc6c67e..., equal to the recorded working-tree digest; status MM). The helper was fixed and a
  regression fixture kills the defective shape.
- The second review pair (t030o41-review2-brief.md) was dispatched and BOTH reviewers died on the
  session limit before reporting anything: that review has NOT happened.

Remaining order (do not skip or reorder):
1. Re-verify the state above from the scripts, not this prompt: source, Decisions digest, HEAD,
   analyzer, no lock/reservation, `spec-gate.sh waiver <spec> opponent 11` refused at exit 4.
2. Rerun the second independent review pair from t030o41-review2-brief.md (read-only, private copies).
   Verify every reported claim yourself before acting. If code changes, record the reason in Decisions
   FIRST (Decisions is still open), re-run the affected suites in a copy, and update the matrix.
3. Run t030o41-mutations.sh for real in the background, with receipts (log + rc read back). Expect
   1-2 h. Every kill/over mutant must be KILLED and every equiv must SURVIVE; restores are cmp-checked.
4. Record the matrix result and the review outcome in Decisions, then FREEZE Decisions.
5. Capture and accept T030o41 (spec-run.sh --from-task --no-tick --summary, assemble the
   Verification-Return block, spec-gate.sh accept); its Verify is `bash tests/run.sh && bash
   tests/shellcheck.sh`, the same command T027 now uses.
6. Hosted CI by the snapshot-PR route (throwaway branch on Rehan712/sdd-kit, draft do-not-merge PR,
   logs retained, PR closed and branch deleted). ASK THE USER TO CONFIRM BEFORE PUSHING. The CI
   ShellCheck job now runs `bash tests/shellcheck.sh` on ShellCheck 0.9 (Ubuntu): confirm --norc works there.
7. One fresh floor. Check disk and swap FIRST: at handoff free disk was about 6.0 GiB and swap
   6.8/7.9 GB, below the 9 GiB the last floor started at (it bottomed at 5.41 GiB); swap shares the
   volume; Docker runs another project's mv-localstack. Ask the user before reclaiming anything.
8. Stop. Round 11 needs its own exact-round waiver approved by the user, validated before and after
   writing.

Two decisions for the user, not to be inferred:
- AC-023 now certifies the identity's view of shipped 001/002, not their raw bytes (the analyzer reads
  a field from any line carrying its marker, a field-grammar defect recorded in Decisions and not
  repaired). Either amend AC-023/plan wording, or fix the analyzer field grammar, or accept the narrowed
  reading in Decisions.
- The hosted-CI push.

Standing rules: record Decisions and task definitions BEFORE refreshing proof; never change source
during a reservation; preserve sealed history; RUN NO SUITE OR TEST FUNCTION IN THE LIVE WORKTREE except
the formal capture/floor commands, which the kit runs there by design; use standalone copies and check
their `git status --ignored` before and after; never pipe suites through tail or infer success from a
trailing command or a background-task notification; read every exit back from its receipt. Until O-015
is accepted and gated, do not tick T030 or write Evidence/frontmatter text stating the superseded
environment membership. zsh: brace "${var}:ref"; run multi-step scripts under bash. GitHub writes:
process-scoped GH_TOKEN="$(gh auth token -h github.com -u Rehan712)", never switch the active account.
Do not infer authorization for repairs beyond T030o41's recorded scope, additional gates, a round-11
waiver, commits, PRs or bypasses from this prompt.
