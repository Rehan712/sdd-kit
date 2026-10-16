#!/usr/bin/env bash
# Decisions identity vs authorization parse, three kits.
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/dec; rm -rf $w; mkdir -p $w
export TMPDIR=$B/tmp
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
W='- 2026-09-27T15:55:36Z — waiver: gate=opponent; round=4; after=3; by=someone; reason=a waiver added later'
mk() { # name variant waiver?
  local f="$w/$1-$3.md"
  {
    printf -- '---\nspec: x\n---\n\n# STATUS\n\n## Where things stand\n\n'
    case "$2" in
      fenced) printf 'The STATUS shape, for reference:\n\n```markdown\n## Decisions log\n- entries go here\n```\n\n';;
      archive) printf '## Decisions log (archived, spec 001)\n\n- 2026-01-01 — old decision\n\n';;
      dup) :;;
      infence) :;;
    esac
    printf '## Decisions log\n\n- 2026-09-06 — one decision\n'
    [[ "$2" == infence ]] && printf -- '- 2026-09-07 — a decision quoting a report:\n\n  ```\n## Round 3\n  ```\n\n'
    [[ "$2" == dup ]] && printf '\n## Open questions / blockers\n\n- none\n\n## Decisions log\n\n- 2026-09-08 — second section\n'
    [[ "$3" == with ]] && printf '%s\n' "$W"
    printf '\n## Handoff note\n\nwhatever\n'
  } > "$f"
}
for v in fenced archive dup infence; do
  mk $v $v without; mk $v $v with
  for kit in pkit kit; do
    for l in C en_US.UTF-8; do
      for x in without with; do
        inloc "$l" bash -c '. "$1/scripts/verification-lib.sh"; vf_semantic_file .specify/specs/x/STATUS.md "$2" "$3"' _ "$B/$kit" "$w/$v-$x.md" "$w/$v-$x.$kit.$l.sem" || echo "semfail $kit $v $x"
      done
      if cmp -s "$w/$v-without.$kit.$l.sem" "$w/$v-with.$kit.$l.sem"; then id=SAME; else id=differ; fi
      printf '%-8s %-5s %-12s identity with/without waiver: %s\n' "$v" "$kit" "$l" "$id"
    done
  done
  # the authorization parse: does it read the waiver? (post-delta kernel)
  mkdir -p "$w/spec-$v"; cp "$w/$v-with.md" "$w/spec-$v/STATUS.md"
  out="$(inloc C bash -c '. "$1/scripts/verification-lib.sh"; declare -f vf_round_authorized >/dev/null && echo has' _ "$B/kit")"
done
echo '== the authorization parse reads the waiver the identity dropped (post-delta kernel)'
for v in fenced archive dup infence; do
  out="$(inloc C bash -c '. "$1/scripts/verification-lib.sh"; vf_round_authorized "$2" opponent 4 2026-09-27T00:00:00Z' _ "$B/kit" "$w/spec-$v" 2>&1)"; rc=$?
  printf '%-8s vf_round_authorized opponent 4: rc=%s %s\n' "$v" "$rc" "$(printf '%s' "$out" | head -1 | cut -c1-100)"
done
