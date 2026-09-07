#!/usr/bin/env bash
# spec-gate.sh — deterministic verification and gate control.
# Usage: spec-gate.sh <floor|checkpoint|round|tally|accept> <spec-dir> [arguments]
#   checkpoint <spec-dir> <exact-stage> — run stage checks and retained coverage.
#   floor <spec-dir> — refresh current proof and execute all mandatory checks.
#   accept <spec-dir> <task> <return-file> — validate proof before one atomic tick.
#   tally <spec-dir> — report rounds, findings, locations and class recurrences.
# Exit: 0 success; 2 usage; 3 integrity/configuration gap; 4 round cap refusal.
set -uo pipefail
HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
. "$HUB_DIR/scripts/verification-lib.sh"
case "${1:-}" in --help|-h) usage_from_header "$0"; exit 0;; esac
[[ $# -ge 2 ]] || { usage_from_header "$0" >&2; exit 2; }
command_name="$1"; spec_dir="$2"; shift 2
[[ -d "$spec_dir" ]] || { echo 'spec directory missing' >&2; exit 2; }
case "$command_name" in
  checkpoint) [[ $# == 1 ]] || exit 2; vf_writer_init; vf_gate_checkpoint "$spec_dir" "$1";;
  floor) [[ $# == 0 ]] || exit 2; vf_writer_init; vf_gate_floor "$spec_dir";;
  accept) [[ $# == 2 ]] || exit 2; exec bash "$HUB_DIR/scripts/spec-task.sh" "done" "$spec_dir" "$1" --return-file "$2";;
  tally) [[ $# == 0 ]] || exit 2; vf_tally "$spec_dir";;
  *) echo 'unknown or unavailable gate operation' >&2; exit 2;;
esac
