#!/usr/bin/env bash
# test-knowledge-cues.sh — the retro loop is closed only if a filed lesson is
# opened again: every knowledge file carries the Cue line the phase skills
# select by, those skills run the lookup, and the lookup command they name
# finds every shipped file.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

# The command the skills print, verbatim (their home is ~/.sdd; here, the kit).
cues() { grep -m1 -H '^\*\*Cue:\*\*' "$1"/knowledge/*.md; }

test_every_knowledge_file_has_a_cue() {
  local f
  for f in "$KIT_DIR"/knowledge/*.md; do
    grep -q '^\*\*Cue:\*\* .' "$f" || t_fail "no **Cue:** line: knowledge/${f##*/}"
  done
}

test_the_lookup_the_skills_name_finds_every_file() {
  local files found
  files="$(find "$KIT_DIR/knowledge" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
  found="$(cues "$KIT_DIR" | wc -l | tr -d ' ')"
  assert_eq "$files" "$found" "the cue lookup must print one line per knowledge file"
}

test_specify_plan_and_tasks_run_the_lookup() {
  local phase
  for phase in specify plan tasks; do
    grep -qF "grep -m1 -H '^\\*\\*Cue:\\*\\*' ~/.sdd/knowledge/*.md" "$KIT_DIR/skills/sdd-$phase/SKILL.md" \
      || t_fail "skills/sdd-$phase never lists the knowledge cues — lessons filed for it are not read"
  done
}

test_retro_requires_a_cue_and_records_lessons_that_did_not_hold() {
  local skill template
  skill="$(cat "$KIT_DIR/skills/sdd-retro/SKILL.md")"
  template="$(cat "$KIT_DIR/templates/retro-template.md")"
  assert_contains "$skill" '**Cue:**' "retro must tell a new knowledge file to open with a cue"
  assert_contains "$skill" 'Lessons that did not hold'
  assert_contains "$template" 'Lessons that did not hold'
}

test_doctor_warns_on_a_knowledge_file_without_a_cue() {
  # The doctor finds its hub from its own path: a copy without the final main
  # call runs check_hub against a sandbox hub and leaves the real homes alone.
  local hub="$SANDBOX/hub" lib="$SANDBOX/hub/scripts/sdd-doctor-lib.sh" out
  mkdir -p "$hub/knowledge" "$hub/scripts"
  cp "$SCRIPTS/lib.sh" "$SCRIPTS/verification-lib.sh" "$hub/scripts/"
  sed '$d' "$SCRIPTS/sdd-doctor.sh" > "$lib"
  printf '# Cued\n\n**Cue:** a spec does X.\n' > "$hub/knowledge/cued.md"
  out="$(bash -c '. "$1"; check_hub' _ "$lib" 2>&1)"
  assert_contains "$out" 'every file opens with a **Cue:** line'
  printf '# Bare\n\nNo cue here.\n' > "$hub/knowledge/bare.md"
  out="$(bash -c '. "$1"; check_hub' _ "$lib" 2>&1)"
  assert_contains "$out" 'no phase will open it: bare.md'
}

t_run_all
