# Opponent round 19 — reviewer brief

Written @@WRITTEN@@ by the invoker (session 22). Everything here is a claim to attack, not authority. The receipts
named below outrank this text. Paths are relative to the spec directory
`.specify/specs/003-gate-round-reduction-and-token-discipline/` unless they start with `scripts/`, `tests/`,
`templates/`, `agents/`, `README.md`, `.specify/stack.yml` or `.github/` (worktree root:
`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 19 is AUTHORIZED by the Decisions line `2026-10-15T00:22:50Z — waiver: gate=opponent; round=19; after=18;
  by=Rehan712; …`, written under the user's standing instruction of 2026-10-07 (the Decisions entry "User
  instruction of 2026-10-07 (session 15)") and the user's decision of 2026-10-14 on round 18's findings (the
  Decisions entry "User decision of 2026-10-14 (session 21)"). Find it by its timestamp (neutral text above the
  Decisions log moves line numbers, and only the Decisions sections are hashed). `bash scripts/spec-gate.sh waiver
  <spec-dir> opponent 19` exited 0 and round 20 is refused at exit 4 at the freeze point
  (`notes/verification/reports/r19-freeze.txt`).
- Reservation (copy exactly into the report): **Round** 19 · **Source** @@SOURCE@@ · **Floor** @@FLOOR@@ ·
  **reserved** @@RESERVED@@. Read them yourself from `notes/verification/rounds/opponent/ROUND-19/meta.nul`.

## Scope: what changed since round 18

Derived mechanically (`notes/verification/reports/r19-scope.sh`; `r19-scope.log`): round 18's FLOOR-OgYGoP
`inputs.nul` against @@FLOOR@@'s.

- Three accepted repairs, NOT yet gated independently, answering round 18 (`notes/verification/reports/opponent-round18.md`),
  under the user's decision of 2026-10-14 (O-018: narrow further, your M1; O-025: refuse tables, your M2; O-023:
  settle on either test, your M3). The kernel change is round 18's own MALL mutant (M1, M2 and M3 together), taken
  from its transcript, with its helper names given kernel names (`vf_m1_odd` is `vf_cm_open_tick`, `vf_m1_url` is
  `vf_cm_url`, `vf_m2_delim` is `vf_para_delim`), plus the rows the task blocks name:
  - **T030o54** (round-18 O-018, reopened, blocking): inside a finding, in both readers of finding records (the
    manifest pass, and the canonical pass of a canonical round before its completion marker), a line is refused by
    name when, outside every code span in some reading, it carries a bracket pair closed on its line whose label
    holds a backtick run the label does not close (`a backtick inside a link destination, title or label`), or a
    URL literal after `http://`, `https://` or `ftp://` (the scheme ending the text before it) or after `www.`, whose
    text up to whitespace or `<` holds a backtick (`an autolink outside a code span`).
  - **T030o55** (round-18 O-025, new, blocking): inside a finding, in both readers, a line whose text, spaces and
    tabs removed, holds a pipe and is a run of hyphen cells with optional colons separated by pipes is refused by
    name (`a table delimiter row`).
  - **T030o56** (round-18 O-023, reopened, minor): a candidate is settled when its lead is settled and either its
    head's brackets balance (T030o53's rule) or its whole text's brackets balance with complete destinations
    (T030o50's rule), each argued sound alone.
  Task blocks in `tasks.md` (search `**T030o54**`, `**T030o55**`, `**T030o56**`). Changed:
  `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`,
  `tests/test-spec-gate.sh`, 003's `spec.md` and `tasks.md`, and the Decisions log. The whole delta is
  `notes/verification/reports/r19-session.diff` (applied by `r19-edits/apply-code.py`, `apply-docs.py` and
  `decisions-1.py`, through `r19-batch-apply.sh`). No focused review ran on this delta: round 19 is its independent
  gate.
- **A spec revision of REQ-011, the user's decision of 2026-10-14, which you may challenge.** Gate reports are
  trusted-author input, written by the kit's own gate agents and read by people as well as by the tally, so a
  rendering divergence in a report (markdown a renderer shows differently from how the documented report grammar
  reads it, which that grammar neither reads nor refuses) is degraded, hence minor, and is recorded for a follow-up
  spec; a report written in the documented grammar that the gate misreads still blocks as wrong-result. It applies
  from round 19 on and re-grades no sealed round (`spec.md` REQ-011, the contract template, and the Decisions entry
  "Spec revision of REQ-011"). The user made it to finish the spec; the Decisions entry states its cost plainly.

Consumers of the changed files and every surface the spec declares are in scope too, and you may expand into
unchanged code.

## Evidence for the repair (claims, not authority)

- The decisions, in Decisions order from the entry "Opponent round 18 is recorded here now that this batch moves
  the source anyway" to the end: round 18's outcome, the user's decision of 2026-10-14, the reproduction, the spec
  revision, the task blocks with the dev run, the round-19 waiver, and the freezing entry.
- Reproduction before repair: `r19-repro.{sh,log,rc,time}` (exit 0, 196 PASS; CUR and PRE, `LANG=C` and
  `en_US.UTF-8`, both passes, direct and end to end).
- Under the user's decision of 2026-10-14 the invoker's extra proof steps were NOT run for this repair: no mutation
  matrix, no two-direction fixture judging, no separate measurement script, no repeated dev runs. The new rows'
  power to kill their bugs is therefore unproven by the invoker; isolate them yourself if you doubt them.
- The one dev run, in a standalone copy built from the live enumeration with both apply scripts applied and a
  `TMPDIR` ending in `/`: `r19-dev.{sh,log,rc,time}` (exit 0; its last line gives the suites and ShellCheck).
- The batch, validated on a scratch copy and then live, every written file byte-identical to the validated copy:
  `r19-batch-apply.sh` with `r19-batch-{scratch,live}.{log,rc}`.
- Acceptance: the freeze point `r19-freeze.txt` (source `1f0774dd…`, Decisions `2b58bbe7…`), the capture of record
  `r19-capture.{log,rc,start,end}` (CAP-656-JZJTKB, exit 0, 147/147 over 15 suites plus ShellCheck, input the frozen
  source), the returns `notes/verification/returns/T030o5{4,5,6}.txt` (`r19-return-T030o5{4,5,6}.{log,rc}`, exit 0
  each), `T030o54-accept.*`, `T030o55-accept.*`, `T030o56-accept.*` (exit 0 each; returns `b8aec2da…`, `33a257ab…`,
  `606eee62…`) and `r19-postaccept.txt`.
- The floor: @@FLOORRUN@@
- No hosted CI has run on the reviewed source.

## Known open — recorded, you may challenge it

- The REQ-011 revision above, and its extent: it grades rendering divergences in reports, not misreadings of the
  documented grammar.
- From the T030o54 to T030o56 task blocks: inside a finding a backtick inside a bracket pair closed on its line, or
  inside a URL literal, outside every code span, is refused; a table is refused inside a finding; `www.` in prose
  and URL literals before a code span parse.
- From the T030o51 to T030o53 rule entry: inside a finding a comparison written `c <= d` or `<30` is refused (a
  report writes it as code, or with a space after the `<`); a code example inside a finding is a fence at the start
  of a line, and one indented under a list item or opened after a list marker is refused; a link whose destination
  or title wraps, or a reference label that wraps, is refused; link definitions stay outside every finding; a
  section heading carrying raw HTML that closes a finding is outside it and parses. Recorded extent: the shared
  quoting tracker's divergences for its other consumers (unchanged); text a renderer hides by CSS or an attribute;
  a finding written in prose only (O-004); a code span inside a word; a link definition outside every finding whose
  title spans into a later finding's lines; outside the narrowed grammar the readings stay approximations, refusing
  wherever one of them sees a label.
- Round 18's matrix (v6) argued equivalents, each argued beside its row in `r18-mutations.sh`; no matrix ran for
  round 18's repair.
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
- Carried from round 18's brief: T030o43 review 3's R3-F7 and R3-F10, review 4's R4-F3, R4-F5, R4-F6 and R4-F8; the
  harness-level bash startup environment and option variables; `TZ`; `PATH` choosing an undeclared tool; shipped
  002's locale-dependent reset parsing; T030o42 review F2; T030o41 review 7's F1, F2, F4 and the unjudged K74 site;
  the kernel's ambient fixture reads; the analyzer field grammar with AC-023's narrowed reading; umbrella-only
  readers; the opponent-only totals, verdict and downgrade guards; README's missing Verification-Return grammar and
  completion marker; 001's legacy report failing `tally` at exit 3; the retained unexamined surfaces.
- The retro (T034) is deferred to a post-merge follow-up by the user's decision of 2026-10-14.

## Method this spec requires

1. Derive each criterion from the grammar or production the code reads, with its source. An enumeration of
   reported spellings is satisfiable while the class stays open.
2. Test a proposed rule against the real recorded history (`notes/opponent.md`, and 001's and 002's reports)
   before proposing it.
3. Mutation-isolate guards in both directions, and restore byte-identically (`cmp`).
4. Assert exact diagnostics, never exit codes alone.
5. Hunt for shipped POSITIVES that assert an attack at rc=0.
6. Grade under the spec as revised: a rendering divergence in a report is minor; a misreading of the documented
   grammar, and any defect outside report rendering, keeps its tier.

## Operational rules

- Work in a copy outside the worktree (for example `/private/tmp/opp19/work`, with `TMPDIR` inside it, ending in
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
- Write the report to `notes/verification/reports/opponent-round19.md` (exempt from the source identity), AND
  return it verbatim as your final message. If your file tool refuses the path, return the block alone; the invoker
  persists it and checks it byte-identical.

## Report grammar the gate will parse

The returned file is the round-19 block ALONE. `--complete` appends it to `notes/opponent.md`, validates it with
`vf_reports`, re-validates the floor to the reserved source, and re-verifies rounds 1-18 against their sealed
digests.

```
## Round 19

**Round:** 19
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
<!-- gate-round-end: opponent:19 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:19 -->`, and nothing non-blank may follow it. These
are the constraints `vf_reports` enforces on the code under review, stated so that a correct report of either
verdict can be canonized. The verdict itself is yours alone.

- The identity lines (Round, Timestamp, Source, Floor, Verdict, totals) come right after `## Round 19`, before any
  other line: a Timestamp line after the round's body is refused. Give the round no `# Opponent review` title line.
- `Blocking`/`Minor` must equal the counted findings. CLEARED requires zero blocking, and CHALLENGED requires at
  least one.
- A CLEARED report may not carry a known ID at a tier below its strictest recorded tier, nor a `resolved` finding
  that an earlier round of this gate counted open. O-018 (reopened) and O-025 were counted open in round 18 at
  wrong-result, and O-023 at degraded, a minor tier. So under CLEARED they may not appear as `### Finding` blocks,
  and your assessment of their repair belongs in the two prose sections. The REQ-011 revision does not change this
  guard: under CLEARED, a finding the revision grades minor can be carried only under an ID the gate has not
  recorded at a blocking tier, or described in the prose sections.
- A CHALLENGED report may re-list findings with any status, at their true tier.
- Field values are read after their own label only: write one bold label per field line, and give a Class, Severity
  or Status line nothing below it in its list item (no continuation line, second paragraph or sub-bullet).
- Under T030o48: inside a finding (from its `### Finding` heading to the next heading as shallow), write no `<`
  followed by a letter, `/`, `!` or `?` outside a code span: no tag, br, comment or processing instruction, not even
  in a fenced block, a block quote or a code span that spans lines. Write no form feed or vertical tab, and no
  carriage return except as a line ending.
- Under T030o51: inside a finding, write no `<` followed by a digit or by one of `.#$%&'*+=^_{|}~-` or a backtick
  outside a code span (write `a < b` with a space, or quote it as code); give no inline link destination or title,
  and no full reference link label, a backtick, and never let one wrap onto the next line; quote such markup in a
  single-line code span, or describe it in words. A heading inside a finding (a deeper heading, or the Finding
  heading itself) is judged too: carry no raw HTML on it.
- Under T030o52: inside a finding, open a code fence only at the very start of a line (no indentation, no list
  marker before it), and write no link reference definition (no line whose text begins with a bracket closed by
  `]:`, after a list or block-quote marker included).
- NEW under T030o54: inside a finding, put no backtick inside a bracket pair (`[...]`, a link's text or a
  reference label) outside a code span, and none inside a URL written after `http://`, `https://`, `ftp://` or
  `www.`; quote such a URL or bracket whole inside a single-line code span, or describe it in words.
- NEW under T030o55: inside a finding, write no table (no line made only of hyphen cells, optional colons and
  pipes). Outside every finding (What I attacked, Held up) all of these parse as before.
- Inside a finding, start no line, and no run of non-blank lines, with text that reads as the word Class or Severity
  unless it is that field's line: every line of a run is read with the lines after it. Quote no Finding heading or
  field line in a fence, block quote or HTML comment anywhere in the round: quote examples inline, in a code span
  after another word (`the line \`#### Severity: data-loss\``). Outside every finding a fenced example of a field
  line is fine, but not of a Finding heading.
