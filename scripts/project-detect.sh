#!/usr/bin/env bash
# project-detect.sh — resolve cwd to a registered project root.
#
# Strategy:
#   1. Walk cwd upward; the first ancestor containing `.specify/stack.yml`
#      wins. Print that ancestor.
#   2. If cwd is inside a linked git worktree (e.g. <repo>.worktrees/NNN-slug,
#      a sibling of the repo), identify the project via the MAIN repo root,
#      but print the WORKTREE root — edits must stay in the worktree.
#   3. Otherwise, search `registry.yml` for a project whose `path:` is an
#      ancestor of cwd. Print the longest match.
#   4. If nothing matches, exit 1.
#
# Usage:
#   project-detect.sh              # prints resolved project root or fails
#   project-detect.sh --stacks     # also prints stacks (TAB-separated)
#   project-detect.sh /some/path   # resolve a path other than cwd
#   project-detect.sh --help

set -euo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
REGISTRY="$HUB_DIR/registry.yml"

usage() { usage_from_header "$0"; exit 0; }

WITH_STACKS=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage ;;
    --stacks) WITH_STACKS=1 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) TARGET="$arg" ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  TARGET="$PWD"
fi

if [[ ! -d "$TARGET" ]]; then
  echo "not a directory: $TARGET" >&2
  exit 2
fi

ABS_TARGET="$(cd "$TARGET" && pwd)"

# Extract `stacks:` from a stack.yml (inline [a, b] or block-list form), TAB-separated.
stacks_from_yml() { yml_list "$1" stacks | tr ' ' '\t'; }

# Match a path against registry.yml; sets REG_PATH / REG_STACKS on success.
# registry_entries (lib.sh) handles ~ paths, quoting, and any field order.
registry_match() {
  local probe="$1"
  REG_PATH=""; REG_STACKS=""
  [[ -f "$REGISTRY" ]] || return 1
  local best_len=0 p_name p_path p_stacks
  while IFS=$'\t' read -r p_name p_path p_stacks; do
    [[ -z "$p_path" ]] && continue
    p_path="$(expand_tilde "$p_path")"
    if [[ "$probe" == "$p_path" || "$probe" == "$p_path"/* ]]; then
      if (( ${#p_path} > best_len )); then
        REG_PATH="$p_path"; REG_STACKS="$(printf '%s' "$p_stacks" | tr ' ' '\t')"; best_len=${#p_path}
      fi
    fi
  done < <(registry_entries "$REGISTRY")
  [[ -n "$REG_PATH" ]]
}

emit() {  # emit <root> [<stacks>]
  echo "$1"
  if (( WITH_STACKS )) && [[ -n "${2:-}" ]]; then
    printf '%s\n' "$2"
  fi
  exit 0
}

# --- Strategy 1: nearest ancestor with .specify/stack.yml ---
walk="$ABS_TARGET"
while [[ "$walk" != "/" && -n "$walk" ]]; do
  if [[ -f "$walk/.specify/stack.yml" ]]; then
    emit "$walk" "$(stacks_from_yml "$walk/.specify/stack.yml")"
  fi
  walk="$(dirname "$walk")"
done

# --- Strategy 2: linked git worktree — identify via main repo, print worktree root ---
if command -v git >/dev/null 2>&1; then
  common="$(git -C "$ABS_TARGET" rev-parse --git-common-dir 2>/dev/null || true)"
  gitdir="$(git -C "$ABS_TARGET" rev-parse --git-dir 2>/dev/null || true)"
  if [[ -n "$common" && -n "$gitdir" && "$common" != "$gitdir" ]]; then
    # Linked worktree: common dir lives in the main repo ("/main/.git/..." or ".git").
    [[ "$common" != /* ]] && common="$(cd "$ABS_TARGET" && cd "$common" && pwd)"
    main_root="$(dirname "${common%/.git*}/.git")"
    wt_root="$(git -C "$ABS_TARGET" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$wt_root" && -d "$main_root" ]]; then
      if [[ -f "$main_root/.specify/stack.yml" ]]; then
        emit "$wt_root" "$(stacks_from_yml "$main_root/.specify/stack.yml")"
      fi
      if registry_match "$main_root"; then
        emit "$wt_root" "$REG_STACKS"
      fi
    fi
  fi
fi

# --- Strategy 3: registry.yml match ---
if [[ ! -f "$REGISTRY" ]]; then
  echo "no project resolved (no .specify/stack.yml ancestor and no registry.yml at $REGISTRY)" >&2
  exit 1
fi

if registry_match "$ABS_TARGET"; then
  emit "$REG_PATH" "$REG_STACKS"
fi

echo "no project matches $ABS_TARGET (cwd not under any registered project root, and not a worktree of one)" >&2
exit 1
