# Opponent round 21 — reviewer brief

Written @@WRITTEN@@ by the invoker (session 24). Everything here is a claim to attack, not authority. The receipts
named below outrank this text. Paths are relative to the spec directory
`.specify/specs/003-gate-round-reduction-and-token-discipline/` unless they start with `scripts/`, `tests/`,
`templates/`, `agents/`, `README.md`, `.specify/stack.yml` or `.github/` (worktree root:
`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 21 is AUTHORIZED by the Decisions line `@@WAIVERTS@@ — waiver: gate=opponent; round=21; after=20;
  by=Rehan712; …`, written under the user's decision of 2026-10-16 after round 20 (the Decisions entry "User
  decision of 2026-10-16 (session 23), after round 20"). Find it by its timestamp (neutral text above the Decisions
  log moves line numbers, and only the Decisions sections are hashed). `bash scripts/spec-gate.sh waiver <spec-dir>
  opponent 21` exited 0 and round 22 is refused at exit 4 at the freeze point
  (`notes/verification/reports/r21-freeze.txt`).
- Reservation (copy exactly into the report): **Round** 21 · **Source** @@SOURCE@@ · **Floor** @@FLOOR@@ ·
  **reserved** @@RESERVED@@. Read them yourself from `notes/verification/rounds/opponent/ROUND-21/meta.nul`.

## Scope: what changed since round 20

Derived mechanically (`notes/verification/reports/r21-scope.sh`; `r21-scope.log`): round 20's FLOOR-UeGEcf
`inputs.nul` against @@FLOOR@@'s.

- Round 20 CHALLENGED (`notes/verification/reports/opponent-round20.md`): O-029 blocking; O-030 and O-031 minor;
  O-032 degraded. By the user's decisions of 2026-10-15 and 2026-10-16, all 003 work was then committed (`2049f65`)
  and pushed, and draft PR #20 opened with `spec-pr.sh --force --draft`; reality-check round 3 was skipped. The user
  chose to repair O-029 test-only on the PR branch, with O-030 and O-031, and authorized this round for it. Three
  accepted test tasks, NOT yet gated independently, each starting from round 20's report and its reproduction
  (`r20-repro-o029.sh`):
  - **T031a4o1** (O-029; AC-009, REQ-012), `tests/test-spec-gate.sh` `round_legacy_reconcile_cases`, called by
    `test_rounds`: on the copy of shipped 002's date-only history, before the valid reconcile, a record naming a
    wrong digest, a wrong round or a timestamp before the history's date each exits 3, writes no `legacy-time.nul`
    and leaves the next round refused with the date-only diagnostic (each wrong record then removed if a regression
    wrote it, so each is judged alone); after it, a waiver dated 2026-07-20T12:00:00Z is refused with `not after the
    previous round completion at 2026-07-20T23:59:59Z` and the current waiver is authorized; after an edit of the
    history, with a floor current for the edited history, neither `waiver` nor `round` authorizes or reserves; with
    the history restored and a fresh floor, round 6 reserves.
  - **T031a1o1** (O-030; AC-022), `acceptance_named_cases`, called by `test_acceptance`: before the explicit-none
    acceptance, a return for the no-row task T006 with an empty `Failure modes:` header is refused with `empty
    required set must explicitly be none`, tasks.md byte-identical.
  - **T031a3o1** (O-031; AC-010), `tests/test-gate-contracts.sh`: a new `records_digest` helper hashes the name and
    bytes of every file under a directory; `shipped_002_tally_case` and `tally_class_cases` hash each directory
    `tally` reads (the 002 copy, the synthetic history, the annotated history) before and after the run; the copy
    check is relabelled as proving only that `copy_kit` is faithful.
  Task blocks in `tasks.md` (search `**T031a1o1**`, `**T031a3o1**`, `**T031a4o1**`). Changed:
  `tests/test-spec-gate.sh`, `tests/test-gate-contracts.sh`, 003's `tasks.md`, STATUS.md (the Decisions log, and
  the `pr:` frontmatter line `spec-pr.sh` wrote), with any other path the scope log lists. No kernel, template,
  agent or documentation file changed. The whole test and tasks delta is
  `notes/verification/reports/r21-session.diff` (applied by `r21-edits/apply-code.py`, `apply-docs.py` and
  `decisions-1.py`, through `r21-batch-apply.sh`). No focused review ran on this delta: round 21 is its independent
  gate.

Consumers of the changed files and every surface the spec declares are in scope too, and you may expand into
unchanged code. Whether the new assertions can fail when the behavior they name breaks, and whether round 20's
O-029 to O-031 are closed class-wide, is the central question; a fixture that cannot fail, or passes for the wrong
reason, is a finding.

## Evidence for the change (claims, not authority)

- The decisions, in Decisions order from the entry "Opponent round 20 is recorded here now that this batch moves the
  source anyway" to the end: round 20's outcome and the reproduction, the user's instruction of 2026-10-15, the
  user's decision of 2026-10-16 with the commit and the draft PR, the task blocks with the dev run, the round-21
  waiver, and the freezing entry.
- Under the user's decisions of 2026-10-14 to 2026-10-16 the invoker's extra proof steps were NOT run (no mutation
  matrix, no two-direction fixture judging, no separate measurement script, no repeated dev runs), with one
  exception: in the one dev run each new O-029 assertion was shown killed by at least one of round 20's three
  mutants (`r21-edits/mutants-o029.py`: the reconciled timestamp ignored; the reconcile digest and round check
  removed; all legacy binding removed), the kernel restored by `cmp` after each. O-030's and O-031's new assertions
  were not mutation-checked by the invoker.
- The one dev run, in a standalone copy built from the live enumeration with both apply scripts applied and a
  `TMPDIR` ending in `/`: `r21-dev.{sh,log,rc,time}` (exit 0; its last line gives the suites, ShellCheck and the
  O-029 kill count; the per-assertion kill lines precede it).
- The batch, validated on a scratch copy and then live, every written file byte-identical to the validated copy:
  `r21-batch-apply.sh` with `r21-batch-{scratch,live}.{log,rc}`.
- Acceptance: the freeze point `r21-freeze.txt`, the capture of record `r21-capture.{log,rc,start,end}`, the
  returns `notes/verification/returns/T031a{1,3,4}o1.txt` (`r21-return-T031a{1,3,4}o1.{log,rc}`),
  `T031a{1,3,4}o1-accept.{log,rc}` and `r21-postaccept.txt`.
- The floor: @@FLOORRUN@@
- Hosted CI: none has run on the reviewed source (the user's GitHub Actions limit; Decisions). The last hosted run
  was on round 19's source (`notes/verification/platforms/ci-20261015-summary.txt`), historical here.

## Known open — recorded, you may challenge it

- Round 20's O-032 (degraded, class round-recovery-diagnostics): the legacy-record refusals in
  `vf_round_history` and `round --reconcile` exit 3 with no diagnostic. It needs a kernel change, which is not
  authorized; it goes to the follow-up spec. The O-029 cases therefore assert exit codes and state, not a
  diagnostic, for those refusals.
- Round 19's three minor findings, recorded and NOT repaired (no task authorized; for the follow-up spec REQ-011
  names): O-026 (a tilde before a backtick run), O-027 (a wrapped shortcut, collapsed or image reference label
  holding a backtick), O-028 (markdown-it 12.3.2's label-scan backtick skip; the spec names no reference renderer),
  with its proposed follow-ups F1 to F4 (`notes/verification/reports/opponent-round19.md`).
- Recorded by reality-check round 2 as outside its five gaps: two assertions that can never fail
  (`tests/test-spec-gate.sh` test_floor's `model-called` file nothing creates, and a next-stage marker nothing
  chains) and the untested plan-level warnings in `scripts/verification-lib.sh` (about lines 1323-1326).
- The REQ-011 revision of 2026-10-14 (`spec.md` REQ-011, the Decisions entry "Spec revision of REQ-011"), and its
  extent: it grades rendering divergences in reports, not misreadings of the documented grammar.
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

- Work in a copy outside the worktree (for example `/private/tmp/opp21/work`, with `TMPDIR` inside it, ending in
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
- Write the report to `notes/verification/reports/opponent-round21.md` (exempt from the source identity), AND
  return it verbatim as your final message. If your file tool refuses the path, return the block alone; the invoker
  persists it and checks it byte-identical.

## Report grammar the gate will parse

The returned file is the round-21 block ALONE. `--complete` appends it to `notes/opponent.md`, validates it with
`vf_reports`, re-validates the floor to the reserved source, and re-verifies rounds 1-20 against their sealed
digests.

```
## Round 21

**Round:** 21
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
<!-- gate-round-end: opponent:21 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:21 -->`, and nothing non-blank may follow it. These
are the constraints `vf_reports` enforces on the code under review, stated so that a correct report of either
verdict can be canonized. The verdict itself is yours alone.

- The identity lines (Round, Timestamp, Source, Floor, Verdict, totals) come right after `## Round 21`, before any
  other line: a Timestamp line after the round's body is refused. Give the round no `# Opponent review` title line.
- `Blocking`/`Minor` must equal the counted findings. CLEARED requires zero blocking, and CHALLENGED requires at
  least one.
- A CLEARED report may not carry a known ID at a tier below its strictest recorded tier, nor a `resolved` finding
  that an earlier round of this gate counted open. O-018 (reopened) and O-025 were counted open in round 18 at
  wrong-result, and O-023 at degraded, a minor tier; round 19 CLEARED with none of them as a finding. O-026, O-027
  and O-028 were counted open in round 19 at minor. O-029 was counted open in round 20 at wrong-result, a blocking
  tier, and O-030 and O-031 at minor, O-032 at degraded, both minor tiers. So under CLEARED, O-018, O-025, O-023 and
  O-029 may not appear as `### Finding` blocks, and O-026 to O-028 and O-030 to O-032 may appear only at a minor
  tier and not as `resolved`; your assessment of them belongs in the two prose sections otherwise. A new finding
  takes a new ID (O-033 onward).
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
- Under T030o54: inside a finding, put no backtick inside a bracket pair (`[...]`, a link's text or a
  reference label) outside a code span, and none inside a URL written after `http://`, `https://`, `ftp://` or
  `www.`; quote such a URL or bracket whole inside a single-line code span, or describe it in words.
- Under T030o55: inside a finding, write no table (no line made only of hyphen cells, optional colons and
  pipes). Outside every finding (What I attacked, Held up) all of these parse as before.
- Inside a finding, start no line, and no run of non-blank lines, with text that reads as the word Class or Severity
  unless it is that field's line: every line of a run is read with the lines after it. Quote no Finding heading or
  field line in a fence, block quote or HTML comment anywhere in the round: quote examples inline, in a code span
  after another word (`the line \`#### Severity: data-loss\``). Outside every finding a fenced example of a field
  line is fine, but not of a Finding heading.
