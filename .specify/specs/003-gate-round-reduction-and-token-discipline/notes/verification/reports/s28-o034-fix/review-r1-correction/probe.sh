#!/bin/bash
. /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/tests/helpers.sh
proof_dir="$1"
mkdir -p "$proof_dir"
SANDBOX="$proof_dir/fixture"
mkdir -p "$SANDBOX"
i=0
while IFS=$'\t' read -r kind fixture; do
  i=$((i+1))
  case_dir="$proof_dir/$(printf '%03d' "$i")"
  mkdir -p "$case_dir"
  spec_dir="$(make_spec_dir)"
  sed "s|\`node --test test/thing.test.js\`|\`$fixture\`|" "$spec_dir/tasks.md" > "$case_dir/tasks.md"
  cp "$case_dir/tasks.md" "$spec_dir/tasks.md"
  printf '%s\n' "$fixture" > "$case_dir/verify.txt"
  printf '%s\n' "$ANALYZER" "$spec_dir" > "$case_dir/argv.txt"
  "$ANALYZER" "$spec_dir" > "$case_dir/output.txt" 2>&1
  rc=$?
  printf '%s\n' "$rc" > "$case_dir/exit.txt"
  warned=no; grep -q 'untyped AC Verify' "$case_dir/output.txt" && warned=yes
  printf '%s\t%s\t%s\t%s\t%s\n' "$i" "$kind" "$rc" "$warned" "$fixture"
done < "$2"
