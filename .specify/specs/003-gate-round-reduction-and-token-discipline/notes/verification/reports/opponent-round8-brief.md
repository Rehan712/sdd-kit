# Opponent round 8 — reviewer brief

Reconstructed 2026-09-18 from the 2026-09-17 Decisions entries in STATUS.md.
The handoff asserted a ready-made brief already existed at this path; it did
not — `notes/verification/reports/` stopped at `opponent-round6.md`. This file
is that brief, rebuilt from the primary record.

Round 8 is AUTHORIZED (STATUS.md:279, 2026-09-17T09:48:00Z) and UNSPENT.
Verified this session: `spec-gate.sh waiver <spec-dir> opponent 8` exits 0;
round 9 is refused at exit 4.

## What is new since round 7

Four repairs, T030o33-T030o36, all ACCEPTED and UNREVIEWED. No independent
reviewer has attacked them. Each carries a derivation-based acceptance
criterion and its own mutation matrix.

### T030o33 — O-012, round-record-reparse-divergence (new, wrong-result)

Closed by DELETING a parser, not widening one. `vf_gate_round` now passes its
already-validated `$verdict`; `vf_reality_matrix` fails closed on any value the
catalog could not have produced; the second verdict parse at the old :2504 is
gone.

Derivation, not enumeration: the rule is stated over the VALIDATOR, not over
the line — any field `vf_reports` parses and emits is consumed from the emitted
catalog by every downstream reader, and no second parser re-derives it. The
sweep came from the call graph, not from the example, and has exactly two
members: `vf_reality_matrix` (the defect) and `vf_report_block`, whose
divergence is DELIBERATE because the sealed digest must cover quoted lines.

Measured before repair, on a one-AC reality-check round with a `MISSING` row:
`**Verdict:** READY` fired the guard (rc=3), while `**Verdict:**  READY`
(two spaces), `**Verdict:**READY` and a one-space READY beside a fenced
duplicate verdict all returned rc=0.

Attack surface worth probing: whether any reader of report text running after
`vf_reports` was missed, and whether `vf_report_block`'s deliberate divergence
can be turned into a field source.

### T030o34 — O-004, gate-report-schema-validation (reopened, 6th round)

**The preferred rule was MEASURED AND REJECTED BEFORE IMPLEMENTATION.** The
round-7 report and the handoff both preferred "count every recorded finding at
its recorded tier and reconcile totals against that". Extracted status and
severity per finding per round from the real `notes/opponent.md`: that rule
computes blocking=6 for round 1 against its declared 5, 6/3 for round 2 against
3/2, and 7/3 for round 3 against 3/1 — it REJECTS THREE ROUNDS WHOSE DIGESTS
ARE SEALED and cannot be edited without wedging every later reserve, complete
and reconcile.

The enforced rule is the report's own stated minimum, derived from the
predicate: `Status: resolved` asserts a repair no data available to
`vf_reports` can corroborate, so it may not buy a CLEARING verdict. "Rests on"
reads off the same predicate — the suppressed finding is one this gate's own
ROUND record already counted, which is history the report making the claim
cannot rewrite. A declared prior-review manifest is not a round and was never
counted, so a first round may still resolve a manifest-recorded finding and
clear (the shape real round-1 O-006 has). Gate-neutral by derivation over
CLEARED and READY — this gives the reality-check side its first
clearing-verdict protection.

Consequence accepted and recorded, not discovered later: the round that
ANNOUNCES a repair is not the round that clears. Measured before accepting —
every clearing round in this repository records ZERO findings (001 opponent
round 3, 001 reality-check, 002 opponent round 5, 002 reality-check), and all
seven rounds of this spec are non-clearing, so nothing real is rejected.

EXTENT DELIBERATELY NOT CLOSED, argued rather than skipped: a round can still
reach CLEARED by omitting a known open finding entirely. That needs cross-round
open-state tracking — a spec-level change, not this class. `vf_tally:1178`
carries the same `status != resolved` suppression but feeds a printf and
decides nothing, so it is a metric, not this class.

### T030o35 — O-002, round-authorization-grammar (reopened, 7th round)

Closed on both halves; the second was open by DOCUMENTATION, not by code.

Derived from the whole production the parser enforces —
`- <UTC> — <kind>: gate=<g>; round=<n>; after=<n-1>; by=<b>; reason=<r>[; revision=<v>]`
— in which every clause has exactly one refusal path and no refusal path may be
silent, so a clause added later inherits it. The gate clause was the only one
taking a bare `next`. It needed a DISTINCTION rather than a note added blindly:
`gate=<g>` ranges over the gates that exist, so another KNOWN gate is that
gate's record and stays correctly silent, while any other value is a malformed
candidate and is named with its line. The gate set moved into one library
constant (`VF_GATES` + `vf_is_gate`) so the guard cannot drift from the gates
the CLI accepts.

Candidate detection now also covers a `<kind>:` written without its trailing
space, but only behind the anchored prefix, so the 2026-09-04 Decisions entry
naming `waiver:` and `spec-revision:` in code spans is still not a candidate.

The authoring half closed where it was actually open: `spec-gate.sh waiver` is
now in README's command block and in the round-cap paragraph the four invoker
documents share, and the guard that keeps it there DERIVES the subcommand set
from the dispatcher in `scripts/spec-gate.sh` instead of enumerating verbs —
the enumeration is exactly how `waiver` shipped with a `--help` line and no
reader.

### T030o36 — O-010, verification-input-identity (reopened)

**The proposed normalization contained two defects found only by probing the
rule before trusting it, and a third found only by mutation.**

1. The round-7 report specified stripping "backticks, asterisks and
   underscores". Stripping underscores DELETES THE NEEDLE: `LC_` is one of the
   names the guard searches for, and a claim naming only the `LC_*` family — a
   complete statement of the superseded rule — escaped a normalizer that
   stripped it. Measured, then underscores kept; backticks and asterisks still
   stripped.
2. A bare participle is not a membership claim. This repository writes
   "`LC_CTYPE` and `LC_ALL` included" meaning "among them", and the first
   normalizing matcher read `tasks.md`'s own replacement text as the superseded
   claim. The reverse direction now requires a passive verb phrase.
3. The negation window began AT the predicate, so "The snapshot no longer
   includes `PATH`…" — how English negates this proposition in the forward
   shape — read as the superseded claim. The window now reaches behind the
   predicate.

Scope is taken from the enumeration the manifest itself uses
(`git ls-files --cached --others --exclude-standard` filtered through
`vf_bookkeeping_path`, minus `STATUS.md`), so it is the manifest set by
construction.

Correction to the round-7 report, recorded rather than quietly dropped: its
`Where` list names `tests/test-gate-contracts.sh:56-62`, which is the GUARD and
not a surviving claim — the live tree carried no survivor at round 7 and
carries none now.

## Mutation matrix (all restored byte-identically, verified with `cmp`)

- **A** — second verdict parse restored: kills the two-space, no-space and
  fenced-duplicate negatives end to end AND both direct-call cases, which
  invert rather than merely fail.
- **B** — clearing-verdict refusal removed: kills all four O-004 negatives on
  both gates.
- **B'** — refuse a clearing verdict on ANY resolved finding: kills the same-ID
  manifest positives on the tally and `--complete` paths. This is the
  over-correction that would have rejected the real round-1 O-006.
- **C** — gate clause silent again: kills the three slip diagnostics at both
  the library and the `spec-gate.sh waiver` entrypoint.
- **C'** — note every non-matching gate: kills the other-gate silence control.
- **C''** — candidate detection narrowed: kills the missing-kind-space case.
- **C'''** — candidate detection widened to a bare token scan: kills the prose
  control.
- **D1-D7** — isolate the O-010 guards one at a time: whitespace collapse,
  manifest-derived scope, negation discrimination, the reverse direction,
  underscore preservation, the passive verb phrase, and the negation window
  reaching behind the predicate.
- **E, F** — kill the documentation half from README and from one invoker
  document.
- **G** — adds an undocumented subcommand to the dispatcher; killed by all
  three of its obligations.

Two mutations exposed defects in the guards rather than in the code: **D3
SURVIVED at first**, which is what sent the author looking for the
forward-negation shape, and **D6** initially depended on live prose alone until
a fixture control was added.

A mutation that SURVIVES is the useful one. Re-run them.

## Known open — confirm, do not rediscover

- O-004 extent: a round can still reach CLEARED by omitting a known open
  finding entirely. Spec-level, not this class.
- O-002 residual from rounds 3/4: `<!DOCTYPE`, `<?`, `<![CDATA[`.
- README's capture/accept sequence says "Save the authentic
  Verification-Return block" without showing its grammar.
- `spec-gate.sh tally` on 001 fails at exit 3 with `duplicate identity field`
  on its legacy multi-round report. Pre-existing, untouched.
- The opponent-only totals, verdict-agreement and severity-downgrade guards are
  at `scripts/verification-lib.sh:1091`, `:1092`, `:1093` — **not** the
  `~:1079-1081` that the 2026-09-17 entries and earlier handoffs name. Verified
  by reading the file 2026-09-18. `clearing()` at `:1077-1079` and the
  suppression refusal at `:1099` are gate-neutral over CLEARED and READY.
- Round 4 declared unexamined and uncleared; rounds 6 and 7 did not reach it:
  umbrella/multi-repo `vf_gate_roots`, `vf_accept_transaction` crash windows,
  `vf_matrix_prior` with a real reality-check carry, the `r`-suffix follow-up
  branch, Linux/CI behaviour, per-negative branch coverage, and AC-014/017/018
  prose.

## Method this spec requires

1. Write each acceptance criterion as a DERIVATION FROM THE GRAMMAR THE PARSER
   READS, with its source cited — never as the list of spellings a report
   named. An enumeration is satisfiable without the class being closed; that is
   the single mechanism that reopened O-002 seven times and O-004 six.
2. TEST THE CRITERION BEFORE IMPLEMENTING IT, against the real recorded history
   in `notes/opponent.md`. Four proposed rules so far would have rejected the
   record that proposed them.
3. Mutation-isolate every guard in BOTH directions; restore byte-identically
   and verify with `cmp`.
4. Assert the exact diagnostic, never the exit code alone.
5. Hunt for shipped POSITIVES asserting an attack at rc=0. Six found so far;
   twice inside the repair for the finding that recorded the trap.

## Operational traps

- NEVER pipe a suite through `tail`; `tests/run.sh` prints no total and its
  exit code IS the signal. A command chain reports its LAST element's status —
  end long runs with `exit $rc` and read the receipt back.
- A guard that writes to the resource it is guarding is not a guard.
- Work outside the worktree. Round 7 ran under `/private/tmp/opp7/work` with
  `TMPDIR` inside it and created, modified, moved or removed NOTHING in the
  worktree — no floor, round, checkpoint or capture. Do the same.
- An ACCEPT does not move the source (`vf_semantic_file` rewrites `- [x]` to
  `- [ ]` and drops `*Evidence:*` before hashing `tasks.md`). ADDING a task
  block DOES. Any Decisions entry in STATUS.md DOES — only that section is
  hashed.
- Write the report under `notes/verification/reports/` — `vf_bookkeeping_path`
  exempts `notes/verification/*`, so it does not move the source mid-reservation.
  Verified in code 2026-09-18.

## Report grammar the gate will parse

The returned report must be the round-8 block ALONE (it is appended to
`notes/opponent.md`, which already holds rounds 1-7). Required shape:

```
## Round 8

**Round:** 8
**Timestamp:** <UTC, >= the reservation's `reserved` and not in the future>
**Source:** <the 64-hex source from the ROUND-8 reservation>
**Floor:** <the FLOOR-xxxxx id from the ROUND-8 reservation>
**Verdict:** CLEARED | CHALLENGED | BLOCKED
**Blocking:** <n> · **Minor:** <m>

### What I attacked
...

### Finding O-0XX
- **Class:** <class>
- **Status:** new | reopened | resolved
- **Prior:** O-0XX | none
- **Severity:** <tier>
- **Scenario:** ...
- **Where:** <file:line, ...>
- **Reproduced:** ...
- **Root cause:** <implementation-error | plan-gap | ...>
- **Blocks:** <REQ-..., AC-...>
- **Wrong behavior:** ...
- **Class-wide fix:** ...

### Held up / follow-up tasks
...
```

Hard constraints the completion enforces (`vf_gate_round`, verification-lib.sh
:2478-2526):

- `Source` and `Floor` must EQUAL the reservation's, and the floor must still
  validate to that same source at completion time — so nothing may move the
  source between reserve and complete.
- `Blocking`/`Minor` must agree with the findings recorded (`:1091`), the
  verdict must agree with the blocking count (`:1092`), a CLEARED verdict may
  not rest on a lowered severity tier (`:1093`) or on a finding this gate's
  ROUND record already counted open (`:1099`).
- Both `### What I attacked` and `### Held up / follow-up tasks` are required
  and must be non-empty (`:1089`).
- The completion must not change any already-sealed round block (`:2514-2521`).

Next free follow-up task id: **T030o37**.
