#!/usr/bin/env bash
# sdd-doctor.sh — validate a project's .specify/ layout.
#
# Checks:
#   - project path exists
#   - .specify/ exists (warning if not — pre-Phase-3 state)
#   - .specify/stack.yml exists and lists stacks
#   - .specify/constitution.md exists
#   - .specify/specs/ directory exists; each spec with tasks.md has a STATUS.md
#   - hub templates/, agents (opponent + reality-check), and scripts are present
#   - each declared stack has a matching overlay in hub
#   - model policy (models.yml): valid, build/ present + fresh, adapters stamped
#   - Codex/Copilot skill copies carry STATUS.md + worktree + opponent wiring
#   - repo briefs (briefs/<repo>.md): missing/stale counts via brief-status.sh
#
# Usage:
#   sdd-doctor.sh [<project-path>]    # defaults to cwd
#   sdd-doctor.sh --all               # iterate all projects in registry.yml
#   sdd-doctor.sh --hub-only           # hub + homes + adapters, no project
#   sdd-doctor.sh --help

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$HUB_DIR/registry.yml"

GREEN=$'\033[32m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
DIM=$'\033[2m'
RESET=$'\033[0m'

errors=0
warnings=0

usage() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

pass()  { echo "  ${GREEN}✓${RESET} $1"; }
fail()  { echo "  ${RED}✗${RESET} $1"; errors=$((errors+1)); }
warn()  { echo "  ${YELLOW}!${RESET} $1"; warnings=$((warnings+1)); }
info()  { echo "  ${DIM}·${RESET} $1"; }

check_hub() {
  echo "Hub: $HUB_DIR"
  [[ -f "$HUB_DIR/constitution.md"            ]] && pass "constitution.md"           || fail "constitution.md missing"
  [[ -f "$HUB_DIR/registry.yml"               ]] && pass "registry.yml"              || fail "registry.yml missing"
  [[ -f "$HUB_DIR/templates/spec-template.md" ]] && pass "templates/spec-template.md"|| fail "spec template missing"
  [[ -f "$HUB_DIR/templates/plan-template.md" ]] && pass "templates/plan-template.md"|| fail "plan template missing"
  [[ -f "$HUB_DIR/templates/tasks-template.md" ]] && pass "templates/tasks-template.md"|| fail "tasks template missing"
  [[ -f "$HUB_DIR/templates/status-template.md" ]] && pass "templates/status-template.md"|| fail "status template missing"
  [[ -d "$HUB_DIR/templates/stack-overlays"   ]] && pass "templates/stack-overlays/" || fail "stack-overlays dir missing"
  [[ -f "$HUB_DIR/agents/opponent.agent.md"      ]] && pass "agents/opponent.agent.md"      || fail "opponent agent missing"
  [[ -f "$HUB_DIR/agents/reality-check.agent.md" ]] && pass "agents/reality-check.agent.md" || fail "reality-check agent missing"
  [[ -f "$HUB_DIR/skills/sdd-retro/SKILL.md"  ]] && pass "skills/sdd-retro (phase 5)"  || fail "sdd-retro skill missing"
  [[ -x "$HUB_DIR/scripts/spec-worktree.sh"   ]] && pass "scripts/spec-worktree.sh"   || fail "spec-worktree.sh missing or not executable"
  [[ -x "$HUB_DIR/scripts/spec-pr.sh"         ]] && pass "scripts/spec-pr.sh"         || fail "spec-pr.sh missing or not executable"
  [[ -x "$HUB_DIR/scripts/sdd-analyze.sh"     ]] && pass "scripts/sdd-analyze.sh"     || fail "sdd-analyze.sh missing or not executable"
  [[ -x "$HUB_DIR/scripts/sdd-status.sh"      ]] && pass "scripts/sdd-status.sh"      || fail "sdd-status.sh missing or not executable"
  [[ -x "$HUB_DIR/scripts/sync.sh"            ]] && pass "scripts/sync.sh"            || fail "sync.sh missing or not executable"
  [[ -x "$HUB_DIR/scripts/system-map.sh"      ]] && pass "scripts/system-map.sh"      || fail "system-map.sh missing or not executable"
  [[ -x "$HUB_DIR/scripts/brief-status.sh"    ]] && pass "scripts/brief-status.sh"    || fail "brief-status.sh missing or not executable"
  # System map (multi-repo features) is optional; when present it must validate.
  if [[ -f "$HUB_DIR/system-map.yml" ]]; then
    if "$HUB_DIR/scripts/system-map.sh" check >/dev/null 2>&1; then
      pass "system-map.yml validates (system-map.sh check)"
    else
      fail "system-map.yml invalid — run scripts/system-map.sh check"
    fi
  else
    info "system-map.yml not present (multi-repo umbrella specs unavailable until created)"
  fi
  # Umbrella specs in the hub: each needs a STATUS.md like project specs do.
  if [[ -d "$HUB_DIR/specs" ]]; then
    local u_total=0 u_missing=0
    for sd in "$HUB_DIR"/specs/*/; do
      [[ -d "$sd" ]] || continue
      u_total=$((u_total+1))
      [[ -f "${sd}STATUS.md" ]] || { warn "umbrella spec $(basename "$sd") has no STATUS.md"; u_missing=$((u_missing+1)); }
    done
    (( u_total > 0 && u_missing == 0 )) && info "all $u_total umbrella spec(s) have STATUS.md"
  fi
  echo
}

# Model policy: models.yml -> stamped build/ copies -> homes + adapters.
check_model_policy() {
  echo "Model policy: models.yml → build/ + CLI adapters"
  if [[ ! -f "$HUB_DIR/models.yml" ]]; then
    info "models.yml not configured — every phase runs on the session model (scripts/configure-models.sh to tier them)"
    if [[ -d "$HUB_DIR/build" ]]; then
      warn "build/ exists without models.yml — run scripts/apply-models.sh (it will clean up), then sync.sh"
    fi
    echo
    return
  fi
  if "$HUB_DIR/scripts/model-policy.sh" check >/dev/null 2>&1; then
    pass "models.yml valid"
  else
    fail "models.yml invalid — run scripts/model-policy.sh check"
  fi
  if [[ ! -f "$HUB_DIR/build/.stamp" ]]; then
    fail "build/ missing — run scripts/apply-models.sh then scripts/sync.sh (homes are serving un-stamped files)"
  else
    stale="$(find "$HUB_DIR/skills" "$HUB_DIR/agents" "$HUB_DIR/models.yml" -newer "$HUB_DIR/build/.stamp" 2>/dev/null | head -1)"
    if [[ -n "$stale" ]]; then
      warn "build/ is stale ($(basename "$stale") changed since last apply) — run scripts/apply-models.sh"
    else
      pass "build/ fresh (skills + agents stamped)"
    fi
  fi
  if [[ -d "$HOME/.codex" ]]; then
    if ls "$HOME"/.codex/sdd-*.config.toml >/dev/null 2>&1; then
      pass "codex sdd-* profiles present ($(ls "$HOME"/.codex/sdd-*.config.toml | xargs -n1 basename | sed 's/\.config\.toml//' | paste -sd', ' -))"
    else
      warn "no codex sdd-* profiles — run scripts/build-adapters.sh"
    fi
  fi
  if [[ -d "$HOME/.copilot" ]] && "$HUB_DIR/scripts/model-policy.sh" get plan copilot model >/dev/null 2>&1; then
    if grep -q '^model:' "$HOME/.copilot/agents/sdd-plan.agent.md" 2>/dev/null; then
      pass "copilot adapters model-pinned"
    else
      warn "copilot adapters not model-pinned — run scripts/build-adapters.sh"
    fi
  fi
  echo
}

# Claude homes publish the hub via symlinks (skills/ + agents/); verify wiring.
check_claude_homes() {
  echo "Claude homes: ~/.claude* symlink wiring (via sync.sh --check)"
  if [[ ! -x "$HUB_DIR/scripts/sync.sh" ]]; then
    fail "sync.sh missing — cannot check home wiring"
    echo
    return
  fi
  local out
  if out="$("$HUB_DIR/scripts/sync.sh" --check 2>&1)"; then
    pass "every home symlinks skills/ + agents/ to the hub"
  else
    fail "home wiring broken — run scripts/sync.sh to repair"
    echo "$out" | grep -E '✗' | sed 's/^/    /'
  fi
  echo
}

# The Codex/Copilot skill copies diverge from the hub by necessity (single-agent
# vs subagent), so we can't line-diff them. Instead we check that each copy carries
# the load-bearing features the hub added: STATUS.md awareness, and (for implement)
# the worktree + opponent wiring. Drift here is a warning, not an error.
check_tool_adapters() {
  echo "Tool adapters: Codex + Copilot copies of the hub skills"
  local codex="$HOME/.codex/skills"
  local copilot="$HOME/.copilot/agents"

  for phase in specify plan tasks implement; do
    local cf="$codex/sdd-$phase/SKILL.md"
    if [[ -f "$cf" ]]; then
      grep -q "STATUS.md" "$cf" && pass "codex sdd-$phase: STATUS.md wired" || warn "codex sdd-$phase: STATUS.md not wired"
    else
      warn "codex sdd-$phase/SKILL.md not found"
    fi
    local pf="$copilot/sdd-$phase.agent.md"
    if [[ -f "$pf" ]]; then
      grep -q "STATUS.md" "$pf" && pass "copilot sdd-$phase: STATUS.md wired" || warn "copilot sdd-$phase: STATUS.md not wired"
    else
      warn "copilot sdd-$phase.agent.md not found"
    fi
  done

  for pair in "codex:$codex/sdd-implement/SKILL.md" "copilot:$copilot/sdd-implement.agent.md"; do
    local tool="${pair%%:*}" file="${pair#*:}"
    [[ -f "$file" ]] || { warn "$tool implement adapter not found"; continue; }
    grep -q "spec-worktree" "$file" && pass "$tool implement: worktree wired" || warn "$tool implement: spec-worktree not wired"
    grep -q "opponent"      "$file" && pass "$tool implement: opponent wired" || warn "$tool implement: opponent gate not wired"
    grep -q "sdd-analyze"   "$file" && pass "$tool implement: analyze wired"  || warn "$tool implement: sdd-analyze not wired"
    grep -qi "retro"        "$file" && pass "$tool implement: retro wired"    || warn "$tool implement: retro not wired"
    grep -q "Legacy specs"  "$file" && pass "$tool implement: legacy-gate backfill wired" || warn "$tool implement: legacy-gate backfill not wired"
  done

  for pair in "codex:$codex/sdd-tasks/SKILL.md" "copilot:$copilot/sdd-tasks.agent.md"; do
    local tool="${pair%%:*}" file="${pair#*:}"
    [[ -f "$file" ]] || continue
    grep -q "sdd-analyze" "$file" && pass "$tool tasks: analyze wired" || warn "$tool tasks: sdd-analyze not wired"
  done

  for pair in "codex:$codex/sdd-plan/SKILL.md" "copilot:$copilot/sdd-plan.agent.md"; do
    local tool="${pair%%:*}" file="${pair#*:}"
    [[ -f "$file" ]] || continue
    grep -q "MET-" "$file" && pass "$tool plan: MET wiring present" || warn "$tool plan: MET-### wiring missing"
  done

  for pair in "codex:$codex/sdd-specify/SKILL.md" "copilot:$copilot/sdd-specify.agent.md"; do
    local tool="${pair%%:*}" file="${pair#*:}"
    [[ -f "$file" ]] || continue
    grep -q "MET-" "$file" && pass "$tool specify: metrics question present" || warn "$tool specify: MET-### question missing"
  done

  [[ -f "$codex/sdd-retro/SKILL.md"   ]] && pass "codex sdd-retro present"   || warn "codex sdd-retro missing"
  [[ -f "$copilot/sdd-retro.agent.md" ]] && pass "copilot sdd-retro present" || warn "copilot sdd-retro missing"
  [[ -f "$copilot/opponent.agent.md" ]] && pass "copilot opponent.agent.md present" || warn "copilot opponent.agent.md missing (Codex reads the hub path inline)"
  echo
}

# Repo briefs (briefs/<repo>.md): missing/stale detection via brief-status.sh.
check_briefs() {
  echo "Repo briefs: briefs/<repo>.md freshness (brief-status.sh)"
  if [[ ! -x "$HUB_DIR/scripts/brief-status.sh" ]]; then
    fail "brief-status.sh missing — cannot check briefs"
    echo
    return
  fi
  local tsv
  tsv="$("$HUB_DIR/scripts/brief-status.sh" list 2>/dev/null)"
  if [[ -z "$tsv" ]]; then
    info "no repos declared in system-map.yml — briefs not applicable"
    echo
    return
  fi
  local missing stale unknown extra
  missing=$(printf '%s\n' "$tsv" | awk -F'\t' '$5 == "missing"' | wc -l | tr -d ' ')
  stale=$(printf '%s\n' "$tsv" | awk -F'\t' '$5 == "stale"' | wc -l | tr -d ' ')
  unknown=$(printf '%s\n' "$tsv" | awk -F'\t' '$5 == "unknown"' | wc -l | tr -d ' ')
  extra=""; (( unknown > 0 )) && extra=", $unknown unknown"
  if (( missing == 0 && stale == 0 && unknown == 0 )); then
    pass "all repo briefs present and fresh"
  else
    warn "briefs: $missing missing, $stale stale$extra (run /sdd:onboard)"
  fi
  echo
}

check_project() {
  local proj="$1"
  echo "Project: $proj"
  if [[ ! -d "$proj" ]]; then
    fail "path does not exist"
    return
  fi
  pass "path exists"

  if [[ ! -d "$proj/.specify" ]]; then
    warn ".specify/ not yet created (Phase 3 work)"
    return
  fi
  pass ".specify/ exists"

  if [[ -f "$proj/.specify/stack.yml" ]]; then
    pass "stack.yml present"
    local stacks
    stacks=$(grep -E '^stacks:' "$proj/.specify/stack.yml" | head -1 | sed -E 's/^stacks:[[:space:]]*\[([^]]*)\].*/\1/' | tr -d ' ' | tr ',' ' ')
    if [[ -n "$stacks" ]]; then
      for s in $stacks; do
        if [[ -f "$HUB_DIR/templates/stack-overlays/$s.md" ]]; then
          pass "overlay for stack '$s'"
        else
          fail "no overlay for stack '$s'"
        fi
      done
    fi
  else
    warn "stack.yml missing"
  fi

  [[ -f "$proj/.specify/constitution.md" ]] && pass "constitution.md" || warn "project constitution.md missing"
  if [[ -d "$proj/.specify/specs" ]]; then
    pass "specs/ directory"
    local missing=0 total=0
    for sd in "$proj"/.specify/specs/*/; do
      [[ -d "$sd" ]] || continue
      total=$((total+1))
      [[ -f "${sd}tasks.md" && ! -f "${sd}STATUS.md" ]] && { warn "no STATUS.md in $(basename "$sd")"; missing=$((missing+1)); }
    done
    (( total > 0 && missing == 0 )) && info "all $total spec(s) have STATUS.md"
  else
    warn "specs/ directory missing"
  fi
  echo
}

list_registry_paths() {
  awk '/^[[:space:]]*path:/ { sub(/^[[:space:]]*path:[[:space:]]*/,""); print }' "$REGISTRY"
}

main() {
  local target="${1:-$PWD}"

  case "$target" in
    --help|-h) usage ;;
    --hub-only)
      check_hub
      check_model_policy
      check_claude_homes
      check_tool_adapters
      check_briefs
      ;;
    --all)
      check_hub
      check_model_policy
      check_claude_homes
      check_tool_adapters
      check_briefs
      if [[ ! -f "$REGISTRY" ]]; then
        fail "registry.yml missing at $REGISTRY"
        return
      fi
      while IFS= read -r p; do
        [[ -z "$p" ]] && continue
        check_project "$p"
      done < <(list_registry_paths)
      ;;
    *)
      check_hub
      check_model_policy
      check_claude_homes
      check_tool_adapters
      check_briefs
      check_project "$(cd "$target" 2>/dev/null && pwd || echo "$target")"
      ;;
  esac

  echo "---"
  if (( errors == 0 && warnings == 0 )); then
    echo "${GREEN}all green${RESET}"
    exit 0
  elif (( errors == 0 )); then
    echo "${YELLOW}$warnings warning(s)${RESET}, 0 errors"
    exit 0
  else
    echo "${RED}$errors error(s)${RESET}, $warnings warning(s)"
    exit 1
  fi
}

main "${1:-}"
