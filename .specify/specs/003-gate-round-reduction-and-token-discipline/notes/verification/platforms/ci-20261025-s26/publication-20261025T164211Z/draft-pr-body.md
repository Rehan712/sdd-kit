Run current-source Linux, macOS, Bash 3.2, and ShellCheck CI for frozen spec 003 RC3. Hosted checks are pending; this temporary draft includes verification evidence and must not be merged. Close it after collecting the required evidence.

- Snapshot commit: `781b963e6777b44059b24e696dafa37c69242a05`
- Approved tree: `43292032de54f25df06531471b07ada5da0becf0`
- Frozen source: `a7e7dd326b27c7565c26349485c440af26f718a7f16e400ea42ed6961d03cd1a`
- Snapshot parent: `2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9`
- Base: `main`; head: `ci-snapshot/spec-003-20261025-s26`
- Existing sealed floor: `FLOOR-il41Kn`; no floor rerun.

Mapping proof: all 177 source paths match the fixed tree's raw blobs/modes and semantic hashes; eight harness and four document records also map. The snapshot contains 13,470 files / 329,260,990 blob bytes. Its parent diff is 1,122 files, +90,059 / -53, including verification bookkeeping; four source paths differ: spec `STATUS.md`, spec `tasks.md`, `tests/test-gate-contracts.sh`, and `tests/test-spec-gate.sh`.

At publication preflight, live main `f4a0e4e31df29b53ccb9e088d3b8d0cd58f8e12f` was an ancestor of the snapshot parent, and `git merge-tree --write-tree` produced the exact approved tree. The evidence collector must independently verify the tree actually tested by GitHub; a later base change or different tested merge tree cannot establish current-source hosted evidence.

Expected `.github/workflows/ci.yml` jobs: `shellcheck`, `tests (ubuntu-latest)`, `tests (macos-latest)`, and `tests-bash32`. No hosted result, runner/log evidence, or completed AC-019 proof is claimed here. Preparation records are under `.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/platforms/ci-20261025-s26/`; publication records are retained locally for the parent handoff. Later publication artifacts were not added to the approved tree.
