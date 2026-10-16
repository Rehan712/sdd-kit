#!/usr/bin/env bash
# The user's authorization, 2026-09-25: remove regenerable caches (cargo
# target/, cdk.out) to free disk for the fresh floor. Removes only: cargo
# target dirs that carry CACHEDIR.TAG and that no process holds open, and
# $TMPDIR/cdk.out* synth outputs. sales-platform/target is excluded (the Docker
# VM and a running test binary hold files in it). Receipts: t030o41-disk-reclaim.{log,rc}.
set -uo pipefail
r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
log="$r/t030o41-disk-reclaim.log"; : > "$log"
avail() { df -k / | awk 'NR==2{printf "%.2f", $4/1048576}'; }
say() { printf '%s\n' "$*" | tee -a "$log"; }
say "start=$(date -u +%Y-%m-%dT%H:%M:%SZ) avail_before=$(avail)GiB"
if pgrep -fl 'cargo|rustc|cdk (synth|deploy|diff)' >> "$log"; then say "REFUSED: a cargo/rustc/cdk process is running"; echo 2 > "$r/t030o41-disk-reclaim.rc"; exit 2; fi
openfiles="$(lsof -n 2>/dev/null | awk '{print $NF}')"
rc=0
for d in "$HOME/projects/memvault.worktrees/010-b-local-first-web-client/target" "$HOME/projects/memvault/target"; do
  if [[ ! -f "$d/CACHEDIR.TAG" ]]; then say "SKIP (no CACHEDIR.TAG): $d"; continue; fi
  if grep -qF "$d/" <<<"$openfiles"; then say "SKIP (held open): $d"; continue; fi
  kb="$(du -sk "$d" | cut -f1)"
  if rm -rf -- "$d"; then say "removed $(awk -v k="$kb" 'BEGIN{printf "%.2f", k/1048576}')GiB $d"; else say "FAILED rm: $d"; rc=1; fi
done
tmp="${TMPDIR%/}"
case "$tmp" in /var/folders/*/T) ;; *) say "REFUSED: unexpected TMPDIR=$tmp"; echo 3 > "$r/t030o41-disk-reclaim.rc"; exit 3;; esac
n=0; kb="$(du -sk "$tmp"/cdk.out* 2>/dev/null | awk '{s+=$1} END {print s+0}')"
for d in "$tmp"/cdk.out*; do
  [[ -d "$d" ]] || continue
  if grep -qF "$d/" <<<"$openfiles"; then say "SKIP (held open): $d"; continue; fi
  rm -rf -- "$d" && n=$((n+1)) || { say "FAILED rm: $d"; rc=1; }
done
say "removed $n cdk.out dirs (~$(awk -v k="$kb" 'BEGIN{printf "%.2f", k/1048576}')GiB) under $tmp"
say "end=$(date -u +%Y-%m-%dT%H:%M:%SZ) avail_after=$(avail)GiB swap_used=$(sysctl -n vm.swapusage | awk '{print $6}')"
echo "$rc" > "$r/t030o41-disk-reclaim.rc"; exit "$rc"
