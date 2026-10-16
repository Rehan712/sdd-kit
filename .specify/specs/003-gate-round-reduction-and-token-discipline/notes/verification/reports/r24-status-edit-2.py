#!/usr/bin/env python3
# Session 22 (2026-10-15), after opponent round 19 and the hosted CI run, before reality-check round 2: STATUS's neutral
# sections only (frontmatter, Where things stand, Open questions, Handoff note, Next action). Every byte of the Decisions
# log, from `## Decisions log` to `## Open questions / blockers`, is checked unchanged. Usage from the worktree root:
# python3 -I <this>
import shutil
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
path = spec + '/STATUS.md'
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
shutil.copyfile(path, rep + '/r24-STATUS-before-2.md')

def dec(x):
    a = x.index('\n## Decisions log\n'); b = x.index('\n## Open questions / blockers\n')
    return x[a:b]
before = dec(t)

def once(old, new):
    global t
    n = t.count(old)
    assert n == 1, 'anchor count %d: %r' % (n, old[:90])
    t = t.replace(old, new)

once('opponent: CHALLENGED (round 18 consumed 2026-10-14; 2 blocking + 1 minor; digest aeb8c870ffbc…; O-018, O-025 and '
     'O-023 repaired as T030o54 to T030o56, accepted 2026-10-15; round 19 authorized, not yet run)',
     'opponent: CLEARED (round 19 consumed 2026-10-15; 0 blocking + 3 minor; digest a99077db6dc4…; O-026, O-027 and '
     'O-028 new, minor under REQ-011 as revised, for the follow-up spec)')

once('## Where things stand\n\n',
     '## Where things stand\n\n'
     '**2026-10-15 (session 22, later) — FLOOR-GCDl2x sealed; opponent round 19 CLEARED, 0 blocking + 3 minor; hosted '
     'CI green on the same source; reality-check round 2 next (neutral record; Decisions frozen at `2b58bbe7…`, source '
     '`1f0774dd…`).** FLOOR-GCDl2x (`r19-floor-1.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}`, exit 0 and wrapper '
     'exit 0, 01:11:52Z to 06:45:03Z, 21 executed and 68 reused, on AC in all 334 samples, free disk 5.19 to 19.27 GiB) '
     'validated to the frozen source (`r19-floor-validate.{out,err,rc,time}`, exit 0, empty stderr); the scope diff '
     'against FLOOR-OgYGoP (`r19-scope.{log,rc}`, exit 0) differs only in the seven files the batch wrote. Round 19 '
     'reserved at 2026-10-15T07:27:04Z (`r19-reserve.{log,rc,time}`, exit 0); the independent opponent, dispatched '
     '07:29:47Z on `opponent-round19-brief.md` (sha256 `f6721f57…`), returned **CLEARED, Blocking 0, Minor 3** '
     '(timestamp 08:06:13Z): O-026 (a tilde before a backtick run: marked\'s text rule binds the run, so a br the gate '
     'reads inside a code span renders live), O-027 (a shortcut reference label holding a backtick that wraps, outside '
     'T030o54\'s one-line rule) and O-028 (markdown-it 12.3.2\'s label scan skipping a backtick pair after an unclosed '
     'bracket), all new, class gate-report-schema-validation, minor under REQ-011 as revised; it held T030o54, T030o55 '
     'and T030o56, did not challenge the revision, and proposed F1 to F4 for the follow-up spec. The file equals the '
     'returned message (`r19-persist.{log,rc}`, exit 0, sha256 `a99077db…`; provenance `opponent-round19.note`); the '
     'worktree states before reservation, at it and at return are byte-identical (`r19-state-{prereserve,reserved,'
     'returned}.*`). Completion (`r19-complete.{log,rc,time}`, exit 0: `round completed gate=opponent round=19 '
     'verdict=CLEARED report=a99077db…`), tally (`r19-tally.{log,rc}`, exit 0: opponent rounds=19, blocking=36 '
     'minor=18) and the final audit (`r19-final-audit.{log,rc}`, exit 0, 63 PASS, 0 FAIL: rounds 1-19 equal their '
     'sealed digests, source and Decisions unchanged, FLOOR-GCDl2x current, round 20 refused at exit 4). Hosted CI by '
     'the snapshot method (`notes/verification/platforms/ci-20261015-summary.txt`): run 38706127101 on draft PR #19, '
     'snapshot commit `5ebc8ef0…` (tree `cebddfdc…`, parent 0d55c62; HEAD and index untouched), all four jobs success '
     '(shellcheck; tests on ubuntu-latest and macos-latest; tests-bash32), 15 suites at 147/147 on each tests job; the '
     'tested merge `71c6eb4b…` has the snapshot\'s tree; PR #19 closed unmerged and its branch deleted. The first '
     'collection fetched no job logs (gh 2.102.0 needs `--allow-escape-sequences`); `collect-2.sh`, with that flag, '
     'passed.\n\n')

once('## Open questions / blockers\n\n',
     '## Open questions / blockers\n\n'
     '- [ ] **Round 19\'s three minor findings and proposed follow-ups (2026-10-15, session 22; for the follow-up spec '
     'REQ-011 names; no task authorized).** O-026 (tilde before a backtick run, marked only), O-027 (a wrapped shortcut, '
     'collapsed or image reference label holding a backtick), O-028 (markdown-it 12.3.2\'s label-scan backtick skip; '
     'root cause spec-gap: the spec names no reference renderer). Proposed: F1 refuse a backtick run directly after a '
     'tilde inside a finding, or place code spans by marked\'s text rule in one more reading; F2 refuse such a wrapped '
     'label; F3 name the reference renderers, or refuse a bracket left open before a backtick run; F4 add an upper-case '
     'scheme row for the URL-literal arm (dropping `tolower` survives every shipped row) and state the narrowed finding '
     'grammar in `agents/opponent.agent.md` (a persona-only gate agent can write a table or link inside a finding and be '
     'refused at completion; it fails closed). Neither blocks 003; the retro (T034) is deferred to after merge.\n')

once('## Handoff note\n\n',
     '## Handoff note\n\n'
     '**2026-10-15 (session 22, later) — round 19 and hosted CI; receipts index.** Every exit was read back from its '
     'receipt. Under `notes/verification/reports/` unless noted:\n'
     '- Floor: `r19-floor.sh`, `r19-floor-1.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}`, '
     '`r19-floor-validate.{out,err,rc,time}`, `r19-scope.{sh,log,rc}`, `r19-floorrun.txt`.\n'
     '- Round 19: `r19-state-{prereserve,reserved,returned}.{txt,entries}`, `r19-reserve.{log,rc,time}`, '
     '`opponent-round19-brief.{draft.md,md,sha256}`, `r19-brief-fill.{log,rc}`, `r19-dispatch.time`, '
     '`opponent-round19.{md,note}`, `r19-persist.{log,rc}`, `r19-return.time`, `r19-complete.{log,rc,time}`, '
     '`r19-tally.{log,rc}`, `r19-final-audit.{sh,log,rc}`.\n'
     '- Hosted CI: `notes/verification/platforms/ci-20261015/` (approval, scripts, build, commit, push, PR, wait, '
     '`collect.{log,rc}` with `run-38706127101/`, `collect-2.{sh,log,rc}` with `run-38706127101-2/`, finish, PR final '
     'state, gh accounts before and after) and `ci-20261015-summary.txt`.\n'
     '- Prepared for reality-check round 2: `rc2-step.sh` (control, reserve, probe, complete, tally), '
     '`rc2-final-audit.sh`, `reality-check-round2-brief.draft.md`.\n'
     '- STATUS before this edit: `r24-STATUS-before-2.md` (edited by `r24-status-edit-2.py`).\n\n')

once('## Next action\n\n**2026-10-15 (session 22, interim)',
     '## Next action\n\n'
     '**2026-10-15 (session 22, later) — opponent round 19 CLEARED and hosted CI green on source `1f0774dd…`; '
     'reality-check round 2 on FLOOR-GCDl2x is next (no waiver: rounds 1-3 need none).** From the worktree root, with '
     '`r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports`:\n'
     '1. `bash $r/rc2-step.sh control CAP-657-4toNJM` (T029\'s floor capture: `bash tests/test-gate-contracts.sh`, '
     '18/18, input the frozen source), before the state snapshot, since its acceptance rewrites T029\'s Evidence line.\n'
     '2. `bash $r/r19-worktree-state.sh rc2-prereserve`; `bash $r/rc2-step.sh reserve FLOOR-GCDl2x` (background); '
     '`bash $r/r19-worktree-state.sh rc2-reserved`; `bash $r/rc2-step.sh probe` (background; AC-016\'s live probe).\n'
     '3. Fill `reality-check-round2-brief.draft.md` into `reality-check-round2-brief.md`; dispatch the reality-check '
     'agent; `bash $r/r19-worktree-state.sh rc2-returned` (entries byte-identical to rc2-reserved).\n'
     '4. `rc2-step.sh complete`, then `tally`, then `rc2-final-audit.sh` with receipts; STATUS (neutral sections only).\n'
     '5. Ask the user about the guarded PR (`spec-pr.sh`, T032), merge and rollout (T033). T034 (retro) is deferred.\n'
     'No STATUS edit between the rc2-prereserve and rc2-returned states. Not authorized: shipped 002\'s reset parsing, '
     'the open-extent task, the follow-ups F1 to F4, commits to the spec branch, the guarded PR and merge before the '
     'user is asked, bypasses.\n\n'
     '*Superseded by the entry above, kept for the record:*\n\n'
     '**2026-10-15 (session 22, interim)')

assert dec(t) == before, 'the Decisions log changed'
assert '\r' not in t
open(path, 'wb').write(t.encode('utf-8'))
print('STATUS neutral sections edited; Decisions log unchanged')
