#!/usr/bin/env bash
set -uo pipefail
HUB_DIR="$PWD"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
[[ "$(cat "$r/t031-complete.rc")" == 0 && "$(cat "$r/t031-tally.rc")" == 0 ]] || exit 3
t="$r/t031-final-audit"
mkdir -p "$t"
for gate in opponent reality-check; do
  vf_round_history "$s" "$gate" "$t" || exit $?
  printf '%s rounds=%s sealed history validated\n' "$gate" "$VF_ROUND_LAST"
done
vf_report_block "$s/notes/reality-check.md" 1 > "$t/canonical-block.md" || exit $?
vf_report_block "$r/reality-check-round1.md" 1 > "$t/returned-block.md" || exit $?
cmp "$t/canonical-block.md" "$t/returned-block.md" || exit $?
digest="$(vf_hash "$t/canonical-block.md")"
[[ "$digest" == "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")" ]] || exit 3
printf 'reality-check:1 report digest=%s canonical/returned/ledger match\n' "$digest"
vf_semantic_file .specify/specs/003-gate-round-reduction-and-token-discipline/STATUS.md "$s/STATUS.md" "$t/decisions.md" || exit $?
[[ "$(vf_hash "$t/decisions.md")" == "$(cat "$r/t031-decisions.sha256")" ]] || exit 3
printf 'Decisions unchanged\n'
[[ ! -d "$s/notes/verification/lock" ]] || exit 3
[[ "$(git rev-parse --short HEAD)" == 0d55c62 ]] || exit 3
for task in T030 T031 T032 T033 T034; do
  grep -F -- "- [ ] **$task**" "$s/tasks.md" || exit 3
done
printf 'HEAD=0d55c62; no held lock; T030-T034 unchecked\n'
