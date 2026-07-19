---
spec_id: 002-usage-limit-handling-for-dispatched-runs
title: Usage limit handling for dispatched runs
status: accepted
created: 2026-07-19
updated: 2026-07-19
owners: [Rehan712]
project: sdd-kit-public
---

# Usage limit handling for dispatched runs

> On individual (non-enterprise) accounts, every provider the kit dispatches to
> enforces stacked usage windows — Claude Code a rolling 5-hour session cap plus
> weekly caps, Codex 5-hour plus weekly credit windows, Copilot a monthly
> premium-request allowance plus burst rate limits. Today a limit-hit dispatched
> run dies as a generic exit-6 failure, killing unattended runs even though SDD
> state is fully resumable from disk. This spec teaches the dispatch seam to
> **classify** limit failures, then — per a machine-local policy — **park** the
> run and auto-resume it when the window resets, or **delegate** it to the next
> configured CLI. Gates and interactive phases are structurally out of reach of
> this machinery and keep their tier by design.

## 1. Problem

`spec-dispatch.sh` treats every non-zero exit from the target CLI identically:
`✗ $CLI exited $rc — inspect $CAP` and exit 6. A usage-limit failure is the one
failure class that (a) is *guaranteed transient* with a knowable horizon, and
(b) hits precisely the unattended runs (overnight `implement --all` slices)
where nobody is around to read the capture. The kit's own architecture makes
these runs cheap to resume — tasks.md checkboxes, STATUS.md, and worktrees mean
a rerun continues from where it stopped — but nothing detects the limit,
records the reset horizon, or reruns the command.

Concrete example: `spec-dispatch.sh implement <spec> --all` routed to Codex at
23:00 hits "You've hit your usage limit. …try again at 2:30 AM" after task
T004. The run exits 6, T005–T012 never execute, and the user discovers a dead
red capture in the morning — six hours after the window reset.

**REQ-001:** A dispatched run that fails because a provider usage limit was hit
must be recognized as such and, per configured policy, automatically resumed at
the reset horizon or re-dispatched to a fallback CLI — never left as a generic
dead failure the user discovers hours later.

## 2. Goals

- **REQ-002 (classify):** A deterministic classifier over the run's captured
  output recognizes usage-limit failures for all three CLIs and classifies the
  window kind — `short` (rolling session/burst: Claude 5-hour, Codex 5-hour,
  Copilot burst rate-limit) or `long` (Claude weekly and per-model weekly caps,
  Codex weekly, Copilot monthly premium allowance) — extracting the reset
  moment when the message carries one (`Claude AI usage limit reached|<epoch>`,
  "resets 3:45pm", "try again at <time>"). The pattern table lives in exactly
  one place, and adding a new provider phrasing is a data edit, not new logic.
  Output that merely *mentions* limits while failing for another reason must
  not classify (fixture-proven against ordinary failures).
- **REQ-003 (capture parity):** The classifier's input exists for every CLI:
  the Codex dispatch branch, which today runs `codex exec` without teeing into
  `$CAP`, captures run output the same way the claude/copilot branches do.
- **REQ-004 (policy):** models.yml (machine-local, gitignored) gains an
  optional `on_limit:` block — per-kind action `park | delegate | fail`, a
  `fallback:` CLI order for delegate, and a `backoff_minutes:` default for
  unparseable resets — parsed, validated, and editable via `model-policy.sh`
  (`check`, a getter, `set`/`unset`). **No `on_limit:` block → no automatic
  action**: the run still classifies, reports kind + reset, prints the exact
  park and `--to` commands to continue manually, and exits with a
  limit-specific code distinct from generic failure (6).
- **REQ-005 (park):** A new `scripts/spec-resume.sh` parks a command: it
  persists a machine-local resume unit holding the *verbatim* original argv,
  registers a one-shot scheduler entry (launchd on darwin, cron elsewhere) at
  reset-plus-jitter — or now-plus-backoff when no reset was parsed — and on
  firing re-executes the argv exactly. Success removes the unit and scheduler
  entry; a repeat limit re-parks at the new horizon under a bounded retry cap
  (never an unbounded retry loop). Units are listable and cancellable
  (`list`/`cancel`). Park and resume events are recorded in the spec's
  STATUS.md through `spec-status.sh`, not hand-edits.
- **REQ-006 (delegate):** On a `long`-kind limit with `delegate` policy,
  `spec-dispatch.sh` retries the same role/spec against the next CLI in
  `fallback:` order that is installed, authenticated, and adapter-ready —
  skipping the CLI that just hit its limit — through the same dispatch path
  and the same deterministic artifact verification. Fallbacks exhausted →
  park per REQ-005. The failover is recorded in STATUS.md's decisions log.
- **REQ-007 (doctor):** `sdd-doctor.sh` validates the `on_limit:` block, warns
  when a configured fallback CLI is missing/unauthenticated or its adapters
  are absent, and surfaces pending parked units plus orphaned scheduler
  entries (unit without job, job without unit).
- **REQ-008 (docs):** README gains a "when a provider hits its usage limit"
  section; models.example.yml documents the `on_limit:` block (commented out,
  like `dispatch:`); a new `knowledge/usage-limit-handling.md` records the
  empirical message formats with provenance and the drift caveat, and the
  manual recipe for interactive (non-dispatched) sessions.

## 3. Non-goals

- **Interactive-session limits.** When the CLI the user is typing in hits its
  limit, the turn dies before any in-band handling can run — only the manual
  recipe (REQ-008) covers it. Automatic top-level wrapping is a future spec.
- **Preflight quota estimation** (stop-at-a-clean-boundary before starting a
  batch). Per-task granularity already bounds mid-task loss; polish later.
- **Tier-down on per-model caps.** Claude's "You've hit your Opus limit"
  names a bucket the classifier MAY record, but acting on it means restamping
  models mid-run (`apply-models.sh`) — out of scope; delegate/park cover it.
- **Pay-per-token API fallback** (subscription exhausted → `ANTHROPIC_API_KEY`
  billing). Deliberate spend decision; a future opt-in spec.
- **Multi-account rotation** — ToS problem, never.
- **Gate or review behavior changes.** Gates and `/sdd:review` are not
  dispatchable and never execute inside dispatched runs; nothing here may
  downgrade, delegate, or park a gate. This spec touches only the four
  dispatchable roles (plan, tasks, implement, retro).
- Porting to the private kit repo (port follows the public merge, as always).

## 4. Success metrics

- **MET-001:** The next real usage-limit event during a dispatched run ends
  with an automatic resume or a successful delegation (STATUS.md decisions log
  records the event) instead of a dead exit-6 capture — checked at that spec's
  retro. Otherwise n/a: internal tooling with no runtime telemetry.
- **MET-002:** Zero false-positive limit classifications across the
  ordinary-failure fixture corpus — enforced permanently by
  `tests/run.sh limits`.

## 5. User stories

### As a kit user running overnight dispatched slices on individual-plan accounts

- I can start `spec-dispatch.sh implement <spec> --all` before bed and find
  the tasks finished in the morning: the Codex 5-hour limit at 2am parked the
  run and the scheduler resumed it at the reset.
- I can configure `long: delegate` with `fallback: [claude, copilot]` so a
  weekly cap doesn't stall a spec for days — the same slice re-dispatches to
  the next provider, and the same `sdd-analyze`/`spec-evidence` checks verify
  the artifacts regardless of who wrote them.
- With no `on_limit:` configured, nothing schedules anything behind my back —
  I get a clear classification and the exact commands to continue by hand.
- I can `spec-resume.sh list` to see what's parked and `cancel` anything I'd
  rather run differently.

### As the kit maintainer

- I can add a new provider phrasing to the pattern table as a one-line data
  edit when a CLI update changes its limit message.
- `sdd-doctor.sh` tells me when my fallback chain is wishful thinking (CLI
  missing, adapters not built) before a 2am failover discovers it for me.

## 6. Acceptance criteria

- [ ] **AC-001:** Classifier fixtures for all three CLIs classify correctly:
  Claude pipe-epoch (`Claude AI usage limit reached|1749924000`) and current
  "You've hit your session limit · resets 3:45pm" → `short`; Claude weekly and
  Opus-bucket phrasings → `long`; Codex "You've hit your usage limit …try
  again at <time>" → kind per message horizon; Copilot "exceeded your premium
  request allowance" / "exhausted your premium model quota" → `long`; Copilot
  burst rate-limit → `short`. At least four ordinary-failure fixtures (auth
  error, network error, test failure, generic crash — including one that
  *mentions* the word "limit") classify as no-limit (proves REQ-002, MET-002)
  — `tests/run.sh limits`.
- [ ] **AC-002:** Reset extraction: pipe-epoch → that exact epoch; "resets
  <clock time>" / "try again at <time>" → a future timestamp; unparseable →
  empty, and the caller applies `backoff_minutes` (proves REQ-002) —
  `tests/run.sh limits`.
- [ ] **AC-003:** Dispatch with no `on_limit:` block, on a limit-classified
  failure: exits with the new limit-specific code, prints kind, reset horizon,
  and copy-pasteable park/`--to` commands, and registers nothing (scheduler
  stub asserts zero invocations) (proves REQ-004) — `tests/run.sh limits`.
- [ ] **AC-004:** Dispatch with `short: park`: writes a resume unit holding
  the verbatim original argv, registers exactly one scheduler entry at the
  parsed reset (or now+backoff when unparseable), and records the park in
  STATUS.md via `spec-status.sh` (proves REQ-005) — `tests/run.sh limits`.
- [ ] **AC-005:** `spec-resume.sh run` re-executes the stored argv verbatim
  (stub records the invocation); success removes unit + scheduler entry; a
  repeat limit re-parks at the new horizon; the retry cap halts re-parking
  with a nonzero exit and the unit marked failed; `list` shows pending units
  and `cancel` removes unit + entry (proves REQ-005) — `tests/run.sh limits`.
- [ ] **AC-006:** Dispatch with `long: delegate`, `fallback: [x, y]`: the
  first installed+adapter-ready fallback is re-dispatched through the same
  path with verification unchanged; the limited CLI is skipped even if
  listed; all fallbacks unavailable → parks per REQ-005; the failover lands
  in STATUS.md's decisions log (proves REQ-006) — `tests/run.sh limits`.
- [ ] **AC-007:** The Codex dispatch branch's output is captured to `$CAP`
  like the other CLIs, and a limit message in a Codex run classifies (proves
  REQ-003) — `tests/run.sh limits`.
- [ ] **AC-008:** `model-policy.sh check` accepts a valid `on_limit:` block;
  rejects an unknown action, an unknown fallback CLI, and a non-numeric
  backoff with a message naming the offender; the getter returns configured
  values and defaults; `set`/`unset` round-trip (proves REQ-004) —
  `tests/run.sh model-policy`.
- [ ] **AC-009:** `sdd-doctor.sh` flags an invalid `on_limit:` block, a
  fallback CLI that is missing or lacks adapters, a pending parked unit, and
  an orphaned scheduler entry (fixture-driven) (proves REQ-007) —
  `tests/run.sh limits` (or a new doctor suite).
- [ ] **AC-010:** README section, models.example.yml `on_limit:` example, and
  `knowledge/usage-limit-handling.md` (message provenance + drift caveat +
  manual interactive recipe) all exist and name the same policy keys the
  parser accepts (proves REQ-008) — grep-verified.
- [ ] **AC-011:** All new/changed scripts pass `shellcheck -S warning`, carry
  the executable bit, and the full suite is green — `tests/run.sh`.

## 7. Constraints

- **CON-001:** bash 3.2 + BSD userland only (the kit's floor); zero new
  dependencies. Scheduling uses what the OS ships: `launchctl` on darwin,
  `crontab` elsewhere; both behind one seam so tests stub it with an env
  override, never touching the real scheduler.
- **CON-002:** No side effects without opt-in: absent `on_limit:`, nothing is
  ever scheduled or delegated automatically. Every parked unit is inspectable
  and cancellable.
- **CON-003:** Resume never widens trust: running the dispatch WAS the
  approval for that one headless run (existing trust model); the resumed
  command must be byte-identical to it — a resume unit is a replay, never a
  new grant.
- **CON-004:** Misclassification safety: unknown-kind or unparseable-reset
  limits get bounded backoff with a retry cap — never a hot loop against a
  capped account, never an infinite park chain.
- **CON-005:** The two kit repos stay byte-identical on kit files (port
  follows the public merge, as with prior PRs).

## 8. Open questions

(none — resume-unit storage location, scheduler-seam shape, and the exact
pattern table are plan-phase decisions; message formats are grounded in the
references below and encoded as fixtures)

## 9. References

- Claude pipe-epoch headless format: https://github.com/anthropics/claude-code/issues/2087
- Claude reset phrasing ("Your limit will reset at 2pm (America/New_York)"): https://github.com/anthropics/claude-code/issues/5977
- Claude session/weekly/Opus window phrasing: https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work
- Codex "You've hit your usage limit …try again at": https://github.com/openai/codex/issues/12299, https://github.com/openai/codex/issues/30041
- Copilot premium allowance messages: https://github.com/orgs/community/discussions/165869, https://github.com/orgs/community/discussions/167237, https://docs.github.com/en/copilot/concepts/usage-limits
- Origin: session 2026-07-19 design discussion (park > delegate ranking;
  detection must live in the wrapper because a limited session's turn dies
  before the model can act)

---

*Workflow:* Once this spec is accepted, run `/sdd:plan` to produce `plan.md` in this same directory.
