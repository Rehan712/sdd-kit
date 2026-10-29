#!/usr/bin/env bash
# T030o43 capture failure (CAP-521-Q8OdIp, rc 1), reproduced in a standalone copy, 2026-09-30 (session 10).
# Hypothesis: tests/test-sdd-analyze.sh::analyzer_locale_and_fault_cases builds its fault matcher and
# its expected diagnostics from the caller's spelling of the fixture spec path, which inherits
# TMPDIR's; sdd-analyze.sh:31 canonicalizes that path with `cd && pwd`, which collapses `//`. So with
# a TMPDIR ending in `/` (macOS's default) the suite fails, and with one that does not it passes.
# Read-only against the live worktree: one copy built from the live enumeration (t030o43-dev.sh's
# mkcopy), the suite run twice in it, each run checked to leave the copy unchanged, and the live
# status outside notes/verification/ checked unchanged. Receipts: <scratch>/<label>.{log,rc}.
# Usage from the worktree root: bash <this> <scratch-dir>
set -uo pipefail
SP="${1:?scratch dir}"; WT="$PWD"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
R="$SP/t030o43-tmpdir-repro"; rm -rf "$R"; mkdir -p "$R"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
copystate() { ( cd "$1" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
mkdir -p "$R/c/tmp" "$R/c/kit"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$R/c/kit" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
( cd "$R/c/kit" && git init -q && git add -A && git -c user.name=d -c user.email=d@invalid commit -qm base ) > /dev/null || { say 'FAIL copy git'; exit 2; }
run() { # <label> <tmpdir spelling>
  local label="$1" td="$2" before; before="$(copystate "$R/c/kit")"
  say "== $label: TMPDIR=[$td]"
  ( cd "$R/c/kit" && TMPDIR="$td" bash tests/test-sdd-analyze.sh ) > "$R/$label.log" 2>&1; echo $? > "$R/$label.rc"
  say "  rc=$(cat "$R/$label.rc") $(LC_ALL=C grep -E -- '-- [0-9]+/[0-9]+ passed|^  FAIL' "$R/$label.log" | tr '\n' ' ')"
  say "  failed assertions: $(LC_ALL=C grep -c '^       assert:' "$R/$label.log")"
  LC_ALL=C grep '^       assert:' "$R/$label.log" | cut -c1-160 | sed 's/^/  | /'
  check "$label left its copy unchanged" "$before" "$(copystate "$R/c/kit")"
}
run no-slash "$R/c/tmp"
check 'no-slash exit 0' 0 "$(cat "$R/no-slash.rc")"
run trailing-slash "$R/c/tmp/"
check 'trailing-slash exit 1' 1 "$(cat "$R/trailing-slash.rc")"
check 'trailing-slash fails test_verification_bindings only' 1 "$(LC_ALL=C grep -c '^  FAIL ' "$R/trailing-slash.log")"
check 'the failing test is test_verification_bindings' 1 "$(LC_ALL=C grep -c '^  FAIL test_verification_bindings$' "$R/trailing-slash.log")"
check 'five failed assertions, as in CAP-521-Q8OdIp' 5 "$(LC_ALL=C grep -c '^       assert:' "$R/trailing-slash.log")"
check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$(livestate)"
say "t030o43-tmpdir-repro failures=$fails"
(( fails == 0 ))
