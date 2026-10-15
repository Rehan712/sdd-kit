#!/usr/bin/env bash
# Measure the candidate O-016 rule BEFORE adopting it, 2026-09-26.
# Usage: bash o016-measure.sh <scratchpad> <worktree>
#
# Read-only against the live worktree: copies are built from its manifest
# enumeration (GIT_OPTIONAL_LOCKS=0). The candidate pin -- `export LC_ALL=C`
# right after each command's existing `unset CDPATH BASH_ENV ENV` in
# tests/helpers.sh, tests/run.sh and tests/shellcheck.sh -- is applied to the
# pinned copies ONLY and committed there, so each copy's status baseline is
# clean. Nothing here is expected in advance except where a line says PASS or
# FAIL; the rest are measurements (`|` lines) whose outcome decides the rule.
#
# Streams run in parallel, each in its own copy, each writing its own receipt:
#   p1  pinned: full suite under LC_ALL=en_GB.UTF-8, then under TZ=Pacific/Kiritimati
#   p2  pinned: full suite under LANG=de_DE.UTF-8 (LC_ALL/LC_CTYPE unset), then TZ=Etc/GMT+12
#   p3  pinned: full suite under LANG=en_US.ISO8859-1 LANGUAGE=de:fr, then TZ=America/St_Johns
#   p4  pinned: the usage-limits suite under six locales, then a program census of
#       the full suite through a PATH shim (every program resolved through PATH,
#       apart from the declared tools bash, git and shellcheck)
#   u   unpinned: tests/shellcheck.sh under nine locale settings; pinned under three
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/o016m"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
expect() { if [[ "$2" == "$3" ]]; then printf 'PASS %s (want=%s got=%s)\n' "$1" "$2" "$3"
  else printf 'FAIL %s (want=%s got=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi; }
note() { printf '  | %s\n' "$*"; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1 ); }
copy_state() { ( cd "$1" && git status --porcelain --ignored -uall | shasum -a 256 | cut -d' ' -f1 ); }
totals() { awk '/-- [0-9]+\/[0-9]+ passed/ {split($2, a, "/"); ok += a[1]; all += a[2]} END {printf "%d/%d", ok, all}' "$1"; }
failed_tests() { grep -o -E 'FAIL test_[A-Za-z0-9_]+' "$1" | sed 's/^FAIL //' | LC_ALL=C sort | tr '\n' ' '; }
pin() { # <file>: export LC_ALL=C right after the file's `unset CDPATH BASH_ENV ENV` line
  local f="$1"
  [[ "$(grep -c -x 'unset CDPATH BASH_ENV ENV' "$f")" == 1 ]] || { echo "pin anchor missing in $f" >&2; return 1; }
  awk '{print} $0 == "unset CDPATH BASH_ENV ENV" {print "export LC_ALL=C"}' "$f" > "$f.pin" && cat "$f.pin" > "$f" && rm -f "$f.pin"
}

L0="$(live_state)"; note "live worktree porcelain digest before: $L0"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul"
expect 'live enumeration rc' 0 "$?"
build() { # <name> <pinned 0|1>
  local c="$R/$1"; mkdir -p "$c"
  ( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$c" && tar -xf - ) || return 1
  if [[ "$2" == 1 ]]; then pin "$c/tests/helpers.sh" && pin "$c/tests/run.sh" && pin "$c/tests/shellcheck.sh" || return 1; fi
  ( cd "$c" && git init -q && git add -A && git -c user.name=measure -c user.email=measure@invalid commit -qm base )
}
for c in p1:1 p2:1 p3:1 p4:1 u:0; do build "${c%%:*}" "${c#*:}"; expect "copy ${c%%:*} built (pinned=${c#*:})" 0 "$?"; done
note "pin as applied (tests/helpers.sh): $(grep -n -A1 -x 'unset CDPATH BASH_ENV ENV' "$R/p1/tests/helpers.sh" | tr '\n' ' ')"
for c in p1 p2 p3 p4 u; do eval "S_$c=\"\$(copy_state \"\$R/\$c\")\""; done

suite() { # <copy> <tag> <env args...>: full suite with receipts
  local c="$1" tag="$2"; shift 2
  ( cd "$R/$c" && env "$@" bash tests/run.sh > "$w/$tag.out" 2>&1; echo "$?" > "$w/$tag.rc" )
}
stream_p1() { suite p1 p1-en_GB LC_ALL=en_GB.UTF-8; suite p1 p1-tz-kiritimati TZ=Pacific/Kiritimati; }
stream_p2() { suite p2 p2-de_DE -u LC_ALL -u LC_CTYPE LANG=de_DE.UTF-8; suite p2 p2-tz-gmt12 TZ=Etc/GMT+12; }
stream_p3() { suite p3 p3-iso8859 -u LC_ALL -u LC_CTYPE LANG=en_US.ISO8859-1 LANGUAGE=de:fr; suite p3 p3-tz-stjohns TZ=America/St_Johns; }
stream_p4() {
  local l
  for l in en_GB.UTF-8 de_DE.UTF-8 fr_FR.UTF-8 ja_JP.UTF-8 en_US.ISO8859-1; do
    ( cd "$R/p4" && env -u LC_ALL -u LC_CTYPE LANG="$l" bash tests/test-usage-limits.sh > "$w/p4-ul-$l.out" 2>&1; echo "$?" > "$w/p4-ul-$l.rc" )
  done
  ( cd "$R/p4" && env LC_TIME=de_DE.UTF-8 bash tests/test-usage-limits.sh > "$w/p4-ul-lctime.out" 2>&1; echo "$?" > "$w/p4-ul-lctime.rc" )
  # Census: a shim for every PATH program name except the declared tools. Each
  # shim logs its name and execs the absolute program it shadows, so PATH is
  # unchanged for everything the program itself runs.
  local shim="$R/shim" log="$w/census.log" d f n
  mkdir -p "$shim"; : > "$log"
  local IFS=:
  for d in $PATH; do
    [[ -d "$d" && "$d" == /* ]] || continue
    for f in "$d"/*; do
      n="${f##*/}"
      [[ -f "$f" && -x "$f" && ! -e "$shim/$n" ]] || continue
      case "$n" in bash|git|shellcheck|*[!A-Za-z0-9._+-]*) continue;; esac
      printf '#!/bin/bash\nprintf "%%s\\n" %q >> %q\nexec %q "$@"\n' "$n" "$log" "$f" > "$shim/$n"
      chmod +x "$shim/$n"
    done
  done
  unset IFS
  ( cd "$R/p4" && env PATH="$shim:$PATH" bash tests/run.sh > "$w/p4-census-run.out" 2>&1; echo "$?" > "$w/p4-census-run.rc" )
}
stream_u() {
  local l i=0
  for l in C POSIX C.UTF-8 en_GB.UTF-8 de_DE.UTF-8 ja_JP.UTF-8 ja_JP.SJIS en_US.ISO8859-1 NONE; do
    i=$((i+1))
    if [[ "$l" == NONE ]]; then
      ( cd "$R/u" && env -u LC_ALL -u LC_CTYPE -u LANG -u LC_TIME -u LC_COLLATE -u LC_MESSAGES bash tests/shellcheck.sh > "$w/u-sc-$i.out" 2>&1; echo "$?" > "$w/u-sc-$i.rc" )
    else
      ( cd "$R/u" && env LC_ALL="$l" bash tests/shellcheck.sh > "$w/u-sc-$i.out" 2>&1; echo "$?" > "$w/u-sc-$i.rc" )
    fi
    printf '%s\n' "$l" > "$w/u-sc-$i.locale"
  done
  for l in de_DE.UTF-8 ja_JP.SJIS en_US.ISO8859-1; do
    ( cd "$R/p1" && env -u LC_ALL -u LC_CTYPE LANG="$l" bash tests/shellcheck.sh > "$w/p-sc-$l.out" 2>&1; echo "$?" > "$w/p-sc-$l.rc" )
  done
}

note "streams started $(date -u +%H:%M:%SZ)"
stream_p1 & a=$!; stream_p2 & b=$!; stream_p3 & c=$!; stream_p4 & d=$!; stream_u & e=$!
wait "$a" "$b" "$c" "$d" "$e"
note "streams returned $(date -u +%H:%M:%SZ)"

echo '== M1. the pin makes the full suite locale-proof'
for tag in p1-en_GB p2-de_DE p3-iso8859; do
  expect "pinned full suite $tag rc" 0 "$(cat "$w/$tag.rc" 2>/dev/null || echo MISSING)"
  note "$tag: $(totals "$w/$tag.out") failed: $(failed_tests "$w/$tag.out")"
done
echo '== M1b. the pinned usage-limits suite under locales (LANG only) and LC_TIME alone'
for l in en_GB.UTF-8 de_DE.UTF-8 fr_FR.UTF-8 ja_JP.UTF-8 en_US.ISO8859-1 lctime; do
  expect "pinned usage-limits under $l rc" 0 "$(cat "$w/p4-ul-$l.rc" 2>/dev/null || echo MISSING)"
  note "$l: $(totals "$w/p4-ul-$l.out")"
done
echo '== M2. ShellCheck across locales (measured; unpinned, then pinned)'
base="$(shasum -a 256 < "$w/u-sc-1.out" | cut -c1-16)"
for i in 1 2 3 4 5 6 7 8 9; do
  note "unpinned LC_ALL=$(cat "$w/u-sc-$i.locale"): rc=$(cat "$w/u-sc-$i.rc") out-bytes=$(wc -c < "$w/u-sc-$i.out" | tr -d ' ') digest=$(shasum -a 256 < "$w/u-sc-$i.out" | cut -c1-16) (C digest $base)"
done
for l in de_DE.UTF-8 ja_JP.SJIS en_US.ISO8859-1; do
  note "pinned LANG=$l: rc=$(cat "$w/p-sc-$l.rc") out-bytes=$(wc -c < "$w/p-sc-$l.out" | tr -d ' ')"
done
echo '== M3. timezone, with the locale pinned (measured)'
for tag in p1-tz-kiritimati p2-tz-gmt12 p3-tz-stjohns; do
  note "$tag: rc=$(cat "$w/$tag.rc" 2>/dev/null || echo MISSING) $(totals "$w/$tag.out") failed: $(failed_tests "$w/$tag.out")"
done
echo '== M4. program census of the full suite (programs resolved through PATH, declared tools excluded)'
note "census run: rc=$(cat "$w/p4-census-run.rc" 2>/dev/null || echo MISSING) $(totals "$w/p4-census-run.out") failed: $(failed_tests "$w/p4-census-run.out")"
LC_ALL=C sort "$w/census.log" | uniq -c | LC_ALL=C sort -k2 > "$w/census-counts.txt"
note "distinct programs: $(wc -l < "$w/census-counts.txt" | tr -d ' ') calls: $(wc -l < "$w/census.log" | tr -d ' ')"
awk '{printf "%s(%s) ", $2, $1} END {print ""}' "$w/census-counts.txt" | fold -w 200 | sed 's/^/  | /'

echo '== hermeticity'
for c in p1 p2 p3 p4 u; do eval "want=\$S_$c"; expect "copy $c unchanged by its runs" "$want" "$(copy_state "$R/$c")"; done
cp "$w/census-counts.txt" "$SP/o016m-census-counts.txt" 2>/dev/null || true
cd "$SP" || exit 2
L1="$(live_state)"; note "live worktree porcelain digest after: $L1"
expect 'live worktree unchanged' "$L0" "$L1"
printf 'o016-measure failures=%s\n' "$fails"
(( fails == 0 ))
