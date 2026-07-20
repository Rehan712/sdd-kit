#!/usr/bin/env bash
# spec-dispatch-ready.sh — conservatively prove a CLI can receive a fallback.
#
# Usage: spec-dispatch-ready.sh <claude|codex|copilot> <plan|tasks|implement|retro>
#
# Exit: 0 = binary, role adapter, and read-only authentication probe are ready;
#       1 = unavailable (with one concise reason); 2 = bad usage.

set -u

CLI="${1:-}"
ROLE="${2:-}"
if [[ $# -ne 2 || ! "$CLI" =~ ^(claude|codex|copilot)$ || ! "$ROLE" =~ ^(plan|tasks|implement|retro)$ ]]; then
  echo "usage: $(basename "$0") <claude|codex|copilot> <plan|tasks|implement|retro>" >&2
  exit 2
fi

command -v "$CLI" >/dev/null 2>&1 || {
  echo "$CLI unavailable: binary not on PATH" >&2
  exit 1
}

case "$CLI" in
  claude)  ADAPTER="$HOME/.claude/skills/sdd-$ROLE/SKILL.md" ;;
  codex)   ADAPTER="$HOME/.codex/skills/sdd-$ROLE/SKILL.md" ;;
  copilot) ADAPTER="$HOME/.copilot/agents/sdd-$ROLE.agent.md" ;;
esac
[[ -f "$ADAPTER" ]] || {
  echo "$CLI unavailable: missing $ROLE adapter ($ADAPTER)" >&2
  exit 1
}

if [[ -n "${SDD_DISPATCH_AUTH_CHECKER:-}" ]]; then
  [[ -x "$SDD_DISPATCH_AUTH_CHECKER" ]] || {
    echo "$CLI unavailable: auth checker is not executable" >&2
    exit 1
  }
  "$SDD_DISPATCH_AUTH_CHECKER" "$CLI" "$ROLE" >/dev/null 2>&1 || {
    echo "$CLI unavailable: authentication probe failed" >&2
    exit 1
  }
else
  case "$CLI" in
    claude)  claude auth status >/dev/null 2>&1 ;;
    codex)   codex login status >/dev/null 2>&1 ;;
    copilot) copilot -p '/user show' --no-color --log-level error >/dev/null 2>&1 ;;
  esac || {
    echo "$CLI unavailable: authentication probe failed" >&2
    exit 1
  }
fi

echo "$CLI ready for $ROLE"
