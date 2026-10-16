# Focused review 3 brief — T030o43's class-wide whitespace rule, 2026-09-29

Every operational rule of `t030o43-review-brief.md` (read it first, in the same
directory) applies unchanged: read-only, a private copy with `TMPDIR` inside
it, no suite or test function in the worktree, one copy and one suite at a
time, a progressive report at `REPORT_PATH` ending `REVIEW COMPLETE`, severity
per finding (blocking: a reproduced wrong result, data loss, regression or
crash; otherwise minor) with an exact reproduction and the smallest
class-wide fix. Check `df -h /`, `sysctl vm.swapusage` and `pmset -g batt`
first; free disk is about 12 GiB.

## Scope

Only the session-8 delta: `$R/t030o43-session8.diff` (11 files). The files
as review 2 saw them are at `REVIEWED_DIR` (given in your prompt), proven by
`$R/t030o43-rev3-base.{sh,log,rc}`: reversing this session's recorded literal
edits (`$R/t030o43-edits/*.pairs` named in that script) from the live files,
then reversing review 2's and review 1's recorded diffs, gives files equal to
the source-70c71885 records taken before any code changed, and applying the
two diffs forward again gives the same files.

Why each change exists: the two newest entries of the Decisions log in
`$S/STATUS.md` (dated 2026-09-29). They record the rule as measured, with
three corrections to the working design `$R/t030o43-review2-design.md`, and
the task-block correction. The measurement before adoption is
`$R/t030o43-design-measure.{sh,log,rc}` (run 1 failed on its rebuild step and
run 2 on four faults in its own cases, kept as `-run1` and `-run2`). The
findings being answered are review 2's (`$R/t030o43-review2.md`, reproduced in
`$R/t030o43-review2-verify.{sh,log,rc}`). The member classification is the last
section of `$R/t030o43-parser-classes.md`. The mutation matrix is
`$R/t030o43-mutations.sh` (v3; dry run `-v3-dry.{log,rc}`); the dev runs are
`$R/t030o43-dev3-quick.*` (the one failure is a fixture fault fixed before
the next run), `t030o43-dev4-quick.*` and, when present, `-full` and
`-full-locale`.

## Attack surface (derive members from the mechanism, not from these examples)

1. The step (`_VF_AWK_WS`, `_VF_AWK_WSLINE`). Is the set exactly the 19
   non-ASCII Unicode White_Space characters, as UTF-8? Is VT the right
   byte? Find any grammar the harness applies where VT reads differently from
   how a UTF-8 locale read U+00A0 before the pin (`[[:cntrl:]]`, default
   field splitting, `index`, bracket classes, `tolower`, `length`), and any
   value that now carries a VT where it is compared, displayed, recorded or
   hashed. Is the claim that the fence tracker (fence, indentation, comment,
   raw HTML) reaches the same state on the mapped line as on the line as
   written true in every branch, so that `vf_report_block` (raw) and
   `vf_reports` (mapped) always agree on quoting?
2. The member derivation. Does every parser of author text in the harness
   files take the step, or carry a correct argument for not taking it? Does
   any value the harness passes on (a command it runs, a path it opens or
   compares, a name it looks up) still come from the mapped line?
3. The prior-review manifest pass. Can any spelling still drop a finding, a
   tier or a Class binding in silence, in either locale? Is any real or
   plausible manifest now refused? Does its grammar match the canonical
   finding parser's where the Decisions entry says it does (headings, field
   lines at any indentation, duplicates, value trimming)?
4. The STATUS view of the input identity. Is it a superset of what the
   authorization scanner reads in every shape (quoting, headings, duplicates,
   unclosed constructs)? Does it change any shipped STATUS identity (the
   measurement says not)? Is anything the scanner reads left unhashed?
5. `vf_contract` routing and its three callers; the artifact-name rule (the
   closed wrapper set, globbing off, tokens ending at any whitespace); the
   analyzer's Agent path; `vf_fm_value`'s values taken as written (quoted
   values, inline comments, a closing fence followed by such whitespace).
6. The fixtures and matrix v3: does each guard fail its fixture with its
   exact diagnostic when removed, and is each argued equivalent (W20, W30,
   W33, M04, E01, E02) really equivalent? Can a fixture pass for the wrong
   reason?
7. The wording: the kernel comments, the contract paragraphs, the task
   block's Acceptance and the two Decisions entries — do they state what the
   code does?
8. Regressions against the review-2 state and the pre-delta state (recorded
   history, the identity, real use).

## Known and recorded — do not report as new, but do report any place that claims them fixed

Everything in `t030o43-review-brief.md`'s list, and the items the first
2026-09-29 Decisions entry records as not in scope: a waiver's `by=` with a
blank value authorizes; `system-map.sh` and `sdd-doctor.sh` parse under the
pin; a C1 control byte in stack.yml; invisible characters that are not
White_Space (U+200B, U+2060, U+FEFF mid-line, U+00AD); CRLF outside the
manifest (a canonical round heading with CR stays refused); the byte pair C2
A0 in a Latin-1 file is read as UTF-8; an artifact name glued to a full-width
colon fails, as its ASCII analogue does.

## Method this spec requires

As in `t030o43-review-brief.md`: derive each criterion from the grammar the
code reads, test a proposed rule against the real recorded history before
proposing it, mutation-isolate guards in both directions with byte-identical
restores, assert exact diagnostics, and read every exit code back.
