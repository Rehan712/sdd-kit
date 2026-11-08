## Round 24

**Round:** 24
**Timestamp:** 2026-10-26T07:25:24Z
**Source:** c7a82b3ae3b900dcb02a4839decad74db1a13457c5bab9ff859625a5357f0be6
**Floor:** FLOOR-GMlmyY
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 1

### What I attacked

This completes the adversarial review of the same reservation, reserved 2026-10-26T06:56:06Z. The failed MAX r1 invocation produced no report or verdict; its planned attacks are not executed evidence. Actual recovery identity comes from `notes/verification/reports/s28-opponent24-max-retry2-invocation.json`: task suffix `sdd003-s28-opponent24-max-current-provider-retry2`, provider `codex_codex_gym`, model `gpt-6.1-sol`, reasoningEffort `max`, serviceTier `default`.

I read all 23 acceptance criteria, the applicable requirements, plan FM/INV rows and registry, T031a5/T031a6/T029 and gate task blocks, the exact round-24 and reality-check-4 waivers, reservation metadata, complete five-file source delta, opponent23 and RC3's gaps/responses. I inspected the classifier, capture/snapshot/currency and matrix/prior-PASS implementations, their connected callers, fixture helpers, assertion propagation, suite enumeration, verification grammar and invoker guidance. FM-001/005/010/020 and INV-001/005 frame these attacks. Seven inspected runtime/helper/runner files match the prior snapshot; the newly exposed classifier behavior justifies expanding into that unchanged affected implementation.

I consumed the existing reservation's successful floor-validation receipt without validating or executing the real floor again. FLOOR-GMlmyY records 21 executions and 79 reuses. Its current T031a5 proof is CAP-770-AgEMCd, 19/19; T031a6 and T029 use CAP-769-bZPhmg, 18/18. CAP-767/768 and source-A7 captures were not treated as current. The hosted audit and completed T029 rejection/acceptance receipts remain context, not a substitute for inspecting assertions or an RC4 verdict.

Fresh attacks ran only under `/private/tmp/opp24-retry2-dp2syp7l`, using Bash 3.2.57. Preserved scripts, command-specific tasks/output, result receipts and hashes are under `notes/verification/reports/s28-opponent24-max-retry2-probes/`:

- The exact changed classifier loop and existing shell-runner control pass. Removing only `typecheck` recognition or only `tsc --noEmit` recognition separately makes the corresponding new assertion fail, exit 1.
- Eighteen actual analyzer invocations exercise weak commands and runner controls. Nine weak variants wrongly omit the required warning; O-034 groups their shared cause. The input declarations and full analyzer output are retained, rather than inferred from the regex alone.
- The complete current `matrix_runtime_cases` passes in isolation. Its six independent revisions cover implementation, genuinely consumed transitive helper, fixture, lock, config and actual criterion text. I inspected current/reuse refusals, saved/carried PASS refusals, byte-identical old logs and restored positives, plus its retained omission, impact, verdict and corruption controls.
- Removing the current-manifest comparison makes that same test fail with 23 unexpected successes. Separately removing matrix capture validation makes it fail with 12 unexpected successes, including saved and carried PASS. Both exit 1 at behavioral assertions. These are deliberate scratch mutations, not defects attributed to the unmodified runtime. The restoration audit confirms all copied originals match live source again; all 62 preserved probe files match their manifest hashes.

### Finding O-034

- **Class:** verification-command-classification
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** Give an AC-referencing task an untyped Verify of `tsc --noEmit tests/unit.ts`, `npm run typecheck -- --project tests/tsconfig.json`, `grep AC-001 tests/check.sh` or `npm run build -- --outDir tests/build`. Siblings include `test -e README.md`, `test -f README.md`, `grep pytest README.md`, `rg bats README.md` and `diff fixtures/test.txt actual.txt`.
- **Where:** scripts/sdd-analyze.sh:291, scripts/sdd-analyze.sh:292, scripts/sdd-analyze.sh:307, tests/test-sdd-analyze.sh:669
- **Reproduced:** `classifier-edge.sh` and `classifier-siblings.sh` invoke the copied, source-matched public analyzer on actual task declarations. Every listed command returns 0 without `untyped AC Verify`, and reports `consistent`. Bare `npm run typecheck`, `tsc --noEmit` and `grep AC-001 README.md` warn; genuine shell/node/cargo/pytest/bats runners remain accepted. See `classifier-observations.json` and the numbered task/output receipts.
- **Root cause:** implementation-error
- **Blocks:** AC-004, REQ-005
- **Wrong behavior:** The runner exemption searches the entire command for test-looking words or paths before classifying weak verification. A filename or search pattern therefore suppresses the warning without executing a behavioral test. The leading `test` also exempts the file-existence checks the weak branch explicitly names. AC-004 expressly requires more than runner substring matching; the new four-command regression loop does not cover these argument-position cases.
- **Class-wide fix:** Repair the shared classifier so runner recognition uses the command's executable/runner position rather than unrelated argument substrings. Sweep both exemption alternatives and retain genuine shell runners and explicit test/assertion/static/manual controls. Extend the existing loop with the reproduced path, search-pattern and file-existence negatives. This is one shared classifier class, with four cited implementation/consumer/test locations; arbitrary shell syntax beyond these cases was not exhaustively explored.

### Finding O-032

- **Class:** round-recovery-diagnostics
- **Status:** open
- **Prior:** O-032
- **Severity:** degraded
- **Scenario:** Reconcile shipped 002's date-only opponent history, edit that history, then submit a corrected reconciliation naming round 5 and the edited history's digest.
- **Where:** scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3552, scripts/verification-lib.sh:3578, scripts/verification-lib.sh:3584
- **Reproduced:** Retained from opponent23's source-matched boundary probe: corrected reconciliation exits 3 with empty output; removing only stale legacy-time.nul permits the correction. Not rerun here. The current library is byte-identical to that reviewed implementation, SHA-256 `015859de8d68d5cbaffa3ea9078a74584f364312b09cd3c739731fd6716a6c36`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The stale stored reconciliation is rejected before its replacement is examined. It fails closed but supplies neither replacement nor the named manual recovery. The existing four-location minor remains unchanged.
- **Class-wide fix:** Preserve the existing follow-up to permit explicit corrected reconciliation and explain refusals across the legacy-read/reconciliation paths. No kernel repair was authorized in this round.

### Held up / follow-up tasks

Open one class-wide follow-up for O-034 covering the shared classifier, its warning consumer and all reproduced sibling forms. A fresh review must establish that weak commands warn while genuine runners and declared verification kinds remain valid. T031a5's new simple typecheck assertions work, but they do not establish this surrounding contract. T031a6 withstands the focused freshness attacks; no separate substantive freshness defect was established.

O-032 retains its existing minor follow-up. O-026/O-027/O-028 remain recorded minor follow-ups and were not reassessed; they are not new findings or newly cleared items. Prior O-029/O-033 repairs were not reopened without new evidence. No real source, tasks, STATUS, index, captures, floor, reservation or canonical gate history was changed; only the assigned report and excluded probe receipts were written.

Not rerun: the real floor, full suites, hosted CI, T029 control, O-032 probe or historical mutation matrices. Other unchanged and previously unexamined surfaces retain their recorded limits; no RC4 readiness is supplied.
Risk: weak untyped AC checks can silently pass authoring validation until O-034 is repaired; existing minor follow-ups remain open.
<!-- gate-round-end: opponent:24 -->
