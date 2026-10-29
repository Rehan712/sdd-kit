## Round 26
**Round:** 26
**Timestamp:** 2026-10-29T11:35:29Z
**Source:** f156c52ee62d1b430b10a302bbba23e3d2f63cecfadd487cfc3571d6ce7d9ee0
**Floor:** FLOOR-LxJkv3
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 1

### What I attacked

This is the genuine independent assessment of the existing reservation of 2026-10-29T11:11:14Z. The read-only live runtime and the actual `s47-opponent26-max-invocation.json` receipt agree on `codex_codex_gym / gpt-6.1-sol / reasoningEffort=max / serviceTier=default`. No substitution, nested agent or additional reservation occurred. I read the complete ready brief; its SHA-256 is `a6b7991e86f18b2371ea966dc09984761602d219a46ebd122d0d1beb0ae58d6d`.

I independently read all 23 ACs, applicable requirements/constraints, plan FM-001–FM-020, INV-001–INV-006, grammar/registry/seams, relevant task claims including T031a5o1/T031a5/T031a6/T029/T030/T031, relevant STATUS Decisions, both constitutions and stack configuration. I read opponent23–25, relevant canonical finding history, RC3, the complete current O-034 repair and connected callers/assertions, quality r5 and retained fixture/provenance receipts. Quality Ship and green checks did not determine this verdict.

The 177-path comparison against C7 independently confirms four changed mapped files: analyzer, analyzer tests, tasks and STATUS; 173 remain unchanged. All 177 current raw hashes match the current hosted source mapping. Git's non-executable 100644 mapping is consistent with the existing mode600 documents. The regenerated repair diff matches the supplied r5 analyzer/test hunks; its sole additional difference is T029's later Evidence refresh from CAP-817 to CAP-819. The larger dirty HEAD diff is pre-existing spec work. Scope receipts and the explicit 23-row relevance sweep are under `notes/verification/reports/s47-opponent26-max-probes/`.

The relevance sweep inspected actual assertions and affected consumers:

- AC-001–AC-006, AC-011 and AC-023: phase-aware/shared/dangling/quoted bindings, local test ownership, all four verification kinds, golden-example assertions, all 14 overlay defaults, command configuration and shipped compatibility. I read the whole changed analyzer/test, its sole weak-warning caller, warning aggregation, `t_fail`/`t_run_all` and suite failure propagation.
- AC-007–AC-010: checker/suite counters, real failure and pipeline/next-stage controls, lost retained bindings, exact-second legacy reconciliation, both gates' caps and pending-round controls, class/site/lifecycle assertions and unchanged history checks. O-032 remains the known recovery limitation; closed findings were not reopened without new evidence.
- AC-012–AC-018: report fields and retained scope, saved/carried PASS consumers, briefing/adapter assertions, invoker trace/stop/escalation controls, actual-or-unknown metrics, public help and all nine documented workflow-command assertions. The current T029 rejection/acceptance is existing context; the later authentic dual-gate AC-016 observation remains RC4's responsibility.
- AC-019–AC-022: source enumeration and fixture isolation, Bash portability, summary byte/line/raw-log/argv/exit assertions, snapshot/capture currency, exact return bindings and atomic acceptance. I inspected T031a6's independently consumed implementation/helper/fixture/lock/config/criterion revisions, unchanged old logs and restored positives, plus current/reuse and saved/carried refusal assertions. These unchanged mechanisms were read, not rerun as another acceptance or mutation matrix.

I consumed the successful existing-floor reservation validation. Independently rehashed floor/reservation seals and raw entries agree: FLOOR-LxJkv3 has 101 records, 5 executions, 96 reuses and 22 unique captures; its input digest is the reviewed source. CAP-818-fLEvh7 records analyzer 19/19 and CAP-819-05nYhW records contracts 18/18, both sealed, no-tick and with identical sourcef156 before/after manifests. Current suite/static capture seals and the retained four-job hosted-CI mapping were inspected. No floor validator, full suite, CI action, capture, acceptance or live-control run was started here.

The reservation kernel genuinely exited 0, with 6,860 raw entries byte-identical at SHA-256 `3ca12e69830dd1f06b6b985847aafd6b54614c068e22167598b00ee835825731`. Its native wrapper genuinely exited 1 after including its own new growing log in its baseline. The preserved ownership observation establishes unchanged pre-invocation originals; it does not turn that wrapper exit into 0. Historical floor preservation failures involving .DS_Store and the generated verifier's global-refs field remain preserved, not repaired or attributed to source corruption.

Fresh focused probes ran outside the worktree with the unmodified, source-matched public analyzer under Bash 3.2.57. Exact scripts, declarations, argv, stdout/stderr, results and hashes are retained in the assigned probe directory:

- `focused-classifier-probes.py`: 181 public cases. All nine original OP24 cases, 48 OP25 noclobber variants, 48 other weak redirect cases, 48 redirected-runner cases and the numeric/operand/control cases meet their expectations. Sixteen newly examined qualified weak executables omit the required warning.
- `qualified-executable-probe.py`: 29 further public cases produce 20 omissions and nine passing controls. A separate new-contract fixture containing explicit test/assertion/static/manual kinds stays consistent. Across both batches, there are 211 public-analyzer invocations including that combined kind control, with 36 omission observations covering 28 distinct commands.
- Four direct owned-fixture executions compare `tests/test` and `tools/test`, both symlinks to the same real `/bin/test` binary, SHA-256 `da6c640b2c20476df1bd9d852ff87df56efde7e3a0eeaa010857703f7bf9fcdb`. Both return 0 for an existing README and 1 after its removal, with empty output. Their corresponding analyzer declarations differ solely in executable path: the tests path suppresses the warning; the tools path warns. No task-supplied Verify string was executed and no stub was put in the analyzer's PATH.

The two literal-concatenation fixture builders are present. Retained fixed Bash3.2/Bash5.2-on/Bash5.2-off raw array streams are byte-identical to the old Bash3.2 baseline, with declared totals 287 weak/162 clean; the historical option-on corruption remains retained. I did not rerun a modern-Bash or historical fixture matrix. The original and redirect repairs hold within the cases above, but the executable-path sibling below prevents class clearance.

### Finding O-034

- **Class:** verification-command-classification
- **Status:** open
- **Prior:** O-034
- **Severity:** wrong-result
- **Scenario:** An AC-referencing task has an untyped Verify of `./tests/node_modules/.bin/tsc --noEmit tests/unit.ts`, `./tests/npm run build`, `./tests/npm run typecheck` or `./tests/test -f README.md`. Equivalent test/, tests/ and nested tools/tests/ executable prefixes also suppress the warning. All eight supported unquoted redirects retain the omission for `./tests/npm<operator/target> run typecheck`, including attached `>|out.txt`.
- **Where:** scripts/sdd-analyze.sh:296, scripts/sdd-analyze.sh:299, scripts/sdd-analyze.sh:313, tests/test-sdd-analyze.sh:668
- **Reproduced:** Run the retained `focused-classifier-probes.py` and `qualified-executable-probe.py` with GIT_OPTIONAL_LOCKS=0 from the assigned worktree. Their `public-classifier/results.json`, `qualified-executable/results.json` and `attack-summary.json` preserve 36 warning omissions across 28 distinct direct commands. Each affected public-analyzer invocation exits 0 and reports consistent. Corresponding tools/ controls warn. The second probe's four direct /bin/test observations establish that the concrete presence-only pair performs identical non-behavioral checks despite the different authoring verdicts.
- **Root cause:** implementation-error
- **Blocks:** AC-004, REQ-005
- **Wrong behavior:** The generic test-path exemption at line296 returns before the known typecheck/build/file-existence branch at line299. The repair correctly checks grep/rg/diff basenames before that exemption, but leaves these other known weak forms after it. A directory component therefore turns a direct known weak executable into supposed behavioral-test evidence. These simple unquoted commands require no wrapper, compound syntax or general shell parser. The current regression matrix qualifies the text-tool basenames but omits qualified tsc/package-build/file-existence siblings. This is the same warning-classification defect at four cited implementation/consumer/test locations, not a new class or merely missing RC evidence.
- **Class-wide fix:** Classify known weak executable/argument forms before the generic test-path exemption, retaining genuine script runners, package test subcommands and explicit kinds. Extend the existing public-analyzer assertions with these qualified basenames, nested test dependency paths, neutral-path counterparts and the eight redirect siblings. Preserve the passing original, noclobber, numeric &>, runner and operand controls. Arbitrary quoting, wrappers, heredocs and compound checks retain the explicit-kind/repository-script limit; their exhaustive classification is not demanded here.

### Finding O-032

- **Class:** round-recovery-diagnostics
- **Status:** open
- **Prior:** O-032
- **Severity:** degraded
- **Scenario:** Reconcile shipped 002's date-only opponent history, edit that history, then submit a corrected reconciliation naming round5 and the edited history's digest.
- **Where:** scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3552, scripts/verification-lib.sh:3578, scripts/verification-lib.sh:3584
- **Reproduced:** Retained from the source-matched opponent23–25 observations: corrected reconciliation exits 3 with empty output; removing only stale legacy-time.nul permits correction. Not rerun here. The inspected current library remains SHA-256 `015859de8d68d5cbaffa3ea9078a74584f364312b09cd3c739731fd6716a6c36`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Stale stored reconciliation fails the history read before replacement is examined. It fails closed without naming the effective manual recovery. The existing four-location minor remains unchanged.
- **Class-wide fix:** Retain the existing follow-up for corrected reconciliation and named diagnostics across the legacy history/reconciliation paths. No kernel or minor-finding repair was performed.

### Held up / follow-up tasks

Keep one class-wide O-034 follow-up covering all four listed sites and the reproduced executable-path/redirect siblings. The original forms now hold, but O-034 remains open and blocking under AC-004/REQ-005. O-032 retains its existing minor follow-up. This round records two unresolved finding IDs at eight cited locations. O-026/O-027/O-028 remain previously recorded, unassessed minor follow-ups; they are not newly cleared or recounted as new observations here. No separate substantive acceptance, currency, invalidation or fixture-construction defect was established in the inspected scope.

The protection inventory covers 22,822 pre-existing worktree entries, including 20,750 files. All original worktree files retain bytes/modes/mtimes; protected external Git files, the real index, HEAD, STATUS, tasks and source remain unchanged. My worktree writes are only this new report and new assigned probe files; the sole allowed concurrent file addition is the exact parent invocation receipt. New authorized children necessarily change the reports/probe directory mtimes, which were retained.

Full preservation is FALSE: the strict comparison observed one new `refs/t3/orchestration-v2/checkpoints/MTJlM2E2YWEzNGFmOGNhN2FiN2U1MGMwODY5MGMzMDU/ordinal/18` ref, pointing to `2e1a843f90e46d7358698a7ac47dc7eacd25b526`, during this review. Attribution is unknown; no ref-writing command was run by this review. The spec branch ref is unchanged. `protection-pre-report.json` preserves the strict exit1; `global-ref-observation.json` records the exact difference. No ref was reverted or added to the allowlist, and no broad preservation exception was granted.

The parent owns authentic history append, completion and tally after this return. This report supplies only the formal OP26 verdict, no RC4/readiness/merge verdict and no authorization of OP27 or any other round. The canonical file has one terminal LF; a UI return omitting that LF must not be described as a literal byte match.

Not checked again: whole floor/full suites, floor validator, fresh hosted/platform execution, historical mutation matrices, O-032 reproduction or the live AC-016 probe. Unchanged and otherwise unexamined surfaces retain the stated limits.
Risk: direct build/typecheck/file-presence checks can still miss the required warning through test-looking executable paths; existing minor follow-ups and the recorded global-ref preservation discrepancy remain open.
<!-- gate-round-end: opponent:26 -->
