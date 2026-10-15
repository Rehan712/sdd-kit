#!/usr/bin/env python3
# Session 22 (2026-10-15), interim, before the round-19 floor: STATUS's neutral sections only (frontmatter, Where things
# stand, Open questions, Handoff note, Next action). Every byte of the Decisions log, from `## Decisions log` to
# `## Open questions / blockers`, is checked unchanged. Usage from the worktree root: python3 -I <this>
import shutil, sys
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
path = spec + '/STATUS.md'
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
shutil.copyfile(path, rep + '/r24-STATUS-before-1.md')

def dec(x):
    a = x.index('\n## Decisions log\n'); b = x.index('\n## Open questions / blockers\n')
    return x[a:b]
before = dec(t)

def once(old, new):
    global t
    n = t.count(old)
    assert n == 1, 'anchor count %d: %r' % (n, old[:90])
    t = t.replace(old, new)

once('opponent: CHALLENGED (round 18 consumed 2026-10-14; 2 blocking + 1 minor; digest aeb8c870ffbc…; O-018 reopened, '
     'O-025 new, O-023 reopened; reproduced; NOT yet in Decisions; round 19 not authorized; repair choices wait for the user)',
     'opponent: CHALLENGED (round 18 consumed 2026-10-14; 2 blocking + 1 minor; digest aeb8c870ffbc…; O-018, O-025 and '
     'O-023 repaired as T030o54 to T030o56, accepted 2026-10-15; round 19 authorized, not yet run)')
once('\nupdated: 2026-10-14\n', '\nupdated: 2026-10-15\n')

once('## Where things stand\n\n',
     '## Where things stand\n\n'
     '**2026-10-15 (session 22, interim, before the floor) — the round-18 repair batch written; T030o54, T030o55 and '
     'T030o56 applied, proven and ACCEPTED; Decisions frozen at `2b58bbe7…` with source `1f0774dd…`; FLOOR-OgYGoP '
     'historical; round 19 authorized, its floor next (neutral record).** Entry: `r23-handoff-state.sh` run again '
     'equals `r23-handoff-state-3.txt` but time, free disk, power and swap (`r24-entry-state.{txt,err,rc}`, exit 0, '
     'empty stderr; on AC, 11 GiB free, swap 1.8 of 3.0 GB). The one dev run (`r19-dev.{sh,log,rc,time}`, exit 0, '
     '2026-10-14T23:56:48Z to 2026-10-15T00:22:29Z): 147/147 over 15 suites plus ShellCheck on a standalone copy with '
     '`r19-edits/apply-code.py` and `apply-docs.py` applied, the live status outside `notes/verification/` unchanged. '
     'The batch (`r19-batch-apply.sh`; waiver timestamp `2026-10-15T00:22:50Z`, kept in `r19-batch.ts`): '
     '`decisions-1.py`, then `apply-docs.py`, then `apply-code.py`, validated on a scratch copy '
     '(`r19-batch-scratch.{log,rc}`, exit 0) and then live (`r19-batch-live.{log,rc}`, exit 0): every written file '
     'byte-identical to the validated copy, round 18 still reported completed, round 19 authorized, round 20 refused '
     'at exit 4, the analyzer at 0 errors, T030o54 to T030o56 present and unticked, the freezing entry the last '
     'Decisions entry; STATUS, spec and tasks before it in `r24-{STATUS,spec,tasks}-before-batch.md`, the delta in '
     '`r19-session.diff`, the new hashes in `r19-edits/post-apply.sha256`. Freeze point `r19-freeze.{txt,rc,err}` '
     '(exit 0): source `1f0774ddf738539f83236db08fa7f8847c3e9a276964fc5582730ed6bd5c8a66`, Decisions '
     '`2b58bbe7be71a9ce18f4df7cf5f641d272b589702580dfcbc4fd7e53f7a2025e`. CAP-656-JZJTKB '
     '(`r19-capture.{log,rc,start,end}`, exit 0, 147/147 over 15 suites plus ShellCheck, input the frozen source, '
     '00:24:41Z to 01:06:00Z, slowed by an unrelated Rust build loading the Mac); the returns validated '
     '(`r19-return-T030o5{4,5,6}.{log,rc}`, exit 0 each); **T030o54, T030o55 and T030o56 ACCEPTED** '
     '(`T030o5{4,5,6}-accept.{log,rc}`, exit 0 each; returns `b8aec2da…`, `33a257ab…`, `606eee62…`); the ticks moved '
     'neither source, Decisions, HEAD, lock nor waivers (`r19-postaccept.{txt,rc,err}`). Prepared for round 19, each '
     'from its r18 version: `r19-floor.sh`, `r19-gate-step.sh`, `r19-scope.sh` (against FLOOR-OgYGoP), '
     '`r19-worktree-state.sh`, `r19-final-audit.sh` (digests 1-19, round 20 refused), `r19-brief-fill.py`, '
     '`r19-persist-report.py`, and `opponent-round19-brief.draft.md` (the waiver and acceptance filled; the '
     'reservation, floor run and disk left to `r19-brief-fill.py`).\n\n')

DONE = '*Done: written to Decisions in the round-18 repair batch (2026-10-15, session 22).* '
once('- [ ] **User decision, 2026-10-14 (session 21), to finish 003 quickly.**',
     '- [x] ' + DONE + '**User decision, 2026-10-14 (session 21), to finish 003 quickly.**')
once('- [ ] **User decision, 2026-10-14 (session 21), after round 18 was reported',
     '- [x] ' + DONE + '**User decision, 2026-10-14 (session 21), after round 18 was reported')
once('- [ ] **Round 18 consumed 2026-10-14 (session 21):',
     '- [x] *Superseded: recorded in Decisions in session 22 and repaired as T030o54 to T030o56, accepted 2026-10-15.* '
     '**Round 18 consumed 2026-10-14 (session 21):')
once('- [ ] **O-018 reopened (round 18, blocking,',
     '- [x] *Superseded: repaired as T030o54 (accepted 2026-10-15, CAP-656-JZJTKB, return `b8aec2da…`); round 19 '
     'gates it.* **O-018 reopened (round 18, blocking,')
once('- [ ] **O-025 (round 18, new, blocking,',
     '- [x] *Superseded: repaired as T030o55 (accepted 2026-10-15, return `33a257ab…`); round 19 gates it.* '
     '**O-025 (round 18, new, blocking,')
once('- [ ] **O-023 reopened (round 18, minor,',
     '- [x] *Superseded: repaired as T030o56 (accepted 2026-10-15, return `606eee62…`); round 19 gates it.* '
     '**O-023 reopened (round 18, minor,')

once('## Handoff note\n\n',
     '## Handoff note\n\n'
     '**2026-10-15 (session 22) — the round-18 repair batch, T030o54 to T030o56 accepted; receipts index.** Every exit '
     'was read back from its receipt. Under `notes/verification/reports/`:\n'
     '- Entry: `r24-entry-state.{txt,err,rc}` (exit 0; `r23-handoff-state.sh` run again).\n'
     '- Dev: `r19-dev.{sh,log,rc,time}`.\n'
     '- Batch: `r19-edits/{decisions-1,apply-docs,apply-code}.py`, `r19-batch-apply.sh`, `r19-batch.ts`, '
     '`r19-batch-{scratch,live}.{log,rc}` with `r19-batch-{scratch,live}-{decisions,docs,code}.log`, `r19-waiver-*`, '
     '`r19-analyze-{scratch,live}.{log,rc}`; `r24-{STATUS,spec,tasks}-before-batch.md`; `r19-session.diff`; '
     '`r19-edits/post-apply.sha256`.\n'
     '- Freeze and acceptance: `r19-freeze.{sh,txt,rc,err}`, `r19-capture.{log,rc,start,end}`, `r19-return.sh` with '
     '`r19-return-T030o5{4,5,6}.{log,rc}`, `T030o5{4,5,6}-accept.{log,rc}`, `r19-postaccept.{txt,rc,err}`.\n'
     '- Prepared for round 19: `r19-floor.sh`, `r19-gate-step.sh`, `r19-scope.sh`, `r19-worktree-state.sh`, '
     '`r19-final-audit.sh`, `r19-brief-fill.py`, `r19-persist-report.py`, `opponent-round19-brief.draft.md`.\n'
     '- STATUS before this edit: `r24-STATUS-before-1.md` (edited by `r24-status-edit.py`).\n\n')

once('## Next action\n\n**2026-10-14 (session 21, later; stopped at 7% battery)',
     '## Next action\n\n'
     '**2026-10-15 (session 22, interim) — T030o54 to T030o56 accepted; Decisions frozen at `2b58bbe7…` with source '
     '`1f0774dd…`; round 19 authorized; the floor is next.** With '
     '`r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports` and the Mac ON AC, '
     'from the worktree root:\n'
     '1. If `$r/r19-floor-1.rc` is absent and no floor runs (`pgrep -f \'spec-gate.sh floor\'`), launch it detached: '
     '`nohup bash -c \'bash "$1/r19-floor.sh" 1 > "$1/r19-floor-1.wrapper.log" 2>&1; echo $? > "$1/r19-floor-1.wrapper.rc"\' '
     '_ "$r" > /dev/null 2>&1 &` (about 5 hours). If one runs, wait on `r19-floor-1.rc` and read it back.\n'
     '2. `bash $r/r19-gate-step.sh validate FLOOR-<id>` (background), `bash $r/r19-scope.sh FLOOR-<id>` to '
     '`r19-scope.{log,rc}`, `bash $r/r19-worktree-state.sh prereserve`, `bash $r/r19-gate-step.sh reserve FLOOR-<id>` '
     '(background), `bash $r/r19-worktree-state.sh reserved`.\n'
     '3. `python3 -I $r/r19-brief-fill.py <date written> <free disk> <floor-run text file>`; dispatch the opponent '
     '(subagent type `opponent`) on `opponent-round19-brief.md`; resume it by message after a usage limit; '
     '`python3 -I $r/r19-persist-report.py <its transcript> $r/opponent-round19.md`; '
     '`bash $r/r19-worktree-state.sh returned`.\n'
     '4. `r19-gate-step.sh complete`, then `tally`, then `r19-final-audit.sh` in the background with receipts; STATUS '
     '(neutral sections only).\n'
     '5. On CLEARED: the hosted CI snapshot run and reality-check round 2 on the same floor, then ask the user about '
     'the guarded PR. On CHALLENGED: reproduce the findings and report them; ask only on a real choice.\n'
     'Not authorized: shipped 002\'s reset parsing, the open-extent task, commits to the spec branch, the guarded PR '
     'and merge before the user is asked, bypasses.\n\n'
     '*Superseded by the entry above, kept for the record:*\n\n'
     '**2026-10-14 (session 21, later; stopped at 7% battery)')

assert dec(t) == before, 'the Decisions log changed'
open(path, 'wb').write(t.encode('utf-8'))
print('STATUS neutral sections edited; Decisions log unchanged')
