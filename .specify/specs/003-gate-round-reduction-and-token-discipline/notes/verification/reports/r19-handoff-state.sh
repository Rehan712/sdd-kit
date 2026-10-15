#!/usr/bin/env bash
# Session-17 end state: round 16 completed CHALLENGED and tallied; the repair the user chose reproduced, measured and its
# fixtures judged, NOT written (Decisions frozen at 29a29da2..., round 16's outcome not yet in Decisions). Read-only.
# Pattern: r18-handoff-state.sh. Run from the worktree root with bash, never sourced into zsh.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/h19.XXXXXX")"; trap 'rm -rf "$t"' EXIT
meta() { tr '\0' '\n' < "$1" | grep -A1 -x "$2" | tail -1; }
printf 'taken=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"; printf 'source=%s\n' "$src"
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/dec"; printf 'decisions=%s\n' "$(vf_hash "$t/dec")"
printf 'head=%s\n' "$(git rev-parse --short HEAD)"
printf 'lock=%s\n' "$([[ -e "$s/notes/verification/lock" ]] && echo HELD || echo absent)"
pending=0; for l in "$s"/notes/verification/rounds/*/ROUND-*; do [[ -f "$l/report.sha256" ]] || pending=$((pending+1)); done
printf 'pending_reservations=%s\n' "$pending"
printf 'opponent_rounds_sealed=%s round16_digest=%s\n' "$(ls -d "$s"/notes/verification/rounds/opponent/ROUND-* | wc -l | tr -d ' ')" "$(cat "$s/notes/verification/rounds/opponent/ROUND-16/report.sha256" 2>/dev/null)"
fl="$(cat "$s/notes/verification/floor-latest")"
printf 'floor_latest=%s floor_source=%s (current only if equal to source)\n' "$fl" "$(meta "$s/notes/verification/floors/$fl/meta.nul" source)"
printf 'captures=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')"
printf 'T030o47=%s ticked, T030=%s ticked\n' "$(grep -c -F -- '- [x] **T030o47**' "$s/tasks.md")" "$(grep -c -F -- '- [x] **T030**' "$s/tasks.md")"
printf 'repair_files=%s\n' "$(shasum -a 256 -c "$r/r17-edits/pre-apply.sha256" 2>&1 | grep -c ': OK$') of 4 hash as r17-edits/pre-apply (the next repair not applied)"
bash scripts/spec-gate.sh waiver "$s" opponent 16 > "$t/w16" 2>&1; printf 'round16_waiver_rc=%s %s\n' "$?" "$(head -1 "$t/w16")"
bash scripts/spec-gate.sh waiver "$s" opponent 17 > /dev/null 2>&1; printf 'round17_waiver_rc=%s\n' "$?"
bash scripts/sdd-analyze.sh "$s" > "$t/an" 2>&1; printf 'analyzer_rc=%s %s\n' "$?" "$(tail -1 "$t/an")"
bash scripts/spec-gate.sh tally "$s" > "$t/tally" 2>&1; printf 'tally_rc=%s %s\n' "$?" "$(grep -E '^(opponent rounds|blocking)=' "$t/tally" | tr '\n' ' ')"
printf 'free=%s power=%s\n' "$(df -h / | awk 'NR==2{print $4}')" "$(pmset -g batt | head -1 | sed "s/.*'\(.*\)'.*/\1/")"
printf 'swap=%s\n' "$(sysctl -n vm.swapusage)"
printf 'receipts:'; for x in r16-floor-2 r16-floor-validate r16-reserve r16-complete r16-tally r16-final-audit r18-handoff-state r17-repro r17-grammar-survey r17-measure r17-fixtures-judge; do printf ' %s.rc=%s' "$x" "$(cat "$r/$x.rc" 2>/dev/null || echo MISSING)"; done; printf '\n'
printf 'prepared repair: '; for f in r17-edits/pre-apply.sha256 r17-edits/kernel-1.pairs r17-edits/vc-1.pairs r17-edits/tgc-1.pairs r17-edits/tsg-1.pairs r17-edits/lit.pl; do printf '%s=%s ' "$f" "$([[ -f "$r/$f" ]] && echo present || echo MISSING)"; done; printf '\n'
