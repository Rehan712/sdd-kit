#!/usr/bin/env bash
# Build T030o42's Verification-Return block from its capture summary and validate it
# before acceptance, 2026-09-27. Run from the worktree root after t030o42-capture.rc reads 0.
# Pattern: returns/T030o41.txt. The rows are the task's declared FM/INV refs against its one
# Tests locator. Validation is the same pair spec-gate accept runs: vf_return_parse, then
# vf_return_check with a scratch receipt; neither ticks anything.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
[[ "$(cat "$r/t030o42-capture.rc" 2>/dev/null)" == 0 ]] || { echo 'capture rc is not 0' >&2; exit 3; }
summary="$(grep -E '^capture=CAP-[0-9]+-[A-Za-z0-9]+ ' "$r/t030o42-capture.log" | tail -1)"
cap="$(printf '%s\n' "$summary" | sed -E 's/^capture=(CAP-[0-9]+-[A-Za-z0-9]+) .*/\1/')"
[[ "$cap" =~ ^CAP-[0-9]+-[A-Za-z0-9]+$ ]] || { echo 'no capture summary' >&2; exit 3; }
loc='tests/test-verification.sh::test_capture_provenance'
ret="$s/notes/verification/returns/T030o42.txt"
t="$(mktemp -d "${TMPDIR:-/tmp}/t030o42-ret.XXXXXX")"; trap 'rm -rf "$t"' EXIT
# Run 1 wrote the return and misused vf_return_parse (it takes an output path);
# a rerun rebuilds the block and requires it byte-identical to the one on disk.
{
  printf 'Verification-Return: 1\nTask: T030o42\nCaptures: %s\nSummary: %s\nFailure modes:\n' "$cap" "$summary"
  for id in FM-010 FM-014 INV-001; do printf '%s, %s, %s\n' "$id" "$loc" "$cap"; done
} > "$t/built"
if [[ -e "$ret" ]]; then cmp -s "$t/built" "$ret" || { echo "existing $ret differs from the rebuilt block" >&2; exit 3; }; echo "existing return equals the rebuilt block"
else cp "$t/built" "$ret"; fi
cat "$ret"
vf_return_parse "$ret" "$t/parsed"; rc=$?
printf 'parse rc=%s records=%s\n' "$rc" "$(tr -cd '\0' < "$t/parsed" | wc -c | awk '{print int($1/4)}')"
vf_return_check "$s" T030o42 "$ret" "$t/receipt" > "$t/check.out" 2>&1; crc=$?
printf 'check rc=%s %s\n' "$crc" "$(head -3 "$t/check.out" | tr '\n' ' ')"
(( rc == 0 && crc == 0 ))
