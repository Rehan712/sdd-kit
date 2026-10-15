#!/usr/bin/env bash
# Invoker verification of focused review 2's findings, 2026-09-27, BEFORE any change.
# Read-only against the live worktree. Three standalone copies from the live enumeration:
# CUR (the tree as review 2 saw it), REV (the files as review 1 saw them laid over it) and
# PRE (the pre-delta files laid over it). Every run removes every LC_* name.
# Usage: bash t030o43-review2-verify.sh <scratchpad> <worktree> <pre-dir> <reviewed-dir>
set -uo pipefail
SP="$1"; WT="$2"; PRE="$3"; REV="$4"
R="$SP/t030o43-r2v"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$R/CUR" "$R/REV" "$R/PRE" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
say() { printf '%s\n' "$*"; }
for d in CUR REV PRE; do
  ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$R/$d" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
done
( cd "$REV" && find . -type f -print0 | tar --null -T - -cf - ) | ( cd "$R/REV" && tar -xf - )
( cd "$PRE" && find . -type f -print0 | tar --null -T - -cf - ) | ( cd "$R/PRE" && tar -xf - )
nolc=(); while IFS='=' read -r name _; do case "$name" in LC_*) nolc+=(-u "$name");; esac; done < <(env)
inloc() { local l="$1"; shift; env ${nolc[@]+"${nolc[@]}"} -u LANG LANG="$l" "$@"; }
NB=$'\302\240'; SRC="$(printf 'a%.0s' {1..64})"
round() { # file verdict class status sev blocking minor
  printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** %s\n**Blocking:** %s · **Minor:** %s\n### What I attacked\nManifest tier binding.\n### Finding G-042\n- **Class:** %s\n- **Status:** %s\n- **Prior:** none\n- **Severity:** %s\n- **Scenario:** a recorded trigger\n- **Where:** scripts/run.sh:9\n- **Reproduced:** concrete trigger at that site\n- **Root cause:** implementation-error\n- **Blocks:** AC-012\n- **Wrong behavior:** observed versus required\n- **Class-wide fix:** read the manifest\n### Held up / follow-up tasks\nFixture disposition recorded.\n<!-- gate-round-end: opponent:1 -->\n' \
    "$SRC" "$2" "$6" "$7" "$3" "$4" "$5" > "$1"
}
vfr() { # kit locale spec -> "rc=N"
  inloc "$2" bash -c 'cd "$1" && . scripts/verification-lib.sh && vf_reports "$2/notes/opponent.md" opponent "$3" "$2"' _ "$R/$1" "$3" "$w/out.nul" > /dev/null 2> "$w/e"
  printf 'rc=%s' "$?"
}
manifest_case() { # label manifest-body  (round: CLEARED, G-042 open at minor; history says data-loss)
  local sp="$R/m-$1"; mkdir -p "$sp/notes/verification/reports"
  printf '%b' "$2" > "$sp/notes/verification/reports/opponent-findings-review.md"
  round "$sp/notes/opponent.md" CLEARED tier-binding open minor 0 1
  say "  $1: PRE $(vfr PRE en_US.UTF-8 "$sp") | REV $(vfr REV en_US.UTF-8 "$sp") | CUR C $(vfr CUR C "$sp") CUR UTF-8 $(vfr CUR en_US.UTF-8 "$sp")"
}
say '== control: the plain manifest refuses the CLEARED round (rc=3) in every kit'
manifest_case control '### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
say '== R2-F2: spellings the pass drops in silence (rc=0 = the CLEARED round sealed)'
manifest_case lower-finding '### finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case leading-space ' ### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case word-before '### Opponent finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case bom '\357\273\277### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n'
manifest_case nbsp-before-hashes "${NB}### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n"
manifest_case crlf '### Finding G-042\r\n- **Class:** tier-binding\r\n- **Severity:** data-loss\r\n'
manifest_case severity-unbolded '### Finding G-042\n- **Class:** tier-binding\n- Severity: data-loss\n'
manifest_case unclosed-fence '### Finding G-042\n- **Class:** tier-binding\n- **Severity:** data-loss\n```\n'
say '== R2-F3: plausible manifests the current pass refuses (rc=3 in CUR where PRE/REV read rc=3 via the tier guard is not the point: see the diagnostic)'
for f in o017-block trailing-section prose-mention; do
  sp="$R/r3-$f"; mkdir -p "$sp/notes/verification/reports"
  case "$f" in
    o017-block) sed -n '1258,1292p' "$R/CUR/$s/notes/opponent.md" > "$sp/notes/verification/reports/opponent-findings-review.md";;
    trailing-section) printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n\n## Follow-up\n- T030o43 fixes the **Severity:** handling\n' > "$sp/notes/verification/reports/opponent-findings-review.md";;
    prose-mention) printf '### Finding O-017\n- **Class:** harness-locale-decoding\n- **Severity:** wrong-result\n- **Scenario:** the **Class:** field was lost\n' > "$sp/notes/verification/reports/opponent-findings-review.md";;
  esac
  # A CHALLENGED round that re-records O-017 at its manifest Class and tier: nothing to refuse.
  printf '## Round 1\n**Round:** 1\n**Timestamp:** 2026-09-06T12:00:01Z\n**Source:** %s\n**Floor:** FLOOR-fixture\n**Verdict:** CHALLENGED\n**Blocking:** 1 · **Minor:** 0\n### What I attacked\nx\n### Finding O-017\n- **Class:** harness-locale-decoding\n- **Status:** open\n- **Prior:** none\n- **Severity:** wrong-result\n- **Scenario:** s\n- **Where:** scripts/run.sh:9\n- **Reproduced:** r\n- **Root cause:** plan-gap\n- **Blocks:** AC-012\n- **Wrong behavior:** w\n- **Class-wide fix:** f\n### Held up / follow-up tasks\nh\n<!-- gate-round-end: opponent:1 -->\n' "$SRC" > "$sp/notes/opponent.md"
  say "  $f: PRE $(vfr PRE C "$sp") | REV $(vfr REV C "$sp") | CUR $(vfr CUR C "$sp") $(head -1 "$w/e" | cut -c1-90)"
done
say '== R2-F4: a U+00A0-only value, refused pre-delta under en_US.UTF-8, read as present now'
sp="$R/r4-field"; mkdir -p "$sp/notes"
round "$sp/notes/opponent.md" CHALLENGED tier-binding new wrong-result 1 0
sed "s/^- \*\*Scenario:\*\* a recorded trigger\$/- **Scenario:** $NB/" "$sp/notes/opponent.md" > "$sp/o" && mv "$sp/o" "$sp/notes/opponent.md"
say "  finding Scenario U+00A0: PRE UTF-8 $(vfr PRE en_US.UTF-8 "$sp") | CUR C $(vfr CUR C "$sp") UTF-8 $(vfr CUR en_US.UTF-8 "$sp")"
lg="$R/r4-legacy"; mkdir -p "$lg"
printf -- '---\nspec: 001-legacy\n---\n\n- AC-001: x\n' > "$lg/spec.md"
printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — x\n  - *Acceptance:* x\n  - *Evidence:* %s\n' "$NB" > "$lg/tasks.md"
for kit in PRE CUR; do for l in C en_US.UTF-8; do ( cd "$lg" && inloc "$l" bash "$R/$kit/scripts/spec-evidence.sh" "$lg" ) > "$w/ev" 2>&1; say "  legacy Evidence U+00A0 $kit $l: exit=$? $(tail -1 "$w/ev")"; done; done
say '== R2-F5: an artifact name after a U+00A0 (shots/a.png exists)'
mkdir -p "$lg/shots"; : > "$lg/shots/a.png"
printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — x\n  - *Acceptance:* x\n  - *Evidence:* screenshot%sshots/a.png\n' "$NB" > "$lg/tasks.md"
for kit in PRE CUR; do for l in C en_US.UTF-8; do ( cd "$lg" && inloc "$l" bash "$R/$kit/scripts/spec-evidence.sh" "$lg" ) > "$w/ev" 2>&1; say "  artifact $kit $l: exit=$? $(grep -o "names artifact '[^']*'" "$w/ev" | head -1)"; done; done
say '== R2-F6: an empty verification_contract value'
ev="$R/r6/.specify/specs/099-e"; mkdir -p "$ev"
printf -- '---\nspec: 099-e\nverification_contract:\n---\n\n- AC-001: x\n' > "$ev/spec.md"; printf -- '---\nspec: 099-e\n---\n\n## Backend\n\n- [ ] **T001** — x\n' > "$ev/tasks.md"
( cd "$R/CUR" && bash scripts/spec-evidence.sh "$ev" ) > "$w/ev" 2>&1; say "  spec-evidence.sh: exit=$? $(tail -1 "$w/ev")"
( cd "$R/CUR" && bash -c '. scripts/verification-lib.sh; vf_bindings "$1" tasks "" "$2"' _ "$ev" "$w/cat" ) > "$w/vb" 2>&1; say "  vf_bindings: exit=$? $(head -1 "$w/vb")"
cd "$SP" && rm -rf "$R"
