## Round 20

**Round:** 20
**Timestamp:** 2026-10-16T02:09:54Z
**Source:** 9cf02d45d97952557c41180743b973563e854825d6d2d5e73b1db3b72be4dfa5
**Floor:** FLOOR-UeGEcf
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 3

### What I attacked

I worked only in a copy under `/private/tmp/opp20/work`, built from the live enumeration (`git ls-files --cached --others --exclude-standard`) and git-initialized, with `TMPDIR` ending in `/`. The four files that matter hash identically in the copy and the worktree: `scripts/verification-lib.sh` `015859de…`, `tests/test-spec-gate.sh` `a5c7a0d0…` (the hash the capture of record `r20-capture.log` names), `tests/test-verification.sh` `8b07ca66…` and `tests/test-gate-contracts.sh` `f927e872…`. In the worktree I created nothing: my file tool refused to write the report path, so the invoker persists this block. I ran no floor, round, checkpoint, capture, accept, suite or test function there, and sourced nothing from its `tests/`. I ran no container.

- **Scope.** The delta in `r20-session.diff`: T031a1 (`acceptance_named_cases`), T031a2 (the new tail of `reuse_floor_cases`, `gate_execute_fixture` and the new block of `capture_validity_cases`), T031a3 (`annotate_002` and `tally_class_cases`) and T031a4 (`round_legacy_reconcile_cases`). Also the kernel paths each case drives: `vf_return_parse`, `vf_return_check`, `vf_capture_check`, `vf_task_capture_matches`, `vf_gate_execute`, `vf_tally`, `vf_round_history`, `vf_round_authorized` and the `--reconcile` branch of `vf_gate_round`. I read the criteria from `spec.md` (AC-007, AC-009, AC-010, AC-020, AC-022, REQ-012), the matching plan text (the authorization grammar and the return grammar) and the four task blocks.
- **Method.** I ran each new case on its own through a runner that sources a rewritten copy of its suite: the helpers path made absolute, and the final `t_run_all` replaced by a loop over named functions with the same sandbox and failure handling. All five cases pass under `/bin/bash` 3.2.57 with the macOS awk, and again with gawk 5.4.0 as `awk`. Then I mutation-isolated each case against the kernel guard that implements the behaviour its comment names. Each mutant is one exact-anchor replacement in the copy's `scripts/verification-lib.sh`, applied by a script that refuses unless the anchor occurs once, run, and restored with `cmp`.
- **T031a1 mutants.** Killed: parse accepting a missing `Failure modes:` block (the diagnostic becomes `required Failure modes are missing`); removing the exit check (it becomes `capture stale: current inputs changed`); dropping the argv comparison from `vf_task_capture_matches` (the unrelated capture is accepted); skipping the manual check when the artifact is absent. Survived: dropping the explicit-none requirement for an empty required set (O-030).
- **T031a2 mutants.** Making `vf_gate_execute` argv-blind (dropping its `cmp` of argv) is killed by `capture_validity_cases` (`old:1 old:1` instead of `old:1 new:0`) and survives `reuse_floor_cases`, because the changed command lives in `.specify/stack.yml`, which the input identity hashes. The test's own comment hands argv isolation to the capture case, so I hold this (below).
- **T031a3 mutants.** Recurrence keyed by Class and file, and by file alone, are both killed by the synthetic fixture. A `vf_tally` that appends to the history it reads survives `tally_class_cases` and `shipped_002_tally_case` (O-031).
- **T031a4 mutants.** Removing the date-only refusal is killed by its exact diagnostic. Survived: the reconciled timestamp replaced by midnight of the history's date; the reconcile-time digest and round check removed; and all legacy binding removed at once, both in `vf_round_history` and in `--reconcile` (O-029).
- **Full suites under mutation.** On two further copies, `bash tests/run.sh` under the explicit-none mutant: exit 0, 147/147 over 15 suites. Under the combined legacy mutant: exit 0, 147/147.
- **Probes on the unmutated kernel.** These show the kernel is right where the fixtures are silent.
  - A waiver dated 2026-07-20T12:00:00Z after reconciling round 5 to 23:59:59Z is refused at exit 4 with `not after the previous round completion at 2026-07-20T23:59:59Z`.
  - A reconcile record naming a wrong digest, a wrong round, or a timestamp before the history's date exits 3 and writes no `legacy-time.nul`.
  - After a valid reconciliation, appending one line to the history makes `waiver` and `round` exit 3 with empty output (O-032).
  - A no-row task returning an empty `Failure modes:` header is refused with `return: empty required set must explicitly be none`.
- **Claims.** `r20-return-T031a{1,2,3,4}.rc`, `T031a{1,2,3,4}-accept.rc`, `r20-floor-2.rc`, `r20-floor-validate.rc`, `r20-reserve.rc` and `r20-scope.rc` all read 0. All four tasks are ticked. The reservation fields match `ROUND-20/meta.nul`.
- **Not examined.** Linux with GNU sed and mawk; hosted CI, which has not run on this source; O-026 to O-028, since no report-grammar code changed in this delta; and the known-open list in the brief, which I did not re-litigate.

### Finding O-029
- **Class:** named-case-fixture-strength
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** `round_legacy_reconcile_cases` reconciles a copy of shipped 002's date-only history to round 5 at 2026-07-20T23:59:59Z, then writes a waiver stamped with the current clock (2026-10-16) and asserts it authorizes round 6. That waiver is later than the reconciled timestamp and also later than any reading of the history's date, so the fixture cannot tell whether ordering uses the reconciled time at all.
  - **Ordering.** No case dates a waiver between the history's date and the reconciled time, where only the reconciled timestamp decides.
  - **Digest binding.** No case reconciles with a wrong digest or round, or edits the history after reconciling.
  - **What the texts promise.** The plan says a legacy round needs a reconciliation record identifying the old report digest before ordering an authorization. AC-009 says reconciliation is for authorization ordering. T031a4's acceptance says the record is bound to the history's digest.
- **Where:** tests/test-spec-gate.sh:1120, tests/test-spec-gate.sh:1121, tests/test-spec-gate.sh:1123, tests/test-spec-gate.sh:1124, tests/test-spec-gate.sh:1126, scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3406, scripts/verification-lib.sh:3581, scripts/verification-lib.sh:3583
- **Reproduced:** In my copy, each mutant applied and restored with `cmp`.
  - **Timestamp ignored.** `vf_round_history` takes `VF_ROUND_TIME` from the history's date at midnight instead of the record (`:3406`). `round_legacy_reconcile_cases` passes. My probe's early waiver (2026-07-20T12:00:00Z) then prints `authorized: opponent round 6` at exit 0. Unmutated, it is refused at exit 4 with `not after the previous round completion at 2026-07-20T23:59:59Z`.
  - **Reconcile checks removed.** Dropping the digest and round check at `:3581` passes the case.
  - **All binding removed.** Removing `:3405`, `:3581` and `:3583` together and ignoring the timestamp passes the case, and the full suite gives exit 0 at 147/147. Under that mutant any file holding the three keys unlocks round 6.
- **Root cause:** implementation-error
- **Blocks:** AC-009, REQ-012
- **Wrong behavior:** The suite now certifies AC-009's legacy clause, but the three checks that make a reconciliation an ordering record bound to one history can each be deleted with every suite green. A regression there would let a waiver written before a legacy history's real last completion authorize the next round. It would also let a reconciliation outlive an edit of the history it names. That bypasses the per-round cap REQ-012 requires, while the fixture added for AC-009 stays green.
- **Class-wide fix:** Test files only. In `round_legacy_reconcile_cases`, assert the refusals that only the reconciled record can decide.
  - **Before the valid reconcile.** A wrong digest, a wrong round and a timestamp before the history's date each exit 3, write no `legacy-time.nul`, and leave the next round refused with the date-only diagnostic. Assert that observable state, since the kernel names none of these refusals (O-032).
  - **After it.** A waiver dated 2026-07-20 before 23:59:59Z is refused with `not after the previous round completion at 2026-07-20T23:59:59Z`. The current waiver is authorized.
  - **After editing the history.** Neither `waiver` nor `round` authorizes or reserves anything.
  - **Check.** Each new assertion must be killed by one of the three mutants above.

### Finding O-030
- **Class:** named-case-fixture-strength
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** AC-022 names no assigned rows with explicit none, and the plan's return grammar says that if the required set is empty, a return must carry `Failure modes: none`. `acceptance_named_cases` asserts only that T006, which owes no rows, is accepted with an explicit none. Nothing returns an empty `Failure modes:` header, or a header followed by narrative, for a task that owes no rows.
- **Where:** tests/test-spec-gate.sh:171, tests/test-spec-gate.sh:172, tests/test-spec-gate.sh:173, scripts/verification-lib.sh:2861
- **Reproduced:** I replaced the guard at `:2861` with one that only refuses mappings, so a block without `none` is accepted. `acceptance_named_cases` and the whole `test_acceptance` still pass, and the full suite gives exit 0 at 147/147. Unmutated, my probe's empty header for T006 is refused with `return: empty required set must explicitly be none`. Under the mutant it prints `accept accepted task=T006`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The explicit part of the named case is unprotected: a regression could accept an empty block for a no-row task, and every suite would stay green. The task owes nothing, so no row is lost, which is why this is minor.
- **Class-wide fix:** In `acceptance_named_cases`, before the explicit-none acceptance, return T006 with an empty `Failure modes:` header and refuse it with `empty required set must explicitly be none`, with tasks.md byte-identical. Generally, pair each accepting case with the refusal that gives its qualifier meaning.

### Finding O-031
- **Class:** named-case-fixture-strength
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** `tally_class_cases` asserts that the 002 copy and the shipped 002 notes keep their hash, labelled as AC-010's clause that original shipped artifacts are not rewritten. Nothing in between can write either file: `annotate_002` reads the copy on standard input, and `tally` runs on a third file, `$SANDBOX/annotated`. `shipped_002_tally_case` runs `tally` on its copy without hashing it afterwards.
- **Where:** tests/test-gate-contracts.sh:2294, tests/test-gate-contracts.sh:2295, tests/test-gate-contracts.sh:2300, tests/test-gate-contracts.sh:2301, tests/test-gate-contracts.sh:558
- **Reproduced:** I made `vf_tally` append a comment line to the history it reads, after it reports. `tally_class_cases` and `shipped_002_tally_case` both still pass. Run on the live tree, this mutant would rewrite shipped 002's notes.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The two byte-identity assertions can never fail, so the no-rewrite clause is held by construction, not by test. Today's `vf_tally` writes nothing, which is why this is minor.
- **Class-wide fix:** Hash each file `tally` reads before and after the run: `$SANDBOX/annotated/notes/opponent.md` in `tally_class_cases`, and the copy in `shipped_002_tally_case`. Keep the copy check, which proves only that `copy_kit` is faithful, and label it that way.

### Finding O-032
- **Class:** round-recovery-diagnostics
- **Status:** new
- **Prior:** none
- **Severity:** degraded
- **Scenario:** An operator reconciles a legacy date-only history, then appends or corrects a line in it, or first writes a reconcile record with a wrong digest, a wrong round, or a timestamp before the history's date. These refusals all exit 3 and print nothing, from `round --reconcile`, from `waiver` and from `round` alike. REQ-012 requires malformed or incomplete existing records to fail closed with a named recovery action.
- **Where:** scripts/verification-lib.sh:3404, scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3406, scripts/verification-lib.sh:3580, scripts/verification-lib.sh:3581, scripts/verification-lib.sh:3582, scripts/verification-lib.sh:3583
- **Reproduced:** On the unmutated copy, through the fixture's own `floor_fixture` CLI on a copy of 002's history: wrong round, `rc=3 out=[]`; timestamp before the date, `rc=3 out=[]`; valid reconcile, then one appended line, gives `waiver` `rc=3 out=[]` and `round` `rc=3 out=[]`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The cap holds, since every case fails closed, which is why this is degraded. But the operator gets no cause and no recovery step. Every later `round` and `waiver` call for that gate stays silent at exit 3 until someone finds `legacy-time.nul` by reading the source. Fixtures can assert only exit codes and state here, never a diagnostic.
- **Class-wide fix:** For the follow-up spec, since no kernel change is authorized now: give every `return 3` in the legacy-record read and in `--reconcile` a `round recovery:` diagnostic. Name the field that disagrees and the recovery, which is to re-run `round --reconcile` with a record for the current history digest. Then assert those diagnostics in the O-029 cases.

### Escalation

Round 20 is past round 3, and it raises one substantive new defect, O-029, and three minor ones.
- **The spec is right.** AC-009, REQ-012 and the plan's authorization text all say a legacy reconciliation exists to order authorizations against a timestamp bound to the history's digest. T031a4's acceptance says so too.
- **The method left the gap.** The fixtures were written from the reviewer's probes, which showed each case only in the direction the probe ran. The two-direction judging and the mutation pass that would have caught the missing directions were dropped by the user's decisions of 2026-10-14 and 2026-10-15, and nothing else caught them. Every surviving mutant here is a missing refusal beside an accepted positive.
- **The decision is the user's.** The repair for O-029 is test-only and small: three groups of assertions in one function. But it moves the source, so it needs a new floor, an authorized round 21, hosted CI and reality-check round 3. The alternative is to accept O-029's risk with a signed waiver in the Decisions log in STATUS.md. O-030 to O-032 do not block either way.

### Held up / follow-up tasks

Held up under attack:

- **T031a1, the other named cases.** Each refusal is pinned by its exact diagnostic, and four mutants of the guards behind them are killed: missing block, exit code, argv binding, and missing manual artifact. The failed capture is also stale, because `tests/check.sh` is restored before acceptance, but the exit check runs first, and its removal changes the diagnostic, so the case still fails. The expected-file comparison of the valid acceptance reproduces `vf_tasks_rewrite`'s Evidence placement and catches any other line changed.
- **T031a2.** The capture-level case holds the inputs fixed, reads `vf_gate_execute`'s six-field records correctly, and kills the argv-blind mutant. The floor-level case cannot isolate argv on its own, since the command lives in the hashed `stack.yml`. Its observable claim, that a changed command executes again with `cache-hits=0`, is true, and the `sed` also rewrites the `reuse_checks` entry, so the new command is still opted in and `cache-hits=0` is not merely a policy effect.
- **T031a3, the recurrence semantics.** Both file-keyed mutants are killed. `annotate_002`'s table matches the 002 text: 1.1 and 4.3 are the minute-less clock findings, and 2.1, 3.1 and 4.2 are the stale-lock findings of the lock lifecycle. The output parses canonically under gawk too.
- **T031a4, the refusal half.** It asserts the exact date-only diagnostic and that ROUND-6 is absent, and it kills the mutant that removes the refusal.
- **Shipped positives.** None of the new cases asserts an attack at exit 0. Each accepted input (a valid return, an explicit none, a correctly bound reconcile, a later waiver) is honest.

Follow-up tasks proposed:

- T031a4o1, test files only (→ O-029). Add the before, after and edited-history cases above to `round_legacy_reconcile_cases`, each shown killed by the timestamp, digest and combined mutants.
- T031a1o1, test files only (→ O-030). Add the empty-header refusal for the no-row task to `acceptance_named_cases`.
- T031a3o1, test files only (→ O-031). Hash the files `tally` reads before and after the run in `tally_class_cases` and `shipped_002_tally_case`.
- O-032 goes to the follow-up spec, since it needs a kernel change, which the user's decision of 2026-10-15 does not authorize. It is non-blocking.
<!-- gate-round-end: opponent:20 -->
