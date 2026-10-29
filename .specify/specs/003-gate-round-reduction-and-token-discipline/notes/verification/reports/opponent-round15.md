## Round 15

**Round:** 15
**Timestamp:** 2026-10-07T18:36:32Z
**Source:** c9f2b61691a4447d28f4baaf640c3f43ec993040fda9febaf8eba82134e5b21e
**Floor:** FLOOR-dCwGgb
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 0

### What I attacked

I worked only in copies under `/private/tmp/opp15`, never in the worktree. I attacked the two accepted repairs and the consumers they feed.

- **T030o45 (O-020).** I attacked the style switch in `vf_reports` (`scripts/verification-lib.sh:1665`, `:1697-1716`). The cases were a title before the identity fields with a late Timestamp, a title after the body of a canonical round, a title after a body made only of quoted lines, a late Timestamp in a canonical round, and a title after the Round line. I also checked every other assignment of `style` and every rule that runs before the `body` flag is set.
- **T030o46 (O-018, O-021).** I attacked the label reader's rendered readings (`:325-401`), the paragraph reader `vf_para` and `vf_para_label` (`:426-442`), and `vf_block_start` (`:418-424`), in both readers (the manifest pass at `:1437-1466` and the canonical pass at `:1663-1680` and `:1771-1775`).
  - I derived each candidate from CommonMark 0.31.2: where a paragraph starts and ends (4.1, 4.3, 4.4, 4.8, 5.1, 5.2, 5.3), code-span precedence (6.1), and hard line breaks (6.7). I rendered every candidate with markdown-it 12.3.2, a CommonMark renderer, and with marked 17.0.5.
  - I ran each candidate through both readers directly, then end to end through `round --complete` and `tally` in a fixture repository, under `LANG=C` and `LANG=en_US.UTF-8`.
- **Method.** I tested the proposed rule against the recorded history, isolated the guard with a mutation in both directions, and hunted the shipped positive rows.
  - **History.** The history set was 001's, 002's and 003's opponent and reality-check reports, the real `opponent-findings-2026-09-09.md` manifest, and the thirteen returned round reports read as manifests.
  - **Mutation.** I mutated a copy of the kernel and ran the two changed suites against it.
  - **Positive rows.** I checked every new `SHAPES` and `ROWS` positive in `tests/test-gate-contracts.sh` against both renderers.
- **Evidence re-run.** I ran the full suite in a git-initialized copy of the frozen tree with `TMPDIR` ending in `/`. It exited 0 at 147/147 over 15 suites, which reproduces the capture's count. I did not run ShellCheck.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-018
- **Severity:** wrong-result
- **Scenario:** A finding records a minor tier on its own tier line, and below it the report or manifest carries a second line that both renderers show as a data-loss tier. Both readers of finding records accept it, so a CLEARED round seals and `tally` counts the finding as minor. T030o46 joins a line to the paragraph before it unless `vf_block_start` reads it as a block start, and then reads only the first word of the joined text. A paragraph boundary placed differently from CommonMark therefore hides the label in both directions. A boundary the reader misses puts the previous paragraph's first word in front of the label. A boundary the reader invents cuts the construct off from its opening tag. Joining is not the deny side that the kernel comment at `:291` claims. Six members, each reproduced:
  - **Missed boundary, an ordered sibling item.** A tight list holds the item `1. a` and then the item `2. <b`, continued by `title="x">Severity: data-loss</b>`. CommonMark starts a sibling item at `2.`, because only a list's first item must be numbered 1 to interrupt a paragraph. The same happens with `01. <b` after a paragraph line, since its number is 1. `vf_block_start` accepts only the spellings `1.` and `1)`, so the item joins the paragraph above it, and the joined text's first word is `a`.
  - **Missed boundary, a setext underline.** The line `A remark` and then the line `===` form a level-1 heading, and the same two-line tag follows it. The reader takes the underline as continuation text.
  - **Missed boundary, a block quote.** The line `Note` is followed by `> <b` and then `> title="x">Severity: data-loss</b>`. `vf_para` strips the quote markers before it asks `vf_block_start`, so that function's own block-quote test never fires. The quoted tag therefore joins the paragraph `Note`.
  - **Invented boundary, an indented continuation line.** The line `<b title="a` is followed by a line indented four spaces, `- b">Severity: data-loss</b>`. A list item cannot start at four spaces of indentation, so CommonMark continues both the paragraph and the attribute value. `vf_para` strips all indentation before it tests, reads a list item, and starts a new paragraph whose first word is `b`.
  - **Code-span precedence.** The line ``[`]`](u)Severity: data-loss`` holds a link whose text is a code span containing a closing bracket. The renderers show it as the bracket followed by the data-loss tier. A code span binds tighter than link brackets (6.1), but `vf_label_links` takes the bracket inside the code span as the link's closer, and every reading then starts at `u`.
  - **A rendered line break.** `Note<br>Severity: data-loss` renders the tier at the start of its own line. Inside a field line, such as a Where value written as `a.sh:1<br><b>Severity:</b> data-loss`, it renders as a second bold tier line inside the same list item. `<p>` and the other block-level tags inside a line behave the same way. The readers take the tag out and read `Note`, or the field's own label.
  - **Why the repair missed these.** The repair's fixtures are each a paragraph that starts on a line `vf_block_start` already accepts. That is why the shipped rows pass.
- **Where:** scripts/verification-lib.sh:426, scripts/verification-lib.sh:427, scripts/verification-lib.sh:429, scripts/verification-lib.sh:434, scripts/verification-lib.sh:418, scripts/verification-lib.sh:291, scripts/verification-lib.sh:371, scripts/verification-lib.sh:325, scripts/verification-lib.sh:399, scripts/verification-lib.sh:1439, scripts/verification-lib.sh:1463, scripts/verification-lib.sh:1677, scripts/verification-lib.sh:1771, scripts/verification-lib.sh:1772, templates/verification-contract.md:369, templates/verification-contract.md:378
- **Reproduced:** Every case below ran in my copy of the frozen tree.
  - **Rendering.** markdown-it 12.3.2 and marked 17.0.5 render every member with `Severity: data-loss` as the first visible text of a list item, a paragraph, a block quote or a rendered line. For the `01.` spelling, markdown-it renders a separate list item and marked renders the same paragraph. In both renderings, the tier follows a hidden tag.
  - **Direct runs.** I put each member after a blank line below a canonical wrong-result tier line in a CHALLENGED round, and below a minor tier in a manifest finding G-042. `vf_reports` exits 0 with empty stderr in both passes for every member. The Where-field spelling exits 0 in the manifest pass.
    - **Controls.** The same tag with no preceding line, and the same tag after a line `Text` followed by `1. <b`, both exit 3. The canonical pass prints `a Severity line this grammar cannot read in finding O-001`, and the manifest pass prints `a second Severity line in finding G-042`.
  - **End to end.** I built the fixture with the suite's own `make_verification_git_dir`, `floor_fixture` and `record_line_report`, then ran `floor`, reserved `round`, and completed `round --complete` for a CLEARED round 1 that re-records the manifest finding G-042 at minor.
    - It sealed (`round completed gate=opponent round=1 verdict=CLEARED`) for the ordered item, the setext underline, the block quote, the indented line, the code span and the line break, under both `LANG=C` and `LANG=en_US.UTF-8`.
    - A CLEARED round whose new finding G-050 carries the minor line and the same member sealed in the same way.
    - `tally` then reports `blocking=0 minor=1` every time.
    - The control was refused at completion under both locales, with the diagnostics above.
  - **Mutation, closing direction.** I replaced `vf_para` and `vf_para_label` with a suffix reading.
    - Every line of a paragraph is a candidate start, and the label is read from the joined text that starts at each candidate whose own line carries no label. A paragraph ends only at a blank line, at a fenced line, or at an ATX heading.
    - With that change, both passes refuse the ordered item, the `01.` spelling, the setext underline, the block quote and the indented line. The controls stay refused.
    - I then added two readings to `vf_label`: one in which characters inside a matched code span are inert, and one that reads the text after each `br` tag and each block-level tag outside code spans. With those, the code-span and line-break prose members are refused too.
    - The Where-field spelling stays accepted by the canonical pass, because `:1771` never label-checks a line written in field spelling.
  - **Mutation, history direction.** Under both mutants, the 21 history runs produce byte-identical output and exit codes to the unmutated kernel: 19 exit 0, and the same two exit 3, which are 001's recorded `tally` failure and the reality-check report read as an opponent manifest.
    - **Changed suites.** With the paragraph mutant in a git-initialized copy, `tests/test-gate-contracts.sh` passes 18/18 and `tests/test-spec-gate.sh` passes 8/8, both exiting 0. A first draft that joined a line across an ATX heading failed the shipped positive `heading-then-attribute-line`, which is why the heading rule is part of the fix.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A visible blocking tier is read as prose by both readers, and a CLEARED round seals over it. This is O-018's wrong behavior, and the end-to-end runs reproduce it.
  - T030o46's acceptance requires the members to be derived "from what a renderer shows as the first word of a line or of a paragraph". The contract says the label is read "from each paragraph, a line joined with the lines that continue it".
  - Both claims fail wherever the reader's paragraph boundary differs from CommonMark's, because a single joined text read only at its first word is not an approximation that can only refuse.
  - Round 14's reported spellings, and the repair's own rows, stay closed.
- **Class-wide fix:** Make every boundary error fall on the refusing side, rather than trying to place boundaries exactly.
  - **Paragraphs.** In `vf_para`, take every line of a run of non-blank, unfenced lines as a candidate paragraph start, and end the run only at a blank line, a fenced line or an ATX heading of at most three spaces. In `vf_para_label`, read the label from the joined text that starts at each candidate whose own line carries no label. Measured as described above, this is history-neutral and refuses all five boundary members.
  - **Code spans.** In `vf_label`, add a reading in which characters inside a matched code span are inert. Code spans bind tighter than link brackets and raw HTML (6.1).
  - **Rendered line starts.** Read the label after each `br` tag and each condition-6 tag found outside code spans, and apply this to field-line values in the canonical pass as well. No recorded report or manifest contains such a tag, so this refuses nothing recorded.
  - **Comment and contract.** Correct the comment at `:288-292` and the contract at `:369` and `:378`.
  - **Fixtures.** Add one row per member in both passes, and one end-to-end case per mechanism.

### Finding O-020
- **Class:** gate-report-schema-validation
- **Status:** resolved
- **Prior:** O-020
- **Severity:** wrong-result
- **Scenario:** Round 14's style switch, and its derived siblings.
  - A report title before the identity fields, and the Timestamp after the body.
  - A title after the body of a canonical round.
  - A title after a body made only of quoted lines.
  - A late Timestamp in a round that is already canonical.
- **Where:** scripts/verification-lib.sh:1665, scripts/verification-lib.sh:1699, scripts/verification-lib.sh:1709, scripts/verification-lib.sh:1716
- **Reproduced:** I ran direct `vf_reports` in my copy.
  - A CLEARED round with a title under its heading, a data-loss finding and a Timestamp after Held up exits 3 with `a Timestamp line after the body of a round its title made legacy`, and the count refusals follow.
  - With the Timestamp early, or with a Round line before the late title, the round stays canonical, and its uncounted blocker is refused with `finding totals disagree`.
  - Every assignment of `style` is guarded by `body`, and every rule ahead of the body flag either sets it, refuses, or consumes only identity fields. The shipped `titleearly` positive reads as canonical.
  - The end-to-end row passed in my full-suite run.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** Nothing remains wrong for round 14's subject. A round's style is decided before its body, and a switch after it is refused by name.
- **Class-wide fix:** Closed for this subject. Keep the O-020 rows.

### Finding O-021
- **Class:** gate-report-schema-validation
- **Status:** resolved
- **Prior:** O-021
- **Severity:** minor
- **Scenario:** A tier line followed directly by a block that a renderer starts there: a `div` element, a `details` element, an uppercase `DIV` with an attribute, or a four-backtick `text` fence.
- **Where:** scripts/verification-lib.sh:418, scripts/verification-lib.sh:422, scripts/verification-lib.sh:423
- **Reproduced:** In a CHALLENGED canonical round, each of the four shapes exits 0.
  - The refusal twins, a `span` element (condition 7) and a three-backtick line whose info string holds a backtick, each exit 3 with `a Severity field whose list item holds more than its line in finding O-001`.
  - The tag list matches CommonMark 0.31.2's condition 6, including `search` and excluding `source`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Nothing remains wrong. The over-refusal is gone, and condition 7 still continues the item.
- **Class-wide fix:** Closed. Keep `value-details` positive, with its `span` twin.

### Held up / follow-up tasks

**Held up:**
- **T030o45.** The style is decided before the body in both gates. No sequence of title, identity fields and body that I could build switches style after the body without a named refusal. All recorded history parses unchanged.
- **T030o46's other rules.** These held under attack: the bracket fixpoint for nested links, linked images, empty links, reference links, angle-bracket and parenthesized destinations, and titles across lines; the intraword `*` removal; and both hiding readings for named, numeric and non-ASCII invisible characters.
- **No positive asserts an attack.** None of the new positive rows asserts an attack at exit 0. I checked `heading-then-attribute-line` and `fenced-tag-example` against both renderers. Neither shows a tier as the first word.

**Non-blocking note:** A code span inside a word, as in the spelling ``S`everity`: data-loss``, renders the word in two typefaces, and neither reader reads it. Whether a reader sees it as one word is the user's call, as it was for intraword emphasis, so I do not count it.

**Follow-up tasks proposed:**
- T030o47: Make the paragraph reading refuse on both sides of a boundary error. Use candidate starts at every line, a code-span-inert reading, and reading after `br` and block-level tags, including in field-line values in the canonical pass. Add both-pass rows and end-to-end cases for the six members (→ O-018).
<!-- gate-round-end: opponent:15 -->
