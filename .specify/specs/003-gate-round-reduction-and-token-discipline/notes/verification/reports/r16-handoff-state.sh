#!/usr/bin/env bash
# Session-15 handoff state: round 15 consumed (CHALLENGED); under the user's standing instruction the T030o47 repair of O-018 is reproduced, measured and its fixtures judged, and round 16 is covered by that instruction, but NOTHING is written to Decisions or code (pattern: r15-handoff-state.sh). Read-only.
# Run from the worktree root with bash, never sourced into zsh.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/h14.XXXXXX")"; trap 'rm -rf "$t"' EXIT
printf 'taken=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'source=%s\n' "$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/dec"; printf 'decisions=%s\n' "$(vf_hash "$t/dec")"
printf 'head=%s\n' "$(git rev-parse --short HEAD)"
printf 'lock=%s\n' "$([[ -e "$s/notes/verification/lock" ]] && echo HELD || echo absent)"
pending=0; for l in "$s"/notes/verification/rounds/*/ROUND-*; do [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
printf 'pending_reservations=%s\n' "$pending"
printf 'opponent_rounds_sealed=%s round15_digest=%s\n' "$(ls -d "$s"/notes/verification/rounds/opponent/ROUND-* | wc -l | tr -d ' ')" "$(cat "$s/notes/verification/rounds/opponent/ROUND-15/report.sha256" 2>/dev/null)"
printf 'floor_latest=%s\n' "$(cat "$s/notes/verification/floor-latest")"
printf 'captures=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
printf 'T030o45=%s T030o46=%s ticked, T030o47 present=%s, T030=%s ticked\n' "$(grep -c -F -- '- [x] **T030o45**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o46**' "$s/tasks.md")" "$(grep -c -F -- '**T030o47**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030**' "$s/tasks.md")"
printf 'repair_files=%s\n' "$(shasum -a 256 -c "$r/r14-edits/post-apply-2.sha256" 2>&1 | grep -c ': OK$') of 4 hash as r14-edits/post-apply-2 (T030o45, T030o46)"
bash scripts/spec-gate.sh waiver "$s" opponent 15 > "$t/w15" 2>&1; printf 'round15_waiver_rc=%s %s\n' "$?" "$(head -1 "$t/w15")"
bash scripts/spec-gate.sh waiver "$s" opponent 16 > /dev/null 2>&1; printf 'round16_waiver_rc=%s\n' "$?"
bash scripts/sdd-analyze.sh "$s" > "$t/an" 2>&1; printf 'analyzer_rc=%s %s\n' "$?" "$(tail -1 "$t/an")"
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; printf 'tally_rc=%s %s\n' "$?" "$(grep -E '^(opponent rounds|blocking)=' "$t/tally" | tr '\n' ' ')"
printf 'free=%s power=%s\n' "$(df -h / | awk 'NR==2{print $4}')" "$(pmset -g batt | head -1 | sed "s/.*'\(.*\)'.*/\1/")"
printf 'swap=%s\n' "$(sysctl -n vm.swapusage)"
printf 'unrepaired_files=%s\n' "$(shasum -a 256 -c "$r/r15-edits/pre-apply.sha256" 2>&1 | grep -c ': OK$') of 4 hash as r15-edits/pre-apply (the T030o47 repair is not applied)"
printf 'receipts: r15-repro.rc=%s r15-measure.rc=%s r15-fixtures-judge.rc=%s r15-final-audit.rc=%s\n' "$(cat "$r/r15-repro.rc")" "$(cat "$r/r15-measure.rc")" "$(cat "$r/r15-fixtures-judge.rc")" "$(cat "$r/r15-final-audit.rc")"
printf 'prepared (sha256, 16): '; for f in r15-edits/kernel-1.pairs r15-edits/vc-1.pairs r15-edits/tgc-1.pairs r15-edits/tsg-1.pairs r15-decisions-1.md r15-task-block.md r15-mutations.sh; do printf '%s=%s ' "$f" "$(shasum -a 256 "$r/$f" | cut -c1-16)"; done; printf '\n'
