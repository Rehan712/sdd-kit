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
    fixture_git -C "$repo" checkout -- "$path" 2>/dev/null || rm "$repo/$path"
  done
  printf changed >> "$repo/src/parser.sh"
  fixture_git -C "$repo" add src/parser.sh
  git -C "$repo" show HEAD:src/parser.sh > "$repo/src/parser.sh"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/manifest"
  [[ "$OUT" != "$baseline" ]] || t_fail 'AC-020: staged-only mutation missed'
  fixture_git -C "$repo" reset -q HEAD -- src/parser.sh
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
  bookkeeping_anchor_cases
  outside_layout_anchor_cases
  kit_copy_cases
  reuse_command_input_cases
  fixture_repository_cases

}

# O-015 review: the reuse-checked commands themselves read only what the input
# identity hashes. In a host kit, tests/run.sh never runs an ignored local
# suite; tests/shellcheck.sh never lints an ignored local script and reads
# neither SHELLCHECK_OPTS nor a .shellcheckrc outside the kit; and a suite
# starts with the kit's own SDD_* knobs and XDG_STATE_HOME cleared.
reuse_command_input_cases() {
  local host="$SANDBOX/host-kit" swapped foreign before base spec repo lib="$SCRIPTS/verification-lib.sh"
  make_host_kit "$host" || t_fail 'AC-020: cannot build the host kit'
  printf 'tests/test-zz-local.sh\nscripts/zz-local.sh\n' >> "$host/.git/info/exclude"
  printf '#!/usr/bin/env bash\necho local-suite-ran\nexit 1\n' > "$host/tests/test-zz-local.sh"
  run_rc 2 bash "$host/tests/run.sh" zz-local
  assert_contains "$OUT" "no test file matches 'zz-local'" 'AC-020: tests/run.sh ran an ignored local suite'
  assert_not_contains "$OUT" 'local-suite-ran' 'AC-020: tests/run.sh ran an ignored local suite'
  # Second review: run as `bash tests/...` from the kit root, each command
  # resolves its own directory with a relative cd, which an exported CDPATH
  # would redirect and print into the substitution.
  run_rc 2 env CDPATH=. bash -c 'cd "$1" && bash tests/run.sh zz-none' _ "$host"
  assert_contains "$OUT" "no test file matches 'zz-none'" 'AC-020: an exported CDPATH decided tests/run.sh'
  if command -v shellcheck > /dev/null 2>&1; then
    printf '#!/usr/bin/env bash\nunused_value=1\ncd /tmp\n' > "$host/scripts/zz-local.sh"
    # The host kit's parent is the sandbox, so ShellCheck's upward rc search
    # would reach this file without --norc.
    printf 'enable=check-unassigned-uppercase\n' > "$SANDBOX/.shellcheckrc"
    run_rc 0 env CDPATH=. SHELLCHECK_OPTS='--enable=check-unassigned-uppercase' \
      bash -c 'cd "$1" && bash tests/shellcheck.sh' _ "$host"
    assert_not_contains "$OUT" 'zz-local.sh' 'AC-020: tests/shellcheck.sh linted an ignored local script'
    # Control: once enumerated, the same script IS linted, so the probe is live.
    sed '/^scripts\/zz-local\.sh$/d' "$host/.git/info/exclude" > "$SANDBOX/exclude" && cat "$SANDBOX/exclude" > "$host/.git/info/exclude"
    run_rc 1 bash "$host/tests/shellcheck.sh"
    assert_contains "$OUT" 'scripts/zz-local.sh' 'AC-020: tests/shellcheck.sh did not lint an enumerated script'
    rm -f "$SANDBOX/.shellcheckrc"
  fi
  run_rc 0 env SDD_RESUME_JITTER_SECONDS=301 XDG_STATE_HOME="$SANDBOX/ambient-state" \
    bash -c '. "$1/tests/helpers.sh"; [[ -z "${SDD_RESUME_JITTER_SECONDS+set}${XDG_STATE_HOME+set}" ]]' _ "$KIT_DIR"
  # Git's repository-local names are cleared when a suite starts, judged where
  # that happens (review 6: fixture_git now clears them for its own writes, so
  # the nested-build assertion below no longer sees this clearing). Every name
  # git lists is exported with a value first.
  local localenv name
  localenv=()
  for name in $(git rev-parse --local-env-vars); do localenv+=("$name=$SANDBOX/ambient-$name"); done
  run_rc 0 env "${localenv[@]}" bash -c '. "$1/tests/helpers.sh"
    for n in $(git rev-parse --local-env-vars); do [[ -z "${!n+set}" ]] || { echo "still set after load: $n"; exit 1; }; done' _ "$KIT_DIR"
  assert_not_contains "$OUT" 'still set after load' "AC-020: a suite kept git's repository-local environment"

  # Second review: a suite enumerates under the configuration the identity
  # enumerates under. An ignore rule git reaches through XDG_CONFIG_HOME hides
  # a non-executable script from the identity, so it is hidden inside the suite
  # too (clearing XDG_CONFIG_HOME exposed it). All of git's global and system
  # configuration is pinned (git_config_pinned), so no configuration of the
  # user's can replace the rule: review 3 found that pinning HOME and the
  # system file alone left an exported GIT_CONFIG_GLOBAL free to name its own
  # core.excludesFile. Every pinned input that can be planted is exported
  # here naming exactly that -- GIT_CONFIG_GLOBAL, GIT_CONFIG_SYSTEM and a HOME
  # whose .gitconfig does it (review 4) -- so the pin is proven rather than
  # assumed. The system file itself cannot be planted from a sandbox. The same
  # run goes through a relative cd under CDPATH, which helpers.sh must clear
  # before it resolves the kit.
  # (The ShellCheck control above left scripts/zz-local.sh enumerated and
  # non-executable; it is not this probe.)
  rm -f "$host/scripts/zz-local.sh"
  mkdir -p "$SANDBOX/xdg/git" "$SANDBOX/xdg-home" "$SANDBOX/replacing-config/home"
  printf 'scripts/zz-xdg.sh\n' > "$SANDBOX/xdg/git/ignore"
  printf 'echo local\n' > "$host/scripts/zz-xdg.sh"; chmod 644 "$host/scripts/zz-xdg.sh"
  : > "$SANDBOX/replacing-config/empty-ignore"
  printf '[core]\n\texcludesFile = %s\n' "$SANDBOX/replacing-config/empty-ignore" > "$SANDBOX/replacing-config/gitconfig"
  cp "$SANDBOX/replacing-config/gitconfig" "$SANDBOX/replacing-config/home/.gitconfig"
  HOME="$SANDBOX/replacing-config/home" \
    GIT_CONFIG_GLOBAL="$SANDBOX/replacing-config/gitconfig" GIT_CONFIG_SYSTEM="$SANDBOX/replacing-config/gitconfig" \
    run_rc 0 git_config_pinned "$SANDBOX/xdg-home" "$SANDBOX/xdg" \
    bash -c '. "$1"; vf_source_paths "$2" "$3" && tr "\0" "\n" < "$3"' _ "$lib" "$host" "$SANDBOX/xdg-list"
  assert_not_contains "$OUT" 'zz-xdg.sh' 'AC-020: precondition: the XDG ignore rule does not hide the script from the identity'
  HOME="$SANDBOX/replacing-config/home" \
    GIT_CONFIG_GLOBAL="$SANDBOX/replacing-config/gitconfig" GIT_CONFIG_SYSTEM="$SANDBOX/replacing-config/gitconfig" \
    run_rc 0 git_config_pinned "$SANDBOX/xdg-home" "$SANDBOX/xdg" env CDPATH=. \
    bash -c 'cd "$1" && bash tests/test-executable-bits.sh' _ "$host"
  assert_not_contains "$OUT" 'zz-xdg.sh' "AC-020: a suite read a script the identity's git configuration ignores"
  rm -f "$host/scripts/zz-xdg.sh"

  # Second review: the root is accepted by directory identity, not spelling.
  # Where the filesystem folds case, a case-variant spelling of the kit path
  # names the kit, and both commands enumerate it.
  if bash -c '. "$1"; vf_case_folds "$2"' _ "$lib" "$SANDBOX"; then
    swapped="$(dirname "$host")/$(basename "$host" | tr 'a-z' 'A-Z')"
    run_rc 2 bash "$swapped/tests/run.sh" zz-none
    assert_contains "$OUT" "no test file matches 'zz-none'" 'AC-020: tests/run.sh refused a case-variant spelling of the kit path'
  fi

  # Second review (F4): git's repository-local environment. A hook exports
  # GIT_INDEX_FILE or GIT_DIR; the kernel names a repository by its path
  # alone, so neither redirects the enumeration, and a suite clears them, so
  # no fixture's git writes the caller's index.
  git_host "$SANDBOX/foreign" || t_fail 'AC-020: cannot build the foreign repository'
  printf 'x\n' > "$SANDBOX/foreign/only-in-foreign.md"
  fixture_git -C "$SANDBOX/foreign" add only-in-foreign.md
  foreign="$SANDBOX/foreign-index"; cp "$SANDBOX/foreign/.git/index" "$foreign"
  before="$(cksum < "$foreign")"
  run_rc 0 env GIT_INDEX_FILE="$foreign" \
    bash -c '. "$1"; vf_source_paths "$2" "$3" && tr "\0" "\n" < "$3"' _ "$lib" "$host" "$SANDBOX/foreign-list"
  assert_not_contains "$OUT" 'only-in-foreign.md' 'AC-020: an exported GIT_INDEX_FILE redirected the enumeration to a foreign index'
  assert_contains "$OUT" 'tests/run.sh' 'AC-020: the enumeration under an exported GIT_INDEX_FILE lost the kit'
  run_rc 0 env GIT_DIR="$SANDBOX/no-such-git-dir" \
    bash -c '. "$1"; vf_source_paths "$2" "$3" && tr "\0" "\n" < "$3"' _ "$lib" "$host" "$SANDBOX/gitdir-list"
  assert_contains "$OUT" 'tests/run.sh' 'AC-020: an exported GIT_DIR redirected the enumeration'
  # The identity itself: every git process vf_snapshot runs goes without them,
  # so a foreign index changes none of its records, and a GIT_DIR naming no
  # repository neither stops the root check nor moves the identity.
  spec="$(make_verification_git_dir foreign-snap)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/snap-base"
  base="$OUT"
  GIT_INDEX_FILE="$foreign" run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/snap-foreign"
  assert_eq "$base" "$OUT" 'AC-020: an exported GIT_INDEX_FILE changed the input identity'
  GIT_DIR="$SANDBOX/no-such-git-dir" run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/snap-gitdir"
  assert_eq "$base" "$OUT" 'AC-020: an exported GIT_DIR stopped or moved the input identity'
  # Review 3: only git's own processes go without them. A project whose check
  # reads one of these names declares it, and the snapshot then hashes its
  # ambient value like any declared name: clearing them for the whole snapshot
  # recorded a declared name as unset whatever its value.
  printf "verification_environment:\n  - 'GIT_PREFIX'\n" >> "$repo/.specify/stack.yml"
  GIT_PREFIX=one/ run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/snap-prefix-one"
  base="$OUT"
  GIT_PREFIX=two/ run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/snap-prefix-two"
  [[ "$OUT" != "$base" ]] || t_fail 'AC-020: two values of a declared git repository-local variable gave one identity'
  assert_contains "$(tr '\000' '\n' < "$SANDBOX/snap-prefix-two")" $'environment\nGIT_PREFIX\npresent' \
    'AC-020: a declared git repository-local variable was recorded as unset'
  mkdir -p "$SANDBOX/nested"
  run_rc 0 env GIT_INDEX_FILE="$foreign" \
    bash -c '. "$1/tests/helpers.sh"; SANDBOX="$2"; make_verification_git_dir nested > /dev/null' _ "$KIT_DIR" "$SANDBOX/nested"
  assert_eq "$before" "$(cksum < "$foreign")" "AC-020: a fixture's git wrote the caller's index through an inherited GIT_INDEX_FILE"

  # Second review: git creates .git/info only from a template directory, and
  # fixture_git's is empty (review 4), so git_host creates it for the fixtures'
  # ignore rules, whatever template the caller exports.
  mkdir -p "$SANDBOX/empty-template"
  GIT_TEMPLATE_DIR="$SANDBOX/empty-template" git_host "$SANDBOX/no-template-host"
  [[ -d "$SANDBOX/no-template-host/.git/info" ]] \
    || t_fail 'AC-020: a host repository made without git templates has no .git/info for its ignore rules'
}

# O-015 review 4: a fixture builds its own repositories through fixture_git,
# under a pinned, empty configuration and template. Configuration outside the
# repository -- a global core.hooksPath that rejects, commit signing that
# fails, a template's active hook or info/exclude -- used to decide whether
# make_verification_git_dir's repository had a commit, and nothing noticed;
# test_capture_provenance then failed with the input identity unchanged.
fixture_repository_cases() {
  local hostile="$SANDBOX/hostile-git" raw="$SANDBOX/hostile-raw" failing="$SANDBOX/failing-sandbox" shim="$SANDBOX/fixture-failing-git" spec repo printed
  mkdir -p "$hostile/hooks" "$hostile/home" "$hostile/xdg/git" "$hostile/template/hooks" "$hostile/template/info" \
    "$hostile/quarantine" "$raw" "$failing" "$shim"
  printf '#!/bin/sh\necho "hostile hook: commit rejected" >&2\nexit 1\n' > "$hostile/hooks/pre-commit"
  chmod +x "$hostile/hooks/pre-commit"
  cp -p "$hostile/hooks/pre-commit" "$hostile/template/hooks/pre-commit"
  printf '*\n' > "$hostile/template/info/exclude"
  printf '* filter=reject\n' > "$hostile/attributes"
  # Configuration that reaches every step a fixture build takes: hooks and
  # signing (commit), line endings (checkout) and a required clean filter that
  # fails (add), planted through every route git reads it from.
  printf '[core]\n\thooksPath = %s\n\tautocrlf = true\n\tattributesFile = %s\n[commit]\n\tgpgsign = true\n[gpg]\n\tprogram = %s\n[filter "reject"]\n\tclean = false\n\tsmudge = cat\n\trequired = true\n' \
    "$hostile/hooks" "$hostile/attributes" "$hostile/no-such-gpg" > "$hostile/gitconfig"
  cp "$hostile/gitconfig" "$hostile/home/.gitconfig"
  cp "$hostile/gitconfig" "$hostile/xdg/git/config"
  # ... and the environment a hook runs in: git exports GIT_AUTHOR_* to commit
  # hooks and GIT_QUARANTINE_PATH to pre-receive hooks (review 5).
  hostile_git_env() {
    HOME="$hostile/home" XDG_CONFIG_HOME="$hostile/xdg" GIT_CONFIG_GLOBAL="$hostile/gitconfig" \
      GIT_TEMPLATE_DIR="$hostile/template" GIT_QUARANTINE_PATH="$hostile/quarantine" \
      GIT_AUTHOR_NAME='Hook Author' GIT_AUTHOR_EMAIL=hook@example.invalid GIT_DEFAULT_HASH=sha256 "$@"
  }
  # The planting is live: a raw build under it gets no commit. This is the one
  # repository write in the suites that deliberately bypasses fixture_git.
  printf 'x\n' > "$raw/file.md"
  if hostile_git_env bash -c 'git -C "$1" init -q && git -C "$1" add . && git -C "$1" -c user.name=R -c user.email=r@example.invalid commit -qm raw' \
      _ "$raw" > /dev/null 2>&1; then
    t_fail 'AC-020: precondition: the hostile git configuration let a raw fixture build commit'
  fi
  # Under the same configuration and environment the fixture builders are
  # unaffected, and the commit carries the fixture's own identity.
  spec="$(hostile_git_env make_verification_git_dir hostile)" \
    || t_fail "AC-020: make_verification_git_dir failed under a user's git configuration or a hook's environment"
  repo="$(cd "$spec/../../.." && pwd -P)"
  git -C "$repo" rev-parse --verify -q HEAD > /dev/null \
    || t_fail "AC-020: a user's git configuration or a hook's environment left the fixture repository without a commit"
  assert_contains "$(git -C "$repo" ls-files)" 'tests/check.sh' \
    "AC-020: a template's info/exclude or a filter kept files out of the fixture repository"
  assert_eq 'Fixture <fixture@example.invalid>' "$(git -C "$repo" log -1 --format='%an <%ae>' 2>/dev/null)" \
    "AC-020: a hook's environment replaced the fixture identity"
  hostile_git_env git_host "$SANDBOX/hostile-host" \
    || t_fail "AC-020: git_host failed under a user's git configuration or a hook's environment"
  [[ ! -e "$SANDBOX/hostile-host/.git/hooks/pre-commit" ]] \
    || t_fail "AC-020: a template's hook reached a host repository"
  [[ ! -s "$SANDBOX/hostile-host/.git/info/exclude" ]] \
    || t_fail "AC-020: a template's info/exclude reached a host repository"
  # A fixture repository that cannot be built fails its test by name, and the
  # helper still hands its caller the sandbox path (review 5: an empty path made
  # every caller's "$spec/../../.." the filesystem root). Run under its own
  # sandbox, so the record it leaves is not this test's.
  printf '#!/bin/sh\necho "git: simulated failure" >&2\nexit 128\n' > "$shim/git"
  chmod +x "$shim/git"
  if printed="$(PATH="$shim:$PATH" SANDBOX="$failing" \
      make_verification_git_dir failing 2> "$SANDBOX/failing.err")"; then
    t_fail 'AC-020: a fixture repository that could not be built returned success'
  fi
  assert_contains "$(cat "$SANDBOX/failing.err")" 'cannot build the make_verification_git_dir failing fixture' \
    'AC-020: a fixture repository that could not be built was not reported by name'
  assert_contains "$(cat "$failing/.fixture-build-failed" 2>/dev/null)" 'make_verification_git_dir failing' \
    'AC-020: a failed fixture build left no record for the runner'
  [[ -n "$printed" && "$printed" == "$failing"/* ]] \
    || t_fail "AC-020: a failed fixture build handed its caller a path outside the sandbox: '$printed'"
  # The runner turns that record into a named failure for a test that ignores
  # the status, as all of make_verification_git_dir's callers do.
  cat > "$SANDBOX/nested-suite.sh" <<NESTED
. "$KIT_DIR/tests/helpers.sh"
test_ignores_a_failed_build() { local spec; spec="\$(make_verification_git_dir ignored)"; : "\$spec"; }
test_zz_builds_nothing() { :; }
t_run_all # the nested suite's own runner
NESTED
  PATH="$shim:$PATH" run_rc 1 bash "$SANDBOX/nested-suite.sh"
  assert_contains "$OUT" 'FAIL test_ignores_a_failed_build' 'AC-020: a test that ignored a failed fixture build passed'
  assert_contains "$OUT" 'a fixture could not be built: make_verification_git_dir ignored' \
    'AC-020: the runner did not name the fixture build that failed'
  # The clean test sorts after the failing one, so a record leaking forward
  # would fail it.
  assert_contains "$OUT" 'ok   test_zz_builds_nothing' 'AC-020: the runner failed a test that built nothing'
  # Review 6: after a build fails, a later write in the directory whose own
  # repository was never built stays in the sandbox rather than climbing into
  # a repository that encloses it (a TMPDIR inside a Git worktree).
  local enclosing="$SANDBOX/enclosing" commits index
  mkdir -p "$enclosing/inner-sandbox"
  fixture_git -C "$enclosing" init -q || fixture_build_failed enclosing
  printf 'x\n' > "$enclosing/pending.txt"
  { fixture_git -C "$enclosing" add pending.txt && fixture_git -C "$enclosing" commit -qm one; } \
    || fixture_build_failed enclosing
  commits="$(git -C "$enclosing" rev-list --count HEAD)"; index="$(git -C "$enclosing" ls-files --stage)"
  PATH="$shim:$PATH" SANDBOX="$enclosing/inner-sandbox" \
    bash -c '. "$1/tests/helpers.sh"; spec="$(make_verification_git_dir climbing 2>/dev/null)"
      repo="$(cd "$spec/../../.." && pwd -P)"; PATH="${PATH#*:}"; fixture_git -C "$repo" add -A > /dev/null 2>&1' _ "$KIT_DIR"
  assert_eq "$commits" "$(git -C "$enclosing" rev-list --count HEAD)" \
    'AC-020: a write after a failed fixture build committed into an enclosing repository'
  assert_eq "$index" "$(git -C "$enclosing" ls-files --stage)" \
    'AC-020: a write after a failed fixture build staged files in an enclosing repository'
}

# Round 10's isolation gap: the anchor exists only for .specify/specs/<name>
# inside the repository. An in-repository spec in any other layout -- a hub's
# specs/<name> umbrella, say -- gets an EMPTY anchor, which excludes nothing,
# so its own records are inputs. That is the deny-side direction.
outside_layout_anchor_cases() {
  local spec repo outside base
  spec="$(make_verification_git_dir outside)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  outside="$repo/specs/004-outside"
  mkdir -p "$repo/specs"; cp -R "$spec" "$outside"
  run_rc 0 bash -c '. "$1"; vf_bookkeeping_anchor "$2" "$3" 0' _ "$SCRIPTS/verification-lib.sh" \
    "$(cd "$outside" && pwd -P)" "$repo"
  assert_eq '' "$OUT" 'AC-020: an in-repository spec outside .specify/specs/<name> was given an anchor'
  run_rc 0 snapshot_fixture "$outside" "$repo" "$SANDBOX/outside-base"
  base="$OUT"
  mkdir -p "$outside/notes"; printf '## Round 1\n' >> "$outside/notes/opponent.md"
  run_rc 0 snapshot_fixture "$outside" "$repo" "$SANDBOX/outside-edited"
  [[ "$OUT" != "$base" ]] \
    || t_fail "AC-020: an outside-layout spec's own notes/opponent.md was excluded; an empty anchor excludes nothing"
}

# O-015 sibling, round 10: copy_kit copies exactly what the identity
# enumerates. A whole-kit copy made with cp -R carried the host's ignored
# system-map.yml into the doctor fixture and failed it with the identity
# unchanged.
kit_copy_cases() {
  local src="$SANDBOX/kit-src" dest="$SANDBOX/kit-dest" name present absent
  name="caf$(printf '\303\251').md"
  mkdir -p "$src/docs" "$src/build" "$src/bin" "$src/.specify/specs/004-y/notes"
  fixture_git -C "$src" init -q || fixture_build_failed kit-copy
  printf 'build/\nmodels.yml\nsystem-map.yml\n' > "$src/.gitignore"
  printf 'tracked\n' > "$src/docs/tracked.md"
  printf 'deleted\n' > "$src/docs/deleted.md"
  printf '#!/usr/bin/env bash\necho run\n' > "$src/bin/run.sh"; chmod 755 "$src/bin/run.sh"
  printf 'stacks: []\n' > "$src/.specify/stack.yml"
  printf -- '- [x] **T001** — Task\n  - *Evidence:* dropped by the identity\n' > "$src/.specify/specs/004-y/tasks.md"
  printf '## Round 1\n' > "$src/.specify/specs/004-y/notes/opponent.md"
  fixture_git -C "$src" add . && fixture_git -C "$src" commit -qm fixture \
    || fixture_build_failed kit-copy
  rm "$src/docs/deleted.md"
  printf 'untracked\n' > "$src/docs/untracked.md"
  printf 'non-ascii\n' > "$src/docs/$name"
  ln -s tracked.md "$src/docs/link.md"
  printf 'repos: [unclosed\n' > "$src/system-map.yml"
  printf 'tiers: [unclosed\n' > "$src/models.yml"
  printf 'stale adapter\n' > "$src/build/adapter.md"
  run_rc 0 copy_kit "$src" "$dest"
  for present in .gitignore docs/tracked.md docs/untracked.md "docs/$name" bin/run.sh .specify/stack.yml; do
    [[ -f "$dest/$present" ]] || t_fail "AC-020: copy_kit dropped the enumerated path $present"
  done
  cmp -s "$src/docs/tracked.md" "$dest/docs/tracked.md" || t_fail 'AC-020: copy_kit changed the content of a copied file'
  [[ -x "$dest/bin/run.sh" ]] || t_fail 'AC-020: copy_kit dropped the executable mode of a copied script'
  [[ -L "$dest/docs/link.md" ]] || t_fail 'AC-020: copy_kit did not keep an enumerated symlink as a link'
  # Spec directories hold every byte the identity drops, so none is copied.
  for absent in system-map.yml models.yml build .git docs/deleted.md .specify/specs; do
    [[ ! -e "$dest/$absent" && ! -L "$dest/$absent" ]] \
      || t_fail "AC-020: copy_kit carried $absent, which the input identity does not hash verbatim"
  done
  # With a directory selector, exactly the enumerated files under it arrive.
  run_rc 0 copy_kit "$src" "$SANDBOX/kit-selected" .specify/specs/004-y
  [[ -f "$SANDBOX/kit-selected/.specify/specs/004-y/tasks.md" ]] \
    || t_fail 'AC-020: copy_kit dropped an enumerated file under the selected directory'
  for absent in docs bin .specify/stack.yml system-map.yml; do
    [[ ! -e "$SANDBOX/kit-selected/$absent" ]] || t_fail "AC-020: copy_kit copied $absent outside the selected directory"
  done
  # A source the enumeration cannot read fails by name and claims no copy.
  mkdir -p "$SANDBOX/not-a-kit"; printf 'x\n' > "$SANDBOX/not-a-kit/file.md"
  run_rc 1 copy_kit "$SANDBOX/not-a-kit" "$SANDBOX/kit-none"
  assert_contains "$OUT" 'copy_kit: cannot enumerate' 'AC-020: an unreadable kit was copied as if it were whole'
  # A subdirectory of a repository is not a kit root: git succeeds there, but
  # its listing is not the identity's enumeration.
  run_rc 1 copy_kit "$src/docs" "$SANDBOX/kit-sub"
  assert_contains "$OUT" 'copy_kit: cannot enumerate' 'AC-020: a repository subdirectory was copied as a whole kit'
  # 2026-09-24: an earlier copy_kit's EXIT trap, fired on `exit` from inside a
  # command substitution, read the CALLER's variables and removed a caller's
  # relative path -- the live .specify/stack.yml. A failing copy_kit run that
  # way must leave every caller-scope path alone.
  printf 'keep\n' > "$SANDBOX/sentinel"
  # shellcheck disable=SC2034  # caller-scope names the helper must never read
  ( cd "$SANDBOX" && list=sentinel present=sentinel work=sentinel tmp=sentinel path=sentinel \
      && out="$(copy_kit "$SANDBOX/not-a-kit" "$SANDBOX/kit-none" 2>&1)"; : "$out" )
  [[ -f "$SANDBOX/sentinel" ]] || t_fail "AC-020: a failing copy_kit removed a path named by its caller's variables"
}

capture_check_fixture() {
  bash -c '. "$1"; vf_capture_check "$2" "$3" "$4" "$5"' _ "$SCRIPTS/verification-lib.sh" "$@"
}

declare_inputs_fixture() { # repo saved-stack path... -> stack.yml declaring exactly these inputs
  local repo="$1" saved="$2"; shift 2
  { sed '/^verification_inputs:/d' "$saved"; printf 'verification_inputs:\n'; printf "  - '%s'\n" "$@"; } > "$repo/.specify/stack.yml"
}

# O-013: generated bookkeeping is the VERIFIED spec's own. Another spec's gate
# records are ordinary source -- a shipped spec's report is a fixture here
# (AC-010), and a changed fixture must not leave an old success reusable
# (AC-020). A declared input is hashed or refused by name, never dropped.
bookkeeping_anchor_cases() {
  local spec repo own sibling path base staged cap spelling declared upper n ignorecase
  spec="$(make_verification_git_dir anchor)"
  repo="$(cd "$spec/../../.." && pwd -P)"
  own="$(cd "$spec" && pwd -P)"; own="${own#"$repo"/}"
  sibling="$repo/.specify/specs/999-sibling"
  cp "$repo/.specify/stack.yml" "$SANDBOX/anchor-stack"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-base"
  base="$OUT"
  # Both directions over all six generated shapes: the verified spec's own
  # record is invisible, the same record of another spec is an input whether
  # it is untracked, staged, or edited after staging.
  for path in notes/opponent.md notes/reality-check.md notes/evidence.md \
      notes/verification/reports/opponent-findings-x.md notes/verification/floors/FLOOR-x/meta.nul \
      notes/captures/CAP-1-x/output.log .tasks.accept.x; do
    mkdir -p "$(dirname "$spec/$path")" "$(dirname "$sibling/$path")"
    printf 'record\n' > "$spec/$path"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-own"
    assert_eq "$base" "$OUT" "AC-020: the verified spec's own $path changed the identity"
    printf 'record\n' > "$sibling/$path"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-sibling"
    [[ "$OUT" != "$base" ]] || t_fail "AC-020: another spec's untracked $path left the identity unchanged"
    fixture_git -C "$repo" add -f -- "$sibling/$path"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-sibling"
    staged="$OUT"
    printf 'edited\n' > "$sibling/$path"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-sibling"
    [[ "$OUT" != "$staged" ]] || t_fail "AC-020: an edit to another spec's tracked $path left the identity unchanged"
    # Staging that edit changes the index record alone, the working file being
    # unchanged, so this isolates the index pass's anchor.
    staged="$OUT"
    fixture_git -C "$repo" add -f -- "$sibling/$path"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-sibling"
    [[ "$OUT" != "$staged" ]] || t_fail "AC-020: a staged-only change to another spec's $path left the identity unchanged"
    fixture_git -C "$repo" rm -q -f --cached -- "$sibling/$path"
    rm -rf "$sibling" "${spec:?}/$path"
  done
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-base"
  assert_eq "$base" "$OUT" 'AC-020: the anchor fixture did not return to its baseline'

  # Through a real capture: an old success stays reusable across the verified
  # spec's own report, and not across another spec's report, findings manifest
  # or floor record.
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  printf '## Round 1\n' >> "$spec/notes/opponent.md"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-current"
  run_rc 0 capture_check_fixture "$spec" "$cap" "$SANDBOX/anchor-current" reuse
  for path in notes/opponent.md notes/verification/reports/opponent-findings-x.md notes/verification/floors/FLOOR-x/meta.nul; do
    mkdir -p "$(dirname "$sibling/$path")"
    printf 'record\n' > "$sibling/$path"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-current"
    run_rc 3 capture_check_fixture "$spec" "$cap" "$SANDBOX/anchor-current" reuse
    assert_contains "$OUT" 'capture stale: current inputs changed' \
      "AC-020: another spec's $path left an old success reusable"
    rm -rf "$sibling"
  done

  # Declared inputs. The verified spec's own records are refused by NAME, by
  # location rather than spelling: the record, a directory wholly inside the
  # records, another spelling of either, and a link naming one. So is the
  # repository root, which is already the whole-source input.
  ln -s "../$own/notes/opponent.md" "$repo/docs/report-link"
  for spelling in "$own/notes/opponent.md" "./$own/notes/opponent.md" "$own//notes/opponent.md" \
      "$own/notes/verification" "$own/notes/captures/" docs/report-link; do
    declare_inputs_fixture "$repo" "$SANDBOX/anchor-stack" "$spelling"
    run_rc 3 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-declared"
    assert_contains "$OUT" "verification inputs: declared input is this spec's own generated bookkeeping: $spelling" \
      "AC-020: declared own bookkeeping $spelling was not refused by name"
  done
  rm "$repo/docs/report-link"
  for spelling in . ./; do
    declare_inputs_fixture "$repo" "$SANDBOX/anchor-stack" "$spelling"
    run_rc 3 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-declared"
    assert_contains "$OUT" "verification inputs: declared input is the repository root: $spelling" \
      "AC-020: the declared repository root $spelling was not refused by name"
  done
  # `..` after a symlinked component resolves through the FILESYSTEM. Read
  # lexically, ign/docs/l lands on the decoy; the kernel reads the spec's own
  # report, so the declaration is refused. ign/ is ignored by git, as declared
  # inputs usually are, so its directory link is never enumerated.
  printf 'ign/\n' >> "$repo/.gitignore"
  mkdir -p "$repo/ign/docs" "$repo/ign/notes"
  ln -s "../$own/notes" "$repo/ign/sub"
  ln -s ../sub/../notes/opponent.md "$repo/ign/docs/l"
  printf 'decoy\n' > "$repo/ign/notes/opponent.md"
  assert_eq "$(cat "$spec/notes/opponent.md")" "$(cat "$repo/ign/docs/l")" 'fixture: the link must reach the own report'
  declare_inputs_fixture "$repo" "$SANDBOX/anchor-stack" ign/docs/l
  run_rc 3 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-declared"
  assert_contains "$OUT" "verification inputs: declared input is this spec's own generated bookkeeping: ign/docs/l" \
    'AC-020: a link reaching the own report through a symlinked parent and .. was not refused'
  # A declared symlink loop terminates, recorded as a link with no target.
  ln -s loop "$repo/ign/loop"
  declare_inputs_fixture "$repo" "$SANDBOX/anchor-stack" ign/loop
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-declared"
  rm -rf "$repo/ign"
  cp "$SANDBOX/anchor-stack" "$repo/.specify/stack.yml"
  # Where the filesystem folds case -- the other spelling then EXISTS -- another
  # case names the same record. The refusal folds, and a spec path typed in
  # another case keeps its own records out of its identity. Where the
  # filesystem does not fold, those spellings name nothing and are not tried.
  if [[ -e "$repo/$own/notes/OPPONENT.md" ]]; then
    # Folding is asked of the filesystem, not of git's recorded core.ignorecase.
    for ignorecase in true false; do
      fixture_git -C "$repo" config core.ignorecase "$ignorecase"
      for spelling in "$own/notes/OPPONENT.md" "$(printf '%s' "$own" | tr '[:lower:]' '[:upper:]')/notes/opponent.md"; do
        declare_inputs_fixture "$repo" "$SANDBOX/anchor-stack" "$spelling"
        run_rc 3 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-declared"
        assert_contains "$OUT" "verification inputs: declared input is this spec's own generated bookkeeping: $spelling" \
          "AC-020: declared own bookkeeping $spelling was not refused on a case-folding filesystem (core.ignorecase=$ignorecase)"
      done
    done
    fixture_git -C "$repo" config core.ignorecase true
    cp "$SANDBOX/anchor-stack" "$repo/.specify/stack.yml"
    upper="$(dirname "$spec")/$(basename "$spec" | tr '[:lower:]' '[:upper:]')"
    run_rc 0 snapshot_fixture "$upper" "$repo" "$SANDBOX/anchor-upper"
    staged="$OUT"
    mkdir -p "$spec/notes/captures/CAP-3-z"; printf 'log\n' > "$spec/notes/captures/CAP-3-z/output.log"
    run_rc 0 snapshot_fixture "$upper" "$repo" "$SANDBOX/anchor-upper"
    assert_eq "$staged" "$OUT" "AC-020: a spec path typed in another case leaked the spec's own records into its identity"
    # The probe climbs past a letterless spec name, which new-spec.sh produces
    # from a title slugified to digits, so the folding is still found.
    cp -R "$repo" "$SANDBOX/anchor-digits"
    mv "$SANDBOX/anchor-digits/$own" "$SANDBOX/anchor-digits/.specify/specs/003-2027"
    fixture_git -C "$SANDBOX/anchor-digits" add -A && fixture_git -C "$SANDBOX/anchor-digits" commit -qm digits \
      || fixture_build_failed letterless-spec
    run_rc 0 snapshot_fixture "$SANDBOX/anchor-digits/.SPECIFY/specs/003-2027" "$SANDBOX/anchor-digits" "$SANDBOX/anchor-digits.nul"
    staged="$OUT"
    mkdir -p "$SANDBOX/anchor-digits/.specify/specs/003-2027/notes/captures/CAP-6-d"
    printf 'log\n' > "$SANDBOX/anchor-digits/.specify/specs/003-2027/notes/captures/CAP-6-d/output.log"
    run_rc 0 snapshot_fixture "$SANDBOX/anchor-digits/.SPECIFY/specs/003-2027" "$SANDBOX/anchor-digits" "$SANDBOX/anchor-digits.nul"
    assert_eq "$staged" "$OUT" "AC-020: a letterless spec typed in another case leaked its own records into its identity"
    declare_inputs_fixture "$SANDBOX/anchor-digits" "$SANDBOX/anchor-stack" .specify/specs/003-2027/notes/OPPONENT.md
    run_rc 3 snapshot_fixture "$SANDBOX/anchor-digits/.specify/specs/003-2027" "$SANDBOX/anchor-digits" "$SANDBOX/anchor-digits.nul"
    assert_contains "$OUT" "verification inputs: declared input is this spec's own generated bookkeeping: .specify/specs/003-2027/notes/OPPONENT.md" \
      'AC-020: a letterless spec did not fold the declared-input refusal'
  else
    # Where the filesystem does NOT fold, a symlink spelled as the case swap of
    # the spec directory is an alias, not evidence of folding; trusting it would
    # fold a sibling spec that differs only in case into this spec's own records.
    upper="$(dirname "$spec")/$(basename "$spec" | tr 'a-zA-Z' 'A-Za-z')"
    ln -s "$(basename "$spec")" "$upper"
    printf '%s\n' ".specify/specs/$(basename "$upper")" >> "$repo/.gitignore"
    declared="$(dirname "$spec")/$(basename "$spec" | sed 's/^003-v/003-V/')"
    mkdir -p "$declared/notes"; printf 'report\n' > "$declared/notes/opponent.md"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-alias"
    staged="$OUT"
    printf 'edited\n' > "$declared/notes/opponent.md"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-alias"
    [[ "$OUT" != "$staged" ]] || t_fail "AC-020: a case-swapped alias symlink folded a sibling spec into this spec's own records"
    rm -rf "$declared" "$upper"
  fi
  # The anchor is string work on physical paths, so git's discovery
  # environment cannot move it: a hook in a linked worktree runs with GIT_DIR
  # exported, under which git takes the working directory as the top level.
  run_rc 0 env GIT_DIR="$repo/.git" bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ \
    "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/anchor-gitdir"
  staged="$OUT"
  mkdir -p "$spec/notes/captures/CAP-4-g"; printf 'log\n' > "$spec/notes/captures/CAP-4-g/output.log"
  run_rc 0 env GIT_DIR="$repo/.git" bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ \
    "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/anchor-gitdir"
  assert_eq "$staged" "$OUT" "AC-020: an exported GIT_DIR leaked the spec's own records into its identity"
  declare_inputs_fixture "$repo" "$SANDBOX/anchor-stack" "$own/notes/captures"
  run_rc 3 env GIT_DIR="$repo/.git" bash -c '. "$1"; vf_snapshot "$2" "$3" "$3" "$4"' _ \
    "$SCRIPTS/verification-lib.sh" "$spec" "$repo" "$SANDBOX/anchor-gitdir"
  assert_contains "$OUT" "verification inputs: declared input is this spec's own generated bookkeeping: $own/notes/captures" \
    'AC-020: an exported GIT_DIR stopped the refusal of declared own bookkeeping'
  cp "$SANDBOX/anchor-stack" "$repo/.specify/stack.yml"
  # So is a repository whose path contains a newline.
  cp -R "$repo" "$SANDBOX/anchor-nl
repo"
  run_rc 0 snapshot_fixture "$SANDBOX/anchor-nl
repo/$own" "$SANDBOX/anchor-nl
repo" "$SANDBOX/anchor-nl"
  staged="$OUT"
  mkdir -p "$SANDBOX/anchor-nl
repo/$own/notes/captures/CAP-5-n"
  printf 'log\n' > "$SANDBOX/anchor-nl
repo/$own/notes/captures/CAP-5-n/output.log"
  run_rc 0 snapshot_fixture "$SANDBOX/anchor-nl
repo/$own" "$SANDBOX/anchor-nl
repo" "$SANDBOX/anchor-nl"
  assert_eq "$staged" "$OUT" "AC-020: a repository path containing a newline leaked the spec's own records into its identity"
  # Another spec's report, declared while git ignores it, is hashed: a record
  # names it and an edit moves the identity. Before O-013 this was dropped.
  declared='.specify/specs/999-sibling/notes/opponent.md'
  mkdir -p "$sibling/notes"; printf 'report\n' > "$repo/$declared"
  printf '.specify/specs/999-sibling/\n' >> "$repo/.gitignore"
  declare_inputs_fixture "$repo" "$SANDBOX/anchor-stack" "$declared"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-declared"
  staged="$OUT"
  assert_eq 1 "$(tr '\0' '\n' < "$SANDBOX/anchor-declared" | grep -c -F -x "$declared")" \
    "AC-020: the declared report of another spec has no identity record"
  printf 'edited\n' > "$repo/$declared"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-declared"
  [[ "$OUT" != "$staged" ]] || t_fail 'AC-020: an edit to a declared input was dropped'
  # A declared directory CONTAINING the records skips them by the enumeration's
  # rule, neither hashed nor counted, so a capture still sees stable inputs.
  # Members are enumerated from the directory's canonical location, so every
  # spelling of the declaration skips the same records.
  n=0
  for spelling in .specify ./.specify .specify/; do
    n=$((n+1))
    declare_inputs_fixture "$repo" "$SANDBOX/anchor-stack" "$spelling"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-declared"
    staged="$OUT"
    mkdir -p "$spec/notes/captures/CAP-2$n-y"; printf 'log\n' > "$spec/notes/captures/CAP-2$n-y/output.log"
    run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-declared"
    assert_eq "$staged" "$OUT" "AC-020: the verified spec's own records were counted inside declared directory $spelling"
  done
  run_rc 0 "$SCRIPTS/spec-run.sh" "$spec" T001 --cwd "$repo" --from-task --no-tick --summary
  cap="$(printf '%s' "$OUT" | sed -n 's/^capture=\([^ ]*\).*/\1/p')"
  run_rc 0 snapshot_fixture "$spec" "$repo" "$SANDBOX/anchor-current"
  run_rc 0 capture_check_fixture "$spec" "$cap" "$SANDBOX/anchor-current" current
  cp "$SANDBOX/anchor-stack" "$repo/.specify/stack.yml"
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
