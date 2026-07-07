#!/usr/bin/env bash
# sync.sh — link the kit's skills + agents into every Claude home.
#
# Distribution model: one symlink PER skill/agent into each Claude home
# (~/.claude and ~/.claude_*), pointing into ~/.sdd (this repo). Your other,
# non-SDD skills and agents in those homes are never touched. Editing the
# repo is publishing — there are no copies to drift.
#
#   ~/.claude/skills/sdd-specify  -> ~/.sdd/skills/sdd-specify
#   ~/.claude/agents/opponent.agent.md -> ~/.sdd/agents/opponent.agent.md
#   ...
#
# Model policy: when models.yml is configured, apply-models.sh generates
# model/effort-stamped copies under build/, and the links point there instead
# (still inside ~/.sdd — the hub stays canonical, build/ is derived from it):
#
#   ~/.claude/skills/sdd-specify -> ~/.sdd/build/skills/sdd-specify
#   ...
#
# Codex (~/.codex) and Copilot (~/.copilot) can't share these files directly —
# scripts/build-adapters.sh generates their adapted copies.
#
# Usage:
#   sync.sh                # create/repair all links (prunes stale kit links too)
#   sync.sh --check        # verify only; exit 1 if anything is mis-wired
#   sync.sh --remove       # uninstall: delete every link that points into the
#                          # kit from every home (nothing else is touched)
#   sync.sh --home <path>  # limit to one home (repeatable)
#   sync.sh --help

set -euo pipefail

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$KIT_DIR/scripts/lib.sh"
# Prefer the stable ~/.sdd path as the link target when it points at this repo,
# so links survive the clone moving (re-run setup.sh after a move either way).
TARGET_ROOT="$KIT_DIR"
if [[ -L "$HOME/.sdd" && "$(readlink "$HOME/.sdd")" == "$KIT_DIR" ]]; then
  TARGET_ROOT="$HOME/.sdd"
fi

init_colors

usage() { usage_from_header "$0"; exit 0; }

CHECK=0
REMOVE=0
HOMES=()

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --check) CHECK=1 ;;
    --remove) REMOVE=1 ;;
    --home) shift; HOMES+=("${1:?--home needs a path}") ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

if (( ${#HOMES[@]} == 0 )); then
  for d in "$HOME/.claude" "$HOME"/.claude_*; do
    [[ -d "$d" ]] || continue
    case "$(basename "$d")" in
      *.bak|*.backup|*.old|*.orig|*.pre-sync.*|*.pre-sdd.*|.sdd-displaced) continue ;;
    esac
    HOMES+=("$d")
  done
fi

if (( ${#HOMES[@]} == 0 )); then
  # Not an error: Codex/Copilot-only machines are supported — their adapters
  # come from build-adapters.sh. Failing here used to abort setup.sh entirely.
  echo "no Claude homes found (~/.claude or ~/.claude_*) — nothing to link; skipping (Codex/Copilot adapters are generated separately)" >&2
  exit 0
fi

problems=0
fixed=0

# ensure_item_link <link-path> <target> <label>
ensure_item_link() {
  local link="$1" target="$2" label="$3"
  if [[ -L "$link" ]]; then
    if [[ "$(readlink "$link")" == "$target" ]]; then
      return
    fi
    if (( CHECK )); then
      echo "  ${RED}✗${RESET} $label: symlink to wrong place ($(readlink "$link"))"
      problems=$((problems+1))
    else
      ln -sfn "$target" "$link"
      echo "  ${GREEN}✓${RESET} $label: re-pointed to kit"
      fixed=$((fixed+1))
    fi
  elif [[ -e "$link" ]]; then
    if (( CHECK )); then
      echo "  ${RED}✗${RESET} $label: real file/dir shadows the kit (drift risk)"
      problems=$((problems+1))
    else
      # Park displaced copies OUTSIDE skills/ and agents/ — a backup left in
      # skills/ gets discovered by Claude Code as a duplicate skill.
      local bakdir="$(dirname "$(dirname "$link")")/.sdd-displaced"
      local bak="$bakdir/$(basename "$link").$(date +%Y%m%d%H%M%S)"
      mkdir -p "$bakdir"
      mv "$link" "$bak"
      ln -s "$target" "$link"
      echo "  ${YELLOW}!${RESET} $label: existing copy moved to ${bak/#$HOME/~}, linked to kit"
      fixed=$((fixed+1))
    fi
  else
    if (( CHECK )); then
      echo "  ${RED}✗${RESET} $label: missing"
      problems=$((problems+1))
    else
      mkdir -p "$(dirname "$link")"
      ln -s "$target" "$link"
      echo "  ${GREEN}+${RESET} $label: linked"
      fixed=$((fixed+1))
    fi
  fi
}

# Model policy: prefer the stamped copies under build/ (see apply-models.sh).
POLICY_ACTIVE=0
if [[ -f "$KIT_DIR/models.yml" ]]; then
  if [[ -d "$KIT_DIR/build" ]]; then
    POLICY_ACTIVE=1
    echo "model policy active — linking the stamped copies under build/"
  else
    echo "${YELLOW}!${RESET} models.yml present but build/ missing — run scripts/apply-models.sh; linking canonical files for now"
  fi
fi

# item_target <kind> <name> — canonical path, or the stamped build copy when present.
item_target() {
  local kind="$1" name="$2"
  if (( POLICY_ACTIVE )) && [[ -e "$KIT_DIR/build/$kind/$name" ]]; then
    echo "$TARGET_ROOT/build/$kind/$name"
  else
    echo "$TARGET_ROOT/$kind/$name"
  fi
}

# points_into_kit <link> — true when the symlink's target is inside the kit
# (via either the real clone path or the stable ~/.sdd alias).
points_into_kit() {
  local t; t="$(readlink "$1")"
  [[ "$t" == "$KIT_DIR"/* || "$t" == "$HOME/.sdd/"* ]]
}

# prune_stale <home> — drop kit-owned links whose source item no longer exists
# (renamed/removed skills and agents would otherwise dangle forever).
# In --remove mode, drops ALL kit-owned links (the uninstall path).
prune_stale() {
  local home="$1" link name
  for link in "$home"/skills/* "$home"/agents/*; do
    [[ -L "$link" ]] || continue
    points_into_kit "$link" || continue
    name="$(basename "$link")"
    if (( REMOVE )); then
      rm "$link"; echo "  ${YELLOW}-${RESET} removed ${link/#$HOME/~}"
      fixed=$((fixed+1))
    elif [[ ! -e "$KIT_DIR/skills/$name" && ! -e "$KIT_DIR/agents/$name" ]]; then
      if (( CHECK )); then
        echo "  ${RED}✗${RESET} ${link/#$HOME/~}: stale kit link (item no longer in the kit)"
        problems=$((problems+1))
      else
        rm "$link"; echo "  ${YELLOW}-${RESET} pruned stale link ${link/#$HOME/~}"
        fixed=$((fixed+1))
      fi
    fi
  done
}

for home in "${HOMES[@]}"; do
  echo "Home: $home"
  if (( REMOVE )); then
    prune_stale "$home"
    continue
  fi
  for skill_dir in "$KIT_DIR"/skills/sdd-*/; do
    [[ -d "$skill_dir" ]] || continue
    name="$(basename "$skill_dir")"
    ensure_item_link "$home/skills/$name" "$(item_target skills "$name")" "skills/$name"
  done
  for agent in "$KIT_DIR"/agents/*.md; do
    [[ -f "$agent" ]] || continue
    b="$(basename "$agent")"
    ensure_item_link "$home/agents/$b" "$(item_target agents "$b")" "agents/$b"
  done
  prune_stale "$home"
done

echo "---"
if (( REMOVE )); then
  echo "removed: $fixed kit link(s). The clone itself, ~/.sdd, and any ~/.codex|~/.copilot adapters remain — delete those by hand if uninstalling for good."
  exit 0
fi
if (( CHECK )); then
  if (( problems == 0 )); then
    echo "${GREEN}wired${RESET} — every home links to the kit"
    exit 0
  fi
  echo "${RED}$problems problem(s)${RESET} — run scripts/sync.sh to repair"
  exit 1
fi
echo "linked/repaired: $fixed"
