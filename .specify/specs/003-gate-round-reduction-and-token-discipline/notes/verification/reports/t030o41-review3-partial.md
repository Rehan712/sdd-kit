# T030o41 focused delta review 3 (session3.diff) — IN PROGRESS

Copy: scratchpad/rev3/copy (standalone git repo, commit "base" = worktree file set, 6404 paths), TMPDIR=rev3/tmp.

## Findings (confirmed)

(none yet)

## Held

(pending)

## Not reached

(pending)

### R3-1 (blocking: reproduced regression/wrong result) — vf_snapshot clears git's local names for the whole subshell, so a DECLARED verification_environment name among them is always hashed "unset"
- scripts/verification-lib.sh:1481 (`vf_git_local_unset || return 3` at the top of vf_snapshot) vs the environment record at :1578-1585 (`${!key+set}`).
- Repro (copy, driver rev3/exp/envdecl.sh: make_verification_git_dir fixture, `verification_environment: ['<NAME>']` appended to its stack.yml, vf_snapshot run twice with NAME=value-one / value-two):
  - GIT_PREFIX, post-delta lib: digests 0513ee8306a4 / 0513ee8306a4 SAME, record `GIT_PREFIX unset`
  - GIT_PREFIX, pre-delta lib (v2/copy): b578ebf720b2 / f39f1704de03 DIFFER, record `GIT_PREFIX present <hash>`
  - control VF_CONTROL: DIFFER on both libs.
  - GIT_CONFIG_COUNT, post-delta: SAME, `unset` (pre-delta failed closed rc=3 for a non-numeric value).
- Effect: any of the 15 `git rev-parse --local-env-vars` names (GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT, GIT_CONFIG, GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE, GIT_PREFIX, ...) that a project declares because its check reads it is silently constant in the identity, while the harness still runs the check with the ambient value (vf_capture runs `(cd "$cwd" && "$@")` uncleared). Reuse then applies across different values. Contradicts the kernel's own comment ("the declared path already proves presence and value affect identity", :1571) and the contract's "membership is exactly the declaration".
- Smallest class-wide fix: scope the clearing to git's own processes, never to the snapshot's reads: run every git call in vf_snapshot through `vf_git` (or compute the environment records from values saved before `vf_git_local_unset`), and refuse (vf_config) or explicitly document declaring a --local-env-vars name. Add the fixture above (declared GIT_PREFIX, two values, digests must differ).

### R3-2 (minor by the rubric; fails T030o41's "fixture in both directions" clause) — two new host-kit fixtures pass with the pre-delta cp -R restored, because the old line read a load-time global that KIT_DIR=host does not redirect
- tests/test-golden-example.sh:131 `test_stage_example_copies_only_enumerated_files` guards stage_example (:619-620); the pre-delta line was `cp -R "$EXAMPLE" "$spec_dir"`, and `EXAMPLE="$KIT_DIR/templates/..."` is fixed at file load (:9), i.e. the LIVE kit.
- tests/test-usage-limits.sh:1030 `test_AC_003_dispatch_fixture_copies_only_enumerated_scripts` guards dispatch_fixture (:93); the pre-delta line was `cp -R "$SCRIPTS" "$DISPATCH_KIT/scripts"`, and `SCRIPTS` is fixed in helpers.sh at load (the LIVE kit).
- Repro (copy; runner rev3/exp/one.sh runs one function exactly as t_run_all does): both functions `ok` on the delta; then with only those two lines reverted by perl (git diff shows exactly `+  cp -R "$EXAMPLE" "$spec_dir"` and `+  cp -R "$SCRIPTS" "$DISPATCH_KIT/scripts"`): `ok test_stage_example_copies_only_enumerated_files`, `ok test_AC_003_dispatch_fixture_copies_only_enumerated_scripts`. The mutants survive: the planted ignored file is in the host, the reverted line copies the live kit, so the negative can never fire. (floor_fixture, stage_umbrella, documented_example_cases and the wizard had `$KIT_DIR` in the old line, so their fixtures are not affected by this.)
- Smallest class-wide fix: a host-kit call must redirect every name a site could read, not just KIT_DIR: call `KIT_DIR="$host" SCRIPTS="$host/scripts" EXAMPLE="$host/templates/examples/001-api-key-expiry" <fixture>` (or drop the load-time globals from copy sites and derive from KIT_DIR at call time), and add each site's pre-delta line to the mutation matrix.

### R3-3 (blocking: reproduced regression; same class as second-pair D7) — the new XDG-ignore fixture fails whenever GIT_CONFIG_GLOBAL is exported with a core.excludesFile, although the kit's enumeration is byte-identical
- tests/test-verification.sh:370-378 (reuse_command_input_cases, reached from test_capture_provenance). It pins HOME, XDG_CONFIG_HOME and GIT_CONFIG_NOSYSTEM, but not GIT_CONFIG_GLOBAL, which replaces both ~/.gitconfig and $XDG_CONFIG_HOME/git/config; any core.excludesFile there replaces the default $XDG_CONFIG_HOME/git/ignore the probe relies on.
- Repro (copy): `rev3/exp/gcg/gitconfig` = `[core] excludesFile = <empty file>` (an ordinary global-ignore setup).
  - `cmp` of `vf_source_paths <copy>` with and without `GIT_CONFIG_GLOBAL=.../gitconfig`: identical (kit enumeration unchanged).
  - delta, `GIT_CONFIG_GLOBAL=... one.sh test-verification.sh reuse_command_input_cases`: FAIL
    `assert: AC-020: precondition: the XDG ignore rule does not hide the script from the identity unexpectedly contains: zz-xdg.sh`
    `assert: expected exit 0, got 1: env HOME=... XDG_CONFIG_HOME=... GIT_CONFIG_NOSYSTEM=1 CDPATH=. bash -c cd "$1" && bash tests/test-executable-bits.sh ...` / `tracked without the executable bit: zz-xdg.sh`
    `assert: AC-020: a suite read a script the identity's git configuration ignores unexpectedly contains: zz-xdg.sh` (misleading: no parity defect exists).
  - same env without GIT_CONFIG_GLOBAL: ok. Pre-delta branch (delta reverse-applied), same env: `ok reuse_command_input_cases`.
- Effect: configuration outside the repository decides the reuse-checked Verify (`bash tests/run.sh` fails via test_capture_provenance) with the identity unchanged.
- Smallest class-wide fix: a fixture that depends on git's global configuration pins all of it, not a subset: add `-u GIT_CONFIG_GLOBAL` (and `-u GIT_CONFIG_SYSTEM`, next to GIT_CONFIG_NOSYSTEM=1) to both `env` calls, or one helper `git_config_pinned HOME XDG` used wherever a test sets HOME/XDG_CONFIG_HOME for git.

### R3-4 (minor; the effect reproduced is contrived) — a sixth live-kit copy site outside copy_kit, so "copy kit content only through copy_kit" and "the five sites" are false
- tests/test-gate-contracts.sh:1596, gate_dispatch_grammar_cases (reached from test_instruction_contracts): `cp "$SCRIPTS/"*.sh "$kit/scripts/"`, a shell glob over the live kit's scripts/ that picks up ignored entries. The Decisions (e) name five sites; templates/verification-contract.md:~186 says the suites "copy kit content only through `copy_kit`"; tasks.md acceptance says copy_kit "is used for every copy of live-kit content, whole or one directory".
- Repro (copy): gate_dispatch_grammar_cases alone: `ok` in 0.5 s. Then `scripts/zz-fifo.sh` added to .git/info/exclude and created with mkfifo: `vf_source_paths` output `cmp`-identical to before (identity unchanged); the same function then hung: after 5 min, `cp .../scripts/apply-models.sh ... .../scripts/zz-fifo.sh .../dispatch-kit/scripts` was still blocked opening the FIFO (killed by hand; copy restored, status clean). An ordinary ignored file is copied but not read by this fixture, so no pass/fail flip was found; cp's exit is unchecked, so a directory or unreadable entry is skipped silently.
- Smallest class-wide fix: `copy_kit "$KIT_DIR" "$kit" scripts` here too, and a grep guard in the suite (outside helpers.sh) that fails on any `cp`/`tar`/`find`/glob whose operand starts with `$KIT_DIR`, `$SCRIPTS` or `$EXAMPLE` and names a directory or a `*`.
