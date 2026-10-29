#!/usr/bin/env bash
. /private/tmp/rev2-t030o43/work/mut.sh
VL=scripts/verification-lib.sh; GC=test-gate-contracts.sh; SG=test-spec-gate.sh; TV=test-verification.sh
echo "== start $(date -u +%H:%M:%SZ)"
restore
# vf_blank reduced to the one sequence the fixture uses: every other White_Space member removed
row Y1 'a required section holding only a U+00A0 counted as a body' $GC report_manifest_locale_cases \
  "$VL" '      gsub(/[ \t\r\f\013]|\302[\205\240]|\341\232\200|\342\200[\200-\212\250\251\257]|\342\201\237|\343\200\200/, "", s)' '      gsub(/[ \t\r\f\013]|\302\240/, "", s)'
# the Decisions identity: first-only start (the repair) vs every-start (the class-wide fix) -- does the fixture tell them apart?
row Y2 'a Decisions log under a heading carrying a U+00A0 left the input identity' $TV harness_locale_cases \
  "$VL" $'      awk \'/^## Decisions log/ && !seen {on=1; seen=1; print; next}' $'      awk \'/^## Decisions log/ {on=1; print; next}'
# the artifact class: [^[:space:][:cntrl:]] vs taking any byte but the ASCII space
row Y3 'a missing non-ASCII artifact name passed under LANG=C' $SG floor_parse_fault_cases \
  scripts/spec-evidence.sh $'grep -oiE \'[^[:space:][:cntrl:]]+\\.(png|jpg|jpeg|gif|svg|pdf)\')"' $'grep -oiE \'[^ ]+\\.(png|jpg|jpeg|gif|svg|pdf)\')"'
echo "== end $(date -u +%H:%M:%SZ)"
