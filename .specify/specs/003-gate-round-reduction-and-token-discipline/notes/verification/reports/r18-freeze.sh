#!/usr/bin/env bash
# T030o51, T030o52 and T030o53 freeze point, 2026-10-13 (session 20): the state from which the capture, acceptance,
# floor and round 18 must not move Decisions. Read-only. Run from the worktree root with bash. Pattern: r17-freeze.sh.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/r18-freeze.XXXXXX")"; trap 'rm -rf "$t"' EXIT
printf 'taken=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'source=%s\n' "$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/dec"; printf 'decisions=%s\n' "$(vf_hash "$t/dec")"
printf 'head=%s\n' "$(git rev-parse --short HEAD)"
bash scripts/sdd-analyze.sh "$s" > "$t/an" 2>&1; printf 'analyzer rc=%s %s\n' "$?" "$(tail -1 "$t/an")"
bash scripts/spec-gate.sh waiver "$s" opponent 18 > "$t/w" 2>&1; printf 'round18_waiver_rc=%s %s\n' "$?" "$(cat "$t/w")"
bash scripts/spec-gate.sh waiver "$s" opponent 19 > "$t/w" 2>&1; printf 'round19_waiver_rc=%s\n' "$?"
printf 'lock=%s\n' "$([[ -e "$s/notes/verification/lock" ]] && echo HELD || echo absent)"
for k in T030o51 T030o52 T030o53; do printf '%s=%s unticked\n' "$k" "$(grep -c -F -- "- [ ] **$k**" "$s/tasks.md")"; done
printf 'captures=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
printf 'repair_files=%s\n' "$(shasum -a 256 -c "$r/r18-edits/post-apply-3.sha256" 2>&1 | grep -c ': OK$') of 4 hash as r18-edits/post-apply-3"
