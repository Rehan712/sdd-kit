#!/usr/bin/env bash
# Round-17 findings O-018 (reopened, blocking), O-024 (new, blocking) and O-023 (reopened, minor), and the round's
# non-blocking minor, reproduced BEFORE any repair, 2026-10-09 (session 19). Pattern: r17-repro.sh. The cases are the
# reviewer's own, taken from its transcript (its run.sh cases, h2/A.md, B.md, C.md, M.md, M2.md, and the V and U
# timing runs), not retyped from prose; siblings the invoker derived from the same mechanisms are marked `derived`:
# their results are recorded, not asserted, and the measurement judges them.
# Read-only against the live worktree: every case runs in standalone copies built from the live enumeration, under
# the scratch directory, with a TMPDIR ending in `/` inside it. CUR is this tree (the four files as
# r17-edits/post-apply-2). PRE is CUR with r17-session.diff reversed (the four files as r17-edits/pre-apply), so a
# member that also holds on PRE predates T030o48 to T030o50. Each case runs through vf_reports directly on CUR and PRE
# in both passes (the prior-review manifest and the canonical round), and each mechanism end to end through
# spec-gate.sh round --complete and tally on CUR, under LANG=C and LANG=en_US.UTF-8 with every LC_* removed.
# marked 17.0.5 and markdown-it 12.3.2 (html enabled) render each case for the record; no verdict reads a rendering.
# Mechanisms (round 17): O-018, a backtick inside a construct that binds before a code span (an email autolink whose
# local part begins with a digit or a symbol, a link destination, a link title) pairs, to the gate, with a later
# backtick into a code span no renderer forms, so a live tag after it reads as inside a span; O-024, a finding's
# extent and the lines a reader sees come from readings a renderer does not share (a fence a list item opens hides a
# `### x` line both passes read as closing the finding; a link reference definition renders nothing yet carries a
# field line); O-023, one bracket quoted in a code span keeps a candidate unsettled for a whole run; the minor, the
# narrowed check is judged before the line's own heading opens or closes a finding.
# The live status outside notes/verification/ is compared before and after.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
MARKED=/Users/babar/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/marked/lib/marked.esm.js
MDIT="/Applications/Cursor.app/Contents/Resources/app/node_modules/@vscode/vsce/node_modules/markdown-it"
X="$SP/r18-repro"; C="$X/cur"; P="$X/pre"; w="$X/work"
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
check 'CUR: the four files hash as r17-edits/post-apply-2' 4 "$(cd "$C" && shasum -a 256 -c "$WT/$r/r17-edits/post-apply-2.sha256" 2>/dev/null | grep -c ': OK$')"
for d in scripts templates tests; do cp -R "$C/$d" "$P/$d"; done
( cd "$P" && patch -R -p1 -s < "$WT/$r/r17-session.diff" ); check 'PRE: r17-session.diff reverses cleanly' 0 "$?"
check 'PRE: the four files hash as r17-edits/pre-apply' 4 "$(cd "$P" && shasum -a 256 -c "$WT/$r/r17-edits/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
printf '%s\n' "import { marked } from '$MARKED';" "import { readFileSync } from 'node:fs';" \
  "process.stdout.write(marked.parse(readFileSync(0, 'utf8')));" > "$X/render-marked.mjs"
printf '%s\n' "const md = require('$MDIT')({html: true});" "const fs = require('node:fs');" \
  "process.stdout.write(md.render(fs.readFileSync(0, 'utf8')));" > "$X/render-mdit.cjs"
render() {
  say "  | marked:      $(printf '%b' "$1" | ( cd "$X" && node render-marked.mjs ) 2>&1 | tr '\n\r' '~^' | LC_ALL=C cut -c1-400)"
  say "  | markdown-it: $(printf '%b' "$1" | ( cd "$X" && node render-mdit.cjs ) 2>&1 | tr '\n\r' '~^' | LC_ALL=C cut -c1-400)"
}

finding() { # heading class status severity-lines [where]
  printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%s\n- **Scenario:** a recorded trigger\n- **Where:** %s\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read or refuse every record line\n' "$1" "$2" "$3" "$4" "${5:-scripts/run.sh:9}"
}
ftail() { # heading class status tail: every field but Severity, then the tail (the reviewer's F, h2/mk.sh)
  printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** bind\n%s' "$1" "$2" "$3" "$4"
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
first() { head -1 "$w/$1.err" | sed 's#.*/opponent[^:]*:#line #' | LC_ALL=C cut -c1-170; }
kitof() { if [[ "$1" == pre ]]; then printf '%s' "$P"; else printf '%s' "$C"; fi; }
sealed() { # label tag passname id: rc 0, stderr empty, the finding recorded at minor
  check "$1: sealed in silence (rc 0)" 0 "$(cat "$w/$2.rc")"; check "$1: stderr empty" 0 "$(wc -c < "$w/$2.err" | tr -d ' ')"
  if [[ "$3" == K ]]; then check "$1: G-050 recorded at minor" 1 "$(catalog "$2" | grep -c "^finding|1|G-050|$4|new|none|minor|")"; fi
}

say '== O-018 direct: G-042 at minor (manifest) or a new G-050 at minor (canonical), a blank line, then the case'
# kind: o18 (a reported member: seals in silence on CUR in both passes), derived (recorded), control (refused on CUR).
cat > "$X/cases" <<'EOF'
r1-autolink-digit-br|o18|Note <1`@a.b><br>Severity: data-loss, tick: `.
r2-autolink-digit-pre|o18|Note <1`@a.b><pre>Severity: data-loss</pre>`
r3-autolink-underscore-p|o18|Note <_`@a.b><p>Severity: data-loss `
r4-destination-br|o18|[x](u`v)<br>Severity: data-loss, tick: `.
r5-title-br|o18|[x](u "`")<br>Severity: data-loss, tick: `.
r6-angle-destination-pre|derived|[x](<1`b>)<pre>Severity: data-loss</pre>`
r7-image-destination-pre|derived|![x](u`v)<pre>Severity: data-loss</pre>`
d1-autolink-backtick-start|derived|Note <`a@b.c><br>Severity: data-loss, tick: `.
d2-autolink-plus|derived|Note <+1`@a.b><br>Severity: data-loss, tick: `.
d3-title-spans-lines|derived|[x](u '\n`')<br>Severity: data-loss, tick: `.
d4-destination-on-next-line|derived|[x](\nu`v)<br>Severity: data-loss, tick: `.
c0-control-pre|control|Note <pre>Severity: data-loss</pre>`
EOF
sealed_pre=''
while IFS='|' read -r tag kind body; do
  say "-- $tag ($kind)"; render "- **Severity:** minor\n\n$body"
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-M-$tag-$kit"; mkdir -p "$sp/notes"
    mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n$body")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
    sk="$X/spec-K-$tag-$kit"; mkdir -p "$sk/notes"
    round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$body")")"$'\n' > "$sk/notes/opponent.md"
    for l in C en_US.UTF-8; do
      vfr "M-$tag-$kit-$l" "$k" "$l" "$sp/notes/opponent.md" "$sp" > /dev/null
      vfr "K-$tag-$kit-$l" "$k" "$l" "$sk/notes/opponent.md" "$sk" > /dev/null
      case "$kind" in
        o18) sealed "O-018 M $tag $kit $l" "M-$tag-$kit-$l" M; sealed "O-018 K $tag $kit $l" "K-$tag-$kit-$l" K dup-binding;;
        control)
          if [[ "$kit" == cur ]]; then
            check "O-018 M $tag cur $l: refused (rc 3)" 3 "$(cat "$w/M-$tag-$kit-$l.rc")"; has "O-018 M $tag cur $l: by name" 'raw HTML outside a code span in finding G-042' "$w/M-$tag-$kit-$l.err"
            check "O-018 K $tag cur $l: refused (rc 3)" 3 "$(cat "$w/K-$tag-$kit-$l.rc")"; has "O-018 K $tag cur $l: by name" 'raw HTML outside a code span in finding G-050' "$w/K-$tag-$kit-$l.err"
          fi;;
        *) say "  | $tag $kit $l: manifest rc=$(cat "$w/M-$tag-$kit-$l.rc") $(first "M-$tag-$kit-$l") | canonical rc=$(cat "$w/K-$tag-$kit-$l.rc") $(first "K-$tag-$kit-$l") G050-minor=$(catalog "K-$tag-$kit-$l" | grep -c '^finding|1|G-050|dup-binding|new|none|minor|')";;
      esac
      [[ "$kit" != pre || "$kind" == control || "$(cat "$w/M-$tag-$kit-$l.rc") $(cat "$w/K-$tag-$kit-$l.rc")" != '0 0' ]] || sealed_pre+=" $tag:$l"
    done
  done
done < "$X/cases"
say "  | cases that also seal on PRE in both passes:${sealed_pre:- none}"
# A backtick inside a full reference link's label, the definition outside the finding (derived).
for kit in cur pre; do
  k="$(kitof "$kit")"; body='[x][a`b]<br>Severity: data-loss, tick: `.'
  sp="$X/spec-L-$kit"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%s\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n%s\n' '[a`b]: /u' "$body")"
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  sk="$X/spec-LK-$kit"; mkdir -p "$sk/notes"
  { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 1\n### What I attacked\nFinding records read by both readers.\n\n%s\n\n' "$SRC" '[a`b]: /u'
    finding '### Finding G-050' dup-binding new "$(printf -- '- **Severity:** minor\n\n%s' "$body")"
    printf '### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n'; } > "$sk/notes/opponent.md"
  for l in C en_US.UTF-8; do
    vfr "L-$kit-$l" "$k" "$l" "$sp/notes/opponent.md" "$sp" > /dev/null; vfr "LK-$kit-$l" "$k" "$l" "$sk/notes/opponent.md" "$sk" > /dev/null
    say "  | d5-label-tick (derived) $kit $l: manifest rc=$(cat "$w/L-$kit-$l.rc") $(first "L-$kit-$l") | canonical rc=$(cat "$w/LK-$kit-$l.rc") $(first "LK-$kit-$l")"
  done
done
render "[a\`b]: /u\n\n- **Severity:** minor\n\n[x][a\`b]<br>Severity: data-loss, tick: \`."

say '== O-024 direct: the reviewer cases (canonical A, B, C after every field but Severity; manifest M, M2), CUR and PRE'
A=$'\n[a]: /u \'\n    - **Severity:** minor\n    - x\'\n'
B=$'- **Severity:** minor\n- ```\n  ### x\n- **Severity**: data-loss\n'
CC=$'\n[a]: /u \'\n    - **Severity:** minor\n    - x\'\n\n- ```\n  ### x\n- **Severity**: data-loss\n'
M=$'### Finding G-042\n- **Class:** tier-binding\n\n[a]: /u \'\n    - **Severity:** minor\n    - x\'\n\n- ```\n  ### x\n- **Severity**: data-loss\n'
M2=$'### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n- ```\n  ### x\n- **Severity**: data-loss\n'
M1=$'### Finding G-042\n- **Class:** tier-binding\n\n[a]: /u \'\n    - **Severity:** minor\n    - x\'\n'
# Siblings the invoker derived (recorded): a fence a list item opens on a later line at 2 spaces, which the tracker
# opens and a column-0 fence closes while a renderer ends it with the item (the phases swap); one at 4 spaces in an
# item, which the tracker does not open; a definition inside a list item; a definition whose label spans lines.
X1=$'- **Severity:** minor\n- note\n  ```\n```\n### x\n```\n- **Severity**: data-loss\n- y\n  ```\n'
X2=$'- **Severity:** minor\n- note\n\n    ```\n  ### x\n    ```\n- **Severity**: data-loss\n'
X3=$'- [a]: /u \'\n      - **Severity:** minor\n      - x\'\n'
X4=$'\n[a\nb]: /u \'\n    - **Severity:** minor\n    - x\'\n'
for v in A B CC X1 X2 X3 X4; do
  body="${!v}"; say "-- canonical $v"; render "$(ftail '### Finding G-050' tier-binding new "$body")"
  for kit in cur pre; do
    k="$(kitof "$kit")"; sk="$X/spec-O-$v-$kit"; mkdir -p "$sk/notes"
    round 1 CLEARED 0 1 "$(ftail '### Finding G-050' tier-binding new "$body")"$'\n' > "$sk/notes/opponent.md"
    for l in C en_US.UTF-8; do
      vfr "O-$v-$kit-$l" "$k" "$l" "$sk/notes/opponent.md" "$sk" > /dev/null
      case "$v" in
        A|B|CC) sealed "O-024 K $v $kit $l" "O-$v-$kit-$l" K tier-binding;;
        *) say "  | $v $kit $l: canonical rc=$(cat "$w/O-$v-$kit-$l.rc") $(first "O-$v-$kit-$l") G050-minor=$(catalog "O-$v-$kit-$l" | grep -c '^finding|1|G-050|tier-binding|new|none|minor|')";;
      esac
    done
  done
done
for v in M M1 M2 X1 X2 X3 X4; do
  case "$v" in X*) body=$'### Finding G-042\n- **Class:** tier-binding\n'"${!v}";; *) body="${!v}";; esac
  say "-- manifest $v"; render "$body"
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-OM-$v-$kit"; mkdir -p "$sp/notes"
    mani "$sp" "$body"
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      vfr "OM-$v-$kit-$l" "$k" "$l" "$sp/notes/opponent.md" "$sp" > /dev/null
      case "$v" in
        M|M1|M2) sealed "O-024 M $v $kit $l" "OM-$v-$kit-$l" M;;
        *) say "  | $v $kit $l: manifest rc=$(cat "$w/OM-$v-$kit-$l.rc") $(first "OM-$v-$kit-$l")";;
      esac
    done
  done
done

say '== the minor: the narrowed check is judged before the line'"'"'s own heading opens or closes a finding (CUR)'
H1="$(finding '### Finding G-050 <b>x</b>' dup-binding new '- **Severity:** minor')"$'\n'
H2="$(finding '### Finding G-050' dup-binding new '- **Severity:** minor')"$'\n'"$(finding '### Finding G-051 <b>x</b>' dup-binding new '- **Severity:** minor')"$'\n'
H3="$(finding '### Finding G-050' dup-binding new '- **Severity:** minor')"$'\n### Notes <b>x</b>\nA note.\n'
for v in H1 H2 H3; do
  sk="$X/spec-H-$v"; mkdir -p "$sk/notes"
  case "$v" in
    H1) round 1 CLEARED 0 1 "$H1" > "$sk/notes/opponent.md";;
    H2) round 1 CLEARED 0 2 "$H2" > "$sk/notes/opponent.md";;
    H3) round 1 CLEARED 0 1 "$H3" > "$sk/notes/opponent.md";;
  esac
  for l in C en_US.UTF-8; do vfr "H-$v-$l" "$C" "$l" "$sk/notes/opponent.md" "$sk" > /dev/null; done
done
for l in C en_US.UTF-8; do
  check "minor H1 $l: the first Finding heading carrying a b tag parses (rc 0)" 0 "$(cat "$w/H-H1-$l.rc")"
  check "minor H2 $l: a later Finding heading carrying a b tag is refused (rc 3)" 3 "$(cat "$w/H-H2-$l.rc")"
  has "minor H2 $l: refused under the previous finding" 'raw HTML outside a code span in finding G-050' "$w/H-H2-$l.err"
  check "minor H3 $l: a section heading that closes the finding, carrying a b tag, is refused (rc 3)" 3 "$(cat "$w/H-H3-$l.rc")"
  has "minor H3 $l: refused under the finding it closes" 'raw HTML outside a code span in finding G-050' "$w/H-H3-$l.err"
done

say '== E: end to end through spec-gate.sh on CUR; fixture, floor and reservation built under C each time'
awk '$0 != "t_run_all"' "$C/tests/test-spec-gate.sh" > "$C/tests/.r18-spec-gate.sh"
build() { # sandbox -> writes spec, cli and the reservation line to <sandbox>/paths, reserve.log
  ( cd "$C" && SANDBOX="$1" bash -c '
      . tests/.r18-spec-gate.sh || exit 9
      spec="$(make_verification_git_dir r18)" || exit 9
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
sealed_e() { check "E $1 $2: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-$1-$2.rc")"
  has "E $1 $2: the completion line" 'round completed gate=opponent round=1 verdict=CLEARED' "$w/E-$1-$2.log"
  has "E $1 $2: the tally counts the finding at minor" 'blocking=0 minor=1' "$w/E-$1-$2.tally"; }
bodyof() { awk -F'|' -v t="$1" '$1 == t {print $3}' "$X/cases"; }
for l in C en_US.UTF-8; do
  # O-018: the autolink member and the destination member in the manifest pass, the autolink in the canonical pass.
  for tag in r1-autolink-digit-br r4-destination-br; do
    setup "m-$tag" "$l"; mani "$SPEC" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n$(bodyof "$tag")")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' "${ID[@]}" > "$SB/returned.md"
    complete "m-$tag" "$l" "$SB/returned.md"; sealed_e "m-$tag" "$l"
  done
  setup k-r2 "$l"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$(bodyof r2-autolink-digit-pre)")")"$'\n' "${ID[@]}" > "$SB/returned.md"
  complete k-r2 "$l" "$SB/returned.md"; sealed_e k-r2 "$l"
  setup k-c0 "$l"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$(bodyof c0-control-pre)")")"$'\n' "${ID[@]}" > "$SB/returned.md"
  complete k-c0 "$l" "$SB/returned.md"
  check "E k-c0 $l: the control is refused (rc 3)" 3 "$(cat "$w/E-k-c0-$l.rc")"; has "E k-c0 $l: by name" 'raw HTML outside a code span in finding G-050' "$w/E-k-c0-$l.log"
  # O-024: the combined case in both passes.
  setup k-cc "$l"
  round 1 CLEARED 0 1 "$(ftail '### Finding G-050' tier-binding new "$CC")"$'\n' "${ID[@]}" > "$SB/returned.md"
  complete k-cc "$l" "$SB/returned.md"; sealed_e k-cc "$l"
  setup m-m "$l"; mani "$SPEC" "$M"
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' "${ID[@]}" > "$SB/returned.md"
  complete m-m "$l" "$SB/returned.md"; sealed_e m-m "$l"
done

say '== O-023: one canonical round, timed on CUR (the reviewer V and U runs)'
perf() { # n variant -> seconds; rc in $w/perf-<variant>-<n>.rc
  local n="$1" v="$2" d="$X/perf-$2-$1" st i; mkdir -p "$d/notes"
  { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 1\n### What I attacked\nx\n### Finding G-050\n- **Class:** tier-binding\n- **Status:** new\n- **Prior:** none\n- **Severity:** minor\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n' "$SRC"
    if [[ "$v" == V ]]; then
      printf -- '- **Reproduced:** the opening bracket `[` is quoted in a code span here\n'
      for i in $(seq 0 $((n - 1))); do printf '  - step %d: ran `vf_reports x` against [the copy](https://x.example/%d) and saw *exit 0* with `rc=%d` here, fine\n' "$i" "$i" "$i"; done
    else
      printf -- '- **Reproduced:** many lines\n'
      for i in $(seq 0 $((n - 1))); do printf '  - member %d: an opening bracket `[` written in a code span at column %d is literal and the copy stayed intact\n' "$i" "$i"; done
    fi
    printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed\n- **Class-wide fix:** bind\n### Held up / follow-up tasks\nx\n<!-- gate-round-end: opponent:1 -->\n'; } > "$d/notes/opponent.md"
  st=$(date +%s); inloc C bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$C" "$d/notes/opponent.md" "$d/c.nul" "$d" < /dev/null > /dev/null 2> "$w/perf-$v-$n.err"
  echo $? > "$w/perf-$v-$n.rc"; echo $(( $(date +%s) - st ))
}
u50="$(perf 50 U)"; u100="$(perf 100 U)"; v200="$(perf 200 V)"; v400="$(perf 400 V)"
say "  | CUR U (a bracket in a code span on every line): n=50 ${u50}s rc=$(cat "$w/perf-U-50.rc"); n=100 ${u100}s rc=$(cat "$w/perf-U-100.rc")"
say "  | CUR V (one bracket in a code span, then n lines): n=200 ${v200}s rc=$(cat "$w/perf-V-200.rc"); n=400 ${v400}s rc=$(cat "$w/perf-V-400.rc")"
check 'O-023: CUR parses the 400-line V run (rc 0)' 0 "$(cat "$w/perf-V-400.rc")"
check 'O-023: CUR takes 30 s or more on the 400-line V run (T030o50 bound missed)' 1 "$(( v400 >= 30 ? 1 : 0 ))"
check 'O-023: doubling the V run from 200 to 400 lines more than quadruples its time' 1 "$(( v400 > 4 * v200 ? 1 : 0 ))"

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r18-repro failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
