#!/usr/bin/env python3
# Builds r18-mutations.sh (matrix v6) from r17-mutations.sh (v5): the header, the scratch directory, the v5 rows whose
# literals T030o51 to T030o53 rewrote (G06, G06e, G07, G12 to G19, E09, E09c, P21, D05 to D07, D12 to D15, D19), and a
# section for every guard they add, each row the mutant the discovery probe measured (r18-discover-mutants.py, read
# against the live kernel; r18-discover-{a,b,c}.log) and judged by the fixture row it names: the rows tgc-1 carries,
# and the rows tgc-2 adds where no tgc-1 row reached a guard (r18-fixtures-judge-2, run 4). A discovery mutant whose
# literal a v5 row takes keeps the v5 row (A08 is G07, S01 is D05, S06 is D06, S10 is D13); every other one is a row
# named V and its discovery id, since v5 already names rows B, C, F, L, R and S. Rows marked equiv are argued beside
# them. A literal of vf_cm_dest also occurs in vf_label_dest, so such a row takes the fewest whole lines of
# vf_cm_dest around the literal that occur once in the kernel (as mf() in r18-discover-mutants.py mutates inside the
# function's own text).
# Usage from the worktree root: python3 -I <this> r17-mutations.sh r18-mutations.sh
import os, subprocess, sys, tempfile
src, dst = sys.argv[1], sys.argv[2]
here = os.path.dirname(os.path.abspath(__file__))
K = open('scripts/verification-lib.sh', encoding='utf-8').read()
t = open(src, encoding='utf-8').read()

def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (old[:90], t.count(old))
    t = t.replace(old, new)

def q(s):  # bash ANSI-C quoting
    return "$'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n') + "'"

# The discovery mutants, as r18-discover-mutants.py writes them for the live kernel.
with tempfile.TemporaryDirectory() as d:
    nul = os.path.join(d, 'm.nul')
    subprocess.run([sys.executable, '-I', os.path.join(here, 'r18-discover-mutants.py'), 'scripts/verification-lib.sh', nul],
                   check=True, stdout=subprocess.DEVNULL)
    f = open(nul, 'rb').read().decode('utf-8').split('\0')[:-1]
MUT = {}
for i in range(0, len(f), 4):
    MUT[f[i]] = (f[i + 1], f[i + 2])

def lit(mid):
    old, new = MUT[mid]
    if not old.startswith('function vf_cm_dest('):
        assert K.count(old) == 1, mid
        return old, new
    # An mf() record: old and new are the whole of vf_cm_dest; take the fewest whole lines around the change that
    # occur once in the kernel.
    a = 0
    while a < len(old) and a < len(new) and old[a] == new[a]: a += 1
    b = 0
    while b < len(old) - a and b < len(new) - a and old[-1 - b] == new[-1 - b]: b += 1
    starts = [0] + [i + 1 for i, ch in enumerate(old) if ch == '\n' and i + 1 < len(old)]
    ends = [i + 1 for i, ch in enumerate(old) if ch == '\n'] + ([len(old)] if not old.endswith('\n') else [])
    ls = max(k for k, x in enumerate(starts) if x <= a); le = min(k for k, x in enumerate(ends) if x >= len(old) - b)
    best = None
    for extra in range(len(starts) + len(ends)):  # the fewest whole lines, preferring lines above
        for up in range(extra + 1):
            dn = extra - up
            if ls - up < 0 or le + dn >= len(ends): continue
            s, e = starts[ls - up], ends[le + dn]
            if K.count(old[s:e]) == 1: best = (s, e); break
        if best: break
    s, e = best
    o = old[s:e]; n = new[s:len(new) - (len(old) - e)]
    assert K.count(o) == 1 and o != n, mid
    return o, n

def row(rid, mid, kind, diag, tf='$GC', case='$RL', note=''):
    o, n = lit(mid)
    out = 'row %s %s %s "%s" "%s" \\\n  "$VL" %s %s\n' % (rid, kind, diag, tf, case, q(o), q(n))
    return out + ''.join('# ' + l + '\n' for l in note.split('\n') if note)

head_old = t[:t.index('# Harness: t030o43-mutations.sh, as v2.\n')]
rep(head_old, '''#!/usr/bin/env bash
# T030o51, T030o52 and T030o53 mutation matrix v6, 2026-10-13 (session 20), from r17-mutations.sh (v5, kept with its
# runs), built by r18-mutations-gen.py: every guard of T030o44 to T030o50 as v5 judged it, with the rows whose literals
# the repair rewrote re-targeted (the narrowed check's call in each pass, the raw-HTML reason, the run-end reset, the
# settled test now read up to each reading's first word), and a row for every guard the repair adds, each the mutant
# the discovery probe measured (r18-discover-mutants.py, r18-discover-{a,b,c}.log) and judged by the fixture row it
# names (tgc-1, or the rows tgc-2 and tgc-3 add, judged by r18-fixtures-judge-2 run 4 and r18-fixtures-judge-3): the
# autolink class and its reason; the
# destination, title and label reader (vf_cm_dest, vf_cm_label) and its two reasons; the fence and definition reasons
# with the carried label; the narrowed check judged after a line's own heading in both passes; the settled test read
# up to each reading's first word. Rows marked equiv are argued beside them. Each in a standalone copy built from the
# live manifest enumeration, every judge under a TMPDIR ending in `/`, in its own process group under a watchdog
# (900 s by default) that stops it whole and counts it failed with the diagnostic `watchdog: judge stopped after`.
''')
rep('# Usage: bash r17-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n] [ONLY=id,id...]\n',
    '# Usage: bash r18-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n] [ONLY=id,id...]\n')
rep('R="$SP/r17-matrix-$si"', 'R="$SP/r18-matrix-$si"')

# The narrowed grammar's reasons are chosen in one chain now, after the first reason ends the loop (T030o51).
RAW_OLD = "\"$VL\" 'if (vf_cm_out && vf_narrow == \"\") vf_narrow = \"raw HTML' 'if (0) vf_narrow = \"raw HTML'"
RAW_NEW = "\"$VL\" '    if (vf_cm_out) vf_narrow = \"raw HTML' '    if (0) vf_narrow = \"raw HTML'"
rep(RAW_OLD, RAW_NEW, 2)
rep("""row G07 equiv '' "$GC" "$RL" \\
  "$VL" 'if (vf_cm_out && vf_narrow == "") vf_narrow = "raw HTML' 'if (vf_cm_out) vf_narrow = "raw HTML'
# G07 argued: the conjunct keeps the first reason a line leaves the grammar; without it raw HTML names the line instead
# of a form feed, vertical tab or carriage return on the same line, which is refused by name either way.
""", row('G07', 'A08', 'equiv', "''", note='''G07 argued (v6: discovery A08): the guard keeps the first reason a line leaves the grammar; without it a later
reason, from the same reading of the line or from a later code-span state, names the line instead. Every reason
refuses the line by name in both passes, and the chain only ever sets one, so the verdict is the same and only the
diagnostic may change; no row writes a line with two reasons.'''))
rep("""row G12 over 'a plausible manifest (escaped-lt-prose) was refused (T030o43 review 2)' "$GC" "$ML" \\
  "$VL" 'if (substr(s, i + 1, 1) ~ /[A-Za-z\\/!?]/) vf_cm_out = 1' 'vf_cm_out = 1'""",
    """row G12 over 'a plausible manifest (escaped-lt-prose) was refused (T030o43 review 2)' "$GC" "$ML" \\
  "$VL" 'if (c ~ /[A-Za-z\\/!?]/) vf_cm_out = 1; else if (c ~ vf_cm_ac)' 'vf_cm_out = 1; if (c ~ vf_cm_ac)'""")
# The manifest pass's narrowed check is judged after a line's own heading (the round's minor).
MC = """'      id != "" && vf_narrow != "" {bad('"""
MCN = """'      id != "" && vf_narrow != "" && (vq ||'"""
rep("""  "$VL" """ + MC + """ '      0 && vf_narrow != "" {bad('""", """  "$VL" """ + MCN + """ '      0 && vf_narrow != "" && (vq ||'""")
rep("""  "$VL" """ + MC + """ '      vf_narrow != "" {bad('""", """  "$VL" """ + MCN + """ '      vf_narrow != "" && (vq ||'""")
CC = 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" {err('
CCN = 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && (vq ||'
for rid, new in (('G15', '0 && vf_narrow != "" {err('), ('G16', 'active && !ended && fid != "" && vf_narrow != "" {err('),
                 ('G17', 'style=="canonical" && !ended && fid != "" && vf_narrow != "" {err('),
                 ('G18', 'style=="canonical" && active && fid != "" && vf_narrow != "" {err('),
                 ('G19', 'style=="canonical" && active && !ended && vf_narrow != "" {err(')):
    i = t.index('row %s ' % rid); j = t.index('\n', t.index('\n', i) + 1)
    seg = t[i:j]; old = "'%s' '%s'" % (CC, new); assert seg.count(old) == 1, rid
    t = t[:i] + seg.replace(old, "'%s' '%s'" % (CCN, new.replace('{err(', '&& (vq ||'))) + t[j:]
rep("""# G18 argued: after the completion marker every non-blank line is refused by name already (the after-marker refusal),
# so a narrowed line there is refused either way; the conjunct keeps one diagnostic.""",
    """# G18 argued: after the completion marker every non-blank line is refused by name already (the after-marker refusal),
# so a narrowed line there is refused either way; the conjunct keeps one diagnostic. The v6 rows G13 to G19 take the
# main check, whose heading conjunct (vq || not a heading) the round's minor added; the checks at a line's own
# heading are the VH rows.""")
# The run-end reset and the per-file reset clear the carried definition label too (T030o52).
rep("""'vf_para_cont = 0; vf_cm_states = " 0"; return}' 'vf_para_cont = 0; return}'""",
    """'vf_para_cont = vf_def_open = 0; vf_cm_states = " 0"; return}' 'vf_para_cont = vf_def_open = 0; return}'""", 2)
rep("""row P21 equiv '' "$GC" "$RL" "$VL" '  if (FNR == 1) {vf_run_n = vf_run_refused = 0; vf_cm_states = " 0"}'$'\\n' ''""",
    """row P21 equiv '' "$GC" "$RL" "$VL" '  if (FNR == 1) {vf_run_n = vf_run_refused = vf_def_open = 0; vf_cm_states = " 0"}'$'\\n' ''""")
rep("""# only add a refusal; every manifest and report a fixture writes begins with an ATX heading, which ends a run anyway,
# and resets the carried code-span states with it (v5).""",
    """# only add a refusal; every manifest and report a fixture writes begins with an ATX heading, which ends a run anyway,
# and resets the carried code-span states with it (v5) and the carried definition label (v6).""")

# L15: vf_cm_dest repeats vf_label_dest's depth loop, so the literal takes the lines after it to the end of
# vf_label_dest's bare-destination branch, which vf_cm_dest ends differently (r18-mutations-dry-run1).
L15O = '      if (c == "(") depth++\n      else if (c == ")") {if (!depth) break; depth--}\n      j++\n    }\n  }\n'
rep("""  "$VL" '      if (c == "(") depth++' '      if (0) depth++'""", '  "$VL" ' + q(L15O) + ' ' + q(L15O.replace('if (c == "(") depth++', 'if (0) depth++')))
# K05: the round-17 minor judges the narrowed check after a heading the manifest pass reads, before the end of the
# heading branch, so the inserted next takes the line after that check (r18-mutations-dry-run1).
K05O = '          idseen=(heading ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) || tolower(word[2]) == "finding"\n          next\n        }\n        if (vf_narrow != "") bad(vf_narrow " in finding " id)\n      }'
rep("""  "$VL" $'          idseen=(heading ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) || tolower(word[2]) == "finding"\\n          next\\n        }\\n      }' $'          idseen=(heading ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) || tolower(word[2]) == "finding"\\n          next\\n        }\\n        next\\n      }'""",
    '  "$VL" ' + q(K05O) + ' ' + q(K05O.replace('id)\n      }', 'id)\n        next\n      }')))
# D04: T030o53's head bracket test keeps the candidate of D04's v5 row on its open image bracket, so the open-code-span
# condition is judged by a row with no bracket before any reading's first word (r18-mutations-run1.note, tgc-3).
i = t.index('row D04 kill '); j = t.index('\n', t.index('\n', i) + 1) + 1
seg = t[i:j]; old = '"$LR image-alt-code-span-closing-two-lines-later $LS"'; assert seg.count(old) == 1
t = t[:i] + seg.replace(old, '"$LR entity-then-code-span-holding-image-across-lines $LS"') \
    + '# D04 (v6): judged by a code span left open across lines after an entity, which holds an image; the open image\n' \
    + '# bracket of its v5 row is kept by the head bracket test now (r18-mutations-run1.note).\n' + t[j:]
# A judge runs in its own process group under a watchdog (pattern: t030o39-o40-mutations.sh), since the 400-line
# timing row (T030o53) makes a mutant that keeps every candidate run for hours (r18-mutations-run1.note).
i = t.index('judge() { # <test file> <case function> -> exit; output in $w/judge.out\n'); j = t.index('}\n', t.index('rm -rf "$SANDBOX"; printf', i)) + 2
old_judge = t[i:j]
assert old_judge.count(') > "$w/judge.out" 2>&1\n') == 1, old_judge
WD = (') > "$w/judge.out" 2>&1 &\n'
      '  local pid=$! n=0\n'
      '  while kill -0 "$pid" 2>/dev/null; do\n'
      '    if (( n++ >= WATCHDOG )); then\n'
      '      kill -TERM -- "-$pid" 2>/dev/null; sleep 2; kill -KILL -- "-$pid" 2>/dev/null; wait "$pid" 2>/dev/null\n'
      '      echo "watchdog: judge stopped after ${WATCHDOG} s" >> "$w/judge.out"; return 124\n'
      '    fi\n'
      '    sleep 1\n'
      '  done\n'
      '  wait "$pid"\n')
new_judge = old_judge.replace('judge() { # <test file> <case function> -> exit; output in $w/judge.out\n',
                              'judge() { # <test file> <case function> -> exit (124 when the watchdog stopped it); output in $w/judge.out\n').replace(') > "$w/judge.out" 2>&1\n', WD)
t = t[:i] + new_judge + t[j:]
rep('set -uo pipefail\nSP="$1"; WT="$2"; DRY="${DRY:-0}"; SHARD="${SHARD:-0/1}"; ONLY="${ONLY:-}"\n',
    'set -uo pipefail\nset -m  # each judge runs in its own process group, which the watchdog stops whole\nSP="$1"; WT="$2"; DRY="${DRY:-0}"; SHARD="${SHARD:-0/1}"; ONLY="${ONLY:-}"; WATCHDOG="${WATCHDOG:-900}"\n')
rep('# Usage: bash r18-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n] [ONLY=id,id...]\n',
    '# Usage: bash r18-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n] [ONLY=id,id...] [WATCHDOG=seconds, 900]\n')
D02O = ("row D02 equiv '' \"$GC\" \"$RL\" \\\n"
        "  \"$VL\" '    if (vf_settled(vf_run_text[k])) vf_run_done[k] = 1' '    if (0) vf_run_done[k] = 1'\n"
        "# D02 argued: a candidate never dropped is T030o47's reader, which reads every candidate on every line, so the\n"
        "# verdicts and diagnostics are the same and only the cost changes (measured: r17-measure, section E).")
D02N = ("row D02 kill 'watchdog: judge stopped after' \"$GC\" \"$RL\" \\\n"
        "  \"$VL\" '    if (vf_settled(vf_run_text[k])) vf_run_done[k] = 1' '    if (0) vf_run_done[k] = 1'\n"
        "# D02 (v6): a kill now. A candidate never dropped is T030o47's reader, whose verdicts are the same, but the 400-line\n"
        "# timing row (T030o53, O-023) bounds the cost: in matrix run 1 that run had taken 624 s when it was stopped, its\n"
        "# timing assertion failing, so its judge is stopped by the watchdog (r18-mutations-run1.note).")
rep(D02O, D02N)
# D11: the escape step of vf_settled_brackets matters to the readings as written alone, since the rendered readings
# take escaped brackets out before they pair brackets (r18-mutations-run1.note, r18-rows-probe-4).
i = t.index('row D11 kill '); j = t.index('\n', t.index('\n', i) + 1) + 1
seg = t[i:j]; old = 'row D11 kill "$LR image-alt-holding-escaped-bracket-across-lines $LS" '; assert seg.count(old) == 1
t = t[:i] + seg.replace(old, "row D11 equiv '' ") + (
    "# D11 argued (v6): the escape step matters to the readings as written alone (the text and its inert code-span\n"
    "# reading): the rendered readings take escaped brackets out before they pair brackets (vf_label_links), so a\n"
    "# bracket that only an escaped one would close stays open before the first word there and keeps the candidate.\n"
    "# Without the step, a reading as written only fails more often (an escaped bracket counted open or stray, or an\n"
    "# escaped `]` before a `(` read as a destination), or passes where a rendered reading already fails, so no\n"
    "# candidate is dropped that is kept now (r18-mutations-run1.note; r18-rows-probe-4: an escaped bracket before the\n"
    "# first word is refused under it too).\n") + t[j:]
# The settled test: brackets are read up to each reading's first word, inside vf_settled_word (T030o53).
i = t.index('row D05 kill '); j = t.index('row D08 kill ')
t = t[:i] + row('D05', 'S01', 'kill', '"$LR image-alt-across-three-lines $LS"', note='D05 (v6: discovery S01): the bracket test of every reading dropped.') \
    + row('D06', 'S06', 'kill', '"$LR link-title-across-three-lines $LS"', note='D06 (v6: discovery S06): the bracket test of the reading as written dropped.') \
    + 'row D07 kill "$LR image-alt-beginning-with-code-span-across-lines $LS" "$GC" "$RL" \\\n  "$VL" ' \
    + q('  if (c != j && (!vf_settled_word(c) || !vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0') + ' ' \
    + q('  if (c != j && (!vf_settled_lead(c) || !vf_settled_lead(vf_label_render(c, 0)) || !vf_settled_lead(vf_label_render(c, 1)))) return 0') + '\n' \
    + '# D07 (v6): the bracket tests of the inert code-span reading and of its two rendered readings dropped.\n' + t[j:]
i = t.index("row D12 equiv '' "); j = t.index("row D16 equiv '' ")
t = t[:i] + '''row D12 kill "$LR image-alt-across-three-lines $LS" "$GC" "$RL" \\
  "$VL" ''' + q('  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0') + " '  if (0) return 0'\n" \
    + '# D12 (v6): a kill now, since the reading test of the text as written also tests its brackets (T030o53).\n' \
    + row('D13', 'S10', 'kill', '"$LR image-alt-beginning-with-code-span-across-lines $LS"', note='D13 (v6: discovery S10): a kill now, through the row whose image alt begins with a code span holding `]`.') \
    + '''row D14 kill "$LR break-image-outside-finding-after-id $LS" "$GC" "$RL" \\
  "$VL" '  return !index(c, "<") || vf_settled_breaks(j, c)' '  return 1'
# D14 (v6): a kill now, outside every finding after a finding ID, where a br is not refused by name.
row D15 equiv '' "$GC" "$RL" \\
  "$VL" $'  return t != ""\\n}\\nfunction vf_settled_head' $'  return 1\\n}\\nfunction vf_settled_head'
# D15 argued: a candidate every other condition shows settled, but one of whose readings holds no first word yet,
# reads every later line in that reading as the candidate starting at the next line reads it, since no construct spans
# the boundary: its head is then the whole reading, so every bracket pair and destination in it is closed, as every
# code span and raw-HTML construct is; that candidate is read too, so dropping the first loses no label.
''' + t[j:]
i = t.index("row D19 equiv '' "); j = t.index("row D20 equiv '' ")
t = t[:i] + '''row D19 kill "$LR break-image-outside-finding-after-id $LS" "$GC" "$RL" \\
  "$VL" ''' + q('    if (!vf_settled_word(x) || !vf_settled_word(vf_label_render(x, 0)) || !vf_settled_word(vf_label_render(x, 1)) || !vf_settled_word(vf_label_render(substr(c, p + L), 0))) return 0') + " '    if (0) return 0'\n" \
    + '# D19 (v6): a kill now, as D14.\n' + t[j:]

LR = '"$LR %s $LS"'
ML_ = "'a plausible manifest (%s) was refused (T030o43 review 2)'"
new = "say '== the narrowed grammar further (T030o51, O-018): the autolink class and its reason'\n"
new += row('VA01', 'A01', 'kill', LR % 'autolink-digit-br')
new += row('VA01e', 'A01', 'kill', "'Note <1`@a.b><br>Severity: data-loss, tick: `. was not refused under LANG=C (T030o44 review)'", '$SG', '$RR')
new += row('VA02', 'A02', 'kill', LR % 'autolink-digit-br')
new += row('VA03', 'A03', 'kill', LR % 'autolink-underscore-p')
new += row('VA04', 'A04', 'kill', LR % 'autolink-backtick-start')
new += row('VA05', 'A05', 'kill', LR % 'autolink-plus')
new += row('VA06', 'A06', 'over', "'a canonical finding with a-escaped-lt was refused under LANG=C (O-018)'")
new += row('VA07', 'A07', 'kill', LR % 'autolink-digit-br')
new += "\nsay '== destinations, titles and labels read before a later backtick (T030o51, O-018): vf_cm_scan, vf_cm_dest, vf_cm_label'\n"
new += row('VB01', 'B01', 'kill', LR % 'destination-holding-backtick')
new += row('VB01e', 'B01', 'kill', "'[x](u`v)<br>Severity: data-loss, tick: `. was not refused under LANG=C (T030o44 review)'", '$SG', '$RR')
new += row('VB02', 'B02', 'kill', LR % 'label-holding-backtick')
new += row('VB04', 'B04', 'kill', LR % 'title-across-lines')
new += row('VB05', 'B05', 'kill', LR % 'destination-holding-backtick')
new += row('VB06', 'B06', 'over', ML_ % 'link-prose', case='$ML')
new += row('VB07', 'B07', 'equiv', "''", note='''VB07 argued: a destination, title or label holding a backtick and a later one on the same line that does not end
there are each a reason to refuse the line by name; the guard keeps the first, and without it the second names the
line, so the verdict is the same and only the diagnostic may change.''')
new += row('VB08', 'B08', 'kill', LR % 'destination-holding-backtick')
new += row('VB09', 'B09', 'kill', LR % 'title-across-lines')
for mid, kind, tag in (('C01', 'kill', 'destination-after-space'), ('C02', 'kill', 'destination-on-next-line'),
                       ('C03', 'kill', 'angle-destination-with-space'), ('C04', 'kill', 'angle-destination-escaped-gt'),
                       ('C05', 'over', 'invalid-angle-destination-holding-lt'), ('C06', 'over', 'unclosed-angle-destination'),
                       ('C07', 'kill', 'destination-escaped-paren'), ('C08', 'over', 'destination-with-space-then-code'),
                       ('C09', 'kill', 'destination-nested-parens'), ('C10', 'kill', 'destination-nested-parens'),
                       ('C11', 'kill', 'bare-destination-at-line-end'), ('C12', 'kill', 'title-holding-backtick'),
                       ('C13', 'kill', 'title-across-lines'), ('C14', 'kill', 'title-in-parens'),
                       ('C15', 'kill', 'title-escaped-quote'), ('C16', 'kill', 'title-across-lines'),
                       ('C17', 'kill', 'title-then-line-end'), ('C18', 'over', 'destination-then-code-span'),
                       ('C19', 'kill', 'destination-space-at-line-end'), ('L01', 'kill', 'label-escaped-bracket'),
                       ('L02', 'over', 'bracket-inside-label-position'), ('L03', 'kill', 'label-across-lines')):
    new += row('V' + mid, mid, kind, LR % tag if kind == 'kill' else ML_ % tag, case='$RL' if kind == 'kill' else '$ML')
new += "\nsay '== a fence that may be inside a list item, and a link reference definition (T030o52, O-024)'\n"
new += row('VF01', 'F01', 'kill', LR % 'fence-after-list-marker')
new += row('VF01e', 'F01', 'kill', "'- **Severity**: data-loss was not refused under LANG=C (T030o44 review)'", '$SG', '$RR')
new += row('VF02', 'F02', 'kill', LR % 'fence-after-list-marker')
new += row('VF03', 'F03', 'kill', LR % 'fence-after-ordered-marker')
new += row('VF04', 'F04', 'kill', LR % 'fence-after-ordered-marker')
new += row('VF05', 'F05', 'over', "'a Severity line followed by a four-backtick-fence was refused under LANG=C (O-021)'")
new += row('VF06', 'F06', 'over', "'a Severity line followed by a tilde-fence was refused under LANG=C (O-021)'")
new += row('VF07', 'F07', 'kill', LR % 'fence-swapping-phase')
new += row('VF08', 'F08', 'kill', LR % 'fence-after-tab')
new += row('VR01', 'R01', 'kill', LR % 'definition-hiding-severity')
new += row('VR01e', 'R01', 'kill', "'a CLEARED completion over a manifest tier hidden in a link reference definition was not refused under LANG=C (round 17, O-024)'", '$SG', '$RR')
new += row('VR02', 'R02', 'kill', LR % 'definition-in-list-item')
new += row('VR03', 'R03', 'kill', LR % 'definition-after-quote-marker', note='''VR03 (v6): session 19 listed R03 as an equivalent; a definition after a block-quote marker passes under it
(r18-rows-probe-2, r18-fixtures-judge-2-run3.note).''')
new += row('VR04', 'R04', 'kill', LR % 'definition-in-list-item')
new += row('VR05', 'R05', 'kill', LR % 'definition-escaped-label')
new += row('VR06', 'R06', 'over', ML_ % 'nested-bracket-then-colon-at-line-start', case='$ML')
new += row('VR07', 'R07', 'kill', LR % 'definition-label-across-lines')
new += row('VR08', 'R08', 'kill', LR % 'definition-label-across-lines')
new += row('VR09', 'R09', 'over', ML_ % 'bracket-left-open-before-blank-line', case='$ML')
new += row('VR10', 'R10', 'equiv', "''", note='''VR10 argued, on P21's premise: without it a definition label left open at the end of one file carries into the next
file the pass reads; every manifest and report begins with an ATX heading, which no reading takes for a definition
inside a finding (none is open at a file's first line) and which ends the run, resetting the carried label.''')
new += row('VR11', 'R11', 'over', ML_ % 'wrapped-link-text', case='$ML')
new += "\nsay '== the narrowed check judged after the heading on a line, in both passes (the round-17 minor, T030o51)'\n"
new += row('VH01', 'H01', 'over', ML_ % 'heading-with-tag-closes-finding', case='$ML')
new += row('VH02', 'H02', 'kill', LR % 'heading-tag-on-first-finding')
new += row('VH03', 'H03', 'kill', LR % 'heading-tag-on-deeper-heading')
new += row('VH04', 'H04', 'over', "'a later Finding heading carrying raw HTML was refused under the finding it closes under LANG=C (round 17)'")
new += row('VH05', 'H05', 'kill', "'a second tier written as title-tag-inside-finding was not refused by name under LANG=C (O-018)'")
new += row('VH06', 'H06', 'kill', "'the first Finding heading of a round carried raw HTML under LANG=C (round 17)'")
new += row('VH07', 'H07', 'kill', "'a second tier written as heading-tag-on-deeper-heading was not refused by name under LANG=C (O-018)'")
new += row('VH08', 'H08', 'equiv', "''", note='''VH08 argued: without the heading conjunct the check at a line's own heading also fires on every narrowed line that is
not a heading, which the main check above has already refused by name with the same diagnostic (a quoted line never
reaches it: its branch ends with next), so it only repeats a diagnostic.''')
new += row('VH09', 'H09', 'kill', LR % 'second-tier-after-empty-comment')
new += "\nsay '== the settled test read up to the first word of each reading (T030o53, O-023)'\n"
new += row('VS02', 'S02', 'kill', "'a 400-line run under a bracket quoted in a code span took'", note='''VS02: the whole reading taken for its head keeps every candidate with a bracket quoted in a code span unsettled, so
the 400-line timing row runs past its 60 s bound (about 340 s in r18-discover-c.log).''')
new += row('VS03', 'S03', 'kill', LR % 'ordered-number-then-image')
new += row('VS04', 'S04', 'equiv', "''", note='''VS04 and VS05 argued: the two rendered readings reduce the same links, images and footnote references, since they
are reduced before the readings diverge (a named or numeric reference beyond ASCII, and a byte beyond ASCII, is a
non-letter in the first and taken out in the second), so the brackets left before a reading's first word (an unclosed
`[`, a stray `]`, a task checkbox) are the same in both, in the same order, and each bracket test fails when the
other does. Where taking out joins a `]` to a `(`, only the second reads a destination there, and no line can make it
one, since links are reduced on the text before it is taken out; so either bracket test may go while the other stays.''')
new += row('VS05', 'S05', 'equiv', "''")
new += row('VS07', 'S07', 'kill', LR % 'image-title-across-lines-outside-finding-after-id', note='''VS07 and VS08 (v6): session 19 listed S07 and S08 as equivalents; outside every finding after a finding ID, an
image whose alt begins with a code span holding `]`, completed with a title across lines or after an inline tag,
hides the tier under them (r18-rows-probe-2, r18-fixtures-judge-2-run3.note).''')
new += row('VS08', 'S08', 'kill', LR % 'tag-image-alt-code-span-outside-finding-after-id')
new += row('VS09', 'S09', 'kill', LR % 'break-image-outside-finding-after-id')
new += '\n'
anchor = 'say "== done shard $SHARD $(date -u +%H:%M:%SZ) rows=$rowi"\n'
rep(anchor, new + anchor)
rep('say "r17-mutations failures=$fails"\n', 'say "r18-mutations failures=$fails"\n')
open(dst, 'w', encoding='utf-8').write(t)
print('ok')
