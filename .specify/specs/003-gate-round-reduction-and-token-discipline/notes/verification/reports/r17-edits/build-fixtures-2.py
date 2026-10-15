#!/usr/bin/env python3
# Session 18: build tgc-2.pairs, the rows matrix v5 needs that tgc-1 lacks, from the exact text of the live
# tests/test-gate-contracts.sh (tgc-1 applied). Each block anchors on the last row of a table and its terminator, so
# lit.pl applies it exactly once. The rows isolate guards of T030o48, T030o49 and T030o50 that no row reached
# (r17-discover-*.log, r17-rows-probe.sh): positives a blank line, a CRLF blank line, a heading of six marks (plain and
# quoted) and the run's reset of carried code-span states must keep parsing; refusals a construct across three lines,
# a code span closing one or two lines later, a stray or escaped bracket, an unclosed backtick run before a span, and a
# processing instruction; two positives outside every finding judge the label reader's comment closer and its break
# names there, where the narrowed grammar does not reach; and raw HTML in a canonical round's Held-up section parses.
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
MO = '### Finding O-017\\n- **Class:** harness-locale-decoding\\n- **Severity:** wrong-result\\n'
MG = '### Finding G-042\\n- **Class:** tier-binding\\n- **Severity:** minor\\n'
# (1) the plausible manifests that must parse (report_manifest_locale_cases)
last = line_starting('nbsp-line-prose|### Finding O-017', 'SHAPES\n')
rows = [
  'image-split-by-blank-line|' + MO + '\\n![x\\n\\ny](u)Severity: data-loss\\n',
  'image-split-by-crlf-blank-line|' + MO + '\\n![x\\r\\n\\r\\ny](u)Severity: data-loss\\r\\n',
  'image-split-by-six-marks|' + MO + '\\n![x\\n###### h\\ny](u)Severity: data-loss\\n',
  'quoted-image-split-by-six-marks|' + MO + '\\n> ![x\\n> ###### h\\n> y](u)Severity: data-loss\\n',
  'span-tag-after-a-lone-backtick-paragraph|' + MO + '\\nNote `a\\n\\nb` <b>` c\\n',
  'outside-comment-closer|' + MO + '\\n## Notes\\n\\nO-017 is discussed below.\\n- <!--> note --> Severity: as noted.\\n',
  'outside-span-tag|' + MO + '\\n## Notes\\n\\nO-017 is discussed below.\\nNote <span>Severity: as noted</span> stays prose.\\n',
]
block(last + '\nSHAPES', last + '\n' + '\n'.join(rows) + '\nSHAPES')
# (2) the manifest refusals of report_record_line_cases
members = [
  ('tag-after-span-closing-next-line', 'Note `a\\nb` <b>` c', 'raw HTML outside a code span in finding G-042'),
  ('tag-after-span-closing-two-lines-later', 'Note `a\\nb\\nc` <b>` d', 'raw HTML outside a code span in finding G-042'),
  ('pi-in-prose', 'Note <?x?> here.', 'raw HTML outside a code span in finding G-042'),
  ('image-alt-across-three-lines', '![x\\ny\\nz](u)Severity: data-loss', 'a second Severity line in finding G-042'),
  ('link-title-across-three-lines', '[](x\\n"t\\nu")Severity: data-loss', 'a second Severity line in finding G-042'),
  ('image-alt-holding-code-span-across-lines', '![x `]`\\ny\\n](u)Severity: data-loss', 'a second Severity line in finding G-042'),
  ('image-alt-code-span-closing-two-lines-later', '![x `]\\ny\\n`](u)Severity: data-loss', 'a second Severity line in finding G-042'),
  ('tag-attribute-across-three-lines', '<b title="a\\nx\\ny">Severity: data-loss</b>', 'a second Severity line in finding G-042'),
  ('image-after-stray-bracket-across-three-lines', ']![a\\nb\\nc](u)Severity: data-loss', 'a second Severity line in finding G-042'),
  ('image-alt-holding-escaped-bracket-across-lines', '![a\\\\]\\nb\\nc](u)Severity: data-loss', 'a second Severity line in finding G-042'),
  ('image-alt-holding-an-unclosed-run-then-a-span', '![``a `]`](u)Severity: data-loss', 'a second Severity line in finding G-042'),
]
last = line_starting('image-after-backtick-info-fence|### Finding G-042', 'ROWS\n')
block(last + '\nROWS', last + '\n' + '\n'.join('%s|%s\\n%s\\n|%s' % (l, MG, b, d) for l, b, d in members) + '\nROWS')
# (3) the canonical refusals of report_record_line_cases
last = line_starting('image-after-backtick-info-fence|- **Severity:** minor', 'ROWS\n')
canon = []
for l, b, d in members:
    d = d.replace('a second Severity line in finding G-042', 'a Severity line this grammar cannot read in finding G-050').replace('G-042', 'G-050')
    canon.append('%s|- **Severity:** minor\\n\\n%s|%s' % (l, b, d))
block(last + '\nROWS', last + '\n' + '\n'.join(canon) + '\nROWS')
# (4) the canonical positives of report_record_line_cases
last = line_starting('a-nbsp-line|### Finding G-042', 'ROWS\n')
pos = [
  'a-image-split-by-blank-line|### Finding G-042|\\n![x\\n\\ny](u)Severity: data-loss\\n\\n',
  'a-image-split-by-six-marks|### Finding G-042|\\n![x\\n###### h\\ny](u)Severity: data-loss\\n\\n',
  'a-quoted-image-split-by-six-marks|### Finding G-042|\\n> ![x\\n> ###### h\\n> y](u)Severity: data-loss\\n\\n',
  'a-span-tag-after-a-lone-backtick-paragraph|### Finding G-042|\\nNote `a\\n\\nb` <b>` c\\n\\n',
]
block(last + '\nROWS', last + '\n' + '\n'.join(pos) + '\nROWS')
# (5) raw HTML in the Held-up section of a canonical round, outside every finding, parses
held = "  assert_not_contains \"$OUT\" 'report recovery' 'AC-012: Held-up prose after the last finding was refused (O-018)'"
new_held = held + '''
  record_round 1 CHALLENGED 1 0 '### Finding G-042' tier-binding new '- **Severity:** data-loss' |
    sed 's/^Fixture disposition recorded\\.$/Held up: <b>no tier<\\/b> here./' > "$report"
  run_rc 0 record_line_vf C "$report" "$spec"
  assert_not_contains "$OUT" 'report recovery' 'AC-012: raw HTML in Held-up prose outside every finding was refused (round 16, O-018)\''''
block(held, new_held)
open(sys.argv[1], 'w', encoding='utf-8').write(''.join(out))
print('blocks', len(out))
