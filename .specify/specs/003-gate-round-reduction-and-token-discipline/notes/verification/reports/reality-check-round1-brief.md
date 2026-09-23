# T031 — first independent reality-check
Worktree: /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline
Spec: /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline
Authorized: reality-check round 1 only. No opponent round, source edits, commits, PRs, bypasses or round-9 waiver. Write only your report and supporting investigation artifacts under notes/verification/reports/. Invoker owns all canonical gate state, control acceptance, completion and STATUS. You are an independent evidence reviewer, not an implementation worker. Do not repair anything.

Read branch-local agents/reality-check.agent.md, the full spec ACs and tasks, relevant plan sections, constitution.md and /Users/babar/.sdd/constitution.md. No local AGENTS.md or matching stack overlay was found. .specify/stack.yml and .github/workflows/ci.yml are authoritative. STATUS.md was read completely by invoker; its full Decisions history remains available without copying it into this brief.

Use the live diff: git diff main -- . ':!.specify/specs/003-gate-round-reduction-and-token-discipline/notes'
This includes staged and unstaged work. Also inspect untracked source inputs via git ls-files --others --exclude-standard (filter bookkeeping using vf_bookkeeping_path; do not drop untracked source). HEAD is 0d55c62 and the tree is dirty. Review every AC, not merely the latest repairs.

Reservation/floor identities will be supplied after sealing/reserving. Read ledger metadata back. The reservation runs vf_floor_validate over all sealed command captures; consume its recorded successful validation, independently compare the current source snapshot to the reserved source, and script-validate the floor integrity and relevant captures before reuse. Do not repeat the entire expensive floor validation when current identity and its validated receipt establish unchanged proof. Reuse only script-validated evidence; do not duplicate unchanged suite runs. Additional focused checks are allowed in isolated scratch copies; never mutate live source. Preserve actual command exit statuses and retained logs; no suite pipelines through tail.

Entry audit: notes/verification/reports/t031-entry-check.log and .rc (0), t031-entry/inputs.nul.
T030o37 (O-004 + D1) and T030o38 (O-002) were accepted against CAP-366-H7QjI6. Both receipts and capture integrity/currentness passed before Decisions changed for this run. Historical targeted evidence: repair-mutations-tightened.log (19 killed, baseline 0, restoration confirmed), repair-handoff-check.log, repair-accept-o37.log, repair-accept-o38.log. These are observations to audit, not substitute gate clearance.
notes/opponent.md contains eight sealed rounds; vf_round_history validated all extracted-block digests. Latest verdict CHALLENGED, digest b391edbf50604425aeea7fcdf8dd2b37d0d2d30c87e8b00a4179e3feed4d12cd. Round 9 denied, six candidates. Reality-check has zero earlier rounds and no carried rows.

Retain full review scope, including previously unexamined umbrella/multi-repo roots, acceptance crash windows, reality-check carry, r-suffix followups, Linux/CI behavior, per-negative branch coverage and AC-014/017/018 prose. Latest repairs: strictest severity fold in reports and tally, D1 whitespace fixtures, finite literal Bash dispatcher reader and documentation checks. Opponent-only totals/downgrade guards remain opponent-only; independently assess their relevance against ACs. Omission/open-state tracking was deferred; do not redesign the spec.

Known obligations to independently judge:
- T031 Inputs names a CLEARED T030 report; actual opponent remains CHALLENGED. User expressly authorized this first reality-check despite that state. No opponent clearance can be invented.
- Typed AC-016 control is notes/verification/handoff/control-t029.sh <current gate-contract capture>. Invoker runs it, preserves rejection/acceptance events and then runs tests/probe-gate-contract.sh during your reservation. The probe requires CURRENT floors for both gates (see source); completed opponent floor is stale. Do not waive the failure or fabricate live evidence.
- AC-019 needs real current Linux/macOS/Bash 3.2 evidence. Historical platforms/ logs do not prove newly changed code; normal PR CI is later and no PR is authorized.
- Existing prose gaps (return-block grammar/completion marker) are claims to assess against the exact ACs.

Write notes/verification/reports/reality-check-round1.md, beginning exactly with ## Round 1 (no preamble) and ending exactly:
<!-- gate-round-end: reality-check:1 -->
Use schema from agents/reality-check.agent.md with Round, UTC Timestamp >= reservation, Source, Floor, Verdict, Summary, AC matrix, Constitution check, Gaps if applicable, Re-run conditions. Every one of the 23 ACs must appear with full canonical criterion/revision digest (derive using vf_ac_catalog). A PASS Evidence cell is exactly CAP-id; review: semantic explanation with paths, and Affected inputs equals reserved whole-source digest. FAIL/MISSING rows require concrete explanation and same criterion/digest/source. NEEDS WORK by default; READY only when every criterion has validated direct evidence including live AC-016. No silent omissions or softened verdicts.

