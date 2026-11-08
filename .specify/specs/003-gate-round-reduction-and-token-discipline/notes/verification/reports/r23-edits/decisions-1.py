#!/usr/bin/env python3
# Session 25 (2026-10-17): the T031a4o3 batch for the Decisions log, appended as its last entries, in byte mode:
# opponent round 22's outcome, the user's decision after round 22, the task block with the one dev run, the round-23
# waiver stamped at writing time, and the freeze. Receipt values are read and asserted, never typed. Only the
# Decisions log changes: every byte before it and from `## Open questions / blockers` on is checked unchanged.
# Pattern: r22-edits/decisions-1.py.
# Usage: python3 -I <this> <root> <UTC timestamp for the waiver>
import os, re, sys
root, ts = sys.argv[1], sys.argv[2]
assert re.fullmatch(r'2026-10-(1[7-9]|2[0-9])T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]Z', ts), ts
assert ts > '2026-10-17T19:00:57Z', 'the waiver must follow round 22\'s completion'
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = os.path.join(root, spec, 'notes/verification/reports')
path = os.path.join(root, spec, 'STATUS.md')
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
def rd(name):
    return open(os.path.join(rep, name), encoding='utf-8').read()
dev_log = rd('r23-dev.log'); dev_t = rd('r23-dev.time').split()
assert rd('r23-dev.rc').strip() == '0' and len(dev_t) == 2
m = re.search(r'^suites=(\S+) shellcheck_rc=0 run_rc=0 mutants_killed=(\d+)/(\d+) o029_assertions_killed=(\d+)/(\d+)$', dev_log, re.M)
assert m and m.group(2) == m.group(3) and m.group(4) == m.group(5), 'the dev run summary is missing or incomplete'
assert re.search(r'^mutant readround .* \(held equivalent by round 21\)$', dev_log, re.M)
for name in ('r22-complete.rc', 'r22-tally.rc', 'r22-final-audit.rc', 'r22-reserve.rc', 'r22-persist.rc'):
    assert rd(name).strip() == '0', (name, rd(name))
assert 'verdict=CHALLENGED report=106c04377eb7b2017769681a05a7ed834d43adbef90d1186ab58568e82348f9a' in rd('r22-complete.log')
assert 'reserved=2026-10-17T08:50:29Z' in rd('r22-reserve.log')
tally = rd('r22-tally.log')
assert 'opponent rounds=22' in tally and 'blocking=39 minor=24' in tally
npass = len(re.findall(r'^PASS ', rd('r22-final-audit.log'), re.M))
assert not re.search(r'^FAIL ', rd('r22-final-audit.log'), re.M)
assert 'Fix the issue then continue' in rd('r22-user-decision-1.txt')
assert 'sha256 106c04377eb7b2017769681a05a7ed834d43adbef90d1186ab58568e82348f9a' in rd('r22-persist-provenance.txt')
assert 'waiver: gate=opponent; round=23;' not in t, 'refusing: the round-23 waiver exists'
anchor = '\n## Open questions / blockers\n'
assert t.count(anchor) == 1 and t.count('\n## Decisions log\n') == 1
head, tail = t.split(anchor)
assert head.endswith('\n') and not head.endswith('\n\n'), 'unexpected end of the Decisions log'

E = []
E.append('- 2026-10-17 — Opponent round 22 is recorded here now that this batch moves the source anyway: CHALLENGED, '
    '1 blocking + 2 minor, report digest `106c04377eb7b2017769681a05a7ed834d43adbef90d1186ab58568e82348f9a`, against '
    'source `809a9b69…` and FLOOR-3Ge8eO (sealed at rc 0, 21 executed and 76 reused, 2026-10-16T21:17:35Z to '
    '2026-10-17T03:28:15Z, validated current), reserved 2026-10-17T08:50:29Z, report timestamp 15:15:47Z. The '
    'reviewer was stopped by the usage limit before its hand-back, so by the user\'s decision the finished block was '
    'persisted byte-exact from its work dir (`notes/verification/reports/r22-persist-provenance.txt`, '
    '`r22-persist.{log,rc}`; no reviewer-stated digest exists). `--complete` and `tally` both exit 0 '
    '(`r22-complete.{log,rc,time}`, `r22-tally.{log,rc}`: opponent=22, blocking=39, minor=24), the final audit exit 0, '
    '%d PASS (`r22-final-audit.{sh,log,rc,time}`). O-029 stays open (wrong-result, root cause plan-gap, blocks AC-009 '
    'and REQ-012): T031a4o2 moved the only valid record to 2026-07-21T06:00:00Z, so the history\'s own date was '
    'unpinned and the record had zero minutes and seconds; a kernel reading a same-day record as the date\'s midnight, '
    'or truncating the record to its hour or minute, passed the case. O-033 is new (minor, degraded, fails closed): '
    'the later-day guard, the validity check in `--reconcile` and the future half by date or year were unpinned. '
    'O-032 stays open (minor, degraded), for the follow-up spec, no kernel change authorized. The kernel was right '
    'in every probe; the invoker did not reproduce the findings this session (the user asked to keep only the steps '
    'the tools require). This entry moves Decisions, so FLOOR-3Ge8eO and round 22\'s observation become historical '
    'for the new source.' % npass)
E.append('- 2026-10-17 — User decision of 2026-10-17 (session 25), after round 22. Asked: "Round 22 is sealed '
    'CHALLENGED on O-029, and the audit passed (76/76). How should O-029 be handled?" with the note that a waiver in '
    'Decisions before reality-check round 3 needs a fresh floor. Offered: repair now as T031a4o3 (test files only, '
    'the reviewer\'s recipe; a fresh floor, an exact-round authorization of round 23, then reality-check round 3); '
    'waive with reality-check round 3 first; waive first with a fresh floor. The user answered "Fix the issue then '
    'continue", read as: repair O-029 now as T031a4o3, then capture, accept, a fresh floor, opponent round 23 (this '
    'answer authorizes it) and reality-check round 3, then commit and push to PR #20. Receipt: '
    '`notes/verification/reports/r22-user-decision-1.txt`. The rest of the session-24 sequence stands (Decisions '
    'above): minor findings do not stop; on CLEARED, hosted CI if the Actions limit has reset, the T029 control, '
    'reality-check round 3, then commit and push to PR #20; on READY, the user is asked before the PR is marked ready '
    'and about the merge (T033). Not authorized: shipped 002\'s reset parsing, the open-extent task, the round-19 '
    'follow-ups F1 to F4, the O-032 kernel change, merge, any bypass. The retro (T034) stays deferred.')
E.append('- 2026-10-17 — T031a4o3 (O-029 with O-033, AC-009 and REQ-012) is opened, Tests, binding plan §7\'s rounds '
    'family (`tests/test-spec-gate.sh::test_rounds`, FM-016, INV-004), with the Verify `bash tests/run.sh && bash '
    'tests/shellcheck.sh`. Test files only, no kernel change: applied by '
    '`notes/verification/reports/r23-edits/apply-code.py` (refusing unless the suite hashes as after T031a4o2), the '
    'block by `r23-edits/apply-docs.py`. The one dev run, in a standalone copy built from the live enumeration with '
    'both scripts applied and a `TMPDIR` ending in `/` (`notes/verification/reports/r23-dev.{sh,log,rc,time}`, %s to '
    '%s, the live status outside `notes/verification/` unchanged): `tests/run.sh` passed %s and `tests/shellcheck.sh` '
    'passed, exit 0; then each of the %s mutants opponent rounds 20, 21 and 22 ran against the T031a fixtures '
    '(`r23-edits/mutants-r23.py`, round 22\'s eleven copied verbatim from the reviewer\'s work dir) was applied to the '
    'copy\'s kernel, its focus case run alone and the kernel restored by `cmp`: every mutant was killed but '
    '`readround`, the read-path round check alone, which round 21 held equivalent and which survives; and %s of %s '
    'O-029 and O-033 assertions were each killed by at least one mutant.'
    % (dev_t[0], dev_t[1], m.group(1), m.group(3), m.group(4), m.group(5)))
E.append('- %s — waiver: gate=opponent; round=23; after=22; by=Rehan712; reason=user chose on 2026-10-17 after round '
    '22 to repair the still-open O-029 as T031a4o3 (test files only) and authorized opponent round 23, so round 23 '
    'assesses that change against a fresh floor sealed after it is accepted' % ts)
E.append('- 2026-10-17 — Decisions are FROZEN from this batch through the live apply of T031a4o3, its capture and '
    'acceptance, the floor, round 23\'s completion and tally, and, on CLEARED, any hosted CI run, the T029 control and '
    'reality-check round 3 on that floor; results go to STATUS\'s neutral sections only, so that the floor stays '
    'current for both gates.')
for e in E:
    assert '\n' not in e and '\r' not in e
assert E[3].count('; ') == 4, 'a waiver needs exactly five fields'
assert head.endswith('.\n') or head.endswith('`\n') or head.endswith(')\n'), repr(head[-40:])
new = head + '\n' + '\n\n'.join(E) + '\n' + anchor + tail
open(path, 'wb').write(new.encode('utf-8'))
print('appended %d entries; waiver %s' % (len(E), ts))
