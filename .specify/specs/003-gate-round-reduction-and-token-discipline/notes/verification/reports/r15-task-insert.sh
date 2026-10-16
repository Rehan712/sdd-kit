#!/usr/bin/env bash
# r15-task-insert.sh <tasks.md> <block.md>: insert the T030o47 block after the T030o46 task block,
# i.e. directly before the "## API" heading that follows it, separated by one blank line.
# Pattern: r14-task-insert.sh.
set -euo pipefail
f="$1" b="$2"
[[ "$(grep -c '^## API$' "$f")" == 1 ]] || { echo "anchor not unique" >&2; exit 3; }
[[ "$(grep -c -E '^- \[.\] \*\*T030o47\*\*' "$f")" == 0 ]] || { echo "T030o47 already present" >&2; exit 3; }
[[ "$(awk '/^## API$/{print prev; exit} NF{prev=$0}' "$f")" == '  - *Evidence:* CAP-567-dtDT42 verified by spec-gate accept; return sha256:9b0a5c84193ccc8ea2bf8b0f3724c017c42b4591ad33a2d74c18fb813fff0bb2' ]] ||
  { echo "the line before ## API is not T030o46's Evidence" >&2; exit 3; }
awk -v bf="$b" '
  /^## API$/ { while ((getline l < bf) > 0) print l; print ""; }
  { print }
' "$f" > "$f.new"
mv "$f.new" "$f"
