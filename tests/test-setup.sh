#!/usr/bin/env bash
# test-setup.sh — the install path: setup.sh, sync.sh and sdd-doctor.sh.
#
# Hermetic by construction: each test copies the kit into $SANDBOX/kit and runs
# with HOME=$SANDBOX/home, so the machine's real ~/.sdd, Claude homes and
# models.yml are never read or written. The resume scheduler is stubbed: the
# doctor must not list this machine's real scheduler jobs.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

# stage — kit copy in $SANDBOX/kit plus a fresh $SANDBOX/home with one Claude
# home. Echoes the kit's physical path (setup.sh links ~/.sdd to that).
stage() {
  local kit="$SANDBOX/kit"
  mkdir -p "$SANDBOX/home/.claude"
  copy_kit "$KIT_DIR" "$kit" >&2 || { fixture_build_failed 'setup kit copy'; echo "$kit"; return 1; }
  (cd "$kit" && pwd -P)
}

in_home() {  # <command...> — run with the sandbox home and a stubbed scheduler
  env HOME="$SANDBOX/home" SDD_RESUME_ROOT="$SANDBOX/resume" \
    SDD_RESUME_SCHEDULER=/usr/bin/true "$@"
}

# A first install must not send the user to research the example map's
# placeholder repos, and must leave every home link and stamped copy in place.
test_fresh_install_links_homes_and_does_not_onboard_example_repos() {
  local kit; kit="$(stage)"
  run_rc 0 in_home bash "$kit/scripts/setup.sh" --no-wizard --no-cli
  assert_eq "$kit" "$(readlink "$SANDBOX/home/.sdd")" 'setup did not link ~/.sdd to the clone'
  [[ -L "$SANDBOX/home/.claude/skills/sdd-plan" && -L "$SANDBOX/home/.claude/agents/sdd-scout.md" ]] \
    || t_fail 'setup left a skill or agent unlinked'
  # "all green", or warnings only (no gh on this machine) — never an error.
  assert_not_contains "$OUT" 'error(s)' 'the doctor reports an error on a fresh install'
  assert_contains "$OUT" 'still the shipped example' 'doctor does not say why briefs are skipped'
  assert_not_contains "$OUT" 'have no repo brief' 'setup asks to onboard the example placeholder repos'
  assert_not_contains "$OUT" 'briefs: 3 missing' 'doctor counts the example placeholder repos as missing briefs'
}

# ~/.sdd pointing at another LIVE clone is someone's working install: setup
# refuses to switch it without --relink, and repairs a dangling link silently.
test_setup_refuses_to_repoint_a_live_install_without_relink() {
  local kit other; kit="$(stage)"
  other="$SANDBOX/other-kit"; mkdir -p "$other"; other="$(cd "$other" && pwd -P)"
  ln -s "$other" "$SANDBOX/home/.sdd"
  run_rc 1 in_home bash "$kit/scripts/setup.sh" --no-wizard --no-cli
  assert_contains "$OUT" 'already points at another kit clone'
  assert_contains "$OUT" '--relink'
  assert_eq "$other" "$(readlink "$SANDBOX/home/.sdd")" 'the refused run still re-pointed ~/.sdd'
  [[ ! -e "$kit/models.yml" ]] || t_fail 'the refused run configured the kit anyway'

  run_rc 0 in_home bash "$kit/scripts/setup.sh" --no-wizard --no-cli --relink
  assert_eq "$kit" "$(readlink "$SANDBOX/home/.sdd")" '--relink did not switch ~/.sdd'

  # The clone moved: the old target is gone, so there is nothing to protect.
  rm "$SANDBOX/home/.sdd"; ln -s "$SANDBOX/moved-away" "$SANDBOX/home/.sdd"
  run_rc 0 in_home bash "$kit/scripts/setup.sh" --no-wizard --no-cli
  assert_eq "$kit" "$(readlink "$SANDBOX/home/.sdd")" 'a dangling ~/.sdd was not repaired'
}

# sync.sh resolves the kit physically, so running it through another path to
# the same clone (a symlinked parent, ~/.sdd itself) agrees with the links
# setup made instead of reporting every one of them as pointing elsewhere.
test_sync_agrees_with_itself_through_a_symlinked_path() {
  local kit; kit="$(stage)"
  run_rc 0 in_home bash "$kit/scripts/setup.sh" --no-wizard --no-cli
  ln -s "$kit" "$SANDBOX/kit-link"
  run_rc 0 in_home bash "$SANDBOX/kit-link/scripts/sync.sh" --check
  run_rc 0 in_home bash "$SANDBOX/home/.sdd/scripts/sync.sh" --check
  run_rc 0 in_home bash "$SANDBOX/kit-link/scripts/sync.sh"
  assert_contains "$OUT" 'linked/repaired: 0' 'a second path to the same clone re-pointed the home links'
}

# doctor --all reads the registry through lib.sh: a quoted ~ path with an
# inline comment is a real project, not `"~/proj"  # mine`.
test_doctor_all_expands_registry_paths() {
  local kit; kit="$(stage)"
  run_rc 0 in_home bash "$kit/scripts/setup.sh" --no-wizard --no-cli
  mkdir -p "$SANDBOX/home/proj"
  printf 'projects:\n  - name: p\n    path: "~/proj"  # mine\n    stacks: [rust]\n' > "$kit/registry.yml"
  run_rc 0 in_home bash "$kit/scripts/sdd-doctor.sh" --all
  assert_contains "$OUT" "Project: $SANDBOX/home/proj"
  assert_not_contains "$OUT" 'path does not exist'
}

# A valid policy that leaves a known role unmapped is a warning the doctor
# shows, with the command that fixes it — not something `models.yml valid` hides.
test_doctor_surfaces_unmapped_roles() {
  local kit; kit="$(stage)"
  run_rc 0 in_home bash "$kit/scripts/setup.sh" --no-wizard --no-cli
  run_rc 0 in_home bash "$kit/scripts/model-policy.sh" --no-apply unset role go
  run_rc 0 in_home bash "$kit/scripts/sdd-doctor.sh" --hub-only
  assert_contains "$OUT" "models.yml: role 'go' not mapped"
  assert_contains "$OUT" 'model-policy.sh set role go <tier>'
}

t_run_all
