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
      [[ -n "$url" && "$url" != "none" ]] && printf '%s\t%s\n' "$r" "$url"
    done
  else
    url="$(fm_get "$status" pr)"
    [[ -n "$url" && "$url" != "none" ]] && printf '%s\t%s\n' "$(basename "$spec_dir")" "$url"
  fi
  return 0
}

# probe_one <url> — echoes "checks/review/merge" tokens:
#   checks: pass|fail|pending|none   review: approved|changes|waiting
#   merge:  clean|conflicts|unknown
probe_one() {
  gh pr view "$1" --json state,reviewDecision,mergeable,statusCheckRollup 2>/dev/null | awk '
    BEGIN { checks="none"; review="waiting"; merge="unknown"; fail=0; pend=0; ok=0 }
    { buf = buf $0 }
    END {
      if (buf == "") { print "error"; exit }
      # statusCheckRollup entries: count conclusions/statuses.
      n = split(buf, parts, /"(conclusion|state)":"/)
      for (i = 2; i <= n; i++) {
        v = parts[i]; sub(/".*/, "", v)
        if (v == "FAILURE" || v == "TIMED_OUT" || v == "CANCELLED" || v == "ERROR" || v == "ACTION_REQUIRED") fail++
        else if (v == "PENDING" || v == "IN_PROGRESS" || v == "QUEUED" || v == "EXPECTED" || v == "") pend++
        else if (v == "SUCCESS" || v == "NEUTRAL" || v == "SKIPPED") ok++
      }
      if (fail > 0) checks="fail"; else if (pend > 0) checks="pending"; else if (ok > 0) checks="pass"
      if (buf ~ /"reviewDecision":"APPROVED"/) review="approved"
      else if (buf ~ /"reviewDecision":"CHANGES_REQUESTED"/) review="changes"
      if (buf ~ /"mergeable":"MERGEABLE"/) merge="clean"
      else if (buf ~ /"mergeable":"CONFLICTING"/) merge="conflicts"
      print checks "/" review "/" merge
    }'
}

# aggregate — probes every PR; prints per-PR lines to stderr and the worst
# state to stdout; empty output means no PRs recorded.
aggregate() {
  local worst="green" line label url state checks review merge
  local urls; urls="$(pr_urls)"
  [[ -z "$urls" ]] && return 3
  while IFS=$'\t' read -r label url; do
    state="$(probe_one "$url")"
    if [[ -z "$state" || "$state" == "error" ]]; then
      echo "  $label: cannot read PR state ($url) — gh error/auth?" >&2
      worst="error"; continue
    fi
    checks="${state%%/*}"; review="$(cut -d/ -f2 <<< "$state")"; merge="${state##*/}"
    echo "  $label: checks=$checks review=$review merge=$merge  $url" >&2
    case "$checks" in
      fail) [[ "$worst" != "error" ]] && worst="red" ;;
      pending) [[ "$worst" == "green" || "$worst" == "changes" || "$worst" == "conflicts" ]] && worst="pending" ;;
    esac
    [[ "$merge" == "conflicts" && "$worst" == "green" ]] && worst="conflicts"
    [[ "$review" == "changes" && "$worst" == "green" ]] && worst="changes"
  done <<< "$urls"
  echo "$worst"
}

write_ci() {  # <field-value>
  fm_set "$status" ci "$1 ($(date +%Y-%m-%d))" 2>/dev/null || true
}

finish() {  # <worst> — write-back + exit code
  local worst="$1"
  case "$worst" in
    green)     write_ci green;   echo "CI: green — checks pass, approved/no objections, mergeable"; exit 0 ;;
    pending)   write_ci pending; echo "CI: pending — checks still running"; exit 10 ;;
    red)       write_ci red;     echo "CI: red — failing checks (run: spec-ci.sh logs $spec_dir)"; exit 20 ;;
    changes)   write_ci red;     echo "CI: changes requested by a reviewer"; exit 30 ;;
    conflicts) write_ci red;     echo "CI: merge conflicts — rebase spec branch onto base"; exit 40 ;;
    error|*)   echo "CI: could not read one or more PRs" >&2; exit 3 ;;
  esac
}

case "$CMD" in
  check)
    worst="$(aggregate)" || { echo "no PR recorded in STATUS.md — run spec-pr.sh first" >&2; exit 3; }
    finish "$worst"
    ;;

  watch)
    start=$(date +%s)
    while :; do
      worst="$(aggregate)" || { echo "no PR recorded in STATUS.md — run spec-pr.sh first" >&2; exit 3; }
      [[ "$worst" != "pending" ]] && finish "$worst"
      (( $(date +%s) - start >= TIMEOUT )) && { write_ci pending; echo "CI: still pending after ${TIMEOUT}s — giving up (re-run watch)"; exit 10; }
      echo "  …checks pending; next poll in ${INTERVAL}s" >&2
      sleep "$INTERVAL"
    done
    ;;

  logs)
    urls="$(pr_urls)"
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
