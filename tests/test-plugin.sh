#!/usr/bin/env bash
# test-plugin.sh — the plugin under plugin/: its manifests and its installer.
#
# The plugin is the kit's installer for Claude Code, Codex, Copilot, Cursor and
# Antigravity. Hermetic: the installer runs with HOME=$SANDBOX/home and clones
# a sandbox copy of the kit (SDD_KIT_REPO), never github.com, and the machine's
# real ~/.sdd is never read or written.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

INSTALL="$KIT_DIR/plugin/skills/sdd-setup/scripts/install.sh"

# json_value <file> <key> — the first top-level-looking "key": "value".
json_value() { sed -n "s/^[[:space:]]*\"$2\":[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$1" | head -1; }

# Each host reads its own manifest, so the same plugin is described three
# times. They must name one plugin at one version, or two hosts disagree about
# what is installed and whether an update exists.
test_manifests_name_one_plugin_at_one_version() {
  local f name version
  version="$(json_value "$KIT_DIR/plugin/plugin.json" version)"
  [[ -n "$version" ]] || t_fail 'plugin/plugin.json has no version'
  for f in plugin/plugin.json plugin/.claude-plugin/plugin.json plugin/.cursor-plugin/plugin.json; do
    [[ -f "$KIT_DIR/$f" ]] || { t_fail "missing $f"; continue; }
    name="$(json_value "$KIT_DIR/$f" name)"
    assert_eq sdd-kit "$name" "$f names another plugin"
    assert_eq "$version" "$(json_value "$KIT_DIR/$f" version)" "$f is at another version"
  done
  # Agent Plugins hosts (Codex, Copilot, Antigravity) reject a root manifest
  # without the schema line.
  assert_contains "$(cat "$KIT_DIR/plugin/plugin.json")" 'agent-plugins.org/schemas/1.0.0/plugin.schema.json'
}

# The marketplaces must point at plugin/ — never at the repository root, whose
# skills/ and agents/ are the kit's canonical files: installed as plugin
# content they load unstamped and under other names, next to the real install.
test_marketplaces_point_at_the_plugin_folder() {
  local f
  for f in .claude-plugin/marketplace.json .cursor-plugin/marketplace.json; do
    [[ -f "$KIT_DIR/$f" ]] || { t_fail "missing $f"; continue; }
    assert_eq sdd-kit "$(json_value "$KIT_DIR/$f" name)" "$f names another marketplace"
    case "$(json_value "$KIT_DIR/$f" source)" in
      plugin|./plugin) ;;
      *) t_fail "$f does not point at plugin/: $(json_value "$KIT_DIR/$f" source)" ;;
    esac
  done
  [[ ! -e "$KIT_DIR/plugin.json" ]] \
    || t_fail 'a root plugin.json makes the whole repository the plugin'
}

# Cursor and Antigravity refuse a skill whose name is not its folder name.
test_setup_skill_is_named_after_its_folder() {
  local f="$KIT_DIR/plugin/skills/sdd-setup/SKILL.md"
  assert_eq 'name: sdd-setup' "$(sed -n '2p' "$f")" 'sdd-setup SKILL.md frontmatter'
  # An agent's shell can be a terminal: without the flag a first install stops
  # at the model wizard's prompts.
  assert_contains "$(cat "$f")" 'scripts/install.sh" --no-wizard' 'the skill runs the installer without --no-wizard'
  [[ -x "$INSTALL" ]] || t_fail 'install.sh is not executable'
}

# origin — a git repository holding the kit, standing in for github.com.
origin() {
  make_host_kit "$SANDBOX/origin" || { fixture_build_failed 'plugin origin kit'; return 1; }
  fixture_git -C "$SANDBOX/origin" add -A >/dev/null 2>&1 \
    && fixture_git -C "$SANDBOX/origin" commit -qm kit \
    || { fixture_build_failed 'plugin origin commit'; return 1; }
  mkdir -p "$SANDBOX/home/.claude"
}

install() {  # [setup.sh flags...]
  env HOME="$SANDBOX/home" SDD_KIT_REPO="$SANDBOX/origin" SDD_RESUME_ROOT="$SANDBOX/resume" \
    SDD_RESUME_SCHEDULER=/usr/bin/true bash "$INSTALL" "$@"
}

# The whole point: from nothing to a working install, and again without harm.
test_install_clones_the_kit_runs_setup_and_is_repeatable() {
  origin || return 0
  run_rc 0 install --no-wizard --no-cli
  local hub; hub="$(cd "$SANDBOX/home/.sdd-kit" && pwd -P)"
  assert_eq "$hub" "$(readlink "$SANDBOX/home/.sdd")" 'the hub is not linked at ~/.sdd'
  [[ -L "$SANDBOX/home/.claude/skills/sdd-plan" ]] || t_fail 'setup.sh did not install the skills'
  [[ -f "$hub/registry.yml" ]] || t_fail 'no registry.yml was bootstrapped'
  [[ ! -e "$hub.cloning" ]] || t_fail 'the staging clone was left behind'

  # Machine-local state written after the install survives an update, and a
  # commit pushed upstream arrives.
  echo '# mine' >> "$hub/registry.yml"
  echo new > "$SANDBOX/origin/NEWFILE"
  fixture_git -C "$SANDBOX/origin" add NEWFILE >/dev/null \
    && fixture_git -C "$SANDBOX/origin" commit -qm new \
    || fixture_build_failed 'plugin origin second commit'
  run_rc 0 install --no-wizard --no-cli
  assert_contains "$OUT" 'already installed'
  [[ -f "$hub/NEWFILE" ]] || t_fail 'the update did not fast-forward the hub'
  assert_contains "$(cat "$hub/registry.yml")" '# mine' 'the update lost registry.yml edits'
}

# An existing install is someone's working clone, wherever it lives: it is
# updated in place, never replaced by a second clone at ~/.sdd-kit.
test_install_updates_an_existing_clone_in_place() {
  origin || return 0
  local live
  fixture_git clone -q "$SANDBOX/origin" "$SANDBOX/elsewhere" \
    || { fixture_build_failed 'plugin live clone'; return 0; }
  live="$(cd "$SANDBOX/elsewhere" && pwd -P)"
  ln -s "$live" "$SANDBOX/home/.sdd"
  run_rc 0 install --no-wizard --no-cli
  [[ ! -e "$SANDBOX/home/.sdd-kit" ]] || t_fail 'a second clone was made next to a live install'
  assert_eq "$live" "$(readlink "$SANDBOX/home/.sdd")" 'the live install link was re-pointed'
}

# Anything in the way is reported and left exactly as it was.
test_install_refuses_what_it_does_not_own() {
  origin || return 0
  mkdir -p "$SANDBOX/home/.sdd-kit"; echo keep > "$SANDBOX/home/.sdd-kit/notes.txt"
  run_rc 1 install --no-wizard --no-cli
  assert_contains "$OUT" 'not an SDD kit clone'
  assert_eq keep "$(cat "$SANDBOX/home/.sdd-kit/notes.txt")" 'a foreign ~/.sdd-kit was modified'
  [[ ! -e "$SANDBOX/home/.sdd" ]] || t_fail 'a refused install still linked ~/.sdd'

  # A clone killed half-way leaves only the staging folder, and the next run
  # starts over instead of refusing it.
  rm -rf "${SANDBOX:?}/home/.sdd-kit"; mkdir -p "$SANDBOX/home/.sdd-kit.cloning/half"
  run_rc 0 install --no-wizard --no-cli
  [[ -f "$SANDBOX/home/.sdd-kit/scripts/setup.sh" && ! -e "$SANDBOX/home/.sdd-kit.cloning" ]] \
    || t_fail 'an interrupted clone was not recovered'

  rm -rf "${SANDBOX:?}/home/.sdd-kit" "${SANDBOX:?}/home/.sdd"; mkdir -p "$SANDBOX/home/.sdd"
  run_rc 1 install --no-wizard --no-cli
  assert_contains "$OUT" 'not a symlink'
  [[ ! -e "$SANDBOX/home/.sdd-kit" ]] || t_fail 'cloned despite an unusable ~/.sdd'
}

t_run_all
