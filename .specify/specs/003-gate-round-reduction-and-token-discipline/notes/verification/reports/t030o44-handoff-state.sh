#!/usr/bin/env bash
# Session-12 handoff state, T030o44 in progress (pattern: r13-handoff-state.sh). Read-only.
# Run from the worktree root with bash, never sourced into zsh. No floor is current (the source moved on purpose).
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/h44.XXXXXX")"; trap 'rm -rf "$t"' EXIT
printf 'taken=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'source=%s\n' "$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/dec"; printf 'decisions=%s\n' "$(vf_hash "$t/dec")"
printf 'head=%s\n' "$(git rev-parse --short HEAD)"
printf 'lock=%s\n' "$([[ -e "$s/notes/verification/lock" ]] && echo HELD || echo absent)"
pending=0; for l in "$s"/notes/verification/rounds/*/ROUND-*; do [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
printf 'pending_reservations=%s\n' "$pending"
printf 'opponent_rounds_sealed=%s round13_digest=%s\n' "$(ls -d "$s"/notes/verification/rounds/opponent/ROUND-* | wc -l | tr -d ' ')" "$(cat "$s/notes/verification/rounds/opponent/ROUND-13/report.sha256")"
printf 'floor_latest=%s\n' "$(cat "$s/notes/verification/floor-latest")"
printf 'captures=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
printf 'T030o44=%s unticked, T030o43=%s ticked, T030=%s ticked\n' "$(grep -c -F -- '- [ ] **T030o44**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o43**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030**' "$s/tasks.md")"
printf 'repair_files=%s\n' "$(shasum -a 256 -c "$r/t030o44-edits/post-apply-2.sha256" 2>&1 | grep -c ': OK$') of 4 hash as post-apply-2"
bash scripts/spec-gate.sh waiver "$s" opponent 14 > "$t/w14" 2>&1; printf 'round14_waiver_rc=%s %s\n' "$?" "$(head -1 "$t/w14")"
bash scripts/spec-gate.sh waiver "$s" opponent 15 > /dev/null 2>&1; printf 'round15_waiver_rc=%s\n' "$?"
bash scripts/sdd-analyze.sh "$s" > "$t/an" 2>&1; printf 'analyzer_rc=%s %s\n' "$?" "$(tail -1 "$t/an")"
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; printf 'tally_rc=%s %s\n' "$?" "$(grep -E '^(opponent rounds|blocking)=' "$t/tally" | tr '\n' ' ')"
printf 'free=%s power=%s\n' "$(df -h / | awk 'NR==2{print $4}')" "$(pmset -g batt | head -1 | sed "s/.*'\(.*\)'.*/\1/")"
printf 'swap=%s\n' "$(sysctl -n vm.swapusage)"
