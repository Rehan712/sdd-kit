#!/usr/bin/env bash
set -euo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/r9-audit.XXXXXX")"
trap 'rm -rf "$t"' EXIT
for gate in opponent reality-check; do
  vf_round_history "$s" "$gate" "$t"
  pending=0
  for ledger in "$s/notes/verification/rounds/$gate"/ROUND-*; do
    vf_integrity "$ledger" meta.nul
    [[ -f "$ledger/report.sha256" ]] || pending=$((pending+1))
  done
  printf '%s sealed rounds=%s pending=%s\n' "$gate" "$VF_ROUND_LAST" "$pending"
  [[ "$pending" == 0 ]]
done
for n in 1 2 3 4 5 6 7 8 9; do
  vf_report_block "$s/notes/opponent.md" "$n" > "$t/block-$n"
  d="$(vf_hash "$t/block-$n")"
  [[ "$d" == "$(cat "$s/notes/verification/rounds/opponent/ROUND-$n/report.sha256")" ]]
  printf 'opponent round %s sealed digest matches: %s\n' "$n" "${d:0:16}"
done
vf_report_block "$r/opponent-round9.md" 9 > "$t/returned-9"
cmp "$t/block-9" "$t/returned-9"
printf 'round 9 canonical/returned/ledger digest=%s\n' "$(vf_hash "$t/block-9")"
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
[[ "$src" == aa18111b6dbe36a6d75e923129802ffa7c688dddedc9a7ec811c350dd7bc66c4 ]]
printf 'source unchanged=%s\n' "$src"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"
dd="$(vf_hash "$t/decisions")"
[[ "$dd" == 98c1ec6a9a37d16f8c9a39dd23ef0168112356de4ee4cd5b4aad788412955093 ]]
printf 'Decisions unchanged=%s\n' "$dd"
[[ "$(vf_floor_validate "$s" FLOOR-k1reWt)" == "$src" ]]
printf 'FLOOR-k1reWt still current\n'
[[ ! -d "$s/notes/verification/lock" ]]
printf 'lock=absent HEAD=%s\n' "$(git rev-parse --short HEAD)"
for task in T030 T031 T032 T033 T034; do grep -F -- "- [ ] **$task**" "$s/tasks.md" > /dev/null; done
printf 'T030-T034 unchecked\n'
set +e
bash scripts/spec-gate.sh waiver "$s" opponent 10 > "$t/w10.log" 2>&1
rc=$?
set -e
printf 'round-10 waiver check exit=%s (%s)\n' "$rc" "$(head -1 "$t/w10.log")"
[[ "$rc" == 4 ]]
printf 'r9 final audit PASS\n'
