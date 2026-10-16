## Round 14

**Round:** 14
**Timestamp:** 2026-10-02T16:20:45Z
**Source:** 75a92e76ef6817868f99e8ca6f477de33f2d97d3d839488de1e9a6acf8701415
**Floor:** FLOOR-auyetN
**Verdict:** CHALLENGED
**Blocking:** 2 · **Minor:** 1

### What I attacked

Scope: T030o44, the repair of round 13's O-018 with O-019 folded in, including the review's repairs from session 13. I also covered the consumers of the four changed files and the unchanged code those rules depend on.

- **The copy.** My copy is the worktree's `git ls-files -z --cached --others --exclude-standard` enumeration (8,927 files) under `/private/tmp/opp14/work`, made its own git repository, with a `TMPDIR` inside it that ends in `/`.
  - Its kernel hashes to `bbec9615…`, the value in `t030o44-edits/post-apply-3.sha256` through `post-apply-6.sha256`.
  - PRE is that kernel with the kernel hunk of `t030o44-final.diff` reversed. It hashes to `cad3c2c3…`, the value in `pre-apply.sha256`.
  - I read the reservation from `ROUND-14/meta.nul`: round 14, `FLOOR-auyetN`, source `75a92e76…`, reserved 2026-10-02T15:43:54Z.
- **Receipts.** All of these exit 0: `t030o44-dev8-full` and `-full-locale`, the capture, both mutation shards, the return validation, the accept, the floor, the floor validation, the scope and the reservation. Both dev8 logs show 15 suites whose counts sum to 147.
- **Method.**
  - I derived the lines that carry a tier from the productions the label reader claims to follow: CommonMark 0.31.2 inline HTML (6.6), links and images (6.3, 6.4), paragraph continuation (4.8, 5.2) and the HTML-block conditions (4.6). I did not start from the spellings the review named.
  - I put each line to both readers twice: directly through `vf_reports`, and end to end through `make_verification_git_dir`, `floor_fixture`, `floor`, a reservation and `round --complete`. Each fixture function came from a suite copy in my copy with `t_run_all` stripped, and ran in a subshell with a fresh `SANDBOX`.
  - Every case ran with every `LC_*` removed, under `LANG=C` and under `LANG=en_US.UTF-8`, and each was compared with PRE.
  - For rendering I used `marked` 17.0.5 together with the spec text. No strict CommonMark renderer is on disk.
- **Where the rules are switched on.** The T030o44 rules hold for "canonical rounds", so I asked which line decides that a round is canonical. The parser decides it per line, from a variable that the round's own text sets and resets. That is Finding O-020.
- **The label reader.** I attacked its rendered reading with constructs that nest and with constructs that span lines. That is Finding O-018, reopened.
- **The item rule.** I asked which lines a renderer lets interrupt the field's paragraph. That is Finding O-021, a minor regression.
- **The mutation matrix of record.** I read the five argued equivalents.
  - Q08's argument rests on "style is set only by a round heading", which is false: the title line and the Timestamp line also set it (O-020).
  - For L05, L19, R03b and B12 I read the arguments and found no counterexample.
- **Candidate fixes, measured before I propose them.**
  - For O-020: a five-line patch in my copy, judged against the probes, and against tallies and catalogs for 001, 002 and 003 in both locales. I restored the kernel afterwards, and `cmp` shows it identical to the worktree's.
  - For O-018: a survey of the recorded history using the kernel's own label functions with the candidate readings added.

Not reached:
- Linux: the Docker CLI did not answer, so I left Docker alone and ran no container.
- ShellCheck and hosted CI.
- My own whole suite. I ran two shipped fixture functions and my own fixture functions only.
- The tracker's other consumers.
- Umbrella and multi-repo roots.

Nothing in the worktree was created, modified, moved or removed except this report, and no suite or test function ran there.

### Finding O-020
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** A returned round puts a report title (`# Opponent review` followed by any text) right under its `## Round <n>` heading, and moves its Timestamp identity line below its findings.
  - Every line in between is judged by the legacy rules, but the round is still validated and sealed as canonical.
  - So a CLEARED round seals while its own report records an open blocking finding that was never counted. Any O-018 member that T030o44 now refuses passes the same way.
  - **How the style moves.** The round heading sets the style to canonical. The title line sets it to legacy while neither the Round line nor the Timestamp line has been read (`:1632`). The Timestamp line sets it back to canonical (`:1642`). Nothing requires the Timestamp to come before the content.
  - **What reads the legacy value.** Every rule T030o44 added reads it: the Finding-heading refusals (`:1670`, `:1671`), the close at `###` (`:1675`), the outside-a-finding and in-finding label rules (`:1702`, `:1703`), the item rule (`:1715`) and the quoted-record refusal (`:1623`).
  - **The older guards read it too.** The whole canonical block of `finding()` (`:1480`) reads it. That block holds completeness, the severity grammar, the duplicate-ID check, the Class binding, both resolved-claim checks, and the count itself (`:1501`). A finding is judged as canonical only if it is still open when the Timestamp line arrives.
  - **What reads the final value.** `flush()` reads the final value. It checks identity, sections, totals and verdict (`:1584`, `:1585`, `:1592`) against counts that the legacy-judged findings never fed.
- **Where:** scripts/verification-lib.sh:1632, scripts/verification-lib.sh:1642, scripts/verification-lib.sh:1480, scripts/verification-lib.sh:1501, scripts/verification-lib.sh:1584, scripts/verification-lib.sh:1585, scripts/verification-lib.sh:1592, scripts/verification-lib.sh:1623, scripts/verification-lib.sh:1670, scripts/verification-lib.sh:1675, scripts/verification-lib.sh:1702, scripts/verification-lib.sh:1703, scripts/verification-lib.sh:1715, templates/verification-contract.md:385
- **Reproduced:** Every case ran in my copy with every `LC_*` removed, under `LANG=C` and under `LANG=en_US.UTF-8`.
  - **An uncounted blocking finding, end to end.** The round 1 report is CLEARED with totals 0 · 1. It carries a canonical `### Finding G-099` (new, data-loss), then `### Finding G-100` (new, minor).
    - Without the title, `round --complete` exits 3 with `finding totals disagree` and `verdict disagrees with blocking findings`.
    - With the title, and the Timestamp after the Held-up section, it prints `round completed gate=opponent round=1 verdict=CLEARED report=680c8d4c…` under C (`477d6240…` under en_US.UTF-8) and exits 0.
    - `ROUND-1` then holds `report.sha256`, and `tally` reports `blocking=1 minor=1` from that one CLEARED round.
  - **Round 13's canonical member, end to end.** Round 1 is CHALLENGED, with G-042 at data-loss, and completes.
    - A CLEARED round 2 at 0 · 0 re-lists G-042 under `#### Finding G-042`. Without the title it exits 3 with `a Finding heading this grammar cannot read` and eleven lines of `a finding field outside any Finding`.
    - With the title it seals (`report=6826cf47…` under C, `0ca41e63…` under en_US.UTF-8), and `tally` reports `opponent rounds=2` with `blocking=1 minor=0`. So round 2 recorded nothing.
    - A CLEARED round 3 at 0 · 1 then seals (`report=80a68629…`). Its new G-050 is at minor, yet the finding also holds three data-loss lines that the shipped rows refuse: one behind `<b>`, one as a `####` heading label, and one canonical line after an empty comment.
  - **Direct `vf_reports`, with the target finding closed before the Timestamp.** Each of the following exits 0 with empty stderr under the title, and exits 3 without it with the named diagnostic:
    - CLEARED 0 · 1 carrying a new data-loss finding: `finding totals disagree`.
    - CLEARED 0 · 1 marking G-042 resolved after round 1 recorded it open: `clearing verdict rests on resolved findings this gate recorded open: G-042`.
    - A brand-new finding claimed resolved: `resolved finding G-077 has no earlier round of this gate and no declared prior-review record`.
    - The tier `catastrophic`: `unknown severity`.

    Every T030o44 member I tried also exits 0 under the title: behind HTML, a heading label, a continued value, an empty comment, and a level-four Finding heading.
  - **PRE.** The counting cases behave the same on PRE. So the defect predates T030o44, and every rule T030o44 added inherits it.
  - **Recorded history.** Round 8 (`notes/opponent.md:854`) tried this downgrade and recorded it as held. The block it measured had no Timestamp, so it failed the reservation check. A late Timestamp passes that check. The matrix's Q08 argument (`notes/verification/reports/t030o44-mutations.sh:191`) rests on the false premise named above.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-012
- **Wrong behavior:** The gate seals a CLEARED round whose own report records an open data-loss finding, and the tally counts that finding as blocking.
  - A resolved claim on an open finding buys clearance, and so does an invented resolution.
  - Every O-018 member that T030o44 refuses is read as prose again.
  - The contract (`templates/verification-contract.md:385`) and the Acceptance ("The canonical rules apply to canonical rounds of either gate") say the opposite.
  - The root cause is that neither the plan nor the contract says how a round's style is decided. The code keys every rule on a running per-line value, and round 8's conclusion took that value as fixed.
- **Class-wide fix:** Decide a round's style once, from the whole round, before any of its lines are judged.
  1. **The measured rule.** A Timestamp line is refused by name when the title line made its round legacy and the round already has content. Content here means any non-blank line other than the round heading, the title and the identity fields.
     - I measured it as a five-line patch in my copy. All nine flipped probes above are refused.
     - Against the unpatched kernel, the tallies, catalogs and diagnostics for 001, 002 and 003 are byte-identical for both gates, under C and under en_US.UTF-8. 001 exits 3 as recorded, and 003 gives `opponent rounds=13 reality-check rounds=1 blocking=27 minor=11 locations=388`.
     - Every canonical round in the history has its Timestamp before any content, and 002's titled rounds carry none.
  2. **Fixtures.** Add the counting case and one T030o44 member end to end, in both directions and with exact diagnostics, plus a mutant that drops the new refusal.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-018
- **Severity:** wrong-result
- **Scenario:** A finding carries a canonical tier line at minor, and a second line whose rendered text a reader sees as a data-loss tier. Both readers of finding records read that line as prose, and a CLEARED round seals.
  - T030o44's label reader reads every line as written and as rendered. But each reading sees one line at a time, and its link reader does not follow nesting.
  - **Nested brackets.** `vf_label_links` matches `!?\[[^]]*\]` (`:357`), which stops at the first closing bracket. CommonMark 6.3 lets link text hold balanced brackets and inline content, images included.
    - So a linked image keeps its alt word as the line's first word. The common badge shape `- [![badge](y.png)](z)Severity: data-loss` is an example, and so are `[![](y)](z)`, `[[]](x)` and an alt holding an escaped bracket.
    - `marked` renders the badge line as `<a href="z"><img src="y.png" alt="badge"></a>Severity: data-loss`. The plain image `![logo](y)` before the same text is refused (row `second-tier-image`).
  - **A construct across lines.** CommonMark lets a line ending fall in several places:
    - inside an open tag's whitespace and attribute values (6.6, whose own example is a `b2` tag with its attribute on the next line);
    - inside link text;
    - between a destination and its title (6.3);
    - inside an image's alt text.

    The second line then starts in the middle of the construct, so neither reading sees its opening angle bracket or bracket.
    - Examples: an item `- <abbr title="the tier this` continued by `finding carries">Severity:</abbr> data-loss`, an item `- <b` continued by `title="x">Severity: data-loss</b>`, an item `- [` continued by `](x)Severity: data-loss`, and an item ending in `[](x` continued by `"t")Severity: data-loss`.
    - `marked` renders each as one list item whose visible text is the data-loss tier.
    - The same constructs written on one line are refused.
- **Where:** scripts/verification-lib.sh:357, scripts/verification-lib.sh:366, scripts/verification-lib.sh:378, scripts/verification-lib.sh:1414, scripts/verification-lib.sh:1703, templates/verification-contract.md:355, templates/verification-contract.md:360
- **Reproduced:** Every case ran in my copy with every `LC_*` removed, under `LANG=C` and under `LANG=en_US.UTF-8`.
  - **The manifest pass, direct.** The manifest holds `### Finding G-042`, its Class line and `- **Severity:** minor`, then the second line. The round is `tier_round_fixture 1 '' G-042:tier-binding:open:minor`, which re-records G-042 at minor in a CLEARED round.
    - Four bracket spellings and four multi-line spellings each exit 0 with empty stderr, and record G-042 at minor.
    - The controls are a canonical second line and the plain image. Both exit 3 with `manifest line 6: a second Severity line in finding G-042`.
  - **The canonical pass, direct.** `record_round 1 CLEARED 0 1 '### Finding G-050' dup-binding new` takes the minor line and then the second line.
    - Both linked images, the tag split across lines, the wrapped `abbr` title, the empty link across lines, the title across lines and the alt across lines each exit 0, recording G-050 at minor.
    - The one-line `abbr`, `b` and link-title forms and the plain image each exit 3 with `a Severity line this grammar cannot read in finding G-050`.
  - **End to end.** Both cases went through `round --complete`.
    - A CLEARED round 1 over the badge manifest seals (`report=33fb53a9…` under C, `214fea24…` under en_US.UTF-8). The plain-image manifest is refused at completion with `manifest line 6: a second Severity line in finding G-042`.
    - A CLEARED round 2 whose new G-050 carries the minor line and the wrapped `abbr` item seals (`report=ce20e98b…`, `3b8d4da6…`). `tally` then reports `blocking=0 minor=2` and `severity-downgrades=0`.
  - **PRE.** Every member behaves the same on PRE. So the members predate T030o44, which states this class closed.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-012
- **Wrong behavior:** A visible blocking tier is read as prose by both readers, and a CLEARED round seals over it. This is O-018's wrong behavior.
  - The Acceptance and the contract (`:355-361`) say the rendered reading takes out images and inline HTML by CommonMark's own productions, and that an approximation can only refuse. Both claims fail for a construct that nests or spans lines, because the Acceptance defines a record line by line.
  - Round 13's reported members and the review's members stay closed.
- **Class-wide fix:** Read the record the way a renderer does, by paragraph and with nesting, and keep the union of the readings, so that an error can only refuse.
  1. **Nesting.** Reduce bracket pairs innermost first, to a fixpoint.
     - An image with a destination or a reference becomes a non-letter.
     - A link becomes its text between non-letters.
     - Any other pair keeps its text.
  2. **Paragraphs.** Read the label from each paragraph as well as from each line, as written and as rendered. A paragraph is a non-blank line joined with the following lines that `vf_block_start` does not take as a block start.
  3. **Measured against history.** I ran both readings, built from the kernel's own label functions, over every line of 001's, 002's and 003's opponent and reality-check reports, the real `opponent-findings-2026-09-09.md` manifest and the twelve returned round reports.
     - No line and no paragraph gains a label, so the readings refuse nothing recorded.
     - On a test file, the survey finds the badge line and both wrapped items, and leaves an ordinary link and the line `Severity was re-read twice.` as prose.
  4. **Fixtures.** Add the members above as rows in both passes, and one end-to-end case per mechanism.

### Finding O-021
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** A Class, Severity or Status field line is followed directly, with no blank line, by a block that a renderer starts there, ending the field's list item. Both passes still refuse the round, as a field whose list item holds more than its line. Such a block can be:
  - an HTML block such as a `div` or `details` element on its own line;
  - a fence of four or more backticks.
- **Where:** scripts/verification-lib.sh:280, scripts/verification-lib.sh:398, scripts/verification-lib.sh:400, scripts/verification-lib.sh:1389, scripts/verification-lib.sh:1609, tests/test-gate-contracts.sh:1355
- **Reproduced:** The round is a canonical CHALLENGED round whose canonical data-loss tier line is followed directly by one of three blocks: a `div` element, a four-backtick `text` fence, or a `details` element.
  - CUR exits 3 with `opponent.md:15: a Severity field whose list item holds more than its line in finding G-050`. PRE exits 0.
  - `marked` closes the list before each block: a closing `ul`, then the `div`, the `pre` and `code` pair, or the `details` element.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The pass refuses a report whose field item a renderer has already closed, and that costs a re-dispatch. It fails closed with a named diagnostic, so it is minor.
  - The kernel comment (`:280-281`) names CommonMark 4.6 conditions 1, 3, 4 and 5 as the kinds that may interrupt a paragraph. Condition 6 may too, since in 4.6 only condition 7 cannot.
  - The fence test (`:400`) admits exactly three backticks, while a fence opens on three or more.
  - The shipped row `value-details` asserts this over-refusal as a member.
- **Class-wide fix:** Derive the set from CommonMark 4.5 and 4.6. Add condition-6 starts, and backtick fences of three or more with no backtick in the info string, and correct the comment. Make `value-details` a positive row, with a `span` row as its refusal twin, because condition 7 cannot interrupt a paragraph. Every recorded round parses today, so the history is unaffected.

### Finding O-019
- **Class:** gate-report-schema-validation
- **Status:** resolved
- **Prior:** O-019
- **Severity:** minor
- **Scenario:** Round 13's two shapes. In the first, a `#### Notes` sub-heading sits between a manifest finding's Class line and its Severity line. In the second, a `#### Details` sub-heading sits directly under the Finding heading.
- **Where:** scripts/verification-lib.sh:1404
- **Reproduced:** I ran direct `vf_reports` under C and under en_US.UTF-8, for both shapes.
  - A CLEARED round 1 that re-records G-042 at minor exits 3 with `clearing verdict rests on 1 lowered severity tier(s) of known findings`, and with no line saying outside any Finding.
  - The CHALLENGED round at data-loss exits 0.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** Nothing remains wrong for round 13's subject. A deeper heading keeps the manifest finding open, and the field lines under it are read.
- **Class-wide fix:** Closed for this subject. Keep the O-019 rows.

### Escalation

Round 14 finds two substantive defects, O-020 (new) and O-018 (reopened), and one minor regression, O-021.
- **The spec is right.** REQ-011 and AC-012 correctly say that a clearing verdict must not rest on a blocking finding that was dropped or lowered.
- **The approach is wrong in two places.**
  - O-020 is structural and predates this task: which rules apply is decided by a value that the round's own text sets, line by line, so a report can switch the canonical rules off. It is measured, small and history-neutral to fix.
  - O-018 shows that a line-scoped approximation of rendered text stays an enumeration. This round's members nest or span lines, and they are found the same way the review's members were.
- **The decision is the user's.** The options are to repair O-020 now and O-018 by paragraph and nesting under new tasks, or to accept the risk with a signed waiver in the Decisions log in STATUS.md.

### Held up / follow-up tasks

These surfaces held:
- **Round 13's reported members and the T030o44 review's members.** All are refused by name. In my copy the shipped `report_record_line_cases` and `round_record_line_cases` exited 0 with no assertion output (16:12:55Z to 16:15:23Z).
- **O-019.** It is resolved, as its finding says.
- **The union design where the stripper over-deletes.** An autolink, a non-tag, a named reference, an empty link and a footnote reference before the label are all refused. These are the shipped rows.
- **The style-agnostic duplicate key.** An indented second Severity is refused even inside O-020's legacy window: my first round-3 attempt failed on exactly that.
- **Recorded history.** For 001, 002 and 003, the tallies and the catalogs of both gates are byte-identical under the unchanged kernel and under my O-020 candidate, in both locales. 001 exits 3, as recorded. 002 and 003 exit 0, and 003 gives `opponent rounds=13 reality-check rounds=1 blocking=27 minor=11 locations=388`.
- **The receipts listed under What I attacked.** They reproduce as stated.

Proposed follow-up tasks:
- **T030o45, for O-020.** Decide a round's style once, for the whole round, and refuse by name a canonical identity line that follows content judged under the legacy rules. Fixtures go in both directions, end to end, with the counting case, one T030o44 member and one mutant. Re-run the history tallies.
- **T030o46, for O-018, with O-021 folded in.** Read Class and Severity labels by paragraph as well as by line, and reduce nested brackets to a fixpoint, in both passes. Derive `vf_block_start` from CommonMark 4.5 and 4.6. Turn the `value-details` row into a positive with a refusal twin. Add the members as rows in both directions.
<!-- gate-round-end: opponent:14 -->
