#!/usr/bin/env bash
# Reproduce round-11 O-016, 2026-09-26, BEFORE any repair.
# Usage: bash o016-repro.sh <scratchpad> <worktree>
#
# Read-only against the live worktree: step 0 reads its manifest enumeration
# (GIT_OPTIONAL_LOCKS=0) and tars those files into two standalone git copies
# under <scratchpad>/o016/. Every capture and suite runs in a copy. Every exit
# code is captured from the command itself, never through a pipe. Each copy's
# `git status --porcelain --ignored` (outside the spec's own records, which a
# capture writes by design) must be unchanged by every suite run, and the live
# worktree's status digest is compared before and after.
#
# A: the identity is the same under three locales, while the verdict of the
#    affected suite is not (the report's static and dynamic premises).
# B: end to end. Copy 1 captures T030o41's Verify under the ambient locale; the
#    reuse predicates then accept that capture under en_GB. In parallel, copy 2
#    runs the same full suite fresh under en_GB, which fails.
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/o016"; C1="$R/copy1"; C2="$R/copy2"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C1" "$C2" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
expect() { # label want got
  if [[ "$2" == "$3" ]]; then printf 'PASS %s (want=%s got=%s)\n' "$1" "$2" "$3"
  else printf 'FAIL %s (want=%s got=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi
}
note() { printf '  | %s\n' "$*"; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1 ); }
copy_state() { ( cd "$1" && git status --porcelain --ignored -uall | grep -v -F "$s/notes/" | shasum -a 256 | cut -d' ' -f1 ); }
snap() { # <copy> <manifest> [env assignments...] -> identity digest
  local c="$1" m="$2"; shift 2
  ( cd "$c" && env "$@" bash -c 'HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh; vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$m" 2> "$m.err" )
}
totals() { awk '/-- [0-9]+\/[0-9]+ passed/ {split($2, a, "/"); ok += a[1]; all += a[2]} END {printf "%d/%d", ok, all}' "$1"; }
failed_tests() { grep -o -E 'FAIL test_[A-Za-z0-9_]+' "$1" | sed 's/^FAIL //' | LC_ALL=C sort | tr '\n' ' '; }
# The three locale-free environments the report's scenario and controls name.
EN_GB=(LC_ALL=en_GB.UTF-8)
DE_DE=(-u LC_ALL -u LC_CTYPE LANG=de_DE.UTF-8)
C_LOC=(LC_ALL=C)

L0="$(live_state)"; note "live worktree porcelain digest before: $L0"
note "ambient: LANG=${LANG-unset} LC_ALL=${LC_ALL-unset} LC_CTYPE=${LC_CTYPE-unset} LC_TIME=${LC_TIME-unset} TZ=${TZ-unset}"

echo '== 0. build two copies from the live manifest enumeration'
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul"
expect 'live enumeration rc' 0 "$?"
for c in "$C1" "$C2"; do
  ( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$c" && tar -xf - )
  expect "extraction into ${c##*/} rc" 0 "$?"
  ( cd "$c" && git init -q && git add -A && git -c user.name=repro -c user.email=repro@invalid commit -qm base )
  expect "${c##*/} committed" 0 "$?"
done
S1="$(copy_state "$C1")"; S2="$(copy_state "$C2")"

echo '== A0. the consulted behaviour: date %p for 2024-01-01T15:45:00Z'
for l in C C.UTF-8 en_US.UTF-8 en_GB.UTF-8 de_DE.UTF-8 fr_FR.UTF-8; do
  note "LC_ALL=$l TZ=UTC date '+%I:%M %p' -> [$(LC_ALL=$l TZ=UTC date -r 1704123900 '+%I:%M %p')]"
done

echo '== A1. the identity does not see the locale'
I0="$(snap "$C1" "$w/a1-ambient.nul")"; expect 'ambient snapshot rc' 0 "$?"
I1="$(snap "$C1" "$w/a1-en_GB.nul" "${EN_GB[@]}")"; expect 'en_GB snapshot rc' 0 "$?"
I2="$(snap "$C1" "$w/a1-de_DE.nul" "${DE_DE[@]}")"; expect 'de_DE snapshot rc' 0 "$?"
note "identity ambient=$I0 en_GB=$I1 de_DE=$I2"
cmp -s "$w/a1-ambient.nul" "$w/a1-en_GB.nul"; expect 'manifest cmp-identical under LC_ALL=en_GB.UTF-8' 0 "$?"
cmp -s "$w/a1-ambient.nul" "$w/a1-de_DE.nul"; expect 'manifest cmp-identical under LANG=de_DE.UTF-8' 0 "$?"
expect 'no environment record in the manifest (verification_environment: [])' 0 "$(tr '\0' '\n' < "$w/a1-ambient.nul" | grep -c -x environment)"

echo '== A2. the affected suite does see it (bash tests/test-usage-limits.sh)'
for case in ambient:0 en_GB:1 de_DE:1 C:0; do
  tag="${case%%:*}"; want="${case#*:}"
  case "$tag" in ambient) e=();; en_GB) e=("${EN_GB[@]}");; de_DE) e=("${DE_DE[@]}");; C) e=("${C_LOC[@]}");; esac
  ( cd "$C1" && env ${e[@]+"${e[@]}"} bash tests/test-usage-limits.sh ) > "$w/a2-$tag.out" 2>&1
  expect "test-usage-limits.sh under $tag rc" "$want" "$?"
  note "$tag: $(totals "$w/a2-$tag.out") failed: $(failed_tests "$w/a2-$tag.out")"
done
grep -A3 'FAIL test_AC_001' "$w/a2-en_GB.out" | grep -E 'expected|actual' | head -2 | sed 's/^/  | en_GB /'
grep -A3 'FAIL test_AC_001' "$w/a2-de_DE.out" | grep -E 'expected|actual' | head -2 | sed 's/^/  | de_DE /'
expect 'copy1 unchanged by the A2 suite runs' "$S1" "$(copy_state "$C1")"

echo '== B. end to end (copy 1 captures and checks reuse; copy 2 runs fresh under en_GB, in parallel)'
expect 'T030o41 Verify is the two reuse-checked commands' 1 "$(awk '/^- \[.\] \*\*T030o41\*\*/{on=1} on && /\*Verify:\*/{print; exit}' "$C1/$s/tasks.md" | grep -c -F '`bash tests/run.sh && bash tests/shellcheck.sh`')"
( cd "$C1" && bash scripts/spec-run.sh "$s" T030o41 --from-task --no-tick --summary > "$w/b-capture.out" 2>&1; echo "$?" > "$w/b-capture.rc" ) &
p1=$!
( cd "$C2" && env "${EN_GB[@]}" bash tests/run.sh > "$w/b-fresh-en_GB.out" 2>&1; echo "$?" > "$w/b-fresh-en_GB.rc" ) &
p2=$!
note "started capture (pid $p1) and fresh en_GB suite (pid $p2) at $(date -u +%H:%M:%SZ)"
wait "$p1"; wait "$p2"
note "both returned at $(date -u +%H:%M:%SZ)"
expect 'capture of T030o41 Verify under the ambient locale rc' 0 "$(cat "$w/b-capture.rc" 2>/dev/null || echo MISSING)"
cap="$(grep -o -E 'CAP-[0-9]+-[A-Za-z0-9]+' "$w/b-capture.out" | head -1)"
note "capture=$cap summary: $(tail -1 "$w/b-capture.out" | cut -c1-240)"
capdir="$C1/$s/notes/captures/$cap"
note "capture command: $(tr '\0' ' ' < "$capdir/argv.nul")"
note "capture totals: $(totals "$capdir/output.log")"
Ib="$(snap "$C1" "$w/b-ambient.nul")"; expect 'ambient snapshot after the capture rc' 0 "$?"
Ie="$(snap "$C1" "$w/b-en_GB.nul" "${EN_GB[@]}")"; expect 'en_GB snapshot after the capture rc' 0 "$?"
note "identity ambient=$Ib en_GB=$Ie capture input_before=$(tr '\0' '\n' < "$capdir/meta.nul" | grep -A1 -x input_before | tail -1)"
expect 'en_GB identity equals the capture input' "$(tr '\0' '\n' < "$capdir/meta.nul" | grep -A1 -x input_before | tail -1)" "$Ie"
( cd "$C1" && env "${EN_GB[@]}" bash -c 'HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
    vf_capture_check "$1" "$2" "$3" reuse' _ "$s" "$cap" "$w/b-en_GB.nul" ) > "$w/b-reuse.out" 2>&1
expect "vf_capture_check $cap reuse under en_GB: accepted (the wrong result)" 0 "$?"
( cd "$C1" && env "${EN_GB[@]}" bash -c 'HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
    vf_binding_snapshot "$1" "$2"' _ "$s" "$w/b-bindings.nul" ) > "$w/b-bindings.out" 2>&1
expect 'binding snapshot under en_GB rc' 0 "$?"
cmp -s "$w/b-bindings.nul" "$capdir/bindings.nul"; expect 'binding snapshot cmp-equal to the capture (the floor match condition)' 0 "$?"
( cd "$C1" && env "${EN_GB[@]}" bash -c 'HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
    vf_task_current "$1" T030o41 "$2" "$3" reuse' _ "$s" "$w/b-bindings.nul" "$w/b-en_GB.nul" ) > "$w/b-current.out" 2>&1
expect 'vf_task_current T030o41 reuse under en_GB rc' 0 "$?"
expect 'vf_task_current names the ambient capture' "$cap" "$(cat "$w/b-current.out")"
expect 'fresh bash tests/run.sh under en_GB rc (the verdict the reuse hides)' 1 "$(cat "$w/b-fresh-en_GB.rc" 2>/dev/null || echo MISSING)"
note "fresh en_GB totals: $(totals "$w/b-fresh-en_GB.out") failed: $(failed_tests "$w/b-fresh-en_GB.out")"
expect 'copy2 unchanged by the fresh suite run' "$S2" "$(copy_state "$C2")"
expect 'copy1 unchanged outside its records by the capture' "$S1" "$(copy_state "$C1")"

cd "$SP" || exit 2
L1="$(live_state)"; note "live worktree porcelain digest after: $L1"
expect 'live worktree unchanged' "$L0" "$L1"
printf 'o016-repro failures=%s\n' "$fails"
(( fails == 0 ))
