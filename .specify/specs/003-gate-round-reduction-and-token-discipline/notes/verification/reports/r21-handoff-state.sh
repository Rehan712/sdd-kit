#!/usr/bin/env bash
# Session-19 end state: round 17 consumed and recorded in Decisions with the round-18 waiver; T030o51, T030o52 and
# T030o53 applied live (r18-edits/post-apply-1), NOT accepted; tgc-2 judged with three rows failing, NOT applied; no
# floor current; round 18 authorized and NOT reserved. Read-only. Pattern: r20-handoff-state.sh. Run from the worktree
# root with bash, never sourced into zsh.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/h21.XXXXXX")"; trap 'rm -rf "$t"' EXIT
meta() { tr '\0' '\n' < "$1" | grep -A1 -x "$2" | tail -1; }
printf 'taken=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"; printf 'source=%s\n' "$src"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/dec"; printf 'decisions=%s\n' "$(vf_hash "$t/dec")"
printf 'head=%s\n' "$(git rev-parse --short HEAD)"
printf 'lock=%s\n' "$([[ -e "$s/notes/verification/lock" ]] && echo HELD || echo absent)"
pending=0; for l in "$s"/notes/verification/rounds/*/ROUND-*; do [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
printf 'pending_reservations=%s\n' "$pending"
printf 'opponent_rounds_sealed=%s round17_digest=%s round18_reserved=%s\n' "$(ls -d "$s"/notes/verification/rounds/opponent/ROUND-* | wc -l | tr -d ' ')" "$(cat "$s/notes/verification/rounds/opponent/ROUND-17/report.sha256" 2>/dev/null)" "$([[ -d "$s/notes/verification/rounds/opponent/ROUND-18" ]] && echo yes || echo no)"
fl="$(cat "$s/notes/verification/floor-latest")"
printf 'floor_latest=%s floor_source=%s (current only if equal to source)\n' "$fl" "$(meta "$s/notes/verification/floors/$fl/meta.nul" source)"
printf 'captures=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
printf 'ticked: T030o50=%s T030o51=%s T030o52=%s T030o53=%s T030=%s\n' "$(grep -c -F -- '- [x] **T030o50**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o51**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o52**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030o53**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030**' "$s/tasks.md")"
printf 'unticked_blocks: %s\n' "$(grep -c -E -- '^- \[ \] \*\*T030o5[123]\*\* ' "$s/tasks.md")"
printf 'repair_files=%s\n' "$(shasum -a 256 -c "$r/r18-edits/post-apply-1.sha256" 2>&1 | grep -c ': OK$') of 4 hash as r18-edits/post-apply-1"
bash scripts/spec-gate.sh waiver "$s" opponent 18 > "$t/w18" 2>&1; printf 'round18_waiver_rc=%s %s\n' "$?" "$(head -1 "$t/w18")"
bash scripts/spec-gate.sh waiver "$s" opponent 19 > /dev/null 2>&1; printf 'round19_waiver_rc=%s\n' "$?"
bash scripts/sdd-analyze.sh "$s" > "$t/an" 2>&1; printf 'analyzer_rc=%s %s\n' "$?" "$(tail -1 "$t/an")"
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; printf 'tally_rc=%s %s\n' "$?" "$(grep -E '^(opponent rounds|blocking)=' "$t/tally" | tr '\n' ' ')"
printf 'free=%s power=%s\n' "$(df -h / | awk 'NR==2{print $4}')" "$(pmset -g batt | head -1 | sed "s/.*'\(.*\)'.*/\1/")"
printf 'swap=%s\n' "$(sysctl -n vm.swapusage)"
printf 'receipts:'; for x in r21-entry-state r18-grammar-survey r18-repro r18-measure r18-fixtures-judge r18-decisions-fill r18-decisions-1-scratch r18-decisions-1-live r18-apply-1 r18-dev1-full r18-dev1-full-locale r18-discover-a r18-discover-b r18-discover-c r18-fixtures-judge-2-0 r18-fixtures-judge-2-1 r18-fixtures-judge-2-2; do printf ' %s.rc=%s' "$x" "$(cat "$r/$x.rc" 2>/dev/null || echo MISSING)"; done; printf '\n'
