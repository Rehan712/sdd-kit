#!/usr/bin/env bash
# test-project-routing.sh — a project's own skills and agents
# (<project>/.specify/routing.md) are matched per file signal by a script, and
# a name nobody can load is an error rather than a silent skip.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

ROUTE="$SCRIPTS/project-routing.sh"

# project — $SANDBOX/proj with one implementer and one reviewer per platform:
# Android as skills, the big screen as agents. Echoes the project root.
project() {
  local p="$SANDBOX/proj" name
  mkdir -p "$p/.specify" "$p/.claude/agents"
  for name in android-implementer android-reviewer ios-implementer acme-architecture; do
    mkdir -p "$p/.claude/skills/$name"
    printf -- '---\nname: %s\n---\n' "$name" > "$p/.claude/skills/$name/SKILL.md"
  done
  printf -- '---\nname: bigscreen-implementer\nmodel: sonnet\n---\n' > "$p/.claude/agents/bigscreen-implementer.md"
  printf -- '---\nname: bigscreen-reviewer\nmodel: opus\ntools: Read, Grep\n---\n' > "$p/.claude/agents/bigscreen-reviewer.md"
  cat > "$p/.specify/routing.md" <<'EOF'
# Project routing

Prose with a | pipe is not a table row.

| Signal | Plan | Implement | Review |
|---|---|---|---|
| `apps/android/**`, `*.kt` | | `android-implementer` | `android-reviewer` |
| `apps/ios/` | — | `ios-implementer`, `ui-ux-pro-max:ui-ux-pro-max` | - |
| `apps/tv/**` | | `bigscreen-implementer` | `bigscreen-reviewer` |
| `*` | `acme-architecture` | | |
EOF
  (cd "$p" && pwd)
}

names() { printf '%s\n' "$OUT" | cut -f1,2 | tr '\t\n' ': ' | sed 's/ $//'; }

test_each_platform_routes_to_its_own_implementer() {
  local p; p="$(project)"
  run_rc 0 "$ROUTE" check "$p"
  assert_contains "$OUT" 'project routing valid (4 row(s)'

  run_rc 0 "$ROUTE" match "$p" implement apps/android/app/Main.kt
  assert_eq "skill	android-implementer	$p/.claude/skills/android-implementer/SKILL.md	apps/android/**" "$OUT"
  run_rc 0 "$ROUTE" match "$p" implement shared/core/Util.kt
  assert_eq 'skill:android-implementer' "$(names)" 'a *.kt file outside apps/android'
  run_rc 0 "$ROUTE" match "$p" implement apps/ios/App/View.swift
  assert_eq 'skill:ios-implementer skill:ui-ux-pro-max:ui-ux-pro-max' "$(names)" 'a directory signal with two names'
  assert_contains "$OUT" 'ui-ux-pro-max:ui-ux-pro-max	-	' 'a plugin skill has no file to read'
  run_rc 0 "$ROUTE" match "$p" implement apps/tv/src/Home.tsx
  assert_eq "agent	bigscreen-implementer	$p/.claude/agents/bigscreen-implementer.md	apps/tv/**" "$OUT"

  # The other phases are their own columns.
  run_rc 0 "$ROUTE" match "$p" review apps/tv/src/Home.tsx apps/android/A.kt
  assert_eq 'skill:android-reviewer agent:bigscreen-reviewer' "$(names)" 'reviewers come back in table order'
  run_rc 0 "$ROUTE" match "$p" plan docs/anything.md
  assert_eq 'skill:acme-architecture' "$(names)"
  run_rc 0 "$ROUTE" match "$p" implement docs/anything.md
  assert_eq '' "$OUT" 'a path no Implement row covers was routed'
}

# No selector lists the phase's rows with their signals — what /sdd:plan reads.
test_no_selector_lists_every_row_of_the_phase() {
  local p; p="$(project)"
  run_rc 0 "$ROUTE" match "$p" implement
  assert_eq 4 "$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')"
  assert_contains "$OUT" 'android-implementer	'"$p"'/.claude/skills/android-implementer/SKILL.md	apps/android/**,*.kt'
}

# A bare `*` signal is split from its list without being expanded against the
# directory the script happens to run in.
test_star_signal_is_not_expanded_against_the_cwd() {
  local p; p="$(project)"
  mkdir -p "$SANDBOX/cwd" && : > "$SANDBOX/cwd/decoy.md"
  OUT="$(cd "$SANDBOX/cwd" && "$ROUTE" match "$p" plan src/x.ts 2>&1)"
  assert_eq "skill	acme-architecture	$p/.claude/skills/acme-architecture/SKILL.md	*" "$OUT"
}

# The dispatcher's two selectors: a task's *Files:*, and the branch diff.
test_task_files_and_branch_diff_select_the_rows() {
  local p spec; p="$(project)"; spec="$p/.specify/specs/001-demo"
  mkdir -p "$spec"
  cat > "$spec/tasks.md" <<'EOF'
- [ ] **T001** [P] — Android screen
  - *Files:* `apps/android/app/Screen.kt`, `apps/android/app/ScreenTest.kt`
  - *Verify:* `./gradlew test`
- [ ] **T002** — Docs
  - *Files:* docs/a.md, docs/b.md
- [ ] **T003** — TV row
  - *Files:* `apps/tv/src/Row.tsx`
EOF
  run_rc 0 "$ROUTE" match "$p" implement --task "$spec" T001
  assert_eq 'skill:android-implementer' "$(names)"
  run_rc 0 "$ROUTE" match "$p" implement --task "$spec" T002
  assert_eq '' "$OUT" 'a docs task matched an Implement row'
  run_rc 0 "$ROUTE" match "$p" plan --task "$spec" T002
  assert_eq 'skill:acme-architecture' "$(names)" 'un-backticked Files were not read'
  run_rc 0 "$ROUTE" match "$p" implement --task "$spec" T003
  assert_eq 'agent:bigscreen-implementer' "$(names)"
  run_rc 1 "$ROUTE" match "$p" implement --task "$spec" T009
  assert_contains "$OUT" 'task T009 not found'

  # The directory may be any path inside the project (the live spec dir here).
  printf 'stacks: []\n' > "$p/.specify/stack.yml"
  run_rc 0 "$ROUTE" match "$spec" implement --task "$spec" T001
  assert_eq 'skill:android-implementer' "$(names)" 'a directory inside the project did not resolve to it'

  fixture_git -C "$p" init -q -b main . && fixture_git -C "$p" add -A && fixture_git -C "$p" commit -qm base \
    && fixture_git -C "$p" checkout -qb spec/001-demo || { fixture_build_failed 'routing repository'; return; }
  mkdir -p "$p/apps/tv/src" && echo x > "$p/apps/tv/src/Row.tsx"
  fixture_git -C "$p" add -A && fixture_git -C "$p" commit -qm tv
  run_rc 0 "$ROUTE" match "$p" review --diff main
  assert_eq 'agent:bigscreen-reviewer' "$(names)" 'the branch diff did not pick the reviewer of the files it changed'
  run_rc 1 "$ROUTE" match "$p" review --diff no-such-base
  assert_contains "$OUT" 'cannot read the diff'
}

# A table that cannot be trusted stops the dispatcher instead of routing
# around the project's conventions.
test_broken_table_is_refused_by_check_and_match() {
  local p; p="$(project)"
  mkdir -p "$p/.claude/agents" && : > "$p/.claude/agents/android-implementer.md"
  cat > "$p/.specify/routing.md" <<'EOF'
| Signal | Implement | Deploy |
|---|---|---|
| `a/**` | `no-such-skill` | x |
|  | `ios-implementer` | |
| `b/**` | | |
| `c/**` | `android-implementer` | |
| `d/**` | `../../etc/passwd` | |
EOF
  run_rc 1 "$ROUTE" check "$p"
  assert_contains "$OUT" 'line 1: unknown column "Deploy"'
  assert_contains "$OUT" 'line 3: "no-such-skill" (implement) is not a project agent'
  assert_contains "$OUT" 'line 4: row has no signal'
  assert_contains "$OUT" 'line 5: row "b/**" names no skill or agent'
  assert_contains "$OUT" 'line 6: "android-implementer" (implement) is both a project agent and a project skill'
  assert_contains "$OUT" 'line 7: "../../etc/passwd" (implement) is not a skill or agent name'
  run_rc 1 "$ROUTE" match "$p" implement c/x
  assert_contains "$OUT" 'invalid project routing table'
  assert_not_contains "$OUT" 'skill	' 'match routed from a broken table'

  printf 'No table here.\n' > "$p/.specify/routing.md"
  run_rc 1 "$ROUTE" check "$p"
  assert_contains "$OUT" 'no routing table'
}

# What a teammate's editor does to the file: CRLF line ends, alignment colons,
# no backticks. And a table inside an HTML comment renders as nothing, so it
# routes nothing.
test_crlf_table_is_read_and_a_commented_out_table_is_not() {
  local p; p="$(project)"
  printf '| signal | implement | review |\r\n|:---|:--:|---:|\r\n| apps/android/**, *.kt | android-implementer | android-reviewer |\r\n' \
    > "$p/.specify/routing.md"
  run_rc 0 "$ROUTE" check "$p"
  run_rc 0 "$ROUTE" match "$p" review shared/Util.kt
  assert_eq 'skill:android-reviewer' "$(names)" 'a CRLF table was not read'

  printf '<!--\n| Signal | Implement |\n|---|---|\n| `apps/**` | `no-such-skill` |\n-->\n\n| Signal | Implement |\n|---|---|\n| `apps/tv/**` | `bigscreen-implementer` |\n' \
    > "$p/.specify/routing.md"
  run_rc 0 "$ROUTE" check "$p"
  assert_contains "$OUT" 'project routing valid (1 row(s)' 'a commented-out table was read'
  run_rc 0 "$ROUTE" match "$p" implement apps/android/A.kt
  assert_eq '' "$OUT" 'a commented-out row routed a task'
}

# No routing.md is the common case: silent, and never an error.
test_project_without_a_table_is_silent() {
  mkdir -p "$SANDBOX/plain"
  run_rc 0 "$ROUTE" match "$SANDBOX/plain" implement src/a.ts
  assert_eq '' "$OUT"
  run_rc 0 "$ROUTE" check "$SANDBOX/plain"
  assert_contains "$OUT" 'no project routing table'
  run_rc 2 "$ROUTE" match "$SANDBOX/plain" deploy
  run_rc 2 "$ROUTE" check "$SANDBOX/missing"
  run_rc 2 "$ROUTE"
}

# Kit agents and skills are names too; a project agent with no model of its
# own is called out, because the kit cannot stamp it.
test_kit_names_resolve_and_an_unpinned_project_agent_is_flagged() {
  local p; p="$(project)"
  printf -- '---\nname: bigscreen-implementer\n---\n' > "$p/.claude/agents/bigscreen-implementer.md"
  cat > "$p/.specify/routing.md" <<'EOF'
| Signal | Implement | Review |
|---|---|---|
| `apps/tv/**` | `bigscreen-implementer` | `security-reviewer` |
| `web/**` | `react-expert` | `opponent` |
EOF
  run_rc 0 "$ROUTE" check "$p"
  assert_contains "$OUT" "project agent 'bigscreen-implementer' pins no model:"
  run_rc 0 "$ROUTE" match "$p" implement web/App.tsx
  assert_eq "agent	react-expert	$KIT_DIR/agents/react-expert.md	web/**" "$OUT"
  run_rc 0 "$ROUTE" match "$p" review web/App.tsx
  assert_eq "agent	opponent	$KIT_DIR/agents/opponent.agent.md	web/**" "$OUT"
}

# The shipped template is a valid table once the skills it names exist.
test_shipped_template_is_a_valid_table() {
  local p="$SANDBOX/tpl" name
  mkdir -p "$p/.specify"
  cp "$KIT_DIR/templates/routing-template.md" "$p/.specify/routing.md"
  for name in android-implementer android-reviewer ios-implementer ios-reviewer \
              bigscreen-implementer bigscreen-reviewer acme-architecture; do
    mkdir -p "$p/.claude/skills/$name" && : > "$p/.claude/skills/$name/SKILL.md"
  done
  run_rc 0 "$ROUTE" check "$p"
  run_rc 0 "$ROUTE" match "$p" implement apps/ios/App.swift
  assert_eq 'skill:ios-implementer' "$(names)"
}

# Every dispatcher asks the script; none is left to read the table by eye.
test_every_dispatcher_asks_the_script() {
  local f
  for f in skills/sdd-plan/SKILL.md skills/sdd-implement/SKILL.md agents/sdd-orchestrator.md templates/stack-routing.md; do
    assert_contains "$(cat "$KIT_DIR/$f")" 'project-routing.sh' "$f"
  done
  assert_contains "$(cat "$KIT_DIR/skills/sdd-implement/SKILL.md")" 'match "$WT" implement --task'
  assert_contains "$(cat "$KIT_DIR/skills/sdd-implement/SKILL.md")" 'match "$WT" review --diff'
  assert_contains "$(cat "$KIT_DIR/agents/sdd-orchestrator.md")" 'match "$WT" review --diff'
  assert_contains "$(cat "$KIT_DIR/templates/stack-routing.md")" '### Project review'
  assert_contains "$(cat "$KIT_DIR/templates/umbrella-guide.md")" '.specify/routing.md'
}

t_run_all
