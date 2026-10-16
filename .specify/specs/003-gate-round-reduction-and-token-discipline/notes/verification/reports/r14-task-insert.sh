#!/usr/bin/env bash
# r14-task-insert.sh <tasks.md> <blocks.md>: insert the T030o45 and T030o46 blocks after the T030o44 task block,
# i.e. directly before the "## API" heading that follows it, separated by one blank line.
# Pattern: t030o44-task-insert.sh.
set -euo pipefail
f="$1" b="$2"
[[ "$(grep -c '^## API$' "$f")" == 1 ]] || { echo "anchor not unique" >&2; exit 3; }
[[ "$(grep -c -E '^- \[.\] \*\*T030o4[56]\*\*' "$f")" == 0 ]] || { echo "T030o45 or T030o46 already present" >&2; exit 3; }
[[ "$(awk '/^## API$/{print prev; exit} NF{prev=$0}' "$f")" == '  - *Evidence:* CAP-544-cjPQ2j verified by spec-gate accept; return sha256:e7fd68649b8160f8d6e7bf0e425b40f2ed1f266af098e633c3186851f4ead372' ]] ||
  { echo "the line before ## API is not T030o44's Evidence" >&2; exit 3; }
awk -v bf="$b" '
  /^## API$/ { while ((getline l < bf) > 0) print l; print ""; }
  { print }
' "$f" > "$f.new"
mv "$f.new" "$f"
