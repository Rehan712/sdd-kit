---
plan_for: 002-usage-limit-handling-for-dispatched-runs
status: accepted  # draft | accepted | implementing | shipped
created: 2026-07-19
updated: 2026-07-19
stacks: []
---

# Plan: Usage limit handling for dispatched runs

> The implementation strategy for `spec.md`. Answers **how**, not what.

## 1. Approach

Keep usage-limit handling at the existing dispatch boundary (REQ-001): capture
every provider's combined output, classify a failed attempt through one
provider-scoped data table, and let an explicit `on_limit:` policy choose
`park`, `delegate`, or `fail` (REQ-002–REQ-004). Parking persists the original
dispatcher argv losslessly and schedules the same command under a bounded retry
unit (REQ-005); delegation loops through ready providers but returns to the
unchanged artifact verifier after the first successful attempt (REQ-006).
Doctor checks, deterministic fixtures, and provenance docs make policy drift,
provider-message drift, and scheduler orphans visible (REQ-007–REQ-008).

## 2. Architecture

| File | Change | Why / requirement | Pattern anchor |
|---|---|---|---|
| `scripts/usage-limit-patterns.tsv` | new | The only provider-message pattern table: detector id, CLI, kind rule, reset rule, POSIX ERE (REQ-002) | no precedent — tracked, commentable TSV data; matching logic does not live here |
| `scripts/usage-limit.sh` | new | Deterministic `classify` command; normalizes capture text, matches the table, extracts reset epochs, and emits one TSV verdict (REQ-002, AC-001/002) | `scripts/brief-status.sh`: Bash-3.2 CLI, deterministic TSV verdicts, explicit usage exits |
| `scripts/spec-dispatch-ready.sh` | new | One installed/authenticated/adapter-ready probe shared by initial dispatch, fallback selection, and doctor (REQ-006/007) | the checks currently inline in `scripts/spec-dispatch.sh`; `scripts/brief-status.sh` for a query-only CLI contract |
| `scripts/spec-dispatch.sh` | modified | Preserve original argv before parsing; tee Codex like the other CLIs; classify only nonzero attempts; apply policy; loop over fallbacks; park; retain current artifact verification (REQ-001, REQ-003–REQ-006) | extend the existing target resolution, command construction, run, and verify sections in place |
| `scripts/model-policy.sh` | modified | Parse, query, validate, canonically emit, set, and unset `on_limit:` without creating a second policy parser (REQ-004) | its existing `dispatch:` flatten → validate → emit → atomic-write pipeline |
| `scripts/configure-models.sh` | modified | Preserve `on_limit:` when the wizard rewrites `models.yml`; today it carries only `dispatch:` (REQ-004) | its `DISPATCH_ROWS` carry-forward block in place |
| `scripts/spec-resume-scheduler.sh` | new | Single `add/remove/list` scheduler seam: launchd on Darwin, crontab elsewhere; replaceable by env in tests (REQ-005, CON-001) | `scripts/spec-worktree.sh`: idempotent create/reuse/remove lifecycle; no scheduler precedent exists |
| `scripts/spec-resume.sh` | new | Persist, list, cancel, and run bounded resume units with lossless argv replay and STATUS events (REQ-005) | `scripts/spec-worktree.sh` for state lifecycle and guards; `scripts/spec-run.sh` for captured command execution; no lossless-argv precedent exists |
| `scripts/spec-status.sh` | modified | Add the deterministic decision/event append API required by park, resume, and delegation (REQ-005/006) | existing `get/set/show` CLI and `templates/status-template.md` Decisions format |
| `scripts/sdd-doctor.sh` | modified | Check policy, fallback readiness, pending/failed units, and unit/job orphans even when `models.yml` is absent (REQ-007) | `check_model_policy()` plus the existing warning/error aggregators |
| `tests/fixtures/usage-limits/**` | new | Provenance-backed provider captures and at least four ordinary failures; no synthetic provider phrasing (REQ-002, MET-002) | no fixture-directory precedent — immutable text inputs named by CLI and detector id |
| `tests/test-usage-limits.sh` | new | Classifier, capture, dispatch-policy, fallback, resume, scheduler-stub, retry-cap, and doctor scenarios (AC-001–AC-007, AC-009) | `tests/test-spec-dispatch.sh` plus `tests/helpers.sh` fresh-sandbox/stub conventions |
| `tests/test-model-policy.sh` | modified | `on_limit:` check/get/default/set/unset and invalid-input matrix (AC-008) | existing `--file` sandbox policy tests |
| `tests/test-spec-status.sh` | new | Decision append placement, date prefix, and `updated:` bump | `tests/test-spec-task.sh` mutation assertions |
| `README.md`, `models.example.yml`, `knowledge/usage-limit-handling.md` | modified/new | User policy, recovery, empirical message provenance, drift caveat, and interactive recipe (REQ-008, AC-010) | README Cross-CLI dispatch section; commented `dispatch:` example; `knowledge/cli-subagent-delegation.md` provenance style |

No gate, review, adapter-generation, or worktree routing code changes. The
role allow-list in `spec-dispatch.sh` remains exactly `plan|tasks|implement|retro`
(REQ-001, spec non-goal).

### Dispatch flow

```text
original argv + cwd captured before parsing
        |
        v
resolve CLI -> readiness probe -> run + tee aggregate capture
        | success                         | nonzero
        v                                 v
unchanged artifact verifier      classify this attempt only
                                          | no match -> existing exit 6
                                          | match -> exit class 7 path
                                          v
                               on_limit block present?
                                 | no / action=fail -> print manual commands
                                 | action=park -> persist/schedule same argv
                                 | action=delegate -> next ready, untried fallback
                                                        | exhausted -> park
                                                        `-> run through same loop
```

The aggregate capture is initialized once and gets a header for every attempted
CLI. Each attempt also tees to a temporary slice used by the classifier, so an
earlier limit message cannot cause a later ordinary failure to be misclassified.
The Codex command drops `--output-last-message "$CAP"`; all three providers use
the same `2>&1 | tee -a "$CAP"` path under `pipefail` (REQ-003, AC-007).

## 3. Data model

### `models.yml` policy

```yaml
on_limit:
  short: park
  long: delegate
  fallback: [claude, copilot]
  backoff_minutes: 60
```

- Block absence is a separate state and means **no automatic action**
  (REQ-004, CON-002). An empty but present block is opt-in.
- Present-block defaults are `short=park`, `long=delegate`, `fallback=[]`, and
  `backoff_minutes=60`. An empty fallback makes `delegate` exhaust immediately
  and safely fall back to parking, matching the settled park-first decision.
- `short` and `long` each accept exactly `park|delegate|fail`; the generic
  dispatch loop supports all declared actions even though REQ-006 exercises
  long-window delegation.
- `fallback` is an ordered, duplicate-free list containing only
  `claude|codex|copilot`; the limited/already-attempted CLI is always skipped.
- `backoff_minutes` is a base-10 integer from 1 through 10080. The parser must
  normalize leading zeros only after the digit-shape guard.
- Flattened policy rows gain `limit\t__present\t1` plus one `limit` row per
  configured key. Canonical emission preserves section order and inline-list
  fallback order. `configure-models.sh` reads these getters before truncating
  its source and writes the block back unchanged.

### Pattern table and classifier result

`scripts/usage-limit-patterns.tsv` columns are:

`detector_id<TAB>cli<TAB>kind_rule<TAB>reset_rule<TAB>lowercase_posix_ere`

`kind_rule` is `short`, `long`, or `horizon`; `reset_rule` is
`pipe_epoch`, `clock`, `datetime`, `relative`, or `none`. The initial rows are:

| Detector id | CLI | Kind rule | Reset rule | Required hard-failure phrase family |
|---|---|---|---|---|
| `claude-pipe-epoch` | claude | short | pipe_epoch | `Claude AI usage limit reached|<epoch>` |
| `claude-session-clock` | claude | short | clock | `Session limit reached` or `You've hit your [session] limit` plus `resets` |
| `claude-weekly-clock` | claude | long | clock/datetime | `Weekly limit reached` / `weekly limit` plus `resets` |
| `claude-model-weekly` | claude | long | clock/datetime | Opus/Sonnet bucket plus hard `limit reached`/`hit ... limit` phrasing |
| `codex-usage-horizon` | codex | horizon | datetime | `You've hit your usage limit` plus `try again at` |
| `copilot-premium-allowance` | copilot | long | none | `exceeded your premium request allowance` |
| `copilot-premium-quota` | copilot | long | none | `exhausted your premium model quota` |
| `copilot-rate-horizon` | copilot | horizon | relative | `hit a ... rate limit` plus `try again in <duration>` |
| `copilot-model-rate` | copilot | short | none | `exhausted this model's rate limit` |

The implementation stores the actual escaped EREs only in the TSV. It strips
ANSI/CR, folds case, and joins wrapped lines before matching. Callers invoke the
classifier only after a nonzero provider exit; matching the generic words
`limit`, `429`, or `Too Many Requests` alone is forbidden (REQ-002, MET-002).

Classifier output is one TSV record:

`limit<TAB><short|long|unknown><TAB><reset_epoch-or-empty><TAB><detector_id>`

No match prints `none` and exits 1; a match exits 0; malformed invocation/input
exits 2. `horizon` is short when a parsed reset is at most 6 hours from injected
`now`, long when later, and unknown when no reset is parseable. Explicit
weekly/monthly detector rows take precedence over horizon inference.

Reset parsing is centralized and runs with `LC_ALL=C`: pipe epochs are copied
exactly; relative durations add to `now`; clock-only values have seconds set to
zero and advance one local day when not future; full dates strip ordinal
suffixes before parsing. Darwin uses `date -j -f`, GNU uses `date -d`. Tests set
`TZ=UTC` and pass `--now <epoch>`; invalid/past full dates return an empty reset
so the caller uses backoff (REQ-002, CON-004).

### Resume unit

State root:

`${SDD_RESUME_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/sdd-kit/resume}`

Every command has deterministic id `sha256(cwd NUL argv...)` (using the same
`shasum`/`sha256sum` portability branch as `spec-run.sh`) and directory
`<root>/<id>/`, created under `umask 077`:

| File | Contents |
|---|---|
| `argv.nul` | every original argv element followed by NUL; never shell source text |
| `cwd.nul` | original working directory followed by NUL |
| `unit.tsv` | `state`, `live_spec`, `role`, `kind`, `reset_epoch`, `run_at_epoch`, `retry_count`, `max_retries`, `last_exit`, `created_at`, `updated_at` |

`state` is `pending|running|failed`. The fixed retry cap is 3 scheduler-fired
attempts after the initial dispatch. `retry_count` increments immediately before
each replay; a limit on attempt 3 marks the unit failed and registers no new
job. Run time is parsed reset or `now + backoff_minutes`, plus deterministic
0–300 second jitter derived from the unit id; `SDD_RESUME_JITTER_SECONDS=0`
makes fixtures exact. Scheduler minute fields round up, never down (AC-004,
AC-005).

NUL is the only byte an OS argv cannot contain, so Bash 3.2
`read -r -d ''` can reconstruct the array without `eval`, `source`, word
splitting, or normalized quoting (CON-003). A per-unit atomic `mkdir` lock
prevents concurrent `run`, `park`, or `cancel` mutations; metadata rewrites use
temp-file + `mv`.

At `run`, remove the firing scheduler entry first, mark the unit running, `cd`
to the stored cwd, then execute the reconstructed array. Exit 0 records resume
success and removes the unit. Generic nonzero marks failed. Exit 7 leaves the
unit only when the nested dispatcher changed the same deterministic unit back
to pending; otherwise it marks failed. This makes the nested dispatcher, not a
second runner, the sole owner of a repeat-limit re-park and retry-cap decision.

## 4. API / contracts

No network API, database, event bus, or client SDK changes.

### Public CLI changes

- `scripts/spec-dispatch.sh` adds exit **7 = provider usage limit classified**.
  Existing exits 0–6 keep their meanings. A successful fallback still exits 0
  only after existing role-specific artifact verification (REQ-004/006).
- On exit 7 with no block or `fail`, output includes CLI, kind, reset (or
  `unknown`), one shell-escaped `spec-resume.sh park ... -- <original argv>`
  command, and shell-escaped `spec-dispatch.sh ... --to <other-cli>` commands.
  It must not invoke the scheduler/readiness fallback path (AC-003).
- `scripts/usage-limit.sh classify <cli> <capture> [--now <epoch>]` implements
  the classifier contract above.
- `scripts/spec-dispatch-ready.sh <cli> <role>` exits 0 only when the binary,
  role adapter, and authentication probe pass; exit 1 prints a concise reason;
  exit 2 is bad usage. Adapter paths are:
  `~/.claude/skills/sdd-<role>/SKILL.md`,
  `~/.codex/skills/sdd-<role>/SKILL.md`, and
  `~/.copilot/agents/sdd-<role>.agent.md`.
- Authentication probes are `claude auth status`, `codex login status`, and
  the Copilot CLI's read-only `/user show` through prompt mode with updates,
  tools, and color disabled. `SDD_DISPATCH_AUTH_CHECKER=<executable>` replaces
  only this auth step in fixtures. A probe that cannot prove readiness is
  unavailable; fallback never spends a model turn merely to test auth.
- `scripts/spec-resume.sh park --spec <live-spec> --role <role> --kind
  <kind> [--reset <epoch>] [--backoff-minutes <n>] -- <original argv...>`;
  `run <unit-id>`; `list [--tsv]`; `cancel <unit-id>`.
- `scripts/spec-resume-scheduler.sh add <unit-id> <run-at-epoch> <state-root>`;
  `remove <unit-id>`; `list` (unit ids, one per line). `spec-resume.sh` calls
  `${SDD_RESUME_SCHEDULER:-$HUB_DIR/scripts/spec-resume-scheduler.sh}` with
  that interface, and rejects a non-executable override.
- `model-policy.sh limit present|short|long|fallback|backoff_minutes` is the
  getter. `present` prints `true|false`; other keys return configured values or
  the present-block defaults. Editing is
  `set on_limit <key> <value>` (fallback value is ordered comma-separated CLIs)
  and `unset on_limit [<key>]` (no key removes the entire block).
- `spec-status.sh append-decision <spec-dir> <text>` inserts
  `- <YYYY-MM-DD> — <text>` at the end of `## Decisions log`, before the next
  `##` heading, and bumps frontmatter `updated:`. It rejects missing/multiple
  Decisions sections rather than writing elsewhere.

### Internal seams (pre-decided)

- `spec-dispatch.sh` snapshots `ORIGINAL_CWD=$PWD` and
  `ORIGINAL_ARGV=("$0" "$@")` before its argument loop. It never reconstructs
  original arguments from parsed flags.
- `run_attempt <cli> <attempt-number>` builds that CLI's command, appends a
  provider header to the aggregate capture, tees to aggregate + temporary
  attempt slice, and returns the provider's true status under `pipefail`.
- `select_fallback <role> <attempted-clis>` reads `model-policy.sh limit
  fallback` in order and returns the first CLI for which
  `spec-dispatch-ready.sh` succeeds; skipped reasons are appended to capture.
- A fallback is added to `attempted-clis` before execution. The current CLI is
  skipped even if repeated in policy. The loop has at most three provider
  attempts and cannot recurse (AC-006).
- Every classified attempt re-reads `limit present`, then the action for that
  attempt's kind. `unknown` never delegates: a present block parks using
  backoff; an absent block reports/manual-exits. `delegate` exhaustion parks.
- Park, retry, resume-success/failure/cancel, and provider failover call only
  `spec-status.sh append-decision`; event text includes unit id or from/to CLI,
  role, kind, and reset/run-at epoch, but never prompt/output content.
- Launchd job label/file is `com.sdd-kit.resume.<id>` under
  `~/Library/LaunchAgents/`; it invokes `~/.sdd/scripts/spec-resume.sh run <id>`
  with `SDD_RESUME_ROOT` preserved. Cron entries carry marker
  `# sdd-kit-resume:<id>` and run every minute behind an epoch-due predicate,
  so a sleeping/offline host runs at the first minute after it returns. The
  runner removes the entry before replay, making both backends one-shot.
- Doctor compares pending unit ids from `spec-resume.sh list --tsv` with job ids
  from the scheduler `list`: pending units are always surfaced; pending unit
  without job and job without unit are orphan warnings; failed units are
  surfaced but do not require a job. This check sits outside the
  `models.yml`-present branch.

## 5. Dependencies

- No new packages, services, network APIs, AWS resources, or IAM actions
  (CON-001).
- Runtime commands remain Bash 3.2 plus OS/POSIX tools already required by the
  kit. New OS integrations are `launchctl` on Darwin and `crontab` elsewhere;
  SHA-256 uses the existing `shasum`/`sha256sum` compatibility branch.
- Tests use only existing `tests/helpers.sh` stubs and temp sandboxes. They set
  `HOME`, `SDD_RESUME_ROOT`, `SDD_RESUME_SCHEDULER`,
  `SDD_DISPATCH_AUTH_CHECKER`, `SDD_RESUME_JITTER_SECONDS=0`, and `TZ=UTC`, so
  no real credential store, scheduler, or user state is touched.

## 6. Stack overlay notes

- n/a — `.specify/stack.yml` declares `stacks: []`, and no project-local
  constitution exists. The applicable implementation constraints are the
  global constitution plus CON-001: Bash 3.2/BSD portability, deterministic
  mutation scripts, behavioral tests named with AC ids, and zero dependencies.
- CI already enforces `shellcheck -S warning -x scripts/*.sh tests/*.sh`, Linux,
  macOS, and an explicit `/bin/bash` 3.2 run. The plan was grounded against a
  green baseline of 10 suites / 70 tests on 2026-07-19.

## 7. Risks

- **R1 — high likelihood × high impact: provider wording drifts or a transcript
  mentions limits and falsely parks.** *Mitigation:* provider + nonzero scoping,
  exact hard-failure EREs in one table, per-attempt slices, four ordinary-error
  fixtures including a `limit` mention, and provenance/drift documentation
  (REQ-002, MET-002).
- **R2 — medium likelihood × high impact: argv replay changes quoting, cwd, or
  trust scope.** *Mitigation:* snapshot before parsing; NUL files under `umask
  077`; array replay without eval/source; deterministic id includes cwd; fixture
  arguments include spaces, quotes, glob characters, empty args, and newlines
  (REQ-005, CON-003).
- **R3 — medium likelihood × high impact: reset parsing is wrong across BSD/GNU
  date, midnight, timezone, or DST.** *Mitigation:* one parser, `LC_ALL=C`,
  injected now/TZ, future-only checks, clock next-day normalization, and safe
  backoff on any parse failure (AC-002, CON-004).
- **R4 — medium likelihood × high impact: duplicate jobs or repeat limits form a
  hot loop.** *Mitigation:* deterministic unit id, atomic per-unit lock,
  remove-before-run scheduler lifecycle, fixed three-attempt cap, persistent
  states, and positive backoff minimum (REQ-005, CON-004).
- **R5 — medium likelihood × medium impact: a fallback binary exists but cannot
  authenticate or lacks its role adapter.** *Mitigation:* one readiness command
  used by dispatch and doctor; conservative failure on unprovable auth; ordered
  skip reasons captured; exhaustion parks (REQ-006/007).
- **R6 — medium likelihood × medium impact: scheduler entries become orphaned or
  a host misses the exact minute.** *Mitigation:* marked idempotent entries,
  cron's every-minute due predicate, launchd calendar unit retained until run,
  and bidirectional doctor reconciliation (REQ-005/007).
- **R7 — low likelihood × medium impact: generic Codex/Copilot horizon is near
  reset and cannot identify the underlying bucket.** *Mitigation:* explicit
  weekly/monthly phrases win; generic horizons use the documented 6-hour split;
  unknowns park/back off and never delegate automatically (REQ-002, CON-004).
- **R8 — low likelihood × medium impact: adding fallback attempts truncates or
  contaminates capture/audit output.** *Mitigation:* initialize aggregate once,
  append attempt headers, classify temporary slices, and retain the unchanged
  verifier after success (REQ-003/006).

## 8. Rollout

- **Deploy order:** land classifier/pattern fixtures and policy/status/readiness
  seams first; then resume/scheduler; then dispatch integration; finally doctor
  and docs. All ship in one PR, but that dependency order keeps tasks and
  commits independently verifiable.
- **Activation:** no feature flag. `on_limit:` absence is the default-off kill
  switch (CON-002). The commented example does not enable behavior.
- **Reversibility:** remove `on_limit:` to stop future automatic actions; run
  `spec-resume.sh list` then `cancel <id>` for existing units. Tracked code can
  be reverted without migrating unit data; unknown units remain inspectable.
- **Observability:** STATUS decision entries are the intentional event trail;
  captures remain under each spec's `notes/`. No dashboard/metric service is
  added for local tooling.
- **MET-001:** at the next real classified event, the affected spec's retro
  checks for `park -> resume success` or `provider A -> provider B` STATUS
  entries and confirms there was no terminal generic exit-6 path.
- **MET-002:** permanent gate is `tests/run.sh limits`, with the four ordinary
  failures required to remain `none`.
- **Release checks:** `tests/run.sh limits`, `tests/run.sh model-policy`, full
  `tests/run.sh`, `shellcheck -S warning -x scripts/*.sh tests/*.sh`, executable
  bit test, and `sync.sh --check`/doctor as applicable (AC-011).
- **Private repo:** no task edits the private kit. After the public PR merges,
  the existing port process copies kit files byte-identically (CON-005).

## 9. Out of scope (deferred)

- Automatic wrapping/recovery for the interactive CLI session; docs provide the
  manual recipe only (REQ-008).
- Quota preflight/estimation or stopping a batch before a likely cap.
- Model-tier restamping when a per-model bucket is exhausted.
- Pay-per-token API fallback or any automatic spending decision.
- Multi-account rotation.
- Gate/review dispatch, delegation, parking, or tier changes.
- Porting the implementation to the private kit before the public merge.

## 10. References

- Related code: `scripts/spec-dispatch.sh`, `scripts/model-policy.sh`,
  `scripts/configure-models.sh`, `scripts/spec-status.sh`,
  `scripts/sdd-doctor.sh`, `scripts/spec-run.sh`, `scripts/spec-worktree.sh`,
  `tests/helpers.sh`, `.github/workflows/ci.yml`.
- Internal guidance: `constitution.md` §§8, 10;
  `knowledge/deterministic-gates.md`; `templates/status-template.md`.
- Claude message evidence:
  https://github.com/anthropics/claude-code/issues/2087,
  https://github.com/anthropics/claude-code/issues/5977,
  https://github.com/anthropics/claude-code/issues/8926,
  https://github.com/anthropics/claude-code/issues/12487.
- Codex message evidence:
  https://github.com/openai/codex/issues/12299,
  https://github.com/openai/codex/issues/30041.
- Copilot message/auth evidence:
  https://github.com/orgs/community/discussions/165869,
  https://github.com/orgs/community/discussions/167237,
  https://github.com/orgs/community/discussions/189990,
  https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/authenticate-copilot-cli.
- ADRs: none — the machine-local policy and scheduler integration are opt-in and
  reversible; the plan records the seams and defaults.

---

*Workflow:* Accepted automatically under `/sdd:go`; next run `/sdd:tasks` to
produce the dependency-ordered checklist.
