#!/usr/bin/env bash
# Read-only production-library probe; every STATUS/spec below is a fixture.
set -uo pipefail
probe_repo="${1:?Pass the spec worktree root}"
probe_fixtures="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$probe_repo" || exit 2
. scripts/lib.sh
. scripts/verification-lib.sh
probe_mismatches=0
probe_cases=0
for probe_case in "$probe_fixtures"/*; do
  [[ -d "$probe_case" && -f "$probe_case/STATUS.md" ]] || continue
  probe_name="${probe_case##*/}"
  case "$probe_name" in
    opponent-*) probe_gate=opponent;;
    reality-check-*) probe_gate=reality-check;;
    *) continue;;
  esac
  probe_expected=4
  case "$probe_name" in *-live) probe_expected=0;; esac
  probe_rc=0
  vf_round_authorized "$probe_case" "$probe_gate" 4 2026-09-08T00:00:00Z || probe_rc=$?
  printf '%s: expected=%s actual=%s\n' "$probe_name" "$probe_expected" "$probe_rc"
  probe_cases=$((probe_cases + 1))
  [[ "$probe_rc" == "$probe_expected" ]] || probe_mismatches=$((probe_mismatches + 1))
done
printf 'cases=%s mismatches=%s\n' "$probe_cases" "$probe_mismatches"
[[ "$probe_cases" == 20 && "$probe_mismatches" == 0 ]]
