#!/usr/bin/env bash
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/ph; rm -rf $w; mkdir -p $w; export TMPDIR=$B/tmp
SANDBOX=$w/sb; mkdir -p $SANDBOX; export SANDBOX
cd $B/ckit; . tests/helpers.sh >/dev/null 2>&1
spec="$(make_verification_git_dir ph)"
NB="$(printf '\302\240')" perl -pi -e 's/^\| manual-family \| manual \| AC-004 \| release-observation \|/| manual-family | manual | AC-004 | $ENV{NB} |/' "$spec/plan.md"
NB="$(printf "\302\240")" perl -pi -e "s/^  - \\*Tests:\\* release-observation\$/  - *Tests:* \$ENV{NB}/" "$spec/tasks.md"; LC_ALL=C grep -n "Tests:\\* ." "$spec/tasks.md" | tail -1 | od -c | tail -3
LC_ALL=C grep -n 'manual-family | manual' "$spec/plan.md" | od -c | sed -n 1,4p
for kit in pkit ckit; do for l in C en_US.UTF-8; do
  out="$(env -u LC_ALL -u LC_CTYPE LANG=$l bash -c '. "$1/scripts/verification-lib.sh"; vf_bindings "$2" tasks "" "$3"' _ $B/$kit $spec $w/b.nul 2>&1)"; rc=$?; rm -f $w/b.nul
  echo "$kit/$l rc=$rc $(printf '%s' "$out" | LC_ALL=C grep -i 'manual\|observation' | head -2 | tr '\n' ' ' | cut -c1-200)"
done; done
