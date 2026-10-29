#!/usr/bin/env python3
# Session 24 (2026-10-16): the T031a4o2 batch for the Decisions log, appended as its last entries, in byte mode:
# opponent round 21's outcome and the reproduction, the user's decision after round 21, the task block with the one
# dev run, the round-22 waiver stamped at writing time, and the freeze. Receipt values are read and asserted, never
# typed. Only the Decisions log changes: every byte before it and from `## Open questions / blockers` on is checked
# unchanged. Pattern: r21-edits/decisions-1.py.
# Usage: python3 -I <this> <root> <UTC timestamp for the waiver>
import os, re, sys
root, ts = sys.argv[1], sys.argv[2]
assert re.fullmatch(r'2026-10-1[6-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]Z', ts), ts
assert ts > '2026-10-16T19:32:30Z', 'the waiver must follow round 21\'s completion'
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = os.path.join(root, spec, 'notes/verification/reports')
path = os.path.join(root, spec, 'STATUS.md')
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
def rd(name):
    return open(os.path.join(rep, name), encoding='utf-8').read()
dev_log = rd('r22-dev.log'); dev_t = rd('r22-dev.time').split()
assert rd('r22-dev.rc').strip() == '0' and len(dev_t) == 2
m = re.search(r'^suites=(\S+) shellcheck_rc=0 run_rc=0 mutants_killed=(\d+)/(\d+) o029_assertions_killed=(\d+)/(\d+)$', dev_log, re.M)
assert m and m.group(2) == m.group(3) and m.group(4) == m.group(5), 'the dev run summary is missing or incomplete'
assert re.search(r'^mutant readround .* \(held equivalent by round 21\)$', dev_log, re.M)
for name in ('r21-complete.rc', 'r21-tally.rc', 'r21-final-audit.rc', 'r21-repro-o029.rc', 'r21-reserve.rc', 'r21-persist.rc'):
    assert rd(name).strip() == '0', (name, rd(name))
assert 'verdict=CHALLENGED report=9f3b01ba3392055b68f2e9d2093d5f5ca236c27baf25aeb37d0b28c6f65a0a1b' in rd('r21-complete.log')
assert 'reserved=2026-10-16T18:39:41Z' in rd('r21-reserve.log')
tally = rd('r21-tally.log')
assert 'opponent rounds=21' in tally and 'blocking=38 minor=22' in tally
npass = len(re.findall(r'^PASS ', rd('r21-final-audit.log'), re.M))
assert 'Repair now (Recommended)' in rd('r21-user-decision-1.txt')
assert 'waiver: gate=opponent; round=22;' not in t, 'refusing: the round-22 waiver exists'
anchor = '\n## Open questions / blockers\n'
assert t.count(anchor) == 1 and t.count('\n## Decisions log\n') == 1
head, tail = t.split(anchor)
assert head.endswith('\n') and not head.endswith('\n\n'), 'unexpected end of the Decisions log'

E = []
E.append('- 2026-10-16 — Opponent round 21 is recorded here now that this batch moves the source anyway: CHALLENGED, '
    '1 blocking + 1 minor, report digest `9f3b01ba3392055b68f2e9d2093d5f5ca236c27baf25aeb37d0b28c6f65a0a1b`, against '
    'source `fd20f46a…` and FLOOR-5cLeox (sealed at rc 0, 21 executed and 75 reused, 2026-10-16T08:49:36Z to '
    '14:35:34Z, validated current), reserved 2026-10-16T18:39:41Z, report timestamp 19:05:21Z, persisted from the '
    'reviewer\'s hand-back (`r21-persist.{log,rc}`, the digest the reviewer stated), `--complete` and `tally` both '
    'exit 0 (`notes/verification/reports/r21-complete.{log,rc,time}`, `r21-tally.{log,rc}`: opponent=21, '
    'blocking=38, minor=22), the final audit exit 0, %d PASS (`r21-final-audit.{sh,log,rc}`). O-029 stays open '
    '(wrong-result, root cause plan-gap, blocks AC-009 and REQ-012): the repair reconciled to 2026-07-20T23:59:59Z, '
    'which an end-of-day reading of the history\'s date also yields, so a kernel ordering by that end of day, or '
    'clamping the record to it, passes the case, and no case reconciled with a future timestamp. Reproduced '
    '(`r21-repro-o029.{sh,log,rc,time}`, exit 0: the case passes under each of the three mutants). O-030 and O-031 '
    'are resolved (their mutants now killed). O-032 (open, degraded) adds that after an edit of a reconciled history '
    '`round --reconcile` with a correct record is itself refused, because the stale `legacy-time.nul` fails the '
    'history read first; for the follow-up spec, no kernel change authorized. This entry moves Decisions, so '
    'FLOOR-5cLeox and round 21\'s observation become historical for the new source.' % npass)
E.append('- 2026-10-16 — User decision of 2026-10-16 (session 24), after round 21. Asked: "Opponent round 21 is '
    'CHALLENGED on O-029 again: the fixture\'s 23:59:59Z reconcile time coincides with an end-of-day reading of the '
    'date, so 3 mutants survive (reproduced). The kernel itself is correct; the risk is a future regression passing '
    'green. O-030/O-031 are resolved. How should I proceed?" The user chose "Repair now (Recommended)": add '
    'T031a4o2, test files only, with the reviewer\'s recipe (reconcile at 2026-07-21T06:00:00Z, refuse a 05:00:00Z '
    'waiver, refuse a future-stamped record), the one dev run killing every mutant the reviewers ran, then capture, '
    'accept, a new floor, opponent round 22 (this answer authorizes it) and reality-check round 3. Not chosen: accept '
    'O-029\'s remaining risk with a signed waiver and continue; commit, push and stop. Receipt: '
    '`notes/verification/reports/r21-user-decision-1.txt`. The rest of the session-24 sequence stands (Decisions '
    'above): minor findings do not stop; on CLEARED, hosted CI if the Actions limit has reset, the T029 control, '
    'reality-check round 3, then commit and push to PR #20; on READY, the user is asked before the PR is marked ready '
    'and about the merge (T033). Not authorized: shipped 002\'s reset parsing, the open-extent task, the round-19 '
    'follow-ups F1 to F4, the O-032 kernel change, merge, any bypass. The retro (T034) stays deferred.')
E.append('- 2026-10-16 — T031a4o2 (O-029, AC-009 and REQ-012) is opened, Tests, binding plan §7\'s rounds family '
    '(`tests/test-spec-gate.sh::test_rounds`, FM-016, INV-004), with the Verify `bash tests/run.sh && bash '
    'tests/shellcheck.sh`. Test files only, no kernel change: applied by '
    '`notes/verification/reports/r22-edits/apply-code.py` (refusing unless the suite hashes as after T031a4o1), the '
    'block by `r22-edits/apply-docs.py`. The one dev run, in a standalone copy built from the live enumeration with '
    'both scripts applied and a `TMPDIR` ending in `/` (`notes/verification/reports/r22-dev.{sh,log,rc,time}`, %s to '
    '%s, the live status outside `notes/verification/` unchanged): `tests/run.sh` passed %s and `tests/shellcheck.sh` '
    'passed, exit 0; then each of the %s mutants opponent rounds 20 and 21 ran against the T031a fixtures '
    '(`r22-edits/mutants-r22.py`) was applied to the copy\'s kernel, its focus case run alone and the kernel restored '
    'by `cmp`: every mutant was killed but `readround`, the read-path round check alone, which round 21 held '
    'equivalent and which survives; and %s of %s O-029 assertions were each killed by at least one mutant.'
    % (dev_t[0], dev_t[1], m.group(1), m.group(3), m.group(4), m.group(5)))
E.append('- %s — waiver: gate=opponent; round=22; after=21; by=Rehan712; reason=user chose on 2026-10-16 after round '
    '21 to repair the still-open O-029 as T031a4o2 (test files only) and authorized opponent round 22, so round 22 '
    'assesses that change against a fresh floor sealed after it is accepted' % ts)
E.append('- 2026-10-16 — Decisions are FROZEN from this batch through the live apply of T031a4o2, its capture and '
    'acceptance, the floor, round 22\'s completion and tally, and, on CLEARED, any hosted CI run, the T029 control and '
    'reality-check round 3 on that floor; results go to STATUS\'s neutral sections only, so that the floor stays '
    'current for both gates.')
for e in E:
    assert '\n' not in e and '\r' not in e
assert E[3].count('; ') == 4, 'a waiver needs exactly five fields'
assert head.endswith('.\n') or head.endswith('`\n') or head.endswith(')\n'), repr(head[-40:])
new = head + '\n' + '\n\n'.join(E) + '\n' + anchor + tail
open(path, 'wb').write(new.encode('utf-8'))
print('appended %d entries; waiver %s' % (len(E), ts))
