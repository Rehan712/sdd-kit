#!/usr/bin/env bash
# verification-lib.sh — source-only verification parsing and runtime helpers.
#
# vf_bindings writes a deterministic catalog. Every record is exactly twelve
# NUL-delimited fields, in this order:
#
#   record_type, primary_id, task_id, stage, state, verify_kind, family,
#   locator, criteria_or_refs, verify, reuse, detail
#
# Record types are meta, definition, family, task, test and binding. A meta
# record identifies the schema/contract/phase. Definitions repeat once per
# declared family; families repeat once per concrete locator; tasks retain the
# exact authored lists; tests resolve task locators to typed families; bindings
# resolve each task FM/INV reference to its exact family and locator. Empty
# positions remain present, so consumers can reject truncated or shifted data.
# Metadata is data only: callers must never source or eval a catalog.

# Public constants shared by later capture and summary consumers.
# shellcheck disable=SC2034
VF_SCHEMA=1
# shellcheck disable=SC2034
VF_SUCCESS_BYTES=2048
# shellcheck disable=SC2034
VF_FAILURE_BYTES=8192
# shellcheck disable=SC2034
VF_DIAGNOSTIC_LINES=20

# vf_config <stack-file> <tasks-file-or-empty> <new-output-dir>
# commands.nul: repeated (gate_checks|checkpoints, stage-or-empty, command).
# reuse.nul/tools.nul/inputs.nul/stages.nul: single-field records.
# meta.nul: key/value pairs (version, gate_count, stage_validation).
# Missing configuration yields an empty catalog; vf_project_config applies
# version policy. Fresh directories prevent reuse of a failed parse result.
vf_config() (
  [[ "$#" -eq 3 ]] || { echo 'error: vf_config needs stack, tasks, output directory' >&2; return 2; }
  local stack="$1" tasks_file="$2" output="$3" stage_map tmp
  [[ ! -e "$output" && ! -L "$output" ]] || {
    printf 'error: %s: output already exists; use a fresh catalog directory\n' "$output" >&2; return 1;
  }
  tmp="$(mktemp -d "$output.tmp.XXXXXX")" || return 1
  trap 'rm -rf "$tmp"' EXIT
  stage_map="$tmp/stage-map"
  : > "$stage_map"
  if [[ -n "$tasks_file" && -f "$tasks_file" ]]; then
    _vf_reject_nul "$tasks_file" "$tasks_file" || return 1
    awk '
      BEGIN { tick=sprintf("%c",96); fence=tick tick tick }
      { line=$0; sub(/^[[:space:]]*/, "", line) }
      index(line,fence)==1 || index(line,"~~~")==1 { fenced=!fenced; next }
      fenced || /^[[:space:]]*>/ { next }
      /^## / { stage=substr($0,4); sub(/[[:space:]]+$/, "", stage) }
      /^- \[[ xX~]\] \*\*T[0-9][0-9][0-9][a-z0-9]*\*\*/ {
        if (stage!="" && !seen[stage]++) print stage
      }
    ' "$tasks_file" > "$stage_map" || return 1
  fi
  local input=/dev/null
  if [[ -e "$stack" ]]; then
    [[ -f "$stack" && -r "$stack" ]] || { printf 'error: %s:1: unreadable configuration\n' "$stack" >&2; return 1; }
    _vf_reject_nul "$stack" "$stack:1" || return 1
    input="$stack"
  fi
  # awk -v interprets backslashes; environment transport preserves path bytes.
  VF_CONFIG_PATH="$stack" VF_CONFIG_OUT="$tmp" VF_CONFIG_STAGES="$stage_map" awk '
    function error(message) {
      printf "error: %s:%d: %s\n", ENVIRON["VF_CONFIG_PATH"], NR ? NR : 1, message > "/dev/stderr"
      errors++
    }
    function trim(s) { sub(/^[ ]+/, "", s); sub(/[ ]+$/, "", s); return s }
    function emit(file,s) { printf "%s%c", s, 0 > (dir "/" file) }
    function scalar(s,    i,c,out,closed,tail) {
      scalar_ok=0; out=""
      if (substr(s,1,1)!=quote) { error("expected single-quoted scalar"); return "" }
      for (i=2;i<=length(s);i++) {
        c=substr(s,i,1)
        if (c==quote) {
          if (substr(s,i+1,1)==quote) { out=out quote; i++ }
          else {
            tail=substr(s,i+1)
            if (tail!="" && tail !~ /^ +(#.*)?$/) { error("trailing scalar content"); return "" }
            closed=1; break
          }
        } else out=out c
      }
      if (!closed) { error("unterminated scalar; multiline scalars are unsupported"); return "" }
      if (trim(out)=="") { error("empty verification scalar"); return "" }
      if (out ~ /\$[({A-Za-z_]/) { error("interpolation is unsupported"); return "" }
      scalar_ok=1; return out
    }
    BEGIN {
      dir=ENVIRON["VF_CONFIG_OUT"]; quote=sprintf("%c",39)
      while ((getline stage < ENVIRON["VF_CONFIG_STAGES"])>0) { stages[stage]=1; stage_count++ }
      close(ENVIRON["VF_CONFIG_STAGES"])
      files[1]="commands.nul"; files[2]="reuse.nul"; files[3]="tools.nul"
      files[4]="inputs.nul"; files[5]="stages.nul"; files[6]="meta.nul"
      for (i=1;i<=6;i++) printf "%s","" > (dir "/" files[i])
    }
    /^[ ]*(#.*)?$/ { next }
    {
      if ($0 ~ /[[:cntrl:]]/) { error("tabs/control bytes are unsupported"); next }
      if ($0 !~ /^ /) {
        if ($0 !~ /^[A-Za-z_][A-Za-z0-9_-]*:/) { error("expected top-level key"); next }
        key=$0; sub(/:.*/, "", key)
        if (seen[key]++) error("duplicate key " key)
        value=substr($0,length(key)+2); value=trim(value)
        if (value ~ /^#/) value=""
        context=""; current_stage=""; closed_list=0
        if (key=="gate_checks" || key=="reuse_checks" || key=="verification_tools" ||
            key=="verification_inputs" || key=="checkpoints") {
          context=key
          if (value ~ /^\[\]( +#.*)?$/ && key!="checkpoints") closed_list=1
          else if (value!="") error("expected block " (key=="checkpoints" ? "map" : "list") " for " key)
        } else if (key ~ /^(gate_|checkpoint|reuse_|verification_)/) error("unknown verification key " key)
        next
      }
      if (context=="") next
      if (closed_list) { error("entries after an inline empty list"); next }
      if (context=="checkpoints" && $0 ~ /^  [^ ]/ && $0 !~ /^  -/) {
        line=substr($0,3)
        colon=index(line,":")
        if (!colon) { error("expected checkpoint stage mapping"); next }
        current_stage=substr(line,1,colon-1)
        value=trim(substr(line,colon+1))
        if (current_stage !~ /^[A-Za-z][A-Za-z0-9 ()\/_-]*$/) { error("invalid checkpoint stage"); next }
        if (seen_stage[current_stage]++) error("duplicate checkpoint stage " current_stage)
        if (stage_count && !(current_stage in stages)) error("unknown checkpoint stage " current_stage)
        emit("stages.nul", current_stage)
        stage_empty=(value ~ /^\[\]( +#.*)?$/)
        if (value!="" && value !~ /^#/ && !stage_empty) error("expected checkpoint block list or []")
        next
      }
      if (context=="checkpoints") {
        if (current_stage=="" || stage_empty || $0 !~ /^    - /) { error("invalid checkpoint list indentation"); next }
        value=scalar(substr($0,7))
      } else {
        if ($0 !~ /^  - /) { error("invalid verification list indentation"); next }
        value=scalar(substr($0,5))
      }
      if (!scalar_ok) next
      if (context=="gate_checks" || context=="checkpoints") {
        emit("commands.nul",context); emit("commands.nul",current_stage); emit("commands.nul",value)
        if (context=="gate_checks") gate_count++
      } else if (context=="reuse_checks") emit("reuse.nul",value)
      else if (context=="verification_tools") emit("tools.nul",value)
      else emit("inputs.nul",value)
    }
    END {
      emit("meta.nul","version"); emit("meta.nul","1")
      emit("meta.nul","gate_count"); emit("meta.nul",gate_count+0)
      emit("meta.nul","stage_validation"); emit("meta.nul",stage_count ? "checked" : "deferred")
      for (i=1;i<=6;i++) if (close(dir "/" files[i])!=0) errors++
      exit errors ? 1 : 0
    }
  ' "$input" || return 1
  rm "$stage_map" || return 1
  mv "$tmp" "$output"
)

# Shared analyzer/doctor policy. Legacy gaps warn; explicit v1 gaps fail.
vf_project_config() (
  [[ "$#" -eq 3 ]] || return 2
  local spec_dir="$1" mode="$2" stack="$3" tmp tasks_file="" rc=0 key value count=0 contract declared
  tmp="$(mktemp -d)" || return 1
  trap 'rm -rf "$tmp"' EXIT
  contract="$(fm_get "$spec_dir/spec.md" verification_contract)"
  declared="$(frontmatter_block "$spec_dir/spec.md" | grep -c '^verification_contract:' || true)"
  if [[ "$declared" -gt 1 || ( "$declared" -eq 1 && "$contract" != 1 ) ]]; then
    printf 'error: %s/spec.md:1: unsupported or duplicate verification_contract %s\n' "$spec_dir" "$contract" >&2
    return 1
  fi
  # Project checkpoints target the active v1 decomposition. Shipped legacy
  # specs may have different stages; do not retrofit their task inventories.
  [[ "$mode" == plan || "$declared" -eq 0 ]] || tasks_file="$spec_dir/tasks.md"
  vf_config "$stack" "$tasks_file" "$tmp/catalog" || return $?
  while IFS= read -r -d '' key && IFS= read -r -d '' value; do
    [[ "$key" != gate_count ]] || count="$value"
  done < "$tmp/catalog/meta.nul"
  if [[ "$declared" -eq 0 && -s "$tmp/catalog/stages.nul" ]]; then
    printf 'warning: %s:1: legacy checkpoint bindings are undeclared; stage membership deferred\n' "$stack" >&2
  fi
  if [[ "$count" -eq 0 ]]; then
    if [[ "$contract" == 1 ]]; then
      printf 'error: %s:1: verification_contract 1 requires nonempty gate_checks\n' "$stack" >&2
      rc=1
    else
      printf 'warning: %s:1: legacy configuration has no gate_checks; no automatic floor clearance\n' "$stack" >&2
    fi
  fi
  return "$rc"
)

_VF_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if ! type fm_get >/dev/null 2>&1; then
  # shellcheck source=scripts/lib.sh
  . "$_VF_LIB_DIR/lib.sh"
fi

_vf_reject_nul() { # <file> <display-name>
  if LC_ALL=C od -An -v -t u1 "$1" | grep -E '(^|[[:space:]])0([[:space:]]|$)' >/dev/null; then
    printf 'error: %s contains a NUL byte\n' "$2" >&2
    return 1
  fi
}

_vf_catalog_meta() { # <output-file> <phase> <contract> <stage>
  local output="$1" phase="$2" contract="$3" stage="$4" tmp
  tmp="$(mktemp "${output}.tmp.XXXXXX" 2>/dev/null)" || {
    printf 'error: cannot create binding catalog beside %s\n' "$output" >&2
    return 1
  }
  if ! printf '%s\0' \
      meta "$VF_SCHEMA" "" "$phase" "" "" "" "" "$contract" "" "" "$stage" \
      > "$tmp" || ! mv "$tmp" "$output"; then
    rm -f "$tmp"
    printf 'error: cannot publish binding catalog to %s\n' "$output" >&2
    return 1
  fi
}

vf_bindings() { # <spec-dir> <plan|tasks|through-stage> <stage-or-empty> <output-file>
  local spec_dir="${1:-}" phase="${2:-}" stage="${3:-}" output="${4:-}"
  local spec plan tasks contract contract_count tmpdir records maps inventory
  local us errors warnings selected stage_list target_found out_tmp

  case "$phase" in
    plan|tasks) [[ -z "$stage" ]] || {
      printf 'error: vf_bindings %s mode requires an empty stage\n' "$phase" >&2
      return 2
    } ;;
    through-stage) [[ -n "$stage" ]] || {
      printf 'error: vf_bindings through-stage requires an exact stage\n' >&2
      return 2
    } ;;
    *)
      printf 'error: vf_bindings phase must be plan, tasks or through-stage\n' >&2
      return 2
      ;;
  esac
  [[ -d "$spec_dir" && -n "$output" ]] || {
    printf 'error: vf_bindings requires a spec directory and output file\n' >&2
    return 2
  }
  spec="$spec_dir/spec.md"; plan="$spec_dir/plan.md"; tasks="$spec_dir/tasks.md"
  [[ -f "$spec" && -f "$plan" ]] || {
    printf 'error: vf_bindings requires spec.md and plan.md\n' >&2
    return 1
  }
  if [[ "$phase" != plan && ! -f "$tasks" ]]; then
    printf 'error: vf_bindings %s mode requires tasks.md\n' "$phase" >&2
    return 1
  fi
  _vf_reject_nul "$spec" spec.md || return 1
  _vf_reject_nul "$plan" plan.md || return 1
  if [[ "$phase" != plan ]]; then
    _vf_reject_nul "$tasks" tasks.md || return 1
  fi

  contract_count="$(frontmatter_block "$spec" | grep -c '^verification_contract:' || true)"
  if [[ "$contract_count" -gt 1 ]]; then
    printf 'error: spec.md declares verification_contract more than once\n' >&2
    return 1
  fi
  contract="$(fm_get "$spec" verification_contract)"
  if [[ "$contract_count" -eq 0 ]]; then
    _vf_catalog_meta "$output" "$phase" legacy "$stage"
    return $?
  fi
  if [[ "$contract" != "$VF_SCHEMA" ]]; then
    printf 'error: unsupported verification_contract %s; expected %s\n' \
      "${contract:-<empty>}" "$VF_SCHEMA" >&2
    return 1
  fi

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/vf-bindings.XXXXXX" 2>/dev/null)" || {
    printf 'error: cannot create vf_bindings temporary directory\n' >&2
    return 1
  }
  records="$tmpdir/records"; maps="$tmpdir/maps"; inventory="$tmpdir/inventory"
  : > "$records"; : > "$maps"; : > "$inventory"
  us=$'\034'

  # Parse only the normative v1 plan tables. Table prose never supplies a
  # missing field: an explicit contract with a three-column registry is an
  # error instead of an inferred kind.
  awk -v OFS="$us" -v mapfile="$maps" \
      -v specacs=" $(grep -oE 'AC-[0-9]{3}' "$spec" | sort -u | tr '\n' ' ')" '
    function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    function clean_cell(s) { s=trim(s); gsub(SUBSEP, "|", s); return s }
    function row(line,    n,i) {
      gsub(/\\\|/, SUBSEP, line)
      sub(/^[[:space:]]*\|/, "", line); sub(/\|[[:space:]]*$/, "", line)
      n=split(line, cell, /\|/)
      for (i=1; i<=n; i++) cell[i]=clean_cell(cell[i])
      return n
    }
    function placeholder(s, low) {
      low=tolower(trim(s))
      return low=="" || low=="todo" || low=="tbd" || low=="tbc" ||
             low=="..." || low=="placeholder" || low ~ /^<.*>$/
    }
    function diag(level, message) { print "D", level, message; if (level=="error") errs++; else warns++ }
    function safe(s) {
      if (index(s, "\t") || index(s, sprintf("%c", 28))) {
        diag("error", "plan table values cannot contain tabs or control separators")
        return 0
      }
      return 1
    }
    function rec(type,primary,task,stage,state,kind,family,locator,criteria,verify,reuse,detail) {
      if (safe(primary) && safe(task) && safe(stage) && safe(state) && safe(kind) &&
          safe(family) && safe(locator) && safe(criteria) && safe(verify) && safe(reuse) && safe(detail))
        print "R",type,primary,task,stage,state,kind,family,locator,criteria,verify,reuse,detail
    }
    function valid_id(id, type) {
      if (type=="failure-mode") return id ~ /^FM-[0-9][0-9][0-9]$/
      return id ~ /^INV-[0-9][0-9][0-9]$/
    }
    function valid_family(name) { return name ~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/ }
    function remember_id(id,type) {
      print "I",id,type >> mapfile
    }
    function remember_definition(id,type,families,    a,n,i,fam,key) {
      n=split(families,a,/,/)
      for (i=1; i<=n; i++) {
        fam=trim(a[i])
        if (!valid_family(fam)) {
          diag("error", id " has malformed test family token: " (fam=="" ? "<empty>" : fam))
          continue
        }
        key=id SUBSEP fam
        defn++; def_id[defn]=id; def_type[defn]=type; def_family[defn]=fam
      }
    }
    function criteria_ok(criteria, family,    prefix,a,n,i,tok,found) {
      prefix=criteria; sub(/:.*/, "", prefix); gsub(/`/, "", prefix)
      n=split(prefix,a,/,/)
      for (i=1; i<=n; i++) {
        tok=trim(a[i])
        if (tok !~ /^AC-[0-9][0-9][0-9]$/) {
          diag("error", "verification family " family " has malformed criterion token: " (tok=="" ? "<empty>" : tok))
          continue
        }
        found=1
        if (index(specacs, " " tok " ")==0)
          diag("error", "verification family " family " references criterion missing from spec.md: " tok)
      }
      if (!found) diag("error", "verification family " family " declares no AC criterion")
    }
    function register_family(name,kind,criteria,locators,    a,n,i,loc,file,literal,key) {
      if (!valid_family(name)) { diag("error", "malformed verification family name: " name); return }
      if (family_seen[name]++) { diag("error", "duplicate verification family " name); return }
      if (kind !~ /^(test|assertion|static|manual)$/) {
        diag("error", "verification family " name " has invalid kind: " (kind=="" ? "<empty>" : kind)); return
      }
      if (placeholder(criteria) || placeholder(locators)) {
        diag("warning", "verification family " name " has blank or placeholder criteria/locator")
        return
      }
      criteria_ok(criteria,name)
      n=split(locators,a,/;/)
      for (i=1; i<=n; i++) {
        loc=trim(a[i]); if (loc ~ /^`.*`$/) { sub(/^`/,"",loc); sub(/`$/,"",loc) }
        if (kind=="manual") {
          if (placeholder(loc) || loc ~ /::/) {
            diag("error", "manual verification family " name " requires an artifact observation name")
            continue
          }
        } else {
          file=loc; sub(/::.*/,"",file); literal=loc; sub(/^[^:]*::/,"",literal)
          if (index(loc,"::")==0 || placeholder(file) || placeholder(literal) ||
              file ~ /^\// || file ~ /(^|\/)\.\.($|\/)/) {
            diag("error", "verification family " name " has malformed concrete locator: " loc)
            continue
          }
        }
        if (!safe(loc)) continue
        if ((loc in locator_kind) && locator_kind[loc] != kind)
          diag("error", "concrete locator " loc " has conflicting kinds " locator_kind[loc] " and " kind)
        else locator_kind[loc]=kind
        print "F",name,kind,criteria,loc >> mapfile
        rec("family",name,"","","",kind,name,loc,criteria,"","","")
      }
    }
    !fenced && /^Exclusions:[[:space:]]*/ {
      exclusions=1; v=$0; sub(/^Exclusions:[[:space:]]*/,"",v)
      if (placeholder(v)) diag("warning", "plan Exclusions entry is blank or placeholder")
    }
    /^[[:space:]]*(```|~~~)/ { fenced=!fenced; next }
    !fenced && $0 !~ /^[[:space:]]*\|/ {
      if (in_table) { in_table=0; section="" }
    }
    !fenced && $0 !~ /^[[:space:]]*>/ && /^[[:space:]]*\|/ {
      n=row($0)
      if (cell[1]=="ID") {
        if (n==6 && cell[2]=="Components" && cell[3]=="Category" && cell[4]=="Trigger" && cell[5]=="Decided behavior" && cell[6]=="Test families") {
          section="fm"; header[section]=1; in_table=1
        } else if (n==5 && cell[2]=="Scope" && cell[3]=="Promise" && cell[4]=="Enforcement sites" && cell[5]=="Test families") {
          section="inv"; header[section]=1; in_table=1
        } else if ($0 ~ /(Scope|Promise|Enforcement sites)/) {
          diag("error", "malformed Invariants header; expected ID | Scope | Promise | Enforcement sites | Test families")
        } else if ($0 ~ /(Components|Category|Decided behavior|Test families)/) {
          diag("error", "malformed Failure modes header; expected ID | Components | Category | Trigger | Decided behavior | Test families")
        }
        next
      }
      if (cell[1]=="Family") {
        if (!(n==4 && cell[2]=="Kind" && cell[3]=="Criteria" && cell[4]=="Concrete locators"))
          diag("error", "malformed verification registry header; expected Family | Kind | Criteria | Concrete locators")
        else { section="registry"; header[section]=1; in_table=1 }
        next
      }
      if (cell[1] ~ /^:?-+:?$/) next
      if (!header[section]) next
      if (section=="fm") {
        if (n!=6) { diag("error", "malformed Failure modes row"); next }
        id=cell[1]
        if (!valid_id(id,"failure-mode")) { diag("error", "malformed failure mode id: " id); next }
        if (defined[id]++) { diag("error", "duplicate failure/invariant definition " id); next }
        remember_id(id,"failure-mode")
        if (cell[3] !~ /^(boundary|concurrency\/ordering|partial failure|regression|state\/data integrity)$/) {
          diag("error", id " has invalid category: " cell[3]); next
        }
        bad=0; for (i=2;i<=6;i++) if (placeholder(cell[i])) bad=1
        if (bad) {
          diag("warning", id " has blank or placeholder required fields")
          if (!placeholder(cell[6])) remember_definition(id,"failure-mode",cell[6])
          next
        }
        fm_count++; remember_definition(id,"failure-mode",cell[6]); next
      }
      if (section=="inv") {
        if (n!=5) { diag("error", "malformed Invariants row"); next }
        id=cell[1]
        if (!valid_id(id,"invariant")) { diag("error", "malformed invariant id: " id); next }
        if (defined[id]++) { diag("error", "duplicate failure/invariant definition " id); next }
        remember_id(id,"invariant")
        bad=0; for (i=2;i<=5;i++) if (placeholder(cell[i])) bad=1
        if (bad) {
          diag("warning", id " has blank or placeholder required fields")
          if (!placeholder(cell[5])) remember_definition(id,"invariant",cell[5])
          next
        }
        inv_count++; remember_definition(id,"invariant",cell[5]); next
      }
      if (section=="registry") {
        if (n!=4) { diag("error", "malformed verification registry row"); next }
        register_family(cell[1],cell[2],cell[3],cell[4]); registry_count++; next
      }
    }
    END {
      if (!header["fm"] || fm_count==0) diag("warning", "plan has no concrete Failure modes rows")
      if (!header["inv"] || inv_count==0) diag("warning", "plan has no concrete Invariants rows")
      if (!exclusions) diag("warning", "plan has no compact Exclusions entry")
      if (!header["registry"] || registry_count==0) diag("warning", "plan has no concrete verification family registry")
      for (i=1;i<=defn;i++) {
        if (!family_seen[def_family[i]])
          diag("error", def_id[i] " references undefined verification family " def_family[i])
        else {
          print "D",def_id[i],def_type[i],def_family[i] >> mapfile
          rec("definition",def_id[i],"","","","",def_family[i],"","","","",def_type[i])
        }
      }
    }
  ' "$plan" > "$records" || {
    printf 'error: vf_bindings could not parse plan.md\n' >&2
    rm -f "$records" "$maps" "$inventory"; rmdir "$tmpdir" 2>/dev/null || true
    return 1
  }

  # Build the task inventory separately so Integration owner may point forward
  # without one-pass ordering guesses. A heading is a stage only when it owns
  # at least one task; prose sections such as Execution contract are ignored.
  if [[ "$phase" != plan ]]; then
    awk -v OFS="$us" '
      /^##[^#]/ { stage=$0; sub(/^##[[:space:]]*/,"",stage) }
      /^- \[[ xX~]\] \*\*T[0-9][0-9][0-9][a-z0-9]*\*\*/ {
        match($0,/T[0-9][0-9][0-9][a-z0-9]*/); id=substr($0,RSTART,RLENGTH)
        if (!(stage in stage_seen)) { stage_seen[stage]=1; stage_order++; stages[stage_order]=stage }
        task_order++; print "T",id,task_order,stage
      }
    ' "$tasks" > "$inventory" || {
      printf 'error: vf_bindings could not inventory tasks.md\n' >&2
      rm -f "$records" "$maps" "$inventory"; rmdir "$tmpdir" 2>/dev/null || true
      return 1
    }
    cat "$inventory" >> "$maps" || {
      printf 'error: vf_bindings could not assemble its task catalog\n' >&2
      rm -f "$records" "$maps" "$inventory"; rmdir "$tmpdir" 2>/dev/null || true
      return 1
    }

    selected=""; target_found=0; stage_list=""
    while IFS="$us" read -r tag _ _ tstage; do
      [[ "$tag" == T ]] || continue
      case "|$stage_list|" in *"|$tstage|"*) continue ;; esac
      stage_list="${stage_list:+$stage_list|}$tstage"
      if [[ "$phase" == through-stage ]]; then
        selected="$selected|$tstage|"
        if [[ "$tstage" == "$stage" ]]; then target_found=1; break; fi
      fi
    done < "$inventory"
    if [[ "$phase" == through-stage && "$target_found" -ne 1 ]]; then
      printf 'D%serror%sunknown task stage for through-stage: %s\n' "$us" "$us" "$stage" >> "$records"
    fi

    awk -F "$us" -v OFS="$us" -v selected="$selected" -v phase="$phase" \
        -v specacs=" $(grep -oE 'AC-[0-9]{3}' "$spec" | sort -u | tr '\n' ' ')" \
        -v specreqs=" $(grep -oE 'REQ-[0-9]{3}' "$spec" | sort -u | tr '\n' ' ')" '
      function trim(s) { sub(/^[[:space:]]+/,"",s); sub(/[[:space:]]+$/, "", s); return s }
      function strip_ticks(s) { s=trim(s); if (s ~ /^`.*`$/) { sub(/^`/,"",s); sub(/`$/,"",s) } return s }
      function diag(level,message) { print "D",level,message; if (level=="error") errs++; else warns++ }
      function safe(s) {
        if (index(s,"\t") || index(s,sprintf("%c",28))) { diag("error","task fields cannot contain tabs or control separators"); return 0 }
        return 1
      }
      function rec(type,primary,task,stage,state,kind,family,locator,criteria,verify,reuse,detail) {
        if (selected!="" && index(selected,"|" stage "|")==0) return
        if (safe(primary) && safe(task) && safe(stage) && safe(state) && safe(kind) && safe(family) &&
            safe(locator) && safe(criteria) && safe(verify) && safe(reuse) && safe(detail))
          print "R",type,primary,task,stage,state,kind,family,locator,criteria,verify,reuse,detail
      }
      function set_field(name,value) {
        if (field_seen[name]++) diag("error","task " id " declares *" name ":* more than once")
        field[name]=trim(value)
      }
      function after(line,label, v) { v=line; sub("^.*\\*" label ":\\*[[:space:]]*","",v); return trim(v) }
      function has_ref(refs,want,    a,n,i,t) {
        n=split(refs,a,/,/); for(i=1;i<=n;i++){t=trim(a[i]); if(t==want)return 1} return 0
      }
      function criteria_overlap(criteria,refs,    p,a,n,i,t) {
        p=criteria; sub(/:.*/,"",p); gsub(/`/,"",p); n=split(p,a,/,/)
        for(i=1;i<=n;i++){t=trim(a[i]); if(has_ref(refs,t))return 1} return 0
      }
      function family_matches_defs(family,    i) {
        for (i=1;i<=task_defn;i++) if (def_family[task_defs[i] SUBSEP family]) return 1
        return 0
      }
      function files_has(files,want,    a,n,i,path) {
        n=split(files,a,/,/)
        for (i=1;i<=n;i++) {
          path=strip_ticks(a[i])
          if (path==want) return 1
        }
        return 0
      }
      function verify_syntax(kind,value,tests,    rest,close_pos,command) {
        if (substr(value,1,1)!="`") {
          diag("error","task " id " Verify must contain one backtick-delimited command")
          return
        }
        rest=substr(value,2); close_pos=index(rest,"`")
        if (close_pos<=1) {
          diag("error","task " id " Verify must contain one backtick-delimited command")
          return
        }
        command=substr(rest,1,close_pos-1)
        if (kind=="manual") {
          if (command !~ /^manual:[[:space:]]+[^[:space:]]/) diag("error","task " id " manual Verify must be manual: <observation>")
          return
        }
        if (command ~ /^manual:[[:space:]]/) diag("error","task " id " automated Verify cannot use manual observation syntax")
      }
      function parse_refs(refs,    a,n,i,t) {
        n=split(refs,a,/,/)
        for(i=1;i<=n;i++) {
          t=trim(a[i])
          if (t ~ /^(plan[[:space:]]+)?§[0-9]/) continue
          if (t ~ /^(AC|REQ|FM|INV)-/) {
            if (t !~ /^(AC|REQ|FM|INV)-[0-9][0-9][0-9]$/) { diag("error","task " id " has malformed Ref token: " t); continue }
            if (ref_seen[t]++) { diag("error","task " id " repeats Ref " t); continue }
            if (t ~ /^AC-/ && index(specacs," " t " ")==0) diag("error","task " id " references criterion missing from spec.md: " t)
            else if (t ~ /^REQ-/ && index(specreqs," " t " ")==0) diag("error","task " id " references requirement missing from spec.md: " t)
            else if (t ~ /^(FM|INV)-/) {
              if (!(t in def_type)) diag("error","task " id " references undefined failure/invariant " t)
              else { assigned[t]=1; task_defs[++task_defn]=t }
            }
            if (t ~ /^AC-/) task_has_ac=1
          } else if (t!="") diag("error","task " id " has unknown Ref token: " t)
        }
      }
      function parse_tests(raw,kind,refs,files,    a,n,i,loc,j,matched,relevant,file,defid,k,bound,owned_any) {
        n=split(raw,a,/,/)
        for(i=1;i<=n;i++) {
          loc=strip_ticks(a[i]); if (loc=="") { diag("error","task " id " has an empty *Tests:* locator"); continue }
          matched=0; relevant=0
          for(j=1;j<=family_n;j++) if (family_loc[j]==loc) {
            matched=1
            if (family_kind[j]!=kind) {
              diag("error","task " id " kind " kind " conflicts with family " family_name[j] " kind " family_kind[j])
              continue
            }
            if (criteria_overlap(family_criteria[j],refs) || family_matches_defs(family_name[j])) {
              relevant=1
              rec("test",loc,id,task_stage,task_state,kind,family_name[j],loc,family_criteria[j],field["Verify"],reuse,integration)
            }
          }
          if (!matched) diag("error","task " id " references unregistered test locator/observation: " loc)
          else if (!relevant) diag("warning","task " id " test " loc " has no criterion shared with its Refs")
          if (kind!="manual") {
            file=loc; sub(/::.*/,"",file)
            if (files_has(files,file)) owned_any=1
          }
          task_loc[++task_locn]=loc
        }
        if (kind!="manual" && task_stage!="Tests" && !owned_any)
          diag("warning","task " id " defers all local coverage: no *Tests:* locator file is in *Files:*" (integration!="" ? "; Integration owner does not excuse local tests" : ""))
        for(k=1;k<=task_defn;k++) {
          defid=task_defs[k]; bound=0
          for(i=1;i<=task_locn;i++) for(j=1;j<=family_n;j++)
            if (family_loc[j]==task_loc[i] && family_kind[j]==kind && def_family[defid SUBSEP family_name[j]]) {
              bound=1
              rec("binding",defid,id,task_stage,task_state,kind,family_name[j],task_loc[i],family_criteria[j],field["Verify"],reuse,integration)
            }
          if (!bound) diag("error","task " id " Ref " defid " has no matching typed test-family locator")
        }
      }
      function flush(    exempt,followup,reuse,owner,i) {
        if (id=="") return
        followup=(id ~ /^T[0-9][0-9][0-9][oascr][0-9]+$/)
        exempt=!followup && (has_agent || task_stage=="Ship")
        if (!exempt) {
          if (!field_seen["Refs"]) diag("error","task " id " has no *Refs:* binding field")
          if (!field_seen["Verify kind"]) diag("error","task " id " has no *Verify kind:* field")
          if (!field_seen["Tests"]) diag("error","task " id " has no *Tests:* field")
          if (!field_seen["Verify"]) diag("error","task " id " has no *Verify:* field")
          if (field_seen["Verify kind"] && field["Verify kind"] !~ /^(test|assertion|static|manual)$/)
            diag("error","task " id " has invalid Verify kind: " field["Verify kind"])
          reuse=field_seen["Reuse"] ? field["Reuse"] : "never"
          if (reuse !~ /^(local|never)$/) diag("error","task " id " has invalid Reuse value: " reuse)
          integration=field["Integration owner"]
          if (integration!="") {
            if (!(integration in task_order)) diag("error","task " id " Integration owner does not exist: " integration)
            else if (task_order[integration] <= task_order[id]) diag("error","task " id " Integration owner is not later: " integration)
            else if (task_stage_by_id[integration] != "Tests") diag("error","task " id " Integration owner is not in the Tests stage: " integration)
          }
          task_defn=0; task_locn=0; delete task_defs; delete task_loc; delete ref_seen; task_has_ac=0
          if (field_seen["Refs"]) parse_refs(field["Refs"])
          rec("task",id,id,task_stage,task_state,field["Verify kind"],"",field["Tests"],field["Refs"],field["Verify"],reuse,integration)
          if (field_seen["Verify kind"] && field["Verify kind"] ~ /^(test|assertion|static|manual)$/ && field_seen["Verify"])
            verify_syntax(field["Verify kind"],field["Verify"],field["Tests"])
          if (field_seen["Tests"] && field_seen["Verify kind"] && field["Verify kind"] ~ /^(test|assertion|static|manual)$/)
            parse_tests(field["Tests"],field["Verify kind"],field["Refs"],field["Files"])
        }
        id=""; delete field; delete field_seen; has_agent=0
      }
      FNR==NR {
        if ($1=="F") { family_n++; family_name[family_n]=$2; family_kind[family_n]=$3; family_criteria[family_n]=$4; family_loc[family_n]=$5 }
        else if ($1=="I") { def_type[$2]=$3; if (!def_seen[$2]++) def_ids[++def_n]=$2 }
        else if ($1=="D") { def_family[$2 SUBSEP $4]=1 }
        else if ($1=="T") { task_order[$2]=$3; task_stage_by_id[$2]=$4 }
        next
      }
      /^##[^#]/ { flush(); task_stage=$0; sub(/^##[[:space:]]*/,"",task_stage); next }
      /^- \[[ xX~]\] \*\*T[0-9][0-9][0-9][a-z0-9]*\*\*/ {
        flush(); match($0,/T[0-9][0-9][0-9][a-z0-9]*/); id=substr($0,RSTART,RLENGTH)
        state_char=substr($0,4,1); task_state=(state_char=="x"||state_char=="X")?"done":(state_char=="~"?"active":"pending")
        if (task_seen[id]++) diag("error","duplicate task id " id)
        next
      }
      id!="" && /\*Files:\*/ { set_field("Files",after($0,"Files")); next }
      id!="" && /\*Acceptance[^*]*:\*/ { if (!field_seen["Acceptance"]) set_field("Acceptance",$0); next }
      id!="" && /\*Verify kind:\*/ { set_field("Verify kind",after($0,"Verify kind")); next }
      id!="" && /\*Tests:\*/ { set_field("Tests",after($0,"Tests")); next }
      id!="" && /\*Verify:\*/ { set_field("Verify",after($0,"Verify")); next }
      id!="" && /\*Reuse:\*/ { set_field("Reuse",after($0,"Reuse")); next }
      id!="" && /\*Refs:\*/ { set_field("Refs",after($0,"Refs")); next }
      id!="" && /\*Integration owner:\*/ { set_field("Integration owner",after($0,"Integration owner")); next }
      id!="" && /\*Agent:\*/ { has_agent=1; next }
      END {
        flush()
        for(i=1;i<=def_n;i++) if (!assigned[def_ids[i]])
          diag("warning",def_ids[i] " has no non-gate task owner at task handoff")
      }
    ' "$maps" "$tasks" >> "$records" || {
      printf 'error: vf_bindings could not parse tasks.md\n' >&2
      rm -f "$records" "$maps" "$inventory"; rmdir "$tmpdir" 2>/dev/null || true
      return 1
    }
  fi

  errors="$(awk -F "$us" '$1=="D" && $2=="error" {n++} END{print n+0}' "$records")"
  warnings="$(awk -F "$us" '$1=="D" && $2=="warning" {n++} END{print n+0}' "$records")"
  while IFS="$us" read -r tag level message rest; do
    [[ "$tag" == D ]] || continue
    printf '%s: %s\n' "$level" "$message" >&2
  done < "$records"

  if [[ "$errors" -gt 0 ]]; then
    rm -f "$records" "$maps" "$inventory"; rmdir "$tmpdir" 2>/dev/null || true
    return 1
  fi

  out_tmp="$(mktemp "${output}.tmp.XXXXXX" 2>/dev/null)" || {
    printf 'error: cannot create binding catalog beside %s\n' "$output" >&2
    rm -f "$records" "$maps" "$inventory"; rmdir "$tmpdir" 2>/dev/null || true
    return 1
  }
  printf '%s\0' meta "$VF_SCHEMA" "" "$phase" "" "" "" "" "$contract" "" "" "$stage" > "$out_tmp"
  while IFS="$us" read -r tag f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 rest; do
    [[ "$tag" == R ]] || continue
    printf '%s\0' "$f1" "$f2" "$f3" "$f4" "$f5" "$f6" "$f7" "$f8" "$f9" "$f10" "$f11" "$f12" >> "$out_tmp"
  done < "$records"
  if ! mv "$out_tmp" "$output"; then
    printf 'error: cannot publish binding catalog to %s\n' "$output" >&2
    rm -f "$out_tmp" "$records" "$maps" "$inventory"; rmdir "$tmpdir" 2>/dev/null || true
    return 1
  fi
  rm -f "$records" "$maps" "$inventory"; rmdir "$tmpdir" 2>/dev/null || true
  [[ "$warnings" -ge 0 ]]
}
