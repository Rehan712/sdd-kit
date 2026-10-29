#!/usr/bin/env bash
# Reality-check round-3 steps with receipts, 2026-10-15 (session 23), run only after opponent round 20 CLEARED and on its
# floor. Pattern: rc3-step.sh. Run from the worktree root with bash, in the
# background. Every exit is written from inside this script to <step>.rc; read it back after.
# Usage: bash <this> control CAP-<id>     -> rc3-control.{log,rc,time}  (T029 typed control: control-t029.sh; before the
#                                            prereserve state, since its acceptance rewrites tasks.md's T029 entry)
#        bash <this> reserve FLOOR-<id>   -> rc3-reserve.{log,rc,time}
#        bash <this> probe                -> rc3-probe.{log,rc,time}    (tests/probe-gate-contract.sh; read-only)
#        bash <this> complete             -> rc3-complete.{log,rc,time} (reading reality-check-round3.md)
#        bash <this> tally                -> rc3-tally.{log,rc}
# A step refuses to run when any of its receipts already exists.
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
step="${1:?step}"
case "$step" in
  control|reserve|probe|complete) base="rc3-$step"; exts=(log rc time);;
  tally) base=rc3-tally; exts=(log rc);;
  *) echo "unknown step: $step" >&2; exit 2;;
esac
for x in "${exts[@]}"; do [[ ! -e "$r/$base.$x" ]] || { echo "refusing: $r/$base.$x exists" >&2; exit 2; }; done
stamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }
case "$step" in
  control)
    cap="${2:?CAP id}"; stamp > "$r/$base.time"
    bash "$s/notes/verification/handoff/control-t029.sh" "$cap" > "$r/$base.log" 2>&1
    echo "$?" > "$r/$base.rc"; stamp >> "$r/$base.time";;
  reserve)
    id="${2:?FLOOR id}"; stamp > "$r/$base.time"
    bash scripts/spec-gate.sh round "$s" reality-check --floor "$id" > "$r/$base.log" 2>&1
    echo "$?" > "$r/$base.rc"; stamp >> "$r/$base.time";;
  probe)
    stamp > "$r/$base.time"
    bash tests/probe-gate-contract.sh "$s" > "$r/$base.log" 2>&1
    echo "$?" > "$r/$base.rc"; stamp >> "$r/$base.time";;
  complete)
    stamp > "$r/$base.time"
    bash scripts/spec-gate.sh round "$s" reality-check --complete "$r/reality-check-round3.md" > "$r/$base.log" 2>&1
    echo "$?" > "$r/$base.rc"; stamp >> "$r/$base.time";;
  tally)
    bash scripts/spec-gate.sh tally "$s" > "$r/$base.log" 2>&1
    echo "$?" > "$r/$base.rc";;
esac
printf '%s rc=%s\n' "$step" "$(cat "$r/$base.rc")"
