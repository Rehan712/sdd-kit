# Read-only survey, 2026-10-08 (session 17): what the narrowed finding grammar the user chose for round 16's O-018
# would meet in the recorded history. Inside every finding (a heading whose text is Finding <ID>, to the next heading
# as shallow), count the lines carrying (a) a `<` followed by a letter, `/`, `!` or `?` outside a code span, by a
# CommonMark 6.1 left-to-right reading of the line (2.4 escapes consumed in pairs, a run closed only by the next run of
# equal length), (b) a form feed or vertical tab, (c) a carriage return that is not the last byte of the line; and,
# for the record, lines whose only such `<` lies inside a code span. Run from the worktree root: python3 -I <this>.
import glob, re, sys
specs = '.specify/specs'
rep = specs + '/003-gate-round-reduction-and-token-discipline/notes/verification/reports'
files = sorted(glob.glob(specs + '/*/notes/opponent.md') + glob.glob(specs + '/*/notes/reality-check.md'))
files += [rep + '/opponent-findings-2026-09-09.md', rep + '/opponent-round3-reconcile.md']
files += sorted(glob.glob(rep + '/opponent-round[0-9].md') + glob.glob(rep + '/opponent-round[0-9][0-9].md'))
PUNCT = set('!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~')
def outside(line):
    """yield (index, inside_span) for each tag-like < by a CommonMark-like left-to-right reading"""
    i, n, res = 0, len(line), []
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
            for p in range(j, close - run):
                if line[p] == '<' and p + 1 < n and re.match(r'[A-Za-z/!?]', line[p + 1]): res.append((p, True))
            i = close; continue
        if c == '<' and i + 1 < n and re.match(r'[A-Za-z/!?]', line[i + 1]): res.append((i, False))
        i += 1
    return res
heading = re.compile(r'^ {0,3}(#{1,6})([ \t]|$)')
fhead = re.compile(r'^ {0,3}#{1,6}[ \t]+[Ff]inding[^A-Za-z0-9]+[A-Za-z][A-Za-z0-9]*-[0-9]')
tot = {'html_out': 0, 'html_in_span_only': 0, 'ffvt': 0, 'lone_cr': 0, 'finding_lines': 0}
for f in files:
    data = open(f, 'rb').read().decode('utf-8', 'replace')
    lines = data.split('\n'); level = 0
    for no, line in enumerate(lines, 1):
        h = heading.match(line)
        if h:
            if fhead.match(line): level = len(h.group(1)); continue
            if level and len(h.group(1)) <= level: level = 0
        if not level: continue
        tot['finding_lines'] += 1
        hits = outside(line); out = [p for p, ins in hits if not ins]
        if out: tot['html_out'] += 1; print('HTML-OUT %s:%d: %s' % (f, no, line[:200]))
        elif hits: tot['html_in_span_only'] += 1
        if '\f' in line or '\v' in line: tot['ffvt'] += 1; print('FFVT %s:%d' % (f, no))
        if '\r' in line[:-1]: tot['lone_cr'] += 1; print('LONECR %s:%d' % (f, no))
print('files=%d %s' % (len(files), ' '.join('%s=%d' % kv for kv in tot.items())))
