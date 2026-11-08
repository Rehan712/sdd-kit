#!/usr/bin/env python3
# Session 25 (2026-10-17): the task block T031a4o3, round 22's proposed follow-up for O-029 with O-033, opened unticked
# after T031a4o2 at the end of the Tests stage, as the user chose after round 22 ("Fix the issue then continue", test
# files only). Pattern: r22-edits/apply-docs.py.
# Usage: python3 -I <this> <root>; refuses unless the anchor occurs exactly once and no block exists.
import hashlib, os, sys
root = sys.argv[1]
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
p = os.path.join(root, spec, 'tasks.md')
t = open(p, 'rb').read().decode('utf-8')
assert '**T031a4o3**' not in t, 'refusing: T031a4o3 exists'
assert '**T031a4o2**' in t, 'refusing: T031a4o2 is missing'
block = ('- [ ] **T031a4o3** — Pin both regions the reconcile guard admits, at non-round times\n'
    '  - *Files:* `tests/test-spec-gate.sh`\n'
    '  - *Acceptance:* In `test_rounds` (`round_legacy_reconcile_cases`), on the copy of shipped 002\'s date-only '
    'history: the record is reconciled first on the history\'s own date to 2026-07-20T15:17:43Z, a waiver dated '
    '15:17:42Z is refused with `not after the previous round completion at 2026-07-20T15:17:43Z` and one dated '
    '15:17:44Z is authorized; then it is reconciled again on a later day to 2026-07-21T06:17:43Z, and a waiver dated '
    '06:17:42Z is refused with `not after the previous round completion at 2026-07-21T06:17:43Z`. Records stamped '
    '2026-07-20T25:00:00Z (an impossible time) and at 23:59:59Z of the current UTC day (later today; skipped in the '
    'last minute of the day) each exit 3, write no `legacy-time.nul` and leave the next round refused with '
    '`date-only history needs timestamped digest reconciliation`, like the other wrong records. In the one dev run '
    'every mutant opponent rounds 20, 21 and 22 ran against these fixtures is killed except the one round 21 held '
    'equivalent (the read-path round check alone), and each new assertion is killed by at least one (AC-009, '
    'REQ-012).\n'
    '  - *Verify kind:* test\n'
    '  - *Tests:* `tests/test-spec-gate.sh::test_rounds`\n'
    '  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0\n'
    '  - *Reuse:* local\n'
    '  - *Refs:* REQ-012, AC-009, FM-016, INV-004, plan §7\n'
    '  - *Notes:* Repairs O-029 as round 22 left it open (blocking) and O-033 (minor). Test files only, no kernel '
    'change, as the user chose on 2026-10-17 after round 22; the cases follow round 22\'s report '
    '(`notes/verification/reports/opponent-round22.md`) and its prototype, and are applied by '
    '`notes/verification/reports/r23-edits/apply-code.py`; the mutants are `r23-edits/mutants-r23.py`. No gate round, '
    'floor or hosted-CI run is part of this task.\n')
anchor = '\n\n## Observability\n'
assert t.count(anchor) == 1
t = t.replace(anchor, '\n\n' + block + anchor)
out = t.encode('utf-8')
open(p, 'wb').write(out)
print('%s  %s' % (hashlib.sha256(out).hexdigest(), spec + '/tasks.md'))
