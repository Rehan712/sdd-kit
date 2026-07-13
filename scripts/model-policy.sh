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
#                                               # (--file must PRECEDE the command;
#                                               # edits on a --file target skip the
#                                               # re-stamp, like --no-apply)
#
# Editing (non-interactive; the wizard scripts/configure-models.sh remains the
# interactive path). Every edit is validated BEFORE it is saved — an invalid
# value never lands in models.yml — and then re-stamps the generated skill and
# agent copies plus the Codex/Copilot adapters automatically, so the change is
# live everywhere without a separate apply step:
#   model-policy.sh update <role> <model> [<effort>] [--cli <cli>] [--solo]
#                                               # role-centric shortcut: edits the
#                                               # tier the role points at (default
#                                               # --cli claude); warns about sibling
#                                               # roles sharing that tier. --solo:
#                                               # sharing siblings keep the old tier —
#                                               # the role is split onto its own new
#                                               # tier (named after the role, cloned
#                                               # from the shared one) before the edit
#   model-policy.sh set tier <tier> <cli> <model|effort> <value>
#   model-policy.sh set role <role> <tier>      # remap a role to another tier
#   model-policy.sh set dispatch <role> <cli>   # route a phase to another CLI
#   model-policy.sh unset tier <tier> <cli> <model|effort>
#   model-policy.sh unset tier <tier>           # drop the WHOLE tier (refused while
#                                               # any role still points at it)
#   model-policy.sh unset role <role>           # role falls back to session default
#   model-policy.sh unset dispatch <role>       # phase runs locally again
#   ... --no-apply                              # save only; skip the re-stamp
#
# Edits rewrite models.yml canonically (schema order, standard header) — inline
# comments are not preserved; models.example.yml documents the schema. Running
# Claude sessions load agent models at startup, so they pick up edits on the
# next session.
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

CUSTOM_FILE=0
NO_APPLY=0

while (( $# )); do
  case "$1" in
    --help|-h) usage ;;
    --file) shift; POLICY="${1:?--file needs a path}"; CUSTOM_FILE=1 ;;
    --no-apply) NO_APPLY=1 ;;
    *) break ;;
  esac
  shift
done

CMD="${1:-}"
[[ -z "$CMD" ]] && usage

# --no-apply may also trail the subcommand args (set/unset/update).
_args=()
for _a in "${@:2}"; do
  [[ "$_a" == "--no-apply" ]] && { NO_APPLY=1; continue; }
  _args+=("$_a")
done
set -- "$CMD" ${_args[@]+"${_args[@]}"}

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

# --- editing -------------------------------------------------------------------
# Edits go flatten -> mutate the TSV -> emit_policy (canonical rewrite) ->
# validate the candidate with `check` -> atomic mv -> re-stamp. A candidate
# that fails validation never replaces models.yml.

# validate_field <cli> <field> <value> — refuse bad input before any rewrite.
validate_field() {
  local cli="$1" field="$2" val="$3"
  # Control whitespace would corrupt the TSV edit pipeline — refuse for any CLI.
  if [[ "$val" == *$'\t'* || "$val" == *$'\n'* ]]; then
    echo "invalid $cli $field: value must not contain tabs or newlines" >&2
    exit 2
  fi
  case "$field" in
    model)
      if [[ "$cli" == "claude" && ! "$val" =~ ^(opus|sonnet|haiku|fable|inherit|claude-[a-z0-9.-]+)$ ]]; then
        local hint=""
        [[ "$val" =~ ^(opus|sonnet|haiku|fable)[-.0-9]+$ ]] \
          && hint=" — did you mean 'claude-$val' (full id) or '${BASH_REMATCH[1]}' (alias)?"
        echo "invalid claude model '$val' (alias opus|sonnet|haiku|fable, inherit, or a claude-* id)$hint" >&2
        exit 2
      fi
      ;;
    effort)
      local allowed="low|medium|high|xhigh|max"
      [[ "$cli" == "codex" ]] && allowed="minimal|low|medium|high|xhigh"
      if [[ ! "$val" =~ ^($allowed)$ ]]; then
        echo "invalid $cli effort '$val' (allowed: ${allowed//|/, })" >&2
        exit 2
      fi
      ;;
  esac
}

require_cli()   { [[ "$1" =~ ^(claude|codex|copilot)$ ]] || { echo "unknown CLI '$1' (claude|codex|copilot)" >&2; exit 2; }; }
require_field() { [[ "$1" =~ ^(model|effort)$ ]]         || { echo "unknown field '$1' (model|effort)" >&2; exit 2; }; }
require_name()  { [[ "$2" =~ ^[A-Za-z0-9_-]+$ ]]         || { echo "invalid $1 name '$2' (letters, digits, '-', '_' only)" >&2; exit 2; }; }

# emit_policy — canonical models.yml from flatten-format TSV on stdin. Tier /
# role / dispatch order is first-seen; per-tier keys in schema order, then any
# custom keys. Inline comments are not preserved (schema: models.example.yml).
emit_policy() {
  awk -F'\t' '
    $1=="tier" {
      if (!($2 in tseen)) { tseen[$2]=1; torder[++tn]=$2 }
      if (!(($2 SUBSEP $3) in kseen)) { kseen[$2 SUBSEP $3]=1; korder[$2]=korder[$2] SUBSEP $3 }
      tval[$2 SUBSEP $3]=$4; next
    }
    $1=="role"     { if (!($2 in rseen)) { rseen[$2]=1; rorder[++rn]=$2 }; rval[$2]=$3; next }
    $1=="dispatch" { if (!($2 in dseen)) { dseen[$2]=1; dorder[++dn]=$2 }; dval[$2]=$3; next }
    END {
      print "# Model policy — MACHINE-LOCAL (gitignored). Written by model-policy.sh."
      print "# Schema + docs: models.example.yml. Query: model-policy.sh show. Change:"
      print "# model-policy.sh update/set/unset (validates first, then re-stamps the"
      print "# generated copies + CLI adapters), or the scripts/configure-models.sh wizard."
      print ""
      print "tiers:"
      nschema=split("claude_model claude_effort codex_model codex_effort copilot_model copilot_effort", schema, " ")
      for (i=1; i<=tn; i++) {
        t=torder[i]
        print "  " t ":"
        for (s=1; s<=nschema; s++)
          if ((t SUBSEP schema[s]) in tval) print "    " schema[s] ": " tval[t SUBSEP schema[s]]
        nk=split(substr(korder[t], 2), keys, SUBSEP)
        for (k=1; k<=nk; k++) {
          known=0
          for (s=1; s<=nschema; s++) if (keys[k]==schema[s]) known=1
          if (!known) print "    " keys[k] ": " tval[t SUBSEP keys[k]]
        }
      }
      print ""
      print "roles:"
      for (i=1; i<=rn; i++) print "  " rorder[i] ": " rval[rorder[i]]
      if (dn > 0) {
        print ""
        print "dispatch:"
        for (i=1; i<=dn; i++) print "  " dorder[i] ": " dval[dorder[i]]
      }
    }
  '
}

# write_policy <tsv> <description...> — validate the candidate, install it,
# then re-stamp everything the policy feeds (unless --no-apply / --file).
write_policy() {
  local tsv="$1"; shift
  local tmp
  tmp="$(mktemp "$POLICY.XXXXXX")"
  printf '%s\n' "$tsv" | emit_policy > "$tmp"
  if ! "$HUB_DIR/scripts/model-policy.sh" --file "$tmp" check >/dev/null 2>&1; then
    echo "  ${RED}✗${RESET} refusing to write: the result fails validation —" >&2
    "$HUB_DIR/scripts/model-policy.sh" --file "$tmp" check >&2 || true
    rm -f "$tmp"
    exit 1
  fi
  mv "$tmp" "$POLICY"
  local line
  for line in "$@"; do echo "  ${GREEN}✓${RESET} $line"; done
  if (( CUSTOM_FILE || NO_APPLY )); then
    echo "  ${DIM}· stamped copies not refreshed — run scripts/apply-models.sh + build-adapters.sh when ready${RESET}"
    return 0
  fi
  "$HUB_DIR/scripts/apply-models.sh" >/dev/null
  # A sync problem must not abort after the policy is already saved.
  if ! "$HUB_DIR/scripts/sync.sh" >/dev/null 2>&1; then
    echo "  ${YELLOW}!${RESET} sync.sh reported a problem — run scripts/sync.sh to see it" >&2
  fi
  "$HUB_DIR/scripts/build-adapters.sh" >/dev/null
  echo "  ${GREEN}✓${RESET} stamped copies + CLI adapters refreshed"
  echo "  ${DIM}· running Claude sessions load agent models at startup — new sessions pick this up${RESET}"
}

# tsv_upsert <tsv> <kind> <name> [<key>] <value> — replace-or-append one row.
tsv_upsert() {
  local tsv="$1" kind="$2" name="$3" key="" val
  if [[ $# -eq 5 ]]; then key="$4"; val="$5"; else val="$4"; fi
  printf '%s\n' "$tsv" | awk -F'\t' -v OFS='\t' -v kind="$kind" -v name="$name" -v key="$key" -v val="$val" '
    kind=="tier" && $1=="tier" && $2==name && $3==key { print "tier", name, key, val; done=1; next }
    kind!="tier" && $1==kind  && $2==name             { print kind, name, val;       done=1; next }
    { print }
    END {
      if (!done) {
        if (kind=="tier") print "tier", name, key, val
        else              print kind, name, val
      }
    }'
}

# tsv_delete <tsv> <kind> <name> [<key>] — drop matching rows.
tsv_delete() {
  printf '%s\n' "$1" | awk -F'\t' -v kind="$2" -v name="$3" -v key="${4:-}" '
    $1==kind && $2==name && (key=="" || $3==key) { next }
    { print }'
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
          # Hard error: an invalid value here stamps into every generated agent
          # and Claude Code refuses to spawn them (model-not-found at launch).
          [[ "$val" =~ ^(opus|sonnet|haiku|fable|inherit|claude-[a-z0-9.-]+)$ ]] || fail "tier '$tier': claude_model '$val' is not an alias (opus|sonnet|haiku|fable|inherit) or claude-* id — agents stamped with it fail to spawn" ;;
        codex_model|copilot_model) ;;
        *) warn "tier '$tier': unknown key '$key' (ignored)" ;;
      esac
    done < <(flatten | awk -F'\t' '$1=="tier"')

    for known in specify plan tasks implement implement-hard review retro onboard go orchestrator opponent reality-check security-reviewer test-engineer stack-expert explore; do
      grep -qx "$known" <<<"$roles" || warn "role '$known' not mapped — that phase/agent keeps the session default"
    done

    # dispatch: — phase -> CLI routing (optional; consumed by spec-dispatch.sh)
    while IFS=$'\t' read -r _ drole dcli; do
      [[ -n "$drole" ]] || continue
      case "$drole" in
        plan|tasks|implement|retro) ;;
        specify) fail "dispatch: 'specify' is an interview — it runs where the user is, never headless" ;;
        review)  fail "dispatch: 'review' needs interactive judgment (merge decisions) — not dispatchable" ;;
        go)      fail "dispatch: 'go' is the autopilot conductor — dispatch its inner phases (plan/tasks/implement) instead" ;;
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

  set)
    KIND="${2:?set what? (tier|role|dispatch)}"
    TSV="$(flatten)"
    case "$KIND" in
      tier)
        T="${3:?tier name required}"; CLI="${4:?cli required}"; FIELD="${5:?field required (model|effort)}"; VAL="${6:?value required}"
        require_name tier "$T"; require_cli "$CLI"; require_field "$FIELD"; validate_field "$CLI" "$FIELD" "$VAL"
        note=""
        flatten | awk -F'\t' '$1=="tier" { print $2 }' | grep -qx "$T" || note=" (new tier)"
        TSV="$(tsv_upsert "$TSV" tier "$T" "${CLI}_${FIELD}" "$VAL")"
        write_policy "$TSV" "tier '$T'$note: ${CLI}_${FIELD} = $VAL"
        ;;
      role)
        R="${3:?role name required}"; T="${4:?tier name required}"
        require_name role "$R"
        flatten | awk -F'\t' '$1=="tier" { print $2 }' | grep -qx "$T" \
          || { echo "tier '$T' is not defined (tiers: $(flatten | awk -F'\t' '$1=="tier" { print $2 }' | sort -u | paste -sd, -))" >&2; exit 2; }
        TSV="$(tsv_upsert "$TSV" role "$R" "$T")"
        write_policy "$TSV" "role '$R' -> tier '$T'"
        ;;
      dispatch)
        R="${3:?role required}"; CLI="${4:?cli required}"
        case "$R" in
          plan|tasks|implement|retro) ;;
          specify) echo "dispatch: 'specify' is an interview — it runs where the user is, never headless" >&2; exit 2 ;;
          review)  echo "dispatch: 'review' needs interactive judgment (merge decisions) — not dispatchable" >&2; exit 2 ;;
          go)      echo "dispatch: 'go' is the autopilot conductor — dispatch its inner phases (plan/tasks/implement) instead" >&2; exit 2 ;;
          *) echo "dispatch: unknown role '$R' (dispatchable: plan, tasks, implement, retro)" >&2; exit 2 ;;
        esac
        require_cli "$CLI"
        command -v "$CLI" >/dev/null 2>&1 \
          || echo "  ${YELLOW}!${RESET} the $CLI CLI is not on PATH on this machine — dispatch will fail until it is installed" >&2
        TSV="$(tsv_upsert "$TSV" dispatch "$R" "$CLI")"
        write_policy "$TSV" "dispatch: $R -> $CLI"
        ;;
      *) echo "unknown set target '$KIND' (tier|role|dispatch)" >&2; exit 2 ;;
    esac
    ;;

  unset)
    KIND="${2:?unset what? (tier|role|dispatch)}"
    TSV="$(flatten)"
    case "$KIND" in
      tier)
        T="${3:?tier name required}"
        if [[ -z "${4:-}" ]]; then
          # No <cli> <field> → drop the whole tier.
          flatten | awk -F'\t' '$1=="tier" { print $2 }' | grep -qx "$T" \
            || { echo "nothing to unset: tier '$T' is not defined" >&2; exit 1; }
          pointing="$(flatten | awk -F'\t' -v t="$T" '$1=="role" && $3==t { print $2 }' | paste -sd, -)"
          [[ -z "$pointing" ]] \
            || { echo "tier '$T' is still in use by role(s): $pointing — remap them first (model-policy.sh set role <role> <tier>)" >&2; exit 2; }
          TSV="$(tsv_delete "$TSV" tier "$T")"
          write_policy "$TSV" "tier '$T' removed"
        else
          CLI="${4}"; FIELD="${5:?field required (model|effort)}"
          require_cli "$CLI"; require_field "$FIELD"
          [[ -n "$(tier_field "$T" "${CLI}_${FIELD}")" ]] \
            || { echo "nothing to unset: tier '$T' has no ${CLI}_${FIELD}" >&2; exit 1; }
          TSV="$(tsv_delete "$TSV" tier "$T" "${CLI}_${FIELD}")"
          write_policy "$TSV" "tier '$T': ${CLI}_${FIELD} removed (that CLI keeps its session default)"
        fi
        ;;
      role)
        R="${3:?role name required}"
        [[ -n "$(role_tier "$R")" ]] || { echo "nothing to unset: role '$R' is not mapped" >&2; exit 1; }
        TSV="$(tsv_delete "$TSV" role "$R")"
        write_policy "$TSV" "role '$R' unmapped (falls back to the session default)"
        ;;
      dispatch)
        R="${3:?role required}"
        flatten | awk -F'\t' '$1=="dispatch" { print $2 }' | grep -qx "$R" \
          || { echo "nothing to unset: no dispatch mapping for '$R'" >&2; exit 1; }
        TSV="$(tsv_delete "$TSV" dispatch "$R")"
        write_policy "$TSV" "dispatch mapping for '$R' removed (runs locally again)"
        ;;
      *) echo "unknown unset target '$KIND' (tier|role|dispatch)" >&2; exit 2 ;;
    esac
    ;;

  update)
    ROLE=""; MODEL=""; EFFORT=""; CLI="claude"; SOLO=0
    shift  # past 'update'
    while (( $# )); do
      case "$1" in
        --cli) shift; CLI="${1:?--cli needs claude|codex|copilot}" ;;
        --solo) SOLO=1 ;;
        -*) echo "unknown flag: $1" >&2; exit 2 ;;
        *) if [[ -z "$ROLE" ]]; then ROLE="$1"
           elif [[ -z "$MODEL" ]]; then MODEL="$1"
           elif [[ -z "$EFFORT" ]]; then EFFORT="$1"
           else echo "unexpected arg: $1" >&2; exit 2; fi ;;
      esac
      shift
    done
    [[ -n "$ROLE" && -n "$MODEL" ]] || { echo "usage: model-policy.sh update <role> <model> [<effort>] [--cli <cli>] [--solo]" >&2; exit 2; }
    require_cli "$CLI"
    validate_field "$CLI" model "$MODEL"
    if [[ -n "$EFFORT" ]]; then validate_field "$CLI" effort "$EFFORT"; fi
    T="$(role_tier "$ROLE")"
    [[ -n "$T" ]] || { echo "role '$ROLE' is not mapped to a tier — map it first: model-policy.sh set role $ROLE <tier> (tiers: $(flatten | awk -F'\t' '$1=="tier" { print $2 }' | sort -u | paste -sd, -))" >&2; exit 2; }
    siblings="$(flatten | awk -F'\t' -v t="$T" -v r="$ROLE" '$1=="role" && $3==t && $2!=r { print $2 }' | paste -sd, -)"
    TSV="$(flatten)"
    desc=()
    if (( SOLO )) && [[ -n "$siblings" ]]; then
      # Split the role onto its own tier: clone the shared tier under the
      # role's name, remap the role, and edit only the clone.
      NEW="$ROLE"
      require_name tier "$NEW"
      if flatten | awk -F'\t' '$1=="tier" { print $2 }' | grep -qx "$NEW"; then
        echo "cannot split: a tier named '$NEW' already exists — split manually (set tier / set role)" >&2; exit 2
      fi
      while IFS=$'\t' read -r key val; do
        [[ -n "$key" ]] || continue
        TSV="$(tsv_upsert "$TSV" tier "$NEW" "$key" "$val")"
      done < <(flatten | awk -F'\t' -v t="$T" '$1=="tier" && $2==t { print $3 "\t" $4 }')
      TSV="$(tsv_upsert "$TSV" role "$ROLE" "$NEW")"
      desc+=("role '$ROLE' split onto its own tier '$NEW' (cloned from '$T'; $siblings keep '$T')")
      T="$NEW"
    elif [[ -n "$siblings" ]]; then
      echo "  ${YELLOW}!${RESET} tier '$T' is shared — this also updates: $siblings (--solo to split the role off first)" >&2
    elif (( SOLO )); then
      echo "  ${DIM}· role '$ROLE' already has tier '$T' to itself — --solo not needed${RESET}" >&2
    fi
    TSV="$(tsv_upsert "$TSV" tier "$T" "${CLI}_model" "$MODEL")"
    desc+=("role '$ROLE' (tier '$T'): ${CLI}_model = $MODEL")
    if [[ -n "$EFFORT" ]]; then
      TSV="$(tsv_upsert "$TSV" tier "$T" "${CLI}_effort" "$EFFORT")"
      desc+=("role '$ROLE' (tier '$T'): ${CLI}_effort = $EFFORT")
    fi
    write_policy "$TSV" "${desc[@]}"
    ;;

  *)
    echo "unknown command: $CMD" >&2
    exit 2
    ;;
esac
