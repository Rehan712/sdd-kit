# Opponent25 DRAFT — parent metadata fill required

Project root (EVERY command cwd): `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`.
Paths below are repo-relative. `S` = `.specify/specs/003-gate-round-reduction-and-token-discipline`; `V` = `S/notes/verification`; `R` = `V/reports`. Expand these aliases when opening files.

This is a preparation draft, not a reservation receipt or review verdict. Adopt `agents/opponent.agent.md` for the future independent adversarial pass. Default **CHALLENGED**; earn CLEARED through concrete attacks. Use BLOCKED if required code/dossier is unreachable. Quality-review Ship and green checks cannot predetermine clearance. Opponent owns correctness under untested inputs; reality-check independently owns every-AC evidence and security-reviewer owns security.

## Frozen inputs and parent-owned reservation

- Intended gate/round: opponent/25 after completed 24; source `16ffcec3c2f0cffa21b8c35e7b90d768a27bdfdd37deba9147edd25489946494`; floor `FLOOR-qoRY6H`; reservation UTC **{{RESERVATION_UTC}}**. Reservation exit/state are UNKNOWN in this draft. Do not guess, poll, reserve again or claim exit 0.
- Parent's active native sequence saves prereserve state, validates the EXISTING completed floor through actual `spec-gate.sh round`, then saves reserved state; it never reruns floor checks. Consume its successful validation receipt only when available. Parent promotes to `R/opponent-round25-brief.md` only after result exit 0, actual `V/rounds/opponent/ROUND-25/meta.nul` (gate/round/floor/source/reserved UTC), and full unchanged entries checks all pass.
- Receipts to consume then: `R/s32-op25-reservation/result.json`, `R/r23-state-s32-op25-prereserve.{txt,entries}`, `R/r23-state-s32-op25-reserved.{txt,entries}`. A pending file is not success. This draft did not inspect those evolving reservation files.
- HEAD `2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9`; real index SHA256 `c492d7ea95abf8e8c335001f20c62ff50bc6f1e2179d7a07d30811181b3dd700`; raw STATUS SHA256 `2519b0a153bd7a8548b1b5d6abf3cefaddd6da93d8c5670efba4322dd4c8be1b`; raw tasks SHA256 `bc4acb0ebbe27dd0ec452236e93f90817702cbed45b38db41d92a16fa8a63d17`. STATUS/tasks filesystem modes0600. Preserve bytes, modes and mtimes.
- Actual user Yes, parent-observed `2026-10-26T20:46:28Z`, authorizes OP25 after24 and CI refresh. Read STATUS Decisions709–711 and `R/s29-approval/CLOSED.md`/approval provenance: recorded parser OP25=0/OP26=4; existing RC4-after3 remains approved/unconsumed, RC5=4. Do not author waivers. No OP26, RC5 or merge authorization.

## Read inputs and retain adversarial scope

Read `S/spec.md` (all 23 AC-001–AC-023 and relevant REQs/constraints), `S/plan.md` (grammar, FM-001–FM-020, INV-001–INV-006, registry and seams), `S/tasks.md` (claims, especially T031a5o1/T031a5/T031a6/T029/T030/T031), `S/STATUS.md` Decisions, `.specify/stack.yml`, `constitution.md` and any applicable hub constitution, and prior `S/notes/opponent.md` with focused history ranges. Evidence lines are claims/attack surface, not proof of semantics. Read `R/opponent-round24.md`, `R/opponent-round23.md`, `R/reality-check-round3.md`, and latest pattern `R/s28-opponent-round24-brief.md`.

Perform a full 23-AC relevance sweep starting from FM/INV rows and inspect actual assertions. AC001–006/011/023: authoring, grammar, overlays, legacy compatibility and warning/classifier semantics; AC007–010: floor/checkpoint/reuse/round/tally behavior; AC012–018: schemas, invalidation, briefing, invoker/live separation and guidance/metrics; AC019–023: platform compatibility, provenance, summaries and atomic acceptance. This is an adversarial sweep, not an RC evidence matrix or an unrequested entire-repo audit. Prioritize repair/siblings/consumers, retain explicitly unexamined extent, and expand into unchanged code when evidence exposes a missed assumption. Closed findings need not be reopened without new evidence; tests/FM coverage never exempt behavior.

Read every actual changed file using `R/s32-op25-source-delta.patch` and `.json`. Derived exact C7 snapshot `5aee77672d03a2c7811e28e55172817da6dee012` (tree `d685ec420ba6ce338e72727638e1ccff0bbb3846`) versus current 177 paths from `V/platforms/ci-20261026-s29/source-mapping.tsv`: only `scripts/sdd-analyze.sh`, `tests/test-sdd-analyze.sh`, `S/tasks.md`, `S/STATUS.md` changed; 173 other mapped paths unchanged; no unexpected mapped changes. Tasks includes the new same T031a5o1 and T029 evidence update; STATUS includes approved Decisions. Do not attribute the much larger existing dirty diff against HEAD to O034. This scope comparison covers the mapped source list, not every excluded artifact.

Inspect connected code as warranted: `scripts/sdd-analyze.sh` command extraction/weak_verify/sole warning consumer; `tests/test-sdd-analyze.sh::test_verification_bindings`, `tests/helpers.sh`, `tests/run.sh`; `templates/verification-contract.md`, relevant templates/invokers; `scripts/verification-lib.sh`, `spec-run.sh`, `spec-gate.sh`, `spec-evidence.sh`, `spec-task.sh`; and actual acceptance/floor/report consumers and tests. Earlier unchanged areas may consume prior reviews/current floor with their stated limits; a diff-only review is insufficient.

## Prior findings, repair and controls

Formal opponent 24: CHALLENGED, one blocking **O-034 / verification-command-classification**, wrong-result, implementation-error, Blocks AC-004/REQ-005; unchanged minor O-032. Sealed 24 at `2026-10-26T07:58:27Z`, tally/closure `08:00:37Z`; `R/s28-op24-sealing-result.json` records 0. Nine original O034 forms let operands/search patterns/file-existence checks masquerade as test runners. Current repair classifies executable/runner positions, strips simple unquoted I/O redirections, bounds every runner alternative, and recognizes optional-path-basename grep/rg/diff BEFORE exemptions; tool paths in operands stay operands. Inspect all sibling sites and regression boundaries yourself.

Complete three-file repair quality comparison against C7 before-live-application copies records117 insertions/14 deletions. Read `R/s28-o034-fix/ponytail-review-r1.md`, `R/s28-o034-fix/ponytail-review-r2.md`, `R/s28-o034-fix/ponytail-review-r3.md` and actual invocation/result provenance alongside; HIGH correction responses `review-r1-correction/HANDOFF.md` and `review-r2-correction/HANDOFF.md`. R1 exposed redirects; R2 exposed executable paths; genuine MAX/default/current-provider R3 Ship supplies implementation-quality context only, with no Must/Should/Nice findings. Current loops have 108 weak/56 clean cases plus 4 explicit kind controls; original nine siblings and 69 weak/50 runner cases retained. Retained RED 39 missing warnings/78 assertion failures → GREEN 19/19. Do not rerun historical matrices by default. Bounded shortcut: complex quoting/wrappers need explicit Verify kind; judge actual AC-004/REQ-005, not an invented full-shell-parser promise.

Current analyzer SHA256 `0c26c101666aa8559814f40c7376da6b07290d8e2830b230a54b8eb01b4afdf7`; analyzer-test `513308051dc409e42fe72c3c20d5a0fe4a1e7607e5373dcff404fd6993cf4516`; contract-test `7bc13dde14004bf4ba967c0f64ec120b19bdde641643a6a7436d154c222f893c` (different files).

**O-032 / round-recovery-diagnostics** remains open/degraded/minor, Prior O-032, Blocks none, unchanged library SHA256 `015859de8d68d5cbaffa3ea9078a74584f364312b09cd3c739731fd6716a6c36`. Retain its four locations/trigger from Round24; no kernel repair authorized. O-026/O-027/O-028 remain recorded minor follow-ups, not reassessed or newly cleared. Preserve finding IDs/status/prior references; reconsider impact only with concrete new evidence. No severity softening for cost/round goals or findings invented by forging trusted-workspace records.

## Current evidence, not formal clearance

- Completed new floor: `V/floors/FLOOR-qoRY6H/{meta.nul,commands.nul,inputs.nul,COMPLETE}`. `R/s29-final-floorrun.{rc,wrapper.rc}` both0, `.floor-id` matches; `.source-before.nul`/`.source-after.nul` byte-identical, SHA256 16ff above. Wrapper interval `2026-10-26T22:55:44Z`–`2026-10-27T06:24:04Z`, 26926.25s; floor metadata starts 22:55:57Z. 101 command records = 21 executions + 80 reuses, 22 unique CAPs; receipt capture count 788→809. Native observer `R/s31-floor-completion-observed.json` confirms no restart. Consume parent's existing-floor reservation validation; do not run vf_floor_validate, floor or suites again without concrete invalidation.
- Derived from actual commands.nul, CAP metadata/argv: **CAP-795-FlRr7i**, `/bin/bash -o pipefail -c 'bash tests/test-sdd-analyze.sh'`, exit 0/no_tick 1, 19/19, supplies T031a5/T031a5o1. **CAP-794-aUZ5t0**, same shell options with `bash tests/test-gate-contracts.sh`, exit 0/no_tick 1, 18/18, supplies T031a6/T029. Both meta input_before/input_after are 16ff. Actual files live at `S/notes/captures/<CAP>/`; `V/captures/<CAP>` is the ledger seal, not a directory. No captures were revalidated in preparation. Historical CAP791/source76977, CAP792/sourceDFA, CAP793/sourceE77 and earlier C7 captures are not current proof after STATUS approval.
- Genuine HIGH T029 invoker control: `R/s29-t029-control/result.json` and worker invocation/result provenance; incomplete return rejected 3/binding-mismatch `ACCEPT-I3Eloa`, tasks unchanged, intact accepted 0/`ACC-MkfiB6`, seal-check 0. No rerun. Live dual-gate AC016 probe belongs to later independent RC4, not this draft or opponent report.
- Current hosted CI 40404936939 attempt 1: head `616dd2d1bb0f3eb16045821b0b30b9c9b40f2395`, tested merge `73db38a9551bcbf7fec9df0b5d2d07ddbcf36184`, tree `e68740dbbf9d10e3abcdfd0c6620ed9c3abd04e1`; shellcheck/Ubuntu/macOS/Bash3.2 all succeeded. `V/platforms/ci-20261026-s29/hosted-s30-audit/{result.json,handoff.md,artifact-hashes.json}` plus raw logs and `R/s30-ci-verified.json` record parent rehash of 48 artifacts, strict 177+8+4 before/after/source16ff/protected-state preservation. AC-019 evidence, not RC readiness.

## Future invocation and exact report contract

Intended review identity: `codex_codex_gym / gpt-6.1-sol / reasoningEffort=max / serviceTier=default`. Planned identity is NOT observed identity. Parent will create `R/s32-opponent25-max-invocation.json` only on actual dispatch; reviewer checks live orchestration against it and records only actual provenance. A capacity retry continues the SAME existing ROUND-25, never creates another round. No fabricated legacy handback records/provider claims.

Future independent reviewer owns ONLY new `R/opponent-round25.md` (refuse overwrite) plus parent-assigned excluded probe receipts. Additional focused adversarial checks, if needed, use isolated scratch outside this worktree, preserve useful results under assigned excluded reports; no duplicate whole-project suite. Preserve real source/STATUS/tasks/HEAD/index/captures/accepted records/floor/reservation/history; no complete/tally/probe/waiver/reset. Parent owns canonical-history persistence and byte comparison. Preparation owns no verdict/report.

Follow `agents/opponent.agent.md` EXACT format below. For EVERY established finding include stable Class, Status, Prior, severity, concrete trigger, EVERY file:line, Reproduced command/result OR concrete trigger/reason, process Root cause, AC/REQ Blocks, observed versus required behavior and class-wide fix/sibling/unexamined extent. Group siblings by class, retain raw site counts and unresolved IDs; report every established blocker. Only reproduced/concrete-trigger data-loss/wrong-result/regression/crash block; degraded/style/docs are minor UNLESS an AC/REQ requires the behavior/document/claim, then wrong-result blocks. No taste gates/redesign. Any blocker means CHALLENGED; no blocker after genuine attack may earn CLEARED with justification; unreachable inputs mean BLOCKED.

Return the canonical report block ALONE, byte-identical to `R/opponent-round25.md`, one final LF, no fences/preamble/epilogue. Actual limits/not checked/risks belong before the final marker. Use actual review UTC, source16ff and FLOOR-qoRY6H; do not substitute reservation UTC for report time:

```markdown
## Round 25
**Round:** 25
**Timestamp:** <actual YYYY-MM-DDTHH:MM:SSZ>
**Source:** 16ffcec3c2f0cffa21b8c35e7b90d768a27bdfdd37deba9147edd25489946494
**Floor:** FLOOR-qoRY6H
**Verdict:** CHALLENGED | CLEARED | BLOCKED
**Blocking:** <n> · **Minor:** <n>

### What I attacked
<surfaces, actual assertions, siblings, consumers/contracts, extent and limits>

### Finding O-<preserve or assign ID>
- **Class:** <stable lowercase-hyphen-slug>
- **Status:** new | open | resolved | reopened
- **Prior:** none | <prior finding IDs>
- **Severity:** data-loss | wrong-result | regression | crash | minor | degraded
- **Scenario:** <exact trigger>
- **Where:** <every repo-relative-file:line>
- **Reproduced:** <command/capture/result or concrete trigger and reason>
- **Root cause:** plan-gap | spec-gap | implementation-error
- **Blocks:** <AC/REQ IDs or none>
- **Wrong behavior:** <observed versus required>
- **Class-wide fix:** <repair, sibling sweep, unexamined extent>

### Held up / follow-up tasks
<clearance reasoning or one task per class with all locations; limits/risks>
<!-- gate-round-end: opponent:25 -->
```
