#!/usr/bin/env bash
# test-spec-ac-coverage.sh — the AC↔test binding floor (code layer).

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
AC_COV="$SCRIPTS/spec-ac-coverage.sh"

test_unreferenced_ac_fails_referenced_ac_passes() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  mkdir -p "$SANDBOX/proj/tests"
  printf "it('AC-001: returns 201', () => {})\n" > "$SANDBOX/proj/tests/thing.test.js"
  run_rc 1 "$AC_COV" "$spec_dir" --root "$SANDBOX/proj"
  assert_contains "$OUT" "AC-001 — named in 1 test file(s)"
  assert_contains "$OUT" "AC-002 — no test file names it"
}

test_all_acs_bound_passes() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  mkdir -p "$SANDBOX/proj/tests"
  printf "it('AC-001: returns 201', () => {})\n" > "$SANDBOX/proj/tests/thing.test.js"
  printf "it('AC-002: rejects bad payload', () => {})\n" > "$SANDBOX/proj/tests/validate.test.js"
  run_rc 0 "$AC_COV" "$spec_dir" --root "$SANDBOX/proj"
  assert_contains "$OUT" "bound"
}

test_test_paths_with_spaces_are_counted() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  mkdir -p "$SANDBOX/proj/e2e tests"
  printf "it('AC-001: returns 201', () => {})\n" > "$SANDBOX/proj/e2e tests/thing.test.js"
  printf "it('AC-002: rejects bad payload', () => {})\n" > "$SANDBOX/proj/e2e tests/error path.spec.js"
  run_rc 0 "$AC_COV" "$spec_dir" --root "$SANDBOX/proj"
  assert_contains "$OUT" "bound" "paths with spaces must not split"
}

test_longer_ids_do_not_satisfy_shorter_acs() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  mkdir -p "$SANDBOX/proj/tests"
  # AC-0012 contains the string AC-001 but must not count as covering it.
  printf "it('AC-0012: unrelated', () => {})\nit('AC-002: rejects', () => {})\n" \
    > "$SANDBOX/proj/tests/thing.test.js"
  run_rc 1 "$AC_COV" "$spec_dir" --root "$SANDBOX/proj"
  assert_contains "$OUT" "AC-001 — no test file names it"
}

test_spec_dir_itself_never_counts_as_coverage() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  # The only AC-### mentions live in .specify/ (the spec itself) — pruned.
  run_rc 1 "$AC_COV" "$spec_dir" --root "$SANDBOX/proj"
  assert_contains "$OUT" "0 test file(s)"
}

test_extra_test_glob_extends_the_net() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  mkdir -p "$SANDBOX/proj/checks"
  printf '// AC-001 and AC-002 verified here\n' > "$SANDBOX/proj/checks/acceptance_check.go"
  run_rc 1 "$AC_COV" "$spec_dir" --root "$SANDBOX/proj"
  run_rc 0 "$AC_COV" "$spec_dir" --root "$SANDBOX/proj" --tests '*_check.go'
  assert_contains "$OUT" "bound"
}

test_default_root_is_the_git_toplevel() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  git init -q "$SANDBOX/proj"
  mkdir -p "$SANDBOX/proj/tests"
  printf 'AC-001 AC-002\n' > "$SANDBOX/proj/tests/all.test.js"
  run_rc 0 "$AC_COV" "$spec_dir"
  assert_contains "$OUT" "bound"
}

test_root_path_containing_test_does_not_classify_everything() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  # A checkout living under a path with "test" in it: repo-relative matching
  # must still require the file itself to smell like a test.
  local root="$SANDBOX/testing-ground/proj2"
  mkdir -p "$root/src"
  printf '// AC-001 AC-002 mentioned in ordinary source\n' > "$root/src/main.go"
  run_rc 1 "$AC_COV" "$spec_dir" --root "$root"
  assert_contains "$OUT" "0 test file(s)"
}

test_no_acs_in_spec_is_a_noop_not_a_crash() {
  local spec_dir; spec_dir="$(make_spec_dir)"
  grep -v 'AC-00' "$spec_dir/spec.md" > "$spec_dir/spec.md.tmp" && mv "$spec_dir/spec.md.tmp" "$spec_dir/spec.md"
  run_rc 0 "$AC_COV" "$spec_dir" --root "$SANDBOX/proj"
  assert_contains "$OUT" "nothing to check"
}

t_run_all
