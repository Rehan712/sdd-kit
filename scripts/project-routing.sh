#!/usr/bin/env bash
# project-routing.sh — a project's own planning, implementation and review
# skills/agents, resolved from <project>/.specify/routing.md.
#
# The kit routes work per task by file signal (templates/stack-routing.md).
# A project that brings its own skills or agents — an Android implementer and
# reviewer, an iOS pair, a big-screen pair — declares them in the same shape,
# one row per signal, and its rows are read BEFORE the kit's table:
#
#   | Signal                    | Plan              | Implement             | Review             |
#   |---------------------------|-------------------|-----------------------|--------------------|
#   | `apps/android/**`, `*.kt` | `android-planner` | `android-implementer` | `android-reviewer` |
#   | `apps/ios/**`, `*.swift`  |                   | `ios-implementer`     | `ios-reviewer`     |
#   | `*`                       | `acme-architecture` |                     |                    |
#
# Signal: comma-separated globs against repo-relative paths. `*` crosses `/`
#   (`*.kt` matches `a/b/c.kt`); a signal ending in `/` is that whole directory;
#   a bare `*` is every file. Rows are tried top to bottom.
# Cells:  comma-separated names; empty, `-` or `—` means none. A name resolves,
#   in order, to a project agent (.claude/agents/<name>.md), a project skill
#   (.claude/skills/<name>/SKILL.md, .agents/skills/<name>/SKILL.md), a kit
#   agent, or a kit skill. `plugin:skill` is a session-listed plugin skill and
#   is not verified. Anything else is an error — a name nobody can load is how
#   a project's conventions get skipped without a word.
#
# This script is the one parser: dispatchers ask it instead of reading the
# table, spec-brief.sh copies its answer into the implementer's brief, and
# sdd-doctor.sh runs `check` for every registered project.
#
# Usage:
#   project-routing.sh check <dir>
#   project-routing.sh match <dir> <plan|implement|review>
#                                       # every row of that phase
#   project-routing.sh match <dir> <phase> <path>...
#                                       # rows whose signal matches a path
#   project-routing.sh match <dir> <phase> --task <spec-dir> <T###>
#                                       # ... the paths of the task's *Files:*
#   project-routing.sh match <dir> <phase> --diff <base>
#                                       # ... the files `<base>...HEAD` changed
#   project-routing.sh --help
#
# <dir> is the project root, a spec worktree, or any directory inside one.
# `match` prints one line per target, in table order, each name once:
#   <agent|skill><TAB><name><TAB><file to read, or - for a plugin skill><TAB><signal>
#
# Exit: 0 = ok (no routing.md is ok and prints nothing); 1 = the table is
#       invalid, or the task / diff could not be read; 2 = usage.

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"

init_colors

case "${1:-}" in --help|-h|"") usage_from_header "$0"; [[ -n "${1:-}" ]] && exit 0 || exit 2 ;; esac

CMD="$1"; DIR="${2:-}"
[[ -n "$DIR" ]] || { echo "usage: project-routing.sh $CMD <dir> ..." >&2; exit 2; }
[[ -d "$DIR" ]] || { echo "not a directory: $DIR" >&2; exit 2; }
DIR="$(cd "$DIR" && pwd)"

# The directory's own .specify/routing.md (a project root or a spec worktree),
# else the one at the project root the directory resolves to.
ROOT="$DIR"
if [[ ! -f "$ROOT/.specify/routing.md" ]]; then
  ROOT="$("$HUB_DIR/scripts/project-detect.sh" "$DIR" 2>/dev/null | head -1)" || ROOT=""
fi
TABLE="$ROOT/.specify/routing.md"

# rows — the table as TSV: <line><TAB><signals, comma-joined><TAB><phase><TAB><name>
# (one line per name; a row with no name at all prints phase `-`). Problems
# are printed as `error<TAB><line><TAB><message>`.
rows() {
  awk '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function clean(s) { gsub(/`/, "", s); return trim(s) }
    !/^[ \t]*\|/ { ncol = 0; next }                  # a table ends at a non-table line
    {
      line = $0; sub(/^[ \t]*\|/, "", line); sub(/\|[ \t]*$/, "", line)
      n = split(line, cell, "|")
      if (clean(cell[1]) ~ /^:?-+:?$/) next          # the |---| separator
      if (!ncol) {
        if (tolower(clean(cell[1])) != "signal") next # a table that is not a routing table
        seen = 1; ncol = n
        for (i = 2; i <= n; i++) {
          h = tolower(clean(cell[i])); phase[i] = h
          if (h != "plan" && h != "implement" && h != "review")
            printf "error\t%d\tunknown column \"%s\" (columns: Signal, Plan, Implement, Review)\n", NR, clean(cell[i])
        }
        next
      }
      sig = ""; m = split(cell[1], part, ",")
      for (j = 1; j <= m; j++) { p = clean(part[j]); if (p != "") sig = sig (sig == "" ? "" : ",") p }
      if (sig == "") { printf "error\t%d\trow has no signal\n", NR; next }
      any = 0
      for (i = 2; i <= n && i <= ncol; i++) {
        m = split(cell[i], part, ",")
        for (j = 1; j <= m; j++) {
          name = clean(part[j])
          if (name == "" || name == "-" || name == "—") continue
          printf "%d\t%s\t%s\t%s\n", NR, sig, phase[i], name; any = 1
        }
      }
      if (!any) printf "%d\t%s\t-\t-\n", NR, sig
    }
    END { if (!seen) print "error\t0\tno routing table — the header row must start with | Signal |" }
  ' "$TABLE"
}

# resolve <name> — prints <kind><TAB><path>. Return 1 = nothing by that name,
# 2 = a project agent and a project skill share it, 3 = not a usable name.
resolve() {
  local name="$1" agent="" skill="" d
  [[ "$name" =~ ^[A-Za-z0-9_.:-]+$ && "$name" != *..* ]] || return 3
  if [[ "$name" == *:* ]]; then printf 'skill\t-\n'; return 0; fi
  [[ -f "$ROOT/.claude/agents/$name.md" ]] && agent="$ROOT/.claude/agents/$name.md"
  # shortcut: only the Claude Code and cross-tool (.agents/) project skill
  # directories are searched; add a CLI's own directory here when one is used.
  for d in .claude/skills .agents/skills; do
    [[ -z "$skill" && -f "$ROOT/$d/$name/SKILL.md" ]] && skill="$ROOT/$d/$name/SKILL.md"
  done
  [[ -n "$agent" && -n "$skill" ]] && return 2
  if [[ -n "$agent" ]]; then printf 'agent\t%s\n' "$agent"; return 0; fi
  if [[ -n "$skill" ]]; then printf 'skill\t%s\n' "$skill"; return 0; fi
  for d in "$HUB_DIR/agents/$name.md" "$HUB_DIR/agents/$name.agent.md"; do
    if [[ -f "$d" ]]; then printf 'agent\t%s\n' "$d"; return 0; fi
  done
  if [[ -f "$HUB_DIR/skills/$name/SKILL.md" ]]; then printf 'skill\t%s\n' "$HUB_DIR/skills/$name/SKILL.md"; return 0; fi
  return 1
}

# problems — every reason the table cannot be trusted, one per line.
problems() {
  local a b c d rc
  while IFS=$'\t' read -r a b c d; do
    if [[ "$a" == "error" ]]; then
      if [[ "$b" == "0" ]]; then printf '%s\n' "$c"; else printf 'line %s: %s\n' "$b" "$c"; fi
      continue
    fi
    [[ "$c" == "-" ]] && { printf 'line %s: row "%s" names no skill or agent\n' "$a" "$b"; continue; }
    case "$c" in plan|implement|review) ;; *) continue ;; esac   # its column was already reported
    resolve "$d" >/dev/null; rc=$?
    case "$rc" in
      1) printf 'line %s: "%s" (%s) is not a project agent (.claude/agents/%s.md), a project skill (.claude/skills/%s/SKILL.md), or a kit agent or skill — write a plugin skill as plugin:skill\n' "$a" "$d" "$c" "$d" "$d" ;;
      2) printf 'line %s: "%s" (%s) is both a project agent and a project skill — rename one\n' "$a" "$d" "$c" ;;
      3) printf 'line %s: "%s" (%s) is not a skill or agent name\n' "$a" "$d" "$c" ;;
    esac
  done < <(rows)
}

# matches <signals> <path>... — print the first signal that matches a path.
matches() {
  local signals="$1" sig path; shift
  local IFS=,
  set -f   # split the list on commas without expanding `*` against the cwd (callers run this in a subshell)
  for sig in $signals; do
    [[ "$sig" == */ ]] && sig="$sig*"
    for path in "$@"; do
      # The signal is a glob by design, so it stays unquoted on the right.
      # shellcheck disable=SC2053
      if [[ "$path" == $sig ]]; then printf '%s\n' "$sig"; return 0; fi
    done
  done
  return 1
}

case "$CMD" in
  check)
    if [[ -z "$ROOT" || ! -f "$TABLE" ]]; then
      echo "  ${DIM}·${RESET} no project routing table (${ROOT:-$DIR}/.specify/routing.md) — the kit's stack-routing.md decides"
      exit 0
    fi
    found="$(problems)"
    if [[ -n "$found" ]]; then
      printf '%s\n' "$found" | sed "s/^/  ${RED}✗${RESET} /"
      echo "  ${RED}$(printf '%s\n' "$found" | wc -l | tr -d ' ') error(s)${RESET} in $TABLE"
      exit 1
    fi
    # A project agent with no model of its own runs on the session's — usually
    # the costliest one. The kit cannot stamp it, so say so.
    while IFS=$'\t' read -r _ _ phase name; do
      [[ "$phase" == "-" ]] && continue
      file="$(resolve "$name" | cut -f2)"
      if [[ "$file" == "$ROOT/.claude/agents/"* ]] && ! frontmatter_block "$file" | grep -q '^model:'; then
        echo "  ${YELLOW}!${RESET} project agent '$name' pins no model: in its frontmatter — it runs on the session's model"
      fi
    done < <(rows | sort -u -t$'\t' -k4,4)
    echo "  ${GREEN}✓${RESET} project routing valid ($(rows | cut -f1 | sort -u | wc -l | tr -d ' ') row(s), $(rows | cut -f4 | sort -u | wc -l | tr -d ' ') skill(s)/agent(s)) — $TABLE"
    ;;

  match)
    PHASE="${3:-}"
    case "$PHASE" in
      plan|implement|review) ;;
      *) echo "usage: project-routing.sh match <dir> <plan|implement|review> [<path>... | --task <spec-dir> <T###> | --diff <base>]" >&2; exit 2 ;;
    esac
    shift 3
    [[ -n "$ROOT" && -f "$TABLE" ]] || exit 0
    found="$(problems)"
    if [[ -n "$found" ]]; then
      echo "invalid project routing table $TABLE — fix it before dispatching (project-routing.sh check):" >&2
      printf '%s\n' "$found" | sed 's/^/  /' >&2
      exit 1
    fi

    ALL=0; PATHS=()
    case "${1:-}" in
      "") ALL=1 ;;
      --task)
        SPEC="${2:-}"; TASK="${3:-}"
        [[ -f "$SPEC/tasks.md" && "$TASK" =~ ^T[0-9][0-9][0-9][a-z0-9]*$ ]] \
          || { echo "usage: project-routing.sh match <dir> <phase> --task <spec-dir> <T###>" >&2; exit 2; }
        block="$(task_block "$SPEC/tasks.md" "$TASK")"
        [[ -n "$block" ]] || { echo "task $TASK not found in $SPEC/tasks.md" >&2; exit 1; }
        # The backticked paths of the *Files:* line; without backticks, its
        # comma-separated items.
        files="$(printf '%s\n' "$block" | grep -E '^[[:space:]]*- \*Files:\*' | head -1 | sed -E 's/^[[:space:]]*- \*Files:\*[[:space:]]*//')"
        if [[ "$files" == *'`'* ]]; then
          list="$(printf '%s\n' "$files" | grep -oE '`[^`]+`' | tr -d '`')"
        else
          list="$(printf '%s\n' "$files" | tr ',' '\n' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
        fi
        while IFS= read -r f; do [[ -n "$f" ]] && PATHS+=("$f"); done <<<"$list"
        ;;
      --diff)
        BASE="${2:-}"
        [[ -n "$BASE" ]] || { echo "usage: project-routing.sh match <dir> <phase> --diff <base>" >&2; exit 2; }
        list="$(git -C "$DIR" diff --name-only "$BASE...HEAD" 2>&1)" \
          || { echo "cannot read the diff $BASE...HEAD in $DIR: $list" >&2; exit 1; }
        while IFS= read -r f; do [[ -n "$f" ]] && PATHS+=("$f"); done <<<"$list"
        ;;
      -*) echo "unknown flag: $1" >&2; exit 2 ;;
      *)
        for f in "$@"; do
          f="${f#"$ROOT"/}"; f="${f#./}"
          [[ -n "$f" ]] && PATHS+=("$f")
        done
        ;;
    esac

    printed=" "
    while IFS=$'\t' read -r _ signals phase name; do
      [[ "$phase" == "$PHASE" ]] || continue
      if (( ALL )); then hit="$signals"
      else hit="$(matches "$signals" ${PATHS[@]+"${PATHS[@]}"})" || continue
      fi
      case "$printed" in *" $name "*) continue ;; esac
      printed="$printed$name "
      printf '%s\t%s\n' "$(resolve "$name" | awk -F'\t' -v n="$name" '{ print $1 "\t" n "\t" $2 }')" "$hit"
    done < <(rows)
    ;;

  *) echo "unknown command: $CMD (check | match)" >&2; exit 2 ;;
esac
