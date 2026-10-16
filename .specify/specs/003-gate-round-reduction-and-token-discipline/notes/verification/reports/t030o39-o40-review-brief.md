# Independent review brief — T030o39 / T030o40 (spec 003), 2026-09-23

You are an independent, READ-ONLY reviewer of two repairs. Do not create, modify,
move or delete anything in the worktree. Do not run `spec-gate.sh round`,
`floor`, `checkpoint` or `accept`, and do not write any authorization line. You
may run tests and probes in a COPY of the tree under your own private temp
directory, with `TMPDIR` pointing there. Return your findings in your reply
only; the invoker saves them.

Worktree: `/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`
Spec dir: `.specify/specs/003-gate-round-reduction-and-token-discipline` (below: `$S`)

## Inputs

- This session's source changes only, as a unified diff against the pre-repair
  source: `$S/notes/verification/reports/t030o39-o40-session.diff`.
- The findings being repaired: `$S/notes/verification/reports/opponent-round9.md`
  (Finding O-013, Finding O-014, and the two isolation gaps under "Held up").
- The governing decisions: the 2026-09-23 entries at the end of the Decisions
  log in `$S/STATUS.md` (the anchoring reading of REQ-009, the T030o39 rule,
  the measured O-010 scan scope, the T030o40 rule). Task blocks: `T030o39` and
  `T030o40` in `$S/tasks.md`.
- Reproduction receipts: `$S/notes/verification/reports/o013-o014-repro.{sh,log}`
  and `o010-scope-measure.{sh,log}`.

The invoker runs a mutation matrix separately; do not rely on it.

## Attack surface (derive members from the mechanism, not from these examples)

1. Identity (`scripts/verification-lib.sh`: `vf_bookkeeping_path`,
   `vf_bookkeeping_anchor`, `vf_physical_rel`, `vf_path_record`, `vf_snapshot`).
   Is exclusion now exactly the verified spec's six generated shapes? Can another
   spec's record still escape the identity through any pass (index, path,
   declared, declared-directory member)? Can the verified spec's own records now
   leak into it, which would make a capture stale during its own execution?
   Consequences for multi-repo and umbrella gates (`vf_gate_roots`,
   `vf_gate_snapshot`, `vf_gate_task_repo`).
2. Declared inputs. Can a declaration reach the verified spec's own records
   without the named refusal: spellings, symlinks, symlink loops, a declared
   symlink to a directory, case-insensitive filesystems, trailing slashes, paths
   outside the repository? Does `vf_physical_rel` terminate and behave under Bash
   3.2 and both BSD and GNU tools? Any regression for existing declarations?
3. The O-010 scan's per-path anchoring (`tests/test-gate-contracts.sh`,
   `superseded_environment_scan`). Is the scope argument in Decisions sound? Can
   a current claim now escape the scan?
4. `vf_reports`' lowered-tier predicate, the new `downgrade` catalog record and
   `vf_tally`. Is the metric now exactly the guard's computation, per gate? Does
   any catalog consumer mishandle the new record kind? On the real record, 003
   should print `severity-downgrades=5`, 002 should print 0, and 001 should keep
   its pre-existing exit 3.
5. Fixture quality. Does each new fixture kill the mutation it exists for? Is
   any new positive certifying an attack at rc=0?
6. Security of the path handling: TOCTOU between the refusal and the hashing,
   names with spaces or newlines, `readlink` output handling, and no execution
   or widening of what is read from outside the repository.

## Reply format

For each finding: a title; severity (blocking only for a reproduced
wrong-result, data-loss, regression or crash, otherwise minor); `file:line`;
the concrete reproduction, with the commands you ran and their actual exit
codes; and the smallest fix. Then list what you attacked that held, and what
you did not reach. Keep the reply under about 1,500 words.
