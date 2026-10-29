#!/usr/bin/env bash
# Collect hosted-CI evidence for run $1 into $2 (read-only against GitHub).
# Requires GH_TOKEN in the environment. Never prints the token.
# Third argument binds the new commit created only after approval.
set -uo pipefail
{
run="$1" out="$2" repo=Rehan712/sdd-kit
want_tree=e68740dbbf9d10e3abcdfd0c6620ed9c3abd04e1
want_head="${3:?usage: collect.sh <run-id> <out-dir> <approved-snapshot-head>}"
mkdir -p "$out"
fail=0
gh api "repos/$repo/actions/runs/$run" > "$out/run.json" || { echo "run api failed"; exit 3; }
gh api "repos/$repo/actions/runs/$run/jobs?per_page=50" > "$out/jobs.json" || { echo "jobs api failed"; exit 3; }
printf 'run=%s status=%s conclusion=%s event=%s head_sha=%s attempt=%s\n' "$run" \
  "$(jq -r .status "$out/run.json")" "$(jq -r .conclusion "$out/run.json")" \
  "$(jq -r .event "$out/run.json")" "$(jq -r .head_sha "$out/run.json")" "$(jq -r .run_attempt "$out/run.json")"
[[ "$(jq -r .head_sha "$out/run.json")" == "$want_head" ]] || { echo "FAIL: head_sha is not the snapshot commit"; fail=1; }
jq -r '.jobs[] | [.id, .name, .status, .conclusion, .runner_name, (.labels|join(",")), .started_at, .completed_at] | @tsv' "$out/jobs.json" > "$out/jobs.tsv"
while IFS=$'\t' read -r id name status conclusion runner labels started completed; do
  safe="$(printf '%s' "$name" | tr -c 'A-Za-z0-9._-' '_')"
  gh api "repos/$repo/actions/jobs/$id/logs" --allow-escape-sequences > "$out/job-$safe.log" 2> "$out/job-$safe.log.err"
  lrc=$?
  printf '\n== job %s (%s)\n' "$name" "$id"
  printf '  status=%s conclusion=%s runner=%s labels=%s\n  started=%s completed=%s log-fetch-exit=%s log-bytes=%s\n' \
    "$status" "$conclusion" "$runner" "$labels" "$started" "$completed" "$lrc" "$(wc -c < "$out/job-$safe.log" | tr -d ' ')"
  [[ "$conclusion" == success ]] || fail=1
  [[ "$lrc" == 0 ]] || fail=1
  jq -r --argjson id "$id" '.jobs[] | select(.id==$id) | .steps[] | "  step \(.number) \(.name): \(.status) \(.conclusion)"' "$out/jobs.json"
  # Runner identity lines from the "Set up job" section.
  grep -E 'Runner Image|Image: |Version: |Operating System|^[0-9TZ:.-]+ (Ubuntu|macOS)|Runner name|Runner Image Provisioner|Included Software' "$out/job-$safe.log" | head -12 | sed 's/^[0-9TZ:.-]* /  id: /'
  grep -E 'shell: ' "$out/job-$safe.log" | sed 's/^[0-9TZ:.-]* /  /' | sort -u
  grep -E 'Process completed with exit code' "$out/job-$safe.log" | sed 's/^[0-9TZ:.-]* /  EXIT: /'
  grep -E 'HEAD is now at|Checking out the ref|/pull/[0-9]+/merge' "$out/job-$safe.log" | head -3 | sed 's/^[0-9TZ:.-]* /  checkout: /'
  if grep -q -- '-- [0-9]*/[0-9]* passed' "$out/job-$safe.log"; then
    sed 's/^[0-9TZ:.-]* //' "$out/job-$safe.log" | grep -E '^  -- [0-9]+/[0-9]+ passed$' |
      awk '{split($2,a,"/"); p+=a[1]; t+=a[2]; n++} END {printf "  suites=%d passed=%d total=%d\n", n, p, t}'
    printf '  ok-lines=%s not-ok-lines=%s\n' \
      "$(sed 's/^[0-9TZ:.-]* //' "$out/job-$safe.log" | grep -c '^  ok ')" \
      "$(sed 's/^[0-9TZ:.-]* //' "$out/job-$safe.log" | grep -E '^  [A-Za-z]' | grep -vc '^  ok ')"
  fi
done < "$out/jobs.tsv"
# The pull_request checkout tests GitHub's merge commit; prove its tree.
merge_sha="$(grep -ho 'HEAD is now at [0-9a-f]*' "$out"/job-*.log | awk '{print $5}' | sort -u)"
printf '\nmerge-commit-short(s) checked out: %s\n' "$(printf '%s' "$merge_sha" | tr '\n' ' ')"
full_sha="$(grep -hoE 'git -c protocol.version=2 fetch .* \+?[0-9a-f]{40}:refs/remotes/pull/[0-9]+/merge' "$out"/job-*.log | grep -oE '[0-9a-f]{40}' | sort -u)"
printf 'merge-commit(s) fetched: %s\n' "$(printf '%s' "$full_sha" | tr '\n' ' ')"
for sha in $full_sha; do
  tree="$(gh api "repos/$repo/git/commits/$sha" --jq .tree.sha)"
  parents="$(gh api "repos/$repo/git/commits/$sha" --jq '[.parents[].sha]|join(",")')"
  printf 'merge %s tree=%s parents=%s\n' "$sha" "$tree" "$parents"
  [[ "$tree" == "$want_tree" ]] || { echo "FAIL: tested merge tree differs from snapshot tree"; fail=1; }
done
[[ -n "$full_sha" ]] || { echo "FAIL: could not identify the tested merge commit"; fail=1; }
printf 'collect result: %s\n' "$([[ $fail == 0 ]] && echo PASS || echo FAIL)"
exit "$fail"
# Keep raw artifact bytes; remove terminal controls only from human diagnostics.
} | LC_ALL=C tr -cd '\11\12\40-\176'
