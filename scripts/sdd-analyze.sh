#!/usr/bin/env bash
# sdd-analyze.sh — cross-artifact consistency check for one spec directory.
#
# Deterministic lint of spec.md ↔ plan.md ↔ tasks.md before implementation:
#   - all four artifacts present (spec, plan, tasks, STATUS)
#   - no unresolved [NEEDS CLARIFICATION: …] markers in spec.md / plan.md
#   - every AC-### defined in spec.md is referenced by at least one
#     IMPLEMENTATION task (gate tasks enumerate every AC, so they don't count)
#   - every REQ-### is referenced by plan.md or tasks.md (warning)
#   - every AC/REQ id referenced in tasks.md actually exists in spec.md
#   - every task has an *Acceptance:* line; non-gate tasks have *Refs:*
#   - every non-gate, non-Ship task has a *Verify:* line — the exact runnable
#     command (or `manual: <what to observe>`) that proves it (warning)
#   - every [x] non-gate, non-Ship task has an *Evidence:* line (warning)
#   - no duplicate task ids
#   - both pre-ship gates present; their Agent: files exist on disk
#   - no template placeholders left over (<Spec Title>, T### skeletons, …)
#   - umbrella specs (repos: frontmatter): every non-gate/non-Ship task carries
#     a [repo:<name>] tag naming a declared repo; every declared repo has work
#   - [EXTERNAL: …] markers in spec.md are mirrored in STATUS.md (warning) —
#     unlike NEEDS CLARIFICATION they don't block; they're tracked blockers
#
# Run it: at the end of /sdd:tasks, in /sdd:implement pre-flight, or any time.
#
# Usage:
#   sdd-analyze.sh <spec-dir>     # e.g. .../.specify/specs/004-foo
#   sdd-analyze.sh --help
#
# Exit: 0 = clean (warnings allowed), 1 = errors found, 2 = usage.

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"

usage() { usage_from_header "$0"; exit 0; }

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && usage
SPEC_DIR="${1:-}"
[[ -z "$SPEC_DIR" || ! -d "$SPEC_DIR" ]] && { echo "usage: sdd-analyze.sh <spec-dir>" >&2; exit 2; }
SPEC_DIR="$(cd "$SPEC_DIR" && pwd)"

init_colors
errors=0; warnings=0
pass() { echo "  ${GREEN}✓${RESET} $1"; }
fail() { echo "  ${RED}✗${RESET} $1"; errors=$((errors+1)); }
warn() { echo "  ${YELLOW}!${RESET} $1"; warnings=$((warnings+1)); }

spec="$SPEC_DIR/spec.md"; plan="$SPEC_DIR/plan.md"; tasks="$SPEC_DIR/tasks.md"; status="$SPEC_DIR/STATUS.md"

echo "Analyzing: $SPEC_DIR"

# --- 1. artifacts present ---
for f in "$spec" "$plan" "$tasks" "$status"; do
  [[ -f "$f" ]] && pass "$(basename "$f") present" || fail "$(basename "$f") missing"
done
(( errors > 0 )) && { echo "---"; echo "${RED}$errors error(s)${RESET} — fix missing artifacts first"; exit 1; }

# --- 1b. unresolved clarification markers ---
# /sdd:specify and /sdd:plan write [NEEDS CLARIFICATION: …] instead of guessing.
# None may survive into tasking/implementation.
nc=$(grep -n '\[NEEDS CLARIFICATION' "$spec" "$plan" 2>/dev/null | head -5 || true)
if [[ -n "$nc" ]]; then
  fail "unresolved [NEEDS CLARIFICATION] marker(s) — resolve before tasking/implementing:"$'\n'"$(echo "$nc" | sed 's/^/      /')"
else
  pass "no unresolved [NEEDS CLARIFICATION] markers"
fi

# --- 1c. external dependencies mirrored in STATUS ---
# [EXTERNAL: <team/repo> — <what> — needed-by <date>] marks a dependency on a
# repo we don't own. It doesn't block (we stub at the contract), but it must be
# visible in STATUS.md blockers so no session ships forgetting it.
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  # Key = the <team/repo> part: everything before the first space-delimited dash.
  key="$(printf '%s' "$ext" | sed -E 's/^\[EXTERNAL:[[:space:]]*//; s/[[:space:]]+(—|--|-)[[:space:]].*$//; s/\][[:space:]]*$//')"
  if [[ -n "$key" ]] && ! grep -qF "$key" "$status"; then
    warn "external dependency '$key' not mirrored in STATUS.md blockers"
  fi
done < <(grep -o '\[EXTERNAL:[^]]*\]' "$spec" 2>/dev/null | sort -u || true)

# --- 2. id inventories ---
spec_acs=$(grep -oE 'AC-[0-9]{3}' "$spec" | sort -u)
spec_reqs=$(grep -oE 'REQ-[0-9]{3}' "$spec" | sort -u)
task_refs=$(grep -oE '(AC|REQ)-[0-9]{3}' "$tasks" | sort -u)

[[ -z "$spec_acs" ]] && fail "spec.md defines no AC-### ids" || pass "spec.md defines $(echo "$spec_acs" | wc -l | tr -d ' ') AC id(s)"
[[ -z "$spec_reqs" ]] && warn "spec.md defines no REQ-### ids"

# --- 3. AC coverage: every spec AC referenced by an IMPLEMENTATION task ---
# The two gate tasks enumerate every AC by design, so counting their Refs would
# make this check vacuously green. A task is a gate iff its block carries an
# *Agent:* line; coverage counts the other tasks only.
impl_refs=$(awk '
  function flush() { if (id != "" && !gate) print buf; id=""; buf=""; gate=0 }
  /^- \[[ xX~]\] \*\*T[0-9]{3}[a-z0-9]*\*\*/ { flush(); match($0, /T[0-9]{3}[a-z0-9]*/); id = substr($0, RSTART, RLENGTH) }
  /^##[^#]/ { flush() }
  /\*Agent:\*/ { gate=1 }
  { if (id != "") buf = buf " " $0 }
  END { flush() }
' "$tasks" | grep -oE '(AC|REQ)-[0-9]{3}' | sort -u)
uncovered=""
for ac in $spec_acs; do
  grep -q "^$ac$" <<< "$impl_refs" || uncovered="$uncovered $ac"
done
if [[ -n "$uncovered" ]]; then
  fail "AC(s) not covered by any implementation task (gate Refs don't count):$uncovered"
else
  [[ -n "$spec_acs" ]] && pass "every AC is covered by an implementation task"
fi

# --- 4. REQ coverage (warning): every REQ referenced by plan or tasks ---
unref=""
for req in $spec_reqs; do
  { grep -q "$req" "$plan" || grep -q "$req" "$tasks"; } || unref="$unref $req"
done
[[ -n "$unref" ]] && warn "REQ(s) not referenced by plan.md or tasks.md:$unref"

# --- 5. dangling refs: ids used in tasks.md that spec.md never defined ---
dangling=""
for id in $task_refs; do
  grep -q "$id" "$spec" || dangling="$dangling $id"
done
[[ -n "$dangling" ]] && fail "tasks.md references id(s) missing from spec.md:$dangling" || pass "all task refs resolve to spec ids"

# --- 5b. umbrella specs: [repo:<name>] tags ---
# An umbrella spec (repos: frontmatter) spans repos; every implementation task
# must say which repo it lands in, and every tag must name a declared repo.
declared_repos="$(spec_declared_repos "$SPEC_DIR")"
task_map="$(awk '
  /^##[^#]/ { sub(/^##[[:space:]]*/,""); stage=$0 }
  /^- \[[ xX~]\] \*\*T[0-9]{3}[a-z0-9]*\*\*/ {
    match($0, /T[0-9]{3}[a-z0-9]*/); id=substr($0,RSTART,RLENGTH)
    tag=""
    if (match($0, /\[repo:[^]]+\]/)) tag=substr($0,RSTART+6,RLENGTH-7)
    print id "\t" stage "\t" tag
  }
' "$tasks")"
if [[ -n "$declared_repos" ]]; then
  untagged=""; badtag=""
  while IFS=$'\t' read -r tid tstage ttag; do
    [[ -z "$tid" ]] && continue
    [[ "$tstage" =~ Reality|Ship ]] && continue
    if [[ -z "$ttag" ]]; then
      untagged="$untagged $tid"
    elif ! grep -qw "$ttag" <<< "$declared_repos"; then
      badtag="$badtag ${tid}[repo:$ttag]"
    fi
  done <<< "$task_map"
  [[ -n "$untagged" ]] && fail "umbrella spec: task(s) missing a [repo:<name>] tag:$untagged"
  [[ -n "$badtag" ]] && fail "umbrella spec: task(s) tagged with undeclared repo(s):$badtag"
  [[ -z "$untagged$badtag" ]] && pass "every implementation task carries a declared [repo:] tag"
  for r in $declared_repos; do
    grep -q "\[repo:$r\]" "$tasks" || warn "declared repo '$r' has no tasks — drop it from repos: or task it"
  done
else
  stray="$(grep -oE '\[repo:[^]]+\]' "$tasks" | sort -u | paste -sd' ' - || true)"
  [[ -n "$stray" ]] && warn "[repo:] tags present but spec.md declares no repos: frontmatter — tags are ignored:$stray"
fi

# --- 6. per-task structure: Acceptance on every task, Refs outside gate/setup/ship ---
# Accepted "acceptance" labels: *Acceptance:*, *Acceptance (anything):*, *Done:*
# (the o-task convention pairs *Defect:* with *Done:*).
# Also emits one AGENTLINE record per task carrying an *Agent:* line, so gate
# validation below sees the whole task block — not a fixed grep window.
tmp="$(mktemp "${TMPDIR:-/tmp}/sdd-analyze.XXXXXX" 2>/dev/null)" \
  || { echo "  ${RED}✗${RESET} cannot create a temp file under ${TMPDIR:-/tmp}"; exit 1; }
trap 'rm -f "$tmp"' EXIT
awk -v RED="$RED" -v YELLOW="$YELLOW" -v RESET="$RESET" '
  function flush() {
    if (id == "") return
    if (!has_acc) {
      if (oos) { printf "  %s!%s task %s (marked out-of-scope) has no acceptance line\n", YELLOW, RESET, id; warns++ }
      else     { printf "  %s✗%s task %s has no *Acceptance:* (or *Done:*) line\n", RED, RESET, id; errs++ }
    }
    if (!has_refs && stage != "Setup" && stage != "Ship" && stage !~ /Reality/) {
      printf "  %s!%s task %s has no *Refs:* line (stage: %s)\n", YELLOW, RESET, id, stage; warns++
    }
    if (!has_ver && !is_gate && !oos && stage != "Ship") {
      printf "  %s!%s task %s has no *Verify:* line (exact command, or manual: <what to observe>)\n", YELLOW, RESET, id; warns++
    }
    if (is_done && !has_ev && !is_gate && stage != "Ship") {
      printf "  %s!%s task %s is [x] but has no *Evidence:* line — a ticked box without evidence is an unproven claim\n", YELLOW, RESET, id; warns++
    }
    id = ""
  }
  /^##[^#]/ { flush(); sub(/^##[[:space:]]*/,""); stage=$0 }
  /^- \[[ xX~]\] \*\*T[0-9]{3}[a-z0-9]*\*\*/ {
    flush()
    match($0, /T[0-9]{3}[a-z0-9]*/); id = substr($0, RSTART, RLENGTH)
    subj = $0
    has_acc=0; has_refs=0; has_ev=0; has_ver=0; is_gate=0
    is_done = ($0 ~ /^- \[[xX]\]/) ? 1 : 0
    oos = ($0 ~ /OUT OF .*SCOPE/) ? 1 : 0
    if (seen[id]++) { printf "  %s✗%s duplicate task id %s\n", RED, RESET, id; errs++ }
    next
  }
  /\*Acceptance[^*]*:\*/ || /\*Done:\*/ { has_acc=1 }
  /\*Refs:\*/ { has_refs=1 }
  /\*Verify:\*/ { has_ver=1 }
  /\*Evidence[^*]*:\*/ { has_ev=1 }
  /\*Agent:\*/ { is_gate=1; if (id != "") printf "AGENTLINE\t%s\t%s\t%s\n", id, subj, $0 }
  END {
    flush()
    printf "TASKCOUNTS %d %d %d\n", length(seen), errs, warns
  }
' "$tasks" > "$tmp" || true
task_summary=$(grep '^TASKCOUNTS' "$tmp" || true)
grep -v '^TASKCOUNTS\|^AGENTLINE' "$tmp" || true
# An empty summary means the awk pass itself failed — count it as an error
# instead of feeding empty vars into the arithmetic below.
[[ -z "$task_summary" ]] && fail "task analysis pass produced no summary (awk failed?)"
read -r _ tcount terrs twarns <<< "${task_summary:-TASKCOUNTS 0 0 0}"
errors=$((errors + terrs)); warnings=$((warnings + twarns))
(( tcount > 0 )) && pass "$tcount task(s) parsed" || fail "no tasks parsed from tasks.md"
(( tcount > 25 )) && warn "$tcount tasks — past the ~25 guideline; consider splitting the spec"

# --- 7. pre-ship gates present, Agent: files exist ---
# Project root = the ancestor holding .specify (spec dir is <root>/.specify/specs/NNN-slug).
proj_root="$(cd "$SPEC_DIR/../../.." && pwd)"
check_gate() {  # <label> <subject-or-path-regex>
  local label="$1" pat="$2" rec line agent_path
  rec=$(grep '^AGENTLINE' "$tmp" | grep -iE "$pat" | head -1 || true)
  if [[ -z "$rec" ]]; then
    fail "$label gate task not found (no task with an *Agent:* line matches /$pat/)"
    return
  fi
  line="${rec##*$'\t'}"
  # The path is the first .md token after the label; annotations (italic or plain
  # parentheticals, backticks) may surround it.
  agent_path=$(echo "$line" | sed -E 's/.*\*Agent:\*[[:space:]]*//; s/`//g' | grep -oE '[^ 	)(]+\.md' | head -1 || true)
  agent_path="${agent_path/#\~\//$HOME/}"   # [[ -f ]] doesn't expand ~
  if [[ -z "$agent_path" ]]; then
    if echo "$line" | grep -q '<'; then
      fail "$label gate Agent: still a template placeholder"
    else
      fail "$label gate Agent: line has no .md path: $line"
    fi
  else
    # Absolute (incl. ~-expanded) paths are checked as-is; relative paths
    # resolve against the PROJECT root — never the caller's cwd, which would
    # make the verdict depend on where the operator happens to stand.
    local resolved="$agent_path"
    [[ "$agent_path" != /* ]] && resolved="$proj_root/$agent_path"
    if [[ -f "$resolved" ]]; then
      pass "$label gate present, agent file exists"
    else
      fail "$label gate agent file not found: $agent_path"
    fi
  fi
}
check_gate "opponent" 'opponent'
check_gate "reality-check" 'reality.?check'
rm -f "$tmp"

# --- 8. leftover template placeholders ---
leftovers=$(grep -nE '<(Title|Spec Title|One-line title|role|name|handle|slug)>|NNN-slug' "$spec" "$tasks" 2>/dev/null | grep -v 'template' | head -5 || true)
[[ -n "$leftovers" ]] && warn "template placeholders remain:"$'\n'"$(echo "$leftovers" | sed 's/^/      /')"

echo "---"
if (( errors == 0 && warnings == 0 )); then
  echo "${GREEN}consistent${RESET} — spec/plan/tasks line up"
  exit 0
elif (( errors == 0 )); then
  echo "${YELLOW}$warnings warning(s)${RESET}, 0 errors"
  exit 0
else
  echo "${RED}$errors error(s)${RESET}, $warnings warning(s)"
  exit 1
fi
