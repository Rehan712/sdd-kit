#!/usr/bin/env bash
# spec-evidence.sh legacy artifact names: Unicode spaces and punctuation next to a name that exists.
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/art; rm -rf $w; export TMPDIR=$B/tmp
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
lg="$w/.specify/specs/001-legacy"; mkdir -p "$lg/shots"; : > "$lg/shots/a.png"
printf -- '---\nspec: 001-legacy\nstatus: accepted\n---\n\n- AC-001: legacy criterion\n' > "$lg/spec.md"
run() { # label evidence-text
  printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — Legacy task\n  - *Acceptance:* legacy\n  - *Evidence:* %s\n' "$2" > "$lg/tasks.md"
  local line="  $1:"
  for kit in pkit kit; do for l in C en_US.UTF-8; do
    out="$( cd "$lg" && inloc "$l" bash "$B/$kit/scripts/spec-evidence.sh" "$lg" 2>&1 )"; rc=$?
    line="$line $kit/$l rc=$rc$(printf '%s' "$out" | LC_ALL=C grep -o "names artifact '[^']*'" | head -1 | sed 's/^/ /')"
  done; done
  printf '%s\n' "$line"
}
echo 'shots/a.png exists in every row'
run ascii-space 'screenshot shots/a.png'
run nbsp "$(printf 'screenshot\302\240shots/a.png')"
run nnbsp "$(printf 'screenshot\342\200\257shots/a.png')"
run ideographic "$(printf '\346\210\252\345\233\276\343\200\200shots/a.png')"
run em-space "$(printf 'screenshot\342\200\203shots/a.png')"
run curly-quotes "$(printf '\342\200\234shots/a.png\342\200\235')"
run guillemets "$(printf '\302\253shots/a.png\302\273')"
run cjk-colon "$(printf '\346\210\252\345\233\276\357\274\232shots/a.png')"
run backticks 'screenshot `shots/a.png`'
run nbsp-only-evidence "$(printf '\302\240')"
