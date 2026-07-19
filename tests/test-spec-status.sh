#!/usr/bin/env bash
# test-spec-status.sh — validated append-only STATUS decisions.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"
SPEC_STATUS="$SCRIPTS/spec-status.sh"

write_status_with_decisions() {
  local spec_dir="$1"
  cat > "$spec_dir/STATUS.md" <<'EOF'
---
spec: 001-test-feature
phase: tasks
updated: 2026-01-01
---
# Status

## Where things stand

Waiting for work.

## Decisions log

- 2026-01-01 — Original decision.

## Open questions / blockers

(none)
EOF
}

test_append_decision_adds_dated_entry_at_end_and_updates_frontmatter() {
  local spec_dir status expected
  spec_dir="$(make_spec_dir)"
  write_status_with_decisions "$spec_dir"

  run_rc 0 "$SPEC_STATUS" append-decision "$spec_dir" "Parked unit abc123 for implement"
  status="$(cat "$spec_dir/STATUS.md")"
  assert_contains "$status" "updated: $TODAY"
  assert_contains "$status" "- $TODAY — Parked unit abc123 for implement"
  expected="$(printf '%s\n\n- %s — %s\n\n## Open questions / blockers' \
    "- 2026-01-01 — Original decision." "$TODAY" "Parked unit abc123 for implement")"
  assert_contains "$status" "$expected" "entry is last in the decisions log"
}

test_append_decision_refuses_missing_section_without_mutation() {
  local spec_dir before after
  spec_dir="$(make_spec_dir)"
  before="$(cat "$spec_dir/STATUS.md")"

  run_rc 1 "$SPEC_STATUS" append-decision "$spec_dir" "Should not be written"
  after="$(cat "$spec_dir/STATUS.md")"
  assert_contains "$OUT" "requires exactly one ## Decisions log section (found 0)"
  assert_eq "$before" "$after" "missing decisions log leaves STATUS.md untouched"
}

test_append_decision_refuses_duplicate_sections_without_mutation() {
  local spec_dir before after
  spec_dir="$(make_spec_dir)"
  write_status_with_decisions "$spec_dir"
  cat >> "$spec_dir/STATUS.md" <<'EOF'

## Decisions log

- 2026-01-02 — Duplicate section.
EOF
  before="$(cat "$spec_dir/STATUS.md")"

  run_rc 1 "$SPEC_STATUS" append-decision "$spec_dir" "Should not be written"
  after="$(cat "$spec_dir/STATUS.md")"
  assert_contains "$OUT" "requires exactly one ## Decisions log section (found 2)"
  assert_eq "$before" "$after" "duplicate decisions logs leave STATUS.md untouched"
}

t_run_all
