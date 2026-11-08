## Round 22

**Round:** 22
**Timestamp:** TIMESTAMP_PLACEHOLDER
**Source:** 809a9b69c4a360cc3e17c07a1f2126a872eb7c229768d4f36f948f228167a443
**Floor:** FLOOR-3Ge8eO
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 2

### What I attacked

I worked only in a copy under `/private/tmp/opp22/work`, built from the live enumeration (`git ls-files --cached --others --exclude-standard`) and git-initialized, with `TMPDIR=/private/tmp/opp22/tmp/`. The files that matter hash the same in the copy and the worktree: `scripts/verification-lib.sh` `015859de…` (unchanged since round 21), `scripts/spec-gate.sh` `79f20eee…`, `tests/test-spec-gate.sh` `bf297cb1…` (the hash `r22-dev.log` prints), `tests/test-gate-contracts.sh` `97beb809…` and `tests/helpers.sh` `b7bc6ff9…`. In the worktree I created, changed and removed nothing; my file tool refuses report files, so the invoker persists this block. I ran no floor, round, checkpoint, capture, accept, suite or test function there, sourced nothing from its `tests/`, and ran no container.

- **Scope.** The delta in `r22-session.diff`: T031a4o2 in `round_legacy_reconcile_cases`, its task block and the new Decisions entries. Also the kernel paths the case drives: the legacy read in `vf_round_history` (`:3403` to `:3407`), the ordering comparison in `vf_round_authorized` (`:3493`), `vf_gate_waiver_check`, and the `--reconcile` branch of `vf_gate_round` (`:3578` to `:3586`). I read REQ-011, REQ-012, AC-009, FM-016, the plan's authorization paragraph, the verification contract's legacy paragraph, and shipped 002's history and STATUS.
- **Method.** Each case ran alone through a runner that copies its suite with the final `t_run_all` replaced by one focus test, as `r22-dev.sh` does. Each mutant is an exact-anchor edit of the copy's kernel that refuses unless its anchor occurs once; after every run the kernel was restored and checked with `cmp`. All runs used `/bin/bash` 3.2.57 and the macOS awk. Unmutated, the case passes. During one stretch another process filled the disk to zero; I discarded every run from that window, re-ran them after the disk recovered behind a free-space guard, and checked every log for disk errors.
- **The dev run's mutants.** I re-ran the 13 O-029 mutants of `r22-edits/mutants-r22.py` against the current case. Twelve are killed by the assertions `r22-dev.log` names; `readround` survives, and I agree with round 21 that it is equivalent. I did not re-run the O-030 and O-031 mutants: neither their cases nor the kernel changed since round 21 killed them.
- **New mutants (11).** Read-path readings that ignore the record: noon of the history's date, the next day's midnight, and the record clamped to the next day's midnight. All three are killed. Survivors on the current case:
  - fail open: a record on the history's own date read as that date's midnight; the record truncated to its hour; the record truncated to its minute (O-029 below);
  - fail closed: the guard requiring a later day than the history's date; a read that never orders earlier than the end of the history's date; the record's validity check removed from `--reconcile`; the future half compared by date only, and by year only (O-033 below).
- **Round 21's case as a control.** I rebuilt round 21's suite by reversing the delta (`b94c7dfa…`, the hash round 21 recorded) and ran its case under the new survivors. It kills the same-day midnight reading, both truncations and the later-day guard; of the five I ran there, only the end-of-day floor survives.
- **Probes on the unmutated kernel.** Through the fixture's own `floor_fixture` CLI on a copy of 002's history: a record at 2026-07-20T18:00:00Z reconciles; a waiver at 12:00:00Z that day is refused at exit 4 with `not after the previous round completion at 2026-07-20T18:00:00Z`; a waiver at 19:00:00Z is authorized and round 6 reserves. A record at 2026-07-21T06:45:30Z refuses waivers at 06:30:00Z and 06:45:10Z the same way. Records stamped `2026-07-20T25:00:00Z` or `2026-07-20` exit 3, write nothing, and a correct record then reconciles. The kernel is correct in every probe.
- **A prototype of the repair.** In a copy of the suite I replaced the valid-record block with a same-day record and a later-day record at non-round times (O-029's Class-wide fix). Unmutated it passes, ShellCheck is clean, and it kills all 16 mutants I ran against it.
- **Claims.** `r22-capture.rc`, `r22-return-T031a4o2.rc`, `T031a4o2-accept.rc`, `r22-floor-1.rc`, `r22-floor-validate.rc` (stderr empty, the frozen source printed), `r22-scope.rc`, `r22-reserve.rc` and both batch logs read 0. CAP-722-hO9jDO carries input `809a9b69…` before and after and shows 15 suites passing 147 of 147, `test_rounds` among them. T031a4o2 is ticked with that capture and return digest `a28b333c…`. The reservation fields match `ROUND-22/meta.nul`, and the scope diff names only STATUS.md, tasks.md and `tests/test-spec-gate.sh`.
- **Not examined.** Linux with GNU tools and mawk; hosted CI, which has not run on this source; a full-suite run under any mutant (only `round_legacy_reconcile_cases` writes `legacy-time.nul` in `tests/`, so the focus run decides each read-path and reconcile mutant); O-026 to O-028, since no report-grammar code changed; and the rest of the brief's known-open list, which I did not re-litigate.

### Finding O-029
- **Class:** named-case-fixture-strength
- **Status:** open
- **Prior:** O-029
- **Severity:** wrong-result
- **Scenario:** T031a4o2 replaced the case's only valid record, on the history's own date at 2026-07-20T23:59:59Z, with one at 2026-07-21T06:00:00Z, and refuses a waiver one whole hour earlier. It moved the record instead of adding a second one, so the fixture now pins one point on a later day and nothing on the history's date.
  - **The same-day region.** The `--reconcile` guard admits a record dated on the history's date or on any later day up to now. Shipped 002 is a same-day history: its five rounds and its round 4 and round 5 authorizations are all dated 2026-07-20. An honest record for it names a time on that date, which is what REQ-012's same-day ordering and the contract's "before ordering same-day authorization" are about. A kernel that reads a same-day record as the date's midnight now passes, which is round 20's midnight reading again, for the records an operator would actually write.
  - **The round hour.** 06:00:00 has zero minutes and seconds, and the refused waiver sits an hour before it. A kernel that drops the record's minutes and seconds, or only its seconds, prints the same `2026-07-21T06:00:00Z` and passes the exact diagnostic.
  - **Not monotone.** Round 21's case killed all three of these mutants, because its record carried nonzero minutes and seconds on the history's date. The repair killed the end-of-day, clamp and future-half mutants and reopened these three.
- **Where:** tests/test-spec-gate.sh:1157, tests/test-spec-gate.sh:1158, tests/test-spec-gate.sh:1160, tests/test-spec-gate.sh:1162, tests/test-spec-gate.sh:1164, scripts/verification-lib.sh:3406, scripts/verification-lib.sh:3493, scripts/verification-lib.sh:3583
- **Reproduced:** In my copy, each mutant applied to `:3406` and restored with `cmp`.
  - **Current case.** Under the same-day midnight reading, the hour truncation and the minute truncation, `round_legacy_reconcile_cases` passes, `1/1 passed`.
  - **Round 21's case.** Each of the three is killed, by `AC-009: a waiver dated before the reconciled completion authorized the next round`.
  - **Hour, end to end.** A record at 2026-07-21T06:45:30Z reconciles, and a waiver dated 2026-07-21T06:30:00Z prints `authorized: opponent round 6`; after a floor, `round` reserves round 6. Unmutated, that waiver is refused at exit 4 with `not after the previous round completion at 2026-07-21T06:45:30Z` and nothing is reserved.
  - **Minute, end to end.** The same record and a waiver at 06:45:10Z: authorized, and round 6 reserved. Unmutated: refused at exit 4, nothing reserved.
  - **Same day, end to end.** A record at 2026-07-20T18:00:00Z and a waiver at 12:00:00Z that day: authorized, and round 6 reserved. Unmutated: refused at exit 4 with `not after the previous round completion at 2026-07-20T18:00:00Z`, nothing reserved.
- **Root cause:** plan-gap
- **Blocks:** AC-009, REQ-012
- **Wrong behavior:** Each of these regressions lets a waiver written before the reconciled completion authorize and reserve the next round with every suite green, which bypasses the per-round cap REQ-012 requires: the wrong behavior O-029 has named since round 20. They are less natural than round 21's end-of-day reading, but they are not new attacks on an old fixture: the case this repair replaced killed them, and the same-day region it dropped is where 002's real records fall. One record at one coarse point is an enumeration, and the class stays open. The root cause is plan-gap: round 21's recipe, which this gate wrote, and the task block prescribed one later-day record at 06:00:00Z, and the code follows them faithfully.
- **Class-wide fix:** Test files only, in `round_legacy_reconcile_cases`. Derive the records from the guard, which admits two regions: the history's date and the later days up to now.
  - **Same-day record.** Reconcile round 5 to 2026-07-20T15:17:43Z. A waiver at 15:17:42Z is refused with `not after the previous round completion at 2026-07-20T15:17:43Z`, and one at 15:17:44Z is authorized.
  - **Later-day record.** Then reconcile again, to 2026-07-21T06:17:43Z. A waiver at 06:17:42Z is refused with `not after the previous round completion at 2026-07-21T06:17:43Z`. Keep the bad-record loop, the current waiver, the edited-history steps and the reservation as they are.
  - **Check.** My prototype of exactly this passes unmutated and under ShellCheck, and kills 16 of 16 mutants: midnight, end of day, clamp, both read-check mutants, the reconcile check, the whole guard, its future half, the same-day midnight reading, both truncations, the end-of-day floor, the later-day guard, the next day's midnight, its clamp and noon.

### Finding O-033
- **Class:** named-case-fixture-strength
- **Status:** new
- **Prior:** none
- **Severity:** degraded
- **Scenario:** Three clauses of the `--reconcile` path are pinned nowhere, or at one far point, and a regression in each fails closed with every suite green.
  - **Same-day records refused.** Rewriting the guard's `! "${stamp:0:10}" < "$VF_ROUND_DATE"` as `"${stamp:0:10}" > "$VF_ROUND_DATE"`, a classic slip when a double negative is made positive, refuses every record on the history's own date. Round 21's case killed it; the current case does not. A read that never orders earlier than the end of the history's date also refuses a same-day waiver written after a same-day record; that one survived round 21's case too.
  - **Validity unchecked.** Removing `vf_utc_valid` from `:3582` lets a record with no real time through.
  - **Future by date or year.** Comparing the future half by date or by year only lets a record stamped later today, or later this year, through; the 2099 record does not tell them apart.
- **Where:** tests/test-spec-gate.sh:1142, tests/test-spec-gate.sh:1147, tests/test-spec-gate.sh:1158, scripts/verification-lib.sh:3406, scripts/verification-lib.sh:3582, scripts/verification-lib.sh:3583
- **Reproduced:** In my copy, each mutant applied and restored with `cmp`; the current case passes under each of the five, `1/1 passed`.
  - **Later-day guard.** Round 21's case fails under it: its same-day reconcile exits 3. Probe: a record at 2026-07-20T18:00:00Z exits 3 with empty output, and a waiver at 19:00:00Z that day is then refused with `date-only history needs timestamped digest reconciliation`. Unmutated, the record reconciles, the waiver is authorized and round 6 reserves.
  - **End-of-day floor.** The same record reconciles, but the 19:00:00Z waiver is refused with `not after the previous round completion at 2026-07-20T23:59:59Z`.
  - **Validity.** Records stamped `2026-07-20T25:00:00Z` and `2026-07-20` are each written at exit 0, the first printing `reconciled legacy gate=opponent round=5 timestamp=2026-07-20T25:00:00Z`. Then `waiver`, `round`, and `round --reconcile` with a correct record all give `rc=3 out=[]`. Unmutated, both records exit 3 and write nothing, the correct record reconciles, and round 6 reserves.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** Each regression refuses a valid same-day reconciliation or a valid same-day waiver, or, for a malformed record, wedges the gate with no diagnostic until `legacy-time.nul` is deleted by hand (the O-032 wedge, reached from a record the kernel itself accepted). A near-future record refuses every waiver until its time passes. The cap holds in every case, so this is degraded, as round 21 graded the future half alone. The task block's fixture design named neither the same-day region nor these clauses, hence plan-gap.
- **Class-wide fix:** Test files only. O-029's fix kills the later-day guard and the end-of-day floor. In the bad-record loop, add a record with an impossible time, such as 2026-07-20T25:00:00Z, refused at exit 3 with no `legacy-time.nul`. For the future half, add a record later today than now, computed without GNU or BSD date arithmetic (for example today's date at 23:59:59Z, skipped in the last second of the day), refused the same way. This can go with O-029's task or to the follow-up spec.

### Finding O-032
- **Class:** round-recovery-diagnostics
- **Status:** open
- **Prior:** O-032
- **Severity:** degraded
- **Scenario:** An operator reconciles a legacy date-only history, then corrects one line in it. The recovery round 20 named, re-running `round --reconcile` with a record for the current history digest, is itself refused, because `vf_gate_round` reads the history at `:3552`, before the `--reconcile` branch at `:3578`, and the stale `legacy-time.nul` fails that read at `:3405` with exit 3.
- **Where:** scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3552, scripts/verification-lib.sh:3578, scripts/verification-lib.sh:3584
- **Reproduced:** On the unmutated copy, whose kernel hashes as in round 21: a reconcile at 2026-07-21T06:17:43Z, one appended line, then `round --reconcile` with a record naming round 5 and the edited history's digest gives `rc=3 out=[]`. O-033's validity probe reaches the same wedge from a malformed record.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** REQ-012 requires a malformed or stale existing record to fail closed with a named recovery action. The cap holds, which is why this stays degraded, but the only recovery is a manual file deletion that no output names.
- **Class-wide fix:** Unchanged from round 21, for the follow-up spec, since no kernel change is authorized: in `--reconcile`, read a stored record that no longer matches leniently so that a record for the current digest can replace it, and give every `return 3` in the legacy read and in `--reconcile` a `round recovery:` diagnostic naming the disagreeing field and that recovery.

### Escalation

Round 22 is past round 3, and its one blocking finding is O-029, still open, not a new defect.
- **The spec is right.** REQ-012, AC-009 and the contract say a reconciliation orders authorizations by its own timestamp, bound to the history's digest, including same-day authorizations.
- **The prescription left the gap.** Round 21's recipe, written by this gate, moved the record to a later day at a round hour instead of adding a later-day record beside the same-day one. The repair followed it exactly. The fix is still test-only and small, and a prototype of it killed all 16 mutants I ran against it.
- **The decision is the user's.** Repair now (it moves the source, so it needs a new floor and an authorized round 23), or accept O-029's remaining risk with a signed waiver in the STATUS.md Decisions log. The kernel behaves correctly in every probe here; the risk is a later regression that would pass green. O-032 and O-033 do not block either way.

### Held up / follow-up tasks

Held up under attack:

- **Every history-only reading.** Midnight, noon, end of day and the next day's midnight, and the record clamped to the end of the day or to the next midnight, are all killed. The exact diagnostic pins the string `2026-07-21T06:00:00Z`, which no reading of 2026-07-20 can print. In that sense round 21's statement of O-029 is met; what stays open is the same-day region and the record's precision, above.
- **The future half.** The 2099 record kills the removal of the future half, and both halves of the guard together.
- **The binding.** Every reconcile-check mutant is killed (whole, digest half, round half), and so are the read-check whole and digest-half mutants. The read-path round check alone stays equivalent, as round 21 held.
- **The bad-record loop.** Each wrong record is judged alone (`rm -f` after each), each label names what is wrong with its record, and each mutant fails the labels of its own mechanism and no others, so the assertions fail for the right reason.
- **Shipped positives.** The later-day record accepted at exit 0 is honest input: the guard admits it, and a later time can only refuse more waivers. The current waiver, the restored history and the reservation are honest too.
- **Claims.** The receipts listed under What I attacked read exit 0 and match the files they describe.

Follow-up tasks proposed:

- T031a4o3, test files only (→ O-029, and O-033's same-day half). In `round_legacy_reconcile_cases`, reconcile first to 2026-07-20T15:17:43Z with waivers at 15:17:42Z (refused, exact diagnostic) and 15:17:44Z (authorized), then to 2026-07-21T06:17:43Z with a waiver at 06:17:42Z (refused, exact diagnostic). Show it kills the 16 mutants listed under O-029.
- O-033's validity and near-future records, with T031a4o3 or for the follow-up spec (minor).
- O-032 goes to the follow-up spec with the recovery above. It needs a kernel change, which is not authorized, and it does not block.
<!-- gate-round-end: opponent:22 -->
