#!/usr/bin/env python3
# Builds r17-mutations.sh (matrix v5) from r15-mutations.sh (v4): the header, the scratch directory, the v4 rows
# whose literals T030o48 to T030o50 rewrote or made ambiguous, the v4 rows whose judging positive the narrowed grammar
# turned into a refusal (re-judged by a row it does not refuse, or re-argued), the paragraph rows replaced by rows on
# the run's new ends, and a section for every guard T030o48, T030o49 and T030o50 add (Decisions 2026-10-08).
# Usage: python3 -I <this> r15-mutations.sh r17-mutations.sh
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding='utf-8').read()

def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (old[:90], t.count(old))
    t = t.replace(old, new)

head_old = t[:t.index('# Harness: t030o43-mutations.sh, as v2.\n')]
rep(head_old, '''#!/usr/bin/env bash
# T030o48, T030o49 and T030o50 mutation matrix v5, 2026-10-08 (session 18), from r15-mutations.sh (v4, kept with its
# runs), built by r17-mutations-gen.py: every guard of T030o44 to T030o47 as v4 judged it, with the rows whose literals
# the repair rewrote or made ambiguous rewritten, the over-correction rows whose positive the narrowed grammar turned
# into a refusal re-judged by a positive it does not refuse (outside every finding, where it does not reach) or
# re-argued, the paragraph rows on the old run ends replaced, and a row for every guard the repair adds: the narrowed
# grammar (each condition of vf_narrow, the `<` class, and its call in each pass with their conjuncts), the code-span
# scan and the code-span reading (escapes, the closer, the carried states, the left-to-right tokenizer), the run's
# ends (a blank line, a heading of one to six marks, never a fenced line, the carried states reset), and each
# condition of vf_settled. Rows marked equiv are argued beside them. Each in a standalone copy built from the live
# manifest enumeration, every judge under a TMPDIR ending in `/`.
''')
rep('# Usage: bash r15-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n] [ONLY=id,id...]\n',
    '# Usage: bash r17-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n] [ONLY=id,id...]\n')
rep('R="$SP/r15-matrix-$si"', 'R="$SP/r17-matrix-$si"')

# L01b: its positive (a comment closer inside a finding) is raw HTML inside a finding now; outside every finding the
# label reader still decides whether a manifest line after a finding ID is a Severity line.
rep("row L01b over 'a canonical finding with a-empty-comment-then-prose was refused under LANG=C (O-018)' \"$GC\" \"$RL\" \\\n",
    "row L01b over 'a plausible manifest (outside-comment-closer) was refused (T030o43 review 2)' \"$GC\" \"$ML\" \\\n")
rep("""  \"$VL\" '{n = index(substr(rest, 3), \"-->\"); s = n ? substr(rest, n + 5) :' '{n = index(substr(rest, 5), \"-->\"); s = n ? substr(rest, n + 7) :'\n""",
    """  \"$VL\" '{n = index(substr(rest, 3), \"-->\"); s = n ? substr(rest, n + 5) :' '{n = index(substr(rest, 5), \"-->\"); s = n ? substr(rest, n + 7) :'
# L01b (v5): inside a finding a comment is raw HTML and refused by name (T030o48), so its row moved outside every
# finding: a manifest line after a finding ID whose label the comment closer decides (r17-edits/tgc-2.pairs).
""")
# P02: the escape gsub now also opens vf_settled_brackets, so the literal takes the line after it.
rep("""row P02 kill \"$LR escaped-bracket-alt $LS\" \"$GC\" \"$RL\" \"$VL\" '  gsub(/\\\\[][]/, \"\\003\", s)'$'\\n' ''""",
    """row P02 kill \"$LR escaped-bracket-alt $LS\" \"$GC\" \"$RL\" \"$VL\" '  gsub(/\\\\[][]/, \"\\003\", s)'$'\\n''  pos = 1' '  pos = 1'""")

# B05, B07, B14, B14c, B17: the HTML clauses of vf_block_start, whose positives are refusals by name now.
EQB = '''# %s argued (v5): inside a finding, where the field-item rule asks vf_block_start, every line this clause admits
# begins with `<` and a letter, `/`, `!` or `?` outside any code span, so it is refused by name as raw HTML outside a
# code span (T030o48) whatever the item rule reads; the clause decides only whether a second diagnostic names the item.
'''
for rid, diag in (('B05', "'a plausible manifest (severity-then-comment) was refused (T030o43 review 2)'"),
                  ('B07', "'a plausible manifest (severity-then-pre-block) was refused (T030o43 review 2)'"),
                  ('B14', "'a plausible manifest (severity-then-details) was refused (T030o43 review 2)'"),
                  ('B14c', "'a Severity line followed by a details-block was refused under LANG=C (O-021)'"),
                  ('B17', "'a plausible manifest (severity-then-closing-tag) was refused (T030o43 review 2)'")):
    i = t.index('row %s over %s ' % (rid, diag))
    j = t.index('\n', t.index('\n', i) + 1) + 1
    row = t[i:j]
    t = t[:i] + row.replace('row %s over %s ' % (rid, diag), "row %s equiv '' " % rid) + (EQB % rid) + t[j:]

# The paragraph section: the run's ends are new (T030o48, T030o49), so the rows on the old literal go.
start = t.index("PL='  if (fenced || t ~ /^[[:space:]]*$/ || q ~ /^ ? ? ?#+([ \\t]|$)/) {vf_run_n'\n")
end = t.index("row P13 kill ")
t = t[:start] + t[end:]
rep("""row P17 over 'expected exit 0, got 3: record_line_vf C' \"$GC\" \"$RL\" \"$VL\" '    if (vf_run_own[k] != \"\") continue'$'\\n' ''""",
    """row P17 over 'expected exit 0, got 3: record_line_vf C' \"$GC\" \"$RL\" \"$VL\" '    if (vf_run_own[k] != \"\") {vf_run_done[k] = 1; continue}'$'\\n' ''""")
rep("""row P21 equiv '' \"$GC\" \"$RL\" \"$VL\" '  if (FNR == 1) vf_run_n = vf_run_refused = 0'$'\\n' ''""",
    """row P21 equiv '' \"$GC\" \"$RL\" \"$VL\" '  if (FNR == 1) {vf_run_n = vf_run_refused = 0; vf_cm_states = \" 0\"}'$'\\n' ''""")
rep("""# P21 argued: without it a run continues into the next file the pass reads, which only adds candidates, so it can
# only add a refusal; every manifest and report a fixture writes begins with an ATX heading, which ends a run anyway.""",
    """# P21 argued: without it a run continues into the next file the pass reads, which only adds candidates, so it can
# only add a refusal; every manifest and report a fixture writes begins with an ATX heading, which ends a run anyway,
# and resets the carried code-span states with it (v5).""")

# The reading after a rendered line start: vf_settled_breaks repeats its filter, so the literals take the next line.
rep("""row X05 kill \"$LR closing-p-inside-line $LS\" \"$GC\" \"$RL\" \"$VL\" ' && !match(rest, /^<\\/[A-Za-z][A-Za-z0-9-]*[ \\t]*>/)) continue' ') continue'""",
    """row X05 kill \"$LR closing-p-inside-line $LS\" \"$GC\" \"$RL\" \\
  \"$VL\" ' && !match(rest, /^<\\/[A-Za-z][A-Za-z0-9-]*[ \\t]*>/)) continue'$'\\n''    L = RLENGTH; nm = tolower(substr(rest, 1, L)); sub(/^<\\/?/, \"\", nm); sub(/[^a-z0-9].*$/, \"\", nm)'$'\\n''    if (nm != \"br\" && !index(vf_lbl_blocks, \" \" nm \" \")) continue'$'\\n''    w = ' \\
  ') continue'$'\\n''    L = RLENGTH; nm = tolower(substr(rest, 1, L)); sub(/^<\\/?/, \"\", nm); sub(/[^a-z0-9].*$/, \"\", nm)'$'\\n''    if (nm != \"br\" && !index(vf_lbl_blocks, \" \" nm \" \")) continue'$'\\n''    w = '""")
rep("""row X06a kill \"$LR p-inside-line $LS\" \"$GC\" \"$RL\" \"$VL\" '    if (nm != \"br\" && !index(vf_lbl_blocks, \" \" nm \" \")) continue' '    if (nm != \"br\") continue'""",
    """row X06a kill \"$LR p-inside-line $LS\" \"$GC\" \"$RL\" \"$VL\" '    if (nm != \"br\" && !index(vf_lbl_blocks, \" \" nm \" \")) continue'$'\\n''    w = ' '    if (nm != \"br\") continue'$'\\n''    w = '""")
rep("""row X06b kill \"$LR br-in-prose $LS\" \"$GC\" \"$RL\" \"$VL\" 'if (nm != \"br\" && !index(vf_lbl_blocks' 'if (!index(vf_lbl_blocks'""",
    """row X06b kill \"$LR br-in-prose $LS\" \"$GC\" \"$RL\" \"$VL\" 'if (nm != \"br\" && !index(vf_lbl_blocks, \" \" nm \" \")) continue'$'\\n''    w = ' 'if (!index(vf_lbl_blocks, \" \" nm \" \")) continue'$'\\n''    w = '""")
i = t.index("row X06c over 'a plausible manifest (span-in-prose) was refused (T030o43 review 2)' \"$GC\" \"$ML\" \\\n")
j = t.index('\n', t.index('\n', i) + 1) + 1
t = t[:i] + """row X06c over 'a plausible manifest (outside-span-tag) was refused (T030o43 review 2)' \"$GC\" \"$ML\" \\
  \"$VL\" '    if (nm != \"br\" && !index(vf_lbl_blocks, \" \" nm \" \")) continue'$'\\n''    w = vf_label_read' '    w = vf_label_read'
# X06c (v5): a span inside a finding is raw HTML and refused by name (T030o48), so its row moved outside every finding.
""" + t[j:]
# X13, X14, X15, X15c: the code-span reading was rewritten as a left-to-right tokenizer (Y rows below).
for rid in ('X13', 'X14'):
    i = t.index('row %s kill ' % rid); j = t.index('\n', i) + 1; t = t[:i] + t[j:]
i = t.index("row X15 over "); j = t.index("say \"== done shard")
t = t[:i] + t[j:]

# N03, N32: vf_settled_lead repeats the word reader's lead loop, so the literals take the line after it.
NX = "$'\\n''    if (match(t, /^([0-9]+[.)]|\\[[ xX]\\])/)) {lead'"
for rid, newloop in (('N03', 'while (t ~ /^([^A-Za-z0-9]|\\[[ xX]\\])/) {'), ('N32', 'while (t ~ /^([[:space:]*+_-]|[0-9]+[.)])/) {')):
    old = "\"$VL\" 'while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\\[[ xX]\\])/) {' '" + newloop + "'"
    new = "\"$VL\" 'while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\\[[ xX]\\])/) {'" + NX + " '" + newloop + "'" + NX
    i = t.index('row %s kill ' % rid); j = t.index('\n', t.index('\n', i) + 1)
    seg = t[i:j]
    assert seg.count(old) == 1, (rid, seg)
    t = t[:i] + seg.replace(old, new) + t[j:]
LR = '$LR'
new = r"""say '== the narrowed grammar inside a finding (T030o48, O-018): vf_narrow, the `<` class, its call in each pass'
row G01 kill "$LR form-feed-in-text $LS" "$GC" "$RL" \
  "$VL" 'if (index(vf_original, sprintf("%c", 12)) || index(vf_original, sprintf("%c", 11))) vf_narrow' 'if (0) vf_narrow'
row G02 kill "$LR form-feed-in-text $LS" "$GC" "$RL" \
  "$VL" 'if (index(vf_original, sprintf("%c", 12)) || index' 'if (index'
row G03 kill "$LR vertical-tab-in-text $LS" "$GC" "$RL" \
  "$VL" ' || index(vf_original, sprintf("%c", 11))) vf_narrow' ') vf_narrow'
row G04 kill "$LR lone-carriage-return $LS" "$GC" "$RL" \
  "$VL" 'else if ((k = index(vf_original, "\r")) && k < length(vf_original)) vf_narrow' 'else if (0) vf_narrow'
row G05 over 'a manifest finding spelled crlf was dropped (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 'k < length(vf_original)) vf_narrow' 'k <= length(vf_original)) vf_narrow'
row G06 kill "$LR pre-in-prose $LS" "$GC" "$RL" \
  "$VL" 'if (vf_cm_out && vf_narrow == "") vf_narrow = "raw HTML' 'if (0) vf_narrow = "raw HTML'
row G06e kill 'a CLEARED completion over a second manifest tier written as - Note<pre>Severity: data-loss</pre> was not refused' "$SG" "$RR" \
  "$VL" 'if (vf_cm_out && vf_narrow == "") vf_narrow = "raw HTML' 'if (0) vf_narrow = "raw HTML'
row G07 equiv '' "$GC" "$RL" \
  "$VL" 'if (vf_cm_out && vf_narrow == "") vf_narrow = "raw HTML' 'if (vf_cm_out) vf_narrow = "raw HTML'
# G07 argued: the conjunct keeps the first reason a line leaves the grammar; without it raw HTML names the line instead
# of a form feed, vertical tab or carriage return on the same line, which is refused by name either way.
row G08 kill "$LR plaintext-in-prose $LS" "$GC" "$RL" \
  "$VL" '~ /[A-Za-z\/!?]/) vf_cm_out = 1' '~ /[\/!?]/) vf_cm_out = 1'
row G09 kill 'a manifest finding carrying raw HTML (severity-then-closing-tag) was not refused by name (round 16, O-018)' "$GC" "$ML" \
  "$VL" '~ /[A-Za-z\/!?]/) vf_cm_out = 1' '~ /[A-Za-z!?]/) vf_cm_out = 1'
row G10 kill 'a manifest finding carrying raw HTML (severity-then-comment) was not refused by name (round 16, O-018)' "$GC" "$ML" \
  "$VL" '~ /[A-Za-z\/!?]/) vf_cm_out = 1' '~ /[A-Za-z\/?]/) vf_cm_out = 1'
row G11 kill "$LR pi-in-prose $LS" "$GC" "$RL" \
  "$VL" '~ /[A-Za-z\/!?]/) vf_cm_out = 1' '~ /[A-Za-z\/!]/) vf_cm_out = 1'
row G12 over 'a plausible manifest (escaped-lt-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 'if (substr(s, i + 1, 1) ~ /[A-Za-z\/!?]/) vf_cm_out = 1' 'vf_cm_out = 1'
row G13 kill "$LR pre-in-prose $LS" "$GC" "$RL" \
  "$VL" '      id != "" && vf_narrow != "" {bad(' '      0 && vf_narrow != "" {bad('
row G14 over 'a plausible manifest (outside-span-tag) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '      id != "" && vf_narrow != "" {bad(' '      vf_narrow != "" {bad('
row G15 kill 'a second tier written as pre-in-prose was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" {err(' '0 && vf_narrow != "" {err('
row G16 kill "$F6" "$GC" "$RL" \
  "$VL" 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" {err(' 'active && !ended && fid != "" && vf_narrow != "" {err('
row G17 equiv '' "$GC" "$RL" \
  "$VL" 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" {err(' 'style=="canonical" && !ended && fid != "" && vf_narrow != "" {err('
# G17 argued, on Q08's premise: while lines are read a canonical style means an active round.
row G18 equiv '' "$GC" "$RL" \
  "$VL" 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" {err(' 'style=="canonical" && active && fid != "" && vf_narrow != "" {err('
# G18 argued: after the completion marker every non-blank line is refused by name already (the after-marker refusal),
# so a narrowed line there is refused either way; the conjunct keeps one diagnostic.
row G19 over 'raw HTML in Held-up prose outside every finding was refused (round 16, O-018)' "$GC" "$RL" \
  "$VL" 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" {err(' 'style=="canonical" && active && !ended && vf_narrow != "" {err('

say '== the code-span scan and the code-span reading (T030o48, O-018): 6.1 read left to right, 2.4 escapes in pairs'
row Y01 over 'a plausible manifest (escaped-lt-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '    if (c == "\\") {i += (i < n && vf_cm_punct(substr(s, i + 1, 1))) ? 2 : 1; continue}' '    if (c == "\\") {i += 1; continue}'
row Y02 equiv '' "$GC" "$RL" \
  "$VL" '  return c != "" && index(vf_cm_p, c) > 0' '  return c != ""'
# Y02 argued: both readers act only on a backslash, a backtick or `<`, each of them punctuation, so taking a
# backslash and a character that is not punctuation as a pair changes no position either reader acts on.
row Y03 over 'a plausible manifest (escaped-lt-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  return c != "" && index(vf_cm_p, c) > 0' '  return 0'
row Y04 kill "$LR code-span-holding-a-backtick $LS" "$GC" "$RL" \
  "$VL" '    if (RLENGTH == r) return off + RSTART + RLENGTH' '    if (1) return off + RSTART + RLENGTH'
row Y05 kill "$LR tag-after-span-closing-next-line $LS" "$GC" "$RL" \
  "$VL" '  if (st > 0) {k = vf_cm_close(s, 1, st); if (!k) {vf_cm_exits = " " st; return}; i = k}' '  if (0) {k = 0}'
row Y06 kill "$LR tag-after-span-closing-next-line $LS" "$GC" "$RL" \
  "$VL" '    if (!k) {vf_cm_exits = vf_cm_exits " " r; i = j; continue}' '    if (!k) {i = j; continue}'
row Y07 kill "$LR tag-after-span-closing-two-lines-later $LS" "$GC" "$RL" \
  "$VL" 'if (!k) {vf_cm_exits = " " st; return}' 'if (!k) {vf_cm_exits = ""; return}'
row Y08 over 'a plausible manifest (code-span-tags-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'    if (!k) {vf_cm_exits = vf_cm_exits " " r; i = j; continue}\n    i = k\n' $'    if (!k) {vf_cm_exits = vf_cm_exits " " r; i = j; continue}\n    i = j\n'
row Y09 kill "$LR tag-after-span-closing-next-line $LS" "$GC" "$RL" \
  "$VL" $'  vf_cm_states = ex\n' $'  vf_cm_states = " 0"\n'
row Y10 equiv '' "$GC" "$RL" \
  "$VL" $'    if (index(done, " " x[i] " ")) continue\n' ''
# Y10 argued: a state read twice repeats the same scan of the same line, which sets the same flag and the same exits.
row Y11 kill "$LR escaped-first-backtick $LS" "$GC" "$RL" \
  "$VL" '    if (c == "\\") {k = (i < n && vf_cm_punct(substr(s, i + 1, 1))) ? 2 : 1; out = out substr(s, i, k); i += k; continue}' '    if (c == "\\") {k = 1; out = out substr(s, i, k); i += k; continue}'
row Y12 over 'a plausible manifest (code-span-word-before-label) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 'f = substr(s, i, k - i); gsub(/[^A-Za-z0-9]/, "\002", f)' 'f = substr(s, i, k - i); gsub(/./, "\002", f)'
row Y12c over 'a canonical finding with a-code-span-word-before-label was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" 'f = substr(s, i, k - i); gsub(/[^A-Za-z0-9]/, "\002", f)' 'f = substr(s, i, k - i); gsub(/./, "\002", f)'
row Y13 kill "$LR image-alt-holding-an-unclosed-run-then-a-span $LS" "$GC" "$RL" \
  "$VL" '    if (!k) {out = out substr(s, i, r); i = j; continue}' '    if (!k) {out = out substr(s, i); i = n + 1; continue}'

say '== the run ends only at a blank line or a heading of one to six marks, never at a fenced line (T030o48, T030o49)'
EB='  if (t == "" || t == "\r" || q ~'
EH='q ~ /^ ? ? ?(#|##|###|####|#####|######)([ \t]|$)/) {vf_run_n'
row E01 over 'a plausible manifest (image-split-by-blank-line) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" "$EB" '  if (t == "\r" || q ~'
row E01c over 'a canonical finding with a-image-split-by-blank-line was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "$EB" '  if (t == "\r" || q ~'
row E02 over 'a plausible manifest (image-split-by-crlf-blank-line) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" "$EB" '  if (t == "" || q ~'
row E03 kill "$LR image-split-by-seven-marks $LS" "$GC" "$RL" \
  "$VL" "$EH" 'q ~ /^ ? ? ?#+([ \t]|$)/) {vf_run_n'
row E03c kill 'a second tier written as image-split-by-seven-marks was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "$EH" 'q ~ /^ ? ? ?#+([ \t]|$)/) {vf_run_n'
row E04 over 'a plausible manifest (image-split-by-six-marks) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 't == "\r" || '"$EH" 't == "\r") {vf_run_n'
row E04c over 'a canonical finding with a-image-split-by-six-marks was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" 't == "\r" || '"$EH" 't == "\r") {vf_run_n'
row E05 over 'a plausible manifest (image-split-by-six-marks) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '(#|##|###|####|#####|######)([ \t]|$)/) {vf_run_n' '(#|##|###|####|#####)([ \t]|$)/) {vf_run_n'
row E06 kill "$LR paragraph-indented-heading-marker $LS" "$GC" "$RL" \
  "$VL" "$EH" 'q ~ /^[ \t]*(#|##|###|####|#####|######)([ \t]|$)/) {vf_run_n'
row E07 over 'a plausible manifest (quoted-image-split-by-six-marks) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  q = s; while (match(q, /^ ? ? ?>[ ]?/)) q = substr(q, RLENGTH + 1)' '  q = s'
row E07c over 'a canonical finding with a-quoted-image-split-by-six-marks was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '  q = s; while (match(q, /^ ? ? ?>[ ]?/)) q = substr(q, RLENGTH + 1)' '  q = s'
row E08 kill "$LR image-after-backtick-info-fence $LS" "$GC" "$RL" \
  "$VL" "$EB" '  if (fenced || t == "" || t == "\r" || q ~'
row E09 over 'a plausible manifest (span-tag-after-a-lone-backtick-paragraph) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 'vf_para_cont = 0; vf_cm_states = " 0"; return}' 'vf_para_cont = 0; return}'
row E09c over 'a canonical finding with a-span-tag-after-a-lone-backtick-paragraph was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" 'vf_para_cont = 0; vf_cm_states = " 0"; return}' 'vf_para_cont = 0; return}'

say '== a settled candidate is dropped (T030o50, O-023): vf_settled and the reader that drops'
row D01 kill "$LR image-alt-across-three-lines $LS" "$GC" "$RL" \
  "$VL" '    if (vf_settled(vf_run_text[k])) vf_run_done[k] = 1' '    vf_run_done[k] = 1'
row D02 equiv '' "$GC" "$RL" \
  "$VL" '    if (vf_settled(vf_run_text[k])) vf_run_done[k] = 1' '    if (0) vf_run_done[k] = 1'
# D02 argued: a candidate never dropped is T030o47's reader, which reads every candidate on every line, so the
# verdicts and diagnostics are the same and only the cost changes (measured: r17-measure, section E).
row D03 kill "$LR tag-attribute-across-three-lines $LS" "$GC" "$RL" \
  "$VL" '  if (index(j, "<") && !vf_settled_html(j)) return 0' '  if (0) return 0'
row D04 kill "$LR image-alt-code-span-closing-two-lines-later $LS" "$GC" "$RL" \
  "$VL" '  vf_cm_scan(j, 0); if (vf_cm_exits != " 0") return 0' '  vf_cm_scan(j, 0)'
row D05 kill "$LR image-alt-across-three-lines $LS" "$GC" "$RL" \
  "$VL" '  if (!vf_settled_brackets(j) || (c != j && !vf_settled_brackets(c))) return 0' '  if (0) return 0'
row D06 kill "$LR link-title-across-three-lines $LS" "$GC" "$RL" \
  "$VL" '  if (!vf_settled_brackets(j) || (c != j && !vf_settled_brackets(c))) return 0' '  if (c != j && !vf_settled_brackets(c)) return 0'
row D07 kill "$LR image-alt-holding-code-span-across-lines $LS" "$GC" "$RL" \
  "$VL" '  if (!vf_settled_brackets(j) || (c != j && !vf_settled_brackets(c))) return 0' '  if (!vf_settled_brackets(j)) return 0'
row D08 kill "$LR image-after-stray-bracket-across-three-lines $LS" "$GC" "$RL" \
  "$VL" '    else if (!d--) return 0' '    else d--'
row D09 kill "$LR image-alt-across-three-lines $LS" "$GC" "$RL" \
  "$VL" $'  if (d) return 0\n' ''
row D10 kill "$LR link-title-across-three-lines $LS" "$GC" "$RL" \
  "$VL" '{p += c; if (!vf_label_dest(s, p + 1)) return 0}' '{p += c}'
row D11 kill "$LR image-alt-holding-escaped-bracket-across-lines $LS" "$GC" "$RL" \
  "$VL" $'  gsub(/\\\\[][]/, "\\003", s)\n  p = 0; d = 0\n' $'  p = 0; d = 0\n'
row D12 equiv '' "$GC" "$RL" \
  "$VL" '  if (!vf_settled_lead(j) || !vf_settled_lead(vf_label_render(j, 0)) || !vf_settled_lead(vf_label_render(j, 1))) return 0' '  if (0) return 0'
# D12 to D15 and D19 argued: a candidate every other condition shows settled, but one of whose readings holds no
# first word yet, reads every later line in that reading as the candidate starting at the next line reads it, since no
# construct spans the boundary, and that candidate is read too; so dropping the first loses no label.
row D13 equiv '' "$GC" "$RL" \
  "$VL" $'  if (c != j && (!vf_settled_lead(vf_label_render(c, 0)) || !vf_settled_lead(vf_label_render(c, 1)))) return 0\n' ''
row D14 equiv '' "$GC" "$RL" \
  "$VL" '  return !index(c, "<") || vf_settled_breaks(j, c)' '  return 1'
row D15 equiv '' "$GC" "$RL" \
  "$VL" $'  return t != ""\n}\nfunction vf_settled_html' $'  return 1\n}\nfunction vf_settled_html'
row D16 equiv '' "$GC" "$RL" \
  "$VL" '    if (vf_run_own[k] != "") {vf_run_done[k] = 1; continue}' '    if (vf_run_own[k] != "") continue'
# D16 argued: a candidate whose own line carries a label is skipped on every line either way; marking it done only
# stops extending it.
row D17 equiv '' "$GC" "$RL" \
  "$VL" 'for (k = 1; k <= vf_run_n; k++) if (!vf_run_done[k]) vf_run_text[k]' 'for (k = 1; k <= vf_run_n; k++) vf_run_text[k]'
# D17 and D18 argued: a candidate marked done is never read again, so extending it changes nothing read; reading it
# again reads a text with no label (a settled one) or meets its own label first (one set aside), as before.
row D18 equiv '' "$GC" "$RL" \
  "$VL" $'    if (vf_run_done[k]) continue\n' ''
row D19 equiv '' "$GC" "$RL" \
  "$VL" '    if (!vf_settled_lead(x) || !vf_settled_lead(vf_label_render(x, 0)) || !vf_settled_lead(vf_label_render(x, 1)) || !vf_settled_lead(vf_label_render(substr(c, p + L), 0))) return 0' '    if (0) return 0'
row D20 equiv '' "$GC" "$RL" \
  "$VL" $'    if (nm != "br" && !index(vf_lbl_blocks, " " nm " ")) continue\n    x = substr(s, p + L)' '    x = substr(s, p + L)'
# D20 argued: without the filter the text after every tag must hold its first word, which can only keep a candidate
# longer, so it can only add a refusal, and inside a finding a tag is refused by name as raw HTML anyway.
row D21 equiv '' "$GC" "$RL" \
  "$VL" '    if (substr(rest, 1, 4) == "<!--") {if (!index(substr(rest, 3), "-->")) return 0; continue}' '    if (substr(rest, 1, 4) == "<!--") continue'
# D21 argued: a comment left open hides the rest of the rendered reading, so that reading holds no first word and the
# lead condition keeps the candidate.
row D22 kill "$LR tag-attribute-across-three-lines $LS" "$GC" "$RL" \
  "$VL" $'    if (!match(rest, vf_lbl_tag) && !match(rest, /^<\\/[A-Za-z][A-Za-z0-9-]*[ \\t]*>/)) return 0\n  }\n  return 1\n}\nfunction vf_settled_brackets' $'  }\n  return 1\n}\nfunction vf_settled_brackets'

"""
anchor = 'say "== done shard $SHARD $(date -u +%H:%M:%SZ) rows=$rowi"\n'
rep(anchor, new + anchor)
rep('say "r15-mutations failures=$fails"\n', 'say "r17-mutations failures=$fails"\n')
open(dst, 'w', encoding='utf-8').write(t)
print('ok')
