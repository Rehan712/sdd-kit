Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

Read the spec's STATUS.md completely FIRST (it is over 300 KB: read it in line ranges; the Read tool's
limit is 25k tokens, and the Bash tool's output limit is about 30 KB). Then read, under
notes/verification/reports/:
- t030o43-handoff-state-8.txt (the state at the stop; re-derive it with bash t030o43-handoff-state-8.sh,
  run from the worktree root with bash, never sourced into the tool's zsh: zsh ties a variable named
  `path` to PATH and the kernel's locals then break it)
- t030o43-review3.md (focused review 3 of the session-8 delta; its scripts under t030o43-review3-repro/)
  and t030o43-review3-brief.md
- the two Decisions entries dated 2026-09-29 (the measured whitespace rule, its three corrections to
  t030o43-review2-design.md, and the task-block correction), and the T030o43 task block in tasks.md
- t030o43-design-measure.{sh,log,rc} (the measurement of record; -run1 and -run2 kept),
  t030o43-pre-rebuild-2.{sh,log,rc}, t030o43-rev3-base.{sh,log,rc} (REVIEWED_DIR for review 3, and the
  delta t030o43-session8.diff), t030o43-edits/ (every session-8 literal edit as a pairs file:
  kernel-5, sdd-analyze-2, spec-evidence-3, spec-run-2, spec-task-2, vc-3, tgc-4, tgc-5, tv-3, tv-4,
  tsa-3..tsa-6, tsg-3..tsg-7, tasks-fix-3)
- the dev runs t030o43-dev3-quick (rc 1, one BOM fixture fault, fixed), t030o43-dev4-{quick,full,full-locale}
  (all rc 0, 147/147 plus ShellCheck), and matrix v3 t030o43-mutations.sh (dry run -v3-dry, probes
  -v3-probe{0,1} and -v3-probe2; it now takes ONLY=<ids> for a probe of named rows)

Verified state at the stop (2026-09-29T22:45Z, t030o43-handoff-state-8.txt):
- T030o43 (O-017 repair) IN PROGRESS and unticked. The code is the measured class-wide whitespace rule
  (the Decisions entries of 2026-09-29), with fixtures; all dev runs pass. Focused review 3
  (t030o43-review3.md, COMPLETE, stopped early at the user's request; its Not-reached list is the next
  review's starting point) found 4 BLOCKING and 7 minor findings, reproduced by the reviewer at kernel-
  function level and NOT yet by the invoker, and nothing of it is in Decisions yet (Decisions frozen at
  4a9442e1…). The blocking ones:
  R3-F1 the manifest pass takes a field's value after the LAST bold label on the line (value() is greedy),
    so `- **Severity:** data-loss; **Prior:** minor` records minor and a CLEARED round over the lowered
    tier seals (a regression of session 8);
  R3-F2 a Severity label not followed immediately by a colon (`**Severity :**`, a U+00A0 or U+202F before
    the colon, `**Severity** —`, a full-width colon, an ordered-list marker) is prose, so the tier drops in
    silence (pre-existing, but it falsifies the recorded rule);
  R3-F3 a Finding heading the pass does not read as a heading (`###<U+00A0>Finding`, U+200B or a tab or a
    U+00A0 before `###`) lets a Class-less finding's Severity fall into a Class-only finding above it
    with no refusal (a narrow regression; review 2's catch-all refused the line);
  R3-F4 Correction 2 took only the Verify command and vf_fm_value from the line as written: the Tests
    locators and manual observation names the harness opens, greps for and compares with unmapped readers
    (vf_locators_exist, vf_return_check against vf_return_parse) still come from the mapped line, so a
    U+00A0 inside one becomes a VT and a task whose files exist cannot be accepted; the binding catalog
    records the VT (a regression toward a false refusal).
  The minor ones: R3-F5 manifest prose that starts `Class:` or `Severity:` (a summary line, an intro, a
    nested sub-bullet) is now refused by name where review 2 accepted it; R3-F6 (from mawk's source, not
    executed) mawk, Ubuntu's default awk and probably the CI job's, treats VT as a default field
    separator, so the kernel comment's "VT is not a default field separator" is false there and `fid=$3`
    and the totals line read a heading like `### Finding G-042<U+00A0>` differently on Linux and macOS;
    this bears on Correction 1 itself (VT rather than a space) and must be measured on a Linux awk before
    the rule is re-recorded (ask the user before using Docker or hosted CI for it); R3-F7 (pre-existing)
    the STATUS identity view does not hash the fence state entering the Decisions log, so two files can
    share an identity while the scanner authorizes one and refuses the other; R3-F8 a reality-check
    matrix criterion cell copied as the spec writes it no longer matches the AC catalog (the catalog maps
    U+00A0 to a space, the cell parser to VT); R3-F9 matrix row E02 is no longer equivalent
    (`vf_fm_value` and `fm_get` now disagree on `verification_contract:<U+00A0>1`); R3-F10 (pre-existing)
    the artifact-name wrapper set is an enumeration (German, Swedish, Danish quotes and 【】 fail);
    R3-F11 the checkpoint-stage fixture proves vf_config only; `vf_bindings through-stage` still refuses
    `## Backend<U+00A0>` (and a trailing ASCII space, pre-existing).
  Nothing may be captured or accepted on this tree.
- Round 13 AUTHORIZED by the recorded waiver 2026-09-27T15:55:36Z (round 13 exits 0, round 14 exits 4).
  No floor is current: FLOOR-0334B2 is historical.
- Source 166bc2fe69bcc89d8c9003696d1b316d9835d7203199c8db19b8fb484d4c59c5, Decisions
  4a9442e1929b39c60b2b8c0e7dbdc624d51f1cb436eb90e60da86f278c5f7b8f, HEAD 0d55c62, no lock, no pending
  reservation, 514 captures, analyzer 0 errors. T030-T034 unticked; T030o39-T030o42 ticked.
- Host at the stop: on AC, free disk 14 GiB. The user authorized removing regenerable caches in earlier
  sessions (r13-disk-reclaim.*); ask again before removing anything else, and never touch
  taxipro-backend, sales-platform, Docker or vm_bundles.

Order:
1. Re-verify the state (bash t030o43-handoff-state-8.sh); check disk, swap and AC power (pmset -g batt).
2. Put the review-3 outcome to the user first if the repair scope is not obvious (the pace decision of
   2026-09-25 applied to T030o41 only; ask whether review 3's minors are repaired here or recorded as open
   extent, and whether R3-F6 is measured on Linux now). Then reproduce every review-3 finding in a
   standalone copy BEFORE any change (pattern:
   t030o43-review2-verify.sh; kits CUR = this tree, REV = REVIEWED_DIR rebuilt by t030o43-rev3-base.sh,
   PRE = t030o43-pre-rebuild-2.sh's output), under C and en_US.UTF-8 with every LC_* removed.
3. Measure the repairs before adopting them, derived from the mechanism, not from the listed spellings:
   for R3-F4, take EVERY value a parser of author text passes on (every task field that reaches rec(),
   every plan registry cell, every printed value another reader compares) from vf_original through one
   per-field helper, and derive the members by listing every field that reaches rec(), a print or an
   outside comparison; for R3-F1, anchor a manifest field's value on its own label (the first
   `**Class:**`/`**Severity:**`), and consider the same for the canonical value(); for R3-F2, decide a
   field line from its label (first word Class/Severity in any case, not continued by a word character),
   every candidate strict or refused by name; for R3-F3, a refusing catch-all for a non-heading line whose
   text after leading whitespace of any kind and a `#` run begins with the word Finding. Test each against
   the recorded history (tally and every STATUS view of 001/002/003, the snapshot records) and review 3's
   own measurement of R3-F2's rule (0 new candidates over every notes/*.md).
4. Record review 3's outcome and the measured rule in Decisions before any code; validate on a scratch
   copy first (bash r11-insert.sh) and after writing (round 13 exit 0, round 14 exit 4, analyzer 0 errors).
5. Implement as recorded pairs files, with a fixture and a matrix row for every guard; dev runs in
   standalone copies (t030o43-dev.sh quick, then full and full-locale in parallel).
6. One short focused review 4 of that delta (pattern t030o43-review3-brief.md; rebuild REVIEWED_DIR by
   extending t030o43-rev3-base.sh with the new pairs files); reproduce and repair its blocking findings;
   then the matrix of record (two shards).
7. Freeze (t030o43-freeze.sh), capture T030o43's Verify (bash scripts/spec-run.sh <spec> T030o43
   --from-task --no-tick --summary, in the background, receipts t030o43-capture.*), return
   (t030o43-return.sh), accept (spec-gate.sh accept), post-accept check.
8. One fresh floor ON AC (bash r13-floor.sh 1, which refuses off AC; about 4 h, cold), validate it
   current, scope (r13-scope.sh), worktree states (r13-worktree-state.sh prereserve/reserved/returned),
   reserve round 13, dispatch the independent opponent with a path-based brief (pattern:
   opponent-round12-brief.md; the report must carry the reservation's Source/Floor and the exact
   <!-- gate-round-end: opponent:13 --> marker), complete, tally, final audit, update STATUS, stop.

Standing rules: record Decisions and task definitions BEFORE refreshing proof; never change source during
a reservation; run no suite or test function in the live worktree except the formal capture, floor and
gate commands; exploratory runs go in standalone copies with a before/after status check; read every exit
back from its receipt, never from a notification; never pipe suites through tail; no foreground command
over 10 minutes; do not edit a bash script while it is running (bash reads it as it goes); write Decisions
text with no line that begins `## ` and no raw comment opener, fence run or raw-HTML tag outside code spans
(the scanner and the identity read them); perl -0pi with an exit in its code truncates the file (write
substitutions through a helper that writes itself). Check disk, swap AND AC power before and during long
runs, and ask before reclaiming anything or stopping Docker (mv-localstack has restart policy "no" and no
persistence). Do not infer authorization for hosted CI, the 002 fix, the open-extent task, reality-check
round 2, round 14, commits, PRs or bypasses.
