# Builds r18-edits/kernel-1.pairs and vc-1.pairs (session 19, round 17's O-018, O-024 and O-023 and its minor, by
# the user's choices of 2026-10-09: narrow O-018 and O-024 further, settle O-023 on each reading's first word, the
# minor folded in) from the exact current text of the two files, so every OLD block is taken verbatim and must match
# exactly once (lit.pl checks). Pattern: r17-edits/build-pairs.py.
# Run from the worktree root: python3 -I <this> <out-dir>
import sys
out = sys.argv[1]
K = open('scripts/verification-lib.sh', encoding='utf-8').read()
V = open('templates/verification-contract.md', encoding='utf-8').read()

def block(old, new, src):
    assert src.count(old) == 1, ('OLD not unique', src.count(old), old[:80])
    return '@@OLD\n' + old + '\n@@NEW\n' + new + '\n@@END\n'

kp = []
# 1. The comment: the settled test and the narrowed grammar.
kp.append(block(
"""# a label. A candidate is dropped once its text is settled (vf_settled; round
# 16, O-023): every construct a reading resolves across lines (a code span, a
# bracket pair, a link destination, a raw-HTML construct) is closed within
# it, and every reading of it, and of the text after each br or block-level
# tag in it, already holds its first word, so no later line can change how
# any reading of it begins; a candidate not shown settled is kept.
# Inside a finding the grammar is narrowed rather than rendered (round 16,
# O-018; the user's decision of 2026-10-08): vf_para also sets vf_narrow to
# the reason a line breaks it, or "": a form feed or vertical tab, a carriage
# return that does not end the line (both read on the line as written), or a
# `<` that may open raw HTML or an autolink (6.5, 6.6, 4.6: one followed by a
# letter, `/`, `!` or `?`) outside every code span. vf_cm_scan places code
# spans by 6.1 read left to right (2.4 escapes taken in pairs, a backtick run
# closed only by the next run of the same length) for every state a paragraph
# may enter the line in: no open span, or a span an earlier line of the run
# left open, read both as an opener and as literal text; the states reset at
# the run's ends. A `<` is inside a code span only when every such reading
# places it there, so a span the reader invents cannot hide one. Both readers
# refuse such a line by name inside a finding.""",
"""# a label. A candidate is dropped once its text is settled (vf_settled; round
# 16, O-023): every code span and raw-HTML construct in it is closed, and
# every reading of it, and of the text after each br or block-level tag in
# it, already holds its first word with no bracket pair or link destination
# that opens at or before that word left open in that reading (vf_settled_word;
# round 17, O-023: a bracket after the first word, quoted in a code span or
# not, cannot change how the reading begins, while one before it can, since
# an image a later line completes takes the word away), so no later line can
# change how any reading of it begins; a candidate not shown settled is kept.
# Inside a finding the grammar is narrowed rather than rendered (round 16,
# O-018; the user's decisions of 2026-10-08 and 2026-10-09): vf_para also sets
# vf_narrow to the reason a line breaks it, or "": a form feed or vertical
# tab, a carriage return that does not end the line (both read on the line as
# written); a code fence that may be inside a list item, three or more
# backticks or tildes after indentation or a list marker (4.5, 5.2: the shared
# tracker opens a fence at the start of a line only, and a renderer ends a
# fence a list item opens with that item, so a line in it can close a finding
# to the passes and the tracker can quote what a renderer shows; round 17,
# O-024); a link reference definition, a line whose text after indentation,
# list markers and block-quote markers begins with a bracket closed at once
# by `]:`, or a later line of its run that closes such a bracket left open at
# the end of its line by `]:`, since a label may span lines (4.7: a definition
# renders nothing, and its title may span lines and hold a field line; round
# 17, O-024); or, outside every code span, a `<` that may open raw
# HTML (6.6, 4.6: one followed by a letter, `/`, `!` or `?`), a `<` that may
# open an autolink (6.5: one followed by a digit or a symbol an email address
# may begin with), or an inline link's destination or title, or a full
# reference link's label, that holds a backtick or does not end on its line
# (6.3, 6.5: each is read before a later backtick can open a code span, so a
# backtick inside it opens none and a code span the reader pairs it into
# hides nothing; round 17, O-018). vf_cm_scan places code
# spans by 6.1 read left to right (2.4 escapes taken in pairs, a backtick run
# closed only by the next run of the same length) for every state a paragraph
# may enter the line in: no open span, or a span an earlier line of the run
# left open, read both as an opener and as literal text; the states reset at
# the run's ends. A `<`, a destination, a title or a label is inside a code
# span only when every such reading places it there, so a span the reader
# invents cannot hide one. Both readers refuse such a line by name inside a
# finding, judged after the line's own heading has opened or closed a finding
# (round 17).""", K))
# 2. vf_cm_scan: the autolink class, and destinations, titles and labels read before a later backtick.
kp.append(block(
"""function vf_cm_scan(s, st,   b, re, n, i, c, j, r, k) {
  b = sprintf("%c", 96); re = "[\\\\\\\\<" b "]"; vf_cm_out = 0; vf_cm_exits = ""; n = length(s); i = 1
  if (st > 0) {k = vf_cm_close(s, 1, st); if (!k) {vf_cm_exits = " " st; return}; i = k}
  while (i <= n && match(substr(s, i), re)) {
    i += RSTART - 1; c = substr(s, i, 1)
    if (c == "\\\\") {i += (i < n && vf_cm_punct(substr(s, i + 1, 1))) ? 2 : 1; continue}
    if (c == "<") {if (substr(s, i + 1, 1) ~ /[A-Za-z\\/!?]/) vf_cm_out = 1; i++; continue}
    j = i; while (j <= n && substr(s, j, 1) == b) j++""",
"""function vf_cm_dest(s, j,   n, c, depth, q) {
  n = length(s); j++
  while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++
  if (j > n) return -1
  if (substr(s, j, 1) == "<") {
    j++
    while (j <= n && (c = substr(s, j, 1)) != ">") {if (c == "\\\\") j++; else if (c == "<") return 0; j++}
    if (j > n) return 0
    j++
  } else {
    depth = 0
    while (j <= n) {
      c = substr(s, j, 1)
      if (c == "\\\\") {j += 2; continue}
      if (c ~ /[ \\t]/) break
      if (c == "(") depth++
      else if (c == ")") {if (!depth) break; depth--}
      j++
    }
    if (j > n) return -1
  }
  while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++
  if (j > n) return -1
  c = substr(s, j, 1)
  if (c == "\\"" || c == sprintf("%c", 39) || c == "(") {
    q = (c == "(") ? ")" : c; j++
    while (j <= n && substr(s, j, 1) != q) {if (substr(s, j, 1) == "\\\\") j++; j++}
    if (j > n) return -1
    j++
    while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++
    if (j > n) return -1
  }
  return (substr(s, j, 1) == ")") ? j + 1 : 0
}
function vf_cm_label(s, j,   n, c) {
  n = length(s); j++
  while (j <= n && (c = substr(s, j, 1)) != "]") {if (c == "\\\\") j++; else if (c == "[") return 0; j++}
  return (j > n) ? -1 : j + 1
}
function vf_cm_scan(s, st,   b, re, n, i, c, j, r, k) {
  b = sprintf("%c", 96); re = "[]\\\\\\\\<" b "]"; vf_cm_out = vf_cm_auto = vf_cm_link = 0; vf_cm_exits = ""; n = length(s); i = 1
  if (vf_cm_ac == "") vf_cm_ac = "[0-9.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"
  if (st > 0) {k = vf_cm_close(s, 1, st); if (!k) {vf_cm_exits = " " st; return}; i = k}
  while (i <= n && match(substr(s, i), re)) {
    i += RSTART - 1; c = substr(s, i, 1)
    if (c == "\\\\") {i += (i < n && vf_cm_punct(substr(s, i + 1, 1))) ? 2 : 1; continue}
    if (c == "<") {c = substr(s, i + 1, 1); if (c ~ /[A-Za-z\\/!?]/) vf_cm_out = 1; else if (c ~ vf_cm_ac) vf_cm_auto = 1; i++; continue}
    if (c == "]") {
      c = substr(s, i + 1, 1)
      if (c == "(" || c == "[") {
        k = (c == "(") ? vf_cm_dest(s, i + 1) : vf_cm_label(s, i + 1)
        if (k < 0) {if (!vf_cm_link) vf_cm_link = 2}
        else if (k && index(substr(s, i + 1, k - i - 1), b)) vf_cm_link = 1
      }
      i++; continue
    }
    j = i; while (j <= n && substr(s, j, 1) == b) j++""", K))
# 3. vf_settled: brackets and destinations read up to each reading's first word only, in every reading.
kp.append(block(
"""function vf_settled_html(s,   p, e, rest) {""",
"""function vf_settled_head(t,   h) {
  h = ""
  while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\\[[ xX]\\])/) {
    if (match(t, /^([0-9]+[.)]|\\[[ xX]\\])/)) {h = h substr(t, 1, RLENGTH); t = substr(t, RLENGTH + 1)}
    else {h = h substr(t, 1, 1); t = substr(t, 2)}
  }
  match(t, /^[A-Za-z0-9]*/)
  return h substr(t, 1, RLENGTH)
}
function vf_settled_word(t) {
  return vf_settled_lead(t) && vf_settled_brackets(vf_settled_head(t))
}
function vf_settled_html(s,   p, e, rest) {""", K))
kp.append(block(
"""    if (!vf_settled_lead(x) || !vf_settled_lead(vf_label_render(x, 0)) || !vf_settled_lead(vf_label_render(x, 1)) || !vf_settled_lead(vf_label_render(substr(c, p + L), 0))) return 0""",
"""    if (!vf_settled_word(x) || !vf_settled_word(vf_label_render(x, 0)) || !vf_settled_word(vf_label_render(x, 1)) || !vf_settled_word(vf_label_render(substr(c, p + L), 0))) return 0""", K))
kp.append(block(
"""  if (!vf_settled_brackets(j) || (c != j && !vf_settled_brackets(c))) return 0
  if (!vf_settled_lead(j) || !vf_settled_lead(vf_label_render(j, 0)) || !vf_settled_lead(vf_label_render(j, 1))) return 0
  if (c != j && (!vf_settled_lead(vf_label_render(c, 0)) || !vf_settled_lead(vf_label_render(c, 1)))) return 0""",
"""  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0
  if (c != j && (!vf_settled_word(c) || !vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0""", K))
# 4. vf_para: a fence a list item may open, a link reference definition, and the two new reasons per reading.
kp.append(block(
"""  if (t == "" || t == "\\r" || q ~ /^ ? ? ?(#|##|###|####|#####|######)([ \\t]|$)/) {vf_run_n = vf_run_refused = vf_para_cont = 0; vf_cm_states = " 0"; return}""",
"""  if (t == "" || t == "\\r" || q ~ /^ ? ? ?(#|##|###|####|#####|######)([ \\t]|$)/) {vf_run_n = vf_run_refused = vf_para_cont = vf_def_open = 0; vf_cm_states = " 0"; return}""", K))
kp.append(block(
"""function vf_para(s,   t, q, k, x, i, n, done, ex) {
  if (FNR == 1) {vf_run_n = vf_run_refused = 0; vf_cm_states = " 0"}
  t = s; sub(/^[ \\t]*(>[ \\t]*)*/, "", t)
  q = s; while (match(q, /^ ? ? ?>[ ]?/)) q = substr(q, RLENGTH + 1)
  vf_narrow = ""
  if (index(vf_original, sprintf("%c", 12)) || index(vf_original, sprintf("%c", 11))) vf_narrow = "a form feed or vertical tab"
  else if ((k = index(vf_original, "\\r")) && k < length(vf_original)) vf_narrow = "a carriage return inside a line"
  n = split(vf_cm_states " 0", x, " "); done = " "; ex = ""
  for (i = 1; i <= n; i++) {
    if (index(done, " " x[i] " ")) continue
    done = done x[i] " "; vf_cm_scan(t, x[i] + 0); ex = ex vf_cm_exits
    if (vf_cm_out && vf_narrow == "") vf_narrow = "raw HTML outside a code span"
  }""",
"""function vf_para_refdef(s, t,   k, n, c) {
  if (!vf_def_open) {
    t = s; sub(/^([ \\t]|>|([-+*]|[0-9]+[.)])[ \\t])*/, "", t)
    if (substr(t, 1, 1) != "[") return 0
    k = 2
  } else k = 1
  n = length(t)
  while (k <= n && (c = substr(t, k, 1)) != "]") {if (c == "\\\\") k++; else if (c == "[") {vf_def_open = 0; return 0}; k++}
  vf_def_open = (k > n)
  return k <= n && substr(t, k + 1, 1) == ":"
}
function vf_para(s,   t, q, k, x, i, n, done, ex, f, d) {
  if (FNR == 1) {vf_run_n = vf_run_refused = vf_def_open = 0; vf_cm_states = " 0"}
  t = s; sub(/^[ \\t]*(>[ \\t]*)*/, "", t)
  q = s; while (match(q, /^ ? ? ?>[ ]?/)) q = substr(q, RLENGTH + 1)
  vf_narrow = ""; f = sprintf("%c%c%c", 96, 96, 96); d = vf_para_refdef(s, t)
  if (index(vf_original, sprintf("%c", 12)) || index(vf_original, sprintf("%c", 11))) vf_narrow = "a form feed or vertical tab"
  else if ((k = index(vf_original, "\\r")) && k < length(vf_original)) vf_narrow = "a carriage return inside a line"
  else if (s ~ ("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)") && s !~ ("^(" f "|~~~)")) vf_narrow = "a code fence that may be inside a list item"
  else if (d) vf_narrow = "a link reference definition"
  n = split(vf_cm_states " 0", x, " "); done = " "; ex = ""
  for (i = 1; i <= n; i++) {
    if (index(done, " " x[i] " ")) continue
    done = done x[i] " "; vf_cm_scan(t, x[i] + 0); ex = ex vf_cm_exits
    if (vf_narrow != "") continue
    if (vf_cm_out) vf_narrow = "raw HTML outside a code span"
    else if (vf_cm_link == 1) vf_narrow = "a backtick inside a link destination, title or label"
    else if (vf_cm_link) vf_narrow = "a link destination, title or label that does not end on its line"
    else if (vf_cm_auto) vf_narrow = "an autolink outside a code span"
  }""", K))
# 5. The manifest pass: the narrowed check judged after a heading has opened or closed a finding (round 17, minor).
kp.append(block(
"""      {vf_para($0)}
      id != "" && vf_narrow != "" {bad(vf_narrow " in finding " id)}
      vf_quoted($0) {
        shape=vf_record($0); if (shape == "" && id != "") shape=vf_para_label()""",
"""      # The narrowed check is judged after the heading on a line has opened or
      # closed a finding (round 17): a heading reads it under the finding it
      # opens or stays in, never under one it closes.
      {vf_para($0); vq=vf_quoted($0)}
      id != "" && vf_narrow != "" && (vq || !/^ ? ? ?#+([ \\t]|$)/) {bad(vf_narrow " in finding " id)}
      vq {
        shape=vf_record($0); if (shape == "" && id != "") shape=vf_para_label()""", K))
kp.append(block(
"""          if (word[3] ~ /^[A-Z][A-Z0-9]*-[0-9]+$/) {id=word[3]; flevel=hl}
          else bad("a Finding heading whose ID this grammar cannot read")
          next
        }
        if (vf_finding_heading($0)) {flushm(); idseen=1; bad("a Finding heading this grammar cannot read"); next}
        if (id == "" || hl <= flevel) {
          flushm()
          idseen=(heading ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) || tolower(word[2]) == "finding"
          next
        }
      }""",
"""          if (word[3] ~ /^[A-Z][A-Z0-9]*-[0-9]+$/) {id=word[3]; flevel=hl; if (vf_narrow != "") bad(vf_narrow " in finding " id)}
          else bad("a Finding heading whose ID this grammar cannot read")
          next
        }
        if (vf_finding_heading($0)) {flushm(); idseen=1; bad("a Finding heading this grammar cannot read"); next}
        if (id == "" || hl <= flevel) {
          flushm()
          idseen=(heading ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) || tolower(word[2]) == "finding"
          next
        }
        if (vf_narrow != "") bad(vf_narrow " in finding " id)
      }""", K))
# 6. The canonical pass: the same, at the finding heading, the report title and the section headings.
kp.append(block(
"""    {vf_para($0)}
    style=="canonical" && active && !ended && fid != "" && vf_narrow != "" {err(vf_narrow " in finding " fid)}
    vf_quoted($0) {""",
"""    # The narrowed check is judged after the heading on a line has opened or
    # closed a finding (round 17): a heading reads it under the finding it
    # opens or stays in, never under one it closes.
    {vf_para($0); vq=vf_quoted($0)}
    style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && (vq || !/^ ? ? ?#+([ \\t]|$)/) {err(vf_narrow " in finding " fid)}
    vq {""", K))
kp.append(block(
"""    /^# (Opponent review|Reality Check)/ {
      if (ended) {err("content after the round completion marker"); next}""",
"""    /^# (Opponent review|Reality Check)/ {
      if (style=="canonical" && active && !ended && fid != "" && vf_narrow != "") err(vf_narrow " in finding " fid)
      if (ended) {err("content after the round completion marker"); next}""", K))
kp.append(block(
"""    /^### Finding / {finding(); if(!active || ended) err("finding outside round"); vf_fields(vf_original, hw); fid=hw[3]; cursec=""; next}""",
"""    /^### Finding / {finding(); if(!active || ended) err("finding outside round"); vf_fields(vf_original, hw); fid=hw[3]; cursec=""; if (style=="canonical" && active && !ended && fid != "" && vf_narrow != "") err(vf_narrow " in finding " fid); next}""", K))
kp.append(block(
"""    style=="canonical" && fid && /^ ? ? ?(#|##|###)([ \\t]|$)/ {finding()}""",
"""    style=="canonical" && fid && /^ ? ? ?(#|##|###)([ \\t]|$)/ {finding()}
    style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && /^ ? ? ?#+([ \\t]|$)/ {err(vf_narrow " in finding " fid)}""", K))

vp = []
vp.append(block(
"""nothing a later line adds can change how it begins. Inside a finding the
grammar is narrowed rather than rendered: a line that carries raw HTML or an
autolink (a `<` followed by a letter, `/`, `!` or `?`) outside every code
span, a form feed or vertical tab, or a carriage return that does not end the
line is refused by name, so a report writes markup inside a finding only as
code, between backticks. The other canonical fields are""",
"""nothing a later line adds can change how it begins. Inside a finding the
grammar is narrowed rather than rendered: a line is refused by name when it
carries, outside every code span, raw HTML or an autolink (a `<` followed by
a letter, a digit, or a symbol an email address may begin with), or an inline
link's destination or title, or a full reference link's label, that holds a
backtick or does not end on its line; when it carries a form feed or vertical
tab, or a carriage return that does not end the line; when it opens a code
fence anywhere but at the start of the line (after indentation or a list
marker, where a list item may open a fence the fence tracker does not
follow); or when it begins or closes a link reference definition's label (a
bracket at the start of a line closed by `]:` on that line, or on a later line
of its paragraph, since a label may span lines). The check
is judged after the line's own heading has opened or closed a finding. So a
report writes markup inside a finding only as code, between backticks, writes
a code example inside a finding as a fence at the start of a line, and keeps
link definitions outside every finding. The other canonical fields are""", V))

open(out + '/kernel-1.pairs', 'w', encoding='utf-8').write(''.join(kp))
open(out + '/vc-1.pairs', 'w', encoding='utf-8').write(''.join(vp))
print('kernel blocks=%d contract blocks=%d' % (len(kp), len(vp)))
