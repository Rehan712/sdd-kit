#!/usr/bin/env bash
# T030o43 member search, 2026-09-27 (session 7). Read-only. Run from the worktree root.
# The harness is the file set vf_snapshot records as `harness` (scripts/verification-lib.sh,
# the `for tool in lib.sh verification-lib.sh spec-run.sh ...` loop): the scripts whose own
# parsing decides a record, an identity or a verdict. This lists every line of those files
# that starts a text-processing program in command position (after start of line, `$(`,
# `<(`, a pipe, `;`, `&&`, `||`, `then`, `do`, `!`, or an `LC_ALL=C`/`VAR=...` prefix),
# skipping comment lines, so each can be classified by hand: its exit status read, or
# discarded; and whether its output decides anything. Nothing here is a guard; the
# classification is the receipt.
set -uo pipefail
files=(scripts/lib.sh scripts/verification-lib.sh scripts/spec-run.sh scripts/spec-task.sh
  scripts/spec-gate.sh scripts/sdd-analyze.sh scripts/spec-ac-coverage.sh scripts/spec-evidence.sh)
LC_ALL=C awk '
  BEGIN { progs = "awk|grep|sed|tr|sort|cut|head|tail|wc|od|uniq|paste|find|xargs|comm|join" }
  FNR == 1 { file = FILENAME }
  /^[[:space:]]*#/ { next }
  {
    line = $0
    pat = "(^|\\$\\(|<\\(|\\||;|&&|\\|\\||[[:space:]]then|[[:space:]]do|!|LC_ALL=C|[A-Z_]+=\"[^\"]*\")[[:space:]]*(" progs ")([[:space:]]|$)"
    if (line ~ pat) { n++; printf "%s:%d: %s\n", file, FNR, substr(line, 1, 220) }
  }
  END { printf "candidates=%d\n", n > "/dev/stderr" }
' "${files[@]}"
