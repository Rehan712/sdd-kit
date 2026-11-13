#!/usr/bin/env bash
# install.sh — install or update the SDD kit from its plugin.
#
# A plugin folder is replaced on every plugin update, so the kit cannot live in
# it: the kit's hub holds this machine's registry, model policy and repo
# briefs. This script puts the hub where it survives — a git clone — and hands
# over to the kit's own scripts/setup.sh, which does the actual install.
#
#   no install yet          clone the kit to ~/.sdd-kit, then run its setup.sh
#   ~/.sdd already linked   fast-forward that clone, then re-run its setup.sh
#
# Safe to re-run. It never deletes or re-points an existing install: a clone it
# cannot fast-forward (local commits, no upstream, offline) is left as it is
# and set up at the version it has.
#
# Usage: install.sh [setup.sh flags, e.g. --no-wizard --no-cli]
# Env:   SDD_KIT_DIR   where a first install is cloned (default ~/.sdd-kit)
#        SDD_KIT_REPO  what a first install clones (default: the public kit)

set -euo pipefail

REPO="${SDD_KIT_REPO:-https://github.com/Rehan712/sdd-kit.git}"
DEST="${SDD_KIT_DIR:-$HOME/.sdd-kit}"

command -v git >/dev/null 2>&1 || { echo "sdd-kit: git is required" >&2; exit 1; }

fresh=0
if [[ -L "$HOME/.sdd" ]] && kit="$(cd -P -- "$HOME/.sdd" 2>/dev/null && pwd -P)"; then
  echo "SDD kit already installed at $kit — updating"
elif [[ -e "$HOME/.sdd" ]]; then
  echo "sdd-kit: ~/.sdd exists and is not a symlink — move it aside and re-run" >&2
  exit 1
else
  # No install, or a dangling ~/.sdd (setup.sh repairs that link itself).
  kit="$DEST"
  if [[ ! -e "$kit" ]]; then
    # Cloned beside the destination and moved into place: a clone killed
    # half-way must not leave a ~/.sdd-kit the check below refuses forever.
    rm -rf "$kit.cloning"
    git clone "$REPO" "$kit.cloning"
    mv "$kit.cloning" "$kit"
    fresh=1
  elif [[ ! -f "$kit/scripts/setup.sh" ]]; then
    echo "sdd-kit: $kit exists and is not an SDD kit clone — set SDD_KIT_DIR to another path" >&2
    exit 1
  fi
fi

if (( ! fresh )) && [[ -e "$kit/.git" ]]; then
  git -C "$kit" pull --ff-only \
    || echo "sdd-kit: could not fast-forward $kit — setting up the version it has" >&2
fi

exec bash "$kit/scripts/setup.sh" "$@"
