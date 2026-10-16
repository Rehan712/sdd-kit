#!/usr/bin/env bash
# Session 19, exploratory and read-only against the live worktree: for each candidate mutant of matrix v6 (a NUL file of
# records id, old, new, judges, written by r18-discover-mutants.py), apply it once to a standalone copy built from the
# live enumeration with the round-17 repair applied (APPLY=1: r18-edits/kernel-1, vc-1, tgc-1 and tsg-1 pairs, before
# the copy's base commit, so a restore returns to the repaired tree; without it the copy is the live tree as it is),
# run each named judge (one fixture function alone, as the matrix runs it, under a TMPDIR ending in `/`), and print
# its rc and the first failing assertions; restore and check byte-identical. It decides nothing: it tells which rows
# kill a mutant, so that v6 names real rows. Pattern: r17-discover.sh. Harness: r17-mutations.sh.
# Usage: [APPLY=1] bash r18-discover.sh <scratchpad-dir> <worktree> <mutants.nul> <label>
set -uo pipefail
SP="$1"; WT="$2"; MF="$3"; label="$4"
R="$SP/r18-disc-$label"; C="$R/copy"; P="$R/pristine"; w="$R/work"
export TMPDIR="$R/tmp/"
rm -rf "$R"; mkdir -p "$C" "$P" "$w" "$TMPDIR"
say() { printf '%s\n' "$*"; }
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul" || { say 'FAIL enumeration'; exit 2; }
for d in "$C" "$P"; do ( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$d" && tar -xf - ) || { say 'FAIL extraction'; exit 2; }; done
if [[ "${APPLY:-0}" == 1 ]]; then
  E="$WT/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/r18-edits"
  for d in "$C" "$P"; do
    perl "$E/lit.pl" "$d/scripts/verification-lib.sh" "$E/kernel-1.pairs" > /dev/null &&
    perl "$E/lit.pl" "$d/templates/verification-contract.md" "$E/vc-1.pairs" > /dev/null &&
    perl "$E/lit.pl" "$d/tests/test-gate-contracts.sh" "$E/tgc-1.pairs" > /dev/null &&
    perl "$E/lit.pl" "$d/tests/test-spec-gate.sh" "$E/tsg-1.pairs" > /dev/null || { say 'FAIL apply'; exit 2; }
  done
fi
( cd "$C" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
printf 'tests/.one-*.sh\n' >> "$C/.git/info/exclude"
replace() {
  perl -e '
    my ($f, $old, $new) = @ARGV; local $/; open my $h, "<", $f or exit 3; my $t = <$h>; close $h;
    my $n = () = $t =~ /\Q$old\E/g; exit 4 if $n != 1;
    $t =~ s/\Q$old\E/$new/; open $h, ">", $f or exit 3; print $h $t; close $h; exit 0' "$C/$1" "$2" "$3"
}
judge() {
  ( cd "$C" && awk '$0 != "t_run_all"' "tests/$1" > "tests/.one-$1" && bash -c '. "tests/.one-$1"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out"; exit "$rc"' _ "$1" "$2" ) > "$w/judge.out" 2>&1
}
restore() {
  ( cd "$C" && git checkout -q -- . && rm -f tests/.one-*.sh ) || return 1
  cmp -s "$C/scripts/verification-lib.sh" "$P/scripts/verification-lib.sh" || say "FAIL restore not byte-identical"
}
f=()
while IFS= read -r -d '' v; do
  f+=("$v"); (( ${#f[@]} == 4 )) || continue
  id="${f[0]}"; old="${f[1]}"; new="${f[2]}"; judges="${f[3]}"; f=()
  replace scripts/verification-lib.sh "$old" "$new"; rc=$?
  if [[ "$rc" != 0 ]]; then say "== $id: literal did not apply once (rc $rc)"; restore; continue; fi
  for j in $judges; do
    judge "${j%%:*}" "${j#*:}"; rc=$?
    n="$(grep -c 'assert:' "$w/judge.out")"
    say "== $id ${j#*:} rc=$rc failing-asserts=$n"
    grep 'assert:' "$w/judge.out" | head -8 | cut -c1-260 | sed 's/^/  | /'
  done
  restore
done < "$MF"
say "r18-discover $label done $(date -u +%H:%M:%SZ)"
