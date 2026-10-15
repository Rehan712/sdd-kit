#!/usr/bin/env bash
# Read-only entry audit for spec 003, 2026-09-23 continuation.
# Run from the worktree root. Writes only under $SP (the scratchpad); a
# before/after stat digest of the whole worktree proves no worktree writes.
set -uo pipefail
SP="${1:?scratchpad dir}"
HUB_DIR="$PWD"
export TMPDIR="$SP/tmp"; mkdir -p "$TMPDIR"
. scripts/lib.sh
. scripts/verification-lib.sh
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
ci="$s/notes/verification/platforms/ci-20260922"
t="$SP/audit-work"; rm -rf "$t"; mkdir -p "$t"
fails=0
pass() { printf 'PASS %s\n' "$*"; }
fail() { printf 'FAIL %s\n' "$*"; fails=$((fails+1)); }
chk() { local label="$1"; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }

wt_digest() {
  find . -path ./.git -prune -o \( -type f -o -type l -o -type d \) -print0 \
    | LC_ALL=C sort -z | xargs -0 stat -f '%N|%z|%m|%p' | shasum -a 256 | cut -d' ' -f1
}
pre="$(wt_digest)"
printf 'worktree-stat-digest pre=%s\n' "$pre"
printf 'tools: bash=%s git=%s shellcheck=%s\n' "$(command -v bash)" "$(command -v git)" "$(command -v shellcheck)"

# 1. Gate histories, pending reservations, sealed digests.
for gate in opponent reality-check; do
  if vf_round_history "$s" "$gate" "$t"; then
    pending=0
    for ledger in "$s/notes/verification/rounds/$gate"/ROUND-*; do
      vf_integrity "$ledger" meta.nul || fail "integrity $ledger"
      [[ -f "$ledger/report.sha256" ]] || pending=$((pending+1))
    done
    printf '%s sealed-rounds=%s pending=%s ledgers=%s\n' "$gate" "$VF_ROUND_LAST" "$pending" \
      "$(ls -d "$s/notes/verification/rounds/$gate"/ROUND-* | wc -l | tr -d ' ')"
    [[ "$pending" == 0 ]] && pass "$gate no pending reservation" || fail "$gate pending=$pending"
    [[ "$gate" != opponent || "$VF_ROUND_LAST" == 9 ]] || fail "opponent last round $VF_ROUND_LAST"
    [[ "$gate" != reality-check || "$VF_ROUND_LAST" == 1 ]] || fail "reality-check last round $VF_ROUND_LAST"
  else fail "vf_round_history $gate"; fi
done
chk 'no opponent ROUND-10 ledger' test ! -e "$s/notes/verification/rounds/opponent/ROUND-10"
chk 'no reality-check ROUND-2 ledger' test ! -e "$s/notes/verification/rounds/reality-check/ROUND-2"
for n in 1 2 3 4 5 6 7 8 9; do
  vf_report_block "$s/notes/opponent.md" "$n" > "$t/block-$n"
  d="$(vf_hash "$t/block-$n")"
  [[ "$d" == "$(cat "$s/notes/verification/rounds/opponent/ROUND-$n/report.sha256")" ]] \
    && printf 'PASS opponent round %s digest %s\n' "$n" "${d:0:16}" || fail "opponent round $n digest"
done
vf_report_block "$r/opponent-round9.md" 9 > "$t/returned-9"
chk 'round 9 canonical block == returned block' cmp -s "$t/block-9" "$t/returned-9"
chk 'round 9 digest == 2aae626e...' test "$(vf_hash "$t/block-9")" == 2aae626e3c60020125ac2bab08a87d27da40ab4e63aa4f15988903feb690e83c
vf_report_block "$s/notes/reality-check.md" 1 > "$t/rc-block-1"
chk 'reality-check round 1 digest == ledger == e5f957db...' test "$(vf_hash "$t/rc-block-1")" == "$(cat "$s/notes/verification/rounds/reality-check/ROUND-1/report.sha256")" -a "$(vf_hash "$t/rc-block-1")" == e5f957dbd67335502a151c5198881e32310fb4a003363c684384565c9ddaa748
vf_report_block "$r/reality-check-round1.md" 1 > "$t/rc-returned-1"
chk 'reality-check round 1 canonical == returned' cmp -s "$t/rc-block-1" "$t/rc-returned-1"
printf 'ROUND-9 meta: %s\n' "$(tr '\0' ' ' < "$s/notes/verification/rounds/opponent/ROUND-9/meta.nul" | cut -c1-400)"

# 2. Source identity, Decisions, floor currency, CI manifest equality.
if src="$(vf_snapshot "$s" "$PWD" "$PWD" "$t/inputs.nul")"; then
  printf 'current source=%s\n' "$src"
  chk 'source == aa18111b...' test "$src" == aa18111b6dbe36a6d75e923129802ffa7c688dddedc9a7ec811c350dd7bc66c4
  chk 'current input manifest cmp-identical to hosted-CI snapshot-inputs.nul' cmp -s "$t/inputs.nul" "$ci/snapshot-inputs.nul"
else fail 'vf_snapshot'; src=''; fi
vf_semantic_file "$s/STATUS.md" "$s/STATUS.md" "$t/decisions"
dd="$(vf_hash "$t/decisions")"
chk "Decisions digest == 98c1ec6a... (got ${dd:0:16})" test "$dd" == 98c1ec6a9a37d16f8c9a39dd23ef0168112356de4ee4cd5b4aad788412955093
if grep -q -E '2aae626e|[Rr]ound 9 (consumed|completed)|O-013|O-014' "$t/decisions"; then fail 'round 9 outcome already in Decisions'
else pass 'round 9 outcome (2aae626e / O-013 / O-014) absent from Decisions'; fi
printf 'last Decisions line: %s\n' "$(grep -v '^[[:space:]]*$' "$t/decisions" | tail -1 | cut -c1-120)"
fv="$(vf_floor_validate "$s" FLOOR-k1reWt 2> "$t/floor.err")"; frc=$?
chk "FLOOR-k1reWt validates current (rc=$frc)" test "$frc" == 0 -a "$fv" == "$src"
ex=0; ru=0; f=()
while IFS= read -r -d '' v; do f+=("$v"); (( ${#f[@]} == 6 )) || continue
  if [[ "${f[5]}" == 1 ]]; then ru=$((ru+1)); else ex=$((ex+1)); fi; f=(); done < "$s/notes/verification/floors/FLOOR-k1reWt/commands.nul"
chk "FLOOR-k1reWt commands executed=$ex reused=$ru (22/49)" test "$ex" == 22 -a "$ru" == 49
for fl in $(find "$s/notes/verification" -maxdepth 2 -name '*latest*'); do printf 'latest pointer %s -> %s\n' "$fl" "$(head -c 200 "$fl" | tr '\0\n' '  ')"; done
for c in CAP-409-Z8jCNl CAP-410-* CAP-389-mHlDcf; do
  for d in "$s"/notes/captures/$c; do id="${d##*/}"
    vf_capture_check "$s" "$id" "$t/inputs.nul" reuse > /dev/null 2> "$t/cap.err"; crc=$?
    chk "capture $id reusable now (rc=$crc)" test "$crc" == 0
  done
done
vf_capture_check "$s" CAP-367-g14RVk "$t/inputs.nul" current > /dev/null 2> "$t/cap367.err"; crc=$?
chk "T029 control capture CAP-367-g14RVk is NOT current (rc=$crc: $(head -1 "$t/cap367.err"))" test "$crc" != 0

# 3. Lock, HEAD, tasks.
chk 'no held lock' test ! -e "$s/notes/verification/lock"
chk "HEAD == 0d55c62 ($(git rev-parse --short HEAD)) on $(git branch --show-current)" test "$(git rev-parse --short HEAD)" == 0d55c62
for task in T030 T031 T032 T033 T034; do chk "$task unchecked" grep -q -F -- "- [ ] **$task**" "$s/tasks.md"; done
for task in T030o37 T030o38; do chk "$task checked" grep -q -F -- "- [x] **$task**" "$s/tasks.md"; done
if grep -q -E 'T030o39|T030o40' "$s/tasks.md"; then fail 'T030o39/T030o40 already in tasks.md'; else pass 'T030o39/T030o40 not yet in tasks.md'; fi
printf 'staging survivors: floor=%s checkpoint=%s capture=%s\n' \
  "$(find "$s/notes" -name '.floor.*' | wc -l | tr -d ' ')" "$(find "$s/notes" -name '.checkpoint.*' | wc -l | tr -d ' ')" "$(find "$s/notes" -name '.capture.*' | wc -l | tr -d ' ')"
printf 'captures on disk=%s ledger entries=%s\n' "$(ls -d "$s"/notes/captures/CAP-* | wc -l | tr -d ' ')" "$(ls "$s"/notes/verification/captures/ | grep -c '^CAP-')"

# 4. Waiver checks and tally, against the actual CLI and its exit codes.
bash scripts/spec-gate.sh waiver "$s" opponent 10 > "$t/w10.log" 2>&1; wrc=$?
chk "opponent round 10 refused at exit 4 (rc=$wrc)" test "$wrc" == 4
printf 'w10 output (%s lines):\n' "$(wc -l < "$t/w10.log" | tr -d ' ')"; sed -n '1,14p' "$t/w10.log" | cut -c1-160
printf 'w10 candidate lines naming STATUS.md: %s\n' "$(grep -c -E 'STATUS\.md:[0-9]+' "$t/w10.log")"
bash scripts/spec-gate.sh waiver "$s" opponent 9 > "$t/w9.log" 2>&1; printf 'opponent 9 check rc=%s: %s\n' "$?" "$(head -1 "$t/w9.log")"
bash scripts/spec-gate.sh waiver "$s" reality-check 2 > "$t/rc2.log" 2>&1; printf 'reality-check 2 check rc=%s: %s\n' "$?" "$(head -1 "$t/rc2.log")"
bash scripts/spec-gate.sh tally "$s" > "$t/tally.log" 2>&1; trc=$?
chk "tally exit 0 (rc=$trc)" test "$trc" == 0
chk 'tally byte-identical to r9-tally.log' cmp -s "$t/tally.log" "$r/r9-tally.log"
[[ -s "$t/tally.log" ]] && ! cmp -s "$t/tally.log" "$r/r9-tally.log" && diff "$r/r9-tally.log" "$t/tally.log" | head -10

# 5. Hosted CI receipts and tree mapping (read-only object reads only).
for f in collect build pr-close branch-delete; do chk "ci $f.rc == 0" test "$(cat "$ci/$f.rc")" == 0; done
chk 'ci snapshot-inputs.sha256 == aa18111b...' test "$(cat "$ci/snapshot-inputs.sha256")" == aa18111b6dbe36a6d75e923129802ffa7c688dddedc9a7ec811c350dd7bc66c4
chk 'snapshot commit tree == 13b18cd7' test "$(git rev-parse '15b7bb5d64343e12f9dbfc51c2df92d0274b2784^{tree}')" == 13b18cd7eea837a226209348e65c7a336623a274
chk 'snapshot commit parent == 0d55c62' test "$(git rev-parse '15b7bb5d64343e12f9dbfc51c2df92d0274b2784^1')" == 0d55c62b01cd3e2295ca34b048a212780dd92c00
printf 'jobs.json: %s\n' "$(jq -r '[.jobs[] | "\(.name)=\(.conclusion)"] | join(" ")' "$ci/run-35774044069/jobs.json")"
printf 'jobs.json non-success step conclusions: %s\n' "$(jq -r '[.jobs[].steps[] | select(.conclusion != "success") | "\(.name)=\(.conclusion)"] | join(" ")' "$ci/run-35774044069/jobs.json")"
for j in tests__ubuntu-latest_ tests__macos-latest_ tests-bash32; do
  lg="$ci/run-35774044069/job-$j.log"
  printf 'job %s: ok-lines=%s FAIL-lines=%s suites=%s summed=%s merge-ref-55d1325e-mentions=%s\n' "$j" \
    "$(grep -c -E '^[^ ]* +ok   ' "$lg")" "$(grep -c -E '^[^ ]* +FAIL ' "$lg")" "$(grep -c -E -- '-- [0-9]+/[0-9]+ passed' "$lg")" \
    "$(grep -o -E -- '-- [0-9]+/[0-9]+ passed' "$lg" | awk -F'[ /]' '{p+=$2; n+=$3} END {print p "/" n}')" "$(grep -c 55d1325e "$lg")"
done
printf 'pr-final-state: %s\n' "$(head -1 "$ci/pr-final-state.txt")"
# O-013 blind spot: bookkeeping bytes CI saw for OTHER specs must equal today's bytes.
git ls-tree -r --full-tree 13b18cd7eea837a226209348e65c7a336623a274 -- .specify/specs/001-* .specify/specs/002-* > "$t/tree-others"
mism=0; nb=0
while IFS=$'\t' read -r head path; do
  read -r mode _ oid <<< "$head"
  cur="$(git hash-object -- "$path" 2>/dev/null)"
  cmode=100644; [[ ! -x "$path" ]] || cmode=100755
  if vf_bookkeeping_path "$path"; then nb=$((nb+1)); printf '  bookkeeping in CI tree: %s %s\n' "$path" "$([[ "$cur" == "$oid" && "$cmode" == "$mode" ]] && echo same || echo DIFFERENT)"; fi
  [[ "$cur" == "$oid" && "$cmode" == "$mode" ]] || { mism=$((mism+1)); printf '  differs: %s\n' "$path"; }
done < "$t/tree-others"
git ls-files --cached --others --exclude-standard -- .specify/specs/001-* .specify/specs/002-* | LC_ALL=C sort > "$t/cur-others"
cut -f2 "$t/tree-others" | LC_ALL=C sort > "$t/tree-others-paths"
chk "001/002 files: $(wc -l < "$t/tree-others" | tr -d ' ') in CI tree, $nb bookkeeping, $mism differ from today's bytes; same path set" test "$mism" == 0 -a -z "$(comm -3 "$t/cur-others" "$t/tree-others-paths")"
chk '001/002 spec dirs clean vs HEAD (no diff, no untracked)' test -z "$(git --no-optional-locks status --porcelain -- .specify/specs/002-usage-limit-handling-for-dispatched-runs .specify/specs/001-*)"

# 6. O-013 function-level check (no reproduction edit): exclusion scope and silent drop.
p2=.specify/specs/002-usage-limit-handling-for-dispatched-runs/notes/opponent.md
vf_bookkeeping_path "$p2"; printf 'vf_bookkeeping_path(002 opponent.md) rc=%s (0 = excluded)\n' "$?"
: > "$t/rec"; vf_path_record "$PWD" "$p2" "$t/rec" "$t"; printf 'vf_path_record(002 opponent.md) rc=%s record-bytes=%s stderr=none-captured\n' "$?" "$(wc -c < "$t/rec" | tr -d ' ')"
: > "$t/rec2"; vf_path_record "$PWD" README.md "$t/rec2" "$t"; printf 'vf_path_record(README.md) rc=%s record-bytes=%s (control)\n' "$?" "$(wc -c < "$t/rec2" | tr -d ' ')"
printf 'identity records: 002 notes/* paths=%s; 002 opponent/reality-check/evidence reports=%s\n' "$(tr '\0' '\n' < "$t/inputs.nul" | grep -c '^\.specify/specs/002-usage-limit-handling-for-dispatched-runs/notes/')" "$(tr '\0' '\n' < "$t/inputs.nul" | grep -c -E '^\.specify/specs/002-[^/]+/notes/(opponent|reality-check|evidence)\.md$')"

# 7. O-014 replay: the tally's own fold, without and with the guard's manifest seed.
vf_reports "$s/notes/opponent.md" opponent "$t/cat" "$s" || fail 'vf_reports opponent'
f=(); : > "$t/obs"
while IFS= read -r -d '' v; do f+=("$v"); (( ${#f[@]} == 12 )) || continue
  [[ "${f[0]}" != finding ]] || printf '%s\t%s\t%s\t%s\n' "${f[1]}" "${f[2]}" "${f[4]}" "${f[6]}" >> "$t/obs"; f=(); done < "$t/cat"
: > "$t/seeds"
for manifest in "$s/notes/verification/reports/opponent-findings-"*.md; do
  awk "$_VF_AWK_FENCE"'
      function flushm() {if(id!="" && cls!="") print id ":" cls ":" sev; id=""; cls=""; sev=""}
      vf_quoted($0) {next}
      /^#+ Finding [A-Z][A-Z0-9]*-[0-9]+[[:space:]]*$/ {flushm(); id=$NF; next}
      id != "" && /^-[[:space:]]+\*\*Class:\*\*/ {cls=$0; sub(/^.*\*\*Class:\*\*[[:space:]]*/, "", cls); gsub(/[[:space:]]/, "", cls)}
      id != "" && /^-[[:space:]]+\*\*Severity:\*\*/ {sev=$0; sub(/^.*\*\*Severity:\*\*[[:space:]]*/, "", sev); gsub(/[[:space:]]/, "", sev)}
      END {flushm()}' "$manifest" >> "$t/seeds"
done
printf 'manifest seeds: %s\n' "$(tr '\n' ' ' < "$t/seeds")"
fold='function tier(s) {return (s=="minor" || s=="degraded") ? "minor" : "blocking"}
  FILENAME==seedfile { split($0, m, ":"); if(m[3]!="") {mt=tier(m[3]); if(!(m[1] in first) || mt=="blocking") first[m[1]]=mt}; next }
  { k=$2; if((k in first) && first[k]=="blocking" && tier($4)=="minor" && $3!="resolved") {down++; printf "  downgrade round=%s id=%s status=%s sev=%s\n", $1, $2, $3, $4}
    if(!(k in first) || tier($4)=="blocking") first[k]=tier($4) }
  END {printf "  severity-downgrades=%d\n", down+0}'
printf 'replay WITHOUT manifest seed (tally rule):\n'; : > "$t/noseed"; awk -F '\t' -v seedfile="$t/noseed" "$fold" "$t/noseed" "$t/obs"
printf 'replay WITH manifest seed (guard rule):\n'; awk -F '\t' -v seedfile="$t/seeds" "$fold" "$t/seeds" "$t/obs"
printf 'cited mutation sites: lib:1243=[%s] tgc:1305=[%s]\n' "$(sed -n '1243p' scripts/verification-lib.sh | sed 's/^ *//')" "$(sed -n '1305p' tests/test-gate-contracts.sh | sed 's/^ *//')"

post="$(wt_digest)"
printf 'worktree-stat-digest post=%s\n' "$post"
chk 'worktree unchanged by this audit' test "$pre" == "$post"
printf 'audit failures=%s\n' "$fails"
(( fails == 0 ))
