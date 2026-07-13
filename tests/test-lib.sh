#!/usr/bin/env bash
# test-lib.sh — unit tests for scripts/lib.sh (frontmatter, YAML, registry).

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
. "$SCRIPTS/lib.sh"

# --- frontmatter ---------------------------------------------------------------

test_fm_get_reads_only_the_fence() {
  cat > "$SANDBOX/f.md" <<'EOF'
---
phase: tasks
branch: spec/001-foo  # set by spec-worktree.sh
pr: "https://github.com/x/y/pull/1"
owner: '#partner-team on Slack'
---
# Body

phase: shipped
EOF
  assert_eq "tasks" "$(fm_get "$SANDBOX/f.md" phase)" "plain scalar"
  assert_eq "spec/001-foo" "$(fm_get "$SANDBOX/f.md" branch)" "inline comment stripped"
  assert_eq "https://github.com/x/y/pull/1" "$(fm_get "$SANDBOX/f.md" pr)" "double quotes stripped"
  assert_eq "#partner-team on Slack" "$(fm_get "$SANDBOX/f.md" owner)" "# inside quotes is data"
  assert_eq "" "$(fm_get "$SANDBOX/f.md" missing)" "missing key is empty"
}

test_fm_get_no_frontmatter_is_empty() {
  printf '# Just a doc\n\nphase: tasks\n' > "$SANDBOX/f.md"
  assert_eq "" "$(frontmatter_block "$SANDBOX/f.md")" "no fence -> empty block"
  assert_eq "" "$(fm_get "$SANDBOX/f.md" phase)" "body keys are never state"
}

test_fm_list_inline_and_block() {
  cat > "$SANDBOX/f.md" <<'EOF'
---
repos: [alpha, beta]
tags:
  - "one"
  - two   # comment
---
EOF
  assert_eq "alpha beta" "$(fm_list "$SANDBOX/f.md" repos)" "inline list"
  assert_eq "one two" "$(fm_list "$SANDBOX/f.md" tags)" "block list, quotes/comments stripped"
}

test_fm_set_replaces_and_keeps_inline_comment() {
  cat > "$SANDBOX/f.md" <<'EOF'
---
phase: tasks
branch: none  # set by spec-worktree.sh
---
body
EOF
  fm_set "$SANDBOX/f.md" branch "spec/001-foo" || t_fail "fm_set exited nonzero"
  assert_eq "spec/001-foo" "$(fm_get "$SANDBOX/f.md" branch)" "value replaced"
  assert_contains "$(cat "$SANDBOX/f.md")" "branch: spec/001-foo  # set by spec-worktree.sh" "comment preserved"
}

test_fm_set_appends_missing_key_inside_fence() {
  printf -- '---\nphase: tasks\n---\nbody\n' > "$SANDBOX/f.md"
  fm_set "$SANDBOX/f.md" pr "https://example.com/pull/2" || t_fail "fm_set exited nonzero"
  assert_eq "https://example.com/pull/2" "$(fm_get "$SANDBOX/f.md" pr)" "appended key readable"
  # The body must not gain the key — it belongs just before the closing fence.
  assert_eq "1" "$(grep -c '^pr:' "$SANDBOX/f.md" | tr -d ' ')" "exactly one pr: line"
}

test_fm_set_refuses_file_without_frontmatter() {
  printf '# no fence here\n' > "$SANDBOX/f.md"
  run_rc 1 fm_set "$SANDBOX/f.md" phase "done"
  assert_contains "$OUT" "no frontmatter" "diagnostic names the problem"
}

# --- plain YAML ----------------------------------------------------------------

test_yml_get_and_list() {
  cat > "$SANDBOX/stack.yml" <<'EOF'
stacks: [javascript, aws]
base_branch: main   # not dev
EOF
  assert_eq "javascript aws" "$(yml_list "$SANDBOX/stack.yml" stacks)" "inline stacks"
  assert_eq "main" "$(yml_get "$SANDBOX/stack.yml" base_branch)" "comment stripped"
  assert_eq "" "$(yml_get "$SANDBOX/missing.yml" anything)" "missing file is empty, not fatal"
}

test_yml_clean_hash_needs_preceding_space() {
  printf 'value: foo#bar\n' > "$SANDBOX/y.yml"
  assert_eq "foo#bar" "$(yml_get "$SANDBOX/y.yml" value)" "foo#bar is data, not comment"
}

# --- registry ------------------------------------------------------------------

test_registry_entries_parses_entries_in_any_field_order() {
  cat > "$SANDBOX/registry.yml" <<'EOF'
# my projects
projects:
  - name: alpha
    path: ~/code/alpha
    stacks: [js, aws]
  - path: "/opt/beta"
    name: beta
    stacks:
      - rust
      - aws   # trailing comment
  - name: broken
EOF
  local expected
  expected="$(printf 'alpha\t~/code/alpha\tjs aws\nbeta\t/opt/beta\trust aws')"
  assert_eq "$expected" "$(registry_entries "$SANDBOX/registry.yml")" \
    "TSV rows; entry with no path skipped"
}

test_registry_path_for_expands_tilde() {
  printf -- '- name: alpha\n  path: ~/code/alpha\n' > "$SANDBOX/registry.yml"
  assert_eq "$HOME/code/alpha" "$(registry_path_for "$SANDBOX/registry.yml" alpha)"
  assert_eq "" "$(registry_path_for "$SANDBOX/registry.yml" nope)" "unknown name is empty, exit 0"
}

test_expand_tilde() {
  assert_eq "$HOME" "$(expand_tilde "~")"
  # Passing a LITERAL ~/ is the point of the test.
  # shellcheck disable=SC2088
  assert_eq "$HOME/x/y" "$(expand_tilde "~/x/y")"
  assert_eq "/abs/path" "$(expand_tilde "/abs/path")" "absolute path untouched"
  assert_eq "" "$(expand_tilde "")" "empty stays empty"
}

# --- misc ----------------------------------------------------------------------

test_usage_from_header() {
  cat > "$SANDBOX/tool.sh" <<'EOF'
#!/usr/bin/env bash
# tool.sh — does a thing.
#
# Usage: tool.sh <arg>
set -e
# a later comment that must NOT be printed
EOF
  local expected
  expected="$(printf 'tool.sh — does a thing.\n\nUsage: tool.sh <arg>')"
  assert_eq "$expected" "$(usage_from_header "$SANDBOX/tool.sh")"
}

test_spec_declared_repos() {
  mkdir -p "$SANDBOX/spec"
  printf -- '---\nrepos: [alpha, beta]\n---\n' > "$SANDBOX/spec/spec.md"
  assert_eq "alpha beta" "$(spec_declared_repos "$SANDBOX/spec")"
  assert_eq "" "$(spec_declared_repos "$SANDBOX/nonexistent")" "no spec.md is empty, not fatal"
}

t_run_all
