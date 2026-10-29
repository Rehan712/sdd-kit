#!/usr/bin/env bash
# Round-15 gate steps with receipts, 2026-10-07 (session 15). Pattern: r14-gate-step.sh (the r12 validate, reserve and
# complete receipts). Run from the worktree root with bash, in the background (each step takes over
# 10 minutes). Every exit is written from inside this script to <step>.rc; read it back after.
# Usage: bash <this> validate FLOOR-<id>   -> r15-floor-validate.{out,err,rc,time}
#        bash <this> reserve FLOOR-<id>    -> r15-reserve.{log,rc,time}
#        bash <this> complete              -> r15-complete.{log,rc,time}
#        bash <this> tally                 -> r15-tally.{log,rc}
# A step refuses to run when any of its receipts already exists.
set -uo pipefail
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
step="${1:?step}"
case "$step" in
  validate) base=r15-floor-validate; exts=(out err rc time);;
  reserve) base=r15-reserve; exts=(log rc time);;
  complete) base=r15-complete; exts=(log rc time);;
  tally) base=r15-tally; exts=(log rc);;
  *) echo "unknown step: $step" >&2; exit 2;;
esac
for x in "${exts[@]}"; do [[ ! -e "$r/$base.$x" ]] || { echo "refusing: $r/$base.$x exists" >&2; exit 2; }; done
stamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }
case "$step" in
  validate)
    id="${2:?FLOOR id}"; stamp > "$r/$base.time"
    bash -c 'HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh; vf_floor_validate "$1" "$2"' \
      _ "$s" "$id" > "$r/$base.out" 2> "$r/$base.err"
    echo "$?" > "$r/$base.rc"; stamp >> "$r/$base.time";;
  reserve)
    id="${2:?FLOOR id}"; stamp > "$r/$base.time"
    bash scripts/spec-gate.sh round "$s" opponent --floor "$id" > "$r/$base.log" 2>&1
    echo "$?" > "$r/$base.rc"; stamp >> "$r/$base.time";;
  complete)
    stamp > "$r/$base.time"
    bash scripts/spec-gate.sh round "$s" opponent --complete "$r/opponent-round15.md" > "$r/$base.log" 2>&1
    echo "$?" > "$r/$base.rc"; stamp >> "$r/$base.time";;
  tally)
    bash scripts/spec-gate.sh tally "$s" > "$r/$base.log" 2>&1
    echo "$?" > "$r/$base.rc";;
esac
printf '%s rc=%s\n' "$step" "$(cat "$r/$base.rc")"
