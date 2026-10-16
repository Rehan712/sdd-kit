#!/usr/bin/env python3
# Session 19: build tgc-2.pairs, the rows matrix v6 needs that tgc-1 lacks, from the exact text of the live
# tests/test-gate-contracts.sh (tgc-1 applied). Each block anchors on the last row of a table and its terminator, so
# lit.pl applies it exactly once. The rows isolate guards of T030o51 to T030o53 that no row reached (the discovery
# probe r18-discover-{a,b,c}.log): members a renderer reads as a link while a reader that missed one production of
# 6.3 would not (a destination after a space, a pointy destination holding a space or an escaped `>`, a bare one
# holding an escaped or a nested parenthesis, a title in parentheses or holding an escaped quote, a label holding an
# escaped bracket, a bare destination or a title left open at a line's end), a fence after a tab in a list item, an
# image completed across lines after an ordered-list number, a tag on a deeper heading and on a report title inside
# a finding, and outside every finding after a finding ID an image completed after a br; the three image rows that
# isolate the settled test (S03, S09, S10) carry one line inside the image before the line that completes it,
# because vf_para_label reads a candidate's label before it asks vf_settled, so a candidate can only be dropped
# early on a line between the opening and the completing one (session 20: r18-rows-probe,
# r18-fixtures-judge-2-run2.note); a link reference definition after a block-quote marker, and outside every
# finding after a finding ID an image whose alt begins with a code span holding `]` completed after a tag and an
# image whose title spans lines after such an alt (the mutants R03, S08 and S07, which session 19 listed as
# equivalents: r18-rows-probe-2, r18-fixtures-judge-2-run3.note); positives a renderer reads
# as no link and a reader that over-read one production would refuse (a pointy destination holding `<` or left
# open, a bare destination holding a space, a destination followed by a code span, a label holding a bracket, a
# bracket left open at the start of a line before a blank line, a nested bracket before `]:`).
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
AU = 'an autolink outside a code span'
BT = 'a backtick inside a link destination, title or label'
OP = 'a link destination, title or label that does not end on its line'
FE = 'a code fence that may be inside a list item'
RAW = 'raw HTML outside a code span'
MO = '### Finding O-017\\n- **Class:** harness-locale-decoding\\n- **Severity:** wrong-result\\n'
MG = '### Finding G-042\\n- **Class:** tier-binding\\n- **Severity:** minor\\n'
TK = '<br>Severity: data-loss, tick: `.'
PR = '<pre>Severity: data-loss</pre>`'
# (label, body after the minor tier and a blank line, diagnostic) for both passes
members = [
  ('destination-after-space', '[x]( u`v)' + TK, BT),
  ('angle-destination-with-space', '[x](<:x `b>)' + PR, BT),
  ('angle-destination-escaped-gt', '[x](<:a\\\\>b`c>)' + PR, BT),
  ('destination-escaped-paren', '[x](u\\\\)v`w)' + TK, BT),
  ('destination-nested-parens', '[x](u(v)`w)' + TK, BT),
  ('bare-destination-at-line-end', '[x](u\\n"x`")' + TK, OP),
  ('destination-space-at-line-end', '[x](u \\n"x`")' + TK, OP),
  ('title-in-parens', '[x](u (`))' + TK, BT),
  ('title-escaped-quote', '[x](u "a\\\\"`")' + TK, BT),
  ('title-then-line-end', '[x](u "t"\\n)x`' + TK, OP),
  ('label-escaped-bracket', '[x][a\\\\]`b]' + TK, BT),
]
# (1) the plausible manifests that must parse (report_manifest_locale_cases)
last = line_starting('narrowed-constructs-outside|', 'SHAPES\n')
pos = [
  ('invalid-angle-destination-holding-lt', '- See [x](<: < `b>) here.\\n'),
  ('unclosed-angle-destination', '- See [x](<:a here and more.\\n'),
  ('destination-with-space-then-code', '- See [x](u v`) and `code`.\\n'),
  ('destination-then-code-span', '- See [x](u `v`) here.\\n'),
  ('bracket-inside-label-position', '- The arr[i][j[`k`]] index.\\n'),
  ('nested-bracket-then-colon-at-line-start', '\\n[a [b]: x\\n'),
  ('bracket-left-open-before-blank-line', '\\n[a note\\n\\nb]: here\\n'),
]
block(last + '\nSHAPES', last + '\n' + '\n'.join('%s|%s%s' % (l, MO, b) for l, b in pos) + '\nSHAPES')
# (2) the manifest refusals of report_record_line_cases
mrows = ['%s|%s\\n%s\\n|%s in finding G-042' % (l, MG, b, d) for l, b, d in members]
mrows += [
  'fence-after-tab|' + MG + '- note\\n\\n\\t```\\n  ### x\\n\\t```\\n- **Severity**: data-loss\\n|' + FE + ' in finding G-042',
  'ordered-number-then-image|' + MG + '\\n1. ![q\\nx\\n](u)Severity: data-loss\\n|a second Severity line in finding G-042',
  'image-alt-beginning-with-code-span-across-lines|' + MG + '\\n![ `]` x\\ny\\n](u)Severity: data-loss\\n|a second Severity line in finding G-042',
  'heading-tag-on-deeper-heading|' + MG + '#### Notes <b>x</b>\\nA note.\\n|' + RAW + ' in finding G-042',
  'definition-after-quote-marker|' + MG + '\\n> [a]: /u\\n|a link reference definition in finding G-042',
  'break-image-outside-finding-after-id|### Finding G-041\\n- **Class:** tier-binding\\n- **Severity:** minor\\n## Notes\\n\\nG-042 is discussed below.\\nNote<br>&nbsp;![q\\nx\\n](u)Severity: data-loss\\n|a severity line outside any Finding',
  'tag-image-alt-code-span-outside-finding-after-id|### Finding G-041\\n- **Class:** tier-binding\\n- **Severity:** minor\\n## Notes\\n\\nG-042 is discussed below.\\n\\n<b>![ `]` x\\ny\\n](u)Severity: data-loss\\n|a severity line outside any Finding',
  'image-title-across-lines-outside-finding-after-id|### Finding G-041\\n- **Class:** tier-binding\\n- **Severity:** minor\\n## Notes\\n\\nG-042 is discussed below.\\n\\n![ `]` x ](u "a\\ny\\nb")Severity: data-loss\\n|a severity line outside any Finding',
]
last = line_starting('heading-tag-on-later-finding|', 'ROWS\n')
block(last + '\nROWS', last + '\n' + '\n'.join(mrows) + '\nROWS')
# (3) the canonical refusals of report_record_line_cases
crows = ['%s|- **Severity:** minor\\n\\n%s|%s in finding G-050' % (l, b, d) for l, b, d in members]
crows += [
  'ordered-number-then-image|- **Severity:** minor\\n\\n1. ![q\\nx\\n](u)Severity: data-loss|a Severity line this grammar cannot read in finding G-050',
  'image-alt-beginning-with-code-span-across-lines|- **Severity:** minor\\n\\n![ `]` x\\ny\\n](u)Severity: data-loss|a Severity line this grammar cannot read in finding G-050',
  'heading-tag-on-deeper-heading|- **Severity:** minor\\n\\n#### Notes <b>x</b>\\nA note.|' + RAW + ' in finding G-050',
  'definition-after-quote-marker|- **Severity:** minor\\n\\n> [a]: /u|a link reference definition in finding G-050',
  'title-tag-inside-finding|- **Severity:** minor\\n\\n# Opponent review <b>x</b>|' + RAW + ' in finding G-050',
]
last = line_starting('definition-line|- **Severity:** minor', 'ROWS\n')
block(last + '\nROWS', last + '\n' + '\n'.join(crows) + '\nROWS')
# (4) the O-024 tails: a fence after a tab in a list item
last = line_starting('definition-escaped-label|\\n[a', 'ROWS\n')
block(last + '\nROWS', last + '\nfence-after-tab|- **Severity:** minor\\n- note\\n\\n\\t```\\n  ### x\\n\\t```\\n- **Severity**: data-loss\\n|' + FE + ' in finding G-050\nROWS')
# (5) the canonical positives of report_record_line_cases
cpos = []
for l, b in pos:
    body = b if b.startswith('\\n') else '  ' + b
    if b.startswith('\\n'): body = b + '\\n'
    cpos.append('a-%s|### Finding G-042|%s' % (l, body))
last = line_starting('a-task-checkboxes|### Finding G-042', 'ROWS\n')
block(last + '\nROWS', last + '\n' + '\n'.join(cpos) + '\nROWS')
open(sys.argv[1], 'w', encoding='utf-8').write(''.join(out))
print('blocks', len(out))
