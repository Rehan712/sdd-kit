# Opponent round 15 — reviewer brief

Written 2026-10-07 by the invoker (sessions 14 and 15). Everything here is a claim to attack, not
authority. The receipts named below outrank this text. Paths are relative to
the spec directory `.specify/specs/003-gate-round-reduction-and-token-discipline/`
unless they start with `scripts/`, `tests/`, `templates/`, `agents/`, `README.md`,
`.specify/stack.yml` or `.github/` (worktree root:
`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 15 is AUTHORIZED by the Decisions line `2026-10-07T09:18:21Z — waiver:
  gate=opponent; round=15; after=14; by=Rehan712; …`. Find it by its timestamp
  (neutral text above the Decisions log moves line numbers, and only the
  Decisions sections are hashed). `bash scripts/spec-gate.sh waiver <spec-dir>
  opponent 15` exited 0 and round 16 is refused at exit 4 at the freeze point
  (`notes/verification/reports/r15-freeze.txt`).
- Reservation (copy exactly into the report): **Round** 15 · **Source**
  @@SOURCE@@ · **Floor** @@FLOOR@@ · **reserved** @@RESERVED@@.
  Read them yourself from `notes/verification/rounds/opponent/ROUND-15/meta.nul`.

## Scope: what changed since round 14

Derived mechanically (`notes/verification/reports/r15-scope.sh`; `r15-scope.log`):
round 14's FLOOR-auyetN `inputs.nul` against @@FLOOR@@'s.

- Two accepted repairs, NOT yet gated independently, both answering round 14
  (`notes/verification/reports/opponent-round14.md`):
  - **T030o45** (round-14 O-020, blocking): a round's style is decided before
    its body. Once a round has a body (any non-blank line but its heading, its
    report title and its identity fields, quoted lines included), a title that
    would make a canonical round legacy and a Timestamp line that would make a
    legacy round canonical are each refused by name, in a round of either gate.
  - **T030o46** (round-14 O-018, reopened, blocking, with O-021 folded in): the
    label reader's rendered reading reduces bracket pairs innermost first to a
    fixpoint, takes out `*` inside a word, and a second rendered reading also
    takes out named references, numeric references beyond ASCII and every byte
    outside ASCII; both readers of finding records read a label from each
    paragraph as well as from each line (`vf_para`, `vf_para_label`); and
    `vf_block_start` admits every HTML block but condition 7 and backtick
    fences of three or more with no backtick in the info string (O-021).
  Task blocks in `tasks.md` (search `**T030o45**`, `**T030o46**`). Changed:
  `scripts/verification-lib.sh`, `templates/verification-contract.md`,
  `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`, 003's `tasks.md` and
  the Decisions log. The whole delta is `notes/verification/reports/r15-session.diff`
  (its two applies are `r15-session-1.diff` and `-2.diff`); the pairs are
  `r14-edits/kernel-1`, `vc-1`, `tgc-1`, `tsg-1` (applied by `r15-apply-1.*`) and
  `tgc-2` (applied by `r15-apply-2.*`). No focused review ran on this delta:
  round 15 is its independent gate.

Consumers of the changed files and every surface the spec declares are in
scope too, and you may expand into unchanged code.

## Evidence for the repair (claims, not authority)

- The decisions, in Decisions order from the entry "Opponent round 14 is
  recorded here now that this batch moves the source anyway" to the end:
  round 14's outcome, the user's decision, the reproduction, the T030o45 and
  T030o46 rules with their measurements, the task blocks, the round-15 waiver,
  and the freezing entry (which records the matrix probe's L18 correction).
- Reproduction before repair: `r14-repro.{sh,log,rc,time}` (exit 0, 606 PASS;
  CUR and PRE, `LANG=C` and `en_US.UTF-8`, direct and end to end; renderings
  by marked 17.0.5, which is not a strict CommonMark renderer).
- Measurement before adoption: `r14-measure.{sh,log,rc,time}` (exit 0, 1684
  PASS) with `r14-measure-suite.log` (the candidate's full suite, 146/147: only
  the predicted `value-details` row). Its count check for the returned round
  reports read as manifests reads 14 under a wrong label: it read twelve
  reports and round 3's reconcile record, the latter twice (recorded in Decisions).
- Fixtures judged in standalone copies before they were applied:
  `r14-fixtures-judge.{sh,log,rc,time}` (exit 0, 33 PASS; run 1 kept with a note)
  and `r15-fixtures-judge-2.{sh,log,rc,time}` (exit 0, the L18 row).
- Dev runs (each in a standalone copy, `TMPDIR` ending in `/`):
  `r15-dev1-{full,full-locale}.*` on the tree before `tgc-2` and
  `r15-dev2-{full,full-locale}.*` on the final tree. @@DEV2@@
- Mutation matrix of record: `r14-mutations.sh` (v3, 144 rows; v2 kept as
  `t030o44-mutations.sh`; the version the probe ran kept as
  `r14-mutations-v3-probe.sh`), dry runs `r14-mutations-dry{,2}.*`, probe
  `r14-mutations-probe.*` (rc 1 on L18 alone) and `-probe2.*` (exit 0), and the
  run of record `r14-mutations-shard{0,1}.{log,rc,start,end}`. @@MATRIX@@
- Acceptance: the freeze point `r15-freeze.txt`, the capture of record
  `r15-capture.{log,rc,start,end}` (@@CAPTURE@@), the returns
  `notes/verification/returns/T030o45.txt` and `T030o46.txt`
  (`r15-return-*.{log,rc}`), `T030o45-accept.{log,rc}`, `T030o46-accept.{log,rc}`
  and `r15-postaccept.txt`. No hosted CI has run on the reviewed source.
- The floor: @@FLOOR@@ (`r15-floor-@@ATTEMPT@@.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}`)
  and its validation (`r15-floor-validate.{out,err,rc,time}`); the scope diff
  against FLOOR-auyetN (`r15-scope.{log,rc}`); the reservation
  `r15-reserve.{log,rc,time}`.

## Known open — recorded, you may challenge it

- From the T030o45 and T030o46 rule entries: a round that carries a report title
  puts it, and every identity field, before its body; inside a finding, a
  paragraph whose rendered text begins with Class or Severity is refused, so a
  line that continues a paragraph is read with the line it continues; a fenced
  example is never joined, so a code example of a record line inside a finding is
  still refused line by line; the shared quoting tracker's divergences for its
  other consumers (unchanged); text a renderer hides by CSS or an attribute; a
  finding written in prose only (O-004); the readings stay approximations,
  refusing wherever one of them sees a label.
- From T030o44's rule entries: a report quotes an example of a Finding heading,
  or of a record line inside a finding, inline in a code span after another
  word, never in a fence, block quote or comment; a Class, Severity or Status
  item carries no continuation line, second paragraph or sub-bullet; a line
  inside a finding whose first word is Class or Severity followed by punctuation
  is refused (review F2's recorded extent); a reality-check gap writes its detail
  as prose; Status, Prior and the other canonical fields are not label-checked;
  a finding opened by no heading at all inside another finding; a manifest
  mixing read findings with a table finding.
- Carried from round 14's brief: T030o43 review 3's R3-F7 and R3-F10, review
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

- Work in a copy outside the worktree (for example `/private/tmp/opp15/work`,
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
- Free disk: @@FREE@@ at reservation; swap shares the volume. Check `df -h /`
  before large copies, and remove your own directory when you finish.
- Never pipe a suite through `tail`. `tests/run.sh` prints no total, so its exit
  code is the signal. Capture exit codes and read them back.
- Write the report to `notes/verification/reports/opponent-round15.md` (exempt
  from the source identity), AND return it verbatim as your final message.

## Report grammar the gate will parse

The returned file is the round-15 block ALONE. `--complete` appends it to
`notes/opponent.md`, validates it with `vf_reports`, re-validates the floor to
the reserved source, and re-verifies rounds 1-14 against their sealed digests.

```
## Round 15

**Round:** 15
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
<!-- gate-round-end: opponent:15 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:15 -->`, and
nothing non-blank may follow it. These are the constraints `vf_reports`
enforces on the code under review, stated so that a correct report of either
verdict can be canonized. The verdict itself is yours alone.

- The identity lines (Round, Timestamp, Source, Floor, Verdict, totals) come
  right after `## Round 15`, before any other line: under T030o45 a Timestamp
  line after the round's body is refused. Give the round no `# Opponent review`
  title line.
- `Blocking`/`Minor` must equal the counted findings. CLEARED requires zero
  blocking, and CHALLENGED requires at least one.
- A CLEARED report may not carry a known ID at a tier below its strictest
  recorded tier, nor a `resolved` finding that an earlier round of this gate
  counted open. O-020 (new, wrong-result), O-018 (reopened, wrong-result) and
  O-021 (new, minor) were counted open in round 14. So under CLEARED they may
  not appear as `### Finding` blocks, and your assessment of their repair
  belongs in the two prose sections.
- A CHALLENGED report may re-list findings with any status, at their true tier.
- Field values are read after their own label only: write one bold label per
  field line, and give a Class, Severity or Status line nothing below it in its
  list item (no continuation line, second paragraph or sub-bullet).
- Inside a finding, start no line or paragraph with the word Class or Severity
  unless it is that field's line; a paragraph is read whole, so this holds too
  when an inline tag, link or comment opened on one line puts that word first
  across a line break. Ordinary wrapped prose is unaffected. Quote no
  Finding heading or field line in a fence, block quote or HTML comment anywhere
  in the round: quote examples inline, in a code span after another word (`the
  line \`#### Severity: data-loss\``). Outside every finding a fenced example of
  a field line is fine, but not of a Finding heading.
