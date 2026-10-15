#!/usr/bin/env bash
# vf_blank: every White_Space code point, and invisible non-White_Space ones, as the only body line.
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/blank; rm -rf $w; mkdir -p $w; export TMPDIR=$B/tmp
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
report() { # file body
  { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 0\n### What I attacked\n' "$SRC"
    printf '%s\n' "$2"
    printf '### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n'; } > "$1"
}
res() { inloc "$2" bash -c '. "$1/scripts/verification-lib.sh" && vf_reports "$2" opponent "$3" "$4"' _ "$B/$1" "$w/r.md" "$w/out.nul" "$w" >/dev/null 2>"$w/e"; local rc=$?
  if [[ $rc == 0 ]]; then echo body; elif grep -q 'empty required report section: what i attacked' "$w/e"; then echo EMPTY; else echo "rc=$rc:$(head -c 80 "$w/e")"; fi; }
printf '%-8s %-6s | %-6s %-6s | %-6s %-6s\n' cp ws pkit-C pkit-U8 kit-C kit-U8
for cp in 0009 000B 000C 000D 0020 0085 00A0 1680 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 200A 2028 2029 202F 205F 3000  180E 200B 200C 200D 2060 FEFF 00AD 2800 3164 FFA0 115F 1160 034F; do
  ch="$(perl -CO -e 'print chr(hex($ARGV[0]))' "$cp")"
  report "$w/r.md" "$ch"
  ws=no; perl -CI -ne 'exit(/^\p{White_Space}+$/ ? 0 : 1)' <<< "$ch" && ws=yes
  printf '%-8s %-6s | %-6s %-6s | %-6s %-6s\n' "U+$cp" "$ws" "$(res pkit C)" "$(res pkit en_US.UTF-8)" "$(res kit C)" "$(res kit en_US.UTF-8)"
done
report "$w/r.md" ' '; echo "ascii-space: kit-C $(res kit C)"
report "$w/r.md" "$(printf ' \302\240\t\343\200\200 ')"; echo "mixed ws: kit-C $(res kit C) pkit-U8 $(res pkit en_US.UTF-8)"
report "$w/r.md" "$(printf '\302\240x')"; echo "nbsp+x: kit-C $(res kit C)"
report "$w/r.md" "$(printf '\302')"; echo "lone C2: kit-C $(res kit C) pkit-U8 $(res pkit en_US.UTF-8)"
report "$w/r.md" "$(printf '\342\200')"; echo "truncated E2 80: kit-C $(res kit C)"
report "$w/r.md" "$(printf '\240')"; echo "lone A0: kit-C $(res kit C)"
