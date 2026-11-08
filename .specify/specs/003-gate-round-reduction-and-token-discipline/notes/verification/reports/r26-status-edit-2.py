#!/usr/bin/env python3
# Session 24 (2026-10-16), after round 21: STATUS's neutral sections only (the opponent frontmatter line, Where things
# stand, Open questions, Next action), recording round 21's outcome and the reproduction neutrally. Every byte of the
# Decisions log is checked unchanged; round 21's outcome goes into Decisions in the next batch. Values the receipts
# hold are read and asserted. Usage from the worktree root: python3 -I <this>
import re, shutil
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
path = spec + '/STATUS.md'
def rd(n):
    return open(rep + '/' + n, encoding='utf-8').read()
for n in ('r21-reserve.rc', 'r21-brief-fill.rc', 'r21-persist.rc', 'r21-complete.rc', 'r21-tally.rc', 'r21-final-audit.rc',
          'r21-repro-o029.rc'):
    assert rd(n).strip() == '0', (n, rd(n))
assert 'verdict=CHALLENGED report=9f3b01ba3392055b68f2e9d2093d5f5ca236c27baf25aeb37d0b28c6f65a0a1b' in rd('r21-complete.log')
assert 'reserved=2026-10-16T18:39:41Z' in rd('r21-reserve.log')
assert 'matches the reviewer-stated sha256' in rd('r21-persist.log')
assert 'final audit failures=0' in rd('r21-final-audit.log')
npass = len(re.findall(r'^PASS ', rd('r21-final-audit.log'), re.M))
tally = rd('r21-tally.log')
assert 'opponent rounds=21' in tally and 'blocking=38 minor=22' in tally
repro = rd('r21-repro-o029.log')
for m in ('endofday', 'clamp', 'future'):
    assert 'under the %s mutant: rc=0' % m in repro, m
assert 'unchanged' in repro
st = [open(rep + '/r21-state-%s.entries' % k, 'rb').read() for k in ('prereserve', 'reserved', 'returned')]
assert st[0] == st[1] == st[2]
ct = rd('r21-complete.time').split(); rt = rd('r21-repro-o029.time').split()
sha = open(rep + '/opponent-round21-brief.sha256', encoding='utf-8').read().split()[0]
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
shutil.copyfile(path, rep + '/r26-STATUS-before-2.md')

def dec(x):
    a = x.index('\n## Decisions log\n'); b = x.index('\n## Open questions / blockers\n')
    return x[a:b]
before = dec(t)

def once(old, new):
    global t
    n = t.count(old)
    assert n == 1, 'anchor count %d: %r' % (n, old[:90])
    t = t.replace(old, new)

m = re.search(r'^opponent: .*$', t, re.M)
once(m.group(0), 'opponent: CHALLENGED (round 21 consumed 2026-10-16; 1 blocking + 1 minor; digest 9f3b01ba3392…; '
     'O-029 still open, a test-only fixture gap for AC-009 (23:59:59Z coincides with an end-of-day reading); O-030 and '
     'O-031 resolved; O-032 degraded, follow-up spec)       # not-run | CHALLENGED | CLEARED | BLOCKED  (+ date)')

once('## Where things stand\n\n',
     '## Where things stand\n\n'
     '**2026-10-16 (session 24, after round 21) — opponent round 21 CHALLENGED, 1 blocking + 1 minor: O-029 still '
     'open, O-030 and O-031 resolved, O-032 degraded; reproduced; a choice for the user (neutral record; Decisions '
     'frozen at `3281e34c…`, source `fd20f46a…`, HEAD `2049f65`).** Round 21 reserved at 2026-10-16T18:39:41Z on '
     'FLOOR-5cLeox (`r21-reserve.{log,rc,time}`, exit 0); the independent opponent, dispatched 18:42:03Z on '
     '`opponent-round21-brief.md` (sha256 `' + sha[:8] + '…`), returned **CHALLENGED, Blocking 1, Minor 1** '
     '(timestamp 19:05:21Z). Its file tool refused the report path, so the block was persisted from its hand-back '
     '(`r21-persist-report.py`, now cutting a preamble at the block heading; `r21-persist.{log,rc}`, exit 0, sha256 '
     '`9f3b01ba…`, equal to the digest the reviewer stated). The worktree states before reservation, at reservation '
     'and at return are byte-identical (`r21-state-{prereserve,reserved,returned}.*`). `--complete` '
     '(`r21-complete.{log,rc,time}`, exit 0, %s to %s, free disk 1.74 to 1.76 GiB) sealed round 21; `tally` exit 0 '
     '(`r21-tally.{log,rc}`: opponent=21, blocking=38, minor=22); the final audit exit 0, %d PASS '
     '(`r21-final-audit.{sh,log,rc}`). O-029 (open, wrong-result, class named-case-fixture-strength, root cause '
     'plan-gap, blocks AC-009 and REQ-012): the repair reconciles round 5 to 2026-07-20T23:59:59Z, which an '
     'end-of-day reading of the history\'s date also yields, so a kernel ordering by 23:59:59Z of the date, or clamping '
     'the record to it, passes the case; and no case reconciles with a future timestamp, so the future half of the '
     '`--reconcile` date guard can be deleted with the case green. The kernel is right in every probe. Reproduced '
     '(`r21-repro-o029.{sh,log,rc,time}`, exit 0, %s to %s: the case passes under each of the three mutants '
     '`r21-edits/mutants-o029-r21.py` applies, the kernel restored by `cmp`, the live status outside '
     '`notes/verification/` unchanged). The reviewer killed round 20\'s three mutants and nine more, and proposes '
     'T031a4o2 (test files only): reconcile to 2026-07-21T06:00:00Z, refuse a waiver dated 2026-07-21T05:00:00Z with '
     '`not after the previous round completion at 2026-07-21T06:00:00Z`, refuse a future-stamped record before the '
     'valid one, each new assertion killed by the end-of-day, clamp and future-half mutants. O-030 and O-031 resolved '
     '(their mutants now killed). O-032 (open, degraded): after an edit of a reconciled history, `round --reconcile` '
     'with a correct record is itself refused, because the stale `legacy-time.nul` fails the history read first; only '
     'deleting that file by hand recovers; for the follow-up spec, no kernel change authorized. Free disk fell from 6.9 '
     'to 1.7 GiB during the review through activity outside the reviewer\'s and the invoker\'s directories.\n\n'
     % (ct[0][11:], ct[1][11:], npass, rt[0][11:], rt[1][11:]))

once('## Open questions / blockers\n\n',
     '## Open questions / blockers\n\n'
     '- [ ] **Round 21 CHALLENGED on O-029 (2026-10-16, session 24); NOT yet in Decisions (frozen at `3281e34c…`); a '
     'choice for the user.** Round 21\'s outcome goes into Decisions in the next batch. Options: repair as T031a4o2 '
     '(test files only, the reviewer\'s recipe), then a dev run, batch, capture, accept, a fresh floor (needs about 10 '
     'GiB free and AC), an authorized round 22 and reality-check round 3; or accept O-029\'s remaining risk with a '
     'signed waiver in Decisions and continue; or commit and push the current state and stop. Committing moves the '
     'source identity, so FLOOR-5cLeox would become historical.\n')

once('## Next action\n\n',
     '## Next action\n\n'
     '**2026-10-16 (session 24, after round 21) — round 21 CHALLENGED on O-029, reproduced; ask the user how to proceed '
     '(Open questions).** No STATUS edit between a prereserve and its returned state; no commit before the choice, since '
     'a commit makes FLOOR-5cLeox historical. Not authorized: round 22 (needs the user\'s exact-round authorization), '
     'shipped 002\'s reset parsing, the open-extent task, the round-19 follow-ups F1 to F4, the O-032 kernel change, '
     'merge, any bypass.\n\n'
     '*Superseded by the entry above, kept for the record:*\n\n')

assert dec(t) == before, 'the Decisions log changed'
open(path, 'wb').write(t.encode('utf-8'))
print('STATUS neutral sections edited; Decisions log unchanged; final audit PASS=%d' % npass)
