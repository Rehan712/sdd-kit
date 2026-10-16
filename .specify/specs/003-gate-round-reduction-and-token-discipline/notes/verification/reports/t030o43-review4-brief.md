# Focused review 4 brief — T030o43's review-3 repairs, 2026-09-30

Every operational rule of `t030o43-review-brief.md` (read it first, in the same
directory) applies unchanged: read-only, a private copy with `TMPDIR` inside
it, no suite or test function in the worktree, one copy and one suite at a
time, a progressive report at `REPORT_PATH` ending `REVIEW COMPLETE`, severity
per finding (blocking: a reproduced wrong result, data loss, regression or
crash; otherwise minor) with an exact reproduction and the smallest
class-wide fix. Check `df -h /`, `sysctl vm.swapusage` and `pmset -g batt`
first; free disk is about 16 GiB and the Mac may be on battery. This is a
SHORT focused review: prefer depth on the attack surface below over breadth,
and stop after about two hours of work with the Held and Not-reached sections
written.

## Scope

Only the session-9 delta: `$R/t030o43-session9.diff` (8 files: the kernel,
`spec-task.sh`, `sdd-analyze.sh`, three suites, the contract, the task block).
The files as review 3 saw them are at `REVIEWED_DIR` (given in your prompt),
proven by `$R/t030o43-rev4-base.{sh,log,rc}`: reversing this session's pairs
files (`$R/t030o43-edits/kernel-6.pairs`, `spec-task-3.pairs`,
`sdd-analyze-3.pairs`, `tgc-6.pairs`, `tsa-7.pairs`, `tsg-8.pairs`,
`vc-4.pairs`, `tasks-fix-4.pairs`) from the live files gives them, and the
chain of `t030o43-base-9.sh` from there reaches the source-70c71885 records.

Why each change exists: the three newest Decisions entries in `$S/STATUS.md`
(dated 2026-09-30): review 3's outcome as reproduced, the user's scope
decisions, the rule as measured with its members and not-members, one
correction to review 3's proposed R3-F5 fix, and the task-block correction.
The findings being answered are review 3's (`$R/t030o43-review3.md`,
reproduced in `$R/t030o43-review3-verify.{sh,log,rc}`; R3-F6 measured in
`$R/t030o43-r3f6-mawk.{sh,log,rc}`). The measurement before adoption is
`$R/t030o43-measure-9.{sh,log,rc}` (run 1, `-run1`, failed on two faults of
its own). The pairs were generated from the files' exact lines by
`$R/t030o43-edits/genpairs.pl` from `t030o43-edits/session9-new/`. The
mutation matrix is `$R/t030o43-mutations.sh` (v4; dry run
`-v4-dry.{log,rc}`); the dev runs are `$R/t030o43-dev5-{quick,full,full-locale}.*`.

## Attack surface (derive members from the mechanism, not from these examples)

1. Values as written (R3-F4). The rule: the mapped line decides; every value
   passed on (catalog, record, another program, a comparison with a value that
   did not come through the step) comes from `vf_original` by the same anchor,
   trimmed by `vf_wstrim`. Is the member list complete: every value reaching a
   `rec`, `print`, `emit` or outside comparison in the sixteen programs that
   take the step? Does any written value then meet a class-based test that
   reads raw U+00A0 bytes differently from VT (a `[[:space:]]` regex, `split`
   on a class, `index`, a trim) inside the pass? Are the argued not-members
   (manifest pass, waiver scanner, `vf_ac_catalog`, names, displays) right?
   Is any comparison now written-vs-mapped (one side through the step, the
   other not)? Start from review 3's Not-reached list: the analyzer's
   displayed values, `spec-task.sh list`, the `vf_reports` catalog values.
2. The manifest pass. The field rule decided by the label (emphasized label or
   not continued by a letter, digit or hyphen), the value after its own label
   only, the catch-all for non-heading `#`-run Finding lines, and the outside
   rule (prose only until a finding ID appears after the last heading). Can any
   spelling still drop a finding, a tier or a Class binding in silence? Is any
   real or plausible manifest now refused (the measurement found none over the
   recorded notes)? Is the ID condition itself too broad or too narrow (the
   ID-shaped pattern `[A-Za-z][A-Za-z0-9]*-[0-9]`, e.g. `UTF-8`)?
3. The canonical `value()` anchored on the first bold label, from the line as
   written: does it change any sealed round's parse, digest, tally or
   completion check (the measurement says only nine free-text Scenario and
   Reproduced catalog values change, read by nobody)? Any identity field or
   finding field whose first bold label is not its key?
4. Default field splitting (R3-F6): is any remaining default-split read of a
   mapped line left anywhere in a member? Is `vf_fields` equivalent to POSIX
   default splitting for every line it now reads?
5. Stages (R3-F11): `vf_heading_text` in `vf_config`, the inventory, the task
   pass, `spec-task.sh` and the analyzer; is any stage reader or comparison
   left that trims differently?
6. The matrix criterion (R3-F8) and E02 (R3-F9).
7. The fixtures and matrix v4: does each new row fail its fixture with its
   exact diagnostic when mutated, and is each argued equivalent (W27, W28,
   W40-W43) really equivalent? Can a fixture pass for the wrong reason?
8. The wording: the kernel comment above `_VF_AWK_WS`, the manifest-pass
   comment, the contract sentences, the task block's Acceptance and the three
   2026-09-30 Decisions entries: do they state what the code does?
9. Regressions against the review-3 state (REVIEWED_DIR) and the recorded
   history.

## Known and recorded — do not report as new, but do report any place that claims them fixed

Everything in `t030o43-review-brief.md`'s and `t030o43-review3-brief.md`'s
lists; R3-F7 (the STATUS identity view does not carry the quoting state that
enters the Decisions log) and R3-F10 (the artifact-name wrapper set is an
enumeration), recorded as open extent; a bold `**Finding G-042**` line with no
`#` run inside another finding, whose Severity then falls into a Class-only
finding above it (R3-F3's precondition beyond the heading catch-all, recorded
extent); a `##` heading with no space after it is a stage to the inventory and
not to `vf_config` (pre-existing); Ubuntu 24.04's mawk 20240123 is not executed
(the rule no longer depends on it).

## Method this spec requires

As in `t030o43-review-brief.md`: derive each criterion from the grammar the
code reads, test a proposed rule against the real recorded history before
proposing it, mutation-isolate guards in both directions with byte-identical
restores, assert exact diagnostics, and read every exit code back.
