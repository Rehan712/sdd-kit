# Independent review brief, focused delta review 4 — T030o41 (spec 003), 2026-09-24

You are an independent, READ-ONLY reviewer. Do not create, modify, move or
delete anything in the worktree. Do not run `spec-gate.sh round`, `floor`,
`checkpoint` or `accept`, and do not write any authorization line. Work in a
COPY under your own private directory with `TMPDIR` pointing there, and remove
the copy when you finish. Check `df -h /` and `sysctl vm.swapusage` first (about
8 GiB free; swap is nearly full and shares the volume; a copy is about 170 MB).
Run single test functions, not whole suites.

**Run no test suite, and no test function, in the worktree itself.** A suite
run from the live checkout deleted a live file earlier today through a helper
defect. Run everything in your copy, and check your copy's
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

- The delta under review: `$S/notes/verification/reports/t030o41-session4.diff`
  (13 files), the repairs of the third review's findings. The pre-delta
  versions of every edited file are at `PRE_DIR` (read them, do not modify
  them); they were proven byte-exact against the recorded pre-delta source
  (`$S/notes/verification/reports/t030o41-s4-pre-verify.{sh,log,rc}`).
  Everything before this delta was reviewed by three earlier passes; attack the
  rest only where the delta reaches it.
- Why each change exists: the LAST entry of the Decisions log in
  `$S/STATUS.md` (session 4, the R3 repair decisions), the third review's
  partial report `$S/notes/verification/reports/t030o41-review3-partial.md`
  with the invoker's reproductions `t030o41-review3-verify{-r31.log,.sh,.log,.rc}`,
  and the member search `t030o41-r34-search.sh` with its run
  `t030o41-r34-search-pre.{log,rc}`.
- The task block `T030o41` in `$S/tasks.md`.
- The mutation matrix of record, `$S/notes/verification/reports/t030o41-mutations.sh`
  (v3, dry run only so far): judge whether each new guard has a mutant, whether
  the mutants use the exact pre-delta lines, and whether an argued equivalent or
  a witness is argued correctly. Do not run the whole matrix.

Deliberately NOT repaired and recorded as open (do not report it as new, but
do report any place that claims it is fixed): the capture harness runs every
command under `bash -o pipefail -c`, whose startup reads `BASH_ENV`, `ENV`,
`SHELLOPTS`, `BASHOPTS` and exported functions before any check starts. Also
recorded and out of scope: the analyzer's field-grammar defect, and the in-place
readers of an ignored `system-map.yml`/`registry.yml` reached only for umbrella
specs.

## Attack surface (derive members from the mechanism, not from these examples)

1. R3-1. The rule: git's repository-local names (`git rev-parse
   --local-env-vars`) are cleared for git's own processes only, never for the
   shell whose environment records the snapshot writes. Is any git process the
   kernel runs (snapshot, enumeration, capture, gate roots, anything the delta
   reaches) still inheriting them? Is any declared name still hashed as unset,
   or any undeclared one still able to move the identity? Does the inner
   subshell change behaviour on a failure path (a submodule entry, a failing
   `cat-file`, a trap, `set -u`, Bash 3.2)? Is the new fixture a genuine
   negative in both directions?
2. R3-3. The rule: a fixture that plants git configuration pins all of it
   (`git_config_pinned`). Is anything else that decides git's configuration or
   its excludes left to the ambient environment in that fixture, or in any
   other fixture that plants configuration? Does the fixture now prove the pin?
3. R3-2. The rule: a host-kit fixture binds every load-time alias that names a
   live-kit directory in its scope (`on_host_kit`, plus `EXAMPLE` and
   `FIXTURES` where a suite defines them), so it judges whatever spelling its
   site reads. Is any whole-kit host call, alias or site left out? Does binding
   `SCRIPTS` to the host change what any fixture actually tests, or let one pass
   for the wrong reason? Are the two partial-tree exceptions sound?
4. R3-4. Is there any remaining read of live-kit content in `tests/` that is a
   directory walk, a copy or a glob outside the enumeration (`copy_kit`,
   `kit_files`, `vf_source_paths`, `vf_path_content`)? Is the new fixture a
   genuine negative?
5. Anything the Decisions entry, the contract paragraph
   (`templates/verification-contract.md`) or the task text claims that the
   code does not do.

## Reply format

For each finding: a title; severity (blocking only for a reproduced
wrong-result, data-loss, regression or crash, otherwise minor); `file:line`;
the exact reproduction you ran, in your copy, and its observed output; and the
smallest class-wide fix. Then list what you attacked that held, and what you
did not reach. Do not soften. Your final reply may be short; the report file is
the deliverable.
