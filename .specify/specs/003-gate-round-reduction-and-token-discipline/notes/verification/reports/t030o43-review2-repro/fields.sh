#!/usr/bin/env bash
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/fields; rm -rf $w; mkdir -p $w/notes; export TMPDIR=$B/tmp
SRC="$(printf 'a%.0s' {1..64})"; NB=$'\302\240'
for field in Scenario Reproduced 'Wrong behavior' 'Class-wide fix' Prior; do
  printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CHALLENGED\n**Blocking:** 1 · **Minor:** 0\n### What I attacked\nx.\n### Finding G-042\n- **Class:** tier-binding\n- **Status:** new\n- **Prior:** none\n- **Severity:** data-loss\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read the manifest\n### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n' "$SRC" |
    FIELD="$field" NB="$NB" perl -pe 's/^(- \*\*\Q$ENV{FIELD}\E:\*\*) .*$/$1 $ENV{NB}/' > $w/notes/opponent.md
  line="- **$field:** <U+00A0> |"
  for kit in pkit ckit; do for l in C en_US.UTF-8; do
    out="$(env -u LC_ALL -u LC_CTYPE LANG=$l bash -c '. "$1/scripts/verification-lib.sh"; vf_reports "$2" opponent "$3" "$4"' _ $B/$kit $w/notes/opponent.md $w/out.nul $w 2>&1)"; rc=$?
    line="$line $kit/$l rc=$rc$(printf '%s' "$out" | LC_ALL=C grep -o 'incomplete finding [A-Z0-9-]*' | head -1 | sed 's/^/ (/;s/$/)/')"
  done; done
  echo "$line"
done
