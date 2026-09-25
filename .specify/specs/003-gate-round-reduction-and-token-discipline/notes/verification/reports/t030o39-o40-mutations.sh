#!/usr/bin/env bash
# T030o39/T030o40 mutation matrix, run 2 (after the independent review), 2026-09-23.
# Usage: bash run-matrix.sh <scratchpad> <worktree>
# Isolated standalone copy of the worktree source. Each mutant's target test
# function comes from mutate.py's table (no glob routing: run 1 routed M1* to
# M10-M16 as well). Each run is its own process group under a watchdog, so a
# mutant that hangs is killed and counted, and every restore is checked
# byte-identical against the live worktree file with cmp.
set -uo pipefail
set -m
SP="$1"; WT="$2"; M="$SP/mut"; C="$M/copy"; W="$M/work"; LIMIT=420
CS="$SP/cs/mtmp"  # case-sensitive APFS image mounted at $SP/cs
export TMPDIR="$M/tmp"; rm -rf "$C" "$W" "$TMPDIR" "$CS"; mkdir -p "$C" "$W" "$TMPDIR" "$CS"
fails=0
( cd "$WT" && git ls-files --cached --others --exclude-standard -z | while IFS= read -r -d '' p; do
    case "$p" in .specify/specs/003-gate-round-reduction-and-token-discipline/notes/captures/*|.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/*) continue;; esac
    [ -e "$p" ] || [ -L "$p" ] && printf '%s\0' "$p"; done ) > "$M/paths.nul"
( cd "$WT" && tar --null -T "$M/paths.nul" -cf - ) | ( cd "$C" && tar -xpf - ) || { echo 'copy failed'; exit 2; }
( cd "$C" && git init -q && git add -A && git -c user.email=m@local -c user.name=m commit -qm matrix && printf 'tests/.one-*.sh\n' >> .git/info/exclude ) || exit 2
strip() { for f in test-verification test-gate-contracts; do awk '$0 != "t_run_all"' "$C/tests/$f.sh" > "$C/tests/.one-$f.sh"; done; }
run_fn() { # stem function tag -> rc of that one function (124 when the watchdog fired)
  ( cd "$C" && exec bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$1" "$2" "$W/$3.out" ) &
  local pid=$! i=0 rc
  while kill -0 "$pid" 2>/dev/null; do
    if (( i++ >= LIMIT )); then kill -TERM -- "-$pid" 2>/dev/null; sleep 2; kill -KILL -- "-$pid" 2>/dev/null; wait "$pid" 2>/dev/null; echo "watchdog: killed after ${LIMIT}s" >> "$W/$3.out"; return 124; fi
    sleep 1
  done
  wait "$pid"; rc=$?
  return "$rc"
}
strip
for t in test-verification:test_capture_provenance test-gate-contracts:test_reports_and_tally test-gate-contracts:test_instruction_contracts; do
  run_fn "${t%%:*}" "${t#*:}" "baseline-${t#*:}"; rc=$?
  if [[ "$rc" == 0 ]]; then printf 'PASS baseline %s rc=0\n' "$t"; else printf 'FAIL baseline %s rc=%s: %s\n' "$t" "$rc" "$(grep -m1 assert "$W/baseline-${t#*:}.out")"; fails=$((fails+1)); fi
done
# The same provenance baseline on the case-sensitive volume, which runs the
# non-folding branch of the fixtures (as Linux CI does).
TMPDIR="$CS" run_fn test-verification test_capture_provenance baseline-cs-test_capture_provenance; rc=$?
if [[ "$rc" == 0 ]]; then printf 'PASS baseline-cs test-verification:test_capture_provenance rc=0\n'; else printf 'FAIL baseline-cs rc=%s: %s\n' "$rc" "$(grep -m1 assert "$W/baseline-cs-test_capture_provenance.out")"; fails=$((fails+1)); fi
python3 "$M/mutate.py" --list > "$M/table.txt" || exit 2
while read -r name target <&3; do
  files="$(python3 "$M/mutate.py" "$name" "$C")" || { printf 'FAIL %s: mutation did not apply\n' "$name"; fails=$((fails+1)); continue; }
  strip
  case "$name" in *-cs) TMPDIR="$CS" run_fn "${target%%:*}" "${target#*:}" "$name"; rc=$?;; *) run_fn "${target%%:*}" "${target#*:}" "$name"; rc=$?;; esac
  detail="$target rc=$rc: $(grep -m1 -E 'assert|AC-0|watchdog' "$W/$name.out" | cut -c1-170)"
  case "$name" in E*) want=SURVIVED;; *) want=KILLED;; esac
  got=SURVIVED; [[ "$rc" == 0 ]] || got=KILLED
  for f in $files; do ( cd "$C" && git checkout -q -- "$f" ); cmp -s "$C/$f" "$WT/$f" || { printf 'FAIL %s: restore of %s is not byte-identical\n' "$name" "$f"; fails=$((fails+1)); }; done
  strip
  [[ -z "$(cd "$C" && git status --porcelain)" ]] || { printf 'FAIL %s: copy not clean after restore\n' "$name"; fails=$((fails+1)); }
  if [[ "$got" == "$want" ]]; then printf 'PASS %s %s %s\n' "$name" "$got" "$detail"; else printf 'FAIL %s want=%s got=%s %s\n' "$name" "$want" "$got" "$detail"; fails=$((fails+1)); fi
done 3< "$M/table.txt"
for f in scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-verification.sh; do
  cmp -s "$C/$f" "$WT/$f" && printf 'PASS final %s byte-identical to live\n' "$f" || { printf 'FAIL final %s differs from live\n' "$f"; fails=$((fails+1)); }
done
printf 'matrix failures=%s\n' "$fails"
(( fails == 0 ))
