#!/usr/bin/env bash
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/hist; rm -rf $w; mkdir -p $w; export TMPDIR=$B/tmp
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
for sp in $B/kit/.specify/specs/*/; do
  s=$(basename $sp)
  for l in C en_US.UTF-8; do
    for kit in rkit kit; do ( cd $B/$kit && inloc $l bash scripts/spec-gate.sh tally "$sp" ) > $w/$kit.out 2>&1; echo "rc=$?" >> $w/$kit.out; done
    printf '%-50s %-11s %s (%s)\n' "$s" "$l" "$(cmp -s $w/rkit.out $w/kit.out && echo identical || echo DIFFER)" "$(tail -1 $w/kit.out)"
  done
done
