#!/usr/bin/env bash
# The real round-12 O-017 finding block, copied verbatim into a prior-review manifest.
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/man3; rm -rf $w; mkdir -p $w/notes/verification/reports; export TMPDIR=$B/tmp
{ printf '# Prior review (round 12 of spec 003)\n\n'; cat $B/work/o017-block.md; } > $w/notes/verification/reports/opponent-findings-r12.md
: > $w/notes/opponent.md
for kit in pkit rkit kit; do for l in C en_US.UTF-8; do
  out="$(env -u LC_ALL -u LC_CTYPE LANG=$l bash -c '. "$1/scripts/verification-lib.sh" && vf_reports "$2" opponent "$3" "$4"' _ "$B/$kit" "$w/notes/opponent.md" "$w/out.nul" "$w" 2>&1)"; rc=$?
  printf '  %-4s %-11s rc=%s %s\n' "$kit" "$l" "$rc" "$(printf '%s' "$out" | head -1 | cut -c1-140)"
done; done
