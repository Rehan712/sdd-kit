#!/usr/bin/env bash
# User-authorized reclaim before the round-13 floor, 2026-09-30 (session 10): "Remove cdk.out*"
# (only $TMPDIR/cdk.out*: another project's CDK synth output, 546 directories, 9.75 GB, last
# written 11:31Z). Pattern: r13-disk-reclaim.sh part 1. Refuses when a cdk or synth-like process
# runs; skips a directory any process holds or anything in which changed within the last hour.
# Nothing else is touched.
set -uo pipefail
T=/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T
say() { printf '%s %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }
free() { df -k / | awk 'NR==2{printf "%.2fGiB", $4/1048576}'; }
say "free before: $(free)"
if pgrep -f 'cdk (synth|deploy|diff)|cdk\.out|jest|vitest|ts-node' >/dev/null; then say 'refused: a cdk, synth or test process runs'; pgrep -fl 'cdk (synth|deploy|diff)|cdk\.out|jest|vitest|ts-node' | cut -c1-160; exit 3; fi
held="$(lsof -Fn 2>/dev/null | grep -c "^n$T/cdk\.out")"
say "open files under $T/cdk.out*: $held"
(( held == 0 )) || { say 'refused: a process holds files there'; exit 3; }
n=0; skipped=0
for d in "$T"/cdk.out*; do
  [[ -d "$d" ]] || continue
  if find "$d" -mmin -60 -print -quit | grep -q .; then skipped=$((skipped+1)); continue; fi
  rm -rf -- "$d" && n=$((n+1))
done
say "removed $n cdk.out directories; skipped $skipped changed within the hour"
say "left: $(ls -d "$T"/cdk.out* 2>/dev/null | wc -l | tr -d ' ')"
say "free after: $(free)"
