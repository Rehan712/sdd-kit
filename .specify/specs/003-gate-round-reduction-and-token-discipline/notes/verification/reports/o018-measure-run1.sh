#!/usr/bin/env bash
# O-018/O-019: the candidate rule MEASURED before adoption, 2026-10-01 (session 12). Read-only
# against the live worktree: two kits built from the live enumeration under the scratch directory,
# with a TMPDIR ending in `/` inside it. CUR is this tree; D is CUR with the candidate pairs
# t030o44-edits/kernel-1.pairs applied to scripts/verification-lib.sh (nothing else). The live
# status outside notes/verification/ is compared before and after.
# A: every o018-repro case, D refusing each member by name with its exact diagnostic. B: siblings
# derived from the rule (rendered text: character references, a second tier behind inline HTML,
# a heading behind a leading U+00A0, a separator after Finding). C: what must still parse (the
# shipped plausible-manifest shapes, the O-019 shapes, canonical findings with sub-headings,
# titles and prose lead-ins). D: the recorded history, CUR against D under LANG=C and
# LANG=en_US.UTF-8 with every LC_* removed: tally, the report catalogs, the waiver checks, the
# analyzer, spec-ac-coverage.sh and the snapshot records. E: the full suite and ShellCheck on D,
# which says which fixtures the rule changes.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
X="$SP/o018-measure"; C="$X/cur"; D="$X/d"; w="$X/work"
rm -rf "$X"; mkdir -p "$C" "$w" "$X/tmp"
export TMPDIR="$X/tmp/"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
has() { if grep -q -F -- "$2" "$3"; then say "PASS $1"; else say "FAIL $1 (missing: $2)"; sed 's/^/  | /' "$3" | head -5; fails=$((fails+1)); fi; }
hasnot() { if grep -q -F -- "$2" "$3"; then say "FAIL $1 (present: $2)"; fails=$((fails+1)); else say "PASS $1"; fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
say "host: $(uname -sr); bash on PATH: $(bash --version | head -1); TMPDIR=$TMPDIR"

( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$C" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$C" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
cp -R "$C" "$D"
perl "$WT/$r/t030o44-edits/lit.pl" "$D/scripts/verification-lib.sh" "$WT/$r/t030o44-edits/kernel-1.pairs" > "$w/apply.log" 2>&1
check 'D: kernel-1.pairs applied, each block exactly once' 'applied 8 block(s)' "$(sed -n 's/^\(applied 8 block(s)\).*/\1/p' "$w/apply.log")"
check 'D: the kernel still parses' 0 "$(bash -n "$D/scripts/verification-lib.sh"; echo $?)"
check 'D: only verification-lib.sh differs from CUR' 'scripts/verification-lib.sh' "$(cd "$D" && git status --porcelain | sed 's/^ M //' | tr '\n' ' ' | sed 's/ $//')"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
SRC="$(printf 'a%.0s' {1..64})"
NB=$'\302\240'; TAB=$'\t'; EMD=$'\342\200\224'; FENCE='```'
finding() { # heading class status severity-lines [extra lines after Scenario]
  printf '%s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n%s\n- **Scenario:** a recorded trigger\n%s- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read or refuse every record line\n' "$1" "$2" "$3" "$4" "${5:-}"
}
round() { # n verdict blocking minor findings [timestamp source floor] [held-up body]
  printf '## Round %s\n**Round:** %s\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nFinding records read by both readers.\n%s### Held up / follow-up tasks\n%s\n<!-- gate-round-end: opponent:%s -->\n' \
    "$1" "$1" "${6:-2026-09-06T12:00:0${1}Z}" "${7:-$SRC}" "${8:-FLOOR-fixture}" "$2" "$3" "$4" "$5" "${9:-Fixture disposition recorded.}" "$1"
}
mani() { mkdir -p "$1/notes/verification/reports"; printf '# Prior review\n\n%s' "$2" > "$1/notes/verification/reports/opponent-findings-review.md"; }
vfr() { # tag kit locale report spec -> prints rc; stderr in $w/<tag>.err, catalog in $w/<tag>.nul
  inloc "$3" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$2" "$4" "$w/$1.nul" "$5" < /dev/null > "$w/$1.out" 2> "$w/$1.err"
  echo $? > "$w/$1.rc"; cat "$w/$1.rc"
}
first() { head -1 "$w/$1.err" | LC_ALL=C cut -c1-160; }
LOW='clearing verdict rests on 1 lowered severity tier(s) of known findings'
G42='### Finding G-042\n- **Class:** tier-binding\n'
both() { # tag spec locale-list -> runs CUR and D; sets nothing, results in $w/<tag>-{cur,d}-<l>.*
  local tag="$1" sp="$2" l
  for l in C en_US.UTF-8; do vfr "$tag-cur-$l" "$C" "$l" "$sp/notes/opponent.md" "$sp" > /dev/null; vfr "$tag-d-$l" "$D" "$l" "$sp/notes/opponent.md" "$sp" > /dev/null; done
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

say '== A1: manifest member (CLEARED round 1 re-records G-042 open at minor, totals 0 . 1)'
cat > "$X/m.cases" <<EOF
control|${G42}- **Severity:** data-loss\n|3|$LOW
m1-h4-colon|${G42}\n#### Severity: data-loss\n|0|a Severity line this grammar cannot read: #### Severity: data-loss
m2-h4-body|${G42}\n#### Severity\n\ndata-loss\n|0|a Severity line this grammar cannot read: #### Severity
m3-h4-bold|${G42}\n#### **Severity:** data-loss\n|0|a Severity line this grammar cannot read: #### **Severity:** data-loss
m4-h4-dash|${G42}\n#### Severity ${EMD} data-loss\n|0|a Severity line this grammar cannot read: #### Severity ${EMD} data-loss
m5-h3-under-h2|## Finding G-042\n- **Class:** tier-binding\n\n### Severity: data-loss\n|0|a Severity line this grammar cannot read: ### Severity: data-loss
m5b-h3-body-under-h2|## Finding G-042\n- **Class:** tier-binding\n\n### Severity\n\ndata-loss\n|0|a Severity line this grammar cannot read: ### Severity
m6-html-b|${G42}- <b>Severity:</b> data-loss\n|0|a Severity line this grammar cannot read: - <b>Severity:</b> data-loss
m7-html-strong|${G42}- <strong>Severity:</strong> data-loss\n|0|a Severity line this grammar cannot read: - <strong>Severity:</strong> data-loss
m8-html-h4|${G42}<h4>Severity: data-loss</h4>\n|0|a Severity line this grammar cannot read: <h4>Severity: data-loss</h4>
d1-h5|${G42}\n##### Severity: data-loss\n|0|a Severity line this grammar cannot read: ##### Severity: data-loss
d2-h6-closed|${G42}\n###### Severity: data-loss ######\n|0|a Severity line this grammar cannot read: ###### Severity: data-loss ######
d3-html-em|${G42}- <em>Severity:</em> data-loss\n|0|a Severity line this grammar cannot read: - <em>Severity:</em> data-loss
d4-html-span|${G42}- <span class="tier">Severity: data-loss</span>\n|0|a Severity line this grammar cannot read: - <span class="tier">Severity: data-loss</span>
d5-blockquote|${G42}> - **Severity:** data-loss\n|0|finding G-042 has no readable Severity
d6-fenced|${G42}${FENCE}text\n- **Severity:** data-loss\n${FENCE}\n|0|finding G-042 has no readable Severity
d7-comment|${G42}<!-- - **Severity:** data-loss -->\n|0|finding G-042 has no readable Severity
d8-absent|${G42}|0|finding G-042 has no readable Severity
setext|${G42}\nSeverity: data-loss\n---\n|3|a Severity line this grammar cannot read: Severity: data-loss
EOF
while IFS='|' read -r tag body currc diag; do
  sp="$X/spec-M-$tag"; mkdir -p "$sp/notes"
  mani "$sp" "$(printf '%b' "$body")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "M-$tag" "$sp"; judge "A1 M $tag" "M-$tag" "$currc" 3 "$diag"
done < "$X/m.cases"

say '== A2: O-019. A sub-heading inside a manifest finding: D reads the fields, as PRE did'
cat > "$X/s.cases" <<EOF
s1-notes|${G42}#### Notes\nReproduced twice.\n- **Severity:** data-loss\n
s2-details|### Finding G-042\n#### Details\n- **Class:** tier-binding\n- **Severity:** data-loss\n
s3-two-levels|### Finding G-042\n#### Details\n##### Evidence\n- **Class:** tier-binding\n- **Severity:** data-loss\n
EOF
while IFS='|' read -r tag body; do
  sp="$X/spec-S-$tag"; mkdir -p "$sp/notes"; mani "$sp" "$(printf '%b' "$body")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "S-$tag" "$sp"; judge "A2 S $tag CLEARED over the lowered tier" "S-$tag" 3 3 "$LOW"
  for l in C en_US.UTF-8; do hasnot "A2 S $tag $l: D no longer says outside" 'outside any Finding' "$w/S-$tag-d-$l.err"; done
  sp="$X/spec-Sp-$tag"; mkdir -p "$sp/notes"; mani "$sp" "$(printf '%b' "$body")"$'\n'
  round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding open '- **Severity:** data-loss')"$'\n' > "$sp/notes/opponent.md"
  both "Sp-$tag" "$sp"; judge "A2 S $tag CHALLENGED at its tier: D parses" "Sp-$tag" 3 0
done < "$X/s.cases"

say '== A3: canonical member (round 1 CHALLENGED, G-042 data-loss; round 2 CLEARED 0 . 0 re-lists it at minor)'
r1="$(round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n')"
cat > "$X/c.cases" <<EOF
c1-h4|#### Finding G-042|0|a Finding heading this grammar cannot read
c2-tab|### Finding${TAB}G-042|0|a Finding heading this grammar cannot read
c3-two-spaces|###  Finding G-042|0|a Finding heading this grammar cannot read
c4-nbsp|### Finding${NB}G-042|0|a Finding heading this grammar cannot read
c5-lowercase|### finding G-042|0|a Finding heading this grammar cannot read
d1-h2|## Finding G-042|0|a Finding heading this grammar cannot read
d2-h5|##### Finding G-042|0|a Finding heading this grammar cannot read
d3-leading-space| ### Finding G-042|0|a Finding heading this grammar cannot read
d4-tab-after-hashes|###${TAB}Finding G-042|0|a Finding heading this grammar cannot read
d5-uppercase|### FINDING G-042|0|a Finding heading this grammar cannot read
d6-colon|### Finding: G-042|0|a Finding heading this grammar cannot read
d7-bold-line|**Finding G-042**|0|a finding field outside any Finding
b1-dash-separator|### Finding ${EMD} G-042|3|incomplete finding
b2-nbsp-before-hashes|${NB}### Finding G-042|0|a Finding heading this grammar cannot read
b3-list-item|- ### Finding G-042|0|a finding field outside any Finding
EOF
sp="$X/spec-C-control"; mkdir -p "$sp/notes"
{ printf '%s\n\n' "$r1"; round 2 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n'; } > "$sp/notes/opponent.md"
both C-control "$sp"; judge 'A3 C control' C-control 3 3 "$LOW"
while IFS='|' read -r tag heading currc diag; do
  sp="$X/spec-C-$tag"; mkdir -p "$sp/notes"
  { printf '%s\n\n' "$r1"; round 2 CLEARED 0 0 "$(finding "$heading" tier-binding open '- **Severity:** minor')"$'\n'; } > "$sp/notes/opponent.md"
  both "C-$tag" "$sp"; judge "A3 C $tag" "C-$tag" "$currc" 3 "$diag"
done < "$X/c.cases"

say '== A4: canonical duplicate key (CLEARED round 1, totals 0 . 1, new G-050 with two Severity lines)'
cat > "$X/u.cases" <<EOF
control|- **Severity:** data-loss\n- **Severity:** minor|3|duplicate finding field
u1-indented-second|- **Severity:** data-loss\n  - **Severity:** minor|0|duplicate finding field
d1-indented-first|  - **Severity:** data-loss\n- **Severity:** minor|0|duplicate finding field
d2-unread-first|- **Severity**: data-loss\n- **Severity:** minor|0|a Severity line this grammar cannot read in finding G-050
b1-html-second|- **Severity:** minor\n  - <b>Severity:</b> data-loss|0|a Severity line this grammar cannot read in finding G-050
b2-charref-second|- **Severity:** minor\n  - &#83;everity: data-loss|0|a Severity line this grammar cannot read in finding G-050
b3-subheading-second|- **Severity:** minor\n#### Severity: data-loss|0|a Severity line this grammar cannot read in finding G-050
b4-hexref-class|- **Severity:** minor\n  - &#x43;lass: other-class|0|a Class line this grammar cannot read in finding G-050
EOF
while IFS='|' read -r tag sevs currc diag; do
  sp="$X/spec-U-$tag"; mkdir -p "$sp/notes"
  round 1 CLEARED 0 1 "$(finding '### Finding G-050' dup-binding new "$(printf '%b' "$sevs")")"$'\n' > "$sp/notes/opponent.md"
  both "U-$tag" "$sp"; judge "A4 U $tag" "U-$tag" "$currc" 3 "$diag"
done < "$X/u.cases"

say '== B: manifest siblings derived from the rendered text'
cat > "$X/b.cases" <<EOF
charref-dec|${G42}- &#83;everity: data-loss\n|0|a Severity line this grammar cannot read: - &#83;everity: data-loss
charref-hex|${G42}- &#x53;everity: data-loss\n|0|a Severity line this grammar cannot read: - &#x53;everity: data-loss
comment-inline|${G42}- <!-- tier --> Severity: data-loss\n|0|a Severity line this grammar cannot read: - <!-- tier --> Severity: data-loss
second-tier-html|${G42}- **Severity:** minor\n- <b>Severity:</b> data-loss\n|0|a second Severity line in finding G-042
finding-dash-heading|### Finding ${EMD} G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n|3|a Finding heading this grammar cannot read
EOF
while IFS='|' read -r tag body currc diag; do
  sp="$X/spec-B-$tag"; mkdir -p "$sp/notes"; mani "$sp" "$(printf '%b' "$body")"$'\n'
  round 1 CLEARED 0 1 "$(finding '### Finding G-042' tier-binding open '- **Severity:** minor')"$'\n' > "$sp/notes/opponent.md"
  both "B-$tag" "$sp"; judge "B $tag" "B-$tag" "$currc" 3 "$diag"
done < "$X/b.cases"

say '== C1: the shipped plausible-manifest shapes, under a CHALLENGED round re-recording O-017 at its tier'
cat > "$X/p.cases" <<'EOF'
recorded-finding-text|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Status:** new\n- **Severity:** wrong-result\n- **Where:** scripts/verification-lib.sh:955-968\n- **The inputs.** The manifest has six lines: a heading, a Class, a Severity and a Scenario.\n- **Class-wide fix:** make every `**Severity:**` line parse by the canonical grammar\n
trailing-section|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Follow-up\n- T030o43 fixes the **Severity:** handling\n- **T001** — fix it; its **Severity:** stays data-loss\n
prose-mention|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n- **Scenario:** the **Class:** field was lost; a line written `-\302\240**Class:**` was skipped\n
finding-summary|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Finding summary\nOne finding.\n\n```text\n- **Severity:** minor\n```\n
summary-prose|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Summary\n\n- Class: harness-locale-decoding, one finding\n- Severity: all blocking\n
introduction-prose|# Prior review\n\nSeverity: every finding below is blocking.\n\n### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n
class-binding-lead-in|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n   - **Class binding.** A manifest recording the tier is read.\n
summary-with-subsection|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Summary\n\n#### Details\n\n- Severity: all blocking\n
severity-prose-inside|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n- Severity was re-read twice, once per locale.\n- **Class-wide fix:** read the status\n
notes-subheading|### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n#### Notes\nReproduced twice.\n
EOF
for row in $(cut -d'|' -f1 "$X/p.cases"); do
  body="$(grep "^$row|" "$X/p.cases" | cut -d'|' -f2-)"
  sp="$X/spec-P-$row"; mkdir -p "$sp/notes/verification/reports"; printf '%b' "$body" > "$sp/notes/verification/reports/opponent-findings-review.md"
  round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding open '- **Severity:** wrong-result')"$'\n' > "$sp/notes/opponent.md"
  both "P-$row" "$sp"; judge "C1 $row parses" "P-$row" 0 0
done
sp="$X/spec-P-class-only"; mkdir -p "$sp/notes/verification/reports"; printf '## Findings\n\n### Finding O-017\n- **Class:** harness-locale-decoding\n' > "$sp/notes/verification/reports/opponent-findings-review.md"
round 1 CHALLENGED 1 0 "$(finding '### Finding O-017' harness-locale-decoding open '- **Severity:** wrong-result')"$'\n' > "$sp/notes/opponent.md"
both P-class-only "$sp"; judge 'C1 class-only, the shipped positive the rule turns into a refusal' P-class-only 0 3 'finding O-017 has no readable Severity'
say '  the real prior-review manifest, under a CHALLENGED round re-recording each of its findings at its tier:'
sp="$X/spec-P-real"; mkdir -p "$sp/notes/verification/reports"; cp "$C/$r/opponent-findings-2026-09-09.md" "$sp/notes/verification/reports/"
body=''; for f in O-001:return-envelope-parsing:wrong-result O-002:round-authorization-grammar:wrong-result O-003:live-control-semantic-validation:wrong-result O-004:gate-report-schema-validation:wrong-result O-005:config-interpolation-validation:wrong-result O-006:post-pr-followup-binding-schema:regression; do
  IFS=: read -r id cl sv <<< "$f"; body+="$(finding "### Finding $id" "$cl" open "- **Severity:** $sv")"$'\n'
done
round 1 CHALLENGED 6 0 "$body" > "$sp/notes/opponent.md"
both P-real "$sp"; judge 'C1 the 2026-09-09 manifest parses' P-real 0 0
check 'C1 the 2026-09-09 manifest: CUR and D catalogs identical' same "$(cmp -s "$w/P-real-cur-C.nul" "$w/P-real-d-C.nul" && echo same)"

say '== C2: canonical findings that must still parse (CHALLENGED round 1, totals 1 . 0)'
cat > "$X/q.cases" <<'EOF'
notes-subheading|### Finding G-042|- **Severity:** data-loss|#### Notes\nReproduced twice, once per locale.\n
details-subheading-with-prose|### Finding G-042|- **Severity:** data-loss|#### Details\n- **The manifest member.** A heading carries the tier.\n
titled-heading|### Finding G-042 — tier read|- **Severity:** data-loss|
class-binding-lead-in|### Finding G-042|- **Severity:** data-loss|  - **Class binding.** The record is read.\n  - Severity was re-read twice.\n
quoted-example|### Finding G-042|- **Severity:** data-loss|  - The lines `#### Severity: data-loss` and `- <b>Severity:</b> minor` are refused.\n
EOF
while IFS='|' read -r tag heading sevs extra; do
  sp="$X/spec-Q-$tag"; mkdir -p "$sp/notes"
  round 1 CHALLENGED 1 0 "$(finding "$heading" tier-binding new "$sevs" "$(printf '%b' "$extra")"$'\n')"$'\n' > "$sp/notes/opponent.md"
  both "Q-$tag" "$sp"; judge "C2 $tag parses" "Q-$tag" 0 0
done < "$X/q.cases"
say '  recorded consequence, the safe direction: a line inside a finding that BEGINS with a code span holding a label is refused'
sp="$X/spec-Q-codespan-lead"; mkdir -p "$sp/notes"
round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss' '  - `#### Severity: data-loss` is the heading form.'$'\n')"$'\n' > "$sp/notes/opponent.md"
both Q-codespan-lead "$sp"; judge 'C2 codespan-lead' Q-codespan-lead 0 3 'a Severity line this grammar cannot read in finding G-042'
sp="$X/spec-Q-heldup-prose"; mkdir -p "$sp/notes"
held="- Severity: all blocking, as recorded."$'\n'"- **The spec is right.** Nothing else held."
round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n' '' '' '' "$held" > "$sp/notes/opponent.md"
both Q-heldup-prose "$sp"; judge 'C2 Held-up prose after the last finding parses' Q-heldup-prose 0 0
sp="$X/spec-Q-field-after-section"; mkdir -p "$sp/notes"
round 1 CHALLENGED 1 0 "$(finding '### Finding G-042' tier-binding new '- **Severity:** data-loss')"$'\n' '' '' '' "- **Severity:** minor" > "$sp/notes/opponent.md"
both Q-field-after-section "$sp"; judge 'C2 a field line after a section heading' Q-field-after-section 3 3 'a finding field outside any Finding'

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
      done
    done
    for kind in tally an cov; do
      check "D $spec $kind under $l: CUR and D identical (output and exit)" same "$(cmp -s "$w/H-$kind-$spec-cur-$l.log" "$w/H-$kind-$spec-d-$l.log" && echo same)"
    done
    say "  | $spec under $l: tally exit $(tail -1 "$w/H-tally-$spec-d-$l.log"), analyzer exit $(tail -1 "$w/H-an-$spec-d-$l.log"), ac-coverage exit $(tail -1 "$w/H-cov-$spec-d-$l.log")"
    for g in opponent reality-check; do
      [[ -f "$w/H-cat-$spec-$g-cur-$l.err" ]] || continue
      check "D $spec $g catalog under $l: CUR and D identical" same "$(cmp -s "$w/H-cat-$spec-$g-cur-$l.nul" "$w/H-cat-$spec-$g-d-$l.nul" && echo same)"
      check "D $spec $g diagnostics and exit under $l: CUR and D identical" same "$(cmp -s "$w/H-cat-$spec-$g-cur-$l.err" "$w/H-cat-$spec-$g-d-$l.err" && echo same)"
      say "  |   $g catalog: exit $(tail -1 "$w/H-cat-$spec-$g-d-$l.err"), $(tr '\0' '\n' < "$w/H-cat-$spec-$g-d-$l.nul" | grep -c -x finding) finding records"
    done
  done
done
for n in 13 14; do
  for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"; ( cd "$K" && bash scripts/spec-gate.sh waiver "$s" opponent "$n" < /dev/null ) > "$w/H-w$n-$k.log" 2>&1; echo $? >> "$w/H-w$n-$k.log"; done
  check "D waiver check for round $n: CUR and D identical" same "$(cmp -s "$w/H-w$n-cur.log" "$w/H-w$n-d.log" && echo same)"
done
check 'D waiver round 14 still refused (exit 4)' 4 "$(tail -1 "$w/H-w14-d.log")"
for k in cur d; do K="$C"; [[ "$k" == d ]] && K="$D"
  ( cd "$K" && bash -c '. scripts/verification-lib.sh && vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$w/H-snap-$k.nul" ) > "$w/H-snap-$k.out" 2>&1
  tr '\0' '\n' < "$w/H-snap-$k.nul" | paste - - - - - - | sed "s#$K#KIT#g" | LC_ALL=C grep -v -F 'scripts/verification-lib.sh' > "$w/H-snap-$k.tsv"
done
check 'D snapshot records outside verification-lib.sh identical (kit path normalized)' same "$(cmp -s "$w/H-snap-cur.tsv" "$w/H-snap-d.tsv" && echo same)"
say "  | snapshot: CUR $(head -c 16 "$w/H-snap-cur.out"), D $(head -c 16 "$w/H-snap-d.out"), records compared $(wc -l < "$w/H-snap-d.tsv" | tr -d ' ')"

say '== E: the full suite and ShellCheck on D (plain locale, TMPDIR ending in /)'
( cd "$D" && bash tests/run.sh < /dev/null ) > "$w/E-suite.log" 2>&1; echo $? > "$w/E-suite.rc"
( cd "$D" && bash tests/shellcheck.sh < /dev/null ) > "$w/E-shellcheck.log" 2>&1; echo $? > "$w/E-shellcheck.rc"
say "  | suite rc=$(cat "$w/E-suite.rc"); shellcheck rc=$(cat "$w/E-shellcheck.rc")"
grep -E '^  -- [0-9]+/[0-9]+ passed|^  FAIL ' "$w/E-suite.log" | sed 's/^/  | /'
grep -E '^       assert' "$w/E-suite.log" | LC_ALL=C cut -c1-200 | sed 's/^/  |   /'
check 'E ShellCheck on D passes' 0 "$(cat "$w/E-shellcheck.rc")"
cp "$w/E-suite.log" "$WT/$r/o018-measure-suite.log"

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "o018-measure failures=$fails"
cd "$SP" && rm -rf "$X"
(( fails == 0 ))
