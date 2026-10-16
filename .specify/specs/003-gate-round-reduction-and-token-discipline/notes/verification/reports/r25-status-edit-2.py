#!/usr/bin/env python3
# Session 23 (2026-10-16), after opponent round 20 (CHALLENGED) and its final audit: STATUS's neutral sections only
# (frontmatter `opponent:`, Where things stand, Open questions, Next action) with round 20's outcome, the O-029
# reproduction and the user's decision to open the draft PR now and fix O-029 later. Every byte of the Decisions log,
# from `## Decisions log` to `## Open questions / blockers`, is checked unchanged; the decisions go into Decisions in
# the next batch. Usage from the worktree root: python3 -I <this> <final-audit PASS count>
import shutil, sys
passes = sys.argv[1]
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
path = spec + '/STATUS.md'
t = open(path, 'rb').read().decode('utf-8')
assert '\r' not in t
shutil.copyfile(path, rep + '/r25-STATUS-before-2.md')

def dec(x):
    a = x.index('\n## Decisions log\n'); b = x.index('\n## Open questions / blockers\n')
    return x[a:b]
before = dec(t)

def once(old, new):
    global t
    n = t.count(old)
    assert n == 1, 'anchor count %d: %r' % (n, old[:90])
    t = t.replace(old, new)

once('opponent: CLEARED (round 19 consumed 2026-10-15; 0 blocking + 3 minor; digest a99077db6dc4…; O-026, O-027 and O-028 new, minor under REQ-011 as revised, for the follow-up spec)',
     'opponent: CHALLENGED (round 20 consumed 2026-10-16; 1 blocking + 3 minor; digest 8630890bab45…; O-029 blocking, a test-only fixture gap for AC-009, to be repaired on the PR branch; O-030 to O-032 minor)')

once('## Where things stand\n\n',
     '## Where things stand\n\n'
     '**2026-10-16 (session 23, after round 20) — opponent round 20 CHALLENGED, 1 blocking + 3 minor; the user chose to '
     'open the draft PR now and repair O-029 later on the PR branch, with CI, before merge (neutral record; Decisions '
     'frozen at `ff60b48b…`, source `9cf02d45…`).** Round 20 reserved at 2026-10-16T01:26:39Z on FLOOR-UeGEcf '
     '(`r20-reserve.{log,rc,time}`, exit 0); the independent opponent, dispatched 01:28:20Z on `opponent-round20-brief.md` '
     '(sha256 `311d80cb…`), returned **CHALLENGED, Blocking 1, Minor 3** (timestamp 02:09:54Z). O-029 (new, '
     'wrong-result, class named-case-fixture-strength, blocks AC-009 and REQ-012): `round_legacy_reconcile_cases` '
     '(T031a4) cannot fail when the reconciled timestamp, the round and digest check, or all legacy binding are '
     'removed from the kernel; the kernel itself is right (an early waiver is refused, a wrong digest or round is '
     'refused). O-030 (minor): no empty-header refusal for a no-row task beside the explicit-none acceptance. O-031 '
     '(minor): the two byte-identity assertions of `tally_class_cases` cannot fail. O-032 (degraded): the legacy '
     'reconcile refusals exit 3 with no diagnostic (a kernel change, for the follow-up spec). Held: T031a1\'s other '
     'cases, T031a2 (the capture-level case kills the argv-blind mutant), T031a3\'s recurrence semantics and the '
     'refusal half of T031a4. The agent could not write the report path; the file was persisted from its own '
     'transcript (`r20-persist.{log,rc}`, exit 0, sha256 `8630890b…`, 17145 bytes); worktree states before '
     'reservation, at it and at return byte-identical (`r20-state-{prereserve,reserved,returned}.*`, 5724 paths). '
     'Completion (`r20-complete.{log,rc,time}`, exit 0: `round completed gate=opponent round=20 verdict=CHALLENGED`), '
     'tally (`r20-tally.{log,rc}`, exit 0: opponent rounds=20, blocking=37 minor=21) and the final audit '
     '(`r20-final-audit.{sh,log,rc}`, exit 0, ' + passes + ' PASS, 0 FAIL). O-029 reproduced by the invoker in a '
     'standalone copy (`r20-repro-o029.{sh,log,rc,time}`, exit 0: the case passes under the timestamp-ignored mutant; '
     'live status unchanged). The user then chose "Draft PR now, fix later" (`r20-user-decision-3.txt`): no '
     'reality-check round 3 now (it could not be READY: AC-019 has no hosted CI on this source, and O-029 would stale '
     'it); commit all 003 work, push the spec branch and open the PR as a draft through `spec-pr.sh --force --draft`, '
     'its body showing opponent CHALLENGED; repair O-029 (test-only) on the PR branch later, with hosted CI once the '
     'Actions limit resets, then re-gate before merge.\n\n')

once('## Open questions / blockers\n\n',
     '## Open questions / blockers\n\n'
     '- [ ] **Before merge (user decision 2026-10-16, session 23; NOT yet in Decisions):** repair O-029 test-only on the '
     'PR branch (the reviewer\'s T031a4o1: before the valid reconcile, a wrong digest, a wrong round and a timestamp '
     'before the history\'s date each exit 3, write no `legacy-time.nul` and leave the next round refused; after it, a '
     'waiver dated 2026-07-20 before 23:59:59Z refused with `not after the previous round completion at '
     '2026-07-20T23:59:59Z`; after editing the history, neither `waiver` nor `round` authorizes or reserves; each '
     'assertion killed by one of the three mutants), optionally O-030 (T031a1o1) and O-031 (T031a3o1), both '
     'test-only; then a fresh floor, an authorized opponent round 21, hosted CI once the Actions limit resets (AC-019) '
     'and reality-check round 3, then mark the PR ready (T033 merge with the user). O-032 (kernel diagnostics) goes '
     'to the follow-up spec. User decision verbatim: `notes/verification/reports/r20-user-decision-3.txt`.\n')

once('## Next action\n\n',
     '## Next action\n\n'
     '**2026-10-16 (session 23, after round 20) — commit all 003 work, push the spec branch and open the draft PR '
     '(`spec-pr.sh --force --draft`), as the user chose; then O-029 on the PR branch, with CI, before merge.** From '
     'the worktree root, as Rehan712 through a process-scoped `GH_TOKEN` (never switch the active gh account, never '
     'print the token): `git add -A`; one commit whose message ends with the Co-Authored-By line; `bash '
     'scripts/spec-pr.sh --force --draft .specify/specs/003-gate-round-reduction-and-token-discipline` (base `main` '
     'from `.specify/stack.yml`). Afterwards, per Open questions: the O-029 repair, a floor, round 21 (needs the '
     'user\'s exact-round authorization), hosted CI, reality-check round 3, then mark the PR ready and ask the user '
     'about the merge (T033). Not authorized: merge, shipped 002\'s reset parsing, the open-extent task, the round-19 '
     'follow-ups F1 to F4, bypasses other than the draft `--force` the user chose.\n\n'
     '*Superseded by the entry above, kept for the record:*\n\n')

assert dec(t) == before, 'the Decisions log changed'
open(path, 'wb').write(t.encode('utf-8'))
print('STATUS neutral sections edited; Decisions log unchanged')
