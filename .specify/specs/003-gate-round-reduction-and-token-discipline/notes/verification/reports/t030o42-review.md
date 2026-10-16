# Independent review — T030o42 (spec 003, O-016) — complete: NO BLOCKING FINDING (3 minor)

Reviewer: independent read-only reviewer, 2026-09-27.
Worktree read-only; experiments in a private copy under /private/tmp/rev-t030o42.

## Findings

### F1 — The edited contract paragraph says the harness reads no locale category; the harness's own awk reads LC_CTYPE and its result depends on it

- **Severity:** minor. The claim is false, but every reproduction below fails closed (rc 3 or an analyzer error); none is a wrong PASS.
- **Where:** `templates/verification-contract.md:352-353` (edited by this delta: "`LANG` and the locale categories are not read by the harness either (it pins `LC_ALL=C` where collation matters)"); `scripts/verification-lib.sh:1573-1575` (the kernel comment the STATUS Decisions entry of 2026-09-26, `STATUS.md:447`, says "speaks of the harness only and stays true"); the unpinned harness readers, for example `scripts/verification-lib.sh:1396-1409` (`vf_semantic_file`, plain `awk`), the configuration and bindings parsers, and the capture glob `scripts/verification-lib.sh:1811-1814` (`for dir in "$spec"/notes/captures/CAP-*`, where the last valid match wins).
- **Reproduction (private copy `/private/tmp/rev-t030o42/c`, TMPDIR inside it):**
  - `env LC_ALL=<L> bash -c '. scripts/verification-lib.sh; vf_snapshot $s $PWD $PWD out/inputs; vf_binding_snapshot $s out/bindings'`, where `s=.specify/specs/003-gate-round-reduction-and-token-discipline`:
    - under `C`, `C.UTF-8` and `en_US.ISO8859-1`: both calls rc=0, inputs `576ef5cd3a23eead…`, bindings `25c7fc1dcc31e604…`;
    - under `ja_JP.SJIS`: both calls rc=3. stderr: `awk: towc: multibyte conversion failure on: '… Define the versioned verification authoring contract'` / `input record number 75, file …/tasks.md`, then `error: vf_bindings could not parse plan.md`.
  - `bash scripts/sdd-analyze.sh <spec>` gives `rc=0 1 warning(s), 0 errors` under `LC_ALL=C` and under `LC_ALL=en_US.UTF-8`. Under `LC_ALL=ja_JP.SJIS` it gives `rc=1 12 error(s), 0 warning(s)`, and the first is `verification configuration parser: awk: towc: multibyte conversion failure …`.
  - The same awk (macOS `awk version 20200816`) fails on an invalid UTF-8 byte under the default UTF-8 locales:
    - `printf 'ab\xff cd\n' | env -u LC_ALL -u LC_CTYPE LANG=en_US.UTF-8 awk '{x=($0 ~ /cd/); print "ok"}'` prints `awk: towc: multibyte conversion failure on: '� cd'`;
    - `LANG=de_DE.UTF-8`, `LC_ALL=C.UTF-8` and `LC_CTYPE=en_US.UTF-8` do the same;
    - `LC_ALL=C` prints `ok`, and so does this session's ambient `LANG=C.UTF-8 LC_CTYPE=UTF-8`;
    - `tolower`/`toupper` fail with `illegal byte sequence`.
  - The same thing happens in the macOS default locale with one byte. Insert `\xff` into the T030o42 subject line of the copy's `tasks.md`, then run `env -u LC_CTYPE LC_ALL=<L> bash scripts/sdd-analyze.sh <spec>`. Under `C` it gives `rc=0 1 warning(s), 0 errors`, `75 task(s) parsed`. Under `en_US.UTF-8` it gives `rc=1 12 error(s), 0 warning(s)` and parses no tasks. The file was restored with `cp -p` and verified with `git diff --quiet`; the status is clean. The pinned suites can never show this behaviour again.
  - Bash glob order, which the harness's capture loop follows, depends on `LC_COLLATE`. With files `CAP-10-a CAP-9-b CAP-1-Z CAP-1-a B a _x -y`, `echo *` gives `-y B CAP-1-Z CAP-1-a CAP-10-a CAP-9-b _x a` under `C` and `C.UTF-8`, and `_x -y a B CAP-1-a CAP-1-Z CAP-10-a CAP-9-b` under `en_US.UTF-8` and `de_DE.UTF-8`.
- **Why it matters here:**
  - The delta re-worded this sentence to name the harness explicitly, and the Decisions entry certifies the kernel comment as true. The harness in fact runs under the caller's locale and reads `LC_CTYPE` (and `LC_COLLATE`, through globbing).
  - With the suites now pinned, no suite run can observe this any more. Before the delta, a suite run from an SJIS shell, or on an invalid UTF-8 byte in an en_US.UTF-8 shell, exercised the unpinned product parsers. The pin removes that exposure exactly as it removes 002's classifier half (the product defect stays; only its detection goes).
- **Smallest class-wide fix:** either pin `LC_ALL=C` once at the kernel's entry (every harness grammar is ASCII, so this changes no identity byte; the identity is already cmp-equal under C, C.UTF-8 and ISO8859-1), or correct both sentences to say that the harness runs under the caller's locale and pins `LC_ALL=C` only at its collation sites. In the second case, record the SJIS / invalid-UTF-8 failure as the known product behaviour, beside 002's classifier.

### F2 — The fixture takes its members from `reuse_checks` only, but the identity also carries gate-check, checkpoint and task-Verify verdicts across shells

- **Severity:** minor. It is a latent coverage gap: every such command the kit ships today is `tests/run.sh`, `tests/shellcheck.sh` or a chain of `bash tests/test-*.sh`, and all of them are pinned. No wrong result was reproduced on the shipped configuration.
- **Where:** `tests/test-verification.sh:553-572` (the probe set is `$cfg/reuse.nul` alone). The verdicts the identity carries across shells without re-execution and without any `local` policy check:
  - `vf_floor_validate` (`scripts/verification-lib.sh:2247-2268`) judges every sealed floor command `current` when `spec-gate.sh round` reserves (`:2601`) and completes (`:2652`);
  - `vf_evidence_current` (`:1820-1836`, predicate `current`, called by `spec-evidence.sh:53`) does the same for every completed task's Verify capture.
  - So the mechanism O-016 names (the identity hashes no undeclared name) applies to `gate_checks`, `checkpoints` and every automated task Verify, not only to `reuse_checks`. The Acceptance says "derive the member from what the programs a reuse-checked command runs consult". The derivation stops at the opt-in list, while the floor seal is the other path by which one shell's verdict decides another's.
- **Reproduction (copy c, restored with `git checkout` and checked with `cmp`, status clean after each run):**
  - G1: add `- 'bash scripts/sdd-analyze.sh .specify/specs/003-gate-round-reduction-and-token-discipline'` under `gate_checks:`. `reuse_command_locale_cases` gives rc=0 with no diagnostic. That command's verdict is locale-dependent (F1: rc=0 under C and en_US.UTF-8, rc=1 under ja_JP.SJIS). A floor sealed in one shell would therefore pass `round` in the other with no by-name failure anywhere.
  - G2: add `- 'bash tests/test-usage-limits.sh | tail -n 1'` under `checkpoints: Backend:`. The fixture gives rc=0 with no diagnostic, although `tail` runs after the suite's pin has gone out of scope.
  - Nothing checks that a `tests/test-*.sh` suite, the unit of every Verify in the three specs' `tasks.md` (enumerated: all `Reuse: local` Verify lines are chains of `bash tests/test-*.sh`, `bash tests/run.sh` and `bash tests/shellcheck.sh`), sources `tests/helpers.sh` before it runs any program. Every suite runs `dirname` first today. That is inert, but "export `LC_ALL=C` before they run anything else" (`templates/verification-contract.md:193-195`) is literally false for suites, and no guard would catch a locale-reading line placed above the `. helpers.sh` line.
- **Smallest class-wide fix:**
  - Take the probe set from every command `vf_config` emits (`commands.nul`, which covers gate_checks and checkpoints, plus `reuse.nul`). Fail by name on any command that is not a probed wrapper.
  - Add one static check that every `tests/test-*.sh` sources `helpers.sh` before its first non-builtin command, and that every automated Verify in the kit's specs is a `&&`-chain of probed commands or `bash tests/test-*.sh`.
  - Alternatively, state in the contract that a gate or checkpoint command is held to the same rule as a reuse-checked one, because a sealed floor is honoured across shells.

### F3 — The census receipt misreads `date(1)`, which does have an ENVIRONMENT section (TZ)

- **Severity:** minor (a receipt inaccuracy). It does not change the rule, because the Decisions entry treats `TZ` separately and measured it.
- **Where:** `notes/verification/reports/o016-census-env.txt` (the `date` row: `date      <no ENVIRONMENT section>`).
- **Reproduction:** `man date | col -b | awk '/^ENVIRONMENT/{f=1} f && /^EXIT STATUS/{exit} f'` on this host prints `ENVIRONMENT` / `The following environment variable affects the execution of date:` / `TZ      The timezone to use when displaying dates. …`. The census row for `date`, the one program whose locale reading caused O-016, therefore records the opposite of its manual page. The header's fallback sentence ("programs whose page has no ENVIRONMENT section still call setlocale()") then covers `date` by argument instead of by reading. The census also looked only for an `ENVIRONMENT` heading. So `sh` is recorded as reading nothing, because macOS `man sh` is a stub page (its only headings are NAME, SYNOPSIS, DESCRIPTION, FILES and SEE ALSO, and it names no variable). The `sh` it runs is bash in POSIX mode, which reads `SHELLOPTS`, the locale, and `ENV` when it is interactive. Those are covered by the pin or by the recorded harness-level item, so the conclusion stands.
- **Smallest fix:** correct the `date` row to `TZ`. State that the census is headings-only, and therefore a lower bound in the same sense the Decisions entry already gives the PATH-shim program list.


## Held

Attacked, and it held. All runs were in private copies under `/private/tmp/rev-t030o42` with TMPDIR inside it; each copy's `git status --porcelain --ignored` was empty before and after every run.

1. **Pin placement (attack 1).**
   - `tests/run.sh:21-24` and `tests/shellcheck.sh:19-24` export `LC_ALL=C` immediately after `unset CDPATH BASH_ENV ENV`, and only builtins run before that point. The same holds for `tests/helpers.sh:18-27`; each suite runs only `dirname` before sourcing it, and `dirname` is byte-oriented (see F2 for the wording).
   - Bash re-reads the locale on the `LC_ALL` assignment. A probe under a missing locale (`LANG=xx_XX.UTF-8`, and also `LC_ALL`/`LC_CTYPE`) is silent under `/bin/bash` 3.2.
   - No escape was found:
     - nothing under `scripts/` or `tests/` assigns `LANG`/`LC_*`, except `LC_ALL=C` command prefixes and the deliberate identity loop at `tests/test-verification.sh:313`;
     - there is no `env -i`, login or interactive shell, `su`, `sudo` or `ssh`, and the `launchctl` calls are stubbed in tests;
     - `script(1)` is always given a command, so it passes the environment on and never picks `$SHELL`;
     - `fixture_git`'s `env -u` list leaves `LC_ALL` alone;
     - the one absolute-path program call, `/bin/date` in the `tests/test-usage-limits.sh:532` clock stub, inherits the pin;
     - `git` here is Apple Git-155 with no translations, and no product script parses git's message text.
   - The harness's `vf_capture` records `(cd "$cwd" && "$@")`'s own exit (`scripts/verification-lib.sh:1719`), so no program outside the pinned command sits on the verdict path.
2. **The pin does not blind ShellCheck.** ShellCheck 0.11.0 on a file carrying UTF-8 bytes and one carrying Latin-1 bytes gives byte-identical output (844 bytes: SC1010, SC2045 and SC2164) at rc=1 under `LC_ALL=C`, `C.UTF-8` and `en_US.UTF-8`.
3. **The fixture works in both directions (attack 3).**
   - Unmutated, `reuse_command_locale_cases` gives rc=0 with empty output under the default `/bin/bash` 3.2, and again with `/bin/bash` shimmed first on PATH as the CI `tests-bash32` job does.
   - Two mutants the matrix lacks are both killed with the exact diagnostic, and both restores are `cmp`-identical:
     - `tests/run.sh` with `export` dropped (`LC_ALL=C` unexported): `AC-020: bash tests/run.sh ran a suite under the caller's locale (O-016) missing substring: locale-probe-pinned`;
     - `tests/shellcheck.sh` with `export` dropped: `AC-020: bash tests/shellcheck.sh ran ShellCheck under the caller's locale (O-016) missing substring: shellcheck saw LC_ALL=C`.
   - A compound `reuse_checks` entry (`bash tests/run.sh && bash tests/shellcheck.sh`) fails by name: `AC-020: reuse-checked command has no locale probe: bash tests/run.sh && bash tests/shellcheck.sh`.
   - The canary and each behaviour run use the identical `env ${nolc[@]} LANG=$l` composition, so a live canary means a hostile run.
   - A renamed case fails with `FAIL <name>`, not vacuously.
   - The nested `SANDBOX` contains `test_`, which `t_run_all` avoids. It is inert for these three cases: their path heuristic, `spec-ac-coverage.sh`'s `-ipath '*test*'`, runs relative to `cd "$root"`, and `sdd-analyze.sh` does not call it.
   - Linux judged by the mechanism half alone is acceptable, because CI also runs `macos-latest` and `tests-bash32`, where the precondition makes the behaviour half mandatory.
4. **The matrix (attack 4).**
   - Every literal matches the post-delta lines (the DRY receipt, and re-read here). Each kill fires for its stated reason:
     - K1/K2: the export probe;
     - K3/K4: the probes;
     - K5: by name;
     - K6/K6b: `tests/run.sh` still pins, so only the behaviour half can fire;
     - K7/K8: the macOS precondition. K8's dependence on it is correct on macOS, and K8 would survive silently on Linux, which the macOS jobs cover.
   - E1 is argued correctly. Before its moved pin, `tests/run.sh` runs `dirname`, `pwd`, `mktemp`, the sourced library (top-level assignments only) and `vf_source_paths`. That function is `git rev-parse` plus `git ls-files -z` (`scripts/verification-lib.sh:1451-1457`): git uses its own ctype, and its output is NUL-framed paths. The `case` patterns have no classes or ranges.
5. **What the check reads versus what the snapshot hashes.**
   - The pin makes the check run under C while the harness runs under the caller's locale. The enumeration is git alone, and `vf_semantic_file`'s patterns are ASCII.
   - `vf_snapshot` and `vf_binding_snapshot` are byte-identical under `C`, `C.UTF-8` and `en_US.ISO8859-1` (inputs `576ef5cd…`, bindings `25c7fc1d…`). macOS awk 20200816 counts bytes for `length` even under UTF-8.
   - The locale can therefore only make the harness fail closed (F1), never hash other bytes than the pinned check reads.
6. **The contract still passes the superseded-environment scan (attack 5).** `tests/test-gate-contracts.sh::test_instruction_contracts` in the copy: rc=0 (1m43s).
7. **TZ.**
   - Every local-date site (`date +%Y-%m-%d` in `spec-task.sh`, `spec-status.sh`, `spec-pr.sh`, `spec-ci.sh`, `new-spec.sh`, `verification-lib.sh:1966`) matches `tests/helpers.sh`'s `TODAY`, and the classifier suite pins `TZ=UTC`.
   - The invoker's Kiritimati run (19:44-20:58Z) was a calendar day ahead of UTC, so a UTC-versus-local date mismatch would have shown. I agree it is measured, not proven.
8. **Option variables versus default variation (attack 2).**
   - None of `UNAME_SYSNAME`, `GREP_OPTIONS`, `TAR_*_OPTIONS`, `POSIXLY_CORRECT`, `GNUSORT_*` or `PERL5OPT` is set by any default login. The split is drawn correctly.
   - `TERM` and `SHELL` do vary by default, but nothing the suite runs reads them for a judged output (no `tput`, no `ls`, and `script` is always given a command).
   - `COLUMNS` reaches only `sed` among the census programs, where it sets the wrap width of the `l` command, and no sed script in `scripts/` or `tests/` uses `l` (grep); no census program formats columns (no `ls`, `who` or `column`).
   - `TMPDIR` also varies by default: see the post-delta run under a symlinked TMPDIR with a trailing slash, below.
9. **Receipts.**
   - The dev run `t030o42-dev1-full` finished at rc=0: 147/147 plain, under `LANG=de_DE.UTF-8` and under `LC_ALL=en_GB.UTF-8`, with the copies and the live status unchanged.
   - The mutation receipts match their script.
   - `t030o42-analyze` has 0 errors, and the waiver receipt says `authorized: opponent round 12`.
   - The delta equals `PRE_DIR` plus exactly the five source files, `tasks.md` and `STATUS.md` (`diff -rq`, excluding `notes/verification/reports`).
   - `scripts/verification-lib.sh` is byte-identical to `PRE_DIR`'s, so the identity's records are unchanged, as claimed.
10. **The pin hides nothing beyond 002's classifier among the shipped tests, under de_DE (attack 1, last question).** The pre-delta tree, copied from `PRE_DIR` into `/private/tmp/rev-t030o42/pre` and made its own repository, was run as `bash tests/run.sh` with every `LC_*` removed and `LANG=de_DE.UTF-8`. De_DE brings a UTF-8 ctype, the case-folding collation that reorders bash globs, and a German `LC_TIME` and `LC_NUMERIC`.
    - Result: rc=1 at 145/147 (00:29:42Z-00:50:08Z), with the copy's status unchanged.
    - The only failures are the two recorded cases, `test_AC_001_classifies_every_planned_provider_limit_fixture` and `test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry`. `test_T013o1_…` passes under de_DE, as `o016-repro.log` records.
    - So among the tests the kit ships, the verdict change the pin makes under de_DE is exactly 002's recorded classifier. F1 names what the pin hides that no shipped test exercises.
11. **TMPDIR, the other default-varying name (attack 2).** The post-delta tree was run as `bash tests/run.sh` with every `LC_*` removed, `LANG=C.UTF-8`, and `TMPDIR=/tmp/rev-t030o42/tmp-tv/`. That value has a symlinked first component (`/tmp -> private/tmp`) and a trailing slash, the shape of macOS's default `/var/folders/…/T/`, whereas the invoker's runs used a real path with no slash.
    - Result: rc=0 at 147/147 (00:37:41Z-00:56:13Z), with the copy's status unchanged and the TMPDIR left empty.
12. **The live worktree is untouched.** Its `git status --porcelain --ignored -uall` outside `$S/notes/verification/`, read with `GIT_OPTIONAL_LOCKS=0` at the end of this review, has digest `66ef051e755c…`, the invoker's own baseline in `t030o42-dev1-*.log`.

## Not reached

These were not reached, and so are not cleared:

- **Linux and GNU tools, and bash 4/5.** This host has only `/bin/bash` 3.2 and Homebrew `gawk`. The claim that the helpers probe's exact `assert_eq 'C LC_ALL=C'` also holds on ubuntu rests on reading bash's `locale.c`: it warns only for an invalid `LC_*` value, not for `LANG`. I did not observe it on Linux.
- **A floor sealed end to end in one locale and a `round` reservation made in another.** F2 rests on the code path (`vf_floor_validate` and `vf_evidence_current` use the `current` predicate, which checks no policy) plus the fixture mutants. It is not a sealed-floor reproduction.
- **A harness verdict that flips in the unsafe direction under a locale.** Every harness locale effect I found fails closed (F1). I did not search every unpinned awk in the kernel and analyzer for a partial-output path whose exit status is masked by a pipeline.
- **Legacy multibyte locales other than ja_JP.SJIS** (EUC-JP, GB18030, Big5), and a Turkish locale's `I`/`i` folding under the kernel's `nocasematch` on a case-folding filesystem.
- **The full census at manual-page depth beyond `date` and `sh`**, and any program reached by absolute path beyond `/bin/date`.
- **The mutation matrix re-run in full.** I re-ran only the extra rows named above and read the receipts for the rest.

## Verdict

NO BLOCKING FINDING. There are three minor findings: F1 (a claim versus the code, in an edited contract sentence), F2 (fixture members; a latent gap) and F3 (a receipt inaccuracy). The pin does what O-016 asked, both halves of the fixture are genuine negatives on macOS, and the matrix rows fire for the reasons stated.

REVIEW COMPLETE
