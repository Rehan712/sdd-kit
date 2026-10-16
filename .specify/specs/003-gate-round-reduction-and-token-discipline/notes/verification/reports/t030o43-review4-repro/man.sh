#!/usr/bin/env bash
# usage: man.sh <kit> <label> <manifest-printf-%b-body> [report-finding spec id:class:status:sev]
K="$1"; label="$2"; body="$3"; rf="${4:-G-042:tier-binding:open:minor}"
export TMPDIR=/private/tmp/rev4-t030o43/tmp
w=$(mktemp -d /private/tmp/rev4-t030o43/tmp/m.XXXXXX); spec="$w/spec"; mkdir -p "$spec/notes/verification/reports"
tier_round_fixture() {
  local n="$1" verdict_override="$2"; shift 2
  local f id class status sev blockers=0 minors=0 verdict body=''
  for f in "$@"; do
    IFS=: read -r id class status sev <<< "$f"
    if [[ "$status" != resolved ]]; then case "$sev" in minor|degraded) minors=$((minors+1));; *) blockers=$((blockers+1));; esac; fi
    body+="$(printf '### Finding %s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** bind the tier the way Class is bound' "$id" "$class" "$status" "$sev")"$'\n'
  done
  if [[ -n "$verdict_override" ]]; then verdict="$verdict_override"; elif (( blockers )); then verdict=CHALLENGED; else verdict=CLEARED; fi
  printf '## Round %s\n**Round:** %s\n**Timestamp:** 2026-09-06T12:00:0%sZ\n' "$n" "$n" "$n"
  printf '**Source:** aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n'
  printf '**Floor:** FLOOR-fixture\n**Verdict:** %s\n' "$verdict"
  printf '**Blocking:** %s · **Minor:** %s\n' "$blockers" "$minors"
  printf '### What I attacked\nSeverity tier binding across rounds of one gate.\n'
  printf '%s' "$body"
  printf '### Held up / follow-up tasks\nFixture disposition recorded.\n'
  printf '<!-- gate-round-end: opponent:%s -->\n' "$n"
}
IFS=, read -ra fs <<< "$rf"
tier_round_fixture 1 '' "${fs[@]}" > "$spec/notes/opponent.md"
printf '%b' "$body" > "$spec/notes/verification/reports/opponent-findings-review.md"
for l in C en_US.UTF-8; do
  args=(); for name in $(compgen -e); do case "$name" in LC_*) args+=(-u "$name");; esac; done
  out="$(env ${args[@]+"${args[@]}"} LANG="$l" bash -c '. "$1/scripts/verification-lib.sh"; vf_reports "$2" opponent "$3" "$4"' _ "$K" "$spec/notes/opponent.md" "$w/out.nul" "$spec" 2>&1)"; rc=$?
  printf '[%s] %s %-12s rc=%s %s\n' "$label" "${K##*/}" "$l" "$rc" "$(printf '%s' "$out" | tr '\n' '|' | cut -c1-230)"
done
rm -rf "$w"
