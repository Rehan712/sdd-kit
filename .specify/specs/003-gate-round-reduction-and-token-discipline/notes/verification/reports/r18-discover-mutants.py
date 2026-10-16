#!/usr/bin/env python3
# Session 19: candidate mutants of matrix v6 for r18-discover.sh, one or more per guard T030o51, T030o52 and T030o53
# add (the autolink class and its reason; the destination, title and label reader and its two reasons; the fence and
# definition reasons with their carried label; the narrowed check placed after a line's own heading in both passes;
# the settled test read up to each reading's first word), each checked to occur exactly once in the given kernel (the
# candidate: CUR with r18-edits/kernel-1.pairs applied). Writes a NUL file of records id, old, new, judges.
# Usage: python3 -I <this> <kernel> <out.nul> [ids...]
import sys
K = open(sys.argv[1], encoding='utf-8').read()
RL = 'test-gate-contracts.sh:report_record_line_cases'
ML = 'test-gate-contracts.sh:report_manifest_locale_cases'
RR = 'test-spec-gate.sh:round_record_line_cases'
BOTH = RL + ' ' + ML
M = []
def m(i, old, new, judges=BOTH):
    assert K.count(old) == 1, (i, K.count(old), old[:70])
    M.append((i, old, new, judges))
def mf(i, old, new, judges=BOTH):
    a = K.index('function vf_cm_dest('); b = K.index('function vf_cm_label(')
    region = K[a:b]
    assert region.count(old) == 1, (i, region.count(old), old[:70])
    M.append((i, region, region.replace(old, new, 1), judges))
AC = '"[0-9.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"'
# T030o51: the autolink class and its reason
m('A01', 'else if (c ~ vf_cm_ac) vf_cm_auto = 1', 'else if (0) vf_cm_auto = 1', BOTH + ' ' + RR)
m('A02', AC, '"[.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"')
m('A03', AC, '"[0-9.#$%&*+=^{|}~" sprintf("%c", 39) b "-]"')
m('A04', AC, '"[0-9.#$%&*+=^_{|}~" sprintf("%c", 39) "-]"')
m('A05', AC, '"[0-9.#$%&*=^_{|}~" sprintf("%c", 39) b "-]"')
m('A06', AC, '"[ 0-9.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"')
m('A07', '    else if (vf_cm_auto) vf_narrow = "an autolink', '    else if (0) vf_narrow = "an autolink')
m('A08', '    if (vf_narrow != "") continue\n', '')
# T030o51: destinations, titles and labels read before a later backtick
m('B01', 're = "[]\\\\\\\\<" b "]"', 're = "[\\\\\\\\<" b "]"', BOTH + ' ' + RR)
m('B02', 'if (c == "(" || c == "[") {', 'if (c == "(") {')
m('B04', '        if (k < 0) {if (!vf_cm_link) vf_cm_link = 2}', '        if (k < 0) {}')
m('B05', '        else if (k && index(substr(s, i + 1, k - i - 1), b)) vf_cm_link = 1', '        else if (0) vf_cm_link = 1', BOTH + ' ' + RR)
m('B06', '        else if (k && index(substr(s, i + 1, k - i - 1), b)) vf_cm_link = 1', '        else if (k) vf_cm_link = 1')
m('B07', '{if (!vf_cm_link) vf_cm_link = 2}', '{vf_cm_link = 2}')
m('B08', '    else if (vf_cm_link == 1) vf_narrow', '    else if (0) vf_narrow')
m('B09', '    else if (vf_cm_link) vf_narrow = "a link destination', '    else if (0) vf_narrow = "a link destination')
mf('C01', '  n = length(s); j++\n  while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n  if (j > n) return -1\n  if (substr(s, j, 1) == "<") {',
         '  n = length(s); j++\n  if (j > n) return -1\n  if (substr(s, j, 1) == "<") {')
mf('C02', '  n = length(s); j++\n  while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n  if (j > n) return -1\n',
         '  n = length(s); j++\n  while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n  if (j > n) return 0\n')
mf('C03', '  if (substr(s, j, 1) == "<") {\n    j++\n    while (j <= n && (c = substr(s, j, 1)) != ">")', '  if (0) {\n    j++\n    while (j <= n && (c = substr(s, j, 1)) != ">")')
mf('C04', '{if (c == "\\\\") j++; else if (c == "<") return 0; j++}', '{if (c == "<") return 0; j++}')
mf('C05', '{if (c == "\\\\") j++; else if (c == "<") return 0; j++}', '{if (c == "\\\\") j++; j++}')
mf('C06', '!= ">") {if (c == "\\\\") j++; else if (c == "<") return 0; j++}\n    if (j > n) return 0\n', '!= ">") {if (c == "\\\\") j++; else if (c == "<") return 0; j++}\n    if (j > n) return -1\n')
mf('C07', '      if (c == "\\\\") {j += 2; continue}\n      if (c ~ /[ \\t]/) break', '      if (c ~ /[ \\t]/) break')
mf('C08', '      if (c ~ /[ \\t]/) break\n      if (c == "(") depth++', '      if (c == "(") depth++')
mf('C09', '      if (c == "(") depth++\n', '')
mf('C10', '      else if (c == ")") {if (!depth) break; depth--}', '      else if (c == ")") break')
mf('C11', '      j++\n    }\n    if (j > n) return -1\n  }', '      j++\n    }\n    if (j > n) return 0\n  }')
mf('C12', '  if (c == "\\"" || c == sprintf("%c", 39) || c == "(") {', '  if (c == sprintf("%c", 39) || c == "(") {')
mf('C13', '  if (c == "\\"" || c == sprintf("%c", 39) || c == "(") {', '  if (c == "\\"" || c == "(") {')
mf('C14', '  if (c == "\\"" || c == sprintf("%c", 39) || c == "(") {', '  if (c == "\\"" || c == sprintf("%c", 39)) {')
mf('C15', '    while (j <= n && substr(s, j, 1) != q) {if (substr(s, j, 1) == "\\\\") j++; j++}', '    while (j <= n && substr(s, j, 1) != q) j++')
mf('C16', '    if (j > n) return -1\n    j++\n    while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n    if (j > n) return -1\n  }',
         '    if (j > n) return 0\n    j++\n    while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n    if (j > n) return -1\n  }')
mf('C17', '    j++\n    while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n    if (j > n) return -1\n  }\n  return',
         '    j++\n    while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n    if (j > n) return 0\n  }\n  return')
mf('C18', '  return (substr(s, j, 1) == ")") ? j + 1 : 0\n}\n', '  return j + 1\n}\n')
mf('C19', '  }\n  while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n  if (j > n) return -1\n  c = substr(s, j, 1)', '  }\n  while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n  if (j > n) return 0\n  c = substr(s, j, 1)')
m('L01', '  while (j <= n && (c = substr(s, j, 1)) != "]") {if (c == "\\\\") j++; else if (c == "[") return 0; j++}\n  return (j > n) ? -1 : j + 1',
         '  while (j <= n && (c = substr(s, j, 1)) != "]") {if (c == "[") return 0; j++}\n  return (j > n) ? -1 : j + 1')
m('L02', '  while (j <= n && (c = substr(s, j, 1)) != "]") {if (c == "\\\\") j++; else if (c == "[") return 0; j++}\n  return (j > n) ? -1 : j + 1',
         '  while (j <= n && (c = substr(s, j, 1)) != "]") {if (c == "\\\\") j++; j++}\n  return (j > n) ? -1 : j + 1')
m('L03', '  return (j > n) ? -1 : j + 1', '  return (j > n) ? 0 : j + 1')
# T030o52: the fence and definition reasons, the carried label
FEN = '  else if (s ~ ("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)") && s !~ ("^(" f "|~~~)")) vf_narrow'
m('F01', FEN, '  else if (0) vf_narrow', BOTH + ' ' + RR)
m('F02', '("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")', '("^[ \\t]*(" f "|~~~)")')
m('F03', '("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")', '("^[ \\t]*(([-+*])[ \\t]+)*(" f "|~~~)")')
m('F04', '("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")', '("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f ")")')
m('F05', ' && s !~ ("^(" f "|~~~)")) vf_narrow', ') vf_narrow')
m('F06', ' && s !~ ("^(" f "|~~~)")) vf_narrow', ' && s !~ ("^(" f ")")) vf_narrow')
m('F07', '("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")', '("^(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")')
m('F08', '("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")', '("^[ ]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")')
m('R01', '  else if (d) vf_narrow = "a link reference definition"', '  else if (0) vf_narrow = "a link reference definition"', BOTH + ' ' + RR)
m('R02', '    t = s; sub(/^([ \\t]|>|([-+*]|[0-9]+[.)])[ \\t])*/, "", t)', '    t = s; sub(/^([ \\t]|>)*/, "", t)')
m('R03', '    t = s; sub(/^([ \\t]|>|([-+*]|[0-9]+[.)])[ \\t])*/, "", t)', '    t = s; sub(/^([ \\t]|([-+*]|[0-9]+[.)])[ \\t])*/, "", t)')
m('R04', '    if (substr(t, 1, 1) != "[") return 0\n    k = 2', '    if (substr(t, 1, 1) != "[" && 0) return 0\n    k = 2')
m('R05', '{if (c == "\\\\") k++; else if (c == "[") {vf_def_open = 0; return 0}; k++}', '{if (c == "[") {vf_def_open = 0; return 0}; k++}')
m('R06', '{if (c == "\\\\") k++; else if (c == "[") {vf_def_open = 0; return 0}; k++}', '{if (c == "\\\\") k++; k++}')
m('R07', '  vf_def_open = (k > n)\n', '  vf_def_open = 0\n')
m('R08', '  if (!vf_def_open) {\n    t = s;', '  if (1) {\n    t = s;')
m('R09', 'vf_para_cont = vf_def_open = 0; vf_cm_states', 'vf_para_cont = 0; vf_cm_states')
m('R10', '  if (FNR == 1) {vf_run_n = vf_run_refused = vf_def_open = 0;', '  if (FNR == 1) {vf_run_n = vf_run_refused = 0;')
m('R11', '  return k <= n && substr(t, k + 1, 1) == ":"', '  return k <= n')
# the minor: the narrowed check judged after a line's own heading, in both passes
m('H01', '      id != "" && vf_narrow != "" && (vq || !/^ ? ? ?#+([ \\t]|$)/) {bad(', '      id != "" && vf_narrow != "" {bad(')
m('H02', '{id=word[3]; flevel=hl; if (vf_narrow != "") bad(vf_narrow " in finding " id)}', '{id=word[3]; flevel=hl}')
m('H03', '          next\n        }\n        if (vf_narrow != "") bad(vf_narrow " in finding " id)\n      }', '          next\n        }\n      }')
m('H04', '&& fid != "" && vf_narrow != "" && (vq || !/^ ? ? ?#+([ \\t]|$)/) {err(', '&& fid != "" && vf_narrow != "" {err(')
m('H05', '      if (style=="canonical" && active && !ended && fid != "" && vf_narrow != "") err(vf_narrow " in finding " fid)\n      if (ended)', '      if (ended)')
m('H06', 'cursec=""; if (style=="canonical" && active && !ended && fid != "" && vf_narrow != "") err(vf_narrow " in finding " fid); next}', 'cursec=""; next}')
m('H07', '    style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && /^ ? ? ?#+([ \\t]|$)/ {err(', '    0 && /^ ? ? ?#+([ \\t]|$)/ {err(')
m('H08', '    style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && /^ ? ? ?#+([ \\t]|$)/ {err(', '    style=="canonical" && active && !ended && fid != "" && vf_narrow != "" {err(')
m('H09', '      vq {\n        shape=vf_record($0); if (shape == "" && id != "") shape=vf_para_label()', '      vf_quoted($0) {\n        shape=vf_record($0); if (shape == "" && id != "") shape=vf_para_label()')
# T030o53: the settled test read up to each reading's first word
m('S01', '  return vf_settled_lead(t) && vf_settled_brackets(vf_settled_head(t))', '  return vf_settled_lead(t)')
m('S02', '  match(t, /^[A-Za-z0-9]*/)\n  return h substr(t, 1, RLENGTH)', '  return h t')
m('S03', '  while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\\[[ xX]\\])/) {\n    if (match(t, /^([0-9]+[.)]|\\[[ xX]\\])/)) {h = h substr(t, 1, RLENGTH); t = substr(t, RLENGTH + 1)}',
         '  while (t ~ /^([^A-Za-z0-9])/) {\n    if (0) {h = h substr(t, 1, RLENGTH); t = substr(t, RLENGTH + 1)}')
m('S04', '  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0',
         '  if (!vf_settled_word(j) || !vf_settled_lead(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0')
m('S05', '  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0',
         '  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_lead(vf_label_render(j, 1))) return 0')
m('S06', '  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0',
         '  if (!vf_settled_lead(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0')
m('S07', '  if (c != j && (!vf_settled_word(c) || !vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0',
         '  if (c != j && (!vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0')
m('S08', '  if (c != j && (!vf_settled_word(c) || !vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0',
         '  if (c != j && (!vf_settled_word(c) || !vf_settled_lead(vf_label_render(c, 0)) || !vf_settled_lead(vf_label_render(c, 1)))) return 0')
m('S09', '    if (!vf_settled_word(x) || !vf_settled_word(vf_label_render(x, 0)) || !vf_settled_word(vf_label_render(x, 1)) || !vf_settled_word(vf_label_render(substr(c, p + L), 0))) return 0',
         '    if (!vf_settled_lead(x) || !vf_settled_lead(vf_label_render(x, 0)) || !vf_settled_lead(vf_label_render(x, 1)) || !vf_settled_lead(vf_label_render(substr(c, p + L), 0))) return 0')
m('S10', '  if (c != j && (!vf_settled_word(c) || !vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0\n', '')
want = set(sys.argv[3:])
with open(sys.argv[2], 'wb') as f:
    for i, old, new, judges in M:
        if want and i not in want: continue
        for v in (i, old, new, judges): f.write(v.encode('utf-8') + b'\0')
print('mutants', len([x for x in M if not want or x[0] in want]))
