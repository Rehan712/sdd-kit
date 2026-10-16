#!/usr/bin/env bash
# Manifest pass attacks: pkit (pre-delta), rkit (reviewed), kit (repaired).
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/man; mkdir -p $w
export TMPDIR=$B/tmp
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
report() { # file verdict class status sev blocking minor [id]
  printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nManifest tier binding.\n### Finding %s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read the manifest\n### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n' \
    "$SRC" "$2" "$6" "$7" "${8:-G-042}" "$3" "$4" "$5" > "$1"
}
vfr() { # kit locale report spec
  inloc "$2" bash -c '. "$1/scripts/verification-lib.sh" && vf_reports "$2" opponent "$3" "$4"' _ "$B/$1" "$3" "$w/out.nul" "$4" > "$w/o" 2> "$w/e"
  local rc=$?
  printf 'rc=%s | %s' "$rc" "$(LC_ALL=C grep -v towc "$w/e" | head -1 | LC_ALL=C sed "s#$w/##g" | cut -c1-120)"
}
row() { # label manifest-printf-format [report args...]
  local label="$1" m="$2" sp="$w/spec-$1"; shift 2
  mkdir -p "$sp/notes/verification/reports"; printf "$m" > "$sp/notes/verification/reports/opponent-findings-review.md"
  report "$sp/notes/opponent.md" "$@"
  for kit in pkit ckit; do for l in C en_US.UTF-8; do printf '  %-16s %-4s %-11s %s\n' "$label" "$kit" "$l" "$(vfr "$kit" "$l" "$sp/notes/opponent.md" "$sp")"; done; done
}
LOW='CLEARED tier-binding open minor 0 1'
LOW='CLEARED tier-binding open minor 0 1'
row nbsp-before-hash '# Prior review\n\n\302\240### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n' $LOW
row nbsp-before-hash2 '# Prior review\n\n### Finding G-041\n- **Class:** other\n- **Severity:** minor\n\n\302\240### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n' $LOW
