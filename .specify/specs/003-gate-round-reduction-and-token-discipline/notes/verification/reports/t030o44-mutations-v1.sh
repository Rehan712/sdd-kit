#!/usr/bin/env bash
# T030o44 mutation matrix, 2026-10-01 (session 12): every guard of the O-018/O-019 repair isolated in a standalone
# copy built from the live manifest enumeration, every judge under a TMPDIR ending in `/`. It also carries the
# eight T030o43 rows (v5) whose literals T030o44 rewrote (M19, M23, N02, N04, N05, N30, N33, N35; found by
# t030o44-o43matrix-dry.{log,rc}), at their new spelling and with their own diagnostics, so the guards they isolated
# stay isolated. Harness: t030o43-mutations.sh.
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
R="$SP/t030o44-matrix-$si"; C="$R/copy"; P="$R/pristine"; w="$R/work"
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
RL=report_record_line_cases; ML=report_manifest_locale_cases; RR=round_record_line_cases
FIELDS='(Class|Status|Prior|Severity|Where|Root cause|Scenario|Reproduced|Blocks|Wrong behavior|Class-wide fix)'

say "== baseline shard $SHARD $(date -u +%H:%M:%SZ)"
if [[ "$DRY" != 1 && "$si" == 0 ]]; then
  for j in "$GC $RL" "$GC $ML" "$GC report_prior_binding_cases" "$GC report_severity_tier_cases" "$GC shipped_002_tally_case" \
           "$SG $RR" "$SG round_locale_cases"; do
    judge ${j% *} ${j#* }; verdict "B ${j#* } unmutated passes" 0 "$?"
    grep -E 'assert:' "$w/judge.out" | head -3 | sed 's/^/  |   /'
    restore
  done
fi

say '== the label reader (vf_label, vf_finding_heading)'
row L01 kill 'a manifest tier written as inline-comment-with-gt was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'  while ((i = index(s, "<!--")) > 0) {\n    n = index(substr(s, i + 4), "-->")\n    s = n ? substr(s, 1, i - 1) substr(s, i + n + 6) : substr(s, 1, i - 1)\n  }\n' ''
row L02 kill 'a manifest tier written as html-tag was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'  gsub(/<\\/?[A-Za-z][A-Za-z0-9-]*[^>]*>|<[?!][^>]*>/, "", s)\n' ''
row L03 kill 'a manifest tier written as character-reference was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'  while (match(s, /&#[0-9]+;|&#[xX][0-9A-Fa-f]+;/)) {\n' $'  while (0) {\n'
row L04 kill 'a manifest tier written as character-reference was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '    n = (t ~ /^[xX]/) ? vf_label_hex(substr(t, 2)) : t + 0' '    n = t + 0'
row L05 equiv '' "$GC" "$RL" \
  "$VL" '((n > 32 && n < 127) ? sprintf("%c", n) : "\001")' 'sprintf("%c", n)'
# L05 argued: the range keeps a reference to a control or non-ASCII code point from decoding to a byte awk treats
# specially (NUL); every such byte is not an ASCII letter, so the label rule reads it as a non-letter either way,
# and no fixture writes one. Kept as defence, recorded as equivalent.
row L06 kill 'a finding opened by level-four was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'  return t ~ /^[A-Za-z][A-Za-z0-9]*-[0-9]/\n}' $'  return 0\n}'
row L07 kill 'a finding opened by tab-after-hashes was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" '  t = s; sub(/^ *#+/, "", t); sub(/^([[:space:]]|[\200-\377])+/, "", t)' '  t = s; sub(/^ *#+/, "", t)'
row L08 over 'a canonical finding with a-findings-word was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" ' || substr(t, 8, 1) ~ /[A-Za-z0-9]/) return 0' ') return 0'
row L09 over 'a canonical finding with a-lead-in was refused under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'  sub(/^[*_[:space:]]+/, "", t)\n  return (t ~ /^[A-Za-z0-9-]/) ? "" : w\n}' $'  return w\n}'
say '== T030o43 rows carried to their new spelling (the label rule moved into vf_label)'
row M19 kill 'a manifest spelled lowercase-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" '  w = tolower(substr(t, 1, RLENGTH)); if (!index(' '  w = substr(t, 1, RLENGTH); w = (w == "Class" || w == "Severity") ? tolower(w) : ""; if (!index('
row N02 kill 'a manifest spelled fullwidth-colon-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'  sub(/^[*_[:space:]]+/, "", t)\n  return (t ~ /^[A-Za-z0-9-]/) ? "" : w' $'  sub(/^[*_]+/, "", t)\n  return (substr(t, 1, 1) == ":") ? w : ""'
row N04 kill 'a manifest spelled separatorless-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'  if (emph && t ~ /^[*_]/) return w\n' ''
row N33 kill 'a manifest spelled multiword-emphasized-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" $'  if (emph && t !~ /^[A-Za-z0-9-]/) {\n    span = t; sub(/[*_].*$/, "", span)\n    if (span ~ /:[[:space:]]*$/) return w\n    rest = substr(t, length(span) + 1)\n    if (rest ~ /^[*_]/) {sub(/^[*_]+/, "", rest); if (rest ~ /^:/) return w}\n  }\n' ''

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
row N03 kill 'a manifest spelled ordered-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" 'while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\[[ xX]\])/) {' 'while (t ~ /^([^A-Za-z0-9]|\[[ xX]\])/) {'
row N32 kill 'a manifest spelled bullet-character-severity was not refused by its own diagnostic (T030o44)' "$GC" "$ML" \
  "$VL" 'while (t ~ /^([^A-Za-z0-9]|[0-9]+[.)]|\[[ xX]\])/) {' 'while (t ~ /^([[:space:]*+_-]|[0-9]+[.)])/) {'
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
row N05 kill 'a manifest spelled nbsp-after-hashes-below-class-only was not refused by name (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'      !/^ ? ? ?#+([ \\t]|$)/ && /^([[:space:]]|[\\200-\\377])*#+([[:space:]]|[\\200-\\377])*[Ff][Ii][Nn][Dd][Ii][Nn][Gg]([^A-Za-z]|$)/ {\n        flushm(); idseen=1; bad("a Finding heading this grammar cannot read"); next\n      }\n' ''
row K06 kill 'a manifest tier written as subheading-then-hidden-finding was not refused by name under LANG=C (O-018)' "$GC" "$RL" \
  "$VL" $'      !/^ ? ? ?#+([ \\t]|$)/ && /^([[:space:]]|[\\200-\\377])*#+([[:space:]]|[\\200-\\377])*[Ff][Ii][Nn][Dd][Ii][Nn][Gg]([^A-Za-z]|$)/ {\n        flushm(); idseen=1; bad("a Finding heading this grammar cannot read"); next\n      }\n' ''
row M23 kill 'a manifest finding spelled before-another was dropped (T030o43 review 2)' "$GC" "$ML" \
  "$VL" $'          flushm(); idseen=1\n          if (word[3]' $'          idseen=1\n          if (word[3]'
# N30 and N35 of T030o43 mutated two clauses this repair removed by design: the deeper-heading idseen clause (a
# deeper heading now keeps the finding open, so its lines are the finding's, judged by K02) and the flevel reset
# (flevel is read only while a finding is open and is set whenever one opens). They have no literal left.

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
row O03 equiv '' "$GC" shipped_002_tally_case \
  "$VL" '    style=="canonical" && !ended && !fid && ' '    !ended && !fid && '
# O03 argued: every field line of a legacy round follows the numbered line that opens its finding, so no legacy
# field line is outside a finding (measured: shipped 002, the only legacy history that parses, tallies unchanged
# under this mutant, probe1). The canonical restriction is the rule as stated, not a guard a fixture can isolate.
say "== done shard $SHARD $(date -u +%H:%M:%SZ) rows=$rowi"
say "t030o44-mutations failures=$fails"
cd "$SP" && rm -rf "$R"
(( fails == 0 ))
