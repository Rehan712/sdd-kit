## Round 19

**Round:** 19
**Timestamp:** 2026-10-15T08:06:13Z
**Source:** 1f0774ddf738539f83236db08fa7f8847c3e9a276964fc5582730ed6bd5c8a66
**Floor:** FLOOR-GCDl2x
**Verdict:** CLEARED
**Blocking:** 0 · **Minor:** 3

### What I attacked

I worked only in a copy under `/private/tmp/opp19/work`, with `TMPDIR` ending in `/`. CUR is the frozen tree: its four repair files hash as `r19-edits/post-apply.sha256`. PRE is CUR with the kernel hunk of `r19-session.diff` reversed; its kernel hashes as `r18-edits/post-apply-3.sha256` (`62a17f93…`), round 18's tree. In the worktree I created nothing except this report, ran no floor, round, checkpoint, capture, accept, suite or test function there, and sourced nothing from its `tests/`. The only containers I ran were throwaway ones of `oven/bun:1` and `zricethezav/gitleaks:v8.24.3`, with `--rm`, `--network none` and my copy mounted read-only.

- **Scope.** The three repairs in both readers of finding records: the manifest pass (`scripts/verification-lib.sh:1733`) and the canonical pass (`:1964`).
  - **T030o54.** `vf_cm_open_tick`, `vf_cm_url`, and the new bracket, colon and `w` arms of `vf_cm_scan` (`:514-540`).
  - **T030o55.** `vf_para_delim` (`:683-686`) and its arm in `vf_para` (`:707`).
  - **T030o56.** `vf_settled_word` (`:584-586`).
  - **Also.** The contract text (`templates/verification-contract.md:383-406`), the new rows in both suites, the REQ-011 revision, and the consumers of `vf_cm_scan` (`vf_para` and `vf_settled`).
- **Derivation.** I worked from the sources the reference renderers ship, not from round 18's spellings.
  - **marked 17.0.5.** I read its inline lexer order (escape, tag, link, reflink, emStrong, codespan, br, del, autolink, url, text) and its GFM text rule.
  - **markdown-it 12.3.2.** I read `lib/helpers/parse_link_label.js` and `lib/rules_inline/backticks.js`.
  - **Tables.** I checked the delimiter-row grammar of both renderers.
- **Runs.** I ran every member directly through `vf_reports` in both passes, under `LANG=C` and `LANG=en_US.UTF-8` with every `LC_*` removed, on CUR and on PRE.
  - **End to end.** I ran `spec-gate.sh floor`, `round`, `round --complete` and `tally` with the suite's own `make_verification_git_dir`, `floor_fixture` and `record_line_report`, in a file of my own inside my copy.
  - **Rendering.** I rendered with the marked and markdown-it binaries that `r19-repro.sh` names.
- **Portability.** The shipped round-18 rows (the seven O-018 members and the table) and the shipped positives give the same exit codes and diagnostics under four awks:
  - macOS awk 20200816 and gawk 5.4.0, each in both locales;
  - mawk 1.3.4, in the `oven/bun:1` container;
  - BusyBox 1.36.1 awk, in the gitleaks container.
- **History.** These outputs are byte-identical between CUR and PRE under both locales: catalogs, stderr and exit codes for 001's, 002's and 003's opponent and reality-check reports, with 003's manifest (001's opponent report stays at exit 3). So are the outputs for all 41 report files carrying a Finding heading, each read as a prior-review manifest.
- **Differential fuzz of the settled rule.** I compared CUR against a mutant whose `vf_settled` never settles, over 84,000 generated runs. Of those, 60,000 were led by a bracket construct before the first word, which is the shape T030o56 newly settles.
- **Differential fuzz of the narrowed grammar.** I generated 220,000 finding bodies of one or two lines, each carrying a br tag followed by a data-loss tier. 1,334 of them pass the gate, and 57 of those show the tier after a live br in a renderer: 53 in marked and 4 in markdown-it. Every one of the 57 is a member of O-026 or O-028.
- **Mutants.** I disabled each new guard in turn and ran the shipped rows against it. Results are under Held up.
- **Suites.** In my copy, `tests/test-gate-contracts.sh` passes 18/18 at exit 0 and `tests/test-spec-gate.sh` passes 8/8 at exit 0.

### Finding O-026
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** Inside a finding, below a minor tier, a line puts a tilde directly before a backtick run that CommonMark pairs into a code span holding a br tag, written `` It took ~`<br>Severity: data-loss` here. ``.
  - **The gate's reading.** It places code spans by CommonMark 6.1, so the tag reads as inside a span. `vf_narrow` stays empty, and `vf_label_inert` makes the tag inert for the break reading.
  - **marked's reading.** The GFM text rule, written `` ^([`~]+|[^`~]) ``, takes a run of tildes and backticks as one piece of text once strikethrough fails at the tilde. The backtick never reaches the codespan rule, so the tag is live and the tier is the first text of the rendered line.
  - **The other renderer.** markdown-it renders a code span.
  - **Reach.** No definition is needed, and the member fits on one line. A tilde used for "about" before a code span is ordinary prose.
- **Where:** scripts/verification-lib.sh:529, scripts/verification-lib.sh:550, scripts/verification-lib.sh:556, scripts/verification-lib.sh:698, scripts/verification-lib.sh:1733, scripts/verification-lib.sh:1964, templates/verification-contract.md:369, templates/verification-contract.md:390
- **Reproduced:** Every case ran in my copy, and the control was checked by its exact diagnostic.
  - **Direct runs.** On CUR and PRE, `vf_reports` exits 0 with empty stderr in both passes and both locales. The catalog records G-050, or the manifest's G-042, at minor.
  - **Control.** `Note <br>Severity: data-loss.` is refused with `raw HTML outside a code span in finding G-050`.
  - **End to end.** The member seals a CLEARED round 1 in both locales as a canonical new G-050, and under `LANG=C` as a manifest G-042 re-recorded at minor. Each completion prints `round completed gate=opponent round=1 verdict=CLEARED`, and `tally` reports `blocking=0 minor=1`.
  - **Fuzz.** All 53 marked-only cases of the fuzz are this mechanism.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** A data-loss tier visible on marked is prose to both readers, and a CLEARED round seals over it at minor. T030o54's acceptance names the URL literal and the bracket pair as the constructs marked binds before any code span, but marked's text rule binds a third. Under REQ-011 as revised, this is a rendering divergence that the documented grammar neither reads nor refuses (it reads a code span), so it is minor.
- **Class-wide fix:** For the follow-up spec, inside a finding refuse a backtick run that directly follows a tilde outside every code span. More generally, derive code-span placement from each reference renderer's lexer, not from CommonMark alone. Add rows in both passes.

### Finding O-027
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** Inside a finding, below a minor tier, a shortcut reference label holds a backtick and wraps onto the next line. A definition of that label stands outside every finding.
  - **The member.** The first line is ``` Note [a``b ```, the second is ``` c`]<br>Severity: data-loss `` ` . ```, and the definition outside the finding is ``` [a``b c`]: https://x.example/ ```.
  - **The gate's reading.** T030o54 judges only a bracket pair closed on its line, so the open label goes unchecked. Both readings of the second line put the tag inside a code span:
    - in the reading where the first line's span is still open, the double-backtick run closes that span after the tag;
    - in the fresh reading, the label's own backtick opens a span that the final backtick closes.
  - **marked's reading.** Its label grammar allows a line ending and a backtick, so it binds the reference across the lines. The label's backticks open nothing, and marked renders the link, then the live tag, then the tier.
  - **markdown-it's reading.** markdown-it 12.3.2 shows the tag live even without the definition, through O-028's mechanism.
- **Where:** scripts/verification-lib.sh:537, scripts/verification-lib.sh:509, scripts/verification-lib.sh:529, scripts/verification-lib.sh:698, scripts/verification-lib.sh:1733, scripts/verification-lib.sh:1964, templates/verification-contract.md:386
- **Reproduced:** Every case ran in my copy.
  - **Direct runs.** On CUR and PRE, `vf_reports` exits 0 with empty stderr in both passes and both locales. The catalog records G-050, or the manifest's G-042, at minor.
  - **End to end.** The member seals a CLEARED round 1 in both locales as a canonical new G-050, and under `LANG=C` as a manifest G-042 re-recorded at minor. `tally` reports `blocking=0 minor=1`.
  - **Rendering.** I rendered the whole canonical report with the definition added. Both renderers show the minor field line, and then the data-loss tier right after a live tag.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** A data-loss tier visible on both renderers is prose to both readers, and a CLEARED round seals over it at minor. This is the O-018 mechanism with the label wrapped, which T030o54 left out by design. It is a rendering divergence outside the documented narrowing, so it is minor under REQ-011 as revised.
- **Class-wide fix:** Inside a finding, refuse a shortcut, collapsed or image reference label that holds a backtick and does not end on its line, as the arm at `:544` already does for a full reference's label. Add rows in both passes.

### Finding O-028
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** Inside a finding, below a minor tier, one line carries a bracket that closes on no later character of the line, then a double-backtick pair holding a br tag, then a lone backtick: ``` Note [a``b c`<br>Severity: data-loss `` ` . ```.
  - **markdown-it's reading.** In markdown-it 12.3.2, the link-label scan calls `skipToken`, which skips the backtick pair silently without caching its closer (`parse_link_label.js:28`, `backticks.js:54`). The lone backtick then marks the line as scanned (`backticks.js:58`). When the main pass reaches the pair, it reads the pair as literal text (`backticks.js:23`), so the tag is live and the tier starts a rendered line.
  - **The other readings.** CommonMark, marked and the gate all read a code span.
  - **Reach.** No definition is needed, and the member fits on one line.
- **Where:** scripts/verification-lib.sh:537, scripts/verification-lib.sh:550, scripts/verification-lib.sh:698, scripts/verification-lib.sh:1733, scripts/verification-lib.sh:1964, templates/verification-contract.md:369
- **Reproduced:** Every case ran in my copy.
  - **Direct runs.** On CUR and PRE, `vf_reports` exits 0 with empty stderr in both passes and both locales.
  - **End to end.** The member seals a CLEARED round 1 in both locales as a canonical new G-050, and under `LANG=C` as a manifest G-042 re-recorded at minor. `tally` reports `blocking=0 minor=1`.
  - **Rendering.** markdown-it shows the tier after a live tag, and marked shows a code span.
  - **Fuzz.** The four markdown-it-only cases of the fuzz are all this mechanism, each with a bracket left open before a backtick pair.
- **Root cause:** spec-gap
- **Blocks:** none
- **Wrong behavior:** A data-loss tier visible on one reference renderer is prose to both readers, and a CLEARED round seals over it at minor. The cause is a renderer bug, but the spec names no renderer the grammar must agree with. It is minor under REQ-011 as revised.
- **Class-wide fix:** In the follow-up spec, name the renderers a report must agree with, or refuse inside a finding a bracket left open on its line that precedes a backtick run. Add rows in both passes.

### Held up / follow-up tasks

**Held up:**
- **O-018's repair (T030o54) on one line.** It holds. All seven round-18 members are refused by name in both passes and both locales, on all four awks. So are the following variants:
  - an upper-case scheme, an upper-case `WWW.`, and a scheme directly after a letter;
  - a label holding an escaped bracket;
  - a label nested in another bracket pair.
  - **marked's single-line binds.** The URL rule's text runs up to whitespace or an angle bracket, and the gate's scan stops only at a space, a tab or an angle bracket, so the gate scans at least as far. The label grammar admits no unescaped bracket, which `vf_cm_label` mirrors.
  - **The class.** It stays open for wrapped labels (O-027) and for constructs outside the enumeration (O-026, O-028), all minor under the revision.
- **O-025's repair (T030o55).** It holds.
  - **Refused.** Delimiter rows with alignment colons, in a list item, behind block-quote markers, and without outer pipes are all refused by name.
  - **Why the strip is safe.** markdown-it 12.3.2 accepts only pipes, hyphens, colons, spaces and tabs on a delimiter line, and marked only spaces as padding. Both are subsets of what `vf_para_delim` strips.
  - **Single-column tables.** marked accepts one with a colon and no pipe, but each of its cells is a whole line, which the line reader reads.
  - **Recorded, not graded.** A Markdown table quoted inside a fenced code example within a finding is now refused, where PRE parsed it. That matches the contract's rule that tables stay outside every finding.
- **O-023's repair (T030o56).** It holds.
  - **Timing.** The round-18 shape takes 0.35 s at 400 lines and 0.70 s at 800 on CUR, against 2.8 s at 50 and 28.4 s at 100 on PRE.
  - **Soundness.** Each half of the union was argued sound in rounds 17 and 18. The 84,000-run fuzz found no line where the never-settling mutant reads a label that the passes miss on CUR.
  - **No regression.** A 400-line run kept unsettled by a lone backtick takes 29.0 s on CUR and 28.7 s on PRE, so the new scan arms cost nothing measurable.
- **Mutants.** Disabling each of these guards turns its shipped rows to exit 0: the bracket arm (three reference rows), the colon arm (three URL rows), the `www.` arm (one row), the `ftp` alternative (one row) and the delimiter arm (the table row).
  - **One survivor.** Dropping `tolower` from the colon arm survives every shipped row. marked binds an upper-case scheme (`HTTP://`), so the guard is needed today but unpinned. Add one upper-case row.
- **The REQ-011 revision.** I do not challenge it. It sits inside REQ-011's own carve-out, and no AC, REQ, FM or INV row requires agreement with a renderer (I checked FM-016, FM-019, INV-004 and INV-006). I graded all three findings under it; without it, O-026 and O-027 would each block as wrong-result.
- **Positives.** No new positive row asserts an attack at exit 0. I rendered the nine new positive bodies and the timing row, and none shows a tier as a first word.
- **A documentation gap, not graded.** The report shape in `agents/opponent.agent.md` does not state the narrowed finding grammar, which lives only in the contract and in invoker briefs. A gate agent that follows the persona alone can write a table or a link inside a finding and be refused at completion by name. It fails closed.

**Follow-up tasks proposed** (for the follow-up spec that REQ-011 names):
- F1: Inside a finding, refuse a backtick run directly after a tilde outside every code span, or place code spans by marked's text rule in one more reading. Add rows in both passes (→ O-026).
- F2: Inside a finding, refuse a shortcut, collapsed or image reference label that holds a backtick and does not end on its line. Add rows in both passes (→ O-027).
- F3: Name the reference renderers in the spec, or refuse a bracket left open on its line before a backtick run. Add rows (→ O-028).
- F4: Add an upper-case scheme row for the URL-literal arm, and state the narrowed finding grammar in `agents/opponent.agent.md`.
<!-- gate-round-end: opponent:19 -->
