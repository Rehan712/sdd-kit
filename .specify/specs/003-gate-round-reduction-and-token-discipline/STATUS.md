---
spec: 003-gate-round-reduction-and-token-discipline
phase: implement          # specify | plan | tasks | implement | review | shipped | abandoned
active_tool: none        # claude | codex | copilot | none — who currently holds the spec
branch: spec/003-gate-round-reduction-and-token-discipline            # spec/003-gate-round-reduction-and-token-discipline once cut, else none
worktree: /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline          # absolute path once created, else none
pr: none                # PR URL once opened — spec-pr.sh writes this itself
opponent: not-run       # not-run | CHALLENGED | CLEARED | BLOCKED  (+ date)
reality_check: not-run  # not-run | NEEDS WORK | FAILED | READY  (+ date)
ci: not-run             # not-run | pending | green | red  (+ date) — spec-ci.sh writes this
retro: not-run          # not-run | done (+ date) — /sdd:retro after ship
updated: 2026-09-06
---

# STATUS — Gate round reduction and token discipline

> The living memory of this spec. **Every tool — Claude, Codex, Copilot — reads this
> on entry and updates it on exit.** It is the handoff record across tools and sessions.
> Keep it short: state and decisions, not narrative. `tasks.md` owns the checklist;
> this file owns the *why*, the *where* (branch/worktree/PR), and *what's next*.
> Scripts mutate frontmatter via `~/.sdd/scripts/spec-status.sh set` — use it too;
> it validates enum values and bumps `updated:` for you.
> Abandoning a spec: set `phase: abandoned`, note why in Decisions, then
> `spec-worktree.sh --remove --delete-branch <spec-dir>` to clean up.
>
> **Hard size rule:** "Where things stand" stays ≤ 10 lines and this file ≤ ~120 lines.
> When a gate round or session log outgrows that, move the detail to `notes/history.md`
> (append-only) and keep ONE summary line here. A STATUS nobody can skim is a STATUS
> nobody reads — frontmatter fields stay one line each (the dashboard parses them).

## Where things stand

Stopped at the user's requested handoff point after T003 and its T003f1 fix.
T001/T002/T003/T003f1 are accepted with captured evidence and clean security
reviews where required; T003 commit is 9d8099e (T002: 8a0d737).
T004/T005 remain [~]: prepared, uncommitted source changes; local checks passed.
Final analyzer: one task-count warning, zero errors. ShellCheck/diff-check pass.
No gate has started. Reuse remains disabled until T023.
Linux Docker image and macOS Bash 3.2 execution routes are ready for T027.

## Decisions log

Append-only, newest last. Each entry: `date — decision — rationale / who decided`.

- 2026-09-04 — Spec created.
- 2026-09-04 — Opponent round cap is SCRIPT-ENFORCED at 3 (`spec-gate.sh round`), round 4+ needs a `waiver:`/`spec-revision:` Decisions line — user chose over advisory-3 and hard-2; the 10-round loop must be impossible, not discouraged.
- 2026-09-04 — Blocking severity = reproduced/concretely-triggered data-loss, wrong-result, regression, crash; doc-integrity blocks only when an AC/REQ names the document or claim — user chose; cuts the 50-finding runs without dropping real defects.
- 2026-09-04 — Tests-with-tasks is an analyzer WARNING (zero allowed on a freshly written tasks.md), not an error — user chose; keeps legacy specs green (CON-003), same pattern as the Verify rule.
- 2026-09-04 — Token metric source = Claude Code usage/credits view read before/after each orchestrated run, recorded in STATUS Decisions at Ship — user's actual observation method; no accounting tooling in scope.
- 2026-09-04 — New stack.yml key named `checkpoints:` (stage → command list); floor = analyze + ac-coverage + evidence + checkpoints — Claude decided, user can override.
- 2026-09-04 — One spec, not two (round-reduction vs token-discipline): the floor script serves both halves and splitting would duplicate persona edits — Claude decided.
- 2026-09-05 — User requested all review issues fixed; revised the spec and acceptance criteria while retaining the agreed models, gate separation, severity policy, and default three-round cap.
- 2026-09-05 — Required `gate_checks:` is separate from optional stage `checkpoints:`; `verification_contract: 1` distinguishes new requirements from legacy warnings. This supersedes the earlier floor = checkpoints decision. Stage checks include completed-task coverage deltas.
- 2026-09-05 — Historical capture presence is not freshness. Reuse requires source/input provenance and invalidation checks; missing provenance forces verification. Workers use `--no-tick --summary`; deterministic `spec-gate.sh accept` validates returns before ticking. Additive metadata/log sidecars are in scope.
- 2026-09-05 — Later review retains affected and unexamined surfaces, including unchanged code. `Class:` identifies defect families separately from process `Root cause:`. Additional-round authorization names one gate and one round with an ordered UTC timestamp; no indefinite unlock.
- 2026-09-05 — FM IDs are defined during planning and bound to tasks during decomposition. Shared rows and test families limit repetition. Authoritative implementation briefs do not restrict planning experts from proposing decisions.
- 2026-09-05 — 002 records five opponent rounds, six wrong-result findings, and one final reality-check report. Two rounds/30% savings remain hypotheses; actual usage and 14-day defect observations accompany proxies. Unknown baselines stay unknown.
- 2026-09-05 — Implement bindings, class sweeps, summaries and floor before enabling reuse. Executable negative fixtures must prove rejection/invalidation; this spec's first-report live probe runs at reality-check, avoiding a circular pre-gate prerequisite.
- 2026-09-05 — User explicitly accepted the revised spec and requested the implementation plan. Spec status set to accepted; planning follows the configured Claude dispatch. The existing single-spec decision remains in force; this pass does not task or implement it.
- 2026-09-05 — Claude dispatch returned a session limit (exit 6 from dispatcher); continued the already authorized planning task with the configured Codex reasoning model (gpt-5.6-sol, xhigh) and local review. No model-policy edit or delayed retry; original failure capture retained.
- 2026-09-05 — The Codex draft helper also reached its usage limit before saving. User explicitly requested continuing here; completed the plan in the current session with no further delegation or provider handoff.
- 2026-09-05 — Plan defines one verification grammar/library shared by existing scripts and spec-gate; typed test bindings, no-tick captures and a serialized validated-return transaction precede task mutation. Gate reservations and exact per-round authorizations fail closed.
- 2026-09-05 — V1 reuse uses conservative whole-source manifests and explicit local-check opt-in, not a dependency graph. Enable reuse/carry only after invalidation fixtures pass; live AC-016 observations run after reports exist, separate from the pre-gate fixture suite.
- 2026-09-05 — In-session structural check: `plan-structure PASS; sections=10; requirements=16; acceptanceCriteria=23; failureModes=20; invariants=6; testFamilies=12; errors=[]`. Checked exact references, unique/resolved IDs, family bindings, statuses and whitespace. This is planning evidence, not implementation/gate clearance.
- 2026-09-05 — User invoked /sdd:tasks and explicitly requested continuation here; accepted plan.md and decomposed locally without a provider/subagent handoff or model-policy edit.
- 2026-09-05 — Retained the accepted single-spec decision despite the ~25-task recommendation: 34 tasks keep each edit task within five files; only T003/T004/T005 are parallel-safe after T002. Shared kernel/test-file edits remain serial.
- 2026-09-05 — Clarified AC-016 ordering in plan §8: the live probe uses the completed opponent report plus the active reality-check reservation/floor; round completion validates the later reality-check report, avoiding a self-prerequisite.
- 2026-09-05 — AC-019 requires real platform evidence, not a local proxy for unrun CI. The current workflow triggers on PRs/main; if no authorized matrix executor is available, implementation must request an execution route before READY. No early draft PR or weakened gate was authorized here.
- 2026-09-05 — Both installed and repository sdd-analyze.sh returned `1 warning(s), 0 errors`; the sole warning is 34 tasks versus the ~25 guideline. All implementation AC refs and both gate paths resolve; no missing Verify warnings.
- 2026-09-05 — Direct task-contract check: `PASS; tasks=34; parallel=3; hard=14; acceptanceCriteria=23; ownedFailureModes=20; ownedInvariants=6; errors=[]`. Verified family/Verify matches, all row owners, existing-or-declared-new files, forward integration ownership, disjoint parallel files and unticked state.

- 2026-09-06 — User invoked /sdd:implement --all and explicitly requested continuation here; run in this Codex session without provider/model handoff. Spec and plan acceptance remains in force; task list accepted for execution. Use required hard-task and independent gate roles locally.
- 2026-09-06 — Authored spec docs were untracked on main; copied them intact to the guarded spec worktree for the initial spec-branch commit, preserving the original checkout. Normal stop-point is T032 Open PR; T033/T034 remain post-merge.

- 2026-09-06 — Normalized plan verification registry to the explicit Family/Kind/Criteria/Concrete locators columns: all kinds were already decided as test in adjacent prose. This is a downstream schema correction, not a requirement or test-ownership change; parser will not infer kind from prose.

- 2026-09-06 — T002 hard-task agent hit its usage limit before final return. Parent preserved partial work and captured exact Verify (18/18 passed), with targeted ShellCheck/diff-check clean; task remains in-progress and uncommitted pending delegated completion/security review. Stopped per the invoked workflow; no fabricated acceptance or later dispatch.

- 2026-09-06 — User requested finishing the current task here, then stopping for handoff. T003 hard-task delegate reached its usage limit before saving changes; parent completed T003 under this explicit instruction, preserving separate security review. T004/T005 remain prepared and unaccepted. T003f1 is the necessary fixture/authoring compatibility companion; no subsequent task will start.

## Open questions / blockers

- [ ] (@Rehan712, non-blocking) Which governed project's next spec is the first MET-001 measurement point.
- [ ] (AC-019) Capture actual Linux container and macOS/Bash-3.2 results at T027 before READY; normal PR CI remains required afterward.

## Handoff note

Use the worktree above; the untracked original spec copy on main is stale.
T004 owns skills/sdd-plan, skills/sdd-tasks and tests/test-gate-contracts.sh;
T005 owns the four golden-example documents and tests/test-golden-example.sh.
Their changes are saved but not accepted: finish from the diff, capture exact
Verify with --no-tick, inspect FM/INV mappings and commit each task separately.
Local T004/T005 checks passed 1/1 and 3/3; no acceptance was fabricated.
T003 config catalogs and the original 12-field bindings catalog are documented
in verification-lib.sh. See notes/history.md for schemas, evidence and quota
events. Reuse/carry remain disabled; platform-matrix verification is still T027.

## Next action

On a new resume request, reconcile and accept T004, then T005; next is T006.
Do not automatically resume: user requested a stop. T030/T031 gates and T032
Open PR are pending; T033/T034 remain post-merge.
