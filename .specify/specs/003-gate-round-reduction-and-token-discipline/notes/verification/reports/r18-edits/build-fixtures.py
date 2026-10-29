#!/usr/bin/env python3
# Session 19: build tgc-1.pairs and tsg-1.pairs, the fixtures for round 17's O-018, O-024 and O-023 and its minor
# (T030o51, T030o52, T030o53), from the exact text of the live tests/test-gate-contracts.sh and tests/test-spec-gate.sh,
# so every OLD block is taken verbatim and lit.pl applies it exactly once. Pattern: r17-edits/build-fixtures-2.py.
# Rows: every round-17 member and derived sibling in both passes, each with its exact diagnostic (the manifest pass in
# report_record_line_cases' first table, the canonical pass in its second table, the O-024 tails after every field in
# a table of their own); the stated consequences as refusals; the positives (the round-17 members quoted inside
# two-backtick code spans, a link with a title, reference links, a `<` before a space, link text wrapped at the start
# of a line, an escaped bracket, a column-0 fence, task checkboxes, a heading carrying a tag that closes a finding, the
# narrowed constructs outside every finding); the minor's three cases; the 400-line timing row; and one end-to-end
# case per mechanism in round_record_line_cases.
# Usage from the worktree root: python3 -I <this> <out-dir>
import sys
out_dir = sys.argv[1]
T = open('tests/test-gate-contracts.sh', encoding='utf-8').read()
G = open('tests/test-spec-gate.sh', encoding='utf-8').read()
def block(src, acc, old, new):
    assert src.count(old) == 1, (src.count(old), old[:80])
    acc.append('@@OLD\n' + old + '\n@@NEW\n' + new + '\n@@END\n')
def line_starting(src, prefix, after):
    i = src.index(prefix)
    while True:
        j = src.index('\n', i)
        if src[j + 1:].startswith(after): return src[i:j]
        i = src.index(prefix, j)
AU = 'an autolink outside a code span'
BT = 'a backtick inside a link destination, title or label'
OP = 'a link destination, title or label that does not end on its line'
FE = 'a code fence that may be inside a list item'
RD = 'a link reference definition'
RAW = 'raw HTML outside a code span'
MO = '### Finding O-017\\n- **Class:** harness-locale-decoding\\n- **Severity:** wrong-result\\n'
MG = '### Finding G-042\\n- **Class:** tier-binding\\n- **Severity:** minor\\n'
MC = '### Finding G-042\\n- **Class:** tier-binding\\n'
DEF = "[a]: /u '\\n    - **Severity:** minor\\n    - x'\\n"
FEN = '- ```\\n  ### x\\n- **Severity**: data-loss\\n'
t = []
# (1) the plausible manifests that must parse (report_manifest_locale_cases)
last = line_starting(T, 'outside-span-tag|### Finding O-017', 'SHAPES\n')
rows = [
  'quoted-destination-member|' + MO + '- The form `` [x](u`v)<br>Severity: data-loss, tick: `. `` stays quoted.\\n',
  'quoted-autolink-member|' + MO + '- The form `` Note <1`@a.b><pre>Severity: data-loss</pre>` `` stays quoted.\\n',
  'link-title-then-code|' + MO + '- See [the doc](u "a title") and `code` after it.\\n',
  'reference-links-prose|' + MO + '- See [the doc][ref] and [x][] here.\\n',
  'lt-before-a-space|' + MO + '- It takes < 30 s and > 2 s.\\n',
  'wrapped-link-at-line-start|' + MO + '\\n[a note that\\nwraps](u) here.\\n',
  'escaped-bracket-at-line-start|' + MO + '\\n\\\\[a]: is not a definition here.\\n',
  'task-checkboxes|' + MO + '- [x] done\\n- [ ] open\\n',
  'column-zero-fence-after-blank|' + MO + '\\n```text\\nplain\\n```\\n',
  'heading-with-tag-closes-finding|' + MO + '### Notes <b>x</b>\\nA note.\\n',
  'narrowed-constructs-outside|[ref]: https://x.example\\n\\n' + MO + '## Notes\\n\\nNote <1@x.example>, [a](u`v) and c <= d.\\n- ```\\n  x\\n- y\\n',
]
block(T, t, last + '\nSHAPES', last + '\n' + '\n'.join(rows) + '\nSHAPES')
# (2) the manifest refusals of report_record_line_cases
members = [
  ('autolink-digit-br', MG + '\\nNote <1`@a.b><br>Severity: data-loss, tick: `.\\n', AU),
  ('autolink-digit-pre', MG + '\\nNote <1`@a.b><pre>Severity: data-loss</pre>`\\n', AU),
  ('autolink-underscore-p', MG + '\\nNote <_`@a.b><p>Severity: data-loss `\\n', AU),
  ('autolink-backtick-start', MG + '\\nNote <`a@b.c><br>Severity: data-loss, tick: `.\\n', AU),
  ('autolink-plus', MG + '\\nNote <+1`@a.b><br>Severity: data-loss, tick: `.\\n', AU),
  ('destination-holding-backtick', MG + '\\n[x](u`v)<br>Severity: data-loss, tick: `.\\n', BT),
  ('title-holding-backtick', MG + '\\n[x](u "`")<br>Severity: data-loss, tick: `.\\n', BT),
  ('angle-destination-holding-backtick', MG + '\\n[x](<1`b>)<pre>Severity: data-loss</pre>`\\n', BT),
  ('label-holding-backtick', '[a`b]: /u\\n\\n' + MG + '\\n[x][a`b]<br>Severity: data-loss, tick: `.\\n', BT),
  ('title-across-lines', MG + "\\n[x](u '\\ny`')<br>Severity: data-loss, tick: `.\\n", OP),
  ('destination-on-next-line', MG + '\\n[x](\\nu`v)<br>Severity: data-loss, tick: `.\\n', OP),
  ('label-across-lines', MG + '\\n[x][a\\nb`]<br>Severity: data-loss, tick: `.\\n', OP),
  ('fence-after-list-marker', MG + FEN, FE),
  ('fence-swapping-phase', MG + '- note\\n  ```\\n```\\n### x\\n```\\n- **Severity**: data-loss\\n- y\\n  ```\\n', FE),
  ('fence-four-spaces-in-item', MG + '- note\\n\\n    ```\\n  ### x\\n    ```\\n- **Severity**: data-loss\\n', FE),
  ('fence-after-ordered-marker', MG + '1. ~~~\\n   ### x\\n- **Severity**: data-loss\\n', FE),
  ('definition-hiding-severity', MC + '\\n' + DEF, RD),
  ('definition-then-fence', MC + '\\n' + DEF + '\\n' + FEN, RD),
  ('definition-in-list-item', MC + "- [a]: /u '\\n      - **Severity:** minor\\n      - x'\\n", RD),
  ('definition-label-across-lines', MC + "\\n[a\\nb]: /u '\\n    - **Severity:** minor\\n    - x'\\n", RD),
  ('definition-escaped-label', MC + "\\n[a\\\\]b]: /u '\\n    - **Severity:** minor\\n    - x'\\n", RD),
  ('lt-equals-prose', MG + '\\nIt holds when c <= d.\\n', AU),
  ('indented-fence-in-item', MG + '- step\\n  ```\\n  bash x\\n  ```\\n', FE),
  ('definition-line', MG + '\\n[a]: https://x.example\\n', RD),
]
def mdiag(d, fid): return d + ' in finding ' + fid
last = line_starting(T, 'image-alt-holding-an-unclosed-run-then-a-span|### Finding G-042', 'ROWS\n')
mrows = ['%s|%s|%s' % (l, b, mdiag(d, 'G-042')) for l, b, d in members]
mrows += ['heading-tag-on-first-finding|### Finding G-042 <b>x</b>\\n- **Class:** tier-binding\\n- **Severity:** minor\\n|' + mdiag(RAW, 'G-042'),
          'heading-tag-on-later-finding|### Finding G-041\\n- **Class:** tier-binding\\n- **Severity:** minor\\n### Finding G-042 <b>x</b>\\n- **Class:** tier-binding\\n- **Severity:** minor\\n|' + mdiag(RAW, 'G-042')]
block(T, t, last + '\nROWS', last + '\n' + '\n'.join(mrows) + '\nROWS')
# (3) the canonical refusals of report_record_line_cases, then the O-024 tails, the minor and the timing row
last = line_starting(T, 'image-alt-holding-an-unclosed-run-then-a-span|- **Severity:** minor', 'ROWS\n')
inline = ['autolink-digit-br', 'autolink-digit-pre', 'autolink-underscore-p', 'autolink-backtick-start', 'autolink-plus',
          'destination-holding-backtick', 'title-holding-backtick', 'angle-destination-holding-backtick',
          'label-holding-backtick', 'title-across-lines', 'destination-on-next-line', 'label-across-lines',
          'lt-equals-prose', 'indented-fence-in-item', 'definition-line']
crows = []
for l, b, d in members:
    if l not in inline: continue
    body = b.replace(MG, '').replace('[a`b]: /u\\n\\n', '')
    if body.startswith('\\n'): body = body[2:]
    if body.endswith('\\n'): body = body[:-2]
    crows.append('%s|- **Severity:** minor\\n\\n%s|%s' % (l, body, mdiag(d, 'G-050')))
tails = [(l, b.replace(MG, '- **Severity:** minor\\n').replace(MC, ''), d) for l, b, d in members
         if l.startswith(('fence-', 'definition-')) and l not in ('definition-line',)]
tail_rows = '\n'.join('%s|%s|%s' % (l, b, mdiag(d, 'G-050')) for l, b, d in tails)
F2 = ('### Finding G-051 <b>x</b>\\n- **Class:** dup-binding\\n- **Status:** new\\n- **Prior:** none\\n'
      '- **Severity:** data-loss\\n- **Scenario:** a recorded trigger\\n- **Where:** scripts/run.sh:9\\n'
      '- **Reproduced:** concrete trigger at that site\\n- **Root cause:** implementation-error\\n- **Blocks:** AC-012\\n'
      '- **Wrong behavior:** observed versus required\\n- **Class-wide fix:** read or refuse every record line\\n')
code = '''
  # A finding'"'"'s extent, and the lines a reader sees, come from constructs both
  # readers follow (round 17, O-024): inside a canonical finding a code fence
  # that may be inside a list item and a link reference definition are refused
  # by name, so a fence a list item opens cannot hide a line both passes read
  # as closing the finding, and a definition cannot carry a field line no
  # renderer shows. Each tail follows every field of the finding.
  while IFS='|' read -r tag tail want; do
    record_round 1 CLEARED 0 1 '### Finding G-050' tier-binding new '' |
      awk -v t="$tail" 'index($0, "### Held up") == 1 {printf "%s", t} {print}' > "$report"
    for l in C en_US.UTF-8; do
      run_rc 3 record_line_vf "$l" "$report" "$spec"
      assert_contains "$OUT" "$want" "AC-012: a canonical finding whose tail is $tag was not refused by name under LANG=$l (round 17, O-024)"
    done
  done <<'ROWS'
''' + tail_rows + '''
ROWS
  # The narrowed check is judged after the heading on a line has opened or
  # closed a finding (round 17): a Finding heading carrying raw HTML is refused
  # under the finding it opens, the first one of a round included, and a
  # section heading that closes a finding is outside it.
  for l in C en_US.UTF-8; do
    record_round 1 CHALLENGED 1 0 '### Finding G-050 <b>x</b>' dup-binding new '- **Severity:** data-loss' > "$report"
    run_rc 3 record_line_vf "$l" "$report" "$spec"
    assert_contains "$OUT" 'raw HTML outside a code span in finding G-050' \\
      "AC-012: the first Finding heading of a round carried raw HTML under LANG=$l (round 17)"
    record_round 1 CHALLENGED 2 0 '### Finding G-050' dup-binding new '- **Severity:** data-loss' |
      awk -v t="''' + F2 + '''" 'index($0, "### Held up") == 1 {printf "%s", t} {print}' > "$report"
    run_rc 3 record_line_vf "$l" "$report" "$spec"
    assert_contains "$OUT" 'raw HTML outside a code span in finding G-051' \\
      "AC-012: a later Finding heading carrying raw HTML was not refused under the finding it opens under LANG=$l (round 17)"
    assert_not_contains "$OUT" 'in finding G-050' \\
      "AC-012: a later Finding heading carrying raw HTML was refused under the finding it closes under LANG=$l (round 17)"
    record_round 1 CHALLENGED 1 0 '### Finding G-050' dup-binding new '- **Severity:** data-loss' |
      awk 'index($0, "### Held up") == 1 {print "### Notes <b>x</b>"; print "A note."} {print}' > "$report"
    run_rc 0 record_line_vf "$l" "$report" "$spec"
    assert_not_contains "$OUT" 'report recovery' \\
      "AC-012: a section heading that closes a finding was refused as raw HTML inside it under LANG=$l (round 17)"
  done
  # A candidate is settled on what opens at or before the first word of each of
  # its readings (round 17, O-023): one bracket quoted in a code span above a
  # long run keeps no later line re-read, so a 400-line Reproduced field parses
  # in seconds, where the round-17 tree took about 300 s.
  record_round 1 CHALLENGED 1 0 '### Finding G-050' dup-binding new '- **Severity:** data-loss' |
    awk -v n=400 'index($0, "- **Reproduced:**") == 1 {print "- **Reproduced:** the opening bracket `[` is quoted in a code span here"; for (i = 0; i < n; i++) printf "  - step %d: ran `vf_reports x` against [the copy](https://x.example/%d) and saw *exit 0* with `rc=%d` here, fine\\n", i, i, i; next} {print}' > "$report"
  t0=$SECONDS
  run_rc 0 record_line_vf C "$report" "$spec"
  assert_not_contains "$OUT" 'report recovery' 'AC-012: a 400-line run under a bracket quoted in a code span was refused (round 17, O-023)'
  (( SECONDS - t0 < 60 )) || t_fail "AC-012: a 400-line run under a bracket quoted in a code span took $((SECONDS - t0)) s, not under 60 s (round 17, O-023)"'''
code = code.replace("""A finding'"'"'s extent""", 'The extent of a finding')
block(T, t, last + '\nROWS', last + '\n' + '\n'.join(crows) + '\nROWS' + code)
# (4) the canonical positives of report_record_line_cases
last = line_starting(T, 'a-span-tag-after-a-lone-backtick-paragraph|### Finding G-042', 'ROWS\n')
pos = [
  'a-quoted-destination-member|### Finding G-042|  - The form `` [x](u`v)<br>Severity: data-loss, tick: `. `` stays quoted.\\n',
  'a-quoted-autolink-member|### Finding G-042|  - The form `` Note <1`@a.b><pre>Severity: data-loss</pre>` `` stays quoted.\\n',
  'a-link-title-then-code|### Finding G-042|  - See [the doc](u "a title") and `code` after it.\\n',
  'a-reference-links|### Finding G-042|  - See [the doc][ref] and [x][] here.\\n',
  'a-lt-before-a-space|### Finding G-042|  - It takes < 30 s and > 2 s.\\n',
  'a-wrapped-link-at-line-start|### Finding G-042|\\n[a note that\\nwraps](u) here.\\n\\n',
  'a-escaped-bracket-at-line-start|### Finding G-042|\\n\\\\[a]: is not a definition here.\\n\\n',
  'a-column-zero-fence|### Finding G-042|\\n```text\\nplain\\n```\\n\\n',
  'a-task-checkboxes|### Finding G-042|  - [x] done\\n  - [ ] open\\n',
]
block(T, t, last + '\nROWS', last + '\n' + '\n'.join(pos) + '\nROWS')
# (5) the comment of report_record_line_cases
old = """  # seven or eight marks, which ends no run; and an image split after a
  # backtick line whose info string holds a backtick, which the tracker fences
  # and a renderer does not, since a run never ends at a fenced line."""
new = old + """ Round 17's
  # members follow (O-018 reopened, O-024): inside a finding the grammar is
  # narrowed further, so a `<` that may open an autolink (a digit or a symbol an
  # email address may begin with), an inline link's destination or title, or a
  # full reference link's label, holding a backtick or not ending on its line,
  # a code fence that may be inside a list item, and a link reference
  # definition, its label on one line or across lines, are each refused by
  # name; so are the stated consequences (`c <= d`, a fence indented under a
  # list item, a definition line)."""
block(T, t, old, new)
block(T, t, '  local spec report l tag body want heading sevs r1 low\n', '  local spec report l tag body want heading sevs r1 low tail t0\n')
open(out_dir + '/tgc-1.pairs', 'w', encoding='utf-8').write(''.join(t))

g = []
# (a) the manifest pass end to end: an autolink, a destination holding a backtick, a fence after a list marker
old = """             $'\\n```a`b\\n\\n![x\\ny](u)Severity: data-loss\\n```|quoted content carries a Severity line'; do"""
new = """             $'\\n```a`b\\n\\n![x\\ny](u)Severity: data-loss\\n```|quoted content carries a Severity line' \\
             $'\\nNote <1`@a.b><br>Severity: data-loss, tick: `.|an autolink outside a code span in finding G-042' \\
             $'\\n[x](u`v)<br>Severity: data-loss, tick: `.|a backtick inside a link destination, title or label in finding G-042' \\
             $'- ```\\n  ### x\\n- **Severity**: data-loss|a code fence that may be inside a list item in finding G-042'; do"""
block(G, g, old, new)
# (b) a definition hiding the manifest tier, end to end
old = """  # O-019: a field line under a sub-heading of the manifest finding is read, so
  # the CLEARED completion is refused on the manifest tier itself."""
new = """  # Round 17 (O-024): a link reference definition renders nothing yet carries
  # a field line, so it is refused by name inside a finding at completion.
  printf '# Prior review\\n\\n### Finding G-042\\n- **Class:** tier-binding\\n\\n[a]: /u %s\\n    - **Severity:** minor\\n    - x%s\\n' "'" "'" > "$manifest"
  for l in C en_US.UTF-8; do
    run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$report"
    assert_contains "$OUT" 'a link reference definition in finding G-042' \\
      "AC-009: a CLEARED completion over a manifest tier hidden in a link reference definition was not refused under LANG=$l (round 17, O-024)"
  done
""" + old
block(G, g, old, new)
# (c) the canonical pass end to end: an autolink and a title holding a backtick
old = """             '- **Severity:** minor\\n\\n![x\\n####### y](u)Severity: data-loss|a Severity line this grammar cannot read in finding G-050'; do"""
new = """             '- **Severity:** minor\\n\\n![x\\n####### y](u)Severity: data-loss|a Severity line this grammar cannot read in finding G-050' \\
             '- **Severity:** minor\\n\\nNote <1`@a.b><pre>Severity: data-loss</pre>`|an autolink outside a code span in finding G-050' \\
             '- **Severity:** minor\\n\\n[x](u "`")<br>Severity: data-loss, tick: `.|a backtick inside a link destination, title or label in finding G-050'; do"""
block(G, g, old, new)
# (d) the round-17 combined case: a definition and a fence a list item opens, after every field, end to end
old = """  # A title and a late Timestamp let a CLEARED round seal over a blocking
  # finding it never counted (O-020); the switch is refused at completion."""
new = """  # Round 17 (O-024): after every field of a canonical finding, a definition
  # carries the minor tier no renderer shows and a fence a list item opens
  # hides the line the passes read as closing the finding, so the data-loss
  # item after it fell outside every finding; both are refused at completion.
  tail=$'\\n[a]: /u \\'\\n    - **Severity:** minor\\n    - x\\'\\n\\n- ```\\n  ### x\\n- **Severity**: data-loss\\n'
  record_line_report "$res" 1 CLEARED 0 1 '### Finding G-050' tier-binding new '' |
    TAIL="$tail" awk 'index($0, "### Held up") == 1 {printf "%s", ENVIRON["TAIL"]} {print}' > "$SANDBOX/record-lines-o024.md"
  for l in C en_US.UTF-8; do
    run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$SANDBOX/record-lines-o024.md"
    assert_contains "$OUT" 'a link reference definition in finding G-050' \\
      "AC-009: a CLEARED completion over a tier hidden in a link reference definition was not refused under LANG=$l (round 17, O-024)"
    assert_contains "$OUT" 'a code fence that may be inside a list item in finding G-050' \\
      "AC-009: a CLEARED completion over a finding a list-item fence closed early was not refused under LANG=$l (round 17, O-024)"
  done
""" + old
block(G, g, old, new)
# (e) the comment of round_record_line_cases
old = """  # placed with 2.4's escapes, an image split by a line of seven marks, and an
  # image after a backtick line the tracker fences and a renderer does not."""
new = """  # placed with 2.4's escapes, an image split by a line of seven marks, and an
  # image after a backtick line the tracker fences and a renderer does not.
  # Round 17's follow (O-018, O-024): a `<` that may open an autolink, a link
  # destination holding a backtick, and a fence after a list marker."""
block(G, g, old, new)
block(G, g, 'round_record_line_cases() {\n  local spec cli res manifest report l row\n', 'round_record_line_cases() {\n  local spec cli res manifest report l row tail\n')
open(out_dir + '/tsg-1.pairs', 'w', encoding='utf-8').write(''.join(g))
print('tgc blocks', len(t), 'tsg blocks', len(g))
