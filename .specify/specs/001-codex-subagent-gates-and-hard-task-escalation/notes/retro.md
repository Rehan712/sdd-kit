# Retro — codex-subagent-gates-and-hard-task-escalation

**Date:** 2026-07-14
**Shipped:** https://github.com/Rehan712/sdd-kit/pull/12 (merged 889631a) → port https://github.com/Rehan712/sdd-kit-private/pull/12 (5b4d884) → live `setup.sh` (three `~/.codex/agents/sdd-*.toml` materialized)
**Rounds:** opponent 3, reality-check 1
**Tasks:** 14 planned → 18 final (4 opponent follow-ups T010o1–T010o4, 0 reality-check, 0 security, 0 CI/review)

## What the gates caught (defect classes)

| # | Defect | Class | Root cause | Caught by | Prevention |
|---|--------|-------|------------|-----------|------------|
| 1 | Copilot handoff shipped as "empirically proven" on a hand-typed excerpt; the only evidence capture was a grep of the knowledge file itself (T010o1) | doc-integrity / self-attesting evidence | implementation-error | opponent R1 F1 | Empirical-claim tasks' *Verify:* must re-run the probe under spec-run.sh, never grep the artifact asserting the claim |
| 2 | Findings stamped codex-cli 0.144.1 while the captured transcript's banner reads v0.144.4 — binary auto-updated mid-session (T010o2) | doc-integrity / version drift | implementation-error | opponent R1 F2 | Stamp versions from the captured run's own banner, not from session memory |
| 3 | spec.md §1 + user story kept promising "[hard] escalation semantics match Claude" after T006 recorded that installed Codex ignores per-agent model pins; only the generated docs hedged (T010o3) | overpromise / spec drift | spec-gap | opponent R1 F3 | When an empirical AC disproves a spec promise, revise spec.md in the same pass as the outward docs |
| 4 | "Per-agent model IS honored" (Copilot) proved with a pin equal to the known session-default model — observation equally consistent with pin-ignored inheritance (T010o4) | experiment design / non-discriminating probe | implementation-error | opponent R2 F1 | Pin values distinct from environment defaults; several distinct pins in one session falsify inheritance outright |

**Root-cause split:** plan-gap 0 · spec-gap 1 · implementation-error 3 — implementation-error dominant, but all three are *evidence-integrity* errors in empirical/doc tasks, not code-execution failures: the code (generator, whitelist, tests) survived all three adversarial rounds untouched. The tuning target is probe/Verify discipline at tasks time (filed to `knowledge/deterministic-gates.md`), not `[hard]` tagging or a model bump — no task failed on reasoning capacity.

## Lessons filed

- **Self-attesting evidence is the grep-instead-of-run failure: an empirical-claim task's Verify must re-run the probe, not inspect the prose asserting it** → `knowledge/deterministic-gates.md` ("Behavioral ACs need a live run" strengthened) (applied)
- **Empirical probes must be able to falsify the null hypothesis — pin values distinct from defaults; stamp versions from the capture's banner; flow disproven promises back into spec.md** → `knowledge/deterministic-gates.md` (new section) (applied)
- No stack-overlay amendments — bash+markdown kit work, `stacks: []`.
- No constitution changes proposed — §10.8 (evidence-not-claims) already covers the doctrine; the failures were in applying it to *empirical* claims, which the knowledge entries now spell out.

## Success metrics check

- MET-001: not yet measurable — requires the next Codex-dispatched spec's gate reports to record subagent provenance (Agent line naming `sdd-opponent`/`sdd-reality-check`, not a persona pass). Check at that spec's retro; check-back noted in STATUS Next action.

## What went well

- Empirical ACs (AC-007/AC-008) ran EARLY in the Tests stage per plan R1 — the wrong-shape risk was retired against the real binary before any doc task could inherit a false claim.
- The hermetic-sandbox seam (copy kit into `$SANDBOX`, run with `HOME=$SANDBOX/home`) delivered adapter tests with zero script changes for testability; both new suites reused it and reproduced under CI's bash-3.2 job unchanged.
- Every opponent round independently re-ran the full cheap-evidence matrix (suites, shellcheck, TOML parse); both fix-rounds were verified against HEAD before CLEARED — no fix-induced regression shipped.
- spec-run.sh captures with sha256 stamps made the Round-2/Round-3 adjudication mechanical: the discriminating T010o4 transcript alone settled the inheritance question.
- The port-follows-merge pattern (CON-004) held: kit-file baseline between repos was byte-identical, so the private port was a clean 10-file copy with the full suite green on both CIs.
