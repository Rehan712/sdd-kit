#!/usr/bin/env bash
# Round-14 repairs: the candidate rules MEASURED before adoption, 2026-10-02 (session 14). Read-only against the
# live worktree: kits built from the live enumeration under the scratch directory, with a TMPDIR ending in `/`
# inside it. CUR is this tree (T030o44 accepted). D is CUR with the candidate pairs r14-edits/kernel-1.pairs
# applied to scripts/verification-lib.sh and r14-edits/vc-1.pairs to templates/verification-contract.md, nothing
# else. The live status outside notes/verification/ is compared before and after. Pattern: t030o44-measure-2.sh.
# The candidate (T030o45, O-020): a round's style is decided before its body; once a round has a body (any
#   non-blank line but its heading, its title and its identity fields), a title that would make a canonical
#   round legacy, or a Timestamp line that would make a legacy round canonical, is refused by name.
# The candidate (T030o46, O-018 with O-021): the rendered reading reduces bracket pairs innermost first to a
#   fixpoint, takes out emphasis inside a word, and a second rendered reading also takes out invisible
#   characters; labels are read by paragraph as well as by line, in both passes, quoted or not; vf_block_start
#   admits HTML-block condition 6 and backtick fences of three or more.
# A: every reproduced member (r14-repro.sh) and the siblings derived since, CUR as reproduced and D refusing by
#    name with its exact diagnostic; the O-021 rows, D parsing what a renderer closes.
# B: what must still parse on D: new positives (prose that wraps, links and images in prose, a titled round
#    whose Timestamp precedes its body, a wrapped Scenario), the thirteen returned round reports read as
#    manifests, the real prior-review manifest, and every case table of t030o44-measure-2.sh (its members
#    stay refused with their diagnostics, its positives parse, its consequences stay refused).
# C: the recorded history, CUR against D under LANG=C and LANG=en_US.UTF-8 with every LC_* removed: tally,
#    analyzer, spec-ac-coverage, every report catalog with its diagnostics and exit, every round's extracted
#    block and every sealed digest of 003, the binding catalogs, the stage maps, the semantic views of every
#    spec file, the waiver checks for rounds 14 and 15, and the snapshot records.
# D: the full suite on D in its own copy, its failing assertions recorded and checked against the predicted set.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
X="$SP/r14-measure"; C="$X/cur"; D="$X/d"; w="$X/work"
rm -rf "$X"; mkdir -p "$C" "$w" "$X/tmp"
export TMPDIR="$X/tmp/"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
has() { if grep -q -F -- "$2" "$3"; then say "PASS $1"; else say "FAIL $1 (missing: $2)"; sed 's/^/  | /' "$3" | head -5; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
say "start $(date -u +%Y-%m-%dT%H:%M:%SZ); host: $(uname -sr); bash on PATH: $(bash --version | head -1); TMPDIR=$TMPDIR"

( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$C" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$C" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
check 'CUR: the four T030o44 files hash as recorded before this repair' 4 "$(cd "$C" && shasum -a 256 -c "$WT/$r/r14-edits/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"
cp -R "$C" "$D"
perl "$WT/$r/r14-edits/lit.pl" "$D/scripts/verification-lib.sh" "$WT/$r/r14-edits/kernel-1.pairs" > "$w/apply.log" 2>&1
perl "$WT/$r/r14-edits/lit.pl" "$D/templates/verification-contract.md" "$WT/$r/r14-edits/vc-1.pairs" >> "$w/apply.log" 2>&1
check 'D: kernel-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 14 block(s) to .*verification-lib.sh$' "$w/apply.log")"
check 'D: vc-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 3 block(s) to .*verification-contract.md$' "$w/apply.log")"
check 'D: the kernel still parses' 0 "$(bash -n "$D/scripts/verification-lib.sh"; echo $?)"
check 'D: only the two candidate files differ from CUR' 'scripts/verification-lib.sh templates/verification-contract.md' "$(cd "$D" && git status --porcelain | sed 's/^ M //' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
finding() { # heading class status severity-lines [extra lines after Scenario]
  printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%s\n- **Scenario:** a recorded trigger\n%s- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read or refuse every record line\n' "$1" "$2" "$3" "$4" "${5:-}"
}
round() { # n verdict blocking minor findings [timestamp source floor] [held-up body]
  printf '## Round %s\n**Round:** %s\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nFinding records read by both readers.\n%s### Held up / follow-up tasks\n%s\n<!-- gate-round-end: opponent:%s -->\n' \
    "$1" "$1" "${6:-2026-09-06T12:00:0${1}Z}" "${7:-$SRC}" "${8:-FLOOR-fixture}" "$2" "$3" "$4" "$5" "${9:-Fixture disposition recorded.}" "$1"
}
lround() { # mode n verdict blocking minor findings [timestamp source floor] (r14-repro.sh's, the Timestamp after the Held-up section)
  local mode="$1" n="$2" ts="${7:-2026-09-06T12:00:0${2}Z}" src="${8:-$SRC}" fl="${9:-FLOOR-fixture}"
  [[ "$mode" == titlefirst ]] || printf '## Round %s\n' "$n"
  [[ "$mode" != titlelate ]] || printf '### What I attacked\nFinding records read by both readers.\n'
  [[ "$mode" == notitle || "$mode" == titleearly ]] || printf '# Opponent review — fixture\n'
  if [[ "$mode" == titleearly ]]; then printf '# Opponent review — fixture\n**Round:** %s\n**Timestamp:** %s\n' "$n" "$ts"; else printf '**Round:** %s\n' "$n"; fi
  printf '**Source:** %s\n**Floor:** %s\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n' "$src" "$fl" "$3" "$4" "$5"
  [[ "$mode" == titlelate ]] || printf '### What I attacked\nFinding records read by both readers.\n'
  printf '%s### Held up / follow-up tasks\nFixture disposition recorded.\n' "$6"
  [[ "$mode" == titleearly ]] || printf '**Timestamp:** %s\n' "$ts"
  printf '<!-- gate-round-end: opponent:%s -->\n' "$n"
}
mani() { mkdir -p "$1/notes/verification/reports"; printf '# Prior review\n\n%s' "$2" > "$1/notes/verification/reports/opponent-findings-review.md"; }
vfr() { # tag kit locale report spec [gate] -> prints rc; stderr in $w/<tag>.err, catalog in $w/<tag>.nul
  inloc "$3" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" "$5" "$3" "$4"' _ "$2" "$4" "$w/$1.nul" "$5" "${6:-opponent}" < /dev/null > "$w/$1.out" 2> "$w/$1.err"
  echo $? > "$w/$1.rc"; cat "$w/$1.rc"
}
both() { # tag spec [gate] [report] -> runs CUR and D under both locales
  local tag="$1" sp="$2" g="${3:-opponent}" rep="${4:-$2/notes/${3:-opponent}.md}" l
  for l in C en_US.UTF-8; do vfr "$tag-cur-$l" "$C" "$l" "$rep" "$sp" "$g" > /dev/null; vfr "$tag-d-$l" "$D" "$l" "$rep" "$sp" "$g" > /dev/null; done
}
judge() { # label tag cur-rc d-rc d-diagnostic [cur-diagnostic]
  local l
  for l in C en_US.UTF-8; do
    check "$1 $l: CUR rc" "$3" "$(cat "$w/$2-cur-$l.rc")"
    check "$1 $l: D rc" "$4" "$(cat "$w/$2-d-$l.rc")"
    [[ -z "${5:-}" ]] || has "$1 $l: D says" "$5" "$w/$2-d-$l.err"
    [[ -z "${6:-}" ]] || has "$1 $l: CUR says" "$6" "$w/$2-cur-$l.err"
    [[ "$4" != 0 ]] || check "$1 $l: D stderr empty" 0 "$(wc -c < "$w/$2-d-$l.err" | tr -d ' ')"
    [[ "$3" != 0 ]] || check "$1 $l: CUR stderr empty" 0 "$(wc -c < "$w/$2-cur-$l.err" | tr -d ' ')"
  done
}
TS='a Timestamp line after the body of a round its title made legacy'
TI='a report title after the body of a canonical round'
G99="$(finding '### Finding G-099' silent-loss new '- **Severity:** data-loss')"$'\n'
G100="$(finding '### Finding G-100' minor-slip new '- **Severity:** minor')"$'\n'

say '== A1: O-020 (T030o45). The title variants seal on CUR and are refused by name on D; the controls without the title are refused on both'
o020_report() { # tag mode
  case "$1" in
    a1-counting|s1-title-opens-round|s2-title-after-content) lround "$2" 1 CLEARED 0 1 "$G99$G100";;
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
  esac
}
while IFS='|' read -r tag mode diag ctl; do
  sp="$X/spec-A-$tag"; mkdir -p "$sp/notes"
  o020_report "$tag" "$mode" > "$sp/notes/opponent-t.md"; o020_report "$tag" notitle > "$sp/notes/opponent-n.md"
  both "A-$tag-t" "$sp" opponent "$sp/notes/opponent-t.md"; judge "A1 $tag ($mode)" "A-$tag-t" 0 3 "$diag"
  both "A-$tag-n" "$sp" opponent "$sp/notes/opponent-n.md"; judge "A1 $tag control" "A-$tag-n" 3 3 "$ctl" "$ctl"
done <<CASES
a1-counting|title|$TS|finding totals disagree
a2-resolved-open|title|$TS|clearing verdict rests on resolved findings this gate recorded open: G-042
a3-invented-resolved|title|$TS|resolved finding G-077 has no earlier round of this gate and no declared prior-review record
a4-unknown-severity|title|$TS|unknown severity
a5-behind-html|title|$TS|a Severity line this grammar cannot read in finding G-050
a6-heading-label|title|$TS|a Severity line this grammar cannot read in finding G-050
a7-continued-value|title|$TS|a Severity field whose list item holds more than its line in finding G-050
a8-empty-comment|title|$TS|quoted content carries a Severity line
a9-level-four-heading|title|$TS|a Finding heading this grammar cannot read
s1-title-opens-round|titlefirst|$TS|finding totals disagree
s2-title-after-content|titlelate|$TI|finding totals disagree
CASES
has 'A1 s2-title-after-content C: D also refuses its late Timestamp' "$TS" "$w/A-s2-title-after-content-t-d-C.err"
rcround() { # title|notitle
  printf '## Round 1\n'; [[ "$1" == notitle ]] || printf '# Reality Check — fixture\n'
  printf '**Round:** 1\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** NEEDS WORK\n\n## Summary\n\nChecked one criterion.\n\n## AC matrix\n\n| AC | Criterion / revision | Evidence | Affected inputs | Verdict |\n|----|----|----|----|----|\n| AC-001 | x | CAP-1 | a | MISSING |\n\n## Constitution check\n\n- PASS\n\n## Gaps (if NEEDS WORK)\n\n1. **AC-001 evidence missing** — the capture is stale.\n   - **Where:** scripts/run.sh:9\n\n## Re-run conditions\n\nRe-invoke when fixed.\n**Timestamp:** 2026-09-06T12:00:01Z\n<!-- gate-round-end: reality-check:1 -->\n' "$SRC"
}
sp="$X/spec-RC"; mkdir -p "$sp/notes"; rcround title > "$sp/notes/rc-t.md"; rcround notitle > "$sp/notes/rc-n.md"
both RC-t "$sp" reality-check "$sp/notes/rc-t.md"; judge 'A1 reality-check title' RC-t 0 3 "$TS"
both RC-n "$sp" reality-check "$sp/notes/rc-n.md"; judge 'A1 reality-check control' RC-n 3 3 'a finding field outside any Finding'

say '== A2: O-018 (T030o46), the manifest pass. The manifest holds G-042 at minor, then LINE; a CLEARED round 1 re-records G-042 at minor'
# tag|LINE (printf %b)|D diagnostic. r14-repro.sh's members (b, m, d), and since: invisible characters inside the
# word (z, the extent sessions 12 and 13 recorded) and a construct spanning quoted lines (q).
cat > "$X/o18.cases" <<'EOF'
b1-badge|- [![badge](y.png)](z)Severity: data-loss|a second Severity line in finding G-042
b2-badge-empty-alt|- [![](y)](z)Severity: data-loss|a second Severity line in finding G-042
b3-nested-empty|- [[]](x)Severity: data-loss|a second Severity line in finding G-042
b4-alt-escaped-bracket|- ![a\\]b](y)Severity: data-loss|a second Severity line in finding G-042
m1-abbr-title-wrapped|- <abbr title="the tier this\nfinding carries">Severity:</abbr> data-loss|a second Severity line in finding G-042
m2-tag-split|- <b\ntitle="x">Severity: data-loss</b>|a second Severity line in finding G-042
m3-empty-link-across|- [\n](x)Severity: data-loss|a second Severity line in finding G-042
m4-title-across|- [](x\n"t")Severity: data-loss|a second Severity line in finding G-042
m5-alt-across|- ![ba\ndge](y)Severity: data-loss|a second Severity line in finding G-042
d1-intraword-emphasis|- S*everity:* data-loss|a second Severity line in finding G-042
d2-intraword-strong|- **Sev**erity: data-loss|a second Severity line in finding G-042
d3-pi-across|- <?x\ny?>Severity: data-loss|a second Severity line in finding G-042
d4-div-across|\n<div\ntitle="x">Severity: data-loss</div>\n|a second Severity line in finding G-042
d5-nested-links|- [[![](y)](z)](w)Severity: data-loss|a second Severity line in finding G-042
d6-cdata-across|- <![CDATA[x\ny]]>Severity: data-loss|a second Severity line in finding G-042
z1-zero-width-space|- Sev\342\200\213erity: data-loss|a second Severity line in finding G-042
z2-soft-hyphen|- Sev\302\255erity: data-loss|a second Severity line in finding G-042
z3-named-soft-hyphen|- Sev&shy;erity: data-loss|a second Severity line in finding G-042
z4-numeric-soft-hyphen|- Sev&#173;erity: data-loss|a second Severity line in finding G-042
z5-named-zero-width|- Se&ZeroWidthSpace;verity: data-loss|a second Severity line in finding G-042
q1-comment-across|- <!-- a\nb --> Severity: data-loss|quoted content carries a Severity line
q2-blockquoted-tag-split|> - <b\n> title="x">Severity: data-loss</b>|quoted content carries a Severity line
EOF
while IFS='|' read -r tag line diag; do
  sp="$X/spec-M-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n$line")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "M-$tag" "$sp"; judge "A2 M $tag" "M-$tag" 0 3 "$diag"
done < "$X/o18.cases"

say '== A3: O-018 (T030o46), the canonical pass. A CLEARED round 1 at 0 . 1 whose new G-050 carries the minor line, then LINE'
while IFS='|' read -r tag line diag; do
  [[ "$diag" == quoted* ]] || diag='a Severity line this grammar cannot read in finding G-050'
  sp="$X/spec-K-$tag"; mkdir -p "$sp/notes"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n$line")")"$'\n' > "$sp/notes/opponent.md"
  both "K-$tag" "$sp"; judge "A3 K $tag" "K-$tag" 0 3 "$diag"
done < "$X/o18.cases"

say '== A4: O-021 (T030o46). A field line followed directly by a block a renderer starts there; the span and backtick-info twins stay refused'
cat > "$X/o21.cases" <<'EOF'
o1-div|<div>\nnote\n</div>\n|3|0
o2-four-backtick-fence|````text\nplain output\n````\n|3|0
o3-details|<details>\nx\n</details>\n|3|0
o4-div-with-attribute|<DIV class="note">\nnote\n</DIV>\n|3|0
o5-closing-tag|</details>\n|3|0
c6-five-tilde-fence|~~~~~\nplain output\n~~~~~\n|0|0
t1-span-twin|<span>\nx\n</span>\n|3|3
t2-backtick-info-twin|```x`y\nnot a fence\n```\n|3|3
EOF
while IFS='|' read -r tag block crc drc; do
  sp="$X/spec-O-$tag"; mkdir -p "$sp/notes"
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** data-loss\n$block")")"$'\n' > "$sp/notes/opponent.md"
  both "O-$tag" "$sp"; judge "A4 canonical $tag" "O-$tag" "$crc" "$drc" "$([[ "$drc" == 3 ]] && echo 'a Severity field whose list item holds more than its line in finding G-050')" "$([[ "$crc" == 3 ]] && echo 'a Severity field whose list item holds more than its line in finding G-050')"
  sm="$X/spec-OM-$tag"; mkdir -p "$sm/notes"
  mani "$sm" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n$block")"$'\n'
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding open '- **Severity:** data-loss')"$'\n' > "$sm/notes/opponent.md"
  both "OM-$tag" "$sm"; judge "A4 manifest $tag" "OM-$tag" "$crc" "$drc" "$([[ "$drc" == 3 ]] && echo 'a Severity field whose list item holds more than its line in finding G-042')" "$([[ "$crc" == 3 ]] && echo 'a Severity field whose list item holds more than its line in finding G-042')"
done < "$X/o21.cases"

say '== B1: new positives that must parse on both kits'
cat > "$X/pos.cases" <<'EOF'
link-prose|- See [the report](x) for the tier.\n
linked-image-prose|- [![badge](y.png)](z) shows the build state.\n
wrapped-prose|- A note that wraps\nonto the next line, then says Severity: as noted.\n
wrapped-link-text|- [a link whose text\nwraps](x) and more.\n
intraword-prose|- The c*a*se of one word.\n
blockquote-prose|\n> A quoted\n> remark about the Severity of it.\n
wrapped-tag-prose|- <abbr title="a long\ntitle">API</abbr> severity is unchanged.\n
image-then-word|- ![logo](y) Classes of defect.\n
EOF
while IFS='|' read -r tag line; do
  sp="$X/spec-PM-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n$line")"$'\n'
  round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding open '- **Severity:** wrong-result')"$'\n' > "$sp/notes/opponent.md"
  both "PM-$tag" "$sp"; judge "B1 manifest $tag parses" "PM-$tag" 0 0
  sp="$X/spec-PK-$tag"; mkdir -p "$sp/notes"
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss' "$(printf '%b' "$line")"$'\n')"$'\n' > "$sp/notes/opponent.md"
  both "PK-$tag" "$sp"; judge "B1 canonical $tag parses" "PK-$tag" 0 0
done < "$X/pos.cases"
sp="$X/spec-PT"; mkdir -p "$sp/notes"
lround titleearly 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n' > "$sp/notes/opponent.md"
both PT "$sp"; judge 'B1 a titled round whose Timestamp precedes its body parses' PT 0 0
check 'B1 the titled round is read canonical on D' 1 "$(tr '\0' '\n' < "$w/PT-d-C.nul" | paste - - - - - - - - - - - - | awk -F '\t' '$1=="round" && $7=="canonical"' | wc -l | tr -d ' ')"
sp="$X/spec-PW"; mkdir -p "$sp/notes"
round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss' $'  that wraps onto a second line, with the Severity it had\n')"$'\n' > "$sp/notes/opponent.md"
both PW "$sp"; judge 'B1 a Scenario continued onto its next line parses' PW 0 0

say '== B2: the case tables of t030o44-measure-2.sh on both kits (members refused with their diagnostics, positives parse)'
tables() { awk -v n="$1" '$0 == "cat > \"$X/" n ".cases\" <<'"'"'EOF'"'"'" {f=1; next} f && $0 == "EOF" {exit} f' "$WT/$r/t030o44-measure-2.sh"; }
tables m > "$X/m2.cases"; tables u > "$X/u2.cases"; tables p > "$X/p2.cases"; tables q > "$X/q2.cases"; tables k > "$X/k2.cases"
check 'B2 the five tables were extracted' '33 17 17 7 2' "$(for t in m2 u2 p2 q2 k2; do wc -l < "$X/$t.cases" | tr -d ' '; done | tr '\n' ' ' | sed 's/ $//')"
base='### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n'
while IFS='|' read -r tag body _ diag; do
  sp="$X/spec-RM-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "${body//@B@/$base}")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  if [[ "$tag" == f10-details-after ]]; then both "RM-$tag" "$sp"; judge "B2 measure-2 manifest member $tag, now parsed by O-021's rule" "RM-$tag" 3 0 '' "$diag"; continue; fi
  both "RM-$tag" "$sp"; judge "B2 measure-2 manifest member $tag" "RM-$tag" 3 3 "$diag" "$diag"
done < "$X/m2.cases"
while IFS='|' read -r tag sevs _ diag; do
  sp="$X/spec-RU-$tag"; mkdir -p "$sp/notes"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "$sevs")")"$'\n' > "$sp/notes/opponent.md"
  both "RU-$tag" "$sp"; judge "B2 measure-2 canonical member $tag" "RU-$tag" 3 3 "$diag" "$diag"
done < "$X/u2.cases"
while IFS='|' read -r tag body; do
  sp="$X/spec-RP-$tag"; mkdir -p "$sp/notes/verification/reports"; printf '%b' "$body" > "$sp/notes/verification/reports/opponent-findings-review.md"
  round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding open '- **Severity:** wrong-result')"$'\n' > "$sp/notes/opponent.md"
  both "RP-$tag" "$sp"; judge "B2 measure-2 manifest positive $tag" "RP-$tag" 0 0
done < "$X/p2.cases"
while IFS='|' read -r tag heading sevs extra; do
  sp="$X/spec-RQ-$tag"; mkdir -p "$sp/notes"
  sv="$(printf '%b' "$sevs")"; [[ "$tag" != severity-then-blank ]] || sv+=$'\n'
  round 1 CHALLENGED 1 0 "$(finding "$heading" tier-binding new "$sv" "$(printf '%b' "$extra")"$'\n')"$'\n' > "$sp/notes/opponent.md"
  both "RQ-$tag" "$sp"; judge "B2 measure-2 canonical positive $tag" "RQ-$tag" 0 0
done < "$X/q2.cases"
while IFS='|' read -r tag body; do
  sp="$X/spec-RK-$tag"; mkdir -p "$sp/notes/verification/reports"; printf '%b' "$body" > "$sp/notes/verification/reports/opponent-findings-review.md"
  round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding open '- **Severity:** wrong-result')"$'\n' > "$sp/notes/opponent.md"
  both "RK-$tag" "$sp"; judge "B2 measure-2 consequence $tag" "RK-$tag" 3 3 'a Severity field whose list item holds more than its line in finding O-017'
done < "$X/k2.cases"

say '== B3: the real prior-review manifest and every returned round report read as a manifest'
sp="$X/spec-RR-real"; mkdir -p "$sp/notes/verification/reports"; cp "$C/$r/opponent-findings-2026-09-09.md" "$sp/notes/verification/reports/"
body=''; for f in O-001:return-envelope-parsing:wrong-result O-002:round-authorization-grammar:wrong-result O-003:live-control-semantic-validation:wrong-result O-004:gate-report-schema-validation:wrong-result O-005:config-interpolation-validation:wrong-result O-006:post-pr-followup-binding-schema:regression; do
  IFS=: read -r id cl sv <<< "$f"; body+="$(finding "### Finding $id" "$cl" open "- **Severity:** $sv")"$'\n'
done
round 1 CHALLENGED 6 0 "$body" > "$sp/notes/opponent.md"
both RR-real "$sp"; judge 'B3 the 2026-09-09 manifest parses' RR-real 0 0
check 'B3 the 2026-09-09 manifest: CUR and D catalogs identical' same "$(cmp -s "$w/RR-real-cur-C.nul" "$w/RR-real-d-C.nul" && echo same)"
nrep=0
for rep in "$C/$r"/opponent-round[0-9]*.md "$C/$r"/opponent-round3-reconcile.md; do
  case "$rep" in *-brief*) continue;; esac
  nrep=$((nrep+1)); b="$(basename "$rep" .md)"; sp="$X/spec-RR-$b"; mkdir -p "$sp/notes/verification/reports"; cp "$rep" "$sp/notes/verification/reports/opponent-findings-review.md"
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "RR-$b" "$sp"; judge "B3 $b as a manifest parses" "RR-$b" 0 0
done
check 'B3 every returned round report was read (rounds 1-14 but the reconciled 3, and its reconcile record)' 14 "$nrep"

say '== C: the recorded history, CUR against D'
for spec in 001-codex-subagent-gates-and-hard-task-escalation 002-usage-limit-handling-for-dispatched-runs 003-gate-round-reduction-and-token-discipline; do
  sp=".specify/specs/$spec"
  for l in C en_US.UTF-8; do
    for k in cur d; do
      K="$C"; [[ "$k" == d ]] && K="$D"
      ( cd "$K" && inloc "$l" bash scripts/spec-gate.sh tally "$sp" < /dev/null ) > "$w/H-tally-$spec-$k-$l.log" 2>&1; echo $? >> "$w/H-tally-$spec-$k-$l.log"
      ( cd "$K" && inloc "$l" bash scripts/sdd-analyze.sh "$sp" < /dev/null ) > "$w/H-an-$spec-$k-$l.log" 2>&1; echo $? >> "$w/H-an-$spec-$k-$l.log"
      ( cd "$K" && inloc "$l" bash scripts/spec-ac-coverage.sh "$sp" < /dev/null ) > "$w/H-cov-$spec-$k-$l.log" 2>&1; echo $? >> "$w/H-cov-$spec-$k-$l.log"
      for g in opponent reality-check; do
        f="$sp/notes/$g.md"; [[ -f "$K/$f" ]] || continue
        ( cd "$K" && inloc "$l" bash -c '. scripts/verification-lib.sh && vf_reports "$1" "$2" "$3" "$4"' _ "$f" "$g" "$w/H-cat-$spec-$g-$k-$l.nul" "$sp" < /dev/null ) > /dev/null 2> "$w/H-cat-$spec-$g-$k-$l.err"
        echo $? >> "$w/H-cat-$spec-$g-$k-$l.err"
        for n in $(seq 1 20); do
          ( cd "$K" && inloc "$l" bash -c '. scripts/verification-lib.sh && vf_report_block "$1" "$2"' _ "$f" "$n" < /dev/null ) > "$w/H-blk-$spec-$g-$n-$k-$l.txt" 2>/dev/null || { rm -f "$w/H-blk-$spec-$g-$n-$k-$l.txt"; break; }
        done
      done
      for mode in plan tasks; do
        ( cd "$K" && inloc "$l" bash -c '. scripts/verification-lib.sh && vf_bindings "$1" "$2" "" "$3"' _ "$sp" "$mode" "$w/H-bind-$spec-$mode-$k-$l.nul" < /dev/null ) > /dev/null 2> "$w/H-bind-$spec-$mode-$k-$l.err"; echo $? >> "$w/H-bind-$spec-$mode-$k-$l.err"
      done
      ( cd "$K" && inloc "$l" bash -c '. scripts/verification-lib.sh && vf_config .specify/stack.yml "$1/tasks.md" "$2"' _ "$sp" "$w/H-cfg-$spec-$k-$l" < /dev/null ) > /dev/null 2> "$w/H-cfg-$spec-$k-$l.err"; echo $? >> "$w/H-cfg-$spec-$k-$l.err"
      for doc in STATUS.md tasks.md plan.md spec.md; do
        [[ -f "$K/$sp/$doc" ]] || continue
        ( cd "$K" && inloc "$l" bash -c '. scripts/verification-lib.sh && vf_semantic_file "$1" "$1" "$2"' _ "$sp/$doc" "$w/H-sem-$spec-$doc-$k-$l.txt" < /dev/null ) 2>> "$w/H-sem-$spec-$k-$l.err"
      done
    done
    for kind in tally an cov; do
      check "C $spec $kind under $l: CUR and D identical, kit path normalized (output and exit)" same \
        "$(cmp -s <(sed "s#$C#KIT#g" "$w/H-$kind-$spec-cur-$l.log") <(sed "s#$D#KIT#g" "$w/H-$kind-$spec-d-$l.log") && echo same)"
    done
    say "  | $spec under $l: tally exit $(tail -1 "$w/H-tally-$spec-d-$l.log"), analyzer exit $(tail -1 "$w/H-an-$spec-d-$l.log"), ac-coverage exit $(tail -1 "$w/H-cov-$spec-d-$l.log")"
    for g in opponent reality-check; do
      [[ -f "$w/H-cat-$spec-$g-cur-$l.err" ]] || continue
      a="$w/H-cat-$spec-$g-cur-$l.nul"; b="$w/H-cat-$spec-$g-d-$l.nul"
      check "C $spec $g catalog under $l: CUR and D identical (or written by neither)" same "$( { [[ ! -e "$a" && ! -e "$b" ]] || cmp -s "$a" "$b"; } && echo same)"
      check "C $spec $g diagnostics and exit under $l: CUR and D identical" same "$(cmp -s "$w/H-cat-$spec-$g-cur-$l.err" "$w/H-cat-$spec-$g-d-$l.err" && echo same)"
      nb=0; same=1
      for x in "$w/H-blk-$spec-$g-"*"-cur-$l.txt"; do [[ -e "$x" ]] || continue; nb=$((nb+1)); cmp -s "$x" "${x/-cur-/-d-}" || same=0; done
      nd=0; for x in "$w/H-blk-$spec-$g-"*"-d-$l.txt"; do [[ -e "$x" ]] && nd=$((nd+1)); done
      check "C $spec $g every extracted round block under $l: CUR and D identical ($nb rounds)" "1 $nb" "$same $nd"
    done
    for mode in plan tasks; do
      check "C $spec $mode binding catalog and diagnostics under $l: CUR and D identical" same \
        "$( { [[ ! -e "$w/H-bind-$spec-$mode-cur-$l.nul" && ! -e "$w/H-bind-$spec-$mode-d-$l.nul" ]] || cmp -s "$w/H-bind-$spec-$mode-cur-$l.nul" "$w/H-bind-$spec-$mode-d-$l.nul"; } && cmp -s "$w/H-bind-$spec-$mode-cur-$l.err" "$w/H-bind-$spec-$mode-d-$l.err" && echo same)"
    done
    check "C $spec stage map and configuration catalog under $l: CUR and D identical" same \
      "$( { [[ ! -e "$w/H-cfg-$spec-cur-$l" && ! -e "$w/H-cfg-$spec-d-$l" ]] || diff -r "$w/H-cfg-$spec-cur-$l" "$w/H-cfg-$spec-d-$l" > /dev/null 2>&1; } && cmp -s "$w/H-cfg-$spec-cur-$l.err" "$w/H-cfg-$spec-d-$l.err" && echo same)"
    for doc in STATUS.md tasks.md plan.md spec.md; do
      [[ -f "$w/H-sem-$spec-$doc-cur-$l.txt" ]] || continue
      check "C $spec $doc semantic view under $l: CUR and D identical" same "$(cmp -s "$w/H-sem-$spec-$doc-cur-$l.txt" "$w/H-sem-$spec-$doc-d-$l.txt" && echo same)"
    done
  done
done
say '  the sealed digests: every completed round ledger of 003 against D'"'"'s extracted block'
nsealed=0
for g in opponent reality-check; do
  for led in "$C/$s/notes/verification/rounds/$g"/ROUND-*; do
    [[ -f "$led/report.sha256" ]] || continue
    n="${led##*ROUND-}"; nsealed=$((nsealed+1))
    for l in C en_US.UTF-8; do
      check "C 003 $g round $n sealed digest under $l equals D's block" "$(cat "$led/report.sha256")" "$(shasum -a 256 < "$w/H-blk-003-gate-round-reduction-and-token-discipline-$g-$n-d-$l.txt" | cut -d' ' -f1)"
    done
  done
done
check 'C 003: fifteen sealed rounds compared (fourteen opponent, one reality-check)' 15 "$nsealed"
for n in 14 15; do
  for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"; ( cd "$K" && bash scripts/spec-gate.sh waiver "$s" opponent "$n" < /dev/null ) > "$w/H-w$n-$k.log" 2>&1; echo $? >> "$w/H-w$n-$k.log"; done
  check "C waiver check for round $n: CUR and D identical" same "$(cmp -s "$w/H-w$n-cur.log" "$w/H-w$n-d.log" && echo same)"
done
check 'C waiver round 14 reported completed (exit 0)' 0 "$(tail -1 "$w/H-w14-d.log")"
check 'C waiver round 15 refused (exit 4)' 4 "$(tail -1 "$w/H-w15-d.log")"
for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"
  ( cd "$K" && bash -c '. scripts/verification-lib.sh && vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$w/H-snap-$k.nul" ) > "$w/H-snap-$k.out" 2>&1
  tr '\0' '\n' < "$w/H-snap-$k.nul" | paste - - - - - - | sed "s#$K#KIT#g" | LC_ALL=C grep -v -F -e 'scripts/verification-lib.sh' -e 'templates/verification-contract.md' > "$w/H-snap-$k.tsv"
done
check 'C snapshot records outside the two candidate files identical (kit path normalized)' same "$(cmp -s "$w/H-snap-cur.tsv" "$w/H-snap-d.tsv" && echo same)"
say "  | snapshot: CUR $(head -c 16 "$w/H-snap-cur.out"), D $(head -c 16 "$w/H-snap-d.out"), records compared $(wc -l < "$w/H-snap-d.tsv" | tr -d ' ')"
for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"
  t0=$(date +%s); ( cd "$K" && bash scripts/spec-gate.sh tally "$s" < /dev/null ) > /dev/null 2>&1; say "  | timing: 003 tally on $k took $(( $(date +%s) - t0 )) s"
done

say '== D: the full suite on D in its own copy (TMPDIR ending in /), failures read assertion by assertion'
DS="$X/dsuite"; cp -R "$D" "$DS"; mkdir -p "$X/tmp-suite"
( cd "$DS" && TMPDIR="$X/tmp-suite/" bash tests/run.sh < /dev/null ) > "$w/suite.log" 2>&1; echo $? > "$w/suite.rc"
say "  | suite rc=$(cat "$w/suite.rc"); per-suite: $(grep -E '^  -- [0-9]+/[0-9]+ passed' "$w/suite.log" | tr '\n' ' ')"
grep -E '^  FAIL ' "$w/suite.log" | sed 's/^/  | /'
grep -E 'assert|expected' "$w/suite.log" | LC_ALL=C cut -c1-230 | sed 's/^/  |   /' | head -60
cp "$w/suite.log" "$WT/$r/r14-measure-suite.log"
check 'D suite: the only failing test is test_reports_and_tally (the over-refusal row value-details, predicted)' \
  '  FAIL test_reports_and_tally' "$(grep -E '^  FAIL ' "$w/suite.log" | tr '\n' '|' | sed 's/|$//')"
check 'D suite: every failing assertion is the value-details row or its exit check' 0 "$(grep -E '^ *assert: ' "$w/suite.log" | grep -v -F 'value-details' | grep -v -c -F 'expected exit 3, got 0: record_line_vf' | tr -d ' ')"
check 'D suite: the value-details row failed under both locales' 2 "$(grep -E '^ *assert: ' "$w/suite.log" | grep -c -F 'written as value-details was not refused' | tr -d ' ')"

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r14-measure failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
