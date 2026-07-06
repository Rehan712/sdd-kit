#!/usr/bin/env bash
# sdd-status.sh — one-screen dashboard of every spec across all projects.
#
# Reads each registered project's .specify/specs/*/STATUS.md frontmatter and
# prints: project, spec, phase, opponent, reality-check, PR, last update.
# Specs without a STATUS.md show phase "?" — that itself is a finding.
# Hub umbrella specs (<hub>/specs/*, multi-repo) appear as project "hub",
# marked "multi" — their per-repo branches/PRs live in the STATUS Repo matrix.
#
# Worktree-aware: during implement, STATUS truth lives in the spec's worktree
# (per /sdd:implement). For each spec, if the main-checkout STATUS names a
# worktree whose own STATUS is newer, that copy wins (marked "wt" in the last
# column). Specs that exist ONLY in a <repo>.worktrees/* checkout (branch cut,
# docs not yet merged back) get their own rows too.
#
# Usage:
#   sdd-status.sh                    # all projects, all specs
#   sdd-status.sh --project <name>   # one project (registry name or path)
#   sdd-status.sh --phase <phase>    # filter: specify|plan|tasks|implement|review|shipped
#   sdd-status.sh --open             # only specs not yet shipped
#   sdd-status.sh --help

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$HUB_DIR/registry.yml"

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

FILTER_PROJECT=""
FILTER_PHASE=""
OPEN_ONLY=0

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --project) shift; FILTER_PROJECT="${1:?--project needs a name}" ;;
    --phase) shift; FILTER_PHASE="${1:?--phase needs a phase}" ;;
    --open) OPEN_ONLY=1 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

field() { sed -n "s/^$1:[[:space:]]*//p" "$2" 2>/dev/null | head -1 | sed -E 's/[[:space:]]*#.*$//; s/[[:space:]]+$//'; }

printf '%-28s %-52s %-10s %-22s %-22s %-6s %-11s %s\n' PROJECT SPEC PHASE OPPONENT REALITY-CHECK PR UPDATED SRC
printf '%.0s-' {1..150}; echo

# print_row <name> <slug> <status-file-or-empty> <source-mark>
print_row() {
  local name="$1" slug="$2" st="$3" mark="$4"
  local phase opp rc pr upd pr_short
  if [[ -n "$st" && -f "$st" ]]; then
    phase="$(field phase "$st")"; phase="${phase:-?}"
    opp="$(field opponent "$st")";  opp="${opp:-—}"
    rc="$(field reality_check "$st")"; rc="${rc:-—}"
    pr="$(field pr "$st")"; pr="${pr:-none}"
    upd="$(field updated "$st")"; upd="${upd:-?}"
  else
    phase="?"; opp="—"; rc="—"; pr="none"; upd="?"
  fi
  [[ -n "$FILTER_PHASE" && "$phase" != "$FILTER_PHASE" ]] && return
  (( OPEN_ONLY )) && [[ "$phase" == "shipped" ]] && return
  # Shorten PR URLs to #NNN for the table.
  pr_short="$pr"
  [[ "$pr" =~ /pull/([0-9]+) ]] && pr_short="#${BASH_REMATCH[1]}"
  [[ "$pr" == "none" ]] && pr_short="—"
  printf '%-28s %-52s %-10s %-22s %-22s %-6s %-11s %s\n' \
    "$name" "${slug:0:52}" "$phase" "${opp:0:22}" "${rc:0:22}" "$pr_short" "${upd:0:11}" "$mark"
}

# Hub umbrella specs (multi-repo features) — STATUS truth lives in the hub
# spec dir itself; per-repo branches/PRs are in its Repo matrix section.
if [[ -z "$FILTER_PROJECT" || "$FILTER_PROJECT" == "hub" ]]; then
  for sd in "$HUB_DIR"/specs/*/; do
    [[ -d "$sd" ]] || continue
    print_row "hub" "$(basename "$sd")" "$sd/STATUS.md" "multi"
  done
fi

while IFS=$'\t' read -r name path; do
  [[ -z "$path" ]] && continue
  if [[ -n "$FILTER_PROJECT" && "$name" != "$FILTER_PROJECT" && "$path" != "$FILTER_PROJECT" ]]; then
    continue
  fi
  seen=" "
  for sd in "$path"/.specify/specs/*/; do
    [[ -d "$sd" ]] || continue
    slug="$(basename "$sd")"
    seen="$seen$slug "
    st="$sd/STATUS.md"
    mark=""
    # Prefer the worktree copy when it's newer. Trust the main STATUS's
    # `worktree:` field first, but a stale main copy may say `none` while a
    # conventional worktree exists — probe that path too (the lying-field
    # case is exactly when the main copy is most wrong).
    if [[ -f "$st" ]]; then
      wt="$(field worktree "$st")"
      [[ -z "$wt" || "$wt" == "none" ]] && wt="$path.worktrees/$slug"
      wt_st="$wt/.specify/specs/$slug/STATUS.md"
      if [[ -f "$wt_st" ]]; then
        upd_main="$(field updated "$st")"
        upd_wt="$(field updated "$wt_st")"
        if [[ "$upd_wt" > "$upd_main" ]]; then st="$wt_st"; mark="wt"; fi
      fi
    fi
    print_row "$name" "$slug" "$st" "$mark"
  done
  # Specs that exist only in a worktree (branch cut, docs not merged back yet).
  for wsd in "$path".worktrees/*/.specify/specs/*/; do
    [[ -d "$wsd" ]] || continue
    slug="$(basename "$wsd")"
    [[ "$seen" == *" $slug "* ]] && continue
    seen="$seen$slug "
    print_row "$name" "$slug" "$wsd/STATUS.md" "wt-only"
  done
done < <(awk '
  /^[[:space:]]*-[[:space:]]*name:/ { sub(/^[[:space:]]*-[[:space:]]*name:[[:space:]]*/,""); name=$0 }
  /^[[:space:]]*path:/ { sub(/^[[:space:]]*path:[[:space:]]*/,""); print name "\t" $0 }
' "$REGISTRY")

# Briefs summary — one-line rollup of repo-brief freshness (see
# brief-status.sh). Sibling script, same dir as this one. Read-only
# dashboard: a brief-status failure must not crash sdd-status, so any error
# just leaves the counts at 0 instead of aborting.
BRIEF_STATUS="$HUB_DIR/scripts/brief-status.sh"
briefs_total=0; briefs_present=0; briefs_stale=0
if brief_list="$("$BRIEF_STATUS" list 2>/dev/null)"; then
  while IFS=$'\t' read -r _ _ _ _ verdict; do
    [[ -z "$verdict" ]] && continue
    briefs_total=$((briefs_total + 1))
    [[ "$verdict" != "missing" ]] && briefs_present=$((briefs_present + 1))
    [[ "$verdict" == "stale" ]] && briefs_stale=$((briefs_stale + 1))
  done <<< "$brief_list"
fi
briefs_line="briefs: $briefs_present/$briefs_total present, $briefs_stale stale"
(( briefs_present < briefs_total || briefs_stale > 0 )) && briefs_line="$briefs_line (run /sdd:onboard)"
echo "$briefs_line"
