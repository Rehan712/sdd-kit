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

# Authoring fixtures declare illustrative checks; these commands are data for
# analyzer tests, never fabricated execution proof for the fixture application.
make_fixture_gate_config() {
  mkdir -p "$1/.specify"
  cat > "$1/.specify/stack.yml" <<'EOF'
stacks: []
gate_checks:
  - 'bash tests/check.sh'
reuse_checks: []
verification_tools:
  - 'bash'
verification_inputs: []
EOF
}

# make_spec_dir — a minimal project in $SANDBOX/proj whose one spec passes
# sdd-analyze.sh cleanly (artifacts, AC coverage, gates, agent files).
# Echoes the spec dir path.
make_spec_dir() {
  local proj="$SANDBOX/proj"
  local spec_dir="$proj/.specify/specs/001-test-feature"
  mkdir -p "$spec_dir" "$proj/agents"
  make_fixture_gate_config "$proj"
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
  - *Verify:* `npm run build` → "built"

## Backend

- [ ] **T002** — Implement the thing endpoint
  - *Files:* `src/thing.js`
  - *Acceptance:* unit test passes
  - *Verify:* `node --test test/thing.test.js` → "pass 1"
  - *Refs:* REQ-001, AC-001

- [ ] **T003** — Validate payloads
  - *Files:* `src/validate.js`
  - *Acceptance:* invalid-payload test passes
  - *Verify:* `node --test test/validate.test.js` → "pass 2"
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

# make_verification_spec_dir [name] — a new-contract fixture with concrete,
# shared FM/INV rows and one family/task for each verification kind. Files and
# literals are declarations only at task handoff; acceptance owns their later
# existence checks.
make_verification_spec_dir() {
  local name="${1:-verification-proj}"
  local proj="$SANDBOX/$name"
  local spec_dir="$proj/.specify/specs/003-verification-fixture"
  mkdir -p "$spec_dir" "$proj/agents"
  make_fixture_gate_config "$proj"
  echo "adversarial reviewer stub" > "$proj/agents/opponent.agent.md"
  echo "evidence auditor stub" > "$proj/agents/reality-check.agent.md"

  cat > "$spec_dir/spec.md" <<'EOF'
---
spec_id: 003-verification-fixture
project: verification-proj
verification_contract: 1
---
# Spec: Verification fixture

## Goals

- REQ-001 — run the shell test
- REQ-002 — run the custom behavioral assertion
- REQ-003 — check the static schema
- REQ-004 — record the release observation

## Acceptance criteria

- AC-001 — the shared boundary behavior has an executable shell test
- AC-002 — a custom command proves the second shared behavior
- AC-003 — the documentation schema is statically checked
- AC-004 — the release artifact is observed by a human
EOF

  cat > "$spec_dir/plan.md" <<'EOF'
---
plan_for: 003-verification-fixture
---
# Plan: Verification fixture

REQ-001, REQ-002, REQ-003 and REQ-004 use the families below.

## Risks, failure modes and verification

| ID | Components | Category | Trigger | Decided behavior | Test families |
|---|---|---|---|---|---|
| FM-001 | parser, runner | boundary | A shared malformed binding reaches either component | Reject the binding before execution | shell-family, assertion-family |
| FM-002 | docs | regression | The documented schema drifts | Fail the static schema check | static-family |

| ID | Scope | Promise | Enforcement sites | Test families |
|---|---|---|---|---|
| INV-001 | release | Every manual result names its artifact | Release checklist | manual-family |

Exclusions: docs / concurrency/ordering — documentation has no shared mutable state.

| Family | Kind | Criteria | Concrete locators |
|---|---|---|---|
| shell-family | test | AC-001 | `tests/check.sh::test_ac_001_shared` |
| assertion-family | assertion | AC-002 | `scripts/check-contract.sh::assert_ac_002_contract` |
| static-family | static | AC-003 | `tests/static.sh::test_ac_003_schema` |
| manual-family | manual | AC-004 | release-observation |
| integration-family | test | AC-001, AC-002 | `tests/integration.sh::test_ac_001_002_integration` |
EOF

  cat > "$spec_dir/STATUS.md" <<'EOF'
---
spec: 003-verification-fixture
phase: tasks
branch: none
---
# Status

## Blockers

(none)
EOF

  cat > "$spec_dir/tasks.md" <<'EOF'
---
tasks_for: 003-verification-fixture
status: draft
---
# Tasks: Verification fixture

## Backend

- [ ] **T001** — Cover the shared shell boundary
  - *Files:* `src/parser.sh`, `tests/check.sh`
  - *Acceptance:* Add and pass the shared boundary shell test.
  - *Verify kind:* test
  - *Tests:* `tests/check.sh::test_ac_001_shared`
  - *Verify:* `bash tests/check.sh` → passed
  - *Reuse:* local
  - *Refs:* REQ-001, AC-001, FM-001
  - *Integration owner:* T005

- [ ] **T002** — Cover the shared custom assertion
  - *Files:* `src/runner.sh`, `scripts/check-contract.sh`
  - *Acceptance:* Add and pass the custom behavioral assertion.
  - *Verify kind:* assertion
  - *Tests:* `scripts/check-contract.sh::assert_ac_002_contract`
  - *Verify:* `bash scripts/check-contract.sh` → passed
  - *Refs:* REQ-002, AC-002, FM-001
  - *Integration owner:* T005

## Docs

- [ ] **T003** — Check the static schema
  - *Files:* `docs/schema.md`, `tests/static.sh`
  - *Acceptance:* Add and pass the static documentation schema check.
  - *Verify kind:* static
  - *Tests:* `tests/static.sh::test_ac_003_schema`
  - *Verify:* `bash tests/static.sh` → passed
  - *Refs:* REQ-003, AC-003, FM-002

- [ ] **T004** — Observe the release artifact
  - *Files:* `artifacts/release.txt`
  - *Acceptance:* Record the observer and digest for the release artifact.
  - *Verify kind:* manual
  - *Tests:* release-observation
  - *Verify:* `manual: inspect the release artifact and record its digest`
  - *Refs:* REQ-004, AC-004, INV-001

## Tests

- [ ] **T005** — Compose the cross-task integration
  - *Files:* `tests/integration.sh`
  - *Acceptance:* Add and pass the parser/runner integration test.
  - *Verify kind:* test
  - *Tests:* `tests/integration.sh::test_ac_001_002_integration`
  - *Verify:* `bash tests/integration.sh` → passed
  - *Refs:* REQ-001, REQ-002, AC-001, AC-002

## Reality Check (pre-ship gate)

- [ ] **T009** — Opponent review
  - *Agent:* agents/opponent.agent.md
  - *Acceptance:* agent returns CLEARED
  - *Refs:* AC-001, AC-002, AC-003, AC-004

- [ ] **T010** — Reality-check
  - *Agent:* agents/reality-check.agent.md
  - *Acceptance:* agent returns READY
  - *Refs:* AC-001, AC-002, AC-003, AC-004

## Ship

- [ ] **T011** — Open the PR
  - *Acceptance:* PR URL recorded
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
