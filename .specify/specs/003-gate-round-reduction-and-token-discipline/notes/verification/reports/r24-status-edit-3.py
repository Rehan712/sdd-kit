#!/usr/bin/env python3
# Session 22 (2026-10-15), end: STATUS's neutral sections only (frontmatter, Where things stand, Open questions, Handoff
# note, Next action) after reality-check round 2 (NEEDS WORK) and the user's decision to add the missing tests. Every byte
# of the Decisions log, from `## Decisions log` to `## Open questions / blockers`, is checked unchanged; the decision goes
# into Decisions in the next session's batch, with the task blocks and the round-20 waiver. Usage from the worktree
# root: python3 -I <this>
import shutil
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
path = spec + '/STATUS.md'
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
shutil.copyfile(path, rep + '/r24-STATUS-before-3.md')

def dec(x):
    a = x.index('\n## Decisions log\n'); b = x.index('\n## Open questions / blockers\n')
    return x[a:b]
before = dec(t)

def once(old, new):
    global t
    n = t.count(old)
    assert n == 1, 'anchor count %d: %r' % (n, old[:90])
    t = t.replace(old, new)

once('reality_check: NEEDS WORK (round 1 sealed 2026-09-21; 21 PASS, AC-016 FAIL, AC-019 MISSING; digest e5f957dbd673…)',
     'reality_check: NEEDS WORK (round 2 sealed 2026-10-15; 18 PASS; AC-007, AC-009, AC-010, AC-020, AC-022 FAIL for '
     'named cases with no fixture; digest 461c29c87123…; the user chose to add the tests as T031a1 to T031a4)')

once('## Where things stand\n\n',
     '## Where things stand\n\n'
     '**2026-10-15 (session 22, end) — reality-check round 2 sealed NEEDS WORK on FLOOR-GCDl2x; the user chose to add '
     'the missing tests; stopped at the user\'s request (neutral record; Decisions frozen at `2b58bbe7…`, source '
     '`1f0774dd…`).** Before the reservation the T029 typed control ran on T029\'s floor capture CAP-657-4toNJM '
     '(`rc2-control.{log,rc,time}`, exit 0: the incomplete copy rejected, `ACCEPT-XhPKuv`, class binding-mismatch, '
     'tasks digest unchanged; the intact return `c46f6098…` accepted, `ACC-hr3r6b`); reality-check round 2 reserved at '
     '2026-10-15T09:23:14Z (`rc2-reserve.{log,rc,time}`, exit 0); the live probe passed during it '
     '(`rc2-probe.{log,rc,time}`, exit 0: `live wiring PASS task=T029 ... opponent=completed '
     'reality-check=reserved-or-completed`). The independent reviewer (dispatched 10:00:41Z on '
     '`reality-check-round2-brief.md`, sha256 `052662af…`) returned **NEEDS WORK** (timestamp 10:25:59Z): 18 PASS, '
     'including AC-016 and AC-019, round 1\'s two failures; AC-007, AC-009, AC-010, AC-020 and AC-022 FAIL because '
     'cases their text names have no fixture (gaps 1 to 4, root cause implementation-error), while its scratch probes '
     '(`rc2-review-probes.txt`, `rc2-review-checks.log`) show the shipped code right in each probed case (AC-010\'s '
     'was not probed). The invoker confirmed each gap by reading the suites. File equals the returned message '
     '(`rc2-persist.{log,rc}`, exit 0, sha256 `461c29c8…`; provenance `reality-check-round2.note`); worktree states '
     'before reservation, at it and at return byte-identical (`r19-state-rc2-{prereserve,reserved,returned}.*`). '
     'Completion (`rc2-complete.{log,rc,time}`, exit 0: `round completed gate=reality-check round=2 verdict=NEEDS '
     'WORK`), tally (`rc2-tally.{log,rc}`, exit 0: opponent rounds=19, reality-check rounds=2) and the final audit '
     '(`rc2-final-audit.{sh,log,rc}`, exit 0, 68 PASS, 0 FAIL). Handoff state: `r24-handoff-state.{txt,rc,err}`.\n\n')

once('## Open questions / blockers\n\n',
     '## Open questions / blockers\n\n'
     '- [ ] **User decision, 2026-10-15 (session 22), after reality-check round 2 (NEEDS WORK); to be written to '
     'Decisions in the next batch.** Asked: "Reality-check round 2 is NEEDS WORK: 5 criteria (AC-007, AC-009, AC-010, '
     'AC-020, AC-022) name cases that no test asserts. The code behaves correctly in the cases the reviewer probed; only '
     'tests are missing. Any fix moves the source, so the tools then require a new floor (~5.5 h), opponent round 20 '
     '(needs your exact-round authorization), hosted CI, and reality-check round 3. How should I proceed?" The user '
     'chose "Add the tests (Recommended)", described as: add the missing fixtures as T031a1 to T031a4 (test files '
     'only, no kernel change); the answer authorizes opponent round 20; then one batch, one capture, one floor, round '
     '20, CI and reality-check round 3. Not chosen: revising the five ACs; stopping. The user then asked to finish the '
     'steps in progress and stop for a next session.\n'
     '- [ ] **Reality-check round 2 gaps (2026-10-15; owned by T031a1 to T031a4 once opened).** (1) AC-022, '
     '`tests/test-spec-gate.sh::test_acceptance`: a return with no `Failure modes:` block; a task owing no rows '
     'accepted with an explicit `Failure modes: none`; `Captures:` naming a nonexistent capture; a capture whose '
     'command exited nonzero; a manual return whose artifact is absent; a capture of an unrelated explicit command '
     'whose log names the test, refused with `do not prove this task Verify`; for a valid acceptance, the '
     '`*Evidence:*` line asserted and only the target task\'s lines changed; each invalid return leaving tasks.md '
     'byte-identical. (2) AC-007 and AC-020: in `reuse_floor_cases` (called by `test_floor`, '
     '`tests/test-spec-gate.sh:567`) change an opted-in gate_checks command string and assert the suite counter '
     'increments with `cache-hits=0` for it; and in `capture_validity_cases` (called by `test_capture_provenance`, '
     '`tests/test-verification.sh:378`) a capture with a different argv is not reused. (3) AC-010, '
     '`tests/test-gate-contracts.sh::test_reports_and_tally`: two findings of one Class in different files with '
     'different Root causes count one recurrence; two Classes sharing a file and Root cause count zero each; an '
     'annotated copy of 002\'s opponent history binding its clock and lock findings to stable classes detects both '
     'recurrences, the original bytes unchanged. (4) AC-009, `tests/test-spec-gate.sh::test_rounds`: a copy of 002\'s '
     'date-only history refuses the next authorization at exit 4 with `date-only history needs timestamped digest '
     'reconciliation`, reconciles through `round --reconcile`, and a later exact waiver then authorizes and reserves '
     'the next round. The reviewer\'s probes `focused2.sh`, `focused3.sh` and `focused4.sh` in '
     '`rc2-review-probes.txt` exercise most of these. Out of scope, recorded: two assertions that can never fail '
     '(`tests/test-spec-gate.sh:557` checks a `model-called` file nothing creates; `:661` a next-stage marker nothing '
     'chains) and the untested plan-level warnings at `scripts/verification-lib.sh:1323-1326`.\n')

once('## Handoff note\n\n',
     '## Handoff note\n\n'
     '**2026-10-15 (session 22, end) — reality-check round 2; receipts index.** Under `notes/verification/reports/`: '
     '`rc2-step.sh`; `rc2-control.{log,rc,time}`; `r19-state-rc2-{prereserve,reserved,returned}.{txt,entries}`; '
     '`rc2-reserve.{log,rc,time}`; `rc2-probe.{log,rc,time}`; `reality-check-round2-brief.{draft.md,md,sha256}`, '
     '`rc2-brief-fill.{py,log,rc}`, `rc2-brief-values.json`, `rc2-dispatch.time`; `reality-check-round2.{md,note}`, '
     '`rc2-review-probes.txt`, `rc2-review-checks.log` (the reviewer\'s); `rc2-persist-report.py`, '
     '`rc2-persist.{log,rc}`, `rc2-return.time`; `rc2-complete.{log,rc,time}`, `rc2-tally.{log,rc}`, '
     '`rc2-final-audit.{sh,log,rc}`; `r19-poststatus-2.{txt,err}`; `r24-handoff-state.{txt,rc,err}` (`r19-freeze.sh` '
     'output at the end of the session). STATUS before this edit: `r24-STATUS-before-3.md` (edited by '
     '`r24-status-edit-3.py`).\n\n')

once('## Next action\n\n**2026-10-15 (session 22, later)',
     '## Next action\n\n'
     '**2026-10-15 (session 22, end) — reality-check round 2 NEEDS WORK; the user chose to add the missing tests '
     '(T031a1 to T031a4) and authorized opponent round 20.** With '
     '`r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports`, from the worktree '
     'root, following round 19\'s pattern (`r19-edits/`, `r19-batch-apply.sh`, `r19-*.sh`):\n'
     '1. Entry: `bash $r/r19-freeze.sh` equals `r24-handoff-state.txt` but `taken=`.\n'
     '2. Write the fixtures for gaps 1 to 4 (Open questions) in a standalone copy; one dev run there '
     '(`r20-dev.*`, `tests/run.sh` and `tests/shellcheck.sh`, exit 0).\n'
     '3. One batch (`r20-edits/decisions-1.py`, `apply-docs.py`, `apply-code.py` through a `r20-batch-apply.sh`), '
     'scratch then live: Decisions gets reality-check round 2\'s outcome, the user\'s decision of 2026-10-15, the '
     'T031a1 to T031a4 task blocks (test files only; Verify `bash tests/run.sh && bash tests/shellcheck.sh`; bindings '
     'acceptance FM-006, FM-010, INV-002; floor and provenance FM-012, FM-014, INV-001; reports FM-019, INV-006; '
     'rounds FM-016, INV-004) with the dev run, the round-20 waiver (`gate=opponent; round=20; after=19`) and a '
     'freezing entry; tasks.md gets the four blocks (a stage such as Tests).\n'
     '4. Freeze point, one capture of record, returns, `spec-gate.sh accept` for T031a1 to T031a4.\n'
     '5. One floor on AC, detached (about 5.5 h), validate, scope against FLOOR-GCDl2x.\n'
     '6. Opponent round 20 (prereserve, reserve, brief, opponent, returned, complete, tally, final audit).\n'
     '7. On CLEARED: hosted CI by the snapshot method (copy `platforms/ci-20261015/`, use `collect-2.sh`\'s '
     '`--allow-escape-sequences`), the T029 control on the new floor\'s T029 capture, reality-check round 3 (no '
     'waiver), complete, tally, final audit. On READY: ask the user about the guarded PR (`spec-pr.sh`, T032), merge '
     'and rollout (T033); T034 is deferred.\n'
     'Not authorized: shipped 002\'s reset parsing, the open-extent task, the round-19 follow-ups F1 to F4, commits to '
     'the spec branch, the guarded PR and merge before the user is asked, bypasses.\n\n'
     '*Superseded by the entry above, kept for the record:*\n\n'
     '**2026-10-15 (session 22, later)')

assert dec(t) == before, 'the Decisions log changed'
assert '\r' not in t
open(path, 'wb').write(t.encode('utf-8'))
print('STATUS neutral sections edited; Decisions log unchanged')
