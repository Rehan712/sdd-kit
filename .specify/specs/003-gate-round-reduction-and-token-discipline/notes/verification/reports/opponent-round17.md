## Round 17

**Round:** 17
**Timestamp:** 2026-10-09T07:39:13Z
**Source:** 54c64d8346fe2459204e68de298f193bb5ea0abe8de86c00de159f05eac07129
**Floor:** FLOOR-QCFkfi
**Verdict:** CHALLENGED
**Blocking:** 2 · **Minor:** 1

### What I attacked

I worked only in copies under `/private/tmp/opp17` with `TMPDIR` ending in `/`. Each copy was rsynced from the worktree with `.git` excluded and then git-initialized. In the worktree I created nothing except this report. I ran no floor, round, checkpoint, capture or accept there.

- **Scope.** I attacked T030o48, T030o49 and T030o50 in both readers of finding records: the manifest pass (`scripts/verification-lib.sh:1610`) and the canonical pass (`:1837`).
  - **T030o48.** The narrowed grammar: `vf_para` sets `vf_narrow` (`:584-601`). `vf_cm_scan` places code spans (`:454-467`), and `vf_label_inert` reads them (`:468-479`).
  - **T030o49.** The six-mark run terminator (`:598`).
  - **T030o50.** The settled-candidate rule: `vf_settled` and its helpers (`:480-535`), and `vf_para_label` (`:603-614`).
  - **Wider surfaces.** I also attacked the extent of a finding as both passes read it (`:1616-1631`, `:1917`, `:1944`), and the shared fence tracker (`:116`) as those readers consume it.
- **Derivation.** I derived each case from CommonMark 0.31.2, not from the spellings already reported:
  - 6.1: a code span binds tighter than everything except raw HTML and autolinks, and the parser reaches a link destination or title before any later backtick.
  - 6.5: an email autolink's local part may begin with a digit or a symbol, and may hold a backtick.
  - 4.7: a link reference definition renders nothing, and its title may span lines.
  - 5.2 and 4.5: a fence opened inside a list item ends with that item.
- **Rendering.** I rendered every member with markdown-it 12.3.2 (html enabled) and marked 17.0.5, the binaries the r17 repro used.
- **Runs.** I ran every member directly through `vf_reports`, in both passes and under `LANG=C` and `LANG=en_US.UTF-8` with every `LC_*` removed.
  - I ran each member on CUR (the frozen tree) and on PRE (CUR with `r17-session.diff` reversed).
  - I ran each mechanism end to end through `spec-gate.sh floor`, `round`, `round --complete` and `tally`. Those runs used the suite's own `make_verification_git_dir`, `floor_fixture` and `record_line_report`, in a file of my own inside my copy.
- **Mutants.** I built three mutants, M1, M2 and M3, one per finding.
  - **Closing direction.** Each mutant refuses or speeds up its own members with an exact diagnostic, and the controls stay as they were.
  - **History.** Each was measured against 001's, 002's and 003's opponent and reality-check reports, with 003's 2026-09-09 manifest, under both locales. Exit codes, stderr and catalogs are byte-identical to CUR, and 001's opponent report stays at exit 3.
  - **Suites.** I ran `tests/test-gate-contracts.sh` and `tests/test-spec-gate.sh` against each mutant in its own copy. The results are reported under Held up.
- **Positives.** I hunted the new positive rows in `tgc-2` and `tsg-1` for an attack asserted at exit 0.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-018
- **Severity:** wrong-result
- **Scenario:** Inside a finding, below a minor tier, a line carries live raw HTML that renders a data-loss tier at the start of a rendered line or block. A backtick sits inside a construct that binds before any later backtick, and the line ends with one more backtick. Three constructs do it:
  - an email autolink whose local part starts with a digit and holds a backtick, as in the line written `` Note <1`@a.b><pre>Severity: data-loss</pre>` ``;
  - a link destination holding a backtick, as in `` [x](u`v)<br>Severity: data-loss, tick: `. ``;
  - a link title holding a backtick, as in `` [x](u "`")<br>Severity: data-loss, tick: `. ``.
  - **The gate's reading.** `vf_cm_scan` flags a `<` only before a letter, `/`, `!` or `?`. It pairs the inner backtick with the last one into a code span, so the `<br>` or `<pre>` reads as inside a span. `vf_narrow` stays empty, and `vf_label_inert` makes the tag inert for the break reading too.
  - **The renderers' reading.** The autolink or link consumes the inner backtick first. The tag is live, and the final backtick is literal.
  - The T030o48 rule and the contract both say an autolink inside a finding is refused, and that a `<` is inside a code span only when every reading places it there. No reading of the code places a backtick inside an autolink or a link destination.
- **Where:** scripts/verification-lib.sh:460, scripts/verification-lib.sh:454, scripts/verification-lib.sh:468, scripts/verification-lib.sh:594, scripts/verification-lib.sh:1610, scripts/verification-lib.sh:1837, templates/verification-contract.md:382
- **Reproduced:** Every case ran in my copies, and every refusal was checked by its exact diagnostic.
  - **Direct runs.** On CUR, `vf_reports` exits 0 with empty stderr for all three members in both passes and both locales, with `pre`, `br` and `p` spellings. The catalog records G-050, or the manifest's G-042, at minor.
  - **Control.** The same line without the autolink is refused: `raw HTML outside a code span in finding G-050`.
  - **Rendering.** markdown-it and marked agree on every member: a mailto or plain link, then the live `<br>`, `<pre>` or `<p>` with the tier as its first text.
  - **End to end.** The autolink member seals a CLEARED round 1 in both passes under both locales, as a canonical new G-050 and as a manifest G-042 re-recorded at minor. The completion line is `round completed gate=opponent round=1 verdict=CLEARED`, and `tally` reports `blocking=0 minor=1`. The control is refused at completion with exit 3 and the diagnostic above.
  - **PRE.** All members also pass on PRE, so this is a gap in T030o48's claim, not a regression.
  - **M1.** M1 adds one reading that masks backticks inside an autolink-shaped or destination-shaped segment before the scan. It refuses every member in both passes and both locales with `raw HTML outside a code span in finding G-050` or `... G-042`. `Use` followed by a code span holding `<br>` still parses, and so does a code span inside link text. The M1 history runs are byte-identical to CUR.
- **Root cause:** implementation-error
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** Raw HTML inside a finding passes the narrowed grammar, and the round-16 members it was adopted to close come back.
  - A visible data-loss tier is read as prose by both readers, and a CLEARED round seals over it.
  - The rule's claim that a reading the reader invents cannot hide a `<` fails, because the code-span reading is not the only reading of where a backtick stands.
- **Class-wide fix:** Place code spans after the constructs that bind before them, or narrow further.
  - **Placing spans.** Take a backtick inside an autolink (6.5, both kinds), a link destination or a link title as literal in at least one reading, so that a `<` counts as inside a span only when that reading agrees.
  - **Narrowing further.** Alternatively, refuse inside a finding a backtick that stands inside such a construct.
  - **Rows.** Add one row per construct in both passes, and one end-to-end case.

### Finding O-024
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** The extent of a finding, and which of its lines a reader sees, are decided by readings a renderer does not share. Two mechanisms each seal a lowered tier, and together they leave data-loss as the only tier on the rendered page.
  - **A finding closed early.** After the finding's fields, a list item whose only text opens a three-backtick fence is followed by an indented line `  ### x`. A renderer shows that line as code inside the item. The tracker opens no fence after a list marker, though, so both passes read the line as a heading as shallow as the Finding heading and close the finding.
  - **A visible tier the gate does not read.** The next line is a sibling item written `- **Severity**: data-loss`. A renderer shows it as an item of the same list, in the same section. The canonical pass checks prose labels only while `fid` is set. The manifest pass refuses a stray tier only when `idseen` is set, and `### x` does not set it.
  - **A tier no reader sees.** Earlier in the same finding, after a blank line, a link reference definition `[a]: /u '` carries a title across three lines. Its second line is an indented `- **Severity:** minor`, and its third line, `    - x'`, closes the title. A renderer shows nothing of the definition. Both passes read the indented line as the finding's Severity field. The item check accepts the next line because `vf_block_start` reads it as a list item.
- **Where:** scripts/verification-lib.sh:1917, scripts/verification-lib.sh:1626, scripts/verification-lib.sh:1641, scripts/verification-lib.sh:1944, scripts/verification-lib.sh:116, scripts/verification-lib.sh:1609, templates/verification-contract.md:382
- **Reproduced:** Every case ran in my copies, under both locales.
  - **Rendering.** With both mechanisms, markdown-it and marked render the finding's h3 and its fields, then a list. The list holds a code block showing `### x` and then an item reading `Severity: data-loss`. No minor tier appears anywhere.
  - **Direct runs.** On CUR and on PRE, `vf_reports` exits 0 with empty stderr and records G-050 at minor. It does the same for the fence-only variant, where the visible minor field stays above the code block and a second, data-loss tier shows below it unrefused, and for the definition-only variant. The manifest pass on the same text exits 0 with G-042 at minor.
  - **End to end.** The combined case seals a CLEARED round 1 as a canonical G-050, and over a manifest G-042 re-recorded at minor, in both locales. The completion line is `round completed gate=opponent round=1 verdict=CLEARED`, and `tally` reports `blocking=0 minor=1`.
  - **M2.** M2 adds two narrowing clauses to `vf_para`. The first refuses a list marker followed by a fence run, printing `a code fence inside a list item in finding G-050`. The second refuses a line starting a link reference definition, printing `a link reference definition in finding G-050`. M2 refuses every variant in both passes and both locales. Its history runs are byte-identical to CUR.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A CLEARED round seals a finding whose only rendered tier is data-loss, at minor.
  - The narrowed grammar shields a finding against raw HTML only. The finding's extent still comes from a line reader that misses a fence a list item opens, and a construct that renders nothing still carries a field line.
  - The rule says a boundary error can only refuse. It does not hold for the boundary that closes a finding.
- **Class-wide fix:** Narrow the finding grammar to what both readers can follow. Inside a finding, refuse by name a fence opened after a list marker and a link reference definition, as M2 does, or end a finding only at a heading at least as shallow as its own, outside any construct a renderer opens.
  - **Rows.** Add rows for each mechanism in both passes, and one end-to-end case.

### Finding O-023
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-023
- **Severity:** degraded
- **Scenario:** A finding's Reproduced line quotes one opening bracket in a code span (as `` `[` ``, which the reports here do), and ordinary sub-bullets follow it.
  - `vf_settled_brackets` is applied to the text as written, where a bracket inside a code span still counts as open. That bracket comes after the line's first word, so it cannot change how any reading begins. Even so, the candidate is never settled.
  - That candidate is extended and re-read through `vf_label` on every following line of the run. The bracket reduction in `vf_label_links` restarts from the start of the text for each pair.
- **Where:** scripts/verification-lib.sh:531, scripts/verification-lib.sh:501, scripts/verification-lib.sh:600, scripts/verification-lib.sh:609, scripts/verification-lib.sh:409
- **Reproduced:** I timed one canonical round on CUR, with the bracket on the Reproduced line followed by n sub-bullets of about 100 characters, each holding two code spans, a link and emphasis.
  - **CUR.** It takes 42.7 s at 200 lines and 305 s at 400, both at exit 0. That misses T030o50's own bound of under 30 s at 400 lines, with at most four times the time when the run doubles.
  - **Every line.** With the bracket on every line, it takes 1.6 s at 50, 11.2 s at 100, 37 s at 150 and 89 s at 200.
  - **History.** 003's opponent report already has seven lines with an unbalanced bracket inside a code span.
  - **M3.** M3 checks brackets only up to the end of each reading's first word. It takes 0.30 s at 400 lines and 0.12 s for the every-line shape at 200. Its history runs are byte-identical to CUR.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** It fails slow, not open. Completing a round and running `tally` each re-read the whole report, so one quoted bracket above a long Reproduced field costs minutes on every read. That is the cost T030o50 was accepted to bound.
- **Class-wide fix:** Count as unsettling only the constructs that open at or before each reading's first word, for brackets as M3 does and likewise for destinations. Add the 400-line timing row with a quoted bracket.

### Held up / follow-up tasks

**Held up:**
- **T030o49.** It holds. A line of seven or eight marks, plain or behind block-quote markers, no longer ends a run, while a one-to-six-mark ATX heading does. A heading-shaped line indented four or more spaces, or behind a tab after a block-quote marker, keeps the run open, which refuses rather than accepts.
- **T030o48, outside O-018's members.** These held:
  - The form feed, vertical tab and lone carriage return checks on the line as written, including a final carriage return read as the line ending.
  - The blank-line reading of spaces and tabs only.
  - The multi-line span states (a span left open read as opener and as literal), escapes in pairs, and the escaped `<`.
  - The every-reading rule for spans the reader itself invents from plain backticks.
  - Character references that decode to `<`, which render as text.
- **T030o50's soundness.** I found no candidate dropped before a later line could change its first word. Joined text adds a space, every construct that can hide a leading word must close before settling, and a link reference definition ends at a line end, so the text after it starts a candidate of its own.
- **Positives.** No new positive row asserts an attack at exit 0. I rendered `a-image-split-by-blank-line`, `a-image-split-by-six-marks`, `a-span-tag-after-a-lone-backtick-paragraph`, `a-escaped-backtick-prose` and `a-nbsp-line`, and none shows a tier as a first word.
- **Mutant suites.** Under M1, `tests/test-gate-contracts.sh` passes 18/18 and `tests/test-spec-gate.sh` passes 8/8, each at exit 0. Under M2 and under M3, both suites pass at the same counts, each at exit 0.
- **Minor, non-blocking.** The narrowed check is judged on a line before that line's own heading opens or closes a finding, so it is off by one heading at both ends of a finding:
  - The first Finding heading of a round may carry raw HTML. `### Finding G-050` followed by a b tag parses.
  - A later Finding heading, or the section heading that closes a finding, is refused under the previous finding's ID.
  - I found no tier attack through it, because any tag that hides content needs a closer, and that closer is refused inside the finding.

**Follow-up tasks proposed:**
- T030o51: Place code spans after autolinks (both kinds) and link destinations and titles, or refuse a backtick inside them within a finding. Add rows in both passes and one end-to-end case (→ O-018).
- T030o52: Inside a finding, refuse by name a fence opened after a list marker and a link reference definition, or derive the finding's extent from the constructs a renderer opens. Add rows in both passes and one end-to-end case (→ O-024).
- T030o53: Settle a candidate on the constructs that open at or before each reading's first word, and add a 400-line timing row whose run holds a bracket quoted in a code span (→ O-023).
- Optionally, judge the narrowed check after the line's own heading has been read (minor, above).
<!-- gate-round-end: opponent:17 -->
