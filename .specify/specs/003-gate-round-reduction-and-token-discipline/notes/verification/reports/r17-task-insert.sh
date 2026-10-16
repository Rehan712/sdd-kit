#!/usr/bin/env bash
# r17-task-insert.sh <tasks.md> <blocks.md>: insert the T030o48, T030o49 and T030o50 blocks after the T030o47 task
# block, i.e. directly before the "## API" heading that follows it, separated by one blank line.
# Pattern: r15-task-insert.sh.
set -euo pipefail
f="$1" b="$2"
[[ "$(grep -c '^## API$' "$f")" == 1 ]] || { echo "anchor not unique" >&2; exit 3; }
[[ "$(grep -c -E '^- \[.\] \*\*T030o(48|49|50)\*\*' "$f")" == 0 ]] || { echo "T030o48-T030o50 already present" >&2; exit 3; }
[[ "$(awk '/^## API$/{print prev; exit} NF{prev=$0}' "$f")" == '  - *Evidence:* CAP-589-ZNd9Ug verified by spec-gate accept; return sha256:2a8d2a944234a6a6daa9771e97f34479e46ee5bc096283385d1c4163134d4755' ]] ||
  { echo "the line before ## API is not T030o47's Evidence" >&2; exit 3; }
awk -v bf="$b" '
  /^## API$/ { while ((getline l < bf) > 0) print l; print ""; }
  { print }
' "$f" > "$f.new"
mv "$f.new" "$f"
