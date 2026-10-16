# Review 7 of T030o41 (spec 003) — focused delta review of t030o41-session4d.diff

COMPLETE — verdict: no blocking finding. Four minor: F1 (ceiling bypass routes), F2 (site checks without a row), F3 (claim), F4 (pre-existing unchecked fixture write).

Reviewer: independent read-only (security-reviewer persona), 2026-09-25. Delta: t030o41-session4d.diff (7 files);
pre-delta at scratchpad/s4d/pre. Git 2.50.1 (Apple Git-155), /bin/bash 3.2.57, macOS 26 (Darwin 25.4).

Method: my copy is rev7/copy, a standalone git repository whose one commit `base` holds the worktree's own
`git ls-files -z --cached --others --exclude-standard` enumeration (GIT_OPTIONAL_LOCKS=0). Recomputing PRE_DIR -> copy
over every file PRE_DIR holds (11; four are unchanged) gives t030o41-session4d.diff line for line, ignoring hunk headers.
TMPDIR=rev7/tmp. Every probe that can fail a build ran under `sandbox-exec -f rev7/rev7.sb` (deny file-write* outside
rev7; checked first: a `touch` outside rev7 gives `Operation not permitted`). Nothing was run in the worktree.

## Findings

### F1 (minor: reproduced write into an enclosing repository at the helper level; no current fixture reaches it) — the new ceiling is not a bound in three cases: a write whose directory IS `$SANDBOX`, a `$SANDBOX` containing `:`, and a relative `$SANDBOX` (both from TMPDIR)
- tests/helpers.sh:471 (`GIT_CEILING_DIRECTORIES="$SANDBOX" \`). Claims: templates/verification-contract.md:203-204
  "git never climbs out of the fixture's sandbox to find a repository"; the fixture_git comment (helpers.sh:456-460);
  Decisions 2026-09-25 (R6-1) "a write in a directory with no repository of its own fails instead of climbing".
- Mechanism. Git applies a ceiling only when it is a proper ancestor of the directory it starts from, so a ceiling
  equal to the start directory is ignored and the search climbs to `/`. And GIT_CEILING_DIRECTORIES is a
  colon-separated list with no escape, so a `$SANDBOX` holding `:` is split into pieces that are not ancestors of
  anything, and no ceiling applies. Git also drops every relative entry. mktemp accepts a TMPDIR with `:` and a
  relative TMPDIR (`TMPDIR=rel mktemp -d "$TMPDIR/sddkit.XXXXXX"` prints `rel/sddkit.GnGayK`), and t_run_all builds
  SANDBOX from TMPDIR.
- Repro (copy; rev7/exp/ceiling-routes.sh under sandbox-exec; E=rev7/exp/encl is a scratch repository with one commit;
  each probe sources the copy's tests/helpers.sh and runs `fixture_git -C <dir> add -A` with SANDBOX set as shown, after
  planting one untracked file in <dir>):
  - control, SANDBOX=E/sb1, dir E/sb1/proj: `add rc=128`, E's index `1 -> 1` (the repair works).
  - SANDBOX=E/sb2, dir E/sb2 (the sandbox itself): `add rc=0`, E's index `1 -> 3`.
  - SANDBOX=`E/a:b/sb3`, dir `E/a:b/sb3/proj`: `add rc=0`, E's index `1 -> 4`.
  - from E, SANDBOX=`rel/sb` (relative), dir `rel/sb/proj`: E's index `1 -> 5`, `rel/sb/proj/planted.txt` staged.
  Raw git confirms both rules: `GIT_CEILING_DIRECTORIES=E/sb git -C E/sb rev-parse --show-toplevel` prints E, and from
  E, `GIT_CEILING_DIRECTORIES=rel git -C rel/proj rev-parse --show-toplevel` prints E.
- Reach today. No fixture write runs in `$SANDBOX` itself (every `fixture_git -C` names a repository root below it;
  ac-coverage's `fixture_git init -q "$SANDBOX/proj"` does no discovery), so the first case is latent, and the comment's
  "No fixture repository is $SANDBOX itself" is the wrong condition: what matters is that no write RUNS there. The
  second and third need a TMPDIR with `:`, or a relative one, plus R6-1's trigger (an `init` that fails while later writes succeed); then R6-1 is back
  unchanged. K75's judge (the enclosing probe) runs with an absolute, colon-free TMPDIR, so it sees none of the three.
- Smallest class-wide fix: t_run_all makes SANDBOX absolute and resolved (`cd "$(mktemp -d ...)" && pwd -P`), and
  fixture_git bounds the search at the sandbox's parent, `GIT_CEILING_DIRECTORIES="${SANDBOX%/*}"`, which also stops a
  search that starts in `$SANDBOX` (measured: with ceiling E, `git -C E/sb2 rev-parse` is "not a git repository", while a repository at E/sb4
  is still found from E/sb4/sub), and make fixture_git refuse a `$SANDBOX` containing `:` by name (git has no escape
  for it). Then the contract sentence holds as written.


### F2 (minor; matrix) — R6-3 is not applied to every site check: R02 bundles kit-copy's two checks, so its add/commit check can be deleted alone with no row failing, and the delta's own new `enclosing` checks have no row
- tests/test-verification.sh:667-668 (`fixture_git -C "$src" add . && fixture_git -C "$src" commit -qm fixture \ ||
  fixture_build_failed kit-copy`) and :659 (`init -q || fixture_build_failed kit-copy`); matrix
  `r02()`/`R02-kit-copy-build-checks-removed` removes both at once. :616 and :618-619 (`|| fixture_build_failed
  enclosing`): `grep -n enclosing t030o41-mutations.sh` finds nothing. Claim: Decisions 2026-09-25 (R6-3) "Each site
  check becomes a `record` row in place of E19".
- Mechanism. Both kit-copy checks write the same name, and @no-writes refuses `init` first, so :659 always names
  kit-copy and the `record` test (name present or absent) cannot tell whether :667-668 still exists. The check is not
  redundant: when `init` works and `add` or `commit` fails, it is the only thing that names the failed build, because
  kit_copy_cases enumerates `--cached --others` and passes on an uncommitted repository. (Conversely, by reading, :659
  is now equivalent: with the ceiling, a failed `init` makes the `add` fail too, and :667-668 names it.)
- Repro (copy; rev7/exp/r02split.sh; kit_copy_cases single-function, the matrix's run_one, under sandbox-exec;
  `nowrites/git` is the matrix's @no-writes shim verbatim, `nocommit/git` exits 128 on `commit` only; restored with
  `git checkout`, copy status equal to baseline afterwards):
  - unmutated @no-writes: rc=1, record `kit-copy kit-copy`. unmutated @no-commit: rc=1, record `kit-copy`.
  - r02's second literal alone (the :667-668 check removed, :659 kept), @no-writes: rc=1, record `kit-copy`. A record
    row for this check SURVIVES.
  - the same mutant, @no-commit: rc=0, no record. kit_copy_cases passes with a fixture repository that has no commit:
    R5-5(a)/R6-3's shape again, unjudged.
- The `enclosing` checks are the only thing that names a failed build of the probe's own enclosing repository.
  Repro (rev7/exp/encl-check.sh; fixture_repository_cases single-function under sandbox-exec, with `noencl/git` first on
  PATH, which exits 128 only for an `init` whose argument ends in `/enclosing`): unmutated rc=1, record
  `enclosing enclosing`; both checks removed (:616 and :618-619 literals, each once): rc=0, no record. The fixture
  then passes with no enclosing repository, so its K75 probe protects nothing (its raw reads climb out of the
  sandbox; with rev7/tmp outside any repository both `commits` and `index` read empty before and after), and no row
  can see the removal.
- Smallest class-wide fix: one row per check, and a judge that fails the step the check guards: a `@no-commit` judge
  (a git refusing only `commit`, or only `add`) for the second checks that follow a checked `init` (kit-copy
  :667-668, enclosing :618-619), with record rows for each and for enclosing's `init` check under @no-writes. (The
  single-check sites, make_verification_git_dir, git_host and letterless-spec, are judged already: K69, R01, R03.) Or give the second check its own name (`kit-copy commit`), so R02 can be
  split under the existing judges.

### F3 (minor; claims) — "The nested-build assertion stays, as fixture_git's own" is not what it judges: it fails only when BOTH the load-time clearing and fixture_git's scrub are gone
- Decisions 2026-09-25 "Repairs for review 6", (R6-4): "The nested-build assertion stays, as `fixture_git`'s own."
  Site: tests/test-verification.sh:513-516 (`env GIT_INDEX_FILE="$foreign" bash -c '. "$1/tests/helpers.sh";
  SANDBOX="$2"; make_verification_git_dir nested'`, then the caller's index checksum).
- Mechanism. The nested shell sources tests/helpers.sh, whose line 45 unsets GIT_INDEX_FILE before the build starts,
  and fixture_git's scrub removes it again. Each guard alone hides the other's absence, so the assertion judges
  neither: review 6's R6-4 was the K33 half of this, and the K70 half is the same.
- Repro (copy; rev7/exp/nested.sh under sandbox-exec; the assertion's own steps against helpers.sh variants; K33 and
  K70 are the matrix's literals, each occurring once): unmutated `caller index unchanged`; K70 alone `unchanged`; K33
  alone `unchanged`; K33+K70 `WRITTEN`.
- No row is lost: K70 is killed by fixture_repository_cases (v5 probe), and K33 now by the new load-time check. Only
  the recorded reason is wrong, in a log that is about to be frozen.
- Smallest fix: when the matrix result is recorded, say the nested-build assertion is a joint check of both guards
  that judges neither alone, and name K70's judge (fixture_repository_cases) as the scrub's.

### F4 (minor: pre-existing, outside the delta, but inside the contract sentence it rewrote) — the foreign-index fixture's `add` is unchecked; when it fails, the GIT_INDEX_FILE negative and the nested-build assertion both compare a missing file with itself and pass
- tests/test-verification.sh:481 (`fixture_git -C "$SANDBOX/foreign" add only-in-foreign.md`, no check), then :482
  (`cp "$SANDBOX/foreign/.git/index" "$foreign"`, unchecked) and :483 (`before="$(cksum < "$foreign")"`). The
  assertions that rely on it: :485-487 (an exported GIT_INDEX_FILE must not redirect the enumeration) and :513-516 (the
  nested build must not write the caller's index). Claim: templates/verification-contract.md:204-205, as edited by this
  delta, "a fixture that cannot build its repository or copy its kit content fails its test by name".
- Mechanism. git_host's `init` is checked, but a fresh repository has no index until the `add`, so a failed `add`
  leaves no `.git/index`: the copy fails, `before` is empty, and every later `cksum < "$foreign"` is empty too. The
  enumeration under a GIT_INDEX_FILE naming a missing file cannot list `only-in-foreign.md`, so assert_not_contains
  passes; the nested build's before/after checksums are both empty.
- Repro (copy; reuse_command_input_cases single-function under sandbox-exec, `noforeign/git` first on PATH, which exits
  128 only for an `add` naming `only-in-foreign.md`): runner rc=0, no build-failure record; the output shows only
  `git: add of the foreign entry refused (probe)`, `cp: .../foreign/.git/index: No such file or directory`, and
  `line 483`/`line 516: .../foreign-index: No such file or directory`. The two negatives passed with no foreign index.
- Reach: after the scrub nothing ambient fails this `add` alone, as for R6-1, so no current verdict is wrong.
- Smallest class-wide fix: a fixture write whose effect a negative relies on is checked like a build step:
  `... add only-in-foreign.md || fixture_build_failed foreign-index`, and assert the precondition directly
  (`GIT_INDEX_FILE="$foreign" git -C "$SANDBOX/foreign" ls-files` lists `only-in-foreign.md`). The other unchecked
  fixture writes (:274, :277, :281, :749, :758, :761, :831, :839) are each followed by an assertion that fails if the
  write did not take effect, as far as I read them (not probed); a row per check under a refusing judge would settle it.

## Held

- R6-4, the load-time check (tests/test-verification.sh:421-430). `git rev-parse --local-env-vars` prints all 15 names
  with every one of them planted as a path (so neither helpers.sh's loop nor the checker's own loop goes empty under
  the planted values; checked one name at a time and all at once). Against helpers.sh variants run with the check's
  exact command: unmutated `rc=0`; K33's literal `rc=1 still set after load: GIT_ALTERNATE_OBJECT_DIRECTORIES`; a
  partial clear that keeps only GIT_PREFIX `rc=1 still set after load: GIT_PREFIX`. So it is a genuine negative for
  each name, and bash 3.2's `${!n+set}` works. The v6 probe's K33 row is killed by it. Class check: I found no other
  row whose line a newer guard now shields (the rows judged by fixture_repository_cases assert their line directly;
  the new ceiling and copy-helper branches shield no mutated line; K52 now also drops the ceiling and is still killed).
  The one shielded assertion is the nested build, which no row judges alone (F3).
- R6-1 within its conditions. With an absolute, colon-free SANDBOX and a write below it, fixture_git cannot reach an
  enclosing repository (F1's control; the K75 probe row). The ceiling breaks no fixture: every `fixture_git -C` names a
  repository root inside the sandbox, no repository is the sandbox, and `init <dir>` does no discovery; a symlinked
  spelling of the ceiling is resolved by git (a ceiling given as a symlink to E/sb still stops the search from
  E/sb/proj), so macOS's /var -> /private/var TMPDIR is fine. dev12 ran 147/147 plainly and hostile with it.
- K75 judges what it claims: the enclosing probe stages into the scratch repository only when the ceiling line is
  gone (v6 probe), and the line K75 removes is exactly the delta's one added code line in fixture_git (after K75 the
  only differences from PRE_DIR's helpers.sh are comments and the two diagnostic wordings). Caveat: the probe's commit
  count assertion can never fail, since the later write is `add -A` alone; only the index assertion judges.
- R6-2's member list. Deriving it again from every function the suites run inside `$(...)` (19 helpers, plus every
  `run_rc` call, which also runs in a substitution) and keeping those that copy kit content or build a repository
  gives exactly the five the Decisions entry names. Every other copy site (doctor_fixture, dispatch_fixture,
  shipped_002_tally_case, gate_dispatch_grammar_cases, documented_example_cases, the wizard and AC-023 fixtures,
  make_host_kit's callers) runs in its test's own shell, where `t_fail` works.
- The four new copy-helper fixtures are genuine negatives in both directions: each fails against its exact PRE_DIR
  failure branch (K76-K79, v6 probe, and the four K7x literals leave no PRE_DIR line unrestored), each passes on the
  post-delta helper (dev12), a copy that succeeded would fail them (stage_kit/stage_umbrella through the status check,
  stage_example/floor_fixture through the missing record), and they run against an empty host, so nothing is written
  outside `$sub`. stage_example and floor_fixture still return 0 on a failed copy; the record fails the test anyway.
- The `record` kind cannot be satisfied by a colliding name today: in every R row the mutated record lacked the name
  (v6 probe), which it could not if another entry supplied it. Caveat: a mutated judge that leaves no record at all
  for another reason (the 1500 s watchdog, a harness failure) also counts as KILLED; the R mutants only delete a
  `|| fixture_build_failed` clause, so none can cause that here. R10's kill is real (its mutated judge passes, rc=0).
- @no-writes: the shim refuses only the subcommands the fixtures' writes use; in kit_copy_cases the only refusals
  were one `init` and one `add`, and the kernel (vf_git) calls none of those subcommands. The sandbox profile
  confines writes (my copy of it denies a `touch` outside rev7). On macOS the confined /usr/bin/git prints an
  `xcrun_db` cache warning on each call; no `record` verdict reads stderr.
- SHARD. A stub of the matrix's own row-selection lines (extracted verbatim) over its 108 `mutant` lines: the union of
  SHARD=0/3, 1/3, 2/3 and of 0/2, 1/2 is exactly the unsharded row list, with no label twice; every `mutant` call is
  at top level, the E04 block and the baselines are gated to shard 0, and SHARD=3/3 or 0/0 is refused.
- Mutant literals: my recomputed PRE_DIR -> copy diff equals t030o41-session4d.diff; K21/K41/K42/K44 and K52 now match
  the post-delta lines (the v6 dry run applies all 108 rows with `matrix failures=0`), and K75-K79 restore PRE_DIR
  exactly (above).
- Claims not reported as fixed: the contract paragraph still names the harness's bash startup environment and the
  kernel's own reads under a user's global excludes as open; nothing claims the analyzer grammar or the umbrella
  readers fixed. dev12's receipts read exit 0 (quick 31 PASS, 0 FAIL; full 147/147 plainly and hostile; live digest equal
  before and after each). Nit: the contract's edit leaves one unwrapped line (templates/verification-contract.md:206).
- Hermeticity. After every run the copy's `git status --porcelain --ignored` equalled its baseline (the 15 ignored
  runners). The live worktree's `git status --porcelain -uall -z` digest was `80f6f939...53af6d` before and after this
  review. Every probe that could fail a build ran under sandbox-exec confined to rev7.

## Not reached

- The whole suite and the whole matrix, deliberately, and no matrix row was run as the matrix runs it. Single
  functions only: kit_copy_cases (4 runs), fixture_repository_cases (2), reuse_command_input_cases (1), plus
  helper-level probes (rev7/exp/ceiling-routes.sh, nested.sh, r02split.sh, encl-check.sh, the R6-4 check's command).
- F1 end to end: I did not run a suite with a colon-bearing or relative TMPDIR (it breaks the PATH shims and relative
  `cd`s first), and did not look for an ambient input that fails `init` alone.
- The other unchecked fixture writes named in F4 (:274-281, :749-761, :831/:839) were read, not probed.
- Linux, a writable root, Bash 4/5, and git builds other than 2.50.1 (Apple); K74's timing; the @hostile judge
  (unchanged since review 6, which credited it).

REVIEW COMPLETE
