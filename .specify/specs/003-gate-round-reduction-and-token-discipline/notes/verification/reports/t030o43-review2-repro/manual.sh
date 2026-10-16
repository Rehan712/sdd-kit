#!/usr/bin/env bash
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/manual; rm -rf $w; mkdir -p $w; export TMPDIR=$B/tmp
SANDBOX=$w/sb; mkdir -p $SANDBOX; export SANDBOX
cd $B/ckit; . tests/helpers.sh >/dev/null 2>&1
spec="$(make_verification_git_dir manualobs)"
t="$spec/tasks.md"
for v in 'inspect the release artifact and record its digest' "$(printf '\302\240')" "$(printf '\342\200\203')" "$(printf '\343\200\200')" ''; do
  perl -0pi -e 's/(  - \*Verify:\* `manual: )[^`]*`/$1.$ENV{V}."`"/e' "$t" 2>/dev/null
  V="$v" perl -0pi -e 's/(  - \*Verify:\* `manual: )[^`]*`/$1$ENV{V}`/' "$t"
  line="observation=[$(printf '%s' "$v" | od -An -tx1 | tr -d ' \n' | cut -c1-20)]"
  for kit in pkit ckit; do for l in C en_US.UTF-8; do
    out="$(env -u LC_ALL -u LC_CTYPE LANG=$l bash -c '. "$1/scripts/verification-lib.sh"; vf_bindings "$2" tasks "" "$3"' _ $B/$kit $spec $w/b.nul 2>&1)"; rc=$?; rm -f $w/b.nul
    line="$line $kit/$l rc=$rc$(printf '%s' "$out" | LC_ALL=C grep -o 'manual Verify must be[^;]*' | head -1 | sed 's/^/ (/;s/$/)/')"
  done; done
  echo "$line"
done
LC_ALL=C grep -n 'Verify:\* `manual' "$t" | od -c | head -3
