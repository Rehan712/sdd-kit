#!/usr/bin/env python3
# Session 22 (2026-10-15): finish opponent-round19-brief.md from its draft (pattern: r18-brief-fill.py). The
# reservation's source, floor and reserved time come from ROUND-19/meta.nul itself (NUL-framed key/value pairs), never from typed text; the date
# written, the free disk and the floor-run sentence are arguments. Refuses when the output exists, when a value is
# missing, or when any @@ placeholder survives (the waiver and acceptance ones are filled before this runs). Writes UTF-8 bytes, no carriage return.
# Usage from the worktree root: python3 -I <this> <written> <disk> <floorrun-text-file>
import os, sys
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
draft, out = rep + '/opponent-round19-brief.draft.md', rep + '/opponent-round19-brief.md'
meta = spec + '/notes/verification/rounds/opponent/ROUND-19/meta.nul'
written, disk, runfile = sys.argv[1], sys.argv[2], sys.argv[3]
assert not os.path.exists(out), 'refusing: %s exists' % out
f = open(meta, 'rb').read().decode('utf-8').split('\0')
kv = {}
for i in range(0, len(f) - 1, 2):
    kv.setdefault(f[i], f[i + 1])
for k in ('round', 'source', 'floor', 'reserved'):
    assert kv.get(k), 'meta.nul lacks %s' % k
assert kv['round'] == '19', kv['round']
floorrun = open(runfile, encoding='utf-8').read().strip()
assert floorrun and '\n\n' not in floorrun
text = open(draft, encoding='utf-8').read()
assert text.count('@@WRITTEN@@ by the invoker (session 22).') == 1, 'draft lacks the written line'
for ph, val in (('@@WRITTEN@@', written), ('@@SOURCE@@', kv['source']), ('@@FLOOR@@', kv['floor']),
                ('@@RESERVED@@', kv['reserved']), ('@@DISK@@', disk), ('@@FLOORRUN@@', floorrun)):
    assert ph in text, 'draft lacks ' + ph
    text = text.replace(ph, val)
assert '@@' not in text, 'a placeholder survives'
assert '\r' not in text
open(out, 'wb').write(text.encode('utf-8'))
print('round=%s source=%s floor=%s reserved=%s' % (kv['round'], kv['source'], kv['floor'], kv['reserved']))
