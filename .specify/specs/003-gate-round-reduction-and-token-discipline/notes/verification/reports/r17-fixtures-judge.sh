#!/usr/bin/env bash
# The fixtures for round 16's O-018, O-022 and O-023 repair judged in standalone copies BEFORE they are applied live,
# 2026-10-08 (session 17), in both directions: FX is CUR (the four files as r17-edits/pre-apply) with the fixture
# pairs r17-edits/tgc-1.pairs and tsg-1.pairs applied (the kernel unrepaired), and DX is FX with the candidate
# kernel-1.pairs and vc-1.pairs applied too. Each changed fixture function runs alone, as t_run_all runs a test (a
# fresh SANDBOX, the build-failure record checked), with a TMPDIR ending in `/`. On DX every changed function must
# pass. On FX: report_manifest_locale_cases must fail only on the plausible manifests that carry raw HTML inside the
# finding, which parse on the unrepaired kernel (the user's narrowed grammar turns them into refusals), its new
# positives passing; report_record_line_cases must fail only on the round-16 member rows and the rows the narrowed
# grammar turns into refusals (the a-* rows that carry raw HTML, the Where value with br and p tags, the Where value
# with a carriage return, O-021's HTML blocks), its new positives passing; the end-to-end round_record_line_cases,
# which stops at its first failure, must fail first at a new row. Read-only against the live worktree, whose status
# outside notes/verification/ is compared before and after. Pattern: r16-fixtures-judge.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"; e="$WT/$r/r17-edits"
X="$SP/r17-fixtures"; FX="$X/fx"; DX="$X/dx"; w="$X/work"
rm -rf "$X"; mkdir -p "$FX" "$w" "$X/tmp"
export TMPDIR="$X/tmp/"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
say "start $(date -u +%Y-%m-%dT%H:%M:%SZ); TMPDIR=$TMPDIR"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$FX" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$FX" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
check 'FX: the four files hash as r17-edits/pre-apply' 4 "$(cd "$FX" && shasum -a 256 -c "$e/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"
perl "$e/lit.pl" "$FX/tests/test-gate-contracts.sh" "$e/tgc-1.pairs" > "$w/apply.log" 2>&1
perl "$e/lit.pl" "$FX/tests/test-spec-gate.sh" "$e/tsg-1.pairs" >> "$w/apply.log" 2>&1
check 'FX: tgc-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 7 block(s) to .*test-gate-contracts.sh$' "$w/apply.log")"
check 'FX: tsg-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 4 block(s) to .*test-spec-gate.sh$' "$w/apply.log")"
cp -R "$FX" "$DX"
perl "$e/lit.pl" "$DX/scripts/verification-lib.sh" "$e/kernel-1.pairs" >> "$w/apply.log" 2>&1
perl "$e/lit.pl" "$DX/templates/verification-contract.md" "$e/vc-1.pairs" >> "$w/apply.log" 2>&1
check 'DX: kernel-1.pairs applied' 1 "$(grep -c '^applied 6 block(s) to .*dx/scripts/verification-lib.sh$' "$w/apply.log")"
check 'DX: vc-1.pairs applied' 1 "$(grep -c '^applied 1 block(s) to .*dx/templates/verification-contract.md$' "$w/apply.log")"
for k in FX DX; do K="$X/$(printf '%s' "$k" | tr 'A-Z' 'a-z')"; check "$k: both suites still parse" '0 0' "$(bash -n "$K/tests/test-gate-contracts.sh"; printf '%s ' $?; bash -n "$K/tests/test-spec-gate.sh"; printf '%s' $?)"; done
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
CASES='test-gate-contracts.sh:report_manifest_locale_cases test-gate-contracts.sh:report_record_line_cases test-spec-gate.sh:round_record_line_cases'
say '== DX: every changed fixture function passes on the repaired kernel'
for c in $CASES; do
  rc="$(judge "$DX" "${c%%:*}" "${c#*:}")"; check "DX ${c#*:} passes" 0 "$rc"
  [[ "$rc" == 0 ]] || grep -E '^ *assert: ' "$w/dx-${c#*:}.out" | LC_ALL=C cut -c1-200 | sed 's/^/  | /' | head -20
done
say '== FX: on the unrepaired kernel'
rc="$(judge "$FX" test-gate-contracts.sh report_manifest_locale_cases)"; check 'FX report_manifest_locale_cases fails' 1 "$rc"
grep -E '^ *assert: ' "$w/fx-report_manifest_locale_cases.out" > "$w/fx-ml.asserts"
moved='carrying raw HTML \((severity-then-pre-block|severity-then-comment|severity-then-div|severity-then-details|severity-then-closing-tag|wrapped-tag-prose|fenced-tag-example|heading-then-attribute-line|br-prose|quoted-heading-then-attribute-line|span-in-prose|blank-line-ends-run)\) was not refused'
check 'FX report_manifest_locale_cases: no failing assertion outside the twelve rows the narrowed grammar refuses and their exit checks' 0 \
  "$(grep -v -E "$moved|^ *assert: expected exit 3, got 0: bash -c" "$w/fx-ml.asserts" | wc -l | tr -d ' ')"
grep -v -E "$moved|^ *assert: expected exit 3, got 0: bash -c" "$w/fx-ml.asserts" | LC_ALL=C cut -c1-200 | sed 's/^/  | unexpected: /' | head -10
check 'FX report_manifest_locale_cases: each of the twelve fails' 12 "$(grep -c -E "$moved" "$w/fx-ml.asserts" | tr -d ' ')"
rc="$(judge "$FX" test-gate-contracts.sh report_record_line_cases)"; check 'FX report_record_line_cases fails' 1 "$rc"
grep -E '^ *assert: ' "$w/fx-report_record_line_cases.out" > "$w/fx-rl.asserts"
say "  | FX report_record_line_cases: $(wc -l < "$w/fx-rl.asserts" | tr -d ' ') failing assertions"
mrows='pre-in-prose|hgroup-in-prose|listing-in-prose|xmp-in-prose|plaintext-in-prose|br-in-link-text|p-in-link-text|tag-holding-backtick|autolink-holding-backtick|autolink-before-label|tag-split-by-form-feed|tag-split-by-seven-marks|html-block-heading|escaped-backtick-then-br|lone-carriage-return|form-feed-in-text|vertical-tab-in-text|escaped-backslash-code-span|escaped-first-backtick|image-split-by-seven-marks|image-split-by-eight-marks-quoted|image-after-backtick-info-fence|tag-split-by-vertical-tab|tag-split-by-eight-marks-quoted'
conv='a canonical finding with (a-empty-comment-then-prose|a-wrapped-tag-prose|a-fenced-tag-example|a-heading-then-attribute-line|a-br-prose|a-quoted-heading-then-attribute-line|a-span-in-prose|a-blank-line-ends-run) was not refused as raw HTML|a Where value with br and p tags was not refused as raw HTML|a Where value holding a carriage return was not refused|a Severity line followed by a (div-block|details-block|closing-tag) was not refused as raw HTML'
check 'FX report_record_line_cases: no failing assertion outside the new member rows, the rows turned into refusals, and their exit checks' 0 \
  "$(grep -v -E "written as ($mrows) was not refused|$conv|^ *assert: expected exit 3, got 0: record_line_vf" "$w/fx-rl.asserts" | wc -l | tr -d ' ')"
grep -v -E "written as ($mrows) was not refused|$conv|^ *assert: expected exit 3, got 0: record_line_vf" "$w/fx-rl.asserts" | LC_ALL=C cut -c1-200 | sed 's/^/  | unexpected: /' | head -10
for lab in a-empty-comment-then-prose a-wrapped-tag-prose a-fenced-tag-example a-heading-then-attribute-line a-br-prose a-quoted-heading-then-attribute-line a-span-in-prose a-blank-line-ends-run; do
  check "FX report_record_line_cases fails on the narrowed row $lab under both locales" 2 "$(grep -c -F -- "a canonical finding with $lab was not refused as raw HTML" "$w/fx-rl.asserts")"
done
for lab in 'a Where value with br and p tags was not refused as raw HTML' 'a Where value holding a carriage return was not refused' 'a Severity line followed by a div-block' 'a Severity line followed by a details-block' 'a Severity line followed by a closing-tag'; do
  check "FX report_record_line_cases fails on: $lab, under both locales" 2 "$(grep -c -F -- "$lab" "$w/fx-rl.asserts")"
done
say '  the round-16 member rows on the unrepaired kernel (each failing row is a member CUR seals or names otherwise):'
IFS='|' read -r -a mr <<< "$mrows"
for lab in "${mr[@]}"; do say "  | $lab: $(grep -c -F -- "written as $lab was not refused" "$w/fx-rl.asserts") failing assertion(s)"; done
for lab in pre-in-prose br-in-link-text tag-holding-backtick tag-split-by-form-feed lone-carriage-return escaped-backslash-code-span escaped-first-backtick image-split-by-seven-marks image-after-backtick-info-fence; do
  check "FX report_record_line_cases fails on the member row $lab" 1 "$(grep -c -F -- "written as $lab was not refused" "$w/fx-rl.asserts" | awk '{print ($1 > 0)}')"
done
rc="$(judge "$FX" test-spec-gate.sh round_record_line_cases)"; check 'FX round_record_line_cases fails' 1 "$rc"
first="$(grep -E '^ *assert: ' "$w/fx-round_record_line_cases.out" | grep -v -E 'expected exit' | sed -n 1p)"
check 'FX round_record_line_cases: its first failing assertion is a new row (raw HTML in prose, end to end)' yes \
  "$([[ "$first" == *'a CLEARED completion over a second manifest tier written as - Note<pre>'* ]] && echo yes)"
say "  | first: $(printf '%s' "$first" | LC_ALL=C cut -c1-160)"
for f in "$w"/fx-*.out "$w"/dx-*.out; do cp "$f" "$WT/$r/r17-fixtures-judge-$(basename "$f")"; done
live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r17-fixtures-judge failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
