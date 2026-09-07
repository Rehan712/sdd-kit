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
          path=trim(a[i])
          sub(/[[:space:]]+\(new( in T[0-9][0-9][0-9][a-z0-9]*)?\)$/, "", path)
          path=strip_ticks(path)
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
        exempt=!followup && !field_seen["Verify kind"] && (has_agent || task_stage=="Ship")
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

# SHA-256 is mandatory for new proof. Read stdin to avoid filename escaping.
vf_hash() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 < "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1" | awk '{print $1}'
  else echo 'verification prerequisite: SHA-256 unavailable' >&2; return 3; fi
}

vf_utc_valid() {
  LC_ALL=C awk -v t="$1" 'BEGIN {
    if (t !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) exit 1
    y=substr(t,1,4)+0; m=substr(t,6,2)+0; d=substr(t,9,2)+0
    split("31 28 31 30 31 30 31 31 30 31 30 31", days," ")
    if (y%4==0 && (y%100!=0 || y%400==0)) days[2]=29
    if(y<1 || m<1 || m>12 || d<1 || d>days[m] || substr(t,12,2)+0>23 || substr(t,15,2)+0>59 || substr(t,18,2)+0>59) exit 1
  }'
}

# Report catalog: twelve NUL fields, round records followed by findings.
# round,n,utc,source,floor,verdict,style,date,"","","",""
# finding,n,id,class,status,prior,severity,locations,root,trigger,reproduced,blocks
# Historical records remain readable and explicitly unclassified.
vf_reports() (
  local file="$1" gate="$2" output="$3" tmp
  tmp="$(mktemp "${output}.XXXXXX")" || return 3
  trap 'rm -f "$tmp"' EXIT
  [[ -e "$file" ]] || { : > "$output"; return 0; }
  _vf_reject_nul "$file" "$file" || return 3
  VF_REPORT_FILE="$file" awk -v gate="$gate" '
    function err(s) {print "report recovery: " ENVIRON["VF_REPORT_FILE"] ":" NR ": " s "; reconcile canonical records" > "/dev/stderr"; bad=1}
    function clean(s) {gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s}
    function value(s) {sub(/^.*\*\*[^*]+:\*\*[ ]*/, "", s); return clean(s)}
    function emit(a,b,c,d,e,f,g,h,i,j,k,l) {printf "%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c",a,0,b,0,c,0,d,0,e,0,f,0,g,0,h,0,i,0,j,0,k,0,l,0}
    function finding() {
      if (!fid) return
      if (style=="canonical") {
        if (fid !~ /^[A-Z][A-Z0-9]*-[0-9]+$/ || cls !~ /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/ || status !~ /^(new|open|resolved|reopened)$/ || prior=="" || root !~ /^(plan-gap|spec-gap|implementation-error)$/ || trigger=="" || repro=="" || loc !~ /[^ ]+:[0-9]+/) err("incomplete finding " fid)
        if (sev !~ /^(data-loss|wrong-result|regression|crash|minor|degraded)$/) err("unknown severity")
        if (seenfinding[n SUBSEP fid]++) err("duplicate finding ID")
        if (status!="resolved") {if (sev ~ /^(minor|degraded)$/) minors++; else blockers++}
      }
      emit("finding",n,fid,cls,status,prior,sev,loc,root,trigger,repro,blocks)
      fid=cls=status=prior=sev=loc=root=trigger=repro=blocks=""
    }
    function flush() {
      finding()
      if (!active) return
      if(style=="legacy" && gate=="reality-check" && declared=="" && n==1) declared=1
      if(n !~ /^[1-9][0-9]*$/ || n!=last+1 || declared!=n || !verdict || !date) err("missing, duplicate or nonsequential round identity")
      if(gate=="opponent" && verdict !~ /^(CLEARED|CHALLENGED|BLOCKED)$/) err("invalid opponent verdict")
      if(gate=="reality-check" && verdict !~ /^(READY|NEEDS WORK|FAILED)$/) err("invalid reality-check verdict")
      if(style=="canonical") {
        if (!ended || !utc || source !~ /^[a-f0-9]+$/ || length(source)!=64 || floor !~ /^FLOOR-[A-Za-z0-9.-]+$/) err("incomplete canonical identity")
        if(gate=="opponent" && (!counted || blockers!=wantb || minors!=wantm)) err("finding totals disagree")
        if(gate=="opponent" && ((verdict=="CLEARED" && blockers) || (verdict=="CHALLENGED" && !blockers))) err("verdict disagrees with blocking findings")
      }
      emit("round",n,utc,source,floor,verdict,style,date,"","","","")
      last=n; active=0
    }
    BEGIN {tick=sprintf("%c",96); fence=tick tick tick}
    {line=$0; sub(/^[ ]*/,"",line)}
    index(line,fence)==1 || index(line,"~~~")==1 {fenced=!fenced; next}
    fenced || /^[ ]*>/ {next}
    /^## Round [1-9][0-9]*$/ {
      flush(); n=$3; active=1; style="canonical"; declared=date=verdict=utc=source=floor=""; ended=counted=blockers=minors=0; next
    }
    /^# (Opponent review|Reality Check)/ {
      if (!active) {n=last+1; active=1; style="legacy"; declared=date=verdict=utc=source=floor=""; ended=counted=blockers=minors=0}
      else if (!declared && !utc) style="legacy"
      next
    }
    /^## Round/ {err("malformed round heading"); next}
    /^\*\*(Round|Timestamp|Source|Floor|Date|Verdict):\*\*/ {
      if (!active || ended) {err("identity outside active round"); next}
      key=$0; sub(/:\*\*.*/,"",key)
      if(seenfield[n SUBSEP key]++) err("duplicate identity field")
      v=value($0)
      if(key=="**Round") declared=v
      if(key=="**Timestamp") {utc=v; date=substr(v,1,10); style="canonical"}
      if(key=="**Source") source=v
      if(key=="**Floor") floor=v
      if(key=="**Date") date=v
      if(key=="**Verdict") verdict=v
      next
    }
    /^<!-- gate-round-end:/ {
      finding(); if($0!="<!-- gate-round-end: " gate ":" n " -->" || ended) err("completion marker mismatch"); ended=1; next
    }
    /^\*\*Blocking:\*\*/ {
      wantb=$2; wantm=$5; counted=1
      if(wantb !~ /^[0-9]+$/ || wantm !~ /^[0-9]+$/) err("malformed totals")
      next
    }
    /^### Finding / {finding(); if(!active || ended) err("finding outside round"); fid=$3; next}
    style=="legacy" && /^[0-9]+\. .*severity:/ {
      finding(); fid="legacy-" n "-" ++legacyid; cls="unclassified"; status="new"; prior="none"
      sev=$0; sub(/^.*severity:\*[ ]*/,"",sev); sev=clean(sev); next
    }
    fid && /^[ ]*- \*\*(Class|Status|Prior|Severity|Where|Root cause|Scenario|Reproduced|Blocks):\*\*/ {
      v=value($0)
      if($0 ~ /\*\*Class:/) cls=v
      if($0 ~ /\*\*Status:/) status=v
      if($0 ~ /\*\*Prior:/) prior=v
      if($0 ~ /\*\*Severity:/) sev=v
      if($0 ~ /\*\*Where:/) loc=v
      if($0 ~ /\*\*Root cause:/) root=v
      if($0 ~ /\*\*Scenario:/) trigger=v
      if($0 ~ /\*\*Reproduced:/) repro=v
      if($0 ~ /\*\*Blocks:/) blocks=v
    }
    END {flush(); if(fenced) err("unclosed code fence"); if(bad) exit 3}
  ' "$file" > "$tmp" || return 3
  local fields=() v
  while IFS= read -r -d '' v; do
    fields+=("$v")
    if (( ${#fields[@]} == 12 )); then
      if [[ "${fields[0]}" == round && "${fields[6]}" == canonical ]]; then
        vf_utc_valid "${fields[2]}" || { echo 'report recovery: invalid UTC calendar timestamp' >&2; return 3; }
      fi
      fields=()
    fi
  done < "$tmp"
  mv "$tmp" "$output"
)

vf_tally() (
  local spec="$1" tmp gate v f=() rounds blockers=0 minors=0 unclassified=0 locations=0
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/vf-tally.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  : > "$tmp/classes"
  for gate in opponent reality-check; do
    vf_reports "$spec/notes/$gate.md" "$gate" "$tmp/report" || return 3
    rounds=0
    while IFS= read -r -d '' v; do
      f+=("$v"); (( ${#f[@]} == 12 )) || continue
      case "${f[0]}" in
        round) rounds=$((rounds+1));;
        finding)
          if [[ "${f[4]}" != resolved ]]; then
            case "${f[6]}" in minor|degraded) minors=$((minors+1));; *) blockers=$((blockers+1));; esac
          fi
          [[ "${f[3]}" != unclassified ]] || unclassified=$((unclassified+1))
          locations=$((locations+$(printf '%s\n' "${f[7]}" | awk '{n=0; while(match($0,/[^ `,]+:[0-9]+/)){n++; $0=substr($0,RSTART+RLENGTH)}; print n}')))
          printf '%s\t%s\t%s\t%s\n' "${f[3]}" "${f[2]}" "${f[4]}" "${f[5]}" >> "$tmp/classes";;
      esac
      f=()
    done < "$tmp/report"
    printf '%s rounds=%s\n' "$gate" "$rounds"
  done
  printf 'blocking=%s minor=%s locations=%s unclassified=%s\n' "$blockers" "$minors" "$locations" "$unclassified"
  LC_ALL=C awk -F '\t' '
    $1!="unclassified" {total[$1]++; if($3=="new" || $3=="reopened") {if(seen[$1]++) recur[$1]++}}
    END {for(c in total) printf "class=%s findings=%d recurrences=%d\n",c,total[c],recur[c]+0}
  ' "$tmp/classes" | LC_ALL=C sort
)

# Writers initialize once at their entry point. Never trust inherited lock state.
vf_writer_init() {
  VF_LOCK_PATH='' VF_LOCK_TOKEN='' VF_STAGING=''
  trap 'vf_writer_cleanup' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP
}
vf_writer_cleanup() {
  if [[ -n "${VF_STAGING:-}" && -d "$VF_STAGING" && ! -L "$VF_STAGING" ]]; then
    rm -rf "$VF_STAGING"
  fi
  vf_unlock
}
vf_lock() {
  local spec="$1" path token
  [[ -z "${VF_LOCK_PATH:-}" ]] || { echo 'verification lock: nested acquisition refused' >&2; return 3; }
  mkdir -p "$spec/notes/verification" || return 3
  path="$spec/notes/verification/lock"
  token="$$-$RANDOM-$RANDOM"
  mkdir "$path" 2>/dev/null || {
    printf 'verification lock exists: %s; inspect owner and reconcile interrupted writer\n' "$path" >&2; return 3;
  }
  # Assignment follows successful acquisition. Failure before mkdir cannot own it.
  if ! printf '%s\n' "$token" > "$path/owner"; then rmdir "$path" 2>/dev/null || :; return 3; fi
  VF_LOCK_TOKEN="$token" VF_LOCK_PATH="$path"
}
vf_unlock() {
  if [[ -n "${VF_LOCK_PATH:-}" && ! -L "$VF_LOCK_PATH" && -f "$VF_LOCK_PATH/owner" && ! -L "$VF_LOCK_PATH/owner" ]] &&
      [[ "$(cat "$VF_LOCK_PATH/owner")" == "${VF_LOCK_TOKEN:-}" ]]; then
    rm "$VF_LOCK_PATH/owner" && rmdir "$VF_LOCK_PATH"
  fi
  VF_LOCK_PATH='' VF_LOCK_TOKEN=''
}

# COMPLETE is written last. Required files and their order are caller-owned.
vf_seal() {
  local dir="$1" file; shift
  [[ ! -e "$dir/COMPLETE" ]] || return 3
  { printf 'verification:1\n'
    for file in "$@"; do
      [[ "$file" != */* && -f "$dir/$file" && ! -L "$dir/$file" ]] || return 3
      printf '%s %s\n' "$(vf_hash "$dir/$file")" "$file"
    done
  } > "$dir/COMPLETE.tmp" || return 3
  mv "$dir/COMPLETE.tmp" "$dir/COMPLETE"
}
vf_integrity() (
  local dir="$1" file expected actual; shift
  [[ -d "$dir" && ! -L "$dir" && -f "$dir/COMPLETE" && ! -L "$dir/COMPLETE" ]] || {
    echo 'capture integrity: missing COMPLETE or linked directory' >&2; return 3;
  }
  expected='verification:1'
  for file in "$@"; do
    [[ -f "$dir/$file" && ! -L "$dir/$file" ]] || { echo "capture integrity: missing $file" >&2; return 3; }
    actual="$(vf_hash "$dir/$file")" || return 3
    expected="$expected
$actual $file"
  done
  [[ "$(cat "$dir/COMPLETE")" == "$expected" ]] || { echo 'capture integrity: COMPLETE/digest mismatch' >&2; return 3; }
)
vf_publish() {
  local staging="$1" final="$2"; shift 2
  [[ "${staging%/*}" == "${final%/*}" && ! -e "$final" && ! -L "$final" ]] || {
    echo 'verification publication: requires fresh same-parent destination' >&2; return 3;
  }
  vf_integrity "$staging" "$@" || return 3
  mv "$staging" "$final"
}

# Exclusions are generated paths only, never entire notes/.specify directories.
vf_bookkeeping_path() {
  case "$1" in
    .specify/specs/*/.tasks.accept.*|.specify/specs/*/notes/captures/*|.specify/specs/*/notes/verification/*|.specify/specs/*/notes/evidence.md|.specify/specs/*/notes/opponent.md|.specify/specs/*/notes/reality-check.md) return 0;;
  esac
  return 1
}
vf_semantic_file() { # <repo-relative path> <input-file> <output-file>
  case "$1" in
    .specify/specs/*/STATUS.md)
      awk '/^## Decisions/ {on=1; print; next} /^## / {on=0} on {print}' "$2" > "$3";;
    .specify/specs/*/spec.md|.specify/specs/*/plan.md|.specify/specs/*/tasks.md)
      awk '
        NR==1 && $0=="---" {fm=1; print; next}
        fm && $0=="---" {fm=0; print; next}
        fm && /^(status|updated):/ {next}
        /^[ ]*- \*Evidence:\*/ {next}
        {sub(/^- \[[ xX~]\] /,"- [ ] "); print}
      ' "$2" > "$3";;
    *) cp "$2" "$3";;
  esac
}
vf_path_record() { # <repo> <relative path> <output> <scratch>
  local repo="$1" path="$2" output="$3" scratch="$4" type mode digest link=''
  if vf_bookkeeping_path "$path"; then return 0; fi
  if [[ -L "$repo/$path" ]]; then
    type='link'; link="$(readlink "$repo/$path"; printf .)"; link="${link%.}"; digest=''; mode=120000
    # Target content is an input even when the target is outside the repository.
    if [[ -f "$repo/$path" ]]; then digest="$(vf_hash "$repo/$path")" || return 3
    elif [[ -d "$repo/$path" ]]; then echo "verification inputs: directory symlink requires explicit target files: $path" >&2; return 3; fi
  elif [[ -f "$repo/$path" ]]; then
    type='file'; mode=100644; [[ ! -x "$repo/$path" ]] || mode=100755
    vf_semantic_file "$path" "$repo/$path" "$scratch/semantic" || return 3
    digest="$(vf_hash "$scratch/semantic")" || return 3
  elif [[ ! -e "$repo/$path" ]]; then type=missing; mode=''; digest=''
  else echo "verification inputs: unsupported file type: $path" >&2; return 3; fi
  printf '%s\0' path "$path" "$type" "$mode" "$digest" "$link" >> "$output"
}

# Fixed arity six-field input records. Git supplies NUL-safe deterministic
# tracked/index and untracked ordering; no GNU sort -z or line-split filenames.
vf_snapshot() (
  local spec="$1" repo="$2" cwd="$3" output="$4" tmp path record head oid mode stage key value tool resolved
  spec="$(cd "$spec" && pwd -P)" || return 3
  repo="$(cd "$repo" && pwd -P)" || return 3
  cwd="$(cd "$cwd" && pwd -P)" || return 3
  [[ "$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" == "$repo" ]] || {
    echo 'verification inputs: Git worktree root required' >&2; return 3;
  }
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/vf-snapshot.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_config "$repo/.specify/stack.yml" "$spec/tasks.md" "$tmp/config" || return 3
  printf '%s\0' version 1 "$repo" "$cwd" '' '' > "$tmp/inputs"
  git -C "$repo" ls-files --stage -z > "$tmp/index" || return 3
  git -C "$repo" ls-files --cached --others --exclude-standard -z > "$tmp/paths" || return 3
  while IFS= read -r -d '' record; do
    path="${record#*$'\t'}"; head="${record%%$'\t'*}"
    vf_bookkeeping_path "$path" && continue
    read -r mode oid stage <<< "$head"
    [[ "$mode" != 160000 ]] || { echo "verification inputs: submodule requires explicit transitive inputs: $path" >&2; return 3; }
    git -C "$repo" cat-file blob "$oid" > "$tmp/blob" || return 3
    vf_semantic_file "$path" "$tmp/blob" "$tmp/semantic" || return 3
    printf '%s\0' index "$path" "$mode" "$stage" "$(vf_hash "$tmp/semantic")" '' >> "$tmp/inputs"
  done < "$tmp/index"
  while IFS= read -r -d '' path; do vf_path_record "$repo" "$path" "$tmp/inputs" "$tmp" || return 3; done < "$tmp/paths"
  while IFS= read -r -d '' path; do
    case "$path" in /*|../*|*/../*|*/..|..) echo 'verification inputs must be repo relative' >&2; return 3;; esac
    [[ -e "$repo/$path" || -L "$repo/$path" ]] || { echo "verification input missing: $path" >&2; return 3; }
    if [[ -d "$repo/$path" && ! -L "$repo/$path" ]]; then
      # find ordering is not canonical across platforms. Hash each record then
      # sort its digest; paths themselves remain intact in each framed record.
      find "$repo/$path" \( -type f -o -type l \) -print0 > "$tmp/extra" || return 3
      : > "$tmp/extra-hashes"
      while IFS= read -r -d '' record; do
        : > "$tmp/path-record"
        vf_path_record "$repo" "${record#"$repo/"}" "$tmp/path-record" "$tmp" || return 3
        vf_hash "$tmp/path-record" >> "$tmp/extra-hashes" || return 3
      done < "$tmp/extra"
      LC_ALL=C sort "$tmp/extra-hashes" > "$tmp/sorted"
      printf '%s\0' declared-directory "$path" "$(vf_hash "$tmp/sorted")" '' '' '' >> "$tmp/inputs"
    else vf_path_record "$repo" "$path" "$tmp/inputs" "$tmp" || return 3; fi
  done < "$tmp/config/inputs.nul"
  # compgen emits names only. Values are hashed without ever persisting secrets.
  compgen -e | LC_ALL=C sort > "$tmp/env-names"
  while IFS= read -r key; do
    case "$key" in PWD|OLDPWD|SHLVL|_) continue;; esac
    value="${!key}"
    printf '%s\0' environment "$key" present "$(printf '%s' "$value" | vf_hash /dev/stdin)" '' '' >> "$tmp/inputs"
  done < "$tmp/env-names"
  { printf '%s\0' bash; cat "$tmp/config/tools.nul"; } > "$tmp/tools"
  while IFS= read -r -d '' tool; do
    resolved="$(command -v "$tool")" || { echo "verification tool missing: $tool" >&2; return 3; }
    [[ -f "$resolved" && -x "$resolved" ]] || { echo "verification tool is not an executable file: $tool" >&2; return 3; }
    printf '%s\0' tool "$tool" "$resolved" "$(vf_hash "$resolved")" '' '' >> "$tmp/inputs"
  done < "$tmp/tools"
  for tool in lib.sh verification-lib.sh spec-run.sh spec-task.sh spec-gate.sh sdd-analyze.sh spec-ac-coverage.sh spec-evidence.sh; do
    resolved="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/$tool"
    [[ -f "$resolved" ]] || { echo "verification harness missing: $tool" >&2; return 3; }
    printf '%s\0' harness "$resolved" "$(vf_hash "$resolved")" '' '' '' >> "$tmp/inputs"
  done
  # The referenced spec can be outside the repository for an umbrella check.
  for path in spec.md plan.md tasks.md STATUS.md; do
    [[ -f "$spec/$path" ]] || continue
    vf_semantic_file ".specify/specs/active/$path" "$spec/$path" "$tmp/semantic" || return 3
    printf '%s\0' document "$spec/$path" "$(vf_hash "$tmp/semantic")" '' '' '' >> "$tmp/inputs"
  done
  cp "$tmp/inputs" "$output" || return 3
  vf_hash "$output"
)

# Normalize the mutable state column; task text and binding changes remain inputs.
vf_binding_snapshot() (
  local spec="$1" out="$2" tmp value fields=()
  tmp="$(mktemp "${TMPDIR:-/tmp}/vf-bindings.XXXXXX")" || return 3
  trap 'rm -f "$tmp"' EXIT
  vf_bindings "$spec" tasks '' "$tmp" || return 3
  : > "$out"
  while IFS= read -r -d '' value; do
    fields+=("$value"); (( ${#fields[@]} == 12 )) || continue
    case "${fields[0]}" in task|test|binding) fields[4]='';; esac
    printf '%s\0' "${fields[@]}" >> "$out"
    fields=()
  done < "$tmp"
  (( ${#fields[@]} == 0 ))
)
vf_task_info() { # catalog task -> VF_TASK (twelve fields)
  local value fields=()
  VF_TASK=()
  while IFS= read -r -d '' value; do
    fields+=("$value"); (( ${#fields[@]} == 12 )) || continue
    if [[ "${fields[0]}" == task && "${fields[2]}" == "$2" ]]; then VF_TASK=("${fields[@]}"); VF_TASK_COMMAND="${fields[9]#\`}"; VF_TASK_COMMAND="${VF_TASK_COMMAND%%\`*}"; return 0; fi
    fields=()
  done < "$1"
  echo "verification task missing: $2" >&2; return 3
}

# Strict unique known NUL key/value metadata; data is never sourced as shell.
vf_meta_load() {
  local file="$1" key value allowed=" $2 " old
  VF_META_KEYS=() VF_META_VALUES=()
  [[ -f "$file" && ! -L "$file" ]] || return 3
  while :; do
    key=''
    if ! IFS= read -r -d '' key; then [[ -z "$key" ]] || return 3; break; fi
    IFS= read -r -d '' value || return 3
    case "$allowed" in *" $key "*) ;; *) echo "metadata: unknown key $key" >&2; return 3;; esac
    for old in ${VF_META_KEYS[@]+"${VF_META_KEYS[@]}"}; do [[ "$old" != "$key" ]] || { echo "metadata: duplicate key $key" >&2; return 3; }; done
    VF_META_KEYS+=("$key"); VF_META_VALUES+=("$value")
  done < "$file"
}
vf_meta_get() {
  local i
  for ((i=0;i<${#VF_META_KEYS[@]};i++)); do
    if [[ "${VF_META_KEYS[i]}" == "$1" ]]; then printf '%s' "${VF_META_VALUES[i]}"; return 0; fi
  done
  echo "metadata: missing $1" >&2; return 3
}
VF_CAPTURE_KEYS='version id sequence kind start end repo cwd check shell input_before input_after no_tick exit output_digest output_bytes policy key'
VF_CAPTURE_FILES=(meta.nul argv.nul inputs.nul inputs-after.nul bindings.nul output.log summary.txt)

vf_escape() {
  # Display bytes only. Preserve full fields in metadata and the complete log.
  LC_ALL=C awk 'BEGIN {ORS=""} {if(NR>1) printf "\\n"; gsub(/\\/,"\\\\"); gsub(/[[:cntrl:]]/,"?"); printf "%s",$0}'
}
vf_summary() {
  local dir="$1" mode="$2" cap command key log exit_code digest input
  vf_meta_load "$dir/meta.nul" "$VF_CAPTURE_KEYS" || return 3
  cap="$(vf_meta_get id)"; exit_code="$(vf_meta_get exit)"
  digest="$(vf_meta_get output_digest)"; input="$(vf_meta_get input_before)"
  command="$(tr '\000' ' ' < "$dir/argv.nul" | vf_escape | head -c 450)"
  key="$(vf_meta_get key | vf_escape | head -c 450)"
  log="$(printf '%s' "${dir%/*}/$cap/output.log" | vf_escape | head -c 350)"
  printf 'capture=%s command=%s key=%s exit=%s output=%s input=%s log=%s [complete metadata: capture directory]\n' \
    "$cap" "$command" "$key" "$exit_code" "$digest" "$input" "$log" | head -c "$VF_SUCCESS_BYTES"
  if [[ "$mode" == failure ]]; then
    LC_ALL=C tail -n "$VF_DIAGNOSTIC_LINES" "$dir/output.log" | \
      LC_ALL=C awk '{gsub(/[[:cntrl:]]/,"?"); print}' | head -c $((VF_FAILURE_BYTES-VF_SUCCESS_BYTES))
  fi
}

vf_capture() { # spec binding cwd policy -- argv...
  local spec="$1" binding="$2" cwd="$3" policy="$4"; shift 4
  [[ "${1:-}" == -- && $# -gt 1 ]] || return 2; shift
  VF_CAPTURE_ID="" VF_CAPTURE_DIR=""
  local repo parent staging id seq before after rc start end check shell_identity final key output_digest
  spec="$(cd "$spec" && pwd -P)" || return 3
  cwd="$(cd "$cwd" && pwd -P)" || return 3
  repo="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || { echo 'capture requires a Git worktree' >&2; return 3; }
  case "$policy" in local|never) ;; *) return 2;; esac
  vf_lock "$spec" || return 3
  parent="$spec/notes/captures"
  mkdir -p "$parent" "$spec/notes/verification/captures" || return 3
  staging="$(mktemp -d "$parent/.capture.XXXXXX")" || return 3
  VF_STAGING="$staging"
  seq=0
  if [[ -f "$spec/notes/verification/sequence" ]]; then
    seq="$(cat "$spec/notes/verification/sequence")"
    [[ "$seq" =~ ^[0-9]+$ && ${#seq} -lt 10 ]] || { echo 'capture ledger: invalid sequence; reconcile' >&2; return 3; }
  fi
  seq=$((seq+1))
  printf '%s\n' "$seq" > "$spec/notes/verification/sequence.tmp" && mv "$spec/notes/verification/sequence.tmp" "$spec/notes/verification/sequence" || return 3
  id="CAP-$seq-${staging##*.}"
  final="$parent/$id"
  cp "$binding" "$staging/bindings.nul" || return 3
  printf '%s\0' "$@" > "$staging/argv.nul"
  shell_identity="$(command -v bash)"
  before="$(vf_snapshot "$spec" "$repo" "$cwd" "$staging/inputs.nul")" || return 3
  { cat "$staging/argv.nul"; printf '%s\0' "$shell_identity" "$(vf_hash "$shell_identity")" "$repo" "$cwd" "$policy"; } > "$staging/check"
  check="$(vf_hash "$staging/check")" || return 3
  rm "$staging/check"
  start="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  (cd "$cwd" && "$@") > "$staging/output.log" 2>&1
  rc=$?
  end="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  after="$(vf_snapshot "$spec" "$repo" "$cwd" "$staging/inputs-after.nul")" || after=unknown
  key=''
  if [[ -n "${VF_KEY_PATTERN:-}" ]]; then key="$(grep -E -- "$VF_KEY_PATTERN" "$staging/output.log" | tail -1 || :)"; fi
  [[ -n "$key" ]] || key="$(awk 'NF {line=$0} END {print line}' "$staging/output.log")"
  [[ -n "$key" ]] || key='(no output)'
  output_digest="$(vf_hash "$staging/output.log")" || return 3
  printf '%s\0' version 1 id "$id" sequence "$seq" kind command start "$start" end "$end" \
    repo "$repo" cwd "$cwd" check "$check" shell "$shell_identity" input_before "$before" input_after "$after" \
    no_tick "${VF_NO_TICK:-1}" exit "$rc" output_digest "$output_digest" \
    output_bytes "$(wc -c < "$staging/output.log" | tr -d ' ')" policy "$policy" key "$key" > "$staging/meta.nul"
  # Render using the final log reference, without exposing a staging path.
  vf_summary "$staging" success > "$staging/summary.txt"
  vf_seal "$staging" "${VF_CAPTURE_FILES[@]}" || return 3
  vf_publish "$staging" "$final" "${VF_CAPTURE_FILES[@]}" || return 3
  VF_STAGING=''
  cp "$final/COMPLETE" "$spec/notes/verification/captures/$id" || return 3
  { printf '\n## %s — %s\n\n' "$id" "$end"; printf 'Captured run, exit %s. Full log: `notes/captures/%s/output.log`.\n\n' "$rc" "$id"; cat "$final/summary.txt"; } >> "$spec/notes/evidence.md" || return 3
  vf_unlock
  VF_CAPTURE_ID="$id"
  VF_CAPTURE_DIR="$final"
  return "$rc"
}
vf_capture_check() (
  local spec="$1" id="$2" manifest="$3" predicate="$4" dir key v exit_code before after seq check shell_path repo cwd policy ledger other f ocheck oinput oexit oseq
  [[ "$id" =~ ^CAP-[1-9][0-9]*-[A-Za-z0-9]+$ ]] || { echo 'capture integrity: invalid capture ID' >&2; return 3; }
  case "$predicate" in integrity|current|reuse) ;; *) return 2;; esac
  dir="$spec/notes/captures/$id"
  vf_integrity "$dir" "${VF_CAPTURE_FILES[@]}" || return 3
  ledger="$spec/notes/verification/captures/$id"
  [[ -f "$ledger" && ! -L "$ledger" ]] && cmp -s "$dir/COMPLETE" "$ledger" || { echo 'capture integrity: ledger disagreement or missing provenance' >&2; return 3; }
  vf_meta_load "$dir/meta.nul" "$VF_CAPTURE_KEYS" || return 3
  for key in $VF_CAPTURE_KEYS; do vf_meta_get "$key" >/dev/null || return 3; done
  [[ "$(vf_meta_get version)" == 1 && "$(vf_meta_get id)" == "$id" && "$(vf_meta_get kind)" == command ]] || return 3
  seq="$(vf_meta_get sequence)"; [[ "$seq" =~ ^[1-9][0-9]*$ && "$id" == CAP-"$seq"-* ]] || return 3
  vf_utc_valid "$(vf_meta_get start)" && vf_utc_valid "$(vf_meta_get end)" || return 3
  [[ "$(vf_meta_get start)" < "$(vf_meta_get end)" || "$(vf_meta_get start)" == "$(vf_meta_get end)" ]] || return 3
  exit_code="$(vf_meta_get exit)"; [[ "$exit_code" =~ ^[0-9]+$ && ${#exit_code} -le 3 && "$exit_code" -le 255 ]] || return 3
  [[ "$(vf_meta_get no_tick)" =~ ^[01]$ ]] || return 3
  before="$(vf_meta_get input_before)"; after="$(vf_meta_get input_after)"
  [[ "$before" == "$(vf_hash "$dir/inputs.nul")" && "$after" == "$(vf_hash "$dir/inputs-after.nul")" ]] || {
    echo 'capture integrity: input manifest mismatch' >&2; return 3;
  }
  [[ "$(vf_meta_get output_digest)" == "$(vf_hash "$dir/output.log")" && "$(vf_meta_get output_bytes)" == "$(wc -c < "$dir/output.log" | tr -d ' ')" ]] || return 3
  check="$(vf_meta_get check)"; shell_path="$(vf_meta_get shell)"; repo="$(vf_meta_get repo)"; cwd="$(vf_meta_get cwd)"; policy="$(vf_meta_get policy)"
  case "$policy" in local|never) ;; *) return 3;; esac
  # Integrity authenticates the stored observation, including its failure.
  [[ "$predicate" != integrity ]] || return 0
  [[ "$exit_code" == 0 ]] || { echo "capture failed: exit $exit_code" >&2; return 3; }
  [[ "$before" == "$after" ]] || { echo 'capture stale: inputs changed during execution' >&2; return 3; }
  [[ -f "$manifest" && "$before" == "$(vf_hash "$manifest")" ]] || { echo 'capture stale: current inputs changed; refresh verification' >&2; return 3; }
  [[ "$predicate" != reuse || "$policy" == local ]] || { echo 'capture freshness: unknown/external/time policy requires execution' >&2; return 3; }
  [[ -f "$shell_path" ]] || return 3
  v="$( { cat "$dir/argv.nul"; printf '%s\0' "$shell_path" "$(vf_hash "$shell_path")" "$repo" "$cwd" "$policy"; } | vf_hash /dev/stdin)"
  [[ "$check" == "$v" ]] || { echo 'capture stale: command/shell/cwd identity changed' >&2; return 3; }
  for other in "$spec"/notes/verification/captures/CAP-*; do
    [[ -f "$other" ]] || continue
    f="${other##*/}"
    vf_capture_check "$spec" "$f" '' integrity >/dev/null || { echo "capture ledger: damaged record $f" >&2; return 3; }
    vf_meta_load "$spec/notes/captures/$f/meta.nul" "$VF_CAPTURE_KEYS" || return 3
    oseq="$(vf_meta_get sequence)"; ocheck="$(vf_meta_get check)"; oinput="$(vf_meta_get input_before)"; oexit="$(vf_meta_get exit)"
    if (( oseq > seq )) && [[ "$ocheck" == "$check" && "$oinput" == "$before" && "$oexit" != 0 ]]; then
      echo "capture superseded: later failed run $f for the same check and inputs" >&2; return 3
    fi
  done
)

vf_task_capture_matches() (
  local catalog="$1" task="$2" dir="$3" tmp
  vf_task_info "$catalog" "$task" || return 3
  tmp="$(mktemp "${TMPDIR:-/tmp}/vf-argv.XXXXXX")" || return 3
  trap 'rm -f "$tmp"' EXIT
  printf '%s\0' "$(command -v bash)" -o pipefail -c "$VF_TASK_COMMAND" > "$tmp"
  cmp -s "$tmp" "$dir/argv.nul" && cmp -s "$catalog" "$dir/bindings.nul"
)

# Discover current proof without changing historical completion or receipts.
vf_task_current() (
  local spec="$1" task="$2" catalog="$3" manifest="$4" predicate="${5:-current}" dir found=''
  for dir in "$spec"/notes/captures/CAP-*; do
    [[ -d "$dir" ]] || continue
    vf_task_capture_matches "$catalog" "$task" "$dir" || continue
    if vf_capture_check "$spec" "${dir##*/}" "$manifest" "$predicate" >/dev/null 2>&1; then found="${dir##*/}"; fi
  done
  [[ -n "$found" ]] || { echo "current evidence missing/stale: $task; refresh its Verify (historical completion preserved)" >&2; return 3; }
  printf '%s\n' "$found"
)

vf_evidence_current() (
  local spec="$1" repo tmp task state stage subject
  repo="$(git -C "$spec" rev-parse --show-toplevel 2>/dev/null)" || return 3
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/vf-evidence.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_binding_snapshot "$spec" "$tmp/bindings" || return 3
  vf_snapshot "$spec" "$repo" "$repo" "$tmp/inputs" >/dev/null || return 3
  while IFS=$'\t' read -r task state stage subject; do
    [[ "$state" == "done" ]] || continue
    # Only exempt true administrative tasks absent from the typed catalog.
    vf_task_info "$tmp/bindings" "$task" >/dev/null 2>&1 || continue
    if [[ "${VF_TASK[5]}" == manual ]]; then vf_manual_current "$spec" "$task" || return 3
    else vf_task_current "$spec" "$task" "$tmp/bindings" "$tmp/inputs" || return 3; fi
  done < <(bash "$(dirname -- "${BASH_SOURCE[0]}")/spec-task.sh" list "$spec")
  echo 'current evidence: all completed task checks have valid current captures'
)
# Parse only an explicit return block. All emitted records have four NUL fields.
vf_return_parse() {
  _vf_reject_nul "$1" "$1" || return 3
  [[ "$(wc -c < "$1")" -le 65536 ]] || { echo 'return exceeds 64 KiB' >&2; return 3; }
  awk '
    function err(s) {print "return: " s > "/dev/stderr"; bad=1}
    function trim(s) {sub(/^[ ]+/,"",s); sub(/[ ]+$/,"",s); return s}
    function rec(a,b,c,d) {printf "%s%c%s%c%s%c%s%c",a,0,b,0,c,0,d,0}
    /^Verification-Return:/ {if(started++) err("duplicate block"); if($0!="Verification-Return: 1") err("unsupported version"); next}
    !started {next}
    /^Task: / {if(task++) err("duplicate Task"); rec("task",substr($0,7),"",""); next}
    /^Captures: / {if(caps++) err("duplicate Captures"); rec("captures",substr($0,11),"",""); next}
    /^Summary: / {summaries++; rec("summary",substr($0,10),"",""); next}
    /^Manual observation: / {if(manual++) err("duplicate manual observation"); rec("manual",substr($0,21),"",""); next}
    /^Failure modes:/ {if(modes++) err("duplicate Failure modes"); if($0=="Failure modes: none") rec("none","","",""); else if($0!="Failure modes:") err("malformed Failure modes"); next}
    /^[ ]*$/ {next}
    modes && /^(FM|INV)-[0-9][0-9][0-9],/ {
      if(split($0,a,",")!=3) err("mapping needs ID, locator, capture")
      else rec("mapping",trim(a[1]),trim(a[2]),trim(a[3])); next
    }
    {err("unexpected field or malformed mapping")}
    END {if(!started || task!=1 || caps!=1 || modes!=1 || !summaries) err("incomplete verification return"); if(bad) exit 3}
  ' "$1" > "$2"
}

vf_return_check() (
  local spec="$1" task="$2" return_file="$3" receipt="$4" tmp repo v i found summary f=() cap ids=() summaries=() mappings=() manual='' none=0 name path digest observer utc result extra before
  [[ -f "$return_file" && ! -L "$return_file" ]] || { echo 'return file missing or linked' >&2; return 3; }
  spec="$(cd "$spec" && pwd -P)" || return 3
  repo="$(git -C "$spec" rev-parse --show-toplevel)" || return 3
  tmp="$(mktemp -d "$spec/notes/verification/return.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_binding_snapshot "$spec" "$tmp/bindings" || return 3
  vf_task_info "$tmp/bindings" "$task" || return 3
  before="$(vf_snapshot "$spec" "$repo" "$repo" "$tmp/inputs")" || return 3
  vf_return_parse "$return_file" "$tmp/return" || return 3
  while IFS= read -r -d '' v; do
    f+=("$v"); (( ${#f[@]} == 4 )) || continue
    case "${f[0]}" in
      task) [[ "${f[1]}" == "$task" ]] || { echo 'return: wrong task' >&2; return 3; };;
      captures)
        if [[ "${f[1]}" != none ]]; then
          IFS=',' read -r -a ids <<< "${f[1]}"
          for ((i=0;i<${#ids[@]};i++)); do ids[i]="$(printf '%s' "${ids[i]}" | sed 's/^ *//;s/ *$//')"; done
        fi;;
      summary) summaries+=("${f[1]}");;
      manual) manual="${f[1]}";;
      none) none=1;;
      mapping) mappings+=("${f[1]}" "${f[2]}" "${f[3]}");;
    esac
    f=()
  done < "$tmp/return"
  : > "$tmp/required"
  while IFS= read -r -d '' v; do
    f+=("$v"); (( ${#f[@]} == 12 )) || continue
    if [[ "${f[0]}" == binding && "${f[2]}" == "$task" ]]; then printf '%s\t%s\n' "${f[1]}" "${f[7]}" >> "$tmp/required"; fi
    f=()
  done < "$tmp/bindings"
  LC_ALL=C sort -u "$tmp/required" > "$tmp/want"
  if [[ -s "$tmp/want" ]]; then (( none == 0 && ${#mappings[@]} > 0 )) || { echo 'return: required Failure modes are missing' >&2; return 3; }
  else (( none == 1 && ${#mappings[@]} == 0 )) || { echo 'return: empty required set must explicitly be none' >&2; return 3; }; fi
  if [[ "${VF_TASK[5]}" == manual ]]; then
    [[ ${#ids[@]} == 0 && -n "$manual" ]] || { echo 'manual acceptance requires an observation and Captures: none' >&2; return 3; }
    IFS=',' read -r name path digest observer utc result extra <<< "$manual"
    for v in name path digest observer utc result; do
      printf -v "$v" '%s' "$(printf '%s' "${!v}" | sed 's/^ *//;s/ *$//')"
    done
    [[ -z "$extra" && -n "$observer" && "$result" == PASS:* && "$name" == "${VF_TASK[7]}" ]] || { echo 'manual observation fields do not match the planned family' >&2; return 3; }
    case "$path" in /*|../*|*/../*|*/..|..) return 3;; esac
    [[ -f "$repo/$path" && ! -L "$repo/$path" && "$digest" == "$(vf_hash "$repo/$path")" ]] || { echo 'manual artifact missing or digest mismatch' >&2; return 3; }
    vf_utc_valid "$utc" || return 3
  else
    [[ -z "$manual" && ${#ids[@]} -gt 0 && ${#ids[@]} -eq ${#summaries[@]} ]] || { echo 'automated return needs captured checks and canonical summaries' >&2; return 3; }
    : > "$tmp/caps"
    for cap in "${ids[@]}"; do
      grep -Fx -- "$cap" "$tmp/caps" >/dev/null && { echo 'return: duplicate capture' >&2; return 3; }
      printf '%s\n' "$cap" >> "$tmp/caps"
      vf_capture_check "$spec" "$cap" "$tmp/inputs" current || return 3
      vf_task_capture_matches "$tmp/bindings" "$task" "$spec/notes/captures/$cap" || { echo 'return: capture command/test bindings do not prove this task Verify; use --from-task' >&2; return 3; }
      vf_meta_load "$spec/notes/captures/$cap/meta.nul" "$VF_CAPTURE_KEYS" || return 3
      [[ "$(vf_meta_get no_tick)" == 1 ]] || { echo 'return: worker must use --no-tick' >&2; return 3; }
      v="$(cat "$spec/notes/captures/$cap/summary.txt")"; found=0
      for summary in "${summaries[@]}"; do [[ "$summary" != "$v" ]] || found=$((found+1)); done
      (( found == 1 )) || { echo 'return: summary is not the authentic capture summary' >&2; return 3; }
    done
  fi
  : > "$tmp/got"
  for ((i=0;i<${#mappings[@]};i+=3)); do
    printf '%s\t%s\n' "${mappings[i]}" "${mappings[i+1]}" >> "$tmp/got"
    if [[ "${VF_TASK[5]}" == manual ]]; then [[ "${mappings[i+2]}" == manual ]] || return 3
    else grep -Fx -- "${mappings[i+2]}" "$tmp/caps" >/dev/null || { echo 'return: mapping names unknown capture' >&2; return 3; }; fi
  done
  LC_ALL=C sort "$tmp/got" > "$tmp/actual"
  cmp -s "$tmp/want" "$tmp/actual" || { echo 'return: missing, extra, duplicate or unknown FM/INV test binding' >&2; return 3; }
  # The catalog is authoritative; locators must exist in source at acceptance.
  while IFS= read -r -d '' v; do
    f+=("$v"); (( ${#f[@]} == 12 )) || continue
    if [[ "${f[0]}" == test && "${f[2]}" == "$task" && "${f[5]}" != manual ]]; then
      path="${f[7]%%::*}"; name="${f[7]#*::}"
      [[ -f "$repo/$path" ]] && grep -F -- "$name" "$repo/$path" >/dev/null || { echo "return: unknown test declaration ${f[7]}" >&2; return 3; }
    fi
    f=()
  done < "$tmp/bindings"
  [[ "$before" == "$(vf_snapshot "$spec" "$repo" "$repo" "$tmp/after")" ]] || { echo 'return: inputs changed during validation' >&2; return 3; }
  printf '%s\0' version 1 task "$task" return_digest "$(vf_hash "$return_file")" binding_digest "$(vf_hash "$tmp/bindings")" input "$before" captures "${ids[*]:-none}" manual "$manual" > "$receipt"
)

vf_tasks_rewrite() { # task-file id box evidence output; one rewrite including date
  VF_EVIDENCE="$4" awk -v id="$2" -v box="$3" -v today="$(date +%Y-%m-%d)" '
    function leave() {if(on && ev!="" && !written) {print "  - *Evidence:* " ev; written=1}; on=0}
    BEGIN {ev=ENVIRON["VF_EVIDENCE"]}
    NR==1 && $0=="---" {fm=1; print; next}
    fm && /^updated:/ {print "updated: " today; updated=1; next}
    fm && $0=="---" {if(!updated) print "updated: " today; fm=0; print; next}
    /^- \[[ xX~]\] \*\*T[0-9][0-9][0-9][a-z0-9]*\*\*/ {
      leave(); match($0,/T[0-9][0-9][0-9][a-z0-9]*/)
      if(substr($0,RSTART,RLENGTH)==id) {sub(/^- \[[ xX~]\]/,"- [" box "]"); on=1; found++}
      print; next
    }
    /^## / {leave()}
    on && /^[ ]*- \*Evidence:\*/ {if(ev!="") {print "  - *Evidence:* " ev; written=1} else print; next}
    on && !/^[ ]*- \*/ {leave()}
    {print}
    END {leave(); if(found!=1) exit 3}
  ' "$1" > "$5"
}

vf_accept_audit() {
  local spec="$1" task="$2" ret="$3" outcome="$4" reason="$5" before="$6" after="$7" tmp final
  mkdir -p "$spec/notes/verification/accept-events" || return 3
  tmp="$(mktemp -d "$spec/notes/verification/accept-events/.event.XXXXXX")" || return 3
  printf '%s\0' version 1 task "$task" return_digest "$ret" outcome "$outcome" reason "$reason" before "$before" after "$after" timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$tmp/meta.nul"
  vf_seal "$tmp" meta.nul || return 3
  final="${tmp%/*}/ACCEPT-${tmp##*.}"
  vf_publish "$tmp" "$final" meta.nul
}

vf_accept_transaction() {
  local spec="$1" task="$2" return_file="$3" tasks before after ret tmp prepared evidence old reason rc
  spec="$(cd "$spec" && pwd -P)" || return 3
  tasks="$spec/tasks.md"
  vf_lock "$spec" || return 3
  before="$(vf_hash "$tasks")" || return 3
  ret=missing; [[ ! -f "$return_file" ]] || ret="$(vf_hash "$return_file")"
  mkdir -p "$spec/notes/verification/accepted/$task" || return 3
  tmp="$(mktemp -d "$spec/notes/verification/accepted/$task/.accept.XXXXXX")" || return 3
  VF_STAGING="$tmp"
  # Reconcile every prepared transaction before accepting another return.
  for old in "$spec/notes/verification/accepted/$task"/ACC-*; do
    [[ -d "$old" && ! -e "$old/COMMITTED" ]] || continue
    vf_integrity "$old" meta.nul return.txt tasks.after digests.nul || return 3
    vf_meta_load "$old/digests.nul" 'before after' || return 3
    if [[ "$before" == "$(vf_meta_get after)" ]]; then
      printf '%s\n' "$(vf_hash "$old/COMPLETE")" > "$old/COMMITTED"
    elif [[ "$before" == "$(vf_meta_get before)" ]]; then
      vf_return_check "$spec" "$task" "$old/return.txt" "$tmp/revalidated" || return 3
      prepared="$(mktemp "$spec/.tasks.accept.XXXXXX")" || return 3
      cp "$old/tasks.after" "$prepared" && mv "$prepared" "$tasks" || return 3
      printf '%s\n' "$(vf_hash "$old/COMPLETE")" > "$old/COMMITTED"
      before="$(vf_hash "$tasks")"
    else echo 'accept recovery: tasks match neither prepared before nor after; reconcile concurrent edits' >&2; return 3; fi
  done
  if vf_return_check "$spec" "$task" "$return_file" "$tmp/meta.nul" > "$tmp/validation.log" 2>&1; then rc=0; else rc=$?; fi
  if (( rc )); then
    reason="$(cat "$tmp/validation.log")"
    vf_accept_audit "$spec" "$task" "$ret" rejected "$reason" "$before" "$(vf_hash "$tasks")" || return 3
    printf 'accept rejected: %s %s\n' "$task" "$reason" | head -c "$VF_FAILURE_BYTES"
    return 3
  fi
  vf_meta_load "$tmp/meta.nul" 'version task return_digest binding_digest input captures manual' || return 3
  evidence="$(vf_meta_get captures) verified by spec-gate accept; return sha256:$ret"
  # Idempotence needs current validation and a receipt for this exact return.
  for old in "$spec/notes/verification/accepted/$task"/ACC-*; do
    [[ -d "$old" && -f "$old/COMMITTED" ]] || continue
    vf_integrity "$old" meta.nul return.txt tasks.after digests.nul || return 3
    if [[ "$(vf_hash "$old/return.txt")" == "$ret" ]] && grep -qE "^- \[x\] \*\*$task\*\*" "$tasks"; then
      vf_accept_audit "$spec" "$task" "$ret" already-accepted current "$before" "$before" || return 3
      printf 'accept already-accepted task=%s return=%s\n' "$task" "$ret"; return 0
    fi
  done
  cp "$return_file" "$tmp/return.txt" || return 3
  vf_tasks_rewrite "$tasks" "$task" x "$evidence" "$tmp/tasks.after" || return 3
  after="$(vf_hash "$tmp/tasks.after")" || return 3
  printf '%s\0' before "$before" after "$after" > "$tmp/digests.nul"
  rm "$tmp/validation.log"
  [[ "$before" == "$(vf_hash "$tasks")" ]] || { echo 'accept: task file changed concurrently' >&2; return 3; }
  vf_seal "$tmp" meta.nul return.txt tasks.after digests.nul || return 3
  old="${tmp%/*}/ACC-${tmp##*.}"
  vf_publish "$tmp" "$old" meta.nul return.txt tasks.after digests.nul || return 3
  VF_STAGING=''
  prepared="$(mktemp "$spec/.tasks.accept.XXXXXX")" || return 3
  cp "$old/tasks.after" "$prepared" && mv "$prepared" "$tasks" || return 3
  printf '%s\n' "$(vf_hash "$old/COMPLETE")" > "$old/COMMITTED"
  vf_accept_audit "$spec" "$task" "$ret" accepted current "$before" "$after" || return 3
  printf 'accept accepted task=%s return=%s\n' "$task" "$ret"
}
# Read-only worktree resolution. Never create or fall back to a base checkout.
vf_gate_roots() {
  local spec="$1" output="$2" repo declared name path branch wt count expected
  : > "$output"
  declared="$(spec_declared_repos "$spec")"
  if [[ -z "$declared" ]]; then
    repo="$(git -C "$spec" rev-parse --show-toplevel 2>/dev/null)" || return 3
    repo="$(cd "$repo" && pwd -P)" || return 3
    expected="$(fm_get "$spec/STATUS.md" worktree 2>/dev/null || :)"
    if [[ -n "$expected" && "$expected" != none ]]; then
      [[ -d "$expected" && "$(cd "$expected" && pwd -P)" == "$repo" ]] || { echo 'gate worktree mismatch: reconcile STATUS worktree' >&2; return 3; }
    fi
    branch="$(fm_get "$spec/STATUS.md" branch 2>/dev/null || :)"
    if [[ -n "$branch" && "$branch" != none ]]; then
      [[ "$(git -C "$repo" symbolic-ref --quiet --short HEAD)" == "$branch" ]] || { echo 'gate branch mismatch' >&2; return 3; }
    fi
    printf '%s\0' "$repo" > "$output"
  else
    for name in $declared; do
      path="$(bash "$HUB_DIR/scripts/system-map.sh" path "$name")" || return 3
      branch="refs/heads/spec/$(basename "$spec")"
      wt="$(git -C "$path" worktree list --porcelain | awk -v branch="$branch" '/^worktree / {p=substr($0,10)} /^branch / && substr($0,8)==branch {print p}')" || return 3
      count="$(printf '%s\n' "$wt" | awk 'NF {n++} END {print n+0}')"
      [[ "$count" == 1 && -d "$wt" ]] || { echo "gate worktree missing/ambiguous for $name" >&2; return 3; }
      printf '%s\0' "$(cd "$wt" && pwd -P)" >> "$output"
    done
  fi
}
vf_gate_snapshot() (
  local spec="$1" roots="$2" out="$3" repo tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/vf-gate-inputs.XXXXXX")" || return 3
  trap 'rm -f "$tmp"' EXIT
  : > "$out"
  while IFS= read -r -d '' repo; do
    vf_snapshot "$spec" "$repo" "$repo" "$tmp" >/dev/null || return 3
    cat "$tmp" >> "$out"
  done < "$roots"
  vf_hash "$out"
)

# All invocations revalidate artifacts; T023 enables previous-invocation reuse.
VF_REUSE_ENABLED=0
vf_gate_execute() { # spec catalog repo policy commands-file kind -- argv...
  local spec="$1" catalog="$2" repo="$3" policy="$4" records="$5" kind="$6"; shift 6
  [[ "$1" == -- ]] || return 2; shift
  local tmp dir cap='' cached=0 rc=0 argv
  tmp="$(mktemp -d "$spec/notes/verification/execute.XXXXXX")" || return 3
  printf '%s\0' "$@" > "$tmp/argv"
  vf_snapshot "$spec" "$repo" "$repo" "$tmp/inputs" >/dev/null || { rm -rf "$tmp"; return 3; }
  # Reuse only exact argv + cwd + inputs and explicit local policy. Captures
  # made in this invocation can serve duplicate commands after current checks.
  if [[ "$policy" == local ]]; then
    for dir in "$spec"/notes/captures/CAP-*; do
      [[ -d "$dir" ]] || continue
      cmp -s "$tmp/argv" "$dir/argv.nul" && cmp -s "$catalog" "$dir/bindings.nul" || continue
      if (( ! VF_REUSE_ENABLED )); then
        grep -Fx "${dir##*/}" "$VF_GATE_FRESH" >/dev/null || continue
      fi
      if vf_capture_check "$spec" "${dir##*/}" "$tmp/inputs" reuse >/dev/null 2>&1; then cap="${dir##*/}"; cached=1; fi
    done
  fi
  if [[ -z "$cap" ]]; then
    VF_NO_TICK=1
    vf_capture "$spec" "$catalog" "$repo" "$policy" -- "$@" || rc=$?
    cap="${VF_CAPTURE_ID:-}"
    [[ -n "$cap" ]] || { rm -rf "$tmp"; return "${rc:-3}"; }
    printf '%s\n' "$cap" >> "$VF_GATE_FRESH"
  fi
  printf -v argv '%s ' "$@"
  printf '%s\0' "$kind" "$repo" "$repo" "$argv" "$cap" "$cached" >> "$records"
  if (( rc )); then vf_summary "$spec/notes/captures/$cap" failure; rm -rf "$tmp"; return "$rc"; fi
  vf_capture_check "$spec" "$cap" "$tmp/inputs" current || { rm -rf "$tmp"; return 3; }
  rm -rf "$tmp"
}

vf_gate_task_repo() { # spec task roots -> physical root
  local spec="$1" task="$2" roots="$3" name path branch wt
  name="$(bash "$HUB_DIR/scripts/spec-task.sh" show "$spec" "$task" | head -1 | sed -n 's/.*\[repo:\([^]]*\)\].*/\1/p')"
  if [[ -n "$name" ]]; then
    path="$(bash "$HUB_DIR/scripts/system-map.sh" path "$name")" || return 3
    branch="refs/heads/spec/$(basename "$spec")"
    wt="$(git -C "$path" worktree list --porcelain | awk -v branch="$branch" '/^worktree / {p=substr($0,10)} /^branch / && substr($0,8)==branch {print p}')" || return 3
    [[ -d "$wt" ]] || return 3
    printf '%s\n' "$(cd "$wt" && pwd -P)"
  else IFS= read -r -d '' path < "$roots"; printf '%s\n' "$path"; fi
}

# Current floor: refresh exact completed-task checks, execute mandatory checks,
# then seal current command/result identities. No model verdict is inferred.
vf_gate_floor() {
  local spec="$1" tmp repo task state stage subject source after root_index=0 kind command check_stage policy v id final start records
  spec="$(cd "$spec" && pwd -P)" || return 3
  mkdir -p "$spec/notes/verification/floors" || return 3
  tmp="$(mktemp -d "$spec/notes/verification/floors/.floor.XXXXXX")" || return 3
  records="$tmp/commands.nul"; : > "$records"
  VF_GATE_FRESH="$tmp/fresh"; : > "$VF_GATE_FRESH"
  vf_gate_roots "$spec" "$tmp/roots.nul" || return 3
  vf_binding_snapshot "$spec" "$tmp/bindings.nul" || return 3
  source="$(vf_gate_snapshot "$spec" "$tmp/roots.nul" "$tmp/inputs.nul")" || return 3
  start="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # Configuration gaps are fatal even for a legacy spec. A no-op is no floor.
  while IFS= read -r -d '' repo; do
    vf_config "$repo/.specify/stack.yml" "$spec/tasks.md" "$tmp/config-$root_index" || return 3
    vf_meta_load "$tmp/config-$root_index/meta.nul" 'version gate_count stage_validation' || return 3
    [[ "$(vf_meta_get gate_count)" -gt 0 ]] || { echo "floor gap: missing nonempty gate_checks in $repo/.specify/stack.yml" >&2; return 3; }
    root_index=$((root_index+1))
  done < "$tmp/roots.nul"
  while IFS=$'\t' read -r task state stage subject; do
    [[ "$state" == "done" ]] || continue
    vf_task_info "$tmp/bindings.nul" "$task" >/dev/null 2>&1 || continue
    if [[ "${VF_TASK[5]}" == manual ]]; then
      vf_manual_current "$spec" "$task" || return 3
      continue
    fi
    repo="$(vf_gate_task_repo "$spec" "$task" "$tmp/roots.nul")" || return 3
    vf_gate_execute "$spec" "$tmp/bindings.nul" "$repo" "${VF_TASK[10]}" "$records" "task:$task" -- "$(command -v bash)" -o pipefail -c "$VF_TASK_COMMAND" || return $?
  done < <(bash "$HUB_DIR/scripts/spec-task.sh" list "$spec")
  IFS= read -r -d '' repo < "$tmp/roots.nul"
  for command in sdd-analyze spec-ac-coverage spec-evidence; do
    # AC coverage receives the actual existing worktrees, including umbrellas.
    local args=("$(command -v bash)" "$HUB_DIR/scripts/$command.sh" "$spec")
    if [[ "$command" == spec-ac-coverage ]]; then while IFS= read -r -d '' v; do args+=(--root "$v"); done < "$tmp/roots.nul"; fi
    vf_gate_execute "$spec" "$tmp/bindings.nul" "$repo" never "$records" "checker:$command" -- "${args[@]}" || return $?
  done
  root_index=0
  while IFS= read -r -d '' repo; do
    while IFS= read -r -d '' kind && IFS= read -r -d '' check_stage && IFS= read -r -d '' command; do
      [[ "$kind" == gate_checks ]] || continue
      policy=never
      while IFS= read -r -d '' v; do [[ "$v" != "$command" ]] || policy=local; done < "$tmp/config-$root_index/reuse.nul"
      vf_gate_execute "$spec" "$tmp/bindings.nul" "$repo" "$policy" "$records" gate_check -- "$(command -v bash)" -o pipefail -c "$command" || return $?
    done < "$tmp/config-$root_index/commands.nul"
    root_index=$((root_index+1))
  done < "$tmp/roots.nul"
  after="$(vf_gate_snapshot "$spec" "$tmp/roots.nul" "$tmp/after")" || return 3
  [[ "$source" == "$after" ]] || { echo 'floor stale: source inputs changed during verification' >&2; return 3; }
  id="FLOOR-${tmp##*.}"
  printf '%s\0' version 1 id "$id" kind floor stage '' start "$start" end "$(date -u +%Y-%m-%dT%H:%M:%SZ)" source "$source" exit 0 > "$tmp/meta.nul"
  vf_lock "$spec" || return 3
  vf_seal "$tmp" meta.nul commands.nul bindings.nul inputs.nul roots.nul || return 3
  final="${tmp%/*}/$id"
  vf_publish "$tmp" "$final" meta.nul commands.nul bindings.nul inputs.nul roots.nul || return 3
  printf '%s\n' "$id" > "$spec/notes/verification/floor-latest.tmp" && mv "$spec/notes/verification/floor-latest.tmp" "$spec/notes/verification/floor-latest" || return 3
  printf '\n## GATE-FLOOR\n\nResult: %s; source: %s; exit: 0; command records: `notes/verification/floors/%s/commands.nul`.\n' "$id" "$source" "$id" >> "$spec/notes/evidence.md"
  vf_unlock
  vf_gate_result_summary "$final"
}
vf_gate_result_summary() {
  local dir="$1" v f=() executed=0 reused=0
  vf_meta_load "$dir/meta.nul" 'version id kind stage start end source exit' || return 3
  while IFS= read -r -d '' v; do
    f+=("$v"); (( ${#f[@]} == 6 )) || continue
    if [[ "${f[5]}" == 1 ]]; then reused=$((reused+1)); else executed=$((executed+1)); fi
    f=()
  done < "$dir/commands.nul"
  printf 'result=%s source=%s exit=%s executed=%s cache-hits=%s records=%s/commands.nul\n' "$(vf_meta_get id)" "$(vf_meta_get source)" "$(vf_meta_get exit)" "$executed" "$reused" "$dir" | head -c "$VF_SUCCESS_BYTES"
}

vf_floor_validate() (
  local spec="$1" id="$2" dir tmp source v f=() repo
  [[ "$id" =~ ^FLOOR-[A-Za-z0-9]+$ ]] || { echo 'floor identity invalid' >&2; return 3; }
  dir="$spec/notes/verification/floors/$id"
  vf_integrity "$dir" meta.nul commands.nul bindings.nul inputs.nul roots.nul || return 3
  vf_meta_load "$dir/meta.nul" 'version id kind stage start end source exit' || return 3
  [[ "$(vf_meta_get exit)" == 0 && "$(vf_meta_get id)" == "$id" ]] || return 3
  source="$(vf_meta_get source)"
  tmp="$(mktemp -d "$spec/notes/verification/floor-check.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_gate_roots "$spec" "$tmp/roots" || return 3
  cmp -s "$tmp/roots" "$dir/roots.nul" || return 3
  [[ "$source" == "$(vf_gate_snapshot "$spec" "$tmp/roots" "$tmp/inputs")" ]] || { echo 'floor stale: refresh floor for current inputs' >&2; return 3; }
  while IFS= read -r -d '' v; do
    f+=("$v"); (( ${#f[@]} == 6 )) || continue
    repo="${f[1]}"
    vf_snapshot "$spec" "$repo" "$repo" "$tmp/repo-inputs" >/dev/null || return 3
    vf_capture_check "$spec" "${f[4]}" "$tmp/repo-inputs" current || return 3
    f=()
  done < "$dir/commands.nul"
  printf '%s\n' "$source"
)

vf_manual_current() (
  local spec="$1" task="$2" receipt tmp found=0
  tmp="$(mktemp "$spec/notes/verification/manual.XXXXXX")" || return 3
  trap 'rm -f "$tmp"' EXIT
  for receipt in "$spec/notes/verification/accepted/$task"/ACC-*; do
    [[ -f "$receipt/COMMITTED" ]] || continue
    vf_integrity "$receipt" meta.nul return.txt tasks.after digests.nul || return 3
    if vf_return_check "$spec" "$task" "$receipt/return.txt" "$tmp" >/dev/null 2>&1; then found=1; fi
  done
  (( found )) || { echo "manual evidence gap: $task needs current artifact-backed acceptance" >&2; return 3; }
)
