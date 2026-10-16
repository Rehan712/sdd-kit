#!/usr/bin/env bash
# Round-16 findings O-018 (reopened, blocking), O-022 (new, blocking, a regression of T030o47) and O-023 (new,
# minor, degraded) reproduced BEFORE any repair, 2026-10-08 (session 17). Pattern: r15-repro.sh. The cases are the
# reviewer's own (its transcript's cases1, cases2 and its carriage-return and timing runs), not retyped from prose.
# Read-only against the live worktree: every case runs in standalone copies built from the live enumeration, under
# the scratch directory, with a TMPDIR ending in `/` inside it. CUR is this tree (the four files as
# r16-edits/post-apply-2). PRE is CUR with r16-session.diff reversed (the four files as r15-edits/pre-apply), so a
# member that also holds on PRE predates T030o47. Each case runs through vf_reports directly on CUR and PRE in both
# passes (the prior-review manifest and the canonical round), and each mechanism end to end through spec-gate.sh
# round --complete and tally on CUR, under LANG=C and LANG=en_US.UTF-8 with every LC_* removed. marked 17.0.5 and
# markdown-it 12.3.2 (html enabled) render each case for the record; no verdict reads a rendering.
# Mechanisms (round 16): O-018, each T030o47 reading diverges from its production on the accepting side: tags HTML
# renders as a block outside condition 6 (pre, listing, xmp, plaintext, hgroup); the reading after a br taken from the
# raw suffix, outside its link context; code spans 6.1 does not form or forms where the reader does not (an escaped
# backslash before a backtick, an escaped first backtick of a run, a backtick inside a tag attribute or an autolink);
# a run ended by a form-feed or vertical-tab line, which 2.1 does not count as blank; a lone carriage return, which
# 2.1 counts as a line ending; a heading-shaped line inside an HTML block (manifest pass). O-022, vf_para ends a run
# at a # run of any length, an ATX heading has one to six. O-023, the run reader grows faster than cubically.
# The live status outside notes/verification/ is compared before and after.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
MARKED=/Users/babar/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/marked/lib/marked.esm.js
MDIT="/Applications/Cursor.app/Contents/Resources/app/node_modules/@vscode/vsce/node_modules/markdown-it"
X="$SP/r17-repro"; C="$X/cur"; P="$X/pre"; w="$X/work"
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
check 'CUR: the four files hash as r16-edits/post-apply-2' 4 "$(cd "$C" && shasum -a 256 -c "$WT/$r/r16-edits/post-apply-2.sha256" 2>/dev/null | grep -c ': OK$')"
for d in scripts templates tests; do cp -R "$C/$d" "$P/$d"; done
( cd "$P" && patch -R -p1 -s < "$WT/$r/r16-session.diff" ); check 'PRE: r16-session.diff reverses cleanly' 0 "$?"
check 'PRE: the four files hash as r15-edits/pre-apply' 4 "$(cd "$P" && shasum -a 256 -c "$WT/$r/r15-edits/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
printf '%s\n' "import { marked } from '$MARKED';" "import { readFileSync } from 'node:fs';" \
  "process.stdout.write(marked.parse(readFileSync(0, 'utf8')));" > "$X/render-marked.mjs"
printf '%s\n' "const md = require('$MDIT')({html: true});" "const fs = require('node:fs');" \
  "process.stdout.write(md.render(fs.readFileSync(0, 'utf8')));" > "$X/render-mdit.cjs"
render() {
  say "  | marked:      $(printf '%b' "$1" | ( cd "$X" && node render-marked.mjs ) 2>&1 | tr '\n\r' '~^' | LC_ALL=C cut -c1-300)"
  say "  | markdown-it: $(printf '%b' "$1" | ( cd "$X" && node render-mdit.cjs ) 2>&1 | tr '\n\r' '~^' | LC_ALL=C cut -c1-300)"
}

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

# tag|kind|body (printf %b). kind: o18 (round 16 O-018 member: seals in silence on CUR in both passes), o18m (the
# HTML-block heading: seals in the manifest pass; its canonical result is recorded), o22 (O-022: seals on CUR and is
# refused on PRE), control (refused on CUR by name). The bodies are the reviewer's cases1 and cases2 verbatim.
cat > "$X/cases" <<'EOF'
a1-pre|o18|Note<pre>Severity: data-loss</pre>
a1b-hgroup|o18|Note<hgroup>Severity: data-loss</hgroup>
a1c-listing|o18|Note<listing>Severity: data-loss</listing>
b2-xmp|o18|Note<xmp>Severity: data-loss</xmp>
b3-plaintext|o18|Note<plaintext>Severity: data-loss
a2-link-br|o18|[Note<br>](u)Severity: data-loss
b4-link-p|o18|[Note<p>](u)Severity: data-loss
a3-escbs-codespan|o18|[\\\\`]`](u)Severity: data-loss
a3b-escbt-run|o18|[\\``]`](u)Severity: data-loss
a4-tag-tick-br|o18|<i title="`"></i>Note<br>Severity: data-loss, tick: `.
b7-autolink-tick-br|o18|<http://a.b/`>Note<br>Severity: data-loss, tick: `.
a6-formfeed|o18|<b title="\n\f\nx">Severity: data-loss</b>
b6-vtab|o18|<b title="\n\v\nx">Severity: data-loss</b>
a7-lone-cr|o18|Note\r\rSeverity: data-loss
b1-htmlblock-heading|o18m|<div>\n<b title="\n# x">Severity: data-loss</b>\n</div>
a5-seven-hash|o22|<b title="\n####### x">Severity: data-loss</b>
b5-eight-hash-quote|o22|> <b title="\n> ######## y">Severity: data-loss</b>
c0-control-br|control|Note<br>Severity: data-loss
c1-canonical|control|- **Severity:** data-loss
EOF
sealed_pre=''
say '== direct, the manifest pass: G-042 at minor, a blank line, then the case; a CLEARED round 1 re-records G-042 at minor'
while IFS='|' read -r tag kind body; do
  say "-- $tag ($kind)"; render "- **Severity:** minor\n\n$body"
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-M-$tag-$kit"; mkdir -p "$sp/notes"
    mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n$body")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      t="M-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      case "$kind:$kit" in
        o18:cur|o18m:cur|o22:cur) check "M $tag cur $l: sealed in silence (rc 0)" 0 "$rc"; check "M $tag cur $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')";;
        o22:pre) check "M $tag pre $l: refused (rc 3)" 3 "$rc"; say "  | M $tag pre $l: $(first "$t")";;
        control:cur)
          check "M $tag cur $l: refused (rc 3)" 3 "$rc"; has "M $tag cur $l: by name" 'a second Severity line in finding G-042' "$w/$t.err";;
        *) say "  | M $tag $kit $l: rc=$rc $(first "$t")"
           [[ "$kit:$rc" != pre:0 ]] || sealed_pre+=" M:$tag:$l";;
      esac
    done
  done
done < "$X/cases"

say '== direct, the canonical pass: a CLEARED round 1 at 0 . 1 whose new G-050 carries the minor line, a blank line, then the case'
while IFS='|' read -r tag kind body; do
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-K-$tag-$kit"; mkdir -p "$sp/notes"
    round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$body")")"$'\n' > "$sp/notes/opponent.md"
    for l in C en_US.UTF-8; do
      t="K-$tag-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
      case "$kind:$kit" in
        o18:cur|o22:cur)
          check "K $tag cur $l: sealed in silence (rc 0)" 0 "$rc"; check "K $tag cur $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')"
          check "K $tag cur $l: G-050 recorded at minor" 1 "$(catalog "$t" | grep -c '^finding|1|G-050|dup-binding|new|none|minor|')";;
        o22:pre)
          check "K $tag pre $l: refused (rc 3)" 3 "$rc"
          if [[ "$tag" == *-quote ]]; then has "K $tag pre $l: by name" 'quoted content carries a Severity line' "$w/$t.err"
          else has "K $tag pre $l: by name" 'a Severity line this grammar cannot read in finding G-050' "$w/$t.err"; fi;;
        control:cur)
          check "K $tag cur $l: refused (rc 3)" 3 "$rc"
          if [[ "$tag" == c1-* ]]; then has "K $tag cur $l: by name" 'duplicate finding field' "$w/$t.err"
          else has "K $tag cur $l: by name" 'a Severity line this grammar cannot read in finding G-050' "$w/$t.err"; fi;;
        *) say "  | K $tag $kit $l: rc=$rc $(first "$t")"
           [[ "$kit:$rc" != pre:0 ]] || sealed_pre+=" K:$tag:$l";;
      esac
    done
  done
done < "$X/cases"
say "  | cases that also seal on PRE (the O-018 members, and the br control, a round-15 member, predate T030o47):${sealed_pre:- none}"

say '== direct, a lone carriage return inside a field-line value (a Where value), both passes'
wv='a.sh:1\r- **Severity:** data-loss'
render "- **Severity:** minor\n- **Where:** $wv"
for kit in cur pre; do
  k="$(kitof "$kit")"; sp="$X/spec-W-$kit"; mkdir -p "$sp/notes" "$sp/k/notes"
  mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n- **Where:** $wv")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new '- **Severity:** minor' "$(printf '%b' "$wv")")"$'\n' > "$sp/k/notes/opponent.md"
  for l in C en_US.UTF-8; do
    t="WM-$kit-$l"; rc="$(vfr "$t" "$k" "$l" "$sp/notes/opponent.md" "$sp")"
    t2="WK-$kit-$l"; rc2="$(vfr "$t2" "$k" "$l" "$sp/k/notes/opponent.md" "$sp/k")"
    if [[ "$kit" == cur ]]; then
      check "W manifest cur $l: sealed in silence (rc 0)" 0 "$rc"; check "W manifest cur $l: stderr empty" 0 "$(wc -c < "$w/$t.err" | tr -d ' ')"
    fi
    say "  | W $kit $l: manifest rc=$rc $(first "$t") | canonical rc=$rc2 $(first "$t2") G050-minor=$(catalog "$t2" | grep -c '^finding|1|G-050|dup-binding|new|none|minor|')"
  done
done

say '== E: end to end through spec-gate.sh on CUR; fixture, floor and reservation built under C each time'
awk '$0 != "t_run_all"' "$C/tests/test-spec-gate.sh" > "$C/tests/.r17-spec-gate.sh"
build() { # sandbox -> writes spec, cli and the reservation line to <sandbox>/paths, reserve.log
  ( cd "$C" && SANDBOX="$1" bash -c '
      . tests/.r17-spec-gate.sh || exit 9
      spec="$(make_verification_git_dir r17)" || exit 9
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
bodyof() { awk -F'|' -v t="$1" '$1 == t {print $3}' "$X/cases"; }
for l in C en_US.UTF-8; do
  # The manifest pass, one member per mechanism (block tag, break out of link context, code-span escape, a backtick
  # held by a tag, form feed, lone carriage return, O-022's seven marks), then the control.
  for tag in a1-pre a2-link-br a3-escbs-codespan a4-tag-tick-br a6-formfeed a7-lone-cr a5-seven-hash c0-control-br; do
    body="$(bodyof "$tag")"
    setup "$tag" "$l"; mani "$SPEC" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n$body")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' "${ID[@]}" > "$SB/returned.md"
    complete "$tag" "$l" "$SB/returned.md"
    if [[ "$tag" == c0-* ]]; then
      check "E $tag $l: refused (rc 3)" 3 "$(cat "$w/E-$tag-$l.rc")"; has "E $tag $l: by name" 'a second Severity line in finding G-042' "$w/E-$tag-$l.log"
    else
      check "E $tag $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-$tag-$l.rc")"
      has "E $tag $l: the completion line" 'round completed gate=opponent round=1 verdict=CLEARED' "$w/E-$tag-$l.log"
      has "E $tag $l: the tally counts the finding at minor" 'blocking=0 minor=1' "$w/E-$tag-$l.tally"
    fi
  done
  # The canonical pass end to end: a new G-050 at minor with a block tag, a lone carriage return and seven marks.
  for tag in a1-pre a7-lone-cr a5-seven-hash; do
    body="$(bodyof "$tag")"
    setup "k-$tag" "$l"
    round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$body")")"$'\n' "${ID[@]}" > "$SB/returned.md"
    complete "k-$tag" "$l" "$SB/returned.md"
    check "E k-$tag $l: CLEARED sealed (rc 0)" 0 "$(cat "$w/E-k-$tag-$l.rc")"
    has "E k-$tag $l: the tally counts G-050 at minor" 'blocking=0 minor=1' "$w/E-k-$tag-$l.tally"
  done
done

say '== O-023: the run reader timed on one canonical round whose Reproduced field has n sub-bullets (the reviewer perf.sh)'
perf() { # kit n -> seconds; rc in $w/perf-<label>-<n>.rc
  local k="$1" n="$2" label="$3" d="$X/perf-$3-$2" st en; mkdir -p "$d/notes"
  { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 1\n### What I attacked\nx\n### Finding G-050\n- **Class:** dup-binding\n- **Status:** new\n- **Prior:** none\n- **Severity:** minor\n- **Scenario:** a trigger\n- **Where:** a.sh:1\n- **Reproduced:** see below\n' "$SRC"
    for i in $(seq 1 "$n"); do printf '  - step %d ran `bash scripts/x.sh --flag %d` in [the copy](u) and <b>exited</b> 0 with output `ok`.\n' "$i" "$i"; done
    printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** x\n- **Class-wide fix:** y\n### Held up / follow-up tasks\nz\n<!-- gate-round-end: opponent:1 -->\n'; } > "$d/notes/opponent.md"
  st=$(date +%s); inloc C bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$k" "$d/notes/opponent.md" "$d/c.nul" "$d" < /dev/null > /dev/null 2> "$w/perf-$label-$n.err"
  echo $? > "$w/perf-$label-$n.rc"; en=$(date +%s); echo $((en - st))
}
t25="$(perf "$C" 25 cur)"; t50="$(perf "$C" 50 cur)"; t100="$(perf "$C" 100 cur)"
p100="$(perf "$P" 100 pre)"; p1000="$(perf "$P" 1000 pre)"
say "  | CUR: n=25 ${t25}s rc=$(cat "$w/perf-cur-25.rc"); n=50 ${t50}s rc=$(cat "$w/perf-cur-50.rc"); n=100 ${t100}s rc=$(cat "$w/perf-cur-100.rc")"
say "  | PRE: n=100 ${p100}s rc=$(cat "$w/perf-pre-100.rc"); n=1000 ${p1000}s rc=$(cat "$w/perf-pre-1000.rc")"
check 'O-023: CUR parses the 100-line run (rc 0)' 0 "$(cat "$w/perf-cur-100.rc")"
check 'O-023: CUR at n=100 takes over 4 times its n=50 time (faster than quadratic growth)' 1 "$(( t100 > 4 * t50 ? 1 : 0 ))"
check 'O-023: CUR at n=100 takes over 10 times PRE at n=1000' 1 "$(( t100 > 10 * (p1000 > 0 ? p1000 : 1) ? 1 : 0 ))"

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r17-repro failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
