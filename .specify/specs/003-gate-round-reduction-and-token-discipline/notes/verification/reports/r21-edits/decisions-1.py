#!/usr/bin/env python3
# Session 24 (2026-10-16): the T031a1o1, T031a3o1 and T031a4o1 batch for the Decisions log, appended as its last
# entries, in byte mode: opponent round 20's outcome and the reproduction, the user's decisions of 2026-10-15 and
# 2026-10-16 with the commit and the draft PR they led to, the task blocks with the one dev run, the round-21 waiver
# stamped at writing time, and the freeze. The dev run's result is read from its receipts, never typed. Only the
# Decisions log changes: every byte before it and from `## Open questions / blockers` on is checked unchanged.
# Pattern: r20-edits/decisions-1.py.
# Usage: python3 -I <this> <root> <UTC timestamp for the waiver>
import os, re, sys
root, ts = sys.argv[1], sys.argv[2]
assert re.fullmatch(r'2026-10-1[6-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]Z', ts), ts
assert ts > '2026-10-16T02:30:02Z', 'the waiver must follow round 20\'s completion'
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = os.path.join(root, spec, 'notes/verification/reports')
path = os.path.join(root, spec, 'STATUS.md')
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
def rd(name):
    return open(os.path.join(rep, name), encoding='utf-8').read()
dev_rc = rd('r21-dev.rc').strip()
dev_log = rd('r21-dev.log')
dev_t = rd('r21-dev.time').split()
assert dev_rc == '0' and len(dev_t) == 2, (dev_rc, dev_t)
m = re.search(r'^suites=(\S+) shellcheck_rc=0 run_rc=0 o029_killed=(\d+)/(\d+)$', dev_log, re.M)
assert m and m.group(2) == m.group(3), 'the dev run log lacks its summary line or a mutant survived'
suites, killed = m.group(1), m.group(2)
for name, want in (('r20-complete.rc', '0'), ('r20-tally.rc', '0'), ('r20-final-audit.rc', '0'),
                   ('r20-repro-o029.rc', '0'), ('r20-pr.rc', '0'), ('r20-reserve.rc', '0')):
    assert rd(name).strip() == want, (name, rd(name))
assert 'verdict=CHALLENGED report=8630890bab45bfcae42acbeda45f203826c7c5afd1da494583ff7bb512602fdd' in rd('r20-complete.log')
assert 'reserved=2026-10-16T01:26:39Z' in rd('r20-reserve.log')
tally = rd('r20-tally.log')
assert 'opponent rounds=20' in tally and 'blocking=37 minor=21' in tally, tally[:200]
assert 'https://github.com/Rehan712/sdd-kit/pull/20' in rd('r20-pr.log')
assert 'waiver: gate=opponent; round=21;' not in t, 'refusing: the round-21 waiver exists'
anchor = '\n## Open questions / blockers\n'
assert t.count(anchor) == 1 and t.count('\n## Decisions log\n') == 1
head, tail = t.split(anchor)
assert head.endswith('\n') and not head.endswith('\n\n'), 'unexpected end of the Decisions log'

E = []
E.append('- 2026-10-16 — Opponent round 20 is recorded here now that this batch moves the source anyway: CHALLENGED, '
    '1 blocking + 3 minor, report digest `8630890bab45bfcae42acbeda45f203826c7c5afd1da494583ff7bb512602fdd`, against '
    'source `9cf02d45…` and FLOOR-UeGEcf (sealed at rc 0, 9 executed and 84 reused, 2026-10-15T21:09:28Z to '
    '2026-10-16T00:51:39Z, validated current), reserved 2026-10-16T01:26:39Z, report timestamp 02:09:54Z, '
    '`--complete` and `tally` both exit 0 (`notes/verification/reports/r20-complete.{log,rc,time}`, '
    '`r20-tally.{log,rc}`: opponent=20, blocking=37, minor=21), the final audit exit 0 (`r20-final-audit.{log,rc}`). '
    'It held T031a1 to T031a4 except as follows. O-029 (new, blocking, wrong-result, class '
    'named-case-fixture-strength, root cause implementation-error, blocks AC-009 and REQ-012): '
    '`round_legacy_reconcile_cases` passes when the kernel ignores the reconciled timestamp, drops the reconcile '
    'digest and round check, or drops all legacy binding; the kernel itself refuses each of those cases. Reproduced '
    'before any repair (`r20-repro-o029.{sh,log,rc,time}`, exit 0: under the timestamp mutant, in a standalone copy, '
    'the case passes; the live status outside `notes/verification/` unchanged). O-030 (minor): no empty '
    '`Failure modes:` header is refused for a task owing no rows. O-031 (minor): the 002 byte-identity checks in '
    '`tally_class_cases` can never fail. O-032 (degraded, class round-recovery-diagnostics): the legacy-record '
    'refusals exit 3 with no diagnostic; it needs a kernel change and goes to the follow-up spec, not authorized here. '
    'The commit `2049f65` of all 003 work and the draft PR (below) moved the source to `3e13d844…`, so FLOOR-UeGEcf '
    'and round 20\'s observation are historical for any later source.')
E.append('- 2026-10-16 — User instruction of 2026-10-15 (session 23), about 23:00Z, while floor attempt 2 ran, verbatim: '
    '"actually my github ci limit reached so skip that part after opponent continue on reality check. Also ignore '
    'minor issues from opponent and reality checker. then continue creation of PR". Asked two questions, the user '
    'chose: (1) "Draft PR with --force (Recommended)": open the PR as a draft through `spec-pr.sh --force --draft`, '
    'the body showing the real verdicts; the PR\'s own CI proves AC-019 once the GitHub Actions limit resets, then '
    'it is marked ready (T033 merge later, with the user); not chosen: wait for CI and open a normal PR; local '
    'evidence instead of CI. (2) "Yes, commit and push (Recommended)": one commit of all 003 work, its message ending '
    'with the Co-Authored-By line, pushed to the spec branch as Rehan712 through a process-scoped GH_TOKEN, then the '
    'PR; not chosen: stop before committing. So: no hosted CI run while the Actions limit holds, and minor findings '
    'of either gate do not stop the sequence. Receipt: `notes/verification/reports/r20-user-decision-2.txt`.')
E.append('- 2026-10-16 — User decision of 2026-10-16 (session 23), after round 20. Asked: "Opponent round 20 is '
    'CHALLENGED on O-029 (a test-only weakness in the new AC-009 fixture; code is correct). How should I proceed?" '
    'The user chose "Draft PR now, fix later (Recommended)": skip reality-check round 3, commit, push and open the '
    'draft PR with `--force` showing opponent CHALLENGED, then fix O-029 (test-only) on the PR branch, with CI when '
    'the Actions limit resets, and re-gate before merge. Not chosen: reality-check round 3 then the draft PR; fix '
    'O-029 first, then the PR. Receipt: `r20-user-decision-3.txt`. Done in session 23: commit `2049f65` of all 003 '
    'work on the spec branch, pushed as Rehan712, and draft PR #20 (https://github.com/Rehan712/sdd-kit/pull/20) '
    'opened through `spec-pr.sh --force --draft` (`r20-pr.{log,rc,time}`, exit 0; the active gh account unchanged, '
    '`r20-gh-accounts-{before,after}.txt`). In session 24 the user authorized opponent round 21 for this repair and '
    'commits plus pushes of this work to the PR branch, and asked to finish fast: only the steps the tools require, '
    'no mutation matrix, no two-direction fixture judging, no separate measurement scripts, no repeated dev runs, '
    'except that each new O-029 assertion is shown killed by one of round 20\'s three mutants in the one dev run. '
    'Order: (a) the fixtures in a standalone copy and that dev run, done (entry below); (b) this batch; (c) the '
    'freeze point, one capture of record, the returns and accept; (d) one fresh floor on AC power; (e) round 21, '
    'complete, tally, the final audit; (f) on CLEARED, hosted CI for the exact source if the Actions limit has reset, '
    'the T029 control on the new floor\'s T029 capture, reality-check round 3 (rounds 1-3 need no authorization), '
    'then commit and push to the PR branch; if CI is still limited, reality-check round 3 anyway, commit, push and '
    'stop; (g) on READY, the user is asked before PR #20 is marked ready and about the merge and rollout (T033). Not '
    'authorized: shipped 002\'s reset parsing; the open-extent task; the round-19 follow-ups F1 to F4; the O-032 '
    'kernel change; merge; any bypass. The retro (T034) stays deferred.')
E.append('- 2026-10-16 — T031a1o1 (O-030, AC-022), T031a3o1 (O-031, AC-010) and T031a4o1 (O-029, AC-009 and REQ-012) '
    'are opened, Tests, binding plan §7\'s existing registry with no new families: acceptance '
    '(`tests/test-spec-gate.sh::test_acceptance`, FM-006, FM-010, INV-002); reports '
    '(`tests/test-gate-contracts.sh::test_reports_and_tally`, FM-019, INV-006); rounds '
    '(`tests/test-spec-gate.sh::test_rounds`, FM-016, INV-004). Each has the Verify `bash tests/run.sh && bash '
    'tests/shellcheck.sh`, so one capture on unchanged source can serve all three acceptances. Test files only, no '
    'kernel change: the cases start from round 20\'s report and `r20-repro-o029.sh` and are applied by '
    '`notes/verification/reports/r21-edits/apply-code.py` (refusing unless the two suites hash as at `2049f65`), the '
    'blocks by `r21-edits/apply-docs.py`. The one dev run, in a standalone copy built from the live enumeration with '
    'both scripts applied and a `TMPDIR` ending in `/` (`notes/verification/reports/r21-dev.{sh,log,rc,time}`, %s to '
    '%s, the live status outside `notes/verification/` unchanged): `tests/run.sh` passed %s and '
    '`tests/shellcheck.sh` passed, exit 0; then each of round 20\'s three mutants (`r21-edits/mutants-o029.py`: the '
    'reconciled timestamp ignored; the reconcile digest and round check removed; all legacy binding removed) was '
    'applied to the copy\'s kernel and restored by `cmp`, and %s of %s new O-029 assertions were each killed by at '
    'least one of them.' % (dev_t[0], dev_t[1], suites, killed, m.group(3)))
E.append('- %s — waiver: gate=opponent; round=21; after=20; by=Rehan712; reason=user chose on 2026-10-16 to repair '
    'round 20\'s O-029 with O-030 and O-031 as T031a4o1, T031a1o1 and T031a3o1 (test files only) on the PR branch '
    'and authorized opponent round 21, so round 21 assesses those changes against a fresh floor sealed after they '
    'are accepted' % ts)
E.append('- 2026-10-16 — Decisions are FROZEN from this batch through the live apply of T031a1o1, T031a3o1 and '
    'T031a4o1, their capture and acceptance, the floor, round 21\'s completion and tally, and, on CLEARED, any hosted '
    'CI run, the T029 control and reality-check round 3 on that floor; results go to STATUS\'s neutral sections '
    'only, so that the floor stays current for both gates.')
for e in E:
    assert '\n' not in e and '\r' not in e
waiver = E[4]
assert waiver.count('; ') == 4, 'a waiver needs exactly five fields'
assert head.endswith('.\n') or head.endswith('`\n') or head.endswith(')\n'), repr(head[-40:])
new = head + '\n' + '\n\n'.join(E) + '\n' + anchor + tail
open(path, 'wb').write(new.encode('utf-8'))
print('appended %d entries; waiver %s' % (len(E), ts))
