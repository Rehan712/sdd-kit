#!/usr/bin/env bash
# T030o43 mutation matrix, 2026-09-27 (session 7): every guard of the O-017 repair
# isolated in a standalone copy built from the live manifest enumeration.
# Usage: bash t030o43-mutations.sh <scratchpad> <worktree> [DRY=1] [SHARD=i/n]
#
# Kinds: kill  -- the judge must FAIL and print the named diagnostic;
#        equiv -- the judge must PASS, with the argument recorded beside the row.
# A judge is one fixture function run alone, as t_run_all runs a test (a fresh
# SANDBOX, the build-failure record checked). Each mutant is a literal
# replacement that must match exactly once (DRY=1 checks only that), and most
# mutants restore the unrepaired line. Every restore is checked byte-identical
# with cmp against a pristine copy.
set -uo pipefail
SP="$1"; WT="$2"; DRY="${DRY:-0}"; SHARD="${SHARD:-0/1}"
si="${SHARD%/*}"; sn="${SHARD#*/}"
R="$SP/t030o43-matrix-$si"; C="$R/copy"; P="$R/pristine"; w="$R/work"
export TMPDIR="$R/tmp"
rm -rf "$R"; mkdir -p "$C" "$P" "$w" "$TMPDIR"
fails=0; rowi=0
say() { printf '%s\n' "$*"; }
verdict() { if [[ "$2" == "$3" ]]; then say "PASS $1"; else say "FAIL $1 (want=$2 got=$3)"; fails=$((fails+1)); fi; }
( cd "$WT" && GIT_OPTIONAL_LOCKS=0 git ls-files -z --cached --others --exclude-standard ) > "$w/enum.nul" || { say 'FAIL enumeration'; exit 2; }
for d in "$C" "$P"; do ( cd "$WT" && tar --null -T "$w/enum.nul" -cf - ) | ( cd "$d" && tar -xf - ) || { say 'FAIL extraction'; exit 2; }; done
( cd "$C" && git init -q && git add -A && git -c user.name=m -c user.email=m@invalid commit -qm base ) || { say 'FAIL copy commit'; exit 2; }
printf 'tests/.one-*.sh\n' >> "$C/.git/info/exclude"
EDITED=(scripts/verification-lib.sh scripts/spec-run.sh scripts/spec-task.sh scripts/spec-evidence.sh scripts/spec-ac-coverage.sh scripts/sdd-analyze.sh)

replace() { # <file> <old> <new>: literal, exactly once
  perl -e '
    my ($f, $old, $new) = @ARGV; local $/; open my $h, "<", $f or exit 3; my $t = <$h>; close $h;
    my $n = () = $t =~ /\Q$old\E/g; exit 4 if $n != 1;
    exit 0 if $ENV{DRY} eq "1";
    $t =~ s/\Q$old\E/$new/; open $h, ">", $f or exit 3; print $h $t; close $h; exit 0' "$C/$1" "$2" "$3"
}
judge() { # <test file> <case function> -> exit; output in $w/judge.out
  ( cd "$C" && awk '$0 != "t_run_all"' "tests/$1" > "tests/.one-$1" && bash -c '. "tests/.one-$1"
      SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sddkit.XXXXXX")"; export SANDBOX
      out="$( ( _t_fail=0; "$2"; exit "$_t_fail" ) 2>&1 )"; rc=$?
      [[ ! -s "$SANDBOX/.fixture-build-failed" ]] || { rc=1; out="$out
build-failure record: $(cat "$SANDBOX/.fixture-build-failed")"; }
      rm -rf "$SANDBOX"; printf "%s\n" "$out"; exit "$rc"' _ "$1" "$2" ) > "$w/judge.out" 2>&1
}
restore() {
  ( cd "$C" && git checkout -q -- . && rm -f tests/.one-*.sh ) || return 1
  local f; for f in "${EDITED[@]}"; do
    cmp -s "$C/$f" "$P/$f" || { say "FAIL restore not byte-identical: $f"; fails=$((fails+1)); }
  done
}
row() { # <id> <kind> <diagnostic-or-empty> <test file> <case> <file old new>...
  local id="$1" kind="$2" diag="$3" tf="$4" case="$5" rc; shift 5
  rowi=$((rowi+1)); (( (rowi - 1) % sn == si )) || return 0
  while (( $# )); do
    replace "$1" "$2" "$3"; rc=$?
    verdict "$id literal applies once in $1" 0 "$rc"
    shift 3
  done
  [[ "$DRY" == 1 ]] && { restore; return; }
  judge "$tf" "$case"; rc=$?
  case "$kind" in
    kill)
      verdict "$id KILLED (judge rc)" 1 "$([[ "$rc" != 0 ]] && echo 1 || echo 0)"
      verdict "$id diagnostic: $diag" 1 "$(grep -c -F -- "$diag" "$w/judge.out" | awk '{print ($1 > 0)}')";;
    equiv) verdict "$id SURVIVES as argued (equiv)" 0 "$rc";;
  esac
  [[ "$rc" == 0 || "$kind" == kill ]] || grep -E 'assert:' "$w/judge.out" | head -5 | sed 's/^/  |   /'
  restore
}
VL=scripts/verification-lib.sh
GC=test-gate-contracts.sh; SG=test-spec-gate.sh; SA=test-sdd-analyze.sh; TV=test-verification.sh

say "== baseline shard $SHARD $(date -u +%H:%M:%SZ)"
if [[ "$DRY" != 1 && "$si" == 0 ]]; then
  for j in "$GC report_manifest_locale_cases" "$SG round_locale_cases" "$SG floor_parse_fault_cases" \
           "$SG acceptance_parse_fault_cases" "$SG checkpoint_parse_fault_cases" "$SA analyzer_locale_and_fault_cases" \
           "$TV harness_locale_cases"; do
    judge ${j% *} ${j#* }; verdict "B ${j#* } unmutated passes" 0 "$?"
    grep -E 'assert:' "$w/judge.out" | head -3 | sed 's/^/  |   /'
    restore
  done
fi

say '== the pin'
row K01 kill "ran a program of its own under the caller's locale (O-017)" "$TV" harness_locale_cases \
  "$VL" $'  unset SDD_HARNESS_CALLER_LC_ALL\n}' $'  unset SDD_HARNESS_CALLER_LC_ALL\n}\nvf_locale_pin() { :; }'
row K02 kill "spec-run.sh ran a program of its own under the caller's locale (O-017)" "$TV" harness_locale_cases \
  scripts/spec-run.sh $'. "$HUB_DIR/scripts/verification-lib.sh"\nSPEC_TASK=' $'SPEC_TASK=' \
  scripts/spec-run.sh $'# Versioned capture path is additive; legacy default output/ticking stays below.\n' $'# Versioned capture path is additive; legacy default output/ticking stays below.\n. "$HUB_DIR/scripts/verification-lib.sh"\n'
row K03 kill "a captured command did not get the caller's LC_ALL (en_US.UTF-8) back (O-017)" "$TV" harness_locale_cases \
  "$VL" '(cd "$cwd" && vf_caller_locale && "$@")' '(cd "$cwd" && "$@")'
row K04 kill "the legacy run did not get the caller's LC_ALL back (O-017)" "$TV" harness_locale_cases \
  scripts/spec-run.sh '( cd "$RUN_CWD" && vf_caller_locale && "${CMD[@]}" )' '( cd "$RUN_CWD" && "${CMD[@]}" )'
row K05 kill "two caller values of a declared LC_ALL gave one identity (O-017)" "$TV" harness_locale_cases \
  "$VL" '    vf_caller_env "$key" "$tmp/env-value"; value=$?' $'    if [[ -n "${!key+set}" ]]; then printf \'%s\' "${!key}" > "$tmp/env-value"; value=0; else value=1; fi'
row K06 kill "the record of a declared LC_ALL carried the pin, not the caller's value (O-017)" "$SG" acceptance_parse_fault_cases \
  "$VL" '  if [[ -z "${SDD_HARNESS_CALLER_LC_ALL:-}" || "${LC_ALL-}" != C ]]; then' '  if :; then'
row K07 kill "a captured command did not get the caller's LC_ALL (unset) back (O-017)" "$TV" harness_locale_cases \
  "$VL" $'    set:*) export LC_ALL="${SDD_HARNESS_CALLER_LC_ALL#set:}";;\n  esac\n  unset SDD_HARNESS_CALLER_LC_ALL' $'    set:*) export LC_ALL="${SDD_HARNESS_CALLER_LC_ALL#set:}";;\n  esac'
row K08 kill "spec-ac-coverage.sh read no AC id after an undecodable byte" "$SG" floor_parse_fault_cases \
  scripts/spec-ac-coverage.sh $'. "$HUB_DIR/scripts/verification-lib.sh"\nSYSMAP=' $'SYSMAP=' \
  scripts/spec-ac-coverage.sh $'if [[ -n "$THROUGH_STAGE" ]]; then\n  mkdir' $'if [[ -n "$THROUGH_STAGE" ]]; then\n  . "$HUB_DIR/scripts/verification-lib.sh"\n  mkdir' \
  scripts/spec-ac-coverage.sh 'spec_acs="$(vf_ids '"'"'AC-[0-9]{3}'"'"' "$SPEC_FILE")" || { echo "${RED}✗${RESET} spec.md could not be read for its AC ids" >&2; exit 3; }' 'spec_acs="$(grep -oE '"'"'AC-[0-9]{3}'"'"' "$SPEC_FILE" | sort -u)"'
# E01: spec-task.sh and spec-evidence.sh load the kernel back at their old lines.
# Equivalent: before those lines neither runs a program that reads a byte of the
# spec (spec-task.sh defines functions and parses arguments; spec-evidence.sh
# parses arguments and resolves its directory), so the pin still precedes every
# read. The early load is kept so that property cannot erode by an edit above.
row E01 equiv '' "$TV" harness_locale_cases \
  scripts/spec-task.sh $'. "$HUB_DIR/scripts/verification-lib.sh"\n\nusage()' $'\nusage()' \
  scripts/spec-task.sh $'# A frontmatter that cannot be read is a failure, never the legacy path, which\n' $'. "$HUB_DIR/scripts/verification-lib.sh"\n# A frontmatter that cannot be read is a failure, never the legacy path, which\n' \
  scripts/spec-evidence.sh $'. "$HUB_DIR/scripts/verification-lib.sh"\n\ninit_colors' $'\ninit_colors' \
  scripts/spec-evidence.sh $'# A frontmatter that cannot be read is a failure, never the legacy check.\n' $'. "$HUB_DIR/scripts/verification-lib.sh"\n# A frontmatter that cannot be read is a failure, never the legacy check.\n'

say '== status reads'
row S01 kill 'a manifest pass that died was read as a manifest recording nothing (O-017)' "$GC" report_manifest_locale_cases \
  "$VL" $'    \' "$manifest" > "$tmp" || {\n      printf \'report recovery: %s: prior-review manifest could not be parsed; reconcile canonical records\\n\' "$manifest" >&2; return 3; }\n    records="$(LC_ALL=C sort -u "$tmp")" || return 3\n    [[ -z "$records" ]] || priorids="$priorids${records//$\'\\n\'/ } "' \
        $'    \' "$manifest" > "$tmp"\n    records="$(LC_ALL=C sort -u "$tmp")"\n    [[ -z "$records" ]] || priorids="$priorids${records//$\'\\n\'/ } "'
row S02 kill 'a Decisions parse that died was not refused by name (O-017)' "$SG" round_locale_cases \
  "$VL" $'  \' "$spec/STATUS.md")" || {\n    echo "round authorization denied: $gate round $round: the Decisions log in STATUS.md could not be parsed, so no authorization was read" >&2\n    return 4\n  }' $'  \' "$spec/STATUS.md")"'
row S03 kill 'the configuration policy counted an unreadable frontmatter as no contract (T030o43)' "$SA" analyzer_locale_and_fault_cases \
  "$VL" '  declared="$(vf_fm_count "$spec_dir/spec.md" verification_contract)" || return 1' '  declared="$(frontmatter_block "$spec_dir/spec.md" | grep -c '"'"'^verification_contract:'"'"' || true)"'
row S04 kill 'the configuration policy read an unreadable frontmatter as no contract (T030o43)' "$SA" analyzer_locale_and_fault_cases \
  "$VL" '  contract="$(vf_fm_value "$spec_dir/spec.md" verification_contract)" || return 1' '  contract="$(fm_get "$spec_dir/spec.md" verification_contract)"'
row S05 kill 'the binding parser counted an unreadable frontmatter as no contract (T030o43)' "$SA" analyzer_locale_and_fault_cases \
  "$VL" '  contract_count="$(vf_fm_count "$spec" verification_contract)" || return 1' '  contract_count="$(frontmatter_block "$spec" | grep -c '"'"'^verification_contract:'"'"' || true)"'
row S06 kill 'the binding parser read an unreadable frontmatter as no contract (T030o43)' "$SA" analyzer_locale_and_fault_cases \
  "$VL" '  contract="$(vf_fm_value "$spec" verification_contract)" || return 1' '  contract="$(fm_get "$spec" verification_contract)"'
row S07 kill "an unreadable worktree skipped the gate's mismatch check (T030o43)" "$SG" floor_parse_fault_cases \
  "$VL" '    expected="$(vf_fm_value "$spec/STATUS.md" worktree)" || return 3' '    expected="$(fm_get "$spec/STATUS.md" worktree 2>/dev/null || :)"'
row S08 kill "an unreadable branch skipped the gate's mismatch check (T030o43)" "$SG" floor_parse_fault_cases \
  "$VL" '    branch="$(vf_fm_value "$spec/STATUS.md" branch)" || return 3' '    branch="$(fm_get "$spec/STATUS.md" branch 2>/dev/null || :)"'
row S09 kill 'an unreadable frontmatter sent spec-run.sh down the legacy path (T030o43)' "$SG" acceptance_parse_fault_cases \
  scripts/spec-run.sh 'contract="$(vf_fm_value "$SPEC_DIR/spec.md" verification_contract)" || exit 3' 'contract="$(fm_get "$SPEC_DIR/spec.md" verification_contract 2>/dev/null || :)"'
row S10 kill 'an unreadable frontmatter let spec-task.sh tick a versioned task on --evidence (T030o43)' "$SG" acceptance_parse_fault_cases \
  scripts/spec-task.sh 'CONTRACT="$(vf_fm_value "$SPEC_DIR/spec.md" verification_contract)" || exit 3' 'CONTRACT="$(fm_get "$SPEC_DIR/spec.md" verification_contract 2>/dev/null || :)"'
row S11 kill 'an unreadable frontmatter swapped the current-evidence check for the legacy one (T030o43)' "$SG" floor_parse_fault_cases \
  scripts/spec-evidence.sh $'evidence_contract="$(vf_fm_value "$SPEC_FILE" verification_contract)" || exit 3\nif [[ "${2:-}" == --current || "$evidence_contract" == 1 ]]; then' \
    $'if [[ "${2:-}" == --current || "$(fm_get "$SPEC_FILE" verification_contract 2>/dev/null || :)" == 1 ]]; then'
row S12 kill 'an AC inventory that could not be read read as no uncovered AC (T030o43)' "$SA" analyzer_locale_and_fault_cases \
  "$VL" $'  (( rc < 2 )) || { printf \'error: %s: ids matching %s could not be read\\n\' "$2" "$1" >&2; return 3; }\n' ''
row S13 kill 'an AC inventory that could not be read read as no uncovered AC (T030o43)' "$SA" analyzer_locale_and_fault_cases \
  scripts/sdd-analyze.sh $'spec_acs="$(vf_ids \'AC-[0-9]{3}\' "$spec")" || fail "spec.md could not be read for its AC ids"\nspec_reqs' $'spec_acs=$(grep -oE \'AC-[0-9]{3}\' "$spec" | sort -u)\nspec_reqs'
row S14 kill 'a task reference inventory that could not be read read as no dangling ref (T030o43)' "$SA" analyzer_locale_and_fault_cases \
  scripts/sdd-analyze.sh 'task_refs="$(vf_ids '"'"'(AC|REQ)-[0-9]{3}'"'"' "$tasks")" || fail "tasks.md could not be read for its AC and REQ references"' 'task_refs=$(grep -oE '"'"'(AC|REQ)-[0-9]{3}'"'"' "$tasks" | sort -u)'
row S15 kill 'a marker search that failed read as no marker (T030o43)' "$SA" analyzer_locale_and_fault_cases \
  scripts/sdd-analyze.sh $'nc="$(grep -n \'\\[NEEDS CLARIFICATION\' "$spec" "$plan")"; nc_rc=$?\nif (( nc_rc > 1 )); then' $'nc="$(grep -n \'\\[NEEDS CLARIFICATION\' "$spec" "$plan")"; nc_rc=0\nif (( nc_rc > 1 )); then'
row S16 kill 'an AC inventory that could not be read let spec-ac-coverage.sh find nothing to check (T030o43)' "$SG" floor_parse_fault_cases \
  scripts/spec-ac-coverage.sh 'spec_acs="$(vf_ids '"'"'AC-[0-9]{3}'"'"' "$SPEC_FILE")" || { echo "${RED}✗${RESET} spec.md could not be read for its AC ids" >&2; exit 3; }' 'spec_acs="$(vf_ids '"'"'AC-[0-9]{3}'"'"' "$SPEC_FILE")"'
row S17 kill 'the binding parser read an AC inventory that failed (T030o43)' "$SA" analyzer_locale_and_fault_cases \
  "$VL" '  if ! acs="$(vf_ids '"'"'AC-[0-9]{3}'"'"' "$spec")" || ! reqs="$(vf_ids '"'"'REQ-[0-9]{3}'"'"' "$spec")"; then' '  if ! acs="$(vf_ids '"'"'AC-[0-9]{3}'"'"' "$spec" || :)" || ! reqs="$(vf_ids '"'"'REQ-[0-9]{3}'"'"' "$spec")"; then'
row S18 kill 'a diagnostic count that failed published a catalog carrying errors (T030o43)' "$SA" analyzer_locale_and_fault_cases \
  "$VL" $'  if ! errors="$(awk -F "$us" \'$1=="D" && $2=="error" {n++} END{print n+0}\' "$records")" ||' $'  if ! errors="$(awk -F "$us" \'$1=="D" && $2=="error" {n++} END{print n+0}\' "$records" || :)" ||'
row S19 kill 'a declared name list that could not be sorted left the declared names unhashed (O-017)' "$TV" harness_locale_cases \
  "$VL" $'  } | LC_ALL=C sort -u -o "$tmp/env-names" || { echo \'verification inputs: declared environment names could not be sorted\' >&2; return 3; }' $'  } | LC_ALL=C sort -u -o "$tmp/env-names"'
row S20 kill 'declared directory digests that could not be sorted were hashed anyway (O-017)' "$TV" harness_locale_cases \
  "$VL" '      LC_ALL=C sort -o "$tmp/sorted" "$tmp/extra-hashes" || { echo "verification inputs: declared directory digests could not be sorted: $path" >&2; return 3; }' '      LC_ALL=C sort -o "$tmp/sorted" "$tmp/extra-hashes"'
row S21 kill 'a required-binding sort that failed accepted a return owing FM rows as none (T030o43)' "$SG" acceptance_parse_fault_cases \
  "$VL" $'  LC_ALL=C sort -u -o "$tmp/want" "$tmp/required" || { echo \'return: the required bindings could not be sorted\' >&2; return 3; }' $'  LC_ALL=C sort -u -o "$tmp/want" "$tmp/required"'
row S22 kill 'a returned-binding sort that failed was not refused by name (T030o43)' "$SG" acceptance_parse_fault_cases \
  "$VL" $'  LC_ALL=C sort -o "$tmp/actual" "$tmp/got" || { echo \'return: the returned bindings could not be sorted\' >&2; return 3; }' $'  LC_ALL=C sort -o "$tmp/actual" "$tmp/got"'
row S23 kill 'a task list that could not be read left completed tasks unchecked (T030o43)' "$SG" floor_parse_fault_cases \
  "$VL" $'  bash "$(dirname -- "${BASH_SOURCE[0]}")/spec-task.sh" list "$spec" > "$tmp/tasks" ||\n    { echo \'current evidence: the task list could not be read\' >&2; return 3; }' $'  bash "$(dirname -- "${BASH_SOURCE[0]}")/spec-task.sh" list "$spec" > "$tmp/tasks"'
row S24 kill "a task list that could not be read left completed tasks' Verify unrefreshed (T030o43)" "$SG" floor_parse_fault_cases \
  "$VL" $'  bash "$HUB_DIR/scripts/spec-task.sh" list "$spec" > "$tmp/tasks.tsv" ||\n    { echo \'floor gap: the task list could not be read\' >&2; return 3; }' $'  bash "$HUB_DIR/scripts/spec-task.sh" list "$spec" > "$tmp/tasks.tsv"'
row S25 kill 'criteria that could not be read recorded fewer coverage bindings (T030o43)' "$SG" checkpoint_parse_fault_cases \
  "$VL" $'          ids="$(printf \'%s\\n\' "${fields[8]}" | vf_ids \'AC-[0-9]{3}\' -)" ||\n            { echo "checkpoint coverage: the criteria of ${fields[2]} could not be read" >&2; return 3; }' $'          ids="$(printf \'%s\\n\' "${fields[8]}" | vf_ids \'AC-[0-9]{3}\' -)"'
row S26 kill 'references that could not be read skipped the binding-gap check (T030o43)' "$SG" checkpoint_parse_fault_cases \
  "$VL" $'      refs="$(printf \'%s\\n\' "${fields[8]}" | vf_ids \'(AC|FM|INV)-[0-9]{3}\' -)" ||\n        { echo "checkpoint coverage: the references of $task could not be read" >&2; return 3; }' $'      refs="$(printf \'%s\\n\' "${fields[8]}" | vf_ids \'(AC|FM|INV)-[0-9]{3}\' -)"'
row S27 kill 'task records that could not be parsed read as no ticked tasks (T030o43)' "$SG" floor_parse_fault_cases \
  scripts/spec-evidence.sh $'\' "$TASKS_FILE")" || { fail "tasks.md could not be parsed for its task records"; records=\'\'; }' $'\' "$TASKS_FILE")"'
row S28 kill 'artifact names that could not be searched read as none named (T030o43)' "$SG" floor_parse_fault_cases \
  scripts/spec-evidence.sh $'  (( arts_rc < 2 )) || fail "$id evidence could not be searched for artifact names"\n' ''
row S29 kill 'a class table that could not be computed went missing from the tally (O-017)' "$GC" report_manifest_locale_cases \
  "$VL" $'  \' "$tmp/classes" > "$tmp/class-lines" || { echo \'tally: the class table could not be computed\' >&2; return 3; }' $'  \' "$tmp/classes" > "$tmp/class-lines"'
row S30 kill 'finding observations that could not be counted went missing from the tally (O-017)' "$GC" report_manifest_locale_cases \
  "$VL" $'"$tmp/classes" ||\n    { echo \'tally: the finding observations could not be counted\' >&2; return 3; }' $'"$tmp/classes"'
# E02: the checkpoint's contract read back to fm_get beside the catalog's.
# Equivalent under every fault a fixture can inject: vf_binding_snapshot reads
# the same frontmatter first, through the checked reader, and refuses before the
# checkpoint's own read is reached; only a divergence between two readers of one
# file would show, which is exactly why the checkpoint takes the catalog's value.
row E02 equiv '' "$SG" checkpoint_parse_fault_cases \
  "$VL" '  if [[ "$catalog_contract" == 1 ]]; then' '  if [[ "$(fm_get "$spec/spec.md" verification_contract)" == 1 ]]; then'

say "== done shard $SHARD $(date -u +%H:%M:%SZ) rows=$rowi"
say "t030o43-mutations failures=$fails"
cd "$SP" && rm -rf "$R"
(( fails == 0 ))
