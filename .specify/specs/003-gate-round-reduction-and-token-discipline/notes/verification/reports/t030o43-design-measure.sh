#!/usr/bin/env bash
# T030o43, session 8 (2026-09-29): measure the class-wide whitespace design of
# review 2 (t030o43-review2-design.md, option 1) BEFORE adopting it. Read-only
# against the live worktree: four standalone kits, each a copy of the live
# manifest enumeration made its own git repository:
#   CUR  the tree as it is (the review-1 repair state)
#   PRE  the pre-delta files (t030o43-pre-rebuild-2.sh) laid over it
#   D    CUR plus the candidate (the pairs files in <edits>): the whitespace
#        step maps each non-ASCII White_Space character to VT
#   DS   the design exactly as written: D with the step mapping to an ASCII
#        space, and the Verify command and frontmatter values taken from the
#        mapped line; measured beside D to show where the two differ
# Every run removes every LC_* name and sets LANG. A line "PASS"/"FAIL" judges
# D (and, where named, DS or the history) against the intended result; the
# PRE/CUR columns are context.
# Usage: bash t030o43-design-measure.sh <scratchpad> <worktree> <edits-dir>
set -uo pipefail
SP="$1"; WT="$2"; E="$3"
R="$SP/t030o43-dm"; w="$R/work"
rm -rf "$R"; mkdir -p "$R" "$w" "$R/tmp"
export TMPDIR="$R/tmp"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
r="$s/notes/verification/reports"
fails=0
say() { printf '%s\n' "$*"; }
check() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=[$2] got=[$3])"; fails=$((fails+1)); fi; }
has() { case "$3" in *"$2"*) say "PASS $1";; *) say "FAIL $1 (want text [$2] in [$3])"; fails=$((fails+1));; esac; }
livestate() { ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignored -uall ) | LC_ALL=C grep -v -F " $s/notes/verification/" | shasum -a 256 | cut -c1-16; }
live_before="$(livestate)"
# The script's own tools read bytes; the kits run under inloc.
export LC_ALL=C
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
LOCS=(C en_US.UTF-8)

# --- kits --------------------------------------------------------------------
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) > "$R/src.tar" || { say 'FAIL enumerate'; exit 2; }
bash "$WT/$r/t030o43-pre-rebuild-2.sh" "$WT" "$R/prefiles" > "$R/pre-rebuild.log" 2>&1 || { say 'FAIL pre-rebuild'; cat "$R/pre-rebuild.log"; exit 2; }
for k in CUR PRE D DS; do
  mkdir -p "$R/$k" && ( cd "$R/$k" && tar -xf "$R/src.tar" ) || { say "FAIL copy $k"; exit 2; }
done
( cd "$R/prefiles" && find . -type f -print0 | tar --null -T - -cf - ) | ( cd "$R/PRE" && tar -xf - )
for p in kernel-5:scripts/verification-lib.sh sdd-analyze-2:scripts/sdd-analyze.sh spec-evidence-3:scripts/spec-evidence.sh \
         spec-run-2:scripts/spec-run.sh spec-task-2:scripts/spec-task.sh; do
  for k in D DS; do
    perl "$WT/$r/t030o43-edits/lit.pl" "$R/$k/${p#*:}" "$E/${p%%:*}.pairs" > /dev/null || { say "FAIL apply ${p%%:*} to $k"; exit 2; }
  done
done
# DS: the same step, mapping to an ASCII space.
perl -e 'local $/; my $f=shift; open my $h,"<",$f or exit 3; my $t=<$h>; close $h;
  my $n = ($t =~ s/(\\343\\200\\200\/, )"\\013"(, s\))/$1" "$2/); exit 4 if $n != 1;
  $n = ($t =~ s/set_field\("Verify",after_written\(vf_original,"Verify"\)\)/set_field("Verify",after(\$0,"Verify"))/); exit 5 if $n != 1;
  $n = ($t =~ s/v = vf_wstrim\(substr\(vf_original, length\(key\) \+ 2\)\)/v = vf_wstrim(substr(\$0, length(key) + 2))/); exit 6 if $n != 1;
  open $h,">",$f or exit 3; print $h $t; close $h' "$R/DS/scripts/verification-lib.sh" || { say 'FAIL DS mapping'; exit 2; }
for k in CUR PRE D DS; do
  ( cd "$R/$k" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid -c commit.gpgsign=false commit -qm base ) >/dev/null 2>&1 || { say "FAIL git $k"; exit 2; }
  for f in scripts/*.sh; do bash -n "$R/$k/$f" || { say "FAIL syntax $k $f"; fails=$((fails+1)); }; done
done
say "kits: CUR PRE D DS built; D edits applied"

NB=$'\302\240'
# The 19 non-ASCII White_Space characters, as UTF-8.
WS19=($'\302\205' $'\302\240' $'\341\232\200' $'\342\200\200' $'\342\200\201' $'\342\200\202' $'\342\200\203' $'\342\200\204'
      $'\342\200\205' $'\342\200\206' $'\342\200\207' $'\342\200\210' $'\342\200\211' $'\342\200\212' $'\342\200\250'
      $'\342\200\251' $'\342\200\257' $'\342\201\237' $'\343\200\200')
SRC="$(printf 'a%.0s' {1..64})"
round() { # file verdict class status sev blocking minor [scenario]
  printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nManifest tier binding.\n### Finding G-042\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n- **Scenario:** %s\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read the manifest\n### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n' \
    "$SRC" "$2" "$6" "$7" "$3" "$4" "$5" "${8:-a recorded trigger}" > "$1"
}
vfr() { # kit locale spec -> "rc=N first-diagnostic"
  inloc "$2" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2/notes/opponent.md" opponent "$3" "$2"' _ "$R/$1" "$3" "$w/out.nul" > /dev/null 2> "$w/e"
  printf 'rc=%s %s' "$?" "$(grep -v '^awk:\|^ source line\|^ context is\|^	' "$w/e" | sed 's/^report recovery: [^:]*: //' | sed -n '1p;$p' | tr '\n' '/' | cut -c1-300)"
}
LOWER='clearing verdict rests on 1 lowered severity tier'
PARSE='prior-review manifest could not be parsed'
manifest_case() { # label want-diagnostic manifest-body [round-args...]
  local label="$1" want="$2" body="$3" sp="$R/m-$1" l got; shift 3
  mkdir -p "$sp/notes/verification/reports"
  printf '%b' "$body" > "$sp/notes/verification/reports/opponent-findings-review.md"
  if (( $# )); then round "$sp/notes/opponent.md" "$@"; else round "$sp/notes/opponent.md" CLEARED tier-binding open minor 0 1; fi
  say "  $label: PRE-UTF8 $(vfr PRE en_US.UTF-8 "$sp") | CUR $(vfr CUR C "$sp")"
  for l in "${LOCS[@]}"; do got="$(vfr D "$l" "$sp")"; has "A $label D $l" "$want" "$got"; done
}
M='### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'

say '== A: prior-review manifest (a CLEARED round re-records G-042 open at minor; the manifest records data-loss)'
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
say '  -- a finding between two lines that begin with a U+00A0 and a fence run (not a fence to any reader)'
manifest_case nbsp-fence-pair "$LOWER" "${NB}\`\`\`\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n${NB}\`\`\`\n"
sp="$R/m-nbsp-fence-pair"; for l in "${LOCS[@]}"; do say "  nbsp-fence-pair DS $l: $(vfr DS "$l" "$sp")"; done
say '  -- every non-ASCII White_Space character after the dash of the Class line'
cp_i=0
for ch in "${WS19[@]}"; do
  cp_i=$((cp_i+1)); sp="$R/m-ws-$cp_i"; mkdir -p "$sp/notes/verification/reports"
  printf '### Finding G-042\n-%s**Class:** tier-binding\n- **Severity:** data-loss\n' "$ch" > "$sp/notes/verification/reports/opponent-findings-review.md"
  round "$sp/notes/opponent.md" CLEARED tier-binding open minor 0 1
  for l in "${LOCS[@]}"; do got="$(vfr D "$l" "$sp")"; has "A ws-$cp_i ($(printf '%s' "$ch" | od -An -tx1 | tr -d ' ')) D $l" "$LOWER" "$got"; done
done

say '== B: plausible manifests parse (a CHALLENGED round re-records O-017 at its manifest Class and tier: rc=0)'
okround() { printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CHALLENGED\n**Blocking:** 1 · **Minor:** 0\n### What I attacked\nx\n### Finding O-017\n- **Class:** harness-locale-decoding\n- **Status:** open\n- **Prior:** none\n- **Severity:** wrong-result\n- **Scenario:** s\n- **Where:** scripts/run.sh:9\n- **Reproduced:** r\n- **Root cause:** plan-gap\n- **Blocks:** AC-012\n- **Wrong behavior:** w\n- **Class-wide fix:** f\n### Held up / follow-up tasks\nh\n<!-- gate-round-end: opponent:1 -->\n' "$SRC" > "$1"; }
for f in o017-block trailing-section prose-mention class-only finding-summary; do
  sp="$R/b-$f"; mkdir -p "$sp/notes/verification/reports"
  case "$f" in
    o017-block) sed -n '1258,1292p' "$R/CUR/$s/notes/opponent.md" > "$sp/notes/verification/reports/opponent-findings-review.md";;
    trailing-section) printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Follow-up\n- T030o43 fixes the **Severity:** handling\n- **T001** — fix it; its **Severity:** stays data-loss\n' > "$sp/notes/verification/reports/opponent-findings-review.md";;
    prose-mention) printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n- **Scenario:** the **Class:** field was lost; a field line written `-\302\240**Class:**` was skipped\n- **Class-wide fix:** make every `**Severity:**` line parse\n' > "$sp/notes/verification/reports/opponent-findings-review.md";;
    class-only) printf '## Findings\n\n### Finding O-017\n- **Class:** harness-locale-decoding\n' > "$sp/notes/verification/reports/opponent-findings-review.md";;
    finding-summary) printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Finding summary\nOne finding.\n\n```text\n- **Severity:** minor\n```\n' > "$sp/notes/verification/reports/opponent-findings-review.md";;
  esac
  okround "$sp/notes/opponent.md"
  say "  $f: PRE $(vfr PRE C "$sp") | CUR $(vfr CUR C "$sp")"
  for l in "${LOCS[@]}"; do check "B $f D $l" 'rc=0 ' "$(vfr D "$l" "$sp")"; done
done
say '  -- the reviewer'"'"'s indented code example of a second Severity inside a finding: read as the canonical parser reads it, and refused as a second field'
sp="$R/b-indented-code"; mkdir -p "$sp/notes/verification/reports"
printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n- **Scenario:** the line\n\n      - **Severity:** minor\n\n  was quoted\n' > "$sp/notes/verification/reports/opponent-findings-review.md"
okround "$sp/notes/opponent.md"
for l in "${LOCS[@]}"; do has "B indented-code D $l" "$PARSE" "$(vfr D "$l" "$sp")"; done

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
  say "  field $field U+00A0: PRE-UTF8 $(vfr PRE en_US.UTF-8 "$sp") | CUR $(vfr CUR C "$sp")"
  for l in "${LOCS[@]}"; do has "C field $field D $l" 'incomplete finding G-042' "$(vfr D "$l" "$sp")"; done
done
say '  -- the canonical field line keeps its one literal space: a Class line written -<U+00A0>**Class:** is not a field'
sp="$R/c-class-nbsp"; mkdir -p "$sp/notes"
round "$sp/notes/opponent.md" CHALLENGED tier-binding new wrong-result 1 0
awk -v nb="$NB" 'index($0, "- **Class:**") == 1 {sub(/^- /, "-" nb)} {print}' "$sp/notes/opponent.md" > "$sp/o" && mv "$sp/o" "$sp/notes/opponent.md"
say "  canonical Class U+00A0: PRE-UTF8 $(vfr PRE en_US.UTF-8 "$sp") | CUR $(vfr CUR C "$sp")"
for l in "${LOCS[@]}"; do has "C canonical Class line after a U+00A0 D $l" 'incomplete finding G-042' "$(vfr D "$l" "$sp")"; done
say '  -- the raw digest reader and the validator agree on quoting: a line that begins with a U+00A0 and a fence run'
fence_probe() { # kit -> vf_fence of the mapped line, and of the raw line
  bash -c 'cd "$1" && . scripts/verification-lib.sh && printf "\302\240\140\140\140\n" | awk "$_VF_AWK_TEXT"'"'"'{print "mapped=" vf_fence($0) " written=" vf_fence(vf_original)}'"'"'' _ "$R/$1"
}
check 'C fence state D: mapped line == line as written' 'mapped=0 written=0' "$(fence_probe D)"
say "  fence state DS: $(fence_probe DS)"

say '== D: the Decisions section in the input identity (R2-F1): pairs that differ only by one waiver line'
sem() { # kit status-file out
  bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_semantic_file .specify/specs/x/STATUS.md "$2" "$3"' _ "$R/$1" "$2" "$3"
}
auth() { # kit status-file -> rc of vf_round_authorized for round 4
  local d="$w/authspec"; rm -rf "$d"; mkdir -p "$d"; cp "$2" "$d/STATUS.md"
  bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_round_authorized "$2" opponent 4 2026-09-27T00:00:00Z' _ "$R/$1" "$d" > /dev/null 2>&1; printf '%s' "$?"
}
WAIVER='- 2026-09-27T15:55:36Z — waiver: gate=opponent; round=4; after=3; by=someone; reason=a reason'
status_pair() { # shape -> writes $w/sa.md (without the waiver) and $w/sb.md (with it)
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
  status_pair "$shape"
  for k in PRE CUR D DS; do
    sem "$k" "$w/sa.md" "$w/sa.$k"; sem "$k" "$w/sb.md" "$w/sb.$k"
    cmp -s "$w/sa.$k" "$w/sb.$k" && id=same || id=differ
    eval "id_$k=\$id"
  done
  a="$(auth D "$w/sb.md")"
  say "  $shape: identity PRE=$id_PRE CUR=$id_CUR D=$id_D DS=$id_DS; D scanner reads the waiver: rc=$a"
  check "D $shape: D identity differs" differ "$id_D"
  [[ "$a" == 0 ]] && check "D $shape: the scanner reads it, so the identity hashes it" differ "$id_D"
done
say '  -- end to end: vf_snapshot of a repository holding the duplicate-later STATUS, without and with the waiver'
status_pair duplicate-later
snapdigest() { # kit status-file -> the identity of a repository holding it
  local g="$w/snap-$1"; rm -rf "$g"; mkdir -p "$g/.specify/specs/004-x"
  printf -- '---\nspec: 004-x\n---\n' > "$g/.specify/specs/004-x/spec.md"
  for f in plan tasks; do printf -- '---\nx: 1\n---\n' > "$g/.specify/specs/004-x/$f.md"; done
  cp "$2" "$g/.specify/specs/004-x/STATUS.md"
  ( cd "$g" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid -c commit.gpgsign=false commit -qm s ) > /dev/null 2>&1
  bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_snapshot "$2/.specify/specs/004-x" "$2" "$2" "$3"' _ "$R/$1" "$g" "$w/snap.nul"
}
for k in CUR D; do
  snap_a="$(snapdigest "$k" "$w/sa.md")"; snap_b="$(snapdigest "$k" "$w/sb.md")"
  say "  snapshot $k: ${snap_a:0:16} ${snap_b:0:16}"
  if [[ "$k" == D ]]; then
    if [[ -n "$snap_a" && -n "$snap_b" && "$snap_a" != "$snap_b" ]]; then v=differ; else v=same; fi
    check 'D snapshot: two identities' differ "$v"
  fi
done

say '== E: task bindings (the v1 fixture spec of tests/helpers.sh)'
fixture() { # kit name -> spec dir
  mkdir -p "$w/fx-$1"
  bash -c 'cd "$1" && SANDBOX="$2" && . tests/helpers.sh && make_verification_spec_dir "$3"' _ "$R/$1" "$w/fx-$1" "$2"
}
bind() { # kit locale spec -> rc and the first diagnostic
  inloc "$2" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_bindings "$2" tasks "" "$3"' _ "$R/$1" "$3" "$w/cat.nul" > /dev/null 2> "$w/be"
  printf 'rc=%s %s' "$?" "$(grep -m1 -E 'manual Verify|placeholder|Verify must|no matching' "$w/be" | cut -c1-110)"
}
for k in PRE CUR D; do eval "fx_$k=\$(fixture $k base)"; done
edit() { perl -e 'local $/; my ($f,$o,$n)=@ARGV; open my $h,"<",$f or exit 3; my $t=<$h>; close $h; my $c=($t =~ s/\Q$o\E/$n/); exit 4 if $c!=1; open $h,">",$f or exit 3; print $h $t; close $h' "$@"; }
for k in PRE CUR D; do eval "sp=\$fx_$k"; edit "$sp/tasks.md" '`manual: inspect the release artifact and record its digest`' "\`manual: $NB\`"; done
say "  manual observation U+00A0: PRE-UTF8 $(bind PRE en_US.UTF-8 "$fx_PRE") | CUR $(bind CUR C "$fx_CUR")"
for l in "${LOCS[@]}"; do has "E manual observation U+00A0 D $l" 'manual Verify must be manual: <observation>' "$(bind D "$l" "$fx_D")"; done
for k in PRE CUR D; do eval "fx_$k=\$(fixture $k ph)"; eval "sp=\$fx_$k"
  edit "$sp/plan.md" '| manual-family | manual | AC-004 | release-observation |' "| manual-family | manual | AC-004 | $NB |"
  edit "$sp/tasks.md" '  - *Tests:* release-observation' "  - *Tests:* $NB"; done
say "  placeholder U+00A0: PRE-UTF8 $(bind PRE en_US.UTF-8 "$fx_PRE") | CUR $(bind CUR C "$fx_CUR")"
for l in "${LOCS[@]}"; do has "E placeholder U+00A0 D $l" 'placeholder' "$(bind D "$l" "$fx_D")"; done
say '  -- a Verify command written with a U+00A0 inside it is run and recorded as written'
cmd_written="grep -c 'a${NB}b' tests/check.sh"
for k in CUR D DS; do eval "fx_$k=\$(fixture $k vc)"; eval "sp=\$fx_$k"; edit "$sp/tasks.md" '`bash tests/check.sh` → passed' "\`$cmd_written\` → passed"; done
vcmd() { # kit spec -> the command the harness would run for T001
  bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_bindings "$2" tasks "" "$3" 2>/dev/null && vf_task_info "$3" T001 && printf "%s" "$VF_TASK_COMMAND"' _ "$R/$1" "$2" "$w/vc.nul"
}
for k in CUR D DS; do eval "sp=\$fx_$k"; got="$(vcmd "$k" "$sp")"; [[ "$got" == "$cmd_written" ]] && v=written || v="changed:$(printf '%s' "$got" | od -An -c | tr -s ' ' | tr -d '\n' | cut -c1-80)"; say "  $k: $v"; [[ "$k" == D ]] && check 'E D runs the Verify command as written' written "$v"; done
say '  -- a Verify value that begins with a U+00A0 before its backticks'
for k in CUR D; do eval "fx_$k=\$(fixture $k lead)"; eval "sp=\$fx_$k"; edit "$sp/tasks.md" '  - *Verify:* `bash tests/check.sh` → passed' "  - *Verify:*$NB\`bash tests/check.sh\` → passed"; done
say "  CUR: $(bind CUR C "$fx_CUR")"
for l in "${LOCS[@]}"; do check "E leading U+00A0 before the Verify backticks D $l" 'bash tests/check.sh' "$(inloc "$l" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_bindings "$2" tasks "" "$3" 2>/dev/null && vf_task_info "$3" T001 && printf "%s" "$VF_TASK_COMMAND"' _ "$R/D" "$fx_D" "$w/lead.nul")"; done

say '== F: frontmatter and contract routing'
fmv() { bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_fm_value "$2" "$3"' _ "$R/$1" "$2" "$3"; }
printf -- '---\nspec: x\nworktree: /tmp/My%sProjects/wt\nbranch: spec/x # the branch\nverification_contract:%s1\n---\n' "$NB" "$NB" > "$w/fm.md"
for k in CUR D DS; do say "  $k worktree=$(fmv "$k" "$w/fm.md" worktree | od -An -c | tr -s ' ' | tr -d '\n') contract=[$(fmv "$k" "$w/fm.md" verification_contract)] branch=[$(fmv "$k" "$w/fm.md" branch)]"; done
check 'F D worktree value is the path as written' "/tmp/My${NB}Projects/wt" "$(fmv D "$w/fm.md" worktree)"
check 'F D a U+00A0 after the contract colon reads as 1' 1 "$(fmv D "$w/fm.md" verification_contract)"
check 'F D an inline comment is dropped' 'spec/x' "$(fmv D "$w/fm.md" branch)"
printf -- '---\nverification_contract: 1%s# pinned\n---\n' "$NB" > "$w/fm2.md"
check 'F D a U+00A0 before an inline comment ends the value' 1 "$(fmv D "$w/fm2.md" verification_contract)"
route() { # kit script value-line -> exit and last line
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
    say "  [$(printf '%b' "$v" | tr '\n' '|')] $script: CUR $(route CUR "$script" "$(printf '%b' "$v")")"
    has "F D $script refuses [$(printf '%b' "$v" | tr '\n' '|')]" 'exit=3 unsupported verification contract' "$(route D "$script" "$(printf '%b' "$v")")"
  done
done
check 'F D spec-task lists a legacy spec' $'exit=0 T001\tdone\tBackend\tx' "$(route D spec-task '')"

say '== G: legacy evidence and artifact names (spec-evidence.sh, legacy spec)'
lg="$w/legacy"; mkdir -p "$lg/shots"; : > "$lg/shots/a.png"; : > "$lg/shots/écran.png"
printf -- '---\nspec: 001-legacy\n---\n\n- AC-001: x\n' > "$lg/spec.md"
ev() { # kit locale evidence -> exit and the artifact diagnostic
  printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — x\n  - *Acceptance:* x\n  - *Evidence:* %s\n' "$3" > "$lg/tasks.md"
  ( cd "$lg" && inloc "$2" bash "$R/$1/scripts/spec-evidence.sh" "$lg" ) > "$w/ev" 2>&1
  printf 'exit=%s %s' "$?" "$(grep -o -m1 "names artifact '[^']*'\|no \*Evidence:\* line" "$w/ev")"
}
evcase() { # label want-exit evidence
  local l; say "  $1: PRE-UTF8 $(ev PRE en_US.UTF-8 "$3") | CUR $(ev CUR C "$3")"
  for l in "${LOCS[@]}"; do has "G $1 D $l" "exit=$2" "$(ev D "$l" "$3")"; done
}
evcase nbsp-only 1 "$NB"
evcase nbsp-separated 0 "screenshot${NB}shots/a.png"
evcase narrow-nbsp-separated 0 $'screenshot\342\200\257shots/a.png'
evcase em-space-separated 0 $'screenshot\342\200\203shots/a.png'
evcase ideographic-space-separated 0 $'\346\210\252\345\233\276\343\200\200shots/a.png'
evcase curly-quoted 0 $'\342\200\234shots/a.png\342\200\235'
evcase guillemets 0 $'\302\253shots/a.png\302\273'
evcase backticked 0 '`shots/a.png`'
evcase missing-quoted 1 $'\342\200\234shots/missing.png\342\200\235'
evcase missing-accented 1 'screenshot shots/café.png'
evcase existing-accented 0 'screenshot shots/écran.png'
evcase fullwidth-colon-glued 1 $'\346\210\252\345\233\276\357\274\232shots/a.png'
evcase glob-not-a-pattern 1 'screenshot shots/*.png'

say '== H: the analyzer'"'"'s gate Agent path'
for k in PRE CUR D; do eval "fx_$k=\$(fixture $k agent)"; eval "sp=\$fx_$k"; edit "$sp/tasks.md" '  - *Agent:* agents/opponent.agent.md' "  - *Agent:* ${NB}agents/opponent.agent.md"; done
an() { ( cd "$R/$1" && inloc "$2" bash scripts/sdd-analyze.sh "$3" ) > "$w/an" 2>&1; printf 'exit=%s %s' "$?" "$(grep -m1 'opponent gate' "$w/an")"; }
say "  PRE-UTF8 $(an PRE en_US.UTF-8 "$fx_PRE") | CUR $(an CUR C "$fx_CUR")"
for l in "${LOCS[@]}"; do has "H agent path after a U+00A0 D $l" 'opponent gate present, agent file exists' "$(an D "$l" "$fx_D")"; done

say '== I: recorded history and the input identity, D against CUR'
# The files the parsers of author text read: every spec's four documents, its
# gate reports and prior-review manifests, the stack configuration and the
# templates. (Captured output under notes/, such as 001's notes/evidence.md,
# which holds a U+202F thousands separator inside a fenced Codex transcript,
# is hashed verbatim and read by no such parser.)
nbsp_files="$(cd "$R/CUR" && git ls-files -z -- '.specify/specs/*/spec.md' '.specify/specs/*/plan.md' '.specify/specs/*/tasks.md' \
  '.specify/specs/*/STATUS.md' '.specify/specs/*/notes/opponent.md' '.specify/specs/*/notes/reality-check.md' \
  '.specify/specs/*/notes/verification/reports/*-findings-*.md' .specify/stack.yml 'templates/*' | xargs -0 perl -ne 'if (/\xc2[\x85\xa0]|\xe1\x9a\x80|\xe2\x80[\x80-\x8a\xa8\xa9\xaf]|\xe2\x81\x9f|\xe3\x80\x80/) { print "$ARGV\n"; close ARGV }' | LC_ALL=C sort -u | tr '\n' ' ')"
check 'I no file a parser of author text reads holds a non-ASCII White_Space character' '' "$nbsp_files"
say "  files that hold one anywhere in the enumeration: $(cd "$R/CUR" && git ls-files -z | xargs -0 perl -ne 'if (/\xc2[\x85\xa0]|\xe1\x9a\x80|\xe2\x80[\x80-\x8a\xa8\xa9\xaf]|\xe2\x81\x9f|\xe3\x80\x80/) { print "$ARGV\n"; close ARGV }' | LC_ALL=C sort -u | tr '\n' ' ')"
for spec in 001-codex-subagent-gates-and-hard-task-escalation 002-usage-limit-handling-for-dispatched-runs 003-gate-round-reduction-and-token-discipline; do
  for l in "${LOCS[@]}"; do
    for cmd in tally sdd-analyze spec-ac-coverage spec-evidence; do
      # 003's evidence check is the current-evidence path, which reads captures, not author text, and runs for most of an hour.
      [[ "$cmd" == spec-evidence && "$spec" == 003-* ]] && continue
      for k in CUR D; do
        case "$cmd" in
          tally) ( cd "$R/$k" && inloc "$l" bash scripts/spec-gate.sh tally ".specify/specs/$spec" ) > "$w/h-$k" 2>&1;;
          *) ( cd "$R/$k" && inloc "$l" bash "scripts/$cmd.sh" ".specify/specs/$spec" ) > "$w/h-$k" 2>&1;;
        esac
        echo "rc=$?" >> "$w/h-$k"; sed "s#$R/$k#KIT#g" "$w/h-$k" > "$w/h-$k.n" && mv "$w/h-$k.n" "$w/h-$k"
      done
      if cmp -s "$w/h-CUR" "$w/h-D"; then say "PASS I ${spec:0:3} $cmd $l identical ($(tail -1 "$w/h-D"))"; else say "FAIL I ${spec:0:3} $cmd $l differs"; diff "$w/h-CUR" "$w/h-D" | head -6; fails=$((fails+1)); fi
    done
  done
done
for k in CUR D; do
  for n in 13 14; do ( cd "$R/$k" && bash scripts/spec-gate.sh waiver "$s" opponent "$n" ) > "$w/wv-$k-$n" 2>&1; echo "rc=$?" >> "$w/wv-$k-$n"; done
done
check 'I round-13 waiver D == CUR' "$(cat "$w/wv-CUR-13")" "$(cat "$w/wv-D-13")"
check 'I round-14 refusal D == CUR' "$(cat "$w/wv-CUR-14")" "$(cat "$w/wv-D-14")"
for k in CUR D; do
  : > "$w/semviews-$k"
  while IFS= read -r st; do
    bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_semantic_file "$2" "$2" "$3"' _ "$R/$k" "$st" "$w/sv"
    printf '%s %s\n' "$st" "$(shasum -a 256 < "$w/sv" | cut -c1-64)" >> "$w/semviews-$k"
  done < <(cd "$R/$k" && git ls-files | grep -E '^\.specify/specs/[^/]+/STATUS\.md$')
done
say "  STATUS semantic views: $(wc -l < "$w/semviews-D" | tr -d ' ') files"
check 'I every STATUS semantic view D == CUR' "$(cat "$w/semviews-CUR")" "$(cat "$w/semviews-D")"
for k in CUR D; do
  for l in "${LOCS[@]}"; do
    inloc "$l" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_snapshot "$2" "$1" "$1" "$3"' _ "$R/$k" "$s" "$w/in-$k-$l.nul" > "$w/digest-$k-$l"
    tr '\0' '\n' < "$w/in-$k-$l.nul" | paste - - - - - - | sed "s#$R/$k#KIT#g" | LC_ALL=C grep -v -E $'^(version|harness)\t|^(path|index)\tscripts/(verification-lib|sdd-analyze|spec-evidence|spec-run|spec-task)\\.sh\t' > "$w/rec-$k-$l"
  done
done
check 'I snapshot records outside the edited files and harness records: D == CUR (C)' "$(shasum < "$w/rec-CUR-C")" "$(shasum < "$w/rec-D-C")"
check 'I snapshot records outside the edited files and harness records: D == CUR (en_US.UTF-8)' "$(shasum < "$w/rec-CUR-en_US.UTF-8")" "$(shasum < "$w/rec-D-en_US.UTF-8")"
check 'I the D snapshot is one digest in both locales' "$(cat "$w/digest-D-C")" "$(cat "$w/digest-D-en_US.UTF-8")"
say "  records compared: $(wc -l < "$w/rec-D-C" | tr -d ' ')"

say '== J: review 1 F3 (the return size read) is unchanged'
{ printf 'Verification-Return: 1\nTask: T001\nCaptures: CAP-1-abcdef\nSummary: x\nFailure modes: none\n'; head -c 70000 /dev/zero | tr '\000' 'x'; printf '\n'; } > "$w/big.txt"
mkdir -p "$w/fwc"; printf '#!/bin/bash\nfor a in "$@"; do [[ "$a" == -c ]] && { echo "wc: injected fault" >&2; exit 2; }; done\nexec /usr/bin/wc "$@"\n' > "$w/fwc/wc"; chmod +x "$w/fwc/wc"
has 'J D a wc fault is refused by name' 'return: its size could not be read' "$(env PATH="$w/fwc:$PATH" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_return_parse "$2" "$3"' _ "$R/D" "$w/big.txt" "$w/big.nul" 2>&1)"

check 'live worktree status outside notes/verification/ unchanged' "$live_before" "$(livestate)"
say "t030o43-design-measure failures=$fails"
if (( fails == 0 )); then rm -rf "$R"; else say "kept: $R"; fi
(( fails == 0 ))
