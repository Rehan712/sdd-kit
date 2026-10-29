#!/usr/bin/env bash
# Session-21 end state: FLOOR-OgYGoP sealed and current for the frozen source; opponent round 18 reserved, run and
# completed (CHALLENGED, digest aeb8c870...); round 18's outcome NOT yet in Decisions (frozen by r18-decisions-2), so
# round 19 stays refused at exit 4; the repair choices wait for the user. Read-only. Pattern: r22-handoff-state.sh.
# Run from the worktree root with bash, never sourced into zsh.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/h23.XXXXXX")"; trap 'rm -rf "$t"' EXIT
meta() { tr '\0' '\n' < "$1" | grep -A1 -x "$2" | tail -1; }
printf 'taken=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"; printf 'source=%s\n' "$src"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/dec"; printf 'decisions=%s\n' "$(vf_hash "$t/dec")"
printf 'head=%s\n' "$(git rev-parse --short HEAD)"
printf 'lock=%s\n' "$([[ -e "$s/notes/verification/lock" ]] && echo HELD || echo absent)"
pending=0; for l in "$s"/notes/verification/rounds/*/ROUND-*; do [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
printf 'pending_reservations=%s\n' "$pending"
printf 'opponent_rounds_sealed=%s round18_digest=%s round19_reserved=%s\n' "$(ls -d "$s"/notes/verification/rounds/opponent/ROUND-* | wc -l | tr -d ' ')" "$(cat "$s/notes/verification/rounds/opponent/ROUND-18/report.sha256" 2>/dev/null)" "$([[ -d "$s/notes/verification/rounds/opponent/ROUND-19" ]] && echo yes || echo no)"
fl="$(cat "$s/notes/verification/floor-latest")"
printf 'floor_latest=%s floor_source=%s (current only if equal to source)\n' "$fl" "$(meta "$s/notes/verification/floors/$fl/meta.nul" source)"
printf 'captures=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
printf 'ticked: T030o50=%s T030o51=%s T030o52=%s T030o53=%s T030=%s\n' "$(grep -c -F -- '- [x] **T030o50**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o51**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o52**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o53**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030**' "$s/tasks.md")"
printf 'unticked_blocks: %s\n' "$(grep -c -E -- '^- \[ \] \*\*T030o5[123]\*\* ' "$s/tasks.md")"
printf 'freeze_point: %s\n' "$(grep -E '^(source|decisions)=' "$r/r18-freeze.txt" | tr '\n' ' ')"
printf 'repair_files=%s\n' "$(shasum -a 256 -c "$r/r18-edits/post-apply-3.sha256" 2>&1 | grep -c ': OK$') of 4 hash as r18-edits/post-apply-3"
bash scripts/spec-gate.sh waiver "$s" opponent 18 > "$t/w18" 2>&1; printf 'round18_waiver_rc=%s %s\n' "$?" "$(head -1 "$t/w18")"
bash scripts/spec-gate.sh waiver "$s" opponent 19 > /dev/null 2>&1; printf 'round19_waiver_rc=%s\n' "$?"
bash scripts/sdd-analyze.sh "$s" > "$t/an" 2>&1; printf 'analyzer_rc=%s %s\n' "$?" "$(tail -1 "$t/an")"
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; printf 'tally_rc=%s %s\n' "$?" "$(grep -E '^(opponent rounds|blocking)=' "$t/tally" | tr '\n' ' ')"
printf 'free=%s power=%s\n' "$(df -h / | awk 'NR==2{print $4}')" "$(pmset -g batt | head -1 | sed "s/.*'\(.*\)'.*/\1/")"
printf 'swap=%s\n' "$(sysctl -n vm.swapusage)"
printf 'receipts:'; for x in r23-entry-state r18-floor-1 r18-floor-1.wrapper r18-floor-validate r18-scope r18-state-prereserve r18-reserve r18-state-reserved r18-brief-fill r18-persist r18-state-returned r18-complete r18-tally r18-final-audit r19-repro; do printf ' %s.rc=%s' "$x" "$(cat "$r/$x.rc" 2>/dev/null || echo MISSING)"; done; printf '\n'
