Continue spec 003 in:
    /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline

    Read the spec's STATUS.md completely FIRST (it is over 256 KB: read it in ranges). Then read, under
    notes/verification/reports/:
    - opponent-round12.md (round 12, CHALLENGED: O-016 resolved, O-017 new) and opponent-round12-brief.md
      (the brief pattern)
    - r12-complete.{log,rc,time}, r12-tally.{log,rc}, r12-final-audit.{sh,log,rc}, r12-state-{prereserve,
      reserved,returned}.{txt,entries,log,rc}, r12-reserve.{log,rc,time}, r12-floor-1.{pre,log,rc,samples.log},
      r12-floor-validate.{out,err,rc,time}, r12-scope.{sh,log,rc}
    - the T030o42 record: the three Decisions entries after the round-12 waiver, t030o42-review.md,
      t030o42-review-verify.{sh,log,rc}, t030o42-mutations.sh with -final.{log,rc}, t030o42-capture.*,
      T030o42-accept.{log,rc}, t030o42-freeze.txt and t030o42-postaccept.txt

    Verified state at the end of session 6 (2026-09-27):
    - Opponent round 12 CONSUMED: CHALLENGED, 1 blocking + 0 minor, digest 4539d729b5402bfa..., on
      FLOOR-0334B2 (source bb996df97887231e1fd50ebce39b2d3b7f918e3896917ea0031a59b227198254), reserved
      2026-09-27T13:44:57Z, report timestamp 14:36:02Z. The worktree was byte-identical at reservation and
      return. O-016 (T030o42) credited RESOLVED.
    - O-017 NEW (harness-locale-decoding, wrong-result, blocks REQ-011, REQ-009, AC-012, AC-020): the kernel's
      own text parsing runs under the caller's locale, and the prior-review manifest pass in vf_reports
      (scripts/verification-lib.sh:955-968, `priorids="$priorids$(awk … | sort -u | tr …)"`) discards its
      exit status. The reviewer reproduced, in its own copy, a CLEARED round with a manifest-recorded blocking
      finding re-recorded at minor that is refused under LANG=C and sealed at exit 0 under en_US.UTF-8, because
      awk dies on an undecodable byte and the manifest seed is lost. Sibling: sdd-analyze.sh reads spec.md with
      grep, which stops at an undecodable byte. It also contradicts T030o42's contract and kernel-comment
      sentence "fails closed in a locale that cannot decode the kit's bytes". The invoker confirmed the static
      premise at :955-968 read-only and did NOT re-run the reproduction. Proposed follow-up: T030o43.
    - Tally: opponent=12, reality-check=1, blocking=26, minor=10, locations=367, observations=53, distinct
      IDs=17, reopened=25, severity-downgrades=5, captures=514.
    - Decisions frozen at 0db7684afbccb2cfbfed7bff71b5f9359dc3affde4d4b92da386477a038437f9; round 12's outcome is
      NOT yet in Decisions (so FLOOR-0334B2 stays current for bb996df9... until the next authorized change).
      No lock, no pending reservation. HEAD 0d55c62. T030-T034 unchecked; T030o39-T030o42 checked.
      Round 13 is NOT authorized (spec-gate.sh waiver ... opponent 13 exits 4 with ten candidates).

    Nothing further is authorized. Put the options to the user:
    1. Repair O-017 as T030o43 (the reviewer's proposal: pin LC_ALL=C for the kernel's own text parsing in
       the kernel, the analyzer and the checkers -- never for the captured command -- read every parser's
       exit status, :955 and :2465 first, add the manifest-locale fixtures and the analyzer marker case with
       mutants, then correct the contract and the kernel comment). Reproduce first in a standalone copy;
       record round 12's outcome and the task block in Decisions before any code; review, matrix,
       acceptance, and then, only with the user's exact-round waiver for round 13 (validated before and after
       writing), one fresh floor and round 13.
    2. A signed waiver of O-017.
    3. Stop.
    Also still open for the user: the open-extent follow-up task (review 7's F1/F2/F4, K74, the harness-level
    environment including the measured option variables, T030o42 review F2's fixture scope, the kernel's
    ambient fixture reads, the analyzer grammar, the umbrella readers); shipped 002's locale-dependent reset
    parsing; hosted CI (ask first); reality-check round 2 (needs CLEARED).

    Standing rules: record Decisions and task definitions BEFORE refreshing proof; never change source during a
    reservation; run no suite or test function in the live worktree except the formal capture, floor and gate
    commands; exploratory runs go in standalone copies with a before/after status check; read every exit back
    from its receipt; never pipe suites through tail; no foreground command over 10 minutes. Check disk, swap
    AND AC power (pmset -g batt) before and during long runs, and ask before reclaiming anything or stopping
    Docker (mv-localstack has restart policy "no" and no persistence). Do not infer authorization for hosted CI,
    the 002 fix, the open-extent task, reality-check round 2, round 13, commits, PRs or bypasses.
