#!/usr/bin/env bash
# T030o43, session 9 (2026-09-30): measure the repairs of focused review 3 BEFORE
# adopting them. Read-only against the live worktree: four standalone kits, each a copy
# of the live manifest enumeration made its own git repository:
#   CUR  the tree as it is (the session-8 state review 3 saw)
#   PRE  the pre-delta files (t030o43-base-9.sh's P) laid over it
#   REV  the review-2 state (t030o43-base-9.sh's B) laid over it
#   D    CUR plus the candidate: t030o43-edits/kernel-6.pairs, spec-task-3.pairs and
#        sdd-analyze-3.pairs
# Every run removes every LC_* name and sets LANG. A "PASS"/"FAIL" line judges D (or the
# history, D against CUR) against the intended result; PRE/REV/CUR columns are context.
# Sections A-J repeat t030o43-design-measure.sh's cases on D (the measurement of record
# for session 8), with the intended results that review 3's rules change marked; K is
# review 3; L is the history beyond session 8's (catalogs, task lists, stage maps, the
# manifest pass over every recorded notes/*.md, the review-3 field-rule measurement);
# M runs the R3-F6 probe on D in the approved throwaway container.
# Usage: bash t030o43-measure-9.sh <scratchpad> <worktree> <pre-dir> <rev-dir>
set -uo pipefail
SP="$1"; WT="$2"; PREF="$3"; REVF="$4"
R="$SP/t030o43-m9"; w="$R/work"
rm -rf "$R"; mkdir -p "$R" "$w" "$R/tmp"
export TMPDIR="$R/tmp"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"; E="$WT/$r/t030o43-edits"
fails=0; passes=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; passes=$((passes+1)); else say "FAIL $1 (want=[$2] got=[$3])"; fails=$((fails+1)); fi; }
has() { case "$3" in *"$2"*) say "PASS $1"; passes=$((passes+1));; *) say "FAIL $1 (want text [$2] in [$3])"; fails=$((fails+1));; esac; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
export LC_ALL=C
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
LOCS=(C en_US.UTF-8)

# --- kits --------------------------------------------------------------------
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) > "$R/src.tar" || { say 'FAIL enumerate'; exit 2; }
for k in CUR PRE REV D; do mkdir -p "$R/$k" && ( cd "$R/$k" && tar -xf "$R/src.tar" ) || { say "FAIL copy $k"; exit 2; }; done
( cd "$PREF" && find . -type f -print0 | tar --null -T - -cf - ) | ( cd "$R/PRE" && tar -xf - )
( cd "$REVF" && find . -type f -print0 | tar --null -T - -cf - ) | ( cd "$R/REV" && tar -xf - )
for p in kernel-6:scripts/verification-lib.sh spec-task-3:scripts/spec-task.sh sdd-analyze-3:scripts/sdd-analyze.sh; do
  perl "$E/lit.pl" "$R/D/${p#*:}" "$E/${p%%:*}.pairs" > /dev/null || { say "FAIL apply ${p%%:*}"; exit 2; }
done
for k in CUR PRE REV D; do
  ( cd "$R/$k" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid -c commit.gpgsign=false commit -qm base ) >/dev/null 2>&1 || { say "FAIL git $k"; exit 2; }
  for f in scripts/*.sh; do bash -n "$R/$k/$f" || { say "FAIL syntax $k $f"; fails=$((fails+1)); }; done
done
say "kits: CUR PRE REV D built; D candidate applied"

NB=$'\302\240'; NNB=$'\342\200\257'; ZW=$'\342\200\213'
WS19=($'\302\205' $'\302\240' $'\341\232\200' $'\342\200\200' $'\342\200\201' $'\342\200\202' $'\342\200\203' $'\342\200\204'
      $'\342\200\205' $'\342\200\206' $'\342\200\207' $'\342\200\210' $'\342\200\211' $'\342\200\212' $'\342\200\250'
      $'\342\200\251' $'\342\200\257' $'\342\201\237' $'\343\200\200')
SRC="$(printf 'a%.0s' {1..64})"
round() { # file verdict class status sev blocking minor [scenario]
  printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nManifest tier binding.\n### Finding G-042\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n- **Scenario:** %s\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read the manifest\n### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n' \
    "$SRC" "$2" "$6" "$7" "$3" "$4" "$5" "${8:-a recorded trigger}" > "$1"
}
vfr() { # kit locale spec -> "rc=N first-diagnostic/last-diagnostic"
  inloc "$2" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2/notes/opponent.md" opponent "$3" "$2"' _ "$R/$1" "$3" "$w/out.nul" > /dev/null 2> "$w/e"
  printf 'rc=%s %s' "$?" "$(grep -v '^awk:\|^ source line\|^ context is\|^	' "$w/e" | sed 's/^report recovery: [^:]*: //' | sed -n '1p;$p' | tr '\n' '/' | LC_ALL=C sed 's/\x0b/<VT>/g' | cut -c1-300)"
}
LOWER='clearing verdict rests on 1 lowered severity tier'
PARSE='prior-review manifest could not be parsed'
manifest_case() { # label want-diagnostic manifest-body [round-args...]
  local label="$1" want="$2" body="$3" sp="$R/m-$1" l got; shift 3
  mkdir -p "$sp/notes/verification/reports"
  printf '%b' "$body" > "$sp/notes/verification/reports/opponent-findings-review.md"
  if (( $# )); then round "$sp/notes/opponent.md" "$@"; else round "$sp/notes/opponent.md" CLEARED tier-binding open minor 0 1; fi
  say "  $label: PRE-UTF8 $(vfr PRE en_US.UTF-8 "$sp") | REV $(vfr REV C "$sp") | CUR $(vfr CUR C "$sp")"
  for l in "${LOCS[@]}"; do got="$(vfr D "$l" "$sp")"; has "$SEC $label D $l" "$want" "$got"; done
}
M='### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'

SEC=A; say '== A: prior-review manifest (session 8 cases; a CLEARED round re-records G-042 open at minor; the manifest records data-loss)'
manifest_case control "$LOWER" "$M"
manifest_case r1-class-nbsp "$LOWER" "### Finding G-042\n-${NB}**Class:** tier-binding\n- **Severity:** data-loss\n"
manifest_case r1-severity-nbsp "$LOWER" "### Finding G-042\n- **Class:** tier-binding\n-${NB}**Severity:** data-loss\n"
manifest_case r1-classbind-nbsp 'changes Class from tier-binding to silent-data-loss' "### Finding G-042\n-${NB}**Class:** tier-binding\n- **Severity:** data-loss\n" CHALLENGED silent-data-loss open wrong-result 1 0
manifest_case r1-heading-nbsp-after-id "$LOWER" "### Finding G-042${NB}\n- **Class:** tier-binding\n- **Severity:** data-loss\n"
manifest_case r1-heading-nbsp-after-hashes "$PARSE" "###${NB}Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n"
manifest_case r2-lower-finding "$LOWER" '### finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case r2-upper-finding "$LOWER" '### FINDING G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case r2-leading-space "$LOWER" ' ### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case r2-word-before "$PARSE" '### Opponent finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case r2-bom "$LOWER" '\357\273\277### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case r2-nbsp-before-hashes "$PARSE" "${NB}### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n"
manifest_case r2-zwsp-before-hashes "$PARSE" '\342\200\213### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case r2-crlf "$LOWER" '### Finding G-042\r\n- **Class:** tier-binding\r\n- **Severity:** data-loss\r\n'
manifest_case r2-crlf-classbind 'changes Class from tier-binding to silent-data-loss' '### Finding G-042\r\n- **Class:** tier-binding\r\n' CHALLENGED silent-data-loss open wrong-result 1 0
manifest_case r2-severity-unbolded "$PARSE" '### Finding G-042\n- **Class:** tier-binding\n- Severity: data-loss\n'
manifest_case r2-severity-colon-outside "$PARSE" '### Finding G-042\n- **Class:** tier-binding\n- **Severity**: data-loss\n'
manifest_case r2-severity-lowercase "$PARSE" '### Finding G-042\n- **Class:** tier-binding\n- **severity:** data-loss\n'
manifest_case r2-severity-italic "$PARSE" '### Finding G-042\n- **Class:** tier-binding\n- *Severity:* data-loss\n'
manifest_case r2-severity-twice "$PARSE" '### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n- **Severity:** minor\n'
manifest_case r2-unclosed-fence "$PARSE" '### Finding G-041\n- **Class:** other-class\n```text\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case r2-unclosed-comment "$PARSE" '### Finding G-041\n- **Class:** other-class\n- **Scenario:** see <!-- never closed\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case r2-unclosed-pre "$PARSE" '### Finding G-041\n- **Class:** other-class\n<pre>\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case r2-merge-into-previous "$LOWER" '### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n### finding G-041\n- **Class:** tier-binding\n- **Severity:** minor\n'
manifest_case r2-titled-heading "$LOWER" '### Finding G-042 — tier binding lost\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case indented-2 "$LOWER" '### Finding G-042\n  - **Class:** tier-binding\n  - **Severity:** data-loss\n'
manifest_case indented-4-severity "$LOWER" '### Finding G-042\n- **Class:** tier-binding\n    - **Severity:** data-loss\n'
manifest_case class-with-space "$PARSE" '### Finding G-042\n- **Class:** tier binding\n- **Severity:** data-loss\n'
manifest_case field-outside-finding "$PARSE" '# Prior review\n- **Severity:** data-loss\n### Finding G-042\n- **Class:** tier-binding\n'
manifest_case id-ill-cased "$PARSE" '### Finding g-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case nbsp-fence-pair "$LOWER" "${NB}\`\`\`\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n${NB}\`\`\`\n"
cp_i=0
for ch in "${WS19[@]}"; do
  cp_i=$((cp_i+1)); sp="$R/m-ws-$cp_i"; mkdir -p "$sp/notes/verification/reports"
  printf '### Finding G-042\n-%s**Class:** tier-binding\n- **Severity:** data-loss\n' "$ch" > "$sp/notes/verification/reports/opponent-findings-review.md"
  round "$sp/notes/opponent.md" CLEARED tier-binding open minor 0 1
  for l in "${LOCS[@]}"; do has "A ws-$cp_i ($(printf '%s' "$ch" | od -An -tx1 | tr -d ' ')) D $l" "$LOWER" "$(vfr D "$l" "$sp")"; done
done

say '== B: plausible manifests parse (a CHALLENGED round re-records O-017 at its manifest Class and tier: rc=0)'
okround() { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CHALLENGED\n**Blocking:** 1 · **Minor:** 0\n### What I attacked\nx\n### Finding O-017\n- **Class:** harness-locale-decoding\n- **Status:** open\n- **Prior:** none\n- **Severity:** wrong-result\n- **Scenario:** s\n- **Where:** scripts/run.sh:9\n- **Reproduced:** r\n- **Root cause:** plan-gap\n- **Blocks:** AC-012\n- **Wrong behavior:** w\n- **Class-wide fix:** f\n### Held up / follow-up tasks\nh\n<!-- gate-round-end: opponent:1 -->\n' "$SRC" > "$1"; }
bcase() { # label body-file-writer...
  local f="$1" sp="$R/b-$1"; mkdir -p "$sp/notes/verification/reports"
  cat > "$sp/notes/verification/reports/opponent-findings-review.md"
  okround "$sp/notes/opponent.md"
  say "  $f: PRE $(vfr PRE C "$sp") | REV $(vfr REV C "$sp") | CUR $(vfr CUR C "$sp")"
}
sed -n '1258,1292p' "$R/CUR/$s/notes/opponent.md" | bcase o017-block
printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Follow-up\n- T030o43 fixes the **Severity:** handling\n- **T001** — fix it; its **Severity:** stays data-loss\n' | bcase trailing-section
printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n- **Scenario:** the **Class:** field was lost; a field line written `-\302\240**Class:**` was skipped\n- **Class-wide fix:** make every `**Severity:**` line parse\n' | bcase prose-mention
printf '## Findings\n\n### Finding O-017\n- **Class:** harness-locale-decoding\n' | bcase class-only
printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Finding summary\nOne finding.\n\n```text\n- **Severity:** minor\n```\n' | bcase finding-summary
for f in o017-block trailing-section prose-mention class-only finding-summary; do
  for l in "${LOCS[@]}"; do check "B $f D $l" 'rc=0 ' "$(vfr D "$l" "$R/b-$f")"; done
done
printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n- **Scenario:** the line\n\n      - **Severity:** minor\n\n  was quoted\n' | bcase indented-code
for l in "${LOCS[@]}"; do has "B indented-code D $l" "$PARSE" "$(vfr D "$l" "$R/b-indented-code")"; done

say '== C: canonical report fields and sections'
cp_i=0
for ch in "${WS19[@]}"; do
  cp_i=$((cp_i+1)); sp="$R/c-sec-$cp_i"; mkdir -p "$sp/notes"
  round "$sp/notes/opponent.md" CHALLENGED tier-binding new wrong-result 1 0
  sed "s/^Manifest tier binding\.\$/$ch/" "$sp/notes/opponent.md" > "$sp/o" && mv "$sp/o" "$sp/notes/opponent.md"
  for l in "${LOCS[@]}"; do has "C section-body ws-$cp_i D $l" 'empty required report section: what i attacked' "$(vfr D "$l" "$sp")"; done
done
for field in Scenario Reproduced 'Wrong behavior' 'Class-wide fix' Prior; do
  sp="$R/c-field-${field// /-}"; mkdir -p "$sp/notes"
  round "$sp/notes/opponent.md" CHALLENGED tier-binding new wrong-result 1 0
  awk -v f="- **$field:**" -v nb="$NB" 'index($0, f) == 1 {print f " " nb; next} {print}' "$sp/notes/opponent.md" > "$sp/o" && mv "$sp/o" "$sp/notes/opponent.md"
  for l in "${LOCS[@]}"; do has "C field $field U+00A0 D $l" 'incomplete finding G-042' "$(vfr D "$l" "$sp")"; done
done
sp="$R/c-class-nbsp"; mkdir -p "$sp/notes"
round "$sp/notes/opponent.md" CHALLENGED tier-binding new wrong-result 1 0
awk -v nb="$NB" 'index($0, "- **Class:**") == 1 {sub(/^- /, "-" nb)} {print}' "$sp/notes/opponent.md" > "$sp/o" && mv "$sp/o" "$sp/notes/opponent.md"
for l in "${LOCS[@]}"; do has "C canonical Class line after a U+00A0 D $l" 'incomplete finding G-042' "$(vfr D "$l" "$sp")"; done
fence_probe() { bash -c 'cd "$1" && . scripts/verification-lib.sh && printf "\302\240\140\140\140\n" | awk "$_VF_AWK_TEXT"'"'"'{print "mapped=" vf_fence($0) " written=" vf_fence(vf_original)}'"'"'' _ "$R/$1"; }
check 'C fence state D: mapped line == line as written' 'mapped=0 written=0' "$(fence_probe D)"

say '== D: the Decisions section in the input identity (R2-F1)'
sem() { bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_semantic_file .specify/specs/x/STATUS.md "$2" "$3"' _ "$R/$1" "$2" "$3"; }
auth() { local d="$w/authspec"; rm -rf "$d"; mkdir -p "$d"; cp "$2" "$d/STATUS.md"
  bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_round_authorized "$2" opponent 4 2026-09-27T00:00:00Z' _ "$R/$1" "$d" > /dev/null 2>&1; printf '%s' "$?"; }
WAIVER='- 2026-09-27T15:55:36Z — waiver: gate=opponent; round=4; after=3; by=someone; reason=a reason'
status_pair() {
  local pre='' post='' log_head='## Decisions log'
  case "$1" in
    fenced-earlier) pre=$'## Where things stand\n\n```text\n## Decisions log\n```\n';;
    archived-earlier) pre=$'## Decisions log (archived, spec 001)\n\n- 2026-01-01 — old\n';;
    duplicate-later) post=$'## Open questions / blockers\n\n- none\n\n## Decisions log\n\n- 2026-09-06 — second section\n';;
    fenced-round-inside) ;;
    heading-nbsp) log_head="## Decisions log$NB";;
  esac
  for v in a b; do
    {
      printf -- '---\nspec: x\n---\n\n%s\n' "$pre"
      printf '%s\n\n- 2026-09-06 — one decision\n' "$log_head"
      [[ "$1" == fenced-round-inside ]] && printf -- '- 2026-09-06 — quoting a report:\n\n```text\n## Round 3\n```\n\n'
      if [[ "$1" != duplicate-later && "$v" == b ]]; then printf '%s\n' "$WAIVER"; fi
      printf '\n%s' "$post"
      if [[ "$1" == duplicate-later && "$v" == b ]]; then printf '%s\n' "$WAIVER"; fi
      [[ "$1" == duplicate-later ]] || printf '\n## Open questions / blockers\n\n- none\n'
    } > "$w/s$v.md"
  done
}
for shape in fenced-earlier archived-earlier duplicate-later fenced-round-inside heading-nbsp; do
  status_pair "$shape"; sem D "$w/sa.md" "$w/sa.D"; sem D "$w/sb.md" "$w/sb.D"
  cmp -s "$w/sa.D" "$w/sb.D" && id=same || id=differ
  check "D $shape: D identity differs" differ "$id"
done

say '== E: task bindings (the v1 fixture spec of tests/helpers.sh)'
fixture() { mkdir -p "$w/fx-$1"; bash -c 'cd "$1" && SANDBOX="$2" && . tests/helpers.sh && make_verification_spec_dir "$3"' _ "$R/$1" "$w/fx-$1" "$2"; }
bind() { # kit locale spec -> rc and the first diagnostic
  inloc "$2" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_bindings "$2" tasks "" "$3"' _ "$R/$1" "$3" "$w/cat.nul" > /dev/null 2> "$w/be"
  printf 'rc=%s %s' "$?" "$(grep -m1 -E 'manual Verify|placeholder|Verify must|no matching|error' "$w/be" | LC_ALL=C sed 's/\x0b/<VT>/g' | cut -c1-140)"
}
edit() { perl -e 'local $/; my ($f,$o,$n)=@ARGV; open my $h,"<",$f or exit 3; my $t=<$h>; close $h; my $c=($t =~ s/\Q$o\E/$n/); exit 4 if $c!=1; open $h,">",$f or exit 3; print $h $t; close $h' "$@"; }
sp="$(fixture D base)"; edit "$sp/tasks.md" '`manual: inspect the release artifact and record its digest`' "\`manual: $NB\`"
for l in "${LOCS[@]}"; do has "E manual observation U+00A0 D $l" 'manual Verify must be manual: <observation>' "$(bind D "$l" "$sp")"; done
sp="$(fixture D ph)"; edit "$sp/plan.md" '| manual-family | manual | AC-004 | release-observation |' "| manual-family | manual | AC-004 | $NB |"; edit "$sp/tasks.md" '  - *Tests:* release-observation' "  - *Tests:* $NB"
for l in "${LOCS[@]}"; do has "E placeholder U+00A0 D $l" 'placeholder' "$(bind D "$l" "$sp")"; done
cmd_written="grep -c 'a${NB}b' tests/check.sh"
vcmd() { bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_bindings "$2" tasks "" "$3" 2>/dev/null && vf_task_info "$3" T001 && printf "%s" "$VF_TASK_COMMAND"' _ "$R/$1" "$2" "$w/vc.nul"; }
sp="$(fixture D vc)"; edit "$sp/tasks.md" '`bash tests/check.sh` → passed' "\`$cmd_written\` → passed"
check 'E D runs the Verify command as written' "$cmd_written" "$(vcmd D "$sp")"
sp="$(fixture D lead)"; edit "$sp/tasks.md" '  - *Verify:* `bash tests/check.sh` → passed' "  - *Verify:*$NB\`bash tests/check.sh\` → passed"
check 'E leading U+00A0 before the Verify backticks D' 'bash tests/check.sh' "$(vcmd D "$sp")"
for k in CUR D; do sp="$(fixture "$k" plain)"; eval "fxplain_$k=\$sp"; done
check 'E the unedited fixture binds in D' 'rc=0 ' "$(bind D C "$fxplain_D")"

say '== F: frontmatter and contract routing'
fmv() { bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_fm_value "$2" "$3"' _ "$R/$1" "$2" "$3"; }
printf -- '---\nspec: x\nworktree: /tmp/My%sProjects/wt\nbranch: spec/x # the branch\nverification_contract:%s1\n---\n' "$NB" "$NB" > "$w/fm.md"
check 'F D worktree value is the path as written' "/tmp/My${NB}Projects/wt" "$(fmv D "$w/fm.md" worktree)"
check 'F D a U+00A0 after the contract colon reads as 1' 1 "$(fmv D "$w/fm.md" verification_contract)"
check 'F D an inline comment is dropped' 'spec/x' "$(fmv D "$w/fm.md" branch)"
route() {
  local d="$w/route/.specify/specs/099-r"; rm -rf "$w/route"; mkdir -p "$d"
  printf -- '---\nspec: 099-r\n%s---\n\n- AC-001: x\n' "$3" > "$d/spec.md"
  printf -- '---\nspec: 099-r\n---\n\n## Backend\n\n- [x] **T001** — x\n  - *Acceptance:* x\n  - *Evidence:* prose\n' > "$d/tasks.md"
  case "$2" in
    spec-evidence) ( cd "$R/$1" && bash scripts/spec-evidence.sh "$d" ) > "$w/ro" 2>&1;;
    spec-task) ( cd "$R/$1" && bash scripts/spec-task.sh list "$d" ) > "$w/ro" 2>&1;;
    spec-run) ( cd "$R/$1" && bash scripts/spec-run.sh "$d" T001 --no-tick -- true ) > "$w/ro" 2>&1;;
  esac
  printf 'exit=%s %s' "$?" "$(grep -m1 'unsupported' "$w/ro" || tail -1 "$w/ro")"
}
for v in 'verification_contract:\n' 'verification_contract: ""\n' "verification_contract: ''\n" 'verification_contract: 2\n' 'verification_contract: 1\nverification_contract: 1\n'; do
  for script in spec-evidence spec-task spec-run; do
    has "F D $script refuses [$(printf '%b' "$v" | tr '\n' '|')]" 'exit=3 unsupported verification contract' "$(route D "$script" "$(printf '%b' "$v")")"
  done
done
check 'F D spec-task lists a legacy spec' $'exit=0 T001\tdone\tBackend\tx' "$(route D spec-task '')"

say '== G: legacy evidence and artifact names (spec-evidence.sh is unchanged; D kernel)'
lg="$w/legacy"; mkdir -p "$lg/shots"; : > "$lg/shots/a.png"; : > "$lg/shots/écran.png"
printf -- '---\nspec: 001-legacy\n---\n\n- AC-001: x\n' > "$lg/spec.md"
ev() { printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — x\n  - *Acceptance:* x\n  - *Evidence:* %s\n' "$3" > "$lg/tasks.md"
  ( cd "$lg" && inloc "$2" bash "$R/$1/scripts/spec-evidence.sh" "$lg" ) > "$w/ev" 2>&1; printf 'exit=%s' "$?"; }
evcase() { local l; for l in "${LOCS[@]}"; do has "G $1 D $l" "exit=$2" "$(ev D "$l" "$3")"; done; }
evcase nbsp-only 1 "$NB"
evcase nbsp-separated 0 "screenshot${NB}shots/a.png"
evcase em-space-separated 0 $'screenshot\342\200\203shots/a.png'
evcase curly-quoted 0 $'\342\200\234shots/a.png\342\200\235'
evcase missing-accented 1 'screenshot shots/café.png'
evcase existing-accented 0 'screenshot shots/écran.png'
evcase glob-not-a-pattern 1 'screenshot shots/*.png'

say '== H: the analyzer'"'"'s gate Agent path'
sp="$(fixture D agent)"; edit "$sp/tasks.md" '  - *Agent:* agents/opponent.agent.md' "  - *Agent:* ${NB}agents/opponent.agent.md"
an() { ( cd "$R/$1" && inloc "$2" bash scripts/sdd-analyze.sh "$3" ) > "$w/an" 2>&1; printf 'exit=%s %s' "$?" "$(grep -m1 'opponent gate' "$w/an")"; }
for l in "${LOCS[@]}"; do has "H agent path after a U+00A0 D $l" 'opponent gate present, agent file exists' "$(an D "$l" "$sp")"; done

SEC=K; say '== K: review 3 (t030o43-review3.md), intended results in D'
H='# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n'
say '  -- R3-F1: a field value is the text after its own label only'
manifest_case f1-sev-then-prior 'a Severity this grammar cannot read' '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss; **Prior:** minor\n'
manifest_case f1-sev-minor-then-dl 'a Severity this grammar cannot read' '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor; **Prior:** data-loss\n'
manifest_case f1-class-then-status 'a Class this grammar cannot read' '# P\n\n### Finding G-042\n- **Class:** tier-binding; **Status:** open\n- **Severity:** data-loss\n'
sp="$R/k-canon-sev"; mkdir -p "$sp/notes"
round "$sp/notes/opponent.md" CLEARED tier-binding open minor 0 1
edit "$sp/notes/opponent.md" '- **Severity:** minor' '- **Severity:** data-loss; **Prior:** minor'
say "  canonical Severity with a second label: CUR $(vfr CUR C "$sp")"
for l in "${LOCS[@]}"; do has "K canonical Severity carrying a second label is refused D $l" 'unknown severity' "$(vfr D "$l" "$sp")"; done
say '  -- R3-F2: a field is decided by its label'
while IFS='|' read -r label tail; do
  manifest_case "f2-$label" 'a Severity line this grammar cannot read' "$H$tail"
done <<CASES
space-colon|- **Severity :** data-loss\n
nbsp-colon|- **Severity${NB}:** data-loss\n
nnbsp-colon|- **Severity${NNB}:** data-loss\n
bold-space-colon|- **Severity** : data-loss\n
emdash|- **Severity** — data-loss\n
fullwidth-colon|- **Severity：** data-loss\n
ordered|1. **Severity:** data-loss\n
nocolon|- **Severity** data-loss\n
CASES
say '  -- R3-F3: a Finding line not read as a heading is refused by name'
for v in "nbsp-after|###${NB}Finding G-042" "tab-before|\t### Finding G-042" "zwsp-before|${ZW}### Finding G-042" "nbsp-before|${NB}### Finding G-042" "no-space|###Finding G-042" "indented-4|    ### Finding G-042"; do
  manifest_case "f3-${v%%|*}" 'a Finding heading this grammar cannot read' "# P\n\n### Finding G-041\n- **Class:** other-class\n${v#*|}\n- **Severity:** data-loss\n"
done
manifest_case f3-readable-control 'finding G-042 has no readable Class' '# P\n\n### Finding G-041\n- **Class:** other-class\n### Finding G-042\n- **Severity:** data-loss\n'
say '  -- R3-F5: prose that starts Class: or Severity: outside any finding, with no finding ID after the last heading'
B='### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
for c in "summary|# Prior review\n\n$B\n## Summary\n\n- Class: tier-binding, one finding\n- Severity: all blocking\n" "intro|# Prior review\n\nSeverity: every finding below is blocking.\n\n$B"; do
  sp="$R/k-f5-${c%%|*}"; mkdir -p "$sp/notes/verification/reports"; printf '%b' "${c#*|}" > "$sp/notes/verification/reports/opponent-findings-review.md"
  round "$sp/notes/opponent.md" CHALLENGED tier-binding open data-loss 1 0
  say "  f5-${c%%|*}: REV $(vfr REV C "$sp") | CUR $(vfr CUR C "$sp")"
  for l in "${LOCS[@]}"; do check "K f5-${c%%|*} parses D $l" 'rc=0 ' "$(vfr D "$l" "$sp")"; done
done
sp="$R/k-f5-nested"; mkdir -p "$sp/notes/verification/reports"
printf '%b' "# Prior review\n\n$B- **Scenario:** the tier moved\n  - Severity: raised from minor after the repro\n" > "$sp/notes/verification/reports/opponent-findings-review.md"
round "$sp/notes/opponent.md" CHALLENGED tier-binding open data-loss 1 0
for l in "${LOCS[@]}"; do has "K f5-nested stays refused inside a finding (it may be the tier) D $l" 'a second Severity line in finding G-042' "$(vfr D "$l" "$sp")"; done
say '  -- R3-F5 guard: an outside line is refused once a finding ID has appeared after the last heading (R2-F2 combinations)'
manifest_case f5g-word-before-unbolded 'a class line outside any Finding' '### Opponent finding G-042\n- Class: tier-binding\n- Severity: data-loss\n'
manifest_case f5g-bold-pseudo-heading 'a severity line outside any Finding' '# P\n\n## Summary\n\n**Finding G-042**\n- Severity: data-loss\n'
manifest_case f5g-colon-heading 'a class line outside any Finding' '### Finding: G-042\n- Class: tier-binding\n- Severity: data-loss\n'
manifest_case f5g-id-on-the-line 'a severity line outside any Finding' '## Summary\n\n- Severity: data-loss (G-042)\n'
say '  -- R3-F4: every value passed on is taken as written'
rv4() { # kit snippet -> output
  inloc C bash -c 'SANDBOX="$(mktemp -d "$TMPDIR/sb.XXXXXX")"; export SANDBOX; . "$1/tests/helpers.sh"
    SCRIPTS="$2/scripts"; ANALYZE="$SCRIPTS/sdd-analyze.sh"; . "$3"; rm -rf "$SANDBOX"' _ "$R/CUR" "$R/$1" "$2" 2>&1 | tr '\n' '|'
}
RP="$WT/$r/t030o43-review3-repro"
out="$(rv4 D "$RP/loc.snip")"; has 'K F4 locator: bindings and locators pass in D' 'bindings rc=0$|locators rc=0$' "$out"; has 'K F4 locator: the catalog holds it as written in D' 'my\302\240check.sh' "$out"
has 'K F4 manual observation name equals the return in D' 'names EQUAL' "$(rv4 D "$RP/man-obs.snip")"
cat > "$w/more.snip" <<'SNIP'
spec_dir="$(make_verification_spec_dir moreproj)"; nb=$'\302\240'
# T001 with a U+00A0 after each comma of its Refs, a Files entry ending "<U+00A0>(new)", a Tests
# locator after a U+00A0, and its stage heading written "##<U+00A0>Backend<U+00A0>": no false refusal.
perl -0pi -e 's/\Q  - *Refs:* REQ-001, AC-001, FM-001\E/  - *Refs:* REQ-001,\xc2\xa0AC-001,\xc2\xa0FM-001/; s/\Q  - *Files:* `src\/parser.sh`, `tests\/check.sh`\E/  - *Files:* `src\/parser.sh`, `tests\/check.sh`, `tests\/extra.sh`\xc2\xa0(new)/; s/\Q  - *Tests:* `tests\/check.sh::test_ac_001_shared`\E/  - *Tests:*\xc2\xa0`tests\/check.sh::test_ac_001_shared`/; s/^## Backend$/##\xc2\xa0Backend\xc2\xa0/m' "$spec_dir/tasks.md"
grep -c $'\302\240' "$spec_dir/tasks.md" | sed 's/^/nbsp-lines=/'
bash -c '. "$1/verification-lib.sh"; vf_bindings "$2" tasks "" "$3"; echo "bindings rc=$?"; vf_task_info "$3" T001 && printf "stage=[%s] tests=[%s]\n" "${VF_TASK[3]}" "${VF_TASK[7]}"' _ "$SCRIPTS" "$spec_dir" "$SANDBOX/m.nul" 2>&1 | LC_ALL=C sed -n l | head -8
SNIP
out="$(rv4 D "$w/more.snip")"; say "  more: CUR $(rv4 CUR "$w/more.snip") | D $out"
has 'K F4 the edits applied' 'nbsp-lines=4' "$out"
has 'K F4 Files, Refs and a stage written with U+00A0 bind in D' 'bindings rc=0' "$out"
has 'K F4 the stage is its text as written, trimmed' 'stage=[Backend]' "$out"
say '  -- R3-F8: a matrix criterion cell copied as the spec writes it equals the catalog'
mx="$w/f8"; mkdir -p "$mx"; printf -- '---\nspec: x\n---\n\n- AC-001 — one%scriterion\n' "$NB" > "$mx/spec.md"
mxcase() { # kit cell -> EQUAL/DIFFER
  rm -f "$mx/acs" "$mx/m"; bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_ac_catalog "$2" "$2/acs"' _ "$R/$1" "$mx"
  local text dig got; text="$(tr '\0' '\n' < "$mx/acs" | sed -n 2p)"; dig="$(tr '\0' '\n' < "$mx/acs" | sed -n 3p)"
  printf '| AC-001 | %s; sha256:%s | CAP-1; review: x | %s | PASS |\n' "$2" "$dig" aaaa > "$mx/block"
  bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_matrix_parse "$2/block" "$2/m"' _ "$R/$1" "$mx"
  got="$(tr '\0' '\n' < "$mx/m" | sed -n 2p)"; [[ "$got" == "$text; sha256:$dig" ]] && echo EQUAL || echo DIFFER
}
check 'K F8 a cell written with the U+00A0 equals the catalog in D' EQUAL "$(mxcase D "one${NB}criterion")"
check 'K F8 a cell written with an ASCII space equals the catalog in D' EQUAL "$(mxcase D 'one criterion')"
check 'K F8 a cell with two spaces equals the catalog in D' EQUAL "$(mxcase D 'one  criterion')"
say '  -- R3-F11: a checkpoint stage written with a trailing U+00A0 or space, end to end through through-stage'
out="$(rv4 D "$RP/stage.snip")"; say "  D: $out"
has 'K F11 U+00A0 suffix: config and through-stage pass in D' '302 240 ] config rc=0 | through-stage rc=0' "$out"
has 'K F11 ASCII space suffix: config and through-stage pass in D' 'suffix= ] config rc=0 | through-stage rc=0' "$out"
say '  -- R3-F6: no member splits a mapped line by default field splitting (static, D)'
dfs="$(grep -c -E 'fid=\$3|n=\$3;|wantb=\$2|&& NF \{' "$R/D/scripts/verification-lib.sh")"
check 'K F6 the four default-split sites are gone from D' 0 "$dfs"
sp="$R/k-f6"; mkdir -p "$sp/notes"; round "$sp/notes/opponent.md" CHALLENGED tier-binding new wrong-result 1 0
edit "$sp/notes/opponent.md" '### Finding G-042' "### Finding G-042${NB}"
for l in "${LOCS[@]}"; do has "K F6 a heading ID followed by a U+00A0 stays refused in D $l" "incomplete finding G-042${NB}" "$(vfr D "$l" "$sp")"; done

say '== I/L: recorded history, D against CUR'
nbsp_files="$(cd "$R/CUR" && git ls-files -z -- '.specify/specs/*/spec.md' '.specify/specs/*/plan.md' '.specify/specs/*/tasks.md' \
  '.specify/specs/*/STATUS.md' '.specify/specs/*/notes/opponent.md' '.specify/specs/*/notes/reality-check.md' \
  '.specify/specs/*/notes/verification/reports/*-findings-*.md' .specify/stack.yml 'templates/*' | xargs -0 perl -ne 'if (/\xc2[\x85\xa0]|\xe1\x9a\x80|\xe2\x80[\x80-\x8a\xa8\xa9\xaf]|\xe2\x81\x9f|\xe3\x80\x80/) { print "$ARGV\n"; close ARGV }' | LC_ALL=C sort -u | tr '\n' ' ')"
check 'I no file a parser of author text reads holds a non-ASCII White_Space character' '' "$nbsp_files"
SPECS=(001-codex-subagent-gates-and-hard-task-escalation 002-usage-limit-handling-for-dispatched-runs 003-gate-round-reduction-and-token-discipline)
same() { # label cmd... run in CUR and D, compare normalized output+rc
  local label="$1" k; shift
  for k in CUR D; do ( cd "$R/$k" && "$@" ) > "$w/h-$k" 2>&1; echo "rc=$?" >> "$w/h-$k"; LC_ALL=C sed -e "s#$R/$k#KIT#g" -e "s#$TMPDIR/[^ /:]*#TMP#g" "$w/h-$k" > "$w/h-$k.n"; done
  if cmp -s "$w/h-CUR.n" "$w/h-D.n"; then say "PASS I $label identical ($(tail -1 "$w/h-D.n"))"; passes=$((passes+1)); else say "FAIL I $label differs"; diff "$w/h-CUR.n" "$w/h-D.n" | head -8 | sed 's/^/  | /'; fails=$((fails+1)); fi
}
for spec in "${SPECS[@]}"; do
  sd=".specify/specs/$spec"
  for l in "${LOCS[@]}"; do
    same "${spec:0:3} tally $l" inloc "$l" bash scripts/spec-gate.sh tally "$sd"
    same "${spec:0:3} sdd-analyze $l" inloc "$l" bash scripts/sdd-analyze.sh "$sd"
    same "${spec:0:3} spec-ac-coverage $l" inloc "$l" bash scripts/spec-ac-coverage.sh "$sd"
    [[ "$spec" == 003-* ]] || same "${spec:0:3} spec-evidence $l" inloc "$l" bash scripts/spec-evidence.sh "$sd"
    same "${spec:0:3} spec-task list $l" inloc "$l" bash scripts/spec-task.sh list "$sd"
  done
  for phase in plan tasks; do
    same "${spec:0:3} vf_bindings $phase catalog" bash -c '. scripts/verification-lib.sh; rm -f "$2"; vf_bindings "$1" "$3" "" "$2"; rc=$?; tr "\0" "\n" < "$2" 2>/dev/null; exit $rc' _ "$sd" "$w/bc.nul" "$phase"
  done
  same "${spec:0:3} vf_config stage map" bash -c '. scripts/verification-lib.sh; rm -rf "$2"; vf_config .specify/stack.yml "$1/tasks.md" "$2"; rc=$?; cat "$2"/*.nul 2>/dev/null | tr "\0" "\n"; exit $rc' _ "$sd" "$w/cfg"
  for g in opponent reality-check; do
    f="$sd/notes/$g.md"; [[ -f "$R/CUR/$f" ]] || continue
    # R3-F1 anchors the canonical value on the line's first bold label, so a
    # free-text Scenario or Reproduced value that QUOTES a bold label is now the
    # whole text, where the greedy reading kept only what followed the last
    # quoted label. No catalog reader reads those two fields (vf_tally reads the
    # type, ID, Class, status, Prior, severity and Where). So: every other field
    # identical, and each differing Scenario/Reproduced value in CUR a strict
    # suffix of D's.
    for k in CUR D; do
      ( cd "$R/$k" && bash -c '. scripts/verification-lib.sh; rm -f "$3"; vf_reports "$1" "$2" "$3" "$4"' _ "$f" "$g" "$w/rc-$k.nul" "$sd" ) > "$w/rc-$k.err" 2>&1; echo "rc=$?" >> "$w/rc-$k.err"
      tr '\0' '\n' < "$w/rc-$k.nul" | paste -d '\t' - - - - - - - - - - - - > "$w/rc-$k.tsv"
    done
    check "I ${spec:0:3} vf_reports $g: status and diagnostics identical" "$(cat "$w/rc-CUR.err")" "$(cat "$w/rc-D.err")"
    check "I ${spec:0:3} vf_reports $g: every field but Scenario and Reproduced identical" "$(cut -f1-9,12 "$w/rc-CUR.tsv" | shasum)" "$(cut -f1-9,12 "$w/rc-D.tsv" | shasum)"
    sfx="$(paste "$w/rc-CUR.tsv" "$w/rc-D.tsv" | awk -F '\t' '{for (i=10;i<=11;i++) if ($i != $(i+12)) {n++; c=$i; d=$(i+12); if (length(c) >= length(d) || substr(d, length(d)-length(c)+1) != c) bad++}} END {printf "%d differ, %d not a suffix", n, bad}')"
    say "  ${spec:0:3} $g Scenario/Reproduced values: $sfx"
    case "$sfx" in *", 0 not a suffix") check "I ${spec:0:3} vf_reports $g: every differing free-text value was a suffix of the anchored one" ok ok;; *) check "I ${spec:0:3} vf_reports $g: every differing free-text value was a suffix of the anchored one" ok "$sfx";; esac
  done
done
same '003 reality-check round-1 matrix cells' bash -c '. scripts/verification-lib.sh; vf_report_block "$1" 1 > "$2.b" && vf_matrix_parse "$2.b" "$2"; rc=$?; tr "\0" "\n" < "$2"; exit $rc' _ "$s/notes/reality-check.md" "$w/mx.nul"
same 'round-13 waiver' bash scripts/spec-gate.sh waiver "$s" opponent 13
same 'round-14 refusal' bash scripts/spec-gate.sh waiver "$s" opponent 14
for k in CUR D; do
  : > "$w/semviews-$k"
  while IFS= read -r st; do
    bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_semantic_file "$2" "$2" "$3"' _ "$R/$k" "$st" "$w/sv"
    printf '%s %s\n' "$st" "$(shasum -a 256 < "$w/sv" | cut -c1-64)" >> "$w/semviews-$k"
  done < <(cd "$R/$k" && git ls-files | grep -E '^\.specify/specs/[^/]+/STATUS\.md$')
done
check 'I every STATUS semantic view D == CUR' "$(cat "$w/semviews-CUR")" "$(cat "$w/semviews-D")"
for k in CUR D; do for l in "${LOCS[@]}"; do
  inloc "$l" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_snapshot "$2" "$1" "$1" "$3"' _ "$R/$k" "$s" "$w/in-$k-$l.nul" > "$w/digest-$k-$l"
  tr '\0' '\n' < "$w/in-$k-$l.nul" | paste - - - - - - | sed "s#$R/$k#KIT#g" | LC_ALL=C grep -v -E $'^(version|harness)\t|^(path|index)\tscripts/(verification-lib|sdd-analyze|spec-task)\\.sh\t' > "$w/rec-$k-$l"
done; done
check 'I snapshot records outside the edited files and harness records: D == CUR (C)' "$(shasum < "$w/rec-CUR-C")" "$(shasum < "$w/rec-D-C")"
check 'I snapshot records outside the edited files and harness records: D == CUR (en_US.UTF-8)' "$(shasum < "$w/rec-CUR-en_US.UTF-8")" "$(shasum < "$w/rec-D-en_US.UTF-8")"
check 'I the D snapshot is one digest in both locales' "$(cat "$w/digest-D-C")" "$(cat "$w/digest-D-en_US.UTF-8")"
say "  records compared: $(wc -l < "$w/rec-D-C" | tr -d ' ')"
say '  -- the manifest pass over every recorded notes/*.md and every real manifest, read as a manifest: D against CUR'
mpass() { # kit file -> records and diagnostics of the manifest pass alone
  local d="$w/mp"; rm -rf "$d"; mkdir -p "$d/notes/verification/reports"; cp "$2" "$d/notes/verification/reports/opponent-findings-x.md"
  printf '## Round 1\n' > "$d/notes/opponent.md"
  : > "$w/mp.rec"
  MP_OUT="$w/mp.nul" MP_REC="$w/mp.rec" bash -c 'cd "$1" && . scripts/verification-lib.sh
    sort() { local last="${*: -1}"; [[ "$last" == "$MP_OUT".* ]] && cat "$last" >> "$MP_REC"; command sort "$@"; }
    vf_reports "$2/notes/opponent.md" opponent "$3" "$2"' _ "$R/$1" "$d" "$w/mp.nul" 2>&1 | grep -E '^manifest line|could not be parsed' | sed "s#$d#MP#g"
  sed 's/^/record /' "$w/mp.rec"
}
mdiff=0; mfiles=0
while IFS= read -r f; do
  mfiles=$((mfiles+1))
  a="$(mpass CUR "$R/CUR/$f")"; b="$(mpass D "$R/D/$f")"
  if [[ "$a" != "$b" ]]; then mdiff=$((mdiff+1)); say "  differs: $f"; diff <(printf '%s\n' "$a") <(printf '%s\n' "$b") | head -6 | cut -c1-200 | sed 's/^/  | /'; fi
done < <(cd "$R/CUR" && git ls-files | grep -E '^\.specify/specs/[^/]+/notes/[^/]+\.md$|^\.specify/specs/[^/]+/notes/verification/reports/[^/]*-findings-[^/]*\.md$')
say "  manifest pass: $mfiles files, $mdiff differ"
say '  -- review 3'"'"'s field-rule measurement (hist-fieldrule.sh), with the emphasized-label trigger added: lines made candidates that are not canonical field lines'
extra="$(cd "$R/CUR" && for f in .specify/specs/*/notes/*.md .specify/specs/*/notes/verification/reports/*-findings-*.md; do LC_ALL=C awk -v F="$f" '
{ t=$0; sub(/^[[:space:]]+/, "", t)
  if (t ~ /^([-*+]|[0-9]+[.)])[[:space:]]/) sub(/^([-*+]|[0-9]+[.)])[[:space:]]+/, "", t)
  emph=(t ~ /^[*_]/); sub(/^[*_]+/, "", t)
  if (!match(t, /^[A-Za-z]+/)) next
  w=tolower(substr(t,1,RLENGTH)); if (w!="class" && w!="severity") next
  r=substr(t,RLENGTH+1)
  if (!(emph && r ~ /^[*_]/)) { sub(/^[*_[:space:]]+/, "", r); if (r ~ /^[A-Za-z0-9-]/) next }
  if ($0 ~ /^[ ]*-[[:space:]]+\*\*(Class|Severity):\*\*/) next
  print F ":" NR ": " substr($0,1,140) }' "$f"; done)"
say "$(printf '%s\n' "$extra" | head -20 | sed 's/^/  | /')"
check 'L the field rule makes no recorded line a candidate that is not a canonical field line' 0 "$(printf '%s' "$extra" | grep -c . )"

say '== J: review 1 F3 (the return size read) is unchanged'
{ printf 'Verification-Return: 1\nTask: T001\nCaptures: CAP-1-abcdef\nSummary: x\nFailure modes: none\n'; head -c 70000 /dev/zero | tr '\000' 'x'; printf '\n'; } > "$w/big.txt"
mkdir -p "$w/fwc"; printf '#!/bin/bash\nfor a in "$@"; do [[ "$a" == -c ]] && { echo "wc: injected fault" >&2; exit 2; }; done\nexec /usr/bin/wc "$@"\n' > "$w/fwc/wc"; chmod +x "$w/fwc/wc"
has 'J D a wc fault is refused by name' 'return: its size could not be read' "$(env PATH="$w/fwc:$PATH" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_return_parse "$2" "$3"' _ "$R/D" "$w/big.txt" "$w/big.nul" 2>&1)"

say '== M: R3-F6 on Linux mawk, D kit, in the approved throwaway container (localstack/localstack:3.8.1, --rm, --network none)'
if command -v docker > /dev/null 2>&1 && docker image inspect localstack/localstack:3.8.1 > /dev/null 2>&1; then
  cat > "$w/m.sh" <<'PROBE'
K=/kit; W=/work; export TMPDIR=$W/tmp; mkdir -p $TMPDIR; NB=$'\302\240'; SRC="$(printf 'a%.0s' {1..64})"
for c in "control|### Finding G-042|**Blocking:** 1 · **Minor:** 0" "id-nbsp|### Finding G-042${NB}|**Blocking:** 1 · **Minor:** 0" "totals-nbsp|### Finding G-042|**Blocking:**${NB}1 · **Minor:** 0"; do
  IFS='|' read -r label head tot <<< "$c"; d=$W/$label; mkdir -p $d/notes
  printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CHALLENGED\n%s\n### What I attacked\nx\n%s\n- **Class:** tier-binding\n- **Status:** open\n- **Prior:** none\n- **Severity:** data-loss\n- **Scenario:** s\n- **Where:** scripts/run.sh:9\n- **Reproduced:** r\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** w\n- **Class-wide fix:** f\n### Held up / follow-up tasks\nh\n<!-- gate-round-end: opponent:1 -->\n' "$SRC" "$tot" "$head" > $d/notes/opponent.md
  out="$(bash -c '. "$1/scripts/verification-lib.sh"; vf_reports "$2/notes/opponent.md" opponent "$3" "$2"' _ $K $d $W/o.nul 2>&1)"; rc=$?
  printf '%s rc=%s %s\n' "$label" "$rc" "$(printf '%s' "$out" | sed "s#$W/##g" | tr '\n' '|' | cut -c1-160)"
done
PROBE
  host="$(bash -c 'K="$1"; W="$2"; mkdir -p "$W"; sed -e "s#^K=/kit; W=/work;#K=$K; W=$W;#" "$3" > "$W.sh"; bash "$W.sh"' _ "$R/D" "$w/mh" "$w/m.sh" 2>&1)"
  cont="$(docker run --rm --network none -v "$R/D:/kit:ro" -v "$w/m.sh:/m.sh:ro" --tmpfs /work:exec --entrypoint /bin/bash localstack/localstack:3.8.1 /m.sh 2>&1)"
  say "  host:"; say "$(printf '%s\n' "$host" | sed "s#$w/mh/##g; s/^/  | /")"
  say "  container:"; say "$(printf '%s\n' "$cont" | sed 's/^/  | /')"
  check 'M D reads the three cases identically on macOS awk and Debian mawk' "$(printf '%s\n' "$host" | sed "s#$w/mh/##g")" "$cont"
else
  say "  SKIP: docker or the image is unavailable"
fi

check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$(livestate)"
say "t030o43-measure-9 passes=$passes failures=$fails"
if (( fails == 0 )); then rm -rf "$R"; else say "kept: $R"; fi
(( fails == 0 ))
