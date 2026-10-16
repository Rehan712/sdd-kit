#!/usr/bin/env bash
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/agent; rm -rf $w; mkdir -p $w; export TMPDIR=$B/tmp
SANDBOX=$w/sb; mkdir -p $SANDBOX; export SANDBOX
cd $B/ckit; . tests/helpers.sh >/dev/null 2>&1
spec="$(make_verification_git_dir agentpath)"; repo="$(cd "$spec/../../.." && pwd -P)"
mkdir -p "$repo/agents"; : > "$repo/agents/opponent.agent.md"; : > "$repo/agents/reality-check.agent.md"
for variant in plain nbsp; do
  cp "$spec/tasks.md" "$w/tasks.orig" 2>/dev/null || true
  [[ $variant == nbsp ]] && NB="$(printf '\302\240')" perl -pi -e 's/^(  - \*Agent:\*) agents\/opponent/$1 $ENV{NB}agents\/opponent/' "$spec/tasks.md"
  for kit in pkit ckit; do for l in C en_US.UTF-8; do
    out="$(cd "$repo" && env -u LC_ALL -u LC_CTYPE LANG=$l bash $B/$kit/scripts/sdd-analyze.sh "$spec" 2>&1)"; rc=$?
    echo "$variant $kit/$l rc=$rc $(printf '%s' "$out" | LC_ALL=C grep -i 'opponent gate\|Opponent' | head -1 | cut -c1-120)"
  done; done
done
