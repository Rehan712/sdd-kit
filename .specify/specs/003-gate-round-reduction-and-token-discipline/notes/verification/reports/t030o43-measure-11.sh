#!/usr/bin/env bash
# T030o43 session 10: the TMPDIR-spelling rule, measured before adoption (the user's class-wide choice after
# CAP-521-Q8OdIp failed at rc 1; reproduction t030o43-tmpdir-repro.*). Read-only against the live worktree.
# Kits built from the live enumeration: CUR (this tree) and D (CUR with the candidate pairs
# t030o43-edits/helpers-1, tv-5, vc-6 and kernel-8). Every exit read back from its receipt.
# Usage from the worktree root: bash <this> <scratch-dir> <a|full>
#   a     load-time spellings, the new fixture and its mutant, the failing member, snapshot records, ShellCheck
#   full  full suites (bash tests/run.sh && bash tests/shellcheck.sh): a census on CUR under a symlinked and an
#         unset TMPDIR, and D under a trailing-slash, a symlinked-with-trailing-slash and an unset TMPDIR;
#         three in parallel, then two, each in its own copy, each copy checked unchanged
set -uo pipefail
SP="${1:?scratch}"; PART="${2:?part}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
E="$WT/$s/notes/verification/reports/t030o43-edits"
M="$SP/t030o43-m11-$PART"; rm -rf "$M"; mkdir -p "$M"
fails=0; passes=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; passes=$((passes+1)); else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
copystate() { ( cd "$1" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | shasum -a 256 | cut -c1-16; }
mkkit() { # <dir> [D]: the live enumeration, a git repository, and for D the candidate applied
  mkdir -p "$1" || return 1
  ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$1" && tar -xf - ) || return 1
  if [[ "${2:-}" == D ]]; then
    perl "$E/lit.pl" "$1/tests/helpers.sh" "$E/helpers-1.pairs" && perl "$E/lit.pl" "$1/tests/test-verification.sh" "$E/tv-5.pairs" &&
    perl "$E/lit.pl" "$1/templates/verification-contract.md" "$E/vc-6.pairs" && perl "$E/lit.pl" "$1/scripts/verification-lib.sh" "$E/kernel-8.pairs" || return 1
  fi
  ( cd "$1" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid commit -qm base ) > /dev/null || return 1
  printf 'tests/.one-*.sh\n' >> "$1/.git/info/exclude"
}
live_before="$(livestate)"
say "part=$PART start=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

judge() { # <kit> <tmpdir spelling|UNSET> <test file> <case> -> rc; output in $M/judge.out (as the matrix judges)
  local k="$1" td="$2" tf="$3" c="$4" envset=()
  if [[ "$td" == UNSET ]]; then envset=(-u TMPDIR); else envset=(TMPDIR="$td"); fi
  ( cd "$k" && awk '$0 != "t_run_all"' "tests/$tf" > "tests/.one-$tf" && env "${envset[@]}" bash -c '. "tests/.one-$1"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out"; exit "$rc"' _ "$tf" "$c"; rc=$?; rm -f "tests/.one-$tf"; exit "$rc" ) > "$M/judge.out" 2>&1
}
nasserts() { LC_ALL=C grep -c 'assert:' "$M/judge.out"; }

case "$PART" in
a)
  mkkit "$M/CUR" && mkkit "$M/D" D || { say 'FAIL kits'; exit 2; }
  say "kits: CUR D built; D candidate applied"
  cur0="$(copystate "$M/CUR")"; d0="$(copystate "$M/D")"
  T="$M/tmp"; mkdir -p "$T/sub"; ln -s tmp "$M/tmplink"
  phys="$(cd -P -- "$T" && pwd -P)"; tphys="$(cd -P -- /tmp && pwd -P)"
  say "== A: the TMPDIR a suite exports after tests/helpers.sh loads (physical: $phys)"
  for sp in "$T" "$T/" "$T//" "$T/./" "$T/sub/.." "$M/tmplink" "$M/tmplink/" "$M/tmplink/sub/../" UNSET; do
    if [[ "$sp" == UNSET ]]; then want="$tphys"; set -- -u TMPDIR; else want="$phys"; set -- TMPDIR="$sp"; fi
    got="$(env "$@" bash -c '. "$1/tests/helpers.sh"; printf "%s|" "$TMPDIR"; env | grep "^TMPDIR="' _ "$M/D" 2>&1)"
    check "A D [$sp] exports the physical path" "$want|TMPDIR=$want" "$got"
    say "  info A CUR [$sp]: $(env "$@" bash -c '. "$1/tests/helpers.sh"; printf "%s|%s" "${TMPDIR-unset}" "$(env | grep -c "^TMPDIR=")"' _ "$M/CUR" 2>&1)"
  done
  got="$(env TMPDIR="$M/no-such-dir" bash -c '. "$1/tests/helpers.sh"; echo helpers-loaded' _ "$M/D" 2>&1)"; rc=$?
  check 'A D a TMPDIR naming no directory stops the suite by name, and nothing else is printed' "2|tests/helpers.sh: TMPDIR does not name a directory: $M/no-such-dir" "$rc|$got"
  say "== B: the member CAP-521-Q8OdIp failed on (tests/test-sdd-analyze.sh::analyzer_locale_and_fault_cases)"
  judge "$M/CUR" "$T/" test-sdd-analyze.sh analyzer_locale_and_fault_cases; rc=$?
  check 'B CUR trailing-slash TMPDIR fails (the capture reproduced)' 1:6 "$rc:$(nasserts)"
  check 'B CUR the fault-injected task-reference read is the failing assertion' 1 "$(grep -c -F 'a task reference inventory that could not be read read as no dangling ref' "$M/judge.out")"
  judge "$M/CUR" "$T" test-sdd-analyze.sh analyzer_locale_and_fault_cases; check 'B CUR TMPDIR without the slash passes' 0 "$?"
  for sp in "$T/" "$T//./" "$M/tmplink/" UNSET; do
    judge "$M/D" "$sp" test-sdd-analyze.sh analyzer_locale_and_fault_cases; rc=$?
    check "B D [$sp] passes" 0:0 "$rc:$(nasserts)"
  done
  say "== C: the new fixture (tests/test-verification.sh::reuse_command_input_cases) and its mutant"
  for sp in "$T/" UNSET; do
    judge "$M/D" "$sp" test-verification.sh reuse_command_input_cases; check "C D [$sp] the fixture passes" 0 "$?"
  done
  cp "$M/D/tests/helpers.sh" "$M/helpers.D"; cp "$M/CUR/tests/helpers.sh" "$M/D/tests/helpers.sh"
  judge "$M/D" "$T/" test-verification.sh reuse_command_input_cases; rc=$?
  check 'C mutant (CUR helpers.sh in D) is killed' 1 "$([[ $rc != 0 ]] && echo 1 || echo 0)"
  check 'C mutant diagnostic: the spelling kept' 1 "$(grep -c -F 'AC-020: a suite kept the spelling of TMPDIR=' "$M/judge.out" | awk '{print ($1>0)}')"
  check 'C mutant diagnostic: the nested sandbox' 1 "$(grep -c -F 'made a sandbox a program prints differently' "$M/judge.out")"
  cp "$M/helpers.D" "$M/D/tests/helpers.sh"; check 'C D helpers.sh restored byte-identical' 0 "$(cmp -s "$M/helpers.D" "$M/D/tests/helpers.sh"; echo $?)"
  sed 's/cd -P -- "\${TMPDIR:-\/tmp}" 2> \/dev\/null && pwd -P/cd -- "${TMPDIR:-\/tmp}" 2> \/dev\/null \&\& pwd/' "$M/helpers.D" > "$M/D/tests/helpers.sh"
  check 'C logical mutant applied' 1 "$(grep -c -F '_t_tmpdir="$(cd -- "${TMPDIR:-/tmp}" 2> /dev/null && pwd)"' "$M/D/tests/helpers.sh")"
  judge "$M/D" "$T/" test-verification.sh reuse_command_input_cases; rc=$?
  check 'C logical-only mutant (cd && pwd) is killed by the symlink spellings' 1 "$([[ $rc != 0 ]] && echo 1 || echo 0)"
  check 'C logical-only mutant diagnostic names a symlink spelling' 1 "$(grep -c 'AC-020: a suite kept the spelling of TMPDIR=.*/tmp-link' "$M/judge.out" | awk '{print ($1>0)}')"
  check 'C logical-only mutant leaves the non-symlink spellings passing' 0 "$(grep -c 'AC-020: a suite kept the spelling of TMPDIR=.*/tmp-real' "$M/judge.out")"
  cp "$M/helpers.D" "$M/D/tests/helpers.sh"; check 'C D helpers.sh restored again' 0 "$(cmp -s "$M/helpers.D" "$M/D/tests/helpers.sh"; echo $?)"
  check 'CUR copy unchanged by part a' "$cur0" "$(copystate "$M/CUR")"
  check 'D copy unchanged by part a' "$d0" "$(copystate "$M/D")"
  say "== D: the input identity (records outside the edited files and the harness unchanged)"
  for k in CUR D; do
    ( cd "$M/$k" && HUB_DIR="$PWD" bash -c '. scripts/lib.sh; . scripts/verification-lib.sh; vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$M/$k.inputs.nul" ) > "$M/$k.src" 2>&1
    check "D snapshot of $k exit 0" 0 "$?"
    tr '\0' '\n' < "$M/$k.inputs.nul" | paste - - - - - - | sed "s#$M/$k#KIT#g" | LC_ALL=C sort > "$M/$k.tsv"
  done
  diff "$M/CUR.tsv" "$M/D.tsv" | LC_ALL=C grep '^[<>]' > "$M/records.diff"
  say "  differing records: $(wc -l < "$M/records.diff" | tr -d ' ')"
  cut -f1,2 "$M/records.diff" | sed 's/^/  | /' | head -20
  other="$(awk -F'\t' '{k=substr($1,3)} k=="harness"{next} $2=="tests/helpers.sh"||$2=="tests/test-verification.sh"||$2=="templates/verification-contract.md"||$2=="scripts/verification-lib.sh"{next} {print}' "$M/records.diff" | wc -l | tr -d ' ')"
  check 'D records differ only for the four edited files and the harness' 0 "$other"
  say "== E: ShellCheck on D"
  ( cd "$M/D" && TMPDIR="$T/" bash tests/shellcheck.sh ) > "$M/D.shellcheck" 2>&1; check 'E D tests/shellcheck.sh exit 0' 0 "$?"
  ;;
full)
  run() { # <label> <kit> <tmpdir|UNSET|LINK>
    local label="$1" kit="$M/$1" before envset=()
    mkkit "$kit" "$2" || { echo "copy failed" > "$M/$label.log"; echo 97 > "$M/$label.rc"; return; }
    before="$(copystate "$kit")"; mkdir -p "$M/$label.tmp"
    case "$3" in
      UNSET) envset=(-u TMPDIR);;
      LINK) ln -s "$label.tmp" "$M/$label.link"; envset=(TMPDIR="$M/$label.link/");;
      *) envset=(TMPDIR="$M/$label.tmp/");;
    esac
    date -u +%H:%M:%SZ > "$M/$label.start"
    ( cd "$kit" && env "${envset[@]}" bash -c 'bash tests/run.sh && bash tests/shellcheck.sh' ) > "$M/$label.log" 2>&1; echo $? > "$M/$label.rc"
    date -u +%H:%M:%SZ > "$M/$label.end"
    [[ "$(copystate "$kit")" == "$before" ]] && echo same > "$M/$label.copy" || echo CHANGED > "$M/$label.copy"
    rm -rf "$kit"
  }
  report() { # <label> <want rc>
    local l="$1"
    say "== $l ($(cat "$M/$l.start" 2>/dev/null)-$(cat "$M/$l.end" 2>/dev/null)): rc=$(cat "$M/$l.rc") $(LC_ALL=C grep -E -- '-- [0-9]+/[0-9]+ passed' "$M/$l.log" | tr -d ' ' | tr '\n' ' ')"
    LC_ALL=C grep -E '^  FAIL ' "$M/$l.log" | sed 's/^/  | /'
    LC_ALL=C grep -E '^       assert:' "$M/$l.log" | cut -c1-180 | sed 's/^/  |   /'
    [[ -n "$2" ]] && check "$l exit $2" "$2" "$(cat "$M/$l.rc")"
    check "$l left its copy unchanged" same "$(cat "$M/$l.copy")"
  }
  run cur-link '' LINK & run cur-unset '' UNSET & run d-slash D SLASH & wait
  run d-link D LINK & run d-unset D UNSET & wait
  for l in cur-link cur-unset; do report "$l" ''; done
  for l in d-slash d-link d-unset; do report "$l" 0; done
  for l in cur-link cur-unset d-slash d-link d-unset; do cp "$M/$l.log" "$WT/$s/notes/verification/reports/t030o43-measure-11-$l.log"; done
  ;;
*) say "unknown part $PART"; exit 2;;
esac
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$(livestate)"
say "t030o43-measure-11 part=$PART passes=$passes failures=$fails end=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
(( fails == 0 ))
