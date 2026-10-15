#!/usr/bin/env bash
# Round-18 findings O-018 (reopened, blocking), O-025 (new, blocking) and O-023 (reopened, minor, degraded) reproduced
# BEFORE any repair, 2026-10-14 (session 21). Pattern: r18-repro.sh. The cases are the reviewer's own, taken from its
# transcript (its members.sh rows, its opp18-e2e.sh rows, its settled.sh texts and its timed link-led run), not
# retyped from prose; a reference member carries its definition outside the finding, as the reviewer's end-to-end
# rows do, since no renderer forms the link without it.
# Read-only against the live worktree: every case runs in standalone copies built from the live enumeration, under
# the scratch directory, with a TMPDIR ending in `/` inside it. CUR is this tree (the four files as
# r18-edits/post-apply-3). PRE is CUR with r18-session.diff reversed (the four files as r18-edits/pre-apply), so a
# member that also holds on PRE predates T030o51 to T030o53. Each case runs through vf_reports directly on CUR and PRE
# in both passes (the prior-review manifest and the canonical round), and each mechanism end to end through
# spec-gate.sh round --complete and tally on CUR, under LANG=C and LANG=en_US.UTF-8 with every LC_* removed.
# marked 17.0.5 and markdown-it 12.3.2 (html enabled) render each case for the record; no verdict reads a rendering.
# Mechanisms (round 18): O-018, a backtick inside a construct marked binds before any code span (a GFM extended
# autolink; a shortcut, collapsed or image reference whose label is defined outside the finding) pairs, to the gate,
# with a later backtick into a code span, so a live tag after it reads as inside a span; O-025, a GFM table inside a
# finding renders a data-loss tier as the first text of a cell, and the label reader never splits a line at a pipe;
# O-023, a bracket that opens before a line's first word and closes after it leaves the candidate unsettled, so a run
# of link-led sub-bullets re-reads it on every line.
# The live status outside notes/verification/ is compared before and after.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
MARKED=/Users/babar/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/marked/lib/marked.esm.js
MDIT="/Applications/Cursor.app/Contents/Resources/app/node_modules/@vscode/vsce/node_modules/markdown-it"
X="$SP/r19-repro"; C="$X/cur"; P="$X/pre"; w="$X/work"
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
check 'CUR: the four files hash as r18-edits/post-apply-3' 4 "$(cd "$C" && shasum -a 256 -c "$WT/$r/r18-edits/post-apply-3.sha256" 2>/dev/null | grep -c ': OK$')"
for d in scripts templates tests; do cp -R "$C/$d" "$P/$d"; done
( cd "$P" && patch -R -p1 -s < "$WT/$r/r18-session.diff" ); check 'PRE: r18-session.diff reverses cleanly' 0 "$?"
check 'PRE: the four files hash as r18-edits/pre-apply' 4 "$(cd "$P" && shasum -a 256 -c "$WT/$r/r18-edits/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"

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
round() { # n verdict blocking minor findings [timestamp source floor]
  printf '## Round %s\n**Round:** %s\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nFinding records read by both readers.\n%s### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:%s -->\n' \
    "$1" "$1" "${6:-2026-09-06T12:00:0${1}Z}" "${7:-$SRC}" "${8:-FLOOR-fixture}" "$2" "$3" "$4" "$5" "$1"
}
withdef() { # definition: copy stdin, the definition (if any) standing alone after the attacked line, outside every finding
  DEF="$1" awk '{print} $0 == "Finding records read by both readers." && ENVIRON["DEF"] != "" {printf "\n%s\n\n", ENVIRON["DEF"]}'
}
mani() { mkdir -p "$1/notes/verification/reports"; printf '# Prior review\n\n%s' "$2" > "$1/notes/verification/reports/opponent-findings-review.md"; }
manibody() { # definition body -> the manifest text (the definition, if any, before the finding)
  if [[ "$1" != - ]]; then printf '%s\n\n' "$1"; fi
  printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n$2"
}
vfr() { # tag kit locale report spec -> prints rc; stderr in $w/<tag>.err, catalog in $w/<tag>.nul
  inloc "$3" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$2" "$4" "$w/$1.nul" "$5" < /dev/null > "$w/$1.out" 2> "$w/$1.err"
  echo $? > "$w/$1.rc"; cat "$w/$1.rc"
}
catalog() { tr '\0' '\n' < "$w/$1.nul" | paste -d'|' - - - - - - - - - - - -; }
first() { head -1 "$w/$1.err" | sed 's#.*/opponent[^:]*:#line #' | LC_ALL=C cut -c1-170; }
kitof() { if [[ "$1" == pre ]]; then printf '%s' "$P"; else printf '%s' "$C"; fi; }
sealed() { # label tag passname: rc 0, stderr empty, and in the canonical pass the finding recorded at minor
  check "$1: sealed in silence (rc 0)" 0 "$(cat "$w/$2.rc")"; check "$1: stderr empty" 0 "$(wc -c < "$w/$2.err" | tr -d ' ')"
  if [[ "$3" == K ]]; then check "$1: G-050 recorded at minor" 1 "$(catalog "$2" | grep -c '^finding|1|G-050|dup-binding|new|none|minor|')"; fi
}

say '== direct: G-042 at minor (manifest) or a new G-050 at minor (canonical), a blank line, then the case'
# kind: o18 and o25, reported members (seal in silence on CUR in both passes); control=<diagnostic> (refused on CUR,
# the canonical diagnostic asserted by name, the manifest one recorded); positive (parses on CUR in both passes).
# Fields are tab-separated (the table cases hold pipes): tag, kind, definition outside the finding or -, body.
printf '%s\t%s\t%s\t%s\n' \
  u1-url-br o18 - 'Note http://a.b/`<br>Severity: data-loss, tick: `.' \
  u2-https-br o18 - 'Note https://a.b/x`<br>Severity: data-loss, tick: `.' \
  u3-www-br o18 - 'Note www.a.b/x`<br>Severity: data-loss, tick: `.' \
  u4-ftp-pre o18 - 'Note ftp://a.b/`<pre>Severity: data-loss</pre>`' \
  f1-shortcut-br o18 '[a`b]: /u' 'Note [a`b]<br>Severity: data-loss, tick: `.' \
  f2-collapsed-br o18 '[a`b]: /u' 'Note [a`b][]<br>Severity: data-loss, tick: `.' \
  f3-image-br o18 '[a`b]: /u' 'Note ![a`b]<br>Severity: data-loss, tick: `.' \
  t1-table o25 - '| Step | Result |\n| - | - |\n| ran | **Severity:** data-loss |' \
  t2-table-item o25 - '- Steps:\n\n  | Step | Result |\n  |:--|--:|\n  | ran | **Severity:** data-loss |' \
  c0-br 'control=raw HTML outside a code span in finding G-050' - 'Note <br>Severity: data-loss.' \
  c1-one-column 'control=a Severity line this grammar cannot read in finding G-050' - '| Result |\n| - |\n| **Severity:** data-loss |' \
  c2-td 'control=raw HTML outside a code span in finding G-050' - 'Note <td>**Severity:** data-loss</td>' \
  p1-url positive - 'See https://x.example/a and `code` here.' \
  p2-link-code positive - 'See [the `x` doc](u) and `code`.' \
  p3-ref positive - 'See [the doc][ref] and [x][] here.' \
  p4-pipe positive - 'It reads a | b and `c | d` here.' > "$X/cases"
sealed_pre=''
while IFS=$'\t' read -r tag kind def body; do
  say "-- $tag ($kind)"
  if [[ "$def" != - ]]; then render "$def\n\n- **Severity:** minor\n\n$body"; else render "- **Severity:** minor\n\n$body"; fi
  for kit in cur pre; do
    k="$(kitof "$kit")"; sp="$X/spec-M-$tag-$kit"; mkdir -p "$sp/notes"
    mani "$sp" "$(manibody "$def" "$body")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
    sk="$X/spec-K-$tag-$kit"; mkdir -p "$sk/notes"
    round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$body")")"$'\n' | withdef "${def#-}" > "$sk/notes/opponent.md"
    for l in C en_US.UTF-8; do
      vfr "M-$tag-$kit-$l" "$k" "$l" "$sp/notes/opponent.md" "$sp" > /dev/null
      vfr "K-$tag-$kit-$l" "$k" "$l" "$sk/notes/opponent.md" "$sk" > /dev/null
      if [[ "$kit" == cur ]]; then
        case "$kind" in
          o18|o25) sealed "${kind/o/O-0} M $tag cur $l" "M-$tag-$kit-$l" M; sealed "${kind/o/O-0} K $tag cur $l" "K-$tag-$kit-$l" K;;
          control=*)
            check "control M $tag cur $l: refused (rc 3)" 3 "$(cat "$w/M-$tag-$kit-$l.rc")"; say "  | manifest: $(first "M-$tag-$kit-$l")"
            check "control K $tag cur $l: refused (rc 3)" 3 "$(cat "$w/K-$tag-$kit-$l.rc")"; has "control K $tag cur $l: by name" "${kind#control=}" "$w/K-$tag-$kit-$l.err";;
          positive)
            check "positive M $tag cur $l: parses (rc 0)" 0 "$(cat "$w/M-$tag-$kit-$l.rc")"
            check "positive K $tag cur $l: parses (rc 0)" 0 "$(cat "$w/K-$tag-$kit-$l.rc")";;
        esac
      else
        say "  | $tag pre $l: manifest rc=$(cat "$w/M-$tag-$kit-$l.rc") $(first "M-$tag-$kit-$l") | canonical rc=$(cat "$w/K-$tag-$kit-$l.rc") $(first "K-$tag-$kit-$l")"
        case "$kind" in o18|o25) [[ "$(cat "$w/M-$tag-$kit-$l.rc") $(cat "$w/K-$tag-$kit-$l.rc")" != '0 0' ]] || sealed_pre+=" $tag:$l";; esac
      fi
    done
  done
done < "$X/cases"
say "  | members that also seal on PRE in both passes:${sealed_pre:- none}"

say '== E: end to end through spec-gate.sh on CUR; fixture, floor and reservation built under C each time'
awk '$0 != "t_run_all"' "$C/tests/test-spec-gate.sh" > "$C/tests/.r19-spec-gate.sh"
build() { # sandbox -> writes spec, cli and the reservation line to <sandbox>/paths, reserve.log
  ( cd "$C" && SANDBOX="$1" bash -c '
      . tests/.r19-spec-gate.sh || exit 9
      spec="$(make_verification_git_dir r19)" || exit 9
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
colof() { awk -F'\t' -v t="$1" -v c="$2" '$1 == t {print $c}' "$X/cases"; }
for l in C en_US.UTF-8; do
  # One member per mechanism in each pass: the URL literal and the shortcut reference (O-018), the table (O-025).
  for tag in u1-url-br f1-shortcut-br t1-table; do
    def="$(colof "$tag" 3)"; body="$(colof "$tag" 4)"
    setup "m-$tag" "$l"; mani "$SPEC" "$(manibody "$def" "$body")"$'\n'
    round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' "${ID[@]}" > "$SB/returned.md"
    complete "m-$tag" "$l" "$SB/returned.md"; sealed_e "m-$tag" "$l"
    setup "k-$tag" "$l"
    round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$body")")"$'\n' "${ID[@]}" | withdef "${def#-}" > "$SB/returned.md"
    complete "k-$tag" "$l" "$SB/returned.md"; sealed_e "k-$tag" "$l"
  done
  setup k-c0 "$l"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$(colof c0-br 4)")")"$'\n' "${ID[@]}" > "$SB/returned.md"
  complete k-c0 "$l" "$SB/returned.md"
  check "E k-c0 $l: the control is refused (rc 3)" 3 "$(cat "$w/E-k-c0-$l.rc")"; has "E k-c0 $l: by name" 'raw HTML outside a code span in finding G-050' "$w/E-k-c0-$l.log"
done

say '== O-023: vf_settled on the reviewer texts, CUR and PRE (1 settles the candidate)'
printf '%s\n' 'cd "$1" && . scripts/verification-lib.sh || exit 9' \
  'LC_ALL=C awk "$_VF_AWK_WS$_VF_AWK_LABEL"'"'"' BEGIN { printf "%s", vf_settled(ENVIRON["T"]) }'"'" > "$X/settled.sh"
st() { T="$2" bash "$X/settled.sh" "$(kitof "$1")" 2>&1; }
for t in '- [the log](x) shows exit 0' '  - ![badge](y.png) step 3' '1. [step](u) ran' '- `[y]` holds'; do
  check "O-023 settled, link-led text, CUR leaves it unsettled: $t" 0 "$(st cur "$t")"
  check "O-023 settled, link-led text, PRE settled it: $t" 1 "$(st pre "$t")"
done
t='- **Reproduced:** the opening bracket `[` is quoted'
check "O-023 settled, round-17 shape, CUR settles it: $t" 1 "$(st cur "$t")"
check "O-023 settled, round-17 shape, PRE left it unsettled: $t" 0 "$(st pre "$t")"

say '== O-023: one canonical round, timed (the reviewer link-led run: T030o53 timing shape with its link moved to the front)'
perf() { # kit n -> seconds; rc in $w/perf-<kit>-<n>.rc
  local kit="$1" n="$2" d="$X/perf-$1-$2" t0 t1 i; mkdir -p "$d/notes"
  { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 1\n### What I attacked\nx\n### Finding G-050\n- **Class:** tier-binding\n- **Status:** new\n- **Prior:** none\n- **Severity:** minor\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** steps follow\n' "$SRC"
    for i in $(seq 0 $((n - 1))); do printf '  - [step %d](https://x.example/%d) ran `vf_reports x` and saw *exit 0* with `rc=%d` here, fine\n' "$i" "$i" "$i"; done
    printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed\n- **Class-wide fix:** bind\n### Held up / follow-up tasks\nx\n<!-- gate-round-end: opponent:1 -->\n'; } > "$d/notes/opponent.md"
  t0=$(perl -MTime::HiRes=time -e 'printf "%.2f", time')
  inloc C bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$(kitof "$kit")" "$d/notes/opponent.md" "$d/c.nul" "$d" < /dev/null > /dev/null 2> "$w/perf-$kit-$n.err"
  echo $? > "$w/perf-$kit-$n.rc"; t1=$(perl -MTime::HiRes=time -e 'printf "%.2f", time')
  awk -v a="$t0" -v b="$t1" 'BEGIN {printf "%.2f", b - a}'
}
c50="$(perf cur 50)"; c100="$(perf cur 100)"; p100="$(perf pre 100)"; p400="$(perf pre 400)"
say "  | CUR: n=50 ${c50}s rc=$(cat "$w/perf-cur-50.rc"); n=100 ${c100}s rc=$(cat "$w/perf-cur-100.rc")"
say "  | PRE: n=100 ${p100}s rc=$(cat "$w/perf-pre-100.rc"); n=400 ${p400}s rc=$(cat "$w/perf-pre-400.rc")"
check 'O-023: CUR parses the 100-line run (rc 0)' 0 "$(cat "$w/perf-cur-100.rc")"
check 'O-023: PRE parses the 400-line run (rc 0)' 0 "$(cat "$w/perf-pre-400.rc")"
check 'O-023: doubling the CUR run from 50 to 100 lines more than quadruples its time' 1 "$(awk -v a="$c50" -v b="$c100" 'BEGIN {x = (b > 4 * a) ? 1 : 0; print x}')"
check 'O-023: CUR at 100 lines is slower than PRE at 400' 1 "$(awk -v a="$p400" -v b="$c100" 'BEGIN {x = (b > a) ? 1 : 0; print x}')"

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r19-repro failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
