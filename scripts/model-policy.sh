#!/usr/bin/env bash
# model-policy.sh — query/validate the machine-local model policy (models.yml).
#
# The policy maps SDD roles (plan, tasks, opponent, stack-expert, ...) to named
# tiers, and each tier to a model + reasoning effort per CLI. This script is
# the ONE parser for that file — apply-models.sh, build-adapters.sh, and
# sdd-doctor.sh consume it, and skills may call it at runtime.
#
# An optional `dispatch:` map routes a PHASE to the CLI that should run it
# (cross-provider: e.g. tasks on Codex, implement on Copilot). No dispatch
# map = every phase runs in the CLI you're typing in — single-provider
# setups need none of this. `scripts/spec-dispatch.sh` consumes it.
#
# Usage:
#   model-policy.sh get <role> <cli> <field>    # field: model | effort | tier
#   model-policy.sh tier <tier> <cli> <field>   # field: model | effort
#   model-policy.sh roles                       # role<TAB>tier lines
#   model-policy.sh tiers                       # tier names
#   model-policy.sh dispatch <role>             # CLI that runs the role, if mapped
#   model-policy.sh dispatch                    # all mappings: role<TAB>cli lines
#   model-policy.sh show                        # human table of the policy
#   model-policy.sh check                       # validate; exit 1 on errors
#   model-policy.sh --file <path> <cmd> ...     # use another policy file
#
# `get`/`tier`/`dispatch <role>` print the single value and exit 0. An unset
# value prints nothing and exits 1 (callers treat that as "leave the CLI's
# default" / "run locally").
# A missing policy file exits 3 (policy not configured) for every command.

set -euo pipefail

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"
POLICY="$HUB_DIR/models.yml"

init_colors

usage() { usage_from_header "$0"; exit 0; }

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --file) shift; POLICY="${1:?--file needs a path}" ;;
    *) break ;;
  esac
  shift
done

CMD="${1:-}"
[[ -z "$CMD" ]] && usage

[[ -f "$POLICY" ]] || { echo "no model policy at $POLICY (run scripts/configure-models.sh)" >&2; exit 3; }

# Flatten models.yml to TSV:
#   tier<TAB><name><TAB><key><TAB><value>
#   role<TAB><name><TAB><tier>
#   dispatch<TAB><role><TAB><cli>
flatten() {
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    /^tiers:/ { sect="tiers"; next }
    /^roles:/ { sect="roles"; next }
    /^dispatch:/ { sect="dispatch"; next }
    /^[^[:space:]]/ { sect=""; next }                # any other top-level key
    {
      line=$0
      sub(/[[:space:]]+#.*$/, "", line)             # inline comments
      # Count tabs as indent too (2 cols each) — a tab-indented models.yml
      # must not silently parse to zero tiers.
      indent=0; ci=1
      while ((c = substr(line, ci, 1)) == " " || c == "\t") { indent += (c=="\t" ? 2 : 1); ci++ }
      sub(/^[[:space:]]+/, "", line)
      eq=index(line, ":")
      if (eq==0) next
      key=substr(line, 1, eq-1)
      val=substr(line, eq+1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      gsub(/^["'\'']|["'\'']$/, "", val)
      if (sect=="tiers") {
        if (indent==2 && val=="") { tier=key; next }
        if (indent>=4 && tier!="" && val!="") printf "tier\t%s\t%s\t%s\n", tier, key, val
      } else if (sect=="roles") {
        if (indent==2 && val!="") printf "role\t%s\t%s\n", key, val
      } else if (sect=="dispatch") {
        if (indent==2 && val!="") printf "dispatch\t%s\t%s\n", key, val
      }
    }
  ' "$POLICY"
}

tier_field() {  # <tier> <key>
  flatten | awk -F'\t' -v t="$1" -v k="$2" '$1=="tier" && $2==t && $3==k { print $4; exit }'
}

role_tier() {  # <role>
  flatten | awk -F'\t' -v r="$1" '$1=="role" && $2==r { print $3; exit }'
}

case "$CMD" in
  roles)
    flatten | awk -F'\t' '$1=="role" { print $2 "\t" $3 }'
    ;;

  tiers)
    flatten | awk -F'\t' '$1=="tier" { print $2 }' | awk '!seen[$0]++'
    ;;

  dispatch)
    if [[ -n "${2:-}" ]]; then
      v="$(flatten | awk -F'\t' -v r="$2" '$1=="dispatch" && $2==r { print $3; exit }')"
      [[ -n "$v" ]] || exit 1
      echo "$v"
    else
      flatten | awk -F'\t' '$1=="dispatch" { print $2 "\t" $3 }'
    fi
    ;;

  tier)
    T="${2:?tier name required}"; CLI="${3:?cli required}"; FIELD="${4:?field required}"
    v="$(tier_field "$T" "${CLI}_${FIELD}")"
    [[ -n "$v" ]] || exit 1
    echo "$v"
    ;;

  get)
    ROLE="${2:?role required}"; CLI="${3:?cli required}"; FIELD="${4:?field required}"
    t="$(role_tier "$ROLE")"
    [[ -n "$t" ]] || exit 1
    if [[ "$FIELD" == "tier" ]]; then echo "$t"; exit 0; fi
    v="$(tier_field "$t" "${CLI}_${FIELD}")"
    [[ -n "$v" ]] || exit 1
    echo "$v"
    ;;

  show)
    echo "Model policy: $POLICY"
    echo
    printf '%-20s %-16s %-22s %-22s %-22s\n' "ROLE" "TIER" "CLAUDE" "CODEX" "COPILOT"
    while IFS=$'\t' read -r role tier; do
      cm="$(tier_field "$tier" claude_model)";  ce="$(tier_field "$tier" claude_effort)"
      xm="$(tier_field "$tier" codex_model)";   xe="$(tier_field "$tier" codex_effort)"
      pm="$(tier_field "$tier" copilot_model)"; pe="$(tier_field "$tier" copilot_effort)"
      printf '%-20s %-16s %-22s %-22s %-22s\n' "$role" "$tier" \
        "${cm:--}${ce:+ ($ce)}" "${xm:--}${xe:+ ($xe)}" "${pm:--}${pe:+ ($pe)}"
    done < <(flatten | awk -F'\t' '$1=="role" { print $2 "\t" $3 }')
    dispatch_rows="$(flatten | awk -F'\t' '$1=="dispatch" { print "  " $2 " -> " $3 }')"
    if [[ -n "$dispatch_rows" ]]; then
      echo
      echo "Dispatch (phase -> CLI that runs it; spec-dispatch.sh):"
      echo "$dispatch_rows"
    fi
    ;;

  check)
    errors=0; warnings=0
    fail() { echo "  ${RED}✗${RESET} $1"; errors=$((errors+1)); }
    warn() { echo "  ${YELLOW}!${RESET} $1"; warnings=$((warnings+1)); }

    tiers="$(flatten | awk -F'\t' '$1=="tier" { print $2 }' | sort -u)"
    roles="$(flatten | awk -F'\t' '$1=="role" { print $2 }')"
    [[ -n "$tiers" ]] || fail "no tiers defined"
    [[ -n "$roles" ]] || fail "no roles defined"

    while IFS=$'\t' read -r _ role tier; do
      [[ -n "$role" ]] || continue
      grep -qx "$tier" <<<"$tiers" || fail "role '$role' points at undefined tier '$tier'"
    done < <(flatten | awk -F'\t' '$1=="role"')

    while IFS=$'\t' read -r _ tier key val; do
      [[ -n "$tier" ]] || continue
      case "$key" in
        claude_effort|copilot_effort)
          [[ "$val" =~ ^(low|medium|high|xhigh|max)$ ]] || fail "tier '$tier': $key '$val' not in low|medium|high|xhigh|max" ;;
        codex_effort)
          [[ "$val" =~ ^(minimal|low|medium|high|xhigh)$ ]] || fail "tier '$tier': codex_effort '$val' not in minimal|low|medium|high|xhigh" ;;
        claude_model)
          [[ "$val" =~ ^(opus|sonnet|haiku|fable|inherit|claude-.*)$ ]] || warn "tier '$tier': claude_model '$val' is not an alias or claude-* id" ;;
        codex_model|copilot_model) ;;
        *) warn "tier '$tier': unknown key '$key' (ignored)" ;;
      esac
    done < <(flatten | awk -F'\t' '$1=="tier"')

    for known in specify plan tasks implement retro onboard orchestrator opponent reality-check security-reviewer test-engineer stack-expert explore; do
      grep -qx "$known" <<<"$roles" || warn "role '$known' not mapped — that phase/agent keeps the session default"
    done

    # dispatch: — phase -> CLI routing (optional; consumed by spec-dispatch.sh)
    while IFS=$'\t' read -r _ drole dcli; do
      [[ -n "$drole" ]] || continue
      case "$drole" in
        plan|tasks|implement|retro) ;;
        specify) fail "dispatch: 'specify' is an interview — it runs where the user is, never headless" ;;
        review)  fail "dispatch: 'review' needs interactive judgment (merge decisions) — not dispatchable" ;;
        *) fail "dispatch: unknown role '$drole' (dispatchable: plan, tasks, implement, retro)" ;;
      esac
      case "$dcli" in
        claude|codex|copilot) ;;
        *) fail "dispatch: role '$drole' -> unknown CLI '$dcli' (claude|codex|copilot)" ;;
      esac
      case "$dcli" in
        claude|codex|copilot)
          command -v "$dcli" >/dev/null 2>&1 \
            || warn "dispatch: '$drole' -> '$dcli' but the $dcli CLI is not on PATH on this machine" ;;
      esac
    done < <(flatten | awk -F'\t' '$1=="dispatch"')

    if (( errors == 0 )); then
      echo "  ${GREEN}✓${RESET} model policy valid ($(wc -l <<<"$tiers" | tr -d ' ') tiers, $(wc -l <<<"$roles" | tr -d ' ') roles, $warnings warning(s))"
      exit 0
    fi
    echo "  ${RED}$errors error(s)${RESET}, $warnings warning(s) in $POLICY"
    exit 1
    ;;

  *)
    echo "unknown command: $CMD" >&2
    exit 2
    ;;
esac
