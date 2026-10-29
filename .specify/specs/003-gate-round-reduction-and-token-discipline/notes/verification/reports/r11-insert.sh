#!/usr/bin/env bash
# insert.sh <STATUS.md> <batch.md>: insert the batch as the last Decisions entries,
# directly before "## Open questions / blockers", separated by blank lines.
set -euo pipefail
f="$1" b="$2"
[[ "$(grep -c '^## Open questions / blockers$' "$f")" == 1 ]] || { echo "anchor not unique" >&2; exit 3; }
awk -v bf="$b" '
  /^## Open questions \/ blockers$/ { while ((getline l < bf) > 0) print l; print ""; }
  { print }
' "$f" > "$f.new"
mv "$f.new" "$f"
