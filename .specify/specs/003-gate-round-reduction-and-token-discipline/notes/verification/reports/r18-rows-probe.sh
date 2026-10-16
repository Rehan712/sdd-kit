#!/usr/bin/env bash
# Session 20, exploratory and read-only against the live worktree (pattern: r17-rows-probe.sh): the tgc-2 rows for
# the settled-test mutants S03, S09 and S10, which r18-fixtures-judge-2 found passing under their mutants, read by
# vf_reports directly in a standalone copy D of the live (repaired) tree, and in copies of D carrying one mutant each
# (r18-discover-mutants.py), each row as tgc-2 wrote it (the construct completed on the line after it opens) and with
# one line inside the construct before the completing line. Kind W is a whole manifest (no G-042 head added), read
# in the manifest pass only. With MUTFILE=<nul> the mutants come from that file (records id, old, new, judges).
# Session 20 later: D04 (v5's open-code-span condition of vf_settled), with r18-rows-probe-3.cases. For a positive (P): a manifest finding O-017 at wrong-result carrying the shape, under a
# CHALLENGED round recording O-017 open at wrong-result, must parse; the canonical twin (a finding G-042 at data-loss
# carrying the body in a CHALLENGED round) must parse. For a refusal (R): a manifest G-042 at minor carrying the body,
# under a CLEARED round re-recording G-042 at minor, must be refused with the diagnostic; the canonical twin is a
# CLEARED round whose new G-050 records minor and carries the body. Each case under LANG=C. It decides nothing.
# Usage from the worktree root: bash <this> <scratch-dir> <cases-file> <mutant-ids...>
set -uo pipefail
SP="${1:?scratch}"; CF="${2:?cases}"; shift 2; WT="$PWD"
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
X="$SP/r18-rows"; w="$X/work"; rm -rf "$X"; mkdir -p "$X/d" "$w" "$X/tmp"; export TMPDIR="$X/tmp/"
say() { printf '%s\n' "$*"; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " ${r%/reports}/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
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
  if [[ -n "${MUTFILE:-}" ]]; then perl -e 'local $/ = "\0"; my @f = <STDIN>; for (my $i = 0; $i < @f; $i += 4) { (my $k = $f[$i]) =~ s/\0$//; print @f[$i .. $i + 3] if $k eq $ARGV[0] }' "$id" < "$MUTFILE" > "$w/$id.nul"; [[ -s "$w/$id.nul" ]] || { say "FAIL mutant $id"; continue; }
  else python3 -I "$WT/$r/r18-discover-mutants.py" "$X/d/scripts/verification-lib.sh" "$w/$id.nul" "$id" > /dev/null || { say "FAIL mutant $id"; continue; }; fi
  perl -e 'local $/ = "\0"; open my $h, "<", $ARGV[0]; my @f = <$h>; chomp @f; my ($i, $old, $new) = @f;
    local $/; open my $k, "<", $ARGV[1]; my $t = <$k>; close $k; my $n = () = $t =~ /\Q$old\E/g; exit 4 if $n != 1;
    $t =~ s/\Q$old\E/$new/; open $k, ">", $ARGV[1]; print $k $t; close $k' "$w/$id.nul" "$X/m-$id/scripts/verification-lib.sh" || { say "FAIL apply $id"; continue; }
  kits+=("m-$id")
done
while IFS='|' read -r kind tag body diag; do
  [[ -n "$kind" && "$kind" != \#* ]] || continue
  b="$(printf '%b' "$body")"
  sm="$X/s-$tag-m"; sk="$X/s-$tag-k"; mkdir -p "$sm/notes" "$sk/notes"
  if [[ "$kind" == W ]]; then
    mani "$sm" "$b"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sm/notes/opponent.md"
    for k in "${kits[@]}"; do
      rm -f "$w/cat.nul"
      rm_=$(vfr "$X/$k" "$sm/notes/opponent.md" "$sm"); em="$(sed -E 's#^report recovery: [^:]*:[0-9]+: ##; s#; reconcile canonical records$##; s#^manifest line [0-9]+: ##' "$w/err" | head -3 | tr '\n' '~' | cut -c1-160)"
      say "$kind $tag [$k] manifest rc=$rm_ ${em}"
    done
    continue
  elif [[ "$kind" == P ]]; then
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
live_after="$(livestate)"
[[ "$live_before" == "$live_after" ]] && say "PASS live worktree status outside notes/verification/ unchanged" || { say "FAIL live status moved"; exit 1; }
say "r18-rows-probe done"
