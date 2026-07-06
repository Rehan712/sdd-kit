#!/usr/bin/env bash
# brief-status.sh — detect missing and stale repo briefs (deterministic; no model judgment).
#
# A brief lives at briefs/<repo>.md for every repo in system-map.yml. This script
# reports, per repo, whether a brief exists and whether its recorded commit has
# drifted >= N commits behind the repo's BASE branch (stack.yml base_branch ->
# origin/HEAD -> main|dev|master -> the brief's recorded branch). Repos are
# enumerated by shelling out to system-map.sh — no second YAML parser (§2.1).
#
# Freshness is counted against LOCAL refs only; the default path never touches the
# network. Pass --fetch to opt into a shallow `git fetch` first.
#
# Usage:
#   brief-status.sh list                        # TSV per repo: repo  brief  sha  behind  verdict
#   brief-status.sh check [--threshold N]        # human summary; exit 1 if any missing or stale
#   brief-status.sh repo <repo> [--threshold N]  # single verdict word (fresh|stale|missing|unknown)
#   brief-status.sh --help
#
# Flags:
#   --threshold N   commits-behind that count as stale (default 20)
#   --fetch         allow a shallow `git fetch` (--depth threshold+1) before counting
#
# verdict: fresh | stale | missing (no brief) | unknown (no Source line / nothing to count against)
# Exit: 0 = ok, 1 = not found / check failed, 2 = usage.

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SYSTEM_MAP="$HUB_DIR/scripts/system-map.sh"
BRIEFS_DIR="$HUB_DIR/briefs"
CACHE_DIR="$HUB_DIR/.cache/repos"

GREEN=$'\033[32m'; RED=$'\033[31m'; RESET=$'\033[0m'

# usage [exit-code]: print the header block as help. A nonzero code (a usage
# error — e.g. an unknown subcommand) prints to stderr and exits with it, so a
# typo'd command fails the plain exit-2 contract instead of reporting success.
usage() {
  local code="${1:-0}"
  if (( code == 0 )); then
    sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
  else
    sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//' >&2
  fi
  exit "$code"
}

# --- arg parse --------------------------------------------------------------
CMD="${1:-}"
[[ "$CMD" == "--help" || "$CMD" == "-h" || -z "$CMD" ]] && usage
shift

THRESHOLD=20
FETCH=0
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold)   THRESHOLD="${2:-}"; shift 2 || { echo "--threshold requires a value" >&2; exit 2; } ;;
    --threshold=*) THRESHOLD="${1#*=}"; shift ;;
    --fetch)       FETCH=1; shift ;;
    -h|--help)     usage ;;
    --*)           echo "unknown option: $1" >&2; exit 2 ;;
    *)             POSITIONAL+=("$1"); shift ;;
  esac
done
[[ "$THRESHOLD" =~ ^[0-9]+$ ]] || { echo "--threshold must be a non-negative integer" >&2; exit 2; }
THRESHOLD=$((10#$THRESHOLD))   # force base-10: a leading zero must not read as octal (08, 010) in later (( )) arithmetic

# --- enumeration (single source of truth: system-map.sh) --------------------
# system-map.sh list prints a formatted header row then one row per repo; the
# repo name is column 1. We do NOT parse system-map.yml directly (CON-003 / R5).
repo_names() { "$SYSTEM_MAP" list 2>/dev/null | awk 'NR>1 {print $1}'; }

# --- verdict computation ----------------------------------------------------
# compute <repo> -> sets R_BRIEF R_SHA R_BEHIND R_VERDICT
compute() {
  local repo="$1"
  local brief_file="$BRIEFS_DIR/$repo.md"
  R_BRIEF=no; R_SHA=-; R_BEHIND=-; R_VERDICT=missing

  [[ -f "$brief_file" ]] || return 0
  R_BRIEF=yes

  # Recorded branch + sha come from the brief's Source line, matched by anchor.
  # Format: **Source:** <branch> @ <full-sha>. No Source line => unknown.
  local src_line
  src_line="$(grep -m1 '^\*\*Source:\*\*' "$brief_file" 2>/dev/null || true)"
  if [[ -z "$src_line" ]]; then R_VERDICT=unknown; return 0; fi

  local rest branch full_sha
  rest="${src_line#\*\*Source:\*\*}"
  branch="$(printf '%s' "$rest"  | sed -E 's/^[[:space:]]*//; s/[[:space:]]*@.*$//')"
  full_sha="$(printf '%s' "$rest" | sed -E 's/^.*@[[:space:]]*//; s/[[:space:]]*$//')"
  if [[ -z "$branch" || -z "$full_sha" ]]; then R_VERDICT=unknown; return 0; fi
  # Malformed line (sha not hex — e.g. missing the ` @ ` separator) => unknown,
  # not stale: an unparseable brief is a signal problem, not measured drift.
  if [[ ! "$full_sha" =~ ^[0-9a-f]{7,40}$ ]]; then R_VERDICT=unknown; return 0; fi
  R_SHA="${full_sha:0:12}"

  # Resolve a git dir to count in. LOCAL checkout first (system-map.sh path),
  # else the cache clone. NO fetch/clone on the default path.
  local gitdir="" local_path
  if local_path="$("$SYSTEM_MAP" path "$repo" 2>/dev/null)"; then
    gitdir="$local_path"
  elif [[ -d "$CACHE_DIR/$repo" ]] && git -C "$CACHE_DIR/$repo" rev-parse --git-dir >/dev/null 2>&1; then
    gitdir="$CACHE_DIR/$repo"
  fi
  # Nothing to count against: don't crash, don't fetch — verdict unknown.
  if [[ -z "$gitdir" ]]; then R_VERDICT=unknown; return 0; fi

  # Staleness counts against the repo's BASE branch (REQ-005), not the branch
  # the brief was researched from — a brief anchored to a feature branch must
  # not read fresh while the base line drifts. Resolution: the repo's
  # .specify/stack.yml base_branch -> origin/HEAD -> main|dev|master -> the
  # recorded Source branch as a last resort.
  local base_branch="" head_ref cand
  if [[ -f "$gitdir/.specify/stack.yml" ]]; then
    base_branch="$(sed -n 's/^base_branch:[[:space:]]*//p' "$gitdir/.specify/stack.yml" | head -1 | sed -E 's/[[:space:]]*#.*$//; s/[[:space:]]+$//')"
  fi
  if [[ -z "$base_branch" ]]; then
    head_ref="$(git -C "$gitdir" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null || true)"
    [[ -n "$head_ref" ]] && base_branch="${head_ref#refs/remotes/origin/}"
  fi
  if [[ -z "$base_branch" ]]; then
    for cand in main dev master; do
      if git -C "$gitdir" show-ref --verify --quiet "refs/heads/$cand" \
         || git -C "$gitdir" show-ref --verify --quiet "refs/remotes/origin/$cand"; then
        base_branch="$cand"; break
      fi
    done
  fi
  [[ -z "$base_branch" ]] && base_branch="$branch"

  # Network is opt-in only, and must land BEFORE ref counting so a fetched
  # origin/<base> can affect the verdict. --depth ONLY on an already-shallow
  # repo (the cache clone — deepen to threshold+1 per plan R1): deepening a
  # user's full checkout would create .git/shallow and break its next
  # `git pull` with "refusing to merge unrelated histories" (opponent r3).
  if (( FETCH )); then
    if [[ "$(git -C "$gitdir" rev-parse --is-shallow-repository 2>/dev/null)" == true ]]; then
      git -C "$gitdir" fetch --depth $((THRESHOLD + 1)) >/dev/null 2>&1 || true
    else
      git -C "$gitdir" fetch >/dev/null 2>&1 || true
    fi
  fi

  # Count against BOTH the local base head and origin/<base> when both resolve,
  # and keep the LARGER drift: a frozen local head (stale cache clone, or a
  # fetched-but-not-merged checkout) must not outvote a remote-tracking ref
  # that already measured more commits. Neither ref existing => unknown.
  local refs=()
  git -C "$gitdir" show-ref --verify --quiet "refs/heads/$base_branch" && refs+=("$base_branch")
  git -C "$gitdir" show-ref --verify --quiet "refs/remotes/origin/$base_branch" && refs+=("origin/$base_branch")
  if (( ${#refs[@]} == 0 )); then
    R_VERDICT=unknown; return 0
  fi

  local ref behind best="" unreachable=0
  for ref in "${refs[@]}"; do
    if behind="$(git -C "$gitdir" rev-list --count "${full_sha}..${ref}" 2>/dev/null)" && [[ -n "$behind" ]]; then
      if [[ -z "$best" ]] || (( behind > best )); then best="$behind"; fi
    else
      # Recorded SHA unreachable from this ref (rewritten, or beyond a shallow
      # --fetch depth): its true distance is >= threshold — a stale vote (R1).
      unreachable=1
    fi
  done
  if (( unreachable )); then
    [[ -n "$best" ]] && R_BEHIND="$best"
    R_VERDICT=stale
  else
    R_BEHIND="$best"
    if (( best >= THRESHOLD )); then R_VERDICT=stale; else R_VERDICT=fresh; fi
  fi
}

# --- subcommands ------------------------------------------------------------
case "$CMD" in
  list)
    while IFS= read -r repo; do
      [[ -z "$repo" ]] && continue
      compute "$repo"
      printf '%s\t%s\t%s\t%s\t%s\n' "$repo" "$R_BRIEF" "$R_SHA" "$R_BEHIND" "$R_VERDICT"
    done < <(repo_names)
    exit 0
    ;;

  check)
    total=0; present=0; missing=0; stale=0; unknown=0
    while IFS= read -r repo; do
      [[ -z "$repo" ]] && continue
      total=$((total + 1))
      compute "$repo"
      case "$R_VERDICT" in
        fresh)   present=$((present + 1)) ;;
        stale)   stale=$((stale + 1)) ;;
        unknown) unknown=$((unknown + 1)) ;;
        missing) missing=$((missing + 1)) ;;
      esac
    done < <(repo_names)

    line="briefs: $present present, $missing missing, $stale stale, $unknown unknown (of $total; threshold $THRESHOLD)"
    if (( missing > 0 || stale > 0 )); then
      echo "${RED}✗${RESET} $line"
      exit 1
    else
      echo "${GREEN}✓${RESET} $line"
      exit 0
    fi
    ;;

  repo)
    repo="${POSITIONAL[0]:-}"
    [[ -z "$repo" ]] && { echo "usage: brief-status.sh repo <repo> [--threshold N] [--fetch]" >&2; exit 2; }
    repo_names | grep -qx "$repo" || { echo "unknown repo: $repo" >&2; exit 1; }
    compute "$repo"
    echo "$R_VERDICT"
    exit 0
    ;;

  *)
    echo "unknown command: $CMD" >&2
    usage 2
    ;;
esac
