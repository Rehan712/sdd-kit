#!/usr/bin/env python3
# Session 23 (2026-10-15): the T031a1 to T031a4 batch for the Decisions log, appended as its last entries, in byte
# mode: round 19's outcome and the hosted CI run, reality-check round 2's outcome, the user's decision of 2026-10-15,
# the task blocks with the one dev run, the round-20 waiver stamped at writing time, and the freeze. The dev run's
# result is read from its receipts, never typed. Only the Decisions log changes: every byte before it and from
# `## Open questions / blockers` on is checked unchanged. Pattern: r19-edits/decisions-1.py.
# Usage: python3 -I <this> <root> <UTC timestamp for the waiver>
import os, re, sys
root, ts = sys.argv[1], sys.argv[2]
assert re.fullmatch(r'2026-10-1[5-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]Z', ts), ts
assert ts > '2026-10-15T10:51:43Z', 'the waiver must follow reality-check round 2\'s completion'
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = os.path.join(root, spec, 'notes/verification/reports')
path = os.path.join(root, spec, 'STATUS.md')
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
dev_rc = open(os.path.join(rep, 'r20-dev.rc'), encoding='utf-8').read().strip()
dev_log = open(os.path.join(rep, 'r20-dev.log'), encoding='utf-8').read()
dev_t = open(os.path.join(rep, 'r20-dev.time'), encoding='utf-8').read().split()
assert dev_rc == '0' and len(dev_t) == 2, (dev_rc, dev_t)
m = re.search(r'^suites=(\S+) shellcheck_rc=0 run_rc=0$', dev_log, re.M)
assert m, 'the dev run log lacks its summary line'
suites = m.group(1)
assert 'waiver: gate=opponent; round=20;' not in t, 'refusing: the round-20 waiver exists'
anchor = '\n## Open questions / blockers\n'
assert t.count(anchor) == 1 and t.count('\n## Decisions log\n') == 1
head, tail = t.split(anchor)
assert head.endswith('\n') and not head.endswith('\n\n'), 'unexpected end of the Decisions log'

E = []
E.append('- 2026-10-15 — Opponent round 19 and the hosted CI run are recorded here now that this batch moves the source '
    'anyway. Round 19: CLEARED, 0 blocking + 3 minor, report digest '
    '`a99077db6dc4193ef8d0551d858140ed3d7ad25a9e317ec3e0402c87203388cf`, against source `1f0774dd…` and FLOOR-GCDl2x '
    '(sealed at rc 0, 21 executed and 68 reused, 01:11:52Z to 06:45:03Z on AC, validated current), reserved '
    '2026-10-15T07:27:04Z, report timestamp 08:06:13Z, `--complete` and `tally` both exit 0 '
    '(`notes/verification/reports/r19-complete.{log,rc,time}`, `r19-tally.{log,rc}`: opponent=19, blocking=36, '
    'minor=18), the final audit exit 0 (`r19-final-audit.{log,rc}`). It held T030o54, T030o55 and T030o56, did not '
    'challenge the REQ-011 revision, and recorded O-026, O-027 and O-028 (new, minor under REQ-011 as revised, class '
    'gate-report-schema-validation) with follow-ups F1 to F4 for the follow-up spec REQ-011 names; none is authorized. '
    'Hosted CI by the snapshot method, under item 3 of the user\'s decision of 2026-10-14: run 38706127101 on draft '
    'PR #19 (snapshot `5ebc8ef0…`, tree `cebddfdc…`, the tested merge with the same tree), all four jobs success '
    '(shellcheck; tests on ubuntu-latest and macos-latest; tests-bash32), 147/147 on each tests job; PR #19 closed '
    'unmerged and its branch deleted (`notes/verification/platforms/ci-20261015-summary.txt`). This entry moves '
    'Decisions, so FLOOR-GCDl2x, round 19\'s observation and that CI evidence become historical for the new source.')
E.append('- 2026-10-15 — Reality-check round 2 on FLOOR-GCDl2x: NEEDS WORK, report digest '
    '`461c29c87123638ff98512ba1b39b101875e932b056f17d67f1e9b465c84fd1e`, reserved 2026-10-15T09:23:14Z, report '
    'timestamp 10:25:59Z, `--complete` and `tally` both exit 0 (`rc2-complete.{log,rc,time}`, `rc2-tally.{log,rc}`), '
    'the final audit exit 0 (`rc2-final-audit.{sh,log,rc}`), after the T029 typed control on T029\'s floor capture '
    'CAP-657-4toNJM (`rc2-control.*`, exit 0) and with the live AC-016 probe passing during it (`rc2-probe.*`, exit '
    '0). Eighteen criteria PASS, including round 1\'s two failures (AC-016 and AC-019). AC-007, AC-009, AC-010, '
    'AC-020 and AC-022 FAIL only because cases their text names have no fixture (gaps 1 to 4, root cause '
    'implementation-error): (1) AC-022, acceptance with no Failure modes block, an explicit none, a nonexistent or '
    'failed capture, an absent manual artifact, an unrelated log naming the test, and a valid acceptance changing '
    'only its own task; (2) AC-007 and AC-020, a changed gate command executing again and a capture never reused '
    'for another argv; (3) AC-010, class recurrence across files and root causes and an annotated copy of 002; (4) '
    'AC-009, the explicit reconciliation of a date-only history. The reviewer\'s scratch probes '
    '(`rc2-review-probes.txt`, `rc2-review-checks.log`) show the shipped code right in each probed case (AC-010\'s '
    'was not probed); the invoker confirmed each gap by reading the suites. Recorded out of scope by the reviewer: two '
    'assertions that can never fail (`tests/test-spec-gate.sh:557`, a `model-called` file nothing creates; `:661`, a '
    'next-stage marker nothing chains) and the untested plan-level warnings at `scripts/verification-lib.sh:1323-1326`.')
E.append('- 2026-10-15 — User decision of 2026-10-15 (session 22), after reality-check round 2. Asked: "Reality-check '
    'round 2 is NEEDS WORK: 5 criteria (AC-007, AC-009, AC-010, AC-020, AC-022) name cases that no test asserts. The '
    'code behaves correctly in the cases the reviewer probed; only tests are missing. Any fix moves the source, so the '
    'tools then require a new floor (~5.5 h), opponent round 20 (needs your exact-round authorization), hosted CI, '
    'and reality-check round 3. How should I proceed?" The user chose "Add the tests (Recommended)": add the missing '
    'fixtures as T031a1 to T031a4 (test files only, no kernel change); the answer authorizes opponent round 20; then '
    'one batch, one capture, one floor, round 20, hosted CI and reality-check round 3. Not chosen: revising the five '
    'ACs; stopping. In session 23 the user confirmed it, authorized round 20 for this, and asked to finish fast: keep '
    'only the steps the tools require and skip the invoker\'s extra proof steps (no mutation matrix, no two-direction '
    'fixture judging, no separate measurement scripts, no repeated dev runs). Order: (a) the fixtures written in a '
    'standalone copy and one dev run there, done (entry below); (b) this batch, before any live code; (c) the fixtures '
    'applied live, the freeze point, one capture of record, the returns and accept; (d) one fresh floor on AC power; '
    '(e) round 20, complete, tally, the final audit; (f) on CLEARED, hosted CI by the snapshot method, the T029 '
    'control on the new floor\'s T029 capture and reality-check round 3, which needs no waiver (rounds 1-3 need no '
    'authorization); (g) on READY, the user is asked for the guarded PR (T032), merge and rollout (T033). Not '
    'authorized: shipped 002\'s locale-dependent reset parsing; the open-extent follow-up task; the round-19 '
    'follow-ups F1 to F4; commits to the spec branch; the guarded PR and merge before the user is asked; any bypass. '
    'The retro (T034) stays deferred.')
E.append('- 2026-10-15 — T031a1 (AC-022, gap 1), T031a2 (AC-007 and AC-020, gap 2), T031a3 (AC-010, gap 3) and T031a4 '
    '(AC-009, gap 4) are opened, Tests, binding plan §7\'s existing registry with no new families: acceptance '
    '(`tests/test-spec-gate.sh::test_acceptance`, FM-006, FM-010, INV-002); floor and provenance '
    '(`tests/test-spec-gate.sh::test_floor`, `tests/test-verification.sh::test_capture_provenance`, FM-012, FM-014, '
    'INV-001); reports (`tests/test-gate-contracts.sh::test_reports_and_tally`, FM-019, INV-006); rounds '
    '(`tests/test-spec-gate.sh::test_rounds`, FM-016, INV-004). Each has the Verify `bash tests/run.sh && bash '
    'tests/shellcheck.sh`, so one capture on unchanged source can serve all four acceptances. Test files only, no '
    'kernel change: the cases start from the reviewer\'s probes and are applied by '
    '`notes/verification/reports/r20-edits/apply-code.py` (refusing unless the three suites hash as at the frozen '
    'source), the blocks by `r20-edits/apply-docs.py`. The one dev run, in a standalone copy built from the live '
    'enumeration with both scripts applied and a `TMPDIR` ending in `/` (`notes/verification/reports/'
    'r20-dev.{sh,log,rc,time}`, %s to %s, the live status outside `notes/verification/` unchanged): `tests/run.sh` '
    'passed %s and `tests/shellcheck.sh` passed, exit 0.' % (dev_t[0], dev_t[1], suites))
E.append('- %s — waiver: gate=opponent; round=20; after=19; by=Rehan712; reason=user chose on 2026-10-15 to add the '
    'fixtures reality-check round 2 found missing as T031a1 to T031a4 (test files only) and authorized opponent round '
    '20, so round 20 assesses those changes against a fresh floor sealed after they are accepted' % ts)
E.append('- 2026-10-15 — Decisions are FROZEN from this batch through the live apply of T031a1 to T031a4, their capture '
    'and acceptance, the floor, round 20\'s completion and tally, and, on CLEARED, the hosted CI run, the T029 control '
    'and reality-check round 3 on that floor; results go to STATUS\'s neutral sections only, so that the floor stays '
    'current for both gates.')
for e in E:
    assert '\n' not in e and '\r' not in e
waiver = E[4]
assert waiver.count('; ') == 4, 'a waiver needs exactly five fields'
assert head.endswith('.\n') or head.endswith('`\n') or head.endswith(')\n'), repr(head[-40:])
new = head + '\n' + '\n\n'.join(E) + '\n' + anchor + tail
open(path, 'wb').write(new.encode('utf-8'))
print('appended %d entries; waiver %s' % (len(E), ts))
