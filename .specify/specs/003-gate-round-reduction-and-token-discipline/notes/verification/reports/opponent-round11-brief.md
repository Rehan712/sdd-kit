# Opponent round 11 — reviewer brief

Written 2026-09-26 by the invoker. Everything here is a claim to attack, not
authority. The receipts named below outrank this text. Paths are relative to
the spec directory `.specify/specs/003-gate-round-reduction-and-token-discipline/`
unless they start with `scripts/`, `tests/`, `templates/`, `agents/`, `README.md`,
`.specify/stack.yml` or `.github/` (worktree root:
`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 11 is AUTHORIZED by the Decisions line `2026-09-26T11:09:20Z — waiver:
  gate=opponent; round=11; after=10; by=Rehan712; …`. Find it by its timestamp:
  it was STATUS.md:431 when checked at authorization (`r11-waiver-*.log`) and is
  STATUS.md:433 now, because two lines of neutral "Where things stand" text were
  added above the Decisions log afterwards; only `## Decisions log` is hashed, and
  its digest is unchanged. `bash scripts/spec-gate.sh waiver <spec-dir> opponent 11`
  exits 0, and round 12 is refused at exit 4 with nine candidates
  (`notes/verification/reports/r11-entry-audit.log`, `.rc` = 0; that audit also
  re-derives the source, the Decisions digest, the ten sealed round digests, the
  tally, HEAD and the task boxes).
- Reservation (copy exactly into the report): **Round** 11 · **Source**
  1fba08ed13e83cbca56ef731047f39c3668dfa47c4ff81873de63ee2eea3b0b0 · **Floor** FLOOR-QeBcq3 · **reserved** 2026-09-26T17:27:11Z.
  Read them yourself from `notes/verification/rounds/opponent/ROUND-11/meta.nul`.

## Scope: what changed since round 10

Derived mechanically, not from memory (`notes/verification/reports/r11-scope.sh`;
`r11-scope.log`, exit 0): the six-field records of round 10's FLOOR-qQEv7w
`inputs.nul` against FLOOR-6eaaRv's (the post-repair floor, source `e07efa81…`)
and against FLOOR-QeBcq3's.

- FLOOR-qQEv7w → FLOOR-6eaaRv: 21 changed `path` records and one new one
  (`tests/shellcheck.sh`), all the single accepted repair, NOT yet gated
  independently:
  - **T030o41** (round-10 O-015, blocking, plus the round-10 anchor-layout
    isolation gap, then expanded by user decision to every measured member of
    the class): task block `tasks.md:716`. Changed: `scripts/verification-lib.sh`,
    `tests/helpers.sh`, `tests/run.sh`, `tests/shellcheck.sh` (new),
    `tests/test-build-adapters.sh`, `tests/test-executable-bits.sh`,
    `tests/test-gate-contracts.sh`, `tests/test-golden-example.sh`,
    `tests/test-model-policy.sh`, `tests/test-sdd-analyze.sh`,
    `tests/test-spec-ac-coverage.sh`, `tests/test-spec-dispatch.sh`,
    `tests/test-spec-gate.sh`, `tests/test-usage-limits.sh`,
    `tests/test-verification.sh`, `templates/verification-contract.md`,
    `README.md`, `.specify/stack.yml`, `.github/workflows/ci.yml`, plus 003's
    `tasks.md` and `STATUS.md`. `plan.md` and `spec.md` are unchanged.
  - Kernel entry points: `vf_semantic_file` (`scripts/verification-lib.sh:1396`),
    `vf_path_content` (:1417), `vf_path_record` (:1421), `vf_source_paths` (:1451),
    `vf_git` (:1476), `vf_snapshot` (:1480). Test-side: `superseded_environment_scan`
    and `superseded_environment_cases` (`tests/test-gate-contracts.sh:55`, :137);
    in `tests/helpers.sh`, `copy_kit` (:405), `git_host` (:442), `fixture_git` (:463),
    `fixture_build_failed` (:482), `on_host_kit` (:494), `git_config_pinned` (:507),
    `kit_files` (:517), `t_run_all` (:537), `make_verification_git_dir` (:568).
    `tests/shellcheck.sh` replaced the inline ShellCheck command in `gate_checks`,
    `reuse_checks`, CI, README and T027's Verify.
- FLOOR-6eaaRv → FLOOR-QeBcq3: `STATUS.md` alone: the round-11 authorization batch (STATUS.md:431-433).
  FLOOR-QeBcq3 sealed at exit 0, 22 executed and 52 reused, 11:43:04Z to 15:52:00Z
  (`notes/verification/reports/r11-floor-1.{pre,log,rc,samples.log}`), and validates
  current for the reserved source (`r11-floor-validate.{out,err,rc}`, exit 0, empty stderr).

Consumers of the changed functions and every surface the spec declares are in
scope too, and you may expand into unchanged code.

## Evidence for the repair (claims, not authority)

- The rule and its derivation, in Decisions order: STATUS.md:395 (the identity
  rule), :403 (the user's expansion to every measured member, re-derived from the
  production), :409 (the parity rule: a reader enumerates under exactly the
  environment and configuration the identity enumerates under), :413, :417, :421
  and :425 (the repairs for reviews 3 to 6, each decided before code), :427 (the
  user's pace decision: review 7 is the last focused review and only its blocking
  findings are repaired), :429 (review 7, the matrix of record, the open extent,
  and the freeze). The user's AC-023 reading and the analyzer-grammar
  observation: :405 and :397. The live-worktree `stack.yml` incident: :399.
- Reproduction before repair: `notes/verification/reports/o015-repro.{sh,log,rc}`
  (exit 0, 64 checks).
- Seven independent review rounds. Each of the first six found at least one
  blocking finding (review 3 stopped incomplete on the session limit, with two
  blocking findings verified); the seventh found none, with four minors:
  `t030o41-review.md` (passes A/B), `t030o41-review2-pass{C,D}.md`,
  `t030o41-review3-partial.md` (incomplete), `t030o41-review4.md` to
  `t030o41-review6.md`, and `t030o41-review7.md` (no blocking finding, four
  minor). Each delta is `t030o41-session{,2,3,4,4b,4c,4d}.diff`. A pre-repair
  baseline is checkable against FLOOR-qQEv7w's `path` records.
- Matrix of record, v6: `t030o41-mutations.sh`, run in three shards
  (`t030o41-mutations-shard{0,1,2}.{log,rc}`, each exit 0): 93 rows killed as
  required (79 kill, 4 over-correction, 10 record), 15 surviving as argued
  (12 equivalents, 3 witnesses), 30 baselines, no watchdog.
- Acceptance: CAP-455-RNmM6l (`bash tests/run.sh && bash tests/shellcheck.sh`,
  147/147), `notes/verification/returns/T030o41.txt`, `T030o41-accept.{log,rc}`.
  Hosted CI run 36159615221 passed 4/4 on a snapshot of source `e07efa81…`
  (`notes/verification/platforms/ci-20260925-summary.txt`). FLOOR-6eaaRv sealed
  at exit 0 and validated current for `e07efa81…`. All of these differ from the
  reviewed source in Decisions only (the round-11 batch, STATUS.md:431-433), so
  they are HISTORICAL. FLOOR-QeBcq3 re-executes and refreshes them; use its captures.
  No hosted CI has run on the reviewed source.

## Invoker observation — none new

The invoker has no new unverified observation for this round. Review 7's four
minors were NOT reproduced by the invoker (STATUS.md:429 says so); treat them,
and every "argued" survivor in the matrix, as claims to attack.

## Known open — recorded, you may challenge it

Open extent carried out of T030o41 by the user's pace decision (STATUS.md:429),
known and recorded, not repaired:
- review 7's F1 (`GIT_CEILING_DIRECTORIES="$SANDBOX"` is no bound for a write in
  `$SANDBOX` itself, a `$SANDBOX` holding `:`, or a relative one), F2 (two site
  checks with no row that can fail alone), F4 (the unchecked fixture `add` at
  `tests/test-verification.sh:481`); F3 was a correction of a recorded reason;
- the timing-dependent unjudged site `tests/test-verification.sh:732` (K74);
- the harness-level bash startup environment: every captured command runs as
  `bash -o pipefail -c`, which reads `BASH_ENV`, `ENV`, `SHELLOPTS`, `BASHOPTS`
  and exported functions at startup (Open questions; this reopens the
  justification of the 2026-09-13 environment-membership rule);
- the kernel's ambient reads and writes of fixture repositories;
- the analyzer's field grammar (STATUS.md:397), and with it AC-023's narrowed
  reading, accepted by the user (STATUS.md:405);
- the umbrella-only in-place readers.

Older known open — confirm, do not rediscover:
- O-004 omission extent: a round can reach CLEARED by not re-listing a known
  open finding. This is spec-level; cross-round open-state tracking was deferred.
- Reality-check totals gap: the totals, verdict-agreement and downgrade guards
  at `scripts/verification-lib.sh:1101-1103` are `gate=="opponent"` only.
- README omits the Verification-Return grammar, and the invoker documents omit
  the mandatory completion marker.
- 001's legacy report fails `tally` at exit 3 (pre-existing, untouched).
- Retained unexamined surfaces: umbrella and multi-repo gate roots, acceptance
  crash windows, real reality-check carry, the `r`-suffix follow-up branch,
  per-negative branch coverage, and AC-014/017/018 prose.

## Method this spec requires

1. Derive each criterion from the grammar or production the code reads, with
   its source. An enumeration of reported spellings is satisfiable while the
   class stays open.
2. Test a proposed rule against the real recorded history (`notes/opponent.md`,
   and 001's and 002's reports) before proposing it. Several proposals would
   have rejected their own record.
3. Mutation-isolate guards in both directions, and restore byte-identically (`cmp`).
4. Assert exact diagnostics, never exit codes alone.
5. Hunt for shipped POSITIVES that assert an attack at rc=0.

## Operational rules

- Work in a copy outside the worktree (for example `/private/tmp/opp11/work`,
  with `TMPDIR` inside it). Create, modify, move or remove NOTHING in the
  worktree except your report file. Run no floor, round, checkpoint, capture or
  accept, and no suite or test function in the worktree itself: the 2026-09-24
  incident (STATUS.md:399) deleted a live file that way. The source must not
  move between reservation and completion, and the invoker checks that the
  worktree is byte-identical before and after your run.
- Free disk: about 18 GiB at reservation; swap shares the volume and has taken
  several GiB during long runs. Check `df -h /` before large copies, and remove
  your own `/private/tmp/opp11` when you finish.
- Never pipe a suite through `tail`. `tests/run.sh` prints no total, so its exit
  code is the signal. Capture exit codes and read them back.
- Write the report to `notes/verification/reports/opponent-round11.md` (exempt
  from the source identity), AND return it verbatim as your final message.

## Report grammar the gate will parse

The returned file is the round-11 block ALONE. `--complete` appends it to
`notes/opponent.md`, validates it with `vf_reports`, re-validates the floor to
the reserved source, and re-verifies rounds 1-10 against their sealed digests.

```
## Round 11

**Round:** 11
**Timestamp:** <UTC YYYY-MM-DDTHH:MM:SSZ, not before the reserved time, not in the future>
**Source:** <exactly the reservation's source>
**Floor:** <exactly the reservation's floor>
**Verdict:** CLEARED | CHALLENGED
**Blocking:** <n> · **Minor:** <m>

### What I attacked
...

### Finding O-0XX
- **Class:** …
- **Status:** new | open | reopened | resolved
- **Prior:** O-0XX | none
- **Severity:** data-loss | wrong-result | regression | crash | minor | degraded
- **Scenario:** …
- **Where:** file:line, …
- **Reproduced:** …
- **Root cause:** plan-gap | spec-gap | implementation-error
- **Blocks:** REQ-…, AC-… | none
- **Wrong behavior:** …
- **Class-wide fix:** …

### Held up / follow-up tasks
...
<!-- gate-round-end: opponent:11 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:11 -->`
(`scripts/verification-lib.sh:1144-1145`), and nothing non-blank may follow it.
These are the constraints `vf_reports` enforces (:1095-1109). They are stated so
that a correct report of either verdict can be canonized. The verdict itself is
yours alone.

- `Blocking`/`Minor` must equal the counted findings (:1101). CLEARED requires
  zero blocking, and CHALLENGED requires at least one (:1102).
- A CLEARED report may not carry a known ID at a tier below its strictest
  recorded tier (:1103). Nor may it carry a `resolved` finding that an earlier
  round of this gate counted open (:1109). O-015 was counted open (new,
  wrong-result) in round 10. So under CLEARED it may not appear as a
  `### Finding` block, and your assessment of its repair belongs in the two
  prose sections.
- A CHALLENGED report may re-list findings with any status, at their true tier.
