#!/usr/bin/env bash
# User-authorized reclaim of regenerable caches before the round-13 floor, 2026-09-27
# ("Yes you can and also remove som regerateable like target or node modules").
# Before each removal: no process of the owning toolchain runs, no process has an open
# file or cwd under the directory, and nothing in it changed in the last hour.
set -uo pipefail
T=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T
say() { printf '%s %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }
free() { df -k / | awk 'NR==2{printf "%.2fGiB", $4/1048576}'; }
say "free before: $(free)"
busy() { # <dir> -> 0 when something uses it
  local d="$1"
  lsof +D "$d" >/dev/null 2>&1 && return 0
  [[ -n "$(find "$d" -newermt '-60 minutes' -print -quit 2>/dev/null)" ]] && return 0
  return 1
}
if [[ "${1:-}" == deps ]]; then skip1=1; else skip1=0; fi
# 1. The kit's own leftover test sandboxes (empty) and CDK synth outputs in TMPDIR.
if (( skip1 )); then say 'part 1 skipped (done in run 1)'; elif pgrep -f 'cdk (synth|deploy|diff)|jest|vitest' >/dev/null; then say 'refused: a cdk or test process runs'; else
  n=0; for d in "$T"/sddkit.* "$T"/vf-*; do [[ -d "$d" ]] || continue; find "$d" -mmin -60 -print -quit | grep -q . && continue; rm -rf -- "$d" && n=$((n+1)); done
  say "removed $n kit sandboxes"
  n=0; for d in "$T"/cdk.out*; do [[ -d "$d" ]] || continue; find "$d" -mmin -60 -print -quit | grep -q . && continue; rm -rf -- "$d" && n=$((n+1)); done
  say "removed $n cdk.out directories; free: $(free)"
fi
# 2. Regenerable dependency and build directories no process is using.
for d in /Users/babar/projects/taxipro/Taxiapp/node_modules /Users/babar/projects/taxipro/gymcoachpro-frontend/node_modules \
         /Users/babar/projects/memvault.worktrees/010-b-local-first-web-client/apps/web/node_modules \
         /Users/babar/projects/memvault.worktrees/010-b-local-first-web-client/target; do
  [[ -d "$d" ]] || { say "absent: $d"; continue; }
  # Exact process names: a -f match also hit a shell whose command line carried the words (run 1).
  if pgrep -x 'cargo|rustc|npm|pnpm|yarn|bun' >/dev/null || pgrep -f '^node .*(expo|metro|next|vite)' >/dev/null; then say "refused (a build process runs): $d"; continue; fi
  if busy "$d"; then say "refused (in use or changed within the hour): $d"; continue; fi
  sz="$(du -sh "$d" 2>/dev/null | cut -f1)"
  rm -rf -- "$d" && say "removed $sz $d" || say "FAILED $d"
done
say "free after: $(free)"
