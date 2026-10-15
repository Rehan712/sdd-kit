# Independent review brief — T030o44 (spec 003, round-13 O-018 with O-019), 2026-10-01

You are an independent, READ-ONLY reviewer of one repair. Everything here is a claim to attack, not
authority; the receipts outrank this text.

## Operational rules

- Create, modify, move or delete NOTHING in the worktree. Do not run `spec-gate.sh round`, `floor`,
  `checkpoint` or `accept` in it, and write no authorization line.
- **Run no test suite and no test function in the worktree itself** (a suite run from the live checkout
  once deleted a live file through a helper defect). Build a COPY under your own private directory (for
  example `/private/tmp/rev-t030o44`) from the worktree's enumeration with `GIT_OPTIONAL_LOCKS=0`
  (`git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf -`), make it its own git
  repository, set `TMPDIR` inside it ENDING IN `/` (macOS's default spelling, under which a capture of
  record once failed), and check its `git status --porcelain --ignored` before and after each run. To run
  one fixture function, strip the trailing `t_run_all` from its suite into a dot-file and call the
  function in a subshell with a fresh `SANDBOX`, as `$R/t030o43-mutations.sh`'s `judge` does.
- Check `df -h /`, `sysctl vm.swapusage` and `pmset -g batt` first: free disk is about 11 GiB and swap
  shares the volume; the Mac may be on battery. Keep at most two copies and one whole suite at a time
  (a whole-suite run takes about 20 minutes); prefer single functions.
- You may run a throwaway container of an image ALREADY on disk, within these limits only: `--rm`,
  `--network none`, your copy mounted read-only, nothing pulled, no other container touched, and Docker
  itself never stopped, started or restarted. Do not touch `mv-localstack` or any other container.
- **Write your report progressively** to `REPORT_PATH` (given in your prompt, outside the worktree):
  create it first with a header saying IN PROGRESS, append each finding as soon as it is confirmed, and
  finish with Held and Not-reached sections and a last line `REVIEW COMPLETE`. For each finding give its
  severity (blocking: a reproduced wrong result, data loss, regression or crash; otherwise minor), the
  exact reproduction, whether it predates the delta, and the smallest class-wide fix. Return the report
  verbatim as your final message. Remove your copies when you finish.
- Never pipe a suite through `tail`; capture exit codes and read them back.

Worktree: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`.
Spec dir `$S` = `.specify/specs/003-gate-round-reduction-and-token-discipline`; receipts `$R` = `$S/notes/verification/reports`.

## Inputs

- The findings: round 13's O-018 and O-019, in `$R/opponent-round13.md`. Neither reader of finding records
  read or refused every line that carries a finding's tier or opens a finding, so a CLEARED round sealed
  over a lowered blocking tier; a sub-heading inside a manifest finding refused its field lines.
- The delta under review: `$R/t030o44-final.diff` (4 files: `scripts/verification-lib.sh`,
  `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`, `templates/verification-contract.md`), plus
  the T030o44 task block in `$S/tasks.md`. It is two applies: `t030o44-session1.diff`
  (`$R/t030o44-apply-1.{sh,log,rc}`: literal pairs `$R/t030o44-edits/{kernel-1,tgc-1,tsg-1,vc-1}.pairs`,
  NEW texts in `t030o44-edits/new/`, and the line-number script `t030o44-edits/fixtures-1.pl`), then
  `t030o44-session2.diff` (`t030o44-apply-2.{sh,log,rc}`: `kernel-2.pairs` replaced a `subheading` flag in
  the manifest pass with the catch-all's own exclusion of ATX headings and dropped two dead `flevel=0`
  assignments; `tgc-2.pairs` added one fixture row). The measured candidate was session 1's kernel; session 2's
  kernel change is argued equivalent in behaviour and is not separately measured. The pre-delta files are the
  live files with both diffs reversed (`t030o44-final.{sh,log,rc}` proves them against
  `$R/t030o44-edits/pre-apply.sha256`).
- Why each change exists: the five newest Decisions entries in `$S/STATUS.md` (dated 2026-10-01): round
  13's outcome; the user's decision; the reproduction; the rule, derived and measured, with its stated
  consequences and recorded extent; the round-14 waiver.
- The invoker's evidence: the reproduction before repair `$R/o018-repro.{sh,log,rc,time}` (CUR and PRE,
  every reported spelling plus siblings derived from the mechanisms, directly and end to end); the
  measurement before adoption `$R/o018-measure.{sh,log,rc,time}` (run 1 kept as `-run1.*` with a note);
  the dev runs `$R/t030o44-dev.sh` with `t030o44-dev1-quick.*`, `t030o44-dev2-gc.*` (copies with the
  candidate applied), `t030o44-dev3-{full,full-locale}.*` (copies of the session-1 tree) and `t030o44-dev4-{full,full-locale}.*`
  (copies of the final tree; they may still be running when you start).

## Attack surface (derive members from the mechanism, not from these examples)

1. The label reader `vf_label` (`_VF_AWK_LABEL`). It claims to read a line's rendered text: inline raw
   HTML dropped, numeric character references decoded, the first word after any run of non-letter,
   non-digit characters, ordered-list numbers and task checkboxes. Is any line a reader of the rendered
   Markdown sees as carrying a Class or Severity still read as prose by either pass, inside a finding?
   Conversely, does it now refuse a real or plausible record line, in a manifest or in a canonical
   finding, that the recorded history or a reasonable report would hold (the invoker records one such
   consequence: a finding line beginning with a code span that holds a label)? Is the HTML stripping
   sound (an unclosed `<!--`, a `>` inside an attribute, an autolink, a `<` in prose)?
2. The manifest pass. Every finding needs one readable Class and one readable Severity; a heading deeper
   than the Finding heading keeps the finding open (O-019) and is classified like any other line (the
   non-heading catch-all excludes every ATX heading); a Finding-like heading the pass cannot open
   is refused. Can any spelling still drop a finding, a tier or a Class binding in silence? Is any real or
   plausible manifest refused? Is the interplay with the outside rule (`idseen`) and `flevel` right after
   a refused Finding heading, at END, and across several findings?
3. The canonical pass. A heading `vf_finding_heading` reads, other than `### Finding <ID>`, is refused; so
   is a non-heading `#` run plus Finding; a heading as shallow as `###` now closes a finding; a field line
   outside any finding is refused; inside a finding a Class or Severity label line that is not the field
   line is refused; the duplicate key ignores indentation; every new rule stops at the completion
   marker. Does any of this change a sealed round's parse, catalog, tally or digest (the measurement says
   none for 001/002/003)? Can a CLEARED round still rest on a tier no reader counted? Does closing at
   `###` change any section-body or Held-up check? Are reality-check reports affected?
4. Regressions: the full recorded history; every report the kit's own fixtures and templates write; the
   golden example; the README's documented workflow; the after-marker rule; legacy rounds.
5. The fixtures: `report_record_line_cases` (`test_reports_and_tally`) and `round_record_line_cases`
   (`test_rounds`). Can any assertion pass for the wrong reason (a refusal from another rule, a fixture
   that never reaches the line it names)? Do the 13 manifests that gained a Severity line still test what
   they tested? Is the shipped `class-only` positive's conversion to a refusal justified?
6. The wording: the kernel comments above `_VF_AWK_LABEL`, the manifest pass and the canonical rules, the
   contract paragraph, the task block's Acceptance and the Decisions entries. Do they say what the code
   does, no more?
7. Anything else you derive. You may expand into unchanged code.

## Known and recorded — do not report as new, but do report any place that claims them fixed

The O-004 omission extent (a round can omit a known finding; a finding written in prose only, with no
Finding heading and no canonical field line, is not a record); a label written with a named character
reference or split by a zero-width character; Status, Prior and the other canonical fields not
label-checked; review 3's R3-F7 and R3-F10 and review 4's R4-F3, R4-F5, R4-F6 and R4-F8 from T030o43; a
finding opened by no heading at all inside another finding; a manifest mixing read findings with a table
finding; the harness-level bash startup environment and option variables; `TZ`; `PATH` choosing an
undeclared tool; shipped 002's locale-dependent reset parsing; T030o42 review F2; T030o41 review 7's F1,
F2, F4 and the unjudged K74 site; the kernel's ambient fixture reads; the analyzer field grammar with
AC-023's narrowed reading; umbrella-only readers; the opponent-only totals, verdict and downgrade guards;
README's missing Verification-Return grammar and completion marker; 001's legacy report failing `tally`
at exit 3; the retained unexamined surfaces in STATUS's Open questions.

## Method this spec requires

1. Derive each criterion from the grammar or production the code reads, with its source. An enumeration
   of reported spellings is satisfiable while the class stays open.
2. Test a proposed rule against the real recorded history (`$S/notes/opponent.md`, 001's and 002's
   reports, the 2026-09-09 manifest) before proposing it.
3. Mutation-isolate guards in both directions, and restore byte-identically (`cmp`).
4. Assert exact diagnostics, never exit codes alone.
5. Hunt for shipped POSITIVES that assert an attack at rc=0.
