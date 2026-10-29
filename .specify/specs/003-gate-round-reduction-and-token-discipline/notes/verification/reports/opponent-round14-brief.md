# Opponent round 14 — reviewer brief

Written 2026-10-02 by the invoker (sessions 12 and 13). Everything here is a claim to attack, not
authority. The receipts named below outrank this text. Paths are relative to
the spec directory `.specify/specs/003-gate-round-reduction-and-token-discipline/`
unless they start with `scripts/`, `tests/`, `templates/`, `agents/`, `README.md`,
`.specify/stack.yml` or `.github/` (worktree root:
`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 14 is AUTHORIZED by the Decisions line `2026-10-01T16:01:04Z — waiver:
  gate=opponent; round=14; after=13; by=Rehan712; …`. Find it by its timestamp
  (neutral text above the Decisions log moves line numbers, and only the
  Decisions sections are hashed). `bash scripts/spec-gate.sh waiver <spec-dir>
  opponent 14` exited 0 and round 15 is refused at exit 4 at the freeze point
  (`notes/verification/reports/t030o44-freeze.txt`).
- Reservation (copy exactly into the report): **Round** 14 · **Source**
  75a92e76ef6817868f99e8ca6f477de33f2d97d3d839488de1e9a6acf8701415 · **Floor** FLOOR-auyetN · **reserved** 2026-10-02T15:43:54Z.
  Read them yourself from `notes/verification/rounds/opponent/ROUND-14/meta.nul`.

## Scope: what changed since round 13

Derived mechanically (`notes/verification/reports/r14-scope.sh`; `r14-scope.log`):
round 13's FLOOR-w6mznu `inputs.nul` against FLOOR-auyetN's.

- One accepted repair, NOT yet gated independently: **T030o44** (round-13
  O-018, blocking, with O-019 folded in): task block in `tasks.md` (search
  `**T030o44**`). Changed: `scripts/verification-lib.sh`,
  `templates/verification-contract.md`, `tests/test-gate-contracts.sh`,
  `tests/test-spec-gate.sh`, 003's `tasks.md` and the Decisions log. It was
  built in two stages, each reviewed or measured:
  - Session 12: one label reader (`vf_label`) for both readers of finding
    records; every manifest finding needs one readable Class and one readable
    Severity; a heading deeper than a Finding heading keeps the finding open;
    the canonical pass refuses Finding-like headings, field lines outside a
    finding and non-field Class or Severity lines inside one, and keys its
    duplicate field by label. Delta `t030o44-session1.diff` and
    `t030o44-session2.diff`; independent review `t030o44-review.md` (5
    blocking, 6 minor), reproduced in `t030o44-review-verify.*`.
  - Session 13, the review's repairs: the label reader reads a line as
    written and as rendered and returns a label either reading yields (the
    rendered reading takes inline HTML out by CommonMark's productions, link
    destinations, reference labels and images out, and renders character
    references); both readers refuse by name a quoted Finding heading, and
    inside a finding a quoted record line, instead of skipping it (the shared
    quoting tracker itself is unchanged); the list item of a Class, Severity
    or (canonical) Status field holds that line only. Delta
    `t030o44-session3.diff` (against the session-12 state); the pairs are
    `t030o44-edits/kernel-3`, `tgc-3` to `tgc-6`, `fixtures-2.pl` with
    `refuse-diags.tsv`, `tsg-2`, `vc-2` and `tasks-fix-1`, applied by
    `t030o44-apply-3.*` to `t030o44-apply-5.*`. The session-13 delta was
    reviewed by no one: round 14 is its independent gate.
  The whole delta against the pre-T030o44 tree is `t030o44-final.diff`.

Consumers of the changed files and every surface the spec declares are in
scope too, and you may expand into unchanged code.

## Evidence for the repair (claims, not authority)

- The decisions, in Decisions order from the entry "Opponent round 13 is
  recorded here now that this batch moves the source anyway" to the end:
  round 13's outcome, the user's decision, the reproduction, the rule and its
  measurement, the round-14 waiver; then the review's outcome, the user's
  session-13 decisions (F5 gate-neutral; F4 refused at the readers, the
  tracker unchanged), the measured repair rule with its stated consequences
  and recorded extent, the task-block correction, and the freezing entry.
- Reproductions: `o018-repro.{sh,log,rc,time}`; the review reproduced in
  `t030o44-review-verify.*`.
- Measurements before adoption: `o018-measure.*` (session 12, run 1 kept) and
  `t030o44-measure-2.{sh,log,rc,time}` (session 13, exit 0, 767 PASS; runs 1
  and 2 kept with notes). A survey found no quoted line carrying a record, and
  no text inside a Class, Severity or Status item, anywhere in the recorded
  history or the twelve returned round reports.
- Dev runs (each in a standalone copy, `TMPDIR` ending in `/`):
  `t030o44-dev8-{full,full-locale}.{log,rc,start,end}`, both exit 0, the full
  suite at 147/147 over 15 suites plus ShellCheck plainly and under
  `LANG=en_US.UTF-8` with every `LC_*` removed. Session 12's dev1 to dev4 ran on
  the session-12 tree; this session's dev5, dev6 and dev7 were stopped before any
  suite finished to add fixture rows and judge nothing (their notes).
- Mutation matrix of record: `t030o44-mutations.sh` (v2, 103 rows; v1 kept as
  `-v1.sh`) with `t030o44-mutations-shard{0,1}.{log,rc,start,end}`: exit 0 each, 103 rows each exactly once:
  77 kills and 21 over-corrections killed, each with its exact diagnostic, 5
  argued equivalents surviving (L05, L19, R03b, Q08, B12; the argument is beside
  each row), 7 baselines, every restore identical. Its first run
  (`t030o44-mutations-run1-shard{0,1}.*` with a note) found one row passing for
  the wrong reason (L13: `![x](y)` let the word reader skip `[x]` as a task
  checkbox), corrected by `tgc-7` before the run of record.
- Acceptance: CAP-544-cjPQ2j (147/147 over 15 suites plus ShellCheck, input `75a92e76…`,
  the frozen source; `t030o44-capture.{log,rc,start,end}`), the freeze point
  `t030o44-freeze.txt`, `notes/verification/returns/T030o44.txt`
  (`t030o44-return-validate.{log,rc}`), `T030o44-accept.{log,rc}` (return
  `e7fd6864…`) and `t030o44-postaccept.txt`. No hosted CI has run on the reviewed source.
- The floor: FLOOR-auyetN (`r14-floor-2.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}`,
  rc 0: source `75a92e76…`, 10 executed and 67 reused, 12:15:42Z to 15:14:52Z on
  AC) and its validation (`r14-floor-validate.{out,err,rc,time}`). Attempt 1
  (`r14-floor-1.*` with `r14-floor-1.note`) failed at rc 1 when the disk filled
  from about 12.5 to 0.1 GiB free in six minutes during one capture; what filled
  it is not established. The scope diff against FLOOR-w6mznu (`r14-scope.{log,rc}`,
  exit 0) names T030o44's four source files, `tasks.md` and `STATUS.md` alone. The reservation: `r14-reserve.{log,rc,time}`.

## Known open — recorded, you may challenge it

- From the session-13 rule entry: the shared tracker's divergences from a
  renderer remain for its other consumers (the authorization scanner, the
  input identity's Decisions view, `vf_report_block`, the task, plan and stage
  readers); text a renderer hides by CSS or an attribute; a label split by a
  zero-width character; a finding written in prose only (the O-004 omission
  extent). Its stated consequences: a report quotes an example of a Finding
  heading, or of a record line inside a finding, inline in a code span after
  another word, never in a fence, block quote or comment; a Class, Severity or
  Status item carries no continuation line, second paragraph or sub-bullet; a
  line inside a finding whose first word is Class or Severity followed by
  punctuation is refused (review F2's recorded extent); a reality-check gap
  writes its detail as prose.
- From session 12's rule entry: a label written with a named character
  reference inside the word; Status, Prior and the other canonical fields are
  not label-checked; a finding opened by no heading at all inside another
  finding; a manifest mixing read findings with a table finding.
- Carried from round 13's brief: T030o43 review 3's R3-F7 and R3-F10, review
  4's R4-F3, R4-F5, R4-F6 and R4-F8; the harness-level bash startup environment
  and option variables; `TZ`; `PATH` choosing an undeclared tool; shipped 002's
  locale-dependent reset parsing; T030o42 review F2; T030o41 review 7's F1, F2,
  F4 and the unjudged K74 site; the kernel's ambient fixture reads; the analyzer
  field grammar with AC-023's narrowed reading; umbrella-only readers; the
  opponent-only totals, verdict and downgrade guards; README's missing
  Verification-Return grammar and completion marker; 001's legacy report failing
  `tally` at exit 3; the retained unexamined surfaces.

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

- Work in a copy outside the worktree (for example `/private/tmp/opp14/work`,
  with `TMPDIR` inside it, ending in `/`). Create, modify, move or remove NOTHING
  in the worktree except your report file. Run no floor, round, checkpoint,
  capture or accept, and no suite or test function in the worktree itself, and
  never source a file from `tests/` there (a suite file ends in `t_run_all`). The
  source must not move between reservation and completion, and the invoker
  checks that the worktree is byte-identical before and after your run.
- You may run a throwaway container of an image ALREADY on disk, within these
  limits only: `--rm`, `--network none`, your copy mounted read-only, nothing
  pulled, no other container touched, and Docker itself never stopped, started
  or restarted. Do not touch `mv-localstack` or any other container.
- Free disk: 7.0 GiB at reservation; swap shares the volume. Check `df -h /`
  before large copies, and remove your own directory when you finish.
- Never pipe a suite through `tail`. `tests/run.sh` prints no total, so its exit
  code is the signal. Capture exit codes and read them back.
- Write the report to `notes/verification/reports/opponent-round14.md` (exempt
  from the source identity), AND return it verbatim as your final message.

## Report grammar the gate will parse

The returned file is the round-14 block ALONE. `--complete` appends it to
`notes/opponent.md`, validates it with `vf_reports`, re-validates the floor to
the reserved source, and re-verifies rounds 1-13 against their sealed digests.

```
## Round 14

**Round:** 14
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
<!-- gate-round-end: opponent:14 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:14 -->`, and
nothing non-blank may follow it. These are the constraints `vf_reports`
enforces on the code under review, stated so that a correct report of either
verdict can be canonized. The verdict itself is yours alone.

- `Blocking`/`Minor` must equal the counted findings. CLEARED requires zero
  blocking, and CHALLENGED requires at least one.
- A CLEARED report may not carry a known ID at a tier below its strictest
  recorded tier, nor a `resolved` finding that an earlier round of this gate
  counted open. O-018 (new, wrong-result) and O-019 (new, minor) were counted
  open in round 13. So under CLEARED they may not appear as `### Finding`
  blocks, and your assessment of their repair belongs in the two prose sections.
- A CHALLENGED report may re-list findings with any status, at their true tier.
- Field values are read after their own label only: write one bold label per
  field line, and give a Class, Severity or Status line nothing below it in its
  list item (no continuation line, second paragraph or sub-bullet).
- Inside a finding, start no line with the word Class or Severity unless it is
  that field's line, and quote no Finding heading or field line in a fence,
  block quote or HTML comment anywhere in the round: quote examples inline, in a
  code span after another word (`the line \`#### Severity: data-loss\``).
  Outside every finding a fenced example of a field line is fine, but not of a
  Finding heading.
