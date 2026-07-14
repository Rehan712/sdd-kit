#!/usr/bin/env bash
# build-adapters.sh — generate Codex + Copilot adapters from the canonical skills.
#
# Instead of hand-maintaining diverging copies, this script generates each
# adapter as:
#
#   adapted frontmatter  +  a per-CLI adaptation preamble  +  the skill body
#
# Copilot CLI is single-agent: its preamble reinterprets subagent delegation
# (adopt the persona as a distinct pass; treat stack experts as lenses).
# Codex CLI has real subagents: its preamble instructs delegation to the
# kit-generated subagents below, with the persona-pass as fallback.
# Re-run after any skill change (setup.sh calls this).
#
# Installs to:
#   ~/.codex/skills/sdd-<phase>/SKILL.md        (if ~/.codex exists)
#   ~/.codex/agents/sdd-{opponent,reality-check,implement-hard}.toml
#                                               (if ~/.codex exists + models.yml)
#   ~/.copilot/agents/sdd-<phase>.agent.md      (if ~/.copilot exists)
#   plus copies of the gate personas for Copilot.
#
# Model policy (models.yml, optional): each phase's tiered model is applied
# the way each CLI allows —
#   Copilot: `model:` pinned in the generated agent frontmatter (per-agent
#            effort isn't supported; the preamble tells the agent to ask for
#            `--effort` when the session doesn't match).
#   Codex:   sessions pin models via per-tier profile files
#            (~/.codex/sdd-<tier>.config.toml — `codex --profile sdd-<tier>`);
#            the gates and [hard]-escalation pin theirs via the generated
#            subagent TOMLs (per-agent model + model_reasoning_effort).
#
# Usage: build-adapters.sh [--help]

set -euo pipefail

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$KIT_DIR/scripts/lib.sh"

init_colors

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && { usage_from_header "$0"; exit 0; }

CODEX_PREAMBLE='> **Codex adaptation.** Wherever this skill says to delegate to an agent, do this:
> - **Gates (opponent / reality-check)** — delegate the gate to the kit subagent
>   `sdd-opponent` / `sdd-reality-check` (`~/.sdd` generates them into `~/.codex/agents/`);
>   it reviews with fresh context — never grade your own work when the subagent exists.
>   If it is not installed, fall back to adopting the persona file as a DISTINCT review
>   pass — fresh read of the diff, that persona'\''s checklist, report format, and default
>   adversarial verdict — and over-correct toward suspicion. Never skip a gate.
> - **Escalation** — a task marked `[hard]`, any failed-acceptance retry, and every gate
>   follow-up (`T###o*`/`T###a*`) is delegated to the `sdd-implement-hard` subagent:
>   fresh context + the escalation brief. (Its TOML pins the reasoning-tier model, which
>   applies where the installed Codex honors per-agent model fields; otherwise the model
>   lever is running the session as `codex --profile sdd-reasoning`.) Not installed →
>   do it yourself and say so in the task notes.
> - **Stack experts** — read the named agent file under `~/.sdd/agents/` and the matching
>   overlay under `~/.sdd/templates/stack-overlays/`, and apply them as your senior-reviewer
>   lens while you do the work yourself.
> - **Orchestrated mode (--all)** — run the task loop yourself, one task at a time, in
>   dependency order, delegating per the rules above.'

COPILOT_PREAMBLE='> **Single-agent adaptation.** You are running on a CLI without subagents. Wherever
> this skill says to delegate to an agent (a stack expert, the sdd-orchestrator, the
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

# codex_subagent_toml <name> <role> <description> <instructions-file> — one
# Codex subagent TOML on stdout: kit marker, identity, the role's tier model +
# effort (keys omitted when that CLI field is unset), and the instructions in
# a multi-line LITERAL string so persona backslashes survive unprocessed. A
# persona containing ''' would silently truncate the literal — fail the build
# loudly instead.
codex_subagent_toml() {
  local name="$1" role="$2" desc="$3" instr="$4" m e
  if grep -qF "'''" "$instr"; then
    echo "  ${RED}✗${RESET} $instr contains ''' — cannot embed in a TOML literal string" >&2
    return 1
  fi
  m="$(policy "$role" codex model)"; e="$(policy "$role" codex effort)"
  desc="${desc//\\/\\\\}"; desc="${desc//\"/\\\"}"   # TOML basic-string escapes
  echo "# Generated by sdd-kit (build-adapters.sh) from models.yml — do not edit."
  echo "name = \"$name\""
  echo "description = \"$desc\""
  [[ -n "$m" ]] && echo "model = \"$m\""
  [[ -n "$e" ]] && echo "model_reasoning_effort = \"$e\""
  echo "developer_instructions = '''"
  cat "$instr"
  echo "'''"
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
      printf '%s\n\n' "$CODEX_PREAMBLE"
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
      printf '%s\n\n' "$COPILOT_PREAMBLE"
      copilot_note "$role"
      skill_body "$skill_file"
    } > "$out"
    echo "  ${GREEN}✓${RESET} copilot: $phase${cp_model:+ (model: $cp_model)}"
    built=$((built+1))
  fi
done

# Non-SDD skills (e.g. architecture skills in skills/): plain adapters — no
# single-agent SDD preamble (they don't delegate to subagents) and no model
# note (they have no SDD role). Their references/ files are NOT copied; the
# generated bodies point at the stable ~/.sdd kit path instead.
for skill_dir in "$KIT_DIR"/skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  case "$name" in sdd-*) continue ;; esac
  skill_file="$skill_dir/SKILL.md"
  [[ -f "$skill_file" ]] || continue
  desc="$(frontmatter_field "$skill_file" description)"

  adapted_body="$(skill_body "$skill_file" \
    | sed -e "s|\`references/|\`~/.sdd/skills/$name/references/|g" \
          -e 's|`\.\./|`~/.sdd/skills/|g' \
          -e 's|same skills folder as this skill; paths below are relative to this SKILL.md|installed by the SDD kit; paths below point into ~/.sdd|')"

  if [[ -d "$HOME/.codex" ]]; then
    out="$HOME/.codex/skills/$name/SKILL.md"
    mkdir -p "$(dirname "$out")"
    {
      printf -- '---\nname: %s\ndescription: %s\nmetadata:\n  cli: codex\n---\n\n' "$name" "$desc"
      printf '%s\n' "$adapted_body"
    } > "$out"
    echo "  ${GREEN}✓${RESET} codex: $name"
    built=$((built+1))
  fi

  if [[ -d "$HOME/.copilot" ]]; then
    out="$HOME/.copilot/agents/$name.agent.md"
    mkdir -p "$(dirname "$out")"
    {
      printf -- '---\nname: %s\ndescription: %s Invoke with `copilot --agent %s`.\ntools: Read, Write, Edit, Bash\n---\n\n' "$name" "$desc" "$name"
      printf '%s\n' "$adapted_body"
    } > "$out"
    echo "  ${GREEN}✓${RESET} copilot: $name"
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

# Codex subagents: on Codex the gates run as REAL subagents (fresh context —
# no self-grading) and [hard]/retry/follow-up work escalates to a reasoning-
# tier implementer. Generated from the canonical personas + models.yml into
# ~/.codex/agents/, pruned by the same kit-marker rule as the tier profiles.
# A TOML without the marker is user-authored and is never touched.
if [[ -d "$HOME/.codex" ]] && (( HAVE_POLICY )); then
  mkdir -p "$HOME/.codex/agents"
  tmp_instr="$(mktemp "${TMPDIR:-/tmp}/sdd-adapters.XXXXXX")"
  trap 'rm -f "$tmp_instr"' EXIT
  keep_agents=""
  for subagent in \
    "sdd-opponent|opponent|$KIT_DIR/agents/opponent.agent.md" \
    "sdd-reality-check|reality-check|$KIT_DIR/agents/reality-check.agent.md" \
    "sdd-implement-hard|implement-hard|"; do
    name="${subagent%%|*}"; rest="${subagent#*|}"
    role="${rest%%|*}"; persona="${rest#*|}"
    # An unmapped role means the user opted that role out of the policy —
    # generate nothing and let the prune below collect a leftover TOML (the
    # skill preambles fall back to persona-pass / do-it-yourself).
    if [[ -z "$(policy "$role" codex tier)" ]]; then
      echo "  ${DIM}·${RESET} codex: subagent $name skipped (role '$role' not in models.yml)"
      continue
    fi
    if [[ -n "$persona" ]]; then
      desc="$(frontmatter_field "$persona" description)"
      skill_body "$persona" > "$tmp_instr"
    else
      # implement-hard has no persona file (on Claude it is a runtime role);
      # its instructions live here.
      desc="SDD kit escalation implementer: [hard] tasks, failed-acceptance retries, and gate follow-ups (T###o*/T###a*)."
      cat > "$tmp_instr" <<'EOF'
You are the SDD kit's escalation implementer, spawned for a task marked
[hard], a failed-acceptance retry, or a gate follow-up (T###o*/T###a*).
Work only in the worktree named in your brief; before the first edit,
`git rev-parse --abbrev-ref HEAD` there must print the spec branch you were
given — anything else: stop and report, don't edit.
Implement exactly the quoted task: the smallest change satisfying its
*Acceptance:* and *Refs:*. Transcribe the plan's pattern anchors and internal
seams verbatim — never re-derive or redesign them.
Run the task's *Verify:* command and return: the files you changed, the
command, and its output pasted verbatim. A reply without pasted output is a
failed task. Unknowns: surface them — never guess silently.
EOF
    fi
    out="$HOME/.codex/agents/$name.toml"
    if codex_subagent_toml "$name" "$role" "$desc" "$tmp_instr" > "$out"; then
      keep_agents="$keep_agents $name.toml"
      echo "  ${GREEN}✓${RESET} codex: subagent $name (role $role)"
      built=$((built+1))
    else
      rm -f "$out"
      exit 1
    fi
  done
  for f in "$HOME"/.codex/agents/sdd-*.toml; do
    [[ -f "$f" ]] || continue
    head -1 "$f" | grep -qF "Generated by sdd-kit" || continue
    case " $keep_agents " in
      *" $(basename "$f") "*) ;;
      *) rm "$f"; echo "  ${DIM}-${RESET} codex: pruned stale subagent $(basename "$f")" ;;
    esac
  done
fi

if (( built == 0 )); then
  echo "  ${DIM}·${RESET} neither ~/.codex nor ~/.copilot found — no adapters built"
else
  echo "adapters built: $built"
fi
