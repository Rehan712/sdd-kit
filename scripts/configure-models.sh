#!/usr/bin/env bash
# configure-models.sh — interactive wizard for the machine-local model policy.
#
# Builds models.yml: which model + reasoning effort each SDD role runs on, per
# CLI (Claude Code, Codex CLI, Copilot CLI). Prompts only for the CLIs
# installed on this machine and carries the defaults for the rest. Re-running
# it reconfigures (defaults come from your current models.yml).
#
# Usage:
#   configure-models.sh               # interactive
#   configure-models.sh --defaults    # write the example defaults, no prompts
#                                     # (refuses if models.yml already exists)
#   configure-models.sh --show        # print the resolved policy table
#   configure-models.sh --no-sync     # don't refresh home links + CLI adapters
#                                     # at the end (setup.sh does that itself)
#
# Answers: Enter accepts the [default]; '-' unsets the key (that CLI keeps its
# session default for the tier). Add extra tiers by editing models.yml by hand
# (see models.example.yml for the schema), then re-run scripts/apply-models.sh.

set -euo pipefail

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$KIT_DIR/scripts/lib.sh"
POLICY="$KIT_DIR/models.yml"
EXAMPLE="$KIT_DIR/models.example.yml"
MP="$KIT_DIR/scripts/model-policy.sh"

init_colors

usage() { usage_from_header "$0"; exit 0; }

DEFAULTS=0; NO_SYNC=0
for arg in "$@"; do
  case "$arg" in
    --help|-h) usage ;;
    --defaults) DEFAULTS=1 ;;
    --no-sync) NO_SYNC=1 ;;
    --show) exec "$MP" show ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

finish() {
  "$KIT_DIR/scripts/apply-models.sh"
  if (( ! NO_SYNC )); then
    # A sync problem must not abort the wizard before adapters are built
    # (set -e would otherwise kill us here on any non-zero exit).
    if "$KIT_DIR/scripts/sync.sh" >/dev/null; then
      echo "  ${GREEN}✓${RESET} Claude home links refreshed"
    else
      echo "  ${YELLOW}!${RESET} sync.sh reported a problem — run scripts/sync.sh to see it" >&2
    fi
    "$KIT_DIR/scripts/build-adapters.sh"
  fi
  echo
  "$MP" show
}

if (( DEFAULTS )); then
  if [[ -f "$POLICY" ]]; then
    echo "models.yml already exists — edit it, or delete it and re-run --defaults" >&2
    exit 1
  fi
  cp "$EXAMPLE" "$POLICY"
  echo "  ${GREEN}+${RESET} models.yml created from models.example.yml"
  finish
  exit 0
fi

if [[ ! -t 0 ]]; then
  echo "no TTY — use --defaults (or edit models.yml directly)" >&2
  exit 2
fi

# Defaults source: current policy if present (reconfigure), else the example.
SRC="$POLICY"; [[ -f "$SRC" ]] || SRC="$EXAMPLE"

HAVE_CODEX=0;   [[ -d "$HOME/.codex" ]]   && HAVE_CODEX=1
HAVE_COPILOT=0; [[ -d "$HOME/.copilot" ]] && HAVE_COPILOT=1

echo "${BOLD}SDD model policy${RESET} — which model runs each phase of the workflow."
echo "Defaults from: ${SRC#"$KIT_DIR"/}"
echo "CLIs: Claude Code$( ((HAVE_CODEX)) && echo ", Codex" )$( ((HAVE_COPILOT)) && echo ", Copilot" )"
(( HAVE_CODEX ))   || echo "  ${DIM}· ~/.codex not found — keeping Codex defaults unprompted${RESET}"
(( HAVE_COPILOT )) || echo "  ${DIM}· ~/.copilot not found — keeping Copilot defaults unprompted${RESET}"
echo "Enter accepts the [default]; '-' unsets a key."
echo

# ask <prompt> <default> — echoes the answer ('-' -> empty).
ask() {
  local a
  read -r -p "  $1 [${2:-unset}]: " a
  [[ -z "$a" ]] && a="$2"
  [[ "$a" == "-" ]] && a=""
  echo "$a"
}

# ask_choice <prompt> <default> <allowed-regex> — re-asks until valid or unset.
ask_choice() {
  local a
  while true; do
    a="$(ask "$1" "$2")"
    [[ -z "$a" || "$a" =~ ^($3)$ ]] && { echo "$a"; return; }
    echo "    ${YELLOW}!${RESET} must be one of: ${3//|/, } (or '-')" >&2
  done
}

TIER_VALS="$(mktemp)"; ROLE_VALS="$(mktemp)"
trap 'rm -f "$TIER_VALS" "$ROLE_VALS"' EXIT

src_tier() { "$MP" --file "$SRC" tier "$1" "$2" "$3" 2>/dev/null || true; }

for tier in $("$MP" --file "$SRC" tiers); do
  case "$tier" in
    reasoning)      echo "${BOLD}Tier '$tier'${RESET} — design + adversarial judgment (specify/plan/tasks, gates)" ;;
    implementation) echo "${BOLD}Tier '$tier'${RESET} — code-writing work (implement, stack experts, tests)" ;;
    *)              echo "${BOLD}Tier '$tier'${RESET}" ;;
  esac

  m="$(ask_choice "Claude model (opus|sonnet|haiku|fable or claude-* id)" "$(src_tier "$tier" claude model)" "opus|sonnet|haiku|fable|inherit|claude-.+")"
  e="$(ask_choice "Claude effort" "$(src_tier "$tier" claude effort)" "low|medium|high|xhigh|max")"
  printf '%s\tclaude_model\t%s\n%s\tclaude_effort\t%s\n' "$tier" "$m" "$tier" "$e" >> "$TIER_VALS"

  if (( HAVE_CODEX )); then
    m="$(ask "Codex model" "$(src_tier "$tier" codex model)")"
    e="$(ask_choice "Codex effort" "$(src_tier "$tier" codex effort)" "minimal|low|medium|high|xhigh")"
  else
    m="$(src_tier "$tier" codex model)"; e="$(src_tier "$tier" codex effort)"
  fi
  printf '%s\tcodex_model\t%s\n%s\tcodex_effort\t%s\n' "$tier" "$m" "$tier" "$e" >> "$TIER_VALS"

  if (( HAVE_COPILOT )); then
    m="$(ask "Copilot model" "$(src_tier "$tier" copilot model)")"
    e="$(ask_choice "Copilot effort" "$(src_tier "$tier" copilot effort)" "low|medium|high|xhigh|max")"
  else
    m="$(src_tier "$tier" copilot model)"; e="$(src_tier "$tier" copilot effort)"
  fi
  printf '%s\tcopilot_model\t%s\n%s\tcopilot_effort\t%s\n' "$tier" "$m" "$tier" "$e" >> "$TIER_VALS"
  echo
done

echo "${BOLD}Role → tier mapping${RESET}"
"$MP" --file "$SRC" roles | sed 's/^/  /'
tiers_list="$("$MP" --file "$SRC" tiers | paste -sd'|' -)"
read -r -p "Remap any roles? [y/N] " remap
if [[ "$remap" =~ ^[Yy] ]]; then
  # Roles stream on fd 3 — ask() must keep reading answers from stdin.
  while IFS=$'\t' read -r -u 3 role dtier; do
    while true; do
      t="$(ask "$role ($tiers_list)" "$dtier")"
      [[ -n "$t" ]] && "$MP" --file "$SRC" tiers | grep -qx "$t" && break
      echo "    ${YELLOW}!${RESET} pick one of: $tiers_list" >&2
    done
    printf '%s\t%s\n' "$role" "$t" >> "$ROLE_VALS"
  done 3< <("$MP" --file "$SRC" roles)
else
  "$MP" --file "$SRC" roles >> "$ROLE_VALS"
fi

# Capture before writing — when reconfiguring, $SRC IS $POLICY and must not be
# read after the output redirect truncates it. The dispatch: map is not part
# of the wizard; carry it over verbatim so reconfiguring never drops it.
TIERS_ORDERED="$("$MP" --file "$SRC" tiers)"
DISPATCH_ROWS="$("$MP" --file "$SRC" dispatch 2>/dev/null || true)"

{
  echo "# Model policy — MACHINE-LOCAL (gitignored). Written by configure-models.sh."
  echo "# Schema + docs: models.example.yml. Re-run scripts/configure-models.sh to"
  echo "# change, use scripts/model-policy.sh update/set/unset for one-off edits"
  echo "# (they re-stamp everything automatically), or edit by hand and re-run"
  echo "# scripts/apply-models.sh + sync.sh + build-adapters.sh (setup.sh does all three)."
  echo
  echo "tiers:"
  for tier in $TIERS_ORDERED; do
    echo "  $tier:"
    for key in claude_model claude_effort codex_model codex_effort copilot_model copilot_effort; do
      v="$(awk -F'\t' -v t="$tier" -v k="$key" '$1==t && $2==k { print $3; exit }' "$TIER_VALS")"
      [[ -n "$v" ]] && echo "    $key: $v"
    done
  done
  echo
  echo "roles:"
  awk -F'\t' '{ printf "  %s: %s\n", $1, $2 }' "$ROLE_VALS"
  if [[ -n "$DISPATCH_ROWS" ]]; then
    echo
    echo "dispatch:"
    awk -F'\t' '{ printf "  %s: %s\n", $1, $2 }' <<<"$DISPATCH_ROWS"
  fi
} > "$POLICY.tmp"
mv "$POLICY.tmp" "$POLICY"

echo
echo "  ${GREEN}✓${RESET} wrote ${POLICY#"$KIT_DIR"/}"
"$MP" check || { echo "  ${YELLOW}!${RESET} fix models.yml and re-run"; exit 1; }
finish
