#!/usr/bin/env bash
# tests/helpers.sh — assertions + fixtures for the kit's test suite. Source it:
#
#   . "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
#
# A test file defines test_* functions and ends with `t_run_all`. Each test
# runs in a subshell with a fresh $SANDBOX temp dir (removed afterwards).
# Assertions print a diagnostic and mark the test failed; they don't abort it,
# so one run shows every failing assertion.
#
# Everything here is bash-3.2 and BSD-tool safe, like the scripts under test.

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Consumed by the test files that source this helper.
# shellcheck disable=SC2034
SCRIPTS="$KIT_DIR/scripts"
# shellcheck disable=SC2034
TODAY="$(date +%Y-%m-%d)"
export NO_COLOR=1   # assertions match plain text, never escape codes

_t_fail=0
t_fail() { printf 'assert: %s\n' "$1"; _t_fail=1; }

# assert_eq <expected> <actual> [label]
assert_eq() {
  [[ "$1" == "$2" ]] && return 0
  t_fail "${3:-values differ}
    expected: $1
    actual:   $2"
}

# assert_contains <haystack> <needle> [label]
assert_contains() {
  case "$1" in *"$2"*) return 0 ;; esac
  t_fail "${3:-output} missing substring: $2
    in: $(printf '%s' "$1" | head -c 600)"
}

# assert_not_contains <haystack> <needle> [label]
assert_not_contains() {
  case "$1" in
    *"$2"*) t_fail "${3:-output} unexpectedly contains: $2" ;;
  esac
}

# run_rc <expected-rc> <cmd...> — run, capture combined output in $OUT,
# assert the exit code. $OUT stays available for content assertions.
run_rc() {
  local want="$1" got
  shift
  OUT="$("$@" 2>&1)"
  got=$?
  [[ "$got" -eq "$want" ]] && return 0
  t_fail "expected exit $want, got $got: $*
    output: $(printf '%s' "$OUT" | head -c 600)"
}

# --- fixtures -----------------------------------------------------------------

# make_spec_dir — a minimal project in $SANDBOX/proj whose one spec passes
# sdd-analyze.sh cleanly (artifacts, AC coverage, gates, agent files).
# Echoes the spec dir path.
make_spec_dir() {
  local proj="$SANDBOX/proj"
  local spec_dir="$proj/.specify/specs/001-test-feature"
  mkdir -p "$spec_dir" "$proj/agents"
  echo "adversarial reviewer stub" > "$proj/agents/opponent.agent.md"
  echo "evidence auditor stub" > "$proj/agents/reality-check.agent.md"

  cat > "$spec_dir/spec.md" <<'EOF'
---
spec: 001-test-feature
project: proj
---
# Spec: Test feature

## Goals

- REQ-001 — store the thing durably

## Success metrics

- MET-001 — p95 write latency under 100ms

## Acceptance criteria

- AC-001 — POST /thing returns 201 and persists the payload
- AC-002 — an invalid payload returns 400 with an error body
EOF

  cat > "$spec_dir/plan.md" <<'EOF'
---
plan_for: 001-test-feature
---
# Plan: Test feature

Covers REQ-001 with a storage module (AC-001) and input validation (AC-002).
EOF

  cat > "$spec_dir/STATUS.md" <<'EOF'
---
spec: 001-test-feature
phase: tasks
branch: none
---
# Status

## Blockers

(none)
EOF

  cat > "$spec_dir/tasks.md" <<'EOF'
---
tasks_for: 001-test-feature
status: in-progress
created: 2026-01-01
updated: 2026-01-01
---
# Tasks: Test feature

## Setup

- [ ] **T001** — Add scaffolding
  - *Files:* `src/`
  - *Acceptance:* build succeeds

## Backend

- [ ] **T002** — Implement the thing endpoint
  - *Files:* `src/thing.js`
  - *Acceptance:* unit test passes
  - *Refs:* REQ-001, AC-001

- [ ] **T003** — Validate payloads
  - *Files:* `src/validate.js`
  - *Acceptance:* invalid-payload test passes
  - *Refs:* AC-002

## Reality Check (pre-ship gate)

- [ ] **T009** — Opponent review: steelman why this implementation is wrong
  - *Agent:* agents/opponent.agent.md
  - *Acceptance:* agent returns **CLEARED**
  - *Refs:* AC-001, AC-002

- [ ] **T010** — Reality-check the implemented spec end-to-end
  - *Agent:* agents/reality-check.agent.md
  - *Acceptance:* agent returns **READY**
  - *Refs:* AC-001, AC-002

## Ship

- [ ] **T011** — Open PR to the base branch
  - *Acceptance:* spec-pr.sh prints the PR URL
EOF

  echo "$spec_dir"
}

# tag_task <tasks.md> <T###> <repo> — add a [repo:<name>] tag to one task line.
tag_task() {
  local f="$1" id="$2" repo="$3"
  sed "s/\*\*$id\*\* — /**$id** [repo:$repo] — /" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

# make_umbrella <spec-dir> <repos-inline> — declare `repos:` in spec.md
# frontmatter (e.g. "[alpha, beta]"), turning the fixture into an umbrella spec.
make_umbrella() {
  local spec="$1/spec.md"
  awk -v repos="$2" '
    /^project:/ { print; print "repos: " repos; next }
    { print }
  ' "$spec" > "$spec.tmp" && mv "$spec.tmp" "$spec"
}

# --- runner --------------------------------------------------------------------

# t_run_all — run every test_* function defined so far; report and exit.
t_run_all() {
  local fn total=0 failed=0 out rc
  for fn in $(declare -F | awk '{print $3}' | grep '^test_'); do
    total=$((total+1))
    # No "test"/"spec" in the sandbox name — scripts under test use path
    # heuristics, and the harness must never satisfy them by accident.
    SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")" || exit 1
    export SANDBOX
    out="$( ( _t_fail=0; "$fn"; exit "$_t_fail" ) 2>&1 )"
    rc=$?
    if (( rc == 0 )); then
      echo "  ok   $fn"
    else
      failed=$((failed+1))
      echo "  FAIL $fn"
      [[ -n "$out" ]] && printf '%s\n' "$out" | sed 's/^/       /'
    fi
    rm -rf "$SANDBOX"
  done
  echo "  -- $((total-failed))/$total passed"
  (( failed == 0 ))
}
