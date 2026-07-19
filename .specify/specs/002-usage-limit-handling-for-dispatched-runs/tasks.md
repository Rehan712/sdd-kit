---
tasks_for: 002-usage-limit-handling-for-dispatched-runs
status: accepted
created: 2026-07-19
updated: 2026-07-19
---

# Tasks: Usage limit handling for dispatched runs

> Dependency-ordered checklist. Each task is small enough to be a single commit
> and has an explicit acceptance check.

## Setup

- [ ] **T001** [hard] — Build deterministic provider limit classifier
  - *Files:* `scripts/usage-limit-patterns.tsv` (new), `scripts/usage-limit.sh` (new), `tests/fixtures/usage-limits/` (new), `tests/test-usage-limits.sh` (new)
  - *Acceptance:* tests named AC-001 and AC-002 prove all planned Claude, Codex, and Copilot hard-failure fixtures classify with the correct kind/reset, the four ordinary-failure fixtures return `none`, and Bash 3.2/BSD-compatible parsing uses only the single TSV pattern table
  - *Verify:* `tests/run.sh limits` → `"== test-usage-limits.sh"` and exit 0
  - *Refs:* REQ-001, REQ-002, AC-001, AC-002, MET-002, plan §2 Architecture and Dispatch flow, plan §3 Pattern table and classifier result, plan R1/R3/R7

## Domain and policy

- [ ] **T002** [P] — Extend model policy with limit actions
  - *Files:* `scripts/model-policy.sh`, `scripts/configure-models.sh`, `tests/test-model-policy.sh`
  - *Acceptance:* tests named AC-008 prove absent-versus-present defaults, valid getters, canonical `set`/`unset` round-trips, ordered fallback preservation through the wizard, and rejection of invalid actions, CLIs, duplicates, and backoff values
  - *Verify:* `tests/run.sh model-policy` → `"== test-model-policy.sh"` and exit 0
  - *Refs:* REQ-004, AC-008, CON-002, plan §2 Architecture, plan §3 `models.yml` policy, plan §4 Public CLI changes

- [ ] **T003** [P] — Append STATUS decisions through validated API
  - *Files:* `scripts/spec-status.sh`, `tests/test-spec-status.sh` (new)
  - *Acceptance:* the focused suite proves `append-decision` inserts one dated entry at the end of the unique Decisions log, bumps `updated:`, and refuses missing or duplicate sections without corrupting STATUS.md
  - *Verify:* `tests/run.sh spec-status` → `"== test-spec-status.sh"` and exit 0
  - *Refs:* REQ-005, REQ-006, plan §2 Architecture, plan §4 Public CLI changes and Internal seams

- [ ] **T004** [P] — Probe fallback CLI readiness consistently
  - *Files:* `scripts/spec-dispatch-ready.sh` (new), `tests/test-usage-limits.sh`
  - *Acceptance:* fixture tests prove each CLI is ready only when its binary, role adapter, and read-only authentication probe succeed, with the auth-checker override and concise unavailable reasons covering every failure seam
  - *Verify:* `tests/run.sh limits` → `"== test-usage-limits.sh"` and exit 0
  - *Refs:* REQ-006, REQ-007, AC-006, AC-009, plan §2 Architecture, plan §4 Public CLI changes, plan R5

- [ ] **T005** [hard] — Implement one-shot resume scheduler seam
  - *Files:* `scripts/spec-resume-scheduler.sh` (new), `tests/test-usage-limits.sh`
  - *Acceptance:* scheduler-stub tests prove idempotent `add`, `remove`, and `list`, minute-up launchd registration on Darwin, marked due-check cron registration elsewhere, state-root preservation, and remove-before-replay one-shot behavior without touching the real scheduler
  - *Verify:* `tests/run.sh limits` → `"== test-usage-limits.sh"` and exit 0
  - *Refs:* REQ-005, AC-004, AC-005, CON-001, plan §2 Architecture, plan §3 Resume unit, plan §4 scheduler contract and Internal seams, plan R4/R6

- [ ] **T006** [hard] — Persist and replay bounded resume units
  - *Files:* `scripts/spec-resume.sh` (new), `tests/test-usage-limits.sh`
  - *Depends on:* T003, T005
  - *Acceptance:* tests named AC-005 prove deterministic private units preserve cwd plus adversarial argv byte-for-byte, `list`/`cancel` reconcile scheduler state, success removes the unit, generic failure marks it failed, repeat exit 7 re-parks only through the nested dispatcher, and attempt three stops without a new job
  - *Verify:* `tests/run.sh limits` → `"== test-usage-limits.sh"` and exit 0
  - *Refs:* REQ-005, AC-004, AC-005, CON-003, CON-004, plan §3 Resume unit, plan §4 resume CLI and Internal seams, plan R2/R4/R6

## Dispatch integration

- [ ] **T007** [hard] — Capture and classify failed dispatch attempts
  - *Files:* `scripts/spec-dispatch.sh`, `tests/test-usage-limits.sh`
  - *Depends on:* T001, T002
  - *Acceptance:* tests named AC-003 and AC-007 prove every provider attempt tees combined output into aggregate and per-attempt captures, Codex retains its true exit status, ordinary failures keep exit 6, and a classified limit with no policy or `fail` exits 7 with kind/reset plus shell-safe manual park and `--to` commands while invoking neither scheduler nor readiness fallback
  - *Verify:* `tests/run.sh limits` → `"== test-usage-limits.sh"` and exit 0
  - *Refs:* REQ-001, REQ-003, REQ-004, AC-003, AC-007, CON-002, plan §2 Dispatch flow, plan §4 Public CLI changes and Internal seams, plan R1/R8

- [ ] **T008** [hard] — Route park policy through resume units
  - *Files:* `scripts/spec-dispatch.sh`, `tests/test-usage-limits.sh`
  - *Depends on:* T003, T005, T006, T007
  - *Acceptance:* tests named AC-004 and AC-005 prove `short: park` persists the untouched original dispatcher argv and cwd, schedules exactly once at parsed-reset-or-backoff plus deterministic jitter, records the unit event through `spec-status.sh`, and lets a nested exit 7 enforce the retry cap without duplicate jobs
  - *Verify:* `tests/run.sh limits` → `"== test-usage-limits.sh"` and exit 0
  - *Refs:* REQ-004, REQ-005, AC-004, AC-005, CON-003, CON-004, plan §2 Dispatch flow, plan §3 Resume unit, plan §4 Internal seams

- [ ] **T009** [hard] — Delegate long limits across ready fallbacks
  - *Files:* `scripts/spec-dispatch.sh`, `tests/test-usage-limits.sh`
  - *Depends on:* T003, T004, T007, T008
  - *Acceptance:* tests named AC-006 prove ordered fallback selection skips the limited and already-attempted CLIs, records readiness skip reasons and from/to decisions, caps the loop at three non-recursive attempts, sends the first success through the unchanged role verifier, classifies only the current slice, and parks when fallbacks exhaust
  - *Verify:* `tests/run.sh limits` → `"== test-usage-limits.sh"` and exit 0
  - *Refs:* REQ-001, REQ-006, AC-006, CON-004, plan §2 Dispatch flow, plan §4 Internal seams, plan R5/R8

## Tests

> Every behavioral test names the AC id it proves so
> `scripts/spec-ac-coverage.sh` can bind acceptance claims to executable checks.

- [ ] **T010** — Bind acceptance IDs and run regressions
  - *Files:* `tests/test-usage-limits.sh`, `tests/test-model-policy.sh`, `tests/test-executable-bits.sh`
  - *Acceptance:* test descriptions bind AC-001 through AC-009 and AC-011 to happy/error coverage, all new scripts are executable, every existing suite remains green, and all changed scripts pass shellcheck at warning severity
  - *Verify:* `bash -c 'tests/run.sh && shellcheck -S warning -x scripts/*.sh tests/*.sh'` → `"== test-usage-limits.sh"` and exit 0
  - *Refs:* REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, REQ-007, AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008, AC-009, AC-011, plan §5 Dependencies, plan §6 Stack overlay notes, plan §8 Release checks

## Observability

- [ ] **T011** — Diagnose limit policy and resume orphans
  - *Files:* `scripts/sdd-doctor.sh`, `tests/test-usage-limits.sh`
  - *Depends on:* T002, T004, T005, T006
  - *Acceptance:* tests named AC-009 prove doctor reports invalid limit policy, unavailable or adapter-missing fallbacks, every pending/failed unit, unit-without-job and job-without-unit orphans, and performs resume reconciliation even when models.yml is absent
  - *Verify:* `tests/run.sh limits` → `"== test-usage-limits.sh"` and exit 0
  - *Refs:* REQ-007, AC-009, plan §2 Architecture, plan §4 Internal seams, plan R5/R6

## Docs

- [ ] **T012** — Document limit policy and recovery workflows
  - *Files:* `README.md`, `models.example.yml`, `knowledge/usage-limit-handling.md` (new), `tests/test-usage-limits.sh`
  - *Acceptance:* a test named AC-010 proves all three documents use the parser's exact `short`, `long`, `fallback`, and `backoff_minutes` keys; README explains automatic and manual recovery; the knowledge note cites empirical message provenance, warns about drift, and gives the interactive-session recipe; the example block remains commented out
  - *Verify:* `tests/run.sh limits` → `"== test-usage-limits.sh"` and exit 0
  - *Refs:* REQ-008, AC-010, CON-002, plan §2 Architecture, plan §8 Activation/Reversibility/Observability, plan §9 interactive-session deferral

## Reality Check (pre-ship gate)

- [ ] **T013** — Opponent review: steelman why this implementation is wrong
  - *Agent:* `~/.sdd/agents/opponent.agent.md`
  - *Inputs:* the diff on this branch, `spec.md`, `plan.md`, every `[x]` task
  - *Acceptance:* agent returns **CLEARED** (not CHALLENGED); findings written to `notes/opponent.md`
  - *Refs:* REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, REQ-007, REQ-008, AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008, AC-009, AC-010, AC-011
  - *On CHALLENGED:* open follow-up tasks here (T013o1, T013o2, …) for each defect; fix and re-run before T014

- [ ] **T014** — Reality-check the implemented spec end-to-end
  - *Agent:* `~/.sdd/agents/reality-check.agent.md`
  - *Inputs:* every prior `[x]` task, `spec.md`, `plan.md`, `notes/opponent.md`
  - *Acceptance:* agent returns **READY** (not NEEDS WORK / FAILED); claim-vs-evidence gaps documented in `notes/reality-check.md`; all AC-### mapped to concrete evidence
  - *Refs:* AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008, AC-009, AC-010, AC-011
  - *On NEEDS WORK:* open follow-up tasks here (T014a1, T014a2, …); do not proceed to Ship until they are `[x]` and the gate is re-run

## Ship

- [ ] **T015** — Open PR to main referencing spec and plan
  - *Files:* (none — branch + PR)
  - *Acceptance:* `~/.sdd/scripts/spec-pr.sh <spec-dir>` prints the PR URL, writes `pr:` and `phase: review` into STATUS.md, includes both gate verdicts in the PR body, and requests a reviewer

- [ ] **T016** — Roll out provider limit handling after merge
  - *Acceptance:* `scripts/sync.sh --check` and `scripts/sdd-doctor.sh` pass from merged `main`; default-off policy remains inert; pending units are inspected; MET-001 observation owner and check-back trigger are recorded in STATUS.md; phase is `shipped`
  - *Refs:* MET-001, MET-002, CON-002, CON-005, plan §8

- [ ] **T017** — Retro: harvest lessons into the hub
  - *Acceptance:* `/sdd:retro` runs, `notes/retro.md` records classifier/scheduler/fallback lessons and the MET-001 result or explicit not-yet-observed status, cross-project lessons are filed in `knowledge/`, and STATUS.md `retro:` is `done`
  - *Refs:* `notes/opponent.md`, `notes/reality-check.md`, `notes/ci.md` (if CI failed en route), STATUS decisions log, plan §8 MET-001/MET-002

---

*Workflow:* Once a task is done, tick its checkbox. Run `/sdd:implement` to
execute the next pending task. When all tasks are `[x]`, set frontmatter
`status: complete`.
