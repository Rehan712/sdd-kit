Prepared commands only; none executed. Explicit workdir: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`.

Parent must recheck live source/task writers, floor, verification lock and pending/staged reservations before floor launch; at least 8 GiB free and actual AC are mandatory. Runner independently rechecks these conditions. Do not queue an AC wait now. Use `parent-floor-launch.argv.json` shell_text only after parent launch authorization and resource preconditions; fresh receipts are reports/s29-final-floorrun.*.

Before publishing, run:
```bash
bash /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261026-s29/verify-prepublish.sh
git ls-remote --heads origin refs/heads/ci-snapshot/spec-003-20261025-s26
gh pr view 21 --repo Rehan712/sdd-kit --json headRefOid,headRefName,isDraft,url
```
Expected remote head `5aee77672d03a2c7811e28e55172817da6dee012` is historical only; parent must query actual head and confirm or explicitly refresh the lease before publishing. Stop on a different head; do not silently replace the lease. Parent provides scoped credentials. Exact candidate push argv (no ref updated here):
```bash
git -c push.followTags=false -c push.recurseSubmodules=no -c push.gpgSign=false push --no-verify --porcelain --force-with-lease=refs/heads/ci-snapshot/spec-003-20261025-s26:5aee77672d03a2c7811e28e55172817da6dee012 origin 616dd2d1bb0f3eb16045821b0b30b9c9b40f2395:refs/heads/ci-snapshot/spec-003-20261025-s26
```
After actual push only, update the existing draft PR21, keep draft, do not merge:
```bash
gh pr edit 21 --repo Rehan712/sdd-kit --title 'test(ci): spec 003 s29 repair and control snapshot (do not merge)' --body-file /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261026-s29/pr21-body.md
```
Later read-only hosted collection (replace placeholders with actual run ID; binds new commit and exact tested merge tree):
```bash
bash /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261026-s29/collect.sh '<actual-run-id>' '/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261026-s29/hosted-<actual-run-id>' 616dd2d1bb0f3eb16045821b0b30b9c9b40f2395
```
No source PR20, new branch, fork, new PR, global credentials or merge. Keep external scratch and unreferenced commit until publication.
