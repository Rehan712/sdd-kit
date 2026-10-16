# T030o41 second-pair review, pass C (items 1 and 5, plus the first-pair claim) — COMPLETE

**Verdict: BLOCKED.** There are 4 blocking findings: F1 wrong-result, F2 wrong-result and regression, F3 regression, and F4 data loss (pre-existing). There are also 5 minor findings.

## How I ran it

- I worked in a private standalone copy only, at `scratchpad/rev2C/copy`. I built it from the worktree's own `git ls-files -z --cached --others --exclude-standard` (6389 paths, the same set) with `GIT_OPTIONAL_LOCKS=0`, committed it as `main`, and made a `pre` branch by reverse-applying `t030o41-session2.diff`.
- `TMPDIR` pointed at `rev2C/tmp`. The copy has been removed, and `rev2D` was not touched.
- Identity is `vf_snapshot` of spec 003 in the copy. The baseline was `05b2dfe60a9a…`, and every probe below was checked with a `cmp` of the manifests.
- I ran test functions one at a time with a driver. The driver sources `helpers.sh` and then the suite with the `helpers.sh` source line and `t_run_all` removed, under `/bin/bash` 3.2.57. It runs each named function in its own `SANDBOX` subshell, exactly as `t_run_all` does. I ran no whole suite.
- I checked the copy's `git status --porcelain --ignored` before and after every run, and it was unchanged each time.
- **The live worktree's status digest changed during my review, and I did not change it.** It went from `7249df4e…` at the start to `b85bd39d…` at the end. The only files newer than my start marker are `STATUS.md` and `notes/verification/reports/t030o41-review2-verify{.sh,-c.sh,.log,.rc}` (the reports directory's mtime is 18:56). I wrote nothing in the worktree.

## F1 — blocking (wrong-result). Directory copies of the live `scripts/` still carry ignored entries. One flips `test_instruction_contracts` while the identity stays the same

**Where**
- The reproduced site is `tests/test-gate-contracts.sh:1684`, in `documented_example_cases` (called from `test_instruction_contracts` through `public_workflow_cases`, line 436). It runs `cp -R "$KIT_DIR/scripts/." "$repo/scripts/"` into a Git fixture repo. There, any copied ignored entry becomes an untracked input of the fixture's own identity.
- The same class, with no flip reproduced:
  - `tests/test-spec-gate.sh:306` (`floor_fixture`)
  - `tests/test-spec-dispatch.sh:16` (`stage_umbrella`)
  - `tests/test-usage-limits.sh:91` (`cp -R "$SCRIPTS"`)
  - `tests/test-golden-example.sh:18` (`cp -R "$EXAMPLE"`)

The `:1684` line predates the repair (the diff does not touch it), but it is squarely in the class the expanded scope claims to cover: "every glob or directory walk a suite makes over the live kit", and copies.

**Reproduction**
1. Probe 1, a directory symlink:
   ```
   printf 'scripts/zz-local-dir\n' >> .git/info/exclude
   ln -s <outside dir> scripts/zz-local-dir
   ```
   - Identity: `05b2dfe6…` before and after, manifests `cmp`-identical.
   - `test_instruction_contracts`: rc=0 without the link, rc=1 with it:
     ```
     assert: expected exit 0, got 3: eval bash scripts/spec-run.sh "$SPEC" "$TASK" --from-task --no-tick --summary
         output: verification inputs: directory symlink requires explicit target files: scripts/zz-local-dir
     ```
     After that, accept, checkpoint, floor and round all return 3, and `opponent rounds=1` is missing.
2. Probe 2, a nested clone (a more realistic setup):
   ```
   mkdir scripts/zz-tool; git -C scripts/zz-tool init
   # exclude 'scripts/zz-tool/'
   ```
   The identity is `cmp`-identical, and the test fails with `verification inputs: unsupported file type: scripts/zz-tool/`.

**Smallest class-wide fix**
- Never `cp -R`, `tar` or glob a live-kit directory in a suite. Use `copy_kit "$KIT_DIR" "$dest" scripts` (the existing selector) at all five sites.
- Add a grep guard over `tests/*.sh`, outside `helpers.sh`, for `cp -[rRa]`, `tar -c` or `find` whose operand is `$KIT_DIR` or `$SCRIPTS`.

## F2 — blocking (wrong-result AND regression). The `XDG_*` reset makes in-suite enumeration diverge from the identity's

**Where**
- `tests/helpers.sh:27-30` unsets `XDG_*`, so Git inside a suite stops reading `$XDG_CONFIG_HOME/git/{config,ignore}`. The identity, `run.sh` and `shellcheck.sh` still read them.
- Affected readers:
  - `kit_files` (`helpers.sh:427`)
  - `copy_kit` (`helpers.sh:389`)
  - `superseded_environment_scan_in` (`tests/test-gate-contracts.sh:63-77`)
  - `shipped_specs_case`

**Reproduction**
1. An overlay ignored only through the XDG Git config:
   ```
   echo templates/stack-overlays/zz-local.md > $P/xdg/git/ignore
   printf '# local notes, no defaults section\n' > templates/stack-overlays/zz-local.md
   ```
   - With `XDG_CONFIG_HOME=$P/xdg`, `git status` shows `!! templates/stack-overlays/zz-local.md`, and the identity is `05b2dfe6…`, `cmp`-identical to the baseline.
   - `test_all_overlay_defaults` fails:
     - `missing substring: ## Failure-mode and checkpoint defaults … in: # local notes, no defaults section`
     - `zz-local scenario prompts expected: 3 actual: 0`
   - Control: the same environment with the file moved away passes.
   - `vf_source_paths` run without `helpers.sh` lists the file 0 times. `kit_files` run under `helpers.sh` lists it.
2. The regression, at the O-010 scan:
   ```
   echo zz-local-note.md > $P/xdg/git/ignore
   printf 'The snapshot always includes PATH and TMPDIR.\n' > zz-local-note.md
   ```
   - The identity is `cmp`-identical.
   - Post-repair, `test_instruction_contracts` fails with `AC-018: superseded fixed-environment membership survives … actual: zz-local-note.md :: always includes PATH`.
   - The pre-repair branch, with the same environment and file, passes.

The same mechanism also reaches `safe.directory` or `core.excludesFile` set in the XDG Git config. I did not reproduce that.

**Smallest class-wide fix**
- Do not clear anything Git consults in the suites. Clear only the six names the kit's scripts read.
- Alternatively, run every live-kit enumeration under the pre-reset environment.
- Add a fixture: an XDG ignore rule names an overlay, and `kit_files` must not list it.

## F3 — blocking for `tests/shellcheck.sh` (regression); `tests/run.sh` has the same defect, pre-existing. An exported `CDPATH`, or one set by a `BASH_ENV` rc file, decides the reuse-checked commands

**Where**
- `tests/shellcheck.sh:15`: `ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"`
- `tests/run.sh:18`: `TESTS_DIR`, which feeds `:25` `ROOT`

Invoked as `bash tests/…`, the `cd` operand is relative, so `cd` consults `CDPATH` and prints the directory into the command substitution. Tested with ShellCheck 0.11.0.

**Reproduction**
- `bash tests/shellcheck.sh` returns 0.
- `CDPATH=. bash tests/shellcheck.sh` returns 2:
  ```
  line 16: <copy>\n<copy>/scripts/verification-lib.sh: No such file or directory
  vf_source_paths: command not found
  cannot enumerate the kit
  ```
- The pre-repair command under the same variable, `CDPATH=. shellcheck -S warning -x scripts/*.sh tests/*.sh`, returns 0.
- `env -u CDPATH BASH_ENV=<file containing 'CDPATH=.'> bash tests/shellcheck.sh` returns 2. So an rc file outside the repository decides the verdict.
- `CDPATH=. bash tests/run.sh zz-none` returns 1. The pre-repair glob under `CDPATH=.` finds 0 suites, so this part predates the repair.

**Smallest class-wide fix**
- Use `CDPATH= cd -- … >/dev/null` (or `unset CDPATH` first) in `run.sh`, `shellcheck.sh`, `helpers.sh:13` and every script entry point.
- Add a fixture that runs both commands with `CDPATH=.` from the repository root.

## F4 — blocking (data loss; pre-existing, identical on `pre` and `main`). Sandbox Git fixtures inherit `GIT_*`, so an exported absolute `GIT_INDEX_FILE` overwrites the caller's index while the suite reports PASS

**Where**
- Every sandbox Git call is unscrubbed. Examples:
  - `helpers.sh:484-486` (`make_verification_git_dir`)
  - `tests/test-verification.sh:441-453` (`kit_copy_cases`)
  - `helpers.sh:419` (`make_host_kit`)
- The reset only covers `SDD_*` and `XDG_*`.

**Measured:** Git 2.50.1 exports `GIT_INDEX_FILE` to a pre-commit hook. For a plain `commit` it is `.git/index` (relative). For `commit -a` and `commit -- <path>` it is absolute (`…/.git/index.lock`, `…/next-index-<pid>.lock`).

**Reproduction**
1. `GIT_INDEX_FILE=<abs scratch copy of the index>` with `test_instruction_contracts`: the test passes, and the scratch index then lists `.specify/specs/003-verification-fixture/STATUS.md`, `plan.md`, `spec.md` and so on. The `pre` branch behaves the same.
2. Pointed at the copy's real index: the test passes, and then `git status` fails with `fatal: unable to read 4e2326ac6647de1dc044c0d1f7e2ff2372e56056`. I restored the index from a saved copy.
3. A real pre-commit hook running that test function, then `git commit -qam probe`: the hook's suite returns 0 and the commit returns 1 with `error: invalid object 100644 4e2326ac… for '.specify/specs/003-verification-fixture/STATUS.md' / Error building trees`.

**Smallest class-wide fix**
- Add one sandbox-Git wrapper in `helpers.sh` that unsets every name `git rev-parse --local-env-vars` reports, and use it for every fixture repo.
- Do not unset those names globally; that would repeat F2 for the live-kit enumeration.
- Add a fixture: run one Git fixture with an absolute scratch `GIT_INDEX_FILE`, and require the scratch index to be byte-identical afterwards.

## Minor findings

**M1. The new leftover-spec negative is vacuous when the live kit has a leftover directory.**
- `tests/test-sdd-analyze.sh:589` uses the live-kit directory glob that B3 removed.
- `:594` copies `tasks.md` from whatever that glob matched last, and does not check the copy.
- With an empty `.specify/specs/002-zz-scratch` (identity unchanged), the planted `001-stale` holds `[]` instead of `[tasks.md]`, and the test still passes.
- This also contradicts "Live-kit globs in suites moved to `kit_files`".
- Fix: build the host from `rel002` or `shipped-rels`, and assert that the planted file exists.

**M2. The contract sentence flagged as m6/A-M3 was reworded, not repaired.**
- `templates/verification-contract.md:184-186` says "The kit's own suites read through `vf_source_paths` and `vf_path_content`". F1's five walks and M1 contradict it.
- `:180-182` says a reuse-checked check "reads no environment variable the project has not declared and no configuration outside the repository". The kit's own two commands contradict it (F2, F3) under `verification_environment: []`.

**M3.** The Decisions say "Every site gets a fixture…", but the wizard site (`tests/test-model-policy.sh:153`) has no host-kit fixture in either direction.

**M4.** The Decisions say "every other script a suite runs operates on a copy". That is false as written:
- Suites run live scripts in place, including `$SCRIPTS/spec-gate.sh` 72 times and `sdd-analyze.sh` 8 times.
- Nothing harmful is exercised today.
- But the in-place readers of the ignored `system-map.yml` and `registry.yml` (`system-map.sh` via `verification-lib.sh:2077`, `:2137`, and `spec-ac-coverage.sh:82`) are one umbrella fixture away.

**M5.** The brief says every first-pair finding was repaired or folded in. That is inaccurate for A-M1: the narrowing of AC-023 is parked as a user decision, neither repaired nor in scope. It is also inaccurate for m6/A-M3 (see M2).

## What held

**First-pair findings, re-run against the repaired code.** The identity was `cmp`-identical in each case.

| Finding | Probe | Result |
|---|---|---|
| B2 | all 22 Evidence lines of 002's `tasks.md` deleted | `test_verification_bindings` passed |
| B3 and A-B2(a) | `001-stale/.DS_Store` and an empty `002-zz-scratch` | `test_verification_bindings` passed |
| A-B2(b) | an empty 002 `FLOOR-zz` | `test_reports_and_tally` passed |

**Repaired, checked by reading the code:** B1, B4, B5, m1, m3, m4, m5, A-B3, A-B4, A-M5, and A-B2(c) and (d).

**m2** is half-pinned. Its awk-failure half is recorded as E02, argued equivalent.

**Other probes that held:**
- A global `commit.gpgsign=true` with a failing `gpg` does not flip `test_instruction_contracts`.
- `VF_*` names are never exported, and every lock path runs `vf_writer_init` first.
- The kit scripts' own environment reads are complete: `HOME`, `NO_COLOR`, `TMPDIR`, five `SDD_*` names and `XDG_STATE_HOME`.
- ShellCheck's `-x` resolves the only source directive to a tracked file.
- bsdtar accepts an empty `-T` list.

## Not reached

- GNU tar: whether `copy_kit`'s `--null -T` still parses names that start with `-` as options.
- Linux, CI, and a case-sensitive `TMPDIR`.
- Any whole suite or a full `tests/run.sh`.
- F2's `safe.directory` variant, which needs a checkout owned by another user.
- EXIT traps firing on signals in the kernel's subshell functions (item 4).
- TZ dependence of the dispatch fixtures.
- Items 2 to 4 beyond what is noted above (pass D covers them).
