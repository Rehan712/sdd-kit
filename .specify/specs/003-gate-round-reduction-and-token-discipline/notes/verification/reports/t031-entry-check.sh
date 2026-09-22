#!/usr/bin/env bash
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
t="$s/notes/verification/reports/t031-entry"
mkdir -p "$t"
check() { local rc=0; "$@" || rc=$?; printf 'exit=%s command=' "$rc"; printf '%q ' "$@"; printf '\n'; return "$rc"; }
check vf_round_history "$s" opponent "$t" || exit $?
printf 'opponent rounds=%s all sealed blocks validated\n' "$VF_ROUND_LAST"
check vf_round_history "$s" reality-check "$t" || exit $?
printf 'reality-check rounds=%s\n' "$VF_ROUND_LAST"
check vf_capture_check "$s" CAP-366-H7QjI6 '' integrity || exit $?
check vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul" || exit $?
check vf_capture_check "$s" CAP-366-H7QjI6 "$t/inputs.nul" current
for task in T030o37 T030o38; do
  for receipt in "$s/notes/verification/accepted/$task"/ACC-*; do
    check vf_integrity "$receipt" meta.nul return.txt tasks.after digests.nul || exit $?
    [[ "$(cat "$receipt/COMMITTED")" == "$(vf_hash "$receipt/COMPLETE")" ]] || exit 3
    printf '%s receipt=%s return=%s\n' "$task" "$receipt" "$(vf_hash "$receipt/return.txt")"
  done
done
check bash scripts/spec-gate.sh waiver "$s" opponent 9
check bash scripts/spec-gate.sh waiver "$s" reality-check 1 || exit $?
check vf_floor_validate "$s" FLOOR-bvsiKa
check bash scripts/spec-gate.sh tally "$s" || exit $?
check git rev-parse --short HEAD || exit $?
rg '^- \[[ x]\] \*\*T03[0-4]\*\*' "$s/tasks.md"
python3 - "$s" <<'PY'
import pathlib,sys
s=pathlib.Path(sys.argv[1]); r=s/'notes/verification/reports'
lines=(r/'repair-mutations-tightened.log').read_text().splitlines()
print('mutation kills=',sum(x.startswith('PASS ') and 'rc=1' in x for x in lines))
print('baseline=',[x for x in lines if x.startswith('PASS baseline')])
print('captures=',len(list((s/'notes/captures').glob('CAP-*'))))
print('lock exists=',(s/'notes/verification/lock').exists())
print('capture staging=',list((s/'notes').rglob('.capture.*')))
PY
