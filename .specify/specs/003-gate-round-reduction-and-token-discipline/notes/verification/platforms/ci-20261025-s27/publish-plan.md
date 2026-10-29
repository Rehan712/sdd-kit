# s27 publication and floor handoff — prepared, not executed

Worktree: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`. Source `c7a82b3ae3b900dcb02a4839decad74db1a13457c5bab9ff859625a5357f0be6`; tree `e98c79fe564564397f36ff0b9910137572ea10bb`; local unreferenced commit `414838bb52898921aa49fb3d25caed6e7b711763`; parent `2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9`.

Update the existing PR21 branch `ci-snapshot/spec-003-20261025-s26` only, with the exact lease against `781b963e6777b44059b24e696dafa37c69242a05`. No new branch or PR. `publication.json` records the exact push argv. Parent supplies the scoped credential. Stop on a changed remote head; do not substitute a new tree. PR21 is linked to this thread; no GitHub write was made here. The new commit captures exactly the approved tree; later excluded orchestration artifacts are deliberately outside that tree.

## Parent push, after handoff review

```bash
cd /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline
set -euo pipefail
export GIT_OPTIONAL_LOCKS=0
out="$PWD/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261025-s27"
bash "$out/verify-prepublish.sh"
# Run in the parent's scoped credential context; no credential/config mutation here.
test "$(gh api repos/Rehan712/sdd-kit/git/ref/heads/ci-snapshot/spec-003-20261025-s26 --jq .object.sha)" = 781b963e6777b44059b24e696dafa37c69242a05
test "$(git rev-parse 414838bb52898921aa49fb3d25caed6e7b711763^{tree})" = e98c79fe564564397f36ff0b9910137572ea10bb
test "$(git rev-parse 414838bb52898921aa49fb3d25caed6e7b711763^)" = 2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9
git -c push.followTags=false -c push.recurseSubmodules=no -c push.gpgSign=false push --no-verify --porcelain --force-with-lease=refs/heads/ci-snapshot/spec-003-20261025-s26:781b963e6777b44059b24e696dafa37c69242a05 origin 414838bb52898921aa49fb3d25caed6e7b711763:refs/heads/ci-snapshot/spec-003-20261025-s26
```

## Parent native background floor launch, only once actual AC is confirmed

```bash
cd /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline
set -euo pipefail
export GIT_OPTIONAL_LOCKS=0
r="$PWD/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports"
pmset -g batt | head -1 | grep -q 'AC Power'
for suffix in launch.log wrapper.log wrapper.rc wrapper.pid log rc time pre samples.log source-before.nul source-after.nul binding-before.json binding-after.json binding-before.log binding-after.log floor-id; do
  test ! -e "$r/s27-floorrun.$suffix"
done
nohup bash -c '
  /usr/bin/time -p -o "$1/s27-floorrun.time" bash "$1/s27-floor.sh" 1 > "$1/s27-floorrun.wrapper.log" 2>&1
  rc=$?
  printf "%s\n" "$rc" > "$1/s27-floorrun.wrapper.rc"
  exit "$rc"
' _ "$r" > "$r/s27-floorrun.launch.log" 2>&1 < /dev/null &
printf '%s\n' "$!" > "$r/s27-floorrun.wrapper.pid"
```

The historical `caffeinate -i -m -s` invocation, 60-second disk/swap/power sampler and internal floor exit receipt remain. The entrypoint remains `bash scripts/spec-gate.sh floor <spec>` with no options. The helper verifies the frozen source/tree/raw mapping and protected HEAD/index/STATUS before and after, saves source manifests and binding reports, and refuses existing s27 receipts. No suites ran during preparation except the explicitly permitted seven small offline collector controls. The `.rc` is the actual floor command status; `.wrapper.rc` also reflects wrapper/binding failure (97), missing receipt (99), or missing AC (98). The parent must check both receipts. A successful run saves a fresh actual `FLOOR-*` ID in `s27-floorrun.floor-id` and the gate itself updates `notes/verification/floor-latest`; no floor ID is invented now. Reuse/execution counts are unknown until this actual run.

## Later hosted collection

```bash
cd /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline
set -euo pipefail
export GIT_OPTIONAL_LOCKS=0
out="$PWD/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261025-s27"
# Observe actual run metadata once; do not reuse the old run ID.
gh run list --repo Rehan712/sdd-kit --branch ci-snapshot/spec-003-20261025-s26 --workflow ci.yml --event pull_request --json databaseId,headSha,status,conclusion,url > "$out/run-candidates.json"
jq --arg head 414838bb52898921aa49fb3d25caed6e7b711763 '[.[] | select(.headSha == $head)]' "$out/run-candidates.json"
# Set run only to the observed matching databaseId after completion.
: "${run:?set run to the actual completed matching run databaseId}"
bash "$out/collect.sh" "$run" "$out/hosted-$run" 414838bb52898921aa49fb3d25caed6e7b711763 > "$out/hosted-$run.log" 2>&1
jq -e --arg head 414838bb52898921aa49fb3d25caed6e7b711763 --arg branch ci-snapshot/spec-003-20261025-s26 '.head_sha == $head and .head_branch == $branch and .event == "pull_request" and .status == "completed" and .conclusion == "success" and .path == ".github/workflows/ci.yml"' "$out/hosted-$run/run.json"
jq -e '(.jobs | length) == 4 and ([.jobs[].name] | sort) == (["shellcheck", "tests (ubuntu-latest)", "tests (macos-latest)", "tests-bash32"] | sort) and all(.jobs[]; .status == "completed" and .conclusion == "success")' "$out/hosted-$run/jobs.json"
bash "$out/verify-prepublish.sh"
```

For monitoring, parent uses T3 `watch_pull_request`, not a polling loop. A new s27 collection driver can be prepared once the actual run ID is known. `collect.sh` is the unchanged current collector except its exact `want_tree` value; head binding stays the required third argument. It retains raw logs, rejects head/tree/checkout/job/download mismatches and sanitizes only human diagnostics. The real tested merge tree must equal `e98c79fe564564397f36ff0b9910137572ea10bb`; a remote main change is not silently accepted.

## Evidence and limits

- `summary.json`, `source-mapping.tsv`, `build.log`, `build.rc`, `build.time`; complete frozen manifest/tree/index/paths at `/var/folders/qp/82x5sgg10_z719z9cw5bj71h0000gn/T/sdd-ci-20261025-s27-th6cxwvh/snapshot` (keep scratch and unreferenced objects until parent publishes).
- `protected-before.json`, `state-before.json`, `verification-prepared.json`, `inputs-prepared.nul`; final protected proof will be `protected-after.json`, `verification-completed.json`, `inputs-completed.nul`.
- `origins.json` pins all reused historical helpers and the preserved prior battery-block proof. Builder copy is byte-identical to s26. The prepublish verifier retains the successful retry's explicit-exit source mismatch protection, plus strict current index/HEAD/STATUS bytes and mtimes.
- `source.diff` and `source.stat` show the source-only changes captured from parent. All 13,840 entries are preserved; 177 source files, 8 harness records, 4 document records; 13,663 own bookkeeping extras; zero mapping mismatches or non-bookkeeping extras.
- Initial warning ShellCheck output is preserved in `syntax-shellcheck.log`: SC2034 for `HUB_DIR` in reused sourced-library callers. The variable is used by `scripts/verification-lib.sh`; `syntax-shellcheck-diagnosed.log`/`.rc` records success with only that diagnosed warning excluded for those two files. Floor and collector pass unexcluded warning ShellCheck. No historical/source file was changed to silence a warning.
- Snapshot helper syntax, actual mapping and strict source binding passed. Seven reused offline collector controls passed (good, wrong head, wrong tree, failed job, missing checkout, terminal escapes/raw-byte retention, failed download). No floor/helper runtime invocation, gates, captures, full suites, push, PR creation, merge, branch or config write occurred. Global refs changed concurrently; no claim is made that unrelated refs stayed fixed.
- Battery-only constraint applies to the floor. Preparation started with 13.59 GiB available, swap 1469.69 MiB and Battery Power100%. Final resource proof is recorded separately. The earlier `s27-preparation-resource-block-1.json` remains intact.
