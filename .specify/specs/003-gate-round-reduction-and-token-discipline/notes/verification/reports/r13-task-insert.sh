#!/usr/bin/env bash
# r13-task-insert.sh <tasks.md> <block.md>: insert the block after the T030o42 task block,
# i.e. directly before the "## API" heading that follows it, separated by one blank line.
set -euo pipefail
f="$1" b="$2"
[[ "$(grep -c '^## API$' "$f")" == 1 ]] || { echo "anchor not unique" >&2; exit 3; }
[[ "$(grep -c '^- \[.\] \*\*T030o43\*\*' "$f")" == 0 ]] || { echo "T030o43 already present" >&2; exit 3; }
awk -v bf="$b" '
  /^## API$/ { while ((getline l < bf) > 0) print l; print ""; }
  { print }
' "$f" > "$f.new"
mv "$f.new" "$f"
