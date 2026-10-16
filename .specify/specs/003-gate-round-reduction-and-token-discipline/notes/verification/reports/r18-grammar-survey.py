# Read-only survey, 2026-10-09 (session 19): what the further narrowing the user chose for round 17's O-018 and O-024
# (2026-10-09: narrow both) would meet in the recorded history. Pattern: r17-grammar-survey.py. Inside every finding
# (a heading whose text is Finding <ID>, to the next heading as shallow), count the lines carrying:
#  (a) a `<` that may open an email autolink and not raw HTML (one followed by a digit or a symbol an email address's
#      local part may begin with, CommonMark 0.31.2 6.5) outside a code span, by the 6.1 left-to-right reading;
#  (b) a backtick inside an inline link's destination or title, or inside a full reference link's label (6.3), each
#      parsed from `](` or `][` wherever it stands on the line;
#  (c) a destination, title or label that does not end on its line (one may continue on the next line);
#  (d) a code fence (three or more backticks or tildes) that is not at column 0: after indentation, or after a list
#      marker run, or both (4.5, 5.2); column-0 fences are counted for the record;
#  (e) a line whose text, after indentation, list markers and block-quote markers, begins with `[` and either closes
#      it at once followed by `:` (a link reference definition, 4.7) or does not close it on the line;
#  (f) for the round-17 minor: the Finding heading line itself, and a heading that closes a finding, with a `<` that
#      may open raw HTML or an autolink outside a code span;
#  (g) for O-023, a code span that holds an unbalanced `[` or `]` (the reviewer counted seven in 003).
# Every hit is printed with its file and line. Run from the worktree root: python3 -I <this>.
import glob, re
specs = '.specify/specs'
rep = specs + '/003-gate-round-reduction-and-token-discipline/notes/verification/reports'
files = sorted(glob.glob(specs + '/*/notes/opponent.md') + glob.glob(specs + '/*/notes/reality-check.md'))
files += [rep + '/opponent-findings-2026-09-09.md', rep + '/opponent-round3-reconcile.md']
files += sorted(glob.glob(rep + '/opponent-round[0-9].md') + glob.glob(rep + '/opponent-round[0-9][0-9].md'))
PUNCT = set('!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~')
HTML = re.compile(r'[A-Za-z/!?]')
AUTO = re.compile(r"[0-9.#$%&'*+=^_`{|}~-]")
def spans(line):
    """the code spans of a line by the 6.1 left-to-right reading: list of (start, end) of span content, and the
    positions of every `<` outside a span"""
    i, n, sp, lt = 0, len(line), [], []
    while i < n:
        c = line[i]
        if c == '\\' and i + 1 < n and line[i + 1] in PUNCT: i += 2; continue
        if c == '`':
            j = i
            while j < n and line[j] == '`': j += 1
            run = j - i; k = j; close = -1
            while k < n:
                if line[k] == '`':
                    m = k
                    while m < n and line[m] == '`': m += 1
                    if m - k == run: close = m; break
                    k = m
                else: k += 1
            if close < 0: i = j; continue
            sp.append((j, close - run)); i = close; continue
        if c == '<': lt.append(i)
        i += 1
    return sp, lt
def dest_end(s, j):
    """s[j] is the `(` after `]`: the index after the closing `)`, -1 when the line ends while the destination or
    title may still continue, 0 when it cannot be one"""
    n = len(s); j += 1
    while j < n and s[j] in ' \t': j += 1
    if j >= n: return -1
    if s[j] == '<':
        j += 1
        while j < n and s[j] != '>':
            if s[j] == '\\': j += 1
            elif s[j] == '<': return 0
            j += 1
        if j >= n: return 0
        j += 1
    else:
        depth = 0
        while j < n:
            c = s[j]
            if c == '\\': j += 2; continue
            if c in ' \t': break
            if c == '(': depth += 1
            elif c == ')':
                if depth == 0: break
                depth -= 1
            j += 1
        if j >= n: return -1
    while j < n and s[j] in ' \t': j += 1
    if j >= n: return -1
    c = s[j]
    if c in '"\'(':
        q = ')' if c == '(' else c; j += 1
        while j < n and s[j] != q:
            if s[j] == '\\': j += 1
            j += 1
        if j >= n: return -1
        j += 1
        while j < n and s[j] in ' \t': j += 1
        if j >= n: return -1
    return j + 1 if j < n and s[j] == ')' else 0
def label_end(s, j):
    """s[j] is the `[` after `]`: the index after the label's `]`, -1 when the line ends inside it, 0 when not one"""
    n = len(s); j += 1
    while j < n and s[j] != ']':
        if s[j] == '\\': j += 1
        elif s[j] == '[': return 0
        j += 1
    return -1 if j >= n else j + 1
heading = re.compile(r'^ {0,3}(#{1,6})([ \t]|$)')
fhead = re.compile(r'^ {0,3}#{1,6}[ \t]+[Ff]inding[^A-Za-z0-9]+[A-Za-z][A-Za-z0-9]*-[0-9]')
lead = re.compile(r'^[ \t]*((>[ \t]?)*([-+*]|[0-9]+[.)])[ \t]+)*(>[ \t]?)*')
fence = re.compile(r'^(?P<pre>[ \t]*(?:(?:[-+*]|[0-9]+[.)])[ \t]+)*)(?:```|~~~)')
tot = dict.fromkeys(['finding_lines', 'a_autolink', 'b_tick_in_dest', 'b_tick_in_dest_outside_spans', 'c_open_dest',
                     'd_fence_not_col0', 'd_fence_col0', 'e_refdef', 'e_unclosed_bracket', 'f_heading_open',
                     'f_heading_close', 'g_span_bracket'], 0)
def hit(k, f, no, line):
    tot[k] += 1; print('%s %s:%d: %s' % (k.upper(), f, no, line[:220]))
for f in files:
    data = open(f, 'rb').read().decode('utf-8', 'replace')
    level = 0
    for no, line in enumerate(data.split('\n'), 1):
        h = heading.match(line)
        if h:
            sp, lt = spans(line)
            html = [p for p in lt if p + 1 < len(line) and (HTML.match(line[p + 1]) or AUTO.match(line[p + 1]))]
            if fhead.match(line):
                if html: hit('f_heading_open', f, no, line)
                level = len(h.group(1)); continue
            if level and len(h.group(1)) <= level:
                if html: hit('f_heading_close', f, no, line)
                level = 0
        if not level: continue
        tot['finding_lines'] += 1
        sp, lt = spans(line)
        insp = lambda p: any(a <= p < b for a, b in sp)
        if any(p + 1 < len(line) and AUTO.match(line[p + 1]) and not HTML.match(line[p + 1]) for p in lt): hit('a_autolink', f, no, line)
        bad = badout = opn = False
        for m in re.finditer(r'\]\(|\]\[', line):
            j = m.start() + 1
            e = dest_end(line, j) if line[j] == '(' else label_end(line, j)
            seg = line[j:] if e == -1 else (line[j:e] if e > 0 else '')
            if e == -1: opn = True
            if '`' in seg:
                bad = True
                if not insp(m.start()): badout = True
        if bad: hit('b_tick_in_dest', f, no, line)
        if badout: tot['b_tick_in_dest_outside_spans'] += 1
        if opn: hit('c_open_dest', f, no, line)
        fm = fence.match(line)
        if fm:
            if fm.group('pre'): hit('d_fence_not_col0', f, no, line)
            else: tot['d_fence_col0'] += 1
        t = line[lead.match(line).end():]
        if t.startswith('['):
            k, n2 = 1, len(t)
            while k < n2 and t[k] != ']':
                if t[k] == '\\': k += 1
                k += 1
            if k >= n2: hit('e_unclosed_bracket', f, no, line)
            elif k + 1 < n2 and t[k + 1] == ':': hit('e_refdef', f, no, line)
        if any(line[a:b].count('[') != line[a:b].count(']') for a, b in sp): tot['g_span_bracket'] += 1
print('files=%d %s' % (len(files), ' '.join('%s=%d' % kv for kv in tot.items())))
