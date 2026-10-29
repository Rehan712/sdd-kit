#!/usr/bin/env bash
# R3-F6 measured, 2026-09-30 (session 9): does mawk read VT as a default field separator,
# and does the kernel read a mapped line differently there? The same probe runs on this
# host (macOS awk) and in a throwaway container of the localstack/localstack:3.8.1 image
# already on disk (Debian 12, awk = mawk 1.3.4 20200120), as the user approved: --rm,
# --network none, the kit copy mounted read-only, nothing pulled, mv-localstack untouched.
# Read-only against the live worktree: the kit is a copy of the live enumeration.
# Usage: bash t030o43-r3f6-mawk.sh <scratchpad> <worktree>
set -uo pipefail
SP="$1"; WT="$2"; R="$SP/t030o43-r3f6"
rm -rf "$R"; mkdir -p "$R/kit" "$R/work"
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$R/kit" && tar -xf - ) || { echo 'FAIL copy'; exit 2; }
cat > "$R/probe.sh" <<'PROBE'
#!/usr/bin/env bash
# probe.sh <kit> <work>: prints one line per measurement; identical on every platform
# except where an awk reads a byte differently.
K="$1"; W="$2"; export TMPDIR="$W/tmp"; rm -rf "$TMPDIR"; mkdir -p "$TMPDIR"
AWK="$(command -v awk)"; printf 'platform=%s awk=%s version=%s\n' "$(uname -s)" "$(readlink -f "$AWK" 2>/dev/null || echo "$AWK")" "$( { "$AWK" --version 2>&1 || "$AWK" -W version 2>&1; } | head -1)"
for b in '\013' '\014' '\015'; do
  printf "a${b}b c\n" | LC_ALL=C awk '{printf "record NF=%d ", NF}'
  printf "a${b}b c\n" | LC_ALL=C awk '{n=split($0, A); printf "split-default=%d ", n}'
  printf "a${b}b c\n" | LC_ALL=C awk '{n=split($0, A, " "); printf "split-space=%d ", n}'
  printf "a${b}b c\n" | LC_ALL=C awk '{$0=$0 ""; printf "reassigned NF=%d ", NF}'
  printf "a${b}b c\n" | LC_ALL=C awk '{printf "class=%d\n", ($0 ~ /a[[:space:]]b/)}'
  printf '  byte=%s\n' "$b"
done
NB=$'\302\240'
# The kernel sites that split a mapped line by default: `fid=$3` of a canonical Finding
# heading, and `wantb=$2; wantm=$5` of the totals line. A U+00A0 is mapped to VT first.
round() { # <heading> <totals>
  printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CHALLENGED\n%s\n### What I attacked\nx\n%s\n- **Class:** tier-binding\n- **Status:** open\n- **Prior:** none\n- **Severity:** data-loss\n- **Scenario:** s\n- **Where:** scripts/run.sh:9\n- **Reproduced:** r\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** w\n- **Class-wide fix:** f\n### Held up / follow-up tasks\nh\n<!-- gate-round-end: opponent:1 -->\n' \
    "$(printf 'a%.0s' {1..64})" "$2" "$1"
}
case_() { # <label> <heading> <totals>
  local d="$W/$1"; rm -rf "$d" "$W/out.nul"; mkdir -p "$d/notes"; round "$2" "$3" > "$d/notes/opponent.md"
  out="$(bash -c '. "$1/scripts/verification-lib.sh"; vf_reports "$2/notes/opponent.md" opponent "$3" "$2"' _ "$K" "$d" "$W/out.nul" 2>&1)"; rc=$?
  ids="$(tr '\0' '\n' 2>/dev/null < "$W/out.nul" | awk 'p==1{print; p=0} $0=="finding"{getline; p=1}' | LC_ALL=C sed -n l | tr '\n' ' ')"
  printf 'case %-22s rc=%s ids=[%s] %s\n' "$1" "$rc" "$ids" "$(printf '%s' "$out" | sed "s#$W/##g" | tr '\n' '|' | LC_ALL=C sed 's/\x0b/<VT>/g' | cut -c1-200)"
}
case_ control '### Finding G-042' '**Blocking:** 1 · **Minor:** 0'
case_ heading-id-nbsp "### Finding G-042${NB}" '**Blocking:** 1 · **Minor:** 0'
case_ heading-id-nbsp-title "### Finding G-042${NB}— title" '**Blocking:** 1 · **Minor:** 0'
case_ totals-nbsp "### Finding G-042" "**Blocking:**${NB}1 · **Minor:** 0"
case_ totals-nbsp-count "### Finding G-042" "**Blocking:** 1${NB}· **Minor:** 0"
PROBE
host="$(bash "$R/probe.sh" "$R/kit" "$R/work" 2>&1)"; hrc=$?
printf '== host (rc=%s)\n%s\n' "$hrc" "$host"
cont="$(docker run --rm --network none -v "$R/kit:/kit:ro" -v "$R/probe.sh:/probe.sh:ro" --tmpfs /work:exec \
  --entrypoint /bin/bash localstack/localstack:3.8.1 /probe.sh /kit /work 2>&1)"; crc=$?
printf '== container (rc=%s)\n%s\n' "$crc" "$cont"
# The measurement: which lines differ between the two awks (the platform line aside).
diffs="$(diff <(printf '%s\n' "$host" | tail -n +2) <(printf '%s\n' "$cont" | tail -n +2))"
printf '== differences host vs container (excluding the platform line)\n%s\n' "${diffs:-none}"
cd "$SP" && rm -rf "$R"
(( hrc == 0 && crc == 0 ))
