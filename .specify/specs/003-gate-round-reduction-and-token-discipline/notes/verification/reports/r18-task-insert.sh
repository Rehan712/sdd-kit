#!/usr/bin/env bash
# r18-task-insert.sh <tasks.md> <blocks.md>: insert the T030o51, T030o52 and T030o53 blocks after the T030o50 task
# block, i.e. directly before the "## API" heading that follows it, separated by one blank line.
# Pattern: r17-task-insert.sh.
set -euo pipefail
f="$1" b="$2"
[[ "$(grep -c '^## API$' "$f")" == 1 ]] || { echo "anchor not unique" >&2; exit 3; }
[[ "$(grep -c -E '^- \[.\] \*\*T030o(51|52|53)\*\*' "$f")" == 0 ]] || { echo "T030o51-T030o53 already present" >&2; exit 3; }
[[ "$(awk '/^## API$/{print prev; exit} NF{prev=$0}' "$f")" == '  - *Evidence:* CAP-612-hpySUJ verified by spec-gate accept; return sha256:032317aa412be675613e896ad1f52e2ddcbe987c33465171781e38a8cedc6f42' ]] ||
  { echo "the line before ## API is not T030o50's Evidence" >&2; exit 3; }
awk -v bf="$b" '
  /^## API$/ { while ((getline l < bf) > 0) print l; print ""; }
  { print }
' "$f" > "$f.new"
mv "$f.new" "$f"
