#!/usr/bin/env bash
# The fixtures for round 17's O-018, O-024 and O-023 and its minor (T030o51, T030o52, T030o53) judged in standalone
# copies BEFORE they are applied live, 2026-10-09 (session 19), in both directions: FX is CUR (the four files as
# r18-edits/pre-apply) with the fixture pairs r18-edits/tgc-1.pairs and tsg-1.pairs applied (the kernel unrepaired),
# and DX is FX with the candidate kernel-1.pairs and vc-1.pairs applied too. Each changed fixture function runs alone,
# as t_run_all runs a test (a fresh SANDBOX, the build-failure record checked), with a TMPDIR ending in `/`. On DX
# every changed function must pass. On FX: report_manifest_locale_cases must fail only on the plausible manifest whose
# heading carries a tag and closes the finding (the minor's one relaxation: the unrepaired kernel refuses it under the
# finding it closes), every other new positive passing; report_record_line_cases must fail only on the round-17 member
# and sibling rows, the stated consequences, the O-024 tails, the minor's rows and the 400-line timing row, every new
# positive passing; the end-to-end round_record_line_cases, whose first new row the unrepaired kernel seals (so every
# later completion fails for that reason), must fail first at its first new row. Read-only against the live
# worktree, whose status outside notes/verification/ is compared before and after. Pattern: r17-fixtures-judge.sh.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"; e="$WT/$r/r18-edits"
X="$SP/r18-fixtures"; FX="$X/fx"; DX="$X/dx"; w="$X/work"
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
check 'FX: the four files hash as r18-edits/pre-apply' 4 "$(cd "$FX" && shasum -a 256 -c "$e/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"
perl "$e/lit.pl" "$FX/tests/test-gate-contracts.sh" "$e/tgc-1.pairs" > "$w/apply.log" 2>&1
perl "$e/lit.pl" "$FX/tests/test-spec-gate.sh" "$e/tsg-1.pairs" >> "$w/apply.log" 2>&1
check 'FX: tgc-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 6 block(s) to .*test-gate-contracts.sh$' "$w/apply.log")"
check 'FX: tsg-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 6 block(s) to .*test-spec-gate.sh$' "$w/apply.log")"
cp -R "$FX" "$DX"
perl "$e/lit.pl" "$DX/scripts/verification-lib.sh" "$e/kernel-1.pairs" >> "$w/apply.log" 2>&1
perl "$e/lit.pl" "$DX/templates/verification-contract.md" "$e/vc-1.pairs" >> "$w/apply.log" 2>&1
check 'DX: kernel-1.pairs applied' 1 "$(grep -c '^applied 13 block(s) to .*dx/scripts/verification-lib.sh$' "$w/apply.log")"
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
moved='a plausible manifest \(heading-with-tag-closes-finding\) was refused'
check 'FX report_manifest_locale_cases: no failing assertion outside the relaxed row and its exit check' 0 \
  "$(grep -v -E "$moved|^ *assert: expected exit 0, got 3: bash -c" "$w/fx-ml.asserts" | wc -l | tr -d ' ')"
grep -v -E "$moved|^ *assert: expected exit 0, got 3: bash -c" "$w/fx-ml.asserts" | LC_ALL=C cut -c1-200 | sed 's/^/  | unexpected: /' | head -10
check 'FX report_manifest_locale_cases: the relaxed row fails' 1 "$(grep -c -E "$moved" "$w/fx-ml.asserts" | tr -d ' ')"
rc="$(judge "$FX" test-gate-contracts.sh report_record_line_cases)"; check 'FX report_record_line_cases fails' 1 "$rc"
grep -E '^ *assert: ' "$w/fx-report_record_line_cases.out" > "$w/fx-rl.asserts"
say "  | FX report_record_line_cases: $(wc -l < "$w/fx-rl.asserts" | tr -d ' ') failing assertions"
mrows='autolink-digit-br|autolink-digit-pre|autolink-underscore-p|autolink-backtick-start|autolink-plus|destination-holding-backtick|title-holding-backtick|angle-destination-holding-backtick|label-holding-backtick|title-across-lines|destination-on-next-line|label-across-lines|fence-after-list-marker|fence-swapping-phase|fence-four-spaces-in-item|fence-after-ordered-marker|definition-hiding-severity|definition-then-fence|definition-in-list-item|definition-label-across-lines|definition-escaped-label|lt-equals-prose|indented-fence-in-item|definition-line|heading-tag-on-first-finding|heading-tag-on-later-finding'
trows='fence-after-list-marker|fence-swapping-phase|fence-four-spaces-in-item|fence-after-ordered-marker|definition-hiding-severity|definition-then-fence|definition-in-list-item|definition-label-across-lines|definition-escaped-label'
minor='the first Finding heading of a round carried raw HTML|a later Finding heading carrying raw HTML was (not refused under the finding it opens|refused under the finding it closes)|a section heading that closes a finding was refused as raw HTML inside it|a 400-line run under a bracket quoted in a code span took'
allowed="written as ($mrows) was not refused|whose tail is ($trows) was not refused|$minor|^ *assert: expected exit (3, got 0|0, got 3): record_line_vf"
check 'FX report_record_line_cases: no failing assertion outside the new rows and their exit checks' 0 \
  "$(grep -v -E "$allowed" "$w/fx-rl.asserts" | wc -l | tr -d ' ')"
grep -v -E "$allowed" "$w/fx-rl.asserts" | LC_ALL=C cut -c1-200 | sed 's/^/  | unexpected: /' | head -10
IFS='|' read -r -a mr <<< "$mrows"
for lab in "${mr[@]}"; do check "FX report_record_line_cases fails on the row $lab (manifest or canonical, both locales)" 1 "$(grep -c -E -- "written as $lab was not refused" "$w/fx-rl.asserts" | awk '{print ($1 >= 2)}')"; done
IFS='|' read -r -a tr_ <<< "$trows"
for lab in "${tr_[@]}"; do check "FX report_record_line_cases fails on the tail $lab under both locales" 2 "$(grep -c -F -- "whose tail is $lab was not refused" "$w/fx-rl.asserts")"; done
for lab in 'the first Finding heading of a round carried raw HTML' 'not refused under the finding it opens' 'refused under the finding it closes' 'a section heading that closes a finding was refused as raw HTML inside it'; do
  check "FX report_record_line_cases fails on the minor: $lab, under both locales" 2 "$(grep -c -F -- "$lab" "$w/fx-rl.asserts")"
done
check 'FX report_record_line_cases fails on the 400-line timing row' 1 "$(grep -c -F 'a 400-line run under a bracket quoted in a code span took' "$w/fx-rl.asserts")"
say "  | the timing row on FX: $(grep -F 'a 400-line run under a bracket quoted in a code span took' "$w/fx-rl.asserts" | LC_ALL=C cut -c1-160)"
rc="$(judge "$FX" test-spec-gate.sh round_record_line_cases)"; check 'FX round_record_line_cases fails' 1 "$rc"
first="$(awk '/^ *assert: / && !/expected exit/ {print; getline; print; exit}' "$w/fx-round_record_line_cases.out")"
check 'FX round_record_line_cases: its first failing assertion is its first new row (an autolink, end to end)' yes \
  "$([[ "$first" == *'a CLEARED completion over a second manifest tier written as'* && "$first" == *'Note <1`@a.b><br>Severity: data-loss, tick: `. was not refused under LANG=C'* ]] && echo yes)"
say "  | first: $(printf '%s' "$first" | tr '\n' ' ' | LC_ALL=C cut -c1-200)"
for f in "$w"/fx-*.out "$w"/dx-*.out; do cp "$f" "$WT/$r/r18-fixtures-judge-$(basename "$f")"; done
live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r18-fixtures-judge failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
