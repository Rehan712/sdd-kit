#!/usr/bin/env bash
# Session 19: r18-edits/tgc-2.pairs judged in standalone copies BEFORE it is applied live. Matrix v6 needs rows that
# isolate guards of T030o51, T030o52 and T030o53 which no row of tgc-1 reached (found by r18-discover.sh with
# r18-discover-mutants.py, r18-discover-{a,b,c}.log). K is the live tree (the repair applied,
# r18-edits/post-apply-1.sha256) with tgc-2 applied: report_record_line_cases and report_manifest_locale_cases must
# pass. For each mutant (literal from r18-discover-mutants.py, read against K's kernel), a copy of K carrying it must
# fail on each row named for it; failing assertions outside the named rows are listed, not judged (another row may
# kill the same mutant). Each function runs alone, as t_run_all runs a test, with a TMPDIR ending in `/`. Read-only
# against the live worktree, whose status outside notes/verification/ is compared before and after.
# Session 20 (run 4): the three image rows of S03, S09 and S10 carry a line inside the image
# (r18-fixtures-judge-2-run2.note), and R03, S07 and S08, listed by session 19 as equivalents, are judged by rows
# measured to isolate them (r18-rows-probe-2, r18-fixtures-judge-2-run3.note).
# Pattern: r17-fixtures-judge-2.sh. Usage from the worktree root: SHARD=i/n bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"; SHARD="${SHARD:-0/1}"; si="${SHARD%/*}"; sn="${SHARD#*/}"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"; e="$WT/$r/r18-edits"
X="$SP/r18-fixtures-2-$si"; K="$X/k"; w="$X/work"
rm -rf "$X"; mkdir -p "$K" "$w" "$X/tmp"
export TMPDIR="$X/tmp/"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
say "start $(date -u +%Y-%m-%dT%H:%M:%SZ) shard $SHARD; TMPDIR=$TMPDIR"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$K" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
check 'K: the four files hash as r18-edits/post-apply-1' 4 "$(cd "$K" && shasum -a 256 -c "$e/post-apply-1.sha256" 2>/dev/null | grep -c ': OK$')"
perl "$e/lit.pl" "$K/tests/test-gate-contracts.sh" "$e/tgc-2.pairs" > "$w/apply.log" 2>&1
check 'K: tgc-2.pairs applied, each block exactly once' 1 "$(grep -c '^applied 5 block(s) to .*test-gate-contracts.sh$' "$w/apply.log")"
check 'K: the suite still parses' 0 "$(bash -n "$K/tests/test-gate-contracts.sh"; echo $?)"
( cd "$K" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
judge() { # <kit> <case function> -> rc; output in $w/<tag>.out
  local K="$1" fn="$2" tag; tag="$(basename "$K")-$fn"
  ( cd "$K" && awk '$0 != "t_run_all"' tests/test-gate-contracts.sh > tests/.one-gc.sh && bash -c '. tests/.one-gc.sh
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$1"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out"; exit "$rc"' _ "$fn"; echo $? > "$X/rc" ) > "$w/$tag.out" 2>&1
  rm -f "$K/tests/.one-gc.sh"; cat "$X/rc"
}
RL=report_record_line_cases; ML=report_manifest_locale_cases
if [[ "$si" == 0 ]]; then
  say '== K: both functions pass with the new rows on the repaired kernel'
  for fn in $RL $ML; do
    rc="$(judge "$K" $fn)"; check "K $fn passes" 0 "$rc"
    [[ "$rc" == 0 ]] || grep -E '^ *assert: ' "$w/k-$fn.out" | LC_ALL=C cut -c1-220 | sed 's/^/  | /' | head -20
  done
fi
mm() { printf 'a plausible manifest (%s) was refused' "$1"; }
mr() { printf 'a manifest tier written as %s was not refused' "$1"; }
kr() { printf 'a second tier written as %s was not refused' "$1"; }
kp() { printf 'a canonical finding with %s was refused' "$1"; }
HU='raw HTML in Held-up prose outside every finding was refused'
both() { printf '%s\n%s\n' "$(mr "$1")" "$(kr "$1")"; }
tl() { printf 'a canonical finding whose tail is %s was not refused' "$1"; }
expect() { # <mutant id>: the messages the rows named for it print when it is applied, one per line
  case "$1" in
    C01) both destination-after-space;;
    C03) both angle-destination-with-space;;
    C04) both angle-destination-escaped-gt;;
    C05) mm invalid-angle-destination-holding-lt; echo; kp a-invalid-angle-destination-holding-lt; echo;;
    C06) mm unclosed-angle-destination; echo; kp a-unclosed-angle-destination; echo;;
    C07) both destination-escaped-paren;;
    C08) mm destination-with-space-then-code; echo; kp a-destination-with-space-then-code; echo;;
    C09|C10) both destination-nested-parens;;
    C11) both bare-destination-at-line-end;;
    C14) both title-in-parens;;
    C15) both title-escaped-quote;;
    C17) both title-then-line-end;;
    C18) mm destination-then-code-span; echo; kp a-destination-then-code-span; echo;;
    C19) both destination-space-at-line-end;;
    L01) both label-escaped-bracket;;
    L02) mm bracket-inside-label-position; echo; kp a-bracket-inside-label-position; echo;;
    F08) mr fence-after-tab; echo; tl fence-after-tab; echo;;
    R06) mm nested-bracket-then-colon-at-line-start; echo; kp a-nested-bracket-then-colon-at-line-start; echo;;
    R09) mm bracket-left-open-before-blank-line; echo; kp a-bracket-left-open-before-blank-line; echo;;
    S03) both ordered-number-then-image;;
    S10) both image-alt-beginning-with-code-span-across-lines;;
    S09) mr break-image-outside-finding-after-id; echo;;
    R03) both definition-after-quote-marker;;
    S07) mr image-title-across-lines-outside-finding-after-id; echo;;
    S08) mr tag-image-alt-code-span-outside-finding-after-id; echo;;
    H03) mr heading-tag-on-deeper-heading; echo;;
    H05) kr title-tag-inside-finding; echo;;
    H07) kr heading-tag-on-deeper-heading; echo;;
  esac
}
MUT=(C01 C03 C04 C05 C06 C07 C08 C09 C10 C11 C14 C15 C17 C18 C19 L01 L02 F08 R06 R09 S03 S09 S10 H03 H05 H07 R03 S07 S08)
i=0
for id in "${MUT[@]}"; do
  i=$((i+1)); (( (i - 1) % sn == si )) || continue
  M="$X/m-$id"; rm -rf "$M"; cp -R "$K" "$M"
  python3 -I "$WT/$r/r18-discover-mutants.py" "$K/scripts/verification-lib.sh" "$w/$id.nul" "$id" > /dev/null || { say "FAIL $id: no such mutant"; fails=$((fails+1)); continue; }
  perl -e 'local $/ = "\0"; open my $h, "<", $ARGV[0]; my @f = <$h>; chomp @f; my ($i, $old, $new) = @f;
    local $/; open my $k, "<", $ARGV[1]; my $t = <$k>; close $k; my $n = () = $t =~ /\Q$old\E/g; exit 4 if $n != 1;
    $t =~ s/\Q$old\E/$new/; open $k, ">", $ARGV[1]; print $k $t; close $k' "$w/$id.nul" "$M/scripts/verification-lib.sh"
  check "$id: the mutant applies exactly once" 0 "$?"
  : > "$w/$id.asserts"
  expect "$id" | grep . > "$w/$id.expect"
  fns=$RL; grep -q -E 'plausible manifest' "$w/$id.expect" && fns="$ML"
  grep -q -E 'tier written as|canonical finding with|whose tail is' "$w/$id.expect" && fns="$fns $RL"
  for fn in $(printf '%s\n' $fns | LC_ALL=C sort -u); do judge "$M" "$fn" > /dev/null; grep -E '^ *assert: ' "$w/m-$id-$fn.out" >> "$w/$id.asserts"; done
  say "== $id ($fns): $(wc -l < "$w/$id.asserts" | tr -d ' ') failing assertions"
  while IFS= read -r msg; do
    check "$id fails on: $msg" 1 "$(grep -c -F -- "$msg" "$w/$id.asserts" | awk '{print ($1 > 0)}')"
  done < "$w/$id.expect"
  grep -v -F -f "$w/$id.expect" "$w/$id.asserts" | grep -v -E 'assert: expected exit [0-9], got [0-9]' | LC_ALL=C cut -c1-200 | sed 's/^/  | also: /' | head -6
  rm -rf "$M"
done
for f in "$w"/*.out "$w"/*.asserts; do [[ -e "$f" ]] && cp "$f" "$WT/$r/r18-fixtures-judge-2-$si-$(basename "$f")"; done
live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r18-fixtures-judge-2 shard $SHARD failures=$fails"
(( fails == 0 ))
