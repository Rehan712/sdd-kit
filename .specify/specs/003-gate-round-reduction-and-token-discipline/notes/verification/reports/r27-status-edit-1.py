#!/usr/bin/env python3
# Session 24 (2026-10-16/17), before round 22's reservation: STATUS's neutral sections only (Where things stand, Open
# questions, Next action) after the T031a4o2 batch, its acceptance and the round-22 floor. Every byte of the Decisions
# log is checked unchanged. Values the receipts hold are read and asserted, never typed. The floor's identity comes
# from r22-floor-1.log. Usage from the worktree root: python3 -I <this>
import re, shutil
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
path = spec + '/STATUS.md'
def rd(n):
    return open(rep + '/' + n, encoding='utf-8').read()
for n in ('r22-dev.rc', 'r22-batch-scratch.rc', 'r22-batch-live.rc', 'r22-freeze.rc', 'r22-capture.rc', 'r22-return-T031a4o2.rc',
          'T031a4o2-accept.rc', 'r22-postaccept.rc', 'r22-floor-1.rc', 'r22-floor-1.wrapper.rc', 'r22-floor-validate.rc', 'r22-scope.rc'):
    assert rd(n).strip() == '0', (n, rd(n))
assert rd('r22-floor-validate.err') == '', 'floor validation wrote stderr'
fz = rd('r22-freeze.txt')
src = re.search(r'^source=([0-9a-f]{64})$', fz, re.M).group(1)
dec = re.search(r'^decisions=([0-9a-f]{64})$', fz, re.M).group(1)
assert src == '809a9b69c4a360cc3e17c07a1f2126a872eb7c229768d4f36f948f228167a443', src
assert rd('r22-floor-validate.out').strip() == src
fl = re.search(r'^result=(FLOOR-[A-Za-z0-9]+) source=(\S+) exit=0 executed=(\d+) cache-hits=(\d+) ', rd('r22-floor-1.log'), re.M)
assert fl and fl.group(2) == src, rd('r22-floor-1.log')[:300]
floor, executed, hits = fl.group(1), fl.group(3), fl.group(4)
cap = re.search(r'^capture=(CAP-[0-9]+-[A-Za-z0-9]+) .* input=' + src, rd('r22-capture.log'), re.M).group(1)
acc = re.search(r'return=([0-9a-f]{64})', rd('T031a4o2-accept.log')).group(1)
dev = re.search(r'^suites=(\S+) shellcheck_rc=0 run_rc=0 mutants_killed=(\d+)/(\d+) o029_assertions_killed=(\d+)/(\d+)$', rd('r22-dev.log'), re.M)
assert dev
pre = rd('r22-floor-1.pre')
start = re.search(r'^start=(\S+)$', pre, re.M).group(1); end = re.search(r'^end=(\S+)$', pre, re.M).group(1)
samples = [l for l in rd('r22-floor-1.samples.log').splitlines() if ' power=' in l]
ac = sum(1 for l in samples if 'power=AC' in l); bat = len(samples) - ac
av = [float(x) for x in re.findall(r'avail=([0-9.]+)GiB', rd('r22-floor-1.samples.log'))]
vt = rd('r22-floor-validate.time').split()
scope = rd('r22-scope.log')
paths = sorted(set(re.findall(r'^[-+] path (\S+)$', scope, re.M)))
nindex = len(set(re.findall(r'^[-+] index (\S+)$', scope, re.M)))
dt = rd('r22-dev.time').split(); ct = [rd('r22-capture.start').strip(), rd('r22-capture.end').strip()]
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
shutil.copyfile(path, rep + '/r27-STATUS-before-1.md')
def decs(x):
    a = x.index('\n## Decisions log\n'); b = x.index('\n## Open questions / blockers\n')
    return x[a:b]
before = decs(t)
def once(old, new):
    global t
    n = t.count(old)
    assert n == 1, 'anchor count %d: %r' % (n, old[:90])
    t = t.replace(old, new)
power = 'on AC in all %d samples' % ac if bat == 0 else 'on AC in %d samples and on battery in %d' % (ac, bat)
once('## Where things stand\n\n',
     '## Where things stand\n\n'
     '**2026-10-17 (session 24, before round 22) — O-029 repaired again test-only as T031a4o2, proven and ACCEPTED; '
     '%s sealed on the frozen source; opponent round 22 next (neutral record; Decisions frozen at `%s…`, source '
     '`%s…`).** The user chose "Repair now" after round 21 (`r21-user-decision-1.txt`). The fixture, from round 21\'s '
     'recipe, applied by `r22-edits/apply-code.py`; an exploratory focus check of the O-029 mutants in a standalone '
     'copy before the dev run (not a receipt). The one dev run (`r22-dev.{sh,log,rc,time}`, exit 0, %s to %s): %s over '
     '15 suites plus ShellCheck; every one of the %s mutants opponent rounds 20 and 21 ran (`r22-edits/mutants-r22.py`) '
     'killed but `readround`, which round 21 held equivalent; %s of %s O-029 assertions each killed by at least one; '
     'the live status outside `notes/verification/` unchanged. The batch (`r22-batch-apply.sh`, waiver timestamp in '
     '`r22-batch.ts`), validated on a scratch copy and then live (`r22-batch-{scratch,live}.{log,rc}`, exit 0 each). '
     'Freeze point `r22-freeze.{txt,rc,err}` (exit 0): source `%s`, Decisions `%s`, HEAD `2049f65`. %s '
     '(`r22-capture.{log,rc,start,end}`, exit 0, input the frozen source, %s to %s); the return validated '
     '(`r22-return-T031a4o2.{log,rc}`, exit 0); **T031a4o2 ACCEPTED** (`T031a4o2-accept.{log,rc}`, exit 0, return '
     '`%s…`); the tick moved neither source, Decisions, waivers nor the test file (`r22-postaccept.{txt,rc,err}`). '
     'Free disk was 1.8 GiB before the floor; at the user\'s instruction ("Delete some target and node_modules from '
     'other projects") the idle Rust build directories `~/projects/memvault/target` (6.1 GiB, last written 18:43Z, '
     'during round 21) and `~/projects/sales-platform/target` (5.1 GiB) were removed after checking no process used '
     'them (`r22-disk-reclaim.txt`; 13 GiB free after). During the floor another session\'s memvault build refilled '
     'the disk twice (00:13Z to 00:22Z, and from about 01:30Z); the user paused it the first time and, the second '
     'time, chose "Kill build + delete target"; by then the build had ended and the floor had sealed, and its '
     'regenerated `target` (13 GiB) was removed with nothing holding it open (`r22-disk-reclaim.txt`, 15 GiB free '
     'after). **%s** (`r22-floor-1.{pre,log,rc,samples.log,wrapper.log,'
     'wrapper.rc}`, exit 0 and wrapper exit 0, %s to %s, %s executed and %s reused, %s; free disk %.1f to %.1f GiB) '
     'validated to the frozen source (`r22-floor-validate.{out,err,rc,time}`, exit 0, empty stderr, %s to %s). The '
     'scope diff against FLOOR-5cLeox (`r22-scope.{log,rc}`, exit 0) differs in content only in %s, %s.\n\n'
     % (floor, dec[:8], src[:8], dt[0], dt[1], dev.group(1), dev.group(3), dev.group(4), dev.group(5), src, dec, cap,
        ct[0], ct[1], acc[:8], floor, start, end, executed, hits, power, min(av), max(av), vt[0], vt[1],
        ', '.join('`%s`' % p for p in paths), ('and in no other record' if nindex == 0 else 'and in the `index` records of %d paths' % nindex)))
once('- [ ] **Round 21 CHALLENGED on O-029 (2026-10-16, session 24); NOT yet in Decisions (frozen at `3281e34c…`); a choice for the user.**',
     '- [x] *Done: the user chose "Repair now" (`r21-user-decision-1.txt`); round 21\'s outcome and the decision are in Decisions since the T031a4o2 batch; T031a4o2 accepted; round 22 gates it.* **Round 21 CHALLENGED on O-029 (2026-10-16, session 24); NOT yet in Decisions (frozen at `3281e34c…`); a choice for the user.**')
once('## Next action\n\n',
     '## Next action\n\n'
     '**2026-10-17 (session 24, before round 22) — %s sealed; round 22, then (on CLEARED) hosted CI if the Actions '
     'limit has reset, the T029 control and reality-check round 3, then commit and push to PR #20.** With '
     '`r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports`, from the worktree '
     'root: `bash $r/r22-worktree-state.sh prereserve`; `bash $r/r22-gate-step.sh reserve %s` (background); `bash '
     '$r/r22-worktree-state.sh reserved`; `python3 -I $r/r22-brief-fill.py <written> <disk> <floor-run text file>`; '
     'dispatch the opponent on `opponent-round22-brief.md`; persist (`r22-persist-report.py`); `r22-worktree-state.sh '
     'returned`; `r22-gate-step.sh complete`, `tally`, `r22-final-audit.sh`. On CLEARED (minor findings do not stop): '
     'ask or check whether the user\'s GitHub Actions limit has reset; `bash $r/rc3-step.sh control <T029 capture of '
     '%s>` before `r22-worktree-state.sh rc3-prereserve`; `rc3-step.sh reserve %s`, `rc3-reserved`, `rc3-step.sh '
     'probe`, the brief (`rc3-brief-fill.py`), the reality-check agent, `rc3-returned`, `rc3-step.sh complete`, '
     '`tally`, `rc3-final-audit.sh`; then commit and push to the PR branch as Rehan712 (process-scoped GH_TOKEN). On '
     'READY: ask the user before marking PR #20 ready and about the merge (T033). On CHALLENGED or NEEDS WORK beyond '
     'minor findings: reproduce, record neutrally, ask the user only on a real choice. No STATUS edit between a '
     'prereserve and its returned state. Not authorized: shipped 002\'s reset parsing, the open-extent task, the '
     'round-19 follow-ups F1 to F4, the O-032 kernel change, merge, any bypass.\n\n'
     '*Superseded by the entry above, kept for the record:*\n\n' % (floor, floor, floor, floor))
assert decs(t) == before, 'the Decisions log changed'
open(path, 'wb').write(t.encode('utf-8'))
print('STATUS neutral sections edited; Decisions log unchanged; floor=%s scope paths: %s; index=%d' % (floor, ', '.join(paths), nindex))
