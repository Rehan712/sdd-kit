#!/usr/bin/env python3
# Builds r15-mutations.sh (matrix v4) from r14-mutations.sh (v3): the header, the scratch directory, the paragraph
# section rewritten for T030o47's paragraph reader, and a section for every other guard T030o47 adds.
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding='utf-8').read()

def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (old[:80], t.count(old))
    t = t.replace(old, new)

head_old = t[:t.index('# Harness: t030o43-mutations.sh, as v2.\n')]
rep(head_old, '''#!/usr/bin/env bash
# T030o47 mutation matrix v4, 2026-10-07 (session 15), from r14-mutations.sh (v3, kept with its runs): every guard of
# T030o44, T030o45 and T030o46 as v3 judged them (with the session-15 corrections of L18, N02 and N32), the paragraph
# rows rewritten for T030o47's paragraph reader (every line of a run a candidate start; the run ends only at a blank
# line, a fenced line or an ATX heading of at most three spaces, read without block-quote markers), and a row for
# every other guard T030o47 adds (Decisions 2026-10-07, session 15): the code-span reading (its call, its two
# renderings, the letters it keeps, the escape and the closer), the reading after a rendered line start (its call,
# the closing-tag branch, the br and block-level names, the plain and the code-span reading of the text after it),
# and the field-value reading of the canonical pass with its two conjuncts. Each in a standalone copy built from the
# live manifest enumeration, every judge under a TMPDIR ending in `/`.
''')
rep('# Usage: bash t030o44-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n] [ONLY=id,id...]\n',
    '# Usage: bash r15-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n] [ONLY=id,id...]\n')
rep('R="$SP/r14-matrix-$si"', 'R="$SP/r15-matrix-$si"')

start = t.index("say '== the paragraph step and the paragraph checks (T030o46, O-018)'\n")
end = t.index("say '== the blocks that end a field item (T030o46, O-021)'\n")
old_section = t[start:end]
# keep the call-site rows of v3 (their literals are unchanged), drop the rows on the old paragraph functions
keep = []
for block in old_section.split('\nrow ')[1:]:
    rid = block.split(' ', 1)[0]
    if rid in ('P13', 'P13e', 'P14', 'P14e', 'P15', 'P16', 'P16e'):
        keep.append('row ' + block.split('\n# ')[0].rstrip('\n'))
new_section = r"""say '== the paragraph step and the paragraph checks (T030o46, T030o47; O-018)'
PL='  if (fenced || t ~ /^[[:space:]]*$/ || q ~ /^ ? ? ?#+([ \t]|$)/) {vf_run_n'
row P10 kill "$LR paragraph-block-quote $LS" "$GC" "$RL" "$VL" '  t = s; sub(/^[ \t]*(>[ \t]*)*/, "", t)' '  t = s; sub(/^[ \t]*/, "", t)'
row P11 over 'a plausible manifest (fenced-tag-example) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" "$PL" '  if (t ~ /^[[:space:]]*$/ || q ~ /^ ? ? ?#+([ \t]|$)/) {vf_run_n'
row P11c over 'a canonical finding with a-fenced-tag-example was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "$PL" '  if (t ~ /^[[:space:]]*$/ || q ~ /^ ? ? ?#+([ \t]|$)/) {vf_run_n'
row P11b over 'a plausible manifest (blank-line-ends-run) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" "$PL" '  if (fenced || q ~ /^ ? ? ?#+([ \t]|$)/) {vf_run_n'
row P11bc over 'a canonical finding with a-blank-line-ends-run was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "$PL" '  if (fenced || q ~ /^ ? ? ?#+([ \t]|$)/) {vf_run_n'
row P12 over 'a plausible manifest (heading-then-attribute-line) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" "$PL" '  if (fenced || t ~ /^[[:space:]]*$/) {vf_run_n'
row P12c over 'a canonical finding with a-heading-then-attribute-line was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "$PL" '  if (fenced || t ~ /^[[:space:]]*$/) {vf_run_n'
row P12i kill "$LR paragraph-indented-heading-marker $LS" "$GC" "$RL" \
  "$VL" "$PL" '  if (fenced || t ~ /^[[:space:]]*$/ || q ~ /^[ \t]*#+([ \t]|$)/) {vf_run_n'
row P12q over 'a plausible manifest (quoted-heading-then-attribute-line) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  q = s; while (match(q, /^ ? ? ?>[ ]?/)) q = substr(q, RLENGTH + 1)' '  q = s'
row P12qc over 'a canonical finding with a-quoted-heading-then-attribute-line was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '  q = s; while (match(q, /^ ? ? ?>[ ]?/)) q = substr(q, RLENGTH + 1)' '  q = s'
""" + '\n'.join(keep) + r"""
row P17 over 'expected exit 0, got 3: record_line_vf C' "$GC" "$RL" "$VL" '    if (vf_run_own[k] != "") continue'$'\n' ''
row P18 equiv '' "$GC" "$RL" "$VL" '{vf_run_refused = 1; return' '{return'
# P18 argued: without it a run already refused is refused again at each later line, which adds a message and
# changes no verdict.
row P19 equiv '' "$GC" "$RL" "$VL" '  if (!vf_para_cont || vf_run_refused) return ""' '  if (vf_run_refused) return ""'
# P19 argued: on a line that opens a run no earlier candidate exists (the loop runs below vf_run_n, which is 1), so
# the guard only saves the loop.
row P20 equiv '' "$GC" "$RL" "$VL" '  for (k = 1; k < vf_run_n; k++) {' '  for (k = 1; k <= vf_run_n; k++) {'
# P20 argued: the candidate the current line opens holds that line without its indentation and block-quote markers,
# which the word reader skips as characters that are not letters or digits, so its label is the line's own; a line
# with a label is skipped, and one without yields none.
row P21 equiv '' "$GC" "$RL" "$VL" '  if (FNR == 1) vf_run_n = vf_run_refused = 0'$'\n' ''
# P21 argued: without it a run continues into the next file the pass reads, which only adds candidates, so it can
# only add a refusal; every manifest and report a fixture writes begins with an ATX heading, which ends a run anyway.
row P22 kill "$LR paragraph-ordered-sibling $LS" "$GC" "$RL" "$VL" 'vf_run_text[k] = vf_run_text[k] " " t' 'vf_run_text[k] = vf_run_text[k]'
row P23 kill "$LR paragraph-ordered-sibling $LS" "$GC" "$RL" \
  "$VL" '  vf_run_n++; vf_run_text[vf_run_n] = t; vf_run_line[vf_run_n] = s; vf_run_own[vf_run_n] = "?"' \
  '  if (!vf_run_n) {vf_run_n++; vf_run_text[vf_run_n] = t; vf_run_line[vf_run_n] = s; vf_run_own[vf_run_n] = "?"}'

"""
t = t[:start] + new_section + t[end:]

x_section = r"""say '== the code-span reading, the reading after a rendered line start, the field-value reading (T030o47, O-018)'
row X01 kill "$LR code-span-in-link $LS" "$GC" "$RL" "$VL" '  c = index(s, sprintf("%c", 96)) ? vf_label_inert(s) : s' '  c = s'
row X02 kill "$LR code-span-in-link $LS" "$GC" "$RL" "$VL" '  if (c != s) {' '  if (0) {'
row X03 kill "$LR code-span-then-soft-hyphen $LS" "$GC" "$RL" "$VL" '    if (w == "") w = vf_label_word(vf_label_render(c, 1), labels)'$'\n' ''
row X04 kill "$LR br-in-prose $LS" "$GC" "$RL" "$VL" '  return index(c, "<") ? vf_label_breaks(s, c, labels) : ""' '  return ""'
row X05 kill "$LR closing-p-inside-line $LS" "$GC" "$RL" "$VL" ' && !match(rest, /^<\/[A-Za-z][A-Za-z0-9-]*[ \t]*>/)) continue' ') continue'
row X06a kill "$LR p-inside-line $LS" "$GC" "$RL" "$VL" '    if (nm != "br" && !index(vf_lbl_blocks, " " nm " ")) continue' '    if (nm != "br") continue'
row X06b kill "$LR br-in-prose $LS" "$GC" "$RL" "$VL" 'if (nm != "br" && !index(vf_lbl_blocks' 'if (!index(vf_lbl_blocks'
row X06c over 'a plausible manifest (span-in-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '    if (nm != "br" && !index(vf_lbl_blocks, " " nm " ")) continue'$'\n' ''
row X07 kill "$LR br-then-code-span $LS" "$GC" "$RL" "$VL" '    if (w == "") w = vf_label_word(vf_label_render(substr(c, p + L), 0), labels)'$'\n' ''
row X08 kill "$LR br-then-soft-hyphen $LS" "$GC" "$RL" "$VL" '    w = vf_label_read(substr(s, p + L), labels)' '    w = ""'
row X09 kill 'a second tier written as br-in-where was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '      if (style=="canonical" && index($0, "<") && (lbl=vf_label_breaks(' '      if (0 && (lbl=vf_label_breaks('
row X10 kill "$F6" "$GC" "$RL" "$VL" '      if (style=="canonical" && index($0, "<") && (lbl=vf_label_breaks(' '      if (index($0, "<") && (lbl=vf_label_breaks('
row X11 equiv '' "$GC" "$RL" "$VL" ' && index($0, "<") && (lbl=vf_label_breaks(' ' && (lbl=vf_label_breaks('
# X11 argued: vf_label_breaks reads only after a tag, which needs a `<`, so on a line without one it returns ""
# whatever the conjunct; the conjunct saves the call.
row X12 kill "$LR heading-label $LS" "$GC" "$RL" "$VL" $'  w = vf_label_read(s, labels)\n  if (w != "") return w\n' $'  w = vf_label_read(s, labels)\n'
# X12, an argued equivalent until the session-16 probe killed it (r16-mutations-probe, rc 1 on this row alone): without
# the early return a line with no code span falls through to the reading after a rendered line start, which reads
# only after a tag, so the label the first readings found is lost; the heading-label rows judge it.
row X13 kill "$LR escaped-backtick-then-code-span $LS" "$GC" "$RL" "$VL" '    if (i > 1 && substr(s, i - 1, 1) == "\\") {out = out substr(s, 1, i + n - 1); s = substr(s, i + n); continue}'$'\n' ''
row X14 kill "$LR code-span-holding-a-backtick $LS" "$GC" "$RL" "$VL" '      if (RLENGTH == n) {k = off + RSTART; break}' '      if (1) {k = off + RSTART; break}'
row X15 over 'a plausible manifest (code-span-word-before-label) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 'f = f ((ch ~ /[A-Za-z0-9]/) ? ch : "\002")' 'f = f "\002"'
row X15c over 'a canonical finding with a-code-span-word-before-label was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" 'f = f ((ch ~ /[A-Za-z0-9]/) ? ch : "\002")' 'f = f "\002"'

"""
rep('row L17 kill "$LR second-tier-code-span-tag $LS" "$GC" "$RL" \\\n  "$VL" \'  return (w != "") ? w : vf_label_word(s, labels)\' \'  return w\'\n', 'row L17 kill "$LR second-tier-footnote-literal $LS" "$GC" "$RL" \\\n  "$VL" \'  return (w != "") ? w : vf_label_word(s, labels)\' \'  return w\'\n# L17 (session 16): run 1 of v4 (r16-mutations-run1-shard0) found its code-span-tag row read by T030o47\'s code-span\n# reading too, so the mutant survived; the row added by r16-edits/tgc-2.pairs, a tier behind an undefined footnote\n# reference that renderers show literally, is read by the reading as written alone (r16-fixtures-judge-2).\n')
rep('say "r14-mutations failures=$fails"\n', 'say "r15-mutations failures=$fails"\n')
anchor = 'say "== done shard $SHARD $(date -u +%H:%M:%SZ) rows=$rowi"\n'
rep(anchor, x_section + anchor)
open(dst, 'w', encoding='utf-8').write(t)
print('ok', len(keep), 'call-site rows kept')
