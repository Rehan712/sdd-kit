# T031 — reality-check round 3
Worktree: /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline
Spec: /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline
Written: @@WRITTEN@@ (UTC).
Authorized: reality-check round 3 only (rounds 1-3 need no waiver; the user's decision of 2026-10-15 in Decisions places it after opponent round 20 CLEARED and on its floor). No opponent round, source edits, commits, PRs or bypasses. Write only your report and supporting investigation artifacts under notes/verification/reports/ (prefix them `rc3-`). The invoker owns all canonical gate state, the T029 control, acceptance, completion and STATUS. You are an independent evidence reviewer, not an implementation worker. Do not repair anything, and never mutate live source: focused checks go in standalone scratch copies with a TMPDIR ending in `/`.

Read branch-local agents/reality-check.agent.md, the full spec ACs (spec.md, including REQ-011's revision of 2026-10-14), tasks.md, the relevant plan sections, constitution.md and /Users/babar/.sdd/constitution.md. .specify/stack.yml and .github/workflows/ci.yml are authoritative. STATUS.md's Decisions log carries the full history; read what you need from it.

## Identity (read every value back from the ledgers yourself)
- Reserved: @@RESERVED@@ (reality-check ROUND-3 ledger under notes/verification/rounds/reality-check/).
- Source: @@SOURCE@@ (whole-source digest; HEAD 0d55c62, dirty tree).
- Floor: @@FLOOR@@ — the same floor opponent round 20 was reserved and completed on. @@FLOORRUN@@
- The reservation runs vf_floor_validate over all sealed command captures; consume its recorded successful validation, compare the current source snapshot to the reserved source independently, and script-validate the floor integrity and the captures you rely on. Do not repeat the whole floor validation when the current identity and its validated receipt establish unchanged proof; do not rerun unchanged suites.

## Since round 2 (2026-10-15, NEEDS WORK on source 1f0774dd…, FLOOR-GCDl2x)
Round 2 (`notes/verification/reports/reality-check-round2.md`) found 18 of 23 criteria PASS, including AC-016 and AC-019. AC-007, AC-009, AC-010, AC-020 and AC-022 FAILED only because cases their text names had no fixture (its gaps 1 to 4); its scratch probes showed the shipped code right in each probed case. The user chose to add the tests as T031a1 to T031a4 (test files only, no kernel change; the Decisions entries of 2026-10-15). The whole-source identity changed (three suites and tasks.md), so no round-2 row can be carried: re-evaluate every row against the current captures, and judge whether each new fixture asserts the case its criterion names.
- Live diff: `git diff main -- . ':!.specify/specs/003-gate-round-reduction-and-token-discipline/notes'` (staged and unstaged), plus untracked source inputs via `git ls-files --others --exclude-standard` (filter bookkeeping with vf_bookkeeping_path; do not drop untracked source). Prior reviewed source manifest: round 2's reservation (notes/verification/rounds/reality-check/ROUND-2).
- Opponent: @@OPPONENT@@
- AC-016 live wiring: @@CONTROL@@
- AC-019 hosted CI: @@CI@@
- The last change, accepted 2026-10-15 against CAP-678-tyxcke (15 suites, 147/147, ShellCheck): T031a1 (AC-022, `acceptance_named_cases`), T031a2 (AC-007 and AC-020, `reuse_floor_cases` and `capture_validity_cases` with `gate_execute_fixture`), T031a3 (AC-010, `tally_class_cases` and `annotate_002`) and T031a4 (AC-009, `round_legacy_reconcile_cases`). The user's decisions of 2026-10-14 and 2026-10-15 dropped the invoker's extra proof steps (mutation matrix, independent fixture judging, separate measurement scripts, repeated dev runs); judge the evidence that exists against the ACs, not against the dropped steps.

## Report
Write notes/verification/reports/reality-check-round3.md, beginning exactly with `## Round 3` (no preamble) and ending exactly with:
<!-- gate-round-end: reality-check:3 -->
Use the schema in agents/reality-check.agent.md: Round, UTC Timestamp at or after the reservation, Source (the reserved digest), Floor, Verdict, Agent, Summary, AC matrix, Constitution check, Gaps if any, Re-run conditions. Every one of the 23 ACs appears with its full canonical criterion and revision digest (derive them with vf_ac_catalog). A PASS Evidence cell is exactly `CAP-id; review: <semantic explanation with paths>`, and Affected inputs equals the reserved whole-source digest. FAIL or MISSING rows carry a concrete explanation and the same criterion, digest and source. Default NEEDS WORK; READY only when every criterion has validated direct evidence, including the live AC-016 probe and current hosted CI for AC-019. No silent omissions or softened verdicts. Keep it brief: the report is read by people and by the tally.
