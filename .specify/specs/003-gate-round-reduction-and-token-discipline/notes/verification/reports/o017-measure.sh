#!/usr/bin/env bash
# O-017 rule measured BEFORE adoption, 2026-09-27 (session 7). Read-only against
# the live worktree. Two standalone copies from the live manifest enumeration:
# U (unrepaired) and P (the candidate rule, applied by literal replacements
# below). Measured in P, against U where history must not move:
#   M1 every repro case gives the C result under every locale;
#   M2 tally for 001, 002 and 003 is byte-identical to U's under C and en_US.UTF-8;
#   M3 vf_snapshot's records equal U's except the harness records, under C and en_US.UTF-8;
#   M4 the captured command sees the caller's LC_ALL exactly (unset, empty, a value);
#   M5 a declared LC_ALL is hashed by the caller's value, as U hashes it, and a
#      capture under a declared LC_ALL is accepted through spec-gate.sh accept.
# P is kept at <scratchpad>/o017-P for the full suite (o017-measure-suite.*).
# Usage: bash o017-measure.sh <scratchpad> <worktree>
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/o017-measure"; U="$R/U"; P="$R/P"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$U" "$P" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
has() { if LC_ALL=C grep -q -F -- "$2" "$3"; then say "PASS $1"; else say "FAIL $1 (missing: $2)"; sed 's/^/  | /' "$3" | head -5; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
for d in "$U" "$P"; do
  ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$d" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
done

# ---- the candidate rule, as literal replacements that must each match once ----
replace() { # <file> <old> <new>
  perl -e '
    my ($f, $old, $new) = @ARGV; local $/; open my $h, "<", $f or exit 3; my $t = <$h>; close $h;
    my $n = () = $t =~ /\Q$old\E/g; exit 4 if $n != 1;
    $t =~ s/\Q$old\E/$new/; open $h, ">", $f or exit 3; print $h $t; close $h; exit 0' "$P/$1" "$2" "$3"
  local rc=$?; check "rule literal applies once: $1" 0 "$rc"
}
cat >> "$P/scripts/lib.sh" <<'EOF'

# --- the harness locale (O-017, candidate) ------------------------------------
harness_locale_pin() {
  if [[ -z "${SDD_HARNESS_CALLER_LC_ALL:-}" || "${LC_ALL-}" != C ]]; then
    if [[ -n "${LC_ALL+set}" ]]; then SDD_HARNESS_CALLER_LC_ALL="set:$LC_ALL"; else SDD_HARNESS_CALLER_LC_ALL=unset; fi
    export SDD_HARNESS_CALLER_LC_ALL
  fi
  export LC_ALL=C
}
harness_caller_locale() {
  case "${SDD_HARNESS_CALLER_LC_ALL:-}" in
    unset) unset LC_ALL;;
    set:*) export LC_ALL="${SDD_HARNESS_CALLER_LC_ALL#set:}";;
  esac
  unset SDD_HARNESS_CALLER_LC_ALL
}
harness_caller_env() {
  if [[ "$1" == LC_ALL ]]; then
    case "${SDD_HARNESS_CALLER_LC_ALL:-}" in
      unset) return 1;;
      set:*) printf '%s' "${SDD_HARNESS_CALLER_LC_ALL#set:}" > "$2"; return 0;;
    esac
  fi
  [[ -n "${!1+set}" ]] || return 1
  printf '%s' "${!1}" > "$2"
}
EOF
check 'rule: lib.sh helpers appended' 0 "$?"
for f in spec-run.sh spec-task.sh spec-gate.sh sdd-analyze.sh spec-ac-coverage.sh spec-evidence.sh; do
  replace "scripts/$f" $'. "$HUB_DIR/scripts/lib.sh"\n' $'. "$HUB_DIR/scripts/lib.sh"\nharness_locale_pin\n'
done
replace scripts/verification-lib.sh $'  . "$_VF_LIB_DIR/lib.sh"\nfi\n' $'  . "$_VF_LIB_DIR/lib.sh"\nfi\nharness_locale_pin\n'
replace scripts/verification-lib.sh '(cd "$cwd" && "$@") > "$staging/output.log" 2>&1' '(cd "$cwd" && harness_caller_locale && "$@") > "$staging/output.log" 2>&1'
replace scripts/spec-run.sh '( cd "$RUN_CWD" && "${CMD[@]}" ) >"$out" 2>&1' '( cd "$RUN_CWD" && harness_caller_locale && "${CMD[@]}" ) >"$out" 2>&1'
replace scripts/verification-lib.sh $'    if [[ -n "${!key+set}" ]]; then\n      printf \'%s\\0\' environment "$key" present "$(printf \'%s\' "${!key}" | vf_hash /dev/stdin)" \'\' \'\' >> "$tmp/inputs"' \
  $'    if harness_caller_env "$key" "$tmp/env-value"; then\n      printf \'%s\\0\' environment "$key" present "$(vf_hash "$tmp/env-value")" \'\' \'\' >> "$tmp/inputs"'
replace scripts/verification-lib.sh $'    priorids="$priorids$(awk "$_VF_AWK_FENCE"\'' $'    awk "$_VF_AWK_FENCE"\''
replace scripts/verification-lib.sh $'    \' "$manifest" | sort -u | tr \'\\n\' \' \')"\n' \
  $'    \' "$manifest" > "$tmp" || { printf \'report recovery: %s: prior-review manifest could not be parsed; reconcile canonical records\\n\' "$manifest" >&2; return 3; }\n    records="$(LC_ALL=C sort -u "$tmp")" || return 3\n    [[ -z "$records" ]] || priorids="$priorids${records//$\'\\n\'/ } "\n'
replace scripts/verification-lib.sh 'local file="$1" gate="$2" output="$3" spec="${4:-}" tmp manifest priorids='"' '" 'local file="$1" gate="$2" output="$3" spec="${4:-}" tmp manifest records priorids='"' '"
for d in "$U" "$P"; do ( cd "$d" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid commit -qm base ) || { say 'FAIL copy commit'; exit 2; }; done
( cd "$P" && bash -n scripts/lib.sh && bash -n scripts/verification-lib.sh && bash -n scripts/spec-run.sh ); check 'rule: P parses' 0 "$?"

nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; if [[ "$l" == ambient ]]; then "$@"; else env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; fi; }
Q=$'\x92'; EMDASH=$'\xe2\x80\x94'; SRC="$(printf 'a%.0s' {1..64})"
manifest() { printf '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n- **Scenario:** %s\n' "$2" > "$1"; }
report() {
  printf '## Round 1\n**Round:** 1\n**Timestamp:** %s\n**Source:** %s\n**Floor:** %s\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nManifest tier binding read across a locale.\n### Finding G-042\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read the parser status\n### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n' \
    "${8:-2026-09-06T12:00:01Z}" "${9:-$SRC}" "${10:-FLOOR-fixture}" "$2" "$6" "$7" "$3" "$4" "$5" > "$1"
}
vfr() { inloc "$2" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$P" "$3" "$w/$1.nul" "$4" > "$w/$1.out" 2> "$w/$1.err"; echo $?; }

say '== M1: the repro cases give the C result under every locale'
spA="$R/specA"; mkdir -p "$spA/notes/verification/reports"
manifest "$spA/notes/verification/reports/opponent-findings-review.md" "the operator${Q}s key vanished"
report "$spA/notes/opponent.md" CLEARED tier-binding open minor 0 1
for l in C en_US.UTF-8 de_DE.UTF-8 C.UTF-8 ja_JP.SJIS ambient; do
  check "M1 A under $l: refused (rc 3)" 3 "$(vfr "A-$l" "$l" "$spA/notes/opponent.md" "$spA")"
  has "M1 A under $l: the lowered-tier refusal" 'clearing verdict rests on 1 lowered severity tier(s) of known findings' "$w/A-$l.err"
done
spC="$R/specC"; mkdir -p "$spC/notes/verification/reports"
manifest "$spC/notes/verification/reports/opponent-findings-review.md" "the operator${Q}s key vanished"
report "$spC/notes/opponent.md" CHALLENGED silent-data-loss open wrong-result 1 0
for l in C en_US.UTF-8 de_DE.UTF-8 C.UTF-8; do
  check "M1 C under $l: refused (rc 3)" 3 "$(vfr "C-$l" "$l" "$spC/notes/opponent.md" "$spC")"
  has "M1 C under $l: the Class refusal" 'finding G-042 changes Class from tier-binding to silent-data-loss' "$w/C-$l.err"
done
spD="$R/specD"; mkdir -p "$spD/notes/verification/reports"
manifest "$spD/notes/verification/reports/opponent-findings-review.md" "the key vanished ${EMDASH} twice"
report "$spD/notes/opponent.md" CLEARED tier-binding open minor 0 1
check 'M1 D under ja_JP.SJIS: refused (rc 3)' 3 "$(vfr D-sjis ja_JP.SJIS "$spD/notes/opponent.md" "$spD")"
awk '$0 != "t_run_all"' "$P/tests/test-spec-gate.sh" > "$P/tests/.o017-spec-gate.sh"
sb="$R/sb-e"; mkdir -p "$sb"
( cd "$P" && SANDBOX="$sb" bash -c '
    . tests/.o017-spec-gate.sh || exit 9
    spec="$(make_verification_git_dir o017)" || exit 9; cli="$(floor_fixture "$spec")" || exit 9
    [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || exit 9
    bash "$cli" floor "$spec" > "$SANDBOX/floor.log" 2>&1 || exit 8
    bash "$cli" round "$spec" opponent > "$SANDBOX/reserve.log" 2>&1 || exit 7
    printf "%s\n%s\n" "$spec" "$cli" > "$SANDBOX/paths"' ) > "$w/E-build.log" 2>&1
check 'M1 E: fixture, floor and reservation' 0 "$?"
spec="$(sed -n 1p "$sb/paths")"; cli="$(sed -n 2p "$sb/paths")"; res="$(cat "$sb/reserve.log")"
rsrc="$(printf '%s' "$res" | sed -n 's/.* source=\([^ ]*\).*/\1/p')"; rfl="$(printf '%s' "$res" | sed -n 's/.* floor=\([^ ]*\).*/\1/p')"; rts="$(printf '%s' "$res" | sed -n 's/.* reserved=\([^ ]*\).*/\1/p')"
mkdir -p "$spec/notes/verification/reports"
manifest "$spec/notes/verification/reports/opponent-findings-review.md" "the operator${Q}s key vanished"
report "$sb/returned.md" CLEARED tier-binding open minor 0 1 "$rts" "$rsrc" "$rfl"
inloc en_US.UTF-8 bash "$cli" round "$spec" opponent --complete "$sb/returned.md" > "$w/E-complete.log" 2>&1
check 'M1 E under en_US.UTF-8: the CLEARED completion is refused (rc 3)' 3 "$?"
has 'M1 E under en_US.UTF-8: the lowered-tier refusal' 'clearing verdict rests on 1 lowered severity tier(s) of known findings' "$w/E-complete.log"
cp -p "$P/$s/spec.md" "$w/spec.orig"
printf '\nA fixture line %s [NEEDS CLARIFICATION: fixture marker]\n' "$Q" >> "$P/$s/spec.md"
( cd "$P" && inloc en_US.UTF-8 bash scripts/sdd-analyze.sh "$s" ) > "$w/F.log" 2>&1
check 'M1 F under en_US.UTF-8: the marker fails the analyzer (rc 1)' 1 "$?"
has 'M1 F: the marker diagnostic' 'unresolved [NEEDS CLARIFICATION] marker(s)' "$w/F.log"
cp -p "$w/spec.orig" "$P/$s/spec.md"
printf '\n- %s AC-998 is a fixture criterion that no test names\n' "$Q" >> "$P/$s/spec.md"
( cd "$P" && inloc en_US.UTF-8 bash scripts/spec-ac-coverage.sh "$s" ) > "$w/G-cov.log" 2>&1
check 'M1 G under en_US.UTF-8: spec-ac-coverage refuses (rc 1)' 1 "$?"
has 'M1 G: AC-998 has no test' 'AC-998 — no test file names it' "$w/G-cov.log"
( cd "$P" && inloc en_US.UTF-8 bash scripts/sdd-analyze.sh "$s" ) > "$w/G-an.log" 2>&1
check 'M1 G under en_US.UTF-8: the analyzer refuses (rc 1)' 1 "$?"
cp -p "$w/spec.orig" "$P/$s/spec.md"
spH="$R/specH"; mkdir -p "$spH"; stamp="$(date -u -v-1M +%Y-%m-%dT%H:%M:%SZ)"
printf -- '---\nspec: h\n---\n\n## Decisions log\n\n- 2026-09-06 — a note with a %s byte\n- %s — waiver: gate=opponent; round=4; after=3; by=fixture; reason=fixture authorization\n' "$Q" "$stamp" > "$spH/STATUS.md"
inloc en_US.UTF-8 bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_round_authorized "$2" opponent 4 2026-09-06T12:00:03Z' _ "$P" "$spH" > "$w/H.log" 2>&1
check 'M1 H under en_US.UTF-8: authorized (rc 0)' 0 "$?"

say '== M2: the recorded history, tally byte-identical to U'
for spec in .specify/specs/001-* .specify/specs/002-* "$s"; do
  sp="$(cd "$U" && ls -d $spec | head -1)"
  for l in C en_US.UTF-8; do
    for d in U P; do ( cd "$R/$d" && inloc "$l" bash scripts/spec-gate.sh tally "$sp" ) > "$w/M2-$d-${sp##*/}-$l.log" 2>&1; echo $? >> "$w/M2-$d-${sp##*/}-$l.log"; done
    check "M2 tally ${sp##*/} under $l equals U (output and rc)" same "$(cmp -s "$w/M2-U-${sp##*/}-$l.log" "$w/M2-P-${sp##*/}-$l.log" && echo same || echo differ)"
  done
done

say '== M3: snapshot records equal U except the harness records'
for l in C en_US.UTF-8; do
  for d in U P; do
    ( cd "$R/$d" && inloc "$l" bash -c '. scripts/verification-lib.sh && vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$w/M3-$d-$l.nul" ) > "$w/M3-$d-$l.out" 2>&1
    # six-field records, one per line; drop the repository path and the harness records
    tr '\0' '\n' < "$w/M3-$d-$l.nul" | paste - - - - - - | LC_ALL=C grep -v -E '^(harness|version)	' | LC_ALL=C sed "s#$R/$d#<repo>#g" > "$w/M3-$d-$l.tsv"
  done
  check "M3 records under $l equal U except harness" same "$(cmp -s "$w/M3-U-$l.tsv" "$w/M3-P-$l.tsv" && echo same || echo differ)"
  say "  | records compared: $(wc -l < "$w/M3-P-$l.tsv" | tr -d ' '); harness records differ as expected: $(tr '\0' '\n' < "$w/M3-P-$l.nul" | paste - - - - - - | LC_ALL=C grep -c '^harness	')"
done

say '== M4/M5: the captured command and a declared LC_ALL'
sb="$R/sb-m"; mkdir -p "$sb"
( cd "$P" && SANDBOX="$sb" bash -c '
    . tests/.o017-spec-gate.sh || exit 9
    spec="$(make_verification_git_dir m45)" || exit 9
    [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || exit 9
    printf "%s\n" "$spec" > "$SANDBOX/paths"' ) > "$w/M4-build.log" 2>&1
check 'M4 fixture' 0 "$?"
spec="$(sed -n 1p "$sb/paths")"; repo="$(cd "$spec/../../.." && pwd -P)"
probe() { # <tag> <env assignment or -u> -> captured LC_ALL as the command saw it
  env ${nolc[@]+"${nolc[@]}"} "$@" bash "$P/scripts/spec-run.sh" "$spec" T001 --cwd "$repo" --no-tick --summary -- \
    bash -c 'printf "seen=%s\n" "${LC_ALL-<unset>}"' > "$w/M4.out" 2>&1
  LC_ALL=C sed -n 's/.*key=seen=\([^ ]*\) .*/\1/p' "$w/M4.out"
}
check 'M4 caller LC_ALL unset: the command sees it unset' '<unset>' "$(probe -u LC_ALL LANG=en_US.UTF-8)"
check 'M4 caller LC_ALL=en_US.UTF-8: the command sees it' 'en_US.UTF-8' "$(probe LC_ALL=en_US.UTF-8)"
check 'M4 caller LC_ALL empty: the command sees it empty' '' "$(probe LC_ALL=)"
say "  | an empty value shows as an empty key field: $(LC_ALL=C grep -c 'key=seen= ' "$w/M4.out") line(s)"
# M5: a declared LC_ALL, hashed by the caller's value, in U and in P
printf 'verification_environment:\n  - '"'"'LC_ALL'"'"'\n' >> "$repo/.specify/stack.yml"
for d in U P; do
  for v in unset en_US.UTF-8 de_DE.UTF-8; do
    if [[ "$v" == unset ]]; then a=(-u LC_ALL); else a=(LC_ALL="$v"); fi
    env ${nolc[@]+"${nolc[@]}"} "${a[@]}" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_snapshot "$2" "$3" "$3" "$4"' _ "$R/$d" "$spec" "$repo" "$w/M5-$d-$v.nul" > /dev/null 2>&1
    tr '\0' '\n' < "$w/M5-$d-$v.nul" | paste - - - - - - | LC_ALL=C grep '^environment	LC_ALL	' > "$w/M5-$d-$v.env"
  done
done
for v in unset en_US.UTF-8 de_DE.UTF-8; do
  check "M5 declared LC_ALL=$v: P hashes the caller value exactly as U" same "$(cmp -s "$w/M5-U-$v.env" "$w/M5-P-$v.env" && [[ -s "$w/M5-P-$v.env" ]] && echo same || echo differ)"
done
check 'M5 two caller values give two records' differ "$(cmp -s "$w/M5-P-en_US.UTF-8.env" "$w/M5-P-de_DE.UTF-8.env" && echo same || echo differ)"
say "  | P records: $(cut -f1-3 "$w/M5-P-unset.env") / $(cut -f1-3 "$w/M5-P-en_US.UTF-8.env")"
live_after="$(livestate)"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$live_after"
say "o017-measure failures=$fails"
rm -rf "$SP/o017-P"; mv "$P" "$SP/o017-P"   # kept for the suite run (o017-measure-suite)
cd "$SP" && rm -rf "$R"
(( fails == 0 ))
