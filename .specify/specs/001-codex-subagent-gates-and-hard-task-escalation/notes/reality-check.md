# Reality Check — 001-codex-subagent-gates-and-hard-task-escalation

**Date:** 2026-07-14
**Verdict:** READY
**Agent:** reality-check (hub default)

## Summary

Independently re-ran every runnable acceptance check — full test suite (green,
exit 0), `shellcheck -S warning -x` (clean), both deterministic floor scripts
(AC↔test binding: bound; evidence integrity: sound), and a from-scratch
hermetic generation of the three subagent TOMLs — each reproduced the claimed
result. The two empirical ACs (AC-007 codex, AC-008 copilot) rest on real
captured CLI transcripts in `notes/evidence.md`; verified by capture-block
integrity and internal consistency per the dossier's cost constraint. All
three opponent rounds' demanded fixes are present on HEAD. Every AC-001..008
has direct, observable evidence.

## AC matrix

| AC | Criterion | Evidence | Verdict |
|----|-----------|----------|---------|
| AC-001 | 3 TOMLs with name/description/instructions/model/effort | Hermetic gen: marker line 1, identity + `model="gpt-5.5"` + `model_reasoning_effort="xhigh"` + persona body; `tests/run.sh build-adapters` 6/6 | PASS |
| AC-002 | Marker-based prune; user TOMLs untouched | Hermetic run: unmarked `my-own-agent.toml` survives; marked stale `sdd-bogus.toml` pruned | PASS |
| AC-003 | No policy / no ~/.codex → degrade silently | Both branches: exit 0, empty stderr, nothing written/created | PASS |
| AC-004 | Codex adapters delegate; Copilot adapters persona-pass | Generated skills grep: sdd-opponent/sdd-implement-hard/"fall back" in codex; persona-pass only in copilot | PASS |
| AC-005 | ultra/max/none accepted; junk rejected; check green; claude unchanged | Direct --file runs: all as specified; `tests/run.sh model-policy` 3/3 | PASS |
| AC-006 | Stale claims gone from 5 surfaces; each states subagent path + fallback | Exact-phrase grep: only accurate Copilot wording remains; `test_stale_single_agent_claims_are_gone` passes | PASS |
| AC-007 | Captured codex run: TOMLs accepted, subagent spawns | evidence.md T006 (sha256:287fa029fdc0): v0.144.4 banner, no parse error, "The sdd-opponent agent said: READY" | PASS |
| AC-008 | Copilot transcript + finding in knowledge/; no unproven delegation promise | T010o1 (sha256:3f5e4d23af7d) + T010o4 discriminating capture (sha256:ed3cb1d6e84c, three distinct child models); docs promise only "proven possible, wiring is a follow-up" | PASS |

## Constitution check

- §10.5 gates subagent-when-available + fallback — PASS (constitution.md:92 is itself an AC-006 surface, correct).
- §10.8 evidence-not-claims — PASS (`spec-evidence.sh` sound; empirical ACs captured via spec-run, the discipline Round-1 Finding 1 enforced).
- §10.6 deterministic checks as scripts — PASS. CON-001/002/003 — PASS (bash 3.2 re-run by the opponent; personal scope only; marker-keyed prune).

## Gaps

None.

## Deferred to post-deploy

None. MET-001 (gate-report provenance on the next Codex-dispatched spec) is a success metric owned by T013 + the retro, not a gate item.

## Re-run conditions

Verdict is READY — proceed to Ship (T012). If any kit file changes before merge, re-run `tests/run.sh` + `shellcheck` and re-confirm the matrix.
