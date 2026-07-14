---
tasks_for: 001-codex-subagent-gates-and-hard-task-escalation
status: complete
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

- [x] **T007** — Prototype Copilot agent-tool handoff and record the finding
  - *Files:* `knowledge/cli-subagent-delegation.md` (new), `tests/test-build-adapters.sh` (AC-007/AC-008 binding test on the knowledge artifact)
  - *Acceptance:* scratch dir with `.github/agents/sdd-proto-hard.agent.md` (distinct `model:`); headless `copilot -p` run asks the session to hand the task to that agent; transcript captured; knowledge file states the dated works/doesn't finding for BOTH CLIs with excerpts and `(learned: sdd-kit-public/001)`; timeboxed — "could not demonstrate" is a valid finding (plan R3)
  - *Verify:* `grep -iE "finding: (works|does not|partial)" knowledge/cli-subagent-delegation.md` → the verdict line
  - *Refs:* REQ-006, AC-008, plan §2 §7 R3
  - *Evidence:* `grep -icE finding: (works|does not|partial) knowledge/cli-subagent-delegation.md → 2 (see notes/evidence.md)` (2026-07-14)

## Docs (only claims T006/T007 proved)

- [x] **T008** — Rewrite gate personas' cross-CLI notes
  - *Files:* `agents/opponent.agent.md`, `agents/reality-check.agent.md`
  - *Acceptance:* opponent's "Single-agent note" replaced with per-CLI text (Codex: kit subagent `sdd-opponent`, fresh context, persona-pass fallback when TOMLs absent; Copilot: per T007's finding); reality-check gains the matching note (anchor: opponent's rewritten section, reality-check verdicts); no "CLI without subagents" phrasing survives in either
  - *Verify:* `sh -c '! grep -q "without subagents" agents/opponent.agent.md agents/reality-check.agent.md && grep -l "sdd-opponent" agents/opponent.agent.md && grep -l "sdd-reality-check" agents/reality-check.agent.md'` → both persona paths (stale phrase absent) — original `grep -L` form always exited 1 by design; amended 2026-07-14
  - *Refs:* REQ-004, AC-006, plan §2
  - *Evidence:* `sh -c ! grep -q "without subagents" agents/opponent.agent.md agents/reality-check.agent.md && grep -l "sdd-opponent" agents/opponent.agent.md && grep -l "sdd-reality-check" agents/reality-check.agent.md → agents/reality-check.agent.md (see notes/evidence.md)` (2026-07-14)
  - Depends on: T006, T007

- [x] **T009** [P] — Correct constitution §10.5 and README per-CLI section
  - *Files:* `constitution.md`, `README.md`, `scripts/build-adapters.sh` (COPILOT_PREAMBLE's "CLI without subagents" claim is false post-T007 — reworded, persona-pass behavior unchanged), `tests/test-build-adapters.sh` (AC-004 assertions track the new phrasing)
  - *Acceptance:* §10.5's "on single-agent CLIs they run as distinct review passes" reworded to subagent-when-available + persona-pass fallback; README gates blurb (~line 95) and the Codex bullet in "How it's applied per CLI" describe profiles (phase tier) + generated `~/.codex/agents/sdd-*.toml` (gates/escalation); Copilot wording matches T007's finding
  - *Verify:* `sh -c 'grep -c "sdd-opponent\|~/.codex/agents" README.md constitution.md'` → count ≥1 per file
  - *Refs:* REQ-004, AC-006, plan §2
  - *Evidence:* `sh -c grep -q "sdd-opponent\|~/.codex/agents" README.md && grep -q "sdd-\*.toml" constitution.md && echo "README + constitution both name the codex subagents" → README + constitution both name the codex subagents (see notes/evidence.md)` (2026-07-14)
  - Depends on: T006, T007

## Reality Check (pre-ship gate)

- [x] **T010** — Opponent review: steelman why this implementation is wrong
  - *Agent:* `~/.sdd/agents/opponent.agent.md`
  - *Inputs:* the diff on this branch, `spec.md`, `plan.md`, every `[x]` task
  - *Acceptance:* agent returns **CLEARED** (not CHALLENGED); findings written to `notes/opponent.md`
  - *Refs:* REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008
  - *On CHALLENGED:* open follow-up tasks here (T010o1, …); fix and re-run before T011

- [x] **T010o1** — Capture the Copilot handoff probe for real
  - *Files:* `knowledge/cli-subagent-delegation.md` (paste the captured transcript)
  - *Defect:* the "empirically proven" Copilot claim shipped on a hand-typed excerpt; the only evidence capture was a grep of the knowledge file itself (opponent Finding 1)
  - *Done:* the delegation probe re-run under `spec-run.sh` (real captured transcript in `notes/evidence.md`), and the transcript block pasted verbatim into the knowledge file's Copilot section
  - *Verify:* `copilot -p "Hand this task off to the sdd-proto-hard custom agent: 'confirm readiness'. Report exactly what it returned." --allow-all --no-color` → "ESCALATED-BY-PROTO"
  - *Refs:* REQ-006, AC-008
  - *Evidence:* `copilot -p Hand this task off to the sdd-proto-hard custom agent: 'confirm readiness'. Report exactly what it returned. --allow-all --no-color → **`ESCALATED-BY-PROTO`** (see notes/evidence.md)` (2026-07-14)

- [x] **T010o2** — Reconcile the codex version stamps with the captured run
  - *Files:* `knowledge/cli-subagent-delegation.md`, `notes/codex-subagents.md` (spec dir)
  - *Defect:* findings stamped codex-cli 0.144.1 while the captured T006 transcript shows v0.144.4 — the binary auto-updated mid-session (opponent Finding 2)
  - *Done:* stamps read 0.144.4 (the captured run's own banner) with a one-line note that earlier uncaptured probes may have run 0.144.1 with identical conclusions
  - *Verify:* `sh -c '! grep -rn "0\.144\.1" knowledge/cli-subagent-delegation.md .specify/specs/001-codex-subagent-gates-and-hard-task-escalation/notes/codex-subagents.md && grep -c "0\.144\.4" knowledge/cli-subagent-delegation.md'` → count ≥ 1
  - *Refs:* AC-007, AC-008
  - *Evidence:* `sh -c ! grep -rn "0\.144\.1" knowledge/cli-subagent-delegation.md .specify/specs/001-codex-subagent-gates-and-hard-task-escalation/notes/codex-subagents.md | grep -v "auto-updated\|may have run" && grep -c "0\.144\.4" knowledge/cli-subagent-delegation.md → 3 (see notes/evidence.md)` (2026-07-14)

- [x] **T010o4** — Discriminating Copilot model-pin probe (or downgrade the claim)
  - *Files:* `knowledge/cli-subagent-delegation.md`
  - *Defect:* the "per-agent model IS honored" claim rests on a probe that pinned `gpt-5.6-terra` — a known session-default — so the capture cannot discriminate honored-vs-inherited (opponent Round 2 Finding 1); the fallback-warning claim is also uncaptured
  - *Done:* one captured session hands off to agents pinning TWO distinct valid models (+ one invalid id); if the spawn lines show their respective models the claim stands with discriminating evidence cited, otherwise it is downgraded to "not independently confirmed"; the fallback warning is captured or its claim removed; the knowledge transcript is labeled abridged with a pointer to the full capture
  - *Verify:* `copilot -p "Hand off to each of the custom agents sdd-proto-a, sdd-proto-b, and sdd-proto-x in turn, each with the task 'confirm readiness'. Report each agent's reply." --allow-all --no-color` → spawn lines for all three agents
  - *Refs:* REQ-006, AC-008
  - *Evidence:* `captured run T010o4 (sha256:ed3cb1d6e84c): one session, three parallel handoffs — spawn lines Sdd-proto-a(claude-sonnet-5), Sdd-proto-b(gpt-5.6-terra), Sdd-proto-x(claude-sonnet-4.6 fallback for invalid pin) — two distinct pins → two distinct child models; knowledge file updated to cite it` (2026-07-14)

- [x] **T010o3** — Align spec.md's escalation promise with the recorded reality
  - *Files:* `spec.md` (this spec dir — §1 problem framing, §5 user story)
  - *Defect:* spec text promises "[hard] escalation semantics match Claude" / "no longer silently runs at the implementation tier" — unmet on the installed Codex (model pin not honored); the generated docs hedge correctly, the durable spec doesn't (opponent Finding 3)
  - *Done:* §1 and the user story promise fresh-context escalation now, model escalation when Codex honors per-agent model fields; STATUS Decisions logs the spec revision
  - *Verify:* `sh -c '! grep -q "match Claude" .specify/specs/001-codex-subagent-gates-and-hard-task-escalation/spec.md && grep -c "fresh context" .specify/specs/001-codex-subagent-gates-and-hard-task-escalation/spec.md'` → count ≥ 1
  - *Refs:* REQ-003, AC-007
  - *Evidence:* `sh -c ! grep -q "match Claude" .specify/specs/001-codex-subagent-gates-and-hard-task-escalation/spec.md && grep -c "fresh context" .specify/specs/001-codex-subagent-gates-and-hard-task-escalation/spec.md → 5 (see notes/evidence.md)` (2026-07-14)

- [x] **T011** — Reality-check the implemented spec end-to-end
  - *Agent:* `~/.sdd/agents/reality-check.agent.md`
  - *Inputs:* every prior `[x]` task, `spec.md`, `plan.md`, `notes/opponent.md`
  - *Acceptance:* agent returns **READY** (not NEEDS WORK / FAILED); all AC-### mapped to concrete evidence in `notes/reality-check.md`
  - *Refs:* AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008
  - *On NEEDS WORK:* open follow-up tasks here (T011a1, …); do not proceed to Ship until they're `[x]` and the gate is re-run

## Ship

- [x] **T012** — Open PR to main referencing spec.md and plan.md
  - *Files:* (none — branch + PR)
  - *Acceptance:* `~/.sdd/scripts/spec-pr.sh <spec-dir>` prints the PR URL; both gate verdicts in the PR body; reviewer requested

- [x] **T013** — Roll out (after /sdd:review reports the PR merged)
  - *Acceptance:* port to the private repo (CON-004, prior-PR pattern); `setup.sh` on the live install; `ls ~/.codex/agents/sdd-*.toml` shows the three generated subagents; STATUS `phase: shipped`; MET-001 check-back noted for the next Codex-dispatched spec's retro
  - *Evidence:* `public PR #12 merged (889631a); ported to private via Rehan712/sdd-kit-private#12 (5b4d884, CI 4/4 green); setup.sh on live install → 0 errors; ls ~/.codex/agents/sdd-*.toml → sdd-implement-hard.toml sdd-opponent.toml sdd-reality-check.toml` (2026-07-14)

- [x] **T014** — Retro: harvest lessons into the hub
  - *Acceptance:* `/sdd:retro` run; `notes/retro.md` written with the root-cause split; STATUS `retro:` set to `done`
