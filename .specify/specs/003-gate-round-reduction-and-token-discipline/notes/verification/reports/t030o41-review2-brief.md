# Independent review brief, second pair — T030o41 (spec 003), 2026-09-24

You are an independent, READ-ONLY reviewer. Do not create, modify, move or
delete anything in the worktree. Do not run `spec-gate.sh round`, `floor`,
`checkpoint` or `accept`, and do not write any authorization line. Work in a
COPY under your own private directory with `TMPDIR` pointing there, and remove
it when you finish. Check `df -h /` first (about 7 GiB free; swap shares the
volume; a copy is about 150 MB, most of it the spec's captures).

**Run no test suite, and no test function, in the worktree itself.** A suite
run from the live checkout deleted a live file earlier today through a helper
defect (the incident below). Run everything in your copy, and check your
copy's `git status --porcelain --ignored` before and after each run.

Worktree: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`
Spec dir: `.specify/specs/003-gate-round-reduction-and-token-discipline` (below: `$S`)

## Inputs

- The first pair of review passes and the invoker's verification and incident
  record: `$S/notes/verification/reports/t030o41-review.md`. Every finding there
  was either repaired or folded into the expanded scope; check that claim.
- The governing decisions: the 2026-09-24 entries at the end of the Decisions
  log in `$S/STATUS.md`. Read the whole run of them: the reproduction, the first
  derivation (which the first pair proved incomplete), the analyzer
  field-grammar observation (deliberately NOT repaired), the incident, the
  review outcome, and the user's choice to EXPAND the task with the re-derived
  member set. Task block: `T030o41` in `$S/tasks.md`; T027's Verify was changed.
- The source changes against the pre-repair tree: regenerate the diff yourself
  from the worktree against git HEAD plus the reproduction receipts if you need
  one, or read the files; the first pair's diff (`t030o41-session.diff`) is
  now out of date.

## What changed since the first pair

- Kernel: `vf_path_content` (a link's target as it is, a file through
  `vf_semantic_file`, always from `"$repo/$path"`), now called by
  `vf_path_record`; `vf_source_paths` unchanged.
- The O-010 scan: fold-aware per-path anchoring, content via `vf_path_content`,
  the report name via `ENVIRON`, a named diagnostic on every failure branch, and
  no EXIT trap (a wrapper owns one private directory).
- The AC-023 loop: shipped set from `vf_source_paths`; probes built from the
  hashed view, anchored to the first task header; exact failure diagnostics.
- `copy_kit`: no EXIT trap; omits `.specify/specs/`; optional directory
  selector; used for every whole-kit copy (doctor, wizard, `stage_kit`).
- `tests/run.sh` enumerates suites; new `tests/shellcheck.sh` (enumerated
  files, `--norc`, `SHELLCHECK_OPTS` unset) is the ShellCheck command in
  `.specify/stack.yml`, CI, README and T027's Verify.
- `tests/helpers.sh`: clears `SDD_*` and `XDG_*` at suite start; `kit_files`
  and `make_host_kit` helpers.
- Live-kit globs in suites moved to `kit_files`; the 002 tally reads an
  enumerated copy of 002's `notes/`; `stage_kit`'s writer removes before writing.
- Fixtures for each site, most of them running the real function against a
  host kit that carries the ignored, directory-shaped, linked or ambient input.

## Attack surface (derive members from the mechanism, not from these examples)

1. Completeness, again. The reuse-checked commands are `reuse_checks:` in
   `.specify/stack.yml`, and every task whose `*Reuse:*` is `local` opts its
   Verify in too. Derive every read those commands make of bytes the identity
   does not hash — their own file lists, globs and directory walks, copies,
   spec records read in place, the environment and configuration outside the
   repository, and the scripts they run — and reproduce any that still flips a
   verdict with the identity unchanged.
2. Anything the expansion broke: behavior of `tests/run.sh` (filters, exit
   codes, Bash 3.2, a kit that is not a Git worktree), `tests/shellcheck.sh`
   (portability of `env -u` and `--norc`, ShellCheck 0.9 on Ubuntu, exit
   codes), the environment reset (a test that relied on an ambient value),
   CI (`.github/workflows/ci.yml`), and the gate and floor with the changed
   `gate_checks`/`reuse_checks` and T027's changed Verify.
3. Whether each new fixture is a genuine negative in both directions, with
   exact diagnostics, and whether calling a `test_*` function from another
   (`KIT_DIR=host test_…`) can pass for the wrong reason.
4. Trap scope: any remaining function whose EXIT trap can read a caller's
   variables (see the incident), in the tests or the kernel.
5. Anything the Decisions entries claim that the code does not do.

## Reply format

For each finding: a title; severity (blocking only for a reproduced
wrong-result, data-loss, regression or crash, otherwise minor); `file:line`;
the exact reproduction you ran, in your copy, and its observed output; and the
smallest class-wide fix. Then list what you attacked that held, and what you
did not reach. Do not soften.
