#!/usr/bin/env bash
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/route; rm -rf $w; export TMPDIR=$B/tmp
sp=$w/.specify/specs/004-x; mkdir -p $sp
printf -- "---\nspec: 004-x\n---\n\n# Plan\n" > $sp/plan.md; printf -- '---\nspec: 004-x\n---\n\n## Backend\n\n- [x] **T001** — task\n  - *Acceptance:* x\n  - *Evidence:* ran it by hand, looked fine\n' > $sp/tasks.md
for v in '' ' ""' " ''" ' # none yet' ' 1' ' 2'; do
  printf -- '---\nspec: 004-x\nstatus: accepted\nverification_contract:%s\n---\n\n- AC-001: x\n' "$v" > $sp/spec.md
  line="verification_contract:$v |"
  for kit in pkit ckit; do
    out="$(cd $w && env -u LC_ALL LANG=C bash $B/$kit/scripts/spec-evidence.sh $sp 2>&1)"; rc=$?
    line="$line $kit spec-evidence rc=$rc ($(printf '%s' "$out" | tail -1 | cut -c1-60))"
  done
  out="$(env -u LC_ALL LANG=C bash -c '. "$1/scripts/verification-lib.sh"; vf_bindings "$2" tasks "" "$3"' _ $B/ckit $sp $w/b.nul 2>&1)"; rc=$?; rm -f $w/b.nul
  line="$line | ckit vf_bindings rc=$rc ($(printf '%s' "$out" | head -1 | cut -c1-70))"
  printf '%s\n' "$line"
done
