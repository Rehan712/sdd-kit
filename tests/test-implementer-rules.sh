#!/usr/bin/env bash
# test-implementer-rules.sh — the three rules every code-writing path carries
# (style guide, ponytail, read-only recon on the cheap tier) and the scout's
# Bash backstop that keeps "read-only" true.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

GUARD="$SCRIPTS/scout-guard.sh"

# payload <command> — a PreToolUse payload as Claude Code sends it: the command
# is a JSON string, so `"` and a newline arrive escaped.
payload() {
  local cmd="$1"
  cmd="${cmd//\\/\\\\}"; cmd="${cmd//\"/\\\"}"; cmd="${cmd//$'\n'/\\n}"
  printf '{"session_id":"s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s","description":"probe"}}' "$cmd"
}

guard_rc() { payload "$1" | bash "$GUARD" > /dev/null 2>&1; echo $?; }

allowed() { assert_eq 0 "$(guard_rc "$1")" "scout-guard blocked a read-only command: $1"; }
blocked() { assert_eq 2 "$(guard_rc "$1")" "scout-guard let a write through: $1"; }

# --- the guard: recon commands run ------------------------------------------------

test_guard_allows_search_read_and_named_test_commands() {
  allowed 'rg -n "fn main" src/'
  allowed 'git status --porcelain'
  allowed 'git -C /tmp/wt log --oneline -5'
  allowed 'git diff main...HEAD -- src/lib.rs'
  allowed 'git merge-base main HEAD'
  allowed 'git branch --show-current'
  allowed 'git stash list'
  allowed 'git worktree list'
  allowed 'cargo test --workspace'
  allowed 'cargo clippy --workspace --all-targets -- -D warnings'
  allowed 'npm test -- --run'
  allowed 'npm run lint && npm run typecheck'
  allowed 'bun test'
  allowed 'cat scripts/spec-gate.sh | head -40'
  allowed 'bash ~/.sdd/scripts/spec-status.sh get specs/001-x phase'
  allowed 'bash ~/.sdd/scripts/spec-graph.sh next specs/001-x'
  allowed 'sed -n 1,40p README.md'
  allowed 'gh pr view 12 --json state'
  allowed 'cdk diff'
  allowed 'terraform plan'
}

# A search FOR a write command is a read: the words sit inside a pattern, not
# in command position.
test_guard_allows_searching_for_the_words_it_blocks() {
  allowed "rg -n 'git commit' docs/"
  allowed 'rg -n "spec-gate.sh accept" skills/ agents/'
  allowed "rg -n '(git commit|git push)' ."
  allowed "rg -n 'rm -rf|mv ' scripts/"
  allowed 'grep -rn "npm install" README.md'
}

# --- the guard: state changes are refused -------------------------------------------

test_guard_blocks_git_writes() {
  blocked 'git commit -m wip'
  blocked 'git add -A'
  blocked 'git -C /tmp/wt push origin HEAD'
  blocked 'git checkout -- src/lib.rs'
  blocked 'git reset --hard HEAD~1'
  blocked 'git stash'
  blocked 'git stash pop'
  blocked 'git worktree add ../wt spec/001-x'
  blocked 'git branch -D spec/001-x'
  blocked 'cd /tmp/wt && git commit -m wip'
  blocked 'git status; git add .'
  blocked $'git status\ngit commit -m wip'
  blocked 'echo $(git stash)'
}

test_guard_blocks_kit_state_scripts() {
  blocked 'bash ~/.sdd/scripts/spec-gate.sh accept specs/001-x T001 r.txt'
  blocked 'bash "$S/spec-run.sh" "$SPEC" T001 --from-task --no-tick --summary'
  blocked './scripts/spec-task.sh done specs/001-x T001 --evidence ok'
  # shellcheck disable=SC2088  # the literal command text a scout would send
  blocked '~/.sdd/scripts/spec-status.sh --file spec.md set specs/001-x status accepted'
  blocked 'bash scripts/spec-pr.sh specs/001-x'
  blocked 'bash scripts/new-spec.sh "a feature"'
}

test_guard_blocks_file_mutation_installs_and_deploys() {
  blocked 'rm -rf build'
  blocked 'mv a.txt b.txt'
  blocked 'sed -i "" s/a/b/ file.txt'
  blocked 'perl -pi -e s/a/b/ file.txt'
  blocked 'cargo test | tee out.log'
  blocked 'find . -name "*.orig" | xargs rm'
  blocked 'npm install'
  blocked 'pnpm add zod'
  blocked 'bun install && bun test'
  blocked 'cargo add serde'
  blocked 'pip install requests'
  blocked 'uv sync'
  blocked 'cdk deploy --all'
  blocked 'terraform apply -auto-approve'
  blocked 'gh pr merge 12 --squash'
  blocked 'sudo rm -rf /tmp/x'
  blocked 'CI=1 npm ci'
}

# The refusal tells the scout what to do next, on stderr (which is what the
# hook hands back to the agent); nothing on stdin is a no-op, not a failure.
test_guard_reports_on_stderr_and_ignores_an_empty_payload() {
  local err
  err="$(payload 'git commit -m wip' | bash "$GUARD" 2>&1 > /dev/null)"
  assert_contains "$err" 'sdd-scout is read-only'
  assert_contains "$err" 'UNKNOWN'
  run_rc 0 bash "$GUARD" < /dev/null
}

frontmatter_of() { awk 'NR==1 && $0=="---" {i=1; next} i && $0=="---" {exit} i' "$1"; }

test_scout_persona_wires_the_guard() {
  local fm; fm="$(frontmatter_of "$KIT_DIR/agents/sdd-scout.md")"
  assert_contains "$fm" 'PreToolUse:'
  assert_contains "$fm" 'matcher: "Bash"'
  assert_contains "$fm" 'scripts/scout-guard.sh'
  assert_contains "$(cat "$KIT_DIR/agents/sdd-scout.md")" 'go under `UNKNOWN`'
}

# --- every implementer persona carries the three rules ------------------------------

test_every_implementer_persona_carries_the_working_rules() {
  local file text list="$SANDBOX/personas" n=0
  kit_files agents '*-expert.md' > "$list" || t_fail 'cannot enumerate the expert personas'
  printf 'agents/test-engineer.md\0' >> "$list"
  while IFS= read -r -d '' file; do
    n=$((n+1))
    text="$(cat "$KIT_DIR/$file")"
    assert_contains "$text" '## Working rules' "$file"
    assert_contains "$text" 'ponytail:ponytail' "$file"
    assert_contains "$text" 'shortcut: <limit>, <when to upgrade>' "$file"
    assert_contains "$text" 'The task outranks it' "$file"
    assert_contains "$text" 'templates/style-guides/' "$file"
    assert_contains "$text" 'Never restyle lines the task does not touch' "$file"
    assert_contains "$text" 'sdd-scout' "$file"
  done < "$list"
  (( n > 1 )) || t_fail 'no expert persona was enumerated'
}

# --- overlays name a style guide that exists ----------------------------------------

style_contract() { # <guide> <overlay tag>...
  local guide="$1" tag text; shift
  [[ -f "$KIT_DIR/templates/style-guides/$guide.md" ]] || t_fail "style guide $guide.md is missing"
  for tag in "$@"; do
    text="$(cat "$KIT_DIR/templates/stack-overlays/$tag.md")"
    assert_contains "$text" '## Style guide' "$tag overlay"
    # shellcheck disable=SC2088  # the literal path the overlay prints
    assert_contains "$text" "~/.sdd/templates/style-guides/$guide.md" "$tag overlay"
    assert_contains "$text" 'never restyle lines the task does not touch' "$tag overlay"
  done
}

test_rust_overlays_name_the_rust_style_guide() {
  style_contract rust rust rust-aws-lambda
  assert_contains "$(cat "$KIT_DIR/templates/style-guides/rust.md")" \
    'https://google.github.io/styleguide/rustguide.html'
}

test_typescript_overlays_name_the_typescript_style_guide() {
  style_contract typescript javascript nextjs react expo-rn loopback4 bun-monorepo \
    aws-cdk-lambda-ts firebase-rtk-codegen
  assert_contains "$(cat "$KIT_DIR/templates/style-guides/typescript.md")" \
    'https://google.github.io/styleguide/tsguide.html'
}

# Both digests rank the project's own config and the file being edited above
# the guide — a style guide is never a licence for a drive-by reformat.
test_style_guides_rank_project_config_first() {
  local g text
  for g in rust typescript; do
    text="$(cat "$KIT_DIR/templates/style-guides/$g.md")"
    assert_contains "$text" '## Precedence' "$g"
    assert_contains "$text" "1. The project's own config" "$g"
    assert_contains "$text" 'style-only change is its own task' "$g"
  done
}

# --- the skills that write code say the same three things ---------------------------

test_code_writing_skills_carry_ponytail_style_and_scout() {
  local f text
  for f in skills/sdd-implement/SKILL.md skills/sdd-review/SKILL.md \
           skills/aws-serverless-lambda-services-arch/SKILL.md; do
    text="$(cat "$KIT_DIR/$f")"
    assert_contains "$text" 'onytail' "$f"
    assert_contains "$text" 'tyle guide' "$f"
    assert_contains "$text" 'sdd-scout' "$f"
  done
  for f in skills/aws-serverless-lambda-services-arch-bun/SKILL.md \
           skills/aws-serverless-lambda-services-arch-node/SKILL.md; do
    assert_contains "$(cat "$KIT_DIR/$f")" 'Code style and scope' "$f"
  done
  assert_contains "$(cat "$KIT_DIR/agents/sdd-orchestrator.md")" 'the style guide it names'
  assert_contains "$(cat "$KIT_DIR/templates/stack-routing.md")" 'templates/style-guides/'
}

# --- official skills: one table, named where they are used --------------------------

test_official_skills_table_names_every_source() {
  local text needle; text="$(cat "$KIT_DIR/templates/official-skills.md")"
  for needle in 'ponytail:ponytail' 'aws-core' 'stripe-best-practices' 'upgrade-stripe' \
      'ui-ux-pro-max' 'node_modules/next/dist/docs/' 'next-cache-components-optimizer' \
      '`code-review`' '`security-review`' 'codex review --base' \
      'Retired: `vercel-labs/next-skills`' 'Load on match, not on sight'; do
    assert_contains "$text" "$needle" 'official-skills.md'
  done
}

test_overlays_and_personas_name_their_official_skills() {
  local tag text file list="$SANDBOX/personas"
  for tag in nextjs react expo-rn aws aws-cdk-lambda-ts rust-aws-lambda troposphere; do
    text="$(cat "$KIT_DIR/templates/stack-overlays/$tag.md")"
    assert_contains "$text" '## Official skills' "$tag overlay"
    # shellcheck disable=SC2088  # the literal path the overlay prints
    assert_contains "$text" '~/.sdd/templates/official-skills.md' "$tag overlay"
  done
  for tag in nextjs react expo-rn; do
    assert_contains "$(cat "$KIT_DIR/templates/stack-overlays/$tag.md")" 'ui-ux-pro-max' "$tag overlay"
  done
  for tag in aws aws-cdk-lambda-ts rust-aws-lambda troposphere; do
    assert_contains "$(cat "$KIT_DIR/templates/stack-overlays/$tag.md")" 'aws-core' "$tag overlay"
  done
  kit_files agents '*-expert.md' > "$list" || t_fail 'cannot enumerate the expert personas'
  printf 'agents/test-engineer.md\0' >> "$list"
  while IFS= read -r -d '' file; do
    text="$(cat "$KIT_DIR/$file")"
    assert_contains "$text" '**Official skills first.**' "$file"
    assert_contains "$text" 'stripe-best-practices' "$file"
    assert_contains "$text" 'Load only what' "$file"
  done < "$list"
}

# The reviewers use the vendor's own review as a first pass and keep their own
# verdict rules: a lead is not a finding, and the costly levels need the user.
test_gates_use_official_reviews_as_leads() {
  local text
  text="$(cat "$KIT_DIR/agents/opponent.agent.md")"
  assert_contains "$text" '`code-review` skill'
  assert_contains "$text" 'never `max` or `ultra`'
  assert_contains "$text" 'leads, not Findings'
  text="$(cat "$KIT_DIR/agents/security-reviewer.md")"
  assert_contains "$text" '`security-review`'
  assert_contains "$text" 'never remove a check below'
  assert_contains "$(cat "$KIT_DIR/skills/sdd-plan/SKILL.md")" 'templates/official-skills.md'
  assert_contains "$(cat "$KIT_DIR/skills/sdd-implement/SKILL.md")" '**Official skills first.**'
}

# --- companions.sh: reads the homes, never installs ---------------------------------

# The caller's own CLAUDE_CONFIG_DIR / CODEX_HOME must not leak into a fixture:
# the script reads them to decide how to address the default home.
companions() { env -u CLAUDE_CONFIG_DIR -u CODEX_HOME HOME="$SANDBOX/home" bash "$SCRIPTS/companions.sh" "$@"; }

claude_home() { # <dir name> <ponytail version or ''>
  local h="$SANDBOX/home/$1"
  mkdir -p "$h/plugins"
  if [[ -n "$2" ]]; then
    mkdir -p "$h/plugins/cache/ponytail/ponytail/$2"
    printf '{"plugins":{"ponytail@ponytail":[{"version":"%s"}]}}\n' "$2" > "$h/plugins/installed_plugins.json"
  fi
}

test_companions_pass_with_ponytail_v5_and_report_the_rest() {
  claude_home .claude 5.3.2
  mkdir -p "$SANDBOX/home/.claude/skills/stripe-best-practices"
  run_rc 0 companions
  assert_contains "$OUT" 'ponytail 5.3.2'
  assert_contains "$OUT" 'aws-core not installed — claude plugin install aws-core@claude-plugins-official'
  assert_contains "$OUT" 'nextjs not installed — npx skills add vercel/next.js -g -a claude-code'
  assert_not_contains "$OUT" 'stripe not installed' 'a skill directory was not counted as installed'
}

test_companions_fail_on_a_missing_or_old_ponytail() {
  claude_home .claude ''
  run_rc 1 companions
  assert_contains "$OUT" 'ponytail missing — claude plugin marketplace add DietrichGebert/ponytail'
  claude_home .claude 4.9.0
  run_rc 1 companions
  assert_contains "$OUT" 'ponytail 4.9.0 is older than v5'
}

# A second home gets the command that targets it; a Codex home is read from
# its config.toml, and a row without a version keeps all seven fields.
test_companions_address_each_home_and_keep_the_tsv_shape() {
  local row
  claude_home .claude 5.3.2
  claude_home .claude_work ''
  mkdir -p "$SANDBOX/home/.codex"
  printf '[plugins."ponytail@ponytail"]\nenabled = true\n' > "$SANDBOX/home/.codex/config.toml"
  run_rc 1 companions --tsv
  assert_contains "$OUT" "CLAUDE_CONFIG_DIR=$SANDBOX/home/.claude_work sh -c 'claude plugin marketplace add"
  row="$(printf '%s\n' "$OUT" | grep "^codex	.codex	ponytail	")"
  assert_eq "codex	.codex	ponytail	core	installed	-	codex plugin marketplace add DietrichGebert/ponytail && codex plugin add ponytail@ponytail" "$row"
  assert_eq 7 "$(printf '%s\n' "$OUT" | grep '	aws-core	' | head -1 | awk -F'\t' '{print NF}')" 'fields in a row without a version'
}

# A session launched with CLAUDE_CONFIG_DIR (or CODEX_HOME) pointing at another
# home runs `claude plugin install` against THAT home. The command printed for
# the default home therefore unsets the variable, or it installs elsewhere.
test_companions_default_home_command_survives_an_inherited_config_dir() {
  claude_home .claude ''
  mkdir -p "$SANDBOX/home/.codex"
  run_rc 1 env CLAUDE_CONFIG_DIR="$SANDBOX/home/.claude_other" CODEX_HOME="$SANDBOX/home/.codex_other" \
    HOME="$SANDBOX/home" bash "$SCRIPTS/companions.sh" --tsv
  assert_contains "$OUT" "claude	.claude	ponytail	core	missing	-	env -u CLAUDE_CONFIG_DIR sh -c 'claude plugin marketplace add"
  assert_contains "$OUT" "claude	.claude	nextjs	stack	missing	-	env -u CLAUDE_CONFIG_DIR sh -c 'npx skills add"
  assert_contains "$OUT" "codex	.codex	aws-core	stack	missing	-	env -u CODEX_HOME sh -c 'codex plugin marketplace add"
  # Codex reads the shared ~/.agents/skills: nothing home-specific to address.
  assert_contains "$OUT" "codex	.codex	nextjs	stack	missing	-	npx skills add vercel/next.js -g -a codex"
}

# The table people read and the manifest the script reads cannot drift: every
# install command companions.sh prints is in official-skills.md.
test_companions_install_commands_match_the_table() {
  local table cmd part rest
  table="$(cat "$KIT_DIR/templates/official-skills.md")"
  claude_home .claude ''
  mkdir -p "$SANDBOX/home/.codex"
  companions --tsv > "$SANDBOX/rows" || true
  [[ -s "$SANDBOX/rows" ]] || t_fail 'companions.sh printed no rows'
  while IFS=$'\t' read -r _ _ _ _ _ _ cmd; do
    rest="$cmd"
    while [[ -n "$rest" ]]; do
      part="${rest%% && *}"
      [[ "$rest" == *' && '* ]] && rest="${rest#* && }" || rest=""
      assert_contains "$table" "\`$part\`" 'official-skills.md Install table'
    done
  done < "$SANDBOX/rows"
}

t_run_all
