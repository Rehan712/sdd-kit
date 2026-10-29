#!/usr/bin/env python3
# Session 24 (2026-10-16): every mutant opponent rounds 20 and 21 ran against the T031a fixtures, each an exact-anchor
# edit of scripts/verification-lib.sh that refuses unless its anchor occurs once. O-029 (round_legacy_reconcile_cases):
# round 21's twelve (midnight, readcheck, readdigest, readround, reccheck, recdigest, recround, recguard, recbefore,
# endofday, clamp, future) and round 20's combined one. O-030 (acceptance_named_cases): explicitnone. O-031
# (shipped_002_tally_case, tally_class_cases): tallyappend, tallytouch, tallynewline.
# Usage: python3 -I <this> <lib> <mutant>
import sys
p, m = sys.argv[1], sys.argv[2]
t = open(p, encoding='utf-8').read()
CHECK = r'''    [[ "$(vf_meta_get round)" == "$VF_ROUND_LAST" && "$(vf_meta_get report_digest)" == "$(vf_hash "$spec/notes/$gate.md")" ]] || return 3
'''
ROUND_ONLY = r'''    [[ "$(vf_meta_get round)" == "$VF_ROUND_LAST" ]] || return 3
'''
DIGEST_ONLY = r'''    [[ "$(vf_meta_get report_digest)" == "$(vf_hash "$spec/notes/$gate.md")" ]] || return 3
'''
READ_PRE = r'''    vf_meta_load "$spec/notes/verification/rounds/$gate/legacy-time.nul" 'round timestamp report_digest' || return 3
'''
REC_PRE = r'''    vf_meta_load "$report" 'round timestamp report_digest' || return 3
'''
TIME = r'''    VF_ROUND_TIME="$(vf_meta_get timestamp)"; vf_utc_valid "$VF_ROUND_TIME" || return 3
'''
GUARD = r'''    [[ ! "${stamp:0:10}" < "$VF_ROUND_DATE" && ! "$stamp" > "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ]] || return 3
'''
TALLY = r'''    printf '%s rounds=%s\n' "$gate" "$rounds"
'''
NONE = r'''  else (( none == 1 && ${#mappings[@]} == 0 )) ||'''
E = {
    'midnight': [(TIME, TIME.replace('"$(vf_meta_get timestamp)"', '"${VF_ROUND_DATE}T00:00:00Z"'))],
    'endofday': [(TIME, TIME.replace('"$(vf_meta_get timestamp)"', '"${VF_ROUND_DATE}T23:59:59Z"'))],
    'clamp': [(TIME, r'''    VF_ROUND_TIME="$(vf_meta_get timestamp)"; [[ "$VF_ROUND_TIME" > "${VF_ROUND_DATE}T23:59:59Z" ]] && VF_ROUND_TIME="${VF_ROUND_DATE}T23:59:59Z"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')],
    'readcheck': [(READ_PRE + CHECK, READ_PRE)],
    'readdigest': [(READ_PRE + CHECK, READ_PRE + ROUND_ONLY)],
    'readround': [(READ_PRE + CHECK, READ_PRE + DIGEST_ONLY)],
    'reccheck': [(REC_PRE + CHECK, REC_PRE)],
    'recdigest': [(REC_PRE + CHECK, REC_PRE + ROUND_ONLY)],
    'recround': [(REC_PRE + CHECK, REC_PRE + DIGEST_ONLY)],
    'recguard': [(GUARD, '')],
    'recbefore': [(GUARD, r'''    [[ ! "$stamp" > "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ]] || return 3
''')],
    'future': [(GUARD, r'''    [[ ! "${stamp:0:10}" < "$VF_ROUND_DATE" ]] || return 3
''')],
    'explicitnone': [(NONE, r'''  else (( ${#mappings[@]} == 0 )) ||''')],
    'tallyappend': [(TALLY, TALLY + r'''    if [[ -f "$spec/notes/$gate.md" ]]; then printf '<!-- tally mutant -->\n' >> "$spec/notes/$gate.md"; fi
''')],
    'tallytouch': [(TALLY, TALLY + r'''    : > "$spec/notes/.tally-mutant"
''')],
    'tallynewline': [(TALLY, TALLY + r'''    if [[ "$gate" == reality-check && -f "$spec/notes/reality-check.md" ]]; then printf '\n' >> "$spec/notes/reality-check.md"; fi
''')],
}
E['combined'] = E['readcheck'] + E['midnight'] + E['reccheck'] + E['recguard']
for old, new in E[m]:
    assert t.count(old) == 1, '%s: anchor count %d: %r' % (m, t.count(old), old[:80])
    t = t.replace(old, new)
open(p, 'w', encoding='utf-8').write(t)
print('mutant applied: %s (%d edit(s))' % (m, len(E[m])))
