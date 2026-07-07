#!/usr/bin/env bash
# spec-evidence.sh — evidence integrity: does every ticked box trace to a REAL
# record? (deterministic; the check that makes spec-run.sh non-bypassable)
#
# spec-run.sh makes a captured run the easy path, but a model can still hand-tick
# with spec-task.sh and type an evidence string — including a `(see
# notes/evidence.md)` pointer to a capture block that never happened, or a
# `screenshot: shots/x.png` for a file that doesn't exist. This check closes that:
#
#   ERRORS (hard, unambiguous)
#     1. an [x] non-gate/non-Ship task with no *Evidence:* line
#     2. an *Evidence:* line pointing to notes/evidence.md with NO matching
#        `## T### …` capture block there (a fabricated pointer)
#     3. an *Evidence:* line naming a screenshot/PDF artifact that isn't on disk
#        (manual-AC evidence must be a committed artifact, not an imaginary path)
#
#   WARNINGS (advisory)
#     4. spec.md marks an AC manual/post-deploy ([DEPLOY]/[MANUAL]/UNVERIFIABLE,
#        or the reality-check deferred it) but STATUS.md records no owner +
#        check-back date — the post-deploy claim has no one on the hook for it
#
# Gate tasks (an *Agent:* line) and Ship-stage tasks are exempt — their evidence
# is the gate report / PR URL, matching spec-task.sh and sdd-analyze.sh.
#
# Usage:
#   spec-evidence.sh <spec-dir>
#   spec-evidence.sh --help
#
# Exit: 0 = clean (warnings allowed), 1 = integrity errors, 2 = usage.

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"

init_colors
usage() { usage_from_header "$0"; exit 0; }

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && usage
SPEC_DIR="${1:-}"
[[ -z "$SPEC_DIR" || ! -d "$SPEC_DIR" ]] && { echo "usage: spec-evidence.sh <spec-dir>" >&2; exit 2; }
SPEC_DIR="$(cd "$SPEC_DIR" && pwd)"
SPEC="$SPEC_DIR/spec.md"; TASKS="$SPEC_DIR/tasks.md"; STATUS="$SPEC_DIR/STATUS.md"
EVID="$SPEC_DIR/notes/evidence.md"; RC="$SPEC_DIR/notes/reality-check.md"
[[ -f "$TASKS" ]] || { echo "no tasks.md in $SPEC_DIR" >&2; exit 1; }

errors=0; warnings=0
pass() { echo "  ${GREEN}✓${RESET} $1"; }
fail() { echo "  ${RED}✗${RESET} $1"; errors=$((errors+1)); }
warn() { echo "  ${YELLOW}!${RESET} $1"; warnings=$((warnings+1)); }

echo "Evidence integrity: $(basename "$SPEC_DIR")"

# Umbrella artifacts live in per-repo worktrees the hub can't cheaply resolve —
# there, a missing artifact path is a warning, not a hard error.
is_umbrella=0
[[ -n "$(spec_declared_repos "$SPEC_DIR")" ]] && is_umbrella=1
repo_root="$(git -C "$SPEC_DIR" rev-parse --show-toplevel 2>/dev/null || true)"

# --- per-task records: id \t stage \t is_gate \t is_done \t evidence-text -----
records="$(awk '
  function flush() { if (id!="") printf "%s\t%s\t%d\t%d\t%s\n", id, stage, is_gate, is_done, ev; id="" }
  /^##[^#]/ { flush(); sub(/^##[[:space:]]*/,""); stage=$0 }
  /^- \[[ xX~]\] \*\*T[0-9]{3}[a-z0-9]*\*\*/ {
    flush(); match($0,/T[0-9]{3}[a-z0-9]*/); id=substr($0,RSTART,RLENGTH)
    is_done = ($0 ~ /^- \[[xX]\]/) ? 1 : 0; is_gate=0; ev=""; next
  }
  /\*Agent:\*/ { is_gate=1 }
  /\*Evidence[^*]*:\*/ {
    line=$0; sub(/^[[:space:]]*-[[:space:]]*\*Evidence[^*]*:\*[[:space:]]*/,"",line); ev=line
  }
  END { flush() }
' "$TASKS")"

checked=0
while IFS=$'\t' read -r id stage is_gate is_done ev; do
  [[ -z "$id" ]] && continue
  (( is_done )) || continue
  (( is_gate )) && continue
  [[ "$stage" =~ Ship|Reality ]] && continue
  checked=$((checked+1))

  # 1. ticked but no evidence line
  if [[ -z "${ev// /}" ]]; then
    fail "$id is [x] with no *Evidence:* line — an unproven claim"
    continue
  fi

  # 2. pointer to notes/evidence.md must resolve to a real capture block
  case "$ev" in
    *evidence.md*)
      if [[ ! -f "$EVID" ]]; then
        fail "$id evidence points to notes/evidence.md, but that file doesn't exist — no captured run"
      elif ! grep -qE "^##[[:space:]]+${id}([^0-9A-Za-z]|$)" "$EVID"; then
        fail "$id evidence points to notes/evidence.md, but no \`## $id …\` capture block is there — fabricated pointer?"
      fi
      ;;
  esac

  # 3. named screenshot/PDF artifact must exist on disk
  for art in $(printf '%s\n' "$ev" | grep -oiE '[[:graph:]]+\.(png|jpg|jpeg|gif|svg|pdf)' || true); do
    art="${art%[.,;:)]}"   # trim trailing punctuation
    if [[ -e "$art" || -e "$SPEC_DIR/$art" || ( -n "$repo_root" && -e "$repo_root/$art" ) ]]; then
      :
    elif (( is_umbrella )); then
      warn "$id names artifact '$art' — not found under the hub (umbrella: check the repo worktree)"
    else
      fail "$id names artifact '$art' in its evidence, but no such file exists"
    fi
  done
done <<< "$records"

(( checked > 0 )) && pass "$checked ticked task(s) checked for evidence integrity" \
  || pass "no ticked implementation tasks yet — nothing to verify"

# --- 4. manual / post-deploy ACs need an owner + check-back date -------------
manual_acs=""
if [[ -f "$SPEC" ]]; then
  manual_acs="$(grep -E 'AC-[0-9]{3}' "$SPEC" | grep -iE '\[DEPLOY\]|\[MANUAL\]|UNVERIFIABLE' \
                 | grep -oE 'AC-[0-9]{3}' | sort -u || true)"
fi
if [[ -f "$RC" ]]; then
  # AC ids under a "Deferred to post-deploy" heading in the reality-check report.
  deferred="$(awk '
    /[Dd]eferred to post-deploy/ { grab=1; next }
    /^#/ { grab=0 }
    grab { print }
  ' "$RC" | grep -oE 'AC-[0-9]{3}' | sort -u || true)"
  manual_acs="$(printf '%s\n%s\n' "$manual_acs" "$deferred" | grep -oE 'AC-[0-9]{3}' | sort -u || true)"
fi

if [[ -n "$manual_acs" ]]; then
  has_checkback=0
  if [[ -f "$STATUS" ]] && grep -qE '\b(20|21)[0-9]{2}-[0-1][0-9]-[0-3][0-9]\b' "$STATUS"; then
    has_checkback=1
  fi
  n="$(printf '%s\n' "$manual_acs" | grep -c .)"
  if (( has_checkback )); then
    pass "$n manual/post-deploy AC(s) and STATUS.md records a check-back date"
  else
    warn "$n manual/post-deploy AC(s) ($(printf '%s' "$manual_acs" | paste -sd' ' -)) but STATUS.md names no owner + check-back date"
  fi
fi

echo "---"
if (( errors == 0 && warnings == 0 )); then
  echo "${GREEN}sound${RESET} — every ticked box traces to real evidence"; exit 0
elif (( errors == 0 )); then
  echo "${YELLOW}$warnings warning(s)${RESET}, 0 errors"; exit 0
else
  echo "${RED}$errors error(s)${RESET}, $warnings warning(s)"; exit 1
fi
