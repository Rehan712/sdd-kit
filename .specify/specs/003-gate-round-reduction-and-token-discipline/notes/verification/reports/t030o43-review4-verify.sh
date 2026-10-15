#!/usr/bin/env bash
# Invoker verification of focused review 4's findings (t030o43-review4.md), 2026-09-30
# (session 9), BEFORE any change. Read-only against the live worktree. Two standalone
# copies from the live enumeration: CUR (this tree, the session-9 state review 4 saw) and
# REV4 (the review-3 state, t030o43-rev4-base.sh's B4, laid over it). Every run removes
# every LC_* name. The reviewer's end-to-end runs used the same vf_reports call that
# `round --complete` makes; here the findings are reproduced at that function.
# Usage: bash t030o43-review4-verify.sh <scratchpad> <worktree> <rev4-dir>
set -uo pipefail
SP="$1"; WT="$2"; REV="$3"
R="$SP/t030o43-r4v"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$R/CUR" "$R/REV4" "$w" "$TMPDIR"
fails=0; checks=0
say() { printf '%s\n' "$*"; }
check() { checks=$((checks+1)); if [[ "$3" =~ $2 ]]; then say "PASS $1: $3"; else say "FAIL $1: want /$2/ got: $3"; fails=$((fails+1)); fi; }
for d in CUR REV4; do
  ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$R/$d" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
done
( cd "$REV" && find . -type f -print0 | tar --null -T - -cf - ) | ( cd "$R/REV4" && tar -xf - )
cmp -s "$R/REV4/scripts/verification-lib.sh" "$R/CUR/scripts/verification-lib.sh" && { say 'FAIL REV4 kernel equals CUR'; fails=$((fails+1)); }
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
NB=$'\302\240'; LOCS=(C en_US.UTF-8)
tier_round_fixture() {
  local n="$1" verdict_override="$2"; shift 2
  local f id class status sev blockers=0 minors=0 verdict body=''
  for f in "$@"; do
    IFS=: read -r id class status sev <<< "$f"
    if [[ "$status" != resolved ]]; then case "$sev" in minor|degraded) minors=$((minors+1));; *) blockers=$((blockers+1));; esac; fi
    body+="$(printf '### Finding %s\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** bind the tier the way Class is bound' "$id" "$class" "$status" "$sev")"$'\n'
  done
  if [[ -n "$verdict_override" ]]; then verdict="$verdict_override"; elif (( blockers )); then verdict=CHALLENGED; else verdict=CLEARED; fi
  printf '## Round %s\n**Round:** %s\n**Timestamp:** 2026-09-06T12:00:0%sZ\n' "$n" "$n" "$n"
  printf '**Source:** aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n'
  printf '**Floor:** FLOOR-fixture\n**Verdict:** %s\n' "$verdict"
  printf '**Blocking:** %s · **Minor:** %s\n' "$blockers" "$minors"
  printf '### What I attacked\nSeverity tier binding across rounds of one gate.\n'
  printf '%s' "$body"
  printf '### Held up / follow-up tasks\nFixture disposition recorded.\n'
  printf '<!-- gate-round-end: opponent:%s -->\n' "$n"
}
man() { # <kit> <locale> <label> <manifest %b body> [report findings]
  local K="$R/$1" l="$2" sp="$R/m/$3" body="$4" rf="${5:-G-042:tier-binding:open:minor}" out rc fs
  if [[ ! -d "$sp" ]]; then
    mkdir -p "$sp/notes/verification/reports"; IFS=, read -ra fs <<< "$rf"
    tier_round_fixture 1 '' "${fs[@]}" > "$sp/notes/opponent.md"
    printf '%b' "$body" > "$sp/notes/verification/reports/opponent-findings-review.md"
  fi
  out="$(inloc "$l" bash -c '. "$1/scripts/verification-lib.sh"; vf_reports "$2/notes/opponent.md" opponent "$3" "$2"' _ "$K" "$sp" "$w/out.nul" 2>&1)"; rc=$?
  printf 'rc=%s %s' "$rc" "$(printf '%s' "$out" | tr '\n' '|' | LC_ALL=C sed -e "s#$R/##g" -e 's/\x0b/<VT>/g' | cut -c1-260)"
}
both() { # <label> <want CUR> <want REV4> <body> [findings]
  local l
  for l in "${LOCS[@]}"; do
    check "$1 CUR $l" "$2" "$(man CUR "$l" "$1" "$4" "${5:-}")"
    check "$1 REV4 $l" "$3" "$(man REV4 "$l" "$1" "$4" "${5:-}")"
  done
}
SEAL='^rc=0 $'
say '== control'
both control '^rc=3 .*clearing verdict rests on 1 lowered' '^rc=3 .*clearing verdict rests on 1 lowered' '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
say '== R4-F1 (blocking, regression): a sub-heading inside a finding, and a U+2011 in a Finding heading ID'
H='# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n\n#### Assessment\n'
both subhead-unbolded "$SEAL" '^rc=3 .*a severity line outside any Finding' "${H}\nSeverity: data-loss\n"
both subhead-bullet-unbolded "$SEAL" '^rc=3 .*a severity line outside any Finding' "${H}- Severity: data-loss\n"
both subhead-star-bullet "$SEAL" '^rc=3 .*a severity line outside any Finding' "${H}* **Severity:** data-loss\n"
both subhead-bold-colon-out "$SEAL" '^rc=3 .*a severity line outside any Finding' "${H}- **Severity**: data-loss\n"
both subhead-strict '^rc=3 .*a severity line outside any Finding' '^rc=3 .*a severity line outside any Finding' "${H}- **Severity:** data-loss\n"
both nbhyphen-unbolded "$SEAL" '^rc=3 .*a class line outside any Finding' '# P\n\n### Finding G\342\200\221042\n- Class: tier-binding\n- Severity: data-loss\n'
say '== R4-F2 (blocking, pre-existing): a multi-word emphasized label, other list markers'
H2='# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n'
both sev-level "$SEAL" "$SEAL" "$H2- **Severity level:** data-loss\n"
both sev-tier "$SEAL" "$SEAL" "$H2- **Severity tier:** data-loss\n"
both sev-paren '^rc=3 .*a Severity line this grammar cannot read' "$SEAL" "$H2- **Severity (tier):** data-loss\n"
both ubullet "$SEAL" "$SEAL" "$H2\342\200\242 **Severity:** data-loss\n"
both endash-bullet "$SEAL" "$SEAL" "$H2\342\200\223 Severity: data-loss\n"
both checkbox "$SEAL" "$SEAL" "$H2- [x] **Severity:** data-loss\n"
say '== R4-F4 (blocking, pre-existing): findings not written as heading and field lines'
both table-with-heading "$SEAL" "$SEAL" '# P\n\n## Findings\n\n| ID | Class | Severity |\n|----|-------|----------|\n| G-042 | tier-binding | data-loss |\n'
both inline-finding "$SEAL" "$SEAL" '# P\n\n## Findings\n\n- **G-042** (tier-binding) — Severity data-loss\n'
say '== R4-F5 (minor): a Finding heading inside a list item'
both list-heading "$SEAL" "$SEAL" '# P\n\n### Finding G-041\n- **Class:** other-class\n- ### Finding G-042\n- **Severity:** data-loss\n'
both ordered-heading "$SEAL" "$SEAL" '# P\n\n### Finding G-041\n- **Class:** other-class\n1. ### Finding G-042\n- **Severity:** data-loss\n'
say '== R4-F6 (minor, refusing, regression): an emphasized lead-in word inside a finding'
B='### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
both bold-lead-in '^rc=3 .*a second Severity line in finding G-042' "$SEAL" "# P\n\n$B**Severity** was re-read after the repro.\n" G-042:tier-binding:open:data-loss
both bold-lead-in-class '^rc=3 .*a second Class line in finding G-042' "$SEAL" "# P\n\n$B- **Class** and tier were both re-read.\n" G-042:tier-binding:open:data-loss
say '== R4-F8 (minor, refusing): an ID-shaped token that names no finding after the last heading'
O='### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n'
both ac-ref-summary '^rc=3 .*a severity line outside any Finding' '^rc=3 .*a severity line outside any Finding' "# P\n\n$O\n## Summary\n\nThe finding blocks AC-012.\n- Severity: all blocking\n" O-017:harness-locale-decoding:open:wrong-result
both utf8-summary '^rc=3 .*a severity line outside any Finding' '^rc=3 .*a severity line outside any Finding' "# P\n\n$O\n## Summary\n\nThe harness decoded UTF-8 under the caller locale.\n- Severity: one blocking finding\n" O-017:harness-locale-decoding:open:wrong-result
say '== R4-F3 (minor): a criterion that begins with a U+00A0 or a tab after its dash'
mx="$w/f3"; mkdir -p "$mx"
mxcase() { # kit spec-line cell -> catalog text and EQUAL/DIFFER
  printf -- '---\nspec: x\n---\n\n%s\n' "$2" > "$mx/spec.md"; rm -f "$mx/acs" "$mx/m"
  bash -c '. "$1/scripts/verification-lib.sh"; vf_ac_catalog "$2" "$2/acs"' _ "$R/$1" "$mx"
  local text dig got; text="$(tr '\0' '\n' < "$mx/acs" | sed -n 2p)"; dig="$(tr '\0' '\n' < "$mx/acs" | sed -n 3p)"
  printf '| AC-001 | %s; sha256:%s | CAP-1; review: x | %s | PASS |\n' "$3" "$dig" aaaa > "$mx/block"
  bash -c '. "$1/scripts/verification-lib.sh"; vf_matrix_parse "$2/block" "$2/m"' _ "$R/$1" "$mx"
  got="$(tr '\0' '\n' < "$mx/m" | sed -n 2p)"
  printf 'text=[%s] %s' "$(printf '%s' "$text" | LC_ALL=C sed -n l | tr -d '\n')" "$([[ "$got" == "$text; sha256:$dig" ]] && echo EQUAL || echo DIFFER)"
}
for cell in 'one criterion' "${NB}one criterion" ' one criterion'; do
  check "F3 leading U+00A0 in the spec, cell [$cell] CUR" '^text=\[ one criterion\$\] DIFFER$' "$(mxcase CUR "- AC-001 —${NB}one criterion" "$cell")"
done
check 'F3 leading tab in the spec CUR' '^text=\[ one criterion\$\] DIFFER$' "$(mxcase CUR $'- AC-001 —\tone criterion' 'one criterion')"
check 'F3 control: trailing U+00A0 CUR' 'EQUAL$' "$(mxcase CUR "- AC-001 — one criterion${NB}" 'one criterion')"
say '== R4-F7.1 (wording): the umbrella tag pass reads its tag from the mapped line'
check 'F7.1 the tag is taken from $0' '^1$' "$(grep -c -F 'if (match($0, /\[repo:[^]]+\]/)) tag=substr($0,RSTART+6,RLENGTH-7)' "$R/CUR/scripts/sdd-analyze.sh")"
say "t030o43-review4-verify checks=$checks failures=$fails"
cd "$SP" && rm -rf "$R"
(( fails == 0 ))
