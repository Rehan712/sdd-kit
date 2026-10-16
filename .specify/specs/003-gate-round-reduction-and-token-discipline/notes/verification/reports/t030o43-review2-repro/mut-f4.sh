#!/usr/bin/env bash
. /private/tmp/rev2-t030o43/work/mut.sh
VL=scripts/verification-lib.sh
GC=test-gate-contracts.sh; SG=test-spec-gate.sh; SA=test-sdd-analyze.sh; TV=test-verification.sh
echo "== start $(date -u +%H:%M:%SZ)"
restore
base $SA analyzer_locale_and_fault_cases
row X5 'an id inventory that could not be sorted read as a short one (T030o43 review)' $SA analyzer_locale_and_fault_cases \
  "$VL" $'  printf \'%s\\n\' "$out" | LC_ALL=C sort -u - ||\n    { printf \'error: %s: ids matching %s could not be sorted\\n\' "$2" "$1" >&2; return 3; }' $'  printf \'%s\\n\' "$out" | LC_ALL=C sort -u -'
base $TV harness_locale_cases
row X1 "a record inherited beside another LC_ALL replaced the caller's value (T030o43 review)" $TV harness_locale_cases \
  "$VL" '  if [[ -z "${SDD_HARNESS_CALLER_LC_ALL:-}" || "${LC_ALL-}" != C ]]; then' '  if [[ -z "${SDD_HARNESS_CALLER_LC_ALL:-}" ]]; then'
row X2 'an unset caller LC_ALL was recorded as the pin (T030o43 review)' $TV harness_locale_cases \
  "$VL" $'      unset) return 1;;\n      set:*) printf' $'      set:*) printf'
base $GC report_manifest_locale_cases
row X3 'manifest records that could not be sorted were read as none (T030o43 review)' $GC report_manifest_locale_cases \
  "$VL" $'    records="$(LC_ALL=C sort -u "$tmp")" ||\n      { printf \'report recovery: %s: prior-review manifest records could not be sorted\\n\' "$manifest" >&2; return 3; }' $'    records="$(LC_ALL=C sort -u "$tmp")"'
row X4 'a class table that could not be sorted went missing from the tally (T030o43 review)' $GC report_manifest_locale_cases \
  "$VL" $'  LC_ALL=C sort "$tmp/class-lines" || { echo \'tally: the class table could not be sorted\' >&2; return 3; }' $'  LC_ALL=C sort "$tmp/class-lines"'
echo "== end $(date -u +%H:%M:%SZ)"
