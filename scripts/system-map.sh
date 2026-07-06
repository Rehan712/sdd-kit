#!/usr/bin/env bash
# system-map.sh — query and validate the team-shared system map.
#
# The map (system-map.yml, committed) describes every repo the hub governs:
# role, owning team, dependencies, and the contracts between repos. The
# registry (registry.yml, machine-local) maps names to paths on THIS machine.
# This script joins the two.
#
# Usage:
#   system-map.sh list                    # every repo: name, role, team, system
#   system-map.sh show <name>             # full entry for one repo
#   system-map.sh path <name>             # local path via registry.yml (exit 1 if not checked out)
#   system-map.sh deps <name>             # direct depends_on of <name>
#   system-map.sh consumers <name>        # repos that depend on <name> (deps + contract consumers)
#   system-map.sh contracts <name>        # contracts <name> is the source of
#   system-map.sh check                   # validate the map (roles, dangling deps, registry join)
#   system-map.sh --help
#
# Exit: 0 = ok, 1 = not found / check failed, 2 = usage.

set -uo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MAP="$HUB_DIR/system-map.yml"
REGISTRY="$HUB_DIR/registry.yml"

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

CMD="${1:-}"
NAME="${2:-}"

[[ "$CMD" == "--help" || "$CMD" == "-h" || -z "$CMD" ]] && usage
[[ -f "$MAP" ]] || { echo "no system map at $MAP — create it from the schema in its header (see registry.example.yml pointer)" >&2; exit 1; }

# Flatten the map into records, one line per field:
#   repo\t<name>\t<field>\t<value>       (list fields are comma-joined, no spaces)
#   contract\t<id>\t<field>\t<value>
flatten() {
  awk '
    function emit() {
      if (rec_name == "") return
      for (k in f) printf "%s\t%s\t%s\t%s\n", section, rec_name, k, f[k]
      delete f; rec_name = ""
    }
    /^repos:/      { emit(); section="repo"; next }
    /^contracts:/  { emit(); section="contract"; next }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*-[[:space:]]*(name|id):/ {
      emit()
      line=$0; sub(/^[[:space:]]*-[[:space:]]*(name|id):[[:space:]]*/, "", line)
      sub(/[[:space:]]*#.*$/, "", line); sub(/[[:space:]]+$/, "", line)
      rec_name=line; next
    }
    section != "" && rec_name != "" && /^[[:space:]]+[a-z_]+:/ {
      line=$0
      sub(/^[[:space:]]+/, "", line)
      key=line; sub(/:.*/, "", key)
      val=line; sub(/^[a-z_]+:[[:space:]]*/, "", val)
      sub(/[[:space:]]*#.*$/, "", val)
      if (val ~ /^\[/) {                        # list field: strip brackets, tighten commas
        gsub(/^\[|\][[:space:]]*$/, "", val)
        gsub(/,[[:space:]]+/, ",", val)
      }
      sub(/[[:space:]]+$/, "", val)
      f[key]=val
    }
    END { emit() }
  ' "$MAP"
}

# field <section> <name> <field>
field() { flatten | awk -F'\t' -v s="$1" -v n="$2" -v k="$3" '$1==s && $2==n && $3==k { print $4; exit }'; }
# names <section>
names() { flatten | awk -F'\t' -v s="$1" '$1==s { print $2 }' | sort -u; }

repo_exists() { names repo | grep -qx "$1"; }

registry_path() {  # <name> — resolve local path from registry.yml
  [[ -f "$REGISTRY" ]] || return 1
  awk -v want="$1" '
    /^[[:space:]]*-[[:space:]]*name:/ { sub(/^[[:space:]]*-[[:space:]]*name:[[:space:]]*/,""); name=$0 }
    /^[[:space:]]*path:/ && name==want { sub(/^[[:space:]]*path:[[:space:]]*/,""); print; exit }
  ' "$REGISTRY" | head -1
}

case "$CMD" in
  list)
    printf '%-34s %-9s %-12s %s\n' NAME ROLE TEAM SYSTEM
    for n in $(names repo); do
      printf '%-34s %-9s %-12s %s\n' "$n" "$(field repo "$n" role)" "$(field repo "$n" team)" "$(field repo "$n" system)"
    done
    ;;

  show)
    [[ -z "$NAME" ]] && { echo "usage: system-map.sh show <name>" >&2; exit 2; }
    repo_exists "$NAME" || { echo "unknown repo: $NAME" >&2; exit 1; }
    flatten | awk -F'\t' -v n="$NAME" '$1=="repo" && $2==n { printf "%s: %s\n", $3, $4 }'
    p="$(registry_path "$NAME")"
    echo "local_path: ${p:-<not in registry.yml on this machine>}"
    provided=$(flatten | awk -F'\t' '$1=="contract" && $3=="source" { print $2 "\t" $4 }' | awk -F'\t' -v n="$NAME" '$2==n { print $1 }' | paste -sd, -)
    [[ -n "$provided" ]] && echo "provides_contracts: $provided"
    exit 0
    ;;

  path)
    [[ -z "$NAME" ]] && { echo "usage: system-map.sh path <name>" >&2; exit 2; }
    p="$(registry_path "$NAME")"
    if [[ -n "$p" && -d "$p" ]]; then
      echo "$p"
    elif [[ -n "$p" ]]; then
      echo "registered but path missing on this machine: $p" >&2; exit 1
    else
      repo_exists "$NAME" && echo "in system map but not in registry.yml on this machine: $NAME" >&2 \
                          || echo "unknown repo: $NAME" >&2
      exit 1
    fi
    ;;

  deps)
    [[ -z "$NAME" ]] && { echo "usage: system-map.sh deps <name>" >&2; exit 2; }
    repo_exists "$NAME" || { echo "unknown repo: $NAME" >&2; exit 1; }
    field repo "$NAME" depends_on | tr ',' '\n' | sed '/^$/d'
    ;;

  consumers)
    [[ -z "$NAME" ]] && { echo "usage: system-map.sh consumers <name>" >&2; exit 2; }
    repo_exists "$NAME" || { echo "unknown repo: $NAME" >&2; exit 1; }
    {
      for n in $(names repo); do
        field repo "$n" depends_on | tr ',' '\n' | grep -qx "$NAME" && echo "$n"
      done
      # consumers of any contract this repo sources
      for c in $(names contract); do
        [[ "$(field contract "$c" source)" == "$NAME" ]] && \
          field contract "$c" consumers | tr ',' '\n' | sed '/^$/d'
      done
    } | sort -u
    ;;

  contracts)
    [[ -z "$NAME" ]] && { echo "usage: system-map.sh contracts <name>" >&2; exit 2; }
    repo_exists "$NAME" || { echo "unknown repo: $NAME" >&2; exit 1; }
    for c in $(names contract); do
      [[ "$(field contract "$c" source)" == "$NAME" ]] && \
        echo "$c ($(field contract "$c" kind)) — $(field contract "$c" path) → consumers: $(field contract "$c" consumers)"
    done
    exit 0
    ;;

  check)
    GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
    errors=0; warnings=0
    pass() { echo "  ${GREEN}✓${RESET} $1"; }
    fail() { echo "  ${RED}✗${RESET} $1"; errors=$((errors+1)); }
    warn() { echo "  ${YELLOW}!${RESET} $1"; warnings=$((warnings+1)); }
    echo "Checking: $MAP"

    all_repos="$(names repo)"
    [[ -z "$all_repos" ]] && fail "no repos parsed from system-map.yml" || pass "$(echo "$all_repos" | wc -l | tr -d ' ') repo(s) parsed"

    dups=$(flatten | awk -F'\t' '$1=="repo" && $3=="role" { print $2 }' | sort | uniq -d)
    [[ -n "$dups" ]] && fail "duplicate repo name(s): $(echo "$dups" | paste -sd, -)"

    for n in $all_repos; do
      role="$(field repo "$n" role)"
      case "$role" in
        app|service|infra|design|library|external) : ;;
        "") fail "$n: missing role" ;;
        *)  fail "$n: invalid role '$role' (app|service|infra|design|library|external)" ;;
      esac
      for d in $(field repo "$n" depends_on | tr ',' ' '); do
        grep -qx "$d" <<< "$all_repos" || fail "$n: depends_on '$d' is not a repo in the map"
      done
      if [[ "$role" != "external" && "$role" != "design" ]]; then
        p="$(registry_path "$n")"
        if [[ -z "$p" ]]; then
          warn "$n: not in registry.yml on this machine (fine on a teammate's machine; add it to work on it here)"
        elif [[ ! -d "$p" ]]; then
          warn "$n: registry path missing on disk: $p"
        fi
      fi
      remote="$(field repo "$n" remote)"
      if [[ -n "$remote" ]]; then
        [[ "$remote" =~ ^(https://|git@|ssh://) ]] || fail "$n: remote '$remote' is not a valid git URL (expected https://, git@, or ssh://)"
      fi
    done

    for c in $(names contract); do
      src="$(field contract "$c" source)"
      [[ -z "$src" ]] && { fail "contract $c: missing source"; continue; }
      grep -qx "$src" <<< "$all_repos" || fail "contract $c: source '$src' is not a repo in the map"
      for con in $(field contract "$c" consumers | tr ',' ' '); do
        grep -qx "$con" <<< "$all_repos" || fail "contract $c: consumer '$con' is not a repo in the map"
      done
    done
    (( errors == 0 )) && pass "roles, deps, and contracts all resolve"

    echo "---"
    if (( errors == 0 )); then
      echo "${GREEN}map ok${RESET} ($warnings warning(s))"; exit 0
    else
      echo "${RED}$errors error(s)${RESET}, $warnings warning(s)"; exit 1
    fi
    ;;

  *)
    echo "unknown command: $CMD" >&2
    usage
    ;;
esac
