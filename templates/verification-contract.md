# Verification contract, version 1

This is the authoritative authoring grammar shared by spec, plan and task
templates and their validators. Opt in with `verification_contract: 1` in
spec.md frontmatter. Legacy specs remain readable without that marker;
warnings describe missing proof without retroactively changing shipped work.
Coverage locates declarations; independent review judges their adequacy.

## Plan definitions

Define failure modes before task decomposition. Use these table headers:

| ID | Components | Category | Trigger | Decided behavior | Test families |
|---|---|---|---|---|---|
| FM-001 | storage, handler | partial failure | Write fails after validation | Return the mapped error and release the acquired connection | storage-errors |

| ID | Scope | Promise | Enforcement sites | Test families |
|---|---|---|---|---|
| INV-001 | storage, handler | Never release an unowned connection | Shared connection guard; handler's acquisition failure path | storage-errors |

IDs match `FM-[0-9]{3}` or `INV-[0-9]{3}` and have unique definitions.
Categories are boundary, concurrency/ordering, partial failure, regression,
and state/data integrity. List every affected component in shared rows.
Triggers, decided behavior, enforcement sites and test families must be concrete,
not blank, TODO, TBD or placeholders. Table cells are single-line; escape pipes.
Refs and family lists are comma-separated exact tokens, never substring matches.

Record compact **Exclusions** as component/category plus a concrete reason.
For example: formatter / concurrency/ordering — pure synchronous transformation
with no shared state. Reuse applicable stack-overlay scenarios or explain their
exclusion; do not copy every default into every plan.

Register intended test families in the plan:

| Family | Kind | Criteria | Concrete locators |
|---|---|---|---|
| storage-errors | test | AC-001 | `tests/storage.sh::test_failed_write_releases_owned_connection` |

A locator is `repo-relative-file::literal-test-name`; multiple locators in a
family are separated by semicolons. The file and literal declaration must
exist when the implementing task is accepted, not while planning future code.
The locator is not proof that an assertion tests the criterion. Planning needs
no task IDs. At task handoff every applicable FM/INV row has a non-gate owner
with a matching named test. Missing/placeholder rows or missing ownership warn;
duplicate definitions, invalid kinds and dangling references are errors.

## Task fields and verification kinds

Every new-contract implementation task uses the fields below. A behavioral
follow-up remains an implementation task even in Reality Check or Ship;
only actual gate review and shipping administration are exempt.

| Field | Grammar / meaning |
|---|---|
| `*Refs:*` | Exact comma-separated REQ/AC and required FM/INV IDs from spec/plan. |
| `*Verify kind:*` | Exactly `test`, `assertion`, `static` or `manual`. |
| `*Tests:*` | Comma-separated concrete locators from the plan registry; manual uses its registered artifact observation name. |
| `*Verify:*` | One backtick-delimited command, optionally followed by the expected-output arrow. No literal backtick or newline inside a command; put complex checks in a repository script. Manual uses `manual: <observation>`. |
| `*Reuse:*` | Optional `local` or `never`; default `never`. Local declares deterministic, complete local inputs. |
| `*Integration owner:*` | Optional real later integration task ID for named cross-task proof. Does not defer local behavioral tests. |

`test` runs executable tests, including shell test runners. `assertion` runs a
custom executable behavioral assertion without requiring a framework wrapper.
`static` proves a criterion explicitly declared static in the plan family.
`manual` records a plan-declared human observation of an actual artifact.
Family kinds constrain task kinds: a failed automated check cannot be relabeled
static/manual to bypass execution. Split mixed automated/manual proof into
separate families/checks. Untyped AC checks offering only build, typecheck or
text-presence evidence warn; new task handoff has zero such warnings.

Tests travel with behavior: add or extend the covering test in the same task
and commit, name it in Files/Acceptance and Tests, and run it in Verify.
Tests-stage tasks retain only integration spanning tasks or stacks.

```markdown
- [ ] **T001** — Map failed storage writes and release owned connections
  - *Files:* `src/storage.sh`, `tests/storage.sh`
  - *Acceptance:* Extend the failed-write and failed-acquisition assertions.
  - *Verify kind:* test
  - *Tests:* `tests/storage.sh::test_failed_write_releases_owned_connection`
  - *Verify:* `bash tests/storage.sh` → passed, exit 0
  - *Reuse:* local
  - *Refs:* REQ-001, AC-001, FM-001, INV-001
```

## Verification command configuration

The stack.yml subset for verification accepts block lists of single-quoted
scalars, doubled single quotes for a literal quote, two-space map indentation,
and `[]` for optional empty lists. Preserve spaces, `#`, arguments and pipelines
inside scalars. Reject duplicate keys, unknown verification keys, tabs, aliases,
multiline scalars, inline nonempty lists, malformed indentation and unknown
checkpoint stages with file:line diagnostics. Unrelated stack keys keep their
existing grammar. Never eval configuration while parsing.

The rejected expansions are the syntactic forms that splice a value at
execution time, because a reused check identity records the command string and
not what the shell substituted into it: parameter expansion (`$NAME`,
`${...}`, and the positional and special parameters `$0`-`$9`, `$?`, `$$`,
`$!`, `$-`, `$*`, `$@`, `$#`), command substitution in all three spellings
(`$(...)`, backticks, and process substitution `<(...)` / `>(...)`),
arithmetic expansion, and word-initial tilde. This is the enforced set, not a
claim that every semantically time-dependent command is caught — a pipeline
that greps the output of `date` parses fine — which is why an external or
clock-dependent check must stay off the reuse opt-in. A literal dollar that the
shell would not expand stays legal, so an end-anchored pattern such as
`grep -c '^ok$' notes.txt` parses byte-for-byte; a plain redirection such as
`bash tests/run.sh > out.log` stays legal because it splices no command output;
brace expansion stays legal because it is deterministic.

```yaml
gate_checks:
  - 'bash tests/run.sh'
  - 'shellcheck -S warning -x scripts/*.sh tests/*.sh'
checkpoints:
  Backend:
    - 'bash tests/run.sh'
reuse_checks: []
verification_tools:
  - 'bash'
  - 'git'
  - 'shellcheck'
verification_inputs: []
verification_environment: []
```

New contracts require nonempty gate_checks covering the actual full suite and
mandatory static checks. Optional checkpoints use exact task-stage headings;
planning defers stage membership until real task decomposition exists. Missing
legacy configuration warns and cannot automatically clear a floor.
reuse_checks opts exact command strings into local reuse; it does not replace
gate_checks. Declare all relevant resolved tools and otherwise ignored input
paths. A declared input whose physical location is the verified spec's own
generated bookkeeping, or the repository root, is refused by name. Location
resolves links, `.`/`..` segments and repeated slashes through the filesystem,
and folds letter case exactly where the filesystem holding the spec does
(probed there, not read from `core.ignorecase`). Inside a declared directory those records are skipped,
never counted; a link member is hashed through its target like any other link.
Unknown, external or time-dependent inputs forbid reuse in version 1.
`verification_environment` lists relevant exported variable names using shell
identifier syntax (`[A-Za-z_][A-Za-z0-9_]*`), with no values or expansions.
The snapshot environment set is exactly this declaration. Declare every
variable that can affect a check result before opting that check into reuse.
Values are hashed; declared unset and present-empty values differ. Undeclared
session settings do not affect identity.

## Runtime acceptance and freshness

Workers capture with `spec-run.sh --no-tick --summary` and return authentic
capture IDs and FM/INV-to-test mappings. Only the invoker validates and ticks
through `spec-gate.sh accept`. Explicit none is valid only for an empty required
set. Missing, forged, failed or stale proof leaves task state unchanged. Manual
acceptance validates the artifact and recorded observation without inventing a
command exit. Historical completion is preserved while current proof refreshes.
Repeating the exact accepted return for an already checked task acknowledges its
intact committed receipt before checking current inputs. It leaves tasks.md
unchanged and does not record a rejection due to source or environment drift.
This historical acknowledgement does not establish current proof: floor and
checkpoint validation still refresh stale captures.

Presence is not freshness: current proof requires complete log/metadata digests,
before/after source and input identity, exact command/shell/cwd, declared tools
and hashed environment. Whole-source changes invalidate potentially affected
proof; only the verified spec's own generated bookkeeping is excluded (its
`.tasks.accept.*`, `notes/captures/`, `notes/verification/`,
`notes/evidence.md`, `notes/opponent.md` and `notes/reality-check.md`).
Another spec's copies of those paths are ordinary inputs: a shipped spec's gate
report can be a test fixture, and a changed fixture invalidates reuse. Gates reuse
valid execution, never automatic semantic PASS, and may attack covered or
previously unexamined unchanged surfaces.

A reused success is sound only while the check's verdict is a function of that
identity, so a check opted into reuse reads the repository only as the snapshot
hashes it: paths from the same enumeration (tracked files and untracked files
git does not ignore), without the verified spec's generated bookkeeping, and
each path's content as the snapshot hashes it — a link's target as it is; spec,
plan and tasks files without the lines the snapshot drops (`status:` and
`updated:` frontmatter, task Evidence lines, checkbox state); STATUS only for
its Decisions log. That covers the check's own file list, any glob or
directory walk it makes, and any copy it reads. No environment variable the
project has not declared, and no configuration outside the repository,
decides its verdict, except what decides the enumeration itself: git's own
configuration, such as its global excludes, which the snapshot reads the same
way as long as the check runs in the snapshot's environment. Git's
repository-local variables (`GIT_DIR`, `GIT_INDEX_FILE` and the rest) decide
nothing about the enumeration, because the snapshot runs git without them.
Only git runs without them, so a check that reads one declares it under
`verification_environment`, and its value is hashed like any declared name.
The programs a check runs consult the environment whether or not the check
itself reads it: `date` formats `%p` from `LC_TIME`, `tr`, `sed`, `grep` and
awk take their character classes from `LC_CTYPE`, `sort` collates by
`LC_COLLATE`, and git's messages follow `LC_MESSAGES`. A check pins such a
name where it starts, or declares it; the kit's reuse-checked commands, and
`tests/helpers.sh` for every suite, export `LC_ALL=C` right after clearing
`CDPATH`, `BASH_ENV` and `ENV`, and a suite loads `tests/helpers.sh` as its
first command, having only resolved its own directory. `LC_ALL` overrides
`LANG` and every locale category. The harness pins its own parsing the same
way: the kernel exports `LC_ALL=C` when it loads, each harness entry script
loads it before any program reads a byte of the spec, and the command a
capture runs gets the caller's `LC_ALL` back exactly.
A check that depends on an ignored path declares it under
`verification_inputs`; one that reads the dropped lines, or configuration it
cannot pin, stays off `reuse_checks`. The kit's own suites read through
`vf_source_paths` and `vf_path_content`, the functions the snapshot itself
calls, and copy kit directories only through `copy_kit`; a single tracked file
is read or copied by its literal name, and the snapshot hashes those bytes
verbatim. `tests/run.sh` lists its suites that way, `tests/shellcheck.sh` lints
the enumerated scripts with no rc file and `SHELLCHECK_OPTS` unset, both clear
`CDPATH`, `BASH_ENV` and `ENV` before resolving a path, and a suite starts with
the kit's own `SDD_*` variables, `XDG_STATE_HOME` and git's repository-local
variables cleared. A fixture builds its own repositories through
`fixture_git`, with none of the caller's git environment and a pinned, empty
git configuration and template, so a user's hooks, signing, template, line
ending or filter settings, or a hook's environment, cannot decide what a
fixture repository holds, and git never climbs out of the fixture's sandbox to
find a repository; a fixture that cannot build its repository or copy its kit
content fails its test by name, and still hands its caller its sandbox path.
Git reads keep the ambient configuration, as the kernel under test does. The harness itself runs each command under `bash`, which reads
`BASH_ENV` and its other startup variables before any check starts; that input
is not yet part of the identity. Nor are the kernel's own reads of a fixture
repository pinned: a user's global excludes can hide a file a fixture plants
untracked.

The implementation plan owns runtime interfaces and their test families:
capture/provenance, acceptance, floor/checkpoints, round reservations and report
validation. Schema examples here establish authoring intent; runtime negative
fixtures must pass before execution reuse or carried PASS rows are enabled.

## Structured worker return

The invoker saves the exact block under the spec's own bookkeeping —
`<spec-dir>/notes/verification/returns/<task>.txt` — and calls
`spec-gate.sh accept <spec-dir> <task> <return-file>`. A return written into
the verified worktree changes the input manifest and makes the fresh capture
stale. Surrounding prose is not execution evidence: narrative may precede
`Verification-Return: 1` and may follow a completed `Failure modes:` section,
and the parser ignores it. Inside the block nothing is relaxed — a line starting
with `FM-` or `INV-` is always read as a mapping, so a malformed row is rejected
rather than mistaken for prose, and an unrecognized line before `Failure modes:`
is still an error. Repeat Summary once per capture; mappings are exact
comma-separated triples. No extra IDs, duplicate rows or guessed summaries.

```text
Verification-Return: 1
Task: T001
Captures: CAP-1-example
Summary: <exact complete summary.txt line from this capture>
Failure modes:
FM-001, tests/storage.sh::test_failed_write_releases_owned_connection, CAP-1-example
INV-001, tests/storage.sh::test_failed_write_releases_owned_connection, CAP-1-example
```

For an empty required FM/INV set use `Failure modes: none`. For a declared
manual family use `Captures: none`, an observation summary, and:
`Manual observation: name, repo-relative-path, sha256-digest, observer, YYYY-MM-DDTHH:MM:SSZ, PASS: result`.
Its mapping uses the registered observation name and `manual` as the third
field. The artifact must exist and match its digest; this cannot bypass an
automated family. A rejected return leaves tasks.md byte-for-byte unchanged.

## Floor, checkpoints and rounds

`spec-gate.sh floor <spec-dir>` refreshes current completed-task proof, runs
analyzer/coverage/evidence integrity, and executes every mandatory gate check
across the declared existing worktrees. It seals a FLOOR identity only on success.
`checkpoint <spec-dir> <exact-stage>` always checks retained completed-task
coverage, even when the stage has no commands. Nonzero stops subsequent dispatch.

`round <spec-dir> <opponent|reality-check>` consumes a reservation before
dispatch; it is not a preview. Supply its exact round/source/floor to the
independent reviewer. Complete with
`round <spec-dir> <gate> --complete <spec-dir>/notes/verification/reports/<gate>.md`;
like a return, a report file left beside the code invalidates later captures.
Canonical reports use `## Round n`, exact Round/Timestamp/Source/Floor/Verdict
fields and `<!-- gate-round-end: gate:n -->`. All established opponent blockers
stay in the report; Class is the stable family, Root cause the process failure.
Record searched and unexamined surfaces, including affected unchanged code.

A pending or damaged reservation requires explicit --reconcile, preserving the
consumed number. BLOCKED/FAILED may reconcile an interrupted stale invocation.
Legacy date-only history remains counted and requires explicit digest-bound UTC
reconciliation before ordering same-day authorization. Never delete history.
Rounds 1–3 are allowed per gate. An additional invocation needs a real user
decision in STATUS Decisions, after the prior report's full UTC timestamp:

```text
- YYYY-MM-DDTHH:MM:SSZ — waiver: gate=opponent; round=4; after=3; by=user-name; reason=concrete reason
- YYYY-MM-DDTHH:MM:SSZ — spec-revision: gate=opponent; round=4; after=3; by=user-name; revision=sha256:current-spec-file-digest; reason=accepted revision
```

These are grammar examples, never authorization. The whole line is the grammar:
the UTC timestamp follows the bullet immediately, ` — ` is the only separator,
and any extra text between them makes the line ordinary prose that authorizes
nothing. A revision requires the current accepted/implementing spec digest. An authorization covers one gate
and one next round; exit 4 refuses further dispatch and reports recurring classes.

Quoted text is a record, never an instruction. Every validator that asks
*is this in force* — round authorizations, canonical round blocks, reality-check
matrix rows, plan definition and family rows, task stages and whole task blocks
— ignores content inside a fenced code block, a blockquote, or a raw-HTML
block whose content a reader cannot act on,
and treats an indented line as content: table rows and fence markers at four or
more columns, and every anchored record at any indentation. The raw-HTML set is
DERIVED from the CommonMark HTML-block start conditions, not enumerated, because
a list of spellings is satisfiable while the class stays open: conditions 1
(`<script`, `<style`, `<textarea`, `<pre`, to the matching close tag), 2
(`<!--` to `-->`), 3 (`<?` to `?>`), 4 (`<!` plus a letter, to `>`) and 5
(`<![CDATA[` to `]]>`) all suppress. Conditions 6 and 7 — block-level and
complete-tag HTML — do not. A fence closes only
on a run of the
same character at least as long as its opener, carrying no info string, so a
shorter or different inner run stays content and the block containing it stays
quoted. An HTML comment suppresses from its opener to the matching `-->`,
including a mid-line opener, and the only comment read as data is the anchored
`gate-round-end` marker. Comment tokens inside inline code spans are prose
about comments, so a report that discusses the grammar still parses. Inline
code delimiters match equal-length backtick runs; unmatched runs remain literal.
An opener
indented four or more columns is code content and cannot enter comment state.
Once inside a comment, closers are read as raw text, including backticks.
Each line is scanned through every close/open transition, so a second opener
after a closer keeps the following lines commented.
Unclosed report comments produce a diagnostic, just as unclosed fences do.
After a round completion marker, any nonblank content before the next real
round heading is rejected, including fenced, commented and blockquoted text.
Validators that ask *what must be covered* — the AC catalog and the capture
input manifest — deliberately do not suppress, because
dropping an obligation, or losing an edit hidden inside a fence from a capture's
input identity, is the unsafe direction. `<details>` and other rendered raw
HTML are not suppressed: their content is visible to a reader, which is the
property that separates a record from a hidden instruction. The authorization
scanner reads the decisions log under the template's exact `## Decisions log`
heading. The input manifest keeps a superset: from every line that begins
`## Decisions log`, quoted or not, to the next `## ` heading the fence tracker
does not quote, so it never keeps less than the scanner reads, and quoting
decides only that a heading quoted inside the log does not end it.

A report's `Status: resolved` claims a defect that was already reported, and a
resolved finding is not counted, so its claim binds to THE FINDING ITSELF:
its own ID must appear in an earlier round of that gate, or that same ID must
appear in a declared `<gate>-findings-<label>.md` prior-review manifest.
The first Class paired with a finding ID in those manifests or gate rounds is
immutable: every later observation of that ID, under every lifecycle status,
must carry the same Class. Resolution therefore requires the same ID/Class
pair, while a changed Class is a new subject and must receive a new ID.
`Prior` is recorded for the reader and never carries the claim. Binding to a
prior ID, and then to one of the same recorded Class, each failed for the same
reason — both are fields the report's own author writes, so the attack only had
to copy one more token printed in the same file. No value of `Prior` can
resolve a brand-new finding. Manifests live under the spec's `notes/verification/reports/`
and are resolved from the spec directory even when completion or reconciliation
validates a temporary report. A canonical report never vouches for its own IDs.
Manifest definitions use the same quoted-content rules as other declarations;
fenced, commented, blockquoted or raw-HTML-hidden examples cannot establish a
prior finding. A Class or Severity line, in a manifest or in a canonical
report, is decided by its label, read from the line as written and from its
rendered text, and a label either reading yields counts, so an approximation
of the rendering can only refuse: the rendered text takes inline raw HTML out
by CommonMark's own productions (an open tag with its attributes, a closing
tag, a comment, which `<!-->` completes, a processing instruction, a
declaration, a CDATA section), reduces bracket pairs innermost first to a
fixpoint (an image becomes no text, a link its text, so a linked image is
taken out as an image is), renders a numeric character reference as its
character and a named one as a character that is no letter or digit, and
takes out emphasis inside a word; a second rendered reading also takes out
every named reference and every character outside ASCII, so a word shown
whole across an invisible character is read whole; a third reading keeps a
code span's letters and digits and makes its other characters inert, so a
bracket or a tag inside one opens or closes nothing, with code spans placed
by CommonMark's left-to-right reading (backslash escapes taken in pairs, a
backtick run closed only by the next run of the same length); and the label
is also read after each `<br>` or block-level tag outside code spans, where a
renderer starts a new line, in prose and in the value of a canonical field
line. The label is the first word after any run of characters that are not
letters or digits, ordered-list numbers and task checkboxes, and it is read
from each line and from each run of non-blank lines, joined from every line
of the run, since an inline construct may span lines and a line reader cannot
place every paragraph boundary where a renderer does: a run ends only at a
blank line (spaces and tabs only) or an ATX heading of one to six marks, never
at a line the fence tracker calls fenced, so a boundary the reader misses or
invents can only make a line refuse; a line of a run stops being re-read once
nothing a later line adds can change how it begins. Inside a finding the
grammar is narrowed rather than rendered: a line is refused by name when it
carries, outside every code span, raw HTML or an autolink (a `<` followed by
a letter, a digit, or a symbol an email address may begin with), or an inline
link's destination or title, or a full reference link's label, that holds a
backtick or does not end on its line; a bracket pair closed on its line (a
shortcut, collapsed or image reference's label) that holds a backtick run it
does not close, or a URL literal (after `http://`, `https://`, `ftp://` or
`www.`) whose text up to whitespace or `<` holds a backtick, since a GFM
renderer binds both before any code span; when it may be a table delimiter
row (hyphen cells, colons allowed, and at least one pipe), since a renderer
shows a cell's first text where the label reader, which never splits a line
at a pipe, does not look; when it carries a form feed or vertical
tab, or a carriage return that does not end the line; when it opens a code
fence anywhere but at the start of the line (after indentation or a list
marker, where a list item may open a fence the fence tracker does not
follow); or when it begins or closes a link reference definition's label (a
bracket at the start of a line closed by `]:` on that line, or on a later line
of its paragraph, since a label may span lines). The check
is judged after the line's own heading has opened or closed a finding. So a
report writes markup inside a finding only as code, between backticks, writes
a code example inside a finding as a fence at the start of a line, and keeps
link definitions and tables outside every finding. Reports are trusted-author
input, written by the kit's own gate agents: a rendering divergence this
grammar neither reads nor refuses is a minor finding for a follow-up, not a
blocker (REQ-011). The other canonical fields are
decided by their spelling. A manifest field line must be a dash, whitespace
and `**Class:**` or `**Severity:**`, its value the text after that label only,
and every manifest finding needs one readable Class and one readable Severity,
so a tier the pass does not read is refused with its finding rather than
dropped. The list item a Class or Severity line opens, and in a canonical
finding a Status line's, holds that line only: a line that would continue its
paragraph, or other text inside the item, is refused by name unless the pass
reads it as a field line of its own. That item ends at a blank line or at a
line that starts a block that may interrupt a paragraph: a list item, an ATX
heading, a block quote, a code fence, an HTML block of any kind but the
seventh, or a thematic break. Quoting is read by a line tracker that
does not follow CommonMark's containers, so it can quote content a renderer
shows; a fenced, blockquoted, commented or raw-HTML line that is a Finding
heading, or that carries a record of the finding it is in (a finding field
line, a Class or Severity line), is therefore refused by name, in a manifest
and in a canonical round before its completion marker, never skipped, and a
report quotes such an example inline, in a code span after another word. A
quoted field line outside any finding attaches to none. A finding is the section its Finding
heading opens: a heading as shallow as that one closes it, and a deeper
heading is one of its lines. A field line, a Finding heading or a line that
looks like one that the pass cannot read is refused by name, and so is a
manifest from which it reads no finding; a Class or Severity line outside a
manifest finding is prose only while nothing since the last heading can hold
a finding's record. In a canonical report of either gate, only `### Finding
<ID>` opens a finding and any other heading that reads as a Finding heading is
refused; a finding field line outside any finding is refused, so a
reality-check report writes a gap's detail as prose; inside a finding, a line
whose label is Class or Severity and that is not that field's own line is
refused, prose included, so such a line starts with another word; and a
field's duplicate is found by its label, whatever its indentation, in a round
of either style. A round's style is decided before its body, since it decides
which of these rules judge the body's lines: once a round has a body, any
non-blank line but its heading, its report title and its identity fields, a
title that would make a canonical round legacy, or a Timestamp line that
would make a legacy round canonical, is refused by name.

The capture input manifest records environment variables whose MEMBERSHIP is
exactly `verification_environment:` — the declaration and nothing beside it.
No name is hashed because the harness happens to run under it: `PATH` is
already pinned precisely by each declared tool's resolved path and content
digest and by the harness records, `SHELL` is never read because library
functions run under an explicit `bash`, `LANG` and the locale categories
change no record the harness writes (it runs its own parsing under
`LC_ALL=C`, where each byte is one character, so no byte can end a parse;
every parser of author text reads the non-ASCII Unicode White_Space
characters as whitespace through one shared step, takes every value it passes
on from the line as written, and never splits such a line by awk's default
field splitting; and a parse that fails, or a grammar token it
cannot read, is refused by name rather than read as an absence),
while a check whose programs read them pins them or declares
them, as the kit's own reuse-checked commands pin `LC_ALL=C` when they start;
the harness gives the caller's `LC_ALL` back to the command a capture runs,
and the record of a declared `LC_ALL` carries that value, and
`TMPDIR` decides where temporary files go, while its spelling (a trailing or
doubled slash, a symlink) can decide a check that compares a path under it
with the path a program prints, so the kit's own suites set it to the physical
path of the directory it names when they start. A
fixed list including them fails the cross-invocation test that matters:
`LC_CTYPE` and `LC_ALL` are exported by default by macOS Terminal, OpenSSH
`SendEnv` and most CI images, so recording them present in one shell and unset
in another moves the digest for a byte-identical worktree. A project whose
checks genuinely depend on a variable pins it where each check starts, so its
value cannot reach the verdict, or declares it; a declared name's presence and
value then affect identity, and only the value hash reaches the manifest.

Reality-check rows use the full normalized criterion plus `; sha256:<digest>`,
`CAP-id; review: <semantic explanation and artifact/path references>`, the exact
whole-source input digest, and PASS/FAIL/MISSING or `carried (round n)`.
Every AC appears. Carry requires an authentic earlier PASS with unchanged
criterion, evidence and whole-source impact set plus current local evidence.
Unknown impact, source/test/helper/config/tool/environment/dependency changes,
failed or damaged evidence require renewed evaluation. Floor execution does
not assign semantic PASS. Models, separate gates and security-review authority
are unchanged.
