#!/bin/bash
. "$1/tests/defs-test-sdd-analyze.sh"
export SANDBOX="$2"
mkdir -p "$SANDBOX"
  # AC-004: real shell runners remain valid; an untyped build/typecheck/text-only
  # command warns even if its displayed expected output says tests passed.
  for fixture in 'npm run build' 'npm run typecheck' 'tsc --noEmit' 'grep AC-001 README.md'; do
    spec_dir="$(make_spec_dir)"
    verification_edit_fixture "$spec_dir/tasks.md" "s|\`node --test test/thing.test.js\`|\`$fixture\`|"
    run_rc 0 "$ANALYZE" "$spec_dir"
    assert_contains "$OUT" 'untyped AC Verify' "AC-004: untyped $fixture warns without breaking legacy"
  done
  spec_dir="$(make_spec_dir)"
  verification_edit_fixture "$spec_dir/tasks.md" 's/`node --test test\/thing.test.js`/`bash tests\/check.sh`/'
  run_rc 0 "$ANALYZE" "$spec_dir"
  assert_not_contains "$OUT" 'untyped AC Verify' 'AC-004: shell test runners need no framework wrapper'

printf 'classifier assertions failed=%s
' "$_t_fail"
exit "$_t_fail"
