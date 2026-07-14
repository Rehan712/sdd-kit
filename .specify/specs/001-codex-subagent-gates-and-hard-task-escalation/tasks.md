---
tasks_for: 001-codex-subagent-gates-and-hard-task-escalation
status: in-progress
created: 2026-07-14
updated: 2026-07-14
---

# Tasks: Codex subagent gates and hard-task escalation

> Dependency-ordered checklist. Each task is small enough to be a single commit
> and has an explicit acceptance check.

## Backend (build-adapters.sh + model-policy.sh)

- [x] **T001** — Split adapter preamble into per-CLI variants
  - *Files:* `scripts/build-adapters.sh`
  - *Acceptance:* `PREAMBLE` becomes `CODEX_PREAMBLE` (delegation wording from plan §4 seams, transcribed: gates → `sdd-opponent`/`sdd-reality-check` with persona-pass fallback; `[hard]`/retries/gate follow-ups → `sdd-implement-hard`) and `COPILOT_PREAMBLE` (today's persona-pass text unchanged); each SDD adapter loop uses its CLI's variant
  - *Verify:* `shellcheck -S warning -x scripts/build-adapters.sh` → "" (exit 0; functional proof lands with T004)
  - *Refs:* REQ-003, AC-004, plan §2 §4
  - *Evidence:* `shellcheck -S warning -x scripts/build-adapters.sh → (no output) (see notes/evidence.md)` (2026-07-14)

- [x] **T002** [hard] — Generate and prune Codex subagent TOMLs
  - *Files:* `scripts/build-adapters.sh`
  - *Acceptance:* new `codex_subagent_toml()` (plan §4 seam signature) + a generation block after the tier-profile block, same `[[ -d ~/.codex ]] && HAVE_POLICY` guard: writes `~/.codex/agents/sdd-{opponent,reality-check,implement-hard}.toml` (kit-marker first line; persona body in `'''` literal with a hard-fail guard if a persona contains `'''`; model/effort per role via the existing `policy()` helper, keys omitted when unset); prunes only marker-bearing stale `sdd-*.toml`
  - *Verify:* `shellcheck -S warning -x scripts/build-adapters.sh` → "" (exit 0; functional proof lands with T004)
  - *Refs:* REQ-002, AC-001, AC-002, AC-003, plan §2 §3 §4
  - *Evidence:* `shellcheck -S warning -x scripts/build-adapters.sh → (no output) (see notes/evidence.md)` (2026-07-14)

- [x] **T003** [P] — Widen codex effort whitelist to documented values
  - *Files:* `scripts/model-policy.sh`, `models.example.yml`
  - *Acceptance:* both validation sites (`validate_field`, `check`) accept `none|minimal|low|medium|high|xhigh|ultra|max` for codex and reject junk; error text and the models.example.yml comment list the same set
  - *Verify:* `sh -c 't=$(mktemp); cp models.example.yml "$t"; scripts/model-policy.sh --file "$t" set tier reasoning codex effort ultra'` → "codex_effort = ultra"
  - *Refs:* REQ-005, AC-005, plan §2 §4
  - *Evidence:* `sh -c t=$(mktemp); cp models.example.yml "$t"; scripts/model-policy.sh --file "$t" set tier reasoning codex effort ultra → ✓ tier 'reasoning': codex_effort = ultra (see notes/evidence.md)` (2026-07-14)

## Tests

- [x] **T004** — Adapter test suite (hermetic sandbox kit)
  - *Files:* `tests/test-build-adapters.sh`
  - *Acceptance:* new suite copies the kit into `$SANDBOX/kit` (git ls-files set), runs with `HOME=$SANDBOX/home` (plan §4 hermeticity seam); tests name AC-001 (TOML fields/stamps), AC-002 (marker prune + user-file survival), AC-003 (no policy / no ~/.codex degradation), AC-004 (codex adapters carry delegation text, copilot adapters persona-pass)
  - *Verify:* `bash tests/run.sh build-adapters` → "passed"
  - *Refs:* AC-001, AC-002, AC-003, AC-004, plan §2
  - *Evidence:* `bash tests/run.sh build-adapters → -- 4/4 passed (see notes/evidence.md)` (2026-07-14)

- [x] **T005** [P] — Model-policy effort test suite
  - *Files:* `tests/test-model-policy.sh`
  - *Acceptance:* new suite (against `--file` sandbox policies only) names AC-005: `ultra`/`max`/`none` accepted for codex, junk value rejected, `check` green on a policy using them, claude effort unchanged (still rejects `ultra`)
  - *Verify:* `bash tests/run.sh model-policy` → "passed"
  - *Refs:* AC-005, plan §2
  - *Evidence:* `bash tests/run.sh model-policy → -- 3/3 passed (see notes/evidence.md)` (2026-07-14)

## Empirical verification (before any doc claims)

- [x] **T006** — Prove installed codex accepts and spawns the TOMLs
  - *Files:* `notes/codex-subagents.md` (new, in this spec dir)
  - *Acceptance:* kit subagent TOMLs generated into a scratch `CODEX_HOME`-equivalent or the real `~/.codex/agents/` (restore after), then a headless `codex exec` run demonstrates: no config parse error, and the CLI can enumerate or spawn a kit subagent; full command + transcript captured; if the documented TOML shape is wrong, fix T002's generator against observed behavior and note the delta (plan R1)
  - *Verify:* `codex exec --sandbox read-only "Which custom agents are available to you? Reply with their names only."` → "sdd-opponent" (adapt flags as the experiment demands; spec-run captures what actually ran)
  - *Refs:* REQ-002, AC-007, plan §7 R1 R2
  - *Evidence:* `codex exec --sandbox read-only Spawn the sdd-opponent agent and have it reply with exactly the word READY, then report what it said. → The sdd-opponent agent said: READY (see notes/evidence.md)` (2026-07-14)

- [ ] **T007** — Prototype Copilot agent-tool handoff and record the finding
  - *Files:* `knowledge/cli-subagent-delegation.md` (new)
  - *Acceptance:* scratch dir with `.github/agents/sdd-proto-hard.agent.md` (distinct `model:`); headless `copilot -p` run asks the session to hand the task to that agent; transcript captured; knowledge file states the dated works/doesn't finding for BOTH CLIs with excerpts and `(learned: sdd-kit-public/001)`; timeboxed — "could not demonstrate" is a valid finding (plan R3)
  - *Verify:* `grep -iE "finding: (works|does not|partial)" knowledge/cli-subagent-delegation.md` → the verdict line
  - *Refs:* REQ-006, AC-008, plan §2 §7 R3

## Docs (only claims T006/T007 proved)

- [ ] **T008** — Rewrite gate personas' cross-CLI notes
  - *Files:* `agents/opponent.agent.md`, `agents/reality-check.agent.md`
  - *Acceptance:* opponent's "Single-agent note" replaced with per-CLI text (Codex: kit subagent `sdd-opponent`, fresh context, persona-pass fallback when TOMLs absent; Copilot: per T007's finding); reality-check gains the matching note (anchor: opponent's rewritten section, reality-check verdicts); no "CLI without subagents" phrasing survives in either
  - *Verify:* `sh -c 'grep -L "without subagents" agents/opponent.agent.md agents/reality-check.agent.md && grep -l "sdd-opponent" agents/opponent.agent.md'` → both filenames then opponent path
  - *Refs:* REQ-004, AC-006, plan §2
  - Depends on: T006, T007

- [ ] **T009** [P] — Correct constitution §10.5 and README per-CLI section
  - *Files:* `constitution.md`, `README.md`
  - *Acceptance:* §10.5's "on single-agent CLIs they run as distinct review passes" reworded to subagent-when-available + persona-pass fallback; README gates blurb (~line 95) and the Codex bullet in "How it's applied per CLI" describe profiles (phase tier) + generated `~/.codex/agents/sdd-*.toml` (gates/escalation); Copilot wording matches T007's finding
  - *Verify:* `sh -c 'grep -c "sdd-opponent\|~/.codex/agents" README.md constitution.md'` → count ≥1 per file
  - *Refs:* REQ-004, AC-006, plan §2
  - Depends on: T006, T007

## Reality Check (pre-ship gate)

- [ ] **T010** — Opponent review: steelman why this implementation is wrong
  - *Agent:* `~/.sdd/agents/opponent.agent.md`
  - *Inputs:* the diff on this branch, `spec.md`, `plan.md`, every `[x]` task
  - *Acceptance:* agent returns **CLEARED** (not CHALLENGED); findings written to `notes/opponent.md`
  - *Refs:* REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008
  - *On CHALLENGED:* open follow-up tasks here (T010o1, …); fix and re-run before T011

- [ ] **T011** — Reality-check the implemented spec end-to-end
  - *Agent:* `~/.sdd/agents/reality-check.agent.md`
  - *Inputs:* every prior `[x]` task, `spec.md`, `plan.md`, `notes/opponent.md`
  - *Acceptance:* agent returns **READY** (not NEEDS WORK / FAILED); all AC-### mapped to concrete evidence in `notes/reality-check.md`
  - *Refs:* AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008
  - *On NEEDS WORK:* open follow-up tasks here (T011a1, …); do not proceed to Ship until they're `[x]` and the gate is re-run

## Ship

- [ ] **T012** — Open PR to main referencing spec.md and plan.md
  - *Files:* (none — branch + PR)
  - *Acceptance:* `~/.sdd/scripts/spec-pr.sh <spec-dir>` prints the PR URL; both gate verdicts in the PR body; reviewer requested

- [ ] **T013** — Roll out (after /sdd:review reports the PR merged)
  - *Acceptance:* port to the private repo (CON-004, prior-PR pattern); `setup.sh` on the live install; `ls ~/.codex/agents/sdd-*.toml` shows the three generated subagents; STATUS `phase: shipped`; MET-001 check-back noted for the next Codex-dispatched spec's retro

- [ ] **T014** — Retro: harvest lessons into the hub
  - *Acceptance:* `/sdd:retro` run; `notes/retro.md` written with the root-cause split; STATUS `retro:` set to `done`
