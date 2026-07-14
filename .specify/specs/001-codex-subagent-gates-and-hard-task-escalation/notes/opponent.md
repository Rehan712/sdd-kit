# Opponent review — codex-subagent-gates-and-hard-task-escalation

**Date:** 2026-07-14
**Verdict:** CHALLENGED
**Round:** 1

## What I attacked

I re-ran every cheap evidence claim (both test suites, shellcheck, the grep
verifies), independently validated the generated TOMLs against a real TOML
parser, re-ran the generator under bash 3.2.57 (CON-001), and stress-checked
the prune/marker logic and the `PREAMBLE` split for regressions — all held. I
then pressure-tested the two empirical findings (T006/T007) for internal
consistency against the captured evidence and for whether the shipped
user-facing docs overpromise relative to what was actually recorded. That is
where it breaks.

## Findings

1. **Copilot "empirically proven" is shipped as fact with no captured probe** — *severity:* wrong-result (doc-integrity / overpromise)
   - **Scenario:** A user reads `README.md`, or any generated Copilot adapter, and is told Copilot's custom-agent handoff is "empirically proven (model pin included)." They act on it (e.g. greenlight the follow-up spec the knowledge file says is "ready"). But the claim rests on a single hand-typed excerpt, not a reproducible capture.
   - **Where:** `knowledge/cli-subagent-delegation.md:25-48` (the Copilot section is one excerpt line + a warning quote — no transcript); claim propagated to `README.md:167`, `scripts/build-adapters.sh:63` (COPILOT_PREAMBLE, stamped into every copilot adapter), `agents/opponent.agent.md:129`. The only spec-run capture backing AC-008 is `notes/evidence.md` T007 = `grep -icE finding: … → 2` — it verifies the file *mentions* a verdict, it captures no copilot run.
   - **Wrong behavior:** AC-008 required "the captured transcript … in `knowledge/cli-subagent-delegation.md`." What shipped is self-attesting prose. Asymmetric with the Codex finding (real `codex exec` capture in evidence.md T006). For a spec whose thesis is "docs must match recorded findings," an unbacked positive claim in user-facing surfaces is the exact failure mode being guarded against.
   - **Smallest fix:** Re-run the Copilot probe under `spec-run.sh` and paste the real transcript into the knowledge file (+ an evidence.md capture block), or downgrade the shipped "proven" claims until a real capture exists.
   - **Root cause:** implementation-error — the AC asked for a captured transcript; a one-line excerpt plus a grep-of-itself was substituted, and AC-008's Verify was too weak to catch the substitution.
   - **Blocks:** AC-008, REQ-006.

2. **Version stamp contradicts its own captured evidence** — *severity:* wrong-result (doc-integrity), low blast radius
   - **Scenario:** Anyone trusting the "version-stamped" discipline reads "codex-cli 0.144.1" as the tested version.
   - **Where:** `knowledge/cli-subagent-delegation.md:7,17` and `notes/codex-subagents.md:3,31,40` stamp **0.144.1**, but the only captured codex transcript — `notes/evidence.md:77` (a real `spec-run.sh` capture) — shows **OpenAI Codex v0.144.4**.
   - **Wrong behavior:** The artifact states "every claim below is version-stamped," yet its stamp disagrees with its own captured run.
   - **Smallest fix:** Reconcile the stamp to the version the captured run used (0.144.4), or note which binary produced which transcript.
   - **Root cause:** implementation-error.
   - **Blocks:** AC-007, AC-008 (accuracy).

3. **`[hard]` escalation does NOT "match Claude" on the installed Codex, but the spec text still promises it** — *severity:* wrong-result (spec-gap), low
   - **Scenario:** A Codex user tags a task `[hard]` expecting reasoning-tier escalation (as on Claude). It is delegated to `sdd-implement-hard`, which runs at the **session** model (per-agent `model` not honored). Fresh context, but no model escalation; nothing at tag-time warns them.
   - **Where:** `spec.md:82` user story ("so that escalation semantics match Claude") and `spec.md:29-30` problem framing vs. the empirical reality in `notes/codex-subagents.md:33-42`. The generated `CODEX_PREAMBLE` and README hedge this correctly — it is the *spec's own* user story and problem statement that were not updated.
   - **Wrong behavior:** The specific harm the spec says it fixes ("[hard] silently runs at implementation tier") is not fixed on this Codex — it is relabeled with fresh context. The user story's promise is unmet.
   - **Smallest fix:** Reword `spec.md` §1 / the user story to "fresh-context escalation (model escalation pending Codex honoring per-agent model)".
   - **Root cause:** spec-gap — the framing wrote a promise the empirically-discovered reality can't meet on the installed binary.
   - **Blocks:** REQ-003 (partial), User stories §5.

## Minor (non-blocking)

- The `head -1 | grep -qF` marker check under `set -o pipefail`: in practice never fires (AC-002 exercises it); awareness only.
- `test_delegation_findings_artifact_present_and_shaped` asserts the loose prefix `"codex-cli 0.144"` — blind to Finding 2's mismatch; a test blind spot, not a break.

## Follow-up tasks proposed

- T010o1 — Capture the Copilot probe for real (run under `spec-run.sh`, paste transcript into `knowledge/cli-subagent-delegation.md`) OR downgrade the shipped "proven" claims until captured (→ Finding 1)
- T010o2 — Reconcile the codex version stamp (0.144.1 vs captured 0.144.4) across the knowledge file and `notes/codex-subagents.md` (→ Finding 2)
- T010o3 — Reword `spec.md` §1 + user story so the `[hard]`-escalation promise matches the hedged generated docs (→ Finding 3)
