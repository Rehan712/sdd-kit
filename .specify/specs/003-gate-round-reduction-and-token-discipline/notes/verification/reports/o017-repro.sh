#!/usr/bin/env bash
# O-017 reproduction BEFORE any repair, 2026-09-27 (session 7). Read-only
# against the live worktree: every case runs in a standalone copy built from
# the live manifest enumeration, under the scratchpad, with TMPDIR inside it.
# The live status outside notes/verification/ is compared before and after.
# Usage: bash o017-repro.sh <scratchpad> <worktree>
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/o017-repro"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
has() { if grep -q -F -- "$2" "$3"; then say "PASS $1"; else say "FAIL $1 (missing: $2)"; sed 's/^/  | /' "$3" | head -5; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$C" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$C" && git init -q && git add -A && git -c user.name=r -c user.email=r@invalid commit -qm base ) || { say 'FAIL copy commit'; exit 2; }

# A locale run: every LC_* name removed, LANG set. "ambient" keeps this shell's own.
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; if [[ "$l" == ambient ]]; then "$@"; else env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; fi; }
say "ambient: $(env | LC_ALL=C grep -E '^(LANG|LC_)' | tr '\n' ' ')"
Q=$'\x92'; RSQ=$'\xe2\x80\x99'; EMDASH=$'\xe2\x80\x94'
SRC="$(printf 'a%.0s' {1..64})"

manifest() { # file scenario-text
  printf '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n- **Scenario:** %s\n' "$2" > "$1"
}
report() { # file verdict class status sev blocking minor [timestamp source floor]
  printf '## Round 1\n**Round:** 1\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nManifest tier binding read across a locale.\n### Finding G-042\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read the parser status\n### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n' \
    "${8:-2026-09-06T12:00:01Z}" "${9:-$SRC}" "${10:-FLOOR-fixture}" "$2" "$6" "$7" "$3" "$4" "$5" > "$1"
}
vfr() { # tag locale report spec -> rc in $w/<tag>.rc, stderr in $w/<tag>.err
  inloc "$2" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$C" "$3" "$w/$1.nul" "$4" > "$w/$1.out" 2> "$w/$1.err"
  echo $? > "$w/$1.rc"; cat "$w/$1.rc"
}

say '== A: manifest carries one cp1252 apostrophe (0x92); CLEARED round re-records G-042 open at minor'
spA="$R/specA"; mkdir -p "$spA/notes/verification/reports"
manifest "$spA/notes/verification/reports/opponent-findings-review.md" "the operator${Q}s key vanished"
report "$spA/notes/opponent.md" CLEARED tier-binding open minor 0 1
check 'A under C: refused (rc 3)' 3 "$(vfr A-C C "$spA/notes/opponent.md" "$spA")"
has 'A under C: the lowered-tier refusal' 'clearing verdict rests on 1 lowered severity tier(s) of known findings' "$w/A-C.err"
for l in en_US.UTF-8 de_DE.UTF-8 C.UTF-8 ambient; do
  check "A under $l: sealed (rc 0)" 0 "$(vfr "A-$l" "$l" "$spA/notes/opponent.md" "$spA")"
  say "  | stderr: $(head -1 "$w/A-$l.err" | LC_ALL=C cut -c1-120)"
done

say '== B: control, the same manifest with the apostrophe as UTF-8 U+2019'
spB="$R/specB"; mkdir -p "$spB/notes/verification/reports"
manifest "$spB/notes/verification/reports/opponent-findings-review.md" "the operator${RSQ}s key vanished"
report "$spB/notes/opponent.md" CLEARED tier-binding open minor 0 1
for l in C en_US.UTF-8 de_DE.UTF-8 C.UTF-8; do
  check "B under $l: refused (rc 3)" 3 "$(vfr "B-$l" "$l" "$spB/notes/opponent.md" "$spB")"
done

say '== C: Class binding; CHALLENGED round reuses G-042 as silent-data-loss over a 0x92 manifest'
spC="$R/specC"; mkdir -p "$spC/notes/verification/reports"
manifest "$spC/notes/verification/reports/opponent-findings-review.md" "the operator${Q}s key vanished"
report "$spC/notes/opponent.md" CHALLENGED silent-data-loss open wrong-result 1 0
check 'C under C: refused (rc 3)' 3 "$(vfr C-C C "$spC/notes/opponent.md" "$spC")"
has 'C under C: the Class-binding refusal' 'finding G-042 changes Class from tier-binding to silent-data-loss' "$w/C-C.err"
for l in en_US.UTF-8 de_DE.UTF-8 C.UTF-8; do
  check "C under $l: accepted (rc 0)" 0 "$(vfr "C-$l" "$l" "$spC/notes/opponent.md" "$spC")"
done

say '== D: Shift-JIS; a valid UTF-8 manifest whose only non-ASCII is one em dash'
spD="$R/specD"; mkdir -p "$spD/notes/verification/reports"
manifest "$spD/notes/verification/reports/opponent-findings-review.md" "the key vanished ${EMDASH} twice"
report "$spD/notes/opponent.md" CLEARED tier-binding open minor 0 1
check 'D under C: refused (rc 3)' 3 "$(vfr D-C C "$spD/notes/opponent.md" "$spD")"
check 'D under en_US.UTF-8: refused (rc 3)' 3 "$(vfr D-en en_US.UTF-8 "$spD/notes/opponent.md" "$spD")"
check 'D under ja_JP.SJIS: sealed (rc 0)' 0 "$(vfr D-sjis ja_JP.SJIS "$spD/notes/opponent.md" "$spD")"
say "  | SJIS stderr: $(head -1 "$w/D-sjis.err" | LC_ALL=C cut -c1-120)"

say '== E: end to end through spec-gate.sh; fixture built, floor sealed and round 1 reserved under C each time'
awk '$0 != "t_run_all"' "$C/tests/test-spec-gate.sh" > "$C/tests/.o017-spec-gate.sh"
for l in C en_US.UTF-8; do
  sb="$R/sb-$l"; mkdir -p "$sb"
  ( cd "$C" && SANDBOX="$sb" bash -c '
      . tests/.o017-spec-gate.sh || exit 9
      spec="$(make_verification_git_dir o017)" || exit 9
      cli="$(floor_fixture "$spec")" || exit 9
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { cat "$SANDBOX/.fixture-build-failed"; exit 9; }
      bash "$cli" floor "$spec" > "$SANDBOX/floor.log" 2>&1 || exit 8
      bash "$cli" round "$spec" opponent > "$SANDBOX/reserve.log" 2>&1 || exit 7
      printf "%s\n%s\n" "$spec" "$cli" > "$SANDBOX/paths"' ) > "$w/E-$l-build.log" 2>&1
  check "E $l: fixture, floor and reservation under C" 0 "$?"
  spec="$(sed -n 1p "$sb/paths")"; cli="$(sed -n 2p "$sb/paths")"; res="$(cat "$sb/reserve.log")"
  rsrc="$(printf '%s' "$res" | sed -n 's/.* source=\([^ ]*\).*/\1/p')"; rfl="$(printf '%s' "$res" | sed -n 's/.* floor=\([^ ]*\).*/\1/p')"
  rts="$(printf '%s' "$res" | sed -n 's/.* reserved=\([^ ]*\).*/\1/p')"
  mkdir -p "$spec/notes/verification/reports"
  manifest "$spec/notes/verification/reports/opponent-findings-review.md" "the operator${Q}s key vanished"
  report "$sb/returned.md" CLEARED tier-binding open minor 0 1 "$rts" "$rsrc" "$rfl"
  inloc "$l" bash "$cli" round "$spec" opponent --complete "$sb/returned.md" > "$w/E-$l-complete.log" 2>&1; echo $? > "$w/E-$l-complete.rc"
  say "  | complete under $l: rc=$(cat "$w/E-$l-complete.rc") $(LC_ALL=C grep -v towc "$w/E-$l-complete.log" | head -1 | LC_ALL=C cut -c1-150)"
  inloc "$l" bash "$cli" tally "$spec" > "$w/E-$l-tally.log" 2>&1; echo $? > "$w/E-$l-tally.rc"
  say "  | tally under $l: rc=$(cat "$w/E-$l-tally.rc") $(LC_ALL=C grep -E '^(blocking|severity)' "$w/E-$l-tally.log" | tr '\n' ' ')"
  if [[ "$l" == en_US.UTF-8 ]]; then
    inloc C bash "$cli" tally "$spec" > "$w/E-$l-tally-C.log" 2>&1; echo $? > "$w/E-$l-tally-C.rc"
    say "  | the same sealed history, tally under C: rc=$(cat "$w/E-$l-tally-C.rc") $(LC_ALL=C grep -m1 'report recovery' "$w/E-$l-tally-C.log" | LC_ALL=C cut -c1-150)"
    inloc C bash "$cli" round "$spec" opponent > "$w/E-$l-next-C.log" 2>&1; echo $? > "$w/E-$l-next-C.rc"
    inloc en_US.UTF-8 bash "$cli" round "$spec" opponent > "$w/E-$l-next-en.log" 2>&1; echo $? > "$w/E-$l-next-en.rc"
    say "  | round 2 reservation: under C rc=$(cat "$w/E-$l-next-C.rc"), then under en_US.UTF-8 rc=$(cat "$w/E-$l-next-en.rc")"
  fi
done
check 'E: under C the CLEARED completion is refused (rc 3)' 3 "$(cat "$w/E-C-complete.rc")"
has 'E: under C the lowered-tier refusal' 'clearing verdict rests on 1 lowered severity tier(s) of known findings' "$w/E-C-complete.log"
check 'E: under en_US.UTF-8 the identical bytes seal CLEARED (rc 0)' 0 "$(cat "$w/E-en_US.UTF-8-complete.rc")"
has 'E: under en_US.UTF-8 the completion line' 'round completed gate=opponent round=1 verdict=CLEARED' "$w/E-en_US.UTF-8-complete.log"
check 'E: the sealed history is refused by tally under C (rc 3)' 3 "$(cat "$w/E-en_US.UTF-8-tally-C.rc")"
check 'E: round 2 under C is refused (rc 3)' 3 "$(cat "$w/E-en_US.UTF-8-next-C.rc")"
check 'E: round 2 under en_US.UTF-8 reserves (rc 0)' 0 "$(cat "$w/E-en_US.UTF-8-next-en.rc")"

say '== F: analyzer sibling; one 0x92 byte before a [NEEDS CLARIFICATION] marker in 003 spec.md'
cp -p "$C/$s/spec.md" "$w/spec.orig"
printf '\nA fixture line %s [NEEDS CLARIFICATION: fixture marker]\n' "$Q" >> "$C/$s/spec.md"
for l in C en_US.UTF-8; do
  ( cd "$C" && inloc "$l" bash scripts/sdd-analyze.sh "$s" ) > "$w/F-$l.log" 2>&1; echo $? > "$w/F-$l.rc"
  say "  | analyzer under $l: rc=$(cat "$w/F-$l.rc") $(tail -1 "$w/F-$l.log")"
done
check 'F under C: the marker fails the analyzer (rc 1)' 1 "$(cat "$w/F-C.rc")"
has 'F under C: the marker diagnostic' 'unresolved [NEEDS CLARIFICATION] marker(s)' "$w/F-C.log"
check 'F under en_US.UTF-8: the analyzer passes (rc 0)' 0 "$(cat "$w/F-en_US.UTF-8.rc")"
has 'F under en_US.UTF-8: the marker reads as absent' 'no unresolved [NEEDS CLARIFICATION] markers' "$w/F-en_US.UTF-8.log"
cp -p "$w/spec.orig" "$C/$s/spec.md"

say '== G: checker sibling (not in the report); one 0x92 byte before an AC id no test names'
printf '\n- %s AC-998 is a fixture criterion that no test names\n' "$Q" >> "$C/$s/spec.md"
for l in C en_US.UTF-8; do
  ( cd "$C" && inloc "$l" bash scripts/spec-ac-coverage.sh "$s" ) > "$w/G-cov-$l.log" 2>&1; echo $? > "$w/G-cov-$l.rc"
  ( cd "$C" && inloc "$l" bash scripts/sdd-analyze.sh "$s" ) > "$w/G-an-$l.log" 2>&1; echo $? > "$w/G-an-$l.rc"
  say "  | under $l: spec-ac-coverage rc=$(cat "$w/G-cov-$l.rc") '$(tail -1 "$w/G-cov-$l.log")'; analyzer rc=$(cat "$w/G-an-$l.rc") '$(tail -1 "$w/G-an-$l.log")'"
done
check 'G under C: spec-ac-coverage refuses (rc 1)' 1 "$(cat "$w/G-cov-C.rc")"
has 'G under C: AC-998 has no test' 'AC-998 — no test file names it' "$w/G-cov-C.log"
check 'G under en_US.UTF-8: spec-ac-coverage passes (rc 0)' 0 "$(cat "$w/G-cov-en_US.UTF-8.rc")"
check 'G under C: the analyzer refuses (rc 1)' 1 "$(cat "$w/G-an-C.rc")"
has 'G under C: AC-998 uncovered' 'AC-998' "$w/G-an-C.log"
check 'G under en_US.UTF-8: the analyzer passes (rc 0)' 0 "$(cat "$w/G-an-en_US.UTF-8.rc")"
cp -p "$w/spec.orig" "$C/$s/spec.md"

say '== H: the waiver parser (:2465) discards its status; a 0x92 line in the Decisions log above a valid waiver'
spH="$R/specH"; mkdir -p "$spH"
stamp="$(date -u -v-1M +%Y-%m-%dT%H:%M:%SZ)"
printf -- '---\nspec: h\n---\n\n## Decisions log\n\n- 2026-09-06 — a note with a %s byte\n- %s — waiver: gate=opponent; round=4; after=3; by=fixture; reason=fixture authorization\n' "$Q" "$stamp" > "$spH/STATUS.md"
for l in C en_US.UTF-8; do
  inloc "$l" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_round_authorized "$2" opponent 4 2026-09-06T12:00:03Z' _ "$C" "$spH" > "$w/H-$l.log" 2>&1; echo $? > "$w/H-$l.rc"
  say "  | under $l: rc=$(cat "$w/H-$l.rc") $(LC_ALL=C grep -v towc "$w/H-$l.log" | tr '\n' ' ' | LC_ALL=C cut -c1-200)"
done
check 'H under C: authorized (rc 0)' 0 "$(cat "$w/H-C.rc")"
check 'H under en_US.UTF-8: denied (rc 4), fail closed' 4 "$(cat "$w/H-en_US.UTF-8.rc")"
has 'H under en_US.UTF-8: the refusal claims no candidate exists' 'no candidate authorization line for this gate was found' "$w/H-en_US.UTF-8.log"

say '== I: the recorded history, unrepaired: tally and snapshot across locales'
for spec in .specify/specs/001-* .specify/specs/002-* "$s"; do
  sp="$(cd "$C" && ls -d $spec | head -1)"
  for l in C en_US.UTF-8; do
    ( cd "$C" && inloc "$l" bash scripts/spec-gate.sh tally "$sp" ) > "$w/I-tally-${sp##*/}-$l.log" 2>&1; echo $? > "$w/I-tally-${sp##*/}-$l.rc"
  done
  if cmp -s "$w/I-tally-${sp##*/}-C.log" "$w/I-tally-${sp##*/}-en_US.UTF-8.log"; then same=identical; else same=DIFFER; fi
  say "  | tally ${sp##*/}: C rc=$(cat "$w/I-tally-${sp##*/}-C.rc"), en_US.UTF-8 rc=$(cat "$w/I-tally-${sp##*/}-en_US.UTF-8.rc"), output $same"
done
for l in C C.UTF-8 en_US.UTF-8 en_US.ISO8859-1; do
  ( cd "$C" && inloc "$l" bash -c '. scripts/verification-lib.sh && vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$w/I-snap-$l.nul" ) > "$w/I-snap-$l.out" 2> "$w/I-snap-$l.err"
  say "  | snapshot under $l: rc=$? digest=$(head -c 16 "$w/I-snap-$l.out")"
done
check 'I: snapshot equal under C and en_US.UTF-8' "$(cat "$w/I-snap-C.out")" "$(cat "$w/I-snap-en_US.UTF-8.out")"

live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "o017-repro failures=$fails"
cd "$SP" && rm -rf "$R"
(( fails == 0 ))
