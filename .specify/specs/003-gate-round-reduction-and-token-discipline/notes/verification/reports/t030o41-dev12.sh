#!/usr/bin/env bash
# T030o41 dev run 12, 2026-09-25 (session 4): the review-6 repairs, in a standalone
# copy. The full suite runs twice: plainly, and under a hostile git environment
# (a rejecting global hook, a failing signer, core.autocrlf, a required clean
# filter that fails, a template with an active hook and an info/exclude of *,
# and a hook's environment: GIT_QUARANTINE_PATH, GIT_AUTHOR_NAME/EMAIL,
# GIT_DEFAULT_HASH), none of which decides the enumeration. The per-function
# runner fails a function that leaves a fixture build-failure record, as
# t_run_all does.
# Usage: bash t030o41-dev12.sh <scratchpad> <worktree> [quick]
# Read-only against the live worktree. Every exit is captured from the command
# itself; the copy's `git status --porcelain --ignored` must be unchanged by
# every run (hermeticity), and the live worktree's status digest is compared
# before and after.
set -uo pipefail
SP="$1"; WT="$2"; MODE="${3:-full}"
R="$SP/dev12"; C="$R/copy"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$w" "$TMPDIR"
fails=0
say() { printf '%s\n' "$*"; }
verdict() { if [[ "$2" == "$3" ]]; then say "PASS $1 (want=$2 got=$3)"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
live_state() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1 ); }
L0="$(live_state)"; say "  | live worktree porcelain digest before: $L0"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul" || { say 'FAIL live enumeration'; exit 2; }
( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$C" && tar -xf - ) || { say 'FAIL copy extraction'; exit 2; }
cd "$C" || exit 2
git init -q && git add -A && git -c user.name=dev -c user.email=dev@invalid commit -qm base || { say 'FAIL copy commit'; exit 2; }
printf 'tests/.one-*.sh\n' >> .git/info/exclude
for f in tests/test-*.sh; do
  [[ "$(grep -c -x 't_run_all' "$f")" == 1 ]] || { say "FAIL runner shape $f"; exit 2; }
  awk '$0 != "t_run_all"' "$f" > "tests/.one-${f#tests/test-}"
done
git status --porcelain --ignored > "$w/status-base.txt"
hermetic() {
  git status --porcelain --ignored > "$w/status-now.txt"
  cmp -s "$w/status-base.txt" "$w/status-now.txt"; verdict "$1: copy unchanged" 0 "$?"
}
run_one() { # <stem> <function>
  ( cd "$C" && bash -c '. "tests/.one-$1.sh"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out" > "$3"; exit "$rc"' _ "$1" "$2" "$w/$2.out" )
}

say '== ShellCheck (the pinned command)'
bash tests/shellcheck.sh > "$w/shellcheck.out" 2>&1; rc=$?
verdict 'bash tests/shellcheck.sh' 0 "$rc"; [[ "$rc" == 0 ]] || head -30 "$w/shellcheck.out"
hermetic shellcheck

say '== new and changed fixtures, one function at a time'
for spec in verification.sh:fixture_repository_cases verification.sh:reuse_command_input_cases verification.sh:kit_copy_cases \
    verification.sh:bookkeeping_anchor_cases verification.sh:outside_layout_anchor_cases \
    spec-ac-coverage.sh:test_default_root_is_the_git_toplevel \
    build-adapters.sh:test_stage_kit_failure_is_named_and_stays_in_the_sandbox \
    golden-example.sh:test_stage_example_failure_is_named_and_stays_in_the_sandbox \
    spec-gate.sh:test_floor_fixture_failure_is_named_and_stays_in_the_sandbox \
    spec-dispatch.sh:test_stage_umbrella_failure_is_named_and_stays_in_the_sandbox \
    gate-contracts.sh:superseded_environment_cases gate-contracts.sh:test_ignored_local_scripts_do_not_reach_the_documented_workflow \
    gate-contracts.sh:test_ignored_local_scripts_do_not_reach_the_dispatch_grammar_kit \
    gate-contracts.sh:test_ignored_local_overlays_and_personas_do_not_decide_the_checks \
    gate-contracts.sh:test_empty_record_directories_do_not_decide_the_002_tally \
    sdd-analyze.sh:test_leftover_spec_directories_do_not_decide_the_shipped_loop \
    spec-gate.sh:test_floor_fixture_stages_only_enumerated_scripts \
    spec-dispatch.sh:test_stage_umbrella_copies_only_enumerated_scripts \
    golden-example.sh:test_stage_example_copies_only_enumerated_files \
    model-policy.sh:test_AC_008_wizard_fixture_never_writes_through_a_host_models_yml \
    usage-limits.sh:test_AC_003_dispatch_fixture_copies_only_enumerated_scripts \
    usage-limits.sh:test_AC_009_doctor_fixture_excludes_machine_local_kit_files \
    executable-bits.sh:test_AC_011_every_kit_script_is_executable \
    executable-bits.sh:test_AC_011_ignored_local_scripts_do_not_decide_the_executable_check \
    build-adapters.sh:test_stage_kit_excludes_and_never_writes_through_a_host_models_yml \
    verification.sh:test_capture_provenance gate-contracts.sh:test_instruction_contracts; do
  stem="${spec%%:*}"; stem="${stem%.sh}"; fn="${spec#*:}"
  run_one "$stem" "$fn"; rc=$?
  verdict "$fn" 0 "$rc"
  [[ "$rc" == 0 ]] || grep -E 'assert:|output:' "$w/$fn.out" | head -8 | cut -c1-240 | sed 's/^/  |   /'
done
hermetic fixtures

if [[ "$MODE" != quick ]]; then
  say '== full suite: bash tests/run.sh'
  start="$(date -u +%H:%M:%SZ)"
  bash tests/run.sh > "$w/run.out" 2>&1; rc=$?
  say "  | run.sh $start - $(date -u +%H:%M:%SZ)"
  verdict 'bash tests/run.sh' 0 "$rc"
  grep -E -- '-- [0-9]+/[0-9]+ passed' "$w/run.out" | sed 's/^/  | /'
  grep -E '^== |FAIL test_' "$w/run.out" | grep -B1 'FAIL test_' | sed 's/^/  | /'
  awk '/-- [0-9]+\/[0-9]+ passed/ {split($2, a, "/"); ok += a[1]; all += a[2]} END {printf "  | total %d/%d\n", ok, all}' "$w/run.out"
  hermetic full-suite

  # Review 4's class proof. None of this environment decides the enumeration,
  # so the input identity is unchanged by it, and no verdict may change either.
  say '== full suite under a hostile git environment'
  H="$R/hostile"; mkdir -p "$H/hooks" "$H/template/hooks" "$H/template/info"
  printf '#!/bin/sh\necho "hostile hook: commit rejected" >&2\nexit 1\n' > "$H/hooks/pre-commit"; chmod +x "$H/hooks/pre-commit"
  cp -p "$H/hooks/pre-commit" "$H/template/hooks/pre-commit"
  printf '*\n' > "$H/template/info/exclude"
  printf '* filter=reject\n' > "$H/attributes"; mkdir -p "$H/quarantine"
  printf '[core]\n\thooksPath = %s\n\tautocrlf = true\n\tattributesFile = %s\n[commit]\n\tgpgsign = true\n[gpg]\n\tprogram = %s\n[filter "reject"]\n\tclean = false\n\tsmudge = cat\n\trequired = true\n' \
    "$H/hooks" "$H/attributes" "$H/no-such-gpg" > "$H/gitconfig"
  HENV=(GIT_CONFIG_GLOBAL="$H/gitconfig" GIT_TEMPLATE_DIR="$H/template" GIT_QUARANTINE_PATH="$H/quarantine"
    GIT_AUTHOR_NAME='Hook Author' GIT_AUTHOR_EMAIL=hook@example.invalid GIT_DEFAULT_HASH=sha256)
  ( cd "$C" && env "${HENV[@]}" bash -c '. scripts/verification-lib.sh; vf_source_paths "$PWD" "$1"' _ "$w/enum-hostile.nul" ) \
    && ( cd "$C" && bash -c '. scripts/verification-lib.sh; vf_source_paths "$PWD" "$1"' _ "$w/enum-plain.nul" ) \
    && cmp -s "$w/enum-plain.nul" "$w/enum-hostile.nul"; verdict 'the kit enumeration is identical under the hostile environment' 0 "$?"
  start="$(date -u +%H:%M:%SZ)"
  env "${HENV[@]}" bash tests/run.sh > "$w/run-hostile.out" 2>&1; rc=$?
  say "  | run.sh (hostile) $start - $(date -u +%H:%M:%SZ)"
  verdict 'bash tests/run.sh under the hostile environment' 0 "$rc"
  grep -E '^== |FAIL test_' "$w/run-hostile.out" | grep -B1 'FAIL test_' | sed 's/^/  | /'
  awk '/-- [0-9]+\/[0-9]+ passed/ {split($2, a, "/"); ok += a[1]; all += a[2]} END {printf "  | total %d/%d\n", ok, all}' "$w/run-hostile.out"
  hermetic hostile-suite
fi

cp "$w/run.out" "$SP/dev12-run.out" 2>/dev/null || true
cd "$SP" || exit 2
L1="$(live_state)"; say "  | live worktree porcelain digest after: $L1"
verdict 'live worktree unchanged' "$L0" "$L1"
say "dev12 failures=$fails"
(( fails == 0 ))
