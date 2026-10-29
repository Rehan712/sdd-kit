# Publishing plan — NOT EXECUTED

Run only after explicit approval for this exact snapshot. Every shell block starts from the existing worktree; no checkout, real-index update, spec-branch commit, or spec-branch push is needed. The only new commit is a temporary CI commit with the fixed tree and parent below. Its SHA does not exist yet.

## 1. Verify the local bindings again

```bash
cd /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline
set -euo pipefail
export GIT_OPTIONAL_LOCKS=0
out="$PWD/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261025-s26"
parent=2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9
tree=43292032de54f25df06531471b07ada5da0becf0
branch=ci-snapshot/spec-003-20261025-s26
repo=Rehan712/sdd-kit
bash "$out/verify-prepublish.sh"
```

The verifier revalidates the current source identity, original HEAD/index bytes, every source-file mode/raw blob, the saved tree/index, manifest mapping, historical-helper immutability, and the original parent-index binding. It does not rebuild or substitute a newer tree. If any binding fails, stop and prepare a new review before publishing.

## 2. Recheck the remote base, then create and push the single snapshot commit

```bash
cd /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline
# Continue in the same shell, with the variables above.
main_sha="$(gh api "repos/$repo/git/ref/heads/main" --jq .object.sha)"
gh api "repos/$repo/compare/$main_sha...$parent" > "$out/main-parent-comparison.json"
jq -e --arg base "$main_sha" '.merge_base_commit.sha == $base and (.status == "ahead" or .status == "identical")' "$out/main-parent-comparison.json"
if git show-ref --verify --quiet "refs/heads/$branch"; then
  echo 'STOP: proposed local snapshot branch already exists' >&2
  exit 1
fi
# Run this creation once; retain the resulting SHA for all subsequent steps.
commit="$(git commit-tree "$tree" -p "$parent" -m 'test(ci): snapshot spec 003 RC3 source a7e7dd32 (s26)')"
printf '%s\n' "$commit" > "$out/approved-snapshot-head.txt"
test "$(git rev-parse "$commit^{tree}")" = "$tree"
test "$(git rev-parse "$commit^")" = "$parent"
# Lease requires this remote branch to be absent; never overwrite an old run.
git push --force-with-lease="refs/heads/$branch:" origin "$commit:refs/heads/$branch"
gh pr create --repo "$repo" --head "$branch" --base main --draft \
  --title 'test(ci): spec 003 RC3 snapshot (s26)' --body-file "$out/pr-body.md" \
  > "$out/snapshot-pr-url.txt"
cat "$out/snapshot-pr-url.txt"
```

Immediately register the returned PR URL with T3 `link_pull_request`; retain the URL before any retry. Do not create a duplicate PR after a lost response: inspect the branch's PR first. Opening this draft PR triggers the existing `pull_request` workflow. There is no `workflow_dispatch`; pushing this branch alone does not trigger the workflow. Do not merge this PR. A remote-base change after this check is caught by the collector's exact merge-tree check.

## 3. Observe and collect the actual hosted run

```bash
cd /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline
# Recover these bindings if a later shell is used.
out="$PWD/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261025-s26"
repo=Rehan712/sdd-kit
branch=ci-snapshot/spec-003-20261025-s26
commit="$(cat "$out/approved-snapshot-head.txt")"
gh run list --repo "$repo" --branch "$branch" --workflow ci.yml --event pull_request \
  --json databaseId,headSha,status,conclusion,url > "$out/run-candidates.json"
jq --arg head "$commit" '[.[] | select(.headSha == $head)]' "$out/run-candidates.json"
```

Use only an actual returned run ID whose head equals the saved commit. If still running, the parent can register `watch_pull_request` and end its turn; this builder does not poll. After that run completes, set `run` to its observed numeric `databaseId`, then execute:

```bash
cd /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline
# run must come from the actual matching run above; no historical/synthetic ID.
: "${run:?set run to the observed matching GitHub databaseId}"
bash "$out/collect.sh" "$run" "$out/hosted-$run" "$commit" > "$out/hosted-$run.log" 2>&1
jq -e --arg head "$commit" --arg branch "$branch" \
  '.head_sha == $head and .head_branch == $branch and .event == "pull_request" and .status == "completed" and .conclusion == "success" and .path == ".github/workflows/ci.yml"' \
  "$out/hosted-$run/run.json"
jq -e '(.jobs | length) == 4 and ([.jobs[].name] | sort) == (["shellcheck", "tests (ubuntu-latest)", "tests (macos-latest)", "tests-bash32"] | sort) and all(.jobs[]; .status == "completed" and .conclusion == "success")' \
  "$out/hosted-$run/jobs.json"
cat "$out/hosted-$run.log"
bash "$out/verify-prepublish.sh"
```

The copied collector requires the actual snapshot commit as argument 3, fetches real logs, and checks the tested PR merge tree equals `43292032de54f25df06531471b07ada5da0becf0`. Keep the full run URL, attempt, head, merge commit/tree, jobs, runner identities, steps and logs. Failures or a different tested tree cannot support current AC-019. Only after these pass may the parent attach hostedCI evidence to its current RC3 process. RC3 completion, gate mutations, PR cleanup and any later merge are outside this builder's scope and this publishing sequence.
