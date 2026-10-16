#!/usr/bin/env bash
# Session 18, exploratory and read-only against the live worktree: candidate fixture rows for matrix v5, read by
# vf_reports directly in a standalone copy D of the live (repaired) tree, and in copies of D carrying one mutant each
# (r17-discover-mutants.py). For a positive (P): a manifest finding O-017 at wrong-result carrying the shape, under a
# CHALLENGED round recording O-017 open at wrong-result, must parse; the canonical twin (a finding G-042 at data-loss
# carrying the body in a CHALLENGED round) must parse. For a refusal (R): a manifest G-042 at minor carrying the body,
# under a CLEARED round re-recording G-042 at minor, must be refused with the diagnostic; the canonical twin is a
# CLEARED round whose new G-050 records minor and carries the body. Each case under LANG=C. It decides nothing.
# Usage from the worktree root: bash <this> <scratch-dir> <cases-file> <mutant-ids...>
set -uo pipefail
SP="${1:?scratch}"; CF="${2:?cases}"; shift 2; WT="$PWD"
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
X="$SP/r17-rows"; w="$X/work"; rm -rf "$X"; mkdir -p "$X/d" "$w" "$X/tmp"; export TMPDIR="$X/tmp/"
say() { printf '%s\n' "$*"; }
cp -R "$WT/scripts" "$X/d/scripts" || { say 'FAIL copy'; exit 2; }
SRC="$(printf 'a%.0s' {1..64})"
finding() { printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%s\n- **Scenario:** a recorded trigger\n- **Where:** a.sh:1\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** the rule\n%s' "$1" "$2" "$3" "$4" "${5:-}"; }
round() { printf '## Round %s\n**Round:** %s\n**Timestamp:** 2026-09-06T12:00:0%sZ\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nFinding records read by both readers.\n%s### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:%s -->\n' "$1" "$1" "$1" "$SRC" "$2" "$3" "$4" "$5" "$1"; }
mani() { mkdir -p "$1/notes/verification/reports"; printf '# Prior review\n\n%s' "$2" > "$1/notes/verification/reports/opponent-findings-review.md"; }
vfr() { # kit report spec -> rc, stderr in $w/err
  LC_ALL=C bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$1" "$2" "$w/cat.nul" "$3" < /dev/null > /dev/null 2> "$w/err"; echo $?
}
kits=(d)
for id in "$@"; do
  cp -R "$X/d" "$X/m-$id"
  python3 -I "$WT/$r/r17-discover-mutants.py" "$w/$id.nul" "$id" > /dev/null || { say "FAIL mutant $id"; continue; }
  perl -e 'local $/ = "\0"; open my $h, "<", $ARGV[0]; my @f = <$h>; chomp @f; my ($i, $old, $new) = @f;
    local $/; open my $k, "<", $ARGV[1]; my $t = <$k>; close $k; my $n = () = $t =~ /\Q$old\E/g; exit 4 if $n != 1;
    $t =~ s/\Q$old\E/$new/; open $k, ">", $ARGV[1]; print $k $t; close $k' "$w/$id.nul" "$X/m-$id/scripts/verification-lib.sh" || { say "FAIL apply $id"; continue; }
  kits+=("m-$id")
done
while IFS='|' read -r kind tag body diag; do
  [[ -n "$kind" && "$kind" != \#* ]] || continue
  b="$(printf '%b' "$body")"
  sm="$X/s-$tag-m"; sk="$X/s-$tag-k"; mkdir -p "$sm/notes" "$sk/notes"
  if [[ "$kind" == P ]]; then
    mani "$sm" "$(printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n%s' "$b")"$'\n'
    round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding new '- **Severity:** wrong-result')"$'\n' > "$sm/notes/opponent.md"
    round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss' "$b")"$'\n' > "$sk/notes/opponent.md"
  else
    mani "$sm" "$(printf '### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n%s' "$b")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sm/notes/opponent.md"
    round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new '- **Severity:** minor' "$b")"$'\n' > "$sk/notes/opponent.md"
  fi
  for k in "${kits[@]}"; do
    rm -f "$w/cat.nul"; rm -rf "$sk/notes/verification"
    rm_=$(vfr "$X/$k" "$sm/notes/opponent.md" "$sm"); em="$(sed -E 's#^report recovery: [^:]*:[0-9]+: ##; s#; reconcile canonical records$##; s#^manifest line [0-9]+: ##' "$w/err" | head -3 | tr '\n' '~' | cut -c1-160)"
    rk=$(vfr "$X/$k" "$sk/notes/opponent.md" "$sk"); ek="$(sed -E 's#^report recovery: [^:]*:[0-9]+: ##; s#; reconcile canonical records$##' "$w/err" | head -3 | tr '\n' '~' | cut -c1-160)"
    say "$kind $tag [$k] manifest rc=$rm_ ${em} | canonical rc=$rk ${ek}"
  done
done < "$CF"
say "r17-rows-probe done"
