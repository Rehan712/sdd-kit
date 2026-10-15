#!/usr/bin/env bash
# Session-18 end state: the round-16 repair batch and the round-17 waiver written; T030o48, T030o49 and T030o50
# applied, proven and accepted; Decisions frozen at b5c78e14...; the round-17 floor sealed or not (read its receipt);
# round 17 NOT reserved. Read-only. Pattern: r19-handoff-state.sh. Run from the worktree root with bash, never sourced
# into zsh.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/h20.XXXXXX")"; trap 'rm -rf "$t"' EXIT
meta() { tr '\0' '\n' < "$1" | grep -A1 -x "$2" | tail -1; }
printf 'taken=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"; printf 'source=%s\n' "$src"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/dec"; printf 'decisions=%s\n' "$(vf_hash "$t/dec")"
printf 'head=%s\n' "$(git rev-parse --short HEAD)"
printf 'lock=%s\n' "$([[ -e "$s/notes/verification/lock" ]] && echo HELD || echo absent)"
pending=0; for l in "$s"/notes/verification/rounds/*/ROUND-*; do [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
printf 'pending_reservations=%s\n' "$pending"
printf 'opponent_rounds_sealed=%s round16_digest=%s round17_digest=%s\n' "$(ls -d "$s"/notes/verification/rounds/opponent/ROUND-* | wc -l | tr -d ' ')" "$(cat "$s/notes/verification/rounds/opponent/ROUND-16/report.sha256" 2>/dev/null)" "$(cat "$s/notes/verification/rounds/opponent/ROUND-17/report.sha256" 2>/dev/null)"
fl="$(cat "$s/notes/verification/floor-latest")"
printf 'floor_latest=%s floor_source=%s (current only if equal to source)\n' "$fl" "$(meta "$s/notes/verification/floors/$fl/meta.nul" source)"
printf 'captures=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
printf 'ticked: T030o47=%s T030o48=%s T030o49=%s T030o50=%s T030=%s\n' "$(grep -c -F -- '- [x] **T030o47**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o48**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o49**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o50**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030**' "$s/tasks.md")"
printf 'repair_files=%s\n' "$(shasum -a 256 -c "$r/r17-edits/post-apply-2.sha256" 2>&1 | grep -c ': OK$') of 4 hash as r17-edits/post-apply-2"
bash scripts/spec-gate.sh waiver "$s" opponent 17 > "$t/w17" 2>&1; printf 'round17_waiver_rc=%s %s\n' "$?" "$(head -1 "$t/w17")"
bash scripts/spec-gate.sh waiver "$s" opponent 18 > /dev/null 2>&1; printf 'round18_waiver_rc=%s\n' "$?"
bash scripts/sdd-analyze.sh "$s" > "$t/an" 2>&1; printf 'analyzer_rc=%s %s\n' "$?" "$(tail -1 "$t/an")"
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; printf 'tally_rc=%s %s\n' "$?" "$(grep -E '^(opponent rounds|blocking)=' "$t/tally" | tr '\n' ' ')"
printf 'free=%s power=%s\n' "$(df -h / | awk 'NR==2{print $4}')" "$(pmset -g batt | head -1 | sed "s/.*'\(.*\)'.*/\1/")"
printf 'swap=%s\n' "$(sysctl -n vm.swapusage)"
printf 'receipts:'; for x in r20-entry-state r17-decisions-1-scratch r17-decisions-1-live r17-apply-1 r17-dev1-full r17-dev1-full-locale r17-discover-a r17-discover-b r17-fixtures-judge-2-0 r17-fixtures-judge-2-1 r17-apply-2 r17-dev2-full r17-dev2-full-locale r17-mutations-dry r17-mutations-probe r17-mutations-shard0 r17-mutations-shard1 r17-mutations-shard2 r17-decisions-2-scratch r17-decisions-2-live r17-freeze r17-capture r17-return-T030o48 r17-return-T030o49 r17-return-T030o50 T030o48-accept T030o49-accept T030o50-accept r17-postaccept r17-floor-1 r17-floor-1.wrapper r17-floor-validate r17-scope; do printf ' %s.rc=%s' "$x" "$(cat "$r/$x.rc" 2>/dev/null || echo MISSING)"; done; printf '\n'
