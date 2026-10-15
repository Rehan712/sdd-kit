#!/usr/bin/env bash
# The rules for round 17's O-018, O-024 and O-023 and its minor MEASURED before adoption, 2026-10-09 (session 19). D
# is CUR (this tree, the four files as r18-edits/pre-apply, equal to r17-edits/post-apply-2) with
# r18-edits/kernel-1.pairs applied to the kernel and r18-edits/vc-1.pairs to the contract. Read-only against the live
# worktree: every kit is a standalone copy built from the live enumeration under the scratch directory, with a TMPDIR
# ending in `/` inside it, every case under LANG=C and LANG=en_US.UTF-8 with every LC_* removed, and the live status
# outside notes/verification/ compared before and after.
# The rules (the user's choices of 2026-10-09): O-018, narrow further: inside a finding, a `<` that may open an
# autolink (a digit or a symbol an email address may begin with) and a link destination, title or reference label
# that holds a backtick or does not end on its line, each outside every code span, are refused by name; O-024, narrow:
# inside a finding, a code fence that may be inside a list item (after indentation or a list marker) and a link
# reference definition (a bracket closed at once by `]:`, or not closed on its line) are refused by name; O-023, a
# candidate is settled once every reading holds its first word with no bracket pair or destination that opens at or
# before it left open; the minor, folded in: the narrowed check is judged after the line's own heading has opened or
# closed a finding.
# A: every case of r18-repro.sh and the derived siblings: each member that seals on CUR is refused on D in both
#    passes with its exact diagnostic; the controls stay refused on both kits; the heading cases move as the rule says.
# B1: positives parse on both kits; B2: the stated consequences (parse on CUR, refused by name on D; and the one
#    relaxation, a section heading that closes a finding); B3: the real prior-review manifest and every returned
#    round report read as a manifest parse on both kits, the manifest's catalog identical.
# C: the recorded history, CUR against D (tally, analyzer, AC coverage, every report catalog with its diagnostics and
#    exit, every extracted round block and every sealed digest of 003, the binding catalogs, the stage maps, the
#    semantic views, the waiver checks for rounds 17 and 18, the snapshot records) and the time 003's tally takes.
# E: O-023, the run reader timed on D, on the reviewer's runs; and the settled test's soundness probe.
# D: the full suite on D in its own copy, every failing assertion recorded.
# Pattern: r17-measure.sh. Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
X="$SP/r18-measure"; C="$X/cur"; D="$X/d"; w="$X/work"
rm -rf "$X"; mkdir -p "$C" "$w" "$X/tmp"
export TMPDIR="$X/tmp/"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
hasre() { if grep -q -E -- "$2" "$3"; then say "PASS $1"; else say "FAIL $1 (missing: $2)"; sed 's/^/  | /' "$3" | head -5; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
say "start $(date -u +%Y-%m-%dT%H:%M:%SZ); host: $(uname -sr); bash on PATH: $(bash --version | head -1); TMPDIR=$TMPDIR"

( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$C" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$C" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
check 'CUR: the four files hash as r18-edits/pre-apply' 4 "$(cd "$C" && shasum -a 256 -c "$WT/$r/r18-edits/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"
cp -R "$C" "$D"
perl "$WT/$r/r18-edits/lit.pl" "$D/scripts/verification-lib.sh" "$WT/$r/r18-edits/kernel-1.pairs" > "$w/apply.log" 2>&1
perl "$WT/$r/r18-edits/lit.pl" "$D/templates/verification-contract.md" "$WT/$r/r18-edits/vc-1.pairs" >> "$w/apply.log" 2>&1
check 'D: kernel-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 13 block(s) to .*verification-lib.sh$' "$w/apply.log")"
check 'D: vc-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 1 block(s) to .*verification-contract.md$' "$w/apply.log")"
check 'D: the kernel still parses' 0 "$(bash -n "$D/scripts/verification-lib.sh"; echo $?)"
check 'D: only the two candidate files differ from CUR' 'scripts/verification-lib.sh templates/verification-contract.md' "$(cd "$D" && git status --porcelain | sed 's/^ M //' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
finding() { # heading class status severity-lines [where]
  printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%s\n- **Scenario:** a recorded trigger\n- **Where:** %s\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read or refuse every record line\n' "$1" "$2" "$3" "$4" "${5:-scripts/run.sh:9}"
}
ftail() { # heading class status tail: every field but Severity, then the tail (the round-17 reviewer F)
  printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** bind\n%s' "$1" "$2" "$3" "$4"
}
round() { # n verdict blocking minor findings
  printf '## Round %s\n**Round:** %s\n**Timestamp:** 2026-09-06T12:00:0%sZ\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nFinding records read by both readers.\n%s### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:%s -->\n' \
    "$1" "$1" "$1" "$SRC" "$2" "$3" "$4" "$5" "$1"
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
judge() { # label tag cur-rc d-rc [d-diagnostic-regex]
  local l
  for l in C en_US.UTF-8; do
    check "$1 $l: CUR rc" "$3" "$(cat "$w/$2-cur-$l.rc")"
    check "$1 $l: D rc" "$4" "$(cat "$w/$2-d-$l.rc")"
    if [[ -n "${5:-}" ]]; then hasre "$1 $l: D says" "$5" "$w/$2-d-$l.err"; else check "$1 $l: D stderr empty" 0 "$(wc -c < "$w/$2-d-$l.err" | tr -d ' ')"; fi
    [[ "$3" != 0 ]] || check "$1 $l: CUR stderr empty" 0 "$(wc -c < "$w/$2-cur-$l.err" | tr -d ' ')"
  done
}
AU='an autolink outside a code span'
BT='a backtick inside a link destination, title or label'
OP='a link destination, title or label that does not end on its line'
FE='a code fence that may be inside a list item'
RD='a link reference definition'

say '== A1: O-018, the reviewer members and the derived siblings, both passes; each is refused on D by its own name'
# tag|kind|expected D diagnostic (a short name above)|body. kind: member (seals on CUR), control (refused on both).
cat > "$X/cases" <<'EOF'
r1-autolink-digit-br|member|AU|Note <1`@a.b><br>Severity: data-loss, tick: `.
r2-autolink-digit-pre|member|AU|Note <1`@a.b><pre>Severity: data-loss</pre>`
r3-autolink-underscore-p|member|AU|Note <_`@a.b><p>Severity: data-loss `
r4-destination-br|member|BT|[x](u`v)<br>Severity: data-loss, tick: `.
r5-title-br|member|BT|[x](u "`")<br>Severity: data-loss, tick: `.
r6-angle-destination-pre|member|BT|[x](<1`b>)<pre>Severity: data-loss</pre>`
d1-autolink-backtick-start|member|AU|Note <`a@b.c><br>Severity: data-loss, tick: `.
d2-autolink-plus|member|AU|Note <+1`@a.b><br>Severity: data-loss, tick: `.
d3-title-spans-lines|member|OP|[x](u '\ny`')<br>Severity: data-loss, tick: `.
d4-destination-on-next-line|member|OP|[x](\nu`v)<br>Severity: data-loss, tick: `.
d6-label-spans-lines|member|OP|[x][a\nb`]<br>Severity: data-loss, tick: `.
d7-autolink-dot|member|AU|Note <.x`@a.b><br>Severity: data-loss, tick: `.
c0-control-pre|control|raw|Note <pre>Severity: data-loss</pre>`
EOF
diag() { case "$1" in AU) printf '%s' "$AU";; BT) printf '%s' "$BT";; OP) printf '%s' "$OP";; FE) printf '%s' "$FE";; RD) printf '%s' "$RD";; raw) printf 'raw HTML outside a code span';; esac; }
while IFS='|' read -r tag kind want body; do
  sp="$X/spec-M-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n$body")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "M-$tag" "$sp"
  sk="$X/spec-K-$tag"; mkdir -p "$sk/notes"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$body")")"$'\n' > "$sk/notes/opponent.md"
  both "K-$tag" "$sk"
  if [[ "$kind" == member ]]; then
    judge "A1 M $tag" "M-$tag" 0 3 "$(diag "$want") in finding G-042"; judge "A1 K $tag" "K-$tag" 0 3 "$(diag "$want") in finding G-050"
  else
    judge "A1 M $tag (refused on both)" "M-$tag" 3 3 "$(diag "$want") in finding G-042"; judge "A1 K $tag (refused on both)" "K-$tag" 3 3 "$(diag "$want") in finding G-050"
  fi
done < "$X/cases"
# A backtick inside a full reference link's label, the definition outside the finding (both passes).
body='[x][a`b]<br>Severity: data-loss, tick: `.'
sp="$X/spec-M-d5"; mkdir -p "$sp/notes"
mani "$sp" "$(printf '%s\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n%s\n' '[a`b]: /u' "$body")"
round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
both M-d5 "$sp"; judge 'A1 M d5-label-tick' M-d5 0 3 "$BT in finding G-042"
sk="$X/spec-K-d5"; mkdir -p "$sk/notes"
{ printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 1\n### What I attacked\nFinding records read by both readers.\n\n%s\n\n' "$SRC" '[a`b]: /u'
  finding '### Finding G-050' dup-binding new "$(printf -- '- **Severity:** minor\n\n%s' "$body")"
  printf '### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n'; } > "$sk/notes/opponent.md"
both K-d5 "$sk"; judge 'A1 K d5-label-tick' K-d5 0 3 "$BT in finding G-050"

say '== A2: O-024, the reviewer cases and the derived siblings, both passes; each is refused on D by its own name'
cat > "$X/o24" <<'EOF'
A|RD|\n[a]: /u '\n    - **Severity:** minor\n    - x'\n
B|FE|- **Severity:** minor\n- ```\n  ### x\n- **Severity**: data-loss\n
CC|RD|\n[a]: /u '\n    - **Severity:** minor\n    - x'\n\n- ```\n  ### x\n- **Severity**: data-loss\n
X1-phase-swap|FE|- **Severity:** minor\n- note\n  ```\n```\n### x\n```\n- **Severity**: data-loss\n- y\n  ```\n
X2-four-space-fence|FE|- **Severity:** minor\n- note\n\n    ```\n  ### x\n    ```\n- **Severity**: data-loss\n
X3-definition-in-item|RD|- [a]: /u '\n      - **Severity:** minor\n      - x'\n
X4-label-spans-lines|RD|\n[a\nb]: /u '\n    - **Severity:** minor\n    - x'\n
X5-ordered-tilde-fence|FE|- **Severity:** minor\n1. ~~~\n   ### x\n- **Severity**: data-loss\n
X6-escaped-label|RD|\n[a\\]b]: /u '\n    - **Severity:** minor\n    - x'\n
EOF
while IFS='|' read -r tag want body; do
  sk="$X/spec-OK-$tag"; mkdir -p "$sk/notes"
  round 1 CLEARED 0 1 "$(ftail '### Finding G-050' tier-binding new "$(printf '%b' "$body")")"$'\n' > "$sk/notes/opponent.md"
  both "OK-$tag" "$sk"; judge "A2 K $tag" "OK-$tag" 0 3 "$(diag "$want") in finding G-050"
  check "A2 K $tag: CUR records G-050 at minor" 1 "$(tr '\0' '\n' < "$w/OK-$tag-cur-C.nul" | paste -d'|' - - - - - - - - - - - - | grep -c '^finding|1|G-050|tier-binding|new|none|minor|')"
  sp="$X/spec-OM-$tag"; mkdir -p "$sp/notes"
  case "$tag" in A|CC) mb="### Finding G-042\n- **Class:** tier-binding\n$body";; *) mb="### Finding G-042\n- **Class:** tier-binding\n$body";; esac
  mani "$sp" "$(printf '%b' "$mb")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "OM-$tag" "$sp"; judge "A2 M $tag" "OM-$tag" 0 3 "$(diag "$want") in finding G-042"
done < "$X/o24"

say '== A3: the minor, the narrowed check judged after the line'"'"'s own heading opens or closes a finding (canonical and manifest)'
rnd() { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** %s\n### What I attacked\nx\n%s### Held up / follow-up tasks\nx\n<!-- gate-round-end: opponent:1 -->\n' "$SRC" "$1" "$2"; }
fm() { finding "$1" dup-binding new '- **Severity:** minor'; }
mk() { local d="$X/spec-H-$1"; mkdir -p "$d/notes"; printf '%s' "$2" > "$d/notes/opponent.md"; both "H-$1" "$d"; }
mk first "$(rnd 1 "$(fm '### Finding G-050 <b>x</b>')"$'\n')"; judge 'A3 K the first Finding heading carries a b tag' H-first 0 3 'raw HTML outside a code span in finding G-050'
mk later "$(rnd 2 "$(fm '### Finding G-050')"$'\n'"$(fm '### Finding G-051 <b>x</b>')"$'\n')"; judge 'A3 K a later Finding heading carries a b tag: refused under its own ID' H-later 3 3 'raw HTML outside a code span in finding G-051'
mk closing "$(rnd 1 "$(fm '### Finding G-050')"$'\n### Notes <b>x</b>\nA note.\n')"; judge 'A3 K a section heading that closes the finding carries a b tag: parses on D (the stated relaxation)' H-closing 3 0
mk deeper "$(rnd 1 "$(fm '### Finding G-050')"$'\n#### Notes <b>x</b>\nA note.\n')"; judge 'A3 K a deeper heading inside the finding carries a b tag' H-deeper 3 3 'raw HTML outside a code span in finding G-050'
mk title "$(rnd 1 "$(fm '### Finding G-050')"$'\n# Opponent review <b>x</b>\n')"; judge 'A3 K a report title inside the finding carries a b tag' H-title 3 3 'raw HTML outside a code span in finding G-050'
mh() { local d="$X/spec-HM-$1"; mkdir -p "$d/notes"; mani "$d" "$2"; round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$d/notes/opponent.md"; both "HM-$1" "$d"; }
mh first $'### Finding G-042 <b>x</b>\n- **Class:** tier-binding\n- **Severity:** minor\n'; judge 'A3 M the first Finding heading carries a b tag' HM-first 0 3 'raw HTML outside a code span in finding G-042'
mh later $'### Finding G-041\n- **Class:** tier-binding\n- **Severity:** minor\n### Finding G-042 <b>x</b>\n- **Class:** tier-binding\n- **Severity:** minor\n'; judge 'A3 M a later Finding heading carries a b tag: refused under its own ID' HM-later 3 3 'raw HTML outside a code span in finding G-042'
mh closing $'### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n### Notes <b>x</b>\nA note.\n'; judge 'A3 M a heading that closes the finding carries a b tag: parses on D (the stated relaxation)' HM-closing 3 0
mh deeper $'### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n#### Notes <b>x</b>\nA note.\n'; judge 'A3 M a deeper heading inside the finding carries a b tag' HM-deeper 3 3 'raw HTML outside a code span in finding G-042'
check 'A3 M a later Finding heading: CUR names the previous finding' 1 "$(grep -c 'raw HTML outside a code span in finding G-041' "$w/HM-later-cur-C.err")"

say '== B1: positives that must parse on both kits'
cat > "$X/positives" <<'EOF'
wrapped-prose|A note that wraps\nonto the next line, then says Severity: as noted.
link-prose|See [the report](x) for the tier.
code-span-brackets|The `[x]` notation and `<b>` tags are prose.
code-span-tags|The `<br>`, `<div>`, `</p>` and `<!-- x -->` spellings are quoted as code.
code-span-in-link|See [`code`](x) and more.
ordered-list|1. first step\n2. second step reads the tier\n3. third
bullet-list|- first\n- second names the Severity of it
block-quote|> A quoted\n> remark about the Severity of it.
indented-continuation|A sentence that wraps\n    onto an indented line, no tier.
setext-heading|A remark\n===\nThe text under it.
four-backtick-fence|````text\nplain output\n````
escaped-backtick-prose|\\`a\\` Severity: as noted.
escaped-lt-prose|An escaped \\<b> stays text, and a < b comparison too.
code-span-word-before-label|- `foo` Severity: unchanged.
link-across-lines|See [the long\nreport](x) for it.
nbsp-only-line|A line\n\302\240\nafter a no-break space line.
crlf-lines|A line ending in CRLF\r\nand another\r
long-span-two-backticks|The ``a `b` c`` span holds backticks.
quoted-destination-member|The form `` [x](u`v)<br>Severity: data-loss, tick: `. `` stays quoted.
quoted-autolink-member|The form `` Note <1`@a.b><pre>Severity: data-loss</pre>` `` stays quoted.
link-title-then-code|See [the doc](u "a title") and `code` after it.
reference-links|See [the doc][ref] and [x][] here.
lt-space-number|It takes < 30 s and > 2 s.
column0-fence-info|```text\nplain\n```
tilde-fence|~~~\nplain\n~~~
checkbox-items|- [x] done\n- [ ] open
escaped-bracket-start|\\[a]: is not a definition here.
bracket-index|The index a[i] and b[j][k] stays prose.
wrapped-link-at-line-start|[a note that\nwraps](u) here.
wrapped-link-in-item|- [a link whose text\n  wraps](x) and more.
bracket-in-span-every-line|- a `[` here\n- a `[` there\n- a `]` too
EOF
while IFS='|' read -r tag body; do
  sp="$X/spec-PM-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n$body")"$'\n'
  round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding open '- **Severity:** wrong-result')"$'\n' > "$sp/notes/opponent.md"
  both "PM-$tag" "$sp"; judge "B1 manifest $tag parses" "PM-$tag" 0 0
  sk="$X/spec-PK-$tag"; mkdir -p "$sk/notes"
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** data-loss\n\n$body")")"$'\n' > "$sk/notes/opponent.md"
  both "PK-$tag" "$sk"; judge "B1 canonical $tag parses" "PK-$tag" 0 0
done < "$X/positives"
sp="$X/spec-PR"; mkdir -p "$sp/notes"
fr="$(printf '%b' '### Finding G-050\n- **Class:** dup-binding\n- **Status:** new\n- **Prior:** none\n- **Severity:** data-loss\n- **Scenario:** a long Scenario\n  that wraps over\n  several lines\n- **Where:** scripts/run.sh:9\n- **Reproduced:** each case below\n  - case one, refused\n  - case two, refused\n  - case three: a `[x]` and a `<b>tag</b>`\n  - case four, with Severity named mid-line\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read or refuse every record line')"
round 1 CHALLENGED 1 0 "$fr"$'\n' > "$sp/notes/opponent.md"
both PR "$sp"; judge 'B1 a long run of field lines and nested bullets with code spans parses' PR 0 0
sp="$X/spec-PO"; mkdir -p "$sp/notes"
round 1 CHALLENGED 1 0 "Prose before any finding with <b>markup</b>, a <1@x.example> address, [a](u\`v) and a definition:"$'\n\n'"[ref]: https://x.example"$'\n\n'"$(finding '### Finding G-050' dup-binding new '- **Severity:** data-loss')"$'\n' > "$sp/notes/opponent.md"
both PO "$sp"; judge 'B1 the narrowed constructs outside any finding parse (the narrowed grammar is the finding'"'"'s)' PO 0 0

say '== B2: the stated consequences inside a finding: parse on CUR, refused by name on D'
cat > "$X/consequences" <<'EOF'
lt-equals|AU|It holds when c <= d.
lt-digit|AU|It took <30 s.
indented-fence-in-item|FE|- step\n  ```\n  bash x\n  ```
marker-fence|FE|- ```\n  bash x\n- next
definition|RD|[a]: https://x.example
definition-label-spans-lines|RD|[a note\nb]: https://x.example
open-destination|OP|See [x](\nu) here.
EOF
while IFS='|' read -r tag want body; do
  sp="$X/spec-QM-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n$body")"$'\n'
  round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding open '- **Severity:** wrong-result')"$'\n' > "$sp/notes/opponent.md"
  both "QM-$tag" "$sp"; judge "B2 manifest $tag" "QM-$tag" 0 3 "$(diag "$want") in finding O-017"
  sk="$X/spec-QK-$tag"; mkdir -p "$sk/notes"
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** data-loss\n\n$body")")"$'\n' > "$sk/notes/opponent.md"
  both "QK-$tag" "$sk"; judge "B2 canonical $tag" "QK-$tag" 0 3 "$(diag "$want") in finding G-050"
done < "$X/consequences"

say '== B3: the real prior-review manifest and every returned round report read as a manifest'
sp="$X/spec-RR-real"; mkdir -p "$sp/notes/verification/reports"; cp "$C/$r/opponent-findings-2026-09-09.md" "$sp/notes/verification/reports/"
body=''; for f in O-001:return-envelope-parsing:wrong-result O-002:round-authorization-grammar:wrong-result O-003:live-control-semantic-validation:wrong-result O-004:gate-report-schema-validation:wrong-result O-005:config-interpolation-validation:wrong-result O-006:post-pr-followup-binding-schema:regression; do
  IFS=: read -r id cl sv <<< "$f"; body+="$(finding "### Finding $id" "$cl" open "- **Severity:** $sv")"$'\n'
done
round 1 CHALLENGED 6 0 "$body" > "$sp/notes/opponent.md"
both RR-real "$sp"; judge 'B3 the 2026-09-09 manifest parses' RR-real 0 0
check 'B3 the 2026-09-09 manifest: CUR and D catalogs identical' same "$(cmp -s "$w/RR-real-cur-C.nul" "$w/RR-real-d-C.nul" && echo same)"
nrep=0
for rep in "$C/$r"/opponent-round[0-9]*.md; do
  case "$rep" in *-brief*) continue;; esac
  nrep=$((nrep+1)); b="$(basename "$rep" .md)"; sp="$X/spec-RR-$b"; mkdir -p "$sp/notes/verification/reports"; cp "$rep" "$sp/notes/verification/reports/opponent-findings-review.md"
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "RR-$b" "$sp"; judge "B3 $b as a manifest parses" "RR-$b" 0 0
done
check 'B3 every returned file read (rounds 2 to 6 and 8 to 17, and the round-3 reconcile record, each once)' 16 "$nrep"

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
check 'C 003: eighteen sealed rounds compared (seventeen opponent, one reality-check)' 18 "$nsealed"
for n in 17 18; do
  for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"; ( cd "$K" && bash scripts/spec-gate.sh waiver "$s" opponent "$n" < /dev/null ) > "$w/H-w$n-$k.log" 2>&1; echo $? >> "$w/H-w$n-$k.log"; done
  check "C waiver check for round $n: CUR and D identical" same "$(cmp -s "$w/H-w$n-cur.log" "$w/H-w$n-d.log" && echo same)"
done
check 'C waiver round 17 reported completed (exit 0)' 0 "$(tail -1 "$w/H-w17-d.log")"
check 'C waiver round 18 refused (exit 4)' 4 "$(tail -1 "$w/H-w18-d.log")"
for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"
  ( cd "$K" && bash -c '. scripts/verification-lib.sh && vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$w/H-snap-$k.nul" ) > "$w/H-snap-$k.out" 2>&1
  tr '\0' '\n' < "$w/H-snap-$k.nul" | paste - - - - - - | sed "s#$K#KIT#g" | LC_ALL=C grep -v -F -e 'scripts/verification-lib.sh' -e 'templates/verification-contract.md' > "$w/H-snap-$k.tsv"
done
check 'C snapshot records outside the two candidate files identical (kit path normalized)' same "$(cmp -s "$w/H-snap-cur.tsv" "$w/H-snap-d.tsv" && echo same)"
say "  | snapshot: CUR $(head -c 16 "$w/H-snap-cur.out"), D $(head -c 16 "$w/H-snap-d.out"), records compared $(wc -l < "$w/H-snap-d.tsv" | tr -d ' ')"
for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"
  t0=$(date +%s); ( cd "$K" && bash scripts/spec-gate.sh tally "$s" < /dev/null ) > /dev/null 2>&1; say "  | timing: 003 tally on $k took $(( $(date +%s) - t0 )) s"
done

say '== E: O-023, the run reader timed on D (one canonical round), and the settled test'"'"'s soundness'
perf() { # kit label n variant -> seconds; rc in $w/perf-<label>-<variant>-<n>.rc
  local k="$1" label="$2" n="$3" v="$4" d="$X/perf-$2-$4-$3" st i; mkdir -p "$d/notes"
  { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 1\n### What I attacked\nx\n### Finding G-050\n- **Class:** tier-binding\n- **Status:** new\n- **Prior:** none\n- **Severity:** minor\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n' "$SRC"
    case "$v" in
      V) printf -- '- **Reproduced:** the opening bracket `[` is quoted in a code span here\n'
         for i in $(seq 0 $((n - 1))); do printf '  - step %d: ran `vf_reports x` against [the copy](https://x.example/%d) and saw *exit 0* with `rc=%d` here, fine\n' "$i" "$i" "$i"; done;;
      U) printf -- '- **Reproduced:** many lines\n'
         for i in $(seq 0 $((n - 1))); do printf '  - member %d: an opening bracket `[` written in a code span at column %d is literal and the copy stayed intact\n' "$i" "$i"; done;;
      html) printf -- '- **Reproduced:** see below\n'
         for i in $(seq 1 "$n"); do printf '  - step %d ran `bash scripts/x.sh --flag %d` in [the copy](u) and <b>exited</b> 0 with output `ok`.\n' "$i" "$i"; done;;
    esac
    printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed\n- **Class-wide fix:** bind\n### Held up / follow-up tasks\nx\n<!-- gate-round-end: opponent:1 -->\n'; } > "$d/notes/opponent.md"
  st=$(date +%s); inloc C bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$k" "$d/notes/opponent.md" "$d/c.nul" "$d" < /dev/null > /dev/null 2> "$w/perf-$label-$v-$n.err"
  echo $? > "$w/perf-$label-$v-$n.rc"; echo $(( $(date +%s) - st ))
}
for n in 200 400; do t="$(perf "$D" d "$n" V)"; say "  | D V n=$n: ${t}s rc=$(cat "$w/perf-d-V-$n.rc")"; eval "dv$n=$t"; done
for n in 100 200; do t="$(perf "$D" d "$n" U)"; say "  | D U n=$n: ${t}s rc=$(cat "$w/perf-d-U-$n.rc")"; eval "du$n=$t"; done
t="$(perf "$D" d 200 html)"; say "  | D html n=200: ${t}s rc=$(cat "$w/perf-d-html-200.rc") $(head -1 "$w/perf-d-html-200.err" | sed 's/.*opponent.md:[0-9]*: //' | LC_ALL=C cut -c1-90)"; dh200="$t"
t="$(perf "$C" cur 100 U)"; say "  | CUR U n=100: ${t}s rc=$(cat "$w/perf-cur-U-100.rc")"
check 'E D: the 400-line V run parses (rc 0)' 0 "$(cat "$w/perf-d-V-400.rc")"
check 'E D: the 200-line U run parses (rc 0)' 0 "$(cat "$w/perf-d-U-200.rc")"
check 'E D: the 200-line run with tags outside code spans is refused (rc 3)' 3 "$(cat "$w/perf-d-html-200.rc")"
check 'E D: the 400-line V run takes under 30 s' 1 "$(( dv400 < 30 ? 1 : 0 ))"
check 'E D: the 200-line U run takes under 30 s' 1 "$(( du200 < 30 ? 1 : 0 ))"
check 'E D: doubling the V run from 200 to 400 lines at most quadruples its time (plus 2 s)' 1 "$(( dv400 <= 4 * dv200 + 2 ? 1 : 0 ))"
# Soundness: a candidate whose rendered reading's first word a later line can take away is kept. A named reference
# and an image opened before the first rendered word, completed on the next line before a tier (the round-17 M3 as
# written settles it on its as-written head `&nbsp`), and an ordered number before an image.
cat > "$X/sound" <<'EOF'
entity-image|&nbsp;![q\n](u)Severity: data-loss
number-image|1. ![q\n](u)Severity: data-loss
entity-link-dest|&amp; [](u\n)Severity: data-loss
EOF
while IFS='|' read -r tag body; do
  sp="$X/spec-SM-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n$body")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "SM-$tag" "$sp"; judge "E sound M $tag (refused on both)" "SM-$tag" 3 3 'a second Severity line in finding G-042|a Severity line this grammar cannot read|a link destination, title or label that does not end on its line'
  sk="$X/spec-SK-$tag"; mkdir -p "$sk/notes"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$body")")"$'\n' > "$sk/notes/opponent.md"
  both "SK-$tag" "$sk"; judge "E sound K $tag (refused on both)" "SK-$tag" 3 3 'a Severity line this grammar cannot read in finding G-050|a link destination, title or label that does not end on its line'
done < "$X/sound"

say '== D: the full suite on D in its own copy (TMPDIR ending in /), failures read assertion by assertion'
DS="$X/dsuite"; cp -R "$D" "$DS"; mkdir -p "$X/tmp-suite"
( cd "$DS" && TMPDIR="$X/tmp-suite/" bash tests/run.sh < /dev/null ) > "$w/suite.log" 2>&1; echo $? > "$w/suite.rc"
say "  | suite rc=$(cat "$w/suite.rc"); per-suite: $(grep -E '^  -- [0-9]+/[0-9]+ passed' "$w/suite.log" | tr '\n' ' ')"
grep -E '^  FAIL ' "$w/suite.log" | sed 's/^/  | /'
grep -E 'assert|expected' "$w/suite.log" | LC_ALL=C cut -c1-230 | sed 's/^/  |   /' | head -80
cp "$w/suite.log" "$WT/$r/r18-measure-suite.log"
say "  | suite exit recorded: $(cat "$w/suite.rc")"

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r18-measure failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
