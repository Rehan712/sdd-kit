#!/usr/bin/env bash
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/snap; rm -rf $w; mkdir -p $w; export TMPDIR=$B/tmp
r=$w/repo; sp=.specify/specs/004-x; mkdir -p $r/$sp
( cd $r && git init -q )
printf -- '---\nspec: 004-x\nstatus: accepted\n---\n\n- AC-001: x\n' > $r/$sp/spec.md
printf -- '---\nspec: 004-x\n---\n\n# Plan\n' > $r/$sp/plan.md
printf -- '---\nspec: 004-x\n---\n\n## Backend\n\n- [ ] **T001** — task\n' > $r/$sp/tasks.md
cp $B/work/dec/dup-without.md $r/$sp/STATUS.md
( cd $r && git add -A && git -c user.name=r -c user.email=r@invalid commit -qm base )
for kit in pkit ckit; do
  for v in without with; do
    cp $B/work/dec/dup-$v.md $r/$sp/STATUS.md
    d=$(cd $r && env -u LC_ALL LANG=C bash -c '. "$1/scripts/verification-lib.sh"; vf_snapshot "$2" "$3" "$3" "$4"' _ $B/$kit $r/$sp $r $w/snap-$kit-$v.nul 2>$w/err); rc=$?
    echo "$kit STATUS=$v rc=$rc digest=${d:0:16} $(head -c 100 $w/err)"
  done
done
