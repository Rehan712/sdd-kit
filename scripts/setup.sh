#!/usr/bin/env bash
# setup.sh — install the SDD kit on this machine.
#
# What it does (idempotent — safe to re-run after every `git pull`):
#   1. Symlinks ~/.sdd -> this repo clone. Everything else (skills, agents,
#      scripts) is referenced through that stable path, so the clone can live
#      anywhere.
#   2. Bootstraps ./registry.yml (from registry.example.yml) and ./system-map.yml
#      (from system-map.example.yml) if absent — both machine/team-local and
#      gitignored: registry.yml maps YOUR project paths to stack tags, and
#      system-map.yml describes YOUR repo topology (never committed to the kit).
#   3. Bootstraps the model policy (./models.yml): on first install it runs the
#      scripts/configure-models.sh wizard (or writes the example defaults when
#      there's no TTY / --no-wizard). Then scripts/apply-models.sh stamps the
#      configured model + effort into generated skill/agent copies under build/.
#   4. Links every SDD skill and agent into each Claude home (~/.claude and
#      ~/.claude_*), one symlink per item — your other skills/agents are
#      untouched. Runs scripts/sync.sh under the hood.
#   5. If ~/.codex (or any ~/.codex_* profile home) or ~/.copilot exist,
#      generates their adapters from the canonical skills via
#      scripts/build-adapters.sh (model policy applied).
#   6. Runs scripts/sdd-doctor.sh to verify the install.
#
# Usage:
#   scripts/setup.sh              # full install
#   scripts/setup.sh --no-cli     # skip codex/copilot adapters
#   scripts/setup.sh --no-wizard  # first install: take default model policy, don't prompt
#   scripts/setup.sh --help

set -euo pipefail

# pwd -P (physical): invoked via ~/.sdd/scripts/setup.sh, a logical pwd would
# yield KIT_DIR=~/.sdd and step 1's ln would turn ~/.sdd into a self-loop.
KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
. "$KIT_DIR/scripts/lib.sh"

init_colors

usage() { usage_from_header "$0"; exit 0; }

NO_CLI=0
NO_WIZARD=0
for arg in "$@"; do
  case "$arg" in
    --help|-h) usage ;;
    --no-cli) NO_CLI=1 ;;
    --no-wizard) NO_WIZARD=1 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

echo "Installing SDD kit from: $KIT_DIR"

# --- 1. ~/.sdd -> repo ---
if [[ "$KIT_DIR" == "$HOME/.sdd" ]]; then
  echo "  ${RED}✗${RESET} refusing to link ~/.sdd to itself — run setup.sh from the real clone" >&2
  exit 1
fi
if [[ -L "$HOME/.sdd" ]]; then
  ln -sfn "$KIT_DIR" "$HOME/.sdd"
  echo "  ${GREEN}✓${RESET} ~/.sdd -> $KIT_DIR"
elif [[ -e "$HOME/.sdd" ]]; then
  echo "  ${YELLOW}!${RESET} ~/.sdd exists and is not a symlink — move it aside and re-run" >&2
  exit 1
else
  ln -s "$KIT_DIR" "$HOME/.sdd"
  echo "  ${GREEN}✓${RESET} ~/.sdd -> $KIT_DIR"
fi

# --- 2. machine-local registry + system map ---
if [[ ! -f "$KIT_DIR/registry.yml" ]]; then
  cp "$KIT_DIR/registry.example.yml" "$KIT_DIR/registry.yml"
  echo "  ${GREEN}+${RESET} registry.yml created from example — EDIT IT to register your projects"
else
  echo "  ${GREEN}✓${RESET} registry.yml present"
fi

if [[ ! -f "$KIT_DIR/system-map.yml" ]]; then
  cp "$KIT_DIR/system-map.example.yml" "$KIT_DIR/system-map.yml"
  echo "  ${GREEN}+${RESET} system-map.yml created from example — EDIT IT to describe your repos"
else
  echo "  ${GREEN}✓${RESET} system-map.yml present"
fi

# --- 3. model policy (which model runs each SDD phase) ---
if [[ ! -f "$KIT_DIR/models.yml" ]]; then
  if (( NO_WIZARD )) || [[ ! -t 0 ]]; then
    "$KIT_DIR/scripts/configure-models.sh" --defaults --no-sync
  else
    echo
    echo "No model policy yet — pick which models run each SDD phase (Enter = default):"
    "$KIT_DIR/scripts/configure-models.sh" --no-sync
    echo
  fi
else
  echo "  ${GREEN}✓${RESET} models.yml present"
  "$KIT_DIR/scripts/apply-models.sh"
fi

# --- 4. Claude homes ---
"$KIT_DIR/scripts/sync.sh"

# --- 5. Codex / Copilot adapters ---
if (( ! NO_CLI )); then
  "$KIT_DIR/scripts/build-adapters.sh"
fi

# --- 6. verify ---
echo
"$KIT_DIR/scripts/sdd-doctor.sh" --hub-only || true

cat <<EOF

Next steps:
  1. Edit $KIT_DIR/registry.yml — one entry per project you want under SDD.
  2. In each project: mkdir -p .specify/specs and add a .specify/stack.yml
     (see registry.example.yml notes; sdd-doctor.sh <project> will guide you).
  3. From inside a project, run /sdd:specify "<feature>" in Claude Code.

Model policy: scripts/configure-models.sh reconfigures which model runs each
phase (scripts/model-policy.sh show prints the current mapping).
EOF

# Repo briefs: point at /sdd:onboard when governed repos lack standing context.
# Guarded — brief-status.sh is a query script and must never fail the install.
briefs_missing="$("$KIT_DIR/scripts/brief-status.sh" list 2>/dev/null | awk -F'\t' '$5 == "missing"' | wc -l | tr -d ' ' || true)"
if [[ "${briefs_missing:-0}" -gt 0 ]]; then
  echo "Briefs: ${YELLOW}$briefs_missing${RESET} registered repo(s) have no repo brief — run /sdd:onboard"
  echo "in Claude Code to research them and write briefs/<repo>.md."
fi
