# Independent review brief, focused delta review 6 — T030o41 (spec 003), 2026-09-25

You are an independent, READ-ONLY reviewer. Do not create, modify, move or
delete anything in the worktree. Do not run `spec-gate.sh round`, `floor`,
`checkpoint` or `accept`, and do not write any authorization line. Work in a
COPY under your own private directory with `TMPDIR` pointing there, and remove
the copy when you finish. Check `df -h /` and `sysctl vm.swapusage` first (about
8 GiB free; swap is nearly full and shares the volume; a copy is about 170 MB).
Run single test functions, not whole suites.

**Run no test suite, and no test function, in the worktree itself.** A suite
run from the live checkout deleted a live file earlier through a helper defect.
Run everything in your copy, and check your copy's
`git status --porcelain --ignored` before and after each run. Build the copy
from the worktree's own enumeration with `GIT_OPTIONAL_LOCKS=0`, for example
`git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf -`.
If you probe a failed fixture build, do it in a way that cannot write outside
your sandbox even on a writable root (review 5's R5-2 shape).

**Write your report progressively** to `REPORT_PATH` (given below, outside
your copy and outside the worktree): create it first with a header saying IN
PROGRESS, append each finding as soon as you have confirmed it, and finish with
the Held and Not-reached sections and a final line `REVIEW COMPLETE`.

Worktree: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`
Spec dir: `.specify/specs/003-gate-round-reduction-and-token-discipline` (below: `$S`)

## Inputs

- The delta under review: `$S/notes/verification/reports/t030o41-session4c.diff`
  (7 files), the repairs of the fifth review's findings. The pre-delta
  versions of every file it edits are at `PRE_DIR` (read them, do not modify
  them). Everything before it was reviewed by five earlier passes, the last
  of them `t030o41-review5.md` over `t030o41-session4b.diff`; attack the rest
  only where this delta reaches it.
- Why each change exists: the LAST TWO entries of the Decisions log in
  `$S/STATUS.md` (2026-09-25: review 5's outcome with the user's decision to
  include R5-4, then the derived repairs), review 5's report
  `t030o41-review5.md`, and the invoker's reproduction
  `t030o41-review5-verify.{sh,log,rc}`.
- The task block `T030o41` in `$S/tasks.md`.
- The invoker's runs: `t030o41-dev11.sh` with `t030o41-dev11-{quick,full}.{log,rc}`
  (quick runs 1 and 2 are void, see `t030o41-dev11-quick-void.note`); the full
  suite runs plainly and once under a widened hostile environment.
- The mutation matrix of record, `t030o41-mutations.sh` (v5, dry run only:
  `t030o41-mutations-v5-dry.{log,rc}`), a probe run of its uncertain v5 rows
  (`t030o41-mutations-v5-probe.{log,rc}`, exit 1: two rows mislabelled, then
  relabelled from the measurement, E16 to K73 and E13 split into K74 and a
  narrowed E13), and a second probe of those three rows
  (`t030o41-mutations-v5-probe2.{log,rc}`). K74 (`git rm -f --cached` restored to
  raw git) was then measured timing-dependent and taken out of the matrix
  (`t030o41-mutations-v5-k74.note` with `-k74-rerun-{1,2}.log`); judge that
  decision too. Judge whether each new guard
  has a row, whether mutants use the exact pre-delta lines, whether each
  argued equivalent is argued correctly, and whether the `@hostile` harness
  and the runners' build-failure check judge what their rows claim. Do not
  run the whole matrix.

Deliberately NOT repaired and recorded as open (do not report as new, but do
report any place that claims them fixed): the capture harness's `bash`
startup environment; the kernel's own reads and writes of a fixture
repository under the ambient git configuration and environment (a global
excludes file can hide a file a fixture plants untracked); the analyzer's
field-grammar defect; the umbrella-only in-place readers of an ignored
`system-map.yml`/`registry.yml`.

## Attack surface (derive members from the mechanism, not from these examples)

1. R5-4. The rule: a fixture's git write starts from none of the caller's git
   environment (every exported `GIT_*` name, and `EMAIL`, removed) and then
   pins its own. Is any input that decides whether or how a fixture repository
   is built still inherited, environment or configuration? Does removing the
   whole family break anything a fixture legitimately needs?
2. R5-2 and R5-5. The rule: a fixture helper whose output a caller uses as a
   path never leaves it an empty one, and a failed build fails its test by
   name whatever the caller does with the status (`fixture_build_failed`,
   checked by `t_run_all`). Is any build or path-producing fixture helper left
   outside it? Can the record leak between tests, or fail a test that did not
   fail a build? Is the nested-suite fixture a genuine negative?
3. R5-1 and R5-3. Does the widened hostile environment reach every operation
   `fixture_git` guards, and does every "nothing is reported" control now
   carry a positive canary?
4. Anything the Decisions entries, the contract paragraph
   (`templates/verification-contract.md`) or the task text claims that the
   code does not do.

## Reply format

For each finding: a title; severity (blocking only for a reproduced
wrong-result, data-loss, regression or crash, otherwise minor); `file:line`;
the exact reproduction you ran, in your copy, and its observed output; and the
smallest class-wide fix. Then list what you attacked that held, and what you
did not reach. Do not soften. Your final reply may be short; the report file is
the deliverable.
