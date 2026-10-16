#!/usr/bin/env python3
# Session 20: build tgc-3.pairs from the exact text of the live tests/test-gate-contracts.sh (tgc-1 and tgc-2
# applied): one row in each pass of report_record_line_cases for v5's D04, the open-code-span condition of
# vf_settled, which T030o53's head bracket test shields on D04's v5 row (`![x `]` completed two lines later: the open
# image bracket before the first word keeps that candidate already). The new row has no bracket before the first
# word of any reading (an entity, then a code span left open across lines that holds an image), so only the open
# span keeps the candidate; once the span closes, the inert reading's first word is the tier (r18-rows-probe-3).
# Usage from the worktree root: python3 -I <this> <out-pairs>
import sys
T = open('tests/test-gate-contracts.sh', encoding='utf-8').read()
out = []
def block(old, new):
    assert T.count(old) == 1, (T.count(old), old[:80])
    out.append('@@OLD\n' + old + '\n@@NEW\n' + new + '\n@@END\n')
def line_starting(prefix, after):
    i = T.index(prefix)
    while True:
        j = T.index('\n', i)
        if T[j + 1:].startswith(after): return T[i:j]
        i = T.index(prefix, j)
MG = '### Finding G-042\\n- **Class:** tier-binding\\n- **Severity:** minor\\n'
BODY = '&amp;`![Severity: data-loss](u) z\\ny\\nw`'
last = line_starting('image-title-across-lines-outside-finding-after-id|', 'ROWS\n')
block(last + '\nROWS', last + '\nentity-then-code-span-holding-image-across-lines|' + MG + '\\n' + BODY + '\\n|a second Severity line in finding G-042\nROWS')
last = line_starting('title-tag-inside-finding|- **Severity:** minor', 'ROWS\n')
block(last + '\nROWS', last + '\nentity-then-code-span-holding-image-across-lines|- **Severity:** minor\\n\\n' + BODY + '|a Severity line this grammar cannot read in finding G-050\nROWS')
open(sys.argv[1], 'w', encoding='utf-8').write(''.join(out))
print('blocks', len(out))
