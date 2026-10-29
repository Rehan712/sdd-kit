#!/usr/bin/env bash
# User-authorized disk reclaim before the round-11 floor, 2026-09-26 (AskUserQuestion answer:
# "Reclaim dev caches"). Regenerable caches only, each removed only if no process holds it,
# re-checked immediately before removal (a point-in-time check does not stay true, 2026-09-18):
#   ~/Library/Caches/ms-playwright   (browsers; `npx playwright install` restores)
#   ~/.cargo/registry/{cache,src}    (crates; the next cargo build re-downloads; index kept)
#   npm cache clean --force          (~/.npm/_cacache)
#   pnpm store prune                 (unreferenced packages only)
# Nothing in any repository, Docker, sales-platform/target or vm_bundles is touched.
# Usage: bash <this>  (writes nothing itself; the caller redirects to .log and writes .rc)
set -uo pipefail
fails=0
avail() { df -k / | awk 'NR==2{printf "%.2fGiB",$4/1048576}'; }
held() {  # $1 dir; prints holders and returns 0 when anything holds it
  local d="$1" out
  out="$(lsof +D "$d" 2>/dev/null | awk 'NR>1{print $1"("$2")"}' | sort -u | tr '\n' ' ')"
  [[ -n "$out" ]] && { printf '  held by: %s\n' "$out"; return 0; }
  return 1
}
busy() { pgrep -fl "$1" 2>/dev/null | head -3; }
printf 'start=%s avail=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(avail)"

rmcache() {  # $1 label, $2 dir, $3 process pattern
  local label="$1" d="$2" pat="$3" before
  [[ -d "$d" ]] || { printf 'SKIP %s: %s absent\n' "$label" "$d"; return 0; }
  before="$(du -sk "$d" | awk '{printf "%.2fGiB",$1/1048576}')"
  if [[ -n "$(busy "$pat")" ]]; then printf 'SKIP %s: process running:\n%s\n' "$label" "$(busy "$pat")"; fails=$((fails+1)); return 0; fi
  if held "$d"; then printf 'SKIP %s: open files\n' "$label"; fails=$((fails+1)); return 0; fi
  rm -rf -- "$d"; local rc=$?
  if [[ -e "$d" ]]; then printf 'FAIL %s: %s still present after rm (rc=%s)\n' "$label" "$d" "$rc"; fails=$((fails+1))
  else printf 'DONE %s: removed %s (%s) avail=%s\n' "$label" "$d" "$before" "$(avail)"; fi
}
rmcache ms-playwright "$HOME/Library/Caches/ms-playwright" 'ms-playwright'
rmcache cargo-registry-cache "$HOME/.cargo/registry/cache" '(^|/)(cargo|rustc)( |$)'
rmcache cargo-registry-src "$HOME/.cargo/registry/src" '(^|/)(cargo|rustc)( |$)'

if [[ -n "$(busy '(^|/)npm( |$)|npm-cli')" ]]; then printf 'SKIP npm cache: npm running\n'; fails=$((fails+1))
else
  b="$(du -sk "$HOME/.npm" 2>/dev/null | awk '{printf "%.2fGiB",$1/1048576}')"
  npm cache clean --force 2>&1 | sed 's/^/  npm| /'; rc=${PIPESTATUS[0]}
  a="$(du -sk "$HOME/.npm" 2>/dev/null | awk '{printf "%.2fGiB",$1/1048576}')"
  if [[ "$rc" == 0 ]]; then printf 'DONE npm cache clean --force: ~/.npm %s -> %s avail=%s\n' "$b" "$a" "$(avail)"
  else printf 'FAIL npm cache clean rc=%s\n' "$rc"; fails=$((fails+1)); fi
fi

if [[ -n "$(busy '(^|/)pnpm( |$)')" ]]; then printf 'SKIP pnpm store prune: pnpm running\n'; fails=$((fails+1))
else
  sp="$(pnpm store path 2>/dev/null)"
  b="$(du -sk "$sp" 2>/dev/null | awk '{printf "%.2fGiB",$1/1048576}')"
  pnpm store prune 2>&1 | tail -5 | sed 's/^/  pnpm| /'; rc=${PIPESTATUS[0]}
  a="$(du -sk "$sp" 2>/dev/null | awk '{printf "%.2fGiB",$1/1048576}')"
  if [[ "$rc" == 0 ]]; then printf 'DONE pnpm store prune: %s %s -> %s avail=%s\n' "$sp" "$b" "$a" "$(avail)"
  else printf 'FAIL pnpm store prune rc=%s\n' "$rc"; fails=$((fails+1)); fi
fi

printf 'end=%s avail=%s failures=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(avail)" "$fails"
(( fails == 0 ))
