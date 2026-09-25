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

# Bash's own environment, cleared before any path is resolved: CDPATH makes a
# relative `cd` search elsewhere and print the directory into a substitution,
# and BASH_ENV/ENV make every nested non-interactive shell source a file from
# outside the repository first. None of them is consulted by git, so clearing
# them cannot change what a suite enumerates (O-015 second review).
unset CDPATH BASH_ENV ENV

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Consumed by the test files that source this helper.
# shellcheck disable=SC2034
SCRIPTS="$KIT_DIR/scripts"
# shellcheck disable=SC2034
TODAY="$(date +%Y-%m-%d)"
export NO_COLOR=1   # assertions match plain text, never escape codes

# A suite enumerates the kit under exactly the environment and configuration
# the input identity enumerates under, so only names no enumeration consults
# are cleared when it starts. The suites are reuse-checked and the identity
# declares no environment (verification_environment: []), so the kit's own
# knobs -- SDD_* and XDG_STATE_HOME, the only names its scripts read besides
# HOME, TMPDIR and NO_COLOR -- must not decide a verdict (O-015 review,
# 2026-09-24). HOME and XDG_CONFIG_HOME stay: git reads its global
# configuration and excludes through them, and clearing them made the suites
# skip ignore rules the identity applies (second review). Git's
# repository-local variables (GIT_DIR, GIT_INDEX_FILE, ...) are cleared too,
# exactly as the kernel clears them wherever it runs git
# (vf_git_local_unset): a hook exports them, and inherited they would point
# every fixture's git at the caller's index. A test that needs a knob sets it
# for the command it runs.
for _t_env in $(compgen -e); do
  case "$_t_env" in SDD_*|XDG_STATE_HOME) unset "$_t_env";; esac
done
for _t_env in $(git rev-parse --local-env-vars); do unset "$_t_env"; done
unset _t_env

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

# copy_kit <kit root> <dest> — the kit's hub content as the input identity
# hashes it. Paths come from vf_source_paths (tracked and untracked files git
# does not ignore), so machine-local ignored files such as system-map.yml or
# models.yml never arrive, and neither does .git. Spec directories are left
# out: every byte the identity drops lives under .specify/specs/ (a spec's
# generated records and the lines vf_semantic_file removes), while every other
# enumerated path is hashed verbatim, so what is copied is exactly hashed
# content whichever spec is being verified. No whole-kit consumer reads a spec:
# the doctor runs --hub-only and the wizard reads models.yml. The suites that
# copy the kit are reuse-checked, so a copy carrying bytes the identity does
# not hash would let those bytes decide a reusable verdict (O-015, round 10).
# An indexed path deleted from the working tree is recorded by the identity as
# missing and has nothing to copy.
#
# No EXIT trap, and every failure path cleans up and RETURNS. Run as the whole
# of a command substitution, as run_rc runs it, bash 3.2 unwinds a subshell
# function's locals before an EXIT trap fires on `exit`, so the trap reads the
# CALLER's variables of the same names: on 2026-09-24 an earlier version's
# `rm -f "$list" "$present"` removed a caller's relative `present` -- the live
# kit's .specify/stack.yml.
#
# With a third argument, only the enumerated files under that repository-
# relative directory are copied, verbatim and at their relative paths, spec
# records included: the 002 tally reads another spec's notes/ that way, whose
# every byte the identity hashes as ordinary source, and a directory holding no
# enumerated file -- an empty FLOOR-* left behind, say -- never arrives.
copy_kit() ( # <kit root> <dest> [<repo-relative directory>]
  set -o pipefail
  local src work path rc
  src="$(cd "$1" && pwd -P)" || return 1
  work="$(mktemp -d "${TMPDIR:-/tmp}/copy-kit.XXXXXX")" || return 1
  if ! bash -c '. "$1/verification-lib.sh"; vf_source_paths "$2" "$3"' _ "$SCRIPTS" "$src" "$work/list"; then
    echo "copy_kit: cannot enumerate $1" >&2; rm -rf -- "$work"; return 1
  fi
  while IFS= read -r -d '' path; do
    if [[ -n "${3:-}" ]]; then
      [[ "$path" == "${3%/}"/* ]] || continue
    else
      # Leaving out more is the safe direction, so the spec-directory match
      # folds case everywhere rather than only where the filesystem does.
      shopt -s nocasematch
      case "$path" in .specify/specs/*) shopt -u nocasematch; continue;; esac
      shopt -u nocasematch
    fi
    [[ ! -e "$src/$path" && ! -L "$src/$path" ]] || printf '%s\0' "$path"
  done < "$work/list" > "$work/present"
  mkdir -p "$2" && ( cd "$src" && tar --null -T "$work/present" -cf - ) | ( cd "$2" && tar -xf - )
  rc=$?
  rm -rf -- "$work"
  return "$rc"
)

# make_host_kit <dest> — a copy of the kit that is its own Git worktree, for
# fixtures that plant what a developer's live kit could hold: an ignored file,
# a symlink, an empty directory. Echoes nothing; fails when the copy or the
# repository cannot be made.
make_host_kit() {
  copy_kit "$KIT_DIR" "$1" && git_host "$1"
}

# git_host <dir> — make <dir> a Git worktree whose .git/info exists, so a
# fixture can append ignore rules to .git/info/exclude. Git creates info/ only
# from a template directory, and fixture_git's template is empty.
git_host() {
  mkdir -p "$1" && fixture_git -C "$1" init -q && mkdir -p "$1/.git/info" \
    || { fixture_build_failed "host repository at $1"; return 1; }
}

# fixture_git <git arguments...> — git for a command that writes a repository
# a fixture builds: init, add, commit, checkout, reset, rm, config. It starts
# from none of the caller's git environment -- every exported GIT_* name, and
# EMAIL, is removed: a hook's GIT_AUTHOR_* or GIT_QUARANTINE_PATH,
# GIT_DEFAULT_HASH, GIT_TEMPLATE_DIR, GIT_CONFIG_GLOBAL and the rest -- and
# then pins its own: an empty sandbox HOME and XDG_CONFIG_HOME, no system
# configuration or attributes, an empty template directory and a fixed
# identity. So a user's hooks, signing, template, line-ending or filter
# settings, or a hook's environment, cannot decide whether a fixture repository
# exists or what it holds (O-015 reviews 4 and 5). It also pins where a
# repository may be found: GIT_CEILING_DIRECTORIES stops the search at
# $SANDBOX, so a write in a directory whose own repository was never built
# fails instead of climbing into an enclosing one -- a TMPDIR inside a Git
# worktree (review 6). No fixture repository is $SANDBOX itself. Git READS, and
# the kit's own code under test, keep the ambient environment: the kit's
# enumeration must match the input identity's, and the kernel is the product.
fixture_git() {
  local name scrub=()
  mkdir -p "$SANDBOX/.fixture-git/template" || return 1
  for name in $(compgen -e); do
    case "$name" in GIT_*|EMAIL) scrub+=(-u "$name");; esac
  done
  env ${scrub[@]+"${scrub[@]}"} HOME="$SANDBOX/.fixture-git" XDG_CONFIG_HOME="$SANDBOX/.fixture-git/.config" \
    GIT_CONFIG_NOSYSTEM=1 GIT_ATTR_NOSYSTEM=1 GIT_TEMPLATE_DIR="$SANDBOX/.fixture-git/template" \
    GIT_CEILING_DIRECTORIES="$SANDBOX" \
    git -c user.name=Fixture -c user.email=fixture@example.invalid "$@"
}

# fixture_build_failed <what> — a fixture could not build its own repository or
# copy the kit content it needs. The diagnostic is printed and recorded in
# $SANDBOX/.fixture-build-failed, and t_run_all fails any test that leaves that
# record, naming the build, whatever the caller did with the status: a helper
# run as a command substitution cannot fail its test itself (O-015 review 5).
# Such a helper still prints its sandbox path, so no caller resolves a path
# outside the sandbox (review 6).
fixture_build_failed() {
  printf 'cannot build the %s fixture\n' "$1" >&2
  printf '%s\n' "$1" >> "$SANDBOX/.fixture-build-failed"
}

# on_host_kit <host> <command...> — run a fixture against a host kit. Every
# load-time alias this file defines for a live-kit directory, KIT_DIR and
# SCRIPTS, points into the host for the call, so the fixture judges whatever
# spelling its site reads, a regression to an older one included: a site
# copying "$SCRIPTS" rather than "$KIT_DIR/scripts" would otherwise read the
# live kit, where the planted ignored file is not (O-015 review 3). A suite's
# own directory aliases are bound by the caller the same way.
on_host_kit() {
  local _t_host="$1"; shift
  KIT_DIR="$_t_host" SCRIPTS="$_t_host/scripts" "$@"
}

# git_config_pinned <home> <xdg config home> <command...> — run a command under
# exactly the git configuration a fixture planted: HOME and XDG_CONFIG_HOME as
# given, the system level off, and GIT_CONFIG_GLOBAL and GIT_CONFIG_SYSTEM
# unset, since either replaces the files the fixture wrote. GIT_CONFIG_SYSTEM
# is moot while GIT_CONFIG_NOSYSTEM=1; unsetting it keeps the pin from resting
# on one variable's precedence. Git's command-line configuration variables
# (GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT) are repository-local names that a
# suite has already cleared (O-015 review 3).
git_config_pinned() {
  local home="$1" xdg="$2"; shift 2
  env -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM HOME="$home" XDG_CONFIG_HOME="$xdg" GIT_CONFIG_NOSYSTEM=1 "$@"
}

# kit_files <dir> <basename glob> — NUL-framed repository-relative paths of the
# enumerated files directly inside <dir> of $KIT_DIR whose basename matches the
# glob: the counterpart of "$KIT_DIR/<dir>/<glob>" that sees only what the
# input identity hashes, never an ignored local file (O-015 review). Fails by
# name when the kit cannot be enumerated.
kit_files() {
  local root list path rc=0
  root="$(cd "$KIT_DIR" && pwd -P)" || return 1
  list="$(mktemp "${TMPDIR:-/tmp}/kit-files.XXXXXX")" || return 1
  if bash -c '. "$1/verification-lib.sh"; vf_source_paths "$2" "$3"' _ "$SCRIPTS" "$root" "$list"; then
    while IFS= read -r -d '' path; do
      [[ "$path" == */* && "${path%/*}" == "$1" ]] || continue
      # shellcheck disable=SC2053  # the second argument IS the pattern
      [[ "${path##*/}" == $2 && -f "$root/$path" ]] && printf '%s\0' "$path"
    done < "$list"
  else
    echo "kit_files: cannot enumerate $KIT_DIR" >&2; rc=1
  fi
  rm -f "$list"
  return "$rc"
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
    # A fixture that could not build its repository fails its test by name,
    # whatever the test did with the status (fixture_build_failed).
    if [[ -s "$SANDBOX/.fixture-build-failed" ]]; then
      rc=1
      out="$out
assert: a fixture could not be built: $(tr '\n' ' ' < "$SANDBOX/.fixture-build-failed")"
    fi
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

# Git-backed execution fixture; existing non-Git authoring fixtures stay intact.
make_verification_git_dir() {
  local spec repo
  spec="$(make_verification_spec_dir "${1:-execution}")"
  repo="$(cd "$spec/../../.." && pwd -P)"
  mkdir -p "$repo/src" "$repo/tests" "$repo/scripts" "$repo/docs"
  printf 'value=good\n' > "$repo/src/parser.sh"
  cat > "$repo/tests/check.sh" <<'EOF'
#!/usr/bin/env bash
# AC-001
 test_ac_001_shared() { . src/parser.sh; [[ "$value" == good ]]; }
test_ac_001_shared || exit 1
echo passed
EOF
  # Built through fixture_git and checked: a commit refused by a hook or a
  # signer used to leave the fixture without HEAD, and nothing noticed. A
  # failed build is recorded, so the test fails by name, and the sandbox path
  # is still printed, so no caller -- none of them checks the status --
  # resolves its paths outside the sandbox (review 5: an empty path made
  # "$spec/../../.." the filesystem root).
  if ! { fixture_git -C "$repo" init -q && fixture_git -C "$repo" add . \
      && fixture_git -C "$repo" commit -qm fixture; }; then
    fixture_build_failed "make_verification_git_dir ${1:-execution}"
    printf '%s\n' "$spec"
    return 1
  fi
  printf '%s\n' "$spec"
}
