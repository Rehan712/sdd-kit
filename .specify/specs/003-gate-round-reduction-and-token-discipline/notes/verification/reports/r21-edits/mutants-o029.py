#!/usr/bin/env python3
# The reviewer's three O-029 mutants (round 20), each an exact-anchor edit of scripts/verification-lib.sh.
# Usage: python3 -I <this> <lib> <timestamp|reconcile|combined>
import sys
p, m = sys.argv[1], sys.argv[2]
t = open(p, encoding='utf-8').read()
READ_CHECK = ('''    vf_meta_load "$spec/notes/verification/rounds/$gate/legacy-time.nul" 'round timestamp report_digest' || return 3
    [[ "$(vf_meta_get round)" == "$VF_ROUND_LAST" && "$(vf_meta_get report_digest)" == "$(vf_hash "$spec/notes/$gate.md")" ]] || return 3
''', '''    vf_meta_load "$spec/notes/verification/rounds/$gate/legacy-time.nul" 'round timestamp report_digest' || return 3
''')
TIME = ('''    VF_ROUND_TIME="$(vf_meta_get timestamp)"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''', '''    VF_ROUND_TIME="${VF_ROUND_DATE}T00:00:00Z"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')
REC_CHECK = ('''    vf_meta_load "$report" 'round timestamp report_digest' || return 3
    [[ "$(vf_meta_get round)" == "$VF_ROUND_LAST" && "$(vf_meta_get report_digest)" == "$(vf_hash "$spec/notes/$gate.md")" ]] || return 3
''', '''    vf_meta_load "$report" 'round timestamp report_digest' || return 3
''')
REC_DATE = ('''    [[ ! "${stamp:0:10}" < "$VF_ROUND_DATE" && ! "$stamp" > "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ]] || return 3
''', '')
edits = {'timestamp': [TIME], 'reconcile': [REC_CHECK], 'combined': [READ_CHECK, TIME, REC_CHECK, REC_DATE]}[m]
for old, new in edits:
    assert t.count(old) == 1, 'anchor count %d: %r' % (t.count(old), old[:80])
    t = t.replace(old, new)
open(p, 'w', encoding='utf-8').write(t)
print('mutant applied: %s (%d edit(s))' % (m, len(edits)))
