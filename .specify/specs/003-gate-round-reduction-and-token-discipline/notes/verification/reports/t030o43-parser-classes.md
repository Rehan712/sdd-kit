# T030o43 — parser sites classified (2026-09-27, session 7)

Source: `t030o43-parser-search.sh` run on the unrepaired tree (`t030o43-parser-search-pre.{log,rc}`,
exit 0, 151 candidate lines over the eight harness files), plus the harness children whose output
the kernel reads (`bash spec-task.sh list`, `spec-task.sh show`), which the program-name search
cannot see. Line numbers are the unrepaired tree's.

The question asked of each site: can this parser FAIL (exit status unread) and the harness then
report a result that PASSES — a clearance, an acceptance, a current floor or capture, a checker
exit 0, a check that silently did not run? With `LC_ALL=C` pinned (the first half of the rule) no
parser here fails on a byte any more; what remains is a failing program for any other reason
(a disk-full write, an unreadable file, a killed process). A site is a MEMBER when its failure reads
as a passing result. It is CLOSED when its failure already refuses. It is DISPLAY when its output
decides nothing (a message, a summary, a warning that never changes an exit code).

## Members (status read, fault fixture, mutant)

| # | Site | What a failure did | Repair |
|---|---|---|---|
| M1 | `verification-lib.sh:955-968` prior-review manifest (reviewer) | the manifest seed was lost; a CLEARED round rested on a lowered tier (O-017) | awk to a file, status read, sort status read |
| M2 | `:2465` Decisions-log authorization parse (reviewer) | fails closed, but the refusal claimed no candidate exists | status read, the refusal names the parse |
| M3 | frontmatter reads that pick the contract, worktree or branch: `vf_project_config :343-346`, `vf_bindings :438-443`, `vf_gate_checkpoint :2359`, `vf_gate_roots :2100-2105`, `spec-run.sh:83`, `spec-task.sh:123`, `spec-evidence.sh:52` | an unread frontmatter read as no `verification_contract`, which selects the legacy path: v1 binding errors become warnings or are skipped, checkpoint coverage is skipped, a v1 task is ticked with `--evidence` alone, and the legacy evidence check replaces `vf_evidence_current`; the worktree/branch mismatch checks were skipped | one checked reader, `vf_fm_value`/`vf_fm_count` |
| M4 | ID inventories read to decide coverage: analyzer `:188` (`spec_acs`) and `:190` (`task_refs`), `spec-ac-coverage.sh:128`, `vf_coverage_catalog :2295`, `vf_completed_coverage :2339` | fewer ids than the file holds: an uncovered AC, a dangling ref or a lost coverage binding went unreported; `spec-ac-coverage.sh` exits 0 on an empty inventory | one checked reader, `vf_ids` |
| M5 | sorts whose output is a file the identity or acceptance reads: env names `:1590`, declared-directory digests `:1542`, required and actual bindings `:1910`/`:1949` | a declared name or directory member unhashed; a return that owes FM/INV rows accepted as `none` | status read |
| M6 | `spec-task.sh list` read by `vf_evidence_current :1837` and `vf_gate_floor :2208` | fewer completed tasks: their Verify not refreshed by the floor, their evidence not checked | the list read to a file, status read |
| M7 | counts over harness records: `vf_bindings :877-878` (errors, warnings); `vf_return_parse :1843` (size bound) | an empty error count published a catalog carrying errors; an empty size passed the 64 KiB bound | status read |
| M8 | analyzer `:147` clarification markers | an unresolved marker read as absent (the report's sibling) | status read |
| M9 | `spec-evidence.sh` legacy path `:71` (task records) and `:111` (artifact names) | a ticked task without evidence, or a named artifact that does not exist, unchecked | status read |
| M10 | `vf_tally :1239-1243` (class table, observation counts) | a MET-002 line silently missing at exit 0 | status read |

## Closed — failure already refuses (status left as is, argued)

`:346`'s sibling `vf_bindings` spec criteria inventories `:466`, `:689-690` (missing ids → `references criterion missing from spec.md`, an error; they move to `vf_ids` anyway with M4); `vf_hash :912-913`
(read); `vf_utc_valid :920` (its status is the result); main `vf_reports :970` (read); `:1230` and
`:2818-2819` (an empty count is an arithmetic error that aborts the tally); `vf_case_folds :1357`
(a failed `tr` reads as "does not fold", so own records are hashed, and the identity moves);
`vf_semantic_file :1399-1401`, `vf_return_parse :1844`, `vf_tasks_rewrite :1969`, `vf_report_block :2420`,
`vf_ac_catalog :2682`, `vf_matrix_parse :2700` (status returned and read by every caller);
`:1534` find (read); `:1737`/`:1770` output bytes (an empty count never equals the file's);
`:1789` (compared, refused); `:1894`/`:1922` trims (an empty id or field refuses); `:1932` duplicate
capture (a failed grep proceeds to `vf_capture_check`, which refuses a repeated capture's summary
count); `:1960`/`:2413` locator presence (a failed grep refuses); `:2061` idempotence (a failed grep
re-validates); `:2113`/`:2173` (read); `:2114` (an empty count is not 1); `:2148` (skips reuse,
re-executes); `:2336`, `:2348` (status is the result / read); `:2739` (an empty criterion never
matches); analyzer `:199-207`, `:210`, `:221`, `:228`, `:253`, `:261`, `:276`/`:334`, `:352`,
`:360`/`:363` (every failure reads as missing, uncovered, dangling or not found, which fails);
`spec-ac-coverage.sh:116-125` and `:139` (fewer test files or hits read as uncovered); `spec-evidence.sh`
`:104`, `:144` (a failed grep fails or warns); `spec-run.sh:76` (not found); `spec-task.sh`
(`set -euo pipefail`: a failed pipeline exits the script nonzero, which M6 now reads).

## Display — decides nothing

`lib.sh` `usage_from_header :200`; `vf_escape :1673`, `vf_summary :1680-1687` and the capture key
`:1730-1731` (text stored and shown; the return must quote the stored summary byte for byte, so a
short summary is consistent, not permissive); `:2071`, `:2247`, `:2542` (messages); `spec-run.sh`
legacy display `:122-173`; analyzer warning-only lines (`:160`/`:189` REQ references, `:169`/`:386`
leftovers, `:185` EXTERNAL mirrors, `:264` stray repo tags) and `spec-evidence.sh:129-139` (manual
AC warnings): each can only suppress a warning, and the analyzer's and checker's verdict is their
exit status, which warnings never change.

## Recorded extent, not repaired here

Umbrella-only readers, already a recorded unexamined surface: `spec_declared_repos` (`fm_list`),
analyzer `:236` task map and its here-string loop `:256`, `vf_gate_task_repo :2169`. `lib.sh`'s
own helpers keep their contract ("no value is an empty echo with exit 0") for their other callers,
002's dispatcher among them; the harness reads the frontmatter it decides with through M3's
checked reader instead. Writes whose status is unread (`printf >> file` in the kernel) are not
parsers; every record the kernel publishes is re-hashed or copied with a checked `cp` before use.

## After the review (2026-09-27): corrections and the character-class members

Correction: M7 as first written also named `vf_return_parse`'s 64 KiB size bound, and the code
was not changed (review F3). It is repaired now: the size is read with its status and must be a
number, with a fault fixture and a matrix row.

The pin has a second consequence the first classification missed (review 1 F1, F2): under C a
byte >= 0x80 is in NO character class, where a UTF-8 locale classes U+00A0 as `[[:space:]]` and
non-ASCII letters as `[[:graph:]]`. The review-1 repair treated it site by site (the table kept in
`t030o43-parser-classes-review1.md`), and review 2 showed that the sites it named were not the class:
two of its repairs regressed (the Decisions view, R2-F1; the manifest catch-all, R2-F3), and every
trim-then-empty test and every name token read a U+00A0 wrongly (R2-F4, R2-F5). The corrected
statement "the other `[[:space:]]` recognizers fail closed" was false for R2-F4's four members.

## After review 2 (2026-09-29): one whitespace step for every parser of author text

Measured before adoption (`t030o43-design-measure.{sh,log,rc}`, exit 0) and recorded in Decisions.
Every parser of author text takes one step before any rule of its own (`_VF_AWK_WS` and
`_VF_AWK_WSLINE` in the kernel): the UTF-8 encoding of each of the 19 non-ASCII Unicode White_Space
characters becomes one VT byte, which `[[:space:]]` matches and no literal grammar does. So every
class-based trim, separator and emptiness test reads the character as whitespace, and every literal
grammar (CommonMark indentation, fences and block quotes, the canonical field line's single space,
the waiver's `; `) reads the line as it did in every locale before the pin; the fence tracker gives
the same state on the mapped line as on the line as written. A value the harness passes on (the
Verify command it runs and records, every `vf_fm_value` result) comes from the line as written,
trimmed at its ends only.

| Takes the step | Why it is a member |
|---|---|
| `vf_config` task stage map, `vf_bindings` plan, inventory and task passes | author tables, headings and task fields; Verify value taken as written |
| prior-review manifest pass | keyed on its field lines by the canonical field grammar; refuses by name what it cannot read |
| main `vf_reports` pass | identity, totals, finding fields, section bodies |
| waiver scanner | the Decisions heading and the authorization grammar |
| `vf_matrix_parse`, `vf_ac_catalog` | reality-check rows and AC text (canonical whitespace) |
| analyzer passes (AC coverage, repo tags, task structure and Agent line) | task blocks, Verify and Agent lines |
| `vf_fm_value`, `vf_fm_count` | frontmatter; values taken as written |
| `spec-evidence.sh` legacy records | Evidence text; artifact names end at any whitespace |
| `spec-task.sh` `task_scan` | stage, exemption and the task list the floor reads |
| `vf_semantic_file` (STATUS) | recognizes on the mapped line, hashes the line as written |

| Does not take it | Why |
|---|---|
| `vf_report_block` | its output is a sealed digest of the report as written; it agrees with `vf_reports` on quoting because the step leaves the fence state unchanged |
| `vf_config` stack.yml grammar, `vf_return_parse` | literal grammars; the commands stack.yml declares run as written |
| `spec-task.sh` rewrite, `vf_tasks_rewrite`, `fm_set` | writers: they reproduce the file's bytes |
| `vf_semantic_file` spec, plan and tasks views | drop literal lines only, so they keep more |
| `lib.sh` helpers (`fm_get`, `fm_list`, registry) | unchanged for their other callers; the harness reads what it decides with through `vf_fm_value`; the analyzer's mode and contract display and the waiver's `status:` read fail closed or display |
| harness records, catalogs, tally inputs, captured output, displays | written by the harness or shown only |

Bracket ranges such as `[A-Z]` match no non-ASCII letter under awk, grep, sed and bash `=~` in
either locale (measured); bash 3.2's glob ranges do under a UTF-8 locale, and the one glob range in
the harness, `'carried (round '[1-9]*')'`, is re-checked by `=~ ^[1-9][0-9]*$`, so no verdict moves.
The four `[[:cntrl:]]` uses reject control bytes (stack.yml, which takes no step) or sanitize
display text. Umbrella readers (`registry_entries`, `fm_list`, `system-map.sh`) stay recorded extent.
