# Independent review brief, focused delta review — T030o41 (spec 003), 2026-09-24

You are an independent, READ-ONLY reviewer. Do not create, modify, move or
delete anything in the worktree. Do not run `spec-gate.sh round`, `floor`,
`checkpoint` or `accept`, and do not write any authorization line. Work in a
COPY under your own private directory with `TMPDIR` pointing there, and remove
it when you finish. Check `df -h /` first (about 6.5 GiB free; swap shares the
volume; a copy is about 170 MB).

**Run no test suite, and no test function, in the worktree itself.** A suite
run from the live checkout deleted a live file earlier today through a helper
defect. Run everything in your copy, and check your copy's
`git status --porcelain --ignored` before and after each run.

Worktree: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`
Spec dir: `.specify/specs/003-gate-round-reduction-and-token-discipline` (below: `$S`)

## Inputs

- The delta under review: `$S/notes/verification/reports/t030o41-session3.diff`
  (15 files), the repairs made after the second review pair. Everything
  before it was reviewed by two earlier pairs; attack the rest only where the
  delta reaches it.
- Why each change exists: the last two 2026-09-24 entries of the Decisions log
  in `$S/STATUS.md` (the second pair's outcome with the user's scope decisions,
  then the derived repairs), and the second pair's reports
  `$S/notes/verification/reports/t030o41-review2-pass{C,D}.md` with the
  invoker's reproductions `t030o41-review2-verify{,-c}.{sh,log,rc,note}`.
- The task block `T030o41` in `$S/tasks.md`.

Deliberately NOT repaired and recorded as open (do not report it as new, but
do report any place that claims it is fixed): the capture harness runs every
command under `bash -o pipefail -c`, whose startup reads `BASH_ENV`, `ENV`,
`SHELLOPTS`, `BASHOPTS` and exported functions before any check starts.

## Attack surface (derive members from the mechanism, not from these examples)

1. Does each repair close its class, not only the reproduced shape? The
   governing rule is parity: a reuse-checked reader enumerates the repository
   under exactly the environment and configuration the identity enumerates
   under. Look for any remaining difference between how the identity
   (`vf_snapshot`, `vf_source_paths`) and a reader (the suites, `tests/run.sh`,
   `tests/shellcheck.sh`, `kit_files`, `copy_kit`, the O-010 scan, the AC-023
   loop) resolve the repository: environment the suites clear or keep, git's
   configuration, git's repository-local variables, spelling of the root,
   copies of live-kit content anywhere in `tests/`.
2. Anything the delta broke: the kernel's `vf_git_local_unset`/`vf_git` under
   `set -u` and Bash 3.2; `vf_source_paths` becoming a subshell function; the
   `-ef` root check (symlinked roots, linked worktrees, a case-sensitive
   filesystem such as Linux CI); captures, floors and umbrella gate roots now
   running git without its local variables; the cost of the extra git calls;
   the O-010 scan fixture's failing-`git` shim on `PATH`; README's new
   precondition.
3. Whether each new fixture is a genuine negative in both directions with an
   exact diagnostic, and whether a `KIT_DIR=host test_...` call can pass for
   the wrong reason.
4. Anything the Decisions entries or the contract paragraph
   (`templates/verification-contract.md`) claim that the code does not do.

## Reply format

For each finding: a title; severity (blocking only for a reproduced
wrong-result, data-loss, regression or crash, otherwise minor); `file:line`;
the exact reproduction you ran, in your copy, and its observed output; and the
smallest class-wide fix. Then list what you attacked that held, and what you
did not reach. Do not soften.
