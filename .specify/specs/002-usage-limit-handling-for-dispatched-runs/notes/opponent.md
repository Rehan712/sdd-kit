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

## Round 4

# Opponent review — 002-usage-limit-handling-for-dispatched-runs

**Date:** 2026-07-20
**Verdict:** CHALLENGED
**Round:** 4

## What I attacked

I re-verified the Round 3 repair independently (own scheduler stub, not the
suite): a failing `remove` during `cancel` now exits 1 with the lock released
and the pending unit + job preserved, and a post-recovery `cancel` cleans up
and records the STATUS event. The full suite (all suites green, 23/23 limits)
and `shellcheck -S warning -x scripts/*.sh tests/*.sh` pass. I then attacked
the surfaces tests cannot see: the environment the real scheduler gives a
fired unit, the remaining lock-held failure windows the o2/o3 fixes did not
cover, and the pattern rows the o1 repair did not touch.

## Findings

1. **A scheduler-fired resume replays into an environment where no provider CLI exists** — *severity:* wrong-result
   - **Scenario:** Any parked dispatch on a normal install. The generated
     launchd plist sets only `SDD_RESUME_ROOT`
     (`scripts/spec-resume-scheduler.sh:78-82`); the cron entry likewise
     (`scripts/spec-resume-scheduler.sh:125`). launchd user agents and cron
     run with the stock system PATH and never source the user's profile. On
     this host `claude` is at `~/.local/bin`, `codex`/`copilot` at
     `/opt/homebrew/bin` — none reachable. Reproduced: parked a unit whose
     argv mirrors the dispatch guard, replayed it under the plist's declared
     environment (`env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin HOME=…
     SDD_RESUME_ROOT=… spec-resume.sh run <unit>`): the guard at
     `scripts/spec-dispatch.sh:155` fails, `run` exits 4, and the unit is
     marked `failed` with `last_exit 4` after consuming a retry.
   - **Where:** `scripts/spec-resume-scheduler.sh:78-82` (launchd), `:125`
     (cron); the replay then dies at `scripts/spec-dispatch.sh:155` (and would
     die at `:299`/`:302` even without the guard — bare CLI names).
   - **Wrong behavior:** The feature's headline path — overnight park, fire at
     reset, "find the tasks finished in the morning" — fails on every real
     firing on a standard brew/npm install. The user discovers a failed unit
     hours later, which is precisely the outcome REQ-001 forbids. Every test
     stubs the scheduler seam, so the suite cannot observe this.
   - **Smallest fix:** Capture the parking process's `PATH` (unit metadata or
     scheduler args) and set it in the plist `EnvironmentVariables` and the
     cron entry's `env` invocation; add a seam-level assertion that `add`
     embeds the captured PATH.
   - **Root cause:** plan-gap. The plan designed the scheduler seam only as
     "replaceable by env in tests" (plan.md §files) and never decided the
     fired job's runtime environment; the implementation faithfully emits an
     entry with no environment capture.
   - **Blocks:** REQ-005 / AC-005, MET-001, CON-003 (the replay is
     argv-identical but not behavior-identical).

2. **A metadata write failure strands the unit behind a stale lock with its scheduler job already gone** — *severity:* wrong-result
   - **Scenario:** The unit dir becomes unwritable between park and fire
     (ENOSPC, permission drift — reproduced with `chmod 555 <unit-dir>`).
     `spec-resume.sh run <unit>`: lock acquired, scheduler `remove` succeeds
     (job deleted), then `write_metadata` fails (`mktemp: Permission denied`)
     and `set -e` kills the script before `release_lock`. Result: state
     `pending`, scheduler job gone, `.<unit>.lock` stale. After storage
     recovers, both `run` and `cancel` exit 1 `resume unit is busy` forever —
     reproduced end to end.
   - **Where:** `scripts/spec-resume.sh:237` (`write_metadata "$dir"` between
     the successful `remove` at `:232` and `release_lock` at `:238`); the same
     window exists in `park` at `:186-188` (metadata/argv/cwd writes while
     locked).
   - **Wrong behavior:** A recoverable storage hiccup makes the parked run
     permanently unmanageable — worse than the o2/o3 cases because the
     one-shot job is already deleted, so nothing will ever fire, and doctor's
     orphan warning is the only trace. Violates REQ-005/AC-005's recoverable
     lifecycle; the Round 3 escalation named exactly this class ("wherever it
     holds the per-unit lock").
   - **Smallest fix:** Stop hand-guarding one call site at a time: scope the
     lock with `trap 'release_lock "$unit_id"' EXIT` (cleared after normal
     release), or explicitly check every write under the lock the way the
     scheduler calls now are. Add a fixture with an unwritable unit dir
     asserting no stale lock.
   - **Root cause:** implementation-error. The plan's lock lifecycle requires
     atomic, recoverable unit operations; o1–o3 patched individual sites while
     `set -e` still escapes the acquire/release window at the remaining ones.
   - **Blocks:** REQ-005 / AC-005.

3. **Claude weekly and Opus-bucket limits with minute-less clocks still classify as `none`** — *severity:* wrong-result
   - **Scenario:** `Weekly limit reached. Your limit will reset at 8pm
     (America/New_York).` and `You've hit your Opus limit. Your limit will
     reset at 8pm.` → `usage-limit.sh classify claude <capture> --now
     1704067200` returns `none`, exit 1 (reproduced). With `8:00pm` the same
     messages classify `long`. The Round 1 concession (minute-less clocks are
     real Claude reset wording, issue 5977) was applied to the session row and
     the central extractor only.
   - **Where:** `scripts/usage-limit-patterns.tsv:4-5` — both weekly rows
     still require `[0-9]{1,2}:[0-9]{2}`, unlike the repaired session row
     (`:3`) and codex row (`:6`).
   - **Wrong behavior:** A real weekly/per-model limit message falls through
     as generic exit 6 — no park, no delegate — defeating the `long: delegate`
     policy for exactly the multi-day windows where delegation matters most.
   - **Smallest fix:** Make minutes optional (`(:[0-9]{2})?`) in rows 4-5 and
     add weekly/Opus minute-less fixtures asserting `long` through the
     dispatch policy path.
   - **Root cause:** implementation-error. The T013o1 repair broadened the
     shared clock grammar but narrowed the table edit to one provider row;
     the plan (and Round 1 finding) covered all clock rows.
   - **Blocks:** REQ-002 / AC-001, REQ-006.

Minor (non-blocking): (a) a pipe-epoch reset already in the past parks a
launchd entry whose calendar date never fires — floor `run_at` at now plus one
minute (`scripts/spec-resume.sh:162`); (b) launchd one-shot entries survive
sleep but not a powered-off night, unlike the cron backend's every-minute
epoch check — worth a line in knowledge/usage-limit-handling.md; (c) `flatten`
recognizes `on_limit:` only with nothing after the colon
(`scripts/model-policy.sh:120`), so a hand-added inline comment silently
disables the whole policy while `dispatch:` tolerates one; (d) STATUS
`active_tool` keeps the original CLI after a successful delegation.

## Held up

- Round 3 repair (cancel/remove failure): failing remove → exit 1, no stale
  lock, unit pending, job preserved; recovered cancel removes unit + job and
  records the STATUS event (independent stub repro, not just the suite test).
- Round 1/2 repairs re-ran green (session/codex minute-less fixtures through
  the park policy path; run-path remove failure releases the lock).
- Adversarial argv replay (spaces, quotes, globs, empty, newline) is
  byte-exact via NUL records; cancel-during-replay is handled
  (`scripts/spec-resume.sh:253-256`); delegate skips the limited CLI, caps at
  three attempts, and parks on exhaustion (suite).

## Escalation

Round 4 surfaces new substantive defects, so per the bounded loop the user
arbitrates. The SPEC is not the problem: all three findings are delivery
gaps against requirements the spec states clearly. Findings 1 and 2 indicate
the implementation approach around the scheduler seam and lock lifecycle needs
one structural pass (environment capture at park time; trap-scoped lock
release) rather than another per-call-site patch; finding 3 is a two-line data
edit completing an already-conceded repair. The user decides: rework via
T013o4–T013o6, or accept the residual risk with a signed waiver in STATUS.md
Decisions (noting that finding 1 means auto-resume will not work in production
as shipped).

## Follow-up tasks proposed

- T013o4 — Capture PATH (parking environment) into scheduler entries so fired
  resumes can find the provider CLIs; assert it at the seam (→ Finding 1).
- T013o5 — Make the per-unit lock release structural (trap-scoped or checked
  writes) so no failure between acquire and release strands a unit; cover the
  unwritable-unit-dir case (→ Finding 2).
- T013o6 — Allow minute-less clocks in the weekly and model-weekly pattern
  rows with fixtures through the dispatch policy path (→ Finding 3).
