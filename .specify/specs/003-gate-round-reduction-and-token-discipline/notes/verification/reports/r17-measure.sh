#!/usr/bin/env bash
# The rules for round 16's O-018, O-022 and O-023 MEASURED before adoption, 2026-10-08 (session 17). D is CUR (this
# tree, the four files as r16-edits/post-apply-2) with r17-edits/kernel-1.pairs applied to the kernel and
# r17-edits/vc-1.pairs to the contract. Read-only against the live worktree: every kit is a standalone copy built from
# the live enumeration under the scratch directory, with a TMPDIR ending in `/` inside it, every case under LANG=C and
# LANG=en_US.UTF-8 with every LC_* removed, and the live status outside notes/verification/ compared before and after.
# The rules (the user's decision of 2026-10-08): O-018, the grammar is narrowed inside a finding (raw HTML or an
# autolink outside every code span, a form feed or vertical tab, a carriage return inside a line are refused by name),
# code spans are placed by CommonMark 6.1 read left to right with 2.4 escapes, and a run never ends at a line the
# tracker calls fenced; O-022, a run ends at an ATX heading of one to six marks only, and at a blank line of spaces
# and tabs; O-023, a candidate whose text is settled is dropped.
# A: every case of r17-repro.sh, the fence sibling the invoker derived, and siblings of the narrowed rule: each member
#    that seals on CUR is refused by name on D in both passes; the controls stay refused on both kits.
# B1: positives parse on both kits; B2: positives of T030o47 that carry raw HTML inside a finding, refused on D by
#    the narrowed grammar (the recorded consequence); B3: the real prior-review manifest and every returned round
#    report read as a manifest parse on both kits, the manifest's catalog identical.
# C: the recorded history, CUR against D (tally, analyzer, AC coverage, every report catalog with its diagnostics and
#    exit, every extracted round block and every sealed digest of 003, the binding catalogs, the stage maps, the
#    semantic views, the waiver checks for rounds 16 and 17, the snapshot records) and the time 003's tally takes.
# E: O-023, the run reader timed on D and CUR, on runs a finding may hold and on the reviewer's run.
# D: the full suite on D in its own copy, every failing assertion recorded.
# Pattern: r15-measure.sh. Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
X="$SP/r17-measure"; C="$X/cur"; D="$X/d"; w="$X/work"
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
check 'CUR: the four files hash as r17-edits/pre-apply' 4 "$(cd "$C" && shasum -a 256 -c "$WT/$r/r17-edits/pre-apply.sha256" 2>/dev/null | grep -c ': OK$')"
cp -R "$C" "$D"
perl "$WT/$r/r17-edits/lit.pl" "$D/scripts/verification-lib.sh" "$WT/$r/r17-edits/kernel-1.pairs" > "$w/apply.log" 2>&1
perl "$WT/$r/r17-edits/lit.pl" "$D/templates/verification-contract.md" "$WT/$r/r17-edits/vc-1.pairs" >> "$w/apply.log" 2>&1
check 'D: kernel-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 6 block(s) to .*verification-lib.sh$' "$w/apply.log")"
check 'D: vc-1.pairs applied, each block exactly once' 1 "$(grep -c '^applied 1 block(s) to .*verification-contract.md$' "$w/apply.log")"
check 'D: the kernel still parses' 0 "$(bash -n "$D/scripts/verification-lib.sh"; echo $?)"
check 'D: only the two candidate files differ from CUR' 'scripts/verification-lib.sh templates/verification-contract.md' "$(cd "$D" && git status --porcelain | sed 's/^ M //' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
finding() { # heading class status severity-lines [where]
  printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%s\n- **Scenario:** a recorded trigger\n- **Where:** %s\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read or refuse every record line\n' "$1" "$2" "$3" "$4" "${5:-scripts/run.sh:9}"
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
NM='(raw HTML outside a code span|a form feed or vertical tab|a carriage return inside a line) in finding'
MD="a second Severity line in finding G-042|a Severity line this grammar cannot read|quoted content carries a Severity line|$NM G-042"
KD="a Severity line this grammar cannot read in finding G-050|quoted content carries a Severity line|$NM G-050"

say '== A: the cases of r17-repro.sh and the derived siblings, both passes; each member is refused by name on D'
# kind: member (seals on CUR, refused on D), refused (refused on both kits).
cat > "$X/cases" <<'EOF'
a1-pre|member|Note<pre>Severity: data-loss</pre>
a1b-hgroup|member|Note<hgroup>Severity: data-loss</hgroup>
a1c-listing|member|Note<listing>Severity: data-loss</listing>
b2-xmp|member|Note<xmp>Severity: data-loss</xmp>
b3-plaintext|member|Note<plaintext>Severity: data-loss
a2-link-br|member|[Note<br>](u)Severity: data-loss
b4-link-p|member|[Note<p>](u)Severity: data-loss
a3-escbs-codespan|member|[\\\\`]`](u)Severity: data-loss
a3b-escbt-run|member|[\\``]`](u)Severity: data-loss
a4-tag-tick-br|member|<i title="`"></i>Note<br>Severity: data-loss, tick: `.
b7-autolink-tick-br|member|<http://a.b/`>Note<br>Severity: data-loss, tick: `.
a6-formfeed|member|<b title="\n\f\nx">Severity: data-loss</b>
b6-vtab|member|<b title="\n\v\nx">Severity: data-loss</b>
a7-lone-cr|member|Note\r\rSeverity: data-loss
b1-htmlblock-heading|member|<div>\n<b title="\n# x">Severity: data-loss</b>\n</div>
a5-seven-hash|member|<b title="\n####### x">Severity: data-loss</b>
b5-eight-hash-quote|member|> <b title="\n> ######## y">Severity: data-loss</b>
o22-image-seven-hash|member|![x\n####### y](u)Severity: data-loss
o22-image-eight-hash-quote|member|> ![x\n> ######## y](u)Severity: data-loss
f1-bogus-fence-image|member|\140\140\140a\140b\n\n![x\ny](u)Severity: data-loss\n\140\140\140
n1-table-tag|member|Note<table>Severity: data-loss</table>
n2-custom-tag|member|Note<x-note>Severity: data-loss</x-note>
n3-upper-pre|member|Note<PRE>Severity: data-loss</PRE>
n4-autolink-before|member|<https://x.example/a>Severity: data-loss
n5-ff-inside-text|member|Note\fSeverity: data-loss
n6-vt-inside-text|member|Note\vSeverity: data-loss
n7-escaped-backtick-tag|member|\\`<br>Severity: data-loss
c0-control-br|refused|Note<br>Severity: data-loss
c1-canonical|refused|- **Severity:** data-loss
c2-tag-alone|refused|<b\ntitle="x">Severity: data-loss</b>
EOF
while IFS='|' read -r tag kind body; do
  sp="$X/spec-M-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n$body")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "M-$tag" "$sp"
  sk="$X/spec-K-$tag"; mkdir -p "$sk/notes"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** minor\n\n$body")")"$'\n' > "$sk/notes/opponent.md"
  both "K-$tag" "$sk"
  if [[ "$kind" == member ]]; then
    for p in M K; do
      for l in C en_US.UTF-8; do say "  | A $p $tag $l: CUR rc=$(cat "$w/$p-$tag-cur-$l.rc") $(head -1 "$w/$p-$tag-cur-$l.err" | LC_ALL=C cut -c1-110)"; done
    done
    judge "A M $tag" "M-$tag" "$(cat "$w/M-$tag-cur-C.rc")" 3 "$MD"; judge "A K $tag" "K-$tag" "$(cat "$w/K-$tag-cur-C.rc")" 3 "$KD"
  else
    judge "A M $tag (refused on both)" "M-$tag" 3 3 "$MD"; judge "A K $tag (refused on both)" "K-$tag" 3 3 "$KD|duplicate finding field"
  fi
done < "$X/cases"
say '  the cases that seal on CUR (each refused on D by the checks above):'
for p in M K; do say "  | $p: $(for f in "$w/$p-"*"-cur-C.rc"; do b="${f##*/}"; b="${b#$p-}"; b="${b%-cur-C.rc}"; [[ "$(cat "$f")" == 0 ]] && printf '%s ' "$b"; done)"; done
wv='a.sh:1\r- **Severity:** data-loss'
sp="$X/spec-W"; mkdir -p "$sp/notes" "$sp/k/notes"
mani "$sp" "$(printf '%b' "### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n- **Where:** $wv")"$'\n'
round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new '- **Severity:** minor' "$(printf '%b' "$wv")")"$'\n' > "$sp/k/notes/opponent.md"
both W-manifest "$sp"; judge 'A W a carriage return in the Where value, manifest pass' W-manifest 0 3 'a carriage return inside a line in finding G-042'
both W-canonical "$sp/k"; judge 'A W a carriage return in the Where value, canonical pass' W-canonical "$(cat "$w/W-canonical-cur-C.rc")" 3 'a carriage return inside a line in finding G-050'

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
round 1 CHALLENGED 1 0 "Prose before any finding with <b>markup</b> and a <br> stays outside the narrowed grammar."$'\n'"$(finding '### Finding G-050' dup-binding new '- **Severity:** data-loss')"$'\n' > "$sp/notes/opponent.md"
both PO "$sp"; judge 'B1 raw HTML outside any finding parses (the narrowed grammar is the finding'"'"'s)' PO 0 0

say '== B2: the recorded consequence, positives of T030o47 that carry raw HTML inside a finding: parse on CUR, refused by name on D'
cat > "$X/consequences" <<'EOF'
br-prose|Line one<br>line two names no tier.
div-prose|A note <div>with a block tag</div> and no tier.
details-block|<details>\nx\n</details>
span-in-prose|Note <span>Severity: as noted</span> stays prose.
blank-line-ends-run|<b title="a\n\n- b">Severity: data-loss</b>
quoted-heading-then-attribute-line|> #### <abbr\n> title="t">Severity: data-loss</abbr>
real-fence-image|\140\140\140text\n\n![x\ny](u)Severity: data-loss\n\140\140\140
multiline-span-tag|A span `opens here\nand <b> closes` here, no tier.
EOF
while IFS='|' read -r tag body; do
  sp="$X/spec-QM-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n$body")"$'\n'
  round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding open '- **Severity:** wrong-result')"$'\n' > "$sp/notes/opponent.md"
  both "QM-$tag" "$sp"
  sk="$X/spec-QK-$tag"; mkdir -p "$sk/notes"
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** data-loss\n\n$body")")"$'\n' > "$sk/notes/opponent.md"
  both "QK-$tag" "$sk"
  for p in M K; do for l in C en_US.UTF-8; do say "  | B2 $p $tag $l: CUR rc=$(cat "$w/Q$p-$tag-cur-$l.rc") D rc=$(cat "$w/Q$p-$tag-d-$l.rc") $(head -1 "$w/Q$p-$tag-d-$l.err" | sed 's/.*opponent.md:[0-9]*: //' | LC_ALL=C cut -c1-110)"; done; done
  check "B2 $tag: refused on D in both passes and both locales" '3 3 3 3' "$(cat "$w/QM-$tag-d-C.rc") $(cat "$w/QM-$tag-d-en_US.UTF-8.rc") $(cat "$w/QK-$tag-d-C.rc") $(cat "$w/QK-$tag-d-en_US.UTF-8.rc")"
done < "$X/consequences"
for b in '<div>' '<details>'; do
  t="value-$(printf '%s' "$b" | tr -dc 'a-z')"
  sp="$X/spec-QV-$t"; mkdir -p "$sp/notes"
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "- **Severity:** data-loss\n$b\nx\n</${b#<}")")"$'\n' > "$sp/notes/opponent.md"
  both "QV-$t" "$sp"
  check "B2 the O-021 block $b after a field line: parses on CUR, refused on D" '0 3' "$(cat "$w/QV-$t-cur-C.rc") $(cat "$w/QV-$t-d-C.rc")"
  hasre "B2 the O-021 block $b: D says" 'raw HTML outside a code span in finding G-050' "$w/QV-$t-d-C.err"
done

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
check 'B3 every returned file read (rounds 2 to 6 and 8 to 16, and the round-3 reconcile record, each once)' 15 "$nrep"

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
check 'C 003: seventeen sealed rounds compared (sixteen opponent, one reality-check)' 17 "$nsealed"
for n in 16 17; do
  for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"; ( cd "$K" && bash scripts/spec-gate.sh waiver "$s" opponent "$n" < /dev/null ) > "$w/H-w$n-$k.log" 2>&1; echo $? >> "$w/H-w$n-$k.log"; done
  check "C waiver check for round $n: CUR and D identical" same "$(cmp -s "$w/H-w$n-cur.log" "$w/H-w$n-d.log" && echo same)"
done
check 'C waiver round 16 reported completed (exit 0)' 0 "$(tail -1 "$w/H-w16-d.log")"
check 'C waiver round 17 refused (exit 4)' 4 "$(tail -1 "$w/H-w17-d.log")"
for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"
  ( cd "$K" && bash -c '. scripts/verification-lib.sh && vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$w/H-snap-$k.nul" ) > "$w/H-snap-$k.out" 2>&1
  tr '\0' '\n' < "$w/H-snap-$k.nul" | paste - - - - - - | sed "s#$K#KIT#g" | LC_ALL=C grep -v -F -e 'scripts/verification-lib.sh' -e 'templates/verification-contract.md' > "$w/H-snap-$k.tsv"
done
check 'C snapshot records outside the two candidate files identical (kit path normalized)' same "$(cmp -s "$w/H-snap-cur.tsv" "$w/H-snap-d.tsv" && echo same)"
say "  | snapshot: CUR $(head -c 16 "$w/H-snap-cur.out"), D $(head -c 16 "$w/H-snap-d.out"), records compared $(wc -l < "$w/H-snap-d.tsv" | tr -d ' ')"
for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"
  t0=$(date +%s); ( cd "$K" && bash scripts/spec-gate.sh tally "$s" < /dev/null ) > /dev/null 2>&1; say "  | timing: 003 tally on $k took $(( $(date +%s) - t0 )) s"
done

say '== E: O-023, the run reader timed (one canonical round whose Reproduced field holds n sub-bullets)'
perf() { # kit label n variant -> seconds; rc in $w/perf-<label>-<variant>-<n>.rc
  local k="$1" label="$2" n="$3" v="$4" d="$X/perf-$2-$4-$3" st i; mkdir -p "$d/notes"
  { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CLEARED\n**Blocking:** 0 · **Minor:** 1\n### What I attacked\nx\n### Finding G-050\n- **Class:** dup-binding\n- **Status:** new\n- **Prior:** none\n- **Severity:** minor\n- **Scenario:** a trigger\n- **Where:** a.sh:1\n- **Reproduced:** see below\n' "$SRC"
    for i in $(seq 1 "$n"); do
      if [[ "$v" == html ]]; then printf '  - step %d ran `bash scripts/x.sh --flag %d` in [the copy](u) and <b>exited</b> 0 with output `ok`.\n' "$i" "$i"
      else printf '  - step %d ran `bash scripts/x.sh --flag %d` in [the copy](u) and `<b>exited</b>` 0 with output `ok`.\n' "$i" "$i"; fi
    done
    printf -- '- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** x\n- **Class-wide fix:** y\n### Held up / follow-up tasks\nz\n<!-- gate-round-end: opponent:1 -->\n'; } > "$d/notes/opponent.md"
  st=$(date +%s); inloc C bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$k" "$d/notes/opponent.md" "$d/c.nul" "$d" < /dev/null > /dev/null 2> "$w/perf-$label-$v-$n.err"
  echo $? > "$w/perf-$label-$v-$n.rc"; echo $(( $(date +%s) - st ))
}
for n in 50 100 200 400; do tl="$(perf "$D" d "$n" legal)"; say "  | D legal n=$n: ${tl}s rc=$(cat "$w/perf-d-legal-$n.rc")"; eval "dl$n=$tl"; done
for n in 100 200; do th="$(perf "$D" d "$n" html)"; say "  | D html n=$n: ${th}s rc=$(cat "$w/perf-d-html-$n.rc") $(head -1 "$w/perf-d-html-$n.err" | sed 's/.*opponent.md:[0-9]*: //' | LC_ALL=C cut -c1-90)"; eval "dh$n=$th"; done
tc="$(perf "$C" cur 100 legal)"; say "  | CUR legal n=100: ${tc}s rc=$(cat "$w/perf-cur-legal-100.rc")"
check 'E D: the 400-line legal run parses (rc 0)' 0 "$(cat "$w/perf-d-legal-400.rc")"
check 'E D: the 200-line run with tags outside code spans is refused (rc 3)' 3 "$(cat "$w/perf-d-html-200.rc")"
check 'E D: the 400-line legal run takes under 30 s' 1 "$(( dl400 < 30 ? 1 : 0 ))"
check 'E D: the 200-line html run takes under 30 s' 1 "$(( dh200 < 30 ? 1 : 0 ))"
check 'E D: doubling the legal run from 200 to 400 lines at most quadruples its time (plus 2 s)' 1 "$(( dl400 <= 4 * dl200 + 2 ? 1 : 0 ))"

say '== D: the full suite on D in its own copy (TMPDIR ending in /), failures read assertion by assertion'
DS="$X/dsuite"; cp -R "$D" "$DS"; mkdir -p "$X/tmp-suite"
( cd "$DS" && TMPDIR="$X/tmp-suite/" bash tests/run.sh < /dev/null ) > "$w/suite.log" 2>&1; echo $? > "$w/suite.rc"
say "  | suite rc=$(cat "$w/suite.rc"); per-suite: $(grep -E '^  -- [0-9]+/[0-9]+ passed' "$w/suite.log" | tr '\n' ' ')"
grep -E '^  FAIL ' "$w/suite.log" | sed 's/^/  | /'
grep -E 'assert|expected' "$w/suite.log" | LC_ALL=C cut -c1-230 | sed 's/^/  |   /' | head -80
cp "$w/suite.log" "$WT/$r/r17-measure-suite.log"
say "  | suite exit recorded (expected to fail only on fixture rows whose findings carry raw HTML, the recorded consequence): $(cat "$w/suite.rc")"

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "r17-measure failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
