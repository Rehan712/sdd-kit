#!/usr/bin/env python3
# Session 21 (2026-10-14): the documents of the round-18 repair batch, as the user decided on 2026-10-14: the spec
# revision of REQ-011 (gate reports are trusted-author input, so a rendering divergence in a report is minor) and the
# task blocks T030o54 (O-018, the reviewer's M1), T030o55 (O-025, M2) and T030o56 (O-023, M3), opened unticked after
# T030o53. Usage: python3 -I <this> <root>; refuses unless every anchor occurs exactly once and no block exists yet.
import hashlib, os, sys
root = sys.argv[1]
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
P = {'spec': spec + '/spec.md', 'tasks': spec + '/tasks.md'}
text = {k: open(os.path.join(root, p), 'rb').read().decode('utf-8') for k, p in P.items()}

def once(k, old, new):
    n = text[k].count(old)
    assert n == 1, '%s: anchor count %d: %r' % (k, n, old[:90])
    text[k] = text[k].replace(old, new)

once('spec', '  Severity never changes merely to meet a round or cost target.\n- **REQ-012',
     '  Severity never changes merely to meet a round or cost target. Threat\n'
     '  model (the user\'s revision of 2026-10-14): gate reports are\n'
     '  trusted-author input, written by the kit\'s own gate agents and read\n'
     '  by people as well as by the tally, so a rendering divergence in a\n'
     '  report (markdown a renderer shows differently from how the documented\n'
     '  report grammar reads it, which that grammar neither reads nor\n'
     '  refuses) is degraded, hence minor, and is recorded for a follow-up\n'
     '  spec; a report written in the documented grammar that the gate\n'
     '  misreads still blocks as wrong-result.\n'
     '- **REQ-012')

for t in ('T030o54', 'T030o55', 'T030o56'):
    assert ('**%s**' % t) not in text['tasks'], 'refusing: %s exists' % t
common = ('  - *Files:* `scripts/verification-lib.sh`, `templates/verification-contract.md`, `tests/test-gate-contracts.sh`, `tests/test-spec-gate.sh`\n'
    '%s'
    '  - *Verify kind:* test\n'
    '  - *Tests:* `tests/test-gate-contracts.sh::test_reports_and_tally`, `tests/test-spec-gate.sh::test_rounds`\n'
    '  - *Verify:* `bash tests/run.sh && bash tests/shellcheck.sh` → all suites `passed`, exit 0\n'
    '  - *Reuse:* local\n'
    '  - *Refs:* REQ-011, AC-009, AC-012, FM-016, FM-019, INV-004, INV-006, plan §3.3, §4.3\n'
    '%s')
tail = (' Reproduced before repair (`notes/verification/reports/r19-repro.{sh,log,rc,time}`); the kernel change is the '
    'round-18 reviewer\'s own mutant, taken from its transcript and applied by '
    '`notes/verification/reports/r19-edits/apply-code.py`. Under the user\'s decision of 2026-10-14 the invoker\'s '
    'extra proof steps (the mutation matrix, two-direction fixture judging, a separate measurement script, repeated '
    'dev runs) are not run for this repair; one dev run in a standalone copy and the capture of record prove it. '
    'T030o54, T030o55 and T030o56 are serial, because all three edit the same four files; one capture of the shared '
    'Verify on unchanged source can serve all three acceptances. No gate round, floor or hosted-CI run is part of '
    'this task.\n')
blocks = (
    '- [ ] **T030o54** — Narrow the finding grammar further: refuse by name a backtick inside a bracket pair closed on its line or inside a GFM URL literal, outside every code span\n'
    + common % (
    '  - *Acceptance:* As the user decided on 2026-10-14 (the round-18 reviewer\'s M1), inside a finding, in both '
    'readers of finding records (the manifest pass, and the canonical pass of a canonical round before its completion '
    'marker), a line is refused by name when, outside every code span in some reading, it carries a bracket pair '
    'closed on its line whose label holds a backtick run the label does not close (a shortcut, collapsed or image '
    'reference\'s label: `a backtick inside a link destination, title or label`), or a URL literal after `http://`, '
    '`https://` or `ftp://` (the scheme ending the text before it) or after `www.`, whose text up to whitespace or '
    '`<` holds a backtick (`an autolink outside a code span`): the constructs marked binds before any code span '
    '(REQ-011, AC-012). Rows in both passes and both locales for every round-18 member (the four URL spellings and '
    'the three reference spellings); positives that parse (a URL literal before a code span, link text holding a '
    'closed code span, references with no backtick in their labels, `www.` in prose); and end to end, a URL member '
    'and a reference member in the manifest pass and a `www.` member and an image-reference member in the '
    'canonical pass, each refused at completion by name.\n',
    '  - *Notes:* Owns round-18 O-018 (reopened, blocking); its members predate T030o51.' + tail) +
    '\n- [ ] **T030o55** — Refuse by name inside a finding a line that may be a GFM table delimiter row\n'
    + common % (
    '  - *Acceptance:* As the user decided on 2026-10-14 (the round-18 reviewer\'s M2), inside a finding, in both '
    'readers of finding records, a line whose text, spaces and tabs removed, holds a pipe and is a run of hyphen '
    'cells with optional colons separated by pipes is refused by name (`a table delimiter row`), since a renderer '
    'shows a cell\'s first text where the label reader, which never splits a line at a pipe, does not look '
    '(REQ-011, AC-012). Rows in both passes and both locales for a table and for a table in a list item with '
    'alignment colons; positives that parse (pipes in prose and in code spans); and end to end, a table in the '
    'manifest pass and a table after the fields of a canonical finding, each refused at completion by name.\n',
    '  - *Notes:* Owns round-18 O-025 (new, blocking); its members predate T030o51, the gap dating from the label '
    'reader itself.' + tail) +
    '\n- [ ] **T030o56** — Settle a run reader\'s candidate when its head or its whole text balances\n'
    + common % (
    '  - *Acceptance:* As the user decided on 2026-10-14 (the round-18 reviewer\'s M3), a candidate is settled when '
    'its lead is settled and either its head\'s brackets balance (T030o53\'s rule) or its whole text\'s brackets '
    'balance with complete destinations (T030o50\'s rule), each argued sound alone (REQ-011, AC-012). A 400-line '
    'Reproduced field of sub-bullets led in turn by a link, an image and a code span holding a bracket parses '
    'within 60 s (0.32 s on the candidate; about 30 s at 100 lines on the round-18 tree), and the round-17 400-line '
    'row stays within its bound.\n',
    '  - *Notes:* Owns round-18 O-023 (reopened, minor, degraded): T030o53\'s head-only rule left link-led lines '
    'unsettled.' + tail))
once('tasks', '\n\n## API\n', '\n\n' + blocks + '\n## API\n')

for k, p in P.items():
    out = text[k].encode('utf-8')
    open(os.path.join(root, p), 'wb').write(out)
    print('%s  %s' % (hashlib.sha256(out).hexdigest(), p))
