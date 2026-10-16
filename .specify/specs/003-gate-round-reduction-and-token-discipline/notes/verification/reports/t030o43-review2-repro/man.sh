#!/usr/bin/env bash
# Manifest pass attacks: pkit (pre-delta), rkit (reviewed), kit (repaired).
set -uo pipefail
B=/private/tmp/rev2-t030o43; w=$B/work/man; rm -rf $w; mkdir -p $w
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
  for kit in pkit rkit kit; do for l in C en_US.UTF-8; do printf '  %-16s %-4s %-11s %s\n' "$label" "$kit" "$l" "$(vfr "$kit" "$l" "$sp/notes/opponent.md" "$sp")"; done; done
}
LOW='CLEARED tier-binding open minor 0 1'
echo '== control: ASCII manifest, lowered tier must refuse'
row control '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n' $LOW
echo '== heading spellings the pass cannot read (the finding at data-loss, the round lowers it)'
row lower-heading '# Prior review\n\n### finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n' $LOW
row upper-heading '# Prior review\n\n### FINDING G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n' $LOW
row indent-heading '# Prior review\n\n ### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n' $LOW
row prefixed-heading '# Prior review\n\n### Opponent finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n' $LOW
row bom-first '\357\273\277### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n' $LOW
row zwsp-heading '# Prior review\n\n\342\200\213### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n' $LOW
echo '== a missed heading merges into the finding above it (G-041 data-loss, then G-042 minor)'
row merge '# Prior review\n\n### Finding G-041\n- **Class:** tier-binding\n- **Severity:** data-loss\n\n### finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n' CLEARED tier-binding open minor 0 1 G-041
echo '== Severity spellings the marker test does not see'
row sev-colon-out '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity**: data-loss\n' $LOW
row sev-plain '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- Severity: data-loss\n' $LOW
row sev-lower '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **severity:** data-loss\n' $LOW
row sev-italic '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- *Severity:* data-loss\n' $LOW
row sev-twice '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n- **Severity:** minor\n' $LOW
echo '== plausible manifests that should parse'
row prose-marker '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n- **Scenario:** a field line written `-<U+00A0>**Class:**` was skipped\n' CLEARED tier-binding open data-loss 1 0
row title-heading '# Prior review\n\n### Finding G-042 — tier binding lost\n- **Class:** tier-binding\n- **Severity:** data-loss\n' CHALLENGED tier-binding open data-loss 1 0
row findings-h2 '# Prior review\n\n## Findings\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n\n## Finding summary\n\nOne finding.\n' CHALLENGED tier-binding open data-loss 1 0
row indented-code '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n- **Scenario:** the report read:\n\n      - **Severity:** minor\n' CHALLENGED tier-binding open data-loss 1 0
row fenced-example '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n\n```\n- **Severity:** minor\n```\n' CHALLENGED tier-binding open data-loss 1 0
row class-only '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n' CHALLENGED tier-binding open data-loss 1 0
row followup-tail '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n\n## Follow-up tasks proposed\n\n- **T001** — fix it; its **Severity:** stays data-loss\n' CHALLENGED tier-binding open data-loss 1 0
