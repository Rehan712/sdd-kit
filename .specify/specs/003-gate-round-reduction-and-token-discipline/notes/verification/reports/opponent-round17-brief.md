# Opponent round 17 — reviewer brief

Written 2026-10-08 and finished 2026-10-09 by the invoker (session 18). Everything here is a claim to attack, not authority. The receipts
named below outrank this text. Paths are relative to the spec directory
`.specify/specs/003-gate-round-reduction-and-token-discipline/` unless they start with `scripts/`, `tests/`,
`templates/`, `agents/`, `README.md`, `.specify/stack.yml` or `.github/` (worktree root:
`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 17 is AUTHORIZED by the Decisions line `2026-10-08T16:41:11Z — waiver: gate=opponent; round=17; after=16;
  by=Rehan712; …`, written under the user's standing instruction of 2026-10-07 (the Decisions entry "User
  instruction of 2026-10-07 (session 15)") and the user's decision of 2026-10-08 on round 16's findings (the
  Decisions entry "User decision of 2026-10-08 (session 17)"). Find it by its timestamp (neutral text above the
  Decisions log moves line numbers, and only the Decisions sections are hashed). `bash scripts/spec-gate.sh waiver
  <spec-dir> opponent 17` exited 0 and round 18 is refused at exit 4 at the freeze point
  (`notes/verification/reports/r17-freeze.txt`).
- Reservation (copy exactly into the report): **Round** 17 · **Source**
  54c64d8346fe2459204e68de298f193bb5ea0abe8de86c00de159f05eac07129 · **Floor** FLOOR-QCFkfi · **reserved** 2026-10-09T00:10:44Z.
  Read them yourself from `notes/verification/rounds/opponent/ROUND-17/meta.nul`.

## Scope: what changed since round 16

Derived mechanically (`notes/verification/reports/r17-scope.sh`; `r17-scope.log`): round 16's FLOOR-UW5FIE
`inputs.nul` against FLOOR-QCFkfi's.

- Three accepted repairs, NOT yet gated independently, answering round 16 (`notes/verification/reports/opponent-round16.md`),
  under the user's decision of 2026-10-08 (narrow the grammar inside a finding rather than approximate a renderer;
  drop settled candidates; one to six marks):
  - **T030o48** (round-16 O-018, reopened, blocking): inside a finding, in both readers of finding records (the
    manifest pass, and the canonical pass of a canonical round before its completion marker), `vf_para` sets
    `vf_narrow` and the line is refused by name when it carries a form feed or vertical tab, or a carriage return
    that does not end the line (both read on the line as written), or a `<` followed by a letter, `/`, `!` or `?`
    outside every code span. `vf_cm_scan` places code spans by CommonMark 0.31.2 6.1 read left to right, 2.4's
    escapes taken in pairs and a backtick run closed only by the next run of the same length, for every state a
    paragraph may enter the line in (no open span, or a span an earlier line of the run left open, read both as an
    opener and as literal text); a `<` is inside a code span only when every reading places it there. The label
    reader's code-span reading (`vf_label_inert`) uses the same tokenizer. A run of lines ends only at a blank line
    of spaces and tabs (a final carriage return read as the line ending) or an ATX heading, never at a line the
    shared tracker calls fenced.
  - **T030o49** (round-16 O-022, blocking, a regression of T030o47): the heading that ends a run is an ATX heading
    of one to six marks after at most three spaces of indentation, read without block-quote markers.
  - **T030o50** (round-16 O-023, minor): a candidate is dropped once its text is settled (`vf_settled`: every
    construct a reading resolves across lines is closed within it, and every reading of it, and of the text after
    each br or block-level tag in it, already holds its first word); a candidate not shown settled is kept.
  Task blocks in `tasks.md` (search `**T030o48**`, `**T030o49**`, `**T030o50**`). Changed: `scripts/verification-lib.sh`,
  `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`, 003's `tasks.md`
  and the Decisions log. The whole delta is `notes/verification/reports/r17-session.diff` (its applies are
  `r17-session-1.diff` and `-2.diff`); the pairs are `r17-edits/kernel-1`, `vc-1`, `tgc-1`, `tsg-1` (applied by
  `r17-apply-1.*`) and `r17-edits/tgc-2` (applied by `r17-apply-2.*`). No focused review ran on this delta: round 17
  is its independent gate.

Consumers of the changed files and every surface the spec declares are in scope too, and you may expand into
unchanged code.

## Evidence for the repair (claims, not authority)

- The decisions, in Decisions order from the entry "Opponent round 16 is recorded here now that this batch moves
  the source anyway" to the end: round 16's outcome, the user's decision of 2026-10-08, the reproduction, the rule
  with its measurement, survey and stated consequences, the task blocks, the round-17 waiver, and the freezing entry.
- Reproduction before repair: `r17-repro.{sh,log,rc,time}` (exit 0, 283 PASS; CUR and PRE, `LANG=C` and
  `en_US.UTF-8`, both passes, direct and end to end; renderings by markdown-it 12.3.2 and marked 17.0.5; run 1 kept
  with a note).
- Survey of the recorded history: `r17-grammar-survey.{py,log,rc}` (exit 0; 22 files, 2188 lines inside findings,
  no raw HTML outside a code span, no form feed, vertical tab or carriage return inside a line).
- Measurement before adoption: `r17-measure.{sh,log,rc,time}` (exit 0, 1065 PASS) with `r17-measure-suite.log`
  (the candidate's full suite, 145/147, failing only on fixture rows that asserted raw HTML inside a finding parses;
  run 1 kept with a note).
- Fixtures judged in standalone copies before they were applied: `r17-fixtures-judge.{sh,log,rc,time}` (exit 0,
  40 PASS: `tgc-1`, `tsg-1`) and `r17-fixtures-judge-2.sh` with `r17-fixtures-judge-2-{0,1}.{log,rc,start,end}`
  (exit 0 each: `tgc-2`, rows the matrix needed, found by the exploratory `r17-discover.sh` with
  `r17-discover-mutants.py` and `r17-rows-probe.sh`).
- Dev runs (each in a standalone copy, `TMPDIR` ending in `/`, by `r15-dev.sh`): `r17-dev1-{full,full-locale}.*` on
  the tree before `r17-edits/tgc-2` and `r17-dev2-{full,full-locale}.*` on the final tree. All four exited 0, at
  147/147 over 15 suites plus ShellCheck, plainly and under `LANG=en_US.UTF-8` with every `LC_*` removed, each copy
  and the live status outside `notes/verification/` unchanged.
- Mutation matrix of record: `r17-mutations.sh` (v5, 227 rows, generated by `r17-mutations-gen.py` from v4
  `r15-mutations.sh`), dry runs `r17-mutations-dry.*` (exit 0; `-dry-run1.*` rc 1 on two carried literals the new
  `vf_settled_lead` made ambiguous), run 1 `r17-mutations-run1-shard{0,1,2}.*` with `r17-mutations-run1.note` (shard 0
  rc 1 on one row label, G08; the script it ran kept as `r17-mutations-v5-run1.sh`), the probe
  `r17-mutations-probe.*` (exit 0), and the run of record `r17-mutations-shard{0,1,2}.{log,rc,start,end}`, exit 0
  each, every one of the 227 rows exactly once: 152 kills and 43 over-corrections killed with exact diagnostics, 32
  argued equivalents surviving (each argued beside its row), 8 baselines, every restore byte-identical.
- Acceptance: the freeze point `r17-freeze.txt` (source `54c64d83…`, Decisions `b5c78e14…`), the capture of record
  `r17-capture.{log,rc,start,end}` (CAP-612-hpySUJ, exit 0, 147/147 over 15 suites plus ShellCheck, input the frozen
  source), the returns `notes/verification/returns/T030o4{8,9}.txt` and `T030o50.txt` (`r17-return-*.{log,rc}`,
  exit 0 each), `T030o48-accept.*`, `T030o49-accept.*`, `T030o50-accept.*` (exit 0 each; returns `4f7624e2…`,
  `a625ec10…`, `032317aa…`) and `r17-postaccept.txt`.
- The floor: FLOOR-QCFkfi (rc 0: source `54c64d83…`, 21 executed and 62 reused, 18:54:42Z to 23:41:51Z;
  `r17-floor-1.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}`; the Mac ran on battery from 19:48Z to about
  21:15Z, 101 of 289 samples, and free disk fell to 4.3 GiB from outside this work before recovering) and its
  validation (`r17-floor-validate.{out,err,rc,time}`); the scope diff against FLOOR-UW5FIE (`r17-scope.{log,rc}`);
  the reservation `r17-reserve.{log,rc,time}`.
- No hosted CI has run on the reviewed source.

## Known open — recorded, you may challenge it

- From the T030o48 to T030o50 rule entry: inside a finding, raw HTML outside a code span is refused by name wherever
  it stands, so a report writes markup inside a finding only as code, between backticks; T030o47's positives that
  carried a tag, a br or a comment inside a finding, O-021's HTML blocks after a field line, a fenced example holding
  a tag inside a finding, and a tag inside a code span that spans lines are refused by name; a four-backtick fence
  after a field line still ends that line's item; raw HTML outside every finding parses as before; a fenced block
  inside a finding no longer ends the run reader's run, so an example inside a real fence whose lines join into a
  tier is refused. Recorded extent: the shared quoting tracker's divergences for its other consumers (unchanged);
  text a renderer hides by CSS or an attribute; a finding written in prose only (O-004); a code span inside a word;
  outside the narrowed grammar the readings stay approximations, refusing wherever one of them sees a label.
- The matrix's argued equivalents (each argued beside its row in `r17-mutations.sh`), among them the HTML clauses
  of `vf_block_start` (B05, B07, B14, B14c, B17), which the narrowed grammar now shields inside a finding.
- From T030o47's rule entry: a line or a canonical field value whose text after a br or block-level tag begins with
  Class or Severity is refused; the readings are approximations.
- From the T030o45 and T030o46 rule entries: a round that carries a report title puts it, and every identity field,
  before its body.
- From T030o44's rule entries: a report quotes an example of a Finding heading, or of a record line inside a
  finding, inline in a code span after another word, never in a fence, block quote or comment; a Class, Severity or
  Status item carries no continuation line, second paragraph or sub-bullet; a line inside a finding whose first word
  is Class or Severity followed by punctuation is refused; a reality-check gap writes its detail as prose; Status,
  Prior and the other canonical fields are not label-checked; a finding opened by no heading at all inside another
  finding; a manifest mixing read findings with a table finding.
- Observed in session 17 (`r16-floor-1.note`), recorded and not repaired: a fixture that completes a round within
  seconds of its own reservation is refused when the wall clock steps backwards in between; it fails closed.
- Carried from round 16's brief: T030o43 review 3's R3-F7 and R3-F10, review 4's R4-F3, R4-F5, R4-F6 and R4-F8; the
  harness-level bash startup environment and option variables; `TZ`; `PATH` choosing an undeclared tool; shipped
  002's locale-dependent reset parsing; T030o42 review F2; T030o41 review 7's F1, F2, F4 and the unjudged K74 site;
  the kernel's ambient fixture reads; the analyzer field grammar with AC-023's narrowed reading; umbrella-only
  readers; the opponent-only totals, verdict and downgrade guards; README's missing Verification-Return grammar and
  completion marker; 001's legacy report failing `tally` at exit 3; the retained unexamined surfaces.

## Method this spec requires

1. Derive each criterion from the grammar or production the code reads, with its source. An enumeration of
   reported spellings is satisfiable while the class stays open.
2. Test a proposed rule against the real recorded history (`notes/opponent.md`, and 001's and 002's reports)
   before proposing it.
3. Mutation-isolate guards in both directions, and restore byte-identically (`cmp`).
4. Assert exact diagnostics, never exit codes alone.
5. Hunt for shipped POSITIVES that assert an attack at rc=0.

## Operational rules

- Work in a copy outside the worktree (for example `/private/tmp/opp17/work`, with `TMPDIR` inside it, ending in
  `/`). Create, modify, move or remove NOTHING in the worktree except your report file. Run no floor, round,
  checkpoint, capture or accept, and no suite or test function in the worktree itself, and never source a file from
  `tests/` there (a suite file ends in `t_run_all`). The source must not move between reservation and completion,
  and the invoker checks that the worktree is byte-identical before and after your run.
- You may run a throwaway container of an image ALREADY on disk, within these limits only: `--rm`,
  `--network none`, your copy mounted read-only, nothing pulled, no other container touched, and Docker itself
  never stopped, started or restarted. Do not touch `mv-localstack` or any other container.
- Free disk: 14 GiB at reservation; swap shares the volume. Check `df -h /` before large copies, and remove your
  own directory when you finish.
- Never pipe a suite through `tail`. `tests/run.sh` prints no total, so its exit code is the signal. Capture exit
  codes and read them back.
- Write the report to `notes/verification/reports/opponent-round17.md` (exempt from the source identity), AND
  return it verbatim as your final message. If your file tool refuses the path, return the block alone; the invoker
  persists it and checks it byte-identical.

## Report grammar the gate will parse

The returned file is the round-17 block ALONE. `--complete` appends it to `notes/opponent.md`, validates it with
`vf_reports`, re-validates the floor to the reserved source, and re-verifies rounds 1-16 against their sealed
digests.

```
## Round 17

**Round:** 17
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
<!-- gate-round-end: opponent:17 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:17 -->`, and nothing non-blank may follow it. These
are the constraints `vf_reports` enforces on the code under review, stated so that a correct report of either
verdict can be canonized. The verdict itself is yours alone.

- The identity lines (Round, Timestamp, Source, Floor, Verdict, totals) come right after `## Round 17`, before any
  other line: a Timestamp line after the round's body is refused. Give the round no `# Opponent review` title line.
- `Blocking`/`Minor` must equal the counted findings. CLEARED requires zero blocking, and CHALLENGED requires at
  least one.
- A CLEARED report may not carry a known ID at a tier below its strictest recorded tier, nor a `resolved` finding
  that an earlier round of this gate counted open. O-018 (reopened) and O-022 were counted open in round 16, and
  O-023 at minor. So under CLEARED they may not appear as `### Finding` blocks, and your assessment of their repair
  belongs in the two prose sections.
- A CHALLENGED report may re-list findings with any status, at their true tier.
- Field values are read after their own label only: write one bold label per field line, and give a Class, Severity
  or Status line nothing below it in its list item (no continuation line, second paragraph or sub-bullet).
- NEW under T030o48: inside a finding (from its `### Finding` heading to the next heading as shallow), write no `<`
  followed by a letter, `/`, `!` or `?` outside a code span: no tag, br, comment, autolink or processing instruction,
  not even in a fenced block, a block quote or a code span that spans lines. Quote markup inline, in a single-line
  code span (`` `<br>` ``), or describe it in words. Write no form feed or vertical tab, and no carriage return
  except as a line ending. Outside every finding (What I attacked, Held up) raw HTML parses as before.
- Inside a finding, start no line, and no run of non-blank lines, with text that reads as the word Class or Severity
  unless it is that field's line: every line of a run is read with the lines after it. Quote no Finding heading or
  field line in a fence, block quote or HTML comment anywhere in the round: quote examples inline, in a code span
  after another word (`the line \`#### Severity: data-loss\``). Outside every finding a fenced example of a field
  line is fine, but not of a Finding heading.
