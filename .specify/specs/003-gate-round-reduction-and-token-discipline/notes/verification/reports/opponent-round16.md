## Round 16

**Round:** 16
**Timestamp:** 2026-10-08T12:22:39Z
**Source:** eee97354a5aa4069a44c3791db4b576486502299450a7d3a89739677ec949c12
**Floor:** FLOOR-UW5FIE
**Verdict:** CHALLENGED
**Blocking:** 2 · **Minor:** 1

### What I attacked

I worked only in copies under `/private/tmp/opp16`, built from the worktree's own enumeration and git-initialized, with `TMPDIR` ending in `/`. I created nothing in the worktree except this report.

- **Scope.** T030o47 (round 15's O-018): the run reader `vf_para` and `vf_para_label` (`scripts/verification-lib.sh:486-505`), the code-span reading `vf_label_inert` (`:421-437`), the rendered line start reading `vf_label_breaks` (`:438-452`), the reading order in `vf_label` (`:453-463`), and the canonical field-value check (`:1848`). I attacked them in both readers, the manifest pass and the canonical pass.
- **Derivation.** I derived the candidates from the productions the code claims to read, not from the reported spellings.
  - CommonMark 0.31.2: the line ending and the blank line (2.1), backslash escapes (2.4), ATX headings (4.2, no more than six marks), HTML blocks (4.6, conditions 1 and 6), code spans and their precedence after raw HTML and autolinks (6.1), and links (6.3).
  - The HTML Living Standard for what a browser shows as a new block: the tree builder closes an open p for `pre`, `listing`, `xmp`, `plaintext` and `hgroup`, and the rendering section gives each of them display block. I checked this with parse5 7.3.0.
- **Rendering.** I rendered every candidate with markdown-it 12.3.2 and marked 17.0.5, the same renderers as round 15.
- **Runs.** I ran each candidate after a blank line below a minor tier in both passes, under `LANG=C` and `LANG=en_US.UTF-8` with every `LC_*` removed. I ran it on CUR (the frozen tree) and on PRE (CUR with `r16-session.diff` reversed). For each mechanism I also ran it end to end through `spec-gate.sh round --complete` and `tally`, using the suite's own fixture builders.
- **Method.** I measured two mutants against the recorded history: 001's, 002's and 003's opponent and reality-check reports, with the 2026-09-09 manifest read in 003's directory.
  - Both mutants were byte-identical to CUR there in exit code, stderr and catalog. 001's opponent report stays at exit 3, as recorded.
  - I ran `tests/test-gate-contracts.sh` and `tests/test-spec-gate.sh` against each mutant in its own git-initialized copy.
  - I hunted the new positive rows for an attack asserted at exit 0.
  - I timed the reader against the length of a run.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-018
- **Severity:** wrong-result
- **Scenario:** A finding records a minor tier, and below it, after a blank line, the report or manifest carries text that both renderers show as a data-loss tier at the start of a rendered line or block. Both readers accept it, so a CLEARED round seals. T030o47 claims that a boundary error can only refuse, but its three new readings each diverge from the production they cite, on the accepting side:
  - **Block-rendered tags outside condition 6.** Prose written as `Note<pre>Severity: data-loss</pre>`, and the same with `listing`, `xmp`, `plaintext` or `hgroup`. Every HTML parser closes the paragraph and opens a block whose first text is the tier. `pre` is condition 1 of the same 4.6 that the rule cites, and GitHub's sanitizer allows it. The tag list at `:440` holds only condition 6.
  - **The reading after a break, out of its context.** Prose written as `[Note<br>](u)Severity: data-loss`, and the same with a p tag. Both renderers put the br inside the link text, so the second rendered line starts with the tier. `:447` reads the raw suffix after the tag, where the link's destination is still visible text, so its first word is `u`.
  - **Code spans that 6.1 does not form, or forms where the reader does not.**
    - An escaped backslash before a backtick (written as bracket, two backslashes, backtick, bracket, backtick, then the destination and the tier). The escaped backslash is literal, so the backtick opens a code span holding the bracket.
    - An escaped first backtick of a two-backtick run. Only one backtick is escaped, so the next one opens a span.
    - A backtick inside an HTML tag's attribute or inside an autolink, paired by the reader with a later backtick across a br, as in `<i title="x"></i>Note<br>Severity: data-loss` with a backtick in the title and one more at the end of the line. Raw HTML and autolinks bind before code spans.
    - At `:425` the reader treats a run after any backslash as escaped whole, and it pairs backticks inside tags. Each divergence either keeps the bracket live, so every reading starts at `u`, or makes the br inert.
  - **Run ends the reader invents.** A run is ended at `:490` by a line that is blank to the POSIX class space. That class also holds form feed, vertical tab and carriage return, which are not blank in 2.1. So a form-feed-only line between the two lines of a split tag (an open tag with a title on one line, then the line `x">Severity: data-loss</b>`) ends the run, and no candidate joins across it.
  - **Line endings the reader misses.** A lone carriage return is a line ending in 2.1, and both renderers split on it. `Note` followed by two lone carriage returns and then the tier is a second paragraph for both renderers, but a single line to the awk reader. A manifest Where value of `a.sh:1`, then one lone carriage return, then a whole field line carrying the data-loss tier, renders as a second bold tier list item.
  - **A heading inside an HTML block.** A `div` line, then a tag split over a line that begins with one `#`, renders the tier first in the div. The manifest pass seals it on CUR and on PRE.
- **Where:** scripts/verification-lib.sh:440, scripts/verification-lib.sh:447, scripts/verification-lib.sh:448, scripts/verification-lib.sh:425, scripts/verification-lib.sh:428, scripts/verification-lib.sh:453, scripts/verification-lib.sh:490, scripts/verification-lib.sh:1848, scripts/verification-lib.sh:313, templates/verification-contract.md:369, templates/verification-contract.md:375
- **Reproduced:** Every case ran in my copies, and every refusal below was checked by its exact diagnostic.
  - **Direct runs on CUR.** `vf_reports` exits 0 with empty stderr in both passes and both locales for `pre`, `hgroup`, `listing`, `xmp`, `plaintext`, the link around br and the link around p, both escape spellings, the tag-held backtick, the autolink-held backtick, the form feed, the vertical tab and the lone carriage return. The canonical catalog records G-050 at minor.
    - The manifest Where value with the carriage return exits 0 in the manifest pass.
    - The HTML-block heading exits 0 in the manifest pass.
  - **Controls.** The plain br in prose is refused in both passes and locales, with `a second Severity line in finding G-042` in the manifest pass and `a Severity line this grammar cannot read in finding G-050` in the canonical pass.
  - **Rendering.** markdown-it 12.3.2 and marked 17.0.5 agree on every member. The tier follows a closed link, a hidden tag or a paragraph break, or it is the first text of a pre, xmp, plaintext, listing or hgroup element that parse5 places as a block after the closed paragraph.
  - **End to end.** These seal a CLEARED round under both locales, and `tally` then reports `blocking=0 minor=1`. The completion line is `round completed gate=opponent round=1 verdict=CLEARED`.
    - **Mechanisms.** The pre tag, the link around br, the escaped backslash, the tag-held backtick, the form feed and the lone carriage return.
    - **Both passes.** Each ran as a manifest member re-recorded at minor and as a canonical new G-050.
    - **Control.** The control is refused at completion with exit 3.
  - **PRE.** Every member above also seals on PRE, so none of them is a regression of T030o47. They are gaps in what its new readings claim to close.
  - **Mutation, closing direction.** Mutant M2 made five changes. With them, every member except the HTML-block heading is refused by name in both passes and both locales, while the controls, the real ATX heading and every shipped positive I re-ran stay as they were:
    - The run counts as blank only for spaces and tabs, with an optional final carriage return.
    - `pre listing xmp plaintext hgroup` join the tag list.
    - The break reading also marks each tag, renders the whole text, and reads after each mark.
    - `vf_label_inert` tokenizes left to right, with one-character escapes and with raw HTML and autolinks taking precedence.
    - `vf_label` also reads after each lone carriage return.
  - **Mutation, history direction.** The history runs under M2 are byte-identical to CUR. The two changed suites under M2 are reported in Held up.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A visible blocking tier is read as prose by both readers, and a CLEARED round seals over it. This is O-018's wrong behavior.
  - The rule claims the readings stay approximations that refuse wherever one of them sees a label, and the kernel comment at `:313` says a boundary error cannot hide a label.
  - Neither holds where the reading's own production is incomplete. That includes the block tags the rule derives from condition 6 alone, the code span without 2.4 and without 6.1's precedence, the break reading without the link context, and the blank line and line ending of 2.1.
- **Class-wide fix:** Derive each reading from the full production, and test each against history as M2 was.
  - Take the rendered line starts from the HTML rendering and tree-building rules rather than condition 6 alone. On the refusing side, read after every tag that is not a known phrasing element.
  - Read after a break inside the rendered text: mark the tag and render the whole line.
  - Tokenize code spans left to right with 2.4 escapes and with raw HTML and autolinks first.
  - Make a blank line spaces and tabs only, and treat a lone carriage return as a line ending, or refuse it.
  - Keep a run open across a heading-shaped line inside an HTML block.
  - Add one row per member in both passes, and one end-to-end case per mechanism.

### Finding O-022
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** regression
- **Scenario:** The run reader ends a run at any line of one or more `#` marks followed by a space, while an ATX heading has at most six (4.2). `vf_block_start` at `:481` already spells it that way, and the rule and the contract both say the run ends at an ATX heading.
  - **The case.** A tag is split so that its title continues on a line that begins with seven marks, for example the line `####### x">Severity: data-loss</b>` after an open tag with a title. Both renderers keep that line in the paragraph and show the tier as its first visible word.
  - **CUR.** The run ends there, so no candidate joins the two lines. The line read alone starts at `x`.
  - **PRE.** The paragraph reader joined the line, because `vf_block_start` correctly declines it, and refused.
  - **Block quote.** The same happens inside a block quote with eight marks.
- **Where:** scripts/verification-lib.sh:490, scripts/verification-lib.sh:481, templates/verification-contract.md:376
- **Reproduced:** These ran in both passes and both locales.
  - **PRE.** PRE refuses both cases. The manifest pass prints `a second Severity line in finding G-042`, or `quoted content carries a Severity line` in the quote. The canonical pass prints `a Severity line this grammar cannot read in finding G-050`.
  - **CUR.** CUR exits 0 with empty stderr and records G-050 at minor. End to end, the seven-mark case seals a CLEARED round under both locales in both passes, with `tally` at `blocking=0 minor=1`.
  - **Mutant M1.** M1 changes only the run terminator to one to six marks. It refuses both cases with PRE's exact diagnostics, and a real six-mark heading still parses.
  - **M1 against history.** Its history runs are byte-identical to CUR. `tests/test-gate-contracts.sh` passes 18/18 and `tests/test-spec-gate.sh` passes 8/8, each at exit 0.
- **Root cause:** implementation-error
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A tier that the reader before T030o47 refused by name now seals a CLEARED round, and the repair itself caused it. The code diverges from its own rule, which ends a run only at an ATX heading.
- **Class-wide fix:** In `vf_para`, end a run only at a real ATX heading, using the six-mark alternation that `vf_block_start` uses. Add a row for seven marks in both passes, plain and quoted.

### Finding O-023
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** degraded
- **Scenario:** A finding carries a long run of non-blank lines, such as a Reproduced field with many sub-bullets that hold code spans, links and tags, as reports here do.
  - `vf_para` appends every line to every open candidate.
  - `vf_para_label` then runs the full `vf_label` on every candidate's joined text for every line.
  - The work therefore grows faster than the cube of the run length. Every `vf_reports` read pays it, and completion and `tally` each read the whole report.
- **Where:** scripts/verification-lib.sh:492, scripts/verification-lib.sh:500
- **Reproduced:** I timed one canonical round whose Reproduced field has n sub-bullets of about 90 characters, each holding a code span, a link and a b tag.
  - **CUR.** It takes 6 s at 50 lines, 73 s at 100 and 390 s at 150, all at exit 0.
  - **PRE.** It takes under 1 s at 100 and 1 s at 1000.
  - **History.** The longest run in the recorded history is 47 lines, in 003's opponent report. Across 001, 002 and 003 it was 8, 32 and 47.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** It fails closed, but completion of a round becomes slower with each long finding. The measurement before adoption covered only the history set, whose longest run is 47 lines.
- **Class-wide fix:** Drop a candidate once its joined text has a fixed first word and no open construct. That leaves no unclosed tag, link bracket or code span. Alternatively, cap the join at the longest construct the readings honour.

### Held up / follow-up tasks

**Held up:**
- **The rest of T030o47.** These held under my attack:
  - The six reported round-15 members and the siblings shipped as rows.
  - The every-line candidate reading for list markers, setext underlines, quote markers and four-space indentation inside a run.
  - The code-span reading for plain spans holding brackets or tags, and the canonical Where value with br and p tags.
- **No positive asserts an attack.** None of the new positive rows asserts an attack at exit 0. I rendered `quoted-heading-then-attribute-line`, `blank-line-ends-run`, `span-in-prose` and `escaped-backtick-prose`, and none shows a tier as a first word.
  - The legacy br-carried Where row is a legacy round, where the canonical rules are recorded as not applying.
- **O-020 and O-021** were not reopened by this delta.
- **M2 suites.** Under M2, `tests/test-gate-contracts.sh` passes 18/18 and `tests/test-spec-gate.sh` passes 8/8, each at exit 0.

**Follow-up tasks proposed:**
- T030o48: derive the rendered line start, code-span and line-ending readings from their full productions, read after a break in rendered context, and keep runs open across heading-shaped lines inside HTML blocks; add rows in both passes and end-to-end cases (→ O-018).
- T030o49: end a run only at an ATX heading of one to six marks (→ O-022).
- T030o50: bound the run reader's cost, measured on a run of at least 200 lines (→ O-023).
<!-- gate-round-end: opponent:16 -->
