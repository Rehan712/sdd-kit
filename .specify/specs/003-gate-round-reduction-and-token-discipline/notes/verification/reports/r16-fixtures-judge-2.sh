#!/usr/bin/env bash
# The session-16 fixture correction judged in standalone copies BEFORE it is applied live, 2026-10-07 (session 16).
# Matrix v4's run of record (r16-mutations-shard0, rc 1) found row L17 surviving: the mutant that drops the reading as
# written (vf_label_read's fallback) survives its only row, `- \`<Severity>\` data-loss`, because T030o47's code-span
# reading now reads that row too. The reading as written alone reads a tier behind an undefined footnote reference,
# `- [^Severity] data-loss`, which markdown-it 12.3.2 and marked 17.0.5 both render literally (its first visible word is
# Severity) while the rendered readings take it for a footnote number: r16-edits/tgc-2.pairs adds that row to the
# manifest table and its twin to the canonical table. K is the live tree (the four files as r15-edits/post-apply-1,
# which r16-edits/pre-apply.sha256 records) with tgc-2 applied: report_record_line_cases must pass. L is K with L17's
# mutant: it must fail, on the two new rows and on no other. P is K with the kernel as it was before T030o47
# (r15-edits/pre-apply.sha256, rebuilt by reversing r16-session.diff): no failing assertion may name the two new rows
# there, since the reading as written (T030o44) reads them too, so they isolate a guard T030o47 shielded and are not
# round-15 members. Each function runs alone, as t_run_all runs a test, with a TMPDIR ending in `/`. Read-only against
# the live worktree, whose status outside notes/verification/ is compared before and after. Pattern:
# r15-fixtures-judge-2.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"; e="$WT/$r/r16-edits"
X="$SP/r16-fixtures-2"; K="$X/k"; L="$X/l"; P="$X/p"; w="$X/work"
rm -rf "$X"; mkdir -p "$K" "$w" "$X/tmp"
export TMPDIR="$X/tmp/"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
say "start $(date -u +%Y-%m-%dT%H:%M:%SZ); TMPDIR=$TMPDIR"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$K" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$K" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
check 'K: the four files hash as r16-edits/pre-apply (r15-edits/post-apply-1)' 4 "$(cd "$K" && shasum -a 256 -c "$e/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"
perl "$e/lit.pl" "$K/tests/test-gate-contracts.sh" "$e/tgc-2.pairs" > "$w/apply.log" 2>&1
check 'K: tgc-2.pairs applied, each block exactly once' 1 "$(grep -c '^applied 2 block(s) to .*test-gate-contracts.sh$' "$w/apply.log")"
check 'K: the suite still parses' 0 "$(bash -n "$K/tests/test-gate-contracts.sh"; echo $?)"
cp -R "$K" "$L"; cp -R "$K" "$P"
perl -e '
  my ($f) = @ARGV; local $/; open my $h, "<", $f or exit 3; my $t = <$h>; close $h;
  my $old = "  return (w != \"\") ? w : vf_label_word(s, labels)"; my $n = () = $t =~ /\Q$old\E/g; exit 4 if $n != 1;
  $t =~ s/\Q$old\E/  return w/; open $h, ">", $f or exit 3; print $h $t; close $h' "$L/scripts/verification-lib.sh"
check 'L: the L17 mutant applies exactly once' 0 "$?"
( cd "$X" && rm -rf prev && mkdir -p prev/scripts && cp "$K/scripts/verification-lib.sh" prev/scripts/ && cd prev && \
  awk '/^--- a\/scripts\/verification-lib.sh$/{p=1} p && /^--- a\/templates\//{p=0} p' "$WT/$r/r16-session.diff" > kernel.diff && patch -s -R -p1 < kernel.diff ) || { say 'FAIL rebuild of the pre-repair kernel'; exit 2; }
cp "$X/prev/scripts/verification-lib.sh" "$P/scripts/verification-lib.sh"
check 'P: the kernel hashes as r15-edits/pre-apply' "$(grep ' scripts/verification-lib.sh$' "$WT/$r/r15-edits/pre-apply.sha256" | cut -c1-64)" "$(shasum -a 256 "$P/scripts/verification-lib.sh" | cut -c1-64)"
judge() { # <kit> <test file> <case function> -> rc; output in $w/<kit>-<case>.out
  local K="$1" tf="$2" fn="$3" tag; tag="$(basename "$K")-$fn"
  ( cd "$K" && awk '$0 != "t_run_all"' "tests/$tf" > "tests/.one-$tf" && bash -c '. "tests/.one-$1"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out"; exit "$rc"' _ "$tf" "$fn"; echo $? > "$X/rc" ) > "$w/$tag.out" 2>&1
  rm -f "$K/tests/.one-$tf"; cat "$X/rc"
}
new='written as (second-tier-footnote-literal|footnote-literal) was not refused'
say '== K: report_record_line_cases passes with the new rows on the repaired kernel'
rc="$(judge "$K" test-gate-contracts.sh report_record_line_cases)"; check 'K report_record_line_cases passes' 0 "$rc"
[[ "$rc" == 0 ]] || grep -E '^ *assert: ' "$w/k-report_record_line_cases.out" | LC_ALL=C cut -c1-200 | sed 's/^/  | /' | head -20
say '== L: the L17 mutant fails on the two new rows and on no other'
rc="$(judge "$L" test-gate-contracts.sh report_record_line_cases)"; check 'L report_record_line_cases fails' 1 "$rc"
grep -E '^ *assert: ' "$w/l-report_record_line_cases.out" > "$w/l.asserts"
say "  | L: $(wc -l < "$w/l.asserts" | tr -d ' ') failing assertions"
check 'L: no failing assertion outside the new rows' 0 \
  "$(grep -v -c -E "$new|^ *assert: expected exit 3, got 0: record_line_vf" "$w/l.asserts" | tr -d ' ')"
grep -v -E "$new|^ *assert: expected exit 3, got 0: record_line_vf" "$w/l.asserts" | LC_ALL=C cut -c1-200 | sed 's/^/  | unexpected: /' | head -10
for lab in second-tier-footnote-literal footnote-literal; do
  for l in C en_US.UTF-8; do
    check "L fails on: written as $lab under LANG=$l" 1 "$(grep -c -F -- "written as $lab was not refused by name under LANG=$l (O-018)" "$w/l.asserts" | awk '{print ($1 > 0)}')"
  done
done
say '== P: on the kernel before T030o47 the two new rows are refused too (the reading as written predates it)'
rc="$(judge "$P" test-gate-contracts.sh report_record_line_cases)"; check 'P report_record_line_cases fails (on the round-15 rows)' 1 "$rc"
grep -E '^ *assert: ' "$w/p-report_record_line_cases.out" > "$w/p.asserts"
say "  | P: $(wc -l < "$w/p.asserts" | tr -d ' ') failing assertions"
check 'P: no failing assertion names the two new rows' 0 "$(grep -c -E "$new" "$w/p.asserts" | tr -d ' ')"
for f in "$w"/*.out; do cp "$f" "$WT/$r/r16-fixtures-judge-2-$(basename "$f")"; done
live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r16-fixtures-judge-2 failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
