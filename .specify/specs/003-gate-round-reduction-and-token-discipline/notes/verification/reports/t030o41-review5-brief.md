# Independent review brief, focused delta review 5 — T030o41 (spec 003), 2026-09-25

You are an independent, READ-ONLY reviewer. Do not create, modify, move or
delete anything in the worktree. Do not run `spec-gate.sh round`, `floor`,
`checkpoint` or `accept`, and do not write any authorization line. Work in a
COPY under your own private directory with `TMPDIR` pointing there, and remove
the copy when you finish. Check `df -h /` and `sysctl vm.swapusage` first (about
10 GiB free; swap is nearly full and shares the volume; a copy is about 170 MB).
Run single test functions, not whole suites.

**Run no test suite, and no test function, in the worktree itself.** A suite
run from the live checkout deleted a live file earlier through a helper defect.
Run everything in your copy, and check your copy's
`git status --porcelain --ignored` before and after each run. Build the copy
from the worktree's own enumeration with `GIT_OPTIONAL_LOCKS=0`, for example
`git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf -`.

**Write your report progressively** to `REPORT_PATH` (given below, outside
your copy and outside the worktree): create it first with a header saying IN
PROGRESS, append each finding as soon as you have confirmed it, and finish with
the Held and Not-reached sections and a final line `REVIEW COMPLETE`. Two
earlier reviewers died on the session limit before replying; a report file is
the only thing that survives that.

Worktree: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`
Spec dir: `.specify/specs/003-gate-round-reduction-and-token-discipline` (below: `$S`)

## Inputs

- The delta under review: `$S/notes/verification/reports/t030o41-session4b.diff`
  (7 files), the repairs of the fourth review's findings. The pre-delta
  versions of every file it edits are at `PRE_DIR` (read them, do not modify
  them). Everything before this delta was reviewed by four earlier passes,
  the last of them `t030o41-review4.md` over `t030o41-session4.diff`; attack
  the rest only where this delta reaches it.
- Why each change exists: the LAST TWO entries of the Decisions log in
  `$S/STATUS.md` (2026-09-25: review 4's outcome with the user's decision to
  include F2, then the derived repairs), review 4's report `t030o41-review4.md`,
  and the invoker's reproduction `t030o41-review4-verify.{sh,log,rc}`.
- The task block `T030o41` in `$S/tasks.md`.
- The invoker's runs: `t030o41-dev10.sh` with `t030o41-dev10-{quick,full}.{log,rc}`
  (the full suite passes plainly and once under a hostile git environment).
- The mutation matrix of record, `$S/notes/verification/reports/t030o41-mutations.sh`
  (v4, dry run only: `t030o41-mutations-v4-dry2.{log,rc}`), and a probe run of
  its F2 rows (`t030o41-mutations-v4-probe.{log,rc}`, exit 1 on one row that was
  then relabelled with an argument, K60 to E15). Judge whether each new guard
  has a row, whether mutants use the exact pre-delta lines, whether each
  argued equivalent is argued correctly, and whether the `@hostile` harness
  judges what its rows claim. Do not run the whole matrix.

Deliberately NOT repaired and recorded as open (do not report as new, but do
report any place that claims them fixed): the capture harness's `bash`
startup environment (`BASH_ENV`, `ENV`, `SHELLOPTS`, `BASHOPTS`, exported
functions); the kernel's own reads and writes of a fixture repository running
under the ambient git configuration (a global excludes file can hide a file a
fixture plants untracked); the analyzer's field-grammar defect; the in-place
readers of an ignored `system-map.yml`/`registry.yml` reached only for
umbrella specs.

## Attack surface (derive members from the mechanism, not from these examples)

1. F2. The rule: every git command in `tests/` that writes a repository runs
   through `fixture_git` (a pinned, empty configuration via
   `git_config_pinned`, an empty fixture-owned template directory, no system
   attributes, a fixed identity), and a fixture repository that cannot be
   built fails by name, while git reads and the kit's code under test keep the
   ambient configuration. Is any repository write in `tests/` left outside
   it, under any spelling? Is any input that decides whether or how a fixture
   repository is built still ambient (environment as well as configuration)?
   Does pinning change what any fixture tests, or let one pass for the wrong
   reason (the empty template, the sandbox-local `.fixture-git` directory, the
   fixed identity)? Is `fixture_repository_cases` a genuine negative in both
   directions? Is the parity argument (reads stay ambient) sound?
2. F1. Does the XDG fixture now prove every pinned input it can plant?
3. F3. The matrix rows above.
4. F4 and the rest: anything the Decisions entries, the contract paragraph
   (`templates/verification-contract.md`) or the task text claims that the
   code does not do.

## Reply format

For each finding: a title; severity (blocking only for a reproduced
wrong-result, data-loss, regression or crash, otherwise minor); `file:line`;
the exact reproduction you ran, in your copy, and its observed output; and the
smallest class-wide fix. Then list what you attacked that held, and what you
did not reach. Do not soften. Your final reply may be short; the report file is
the deliverable.
