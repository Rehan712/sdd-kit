#!/usr/bin/env python3
# Session 21 (2026-10-14): the round-18 repair batch for the Decisions log, appended as its last entries, in byte
# mode: round 18's outcome, the user's decisions of 2026-10-14, the reproduction, the spec revision, the task blocks
# with the one dev run, the round-19 waiver stamped at writing time, and the freeze. The dev run's result is read from
# its receipts, never typed. Only the Decisions log changes: every byte before it and from `## Open questions /
# blockers` on is checked unchanged. Usage: python3 -I <this> <root> <UTC timestamp for the waiver>
import os, re, sys
root, ts = sys.argv[1], sys.argv[2]
assert re.fullmatch(r'2026-10-1[4-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]Z', ts), ts
assert ts > '2026-10-14T17:08:04Z', 'the waiver must follow round 18\'s completion'
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = os.path.join(root, spec, 'notes/verification/reports')
path = os.path.join(root, spec, 'STATUS.md')
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
dev_rc = open(os.path.join(rep, 'r19-dev.rc'), encoding='utf-8').read().strip()
dev_log = open(os.path.join(rep, 'r19-dev.log'), encoding='utf-8').read()
dev_t = open(os.path.join(rep, 'r19-dev.time'), encoding='utf-8').read().split()
assert dev_rc == '0' and len(dev_t) == 2, (dev_rc, dev_t)
m = re.search(r'^suites=(\S+) shellcheck_rc=0 run_rc=0$', dev_log, re.M)
assert m, 'the dev run log lacks its summary line'
suites = m.group(1)
assert 'waiver: gate=opponent; round=19;' not in t, 'refusing: the round-19 waiver exists'
anchor = '\n## Open questions / blockers\n'
assert t.count(anchor) == 1 and t.count('\n## Decisions log\n') == 1
head, tail = t.split(anchor)
assert head.endswith('\n') and not head.endswith('\n\n'), 'unexpected end of the Decisions log'

E = []
E.append('- 2026-10-14 — Opponent round 18 is recorded here now that this batch moves the source anyway: CHALLENGED, '
    '2 blocking + 1 minor, report digest `aeb8c870ffbcbf9fedf422f5f33bb7ac4950cf9443437cfca6bc5e5e44513932`, against '
    'source `567cb6e0…` and FLOOR-OgYGoP, reserved 2026-10-14T12:22:22Z, report timestamp 13:22:23Z, with '
    '`--complete` and `tally` both exit 0 (`notes/verification/reports/r18-complete.{log,rc,time}`, 16:53:44Z to '
    '17:08:04Z, `r18-tally.{log,rc}`). FLOOR-OgYGoP sealed at rc 0 on the frozen source (`r18-floor-1.*`, 21 '
    'executed and 65 reused, 07:02:57Z to 11:51:10Z) and validated current (`r18-floor-validate.*`). Rounds 1-17 '
    'kept their sealed digests, and the worktree states recorded before reservation, at reservation and at return '
    'are byte-identical (`r18-state-{prereserve,reserved,returned}.*`, 5372 paths). Tally: opponent=18, '
    'reality-check=1, blocking=36, minor=15, locations=496, unclassified=0, observations=72, distinct IDs=25, '
    'reopened=32, severity-downgrades=5, captures=649. The reviewer wrote its report itself, stopped on a session '
    'usage limit before returning and was resumed by message after the reset; the block it returned is '
    'byte-identical to the file (`r18-persist.{log,rc}`; provenance `opponent-round18.note`). It credited T030o51 '
    'as holding for every construct CommonMark 0.31.2 binds before a code span, T030o52 for every list-marker form it '
    'tried, T030o53\'s soundness and the folded minor, and found no positive row asserting an attack. It reopened '
    'O-018 (wrong-result, plan-gap, blocks REQ-011, AC-009, AC-012): a backtick inside a GFM extended autolink, or '
    'inside a shortcut, collapsed or image reference\'s label, which marked binds before any code span, pairs, to '
    'the gate, with a later backtick into a code span, so a live `br` or `pre` tag after it reads as inside a span '
    'and a data-loss tier marked shows seals a CLEARED round at minor, in both passes and both locales, on CUR and '
    'PRE. It established O-025 (new, wrong-result, plan-gap, blocks REQ-011, AC-009, AC-012): a GFM table inside a '
    'finding shows a data-loss tier as a cell\'s first text in both renderers, which the label reader, never '
    'splitting a line at a pipe, does not read. It reopened O-023 (degraded, plan-gap): T030o53\'s head-only rule '
    'leaves a candidate led by a link, an image or a code span holding a bracket unsettled (29.4 s at 100 lines, '
    '373 s at 200). Final audit: `r18-final-audit.{sh,log,rc}`, exit 0, 59 PASS. The outcome was held out of this '
    'log until now, so that FLOOR-OgYGoP and the round-18 observation stayed current for `567cb6e0…` through '
    'completion.')
E.append('- 2026-10-14 — User decision of 2026-10-14 (session 21), after round 18 was reported and the invoker stopped '
    'to ask, as the standing instruction of 2026-10-07 requires on a choice between fixes with trade-offs, each '
    'option chosen as the invoker recommended it: O-018, narrow further (the reviewer\'s M1), over deriving the '
    'refused constructs from what each renderer binds before a code span; O-025, refuse tables (the reviewer\'s M2), '
    'over reading the label after every unescaped pipe; O-023, settle on either test (the reviewer\'s M3). The user '
    'then asked: "with which option the implementation would be fast i want to finish everything quickly. i have '
    'been working with this spec for past 4 weeks i think. Give me best option and tell me which things i can waive '
    'out to finish work with the spec", and selected "Drop extra proof steps, Authorize CI + reality-check 2, Defer '
    'the retro (T034), Choose all that would be recommended by you", the last covering the spec revision the invoker '
    'recommended. Decided: (1) for this repair the invoker\'s extra proof steps are not run (the mutation matrix, '
    'two-direction fixture judging, a separate measurement script, repeated dev runs); kept are one dev run in a '
    'standalone copy, one capture of record, the returns and `spec-gate.sh accept`, the floor and the gate rounds; '
    '(2) REQ-011 is revised (entry below); (3) a hosted CI run on the current source by the established snapshot '
    'method (a temporary branch and PR closed unmerged, the active gh account never switched) and reality-check '
    'round 2, which needs no waiver (rounds 1-3 need no authorization), are authorized, both after round 19 and on '
    'its floor while the source is unchanged, so one floor serves both gates; (4) the retro (T034) is deferred to a '
    'post-merge follow-up. Order: (a) reproduce, done (entry below); (b) one dev run of the repair in a standalone '
    'copy, done (entry below); (c) this batch, before any live code: the outcome, this decision, the reproduction, '
    'the spec revision, the task blocks and the round-19 waiver; (d) the repair applied live, the freeze point, one '
    'capture of record, the returns and accept; (e) one fresh floor on AC power; (f) round 19, complete, tally, the '
    'final audit, the report; (g) on CLEARED, the hosted CI run and reality-check round 2 on the same floor, then the '
    'user is asked for the guarded PR. Not authorized: shipped 002\'s locale-dependent reset parsing; the open-extent '
    'follow-up task; commits to the spec branch; the guarded PR and merge before the user is asked; any bypass. Cost '
    'stated rather than hidden: dropping the extra proof steps trades the invoker\'s independent proof that every new '
    'row kills its bug for time; round 19 checks the repair independently.')
E.append('- 2026-10-14 — Round 18\'s findings reproduced independently BEFORE any repair, in standalone copies built '
    'from the live enumeration with a `TMPDIR` ending in `/`, from the reviewer\'s own cases in its transcript '
    '(`notes/verification/reports/r19-repro.{sh,log,rc,time}`, exit 0, 196 PASS, 0 FAIL, 17:10:12Z to 17:18:12Z, the '
    'live status outside `notes/verification/` unchanged): the seven O-018 members and both O-025 table spellings '
    'seal in silence on CUR (`r18-edits/post-apply-3`) in both passes and both locales, and on PRE (CUR with '
    '`r18-session.diff` reversed) too; a URL member, a reference member and the table each seal a CLEARED round 1 end '
    'to end in both passes and both locales, while the `br` control is refused at exit 3 by name; the one-column '
    'table and a raw `td` stay refused; four positives parse; `vf_settled` leaves the link-, image-, ordered-item- '
    'and bracketed-code-span-led texts unsettled on CUR and settles them on PRE, and the reverse for round 17\'s '
    'shape; the link-led run took 2.89 s at 50 lines and 29.86 s at 100 on CUR, 0.09 s at 100 and 0.29 s at 400 on '
    'PRE.')
E.append('- 2026-10-14 — Spec revision of REQ-011, the user\'s decision above: gate reports are trusted-author input, '
    'written by the kit\'s own gate agents and read by people as well as by the tally, so a rendering divergence in a '
    'report (markdown a renderer shows differently from how the documented report grammar reads it, which that '
    'grammar neither reads nor refuses) is degraded, hence minor, and is recorded for a follow-up spec; a report '
    'written in the documented grammar that the gate misreads still blocks as wrong-result. The contract template '
    'says the same. Stated plainly: of the 30 findings in class gate-report-schema-validation, 24 are recurrences, '
    'and from round 15 to round 18 each round found another construct a renderer reads differently; the user made '
    'this revision to finish the spec, on the threat model it states, after the repair in this batch closes every '
    'divergence found so far. It applies from round 19 on and re-grades no sealed round.')
E.append('- 2026-10-14 — T030o54 (O-018), T030o55 (O-025) and T030o56 (O-023) are opened, Backend, binding plan §7\'s '
    'existing registry with no new families exactly as T030o44 to T030o53 do: reports '
    '(`tests/test-gate-contracts.sh::test_reports_and_tally`, FM-019, INV-006) and rounds '
    '(`tests/test-spec-gate.sh::test_rounds`, FM-016, INV-004), each with the Verify `bash tests/run.sh && bash '
    'tests/shellcheck.sh`, so one capture on unchanged source can serve all three acceptances; they are serial, '
    'because all three edit the same four files. The kernel change is the reviewer\'s own MALL mutant (its M1, M2 and '
    'M3 together), taken from its transcript with its helper names given kernel names, which the reviewer ran with '
    'both changed suites passing (18/18 and 8/8) and every history output byte-identical; it is applied by '
    '`notes/verification/reports/r19-edits/apply-code.py` (refusing unless the four files hash as '
    '`r18-edits/post-apply-3`), with the rows the task blocks name, and the documents by `r19-edits/apply-docs.py`. '
    'A spot check on a standalone copy refused every member by name, parsed every positive, and parsed a 400-line '
    'run of link-, image- and code-span-led sub-bullets in 0.32 s. The one dev run, in a standalone copy built from '
    'the live enumeration with both scripts applied and a `TMPDIR` ending in `/` (`notes/verification/reports/'
    'r19-dev.{sh,log,rc,time}`, %s to %s, the live status outside `notes/verification/` unchanged): `tests/run.sh` '
    'passed %s and `tests/shellcheck.sh` passed, exit 0.' % (dev_t[0], dev_t[1], suites))
E.append('- %s — waiver: gate=opponent; round=19; after=18; by=Rehan712; reason=user instructed on 2026-10-07 to '
    'repair the findings of a CHALLENGED round and rerun the opponent until all issues are resolved, and on 2026-10-14 '
    'chose the round-18 repair and asked to finish the spec quickly, so round 19 assesses the repairs of round 18\'s '
    'O-018, O-025 and O-023 against a fresh floor sealed after those repairs are accepted' % ts)
E.append('- 2026-10-14 — Decisions are FROZEN from this batch through the live apply of T030o54, T030o55 and T030o56, '
    'their capture and acceptance, the floor, round 19\'s completion and tally, and, on CLEARED, the hosted CI run '
    'and reality-check round 2 on that floor; results go to STATUS\'s neutral sections only, so that the floor stays '
    'current for both gates.')
for e in E:
    assert '\n' not in e and '\r' not in e
waiver = E[5]
assert waiver.count('; ') == 4, 'a waiver needs exactly five fields'
assert head.endswith('.\n') or head.endswith('`\n') or head.endswith(')\n'), repr(head[-40:])
new = head + '\n' + '\n\n'.join(E) + '\n' + anchor + tail
open(path, 'wb').write(new.encode('utf-8'))
print('appended %d entries; waiver %s' % (len(E), ts))
