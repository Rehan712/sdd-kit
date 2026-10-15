# Builds r17-edits/tgc-1.pairs and tsg-1.pairs (session 17): the fixtures for round 16's O-018 (narrowed grammar,
# CommonMark code spans, runs past tracker fences), O-022 (one to six marks) and the recorded consequence that raw
# HTML inside a finding is refused. Every OLD block is taken verbatim from the current file and must match exactly
# once (lit.pl checks). Run from the worktree root: python3 -I <this> <out-dir>
import sys
out = sys.argv[1]
G = open('tests/test-gate-contracts.sh', encoding='utf-8').read()
S = open('tests/test-spec-gate.sh', encoding='utf-8').read()

def block(old, new, src):
    assert src.count(old) == 1, ('OLD not unique', src.count(old), old[:90])
    return '@@OLD\n' + old + '\n@@NEW\n' + new + '\n@@END\n'

def row_line(src, prefix):
    i = src.index('\n' + prefix) + 1
    j = src.index('\n', i)
    return src[i:j]

tg = []
# --- 1. The plausible-manifest positives: the rows that carry raw HTML inside the finding move to a refusal table.
narrow_tags = ['severity-then-pre-block', 'severity-then-comment', 'severity-then-div', 'severity-then-details',
               'severity-then-closing-tag', 'wrapped-tag-prose', 'fenced-tag-example', 'heading-then-attribute-line',
               'br-prose', 'quoted-heading-then-attribute-line', 'span-in-prose', 'blank-line-ends-run']
start = G.index("  # Real and plausible manifests parse (R2-F3)")
end = G.index("SHAPES\n", G.index("code-span-word-before-label|### Finding O-017")) + len("SHAPES")
old = G[start:end]
moved = []
lines = old.split('\n')
kept = []
for ln in lines:
    tag = ln.split('|', 1)[0]
    if tag in narrow_tags and '|### Finding O-017' in ln:
        moved.append(ln)
    else:
        kept.append(ln)
assert len(moved) == len(narrow_tags), (len(moved), narrow_tags)
new = '\n'.join(kept)
new = new.replace("""  # has nothing to refuse.
  tier_round_fixture""", """  # has nothing to refuse. Markup inside a finding is written as code, between
  # backticks (round 16, O-018): a tag in a code span, an escaped `<`, a `<`
  # that opens nothing, a no-break-space line and a link that wraps parse.
  tier_round_fixture""")
assert new.count("has nothing to refuse. Markup inside a finding") == 1
new = new.replace("""code-span-word-before-label|### Finding O-017\\n- **Class:** harness-locale-decoding\\n- **Severity:** wrong-result\\n\\n- `foo` Severity: unchanged.\\n
SHAPES""", """code-span-word-before-label|### Finding O-017\\n- **Class:** harness-locale-decoding\\n- **Severity:** wrong-result\\n\\n- `foo` Severity: unchanged.\\n
code-span-tags-prose|### Finding O-017\\n- **Class:** harness-locale-decoding\\n- **Severity:** wrong-result\\n- The `<br>`, `<div>`, `</p>` and `<!-- x -->` spellings are quoted as code.\\n
escaped-lt-prose|### Finding O-017\\n- **Class:** harness-locale-decoding\\n- **Severity:** wrong-result\\n- An escaped \\\\<b> stays text, and a < b comparison too.\\n
long-span-prose|### Finding O-017\\n- **Class:** harness-locale-decoding\\n- **Severity:** wrong-result\\n- The ``a `b` c`` span holds backticks.\\n
nbsp-line-prose|### Finding O-017\\n- **Class:** harness-locale-decoding\\n- **Severity:** wrong-result\\n\\nA line\\n\\302\\240\\nafter a no-break space line.\\n
SHAPES
  # Raw HTML or an autolink inside a manifest finding, outside every code span,
  # is refused by name, so the rows above that carried it are refusals now
  # (round 16, O-018; the user's decision of 2026-10-08): a block a renderer
  # starts after a field line, a tag that wraps, a fenced or quoted tag, a
  # tag inside prose.
  while IFS='|' read -r label shape; do
    printf '%b' "$shape" > "$spec/notes/verification/reports/opponent-findings-review.md"
    run_rc 3 bash -c '. "$1"; vf_reports "$2" opponent "$3" "$4"' _ \\
      "$SCRIPTS/verification-lib.sh" "$report" "$SANDBOX/manifest-locale.nul" "$spec"
    assert_contains "$OUT" 'raw HTML outside a code span in finding O-017' \\
      "AC-012: a manifest finding carrying raw HTML ($label) was not refused by name (round 16, O-018)"
  done <<'SHAPES'
""" + '\n'.join(moved) + """
SHAPES""")
assert new.count("raw HTML outside a code span in finding O-017") == 1
tg.append(block(old, new, G))

# --- 2. The manifest member rows of report_record_line_cases: round 16's members.
anchor = "checkbox-then-tag|### Finding G-042\\n- **Class:** tier-binding\\n- **Severity:** minor\\n- [x] <b>Severity:</b> data-loss\\n|a second Severity line in finding G-042: - [x] <b>Severity:</b> data-loss\nROWS"
assert G.count(anchor) == 1
M = "### Finding G-042\\n- **Class:** tier-binding\\n- **Severity:** minor\\n\\n"
H = 'raw HTML outside a code span in finding G-042'
mrows = [
 ('pre-in-prose', 'Note<pre>Severity: data-loss</pre>', H),
 ('hgroup-in-prose', 'Note<hgroup>Severity: data-loss</hgroup>', H),
 ('listing-in-prose', 'Note<listing>Severity: data-loss</listing>', H),
 ('xmp-in-prose', 'Note<xmp>Severity: data-loss</xmp>', H),
 ('plaintext-in-prose', 'Note<plaintext>Severity: data-loss', H),
 ('br-in-link-text', '[Note<br>](u)Severity: data-loss', H),
 ('p-in-link-text', '[Note<p>](u)Severity: data-loss', H),
 ('tag-holding-backtick', '<i title="`"></i>Note<br>Severity: data-loss, tick: `.', H),
 ('autolink-holding-backtick', '<http://a.b/`>Note<br>Severity: data-loss, tick: `.', H),
 ('autolink-before-label', '<https://x.example/a>Severity: data-loss', H),
 ('tag-split-by-form-feed', '<b title="\\n\\f\\nx">Severity: data-loss</b>', H),
 ('tag-split-by-seven-marks', '<b title="\\n####### x">Severity: data-loss</b>', H),
 ('html-block-heading', '<div>\\n<b title="\\n# x">Severity: data-loss</b>\\n</div>', H),
 ('escaped-backtick-then-br', '\\\\`<br>Severity: data-loss', H),
 ('lone-carriage-return', 'Note\\r\\rSeverity: data-loss', 'a carriage return inside a line in finding G-042'),
 ('form-feed-in-text', 'Note\\fSeverity: data-loss', 'a form feed or vertical tab in finding G-042'),
 ('vertical-tab-in-text', 'Note\\vSeverity: data-loss', 'a form feed or vertical tab in finding G-042'),
 ('escaped-backslash-code-span', '[\\\\\\\\`]`](u)Severity: data-loss', 'a second Severity line in finding G-042'),
 ('escaped-first-backtick', '[\\\\``]`](u)Severity: data-loss', 'a second Severity line in finding G-042'),
 ('image-split-by-seven-marks', '![x\\n####### y](u)Severity: data-loss', 'a second Severity line in finding G-042'),
 ('image-split-by-eight-marks-quoted', '> ![x\\n> ######## y](u)Severity: data-loss', 'quoted content carries a Severity line'),
 ('image-after-backtick-info-fence', '\\140\\140\\140a\\140b\\n\\n![x\\ny](u)Severity: data-loss\\n\\140\\140\\140', 'quoted content carries a Severity line'),
]
newrows = ''.join('%s|%s%s\\n|%s\n' % (t, M, b, w) for t, b, w in mrows)
tg.append(block(anchor, anchor[:-len('ROWS')] + newrows + 'ROWS', G))
old_c = """  # bracket, and after a rendered line start (a br tag in four spellings, a p
  # or div tag inside the line, a br inside a Where value)."""
new_c = """  # bracket, and after a rendered line start (a br tag in four spellings, a p
  # or div tag inside the line, a br inside a Where value). Round 16's members
  # follow (O-018 reopened, O-022): inside a finding the grammar is narrowed, so
  # raw HTML or an autolink outside every code span is refused by name (a tag
  # HTML renders as a block, a br in link text, a tag or autolink holding a
  # backtick, a tag split by a form feed or a line of seven marks, a heading
  # inside an HTML block, an escaped backtick before a tag), and so are a
  # carriage return inside a line, a form feed and a vertical tab; a code span
  # placed by 6.1 with 2.4's escapes taken in pairs; an image split by a line of
  # seven or eight marks, which ends no run; and an image split after a
  # backtick line whose info string holds a backtick, which the tracker fences
  # and a renderer does not, since a run never ends at a fenced line."""
tg.append(block(old_c, new_c, G))

# --- 3. The canonical second-tier rows: round 16's members in the canonical pass.
anchor3 = "paragraph-zero-one|- **Severity:** minor\\n\\nText\\n01. <b\\ntitle=\"x\">Severity: data-loss</b>|a Severity line this grammar cannot read in finding G-050\n"
assert G.count(anchor3) == 1
tail_start = G.index(anchor3) + len(anchor3)
tail_end = G.index("ROWS\n", tail_start)
old3 = G[G.index(anchor3):tail_end + len("ROWS")]
K = '- **Severity:** minor\\n\\n'
HK = 'raw HTML outside a code span in finding G-050'
krows = [
 ('pre-in-prose', 'Note<pre>Severity: data-loss</pre>', HK),
 ('br-in-link-text', '[Note<br>](u)Severity: data-loss', HK),
 ('tag-holding-backtick', '<i title="`"></i>Note<br>Severity: data-loss, tick: `.', HK),
 ('tag-split-by-vertical-tab', '<b title="\\n\\v\\nx">Severity: data-loss</b>', HK),
 ('tag-split-by-eight-marks-quoted', '> <b title="\\n> ######## y">Severity: data-loss</b>', HK),
 ('lone-carriage-return', 'Note\\r\\rSeverity: data-loss', 'a carriage return inside a line in finding G-050'),
 ('form-feed-in-text', 'Note\\fSeverity: data-loss', 'a form feed or vertical tab in finding G-050'),
 ('escaped-backslash-code-span', '[\\\\\\\\`]`](u)Severity: data-loss', 'a Severity line this grammar cannot read in finding G-050'),
 ('escaped-first-backtick', '[\\\\``]`](u)Severity: data-loss', 'a Severity line this grammar cannot read in finding G-050'),
 ('image-split-by-seven-marks', '![x\\n####### y](u)Severity: data-loss', 'a Severity line this grammar cannot read in finding G-050'),
 ('image-after-backtick-info-fence', '\\140\\140\\140a\\140b\\n\\n![x\\ny](u)Severity: data-loss\\n\\140\\140\\140', 'quoted content carries a Severity line'),
]
new3 = old3[:-len('ROWS')] + ''.join('%s|%s%s|%s\n' % (t, K, b, w) for t, b, w in krows) + 'ROWS'
tg.append(block(old3, new3, G))

# --- 4. The Where value: a br and p tags with no tier are raw HTML now; a carriage return is refused; a code span parses.
old4 = """    record_round 1 CHALLENGED 1 0 '### Finding G-050' dup-binding new '- **Severity:** data-loss' |
      sed 's#^- \\*\\*Where:\\*\\* scripts/run.sh:9$#- **Where:** a.sh:1<br>b.sh:2 and <p>c.sh:3#' > "$report"
    run_rc 0 record_line_vf "$l" "$report" "$spec"
    assert_not_contains "$OUT" 'report recovery' "AC-012: a Where value with br and p tags and no tier was refused under LANG=$l (O-018)"
  done"""
new4 = """    record_round 1 CHALLENGED 1 0 '### Finding G-050' dup-binding new '- **Severity:** data-loss' |
      sed 's#^- \\*\\*Where:\\*\\* scripts/run.sh:9$#- **Where:** a.sh:1<br>b.sh:2 and <p>c.sh:3#' > "$report"
    run_rc 3 record_line_vf "$l" "$report" "$spec"
    assert_contains "$OUT" 'raw HTML outside a code span in finding G-050' \\
      "AC-012: a Where value with br and p tags was not refused as raw HTML under LANG=$l (round 16, O-018)"
    record_round 1 CHALLENGED 1 0 '### Finding G-050' dup-binding new '- **Severity:** data-loss' |
      sed "s#^- \\\\*\\\\*Where:\\\\*\\\\* scripts/run.sh:9\\$#- **Where:** a.sh:1$(printf '\\r')- **Severity:** minor#" > "$report"
    run_rc 3 record_line_vf "$l" "$report" "$spec"
    assert_contains "$OUT" 'a carriage return inside a line in finding G-050' \\
      "AC-012: a Where value holding a carriage return was not refused by name under LANG=$l (round 16, O-018)"
    record_round 1 CHALLENGED 1 0 '### Finding G-050' dup-binding new '- **Severity:** data-loss' |
      sed 's#^- \\*\\*Where:\\*\\* scripts/run.sh:9$#- **Where:** a.sh:1 (the `<br>` tag is quoted as code)#' > "$report"
    run_rc 0 record_line_vf "$l" "$report" "$spec"
    assert_not_contains "$OUT" 'report recovery' "AC-012: a Where value quoting a tag as code was refused under LANG=$l (round 16, O-018)"
  done"""
tg.append(block(old4, new4, G))

# --- 5. O-021's blocks after a field line: the HTML ones are raw HTML inside a finding now; the fence stays.
old5 = """  # A field line followed directly by a block a renderer starts there holds
  # its item alone (round 14, O-021): every HTML block but the seventh kind,
  # condition 6's block-level tags included, and a fence of three or more
  # backticks may interrupt the field's paragraph, so the round parses.
  while IFS='|' read -r tag sevs; do
    record_round 1 CHALLENGED 1 0 '### Finding G-050' dup-binding new "$sevs" > "$report"
    for l in C en_US.UTF-8; do
      run_rc 0 record_line_vf "$l" "$report" "$spec"
      assert_not_contains "$OUT" 'report recovery' "AC-012: a Severity line followed by a $tag was refused under LANG=$l (O-021)"
    done
  done <<'ROWS'
div-block|- **Severity:** data-loss\\n<div>\\nnote\\n</div>\\n
details-block|- **Severity:** data-loss\\n<details>\\nx\\n</details>\\n
closing-tag|- **Severity:** data-loss\\n</details>\\n
four-backtick-fence|- **Severity:** data-loss\\n````text\\nplain output\\n````\\n
ROWS"""
new5 = """  # A field line followed directly by a block a renderer starts there holds
  # its item alone (round 14, O-021): a fence of three or more backticks, or of
  # tildes, may interrupt the field's paragraph, so the round parses. An HTML
  # block there is raw HTML inside a finding, refused by name (round 16, O-018).
  while IFS='|' read -r tag sevs; do
    record_round 1 CHALLENGED 1 0 '### Finding G-050' dup-binding new "$sevs" > "$report"
    for l in C en_US.UTF-8; do
      run_rc 0 record_line_vf "$l" "$report" "$spec"
      assert_not_contains "$OUT" 'report recovery' "AC-012: a Severity line followed by a $tag was refused under LANG=$l (O-021)"
    done
  done <<'ROWS'
four-backtick-fence|- **Severity:** data-loss\\n````text\\nplain output\\n````\\n
tilde-fence|- **Severity:** data-loss\\n~~~\\nplain output\\n~~~\\n
ROWS
  while IFS='|' read -r tag sevs; do
    record_round 1 CHALLENGED 1 0 '### Finding G-050' dup-binding new "$sevs" > "$report"
    for l in C en_US.UTF-8; do
      run_rc 3 record_line_vf "$l" "$report" "$spec"
      assert_contains "$OUT" 'raw HTML outside a code span in finding G-050' \\
        "AC-012: a Severity line followed by a $tag was not refused as raw HTML under LANG=$l (round 16, O-018)"
    done
  done <<'ROWS'
div-block|- **Severity:** data-loss\\n<div>\\nnote\\n</div>\\n
details-block|- **Severity:** data-loss\\n<details>\\nx\\n</details>\\n
closing-tag|- **Severity:** data-loss\\n</details>\\n
ROWS"""
tg.append(block(old5, new5, G))

# --- 6. The canonical positives: the rows with raw HTML move to a refusal table; new positives join.
cnarrow = ['a-empty-comment-then-prose', 'a-wrapped-tag-prose', 'a-fenced-tag-example', 'a-heading-then-attribute-line',
           'a-br-prose', 'a-quoted-heading-then-attribute-line', 'a-span-in-prose', 'a-blank-line-ends-run']
s6 = G.index("a-notes-sub-heading|### Finding G-042|#### Notes")
e6 = G.index("ROWS\n", s6) + len("ROWS")
old6 = G[s6:e6]
rows6 = old6.split('\n')
keep6 = [r for r in rows6 if r.split('|', 1)[0] not in cnarrow]
mv6 = [r for r in rows6 if r.split('|', 1)[0] in cnarrow]
assert len(mv6) == len(cnarrow), len(mv6)
extra6 = [
 'a-code-span-tags|### Finding G-042|  - The `<br>`, `<div>`, `</p>` and `<!-- x -->` spellings are quoted as code.\\n',
 'a-escaped-lt|### Finding G-042|  - An escaped \\\\<b> stays text, and a < b comparison too.\\n',
 'a-long-span|### Finding G-042|  - The ``a `b` c`` span holds backticks.\\n',
 'a-nbsp-line|### Finding G-042|\\nA line\\n\\302\\240\\nafter a no-break space line.\\n\\n',
]
new6 = '\n'.join(keep6[:-1] + extra6 + ['ROWS',
 "  # Raw HTML or an autolink inside a canonical finding, outside every code",
 "  # span, is refused by name (round 16, O-018; the user's decision of",
 "  # 2026-10-08), so the rows that carried it are refusals now.",
 "  while IFS='|' read -r tag heading body; do",
 "    record_round 1 CHALLENGED 1 0 \"$heading\" tier-binding new '- **Severity:** data-loss' \"$body\" > \"$report\"",
 "    for l in C en_US.UTF-8; do",
 "      run_rc 3 record_line_vf \"$l\" \"$report\" \"$spec\"",
 "      assert_contains \"$OUT\" 'raw HTML outside a code span in finding G-042' \\",
 "        \"AC-012: a canonical finding with $tag was not refused as raw HTML under LANG=$l (round 16, O-018)\"",
 "    done",
 "  done <<'ROWS'"] + mv6 + ['ROWS'])
assert keep6[-1] == 'ROWS'
tg.append(block(old6, new6, G))

ts = []
# --- tsg 1. End to end, the manifest pass: one spelling per mechanism of round 16.
old7 = """             '- [`]`](u)Severity: data-loss|a second Severity line in finding G-042' \\
             '- Note<br>Severity: data-loss|a second Severity line in finding G-042'; do"""
new7 = """             '- [`]`](u)Severity: data-loss|a second Severity line in finding G-042' \\
             '- Note<br>Severity: data-loss|a second Severity line in finding G-042' \\
             '- Note<pre>Severity: data-loss</pre>|raw HTML outside a code span in finding G-042' \\
             $'- Note\\r\\rSeverity: data-loss|a carriage return inside a line in finding G-042' \\
             $'- Note\\fSeverity: data-loss|a form feed or vertical tab in finding G-042' \\
             '- [\\\\`]`](u)Severity: data-loss|a second Severity line in finding G-042' \\
             $'\\n![x\\n####### y](u)Severity: data-loss|a second Severity line in finding G-042' \\
             $'\\n```a`b\\n\\n![x\\ny](u)Severity: data-loss\\n```|quoted content carries a Severity line'; do"""
ts.append(block(old7, new7, S))
old7c = """  # more than its line. Round 15's mechanisms follow, one spelling each
  # (T030o47): a paragraph boundary the reader misses (a sibling ordered item)
  # or invents (an indented list marker), a code span that holds a bracket, and
  # a rendered line start (a br tag)."""
new7c = """  # more than its line. Round 15's mechanisms follow, one spelling each
  # (T030o47): a paragraph boundary the reader misses (a sibling ordered item)
  # or invents (an indented list marker), a code span that holds a bracket, and
  # a rendered line start (a br tag). Round 16's follow (O-018, O-022): raw HTML
  # inside a finding, a carriage return inside a line, a form feed, a code span
  # placed with 2.4's escapes, an image split by a line of seven marks, and an
  # image after a backtick line the tracker fences and a renderer does not."""
ts.append(block(old7c, new7c, S))
# --- tsg 2. End to end, the canonical pass.
old8 = """             '- **Severity:** minor\\n\\nNote\\n> <b\\n> title="x">Severity: data-loss</b>|quoted content carries a Severity line'; do"""
new8 = """             '- **Severity:** minor\\n\\nNote\\n> <b\\n> title="x">Severity: data-loss</b>|quoted content carries a Severity line' \\
             '- **Severity:** minor\\n\\nNote<pre>Severity: data-loss</pre>|raw HTML outside a code span in finding G-050' \\
             '- **Severity:** minor\\n\\nNote\\r\\rSeverity: data-loss|a carriage return inside a line in finding G-050' \\
             '- **Severity:** minor\\n\\n![x\\n####### y](u)Severity: data-loss|a Severity line this grammar cannot read in finding G-050'; do"""
ts.append(block(old8, new8, S))
# --- tsg 3. The completing round 2: an HTML block after its field line is raw HTML now; a fence ends the item.
old9 = """  # The round that completes carries a block-level HTML block directly after its
  # Severity line, which ends that line's item (O-021).
  record_line_report "$res" 2 CHALLENGED 1 0 '### Finding G-042' tier-binding open '- **Severity:** data-loss\\n<details>\\nx\\n</details>\\n' > "$report"
  run_rc 0 bash "$cli" round "$spec" opponent --complete "$report\""""
new9 = """  # An HTML block directly after a Severity line is raw HTML inside a finding,
  # refused by name at completion (round 16, O-018); the round that completes
  # carries a fence there, which ends that line's item (O-021).
  record_line_report "$res" 2 CHALLENGED 1 0 '### Finding G-042' tier-binding open '- **Severity:** data-loss\\n<details>\\nx\\n</details>\\n' > "$report"
  run_rc 3 bash "$cli" round "$spec" opponent --complete "$report"
  assert_contains "$OUT" 'raw HTML outside a code span in finding G-042' \\
    'AC-009: a round 2 with an HTML block after a field line was not refused as raw HTML (round 16, O-018)'
  record_line_report "$res" 2 CHALLENGED 1 0 '### Finding G-042' tier-binding open '- **Severity:** data-loss\\n````text\\nplain output\\n````\\n' > "$report"
  run_rc 0 bash "$cli" round "$spec" opponent --complete "$report\""""
ts.append(block(old9, new9, S))

open(out + '/tgc-1.pairs', 'w', encoding='utf-8').write(''.join(tg))
open(out + '/tsg-1.pairs', 'w', encoding='utf-8').write(''.join(ts))
print('tgc-1.pairs: %d blocks; tsg-1.pairs: %d blocks' % (len(tg), len(ts)))
