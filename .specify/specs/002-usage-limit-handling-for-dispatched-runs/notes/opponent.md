# Opponent review — 002-usage-limit-handling-for-dispatched-runs

**Date:** 2026-07-20
**Verdict:** CHALLENGED
**Round:** 1

## What I attacked

I traced the classifier from captured provider output through dispatch policy,
fallback, parking, and replay, then re-ran the focused suites, full suite,
shellcheck, AC coverage, and evidence checks. I also exercised a known
human-clock usage-limit wording outside the narrow fixture corpus, because the
feature's value depends on recognizing real provider wording rather than only
the one spelling in each fixture.

## Findings

1. **Known clock-only reset messages are treated as ordinary failures** — *severity:* wrong-result
   - **Scenario:** Claude emits the wording cited by the spec's own reference:
     `You've hit your session limit. Your limit will reset at 2pm (America/New_York).`
     Run `scripts/usage-limit.sh classify claude <capture> --now 1704067200`.
     The reproduced result is `none` with exit 1. The closely related
     `You've hit your session limit. Your limit resets 2pm.` also returns
     `none`. Codex's `... Try again at 2pm.` matches but is emitted as
     `limit\tunknown` because its clock parser also requires `HH:MM`.
   - **Where:** `scripts/usage-limit-patterns.tsv:3-6` requires a colon in all
     clock values and does not accept `will reset at`; `scripts/usage-limit.sh:63-74`
     likewise only extracts `H:MM am/pm`.
   - **Wrong behavior:** A real, documented usage-limit failure falls through
     `scripts/spec-dispatch.sh:450-454` as generic exit 6, so no configured
     park/delegate action occurs. A recognized Codex clock-only limit becomes
     `unknown` and takes the manual-only path at `scripts/spec-dispatch.sh:465-481`.
     This defeats the promised classification and automatic recovery for a
     message that carries a usable reset time.
   - **Smallest fix:** Accept both `H[H]am/pm` and `H[H]:MMam/pm`, including
     `will reset at`, in the table and central clock extractor; normalize a
     missing minute to `:00`. Add Claude and Codex no-minute fixtures plus
     dispatch-policy assertions that they park/delegate rather than exit 6 or
     manual-only.
   - **Root cause:** plan-gap. The plan's pattern table and clock grammar
     pre-decided only colon-bearing clocks, despite the referenced Claude
     wording using `2pm`; the implementation follows that narrowed design.
   - **Blocks:** REQ-001, REQ-002, AC-001, AC-002.

## Follow-up tasks proposed

- T013o1 — Broaden clock-only limit recognition/extraction and cover it through the dispatch policy path (→ Finding 1).

## Round 2

# Opponent review — 002-usage-limit-handling-for-dispatched-runs

**Date:** 2026-07-20
**Verdict:** CHALLENGED
**Round:** 2

## What I attacked

I verified the Round 1 clock-only repair from the pattern table through reset
extraction and the configured dispatch park path: the new Claude and Codex
fixtures classify and create/schedule resume units rather than falling through
to exit 6 or manual-only recovery. I then pressure-tested resume replay around
the required remove-before-replay ordering, including a scheduler failure at
that boundary, and re-ran the focused suites, full suite, shellcheck, AC
coverage, evidence check, and diff whitespace check.

## Findings

1. **A scheduler remove failure permanently strands a parked run** — *severity:* wrong-result
   - **Scenario:** A cron/launchd scheduler entry exists for a pending unit,
     but its `remove <unit-id>` command fails transiently (for example,
     crontab/launchctl is temporarily unavailable). `spec-resume.sh run
     <unit-id>` acquires the unit lock and invokes the failing removal. I
     reproduced this with a scheduler stub that succeeds for `add` and returns
     1 for `remove`: `run` exits 1 before the stored argv runs, leaves the unit
     pending and its scheduler job present, and leaves `.<unit-id>.lock` in
     the state root. Every later scheduler firing waits for the lock and exits
     `resume unit is busy`, even after the scheduler itself recovers.
   - **Where:** `scripts/spec-resume.sh:222-235`, especially the unchecked
     `"$SCHEDULER" remove "$unit_id"` at line 232 while `set -e` is active.
   - **Wrong behavior:** One transient scheduler error turns an automatically
     recoverable limit hit into a permanently dead parked run. This violates
     the required one-shot replay/recovery behavior and leaves an orphaned
     scheduler entry rather than safely retrying or failing the unit.
   - **Smallest fix:** Handle `remove` explicitly before changing state: on
     failure release the per-unit lock and return nonzero (leaving the pending
     unit/job retryable), or atomically mark it failed and record the event.
     Add a fixture where `remove` fails, asserting no argv replay and no stale
     lock; then make removal succeed and assert the same unit can resume.
   - **Root cause:** implementation-error. The plan correctly requires
     remove-before-replay and an atomic per-unit lock, but the implementation
     lets `set -e` terminate between acquiring and releasing that lock.
   - **Blocks:** REQ-005 / AC-005.

## Follow-up tasks proposed

- T013o2 — Make failed scheduler removal release/reconcile the resume-unit lock and cover recovery after a transient removal failure (→ Finding 1).

## Round 3

# Opponent review — 002-usage-limit-handling-for-dispatched-runs

**Date:** 2026-07-20
**Verdict:** CHALLENGED
**Round:** 3

## What I attacked

I reverified both earlier findings from their repaired classifier and replay
paths: clock-only reset wording is now parsed through the configured park path,
and a failed scheduler removal during `run` releases the unit lock and permits a
later replay. I then attacked the same lock/removal boundary in `cancel`, and
reran the full suite, ShellCheck, AC coverage, evidence integrity, analyzer,
and diff-whitespace checks; those checks pass but do not cover this failure
path.

## Findings

1. **A scheduler remove failure during cancel permanently strands the resume unit** — *severity:* wrong-result
   - **Scenario:** A pending unit has a scheduler entry, but the scheduler's
     `remove <unit-id>` fails transiently. After parking a unit with a seam
     stub that succeeds for `add` and fails for `remove`, `spec-resume.sh
     cancel <unit-id>` exits 1. The unit and job remain, but so does
     `.<unit-id>.lock`. Once the scheduler stub is repaired, a second `cancel`
     (and a scheduled `run`) waits for the stale lock and exits `resume unit is
     busy`; no automatic recovery or cancellation is possible.
   - **Where:** `scripts/spec-resume.sh:298-306`, specifically line 303 after
     `acquire_lock` and before `release_lock`.
   - **Wrong behavior:** A transient scheduler failure makes a parked
     dispatch permanently unmanageable and prevents the required cancel/replay
     lifecycle. This violates the recoverable, inspectable-and-cancellable
     resume-unit behavior in REQ-005 and AC-005.
   - **Smallest fix:** Handle scheduler removal in `cancel` explicitly: on
     failure, release the lock and return nonzero while retaining the pending
     unit/job; only delete the unit after a successful removal. Add a fixture
     that repeats the recovery assertion already present for `run`.
   - **Root cause:** implementation-error. The plan's lock lifecycle requires
     atomic, recoverable unit operations; the Round 2 repair applied that rule
     to `run`, but `cancel` still lets `set -e` exit between lock acquisition
     and release.
   - **Blocks:** REQ-005 / AC-005.

## Escalation

This is not a spec ambiguity: it indicates the current implementation approach
has incomplete error handling wherever it holds the per-unit lock across a
scheduler operation. The user must decide whether to rework that lifecycle
handling (including the proposed follow-up) or accept the stranded-unit risk in
a signed `STATUS.md` waiver; the gate remains challenged pending that decision
and a verified repair.

## Follow-up tasks proposed

- T013o3 — Release the resume-unit lock when scheduler removal fails during cancel, and verify retry after scheduler recovery (→ Finding 1).
