#!/usr/bin/env bash
# Round-14 findings reproduced BEFORE any repair, 2026-10-02 (session 14): O-020 (new, blocking), O-018
# reopened (blocking) and O-021 (new, minor), each reported member plus siblings derived from the
# mechanism the report names. Read-only against the live worktree: every case runs in standalone copies
# built from the live enumeration, under the scratch directory, with a TMPDIR ending in `/` inside it.
# CUR is this tree. PRE is CUR with t030o44-final.diff reversed (its four files), so a member that also
# holds on PRE predates T030o44. Each case runs through vf_reports directly on CUR and PRE, and the
# reported mechanisms also end to end through spec-gate.sh round --complete and tally on CUR, under
# LANG=C and LANG=en_US.UTF-8 with every LC_* removed. marked 17.0.5 (not a strict CommonMark renderer,
# the only one on disk, as round 14 used) renders each member for the record; the verdicts never read it.
# The live status outside notes/verification/ is compared before and after.
# O-020 mechanism: a round's style is a running per-line value; the round heading sets canonical, a
#   title line sets legacy while neither Round nor Timestamp is read, a Timestamp line sets canonical.
#   Siblings: a round the title starts (no round heading), a title placed after content, the reality-
#   check gate.
# O-018 mechanism: the label reader reads one line at a time and its link reader stops at the first `]`.
#   Siblings derived from what renders as the first word: a construct opened on one line whose hidden
#   letters continue on the next (a processing instruction, a CDATA section, a condition-6 HTML block),
#   deeper nesting, and emphasis delimiters inside the word, which a renderer removes.
# O-021 mechanism: vf_block_start admits HTML-block conditions 1, 3, 4, 5 only and exactly three
#   backticks; condition 6 and a longer fence also end a paragraph.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
MARKED=/Users/babar/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/marked/lib/marked.esm.js
X="$SP/r14-repro"; C="$X/cur"; P="$X/pre"; w="$X/work"
rm -rf "$X"; mkdir -p "$C" "$P" "$w" "$X/tmp"
export TMPDIR="$X/tmp/"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
has() { if grep -q -F -- "$2" "$3"; then say "PASS $1"; else say "FAIL $1 (missing: $2)"; sed 's/^/  | /' "$3" | head -5; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
say "host: $(uname -sr); bash on PATH: $(bash --version | head -1); TMPDIR=$TMPDIR"
say "start $(date -u +%Y-%m-%dT%H:%M:%SZ)"

( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$C" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$C" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
check 'CUR: the kernel hashes as post-apply-6' bbec96153f4f42a65ffa6c4371babd7d60b0aa04a1e236bfe82b4cc7fe36b597 "$(shasum -a 256 "$C/scripts/verification-lib.sh" | cut -d' ' -f1)"
for d in scripts templates tests; do cp -R "$C/$d" "$P/$d"; done
check 'PRE: t030o44-final.diff names 4 files' 4 "$(grep -c '^+++ b/' "$WT/$r/t030o44-final.diff")"
( cd "$P" && patch -R -p1 -s < "$WT/$r/t030o44-final.diff" ); check 'PRE: t030o44-final.diff reverses cleanly' 0 "$?"
check 'PRE: no reject or backup files' 0 "$(find "$P" -name '*.rej' -o -name '*.orig' | wc -l | tr -d ' ')"
check 'PRE: the kernel hashes as pre-apply' cad3c2c399f5906ef629ba2627506c32fdc1307c40f51b9a382710cd55cf0251 "$(shasum -a 256 "$P/scripts/verification-lib.sh" | cut -d' ' -f1)"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
printf '%s\n' "import { marked } from '$MARKED';" "import { readFileSync } from 'node:fs';" \
  "process.stdout.write(marked.parse(readFileSync(0, 'utf8')));" > "$X/render.mjs"
render() { say "  | marked: $(printf '%b' "$1" | node "$X/render.mjs" 2>&1 | tr '\n' ' ' | LC_ALL=C cut -c1-300)"; }

# A canonical finding block. $4 is the whole Severity part (one or more lines, no trailing newline).
finding() { # heading class status severity-lines
  printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%s\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read or refuse every record line\n' "$1" "$2" "$3" "$4"
}
round() { # n verdict blocking minor findings [timestamp source floor] -- the Timestamp right after the Round line
  printf '## Round %s\n**Round:** %s\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nFinding records read by both readers.\n%s### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:%s -->\n' \
    "$1" "$1" "${6:-2026-09-06T12:00:0${1}Z}" "${7:-$SRC}" "${8:-FLOOR-fixture}" "$2" "$3" "$4" "$5" "$1"
}
# The Timestamp after the Held-up section. Modes: title (the round heading, then the title), notitle (the
# same round without the title: the control), titlefirst (the title alone opens the round), titlelate (the
# title after the What-I-attacked section, so content precedes it).
lround() { # mode n verdict blocking minor findings [timestamp source floor]
  local mode="$1" n="$2" ts="${7:-2026-09-06T12:00:0${2}Z}" src="${8:-$SRC}" fl="${9:-FLOOR-fixture}"
  [[ "$mode" == titlefirst ]] || printf '## Round %s\n' "$n"
  [[ "$mode" != titlelate ]] || printf '### What I attacked\nFinding records read by both readers.\n'
  [[ "$mode" == notitle ]] || printf '# Opponent review — fixture\n'
  printf '**Round:** %s\n**Source:** %s\n**Floor:** %s\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n' "$n" "$src" "$fl" "$3" "$4" "$5"
  [[ "$mode" == titlelate ]] || printf '### What I attacked\nFinding records read by both readers.\n'
  printf '%s### Held up / follow-up tasks\nFixture disposition recorded.\n**Timestamp:** %s\n<!-- gate-round-end: opponent:%s -->\n' "$6" "$ts" "$n"
}
mani() { mkdir -p "$1/notes/verification/reports"; printf '# Prior review\n\n%s' "$2" > "$1/notes/verification/reports/opponent-findings-review.md"; }
vfr() { # tag kit locale report spec [gate] -> prints rc; stderr in $w/<tag>.err, catalog in $w/<tag>.nul
  inloc "$3" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" "$5" "$3" "$4"' _ "$2" "$4" "$w/$1.nul" "$5" "${6:-opponent}" < /dev/null > "$w/$1.out" 2> "$w/$1.err"
  echo $? > "$w/$1.rc"; cat "$w/$1.rc"
}
catalog() { tr '\0' '\n' < "$w/$1.nul" | paste -d'|' - - - - - - - - - - - -; }
first() { head -1 "$w/$1.err" | LC_ALL=C cut -c1-170; }
kitof() { if [[ "$1" == pre ]]; then printf '%s' "$P"; else printf '%s' "$C"; fi; }
G99="$(finding '### Finding G-099' silent-loss new '- **Severity:** data-loss')"$'\n'
G100="$(finding '### Finding G-100' minor-slip new '- **Severity:** minor')"$'\n'

say '== O-020 direct: the title variant against the same round without its title (the control), CUR and PRE'
# tag|mode-pair|diagnostic the control must print|builder. Every builder writes the report for one mode.
o020_report() { # tag mode
  case "$1" in
    a1-counting) lround "$2" 1 CLEARED 0 1 "$G99$G100";;
    a2-resolved-open)
      round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n'; printf '\n'
      lround "$2" 2 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding resolved '- **Severity:** data-loss')"$'\n'"$G100";;
    a3-invented-resolved) lround "$2" 1 CLEARED 0 1 "$(finding '### Finding G-077' tier-binding resolved '- **Severity:** data-loss')"$'\n'"$G100";;
    a4-unknown-severity) lround "$2" 1 CLEARED 0 1 "$(finding '### Finding G-098' tier-binding new '- **Severity:** catastrophic')"$'\n'"$G100";;
    a5-behind-html) lround "$2" 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new $'- **Severity:** minor\n- <b>Severity:</b> data-loss')"$'\n'"$G100";;
    a6-heading-label) lround "$2" 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new $'- **Severity:** minor\n#### Severity: data-loss')"$'\n'"$G100";;
    a7-continued-value) lround "$2" 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new $'- **Severity:** minor\n  data-loss')"$'\n'"$G100";;
    a8-empty-comment) lround "$2" 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new $'- **Severity:** minor\n\n<!-->\n\n- **Severity:** data-loss\n\nThe tier above. -->')"$'\n'"$G100";;
    a9-level-four-heading)
      round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n'; printf '\n'
      lround "$2" 2 CLEARED 0 0 "$(finding '#### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n';;
    s1-title-opens-round) lround "$2" 1 CLEARED 0 1 "$G99$G100";;
    s2-title-after-content) lround "$2" 1 CLEARED 0 1 "$G99$G100";;
  esac
}
while IFS='|' read -r tag mode want; do
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-A-$tag-$kit"; mkdir -p "$sp/notes"
    for variant in "$mode" notitle; do
      o020_report "$tag" "$variant" > "$sp/notes/opponent-$variant.md"
      for l in C en_US.UTF-8; do
        t="A-$tag-$kit-$variant-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent-$variant.md" "$sp")"
        if [[ "$variant" == notitle && "$kit" == cur ]]; then
          check "A $tag cur control (no title) $l: refused (rc 3)" 3 "$rc"; has "A $tag cur control $l: $want" "$want" "$w/$t.err"
        elif [[ "$variant" == notitle ]]; then
          say "  | A $tag pre control $l: rc=$rc $(first "$t")"
        else
          check "A $tag $kit $variant $l: sealed in silence (rc 0)" 0 "$rc"
          check "A $tag $kit $variant $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')"
        fi
      done
    done
  done
done <<'CASES'
a1-counting|title|finding totals disagree
a2-resolved-open|title|clearing verdict rests on resolved findings this gate recorded open: G-042
a3-invented-resolved|title|resolved finding G-077 has no earlier round of this gate and no declared prior-review record
a4-unknown-severity|title|unknown severity
a5-behind-html|title|a Severity line this grammar cannot read in finding G-050
a6-heading-label|title|a Severity line this grammar cannot read in finding G-050
a7-continued-value|title|a Severity field whose list item holds more than its line in finding G-050
a8-empty-comment|title|quoted content carries a Severity line
a9-level-four-heading|title|a Finding heading this grammar cannot read
s1-title-opens-round|titlefirst|finding totals disagree
s2-title-after-content|titlelate|finding totals disagree
CASES
for l in C en_US.UTF-8; do
  has "A a1-counting cur $l: the control also names the verdict" 'verdict disagrees with blocking findings' "$w/A-a1-counting-cur-notitle-$l.err"
  check "A a1-counting cur title $l: the uncounted G-099 is still in the catalog the tally reads" 1 "$(catalog "A-a1-counting-cur-title-$l" | grep -c '^finding|1|G-099|silent-loss|new|none|data-loss|')"
  check "A a9-level-four-heading cur title $l: round 2 records no finding" 0 "$(catalog "A-a9-level-four-heading-cur-title-$l" | grep -c '^finding|2|')"
  has "A a9-level-four-heading cur control $l: the field lines outside any finding" 'a finding field outside any Finding' "$w/A-a9-level-four-heading-cur-notitle-$l.err"
done

say '== O-020 direct, reality-check gate: a gap written in field spelling under a title and a late Timestamp'
rcround() { # title|notitle
  printf '## Round 1\n'; [[ "$1" == notitle ]] || printf '# Reality Check — fixture\n'
  printf '**Round:** 1\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** NEEDS WORK\n\n## Summary\n\nChecked one criterion.\n\n## AC matrix\n\n| AC | Criterion / revision | Evidence | Affected inputs | Verdict |\n|----|----|----|----|----|\n| AC-001 | x | CAP-1 | a | MISSING |\n\n## Constitution check\n\n- PASS\n\n## Gaps (if NEEDS WORK)\n\n1. **AC-001 evidence missing** — the capture is stale.\n   - **Where:** scripts/run.sh:9\n\n## Re-run conditions\n\nRe-invoke when fixed.\n**Timestamp:** 2026-09-06T12:00:01Z\n<!-- gate-round-end: reality-check:1 -->\n' "$SRC"
}
for kit in cur pre; do
  k="$(kitof "$kit")"; sp="$X/spec-RC-$kit"; mkdir -p "$sp/notes"
  for variant in title notitle; do
    rcround "$variant" > "$sp/notes/reality-check-$variant.md"
    for l in C en_US.UTF-8; do
      t="RC-$kit-$variant-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/reality-check-$variant.md" "$sp" reality-check)"
      if [[ "$kit" == cur && "$variant" == notitle ]]; then
        check "RC cur control $l: refused (rc 3)" 3 "$rc"; has "RC cur control $l: by name" 'a finding field outside any Finding' "$w/$t.err"
      elif [[ "$variant" == title ]]; then
        check "RC $kit title $l: sealed in silence (rc 0)" 0 "$rc"; check "RC $kit title $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')"
      else say "  | RC $kit control $l: rc=$rc $(first "$t")"; fi
    done
  done
done

say '== O-018 direct: the manifest holds G-042 at minor and a second line a reader sees as a data-loss tier; a CLEARED round 1 re-records G-042 at minor'
cat > "$X/o018.cases" <<'EOF'
b1-badge|- [![badge](y.png)](z)Severity: data-loss
b2-badge-empty-alt|- [![](y)](z)Severity: data-loss
b3-nested-empty|- [[]](x)Severity: data-loss
b4-alt-escaped-bracket|- ![a\\]b](y)Severity: data-loss
m1-abbr-title-wrapped|- <abbr title="the tier this\nfinding carries">Severity:</abbr> data-loss
m2-tag-split|- <b\ntitle="x">Severity: data-loss</b>
m3-empty-link-across|- [\n](x)Severity: data-loss
m4-title-across|- [](x\n"t")Severity: data-loss
m5-alt-across|- ![ba\ndge](y)Severity: data-loss
d1-intraword-emphasis|- S*everity:* data-loss
d2-intraword-strong|- **Sev**erity: data-loss
d3-pi-across|- <?x\ny?>Severity: data-loss
d4-div-across|\n<div\ntitle="x">Severity: data-loss</div>\n
d5-deeper-nesting|- [[![](y)](z)](w)Severity: data-loss
d6-cdata-across|- <![CDATA[x\ny]]>Severity: data-loss
c1-canonical|- **Severity:** data-loss
c2-plain-image|- ![logo](y)Severity: data-loss
c3-one-line-abbr|- <abbr title="the tier this finding carries">Severity:</abbr> data-loss
c4-one-line-tag|- <b title="x">Severity: data-loss</b>
EOF
while IFS='|' read -r tag line; do
  render "- **Severity:** minor\n$line"
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-M-$tag-$kit"; mkdir -p "$sp/notes"
    mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n$line")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      t="M-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      if [[ "$tag" == c* && "$kit" == cur ]]; then
        check "M $tag cur $l: refused (rc 3)" 3 "$rc"; has "M $tag cur $l: by name" 'a second Severity line in finding G-042' "$w/$t.err"
      elif [[ "$tag" == c* ]]; then say "  | M $tag pre $l: rc=$rc $(first "$t")"
      else
        check "M $tag $kit $l: sealed in silence (rc 0)" 0 "$rc"; check "M $tag $kit $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')"
      fi
    done
  done
done < "$X/o018.cases"

say '== O-018 direct, the canonical pass: a CLEARED round 1 at 0 . 1 whose new G-050 carries the minor line and then the second line'
while IFS='|' read -r tag line; do
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-K-$tag-$kit"; mkdir -p "$sp/notes"
    round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n$line")")"$'\n' > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      t="K-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      if [[ "$tag" == c1-* && "$kit" == cur ]]; then
        check "K $tag cur $l: refused (rc 3)" 3 "$rc"; has "K $tag cur $l: by name" 'duplicate finding field' "$w/$t.err"
      elif [[ "$tag" == c* && "$kit" == cur ]]; then
        check "K $tag cur $l: refused (rc 3)" 3 "$rc"; has "K $tag cur $l: by name" 'a Severity line this grammar cannot read in finding G-050' "$w/$t.err"
      elif [[ "$tag" == c* ]]; then say "  | K $tag pre $l: rc=$rc $(first "$t")"
      else
        check "K $tag $kit $l: sealed in silence (rc 0)" 0 "$rc"; check "K $tag $kit $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')"
        check "K $tag $kit $l: G-050 recorded at minor" 1 "$(catalog "$t" | grep -c '^finding|1|G-050|dup-binding|new|none|minor|')"
      fi
    done
  done
done < "$X/o018.cases"

say '== O-021 direct: a field line followed directly by a block a renderer starts there (both passes); the span twin is a continuation'
cat > "$X/o021.cases" <<'EOF'
o1-div|<div>\nnote\n</div>\n
o2-four-backtick-fence|````text\nplain output\n````\n
o3-details|<details>\nx\n</details>\n
t1-span-twin|<span>\nx\n</span>\n
EOF
while IFS='|' read -r tag block; do
  render "- **Severity:** data-loss\n$block"
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-O-$tag-$kit"; mkdir -p "$sp/notes"
    round 1 CHALLENGED 1 0 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** data-loss\n$block")")"$'\n' > "$sp/notes/opponent.md"
    mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n$block")"$'\n'
    printf '%s\n\n' "$(round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding open '- **Severity:** data-loss')"$'\n')" > "$sp/notes/opponent-m.md"
    rm -f "$sp/notes/verification/reports/opponent-findings-review.md.keep"
    for l in C en_US.UTF-8; do
      # The canonical pass alone: the manifest moves aside while it runs.
      mv "$sp/notes/verification/reports/opponent-findings-review.md" "$sp/notes/verification/reports/opponent-findings-review.md.keep"
      t="O-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      mv "$sp/notes/verification/reports/opponent-findings-review.md.keep" "$sp/notes/verification/reports/opponent-findings-review.md"
      tm="OM-$tag-$kit-$l"; rcm="$(vfr "$tm" "$k" "$l" "$sp/notes/opponent-m.md" "$sp")"
      if [[ "$kit" == cur ]]; then
        check "O $tag cur $l: the canonical pass refuses (rc 3)" 3 "$rc"
        has "O $tag cur $l: by name" 'a Severity field whose list item holds more than its line in finding G-050' "$w/$t.err"
        check "O $tag cur $l: the manifest pass refuses (rc 3)" 3 "$rcm"
        has "O $tag cur $l: by name" 'a Severity field whose list item holds more than its line in finding G-042' "$w/$tm.err"
      else
        check "O $tag pre $l: the canonical pass parses (rc 0)" 0 "$rc"
        say "  | O $tag pre $l: manifest rc=$rcm $(first "$tm")"
      fi
    done
  done
done < "$X/o021.cases"

say '== E: end to end through spec-gate.sh on CUR; fixture, floor and reservation built under C each time'
awk '$0 != "t_run_all"' "$C/tests/test-spec-gate.sh" > "$C/tests/.r14-spec-gate.sh"
build() { # sandbox -> writes spec, cli and the reservation line to <sandbox>/paths, reserve.log
  ( cd "$C" && SANDBOX="$1" bash -c '
      . tests/.r14-spec-gate.sh || exit 9
      spec="$(make_verification_git_dir r14)" || exit 9
      cli="$(floor_fixture "$spec")" || exit 9
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { cat "$SANDBOX/.fixture-build-failed"; exit 9; }
      bash "$cli" floor "$spec" > "$SANDBOX/floor.log" 2>&1 || exit 8
      bash "$cli" round "$spec" opponent > "$SANDBOX/reserve.log" 2>&1 || exit 7
      printf "%s\n%s\n" "$spec" "$cli" > "$SANDBOX/paths"' ) > "$1/build.log" 2>&1
}
field() { sed -n "s/.* $1=\([^ ]*\).*/\1/p" "$2"; }
ID=()
setup() { # tag locale -> SB SPEC CLI and ID=(reserved source floor) of the round-1 reservation
  SB="$X/sb-$1-$2"; mkdir -p "$SB"; build "$SB"; check "E $1 $2: fixture, floor and round-1 reservation" 0 "$?"
  SPEC="$(sed -n 1p "$SB/paths")"; CLI="$(sed -n 2p "$SB/paths")"
  ID=("$(field reserved "$SB/reserve.log")" "$(field source "$SB/reserve.log")" "$(field floor "$SB/reserve.log")")
}
reserve2() { # tag locale: complete a CHALLENGED round 1 carrying G-042 at data-loss, then reserve round 2
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n' "${ID[@]}" > "$SB/r1.md"
  inloc "$2" bash "$CLI" round "$SPEC" opponent --complete "$SB/r1.md" > "$SB/complete1.log" 2>&1
  check "E $1 $2: round 1 CHALLENGED completes (rc 0)" 0 "$?"
  ( cd "$C" && bash "$CLI" round "$SPEC" opponent ) > "$SB/reserve2.log" 2>&1; check "E $1 $2: round 2 reserved" 0 "$?"
  ID=("$(field reserved "$SB/reserve2.log")" "$(field source "$SB/reserve2.log")" "$(field floor "$SB/reserve2.log")")
}
complete() { # tag locale returned-file
  inloc "$2" bash "$CLI" round "$SPEC" opponent --complete "$3" > "$w/E-$1-$2.log" 2>&1; echo $? > "$w/E-$1-$2.rc"
  inloc "$2" bash "$CLI" tally "$SPEC" > "$w/E-$1-$2.tally" 2>&1; echo $? > "$w/E-$1-$2.tally.rc"
  say "  | E $1 $2: complete rc=$(cat "$w/E-$1-$2.rc") $(head -1 "$w/E-$1-$2.log" | LC_ALL=C cut -c1-150)"
  say "  |   tally rc=$(cat "$w/E-$1-$2.tally.rc") $(LC_ALL=C grep -E '^(opponent rounds|blocking|severity-downgrades)=' "$w/E-$1-$2.tally" | tr '\n' ' ')"
}
sealed() { [[ -f "$SPEC/notes/verification/rounds/opponent/ROUND-$1/report.sha256" ]] && echo yes; }
for l in C en_US.UTF-8; do
  # O-020: the uncounted blocking finding, and round 13's canonical member, each with its control.
  setup e1-counting "$l"; lround title 1 CLEARED 0 1 "$G99$G100" "${ID[@]}" > "$SB/returned.md"; complete e1-counting "$l" "$SB/returned.md"
  check "E e1-counting $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-e1-counting-$l.rc")"
  has "E e1-counting $l: the completion line" 'round completed gate=opponent round=1 verdict=CLEARED' "$w/E-e1-counting-$l.log"
  check "E e1-counting $l: ROUND-1 sealed" yes "$(sealed 1)"
  has "E e1-counting $l: the tally counts a blocking finding from the CLEARED round" 'blocking=1 minor=1' "$w/E-e1-counting-$l.tally"
  setup e1-control "$l"; lround notitle 1 CLEARED 0 1 "$G99$G100" "${ID[@]}" > "$SB/returned.md"; complete e1-control "$l" "$SB/returned.md"
  check "E e1-control $l: refused (rc 3)" 3 "$(cat "$w/E-e1-control-$l.rc")"
  has "E e1-control $l: by name" 'finding totals disagree' "$w/E-e1-control-$l.log"
  setup e2-member "$l"; reserve2 e2-member "$l"
  lround title 2 CLEARED 0 0 "$(finding '#### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' "${ID[@]}" > "$SB/returned.md"; complete e2-member "$l" "$SB/returned.md"
  check "E e2-member $l: round 2 CLEARED sealed (rc 0)" 0 "$(cat "$w/E-e2-member-$l.rc")"
  has "E e2-member $l: the completion line" 'round completed gate=opponent round=2 verdict=CLEARED' "$w/E-e2-member-$l.log"
  has "E e2-member $l: two rounds" 'opponent rounds=2' "$w/E-e2-member-$l.tally"
  has "E e2-member $l: round 2 recorded nothing" 'blocking=1 minor=0' "$w/E-e2-member-$l.tally"
  setup e2-control "$l"; reserve2 e2-control "$l"
  lround notitle 2 CLEARED 0 0 "$(finding '#### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' "${ID[@]}" > "$SB/returned.md"; complete e2-control "$l" "$SB/returned.md"
  check "E e2-control $l: refused (rc 3)" 3 "$(cat "$w/E-e2-control-$l.rc")"
  has "E e2-control $l: by name" 'a Finding heading this grammar cannot read' "$w/E-e2-control-$l.log"
  setup e3-title-opens "$l"; lround titlefirst 1 CLEARED 0 1 "$G99$G100" "${ID[@]}" > "$SB/returned.md"; complete e3-title-opens "$l" "$SB/returned.md"
  check "E e3-title-opens $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-e3-title-opens-$l.rc")"
  has "E e3-title-opens $l: the tally counts a blocking finding from the CLEARED round" 'blocking=1 minor=1' "$w/E-e3-title-opens-$l.tally"
  # O-018: the badge in the manifest, the wrapped abbr title in the canonical pass, intra-word emphasis.
  setup e4-badge "$l"; mani "$SPEC" "$(printf '%b' '### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n- [![badge](y.png)](z)Severity: data-loss')"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' "${ID[@]}" > "$SB/returned.md"; complete e4-badge "$l" "$SB/returned.md"
  check "E e4-badge $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-e4-badge-$l.rc")"
  has "E e4-badge $l: the tally" 'blocking=0 minor=1' "$w/E-e4-badge-$l.tally"
  setup e4-control "$l"; mani "$SPEC" "$(printf '%b' '### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n- ![logo](y)Severity: data-loss')"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' "${ID[@]}" > "$SB/returned.md"; complete e4-control "$l" "$SB/returned.md"
  check "E e4-control $l: refused (rc 3)" 3 "$(cat "$w/E-e4-control-$l.rc")"
  has "E e4-control $l: by name" 'a second Severity line in finding G-042' "$w/E-e4-control-$l.log"
  for c in 'e5-abbr-wrapped|- <abbr title="the tier this\nfinding carries">Severity:</abbr> data-loss' 'e6-intraword|- S*everity:* data-loss'; do
    setup "${c%%|*}" "$l"
    round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n${c#*|}")")"$'\n' "${ID[@]}" > "$SB/returned.md"; complete "${c%%|*}" "$l" "$SB/returned.md"
    check "E ${c%%|*} $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-${c%%|*}-$l.rc")"
    has "E ${c%%|*} $l: the tally" 'blocking=0 minor=1' "$w/E-${c%%|*}-$l.tally"
  done
  setup e5-control "$l"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new $'- **Severity:** minor\n- <abbr title="the tier this finding carries">Severity:</abbr> data-loss')"$'\n' "${ID[@]}" > "$SB/returned.md"; complete e5-control "$l" "$SB/returned.md"
  check "E e5-control $l: refused (rc 3)" 3 "$(cat "$w/E-e5-control-$l.rc")"
  has "E e5-control $l: by name" 'a Severity line this grammar cannot read in finding G-050' "$w/E-e5-control-$l.log"
done

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r14-repro failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
