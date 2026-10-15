#!/usr/bin/env bash
# Session 4, 2026-09-24: prove the rebuilt pre-session-4 files byte-exact.
# Usage (from the worktree root): bash t030o41-s4-pre-verify.sh <dir holding cur/ and pre/>
# The previous session's copy no longer exists, so the pre-edit versions were
# rebuilt by reversing this session's literal edits (pre/). This script puts
# them in place for ONE read-only vf_snapshot, which must reproduce the handoff
# source and Decisions digests, then restores the current files (cur/) and
# cmp-checks every one. No suite, test function or gate write runs.
set -uo pipefail
D="$1"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
want() { grep -E "^$1=" "$r/t030o41-handoff-state-3.txt" | cut -d= -f2; }
fails=0
chk() { local label="$1"; shift; if "$@"; then printf 'PASS %s\n' "$label"; else printf 'FAIL %s\n' "$label"; fails=$((fails+1)); fi; }
state() { GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall -z | shasum -a 256 | cut -d' ' -f1; }
ident() { # -> "<source> <decisions>" from a fresh shell sourcing the library on disk
  bash -c 'HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
    t="$(mktemp -d "${TMPDIR:-/tmp}/s4-pre.XXXXXX")" || exit 3
    src="$(vf_snapshot "$1" "$PWD" "$PWD" "$t/inputs.nul")" || { rm -rf "$t"; exit 3; }
    vf_semantic_file "$1/STATUS.md" "$1/STATUS.md" "$t/decisions" || { rm -rf "$t"; exit 3; }
    printf "%s %s\n" "$src" "$(vf_hash "$t/decisions")"; rm -rf "$t"' _ "$s"
}
files="$(cd "$D/cur" && find . -type f | sed 's|^\./||' | LC_ALL=C sort)"
S0="$(state)"; printf 'worktree porcelain digest before: %s\n' "$S0"
for f in $files; do chk "live $f equals cur/ before the swap" cmp -s "$f" "$D/cur/$f"; done
(( fails == 0 )) || { echo 'live tree differs from cur/; nothing swapped'; exit 1; }
post_before="$(ident)"; printf 'post identity before the swap: %s\n' "$post_before"
for f in $files; do cp -p "$D/pre/$f" "$f" || { echo "FAIL swap-in $f"; fails=$((fails+1)); }; done
pre="$(ident)"; rc=$?
for f in $files; do cp -p "$D/cur/$f" "$f" || { echo "FAIL restore $f"; fails=$((fails+1)); }; done
printf 'pre identity (rc=%s): %s\n' "$rc" "$pre"
chk "pre source == handoff source $(want source)" test "${pre%% *}" == "$(want source)"
chk "pre Decisions == handoff Decisions $(want decisions)" test "${pre##* }" == "$(want decisions)"
for f in $files; do chk "live $f restored byte-identical" cmp -s "$f" "$D/cur/$f"; done
post_after="$(ident)"; printf 'post identity after the restore: %s\n' "$post_after"
chk 'post identity unchanged by the swap' test "$post_before" == "$post_after"
S1="$(state)"; printf 'worktree porcelain digest after: %s\n' "$S1"
chk 'worktree status unchanged' test "$S0" == "$S1"
printf 'pre-verify failures=%s\n' "$fails"
(( fails == 0 ))
