#!/usr/bin/env bash
# spec-pr.sh — push the spec branch and open a PR to the base branch via gh.
#
# Pushes `spec/NNN-slug` and opens a PR (default base `dev`) whose body links the
# spec/plan/tasks and quotes the opponent + reality-check verdicts from STATUS.md.
# Prints the PR URL on stdout. If `gh` is missing/unauthenticated, the push still
# happens and the manual command is printed to stderr (exit 3).
#
# GATE ENFORCEMENT: refuses to open the PR (exit 4) unless STATUS.md shows
# opponent CLEARED and reality_check READY. `--force` overrides ONLY together
# with `--draft` (a mid-flight draft PR; the body still shows the real
# verdicts). A non-draft PR can never skip the gates.
#
# WRITE-BACK: on success the PR URL is written into STATUS.md frontmatter
# (`pr:`, plus `phase: review` for non-drafts; umbrella repos get `pr_<name>:`)
# and `updated:` is bumped — no session has to remember to do it.
#
# UMBRELLA SPECS (spec.md has `repos:` frontmatter): the spec lives in the hub
# and each declared repo ships its own PR — pass `--repo <name>` per repo.
# Gates are spec-wide (read from the umbrella STATUS.md) and gate ALL the PRs.
#
# Usage:
#   spec-pr.sh <spec-dir>
#   spec-pr.sh --base <branch> <spec-dir>   # default base: dev
#   spec-pr.sh --draft <spec-dir>
#   spec-pr.sh --force --draft <spec-dir>   # mid-flight draft, gates not yet run
#   spec-pr.sh --repo <name> <spec-dir>     # umbrella: PR for one declared repo
#   spec-pr.sh --help

set -euo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
SYSMAP="$HUB_DIR/scripts/system-map.sh"

usage() { usage_from_header "$0"; exit 0; }

BASE=""   # --base wins; else .specify/stack.yml `base_branch:`; else dev
DRAFT=""
FORCE=0
SPEC_ARG=""
REPO_NAME=""

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --base) shift; BASE="${1:?--base needs a branch}" ;;
    --draft) DRAFT="--draft" ;;
    --force) FORCE=1 ;;
    --repo) shift; REPO_NAME="${1:?--repo needs a repo name}" ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) SPEC_ARG="$1" ;;
  esac
  shift
done

[[ -z "$SPEC_ARG" || ! -d "$SPEC_ARG" ]] && { echo "usage: spec-pr.sh <spec-dir>" >&2; exit 2; }

spec_dir="$(cd "$SPEC_ARG" && pwd)"
slug="$(basename "$spec_dir")"
branch="spec/$slug"
status="$spec_dir/STATUS.md"

# Umbrella detection: `repos:` in spec.md FRONTMATTER (body text is ignored).
declared_repos="$(spec_declared_repos "$spec_dir")"

if [[ -n "$declared_repos" ]]; then
  if [[ -z "$REPO_NAME" ]]; then
    echo "umbrella spec ($slug) declares repos: $declared_repos" >&2
    echo "each repo ships its own PR — run once per repo: spec-pr.sh --repo <name> $spec_dir" >&2
    exit 2
  fi
  grep -qw "$REPO_NAME" <<< "$declared_repos" \
    || { echo "repo '$REPO_NAME' is not declared by this umbrella spec (declared: $declared_repos)" >&2; exit 1; }
  repo="$("$SYSMAP" path "$REPO_NAME")" || exit 1
else
  [[ -n "$REPO_NAME" ]] && { echo "--repo only applies to umbrella specs (spec.md with repos: frontmatter)" >&2; exit 2; }
  repo="$(git -C "$spec_dir" rev-parse --show-toplevel)"
fi

# Resolve base branch: flag > project stack.yml `base_branch:` > dev.
# Check the checkout itself first, then the main repo (a worktree checkout may
# predate stack.yml being committed).
read_base() { yml_get "$1/.specify/stack.yml" base_branch; }
if [[ -z "$BASE" ]]; then
  BASE="$(read_base "$repo")"
  if [[ -z "$BASE" ]]; then
    common="$(git -C "$repo" rev-parse --git-common-dir 2>/dev/null || true)"
    [[ -n "$common" && "$common" != /* ]] && common="$repo/$common"
    main_root="$(dirname "$common")"
    [[ -d "$main_root" && "$main_root" != "$repo" ]] && BASE="$(read_base "$main_root")"
  fi
  BASE="${BASE:-dev}"
fi

# Run gh from the spec's worktree when STATUS.md names one; else the repo.
# Umbrella: STATUS frontmatter worktree stays `none` — probe the conventional
# per-repo worktree path instead.
workdir="$repo"
if [[ -n "$declared_repos" ]]; then
  wt="$(dirname "$repo")/$(basename "$repo").worktrees/$slug"
  [[ -d "$wt" ]] && workdir="$wt"
elif [[ -f "$status" ]]; then
  wt="$(fm_get "$status" worktree)"
  [[ -n "$wt" && "$wt" != "none" && -d "$wt" ]] && workdir="$wt"
fi

title="$slug"
[[ -f "$spec_dir/spec.md" ]] && title="$(fm_get_raw "$spec_dir/spec.md" title)"
[[ -z "$title" ]] && title="$slug"
[[ -n "$declared_repos" ]] && title="$title ($REPO_NAME)"

opp="not-run"; rc="not-run"
if [[ -f "$status" ]]; then
  opp="$(fm_get "$status" opponent)"; opp="${opp:-not-run}"
  rc="$(fm_get "$status" reality_check)"; rc="${rc:-not-run}"
fi

# Gate check: both verdicts must lead with CLEARED / READY (any case — real
# STATUS files carry annotations like "CLEARED (2026-06-28)" or "cleared-r2").
opp_lc="$(printf '%s' "$opp" | tr '[:upper:]' '[:lower:]')"
rc_lc="$(printf '%s' "$rc" | tr '[:upper:]' '[:lower:]')"
if [[ "$opp_lc" != cleared* || "$rc_lc" != ready* ]]; then
  if (( FORCE )) && [[ -z "$DRAFT" ]]; then
    echo "REFUSED: --force only applies to draft PRs (--force --draft) — a non-draft PR must pass the gates" >&2
    exit 4
  elif (( FORCE )); then
    echo "warning: opening DRAFT PR with gates not passed (opponent: $opp / reality_check: $rc) — --force --draft given" >&2
  else
    echo "REFUSED: pre-ship gates not passed for $slug" >&2
    echo "  opponent:      $opp   (needs CLEARED)" >&2
    echo "  reality_check: $rc   (needs READY)" >&2
    echo "Run the gates via /sdd:implement, or use --force --draft for a mid-flight draft PR." >&2
    exit 4
  fi
fi

git -C "$workdir" push -u origin "$branch" >&2

if [[ -n "$declared_repos" ]]; then
  # (paste -d takes a delimiter LIST — 'sd', ' would alternate. Join then space.)
  others="$(tr ' ' '\n' <<< "$declared_repos" | grep -vx "$REPO_NAME" | paste -sd, - | sed 's/,/, /g')"
  body="$(cat <<EOF
Implements the **$REPO_NAME** slice of umbrella spec \`$slug\` (hub: \`~/.sdd/specs/$slug/\`).

- Spec / plan / tasks live in the spec hub, not this repo: \`specs/$slug/{spec.md,plan.md,tasks.md}\`
- Sibling PRs (same spec, other repos): $others
- Merge order follows the plan's contract ordering — providers before consumers.

**Pre-ship gates (spec-wide — cover every repo's slice)**
- Opponent: $opp
- Reality-check: $rc
EOF
)"
else
  rel=".specify/specs/$slug"
  body="$(cat <<EOF
Implements spec \`$rel\`.

- Spec: \`$rel/spec.md\`
- Plan: \`$rel/plan.md\`
- Tasks: \`$rel/tasks.md\`

**Pre-ship gates**
- Opponent: $opp
- Reality-check: $rc
EOF
)"
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh not found — branch pushed, open the PR manually:" >&2
  echo "  gh pr create --base $BASE --head $branch --title \"$title\"" >&2
  exit 3
fi

# Create the PR — or, on re-run, reuse the one that already exists (idempotent).
pr_url="$( (cd "$workdir" && gh pr create --base "$BASE" --head "$branch" $DRAFT \
              --title "$title" --body "$body") )" \
  || pr_url="$( (cd "$workdir" && gh pr view "$branch" --json url -q .url 2>/dev/null) )" \
  || { echo "gh pr create failed and no existing PR found for $branch" >&2; exit 3; }
echo "$pr_url"

# Write the PR back into STATUS.md so the dashboard and the next session see it
# without relying on anyone remembering to edit the file.
#   single-repo: pr: <url>, phase: review (drafts keep the current phase)
#   umbrella:    pr_<repo>: <url> — the frontmatter mirror of the Repo matrix row
if [[ -f "$status" ]]; then
  if [[ -n "$declared_repos" ]]; then
    fm_set "$status" "pr_$REPO_NAME" "$pr_url"
  else
    fm_set "$status" pr "$pr_url"
    [[ -z "$DRAFT" ]] && fm_set "$status" phase "review"
  fi
  fm_set "$status" updated "$(date +%Y-%m-%d)"
  echo "STATUS.md updated (pr${declared_repos:+_$REPO_NAME}:, updated:)" >&2
fi
