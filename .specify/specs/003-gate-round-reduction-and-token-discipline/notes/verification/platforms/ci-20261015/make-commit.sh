#!/usr/bin/env bash
# Build the snapshot (build-snapshot.sh through a temporary index), then create
# the snapshot commit on parent 0d55c62 with git commit-tree: HEAD, the real
# index and the spec branch are untouched. Usage (worktree root): make-commit.sh <ci-dir>
set -uo pipefail
P="$1"
[[ ! -e "$P/commit.txt" ]] || { echo "refusing: commit.txt exists" >&2; exit 2; }
bash "$P/build-snapshot.sh" "$P/snapshot" > "$P/build.log" 2>&1; rc=$?; echo "$rc" > "$P/build.rc"
printf 'build exit=%s\n' "$rc"; (( rc == 0 )) || exit "$rc"
tree="$(sed -n 's/^tree=//p' "$P/build.log")"; source="$(sed -n 's/^source=//p' "$P/build.log")"
printf '%s\n' "$tree" > "$P/tree.txt"; printf '%s\n' "$source" > "$P/source.txt"
cat > "$P/commit-msg.txt" <<MSG
ci-snapshot: spec 003 platform evidence for source ${source:0:8}

Throwaway snapshot of the exact non-ignored worktree of
spec/003-gate-round-reduction-and-token-discipline at 0d55c62, built
through a temporary index for AC-019 hosted-CI evidence after
T030o54 to T030o56 and opponent round 19.
Not for merge.

Source identity: $source
Tree: $tree

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
MSG
commit="$(git commit-tree "$tree" -p 0d55c62 -F "$P/commit-msg.txt")" || exit 3
printf '%s\n' "$commit" > "$P/commit.txt"
cat > "$P/pr-body.md" <<BODY
**Do not merge.** Throwaway snapshot that exists only to run \`.github/workflows/ci.yml\` on the exact uncommitted worktree of spec 003 (gate round reduction and token discipline) for its AC-019 platform evidence, after the T030o54 to T030o56 repairs and opponent round 19. It will be closed and its branch deleted as soon as the job logs are saved.

- Snapshot commit \`$commit\`, tree \`$tree\`, parent \`0d55c62\` (spec branch HEAD).
- Verification source identity \`$source\` (mapping in \`build.log\`).
- The spec's guarded PR (T032) is separate and is not this one.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
BODY
printf 'commit=%s tree=%s source=%s\n' "$commit" "$tree" "$source"
