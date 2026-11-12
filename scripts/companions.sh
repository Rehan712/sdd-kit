#!/usr/bin/env bash
# companions.sh — which official skills are installed in each CLI home, and
# the exact command that installs the missing ones.
#
# The kit prefers vendor-maintained skills over its own overlays wherever one
# is listed in the session (templates/official-skills.md is the table). A
# skill that is not installed is silently not preferred, so this is the check
# that says what a machine is missing. It reads files only: it never runs a
# CLI, installs anything, or touches the network.
#
# Homes: every existing ~/.claude and ~/.claude_*, ~/.codex and ~/.codex_*.
# Detection: the plugin's entry in the home's own registry (Claude:
# plugins/installed_plugins.json; Codex: config.toml `[plugins."<name>@...`),
# or a skill directory of that name under <home>/skills (Codex also reads the
# shared ~/.agents/skills).
#
# `core` companions (ponytail, v5 or newer) are part of how the kit works;
# `stack` ones matter only to projects on that stack.
#
# Usage:
#   companions.sh            # human report, grouped by home
#   companions.sh --tsv      # cli, home, id, level, state, version (- when
#                            # unknown), install
#   companions.sh --help
# Exit: 0 = every core companion is current in every home found,
#       1 = a core companion is missing or older than its required major,
#       2 = bad usage.

set -u

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$KIT_DIR/scripts/lib.sh"
init_colors

TSV=0
for arg in "$@"; do
  case "$arg" in
    --help|-h) usage_from_header "$0"; exit 0 ;;
    --tsv) TSV=1 ;;
    check) ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# id | level | min major | plugin name | skill dirs (comma, any one) |
# claude install | codex install
manifest() {
  cat <<'EOF'
ponytail|core|5|ponytail||claude plugin marketplace add DietrichGebert/ponytail && claude plugin install ponytail@ponytail|codex plugin marketplace add DietrichGebert/ponytail && codex plugin add ponytail@ponytail
aws-core|stack||aws-core||claude plugin install aws-core@claude-plugins-official|codex plugin marketplace add aws/agent-toolkit-for-aws && codex plugin add aws-core@agent-toolkit-for-aws
stripe|stack||stripe|stripe-best-practices|claude plugin install stripe@claude-plugins-official|codex plugin add stripe@openai-curated
nextjs|stack||nextjs|next-cache-components-optimizer,next-cache-components-adoption,next-dev-loop|npx skills add vercel/next.js -g -a claude-code -s "*" -y|npx skills add vercel/next.js -g -a codex -s "*" -y
ui-ux-pro-max|stack||ui-ux-pro-max|ui-ux-pro-max|claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill && claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill|npm install -g uipro-cli && uipro init --ai codex
EOF
}

# has_skill_dir <home> <cli> <comma list> — any one of the named skill dirs.
has_skill_dir() {
  local home="$1" cli="$2" d rest="$3"
  [[ -n "$rest" ]] || return 1
  while [[ -n "$rest" ]]; do
    d="${rest%%,*}"
    [[ "$rest" == *,* ]] && rest="${rest#*,}" || rest=""
    [[ -e "$home/skills/$d" ]] && return 0
    [[ "$cli" == codex && -e "$HOME/.agents/skills/$d" ]] && return 0
  done
  return 1
}

# has_plugin <home> <cli> <plugin name>
has_plugin() {
  case "$2" in
    claude) grep -qs "\"$3@" "$1/plugins/installed_plugins.json" ;;
    codex)  grep -qs "^\[plugins\.\"$3@" "$1/config.toml" ;;
  esac
}

# plugin_version <home> <cli> <plugin name> — newest cached version, or empty
# (Codex keeps no per-plugin version on disk that this can read).
plugin_version() {
  [[ "$2" == claude ]] || return 0
  local d best="" v
  for d in "$1"/plugins/cache/*/"$3"/*/; do
    [[ -d "$d" ]] || continue
    v="${d%/}"; v="${v##*/}"
    case "$v" in [0-9]*) ;; *) continue ;; esac
    if [[ -z "$best" ]] || [[ "$(printf '%s\n%s\n' "$best" "$v" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" == "$v" ]]; then
      best="$v"
    fi
  done
  printf '%s' "$best"
}

rows() {
  local home cli id level min plugin dirs c_install x_install state ver install prefix
  for home in "$HOME/.claude" "$HOME"/.claude_* "$HOME/.codex" "$HOME"/.codex_*; do
    [[ -d "$home" ]] || continue
    case "${home##*/}" in .claude*) cli=claude ;; *) cli=codex ;; esac
    # Each command must reach the home it is printed for. A secondary home is
    # addressed through its variable; the default home needs that variable
    # *unset*, and a shell that inherited one (a session launched with
    # CLAUDE_CONFIG_DIR set) would otherwise install into the wrong home.
    prefix=""
    case "${home##*/}" in
      .claude)   [[ -z "${CLAUDE_CONFIG_DIR:-}" ]] || prefix="env -u CLAUDE_CONFIG_DIR " ;;
      .codex)    [[ -z "${CODEX_HOME:-}" ]] || prefix="env -u CODEX_HOME " ;;
      .claude_*) prefix="CLAUDE_CONFIG_DIR=$home " ;;
      .codex_*)  prefix="CODEX_HOME=$home " ;;
    esac
    while IFS='|' read -r id level min plugin dirs c_install x_install; do
      [[ -n "$id" ]] || continue
      ver=""; state=missing
      if has_plugin "$home" "$cli" "$plugin"; then
        state=installed
        ver="$(plugin_version "$home" "$cli" "$plugin")"
        if [[ -n "$min" && -n "$ver" && "${ver%%.*}" -lt "$min" ]]; then state=outdated; fi
      elif has_skill_dir "$home" "$cli" "$dirs"; then
        state=installed
      fi
      if [[ "$cli" == claude ]]; then install="$c_install"; else install="$x_install"; fi
      # `claude`/`codex` commands act on one home, and so does `npx skills`
      # for Claude Code (it links into that home's skills/). For Codex it
      # installs to the shared ~/.agents/skills, and `npm -g` is machine-wide.
      if [[ -n "$prefix" ]]; then
        case "$cli:$install" in
          *:claude\ *|*:codex\ *|claude:npx\ *) install="${prefix}sh -c '$install'" ;;
        esac
      fi
      # `-` for "no version": a tab is IFS whitespace, so an empty field
      # between two tabs would vanish when the row is read back.
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$cli" "${home##*/}" "$id" "$level" "$state" "${ver:--}" "$install"
    done < <(manifest)
  done
}

rc=0
if (( TSV )); then
  rows || true
fi
last=""
while IFS=$'\t' read -r cli home id level state ver install; do
  [[ -n "$id" ]] || continue
  if [[ "$level" == core && "$state" != installed ]]; then rc=1; fi
  (( TSV )) && continue
  if [[ "$home" != "$last" ]]; then echo "  $home"; last="$home"; fi
  case "$state" in
    installed) [[ "$ver" == - ]] && ver=""
               echo "    ${GREEN}✓${RESET} $id${ver:+ $ver}" ;;
    outdated)  echo "    ${YELLOW}!${RESET} $id $ver is older than v5 — update: $install" ;;
    *)         if [[ "$level" == core ]]; then
                 echo "    ${YELLOW}!${RESET} $id missing — $install"
               else
                 echo "    ${DIM}·${RESET} $id not installed — $install"
               fi ;;
  esac
done < <(rows)
exit "$rc"
