# Independent review brief — T030o42 (spec 003, O-016), 2026-09-27

You are an independent, READ-ONLY reviewer. Do not create, modify, move or
delete anything in the worktree. Do not run `spec-gate.sh round`, `floor`,
`checkpoint` or `accept`, and do not write any authorization line. Work in a
COPY under your own private directory (for example `/private/tmp/rev-t030o42`)
with `TMPDIR` pointing inside it, and remove it when you finish. Check
`df -h /` and `sysctl vm.swapusage` first (a copy is about 170 MB; swap shares
the volume). Prefer single test functions to whole suites; one whole-suite run
takes about 20 minutes.

**Run no test suite, and no test function, in the worktree itself.** A suite
run from the live checkout once deleted a live file through a helper defect.
Build your copy from the worktree's own enumeration with
`GIT_OPTIONAL_LOCKS=0`, for example
`git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf -`,
make it its own git repository, and check its
`git status --porcelain --ignored` before and after each run.

**Write your report progressively** to `REPORT_PATH` (given in your prompt,
outside your copy and outside the worktree): create it first with a header
saying IN PROGRESS, append each finding as soon as you have confirmed it, and
finish with the Held and Not-reached sections and a final line
`REVIEW COMPLETE`.

Worktree: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`
Spec dir: `.specify/specs/003-gate-round-reduction-and-token-discipline` (below: `$S`).
Receipts: `$S/notes/verification/reports/` (below: `$R`).

## Inputs

- The finding: round 11's O-016, in `$R/opponent-round11.md` (a PASS of the
  kit's reuse-checked `bash tests/run.sh` captured in one locale is reused from
  a shell whose locale fails it, because `date`/`tr` read the locale while the
  identity hashes no undeclared name).
- The delta under review: `$R/t030o42-session.diff` (5 source files plus the
  task block). The pre-delta versions of every file it edits are at `PRE_DIR`
  (given in your prompt; read them, do not modify them).
- Why each change exists: the LAST TWO entries of the Decisions log in
  `$S/STATUS.md` (2026-09-26: the entry audit and the reproduction; then the
  rule, its derivation and its measurements), and the task block `T030o42` in
  `$S/tasks.md`.
- The invoker's evidence: the reproduction `$R/o016-repro.{sh,log,rc,note}`;
  the measurement of the rule before adoption `$R/o016-measure.{sh,log,rc}`
  with the program census `o016-census-counts.txt`, the manual pages'
  ENVIRONMENT sections `o016-census-env.txt`, and the option-variable probe
  `o016-option-vars.txt`; the live checks `o016-live-check*.{sh,log,rc}`; the
  dev runs `t030o42-dev.sh` with `t030o42-dev1-quick.{log,rc}` and
  `t030o42-dev1-full.{log,rc}`; and the mutation matrix
  `t030o42-mutations.sh` with `-dry.{log,rc}` and `.{log,rc}`.

## Known and recorded — do not report as new, but do report any place that claims them fixed

- The harness-level environment: every captured command runs as
  `bash -o pipefail -c`, which reads `BASH_ENV`, `ENV`, `SHELLOPTS`, `BASHOPTS`
  and exported functions; and, measured this session, option variables a
  program reads only when someone sets them (`UNAME_SYSNAME`, `GREP_OPTIONS`,
  `TAR_*_OPTIONS`, `POSIXLY_CORRECT`, `GNUSORT_*`, `COLUMNS`, `PERL5OPT`). These
  wait for a plan-level user decision (hash the startup inputs, or pin a
  closed harness environment).
- `PATH` choosing an undeclared tool (the kernel comment at
  `scripts/verification-lib.sh` near :1580 records `verification_tools:` as
  the place tools are closed).
- Shipped 002's own locale-dependent reset parsing in `scripts/usage-limit.sh`
  (a product defect outside spec 003; the pin removes only the reuse half).
- Review 7's F1, F2, F4, the unjudged `tests/test-verification.sh` K74 site,
  the kernel's ambient fixture reads, the analyzer's field grammar, the
  umbrella-only in-place readers.

## Attack surface (derive members from the mechanism, not from these examples)

1. The rule: no locale category may decide the verdict of a reuse-checked
   command the kit ships, because the identity hashes no undeclared name.
   Is every such command pinned before any program on a verdict path reads a
   locale? Is there a reuse-checked verdict path that escapes the pin (a
   program started before it, a sub-shell that resets it, a script that sets
   `LANG`/`LC_*` itself later, a child that clears the environment)? Does the
   pin CHANGE any verdict in a way that hides a real defect the suite should
   catch, beyond the recorded 002 classifier?
2. The derivation: is the census and man-page reading sound, and does any
   default-varying name other than the locale family decide a verdict (the
   invoker measured `TZ` inert under three offsets, not proven)? Is the split
   between default variation and deliberately set option variables drawn
   correctly, and does anything the invoker filed under the recorded
   harness-level item in fact vary by default?
3. The fixture `reuse_command_locale_cases`: is each half a genuine negative
   in both directions? Does deriving the commands from `reuse_checks` really
   make a new command fail by name? Can the behaviour half pass vacuously
   (host without the locales, an ambient `LC_*` masking `LANG`, a canary that
   is always equal)? Is the macOS precondition sound, and is Linux CI
   (ubuntu, likely only `C.UTF-8`/`en_US.UTF-8`) judged by the mechanism half
   alone acceptable?
4. The matrix: does each guard have a row, does each mutant use the exact
   post-delta lines, is the argued equivalent E1 argued correctly, and does
   any row pass or fail for the wrong reason?
5. Anything the Decisions entries, the contract paragraphs
   (`templates/verification-contract.md`, the two edited paragraphs) or the
   task text claim that the code does not do. The contract must also still
   pass the repository-wide superseded-environment scan
   (`tests/test-gate-contracts.sh::test_instruction_contracts`).

## Method this spec requires

Derive each criterion from the grammar or production the code reads, with its
source. Test a proposed rule against the real record before proposing it.
Mutation-isolate guards in both directions and restore byte-identically
(`cmp`). Assert exact diagnostics, never exit codes alone. Hunt for shipped
positives that assert an attack at rc=0.

## Reply format

For each finding: a title; severity (blocking only for a reproduced
wrong-result, data-loss, regression or crash; otherwise minor); `file:line`;
the exact reproduction you ran in your copy and its observed output; and the
smallest class-wide fix. Then list what you attacked that held, and what you
did not reach. Do not soften. Your final reply may be short; the report file
is the deliverable.
