#!/usr/bin/env bash
# T030o44 review repairs: the candidate rule MEASURED before adoption, 2026-10-02 (session 13). Read-only
# against the live worktree: two kits built from the live enumeration under the scratch directory, with a
# TMPDIR ending in `/` inside it. CUR is this tree (the T030o44 delta of session 12 applied); D is CUR
# with the candidate pairs t030o44-edits/kernel-3.pairs applied to scripts/verification-lib.sh (nothing
# else; texts in t030o44-edits/new-3/). The live status outside notes/verification/ is compared before
# and after. Pattern: o018-measure.sh.
# A: every review member, CUR as the review found it and D refusing it by name with its exact
#    diagnostic: manifest (M) and canonical (U) rows for F1, F4, F9, F10, F11, and siblings derived
#    from each mechanism (an image, a reference link, a footnote reference, a destination with nested
#    parentheses, a comment holding `>`, a fenced, blockquoted, commented or raw second tier, a whole
#    hidden finding, a Status continued past its line).
# B: what must still parse on D: the shipped plausible-manifest shapes and canonical positives of
#    o018-measure, the twelve returned round reports read as manifests, quoted prose without a record,
#    a field line followed by a heading, a thematic break, a blank line and prose, a legacy round
#    reaching every canonical conjunct (F6).
# C: the minors' rows (F2 prose refusals, F3 the legacy duplicate, F5 a reality-check gap written in
#    field spelling), recorded, on both kits.
# D: the recorded history, CUR against D under LANG=C and LANG=en_US.UTF-8 with every LC_* removed:
#    tally, analyzer, spec-ac-coverage, every report catalog with its diagnostics and exit, every
#    round's extracted block (the sealed digests), the binding catalogs, the stage maps, the semantic
#    views of every spec file, the waiver checks for rounds 14 and 15, and the snapshot records.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
X="$SP/t030o44-measure-2"; C="$X/cur"; D="$X/d"; w="$X/work"
rm -rf "$X"; mkdir -p "$C" "$w" "$X/tmp"
export TMPDIR="$X/tmp/"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
has() { if grep -q -F -- "$2" "$3"; then say "PASS $1"; else say "FAIL $1 (missing: $2)"; sed 's/^/  | /' "$3" | head -5; fails=$((fails+1)); fi; }
hasnot() { if grep -q -F -- "$2" "$3"; then say "FAIL $1 (present: $2)"; fails=$((fails+1)); else say "PASS $1"; fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
say "start $(date -u +%Y-%m-%dT%H:%M:%SZ); host: $(uname -sr); bash on PATH: $(bash --version | head -1); TMPDIR=$TMPDIR"

( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$C" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$C" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
check 'CUR: the four T030o44 files hash as post-apply-2' 4 "$(cd "$C" && shasum -a 256 -c "$WT/$r/t030o44-edits/post-apply-2.sha256" 2>/dev/null | grep -c ': OK$')"
cp -R "$C" "$D"
perl "$WT/$r/t030o44-edits/lit.pl" "$D/scripts/verification-lib.sh" "$WT/$r/t030o44-edits/kernel-3.pairs" > "$w/apply.log" 2>&1
check 'D: kernel-3.pairs applied, each block exactly once' 'applied 7 block(s)' "$(sed -n 's/^\(applied 7 block(s)\).*/\1/p' "$w/apply.log")"
check 'D: the kernel still parses' 0 "$(bash -n "$D/scripts/verification-lib.sh"; echo $?)"
check 'D: only verification-lib.sh differs from CUR' 'scripts/verification-lib.sh' "$(cd "$D" && git status --porcelain | sed 's/^ M //' | tr '\n' ' ' | sed 's/ $//')"

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
mani() { mkdir -p "$1/notes/verification/reports"; printf '# Prior review\n\n%s' "$2" > "$1/notes/verification/reports/opponent-findings-review.md"; }
vfr() { # tag kit locale report spec [gate] -> prints rc; stderr in $w/<tag>.err, catalog in $w/<tag>.nul
  inloc "$3" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" "$5" "$3" "$4"' _ "$2" "$4" "$w/$1.nul" "$5" "${6:-opponent}" < /dev/null > "$w/$1.out" 2> "$w/$1.err"
  echo $? > "$w/$1.rc"; cat "$w/$1.rc"
}
LOW='clearing verdict rests on 1 lowered severity tier(s) of known findings'
both() { # tag spec [gate] -> runs CUR and D under both locales
  local tag="$1" sp="$2" g="${3:-opponent}" l
  for l in C en_US.UTF-8; do vfr "$tag-cur-$l" "$C" "$l" "$sp/notes/$g.md" "$sp" "$g" > /dev/null; vfr "$tag-d-$l" "$D" "$l" "$sp/notes/$g.md" "$sp" "$g" > /dev/null; done
}
judge() { # label tag cur-rc d-rc d-diagnostic
  local l
  for l in C en_US.UTF-8; do
    check "$1 $l: CUR rc" "$3" "$(cat "$w/$2-cur-$l.rc")"
    check "$1 $l: D rc" "$4" "$(cat "$w/$2-d-$l.rc")"
    [[ -z "${5:-}" ]] || has "$1 $l: D says" "$5" "$w/$2-d-$l.err"
    [[ "$4" != 0 ]] || check "$1 $l: D stderr empty" 0 "$(wc -c < "$w/$2-d-$l.err" | tr -d ' ')"
  done
}
SEC='a second Severity line in finding G-042'
QSEV='quoted content carries a Severity line'
ITEM='a Severity field whose list item holds more than its line in finding'

say '== A1: manifest members (CLEARED round 1 re-records G-042 open at minor; the manifest holds G-042 at minor, then LINE)'
cat > "$X/m.cases" <<'EOF'
ctl-html-b|@B@- <b>Severity:</b> data-loss\n|3|a second Severity line in finding G-042: - <b>Severity:</b> data-loss
f1-quoted-gt|@B@- <b title="a>b">Severity:</b> data-loss\n|0|a second Severity line in finding G-042: - <b title="a>b">Severity:</b> data-loss
f1-autolink|@B@- <Severity:data-loss>\n|0|a second Severity line in finding G-042: - <Severity:data-loss>
f1-non-tag|@B@- <Severity: data-loss>\n|0|a second Severity line in finding G-042: - <Severity: data-loss>
f4-empty-comment|@B@\n<!-->\n\n- **Severity:** data-loss\n\nNotes end here. -->\n|0|quoted content carries a Severity line: - **Severity:** data-loss
f4-empty-comment-dash|@B@\n<!--->\n\n- **Severity:** data-loss\n\nNotes end here. -->\n|0|quoted content carries a Severity line: - **Severity:** data-loss
f4-opener-in-attribute|@B@- <b title="<!--">Note</b> the tier below.\n- **Severity:** data-loss\n- That is the tier. -->\n|0|quoted content carries a Severity line: - **Severity:** data-loss
f4-fence-info-backtick|@B@\n```x`y\n- **Severity:** data-loss\n```\n|0|quoted content carries a Severity line: - **Severity:** data-loss
f9-nbsp|@B@- &nbsp;Severity: data-loss\n|0|a second Severity line in finding G-042: - &nbsp;Severity: data-loss
f9-ensp-bold|@B@- &ensp;**Severity:** data-loss\n|0|a second Severity line in finding G-042: - &ensp;**Severity:** data-loss
ctl-numeric-ref|@B@- &#160;Severity: data-loss\n|3|a second Severity line in finding G-042: - &#160;Severity: data-loss
f10-continued-indented|@B@  data-loss\n|0|a Severity field whose list item holds more than its line in finding G-042:   data-loss
f10-continued-lazy|@B@data-loss\n|0|a Severity field whose list item holds more than its line in finding G-042: data-loss
f10-second-paragraph|@B@\n  data-loss\n|0|a Severity field whose list item holds more than its line in finding G-042:   data-loss
f10-nested-item|@B@  - data-loss\n|0|a Severity field whose list item holds more than its line in finding G-042:   - data-loss
f10-ordered-two|@B@2. data-loss\n|0|a Severity field whose list item holds more than its line in finding G-042: 2. data-loss
f10-fence-info-direct|@B@```x`y\nnot a fence\n```\n|0|a Severity field whose list item holds more than its line in finding G-042: ```x`y
s-nested-field-under-class|### Finding G-042\n  - **Class:** tier-binding\n    - **Severity:** data-loss\n|3|clearing verdict rests on 1 lowered severity tier(s) of known findings
ws-separator-read|### Finding G-042\n-\302\240**Class:** tier-binding\n-\302\240**Severity:** data-loss\n|3|clearing verdict rests on 1 lowered severity tier(s) of known findings
f10-details-after|@B@<details>\nx\n</details>\n|0|a Severity field whose list item holds more than its line in finding G-042: <details>
f10-nested-tier-note|@B@  - **Tier:** data-loss\n|0|a Severity field whose list item holds more than its line in finding G-042:   - **Tier:** data-loss
f11-empty-link|@B@- [](x)**Severity:** data-loss\n|0|a second Severity line in finding G-042: - [](x)**Severity:** data-loss
f11-link-title|@B@- [](#a "t")Severity: data-loss\n|0|a second Severity line in finding G-042: - [](#a "t")Severity: data-loss
s-image|@B@- ![x](y)Severity: data-loss\n|0|a second Severity line in finding G-042: - ![x](y)Severity: data-loss
s-reference-link|@B@- [][r]Severity: data-loss\n|0|a second Severity line in finding G-042: - [][r]Severity: data-loss
s-footnote|@B@- [^1]Severity: data-loss\n|0|a second Severity line in finding G-042: - [^1]Severity: data-loss
s-nested-destination|@B@- [](a(b)c)Severity: data-loss\n|0|a second Severity line in finding G-042: - [](a(b)c)Severity: data-loss
s-comment-with-gt|@B@- <!-- a>b --> Severity: data-loss\n|3|a second Severity line in finding G-042: - <!-- a>b --> Severity: data-loss
s-fenced-second|@B@\n```text\n- **Severity:** data-loss\n```\n|0|quoted content carries a Severity line: - **Severity:** data-loss
s-blockquoted-second|@B@> - **Severity:** data-loss\n|0|quoted content carries a Severity line: > - **Severity:** data-loss
s-commented-second|@B@<!--\n- **Severity:** data-loss\n-->\n|0|quoted content carries a Severity line: - **Severity:** data-loss
s-script-second|@B@\n<script>\n- **Severity:** data-loss\n</script>\n|0|quoted content carries a Severity line: - **Severity:** data-loss
s-hidden-finding|@B@\n<!-->\n\n### Finding G-043\n- **Class:** other-binding\n- **Severity:** data-loss\n\n-->\n|0|quoted content carries a Finding heading: ### Finding G-043
EOF
base='### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n'
while IFS='|' read -r tag body currc diag; do
  sp="$X/spec-M-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "${body//@B@/$base}")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "M-$tag" "$sp"; judge "A1 M $tag" "M-$tag" "$currc" 3 "$diag"
done < "$X/m.cases"

say '== A2: canonical members (CLEARED round 1, totals 0 . 1, new G-050 written - **Severity:** minor, then LINE)'
cat > "$X/u.cases" <<'EOF'
ctl-html-b|- **Severity:** minor\n- <b>Severity:</b> data-loss|3|a Severity line this grammar cannot read in finding G-050
f1-quoted-gt|- **Severity:** minor\n- <b title="a>b">Severity:</b> data-loss|0|a Severity line this grammar cannot read in finding G-050
f1-quoted-gt-nested|- **Severity:** minor\n  - <b title="a>b">Severity:</b> data-loss|0|a Severity field whose list item holds more than its line in finding G-050
f1-autolink|- **Severity:** minor\n- <Severity:data-loss>|0|a Severity line this grammar cannot read in finding G-050
f1-non-tag|- **Severity:** minor\n- <Severity: data-loss>|0|a Severity line this grammar cannot read in finding G-050
f4-empty-comment|- **Severity:** minor\n\n<!-->\n\n- **Severity:** data-loss\n\nThe tier above is the one we stand by. -->|0|quoted content carries a Severity line
f4-empty-comment-dash|- **Severity:** minor\n\n<!--->\n\n- **Severity:** data-loss\n\nThe tier above is the one we stand by. -->|0|quoted content carries a Severity line
f4-opener-in-attribute|- **Severity:** minor\n- <b title="<!--">Note</b> the tier below.\n- **Severity:** data-loss\n- That is the tier. -->|0|quoted content carries a Severity line
f4-fence-info-backtick|- **Severity:** minor\n\n```x`y\n- **Severity:** data-loss\n```|0|quoted content carries a Severity line
f9-nbsp-bold|- **Severity:** minor\n- &nbsp;**Severity:** data-loss|0|a Severity line this grammar cannot read in finding G-050
f10-continued-indented|- **Severity:** minor\n  data-loss|0|a Severity field whose list item holds more than its line in finding G-050
f10-continued-lazy|- **Severity:** minor\ndata-loss|0|a Severity field whose list item holds more than its line in finding G-050
f11-empty-link|- **Severity:** minor\n- [](x)**Severity:** data-loss|0|a Severity line this grammar cannot read in finding G-050
s-image|- **Severity:** minor\n- ![x](y)Severity: data-loss|0|a Severity line this grammar cannot read in finding G-050
s-fenced-second|- **Severity:** minor\n\n```text\n- **Severity:** data-loss\n```|0|quoted content carries a Severity line
s-blockquoted-second|- **Severity:** minor\n> - **Severity:** data-loss|0|quoted content carries a Severity line
s-quoted-status|- **Severity:** minor\n\n<!-->\n\n- **Status:** resolved\n\n-->|0|quoted content carries a finding field line
EOF
while IFS='|' read -r tag sevs currc diag; do
  sp="$X/spec-U-$tag"; mkdir -p "$sp/notes"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "$sevs")")"$'\n' > "$sp/notes/opponent.md"
  both "U-$tag" "$sp"; judge "A2 U $tag" "U-$tag" "$currc" 3 "$diag"
done < "$X/u.cases"
sp="$X/spec-U-status-continued"; mkdir -p "$sp/notes"
round 1 CHALLENGED 1 0 "$(finding '### Finding G-050' dup-binding "$(printf 'new\n  reopened later')" '- **Severity:** data-loss')"$'\n' > "$sp/notes/opponent.md"
both U-status-continued "$sp"; judge 'A2 U status-continued' U-status-continued 0 3 'a Status field whose list item holds more than its line in finding G-050'
sp="$X/spec-U-hidden-finding"; mkdir -p "$sp/notes"
round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new '- **Severity:** minor')"$'\n\n<!-->\n\n'"$(finding '### Finding G-051' other-binding new '- **Severity:** data-loss')"$'\n\n-->\n' > "$sp/notes/opponent.md"
both U-hidden-finding "$sp"; judge 'A2 U hidden-finding' U-hidden-finding 0 3 'quoted content carries a Finding heading'
say '  end to end is the fixtures'"'"' job (round_record_line_cases); every row above reads through the same vf_reports'

say '== B1: manifests that must still parse on D (CHALLENGED round 1 re-records O-017 at its tier)'
cat > "$X/p.cases" <<'EOF'
recorded-finding-text|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Status:** new\n- **Severity:** wrong-result\n- **Where:** scripts/verification-lib.sh:955-968\n- **The inputs.** The manifest has six lines: a heading, a Class, a Severity and a Scenario.\n- **Class-wide fix:** make every `**Severity:**` line parse by the canonical grammar\n
trailing-section|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Follow-up\n- T030o43 fixes the **Severity:** handling\n- **T001** — fix it; its **Severity:** stays data-loss\n
prose-mention|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n- **Scenario:** the **Class:** field was lost; a line written `-\302\240**Class:**` was skipped\n
summary-prose|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Summary\n\n- Class: harness-locale-decoding, one finding\n- Severity: all blocking\n
introduction-prose|# Prior review\n\nSeverity: every finding below is blocking.\n\n### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n
class-binding-lead-in|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n- **Class binding.** A manifest recording the tier is read.\n
summary-with-subsection|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Summary\n\n#### Details\n\n- Severity: all blocking\n
severity-prose-inside|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n- Severity was re-read twice, once per locale.\n- **Class-wide fix:** read the status\n
notes-subheading|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n#### Notes\nReproduced twice.\n
severity-then-heading|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n#### Notes\nReproduced twice.\n
severity-then-thematic-break|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n---\nAfter the break.\n
severity-then-blank-and-prose|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\nA paragraph after the finding.\n
severity-first|### Finding O-017\n- **Severity:** wrong-result\n- **Class:** harness-locale-decoding\n
severity-then-fenced-block|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n```text\nplain output\n```\n
severity-then-pre-block|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n<pre>\nplain output\n</pre>\n
finding-summary|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Finding summary\nOne finding.\n\n```text\n- **Severity:** minor\n```\n
quoted-output-without-record|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n```text\nplain output, no record in it\n```\n> A quoted remark.\n
EOF
for row in $(cut -d'|' -f1 "$X/p.cases"); do
  body="$(grep "^$row|" "$X/p.cases" | cut -d'|' -f2-)"
  sp="$X/spec-P-$row"; mkdir -p "$sp/notes/verification/reports"; printf '%b' "$body" > "$sp/notes/verification/reports/opponent-findings-review.md"
  round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding open '- **Severity:** wrong-result')"$'\n' > "$sp/notes/opponent.md"
  both "P-$row" "$sp"; judge "B1 $row parses" "P-$row" 0 0
done
say '  the real prior-review manifest, under a CHALLENGED round re-recording each of its findings at its tier:'
sp="$X/spec-P-real"; mkdir -p "$sp/notes/verification/reports"; cp "$C/$r/opponent-findings-2026-09-09.md" "$sp/notes/verification/reports/"
body=''; for f in O-001:return-envelope-parsing:wrong-result O-002:round-authorization-grammar:wrong-result O-003:live-control-semantic-validation:wrong-result O-004:gate-report-schema-validation:wrong-result O-005:config-interpolation-validation:wrong-result O-006:post-pr-followup-binding-schema:regression; do
  IFS=: read -r id cl sv <<< "$f"; body+="$(finding "### Finding $id" "$cl" open "- **Severity:** $sv")"$'\n'
done
round 1 CHALLENGED 6 0 "$body" > "$sp/notes/opponent.md"
both P-real "$sp"; judge 'B1 the 2026-09-09 manifest parses' P-real 0 0
check 'B1 the 2026-09-09 manifest: CUR and D catalogs identical' same "$(cmp -s "$w/P-real-cur-C.nul" "$w/P-real-d-C.nul" && echo same)"
say '  each returned round report read as a prior-review manifest, under a CLEARED round re-recording G-042 at minor:'
for rep in "$C/$r"/opponent-round[0-9]*.md "$C/$r"/opponent-round3-reconcile.md; do
  case "$rep" in *-brief*) continue;; esac
  b="$(basename "$rep" .md)"; sp="$X/spec-R-$b"; mkdir -p "$sp/notes/verification/reports"; cp "$rep" "$sp/notes/verification/reports/opponent-findings-review.md"
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "R-$b" "$sp"; judge "B1 $b as a manifest parses" "R-$b" 0 0
done

say '  consequences recorded rather than discovered: a Class or Severity item holds its line alone, so D refuses these'
cat > "$X/k.cases" <<'EOF'
nested-note|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n  - **Note:** reproduced twice\n
nested-lead-in|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n   - **Class binding.** A manifest recording the tier is read.\n
EOF
for row in $(cut -d'|' -f1 "$X/k.cases"); do
  body="$(grep "^$row|" "$X/k.cases" | cut -d'|' -f2-)"
  sp="$X/spec-K-$row"; mkdir -p "$sp/notes/verification/reports"; printf '%b' "$body" > "$sp/notes/verification/reports/opponent-findings-review.md"
  round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding open '- **Severity:** wrong-result')"$'\n' > "$sp/notes/opponent.md"
  both "K-$row" "$sp"; judge "B1 consequence $row" "K-$row" 0 3 'a Severity field whose list item holds more than its line in finding O-017'
done

say '== B2: canonical findings that must still parse on D (CHALLENGED round 1, totals 1 . 0)'
cat > "$X/q.cases" <<'EOF'
notes-subheading|### Finding G-042|- **Severity:** data-loss|#### Notes\nReproduced twice, once per locale.\n
details-subheading-with-prose|### Finding G-042|- **Severity:** data-loss|#### Details\n- **The manifest member.** A heading carries the tier.\n
titled-heading|### Finding G-042 — tier read|- **Severity:** data-loss|
class-binding-lead-in|### Finding G-042|- **Severity:** data-loss|  - **Class binding.** The record is read.\n  - Severity was re-read twice.\n
quoted-example-inline|### Finding G-042|- **Severity:** data-loss|  - The lines `#### Severity: data-loss` and `- <b>Severity:</b> minor` are refused.\n
quoted-output-without-record|### Finding G-042|- **Severity:** data-loss|\n```text\nplain output, no record in it\n```\n\n
severity-then-blank|### Finding G-042|- **Severity:** data-loss\n|
EOF
while IFS='|' read -r tag heading sevs extra; do
  sp="$X/spec-Q-$tag"; mkdir -p "$sp/notes"
  sv="$(printf '%b' "$sevs")"; [[ "$tag" != severity-then-blank ]] || sv+=$'\n'
  round 1 CHALLENGED 1 0 "$(finding "$heading" tier-binding new "$sv" "$(printf '%b' "$extra")"$'\n')"$'\n' > "$sp/notes/opponent.md"
  both "Q-$tag" "$sp"; judge "B2 $tag parses" "Q-$tag" 0 0
done < "$X/q.cases"
sp="$X/spec-Q-quoted-field-outside"; mkdir -p "$sp/notes"
round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n' '' '' '' "$(printf 'Disposition recorded.\n```text\n- **Severity:** minor\n```')" > "$sp/notes/opponent.md"
both Q-quoted-field-outside "$sp"; judge 'B2 a quoted field line outside any finding parses' Q-quoted-field-outside 0 0
sp="$X/spec-Q-quoted-heading-outside"; mkdir -p "$sp/notes"
round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n' '' '' '' "$(printf 'Disposition recorded.\n<!--\n### Finding G-051\n-->')" > "$sp/notes/opponent.md"
both Q-quoted-heading-outside "$sp"; judge 'A2 a quoted Finding heading outside any finding' Q-quoted-heading-outside 0 3 'quoted content carries a Finding heading'
sp="$X/spec-Q-heldup-prose"; mkdir -p "$sp/notes"
held="- Severity: all blocking, as recorded."$'\n'"- **The spec is right.** Nothing else held."
round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n' '' '' '' "$held" > "$sp/notes/opponent.md"
both Q-heldup-prose "$sp"; judge 'B2 Held-up prose after the last finding parses' Q-heldup-prose 0 0
say '  B3, F6: a legacy round reaching every canonical conjunct parses on D, with its catalog'
sp="$X/spec-L-reach"; mkdir -p "$sp/notes"
printf '# Opponent review\n**Round:** 1\n**Date:** 2026-07-20\n**Verdict:** CHALLENGED\n\n## What I attacked\n- **Scenario:** a recorded trigger\n\n1. **A defect** — *severity:* wrong-result\n   - **Where:** `a.sh:1`\n   - Severity, as above.\n   - **Severity**: noted\n#### Finding G-1\n### Notes\n   - **Blocks:** AC-001\n> - **Severity:** quoted in a legacy round\n' > "$sp/notes/opponent.md"
both L-reach "$sp"; judge 'B3 legacy round' L-reach 0 0
for k in cur d; do check "B3 legacy round $k catalog: legacy-1-1 keeps Blocks AC-001" 'legacy-1-1 AC-001' "$(tr '\0' '\n' < "$w/L-reach-$k-C.nul" | paste - - - - - - - - - - - - | awk -F '\t' '$1=="finding" {print $3, $12}')"; done

say '== C: the minors, recorded (both kits refuse)'
sp="$X/spec-F2"; for line in '  class, not one spelling of it.' '  (class) line outside any Finding in both locales.' '  - Severity: unchanged from round 12.' '  - Class, Status and Prior are unchanged.' '  - "Severity" here is the tier the count reads.' '  - Severity/Class binding held.'; do
  t="F2-$(printf '%s' "$line" | shasum | cut -c1-8)"; sp="$X/spec-$t"; mkdir -p "$sp/notes"
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss' "$line"$'\n')"$'\n' > "$sp/notes/opponent.md"
  both "$t" "$sp"; judge "C F2 '$line'" "$t" 3 3 'line this grammar cannot read in finding G-042'
done
sp="$X/spec-F3"; mkdir -p "$sp/notes"
printf '# Opponent review\n**Round:** 1\n**Date:** 2026-07-20\n**Verdict:** CHALLENGED\n1. **A defect** — *severity:* wrong-result\n   - **Scenario:** x\n   - **Where:** `a.sh:1`\n     - **Where:** `b.sh:2`\n' > "$sp/notes/opponent.md"
both F3 "$sp"; judge 'C F3 legacy indented duplicate' F3 3 3 'duplicate finding field'
sp="$X/spec-F5"; mkdir -p "$sp/notes"
printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** NEEDS WORK\n\n## Summary\n\nChecked one criterion.\n\n## AC matrix\n\n| AC | Criterion / revision | Evidence | Affected inputs | Verdict |\n|----|----|----|----|----|\n| AC-001 | x | CAP-1 | a | MISSING |\n\n## Constitution check\n\n- PASS\n\n## Gaps (if NEEDS WORK)\n\n1. **AC-001 evidence missing** — the capture is stale.\n   - **Where:** scripts/run.sh:9\n   - **Blocks:** AC-001\n\n## Re-run conditions\n\nRe-invoke when fixed.\n<!-- gate-round-end: reality-check:1 -->\n' "$SRC" > "$sp/notes/reality-check.md"
both F5 "$sp" reality-check; judge 'C F5 reality-check gap in field spelling' F5 3 3 'a finding field outside any Finding'
printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** NEEDS WORK\n\n## Summary\n\nChecked one criterion.\n\n## AC matrix\n\n| AC | Criterion / revision | Evidence | Affected inputs | Verdict |\n|----|----|----|----|----|\n| AC-001 | x | CAP-1 | a | MISSING |\n\n## Constitution check\n\n- PASS\n\n## Gaps (if NEEDS WORK)\n\n1. **AC-001 evidence missing** — the capture is stale. Where: scripts/run.sh:9. *Root cause:* implementation-error\n\n## Re-run conditions\n\nRe-invoke when fixed.\n<!-- gate-round-end: reality-check:1 -->\n' "$SRC" > "$sp/notes/reality-check.md"
both F5t "$sp" reality-check; judge 'C F5 the template shape itself parses' F5t 0 0

say '== D: the recorded history, CUR against D'
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
      check "D $spec $kind under $l: CUR and D identical, kit path normalized (output and exit)" same \
        "$(cmp -s <(sed "s#$C#KIT#g" "$w/H-$kind-$spec-cur-$l.log") <(sed "s#$D#KIT#g" "$w/H-$kind-$spec-d-$l.log") && echo same)"
    done
    say "  | $spec under $l: tally exit $(tail -1 "$w/H-tally-$spec-d-$l.log"), analyzer exit $(tail -1 "$w/H-an-$spec-d-$l.log"), ac-coverage exit $(tail -1 "$w/H-cov-$spec-d-$l.log")"
    for g in opponent reality-check; do
      [[ -f "$w/H-cat-$spec-$g-cur-$l.err" ]] || continue
      a="$w/H-cat-$spec-$g-cur-$l.nul"; b="$w/H-cat-$spec-$g-d-$l.nul"
      check "D $spec $g catalog under $l: CUR and D identical (or written by neither)" same "$( { [[ ! -e "$a" && ! -e "$b" ]] || cmp -s "$a" "$b"; } && echo same)"
      check "D $spec $g diagnostics and exit under $l: CUR and D identical" same "$(cmp -s "$w/H-cat-$spec-$g-cur-$l.err" "$w/H-cat-$spec-$g-d-$l.err" && echo same)"
      nb=0; same=1
      for x in "$w/H-blk-$spec-$g-"*"-cur-$l.txt"; do [[ -e "$x" ]] || continue; nb=$((nb+1)); cmp -s "$x" "${x/-cur-/-d-}" || same=0; done
      nd=0; for x in "$w/H-blk-$spec-$g-"*"-d-$l.txt"; do [[ -e "$x" ]] && nd=$((nd+1)); done
      check "D $spec $g every extracted round block under $l: CUR and D identical ($nb rounds)" "1 $nb" "$same $nd"
    done
    for mode in plan tasks; do
      check "D $spec $mode binding catalog and diagnostics under $l: CUR and D identical" same \
        "$( { [[ ! -e "$w/H-bind-$spec-$mode-cur-$l.nul" && ! -e "$w/H-bind-$spec-$mode-d-$l.nul" ]] || cmp -s "$w/H-bind-$spec-$mode-cur-$l.nul" "$w/H-bind-$spec-$mode-d-$l.nul"; } && cmp -s "$w/H-bind-$spec-$mode-cur-$l.err" "$w/H-bind-$spec-$mode-d-$l.err" && echo same)"
    done
    check "D $spec stage map and configuration catalog under $l: CUR and D identical" same \
      "$( { [[ ! -e "$w/H-cfg-$spec-cur-$l" && ! -e "$w/H-cfg-$spec-d-$l" ]] || diff -r "$w/H-cfg-$spec-cur-$l" "$w/H-cfg-$spec-d-$l" > /dev/null 2>&1; } && cmp -s "$w/H-cfg-$spec-cur-$l.err" "$w/H-cfg-$spec-d-$l.err" && echo same)"
    for doc in STATUS.md tasks.md plan.md spec.md; do
      [[ -f "$w/H-sem-$spec-$doc-cur-$l.txt" ]] || continue
      check "D $spec $doc semantic view under $l: CUR and D identical" same "$(cmp -s "$w/H-sem-$spec-$doc-cur-$l.txt" "$w/H-sem-$spec-$doc-d-$l.txt" && echo same)"
    done
  done
done
say '  the sealed digests: every completed round ledger of 003 against D'"'"'s extracted block'
for g in opponent reality-check; do
  for led in "$C/$s/notes/verification/rounds/$g"/ROUND-*; do
    [[ -f "$led/report.sha256" ]] || continue
    n="${led##*ROUND-}"
    for l in C en_US.UTF-8; do
      check "D 003 $g round $n sealed digest under $l equals D's block" "$(cat "$led/report.sha256")" "$(shasum -a 256 < "$w/H-blk-003-gate-round-reduction-and-token-discipline-$g-$n-d-$l.txt" | cut -d' ' -f1)"
    done
  done
done
for n in 14 15; do
  for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"; ( cd "$K" && bash scripts/spec-gate.sh waiver "$s" opponent "$n" < /dev/null ) > "$w/H-w$n-$k.log" 2>&1; echo $? >> "$w/H-w$n-$k.log"; done
  check "D waiver check for round $n: CUR and D identical" same "$(cmp -s "$w/H-w$n-cur.log" "$w/H-w$n-d.log" && echo same)"
done
check 'D waiver round 14 authorized (exit 0)' 0 "$(tail -1 "$w/H-w14-d.log")"
check 'D waiver round 15 refused (exit 4)' 4 "$(tail -1 "$w/H-w15-d.log")"
for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"
  ( cd "$K" && bash -c '. scripts/verification-lib.sh && vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$w/H-snap-$k.nul" ) > "$w/H-snap-$k.out" 2>&1
  tr '\0' '\n' < "$w/H-snap-$k.nul" | paste - - - - - - | sed "s#$K#KIT#g" | LC_ALL=C grep -v -F 'scripts/verification-lib.sh' > "$w/H-snap-$k.tsv"
done
check 'D snapshot records outside verification-lib.sh identical (kit path normalized)' same "$(cmp -s "$w/H-snap-cur.tsv" "$w/H-snap-d.tsv" && echo same)"
say "  | snapshot: CUR $(head -c 16 "$w/H-snap-cur.out"), D $(head -c 16 "$w/H-snap-d.out"), records compared $(wc -l < "$w/H-snap-d.tsv" | tr -d ' ')"

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "end $(date -u +%Y-%m-%dT%H:%M:%SZ)"
say "t030o44-measure-2 failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
