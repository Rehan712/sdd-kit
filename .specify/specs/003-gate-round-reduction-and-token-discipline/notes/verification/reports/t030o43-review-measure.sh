#!/usr/bin/env bash
# T030o43 review repairs measured BEFORE adoption, 2026-09-27: the same cases as
# t030o43-review-verify.sh, run on U (the reviewed tree) and P (U with the candidate
# pairs t030o43-edits/kernel-4.pairs and spec-evidence-2.pairs applied), then the
# recorded history: tally for 001, 002, 003 and the snapshot, P against U. Read-only.
# Every run removes every LC_* name.
# Usage: bash t030o43-review-measure.sh <scratchpad> <worktree>
set -uo pipefail
SP="$1"; WT="$2"; E="$WT/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/t030o43-edits"
R="$SP/t030o43-rm"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$R/U" "$R/P" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
say() { printf '%s\n' "$*"; }
for d in U P; do
  ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$R/$d" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
done
perl "$E/lit.pl" "$R/P/scripts/verification-lib.sh" "$E/kernel-4.pairs" && perl "$E/lit.pl" "$R/P/scripts/spec-evidence.sh" "$E/spec-evidence-2.pairs" || { say 'FAIL candidate'; exit 2; }
for d in U P; do ( cd "$R/$d" && git init -q && git add -A && git -c user.name=v -c user.email=v@invalid commit -qm base ) >/dev/null || { say 'FAIL commit'; exit 2; }; done
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
NB=$'\302\240'
SRC="$(printf 'a%.0s' {1..64})"
report() { # file verdict class status sev blocking minor [attack-body]
  printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\n%s\n### Finding G-042\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read the manifest\n### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n' \
    "$SRC" "$2" "$6" "$7" "${8:-Manifest tier binding.}" "$3" "$4" "$5" > "$1"
}
vfr() { # kit locale report spec -> "rc | first diagnostic"
  inloc "$2" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2" opponent "$3" "$4"' _ "$R/$1" "$3" "$w/out.nul" "$4" > "$w/o" 2> "$w/e"
  printf 'rc=%s | %s' "$?" "$(LC_ALL=C grep -v towc "$w/e" | head -1 | cut -c1-110)"
}
case_row() { # label manifest-text verdict class status sev blocking minor [attack-body]
  local label="$1" m="$2" sp="$R/spec-$1"; shift 2
  mkdir -p "$sp/notes/verification/reports"; printf '%s' "$m" > "$sp/notes/verification/reports/opponent-findings-review.md"
  report "$sp/notes/opponent.md" "$@"
  for kit in U P; do for l in C en_US.UTF-8; do say "  $label $kit $l: $(vfr "$kit" "$l" "$sp/notes/opponent.md" "$sp")"; done; done
}
say '== F1: a U+00A0 after the dash of a manifest field line'
case_row F1-class "$(printf '### Finding G-042\n-%s**Class:** tier-binding\n- **Severity:** data-loss\n' "$NB")" CLEARED tier-binding open minor 0 1
case_row F1-severity "$(printf '### Finding G-042\n- **Class:** tier-binding\n-%s**Severity:** data-loss\n' "$NB")" CLEARED tier-binding open minor 0 1
case_row F1-classbind "$(printf '### Finding G-042\n-%s**Class:** tier-binding\n- **Severity:** data-loss\n' "$NB")" CHALLENGED silent-data-loss open wrong-result 1 0
say '== derived: a U+00A0 at the end of the manifest Finding heading'
case_row D1-heading "$(printf '### Finding G-042%s\n- **Class:** tier-binding\n- **Severity:** data-loss\n' "$NB")" CLEARED tier-binding open minor 0 1
say '== derived: a required report section whose only body line is a U+00A0'
case_row D2-section "$(printf '### Finding G-001\n- **Class:** other\n- **Severity:** minor\n')" CLEARED tier-binding open minor 0 1 "$NB"
say '== derived: a U+00A0 after the Decisions log heading, and the identity'
for kit in U P; do
  for l in C en_US.UTF-8; do
    printf -- '---\nspec: x\n---\n\n## Decisions log%s\n\n- 2026-09-06 — one decision\n' "$NB" > "$w/status-a.md"
    printf -- '---\nspec: x\n---\n\n## Decisions log%s\n\n- 2026-09-06 — a different decision\n' "$NB" > "$w/status-b.md"
    for v in a b; do
      inloc "$l" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_semantic_file "$2" "$3" "$4"' _ "$R/$kit" "$s/STATUS.md" "$w/status-$v.md" "$w/sem-$v"
    done
    if cmp -s "$w/sem-a" "$w/sem-b"; then v=same; else v=differ; fi
    say "  D3 $kit $l: two Decisions logs hash to the $v bytes ($(wc -c < "$w/sem-a" | tr -d ' ') bytes kept)"
  done
done
say '== derived: a U+00A0 after the verification_contract colon, and spec-evidence.sh'
for kit in U P; do
  sp="$R/$kit/.specify/specs/099-ev"; mkdir -p "$sp"
  printf -- '---\nspec: 099-ev\nverification_contract:%s1\n---\n\n- AC-001: x\n' "$NB" > "$sp/spec.md"
  printf -- '---\nspec: 099-ev\n---\n\n## Backend\n\n- [ ] **T001** — x\n' > "$sp/tasks.md"
  for l in C en_US.UTF-8; do
    ( cd "$R/$kit" && inloc "$l" bash scripts/spec-evidence.sh "$sp" ) > "$w/ev" 2>&1
    say "  D4 $kit $l: rc=$? $(head -1 "$w/ev" | cut -c1-90) / $(tail -1 "$w/ev" | cut -c1-80)"
  done
  rm -rf "$sp"
done
say '== F2: legacy artifact names with non-ASCII letters'
for kit in U P; do
  lg="$R/legacy-$kit/.specify/specs/001-legacy"; mkdir -p "$lg/shots"
  printf -- '---\nspec: 001-legacy\nstatus: accepted\n---\n\n- AC-001: legacy criterion\n' > "$lg/spec.md"
  for name in 'café' 'écran'; do
    [[ "$name" == écran ]] && : > "$lg/shots/écran.png"
    printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — Legacy task\n  - *Acceptance:* legacy\n  - *Evidence:* screenshot shots/%s.png\n' "$name" > "$lg/tasks.md"
    for l in C en_US.UTF-8; do
      ( cd "$lg" && inloc "$l" bash "$R/$kit/scripts/spec-evidence.sh" "$lg" ) > "$w/ev" 2>&1
      say "  F2 $kit $l shots/$name.png ($([[ -e "$lg/shots/$name.png" ]] && echo exists || echo missing)): rc=$? $(grep -E '✗|✓' "$w/ev" | head -2 | tr '\n' ' ' | cut -c1-140)"
    done
  done
done
say '== F3: the return size bound under a failing wc'
( cd "$R/P" && bash -c '. tests/helpers.sh; fault_bin "$1/fault-wc" wc -c' _ "$w" )
{ printf 'Verification-Return: 1\nTask: T001\nCaptures: CAP-1-x\nSummary: s\nFailure modes: none\n'; head -c 81000 /dev/zero | tr '\0' 'x'; printf '\n'; } > "$w/big-return"
say "  return bytes: $(wc -c < "$w/big-return" | tr -d ' ')"
for f in plain fault; do
  if [[ "$f" == fault ]]; then p="$w/fault-wc:$PATH"; else p="$PATH"; fi
  ( cd "$R/P" && env PATH="$p" bash -c '. scripts/verification-lib.sh; vf_return_parse "$1" "$2"' _ "$w/big-return" "$w/parsed" ) > "$w/rp" 2>&1
  say "  F3 P $f: rc=$? $(head -1 "$w/rp" | cut -c1-80)"
done
say '== history: tally for 001, 002 and 003, P against U'
for spec in .specify/specs/001-* .specify/specs/002-* "$s"; do
  sp="$(cd "$R/U" && ls -d $spec | head -1)"
  for l in C en_US.UTF-8; do
    for kit in U P; do ( cd "$R/$kit" && inloc "$l" bash scripts/spec-gate.sh tally "$sp" ) > "$w/t-$kit" 2>&1; echo "rc=$?" >> "$w/t-$kit"; done
    say "  tally ${sp##*/} $l: $(cmp -s "$w/t-U" "$w/t-P" && echo "identical ($(tail -1 "$w/t-P"))" || echo DIFFER)"
  done
done
say '== history: the snapshot, P against U, outside the edited files'
for kit in U P; do
  ( cd "$R/$kit" && inloc C bash -c '. scripts/verification-lib.sh && vf_snapshot "$1" "$PWD" "$PWD" "$2"' _ "$s" "$w/snap-$kit.nul" ) > /dev/null 2>&1
  tr '\0' '\n' < "$w/snap-$kit.nul" | paste - - - - - - | LC_ALL=C sed "s#$R/$kit#<repo>#g" |
    LC_ALL=C awk -F '\t' '$1=="harness" || $1=="version" {next} ($1=="path" || $1=="index") && ($2=="scripts/verification-lib.sh" || $2=="scripts/spec-evidence.sh") {next} {print}' > "$w/snap-$kit.kept"
done
say "  snapshot records outside the two edited files: $(cmp -s "$w/snap-U.kept" "$w/snap-P.kept" && echo identical || echo DIFFER) ($(wc -l < "$w/snap-P.kept" | tr -d ' ') records)"
cd "$SP" && rm -rf "$R"
