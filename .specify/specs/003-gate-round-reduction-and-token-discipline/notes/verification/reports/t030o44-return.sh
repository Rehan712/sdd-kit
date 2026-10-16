#!/usr/bin/env bash
# Build T030o44's Verification-Return block from its capture summary and validate it
# before acceptance, 2026-10-02 (session 13), reading t030o44-capture.*.
# Pattern: t030o43-return-2.sh. The Failure-mode rows are the task's required bindings exactly
# as the catalog lists them (every binding record for T030o44: its FM/INV ref and the
# locator that binds it), so the envelope cannot drift from what vf_return_check wants.
# Validation is the pair spec-gate accept runs: vf_return_parse, then vf_return_check with a
# scratch receipt; neither ticks anything. A rerun requires the file on disk byte-identical.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
[[ "$(cat "$r/t030o44-capture.rc" 2>/dev/null)" == 0 ]] || { echo 'capture rc is not 0' >&2; exit 3; }
summary="$(grep -E '^capture=CAP-[0-9]+-[A-Za-z0-9]+ ' "$r/t030o44-capture.log" | tail -1)"
cap="$(printf '%s\n' "$summary" | sed -E 's/^capture=(CAP-[0-9]+-[A-Za-z0-9]+) .*/\1/')"
[[ "$cap" =~ ^CAP-[0-9]+-[A-Za-z0-9]+$ ]] || { echo 'no capture summary' >&2; exit 3; }
ret="$s/notes/verification/returns/T030o44.txt"
t="$(mktemp -d "${TMPDIR:-/tmp}/t030o44-ret.XXXXXX")"; trap 'rm -rf "$t"' EXIT
vf_binding_snapshot "$s" "$t/bindings" || { echo 'binding snapshot failed' >&2; exit 3; }
f=(); : > "$t/rows"
while IFS= read -r -d '' v; do
  f+=("$v"); (( ${#f[@]} == 12 )) || continue
  [[ "${f[0]}" == binding && "${f[2]}" == T030o44 ]] && printf '%s, %s, %s\n' "${f[1]}" "${f[7]}" "$cap" >> "$t/rows"
  f=()
done < "$t/bindings"
[[ -s "$t/rows" ]] || { echo 'no binding rows for T030o44' >&2; exit 3; }
{ printf 'Verification-Return: 1\nTask: T030o44\nCaptures: %s\nSummary: %s\nFailure modes:\n' "$cap" "$summary"
  LC_ALL=C sort -u "$t/rows"; } > "$t/built"
if [[ -e "$ret" ]]; then cmp -s "$t/built" "$ret" || { echo "existing $ret differs from the rebuilt block" >&2; exit 3; }; echo "existing return equals the rebuilt block"
else cp "$t/built" "$ret"; fi
cat "$ret"
vf_return_parse "$ret" "$t/parsed"; rc=$?
printf 'parse rc=%s records=%s\n' "$rc" "$(tr -cd '\0' < "$t/parsed" | wc -c | awk '{print int($1/4)}')"
vf_return_check "$s" T030o44 "$ret" "$t/receipt" > "$t/check.out" 2>&1; crc=$?
printf 'check rc=%s %s\n' "$crc" "$(head -3 "$t/check.out" | tr '\n' ' ')"
(( rc == 0 && crc == 0 ))
