# Independent review brief, focused delta review 7 — T030o41 (spec 003), 2026-09-25

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

- The delta under review: `$S/notes/verification/reports/t030o41-session4d.diff`
  (7 files), the repairs of the sixth review's findings. The pre-delta
  versions of every file it edits are at `PRE_DIR` (read them, do not modify
  them). Everything before it was reviewed by six earlier passes, the last
  of them `t030o41-review6.md` over `t030o41-session4c.diff`; attack the rest
  only where this delta reaches it.
- Why each change exists: the LAST TWO entries of the Decisions log in
  `$S/STATUS.md` (2026-09-25: review 6's outcome, which also supersedes three
  labels of the review-5 repairs entry, then the derived repairs), review 6's
  report `t030o41-review6.md`, and the invoker's reproduction
  `t030o41-review6-verify.{sh,log,rc}`.
- The task block `T030o41` in `$S/tasks.md`.
- The invoker's runs: `t030o41-dev12.sh` with `t030o41-dev12-{quick,full}.{log,rc}`
  (the full suite runs plainly and once under the widened hostile environment).
- The mutation matrix of record, `t030o41-mutations.sh` (v6, dry run only:
  `t030o41-mutations-v6-dry.{log,rc}`), and a probe run of every new or
  rewritten v6 row (`t030o41-mutations-v6-probe.{log,rc}`, exit 0). v6 adds a
  `@no-writes` judge (a `git` first on `PATH` refusing every repository write,
  under `sandbox-exec` confined to the matrix directory) and a `record` row
  kind (the unmutated judge must leave the named build-failure record, and the
  mutant is killed when the name is gone). Earlier label changes are recorded
  in the Decisions entries and in `t030o41-mutations-v5-k74.note` (the one
  unjudged, timing-dependent site). Judge whether each new guard has a row,
  whether mutants use the exact pre-delta lines, whether each argued
  equivalent is argued correctly, and whether the `@hostile` and `@no-writes`
  judges and the `record` kind judge what their rows claim. Since the probe,
  the matrix also gained `SHARD=i/n` (a harness-only change: each shard takes
  every n-th row in its own copy, and only shard 0 runs the baselines); judge
  that the shards cover every row once. Do not run the whole matrix.
- This is the last focused review of T030o41 (Decisions, 2026-09-25, the
  user's decision on pace): report every finding as usual; the invoker repairs
  only blocking ones here and records the rest.

Deliberately NOT repaired and recorded as open (do not report as new, but do
report any place that claims them fixed): the capture harness's `bash`
startup environment; the kernel's own reads and writes of a fixture
repository under the ambient git configuration and environment (a global
excludes file can hide a file a fixture plants untracked); the analyzer's
field-grammar defect; the umbrella-only in-place readers of an ignored
`system-map.yml`/`registry.yml`.

## Attack surface (derive members from the mechanism, not from these examples)

1. R6-4. The suite-start clearing of git's repository-local names is now
   judged where it acts, at `tests/helpers.sh` load. Is it a genuine negative
   for every name, and does any other matrix row now judge a line a newer
   guard shields?
2. R6-1. The rule: `fixture_git` never lets git climb out of the fixture's
   sandbox to find a repository (`GIT_CEILING_DIRECTORIES="$SANDBOX"`). Can a
   fixture write still reach a repository outside the sandbox, by another
   route? Does the ceiling break any fixture that legitimately finds its
   repository from a subdirectory?
3. R6-2. The rule: every fixture helper whose output a caller uses as a path,
   and which can fail to copy kit content or build a repository, records the
   failure and still prints its sandbox path. Is any such helper left outside
   it? Are the four new fixtures genuine negatives in both directions?
4. R6-3. Does each site check now have a row that can fail, and can a
   `record` row pass for the wrong reason?
5. Anything the Decisions entries, the contract paragraph
   (`templates/verification-contract.md`) or the task text claims that the
   code does not do.

## Reply format

For each finding: a title; severity (blocking only for a reproduced
wrong-result, data-loss, regression or crash, otherwise minor); `file:line`;
the exact reproduction you ran, in your copy, and its observed output; and the
smallest class-wide fix. Then list what you attacked that held, and what you
did not reach. Do not soften. Your final reply may be short; the report file is
the deliverable.
