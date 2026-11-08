## Round 27
**Round:** 27
**Timestamp:** 2026-10-30T13:17:01Z
**Source:** 7d4f17221f13d850cb7db06cdbb6261119ca97b52228adeac74d82f6496a9bff
**Floor:** FLOOR-DJZyNl
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 1

### What I attacked

This is the independent formal opponent assessment of the existing reservation of 2026-10-30T12:49:20Z. Read-only `t3_thread_configure({})` actually returned provider instance `codex`, model `gpt-6.1-sol`, `reasoningEffort=max`, `serviceTier=default`; these match the requested settings. The authentic response and comparison are saved in `notes/verification/reports/s67-opponent27-max-probes/runtime-config.json` and `runtime-identity-check.json`. I performed this review myself. No nested agent, model CLI, provider substitution or additional reservation was used. I read the full 17,022-byte standalone brief, SHA-256 `203f7ffaedb02e8c534a95f7c3de17cd402ce3d0ea32483ef7a0237074b38792`.

I read all 23 ACs and applicable requirements/constraints, the complete plan including FM-001–FM-020, INV-001–INV-006, grammar/registry/seams, relevant task claims including T031a5o1/T031a5/T031a6/T029/T030/T031, current authorization and relevant STATUS Decisions, both constitutions and stack configuration. I inspected opponent23–26, relevant canonical finding history and RC3. The genuine quality-r6 Ship result is context; it supplies no formal clearance and did not determine this verdict.

All 177 current source mappings match the frozen snapshot's raw bytes, Git blobs, modes and recorded mtimes; all 177 mapped index entries match the real index. I read the complete O-034 repair diff and independently reconstructed the latest analyzer/test diff from the saved pre-OP26-correction copies: it matches the supplied code/test hunks exactly. Analyzer, analyzer-test and distinct contract-test hashes match the brief. The larger dirty HEAD delta is preexisting spec work. These comparisons are retained in `source-scope-audit.json`.

The 23-row `ac-relevance-sweep.json` records inspected assertions, FM/INV relevance, consumers and limits. This is a correctness relevance sweep, not a reality-check evidence verdict:

- AC-001–AC-006, AC-011 and AC-023: phase-aware/shared/duplicate/dangling/quoted bindings, exact local test ownership, explicit verification kinds, golden-example assertions, all 14 actual overlay defaults, command-configuration errors and legacy compatibility. I traced the complete changed classifier, command extraction, its sole warning consumer, warning aggregation and assertion/suite failure propagation.
- AC-007–AC-010: checker/suite counters, source/command reuse boundaries, real failure and pipeline/next-stage controls, lost retained coverage, both gates' caps and pending-round handling, authorization/history consumers and class/site/lifecycle assertions. O-032 remains the known recovery limitation.
- AC-012–AC-018: report schema and retained review scope, current/saved/carried PASS consumers, briefing/adapter assertions, invoker trace/stop/escalation controls, typed follow-ups, actual-or-unknown metrics and the nine documented workflow-command assertions. I inspected the live-probe bootstrap/control assertions and current T029 receipts without executing another live control or issuing a readiness verdict.
- AC-019–AC-022: source enumeration, fixture/environment isolation, portability, measured summary/log/argv/exit assertions, capture currency, exact return bindings, manual-proof separation and atomic acceptance/ownership consumers. T031a6's six independently consumed input revisions, unchanged old logs, current/reuse/saved/carried refusals and restored positives were inspected, not rerun.

I consumed the existing reservation's successful kernel validation without invoking another floor validator. Independent byte inspection confirms the pending seal and FLOOR-DJZyNl's five sealed members, reviewed source digest, 101 records, 20 executions, 81 reuses and 22 unique captures. CAP-844-GCqKod records contracts 18/18 and CAP-845-hwbWOH records analyzer 19/19; their seven sealed members rehash, both are no-tick, and both before/after manifests equal the reviewed source. Current rejection/acceptance receipts retain the genuine T029 control and subsequent analyzer acceptance; historical failed delegates and terminal-LF comparisons were not rewritten.

I independently rehashed all 35 retained hosted artifacts and all four job logs for run40966033511 attempt1. Their successful jobs identify tested merge `70b8ab820abbbaf2792d822c0bad117d91c363a2`; the saved API reply binds its tree to snapshot `e75b3027023ef251fa0c531c96f2b8276aa980ae`. The snapshot's tree/parent were also read locally. The tested merge object is absent locally: the read-only Git lookup returned128; I did not fetch it. This is retained evidence inspection, not fresh CI execution.

Fresh attacks used the unmodified public analyzer under Bash3.2.57, with explicit worktree cwd and GIT_OPTIONAL_LOCKS=0 in every launch/subprocess environment. Task Verify strings were declarations only and were never executed. No executable PATH stubs were added. Scripts, exact declarations, analyzer argv/cwd/nonsecret environment, full stdout/stderr, results and hash proofs are retained in the assigned probes:

- `classifier-probes.py`: 175 declarations plus one combined new-contract four-kind control, 176 public invocations. Qualified known tools, all eight redirect families, original O-034 inputs, numeric-word boundaries, genuine runners, operands and basename-boundary controls hold. Six newly examined direct typecheck forms omit the warning.
- `option-order-probes.py`: 54 more public invocations. Across bare, tests/ and tools/ executables and all eight supported redirects, 27 option-first forms omit the warning; all 27 equivalent reordered controls warn.
- Total: 230 invocations, all exit0; 33 omission observations covering 30 distinct commands. The other 197 invocations meet their expectations, including the explicit-kind control. All 687 per-case task/stdout/stderr artifacts rehash against their receipts. The initial driver receipt's equivalent absolute-path rendering is explicitly corrected to the literal launched relative argv in `probe-launches-exact.json`; the original receipt is retained.

The new evidence exposes an option-order assumption in the existing weak predicate after the repaired path normalization. These are direct, simple, unquoted commands; this finding does not demand a general shell parser.

### Finding O-034

- **Class:** verification-command-classification
- **Status:** open
- **Prior:** O-034
- **Severity:** wrong-result
- **Scenario:** An AC-referencing task has no Verify kind and declares `tsc --project tests/tsconfig.json --noEmit` or `tsc --pretty false --noEmit tests/unit.ts`. The same omission occurs with `./tests/tsc` and `tools/tsc`. Every supported simple redirect retains it; for example, `./tests/tsc>|out.txt --project tests/tsconfig.json --noEmit`. Moving only the option order to `tsc --noEmit --project tests/tsconfig.json` produces the required warning.
- **Where:** scripts/sdd-analyze.sh:302, scripts/sdd-analyze.sh:316, tests/test-sdd-analyze.sh:694, tests/test-sdd-analyze.sh:721
- **Reproduced:** From the assigned worktree with GIT_OPTIONAL_LOCKS=0, run the retained `classifier-probes.py` and `option-order-probes.py` using `python3 -I`; literal launch argv are in `probe-launches-exact.json`. `classifier-results.json`, `option-order-results.json` and `attack-summary.json` record33 omissions across30 distinct commands. Every omitted-warning call exits0, prints consistent and has empty stderr. The27 corresponding option-reordered calls warn with exit0. Representative complete outputs are `case-159/stdout.txt`, `case-160/stdout.txt` and `case-162/stdout.txt`.
- **Root cause:** implementation-error
- **Blocks:** AC-004, REQ-005
- **Wrong behavior:** The weak predicate recognizes typechecking only when the executable text is immediately followed by whitespace and --noEmit. A normal preceding --project or --pretty option prevents that match. With no other weak keyword, the task is reported consistent although the declared command still performs only typechecking. The three-line basename repair correctly removes the misleading test directory, but leaves this argument-adjacency assumption intact. Both generated and explicit regression lists keep --noEmit immediately after tsc, so their warning assertions cannot catch this sibling. This is an observed authoring-classification failure, not merely missing reality-check evidence.
- **Class-wide fix:** Recognize the known direct tsc typecheck form independently of ordinary option order, preserving genuine runners, custom/explicit kinds and the supported redirect normalization. Add public-analyzer assertions for the two reproduced flag orders, bare and qualified executable siblings, and all eight redirects; retain all prior path, numeric, operand and runner controls. Four current implementation/consumer/test sites are cited. Arbitrary quoting, wrappers, heredocs, compounds and other unexamined command grammars retain the documented explicit-kind/repository-script limit.

### Finding O-032

- **Class:** round-recovery-diagnostics
- **Status:** open
- **Prior:** O-032
- **Severity:** degraded
- **Scenario:** Reconcile shipped002's date-only opponent history, edit that history, then submit a corrected reconciliation naming round5 and the edited history's digest.
- **Where:** scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3552, scripts/verification-lib.sh:3578, scripts/verification-lib.sh:3584
- **Reproduced:** Retained from source-matched opponent23–26 observations: corrected reconciliation exits3 with empty output; removing only stale legacy-time.nul permits correction. Not rerun here. The inspected current library remains SHA-256 `015859de8d68d5cbaffa3ea9078a74584f364312b09cd3c739731fd6716a6c36`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Stale stored reconciliation fails the history read before replacement is examined. It fails closed without naming the effective manual recovery. The existing four-location minor remains unchanged.
- **Class-wide fix:** Retain the existing follow-up for corrected reconciliation and named diagnostics across the legacy history/reconciliation paths. No kernel or minor-finding repair was performed.

### Held up / follow-up tasks

Retain one class-wide O-034 follow-up covering its four cited sites and the reproduced option-order/qualified-tool/redirect siblings. The earlier operand, redirect-boundary and qualified-executable repairs hold in the fresh cases above, but this remaining direct typecheck omission prevents clearance under AC-004/REQ-005. O-032 retains its existing minor follow-up. This round records two unresolved finding IDs at eight cited locations. O-026/O-027/O-028 remain recorded, unassessed minor follow-ups; they are neither newly cleared nor recounted as new observations. No separate substantive acceptance, currency, invalidation or fixture-construction defect was established in the inspected scope.

The protection baseline contains28,082 preexisting files/symlinks:23,020 worktree entries plus shared Git metadata. All original worktree entries retain bytes, modes and mtimes; HEAD, the spec branch, real index, STATUS, tasks, source and historical evidence remain unchanged. Raw refs are byte-identical and there are no unexpected file additions. My worktree writes are only this new report and new assigned probe files; external scratch remains retained.

Strict preservation for this review is FALSE. Both recorded checks exit1 because shared `/Users/babar/projects/sdd-kit-public/.git/FETCH_HEAD` changed mtime from1793365279226384423 to1793365331309241268. Its bytes, SHA-256 `de3f7cee1e9faf051e576d95a28da60f3bcf321e4bc4e9ccbf9a21258054df48`, size1729 and mode644 are unchanged. Attribution is unknown; this review ran no fetch or network command. The actual before/after difference is retained in the protection receipts, without restoration or allowlisting. The earlier reservation window's strict preservation passed; historical strict preservation remains false. These are separate observations.

The floor launched on observed AC power; the authorized sampler later recorded battery from23:37:30Z until first recorded AC return07:32:19Z. Its original process continued. Neither continuous AC nor uninterrupted awake execution is claimed.

The parent owns authentic report comparison, completion and tally before any repair. This report consumes only the existing OP27 and supplies no OP28, RC5, RC4-readiness or merge authority. The canonical report has exactly one terminal LF; a UI return omitting it must not be called a literal byte match.

Not checked again: full suites/floor, kernel floor validator, fresh hosted/platform execution, historical mutation matrices, O-032 reproduction, capture/acceptance operations or the live AC-016 probe. Unchanged and otherwise unexamined surfaces retain those limits.
Risk: ordinary option order can still conceal direct typecheck-only AC verification; the existing minor follow-ups and recorded preservation discrepancy remain open.
<!-- gate-round-end: opponent:27 -->
