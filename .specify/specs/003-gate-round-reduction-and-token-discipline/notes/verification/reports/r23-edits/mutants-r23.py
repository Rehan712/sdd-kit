#!/usr/bin/env python3
# Session 25 (2026-10-17): r22-edits/mutants-r22.py (opponent rounds 20 and 21, 17 mutants) plus the eleven round 22
# ran against T031a4o2 (hour, minute, maxeod, samedaymid, laterday, futureday, futureyear, recvalid, nextmid,
# clampnext, noon), copied verbatim from the reviewer's work dir. Each is an exact-anchor edit of
# scripts/verification-lib.sh that refuses unless its anchor occurs once.
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
  # Round 22 reviewer (opponent-round22.md; /private/tmp/opp22/scripts/mut.py), copied verbatim:
  # read path: the record's time truncated to its hour / minute (round-down readings of the record)
  'hour': [(TIME, '''    VF_ROUND_TIME="$(vf_meta_get timestamp)"; VF_ROUND_TIME="${VF_ROUND_TIME:0:13}:00:00Z"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')],
  'minute': [(TIME, '''    VF_ROUND_TIME="$(vf_meta_get timestamp)"; VF_ROUND_TIME="${VF_ROUND_TIME:0:16}:00Z"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')],
  # read path: never earlier than the end of the history's date (fails closed for a same-day record)
  'maxeod': [(TIME, '''    VF_ROUND_TIME="$(vf_meta_get timestamp)"; [[ "$VF_ROUND_TIME" < "${VF_ROUND_DATE}T23:59:59Z" ]] && VF_ROUND_TIME="${VF_ROUND_DATE}T23:59:59Z"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')],
  # read path: a record on the history's own date read as that date's midnight (fails open for a same-day record)
  'samedaymid': [(TIME, '''    VF_ROUND_TIME="$(vf_meta_get timestamp)"; [[ "${VF_ROUND_TIME:0:10}" == "$VF_ROUND_DATE" ]] && VF_ROUND_TIME="${VF_ROUND_DATE}T00:00:00Z"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')],
  # reconcile guard: a record must fall on a LATER day than the history's date (refuses every same-day record)
  'laterday': [(GUARD, '''    [[ "${stamp:0:10}" > "$VF_ROUND_DATE" && ! "$stamp" > "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ]] || return 3
''')],
  # reconcile guard: future checked by date only (accepts a record later today)
  'futureday': [(GUARD, '''    [[ ! "${stamp:0:10}" < "$VF_ROUND_DATE" && ! "${stamp:0:10}" > "$(date -u +%Y-%m-%d)" ]] || return 3
''')],
  # reconcile guard: future checked by year only (accepts a record later this year)
  'futureyear': [(GUARD, '''    [[ ! "${stamp:0:10}" < "$VF_ROUND_DATE" && ! "${stamp:0:4}" > "$(date -u +%Y)" ]] || return 3
''')],
  # reconcile path: the record's timestamp no longer validated as a real UTC time before it is written
  'recvalid': [('''    stamp="$(vf_meta_get timestamp)"; vf_utc_valid "$stamp" || return 3
''', '''    stamp="$(vf_meta_get timestamp)"
''')],
  # read path: the history's date read as the next day's midnight (an exclusive end of day), ignoring the record
  'nextmid': [(TIME, '''    VF_ROUND_TIME="$(date -j -u -v+1d -f %Y-%m-%d "$VF_ROUND_DATE" +%Y-%m-%dT00:00:00Z)"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')],
  # read path: the record clamped to the next day's midnight when later
  'clampnext': [(TIME, '''    VF_ROUND_TIME="$(vf_meta_get timestamp)"; _n="$(date -j -u -v+1d -f %Y-%m-%d "$VF_ROUND_DATE" +%Y-%m-%dT00:00:00Z)"; [[ "$VF_ROUND_TIME" > "$_n" ]] && VF_ROUND_TIME="$_n"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')],
  # read path: the history's date read as its noon, ignoring the record
  'noon': [(TIME, '''    VF_ROUND_TIME="${VF_ROUND_DATE}T12:00:00Z"; vf_utc_valid "$VF_ROUND_TIME" || return 3
''')],
}
E['combined'] = E['readcheck'] + E['midnight'] + E['reccheck'] + E['recguard']
for old, new in E[m]:
    assert t.count(old) == 1, '%s: anchor count %d: %r' % (m, t.count(old), old[:80])
    t = t.replace(old, new)
open(p, 'w', encoding='utf-8').write(t)
print('mutant applied: %s (%d edit(s))' % (m, len(E[m])))
