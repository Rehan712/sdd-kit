#!/usr/bin/env bash
# Build the Verification-Return block of T031a4o3 (argument) from the one capture of record,
# r23-capture.*, and validate it before acceptance, 2026-10-17 (session 25). Usage from the worktree root: bash <this> <task>
# Pattern: r22-return.sh. The Failure-mode rows are the task's required bindings exactly
# as the catalog lists them (every binding record for the task: its FM/INV ref and the
# locator that binds it), so the envelope cannot drift from what vf_return_check wants.
# Validation is the pair spec-gate accept runs: vf_return_parse, then vf_return_check with a
# scratch receipt; neither ticks anything. A rerun requires the file on disk byte-identical.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
task="${1:?task}"; [[ "$task" == T031a4o3 ]] || { echo "task must be T031a4o3" >&2; exit 2; }
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
[[ "$(cat "$r/r23-capture.rc" 2>/dev/null)" == 0 ]] || { echo 'capture rc is not 0' >&2; exit 3; }
summary="$(grep -E '^capture=CAP-[0-9]+-[A-Za-z0-9]+ ' "$r/r23-capture.log" | tail -1)"
cap="$(printf '%s\n' "$summary" | sed -E 's/^capture=(CAP-[0-9]+-[A-Za-z0-9]+) .*/\1/')"
[[ "$cap" =~ ^CAP-[0-9]+-[A-Za-z0-9]+$ ]] || { echo 'no capture summary' >&2; exit 3; }
ret="$s/notes/verification/returns/$task.txt"
t="$(mktemp -d "${TMPDIR:-/tmp}/r23-ret.XXXXXX")"; trap 'rm -rf "$t"' EXIT
vf_binding_snapshot "$s" "$t/bindings" || { echo 'binding snapshot failed' >&2; exit 3; }
f=(); : > "$t/rows"
while IFS= read -r -d '' v; do
  f+=("$v"); (( ${#f[@]} == 12 )) || continue
  [[ "${f[0]}" == binding && "${f[2]}" == "$task" ]] && printf '%s, %s, %s\n' "${f[1]}" "${f[7]}" "$cap" >> "$t/rows"
  f=()
done < "$t/bindings"
[[ -s "$t/rows" ]] || { echo "no binding rows for $task" >&2; exit 3; }
{ printf 'Verification-Return: 1\nTask: %s\nCaptures: %s\nSummary: %s\nFailure modes:\n' "$task" "$cap" "$summary"
  LC_ALL=C sort -u "$t/rows"; } > "$t/built"
if [[ -e "$ret" ]]; then cmp -s "$t/built" "$ret" || { echo "existing $ret differs from the rebuilt block" >&2; exit 3; }; echo "existing return equals the rebuilt block"
else cp "$t/built" "$ret"; fi
cat "$ret"
vf_return_parse "$ret" "$t/parsed"; rc=$?
printf 'parse rc=%s records=%s\n' "$rc" "$(tr -cd '\0' < "$t/parsed" | wc -c | awk '{print int($1/4)}')"
vf_return_check "$s" "$task" "$ret" "$t/receipt" > "$t/check.out" 2>&1; crc=$?
printf 'check rc=%s %s\n' "$crc" "$(head -3 "$t/check.out" | tr '\n' ' ')"
(( rc == 0 && crc == 0 ))
