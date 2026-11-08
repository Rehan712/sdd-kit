# RC3 invalidation fixture candidate

Patch: `invalidation.patch` (standard a/tests/test-gate-contracts.sh -> b/tests/test-gate-contracts.sh).
Candidate: `test-gate-contracts.sh`.
Only eventual source target: `tests/test-gate-contracts.sh`; `tests/test-verification.sh` requires no change.

## Baseline and checks actually performed

- Source SHA256: `97beb8090a7485d945a3564e3eed8f06b12d9878b4a0bda4a56063117d6595a3`.
- Candidate SHA256: `7bc13dde14004bf4ba967c0f64ec120b19bdde641643a6a7436d154c222f893c`.
- Patch SHA256: `3fcf58dc0bbb39876db86eff06d2bb887fd2384031ba9d8f2ebabafd95881903`.
- `/bin/bash --version`: GNU Bash 3.2.57(1)-release (arm64-apple-darwin25).
- `/bin/bash -n <owned candidate>`: exit 0, repeated on final candidate.
- `GIT_OPTIONAL_LOCKS=0 git apply --check <owned invalidation.patch>`: exit 0, repeated on final patch.
- Source SHA256 still matched the recorded baseline at final applicability check.
- No live source/index/ref/task/STATUS/plan/config/gate writes, patch application, fixtures, captures, gates, suites, commits, pushes or delegation performed.

## Actual changed family and intended execution after parent applies

Declared family: `reports`.
Locator: `tests/test-gate-contracts.sh::test_reports_and_tally`.
Existing caller: `test_reports_and_tally` invokes `matrix_runtime_cases` (all new logic is inside that existing fixture).
File command: `GIT_OPTIONAL_LOCKS=0 /bin/bash tests/test-gate-contracts.sh`.
Run from `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`.

For just the declared family with the existing fresh-sandbox runner:

```bash
GIT_OPTIONAL_LOCKS=0 /bin/bash <<'BASH'
. tests/helpers.sh
. <(sed '/^\. .*helpers.sh/d; /^t_run_all$/d' tests/test-gate-contracts.sh)
for fn in $(declare -F | awk '{print $3}' | grep '^test_'); do
  [[ "$fn" == test_reports_and_tally ]] || unset -f "$fn"
done
t_run_all
BASH
```

These commands are supplied for parent execution after closure/application; they have NOT been run here.

## Assertions added

The original matrix fixture still captures one successful `bash tests/check.sh` through `spec-run.sh`, saves a real round-1 PASS and carries it in round 2. Its check now sources `src/parser.sh`, which imports and calls `lib/shared.sh`, consumes `tests/fixtures/value`, and reads the expected value from `config.yml` and the required helper version from `lockfile`. No new shared helper abstraction or test family is introduced.

Six independent mutations change the implementation function, the transitive helper function, consumed data, locked version, consumed configuration, and actual referenced AC-001 text in fixture `spec.md`. The first five also run the actual check directly and require failure, demonstrating consumption without publishing a later failed capture. The criterion case asserts that the real AC line changed.

Each mutation snapshots current inputs, requires both `current` and `reuse` to refuse the original successful capture specifically for changed inputs, refuses both the saved round-1 PASS and round-2 carry, and compares old output.log byte-for-byte using cmp. Each mutation is restored before the next; both capture predicates and both matrix rounds must pass again. Initial unchanged controls pass as well. Existing missing row, unknown impact, verdict, criterion-digest spelling, log corruption and source-mutation controls remain unchanged.

## Parent registry follow-up after closure

The current `plan.md` reports registry row (around line 553) lists AC-010, AC-012, AC-013, AC-017. Add AC-020 and describe saved-success/carry invalidation for implementation/transitive-helper/data/lock/config/actual criterion edits at the existing locator. The provenance row around line 547 currently claims helper/fixture/criterion mutation coverage exclusively at `tests/test-verification.sh::test_capture_provenance`; clarify that this reports fixture supplies saved-PASS and successful-capture cases for those inputs, either by adding the reports locator there or moving those claims to the reports description. Parent owns any plan/task/binding update; this patch deliberately contains none.

## Limits

Fixtures have not executed, so syntax/applicability are the only verified outcomes. The parent must run the real family and required checks after applying, and supply new source-bound evidence. No runtime bug fix is proposed: RC3's isolated probe already established the current behavior.
