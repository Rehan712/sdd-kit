#!/usr/bin/env bash
# T030o41 mutation matrix, 2026-09-24 (v2: the second review's repairs added). Usage: bash t030o41-mutations.sh <scratchpad> <worktree>
#
# Read-only against the live worktree: its manifest enumeration is tarred into
# a standalone git copy under <scratchpad>/t030o41-mut/copy and every mutant
# runs there. A mutant is a function applying exact literal substitutions
# (perl \Q..\E), each required to occur exactly once; each run executes only
# the fixture functions that must judge it, under a 1500 s watchdog; every
# restore is checked byte-identical against the live file with cmp; the copy's
# `git status --porcelain --ignored` must be unchanged after every run.
#   kill   a named fixture must fail          (mutant KILLED)
#   over   an over-correction control: a named fixture must fail
#   equiv  argued equivalent: every named fixture passes (SURVIVES)
set -uo pipefail
SP="$1"; WT="$2"
R="$SP/t030o41-mut"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
fails=0
say() { printf '%s\n' "$*"; }
verdict() { if [[ "$2" == "$3" ]]; then say "PASS $1 (want=$2 got=$3)"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }

( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul" || { say 'FAIL live enumeration'; exit 2; }
( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$C" && tar -xf - ) || { say 'FAIL copy extraction'; exit 2; }
cd "$C" || exit 2
git init -q && git add -A && git -c user.name=mut -c user.email=mut@invalid commit -qm base || { say 'FAIL copy commit'; exit 2; }
printf 'tests/.one-*.sh\n' >> .git/info/exclude
STEMS="gate-contracts verification sdd-analyze usage-limits model-policy build-adapters executable-bits spec-gate spec-dispatch golden-example"
for stem in $STEMS; do
  [[ "$(grep -c -x 't_run_all' "tests/test-$stem.sh")" == 1 ]] || { say "FAIL $stem runner shape"; exit 2; }
done
runners() { local stem; for stem in $STEMS; do awk '$0 != "t_run_all"' "tests/test-$stem.sh" > "tests/.one-$stem.sh"; done; }
runners
git status --porcelain --ignored > "$w/status-base.txt"
[[ -z "$(git status --porcelain)" ]] || { say 'FAIL copy not clean'; exit 2; }

run_one() { # <stem> <function> <tag> -> exit status of that function, harness-style, under a watchdog
  local stem="$1" fn="$2" tag="$3" pid n=0
  ( cd "$C" && exec bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$stem" "$fn" "$w/$tag.$fn.out" ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    (( n++ < 1500 )) || { pkill -TERM -P "$pid" 2>/dev/null; kill -TERM "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; say "  | WATCHDOG $fn"; return 124; }
    sleep 1
  done
  wait "$pid"
}
sub() { # <file> <old> <new>: exactly one occurrence, else fail
  local n
  n="$(OLD="$2" perl -0ne 'my $c = () = /\Q$ENV{OLD}\E/g; print $c' "$1")"
  [[ "$n" == 1 ]] || { say "  | literal occurs $n times in $1: ${2:0:70}"; return 1; }
  OLD="$2" NEW="$3" perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/' "$1"
}
restore_all() {
  local f
  git checkout -q -- .; runners
  for f in scripts/verification-lib.sh templates/verification-contract.md tests/helpers.sh tests/run.sh tests/shellcheck.sh \
      tests/test-gate-contracts.sh tests/test-verification.sh tests/test-sdd-analyze.sh tests/test-usage-limits.sh \
      tests/test-model-policy.sh tests/test-build-adapters.sh tests/test-executable-bits.sh \
      tests/test-spec-gate.sh tests/test-spec-dispatch.sh tests/test-golden-example.sh; do
    cmp -s "$f" "$WT/$f" || { say "FAIL restore $f differs from the live file"; fails=$((fails+1)); }
  done
  git status --porcelain --ignored > "$w/status-now.txt"
  cmp -s "$w/status-base.txt" "$w/status-now.txt" || { say 'FAIL the copy tree changed (a run was not hermetic)'; fails=$((fails+1)); diff "$w/status-base.txt" "$w/status-now.txt" | head -5; }
}
mutant() { # <kind> <label> <apply function> <stem:function>...
  local kind="$1" label="$2" apply="$3" spec rc any=0 all=0; shift 3
  say "== $kind $label"
  if ! "$apply"; then say "FAIL $label: mutation not applied"; fails=$((fails+1)); restore_all; return; fi
  runners
  if [[ -n "${DRY:-}" ]]; then say "PASS $label applied (dry run)"; restore_all; return; fi
  for spec in "$@"; do
    run_one "${spec%%:*}" "${spec#*:}" "$label"; rc=$?
    say "  | ${spec#*:} rc=$rc"
    grep -m2 'assert:' "$w/$label.${spec#*:}.out" 2>/dev/null | cut -c1-190 | sed 's/^/  |   /'
    if (( rc == 0 )); then all=$((all+1)); else any=1; fi
  done
  case "$kind" in
    kill|over) verdict "$label KILLED" 1 "$any";;
    equiv) verdict "$label SURVIVES (argued equivalent)" "$#" "$all";;
  esac
  restore_all
}

G=tests/test-gate-contracts.sh V=scripts/verification-lib.sh H=tests/helpers.sh A=tests/test-sdd-analyze.sh
T=tests/test-verification.sh B=tests/test-build-adapters.sh U=tests/test-usage-limits.sh
SCAN=gate-contracts:superseded_environment_cases

say '== baselines'
[[ -n "${DRY:-}" ]] || for spec in "$SCAN" gate-contracts:test_instruction_contracts gate-contracts:test_ignored_local_overlays_and_personas_do_not_decide_the_checks \
    gate-contracts:test_empty_record_directories_do_not_decide_the_002_tally \
    verification:kit_copy_cases verification:outside_layout_anchor_cases verification:reuse_command_input_cases \
    sdd-analyze:test_verification_bindings sdd-analyze:test_leftover_spec_directories_do_not_decide_the_shipped_loop \
    usage-limits:test_AC_009_doctor_fixture_excludes_machine_local_kit_files \
    model-policy:test_AC_008_usage_limit_policy_wizard_preserves_ordered_fallback \
    build-adapters:test_stage_kit_excludes_and_never_writes_through_a_host_models_yml \
    executable-bits:test_AC_011_ignored_local_scripts_do_not_decide_the_executable_check \
    gate-contracts:test_ignored_local_scripts_do_not_reach_the_documented_workflow \
    spec-gate:test_floor_fixture_stages_only_enumerated_scripts \
    spec-dispatch:test_stage_umbrella_copies_only_enumerated_scripts \
    golden-example:test_stage_example_copies_only_enumerated_files \
    model-policy:test_AC_008_wizard_fixture_never_writes_through_a_host_models_yml \
    usage-limits:test_AC_003_dispatch_fixture_copies_only_enumerated_scripts; do
  run_one "${spec%%:*}" "${spec#*:}" baseline; verdict "baseline ${spec#*:}" 0 "$?"
done
restore_all

# --- the O-010 scan (O-015 and pass B) ---
k01() { sub "$G" 'vf_path_content "$root" "$path" "$content"' 'cp -- "$root/$path" "$content"'; }
k02() { sub "$G" 'vf_source_paths "$root" "$list" || { echo "superseded_environment_scan: cannot enumerate $1"' 'git -C "$root" ls-files --cached --others --exclude-standard | tr '"'"'\n'"'"' '"'"'\0'"'"' > "$list" || { echo "superseded_environment_scan: cannot enumerate $1"'; }
k03() { sub "$G" 'vf_source_paths "$root" "$list" || { echo "superseded_environment_scan: cannot enumerate $1" >&2; return 1; }' 'vf_source_paths "$root" "$list" 2>/dev/null || true'; }
k04() { sub "$G" '  ! vf_case_folds "$root" || fold=1' '  :'; }
k05() { sub "$G" 'P="$path" LC_ALL=C awk '"'" 'LC_ALL=C awk -v path="$path" '"'" && sub "$G" 'ENVIRON["P"], claim}' 'path, claim}'; }
k06() { sub "$G" 'vf_path_content "$root" "$path" "$content"' 'vf_semantic_file "$path" "$root/$path" "$content"'; }
k07() { sub "$G" 'vf_path_content "$root" "$path" "$content" || { echo "superseded_environment_scan: cannot read $path" >&2; return 1; }' 'vf_path_content "$root" "$path" "$content" || true'; }
o01() { sub "$G" '    case "$path" in STATUS.md|*/STATUS.md) continue;; esac' '    case "$path" in STATUS.md|*/STATUS.md|.specify/specs/*) continue;; esac'; }
e01() { sub "$G" "reported=\"\$(superseded_environment_scan \"\$KIT_DIR\")\" || t_fail 'AC-018: the superseded-rule scan could not read the live tree'" 'reported="$(superseded_environment_scan "$KIT_DIR")"'; }
e02() { sub "$G" "' \"\$content\" || { echo \"superseded_environment_scan: cannot scan \$path\" >&2; return 1; }" "' \"\$content\""; }
mutant kill K01-scan-reads-raw-bytes k01 "$SCAN"
mutant kill K02-scan-enumerates-without-nul-framing k02 "$SCAN"
mutant kill K03-scan-swallows-enumeration-failure k03 "$SCAN"
mutant kill K04-scan-never-folds-case k04 "$SCAN"
mutant kill K05-scan-passes-names-through-awk-v k05 "$SCAN"
mutant kill K06-scan-normalizes-links-by-name k06 "$SCAN"
mutant kill K07-scan-skips-unreadable-files k07 "$SCAN"
mutant over O01-scan-skips-every-spec-file o01 "$SCAN"
mutant equiv E01-live-scan-exit-unasserted e01 "$SCAN"
mutant equiv E02-awk-failure-diagnostic-removed e02 "$SCAN"

# --- the kernel ---
k08() { sub "$V" '  [[ "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" -ef "$1" ]] || {
    echo '"'"'verification inputs: Git worktree root required'"'"' >&2; return 3;
  }
  git -C "$1" ls-files' '  git -C "$1" ls-files'; }
k09() { sub "$V" '; [[ "$own" =~ ^\.specify/specs/[^/]+$ ]] || own='"''" ''; }
k10() { sub "$V" '  if [[ -L "$1/$2" ]]; then cp -- "$1/$2" "$3"
  else vf_semantic_file "$2" "$1/$2" "$3"; fi' '  vf_semantic_file "$2" "$1/$2" "$3"'; }
mutant kill K08-source-paths-drops-root-check k08 "$SCAN" verification:kit_copy_cases
mutant kill K09-anchor-layout-clause-deleted k09 verification:outside_layout_anchor_cases
mutant kill K10-path-content-normalizes-links k10 "$SCAN"

say '== equiv E03-snapshot-own-git-line and E04-link-digest-direct (identity compared directly)'
ln -s README.md "$C/zz-link.md"
snap() { ( cd "$C" && bash -c '. scripts/verification-lib.sh; vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ .specify/specs/003-gate-round-reduction-and-token-discipline "$1" ) > /dev/null; }
strip() { tr '\0' '\n' < "$1" | paste -d '|' - - - - - - | grep -v -F 'verification-lib.sh'; }
snap "$w/eq-base.nul"; verdict 'E03/E04 baseline snapshot rc' 0 "$?"
sub "$V" '  vf_source_paths "$repo" "$tmp/paths" || return 3' '  git -C "$repo" ls-files --cached --others --exclude-standard -z > "$tmp/paths" || return 3'; verdict 'E03 applied' 0 "$?"
snap "$w/eq-e03.nul"; verdict 'E03 snapshot rc' 0 "$?"
cmp -s <(strip "$w/eq-base.nul") <(strip "$w/eq-e03.nul"); verdict 'E03 every record not naming verification-lib.sh is identical' 0 "$?"
git checkout -q -- "$V"
sub "$V" '      vf_path_content "$repo" "$path" "$scratch/semantic" && digest="$(vf_hash "$scratch/semantic")" || return 3' '      digest="$(vf_hash "$repo/$path")" || return 3'; verdict 'E04 applied' 0 "$?"
snap "$w/eq-e04.nul"; verdict 'E04 snapshot rc' 0 "$?"
cmp -s <(strip "$w/eq-base.nul") <(strip "$w/eq-e04.nul"); verdict 'E04 every record not naming verification-lib.sh is identical, the link record included' 0 "$?"
verdict 'E04 the probe tree holds a link record' 1 "$(strip "$w/eq-base.nul" | grep -c '^path|zz-link.md|link|')"
rm -f "$C/zz-link.md"; restore_all

# --- the AC-023 loop ---
k11() { sub "$A" 'bash -c '"'"'. "$1/verification-lib.sh"; vf_path_content "$2" "$3" "$4"'"'"' \
      _ "$SCRIPTS" "$1" "$2/$value" "$spec_dir/$value"' 'cp "$1/$2/$value" "$spec_dir/$value"'; }
k12() { sub "$A" '  : > "$SANDBOX/shipped-rels"' '  : > "$SANDBOX/shipped-rels"; for d in "$KIT_DIR"/.specify/specs/001-* "$KIT_DIR"/.specify/specs/002-*; do printf '"'"'%s\0'"'"' ".specify/specs/${d##*/}" >> "$SANDBOX/shipped-rels"; done; : > "$SANDBOX/kit-paths"'; }
k13() { sub "$A" "awk -v p=\"\$probe\" '!done && /^- \\[[ xX~]\\] \\*\\*T[0-9]/ {print; print \"  - *Evidence:* \" p; done=1; next} {print}'" "awk -v p=\"\$probe\" '!done && /^[ ]*- \\*Evidence:\\*/ {print; print \"  - *Evidence:* \" p; done=1; next} {print}'"; }
o02() { sub "$A" "  verification_edit_fixture \"\$spec_dir/tasks.md\" 's|~/.sdd/agents/|agents/|g'
  run_rc \"\$3\"" "  verification_edit_fixture \"\$spec_dir/tasks.md\" 's|~/.sdd/agents/|agents/|g; s/cross-checked with \\*Agent:\\*//; s/<!-- earlier//'
  run_rc \"\$3\""; }
mutant kill K11-analyzer-loop-reads-raw-bytes k11 sdd-analyze:test_verification_bindings
mutant kill K12-shipped-set-from-a-glob k12 sdd-analyze:test_leftover_spec_directories_do_not_decide_the_shipped_loop
mutant kill K13-probe-anchored-on-a-dropped-line k13 sdd-analyze:test_verification_bindings
mutant over O02-analyzer-strips-markers-everywhere o02 sdd-analyze:test_verification_bindings

# --- copy_kit and its callers ---
k14() { sub "$H" 'mkdir -p "$2" && ( cd "$src" && tar --null -T "$work/present" -cf - ) | ( cd "$2" && tar -xf - )' 'mkdir -p "$2" && cp -R "$src/." "$2/"'; }
k15() { sub "$H" '    echo "copy_kit: cannot enumerate $1" >&2; rm -rf -- "$work"; return 1' '    :'; }
k16() { sub "$H" '    [[ ! -e "$src/$path" && ! -L "$src/$path" ]] || printf '"'"'%s\0'"'"' "$path"' '    printf '"'"'%s\0'"'"' "$path"'; }
k17() { sub "$H" '      case "$path" in .specify/specs/*) shopt -u nocasematch; continue;; esac' '      :'; }
k18() { sub "$H" '      [[ "$path" == "${3%/}"/* ]] || continue' '      :'; }
k19() { sub "$H" '    echo "copy_kit: cannot enumerate $1" >&2; rm -rf -- "$work"; return 1' '    echo "copy_kit: cannot enumerate $1" >&2; exit 1' \
          && sub "$H" '  work="$(mktemp -d "${TMPDIR:-/tmp}/copy-kit.XXXXXX")" || return 1' '  work="$(mktemp -d "${TMPDIR:-/tmp}/copy-kit.XXXXXX")" || return 1
  trap '"'"'rm -rf -- "$work"'"'"' EXIT'; }
o03() { sub "$H" 'bash -c '"'"'. "$1/verification-lib.sh"; vf_source_paths "$2" "$3"'"'"' _ "$SCRIPTS" "$src" "$work/list"' 'git -C "$src" ls-files -z --cached > "$work/list"'; }
e05() { sub "$H" 'copy_kit() ( # <kit root> <dest> [<repo-relative directory>]
  set -o pipefail
' 'copy_kit() ( # <kit root> <dest> [<repo-relative directory>]
'; }
k20() { sub "$U" "copy_kit \"\$KIT_DIR\" \"\$DOCTOR_KIT\" || t_fail 'AC-009: cannot copy the kit for the doctor fixture'" 'cp -R "$KIT_DIR" "$DOCTOR_KIT"'; }
k21() { sub "$B" "copy_kit \"\$KIT_DIR\" \"\$kit\" >&2 || { echo 'stage_kit: cannot stage the kit copy' >&2; return 1; }" "(cd \"\$KIT_DIR\" && tar -cf - --exclude .git --exclude .specify --exclude '*.worktrees' .) | (cd \"\$kit\" && tar -xf -)"; }
k22() { sub "$B" '  rm -f "$1/models.yml"
  cat > "$1/models.yml"' '  cat > "$1/models.yml"'; }
e06() { sub tests/test-model-policy.sh "copy_kit \"\$KIT_DIR\" \"\$kit\" || t_fail 'AC-008: cannot copy the kit for the wizard fixture'" 'cp -R "$KIT_DIR" "$kit"'; }
mutant kill K14-copy-kit-is-cp-R k14 verification:kit_copy_cases
mutant kill K15-copy-kit-swallows-enumeration-failure k15 verification:kit_copy_cases
mutant kill K16-copy-kit-copies-deleted-paths k16 verification:kit_copy_cases
mutant kill K17-copy-kit-copies-spec-directories k17 verification:kit_copy_cases
mutant kill K18-copy-kit-ignores-the-selector k18 verification:kit_copy_cases
mutant kill K19-copy-kit-trap-and-exit k19 verification:kit_copy_cases
mutant over O03-copy-kit-tracked-only o03 verification:kit_copy_cases
mutant equiv E05-copy-kit-without-pipefail e05 verification:kit_copy_cases
mutant kill K20-doctor-fixture-is-cp-R k20 usage-limits:test_AC_009_doctor_fixture_excludes_machine_local_kit_files
mutant kill K21-stage-kit-is-the-old-tar k21 build-adapters:test_stage_kit_excludes_and_never_writes_through_a_host_models_yml
mutant kill K22-policy-writer-follows-links k22 build-adapters:test_stage_kit_excludes_and_never_writes_through_a_host_models_yml
mutant kill K45-wizard-fixture-is-cp-R e06 model-policy:test_AC_008_wizard_fixture_never_writes_through_a_host_models_yml

# --- the reuse-checked commands, globs, tally and environment ---
k23() { sub tests/run.sh 'for f in ${suites[@]+"${suites[@]}"}; do' 'for f in "$TESTS_DIR"/test-*.sh; do'; }
k24() { sub tests/shellcheck.sh 'exec env -u SHELLCHECK_OPTS shellcheck --norc -S warning -x "${files[@]}"' 'exec env -u SHELLCHECK_OPTS shellcheck -S warning -x "${files[@]}"'; }
k25() { sub tests/shellcheck.sh 'exec env -u SHELLCHECK_OPTS shellcheck --norc -S warning -x "${files[@]}"' 'exec shellcheck --norc -S warning -x "${files[@]}"'; }
k26() { sub tests/shellcheck.sh 'exec env -u SHELLCHECK_OPTS shellcheck --norc -S warning -x "${files[@]}"' 'exec env -u SHELLCHECK_OPTS shellcheck --norc -S warning -x scripts/*.sh tests/*.sh'; }
k27() { sub "$H" '  case "$_t_env" in SDD_*|XDG_STATE_HOME) unset "$_t_env";; esac' '  :'; }
k28() { sub tests/test-executable-bits.sh "{ kit_files scripts '*.sh' && kit_files tests 'run.sh'; } > \"\$list\"" "( cd \"\$KIT_DIR\" && for f in scripts/*.sh tests/run.sh; do printf '%s\\0' \"\$f\"; done ) > \"\$list\""; }
k29() { sub "$G" "kit_files templates/stack-overlays '*.md' > \"\$list\"" "( cd \"\$KIT_DIR\" && for f in templates/stack-overlays/*.md; do printf '%s\\0' \"\$f\"; done ) > \"\$list\""; }
k30() { sub "$G" "kit_files agents '*-expert.md' > \"\$list\"" "( cd \"\$KIT_DIR\" && for f in agents/*-expert.md; do printf '%s\\0' \"\$f\"; done ) > \"\$list\""; }
k31() { sub "$G" 'tally "$copy/$rel"' 'tally "$KIT_DIR/$rel"'; }
k32() { sub templates/verification-contract.md 'A reused success is sound only while the check'"'"'s verdict is a function of that
identity, so a check opted into reuse reads the repository only as the snapshot
hashes it:' 'A reused success is sound:'; }
mutant kill K23-run-sh-globs-its-suites k23 verification:reuse_command_input_cases
mutant kill K24-shellcheck-reads-rc-files k24 verification:reuse_command_input_cases
mutant kill K25-shellcheck-reads-SHELLCHECK_OPTS k25 verification:reuse_command_input_cases
mutant kill K26-shellcheck-globs-its-files k26 verification:reuse_command_input_cases
mutant kill K27-suites-keep-ambient-kit-knobs k27 verification:reuse_command_input_cases
mutant kill K28-executable-check-globs k28 executable-bits:test_AC_011_ignored_local_scripts_do_not_decide_the_executable_check
mutant kill K29-overlay-check-globs k29 gate-contracts:test_ignored_local_overlays_and_personas_do_not_decide_the_checks
mutant kill K30-persona-check-globs k30 gate-contracts:test_ignored_local_overlays_and_personas_do_not_decide_the_checks
mutant kill K31-tally-reads-records-in-place k31 gate-contracts:test_empty_record_directories_do_not_decide_the_002_tally
mutant kill K32-contract-obligation-deleted k32 gate-contracts:test_instruction_contracts

# --- v2: the second review's repairs ---
RV=verification:reuse_command_input_cases
k33() { sub "$H" 'for _t_env in $(git rev-parse --local-env-vars); do unset "$_t_env"; done' ':'; }
k34() { sub "$V" '  for name in $names; do unset "$name"; done' '  :'; }
k34b() { sub "$V" '  vf_git_local_unset || return 3
  [[ "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" -ef "$1" ]] || {' '  [[ "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" -ef "$1" ]] || {'; }
k34c() { sub "$V" '  # without git'"'"'s repository-local environment too (see vf_git_local_unset).
  vf_git_local_unset || return 3' '  # (scrub removed)'; }
k35() { sub "$V" '  [[ "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" -ef "$1" ]] || {' '  [[ "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" == "$1" ]] || {'; }
k36() { sub tests/run.sh 'unset CDPATH BASH_ENV ENV' ':'; }
k37() { sub tests/shellcheck.sh 'unset CDPATH BASH_ENV ENV' ':'; }
k38() { sub "$H" 'unset CDPATH BASH_ENV ENV' ':'; }
k39() { sub "$H" '  mkdir -p "$1" && git -C "$1" init -q && mkdir -p "$1/.git/info"' '  mkdir -p "$1" && git -C "$1" init -q'; }
k40() { sub "$G" "  copy_kit \"\$KIT_DIR\" \"\$repo\" scripts || { t_fail 'documented fixture: cannot copy the kit scripts'; return; }" '  cp -R "$KIT_DIR/scripts/." "$repo/scripts/"'; }
k41() { sub tests/test-spec-gate.sh "  copy_kit \"\$KIT_DIR\" \"\$kit\" scripts || t_fail 'AC-007: cannot stage the kit scripts'" '  cp -R "$KIT_DIR/scripts" "$kit/scripts"'; }
k42() { sub tests/test-spec-dispatch.sh "  copy_kit \"\$KIT_DIR\" \"\$kit\" scripts || { echo 'stage_umbrella: cannot stage the kit scripts' >&2; return 1; }" '  cp -R "$KIT_DIR/scripts" "$kit/scripts"'; }
k43() { sub "$U" "  copy_kit \"\$KIT_DIR\" \"\$DISPATCH_KIT\" scripts || t_fail 'AC-003: cannot stage the kit scripts for the dispatch fixture'" '  cp -R "$SCRIPTS" "$DISPATCH_KIT/scripts"'; }
k44() { sub tests/test-golden-example.sh '  copy_kit "$KIT_DIR" "$SANDBOX/example-copy" "$rel" && mv "$SANDBOX/example-copy/$rel" "$spec_dir" \
    || t_fail '"'"'cannot copy the example as the input identity enumerates it'"'" '  cp -R "$KIT_DIR/$rel" "$spec_dir"'; }
o04() { sub "$H" '  case "$_t_env" in SDD_*|XDG_STATE_HOME) unset "$_t_env";; esac' '  case "$_t_env" in SDD_*|XDG_*) unset "$_t_env";; esac'; }
mutant kill K33-suites-keep-git-local-environment k33 "$RV"
mutant kill K34-kernel-keeps-git-local-environment k34 "$RV" "$SCAN"
mutant kill K34b-source-paths-keeps-git-local-environment k34b "$RV"
mutant kill K34c-snapshot-keeps-git-local-environment k34c "$RV"
mutant kill K35-root-compared-by-spelling k35 "$RV"
mutant kill K36-run-sh-keeps-CDPATH k36 "$RV"
mutant kill K37-shellcheck-sh-keeps-CDPATH k37 "$RV"
mutant kill K38-helpers-keep-CDPATH k38 "$RV"
mutant kill K39-host-repo-without-info-dir k39 "$RV"
mutant kill K40-documented-workflow-copies-with-cp-R k40 gate-contracts:test_ignored_local_scripts_do_not_reach_the_documented_workflow
mutant kill K41-floor-fixture-copies-with-cp-R k41 spec-gate:test_floor_fixture_stages_only_enumerated_scripts
mutant kill K42-stage-umbrella-copies-with-cp-R k42 spec-dispatch:test_stage_umbrella_copies_only_enumerated_scripts
mutant kill K43-dispatch-fixture-copies-with-cp-R k43 usage-limits:test_AC_003_dispatch_fixture_copies_only_enumerated_scripts
mutant kill K44-stage-example-copies-with-cp-R k44 golden-example:test_stage_example_copies_only_enumerated_files
mutant over O04-suites-clear-every-XDG-name o04 "$RV"

say "matrix failures=$fails"
(( fails == 0 ))
