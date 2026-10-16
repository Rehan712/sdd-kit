#!/usr/bin/env bash
# Push the snapshot commit to a throwaway branch and open a draft PR, as
# Rehan712, without changing the active gh account: GH_TOKEN is scoped to this
# process and never printed. Usage (worktree root): push-and-pr.sh <ci-dir>
set -uo pipefail
P="$1" repo=Rehan712/sdd-kit branch=ci-snapshot/spec-003-20261015
commit="$(cat "$P/commit.txt")"
[[ ! -e "$P/push.rc" ]] || { echo "refusing: push.rc exists" >&2; exit 2; }
GH_TOKEN="$(gh auth token -h github.com -u Rehan712)" || { echo 'no Rehan712 token' >&2; exit 3; }
export GH_TOKEN
[[ "$(gh api user --jq .login)" == Rehan712 ]] || { echo 'token is not Rehan712' >&2; exit 3; }
git push origin "+${commit}:refs/heads/${branch}" > "$P/push.log" 2>&1; rc=$?; echo "$rc" > "$P/push.rc"
printf 'push exit=%s\n' "$rc"; (( rc == 0 )) || exit "$rc"
gh pr create --repo "$repo" --draft --base main --head "$branch" \
  --title "DO NOT MERGE: spec 003 CI snapshot $(cut -c1-8 "$P/source.txt")" --body-file "$P/pr-body.md" > "$P/pr.log" 2>&1; rc=$?; echo "$rc" > "$P/pr.rc"
printf 'pr exit=%s %s\n' "$rc" "$(tail -1 "$P/pr.log")"
exit "$rc"
