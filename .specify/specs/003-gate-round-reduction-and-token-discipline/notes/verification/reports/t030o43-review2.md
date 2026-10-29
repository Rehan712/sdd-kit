# T030o43 focused review 2 (review repairs) — COMPLETE

Reviewer: independent, read-only. Scope: `$R/t030o43-review-repair.diff` (8 files).
Started 2026-09-27.

Result: five blocking findings by the brief's definition (R2-F1 to R2-F5) and three minor (R2-F6 to
R2-F8). R2-F1 (the Decisions identity keeps less, not more) and R2-F4 (U+00A0-only values now read as
present at four sites) are regressions toward a wrong pass. R2-F2 is the O-017 wrong result reached
by other spellings, pre-existing in every kit. R2-F3 and R2-F5 are regressions toward a false
refusal. The five F4 fixture assertions and the F3 size read hold.

## Findings

Base check: private copy `/private/tmp/rev2-t030o43/kit` from the worktree's own
`git ls-files -z --cached --others --exclude-standard` (GIT_OPTIONAL_LOCKS=0), its own git
repository. `patch -p1` of `t030o43-review-repair.diff` onto REVIEWED_DIR gives all 8 files
`cmp`-equal to the copy. Side-by-side kits: `pkit` (copy's scripts/templates/tests with PRE_DIR
laid over, each `cmp`-checked), `rkit` (REVIEWED_DIR laid over), and `ckit` (the copy's committed scripts, templates and tests via
`git archive HEAD`, for side runs while the copy was mutated; `cmp`-equal to the copy). Every run: TMPDIR inside
`/private/tmp/rev2-t030o43`, every `LC_*` removed, `LANG` as stated.

### R2-F1 (blocking, regression): the identity's new Decisions rule keeps LESS, not more — a waiver the authorization parse reads leaves the input identity

`vf_semantic_file` now keeps STATUS from the FIRST line beginning `## Decisions log`
(`/^## Decisions log/ && !seen {on=1; seen=1; ...} /^## / {on=0}`). Any later heading — including
the real, exact `## Decisions log` — now matches only `/^## /` and turns the section OFF. The
authorization parse (`vf_round_authorized`, `:2666`) is unchanged: it starts at EVERY unquoted
exact `^## Decisions log[[:space:]]*$` and skips quoted lines. So whenever STATUS carries an
earlier line beginning `## Decisions log`, the real log drops out of the identity while the
authorization parse still reads it. Pre-delta, the identity started at every exact heading, so it
kept the real log.

Reproduction (`/private/tmp/rev2-t030o43/work/dec.sh`): STATUS.md pairs differing only by one
line `- 2026-09-27T15:55:36Z — waiver: gate=opponent; round=4; after=3; by=someone; reason=...`
appended to the real `## Decisions log` section; `vf_semantic_file .specify/specs/x/STATUS.md`
of each, compared with `cmp`:
- `fenced`: "Where things stand" holds a fenced example containing the line `## Decisions log`.
  Pre-delta (C and en_US.UTF-8): identities differ. Post-delta (both): identical.
- `archive`: an earlier section `## Decisions log (archived, spec 001)`. Pre: differ. Post: identical.
- `dup`: a second exact `## Decisions log` section after `## Open questions / blockers`, the
  waiver in it. Pre: differ. Post: identical.
- In all three, post-delta `vf_round_authorized <spec> opponent 4 2026-09-27T00:00:00Z` returns
  rc=0 (authorized) from the very line the identity no longer hashes.
- The input identity itself (`/private/tmp/rev2-t030o43/work/snap.sh`): a git repo holding
  `.specify/specs/004-x/{spec,plan,tasks,STATUS}.md`, `vf_snapshot <spec> <repo> <repo> <out>` under C
  with the `dup` STATUS without and with the waiver. pkit: digests `f6218e26…` and `79f361d1…`
  (differ). Repaired kit: `7cbb5a91…` both times.
- Pre-existing sibling, same class (both kernels, both locales): a Decisions entry quoting a fenced
  line `## Round 3` ends the identity's section at the fenced line (the identity awk is not
  fence-aware), while the authorization parse skips the quoted line and reads a waiver after it:
  identities identical, `vf_round_authorized` rc=0.

It also reverses an accepted task: T030o17 (`tasks.md:485-487`, ticked) requires that "Both the
round-authorization scanner and the input manifest recognize only the template's exact `## Decisions
log` heading ... the two views stay in step". The identity view now also starts at
`## Decisions log (archived ...)`, `## Decisions logged elsewhere` and the like, and the views no
longer agree. T030o17's fixture (`test-spec-gate.sh:1210-1215`) checks only the authorization view,
and the repair's fixture only the U+00A0-suffixed heading, so no fixture compares the two views; a
mutant that drops `!seen` also passes `harness_locale_cases` (R2-F7, row Y2).

The contract (`templates/verification-contract.md:330-331`) still says "The decisions log is the
template's exact `## Decisions log` heading, in both views" — now false for the identity view, and
the kernel comment ("the identity keeps more, never less") is false for the three shapes above.

Smallest class-wide fix: the identity's section must be a superset of what every reader reads, and
the two views must keep one heading grammar (T030o17). (1) Start at EVERY exact heading
(`^## Decisions log[[:space:]]*$`, every occurrence, quoted or not), as before the repair. (2) Refuse by
name, in both views, a line that begins `## Decisions log` but is not the exact heading (the U+00A0 case
included): the authorization parse denies naming the line, and `vf_semantic_file` returns non-zero so
the snapshot refuses, instead of hashing a guess. (3) End the identity's section only at a `## ` line
the shared fence tracker does not quote (prepend `$_VF_AWK_FENCE`; an unclosed fence then keeps to
EOF). Add fixture pairs for the duplicate, prefixed-earlier, fenced-earlier and fenced-inside shapes
(each must give two identities, or a named refusal), one that compares the two views, and restate the
contract sentence and the kernel comment.

### R2-F2 (blocking, wrong result; pre-existing in all three kits): the strict manifest pass still drops a finding in silence when its heading is spelled any way the pass cannot read, or its Severity by any spelling the marker test does not see

The repair's comment says "Every line that carries a manifest record's marker must parse as that
record". The code does not do that. The refusing catch-all is `id != "" && /\*\*(Class|Severity):\*\*/`,
so a marker line OUTSIDE a finding is skipped without a word, and the heading catch-all
`/^#+[^A-Za-z]*Finding([^A-Za-z]|$)/` is case-sensitive, anchored at column 1, and allows no word
before `Finding`. A heading it cannot see leaves the fields after it outside any finding (dropped),
or inside the finding above (last write wins, no duplicate check, unlike the canonical parser's
`duplicate finding field`).

Reproduction (`/private/tmp/rev2-t030o43/work/man.sh`, direct `vf_reports`, report = canonical
CLEARED round 1 with `### Finding G-042`, `- **Class:** tier-binding`, `- **Status:** open`,
`- **Severity:** minor`, `**Blocking:** 0 · **Minor:** 1`; manifest `opponent-findings-review.md`
records G-042 `tier-binding` at `data-loss`). The ASCII control refuses in every kit and locale
(rc=3, `clearing verdict rests on 1 lowered severity tier(s) of known findings`). Each of these
gives rc=0 with no diagnostic in pkit, rkit and the repaired kit, under C and en_US.UTF-8:
- headings: `### finding G-042`, `### FINDING G-042`, ` ### Finding G-042` (one leading space, a
  valid CommonMark heading), `### Opponent finding G-042`, a UTF-8 BOM before `### Finding G-042`
  on line 1, a U+200B before `###`;
- a U+00A0 BEFORE `###` (`<U+00A0>### Finding G-042`, `man4.sh`): rc=0 in pkit and the repaired kit,
  both locales, alone or after a `### Finding G-041` (whose Class and Severity it then overwrites).
  This is a manifest heading carrying a U+00A0, which the corrected Acceptance says "is refused in
  every locale"; the fixtures only put the U+00A0 after `###` or after the ID;
- merge: `### Finding G-041` at data-loss, then `### finding G-042` at minor: G-041 is recorded at
  minor, and a CLEARED round lowering G-041 to minor seals;
- Severity: `- **Severity**: data-loss`, `- Severity: data-loss`, `- **severity:** data-loss`,
  `- *Severity:* data-loss`, and two `- **Severity:**` lines (data-loss, then minor);
- CRLF line endings (`man5.sh`): the heading regex's `[[:space:]]*$` admits the `\r`, and `id=$NF` keeps
  it, so every manifest ID is recorded as `G-042\r` (measured: `id=[G-042\r]`). Neither binding reaches
  the round's G-042: the lowered tier AND a changed Class (`silent-data-loss`) both give rc=0, in
  every kit and locale. The canonical parser refuses the same heading (`fid !~ /^[A-Z][A-Z0-9]*-[0-9]+$/`);
- quoting left open (`man6.sh`): after `### Finding G-041`, an unclosed ```` ```text ```` in its Scenario, a
  mid-line `<!--` that never closes, or a `<pre>` that never closes, suppresses every later line, so
  `### Finding G-042` at data-loss is dropped: rc=0 in pkit and the repaired kit, both locales. The
  canonical parser refuses the first two at END (`unclosed code fence`, `unclosed HTML comment`); the
  manifest pass has no END check;
- through the entry script: `spec-gate.sh tally <spec>` on the `### finding G-042` spec exits 0
  with `blocking=0 minor=1` in pkit and the repaired kit, both locales, where the control exits 3.

Not a regression, but it is the wrong result O-017 and review F1 named (a CLEARED round resting on a
lowered tier of a manifest-recorded blocking finding), reached by ASCII spellings, a U+00A0, a BOM,
CRLF endings or unclosed quoting, and it falsifies the repair's own stated rule.

Smallest class-wide fix: key the pass on field lines, not headings. (1) Any line whose first word,
after optional indentation, list marker and emphasis, is `Class` or `Severity` in any case,
followed by `:` inside or outside the emphasis, must match the strict field grammar, whether or not
a finding is open; a strict field line with no open finding is an error. (2) A second Class or
Severity line in one finding is an error (the canonical parser's own duplicate rule). (3) Strip a
UTF-8 BOM on line 1 and a trailing `\r` on every line (or refuse CR), and require the recorded ID
to match `^[A-Z][A-Z0-9]*-[0-9]+$` exactly. (4) At END, refuse a manifest whose
fence, comment or raw-HTML state is still open (`fenced || commented || rawkind`). With (1) and (2), a
heading the pass cannot read can no longer lose a finding:
its fields fall outside a finding or duplicate the one above, and both refuse.

### R2-F3 (blocking by the brief's definition: regression, refusing direction): the strict pass refuses the spec's own recorded finding text, and ordinary headings, as a manifest

The unanchored catch-all refuses any line inside a finding that merely MENTIONS `**Class:**` or
`**Severity:**`, and `flushm` runs only at a Finding heading, so every line after the last finding
(follow-up tasks, assessment) is still "inside" it. Headings the canonical parser reads
(`/^### Finding /`, `fid=$3`, a title allowed) are refused.

Reproduction (`man.sh`, `man2.sh`, `man3.sh`): each passes the manifest pass in pkit and rkit (rc=0; for
the O-017 case the run stops later, at the deliberately empty report's `no recognized rounds`), and
is refused by the manifest pass in the repaired kit (rc=3) under C and en_US.UTF-8:
- the REAL round-12 `### Finding O-017` block of `notes/opponent.md` (lines 1258-1292), copied
  verbatim into `opponent-findings-r12.md`: `manifest line 14: a Class or Severity line this
  grammar cannot read:   - **The inputs.** The manifest has six lines: ...`;
- `- **Scenario:** a field line written `-<U+00A0>**Class:**` was skipped`;
- `- **Class-wide fix:** make every `**Severity:**` line parse by the canonical grammar`;
- a follow-up line after the last finding: `- **T001** — fix it; its **Severity:** stays data-loss`;
- an indented code block (six spaces) inside a finding quoting `- **Severity:** minor`;
- `### Finding G-042 — tier binding lost` (`a Finding heading this grammar cannot read`), and
  `## Finding summary` after the findings.
The real 003 manifest still parses (the invoker's measure, and my `hist.sh`: `tally` for 001, 002 and
003 is byte-identical between rkit and the repaired kit under C and en_US.UTF-8). Held: `## Findings`,
fenced and HTML-commented examples, and a Class-only finding parse in the repaired kit.

Smallest class-wide fix: the same restructure as R2-F2. A field is a line-initial field, never a
mid-line mention; flush the finding at every heading line, not only a Finding heading; and read the
heading exactly as the canonical parser does (`### Finding <ID>` followed by anything), so a titled
heading is a finding, not an error.

### R2-F4 (blocking, regression, passes a wrong result): the "is this value empty" class — the repair gave the section-body test a Unicode blank, and left every other emptiness test over author text on `[[:space:]]`, where a U+00A0-only value now reads as present

The repair recognised that under the pin a line of Unicode blanks is no longer blank, and fixed ONE
emptiness test (`secbody`, via `vf_blank`). Every other site that trims author text with
`[[:space:]]` and then asks "is anything left?" has the same defect, and the classification's
arguments for them ("the main report parser's field lines use literal spaces and refuse an incomplete
finding", "manual-Verify ... tokens refuse", "or only trim a value, which then compares unequal and
refuses") are wrong: the trimmed residue is tested for emptiness, and a U+00A0 residue PASSES. Pre-delta
under en_US.UTF-8 macOS awk classes U+00A0 as `[[:space:]]` (measured in `blank.sh`: it is the only
non-ASCII code point it does), so each of these was refused there and is accepted now in every locale:

1. Canonical finding fields (`vf_reports` `value()` -> `clean()`, then `trigger==""`, `repro==""`,
   `wrong==""`, `fix==""`, `prior==""`). `/private/tmp/rev2-t030o43/work/fields.sh`: a canonical
   CHALLENGED round, one data-loss finding, one field set to `<U+00A0>`. For each of `Scenario`,
   `Reproduced`, `Wrong behavior`, `Class-wide fix` and `Prior`: pkit en_US.UTF-8 rc=3
   `incomplete finding G-042`; pkit C rc=0; repaired kit rc=0 under C and en_US.UTF-8. A gate report
   whose finding has no reproduction (O-004's required fields) is accepted.
2. Legacy Evidence (`spec-evidence.sh:88` trim, `:102` `[[ -z "${ev// /}" ]]`). `art.sh` row
   `nbsp-only-evidence`: `- [x] **T001** — Legacy task` with `  - *Evidence:* <U+00A0>`. pkit
   en_US.UTF-8 rc=1 `T001 is [x] with no *Evidence:* line — an unproven claim`; pkit C rc=0; repaired
   kit rc=0 in both, `sound — every ticked box traces to real evidence`.
3. A manual Verify's observation (`vf_bindings :859`, `^manual:[[:space:]]+[^[:space:]]`). `manual.sh`:
   the kit's own v1 fixture (`make_verification_git_dir`), T004 (`*Verify kind:* manual`) with
   ``*Verify:* `manual: <U+00A0>` ``. pkit en_US.UTF-8 rc=1 `task T004 manual Verify must be manual:
   <observation>`; pkit C rc=0; repaired kit rc=0 in both. (An empty ASCII observation is refused
   everywhere.)
4. Plan table placeholders (`placeholder()` = `tolower(trim(s))==""`). `placeholder.sh`: the same
   fixture with the `manual-family` registry locator and T004's `*Tests:*` both `<U+00A0>`. pkit
   en_US.UTF-8 rc=1 (`verification family manual-family has blank or placeholder criteria/locator`,
   `task T004 Ref INV-001 has no matching typed test-family locator`); pkit C rc=0; repaired kit rc=0 in
   both: a manual task binds to an invisible observation name.

Same shape as review F1: the delta makes the C miss universal. Smallest class-wide fix: one shared
definition of blank (vf_blank's byte set, lifted into a kernel awk fragment, e.g. `_VF_AWK_BLANK`, with
a `vf_trim` built on it), used by EVERY trim whose result is tested for emptiness or placeholder-ness:
`clean()`/`value()` in `vf_reports`, `trim()`/`after()`/`placeholder()` in `vf_bindings`, the manual
observation test, spec-evidence's Evidence value, and the post-marker `ended && $0 !~ /^[[:space:]]*$/`.
Derive the members by searching for every `[[:space:]]` trim whose result reaches `==""`, `-z`,
`!~ /[^[:space:]]/` or `placeholder`, not by listing sites. One U+00A0 fixture per member.

### R2-F5 (blocking by the brief's definition: regression, refusing direction): a Unicode space or quote is now read INTO a name — `[^[:space:][:cntrl:]]` artifact names and the analyzer's Agent path fail on files that exist

Under C, `[^[:space:][:cntrl:]]` admits every byte >= 0x80, including the UTF-8 encodings of Unicode
spaces and quotation marks. The name therefore runs back across a U+00A0 or U+3000 to the previous
word.

Reproduction (`art.sh`; `shots/a.png` exists in every row; legacy spec as in R2-F4):
- `screenshot<U+00A0>shots/a.png`, `screenshot<U+202F>shots/a.png`, `screenshot<U+2003>shots/a.png`:
  pkit rc=0 under C and en_US.UTF-8; repaired kit rc=1 under both, `T001 names artifact 'screenshot shots/a.png' in its evidence, but no such file exists`.
- `截图<U+3000>shots/a.png`: pkit rc=0 under both; repaired kit rc=1 under both (`'截图　shots/a.png'`).
- `“shots/a.png”`, `«shots/a.png»`, `截图：shots/a.png`: pkit rc=0 under C (rc=1 under
  en_US.UTF-8); repaired kit rc=1 under both, so a C caller regresses.
- Same class, another site: `sdd-analyze.sh:365` strips `.*\*Agent:\*[[:space:]]*` with `sed`, then takes
  `[^ \t)(]+\.md`. macOS sed under en_US.UTF-8 classes U+00A0, U+2003, U+202F and U+3000 as
  `[[:space:]]` (measured); under C none. `agent.sh`: the kit's v1 fixture, with the files
  `agents/opponent.agent.md` and `agents/reality-check.agent.md` present and the opponent task's line
  `  - *Agent:* <U+00A0>agents/opponent.agent.md`. pkit en_US.UTF-8: rc=0, `✓ opponent gate present,
  agent file exists`; pkit C rc=1; repaired kit rc=1 under both, `✗ opponent gate agent file not found:
  <U+00A0>agents/opponent.agent.md`. The analyzer is a floor checker, so a UTF-8 caller's floor on such a
  spec now fails.
- Pre-existing in every kit and locale: a backtick-quoted name (`` `shots/a.png` ``) fails as
  `` '`shots/a.png' ``.

Smallest class-wide fix: split name tokens (artifact names, the Agent path) on the same shared blank set (ASCII blanks, controls,
and the White_Space UTF-8 sequences) — e.g. rewrite those sequences to a space with one `LC_ALL=C sed`
before `grep -o '[^ ]+\.(png|…)'` — and trim a closed set of wrapping punctuation (ASCII quotes and
backticks, `“ ” ‘ ’ « » 「 」 （ ） ：`) from both ends of each token. Extend the fixture: an existing
name after a U+00A0 and inside curly quotes must pass in every locale.

### R2-F6 (minor; pre-existing): `spec-evidence.sh`'s "three ways, as every other reader routes it" is two-and-a-half — a present but empty contract key is the legacy check here and a refusal in the kernel

The new routing tests the VALUE (`-z` -> legacy). The kernel routes by the KEY: `vf_bindings`
(`:547-561`) and `vf_project_config` (`:345-350`) count the key with `vf_fm_count`, and a key that is
present with an empty value is `unsupported verification_contract <empty>; expected 1`.

Reproduction (`/private/tmp/rev2-t030o43/work/route.sh`): a spec with a plan, and tasks.md holding one
ticked task whose Evidence is prose. With `verification_contract:`, `verification_contract: ""` and
`verification_contract: ''`, `spec-evidence.sh <spec>` exits 0 (`sound — every ticked box traces to
real evidence`, the legacy check) in pkit and the repaired kit, while the repaired kernel's
`vf_bindings <spec> tasks '' <out>` exits 1 with the message above. The values `2` and `# none yet` are
now refused by name (rc=3), which is the intended part and holds. `spec-run.sh:87` and
`spec-task.sh:128` share the value test, so the same key reads as legacy there too. The floor reaches
`vf_project_config` first, so I found no floor verdict that changes; a standalone checker run does.

Smallest class-wide fix: route by the key, as the kernel does, in all three entry scripts: count 0 is
legacy, count 1 with value `1` is current, anything else is refused. One shared helper
(`vf_contract_route`) instead of three copies of the test.

### R2-F7 (minor): fixture gaps in the repair's own guards

Measured in the copy with `/private/tmp/rev2-t030o43/work/mut-extra.sh` (the invoker's `judge`:
one fixture function, a fresh SANDBOX, restore checked with `cmp` and a clean
`git status --porcelain --ignored`):
- **Y1** — `vf_blank` reduced to `[ \t\r\f\013]|\302\240` (16 of the 17 non-ASCII White_Space
  sequences removed) SURVIVES `report_manifest_locale_cases`: only U+00A0 is exercised. `blank.sh`
  shows the live set is right (every White_Space code point is EMPTY, in both locales), but no
  fixture would notice a broken octal range under a different awk.
- **Y3** — the artifact class replaced by `[^ ]` SURVIVES `floor_parse_fault_cases` (no tab or
  control byte in any case).
- **Y2** — dropping the identity's `!seen` SURVIVES `harness_locale_cases`: no fixture separates
  the first-only rule from every-occurrence, which is why R2-F1 was not caught.
Smallest fix: loop the section-body case over every White_Space code point; add a tab-separated
artifact case; add R2-F1's fixture pairs.

### R2-F8 (minor, wording): the restated sentences say more than the code does

- Kernel comment (`verification-lib.sh:384-387`): "each parser that decides with it refuses such a
  line, or, where it decides what must be covered, keeps more" — false for R2-F1 (keeps less),
  R2-F2 (drops) and R2-F4's four members (accept).
- Manifest-pass comment (`:1081-1086`): "Every line that carries a manifest record's marker must
  parse as that record, by the same field grammar a canonical finding obeys" — marker lines outside
  a finding are skipped (R2-F2); and the grammars differ: the canonical heading is `/^### Finding /`
  with `fid=$3` (a title allowed), its field lines `^[ ]*- \*\*Field:\*\*` (indentation allowed, one
  literal space, duplicates refused); the manifest wants a column-1 `-`, admits `-[[:space:]]+`,
  refuses a titled heading and accepts duplicates.
- `vf_blank` comment: "Blank is what a reader sees as blank" — a line of only U+200B, U+2060, U+FEFF,
  U+00AD, U+2800 or U+3164 is invisible and counts as a body (`blank.sh`; same in pkit, so not a
  regression). Either say "Unicode White_Space" and stop, or add Default_Ignorable_Code_Point and the
  fillers.
- `vf_semantic_file` comment "The identity keeps more, never less"; contract `:330-331` "exact
  `## Decisions log` heading, in both views"; T030o17's Acceptance — see R2-F1.
- Contract `:359-362`: "a record line its ASCII grammar cannot read is refused by name or, where the
  harness decides what must be covered, kept whole; and a parse that fails never reads as a passing
  result" — R2-F2 and R2-F4 are counter-examples on this tree.
- The corrected Acceptance (`tasks.md:740`): "a manifest heading ... carrying a U+00A0 is refused in
  every locale" — false for a U+00A0 before `###` (R2-F2).
- `t030o43-parser-classes.md`, last section: "The other `[[:space:]]` recognizers fail closed on such
  a line (the main report parser's field lines use literal spaces and refuse an incomplete finding;
  ... manual-Verify ... tokens refuse; ... or only trim a value, which then compares unequal and
  refuses)" — R2-F4's members 1 to 4. And C3's repair is R2-F1.
Fix: restate after the repairs, and derive each "refuses"/"fails closed" from a measurement.

## Held

Each was run in the copy or the side-by-side kits and gave no wrong result.
- **Base.** REVIEWED_DIR plus `t030o43-review-repair.diff` equals the copy, byte for byte, for all 8
  files.
- **The five new F4 fixture assertions** (`mut-f4.sh`, log `mut-f4.log`). Baselines pass unmutated
  (`analyzer_locale_and_fault_cases` 4 s, `harness_locale_cases` 18 s, `report_manifest_locale_cases`
  2 s). Each guard removed with the invoker's own literal, judged alone, restored with `cmp` and a clean
  `git status --porcelain --ignored`: X1 (the record's re-read branch), X2 (`vf_caller_env`'s unset
  branch), X3 (the manifest sort), X4 (the tally sort) and X5 (`vf_ids`' sort) each FAIL their judge
  with their exact diagnostic (`a record inherited beside another LC_ALL replaced the caller's
  value`, `an unset caller LC_ALL was recorded as the pin`, `manifest records that could not be sorted
  were read as none`, `a class table that could not be sorted went missing from the tally`, `an id
  inventory that could not be sorted read as a short one`). Every `fault_bin` marker used by them
  (`manifest-locale.nul.`, `class-lines`, `=-u =-`) names only its target invocation.
- **F3, the size read.** Boundary unchanged: 65536 bytes parse, 65537 and 81084 give `return exceeds
  64 KiB`; with `fault_bin wc -c`, every size gives rc=3 and `return: its size could not be read`.
  `a && b || c` is safe under `spec-task.sh`'s `set -e`.
- **`vf_blank`'s set.** It is exactly Unicode White_Space as UTF-8 (U+0009 to U+000D less LF,
  U+0020, U+0085, U+00A0, U+1680, U+2000 to U+200A, U+2028, U+2029, U+202F, U+205F, U+3000); each, as
  a section's only body line, is `empty required report section` under C and en_US.UTF-8, and bwk
  awk handles the octal ranges byte-wise (`blank.sh`). Pre-delta en_US.UTF-8 awk classed only U+00A0,
  so the repair only refuses more. No real report's required section now counts as empty: `tally`
  for 001, 002 and 003 is byte-identical to the reviewed tree in both locales.
- **Manifest shapes that should parse:** `## Findings`, fenced, HTML-commented and blockquoted examples
  (a commented `**Severity:** minor` does not lower the recorded tier), and a Class-only finding.
  Every U+00A0 position the fixtures name (after the dash of either field, after the ID, between `###`
  and `Finding`), and a U+00A0 inside or before a Class value, before a Severity value, or between
  `Finding` and the ID, are refused by name in both locales (`man8.sh`).
- **Shipped STATUS identities.** `vf_semantic_file` of 001's, 002's and 003's STATUS.md is
  byte-identical to the reviewed tree's; each has exactly one line beginning `## Decisions log`.
- **Contract routing, the intended part.** `2` and `# none yet` (my `route.sh`) and `<U+00A0>1` (the
  invoker's measure, row D4) are refused by name (`unsupported verification contract: …`, rc=3) where
  the pre-delta kernel ran the legacy check.
- **`[A-Z]` ranges.** awk, grep, sed and bash `=~` match no non-ASCII letter in either locale. bash
  3.2's GLOB ranges do (`case É in [A-Z])` matches under en_US.UTF-8, measured), so the
  classification's "(measured)" is too broad; but the one glob range in the harness,
  `'carried (round '[1-9]*')'`, is re-checked by `=~ ^[1-9][0-9]*$`, so no verdict moves.
- **String ordering.** The first review said the harness has no bash ordering test; there are two,
  `[[ "$stamp" > "$previous" ]]` and `[[ ! "$stamp" > "$now" ]]` in `vf_round_authorized`. Both
  compare `vf_utc_valid` stamps of one fixed ASCII shape, which C and en_US.UTF-8 order alike.

## Outside the repair's scope, observed (pre-existing in pkit and the repaired kit)

- A waiver or revision with `by= ` (one ASCII space) or `by=<U+00A0>` authorizes (`vf_round_authorized`
  rc=0): `by=[^;]+` has no emptiness test. `by=` alone is refused.
- `for art in $arts` in `spec-evidence.sh` is unquoted, so an Evidence of `screenshot shots/*.png`
  passes when any PNG exists there (measured with the checker run from the spec directory).
- `system-map.sh` (12 `[[:space:]]` uses) and `sdd-doctor.sh` (1) now parse under the pin; neither is
  in the eight-file derivation. `system-map.sh` is reached only through the umbrella gate roots.

## Not reached

- **Linux / GNU tools / bash 4-5.** Every measurement here is macOS awk, grep, sed and bash 3.2. GNU
  awk's `[[:space:]]` and default field splitting, and GNU sed's UTF-8 classes, were not measured, so
  the pre-delta side of R2-F4 and R2-F5 is proven for macOS only (the post-delta side follows from the
  pin on any host).
- **The invoker's full mutation matrix and suite.** I ran only my rows (X1-X5, Y1-Y3) and the three
  baselines, one fixture function at a time; no whole suite and no ShellCheck (the invoker's matrix
  shards were running, and disk was at 4.6-11 GiB).
- **End-to-end through `round --complete`** for R2-F2 to R2-F4. I used direct `vf_reports`, `tally`,
  `vf_bindings`, `vf_snapshot`, `sdd-analyze.sh` and `spec-evidence.sh`; the first review established
  that `vf_reports` and `round --complete` agree on the manifest.
- **The canonical report parser** under the same heading spellings as R2-F2 (for example a lowercase
  `### finding` in a round): out of this delta; not tested.
- **Other invisible characters** in names and fields (U+200B, U+FEFF) and other scripts' punctuation
  beyond those listed in R2-F5.
- **Umbrella and multi-repo specs**, EUC-JP, GB18030 and Big5 locales.

The scripts (and `mut-f4.log`, `mut-extra.log`) are kept beside this report in `repro/`. They name
paths inside the removed `/private/tmp/rev2-t030o43`; to re-run, rebuild the copy from the worktree's
enumeration and the `pkit`/`rkit`/`ckit` kits as the Base check describes (`ckit` is the copy's committed
scripts, used for side runs while the copy was mutated).
Nothing in the worktree was created, modified, moved or removed.

REVIEW COMPLETE
