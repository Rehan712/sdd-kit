# Independent review — T030o39 / T030o40, 2026-09-23 (returned report, verbatim substance)

Reviewer: `security-reviewer` subagent, read-only, working in a private copy
(`/private/tmp/rev-o39.1ygCYw/`), brief `t030o39-o40-review-brief.md`. The
live worktree's `git status --porcelain -uall` digest was identical before and
after its work. Host: `/bin/bash` 3.2 only, BSD tools, APFS.

## Findings as returned

1. **Anchor keeps the typed case** (blocking under the brief's rule: reproduced
   regression, fails closed). `vf_bookkeeping_anchor` derives the anchor from
   `pwd -P`, which under bash 3.2 keeps the typed case on APFS while git reports
   the on-disk case. A spec path typed in another case gives an anchor that
   never matches git's paths, so the spec's own captures become inputs:
   `spec-run.sh <UPPER> T001 … --summary` exits 0 but `vf_capture_check … reuse`
   exits 3 with `capture stale: inputs changed during execution`, and
   `spec-gate.sh floor <UPPER>` exits 3 the same way. Pre-repair: reuse 0,
   floor 1 (the fixture's analyzer result). Fix: take the anchor from
   `git rev-parse --show-prefix` and check the toplevel.
2. **Declared-input refusal is case-sensitive on a case-folding filesystem**
   (minor). `$own/notes/OPPONENT.md`, `$own/NOTES/opponent.md` and
   `.specify/specs/003-Verification-Fixture/notes/opponent.md` each exit 0 with
   the own report hashed; `$own/NOTES/verification` is not refused. Fails
   closed. Fix: fold case when `core.ignorecase` is true (`nocasematch`).
3. **`vf_physical_rel` resolves `..` lexically** (minor). Plain `cd` is `cd -L`:
   with `ign/sub -> ../$own/notes`, `ign/docs/l -> ../sub/../notes/opponent.md`
   and a decoy `ign/notes/opponent.md`, the kernel reads the own report while
   the function prints the decoy, and the declaration is hashed unrefused. Fix:
   `cd -P --`.
4. **The contract sentence overstates declared-directory behaviour** (minor;
   the code behaviour predates this change). Declaring `.` or `./` makes
   `vf_physical_rel` fail at the root and members arrive as `./.specify/…`,
   bypassing the member skip; a declared ignored directory holding a symlink to
   the own report hashes that member. Fix: handle the root and link members, or
   narrow the sentence.
5. **Fixture gaps** (minor). The mutant `find "$repo/${real:-$path}"` →
   `find "$repo/$path"` survives the suite although it changes behaviour for
   `./$own/notes`; no fixture declares a symlink loop, so deleting the loop
   bound would hang unnoticed.

## Held, per the reviewer

Real record: 003 `severity-downgrades=5` (exit 0), 002 `0` (exit 0), 001 exit 3
with its pre-existing `duplicate identity field`. Both suites pass in the copy
(3/3, 14/14). T030o40: one predicate per observation, a `downgrade` record only
beside its finding, per-round counter reset in both styles, every catalog
consumer ignores the new kind, the manifest read is per gate. Another spec's
records can no longer escape the index, path, declared or member passes; the
anchor is quoted, so it cannot inject a glob, and `003-x-extra` cannot match
`003-x`. The O-010 per-path scope covers everything the old scope did. No
execution of tree content; reads outside the repository are not widened.

## Not reached, per the reviewer

GNU tools, bash 5 and Linux; the full `tests/run.sh` and ShellCheck; an
end-to-end multi-repo or umbrella gate; the invoker's mutation matrix; the
pre-existing self-trap of an enumerated symlink that targets the spec's own
records.

## Second pass (session-2 diff), 2026-09-23

- **R1** (blocking under the brief's rule, fails closed): the git-derived anchor
  obeyed git's discovery environment. With `GIT_DIR` exported, as git does for
  hooks in a linked worktree, `rev-parse --show-prefix` from the spec directory
  printed an empty prefix, the anchor came out empty, and own captures went stale
  during their own execution (pre-repair: stable). `_vf_git_where` also split at
  the first newline, so a repository path containing a newline emptied the anchor.
  Verified on this host by the invoker. Reviewer's fix: `env -u GIT_DIR -u
  GIT_WORK_TREE` plus a toplevel-aware parser. Adopted instead: no git discovery
  at all (string anchor, `cd -P && pwd -P` resolver).
- **R2** (minor): folding followed `core.ignorecase`, not the filesystem; with it
  false on APFS the refusal missed `OPPONENT.md`, and with it true on a
  case-sensitive volume a sibling spec differing only in case would fold into the
  own exclusion (escape direction, by inspection). Adopted: probe the filesystem
  (`-ef` against a case-swapped spelling).
- Informational: a declared dangling link into a not-yet-created own capture is
  accepted until the capture exists, then refused (fails closed); declaring `.git`
  itself is accepted and hashes git internals (pre-existing).
- Held: all five first-pass findings repaired; root refusal reaches `.`, `./`,
  `./.` and a root link; `nocasematch` does not leak under `set -euo pipefail`;
  suites 3/3 and 14/14; tallies 003=5, 002=0, 001 exit 3.

## Third pass (session-3 diff), 2026-09-23

- **T1** (blocking under the brief's rule, narrow, fails closed): the fold probe
  swapped only the spec directory's basename, so a letterless name such as
  `003-2027` (reachable: `new-spec.sh` slugifies titles to `[a-z0-9-]`) reported no
  folding on APFS; a spec path typed in another case then leaked its own records,
  and `notes/OPPONENT.md` was hashed instead of refused. Reviewer-verified fix:
  climb to the nearest component with a letter. Adopted verbatim.
- **T2** (minor, by inspection): `-ef` follows symlinks, so on a case-sensitive
  filesystem a symlink spelled as the case swap would report folding. Fix: refuse
  a swapped spelling that is itself a symlink. Adopted, with a fixture that runs
  where the filesystem does not fold.
- Informational: a repo argument with a trailing slash gives an empty anchor
  (vf_snapshot always normalizes); a symlinked spec directory gets an empty anchor
  (not a regression).
- Held: no R1/R2 member remains (GIT_DIR exported, newline repo path,
  `core.ignorecase=false`, linked worktree, case-variant spec path, every earlier
  spelling); glob characters in the repo path are inert under quoting; suites 3/3
  and 14/14; tallies unchanged.
- Not reached by the reviewer: a case-sensitive volume, GNU tools, bash 5, Unicode
  normalization (NFD/NFC). The invoker then ran `tests/test-verification.sh` with
  TMPDIR on a case-sensitive APFS disk image as well as on APFS: 3/3 on both.
