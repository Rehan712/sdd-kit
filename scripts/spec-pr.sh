#!/usr/bin/env bash
# spec-pr.sh — push the spec branch and open a PR to the base branch via gh.
#
# Pushes `spec/NNN-slug` and opens a PR (default base `dev`) whose body links the
# spec/plan/tasks and quotes the opponent + reality-check verdicts from STATUS.md.
# Prints the PR URL on stdout. If `gh` is missing/unauthenticated, the push still
# happens and the manual command is printed to stderr (exit 3). A forced draft
# needs gh before the push so an existing non-draft PR cannot receive unchecked work.
#
# GATE ENFORCEMENT: refuses to open the PR (exit 4) unless STATUS.md shows
# opponent CLEARED and reality_check READY. Versioned specs also require current sealed rounds. `--force` overrides ONLY together
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
#   spec-pr.sh --verify-head <spec-dir>     # validate for merge and print the reviewed commit
#   spec-pr.sh --help

set -euo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
SYSMAP="$HUB_DIR/scripts/system-map.sh"

usage() { usage_from_header "$0"; exit 0; }

BASE=""   # --base wins; else .specify/stack.yml `base_branch:`; else dev
DRAFT=""
FORCE=0
VERIFY_HEAD=0
SPEC_ARG=""
REPO_NAME=""

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --base) shift; BASE="${1:?--base needs a branch}" ;;
    --verify-head) VERIFY_HEAD=1 ;;
    --draft) DRAFT="--draft" ;;
    --force) FORCE=1 ;;
    --repo) shift; REPO_NAME="${1:?--repo needs a repo name}" ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) SPEC_ARG="$1" ;;
  esac
  shift
done

[[ -z "$SPEC_ARG" || ! -d "$SPEC_ARG" ]] && { echo "usage: spec-pr.sh <spec-dir>" >&2; exit 2; }

if (( VERIFY_HEAD )) && [[ -n "$DRAFT" || "$FORCE" == 1 ]]; then echo "--verify-head cannot override gates" >&2; exit 2; fi
if (( FORCE )) && [[ -z "$DRAFT" ]]; then echo "--force requires --draft" >&2; exit 4; fi

spec_dir="$(cd "$SPEC_ARG" && pwd -P)"
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
  list_has "$declared_repos" "$REPO_NAME" \
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

# Locate the branch via Git even when STATUS points at an old checkout.
workdir="$(git -C "$repo" worktree list --porcelain | awk -v branch="refs/heads/$branch" '
  /^worktree / {path=substr($0,10)} $0=="branch " branch {print path}')"
head="$(git -C "$repo" rev-parse --verify "refs/heads/$branch^{commit}")" || exit 4
. "$HUB_DIR/scripts/verification-lib.sh"
contract="$(vf_contract "$spec_dir/spec.md")" || exit 4
# A locally removed contract key cannot downgrade a versioned branch to label-only gates.
if [[ -z "$contract" && -z "$declared_repos" ]]; then
  spec_path=".specify/specs/$slug/spec.md"
  tree_entry="$(git -C "$repo" ls-tree "$head" -- "$spec_path")" || exit 4
  if [[ -n "$tree_entry" ]]; then
    committed_contract="$(
      tmp="$(mktemp)" || exit 1; trap 'rm -f "$tmp"' EXIT
      git -C "$repo" show "$head:$spec_path" > "$tmp" && vf_contract "$tmp"
    )" || exit 4
    contract="$committed_contract"
  fi
fi
if [[ -n "$workdir" ]]; then
  workdir="$(cd "$workdir" && pwd -P)"
  if [[ -z "$declared_repos" && -f "$workdir/.specify/specs/$slug/spec.md" ]]; then
    spec_dir="$workdir/.specify/specs/$slug"
    current="$(vf_contract "$spec_dir/spec.md")" || exit 4
    [[ -z "$contract" || "$current" == "$contract" ]] || { echo 'worktree contract mismatch' >&2; exit 4; }
    contract="$current"; status="$spec_dir/STATUS.md"
  fi
elif [[ -n "$contract" ]]; then
  echo "release: reviewed worktree for $branch required" >&2; exit 4
else workdir="$repo"; fi

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
  if (( FORCE )); then
    echo "warning: opening DRAFT PR with gates not passed (opponent: $opp / reality_check: $rc) — --force --draft given" >&2
  else
    echo "REFUSED: pre-ship gates not passed for $slug" >&2
    echo "  opponent:      $opp   (needs CLEARED)" >&2
    echo "  reality_check: $rc   (needs READY)" >&2
    echo "Run the gates via /sdd:implement, or use --force --draft for a mid-flight draft PR." >&2
    exit 4
  fi
fi

if [[ "$contract" == 1 && "$FORCE" == 0 ]]; then
  if [[ -z "$declared_repos" && "$(git -C "$spec_dir" rev-parse --show-toplevel)" != "$workdir" ]]; then
    echo "release: spec must be verified in $workdir" >&2; exit 4
  fi
  vf_release_check "$spec_dir" "$workdir" "$head" || exit 4
  [[ "$(git -C "$workdir" symbolic-ref --quiet HEAD)" == "refs/heads/$branch" &&
     "$(git -C "$workdir" rev-parse HEAD)" == "$head" ]] || { echo 'branch changed during verification' >&2; exit 4; }
fi
if (( VERIFY_HEAD )); then printf '%s\n' "$head"; exit 0; fi
if (( FORCE )); then
  ready="$(cd "$workdir" && gh pr list --head "$branch" --state open --json isCrossRepository,isDraft --jq '[.[] | select(.isCrossRepository == false and .isDraft == false)] | length')" || {
    echo 'cannot establish draft status before pushing with --force' >&2; exit 4; }
  [[ "$ready" == 0 ]] || { echo 'refusing to push unreviewed commits to an open non-draft PR' >&2; exit 4; }
fi
git -C "$workdir" push origin "$head:refs/heads/$branch" >&2
git -C "$workdir" branch --set-upstream-to="origin/$branch" "$branch" >&2

if [[ -n "$declared_repos" ]]; then
  # (paste -d takes a delimiter LIST — 'sd', ' would alternate. Join then space.)
  others="$(tr ' ' '\n' <<< "$declared_repos" | awk -v self="$REPO_NAME" '$0!=self' | paste -sd, - | sed 's/,/, /g')"
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
  echo "  gh pr create $DRAFT --base $BASE --head $branch --title \"$title\"" >&2
  exit 3
fi

# Create the PR — or, on re-run, reuse the one that already exists (idempotent).
pr_url="$( (cd "$workdir" && gh pr create --base "$BASE" --head "$branch" $DRAFT \
              --title "$title" --body "$body") )" \
  || pr_url="$( (cd "$workdir" && gh pr list --state open --base "$BASE" --head "$branch" --json url,isCrossRepository --jq '.[] | select(.isCrossRepository == false) | .url') )" \
  || { echo "gh pr create failed and no existing PR found for $branch" >&2; exit 3; }
[[ -n "$pr_url" && "$pr_url" != *$'\n'* ]] || { echo "no unique open PR for the published commit and base" >&2; exit 3; }
remote="$(cd "$workdir" && gh pr view "$pr_url" --json state,baseRefName,headRefName,headRefOid,isCrossRepository,isDraft \
  --jq '[.state,.baseRefName,.headRefName,.headRefOid,(.isCrossRepository|tostring),(.isDraft|tostring)] | join("|")')" || exit 3
draft_flag=false; [[ -z "$DRAFT" ]] || draft_flag=true
[[ "$remote" == "OPEN|$BASE|$branch|$head|false|$draft_flag" ]] || {
  echo 'open PR does not match the published commit, branch, base or draft status' >&2; exit 4; }
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
