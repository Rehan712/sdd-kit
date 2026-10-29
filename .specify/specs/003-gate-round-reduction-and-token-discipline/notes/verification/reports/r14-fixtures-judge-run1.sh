#!/usr/bin/env bash
# The round-14 fixtures judged in standalone copies BEFORE they are applied live, 2026-10-02 (session 14), in
# both directions: FX is CUR with the fixture pairs r14-edits/tgc-1.pairs and tsg-1.pairs applied (the kernel
# unrepaired), and DX is FX with the candidate kernel-1.pairs and vc-1.pairs applied too. Each changed fixture
# function runs alone, as t_run_all runs a test (a fresh SANDBOX, the build-failure record checked), with a
# TMPDIR ending in `/`. On DX every function must pass; on FX each must fail on exactly the rows the repair
# exists for (the defects reproduced by r14-repro.sh) and on nothing else. Read-only against the live worktree,
# whose status outside notes/verification/ is compared before and after.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"; e="$WT/$r/r14-edits"
X="$SP/r14-fixtures"; FX="$X/fx"; DX="$X/dx"; w="$X/work"
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
check 'FX: the four files hash as recorded before this repair' 4 "$(cd "$FX" && shasum -a 256 -c "$e/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"
perl "$e/lit.pl" "$FX/tests/test-gate-contracts.sh" "$e/tgc-1.pairs" > "$w/apply.log" 2>&1
perl "$e/lit.pl" "$FX/tests/test-spec-gate.sh" "$e/tsg-1.pairs" >> "$w/apply.log" 2>&1
check 'FX: tgc-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 7 block(s) to .*test-gate-contracts.sh$' "$w/apply.log")"
check 'FX: tsg-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 5 block(s) to .*test-spec-gate.sh$' "$w/apply.log")"
cp -R "$FX" "$DX"
perl "$e/lit.pl" "$DX/scripts/verification-lib.sh" "$e/kernel-1.pairs" >> "$w/apply.log" 2>&1
perl "$e/lit.pl" "$DX/templates/verification-contract.md" "$e/vc-1.pairs" >> "$w/apply.log" 2>&1
check 'DX: kernel-1.pairs applied' 1 "$(grep -c '^applied 14 block(s) to .*dx/scripts/verification-lib.sh$' "$w/apply.log")"
check 'DX: vc-1.pairs applied' 1 "$(grep -c '^applied 3 block(s) to .*dx/templates/verification-contract.md$' "$w/apply.log")"
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
CASES='test-gate-contracts.sh:report_manifest_locale_cases test-gate-contracts.sh:report_record_line_cases test-gate-contracts.sh:report_round_style_cases test-spec-gate.sh:round_record_line_cases'
say '== DX: every changed fixture function passes on the repaired kernel'
for c in $CASES; do
  rc="$(judge "$DX" "${c%%:*}" "${c#*:}")"; check "DX ${c#*:} passes" 0 "$rc"
  [[ "$rc" == 0 ]] || grep -E '^ *assert: ' "$w/dx-${c#*:}.out" | LC_ALL=C cut -c1-200 | sed 's/^/  | /' | head -20
done
say '== FX: on the unrepaired kernel each fails, on the rows the repair exists for and on no other'
for c in $CASES; do
  rc="$(judge "$FX" "${c%%:*}" "${c#*:}")"; check "FX ${c#*:} fails" 1 "$rc"
  grep -E '^ *assert: ' "$w/fx-${c#*:}.out" > "$w/fx-${c#*:}.asserts"
  say "  | FX ${c#*:}: $(wc -l < "$w/fx-${c#*:}.asserts" | tr -d ' ') failing assertions"
done
# Every failing assertion of the three direct functions on FX must be a new row's: its label names a round-14
# member, an O-021 positive or the O-020 switch, or it is the exit check that accompanies such a label. The
# end-to-end function cascades once the unrepaired kernel seals a round it should refuse, so for it the first
# failing assertion must be the first new row it reaches.
want='O-020|O-021|^ *assert: expected exit [0-9]+, got [0-9]+: (record_line_vf|bash)|written as (nested-|escaped-|wrapped-|split-|empty-link-|link-title-|image-alt-|pi-|cdata-|div-block-|intraword-|zero-width|soft-hyphen|named-|numeric-|comment-across|blockquoted-tag)|plausible manifest \(severity-then-(div|details|closing-tag|four-backtick)'
for c in $CASES; do
  [[ "${c#*:}" != round_record_line_cases ]] || continue
  f="$w/fx-${c#*:}.asserts"
  check "FX ${c#*:}: no failing assertion outside the new rows" 0 "$(grep -v -c -E "$want" "$f" | tr -d ' ')"
  grep -v -E "$want" "$f" | LC_ALL=C cut -c1-200 | sed 's/^/  | unexpected: /' | head -10
done
check 'FX round_record_line_cases: its first failing assertion is the first new row (the linked image, end to end)' yes \
  "$(grep -v -E 'expected exit' "$w/fx-round_record_line_cases.asserts" | head -1 | grep -q -F 'second manifest tier written as - [![badge](y.png)](z)Severity: data-loss' && echo yes)"
say '  the round-14 rows each fail on FX (sampled by label):'
for lbl in 'written as nested-badge was not refused' 'written as split-tag was not refused' 'written as zero-width-space was not refused' \
           'written as comment-across-quoted was not refused' 'a second tier written as wrapped-abbr-title' 'a second tier written as blockquoted-tag-split' \
           'a plausible manifest (severity-then-details) was refused' 'followed by a details-block was refused' 'a title and a late Timestamp let a round with uncounted-blocking seal' \
           'a round its title opens sealed' 'a title after the body of a canonical round was read' 'a reality-check round sealed its legacy-judged body' \
           'whose only body before its late Timestamp is quoted sealed'; do
  check "FX fails on: $lbl" yes "$(cat "$w"/fx-*.asserts | grep -q -F -- "$lbl" && echo yes)"
done
for f in "$w"/fx-*.out "$w"/dx-*.out; do cp "$f" "$WT/$r/r14-fixtures-judge-$(basename "$f")"; done
live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r14-fixtures-judge failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
