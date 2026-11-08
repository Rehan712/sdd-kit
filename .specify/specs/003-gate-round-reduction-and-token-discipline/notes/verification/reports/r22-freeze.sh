#!/usr/bin/env bash
# T031a4o2 freeze point, 2026-10-16 (session 24): the state from which the capture, acceptance,
# floor and round 22 (and, on CLEARED, any hosted CI run, the T029 control and reality-check round 3) must not move
# Decisions. Read-only. Run from the worktree root with bash. Pattern: r21-freeze.sh.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/r22-freeze.XXXXXX")"; trap 'rm -rf "$t"' EXIT
printf 'taken=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'source=%s\n' "$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/dec"; printf 'decisions=%s\n' "$(vf_hash "$t/dec")"
printf 'head=%s\n' "$(git rev-parse --short HEAD)"
bash scripts/sdd-analyze.sh "$s" > "$t/an" 2>&1; printf 'analyzer rc=%s %s\n' "$?" "$(tail -1 "$t/an")"
bash scripts/spec-gate.sh waiver "$s" opponent 22 > "$t/w" 2>&1; printf 'round22_waiver_rc=%s %s\n' "$?" "$(cat "$t/w")"
bash scripts/spec-gate.sh waiver "$s" opponent 23 > "$t/w" 2>&1; printf 'round23_waiver_rc=%s\n' "$?"
printf 'lock=%s\n' "$([[ -e "$s/notes/verification/lock" ]] && echo HELD || echo absent)"
for k in T031a4o2; do printf '%s=%s unticked\n' "$k" "$(grep -c -F -- "- [ ] **$k**" "$s/tasks.md")"; done
printf 'captures=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
printf 'test_files=%s\n' "$(shasum -a 256 -c "$r/r22-edits/post-apply.sha256" 2>&1 | grep -c ': OK$') of 1 hash as r22-edits/post-apply"
