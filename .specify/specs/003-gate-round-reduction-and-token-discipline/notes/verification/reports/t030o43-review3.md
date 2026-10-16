# Focused review 3 — T030o43 session-8 delta (class-wide whitespace rule)

Status: COMPLETE (stopped early at the invoker's request)

Reviewer: independent, read-only. Copy at /private/tmp/rev3-t030o43 (removed at end).

## Findings

Method for every manifest finding below: `repro/man.sh <kit> <label> <manifest %b body>` (copied next to this
report). It writes a spec whose `notes/opponent.md` is the suite's own `tier_round_fixture 1 ''
G-042:tier-binding:open:minor` (a canonical CLEARED round that records G-042 at `minor`), writes the
manifest `notes/verification/reports/opponent-findings-review.md`, and runs
`vf_reports <report> opponent <out> <spec>` under `LANG=C` and `LANG=en_US.UTF-8` with every `LC_*`
removed. `kit` = my copy of the live worktree (session-8 state); `rv` = the same copy's scripts with the
REVIEWED_DIR files laid over (review-2 state; I checked `patch -p1` of `t030o43-session8.diff` onto
REVIEWED_DIR gives all 13 files `cmp`-equal to the copy). Control: the canonical manifest
(`- **Class:** tier-binding`, `- **Severity:** data-loss`) gives rc=3 `clearing verdict rests on 1
lowered severity tier(s) of known findings` in both kits and both locales.

### R3-F1 (blocking, regression toward a pass): the manifest pass now takes a field's value after the LAST bold label on the line, so a Severity line carrying a second label records the wrong tier and a CLEARED round over the lowered tier seals

The new pass reuses the canonical parser's `value()` (`sub(/^.*\*\*[^*]+:\*\*[ ]*/, "", s)`), whose
`.*` is greedy: on `- **Severity:** data-loss; **Prior:** minor` it returns `minor`, which is in the
Severity grammar, so the manifest records G-042 at `minor`. Review-2's pass stripped only up to
`**Severity:**` and removed whitespace, so the same line failed the grammar and was refused by name.

Reproduction (both locales identical):

    man.sh kit sev-then-prior '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss; **Prior:** minor\n'
      kit: rc=0, no output (CLEARED round resting on G-042 lowered from data-loss to minor is sealed)
      rv:  rc=3 manifest line 5: a Severity this grammar cannot read: - **Severity:** data-loss; **Prior:** minor
    man.sh kit sev-minor-then-prior-dataloss '...- **Severity:** minor; **Prior:** data-loss\n'
      kit: rc=3 clearing verdict rests on 1 lowered severity tier(s)   (so the pass read the LAST label's value)
    man.sh kit class-then-status '# P\n\n### Finding G-042\n- **Class:** tier-binding; **Status:** open\n- **Severity:** data-loss\n'
      kit: rc=3 finding G-042 changes Class from open to tier-binding   (Class bound to "open")
      rv:  rc=3 manifest line 4: a Class this grammar cannot read: ...

The Decisions entry says the value is "trimmed at its ends, as the canonical parser trims it"; the
canonical parser has the same greedy defect for its own report lines, but there a finding is refused
when any required field is off, while here the wrong value is the whole record.

Smallest class-wide fix: in the manifest pass take the value after the FIRST `**Class:**` /
`**Severity:**` label only (anchor on the field's own label, e.g. `sub(/^[ ]*-[[:space:]]+\*\*Severity:\*\*/, "", s)`
then trim), so any further `**Label:**` text stays in the value and fails the value grammar by name.
The same non-greedy anchor would repair the canonical `value()` for every field.

### R3-F2 (blocking, wrong result; pre-existing in rv, but it falsifies the session's rule and one member is this delta's own class): a Severity line whose label is not followed IMMEDIATELY by a colon is prose to the pass, so the finding is kept as Class-only and its tier is dropped in silence

`fieldname()` returns a field only when the character after the word (and after emphasis) is `:`.
Whitespace between the label and its colon — including the U+00A0 / U+202F that French typography
puts before a colon, which the step maps to VT — or any other separator makes the line prose. The
pass accepts a Class-only finding, so the tier is silently absent and the O-017 wrong result
returns: the CLEARED round resting on the lowered tier seals. The kernel comment says "no spelling
loses a finding"; the Acceptance says "every spelling of a finding is either read or refused by
name, never dropped".

Reproduction, header `H='# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n'`; every
row gives rc=0 with no output in kit AND rv, under C and en_US.UTF-8 (control: rc=3 as above):

    man.sh kit sev-space-colon      "$H- **Severity :** data-loss\n"
    man.sh kit sev-nbsp-colon       "$H- **Severity\302\240:** data-loss\n"      (U+00A0 before the colon)
    man.sh kit sev-nnbsp-colon      "$H- **Severity\342\200\257:** data-loss\n"  (U+202F before the colon)
    man.sh kit sev-bold-space-colon "$H- **Severity** : data-loss\n"
    man.sh kit sev-emdash           "$H- **Severity** — data-loss\n"
    man.sh kit sev-fullwidth-colon  "$H- **Severity：** data-loss\n"
    man.sh kit sev-ordered          "$H1. **Severity:** data-loss\n"             (ordered-list marker)
    man.sh kit sev-nocolon          "$H- **Severity** data-loss\n"

Smallest class-wide fix: decide "is this a field line" from the LABEL, not from the colon. A line is a
field candidate when its first word, after indentation, a bullet OR ordered-list marker and emphasis,
is `Class` or `Severity` in any case and is not continued by a word character — i.e. after optional
emphasis and whitespace the next character is not a letter, digit or `-` (so `Class-wide fix` and
"Severity was lowered" stay prose); every candidate must then be the strict `- **Class:**` /
`- **Severity:**` spelling or is refused by name. Measured against the recorded history: over every
`notes/*.md` of 001, 002 and 003 and the real 003 manifest, this rule makes no line a candidate that is
not already a canonical field line (0 hits; the awk is in this review's notes, `repro/` section below),
so no real report or manifest is newly refused. (`**Severity** data-loss`, with no separator at all,
stays prose under this rule; closing it too needs "an emphasized Class/Severity label" as a second
trigger.)

### R3-F3 (blocking by the brief's definition: regression toward a pass; narrow): a Finding heading the pass does not read as a heading lets a Class-less finding's Severity fall into a Class-only finding above it, with no refusal

The comment's argument is "its fields fall outside it, or into the one above, and both refuse". Into
the one above refuses only when the one above already has that field, and the pass accepts a
Class-only finding (fixture `class-only`). So after a Class-only finding, a non-heading Finding line
(`###<U+00A0>Finding`, `<U+00A0>###`, U+200B before `###`, a tab before `###`) followed by a Severity
and no Class moves that Severity into the finding above. Read as a heading, the same finding is
refused (`finding G-042 has no readable Class`). Review 2's catch-all
(`/^#+[^A-Za-z]*Finding([^A-Za-z]|$)/`) refused the line itself.

    man.sh kit classless-after-classonly-nbsp '# P\n\n### Finding G-041\n- **Class:** other-class\n###\302\240Finding G-042\n- **Severity:** data-loss\n'
      kit: rc=0 (C and en_US.UTF-8)   G-042 lost; G-041 recorded at data-loss
      rv:  rc=3 manifest line 5: a Finding heading this grammar cannot read: ###<U+00A0>Finding G-042
    man.sh kit classless-readable '# P\n\n### Finding G-041\n- **Class:** other-class\n### Finding G-042\n- **Severity:** data-loss\n'
      kit: rc=3 manifest line 6: finding G-042 has no readable Class   (control)

The same absorption with the line written `\t### Finding G-042`, `<U+200B>### Finding G-042` or
`<U+00A0>### Finding G-042` gives rc=0 in BOTH kits (measured, both locales): review 2's catch-all
was anchored at column 1, so those three are pre-existing; the `###<U+00A0>Finding` spelling is the
regression.

Precondition, stated fairly: the dropped finding is itself malformed (no Class). The outcome is still
the one the rule forbids: a manifest the pass would refuse is accepted, and G-042's recorded tier is
not bound, so the CLEARED round lowering G-042 seals.

Smallest class-wide fix: keep a refusing catch-all for any line that is not read as an ATX heading
but whose text, after leading whitespace of any kind (the mapped VT, a tab, U+200B) and a `#` run,
begins with the word `Finding` in any case — refused by name, as review 2's pass did. (Equivalent:
a Severity may attach only to a finding opened by a heading since the last Class-bearing line; the
catch-all is smaller.)

### R3-F4 (blocking, regression toward a false refusal): the test locators and manual observation names the harness OPENS, GREPS FOR and COMPARES with unmapped readers still come from the mapped line, so a U+00A0 inside one becomes a VT and a task whose files exist cannot be accepted

Attack item 2. Correction 2 took only the Verify command and `vf_fm_value` from the line as written.
Every other value of the task pass (`after($0, ...)`: Tests, Refs, Reuse, Integration owner, Files)
and every plan registry cell is read from the mapped line and written to the binding catalog. Two of
them leave the parser as names the harness acts on: the `*Tests:*` locator (`vf_locators_exist` and
`vf_return_check` open `$repo/${locator%%::*}` and `grep -F` the function name; the return check also
`cmp`s the catalog's `(FM/INV id, locator)` pairs against the worker return, which `vf_return_parse`
reads unmapped), and a manual family's observation name (`[[ "$name" == "${VF_TASK[7]}" ]]` against
the unmapped return). The catalog also records the VT, so the sealed `bindings.nul` of a capture or
acceptance no longer carries the author's bytes.

Reproduction (`repro/fx.sh <kit> <snippet>`: sources the copy's `tests/helpers.sh` with a fresh
SANDBOX under my TMPDIR, SCRIPTS pointed at the kit, then runs the snippet):

    fx.sh kit loc.snip     # make_verification_spec_dir; T001's locator and its plan registry row become
                           # tests/my<U+00A0>check.sh::test_ac_001_shared, and that file exists
      kit: bindings rc=0; verification binding: unknown test tests/my\vcheck.sh::test_ac_001_shared; locators rc=3
           catalog: `tests/my\vcheck.sh::test_ac_001_shared`
      rv:  bindings rc=0; locators rc=0; catalog: tests/my\302\240check.sh::test_ac_001_shared
    fx.sh kit man-obs.snip # T004's manual family and Tests become release<U+00A0>observation; a return names it
      kit: catalog locator release\vobservation, return name release\302\240observation -> DIFFER
           (vf_return_check: 'manual observation fields do not match the planned family')
      rv:  both release\302\240observation -> EQUAL

(`sed -n l` output, so `\v` is the VT byte.) Displays carry it too: the diagnostic above prints a raw
VT to the terminal.

Smallest class-wide fix: apply Correction 2 to every value a parser of author text passes on, not
to two named sites: keep the mapped line for matching and for class-based tests (emptiness,
separators, trimming), and take each emitted VALUE from `vf_original` at the same offsets, trimmed
with `vf_wstrim`. The step maps whole characters, so a value's position is not preserved between the
two lines; the simplest correct shape is a per-field helper `written(label)` that re-applies the
field's own anchor (`sub("^.*\\*" label ":\\*", "")`) to `vf_original` and `vf_wstrim`s it, exactly as
`after_written` does for Verify, used for Tests/Files/Refs/Reuse/Integration owner and for the plan
table's cells (split `vf_original` on `|` the same way). Then derive the members by listing every
field that reaches `rec(...)`, a `print`, or a comparison outside the parser.

### R3-F5 (minor, refusing direction, regression): plausible manifests with prose that starts `Class:` or `Severity:` are now refused

A consequence of keying on the first word, which R2-F2 asked for: a summary list, an intro sentence
or a nested sub-bullet whose first word is `Class:`/`Severity:` is refused by name. Review 2's pass
accepted all three.

    B='### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'   (report records G-042 at data-loss)
    man.sh kit summary-prose  "# Prior review\n\n$B\n## Summary\n\n- Class: tier-binding, one finding\n- Severity: all blocking\n" G-042:tier-binding:open:data-loss
      kit rc=3 manifest line 9: a class line outside any Finding ...; rv rc=0
    man.sh kit intro-prose    "# Prior review\n\nSeverity: every finding below is blocking.\n\n$B" ...
      kit rc=3 a severity line outside any Finding; rv rc=0
    man.sh kit nested-mention "# Prior review\n\n### Finding G-042\n...\n- **Scenario:** the tier moved\n  - Severity: raised from minor after the repro\n" ...
      kit rc=3 a second Severity line in finding G-042; rv rc=0

The refusal is named and fails closed, and no recorded manifest is affected (the real 003 manifest
parses). The trade-off is inherent: R3-F2's fix widens it. Smallest fix, if it is wanted: treat
a candidate outside any finding as prose unless it is the strict `- **Class:**`/`- **Severity:**`
spelling, and refuse only strict spellings there.

### R3-F6 (minor, from source reading, not executed): VT IS a default field separator in mawk, so the kernel comment is false on Linux and `$N` reads of mapped lines depend on the platform's awk

`_VF_AWK_WS`'s comment says "VT is neither a space, a tab nor a default field separator". That is true
of macOS awk 20200816 and gawk. mawk (Ubuntu's default `awk`; the Ubuntu 24.04 runner image lists no
gawk, so the kit's `tests (ubuntu-latest)` job probably runs mawk) marks `\013` as `SC_SPACE`
(`makescan.c:39`: `scan_code['\r'] = scan_code['\013'] = SC_SPACE;`) and `space_split()` (`split.c:85-110`) splits
FS=" " records on every `SC_SPACE` byte. Mapped lines are split this way at `vf_reports`'
`/^### Finding / {fid=$3}` and the totals line `wantb=$2; wantm=$5`. So `### Finding G-042<U+00A0>`
(or `<U+00A0>— title`) is `G-042` under mawk and `G-042\v...` (incomplete finding) under macOS
awk/gawk. The same report is accepted on Linux and refused on macOS; before the delta it was refused
on both. I did not run mawk: building it from the upstream source in my private directory was refused
by the permission system, so this rests on the cited source lines. Smallest fix: do not use default
field splitting on a mapped line in any member (`split($0, w, / +/)` or explicit `FS=" "`-free
parsing), or map to a byte no awk treats as whitespace, and correct the comment.

### R3-F7 (minor, pre-existing): the STATUS identity view omits the quoting context the scanner reads before the log, so one identity can carry two authorization outcomes

The superset claim holds for the lines inside the log but not for the fence state that enters it. In
`repro/status-ctx.sh`, A has an unclosed ```` ````text ```` in "Where things stand"; B does not. The log
holds the waiver, then ```` ``` ````, a quoted line and ```` ```` ````. The identity views are
`cmp`-IDENTICAL in kit and rv, yet `vf_round_authorized <spec> opponent 4 2026-09-27T00:00:00Z` gives rc=4
for A (the heading is quoted, nothing read) and rc=0 for B. Smallest fix: emit the tracker state
(`fenced`, `vf_fence_ch`, `vf_fence_n`, `commented`, `rawkind`) as a synthetic line before each hashed
Decisions heading, or hash from the start of the construct that is open there.

### R3-F8 (minor, refusing direction, regression for such criteria): the reality-check matrix cell is mapped but compared with the AC catalog's space-normalized text

`vf_ac_catalog` now normalizes U+00A0 to an ASCII space. `vf_matrix_parse` maps it to VT and trims
only spaces. So a criterion cell copied as the spec wrote it no longer equals the canonical text
(`repro/matrix.sh`, `- AC-001 — one<U+00A0>criterion`: kit catalog `one criterion`, a cell written
`one<U+00A0>criterion` parses to `one\vcriterion`, so DIFFER and `matrix: changed/missing criterion`; rv:
EQUAL). The criterion's digest also changes for any existing spec with such text, so its `carried`
rows break (none in the kit's history). Smallest fix: canonicalize the cell's criterion by the same rule
(`gsub(/[[:space:]]+/, " ")` on the mapped cell) before comparing. More generally, every comparison of an
author copy against a canonical form should canonicalize both sides.

### R3-F9 (minor, matrix): E02 is not equivalent after this delta

E02's argument is that only a divergence between two readers of one file could show the mutant. The
delta creates exactly such a divergence: for `verification_contract:<U+00A0>1`, `vf_fm_value` gives `1`
(the catalog contract) but `fm_get` gives `\302\2401`. Under E02 the checkpoint would take the legacy
branch and skip `vf_completed_coverage`. No checkpoint fixture feeds that input, so the row survives.
Fix: add the `route-nbsp` shape to `checkpoint_parse_fault_cases` and make E02 a kill row. (W30's
"emits the same cells" is false byte-for-byte, since the cells carry VT, but I found no verdict it
changes.)

### R3-F10 (minor, refusing direction, pre-existing): the artifact-name wrapper set is an enumeration

`repro/art.sh`: an existing `shots/a.png` fails in kit and rv, both locales, when it is wrapped as
`„shots/a.png“` (U+201E, German), `”shots/a.png”` (Swedish), `【shots/a.png】` or `»shots/a.png«`
(Danish): `T001 names artifact '„shots/a.png' ... no such file exists`. ASCII `"shots/a.png"` passes in
kit. Smallest fix: strip any leading run of Unicode opening/initial punctuation (Ps, Pi, plus Pf used
as an opener) by table, or say in the contract that the set is closed.

### R3-F11 (minor, fixture reason): the checkpoint-stage fixture proves `vf_config` only; end to end the stage is still refused

The test-sdd-analyze.sh fixture says "a checkpoint declared for Backend names the stage written
'## Backend<U+00A0>'" and exercises `vf_config` alone. `vf_bindings`' inventory trims only the leading
whitespace of a stage, so `through-stage Backend` fails (`repro/stage.snip` via `fx.sh`):

    kit: suffix U+00A0 -> config rc=0 | error: unknown task stage for through-stage: Backend, rc=1
    kit: suffix ' '    -> config rc=0 | same error, rc=1   (pre-existing for an ASCII trailing space)
    rv:  suffix U+00A0 -> config rc=1 unknown checkpoint stage Backend | through-stage rc=1

So the checkpoint is refused either way; only the message moved. Fix: trim both ends of the stage in
`vf_bindings`' inventory and task passes (and `task_scan`) as `vf_config` does, and assert through
`through-stage` or `spec-gate.sh checkpoint`.

## Held (attacked, with evidence)

- The set in `_VF_AWK_WS` is exactly the 19 non-ASCII White_Space code points, and each UTF-8 encoding
  is right: U+0085 C2 85, U+00A0 C2 A0, U+1680 E1 9A 80, U+2000-200A E2 80 80-8A, U+2028/2029 E2 80 A8/A9,
  U+202F E2 80 AF, U+205F E2 81 9F, U+3000 E3 80 80.
- Fence-tracker equivalence (`repro/fence-diff2.sh`): 7030 samples (19 characters x 37 line templates
  covering fences, the closer rule, indentation, blockquotes, comments incl. mid-line and gate-round-end,
  code spans, and raw HTML conditions 1/3/4/5, each in 10 entry contexts). The state sequence
  (`quoted fenced commented rawkind fence_ch fence_n`) is identical on raw and mapped lines. So
  `vf_report_block` and `vf_reports` agree on quoting.
- REVIEWED_DIR plus `t030o43-session8.diff` equals the live files (all 13 `cmp`-equal after `patch -p1`).
- Shipped STATUS identity views for 001, 002 and 003 are byte-identical between kit and rv.
- Manifest controls and the R2-F2/R2-F3 shapes behave as the fixtures claim. Headings `### Opponent
  finding`, `### Finding G-042:`, `### Findings` and `## Finding summary` close or refuse correctly;
  a readable Class-less finding is refused.
- The waiver scanner and the identity view share one tracker state over every line, and the identity
  starts wherever the scanner can start, so inside the log it is a superset (the context gap is R3-F7).
- The Verify command is taken as written, and a second `*Verify:*` line is refused by `set_field`, so
  `verify_read` cannot judge a different line than the one run.
- `[[:cntrl:]]`, `[[:blank:]]`, `[[:print:]]`, `[[:graph:]]` do not appear in any mapped parser. The
  only `[[:cntrl:]]` uses are stack.yml (unmapped) and capture output (unmapped).
- The equivalence rows W20, W33, M04 and E01 hold by the argument given. W30 holds in verdict.
- The proposed R3-F2 rule was checked against every recorded `notes/*.md` of 001, 002 and 003 and the
  real manifest: 0 new candidates (`repro/hist-fieldrule.sh`).

## Not reached (stopped early at the invoker's request)

- Running the v3 matrix rows or any suite fixture function in my copy; mutation-isolation of the new
  guards, both directions.
- A full member sweep of item 2 beyond the task pass, plan pass and return check. Still to do: the
  analyzer's displayed values, `spec-task.sh list` subjects carrying VT to the terminal and to the
  floor's task list, and the `vf_reports` catalog values `loc`/`trigger`/`repro` carrying VT.
- An end-to-end `spec-gate.sh round --complete` / `accept` / `checkpoint` run for R3-F1 to F4 (all
  reproduced at the kernel-function level only).
- Item 7 wording review, beyond the claims contradicted above: the contract paragraph, the Acceptance,
  and both Decisions entries sentence by sentence.
- Item 8 regressions on the recorded history: re-running tally, analyzer, spec-ac-coverage and
  spec-evidence for 001-003 in kit vs rv.
- Running mawk (R3-F6), and the Linux behaviour of the fixtures generally.
- `vf_fm_value` against `fm_get` on every frontmatter shape the kit writes.

Note: the scripts in `repro/` hard-code my removed copy (`/private/tmp/rev3-t030o43/{kit,rv}`, TMPDIR under it). To rerun, rebuild `kit` from the worktree enumeration and `rv` as `kit`'s scripts/ and templates/ with REVIEWED_DIR laid over.

REVIEW COMPLETE
