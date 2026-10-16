#!/usr/bin/env bash
# T030o45/T030o46 mutation matrix v3, 2026-10-02 (session 14), from t030o44-mutations.sh (v2, kept): every guard
# of T030o44 as v2 judged it, its rows rewritten where the round-14 repairs changed their literal, and a row for
# every guard of the round-14 repairs (Decisions 2026-10-02, session 14): the round style decided before its body
# (O-020: the two refusals, both body markers, the per-round reset), the bracket fixpoint, the escape, the
# checkbox, the image, emphasis inside a word, the three hiding branches, the paragraph step (block-quote markers,
# the fence and heading breaks, the paragraph checks of both passes and of both quoted refusals) (O-018), and the
# blocks that end a field's item (O-021). Row Q08 stays an argued equivalent on its true premise. Each in a
# standalone copy built from the live manifest enumeration, every judge under a TMPDIR ending in `/`.
# Harness: t030o43-mutations.sh, as v2.
# Usage: bash t030o44-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n] [ONLY=id,id...]
# Kinds: kill  -- the judge must FAIL and print the named diagnostic;
#        over  -- an over-correction mutant: the judge must FAIL on a positive and print the named diagnostic;
#        equiv -- the judge must PASS, with the argument recorded beside the row.
# A judge is one fixture function run alone, as t_run_all runs a test (a fresh SANDBOX, the build-failure record
# checked). Each mutant is a literal replacement that must match exactly once (DRY=1 checks only that). Every
# restore is checked byte-identical with cmp against a pristine copy.
set -uo pipefail
SP="$1"; WT="$2"; DRY="${DRY:-0}"; SHARD="${SHARD:-0/1}"; ONLY="${ONLY:-}"
si="${SHARD%/*}"; sn="${SHARD#*/}"
R="$SP/r14-matrix-$si"; C="$R/copy"; P="$R/pristine"; w="$R/work"
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
judge() { # <test file> <case function> -> exit; output in $w/judge.out
  ( cd "$C" && awk '$0 != "t_run_all"' "tests/$1" > "tests/.one-$1" && bash -c '. "tests/.one-$1"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out"; exit "$rc"' _ "$1" "$2" ) > "$w/judge.out" 2>&1
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
row L01b over 'a canonical finding with a-empty-comment-then-prose was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '{n = index(substr(rest, 3), "-->"); s = n ? substr(rest, n + 5) :' '{n = index(substr(rest, 5), "-->"); s = n ? substr(rest, n + 7) :'
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
  "$VL" '      if (c == "(") depth++' '      if (0) depth++'
row L16 kill "$LR second-tier-link-title $LS" "$GC" "$RL" \
  "$VL" '  if (c == "\"" || c == vf_lbl_q || c == "(") {' '  if (0) {'
row L17 kill "$LR second-tier-code-span-tag $LS" "$GC" "$RL" \
  "$VL" '  return (w != "") ? w : vf_label_word(s, labels)' '  return w'
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
  "$VL" 'while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\[[ xX]\])/) {' 'while (t ~ /^([^A-Za-z0-9]|\[[ xX]\])/) {'
row N32 kill 'a manifest spelled checkbox-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" 'while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\[[ xX]\])/) {' 'while (t ~ /^([[:space:]*+_-]|[0-9]+[.)])/) {'

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
row B05 over 'a plausible manifest (severity-then-comment) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" ' || t ~ /^<!--/ || t ~ /^~~~/' ' || t ~ /^~~~/'
row B06 over 'a plausible manifest (severity-then-tilde-fence) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" ' || t ~ /^~~~/ || vf_raw_start(t)) return 1' ' || vf_raw_start(t)) return 1'
row B07 over 'a plausible manifest (severity-then-pre-block) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" ' || vf_raw_start(t)) return 1' ') return 1'
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
  "$VL" $'          idseen=(heading ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) || tolower(word[2]) == "finding"\n          next\n        }\n      }' $'          idseen=(heading ~ /[A-Za-z][A-Za-z0-9]*-[0-9]/) || tolower(word[2]) == "finding"\n          next\n        }\n        next\n      }'
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
row P02 kill "$LR escaped-bracket-alt $LS" "$GC" "$RL" "$VL" '  gsub(/\\[][]/, "\003", s)'$'\n' ''
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

say '== the paragraph step and the paragraph checks (T030o46, O-018)'
row P10 kill "$LR blockquoted-tag-split $LS" "$GC" "$RL" "$VL" '  t = s; sub(/^[ \t]*(>[ \t]*)*/, "", t)' '  t = s; sub(/^[ \t]*/, "", t)'
row P11 over 'a plausible manifest (fenced-tag-example) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  if (fenced || t ~ /^[[:space:]]*$/) {vf_para_text' '  if (t ~ /^[[:space:]]*$/) {vf_para_text'
row P11c over 'a canonical finding with a-fenced-tag-example was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '  if (fenced || t ~ /^[[:space:]]*$/) {vf_para_text' '  if (t ~ /^[[:space:]]*$/) {vf_para_text'
row P12 over 'a plausible manifest (heading-then-attribute-line) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  vf_para_open = (t !~ /^#+([ \t]|$)/)' '  vf_para_open = 1'
row P12c over 'a canonical finding with a-heading-then-attribute-line was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '  vf_para_open = (t !~ /^#+([ \t]|$)/)' '  vf_para_open = 1'
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
row P17 equiv '' "$GC" "$RL" "$VL" '  if (vf_para_first != "") return ""'$'\n' ''
# P17 argued: a paragraph whose first line carries a label had that line judged as a line already (refused, or a
# canonical field line whose continuation the field-item rule refuses), so the mutant only repeats a refusal of a
# paragraph already refused; outside any finding it reaches the same outside rule its first line reached.
row P18 equiv '' "$GC" "$RL" "$VL" '  vf_para_first = "refused"'$'\n' ''
# P18 argued: without it a paragraph already refused is refused again at each later line, which adds a message and
# changes no verdict.
row P19 equiv '' "$GC" "$RL" "$VL" '  if (!vf_para_cont) return ""'$'\n' ''
# P19 argued: on a line that opens a paragraph the joined text is that line, whose label the line rules read
# already, so the paragraph check yields nothing a line check did not.

say '== the blocks that end a field item (T030o46, O-021)'
row B13 over 'a plausible manifest (severity-then-four-backtick-fence) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  if (t ~ ("^" b b b b "*[^" b "]*$")) return 1' '  if (t ~ ("^" b b b "[^" b "]*$")) return 1'
row B14 over 'a plausible manifest (severity-then-details) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  if (tolower(t) ~ /^<\/?(address|article' '  if (0 && tolower(t) ~ /^<\/?(address|article'
row B14c over 'a Severity line followed by a details-block was refused under LANG=C (O-021)' "$GC" "$RL" \
  "$VL" '  if (tolower(t) ~ /^<\/?(address|article' '  if (0 && tolower(t) ~ /^<\/?(address|article'
row B15 kill "$LR value-span-twin $LS" "$GC" "$RL" "$VL" '|ul)([ \t>]|\/>|$)/) return 1' '|ul|span)([ \t>]|\/>|$)/) return 1'
row B17 over 'a plausible manifest (severity-then-closing-tag) was refused (T030o43 review 2)' "$GC" "$ML" \
  "$VL" '  if (tolower(t) ~ /^<\/?(address|' '  if (tolower(t) ~ /^<(address|'
say "== done shard $SHARD $(date -u +%H:%M:%SZ) rows=$rowi"
say "r14-mutations failures=$fails"
cd "$SP" && rm -rf "$R"
(( fails == 0 ))
