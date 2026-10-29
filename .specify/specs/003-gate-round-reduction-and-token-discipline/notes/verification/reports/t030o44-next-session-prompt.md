Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (over 420 KB: read it in line ranges; the Read tool's limit is 25k
tokens, and the Bash tool's output limit is about 30 KB). Then read, under notes/verification/reports/:
- t030o44-handoff-state.txt (the state at the stop; re-derive it with bash t030o44-handoff-state.sh, run from the
  worktree root with bash, never sourced into the tool's zsh)
- the T030o44 record: t030o44-decisions-1.md (the five Decisions entries of 2026-10-01), the T030o44 task block in
  tasks.md, o018-repro.*, o018-measure.* (and -run1.* with its note), t030o44-apply-{1,2}.*, t030o44-final.*,
  t030o44-session{1,2}.diff, t030o44-dev*-*.{log,rc}
- the independent review: t030o44-review-brief.md, t030o44-review.md (5 blocking, 6 minor) and the invoker's
  reproduction t030o44-review-verify.{sh,log,rc}
- the prepared, NOT applied edits: t030o44-edits/tgc-3.pairs, t030o44-edits/fixtures-2.pl with refuse-diags.tsv,
  and the matrix t030o44-mutations.sh (with -dry.* and -probe1.*); T030o43's matrix on this tree:
  t030o44-o43matrix-shard{0,1}.*
- t030o44-incident-1.note
- STATUS's session-12 paragraph (Where things stand), the new Open questions entries and Next action

Verified state at the stop (2026-10-01T21:07Z, t030o44-handoff-state.txt):
- Source e42300018f7a27be460135bba6db86732c765a3b8242fc256eaf703190b2e2a6, Decisions
  2695a97580457a5cdc85c15d3d39fbc1fb71dbe98f3caa880805bc5d39a87400, HEAD 0d55c62, no lock, no pending reservation,
  13 sealed opponent rounds (round 13 2ddbed64…), 537 captures, analyzer 0 errors, tally opponent=13 blocking=27
  minor=11 locations=388. No floor is current (FLOOR-w6mznu is historical, by design).
- Round 14 is AUTHORIZED (waiver 2026-10-01T16:01:04Z, approved by the user as written; round 14 exit 0, round 15
  exit 4). It has not run. T030o44 is open (unticked); T030-T034 unticked.
- The T030o44 repair is APPLIED (scripts/verification-lib.sh, tests/test-gate-contracts.sh, tests/test-spec-gate.sh,
  templates/verification-contract.md; they hash as t030o44-edits/post-apply-2.sha256). dev1 to dev4 all exit 0
  (dev4: the full suite at 147/147 plus ShellCheck, plainly and under en_US.UTF-8, TMPDIR ending in `/`).
- The independent review found 5 BLOCKING findings, one class (a line a reader of the rendered Markdown sees as a
  second blocking tier is read as prose or hidden, so a CLEARED round seals): F1 the label reader's HTML strip is
  not CommonMark's inline-HTML grammar (an autolink and a non-tag are REGRESSIONS of this delta; a quoted `>` in an
  attribute predates it); F4 the shared quoting tracker (`<!-->`, `<!--->`, a `<!--` inside an attribute, a backtick
  fence whose info string holds a backtick; predates; the tracker also feeds vf_report_block's sealed digests);
  F9 a named character reference before the label; F10 a Class or Severity value continued on the next line;
  F11 a label after an empty link (F9-F11 predate). And 6 minor: F2 over-refusal of prose, F3 duplicate key in
  legacy rounds, F5 the canonical rules in reality-check reports, F6 un-isolated `style=="canonical"` conjuncts and
  comment loop, F7 four masked manifest guards, F8 wording. The invoker reproduced every claim (205 PASS; the one
  FAIL, F6's MD mutant killed once, did not reproduce: MD survives in isolation and three unmutated runs pass).
  The review's outcome is NOT yet in Decisions.
- Host at the stop: on battery, free disk 6.4 GiB, swap 7.1 of 8.2 GB used by other work on the machine.

Order:
1. Re-verify the state (bash t030o44-handoff-state.sh); it must match the above. Check disk, swap AND AC power.
2. Put the scope decision to the user (STATUS Next action): (1) repair the five blocking findings within T030o44,
   recommended, with F6/F7/F8, F3's wording, F2's recorded extent and F5's decision folded in; (2) repair only F1's
   two regressions plus the fixture and wording minors, recording F1's quoted-`>` member, F4, F9, F10 and F11 as
   open extent (round 14 will probably reopen O-018); (3) stop or a signed waiver.
3. For option 1: record the review's outcome, the user's decisions and the measured rule in Decisions BEFORE any
   code (validate on a scratch copy, then live: round 14 still exit 0, round 15 exit 4, analyzer 0 errors). Measure
   the candidate first in standalone copies against the recorded history, and for any change to vf_comment or
   vf_fence measure every sealed round digest (vf_report_block) and every catalog that shares the tracker (the
   authorization scanner, the Decisions view, the AC and binding catalogs). The reviewer's design to weigh: a label
   is read when ANY reading yields one (the stripped text, and the raw text with `<` and `>` as non-letters), so an
   approximation error can only refuse; strip by CommonMark's own productions (tags with quoted attributes,
   autolinks to their URI, comments that close on `<!-->`); named references as a non-letter placeholder; link
   destinations dropped; refuse a line that would lazily continue a Class or Severity field line. Then rebuild
   tgc-3.pairs and fixtures-2.pl (and refuse-diags.tsv) against the new code, add the review's rows as fixtures in
   both directions (and a legacy-round positive for F6), dev runs with a TMPDIR ending in `/`, the matrix of record
   (update t030o44-mutations.sh, dry run, then shards), freeze, capture
   (`spec-run.sh <spec> T030o44 --from-task --no-tick --summary`), return, `spec-gate.sh accept`, one fresh floor
   on AC (about 4 hours: launch detached with nohup and a wrapper rc, pattern r13-floor.sh), reserve round 14,
   brief, dispatch the independent opponent, complete, tally, final audit, update STATUS, stop.

Standing rules: never change source during a reservation, and make no STATUS edit between the prereserve and
returned states; run no suite or test function in the live worktree except the formal capture, floor and gate
commands; NEVER source a file from tests/ (a suite file ends in t_run_all) and never source anything from tests/
with the live worktree as the working directory: extract a helper with awk into a scratch file; exploratory runs go
in standalone copies with a before/after status check, and any dev run gives its copy a TMPDIR ending in `/`; run
any loop that uses printf '%b' escapes inside bash, not the tool's zsh (zsh does not decode `\342`); read every exit
back from its receipt, never from a notification; never pipe suites through tail; no foreground command over 10
minutes (macOS has no `timeout`; background it). A floor takes about 4 hours, longer than a tool-managed background
shell may live (2 hours): launch it detached with nohup and a wrapper rc and wait on its receipt. Do not edit a bash
script while it is running. Check disk, swap and AC power before and during long runs (the battery ran down to 17%
mid-session once), and ask before reclaiming anything or stopping Docker; never touch taxipro-backend,
sales-platform, Docker or vm_bundles. Reviewers may use throwaway containers of images already on disk only within
the recorded limits. Do not infer authorization for hosted CI, the 002 fix, the open-extent task, round 15,
commits, PRs or bypasses.
