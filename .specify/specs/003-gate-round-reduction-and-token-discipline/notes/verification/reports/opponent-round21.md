## Round 21

**Round:** 21
**Timestamp:** 2026-10-16T19:05:21Z
**Source:** fd20f46a37268b1cd8bb7874982e3a26a1ce713a04418168d3c6b898edf76305
**Floor:** FLOOR-5cLeox
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 1

### What I attacked

I worked only in a copy under `/private/tmp/opp21/work`, built from the live enumeration (`git ls-files --cached --others --exclude-standard`) and git-initialized, with `TMPDIR` ending in `/`. The files that matter hash the same in the copy and the worktree: `scripts/verification-lib.sh` `015859de…`, `scripts/spec-gate.sh` `79f20eee…`, `tests/test-spec-gate.sh` `b94c7dfa…` (the hash `r21-dev.log` prints), `tests/test-gate-contracts.sh` `97beb809…` and `tests/helpers.sh` `b7bc6ff9…`. In the worktree I created nothing: my file tool refuses report files, so the invoker persists this block. I ran no floor, round, checkpoint, capture, accept, suite or test function there, sourced nothing from its `tests/`, and ran no container.

- **Scope.** The delta in `r21-session.diff`: T031a4o1 (`round_legacy_reconcile_cases`), T031a1o1 (`acceptance_named_cases`) and T031a3o1 (`records_digest`, `shipped_002_tally_case`, `tally_class_cases`). Also the kernel paths those cases drive: `vf_round_history`, `vf_round_authorized`, `vf_gate_waiver_check`, the `--reconcile` branch of `vf_gate_round`, `vf_return_check` and `vf_tally`. I read AC-009, AC-010, AC-022, REQ-012 and REQ-015 in `spec.md`, the plan's authorization paragraph, and the three task blocks.
- **Method.** Each case ran on its own through a runner that copies its suite into the copy's `tests/` with the final `t_run_all` replaced by one focus test, as `r21-dev.sh` does. Each mutant is an exact-anchor edit of the copy's `scripts/verification-lib.sh` that refuses unless its anchor occurs once. After every run the kernel was restored and checked with `cmp`. All runs used `/bin/bash` 3.2.57 and the macOS awk. Unmutated, all four cases pass.
- **O-029 mutants (12).** Killed: the reconciled time replaced by midnight of the history's date (round 20's); the read-path round and digest check removed, and its digest half alone; the reconcile check removed, its digest half alone and its round half alone; the whole date guard of `--reconcile`, and its before-the-date half alone. Survived:
  - the reconciled time replaced by the end of the history's date, 23:59:59Z (O-029 below);
  - the reconciled time clamped to that end of day when it is later (O-029 below);
  - the future half of the `--reconcile` date guard removed (O-029 below);
  - the read-path round check alone removed. I hold that one equivalent: only `--reconcile` writes a record, and it checks the round; the read path checks the digest, which fixes the history and so its last round.
- **O-030 mutant.** Round 20's mutant, the guard at `:2861` reduced to refusing mappings, is now killed by the new assertions (O-030 below).
- **O-031 mutants (3).** All killed: appending a comment line to the history after the report (round 20's), creating a new empty file under `notes/`, and appending a newline to an existing `reality-check.md` (O-031 below).
- **Probes on the unmutated kernel.** These ran through the fixture's own `floor_fixture` CLI on a copy of shipped 002's history.
  - A record reconciled to 2026-07-21T09:00:00Z, a day after the history's date, is accepted. A waiver dated 2026-07-21T08:00:00Z is then refused at exit 4 with `not after the previous round completion at 2026-07-21T09:00:00Z`, and `round` reserves nothing.
  - A record at 2026-07-20T18:00:00Z, inside the date, lets a waiver dated 19:00 that day authorize round 6.
  - After a valid reconcile and one appended line, `round --reconcile` with a correct record for the edited history exits 3 with empty output, and so does `round`. Only after I deleted `legacy-time.nul` by hand did the same record reconcile (O-032 below).
  - A record stamped 2099-01-01T00:00:00Z is refused at exit 3 and nothing is written.
  - A hand-written `legacy-time.nul` stamped 2026-07-19, before the history's date, is read with no date check, and a waiver dated 2026-07-19T12:00:00Z then authorizes round 6. I hold this outside the model (below).
- **Full suite under a mutant.** I started `tests/run.sh` on a second copy under the end-of-day mutant. I stopped it after the first two suites (12 of 147 tests, no failure), because free disk on `/` fell from 6.9 GiB to under 2 GiB through activity outside my directories, which stayed under 700 MiB. Instead I checked that the mutated line runs only when `legacy-time.nul` exists. No shipped spec holds one, and in `tests/` only `round_legacy_reconcile_cases` writes one, so the focus run decides that mutant for the whole suite.
- **Claims.** `r21-return-T031a{1,3,4}o1.rc`, `T031a{1,3,4}o1-accept.rc`, `r21-capture.rc`, `r21-floor-1.rc`, `r21-floor-validate.rc`, `r21-reserve.rc`, `r21-scope.rc` and `r21-freeze.rc` all read 0. The capture of record CAP-700-lvBf95 carries input `fd20f46a…` before and after, and shows 15 suites passing 147 of 147. `r21-dev.log` shows each of the 9 new O-029 assertions killed by one of round 20's three mutants, as the task block says. The reservation fields match `ROUND-21/meta.nul`, and all three tasks are ticked (`r21-postaccept.txt`).
- **Not examined.** Linux with GNU tools and mawk; hosted CI, which has not run on this source; a completed full-suite run under any mutant; O-026 to O-028, since no report-grammar code changed; and the brief's known-open list, which I did not re-litigate.

### Finding O-029
- **Class:** named-case-fixture-strength
- **Status:** open
- **Prior:** O-029
- **Severity:** wrong-result
- **Scenario:** The repair reconciles round 5 to 2026-07-20T23:59:59Z, which is also the end of the history's own date. A kernel that orders legacy authorizations against the end of the history's date, and never reads the record's timestamp, prints the same diagnostic for the early waiver. So the fixture cannot tell the reconciled time from a reading of the date.
  - **The test's own claim.** Its comment says that between the history's date and the reconciled time only the record decides. With the record at the end of the date, the record and the end-of-day reading decide the same way.
  - **The kernel accepts later records.** The `--reconcile` guard refuses only a stamp dated before the history's date or in the future, so a record on any later day is valid input.
  - **The plan's rule.** A waiver's timestamp must be later than the preceding completed or reconciled invocation. AC-009 says the reconciliation is for authorization ordering.
  - **The future half.** No case reconciles with a timestamp in the future, so the second half of the same guard can be deleted with the case green.
- **Where:** tests/test-spec-gate.sh:1153, tests/test-spec-gate.sh:1156, tests/test-spec-gate.sh:1157, tests/test-spec-gate.sh:1159, scripts/verification-lib.sh:3406, scripts/verification-lib.sh:3583
- **Reproduced:** In my copy, each mutant applied and restored with `cmp`.
  - **End of day.** `VF_ROUND_TIME` at `:3406` set to the history's date at 23:59:59Z: `round_legacy_reconcile_cases` passes. My probe then reconciles round 5 to 2026-07-21T09:00:00Z, accepted at exit 0, and writes a waiver dated 2026-07-21T08:00:00Z. Under the mutant that waiver prints `authorized: opponent round 6`, and `round` reserves round 6 on a current floor. Unmutated, it is refused at exit 4 with `not after the previous round completion at 2026-07-21T09:00:00Z`, and nothing is reserved.
  - **Clamp.** The record's time kept, but clamped to 23:59:59Z of the date when later: the case passes, and the same probe authorizes and reserves round 6.
  - **Future half.** The `! "$stamp" > now` half of `:3583` removed: the case passes. My probe's record stamped 2099-01-01T00:00:00Z is then written at exit 0. Unmutated, it exits 3 and writes nothing.
- **Root cause:** plan-gap
- **Blocks:** AC-009, REQ-012
- **Wrong behavior:** O-029's ordering clause is still unprotected for any record not stamped at the end of the history's date. A regression that reads the date instead of the record lets a waiver written before the reconciled completion authorize the next round, with every suite green. That bypasses the per-round cap REQ-012 requires, the way round 20 described. The task block prescribed 23:59:59Z, and the code follows it faithfully, which is why the root cause is plan-gap. A regression in the future half fails closed instead: one future record refuses every waiver until it is overwritten. That half alone would be minor.
- **Class-wide fix:** Test files only. In `round_legacy_reconcile_cases`, reconcile to a time that no reading of the date produces, on a later day, so that one record separates the record from both readings of the date.
  - **Record.** Reconcile round 5 to 2026-07-21T06:00:00Z, with the right digest.
  - **Refusal.** A waiver dated 2026-07-21T05:00:00Z is refused with `not after the previous round completion at 2026-07-21T06:00:00Z`. That kills midnight, end of day and the clamp.
  - **Future.** Before the valid reconcile, a record stamped 2099-01-01T00:00:00Z exits 3, writes no `legacy-time.nul`, and leaves the next round refused as date-only.
  - **Check.** Show each new assertion killed by the end-of-day, clamp and future-half mutants above, as well as by round 20's three.

### Finding O-032
- **Class:** round-recovery-diagnostics
- **Status:** open
- **Prior:** O-032
- **Severity:** degraded
- **Scenario:** An operator reconciles a legacy date-only history, then corrects one line in it. Round 20 named the recovery for the follow-up spec: re-run `round --reconcile` with a record for the current history digest. That recovery is itself refused.
  - **Why.** `vf_gate_round` reads the history with `vf_round_history` at `:3552`, before the `--reconcile` branch at `:3578`. The stale `legacy-time.nul` fails that read at `:3405` with exit 3, so the new record is never examined.
  - **Effect.** No CLI command recovers that gate. Only deleting `legacy-time.nul` by hand does, and nothing names that file.
- **Where:** scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3552, scripts/verification-lib.sh:3578, scripts/verification-lib.sh:3584
- **Reproduced:** On the unmutated copy, through the fixture's own `floor_fixture` CLI on a copy of 002's history: a valid reconcile, then one appended line, then `round --reconcile` with a record naming round 5 and the edited history's digest gives `rc=3 out=[]`, and `round` gives `rc=3 out=[]`. After I deleted `legacy-time.nul` by hand, the same record reconciled at exit 0.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** REQ-012 requires a malformed or stale existing record to fail closed with a named recovery action. The cap holds, which is why this stays degraded. But the only recovery is a manual file deletion that no output names, and the recovery recorded for the follow-up spec would not work as written.
- **Class-wide fix:** For the follow-up spec, since no kernel change is authorized now. In `--reconcile`, read a stored record that no longer matches leniently, so that a record for the current digest can replace it. Give every `return 3` in the legacy read and in `--reconcile` a `round recovery:` diagnostic that names the disagreeing field and that recovery. Then assert those diagnostics in the O-029 cases, including a re-reconcile after an edit.

### Finding O-030
- **Class:** named-case-fixture-strength
- **Status:** resolved
- **Prior:** O-030
- **Severity:** minor
- **Scenario:** In round 20, a mutant replaced the guard that requires `Failure modes: none` for a task owing no rows with one that only refuses mappings, and every suite stayed green.
- **Where:** tests/test-spec-gate.sh:174, tests/test-spec-gate.sh:175, tests/test-spec-gate.sh:176, tests/test-spec-gate.sh:178, scripts/verification-lib.sh:2861
- **Reproduced:** In my copy, round 20's mutant applied and restored with `cmp`: `acceptance_named_cases` now fails. The accept of the empty-header return for T006 exits 0 instead of 3, the diagnostic `empty required set must explicitly be none` is missing, and tasks.md changes.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** None remains. A return for the no-row task T006 with an empty `Failure modes:` header is refused with the exact diagnostic, and tasks.md keeps its text. A header followed by narrative reaches the same guard through the parser's truncation record, so the same assertion protects it.
- **Class-wide fix:** Done by T031a1o1. No further task.

### Finding O-031
- **Class:** named-case-fixture-strength
- **Status:** resolved
- **Prior:** O-031
- **Severity:** minor
- **Scenario:** In round 20, a mutant made `vf_tally` append to the history it reads, and both 002 tally cases stayed green, because no case hashed what the tally read.
- **Where:** tests/test-gate-contracts.sh:559, tests/test-gate-contracts.sh:561, tests/test-gate-contracts.sh:2245, tests/test-gate-contracts.sh:2299, tests/test-gate-contracts.sh:2309, scripts/verification-lib.sh:2150
- **Reproduced:** In my copy, each mutant applied and restored with `cmp`. Round 20's mutant, `vf_tally` appending a comment line to the history it reads after it reports, now fails all three new digest assertions in `shipped_002_tally_case` and `tally_class_cases`. So does a mutant that creates a new empty file under `notes/`. A mutant that appends a newline to an existing `reality-check.md` fails the shipped 002 assertion, the only case whose history has one.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** None remains for file content. `records_digest` covers every regular file under each directory the tally reads, by name and bytes. It does not see a new empty directory or a mode change, and neither rewrites a shipped artifact.
- **Class-wide fix:** Done by T031a3o1. No further task.

### Escalation

Round 21 is past round 3. Its one blocking finding is O-029, still open; it is not a new defect.
- **The spec is right.** AC-009, REQ-012 and the plan say a reconciliation orders authorizations by its own timestamp, bound to the history's digest.
- **The prescription left the gap.** Round 20 prescribed a reconciled time of 23:59:59Z and a waiver earlier that day, and asked for each assertion to be killed by its three mutants. The repair does exactly that. But 23:59:59Z is also what an end-of-day reading of the date yields, so the timestamp half of the binding is proven against midnight only.
- **The decision is the user's.** The repair is test-only and small: one record time, one waiver and one future-record case in one function. It moves the source, so it needs a new floor and an authorized round 22. The alternative is to accept O-029's remaining risk with a signed waiver in the STATUS.md Decisions log. The kernel behaves correctly in every probe here; the risk is a later regression that would pass green. O-032 does not block either way.

### Held up / follow-up tasks

Held up under attack:

- **T031a4o1, the digest and round binding.** Every mutant of the reconcile-time check is killed: the whole check, its digest half and its round half. So is every mutant of the read-time binding: the whole check and its digest half. The edited-history assertions work for the right reason: the floor is re-run on the edited history, so it is current and only the binding refuses the round, and the absence of `authorized` is a sound check because no refusal text contains that word.
- **T031a4o1, the date guard and the early waiver.** The record stamped before the history's date kills both the whole guard and its before-the-date half. Midnight is killed by the early waiver's exact diagnostic.
- **T031a1o1.** The new refusal is pinned by its exact diagnostic and kills round 20's mutant. The byte check compares tasks.md as `$(cat)` text, which drops trailing newlines, like every other check in this function; a refused accept writes nothing, so this smells but does not break.
- **T031a3o1.** `records_digest` sorts names under `LC_ALL=C` and hashes each regular file, and every directory the tally reads in these cases is hashed before and after. The kit-level 002 check is honest as relabelled: nothing in the case writes there.
- **The hand-written early record.** `vf_round_history` checks the round and digest of `legacy-time.nul` but not its date bounds. Only `--reconcile` writes that file, and it checks them, and a digest-bound record cannot later fall outside its history's date. A hand-forged record is as forgeable as any ledger here, so I record this as a smell, not a finding.
- **Shipped positives.** None of the new cases asserts an attack at exit 0. Each accepted input is honest: the valid reconcile, the current waiver, the restored history, the explicit none, and the tally runs.

Follow-up tasks proposed:

- T031a4o2, test files only (→ O-029). In `round_legacy_reconcile_cases`, reconcile to 2026-07-21T06:00:00Z and refuse a waiver dated 2026-07-21T05:00:00Z with the exact diagnostic. Refuse a future-stamped reconcile record before the valid one. Show each new assertion killed by the end-of-day, clamp and future-half mutants.
- O-032 goes to the follow-up spec with the corrected recovery above. It needs a kernel change, which is not authorized, and it does not block.
<!-- gate-round-end: opponent:21 -->
