#!/usr/bin/env bash
# Observe exact configuration catalogs and real analyzer/doctor policy.
. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

config_parse() {
  bash -o pipefail -c '. "$1"; vf_config "$2" "$3" "$4"' _ \
    "$SCRIPTS/verification-lib.sh" "$1" "$2" "$3"
}

config_good() {
  cat > "$1" <<'EOF'
stacks: []
base_branch: main
gate_checks:
  - 'printf ''%s\n'' "two  spaces # literal" | cat'
  - 'bash tests/run.sh'
checkpoints:
  Backend:
    - 'false | true'
  Docs: []
reuse_checks: []
verification_tools:
  - 'bash'
verification_inputs:
  - 'fixtures/space name\literal'
verification_environment:
  - 'CI'
  - 'PROJECT_MODE'
EOF
}

test_config_grammar() {
  local spec_dir stack catalog first stage command key val count=0 sample=0
  local malformed doctor_dir doctor_lib expected fixture
  spec_dir="$(make_verification_spec_dir config)"
  stack="$spec_dir/../../stack.yml"
  config_good "$stack"
  catalog="$SANDBOX/catalog"
  run_rc 0 config_parse "$stack" "$spec_dir/tasks.md" "$catalog"
  # AC-011/FM-006: compare exact bytes, including quotes/spaces/hash/backslash.
  expected="$SANDBOX/expected.nul"
  printf '%s\0' gate_checks "" 'printf '\''%s\n'\'' "two  spaces # literal" | cat' \
    gate_checks "" 'bash tests/run.sh' checkpoints Backend 'false | true' > "$expected"
  run_rc 0 cmp "$expected" "$catalog/commands.nul"
  printf '%s\0' 'fixtures/space name\literal' > "$expected"
  run_rc 0 cmp "$expected" "$catalog/inputs.nul"
  printf '%s\0' CI PROJECT_MODE > "$expected"
  run_rc 0 cmp "$expected" "$catalog/environment.nul"
  while IFS= read -r -d '' key && IFS= read -r -d '' val; do
    [[ "$key" != gate_count ]] || assert_eq 2 "$val" 'AC-011: both required commands retained'
    [[ "$key" != stage_validation ]] || assert_eq checked "$val" 'AC-011: actual tasks constrain stages'
    count=$((count+1))
  done < "$catalog/meta.nul"
  assert_eq 3 "$count" 'AC-011: versioned complete metadata'
  assert_eq 0 "$(wc -c < "$catalog/reuse.nul" | tr -d ' ')" 'AC-011: no reuse opt-in'
  run_rc 1 config_parse "$stack" "$spec_dir/tasks.md" "$catalog"
  assert_contains "$OUT" 'fresh catalog' 'AC-011: failed parse cannot claim a prior catalog'

  # AC-011/FM-011: malformed cases name path/line and publish no catalog.
  for malformed in \
    $'gate_checks: [true]' \
    $'gate_checks:\n  - true' \
    $'gate_checks:\n  - "true"' \
    $'gate_checks:\n  - |' \
    $'gate_checks:\n  - >' \
    $'gate_checks:\n  - *alias' \
    $'gate_checks:\n  - &anchor true' \
    $'gate_checks:\n   - \'true\'' \
    $'gate_checks:\n\t- \'true\'' \
    $'gate_checks:\n  - \'unterminated' \
    $'gate_checks:\n  - \'true\'garbage' \
    $'gate_checks:\n  - \'true\' # comment\n  - \'\'' \
    $'gate_checks: []\n  - \'true\'' \
    $'gate_checks: []\ngate_checks: []' \
    $'verification_unknown: []' \
    $'gate_check: []' \
    $'reuse_check: []' \
    $'checkpoints:\n  Unknown:\n    - \'true\'' \
    $'checkpoints:\n  Backend: []\n  Backend: []' \
    $'checkpoints:\n  Backend: []\n    - \'true\'' \
    $'checkpoints:\n    - \'true\'' \
    $'verification_tools: [bash]' \
    $'verification_environment: [CI]' \
    $'verification_environment:\n  - \'bad-name\'' \
    $'verification_environment:\n  - \'1BAD\'' \
    $'gate_checks:\n  - \'$(touch marker)\'' \
    $'gate_checks:\n  - \'$SECRET\'' \
    $'gate_checks:\n  - \'${SECRET}\'' \
    $'gate_checks:\n  - \'true $0\'' \
    $'gate_checks:\n  - \'true $1\'' \
    $'gate_checks:\n  - \'true $?\'' \
    $'gate_checks:\n  - \'true $$\'' \
    $'gate_checks:\n  - \'true $!\'' \
    $'gate_checks:\n  - \'true $-\'' \
    $'gate_checks:\n  - \'true $*\'' \
    $'gate_checks:\n  - \'true $@\'' \
    $'gate_checks:\n  - \'true $#\'' \
    $'gate_checks:\n  - \'true $((1+1))\'' \
    $'reuse_checks:\n  - \'true $1\'' \
    $'verification_tools:\n  - \'bash $1\'' \
    $'verification_inputs:\n  - \'src/$1\'' \
    $'checkpoints:\n  Backend:\n    - \'true $1\'' \
    $'gate_checks:\n  - \'test `date -u +%Y` = 2026\'' \
    $'gate_checks:\n  - \'echo `id -un`\'' \
    $'gate_checks:\n  - \'echo `echo `id -un``\'' \
    $'reuse_checks:\n  - \'test `date -u +%Y` = 2026\'' \
    $'checkpoints:\n  Backend:\n    - \'echo `id -un`\'' \
    $'gate_checks:\n  - \'diff <(date -u +%Y) baseline.txt\'' \
    $'gate_checks:\n  - \'bash tests/run.sh > >(tee log)\'' \
    $'reuse_checks:\n  - \'diff <(date -u +%Y) baseline.txt\'' \
    $'checkpoints:\n  Backend:\n    - \'cat <(date -u +%Y)\'' \
    $'verification_tools:\n  - \'bash <(true)\'' \
    $'verification_inputs:\n  - \'src/<(true)\'' \
    $'gate_checks:\n  - \'ls ~/private\'' \
    $'gate_checks:\n  - \'bash tests/run.sh ~\'' \
    $'verification_inputs:\n  - \'~/fixtures\''; do
    sample=$((sample+1))
    printf '%s\n' "$malformed" > "$stack"
    run_rc 1 config_parse "$stack" "$spec_dir/tasks.md" "$SANDBOX/invalid-$sample"
    assert_contains "$OUT" "$stack:" "AC-011: case $sample names source line"
    [[ ! -e "$SANDBOX/invalid-$sample" ]] || t_fail "AC-011: malformed case $sample published"
  done
  printf 'gate_checks:\n  - '\''true'\''\0\n' > "$stack"
  run_rc 1 config_parse "$stack" "$spec_dir/tasks.md" "$SANDBOX/nul"
  assert_contains "$OUT" 'NUL byte' 'AC-011: authored NUL cannot corrupt the catalog'

  # AC-011/FM-011: a dollar Bash would not expand is a literal, so closing the
  # expansion grammar must not reject an end-anchored pattern or a group.
  cat > "$stack" <<'LITERAL'
gate_checks:
  - 'grep -c ''^ok$'' notes.txt'
  - 'grep -Ec ''(warn$|error)'' notes.txt'
LITERAL
  run_rc 0 config_parse "$stack" "$spec_dir/tasks.md" "$SANDBOX/literal-dollar"
  printf '%s\0' gate_checks "" "grep -c '^ok\$' notes.txt" \
    gate_checks "" "grep -Ec '(warn\$|error)' notes.txt" > "$expected"
  run_rc 0 cmp "$expected" "$SANDBOX/literal-dollar/commands.nul"

  # AC-011/REQ-009: brace expansion is deterministic and stays legal, and a
  # tilde that is not word-initial is a literal character, so neither may be
  # swept up by closing the command-substitution and tilde cases.
  cat > "$stack" <<'DETERMINISTIC'
gate_checks:
  - 'bash tests/run.sh --report a{1,2}.txt'
  - 'grep -c a~b notes.txt'
DETERMINISTIC
  run_rc 0 config_parse "$stack" "$spec_dir/tasks.md" "$SANDBOX/deterministic"
  printf '%s\0' gate_checks "" 'bash tests/run.sh --report a{1,2}.txt' \
    gate_checks "" 'grep -c a~b notes.txt' > "$expected"
  run_rc 0 cmp "$expected" "$SANDBOX/deterministic/commands.nul"

  # AC-011/REQ-009: closing the third spelling of command substitution must not
  # sweep up a plain redirection, which splices no command output.
  cat > "$stack" <<'REDIRECTION'
gate_checks:
  - 'bash tests/run.sh > out.log'
  - 'bash tests/run.sh 2>&1 | tee out.log'
REDIRECTION
  run_rc 0 config_parse "$stack" "$spec_dir/tasks.md" "$SANDBOX/redirection"
  printf '%s\0' gate_checks "" 'bash tests/run.sh > out.log' \
    gate_checks "" 'bash tests/run.sh 2>&1 | tee out.log' > "$expected"
  run_rc 0 cmp "$expected" "$SANDBOX/redirection/commands.nul"

  # AC-011/FM-006: parsing never executes the command. The declared check
  # boundary can execute its unchanged string with real pipeline status.
  printf "gate_checks:\n  - 'touch %s'\n" "$SANDBOX/should-not-exist" > "$stack"
  run_rc 0 config_parse "$stack" "$spec_dir/tasks.md" "$SANDBOX/no-execution"
  [[ ! -e "$SANDBOX/should-not-exist" ]] || t_fail 'AC-011: parser executed a command'
  config_good "$stack"
  while IFS= read -r -d '' first && IFS= read -r -d '' stage && IFS= read -r -d '' command; do
    if [[ "$first" == checkpoints && "$stage" == Backend ]]; then
      run_rc 1 bash -o pipefail -c "$command"
    fi
  done < "$catalog/commands.nul"

  # AC-011: planning/scaffold defers membership, real decomposition enables it.
  printf "gate_checks:\n  - 'true'\ncheckpoints:\n  Future:\n    - 'true'\n" > "$stack"
  run_rc 0 config_parse "$stack" "" "$SANDBOX/plan"
  fixture="$SANDBOX/scaffold.md"
  printf '## Setup\n' > "$fixture"
  run_rc 0 config_parse "$stack" "$fixture" "$SANDBOX/scaffold"
  run_rc 0 "$SCRIPTS/sdd-analyze.sh" "$spec_dir" --phase plan
  run_rc 1 "$SCRIPTS/sdd-analyze.sh" "$spec_dir" --phase tasks
  assert_contains "$OUT" 'unknown checkpoint stage Future'
  printf '\140\140\140markdown\n## Future\n- [ ] **T099** — quoted\n\140\140\140\n' >> "$spec_dir/tasks.md"
  run_rc 1 config_parse "$stack" "$spec_dir/tasks.md" "$SANDBOX/fenced-stage"
  assert_contains "$OUT" 'unknown checkpoint stage Future'
  # AC-011/FM-016: the stage scanner shares the nested-fence grammar. An inner
  # shorter fence or another fence character must not expose a quoted task
  # block as a declared stage.
  printf '\140\140\140\140markdown\n\140\140\140text\n## Future\n- [ ] **T098** — quoted in a nested example\n\140\140\140\n~~~text\n## Future\n- [ ] **T097** — quoted with another fence character\n~~~\n\140\140\140\140\n' >> "$spec_dir/tasks.md"
  run_rc 1 config_parse "$stack" "$spec_dir/tasks.md" "$SANDBOX/nested-fenced-stage"
  assert_contains "$OUT" 'unknown checkpoint stage Future' 'AC-011: a nested-fence example declared a stage'
  # AC-011/FM-016: an HTML-commented task block is quoted too, in the same
  # scanner, including a mid-line opener.
  printf -- '<!--\n## Future\n- [ ] **T095** — quoted in a comment\n-->\n' >> "$spec_dir/tasks.md"
  printf -- 'superseded <!--\n## Future\n- [ ] **T094** — quoted after a mid-line opener\n-->\n' >> "$spec_dir/tasks.md"
  run_rc 1 config_parse "$stack" "$spec_dir/tasks.md" "$SANDBOX/commented-stage"
  assert_contains "$OUT" 'unknown checkpoint stage Future' 'AC-011: a commented task block declared a stage'
  # Control: a real stage after the closed example is recognized again.
  printf '\n## Future\n- [ ] **T096** — real stage after the closed example\n' >> "$spec_dir/tasks.md"
  run_rc 0 config_parse "$stack" "$spec_dir/tasks.md" "$SANDBOX/nested-real-stage"
  # Restore the fixture: the legacy analyzer task scan predates fenced examples.
  spec_dir="$(make_verification_spec_dir config)"

  # AC-011/AC-023: invoke the real doctor project check from a copied script
  # without its final main call, avoiding unrelated home/scheduler operations.
  doctor_dir="$SANDBOX/doctor-kit/scripts"
  mkdir -p "$doctor_dir"
  cp "$SCRIPTS/lib.sh" "$SCRIPTS/verification-lib.sh" "$doctor_dir/"
  doctor_lib="$doctor_dir/sdd-doctor-lib.sh"
  sed '$d' "$SCRIPTS/sdd-doctor.sh" > "$doctor_lib"
  config_good "$stack"
  run_rc 0 "$SCRIPTS/sdd-analyze.sh" "$spec_dir" --phase tasks
  run_rc 0 bash -c '. "$1"; check_project "$2"; exit "$errors"' _ "$doctor_lib" "$spec_dir/../../.."
  assert_contains "$OUT" 'verification command configuration valid'
  printf 'stacks: []\n' > "$stack"
  run_rc 1 "$SCRIPTS/sdd-analyze.sh" "$spec_dir" --phase tasks
  assert_contains "$OUT" 'requires nonempty gate_checks'
  run_rc 1 bash -c '. "$1"; check_project "$2"; exit "$errors"' _ "$doctor_lib" "$spec_dir/../../.."
  assert_contains "$OUT" 'requires nonempty gate_checks'
  sed '/^verification_contract:/d' "$spec_dir/spec.md" > "$spec_dir/spec.md.tmp"
  mv "$spec_dir/spec.md.tmp" "$spec_dir/spec.md"
  run_rc 0 "$SCRIPTS/sdd-analyze.sh" "$spec_dir" --phase tasks
  assert_contains "$OUT" 'legacy configuration has no gate_checks'
  run_rc 0 bash -c '. "$1"; check_project "$2"; exit "$errors"' _ "$doctor_lib" "$spec_dir/../../.."
  assert_contains "$OUT" 'no automatic floor clearance'
  rm "$stack"
  run_rc 0 config_parse "$stack" "" "$SANDBOX/missing"
  printf 'gate_checks: [true]\n' > "$stack"
  run_rc 1 "$SCRIPTS/sdd-analyze.sh" "$spec_dir" --phase tasks
  assert_contains "$OUT" 'expected block list'
}

# AC-020/AC-022 / INV-003: lock ownership survives failed acquisition, errors
# and signals; no reader can mistake incomplete publication for a capture.
test_owned_transactions() {
  local spec="$SANDBOX/spec" lib="$SCRIPTS/verification-lib.sh"
  mkdir -p "$spec/notes/verification/lock"
  printf 'foreign-owner\n' > "$spec/notes/verification/lock/owner"
  run_rc 3 bash -c '. "$1"; vf_writer_init; vf_lock "$2"' _ "$lib" "$spec"
  assert_eq foreign-owner "$(cat "$spec/notes/verification/lock/owner")"
  rm -rf "$spec/notes/verification/lock"
  run_rc 7 bash -c '. "$1"; vf_writer_init; vf_lock "$2" || exit; exit 7' _ "$lib" "$spec"
  [[ ! -e "$spec/notes/verification/lock" ]] || t_fail 'AC-022: owned lock leaked on failure'
  run_rc 143 bash -c '. "$1"; vf_writer_init; vf_lock "$2" || exit; kill -TERM $$; exit 9' _ "$lib" "$spec"
  [[ ! -e "$spec/notes/verification/lock" ]] || t_fail 'AC-022: owned lock leaked on signal'
  run_rc 0 bash -c '. "$1"; vf_writer_init; vf_lock "$2" || exit; printf replacement > "$VF_LOCK_PATH/owner"' _ "$lib" "$spec"
  assert_eq replacement "$(cat "$spec/notes/verification/lock/owner")" 'AC-022: replaced owner survives cleanup'
  mkdir "$SANDBOX/staging"
  printf full-log > "$SANDBOX/staging/output.log"
  run_rc 3 bash -c '. "$1"; vf_publish "$2" "$3" output.log' _ "$lib" "$SANDBOX/staging" "$SANDBOX/final"
  [[ ! -e "$SANDBOX/final" ]] || t_fail 'AC-020: incomplete publication became visible'
  run_rc 0 bash -c '. "$1"; vf_seal "$2" output.log && vf_publish "$2" "$3" output.log && vf_integrity "$3" output.log' _ "$lib" "$SANDBOX/staging" "$SANDBOX/final"
  printf damaged >> "$SANDBOX/final/output.log"
  run_rc 3 bash -c '. "$1"; vf_integrity "$2" output.log' _ "$lib" "$SANDBOX/final"
}

snapshot_fixture() {
  bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ "$SCRIPTS/verification-lib.sh" "$1" "$2" "$3"
}

# AC-020: every semantic input class invalidates; bookkeeping alone does not.
test_capture_provenance() {
  local spec repo baseline changed declared path
  spec="$(make_verification_git_dir snapshot)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  baseline="$OUT"
  for path in src/parser.sh tests/check.sh lockfile config.yml 'untracked name'; do
    printf changed >> "$repo/$path"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
    [[ "$OUT" != "$baseline" ]] || t_fail "AC-020: mutation missed: $path"
    git -C "$repo" checkout -- "$path" 2>/dev/null || rm "$repo/$path"
  done
  printf changed >> "$repo/src/parser.sh"
  git -C "$repo" add src/parser.sh
  git -C "$repo" show HEAD:src/parser.sh > "$repo/src/parser.sh"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  [[ "$OUT" != "$baseline" ]] || t_fail 'AC-020: staged-only mutation missed'
  git -C "$repo" reset -q HEAD -- src/parser.sh
  chmod +x "$repo/src/parser.sh"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  [[ "$OUT" != "$baseline" ]] || t_fail 'AC-020: executable mode missed'
  chmod -x "$repo/src/parser.sh"
  mkdir -p "$spec/notes/captures/CAP-dummy" "$spec/notes/verification"
  printf bookkeeping > "$spec/notes/evidence.md"
  printf bookkeeping > "$spec/notes/captures/CAP-dummy/output.log"
  printf bookkeeping > "$spec/notes/opponent.md"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  assert_eq "$baseline" "$OUT" 'AC-020: generated bookkeeping stays reusable'
  sed 's/^- \[ \] /- [x] /' "$spec/tasks.md" > "$SANDBOX/tasks"
  cp "$SANDBOX/tasks" "$spec/tasks.md"
  printf '  - *Evidence:* generated capture\n' >> "$spec/tasks.md"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  assert_eq "$baseline" "$OUT" 'AC-020: checkbox/evidence bookkeeping excluded'
  printf '\n## Decisions log\n- preserve this semantic decision\n' >> "$spec/STATUS.md"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  [[ "$OUT" != "$baseline" ]] || t_fail 'AC-020: STATUS decision omitted'
  changed="$OUT"
  # AC-016/AC-020: undeclared process-local variables are outside the closed
  # input set. The harness effort setting varies between independent gate
  # invocations and must not turn a byte-identical worktree into stale proof.
  run_rc 0 env CLAUDE_EFFORT=fixture-only bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/manifest"
  assert_eq "$changed" "$OUT" 'AC-016: undeclared harness environment changed source identity'
  # O-010 round 4: the fixture above picked ONE undeclared name, and the family
  # whose membership still came from the ambient process survived it for two
  # rounds. LC_CTYPE and LC_ALL are the names macOS Terminal, OpenSSH SendEnv
  # and most CI images export by default, so they are exactly the ones a second
  # process differs by -- and the fixed names once hashed beside the declaration
  # are read by no check for its result. Membership is the declaration alone.
  local undeclared
  for undeclared in LC_CTYPE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LC_TELEPHONE=en_US.UTF-8 \
                    LC_UNKNOWN_CATEGORY=1 LANG=C SHELL=/bin/zsh TMPDIR="$SANDBOX/alt-tmp/"; do
    mkdir -p "$SANDBOX/alt-tmp"
    run_rc 0 env "$undeclared" bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/manifest"
    assert_eq "$changed" "$OUT" "AC-016: undeclared $undeclared changed source identity across invocations"
  done
  # PATH is pinned far more precisely by the tool and harness records, so a
  # reordering that changes no resolved binary must not invalidate proof.
  run_rc 0 env PATH="/usr/bin:$PATH" bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/manifest"
  assert_eq "$changed" "$OUT" 'AC-016: a reordered PATH invalidated a byte-identical worktree'
  # A project can add a real environment dependency explicitly. Presence and
  # value then affect identity, while only the value hash reaches the manifest.
  printf "verification_environment:\n  - 'VF_TEST_SECRET'\n" >> "$repo/.specify/stack.yml"
  run_rc 0 env VF_TEST_SECRET=not-persisted bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/manifest"
  declared="$OUT"
  assert_not_contains "$(tr '\000' '\n' < "$SANDBOX/manifest")" not-persisted
  run_rc 0 env VF_TEST_SECRET=changed-value bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/manifest"
  [[ "$OUT" != "$declared" ]] || t_fail 'AC-020: declared environment change omitted'
  assert_not_contains "$(tr '\000' '\n' < "$SANDBOX/manifest")" changed-value
  sed '/^verification_environment:/,$d' "$repo/.specify/stack.yml" > "$SANDBOX/stack-without-environment"
  cp "$SANDBOX/stack-without-environment" "$repo/.specify/stack.yml"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  assert_eq "$changed" "$OUT" 'AC-020: removing the declaration did not restore the closed input set'
  ln -s src/parser.sh "$repo/link"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  [[ "$OUT" != "$changed" ]] || t_fail 'AC-020: symlink omitted'
  # AC-020: ignored declarations, odd filenames and tool content are inputs.
  printf 'ignored/\n' > "$repo/.gitignore"
  mkdir "$repo/ignored"
  printf first > "$repo/ignored/tool"
  chmod +x "$repo/ignored/tool"
  printf "verification_inputs:\n  - 'ignored'\n" > "$SANDBOX/declared"
  sed '/^verification_inputs:/d' "$repo/.specify/stack.yml" > "$SANDBOX/stack"
  cat "$SANDBOX/stack" "$SANDBOX/declared" > "$repo/.specify/stack.yml"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  changed="$OUT"
  printf second > "$repo/ignored/tool"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  [[ "$OUT" != "$changed" ]] || t_fail 'AC-020: ignored declared input missed'
  changed="$OUT"
  printf odd > "$repo/line
break"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  [[ "$OUT" != "$changed" ]] || t_fail 'AC-020: newline path missed'
  changed="$OUT"
  printf semantic >> "$spec/plan.md"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  [[ "$OUT" != "$changed" ]] || t_fail 'AC-020: plan semantic change missed'


  # AC-020: working directory and declared tool bytes are independent inputs.
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/cwd-before"
  changed="$OUT"
  run_rc 0 bash -c '. "$1"; vf_snapshot "$2" "$3" "$3/src" "$4"' _ "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/cwd-after"
  [[ "$OUT" != "$changed" ]] || t_fail 'AC-020: cwd change missed'
  mkdir "$SANDBOX/tool-bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$SANDBOX/tool-bin/probe-tool"
  chmod +x "$SANDBOX/tool-bin/probe-tool"
  awk '{print} /^verification_tools:/ {printf "  - %cprobe-tool%c\n",39,39}' "$repo/.specify/stack.yml" > "$SANDBOX/tool-stack"
  cp "$SANDBOX/tool-stack" "$repo/.specify/stack.yml"
  run_rc 0 env PATH="$SANDBOX/tool-bin:$PATH" bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/tool-before"
  changed="$OUT"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$SANDBOX/tool-bin/probe-tool"
  run_rc 0 env PATH="$SANDBOX/tool-bin:$PATH" bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/tool-after"
  [[ "$OUT" != "$changed" ]] || t_fail 'AC-020: declared executable mutation missed'
  capture_validity_cases

}

capture_check_fixture() {
  bash -c '. "$1"; vf_capture_check "$2" "$3" "$4" "$5"' _ "$SCRIPTS/verification-lib.sh" "$@"
}

capture_validity_cases() {
  local spec repo cap later before file
  spec="$(make_verification_git_dir validity)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/current"
  run_rc 0 capture_check_fixture "$spec" "$cap" "$SANDBOX/current" current
  for file in output.log COMPLETE argv.nul inputs.nul bindings.nul meta.nul; do
    cp "$spec/notes/captures/$cap/$file" "$SANDBOX/saved"
    printf tampered >> "$spec/notes/captures/$cap/$file"
    run_rc 3 capture_check_fixture "$spec" "$cap" "$SANDBOX/current" current
    cp "$SANDBOX/saved" "$spec/notes/captures/$cap/$file"
  done
  mv "$spec/notes/captures/$cap/output.log" "$SANDBOX/log"
  run_rc 3 capture_check_fixture "$spec" "$cap" "$SANDBOX/current" current
  mv "$SANDBOX/log" "$spec/notes/captures/$cap/output.log"
  # AC-023: historical completion survives a stale proof rejection.
  # Seed historical completion, as if accepted before the guarded writer existed.
  sed 's/^- \[ \] \*\*T001\*\*/- [x] **T001**/' "$spec/tasks.md" > "$SANDBOX/historical-tasks"
  cp "$SANDBOX/historical-tasks" "$spec/tasks.md"
  before="$(cat "$spec/tasks.md")"
  printf 'value=bad\n' > "$repo/src/parser.sh"
  run_rc 0 capture_check_fixture "$spec" "$cap" '' integrity
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/current"
  run_rc 3 capture_check_fixture "$spec" "$cap" "$SANDBOX/current" current
  assert_contains "$OUT" 'current inputs changed'
  run_rc 3 "$SCRIPTS/spec-evidence.sh" "$spec"
  assert_eq "$before" "$(cat "$spec/tasks.md")"
  # AC-020: a command mutating its own inputs cannot create current proof.
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --no-tick --summary -- bash -c 'echo changed >> src/parser.sh'
  later="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/current"
  run_rc 3 capture_check_fixture "$spec" "$later" "$SANDBOX/current" current
  assert_contains "$OUT" 'inputs changed during execution'
  # AC-020: external state has no reuse policy; its later failed observation
  # nevertheless supersedes an older same-input success for initial acceptance.
  printf 'value=good\n' > "$repo/src/parser.sh"
  printf '\n[[ ! -f ../switch ]] || exit 9\n' >> "$repo/tests/check.sh"
  sed 's/Reuse:\* local/Reuse:* never/' "$spec/tasks.md" > "$SANDBOX/tasks"
  cp "$SANDBOX/tasks" "$spec/tasks.md"
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/current"
  run_rc 3 capture_check_fixture "$spec" "$cap" "$SANDBOX/current" reuse
  assert_contains "$OUT" 'policy requires execution'
  touch "$repo/../switch"
  run_rc 9 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  run_rc 3 capture_check_fixture "$spec" "$cap" "$SANDBOX/current" current
  assert_contains "$OUT" 'later failed run'
}

t_run_all
