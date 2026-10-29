#!/usr/bin/env python3
# Session 23 (2026-10-16), before round 20's reservation: STATUS's neutral sections only (frontmatter `updated:`, Where
# things stand, Open questions, Next action) after the T031a1 to T031a4 batch, their acceptance and FLOOR-UeGEcf, with
# the user's instruction of 2026-10-15 (no hosted CI, minor findings do not stop, a draft PR with --force, commit and
# push). Every byte of the Decisions log, from `## Decisions log` to `## Open questions / blockers`, is checked
# unchanged; the instruction goes into Decisions in the next batch. Usage from the worktree root: python3 -I <this>
import shutil
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
path = spec + '/STATUS.md'
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
shutil.copyfile(path, rep + '/r25-STATUS-before-1.md')

def dec(x):
    a = x.index('\n## Decisions log\n'); b = x.index('\n## Open questions / blockers\n')
    return x[a:b]
before = dec(t)

def once(old, new):
    global t
    n = t.count(old)
    assert n == 1, 'anchor count %d: %r' % (n, old[:90])
    t = t.replace(old, new)

once('\nupdated: 2026-10-15\n', '\nupdated: 2026-10-16\n')

once('## Where things stand\n\n',
     '## Where things stand\n\n'
     '**2026-10-16 (session 23, before round 20) — T031a1 to T031a4 written, proven and ACCEPTED; FLOOR-UeGEcf sealed on '
     'the frozen source; opponent round 20 next; no hosted CI, by the user\'s instruction (neutral record; Decisions '
     'frozen at `ff60b48b…`, source `9cf02d45…`).** Entry (`r20-entry.{txt,err,rc}`, exit 0) equals '
     '`r24-handoff-state.txt` but `taken=`. The fixtures for reality-check round 2\'s gaps 1 to 4 (test files only, '
     'from the reviewer\'s probes), applied by `r20-edits/apply-code.py`; the one dev run (`r20-dev.{sh,log,rc,time}`, '
     'exit 0, 16:39:15Z to 17:02:51Z): 147/147 over 15 suites plus ShellCheck, the live status outside '
     '`notes/verification/` unchanged. The batch (`r20-batch-apply.sh`, waiver timestamp `2026-10-15T17:03:04Z` in '
     '`r20-batch.ts`), validated on a scratch copy (`r20-batch-scratch.{log,rc}`, exit 0) and then live '
     '(`r20-batch-live.{log,rc}`, exit 0): every written file byte-identical to the validated copy, round 19 still '
     'reported completed, round 20 authorized, round 21 refused at exit 4, the analyzer at 0 errors, the four blocks '
     'present and unticked, the freezing entry last; the delta in `r20-session.diff`. Freeze point '
     '`r20-freeze.{txt,rc,err}` (exit 0): source `9cf02d45d97952557c41180743b973563e854825d6d2d5e73b1db3b72be4dfa5`, '
     'Decisions `ff60b48b99947f0f597106a935dd792dd1d31dd47b7b7037d6c3857251cc7e1f`. CAP-678-tyxcke '
     '(`r20-capture.{log,rc,start,end}`, exit 0, 147/147 plus ShellCheck, input the frozen source, 17:04:24Z to '
     '17:27:25Z); the returns validated (`r20-return-T031a{1,2,3,4}.{log,rc}`, exit 0 each); **T031a1 to T031a4 '
     'ACCEPTED** (`T031a{1,2,3,4}-accept.{log,rc}`, exit 0 each; returns `fc2c2d9e…`, `fe2d6670…`, `15122b56…`, '
     '`620f3398…`); the ticks moved neither source, Decisions, waivers nor the test files (`r20-postaccept.{txt,rc,err}`). '
     'Floor attempt 1 (`r20-floor-1.*`) FAILED at rc 3 and sealed nothing: the Mac left AC at 19:26:35Z (the user '
     'unplugged it for about an hour and asked to continue), then another session\'s builds in `~/projects/memvault` '
     'filled the disk to 0.12 GiB and the floor\'s own snapshot copy hit `No space left on device` at 19:49:53Z; the '
     'user freed space; no lock, no staging capture left, twelve complete exit-0 captures CAP-679 to CAP-690 kept '
     '(`r20-floor-1.note`). Attempt 2 (`r20-floor-2.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}`, exit 0 and '
     'wrapper exit 0, 21:09:28Z to 00:51:39Z, on AC except 22:00:39Z to 22:24:54Z on battery, 97% to 80%, by the '
     'user\'s choice; free disk 11.9 to 14 GiB) sealed **FLOOR-UeGEcf**: source `9cf02d45…`, 9 executed and 84 reused. '
     'The scope diff against FLOOR-GCDl2x (`r20-scope.{log,rc}`, exit 0) differs only in the five files the batch '
     'wrote (STATUS.md, tasks.md and the three suites). The user\'s instruction of 2026-10-15 (Open questions, '
     '`r20-user-decision-2.txt`): the hosted CI run is skipped (the GitHub Actions limit is reached), minor findings '
     'of either gate do not stop the sequence, and after reality-check round 3 the 003 work is committed and pushed '
     'and the PR opened as a draft through `spec-pr.sh --force --draft`.\n\n')

once('- [ ] **User decision, 2026-10-15 (session 22), after reality-check round 2 (NEEDS WORK); to be written to Decisions in the next batch.**',
     '- [x] *Done: written to Decisions in the T031a1 to T031a4 batch (2026-10-15, session 23).* **User decision, 2026-10-15 (session 22), after reality-check round 2 (NEEDS WORK); to be written to Decisions in the next batch.**')
once('- [ ] **Reality-check round 2 gaps (2026-10-15; owned by T031a1 to T031a4 once opened).**',
     '- [x] *Superseded: fixtures added as T031a1 to T031a4 (accepted 2026-10-15, CAP-678-tyxcke); round 20 and reality-check round 3 gate them.* **Reality-check round 2 gaps (2026-10-15; owned by T031a1 to T031a4 once opened).**')
once('## Open questions / blockers\n\n',
     '## Open questions / blockers\n\n'
     '- [ ] **User instruction, 2026-10-15 (session 23), about 23:00Z, while floor attempt 2 ran; NOT yet in Decisions '
     '(frozen at `ff60b48b…`); it goes into the next batch.** Verbatim: "actually my github ci limit reached so skip '
     'that part after opponent continue on reality check. Also ignore minor issues from opponent and reality checker. '
     'then continue creation of PR". The invoker then asked two questions and the user chose: (1) "Draft PR with '
     '--force (Recommended)": after reality-check round 3, which without a hosted CI run on the current source will '
     'fail AC-019 ("the existing CI bash matrix"), open the PR as a draft through `spec-pr.sh --force --draft`, the '
     'body showing the real verdicts; the PR\'s own CI proves AC-019 once the Actions limit resets, then it is marked '
     'ready (T033 merge later, with the user); not chosen: wait for CI and open a normal PR; local evidence instead of '
     'CI. (2) "Yes, commit and push (Recommended)": one commit of all 003 work, its message ending with the '
     'Co-Authored-By line, pushed to the spec branch as Rehan712 through a process-scoped GH_TOKEN, then the PR; not '
     'chosen: stop before committing. Receipt: `notes/verification/reports/r20-user-decision-2.txt`.\n')

once('## Next action\n\n',
     '## Next action\n\n'
     '**2026-10-16 (session 23, before round 20) — FLOOR-UeGEcf sealed; round 20, then reality-check round 3 (no hosted '
     'CI), then the commit, push and a draft PR, as the user instructed on 2026-10-15.** With '
     '`r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports`, from the worktree '
     'root: `bash $r/r20-worktree-state.sh prereserve`; `bash $r/r20-gate-step.sh reserve FLOOR-UeGEcf` (background); '
     '`bash $r/r20-worktree-state.sh reserved`; `python3 -I $r/r20-brief-fill.py <written> <disk> <floor-run text '
     'file>`; dispatch the opponent on `opponent-round20-brief.md`; persist; `r20-worktree-state.sh returned`; '
     '`r20-gate-step.sh complete`, `tally`, `r20-final-audit.sh`. On CLEARED (minor findings do not stop): `bash '
     '$r/rc3-step.sh control <T029 capture of FLOOR-UeGEcf>` before `r20-worktree-state.sh rc3-prereserve`; '
     '`rc3-step.sh reserve FLOOR-UeGEcf`, `rc3-reserved`, `rc3-step.sh probe`, the brief '
     '(`rc3-brief-fill.py`), the reality-check agent, `rc3-returned`, `rc3-step.sh complete`, `tally`, '
     '`rc3-final-audit.sh`; then the commit, the push and `spec-pr.sh --force --draft`. On blocking findings: '
     'reproduce, record neutrally, ask the user. No STATUS edit between a prereserve and its returned state. Not '
     'authorized: shipped 002\'s reset parsing, the open-extent task, the round-19 follow-ups F1 to F4, merge, '
     'bypasses other than the draft `--force` the user chose.\n\n'
     '*Superseded by the entry above, kept for the record:*\n\n')

assert dec(t) == before, 'the Decisions log changed'
open(path, 'wb').write(t.encode('utf-8'))
print('STATUS neutral sections edited; Decisions log unchanged')
