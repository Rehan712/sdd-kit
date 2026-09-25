#!/usr/bin/env bash
# Run from the spec worktree. All mutations are isolated from live source.
set -uo pipefail
repair_root="$PWD"
repair_tmp="$(mktemp -d /private/tmp/sdd003-mutations.XXXXXX)" || exit 1
mkdir "$repair_tmp/scripts"
cp scripts/*.sh "$repair_tmp/scripts/"
cp scripts/verification-lib.sh "$repair_tmp/library.original"
cp tests/test-gate-contracts.sh "$repair_tmp/tests.original"
cp "$repair_tmp/tests.original" "$repair_tmp/tests.sh"
repair_lib="$repair_tmp/scripts/verification-lib.sh"
repair_tests="$repair_tmp/tests.sh"
repair_failed=0
run_case() (
  . "$repair_root/tests/helpers.sh"
  eval "$(sed '1,5d; /^t_run_all$/d' "$repair_tests")"
  SCRIPTS="$repair_tmp/scripts"
  SANDBOX="$(mktemp -d "$repair_tmp/case.XXXXXX")" || exit 1
  "$1"
  exit "$_t_fail"
)
for mutation in baseline round-first round-last round-all-blocking manifest-first tally-first tally-last tally-all-blocking forbid-recharacterisation d1-no-collapse d1-no-negation cli-old-reader cli-no-open-paren cli-narrow-verbs cli-silent-clause cli-no-pattern-check cli-no-catchall-check cli-no-synopsis cli-no-detail cli-no-readme; do
  cp "$repair_tmp/library.original" "$repair_lib"
  cp "$repair_tmp/tests.original" "$repair_tests"
  family=report_severity_tier_cases
  case "$mutation" in
    round-first) perl -0pi -e 's/ \|\| sev !~ \/\^\(minor\|degraded\)\$\///' "$repair_lib";;
    round-last) perl -0pi -e 's/if \(!\(fid in firsttier\) \|\| sev !~ \/\^\(minor\|degraded\)\$\//if (1/' "$repair_lib";;
    round-all-blocking) perl -0pi -e 's/firsttier\[fid\]=\(sev ~ \/\^\(minor\|degraded\)\$\/\) \? "minor" : "blocking"/firsttier[fid]="blocking"/' "$repair_lib";;
    manifest-first) perl -0pi -e 's/ \|\| manifesttier=="blocking"//' "$repair_lib";;
    tally-first) perl -0pi -e 's/ \|\| tier\(\$6\)=="blocking"//' "$repair_lib";;
    tally-last) perl -0pi -e 's/if\(!\(k in first\) \|\| tier\(\$6\)=="blocking"\)/if(1)/' "$repair_lib";;
    tally-all-blocking) perl -0pi -e 's/first\[k\]=tier\(\$6\)/first[k]="blocking"/' "$repair_lib";;
    forbid-recharacterisation) perl -0pi -e 's/gate=="opponent" && verdict=="CLEARED" && downgraded/gate=="opponent" \&\& downgraded/' "$repair_lib";;
    d1-no-collapse) family=superseded_environment_cases; sed '/gsub(\/\[\[:space:\]\]+\/, " ", stream)/d' "$repair_tests" > "$repair_tmp/edited"; cp "$repair_tmp/edited" "$repair_tests";;
    d1-no-negation) family=superseded_environment_cases; perl -0pi -e 's/if \(!negated\(gap\)\)/if (1)/g' "$repair_tests";;
    cli-old-reader) family=gate_dispatch_grammar_cases; perl -0pi -e 's/gate_dispatch_verbs\(\) \{.*?\n\}/gate_dispatch_verbs() {\n  awk '\''\/^case "\\\$command_name" in\$\/ {on=1; next} on \&\& \/^esac\$\/ {on=0} on \&\& \/^  [a-z][a-z-]*\\)\/ {v=\$1; sub(\/\\).*\/,"",v); print v}'\'' "\$1"\n}/s' "$repair_tests";;
    cli-no-open-paren) family=gate_dispatch_grammar_cases; perl -0pi -e 's/^      sub\([^\n]*"", line\)\n//m' "$repair_tests";;
    cli-narrow-verbs) family=gate_dispatch_grammar_cases; perl -0pi -e 's/\[A-Za-z0-9_\.\\\/:\+\@%=-\]/[a-z-]/' "$repair_tests";;
    cli-silent-clause) family=gate_dispatch_grammar_cases; perl -0pi -e 's/if\(body !~ \/;;\$\/\) fail\(\)/if(body !~ \/;;\$\/) next/' "$repair_tests";;
    cli-no-pattern-check) family=gate_dispatch_grammar_cases; sed '/if(verb !~/d' "$repair_tests" > "$repair_tmp/edited"; cp "$repair_tmp/edited" "$repair_tests";;
    cli-no-catchall-check) family=gate_dispatch_grammar_cases; sed '/if(body !=/d' "$repair_tests" > "$repair_tmp/edited"; cp "$repair_tmp/edited" "$repair_tests";;
    cli-no-synopsis) family=gate_dispatch_grammar_cases; sed '/assert_eq "\$derived" "\$synopsis"/d' "$repair_tests" > "$repair_tmp/edited"; cp "$repair_tmp/edited" "$repair_tests";;
    cli-no-detail) family=gate_dispatch_grammar_cases; sed '/assert_contains "\$OUT" "  \$verb <spec-dir>"/d' "$repair_tests" > "$repair_tmp/edited"; cp "$repair_tmp/edited" "$repair_tests";;
    cli-no-readme) family=gate_dispatch_grammar_cases; perl -0pi -e 's/    assert_contains "\$readme" "spec-gate.sh \$verb " \\\n      "AC-018: spec-gate.sh \$verb appears in no operator-facing document"\n//' "$repair_tests";;
  esac
  if [[ "$mutation" != baseline ]] && cmp -s "$repair_lib" "$repair_tmp/library.original" && cmp -s "$repair_tests" "$repair_tmp/tests.original"; then
    printf 'NOT APPLIED %s\n' "$mutation"; repair_failed=1; continue
  fi
  if ! bash -n "$repair_lib" "$repair_tests"; then printf 'INVALID MUTATION %s\n' "$mutation"; repair_failed=1; continue; fi
  run_case "$family" > "$repair_tmp/$mutation.log" 2>&1
  repair_rc=$?
  if [[ "$mutation" == baseline ]]; then expected=0; else expected=1; fi
  if [[ "$repair_rc" == "$expected" ]] && { [[ "$expected" == 0 ]] || grep -q '^assert:' "$repair_tmp/$mutation.log"; }; then
    printf 'PASS %s rc=%s\n' "$mutation" "$repair_rc"
    if [[ "$expected" == 1 ]]; then sed -n '/^assert:/p' "$repair_tmp/$mutation.log" | head -3; fi
  else printf 'SURVIVED OR INVALID %s rc=%s log=%s\n' "$mutation" "$repair_rc" "$repair_tmp/$mutation.log"; repair_failed=1; fi
  cp "$repair_tmp/library.original" "$repair_lib"
  cp "$repair_tmp/tests.original" "$repair_tests"
  cmp "$repair_lib" "$repair_tmp/library.original" || exit 1
  cmp "$repair_tests" "$repair_tmp/tests.original" || exit 1
done
cmp scripts/verification-lib.sh "$repair_tmp/library.original" || exit 1
cmp tests/test-gate-contracts.sh "$repair_tmp/tests.original" || exit 1
printf 'byte-identical restore/live comparison complete; artifacts=%s exit=%s\n' "$repair_tmp" "$repair_failed"
exit "$repair_failed"
