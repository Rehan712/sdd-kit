#!/usr/bin/env python3
# Session 21 (2026-10-14): the neutral STATUS edit after opponent round 18 (frontmatter opponent and updated lines,
# Where things stand, Open questions, Handoff note, Next action). The Decisions log is NOT touched: the script checks
# that the bytes from `## Decisions log` up to `## Open questions / blockers` are unchanged. The final audit's result
# is read from its receipts, never typed. Refuses unless every anchor occurs exactly once.
# Usage from the worktree root: python3 -I <this>
import re
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
path = spec + '/STATUS.md'
text = open(path, encoding='utf-8').read()
assert '\r' not in text
arc = open(rep + '/r18-final-audit.rc', encoding='utf-8').read().strip()
alog = open(rep + '/r18-final-audit.log', encoding='utf-8').read().splitlines()
npass = sum(1 for l in alog if l.startswith('PASS '))
nfail = sum(1 for l in alog if l.startswith('FAIL '))
assert arc == '0' and nfail == 0 and alog[-1] == 'final audit failures=0', (arc, nfail, alog[-1])
rrc = open(rep + '/r19-repro.rc', encoding='utf-8').read().strip()
rlog = open(rep + '/r19-repro.log', encoding='utf-8').read().splitlines()
rpass = sum(1 for l in rlog if l.startswith('PASS '))
assert rrc == '0' and not any(l.startswith('FAIL ') for l in rlog) and rlog[-1] == 'r19-repro failures=0'

def dec(t):
    a = t.index('\n## Decisions log\n'); b = t.index('\n## Open questions / blockers\n')
    return t[a:b]
before = dec(text)

def once(old, new):
    global text
    assert text.count(old) == 1, 'anchor count %d: %r' % (text.count(old), old[:80])
    text = text.replace(old, new)

m = re.search(r'^opponent: CHALLENGED \(round 17 consumed 2026-10-09;[^\n]*?\)( +# not-run)', text, re.M)
assert m and len(re.findall(r'^opponent: ', text, re.M)) == 1
text = text[:m.start()] + ('opponent: CHALLENGED (round 18 consumed 2026-10-14; 2 blocking + 1 minor; digest aeb8c870ffbc…; '
    'O-018 reopened, O-025 new, O-023 reopened; reproduced; NOT yet in Decisions; round 19 not authorized; repair '
    'choices wait for the user)') + m.group(1) + text[m.end():]
once('\nupdated: 2026-10-13\n', '\nupdated: 2026-10-14\n')

where = ('**2026-10-14 (session 21, end) — FLOOR-OgYGoP sealed; opponent round 18 consumed: CHALLENGED, 2 blocking + 1 '
    'minor; O-018 reopened (blocking), O-025 new (blocking), O-023 reopened (minor, degraded); the findings reproduced '
    'before any repair; stopped, as the standing instruction requires, because the repairs offer choices with '
    'trade-offs (neutral record; Decisions frozen at `02b9cc4c…`, round 18\'s outcome deliberately NOT yet in '
    'Decisions).** Entry: `r22-handoff-state.sh` run again equals `r22-handoff-state.txt` but time, free disk, power '
    'and swap (`r23-entry-state.{txt,err,rc,start,end}`, exit 0, empty stderr; on AC, 11 GiB free). The floor ran '
    'detached under `nohup` (`r18-floor-1.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}`, exit 0): FLOOR-OgYGoP on '
    'source `567cb6e0…`, 21 executed and 65 reused, 07:02:57Z to 11:51:10Z, on AC but for two short battery spells '
    '(07:09:45Z to 07:10:19Z and 07:21:44Z to 07:26:47Z, at 85 to 92%%), free disk 10.16 to 10.84 GiB; validated '
    'current (`r18-floor-validate.{out,err,rc,time}`, exit 0, empty stderr); the scope against FLOOR-QCFkfi '
    '(`r18-scope.{log,rc}`, exit 0) differs in exactly `STATUS.md`, `tasks.md`, `scripts/verification-lib.sh`, '
    '`templates/verification-contract.md`, `tests/test-gate-contracts.sh` and `tests/test-spec-gate.sh`. ROUND-18 was '
    'reserved at 2026-10-14T12:22:22Z on FLOOR-OgYGoP and source `567cb6e0…` (`r18-reserve.{log,rc,time}`, exit 0); '
    'the worktree states before reservation, at reservation and at return are byte-identical: 5372 paths, entries '
    'digest `c0ebb467…` (`r18-state-{prereserve,reserved,returned}.*`). The brief was finished from the draft by '
    '`r18-brief-fill.py` (`r18-brief-fill.{log,rc}`, exit 0; `opponent-round18-brief.md`, sha256 `86614ab6…`). The '
    'independent opponent (dispatched 12:24:31Z) wrote `opponent-round18.md` itself at 13:23:19Z and stopped on a '
    'session usage limit before returning; resumed by message after the reset (16:51:03Z), it left the file '
    'unchanged, removed its copy and returned the block, which `r18-persist-report.py` found byte-identical to the '
    'file (`r18-persist.{log,rc}`, exit 0; timestamp 13:22:23Z, sha256 `aeb8c870…`, 18188 bytes; provenance '
    '`opponent-round18.note`). The Mac ran on battery from 12:24Z. It credited T030o51 as holding for every '
    'construct CommonMark 0.31.2 binds before a code span, T030o52 for every list-marker form it tried, T030o53\'s '
    'soundness (no candidate the new rule settles whose first word a later line can change) and the folded minor; '
    'found no positive row asserting an attack; and judged its mutants M1, M2, M3 and MALL history-neutral, with both '
    'changed suites passing under MALL (18/18 and 8/8). It **reopened O-018** (wrong-result, plan-gap, blocks '
    'REQ-011, AC-009, AC-012): a backtick inside a construct marked binds before any code span, a GFM extended '
    'autolink (`http://`, `https://`, `www.`, `ftp://`) or a shortcut, collapsed or image reference whose label is '
    'defined outside the finding, pairs, to the gate, with a later backtick into a code span, so a live `br` or `pre` '
    'tag after it reads as inside a span and a data-loss tier marked shows seals a CLEARED round at minor in both '
    'passes and both locales, on CUR and PRE (a gap in T030o51\'s claim, whose constructs came from CommonMark alone, '
    'not a regression); its M1 refuses a backtick inside a bracket pair, or inside a URL literal, that some reading '
    'places outside every code span. It established **O-025** (new, wrong-result, plan-gap, blocks REQ-011, AC-009, '
    'AC-012): a GFM table inside a finding renders a data-loss tier as the first text of a cell in both renderers, '
    'and the label reader never splits a line at a pipe, so the tier is prose and a CLEARED round seals over it, on '
    'CUR and PRE; no delimiter line stands inside any finding of 001\'s, 002\'s or 003\'s reports; its M2 refuses by '
    'name a line that may be a table delimiter line. It **reopened O-023** (degraded, plan-gap, blocks none): '
    '`vf_settled_word` checks brackets only in the head, so a bracket that opens before the first word and closes '
    'after it (a sub-bullet led by a link, an image or a code span holding a bracket) leaves the candidate '
    'unsettled; T030o53\'s timing shape with its link moved to the front took 29.4 s at 100 lines and 373 s at 200 '
    'on CUR (0.10 s at 100 and 0.32 s at 400 on PRE), beyond T030o53\'s bound; its M3 settles on either test '
    '(0.32 s at 400). Proposed follow-ups: T030o54 (O-018), T030o55 (O-025), T030o56 (O-023). `--complete` exited 0 '
    'with digest `aeb8c870ffbcbf9fedf422f5f33bb7ac4950cf9443437cfca6bc5e5e44513932` (`r18-complete.{log,rc,time}`, '
    '16:53:44Z to 17:08:04Z); `tally` exited 0 at opponent=18, reality-check=1, blocking=36, minor=15, '
    'locations=496, unclassified=0, observations=72, distinct IDs=25, reopened=32, severity-downgrades=5, '
    'captures=649 (`r18-tally.{log,rc}`). Final audit `r18-final-audit.{sh,log,rc}`, exit 0, %d PASS (eighteen sealed '
    'opponent digests and the reality-check round, the returned block equal to round 18\'s, the worktree states, the '
    'source and Decisions equal to the freeze point, FLOOR-OgYGoP current, no lock, HEAD `0d55c62`, T030o39 to '
    'T030o53 ticked, round 18 completed and round 19 refused at exit 4). Reproduced BEFORE any repair, in standalone '
    'copies with a `TMPDIR` ending in `/`, from the reviewer\'s own cases in its transcript '
    '(`r19-repro.{sh,log,rc,time}`, exit 0, %d PASS, 0 FAIL, 17:10:12Z to 17:18:12Z; live status outside '
    '`notes/verification/` unchanged): the seven O-018 members and both O-025 table spellings seal in silence on CUR '
    'in both passes and both locales, and on PRE too; one URL member, one reference member and the table each seal a '
    'CLEARED round 1 end to end in both passes and both locales (`tally` blocking=0 minor=1), while the `br` control '
    'is refused at exit 3 by name; the one-column table and the raw `td` tag stay refused; the four positives parse; '
    '`vf_settled` leaves the link-, image-, ordered-item- and bracketed-code-span-led texts unsettled on CUR and '
    'settles them on PRE, and the reverse for round 17\'s shape; the link-led run took 2.89 s at 50 lines and 29.86 s '
    'at 100 on CUR, 0.09 s at 100 and 0.29 s at 400 on PRE. State at the stop: `r23-handoff-state.{sh,txt,rc,err}`.'
    ) % (npass, rpass)
once('## Where things stand\n\n', '## Where things stand\n\n' + where + '\n\n')

oq_old = '- [ ] **Session 20 (2026-10-13), stopped before the floor:**'
once(oq_old, '- [x] *Superseded by session 21 (above).* **Session 20 (2026-10-13), stopped before the floor:**')
oq = ('- [ ] **Round 18 consumed 2026-10-14 (session 21): CHALLENGED, 2 blocking + 1 minor (digest `aeb8c870…`, '
    'FLOOR-OgYGoP); reproduced (`r19-repro`, exit 0); repair choices pending with the user.** Round 18\'s outcome is '
    'NOT yet in Decisions, so FLOOR-OgYGoP stays current for `567cb6e0…` until the next batch; round 19 is refused '
    'at exit 4 until its waiver is written with that repair. T030o52 was credited as holding, T030o51 for every '
    'CommonMark 0.31.2 construct, T030o53\'s soundness and the folded minor too.\n'
    '- [ ] **O-018 reopened (round 18, blocking, wrong-result, plan-gap; NOT repaired; a choice for the user).** A '
    'backtick inside a GFM extended autolink, or inside the label of a shortcut, collapsed or image reference defined '
    'outside the finding, pairs to the gate with a later backtick into a code span marked does not form, so a live '
    '`br` or `pre` tag after it reads as inside a span (`scripts/verification-lib.sh:509`, `:514`, `:538`, `:690`). '
    'Options: (a) narrow further: inside a finding, refuse a backtick inside a bracket pair, or inside a URL literal, '
    'that some reading places outside every code span (the reviewer\'s M1); (b) derive the refused constructs from '
    'what each reference renderer binds before a code span (GFM extended autolinks, marked\'s reference tokenizer). '
    'Proposed: T030o54, with rows in both passes and one end-to-end case per construct.\n'
    '- [ ] **O-025 (round 18, new, blocking, wrong-result, plan-gap; NOT repaired; a choice for the user).** A GFM '
    'table inside a finding renders a data-loss tier as the first text of a cell, and the label reader never splits '
    'a line at a pipe (`:632`, `:617`, `:619`, `:364`). Options: (a) narrow: refuse by name inside a finding a line '
    'that may be a table delimiter line (the reviewer\'s M2); (b) read the label after every unescaped pipe of a run '
    'that holds a delimiter line (GFM splits cells inside code spans too, so that reading cannot skip spans). '
    'Proposed: T030o55, with rows in both passes and one end-to-end case.\n'
    '- [ ] **O-023 reopened (round 18, minor, degraded, plan-gap; NOT repaired).** A bracket that opens before a '
    'line\'s first word and closes after it leaves the candidate unsettled (`:557`, `:566`): 29.9 s at 100 '
    'link-led lines on CUR. Options: settle on either test (the head balanced, or the whole text balanced with '
    'complete destinations; the reviewer\'s M3, the union of T030o53\'s and T030o50\'s rules, each argued sound '
    'alone), or count a bracket before the first word as unsettling only while that reading leaves it unclosed. '
    'Proposed: T030o56, with a 400-line timing row whose sub-bullets begin with a link, an image and a code span '
    'holding a bracket.\n')
once('## Open questions / blockers\n\n', '## Open questions / blockers\n\n' + oq)

ho = ('**2026-10-14 (session 21) — the floor, round 18 run and consumed, its findings reproduced; receipts index.** '
    'Every exit was read back from its receipt. Under `notes/verification/reports/`:\n'
    '- Entry: `r23-entry-state.{txt,err,rc,start,end}` (exit 0; `r22-handoff-state.sh` run again).\n'
    '- Floor: `r18-floor-1.{pre,log,rc,samples.log,wrapper.log,wrapper.rc}` (FLOOR-OgYGoP); '
    '`r18-floor-validate.{out,err,rc,time}`; `r18-scope.{log,rc}`.\n'
    '- Reservation and run: `r18-state-prereserve.{txt,entries,log,rc}`, `r18-reserve.{log,rc,time}`, '
    '`r18-state-reserved.*`; `r18-brief-fill.{py,log,rc}` with `opponent-round18-brief.md`; `opponent-round18.md` '
    'with `opponent-round18.note`; `r18-persist-report.py` with `r18-persist.{log,rc}`; `r18-state-returned.*`.\n'
    '- Completion: `r18-complete.{log,rc,time}`, `r18-tally.{log,rc}`, `r18-final-audit.{log,rc}`.\n'
    '- Reproduction: `r19-repro.{sh,log,rc,time}`.\n'
    '- STATUS before this edit: `r23-STATUS-before-1.md` (edited by `r23-status-edit.py`, `r23-status-edit.{log,rc}`); '
    'the stop state: `r23-handoff-state.{sh,txt,rc,err}`.\n\n')
once('## Handoff note\n\n', '## Handoff note\n\n' + ho)

na = ('**2026-10-14 (session 21, end) — round 18 consumed CHALLENGED (2 blocking + 1 minor) and its findings '
    'reproduced; stopped to ask the user how to repair, since the standing instruction stops on a choice between '
    'fixes with trade-offs.** Order, once the user has chosen (Open questions, round 18):\n'
    '1. Re-verify: `bash .../reports/r23-handoff-state.sh` from the worktree root (bash, never sourced) must equal '
    '`r23-handoff-state.txt` but time, disk, power and swap. Check free disk, swap and AC power.\n'
    '2. Measure the chosen rules before adoption against the recorded history (as `r18-measure.sh` did) and the full '
    'suite on the candidate; correct a rule found wrong before writing it.\n'
    '3. Write one Decisions batch before any code: round 18\'s outcome, the user\'s choices, the reproduction '
    '(`r19-repro`), the rules with their measurement, the task blocks (T030o54 O-018, T030o55 O-025, T030o56 O-023), '
    'and the round-19 waiver stamped at writing time (after round 18\'s completion, 2026-10-14T17:08:04Z), in byte '
    'mode; validated on a scratch copy and live (round 19 exit 0, round 20 exit 4, analyzer 0 errors).\n'
    '4. Fixtures judged in standalone copies in both directions; apply after a hash check; dev runs; the mutation '
    'matrix (discovery probe first, so every row names a fixture that kills it; dry run, probe, run of record); a '
    'freezing entry; the freeze point; one capture of record; the returns and `spec-gate.sh accept`.\n'
    '5. One fresh floor on AC (detached under `nohup`; this session\'s took 4h48m with 65 reused), validate, scope '
    'against FLOOR-OgYGoP, worktree states, reserve round 19, the brief (from `opponent-round18-brief.md`), the '
    'opponent (check or persist its returned block from its transcript; resume it after a usage limit), complete, '
    'tally, final audit, STATUS, report.\n'
    'Not authorized: hosted CI without asking, shipped 002\'s reset parsing, the open-extent task, reality-check '
    'round 2, commits, the PR, merge, bypasses.\n\n'
    '*Superseded by session 21\'s end, kept for the record:*\n\n')
once('## Next action\n\n', '## Next action\n\n' + na)

assert dec(text) == before, 'the Decisions log moved'
assert '\r' not in text
open(path, 'wb').write(text.encode('utf-8'))
print('audit PASS=%d repro PASS=%d; STATUS written, Decisions bytes unchanged' % (npass, rpass))
