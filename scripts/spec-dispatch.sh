#!/usr/bin/env bash
# spec-dispatch.sh — run one SDD phase on ANOTHER CLI/provider, headlessly.
#
# The models.yml `dispatch:` map (see models.example.yml) routes a phase to
# the CLI that should run it — e.g. plan on Claude Code, tasks on Codex
# (gpt-5.5), implement on Copilot (claude-sonnet-5). This script is the one
# dispatcher: it resolves the target CLI, builds that CLI's headless
# invocation with the right model/profile/agent from the SAME policy, runs it
# in the right working root, captures the final message into the spec's
# notes/, and verifies the artifacts on return with the kit's deterministic
# checkers (sdd-analyze.sh / spec-evidence.sh). Artifacts are the interface —
# which provider wrote them never weakens the checks.
#
# Single-provider setups never need this script: no `dispatch:` map = every
# phase runs in the CLI you're typing in, exactly as before.
#
# TRUST MODEL: a dispatched run is non-interactive, so the target CLI runs
# with auto-approved tools — Codex inside its own workspace-write sandbox,
# Copilot with --allow-all-tools, Claude with --dangerously-skip-permissions.
# Running this script IS the approval for that one run; the working root
# (spec worktree for implement) bounds the blast radius. Don't dispatch specs
# you wouldn't let an agent implement unattended.
#
# Dispatchable roles: plan, tasks, implement, retro.
#   specify — never (it's an interview);  review — never (interactive merges).
# Umbrella specs (spec.md `repos:` frontmatter) are not dispatchable yet —
# run those phases interactively.
#
# Usage:
#   spec-dispatch.sh <role> <spec-dir>            # role: plan|tasks|implement|retro
#   spec-dispatch.sh implement <dir> --task T###  # exactly that task, then stop
#   spec-dispatch.sh implement <dir> --all        # all remaining tasks
#   spec-dispatch.sh <role> <dir> --to <cli>      # override the dispatch: map
#   spec-dispatch.sh <role> <dir> --note "<text>" # extra context for the run
#   spec-dispatch.sh <role> <dir> --dry-run       # print the command, run nothing
#   spec-dispatch.sh --help
#
# Exit: 0 = dispatched + artifacts verified; 1 = ran but verification failed;
#       2 = usage; 3 = no dispatch mapping (and no --to); 4 = target CLI or
#       its adapters unavailable; 5 = umbrella spec (unsupported); 6 = the
#       target CLI exited non-zero (captured output kept either way).

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
MP="$HUB_DIR/scripts/model-policy.sh"
STATUS_SH="$HUB_DIR/scripts/spec-status.sh"
WORKTREE_SH="$HUB_DIR/scripts/spec-worktree.sh"

init_colors

usage() { usage_from_header "$0"; exit 0; }

ROLE=""
SPEC_ARG=""
TASK=""
ALL=0
TO=""
NOTE=""
DRY=0

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --task) shift; TASK="${1:?--task needs T###}" ;;
    --all) ALL=1 ;;
    --to) shift; TO="${1:?--to needs claude|codex|copilot}" ;;
    --note) shift; NOTE="${1:?--note needs text}" ;;
    --dry-run) DRY=1 ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) if [[ -z "$ROLE" ]]; then ROLE="$1"; elif [[ -z "$SPEC_ARG" ]]; then SPEC_ARG="$1"; else echo "unexpected arg: $1" >&2; exit 2; fi ;;
  esac
  shift
done

[[ -n "$ROLE" && -n "$SPEC_ARG" ]] || { usage_from_header "$0" >&2; exit 2; }

case "$ROLE" in
  plan|tasks|implement|retro) ;;
  specify) echo "specify is an interview — it runs where the user is, never headless" >&2; exit 2 ;;
  review)  echo "review needs interactive judgment (merge decisions) — not dispatchable" >&2; exit 2 ;;
  *) echo "unknown role '$ROLE' (dispatchable: plan, tasks, implement, retro)" >&2; exit 2 ;;
esac
[[ -n "$TASK" && "$ROLE" != "implement" ]] && { echo "--task only applies to implement" >&2; exit 2; }
(( ALL )) && [[ "$ROLE" != "implement" ]] && { echo "--all only applies to implement" >&2; exit 2; }
[[ -n "$TASK" ]] && (( ALL )) && { echo "--task and --all are mutually exclusive" >&2; exit 2; }

SPEC_DIR="$(cd -- "$SPEC_ARG" 2>/dev/null && pwd)" || { echo "spec dir not found: $SPEC_ARG" >&2; exit 2; }
[[ -f "$SPEC_DIR/spec.md" ]] || { echo "no spec.md in $SPEC_DIR" >&2; exit 2; }
SLUG="$(basename "$SPEC_DIR")"

# Umbrella specs: per-repo worktrees + hub-owned artifacts — not dispatchable yet.
if [[ -n "$(fm_get "$SPEC_DIR/spec.md" repos)" || -n "$(fm_list "$SPEC_DIR/spec.md" repos)" ]]; then
  echo "umbrella spec ($SLUG declares repos:) — dispatch is single-repo only; run the phase interactively" >&2
  exit 5
fi

# Project root: <root>/.specify/specs/<slug> — refuse anything shaped differently.
PROJ_ROOT="$(cd -- "$SPEC_DIR/../../.." && pwd)"
[[ -d "$PROJ_ROOT/.specify/specs/$SLUG" ]] || { echo "spec dir is not at <project>/.specify/specs/<slug>: $SPEC_DIR" >&2; exit 2; }

# --- resolve the target CLI ---------------------------------------------------

CLI="$TO"
if [[ -z "$CLI" ]]; then
  CLI="$("$MP" dispatch "$ROLE" 2>/dev/null)" || true
  if [[ -z "$CLI" ]]; then
    echo "no dispatch mapping for '$ROLE' (models.yml dispatch: block) and no --to given — run the phase locally instead" >&2
    exit 3
  fi
fi
case "$CLI" in
  claude|codex|copilot) ;;
  *) echo "unknown CLI '$CLI' (claude|codex|copilot)" >&2; exit 2 ;;
esac

command -v "$CLI" >/dev/null 2>&1 || { echo "target CLI '$CLI' is not on PATH — install/authenticate it, or drop the dispatch mapping" >&2; exit 4; }
case "$CLI" in
  codex)   [[ -f "$HOME/.codex/skills/sdd-$ROLE/SKILL.md" ]] || { echo "codex adapter ~/.codex/skills/sdd-$ROLE missing — run scripts/build-adapters.sh" >&2; exit 4; } ;;
  copilot) [[ -f "$HOME/.copilot/agents/sdd-$ROLE.agent.md" ]] || { echo "copilot agent ~/.copilot/agents/sdd-$ROLE.agent.md missing — run scripts/build-adapters.sh" >&2; exit 4; } ;;
esac

# --- resolve the working root (and worktree, for implement) -------------------

ROOT="$PROJ_ROOT"
LIVE_SPEC="$SPEC_DIR"
EXTRA_DIRS=()   # dirs the run must reach beyond its working root

if [[ "$ROLE" == "implement" ]]; then
  WT="$(fm_get "$SPEC_DIR/STATUS.md" worktree 2>/dev/null)"
  if [[ -z "$WT" || "$WT" == "none" || ! -d "$WT" ]]; then
    if (( DRY )); then
      WT="<worktree — spec-worktree.sh would cut/reuse it here>"
    else
      WT="$("$WORKTREE_SH" "$SPEC_DIR" | tail -1)" || { echo "spec-worktree.sh failed — cannot dispatch implement" >&2; exit 4; }
    fi
  fi
  if [[ -d "$WT" ]]; then
    # Worktree guard before handing the tree to a foreign agent.
    branch="$(git -C "$WT" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    [[ "$branch" == "spec/$SLUG" ]] || { echo "worktree guard failed: $WT is on '$branch', expected spec/$SLUG" >&2; exit 4; }
    LIVE_SPEC="$WT/.specify/specs/$SLUG"
    [[ -d "$LIVE_SPEC" ]] || { echo "live spec dir missing in worktree: $LIVE_SPEC (commit the spec docs on the base branch first)" >&2; exit 4; }
  else
    LIVE_SPEC="$WT/.specify/specs/$SLUG"   # dry-run placeholder path
  fi
  ROOT="$WT"
  EXTRA_DIRS+=("$PROJ_ROOT")   # worktree git ops write into the main repo's .git
fi
if [[ "$ROLE" == "retro" ]]; then
  EXTRA_DIRS+=("$HUB_DIR")     # retro files lessons into hub knowledge/ + briefs/
fi

# --- capture file + prompt -----------------------------------------------------

TS="$(date +%Y%m%d-%H%M%S)"
CAP="$LIVE_SPEC/notes/dispatch-$ROLE-$TS.md"

task_line=""
if [[ "$ROLE" == "implement" ]]; then
  if [[ -n "$TASK" ]]; then task_line="Execute exactly task $TASK, then stop."
  elif (( ALL )); then task_line="Execute ALL remaining tasks in dependency order (orchestrated mode), then stop."
  else task_line="Execute the next pending task, then stop."
  fi
fi

case "$CLI" in
  codex)   pointer="Your instructions are your installed skill: read ~/.codex/skills/sdd-$ROLE/SKILL.md and execute it for that spec directory." ;;
  copilot) pointer="You are the sdd-$ROLE agent — your agent instructions ARE the phase skill; execute them for that spec directory." ;;
  claude)  pointer="Invoke your sdd-$ROLE skill (the /sdd:$ROLE phase) for that spec directory." ;;
esac

wt_line=""
[[ "$ROLE" == "implement" ]] && wt_line="The spec worktree is already cut: your working directory IS the worktree (branch spec/$SLUG). Run the worktree guard, skip re-cutting, and work only under it.
"

PROMPT="NON-INTERACTIVE DISPATCHED RUN — sent from another CLI via ~/.sdd/scripts/spec-dispatch.sh.
Execute the SDD $ROLE phase for the spec directory: $LIVE_SPEC
$pointer
$wt_line$task_line

Rules for this run (they override any instruction to ask the user):
- Never ask the user anything. An unknown you cannot resolve from the artifacts or code -> write [NEEDS CLARIFICATION: <question>] in the artifact where the answer belongs, mirror it in STATUS.md Open questions, and stop cleanly.
- Follow the skill's grounding rules exactly: evidence only from commands you actually ran; never fabricate.
- Update STATUS.md as the skill instructs, and set active_tool: $CLI.
- End with a short summary: what you produced, what remains, any [NEEDS CLARIFICATION] markers you left.${NOTE:+
- Extra context from the dispatcher: $NOTE}"

# --- build the target CLI's command -------------------------------------------

CMD=("$CLI")
case "$CLI" in
  codex)
    CMD=(codex exec)
    tier="$("$MP" get "$ROLE" codex tier 2>/dev/null)" || tier=""
    if [[ -n "$tier" && -f "$HOME/.codex/sdd-$tier.config.toml" ]]; then
      CMD+=(--profile "sdd-$tier")
    else
      m="$("$MP" get "$ROLE" codex model 2>/dev/null)" || m=""
      [[ -n "$m" ]] && CMD+=(-m "$m")
    fi
    CMD+=(-C "$ROOT" -s workspace-write)
    for d in ${EXTRA_DIRS[@]+"${EXTRA_DIRS[@]}"}; do CMD+=(--add-dir "$d"); done
    CMD+=(--output-last-message "$CAP")
    CMD+=("$PROMPT")
    ;;
  copilot)
    CMD=(copilot --agent "sdd-$ROLE" -p "$PROMPT" -C "$ROOT" --allow-all-tools --no-color --log-level error)
    m="$("$MP" get "$ROLE" copilot model 2>/dev/null)" || m=""
    e="$("$MP" get "$ROLE" copilot effort 2>/dev/null)" || e=""
    [[ -n "$m" ]] && CMD+=(--model "$m")
    [[ -n "$e" ]] && CMD+=(--effort "$e")
    CMD+=(--add-dir "$HUB_DIR")
    for d in ${EXTRA_DIRS[@]+"${EXTRA_DIRS[@]}"}; do [[ "$d" == "$HUB_DIR" ]] || CMD+=(--add-dir "$d"); done
    ;;
  claude)
    CMD=(claude -p "$PROMPT" --dangerously-skip-permissions)
    m="$("$MP" get "$ROLE" claude model 2>/dev/null)" || m=""
    e="$("$MP" get "$ROLE" claude effort 2>/dev/null)" || e=""
    [[ -n "$m" ]] && CMD+=(--model "$m")
    [[ -n "$e" ]] && CMD+=(--effort "$e")
    CMD+=(--add-dir "$HUB_DIR")
    for d in ${EXTRA_DIRS[@]+"${EXTRA_DIRS[@]}"}; do [[ "$d" == "$HUB_DIR" ]] || CMD+=(--add-dir "$d"); done
    ;;
esac

if (( DRY )); then
  echo "dispatch:  $ROLE -> $CLI"
  echo "root:      $ROOT"
  echo "spec:      $LIVE_SPEC"
  echo "capture:   $CAP"
  echo "command:"
  printf '  %q' "${CMD[@]}"
  echo
  exit 0
fi

# --- run ------------------------------------------------------------------------

mkdir -p "$LIVE_SPEC/notes"
bash "$STATUS_SH" set "$LIVE_SPEC" active_tool "$CLI" >/dev/null 2>&1 \
  || echo "  ${YELLOW}!${RESET} could not set active_tool in STATUS.md (continuing)" >&2

echo "dispatching $ROLE -> $CLI (root: $ROOT)" >&2
started=$(date +%s)

rc=0
case "$CLI" in
  codex)
    "${CMD[@]}" || rc=$?
    ;;
  copilot|claude)
    { echo "# Dispatched $ROLE -> $CLI — $(date '+%Y-%m-%d %H:%M:%S')"; echo; } > "$CAP"
    ( cd "$ROOT" && "${CMD[@]}" ) 2>&1 | tee -a "$CAP" || rc=$?
    ;;
esac

echo >&2
echo "elapsed: $(( $(date +%s) - started ))s — captured: $CAP" >&2

if (( rc != 0 )); then
  echo "  ${RED}✗${RESET} $CLI exited $rc — inspect $CAP; artifacts NOT verified" >&2
  exit 6
fi

# --- verify the artifacts (deterministic, provider-agnostic) --------------------

verify_rc=0
case "$ROLE" in
  plan)
    upd="$(fm_get "$LIVE_SPEC/plan.md" updated 2>/dev/null)"
    if [[ "$upd" == "$(date +%Y-%m-%d)" ]]; then
      echo "  ${GREEN}✓${RESET} plan.md updated: $upd"
    else
      echo "  ${RED}✗${RESET} plan.md 'updated:' is '${upd:-unset}' (expected today) — the run may not have written the plan"
      verify_rc=1
    fi
    n=$(grep -c 'NEEDS CLARIFICATION' "$LIVE_SPEC/plan.md" 2>/dev/null || true)
    (( n > 0 )) && echo "  ${YELLOW}!${RESET} $n [NEEDS CLARIFICATION] marker(s) left in plan.md — resolve before /sdd:tasks"
    ;;
  tasks)
    bash "$HUB_DIR/scripts/sdd-analyze.sh" "$LIVE_SPEC" || verify_rc=1
    ;;
  implement)
    bash "$HUB_DIR/scripts/sdd-analyze.sh" "$LIVE_SPEC" || verify_rc=1
    bash "$HUB_DIR/scripts/spec-evidence.sh" "$LIVE_SPEC" || verify_rc=1
    ;;
  retro)
    if [[ -f "$LIVE_SPEC/notes/retro.md" ]]; then
      echo "  ${GREEN}✓${RESET} notes/retro.md written"
    else
      echo "  ${RED}✗${RESET} notes/retro.md missing — the run did not complete the retro"
      verify_rc=1
    fi
    ;;
esac

if (( verify_rc == 0 )); then
  echo "  ${GREEN}✓${RESET} dispatch complete — read $CAP, then continue in your CLI (STATUS.md is current)"
  exit 0
fi
echo "  ${RED}✗${RESET} dispatched run finished but artifacts failed verification — read $CAP and the checker output above" >&2
exit 1
