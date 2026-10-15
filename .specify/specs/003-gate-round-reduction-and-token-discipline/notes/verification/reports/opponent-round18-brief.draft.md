# Opponent round 18 — reviewer brief

Written @@WRITTEN@@ by the invoker (session 20). Everything here is a claim to attack, not authority. The receipts
named below outrank this text. Paths are relative to the spec directory
`.specify/specs/003-gate-round-reduction-and-token-discipline/` unless they start with `scripts/`, `tests/`,
`templates/`, `agents/`, `README.md`, `.specify/stack.yml` or `.github/` (worktree root:
`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 18 is AUTHORIZED by the Decisions line `2026-10-09T09:41:41Z — waiver: gate=opponent; round=18; after=17;
  by=Rehan712; …`, written under the user's standing instruction of 2026-10-07 (the Decisions entry "User
  instruction of 2026-10-07 (session 15)") and the user's decision of 2026-10-09 on round 17's findings (the
  Decisions entry "User decision of 2026-10-09 (session 19)"). Find it by its timestamp (neutral text above the
  Decisions log moves line numbers, and only the Decisions sections are hashed). `bash scripts/spec-gate.sh waiver
  <spec-dir> opponent 18` exited 0 and round 19 is refused at exit 4 at the freeze point
  (`notes/verification/reports/r18-freeze.txt`).
- Reservation (copy exactly into the report): **Round** 18 · **Source** @@SOURCE@@ · **Floor** @@FLOOR@@ ·
  **reserved** @@RESERVED@@. Read them yourself from `notes/verification/rounds/opponent/ROUND-18/meta.nul`.

## Scope: what changed since round 17

Derived mechanically (`notes/verification/reports/r18-scope.sh`; `r18-scope.log`): round 17's FLOOR-QCFkfi
`inputs.nul` against @@FLOOR@@'s.

- Three accepted repairs, NOT yet gated independently, answering round 17 (`notes/verification/reports/opponent-round17.md`),
  under the user's decision of 2026-10-09 (O-018: narrow further; O-024: narrow, the reviewer's M2; O-023: the
  reviewer's M3, corrected for soundness), with the round's minor folded into T030o51 by the invoker:
  - **T030o51** (round-17 O-018, reopened, blocking, and the minor): inside a finding, in both readers of finding
    records (the manifest pass, and the canonical pass of a canonical round before its completion marker),
    T030o48's narrowed grammar gains three reasons, each read in every reading `vf_cm_scan` makes of the line: a `<`
    followed by a digit or a symbol an email address's local part may begin with (`.#$%&'*+=^_{|}~-` or a backtick)
    outside every code span (`an autolink outside a code span`); an inline link's destination or title, or a full
    reference link's label, read from a `]` followed by `(` or `[` that some reading places outside every code span
    (`vf_cm_dest`, `vf_cm_label`, by 6.3's productions), that holds a backtick (`a backtick inside a link
    destination, title or label`) or does not end on its line (`a link destination, title or label that does not
    end on its line`); a `](` or `][` every reading places inside a code span is literal. The minor: the narrowed
    check is judged after the line's own heading has opened or closed a finding, in both passes.
  - **T030o52** (round-17 O-024, new, blocking, plan-gap): inside a finding, in both readers, a line is refused by
    name when it opens a code fence (three or more backticks or tildes) after indentation or a list marker, anywhere
    but at the start of the line (`a code fence that may be inside a list item`), and when its text, after
    indentation, list markers and block-quote markers, begins a link reference definition, or closes by `]:` a label
    that a bracket at the start of an earlier line of its run left open (`a link reference definition`); the run
    reader carries an open label to the next line of its run and drops it with the run.
  - **T030o53** (round-17 O-023, reopened, minor): a candidate is settled once every code span and raw-HTML
    construct in it is closed and every reading of it (as written, the inert code-span reading, the rendered
    readings of both, and the readings after each br or block-level tag) holds its first word with no bracket pair
    or link destination left open at or before that word in that reading (`vf_settled_word`, `vf_settled_head`,
    ordered-list numbers and task checkboxes counted before the word); the invoker's correction to M3 (which read
    the as-written head only) keeps `&nbsp;![q` and `1. ![q` unsettled.
  Task blocks in `tasks.md` (search `**T030o51**`, `**T030o52**`, `**T030o53**`). Changed: `scripts/verification-lib.sh`,
  `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`, 003's `tasks.md`
  and the Decisions log. The whole delta is `notes/verification/reports/r18-session.diff` (its applies are
  `r18-session-1.diff` to `-3.diff`); the pairs are `r18-edits/kernel-1`, `vc-1`, `tgc-1`, `tsg-1` (applied by
  `r18-apply-1.*`), `r18-edits/tgc-2` (applied by `r18-apply-2.*`) and `r18-edits/tgc-3` (applied by `r18-apply-3.*`). No focused review ran on this delta: round 18
  is its independent gate.

Consumers of the changed files and every surface the spec declares are in scope too, and you may expand into
unchanged code.

## Evidence for the repair (claims, not authority)

- The decisions, in Decisions order from the entry "Opponent round 17 is recorded here now that this batch moves
  the source anyway" to the end: round 17's outcome, the user's decision of 2026-10-09, the reproduction, the rules
  with their measurement, survey and stated consequences, the task blocks, the round-18 waiver, and the freezing
  entry.
- Reproduction before repair: `r18-repro.{sh,log,rc,time}` (exit 0, 231 PASS; CUR and PRE, `LANG=C` and
  `en_US.UTF-8`, both passes, direct and end to end; renderings by markdown-it 12.3.2 and marked 17.0.5).
- Survey of the recorded history: `r18-grammar-survey.{py,log,rc}` (exit 0; 23 files, 2326 lines inside findings).
- Measurement before adoption: `r18-measure.{sh,log,rc,time}` (exit 0, 1380 PASS) with `r18-measure-suite.log`
  (the candidate's full suite, 147/147; run 1 stopped and kept with a note).
- Fixtures judged in standalone copies before they were applied: `r18-fixtures-judge.{sh,log,rc,time}` (exit 0,
  58 PASS: `tgc-1`, `tsg-1`; run 1 kept with a note) and `r18-fixtures-judge-2.sh` with
  `r18-fixtures-judge-2-{0,1,2}.{log,rc,start,end}` (run 4, exit 0 each: `tgc-2`, rows the matrix needed, found by
  the exploratory `r18-discover.sh` with `r18-discover-mutants.py`; runs 1 to 3 kept with notes: run 2 found three
  rows completing their construct on the next line, which no settled-test mutant can reach, and run 3's pairs lacked
  rows for three mutants session 19 had listed as equivalents, `r18-rows-probe{,-2}.*`, `r18-rows-render{,-2}.*`), and
  `r18-fixtures-judge-3.{sh,log,rc,start,end}` (exit 0: `tgc-3`, the row matrix run 1 needed for v5's D04,
  `r18-rows-probe-3.*`).
- Dev runs (each in a standalone copy, `TMPDIR` ending in `/`, by `r15-dev.sh`): `r18-dev1-{full,full-locale}.*` on
  the tree before `r18-edits/tgc-2`, `r18-dev2-{full,full-locale}.*` before `tgc-3` and `r18-dev3-{full,full-locale}.*`
  on the final tree. All six exited 0, at 147/147 over 15 suites plus ShellCheck, plainly and under `LANG=en_US.UTF-8` with every `LC_*` removed, each copy and the live status outside `notes/verification/` unchanged.
- Mutation matrix of record: `r18-mutations.sh` (v6, generated by `r18-mutations-gen.py` from v5 `r17-mutations.sh`
  and the discovery mutants), dry runs `r18-mutations-dry.*` (exit 0;
  `-dry-run1.*` rc 1 on L15 and K05, whose literals the repair moved, `-dry-run2.*` exit 0), the probe of the 100 new and
  re-targeted rows `r18-mutations-probe-shard{0,1,2}.*` (exit 0 each), run 1 `r18-mutations-run1-shard{0,1,2}.*` with
  `r18-mutations-run1.note` (shards 1 and 2 rc 1 on D02, D04 and D11, three v5 rows the head bracket test changed; the
  script it ran kept as `r18-mutations-v6-run1.sh`), the probe `r18-mutations-probe2.*` (exit 0), and the run of record
  `r18-mutations-shard{0,1,2}.{log,rc,start,end}`, exit 0 each, every one of the 303 rows exactly once: 213 kills and 57
  over-corrections killed with exact diagnostics (D02 by the judge's 900 s watchdog), 33 argued equivalents surviving
  (each argued beside its row), 8 baselines, every restore byte-identical.
- Acceptance: the freeze point `r18-freeze.txt` (source `567cb6e0…`, Decisions `02b9cc4c…`), the capture of record
  `r18-capture.{log,rc,start,end}` (CAP-634-14RLF3, exit 0, 147/147 over 15 suites plus ShellCheck, input the frozen
  source), the returns `notes/verification/returns/T030o5{1,2,3}.txt` (`r18-return-T030o5{1,2,3}.{log,rc}`, exit 0
  each), `T030o51-accept.*`, `T030o52-accept.*`, `T030o53-accept.*` (exit 0 each; returns `505b44cb…`, `6289f739…`,
  `0e8a0252…`) and `r18-postaccept.txt`.
- The floor: @@FLOORRUN@@
- No hosted CI has run on the reviewed source.

## Known open — recorded, you may challenge it

- From the T030o51 to T030o53 rule entry: inside a finding a comparison written `c <= d` or `<30` is refused (a
  report writes it as code, or with a space after the `<`); a code example inside a finding is a fence at the start
  of a line, and one indented under a list item or opened after a list marker is refused; a link whose destination
  or title wraps, or a reference label that wraps, is refused; link definitions stay outside every finding; a
  section heading carrying raw HTML that closes a finding is outside it and parses. Recorded extent: the shared
  quoting tracker's divergences for its other consumers (unchanged); text a renderer hides by CSS or an attribute;
  a finding written in prose only (O-004); a code span inside a word; a link definition outside every finding whose
  title spans into a later finding's lines; outside the narrowed grammar the readings stay approximations, refusing
  wherever one of them sees a label.
- The matrix's argued equivalents (each argued beside its row in `r18-mutations.sh`), among them six new ones of the
  repair (G07, VB07, VH08, VR10, VS04, VS05) and v5's D11, re-argued under the head bracket test.
- From the T030o48 to T030o50 rule entry: inside a finding, raw HTML outside a code span is refused by name wherever
  it stands, a fenced block no longer ends the run reader's run, and the readings outside the narrowed grammar stay
  approximations.
- From T030o47's rule entry: a line or a canonical field value whose text after a br or block-level tag begins with
  Class or Severity is refused.
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
- Carried from round 17's brief: T030o43 review 3's R3-F7 and R3-F10, review 4's R4-F3, R4-F5, R4-F6 and R4-F8; the
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

- Work in a copy outside the worktree (for example `/private/tmp/opp18/work`, with `TMPDIR` inside it, ending in
  `/`). Create, modify, move or remove NOTHING in the worktree except your report file. Run no floor, round,
  checkpoint, capture or accept, and no suite or test function in the worktree itself, and never source a file from
  `tests/` there (a suite file ends in `t_run_all`). The source must not move between reservation and completion,
  and the invoker checks that the worktree is byte-identical before and after your run.
- You may run a throwaway container of an image ALREADY on disk, within these limits only: `--rm`,
  `--network none`, your copy mounted read-only, nothing pulled, no other container touched, and Docker itself
  never stopped, started or restarted. Do not touch `mv-localstack` or any other container.
- Free disk: @@DISK@@ at reservation; swap shares the volume. Check `df -h /` before large copies, and remove your
  own directory when you finish.
- Never pipe a suite through `tail`. `tests/run.sh` prints no total, so its exit code is the signal. Capture exit
  codes and read them back.
- Write the report to `notes/verification/reports/opponent-round18.md` (exempt from the source identity), AND
  return it verbatim as your final message. If your file tool refuses the path, return the block alone; the invoker
  persists it and checks it byte-identical.

## Report grammar the gate will parse

The returned file is the round-18 block ALONE. `--complete` appends it to `notes/opponent.md`, validates it with
`vf_reports`, re-validates the floor to the reserved source, and re-verifies rounds 1-17 against their sealed
digests.

```
## Round 18

**Round:** 18
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
<!-- gate-round-end: opponent:18 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:18 -->`, and nothing non-blank may follow it. These
are the constraints `vf_reports` enforces on the code under review, stated so that a correct report of either
verdict can be canonized. The verdict itself is yours alone.

- The identity lines (Round, Timestamp, Source, Floor, Verdict, totals) come right after `## Round 18`, before any
  other line: a Timestamp line after the round's body is refused. Give the round no `# Opponent review` title line.
- `Blocking`/`Minor` must equal the counted findings. CLEARED requires zero blocking, and CHALLENGED requires at
  least one.
- A CLEARED report may not carry a known ID at a tier below its strictest recorded tier, nor a `resolved` finding
  that an earlier round of this gate counted open. O-018 (reopened) and O-024 were counted open in round 17 at
  wrong-result, and O-023 at degraded, a minor tier. So under CLEARED they may not appear as `### Finding` blocks, and your
  assessment of their repair belongs in the two prose sections.
- A CHALLENGED report may re-list findings with any status, at their true tier.
- Field values are read after their own label only: write one bold label per field line, and give a Class, Severity
  or Status line nothing below it in its list item (no continuation line, second paragraph or sub-bullet).
- Under T030o48: inside a finding (from its `### Finding` heading to the next heading as shallow), write no `<`
  followed by a letter, `/`, `!` or `?` outside a code span: no tag, br, comment or processing instruction, not even
  in a fenced block, a block quote or a code span that spans lines. Write no form feed or vertical tab, and no
  carriage return except as a line ending.
- NEW under T030o51: inside a finding, write no `<` followed by a digit or by one of `.#$%&'*+=^_{|}~-` or a
  backtick outside a code span (write `a < b` with a space, or quote it as code); give no inline link destination or
  title, and no full reference link label, a backtick, and never let one wrap onto the next line; quote such
  markup in a single-line code span, or describe it in words. A heading inside a finding (a deeper heading, or the
  Finding heading itself) is judged too: carry no raw HTML on it.
- NEW under T030o52: inside a finding, open a code fence only at the very start of a line (no indentation, no list
  marker before it), and write no link reference definition (no line whose text begins with a bracket closed by
  `]:`, after a list or block-quote marker included). Outside every finding (What I attacked, Held up) all of these
  parse as before.
- Inside a finding, start no line, and no run of non-blank lines, with text that reads as the word Class or Severity
  unless it is that field's line: every line of a run is read with the lines after it. Quote no Finding heading or
  field line in a fence, block quote or HTML comment anywhere in the round: quote examples inline, in a code span
  after another word (`the line \`#### Severity: data-loss\``). Outside every finding a fenced example of a field
  line is fine, but not of a Finding heading.
