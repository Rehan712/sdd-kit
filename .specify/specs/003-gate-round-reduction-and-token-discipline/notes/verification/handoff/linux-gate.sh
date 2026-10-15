#!/usr/bin/env bash
# Fixed Linux executor for current proof, floor, reservations and report completion.
# The existing spec worktree is bind-mounted at its original absolute path.
exec docker exec sdd003-gates-20260909 /bin/bash "$@"
