## Round 18

**Round:** 18
**Timestamp:** 2026-10-14T13:22:23Z
**Source:** 567cb6e04411ca525cb059fc247ab7ac34b1c52718f969d3478734ee69a7228e
**Floor:** FLOOR-OgYGoP
**Verdict:** CHALLENGED
**Blocking:** 2 · **Minor:** 1

### What I attacked

I worked only in copies under `/private/tmp/opp18`, with `TMPDIR` ending in `/`. Each copy was rsynced from the worktree with `.git` excluded and then git-initialized. CUR (the frozen tree) hashes as `r18-edits/post-apply-3.sha256`. PRE is CUR with `r18-session.diff` reversed, and it hashes as `r18-edits/pre-apply.sha256`. In the worktree I created nothing except this report, and I ran no floor, round, checkpoint, capture or accept there. I hashed every worktree file before and after my run.

- **Scope.** I attacked T030o51, T030o52, T030o53 and the folded minor in both readers of finding records: the manifest pass (`scripts/verification-lib.sh:1711`) and the canonical pass (`:1942`, `:1976`, `:2011`, `:2024`).
  - **The changed code.** `vf_cm_dest`, `vf_cm_label` and `vf_cm_scan` (`:475-537`), `vf_para_refdef` and `vf_para` (`:665-700`), and `vf_settled_head` and `vf_settled_word` (`:557-568`).
  - **Unchanged code they feed.** `vf_label`, `vf_label_breaks` and `vf_para_label`.
- **Derivation.** I derived each case from the productions the reference renderers apply, not from round 17's spellings, and not from CommonMark 0.31.2 alone:
  - which constructs consume a backtick before a code span can open: CommonMark 6.1, 6.3 and 6.5, GFM's extended autolinks, and marked's reference-link tokenizer;
  - where a renderer starts a new line: GFM tables, and the gate's own block-level tag list;
  - what can still change a candidate's first word after it is settled.
- **Rendering.** I rendered every member with markdown-it 12.3.2 (html enabled) and marked 17.0.5, the binaries `r18-repro.sh` used. No cmark-gfm is on disk, so I did not run GitHub's renderer.
- **Runs.** I ran every member directly through `vf_reports` in both passes, under `LANG=C` and `LANG=en_US.UTF-8` with every `LC_*` removed, on CUR and on PRE.
  - I ran each mechanism end to end through `spec-gate.sh floor`, `round`, `round --complete` and `tally`.
  - Those runs used the suite's own `make_verification_git_dir`, `floor_fixture` and `record_line_report`, in a file of my own inside my copy.
- **Mutants.** I built one mutant per finding (M1, M2, M3) and one that combines all three (MALL).
  - Each mutant refuses its own members with an exact diagnostic, or ends the slow path, while the controls and positives stay as they were.
  - The history and both record-reader suites were run against MALL. The results are under Held up.
- **Positives.** I rendered the 34 new positive rows: the 18 manifest shapes in `tgc-1` and the 16 canonical `a-` rows. None shows a data-loss tier at the start of a block, a cell or a rendered line.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-018
- **Severity:** wrong-result
- **Scenario:** Inside a finding, below a minor tier, a line carries a backtick inside a construct that marked binds before any code span, and the line ends with one more backtick. The reader pairs the two backticks into a code span that holds a br or pre tag. marked renders that tag live, with the data-loss tier as the first text of the new line.
  - **An extended autolink.** GFM's URL literal takes every character up to whitespace or an angle bracket, a backtick included. Examples are the line written `` Note http://a.b/`<br>Severity: data-loss, tick: `. `` and its `https://`, `www.` and `ftp://` spellings (the last with a pre tag).
  - **A shortcut, collapsed or image reference.** The member is written `` Note [a`b]<br>Severity: data-loss, tick: `. ``, or with `[]` or a leading `!`. It needs a definition of that label outside every finding, where definitions still parse. marked's reference tokenizer reads the label up to the first bracket without regard to code spans.
  - **The gate's reading.** `vf_cm_scan` stops only at a closing bracket, a backslash, an angle bracket and a backtick. It reads a destination or a label only after a closing bracket followed by a parenthesis or a bracket, so it sees neither construct.
    - The inner backtick pairs with the last one, so the tag reads as inside a span and `vf_narrow` stays empty.
    - `vf_label_inert` makes the tag inert, so the break reading sees nothing either.
  - **The renderers.** markdown-it agrees with the reader and renders a code span. marked renders a link whose target ends in `%60`, then the live tag, then the tier.
  - **The derivation.** T030o51's acceptance derives its constructs from CommonMark 0.31.2 only, while the renderers every repro of this gate uses include marked, which applies GFM.
- **Where:** scripts/verification-lib.sh:514, scripts/verification-lib.sh:509, scripts/verification-lib.sh:538, scripts/verification-lib.sh:690, scripts/verification-lib.sh:1711, scripts/verification-lib.sh:1942, templates/verification-contract.md:382
- **Reproduced:** Every case ran in my copies, and every refusal was checked by its exact diagnostic.
  - **Direct runs.** On CUR, `vf_reports` exits 0 with empty stderr for all seven spellings, in both passes and both locales. The catalog records G-050, or the manifest's G-042, at minor.
  - **Control.** The line `Note <br>Severity: data-loss.` is refused with `raw HTML outside a code span in finding G-050`.
  - **End to end.** The URL member and the reference member each seal a CLEARED round 1 in both passes under both locales, as a canonical new G-050 and as a manifest G-042 re-recorded at minor. The completion line is `round completed gate=opponent round=1 verdict=CLEARED`, and `tally` reports `blocking=0 minor=1`. The control is refused at completion with exit 3.
  - **PRE.** Every member also passes on PRE, so this is a gap in T030o51's claim, not a regression.
  - **M1.** M1 adds two checks to `vf_cm_scan`, each made only where a reading places the construct outside every code span.
    - A bracket pair closed on its line that holds a backtick run it does not close is refused with `a backtick inside a link destination, title or label in finding G-050`.
    - A URL literal after `http`, `https` or `ftp` and a colon, or after `www.`, whose run up to whitespace or an angle bracket holds a backtick, is refused with `an autolink outside a code span in finding G-050`.
    - M1 refuses every member in both passes and both locales (`... G-042` in the manifest pass). The positives still parse: `See https://x.example/a and` followed by a code span, link text holding a closed code span, full and collapsed reference prose, and pipes in prose and in code spans.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A data-loss tier visible on a reference renderer is prose to both readers, and a CLEARED round seals over it at minor. The rule's claim that a span the reader invents cannot hide a tag fails, because the reader's code spans are placed by CommonMark while marked places them after these two constructs.
- **Class-wide fix:** Derive the refused constructs from what each reference renderer binds before a code span, GFM's extended autolinks and marked's reference tokenizer included, or narrow further.
  - **Narrowing.** Inside a finding, refuse a backtick inside a bracket pair, or inside a URL literal, that some reading places outside every code span, as M1 does.
  - **Rows.** Add one row per spelling in both passes, and one end-to-end case per construct.

### Finding O-025
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** Inside a finding, below a minor tier, sits a GFM table whose second column carries a data-loss tier.
  - **The member.** The table's lines are a header line `| Step | Result |`, a delimiter line `| - | - |`, and a row `| ran | x |` whose `x` is the canonical bold Severity label followed by `data-loss`.
  - **The renderers.** markdown-it and marked both render a table whose second cell starts with a bold Severity label and data-loss. That is the rendering the gate refuses when it is written as a raw td tag, because td is in its own list of block-level tags after which a renderer starts a new line (`:619`).
  - **The gate's reading.** The label reader reads the first word of each line and of each run, and the text after each br or block-level tag. It never splits a line at a pipe, so the cell's tier is prose, and nothing in the narrowed grammar refuses a table.
  - **A list-item spelling.** The same table indented under a list item, with alignment colons in the delimiter line, behaves the same in both renderers and both passes.
- **Where:** scripts/verification-lib.sh:632, scripts/verification-lib.sh:617, scripts/verification-lib.sh:619, scripts/verification-lib.sh:364, scripts/verification-lib.sh:701, scripts/verification-lib.sh:676, scripts/verification-lib.sh:1711, scripts/verification-lib.sh:1942, templates/verification-contract.md:371
- **Reproduced:** Every case ran in my copies, under both locales.
  - **Direct runs.** On CUR, `vf_reports` exits 0 with empty stderr for both spellings in both passes. The catalog records G-050, or the manifest's G-042, at minor.
  - **Controls.** A one-column table whose only cell is the tier is refused with `a Severity line this grammar cannot read in finding G-050`. The same tier after a raw td tag is refused with `raw HTML outside a code span in finding G-050`.
  - **End to end.** The table seals a CLEARED round 1 in both passes under both locales, as a canonical new G-050 and as a manifest G-042 re-recorded at minor. The completion line is `round completed gate=opponent round=1 verdict=CLEARED`, and `tally` reports `blocking=0 minor=1`.
  - **PRE.** Every case also passes on PRE. The gap dates from the label reader itself, not from this repair.
  - **History.** No delimiter line stands inside any finding of 001's, 002's or 003's opponent and reality-check reports. Each reality-check report holds one table, outside every finding.
  - **M2.** M2 refuses, inside a finding, a line that may be a GFM delimiter line: hyphen cells with optional colons and at least one pipe. It prints `a table delimiter row in finding G-050`, or `... G-042` in the manifest pass. M2 refuses both spellings in both passes and both locales, and pipes in prose and in code spans still parse.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A data-loss tier rendered as the first text of a table cell, which both reference renderers show, is prose to both readers. A CLEARED round seals over it at minor.
- **Class-wide fix:** Narrow the finding grammar to exclude tables, or read them.
  - **Narrowing.** Inside a finding, refuse by name a line that may be a table delimiter line, as M2 does.
  - **Reading.** Alternatively, read the label after every unescaped pipe in a run that holds a delimiter line. GFM splits cells inside code spans too, so that reading cannot skip spans.
  - **Rows.** Add rows in both passes and one end-to-end case.

### Finding O-023
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-023
- **Severity:** degraded
- **Scenario:** A finding's field holds a run of sub-bullets, each of which begins with a link, written as `  - [step 1](https://x.example/1) ran ...`. An image or a bracket other than a task checkbox at the start of each line does the same.
  - **The mechanism.** `vf_settled_word` checks brackets only in `vf_settled_head`, which stops at the end of the first word. A pair that opens before the first word and closes after it is therefore open in the head. The candidate is never settled, and every later line of the run re-reads it through `vf_label`.
  - **PRE.** PRE settled these candidates, because it checked bracket balance over the whole text.
  - **Direct calls.** `vf_settled` returns 0 on CUR and 1 on PRE for each of these texts: `- [the log](x) shows exit 0`, `  - ![badge](y.png) step 3`, `1. [step](u) ran`, and a line led by a code span holding a bracket that is not a checkbox. For round 17's shapes it returns 1 on CUR and 0 on PRE.
- **Where:** scripts/verification-lib.sh:557, scripts/verification-lib.sh:566, scripts/verification-lib.sh:583, scripts/verification-lib.sh:609, scripts/verification-lib.sh:709, templates/verification-contract.md:380
- **Reproduced:** I timed one canonical round whose Reproduced field holds n sub-bullets of the form `[step i](https://x.example/i) ran`, followed by a code span, emphasis and another code span, which is T030o53's own timing shape with its link moved to the front.
  - **CUR.** It takes 2.8 s at 50 lines, 29.4 s at 100, 145 s at 150 and 373 s at 200, each at exit 0. Doubling the run from 100 to 200 lines multiplies the time by 12.7.
  - **PRE.** It takes 0.10 s at 100 lines and 0.32 s at 400.
  - **The bound.** T030o53's acceptance requires that 400 sub-bullets with code spans, links and emphasis parse in under 30 s, and that doubling the run at most quadruples the time. Its timing row keeps each link after the first word.
  - **History.** The history is unaffected. 003's opponent report takes 1.47 s on CUR (1.52 s on PRE), and no line of 001's, 002's or 003's reports begins with link text.
  - **M3.** M3 settles a reading when its head's brackets balance or its whole text's brackets balance with complete destinations. That is the union of T030o53's rule and T030o50's, each argued sound alone. M3 takes 0.17 s at 200 lines and 0.32 s at 400, and round 17's shape stays at 0.31 s at 400 lines.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** It fails slow, not open, and it is slower than the round-17 tree on a shape that tree parsed at once. Completing a round and running `tally` each re-read the whole report, so one such run costs minutes on every later read.
- **Class-wide fix:** Count a bracket before the first word as unsettling only while that reading leaves it unclosed, or settle on either test, as M3 does. Add a 400-line timing row whose sub-bullets begin with a link, an image and a code span holding a bracket.

### Held up / follow-up tasks

**Held up:**
- **T030o51 under CommonMark 0.31.2.** It holds for every construct those productions bind before a code span. Each of these was refused by name in both passes and both locales:
  - a destination with nested parentheses holding a backtick;
  - a title holding a backtick in parentheses and in single quotes;
  - a title separated from the destination and the closing parenthesis by tabs;
  - email autolinks whose local part begins with a hash, a tilde or a single quote.
  - A character reference spelling the br tag renders as text and parses, which is right.
  - By reading `vf_cm_dest` and `vf_cm_label` against 6.3, an invalid pointy destination, a control character in a destination and an unescaped parenthesis in a parenthesized title can only over-refuse. Every character 6.5 lets an email local part begin with is in `vf_cm_ac` or the raw-HTML class.
  - marked 17.0.5's strikethrough respects code spans, and GFM's email literal takes no backtick.
- **T030o52.** It holds. Every list-marker form I tried is refused: an ordered marker with a parenthesis, a marker followed by a tab, nested markers, and an item whose first line is empty (the canonical pass refuses that one by its item rule first).
  - A fence behind a block-quote marker is not refused. Every line it holds needs the marker too, though, and neither pass reads a marker-led line as a heading, so the data-loss line after it is refused with `a Severity line this grammar cannot read in finding G-050`.
  - Both renderers agree that a column-zero fence after an item leaves the item.
  - Definitions are refused after list and quote markers in either order, and the shipped rows cover labels across lines and escaped labels. A footnote definition is refused as a definition.
- **T030o53's soundness.** I found no candidate the new rule settles whose first word a later line can change.
  - Joining adds a space, so emphasis and references never merge across lines.
  - An image that takes the first word needs its opening bracket in the head of some reading. The inert reading keeps a leading code span's letters, and a span with none leaves the bracket in the head.
  - A destination left open in the head unsettles the candidate.
  - A definition ends at its line end, so the next line is a candidate of its own.
- **The folded minor.** It holds. A tag on the first Finding heading of a round is refused under the finding it opens, a later Finding heading is refused under its own ID, and a section heading that closes a finding is outside it.
- **Positives.** No new positive row asserts an attack at exit 0.
- **Mutant suites.** Under MALL (M1, M2 and M3 together), `tests/test-gate-contracts.sh` passes 18/18 at exit 0 and `tests/test-spec-gate.sh` passes 8/8 at exit 0.
- **History under the mutants.** MALL and M3 each leave every output byte-identical to CUR, under both locales. That covers the catalogs, diagnostics and exits of 001's, 002's and 003's opponent and reality-check reports (001's opponent report stays at exit 3), their tallies, 003's 2026-09-09 manifest, and the 16 returned round reports read as manifests.

**Follow-up tasks proposed:**
- T030o54: Inside a finding, refuse a backtick inside a bracket pair, or inside a GFM URL literal, that some reading places outside every code span; or derive the constructs from what marked binds before a code span. Add rows in both passes and one end-to-end case per construct (→ O-018).
- T030o55: Inside a finding, refuse by name a line that may be a GFM table delimiter line, or read the label after every unescaped pipe of a table run. Add rows in both passes and one end-to-end case (→ O-025).
- T030o56: Settle a candidate when a bracket before the first word is closed in that reading, not only when the head balances. Add a 400-line timing row whose sub-bullets begin with a link, an image and a code span holding a bracket (→ O-023).
<!-- gate-round-end: opponent:18 -->
