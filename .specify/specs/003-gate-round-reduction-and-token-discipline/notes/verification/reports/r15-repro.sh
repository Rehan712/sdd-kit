#!/usr/bin/env bash
# Round-15 finding O-018 (reopened, blocking) reproduced BEFORE any repair, 2026-10-07 (session 15): the reported
# members plus siblings derived from the mechanism the report names. Read-only against the live worktree: every
# case runs in standalone copies built from the live enumeration, under the scratch directory, with a TMPDIR
# ending in `/` inside it. CUR is this tree (the kernel as r14-edits/post-apply-2). PRE is CUR with
# r15-session.diff reversed (its four files, the kernel as r14-edits/pre-apply), so a member that also holds on
# PRE predates T030o46. Each case runs through vf_reports directly on CUR and PRE in both passes (the prior-review
# manifest and the canonical round), and each mechanism end to end through spec-gate.sh round --complete and
# tally on CUR, under LANG=C and LANG=en_US.UTF-8 with every LC_* removed. marked 17.0.5 and markdown-it 12.3.2
# (a CommonMark renderer, with html enabled) render each case for the record; no verdict reads a rendering.
# The live status outside notes/verification/ is compared before and after.
# Mechanism (round 15): the paragraph reader joins a line to the paragraph before it unless vf_block_start
# reads it as a block start, and reads only the first word of the joined text, so a paragraph boundary placed
# differently from CommonMark 0.31.2 hides the label: a boundary the reader misses (a sibling ordered item of
# any number, 4.8 and 5.2; a setext underline, 4.3; a block-quote marker, which vf_para strips before it asks
# vf_block_start, 5.1), a boundary it invents (a line indented four or more spaces that begins with a block
# marker continues the paragraph, 4.4 and 4.8, but vf_para strips the indentation first), code-span precedence
# (6.1: a code span binds tighter than link brackets, so a `]` inside one closes no link), and a rendered line
# start inside a line (a br tag, a block-level tag), in prose and in a field-line value.
# Siblings derived from the same productions: the `)` delimiter and a leading zero for the ordered item, the
# `-` setext underline (a thematic break to vf_block_start, so expected read), a nested block quote, the other
# block markers at four spaces of indentation (`>`, `#`, `1.`), a code span in an image, the other spellings of
# br, and a p and a div tag inside a line.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
MARKED=/Users/babar/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/marked/lib/marked.esm.js
MDIT="/Applications/Cursor.app/Contents/Resources/app/node_modules/@vscode/vsce/node_modules/markdown-it"
X="$SP/r15-repro"; C="$X/cur"; P="$X/pre"; w="$X/work"
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
check 'CUR: the four files hash as r14-edits/post-apply-2' 4 "$(cd "$C" && shasum -a 256 -c "$WT/$r/r14-edits/post-apply-2.sha256" 2>/dev/null | grep -c ': OK$')"
for d in scripts templates tests; do cp -R "$C/$d" "$P/$d"; done
( cd "$P" && patch -R -p1 -s < "$WT/$r/r15-session.diff" ); check 'PRE: r15-session.diff reverses cleanly' 0 "$?"
check 'PRE: the four files hash as r14-edits/pre-apply' 4 "$(cd "$P" && shasum -a 256 -c "$WT/$r/r14-edits/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
printf '%s\n' "import { marked } from '$MARKED';" "import { readFileSync } from 'node:fs';" \
  "process.stdout.write(marked.parse(readFileSync(0, 'utf8')));" > "$X/render-marked.mjs"
printf '%s\n' "const md = require('$MDIT')({html: true});" "const fs = require('node:fs');" \
  "process.stdout.write(md.render(fs.readFileSync(0, 'utf8')));" > "$X/render-mdit.cjs"
render() {
  say "  | marked:      $(printf '%b' "$1" | ( cd "$X" && node render-marked.mjs ) 2>&1 | tr '\n' ' ' | LC_ALL=C cut -c1-300)"
  say "  | markdown-it: $(printf '%b' "$1" | ( cd "$X" && node render-mdit.cjs ) 2>&1 | tr '\n' ' ' | LC_ALL=C cut -c1-300)"
}

# A canonical finding block. $4 is the whole Severity part (one or more lines, no trailing newline); $5 the Where value.
finding() { # heading class status severity-lines [where]
  printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%s\n- **Scenario:** a recorded trigger\n- **Where:** %s\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read or refuse every record line\n' "$1" "$2" "$3" "$4" "${5:-scripts/run.sh:9}"
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
first() { head -1 "$w/$1.err" | LC_ALL=C cut -c1-170; }
kitof() { if [[ "$1" == pre ]]; then printf '%s' "$P"; else printf '%s' "$C"; fi; }

# tag|kind|body. kind: member (reported by round 15: must seal in silence on CUR), sibling (derived: its CUR
# result is recorded, and it is a member when it seals there), control (must be refused on CUR by name).
cat > "$X/cases" <<'EOF'
m1-ordered-sibling|member|1. a\n2. <b\ntitle="x">Severity: data-loss</b>
m2-zero-one-after-text|member|Text\n01. <b\ntitle="x">Severity: data-loss</b>
m3-setext-underline|member|A remark\n===\n<b\ntitle="x">Severity: data-loss</b>
m4-block-quote|member|Note\n> <b\n> title="x">Severity: data-loss</b>
m5-indented-continuation|member|<b title="a\n    - b">Severity: data-loss</b>
m6-code-span-in-link|member|[`]`](u)Severity: data-loss
m7-br-in-prose|member|Note<br>Severity: data-loss
s1-ordered-paren-sibling|sibling|1) a\n2) <b\ntitle="x">Severity: data-loss</b>
s2-setext-dash|sibling|A remark\n---\n<b\ntitle="x">Severity: data-loss</b>
s3-nested-quote|sibling|Note\n> > <b\n> > title="x">Severity: data-loss</b>
s4-indented-quote-marker|sibling|<b title="a\n    > b">Severity: data-loss</b>
s5-indented-heading-marker|sibling|<b title="a\n    # b">Severity: data-loss</b>
s6-indented-ordered-marker|sibling|<b title="a\n    1. b">Severity: data-loss</b>
s7-code-span-in-image|sibling|![`]`](u)Severity: data-loss
s8-br-self-closing|sibling|Note<br/>Severity: data-loss
s9-br-spaced|sibling|Note<br />Severity: data-loss
s10-br-upper|sibling|Note<BR>Severity: data-loss
s11-p-inside-line|sibling|Note<p>Severity: data-loss
s12-div-inside-line|sibling|Note <div>Severity: data-loss</div>
c1-canonical|control|- **Severity:** data-loss
c2-tag-alone|control|<b\ntitle="x">Severity: data-loss</b>
c3-ordered-one-after-text|control|Text\n1. <b\ntitle="x">Severity: data-loss</b>
EOF
members=0; sealed_siblings=''
say '== O-018 direct, the manifest pass: G-042 at minor, a blank line, then the case; a CLEARED round 1 re-records G-042 at minor'
while IFS='|' read -r tag kind body; do
  render "- **Severity:** minor\n\n$body"
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-M-$tag-$kit"; mkdir -p "$sp/notes"
    mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n$body")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      t="M-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      case "$kind:$kit" in
        member:cur) check "M $tag cur $l: sealed in silence (rc 0)" 0 "$rc"; check "M $tag cur $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')";;
        control:cur) check "M $tag cur $l: refused (rc 3)" 3 "$rc"; has "M $tag cur $l: by name" 'a second Severity line in finding G-042' "$w/$t.err";;
        *) say "  | M $tag $kit $l: rc=$rc $(first "$t")"
           [[ "$kind:$kit:$rc" != sibling:cur:0 ]] || sealed_siblings+=" M:$tag:$l";;
      esac
    done
  done
done < "$X/cases"

say '== O-018 direct, the canonical pass: a CLEARED round 1 at 0 . 1 whose new G-050 carries the minor line, a blank line, then the case'
while IFS='|' read -r tag kind body; do
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-K-$tag-$kit"; mkdir -p "$sp/notes"
    round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$body")")"$'\n' > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      t="K-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      case "$kind:$kit" in
        member:cur)
          check "K $tag cur $l: sealed in silence (rc 0)" 0 "$rc"; check "K $tag cur $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')"
          check "K $tag cur $l: G-050 recorded at minor" 1 "$(catalog "$t" | grep -c '^finding|1|G-050|dup-binding|new|none|minor|')";;
        control:cur)
          check "K $tag cur $l: refused (rc 3)" 3 "$rc"
          if [[ "$tag" == c1-* ]]; then has "K $tag cur $l: by name" 'duplicate finding field' "$w/$t.err"
          else has "K $tag cur $l: by name" 'a Severity line this grammar cannot read in finding G-050' "$w/$t.err"; fi;;
        *) say "  | K $tag $kit $l: rc=$rc $(first "$t")"
           [[ "$kind:$kit:$rc" != sibling:cur:0 ]] || sealed_siblings+=" K:$tag:$l";;
      esac
    done
  done
done < "$X/cases"

say '== O-018 direct, a rendered line start inside a field-line value (the Where field), both passes'
wv='a.sh:1<br><b>Severity:</b> data-loss'
render "- **Severity:** minor\n- **Where:** $wv"
for kit in cur pre; do
  k="$(kitof "$kit")"; sp="$X/spec-W-$kit"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n- **Where:** $wv")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  mkdir -p "$sp/k/notes"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new '- **Severity:** minor' "$wv")"$'\n' > "$sp/k/notes/opponent.md"
  for l in C en_US.UTF-8; do
    t="WM-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
    t2="WK-$kit-$l"; rc2="$(vfr "$t2" "$k" "$l" "$sp/k/notes/opponent.md" "$sp/k")"
    if [[ "$kit" == cur ]]; then
      check "W manifest cur $l: sealed in silence (rc 0)" 0 "$rc"; check "W manifest cur $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')"
      check "W canonical cur $l: sealed in silence (rc 0)" 0 "$rc2"
      check "W canonical cur $l: G-050 recorded at minor" 1 "$(catalog "$t2" | grep -c '^finding|1|G-050|dup-binding|new|none|minor|')"
    else say "  | W pre $l: manifest rc=$rc canonical rc=$rc2"; fi
  done
done
say "  | siblings sealed on CUR (members by derivation):${sealed_siblings:- none}"

say '== E: end to end through spec-gate.sh on CUR; fixture, floor and reservation built under C each time'
awk '$0 != "t_run_all"' "$C/tests/test-spec-gate.sh" > "$C/tests/.r15-spec-gate.sh"
build() { # sandbox -> writes spec, cli and the reservation line to <sandbox>/paths, reserve.log
  ( cd "$C" && SANDBOX="$1" bash -c '
      . tests/.r15-spec-gate.sh || exit 9
      spec="$(make_verification_git_dir r15)" || exit 9
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
complete() { # tag locale returned-file
  inloc "$2" bash "$CLI" round "$SPEC" opponent --complete "$3" > "$w/E-$1-$2.log" 2>&1; echo $? > "$w/E-$1-$2.rc"
  inloc "$2" bash "$CLI" tally "$SPEC" > "$w/E-$1-$2.tally" 2>&1; echo $? > "$w/E-$1-$2.tally.rc"
  say "  | E $1 $2: complete rc=$(cat "$w/E-$1-$2.rc") $(head -1 "$w/E-$1-$2.log" | LC_ALL=C cut -c1-150)"
  say "  |   tally rc=$(cat "$w/E-$1-$2.tally.rc") $(LC_ALL=C grep -E '^(opponent rounds|blocking|severity-downgrades)=' "$w/E-$1-$2.tally" | tr '\n' ' ')"
}
for l in C en_US.UTF-8; do
  # One manifest member per mechanism: a missed boundary (the ordered sibling, the setext underline, the block
  # quote), an invented one (the indented line), code-span precedence and a rendered line start; then the control.
  for tag in m1-ordered-sibling m3-setext-underline m4-block-quote m5-indented-continuation m6-code-span-in-link m7-br-in-prose c1-canonical; do
    body="$(awk -F'|' -v t="$tag" '$1 == t {print $3}' "$X/cases")"
    setup "$tag" "$l"; mani "$SPEC" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n$body")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' "${ID[@]}" > "$SB/returned.md"
    complete "$tag" "$l" "$SB/returned.md"
    if [[ "$tag" == c1-* ]]; then
      check "E $tag $l: refused (rc 3)" 3 "$(cat "$w/E-$tag-$l.rc")"; has "E $tag $l: by name" 'a second Severity line in finding G-042' "$w/E-$tag-$l.log"
    else
      check "E $tag $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-$tag-$l.rc")"
      has "E $tag $l: the completion line" 'round completed gate=opponent round=1 verdict=CLEARED' "$w/E-$tag-$l.log"
      has "E $tag $l: the tally counts the finding at minor" 'blocking=0 minor=1' "$w/E-$tag-$l.tally"
    fi
  done
  # The canonical pass end to end: a new G-050 at minor with the indented-continuation member.
  setup k-indented "$l"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' '- **Severity:** minor\n\n<b title="a\n    - b">Severity: data-loss</b>')")"$'\n' "${ID[@]}" > "$SB/returned.md"
  complete k-indented "$l" "$SB/returned.md"
  check "E k-indented $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-k-indented-$l.rc")"
  has "E k-indented $l: the tally counts G-050 at minor" 'blocking=0 minor=1' "$w/E-k-indented-$l.tally"
done

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r15-repro failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
