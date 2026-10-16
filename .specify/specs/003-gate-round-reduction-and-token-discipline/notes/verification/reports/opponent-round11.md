## Round 11

**Round:** 11
**Timestamp:** 2026-09-26T18:25:56Z
**Source:** 1fba08ed13e83cbca56ef731047f39c3668dfa47c4ff81873de63ee2eea3b0b0
**Floor:** FLOOR-QeBcq3
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 0

### What I attacked

I checked identity and scope myself before using the brief. `notes/verification/rounds/opponent/ROUND-11/meta.nul` records round 11, FLOOR-QeBcq3, source `1fba08ed…` and reservation time 2026-09-26T17:27:11Z, and `r11-reserve.log` says the same. All execution ran in four copies under `/private/tmp/opp11`, plus one scratch enclosing repository there, with `TMPDIR` inside that directory. Each copy is the worktree's own `git ls-files -z --cached --others --exclude-standard` enumeration, read with `GIT_OPTIONAL_LOCKS=0`, plus its own `.git` holding the live index and the main repository's objects as a read-only alternate. In the first copy, `vf_snapshot` produces 370 records. The `version`, `harness` and `document` records carry the copy's absolute paths. The other 357 records are byte-equal to FLOOR-QeBcq3's `inputs.nul`, and the `harness` and `document` digests are equal as well. So my copies hold the reviewed source. In a copy:
- `spec-gate.sh waiver … opponent 11` prints `authorized: opponent round 11` at exit 0;
- round 12 exits 4 and lists nine refused candidates;
- `spec-gate.sh tally` reproduces opponent=10, reality-check=1, blocking=24, minor=10, observations=49, distinct IDs=15, reopened=25 and severity-downgrades=5.

The repair itself (T030o41, O-015 plus the anchor-layout gap):
- **Round 10's exact scenario.** I ran `spec-task.sh done <spec> T030 --evidence "hosted CI green; the macOS job includes PATH and TMPDIR shims for Bash 3.2 (2026-09-24)"`. It printed `T030 -> [x] with evidence`. The manifest stayed `cmp`-identical at `1d395fb5…`, and the verbatim extracted `superseded_environment_scan` over the whole copy printed nothing, at exit 0.
- **The scan's content read.** Replacing the scan's `vf_path_content` call with a raw `cp` fails `superseded_environment_cases` with `AC-020: a claim on a line the identity drops was scanned, so a reusable PASS of this suite could fail (O-015)`.
- **The layout clause.** Deleting the `vf_bookkeeping_anchor` clause fails `outside_layout_anchor_cases` with both of its assertions.
- Both mutants were restored and checked with `cmp`.
- **The full suite.** `bash tests/run.sh` passes 15 suites, 147/147, at exit 0. The copy's `git status --porcelain --ignored -uall` digest was the same before and after.

I then derived the reader class again, this time from what a reuse-checked command consults rather than from the kit's own `${NAME}` reads. T030o41's member (5) was measured only as those reads (STATUS.md:409). The contract that T030o41 rewrote now states that such a check "reads no environment variable the project has not declared" (`templates/verification-contract.md:180-181`). So I varied undeclared environment one input at a time and ran the full suite, or the affected suite, in a copy each time:
- **Locale.** The identity is `cmp`-identical under `LC_ALL=en_GB.UTF-8` and under `LANG=de_DE.UTF-8`. The suite fails under both; that is Finding O-016.
- **Timezone.** `test-usage-limits.sh` passes 27/27 under `TZ=Pacific/Kiritimati` and under `TZ=Etc/GMT+12`.
- **ShellCheck.** `tests/shellcheck.sh` exits 0 with empty output under `LC_ALL=C`, `C.UTF-8`, `en_GB.UTF-8` and `POSIX`, and with every locale name unset. Its `-x` source-following reaches only the one tracked `# shellcheck source=scripts/lib.sh`.
- **`TMPDIR` inside an enclosing Git repository.** The full suite passes 147/147 at exit 0. The enclosing repository keeps one index entry and one commit, and the copy is unchanged.
- **Homebrew's `gawk` first on `PATH`.** The identity is `cmp`-identical, and the full suite passes 147/147 at exit 0.

Known open, confirmed rather than rediscovered:
- the O-004 omission extent;
- the opponent-only totals, verdict and downgrade guards at `scripts/verification-lib.sh:1101-1103`;
- README's comment-only `Verification-Return` at :434, and the completion marker carried only by the two personas;
- 001's exit 3;
- review 7's F1 to F4 and K74. I checked by grep that every `fixture_git -C` still names a repository below `$SANDBOX`, so F1 stays latent, as recorded;
- the harness-level bash startup environment, the kernel's ambient fixture reads, the analyzer field grammar with AC-023's narrowed reading, and the umbrella-only readers.

Not reached, and therefore not cleared:
- a whole floor sealed in a copy under a second locale. I ran the exact predicate that decides its cache hit instead;
- Linux, GNU tools, and Bash 4 or 5;
- the matrix rows beyond the two I re-ran;
- umbrella and multi-repo roots, acceptance crash windows, a real reality-check carry, the `r`-suffix branch, and AC-014/017/018 prose.

Nothing in the worktree was created, modified, moved or removed except this report.

### Finding O-016
- **Class:** verification-input-identity
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** A PASS captured in one shell is reused by a floor sealed in another shell whose locale differs, although a fresh run in that shell fails:
  1. The invoker captures `bash tests/run.sh`, or T030o41's Verify `bash tests/run.sh && bash tests/shellcheck.sh`, from a shell with `LANG=C.UTF-8`. That is what this review's own shell exports.
  2. A floor for the same source is later sealed from a shell whose locale's `LC_TIME` has no plain `AM`/`PM`. Examples are a UK-region macOS Terminal (`LANG=en_GB.UTF-8`, where `%p` prints `p.m.`) or a German one (`LANG=de_DE.UTF-8`, where `%p` prints nothing).
  3. Both reuse-checked commands are opted in (`.specify/stack.yml:14-16`), and `verification_environment: []` declares no locale name (`.specify/stack.yml:22`). The environment records hash declared names only (`scripts/verification-lib.sh:1586-1594`), so the manifest is byte-identical in both shells. Currency and reuse are decided by the manifest digest (`:1774`, and the floor's reuse at `:2147`).
  4. The floor therefore takes a cache hit on the C.UTF-8 PASS. A fresh run in its own shell fails, because the suite reads the locale through `tr` and `date`, both in the shipped classifier (`scripts/usage-limit.sh:29` `tr '[:lower:]' '[:upper:]'` and `:32` `date -j -f '… %I:%M:%S%p'`) and in the test's own clock fixture (`tests/test-usage-limits.sh:392-395` `date '+%I:%M %p'`).
  5. The suite pins `TZ=UTC` for the classifier (`tests/test-usage-limits.sh:14`) but no locale name. `tests/helpers.sh:42-45` clears only `SDD_*`, `XDG_STATE_HOME` and git's repository-local names.
- **Where:** scripts/usage-limit.sh:29, scripts/usage-limit.sh:32, tests/test-usage-limits.sh:14, tests/test-usage-limits.sh:23, tests/test-usage-limits.sh:392, tests/helpers.sh:43, tests/helpers.sh:45, .specify/stack.yml:14, .specify/stack.yml:22, scripts/verification-lib.sh:1591, scripts/verification-lib.sh:1774, scripts/verification-lib.sh:2147, templates/verification-contract.md:180, templates/verification-contract.md:345
- **Reproduced:** End to end, in a copy whose manifest equals FLOOR-QeBcq3's:
  - **Capture.** Under the ambient `LANG=C.UTF-8`, `spec-run.sh <spec> T030o41 --from-task --no-tick --summary` produced CAP-499-SAEWo5: `/bin/bash -o pipefail -c bash tests/run.sh && bash tests/shellcheck.sh`, exit 0, input `1d395fb5…` both before and after.
  - **Reuse under en_GB.** Then, with `LC_ALL=en_GB.UTF-8` (`locale` reports `LC_TIME="en_GB.UTF-8"`), `vf_snapshot` printed the same `1d395fb5…`. `vf_capture_check <spec> CAP-499-SAEWo5 <manifest> reuse` returned rc=0. `vf_binding_snapshot` is `cmp`-equal to the capture's `bindings.nul`, which is the floor's match condition at :2143. `vf_task_current <spec> T030o41 <catalog> <manifest> reuse` printed `CAP-499-SAEWo5` at rc=0.
  - **Fresh run under en_GB.** In a second copy, the same `bash tests/run.sh` under `LC_ALL=en_GB.UTF-8` exits 1 at 144/147. The failures are `test_AC_001_classifies_every_planned_provider_limit_fixture`, `test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry` and `test_T013o1_clock_only_horizons_follow_configured_park_policy`. The first reports `expected: limit<TAB>short<TAB>1704123900<TAB>claude-session-clock` against `actual:   limit<TAB>short<TAB><TAB>claude-session-clock`. The third reports `T013o1: both concrete clock resets create resume units`, expected 2, actual 0.
  - **Ambient baseline.** In a third copy, the ambient run passes 147/147 at exit 0.
  - **de_DE.** Under `LANG=de_DE.UTF-8` (with `LC_ALL` and `LC_CTYPE` unset), `bash tests/test-usage-limits.sh` exits 1 at 25/27. Here `resets 3:45pm` classifies as `limit<TAB>short<TAB>1704080700`, exactly 43200 s before the expected `1704123900`.
  - **Controls.** `LC_ALL=C` passes 27/27. `date -v+1H '+%I:%M %p'` prints `PM` under C, C.UTF-8 and en_US.UTF-8, `p.m.` under en_GB.UTF-8, and nothing under de_DE.UTF-8 and fr_FR.UTF-8.
  - Every copy's status digest was unchanged by each suite run.
- **Root cause:** implementation-error
- **Blocks:** REQ-009, AC-020
- **Wrong behavior:** REQ-009 makes "relevant toolchain and environment identity" an input. AC-020 says a changed relevant environment identity cannot reuse the old success. Plan §3.2 item 4 keeps the identity stable across shells by hashing only declared names, and puts the cost on the project: "Projects must declare additional variables their checks depend on." The kit's own project declares none, yet the verdict of its own reuse-checked suite is a function of `LANG`/`LC_ALL`/`LC_TIME`. So a floor or reservation run from a UK- or German-region shell certifies a PASS that its own tree does not produce there.
  - This is the cross-shell variation the 2026-09-13 decision measured and designed the identity to tolerate: locale names differ by default between Terminal, SSH and CI. The kit's reuse opt-in inherits that tolerance without the declaration or pin that makes it sound.
  - T030o41 took on "the environment and configuration the programs consult", and its contract sentence (`templates/verification-contract.md:180-181`) says a reuse-checked check reads no undeclared variable. Its measurement of that member counted only `${NAME}` reads in `scripts/*.sh` (STATUS.md:409), so it missed the environment the tools those scripts and suites run consult.
  - The contract's justification that "`LANG` and the locale categories are not read either" (:345-346) is true of the harness it describes, but not of the kit's own checks.
  - This is not the recorded harness-startup item. That item is bash reading `BASH_ENV`, `ENV`, `SHELLOPTS`, `BASHOPTS` and exported functions. This member is `date` reading `LC_TIME` inside the suite body, from a default login locale, with no hostile setup. Of the two options recorded for that item, hashing bash's startup inputs would not close this one, and pinning a closed harness environment would.
  - Under C.UTF-8 and en_US.UTF-8, `%p` prints `PM` (measured here), so a fresh CI run under either locale would pass too.
- **Class-wide fix:** Derive member (5) from what the invoked programs consult, not from the kit's own variable reads: `date` reads `LC_TIME` and `TZ`, and `tr`, `sort`, `awk` and `grep` read `LC_CTYPE` and `LC_COLLATE`. Then choose, per name, to pin or to declare.
  - **Pin (recommended).** `tests/helpers.sh` exports `LC_ALL=C` beside its existing clearing, and `tests/run.sh` does the same before it enumerates. A name whose value the verdict then cannot see needs no declaration, and the digest stays stable across shells, which the 2026-09-13 decision required.
  - **Fixture.** Add one in both directions. The classifier cases and `test_T013o1_…` pass under `LANG=en_GB.UTF-8` and `LANG=de_DE.UTF-8`, and removing the pin fails that fixture.
  - **Contract.** Correct the contract sentence so that it names what the kit's own suites pin.
  - **Rejected alternative.** Declaring `LANG`, `LC_ALL` and `LC_TIME` under `verification_environment` is the other route. It is correct, but it invalidates every floor across shells, which is what the 2026-09-13 decision rejected.
  - **Out of this spec.** The shipped classifier's own locale dependence (next section) is a separate defect in 002's product. Pinning the suite removes only the reuse half.

### Finding O-015
- **Class:** verification-input-identity
- **Status:** resolved
- **Prior:** O-015
- **Severity:** wrong-result
- **Scenario:** Round 10's case: the T030 tick with a guard-flagged sentence on its Evidence line, and the same sentence on a `status:`/`updated:` line, a body line, a git-quoted name and a link target. I also tried a tree git cannot enumerate. The derived siblings are the suite list, the ShellCheck file list and its rc files, live-kit globs, whole-kit and directory copies, 002's records read in place, and the AC-023 loop. I also attacked the in-repository spec outside `.specify/specs/<name>`.
- **Where:** tests/test-gate-contracts.sh:63, tests/test-gate-contracts.sh:86, scripts/verification-lib.sh:1371, scripts/verification-lib.sh:1417, scripts/verification-lib.sh:1451, tests/helpers.sh:405, tests/run.sh:33, tests/shellcheck.sh:41
- **Reproduced:** In copies whose manifest equals FLOOR-QeBcq3's:
  - The exact round-10 tick in a copy leaves the manifest `cmp`-identical and the scan silent at exit 0.
  - The raw-bytes mutant of the scan's content read fails `superseded_environment_cases` with the O-015 assertion.
  - Deleting the layout clause fails `outside_layout_anchor_cases` with `AC-020: an in-repository spec outside .specify/specs/<name> was given an anchor` and `… an empty anchor excludes nothing`.
  - Both mutants were restored and checked with `cmp`.
  - The full suite passes 147/147, both plainly and with `TMPDIR` inside an enclosing repository, and ShellCheck passes under four locales.
- **Root cause:** plan-gap
- **Blocks:** REQ-009, AC-020
- **Wrong behavior:** Nothing remains wrong for round 10's subject. Every repository byte a reuse-checked command in this kit reads now comes through `vf_source_paths` and `vf_path_content`, as the identity hashes it, and a tree that cannot be enumerated fails by name. The class stays open through the environment, as recorded in O-016.
- **Class-wide fix:** Closed for this member. Keep the fixtures.

### Held up / follow-up tasks

These surfaces held:
- O-015's subject and the round-10 isolation gap, as recorded above.
- The copy's manifest equals FLOOR-QeBcq3's, and the waiver, refusal and tally reproduce.
- `TZ` does not reach any verdict I ran.
- `tests/shellcheck.sh` is locale-proof, and `-x` follows only a tracked file.
- R6-1's ceiling holds for an absolute, colon-free `TMPDIR` inside an enclosing repository: the whole suite ran there and wrote nothing to it.
- An undeclared tool swapped through `PATH`, Homebrew's `gawk` as `awk`, left the identity and all 147 tests unchanged.

Proposed follow-ups:
- **T030o42, for O-016.** Pin `LC_ALL=C` at the start of the kit's own reuse-checked commands (`tests/helpers.sh` and `tests/run.sh`), re-derive the environment member from what the invoked programs consult, correct `templates/verification-contract.md:180-181` and :345-346, and add the two-locale fixture with its mutant.
- **Outside spec 003, recorded for the user.** Shipped 002's `scripts/usage-limit.sh` parses provider clock text under the ambient locale. Under `LANG=de_DE.UTF-8`, `resets 3:45pm` yields a reset 12 hours early (`1704080700` against `1704123900`), so a parked dispatch resumes while still limited. Under `LANG=en_GB.UTF-8` it yields no reset at all. The smallest fix is to run its `tr` and `date -j -f` (and `date -d` on Linux) under `LC_ALL=C`, because the provider's text is English whatever the user's locale. It needs its own follow-up and user decision.
<!-- gate-round-end: opponent:11 -->
