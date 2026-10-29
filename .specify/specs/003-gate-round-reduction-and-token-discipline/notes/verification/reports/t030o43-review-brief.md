# Independent review brief — T030o43 (spec 003, O-017), 2026-09-27

You are an independent, READ-ONLY reviewer. Do not create, modify, move or
delete anything in the worktree. Do not run `spec-gate.sh round`, `floor`,
`checkpoint` or `accept` in the worktree, and do not write any authorization
line. Work in a COPY under your own private directory (for example
`/private/tmp/rev-t030o43`) with `TMPDIR` pointing inside it, and remove it
when you finish. Check `df -h /`, `sysctl vm.swapusage` and `pmset -g batt`
first: free disk is about 5.5 GiB and swap shares the volume, so keep at most
one copy of about 190 MB and one suite running at a time. Prefer single test
functions to whole suites; one whole-suite run takes about 20 minutes.

**Run no test suite, and no test function, in the worktree itself.** A suite
run from the live checkout once deleted a live file through a helper defect.
Build your copy from the worktree's own enumeration with
`GIT_OPTIONAL_LOCKS=0`, for example
`git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf -`,
make it its own git repository, and check its
`git status --porcelain --ignored` before and after each run. To run one
fixture function, strip the trailing `t_run_all` from its suite into a
dot-file the copy ignores and call the function in a subshell with a fresh
`SANDBOX`, as `$R/t030o43-mutations.sh`'s `judge` does.

**Write your report progressively** to `REPORT_PATH` (given in your prompt,
outside your copy and outside the worktree): create it first with a header
saying IN PROGRESS, append each finding as soon as you have confirmed it, and
finish with the Held and Not-reached sections and a final line
`REVIEW COMPLETE`. For each finding give the severity (blocking means a
reproduced wrong result, data loss, regression or crash; otherwise minor), the
exact reproduction, and the smallest class-wide fix.

Worktree: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`
Spec dir: `.specify/specs/003-gate-round-reduction-and-token-discipline` (below: `$S`).
Receipts: `$S/notes/verification/reports/` (below: `$R`).

## Inputs

- The finding: round 12's O-017, in `$R/opponent-round12.md`. The harness's
  own text parsing ran under the caller's locale; macOS awk dies at a byte its
  locale cannot decode, and grep stops matching there and exits 0; and the
  prior-review manifest pass in `vf_reports` discarded its awk's status. So a
  CLEARED round resting on a lowered tier of a manifest-recorded blocking
  finding was refused under C and sealed under en_US.UTF-8.
- The delta under review: `$R/t030o43-session.diff` (13 files, the task block
  included). The pre-delta versions of every file it edits are at `PRE_DIR`
  (given in your prompt; read them, do not modify them). They were rebuilt by
  reversing each literal edit and proven byte-exact against the inputs
  manifest recorded before any code changed (`$R/t030o43-pre-rebuild.{sh,log,rc}`;
  run 1's failure, `-run1`, was the rebuild script's own bug).
- Why each change exists: the Decisions log in `$S/STATUS.md` from the entry
  "Opponent round 12 is recorded here now that this batch moves the source
  anyway" to the end (round 12's outcome; the user's decision; the
  reproduction; the rule, its derivation and its measurements; the round-13
  waiver; two task-block corrections), and the task block `T030o43` in
  `$S/tasks.md`.
- The invoker's evidence: the reproduction `$R/o017-repro.{sh,log,rc,time}`; the
  measurement of the rule before adoption `$R/o017-measure.{sh,log,rc,time}` with
  the corrected `o017-measure-m3.{sh,log,rc}` and `o017-measure-m3keep-C.diff`,
  and the prototype's suite `o017-measure-suite.{log,rc,time}`; the member
  search `$R/t030o43-parser-search.sh` with `-pre.{log,rc}` and the hand
  classification `$R/t030o43-parser-classes.md`; the dev runs `t030o43-dev.sh`
  with `t030o43-dev1-quick.{log,rc}` and `t030o43-dev1-full.{log,rc}` (and
  `-full-locale` if present); the mutation matrix `t030o43-mutations.sh` with
  `-dry.{log,rc}` (the real run may still be in progress when you start).

## Known and recorded — do not report as new, but do report any place that claims them fixed

- The harness-level environment: every captured command runs as
  `bash -o pipefail -c`, which reads `BASH_ENV`, `ENV`, `SHELLOPTS`, `BASHOPTS`
  and exported functions; and option variables a program reads only when
  someone sets them (`UNAME_SYSNAME`, `GREP_OPTIONS`, `TAR_*_OPTIONS`,
  `POSIXLY_CORRECT`, `GNUSORT_*`, `COLUMNS`, `PERL5OPT`). Pending a plan-level
  user decision.
- `PATH` choosing an undeclared tool (`verification_tools:` closes tools). The
  fixtures here put a failing copy of one program first on `PATH` to prove a
  status is read; that is a test device, not a claimed attack surface.
- `TZ` (measured inert, not proven); shipped 002's locale-dependent reset
  parsing in `scripts/usage-limit.sh` (outside spec 003: 002's dispatcher
  sources `lib.sh`, not the kernel, so the pin does not reach it).
- T030o42 review F2 (the reuse-probe fixture takes its members from
  `reuse_checks` alone), review 7's F1, F2, F4, the unjudged K74 site, the
  kernel's ambient fixture reads, the analyzer's field grammar, the
  umbrella-only in-place readers (`spec_declared_repos`, the analyzer's task
  map, `vf_gate_task_repo`), the O-004 omission extent, the opponent-only
  totals guards, README's Verification-Return grammar, 001's legacy exit 3.

## Attack surface (derive members from the mechanism, not from these examples)

1. The pin. Is every harness process pinned before any of its programs reads
   a repository or bookkeeping byte: the six entry scripts, direct callers that
   source the kernel, and every harness process the harness starts (the
   `spec-task.sh` children, `accept`'s exec, `system-map.sh`)? Does anything
   the harness starts that is NOT its own parsing run under the pin when it
   should keep the caller's locale, or is there a second place a captured or
   user command runs that the restore misses? Does the pin change any verdict,
   record or tally the kit's recorded history depends on (M2 and M3 claim not;
   test that claim, including bash's own matching and glob order)?
2. The caller-locale record (`SDD_HARNESS_CALLER_LC_ALL`). Is the caller's
   LC_ALL (set, set empty, unset) given back exactly to the captured command,
   and is the record never visible to it? Is the inheritance rule sound (a
   process re-reads only when the record is absent or LC_ALL is not C)? Can the
   record make the harness hash one LC_ALL and run the check under another?
   Does a declared LC_ALL hash the value the check actually ran under, through
   every path (`spec-run.sh`, the floor, `accept`'s exec chain, checkpoints)?
3. The exit-status half. Is the member derivation complete: a parser whose
   output decides a record, an identity or a verdict, and whose failure reads
   as an absence that passes, that is not repaired? Is any "closed" or
   "display" classification in `t030o43-parser-classes.md` wrong? Is any
   status read itself wrong (grep's no-match 1 read as failure, SIGPIPE, an
   assumption about `pipefail`, a `set -e` interaction in `spec-task.sh`)? Is
   `vf_fm_value`/`vf_fm_count` exactly equivalent to `fm_get` and the old
   count on every frontmatter shape the kit writes or reads?
4. The fixtures. Does each fail in both directions (removing its guard fails
   it with its exact diagnostic)? Can `fault_bin`'s marker match an
   invocation other than the one it targets, so a fixture passes for the wrong
   reason? Is `locale_hostile` a real precondition on macOS, and what do the
   fixtures prove on a Linux host without these locales? Hunt for a shipped
   POSITIVE that asserts an attack at rc=0.
5. The wording: do the contract paragraph and the kernel comments now state
   what the code does? Do they pass the O-010 scan for the right reason?
6. Regressions: behavior the delta changes on purpose (bash `nocasematch`
   folding ASCII only under C; the capture loop's glob order; `spec-ac-coverage.sh`
   and `spec-task.sh` loading the kernel at their top; the checkpoint reading
   its contract from the binding catalog). Does any of it break a real use?

## Method this spec requires

1. Derive each criterion from the grammar or production the code reads, with
   its source. An enumeration of reported spellings is satisfiable while the
   class stays open.
2. Test a proposed rule against the real recorded history (`notes/opponent.md`,
   and 001's and 002's reports) before proposing it.
3. Mutation-isolate guards in both directions, and restore byte-identically (`cmp`).
4. Assert exact diagnostics, never exit codes alone.
5. Never pipe a suite through `tail`; `tests/run.sh` prints no total, so its
   exit code is the signal. Capture exit codes and read them back.
