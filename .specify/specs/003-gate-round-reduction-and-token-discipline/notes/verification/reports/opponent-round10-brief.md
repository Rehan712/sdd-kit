# Opponent round 10 — reviewer brief

Written 2026-09-24 by the invoker. Everything here is a claim to attack, not
authority. The receipts named below outrank this text. Paths are relative to
the spec directory `.specify/specs/003-gate-round-reduction-and-token-discipline/`
unless they start with `scripts/`, `tests/`, `templates/` or `agents/` (worktree
root: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 10 is AUTHORIZED by the Decisions line `2026-09-23T17:33:27Z — waiver:
  gate=opponent; round=10; after=9; by=Rehan712; …` (STATUS.md:367 when this was
  written; find it by its timestamp). `bash scripts/spec-gate.sh waiver <spec-dir>
  opponent 10` exits 0, and round 11 is refused at exit 4 with eight candidates
  (`notes/verification/reports/r10-entry-audit.log`, `.rc` = 0).
- Reservation (copy exactly into the report): **Round** 10 · **Source**
  6c6291c2b37d35fb82c67c42c173ae042bb116c742f1c84a5dfa9c1c77c04c2d · **Floor** FLOOR-qQEv7w · **reserved** 2026-09-24T02:31:44Z.
  Read them yourself from `notes/verification/rounds/opponent/ROUND-10/meta.nul`.

## Scope: what changed since round 9

Derived mechanically, not from memory (`notes/verification/reports/r10-scope.{sh,log}`,
exit 0): the six-field records of round 9's FLOOR-k1reWt `inputs.nul` against a
read-only snapshot of the live tree differ in these paths:

- `scripts/verification-lib.sh`, `tests/test-verification.sh`,
  `tests/test-gate-contracts.sh`, `templates/verification-contract.md`: the two
  accepted repairs, NOT yet gated independently:
  - **T030o39** (round-9 O-013, blocking): generated bookkeeping anchored to the
    VERIFIED spec (`vf_bookkeeping_path`, `scripts/verification-lib.sh:1333`),
    filesystem case-fold probe (`vf_case_folds` :1354), string anchor
    (`vf_bookkeeping_anchor` :1368), physical resolver (`vf_physical_rel` :1379),
    named refusals of a declared input that is the repository root or the spec's
    own bookkeeping (:1470-1472), and per-path anchoring of the O-010 scan
    (`tests/test-gate-contracts.sh:42-50`). Task block `tasks.md:694`.
  - **T030o40** (round-9 O-014, minor, plus the two round-9 isolation gaps): the
    lowered-tier predicate evaluated once per observation in `vf_reports`
    (:1054-1057) and emitted as `downgrade` records; `vf_tally` counts those
    records (:1232, :1245-1253) instead of folding again. Fixtures for the
    manifest-then-round downgrade, the cross-gate same ID, and two dispatcher
    clauses on one line. Task block `tasks.md:705`.
- `plan.md` (§3 step 3 aligned by T030o39), `tasks.md` (the two task blocks),
  `STATUS.md` (only `## Decisions log` is hashed; the new entries are
  STATUS.md:339-367).
- Twelve NEW records: the `index` and `path` records of 001's and 002's
  `notes/{evidence,opponent,reality-check}.md`. They now enter the identity as
  ordinary source, which is the intended effect of the O-013 anchoring.

FLOOR-oejTDu (the post-repair floor, source `d27bab53…`) against the current
tree differs in `STATUS.md` alone: the round-10 authorization batch.

Consumers of the changed functions and every surface the spec declares are in
scope too, and you may expand into unchanged code.

## Evidence for the repairs (claims, not authority)

- The user's anchoring reading of REQ-009, which T030o39 implements: STATUS.md:341.
  The rule and its derivation: :347-353. Residual extent, argued rather than
  closed: :359, and "T030o39 residual extent" under Open questions.
- Reproduction before repair: `notes/verification/reports/o013-o014-repro.{sh,log,rc}` (exit 0).
- Scan-scope measurement behind the per-path O-010 anchoring:
  `notes/verification/reports/o010-scope-measure.{sh,log}`.
- Three independent review passes, each of which found a fail-closed regression
  that was then repaired: `notes/verification/reports/t030o39-o40-review{-brief,}.md`, STATUS.md:355.
- Matrix of record: `notes/verification/reports/t030o39-o40-mutations.{sh,py,log,rc}`
  (exit 0: 25 kill mutants killed, 2 argued equivalents E1/E2 surviving,
  3 over-correction controls killed). Runs 1-3 were stopped and are void
  (`…-matrix-run1-stopped.log`, `…-run2-3.note`); run 1's glob-routing bug is
  recorded at STATUS.md:361.
- Acceptance: CAP-411-B8GLAC, plus `T030o39-accept.{log,rc}` and `T030o40-accept.{log,rc}`.
  CAP-412-59sk66 ran T027's full suite 130/130 and ShellCheck. Hosted CI run
  35854215839 is 4/4 (`notes/verification/platforms/ci-20260923-summary.txt`).
  All of these are on source `d27bab53…`, which differs from the reviewed source
  in Decisions only, so they are HISTORICAL. The round-10 floor re-executes and
  refreshes them; use its captures.
- Tally moved `severity-downgrades` 4 → 5 (O-001 in round 1); every other
  counter is unchanged (`r10-entry-audit.log`).

## Invoker observation — none new

The invoker has no new unverified observation for this round. The residual
extent at STATUS.md:359 was argued as failing closed or pre-existing by the
invoker who wrote the repair. Treat each item there as a claim to attack.

## Known open — confirm, do not rediscover

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

- Work in a copy outside the worktree (for example `/private/tmp/opp10/work`,
  with `TMPDIR` inside it). Create, modify, move or remove NOTHING in the
  worktree except your report file. Run no floor, round, checkpoint, capture or
  accept. The source must not move between reservation and completion.
- Free disk on this host is limited (about 13 GiB at reservation; swap shares
  the volume and has taken several GiB during long runs). Check `df -h /` before large copies, and remove your
  own `/private/tmp/opp10` when you finish.
- Never pipe a suite through `tail`. `tests/run.sh` prints no total, so its exit
  code is the signal. Capture exit codes and read them back.
- Write the report to `notes/verification/reports/opponent-round10.md` (exempt
  from the source identity), AND return it verbatim as your final message.

## Report grammar the gate will parse

The returned file is the round-10 block ALONE. `--complete` appends it to
`notes/opponent.md`, validates it with `vf_reports`, re-validates the floor to
the reserved source, and re-verifies rounds 1-9 against their sealed digests.

```
## Round 10

**Round:** 10
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
<!-- gate-round-end: opponent:10 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:10 -->`
(`scripts/verification-lib.sh:1144-1145`), and nothing non-blank may follow it.
These are the constraints `vf_reports` enforces (:1095-1109). They are stated so
that a correct report of either verdict can be canonized. The verdict itself is
yours alone.

- `Blocking`/`Minor` must equal the counted findings (:1101). CLEARED requires
  zero blocking, and CHALLENGED requires at least one (:1102).
- A CLEARED report may not carry a known ID at a tier below its strictest
  recorded tier (:1103). Nor may it carry a `resolved` finding that an earlier
  round of this gate counted open (:1109). O-013 and O-014 were counted open in
  round 9. So under CLEARED, neither may appear as a `### Finding` block, and
  your assessment of their repairs belongs in the two prose sections.
- A CHALLENGED report may re-list findings with any status, at their true tier.
