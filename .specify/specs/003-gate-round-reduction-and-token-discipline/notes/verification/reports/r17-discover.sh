#!/usr/bin/env bash
# Session 18, exploratory and read-only against the live worktree: for each candidate mutant of matrix v5 (a NUL file of
# records id, old, new, judges, written by r17-discover-mutants.py), apply it once to a standalone copy built from the
# live enumeration, run each named judge (one fixture function alone, as the matrix runs it, under a TMPDIR ending in
# `/`), and print its rc and the first failing assertions; restore and check byte-identical. It decides nothing: it
# tells which existing rows kill a mutant, so that v5 names real rows. Harness: r15-mutations.sh.
# Usage: bash r17-discover.sh <scratchpad-dir> <worktree> <mutants.nul> <label>
set -uo pipefail
SP="$1"; WT="$2"; MF="$3"; label="$4"
R="$SP/r17-disc-$label"; C="$R/copy"; P="$R/pristine"; w="$R/work"
export TMPDIR="$R/tmp/"
rm -rf "$R"; mkdir -p "$C" "$P" "$w" "$TMPDIR"
say() { printf '%s\n' "$*"; }
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul" || { say 'FAIL enumeration'; exit 2; }
for d in "$C" "$P"; do ( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$d" && tar -xf - ) || { say 'FAIL extraction'; exit 2; }; done
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
say "r17-discover $label done $(date -u +%H:%M:%SZ)"
