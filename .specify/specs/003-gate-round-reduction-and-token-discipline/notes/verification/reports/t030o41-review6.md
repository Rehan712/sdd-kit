# Review 6 of T030o41 (spec 003) — focused delta review of t030o41-session4c.diff

COMPLETE — verdict: BLOCKED (R6-4 blocking: reproduced regression of the matrix, K33 now unkillable; R6-1, R6-2, R6-3, R6-5 minor)

Reviewer: independent read-only (security-reviewer persona), 2026-09-25. Delta: t030o41-session4c.diff (7 files); pre-delta at scratchpad/s4c/pre.

## Findings

Method: my copy is at rev6/copy, a standalone git repo whose single commit `base` holds the worktree's own
`git ls-files -z --cached --others --exclude-standard` enumeration, taken with GIT_OPTIONAL_LOCKS=0. I recomputed
PRE_DIR->copy over the 7 files plus scripts/verification-lib.sh, which is unchanged. Ignoring hunk headers, the
result matches t030o41-session4c.diff line for line. TMPDIR=rev6/tmp. Git 2.50.1 (Apple Git-155), /bin/bash 3.2.57, macOS.
The per-function runners are made as dev11 makes them (`tests/.one-*.sh`, excluded through .git/info/exclude). My single-function
runner (rev6/exp/one.sh) is dev11's run_one, including its build-failure record check. After every run, the copy's
`git status --porcelain --ignored` matched its baseline (the 15 ignored runners).

### R6-1 (minor: reproduced write outside the sandbox; no ambient trigger found after the scrub) — once a fixture build fails, its caller keeps running, and later `fixture_git` writes find their repository by searching upward. When `init` is the step that failed, they commit into any repository that encloses TMPDIR
- tests/helpers.sh:579-585 (make_verification_git_dir: records, prints the sandbox path, returns 1, and callers go on).
  tests/test-verification.sh:822-823 (`fixture_git -C "$SANDBOX/anchor-digits" add -A && fixture_git ... commit -qm digits`),
  :720/:729/:732/:802/:810 (bookkeeping `add -f`, `rm --cached`, `config`), :274/:277/:281 (test_capture_provenance
  `checkout`/`add`/`reset`), :630 then :638 (kit-copy: `init -q || fixture_build_failed kit-copy`, then `add . && commit`).
  Claim: tasks.md T030o41 Acceptance, "a fixture repository that cannot be built fails its test by name whatever the
  caller does with the status, while leaving no caller a path outside its sandbox".
- Mechanism. By design the record lets a caller that ignores the status continue. When `init` failed, `$repo` has no
  `.git`, so every later `fixture_git -C "$repo" …` write searches upward from the sandbox. fixture_git pins git's
  configuration and environment. It does not pin where a repository is looked for, and its scrub also removes any
  GIT_CEILING_DIRECTORIES the caller had set. Every path the fixture hands out is inside the sandbox, but the repository
  those writes resolve to is not.
- Repro (copy; rev6/exp/discovery.sh; everything under rev6/tmp). E is a scratch repository with one commit and one
  untracked file, pending.txt. TMPDIR=E/tmp. A PATH shim `git` exits 128 when any argument is `init` and execs /usr/bin/git
  otherwise (review 5's R5-5(a) shim). No ancestor of rev6 is a repository (`git -C rev6 rev-parse` → not a git repository).
  - bookkeeping_anchor_cases: rc=1, `cannot build the make_verification_git_dir anchor fixture repository` (the record
    works), then the function runs to the end. E before: commits=1, index-entries=0. E after: commits=2,
    `head-author='Fixture: digits'`, index-entries=49, `49 files changed, 351 insertions(+)`. The commit holds E's own
    pending.txt, staged by `add -A`, and every sandbox file, `tmp/sddkit.QqPnEO/.fixture-build-failed` included.
  - kit_copy_cases: E after, commits=2, `head-author='Fixture: fixture'`, 7 files (`tmp/sddkit.2R0x8f/kit-src/...`).
- Against PRE_DIR, from the code and review 5's trace (not rerun: it writes at `/`): the pre-delta helper printed
  nothing, so bookkeeping_anchor_cases resolved `repo=/` and aborted at `${spec:?}` (PRE_DIR :697, post :733) in its first iteration,
  before the anchor-digits commit. The delta removed the root-path writes, a real improvement in the common case where
  TMPDIR is outside every repository. In their place it lets the function reach this commit. The kit-copy site is
  pre-existing: its `init` was unchecked before and the build still continues after it.
- Trigger: an `init` that fails while later git writes succeed, with TMPDIR inside a Git worktree (TMPDIR under a
  project, or a home directory kept as a repository). Before this delta, GIT_QUARANTINE_PATH was exactly such an input:
  it refuses `init`'s HEAD write and allows `add` and `config`. The scrub removed it, and I found no configuration or
  environment input left that fails `init` alone. That is why I rate this minor. Any future input that fails `init`
  alone makes it a data-mutation defect, and any failed-build probe run with TMPDIR inside a repository does the same.
- Smallest class-wide fix: have fixture_git pin where a repository may be found, as it pins everything else, for
  example `GIT_CEILING_DIRECTORIES="$SANDBOX"`. No fixture repository is `$SANDBOX` itself, so every fixture repository
  is still found from inside, and a write in a directory without its own repository fails instead of climbing. Add a row:
  the failed-build fixture with TMPDIR inside a scratch repository, asserting that repository is unchanged.
- Fix measured in the copy (then restored with `git checkout`): with `GIT_CEILING_DIRECTORIES="$SANDBOX"` added to
  fixture_git's `env` line, the same probe of bookkeeping_anchor_cases leaves E at commits=1, index-entries=0. Unprobed,
  bookkeeping_anchor_cases, kit_copy_cases and fixture_repository_cases each give rc=0.

### R6-2 (minor: pre-existing, but inside the rule the Decisions entry states for every helper) — three copy helpers break "a fixture helper whose output a caller uses as a path never leaves it an empty one" and "a helper run as a command substitution cannot fail its test itself"; their callers then write at `/`
- The rule, as the last Decisions entry states it: "A fixture helper whose output a caller uses as a path may never leave
  it an empty one, and a failed build must fail its test whatever the caller does with the status." fixture_build_failed's
  own comment gives the reason: "a helper run as a command substitution cannot fail its test itself". The repair
  applied the rule to repository builds only. These kit-copy fixture helpers are outside it:
  - tests/test-build-adapters.sh:17-23 `stage_kit`: on a failed copy it prints nothing and returns 1. None of its 7
    callers (`kit="$(stage_kit)"`, :52 :76 :97 :114 :166 :204 :239) checks the status, and then `$kit/...` is `/...`:
    :86 `grep -v … "$kit/models.yml" > "$kit/models.yml.tmp"`, :98 `rm "$kit/models.yml"`, and `write_policy_file "$kit"`
    (`rm -f "$1/models.yml"; cat > "$1/models.yml"`, :29-30).
  - tests/test-golden-example.sh:22-23 `stage_example` and tests/test-spec-gate.sh:308 `floor_fixture` call `t_fail`
    inside the command substitution that runs them (`spec_dir="$(stage_example)"`, `gate="$(floor_fixture …)"`, 13
    callers). The failure is lost with the subshell, and the `assert:` text is captured into the path variable.
- Repro (copy, with its `.git` moved aside, the unsupported but ordinary case of a suite run from an exported tree, so
  copy_kit's vf_source_paths refuses; every run under `sandbox-exec -f rev6/exp/rev6.sb`, which denies any write outside
  rev6, root included; `.git` restored and hermeticity rechecked afterwards):
  - test_prune_respects_kit_marker_and_role_unmapping: rc=1, `stage_kit: cannot stage the kit copy`, `bash
    /scripts/build-adapters.sh: No such file or directory`, then `line 86: /models.yml.tmp: Operation not permitted`.
  - test_degrades_without_policy_or_codex_home: rc=1, `rm: /models.yml: No such file or directory` (it would delete an
    existing /models.yml), then `line 30: /models.yml: Operation not permitted`, write_policy_file writing at the root.
  - test_golden_example_passes_sdd_analyze_with_zero_warnings: rc=1. The name is lost: the only trace of the copy failure
    is inside another assertion's argv: `expected exit 0, got 2: …/scripts/sdd-analyze.sh assert: cannot copy the
    example as the input…`.
- On a writable root (a container running as root) the first two tests create /models.yml.tmp and /models.yml, and
  delete any existing /models.yml. The tests still fail, so no verdict is wrong. That is why I rate this minor.
- Smallest class-wide fix: the same rule for every fixture helper whose output is a path. On failure it calls
  fixture_build_failed (rename it for copies, or make it generic) and still prints its sandbox path: `stage_kit` →
  `{ fixture_build_failed "stage_kit copy"; echo "$kit"; return 1; }`, `stage_example` and `floor_fixture` the same
  in place of `t_fail`. `stage_umbrella` (tests/test-spec-dispatch.sh:18) has the same shape, but its callers write
  nothing through `$dir`, so it needs the fix only for the name.

### R6-3 (minor; matrix) — E19 is argued equivalent on a false premise. A failing git is exactly what fixture_repository_cases itself plants, and under it E19 changes a verdict: `test_default_root_is_the_git_toplevel` goes from failing by name to passing
- notes/verification/reports/t030o41-mutations.sh, the comment above `e19()` ("the per-site build checks fire only when a
  pinned build fails, which no plantable input causes; fixture_repository_cases proves the mechanism once (K67 to K69)")
  and `mutant equiv E19-site-build-checks-removed …`. Decisions (2026-09-25 repairs): "Argued equivalents cover … the
  per-site build checks. The per-site checks fire only when a pinned build fails". Site:
  tests/test-spec-ac-coverage.sh:62.
- A failing git on PATH can be planted from a sandbox. fixture_repository_cases plants one (`$shim/git`, exit 128), and
  review 5's R5-5(a) used one that refuses only `init`. The @hostile judge plants only configuration and environment,
  so under it E19 cannot fail, and the row records that as equivalence.
- Repro (copy; `rev6/exp/noinit/git` exits 128 when any argument is `init`, else execs /usr/bin/git; each run under
  sandbox-exec, write-confined to rev6; restored with `git checkout`, hermeticity rechecked):
  - unmutated, plain: `test_default_root_is_the_git_toplevel` rc=0.
  - unmutated, init refused: rc=1, `build-failure record: ac-coverage-project` (the repair works).
  - E19's own ac-coverage literal (` || fixture_build_failed ac-coverage-project` → ``, occurs once) applied, init
    refused: rc=0, only `git: init refused (probe)` in the output. That is R5-5(a) again: the test named "default root is
    the git toplevel" passes with no repository.
- So E19 is a surviving mutant, not an equivalent one, and a site check can be deleted without any row failing. Review 5
  asked for a row per check, killed under FR's failing-git shim.
- Smallest class-wide fix: add a judge suffix such as `@no-init` (an init-refusing git shim first on PATH, judged by the
  same runner) and turn E19 into per-site kills under it. Where a site's test would fail anyway with no repository (for
  example the tally and doctor hosts, whose later enumeration refuses), assert the build-failure record's name, which
  only the check produces. Say in the comment that the @hostile judge plants no failing git.

### R6-4 (blocking: reproduced regression of the matrix of record, caused by this delta; no runtime behaviour is wrong) — the new GIT_* scrub makes K33 unkillable: the suite-start clearing of git's repository-local names can be deleted and no fixture notices
- tests/helpers.sh:44 (`for _t_env in $(git rev-parse --local-env-vars); do unset "$_t_env"; done`), whose stated purpose
  (:36-40, and the Acceptance) is "so a repository is named by its path alone and no fixture can write a caller's index".
  Its only fixture is tests/test-verification.sh:503-506: a nested `bash -c '. helpers.sh; SANDBOX=…;
  make_verification_git_dir nested'` under `GIT_INDEX_FILE=$foreign`, asserting the caller's index is unchanged. Matrix row:
  `mutant kill K33-suites-keep-git-local-environment k33 "$RV"`.
- The delta's fixture_git now removes every exported GIT_* name itself, so the nested build never sees GIT_INDEX_FILE,
  whether or not helpers.sh cleared it. The one assertion that judged the suite-start clearing now passes without it.
  No other fixture re-sources helpers.sh with a repository-local name planted. The plantings at
  tests/test-gate-contracts.sh:316 and tests/test-verification.sh:853-861 happen after load and reach only the kernel,
  which clears those names for its own processes (vf_git_local_unset).
- Repro (copy; K33's own literal, which occurs once; `reuse_command_input_cases` single-function, harness-style,
  under sandbox-exec; restored with `git checkout`, hermeticity rechecked):
  - post-delta unmutated: rc=0 (65 s). post-delta + K33: rc=0 (65 s), no assertion. The kill row SURVIVES.
  - PRE_DIR's tests/helpers.sh and tests/test-verification.sh swapped in, + K33: rc=1, `assert: AC-020: a fixture's git
    wrote the caller's index through an inherited GIT_INDEX_FILE`. PRE_DIR unmutated: rc=0. So this delta turned the
    kill into a survivor.
- Every recorded K33 result is a dry run (v2 to v5 dry logs), and the v5 probes did not run K33, so nothing recorded
  shows this. The first real matrix run will print `FAIL K33-… KILLED (want=1 got=0)`. Meanwhile the clearing still
  matters: without it a hook-exported GIT_DIR or GIT_INDEX_FILE redirects the suites' raw git reads (for example
  fixture_repository_cases' `git -C "$repo" rev-parse --verify HEAD`, `ls-files` and `log`, and test_capture_provenance's
  `git show HEAD:… > "$repo/…"`) and the kit's own git calls outside the kernel. The Acceptance's "each site has a
  fixture in both directions" no longer holds for this site.
- Smallest class-wide fix: judge the clearing where it acts, at helpers.sh load, not through a fixture write that
  fixture_git now also guards. The SDD_* probe at tests/test-verification.sh:419-420 already does that. Add
  `run_rc 0 env GIT_INDEX_FILE=… GIT_DIR=… bash -c '. "$1/tests/helpers.sh"; [[ -z "${GIT_INDEX_FILE+set}${GIT_DIR+set}" ]]' _ "$KIT_DIR"`
  (every name `--local-env-vars` prints, or a loop over them), and keep the nested-build assertion as fixture_git's
  own. As a class check: for each existing row, ask whether the delta's new guard now shields the line the row
  mutates. Reading the rows (not running them), I found no other such row. K49/K50/K61/K62/E07/E08 go through git_config_pinned, which fixture_git no longer uses,
  and K39 is still killed through git_host.

### R6-5 (minor; claims) — the last Decisions entry still states three arguments the invoker's own v5 probes refuted, plus one my runs refute; K74's removal leaves one fixture_git site with no row at all
- STATUS.md Decisions, 2026-09-25 "Repairs for review 5":
  (a) "E13 splits into a kill for the add, checkout and reset sites, and an argued equivalent for rm --cached and config,
  which neither an eol setting nor a filter reaches". The K74 note measured the hostile filter reaching `rm -f --cached`
  (killed in 2 of 4 runs). So the filter does reach it, and the site is no argued equivalent.
  (b) "Argued equivalents cover the template pin and its mkdir". The template pin is the kill K73 since probe 1
  (`FAIL E16… SURVIVES`, relabelled).
  (c) "The per-site checks fire only when a pinned build fails" as the basis for equivalence: refuted, see R6-3.
  (d) "make_verification_git_dir … still prints its sandbox path, so none of its 27 callers can resolve outside
  $SANDBOX". The paths hold, but the repository its callers' later writes find does not: see R6-1.
  The where-things-stand paragraph (STATUS.md:22) records the (a)/(b) relabels. The Decisions entry, which the brief names
  as the reason for each change, does not, and that log is about to be frozen.
- The K74 decision itself: removing a row whose verdict depends on timing is right for a matrix of record. The measured
  mechanism is plausible: git re-hashes an index entry through the clean filter only when its stat data cannot prove it
  clean. But the note's justification, "the site stays pinned … for the same reason as the add sites K72 kills
  deterministically", is a reason to keep the pin, not evidence that reverting it would be seen. After the removal,
  tests/test-verification.sh:732 is the one fixture_git site with neither a kill row nor an argued-equivalent row, and a
  revert there goes unseen in about half of runs. Record it as a known unjudged site (with its measured 2-of-4) in
  Decisions when the matrix result is recorded, rather than leaving the refuted argument (a) in place.
- Smallest fix: when the matrix result is recorded, amend or supersede (a) to (d) in the Decisions entry, and name the
  unjudged :732 site.

## Held

- R5-4, the scrub itself (rev6/exp/scrub.sh, helpers.sh sourced, a build under a function-call prefix of GIT_AUTHOR_*,
  GIT_COMMITTER_*, GIT_AUTHOR_DATE, GIT_DEFAULT_HASH=sha256, GIT_DEFAULT_REF_FORMAT=reftable, EMAIL, GIT_ATTR_SOURCE=nosuchrev,
  GIT_QUARANTINE_PATH, GIT_CONFIG_GLOBAL/SYSTEM, GIT_TEMPLATE_DIR, GIT_EXEC_PATH, GIT_CEILING_DIRECTORIES=/). Result:
  build rc=0; author and committer `Fixture <fixture@example.invalid>` at the real time; objfmt=sha1, reffmt=files.
  Inside fixture_git, `config --list --show-origin --show-scope` shows only `.git/config` and the two command-line
  identity entries, even with GIT_CONFIG_PARAMETERS planted. Under bash 3.2, `compgen -e` lists temporary assignments
  made before a function call, so the scrub sees them. It also removed an ambient GIT_EDITOR.
- R5-4, whether the family removal breaks a fixture's need. No suite sets a GIT_* name for a fixture build on purpose (grep).
  The one caller that sets GIT_TEMPLATE_DIR for git_host (tests/test-verification.sh:516) asserts only what the empty
  template gives it anyway. The remaining non-GIT_ inputs of these writes (PATH, TZ, LANG) choose the git binary or
  format timestamps and messages. They decide no fixture content, and PATH is the one the kernel uses too.
- E13's argument, for the ambient environment. Git 2.50.1 does honour the legacy GIT_CONFIG for `git config` writes
  (rev6/exp/gitconfig-env.sh: a raw write lands in the named file and the repository keeps `true`; `env -u GIT_CONFIG` puts
  it back). But GIT_CONFIG is one of the 15 `--local-env-vars` names that helpers.sh clears at load, so no ambient value
  reaches the config sites, and the kernel's `ls-files` ignores it. My only caveat is R6-4: that clearing is now unjudged.
- Raw git writes in the suites: after the delta, only the deliberate control at tests/test-verification.sh:549
  (grep over init/add/commit/checkout/reset/rm/config and plumbing writers, excluding fixture_git and reads).
- R5-2 and R5-5 mechanism. A failed make_verification_git_dir records its failure and prints the sandbox path (K68/K69
  killed in v5-probe). The record lives in the per-test SANDBOX, only t_run_all removes it (no test deletes, moves or
  chmods the sandbox), and the only SANDBOX reassignments are FR's own `$failing` and the :505 nested build, which checks
  its status with `run_rc 0`. No test shims git around a fixture build other than FR. So no record leaks, and none fails a
  test that built nothing. The nested-suite fixture is a genuine negative: K67 is killed there (v5-probe: nested exit 0,
  `FAIL test_ignores_a_failed_build` missing). Caveat: bash sorts `declare -F` (checked), so `test_builds_nothing` runs
  before the failing test and could not see a record leaking forward. Such a leak is caught today only by FR's `$failing`
  record assertion. Naming the clean test so it sorts last would make it cover that too.
- R5-3. Tree 2's canary works: it must report exactly `canary.md`, and the over-correction diagnostic stays on everything
  else (K60 killed in v5-probe by `the control tree was not scanned`). Tree 3's empty-result control (:273) has no canary of
  its own. The positive at :285 on the same tree fails whenever its enumeration is emptied, so the tree is not vacuous.
  The live-tree control (:143) asserts the scan's exit. The executable-bits control asserts `[[ -s "$list" ]]` (:18).
- R5-1, the harness reach. With the widened @hostile environment each guarded operation has a planted input: init
  (template, GIT_DEFAULT_HASH, quarantine), add (the required filter), commit (hooks, signing, author environment,
  quarantine) and checkout (autocrlf). reset is killed ALONE, deterministically. I applied only K72's reset literal in the
  copy and ran test_capture_provenance@hostile twice under sandbox-exec: rc=1 both times, `fatal: src/parser.sh: clean
  filter 'reject' failed`, `generated bookkeeping stays reusable`. Entries taken from a tree carry no stat data, so their
  refresh always re-hashes. So K72's bundle hides no weak site. rm --cached is timing-dependent (the K74 note), and nothing
  plantable reaches config (above).
- The runners' build-failure check (dev11 run_one, the matrix run_one) matches t_run_all's, and the matrix's @hostile
  planting is what its header says (I re-derived it verbatim in rev6/exp/hostile-env.sh). One note: GIT_DEFAULT_HASH is
  planted by FR, dev11 and @hostile but asserted nowhere, so a scrub that let it through would survive. Review 5 found no
  verdict it changes, so this is decorative, not a gap.
- Mutant literals: v5-dry2 applies 94 rows with `matrix failures=0`. The matrix in my copy is cmp-identical to the live
  one. The site rows (K57, K59, K60, K63, K64, K65, E11, E12, E14) restore the pre-F2 raw lines, as review 5 credited. The
  new-guard rows (K55, K67, K68, K69, K70, K71, K54, K58, K73) remove exactly the delta's lines. K73's kill is
  host-dependent: it needs a non-empty installation template `info/exclude`.
- The contract paragraph and the fixture_git comment claim nothing recorded open as fixed: the bash startup
  environment, the kernel's ambient reads of fixture repositories and global excludes, the analyzer grammar, the umbrella
  readers. Both state the kernel's reads as open. Apart from R6-1's repository search, the contract sentence is what
  the code does.
- The recomputed PRE_DIR→copy diff equals t030o41-session4c.diff. dev11's receipts read exit 0 (quick 25 PASS, full
  143/143 plainly and hostile, live digest unchanged in both).
- Hermeticity. After every run, the copy's `git status --porcelain --ignored` matched its baseline. The live worktree's
  `git status --porcelain -uall -z` digest was `99b0cfe4…d0ba0` before and after this review. Every failed-build probe ran
  under sandbox-exec (rev6/exp/rev6.sb, which denies every write outside rev6) or with TMPDIR inside a scratch repository
  in rev6. The pre-delta failed-build path was not run, because it writes at `/`.

## Not reached

- The whole suite and the whole matrix, deliberately. I ran single functions only: bookkeeping_anchor_cases,
  kit_copy_cases, fixture_repository_cases, reuse_command_input_cases (plain and K33, post and PRE_DIR),
  test_default_root_is_the_git_toplevel, test_capture_provenance@hostile (reset literal, twice), and three build-adapters
  and golden-example functions under sandbox-exec.
- A mutant restoring PRE_DIR's exact fixture_git body (the git_config_pinned route). K70 removes more than that, so it is
  not the exact revert. I did not run the exact revert. Review 5's reproduction (GIT_QUARANTINE_PATH refusing `init`)
  implies FR kills it.
- A real writable root (Linux, a container as root). R6-1's enclosing-repository commit was observed. R6-2's root writes
  were observed only as sandbox-exec denials.
- K74's timing on other filesystems or git builds (nanosecond stat), E17/E18 re-runs, stage_umbrella's and
  floor_fixture's failure paths (read, not run), Bash 4/5, and git versions other than 2.50.1 (Apple).

REVIEW COMPLETE
