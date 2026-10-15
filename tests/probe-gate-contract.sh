#!/usr/bin/env bash
# probe-gate-contract.sh — read-only live AC-016 wiring audit.
# Usage: probe-gate-contract.sh <spec-dir> [--task T029]
# Requires genuine rejection/acceptance, completed opponent, and an active
# or completed reality-check reservation. Not a default-suite prerequisite.
set -uo pipefail
HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
. "$HUB_DIR/scripts/verification-lib.sh"
[[ $# == 1 || ( $# == 3 && "$2" == --task ) ]] || exit 2
spec="$(cd "$1" && pwd -P)" || exit 3
task="${3:-T029}"
[[ "$task" =~ ^T[0-9][0-9][0-9][a-z0-9]*$ ]] || exit 2
tmp="$(mktemp -d "${TMPDIR:-/tmp}/vf-probe.XXXXXX")" || exit 3
trap 'rm -rf "$tmp"' EXIT
accepted='' rejected='' accepted_before='' accepted_time='' accepted_digest='' class=''
for event in "$spec"/notes/verification/accept-events/ACCEPT-*; do
  [[ -d "$event" ]] || continue
  vf_integrity "$event" meta.nul || exit 3
  vf_meta_load "$event/meta.nul" 'version task return_digest outcome reason class before after timestamp' || exit 3
  [[ "$(vf_meta_get task)" == "$task" && "$(vf_meta_get outcome)" == accepted ]] || continue
  accepted_before="$(vf_meta_get before)"
  accepted_time="$(vf_meta_get timestamp)"
  accepted_digest="$(vf_meta_get return_digest)"
  vf_utc_valid "$accepted_time" || exit 3
  for receipt in "$spec"/notes/verification/accepted/"$task"/ACC-*; do
    [[ -f "$receipt/COMMITTED" ]] || continue
    vf_integrity "$receipt" meta.nul return.txt tasks.after digests.nul || exit 3
    [[ "$(cat "$receipt/COMMITTED")" == "$(vf_hash "$receipt/COMPLETE")" && "$(vf_hash "$receipt/return.txt")" == "$accepted_digest" ]] || continue
    vf_return_check "$spec" "$task" "$receipt/return.txt" "$tmp/validated" >/dev/null || continue
    for negative in "$spec"/notes/verification/accept-events/ACCEPT-*; do
      vf_integrity "$negative" meta.nul || exit 3
      vf_meta_load "$negative/meta.nul" 'version task return_digest outcome reason class before after timestamp' || exit 3
      [[ "$(vf_meta_get task)" == "$task" && "$(vf_meta_get outcome)" == rejected &&
         "$(vf_meta_get before)" == "$accepted_before" && "$(vf_meta_get after)" == "$accepted_before" &&
         "$(vf_meta_get return_digest)" != "$accepted_digest" ]] || continue
      # AC-016 names one control: the deliberately incomplete FM/INV copy. Any
      # other rejection class is a different observation, and an event with no
      # recorded class predates typing, so neither can stand in for it.
      class="$(vf_meta_get class 2>/dev/null)" || class=''
      [[ "$class" == binding-mismatch ]] || continue
      stamp="$(vf_meta_get timestamp)"; vf_utc_valid "$stamp" || exit 3
      [[ ! "$stamp" > "$accepted_time" ]] || continue
      rejected="$negative"; accepted="$receipt"; break
    done
    [[ -z "$accepted" ]] || break
  done
  [[ -z "$accepted" ]] || break
done
[[ -n "$accepted" && -n "$rejected" ]] || { echo 'probe gap: authentic rejected-copy/intact-acceptance control missing or stale' >&2; exit 3; }
grep -qE "^- \[x\] \*\*$task\*\*" "$spec/tasks.md" || exit 3
for gate in opponent reality-check; do
  vf_round_history "$spec" "$gate" "$tmp" || exit 3
  found=0
  for ledger in "$spec"/notes/verification/rounds/"$gate"/ROUND-*; do
    [[ -d "$ledger" ]] || continue
    vf_integrity "$ledger" meta.nul || exit 3
    vf_meta_load "$ledger/meta.nul" 'version gate round floor source reserved' || exit 3
    [[ "$(vf_meta_get gate)" == "$gate" ]] || exit 3
    floor="$(vf_meta_get floor)"; source="$(vf_meta_get source)"
    [[ "$gate" != opponent || -f "$ledger/report.sha256" ]] || continue
    [[ "$(vf_floor_validate "$spec" "$floor")" == "$source" ]] || continue
    found=1
  done
  (( found )) || { echo "probe gap: $gate current reservation/floor observation missing" >&2; exit 3; }
done
printf 'live wiring PASS task=%s rejection=%s class=binding-mismatch acceptance=%s opponent=completed reality-check=reserved-or-completed\n' "$task" "${rejected##*/}" "${accepted##*/}"
