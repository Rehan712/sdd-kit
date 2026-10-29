#!/usr/bin/env python3
# Session 24 (2026-10-16): the task block T031a4o2, round 21's proposed follow-up for O-029, opened unticked after
# T031a4o1 at the end of the Tests stage, as the user chose after round 21 ("Repair now", test files only).
# Usage: python3 -I <this> <root>; refuses unless the anchor occurs exactly once and no block exists.
import hashlib, os, sys
root = sys.argv[1]
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
p = os.path.join(root, spec, 'tasks.md')
t = open(p, 'rb').read().decode('utf-8')
assert '**T031a4o2**' not in t, 'refusing: T031a4o2 exists'
block = ('- [ ] **T031a4o2** — Reconcile the legacy record to a time no reading of the date yields\n'
    '  - *Files:* `tests/test-spec-gate.sh`\n'
    '  - *Acceptance:* In `test_rounds` (`round_legacy_reconcile_cases`), on the copy of shipped 002\'s date-only '
    'history: the valid record is reconciled to 2026-07-21T06:00:00Z, a later day than the history\'s date, so '
    'neither its midnight nor its end of day yields that time; a waiver dated 2026-07-21T05:00:00Z is refused with '
    '`not after the previous round completion at 2026-07-21T06:00:00Z`; before the valid record, one stamped '
    '2099-01-01T00:00:00Z exits 3, writes no `legacy-time.nul` and leaves the next round refused with `date-only '
    'history needs timestamped digest reconciliation`, like the wrong-digest, wrong-round and before-the-date '
    'records. In the one dev run every mutant opponent rounds 20 and 21 ran against these fixtures is killed except '
    'the one round 21 held equivalent (the read-path round check alone), and each new assertion is killed by at '
    'least one (AC-009, REQ-012).\n'
    '  - *Verify kind:* test\n'
    '  - *Tests:* `tests/test-spec-gate.sh::test_rounds`\n'
    '  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0\n'
    '  - *Reuse:* local\n'
    '  - *Refs:* REQ-012, AC-009, FM-016, INV-004, plan §7\n'
    '  - *Notes:* Repairs O-029 as round 21 left it open (blocking). Test files only, no kernel change, as the user '
    'chose on 2026-10-16 after round 21; the cases follow round 21\'s report (`notes/verification/reports/'
    'opponent-round21.md`) and `r21-repro-o029.sh`, and are applied by `notes/verification/reports/r22-edits/'
    'apply-code.py`; the mutants are `r22-edits/mutants-r22.py`. No gate round, floor or hosted-CI run is part of '
    'this task.\n')
anchor = '\n\n## Observability\n'
assert t.count(anchor) == 1
t = t.replace(anchor, '\n\n' + block + anchor)
out = t.encode('utf-8')
open(p, 'wb').write(out)
print('%s  %s' % (hashlib.sha256(out).hexdigest(), spec + '/tasks.md'))
