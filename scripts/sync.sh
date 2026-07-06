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
#   sync.sh                # create/repair all links
#   sync.sh --check        # verify only; exit 1 if anything is mis-wired
#   sync.sh --home <path>  # limit to one home (repeatable)
#   sync.sh --help

set -euo pipefail

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Prefer the stable ~/.sdd path as the link target when it points at this repo,
# so links survive the clone moving (re-run setup.sh after a move either way).
TARGET_ROOT="$KIT_DIR"
if [[ -L "$HOME/.sdd" && "$(readlink "$HOME/.sdd")" == "$KIT_DIR" ]]; then
  TARGET_ROOT="$HOME/.sdd"
fi

GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'

usage() { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

CHECK=0
HOMES=()

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --check) CHECK=1 ;;
    --home) shift; HOMES+=("${1:?--home needs a path}") ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

if (( ${#HOMES[@]} == 0 )); then
  for d in "$HOME/.claude" "$HOME"/.claude_*; do
    [[ -d "$d" ]] || continue
    case "$(basename "$d")" in
      *.bak|*.backup|*.old|*.orig|*.pre-sync.*) continue ;;
    esac
    HOMES+=("$d")
  done
fi

if (( ${#HOMES[@]} == 0 )); then
  echo "no Claude homes found (~/.claude or ~/.claude_*) — is Claude Code installed?" >&2
  exit 1
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
      local bak="$link.pre-sdd.$(date +%Y%m%d%H%M%S)"
      mv "$link" "$bak"
      ln -s "$target" "$link"
      echo "  ${YELLOW}!${RESET} $label: existing copy moved to $(basename "$bak"), linked to kit"
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

for home in "${HOMES[@]}"; do
  echo "Home: $home"
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
done

echo "---"
if (( CHECK )); then
  if (( problems == 0 )); then
    echo "${GREEN}wired${RESET} — every home links to the kit"
    exit 0
  fi
  echo "${RED}$problems problem(s)${RESET} — run scripts/sync.sh to repair"
  exit 1
fi
echo "linked/repaired: $fixed"
