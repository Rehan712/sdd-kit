#!/usr/bin/env bash
# T030o51, T030o52 and T030o53 mutation matrix v6, 2026-10-13 (session 20), from r17-mutations.sh (v5, kept with its
# runs), built by r18-mutations-gen.py: every guard of T030o44 to T030o50 as v5 judged it, with the rows whose literals
# the repair rewrote re-targeted (the narrowed check's call in each pass, the raw-HTML reason, the run-end reset, the
# settled test now read up to each reading's first word), and a row for every guard the repair adds, each the mutant
# the discovery probe measured (r18-discover-mutants.py, r18-discover-{a,b,c}.log) and judged by the fixture row it
# names (tgc-1, or the rows tgc-2 and tgc-3 add, judged by r18-fixtures-judge-2 run 4 and r18-fixtures-judge-3): the
# autolink class and its reason; the
# destination, title and label reader (vf_cm_dest, vf_cm_label) and its two reasons; the fence and definition reasons
# with the carried label; the narrowed check judged after a line's own heading in both passes; the settled test read
# up to each reading's first word. Rows marked equiv are argued beside them. Each in a standalone copy built from the
# live manifest enumeration, every judge under a TMPDIR ending in `/`, in its own process group under a watchdog
# (900 s by default) that stops it whole and counts it failed with the diagnostic `watchdog: judge stopped after`.
# Harness: t030o43-mutations.sh, as v2.
# Usage: bash r18-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n] [ONLY=id,id...] [WATCHDOG=seconds, 900]
# Kinds: kill  -- the judge must FAIL and print the named diagnostic;
#        over  -- an over-correction mutant: the judge must FAIL on a positive and print the named diagnostic;
#        equiv -- the judge must PASS, with the argument recorded beside the row.
# A judge is one fixture function run alone, as t_run_all runs a test (a fresh SANDBOX, the build-failure record
# checked). Each mutant is a literal replacement that must match exactly once (DRY=1 checks only that). Every
# restore is checked byte-identical with cmp against a pristine copy.
set -uo pipefail
set -m  # each judge runs in its own process group, which the watchdog stops whole
SP="$1"; WT="$2"; DRY="${DRY:-0}"; SHARD="${SHARD:-0/1}"; ONLY="${ONLY:-}"; WATCHDOG="${WATCHDOG:-900}"
si="${SHARD%/*}"; sn="${SHARD#*/}"
R="$SP/r18-matrix-$si"; C="$R/copy"; P="$R/pristine"; w="$R/work"
export TMPDIR="$R/tmp/"
rm -rf "$R"; mkdir -p "$C" "$P" "$w" "$TMPDIR"
fails=0; rowi=0
say() { printf '%s\n' "$*"; }
verdict() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul" || { say 'FAIL enumeration'; exit 2; }
for d in "$C" "$P"; do ( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$d" && tar -xf - ) || { say 'FAIL extraction'; exit 2; }; done
( cd "$C" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid -c core.hooksPath=/dev/null commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
printf 'tests/.one-*.sh\n' >> "$C/.git/info/exclude"
EDITED=(scripts/verification-lib.sh tests/test-gate-contracts.sh tests/test-spec-gate.sh)

replace() { # <file> <old> <new>: literal, exactly once
  perl -e '
    my ($f, $old, $new) = @ARGV; local $/; open my $h, "<", $f or exit 3; my $t = <$h>; close $h;
    my $n = () = $t =~ /\Q$old\E/g; exit 4 if $n != 1;
    exit 0 if $ENV{DRY} eq "1";
    $t =~ s/\Q$old\E/$new/; open $h, ">", $f or exit 3; print $h $t; close $h; exit 0' "$C/$1" "$2" "$3"
}
judge() { # <test file> <case function> -> exit (124 when the watchdog stopped it); output in $w/judge.out
  ( cd "$C" && awk '$0 != "t_run_all"' "tests/$1" > "tests/.one-$1" && bash -c '. "tests/.one-$1"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out"; exit "$rc"' _ "$1" "$2" ) > "$w/judge.out" 2>&1 &
  local pid=$! n=0
  while kill -0 "$pid" 2>/dev/null; do
    if (( n++ >= WATCHDOG )); then
      kill -TERM -- "-$pid" 2>/dev/null; sleep 2; kill -KILL -- "-$pid" 2>/dev/null; wait "$pid" 2>/dev/null
      echo "watchdog: judge stopped after ${WATCHDOG} s" >> "$w/judge.out"; return 124
    fi
    sleep 1
  done
  wait "$pid"
}
restore() {
  ( cd "$C" && git checkout -q -- . && rm -f tests/.one-*.sh ) || return 1
  local f; for f in "${EDITED[@]}"; do
    cmp -s "$C/$f" "$P/$f" || { say "FAIL restore not byte-identical: $f"; fails=$((fails+1)); }
  done
}
row() { # <id> <kind> <diagnostic-or-empty> <test file> <case> <file old new>...
  local id="$1" kind="$2" diag="$3" tf="$4" case="$5" rc; shift 5
  rowi=$((rowi+1)); (( (rowi - 1) % sn == si )) || return 0
  [[ -z "$ONLY" || ",$ONLY," == *",$id,"* ]] || return 0
  while (( $# )); do
    replace "$1" "$2" "$3"; rc=$?
    verdict "$id literal applies once in $1" 0 "$rc"
    shift 3
  done
  [[ "$DRY" == 1 ]] && { restore; return; }
  judge "$tf" "$case"; rc=$?
  case "$kind" in
    kill|over)
      verdict "$id KILLED ($kind, judge rc)" 1 "$([[ "$rc" != 0 ]] && echo 1 || echo 0)"
      verdict "$id diagnostic: $diag" 1 "$(grep -c -F -- "$diag" "$w/judge.out" | awk '{print ($1 > 0)}')";;
    equiv) verdict "$id SURVIVES as argued (equiv)" 0 "$rc";;
  esac
  [[ "$rc" == 0 || "$kind" != equiv ]] || grep -E 'assert:' "$w/judge.out" | head -5 | sed 's/^/  |   /'
  restore
}
VL=scripts/verification-lib.sh
GC=test-gate-contracts.sh; SG=test-spec-gate.sh
RL=report_record_line_cases; ML=report_manifest_locale_cases; RR=round_record_line_cases; ST=report_round_style_cases
FIELDS='(Class|Status|Prior|Severity|Where|Root cause|Scenario|Reproduced|Blocks|Wrong behavior|Class-wide fix)'

say "== baseline shard $SHARD $(date -u +%H:%M:%SZ)"
if [[ "$DRY" != 1 && "$si" == 0 ]]; then
  for j in "$GC $RL" "$GC $ML" "$GC $ST" "$GC report_prior_binding_cases" "$GC report_severity_tier_cases" "$GC shipped_002_tally_case" \
           "$SG $RR" "$SG round_locale_cases"; do
    judge ${j% *} ${j#* }; verdict "B ${j#* } unmutated passes" 0 "$?"
    grep -E 'assert:' "$w/judge.out" | head -3 | sed 's/^/  |   /'
    restore
  done
fi


say '== the label reader (vf_label_word, vf_label_html, vf_label_links, vf_label_render, vf_label, vf_finding_heading)'
LR='a manifest tier written as'; LS='was not refused by name under LANG=C (O-018)'
row L01 kill "$LR second-tier-comment-holding-gt $LS" "$GC" "$RL" \
  "$VL" '    if (substr(rest, 1, 4) == "<!--") {n = index(substr(rest, 3), "-->"); s = n ? substr(rest, n + 5) : ""; continue}'$'\n' ''
row L01b over 'a plausible manifest (outside-comment-closer) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '{n = index(substr(rest, 3), "-->"); s = n ? substr(rest, n + 5) :' '{n = index(substr(rest, 5), "-->"); s = n ? substr(rest, n + 7) :'
# L01b (v5): inside a finding a comment is raw HTML and refused by name (T030o48), so its row moved outside every
# finding: a manifest line after a finding ID whose label the comment closer decides (r17-edits/tgc-2.pairs).
row L02 kill "$LR html-tag $LS" "$GC" "$RL" \
  "$VL" '    if (match(rest, vf_lbl_tag) || match(rest, /^<\/[A-Za-z][A-Za-z0-9-]*[ \t]*>/)) {s = substr(rest, RLENGTH + 1); continue}'$'\n' ''
row L02b kill "$LR second-tier-quoted-gt $LS" "$GC" "$RL" \
  "$VL" '"|\"[^\"]*\"))?)*' '"|\"[^\">]*\"))?)*'
row L02c kill "$LR second-tier-closing-tag $LS" "$GC" "$RL" \
  "$VL" ' || match(rest, /^<\/[A-Za-z][A-Za-z0-9-]*[ \t]*>/)' ''
row L02d kill "$LR second-tier-processing-instruction $LS" "$GC" "$RL" \
  "$VL" '    if (substr(rest, 1, 2) == "<?") {n = index(substr(rest, 3), "?>"); s = n ? substr(rest, n + 4) : ""; continue}'$'\n' ''
row L02e kill "$LR second-tier-declaration $LS" "$GC" "$RL" \
  "$VL" '    if (rest ~ /^<![A-Za-z]/) {n = index(rest, ">"); s = n ? substr(rest, n + 1) : ""; continue}'$'\n' ''
row L02f kill "$LR second-tier-cdata $LS" "$GC" "$RL" \
  "$VL" '    if (substr(rest, 1, 9) == "<![CDATA[") {n = index(rest, "]]>"); s = n ? substr(rest, n + 3) : ""; continue}'$'\n' ''
row L03 kill "$LR character-reference $LS" "$GC" "$RL" \
  "$VL" $'  while (match(s, /&#[0-9]+;|&#[xX][0-9A-Fa-f]+;/)) {\n' $'  while (0) {\n'
row L04 kill "$LR character-reference $LS" "$GC" "$RL" \
  "$VL" '    n = (t ~ /^[xX]/) ? vf_label_hex(substr(t, 2)) : t + 0' '    n = t + 0'
row L05 equiv '' "$GC" "$RL" \
  "$VL" '((n > 32 && n < 127) ? sprintf("%c", n) : ((hide && n > 126) ? "" : "\001"))' 'sprintf("%c", n)'
# L05 argued (v1): every byte the range keeps out is not an ASCII letter, so the word rule reads it as a
# non-letter either way, and no fixture writes a reference to one.
row L10 kill "$LR second-tier-named-reference $LS" "$GC" "$RL" \
  "$VL" '  gsub(/&[A-Za-z][A-Za-z0-9]*;/, hide ? "" : "\001", s)'$'\n' ''
row L11 kill "$LR second-tier-footnote $LS" "$GC" "$RL" \
  "$VL" '  gsub(/\[\^[^]]*\]/, "\001", s)'$'\n' ''
row L12 kill "$LR second-tier-empty-link $LS" "$GC" "$RL" \
  "$VL" '  s = vf_label_links(s)'$'\n' ''
row L13 kill "$LR second-tier-image $LS" "$GC" "$RL" \
  "$VL" '(b ? "\001" : "\001" inner "\001")' '("\001" inner "\001")'
row L14 kill "$LR second-tier-reference-link $LS" "$GC" "$RL" \
  "$VL" '    else if (substr(s, j, 1) == "[" && (k = index(substr(s, j + 1), "]"))) m = j + k + 1'$'\n' ''
row L15 kill "$LR second-tier-nested-destination $LS" "$GC" "$RL" \
  "$VL" $'      if (c == "(") depth++\n      else if (c == ")") {if (!depth) break; depth--}\n      j++\n    }\n  }\n' $'      if (0) depth++\n      else if (c == ")") {if (!depth) break; depth--}\n      j++\n    }\n  }\n'
row L16 kill "$LR second-tier-link-title $LS" "$GC" "$RL" \
  "$VL" '  if (c == "\"" || c == vf_lbl_q || c == "(") {' '  if (0) {'
row L17 kill "$LR second-tier-footnote-literal $LS" "$GC" "$RL" \
  "$VL" '  return (w != "") ? w : vf_label_word(s, labels)' '  return w'
# L17 (session 16): run 1 of v4 (r16-mutations-run1-shard0) found its code-span-tag row read by T030o47's code-span
# reading too, so the mutant survived; the row added by r16-edits/tgc-2.pairs, a tier behind an undefined footnote
# reference that renderers show literally, is read by the reading as written alone (r16-fixtures-judge-2).
row L18 kill "$LR second-tier-tag-then-reference $LS" "$GC" "$RL" \
  "$VL" '  w = vf_label_word(vf_label_render(s, 0), labels)' '  w = ""'
# L18 (session 15): the probe (r14-mutations-probe.*, run on r14-mutations-v3-probe.sh) found the html-tag row
# passing for the wrong reason, since the second rendered reading also strips HTML; the row added by
# r14-edits/tgc-2.pairs, a tier behind a closing tag and a named reference, is read by the first reading alone.
row L19 equiv '' "$GC" "$RL" \
  "$VL" '"-->"); s = n ? substr(rest, n + 5) : ""; continue}' '"-->"); s = n ? substr(rest, n + 5) : substr(rest, 5); continue}'
# L19 argued: an opener that does not close on its line hides the rest of the rendered reading; the mutant keeps
# that rest instead, which the reading as written already reads (its prefix skip steps over `<!--`), so the two
# can differ only where markup that renders nothing follows the opener, and there only toward a refusal.
row L06 kill 'a finding opened by level-four was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'  return t ~ /^[A-Za-z][A-Za-z0-9]*-[0-9]/\n}' $'  return 0\n}'
row L07 kill 'a finding opened by tab-after-hashes was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '  t = s; sub(/^ *#+/, "", t); sub(/^([[:space:]]|[\200-\377])+/, "", t)' '  t = s; sub(/^ *#+/, "", t)'
row L08 over 'a canonical finding with a-findings-word was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" ' || substr(t, 8, 1) ~ /[A-Za-z0-9]/) return 0' ') return 0'
row L09 over 'a canonical finding with a-lead-in was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'  sub(/^[*_[:space:]]+/, "", t)\n  return (t ~ /^[A-Za-z0-9-]/) ? "" : w\n}' $'  return w\n}'
say '== T030o43 rows carried to their spelling in vf_label_word'
row M19 kill 'a manifest spelled lowercase-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" '  w = tolower(substr(t, 1, RLENGTH)); if (!index(' '  w = substr(t, 1, RLENGTH); w = (w == "Class" || w == "Severity") ? tolower(w) : ""; if (!index('
# N02 and N32 (session 15): matrix run 1 (r14-mutations-run1-shard0.*) killed both mutants, each with another row's
# assertion: T030o46's second rendered reading drops every byte outside ASCII, so it reads the fullwidth colon
# and the U+2022 bullet spellings too, and those rows no longer isolate these guards. bare-class-word judges N02
# (a label word that ends its line); checkbox-severity judges N32, and a narrower mutant that keeps the checkbox
# skip is killed by the heading-label rows of report_record_line_cases (a `#` lead), so that branch stays isolated.
row N02 kill 'a manifest spelled bare-class-word was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'  sub(/^[*_[:space:]]+/, "", t)\n  return (t ~ /^[A-Za-z0-9-]/) ? "" : w' $'  sub(/^[*_]+/, "", t)\n  return (substr(t, 1, 1) == ":") ? w : ""'
row N04 kill 'a manifest spelled separatorless-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'  if (emph && t ~ /^[*_]/) return w\n' ''
row N33 kill 'a manifest spelled multiword-emphasized-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'  if (emph && t !~ /^[A-Za-z0-9-]/) {\n    span = t; sub(/[*_].*$/, "", span)\n    if (span ~ /:[[:space:]]*$/) return w\n    rest = substr(t, length(span) + 1)\n    if (rest ~ /^[*_]/) {sub(/^[*_]+/, "", rest); if (rest ~ /^:/) return w}\n  }\n' ''
row N03 kill 'a manifest spelled ordered-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" 'while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\[[ xX]\])/) {'$'\n''    if (match(t, /^([0-9]+[.)]|\[[ xX]\])/)) {lead' 'while (t ~ /^([^A-Za-z0-9]|\[[ xX]\])/) {'$'\n''    if (match(t, /^([0-9]+[.)]|\[[ xX]\])/)) {lead'
row N32 kill 'a manifest spelled checkbox-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" 'while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\[[ xX]\])/) {'$'\n''    if (match(t, /^([0-9]+[.)]|\[[ xX]\])/)) {lead' 'while (t ~ /^([[:space:]*+_-]|[0-9]+[.)])/) {'$'\n''    if (match(t, /^([0-9]+[.)]|\[[ xX]\])/)) {lead'

say '== the record shapes a quoted line may carry (vf_record) and the quoted-record refusal'
row R01 kill "$LR second-tier-fenced $LS" "$GC" "$RL" \
  "$VL" '  if (l != "") return (l == "class") ? "Class line" : "Severity line"'$'\n' ''
row R02 kill 'a second tier written as quoted-status was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '  if (s ~ /^[ ]*-[[:space:]]+\*\*(Class|Status|Prior|Severity|Where|Root cause|Scenario|Reproduced|Blocks|Wrong behavior|Class-wide fix):\*\*/) return "finding field line"'$'\n' ''
row R03 kill "$LR hidden-finding $LS" "$GC" "$RL" \
  "$VL" '  if (s ~ /^ ? ? ?#+([ \t]|$)/) return (vf_finding_heading(s) || s ~ /^### Finding /) ? "Finding heading" : ""' '  if (s ~ /^ ? ? ?#+([ \t]|$)/) return ""'
row R03b equiv '' "$GC" "$RL" \
  "$VL" '(vf_finding_heading(s) || s ~ /^### Finding /) ? "Finding heading"' 'vf_finding_heading(s) ? "Finding heading"'
# R03b argued: a `### Finding` heading whose text holds no finding ID opens, unquoted, a canonical finding every
# rule refuses as incomplete, so it never carries a counted tier; quoted, hiding it hides nothing countable, and a
# record line under it inside a finding is refused on its own.
row R04 kill 'a hidden Finding heading behind a U+00A0 was skipped (T030o44 review)' "$GC" "$RL" \
  "$VL" '  if (s ~ /^([[:space:]]|[\200-\377])*#+([[:space:]]|[\200-\377])*[Ff][Ii][Nn][Dd][Ii][Nn][Gg]([^A-Za-z]|$)/) return "Finding heading"'$'\n' ''
row Q01 kill "$LR second-tier-fenced $LS" "$GC" "$RL" \
  "$VL" 'if (shape != "" && (id != "" || shape == "Finding heading")) bad(' 'if (0) bad('
row Q02 kill "$LR hidden-finding-outside $LS" "$GC" "$RL" \
  "$VL" '(id != "" || shape == "Finding heading")' '(id != "")'
row Q03 over 'a plausible manifest (finding-summary) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '(id != "" || shape == "Finding heading")' '(1)'
row Q04 kill 'a second tier written as second-tier-fenced was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '        if (shape != "" && (fid != "" || shape == "Finding heading")) err("quoted content carries a " shape)'$'\n' ''
row Q04e kill 'a CLEARED completion over a second tier written as - **Severity:** minor\n\n<!-->' "$SG" "$RR" \
  "$VL" '        if (shape != "" && (fid != "" || shape == "Finding heading")) err("quoted content carries a " shape)'$'\n' ''
row Q05 kill 'a Finding heading hidden in a Held-up section was skipped (T030o44 review)' "$GC" "$RL" \
  "$VL" '(fid != "" || shape == "Finding heading")' '(fid != "")'
row Q06 over 'expected exit 0, got 3: record_line_vf C' "$GC" "$RL" \
  "$VL" '(fid != "" || shape == "Finding heading")' '(1)'
row Q07 kill 'a canonical rule reached a legacy round, or the round lost its Blocks (T030o44 review F6)' "$GC" "$RL" \
  "$VL" '      else if (style=="canonical" && active) {' '      else if (active) {'
row Q08 equiv '' "$GC" "$RL" \
  "$VL" '      else if (style=="canonical" && active) {' '      else if (style=="canonical") {'
# Q08 argued, on the premise round 14 corrected (v2 argued it from "style is set only by a round heading", which
# O-020 refuted: the title and the Timestamp line set it too): style becomes canonical only at a round heading,
# which sets active, or at a Timestamp line, which is read only in an active round (an identity line outside one is
# refused before it can set the style); active is cleared only by flush, which runs at the next round heading,
# which sets it again, or at END. So while lines are read, a canonical style means an active round.

say '== the field-item rule (vf_block_start and both passes)'
MI='          if (substr($0, ii + 1, 1) == "\t" || '
CI='Class-wide fix):\*\*/)'$'\n''        if (substr($0, ii + 1, 1) == "\t" || '
row I01 kill "$LR value-continued $LS" "$GC" "$RL" "$VL" "$MI(!fl" '          if (0 && (!fl'
row I02 kill 'a second tier written as value-continued was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "$CI(!fl" 'Class-wide fix):\*\*/)'$'\n''        if (0 && (!fl'
row I02e kill 'a CLEARED completion over a second tier written as - **Severity:** minor\n  data-loss' "$SG" "$RR" \
  "$VL" "$CI(!fl" 'Class-wide fix):\*\*/)'$'\n''        if (0 && (!fl'
row I03 over 'a manifest field line after White_Space character 1 was not read under LANG=C (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 'fl=($0 ~ /^[ ]*-[[:space:]]+\*\*(Class|Severity):\*\*/)' 'fl=0'
row I04 over 'expected exit 0, got 3: record_line_vf C' "$GC" "$RL" \
  "$VL" 'fl=($0 ~ /^[ ]*- \*\*(Class|Status|Prior|Severity|Where|Root cause|Scenario|Reproduced|Blocks|Wrong behavior|Class-wide fix):\*\*/)' 'fl=0'
row I05 over 'a plausible manifest (severity-then-blank-and-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" "$MI(!fl && (ii >= itemind + 2 || (!itemblank && " "$MI(!fl && (ii >= itemind + 2 || (1 && "
row I06 over 'expected exit 0, got 3: record_line_vf C' "$GC" "$RL" \
  "$VL" "$CI(!fl && (ii >= itemind + 2 || (!itemblank && " "$CI(!fl && (ii >= itemind + 2 || (1 && "
row I07 kill 'a Status continued past its line was read without its continuation under LANG=C (T030o44 review)' "$GC" "$RL" \
  "$VL" '(Class|Severity|Status)$/) {itemfield=' '(Class|Severity)$/) {itemfield='
row I08 kill 'a canonical rule reached a legacy round, or the round lost its Blocks (T030o44 review F6)' "$GC" "$RL" \
  "$VL" 'if (style=="canonical" && key ~ /^- \*\*(Class' 'if (key ~ /^- \*\*(Class'
row I09 kill "$LR class-value-continued $LS" "$GC" "$RL" \
  "$VL" '; itemfield="Class"; itemind=match($0, /[^ ]/) - 1; itemblank=0; itemid=id' ''
row I10 kill "$LR value-tab-paragraph $LS" "$GC" "$RL" "$VL" "$MI" '          if ('
row I11 kill 'a second tier written as value-tab-paragraph was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "$CI" 'Class-wide fix):\*\*/)'$'\n''        if ('
row I12 kill "$LR value-continued $LS" "$GC" "$RL" \
  "$VL" '; itemfield="Severity"; itemind=match($0, /[^ ]/) - 1; itemblank=0; itemid=id' ''
row I13 kill "$LR value-second-paragraph $LS" "$GC" "$RL" \
  "$VL" "$MI(!fl && (ii >= itemind + 2 || " "$MI(!fl && (0 || "
row I14 kill 'a second tier written as value-second-paragraph was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "$CI(!fl && (ii >= itemind + 2 || " "$CI(!fl && (0 || "
row B01 over 'a plausible manifest (recorded-finding-text) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  if (t ~ /^[-+*][ \t]+[^ \t]/ || t ~ /^1[.)][ \t]+[^ \t]/) return 1' '  if (t ~ /^1[.)][ \t]+[^ \t]/) return 1'
row B02 over 'a plausible manifest (severity-then-ordered-one) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" ' || t ~ /^1[.)][ \t]+[^ \t]/) return 1' ') return 1'
row B03 over 'a plausible manifest (severity-then-heading) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  if (t ~ /^(#|##|###|####|#####|######)([ \t]|$)/ || t ~ /^>/' '  if (t ~ /^>/'
row B04 over 'a plausible manifest (severity-then-blockquote) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" ' || t ~ /^>/ || t ~ /^<!--/' ' || t ~ /^<!--/'
row B05 equiv '' "$GC" "$ML" \
  "$VL" ' || t ~ /^<!--/ || t ~ /^~~~/' ' || t ~ /^~~~/'
# B05 argued (v5): inside a finding, where the field-item rule asks vf_block_start, every line this clause admits
# begins with `<` and a letter, `/`, `!` or `?` outside any code span, so it is refused by name as raw HTML outside a
# code span (T030o48) whatever the item rule reads; the clause decides only whether a second diagnostic names the item.
row B06 over 'a plausible manifest (severity-then-tilde-fence) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" ' || t ~ /^~~~/ || vf_raw_start(t)) return 1' ' || vf_raw_start(t)) return 1'
row B07 equiv '' "$GC" "$ML" \
  "$VL" ' || vf_raw_start(t)) return 1' ') return 1'
# B07 argued (v5): inside a finding, where the field-item rule asks vf_block_start, every line this clause admits
# begins with `<` and a letter, `/`, `!` or `?` outside any code span, so it is refused by name as raw HTML outside a
# code span (T030o48) whatever the item rule reads; the clause decides only whether a second diagnostic names the item.
row B08 over 'a plausible manifest (severity-then-fenced-block) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  if (t ~ ("^" b b b b "*[^" b "]*$")) return 1'$'\n' ''
row B09 over 'a plausible manifest (severity-then-thematic-break) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  return (t ~ /^(\*[ \t]*\*[ \t]*\*[* \t]*|-[ \t]*-[ \t]*-[- \t]*|_[ \t]*_[ \t]*_[_ \t]*)$/)' '  return 0'
row B10 kill "$LR value-ordered-two $LS" "$GC" "$RL" \
  "$VL" '/^1[.)][ \t]+[^ \t]/' '/^[0-9]+[.)][ \t]+[^ \t]/'
row B11 kill "$LR value-backtick-info-fence $LS" "$GC" "$RL" \
  "$VL" '("^" b b b b "*[^" b "]*$")' '("^" b b b b "*.*$")'
row B12 equiv '' "$GC" "$RL" \
  "$VL" '/^[-+*][ \t]+[^ \t]/' '/^[-+*]/'
# B12 argued: the mutant also takes a bullet with no text, at less than the item's content indentation, as ending the
# field's item; such a line is an empty list item or a sibling's marker, which adds no text to the field's value
# either way, and a deeper one is judged by the indentation branch before vf_block_start is asked.

say '== the manifest pass'
# Carried from T030o43 v5 unchanged in literal: these seven survived on the T030o44 tree (t030o44-o43matrix-shard{0,1})
# because T030o44's Severity requirement refused their fixtures first; the table now asserts each row's own
# diagnostic (fixtures-2.pl), which is what judges them here.
row M06 kill 'a manifest spelled field-outside-finding was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'          if (strict || idseen || $0 ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) bad("a " field " line outside any Finding")\n' ''
row M13 kill 'a manifest spelled no-class-beside-another was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'        if(id!="" && cls=="") bad("finding " id " has no readable Class")\n' ''
row M14 kill 'a manifest spelled fence-left-open was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'        if (fenced) bad("a code fence is left open")\n' ''
row M15 kill 'a manifest spelled comment-left-open was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'        if (commented) bad("an HTML comment is left open")\n' ''
row M16 kill 'a manifest spelled raw-block-left-open was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'        if (rawkind) bad("a raw HTML block is left open")\n' ''
row K01 kill 'a manifest tier written as no-tier was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'        if(id!="" && !severities) bad("finding " id " has no readable Severity")\n' ''
row K01e kill 'a CLEARED completion over a manifest tier written as > - **Severity:** data-loss was not refused under LANG=C (O-018)' "$SG" "$RR" \
  "$VL" $'        if(id!="" && !severities) bad("finding " id " has no readable Severity")\n' ''
row K02 kill 'a manifest field line under a sub-heading (notes-sub-heading) was not read under LANG=C (O-019)' "$GC" "$RL" \
  "$VL" '        if (id == "" || hl <= flevel) {' '        if (1) {'
row K03 kill 'a manifest tier written as dash-separated-heading was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'        if (vf_finding_heading($0)) {flushm(); idseen=1; bad("a Finding heading this grammar cannot read"); next}\n' ''
row K04 over 'a manifest field line under a sub-heading (finding-summary-sub-heading) was not read under LANG=C (O-019)' "$GC" "$RL" \
  "$VL" $'      }\n      !/^ ? ? ?#+([ \\t]|$)/ && /^([[:space:]]|[\\200-\\377])*#+' $'      }\n      /^([[:space:]]|[\\200-\\377])*#+'
row K05 kill 'a manifest tier written as heading-label was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'          idseen=(heading ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) || tolower(word[2]) == "finding"\n          next\n        }\n        if (vf_narrow != "") bad(vf_narrow " in finding " id)\n      }' $'          idseen=(heading ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) || tolower(word[2]) == "finding"\n          next\n        }\n        if (vf_narrow != "") bad(vf_narrow " in finding " id)\n        next\n      }'
row N05 kill 'a manifest spelled nbsp-after-hashes-below-class-only was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'      !/^ ? ? ?#+([ \\t]|$)/ && /^([[:space:]]|[\\200-\\377])*#+([[:space:]]|[\\200-\\377])*[Ff][Ii][Nn][Dd][Ii][Nn][Gg]([^A-Za-z]|$)/ {\n        flushm(); idseen=1; bad("a Finding heading this grammar cannot read"); next\n      }\n' ''
row K06 kill 'a manifest tier written as subheading-then-hidden-finding was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'      !/^ ? ? ?#+([ \\t]|$)/ && /^([[:space:]]|[\\200-\\377])*#+([[:space:]]|[\\200-\\377])*[Ff][Ii][Nn][Dd][Ii][Nn][Gg]([^A-Za-z]|$)/ {\n        flushm(); idseen=1; bad("a Finding heading this grammar cannot read"); next\n      }\n' ''
row M23 kill 'a manifest finding spelled before-another was dropped (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'          flushm(); idseen=1\n          if (word[3]' $'          idseen=1\n          if (word[3]'

say '== the canonical pass'
row C01 kill 'a finding opened by level-four was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'    style=="canonical" && !ended && /^ ? ? ?#+([ \\t]|$)/ && vf_finding_heading($0) {err("a Finding heading this grammar cannot read"); next}\n' ''
row C01e kill 'a CLEARED round 2 under #### Finding G-042 was not refused under LANG=C (O-018)' "$SG" "$RR" \
  "$VL" $'    style=="canonical" && !ended && /^ ? ? ?#+([ \\t]|$)/ && vf_finding_heading($0) {err("a Finding heading this grammar cannot read"); next}\n' ''
row C02 kill 'a finding opened by no-break-space-before-hashes was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'    style=="canonical" && !ended && !/^ ? ? ?#+([ \\t]|$)/ && /^([[:space:]]|[\\200-\\377])*#+' $'    0 && /^([[:space:]]|[\\200-\\377])*#+'
row C03 kill 'a field line after a section heading was read into the finding above it (O-018)' "$GC" "$RL" \
  "$VL" $'    style=="canonical" && fid && /^ ? ? ?(#|##|###)([ \\t]|$)/ {finding()}\n' ''
row C04 kill 'a finding opened by bold-line was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "    style==\"canonical\" && !ended && !fid && /^[ ]*- \\*\\*$FIELDS:\\*\\*/ {err(\"a finding field outside any Finding\"); next}"$'\n' ''
row C05 kill 'a second tier written as unread-first was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '      if (lbl != "") err(' '      if (0) err('
row C06 kill 'a second tier written as indented-second was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '      key=$0; sub(/:\*\*.*/,"",key); sub(/^[ ]*/,"",key)' '      key=$0; sub(/:\*\*.*/,"",key)'
row C07 kill '#### Finding G-043 after the completion marker lost the after-marker refusal (T030o44)' "$GC" "$RL" \
  "$VL" '    style=="canonical" && !ended && /^ ? ? ?#+([ \t]|$)/ && vf_finding_heading($0)' '    style=="canonical" && /^ ? ? ?#+([ \t]|$)/ && vf_finding_heading($0)'
row C08 kill '- **Severity:** minor after the completion marker lost the after-marker refusal (T030o44)' "$GC" "$RL" \
  "$VL" '    style=="canonical" && !ended && !fid && ' '    style=="canonical" && !fid && '
row C09 kill 'after the completion marker lost the after-marker refusal (T030o44)' "$GC" "$RL" \
  "$VL" '    style=="canonical" && !ended && !/^ ? ? ?#+([ \t]|$)/ && ' '    style=="canonical" && !/^ ? ? ?#+([ \t]|$)/ && '
row O01 over 'a canonical finding with a-notes-sub-heading was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '    style=="canonical" && fid && /^ ? ? ?(#|##|###)([ \t]|$)/ {finding()}' '    style=="canonical" && fid && /^ ? ? ?#+([ \t]|$)/ {finding()}'
row O02 over 'Held-up prose after the last finding was refused (O-018)' "$GC" "$RL" \
  "$VL" '    style=="canonical" && fid && !/^[ ]*- \*\*' '    style=="canonical" && !/^[ ]*- \*\*'
say '== the canonical conjuncts that keep legacy rounds as they were (T030o44 review F6; O03 of v1 is now a kill)'
F6='a canonical rule reached a legacy round, or the round lost its Blocks (T030o44 review F6)'
row O03 kill "$F6" "$GC" "$RL" "$VL" '    style=="canonical" && !ended && !fid && ' '    !ended && !fid && '
row F6a kill "$F6" "$GC" "$RL" "$VL" '    style=="canonical" && fid && !/^[ ]*- \*\*(' '    fid && !/^[ ]*- \*\*('
row F6b kill "$F6" "$GC" "$RL" "$VL" '    style=="canonical" && !ended && /^ ? ? ?#+([ \t]|$)/ && vf_finding_heading($0)' '    !ended && /^ ? ? ?#+([ \t]|$)/ && vf_finding_heading($0)'
row F6c kill "$F6" "$GC" "$RL" "$VL" '    style=="canonical" && fid && /^ ? ? ?(#|##|###)([ \t]|$)/ {finding()}' '    fid && /^ ? ? ?(#|##|###)([ \t]|$)/ {finding()}'
row F6d kill "$F6" "$GC" "$RL" "$VL" '    style=="canonical" && !ended && !/^ ? ? ?#+([ \t]|$)/ && ' '    !ended && !/^ ? ? ?#+([ \t]|$)/ && '
say '== the round style decided before its body (T030o45, O-020)'
SL='a title and a late Timestamp let a round with uncounted-blocking seal under LANG=C (O-020)'
TSERR='if (style=="legacy" && body) err("a Timestamp line after the body of a round its title made legacy"); '
TIERR='if (style=="canonical" && body) err("a report title after the body of a canonical round"); '
row S01 kill "$SL" "$GC" "$ST" "$VL" "$TSERR" ''
row S01e kill 'a CLEARED completion under a title and a late Timestamp was not refused under LANG=C (O-020)' "$SG" "$RR" "$VL" "$TSERR" ''
row S02 kill 'a title after the body of a canonical round was read under LANG=C (O-020)' "$GC" "$ST" "$VL" "$TIERR" ''
row S03 kill "$SL" "$GC" "$ST" "$VL" '    active && $0 !~ /^[[:space:]]*$/ {body=1}'$'\n' ''
row S04 kill 'a round whose only body before its late Timestamp is quoted sealed under LANG=C (O-020)' "$GC" "$ST" \
  "$VL" '      if (active && $0 !~ /^[[:space:]]*$/) body=1'$'\n' ''
row S05 kill 'a report title after the body of a canonical round' "$GC" shipped_002_tally_case \
  "$VL" 'ended=counted=blockers=minors=downgraded=body=0; next' 'ended=counted=blockers=minors=downgraded=0; next'
row S06 equiv '' "$GC" shipped_002_tally_case \
  "$VL" 'suppressed=""; ended=counted=blockers=minors=downgraded=body=0}' 'suppressed=""; ended=counted=blockers=minors=downgraded=0}'
# S06 argued: the branch runs only when no round is active, which is only before the first round of the file
# (active is cleared only by flush, at a round heading that sets it again or at END), where body is still unset.
row S07 over 'expected exit 0, got 3: record_line_vf C' "$GC" "$ST" \
  "$VL" 'if (style=="legacy" && body) err("a Timestamp line' 'if (style=="legacy") err("a Timestamp line'
row S08 over 'a report title after the body of a canonical round' "$GC" shipped_002_tally_case \
  "$VL" 'if (style=="canonical" && body) err("a report title' 'if (style=="canonical") err("a report title'

say '== the rendered reading: the bracket fixpoint, the escape, the checkbox, emphasis inside a word, hiding (T030o46, O-018)'
row P01 kill "$LR nested-badge $LS" "$GC" "$RL" "$VL" 'substr(s, m); pos = 1; continue}' 'substr(s, m); pos = i + 1; continue}'
row P01b kill "$LR nested-brackets $LS" "$GC" "$RL" "$VL" '"\001" inner "\001" substr(s, j); pos = 1' '"\001" inner "\001" substr(s, j); pos = j'
row P01e kill 'a CLEARED completion over a second manifest tier written as - [![badge](y.png)](z)Severity: data-loss' "$SG" "$RR" \
  "$VL" 'substr(s, m); pos = 1; continue}' 'substr(s, m); pos = i + 1; continue}'
row P02 kill "$LR escaped-bracket-alt $LS" "$GC" "$RL" "$VL" '  gsub(/\\[][]/, "\003", s)'$'\n''  pos = 1' '  pos = 1'
row P03 kill "$LR checkbox-then-tag $LS" "$GC" "$RL" "$VL" '    if (!b && inner ~ /^[ xX]$/) {pos = j; continue}'$'\n' ''
row P05 kill "$LR intraword-emphasis $LS" "$GC" "$RL" \
  "$VL" '  while (match(s, /[A-Za-z0-9]\*+[A-Za-z0-9]/)) s = substr(s, 1, RSTART) substr(s, RSTART + RLENGTH - 1)'$'\n' ''
row P05e kill 'a CLEARED completion over a second manifest tier written as - S*everity:* data-loss' "$SG" "$RR" \
  "$VL" '  while (match(s, /[A-Za-z0-9]\*+[A-Za-z0-9]/)) s = substr(s, 1, RSTART) substr(s, RSTART + RLENGTH - 1)'$'\n' ''
row P06 kill "$LR zero-width-space $LS" "$GC" "$RL" "$VL" '  if (w == "") w = vf_label_word(vf_label_render(s, 1), labels)'$'\n' ''
row P06e kill 'a CLEARED completion over a second manifest tier written as - Sev' "$SG" "$RR" \
  "$VL" '  if (w == "") w = vf_label_word(vf_label_render(s, 1), labels)'$'\n' ''
row P07 kill "$LR named-soft-hyphen $LS" "$GC" "$RL" "$VL" '  gsub(/&[A-Za-z][A-Za-z0-9]*;/, hide ? "" : "\001", s)' '  gsub(/&[A-Za-z][A-Za-z0-9]*;/, "\001", s)'
row P08 kill "$LR numeric-soft-hyphen $LS" "$GC" "$RL" "$VL" '((hide && n > 126) ? "" : "\001")' '"\001"'
row P09 kill "$LR soft-hyphen $LS" "$GC" "$RL" "$VL" '  if (hide) gsub(/[\200-\377]/, "", s)'$'\n' ''

say '== the paragraph step and the paragraph checks (T030o46, T030o47; O-018)'
row P13 kill "$LR split-tag $LS" "$GC" "$RL" "$VL" '        if (field == "" && pl != "") {field=' '        if (0) {field='
row P13e kill 'a CLEARED completion over a second manifest tier written as - <b' "$SG" "$RR" \
  "$VL" '        if (field == "" && pl != "") {field=' '        if (0) {field='
row P14 kill 'a second tier written as split-tag was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '      if (lbl == "" && pl != "") lbl=' '      if (0) lbl='
row P14e kill 'a CLEARED completion over a second tier written as - **Severity:** minor\n- <abbr' "$SG" "$RR" \
  "$VL" '      if (lbl == "" && pl != "") lbl=' '      if (0) lbl='
row P15 kill "$LR comment-across-quoted $LS" "$GC" "$RL" \
  "$VL" 'shape=vf_record($0); if (shape == "" && id != "") shape=vf_para_label()' 'shape=vf_record($0)'
row P16 kill 'a second tier written as comment-across-quoted was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" 'shape=vf_record($0); if (shape == "" && fid != "") shape=vf_para_label()' 'shape=vf_record($0)'
row P16e kill 'a CLEARED completion over a second tier written as - **Severity:** minor\n- <!-- a' "$SG" "$RR" \
  "$VL" 'shape=vf_record($0); if (shape == "" && fid != "") shape=vf_para_label()' 'shape=vf_record($0)'
row P17 over 'expected exit 0, got 3: record_line_vf C' "$GC" "$RL" "$VL" '    if (vf_run_own[k] != "") {vf_run_done[k] = 1; continue}'$'\n' ''
row P18 equiv '' "$GC" "$RL" "$VL" '{vf_run_refused = 1; return' '{return'
# P18 argued: without it a run already refused is refused again at each later line, which adds a message and
# changes no verdict.
row P19 equiv '' "$GC" "$RL" "$VL" '  if (!vf_para_cont || vf_run_refused) return ""' '  if (vf_run_refused) return ""'
# P19 argued: on a line that opens a run no earlier candidate exists (the loop runs below vf_run_n, which is 1), so
# the guard only saves the loop.
row P20 equiv '' "$GC" "$RL" "$VL" '  for (k = 1; k < vf_run_n; k++) {' '  for (k = 1; k <= vf_run_n; k++) {'
# P20 argued: the candidate the current line opens holds that line without its indentation and block-quote markers,
# which the word reader skips as characters that are not letters or digits, so its label is the line's own; a line
# with a label is skipped, and one without yields none.
row P21 equiv '' "$GC" "$RL" "$VL" '  if (FNR == 1) {vf_run_n = vf_run_refused = vf_def_open = 0; vf_cm_states = " 0"}'$'\n' ''
# P21 argued: without it a run continues into the next file the pass reads, which only adds candidates, so it can
# only add a refusal; every manifest and report a fixture writes begins with an ATX heading, which ends a run anyway,
# and resets the carried code-span states with it (v5) and the carried definition label (v6).
row P22 kill "$LR paragraph-ordered-sibling $LS" "$GC" "$RL" "$VL" 'vf_run_text[k] = vf_run_text[k] " " t' 'vf_run_text[k] = vf_run_text[k]'
row P23 kill "$LR paragraph-ordered-sibling $LS" "$GC" "$RL" \
  "$VL" '  vf_run_n++; vf_run_text[vf_run_n] = t; vf_run_line[vf_run_n] = s; vf_run_own[vf_run_n] = "?"' \
  '  if (!vf_run_n) {vf_run_n++; vf_run_text[vf_run_n] = t; vf_run_line[vf_run_n] = s; vf_run_own[vf_run_n] = "?"}'

say '== the blocks that end a field item (T030o46, O-021)'
row B13 over 'a plausible manifest (severity-then-four-backtick-fence) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  if (t ~ ("^" b b b b "*[^" b "]*$")) return 1' '  if (t ~ ("^" b b b "[^" b "]*$")) return 1'
row B14 equiv '' "$GC" "$ML" \
  "$VL" '  if (tolower(t) ~ /^<\/?(address|article' '  if (0 && tolower(t) ~ /^<\/?(address|article'
# B14 argued (v5): inside a finding, where the field-item rule asks vf_block_start, every line this clause admits
# begins with `<` and a letter, `/`, `!` or `?` outside any code span, so it is refused by name as raw HTML outside a
# code span (T030o48) whatever the item rule reads; the clause decides only whether a second diagnostic names the item.
row B14c equiv '' "$GC" "$RL" \
  "$VL" '  if (tolower(t) ~ /^<\/?(address|article' '  if (0 && tolower(t) ~ /^<\/?(address|article'
# B14c argued (v5): inside a finding, where the field-item rule asks vf_block_start, every line this clause admits
# begins with `<` and a letter, `/`, `!` or `?` outside any code span, so it is refused by name as raw HTML outside a
# code span (T030o48) whatever the item rule reads; the clause decides only whether a second diagnostic names the item.
row B15 kill "$LR value-span-twin $LS" "$GC" "$RL" "$VL" '|ul)([ \t>]|\/>|$)/) return 1' '|ul|span)([ \t>]|\/>|$)/) return 1'
row B17 equiv '' "$GC" "$ML" \
  "$VL" '  if (tolower(t) ~ /^<\/?(address|' '  if (tolower(t) ~ /^<(address|'
# B17 argued (v5): inside a finding, where the field-item rule asks vf_block_start, every line this clause admits
# begins with `<` and a letter, `/`, `!` or `?` outside any code span, so it is refused by name as raw HTML outside a
# code span (T030o48) whatever the item rule reads; the clause decides only whether a second diagnostic names the item.
say '== the code-span reading, the reading after a rendered line start, the field-value reading (T030o47, O-018)'
row X01 kill "$LR code-span-in-link $LS" "$GC" "$RL" "$VL" '  c = index(s, sprintf("%c", 96)) ? vf_label_inert(s) : s' '  c = s'
row X02 kill "$LR code-span-in-link $LS" "$GC" "$RL" "$VL" '  if (c != s) {' '  if (0) {'
row X03 kill "$LR code-span-then-soft-hyphen $LS" "$GC" "$RL" "$VL" '    if (w == "") w = vf_label_word(vf_label_render(c, 1), labels)'$'\n' ''
row X04 kill "$LR br-in-prose $LS" "$GC" "$RL" "$VL" '  return index(c, "<") ? vf_label_breaks(s, c, labels) : ""' '  return ""'
row X05 kill "$LR closing-p-inside-line $LS" "$GC" "$RL" \
  "$VL" ' && !match(rest, /^<\/[A-Za-z][A-Za-z0-9-]*[ \t]*>/)) continue'$'\n''    L = RLENGTH; nm = tolower(substr(rest, 1, L)); sub(/^<\/?/, "", nm); sub(/[^a-z0-9].*$/, "", nm)'$'\n''    if (nm != "br" && !index(vf_lbl_blocks, " " nm " ")) continue'$'\n''    w = ' \
  ') continue'$'\n''    L = RLENGTH; nm = tolower(substr(rest, 1, L)); sub(/^<\/?/, "", nm); sub(/[^a-z0-9].*$/, "", nm)'$'\n''    if (nm != "br" && !index(vf_lbl_blocks, " " nm " ")) continue'$'\n''    w = '
row X06a kill "$LR p-inside-line $LS" "$GC" "$RL" "$VL" '    if (nm != "br" && !index(vf_lbl_blocks, " " nm " ")) continue'$'\n''    w = ' '    if (nm != "br") continue'$'\n''    w = '
row X06b kill "$LR br-in-prose $LS" "$GC" "$RL" "$VL" 'if (nm != "br" && !index(vf_lbl_blocks, " " nm " ")) continue'$'\n''    w = ' 'if (!index(vf_lbl_blocks, " " nm " ")) continue'$'\n''    w = '
row X06c over 'a plausible manifest (outside-span-tag) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '    if (nm != "br" && !index(vf_lbl_blocks, " " nm " ")) continue'$'\n''    w = vf_label_read' '    w = vf_label_read'
# X06c (v5): a span inside a finding is raw HTML and refused by name (T030o48), so its row moved outside every finding.
row X07 kill "$LR br-then-code-span $LS" "$GC" "$RL" "$VL" '    if (w == "") w = vf_label_word(vf_label_render(substr(c, p + L), 0), labels)'$'\n' ''
row X08 kill "$LR br-then-soft-hyphen $LS" "$GC" "$RL" "$VL" '    w = vf_label_read(substr(s, p + L), labels)' '    w = ""'
row X09 kill 'a second tier written as br-in-where was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '      if (style=="canonical" && index($0, "<") && (lbl=vf_label_breaks(' '      if (0 && (lbl=vf_label_breaks('
row X10 kill "$F6" "$GC" "$RL" "$VL" '      if (style=="canonical" && index($0, "<") && (lbl=vf_label_breaks(' '      if (index($0, "<") && (lbl=vf_label_breaks('
row X11 equiv '' "$GC" "$RL" "$VL" ' && index($0, "<") && (lbl=vf_label_breaks(' ' && (lbl=vf_label_breaks('
# X11 argued: vf_label_breaks reads only after a tag, which needs a `<`, so on a line without one it returns ""
# whatever the conjunct; the conjunct saves the call.
row X12 kill "$LR heading-label $LS" "$GC" "$RL" "$VL" $'  w = vf_label_read(s, labels)\n  if (w != "") return w\n' $'  w = vf_label_read(s, labels)\n'
# X12, an argued equivalent until the session-16 probe killed it (r16-mutations-probe, rc 1 on this row alone): without
# the early return a line with no code span falls through to the reading after a rendered line start, which reads
# only after a tag, so the label the first readings found is lost; the heading-label rows judge it.
say '== the narrowed grammar inside a finding (T030o48, O-018): vf_narrow, the `<` class, its call in each pass'
row G01 kill "$LR form-feed-in-text $LS" "$GC" "$RL" \
  "$VL" 'if (index(vf_original, sprintf("%c", 12)) || index(vf_original, sprintf("%c", 11))) vf_narrow' 'if (0) vf_narrow'
row G02 kill "$LR form-feed-in-text $LS" "$GC" "$RL" \
  "$VL" 'if (index(vf_original, sprintf("%c", 12)) || index' 'if (index'
row G03 kill "$LR vertical-tab-in-text $LS" "$GC" "$RL" \
  "$VL" ' || index(vf_original, sprintf("%c", 11))) vf_narrow' ') vf_narrow'
row G04 kill "$LR lone-carriage-return $LS" "$GC" "$RL" \
  "$VL" 'else if ((k = index(vf_original, "\r")) && k < length(vf_original)) vf_narrow' 'else if (0) vf_narrow'
row G05 over 'a manifest finding spelled crlf was dropped (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 'k < length(vf_original)) vf_narrow' 'k <= length(vf_original)) vf_narrow'
row G06 kill "$LR pre-in-prose $LS" "$GC" "$RL" \
  "$VL" '    if (vf_cm_out) vf_narrow = "raw HTML' '    if (0) vf_narrow = "raw HTML'
row G06e kill 'a CLEARED completion over a second manifest tier written as - Note<pre>Severity: data-loss</pre> was not refused' "$SG" "$RR" \
  "$VL" '    if (vf_cm_out) vf_narrow = "raw HTML' '    if (0) vf_narrow = "raw HTML'
row G07 equiv '' "$GC" "$RL" \
  "$VL" $'    if (vf_narrow != "") continue\n' $''
# G07 argued (v6: discovery A08): the guard keeps the first reason a line leaves the grammar; without it a later
# reason, from the same reading of the line or from a later code-span state, names the line instead. Every reason
# refuses the line by name in both passes, and the chain only ever sets one, so the verdict is the same and only the
# diagnostic may change; no row writes a line with two reasons.
row G08 kill "$LR plaintext-in-prose $LS" "$GC" "$RL" \
  "$VL" '~ /[A-Za-z\/!?]/) vf_cm_out = 1' '~ /[\/!?]/) vf_cm_out = 1'
row G09 kill 'a manifest finding carrying raw HTML (severity-then-closing-tag) was not refused by name (round 16, O-018)' "$GC" "$ML" \
  "$VL" '~ /[A-Za-z\/!?]/) vf_cm_out = 1' '~ /[A-Za-z!?]/) vf_cm_out = 1'
row G10 kill 'a manifest finding carrying raw HTML (severity-then-comment) was not refused by name (round 16, O-018)' "$GC" "$ML" \
  "$VL" '~ /[A-Za-z\/!?]/) vf_cm_out = 1' '~ /[A-Za-z\/?]/) vf_cm_out = 1'
row G11 kill "$LR pi-in-prose $LS" "$GC" "$RL" \
  "$VL" '~ /[A-Za-z\/!?]/) vf_cm_out = 1' '~ /[A-Za-z\/!]/) vf_cm_out = 1'
row G12 over 'a plausible manifest (escaped-lt-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 'if (c ~ /[A-Za-z\/!?]/) vf_cm_out = 1; else if (c ~ vf_cm_ac)' 'vf_cm_out = 1; if (c ~ vf_cm_ac)'
row G13 kill "$LR pre-in-prose $LS" "$GC" "$RL" \
  "$VL" '      id != "" && vf_narrow != "" && (vq ||' '      0 && vf_narrow != "" && (vq ||'
row G14 over 'a plausible manifest (outside-span-tag) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '      id != "" && vf_narrow != "" && (vq ||' '      vf_narrow != "" && (vq ||'
row G15 kill 'a second tier written as pre-in-prose was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && (vq ||' '0 && vf_narrow != "" && (vq ||'
row G16 kill "$F6" "$GC" "$RL" \
  "$VL" 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && (vq ||' 'active && !ended && fid != "" && vf_narrow != "" && (vq ||'
row G17 equiv '' "$GC" "$RL" \
  "$VL" 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && (vq ||' 'style=="canonical" && !ended && fid != "" && vf_narrow != "" && (vq ||'
# G17 argued, on Q08's premise: while lines are read a canonical style means an active round.
row G18 equiv '' "$GC" "$RL" \
  "$VL" 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && (vq ||' 'style=="canonical" && active && fid != "" && vf_narrow != "" && (vq ||'
# G18 argued: after the completion marker every non-blank line is refused by name already (the after-marker refusal),
# so a narrowed line there is refused either way; the conjunct keeps one diagnostic. The v6 rows G13 to G19 take the
# main check, whose heading conjunct (vq || not a heading) the round's minor added; the checks at a line's own
# heading are the VH rows.
row G19 over 'raw HTML in Held-up prose outside every finding was refused (round 16, O-018)' "$GC" "$RL" \
  "$VL" 'style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && (vq ||' 'style=="canonical" && active && !ended && vf_narrow != "" && (vq ||'

say '== the code-span scan and the code-span reading (T030o48, O-018): 6.1 read left to right, 2.4 escapes in pairs'
row Y01 over 'a plausible manifest (escaped-lt-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '    if (c == "\\") {i += (i < n && vf_cm_punct(substr(s, i + 1, 1))) ? 2 : 1; continue}' '    if (c == "\\") {i += 1; continue}'
row Y02 equiv '' "$GC" "$RL" \
  "$VL" '  return c != "" && index(vf_cm_p, c) > 0' '  return c != ""'
# Y02 argued: both readers act only on a backslash, a backtick or `<`, each of them punctuation, so taking a
# backslash and a character that is not punctuation as a pair changes no position either reader acts on.
row Y03 over 'a plausible manifest (escaped-lt-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  return c != "" && index(vf_cm_p, c) > 0' '  return 0'
row Y04 kill "$LR code-span-holding-a-backtick $LS" "$GC" "$RL" \
  "$VL" '    if (RLENGTH == r) return off + RSTART + RLENGTH' '    if (1) return off + RSTART + RLENGTH'
row Y05 kill "$LR tag-after-span-closing-next-line $LS" "$GC" "$RL" \
  "$VL" '  if (st > 0) {k = vf_cm_close(s, 1, st); if (!k) {vf_cm_exits = " " st; return}; i = k}' '  if (0) {k = 0}'
row Y06 kill "$LR tag-after-span-closing-next-line $LS" "$GC" "$RL" \
  "$VL" '    if (!k) {vf_cm_exits = vf_cm_exits " " r; i = j; continue}' '    if (!k) {i = j; continue}'
row Y07 kill "$LR tag-after-span-closing-two-lines-later $LS" "$GC" "$RL" \
  "$VL" 'if (!k) {vf_cm_exits = " " st; return}' 'if (!k) {vf_cm_exits = ""; return}'
row Y08 over 'a plausible manifest (code-span-tags-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'    if (!k) {vf_cm_exits = vf_cm_exits " " r; i = j; continue}\n    i = k\n' $'    if (!k) {vf_cm_exits = vf_cm_exits " " r; i = j; continue}\n    i = j\n'
row Y09 kill "$LR tag-after-span-closing-next-line $LS" "$GC" "$RL" \
  "$VL" $'  vf_cm_states = ex\n' $'  vf_cm_states = " 0"\n'
row Y10 equiv '' "$GC" "$RL" \
  "$VL" $'    if (index(done, " " x[i] " ")) continue\n' ''
# Y10 argued: a state read twice repeats the same scan of the same line, which sets the same flag and the same exits.
row Y11 kill "$LR escaped-first-backtick $LS" "$GC" "$RL" \
  "$VL" '    if (c == "\\") {k = (i < n && vf_cm_punct(substr(s, i + 1, 1))) ? 2 : 1; out = out substr(s, i, k); i += k; continue}' '    if (c == "\\") {k = 1; out = out substr(s, i, k); i += k; continue}'
row Y12 over 'a plausible manifest (code-span-word-before-label) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 'f = substr(s, i, k - i); gsub(/[^A-Za-z0-9]/, "\002", f)' 'f = substr(s, i, k - i); gsub(/./, "\002", f)'
row Y12c over 'a canonical finding with a-code-span-word-before-label was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" 'f = substr(s, i, k - i); gsub(/[^A-Za-z0-9]/, "\002", f)' 'f = substr(s, i, k - i); gsub(/./, "\002", f)'
row Y13 kill "$LR image-alt-holding-an-unclosed-run-then-a-span $LS" "$GC" "$RL" \
  "$VL" '    if (!k) {out = out substr(s, i, r); i = j; continue}' '    if (!k) {out = out substr(s, i); i = n + 1; continue}'

say '== the run ends only at a blank line or a heading of one to six marks, never at a fenced line (T030o48, T030o49)'
EB='  if (t == "" || t == "\r" || q ~'
EH='q ~ /^ ? ? ?(#|##|###|####|#####|######)([ \t]|$)/) {vf_run_n'
row E01 over 'a plausible manifest (image-split-by-blank-line) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" "$EB" '  if (t == "\r" || q ~'
row E01c over 'a canonical finding with a-image-split-by-blank-line was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "$EB" '  if (t == "\r" || q ~'
row E02 over 'a plausible manifest (image-split-by-crlf-blank-line) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" "$EB" '  if (t == "" || q ~'
row E03 kill "$LR image-split-by-seven-marks $LS" "$GC" "$RL" \
  "$VL" "$EH" 'q ~ /^ ? ? ?#+([ \t]|$)/) {vf_run_n'
row E03c kill 'a second tier written as image-split-by-seven-marks was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" "$EH" 'q ~ /^ ? ? ?#+([ \t]|$)/) {vf_run_n'
row E04 over 'a plausible manifest (image-split-by-six-marks) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 't == "\r" || '"$EH" 't == "\r") {vf_run_n'
row E04c over 'a canonical finding with a-image-split-by-six-marks was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" 't == "\r" || '"$EH" 't == "\r") {vf_run_n'
row E05 over 'a plausible manifest (image-split-by-six-marks) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '(#|##|###|####|#####|######)([ \t]|$)/) {vf_run_n' '(#|##|###|####|#####)([ \t]|$)/) {vf_run_n'
row E06 kill "$LR paragraph-indented-heading-marker $LS" "$GC" "$RL" \
  "$VL" "$EH" 'q ~ /^[ \t]*(#|##|###|####|#####|######)([ \t]|$)/) {vf_run_n'
row E07 over 'a plausible manifest (quoted-image-split-by-six-marks) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  q = s; while (match(q, /^ ? ? ?>[ ]?/)) q = substr(q, RLENGTH + 1)' '  q = s'
row E07c over 'a canonical finding with a-quoted-image-split-by-six-marks was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '  q = s; while (match(q, /^ ? ? ?>[ ]?/)) q = substr(q, RLENGTH + 1)' '  q = s'
row E08 kill "$LR image-after-backtick-info-fence $LS" "$GC" "$RL" \
  "$VL" "$EB" '  if (fenced || t == "" || t == "\r" || q ~'
row E09 over 'a plausible manifest (span-tag-after-a-lone-backtick-paragraph) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" 'vf_para_cont = vf_def_open = 0; vf_cm_states = " 0"; return}' 'vf_para_cont = vf_def_open = 0; return}'
row E09c over 'a canonical finding with a-span-tag-after-a-lone-backtick-paragraph was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" 'vf_para_cont = vf_def_open = 0; vf_cm_states = " 0"; return}' 'vf_para_cont = vf_def_open = 0; return}'

say '== a settled candidate is dropped (T030o50, O-023): vf_settled and the reader that drops'
row D01 kill "$LR image-alt-across-three-lines $LS" "$GC" "$RL" \
  "$VL" '    if (vf_settled(vf_run_text[k])) vf_run_done[k] = 1' '    vf_run_done[k] = 1'
row D02 kill 'watchdog: judge stopped after' "$GC" "$RL" \
  "$VL" '    if (vf_settled(vf_run_text[k])) vf_run_done[k] = 1' '    if (0) vf_run_done[k] = 1'
# D02 (v6): a kill now. A candidate never dropped is T030o47's reader, whose verdicts are the same, but the 400-line
# timing row (T030o53, O-023) bounds the cost: in matrix run 1 that run had taken 624 s when it was stopped, its
# timing assertion failing, so its judge is stopped by the watchdog (r18-mutations-run1.note).
row D03 kill "$LR tag-attribute-across-three-lines $LS" "$GC" "$RL" \
  "$VL" '  if (index(j, "<") && !vf_settled_html(j)) return 0' '  if (0) return 0'
row D04 kill "$LR entity-then-code-span-holding-image-across-lines $LS" "$GC" "$RL" \
  "$VL" '  vf_cm_scan(j, 0); if (vf_cm_exits != " 0") return 0' '  vf_cm_scan(j, 0)'
# D04 (v6): judged by a code span left open across lines after an entity, which holds an image; the open image
# bracket of its v5 row is kept by the head bracket test now (r18-mutations-run1.note).
row D05 kill "$LR image-alt-across-three-lines $LS" "$GC" "$RL" \
  "$VL" $'  return vf_settled_lead(t) && vf_settled_brackets(vf_settled_head(t))' $'  return vf_settled_lead(t)'
# D05 (v6: discovery S01): the bracket test of every reading dropped.
row D06 kill "$LR link-title-across-three-lines $LS" "$GC" "$RL" \
  "$VL" $'  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0' $'  if (!vf_settled_lead(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0'
# D06 (v6: discovery S06): the bracket test of the reading as written dropped.
row D07 kill "$LR image-alt-beginning-with-code-span-across-lines $LS" "$GC" "$RL" \
  "$VL" $'  if (c != j && (!vf_settled_word(c) || !vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0' $'  if (c != j && (!vf_settled_lead(c) || !vf_settled_lead(vf_label_render(c, 0)) || !vf_settled_lead(vf_label_render(c, 1)))) return 0'
# D07 (v6): the bracket tests of the inert code-span reading and of its two rendered readings dropped.
row D08 kill "$LR image-after-stray-bracket-across-three-lines $LS" "$GC" "$RL" \
  "$VL" '    else if (!d--) return 0' '    else d--'
row D09 kill "$LR image-alt-across-three-lines $LS" "$GC" "$RL" \
  "$VL" $'  if (d) return 0\n' ''
row D10 kill "$LR link-title-across-three-lines $LS" "$GC" "$RL" \
  "$VL" '{p += c; if (!vf_label_dest(s, p + 1)) return 0}' '{p += c}'
row D11 equiv '' "$GC" "$RL" \
  "$VL" $'  gsub(/\\\\[][]/, "\\003", s)\n  p = 0; d = 0\n' $'  p = 0; d = 0\n'
# D11 argued (v6): the escape step matters to the readings as written alone (the text and its inert code-span
# reading): the rendered readings take escaped brackets out before they pair brackets (vf_label_links), so a
# bracket that only an escaped one would close stays open before the first word there and keeps the candidate.
# Without the step, a reading as written only fails more often (an escaped bracket counted open or stray, or an
# escaped `]` before a `(` read as a destination), or passes where a rendered reading already fails, so no
# candidate is dropped that is kept now (r18-mutations-run1.note; r18-rows-probe-4: an escaped bracket before the
# first word is refused under it too).
row D12 kill "$LR image-alt-across-three-lines $LS" "$GC" "$RL" \
  "$VL" $'  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0' '  if (0) return 0'
# D12 (v6): a kill now, since the reading test of the text as written also tests its brackets (T030o53).
row D13 kill "$LR image-alt-beginning-with-code-span-across-lines $LS" "$GC" "$RL" \
  "$VL" $'  if (c != j && (!vf_settled_word(c) || !vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0\n' $''
# D13 (v6: discovery S10): a kill now, through the row whose image alt begins with a code span holding `]`.
row D14 kill "$LR break-image-outside-finding-after-id $LS" "$GC" "$RL" \
  "$VL" '  return !index(c, "<") || vf_settled_breaks(j, c)' '  return 1'
# D14 (v6): a kill now, outside every finding after a finding ID, where a br is not refused by name.
row D15 equiv '' "$GC" "$RL" \
  "$VL" $'  return t != ""\n}\nfunction vf_settled_head' $'  return 1\n}\nfunction vf_settled_head'
# D15 argued: a candidate every other condition shows settled, but one of whose readings holds no first word yet,
# reads every later line in that reading as the candidate starting at the next line reads it, since no construct spans
# the boundary: its head is then the whole reading, so every bracket pair and destination in it is closed, as every
# code span and raw-HTML construct is; that candidate is read too, so dropping the first loses no label.
row D16 equiv '' "$GC" "$RL" \
  "$VL" '    if (vf_run_own[k] != "") {vf_run_done[k] = 1; continue}' '    if (vf_run_own[k] != "") continue'
# D16 argued: a candidate whose own line carries a label is skipped on every line either way; marking it done only
# stops extending it.
row D17 equiv '' "$GC" "$RL" \
  "$VL" 'for (k = 1; k <= vf_run_n; k++) if (!vf_run_done[k]) vf_run_text[k]' 'for (k = 1; k <= vf_run_n; k++) vf_run_text[k]'
# D17 and D18 argued: a candidate marked done is never read again, so extending it changes nothing read; reading it
# again reads a text with no label (a settled one) or meets its own label first (one set aside), as before.
row D18 equiv '' "$GC" "$RL" \
  "$VL" $'    if (vf_run_done[k]) continue\n' ''
row D19 kill "$LR break-image-outside-finding-after-id $LS" "$GC" "$RL" \
  "$VL" $'    if (!vf_settled_word(x) || !vf_settled_word(vf_label_render(x, 0)) || !vf_settled_word(vf_label_render(x, 1)) || !vf_settled_word(vf_label_render(substr(c, p + L), 0))) return 0' '    if (0) return 0'
# D19 (v6): a kill now, as D14.
row D20 equiv '' "$GC" "$RL" \
  "$VL" $'    if (nm != "br" && !index(vf_lbl_blocks, " " nm " ")) continue\n    x = substr(s, p + L)' '    x = substr(s, p + L)'
# D20 argued: without the filter the text after every tag must hold its first word, which can only keep a candidate
# longer, so it can only add a refusal, and inside a finding a tag is refused by name as raw HTML anyway.
row D21 equiv '' "$GC" "$RL" \
  "$VL" '    if (substr(rest, 1, 4) == "<!--") {if (!index(substr(rest, 3), "-->")) return 0; continue}' '    if (substr(rest, 1, 4) == "<!--") continue'
# D21 argued: a comment left open hides the rest of the rendered reading, so that reading holds no first word and the
# lead condition keeps the candidate.
row D22 kill "$LR tag-attribute-across-three-lines $LS" "$GC" "$RL" \
  "$VL" $'    if (!match(rest, vf_lbl_tag) && !match(rest, /^<\\/[A-Za-z][A-Za-z0-9-]*[ \\t]*>/)) return 0\n  }\n  return 1\n}\nfunction vf_settled_brackets' $'  }\n  return 1\n}\nfunction vf_settled_brackets'

say '== the narrowed grammar further (T030o51, O-018): the autolink class and its reason'
row VA01 kill "$LR autolink-digit-br $LS" "$GC" "$RL" \
  "$VL" $'else if (c ~ vf_cm_ac) vf_cm_auto = 1' $'else if (0) vf_cm_auto = 1'
row VA01e kill 'Note <1`@a.b><br>Severity: data-loss, tick: `. was not refused under LANG=C (T030o44 review)' "$SG" "$RR" \
  "$VL" $'else if (c ~ vf_cm_ac) vf_cm_auto = 1' $'else if (0) vf_cm_auto = 1'
row VA02 kill "$LR autolink-digit-br $LS" "$GC" "$RL" \
  "$VL" $'"[0-9.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"' $'"[.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"'
row VA03 kill "$LR autolink-underscore-p $LS" "$GC" "$RL" \
  "$VL" $'"[0-9.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"' $'"[0-9.#$%&*+=^{|}~" sprintf("%c", 39) b "-]"'
row VA04 kill "$LR autolink-backtick-start $LS" "$GC" "$RL" \
  "$VL" $'"[0-9.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"' $'"[0-9.#$%&*+=^_{|}~" sprintf("%c", 39) "-]"'
row VA05 kill "$LR autolink-plus $LS" "$GC" "$RL" \
  "$VL" $'"[0-9.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"' $'"[0-9.#$%&*=^_{|}~" sprintf("%c", 39) b "-]"'
row VA06 over 'a canonical finding with a-escaped-lt was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'"[0-9.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"' $'"[ 0-9.#$%&*+=^_{|}~" sprintf("%c", 39) b "-]"'
row VA07 kill "$LR autolink-digit-br $LS" "$GC" "$RL" \
  "$VL" $'    else if (vf_cm_auto) vf_narrow = "an autolink' $'    else if (0) vf_narrow = "an autolink'

say '== destinations, titles and labels read before a later backtick (T030o51, O-018): vf_cm_scan, vf_cm_dest, vf_cm_label'
row VB01 kill "$LR destination-holding-backtick $LS" "$GC" "$RL" \
  "$VL" $'re = "[]\\\\\\\\<" b "]"' $'re = "[\\\\\\\\<" b "]"'
row VB01e kill '[x](u`v)<br>Severity: data-loss, tick: `. was not refused under LANG=C (T030o44 review)' "$SG" "$RR" \
  "$VL" $'re = "[]\\\\\\\\<" b "]"' $'re = "[\\\\\\\\<" b "]"'
row VB02 kill "$LR label-holding-backtick $LS" "$GC" "$RL" \
  "$VL" $'if (c == "(" || c == "[") {' $'if (c == "(") {'
row VB04 kill "$LR title-across-lines $LS" "$GC" "$RL" \
  "$VL" $'        if (k < 0) {if (!vf_cm_link) vf_cm_link = 2}' $'        if (k < 0) {}'
row VB05 kill "$LR destination-holding-backtick $LS" "$GC" "$RL" \
  "$VL" $'        else if (k && index(substr(s, i + 1, k - i - 1), b)) vf_cm_link = 1' $'        else if (0) vf_cm_link = 1'
row VB06 over 'a plausible manifest (link-prose) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'        else if (k && index(substr(s, i + 1, k - i - 1), b)) vf_cm_link = 1' $'        else if (k) vf_cm_link = 1'
row VB07 equiv '' "$GC" "$RL" \
  "$VL" $'{if (!vf_cm_link) vf_cm_link = 2}' $'{vf_cm_link = 2}'
# VB07 argued: a destination, title or label holding a backtick and a later one on the same line that does not end
# there are each a reason to refuse the line by name; the guard keeps the first, and without it the second names the
# line, so the verdict is the same and only the diagnostic may change.
row VB08 kill "$LR destination-holding-backtick $LS" "$GC" "$RL" \
  "$VL" $'    else if (vf_cm_link == 1) vf_narrow' $'    else if (0) vf_narrow'
row VB09 kill "$LR title-across-lines $LS" "$GC" "$RL" \
  "$VL" $'    else if (vf_cm_link) vf_narrow = "a link destination' $'    else if (0) vf_narrow = "a link destination'
row VC01 kill "$LR destination-after-space $LS" "$GC" "$RL" \
  "$VL" $'  while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n  if (j > n) return -1\n  if (substr(s, j, 1) == "<") {\n' $'  if (j > n) return -1\n  if (substr(s, j, 1) == "<") {\n'
row VC02 kill "$LR destination-on-next-line $LS" "$GC" "$RL" \
  "$VL" $'  if (j > n) return -1\n  if (substr(s, j, 1) == "<") {\n' $'  if (j > n) return 0\n  if (substr(s, j, 1) == "<") {\n'
row VC03 kill "$LR angle-destination-with-space $LS" "$GC" "$RL" \
  "$VL" $'  if (substr(s, j, 1) == "<") {\n    j++\n' $'  if (0) {\n    j++\n'
row VC04 kill "$LR angle-destination-escaped-gt $LS" "$GC" "$RL" \
  "$VL" $'    while (j <= n && (c = substr(s, j, 1)) != ">") {if (c == "\\\\") j++; else if (c == "<") return 0; j++}\n' $'    while (j <= n && (c = substr(s, j, 1)) != ">") {if (c == "<") return 0; j++}\n'
row VC05 over 'a plausible manifest (invalid-angle-destination-holding-lt) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'    while (j <= n && (c = substr(s, j, 1)) != ">") {if (c == "\\\\") j++; else if (c == "<") return 0; j++}\n' $'    while (j <= n && (c = substr(s, j, 1)) != ">") {if (c == "\\\\") j++; j++}\n'
row VC06 over 'a plausible manifest (unclosed-angle-destination) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'    while (j <= n && (c = substr(s, j, 1)) != ">") {if (c == "\\\\") j++; else if (c == "<") return 0; j++}\n    if (j > n) return 0\n' $'    while (j <= n && (c = substr(s, j, 1)) != ">") {if (c == "\\\\") j++; else if (c == "<") return 0; j++}\n    if (j > n) return -1\n'
row VC07 kill "$LR destination-escaped-paren $LS" "$GC" "$RL" \
  "$VL" $'      if (c == "\\\\") {j += 2; continue}\n      if (c ~ /[ \\t]/) break\n      if (c == "(") depth++\n      else if (c == ")") {if (!depth) break; depth--}\n      j++\n    }\n    if (j > n) return -1\n' $'      if (c ~ /[ \\t]/) break\n      if (c == "(") depth++\n      else if (c == ")") {if (!depth) break; depth--}\n      j++\n    }\n    if (j > n) return -1\n'
row VC08 over 'a plausible manifest (destination-with-space-then-code) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'      if (c ~ /[ \\t]/) break\n      if (c == "(") depth++\n      else if (c == ")") {if (!depth) break; depth--}\n      j++\n    }\n    if (j > n) return -1\n' $'      if (c == "(") depth++\n      else if (c == ")") {if (!depth) break; depth--}\n      j++\n    }\n    if (j > n) return -1\n'
row VC09 kill "$LR destination-nested-parens $LS" "$GC" "$RL" \
  "$VL" $'      if (c == "(") depth++\n      else if (c == ")") {if (!depth) break; depth--}\n      j++\n    }\n    if (j > n) return -1\n' $'      else if (c == ")") {if (!depth) break; depth--}\n      j++\n    }\n    if (j > n) return -1\n'
row VC10 kill "$LR destination-nested-parens $LS" "$GC" "$RL" \
  "$VL" $'      else if (c == ")") {if (!depth) break; depth--}\n      j++\n    }\n    if (j > n) return -1\n' $'      else if (c == ")") break\n      j++\n    }\n    if (j > n) return -1\n'
row VC11 kill "$LR bare-destination-at-line-end $LS" "$GC" "$RL" \
  "$VL" $'    }\n    if (j > n) return -1\n' $'    }\n    if (j > n) return 0\n'
row VC12 kill "$LR title-holding-backtick $LS" "$GC" "$RL" \
  "$VL" $'  if (c == "\\"" || c == sprintf("%c", 39) || c == "(") {\n' $'  if (c == sprintf("%c", 39) || c == "(") {\n'
row VC13 kill "$LR title-across-lines $LS" "$GC" "$RL" \
  "$VL" $'  if (c == "\\"" || c == sprintf("%c", 39) || c == "(") {\n' $'  if (c == "\\"" || c == "(") {\n'
row VC14 kill "$LR title-in-parens $LS" "$GC" "$RL" \
  "$VL" $'  if (c == "\\"" || c == sprintf("%c", 39) || c == "(") {\n' $'  if (c == "\\"" || c == sprintf("%c", 39)) {\n'
row VC15 kill "$LR title-escaped-quote $LS" "$GC" "$RL" \
  "$VL" $'    while (j <= n && substr(s, j, 1) != q) {if (substr(s, j, 1) == "\\\\") j++; j++}\n    if (j > n) return -1\n' $'    while (j <= n && substr(s, j, 1) != q) j++\n    if (j > n) return -1\n'
row VC16 kill "$LR title-across-lines $LS" "$GC" "$RL" \
  "$VL" $'    if (j > n) return -1\n    j++\n' $'    if (j > n) return 0\n    j++\n'
row VC17 kill "$LR title-then-line-end $LS" "$GC" "$RL" \
  "$VL" $'    while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n    if (j > n) return -1\n' $'    while (j <= n && substr(s, j, 1) ~ /[ \\t]/) j++\n    if (j > n) return 0\n'
row VC18 over 'a plausible manifest (destination-then-code-span) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'    if (j > n) return -1\n  }\n  return (substr(s, j, 1) == ")") ? j + 1 : 0\n' $'    if (j > n) return -1\n  }\n  return j + 1\n'
row VC19 kill "$LR destination-space-at-line-end $LS" "$GC" "$RL" \
  "$VL" $'  if (j > n) return -1\n  c = substr(s, j, 1)\n' $'  if (j > n) return 0\n  c = substr(s, j, 1)\n'
row VL01 kill "$LR label-escaped-bracket $LS" "$GC" "$RL" \
  "$VL" $'  while (j <= n && (c = substr(s, j, 1)) != "]") {if (c == "\\\\") j++; else if (c == "[") return 0; j++}\n  return (j > n) ? -1 : j + 1' $'  while (j <= n && (c = substr(s, j, 1)) != "]") {if (c == "[") return 0; j++}\n  return (j > n) ? -1 : j + 1'
row VL02 over 'a plausible manifest (bracket-inside-label-position) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'  while (j <= n && (c = substr(s, j, 1)) != "]") {if (c == "\\\\") j++; else if (c == "[") return 0; j++}\n  return (j > n) ? -1 : j + 1' $'  while (j <= n && (c = substr(s, j, 1)) != "]") {if (c == "\\\\") j++; j++}\n  return (j > n) ? -1 : j + 1'
row VL03 kill "$LR label-across-lines $LS" "$GC" "$RL" \
  "$VL" $'  return (j > n) ? -1 : j + 1' $'  return (j > n) ? 0 : j + 1'

say '== a fence that may be inside a list item, and a link reference definition (T030o52, O-024)'
row VF01 kill "$LR fence-after-list-marker $LS" "$GC" "$RL" \
  "$VL" $'  else if (s ~ ("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)") && s !~ ("^(" f "|~~~)")) vf_narrow' $'  else if (0) vf_narrow'
row VF01e kill '- **Severity**: data-loss was not refused under LANG=C (T030o44 review)' "$SG" "$RR" \
  "$VL" $'  else if (s ~ ("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)") && s !~ ("^(" f "|~~~)")) vf_narrow' $'  else if (0) vf_narrow'
row VF02 kill "$LR fence-after-list-marker $LS" "$GC" "$RL" \
  "$VL" $'("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")' $'("^[ \\t]*(" f "|~~~)")'
row VF03 kill "$LR fence-after-ordered-marker $LS" "$GC" "$RL" \
  "$VL" $'("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")' $'("^[ \\t]*(([-+*])[ \\t]+)*(" f "|~~~)")'
row VF04 kill "$LR fence-after-ordered-marker $LS" "$GC" "$RL" \
  "$VL" $'("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")' $'("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f ")")'
row VF05 over 'a Severity line followed by a four-backtick-fence was refused under LANG=C (O-021)' "$GC" "$RL" \
  "$VL" $' && s !~ ("^(" f "|~~~)")) vf_narrow' $') vf_narrow'
row VF06 over 'a Severity line followed by a tilde-fence was refused under LANG=C (O-021)' "$GC" "$RL" \
  "$VL" $' && s !~ ("^(" f "|~~~)")) vf_narrow' $' && s !~ ("^(" f ")")) vf_narrow'
row VF07 kill "$LR fence-swapping-phase $LS" "$GC" "$RL" \
  "$VL" $'("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")' $'("^(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")'
row VF08 kill "$LR fence-after-tab $LS" "$GC" "$RL" \
  "$VL" $'("^[ \\t]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")' $'("^[ ]*(([-+*]|[0-9]+[.)])[ \\t]+)*(" f "|~~~)")'
row VR01 kill "$LR definition-hiding-severity $LS" "$GC" "$RL" \
  "$VL" $'  else if (d) vf_narrow = "a link reference definition"' $'  else if (0) vf_narrow = "a link reference definition"'
row VR01e kill 'a CLEARED completion over a manifest tier hidden in a link reference definition was not refused under LANG=C (round 17, O-024)' "$SG" "$RR" \
  "$VL" $'  else if (d) vf_narrow = "a link reference definition"' $'  else if (0) vf_narrow = "a link reference definition"'
row VR02 kill "$LR definition-in-list-item $LS" "$GC" "$RL" \
  "$VL" $'    t = s; sub(/^([ \\t]|>|([-+*]|[0-9]+[.)])[ \\t])*/, "", t)' $'    t = s; sub(/^([ \\t]|>)*/, "", t)'
row VR03 kill "$LR definition-after-quote-marker $LS" "$GC" "$RL" \
  "$VL" $'    t = s; sub(/^([ \\t]|>|([-+*]|[0-9]+[.)])[ \\t])*/, "", t)' $'    t = s; sub(/^([ \\t]|([-+*]|[0-9]+[.)])[ \\t])*/, "", t)'
# VR03 (v6): session 19 listed R03 as an equivalent; a definition after a block-quote marker passes under it
# (r18-rows-probe-2, r18-fixtures-judge-2-run3.note).
row VR04 kill "$LR definition-in-list-item $LS" "$GC" "$RL" \
  "$VL" $'    if (substr(t, 1, 1) != "[") return 0\n    k = 2' $'    if (substr(t, 1, 1) != "[" && 0) return 0\n    k = 2'
row VR05 kill "$LR definition-escaped-label $LS" "$GC" "$RL" \
  "$VL" $'{if (c == "\\\\") k++; else if (c == "[") {vf_def_open = 0; return 0}; k++}' $'{if (c == "[") {vf_def_open = 0; return 0}; k++}'
row VR06 over 'a plausible manifest (nested-bracket-then-colon-at-line-start) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'{if (c == "\\\\") k++; else if (c == "[") {vf_def_open = 0; return 0}; k++}' $'{if (c == "\\\\") k++; k++}'
row VR07 kill "$LR definition-label-across-lines $LS" "$GC" "$RL" \
  "$VL" $'  vf_def_open = (k > n)\n' $'  vf_def_open = 0\n'
row VR08 kill "$LR definition-label-across-lines $LS" "$GC" "$RL" \
  "$VL" $'  if (!vf_def_open) {\n    t = s;' $'  if (1) {\n    t = s;'
row VR09 over 'a plausible manifest (bracket-left-open-before-blank-line) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'vf_para_cont = vf_def_open = 0; vf_cm_states' $'vf_para_cont = 0; vf_cm_states'
row VR10 equiv '' "$GC" "$RL" \
  "$VL" $'  if (FNR == 1) {vf_run_n = vf_run_refused = vf_def_open = 0;' $'  if (FNR == 1) {vf_run_n = vf_run_refused = 0;'
# VR10 argued, on P21's premise: without it a definition label left open at the end of one file carries into the next
# file the pass reads; every manifest and report begins with an ATX heading, which no reading takes for a definition
# inside a finding (none is open at a file's first line) and which ends the run, resetting the carried label.
row VR11 over 'a plausible manifest (wrapped-link-text) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'  return k <= n && substr(t, k + 1, 1) == ":"' $'  return k <= n'

say '== the narrowed check judged after the heading on a line, in both passes (the round-17 minor, T030o51)'
row VH01 over 'a plausible manifest (heading-with-tag-closes-finding) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'      id != "" && vf_narrow != "" && (vq || !/^ ? ? ?#+([ \\t]|$)/) {bad(' $'      id != "" && vf_narrow != "" {bad('
row VH02 kill "$LR heading-tag-on-first-finding $LS" "$GC" "$RL" \
  "$VL" $'{id=word[3]; flevel=hl; if (vf_narrow != "") bad(vf_narrow " in finding " id)}' $'{id=word[3]; flevel=hl}'
row VH03 kill "$LR heading-tag-on-deeper-heading $LS" "$GC" "$RL" \
  "$VL" $'          next\n        }\n        if (vf_narrow != "") bad(vf_narrow " in finding " id)\n      }' $'          next\n        }\n      }'
row VH04 over 'a later Finding heading carrying raw HTML was refused under the finding it closes under LANG=C (round 17)' "$GC" "$RL" \
  "$VL" $'&& fid != "" && vf_narrow != "" && (vq || !/^ ? ? ?#+([ \\t]|$)/) {err(' $'&& fid != "" && vf_narrow != "" {err('
row VH05 kill 'a second tier written as title-tag-inside-finding was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'      if (style=="canonical" && active && !ended && fid != "" && vf_narrow != "") err(vf_narrow " in finding " fid)\n      if (ended)' $'      if (ended)'
row VH06 kill 'the first Finding heading of a round carried raw HTML under LANG=C (round 17)' "$GC" "$RL" \
  "$VL" $'cursec=""; if (style=="canonical" && active && !ended && fid != "" && vf_narrow != "") err(vf_narrow " in finding " fid); next}' $'cursec=""; next}'
row VH07 kill 'a second tier written as heading-tag-on-deeper-heading was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'    style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && /^ ? ? ?#+([ \\t]|$)/ {err(' $'    0 && /^ ? ? ?#+([ \\t]|$)/ {err('
row VH08 equiv '' "$GC" "$RL" \
  "$VL" $'    style=="canonical" && active && !ended && fid != "" && vf_narrow != "" && /^ ? ? ?#+([ \\t]|$)/ {err(' $'    style=="canonical" && active && !ended && fid != "" && vf_narrow != "" {err('
# VH08 argued: without the heading conjunct the check at a line's own heading also fires on every narrowed line that is
# not a heading, which the main check above has already refused by name with the same diagnostic (a quoted line never
# reaches it: its branch ends with next), so it only repeats a diagnostic.
row VH09 kill "$LR second-tier-after-empty-comment $LS" "$GC" "$RL" \
  "$VL" $'      vq {\n        shape=vf_record($0); if (shape == "" && id != "") shape=vf_para_label()' $'      vf_quoted($0) {\n        shape=vf_record($0); if (shape == "" && id != "") shape=vf_para_label()'

say '== the settled test read up to the first word of each reading (T030o53, O-023)'
row VS02 kill 'a 400-line run under a bracket quoted in a code span took' "$GC" "$RL" \
  "$VL" $'  match(t, /^[A-Za-z0-9]*/)\n  return h substr(t, 1, RLENGTH)' $'  return h t'
# VS02: the whole reading taken for its head keeps every candidate with a bracket quoted in a code span unsettled, so
# the 400-line timing row runs past its 60 s bound (about 340 s in r18-discover-c.log).
row VS03 kill "$LR ordered-number-then-image $LS" "$GC" "$RL" \
  "$VL" $'  while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\\[[ xX]\\])/) {\n    if (match(t, /^([0-9]+[.)]|\\[[ xX]\\])/)) {h = h substr(t, 1, RLENGTH); t = substr(t, RLENGTH + 1)}' $'  while (t ~ /^([^A-Za-z0-9])/) {\n    if (0) {h = h substr(t, 1, RLENGTH); t = substr(t, RLENGTH + 1)}'
row VS04 equiv '' "$GC" "$RL" \
  "$VL" $'  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0' $'  if (!vf_settled_word(j) || !vf_settled_lead(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0'
# VS04 and VS05 argued: the two rendered readings reduce the same links, images and footnote references, since they
# are reduced before the readings diverge (a named or numeric reference beyond ASCII, and a byte beyond ASCII, is a
# non-letter in the first and taken out in the second), so the brackets left before a reading's first word (an unclosed
# `[`, a stray `]`, a task checkbox) are the same in both, in the same order, and each bracket test fails when the
# other does. Where taking out joins a `]` to a `(`, only the second reads a destination there, and no line can make it
# one, since links are reduced on the text before it is taken out; so either bracket test may go while the other stays.
row VS05 equiv '' "$GC" "$RL" \
  "$VL" $'  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_word(vf_label_render(j, 1))) return 0' $'  if (!vf_settled_word(j) || !vf_settled_word(vf_label_render(j, 0)) || !vf_settled_lead(vf_label_render(j, 1))) return 0'
row VS07 kill "$LR image-title-across-lines-outside-finding-after-id $LS" "$GC" "$RL" \
  "$VL" $'  if (c != j && (!vf_settled_word(c) || !vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0' $'  if (c != j && (!vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0'
# VS07 and VS08 (v6): session 19 listed S07 and S08 as equivalents; outside every finding after a finding ID, an
# image whose alt begins with a code span holding `]`, completed with a title across lines or after an inline tag,
# hides the tier under them (r18-rows-probe-2, r18-fixtures-judge-2-run3.note).
row VS08 kill "$LR tag-image-alt-code-span-outside-finding-after-id $LS" "$GC" "$RL" \
  "$VL" $'  if (c != j && (!vf_settled_word(c) || !vf_settled_word(vf_label_render(c, 0)) || !vf_settled_word(vf_label_render(c, 1)))) return 0' $'  if (c != j && (!vf_settled_word(c) || !vf_settled_lead(vf_label_render(c, 0)) || !vf_settled_lead(vf_label_render(c, 1)))) return 0'
row VS09 kill "$LR break-image-outside-finding-after-id $LS" "$GC" "$RL" \
  "$VL" $'    if (!vf_settled_word(x) || !vf_settled_word(vf_label_render(x, 0)) || !vf_settled_word(vf_label_render(x, 1)) || !vf_settled_word(vf_label_render(substr(c, p + L), 0))) return 0' $'    if (!vf_settled_lead(x) || !vf_settled_lead(vf_label_render(x, 0)) || !vf_settled_lead(vf_label_render(x, 1)) || !vf_settled_lead(vf_label_render(substr(c, p + L), 0))) return 0'

say "== done shard $SHARD $(date -u +%H:%M:%SZ) rows=$rowi"
say "r18-mutations failures=$fails"
cd "$SP" && rm -rf "$R"
(( fails == 0 ))
