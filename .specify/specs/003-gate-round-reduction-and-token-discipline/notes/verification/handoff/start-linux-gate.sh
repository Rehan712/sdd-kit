#!/usr/bin/env bash
# Resume-only helper. Run from the guarded spec worktree after user resumption.
set -euo pipefail
[[ "$(git rev-parse --abbrev-ref HEAD)" == spec/003-gate-round-reduction-and-token-discipline ]]
docker run -d --rm --network none --name sdd003-gates-20260909 --hostname 500b8caafec8 --user 501:20 \
  --tmpfs /tmp:rw,exec,size=1073741824 -e HOME=/tmp/sdd003-home \
  -v /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline:/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline \
  -v /Users/babar/projects/sdd-kit-public/.git:/Users/babar/projects/sdd-kit-public/.git:ro \
  -w /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline \
  sdd-spec003-verification:local -c 'mkdir -p "$HOME/.sdd" && ln -s "$PWD/agents" "$HOME/.sdd/agents" && exec tail -f /dev/null'
