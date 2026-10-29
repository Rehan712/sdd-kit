#!/usr/bin/env python3
# Round 21's three surviving O-029 mutants, each an exact-anchor edit of scripts/verification-lib.sh.
# Usage: python3 -I <this> <lib> <endofday|clamp|future>
import sys
p, m = sys.argv[1], sys.argv[2]
t = open(p, encoding='utf-8').read()
TIME = '''    VF_ROUND_TIME="$(vf_meta_get timestamp)"; vf_utc_valid "$VF_ROUND_TIME" || return 3
'''
GUARD = '''    [[ ! "${stamp:0:10}" < "$VF_ROUND_DATE" && ! "$stamp" > "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ]] || return 3
'''
edits = {
    'endofday': [(TIME, '''    VF_ROUND_TIME="${VF_ROUND_DATE}T23:59:59Z"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')],
    'clamp': [(TIME, '''    VF_ROUND_TIME="$(vf_meta_get timestamp)"; [[ "$VF_ROUND_TIME" > "${VF_ROUND_DATE}T23:59:59Z" ]] && VF_ROUND_TIME="${VF_ROUND_DATE}T23:59:59Z"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')],
    'future': [(GUARD, '''    [[ ! "${stamp:0:10}" < "$VF_ROUND_DATE" ]] || return 3
''')],
}[m]
for old, new in edits:
    assert t.count(old) == 1, 'anchor count %d: %r' % (t.count(old), old[:80])
    t = t.replace(old, new)
open(p, 'w', encoding='utf-8').write(t)
print('mutant applied: %s' % m)
