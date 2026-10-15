# Opponent round 13 — reviewer brief

Written 2026-09-30 by the invoker (sessions 9 to 11). Everything here is a claim to attack, not
authority. The receipts named below outrank this text. Paths are relative to
the spec directory `.specify/specs/003-gate-round-reduction-and-token-discipline/`
unless they start with `scripts/`, `tests/`, `templates/`, `agents/`, `README.md`,
`.specify/stack.yml` or `.github/` (worktree root:
`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 13 is AUTHORIZED by the Decisions line `2026-09-27T15:55:36Z — waiver:
  gate=opponent; round=13; after=12; by=Rehan712; …`. Find it by its timestamp
  (neutral text above the Decisions log moves line numbers, and only the
  Decisions sections are hashed). `bash scripts/spec-gate.sh waiver <spec-dir>
  opponent 13` exited 0 and round 14 is refused at exit 4 at the second freeze
  point and again at this session's entry
  (`notes/verification/reports/t030o43-freeze-2.txt`, `t030o43-entry-11.txt`).
- Reservation (copy exactly into the report): **Round** 13 · **Source**
  24828d54ee3b743533467e880ce81eb33deec5f1429dea750f4380a899bba145 · **Floor** FLOOR-w6mznu · **reserved** 2026-09-30T23:30:26Z.
  Read them yourself from `notes/verification/rounds/opponent/ROUND-13/meta.nul`.

## Scope: what changed since round 12

Derived mechanically (`notes/verification/reports/r13-scope.sh`; `r13-scope.log`):
round 12's FLOOR-0334B2 `inputs.nul` against FLOOR-w6mznu's.

- One accepted repair, NOT yet gated independently: **T030o43** (round-12
  O-017, blocking): task block in `tasks.md` (search `**T030o43**`). It pins
  `LC_ALL=C` for the harness's own parsing (the kernel on load; every harness
  entry script loads it directly after `lib.sh`), gives the captured command
  the caller's `LC_ALL` back, reads every parser's exit status, and reads the
  19 non-ASCII Unicode White_Space characters as whitespace through one shared
  step (`_VF_AWK_WS`, `_VF_AWK_WSLINE`) with every value passed on taken from
  the line as written; the prior-review manifest pass reads by the canonical
  field grammar keyed on its field lines. Changed: `scripts/verification-lib.sh`,
  `scripts/spec-run.sh`, `scripts/spec-task.sh`, `scripts/spec-evidence.sh`,
  `scripts/spec-ac-coverage.sh`, `scripts/sdd-analyze.sh`,
  `templates/verification-contract.md`, `tests/helpers.sh`,
  `tests/test-verification.sh`, `tests/test-gate-contracts.sh`,
  `tests/test-spec-gate.sh`, `tests/test-sdd-analyze.sh`, 003's `tasks.md` and
  the Decisions log. The whole delta against the pre-repair tree is
  `notes/verification/reports/t030o43-final.diff`; the reviewed stages are
  `t030o43-session.diff` (review 1), `t030o43-review-repair.diff` (review 2),
  `t030o43-session8.diff` (review 3) and `t030o43-session9.diff` (review 4),
  and the review-4 repairs are the pairs files `t030o43-edits/kernel-7`,
  `tgc-7`, `tgc-8`, `vc-5` and `tasks-fix-5`. Two later changes were
  reviewed by no one: `t030o43-edits/tgc-9.pairs`, the matrix-of-record
  correction of seven rows whose manifests recorded no finding (session 9);
  and session 10's repair after the first capture of record failed
  (CAP-521-Q8OdIp, rc 1, on a `TMPDIR` spelled with a trailing slash):
  `tests/helpers.sh` now exports `TMPDIR` as the physical path of the
  directory it names, with a fixture in `reuse_command_input_cases` and the
  contract sentence and kernel comment corrected (`t030o43-session10.diff`,
  5 files; pairs `helpers-1`, `tv-5`, `vc-6`, `kernel-8`, `tasks-fix-6`;
  the Decisions entries from "Session 10 of T030o43").

Consumers of the changed files and every surface the spec declares are in
scope too, and you may expand into unchanged code.

## Evidence for the repair (claims, not authority)

- The decisions, in Decisions order from the entry "Opponent round 12 is
  recorded here now that this batch moves the source anyway" to the end:
  round 12's outcome, the user's decision, the reproduction, the rule and its
  measurement, the round-13 waiver, the task-block corrections, and the four
  focused reviews' outcomes with each repair's measured rule and corrections.
- Reproductions: `o017-repro.{sh,log,rc,time}`; reviews 1-4 reproduced in
  `t030o43-review-verify.*`, `t030o43-review2-verify.*`, `t030o43-review3-verify.*`,
  `t030o43-review4-verify.*`.
- Measurements before adoption: `o017-measure.*` with `o017-measure-m3.*`,
  `t030o43-review-measure.*`, `t030o43-design-measure.*`, `t030o43-measure-9.*`,
  `t030o43-measure-10.*` (each with its kept failed runs), and R3-F6 on mawk in
  a local container, `t030o43-r3f6-mawk.*`.
- Reviews: `t030o43-review{,2,3,4}.md` with their briefs.
- The failed capture and its repair: CAP-521-Q8OdIp (`t030o43-capture.{log,rc,start,end}`,
  rc 1: `tests/test-sdd-analyze.sh::test_verification_bindings` 18/19 on six
  assertions of `analyzer_locale_and_fault_cases`), reproduced in
  `t030o43-tmpdir-repro.{sh,log,rc,note}`, the rule measured in
  `t030o43-measure-11.sh` (`-11a.*`, `-11full.*`, and the five suite logs
  `t030o43-measure-11-*.log`: a census on the unrepaired tree and the
  repair under three spellings) and `t030o43-o010-precheck.*`.
- Dev runs: `t030o43-dev{1..8}-*`. Every run before dev8 gave its copy a
  `TMPDIR` written without a trailing slash, which is why none saw the
  capture's failure. dev8 (`t030o43-dev10.sh`) gives every run one ending in
  `/`: `t030o43-dev8-{full,full-locale}.{log,rc,start,end}`, both exit 0,
  the full suite at 147/147 plus ShellCheck plainly and under
  `LANG=en_US.UTF-8` with every `LC_*` removed.
- Mutation matrix of record: `t030o43-mutations.sh` (v5, 153 rows, every
  judge under a `TMPDIR` ending in `/`) with
  `t030o43-mutations-v5-shard{0,1}.{log,rc,start,end}`: exit 0 each, 142 kills, each with its exact diagnostic,
  11 argued equivalents surviving (the same eleven as v4), 8 baselines,
  every restore identical. Its dry
  run and the probe of the six new rows are `-v5-dry.*` and `-v5-probe.*`.
  v4 (147 rows, session 9) is kept as `t030o43-mutations-v4.sh` with its
  receipts `-v4-shard{0,1}.*`. The unprefixed
  `t030o43-mutations-shard{0,1}.*` are the 56-row matrix of the review-1
  state and are historical.
- Acceptance: CAP-522-PgNdFn (147/147 over 15 suites plus ShellCheck, input `24828d54…`, the frozen source; the first capture, CAP-521-Q8OdIp, failed and is listed above) (`bash tests/run.sh && bash tests/shellcheck.sh`;
  `t030o43-capture-2.{log,rc,start,end}`), `notes/verification/returns/T030o43.txt`
  (`t030o43-return-validate.{log,rc}`), `T030o43-accept.{log,rc}` and
  `t030o43-postaccept.txt`. No hosted CI has run on the reviewed source.
- The floor: FLOOR-w6mznu (`r13-floor-1.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}`,
  rc 0: source `24828d54…`, 21 executed as CAP-523-v32rBY to CAP-543-cVvDyf and
  55 reused, 18:49:40Z to 23:00:52Z on AC) and its validation
  (`r13-floor-validate.{out,err,rc,time}`, rc 0, output equal to the source,
  empty stderr). The scope diff against FLOOR-0334B2 (`r13-scope.{log,rc}`,
  exit 0) names T030o43's twelve source files, `tasks.md` and `STATUS.md` alone.
  The reservation: `r13-reserve.{log,rc,time}` (exit 0).

## Known open — recorded, you may challenge it

- Review 3's R3-F7 (the STATUS identity view does not carry the quoting state
  that enters the Decisions log) and R3-F10 (the artifact-name wrapper set is
  an enumeration); review 4's R4-F3 (a criterion beginning with a U+00A0 or a
  tab after its dash keeps a leading space in the AC catalog), R4-F5 (a Finding
  heading inside a list item), R4-F6 (an emphasized Class or Severity lead-in
  word inside a finding is refused as a second field) and R4-F8 (the ID
  condition reads UTF-8, AC-012 or REQ-011 as a finding ID); a finding opened by
  no heading at all (a setext heading, raw HTML, a bold line) inside another
  finding; a non-Finding heading at the Finding heading's own level ends the
  finding; a manifest mixing read findings with a table finding; a `##`
  heading with no space after it is a stage to the inventory and not to
  `vf_config`; Ubuntu 24.04's mawk is not executed (the rule no longer depends
  on default field splitting).
- From the rule entries: a waiver's `by=` with a blank value authorizes;
  `system-map.sh` and `sdd-doctor.sh` parse under the pin; a C1 control byte in
  stack.yml; invisible characters that are not White_Space; CRLF outside the
  manifest; a Latin-1 C2 A0 pair read as UTF-8; an artifact name glued to a
  full-width colon fails.
- From session 10's TMPDIR rule: a `TMPDIR` inside a Git worktree is a
  different directory, not a spelling (review 7's F1); Linux, where `TMPDIR`
  is usually unset over a physical `/tmp`, was not run for this change.
- Carried from round 12's brief: the harness-level bash startup environment and
  option variables; `TZ`; `PATH` choosing an undeclared tool; shipped 002's
  locale-dependent reset parsing; T030o42 review F2; review 7's F1, F2, F4 and
  the unjudged K74 site; the kernel's ambient fixture reads; the analyzer field
  grammar with AC-023's narrowed reading; umbrella-only readers; the O-004
  omission extent; the opponent-only totals, verdict and downgrade guards;
  README's missing Verification-Return grammar and completion marker; 001's
  legacy report failing `tally` at exit 3; the retained unexamined surfaces.

## Method this spec requires

1. Derive each criterion from the grammar or production the code reads, with
   its source. An enumeration of reported spellings is satisfiable while the
   class stays open.
2. Test a proposed rule against the real recorded history (`notes/opponent.md`,
   and 001's and 002's reports) before proposing it.
3. Mutation-isolate guards in both directions, and restore byte-identically (`cmp`).
4. Assert exact diagnostics, never exit codes alone.
5. Hunt for shipped POSITIVES that assert an attack at rc=0.

## Operational rules

- Work in a copy outside the worktree (for example `/private/tmp/opp13/work`,
  with `TMPDIR` inside it). Create, modify, move or remove NOTHING in the
  worktree except your report file. Run no floor, round, checkpoint, capture or
  accept, and no suite or test function in the worktree itself. The source must
  not move between reservation and completion, and the invoker checks that the
  worktree is byte-identical before and after your run.
- Free disk: 8.1 GiB at reservation; swap shares the volume. Check `df -h /`
  before large copies (the non-ignored enumeration was about 173 MB in 8,112
  files while the floor ran, and grows with each capture), and remove your own directory
  when you finish.
- Never pipe a suite through `tail`. `tests/run.sh` prints no total, so its exit
  code is the signal. Capture exit codes and read them back.
- Write the report to `notes/verification/reports/opponent-round13.md` (exempt
  from the source identity), AND return it verbatim as your final message.

## Report grammar the gate will parse

The returned file is the round-13 block ALONE. `--complete` appends it to
`notes/opponent.md`, validates it with `vf_reports`, re-validates the floor to
the reserved source, and re-verifies rounds 1-12 against their sealed digests.

```
## Round 13

**Round:** 13
**Timestamp:** <UTC YYYY-MM-DDTHH:MM:SSZ, not before the reserved time, not in the future>
**Source:** <exactly the reservation's source>
**Floor:** <exactly the reservation's floor>
**Verdict:** CLEARED | CHALLENGED
**Blocking:** <n> · **Minor:** <m>

### What I attacked
...

### Finding O-0XX
- **Class:** …
- **Status:** new | open | reopened | resolved
- **Prior:** O-0XX | none
- **Severity:** data-loss | wrong-result | regression | crash | minor | degraded
- **Scenario:** …
- **Where:** file:line, …
- **Reproduced:** …
- **Root cause:** plan-gap | spec-gap | implementation-error
- **Blocks:** REQ-…, AC-… | none
- **Wrong behavior:** …
- **Class-wide fix:** …

### Held up / follow-up tasks
...
<!-- gate-round-end: opponent:13 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:13 -->`, and
nothing non-blank may follow it. These are the constraints `vf_reports`
enforces, stated so that a correct report of either verdict can be canonized.
The verdict itself is yours alone.

- `Blocking`/`Minor` must equal the counted findings. CLEARED requires zero
  blocking, and CHALLENGED requires at least one.
- A CLEARED report may not carry a known ID at a tier below its strictest
  recorded tier, nor a `resolved` finding that an earlier round of this gate
  counted open. O-017 was counted open (new, wrong-result) in round 12. So
  under CLEARED it may not appear as a `### Finding` block, and your assessment
  of its repair belongs in the two prose sections.
- A CHALLENGED report may re-list findings with any status, at their true tier.
- Field values are read after their own label only: write one bold label per
  field line.
