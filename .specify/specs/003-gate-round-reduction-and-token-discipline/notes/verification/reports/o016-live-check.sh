#!/usr/bin/env bash
# Post-hoc live-worktree check for o016-repro.sh / o016-measure.sh, whose own
# tripwire hashed the whole `git status` and so also saw the invoker's new
# receipts under notes/verification/reports/ (see o016-repro.note). This one
# leaves out <spec>/notes/verification/, compares with the mid-run baseline in
# o016-live-midrun.txt, and re-derives the source identity. Read-only.
set -uo pipefail
HUB_DIR="$PWD"; . scripts/lib.sh; . scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline; r="$s/notes/verification/reports"
t="$(mktemp -d "${TMPDIR:-/tmp}/o016-live.XXXXXX")"; trap 'rm -rf "$t"' EXIT
fails=0
chk() { local l="$1"; shift; if "$@"; then echo "PASS $l"; else echo "FAIL $l"; fails=$((fails+1)); fi; }
now="$(GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall | grep -v -F "$s/notes/verification/" | LC_ALL=C sort | shasum -a 256 | cut -d' ' -f1)"
chk "status outside notes/verification/ == mid-run baseline ($now)" test "$now" == "$(sed -n 2p "$r/o016-live-midrun.txt")"
src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"
chk "source == 37cfccef... ($src)" test "$src" == 37cfccef3868bfd3939995882b5383d2f691b811cbb0dd0a754fe4bee68f16e1
echo 'status entries under notes/verification/ that are not reports receipts:'
GIT_OPTIONAL_LOCKS=0 git status --porcelain -uall | grep -F "$s/notes/verification/" | grep -v -F "$r/" | sed 's/^/  /'
echo "live-check failures=$fails"; (( fails == 0 ))
