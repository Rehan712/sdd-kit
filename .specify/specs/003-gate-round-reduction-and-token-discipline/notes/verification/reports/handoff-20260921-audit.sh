#!/usr/bin/env bash
set -euo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
t=/tmp/spec003-handoff.t56KXa
for gate in opponent reality-check; do
  vf_round_history "$s" "$gate" "$t"
  printf '%s sealed rounds=%s\n' "$gate" "$VF_ROUND_LAST"
  pending=0
  for ledger in "$s/notes/verification/rounds/$gate"/ROUND-*; do
    vf_integrity "$ledger" meta.nul
    if [[ ! -f "$ledger/report.sha256" ]]; then pending=$((pending+1)); fi
  done
  printf '%s pending=%s\n' "$gate" "$pending"
  [[ "$pending" == 0 ]]
done
vf_report_block "$s/notes/reality-check.md" 1 > "$t/canonical-block"
vf_report_block "$r/reality-check-round1.md" 1 > "$t/returned-block"
cmp "$t/canonical-block" "$t/returned-block"
digest="$(vf_hash "$t/canonical-block")"
[[ "$digest" == "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")" ]]
printf 'reality report canonical/returned/ledger=%s\n' "$digest"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"
digest="$(vf_hash "$t/decisions")"
[[ "$digest" == "$(cat "$r/t031-decisions.sha256")" ]]
printf 'Decisions unchanged=%s\n' "$digest"
[[ ! -d "$s/notes/verification/lock" ]]
printf 'lock=absent HEAD=%s\n' "$(git rev-parse HEAD)"
for task in T030 T031 T032 T033 T034; do
  grep -F -- "- [ ] **$task**" "$s/tasks.md"
done
vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul"
for cap in CAP-367-g14RVk CAP-384-nH42Di CAP-385-oU69jN CAP-386-fmjMGY CAP-387-kPL8E3 CAP-388-6uDX8d; do
  vf_capture_check "$s" "$cap" "$t/inputs.nul" current
  printf '%s current validation exit=0\n' "$cap"
done
for event in ACCEPT-ASelAO ACCEPT-5U1YH6; do
  vf_integrity "$s/notes/verification/accept-events/$event" meta.nul
  vf_meta_load "$s/notes/verification/accept-events/$event/meta.nul" 'version task return_digest outcome reason class before after timestamp'
  printf '%s outcome=%s before=%s after=%s timestamp=%s\n' "$event" "$(vf_meta_get outcome)" "$(vf_meta_get before)" "$(vf_meta_get after)" "$(vf_meta_get timestamp)"
done
receipt="$s/notes/verification/accepted/T029/ACC-Zx8W9q"
vf_integrity "$receipt" meta.nul return.txt tasks.after digests.nul
[[ "$(cat "$receipt/COMMITTED")" == "$(vf_hash "$receipt/COMPLETE")" ]]
printf 'T029 committed receipt integrity exit=0\n'
vf_integrity "$s/notes/verification/floors/FLOOR-NbXfe5" meta.nul commands.nul bindings.nul inputs.nul roots.nul
printf 'FLOOR-NbXfe5 integrity exit=0\n'
vf_matrix_parse "$t/canonical-block" "$t/matrix.nul"
awk -F '|' '/^\| AC-[0-9]/ {gsub(/ /,"",$6); n[$6]++; total++} END {printf "AC rows=%d PASS=%d FAIL=%d MISSING=%d\n",total,n["PASS"],n["FAIL"],n["MISSING"]}' "$t/canonical-block"
bash scripts/spec-gate.sh tally "$s"
set +e
bash scripts/spec-gate.sh waiver "$s" opponent 9 > "$t/waiver.log" 2>&1
rc=$?
printf '%s\n' "$rc" > "$t/waiver.rc"
set -e
cat "$t/waiver.log"
printf 'waiver actual exit=%s\n' "$rc"
[[ "$rc" == 4 ]]
printf 'handoff audit PASS\n'
