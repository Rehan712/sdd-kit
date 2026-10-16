#!/usr/bin/env bash
# The invoker's reproduction of the T030o44 independent review (t030o44-review.md), 2026-10-01 (session 12), BEFORE
# any change. Read-only against the live worktree: CUR (this tree) and PRE (CUR with t030o44-session2.diff and then
# t030o44-session1.diff reversed, proven against t030o44-edits/pre-apply.sha256) are standalone copies of the live
# enumeration under the scratch directory, with a TMPDIR ending in `/`. Direct cases run vf_reports under LANG=C
# and LANG=en_US.UTF-8 with every LC_* removed; F1 and F4 also end to end through spec-gate.sh. F6's mutants run in
# a third copy, each judged by the fixture functions alone and by a legacy round, restored byte-identically. F7 is
# the invoker's own t030o44-o43matrix-shard{0,1} run (M13 to M16 surviving), cited, not re-run.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
X="$SP/t030o44-rv"; C="$X/cur"; P="$X/pre"; M="$X/mut"; w="$X/work"
rm -rf "$X"; mkdir -p "$C" "$P" "$w" "$X/tmp"
export TMPDIR="$X/tmp/"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
has() { if grep -q -F -- "$2" "$3"; then say "PASS $1"; else say "FAIL $1 (missing: $2)"; sed 's/^/  | /' "$3" | head -4; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
say "host: $(uname -sr); bash on PATH: $(bash --version | head -1); TMPDIR=$TMPDIR"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$C" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$C" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
cp -R "$C" "$M"
for d in scripts templates tests; do cp -R "$C/$d" "$P/$d"; done
( cd "$P" && patch -R -p1 -s < "$WT/$r/t030o44-session2.diff" && patch -R -p1 -s < "$WT/$r/t030o44-session1.diff" ); check 'PRE: both session diffs reverse cleanly' 0 "$?"
( cd "$P" && shasum -a 256 -c "$WT/$r/t030o44-edits/pre-apply.sha256" ) > "$w/pre.sha" 2>&1; check 'PRE: hashes as recorded before apply 1' 0 "$?"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
finding() { # heading class status severity-lines [extra after Scenario] (%b on all)
  printf '%b\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%b\n- **Scenario:** a recorded trigger\n%b- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read or refuse every record line\n' "$1" "$2" "$3" "$4" "${5:-}"
}
round() { # n verdict blocking minor findings [timestamp source floor]
  printf '## Round %s\n**Round:** %s\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nFinding records read by both readers.\n%s### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:%s -->\n' \
    "$1" "$1" "${6:-2026-09-06T12:00:0${1}Z}" "${7:-$SRC}" "${8:-FLOOR-fixture}" "$2" "$3" "$4" "$5" "$1"
}
vfr() { # tag kit locale gate report spec -> prints rc; $w/<tag>.{err,nul}
  inloc "$3" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" "$3" "$4" "$5"' _ "$2" "$5" "$4" "$w/$1.nul" "$6" < /dev/null > "$w/$1.out" 2> "$w/$1.err"
  echo $? > "$w/$1.rc"; cat "$w/$1.rc"
}
catrow() { tr '\0' '\n' < "$w/$1.nul" | paste -d'|' - - - - - - - - - - - - | grep "^finding|1|$2|" | cut -d'|' -f7; }
G42='### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n'
manicase() { # tag line(%b) cur-rc pre-rc [cur-diag] [pre-diag]
  local tag="$1" line="$2" sp="$X/spec-$1" k kit l
  mkdir -p "$sp/notes/verification/reports"
  printf '# Prior review\n\n%b%b\n' "$G42" "$line" > "$sp/notes/verification/reports/opponent-findings-review.md"
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  for l in C en_US.UTF-8; do
    check "$tag CUR $l" "$3" "$(vfr "$tag-cur-$l" "$C" "$l" opponent "$sp/notes/opponent.md" "$sp")"
    check "$tag PRE $l" "$4" "$(vfr "$tag-pre-$l" "$P" "$l" opponent "$sp/notes/opponent.md" "$sp")"
    [[ -z "${5:-}" ]] || has "$tag CUR $l says" "$5" "$w/$tag-cur-$l.err"
    [[ -z "${6:-}" ]] || has "$tag PRE $l says" "$6" "$w/$tag-pre-$l.err"
    [[ "$3" != 0 ]] || check "$tag CUR $l: stderr empty" 0 "$(wc -c < "$w/$tag-cur-$l.err" | tr -d ' ')"
  done
}
canocase() { # tag severity-lines(%b) cur-rc pre-rc [cur-diag] -- CLEARED 0 . 1, new G-050
  local tag="$1" sp="$X/spec-$1" l
  mkdir -p "$sp/notes"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$2")"$'\n' > "$sp/notes/opponent.md"
  for l in C en_US.UTF-8; do
    check "$tag CUR $l" "$3" "$(vfr "$tag-cur-$l" "$C" "$l" opponent "$sp/notes/opponent.md" "$sp")"
    check "$tag PRE $l" "$4" "$(vfr "$tag-pre-$l" "$P" "$l" opponent "$sp/notes/opponent.md" "$sp")"
    [[ -z "${5:-}" ]] || has "$tag CUR $l says" "$5" "$w/$tag-cur-$l.err"
    [[ "$3" != 0 ]] || check "$tag CUR $l: G-050 recorded at minor" minor "$(catrow "$tag-cur-$l" G-050)"
  done
}
SECOND='a second Severity line in finding G-042'

say '== F1 (blocking): the HTML strip is not the inline-HTML grammar'
manicase F1-control '- <b>Severity:</b> data-loss' 3 0 "$SECOND"
manicase F1-quoted-gt '- <b title="a>b">Severity:</b> data-loss' 0 0
manicase F1-autolink '- <Severity:data-loss>' 0 3 '' "$SECOND"
manicase F1-not-a-tag '- <Severity: data-loss>' 0 3 '' "$SECOND"
canocase F1c-quoted-gt '- **Severity:** minor\n  - <b title="a>b">Severity:</b> data-loss' 0 0
canocase F1c-autolink '- **Severity:** minor\n  - <Severity:data-loss>' 0 0
canocase F1c-not-a-tag '- **Severity:** minor\n  - <Severity: data-loss>' 0 0
canocase F1c-control '- **Severity:** minor\n  - <b>Severity:</b> data-loss' 3 0 'a Severity line this grammar cannot read in finding G-050'

say '== F4 (blocking): <!--> and <!---> open a comment in the quoting tracker; siblings'
canocase F4-empty-comment '- **Severity:** minor\n\n<!-->\n\n- **Severity:** data-loss\n\nThe tier above is the one we stand by. -->' 0 0
canocase F4-empty-comment-3 '- **Severity:** minor\n\n<!--->\n\n- **Severity:** data-loss\n\nThe tier above is the one we stand by. -->' 0 0
canocase F4-attribute '- **Severity:** minor\n- <b title="<!--">Note</b> the tier below.\n- **Severity:** data-loss\n- That is the tier. -->' 0 0
canocase F4-fence-info '- **Severity:** minor\n```x`y\n  - **Severity:** data-loss\n   ```' 0 0
manicase F4m-empty-comment '\n<!-->\n\n- **Severity:** data-loss\n\nNotes end here. -->' 0 0

say '== F9 (blocking): a named character reference before the label'
manicase F9-nbsp '- &nbsp;Severity: data-loss' 0 0
manicase F9-ensp '- &ensp;**Severity:** data-loss' 0 0
manicase F9-numeric-control '- &#160;Severity: data-loss' 3 0 "$SECOND"
canocase F9c-nbsp '- **Severity:** minor\n  - &nbsp;**Severity:** data-loss' 0 0

say '== F10 (blocking): a value continued on the next line'
canocase F10c '- **Severity:** minor\n  data-loss' 0 0
manicase F10m '  data-loss' 0 0

say '== F11 (blocking): a label after an empty link or image'
manicase F11-empty-link '- [](x)**Severity:** data-loss' 0 0
manicase F11-titled-link '- [](#a "t")Severity: data-loss' 0 0
canocase F11c-empty-link '- **Severity:** minor\n  - [](x)**Severity:** data-loss' 0 0

say '== F2 (minor): the in-finding label rule refuses ordinary prose'
for line in '  class, not one spelling of it.' '  (class) line outside any Finding in both locales.' '  - Severity: unchanged from round 12.' \
            '  - Class, Status and Prior are unchanged.' '  - "Severity" here is the tier the count reads.' '  - Severity/Class binding held.'; do
  sp="$X/spec-F2-$RANDOM"; mkdir -p "$sp/notes"
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss' "$line\n")"$'\n' > "$sp/notes/opponent.md"
  check "F2 CUR refuses: $line" 3 "$(vfr F2c "$C" C opponent "$sp/notes/opponent.md" "$sp")"
  has "F2 CUR names it: $line" 'line this grammar cannot read in finding G-042' "$w/F2c.err"
  check "F2 PRE parses: $line" 0 "$(vfr F2p "$P" C opponent "$sp/notes/opponent.md" "$sp")"
done

say '== F3 (minor): the duplicate-key change reaches legacy rounds'
legacy() { printf '# Opponent review\n\n**Round:** 1\n**Date:** 2026-07-20\n**Verdict:** CHALLENGED\n\n1. **A defect** — *severity:* wrong-result\n   - **Scenario:** x\n%b' "$1"; }
sp="$X/spec-F3"; mkdir -p "$sp/notes"; legacy '   - **Where:** `a.sh:1`\n     - **Where:** `b.sh:2`\n' > "$sp/notes/opponent.md"
check 'F3 CUR refuses the legacy round' 3 "$(vfr F3c "$C" C opponent "$sp/notes/opponent.md" "$sp")"
has 'F3 CUR: duplicate finding field' 'duplicate finding field' "$w/F3c.err"
check 'F3 PRE reads it' 0 "$(vfr F3p "$P" C opponent "$sp/notes/opponent.md" "$sp")"

say '== F5 (minor): the canonical rules reach reality-check reports'
rc_round() { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** NEEDS WORK\n### Summary\nOne gap.\n### AC matrix\n| AC | Status |\n|----|--------|\n| AC-001 | MISSING |\n### Constitution check\nFixture only.\n### Gaps\n%b### Re-run conditions\nFixture only.\n<!-- gate-round-end: reality-check:1 -->\n' "$SRC" "$1"; }
sp="$X/spec-F5a"; mkdir -p "$sp/notes"; rc_round '1. **AC-001 evidence missing** — the capture is stale.\n   - **Where:** scripts/run.sh:9\n   - **Blocks:** AC-001\n' > "$sp/notes/reality-check.md"
check 'F5 CUR refuses gap field bullets' 3 "$(vfr F5ac "$C" C reality-check "$sp/notes/reality-check.md" "$sp")"
has 'F5 CUR: a finding field outside any Finding' 'a finding field outside any Finding' "$w/F5ac.err"
check 'F5 PRE reads them' 0 "$(vfr F5ap "$P" C reality-check "$sp/notes/reality-check.md" "$sp")"
sp="$X/spec-F5b"; mkdir -p "$sp/notes"; rc_round '#### Finding AC-001 unsupported\nThe capture is stale.\n' > "$sp/notes/reality-check.md"
check 'F5 CUR refuses a Finding-like gap heading' 3 "$(vfr F5bc "$C" C reality-check "$sp/notes/reality-check.md" "$sp")"
has 'F5 CUR: a Finding heading this grammar cannot read' 'a Finding heading this grammar cannot read' "$w/F5bc.err"
check 'F5 PRE reads it' 0 "$(vfr F5bp "$P" C reality-check "$sp/notes/reality-check.md" "$sp")"

say '== F1 and F4 end to end through spec-gate.sh on CUR (under C)'
awk '$0 != "t_run_all"' "$C/tests/test-spec-gate.sh" > "$C/tests/.rv-spec-gate.sh"
e2e() { # tag manifest(%b or empty) report-severity-lines(%b) verdict blocking minor -> complete rc and line
  local sb="$X/sb-$1" spec cli res
  mkdir -p "$sb"
  ( cd "$C" && SANDBOX="$sb" bash -c '. tests/.rv-spec-gate.sh || exit 9
      spec="$(make_verification_git_dir rv)" || exit 9; cli="$(floor_fixture "$spec")" || exit 9
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || exit 9
      bash "$cli" floor "$spec" > "$SANDBOX/floor.log" 2>&1 || exit 8
      bash "$cli" round "$spec" opponent > "$SANDBOX/reserve.log" 2>&1 || exit 7
      printf "%s\n%s\n" "$spec" "$cli" > "$SANDBOX/paths"' ) > "$sb/build.log" 2>&1
  check "E $1: fixture, floor, reservation" 0 "$?"
  spec="$(sed -n 1p "$sb/paths")"; cli="$(sed -n 2p "$sb/paths")"; res="$(cat "$sb/reserve.log")"
  if [[ -n "$2" ]]; then mkdir -p "$spec/notes/verification/reports"; printf '# Prior review\n\n%b\n' "$2" > "$spec/notes/verification/reports/opponent-findings-review.md"; fi
  round 1 "$4" "$5" "$6" "$(finding "### Finding ${7:-G-042}" "${8:-tier-binding}" "${9:-open}" "$3")"$'\n' \
    "$(printf '%s' "$res" | sed -n 's/.* reserved=\([^ ]*\).*/\1/p')" "$(printf '%s' "$res" | sed -n 's/.* source=\([^ ]*\).*/\1/p')" \
    "$(printf '%s' "$res" | sed -n 's/.* floor=\([^ ]*\).*/\1/p')" > "$sb/returned.md"
  bash "$cli" round "$spec" opponent --complete "$sb/returned.md" > "$w/E-$1.log" 2>&1; echo $? > "$w/E-$1.rc"
  bash "$cli" tally "$spec" > "$w/E-$1.tally" 2>&1
}
e2e F1 "${G42}- <b title=\"a>b\">Severity:</b> data-loss" '- **Severity:** minor' CLEARED 0 1
check 'E F1: CLEARED completes over the quoted-> tier' 0 "$(cat "$w/E-F1.rc")"; has 'E F1: verdict line' 'verdict=CLEARED' "$w/E-F1.log"
e2e F4 '' '- **Severity:** minor\n\n<!-->\n\n- **Severity:** data-loss\n\nThe tier above is the one we stand by. -->' CLEARED 0 1 G-050 dup-binding new
check 'E F4: CLEARED completes over the hidden tier' 0 "$(cat "$w/E-F4.rc")"; has 'E F4: tally blocking=0 minor=1' 'blocking=0 minor=1' "$w/E-F4.tally"

say '== F6 (minor): the style=="canonical" conjuncts and the comment loop, mutated in a third copy'
EDLIST=(scripts/verification-lib.sh)
mut() { # <old> <new>: literal once in the mutation copy's kernel
  perl -e 'my ($f,$o,$n)=@ARGV; local $/; open my $h,"<",$f or exit 3; my $t=<$h>; close $h; my $c=()=$t=~/\Q$o\E/g; exit 4 if $c!=1; $t=~s/\Q$o\E/$n/; open $h,">",$f or exit 3; print $h $t; close $h' "$M/scripts/verification-lib.sh" "$1" "$2"
}
judgefn() { # <test file> <function> -> rc
  ( cd "$M" && awk '$0 != "t_run_all"' "tests/$1" > "tests/.rv-$1" && bash -c '. "tests/.rv-$1"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || rc=1; rm -rf "$SANDBOX"; exit "$rc"' _ "$1" "$2" ) > /dev/null 2>&1
  echo $?
}
restore() { ( cd "$M" && git checkout -q -- . && rm -f tests/.rv-*.sh ); cmp -s "$M/scripts/verification-lib.sh" "$C/scripts/verification-lib.sh" || { say 'FAIL restore'; fails=$((fails+1)); }; }
sp="$X/spec-F6"; mkdir -p "$sp/notes"
printf '# Opponent review\n\n**Round:** 1\n**Date:** 2026-07-20\n**Verdict:** CHALLENGED\n\n## What I attacked\n- **Scenario:** a recorded trigger\n\n1. **A defect** — *severity:* wrong-result\n   - **Where:** `a.sh:1`\n   - Severity, as above.\n#### Finding G-1\n### Notes\n   - **Blocks:** AC-001\n\302\240### Finding G-2\n' > "$sp/notes/opponent.md"
check 'F6 legacy round: CUR reads it' 0 "$(vfr F6cur "$C" C opponent "$sp/notes/opponent.md" "$sp")"
for row in 'MA|    style=="canonical" && !ended && !fid && |    !ended && !fid && ' \
           'MB|    style=="canonical" && fid && !/^[ ]*- \*\*(|    fid && !/^[ ]*- \*\*(' \
           'MC|    style=="canonical" && !ended && /^ ? ? ?#+|    !ended && /^ ? ? ?#+' \
           'MD|    style=="canonical" && fid && /^ ? ? ?(#|##|###)|    fid && /^ ? ? ?(#|##|###)' \
           'ME|    style=="canonical" && !ended && !/^ ? ? ?#+|    !ended && !/^ ? ? ?#+'; do
  IFS='|' read -r id old new <<< "$row"
  mut "$old" "$new"; check "F6 $id literal applies once" 0 "$?"
  check "F6 $id survives report_record_line_cases" 0 "$(judgefn test-gate-contracts.sh report_record_line_cases)"
  check "F6 $id survives shipped_002_tally_case" 0 "$(judgefn test-gate-contracts.sh shipped_002_tally_case)"
  rc="$(vfr "F6$id" "$M" C opponent "$sp/notes/opponent.md" "$sp")"
  if [[ "$id" == MD ]]; then say "  | F6 MD on the legacy round: rc=$rc (the reviewer: rc 0 with the Blocks field lost)"
  else check "F6 $id changes the legacy round (refused)" 3 "$rc"; fi
  restore
done
mut $'  while ((i = index(s, "<!--")) > 0) {\n    n = index(substr(s, i + 4), "-->")\n    s = n ? substr(s, 1, i - 1) substr(s, i + n + 6) : substr(s, 1, i - 1)\n  }\n' ''
check 'F6 MM4 literal applies once' 0 "$?"
check 'F6 MM4 survives report_record_line_cases' 0 "$(judgefn test-gate-contracts.sh report_record_line_cases)"
restore
manicase F6-mm4-cur '- <!-- a>b --> Severity: data-loss' 3 0 "$SECOND"

say '== F7 (minor): cited from t030o44-o43matrix-shard{0,1}.log'
for id in M13 M14 M15 M16; do
  check "F7 $id survived on the T030o44 tree" 1 "$(cat "$WT/$r"/t030o44-o43matrix-shard*.log | grep -c -E "^FAIL $id KILLED")"
done
say '== F8 (minor, wording): the contract sentence on rendered text'
has 'F8 the contract claims every field line is decided by its rendered label' 'A field line, in a manifest or in a canonical report, is decided' "$C/templates/verification-contract.md"
has 'F8 the canonical pass label-reads Class and Severity only' 'lbl=vf_label($0, "class severity")' "$C/scripts/verification-lib.sh"

check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$(livestate)"
say "t030o44-review-verify failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
