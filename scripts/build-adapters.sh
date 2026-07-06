#!/usr/bin/env bash
# build-adapters.sh — generate Codex + Copilot adapters from the canonical skills.
#
# Codex CLI and Copilot CLI are single-agent tools: they can't spawn the
# subagents the Claude skills delegate to. Instead of hand-maintaining
# diverging copies, this script generates each adapter as:
#
#   adapted frontmatter  +  a single-agent adaptation preamble  +  the skill body
#
# The preamble tells the agent how to reinterpret subagent delegation
# (adopt the persona as a distinct pass; treat stack experts as lenses).
# Re-run after any skill change (setup.sh calls this).
#
# Installs to:
#   ~/.codex/skills/sdd-<phase>/SKILL.md        (if ~/.codex exists)
#   ~/.copilot/agents/sdd-<phase>.agent.md      (if ~/.copilot exists)
#   plus copies of the gate personas for Copilot.
#
# Model policy (models.yml, optional): each phase's tiered model is applied
# the way each CLI allows —
#   Copilot: `model:` pinned in the generated agent frontmatter (per-agent
#            effort isn't supported; the preamble tells the agent to ask for
#            `--effort` when the session doesn't match).
#   Codex:   skills can't pin models, so a per-tier profile file is written
#            (~/.codex/sdd-<tier>.config.toml — `codex --profile sdd-<tier>`)
#            and the preamble tells the agent to steer the user to it.
#
# Usage: build-adapters.sh [--help]

set -euo pipefail

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN=$'\033[32m'; DIM=$'\033[2m'; RESET=$'\033[0m'

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

PREAMBLE='> **Single-agent adaptation.** You are running on a CLI without subagents. Wherever
> this skill says to delegate to an agent (a stack expert, the SDDOrchestrator, the
> opponent or reality-check gate), do this instead:
> - **Stack experts** — read the named agent file under `~/.sdd/agents/` and the matching
>   overlay under `~/.sdd/templates/stack-overlays/`, and apply them as your senior-reviewer
>   lens while you do the work yourself.
> - **Gates (opponent / reality-check)** — adopt the persona file as a DISTINCT review pass:
>   fresh read of the diff, that persona'\''s checklist and report format, its default
>   adversarial verdict. You are grading work you may have written, so over-correct toward
>   suspicion. Never skip a gate because you cannot spawn it.
> - **Orchestrated mode (--all)** — run the task loop yourself, one task at a time, in
>   dependency order; everything else in the skill still applies.'

# frontmatter_field <file> <key> — read a key from the skill YAML frontmatter.
frontmatter_field() {
  awk -v key="$2" '
    NR==1 && $0=="---" { inside=1; next }
    inside && $0=="---" { exit }
    inside && index($0, key ":")==1 { sub("^" key ":[[:space:]]*", ""); print; exit }
  ' "$1"
}

# skill_body <file> — everything after the closing frontmatter fence.
skill_body() {
  awk 'NR==1 && $0=="---" {inside=1; next} inside && $0=="---" {inside=0; body=1; next} body' "$1"
}

# Model policy (optional). policy <role> <cli> <field> — empty when unset.
MP="$KIT_DIR/scripts/model-policy.sh"
HAVE_POLICY=0
[[ -f "$KIT_DIR/models.yml" ]] && HAVE_POLICY=1
policy() {
  (( HAVE_POLICY )) || return 0
  "$MP" get "$1" "$2" "$3" 2>/dev/null || true
}

# codex_note / copilot_note <role> — per-phase model-policy preamble block.
codex_note() {
  local tier m e
  tier="$(policy "$1" codex tier)"; m="$(policy "$1" codex model)"; e="$(policy "$1" codex effort)"
  [[ -n "$m$e" ]] || return 0
  printf '> **Model policy.** This phase is tiered `%s`: model `%s`%s. Codex cannot switch\n> models from a skill — if the current session does not match, tell the user to relaunch\n> as `codex --profile sdd-%s` (profile installed by the SDD kit) or switch via `/model`,\n> and offer to continue on the current model only if they decline.\n\n' \
    "$tier" "${m:-session-default}" "${e:+ (reasoning \`$e\`)}" "$tier"
}
copilot_note() {
  local m e
  m="$(policy "$1" copilot model)"; e="$(policy "$1" copilot effort)"
  [[ -n "$m$e" ]] || return 0
  printf '> **Model policy.** This agent is pinned to `%s`%s. Copilot cannot set reasoning\n> effort per agent — suggest the user run with `--effort=%s` (or set `effortLevel` in\n> `~/.copilot/settings.json`) when their session effort is lower.\n\n' \
    "${m:-the session model}" "${e:+; the phase wants effort \`$e\`}" "${e:-high}"
}

# stamp_frontmatter <src> <model> — persona copy with `model:` injected (stdout).
stamp_frontmatter() {
  awk -v model="$2" '
    NR==1 && $0=="---" { print; infm=1; next }
    infm && $0=="---" { if (model != "") print "model: " model; print; infm=0; next }
    infm && $0 ~ /^model:/ { next }
    { print }
  ' "$1"
}

built=0

for skill_dir in "$KIT_DIR"/skills/sdd-*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_file="$skill_dir/SKILL.md"
  phase="$(basename "$skill_dir")"                 # e.g. sdd-specify
  role="${phase#sdd-}"                             # e.g. specify
  desc="$(frontmatter_field "$skill_file" description)"

  if [[ -d "$HOME/.codex" ]]; then
    out="$HOME/.codex/skills/$phase/SKILL.md"
    mkdir -p "$(dirname "$out")"
    {
      printf -- '---\nname: %s\ndescription: %s\nmetadata:\n  short-description: %s (SDD)\n  cli: codex\n---\n\n' \
        "$phase" "$desc" "${phase#sdd-}"
      printf '%s\n\n' "$PREAMBLE"
      codex_note "$role"
      skill_body "$skill_file"
    } > "$out"
    echo "  ${GREEN}✓${RESET} codex: $phase"
    built=$((built+1))
  fi

  if [[ -d "$HOME/.copilot" ]]; then
    out="$HOME/.copilot/agents/$phase.agent.md"
    mkdir -p "$(dirname "$out")"
    cp_model="$(policy "$role" copilot model)"
    cp_model_line=""
    [[ -n "$cp_model" ]] && cp_model_line="model: $cp_model"$'\n'
    {
      printf -- '---\nname: %s\ndescription: %s Invoke with `copilot --agent %s`.\ntools: Read, Write, Edit, Bash\n%s---\n\n' \
        "$phase" "$desc" "$phase" "$cp_model_line"
      printf '%s\n\n' "$PREAMBLE"
      copilot_note "$role"
      skill_body "$skill_file"
    } > "$out"
    echo "  ${GREEN}✓${RESET} copilot: $phase${cp_model:+ (model: $cp_model)}"
    built=$((built+1))
  fi
done

# Copilot benefits from local copies of the gate personas (it lists agents by dir).
if [[ -d "$HOME/.copilot" ]]; then
  for persona in opponent.agent.md reality-check.agent.md; do
    role="${persona%.agent.md}"                    # opponent / reality-check
    cp_model="$(policy "$role" copilot model)"
    stamp_frontmatter "$KIT_DIR/agents/$persona" "$cp_model" > "$HOME/.copilot/agents/$persona"
    echo "  ${GREEN}✓${RESET} copilot: $persona (persona copy${cp_model:+, model: $cp_model})"
  done
fi

# Codex per-tier profile files: `codex --profile sdd-<tier>` runs that tier's
# model + reasoning effort. Stale sdd-*.config.toml (removed tiers) are pruned.
if [[ -d "$HOME/.codex" ]] && (( HAVE_POLICY )); then
  keep=""
  while IFS= read -r tier; do
    m="$("$MP" tier "$tier" codex model 2>/dev/null || true)"
    e="$("$MP" tier "$tier" codex effort 2>/dev/null || true)"
    [[ -n "$m$e" ]] || continue
    out="$HOME/.codex/sdd-$tier.config.toml"
    {
      echo "# Generated by sdd-kit (build-adapters.sh) from models.yml — do not edit."
      echo "# Usage: codex --profile sdd-$tier"
      [[ -n "$m" ]] && echo "model = \"$m\""
      [[ -n "$e" ]] && echo "model_reasoning_effort = \"$e\""
    } > "$out"
    keep="$keep sdd-$tier.config.toml"
    echo "  ${GREEN}✓${RESET} codex: profile sdd-$tier (${m:-session model}${e:+, $e})"
    built=$((built+1))
  done < <("$MP" tiers)
  for f in "$HOME"/.codex/sdd-*.config.toml; do
    [[ -f "$f" ]] || continue
    case " $keep " in
      *" $(basename "$f") "*) ;;
      *) rm "$f"; echo "  ${DIM}-${RESET} codex: pruned stale $(basename "$f")" ;;
    esac
  done
fi

if (( built == 0 )); then
  echo "  ${DIM}·${RESET} neither ~/.codex nor ~/.copilot found — no adapters built"
else
  echo "adapters built: $built"
fi
