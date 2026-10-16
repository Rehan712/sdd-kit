# T030o41 second pair, pass D — final report

Copy: rev2D/copy (standalone git repo, commit "post" = worktree file set at ~18:10), TMPDIR=rev2D/tmp.
Worktree status digest (git status --porcelain -uall -z | sha256) before and after: 7249df4e7b594d3d38245046dd0c345ddf4ccbd940aa36f559504cd9ef9caef0 (unchanged). Copy removed at the end; rev2C never touched.
Single tests run with a generated runner (tests/.zz-one-<suite>, excluded via the copy's .git/info/exclude, removed after each run).
Baseline identity in copy: vf_snapshot 003 = 3c6e3d9bc6cf57072b914ebea147a06d1d46dce589a68b19c95ee46fe65b8892

## Findings

### D1 — blocking (wrong result). The suite-start XDG_* reset makes every in-suite enumeration diverge from the identity's
tests/helpers.sh:27-30 unsets XDG_CONFIG_HOME in every suite. git reads its global
excludes ($XDG_CONFIG_HOME/git/ignore, the default core.excludesFile) and global
config ($XDG_CONFIG_HOME/git/config) from it. The identity (vf_snapshot, in the
gate/capture process) and tests/run.sh enumerate with the ambient value; kit_files,
copy_kit, make_host_kit, shipped_specs_case and superseded_environment_scan run
inside the suite after the reset and fall back to $HOME/.config/git/*.
Repro (copy): HOME=$R/h1/home (empty) XDG_CONFIG_HOME=$R/h1/xdg with
xdg/git/ignore = "zz-local.sh"; plant non-executable scripts/zz-local.sh.
vf_snapshot 003 before/after: 3c6e3d9b… both, manifests cmp-identical; git status: "!! scripts/zz-local.sh".
`bash tests/run.sh executable` -> rc=1, "FAIL test_AC_011_every_kit_script_is_executable /
assert: tracked without the executable bit: zz-local.sh". File removed -> rc=0, 2/2.
Fix: reset only what the kit's scripts read for results (SDD_* and XDG_STATE_HOME,
the one XDG name the kit reads: scripts/spec-resume.sh:15), never a variable git consults;
or pin git config identically in vf_source_paths for identity and suites.

### D3 — blocking (wrong result). Three suites still copy the live kit's scripts/ with cp -R; one of them feeds the copy to a snapshot
tests/test-gate-contracts.sh:1684 (documented_example_cases, reached from
test_instruction_contracts via public_workflow_cases:1662) runs
`cp -R "$KIT_DIR/scripts/." "$repo/scripts/"` into a Git fixture repo and then runs the
README workflow (spec-run capture, accept, checkpoint, floor) whose vf_snapshot
enumerates that repo, where every copied file is untracked and so an input. Siblings of
the same shape: tests/test-spec-gate.sh:306 (floor_fixture) and
tests/test-spec-dispatch.sh:16 (stage_umbrella) — these two copy into a non-Git sandbox kit whose harness records hash named files only, so I did not find a flip through them; they are the same unhashed read. Decisions (member 3: "every other script a suite runs operates on a copy, so its own globs see only what the copy holds") misses all three.
Repro (copy): `printf 'scripts/zz-dir\n' >> .git/info/exclude; ln -s "$PWD/templates" scripts/zz-dir`.
vf_snapshot 003 before/after: 3c6e3d9b… both, manifests cmp-identical; git status "!! scripts/zz-dir".
test_instruction_contracts alone: FAIL, "expected exit 0, got 3: eval bash scripts/spec-run.sh ... output:
verification inputs: directory symlink requires explicit target files: scripts/zz-dir", then accept,
checkpoint, floor, round all rc=3 and "output missing substring: opponent rounds=1". Link removed: ok, 1/1.
(A relative link dangles in the fixture and does not flip; an absolute one does.)
Fix: every directory copy of the live kit goes through copy_kit's selector
(`copy_kit "$KIT_DIR" "$repo" scripts`, `copy_kit "$KIT_DIR" "$kit" scripts`); no cp -R/tar of "$KIT_DIR/…" remains in tests.

### D2 — minor (fixture vacuous under a leftover). The leftover-spec fixture itself globs the live kit
tests/test-sdd-analyze.sh:589 `for spec in "$KIT_DIR"/.specify/specs/001-* "$KIT_DIR"/.specify/specs/002-*`
and :594 `cp "$KIT_DIR/.specify/specs/${spec##*/}/tasks.md" …/001-stale/tasks.md` (last glob value, cp unchecked).
Repro (copy): `mkdir .specify/specs/002-zz-scratch` (empty; identity unchanged). The fixture still passes,
printing "cp: …/002-zz-scratch/tasks.md: No such file or directory": the ignored 001-stale spec never gets a
tasks.md, so the ignored-files direction tests nothing. Mutant shipped_specs_case that enumerates by
`"$KIT_DIR"/.specify/specs/00[12]-*/tasks.md` (reads ignored files): without the leftover it is KILLED
("expected 2 actual 3", "cannot read .specify/specs/001-stale/spec.md"); with the leftover it SURVIVES (ok 1/1).
Fix: take the sources from the enumeration (the rel002/shipped rels shipped_specs_case derives on the live
kit), copy 002's tasks.md by that name, `|| t_fail` the cp, and assert host/001-stale/tasks.md exists before the call.

### D4 — blocking (regression). tests/run.sh and tests/shellcheck.sh fail on a kit path spelled with different letter case (macOS default APFS)
scripts/verification-lib.sh:1449 (vf_source_paths) compares spellings: `[[ "$(git -C "$1" rev-parse --show-toplevel)" == "$1" ]]`.
tests/run.sh:25 and tests/shellcheck.sh:15 derive ROOT with bash `pwd -P`, which keeps the spelling it was
given; git returns the on-disk case. Repro (copy, /bin/bash 3.2): with V = the copy path spelled .../SCRATCHPAD/...,
`cd "$V/copy" && pwd -P` -> ".../SCRATCHPAD/rev2D/copy", `git rev-parse --show-toplevel` -> ".../scratchpad/rev2D/copy";
`bash "$V/copy/tests/run.sh" lib` -> "verification inputs: Git worktree root required / tests/run.sh: cannot
enumerate the kit (a Git worktree is required)", rc=1. The pre-repair run.sh (git show pre:tests/run.sh) through the
same path: 13/13, rc=0. Same comparison guards copy_kit/kit_files inside every suite: `/bin/bash "$V/copy/tests/test-executable-bits.sh"` -> both tests FAIL ("kit_files: cannot enumerate …/SCRATCHPAD/…", "copy_kit: cannot enumerate …").
The gate's capture path is also exposed: vf_capture takes repo from git (canonical) but cwd from `pwd -P` (as spelled) and
runs `(cd "$cwd" && bash tests/run.sh)`, so an operator in `~/Projects/...` for `~/projects/...` now gets a failing check
(capture not executed; the mechanism reproduced: `cwd=$(cd "$V/copy" && pwd -P); (cd "$cwd" && bash tests/run.sh lib)` -> "cannot enumerate the kit", and the same for `bash tests/shellcheck.sh`; spec-run.sh defaults RUN_CWD to $PWD, :78).
Fix: compare identities, not spellings — `[[ "$top" -ef "$1" ]]` in vf_source_paths (and the same test at vf_snapshot :1464),
and have run.sh/shellcheck.sh use git's toplevel as ROOT once it is -ef the script's root.

### D5 — blocking by the rubric (regression; by design per Decisions). A kit that is not its own Git worktree root can no longer run either command
Repro (copy): `git archive` of post and of pre (without .specify/specs) into plain directories.
pre `bash nogit-pre/tests/run.sh lib` -> 13/13, rc=0. post `bash nogit-post/tests/run.sh lib` -> "tests/run.sh: cannot
enumerate the kit (a Git worktree is required)", rc=1; `bash nogit-post/tests/shellcheck.sh` -> rc=2.
Same for a kit vendored as a subdirectory of another repo (git init; cp -R kit sdd-kit; commit): post rc=1, pre 13/13.
README:330-338 still documents `tests/run.sh` with no worktree precondition. The identity itself refuses a non-root, so no
reuse can apply there; the smallest fix that keeps the reuse property is to distinguish "not a Git worktree root" (vf_snapshot
would refuse; nothing can be reused, so the old glob is harmless — say so on stderr) from a git failure inside a worktree
(fail, as now), and to document the precondition in README. If the refusal is kept deliberately, README and the task text must say so.

### D6 — minor (latent; mechanism reproduced, no reachable kernel trigger found). The trap-scope rule is stated too narrowly: nounset and ${x:?} errors leak too, even on a direct call
tests/helpers.sh:377-382 and the incident record say only `exit` from a subshell function run as the whole of a
command substitution leaks, and that `return`/falling off do not. Under /bin/bash 3.2 with `set -u` (spec-gate.sh:11,
spec-run.sh:34, spec-evidence.sh:31, sdd-analyze.sh:31, spec-ac-coverage.sh:34 all run the kernel so), a
subshell function whose body hits an unbound variable, an empty "${arr[@]}", or `${2:?}` fires its EXIT trap in the
CALLER's scope — in a command substitution, in a `||` list, AND on a plain direct call:
rev2D/exp/t3.sh: `f() ( local tmp=inner; trap 'echo "trap sees: $tmp"' EXIT; echo "$undefined_var" ); tmp=CALLER`
-> "trap sees: CALLER" for `out=$(f)`, `out=$(f) || …`, and `f` direct; same for an empty array and `${2:?missing}`.
(Controls: `exit` direct -> inner; `return` -> inner; a signal -> inner or no trap; errexit is not inherited into $(…).)
19 kernel subshell functions set `trap 'rm -rf "$tmp"' EXIT` / `rm -f "$tmp"` (verification-lib.sh:204, 344, 936,
1216, 1468, 1591, 1769, 1792, 1845, 2089, 2225, 2242, 2276, 2430 [rejects], 2525, 2647, 2698, 2739, 2749), and they
nest with the same name: vf_evidence_current (tmp=its dir) -> vf_snapshot; vf_return_check -> vf_binding_snapshot,
vf_snapshot, vf_task_capture_matches. I found no reachable unbound reference today (the unguarded "${ids[@]}" at :1897 and
"${fields[@]}" at :1597 are guarded by length tests), so no wrong result is reproduced; one future unbound name in any
of them becomes `rm -rf` of the caller's $tmp. Fix (class-wide, one line each): bind the value, not the name —
`trap "rm -rf -- $(printf %q "$tmp")" EXIT` — or the wrapper-owns-directory pattern copy_kit now uses; and correct the comment.

### D7 — blocking (wrong result). The new host-kit fixtures assume git init creates .git/info/exclude; a global init.templateDir flips them
make_host_kit (tests/helpers.sh, `copy_kit … && git -C "$1" init -q`) and the fixtures then append ignore rules to
"$host/.git/info/exclude": tests/test-executable-bits.sh:30, tests/test-gate-contracts.sh:525, tests/test-sdd-analyze.sh:593,
tests/test-verification.sh:394 and :407. git creates info/exclude only from the template directory; with
`init.templateDir` pointing at a template without info/ (the usual git-secrets / global-hooks setup) or GIT_TEMPLATE_DIR,
there is no info/ directory: `GIT_TEMPLATE_DIR=<empty> git init` -> .git holds HEAD, config, objects, refs only.
Repro (copy): HOME=$R/h7/home whose .gitconfig sets init.templateDir to an empty directory. vf_snapshot 003: 3c6e3d9b…
(unchanged). `bash tests/run.sh executable` -> rc=1: "…/host-kit/.git/info/exclude: No such file or directory" then
"FAIL test_AC_011_ignored_local_scripts_do_not_decide_the_executable_check / assert: tracked without the executable bit: zz-local.sh".
Configuration outside the repository decides a reuse-checked verdict — the obligation this task states.
Fix: create the file's directory where the rules are written (`mkdir -p "$1/.git/info"` in make_host_kit, and in the
fixture that git-inits its host itself, test-sdd-analyze.sh:588), or write the
rules to a host-level .gitignore; do NOT neutralize global git config inside suites, which would widen D1.

### D8 — minor (read, not executed). Two small leftovers
(a) tests/shellcheck.sh:11/18-22/32 uses exit 2 for "cannot enumerate" / "no scripts", which is also ShellCheck's own
"some files could not be processed" status, so a caller cannot tell the two apart. Fix: use a status ShellCheck never
returns (e.g. 5) or document the overlap. (b) First-pair m2 is only half closed: the scan's read-failure branch is now
pinned (locked.md fixture), but its awk-failure branch (tests/test-gate-contracts.sh:133, "cannot scan") has no fixture
and no assertion anywhere in tests/, so its removal mutant survives by construction.

## Held
- Mutation matrix (each fixture run alone in the copy; each mutant restored with git checkout; control passes):
  M1a overlay glob / M1b persona glob -> test_ignored_local_overlays_and_personas_do_not_decide_the_checks FAIL (exact contract diagnostics);
  M6 executable-bits glob -> test_AC_011_ignored_local_scripts… FAIL ("tracked without the executable bit: zz-local.sh");
  M2 tally in place -> test_empty_record_directories… FAIL (rc 3); M4 doctor cp -R -> test_AC_009_doctor_fixture… FAIL
  (three assertions); M5a old stage_kit tar -> FAIL (registry.yml assertion only; the models.yml-link assertion cannot see
  the old tar because the fixed writer replaces the link); M5b writer without rm -f -> FAIL (link kept, target cksum changed);
  M7a run.sh glob -> reuse_command_input_cases FAIL ("expected exit 2, got 1", local-suite-ran); M7b no --norc and
  M7c SHELLCHECK_OPTS kept -> FAIL each independently (SC2154 HUB_DIR); M7d reset removed -> FAIL.
  shipped_specs_case file-glob mutant -> test_leftover_spec_directories… FAIL (but see D2).
- tests/run.sh sourcing verification-lib.sh/lib.sh has no top-level side effect (no export/set/trap); empty-suite-array
  expansion is 3.2-safe; exit 2 on no match, 1 on suite failure, 1 on no enumeration (observed).
- bsdtar with an empty -T list (copy_kit selector matching nothing) exits 0 with and without pipefail.
- ShellCheck 0.11 under LC_ALL=C/LANG=C: rc 0, no locale dependence on macOS.
- sdd-analyze on 003 with the changed T027/T030o41 Verify: rc 0, 1 warning (task count). vf_config accepts the new gate/reuse lines.
- Kernel EXIT traps: no shell-level `exit` reachable inside a trap-bearing function (only awk exits and vf_writer_init's
  global signal traps, which are not inherited into $(…) — observed: TERM with a parent `exit 143` trap kills the comsub
  without running any EXIT trap). No script redefines a library function. Tests hold no EXIT trap except the top-level
  tests/probe-gate-contract.sh.

- Invoking a test_* function from another with `KIT_DIR=host`: the nested tests read the host through KIT_DIR
  (mutation diagnostics quote the host's zz-local files), SCRIPTS stays the live kit (harmless: only vf_source_paths /
  the analyzer / the tally are taken from it), every nested enumeration asserts non-empty, and a failing nested
  assertion fails the outer test. The one wrong-reason pass found is D2 (a live-kit glob inside the fixture).
- tests/shellcheck.sh: file set equals the old glob's except ignored files (and would add a tracked dot-file script);
  `env -u` is supported by BSD, GNU and BusyBox env; --norc and SHELLCHECK_OPTS unset each independently killed (M7b/M7c).
- Gate/floor code path read: vf_gate_execute reuses only on exact argv + bindings + inputs; the changed command strings
  simply make older captures non-reusable; T027's stale capture is reported as "current evidence missing/stale", as for any
  source change. Not executed (brief forbids floor/checkpoint/accept/round).

## Not reached
- ShellCheck 0.9 (Ubuntu 24.04) — only 0.11 installed; GNU tar (copy_kit on Linux CI; `-T` names beginning with "-") —
  not installed; Bash 4/5 — only /bin/bash 3.2 available, so every run here was 3.2.
- Full unfiltered `bash tests/run.sh` in the copy (swap nearly full; single functions and small suites only).
- A reachable nounset trigger inside a kernel trap-bearing function (D6 stays latent).
- Hook environments (exported GIT_DIR / GIT_INDEX_FILE): pre-existing fixture exposure (git -C … add/commit), not attacked.
- spec-gate floor/checkpoint/round/accept and spec-run capture: not run per the brief; D4's capture exposure shown by mechanism only.

