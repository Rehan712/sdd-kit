#!/usr/bin/env bash
# Session 18: fill the placeholders of r17-decisions-1.md at writing time, in byte mode (perl without -C; the em
# dash is written as its UTF-8 bytes, never taken from the environment): each @@DATE@@ becomes the UTC date of
# writing, and the @@WAIVER@@ line the round-17 authorization stamped now, which must follow round 16's completion
# (2026-10-08T12:38:54Z). Refuses unless the batch holds exactly five @@DATE@@ and one @@WAIVER@@ line.
# Pattern: r16-decisions-fill.sh. Usage from the worktree root: bash <this>
set -euo pipefail
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
B="$r/r17-decisions-1.md"
[[ "$(grep -o '@@DATE@@' "$B" | wc -l | tr -d ' ')" == 5 ]] || { echo 'FAIL want five @@DATE@@' >&2; exit 3; }
[[ "$(grep -c '^@@WAIVER@@$' "$B")" == 1 ]] || { echo 'FAIL want one @@WAIVER@@ line' >&2; exit 3; }
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; day="${ts%%T*}"
[[ "$ts" > 2026-10-08T12:38:54Z ]] || { echo "FAIL $ts does not follow round 16's completion" >&2; exit 3; }
reason="user instructed on 2026-10-07 to repair the findings of a CHALLENGED round and rerun the opponent until all issues are resolved, so round 17 assesses the repairs of round 16's O-018, O-022 and O-023 against a fresh floor sealed after those repairs are accepted"
[[ "$reason" != *';'* ]] || { echo 'FAIL the reason holds a semicolon' >&2; exit 3; }
dash="$(printf '\342\200\224')"
line="- $ts $dash waiver: gate=opponent; round=17; after=16; by=Rehan712; reason=$reason"
DAY="$day" LINE="$line" perl -i -pe 's/\@\@DATE\@\@/$ENV{DAY}/g; s/^\@\@WAIVER\@\@$/$ENV{LINE}/' "$B"
grep -c '@@' "$B" || true
printf 'filled date=%s waiver=%s\n' "$day" "$ts"
