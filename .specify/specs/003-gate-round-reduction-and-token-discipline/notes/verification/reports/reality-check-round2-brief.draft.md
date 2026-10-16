# T031 — reality-check round 2
Worktree: /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline
Spec: /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline
Written: @@WRITTEN@@ (UTC).
Authorized: reality-check round 2 only (rounds 1-3 need no waiver; the user's decision of 2026-10-14 in Decisions, item 3, places it after opponent round 19 and on its floor). No opponent round, source edits, commits, PRs or bypasses. Write only your report and supporting investigation artifacts under notes/verification/reports/ (prefix them `rc2-`). The invoker owns all canonical gate state, the T029 control, acceptance, completion and STATUS. You are an independent evidence reviewer, not an implementation worker. Do not repair anything, and never mutate live source: focused checks go in standalone scratch copies with a TMPDIR ending in `/`.

Read branch-local agents/reality-check.agent.md, the full spec ACs (spec.md, including REQ-011's revision of 2026-10-14), tasks.md, the relevant plan sections, constitution.md and /Users/babar/.sdd/constitution.md. .specify/stack.yml and .github/workflows/ci.yml are authoritative. STATUS.md's Decisions log carries the full history; read what you need from it.

## Identity (read every value back from the ledgers yourself)
- Reserved: @@RESERVED@@ (reality-check ROUND-2 ledger under notes/verification/rounds/reality-check/).
- Source: @@SOURCE@@ (whole-source digest; HEAD 0d55c62, dirty tree).
- Floor: @@FLOOR@@ — the same floor opponent round 19 was reserved and completed on. @@FLOORRUN@@
- The reservation runs vf_floor_validate over all sealed command captures; consume its recorded successful validation, compare the current source snapshot to the reserved source independently, and script-validate the floor integrity and the captures you rely on. Do not repeat the whole floor validation when the current identity and its validated receipt establish unchanged proof; do not rerun unchanged suites.

## Since round 1 (2026-09-20, NEEDS WORK on source 09a0a919…, FLOOR-NbXfe5)
Round 1 found 21 of 23 criteria with current direct evidence. AC-016 failed: the live probe exited 3 with no current opponent reservation/floor observation. AC-019 lacked current Linux/CI-matrix evidence for that source. Every row must be re-evaluated: the source has changed since round 1 (opponent rounds 9-19 and their repairs, T030o39 through T030o56), so no round-1 row can be carried.
- Live diff: `git diff main -- . ':!.specify/specs/003-gate-round-reduction-and-token-discipline/notes'` (staged and unstaged), plus untracked source inputs via `git ls-files --others --exclude-standard` (filter bookkeeping with vf_bookkeeping_path; do not drop untracked source). Prior reviewed source manifest: round 1's reservation (notes/verification/rounds/reality-check/ROUND-1).
- Opponent: @@OPPONENT@@
- AC-016 live wiring: @@CONTROL@@
- AC-019 hosted CI: @@CI@@
- The last repairs, accepted 2026-10-15 against CAP-656-JZJTKB (15 suites, 147/147, ShellCheck): T030o54 (O-018), T030o55 (O-025) and T030o56 (O-023). The user's decision of 2026-10-14 dropped the invoker's extra proof steps (mutation matrix, independent fixture judging, separate measurement scripts, repeated dev runs); judge the evidence that exists against the ACs, not against the dropped steps.

## Report
Write notes/verification/reports/reality-check-round2.md, beginning exactly with `## Round 2` (no preamble) and ending exactly with:
<!-- gate-round-end: reality-check:2 -->
Use the schema in agents/reality-check.agent.md: Round, UTC Timestamp at or after the reservation, Source (the reserved digest), Floor, Verdict, Agent, Summary, AC matrix, Constitution check, Gaps if any, Re-run conditions. Every one of the 23 ACs appears with its full canonical criterion and revision digest (derive them with vf_ac_catalog). A PASS Evidence cell is exactly `CAP-id; review: <semantic explanation with paths>`, and Affected inputs equals the reserved whole-source digest. FAIL or MISSING rows carry a concrete explanation and the same criterion, digest and source. Default NEEDS WORK; READY only when every criterion has validated direct evidence, including the live AC-016 probe and current hosted CI for AC-019. No silent omissions or softened verdicts. Keep it brief: the report is read by people and by the tally.
