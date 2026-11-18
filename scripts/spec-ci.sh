#!/usr/bin/env bash
# spec-ci.sh — deterministic PR/CI state for a spec in review (the CI watcher).
#
# Owns the machine half of the review phase: reads the PR(s) recorded in
# STATUS.md by spec-pr.sh, asks gh for check + review + mergeability state,
# writes the aggregate back to STATUS.md (`ci:` frontmatter), and exits with a
# distinct code per state so skills and hooks can branch without parsing prose.
# Judgment (triaging a red build, deciding to merge) belongs to /sdd:review.
#
# Umbrella specs: aggregates over every declared repo's PR (worst state wins);
# --repo <name> narrows to one.
#
# Usage:
#   spec-ci.sh check <spec-dir>            # one-shot state probe + ci: write-back
#   spec-ci.sh watch <spec-dir>            # poll until checks settle (then = check)
#   spec-ci.sh logs  <spec-dir>            # failing checks -> notes/ci.md (+ stdout)
#   spec-ci.sh --repo <name> check <dir>   # umbrella: one declared repo only
#   spec-ci.sh --interval N --timeout N watch <dir>   # defaults 30s / 1800s
#
# Exit codes:
#   0  green   — checks pass, no changes requested, no conflicts
#   3  no PR recorded / gh missing or unauthenticated
#   10 pending — checks still running (watch timed out while pending)
#   20 red     — at least one required check failing
#   30 changes requested by a reviewer
#   40 merge conflicts (branch needs a rebase onto base)
#   2  usage
#
# ci: frontmatter written: green | pending | red (+ date). "changes requested"
# and "conflicts" also write red — CI-red vs review-red is in the exit code and
# the printed summary, not the coarse field.

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"

usage() { usage_from_header "$0"; exit 0; }

REPO_NAME=""
INTERVAL=30
TIMEOUT=1800
ARGS=()
while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --repo) shift; REPO_NAME="${1:?--repo needs a name}" ;;
    --interval) shift; INTERVAL="${1:?--interval needs seconds}" ;;
    --timeout) shift; TIMEOUT="${1:?--timeout needs seconds}" ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done
CMD="${ARGS[0]:-}"
SPEC_ARG="${ARGS[1]:-}"
[[ -z "$CMD" || -z "$SPEC_ARG" || ! -d "$SPEC_ARG" ]] && { usage_from_header "$0" >&2; exit 2; }
spec_dir="$(cd "$SPEC_ARG" && pwd)"
status="$spec_dir/STATUS.md"
[[ -f "$status" ]] || { echo "no STATUS.md in $spec_dir" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "gh not found — spec-ci.sh needs the GitHub CLI" >&2; exit 3; }

declared_repos="$(spec_declared_repos "$spec_dir")"
[[ -n "$REPO_NAME" && -z "$declared_repos" ]] \
  && { echo "--repo only applies to umbrella specs" >&2; exit 2; }

# pr_urls — one "label<TAB>url" line per PR to inspect.
pr_urls() {
  local r url
  if [[ -n "$declared_repos" ]]; then
    for r in $declared_repos; do
      [[ -n "$REPO_NAME" && "$r" != "$REPO_NAME" ]] && continue
      url="$(fm_get "$status" "pr_$r")"
      [[ -n "$url" && "$url" != "none" ]] || { echo "missing PR for $r" >&2; return 3; }
      printf '%s\t%s\n' "$r" "$url"
    done
  else
    url="$(fm_get "$status" pr)"
    [[ -n "$url" && "$url" != "none" ]] && printf '%s\t%s\n' "$(basename "$spec_dir")" "$url"
  fi
  return 0
}

# Read all merge conditions from one PR response. Unknown conditions remain pending.
probe_one() {
  local summary state draft review merge status checks check pending=0
  summary="$(gh pr view "$1" --json state,isDraft,reviewDecision,mergeable,mergeStateStatus,statusCheckRollup --jq '
    [.state, (.isDraft|tostring), (.reviewDecision // ""), .mergeable, .mergeStateStatus,
     ([.statusCheckRollup[] | if .__typename == "CheckRun" then
        (if .status == "COMPLETED" then .conclusion else "PENDING" end)
        else .state end | . // "UNKNOWN"] | join(","))] | join("|")')" || return 3
  IFS='|' read -r state draft review merge status checks <<< "$summary"
  case "$state" in MERGED) echo merged; return;; CLOSED) echo closed; return;; OPEN) ;; *) return 3;; esac
  local results=()
  IFS=, read -r -a results <<< "$checks"
  for check in ${results[@]+"${results[@]}"}; do
    case "$check" in
      FAILURE|TIMED_OUT|CANCELLED|ERROR|ACTION_REQUIRED|STARTUP_FAILURE) echo red; return;;
      SUCCESS|NEUTRAL|SKIPPED) ;;
      *) pending=1;;
    esac
  done
  if [[ "$merge" == CONFLICTING ]]; then echo conflicts
  elif [[ "$review" == CHANGES_REQUESTED ]]; then echo changes
  elif [[ "$draft" != false || "$merge" != MERGEABLE || ( "$status" != CLEAN && "$status" != HAS_HOOKS ) ||
          ( -n "$review" && "$review" != APPROVED ) || "$pending" == 1 ]]; then echo pending
  else echo green; fi
}

# aggregate — probes every PR; prints per-PR lines to stderr and the worst
# state to stdout; empty output means no PRs recorded.
aggregate() {
  local worst=0 open=0 rank label url state urls
  local states=(green pending changes conflicts red error)
  urls="$(pr_urls)" || return 3
  [[ -n "$urls" ]] || return 3
  while IFS=$'\t' read -r label url; do
    state="$(probe_one "$url")" || state=error
    echo "  $label: $state  $url" >&2
    if [[ "$state" == merged && -n "$declared_repos" && -z "$REPO_NAME" ]]; then continue; fi
    open=$((open+1))
    case "$state" in
      green) rank=0;; pending) rank=1;; changes) rank=2;; conflicts) rank=3;;
      red|closed|merged) rank=4;; *) rank=5;;
    esac
    if (( rank > worst )); then worst=$rank; fi
  done <<< "$urls"
  if (( open == 0 )); then echo merged; else echo "${states[worst]}"; fi
}

write_ci() {  # <field-value>
  fm_set "$status" ci "$1 ($(date +%Y-%m-%d))" 2>/dev/null || true
}

finish() {  # <worst> — write-back + exit code
  local worst="$1"
  case "$worst" in
    green)     write_ci green;   echo "CI: green — checks pass, approved/no objections, mergeable"; exit 0 ;;
    pending)   write_ci pending; echo "CI: pending — checks still running"; exit 10 ;;
    red)       write_ci red;     echo "CI: red — closed PR or failed checks (run: spec-ci.sh logs $spec_dir)"; exit 20 ;;
    changes)   write_ci red;     echo "CI: changes requested by a reviewer"; exit 30 ;;
    conflicts) write_ci red;     echo "CI: merge conflicts — rebase spec branch onto base"; exit 40 ;;
    merged)    echo "CI: all recorded PRs already merged"; exit 3 ;;
    error|*)   write_ci pending; echo "CI: could not read one or more PRs" >&2; exit 3 ;;
  esac
}

case "$CMD" in
  check)
    worst="$(aggregate)" || { write_ci pending; echo "no PR recorded in STATUS.md — run spec-pr.sh first" >&2; exit 3; }
    finish "$worst"
    ;;

  watch)
    start=$(date +%s)
    while :; do
      worst="$(aggregate)" || { write_ci pending; echo "no PR recorded in STATUS.md — run spec-pr.sh first" >&2; exit 3; }
      [[ "$worst" != "pending" ]] && finish "$worst"
      (( $(date +%s) - start >= TIMEOUT )) && { write_ci pending; echo "CI: still pending after ${TIMEOUT}s — giving up (re-run watch)"; exit 10; }
      echo "  …checks pending; next poll in ${INTERVAL}s" >&2
      sleep "$INTERVAL"
    done
    ;;

  logs)
    urls="$(pr_urls)" || exit 3
    [[ -z "$urls" ]] && { echo "no PR recorded in STATUS.md" >&2; exit 3; }
    mkdir -p "$spec_dir/notes"
    out="$spec_dir/notes/ci.md"
    {
      echo "# CI failures — $(basename "$spec_dir")"
      echo
      echo "**Date:** $(date +%Y-%m-%d)"
      echo
      while IFS=$'\t' read -r label url; do
        echo "## $label — $url"
        echo
        echo '```'
        # Failing checks summary (name, state, link) — never let a gh error kill the report.
        gh pr checks "$url" 2>&1 | grep -viE '\bpass\b|\bsuccess\b|\bskipping\b|\bskipped\b' || echo "(no failing checks listed)"
        echo '```'
        echo
        # For GitHub-Actions checks, pull the failed-step logs of each failing run.
        for run_id in $(gh pr checks "$url" 2>/dev/null | grep -oE 'runs/[0-9]+' | cut -d/ -f2 | sort -u | head -5); do
          echo "### run $run_id — failed steps"
          echo
          echo '```'
          gh run view "$run_id" --log-failed 2>&1 | tail -100 || echo "(logs unavailable)"
          echo '```'
          echo
        done
      done <<< "$urls"
    } > "$out"
    echo "wrote $out" >&2
    cat "$out"
    ;;

  *)
    echo "unknown command: $CMD" >&2
    usage_from_header "$0" >&2
    exit 2
    ;;
esac
