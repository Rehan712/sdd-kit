# Opponent round 9 — reviewer brief

Written 2026-09-22 by the invoker. Everything here is a claim to attack, not
authority. The receipts named below outrank this text.

## Authorization and identity

- Round 9 is AUTHORIZED by the Decisions line `2026-09-22T19:22:38Z — waiver:
  gate=opponent; round=9; …` (STATUS.md:329 when this was written; unhashed
  STATUS edits can shift line numbers, so find it by its timestamp). `bash scripts/spec-gate.sh waiver <spec-dir>
  opponent 9` exits 0; round 10 is refused at exit 4 with seven candidates.
- Reservation (fill-in by the invoker before dispatch — copy exactly into the
  report): **Round** 9 · **Source** aa18111b6dbe36a6d75e923129802ffa7c688dddedc9a7ec811c350dd7bc66c4 · **Floor** FLOOR-k1reWt ·
  **reserved** 2026-09-22T23:49:11Z. Read them yourself from
  `notes/verification/rounds/opponent/ROUND-9/meta.nul`.

## Scope: what changed since round 8

Derived mechanically, not from memory: the per-file `path` records of
round 8's FLOOR-bvsiKa manifest (`notes/verification/floors/FLOOR-bvsiKa/inputs.nul`)
against the current manifest differ in exactly four files:

- `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh` — the two
  accepted, UNREVIEWED repairs:
  - **T030o37** (round-8 O-004 + mutation D1): both history writers keep the
    strictest tier; `vf_tally` folds the same way. Task block tasks.md:672.
  - **T030o38** (round-8 O-002): every dispatcher clause in
    `scripts/spec-gate.sh` must classify or fail closed. Task block tasks.md:683.
  - Their reasoning: the first four 2026-09-20 Decisions entries
    (STATUS.md:311-315 when written; the fifth, at :317, authorizes T031). Their
    mutation evidence: `notes/verification/reports/repair-mutations-tightened.log`
    (script `repair-mutations.sh`), plus `repair-o004-*`, `repair-o002-*`.
- `STATUS.md` (Decisions only is hashed) and `tasks.md` (the two task blocks).

Consumers of the changed functions and all surfaces the spec declares are in
scope too; you may expand into unchanged code.

## New evidence since round 8

- Reality-check round 1 sealed NEEDS WORK: `notes/reality-check.md`
  (21 PASS, AC-016 FAIL, AC-019 MISSING).
- Hosted CI on the exact current tree: `notes/verification/platforms/ci-20260922/`
  (snapshot mapping, job logs, conclusions). This is the first Linux/CI
  evidence for this source — the retained "Linux/CI behaviour" surface.

## Invoker observation — unverified, not a finding

`vf_bookkeeping_path` (`scripts/verification-lib.sh:1322`) excludes
`.specify/specs/*/notes/{opponent,reality-check,evidence}.md` for EVERY spec,
while `tests/test-gate-contracts.sh:702-706` asserts rounds/blocking/unclassified
counts read from the LIVE shipped 002 spec's reports. If that holds, a test
outcome depends on a file outside the capture input identity, so an edit to
those reports would leave a reusable capture "current". Attack or dismiss it;
do not take it on trust.

## Known open — confirm, do not rediscover

- O-004 omission extent: a round can reach CLEARED by not re-listing a known
  open finding (spec-level; cross-round open-state tracking deferred).
- Reality-check totals gap: the totals/verdict-agreement/downgrade guards are
  `gate=="opponent"` only (`verification-lib.sh:1093-1095`).
- README omits the Verification-Return grammar; invoker instructions omit the
  mandatory completion marker.
- 001's legacy report fails `tally` at exit 3 (pre-existing, untouched).
- Retained unexamined surfaces: umbrella/multi-repo gate roots, acceptance
  crash windows, real reality-check carry, the `r`-suffix follow-up branch,
  per-negative branch coverage, AC-014/017/018 prose.

## Method this spec requires

1. Derive each criterion from the grammar the parser reads, with its source —
   an enumeration of reported spellings is satisfiable while the class stays open.
2. Test a proposed rule against the real recorded history in `notes/opponent.md`
   before proposing it; several proposals would have rejected their own record.
3. Mutation-isolate guards in both directions; restore byte-identically (`cmp`).
4. Assert exact diagnostics, never exit codes alone.
5. Hunt for shipped POSITIVES asserting an attack at rc=0.

## Operational rules

- Work in a copy outside the worktree (e.g. `/private/tmp/opp9/work`, with
  `TMPDIR` inside it). Create, modify, move or remove NOTHING in the worktree
  except your report file. No floor, round, checkpoint, capture or accept.
  The source must not move between reservation and completion.
- Never pipe a suite through `tail`; `tests/run.sh` prints no total and its
  exit code is the signal. Capture exit codes and read them back.
- Write the report to `notes/verification/reports/opponent-round9.md`
  (exempt from the source identity).

## Report grammar the gate will parse

The returned file is the round-9 block ALONE. `--complete` appends it to
`notes/opponent.md`, validates it with `vf_reports`, and re-verifies rounds 1-8.

```
## Round 9

**Round:** 9
**Timestamp:** <UTC, not before the reservation's reserved time, not in the future>
**Source:** <exactly the reservation's source>
**Floor:** <exactly the reservation's floor>
**Verdict:** CLEARED | CHALLENGED
**Blocking:** <n> · **Minor:** <m>

### What I attacked
...

### Finding O-0XX
- **Class:** …
- **Status:** new | reopened | resolved
- **Prior:** O-0XX | none
- **Severity:** …
- **Scenario:** …
- **Where:** file:line, …
- **Reproduced:** …
- **Root cause:** …
- **Blocks:** REQ-…, AC-…
- **Wrong behavior:** …
- **Class-wide fix:** …

### Held up / follow-up tasks
...
<!-- gate-round-end: opponent:9 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:9 -->`; nothing
non-blank may follow it. Constraints `vf_reports` enforces
(`scripts/verification-lib.sh:1086-1101`), stated so a correct report of either
verdict can be canonized — the verdict itself is yours alone:

- `Blocking`/`Minor` must equal the counted findings (`:1093`); CLEARED
  requires zero blocking and CHALLENGED requires at least one (`:1094`).
- A CLEARED report may not carry a known ID at a tier below its strictest
  recorded tier (`:1095`), nor a `resolved` finding that an earlier round of
  this gate counted open (`:1101`). O-004 and O-002 were counted open in
  round 8, so under CLEARED neither may appear as a `### Finding` block; your
  assessment of their repairs then belongs in the two prose sections.
- A CHALLENGED report may re-list findings with any status at their true tier.
