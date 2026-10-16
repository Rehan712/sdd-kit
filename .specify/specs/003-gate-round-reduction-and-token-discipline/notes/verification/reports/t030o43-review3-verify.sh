#!/usr/bin/env bash
# Invoker verification of focused review 3's findings (t030o43-review3.md), 2026-09-30
# (session 9), BEFORE any change. Read-only against the live worktree. Three standalone
# copies from the live enumeration: CUR (this tree, the session-8 state review 3 saw),
# REV (the review-2 state, t030o43-base-9.sh's B, laid over it) and PRE (the pre-delta
# files, its P). Every run removes every LC_* name. R3-F6 (mawk) is measured in a
# container by t030o43-r3f6-mawk.sh; here only its macOS half. The review's snippets
# loc.snip, man-obs.snip and stage.snip are run as written; man.sh, art.sh, matrix.sh and
# status-ctx.sh hard-code the reviewer's removed copy, so their bodies are inlined.
# Usage: bash t030o43-review3-verify.sh <scratchpad> <worktree> <pre-dir> <reviewed-dir>
set -uo pipefail
SP="$1"; WT="$2"; PRE="$3"; REV="$4"
R="$SP/t030o43-r3v"; w="$R/work"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
RP="$WT/$s/notes/verification/reports/t030o43-review3-repro"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$R/CUR" "$R/REV" "$R/PRE" "$w" "$TMPDIR"
fails=0; checks=0
say() { printf '%s\n' "$*"; }
check() { # <label> <want ERE> <got>
  checks=$((checks+1))
  if [[ "$3" =~ $2 ]]; then say "PASS $1: $3"; else say "FAIL $1: want /$2/ got: $3"; fails=$((fails+1)); fi
}
info() { say "  info $1: $2"; }
for d in CUR REV PRE; do
  ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$R/$d" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
done
( cd "$REV" && find . -type f -print0 | tar --null -T - -cf - ) | ( cd "$R/REV" && tar -xf - )
( cd "$PRE" && find . -type f -print0 | tar --null -T - -cf - ) | ( cd "$R/PRE" && tar -xf - )
for d in REV PRE; do cmp -s "$R/$d/scripts/verification-lib.sh" "$R/CUR/scripts/verification-lib.sh" && { say "FAIL $d kernel equals CUR's"; fails=$((fails+1)); }; done
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
NB=$'\302\240'; NNB=$'\342\200\257'; ZW=$'\342\200\213'
LOCS=(C en_US.UTF-8)

# The suite's own tier_round_fixture (from the review's man.sh): a canonical round 1
# recording each id:class:status:sev; CLEARED when nothing blocks.
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
man() { # <kit> <locale> <label> <manifest %b body> [report findings] -> "rc=N <stderr>"
  local K="$R/$1" l="$2" sp="$R/m/$3" body="$4" rf="${5:-G-042:tier-binding:open:minor}" out rc fs
  if [[ ! -d "$sp" ]]; then
    mkdir -p "$sp/notes/verification/reports"; IFS=, read -ra fs <<< "$rf"
    tier_round_fixture 1 '' "${fs[@]}" > "$sp/notes/opponent.md"
    printf '%b' "$body" > "$sp/notes/verification/reports/opponent-findings-review.md"
  fi
  out="$(inloc "$l" bash -c '. "$1/scripts/verification-lib.sh"; vf_reports "$2/notes/opponent.md" opponent "$3" "$2"' _ "$K" "$sp" "$w/out.nul" 2>&1)"; rc=$?
  printf 'rc=%s %s' "$rc" "$(printf '%s' "$out" | tr '\n' '|' | LC_ALL=C sed -e "s#$R/##g" -e 's/\x0b/<VT>/g' | cut -c1-300)"
}
fx() { # <kit> <snippet>: the review's fx.sh -- CUR's helpers, SCRIPTS pointed at the kit
  inloc C bash -c 'SANDBOX="$(mktemp -d "$TMPDIR/sb.XXXXXX")"; export SANDBOX; . "$1/tests/helpers.sh"
    SCRIPTS="$2/scripts"; ANALYZE="$SCRIPTS/sdd-analyze.sh"; . "$3"; rm -rf "$SANDBOX"' _ "$R/CUR" "$R/$1" "$2" 2>&1
}

say "== control: the canonical manifest refuses the CLEARED round in every kit and locale"
for k in CUR REV PRE; do for l in "${LOCS[@]}"; do
  check "control $k $l" '^rc=3 .*clearing verdict rests on 1 lowered severity tier' "$(man "$k" "$l" control '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n')"
done; done

say "== R3-F1: the value after the LAST bold label on a field line"
for l in "${LOCS[@]}"; do
  check "F1 sev-then-prior CUR $l (seals: the regression)" '^rc=0 $' "$(man CUR "$l" sev-then-prior '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss; **Prior:** minor\n')"
  check "F1 sev-then-prior REV $l (refused by name)" '^rc=3 .*a Severity this grammar cannot read' "$(man REV "$l" sev-then-prior x)"
  check "F1 sev-minor-then-prior-dataloss CUR $l (the LAST value read)" '^rc=3 .*clearing verdict rests on 1 lowered' "$(man CUR "$l" sev-minor-then-dl '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor; **Prior:** data-loss\n')"
  check "F1 class-then-status CUR $l (Class bound to open)" '^rc=3 .*finding G-042 changes Class from open to tier-binding' "$(man CUR "$l" class-then-status '# P\n\n### Finding G-042\n- **Class:** tier-binding; **Status:** open\n- **Severity:** data-loss\n')"
  check "F1 class-then-status REV $l" '^rc=3 .*a Class this grammar cannot read' "$(man REV "$l" class-then-status x)"
done
info "F1 sev-then-prior PRE en_US.UTF-8" "$(man PRE en_US.UTF-8 sev-then-prior x)"

say "== R3-F2: a Severity label not followed immediately by a colon is prose (the tier drops)"
H='# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n'
while IFS='|' read -r label tail; do
  for k in CUR REV; do for l in "${LOCS[@]}"; do
    # Correction to review 3 (run 1): review 2's catch-all refused the ordered-list
    # spelling by name, so that member is a regression of session 8, not pre-existing.
    if [[ "$label" == ordered && "$k" == REV ]]; then
      check "F2 $label $k $l (refused by name: a regression in CUR)" '^rc=3 manifest line 5: a Class or Severity line this grammar cannot read' "$(man "$k" "$l" "f2-$label" "$H$tail")"
    else
      check "F2 $label $k $l (seals)" '^rc=0 $' "$(man "$k" "$l" "f2-$label" "$H$tail")"
    fi
  done; done
  info "F2 $label PRE en_US.UTF-8" "$(man PRE en_US.UTF-8 "f2-$label" x)"
done <<CASES
space-colon|- **Severity :** data-loss\n
nbsp-colon|- **Severity${NB}:** data-loss\n
nnbsp-colon|- **Severity${NNB}:** data-loss\n
bold-space-colon|- **Severity** : data-loss\n
emdash|- **Severity** — data-loss\n
fullwidth-colon|- **Severity：** data-loss\n
ordered|1. **Severity:** data-loss\n
nocolon|- **Severity** data-loss\n
CASES

say "== R3-F3: a Finding line not read as a heading moves a Class-less finding's Severity into the finding above"
for l in "${LOCS[@]}"; do
  check "F3 nbsp-after-hashes CUR $l (seals: the regression)" '^rc=0 $' "$(man CUR "$l" f3-nbsp-after "# P\n\n### Finding G-041\n- **Class:** other-class\n###${NB}Finding G-042\n- **Severity:** data-loss\n")"
  check "F3 nbsp-after-hashes REV $l (refused by review 2's catch-all)" '^rc=3 .*a Finding heading this grammar cannot read' "$(man REV "$l" f3-nbsp-after x)"
  check "F3 readable control CUR $l" '^rc=3 .*finding G-042 has no readable Class' "$(man CUR "$l" f3-readable '# P\n\n### Finding G-041\n- **Class:** other-class\n### Finding G-042\n- **Severity:** data-loss\n')"
  for v in "tab|\t### Finding G-042" "zwsp|${ZW}### Finding G-042" "nbsp-before|${NB}### Finding G-042"; do
    for k in CUR REV; do
      check "F3 ${v%%|*} $k $l (seals, pre-existing)" '^rc=0 $' "$(man "$k" "$l" "f3-${v%%|*}" "# P\n\n### Finding G-041\n- **Class:** other-class\n${v#*|}\n- **Severity:** data-loss\n")"
    done
  done
done

say "== R3-F4: Tests locators and manual observation names are taken from the mapped line"
out="$(fx CUR "$RP/loc.snip")"; check "F4 locator CUR (VT in the catalog, locators refused)" 'locators rc=3' "$(printf '%s' "$out" | tr '\n' '|')"
check "F4 locator CUR catalog carries VT" 'my\\vcheck\.sh' "$(printf '%s' "$out" | tr '\n' '|')"
out="$(fx REV "$RP/loc.snip")"; check "F4 locator REV (as written, locators pass)" 'locators rc=0.*my\\302\\240check\.sh' "$(printf '%s' "$out" | tr '\n' '|')"
out="$(fx CUR "$RP/man-obs.snip")"; check "F4 manual observation CUR" 'catalog locator: release\\vobservation.*names DIFFER' "$(printf '%s' "$out" | tr '\n' '|')"
out="$(fx REV "$RP/man-obs.snip")"; check "F4 manual observation REV" 'names EQUAL' "$(printf '%s' "$out" | tr '\n' '|')"

say "== R3-F5: prose that starts Class: or Severity: is now refused by name"
B='### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
RF=G-042:tier-binding:open:data-loss
for l in "${LOCS[@]}"; do
  check "F5 summary-prose CUR $l" '^rc=3 .*a class line outside any Finding' "$(man CUR "$l" f5-summary "# Prior review\n\n$B\n## Summary\n\n- Class: tier-binding, one finding\n- Severity: all blocking\n" "$RF")"
  check "F5 intro-prose CUR $l" '^rc=3 .*a severity line outside any Finding' "$(man CUR "$l" f5-intro "# Prior review\n\nSeverity: every finding below is blocking.\n\n$B" "$RF")"
  check "F5 nested-mention CUR $l" '^rc=3 .*a second Severity line in finding G-042' "$(man CUR "$l" f5-nested "# Prior review\n\n$B- **Scenario:** the tier moved\n  - Severity: raised from minor after the repro\n" "$RF")"
  for c in summary intro nested; do check "F5 $c REV $l (accepted)" '^rc=0 $' "$(man REV "$l" "f5-$c" x "$RF")"; done
done

say "== R3-F6 (macOS half): a Finding heading whose ID is followed by a U+00A0"
rpt="$R/f6"; mkdir -p "$rpt/notes"
tier_round_fixture 1 '' G-042:tier-binding:open:data-loss | LC_ALL=C sed "s/^### Finding G-042\$/### Finding G-042${NB}/" > "$rpt/notes/opponent.md"
for k in CUR REV; do for l in "${LOCS[@]}"; do
  o="$(inloc "$l" bash -c '. "$1/scripts/verification-lib.sh"; vf_reports "$2/notes/opponent.md" opponent "$3" "$2"' _ "$R/$k" "$rpt" "$w/out.nul" 2>&1)"; rc=$?
  info "F6 $k $l" "rc=$rc $(printf '%s' "$o" | tr '\n' '|' | LC_ALL=C sed 's/\x0b/<VT>/g' | cut -c1-160)"
done; done

say "== R3-F7: the STATUS identity view omits the quoting state entering the Decisions log"
st="$R/f7"; mkdir -p "$st/a" "$st/b"
waiver='- 2026-09-27T15:55:36Z — waiver: gate=opponent; round=4; after=3; by=someone; reason=a fixture reason'
for v in a b; do
  {
    printf -- '---\nspec: x\n---\n\n## Where things stand\n\nState.\n'
    [[ "$v" == a ]] && printf '\n````text\nan example the author never closed\n'
    printf '\n## Decisions log\n\n%s\n\n```\n- 2026-09-06 — quoted\n````\n\n## Open questions / blockers\n\n- none\n' "$waiver"
  } > "$st/$v/STATUS.md"
done
for k in CUR REV; do
  inloc C bash -c '. "$1/scripts/verification-lib.sh"; vf_semantic_file .specify/specs/x/STATUS.md "$2/a/STATUS.md" "$2/a.sem"; vf_semantic_file .specify/specs/x/STATUS.md "$2/b/STATUS.md" "$2/b.sem"' _ "$R/$k" "$st"
  check "F7 $k identity views" 'IDENTICAL' "$(cmp -s "$st/a.sem" "$st/b.sem" && echo IDENTICAL || echo differ)"
  inloc C bash -c '. "$1/scripts/verification-lib.sh"; vf_round_authorized "$2" opponent 4 2026-09-27T00:00:00Z' _ "$R/$k" "$st/a" > /dev/null 2>&1; ra=$?
  inloc C bash -c '. "$1/scripts/verification-lib.sh"; vf_round_authorized "$2" opponent 4 2026-09-27T00:00:00Z' _ "$R/$k" "$st/b" > /dev/null 2>&1; rb=$?
  check "F7 $k authorization a/b" '^a=4 b=0$' "a=$ra b=$rb"
done

say "== R3-F8: a matrix criterion cell copied as written no longer equals the AC catalog"
mx="$R/f8"; mkdir -p "$mx"
printf -- '---\nspec: x\n---\n\n- AC-001 — one%scriterion\n' "$NB" > "$mx/spec.md"
for k in CUR REV; do
  rm -f "$mx/acs"; inloc C bash -c '. "$1/scripts/verification-lib.sh"; vf_ac_catalog "$2" "$2/acs"' _ "$R/$k" "$mx" || info "F8 $k" "catalog rc=$?"
  text="$(tr '\0' '\n' < "$mx/acs" | sed -n 2p)"; dig="$(tr '\0' '\n' < "$mx/acs" | sed -n 3p)"
  printf '| AC-001 | %s; sha256:%s | CAP-1; review: x | %s | PASS |\n' "one${NB}criterion" "$dig" aaaa > "$mx/block"
  inloc C bash -c '. "$1/scripts/verification-lib.sh"; vf_matrix_parse "$2/block" "$2/m"' _ "$R/$k" "$mx"
  got="$(tr '\0' '\n' < "$mx/m" | sed -n 2p)"
  r=DIFFER; [[ "$got" == "$text; sha256:$dig" ]] && r=EQUAL
  info "F8 $k catalog text" "$(printf '%s' "$text" | LC_ALL=C sed -n l)"
  [[ "$k" == CUR ]] && check "F8 CUR cell as written" '^DIFFER$' "$r" || check "F8 REV cell as written" '^EQUAL$' "$r"
done

say "== R3-F9: vf_fm_value and fm_get disagree on verification_contract:<U+00A0>1 (E02's premise)"
fm="$R/f9"; mkdir -p "$fm"; printf -- '---\nspec: x\nverification_contract:%s1\n---\n' "$NB" > "$fm/spec.md"
a="$(inloc C bash -c 'HUB_DIR="$1"; . "$1/scripts/lib.sh"; . "$1/scripts/verification-lib.sh"; vf_fm_value "$2" verification_contract' _ "$R/CUR" "$fm/spec.md" | LC_ALL=C sed -n l)"
b="$(inloc C bash -c 'HUB_DIR="$1"; . "$1/scripts/lib.sh"; . "$1/scripts/verification-lib.sh"; fm_get "$2" verification_contract' _ "$R/CUR" "$fm/spec.md" | LC_ALL=C sed -n l)"
check "F9 CUR readers" '^vf_fm_value=1\$ fm_get=\\302\\2401\$$' "vf_fm_value=$a fm_get=$b"
check "F9 no checkpoint fixture feeds the U+00A0 contract" '^0$' "$(awk '/^checkpoint_parse_fault_cases\(\)/,/^}/' "$R/CUR/tests/test-spec-gate.sh" | grep -c -e '302.240' -e 'nbsp' -e 'NB')"

say "== R3-F10: the artifact-name wrapper set is an enumeration"
lg="$R/f10"; mkdir -p "$lg/shots"; : > "$lg/shots/a.png"
printf -- '---\nspec: 001-legacy\n---\n\n# Spec\n\n- AC-001 — x\n' > "$lg/spec.md"
while IFS='|' read -r label ev want; do
  printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — Legacy task\n  - *Acceptance:* legacy\n  - *Evidence:* screenshot %s\n' "$ev" > "$lg/tasks.md"
  for k in CUR REV; do for l in "${LOCS[@]}"; do
    o="$(cd "$lg" && inloc "$l" bash "$R/$k/scripts/spec-evidence.sh" "$lg" 2>&1)"; rc=$?
    [[ "$label" == ascii && "$k" == REV ]] && { info "F10 $label $k $l" "rc=$rc"; continue; }
    check "F10 $label $k $l" "$want" "rc=$rc $(printf '%s' "$o" | grep -o "names artifact '[^']*'" | head -1)"
  done; done
done <<CASES
german|„shots/a.png“|^rc=[1-9][0-9]* names artifact
swedish|”shots/a.png”|^rc=[1-9][0-9]* names artifact
lenticular|【shots/a.png】|^rc=[1-9][0-9]* names artifact
danish|»shots/a.png«|^rc=[1-9][0-9]* names artifact
ascii|"shots/a.png"|^rc=0
CASES

say "== R3-F11: the checkpoint-stage fixture proves vf_config only"
out="$(fx CUR "$RP/stage.snip")"; say "$out" | sed 's/^/  | /'
check "F11 CUR U+00A0 suffix" 'suffix= 302 240 ?\] config rc=0 \|.*unknown task stage for through-stage: Backend.*through-stage rc=1' "$(printf '%s' "$out" | grep -F '302 240')"
check "F11 CUR ASCII space suffix (pre-existing)" 'config rc=0 \|.*unknown task stage for through-stage: Backend.*through-stage rc=1' "$(printf '%s' "$out" | grep -F 'suffix= ]')"
out="$(fx REV "$RP/stage.snip")"; say "$out" | sed 's/^/  | /'
check "F11 REV U+00A0 suffix" 'suffix= 302 240 ?\] .*unknown checkpoint stage Backend.*config rc=1' "$(printf '%s' "$out" | grep -F '302 240')"

say "t030o43-review3-verify checks=$checks failures=$fails"
cd "$SP" && rm -rf "$R"
(( fails == 0 ))
