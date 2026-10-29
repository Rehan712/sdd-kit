#!/usr/bin/env bash
# T030o44 freeze point, 2026-10-02 (session 13): the state from which the capture, acceptance, floor and round 14
# must not move Decisions. Read-only. Run from the worktree root with bash. Pattern: t030o43-freeze.sh.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/t030o44-freeze.XXXXXX")"; trap 'rm -rf "$t"' EXIT
printf 'taken=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'source=%s\n' "$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/dec"; printf 'decisions=%s\n' "$(vf_hash "$t/dec")"
printf 'head=%s\n' "$(git rev-parse --short HEAD)"
bash scripts/sdd-analyze.sh "$s" > "$t/an" 2>&1; printf 'analyzer rc=%s %s\n' "$?" "$(tail -1 "$t/an")"
bash scripts/spec-gate.sh waiver "$s" opponent 14 > "$t/w" 2>&1; printf 'round14_waiver_rc=%s %s\n' "$?" "$(cat "$t/w")"
bash scripts/spec-gate.sh waiver "$s" opponent 15 > "$t/w" 2>&1; printf 'round15_waiver_rc=%s\n' "$?"
printf 'lock=%s\n' "$([[ -e "$s/notes/verification/lock" ]] && echo HELD || echo absent)"
printf 'T030o44=%s\n' "$(grep -c -F -- '- [ ] **T030o44**' "$s/tasks.md") unticked"
printf 'captures=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
printf 'repair_files=%s\n' "$(shasum -a 256 -c "$r/t030o44-edits/post-apply-6.sha256" 2>&1 | grep -c ': OK$') of 4 hash as post-apply-6"
