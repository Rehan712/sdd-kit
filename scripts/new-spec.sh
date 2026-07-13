#!/usr/bin/env bash
# new-spec.sh — bootstrap a new spec directory inside a project (or the hub).
#
# Copies the hub spec/plan/tasks templates into:
#   <project>/.specify/specs/NNN-slug/{spec.md,plan.md,tasks.md}
#
# NNN is auto-incremented from existing specs (zero-padded to 3 digits).
# Slug is derived from the supplied title, kebab-case, alphanumerics only.
#
# UMBRELLA MODE (--multi): a feature spanning multiple repos gets ONE spec in
# the hub at <hub>/specs/NNN-slug/ (committed — it travels to the whole team).
# --repos declares the repos in scope (validated against system-map.yml /
# registry.yml; role `external` repos are rejected — they never receive tasks).
# The spec gets `repos:` frontmatter and STATUS.md gets a per-repo matrix.
#
# Usage:
#   new-spec.sh "Add eviction policy to memory store"
#   new-spec.sh --project /path/to/project "Title here"
#   new-spec.sh --multi --repos repo-a,repo-b "Cross-repo feature title"
#   new-spec.sh --help

set -euo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
DETECT="$HUB_DIR/scripts/project-detect.sh"
TEMPLATES="$HUB_DIR/templates"

usage() { usage_from_header "$0"; exit 0; }

PROJECT=""
TITLE=""
MULTI=0
REPOS=""

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --project) shift; PROJECT="${1:?--project needs a path}" ;;
    --multi) MULTI=1 ;;
    --repos) shift; REPOS="${1:?--repos needs a comma-separated list}" ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) TITLE="$1" ;;
  esac
  shift
done

# --project takes a PATH (skills have passed repo names here by mistake).
if [[ -n "$PROJECT" && ! -d "$PROJECT" ]]; then
  echo "--project needs an existing directory, got: $PROJECT" >&2
  echo "(for a repo NAME, resolve it first: scripts/system-map.sh path <name>)" >&2
  exit 2
fi

if [[ -z "$TITLE" ]]; then
  echo "usage: new-spec.sh [--project PATH | --multi --repos a,b] \"<title>\"" >&2
  exit 2
fi

if (( MULTI )); then
  [[ -z "$REPOS" ]] && { echo "--multi requires --repos <name,name,...>" >&2; exit 2; }
  REPOS="$(printf '%s' "$REPOS" | tr -d ' ')"
  SYSMAP="$HUB_DIR/scripts/system-map.sh"
  n_repos=0
  for r in ${REPOS//,/ }; do
    n_repos=$((n_repos+1))
    if [[ -f "$HUB_DIR/system-map.yml" ]]; then
      role="$("$SYSMAP" show "$r" 2>/dev/null | sed -n 's/^role: //p' || true)"
      [[ -z "$role" ]] && { echo "repo '$r' not in system-map.yml — add it there first" >&2; exit 1; }
      [[ "$role" == "external" ]] && { echo "repo '$r' has role 'external' — other teams' repos never receive tasks; record the dependency in the spec as [EXTERNAL: …] instead" >&2; exit 1; }
    else
      # No map yet: fall back to registry names.
      grep -qE "^[[:space:]]*-[[:space:]]*name:[[:space:]]*${r}[[:space:]]*$" "$HUB_DIR/registry.yml" 2>/dev/null \
        || { echo "repo '$r' not in registry.yml (and no system-map.yml exists)" >&2; exit 1; }
    fi
  done
  (( n_repos < 2 )) && echo "note: --multi with a single repo — the plain single-repo flow is usually the better fit" >&2
  SPECS_ROOT="$HUB_DIR/specs"
else
  if [[ -z "$PROJECT" ]]; then
    PROJECT="$("$DETECT")" || { echo "could not resolve project from cwd; pass --project" >&2; exit 1; }
  fi
  SPECS_ROOT="$PROJECT/.specify/specs"
fi

mkdir -p "$SPECS_ROOT"

# Find next NNN.
next_n=1
for d in "$SPECS_ROOT"/*/; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  if [[ "$name" =~ ^([0-9]{3})- ]]; then
    n=$((10#${BASH_REMATCH[1]}))
    if (( n >= next_n )); then
      next_n=$((n+1))
    fi
  fi
done
nnn=$(printf '%03d' "$next_n")

# Slugify title.
full_slug=$(echo "$TITLE" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
slug=$(printf '%s' "$full_slug" | cut -c1-50)
if [[ "$slug" != "$full_slug" && "$slug" == *-* ]]; then
  # Truncation landed mid-word — drop the dangling partial segment.
  slug=$(printf '%s' "$slug" | sed -E 's/-[^-]*$//')
fi
slug=$(printf '%s' "$slug" | sed -E 's/-+$//')
[[ -z "$slug" ]] && slug="untitled"

dir="$SPECS_ROOT/$nnn-$slug"
if [[ -d "$dir" ]]; then
  echo "directory already exists: $dir" >&2
  exit 1
fi

mkdir -p "$dir" "$dir/notes"
touch "$dir/notes/.gitkeep"   # gate reports/evidence land here; survive commits
today=$(date +%Y-%m-%d)

# Escape sed replacement metacharacters (\, &, /) so titles like
# "A/B testing & rollout" don't break or corrupt the substitution.
title_esc=$(printf '%s' "$TITLE" | sed -e 's/[\/&\\]/\\&/g')

# Copy templates with light placeholder substitution.
sed -e "s/NNN-slug/$nnn-$slug/" \
    -e "s/<One-line title>/$title_esc/" \
    -e "s/<Title>/$title_esc/" \
    -e "s/YYYY-MM-DD/$today/g" \
    "$TEMPLATES/spec-template.md" > "$dir/spec.md"

sed -e "s/NNN-slug/$nnn-$slug/" \
    -e "s/<Spec Title>/$title_esc/" \
    -e "s/YYYY-MM-DD/$today/g" \
    "$TEMPLATES/plan-template.md" > "$dir/plan.md"

sed -e "s/NNN-slug/$nnn-$slug/" \
    -e "s/<Spec Title>/$title_esc/" \
    -e "s/YYYY-MM-DD/$today/g" \
    "$TEMPLATES/tasks-template.md" > "$dir/tasks.md"

sed -e "s/NNN-slug/$nnn-$slug/" \
    -e "s/<Spec Title>/$title_esc/" \
    -e "s/YYYY-MM-DD/$today/g" \
    "$TEMPLATES/status-template.md" > "$dir/STATUS.md"

if (( MULTI )); then
  repos_yaml="[$(printf '%s' "$REPOS" | sed 's/,/, /g')]"

  # spec.md: pin project to the hub, declare the repos, and append the
  # umbrella-specific authoring notes before the workflow footer.
  awk -v repos_csv="$REPOS" -v repos_yaml="$repos_yaml" '
    /^project:/ && !fm_done {
      print "project: hub  # umbrella spec — spans multiple repos"
      print "repos: " repos_yaml
      fm_done=1
      next
    }
    /^\*Workflow:\*/ && !done {
      print "## Repos in scope (umbrella spec)"
      print ""
      print "| Repo | Why it'\''s touched |"
      print "|---|---|"
      n = split(repos_csv, rs, ",")
      for (i = 1; i <= n; i++) print "| " rs[i] " | <why it'\''s touched> |"
      print ""
      print "- Tag each AC-### in §6 with the repo(s) that prove it: `[repo:<name>]`."
      print "- Dependencies on OTHER teams'\'' repos are never listed above. Record each as"
      print "  `[EXTERNAL: <team/repo> — <what you need> — needed-by <date>]` in §7 Constraints"
      print "  and mirror it in STATUS.md blockers. We stub at the contract, never at guesses."
      print ""
      done=1
    }
    { print }
  ' "$dir/spec.md" > "$dir/spec.md.tmp" && mv "$dir/spec.md.tmp" "$dir/spec.md"

  # STATUS.md: declare the repos in frontmatter and add the per-repo matrix
  # (branch/worktree/PR are per-repo for an umbrella spec; the frontmatter
  # branch/worktree/pr fields stay `none` — the matrix is the truth).
  awk -v repos_csv="$REPOS" -v repos_yaml="$repos_yaml" '
    /^spec:/ && !fm_done {
      print
      print "repos: " repos_yaml
      fm_done=1
      next
    }
    /^## Decisions log/ && !done {
      print "## Repo matrix"
      print ""
      print "> Umbrella spec: branch/worktree/PR live PER REPO here (the frontmatter"
      print "> fields stay `none`). Gates run once, spec-wide, in the frontmatter."
      print ""
      print "| Repo | Branch | Worktree | PR | Tasks done |"
      print "|---|---|---|---|---|"
      n = split(repos_csv, rs, ",")
      for (i = 1; i <= n; i++) print "| " rs[i] " | none | none | none | not-run |"
      print ""
      done=1
    }
    { print }
  ' "$dir/STATUS.md" > "$dir/STATUS.md.tmp" && mv "$dir/STATUS.md.tmp" "$dir/STATUS.md"

  # The awk passes above key on template markers — verify the injections
  # actually landed instead of silently producing a non-umbrella spec.
  grep -q '^repos:' "$dir/spec.md" && grep -q '^## Repos in scope' "$dir/spec.md" \
    || { echo "ERROR: umbrella injection failed for spec.md (template markers moved?)" >&2; exit 1; }
  grep -q '^repos:' "$dir/STATUS.md" && grep -q '^## Repo matrix' "$dir/STATUS.md" \
    || { echo "ERROR: umbrella injection failed for STATUS.md (template markers moved?)" >&2; exit 1; }
fi

echo "$dir"
