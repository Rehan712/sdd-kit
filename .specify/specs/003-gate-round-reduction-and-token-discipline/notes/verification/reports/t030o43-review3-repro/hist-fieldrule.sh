#!/usr/bin/env bash
# Proposed R3-F2 field-candidate rule applied to the recorded history; prints any line it would
# make a candidate that is not already a canonical `- **Class:**` / `- **Severity:**` line.
# usage: bash hist-fieldrule.sh <kit-root>
cd "$1" || exit 2
for f in .specify/specs/*/notes/*.md .specify/specs/*/notes/verification/reports/*-findings-*.md; do LC_ALL=C awk -v F="$f" '
{ t=$0; sub(/^[[:space:]]+/, "", t)
  if (t ~ /^([-*+]|[0-9]+[.)])[[:space:]]/) sub(/^([-*+]|[0-9]+[.)])[[:space:]]+/, "", t)
  sub(/^[*_]+/, "", t)
  if (!match(t, /^[A-Za-z]+/)) next
  w=tolower(substr(t,1,RLENGTH)); if (w!="class" && w!="severity") next
  r=substr(t,RLENGTH+1); sub(/^[*_[:space:]]+/, "", r)
  c=substr(r,1,1)
  if (c ~ /[A-Za-z0-9-]/ ) next
  if ($0 ~ /^[ ]*-[[:space:]]+\*\*(Class|Severity):\*\*/) next
  print F ":" NR ": " substr($0,1,140) }' "$f"; done
