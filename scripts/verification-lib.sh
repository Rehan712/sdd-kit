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
# The gates that exist, in one place. Every check that has to decide whether a
# value NAMES A GATE reads this rather than restating the pair, so no guard can
# fall out of step with the gates the CLI accepts.
VF_GATES='opponent reality-check'
vf_is_gate() { case " $VF_GATES " in *" $1 "*) return 0;; esac; return 1; }

# _VF_AWK_FENCE — the ONE fence tracker every parser shares. Quoted content is
# a record, never an instruction: a waiver reproduced inside a code fence or a
# blockquote must lift nothing, a `## Round` heading quoted in a capture must
# not add a round, and a `|` table row inside an example must not define a row.
#
# A single toggled boolean is not enough (O-002, round-authorization-grammar):
# CommonMark closes a fenced block only with a run of the SAME character that is
# at least as long as the opener, carrying no info string. A nested shorter or
# other-character run is content. The old toggle treated every run as a switch,
# so an inner ``` inside an outer ```` (or inside ~~~) turned suppression OFF
# and exposed the quoted text. This tracker keeps the opener's character and
# width, so only a real closer reopens parsing; anything it cannot prove closed
# keeps suppressing, which is the deny-side error.
#
# The same derivation governs raw HTML: see vf_raw_start below, which takes its
# suppressed set from the CommonMark HTML-block conditions instead of a list of
# tag names, so closing it also closes the <!DOCTYPE / <? / <![CDATA[ residual.
#
# Callers prepend it to their awk program and call vf_fence($0) on every line:
# it returns 1 when the line is itself a fence marker (the caller may `next`)
# and leaves the global `fenced` holding the state for the lines that follow.
# Indentation of four or more columns is content, not a fence, exactly as
# CommonMark has it — otherwise an indented ``` inside a block would close it.
_VF_AWK_FENCE='
function vf_fence(s,   t, ind, ch, n, rest) {
  if (vf_bt == "") vf_bt = sprintf("%c", 96)
  ind = match(s, /[^ ]/)
  if (ind == 0 || ind > 4) return 0
  t = substr(s, ind)
  ch = substr(t, 1, 1)
  if (ch != vf_bt && ch != "~") return 0
  n = 0
  while (substr(t, n + 1, 1) == ch) n++
  if (n < 3) return 0
  if (!fenced) { fenced = 1; vf_fence_ch = ch; vf_fence_n = n; return 1 }
  if (ch != vf_fence_ch || n < vf_fence_n) return 0
  rest = substr(t, n + 1); sub(/[ \t]*$/, "", rest)
  if (rest != "") return 0
  fenced = 0
  return 1
}
function vf_indented(s,   ind) {
  ind = match(s, /[^ ]/)
  if (ind == 0 || ind > 4) return 1
  return (substr(s, ind, 1) == "\t")
}
function vf_code_close(s, start, width,   j, run, n) {
  n = length(s); j = start
  while (j <= n) {
    if (substr(s, j, 1) != vf_bt) { j++; continue }
    run = 0
    while (substr(s, j + run, 1) == vf_bt) run++
    if (run == width) return j
    j += run
  }
  return 0
}
function vf_comment(s,   ind, i, n, run, end_at, line_quoted, started) {
  if (vf_bt == "") vf_bt = sprintf("%c", 96)
  started = commented
  if (!commented && index(s, "<!--") == 0) return 0
  if (!commented && s ~ /^[ ]*<!--[ ]*gate-round-end:[ ]*[a-z][a-z-]*:[0-9][0-9]*[ ]*-->[ ]*$/) return 0
  # Four or more columns of indentation is an indented code block, exactly as
  # vf_fence already treats it. Such an opener is literal text every reader
  # sees, so honouring it as a marker let a visible finding be swallowed.
  if (!commented) {
    ind = match(s, /[^ ]/)
    if (ind == 0 || ind > 4 || substr(s, ind, 1) == "\t") return 0
  }
  # Walk every transition on the line. Outside a comment, matched code spans
  # suppress comment tokens. Inside a comment, backticks are raw bytes and the
  # next closer wins. Stopping after the first opener/closer made
  # `<!-- first --> <!-- second` end in the wrong state, and a closer followed
  # by a new opener had the reciprocal bug.
  i = 1; n = length(s); line_quoted = started
  while (i <= n) {
    if (commented) {
      end_at = index(substr(s, i), "-->")
      if (!end_at) break
      commented = 0; i += end_at + 2; continue
    }
    if (substr(s, i, 1) == vf_bt) {
      run = 0
      while (substr(s, i + run, 1) == vf_bt) run++
      # A code span closes only on a backtick run exactly as long as its
      # opener. A shorter/longer run is content, and an unmatched run is
      # literal text. The old boolean toggle made a visible comment opener
      # disappear after an unmatched delimiter and exposed one nested inside
      # a wider code span.
      end_at = vf_code_close(s, i + run, run)
      if (end_at) { i = end_at + run; continue }
      i += run; continue
    }
    if (substr(s, i, 4) == "<!--") {
      if (substr(s, 1, i - 1) ~ /^[ ]*$/) line_quoted = 1
      commented = 1; i += 4; continue
    }
    i++
  }
  return line_quoted
}
# CommonMark 0.31.2 section 4.6 defines seven HTML-block start conditions. The
# suppressed set is DERIVED from them rather than enumerated, because four
# rounds of O-002 showed that a list of spellings is satisfiable while the class
# stays open: fences, then HTML comments, then indented openers, then condition
# 1 raw HTML each survived a repair written against the previous report.
#
# Conditions 1, 3, 4 and 5 suppress. Two independent reasons agree, and both
# matter: <script> and <style> content is rendered by no browser and is deleted
# outright by the GitHub sanitizer, so honouring it would let a line NO READER CAN
# SEE lift the round cap; <pre> and <textarea> content is literal quoted text,
# which is the same record-not-instruction property a fence has. <? ?>, <!NAME >
# and <![CDATA[ ]]> render nothing either. Conditions 6 and 7 — block-level and
# complete-tag HTML, <details> included — deliberately do NOT suppress: their
# content is rendered prose a reader sees, which is the property the contract
# names as the line between a record and a hidden instruction.
#
# vf_raw_start takes the leading content of the line, so an opener in a matched
# inline code span is literal (the same rule comments follow) and a mid-line
# <script> starts no block, exactly as CommonMark has it.
function vf_raw_start(t,   low, tag) {
  low = tolower(t)
  if (match(low, /^<(script|style|textarea|pre)([ \t>]|$)/)) {
    tag = substr(low, 2, RLENGTH - 1)
    sub(/[ \t>].*$/, "", tag)
    return tag
  }
  if (substr(t, 1, 2) == "<?") return 3
  if (substr(t, 1, 9) == "<![CDATA[") return 5
  if (t ~ /^<![A-Za-z]/) return 4
  return 0
}
function vf_raw_end(s, kind,   low) {
  low = tolower(s)
  if (kind ~ /^(script|style|textarea|pre)$/) return (index(low, "</" kind ">") > 0)
  if (kind == 3) return (index(s, "?>") > 0)
  if (kind == 4) return (index(s, ">") > 0)
  if (kind == 5) return (index(s, "]]>") > 0)
  return 1
}
function vf_quoted(s,   ind, t, k) {
  # An unclosed raw-HTML block keeps suppressing, which denies: same deny-side
  # error the fence and comment trackers already make.
  if (rawkind) { if (vf_raw_end(s, rawkind)) rawkind = 0; return 1 }
  if (commented) return vf_comment(s)
  if (vf_fence(s)) return 1
  if (fenced) return 1
  if (s ~ /^[ ]*>/) return 1
  ind = match(s, /[^ ]/)
  if (ind > 0 && ind <= 4 && substr(s, ind, 1) != "\t") {
    t = substr(s, ind)
    k = vf_raw_start(t)
    if (k) { if (!vf_raw_end(t, k)) rawkind = k; return 1 }
  }
  return vf_comment(s)
}
'

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
    awk "$_VF_AWK_FENCE"'
      vf_quoted($0) { next }
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
      # A reused check identity records the command string, never what the
      # shell substituted into it, so the enforced set is the syntactic forms
      # that splice a value at execution time: parameter expansion including
      # the positional and special parameters, ALL THREE spellings of command
      # substitution -- $(...), backticks and process substitution <(...)
      # / >(...) -- and word-initial tilde. This is what is enforced, not a
      # claim that every semantically time-dependent command is caught: a
      # pipeline that greps the output of date is accepted and always will be,
      # which is why an external or clock-dependent check must stay off the
      # reuse opt-in. A dollar before a quote or a regex operator is a
      # literal end-anchor and stays legal, and brace expansion stays legal
      # because it is deterministic.
      if (out ~ /\$[({A-Za-z_0-9?!*@#$-]/) { error("interpolation is unsupported"); return "" }
      if (index(out,tick)) { error("command substitution is unsupported") ; return "" }
      if (index(out,"<(") || index(out,">(")) { error("command substitution is unsupported") ; return "" }
      if (out ~ /(^|[ \t])~/) { error("tilde expansion is unsupported"); return "" }
      scalar_ok=1; return out
    }
    BEGIN {
      dir=ENVIRON["VF_CONFIG_OUT"]; quote=sprintf("%c",39); tick=sprintf("%c",96)
      while ((getline stage < ENVIRON["VF_CONFIG_STAGES"])>0) { stages[stage]=1; stage_count++ }
      close(ENVIRON["VF_CONFIG_STAGES"])
      files[1]="commands.nul"; files[2]="reuse.nul"; files[3]="tools.nul"
      files[4]="inputs.nul"; files[5]="stages.nul"; files[6]="meta.nul"
      files[7]="environment.nul"
      for (i=1;i<=7;i++) printf "%s","" > (dir "/" files[i])
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
            key=="verification_inputs" || key=="verification_environment" || key=="checkpoints") {
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
      else if (context=="verification_environment") {
        if (value !~ /^[A-Za-z_][A-Za-z0-9_]*$/) { error("verification_environment needs a variable name"); next }
        emit("environment.nul",value)
      }
      else emit("inputs.nul",value)
    }
    END {
      emit("meta.nul","version"); emit("meta.nul","1")
      emit("meta.nul","gate_count"); emit("meta.nul",gate_count+0)
      emit("meta.nul","stage_validation"); emit("meta.nul",stage_count ? "checked" : "deferred")
      for (i=1;i<=7;i++) if (close(dir "/" files[i])!=0) errors++
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
      -v specacs=" $(grep -oE 'AC-[0-9]{3}' "$spec" | sort -u | tr '\n' ' ')" \
      "$_VF_AWK_FENCE"'
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
    /^Exclusions:[[:space:]]*/ {
      exclusions=1; v=$0; sub(/^Exclusions:[[:space:]]*/,"",v)
      if (placeholder(v)) diag("warning", "plan Exclusions entry is blank or placeholder")
    }
    vf_quoted($0) { next }
    $0 !~ /^[[:space:]]*\|/ || vf_indented($0) {
      if (in_table) { in_table=0; section="" }
    }
    !vf_indented($0) && /^[[:space:]]*\|/ {
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
    awk -v OFS="$us" "$_VF_AWK_FENCE"'
      vf_quoted($0) { next }
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
        -v specreqs=" $(grep -oE 'REQ-[0-9]{3}' "$spec" | sort -u | tr '\n' ' ')" \
        "$_VF_AWK_FENCE"'
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
      function parse_tests(raw,kind,refs,files,    a,n,i,loc,j,matched,relevant,file,defid,k,bound,owned_any,ref,refn,refs_array,covered) {
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
        # A matching FM or one overlapping AC must not conceal another
        # criterion omitted from the declared coverage of all selected families.
        refn=split(refs,refs_array,/,/)
        for(k=1;k<=refn;k++) {
          ref=trim(refs_array[k]); if(ref !~ /^AC-[0-9][0-9][0-9]$/) continue
          covered=0
          for(i=1;i<=task_locn;i++) for(j=1;j<=family_n;j++)
            if(family_loc[j]==task_loc[i] && family_kind[j]==kind && criteria_overlap(family_criteria[j],ref)) covered=1
          if(!covered) diag("warning","task " id " " ref " has no declared test-family binding")
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
      vf_quoted($0) { next }
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
vf_hash() (
  set -o pipefail
  local digest
  if command -v shasum >/dev/null 2>&1; then digest="$(shasum -a 256 < "$1" | awk '{print $1}')" || return 3
  elif command -v sha256sum >/dev/null 2>&1; then digest="$(sha256sum < "$1" | awk '{print $1}')" || return 3
  else echo 'verification prerequisite: SHA-256 unavailable' >&2; return 3; fi
  [[ "$digest" =~ ^[a-f0-9]{64}$ ]] || { echo 'verification prerequisite: invalid SHA-256 result' >&2; return 3; }
  printf '%s\n' "$digest"
)

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
  local file="$1" gate="$2" output="$3" spec="${4:-}" tmp manifest priorids=' '
  tmp="$(mktemp "${output}.XXXXXX")" || return 3
  trap 'rm -f "$tmp"' EXIT
  [[ -e "$file" ]] || { : > "$output"; return 0; }
  _vf_reject_nul "$file" "$file" || return 3
  # A resolved finding claims a defect already reported. Earlier rounds of this
  # gate are the normal source; a gate's FIRST round can only reference review
  # that happened before any round existed, so a declared prior-review manifest
  # named <gate>-findings-<label>.md beside the canonical reports also counts.
  # The canonical report and its copies are deliberately NOT a source: a report
  # that vouched for its own IDs would validate anything it asserted.
  #
  # The manifest is located from the SPEC, never from the report's own path.
  # `round --complete` validates a temporary combined.md under
  # notes/verification/round-check.XXXX/, so deriving the directory from the
  # file silently loses the manifest exactly when a round is being sealed —
  # which refused a completed round whose only resolved finding was legitimate.
  [[ -n "$spec" ]] || spec="$(dirname "$file")/.."
  for manifest in "$spec/notes/verification/reports/$gate-findings-"*.md; do
    [[ -f "$manifest" ]] || continue
    _vf_reject_nul "$manifest" "$manifest" || return 3
    priorids="$priorids$(awk "$_VF_AWK_FENCE"'
      function flushm() {if(id!="" && cls!="") print id ":" cls ":" sev; id=""; cls=""; sev=""}
      vf_quoted($0) {next}
      /^#+ Finding [A-Z][A-Z0-9]*-[0-9]+[[:space:]]*$/ {flushm(); id=$NF; next}
      id != "" && /^-[[:space:]]+\*\*Class:\*\*/ {
        cls=$0; sub(/^.*\*\*Class:\*\*[[:space:]]*/, "", cls)
        gsub(/[[:space:]]/, "", cls)
      }
      id != "" && /^-[[:space:]]+\*\*Severity:\*\*/ {
        sev=$0; sub(/^.*\*\*Severity:\*\*[[:space:]]*/, "", sev)
        gsub(/[[:space:]]/, "", sev)
      }
      END {flushm()}
    ' "$manifest" | sort -u | tr '\n' ' ')"
  done
  VF_REPORT_FILE="$file" awk -v gate="$gate" -v priorids="$priorids" "$_VF_AWK_FENCE"'
    function err(s) {print "report recovery: " ENVIRON["VF_REPORT_FILE"] ":" NR ": " s "; reconcile canonical records" > "/dev/stderr"; bad=1}
    function clean(s) {gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s}
    function value(s) {sub(/^.*\*\*[^*]+:\*\*[ ]*/, "", s); return clean(s)}
    function emit(a,b,c,d,e,f,g,h,i,j,k,l) {printf "%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c",a,0,b,0,c,0,d,0,e,0,f,0,g,0,h,0,i,0,j,0,k,0,l,0}
    BEGIN {
      manifestn=split(priorids, manifestrecords, /[ ]+/)
      for(manifesti=1; manifesti<=manifestn; manifesti++) {
        if(manifestrecords[manifesti]=="") continue
        split(manifestrecords[manifesti], manifestfields, ":")
        manifestid=manifestfields[1]; manifestclass=manifestfields[2]; manifestsev=manifestfields[3]
        if(manifestid=="" || manifestclass=="") continue
        if((manifestid in firstclass) && firstclass[manifestid]!=manifestclass)
          manifestconflict[manifestid]=1
        else firstclass[manifestid]=manifestclass
        # sort -u orders manifest records lexically, not by observation, so the
        # STRICTEST recorded tier wins rather than the first one read. Sticky
        # blocking is the deny-side error, same direction as every other guard.
        if(manifestsev!="") {
          manifesttier=(manifestsev ~ /^(minor|degraded)$/) ? "minor" : "blocking"
          if(!(manifestid in firsttier) || manifesttier=="blocking") firsttier[manifestid]=manifesttier
        }
        manifestseen[manifestid]=1
      }
    }
    function finding() {
      if (!fid) return
      if (style=="canonical") {
        if (fid !~ /^[A-Z][A-Z0-9]*-[0-9]+$/ || cls !~ /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/ || status !~ /^(new|open|resolved|reopened)$/ || prior=="" || root !~ /^(plan-gap|spec-gap|implementation-error)$/ || trigger=="" || repro=="" || loc !~ /[^ ]+:[0-9]+/ || wrong=="" || fix=="") err("incomplete finding " fid)
        if (sev !~ /^(data-loss|wrong-result|regression|crash|minor|degraded)$/) err("unknown severity")
        if (seenfinding[n SUBSEP fid]++) err("duplicate finding ID")
        # Finding IDs name stable subjects across the whole gate history. A
        # copied historical ID cannot be reused for a new blocker by changing
        # its author-controlled Class and marking the new subject resolved.
        if (manifestconflict[fid]) err("prior-review finding " fid " has conflicting Class definitions")
        if ((fid in firstclass) && firstclass[fid] != cls)
          err("finding " fid " changes Class from " firstclass[fid] " to " cls)
        # Resolved is a claim about a finding that already existed, and a
        # resolved finding is not counted, so a brand-new blocking defect could
        # otherwise be recorded in full and tallied as zero. The claim has to
        # be checked for EXISTENCE of THIS finding, not shape and not the
        # existence of some other finding: a well-formed invented ID paired
        # with a real Prior is exactly the attack. Accept it when this ID was
        # seen in an earlier round of this gate (the documented
        # new/open/resolved/reopened lifecycle keeps one ID and needs no
        # Prior), or when this ID appears in a declared prior-review manifest.
        if (status=="resolved" && !((fid in lastseen) && (lastseen[fid]+0) < (n+0)) && !(fid in manifestseen))
          err("resolved finding " fid " has no earlier round of this gate and no declared prior-review record")
        if (status!="resolved") {if (sev ~ /^(minor|degraded)$/) minors++; else blockers++}
        # Round 5 bound Class, which the tally never reads. The tokens the count
        # and the verdict DO read are Status and Severity, and Severity stayed
        # free to drop a tier for an ID the gate already knows, so a still-open
        # data-loss defect could be tallied as a minor and let CLEARED through
        # on blockers==0. Binding the tier outright is the wrong rule: round 6
        # itself records O-002 at degraded after five rounds at wrong-result,
        # an honest re-characterisation of the next member of a class. So the
        # guard binds where the ATTACK lands instead - a clearing verdict may
        # not rest on a downgrade - and a non-clearing round may re-characterise.
        # The predicate itself is evaluated once, after this block (O-014).
        # Round 6 bound Severity, the SECOND token of the predicate on the line
        # above, and wrote status!="resolved" into the guard on the line below
        # as an explicit exemption - so the token that suppresses the count is
        # the token the new guard declines to inspect, one line apart in the
        # same statement. Extent is derived from that predicate rather than
        # from the field a report named: `Status` and `Severity` are the only
        # two inputs to the count, and the count is the only input to the
        # clearance check in flush(). Severity is bindable to history because
        # the gate has seen the ID before; `Status: resolved` is NOT - it
        # asserts a repair that no data available to this validator can
        # corroborate. So the suppression may not be worth a clearing verdict.
        # "Rests on" is read off the predicate too: an observation rests on the
        # suppression exactly when the ROUND record of this gate already counted
        # that ID, which is a history the report making the claim cannot
        # rewrite. A declared prior-review manifest is not a round and was
        # never counted, so a first round may still resolve a manifest-recorded
        # finding and clear - the shape the real round 1 O-006 has.
        if (status=="resolved" && (fid in openround))
          suppressed = suppressed (suppressed=="" ? "" : ", ") fid
      }
      # One computation, two readers (O-014). A lowered tier is judged here,
      # once per observation of every round style, against the history both
      # writers below and the manifest pass share. flush() refuses a clearing
      # verdict that rests on it; vf_tally counts the emitted records. A second
      # fold inside the tally is how the metric lost the manifest seed.
      lowered = ((fid in firsttier) && firsttier[fid]=="blocking" && sev ~ /^(minor|degraded)$/ && status!="resolved")
      if (lowered) downgraded++
      emit("finding",n,fid,cls,status,prior,sev,loc,root,trigger,repro,blocks)
      if (lowered) emit("downgrade",n,fid,cls,status,prior,sev,"","","","","")
      if (!(fid in firstclass)) firstclass[fid]=cls
      # Fold every observation, just like the manifest writer: an escalation
      # must remain history when a later round walks the same ID back down.
      if (!(fid in firsttier) || sev !~ /^(minor|degraded)$/) firsttier[fid]=(sev ~ /^(minor|degraded)$/) ? "minor" : "blocking"
      if (status!="resolved") openround[fid]=n
      lastseen[fid]=n
      fid=cls=status=prior=sev=loc=root=trigger=repro=blocks=wrong=fix=""
    }
    # A canonical round must carry the required record for its gate, not only
    # identity fields: clearance without the attack/scope sections is exactly
    # the review contract this validator exists to enforce.
    # A resolved claim is bound to the SUBJECT it claims, which is the finding
    # own ID — never to a label the author of the finding also writes.
    # Requiring Prior to name a prior finding (round 2), then one of the same
    # recorded Class (round 3), each bound the claim to something the report
    # controls: the attack only had to copy one more token printed in the same
    # file. The different-ID Prior branch is therefore gone, not narrowed.
    #
    # Dropping it loses no legitimate record. The only cross-manifest
    # resolution in this repository is round 1 O-006, whose Prior is its OWN
    # id, and that is accepted here by the manifest lookup on fid.
    function need(name) {
      if (!section[n SUBSEP name]) err("missing required report section: " name)
      else if (!secbody[n SUBSEP name]) err("empty required report section: " name)
    }
    # The verdicts that CLEAR their gate, named once. CLEARED and READY are the
    # only two values of the verdict field that end a gate; every other value
    # leaves it open, which is why a non-clearing round may still record a
    # resolution or re-characterise a tier.
    function clearing() {
      return (gate=="opponent" && verdict=="CLEARED") || (gate=="reality-check" && verdict=="READY")
    }
    function flush() {
      finding()
      if (!active) return
      if(style=="legacy" && gate=="reality-check" && declared=="" && n==1) declared=1
      if(n !~ /^[1-9][0-9]*$/ || length(n)>9 || n!=last+1 || declared!=n || !verdict || !date) err("missing, duplicate or nonsequential round identity")
      if(gate=="opponent" && verdict !~ /^(CLEARED|CHALLENGED|BLOCKED)$/) err("invalid opponent verdict")
      if(gate=="reality-check" && verdict !~ /^(READY|NEEDS WORK|FAILED)$/) err("invalid reality-check verdict")
      if(style=="canonical") {
        if (!ended || !utc || source !~ /^[a-f0-9]+$/ || length(source)!=64 || floor !~ /^FLOOR-[A-Za-z0-9.-]+$/) err("incomplete canonical identity")
        if (gate=="opponent") {need("what i attacked"); need("held up / follow-up tasks")}
        if (gate=="reality-check") {need("summary"); need("ac matrix"); need("constitution check"); need("re-run conditions")}
        if(gate=="opponent" && (!counted || blockers!=wantb || minors!=wantm)) err("finding totals disagree")
        if(gate=="opponent" && ((verdict=="CLEARED" && blockers) || (verdict=="CHALLENGED" && !blockers))) err("verdict disagrees with blocking findings")
        if(gate=="opponent" && verdict=="CLEARED" && downgraded) err("clearing verdict rests on " downgraded " lowered severity tier(s) of known findings")
        # Gate-neutral by derivation: clearing() names the clearing verdict of both
        # verdicts, because an uncorroborable suppression buys the same thing
        # on either side. The sibling checks above stay opponent-only because
        # they read the opponent-only totals line; that asymmetry is recorded
        # as the reality-check totals gap, not closed here.
        if(clearing() && suppressed!="") err("clearing verdict rests on resolved findings this gate recorded open: " suppressed)
      }
      emit("round",n,utc,source,floor,verdict,style,date,"","","","")
      last=n; active=0
    }
    vf_quoted($0) {
      # Quoting does not exempt a line from the after-marker rule: a fenced,
      # commented or blockquoted preamble is still content the accumulator
      # would attribute to the sealed round above it.
      if (ended && $0 !~ /^[ ]*$/) err("content after the round completion marker")
      next
    }
    /^## Round [1-9][0-9]*$/ {
      flush(); n=$3; active=1; style="canonical"; declared=date=verdict=utc=source=floor=cursec=suppressed=""; ended=counted=blockers=minors=downgraded=0; next
    }
    /^# (Opponent review|Reality Check)/ {
      if (ended) {err("content after the round completion marker"); next}
      if (!active) {n=last+1; active=1; style="legacy"; declared=date=verdict=utc=source=floor=suppressed=""; ended=counted=blockers=minors=downgraded=0}
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
      finding(); if($0!="<!-- gate-round-end: " gate ":" n " -->" || ended) err("completion marker mismatch"); ended=1; cursec=""; next
    }
    /^\*\*Blocking:\*\*/ {
      if (ended) {err("content after the round completion marker"); next}
      # Every per-round singleton must refuse a second occurrence rather than
      # let the last write win. The identity fields carry this guard; the
      # totals line did not, so a second totals line further down the round
      # silently replaced the one the reader sees above the findings.
      if(seenfield[n SUBSEP "**Blocking"]++) err("duplicate totals field")
      wantb=$2; wantm=$5; counted=1
      if(wantb !~ /^[0-9]+$/ || wantm !~ /^[0-9]+$/) err("malformed totals")
      next
    }
    /^### Finding / {finding(); if(!active || ended) err("finding outside round"); fid=$3; cursec=""; next}
    # Round, review and finding headings are consumed above, so what remains
    # here is a section heading. Level is not fixed by the templates.
    /^#+[ ]/ {
      heading=$0; sub(/^#+[ ]+/,"",heading); cursec=tolower(clean(heading))
      section[n SUBSEP cursec]=1
    }
    # A heading alone is not a record: require at least one non-blank, non-heading
    # line under it. Finding blocks and the completion marker close the section so
    # their own lines cannot be counted as another section body.
    cursec!="" && $0 !~ /^[[:space:]]*$/ && $0 !~ /^#+[ ]/ {secbody[n SUBSEP cursec]=1}
    style=="legacy" && /^[0-9]+\. .*severity:/ {
      finding(); fid="legacy-" n "-" ++legacyid; cls="unclassified"; status="new"; prior="none"
      sev=$0; sub(/^.*severity:\*[ ]*/,"",sev); sev=clean(sev); next
    }
    style=="legacy" && inwhere && !/^[ ]*- \*\*/ {loc=loc " " clean($0)}
    /^[ ]*- \*\*/ {inwhere=0}
    fid && /^[ ]*- \*\*(Class|Status|Prior|Severity|Where|Root cause|Scenario|Reproduced|Blocks|Wrong behavior|Class-wide fix):\*\*/ {
      key=$0; sub(/:\*\*.*/,"",key)
      if(seenfindingfield[n SUBSEP fid SUBSEP key]++) err("duplicate finding field")
      v=value($0)
      if($0 ~ /\*\*Class:/) cls=v
      if($0 ~ /\*\*Status:/) status=v
      if($0 ~ /\*\*Prior:/) prior=v
      if($0 ~ /\*\*Severity:/) sev=v
      if($0 ~ /\*\*Where:/) {loc=v; inwhere=1}
      if($0 ~ /\*\*Root cause:/) root=v
      if($0 ~ /\*\*Scenario:/) trigger=v
      if($0 ~ /\*\*Reproduced:/) repro=v
      if($0 ~ /\*\*Blocks:/) blocks=v
      if($0 ~ /\*\*Wrong behavior:/) wrong=v
      if($0 ~ /\*\*Class-wide fix:/) fix=v
    }
    # A completed round is sealed. vf_report_block attributes any stray line to
    # the preceding round, so content after the marker would silently change an
    # already sealed digest; refuse it here instead. Fenced and quoted lines are
    # skipped above, and legacy rounds never set ended.
    ended && $0 !~ /^[[:space:]]*$/ {err("content after the round completion marker")}
    END {flush(); if(!last) err("no recognized rounds"); if(fenced) err("unclosed code fence"); if(commented) err("unclosed HTML comment"); if(bad) exit 3}
  ' "$file" > "$tmp" || return 3
  local fields=() v
  while IFS= read -r -d '' v; do
    fields+=("$v")
    if (( ${#fields[@]} == 12 )); then
      if [[ "${fields[0]}" == round && "${fields[6]}" == canonical ]]; then
        vf_utc_valid "${fields[2]}" || { echo 'report recovery: invalid UTC calendar timestamp' >&2; return 3; }
      elif [[ "${fields[0]}" == round ]]; then
        vf_utc_valid "${fields[7]}T00:00:00Z" || { echo 'report recovery: invalid legacy date' >&2; return 3; }
      fi
      fields=()
    fi
  done < "$tmp"
  mv "$tmp" "$output"
)

vf_tally() (
  local spec="$1" tmp gate v f=() rounds blockers=0 minors=0 unclassified=0 locations=0 downgrades=0
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/vf-tally.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  : > "$tmp/classes"
  for gate in opponent reality-check; do
    vf_reports "$spec/notes/$gate.md" "$gate" "$tmp/report" "$spec" || return 3
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
          printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${f[3]}" "${f[2]}" "${f[4]}" "${f[5]}" "$gate" "${f[6]}" >> "$tmp/classes";;
        downgrade) downgrades=$((downgrades+1));;
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
  awk -F '\t' '{ids[$1 SUBSEP $2]=1; observations++; if($3=="reopened") reopened++}
    END {for(k in ids) distinct++; printf "finding-observations=%d distinct-finding-ids=%d reopened=%d\n", observations,distinct,reopened}' "$tmp/classes"
  # A severity downgrade is refused only where it buys a clearing verdict, so
  # honest re-characterisation stays legal -- which means it must not be
  # SILENT. Counting it here is the other half of that trade: MET-002 can see
  # how often a recorded tier moved down, which is the measurement REQ-011's
  # "severity never changes merely to meet a round or cost target" needs. The
  # count is the guard's own: vf_reports emits one downgrade record per
  # observation it judged lowered, per gate, against the same manifest and
  # round history. There is deliberately no second fold here (O-014).
  printf 'severity-downgrades=%s\n' "$downgrades"
  vf_execution_tally "$spec"
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

# Exclusions are generated paths only, never entire notes/.specify directories,
# and only the VERIFIED spec's own. Another spec's reports, captures and ledgers
# are ordinary source: a shipped spec's gate report is a fixture here (AC-010),
# and a changed fixture must invalidate reuse (AC-020). <own> is the verified
# spec's repo-relative directory, or empty when the spec is not
# .specify/specs/<name> inside the repository being read; empty excludes nothing.
vf_bookkeeping_path() { # <repo-relative path> <own spec dir or empty> [1 when the filesystem folds case]
  (( $# == 2 || $# == 3 )) || { echo 'vf_bookkeeping_path: <path> <own> [fold] required' >&2; return 2; }
  [[ -n "$2" ]] || return 1
  local rc=1 was=0
  # Where the filesystem folds case, OPPONENT.md IS opponent.md, so the match
  # folds too; everywhere else they are two different files.
  if [[ "${3:-0}" == 1 ]]; then shopt -q nocasematch && was=1; shopt -s nocasematch; fi
  case "$1" in
    "$2"/.tasks.accept.*|"$2"/notes/captures/*|"$2"/notes/verification/*|"$2"/notes/evidence.md|"$2"/notes/opponent.md|"$2"/notes/reality-check.md) rc=0;;
  esac
  [[ "${3:-0}" != 1 || "$was" == 1 ]] || shopt -u nocasematch
  return "$rc"
}
# Whether the filesystem holding a directory folds letter case, asked of the
# filesystem itself: a case-swapped spelling names the same inode. Git's
# core.ignorecase is only a recorded guess and can be wrong in either
# direction, and folding where the filesystem does not would let a different
# spec's records pass as this spec's own. The probe climbs to the nearest
# component that HAS a letter to swap (new-spec.sh can slugify a title to
# digits alone), and a swapped spelling that is itself a symlink is an alias,
# not evidence of folding.
vf_case_folds() { # <existing physical directory>
  local d="$1" alt
  while [[ "$d" == /?* ]]; do
    alt="$(dirname -- "$d")/$(basename -- "$d" | tr 'a-zA-Z' 'A-Za-z')"
    if [[ "$alt" != "$d" ]]; then [[ ! -L "$alt" && "$d" -ef "$alt" ]]; return; fi
    d="$(dirname -- "$d")"
  done
  return 1
}
# The anchor for vf_bookkeeping_path: the spec's own directory relative to the
# physical repository root, when it is .specify/specs/<name>. Pure string work,
# so no git discovery and none of its environment (GIT_DIR in a hook) can
# change it. A spelling typed in another case matches because every comparison
# folds case where the filesystem does.
vf_bookkeeping_anchor() { # <physical spec dir> <physical repo root> <fold>
  local own='' was=0
  if [[ "$3" == 1 ]]; then shopt -q nocasematch && was=1; shopt -s nocasematch; fi
  if [[ "$1" == "$2"/* ]]; then own="${1:$((${#2}+1))}"; [[ "$own" =~ ^\.specify/specs/[^/]+$ ]] || own=''; fi
  [[ "$3" != 1 || "$was" == 1 ]] || shopt -u nocasematch
  [[ -z "$own" ]] || printf '%s\n' "$own"
}
# Physical repo-relative location of a path: every symlink followed and every
# `..` resolved by the filesystem (cd -P, never lexically). Prints "." for the
# repository root and fails for a location outside it. Spelling is kept as
# typed; every comparison folds case where the filesystem does.
vf_physical_rel() ( # <physical repo root> <repo-relative path> <fold>
  local repo="$1" path="$1/$2" link dir base='' n=0
  [[ "${3:-0}" != 1 ]] || shopt -s nocasematch
  while [[ -L "$path" ]]; do
    (( n++ < 40 )) || return 1
    link="$(readlink "$path")" || return 1
    case "$link" in /*) path="$link";; *) path="$(dirname -- "$path")/$link";; esac
  done
  if [[ -d "$path" ]]; then dir="$path"; else dir="$(dirname -- "$path")"; base="$(basename -- "$path")"; fi
  dir="$(cd -P -- "$dir" 2>/dev/null && pwd -P)" || return 1
  if [[ "$dir" == "$repo" ]]; then dir=''
  elif [[ "$dir" == "$repo"/* ]]; then dir="${dir:$((${#repo}+1))}"
  else return 1; fi
  if [[ -n "$dir" && -n "$base" ]]; then printf '%s/%s\n' "$dir" "$base"
  elif [[ -n "$dir$base" ]]; then printf '%s\n' "$dir$base"
  else printf '.\n'; fi
)
vf_semantic_file() { # <repo-relative path> <input-file> <output-file>
  case "$1" in
    .specify/specs/*/STATUS.md)
      awk '/^## Decisions log[[:space:]]*$/ {on=1; print; next} /^## / {on=0} on {print}' "$2" > "$3";;
    .specify/specs/*/spec.md|.specify/specs/*/plan.md|.specify/specs/*/tasks.md)
      awk -v document="$1" '
        NR==1 && $0=="---" {fm=1; print; next}
        fm && $0=="---" {fm=0; print; next}
        fm && /^(status|updated):/ {next}
        document ~ /\/tasks\.md$/ && /^[ ]*- \*Evidence:\*/ {next}
        {sub(/^- \[[ xX~]\] /,"- [ ] "); print}
      ' "$2" > "$3";;
    *) cp "$2" "$3";;
  esac
}
# The bytes the identity hashes for one working-tree path, and the only way a
# reader whose verdict must be a function of the identity should obtain them:
# a link's target as it is (the link's own name says nothing about its
# target's grammar), a regular file through vf_semantic_file under its
# repository-relative name. The input is always "$repo/$path", so a name that
# begins with "-" is a path and never an option.
vf_path_content() { # <repo> <relative path> <output>
  if [[ -L "$1/$2" ]]; then cp -- "$1/$2" "$3"
  else vf_semantic_file "$2" "$1/$2" "$3"; fi
}
vf_path_record() { # <repo> <relative path> <output> <scratch> <own spec dir or empty> [fold]
  local repo="$1" path="$2" output="$3" scratch="$4" own="$5" fold="${6:-0}" type mode digest link=''
  # Only the enumeration passes an anchor. A declared input arrives with an
  # empty one, so it can never take this return: it is hashed, or it was
  # refused by name before this call.
  if vf_bookkeeping_path "$path" "$own" "$fold"; then return 0; fi
  if [[ -L "$repo/$path" ]]; then
    type='link'; link="$(readlink "$repo/$path"; printf .)"; link="${link%.}"; digest=''; mode=120000
    # Target content is an input even when the target is outside the repository.
    if [[ -f "$repo/$path" ]]; then
      vf_path_content "$repo" "$path" "$scratch/semantic" && digest="$(vf_hash "$scratch/semantic")" || return 3
    elif [[ -d "$repo/$path" ]]; then echo "verification inputs: directory symlink requires explicit target files: $path" >&2; return 3; fi
  elif [[ -f "$repo/$path" ]]; then
    type='file'; mode=100644; [[ ! -x "$repo/$path" ]] || mode=100755
    vf_path_content "$repo" "$path" "$scratch/semantic" || return 3
    digest="$(vf_hash "$scratch/semantic")" || return 3
  elif [[ ! -e "$repo/$path" ]]; then type=missing; mode=''; digest=''
  else echo "verification inputs: unsupported file type: $path" >&2; return 3; fi
  printf '%s\0' path "$path" "$type" "$mode" "$digest" "$link" >> "$output"
}

# The source enumeration: tracked and untracked-but-not-ignored paths,
# NUL-framed, relative to the repository root. vf_snapshot hashes exactly this
# set, so a reader whose verdict must be a function of the input identity -- a
# reuse-checked check, or a test fixture copying the kit -- enumerates through
# it as well: two spellings of "the source" are two things that can drift.
# A git failure is a failure, never an empty and therefore clean tree. The root
# is accepted by directory identity, not spelling: bash's `pwd -P` keeps a case
# the caller typed where git reports the on-disk one, and both name one
# directory on a folding filesystem.
vf_source_paths() ( # <repo root> <output>
  vf_git_local_unset || return 3
  [[ "$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" -ef "$1" ]] || {
    echo 'verification inputs: Git worktree root required' >&2; return 3;
  }
  git -C "$1" ls-files --cached --others --exclude-standard -z > "$2" || return 3
)

# Git's repository-local environment: the names `git rev-parse
# --local-env-vars` prints (GIT_DIR, GIT_INDEX_FILE, GIT_WORK_TREE, ...), which
# git exports to its hooks and which redirect every git command inheriting
# them -- to another index, another repository. The kernel names a repository
# by its path alone, so it runs git with none of them set, and the kit's suites
# unset them when they start (tests/helpers.sh): a reader resolving the same
# path then enumerates exactly what the identity hashes, and no fixture can
# write a caller's index. The list comes from git itself, which prints it even
# when those variables are broken. Call it only in a subshell that runs git
# (vf_git, or one around a block of git calls), never in a shell that reads a
# declared environment value: a project may declare one of these names under
# verification_environment, and its value must still be hashed.
vf_git_local_unset() {
  local name names
  names="$(git rev-parse --local-env-vars)" || return 3
  for name in $names; do unset "$name"; done
}
vf_git() ( vf_git_local_unset || return 3; exec git "$@" )

# Fixed arity six-field input records. Git supplies NUL-safe deterministic
# tracked/index and untracked ordering; no GNU sort -z or line-split filenames.
vf_snapshot() (
  local spec="$1" repo="$2" cwd="$3" output="$4" tmp path record head oid mode stage key value tool resolved own real fold=0
  spec="$(cd "$spec" && pwd -P)" || return 3
  repo="$(cd "$repo" && pwd -P)" || return 3
  cwd="$(cd "$cwd" && pwd -P)" || return 3
  ! vf_case_folds "$spec" || fold=1
  own="$(vf_bookkeeping_anchor "$spec" "$repo" "$fold")"
  [[ "$(vf_git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" == "$repo" ]] || {
    echo 'verification inputs: Git worktree root required' >&2; return 3;
  }
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/vf-snapshot.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_config "$repo/.specify/stack.yml" "$spec/tasks.md" "$tmp/config" || return 3
  printf '%s\0' version 1 "$repo" "$cwd" '' '' > "$tmp/inputs"
  # Git runs without its repository-local environment (vf_git_local_unset),
  # and only git does: this shell keeps those names, so the environment records
  # below hash a declared one by its ambient value, like any declared name. One
  # subshell holds the index listing and every per-entry lookup, so git is asked
  # for the list once per snapshot, not once per entry.
  (
    vf_git_local_unset || exit 3
    git -C "$repo" ls-files --stage -z > "$tmp/index" || exit 3
    while IFS= read -r -d '' record; do
      path="${record#*$'\t'}"; head="${record%%$'\t'*}"
      vf_bookkeeping_path "$path" "$own" "$fold" && continue
      read -r mode oid stage <<< "$head"
      [[ "$mode" != 160000 ]] || { echo "verification inputs: submodule requires explicit transitive inputs: $path" >&2; exit 3; }
      git -C "$repo" cat-file blob "$oid" > "$tmp/blob" || exit 3
      vf_semantic_file "$path" "$tmp/blob" "$tmp/semantic" || exit 3
      printf '%s\0' index "$path" "$mode" "$stage" "$(vf_hash "$tmp/semantic")" '' >> "$tmp/inputs"
    done < "$tmp/index"
  ) || return 3
  vf_source_paths "$repo" "$tmp/paths" || return 3
  while IFS= read -r -d '' path; do vf_path_record "$repo" "$path" "$tmp/inputs" "$tmp" "$own" "$fold" || return 3; done < "$tmp/paths"
  while IFS= read -r -d '' path; do
    case "$path" in /*|../*|*/../*|*/..|..) echo 'verification inputs must be repo relative' >&2; return 3;; esac
    [[ -e "$repo/$path" || -L "$repo/$path" ]] || { echo "verification input missing: $path" >&2; return 3; }
    # A declared input is never dropped silently. The verified spec's own
    # generated records cannot be one: hashing its report or ledgers would let
    # completing a round invalidate the floor that completion revalidates. So
    # a declaration reaching them -- the record itself, or a directory wholly
    # inside them, located physically rather than by spelling -- is refused.
    # So is the repository root: the whole source is already an input, and a
    # declared root would also sweep in every ignored file and .git itself.
    real="$(vf_physical_rel "$repo" "$path" "$fold")" || real=''
    if [[ "$real" == . ]]; then echo "verification inputs: declared input is the repository root: $path" >&2; return 3; fi
    if [[ -n "$real" ]] && { vf_bookkeeping_path "$real" "$own" "$fold" || { [[ -d "$repo/$real" ]] && vf_bookkeeping_path "$real/." "$own" "$fold"; }; }; then
      echo "verification inputs: declared input is this spec's own generated bookkeeping: $path" >&2; return 3
    fi
    if [[ -d "$repo/$path" && ! -L "$repo/$path" ]]; then
      # find ordering is not canonical across platforms. Hash each record then
      # sort its digest; paths themselves remain intact in each framed record.
      # Members follow the enumeration's own rule: the verified spec's
      # generated records are not inputs, and are not counted either.
      find "$repo/${real:-$path}" \( -type f -o -type l \) -print0 > "$tmp/extra" || return 3
      : > "$tmp/extra-hashes"
      while IFS= read -r -d '' record; do
        vf_bookkeeping_path "${record#"$repo/"}" "$own" "$fold" && continue
        : > "$tmp/path-record"
        vf_path_record "$repo" "${record#"$repo/"}" "$tmp/path-record" "$tmp" '' || return 3
        vf_hash "$tmp/path-record" >> "$tmp/extra-hashes" || return 3
      done < "$tmp/extra"
      LC_ALL=C sort "$tmp/extra-hashes" > "$tmp/sorted"
      printf '%s\0' declared-directory "$path" "$(vf_hash "$tmp/sorted")" '' '' '' >> "$tmp/inputs"
    else vf_path_record "$repo" "$path" "$tmp/inputs" "$tmp" '' || return 3; fi
  done < "$tmp/config/inputs.nul"
  # The environment record is a DECLARED, CLOSED set: the variables the harness
  # demonstrably uses, plus whatever the project declares. Hashing everything
  # compgen emits made the identity a session fingerprint rather than an input
  # identity — one undeclared variable the CLI varies per invocation (its own
  # effort setting) changed exactly one record of 2116 and stopped every floor,
  # capture and the AC-016 probe revalidating from any other process, which is
  # precisely the cross-invocation check the gate model is built on.
  # Values are hashed, never persisted, so a declared secret stays a secret.
  #
  # MEMBERSHIP IS EXACTLY THE DECLARATION. Not the declaration plus a fixed
  # list, which is what kept this finding alive: the previous repair closed the
  # set for every name except the LC_* family, whose membership it still read
  # out of the ambient process with `compgen -e | grep '^LC_'`.
  #
  # Replacing that with a closed literal locale list does NOT fix it either,
  # and the attempt is recorded because it looks like it should. LC_CTYPE and
  # LC_ALL are the two names macOS Terminal, OpenSSH SendEnv and most CI images
  # export by default; a fixed list records them present in one shell and unset
  # in another, so the digest still moves between two processes looking at a
  # byte-identical worktree. Closing the set means closing it against the names
  # that actually vary, not the ones that are easy to enumerate.
  #
  # Every fixed name previously hashed here fails the same test of whether the
  # harness reads it for RESULTS: PATH is already pinned far more precisely by
  # the `tool` records below (resolved absolute path plus content digest) and
  # by the `harness` records, so it added no identity those lack while
  # invalidating captures on a reordering that changes nothing; SHELL is never
  # read, because library functions run under an explicit `bash`; LANG and the
  # locale categories are not read either, and the harness pins `LC_ALL=C` at
  # the sites where collation actually matters; TMPDIR decides where temporary
  # files are written, never what a check concludes.
  #
  # A project whose checks genuinely depend on one of these declares it in
  # `verification_environment:`, and the declared path already proves presence
  # and value affect identity while only the value HASH reaches the manifest.
  # An UNDECLARED tool a check invokes is covered by neither this record nor
  # the tool records, before or after this change; `verification_tools:` is the
  # place that is closed. Default `[]` therefore yields an environment record
  # a second process reproduces exactly, which is the cross-invocation property
  # AC-016 depends on and the reason O-010 blocks.
  { while IFS= read -r -d '' key; do printf '%s\n' "$key"; done < "$tmp/config/environment.nul"
  } | LC_ALL=C sort -u > "$tmp/env-names"
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    if [[ -n "${!key+set}" ]]; then
      printf '%s\0' environment "$key" present "$(printf '%s' "${!key}" | vf_hash /dev/stdin)" '' '' >> "$tmp/inputs"
    else
      printf '%s\0' environment "$key" unset '' '' '' >> "$tmp/inputs"
    fi
  done < "$tmp/env-names"
  { printf '%s\0' bash; cat "$tmp/config/tools.nul"; } > "$tmp/tools"
  while IFS= read -r -d '' tool; do
    resolved="$(cd "$cwd" && command -v "$tool")" || { echo "verification tool missing: $tool" >&2; return 3; }
    [[ "$resolved" == /* ]] || resolved="$cwd/$resolved"
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
  repo="$(vf_git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || { echo 'capture requires a Git worktree' >&2; return 3; }
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
  if ! after="$(vf_snapshot "$spec" "$repo" "$cwd" "$staging/inputs-after.nul")"; then
    : > "$staging/inputs-after.nul"
    after="$(vf_hash "$staging/inputs-after.nul")" || return 3
  fi
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
    oseq="${f#CAP-}"; oseq="${oseq%%-*}"
    [[ "$oseq" =~ ^[1-9][0-9]*$ ]] || return 3
    (( oseq > seq )) || continue
    cmp -s "$other" "$spec/notes/captures/$f/COMPLETE" || return 3
    [[ "$(awk '$2=="meta.nul" {print $1}' "$other")" == "$(vf_hash "$spec/notes/captures/$f/meta.nul")" ]] || return 3
    vf_meta_load "$spec/notes/captures/$f/meta.nul" "$VF_CAPTURE_KEYS" || return 3
    oseq="$(vf_meta_get sequence)"; ocheck="$(vf_meta_get check)"; oinput="$(vf_meta_get input_before)"; oexit="$(vf_meta_get exit)"
    if (( oseq > seq )) && [[ "$ocheck" == "$check" && "$oinput" == "$before" && "$oexit" != 0 ]]; then
      vf_capture_check "$spec" "$f" '' integrity >/dev/null || return 3
      echo "capture superseded: later failed run $f for the same check and inputs" >&2; return 3
    fi
  done
)

vf_task_capture_matches() (
  local catalog="$1" task="$2" dir="$3" tmp repo
  vf_task_info "$catalog" "$task" || return 3
  tmp="$(mktemp "${TMPDIR:-/tmp}/vf-argv.XXXXXX")" || return 3
  trap 'rm -f "$tmp"' EXIT
  printf '%s\0' "$(command -v bash)" -o pipefail -c "$VF_TASK_COMMAND" > "$tmp"
  cmp -s "$tmp" "$dir/argv.nul" && cmp -s "$catalog" "$dir/bindings.nul" || return 3
  vf_meta_load "$dir/meta.nul" "$VF_CAPTURE_KEYS" || return 3
  repo="$(vf_meta_get repo)" || return 3
  vf_locators_exist "$catalog" "$task" "$repo"
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
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/vf-evidence.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_binding_snapshot "$spec" "$tmp/bindings" || return 3
  vf_gate_roots "$spec" "$tmp/roots" || return 3
  while IFS=$'\t' read -r task state stage subject; do
    [[ "$state" == "done" ]] || continue
    # Only exempt true administrative tasks absent from the typed catalog.
    vf_task_info "$tmp/bindings" "$task" >/dev/null 2>&1 || continue
    repo="$(vf_gate_task_repo "$spec" "$task" "$tmp/roots")" || return 3
    vf_snapshot "$spec" "$repo" "$repo" "$tmp/inputs" >/dev/null || return 3
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
    !started || ended {next}
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
    # Narrative around the block is permitted and is never evidence (plan 4.2).
    # The mapping section is contiguous rows: the first other non-blank line
    # ends the block and everything after it is narrative, including prose that
    # opens with an FM or INV token. A line that is clearly an attempted
    # mapping (ID followed by a comma) is still validated as one above, so a
    # malformed row is rejected rather than silently dropped. Record the early
    # end so the checker can distinguish a truncated envelope from a genuine
    # row mismatch instead of reporting dropped rows as missing.
    modes {rec("truncated","","",""); ended=1; next}
    {err("unexpected field or malformed mapping")}
    END {if(!started || task!=1 || caps!=1 || modes!=1 || !summaries) err("incomplete verification return"); if(bad) exit 3}
  ' "$1" > "$2"
}

vf_return_check() (
  local spec="$1" task="$2" return_file="$3" receipt="$4" tmp repo v i found summary f=() cap ids=() summaries=() mappings=() manual='' none=0 truncated=0 name path digest observer utc result extra before
  [[ -f "$return_file" && ! -L "$return_file" ]] || { echo 'return file missing or linked' >&2; return 3; }
  spec="$(cd "$spec" && pwd -P)" || return 3
  tmp="$(mktemp -d "$spec/notes/verification/return.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_binding_snapshot "$spec" "$tmp/bindings" || return 3
  vf_task_info "$tmp/bindings" "$task" || return 3
  vf_gate_roots "$spec" "$tmp/roots" || return 3
  repo="$(vf_gate_task_repo "$spec" "$task" "$tmp/roots")" || return 3
  before="$(vf_snapshot "$spec" "$repo" "$repo" "$tmp/inputs")" || return 3
  vf_return_parse "$return_file" "$tmp/return" || return 3
  while IFS= read -r -d '' v; do
    f+=("$v"); (( ${#f[@]} == 4 )) || continue
    case "${f[0]}" in
      task) [[ "${f[1]}" == "$task" ]] || { echo 'return: wrong task' >&2; return 3; };;
      captures)
        if [[ "${f[1]}" != none ]]; then
          case "${f[1]}" in *,|,*|*,,*) echo 'return: empty capture ID' >&2; return 3;; esac
          IFS=',' read -r -a ids <<< "${f[1]}"
          for ((i=0;i<${#ids[@]};i++)); do ids[i]="$(printf '%s' "${ids[i]}" | sed 's/^ *//;s/ *$//')"; done
        fi;;
      summary) summaries+=("${f[1]}");;
      manual) manual="${f[1]}";;
      none) none=1;;
      truncated) truncated=1;;
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
  if [[ -s "$tmp/want" ]]; then
    if (( none != 0 || ${#mappings[@]} == 0 )); then
      if (( truncated )); then echo 'return: Failure modes section ended at narrative before any mapping row; keep the rows contiguous' >&2
      else echo 'return: required Failure modes are missing' >&2; fi
      return 3
    fi
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
  if ! cmp -s "$tmp/want" "$tmp/actual"; then
    if (( truncated )); then echo 'return: Failure modes section ended at narrative before all mapping rows; keep the rows contiguous' >&2
    else echo 'return: missing, extra, duplicate or unknown FM/INV test binding' >&2; fi
    return 3
  fi
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

# Type a rejection so a live observation can require the specific control it
# claims to have run, instead of trusting any nonzero exit. The validator
# reports prose, so the mapping is explicit here and fails closed: anything
# unrecognized is "other" and satisfies no control.
vf_reject_class() {
  local text
  text="$(cat "$1" 2>/dev/null)"
  case "$text" in
    # binding-mismatch now means only a genuine required-row problem, which is
    # what the AC-016 control has to prove. A truncated envelope is its own
    # class so a formatting slip cannot stand in for the incomplete copy.
    *'Failure modes section ended at narrative'*) printf truncated-envelope;;
    *'missing, extra, duplicate or unknown FM/INV test binding'*|\
    *'required Failure modes are missing'*|\
    *'empty required set must explicitly be none'*) printf binding-mismatch;;
    *'summary is not the authentic capture summary'*) printf forged-summary;;
    *'return: wrong task'*) printf wrong-task;;
    *'mapping names unknown capture'*|*'duplicate capture'*) printf unknown-capture;;
    *'capture integrity'*) printf capture-integrity;;
    *'capture stale'*|*'capture failed'*|\
    *'capture superseded'*|*'inputs changed during validation'*) printf stale-capture;;
    *'unexpected field or malformed mapping'*|*'incomplete verification return'*|\
    *'mapping needs ID, locator, capture'*|*'unsupported version'*) printf malformed-return;;
    *) printf other;;
  esac
}

vf_accept_audit() {
  local spec="$1" task="$2" ret="$3" outcome="$4" reason="$5" before="$6" after="$7" class="${8:-none}" tmp final
  mkdir -p "$spec/notes/verification/accept-events" || return 3
  tmp="$(mktemp -d "$spec/notes/verification/accept-events/.event.XXXXXX")" || return 3
  printf '%s\0' version 1 task "$task" return_digest "$ret" outcome "$outcome" reason "$reason" class "$class" before "$before" after "$after" timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$tmp/meta.nul"
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
  # Idempotence is decided by the RECEIPT, before anything is revalidated: the
  # tick this return already earned was proven when it was earned, so re-proving
  # it is not what makes a repeat call safe. Validating first meant a return
  # whose inputs had merely drifted was reported as rejected and wrote a
  # rejection audit event into the very ledger the AC-016 probe reads.
  for old in "$spec/notes/verification/accepted/$task"/ACC-*; do
    [[ -d "$old" && -f "$old/COMMITTED" ]] || continue
    vf_integrity "$old" meta.nul return.txt tasks.after digests.nul || return 3
    [[ "$(cat "$old/COMMITTED")" == "$(vf_hash "$old/COMPLETE")" ]] || {
      echo 'accept receipt: committed marker digest mismatch' >&2; return 3;
    }
    if [[ "$(vf_hash "$old/return.txt")" == "$ret" ]] && grep -qE "^- \[x\] \*\*$task\*\*" "$tasks"; then
      vf_accept_audit "$spec" "$task" "$ret" already-accepted historical-receipt "$before" "$before" || return 3
      printf 'accept already-accepted task=%s return=%s freshness=historical\n' "$task" "$ret"; return 0
    fi
  done
  if vf_return_check "$spec" "$task" "$return_file" "$tmp/meta.nul" > "$tmp/validation.log" 2>&1; then rc=0; else rc=$?; fi
  if (( rc )); then
    reason="$(cat "$tmp/validation.log")"
    vf_accept_audit "$spec" "$task" "$ret" rejected "$reason" "$before" "$(vf_hash "$tasks")" \
      "$(vf_reject_class "$tmp/validation.log")" || return 3
    printf 'accept rejected: %s %s\n' "$task" "$reason" | head -c "$VF_FAILURE_BYTES"
    return 3
  fi
  vf_meta_load "$tmp/meta.nul" 'version task return_digest binding_digest input captures manual' || return 3
  evidence="$(vf_meta_get captures) verified by spec-gate accept; return sha256:$ret"
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
    repo="$(vf_git -C "$spec" rev-parse --show-toplevel 2>/dev/null)" || return 3
    repo="$(cd "$repo" && pwd -P)" || return 3
    expected="$(fm_get "$spec/STATUS.md" worktree 2>/dev/null || :)"
    if [[ -n "$expected" && "$expected" != none ]]; then
      [[ -d "$expected" && "$(cd "$expected" && pwd -P)" == "$repo" ]] || { echo 'gate worktree mismatch: reconcile STATUS worktree' >&2; return 3; }
    fi
    branch="$(fm_get "$spec/STATUS.md" branch 2>/dev/null || :)"
    if [[ -n "$branch" && "$branch" != none ]]; then
      [[ "$(vf_git -C "$repo" symbolic-ref --quiet --short HEAD)" == "$branch" ]] || { echo 'gate branch mismatch' >&2; return 3; }
    fi
    printf '%s\0' "$repo" > "$output"
  else
    for name in $declared; do
      path="$(bash "$HUB_DIR/scripts/system-map.sh" path "$name")" || return 3
      branch="refs/heads/spec/$(basename "$spec")"
      wt="$(vf_git -C "$path" worktree list --porcelain | awk -v branch="$branch" '/^worktree / {p=substr($0,10)} /^branch / && substr($0,8)==branch {print p}')" || return 3
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

# Explicit local checks may reuse only after every current predicate passes.
VF_REUSE_ENABLED=1
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
    wt="$(vf_git -C "$path" worktree list --porcelain | awk -v branch="$branch" '/^worktree / {p=substr($0,10)} /^branch / && substr($0,8)==branch {print p}')" || return 3
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
vf_coverage_catalog() { # raw selected binding catalog -> fixed triples task,id,locator
  local catalog="$1" output="$2" value fields=() id
  : > "$output"
  while IFS= read -r -d '' value; do
    fields+=("$value"); (( ${#fields[@]} == 12 )) || continue
    if [[ "${fields[4]}" == "done" ]]; then
      case "${fields[0]}" in
        binding) printf '%s\0' "${fields[2]}" "${fields[1]}" "${fields[7]}" >> "$output";;
        test)
          while IFS= read -r id; do
            [[ -z "$id" ]] || printf '%s\0' "${fields[2]}" "$id" "${fields[7]}" >> "$output"
          done < <(printf '%s\n' "${fields[8]}" | grep -oE 'AC-[0-9]{3}' | LC_ALL=C sort -u);;
      esac
    fi
    fields=()
  done < "$catalog"
}
vf_coverage_lines() {
  local task id locator
  while IFS= read -r -d '' task && IFS= read -r -d '' id && IFS= read -r -d '' locator; do
    printf '%s\t%s\t%s\n' "$task" "$id" "$locator"
  done < "$1"
}
vf_completed_coverage() (
  local spec="$1" stage="$2" output="$3" tmp task value fields=() ref receipt found previous
  tmp="$(mktemp -d "$spec/notes/verification/coverage.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_bindings "$spec" through-stage "$stage" "$tmp/raw" || return 3
  vf_coverage_catalog "$tmp/raw" "$output" || return 3
  vf_bindings "$spec" tasks '' "$tmp/all" || return 3
  vf_coverage_catalog "$tmp/all" "$tmp/all-coverage" || return 3
  vf_coverage_lines "$tmp/all-coverage" > "$tmp/current"
  while IFS= read -r -d '' value; do
    fields+=("$value"); (( ${#fields[@]} == 12 )) || continue
    if [[ "${fields[0]}" == task && "${fields[4]}" == "done" ]]; then
      task="${fields[2]}"
      local roots="$tmp/roots" repo
      vf_gate_roots "$spec" "$roots" || return 3
      repo="$(vf_gate_task_repo "$spec" "$task" "$roots")" || return 3
      vf_locators_exist "$tmp/all" "$task" "$repo" || return 3
      # A receipt authenticates historical acceptance; current task execution
      # is refreshed separately without undoing that historical state.
      found=0
      for receipt in "$spec/notes/verification/accepted/$task"/ACC-*; do
        [[ -f "$receipt/COMMITTED" ]] || continue
        vf_integrity "$receipt" meta.nul return.txt tasks.after digests.nul || return 3
        [[ "$(cat "$receipt/COMMITTED")" == "$(vf_hash "$receipt/COMPLETE")" ]] || return 3
        found=1
      done
      (( found )) || { echo "checkpoint acceptance gap: $task has no captured acceptance; refresh bootstrap receipt" >&2; return 3; }
      while IFS= read -r ref; do
        [[ -n "$ref" ]] || continue
        if ! awk -F '\t' -v task="$task" -v ref="$ref" '$1==task && $2==ref {found=1} END {exit !found}' "$tmp/current"; then
          echo "checkpoint binding gap: $task $ref has no covering test" >&2; return 3
        fi
      done < <(printf '%s\n' "${fields[8]}" | grep -oE '(AC|FM|INV)-[0-9]{3}' | LC_ALL=C sort -u)
    fi
    fields=()
  done < "$tmp/raw"
  # Previously established bindings must survive even if a task/Ref vanished.
  for previous in "$spec"/notes/verification/checkpoints/CHECKPOINT-*; do
    [[ -d "$previous" ]] || continue
    vf_integrity "$previous" meta.nul commands.nul bindings.nul inputs.nul roots.nul coverage.nul || return 3
    vf_coverage_lines "$previous/coverage.nul" > "$tmp/prior"
    awk -F '\t' 'FILENAME==ARGV[1] {current[$0]=1; next} !($0 in current) {print "checkpoint lost prior binding: " $0 > "/dev/stderr"; bad=1} END {exit bad ? 3 : 0}' "$tmp/current" "$tmp/prior" || return 3
  done
)

vf_gate_checkpoint() {
  local spec="$1" stage="$2" tmp repo source after task kind check_stage command policy v index=0 id final commands=0 start
  start="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  spec="$(cd "$spec" && pwd -P)" || return 3
  mkdir -p "$spec/notes/verification/checkpoints" || return 3
  tmp="$(mktemp -d "$spec/notes/verification/checkpoints/.checkpoint.XXXXXX")" || return 3
  VF_GATE_FRESH="$tmp/fresh"; : > "$VF_GATE_FRESH"; : > "$tmp/commands.nul"
  vf_gate_roots "$spec" "$tmp/roots.nul" || return 3
  vf_binding_snapshot "$spec" "$tmp/bindings.nul" || return 3
  if [[ "$(fm_get "$spec/spec.md" verification_contract)" == 1 ]]; then
    vf_completed_coverage "$spec" "$stage" "$tmp/coverage.nul" || return 3
  else
    echo 'checkpoint legacy warning: missing typed acceptance/bindings may be gaps' >&2
    : > "$tmp/coverage.nul"
  fi
  source="$(vf_gate_snapshot "$spec" "$tmp/roots.nul" "$tmp/inputs.nul")" || return 3
  vf_bindings "$spec" through-stage "$stage" "$tmp/selected" || return 3
  while IFS= read -r -d '' v; do
    local fields=()
    fields+=("$v")
    # Read the remaining eleven fields without dropping empty values.
    local i
    for ((i=1;i<12;i++)); do IFS= read -r -d '' v || return 3; fields+=("$v"); done
    [[ "${fields[0]}" == task && "${fields[4]}" == "done" ]] || continue
    task="${fields[2]}"
    if [[ "${fields[5]}" == manual ]]; then vf_manual_current "$spec" "$task" || return 3; continue; fi
    vf_task_info "$tmp/bindings.nul" "$task" || return 3
    repo="$(vf_gate_task_repo "$spec" "$task" "$tmp/roots.nul")" || return 3
    vf_gate_execute "$spec" "$tmp/bindings.nul" "$repo" "${VF_TASK[10]}" "$tmp/commands.nul" "task:$task" -- "$(command -v bash)" -o pipefail -c "$VF_TASK_COMMAND" || return $?
  done < "$tmp/selected"
  while IFS= read -r -d '' repo; do
    vf_config "$repo/.specify/stack.yml" "$spec/tasks.md" "$tmp/config-$index" || return 3
    while IFS= read -r -d '' kind && IFS= read -r -d '' check_stage && IFS= read -r -d '' command; do
      [[ "$kind" == checkpoints && "$check_stage" == "$stage" ]] || continue
      policy=never
      while IFS= read -r -d '' v; do [[ "$v" != "$command" ]] || policy=local; done < "$tmp/config-$index/reuse.nul"
      vf_gate_execute "$spec" "$tmp/bindings.nul" "$repo" "$policy" "$tmp/commands.nul" checkpoint -- "$(command -v bash)" -o pipefail -c "$command" || return $?
      commands=$((commands+1))
    done < "$tmp/config-$index/commands.nul"
    index=$((index+1))
  done < "$tmp/roots.nul"
  after="$(vf_gate_snapshot "$spec" "$tmp/roots.nul" "$tmp/after")" || return 3
  [[ "$source" == "$after" ]] || { echo 'checkpoint inputs changed during execution' >&2; return 3; }
  id="CHECKPOINT-${tmp##*.}"
  printf '%s\0' version 1 id "$id" kind checkpoint stage "$stage" start "$start" end "$(date -u +%Y-%m-%dT%H:%M:%SZ)" source "$source" exit 0 > "$tmp/meta.nul"
  vf_lock "$spec" || return 3
  vf_seal "$tmp" meta.nul commands.nul bindings.nul inputs.nul roots.nul coverage.nul || return 3
  final="${tmp%/*}/$id"
  vf_publish "$tmp" "$final" meta.nul commands.nul bindings.nul inputs.nul roots.nul coverage.nul || return 3
  vf_unlock
  (( commands )) || printf 'no checkpoint commands; completed-task coverage checked\n'
  vf_gate_result_summary "$final"
}

# Declaration location is necessary evidence; semantic adequacy remains review.
vf_locators_exist() {
  local catalog="$1" task="$2" repo="$3" value fields=() path name
  while IFS= read -r -d '' value; do
    fields+=("$value"); (( ${#fields[@]} == 12 )) || continue
    if [[ "${fields[0]}" == test && "${fields[2]}" == "$task" && "${fields[5]}" != manual ]]; then
      path="${fields[7]%%::*}"; name="${fields[7]#*::}"
      [[ -f "$repo/$path" ]] && grep -F -- "$name" "$repo/$path" >/dev/null || { echo "verification binding: unknown test ${fields[7]}" >&2; return 3; }
    fi
    fields=()
  done < "$catalog"
}

vf_report_block() { # report-file round -> canonical block, ignoring quoted headings
  awk -v wanted="$2" "$_VF_AWK_FENCE"'
    { quoted = vf_quoted($0) }
    !quoted && /^## Round [1-9][0-9]*$/ {n=$3}
    !n && !quoted && /^# (Opponent review|Reality Check)/ {n=1}
    n==wanted {text=text $0 "\n"}
    END {sub(/\n+$/, "", text); if(text!="") print text; else exit 3}
  ' "$1"
}
vf_round_history() { # spec gate temp -> globals
  local spec="$1" gate="$2" tmp="$3" value f=() ledger
  VF_ROUND_LAST=0 VF_ROUND_TIME='' VF_ROUND_STYLE='' VF_ROUND_DATE=''
  vf_reports "$spec/notes/$gate.md" "$gate" "$tmp/catalog" "$spec" || return 3
  while IFS= read -r -d '' value; do
    f+=("$value"); (( ${#f[@]} == 12 )) || continue
    if [[ "${f[0]}" == round ]]; then
      VF_ROUND_LAST="${f[1]}" VF_ROUND_TIME="${f[2]}" VF_ROUND_STYLE="${f[6]}" VF_ROUND_DATE="${f[7]}"
      ledger="$spec/notes/verification/rounds/$gate/ROUND-${f[1]}"
      if [[ -f "$ledger/report.sha256" ]]; then
        vf_integrity "$ledger" meta.nul || return 3
        vf_report_block "$spec/notes/$gate.md" "${f[1]}" > "$tmp/block" || return 3
        [[ "$(cat "$ledger/report.sha256")" == "$(vf_hash "$tmp/block")" ]] || { echo 'round recovery: completed report digest changed; reconcile report/ledger' >&2; return 3; }
      elif [[ "${f[6]}" == canonical && ! -d "$ledger" ]]; then
        echo 'round recovery: canonical report has no reservation ledger; reconcile its invocation' >&2; return 3
      fi
    fi
    f=()
  done < "$tmp/catalog"
  if [[ "$VF_ROUND_STYLE" == legacy && -f "$spec/notes/verification/rounds/$gate/legacy-time.nul" ]]; then
    vf_meta_load "$spec/notes/verification/rounds/$gate/legacy-time.nul" 'round timestamp report_digest' || return 3
    [[ "$(vf_meta_get round)" == "$VF_ROUND_LAST" && "$(vf_meta_get report_digest)" == "$(vf_hash "$spec/notes/$gate.md")" ]] || return 3
    VF_ROUND_TIME="$(vf_meta_get timestamp)"; vf_utc_valid "$VF_ROUND_TIME" || return 3
  fi
}

vf_round_authorized() (
  local spec="$1" gate="$2" round="$3" previous="$4" line stamp kind revision rejects now
  [[ -n "$previous" ]] || { echo 'round authorization: date-only history needs timestamped digest reconciliation' >&2; return 4; }
  # A fail-closed parser that names nothing turns an authoring error into an
  # unexplained refusal. Round 6 recorded the real cost of that silence on this
  # spec: a semicolon inside reason= split the line into six fields, the entry
  # was discarded with no output, and the next session inherited a handoff
  # asserting the round was already authorized. Every refusal below now names
  # the line and the clause, so the operator sees WHICH entry failed and WHY.
  rejects="$(mktemp "${TMPDIR:-/tmp}/vf-waiver.XXXXXX")" || return 4
  trap 'rm -f "$rejects"' EXIT
  line="$(awk -v gate="$gate" -v round="$round" -v rejects="$rejects" -v gates="$VF_GATES" "$_VF_AWK_FENCE"'
    # The grammar is the whole line: the UTC stamp is anchored right after the
    # bullet and nothing may sit between it and the separator, so no permissive
    # prefix can smuggle a valid-looking timestamp past a malformed entry.
    function note(why) {printf "  STATUS.md:%d %s\n", NR, why > rejects}
    function knowngate(v) {return index(" " gates " ", " " v " ") > 0}
    BEGIN {pre="^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z — "}
    # Quoted text is a record, not an authorization: a revoked or illustrative
    # line reproduced in a fence or blockquote must lift nothing. Same
    # suppression the report and config parsers use. An unclosed fence keeps
    # suppressing, which denies, which is the safe direction. Indented bullets
    # are already excluded because the grammar anchors the bullet at column 1.
    vf_quoted($0) {next}
    /^## Decisions log[[:space:]]*$/ {on=1; next} /^## / {on=0}
    # Candidate detection is deliberately WIDER than the grammar: anything a
    # reader would take for an authorization is reported when refused, even
    # when it fails before the gate field can be read. The second alternative
    # catches "<kind>:" written without its trailing space, which the first
    # cannot see -- but only when the whole anchored prefix is present, so
    # prose that merely mentions `waiver:` in a code span is still not a
    # candidate and the refusal list stays readable.
    on && (/(waiver|spec-revision): / || $0 ~ pre "(waiver|spec-revision):") {
      kindtok = ($0 ~ /spec-revision:/) ? "spec-revision" : "waiver"
      if ($0 ~ pre kindtok ":" && $0 !~ pre kindtok ": ") {
        note("refused: \"" kindtok ":\" must be followed by one space before gate=")
        next
      }
      if ($0 !~ pre "(waiver|spec-revision): ") {
        note("refused: line must start with \"- <YYYY-MM-DDTHH:MM:SSZ> \" and the em-dash separator before \"" kindtok ":\"")
        next
      }
      stamp=substr($0,3,20); rest=$0; sub(pre,"",rest)
      kind=rest; sub(/:.*/,"",kind); sub(/^[^:]+: /,"",rest)
      n=split(rest,f,"; ")
      # The gate clause was the ONE refusal in this production taking a bare
      # next with no note(), so a single-letter slip made the tail below report
      # that NO candidate exists while listing four unrelated historical lines
      # and omitting the one just written. It is also the one clause that needs
      # a DISTINCTION rather than a note added blindly, and the grammar
      # supplies it: gate=<g> where <g> ranges over the gates that exist. A
      # value naming another KNOWN gate is that gate record and is correctly
      # skipped in silence; anything else is a malformed candidate for the gate
      # being asked about and must be named. Reading the gate set from VF_GATES
      # rather than restating it keeps this inheritable by a third gate.
      if (f[1]!="gate=" gate) {
        if (f[1] ~ /^gate=/ && knowngate(substr(f[1],6))) next
        if (f[1] ~ /^gate=/) note("refused: gate=\"" substr(f[1],6) "\" names no known gate (" gates ")")
        else note("refused: first field must be gate=<" gates ">, found \"" f[1] "\"")
        next
      }
      if ((kind=="waiver" && n!=5) || (kind=="spec-revision" && n!=6)) {
        note("refused: " kind " needs exactly " (kind=="waiver" ? "5" : "6") " \"; \"-separated fields, found " n " — a \"; \" inside reason= splits the entry")
        next
      }
      if (f[2]!="round=" round) {note("authorizes " f[2] ", not round=" round); next}
      if (f[3]!=("after=" (round-1))) {note("refused: " f[3] " must be after=" (round-1)); next}
      if (f[4]!~/^by=[^;]+$/) {note("refused: by= is missing, empty or contains \";\""); next}
      if (f[n]!~/^reason=[^;]+$/) {note("refused: reason= is missing, empty or contains \";\""); next}
      if (kind=="spec-revision" && f[5]!~/^revision=[^;]+$/) {note("refused: revision= is missing, empty or contains \";\""); next}
      print stamp "\t" kind "\t" (kind=="spec-revision" ? substr(f[5],10) : "none")
    }
  ' "$spec/STATUS.md")"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  while IFS=$'\t' read -r stamp kind revision; do
    [[ -n "$stamp" ]] || continue
    vf_utc_valid "$stamp" || { printf '  %s refused: malformed UTC timestamp\n' "$stamp" >> "$rejects"; continue; }
    [[ "$stamp" > "$previous" ]] || { printf '  %s refused: not after the previous round completion at %s\n' "$stamp" "$previous" >> "$rejects"; continue; }
    [[ ! "$stamp" > "$now" ]] || { printf '  %s refused: timestamp is in the future\n' "$stamp" >> "$rejects"; continue; }
    if [[ "$kind" == spec-revision ]]; then
      [[ "$revision" == "sha256:$(vf_hash "$spec/spec.md")" ]] || { printf '  %s refused: revision= does not match the current spec.md digest\n' "$stamp" >> "$rejects"; continue; }
      case "$(fm_get "$spec/spec.md" status)" in accepted|implementing) ;; *) printf '  %s refused: spec.md status is not accepted or implementing\n' "$stamp" >> "$rejects"; continue;; esac
    fi
    return 0
  done <<< "$line"
  echo "round authorization denied: $gate round $round needs an exact-round user waiver/spec revision after round $((round-1))" >&2
  if [[ -s "$rejects" ]]; then
    echo "  candidate authorization lines were found and refused:" >&2
    head -n 10 "$rejects" >&2
  else
    echo "  no candidate authorization line for this gate was found in the Decisions log" >&2
  fi
  return 4
)

# Authoring-time authorization check: same grammar and the same diagnostics as
# a reservation, with no reservation and no state change. The operator can
# validate a waiver WHEN THEY WRITE IT instead of discovering at the next gate
# that it authorizes nothing, which is the failure round 6 recorded.
vf_gate_waiver_check() ( # spec gate round
  local spec="$1" gate="$2" round="$3" tmp
  vf_is_gate "$gate" || { echo 'unknown gate' >&2; return 2; }
  [[ "$round" =~ ^[1-9][0-9]{0,8}$ ]] || { echo 'round must be a positive integer' >&2; return 2; }
  spec="$(cd "$spec" && pwd -P)" || return 3
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/vf-waiver-check.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_round_history "$spec" "$gate" "$tmp" || return 3
  # An already-sealed round is not "denied" — saying so would send the operator
  # hunting for an authorization problem that does not exist.
  if (( round <= VF_ROUND_LAST )); then
    printf '%s round %s is already completed; the next round is %s\n' "$gate" "$round" "$((VF_ROUND_LAST+1))"
    return 0
  fi
  if (( round < 4 )); then
    printf 'rounds 1-3 need no authorization: %s round %s\n' "$gate" "$round"
    return 0
  fi
  vf_round_authorized "$spec" "$gate" "$round" "$VF_ROUND_TIME" || return 4
  printf 'authorized: %s round %s\n' "$gate" "$round"
)
vf_gate_round() { # spec gate [--floor id | --complete file | --reconcile file]
  local spec="$1" gate="$2"; shift 2
  local mode=reserve floor='' report='' tmp next pending='' ledger source reserved stamp value f=() n report_source report_floor verdict report_time combined digest prior m
  vf_is_gate "$gate" || return 2
  while (( $# )); do
    case "$1" in
      --floor) [[ $# -ge 2 && -z "$floor" ]] || return 2; floor="$2"; shift 2;;
      --complete|--reconcile) [[ $# -eq 2 && "$mode" == reserve ]] || return 2; mode="${1#--}"; report="$2"; shift 2;;
      *) return 2;;
    esac
  done
  spec="$(cd "$spec" && pwd -P)" || return 3
  vf_lock "$spec" || return 3
  mkdir -p "$spec/notes/verification/rounds/$gate" || return 3
  tmp="$(mktemp -d "$spec/notes/verification/round-check.XXXXXX")" || return 3
  VF_STAGING="$tmp"
  vf_round_history "$spec" "$gate" "$tmp" || return 3
  for ledger in "$spec/notes/verification/rounds/$gate"/ROUND-*; do
    [[ -d "$ledger" ]] || continue
    vf_integrity "$ledger" meta.nul || return 3
    if [[ ! -f "$ledger/report.sha256" ]]; then
      [[ -z "$pending" ]] || { echo 'round recovery: multiple pending reservations' >&2; return 3; }
      pending="$ledger"
    fi
  done
  if [[ "$mode" == reserve ]]; then
    [[ -z "$pending" ]] || { echo 'round recovery: interrupted invocation; use --complete or --reconcile before another invocation' >&2; return 3; }
    next=$((VF_ROUND_LAST+1))
    if (( next >= 4 )); then vf_round_authorized "$spec" "$gate" "$next" "$VF_ROUND_TIME" || { vf_tally "$spec"; echo "Suggested next: sweep sibling sites of recurring classes; obtain scoped user authorization." >&2; return 4; }; fi
    [[ -n "$floor" ]] || floor="$(cat "$spec/notes/verification/floor-latest" 2>/dev/null)"
    source="$(vf_floor_validate "$spec" "$floor")" || return 3
    reserved="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    mkdir "$tmp/reservation" || return 3
    printf '%s\0' version 1 gate "$gate" round "$next" floor "$floor" source "$source" reserved "$reserved" > "$tmp/reservation/meta.nul"
    vf_seal "$tmp/reservation" meta.nul || return 3
    # Stage beside the final reservation so publication is one rename.
    ledger="$spec/notes/verification/rounds/$gate/.reservation-${tmp##*.}"
    mv "$tmp/reservation" "$ledger" || return 3
    vf_publish "$ledger" "$spec/notes/verification/rounds/$gate/ROUND-$next" meta.nul || return 3
    printf 'round=%s gate=%s source=%s floor=%s reserved=%s\n' "$next" "$gate" "$source" "$floor" "$reserved"
    return 0
  fi
  if [[ -z "$pending" && "$mode" == reconcile && "$VF_ROUND_STYLE" == legacy ]]; then
    # Explicit date-only reconciliation is data, never a waiver or reset.
    vf_meta_load "$report" 'round timestamp report_digest' || return 3
    [[ "$(vf_meta_get round)" == "$VF_ROUND_LAST" && "$(vf_meta_get report_digest)" == "$(vf_hash "$spec/notes/$gate.md")" ]] || return 3
    stamp="$(vf_meta_get timestamp)"; vf_utc_valid "$stamp" || return 3
    [[ ! "${stamp:0:10}" < "$VF_ROUND_DATE" && ! "$stamp" > "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ]] || return 3
    cp "$report" "$spec/notes/verification/rounds/$gate/legacy-time.nul" || return 3
    printf 'reconciled legacy gate=%s round=%s timestamp=%s\n' "$gate" "$VF_ROUND_LAST" "$stamp"
    return 0
  fi
  [[ -n "$pending" && -f "$report" ]] || { echo 'round completion: pending reservation and returned report required' >&2; return 3; }
  vf_meta_load "$pending/meta.nul" 'version gate round floor source reserved' || return 3
  n="$(vf_meta_get round)"; floor="$(vf_meta_get floor)"; source="$(vf_meta_get source)"; reserved="$(vf_meta_get reserved)"
  [[ "$(vf_meta_get version)" == 1 && "$(vf_meta_get gate)" == "$gate" &&
     "$n" =~ ^[1-9][0-9]*$ && ${#n} -le 9 && "${pending##*/}" == "ROUND-$n" &&
     "$source" =~ ^[a-f0-9]{64}$ && "$floor" =~ ^FLOOR-[A-Za-z0-9]+$ ]] || return 3
  vf_utc_valid "$reserved" || return 3
  combined="$tmp/combined.md"
  if (( VF_ROUND_LAST == n )); then
    vf_report_block "$spec/notes/$gate.md" "$n" > "$tmp/existing" || return 3
    vf_report_block "$report" "$n" > "$tmp/returned" || return 3
    cmp -s "$tmp/existing" "$tmp/returned" || { echo 'round recovery: appended report differs from returned report' >&2; return 3; }
    cp "$spec/notes/$gate.md" "$combined" || return 3
  elif (( VF_ROUND_LAST+1 == n )); then
    : > "$combined"
    [[ ! -f "$spec/notes/$gate.md" ]] || cat "$spec/notes/$gate.md" > "$combined"
    printf '\n' >> "$combined"; cat "$report" >> "$combined"
  else echo 'round recovery: reservation and canonical count disagree' >&2; return 3; fi
  vf_reports "$combined" "$gate" "$tmp/completed-catalog" "$spec" || return 3
  report_source='' report_floor='' verdict='' report_time=''
  while IFS= read -r -d '' value; do
    f+=("$value"); (( ${#f[@]} == 12 )) || continue
    if [[ "${f[0]}" == round && "${f[1]}" == "$n" ]]; then
      report_time="${f[2]}" report_source="${f[3]}" report_floor="${f[4]}" verdict="${f[5]}"
    elif [[ "${f[0]}" == round && "${f[1]}" -gt "$n" ]]; then return 3; fi
    f=()
  done < "$tmp/completed-catalog"
  [[ ! "$report_time" > "$(date -u +%Y-%m-%dT%H:%M:%SZ)" && "$report_source" == "$source" && "$report_floor" == "$floor" && ( "$report_time" > "$reserved" || "$report_time" == "$reserved" ) ]] || { echo 'round completion: report identities/timestamp differ from reservation' >&2; return 3; }
  if [[ "$mode" != reconcile || ( "$verdict" != BLOCKED && "$verdict" != FAILED ) ]]; then
    [[ "$(vf_floor_validate "$spec" "$floor")" == "$source" ]] || return 3
  fi
  # $verdict is the value vf_reports validated and emitted above, not a second
  # reading of the report text. See the note on vf_reality_matrix.
  if [[ "$gate" == reality-check ]]; then vf_reality_matrix "$spec" "$combined" "$n" "$source" "$verdict" || return 3; fi
  # Belt and braces for the same class: never publish a completion that would
  # move a previously sealed round, which would wedge every later invocation.
  for prior in "$spec/notes/verification/rounds/$gate"/ROUND-*; do
    [[ -d "$prior" && -f "$prior/report.sha256" ]] || continue
    m="${prior##*/ROUND-}"
    [[ "$m" != "$n" ]] || continue
    vf_report_block "$combined" "$m" > "$tmp/prior-block" || return 3
    [[ "$(cat "$prior/report.sha256")" == "$(vf_hash "$tmp/prior-block")" ]] || {
      echo 'round completion: report would change already sealed round '"$m"'; correct the returned report' >&2; return 3; }
  done
  vf_report_block "$combined" "$n" > "$tmp/block" || return 3
  digest="$(vf_hash "$tmp/block")" || return 3
  mv "$combined" "$spec/notes/$gate.md" || return 3
  printf '%s\n' "$digest" > "$pending/report.sha256.tmp" && mv "$pending/report.sha256.tmp" "$pending/report.sha256" || return 3
  printf 'round completed gate=%s round=%s verdict=%s report=%s\n' "$gate" "$n" "$verdict" "$digest"
}

# Every AC definition, with canonical whitespace and its exact revision digest.
vf_ac_catalog() (
  local spec="$1" output="$2" tmp id criterion
  tmp="$(mktemp "${TMPDIR:-/tmp}/vf-ac.XXXXXX")" || return 3
  trap 'rm -f "$tmp"' EXIT
  awk '
    function flush() {if(id!="") {gsub(/[[:space:]]+/," ",text); sub(/ +$/, "",text); printf "%s%c%s%c",id,0,text,0}; id=""}
    /^- (\[[ xX]\] )?(\*\*)?AC-[0-9][0-9][0-9]/ {
      flush(); match($0,/AC-[0-9][0-9][0-9]/); id=substr($0,RSTART,RLENGTH)
      if(seen[id]++) {print "duplicate AC definition" > "/dev/stderr"; bad=1}
      text=substr($0,RSTART+RLENGTH); sub(/^(:\*\*|\*\*:|\*\*|:)?[ ]*(—[ ]*)?/,"",text); next
    }
    /^#/ || /^- / {flush()}
    id!="" && NF {text=text " " $0}
    END {flush(); if(bad) exit 3}
  ' "$spec/spec.md" > "$tmp" || return 3
  : > "$output"
  while IFS= read -r -d '' id && IFS= read -r -d '' criterion; do
    printf '%s\0' "$id" "$criterion" "$(printf '%s' "$criterion" | vf_hash /dev/stdin)" >> "$output"
  done < "$tmp"
  [[ -s "$output" ]] || { echo 'matrix: no AC definitions found' >&2; return 3; }
)
vf_matrix_parse() {
  awk -F '|' "$_VF_AWK_FENCE"'
    function trim(s) {sub(/^[ ]*/,"",s); sub(/[ ]*$/, "",s); return s}
    vf_quoted($0) {next}
    /^\| AC-[0-9][0-9][0-9] / {
      if(NF!=7 || seen[trim($2)]++) {print "matrix: malformed/duplicate row" > "/dev/stderr"; bad=1; next}
      for(i=2;i<=6;i++) printf "%s%c",trim($i),0
    }
    END {if(bad) exit 3}
  ' "$1" > "$2"
}
# The verdict is a PARAMETER here, never re-derived from the report text.
# vf_reports parses the identity production at :1083-1094 — tolerating
# surrounding whitespace through value() at :968, refusing a duplicate field at
# :1086, skipping quoted content at :1066 — validates it at :1054 and emits it
# as field 5 of the round record at :1063; vf_gate_round holds that value and
# passes it in. A second parser over the same text is a second grammar, and the
# two disagree on every shape the first one tolerates: a one-space-only sed read
# `**Verdict:**  READY` as " READY" and stood the :2520 guard down over MISSING
# rows. The rule this encodes, stated over the validator rather than over this
# line: any field vf_reports emits is consumed from the emitted catalog by every
# downstream reader. vf_report_block is the one deliberate divergence — its
# output must include quoted lines because the sealed digest covers them — which
# is exactly why it is a digest input and never a field source.
vf_reality_matrix() (
  local spec="$1" report="$2" round="$3" source="$4" verdict="$5" tmp id text digest value fields=() found expected count=0 rows=0 prior
  # Fail closed on a caller that supplies no catalog value: an unrecognized
  # verdict must never reach :2520 as "not READY" and quietly permit the row.
  case "$verdict" in
    READY|'NEEDS WORK'|FAILED) ;;
    *) echo 'matrix: caller supplied no validated round verdict' >&2; return 3;;
  esac
  tmp="$(mktemp -d "$spec/notes/verification/matrix.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_ac_catalog "$spec" "$tmp/acs" || return 3
  vf_report_block "$report" "$round" > "$tmp/block" || return 3
  vf_matrix_parse "$tmp/block" "$tmp/matrix" || return 3
  while IFS= read -r -d '' id && IFS= read -r -d '' text && IFS= read -r -d '' digest; do
    count=$((count+1)); found=0
    # Markdown table delimiters in criteria use their HTML entity spelling.
    expected="$(printf '%s' "$text" | sed 's/|/\&#124;/g'); sha256:$digest"
    while IFS= read -r -d '' value; do
      fields+=("$value"); (( ${#fields[@]} == 5 )) || continue
      if [[ "${fields[0]}" == "$id" ]]; then
        found=$((found+1))
        [[ "${fields[1]}" == "$expected" && "${fields[3]}" == "$source" && -n "${fields[2]}" ]] || { echo "matrix: changed/missing criterion, evidence or impact mapping for $id" >&2; return 3; }
        case "${fields[4]}" in
          PASS) vf_matrix_evidence "$spec" "${fields[2]}" || return 3;;
          'carried (round '[1-9]*')')
            prior="${fields[4]#carried (round }"; prior="${prior%)}"
            [[ "$prior" =~ ^[1-9][0-9]*$ ]] && (( prior < round )) || return 3
            vf_matrix_prior "$spec" "$report" "$prior" "$id" "$expected" "${fields[2]}" "$source" || return 3;;
          FAIL|MISSING) [[ "$verdict" != READY ]] || { echo 'matrix: READY contains unsupported row' >&2; return 3; };;
          *) echo 'matrix: unknown status; renew evaluation' >&2; return 3;;
        esac
      fi
      fields=()
    done < "$tmp/matrix"
    (( found == 1 )) || { echo "matrix: missing $id" >&2; return 3; }
  done < "$tmp/acs"
  while IFS= read -r -d '' value; do rows=$((rows+1)); done < "$tmp/matrix"
  (( rows == count*5 )) || { echo 'matrix: unknown AC row' >&2; return 3; }
)

# Exact Evidence cell: "CAP-id; review: <semantic explanation>".
# The explanation is the independent reviewer's judgment, not inferred by code.
vf_matrix_evidence() (
  local spec="$1" evidence="$2" tmp cap repo policy
  case "$evidence" in *'; review: '?*) ;; *) echo 'matrix: semantic review and capture reference required' >&2; return 3;; esac
  cap="${evidence%%; review: *}"
  [[ "$cap" =~ ^CAP-[1-9][0-9]*-[A-Za-z0-9]+$ ]] || return 3
  vf_meta_load "$spec/notes/captures/$cap/meta.nul" "$VF_CAPTURE_KEYS" || return 3
  repo="$(vf_meta_get repo)"; policy="$(vf_meta_get policy)"
  tmp="$(mktemp "$spec/notes/verification/matrix-input.XXXXXX")" || return 3
  trap 'rm -f "$tmp"' EXIT
  vf_snapshot "$spec" "$repo" "$repo" "$tmp" >/dev/null || return 3
  vf_capture_check "$spec" "$cap" "$tmp" current || return 3
  # A carried row cannot turn a fresh external observation into reusable proof.
  [[ "${3:-renewed}" != carried || "$policy" == local ]] || return 3
)
vf_matrix_prior() (
  local spec="$1" report="$2" prior="$3" id="$4" criterion="$5" evidence="$6" source="$7" tmp value prior_fields=() found=0
  [[ "$prior" =~ ^[1-9][0-9]*$ ]] || return 3
  tmp="$(mktemp -d "$spec/notes/verification/matrix-prior.XXXXXX")" || return 3
  trap 'rm -rf "$tmp"' EXIT
  vf_report_block "$report" "$prior" > "$tmp/block" || return 3
  vf_matrix_parse "$tmp/block" "$tmp/rows" || return 3
  # Only a completed authentic report can supply PASS, never a draft or FAIL.
  [[ -f "$spec/notes/verification/rounds/reality-check/ROUND-$prior/report.sha256" ]] || return 3
  [[ "$(vf_hash "$tmp/block")" == "$(cat "$spec/notes/verification/rounds/reality-check/ROUND-$prior/report.sha256")" ]] || return 3
  while IFS= read -r -d '' value; do
    prior_fields+=("$value"); (( ${#prior_fields[@]} == 5 )) || continue
    if [[ "${prior_fields[0]}" == "$id" && "${prior_fields[1]}" == "$criterion" && "${prior_fields[2]}" == "$evidence" && "${prior_fields[3]}" == "$source" && "${prior_fields[4]}" == PASS ]]; then found=1; fi
    prior_fields=()
  done < "$tmp/rows"
  (( found )) || { echo 'matrix: prior PASS/criterion/impact/evidence differs; renew evaluation' >&2; return 3; }
  vf_matrix_evidence "$spec" "$evidence" carried
)

vf_execution_tally() (
  local spec="$1" dir file v f=() executed=0 reused=0 bytes=0 summary_bytes=0 captures=0 results=0
  for dir in "$spec"/notes/verification/floors/FLOOR-* "$spec"/notes/verification/checkpoints/CHECKPOINT-*; do
    [[ -d "$dir" ]] || continue
    if [[ "${dir##*/}" == FLOOR-* ]]; then
      vf_integrity "$dir" meta.nul commands.nul bindings.nul inputs.nul roots.nul || return 3
    else
      vf_integrity "$dir" meta.nul commands.nul bindings.nul inputs.nul roots.nul coverage.nul || return 3
    fi
    results=$((results+1))
    while IFS= read -r -d '' v; do
      f+=("$v"); (( ${#f[@]} == 6 )) || continue
      if [[ "${f[5]}" == 1 ]]; then reused=$((reused+1)); else executed=$((executed+1)); fi
      f=()
    done < "$dir/commands.nul"
  done
  for file in "$spec"/notes/verification/captures/CAP-*; do
    [[ -f "$file" ]] || continue
    vf_capture_check "$spec" "${file##*/}" '' integrity || return 3
    dir="$spec/notes/captures/${file##*/}"
    bytes=$((bytes+$(wc -c < "$dir/output.log")))
    summary_bytes=$((summary_bytes+$(wc -c < "$dir/summary.txt")))
    captures=$((captures+1))
  done
  printf 'execution-observations=%s check-executions=%s cache-hits=%s captures=%s full-log-bytes=%s returned-summary-bytes=%s usage=unknown baseline-usage=unknown\n' "$results" "$executed" "$reused" "$captures" "$bytes" "$summary_bytes"
)
