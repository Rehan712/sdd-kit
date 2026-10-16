#!/usr/bin/env python3
# Session 23 (2026-10-15): finish reality-check-round3-brief.md from its draft (pattern: rc2-brief-fill.py). The
# reservation's source, floor and reserved time come from rounds/reality-check/ROUND-3/meta.nul itself (NUL-framed key/value
# pairs), never from typed text; the date written and the floor-run, opponent, control and CI sentences come from a JSON
# file of strings. Refuses when the output exists, when a value is missing, or when any @@ placeholder survives.
# Usage from the worktree root: python3 -I <this> <written> <values.json>
import json, os, sys
spec = '.specify/specs/003-gate-round-reduction-and-token-discipline'
rep = spec + '/notes/verification/reports'
draft, out = rep + '/reality-check-round3-brief.draft.md', rep + '/reality-check-round3-brief.md'
meta = spec + '/notes/verification/rounds/reality-check/ROUND-3/meta.nul'
written, valfile = sys.argv[1], sys.argv[2]
assert not os.path.exists(out), 'refusing: %s exists' % out
f = open(meta, 'rb').read().decode('utf-8').split('\0')
kv = {}
for i in range(0, len(f) - 1, 2):
    kv.setdefault(f[i], f[i + 1])
for k in ('gate', 'round', 'source', 'floor', 'reserved'):
    assert kv.get(k), 'meta.nul lacks %s' % k
assert kv['gate'] == 'reality-check' and kv['round'] == '3', (kv['gate'], kv['round'])
vals = json.load(open(valfile, encoding='utf-8'))
text = open(draft, encoding='utf-8').read()
for ph, val in (('@@WRITTEN@@', written), ('@@RESERVED@@', kv['reserved']), ('@@SOURCE@@', kv['source']),
                ('@@FLOOR@@', kv['floor']), ('@@FLOORRUN@@', vals['floorrun']), ('@@OPPONENT@@', vals['opponent']),
                ('@@CONTROL@@', vals['control']), ('@@CI@@', vals['ci'])):
    assert val and '\n' not in val, 'empty or multi-line value for ' + ph
    assert text.count(ph) == 1, 'draft lacks exactly one ' + ph
    text = text.replace(ph, val)
assert '@@' not in text, 'a placeholder survives'
assert '\r' not in text
open(out, 'wb').write(text.encode('utf-8'))
print('gate=%s round=%s source=%s floor=%s reserved=%s' % (kv['gate'], kv['round'], kv['source'], kv['floor'], kv['reserved']))
