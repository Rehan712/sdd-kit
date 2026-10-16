#!/usr/bin/env python3
# Session 23 (2026-10-15): the task blocks T031a1 to T031a4, the fixtures reality-check round 2 found missing, opened
# unticked at the end of the Tests stage, as the user decided on 2026-10-15 ("Add the tests": test files only, no
# kernel change). Usage: python3 -I <this> <root>; refuses unless the anchor occurs exactly once and no block exists.
import hashlib, os, sys
root = sys.argv[1]
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
P = {'tasks': spec + '/tasks.md'}
text = {k: open(os.path.join(root, p), 'rb').read().decode('utf-8') for k, p in P.items()}

def once(k, old, new):
    n = text[k].count(old)
    assert n == 1, '%s: anchor count %d: %r' % (k, n, old[:90])
    text[k] = text[k].replace(old, new)

for t in ('T031a1', 'T031a2', 'T031a3', 'T031a4'):
    assert ('**%s**' % t) not in text['tasks'], 'refusing: %s exists' % t
common = ('  - *Files:* %s\n'
    '  - *Acceptance:* %s\n'
    '  - *Verify kind:* test\n'
    '  - *Tests:* %s\n'
    '  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0\n'
    '  - *Reuse:* local\n'
    '  - *Refs:* %s\n'
    '  - *Notes:* %s\n')
tail = (' Test files only, no kernel change, as the user decided on 2026-10-15; the cases start from the reviewer\'s '
    'probes (`notes/verification/reports/rc2-review-probes.txt`) and are applied by '
    '`notes/verification/reports/r20-edits/apply-code.py`. Under the user\'s decisions of 2026-10-14 and 2026-10-15 '
    'the invoker\'s extra proof steps (the mutation matrix, two-direction fixture judging, a separate measurement '
    'script, repeated dev runs) are not run; one dev run in a standalone copy and the capture of record prove it. '
    'T031a1 to T031a4 share one Verify, so one capture on unchanged source can serve all four acceptances. No gate '
    'round, floor or hosted-CI run is part of this task.')
blocks = (
    '- [ ] **T031a1** — Cover the acceptance cases reality-check round 2 found without a fixture\n'
    + common % (
    '`tests/test-spec-gate.sh`',
    'In `test_acceptance` (`acceptance_named_cases`), each refused with its named reason and tasks.md '
    'byte-identical: a return with no `Failure modes:` block (`incomplete verification return`); `Captures:` naming '
    'a capture that does not exist (`capture integrity: missing COMPLETE or linked directory`); a capture of an '
    'unrelated explicit command whose log names the test (`do not prove this task Verify`); a capture whose command '
    'exited nonzero (`capture failed: exit 5`); a manual return whose artifact is absent (`manual artifact missing or '
    'digest mismatch`). A valid acceptance changes only its own checkbox and adds its `*Evidence:*` line (asserted '
    'against the expected file), and a task owing no rows is accepted with an explicit `Failure modes: none` (AC-022).',
    '`tests/test-spec-gate.sh::test_acceptance`',
    'REQ-006, REQ-009, AC-022, FM-006, FM-010, INV-002, plan §7',
    'Owns reality-check round 2 gap 1 (AC-022).' + tail) +
    '\n- [ ] **T031a2** — Show a changed command executes again and a capture is never reused for another argv\n'
    + common % (
    '`tests/test-spec-gate.sh`, `tests/test-verification.sh`',
    'In `reuse_floor_cases` (called by `test_floor`), changing an opted-in gate_checks command string from '
    '`bash tests/check.sh` to `bash ./tests/check.sh` runs the suite again with `cache-hits=0`; in '
    '`capture_validity_cases` (called by `test_capture_provenance`), with the inputs unchanged, the floor\'s reuse '
    'path (`vf_gate_execute`, local policy) reuses a passing capture for its own argv and not for another command '
    'string that runs the same test (AC-007, AC-020).',
    '`tests/test-spec-gate.sh::test_floor`, `tests/test-verification.sh::test_capture_provenance`',
    'REQ-007, REQ-009, AC-007, AC-020, FM-012, FM-014, INV-001, plan §7',
    'Owns reality-check round 2 gap 2 (AC-007, AC-020).' + tail) +
    '\n- [ ] **T031a3** — Cover class recurrence across files and root causes and an annotated copy of 002\n'
    + common % (
    '`tests/test-gate-contracts.sh`',
    'In `test_reports_and_tally` (`tally_class_cases`): two findings of one Class at different files with different '
    'Root causes count one recurrence; two Classes sharing a file and a Root cause count none; an annotated copy of '
    'shipped 002\'s opponent history (`annotate_002`, its six legacy findings as canonical findings with stable '
    'Classes) detects both its clock recurrence and its lock recurrence, while the copy and the shipped notes stay '
    'byte-identical (AC-010).',
    '`tests/test-gate-contracts.sh::test_reports_and_tally`',
    'REQ-015, AC-010, FM-019, INV-006, plan §7',
    'Owns reality-check round 2 gap 3 (AC-010).' + tail) +
    '\n- [ ] **T031a4** — Exercise the explicit reconciliation of a legacy date-only history\n'
    + common % (
    '`tests/test-spec-gate.sh`',
    'In `test_rounds` (`round_legacy_reconcile_cases`): with a copy of shipped 002\'s date-only opponent history, '
    'the next round is refused at exit 4 with `date-only history needs timestamped digest reconciliation` and '
    'reserves nothing; `round --reconcile` records an explicit timestamp bound to the history\'s digest; an exact '
    'waiver written after it then authorizes round 6, which reserves on a fresh floor (AC-009).',
    '`tests/test-spec-gate.sh::test_rounds`',
    'REQ-012, AC-009, FM-016, INV-004, plan §7',
    'Owns reality-check round 2 gap 4 (AC-009).' + tail))
once('tasks', '\n\n## Observability\n', '\n\n' + blocks + '\n## Observability\n')

for k, p in P.items():
    out = text[k].encode('utf-8')
    open(os.path.join(root, p), 'wb').write(out)
    print('%s  %s' % (hashlib.sha256(out).hexdigest(), p))
