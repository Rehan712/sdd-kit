#!/usr/bin/env bash
# spec-ac-coverage.sh — does a real test name each AC it proves? (deterministic)
#
# sdd-analyze.sh checks AC coverage on PAPER: every AC-### is referenced by some
# task's *Refs:*. A model satisfies that by typing `Refs: AC-001` — with no test
# in the tree that actually exercises AC-001. This script checks the CODE layer:
# for each AC-### in spec.md, it greps the repo's TEST files for that id. The
# convention it enforces is one line: the test that proves an AC names the AC in
# its title / description / comment (e.g. `it('AC-001: returns 201', …)`).
#
# A hit is a necessary condition, not a sufficient one — a test mentioning AC-001
# still has to assert the right thing, which the reality-check gate verifies. This
# script provides the deterministic FLOOR: an AC with zero test references has
# nothing binding a passing test to it, whatever tasks.md claims.
#
# Test files = files whose path matches test/spec/e2e/__tests__ (case-insensitive),
# under the repo root, excluding vendor/build dirs AND .specify/ (so the spec's own
# AC ids never count as their own coverage). Override the roots with --root, the
# patterns with --tests.
#
# Usage:
#   spec-ac-coverage.sh <spec-dir>                     # single repo: root = git toplevel
#   spec-ac-coverage.sh <spec-dir> --root <dir> ...    # search these roots (repeatable)
#   spec-ac-coverage.sh <spec-dir> --tests '*_test.go' # extra test-path glob (repeatable)
#   spec-ac-coverage.sh --help
#
# Umbrella specs (spec.md repos: frontmatter): with no --root, each declared repo's
# checkout is resolved via system-map.sh and all are searched.
#
# Exit: 0 = every AC has >=1 test reference; 1 = one or more ACs unreferenced or
#       no root resolvable; 2 = usage.

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
SYSMAP="$HUB_DIR/scripts/system-map.sh"

init_colors
usage() { usage_from_header "$0"; exit 0; }

ROOTS=()
EXTRA_GLOBS=()
ARGS=()
while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --root)  shift; ROOTS+=("${1:?--root needs a directory}") ;;
    --tests) shift; EXTRA_GLOBS+=("${1:?--tests needs a glob}") ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done

SPEC_DIR="${ARGS[0]:-}"
[[ -z "$SPEC_DIR" || ! -d "$SPEC_DIR" ]] && { echo "usage: spec-ac-coverage.sh <spec-dir>" >&2; exit 2; }
SPEC_DIR="$(cd "$SPEC_DIR" && pwd)"
SPEC="$SPEC_DIR/spec.md"
[[ -f "$SPEC" ]] || { echo "no spec.md in $SPEC_DIR" >&2; exit 1; }

# --- resolve search roots ---------------------------------------------------
if (( ${#ROOTS[@]} == 0 )); then
  declared_repos="$(spec_declared_repos "$SPEC_DIR")"
  if [[ -n "$declared_repos" ]]; then
    for r in $declared_repos; do
      p="$("$SYSMAP" path "$r" 2>/dev/null || true)"
      [[ -n "$p" && -d "$p" ]] && ROOTS+=("$p") \
        || echo "  ${YELLOW}!${RESET} repo '$r' has no local checkout — pass --root for it" >&2
    done
  else
    top="$(git -C "$SPEC_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$top" && -d "$top" ]]; then
      ROOTS+=("$top")
    elif [[ -d "$SPEC_DIR/../../.." ]]; then
      ROOTS+=("$(cd "$SPEC_DIR/../../.." && pwd)")
    fi
  fi
fi
(( ${#ROOTS[@]} )) || { echo "${RED}✗${RESET} no search root resolvable — pass --root <dir>" >&2; exit 1; }

# --- enumerate test files under the roots -----------------------------------
# Prune vendor/build/.specify; keep files whose REPO-RELATIVE path smells like
# a test. Matching relative to the root matters: a checkout that merely LIVES
# under e.g. ~/testing/ or ~/projects/spectrum/ must not turn every file into
# a "test file" and make this gate vacuously green.
list_test_files() {
  local root="$1" g
  local find_args=(
    .
    \( -name .git -o -name node_modules -o -name target -o -name dist -o -name build \
       -o -name .next -o -name .venv -o -name venv -o -name vendor -o -name coverage \
       -o -name .specify \) -prune -o
    -type f \(
      -ipath '*test*' -o -ipath '*spec*' -o -ipath '*e2e*' -o -ipath '*__tests__*'
  )
  for g in ${EXTRA_GLOBS[@]+"${EXTRA_GLOBS[@]}"}; do
    find_args+=( -o -ipath "*$g*" -o -name "$g" )
  done
  find_args+=( \) -print )
  ( cd "$root" && find "${find_args[@]}" 2>/dev/null ) | sed "s|^\./|$root/|"
}

TESTS_TMP="$(mktemp "${TMPDIR:-/tmp}/ac-cov.XXXXXX")" || exit 1
trap 'rm -f "$TESTS_TMP"' EXIT
for root in "${ROOTS[@]}"; do
  [[ -d "$root" ]] || continue
  list_test_files "$root"
done | sort -u > "$TESTS_TMP"
test_count="$(grep -c . "$TESTS_TMP" || true)"

# --- per-AC coverage --------------------------------------------------------
spec_acs="$(grep -oE 'AC-[0-9]{3}' "$SPEC" | sort -u)"
[[ -z "$spec_acs" ]] && { echo "${YELLOW}!${RESET} spec.md defines no AC-### ids — nothing to check"; exit 0; }

echo "AC↔test binding for $(basename "$SPEC_DIR")  (roots: ${ROOTS[*]}; $test_count test file(s))"
missing=0
for ac in $spec_acs; do
  if [[ "$test_count" == 0 ]]; then
    hits=""
  else
    # AC-001 must not match AC-0012 etc. AC ids are 3 digits so this is belt-and-braces.
    # xargs -0 so test paths with spaces survive (find output is newline-delimited).
    hits="$(tr '\n' '\0' < "$TESTS_TMP" | xargs -0 grep -lE "${ac}([^0-9]|$)" 2>/dev/null || true)"
  fi
  if [[ -n "$hits" ]]; then
    n="$(printf '%s\n' "$hits" | grep -c .)"
    echo "  ${GREEN}✓${RESET} $ac — named in $n test file(s)"
    printf '%s\n' "$hits" | sed "s#^#      #"
  else
    echo "  ${RED}✗${RESET} $ac — no test file names it"
    missing=$((missing+1))
  fi
done

echo "---"
if (( missing == 0 )); then
  echo "${GREEN}bound${RESET} — every AC is named by at least one test file"
  exit 0
else
  echo "${RED}$missing AC(s)${RESET} with no test naming them — add the AC id to the test that proves it, or add the test"
  exit 1
fi
