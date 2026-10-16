#!/usr/bin/env bash
# O-018 and O-019 reproduction BEFORE any repair, 2026-10-01 (session 12). Read-only against the
# live worktree: every case runs in standalone copies built from the live enumeration, under the
# scratch directory, with a TMPDIR ending in `/` inside it. CUR is this tree. PRE is CUR with
# t030o43-final.diff reversed, without its tasks.md hunks (tasks.md has moved since, and no case
# reads it). The live status outside notes/verification/ is compared before and after.
# Cases: every spelling round 13 reported, plus siblings derived from the three mechanisms the
# report names (a heading consumes the line before the field classifier runs; the prefix skip
# stops at an HTML tag's name; quoting hides the line) and the two the canonical pass has (only
# `### Finding ` opens a finding; the duplicate-field key is the line's spelling, indentation
# included). Each runs through vf_reports directly on CUR and PRE, and the reported members also
# end to end through spec-gate.sh round --complete and tally on CUR, under LANG=C and
# LANG=en_US.UTF-8 with every LC_* removed.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
X="$SP/o018-repro"; C="$X/cur"; P="$X/pre"; w="$X/work"
rm -rf "$X"; mkdir -p "$C" "$P" "$w" "$X/tmp"
export TMPDIR="$X/tmp/"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
has() { if grep -q -F -- "$2" "$3"; then say "PASS $1"; else say "FAIL $1 (missing: $2)"; sed 's/^/  | /' "$3" | head -5; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
say "host: $(uname -sr); bash on PATH: $(bash --version | head -1); TMPDIR=$TMPDIR"

( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$C" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$C" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
for d in scripts templates tests; do cp -R "$C/$d" "$P/$d"; done
awk '/^--- a\/\.specify\//{exit} {print}' "$WT/$r/t030o43-final.diff" > "$X/kit.diff"
check 'PRE: the kit part of t030o43-final.diff names 12 files' 12 "$(grep -c '^+++ b/' "$X/kit.diff")"
( cd "$P" && patch -R -p1 -s < "$X/kit.diff" ); check 'PRE: t030o43-final.diff reverses cleanly' 0 "$?"
check 'PRE: no reject or backup files' 0 "$(find "$P" -name '*.rej' -o -name '*.orig' | wc -l | tr -d ' ')"
check 'PRE: the kernel has no shared whitespace step' 0 "$(grep -c '_VF_AWK_WS' "$P/scripts/verification-lib.sh")"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
NB=$'\302\240'; TAB=$'\t'; EMD=$'\342\200\224'; FENCE='```'

# A canonical finding block. $4 is the whole Severity part (one or more lines, no trailing newline).
finding() { # heading class status severity-lines
  printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%s\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read or refuse every record line\n' "$1" "$2" "$3" "$4"
}
round() { # n verdict blocking minor findings [timestamp source floor]
  printf '## Round %s\n**Round:** %s\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nFinding records read by both readers.\n%s### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:%s -->\n' \
    "$1" "$1" "${6:-2026-09-06T12:00:0${1}Z}" "${7:-$SRC}" "${8:-FLOOR-fixture}" "$2" "$3" "$4" "$5" "$1"
}
mani() { mkdir -p "$1/notes/verification/reports"; printf '# Prior review\n\n%s' "$2" > "$1/notes/verification/reports/opponent-findings-review.md"; }
vfr() { # tag kit locale report spec -> prints rc; stderr in $w/<tag>.err, catalog in $w/<tag>.nul
  inloc "$3" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$2" "$4" "$w/$1.nul" "$5" < /dev/null > "$w/$1.out" 2> "$w/$1.err"
  echo $? > "$w/$1.rc"; cat "$w/$1.rc"
}
catalog() { tr '\0' '\n' < "$w/$1.nul" | paste -d'|' - - - - - - - - - - - -; }
first() { head -1 "$w/$1.err" | LC_ALL=C cut -c1-160; }
G42='### Finding G-042\n- **Class:** tier-binding\n'

say '== M: manifest member. A CLEARED round 1 re-records G-042 open at minor, totals 0 . 1; the manifest holds G-042 at data-loss in some spelling'
# tag|manifest body (printf %b), every one after "# Prior review" and a blank line
cat > "$X/m.cases" <<EOF
control|${G42}- **Severity:** data-loss\n
m1-h4-colon|${G42}\n#### Severity: data-loss\n
m2-h4-body|${G42}\n#### Severity\n\ndata-loss\n
m3-h4-bold|${G42}\n#### **Severity:** data-loss\n
m4-h4-dash|${G42}\n#### Severity ${EMD} data-loss\n
m5-h3-under-h2|## Finding G-042\n- **Class:** tier-binding\n\n### Severity: data-loss\n
m5b-h3-body-under-h2|## Finding G-042\n- **Class:** tier-binding\n\n### Severity\n\ndata-loss\n
m6-html-b|${G42}- <b>Severity:</b> data-loss\n
m7-html-strong|${G42}- <strong>Severity:</strong> data-loss\n
m8-html-h4|${G42}<h4>Severity: data-loss</h4>\n
d1-h5|${G42}\n##### Severity: data-loss\n
d2-h6-closed|${G42}\n###### Severity: data-loss ######\n
d3-html-em|${G42}- <em>Severity:</em> data-loss\n
d4-html-span|${G42}- <span class="tier">Severity: data-loss</span>\n
d5-blockquote|${G42}> - **Severity:** data-loss\n
d6-fenced|${G42}${FENCE}text\n- **Severity:** data-loss\n${FENCE}\n
d7-comment|${G42}<!-- - **Severity:** data-loss -->\n
d8-absent|${G42}
EOF
while IFS='|' read -r tag body; do
  for kit in cur pre; do
    k="$C"; [[ "$kit" == pre ]] && k="$P"
    sp="$X/spec-M-$tag-$kit"; mkdir -p "$sp/notes"
    mani "$sp" "$(printf '%b' "$body")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      t="M-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      if [[ "$tag" == control ]]; then
        check "M $tag $kit $l: refused (rc 3)" 3 "$rc"
        has "M $tag $kit $l: the lowered-tier refusal" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' "$w/$t.err"
      elif [[ "$kit" == cur ]]; then
        check "M $tag cur $l: sealed in silence (rc 0)" 0 "$rc"
        check "M $tag cur $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')"
      elif [[ "$tag" == m* ]]; then
        check "M $tag pre $l: sealed in silence too, so it predates T030o43 (rc 0)" 0 "$rc"
      else
        say "  | M $tag pre $l: rc=$rc $(first "$t")"
      fi
    done
  done
done < "$X/m.cases"
say '  setext form, which the report says CUR now refuses and PRE did not:'
for kit in cur pre; do
  k="$C"; [[ "$kit" == pre ]] && k="$P"; sp="$X/spec-M-setext-$kit"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "${G42}\nSeverity: data-loss\n---\n")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  rc="$(vfr "M-setext-$kit" "$k" C "$sp/notes/opponent.md" "$sp")"; say "  | M setext $kit C: rc=$rc $(first "M-setext-$kit")"
done
check 'M setext cur: refused (rc 3)' 3 "$(cat "$w/M-setext-cur.rc")"
has 'M setext cur: by name' 'a Severity line this grammar cannot read' "$w/M-setext-cur.err"

say '== S: O-019. A sub-heading inside a manifest finding, above its canonical field lines'
cat > "$X/s.cases" <<EOF
s1-notes|${G42}#### Notes\nReproduced twice.\n- **Severity:** data-loss\n
s2-details|### Finding G-042\n#### Details\n- **Class:** tier-binding\n- **Severity:** data-loss\n
EOF
while IFS='|' read -r tag body; do
  for kit in cur pre; do
    k="$C"; [[ "$kit" == pre ]] && k="$P"; sp="$X/spec-S-$tag-$kit"; mkdir -p "$sp/notes"
    mani "$sp" "$(printf '%b' "$body")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      t="S-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      check "S $tag $kit $l: refused (rc 3)" 3 "$rc"
      if [[ "$kit" == pre ]]; then has "S $tag pre $l: on the lowered tier, so PRE read the fields" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' "$w/$t.err"
      elif [[ "$tag" == s1-notes ]]; then has "S $tag cur $l: the Severity line refused as outside any Finding" 'a severity line outside any Finding: - **Severity:** data-loss' "$w/$t.err"
      else
        has "S $tag cur $l: the finding refused as Class-less at the sub-heading" 'finding G-042 has no readable Class: #### Details' "$w/$t.err"
        has "S $tag cur $l: the Class line refused as outside any Finding" 'a class line outside any Finding: - **Class:** tier-binding' "$w/$t.err"
      fi
    done
  done
done < "$X/s.cases"

say '== C: canonical-report member. Round 1 CHALLENGED with G-042 open at data-loss; round 2 CLEARED, totals 0 . 0, re-lists G-042 open at minor under a heading'
r1="$(round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n')"
cat > "$X/c.cases" <<EOF
c1-h4|#### Finding G-042
c2-tab|### Finding${TAB}G-042
c3-two-spaces|###  Finding G-042
c4-nbsp|### Finding${NB}G-042
c5-lowercase|### finding G-042
d1-h2|## Finding G-042
d2-h5|##### Finding G-042
d3-leading-space| ### Finding G-042
d4-tab-after-hashes|###${TAB}Finding G-042
d5-uppercase|### FINDING G-042
d6-colon|### Finding: G-042
d7-bold-line|**Finding G-042**
EOF
for kit in cur pre; do
  k="$C"; [[ "$kit" == pre ]] && k="$P"; sp="$X/spec-C-control-$kit"; mkdir -p "$sp/notes"
  { printf '%s\n\n' "$r1"; round 2 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n'; } > "$sp/notes/opponent.md"
  for l in C en_US.UTF-8; do
    t="C-control-$kit-$l"; check "C control $kit $l: the canonical heading at minor, totals 0 . 1, refused (rc 3)" 3 "$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
    has "C control $kit $l: the lowered-tier refusal" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' "$w/$t.err"
  done
done
while IFS='|' read -r tag heading; do
  for kit in cur pre; do
    k="$C"; [[ "$kit" == pre ]] && k="$P"; sp="$X/spec-C-$tag-$kit"; mkdir -p "$sp/notes"
    { printf '%s\n\n' "$r1"; round 2 CLEARED 0 0 "$(finding "$heading" tier-binding open '- **Severity:** minor')"$'\n'; } > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      t="C-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      if [[ "$kit" == cur ]]; then
        check "C $tag cur $l: sealed in silence (rc 0)" 0 "$rc"
        check "C $tag cur $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')"
        check "C $tag cur $l: round 2 records no finding" 0 "$(catalog "$t" | grep -c '^finding|2|')"
      elif [[ "$tag" == c* ]]; then
        check "C $tag pre $l: sealed in silence too (rc 0)" 0 "$rc"
      else
        say "  | C $tag pre $l: rc=$rc $(first "$t")"
      fi
    done
  done
done < "$X/c.cases"

say '== U: the canonical duplicate key. A CLEARED round 1, totals 0 . 1, with a new finding G-050 carrying two Severity lines'
cat > "$X/u.cases" <<EOF
control|- **Severity:** data-loss\n- **Severity:** minor
u1-indented-second|- **Severity:** data-loss\n  - **Severity:** minor
d1-indented-first|  - **Severity:** data-loss\n- **Severity:** minor
d2-unread-first|- **Severity**: data-loss\n- **Severity:** minor
EOF
while IFS='|' read -r tag sevs; do
  for kit in cur pre; do
    k="$C"; [[ "$kit" == pre ]] && k="$P"; sp="$X/spec-U-$tag-$kit"; mkdir -p "$sp/notes"
    round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "$sevs")")"$'\n' > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      t="U-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      if [[ "$tag" == control ]]; then
        check "U control $kit $l: refused (rc 3)" 3 "$rc"; has "U control $kit $l: by name" 'duplicate finding field' "$w/$t.err"
      elif [[ "$kit" == cur ]]; then
        check "U $tag cur $l: sealed (rc 0)" 0 "$rc"
        check "U $tag cur $l: G-050 recorded at minor" 1 "$(catalog "$t" | grep -c '^finding|1|G-050|dup-binding|new|none|minor|')"
      elif [[ "$tag" == u* ]]; then
        check "U $tag pre $l: sealed too (rc 0)" 0 "$rc"
      else
        say "  | U $tag pre $l: rc=$rc $(first "$t")"
      fi
    done
  done
done < "$X/u.cases"

say '== E: end to end through spec-gate.sh on CUR; fixture, floor and reservation built under C each time'
awk '$0 != "t_run_all"' "$C/tests/test-spec-gate.sh" > "$C/tests/.o018-spec-gate.sh"
build() { # sandbox -> writes spec, cli and the reservation line to <sandbox>/paths, reserve.log
  ( cd "$C" && SANDBOX="$1" bash -c '
      . tests/.o018-spec-gate.sh || exit 9
      spec="$(make_verification_git_dir o018)" || exit 9
      cli="$(floor_fixture "$spec")" || exit 9
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { cat "$SANDBOX/.fixture-build-failed"; exit 9; }
      bash "$cli" floor "$spec" > "$SANDBOX/floor.log" 2>&1 || exit 8
      bash "$cli" round "$spec" opponent > "$SANDBOX/reserve.log" 2>&1 || exit 7
      printf "%s\n%s\n" "$spec" "$cli" > "$SANDBOX/paths"' ) > "$1/build.log" 2>&1
}
field() { sed -n "s/.* $1=\([^ ]*\).*/\1/p" "$2"; }
e2e() { # tag locale kind(manifest|canonical|dup) payload
  local tag="$1" l="$2" kind="$3" payload="$4" sb spec cli
  sb="$X/sb-$tag-$l"; mkdir -p "$sb"; build "$sb"; check "E $tag $l: fixture, floor and round-1 reservation" 0 "$?"
  spec="$(sed -n 1p "$sb/paths")"; cli="$(sed -n 2p "$sb/paths")"
  case "$kind" in
    manifest)
      mani "$spec" "$(printf '%b' "$payload")"$'\n'
      round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' \
        "$(field reserved "$sb/reserve.log")" "$(field source "$sb/reserve.log")" "$(field floor "$sb/reserve.log")" > "$sb/returned.md";;
    canonical)
      round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n' \
        "$(field reserved "$sb/reserve.log")" "$(field source "$sb/reserve.log")" "$(field floor "$sb/reserve.log")" > "$sb/r1.md"
      inloc "$l" bash "$cli" round "$spec" opponent --complete "$sb/r1.md" > "$sb/complete1.log" 2>&1
      check "E $tag $l: round 1 CHALLENGED completes (rc 0)" 0 "$?"
      ( cd "$C" && bash "$cli" round "$spec" opponent ) > "$sb/reserve2.log" 2>&1; check "E $tag $l: round 2 reserved" 0 "$?"
      round 2 CLEARED "${payload%%|*}" "$(printf '%s' "$payload" | cut -d'|' -f2)" \
        "$(finding "${payload##*|}" tier-binding open '- **Severity:** minor')"$'\n' \
        "$(field reserved "$sb/reserve2.log")" "$(field source "$sb/reserve2.log")" "$(field floor "$sb/reserve2.log")" > "$sb/returned.md";;
    dup)
      round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "$payload")")"$'\n' \
        "$(field reserved "$sb/reserve.log")" "$(field source "$sb/reserve.log")" "$(field floor "$sb/reserve.log")" > "$sb/returned.md";;
  esac
  inloc "$l" bash "$cli" round "$spec" opponent --complete "$sb/returned.md" > "$w/E-$tag-$l.log" 2>&1; echo $? > "$w/E-$tag-$l.rc"
  inloc "$l" bash "$cli" tally "$spec" > "$w/E-$tag-$l.tally" 2>&1; echo $? > "$w/E-$tag-$l.tally.rc"
  say "  | E $tag $l: complete rc=$(cat "$w/E-$tag-$l.rc") $(head -1 "$w/E-$tag-$l.log" | LC_ALL=C cut -c1-140)"
  say "  |   tally rc=$(cat "$w/E-$tag-$l.tally.rc") $(LC_ALL=C grep -E '^(opponent rounds|blocking|severity-downgrades)=' "$w/E-$tag-$l.tally" | tr '\n' ' ')"
  SEALED="$spec/notes/verification/rounds/opponent"
}
for l in C en_US.UTF-8; do
  e2e m1-h4-colon "$l" manifest "${G42}\n#### Severity: data-loss\n"
  check "E m1-h4-colon $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-m1-h4-colon-$l.rc")"
  has "E m1-h4-colon $l: the completion line" 'round completed gate=opponent round=1 verdict=CLEARED' "$w/E-m1-h4-colon-$l.log"
  check "E m1-h4-colon $l: ROUND-1 sealed" yes "$([[ -f "$SEALED/ROUND-1/report.sha256" ]] && echo yes)"
  has "E m1-h4-colon $l: tally blocking=0 minor=1" 'blocking=0 minor=1' "$w/E-m1-h4-colon-$l.tally"
  has "E m1-h4-colon $l: tally severity-downgrades=0" 'severity-downgrades=0' "$w/E-m1-h4-colon-$l.tally"
  e2e m2-h4-body "$l" manifest "${G42}\n#### Severity\n\ndata-loss\n"
  check "E m2-h4-body $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-m2-h4-body-$l.rc")"
  e2e m-control "$l" manifest "${G42}- **Severity:** data-loss\n"
  check "E m-control $l: refused (rc 3)" 3 "$(cat "$w/E-m-control-$l.rc")"
  has "E m-control $l: the lowered-tier refusal" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' "$w/E-m-control-$l.log"
  for c in "c1-h4|#### Finding G-042" "c2-tab|### Finding${TAB}G-042" "c4-nbsp|### Finding${NB}G-042" "d7-bold-line|**Finding G-042**"; do
    e2e "${c%%|*}" "$l" canonical "0|0|${c#*|}"
    check "E ${c%%|*} $l: round 2 CLEARED sealed (rc 0)" 0 "$(cat "$w/E-${c%%|*}-$l.rc")"
    has "E ${c%%|*} $l: the completion line" 'round completed gate=opponent round=2 verdict=CLEARED' "$w/E-${c%%|*}-$l.log"
    has "E ${c%%|*} $l: tally counts round 1 only" 'blocking=1 minor=0' "$w/E-${c%%|*}-$l.tally"
  done
  e2e c-control "$l" canonical "0|1|### Finding G-042"
  check "E c-control $l: round 2 refused (rc 3)" 3 "$(cat "$w/E-c-control-$l.rc")"
  has "E c-control $l: the lowered-tier refusal" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' "$w/E-c-control-$l.log"
  e2e u1-indented-second "$l" dup '- **Severity:** data-loss\n  - **Severity:** minor'
  check "E u1-indented-second $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-u1-indented-second-$l.rc")"
  has "E u1-indented-second $l: tally blocking=0 minor=1" 'blocking=0 minor=1' "$w/E-u1-indented-second-$l.tally"
done

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "o018-repro failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
