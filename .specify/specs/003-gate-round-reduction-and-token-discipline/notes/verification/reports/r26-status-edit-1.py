#!/usr/bin/env python3
# Session 24 (2026-10-16), before round 21's reservation: STATUS's neutral sections only (Where things stand, Open
# questions, Next action) after the T031a1o1, T031a3o1 and T031a4o1 batch, their acceptance and FLOOR-5cLeox. Every
# byte of the Decisions log, from `## Decisions log` to `## Open questions / blockers`, is checked unchanged. Values
# that receipts hold are read from them and asserted, never typed. Usage from the worktree root: python3 -I <this>
import re, shutil
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
path = spec + '/STATUS.md'
def rd(n):
    return open(rep + '/' + n, encoding='utf-8').read()
for n in ('r21-entry.txt', 'r21-dev.rc', 'r21-batch-scratch.rc', 'r21-batch-live.rc', 'r21-freeze.rc', 'r21-capture.rc',
          'r21-return-T031a1o1.rc', 'r21-return-T031a3o1.rc', 'r21-return-T031a4o1.rc', 'T031a1o1-accept.rc',
          'T031a3o1-accept.rc', 'T031a4o1-accept.rc', 'r21-postaccept.rc', 'r21-floor-1.rc', 'r21-floor-1.wrapper.rc',
          'r21-floor-validate.rc', 'r21-scope.rc'):
    if n.endswith('.rc'):
        assert rd(n).strip() == '0', (n, rd(n))
assert rd('r21-floor-validate.err') == '', 'floor validation wrote stderr'
src = 'fd20f46a37268b1cd8bb7874982e3a26a1ce713a04418168d3c6b898edf76305'
assert rd('r21-floor-validate.out').strip() == src
assert ('source=%s' % src) in rd('r21-freeze.txt') and 'decisions=3281e34cc789ff6f6931a42dabb851c138d424e98a6ae1643c3ea1656d0d7f14' in rd('r21-freeze.txt')
assert 'result=FLOOR-5cLeox source=%s exit=0 executed=21 cache-hits=75' % src in rd('r21-floor-1.log')
assert 'capture=CAP-700-lvBf95 ' in rd('r21-capture.log') and ('input=%s' % src) in rd('r21-capture.log')
assert rd('r21-batch.ts').strip() == '2026-10-16T08:20:54Z'
vt = rd('r21-floor-validate.time').split()
assert len(vt) == 2
scope = rd('r21-scope.log')
paths = sorted(set(re.findall(r'^[-+] path (\S+)$', scope, re.M)))
assert paths == sorted([spec + '/STATUS.md', spec + '/tasks.md', 'tests/test-gate-contracts.sh', 'tests/test-spec-gate.sh']), paths
nindex = len(set(re.findall(r'^[-+] index (\S+)$', scope, re.M)))
assert nindex == 34, nindex
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
shutil.copyfile(path, rep + '/r26-STATUS-before-1.md')

def dec(x):
    a = x.index('\n## Decisions log\n'); b = x.index('\n## Open questions / blockers\n')
    return x[a:b]
before = dec(t)

def once(old, new):
    global t
    n = t.count(old)
    assert n == 1, 'anchor count %d: %r' % (n, old[:90])
    t = t.replace(old, new)

once('## Where things stand\n\n',
     '## Where things stand\n\n'
     '**2026-10-16 (session 24, before round 21) — O-029, O-030 and O-031 repaired test-only as T031a4o1, T031a1o1 '
     'and T031a3o1, proven and ACCEPTED; FLOOR-5cLeox sealed on the frozen source; opponent round 21 next (neutral '
     'record; Decisions frozen at `3281e34c…`, source `fd20f46a…`).** Entry (`r21-entry.txt`) equals '
     '`r25-handoff-state.txt` but `taken=`; free disk then 5.6 GiB, on battery. The fixtures, from round 20\'s report '
     'and `r20-repro-o029.sh`, applied by `r21-edits/apply-code.py`; the one dev run (`r21-dev.{sh,log,rc,time}`, '
     'exit 0, 07:54:58Z to 08:20:41Z): 147/147 over 15 suites plus ShellCheck, the live status outside '
     '`notes/verification/` unchanged, and 9 of 9 new O-029 assertions each killed by at least one of round 20\'s '
     'three mutants (`r21-edits/mutants-o029.py`; the kernel restored by `cmp` after each). An exploratory focused '
     'check in a standalone copy before it (not a receipt) moved one cleanup line after the assertion it was hiding. '
     'The batch (`r21-batch-apply.sh`, waiver timestamp `2026-10-16T08:20:54Z` in `r21-batch.ts`), validated on a '
     'scratch copy (`r21-batch-scratch.{log,rc}`, exit 0) and then live (`r21-batch-live.{log,rc}`, exit 0): every '
     'written file byte-identical to the validated copy, round 20 still reported completed, round 21 authorized, round '
     '22 refused at exit 4, the analyzer at 0 errors, the three blocks present and unticked, the freezing entry last; '
     'the delta in `r21-session.diff`. Freeze point `r21-freeze.{txt,rc,err}` (exit 0): source `' + src + '`, '
     'Decisions `3281e34cc789ff6f6931a42dabb851c138d424e98a6ae1643c3ea1656d0d7f14`, HEAD `2049f65`. CAP-700-lvBf95 '
     '(`r21-capture.{log,rc,start,end}`, exit 0, 147/147 plus ShellCheck, input the frozen source, 08:22:34Z to '
     '08:45:59Z); the returns validated (`r21-return-T031a{1,3,4}o1.{log,rc}`, exit 0 each); **T031a1o1, T031a3o1 and '
     'T031a4o1 ACCEPTED** (`T031a{1,3,4}o1-accept.{log,rc}`, exit 0 each); the ticks moved neither source, Decisions, '
     'waivers nor the test files (`r21-postaccept.{txt,rc,err}`). The user freed disk (about 19 GiB free) and put the '
     'Mac on AC before the floor. **FLOOR-5cLeox** (`r21-floor-1.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}`, '
     'exit 0 and wrapper exit 0, 08:49:36Z to 14:35:34Z, 21 executed and 75 reused, on AC in 339 samples and on '
     'battery at 100%% in the last 8, 14:28:56Z to 14:35:34Z; free disk 8.0 to 18.5 GiB) validated to the frozen source '
     '(`r21-floor-validate.{out,err,rc,time}`, exit 0, empty stderr, %s to %s). The scope diff against FLOOR-UeGEcf '
     '(`r21-scope.{log,rc}`, exit 0; 370 records against 371) differs in content (`path` records) only in the files '
     'the batch wrote, %s; its other differences are `index` records of %d paths, the git index entries the commit '
     '`2049f65` staged (`tests/shellcheck.sh`, new in 003, gains one). The reality-check round 3 tooling written for the '
     'round-20 path (`rc3-final-audit.sh`, `reality-check-round3-brief.draft.md`) was moved to the round-21 path, '
     'unused before.\n\n' % (vt[0], vt[1], ', '.join('`%s`' % p for p in paths), nindex))

once('- [ ] **Before merge (user decision 2026-10-16, session 23; NOT yet in Decisions):**',
     '- [ ] *In Decisions since the T031a1o1 to T031a4o1 batch (2026-10-16, session 24); the repair is T031a4o1, T031a1o1 and T031a3o1, accepted on CAP-700-lvBf95; round 21 gates it.* **Before merge (user decision 2026-10-16, session 23; NOT yet in Decisions):**')
once('- [ ] **User instruction, 2026-10-15 (session 23), about 23:00Z, while floor attempt 2 ran; NOT yet in Decisions',
     '- [x] *Done: written to Decisions in the T031a1o1 to T031a4o1 batch (2026-10-16, session 24).* **User instruction, 2026-10-15 (session 23), about 23:00Z, while floor attempt 2 ran; NOT yet in Decisions')

once('## Next action\n\n',
     '## Next action\n\n'
     '**2026-10-16 (session 24, before round 21) — FLOOR-5cLeox sealed; round 21, then (on CLEARED) hosted CI if the '
     'Actions limit has reset, the T029 control and reality-check round 3, then commit and push to PR #20.** With '
     '`r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports`, from the worktree '
     'root: `bash $r/r21-worktree-state.sh prereserve`; `bash $r/r21-gate-step.sh reserve FLOOR-5cLeox` (background); '
     '`bash $r/r21-worktree-state.sh reserved`; `python3 -I $r/r21-brief-fill.py <written> <disk> <floor-run text '
     'file>`; dispatch the opponent on `opponent-round21-brief.md`; persist (`r21-persist-report.py`); '
     '`r21-worktree-state.sh returned`; `r21-gate-step.sh complete`, `tally`, `r21-final-audit.sh`. On CLEARED (minor '
     'findings do not stop): ask or check whether the user\'s GitHub Actions limit has reset (hosted CI for the exact '
     'source if so); `bash $r/rc3-step.sh control <T029 capture of FLOOR-5cLeox>` before `r21-worktree-state.sh '
     'rc3-prereserve`; `rc3-step.sh reserve FLOOR-5cLeox`, `rc3-reserved`, `rc3-step.sh probe`, the brief '
     '(`rc3-brief-fill.py`), the reality-check agent, `rc3-returned`, `rc3-step.sh complete`, `tally`, '
     '`rc3-final-audit.sh`; then commit and push to the PR branch as Rehan712 (process-scoped GH_TOKEN). On READY: ask '
     'the user before marking PR #20 ready and about the merge and rollout (T033); T034 stays deferred. On CHALLENGED '
     'or NEEDS WORK beyond minor findings: reproduce, record neutrally, ask the user only on a real choice. No STATUS '
     'edit between a prereserve and its returned state. Not authorized: shipped 002\'s reset parsing, the open-extent '
     'task, the round-19 follow-ups F1 to F4, the O-032 kernel change, merge, any bypass.\n\n'
     '*Superseded by the entry above, kept for the record:*\n\n')

assert dec(t) == before, 'the Decisions log changed'
open(path, 'wb').write(t.encode('utf-8'))
print('STATUS neutral sections edited; Decisions log unchanged; scope paths: %s' % ', '.join(paths))
