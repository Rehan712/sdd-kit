# Independent review — T030o44 (spec 003, round-13 O-018 with O-019) — COMPLETE

Reviewer: independent read-only reviewer, 2026-10-01. Started 18:56 CEST.
Environment at start: df -h / 7.6 GiB avail; swap 1931M used of 3072M; on battery, 25 %, ~0:50 remaining.
Work is done only in a private copy under /private/tmp/rev-t030o44 (TMPDIR ending in "/").
Finished 20:35 CEST (about 1 h 40 min). At the end: df -h / 12 GiB available; on AC power. Nothing in the worktree was created, modified, moved or deleted, and no test ran there. All copies were removed at the end.

**Summary.** 11 findings: 5 blocking (F1, F4, F9, F10, F11) and 6 minor (F2, F3, F5, F6, F7, F8).
- **Every blocking finding is one class.** Some line a reader of the rendered Markdown sees as a second, blocking tier is read as prose or hidden by both readers of finding records, so a CLEARED round seals. F1 and F4 are reproduced end to end through `round --complete`.
- **One part of F1 is a regression of this delta.** In a manifest, an autolink `<Severity:data-loss>` and a non-tag `<Severity: data-loss>` were refused by PRE and are read as prose by CUR.
- **The other blocking members predate the delta.** They sit in the new label reader's approximation of rendered text (a quoted `>` in a tag, a named reference before the label, an empty link), in the field-value reading (a value continued on the next line) and in the shared quoting tracker (`<!-->`, a `<!--` inside an attribute, a backtick fence with a backtick in its info string).
- **Round 13's reported members are closed.** Every one is refused by name, and the recorded history (tally and catalogs for 001, 002 and 003) is byte-identical to PRE.
- **The minor findings fail closed or are wording and fixture gaps.** They are over-refusal beyond the recorded consequence (F2), legacy and reality-check reach that is not stated (F3, F5), guards that no fixture isolates, confirmed by two whole-suite mutant runs at rc 0 (F6, F7), and claims broader than the code (F8).

## Findings

### F1 — blocking (a regression for two manifest members; predates for the quoted-`>` member and for the canonical pass): vf_label's HTML strip is not CommonMark's inline-HTML grammar, so a visible second tier is read as prose in both passes and a CLEARED round seals

**Mechanism.** `vf_label` (`scripts/verification-lib.sh:272-300`) deletes `<\/?[A-Za-z][A-Za-z0-9-]*[^>]*>` before reading the first word. That regex is not CommonMark 6.6's open/closing-tag production, and it errs in both directions, in each case toward "no label":
- it deletes text that renders VISIBLY: an autolink `<Severity:data-loss>` (CommonMark 6.5: scheme of 2-32 letters, `:`, no space; renders as link text `Severity:data-loss`), and a `<Severity: data-loss>` that is no tag at all (a `:` right after a tag name is not an attribute; renders literally as `<Severity: data-loss>`);
- it stops a valid tag at a `>` inside a quoted attribute value, so `<b title="a>b">Severity:</b>` leaves `b">Severity:` and the first word read is `b`.
The kit's own fixtures assert that a second tier behind inline HTML must be refused (`report_record_line_cases` rows `second-tier-behind-html` in the manifest and `behind-html` in the canonical duplicate rows). These spellings are the same member.

**Reproduction** (private copy, every `LC_*` removed, `TMPDIR=/private/tmp/rev-t030o44/tmp/`; harness `vr.sh` = `. scripts/verification-lib.sh; vf_reports <report> opponent <out> <spec>`; report = `tier_round_fixture 1 '' G-042:tier-binding:open:minor`, i.e. a CLEARED round re-recording G-042 at minor). Manifest `opponent-findings-review.md` =
`# Prior review` / `### Finding G-042` / `- **Class:** tier-binding` / `- **Severity:** minor` / LINE:

| LINE | `marked` 17.0.5 renders the item as | CUR (both LANG=C and en_US.UTF-8) | PRE |
|---|---|---|---|
| `- <b>Severity:</b> data-loss` (shipped control) | `<b>Severity:</b> data-loss` | rc 3 `a second Severity line in finding G-042` | rc 0 |
| `- <b title="a>b">Severity:</b> data-loss` | `<b title="a>b">Severity:</b> data-loss` (bold "Severity:") | **rc 0, G-042 recorded `minor`, empty stderr** | rc 0 |
| `- <Severity:data-loss>` | `<a href="Severity:data-loss">Severity:data-loss</a>` | **rc 0, minor** | rc 3 `a second Severity line in finding G-042` |
| `- <Severity: data-loss>` | `&lt;Severity: data-loss&gt;` | **rc 0, minor** | rc 3 `a second Severity line in finding G-042` |

Canonical pass, same mechanism: `record_round 1 CLEARED 0 1 '### Finding G-050' dup-binding new '- **Severity:** minor\n  - <b title="a>b">Severity:</b> data-loss'` -> CUR rc 0, G-050 recorded `minor`; the shipped `<b>` spelling -> rc 3 `a Severity line this grammar cannot read in finding G-050`. `<Severity:data-loss>` and `<Severity: data-loss>` on that nested line also give rc 0 on CUR.

**End to end** (fixture function `e2e_battr` sourced into `tests/test-spec-gate.sh` with `t_run_all` stripped, fresh SANDBOX, `make_verification_git_dir` + `floor_fixture`): floor rc 0; reserve round 1; the manifest above with the `title="a>b"` line; `record_line_report "$res" 1 CLEARED 0 1 '### Finding G-042' tier-binding open '- **Severity:** minor'` -> `round completed gate=opponent round=1 verdict=CLEARED report=f6ce2df8…`, rc 0; round 2 CLEARED 0 · 1 with new G-050 carrying `- **Severity:** minor` and `  - <b title="a>b">Severity:</b> data-loss` -> `round completed gate=opponent round=2 verdict=CLEARED report=9653434e…`, rc 0; `tally` -> `blocking=0 minor=2 … severity-downgrades=0`.

**Predates?** The `title="a>b"` member predates the delta (PRE also seals; PRE never read labels behind tags). The autolink and the `<Severity: data-loss>` literal are **regressions of this delta**: PRE's prefix skip stepped over `<` and refused both by name; CUR's strip deletes them. (A plain `- <!-- Severity: data-loss` item closed by a `-->` in a later item behaves the same way — PRE refuses, CUR reads prose — but whether it renders depends on the renderer: strict CommonMark leaves an inline comment that does not close in its paragraph as literal text, `marked` passes it through as raw HTML; held as renderer-dependent, not counted here.)

**Smallest class-wide fix.** Make the strip deny-side instead of lossy: delete only what CommonMark 6.6 renders as nothing — an open tag by its full production (attribute values `"…"`, `'…'` or unquoted, which may hold `>`), a closing tag `</name\s*>`, a complete comment, PI, declaration or CDATA — and replace an autolink by its URI text; everything else, `<` included, stays a non-letter the prefix skip steps over. In addition, return a label when EITHER reading yields one (the stripped text, or the raw text with `<` and `>` read as non-letters, as PRE did), so an error in the strip can only refuse; the union alone closes the two regressions, and the full tag production is still needed for the quoted-`>` member. Add the three rows above in both directions to `report_record_line_cases` and the canonical duplicate rows.

### F2 — minor (new with this delta; fails closed): the canonical in-finding label rule refuses ordinary prose far beyond the one consequence Decisions records

**Mechanism.** Inside a canonical finding every non-field line goes through `vf_label` (`scripts/verification-lib.sh:1564-1567`). A word Class or Severity followed by any non-letter, non-digit, non-hyphen character is a label, so a continuation line or sub-bullet whose first word is `class`/`severity` followed by `,` `.` `)` `/` `"` or `:` refuses the whole round. Decisions (2026-10-01, "the rule") and the test comment at `tests/test-gate-contracts.sh` (the `a-quoted-example` block) record only "a finding line that BEGINS with a code span holding a label".

**Reproduction** (direct `vf_reports`; `record_round 1 CHALLENGED 1 0 '### Finding G-042' tier-binding new '- **Severity:** data-loss' "<LINE>\n"`, which puts LINE after the Scenario field). Each LINE gives CUR rc 3 with `a Class line this grammar cannot read in finding G-042` or `a Severity line this grammar cannot read in finding G-042`, PRE rc 0:
- `  class, not one spelling of it.` (a wrapped Scenario/Wrong-behavior value; this spec's own prose says "the class stays open")
- `  (class) line outside any Finding in both locales.` (a verbatim wrapped line from `t030o43-review4.md:91`)
- `  - Severity: unchanged from round 12.`
- `  - Class, Status and Prior are unchanged.`
- `  - "Severity" here is the tier the count reads.`
- `  - Severity/Class binding held.`

A survey with the kernel's own `vf_label` over this spec's reviewer reports (`reports/opponent-round*.md`, `reports/*review*.md`) finds 14 such lines in agent-written prose about this very subject: 10 begin with a code span (the recorded consequence) and 4 do not (`t030o43-review.md:104` `class: add every positive POSIX class…`, `t030o43-review2.md:101` `- Severity: …`, `t030o43-review3.md:17` `(`- **Class:** …` …`, `t030o43-review4.md:91` `(class) line outside …`). None occurs inside a finding of the recorded history (my survey over 001/002/003 `notes/opponent.md` and `notes/reality-check.md` found 0 non-field label lines, and `tally` for 001/002/003 is byte-identical CUR vs PRE under C and en_US.UTF-8: 001 rc 3, 002 rc 0, 003 rc 0 at `opponent rounds=13 … blocking=27 minor=11 locations=388`).

**Predates?** No: PRE read every such line as prose; the rule is new. It fails closed with a named diagnostic, so minor — but a refused `round --complete` on an agent's verbatim report costs a re-dispatch, so the recorded extent should say so.

**Smallest class-wide fix.** Record the consequence at its real extent (Decisions and the fixture comment: "any line inside a finding whose first rendered word is Class or Severity followed by punctuation is refused"), and tell the report's author (`agents/opponent.agent.md`) not to begin a line inside a finding with those words. This is the smaller and safer fix, because the refusal is the deny side. Narrowing the rule to the shape a reader takes as a field (an emphasis-closed label, or the word followed by a colon or dash separator) would stop refusing `class,`, `(class)` and `"Severity"` while still refusing every fixture row (`<b>Severity:</b>`, `&#83;everity:`, `#### Severity:`, `&#x43;lass:`). But it would also let `- Severity, data-loss` through as prose, so it needs its own measurement first. Either way, add the six lines above as fixture rows, as named refusals or as positives.

### F3 — minor (wording; new with this delta): the duplicate-key change is not gated on canonical rounds, contrary to the Acceptance and the Decisions rule entry (the contract scopes it to "a canonical report" and is silent on legacy)

The task block's Acceptance and the 2026-10-01 rule entry say "These rules apply to canonical rounds before the completion marker, so legacy rounds and the after-marker refusal are unchanged", listing the label-keyed duplicate among "these rules". The code change `sub(/^[ ]*/,"",key)` (`scripts/verification-lib.sh:1571`) sits in the style-agnostic `fid && /^[ ]*- \*\*(…):\*\*/` rule, so it applies to legacy rounds.

**Reproduction.** Legacy report `# Opponent review` / `**Round:** 1` / `**Date:** 2026-07-20` / `**Verdict:** CHALLENGED` / `1. **A defect** — *severity:* wrong-result` / `   - **Scenario:** x` / ``   - **Where:** `a.sh:1` `` / ``     - **Where:** `b.sh:2` ``: CUR rc 3 `opponent.md:10: duplicate finding field`; PRE rc 0 (catalog `legacy-1-1 … `b.sh:2``). The recorded 001/002 legacy rounds are unaffected (tallies identical, above).

**Predates?** No. Fails closed. **Fix:** either gate the key normalisation on `style=="canonical"` or (better, since a legacy last-wins Where is no better) change the Acceptance/Decisions wording to "the duplicate-field key ignores indentation in every round; the other new rules apply to canonical rounds before the marker", and add the legacy row above as a fixture.

### F4 — blocking (predates the delta; unchanged code the delta's rule relies on): `<!-->` and `<!--->` open a multi-line comment in the quoting tracker, though they are complete empty comments, so a VISIBLE canonical `- **Severity:**` line is hidden and a CLEARED round seals

**Mechanism.** CommonMark 0.31.2 (6.6 and HTML-block condition 2, whose end condition is a line containing `-->`) and the HTML5 parser both treat `<!-->` and `<!--->` as complete, empty comments. `vf_comment` (`scripts/verification-lib.sh:149-193`) looks for the closer only after the four-character opener (`i += 4`, then `index(substr(s, i), "-->")`), so it never sees the `-->` that the opener itself ends with, sets `commented`, and `vf_quoted` suppresses every following line until some later `-->`. `vf_label`'s own strip has the same off-by-two (`index(substr(s, i + 4), "-->")`, `:273-276`). The delta's rule ("a tier the pass does not read, a quoted one included, is refused with its finding") closes this for a manifest finding whose ONLY tier is hidden, but not for a second tier, and the canonical pass hides the line outright.

**Reproduction, end to end** (fixture function sourced into `tests/test-spec-gate.sh` with `t_run_all` stripped, fresh SANDBOX, `make_verification_git_dir` + `floor_fixture`; floor rc 0; reserve rc 0): report `record_line_report "$res" 1 CLEARED 0 1 '### Finding G-050' dup-binding new '- **Severity:** minor\n\n<!-->\n\n- **Severity:** data-loss\n\nThe tier above is the one we stand by. -->'` -> `round completed gate=opponent round=1 verdict=CLEARED report=7cd392ed…`, rc 0; `tally` -> `blocking=0 minor=1 … severity-downgrades=0`. `marked` 17.0.5 renders the finding with BOTH `<li><strong>Severity:</strong> minor</li>` and, after the raw `<!-->` line, `<li><strong>Severity:</strong> data-loss</li>` — the data-loss line is a canonical field line a reader sees, written in the canonical spelling. Direct `vf_reports` gives rc 0 with G-050 at `minor` on CUR and on PRE; `<!--->` gives the same. Manifest form (`### Finding G-042` / Class / `- **Severity:** minor` / blank / `<!-->` / blank / `- **Severity:** data-loss` / blank / `Notes end here. -->`, CLEARED round re-recording G-042 at minor): rc 0 on CUR and PRE, G-042 recorded `minor`.

**Predates?** Yes (PRE identical). It is not in the known list (no `<!-->` in STATUS, tasks, the contract or any receipt), and the delta's comment ("a quoted one included") and contract text imply quoted tiers can no longer pass, which holds only for a finding's sole tier.

**A sibling: an opener inside an attribute value.** `vf_comment` opens on a `<!--` inside a quoted attribute value. Canonical G-050 with `- **Severity:** minor`, `- <b title="<!--">Note</b> the tier below.`, `- **Severity:** data-loss`, `- That is the tier. -->` under CLEARED 0 · 1: CUR and PRE rc 0, G-050 at `minor`; `marked` renders all four items, the data-loss one as `<li><strong>Severity:</strong> data-loss</li>`.

**A sibling: a fence the renderer does not open.** CommonMark 4.5: a backtick fence's info string may not contain a backtick, so ```` ```x`y ```` is paragraph text, but `vf_fence` (`:116-131`) opens a fence on any run of three backticks. Canonical G-050 with `- **Severity:** minor`, then ```` ```x`y ````, `  - **Severity:** data-loss`, ````    ``` ```` (three spaces): CUR and PRE rc 0, G-050 at minor; `marked` shows `<p>```x`y</p>` and the data-loss item as a visible bullet (it then renders the rest of the finding as a code block, so this one is visible damage to a careful reader; F4's `<!-->` form leaves no trace beyond a stray `-->`).

**Smallest class-wide fix.** In `vf_comment` and in `vf_label`'s strip, start the closer search at the opener's third character (`index(substr(s, i + 2), "-->")` with the matching offset), so `<!-->` and `<!--->` close on their own line as both specifications say; add both spellings as fixture rows (manifest second tier, canonical second tier, and a plain line after them that must be read). Class-wide, the quoting tracker should be checked against every HTML-block and inline-HTML end condition, the fence opener's own conditions (a backtick fence's info string holds no backtick), and inline context (a `<!--` inside a tag's quoted attribute value, like one inside a code span, opens nothing), not only the opener spellings, since a tracker that stays open longer than the renderer hides exactly the lines the record readers rely on.

### F5 — minor (new with this delta; fails closed; not stated anywhere): the canonical "field line outside any Finding" rule also refuses reality-check reports, whose template has no Finding sections at all

The rule (`scripts/verification-lib.sh:1563`) is gated on `style=="canonical"` only, not on the gate, so it applies to every canonical `notes/reality-check.md` round. The reality-check template (`agents/reality-check.agent.md:104-139`) writes gaps as numbered items whose detail is free-form ("which AC it blocks … Reference file paths"); a sub-bullet in the canonical bold-label spelling is now a refusal.

**Reproduction** (direct `vf_reports … reality-check …`, LC_ALL=C): a canonical reality-check round exactly in the template's shape (Summary, AC matrix with one row, Constitution check, Gaps, Re-run conditions, marker) whose gap item `1. **AC-001 evidence missing** — the capture is stale.` carries `   - **Where:** scripts/run.sh:9` and `   - **Blocks:** AC-001` -> CUR rc 3 `reality-check.md:26: a finding field outside any Finding` and `:27: …`; PRE rc 0. 003's one canonical reality-check round is unaffected (tally identical). The canonical Finding-heading refusal reaches the same reports, since an AC ID is ID-shaped: the same round with `#### Finding AC-001 unsupported` under its Gaps heading (and no bold field bullets) gives CUR rc 3 `reality-check.md:25: a Finding heading this grammar cannot read`, PRE rc 0. (`### Finding AC-001 …` was already read as a canonical finding opener, and is refused as incomplete on both.) Neither the task block, the Decisions rule entry nor the measurement (which surveyed "56 findings in 003's 13 rounds", the opponent gate) mentions the reality-check gate; the brief's question "Are reality-check reports affected?" is answered yes.

**Predates?** No. **Fix:** gate the outside-a-finding rule (and, for symmetry, the in-finding label rule) on the gates whose reports carry findings — or record in the contract that a reality-check report may not use the canonical finding field spelling outside a `### Finding` section, and add the row above as a fixture either way.

### F6 — minor (fixtures; new with this delta): the five `style=="canonical"` conjuncts that carry the "legacy rounds are unchanged" claim are not mutation-isolated

The Acceptance says "removing any guard fails a fixture" and "These rules apply to canonical rounds … so legacy rounds … are unchanged". Each new canonical rule carries a `style=="canonical"` conjunct (`scripts/verification-lib.sh:1536`, `:1537`, `:1541`, `:1563`, `:1564`). No fixture writes a legacy round that reaches them: the only legacy reports any fixture reads are shipped 002's five rounds (`shipped_002_tally_case`), which contain none of the triggering shapes, and the `legacy` after-marker row (`tests/test-spec-gate.sh:1019`) is a line after a canonical marker, not a legacy round.

**Reproduction.** Literal once-only mutants in a third private copy, each restored byte-identically (`cmp`), judged with `report_record_line_cases` and `shipped_002_tally_case` (t_run_all stripped, fresh SANDBOX):
- MA `style=="canonical" && !ended && !fid && /` -> `!ended && !fid && /` (outside-a-finding rule): both functions rc 0, SURVIVED.
- MB `style=="canonical" && fid && !/^[ ]*- \*\*(` -> `fid && !/…` (in-finding label rule): SURVIVED.
- MC `style=="canonical" && !ended && /^ ? ? ?#+` -> `!ended && /^ ? ? ?#+` (Finding-heading refusal): SURVIVED.
- MD `style=="canonical" && fid && /^ ? ? ?(#|##|###)` -> `fid && /…` (close at `###`): SURVIVED.
- ME `style=="canonical" && !ended && !/^ ? ? ?#+([ \t]|$)/ && …` -> without `style=="canonical" && ` (non-heading `#`-run Finding refusal, `:1537`): on the legacy report `# Opponent review` / Round / Date / Verdict / `1. **A defect** — *severity:* wrong-result` / ``   - **Where:** `a.sh:1` `` / `\302\240### Finding G-1`, CUR rc 0 and ME rc 3 `:9: a Finding heading this grammar cannot read`.
Each mutant does change a legacy round: on a legacy report (`# Opponent review`, Round/Date/Verdict, `## What I attacked` with `- **Scenario:** …`, `1. **A defect** — *severity:* wrong-result`, `   - **Where:** \`a.sh:1\``, `   - Severity, as above.`, `#### Finding G-1`, `### Notes`, `   - **Blocks:** AC-001`) CUR gives rc 0 (catalog `legacy-1-1 … Blocks=AC-001`); MA gives rc 3 `:9: a finding field outside any Finding`, MB rc 3 `:13: a Severity line this grammar cannot read in finding legacy-1-1`, MC rc 3 `:15: a Finding heading this grammar cannot read`, MD rc 0 with the finding's Blocks field lost. **Whole suite, confirmed:** with all five conjuncts deleted at once (MA to ME, committed in the mutation copy), `TMPDIR=<copy>/tmp/ bash tests/run.sh` exits 0, 15 suites, 147 tests ok, 18:13:56Z to 18:33:59Z, and the copy's status is clean afterwards. MA, MB, MC and ME only add refusals on legacy rounds, so they survive one by one as well. MD alone drops a legacy field instead, but with MA also applied that same line is refused, so a fixture that caught MD alone would have failed the combined run too.

**Also un-isolated, same class:** MM4, deleting the comment-strip loop of `vf_label` (`:273-276`), SURVIVES `report_record_line_cases` (rc 0), because the `inline-comment` row `- <!-- tier --> Severity: data-loss` is also stripped by the `<[?!][^>]*>` alternative. The loop matters: manifest `### Finding G-042` / Class / `- **Severity:** minor` / `- <!-- a>b --> Severity: data-loss` under the CLEARED minor round gives CUR rc 3 `manifest line 6: a second Severity line in finding G-042`, MM4 rc 0 with G-042 at minor. (Killed as expected, for contrast: MM1 deleting the `no readable Severity` check, MM2 `if (id == "" || hl <= flevel)` -> `if (1)`, MM5 disabling the reference decode.)

**Predates?** No. **Fix:** add one legacy-round positive (the report above, or a copy of a shipped 002 round with those four lines appended) asserting rc 0 and its catalog fields, in `report_record_line_cases`, and a comment-with-`>` row (the MM4 line above) in both passes.

### F7 — minor (fixtures; caused by this delta): the new Severity requirement makes four shipped manifest guards un-isolated, because the T030o43 `refuse` rows assert only the generic `prior-review manifest could not be parsed`

**Mechanism.** The shapes table in `report_manifest_locale_cases` (`tests/test-gate-contracts.sh:1012-1093`) asserts rc 3 and the generic `prior-review manifest could not be parsed` for every `refuse` row (method 4 asks for exact diagnostics). Several rows hold a G-041 written with a Class alone (`fence-left-open`, `comment-left-open`, `raw-block-left-open`, `no-class-beside-another`). Under this delta each of those G-041s is ALSO refused as `finding G-041 has no readable Severity`, so the row passes whether or not the guard it exists for still runs. The delta added a Severity line to 13 other Class-only manifests, but not to these rows.

**Reproduction.** Literal once-only mutants, restored byte-identically (`cmp`), judged with `report_manifest_locale_cases` and `report_record_line_cases`:

| mutant (deleted line in the manifest pass) | CUR | PRE (same mutant, PRE kernel and PRE tests) |
|---|---|---|
| MX1 `if (fenced) bad("a code fence is left open")` | both rc 0, SURVIVED | rc 1, KILLED (`expected exit 3, got 0`) |
| MX2 `if (commented) bad("an HTML comment is left open")` | SURVIVED | KILLED |
| MX3 `if (rawkind) bad("a raw HTML block is left open")` | SURVIVED | KILLED |
| MX4 `if(id!="" && cls=="") bad("finding " id " has no readable Class")` | SURVIVED | KILLED |

No other fixture asserts any of these four diagnostics (`grep -n 'left open\|has no readable Class' tests/*.sh` finds none). **Whole suite, confirmed:** with all four lines deleted at once (committed in the mutation copy so its status was clean), `TMPDIR=<copy>/tmp/ bash tests/run.sh` exits 0, 15 suites, 147 tests ok, 17:51:32Z to 18:13:20Z, and the copy's `git status --porcelain --ignored` is empty afterwards. Each deletion only loosens the pass, so the combined mutant surviving means each one survives on its own.

**Predates?** The generic assertion predates; the loss of isolation is caused by this delta. **Smallest fix:** give each Class-only G-041 in that table a `- **Severity:** minor` line, as the delta did for the other 13 manifests, and replace the `refuse` column with the exact expected diagnostic per row, so a refusal from another rule can no longer satisfy a row.

### F8 — minor (wording): the contract, the kernel comments and the Acceptance say more than the code and the fixtures do

1. **A recorded-open item stated as closed.** `templates/verification-contract.md:356-357`: "A field line, in a manifest or in a canonical report, is decided by its label, read from the line's rendered text". In the canonical pass only Class and Severity are label-read (`vf_label($0, "class severity")`, `scripts/verification-lib.sh:1565`); Status, Prior, Where and the other fields are still decided by spelling (`^[ ]*- \*\*(…):\*\*`), which is the KNOWN item "Status, Prior and the other canonical fields not label-checked" (brief's known list; Decisions 2026-10-01 rule entry). The contract sentence reads as if that item were closed. Fix: "A Class or Severity line, in a manifest or in a canonical report, …".
2. **"Inline raw HTML renders as nothing."** Contract `:357-358`, kernel comment `:255-258`, Acceptance, Decisions (1): the strip deletes autolinks and non-tags and mis-ends tags with a quoted `>` (F1). Fix with F1, or say "text matching `<name …>`, `</name>`, `<?…>`, `<!…>` and `<!--…-->` is dropped".
3. **What the first word follows.** Contract `:358-359` says "the first word after any indentation, heading marker, list marker or emphasis"; the code (and the kernel comment, correctly) skips any run of non-letter, non-digit characters — quotes, parentheses, backticks, `[`, `<`, `/` — which is where F2's refusals come from. Fix: use the kernel comment's wording in the contract.
4. **"Fixtures cover every reproduced member … directly and end to end … under `LANG=C` and `LANG=en_US.UTF-8`."** Not met as written. Reproduced members with no fixture row anywhere in `tests/` (literal `grep -F`): `#### **Severity:** data-loss`, `#### Severity — data-loss`, `<strong>`/`<em>`/`<span>` labels, Severity headings at levels 5 and 6 (one with closing hashes), the heading-body form under `## Finding`, and `##### Finding G-042`. End to end (`round_record_line_cases`), the heading-body form is not run at all, and the O-019 completion (`tests/test-spec-gate.sh:837`) and the indented-duplicate completion (`:841`) run without `in_locale`, i.e. under the suite's exported `LC_ALL=C` only (`tests/helpers.sh:27`). The mechanisms are covered by sibling rows, so this is a claim-scope fix: either add the rows or say "every mechanism … with one or more spellings each".
5. **"Removing any guard fails a fixture"** (Acceptance) — not met; see F6 (five `style=="canonical"` conjuncts, the comment-strip loop) and F7 (four manifest guards masked by the new rule).
6. **"Legacy rounds … are unchanged"** — see F3. **"A finding line that BEGINS with a code span holding a label"** as the stated consequence — see F2.

### F9 — blocking (predates the delta; adjacent to, but not the same as, the known named-reference item): a NAMED character reference in front of the label is read as the first word, so `- &nbsp;**Severity:** data-loss` is prose to both passes while `- &#160;…` is refused

**Mechanism.** `vf_label` decodes numeric references only (`:278-282`). A named reference before the label (`&nbsp;`, `&ensp;`, `&emsp;`, `&thinsp;`, `&lpar;`, `&quot;` …) is left as `&name;`; the prefix skip steps over `&` and stops at the entity name, which becomes "the first word". The rendered first word is the label. The known item is "a label written with a named character reference" (the label's own letters or separator); this is a reference in the PREFIX, which the rule's own text ("the first word after any run of characters that are not letters or digits") says is skipped.

**Reproduction** (direct `vf_reports`, CLEARED round re-recording G-042 at minor; manifest `### Finding G-042` / `- **Class:** tier-binding` / `- **Severity:** minor` / LINE):
- LINE `- &nbsp;Severity: data-loss` -> CUR rc 0, G-042 `minor`; PRE rc 0.
- LINE `- &ensp;**Severity:** data-loss` -> CUR rc 0, `minor`; PRE rc 0. `marked` renders `<li>&ensp;<strong>Severity:</strong> data-loss</li>`.
- LINE `- &#160;Severity: data-loss` (control, numeric) -> CUR rc 3 `manifest line 6: a second Severity line in finding G-042`.
- Canonical: `record_round 1 CLEARED 0 1 '### Finding G-050' dup-binding new '- **Severity:** minor\n  - &nbsp;**Severity:** data-loss'` -> CUR rc 0, G-050 recorded `minor` (the `<b>` and `&#83;` siblings are refused by the shipped rows).

**Predates?** Yes (PRE reads both as prose too); the delta's numeric decoding makes the two spellings of the same rendered line disagree.

**Smallest class-wide fix.** In `vf_label`, after decoding numeric references, replace every named reference `&[A-Za-z][A-Za-z0-9]*;` by the non-letter placeholder `\001`. No HTML5 named reference renders as an ASCII letter or digit, so this is exact for the prefix skip and needs no entity table; a label whose own letters are written as references then remains the known item, and the separator case (`Severity&colon;`) is closed with it. Add the three LINEs above as rows in both passes.

### F10 — blocking (predates the delta): a Class or Severity value continued on the next line (a lazy paragraph continuation) is ignored by both passes, so the rendered field `Severity: minor data-loss` is read as `minor`

**Mechanism.** Both passes take a field's value from its own line only (manifest `value()`, `:1278`; canonical `v=value(vf_original)`, `:1573`, with `value()` at `:1344`) and read the next line as an unrelated line. In CommonMark a non-blank line that is not a list item, heading, fence, quote or HTML start continues the list item's paragraph (lazy continuation), so it renders as part of the field's value. The continuation `  data-loss` has no label, so neither the manifest classifier nor the new in-finding rule sees it. The kernel comment's own grammar is "a value of its grammar, which is the text after that label and nothing further (R3-F1); anything else is refused by name".

**Reproduction** (direct `vf_reports`, every `LC_*` removed):
- Canonical: `record_round 1 CLEARED 0 1 '### Finding G-050' dup-binding new '- **Severity:** minor\n  data-loss'` -> CUR rc 0, G-050 recorded `minor`; PRE rc 0. `marked` renders `<li><strong>Severity:</strong> minor\ndata-loss</li>`, displayed "Severity: minor data-loss".
- Manifest: `### Finding G-042` / `- **Class:** tier-binding` / `- **Severity:** minor` / `  data-loss`, under the CLEARED round re-recording G-042 at minor -> CUR rc 0, G-042 `minor`.
(`round --complete` reads through the same `vf_reports`, as F1 and F4 show end to end.)

**Recorded history.** No canonical field line in 003's 13 rounds is followed by a lazy continuation line (awk survey over `notes/opponent.md`: 0), so a refusal costs nothing recorded.

**Predates?** Yes. **Smallest class-wide fix.** In both passes, after a Class or Severity field line, refuse by name a following non-blank line that would continue its paragraph (not blank, not a list item, heading, fence, blockquote or HTML-block start), e.g. `a Severity value continued on the next line in finding <ID>`; add both shapes as rows. (Applying the same rule to every canonical field would also close the value half of the known "other fields not label-checked" item, but only Class and Severity are needed here.)

Locale note for F1, F4, F9, F10 and F11: every direct member above was re-run with every `LC_*` removed under `LANG=en_US.UTF-8` as well as `LANG=C`, with identical exit codes and catalogs.

### F11 — blocking (predates the delta; the same rendered-text gap as F1, through link syntax): a label after an empty link or image is read as the link destination's first word, so `- [](x)**Severity:** data-loss` is prose to both passes

**Mechanism.** `vf_label` approximates the rendered text by stripping inline HTML and decoding numeric references, and then skips non-letters. A link destination or title (`[](x)`, `[](#a "t")`, `![](img.png)`) renders as nothing visible, but its letters stop the prefix skip, so "the first word" is `x` or `a`.

**Reproduction** (direct `vf_reports`; manifest `### Finding G-042` / `- **Class:** tier-binding` / `- **Severity:** minor` / LINE, under the CLEARED round re-recording G-042 at minor):
- LINE `- [](x)**Severity:** data-loss` gives CUR rc 0 with G-042 at `minor`, and PRE rc 0. `marked` renders `<li><a href="x"></a><strong>Severity:</strong> data-loss</li>`.
- LINE `- [](#a "t")Severity: data-loss` gives CUR rc 0, `minor`, and PRE rc 0. `marked` renders `<li><a href="#a" title="t"></a>Severity: data-loss</li>`.
- Canonical: `record_round 1 CLEARED 0 1 '### Finding G-050' dup-binding new '- **Severity:** minor\n  - [](x)**Severity:** data-loss'` gives CUR rc 0, with G-050 recorded at `minor`.

**Predates?** Yes. **Smallest class-wide fix:** with F1's fix, drop link and image destinations and reference labels before the prefix skip (`](…)` -> `]`, `][…]` -> `]`). Better still, as in F1, return a label when any of the readings yields one, so text that renders invisibly can only make a line refuse. Add both LINEs as rows in both passes.

## Held

- **Identity of what I reviewed.** My copy is the worktree's `git ls-files -z --cached --others --exclude-standard` enumeration (built with `GIT_OPTIONAL_LOCKS=0`), its own git repository. Its four delta files hash as `t030o44-edits/post-apply-2.sha256`. PRE was rebuilt by reversing `t030o44-session2.diff` and then `t030o44-session1.diff` (`patch -R -p1`, both rc 0, no rejects); its four files hash as `t030o44-edits/pre-apply.sha256` (all OK).
- **Recorded history.** `spec-gate.sh tally` for 001, 002 and 003 is byte-identical between CUR and PRE under `LANG=C` and `LANG=en_US.UTF-8` with every `LC_*` removed: 001 rc 3, 002 rc 0, and 003 rc 0 at `opponent rounds=13 reality-check rounds=1 blocking=27 minor=11 locations=388 unclassified=0 … severity-downgrades=5`. The `vf_reports` catalogs and diagnostics for the opponent and reality-check reports of 001, 002 and 003 are byte-identical CUR vs PRE (001 opponent rc 3 on both, same stderr). The real 2026-09-09 manifest parses (it is read by 003's tally).
- **Round 13's reported members.** All are refused by name on CUR, as the fixtures assert. `report_record_line_cases` gives rc 0 with 83 assertions executed, and `round_record_line_cases` gives rc 0. Both ran on macOS bash 3.2 with BWK awk, and again in a throwaway Linux container: the local `ghcr.io/cargo-lambda/cargo-lambda:latest` image, `--rm --network none`, uid 1000, the copy mounted read-only and copied into a tmpfs, nothing pulled, no other container touched, and Docker not restarted. Its tools were mawk 1.3.4 20250131, bash 5.2.37 and git 2.47.3. There `report_record_line_cases`, `round_record_line_cases` and `report_manifest_locale_cases` each gave rc 0. That image has no en_US.UTF-8, so the locale half there is only nominal. The invoker's dev4 whole-suite runs of the final tree finished at rc 0 both ways (`t030o44-dev4-{full,full-locale}.{log,rc}`, 15 suites, ShellCheck clean).
- **Session 2's equivalence argument holds.** The only ATX headings that reach the non-heading `#`-run rule are the deeper headings that fall through inside a finding. Those are exactly the lines session 1 flagged `subheading=1`, and the catch-all cleared that flag on the same line, so it never carried over to the next one. The two `flevel=0` assignments were dead, because `flevel` is read only while `id != ""`, and `id` is set only together with `flevel`.
- **The manifest pass's outside rule, `idseen` and `flevel`.** I checked them after a refused Finding heading, at END, and across nested and sibling findings. I found no silent drop of a finding or of a Class binding. Every canonical field line outside a finding is refused whatever `idseen` holds, so a dropped finding needs every field in a non-canonical spelling, which is the recorded O-004 extent.
- **The canonical pass's close at `###`.** It does not change `need()` or `secbody`: the close rule does not `next`, so the section rule still runs on that heading. The after-marker refusal survives for a field line and for a Finding-like heading.
- **Mutants killed as expected.** Each was a literal once-only edit, restored byte-identically (`cmp`):
  - MM1, the manifest `no readable Severity` check deleted;
  - MM2, the heading fall-through replaced by `if (1)`;
  - MM5, the numeric reference decode disabled;
  - MC1, the duplicate key's indentation strip deleted;
  - MC2, the `###` close deleted;
  - MC3, `!ended` dropped from the outside-a-finding rule;
  - MC4, `!ended` dropped from the canonical Finding-heading refusal.

  Each of these gives `report_record_line_cases` rc 1 with that row's own diagnostic missing.
- **The 13 manifests that gained a Severity line still test their subject.** Each asserts its specific diagnostic, either the O-042 resolved-claim refusal or the Class-drift refusal. A broken quoting tracker would expose the Class-only O-042 inside the fence, comment or `<script>`, and the resulting manifest refusal would still fail the specific assertion.
- **Converting `class-only` into a refusal is justified.** Under the rule, an absent tier cannot be told apart from a dropped one. The real manifest carries a Severity on all six findings, and no README, template, agent or skill shows a manifest example; the only text is the contract prose at `:340`.
- **Positives.** The new positives and the plausible-manifest shapes (`trailing-section`, `summary-with-subsection`, `class-binding-lead-in`, the canonical `a-*` rows and the Held-up `- Severity: all blocking` line) are not attacks asserted at rc 0. Each places the label outside any finding, or as prose that is no tier.
- **Recorded extent, not counted.** A label heading at the Finding heading's own level right after a finding (`### Severity: data-loss` after `### Finding G-042`) is prose to both passes on CUR and on PRE. I take this to be the "recorded same-level extent" that O-019 names.
- **Real reports as plausible manifests.** I used each of this spec's 12 returned round reports (`reports/opponent-round{2,3,4,5,6,8,9,10,11,12,13}.md` and `opponent-round3-reconcile.md`) as a prior-review manifest under the CLEARED fixture round. Each parses (rc 0) on both CUR and PRE. The eight round briefs are refused on both, since they are not manifests. So the new Severity requirement and the deeper-heading rule do not refuse any real finding text this project has written.

## Not reached

- **A strict CommonMark renderer.** None is on disk: there is no cmark, cmark-gfm, commonmark.js or markdown-it. My rendering evidence is the CommonMark 0.31.2 and HTML5 rules as cited, plus `marked` 17.0.5 (`~/.cache/codex-runtimes/.../node_modules/marked`), which is not strictly CommonMark. One case is held for that reason: an inline `<!--` that does not close inside its own paragraph but is closed by a `-->` in a later block. PRE refuses it as a second manifest tier and CUR reads it as prose; strict CommonMark shows it, while `marked` passes it through raw.
- **Whole-suite mutation runs.** I made only the two combined runs described under F6 and F7. Every other mutant was judged with targeted fixture functions only. I did not run my own unmutated whole suite; the invoker's dev4 runs cover that.
- **ShellCheck, hosted CI and the Linux whole suite.** None was run by me. My Linux run covered three fixture functions only, under C, because the image has no en_US.UTF-8.
- **Other readers that share the quoting tracker.** I did not examine how F4's `<!-->` and fence divergences affect the authorization scanner, the Decisions view, the AC and binding catalogs, or `vf_report_block`'s sealed digest. Both of the readers I checked hide the same lines.
- **GFM extensions.** I did not examine footnotes, tables with the tier in a non-first cell (which are close to the known table-finding item), task-list edge cases, or setext headings as section closers.
- **Umbrella and multi-repo roots; EUC-JP, GB18030 and Big5.**
- **The mutation matrix of record and the invoker's `o018-measure` itself.** I read their results and did not re-run them.

REVIEW COMPLETE
