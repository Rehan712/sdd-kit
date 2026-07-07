#!/usr/bin/env bash
# lib.sh — shared parsing helpers for the SDD kit scripts. Source, don't run:
#
#   . "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
#
# Everything here is bash-3.2 and BSD-tool safe (no sed -i, no grep -P, no
# associative arrays). Helpers echo their result; "no value" is an empty
# echo with exit 0, so `set -euo pipefail` callers never die on a missing key.
#
# Frontmatter helpers (fm_*) read ONLY the YAML between the opening `---` on
# line 1 and the closing `---` — a `repos:` or `phase:` in the document body
# is never mistaken for state. Plain-YAML helpers (yml_*) are for files with
# no fence (stack.yml, registry.yml, models.yml).

# --- value cleanup -----------------------------------------------------------

# _yml_clean <raw> — strip an inline comment and surrounding quotes.
# Per YAML, a `#` only starts a comment when preceded by whitespace: a value
# like `"#partner-team on Slack"` or `foo#bar` is data, not comment.
_yml_clean() {
  local v="$1"
  case "$v" in
    \"*) v="${v#\"}"; v="${v%%\"*}" ;;
    \'*) v="${v#\'}"; v="${v%%\'*}" ;;
    *)   v="$(printf '%s' "$v" | sed -E 's/[[:space:]]+#.*$//; s/[[:space:]]+$//')" ;;
  esac
  printf '%s\n' "$v"
}

# --- frontmatter (--- fenced) ------------------------------------------------

# frontmatter_block <file> — print the YAML inside the fence; empty if none.
frontmatter_block() {
  [[ -f "${1:-}" ]] || return 0
  awk 'NR==1 { if ($0 != "---") exit; next }
       /^---[[:space:]]*$/ { exit }
       { print }' "$1"
}

# fm_get <file> <key> — scalar value, comment/quote-stripped. Empty if absent.
fm_get() {
  local raw
  raw="$(frontmatter_block "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1)"
  [[ -n "$raw" ]] || return 0
  _yml_clean "$raw"
}

# fm_get_raw <file> <key> — no comment/quote stripping (titles may contain '#').
fm_get_raw() {
  frontmatter_block "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1 \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

# fm_list <file> <key> — list value as ONE space-separated line.
# Accepts inline (`key: [a, b]`) and block (`key:` + `  - a` lines) forms.
fm_list() { _yml_list_from "$(frontmatter_block "$1")" "$2"; }

# fm_set <file> <key> <value> — set/replace a scalar key inside the frontmatter.
# Preserves an existing inline `# comment` on the line; appends the key just
# before the closing --- when missing. Exit 1 if the file has no frontmatter.
fm_set() {
  local file="$1" key="$2" value="$3" tmp
  [[ -f "$file" ]] || { echo "fm_set: no such file: $file" >&2; return 1; }
  [[ "$(head -1 "$file")" == "---" ]] \
    || { echo "fm_set: $file has no frontmatter block" >&2; return 1; }
  tmp="$(mktemp "${TMPDIR:-/tmp}/fm_set.XXXXXX")" || return 1
  awk -v key="$key" -v val="$value" '
    NR==1 && $0=="---" { infm=1; print; next }
    infm && index($0, key ":") == 1 {
      cmt = ""
      if (match($0, /[[:space:]]+#.*$/)) cmt = substr($0, RSTART)
      print key ": " val cmt; done=1; next
    }
    infm && /^---[[:space:]]*$/ { if (!done) print key ": " val; infm=0; print; next }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# --- plain YAML (no fence): stack.yml, registry.yml --------------------------

# yml_get <file> <key> — scalar value from an unfenced YAML file.
yml_get() {
  local raw
  raw="$(sed -n "s/^$2:[[:space:]]*//p" "${1:-/dev/null}" 2>/dev/null | head -1)"
  [[ -n "$raw" ]] || return 0
  _yml_clean "$raw"
}

# yml_list <file> <key> — list (inline or block) from an unfenced YAML file.
yml_list() { _yml_list_from "$(cat "${1:-/dev/null}" 2>/dev/null)" "$2"; }

# _yml_list_from <yaml-text> <key> — space-separated items, inline or block form.
_yml_list_from() {
  printf '%s\n' "$1" | awk -v key="$2" '
    index($0, key ":") == 1 && $0 ~ /\[/ {
      line=$0; sub(/^[^[]*\[/, "", line); sub(/\].*$/, "", line)
      gsub(/[[:space:]"\047]/, "", line); gsub(/,/, " ", line)
      print line; exit
    }
    index($0, key ":") == 1 { inblock=1; next }
    inblock && /^[[:space:]]+-[[:space:]]*/ {
      item=$0; sub(/^[[:space:]]+-[[:space:]]*/, "", item)
      sub(/[[:space:]]+#.*$/, "", item); gsub(/["\047]/, "", item)
      sub(/[[:space:]]+$/, "", item)
      if (item != "") items = items (items=="" ? "" : " ") item
      next
    }
    inblock { exit }
    END { if (items != "") print items }
  '
}

# --- registry.yml -------------------------------------------------------------

# expand_tilde <path> — expand a leading ~ or ~/ to $HOME.
expand_tilde() {
  case "${1:-}" in
    "~")   printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s\n' "$HOME/${1#\~/}" ;;
    *)     printf '%s\n' "${1:-}" ;;
  esac
}

# registry_entries <registry.yml> — one line per project:
#   name<TAB>path<TAB>stacks (space-separated)
# Field order inside an entry doesn't matter; `~` in path is expanded;
# quotes and inline comments are stripped. Entries missing name or path
# are skipped (they'd be unusable anyway).
registry_entries() {
  [[ -f "${1:-}" ]] || return 0
  awk '
    function clean(s) {
      sub(/[[:space:]]+#.*$/, "", s); gsub(/["\047]/, "", s)
      sub(/[[:space:]]+$/, "", s); return s
    }
    function flush() {
      if (name != "" && path != "") printf "%s\t%s\t%s\n", name, path, stacks
      name=""; path=""; stacks=""; inlist=""
    }
    /^[[:space:]]*#/ { next }
    # A dash line carrying a key (- name: x) starts a NEW entry; a bare dash
    # line (- rust) is an item of the current block list (e.g. stacks:).
    /^[[:space:]]*-[[:space:]]*[A-Za-z_]+:/ { flush() }
    /^[[:space:]]*-[[:space:]]*[^:]*$/ && !/^[[:space:]]*-[[:space:]]*$/ {
      if (inlist == "stacks") {
        item=$0; sub(/^[[:space:]]*-[[:space:]]*/, "", item); item=clean(item)
        if (item != "") stacks = stacks (stacks=="" ? "" : " ") item
      }
      next
    }
    {
      line=$0; sub(/^[[:space:]]*-?[[:space:]]*/, "", line)
      if      (line ~ /^name:/)   { sub(/^name:[[:space:]]*/, "", line);  name=clean(line); inlist="" }
      else if (line ~ /^path:/)   { sub(/^path:[[:space:]]*/, "", line);  path=clean(line); inlist="" }
      else if (line ~ /^stacks:[[:space:]]*$/) { stacks=""; inlist="stacks" }
      else if (line ~ /^stacks:/) {
        sub(/^stacks:[[:space:]]*\[?/, "", line); sub(/\].*$/, "", line)
        gsub(/[[:space:]"\047]/, "", line); gsub(/,/, " ", line); stacks=line; inlist=""
      }
      else if (line ~ /^[A-Za-z_]+:/) { inlist="" }
    }
    END { flush() }
  ' "$1"
}

# registry_path_for <registry.yml> <name> — the project path (tilde-expanded);
# empty + exit 0 when not registered.
registry_path_for() {
  local line
  line="$(registry_entries "$1" | awk -F'\t' -v n="$2" '$1==n { print $2; exit }')"
  [[ -n "$line" ]] || return 0
  expand_tilde "$line"
}

# --- misc ---------------------------------------------------------------------

# init_colors — set GREEN/RED/YELLOW/DIM/BOLD/RESET. Empty when stdout is not
# a TTY or NO_COLOR is set (https://no-color.org) — piped/CI output must not
# be full of escape codes.
init_colors() {
  if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
    GREEN=""; RED=""; YELLOW=""; DIM=""; BOLD=""; RESET=""
  else
    GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'
    DIM=$'\033[2m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
  fi
}

# spec_declared_repos <spec-dir> — the umbrella `repos:` list from spec.md
# frontmatter (space-separated); empty for single-repo specs.
spec_declared_repos() { fm_list "${1:-}/spec.md" repos; }

# usage_from_header <script-path> — print the script's leading `#` comment
# block (skipping the shebang) — immune to line-number drift, unlike sed -n.
usage_from_header() {
  awk 'NR==1 { next }
       /^#/ { sub(/^# ?/, ""); print; next }
       { exit }' "$1"
}
