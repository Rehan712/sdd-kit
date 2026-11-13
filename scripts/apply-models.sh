#!/usr/bin/env bash
# apply-models.sh — materialize the model policy into build/ for Claude Code.
#
# Claude Code reads a skill's/agent's model + reasoning effort from its YAML
# frontmatter. The canonical files under skills/ and agents/ are committed and
# shared, but the model policy (models.yml) is machine-local — so instead of
# stamping the canonical files, this script generates copies:
#
#   build/skills/sdd-<phase>/SKILL.md   (canonical body + model:/effort: stamped)
#   build/agents/<name>.md              (same)
#
# An agent's stamp holds for its whole run. A skill's covers only the turn that
# loaded it — the next turn (the user's reply, a background agent finishing) is
# back at the session's own effort — so each stamped skill also opens with a
# note (turn_note below) that tells the session how to stay on its tier. The
# note exists only where a stamp does: not in the canonical files, the
# un-stamped copies, or the Codex/Copilot adapters built from them.
#
# sync.sh links the Claude homes at build/ when it exists, else at the
# canonical files. No models.yml (or --clean) removes build/ so the homes fall
# back to the canonical, un-stamped files on the next sync.
#
# Role mapping: skills/sdd-<phase> -> role <phase>; agents/ by filename —
# opponent.agent.md -> opponent, reality-check.agent.md -> reality-check,
# security-reviewer.md -> security-reviewer, sdd-orchestrator.md ->
# orchestrator, test-engineer.md -> test-engineer, sdd-scout.md -> explore,
# *-expert.md -> stack-expert.
# A role missing from models.yml (or an unrecognized agent file) is copied
# un-stamped — it keeps the session default.
#
# Usage: apply-models.sh [--clean] [--help]
# Re-run after editing models.yml, any skill/agent, or pulling the kit
# (setup.sh does). Follow with sync.sh if build/ appeared or disappeared.

set -euo pipefail

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$KIT_DIR/scripts/lib.sh"
POLICY="$KIT_DIR/models.yml"
BUILD="$KIT_DIR/build"
MP="$KIT_DIR/scripts/model-policy.sh"

init_colors

usage() { usage_from_header "$0"; exit 0; }

CLEAN=0
for arg in "$@"; do
  case "$arg" in
    --help|-h) usage ;;
    --clean) CLEAN=1 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if (( CLEAN )) || [[ ! -f "$POLICY" ]]; then
  if [[ -d "$BUILD" ]]; then
    rm -rf "$BUILD"
    echo "  ${YELLOW}-${RESET} build/ removed — run scripts/sync.sh to re-point homes at the canonical files"
  else
    echo "  ${DIM}·${RESET} no model policy (models.yml) — homes link the canonical files"
  fi
  exit 0
fi

# Refuse to build from a broken policy — half-stamped homes are worse than none.
if ! "$MP" check >/dev/null 2>&1; then
  echo "  ${RED}✗${RESET} models.yml invalid — fix it first:" >&2
  "$MP" check >&2 || true
  exit 1
fi

# role_for_agent <basename> — the policy role an agent file belongs to.
role_for_agent() {
  case "$1" in
    opponent.agent.md)      echo "opponent" ;;
    reality-check.agent.md) echo "reality-check" ;;
    security-reviewer.md)   echo "security-reviewer" ;;
    sdd-orchestrator.md)    echo "orchestrator" ;;
    test-engineer.md)       echo "test-engineer" ;;
    sdd-scout.md)           echo "explore" ;;
    *-expert.md)            echo "stack-expert" ;;
    *)                      echo "" ;;
  esac
}

# stamp <src> <dst> <model> <effort> [<note>] — copy src, injecting
# model:/effort: into the frontmatter (replacing any existing lines) and the
# note, when given, as the first paragraph of the body. No frontmatter ->
# plain copy.
stamp() {
  local src="$1" dst="$2" model="$3" effort="$4"
  # ENVIRON, not -v: BSD awk rejects a newline in a -v value.
  NOTE="${5:-}" awk -v model="$model" -v effort="$effort" '
    NR==1 && $0=="---" { print; infm=1; next }
    infm && $0=="---" {
      if (model  != "") print "model: "  model
      if (effort != "") print "effort: " effort
      print; infm=0
      if (ENVIRON["NOTE"] != "") { print ""; print ENVIRON["NOTE"] }
      next
    }
    infm && ($0 ~ /^model:/ || $0 ~ /^effort:/) { next }
    { print }
  ' "$src" > "$dst"
}

# turn_note <skill name> — the paragraph a stamped skill opens with. Claude
# Code applies a skill's model/effort to the turn that loaded it and no
# further (observed: the experts of a /sdd:plan ran in the background, their
# completion notices started new turns, and the review findings were folded
# into the plan at the session's medium instead of the policy's high). A
# foreground agent keeps the turn; re-invoking the skill in a later turn puts
# the stamp back and, while the skill is still in context, reloads nothing.
turn_note() {
  local name="$1" orchestrator=""
  case "$name" in
    sdd-implement|sdd-go) orchestrator=" The long \`sdd-orchestrator\` run of \`--all\` is the one launch that may
stay in the background, so the user can still talk to the session; its
completion notice starts a later turn." ;;
  esac
  cat <<EOF
**Stay on this phase's model policy.** The \`model:\`/\`effort:\` in this
file's frontmatter cover only the turn that loaded this skill: any later turn
— the user's reply, the completion notice of a background agent or command —
silently runs at the session's own effort. So launch the agents this phase
consults in the foreground (\`run_in_background: false\`; several in one
message still run in parallel) and carry on in the same turn; an agent
returning there is not a new turn.$orchestrator When a later turn continues this phase,
make its first call the Skill tool with \`$name\` — alone, with no other tool
call in that message: work sent alongside it still runs at the session's
effort. It answers "already loaded" and puts the stamp back for the calls
after it. If it returns this skill's text again instead (compaction or a
resumed session dropped it), that is not a restart: continue from where
STATUS.md and the artifacts stand.
EOF
}

# Rebuild from scratch — cheap, and removals in skills/ or agents/ propagate.
rm -rf "$BUILD/skills" "$BUILD/agents"
mkdir -p "$BUILD/skills" "$BUILD/agents"

stamped=0
copied=0

for skill_dir in "$KIT_DIR"/skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"          # sdd-plan | aws-serverless-...
  role="${name#sdd-}"                      # plan (non-sdd skills stay unmapped -> copied verbatim)
  cp -R "$skill_dir" "$BUILD/skills/$name"
  model="$("$MP" get "$role" claude model 2>/dev/null || true)"
  effort="$("$MP" get "$role" claude effort 2>/dev/null || true)"
  if [[ -n "$model" || -n "$effort" ]]; then
    stamp "$skill_dir/SKILL.md" "$BUILD/skills/$name/SKILL.md" "$model" "$effort" "$(turn_note "$name")"
    echo "  ${GREEN}✓${RESET} skill $name ← ${model:-session}${effort:+ ($effort)}"
    stamped=$((stamped+1))
  else
    echo "  ${DIM}·${RESET} skill $name — role '$role' unmapped, session default"
    copied=$((copied+1))
  fi
done

for agent in "$KIT_DIR"/agents/*.md; do
  [[ -f "$agent" ]] || continue
  b="$(basename "$agent")"
  role="$(role_for_agent "$b")"
  model=""; effort=""
  if [[ -n "$role" ]]; then
    model="$("$MP" get "$role" claude model 2>/dev/null || true)"
    effort="$("$MP" get "$role" claude effort 2>/dev/null || true)"
  fi
  if [[ -n "$model" || -n "$effort" ]]; then
    stamp "$agent" "$BUILD/agents/$b" "$model" "$effort"
    echo "  ${GREEN}✓${RESET} agent $b ← ${model:-session}${effort:+ ($effort)}"
    stamped=$((stamped+1))
  else
    cp "$agent" "$BUILD/agents/$b"
    if [[ -n "$role" ]]; then
      echo "  ${DIM}·${RESET} agent $b — role '$role' unmapped, session default"
    else
      echo "  ${DIM}·${RESET} agent $b — no role mapping, session default"
    fi
    copied=$((copied+1))
  fi
done

touch "$BUILD/.stamp"
echo "build/: $stamped stamped, $copied passthrough"
