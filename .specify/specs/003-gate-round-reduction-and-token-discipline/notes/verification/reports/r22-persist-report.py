#!/usr/bin/env python3
# Session 24 (2026-10-16): persist the round-22 opponent's returned report, byte-exact, from the agent's own transcript (the
# `message` of its last SubagentHandback call), as for round 21 (r21-persist-report.py). Checks that
# the block starts with `## Round 22`, ends with the completion marker and one newline, holds no carriage return, and,
# if the report file already exists (the agent wrote it), that it is byte-identical. Prints the sha256 and size.
# Usage: python3 -I <this> <agent transcript .jsonl> <report path> [<sha256 the reviewer stated>]
import hashlib, json, os, sys
tr, out = sys.argv[1], sys.argv[2]
msgs = []
for line in open(tr, encoding='utf-8'):
    try:
        o = json.loads(line)
    except Exception:
        continue
    if o.get('type') != 'assistant':
        continue
    for c in (o.get('message') or {}).get('content') or []:
        if c.get('type') == 'tool_use' and c.get('name') == 'SubagentHandback':
            msgs.append((c.get('input') or {}).get('message', ''))
assert msgs, 'no SubagentHandback call in the transcript'
block = msgs[-1]
# A hand-back (as round 21's) carries a preamble before the block: cut at the block's own heading line.
if not block.startswith('## Round 22\n'):
    assert block.count('\n## Round 22\n') == 1, 'no single block heading'
    block = block[block.index('\n## Round 22\n') + 1:]
marker = '<!-- gate-round-end: opponent:22 -->'
if not block.endswith('\n'):
    block += '\n'
assert block.startswith('## Round 22\n'), block[:40]
assert block.rstrip('\n').endswith(marker), block[-80:]
assert block.endswith(marker + '\n'), 'more than one newline after the marker'
assert '\r' not in block
data = block.encode('utf-8')
if os.path.exists(out):
    assert open(out, 'rb').read() == data, 'existing report differs from the returned block'
    print('existing report equals the returned block')
else:
    open(out, 'wb').write(data)
    print('persisted')
if len(sys.argv) > 3:
    assert hashlib.sha256(data).hexdigest() == sys.argv[3], 'block differs from the digest the reviewer stated'
    print('matches the reviewer-stated sha256')
print('handbacks=%d sha256=%s bytes=%d lines=%d' % (len(msgs), hashlib.sha256(data).hexdigest(), len(data), block.count('\n')))
