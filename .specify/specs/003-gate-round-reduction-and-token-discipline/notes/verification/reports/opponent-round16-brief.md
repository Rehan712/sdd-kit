# Opponent round 16 — reviewer brief

Written 2026-10-07 by the invoker (session 16) and finished 2026-10-08 (session 17). Everything here is a claim to attack, not
authority. The receipts named below outrank this text. Paths are relative to
the spec directory `.specify/specs/003-gate-round-reduction-and-token-discipline/`
unless they start with `scripts/`, `tests/`, `templates/`, `agents/`, `README.md`,
`.specify/stack.yml` or `.github/` (worktree root:
`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 16 is AUTHORIZED by the Decisions line `2026-10-07T21:10:41Z — waiver:
  gate=opponent; round=16; after=15; by=Rehan712; …`, written under the user's
  standing instruction of 2026-10-07 (the Decisions entry "User instruction of
  2026-10-07 (session 15)"). Find it by its timestamp (neutral text above the
  Decisions log moves line numbers, and only the Decisions sections are hashed).
  `bash scripts/spec-gate.sh waiver <spec-dir> opponent 16` exited 0 and round 17
  is refused at exit 4 at the freeze point (`notes/verification/reports/r16-freeze.txt`).
- Reservation (copy exactly into the report): **Round** 16 · **Source**
  eee97354a5aa4069a44c3791db4b576486502299450a7d3a89739677ec949c12 · **Floor** FLOOR-UW5FIE · **reserved** 2026-10-08T11:38:55Z.
  Read them yourself from `notes/verification/rounds/opponent/ROUND-16/meta.nul`.

## Scope: what changed since round 15

Derived mechanically (`notes/verification/reports/r16-scope.sh`; `r16-scope.log`):
round 15's FLOOR-dCwGgb `inputs.nul` against FLOOR-UW5FIE's.

- One accepted repair, NOT yet gated independently, answering round 15
  (`notes/verification/reports/opponent-round15.md`):
  - **T030o47** (round-15 O-018, reopened, blocking): both readers of finding
    records keep a run of non-blank lines that only a blank line, a line in a
    code fence or an ATX heading of at most three spaces ends (a heading inside a
    block quote included), read each line without its indentation and
    block-quote markers, and take every line of the run as a candidate paragraph
    start (`vf_para`, `vf_para_label`), so a paragraph boundary the reader misses
    or invents can only refuse; the label reader adds a reading that keeps the
    letters and digits of every code span and makes its other characters inert
    (`vf_label_inert`), and reads the label after each br tag and each
    condition-6 block-level tag, open or closing, outside code spans
    (`vf_label_breaks`), in prose and, in the canonical pass, in the value of
    every field line of a canonical round.
  Task block in `tasks.md` (search `**T030o47**`). Changed:
  `scripts/verification-lib.sh`, `templates/verification-contract.md`,
  `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`, 003's `tasks.md` and
  the Decisions log. The whole delta is `notes/verification/reports/r16-session.diff`;
  the pairs are `r15-edits/kernel-1`, `vc-1`, `tgc-1`, `tsg-1` (applied by
  `r16-apply-1.*`). No focused review ran on this delta: round 16 is its
  independent gate.

Consumers of the changed files and every surface the spec declares are in
scope too, and you may expand into unchanged code.

## Evidence for the repair (claims, not authority)

- The decisions, in Decisions order from the entry "Opponent round 15 is
  recorded here now that this batch moves the source anyway" to the end:
  round 15's outcome, the user's standing instruction and the invoker's reading
  of it, the reproduction, the T030o47 rule with its measurement and its
  correction before adoption, the task block, the round-16 waiver, and the
  freezing entry.
- Reproduction before repair: `r15-repro.{sh,log,rc,time}` (exit 0, 166 PASS;
  CUR and PRE, `LANG=C` and `en_US.UTF-8`, both passes, direct and end to end;
  renderings by markdown-it 12.3.2 and marked 17.0.5).
- Measurement before adoption: `r15-measure.{sh,log,rc,time}` (exit 0, 975 PASS)
  with `r15-measure-suite.log` (the candidate's full suite, 147/147). Run 1
  (`r15-measure-run1.*`, with a note) measured a first candidate that made every
  character of a code span inert and was stopped; the adopted reading keeps
  letters and digits.
- Fixtures judged in standalone copies before they were applied:
  `r16-fixtures-judge.{sh,log,rc,time}` (exit 0, the judge of record);
  `r15-fixtures-judge.*` judged the pairs before two canonical rows were added
  (`r15-fixtures-judge.note`, `r15-edits/tgc-1-run5.pairs`); runs 1 to 4 kept
  with notes.
- Dev runs (each in a standalone copy, `TMPDIR` ending in `/`, by `r15-dev.sh`):
  `r16-dev1-{full,full-locale}.*` on the tree before `r16-edits/tgc-2` and
  `r16-dev2-{full,full-locale}.*` on the final tree. All four exited 0, at 147/147 over 15 suites plus ShellCheck, plainly and under `LANG=en_US.UTF-8` with every `LC_*` removed, each copy and the live status outside `notes/verification/` unchanged.
- Mutation matrix of record: `r15-mutations.sh` (v4, 171 rows, generated by
  `r15-mutations-gen.py`, which reproduces it byte-identically; v3 kept as
  `r14-mutations.sh`), dry runs `r16-mutations-dry{,2}.*` (exit 0), probe
  `r16-mutations-probe.*` (rc 1: X12, recorded as an argued equivalent, was killed by the heading-label rows and is now a kill row; the scripts it ran are kept as `r15-mutations-v4-probe.sh` and `r15-mutations-gen-v4-probe.py`) and `-probe2.*` (exit 0), run 1
  `r16-mutations-run1-shard{0,1}.*` with `r16-mutations-run1.note` (shard 0 rc 1: L17 survived, because T030o47's code-span reading also reads its only row; a row isolating it, a tier behind an undefined footnote reference, was added in both passes: `r16-l17-probe.*`, `r16-edits/tgc-2.pairs`, judged by `r16-fixtures-judge-2.*`, exit 0, applied by `r16-apply-2.*`, exit 0), `-probe3.*` (exit 0), and the
  run of record `r16-mutations-shard{0,1}.{log,rc,start,end}`. The run of record exited 0 in each shard, every one of the 171 rows exactly once: 121 kills and 39 over-corrections killed with exact diagnostics, 11 argued equivalents surviving (L05, L19, R03b, Q08, B12, S06, P18, P19, P20, P21, X11; each argued beside its row), 8 baselines, every restore byte-identical.
- Acceptance: the freeze point `r16-freeze.txt` (run 1 kept as `r16-freeze-run1.*`
  with a note), the capture of record `r16-capture.{log,rc,start,end}`
  (CAP-589-ZNd9Ug, exit 0, 147/147 over 15 suites plus ShellCheck, input `eee97354…`, the frozen source), the return
  `notes/verification/returns/T030o47.txt` (`r16-return-T030o47.{log,rc}`, exit 0),
  `T030o47-accept.{log,rc}` (exit 0, return `2a8d2a94…`) and `r16-postaccept.txt`.
  No hosted CI has run on the reviewed source.
- The floor: FLOOR-UW5FIE (rc 0: source `eee97354…`, 12 executed and 68 reused, 07:43:36Z
  to 11:07:48Z on AC; `r16-floor-2.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}`;
  attempt 1, `r16-floor-1.*`, failed at rc 1 on a backward wall-clock step during
  a fixture and sealed nothing: `r16-floor-1.note`, `r16-floor-1-timed.log`)
  and its validation (`r16-floor-validate.{out,err,rc,time}`); the scope diff
  against FLOOR-dCwGgb (`r16-scope.{log,rc}`); the reservation
  `r16-reserve.{log,rc,time}`.

## Known open — recorded, you may challenge it

- From the T030o47 rule entry: inside a finding, a line after which the text
  joined from an earlier line of its run reads, as written or as rendered, as a
  Class or Severity line is refused, so a run of lines is read from each of its
  lines; a code span's syntax opens and closes nothing in that reading; a line
  or a canonical field value whose text after a br or block-level tag begins
  with Class or Severity is refused. Recorded extent: the shared quoting
  tracker's divergences for its other consumers (unchanged); text a renderer
  hides by CSS or an attribute; a finding written in prose only (O-004); a code
  span inside a word (round 15's non-blocking note, left to the user, as
  intraword emphasis was); the readings stay approximations, refusing wherever
  one of them sees a label.
- From the T030o45 and T030o46 rule entries: a round that carries a report title
  puts it, and every identity field, before its body; a fenced example is never
  joined, so a code example of a record line inside a finding is still refused
  line by line.
- From T030o44's rule entries: a report quotes an example of a Finding heading,
  or of a record line inside a finding, inline in a code span after another
  word, never in a fence, block quote or comment; a Class, Severity or Status
  item carries no continuation line, second paragraph or sub-bullet; a line
  inside a finding whose first word is Class or Severity followed by punctuation
  is refused (review F2's recorded extent); a reality-check gap writes its detail
  as prose; Status, Prior and the other canonical fields are not label-checked;
  a finding opened by no heading at all inside another finding; a manifest
  mixing read findings with a table finding.
- Observed in session 17 (`r16-floor-1.note`), recorded and not repaired: a
  fixture that completes a round within seconds of its own reservation
  (`round_report` in `tests/test-spec-gate.sh`, which stamps the report at the
  reservation's second) is refused when the wall clock steps backwards in
  between (`scripts/verification-lib.sh:3373` refuses a Timestamp later than
  `date -u`); it failed floor attempt 1 closed, never as a wrong PASS.
- Carried from round 15's brief: T030o43 review 3's R3-F7 and R3-F10, review
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

- Work in a copy outside the worktree (for example `/private/tmp/opp16/work`,
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
- Free disk: 10 GiB at reservation; swap shares the volume. Check `df -h /`
  before large copies, and remove your own directory when you finish.
- Never pipe a suite through `tail`. `tests/run.sh` prints no total, so its exit
  code is the signal. Capture exit codes and read them back.
- Write the report to `notes/verification/reports/opponent-round16.md` (exempt
  from the source identity), AND return it verbatim as your final message. If
  your file tool refuses the path, return the block alone; the invoker persists
  it and checks it byte-identical.

## Report grammar the gate will parse

The returned file is the round-16 block ALONE. `--complete` appends it to
`notes/opponent.md`, validates it with `vf_reports`, re-validates the floor to
the reserved source, and re-verifies rounds 1-15 against their sealed digests.

```
## Round 16

**Round:** 16
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
<!-- gate-round-end: opponent:16 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:16 -->`, and
nothing non-blank may follow it. These are the constraints `vf_reports`
enforces on the code under review, stated so that a correct report of either
verdict can be canonized. The verdict itself is yours alone.

- The identity lines (Round, Timestamp, Source, Floor, Verdict, totals) come
  right after `## Round 16`, before any other line: a Timestamp line after the
  round's body is refused. Give the round no `# Opponent review` title line.
- `Blocking`/`Minor` must equal the counted findings. CLEARED requires zero
  blocking, and CHALLENGED requires at least one.
- A CLEARED report may not carry a known ID at a tier below its strictest
  recorded tier, nor a `resolved` finding that an earlier round of this gate
  counted open. O-018 (reopened, wrong-result) was counted open in round 15, and
  O-020 and O-021 in round 14. So under CLEARED they may not appear as
  `### Finding` blocks, and your assessment of their repair belongs in the two
  prose sections.
- A CHALLENGED report may re-list findings with any status, at their true tier.
- Field values are read after their own label only: write one bold label per
  field line, and give a Class, Severity or Status line nothing below it in its
  list item (no continuation line, second paragraph or sub-bullet).
- Inside a finding, start no line, and no run of non-blank lines, with text that
  reads as the word Class or Severity unless it is that field's line: under
  T030o47 every line of a run is read with the lines after it, so a word Class
  or Severity that begins the joined text from any line refuses, and so does
  one right after a `<br>` or block-level tag, in prose or in a field value.
  Ordinary wrapped prose is unaffected. Quote no Finding heading or field line
  in a fence, block quote or HTML comment anywhere in the round: quote examples
  inline, in a code span after another word (`the line \`#### Severity:
  data-loss\``). Outside every finding a fenced example of a field line is fine,
  but not of a Finding heading.
