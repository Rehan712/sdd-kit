# Ubuntu CI diagnosis — read-only log digest
Run 40668391031 attempt 1; job 122748655967 `tests (ubuntu-latest)`; published head `08210681770b65c6ccdfa2571b80a79a09e03154`.
Frozen source `9eb5835224ccdf82b8d97b108097fac6ab5b993c38200fd1970c765c5e6a3842`; local HEAD `2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9`.
L = `.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s35-ci-failure/ubuntu-log-raw.stdout`; C = `.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261028-s34/hosted-s34-audit/collect-hosted.py`.
Actual failed step: `run the test suite` / `tests/run.sh` (L:145–147,615; ubuntu-job.stdout:1 `/steps/2`).
Exactly one failed test: `tests/test-sdd-analyze.sh::test_verification_bindings` (L:218,237,527: 18/19); 22 assertion diagnostics.
Weak cases each miss `untyped AC Verify` and `warning(s), 0 errors`:
- `grepREDIRECT>out.txt AC-001 README.md` — L:238,255.
- `tscREDIRECT>out.txt --noEmit` — L:272,289.
- `testREDIRECT>out.txt -e README.md` — L:306,323.
- `test -fREDIRECT>out.txt README.md` — L:340,357.
- `tsc REDIRECT>out.txt --noEmit` — L:374,391.
- `test REDIRECT>out.txt -e README.md` — L:408,425.
Runner cases each unexpectedly contain `untyped AC Verify` and miss `consistent`:
- `bashREDIRECT>out.txt tests/typecheck.sh` — L:442,443.
- `cargo testREDIRECT>out.txt --test typecheck` — L:459,460.
- `npm runREDIRECT>out.txt test -- --grep typecheck` — L:476,477.
- `bash REDIRECT>out.txt tests/typecheck.sh` — L:493,494.
- `npm run REDIRECT>out.txt test -- --grep typecheck` — L:510,511.
The remaining suites continue through `test-verification.sh` 3/3, then exit 1 (L:528–615); no logged timeout/resource-kill/download failure.
Diagnosis: fixture construction portability defect, high confidence; not demonstrated product-parser regression or transient infrastructure failure.
Source: redirect list includes `&>out.txt` at tests/test-sdd-analyze.sh:676; builders :681,:686 interpolate unquoted replacement text in `${fixture/REDIRECT/$spacing$redirect}`.
Inference: Bash `patsub_replacement` expands replacement `&` to matched `REDIRECT`, yielding the exact malformed labels above. The log does not record Bash version or shopt state; mechanism not reproduced here.
Malformed command words then explain both directions via scripts/sdd-analyze.sh:289–299,:313–314. Helpers record assertion failures without aborting (tests/helpers.sh:74–108,:613–632); tests/run.sh:56,:63 propagates failure.
All five relevant local files equal their published Git blobs; hashes in result.json. L:92,:141,:143–144 bind tested merge `9894ce4a679c8120e1be7c432106f7a07021eb0b`.
Unknown: tested merge object is absent locally; its tree equality is not independently established in this diagnosis. No network fetch/API query performed.
Proposed next action (not applied): parent obtains a narrow source-unfreeze decision, then changes ONLY fixture builders :681,:686 to concatenate `${fixture%%REDIRECT*}$spacing$redirect${fixture#*REDIRECT}` within the existing array string.
Retain all cases/assertions; later authorize focused validation on Bash 3.2 and the newer Ubuntu Bash, including the literal generated `&>` strings, before refreshing snapshot CI.
This changes frozen test source/identity: existing CI remains evidence for the old snapshot, not the repaired one; accepted evidence/bindings need reassessment by parent. No product/workflow/collector change proposed.
Scope: O-034 fixture construction only (tests/test-sdd-analyze.sh:667,:691; tasks.md:1085,:1093). O-032 recovery diagnostics and recorded minors are not implicated or proposed for repair (STATUS.md:34).
No unchanged-source retry recommended: malformed deterministic fixture labels give no transient justification.
Collector requires exactly four successful jobs AND every job run_attempt == wanted_attempt (C:44–48), one tested merge/tree binding (C:50–60); carried prior-attempt jobs cannot satisfy it. Do not weaken collector.
Artifacts: ubuntu-log-excerpt.txt strips ANSI only from selected original lines; result.json maps excerpt lines to immutable raw lines, enumerates all assertions, and records file bindings/state.
Not run: tests/repros/suites, captures, CI queries/retries/cancellations, collector, source helpers, reserves/completions/floor/gates, delegates, secrets, PR/watch/link operations, Git writes, commits/pushes/ref changes.
Limits: diagnosis only; no quality/formal verdict, no claim of green CI; other jobs remain at their archived observation states.
