#!/usr/bin/env python3
# Session 24 (2026-10-16): the task blocks T031a1o1, T031a3o1 and T031a4o1, round 20's proposed follow-ups for O-030,
# O-031 and O-029, opened unticked after T031a4 at the end of the Tests stage, as the user decided on 2026-10-16
# (fix O-029 on the PR branch before merge, test files only). Usage: python3 -I <this> <root>; refuses unless the
# anchor occurs exactly once and no block exists.
import hashlib, os, sys
root = sys.argv[1]
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
P = {'tasks': spec + '/tasks.md'}
text = {k: open(os.path.join(root, p), 'rb').read().decode('utf-8') for k, p in P.items()}

def once(k, old, new):
    n = text[k].count(old)
    assert n == 1, '%s: anchor count %d: %r' % (k, n, old[:90])
    text[k] = text[k].replace(old, new)

for t in ('T031a1o1', 'T031a3o1', 'T031a4o1'):
    assert ('**%s**' % t) not in text['tasks'], 'refusing: %s exists' % t
common = ('  - *Files:* %s\n'
    '  - *Acceptance:* %s\n'
    '  - *Verify kind:* test\n'
    '  - *Tests:* %s\n'
    '  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0\n'
    '  - *Reuse:* local\n'
    '  - *Refs:* %s\n'
    '  - *Notes:* %s\n')
tail = (' Test files only, no kernel change, as the user decided on 2026-10-16; the cases start from opponent round '
    '20\'s report (`notes/verification/reports/opponent-round20.md`) and `r20-repro-o029.sh`, and are applied by '
    '`notes/verification/reports/r21-edits/apply-code.py`. Under the user\'s decisions of 2026-10-14 to 2026-10-16 '
    'the invoker\'s extra proof steps are not run, except that each new O-029 assertion is shown killed by one of '
    'round 20\'s three mutants in the one dev run. T031a1o1, T031a3o1 and T031a4o1 share one Verify, so one capture '
    'on unchanged source can serve all three acceptances. No gate round, floor or hosted-CI run is part of this task.')
blocks = (
    '- [ ] **T031a1o1** — Refuse an empty Failure modes header for a task owing no rows\n'
    + common % (
    '`tests/test-spec-gate.sh`',
    'In `test_acceptance` (`acceptance_named_cases`), before the explicit-none acceptance, a return for the no-row '
    'task T006 with an empty `Failure modes:` header is refused with `empty required set must explicitly be none`, '
    'tasks.md byte-identical (AC-022).',
    '`tests/test-spec-gate.sh::test_acceptance`',
    'REQ-006, REQ-009, AC-022, FM-006, FM-010, INV-002, plan §7',
    'Repairs O-030 (round 20, minor).' + tail) +
    '\n- [ ] **T031a3o1** — Hash the records the tally reads before and after it\n'
    + common % (
    '`tests/test-gate-contracts.sh`',
    'In `test_reports_and_tally`, every file under each directory `tally` reads is hashed (names and bytes) before '
    'and after the run: the copy in `shipped_002_tally_case`, and the synthetic and annotated histories in '
    '`tally_class_cases`; the copy check there is labelled as proving only that `copy_kit` is faithful (AC-010).',
    '`tests/test-gate-contracts.sh::test_reports_and_tally`',
    'REQ-015, AC-010, FM-019, INV-006, plan §7',
    'Repairs O-031 (round 20, minor).' + tail) +
    '\n- [ ] **T031a4o1** — Assert the refusals only a reconciled legacy record decides\n'
    + common % (
    '`tests/test-spec-gate.sh`',
    'In `test_rounds` (`round_legacy_reconcile_cases`), on the copy of shipped 002\'s date-only history: before the '
    'valid reconcile, a record naming a wrong digest, a wrong round or a timestamp before the history\'s date each '
    'exits 3, writes no `legacy-time.nul` and leaves the next round refused with `date-only history needs '
    'timestamped digest reconciliation`; after it, a waiver dated 2026-07-20T12:00:00Z is refused with `not after '
    'the previous round completion at 2026-07-20T23:59:59Z` and the current waiver is authorized; after an edit of '
    'the history, with a floor current for it, neither `waiver` nor `round` authorizes or reserves; with the '
    'history restored, round 6 reserves. Each new assertion is killed by one of round 20\'s three mutants (the '
    'reconciled timestamp ignored; the reconcile digest and round check removed; all legacy binding removed) '
    '(AC-009, REQ-012).',
    '`tests/test-spec-gate.sh::test_rounds`',
    'REQ-012, AC-009, FM-016, INV-004, plan §7',
    'Repairs O-029 (round 20, blocking).' + tail))
once('tasks', '\n\n## Observability\n', '\n\n' + blocks + '\n## Observability\n')

for k, p in P.items():
    out = text[k].encode('utf-8')
    open(os.path.join(root, p), 'wb').write(out)
    print('%s  %s' % (hashlib.sha256(out).hexdigest(), p))
