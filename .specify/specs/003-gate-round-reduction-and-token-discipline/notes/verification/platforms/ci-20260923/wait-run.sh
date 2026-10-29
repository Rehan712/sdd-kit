#!/usr/bin/env bash
# Poll the pull_request run for the snapshot commit until it completes (max ~45 min).
set -uo pipefail
P="$1" repo=Rehan712/sdd-kit commit="$(cat "$1/commit.txt")"
GH_TOKEN="$(gh auth token -h github.com -u Rehan712)" || exit 3; export GH_TOKEN
for i in $(seq 1 90); do
  gh api "repos/$repo/actions/runs?head_sha=$commit&event=pull_request&per_page=5" > "$P/runs.json" 2>/dev/null || { sleep 30; continue; }
  n="$(jq '.workflow_runs | length' "$P/runs.json")"
  if [[ "$n" -ge 1 ]]; then
    st="$(jq -r '.workflow_runs[0].status' "$P/runs.json")"; id="$(jq -r '.workflow_runs[0].id' "$P/runs.json")"
    printf '%s poll=%s run=%s status=%s\n' "$(date -u +%H:%M:%SZ)" "$i" "$id" "$st" >> "$P/wait.log"
    if [[ "$st" == completed ]]; then printf '%s\n' "$id" > "$P/run-id.txt"; jq -r '.workflow_runs[0].conclusion' "$P/runs.json" > "$P/run-conclusion.txt"; exit 0; fi
  else printf '%s poll=%s no run yet\n' "$(date -u +%H:%M:%SZ)" "$i" >> "$P/wait.log"; fi
  sleep 30
done
exit 4
