# Focused review 4 — T030o43 session-9 delta (review-3 repairs)

Status: COMPLETE (2026-09-30 11:21-12:00 CEST)

Reviewer: independent, read-only. Private copy at /private/tmp/rev4-t030o43 (removed at end). The two drivers,
`man.sh` and `e2e.sh`, are kept in `rev4-repro/` beside this report; they hard-code the removed copy
(`/private/tmp/rev4-t030o43/{kit,rv}`, TMPDIR under it): rebuild `kit` from the worktree enumeration and `rv` as
`kit`'s scripts/, templates/ and tests/ with REVIEWED_DIR laid over.

## Findings

Method for manifest cases: `man.sh <kit> <label> <manifest %b body>` (review 3's `t030o43-review3-repro/man.sh`
with my paths). It writes a spec whose `notes/opponent.md` is the suite's `tier_round_fixture 1 ''
G-042:tier-binding:open:minor` (a canonical CLEARED round recording G-042 open at `minor`), writes the manifest
`notes/verification/reports/opponent-findings-review.md`, and runs `vf_reports <report> opponent <out> <spec>` under
`LANG=C` and `LANG=en_US.UTF-8` with every `LC_*` removed. `kit` = my copy of the live worktree enumeration
(session-9 state; the 8 delta files `cmp`-equal to the worktree); `rv` = the same copy's scripts/templates/tests with
REVIEWED_DIR laid over (I checked `patch -p1` of `t030o43-session9.diff` onto REVIEWED_DIR gives all 13 files
`cmp`-equal to `kit`). Control (canonical manifest `- **Class:** tier-binding` / `- **Severity:** data-loss`): rc=3
`clearing verdict rests on 1 lowered severity tier(s) of known findings` in both kits and both locales.

### R4-F1 (blocking: regression toward a pass, reproduced): a sub-heading inside a finding ends it, and since session 9 a non-canonical Severity line under that sub-heading is prose, so the finding is kept Class-only and its tier is dropped in silence

The R3-F5 repair made a Class/Severity line outside any finding prose "until a finding ID appears after the last
heading". Every heading resets that state (`idseen=(heading ~ /ID/)`), and every heading closes the open finding. So
a finding with a sub-section heading (`#### Assessment`, a heading of no ID) is closed there, and its tier line
below it is outside any finding with no ID after the last heading: prose. The Class line above the sub-heading keeps
the finding as Class-only (accepted), so G-042's manifest tier is absent and the CLEARED round that lowers G-042 to
minor seals. REVIEWED_DIR refused every such line by name (`a severity line outside any Finding`). Only the one strict
spelling `- **Severity:** ...` is still refused under the sub-heading.

    H='# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n\n#### Assessment\n'
    man.sh kit subhead-unbolded        "${H}\nSeverity: data-loss\n"     kit: rc=0 (C and en_US.UTF-8), no output
    man.sh kit subhead-bullet-unbolded "${H}- Severity: data-loss\n"     kit: rc=0 (both)
    man.sh kit subhead-star-bullet     "${H}* **Severity:** data-loss\n" kit: rc=0 (both)
    man.sh kit subhead-bold-colon-out  "${H}- **Severity**: data-loss\n" kit: rc=0 (both)
      rv, each of the four: rc=3 manifest line N: a severity line outside any Finding: <the line> (both locales)
    man.sh kit subhead-strict          "${H}- **Severity:** data-loss\n" kit and rv: rc=3 a severity line outside any Finding

Why it is a wrong result, not only a stylistic spelling: the contract and the comment say the pass "reads by the
canonical finding's own field grammar", and the canonical parser does NOT end a finding at a section heading
(`/^#+[ ]/` only sets `cursec`; fields keep attaching to `fid` until the next `### Finding`, round or marker). So in
the canonical grammar that Severity belongs to G-042, and the R3-F5 correction's premise ("only a finding's record
can carry a Class or a tier") is exactly what the sub-heading breaks: the record continues, the pass's state does
not. The same three non-strict spellings directly under the Finding heading are refused (`a Severity line this
grammar cannot read`), so the sub-heading is the only thing that turns a refusal into silence.

Measured against the recorded history: over every `notes/*.md` of 001, 002, 003 and the real 003 manifest, no heading
deeper than a Finding heading appears inside a finding (0 hits, awk scan in this report's method), and review 3's /
measure-9's field-rule scan found no recorded non-canonical Class/Severity line at all, so the fix below changes no
recorded parse.

Smallest class-wide fix: a heading ends the "prose until an ID" state only when it is not a sub-section of the finding
it closes: at a heading, `idseen = (heading has an ID) || (level(heading) > level(last Finding heading), with no
heading at or above that level since)` (keep the level of the Finding heading when it opens and forget it at the
next heading at or above that level; the measured code is below). R3-F5's two fixtures still parse (`## Summary` after `###`
findings is shallower; the introduction precedes every finding). Faithful to the canonical grammar, and equivalent in
outcome, is to not close a finding at a deeper heading at all (its fields then attach, and a second or non-canonical
one is refused by the inside rules). Add the four rows above as `refuse` shapes. (A same-level non-Finding heading,
`### Assessment` under `### Finding G-042`, is the ambiguous remainder: the canonical parser still attaches the field
there; closing that too needs "not shallower" instead of "deeper", which refuses summary prose under same-level
`## Summary` after `## Finding` headings, as REVIEWED_DIR did.)

Second member, same mechanism (the ID condition does not see a Finding heading whose ID it cannot read): the R3-F5
correction argues that a heading the pass does not open, combined with unbolded fields, is refused "because only a
finding's record can carry a Class or a tier". A Finding heading whose ID uses a non-ASCII hyphen (U+2011, as copied
from rendered text) is not ID-shaped to `[A-Za-z][A-Za-z0-9]*-[0-9]`, so it opens nothing and sets no `idseen`, and
its unbolded fields are prose:

    man.sh kit nbhyphen-unbolded '# P\n\n### Finding G\342\200\221042\n- Class: tier-binding\n- Severity: data-loss\n'
      kit: rc=0 (C and en_US.UTF-8)
      rv:  rc=3 manifest line 4: a class line outside any Finding: - Class: tier-binding (both)
    (with `- **Class:**` / `- **Severity:**` lines both kits refuse: a class line outside any Finding)

Fix for this member, in the same place: a heading whose second word is `Finding` (any case) sets `idseen` whatever
its third word, since that heading announces a finding record. `## Finding summary` followed by prose `Severity:` is
then refused (REVIEWED_DIR's behaviour); no recorded file has such a prose line (review 3's and measure-9's
field-rule scans: 0 non-canonical candidates), and the `finding-summary` fixture's Severity is fenced.

Both member fixes MEASURED in my copy (then restored, `cmp`-identical to the worktree file). The heading rule became:

    flushm(); heading=$0; sub(/^ +/, "", heading); split(heading, word, /[[:space:]]+/)
    hl=match(heading, /[^#]/); hl=(hl ? hl-1 : length(heading))
    if (tolower(word[2]) == "finding" && word[3] ~ /^[A-Za-z][A-Za-z0-9]*-[0-9]/) {
      if (word[3] ~ /^[A-Z][A-Z0-9]*-[0-9]+$/) {id=word[3]; flevel=hl}
      else bad("a Finding heading whose ID this grammar cannot read")
    } else if (flevel && hl <= flevel) flevel=0
    idseen=(heading ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) || tolower(word[2]) == "finding" || (flevel && hl > flevel)

Results: the four sub-heading rows, a `#####` sub-sub-heading row and the U+2011 row each give rc=3 `a severity
(class) line outside any Finding` in both locales; the control still rc=3 on the lowered tier; `summary-prose` rc=0.
`report_manifest_locale_cases` run alone as the matrix's `judge` does: rc=0 (the judge itself checked: the N06 mutant
on top of the fix gives rc=1 with `a plausible manifest (summary-prose) was refused`). The manifest pass over all 18
recorded notes files and manifests, read as manifests (measure-9's `mpass`): 0 of 18 differ, 59 records.

### R4-F2 (blocking by the brief's definition: reproduced wrong result; pre-existing, not a regression, but it contradicts the rule session 9 states): an emphasized Severity label of more than one word is prose, so the tier drops in silence

The comment above the manifest pass and the 2026-09-30 Decisions entry state the field rule as "a line whose first
word ... is Class or Severity in any case, and which is either an emphasized label or not continued by a letter,
digit or hyphen". `- **Severity level:** data-loss` is an emphasized label whose first word is Severity, but
`fieldname()` treats a line as an emphasized label only when the emphasis closes directly after the word
(`if (emph && t ~ /^[*_]/) return w`); otherwise it skips emphasis and spaces and tests the next word, finds `level`,
and returns prose. The finding is then Class-only and accepted, and the CLEARED round lowering G-042 seals.

    H='# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n'
    man.sh kit sev-level  "$H- **Severity level:** data-loss\n"  kit rc=0, rv rc=0 (C and en_US.UTF-8)
    man.sh kit sev-tier   "$H- **Severity tier:** data-loss\n"   kit rc=0, rv rc=0
    man.sh kit sev-hyphen "$H- **Severity-tier:** data-loss\n"   kit rc=0, rv rc=0
    man.sh kit sev-paren  "$H- **Severity (tier):** data-loss\n" kit rc=3 a Severity line this grammar cannot read; rv rc=0

(`Severity-tier` is prose by the stated hyphen rule and is listed only as the edge of the same class.)

A second member of the same class, the list marker: `fieldname()` skips only the closed ASCII set `-`, `*`, `+`,
`N.`, `N)` before the first word, so a Severity line under any other marker has no first word and is prose:

    man.sh kit ubullet       "$H\342\200\242 **Severity:** data-loss\n"   (U+2022 bullet)  kit rc=0, rv rc=0 (both locales)
    man.sh kit endash-bullet "$H\342\200\223 Severity: data-loss\n"       (U+2013 as bullet) kit rc=0, rv rc=0
    man.sh kit checkbox      "$H- [x] **Severity:** data-loss\n"          kit rc=0, rv rc=0

Smallest class-wide fix (one rule for both members): (a) find the first word after ANY leading run of characters
that are not letters or digits (indentation, any marker, emphasis, non-ASCII bytes) and task-list checkboxes
(`[ ]`, `[x]`, `[X]`), not after a closed marker set; and (b) make "an emphasized label" mean what the comment says: an emphasized span that begins with the
word Class or Severity, is not continued by a letter, digit or hyphen directly after the word, and ends with a colon
inside or directly after the emphasis (`**Severity level:**`, `**Severity level**:`). Such a line is a field line and
must be the strict spelling or is refused by name. Measured over every recorded `notes/*.md` of 001, 002, 003 and the
real manifest with (a) and (b) added to the implemented rule: 0 lines become candidates that are not canonical field
lines (awk in this report's method; the same rule, unit-checked, reads `- [x] **Severity:**`, `• **Severity:**` and
`- **Severity level:**` as field lines and `- **Class-wide fix:**` and `- **Class binding.** ...` as prose). Without the colon condition in (b) the widening would catch the recorded prose
lead-in `   - **Class binding.** A manifest recording ...` (003 `notes/opponent.md:1274`), and without "not directly
continued by a hyphen" every canonical `- **Class-wide fix:**` line, so both conditions are needed. Add `sev-level`,
`ubullet` and `checkbox` as `refuse` shapes. (An abbreviated or synonym label, `**Sev:**`, `**Tier:**`, stays prose
under any label rule; closing that needs refusing a Class-only finding that carries any other `**Label:**` line whose
value is a severity word, recorded here as the remaining extent.)

### R4-F3 (minor, refusing direction; pre-existing, but the R3-F8 repair claims it closed): the matrix criterion is not read "by the same rule" as the AC catalog at its start, so a criterion that begins with a U+00A0 or a tab after its dash can never be matched

`vf_ac_catalog` removes only ASCII spaces after `AC-### —` (`sub(/^(:\*\*|\*\*:|\*\*|:)?[ ]*(—[ ]*)?/, "", text)`),
then collapses every whitespace run to one space and trims only a TRAILING space run (`sub(/ +$/, "", text)`). So
`- AC-001 —<U+00A0>one criterion` (or `—<TAB>one criterion`) has the canonical text ` one criterion`, with a leading
space, and its digest is over that text. `vf_matrix_parse`'s new `criterion()` collapses runs and then trims BOTH
ends, so no cell can produce the leading space: every spelling of the cell is `changed/missing criterion`.

    (catalog text shown with `sed -n l`)   spec line `- AC-001 —<U+00A0>one criterion` -> catalog ` one criterion$`
    cell `one criterion`, `<U+00A0>one criterion`, ` one criterion`  -> DIFFER in kit (and in rv)
    spec line `- AC-001 —<TAB>one criterion` -> catalog ` one criterion$`; cell `one criterion` -> DIFFER
    control: spec `- AC-001 — one criterion<U+00A0>` (trailing) -> EQUAL in kit
    third member, all ASCII: `- AC-001 —` with the criterion on the next line `  one criterion` -> catalog
      ` one criterion$` (the continuation is appended as " " $0), so no cell can match it either

The comment says "the cell is read by the same rule, so a criterion copied as the spec writes it is the same
criterion"; it is the same rule only in the middle and at the end. Smallest class-wide fix: one canonicalization
function used by both sides (collapse every whitespace run to one space, then trim both ends), i.e. add the leading
trim to `vf_ac_catalog`'s `flush()`. No recorded spec.md has an AC whose text begins with a tab or a non-ASCII space
after the dash, and none whose criterion starts on the next line (greps over 001-003 spec.md: 0 hits each), so no
recorded digest or carried row changes.

### R4-F4 (blocking by the brief's definition: reproduced wrong result; pre-existing, not a regression; contradicts the new contract sentence): a manifest whose findings are not heading-plus-field-lines records nothing, in silence

The new contract sentence says "a finding, a field or a heading the pass cannot read is refused by name, never
dropped". A finding recorded as a table row or as one list line has no heading and no line whose first word is Class
or Severity, so the pass reads none of it and refuses nothing; the manifest records no finding, G-042 has no
manifest tier, and the CLEARED round lowering it seals.

    man.sh kit table-with-heading '# P\n\n## Findings\n\n| ID | Class | Severity |\n|----|-------|----------|\n| G-042 | tier-binding | data-loss |\n'
      kit rc=0, rv rc=0 (C and en_US.UTF-8)
    man.sh kit inline-finding '# P\n\n## Findings\n\n- **G-042** (tier-binding) — Severity data-loss\n'
      kit rc=0, rv rc=0 (both)

A summary table of prior findings is a common way to write a prior review. Smallest class-wide fix: refuse by name a
manifest from which the pass records no finding ("the manifest records no finding the grammar can read"); a declared
manifest exists only to vouch for IDs, so an empty record is never the intent. The real 003 manifest records its
findings, so no recorded manifest is refused. (A mixed manifest, some findings under headings and one more in a
table, stays open under that fix; closing it needs refusing a table row or list item that BEGINS with a canonical
finding ID outside any recorded finding. I did not measure that variant.)

### R4-F5 (minor; R3-F3's class, outside both the recorded extent's wording and the catch-all's): a Finding heading inside a list item is not read, so a Class-less finding's Severity falls into a Class-only finding above it

`- ### Finding G-042` (or `1. ### Finding G-042`) is an ATX heading inside a list item in CommonMark, rendered as a
heading. The heading rule needs at most three spaces before the `#` run, and the new catch-all allows only
whitespace or non-ASCII bytes before it, so the line is neither; the finding above stays open and takes the Severity.

    man.sh kit list-heading    '# P\n\n### Finding G-041\n- **Class:** other-class\n- ### Finding G-042\n- **Severity:** data-loss\n'
    man.sh kit ordered-heading '# P\n\n### Finding G-041\n- **Class:** other-class\n1. ### Finding G-042\n- **Severity:** data-loss\n'
      both: kit rc=0, rv rc=0 (C and en_US.UTF-8); G-042 lost, G-041 recorded at data-loss

The recorded extent names "a finding opened by a line with no `#` run"; this one has a `#` run, and the kernel
comment's catch-all ("after leading whitespace or invisible characters, is a `#` run and the word Finding") does not
cover a list marker. Smallest class-wide fix: let the catch-all's leading run include list markers
(`^([[:space:]]|[\200-\377]|[-*+]|[0-9]+[.)])*#+...Finding`). Measured: no recorded `notes/*.md` of 001-003 or the
real manifest has a line of that shape (grep, 0 hits). Same precondition as R3-F3 (the lost finding has no Class).

### End-to-end confirmation of R4-F1, R4-F2 and R4-F4 (live kit, in my copy)

`e2e.sh <label> <manifest>` sources my copy's `tests/test-spec-gate.sh` without `t_run_all`, builds
`make_verification_git_dir` + `floor_fixture` (as `round_locale_cases` does), runs `floor` and `round <spec> opponent`,
writes the manifest, and completes round 1 with a CLEARED report recording G-042 open at `minor`
(`bash "$cli" round "$spec" opponent --complete report.md`):

    control (canonical manifest, G-042 data-loss)  rc=3 ... clearing verdict rests on 1 lowered severity tier(s) of known findings
    R4-F1 sub-heading, unbolded Severity           rc=0 round completed gate=opponent round=1 verdict=CLEARED report=a576c35c...
    R4-F1 U+2011 in the heading's ID, unbolded     rc=0 round completed ... verdict=CLEARED
    R4-F2 `- **Severity level:** data-loss`        rc=0 round completed ... verdict=CLEARED
    R4-F2 `• **Severity:** data-loss`              rc=0 round completed ... verdict=CLEARED
    R4-F4 table manifest                           rc=0 round completed ... verdict=CLEARED

So each is the O-017 wrong result itself: a CLEARED round resting on a lowered tier of a manifest-recorded blocking
finding is sealed.

### R4-F6 (minor, refusing direction, regression of session 9): an emphasized Class or Severity lead-in word inside a finding's narrative is now a field line, so the manifest is refused

The separatorless trigger (`if (emph && t ~ /^[*_]/) return w`, added for R3-F2's `- **Severity** data-loss`) makes
any line that begins with an emphasized `Class` or `Severity` word a field line, whatever follows. Inside a finding
that already has its canonical fields, a narrative line of that shape is then refused as a second field.

    B='### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'   (round records G-042 at data-loss)
    man.sh kit bold-lead-in       "# P\n\n$B**Severity** was re-read after the repro.\n"
      kit rc=3 manifest line 6: a second Severity line in finding G-042: **Severity** was re-read after the repro.
    man.sh kit bold-lead-in-class "# P\n\n$B- **Class** and tier were both re-read.\n"
      kit rc=3 manifest line 6: a second Class line in finding G-042 ...
      rv, both: rc=0 (C and en_US.UTF-8)

It fails closed and names the line, and no recorded file has such a line (measure-9's field-rule scan), so it is the
R3-F5 kind of trade-off, introduced here. Smallest fix, if wanted: for an emphasized label followed directly by a word
(no colon), make it a field only when that word is in the field's value grammar for Severity (a severity token), and
keep Class as is; or state the trade-off in the comment and add `bold-lead-in` as a deliberate `refuse` row, as was
done for `nested-severity-prose`.

### R4-F7 (minor, wording): four statements claim more than the code does

1. The kernel comment above `_VF_AWK_WS` says "Every value a member passes on -- into a catalog or a record, to
   another program, or into a comparison with a value that did not come through the step -- is taken from
   vf_original". The analyzer's umbrella tag pass (a member: it takes `_VF_AWK_TEXT`) prints `tag` from the mapped line
   (`sdd-analyze.sh`, `if (match($0, /\[repo:[^]]+\]/)) tag=substr($0,...)`) and the shell compares it with
   `spec_declared_repos` (`grep -qw "$ttag"`), which did not come through the step; a `[repo:]` name admits whitespace
   (`[^]]+`), so it is not covered by the "no whitespace" or "name" exceptions either. This is the recorded
   umbrella-only extent (the analyzer's task map), but the 2026-09-30 member derivation lists the pass's stage and not
   its tag, as neither member nor not-member, and the comment claims the rule without exception. From source reading;
   not executed (a repo name with a non-ASCII space is implausible). Fix: take `tag` from `vf_original` by the same
   anchor, or name the tag in the comment's exceptions and in the recorded extent.
2. The new contract sentence "a finding, a field or a heading the pass cannot read is refused by name, never
   dropped" and the Acceptance's "so every spelling of a finding is either read or refused by name, never dropped"
   are contradicted by R4-F1, R4-F2, R4-F4 and R4-F5, and, by design, by the outside rule itself (a non-canonical Class
   or Severity line outside any finding before an ID appears is prose). The same sentence says a field line "must be
   written `- **Class:**`", while the pass also accepts `-<U+00A0>**Class:**` and `-<TAB>**Class:**` (its strict test
   is `-[[:space:]]+`), which the canonical parser does not read as a field (it needs `- ` exactly); accepting more
   binds more, so this is precision only.
3. Decisions (4)'s premise "because only a finding's record can carry a Class or a tier", used to justify the ID
   condition, is contradicted by a sub-section heading inside a finding (R4-F1): the canonical grammar keeps the
   record open there.
4. Decisions (1)'s not-member argument lists "a `revision=` compared with a hex digest" among "values whose grammar
   admits no whitespace"; the scanner's grammar is `revision=[^;]+`, which admits it. The outcome is the same on either
   line (any whitespace makes it unequal to `sha256:<hex>`), so only the reason is misstated.
(R4-F3 covers the R3-F8 comment "read by the same rule".)

### R4-F8 (minor, refusing direction; not a regression, REVIEWED_DIR refused these too): the ID condition is broad enough that R3-F5's summary prose is still refused whenever the summary mentions a criterion, a requirement or UTF-8

`[A-Za-z][A-Za-z0-9]*-[0-9]` matches `UTF-8`, `SHA-256`, `ISO-8601`, `AC-012`, `REQ-011`. After the last heading,
any such token turns the following prose Class/Severity lines into refusals, so the R3-F5 repair's summary list
parses only when the summary names nothing ID-shaped:

    man.sh kit ac-ref-summary '# P\n\n### Finding O-017\n...\n\n## Summary\n\nThe finding blocks AC-012.\n- Severity: all blocking\n'
    man.sh kit utf8-summary   '# P\n\n### Finding O-017\n...\n\n## Summary\n\nThe harness decoded UTF-8 under the caller locale.\n- Severity: one blocking finding\n'
      kit and rv, both: rc=3 manifest line 10: a severity line outside any Finding: - Severity: ...

(O-017's own subject is UTF-8, so a prior review of it plausibly mentions it.) Fails closed and names the line.
Smallest fix, if the R3-F5 intent is to hold: use the canonical finding-ID grammar as a whole token
(`(^|[^A-Za-z0-9])[A-Z][A-Z0-9]*-[0-9]+([^A-Za-z0-9-]|$)`) and exclude the spec's own ID namespaces (`AC-`, `REQ-`,
`FM-`, `INV-`), which name criteria, not findings; `UTF-8` still matches that grammar, so it stays a refusal unless the
condition is keyed on IDs the canonical report actually uses. Measure against the history before adopting.

## Held (attacked, with evidence)

- The base: `patch -p1` of `t030o43-session9.diff` onto REVIEWED_DIR gives all 13 files `cmp`-equal to the live
  worktree files (the 8 edited and the 5 carried).
- Values as written (item 1), by reading every program that takes the step (the three analyzer passes, spec-evidence,
  `vf_config`'s stage map, `vf_fm_value`/`vf_fm_count`, the plan pass, the inventory, the task pass, the manifest pass,
  `vf_reports`, the STATUS view, the waiver scanner, `vf_ac_catalog`, `vf_matrix_parse`, `task_scan`): every value
  reaching a `rec`, `print`, `emit` or outside comparison comes from `vf_original` or has no-whitespace grammar, a name
  rule, or both sides mapped, except the umbrella `[repo:]` tag (R4-F7.1, known extent). Every class-based test applied
  to a written value inside a pass (`trim` as `vf_wstrim`, the `(new)` suffix via `vf_wsclass`, the `plan §` test via
  `vf_ws`, `placeholder`, `[^ ]+:[0-9]+`, emptiness after trim) reads raw U+00A0 as the mapped line read VT. The mapped
  and written lines share every ASCII byte, so each anchor (`after_written`'s greedy `^.*\*Label:\*`, the canonical
  `^[^*]*\*\*[^*]+:\*\*`, `vf_heading_text`'s `^#+`, the plan row's pipes) lands at the same logical place. No
  comparison is written-vs-mapped among the task pass, inventory, `selected`, `through-stage`, `vf_config`/stack.yml,
  the return check and the manual observation name.
- History, kit against rv (REVIEWED_DIR), in my copy: `vf_tally` for 001/002/003 byte-identical (001 rc=3 in both,
  pre-existing duplicate identity fields), `spec-task.sh list` identical, `sdd-analyze.sh` output identical, the
  binding catalogs (`vf_bindings tasks`) and their diagnostics identical for all three specs (003: 5916 fields). The
  report catalogs of both gates of 001-003 are identical except 003's opponent report, where exactly 9 values differ
  (8 Scenario, 1 Reproduced), each old value a suffix of the new, as Decisions says; no reader reads catalog fields 9
  and 10 (grep). `git status --porcelain --ignored` of my copy was clean before and after.
- Item 3: every identity and finding field line is matched anchored at its start (`^\*\*(Round|...):\*\*`,
  `^[ ]*- \*\*(Class|...):\*\*`), so the first bold label is always the key.
- Item 4: no member reads `$N`, `NF` or a two-argument or `FS=" "` `split` of a mapped line (grep of all member
  programs); `vf_fields` equals POSIX default splitting under C for a newline-free record (blanks are space and tab).
  W40-W42 are equivalent as argued (W41's anchored `^## Round [1-9][0-9]*$` admits no VT at all; W42's appended
  whitespace-only line is collapsed away by `flush()` in every position).
- Item 5: all stage readers that compare (`vf_config`, inventory, task pass, `task_scan`, both analyzer passes) use
  `vf_heading_text(vf_original)`; spec-evidence's leading-only trim is compared by substring only. W27, W28, W43 are
  equivalent as argued.
- Item 6/7: the v4 probe log shows every new N-row killed with its diagnostic and W27/W28/W40-W43 surviving; the two
  failures (M09, M10) are recorded in STATUS. I re-derived M10's equivalence (a non-canonical Severity line's whole
  trimmed text always starts with a marker or the word Severity, so it can never be a severity token) and M09's
  exception (a line that is exactly `class`). New fixtures cannot pass vacuously: each has a precondition check or a
  kill row (N16-N29, E02). The `refuse` judge asserts only the generic `prior-review manifest could not be parsed`,
  which is how M09/M10 survive; that is the recorded cause.
- The manifest pass under both locales: R3-F1, R3-F2 (all eight), R3-F3 (six spellings) and the R2-F2 combinations
  are refused as the fixtures claim; `sev-paren` (`**Severity (tier):**`) is newly refused by name; `### Finding G-042:`,
  `### **Finding** G-042`, `### Finding — G-042` and `### G-042 — Finding` refuse or close correctly; a strict field
  line with a second bold label is refused (value after its own label only).
- The canonical parser keeps a finding open across a section heading (checked: a `#### Assessment` sub-heading then
  `- **Severity:** data-loss` attaches to G-042), the fact R4-F1 rests on.
- My R4-F1 fix is measured: fixes both members, `report_manifest_locale_cases` passes, 0 of 18 recorded files differ.

## Not reached

- Running the full suites or the matrix of record (the invoker's probe covers the matrix; I ran one fixture function
  and my own kernel-level and end-to-end cases only).
- mawk (R3-F6) and any Linux behaviour: no container, by the constraints.
- R4-F7.1 executed (umbrella spec with a non-ASCII space in a repo name), and an end-to-end run for R4-F5 (its
  kernel-level result is the same code path as R4-F1's end-to-end).
- The rendered-heading classes beyond R4-F5 that the pass also does not see (setext `Finding G-042` + `---`, and
  `<h3>Finding G-042</h3>`): both give rc=0 below a Class-only finding in kit and rv (setext measured; raw `<h3>`
  not run); I file them under the recorded extent "a finding opened by a line with no `#` run".
- The fixes proposed for R4-F2, R4-F3, R4-F4 and R4-F8 were measured against the history by scans only (0 hits), not
  implemented and run against the suites.
- A sentence-by-sentence reading of the first 2026-09-30 Decisions entry's reproduction claims (e.g. REV refusing the
  ordered-list spelling): I have no REV kit.

REVIEW COMPLETE
