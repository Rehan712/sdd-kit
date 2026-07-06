#!/usr/bin/env bash
# spec-worktree.sh — create (or reuse) a git worktree + branch for a spec.
#
# Cuts branch `spec/NNN-slug` from local `dev` (default base — it carries the spec
# docs you committed there; warns if local dev is behind origin) and adds a worktree at:
#     <repo-parent>/<repo-name>.worktrees/NNN-slug
# The worktree is a sibling of the repo, OUTSIDE the working tree — no .gitignore
# entry needed and no nested-git noise.
#
# UMBRELLA SPECS (spec.md has `repos:` frontmatter; the spec lives in the hub's
# specs/): the branch+worktree is cut in each DECLARED repo, not in the hub.
#   --repo <name>   cut/reuse for that one repo (path resolved via registry);
#                   prints its worktree path as the last line, same contract.
#   --all-repos     cut/reuse for every declared repo; prints one
#                   `<name>TAB<worktree>` line per repo instead.
#
# Idempotent: if a worktree already exists for the branch, its path is returned.
# Prints the absolute worktree path as the LAST line of stdout; all diagnostics
# go to stderr, so callers can do:  WT="$(spec-worktree.sh <spec-dir> | tail -1)"
#
# Usage:
#   spec-worktree.sh <spec-dir>                 # e.g. .../.specify/specs/004-foo
#   spec-worktree.sh --project <repo> 004-foo   # by slug, repo explicit
#   spec-worktree.sh --base <ref> <spec-dir>    # override base branch (default dev)
#   spec-worktree.sh --repo <name> <spec-dir>   # umbrella: one declared repo
#   spec-worktree.sh --all-repos <spec-dir>     # umbrella: every declared repo
#   spec-worktree.sh --help

set -euo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DETECT="$HUB_DIR/scripts/project-detect.sh"
SYSMAP="$HUB_DIR/scripts/system-map.sh"

usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

BASE=""   # --base wins; else .specify/stack.yml `base_branch:`; else dev
PROJECT=""
SPEC_ARG=""
REPO_NAME=""
ALL_REPOS=0

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --base) shift; BASE="${1:?--base needs a ref}" ;;
    --project) shift; PROJECT="${1:?--project needs a path}" ;;
    --repo) shift; REPO_NAME="${1:?--repo needs a repo name}" ;;
    --all-repos) ALL_REPOS=1 ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) SPEC_ARG="$1" ;;
  esac
  shift
done

[[ -z "$SPEC_ARG" ]] && { echo "usage: spec-worktree.sh <spec-dir|NNN-slug>" >&2; exit 2; }

# Resolve slug + spec_dir, whether given a spec-dir path or a bare slug.
spec_dir=""
if [[ -d "$SPEC_ARG" ]]; then
  spec_dir="$(cd "$SPEC_ARG" && pwd)"
  slug="$(basename "$spec_dir")"
elif [[ -d "$HUB_DIR/specs/$SPEC_ARG" ]]; then
  spec_dir="$HUB_DIR/specs/$SPEC_ARG"   # bare slug naming a hub umbrella spec
  slug="$SPEC_ARG"
else
  slug="$SPEC_ARG"
fi

# Umbrella = spec.md declares `repos:` frontmatter.
declared_repos=""
if [[ -n "$spec_dir" && -f "$spec_dir/spec.md" ]]; then
  declared_repos="$(sed -n 's/^repos:[[:space:]]*\[\([^]]*\)\].*/\1/p' "$spec_dir/spec.md" | head -1 | tr -d ' ' | tr ',' ' ')"
fi

# Resolve base branch for a given repo: flag > its stack.yml `base_branch:` > dev.
read_base() {
  # Missing stack.yml must mean "no answer", not death-by-pipefail under set -e.
  [[ -f "$1/.specify/stack.yml" ]] || return 0
  sed -n 's/^base_branch:[[:space:]]*//p' "$1/.specify/stack.yml" \
    | head -1 | sed -E 's/[[:space:]]*#.*$//; s/[[:space:]]+$//'
}
resolve_base() {  # <repo> — echoes the base ref name
  local repo="$1" base="$BASE" common main_root
  if [[ -z "$base" ]]; then
    base="$(read_base "$repo")"
    if [[ -z "$base" ]]; then
      common="$(git -C "$repo" rev-parse --git-common-dir 2>/dev/null || true)"
      [[ -n "$common" && "$common" != /* ]] && common="$repo/$common"
      main_root="$(dirname "$common")"
      [[ -d "$main_root" && "$main_root" != "$repo" ]] && base="$(read_base "$main_root")"
    fi
    base="${base:-dev}"
  fi
  echo "$base"
}

# cut_one <repo-path> — create/reuse branch spec/$slug + worktree; echoes wt path.
cut_one() {
  local repo="$1" base branch wt existing base_ref behind
  base="$(resolve_base "$repo")"
  branch="spec/$slug"
  wt="$(dirname "$repo")/$(basename "$repo").worktrees/$slug"

  # Reuse an existing worktree for this branch if there is one.
  existing="$(git -C "$repo" worktree list --porcelain | awk -v b="refs/heads/$branch" '
    /^worktree /{ w=$2 }
    /^branch /{ if ($2==b) print w }
  ')"
  if [[ -n "$existing" ]]; then
    echo "reusing existing worktree for $branch: $existing" >&2
    echo "$existing"
    return 0
  fi

  # Base on LOCAL `$base` — it carries the spec docs you committed there. We fetch
  # only to warn when local is behind origin; we do NOT base on origin/$base, which
  # would silently drop locally-committed-but-unpushed spec docs.
  if git -C "$repo" show-ref --verify --quiet "refs/heads/$base"; then
    base_ref="$base"
  else
    base_ref="origin/$base"   # no local branch (e.g. fresh clone); fall back to remote
  fi
  if git -C "$repo" remote get-url origin >/dev/null 2>&1; then
    if git -C "$repo" fetch origin "$base" >/dev/null 2>&1; then
      if [[ "$base_ref" == "$base" ]]; then
        behind="$(git -C "$repo" rev-list --count "$base..origin/$base" 2>/dev/null || echo 0)"
        [[ "$behind" =~ ^[0-9]+$ && "$behind" -gt 0 ]] && \
          echo "warning: local $base is $behind commit(s) behind origin/$base — consider 'git -C $repo pull' before implementing" >&2
      fi
    else
      echo "fetch origin $base failed; basing on local $base" >&2
    fi
  fi

  mkdir -p "$(dirname "$wt")"

  if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
    echo "branch $branch exists; attaching worktree at $wt" >&2
    git -C "$repo" worktree add "$wt" "$branch" >&2
  else
    echo "creating $branch from $base_ref; worktree at $wt" >&2
    git -C "$repo" worktree add -b "$branch" "$wt" "$base_ref" >&2
  fi

  echo "$wt"
}

# --- Umbrella dispatch ---
if [[ -n "$declared_repos" ]]; then
  if [[ -n "$REPO_NAME" ]]; then
    grep -qw "$REPO_NAME" <<< "$declared_repos" \
      || { echo "repo '$REPO_NAME' is not declared by this umbrella spec (declared: $declared_repos)" >&2; exit 1; }
    repo_path="$("$SYSMAP" path "$REPO_NAME")" || exit 1
    cut_one "$repo_path"
    exit 0
  elif (( ALL_REPOS )); then
    rc=0
    for r in $declared_repos; do
      if repo_path="$("$SYSMAP" path "$r")"; then
        wt="$(cut_one "$repo_path" | tail -1)"
        printf '%s\t%s\n' "$r" "$wt"
      else
        echo "skipping $r — not resolvable on this machine" >&2
        rc=1
      fi
    done
    exit "$rc"
  else
    echo "umbrella spec ($slug) declares repos: $declared_repos" >&2
    echo "pass --repo <name> for one worktree, or --all-repos for all" >&2
    exit 2
  fi
fi

[[ -n "$REPO_NAME" || "$ALL_REPOS" == 1 ]] && \
  { echo "--repo/--all-repos only apply to umbrella specs (spec.md with repos: frontmatter)" >&2; exit 2; }

# --- Single-repo spec: resolve the one repo and cut ---
if [[ -n "$spec_dir" ]]; then
  repo="$(git -C "$spec_dir" rev-parse --show-toplevel)"
else
  if [[ -z "$PROJECT" ]]; then
    PROJECT="$("$DETECT")" || { echo "cannot resolve project; pass --project or a spec-dir path" >&2; exit 1; }
  fi
  repo="$(cd "$PROJECT" && git rev-parse --show-toplevel)"
fi
cut_one "$repo"
