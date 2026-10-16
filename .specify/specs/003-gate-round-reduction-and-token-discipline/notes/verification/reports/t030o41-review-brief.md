# Independent review brief — T030o41 (spec 003), 2026-09-24

You are an independent, READ-ONLY reviewer of one repair. Do not create, modify,
move or delete anything in the worktree. Do not run `spec-gate.sh round`,
`floor`, `checkpoint` or `accept`, and do not write any authorization line. You
may run tests and probes in a COPY of the tree under your own private temp
directory, with `TMPDIR` pointing there. Check free disk (`df -h /`) before
copying: the host has about 7 GiB free, a copy is about 150 MB, and swap shares
the volume. Remove your copy when you finish. Return your findings in your reply
only; the invoker saves them.

Worktree: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`
Spec dir: `.specify/specs/003-gate-round-reduction-and-token-discipline` (below: `$S`)

## Inputs

- This session's source changes only, as a unified diff against the pre-repair
  source: `$S/notes/verification/reports/t030o41-session.diff`.
- The finding being repaired: `$S/notes/verification/reports/opponent-round10.md`
  (Finding O-015, and the isolation gap under "Held up").
- The governing decisions: the 2026-09-24 entries at the end of the Decisions
  log in `$S/STATUS.md` (the reproduction, the sibling derivation, the T030o41
  rule, and the analyzer field-grammar observation, which is deliberately NOT
  repaired). Task block: `T030o41` in `$S/tasks.md`.
- Reproduction before repair: `$S/notes/verification/reports/o015-repro.{sh,log,rc}`
  (exit 0, 64 checks).

The invoker runs a mutation matrix separately
(`$S/notes/verification/reports/t030o41-mutations.sh`); do not rely on it.

## The rule under review

A reuse-checked command's verdict may come from reuse only if it is a function
of the input identity. So every read such a command makes of the repository
must read what `vf_snapshot` hashes: the path set from one enumeration function
(`vf_source_paths`), minus `vf_bookkeeping_path`, with content through
`vf_semantic_file` under the path's repository-relative name. The session
applied this to three readers: the O-010 scan, the AC-023 analyzer loop and the
whole-kit test copies (`copy_kit`).

## Attack surface (derive members from the mechanism, not from these examples)

1. Is the reader set complete? The reuse-checked commands are `reuse_checks:`
   in `.specify/stack.yml`. Derive every read those commands make of bytes the
   identity does not hash: the verified spec's six generated shapes,
   `vf_semantic_file`'s drops, git-ignored paths, `.git`, anything outside the
   repository, and anything in the environment that is not declared. Look in
   `tests/*.sh` AND in the scripts they call from the live kit. Any reader that
   still flips with the identity unchanged is a finding. Reproduce it.
2. `vf_source_paths` and `vf_snapshot`. Is the identity byte-identical to the
   pre-repair function for every tree, including a subdirectory, a bare
   repository, a linked worktree, `GIT_DIR`/`GIT_WORK_TREE` exported, names
   with newlines, and a repository whose root is a symlink?
3. The O-010 scan. Can a current claim now escape it: symlinks (the identity
   hashes a link's target raw, while the scan normalizes by the link's name),
   a file git lists but cannot read, a name with a backslash or newline (the
   awk `-v` report), a file changing during the scan? Can it now fail on a
   healthy tree? Is anything reported that the identity does not hash?
4. The AC-023 loop. Does reading the hashed view weaken what AC-023 claims
   ("Shipped 001/002 remain analyzer exit 0")? Is the body-line control a
   genuine negative, or does it pass for an unrelated reason?
5. `copy_kit`. GNU tar versus BSD tar (`--null -T`, a name starting with `-`),
   modes and symlinks preserved, a copy into an existing destination (the doctor
   fixture calls it twice in one test), an indexed-but-deleted path, a symlink
   pointing outside the kit, and Bash 3.2.
6. Fixture quality. Does each new fixture kill the mutation it exists for, in
   both directions? Is any new positive certifying an attack at rc=0? Does any
   assertion check an exit code where it should check the exact diagnostic?
7. Anything the session claims in Decisions that the code does not do.

## Reply format

For each finding: a title; severity (blocking only for a reproduced
wrong-result, data-loss, regression or crash, otherwise minor); `file:line`;
the exact reproduction you ran and its observed output; and the smallest
class-wide fix. Then list what you attacked that held, and what you did not
reach. Do not soften: if the repair is wrong, say so.
