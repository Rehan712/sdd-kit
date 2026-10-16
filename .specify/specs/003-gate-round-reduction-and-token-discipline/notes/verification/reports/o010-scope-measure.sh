#!/usr/bin/env bash
# usage: scan.sh <scripts-dir> <root> -- runs the live superseded_environment_scan with SCRIPTS pointed at a variant library
SCRIPTS="$1"; root="$2"
eval "$(sed -n '/^superseded_environment_scan() (/,/^)$/p' "$root/tests/test-gate-contracts.sh")"
superseded_environment_scan "$root"
