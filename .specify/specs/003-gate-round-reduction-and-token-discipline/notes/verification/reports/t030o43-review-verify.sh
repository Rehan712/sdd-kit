#!/usr/bin/env bash
# Invoker verification of the T030o43 review's findings, 2026-09-27, BEFORE any
# change, plus the members the invoker derived from the same mechanism. Read-only
# against the live worktree. Two standalone copies from the live enumeration:
# POST (the tree as reviewed) and PRE (the same with the rebuilt pre-delta files
# laid over it, `t030o43-pre-rebuild.sh`). Every run removes every LC_* name.
# Usage: bash t030o43-review-verify.sh <scratchpad> <worktree> <pre-dir>
set -uo pipefail
SP="$1"; WT="$2"; PRE="$3"
R="$SP/t030o43-rv"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$R/POST" "$R/PRE" "$w" "$TMPDIR"
s=.specify/specs/003-gate-round-reduction-and-token-discipline
say() { printf '%s\n' "$*"; }
for d in POST PRE; do
  ( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - ) | ( cd "$R/$d" && tar -xf - ) || { say 'FAIL copy'; exit 2; }
done
( cd "$PRE" && find . -type f -print0 | tar --null -T - -cf - ) | ( cd "$R/PRE" && tar -xf - ) || { say 'FAIL overlay'; exit 2; }
for d in POST PRE; do ( cd "$R/$d" && git init -q && git add -A && git -c user.name=v -c user.email=v@invalid commit -qm base ) >/dev/null || { say 'FAIL commit'; exit 2; }; done
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
  for kit in PRE POST; do for l in C en_US.UTF-8; do say "  $label $kit $l: $(vfr "$kit" "$l" "$sp/notes/opponent.md" "$sp")"; done; done
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
for kit in PRE POST; do
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
for kit in PRE POST; do
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
for kit in PRE POST; do
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
( cd "$R/POST" && bash -c '. tests/helpers.sh; fault_bin "$1/fault-wc" wc -c' _ "$w" )
{ printf 'Verification-Return: 1\nTask: T001\nCaptures: CAP-1-x\nSummary: s\nFailure modes: none\n'; head -c 81000 /dev/zero | tr '\0' 'x'; printf '\n'; } > "$w/big-return"
say "  return bytes: $(wc -c < "$w/big-return" | tr -d ' ')"
for f in plain fault; do
  if [[ "$f" == fault ]]; then p="$w/fault-wc:$PATH"; else p="$PATH"; fi
  ( cd "$R/POST" && env PATH="$p" bash -c '. scripts/verification-lib.sh; vf_return_parse "$1" "$2"' _ "$w/big-return" "$w/parsed" ) > "$w/rp" 2>&1
  say "  F3 POST $f: rc=$? $(head -1 "$w/rp" | cut -c1-80)"
done
say '== F4: the five guards the fixtures do not reach (code read, plus X1 and X2 by hand)'
sp="$R/x-spec"
( cd "$R/POST" && SANDBOX="$R/x-sb" bash -c 'mkdir -p "$SANDBOX"; . tests/helpers.sh; make_verification_git_dir x12' ) > "$w/x-path" 2>/dev/null
xs="$(cat "$w/x-path")"; xr="$(cd "$xs/../../.." && pwd -P)"
( cd "$R/POST" && env ${nolc[@]+"${nolc[@]}"} SDD_HARNESS_CALLER_LC_ALL=set:C LC_ALL=en_US.UTF-8 bash scripts/spec-run.sh "$xs" T001 --cwd "$xr" --no-tick --summary -- bash -c 'printf "seen=%s\n" "${LC_ALL-<unset>}"' ) > "$w/x1" 2>&1
say "  X1 an inherited set:C record with LC_ALL=en_US.UTF-8: $(LC_ALL=C grep -o 'key=seen=[^ ]*' "$w/x1")"
printf "verification_environment:\n  - 'LC_ALL'\n" >> "$xr/.specify/stack.yml"
for v in unset C; do
  if [[ "$v" == unset ]]; then a=(-u LC_ALL); else a=(LC_ALL=C); fi
  ( cd "$R/POST" && env ${nolc[@]+"${nolc[@]}"} "${a[@]}" bash -c '. scripts/verification-lib.sh; vf_snapshot "$1" "$2" "$2" "$3"' _ "$xs" "$xr" "$w/x2-$v.nul" ) > /dev/null 2>&1
  say "  X2 caller LC_ALL $v: $(tr '\0' '\n' < "$w/x2-$v.nul" | paste - - - - - - | LC_ALL=C grep '^environment	LC_ALL' | cut -f1-3)"
done
say "  X3-X5: the manifest sort, the tally class-table sort and vf_ids' sort: $(grep -c -E 'records="\$\(LC_ALL=C sort -u "\$tmp"\)" \|\| return 3$|printf .%s\\n. "\$out" \| LC_ALL=C sort -u$' "$R/POST/scripts/verification-lib.sh") of the three carry no diagnostic and no fixture fault"
say '== F5: the kernel loaded outside the eight harness files'
( cd "$R/POST" && grep -l 'verification-lib.sh' scripts/*.sh | tr '\n' ' ' ); echo
cd "$SP" && rm -rf "$R"
