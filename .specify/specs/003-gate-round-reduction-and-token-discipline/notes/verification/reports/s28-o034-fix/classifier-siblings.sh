#!/bin/bash
. "$1/tests/defs-test-sdd-analyze.sh"
export SANDBOX="$2"
mkdir -p "$SANDBOX"
for edge_command in 'test -e README.md' 'test -f README.md' 'grep pytest README.md' 'rg bats README.md' 'diff fixtures/test.txt actual.txt' 'node --test test/thing.test.js' 'cargo test' 'pytest' 'bats test.bats' 'bash tests/check.sh'; do
  edge_spec="$(make_spec_dir)"
  verification_edit_fixture "$edge_spec/tasks.md" "s|\`node --test test/thing.test.js\`|\`$edge_command\`|"
  cp "$edge_spec/tasks.md" "$2/$(printf %03d "${edge_i:-0}").tasks.md"
  "$ANALYZE" "$edge_spec" > "$2/$(printf %03d "${edge_i:-0}").log" 2>&1
  edge_rc=$?
  if rg -q 'untyped AC Verify' "$2/$(printf %03d "${edge_i:-0}").log"; then edge_warn=yes; else edge_warn=no; fi
  printf 'exit=%s warning=%s command=%s
' "$edge_rc" "$edge_warn" "$edge_command"
  edge_i=$((${edge_i:-0}+1))
done
