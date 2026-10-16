#!/usr/bin/env bash
# User-authorized (session 13, 2026-10-02) removal of ONE regenerable cargo build cache before the round-14 floor:
# ~/projects/memvault.worktrees/010-b-local-first-web-client/target. Refuses if a cargo or rustc process runs or a
# process holds a file under it. Touches nothing else. Usage: bash <this>
set -uo pipefail
d="$HOME/projects/memvault.worktrees/010-b-local-first-web-client/target"
echo "taken=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
[[ -d "$d" && ! -L "$d" ]] || { echo "refusing: $d is not a plain directory"; exit 2; }
[[ -f "$d/CACHEDIR.TAG" ]] && echo "CACHEDIR.TAG present" || echo "no CACHEDIR.TAG (cargo target layout checked below)"
ls "$d" | head -5
echo "free before: $(df -k / | awk 'NR==2{printf "%.2fGiB",$4/1048576}')  size: $(du -sh "$d" | cut -f1)"
if pgrep -x cargo >/dev/null || pgrep -x rustc >/dev/null || pgrep -f 'cargo-' >/dev/null; then echo "refusing: a cargo or rustc process is running"; pgrep -lf 'cargo|rustc' | head; exit 3; fi
holders="$(lsof -n 2>/dev/null | awk -v d="$d/" 'index($0, d) {print $1, $2}' | sort -u)"
[[ -z "$holders" ]] || { echo "refusing: processes hold files under it:"; printf '%s\n' "$holders"; exit 4; }
rm -rf "$d"; rc=$?
echo "rm rc=$rc; exists after: $([[ -e "$d" ]] && echo yes || echo no)"
echo "free after: $(df -k / | awk 'NR==2{printf "%.2fGiB",$4/1048576}')"
exit "$rc"
