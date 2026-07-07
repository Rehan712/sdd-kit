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
#   sdd-status.sh --phase <phase>    # filter: specify|plan|tasks|implement|review|shipped|abandoned
#   sdd-status.sh --open             # only specs not yet shipped/abandoned
#   sdd-status.sh --tsv              # machine-readable: TAB-separated, no header
#                                    # cols: project spec phase opponent
#                                    #       reality_check ci pr updated src
#   sdd-status.sh --help

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
REGISTRY="$HUB_DIR/registry.yml"

usage() { usage_from_header "$0"; exit 0; }

FILTER_PROJECT=""
FILTER_PHASE=""
OPEN_ONLY=0
TSV=0

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --project) shift; FILTER_PROJECT="${1:?--project needs a name}" ;;
    --phase) shift; FILTER_PHASE="${1:?--phase needs a phase}" ;;
    --open) OPEN_ONLY=1 ;;
    --tsv) TSV=1 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

if (( ! TSV )); then
  printf '%-28s %-52s %-10s %-20s %-20s %-8s %-6s %-11s %s\n' PROJECT SPEC PHASE OPPONENT REALITY-CHECK CI PR UPDATED SRC
  printf '%.0s-' {1..156}; echo
fi

# date_num <YYYY-MM-DD-ish> — normalize to a comparable number (20260707);
# anything unparseable becomes 0. A lexicographic compare would misorder
# "2026-7-1" vs "2026-06-30" — this doesn't.
date_num() {
  printf '%s\n' "${1:-}" | awk -F- 'NF==3 && $1+0>0 { printf "%04d%02d%02d", $1, $2, $3; exit } { print 0 }'
}

# print_row <name> <slug> <status-file-or-empty> <source-mark>
print_row() {
  local name="$1" slug="$2" st="$3" mark="$4"
  local phase opp rc ci pr upd pr_short
  if [[ -n "$st" && -f "$st" ]]; then
    phase="$(fm_get "$st" phase)"; phase="${phase:-?}"
    opp="$(fm_get "$st" opponent)";  opp="${opp:-—}"
    rc="$(fm_get "$st" reality_check)"; rc="${rc:-—}"
    ci="$(fm_get "$st" ci)"; ci="${ci:-—}"
    pr="$(fm_get "$st" pr)"; pr="${pr:-none}"
    upd="$(fm_get "$st" updated)"; upd="${upd:-?}"
  else
    phase="?"; opp="—"; rc="—"; ci="—"; pr="none"; upd="?"
  fi
  [[ -n "$FILTER_PHASE" && "$phase" != "$FILTER_PHASE" ]] && return
  (( OPEN_ONLY )) && [[ "$phase" == "shipped" || "$phase" == "abandoned" ]] && return
  if (( TSV )); then
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$name" "$slug" "$phase" "$opp" "$rc" "$ci" "$pr" "$upd" "$mark"
    return
  fi
  # Shorten PR URLs to #NNN for the table.
  pr_short="$pr"
  [[ "$pr" =~ /pull/([0-9]+) ]] && pr_short="#${BASH_REMATCH[1]}"
  [[ "$pr" == "none" ]] && pr_short="—"
  printf '%-28s %-52s %-10s %-20s %-20s %-8s %-6s %-11s %s\n' \
    "$name" "${slug:0:52}" "$phase" "${opp:0:20}" "${rc:0:20}" "${ci:0:8}" "$pr_short" "${upd:0:11}" "$mark"
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
      wt="$(fm_get "$st" worktree)"
      [[ -z "$wt" || "$wt" == "none" ]] && wt="$path.worktrees/$slug"
      wt_st="$wt/.specify/specs/$slug/STATUS.md"
      if [[ -f "$wt_st" ]]; then
        upd_main="$(date_num "$(fm_get "$st" updated)")"
        upd_wt="$(date_num "$(fm_get "$wt_st" updated)")"
        # Numeric compare; on a tie (or both unparseable) prefer the worktree
        # copy — during implement that's where the truth is being written.
        if (( upd_wt >= upd_main )); then st="$wt_st"; mark="wt"; fi
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
done < <(registry_entries "$REGISTRY" | while IFS=$'\t' read -r n p _; do
  printf '%s\t%s\n' "$n" "$(expand_tilde "$p")"
done)

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
if (( ! TSV )); then
  briefs_line="briefs: $briefs_present/$briefs_total present, $briefs_stale stale"
  (( briefs_present < briefs_total || briefs_stale > 0 )) && briefs_line="$briefs_line (run /sdd:onboard)"
  echo "$briefs_line"
fi
