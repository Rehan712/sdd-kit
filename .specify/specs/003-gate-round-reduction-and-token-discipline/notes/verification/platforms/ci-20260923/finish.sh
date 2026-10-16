#!/usr/bin/env bash
# Collect the hosted-CI evidence, then close the draft PR unmerged and delete the
# throwaway branch, as Rehan712 via a process-scoped GH_TOKEN (never printed; the
# active gh account is not changed). Usage (worktree root): finish.sh <ci-dir>
set -uo pipefail
P="$1" repo=Rehan712/sdd-kit branch=ci-snapshot/spec-003-20260923
tree=3e638490ed9a92bcdb8faff9fdd529b4e7021a15 commit="$(cat "$P/commit.txt")"
[[ ! -e "$P/collect.rc" ]] || { echo 'refusing: collect.rc exists' >&2; exit 2; }
GH_TOKEN="$(gh auth token -h github.com -u Rehan712)" || exit 3; export GH_TOKEN
run="$(cat "$P/run-id.txt")"
bash "$P/collect.sh" "$run" "$P/run-$run" "$tree" "$commit" > "$P/collect.log" 2>&1; echo "$?" > "$P/collect.rc"
printf 'collect exit=%s\n' "$(cat "$P/collect.rc")"
pr="$(tail -1 "$P/pr.log")"; pr="${pr##*/}"
gh pr close "$pr" --repo "$repo" --comment 'Hosted-CI evidence collected; closing unmerged as planned. Not for merge.' > "$P/pr-close.log" 2>&1; echo "$?" > "$P/pr-close.rc"
git push origin --delete "$branch" > "$P/branch-delete.log" 2>&1; echo "$?" > "$P/branch-delete.rc"
gh pr view "$pr" --repo "$repo" --json state,closed,closedAt,mergedAt,isDraft,headRefOid \
  --jq '"state=\(.state) closed=\(.closed) closedAt=\(.closedAt) mergedAt=\(.mergedAt) draft=\(.isDraft) head=\(.headRefOid)"' > "$P/pr-final-state.txt" 2>&1
if [[ -n "$(git ls-remote --heads origin "$branch")" ]]; then echo 'remote branch now: PRESENT' >> "$P/pr-final-state.txt"; else echo 'remote branch now: absent' >> "$P/pr-final-state.txt"; fi
printf 'pr-close exit=%s branch-delete exit=%s\n' "$(cat "$P/pr-close.rc")" "$(cat "$P/branch-delete.rc")"
cat "$P/pr-final-state.txt"
