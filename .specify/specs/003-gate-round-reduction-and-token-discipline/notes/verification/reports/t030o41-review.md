# T030o41 independent review, 2026-09-24

Saved by the invoker. Each reviewer worked read-only in its own private copy.
The invoker re-verified the load-bearing reproductions before acting; that
verification is recorded at the end of each pass.

## Pass B (security-reviewer; items 2, 3, 5, 6)

Live worktree never modified: `git status --porcelain -uall -z` digest `72d8ca17…`
before and after. Private copy `/private/tmp/revB-t030o41` (standalone git repo
from the worktree's own `ls-files -z --cached --others --exclude-standard`, plus a
`pre` branch made by reverse-applying `t030o41-session.diff`), removed afterwards.
Baseline in the copy under `/bin/bash` 3.2.57 and bsdtar 3.5.3: all five Verify
suites exit 0 (3/3, 14/14, 18/18, 26/26, 8/8); ShellCheck on the seven changed
shell files exits 0.

**Verdict: the repair is not correct as it stands.**

### B1 — blocking. The rewritten scan reads the verified spec's own records under a case-variant spelling, which the identity excludes
`tests/test-gate-contracts.sh:63-64` calls `vf_bookkeeping_path "$path" "$own"`
with no fold and derives `own` with a case-sensitive `case`; the identity passes
the fold (`scripts/verification-lib.sh:1451`, `:1464`, `:1416`). Fixture: with
`$spec/Notes/opponent.md` and a claim appended, `vf_case_folds: 1`, the snapshot
digest stays `4463ed84…` (`cmp`-identical manifests) while the scan goes from
`[]` to `…/Notes/opponent.md :: always includes PATH`. Suite level in a kit copy:
`git rm --cached` 003's `notes/opponent.md`, rename it to `notes/Opponent.md`; the
identity stays `146e5f85…` and `test_instruction_contracts` fails (rc=1) on
`…/notes/Opponent.md :: PATH is hashed`. Pre-existing, but inside the reader and
the rule this session rewrote. Fix: compute `fold` with `vf_case_folds "$root"`,
derive `own` under `nocasematch` where the filesystem folds, pass `"$fold"`.

### B2 — blocking. The new AC-023 fixture places its probes by 002's Evidence lines, which the identity drops
`tests/test-sdd-analyze.sh:531`, `:536` key both insertions on the first raw
`- *Evidence:*` line. Deleting all 22 Evidence lines of 002's `tasks.md` leaves the
manifest `cmp`-identical, and `bash tests/test-sdd-analyze.sh` fails 17/18
(`expected exit 1, got 0`, twice): the body probe is never inserted and the
Evidence direction tests nothing. Fix: build both probes from the hashed view,
anchored to a hashed line such as the first task header.

### B3 — blocking. The AC-023 loop enumerates shipped specs by directory glob, not through `vf_source_paths`
`tests/test-sdd-analyze.sh:513`; `:527` uses `basename` on the same glob.
`.specify/specs/001-stale/.DS_Store` (ignored) leaves the manifest `cmp`-identical
and fails `test_verification_bindings` with `cannot read
.specify/specs/001-stale/spec.md as the identity hashes it`. Fix: derive the
shipped set from `vf_source_paths` output.

### B4 — blocking (regression, fails closed). The rewritten scan fails on healthy trees whose names the identity hashes
`vf_semantic_file "$path" "$path"` passes a relative input, so `cp` parses a
leading `-` as options (the identity passes `"$repo/$path"`, `:1424`);
`awk -v path="$path"` is rejected by BSD awk for a newline and rewrites backslash
escapes; the awk-failure branch prints no diagnostic. `-notes.md`: post-repair
`test_instruction_contracts` rc=1 (`cp: illegal option -- o`,
`superseded_environment_scan: cannot read -notes.md`), pre-repair rc=0. A newline
name: post-repair rc=1 (`awk: newline in string`), pre-repair rc=0.

### B5 — blocking (regression, guard false-clean). A symlinked spec, plan or tasks file: a claim the identity hashes escapes the scan
The scan normalizes by the link's name; `vf_path_record` (`:1417-1420`) hashes a
link's target raw. A symlinked `004-y/tasks.md` whose target's Evidence line
carries the claim: post-repair `scan1 rc=0 out=[]` with the identity changed;
pre-repair it was reported.

### Shared fix for B1, B4, B5
One library function as the only way to read a path's hashed content (a link:
the raw target via `cp -- "$repo/$path"`; a file: `vf_semantic_file "$path"
"$repo/$path"`), called by `vf_path_record` and every reader; the report name to
awk through `ENVIRON`; a diagnostic on the awk-failure branch. Trialled inline on
a private copy: `superseded_environment_cases` rc=0; case-variant not reported;
symlink claim reported; `-notes.md`, newline and backslash names reported verbatim.

### Minor
- m1. The body-line control's diagnostic is vacuous: `'opponent gate'` also
  matches `✓ opponent gate present, agent file exists`. Assert the exact
  failure lines.
- m2. The scan's read-failure (`:67`) and awk-failure (`:112`) branches are
  unpinned; both removal mutants survive. A mode-000 file fails correctly today.
- m3. `kit_copy_cases` checks neither content nor mode: a truncating mutant and
  an exec-bit-stripping mutant survive it (caught only by consumer suites).
- m4. `copy_kit` copies the verified spec's own records (143 MB of 146 MB here),
  bytes the identity does not hash; the new doctor test makes two such copies.
- m5. The Evidence-direction positive certifies the identity's view, not the raw
  artifact (the raw artifact still fails on the field-grammar defect); the label
  overstates it.
- m6. The rule's wording is wrong for symlinks ("through `vf_semantic_file`"),
  and `templates/verification-contract.md:180`'s "the kit's own suites read
  through …" is contradicted by B2 and B3.

### Held
`vf_snapshot` source records byte-identical pre/post for the repository root, a
linked worktree, a symlinked root, exported `GIT_DIR`/`GIT_WORK_TREE`, and names
with a newline, a double quote or non-ASCII; a subdirectory and a bare repository
both fail identically (`Git worktree root required`). The scan enumerates
correctly through a symlinked root, a linked worktree and exported git variables;
an unreadable listed file fails closed by name; `café`, `say"hi"` and tab names
are reported. `copy_kit` under bsdtar copies `-C`, `-x.md`, `--null`, backslash,
newline and space names, preserves modes 755 and 0444, keeps links verbatim, omits
ignored directories and deleted-but-indexed paths, and overwrites into an existing
destination. Kills confirmed: four scan mutants, four `copy_kit` mutants, and the
layout clause by each assertion of `outside_layout_anchor_cases` independently.

### Not reached
GNU tar (not installed); Linux mawk with a newline in `-v`; a case-sensitive run
of B1; fixture suites under a hook environment; the full `tests/run.sh`.

### Invoker verification of pass B (2026-09-24)
Re-run here against the live code in a scratch fixture, not the worktree:
B1 `vf_case_folds=1`, scan reported `.specify/specs/004-y/Notes/opponent.md ::
always includes PATH`; B4 `-notes.md` rc=1 with `cp: illegal option -- o`, a
newline name rc=1 with `awk: newline in string`; B5 a symlinked `tasks.md` whose
target's Evidence line carries the claim: scan rc=0 with empty output. B2 and B3
confirmed by reading `tests/test-sdd-analyze.sh`: both probes are keyed on the raw
Evidence line and the shipped set is a directory glob.

## Pass A (security-reviewer; items 1, 4, 7)

Reviewed the state in `t030o41-session.diff` (461 lines) in a private standalone
copy under the scratchpad (`rev/copy`, built about 09:10, removed 09:42:16).
Baselines in the clean copy: test-sdd-analyze 18/18, test-gate-contracts 14/14,
test-usage-limits 26/26, test-build-adapters 8/8, test-spec-run 6/6, ShellCheck
rc=0, identity `5a129a64…`. **Status: blocked.** The reviewer also reported that
the live `.specify/stack.yml` was deleted in the working tree (`MD`, directory
mtime 09:42) and that it had not caused it; see the invoker's incident note below.

### A-B1 — blocking. The repair's own AC-023 probe fixture depends on bytes the identity drops
Same as pass B's B2: deleting every Evidence line of 002's `tasks.md` leaves the
identity `5a129a64…` and fails `test_verification_bindings` 17/18.

### A-B2 — blocking. Directory globs of the live tree bypass `vf_source_paths`
(a) An empty `.specify/specs/002-zz-scratch` leaves the identity unchanged and
fails the AC-023 loop 17/18 (same class as pass B's B3). (b) An empty
`002/notes/verification/floors/FLOOR-zz` leaves the identity unchanged; the 002
`tally` goes rc=0 → rc=3 (`capture integrity: missing COMPLETE or linked
directory`) and `test_reports_and_tally` fails 13/14. The tally's `FLOOR-*`,
`CHECKPOINT-*` and `CAP-*` globs (`scripts/verification-lib.sh:2766`, `:2780`)
see directory-shaped entries the identity never records. (c) An ignored
`scripts/zz-local.sh` (via `.git/info/exclude`) leaves porcelain and identity
unchanged and turns `shellcheck -S warning -x scripts/*.sh tests/*.sh` rc=1.
(d) An ignored `tests/test-zz-local.sh` is run by `tests/run.sh`'s `test-*.sh`
glob (filtered form reproduced).

### A-B3 — blocking (wrong result and data loss). A third whole-kit copy, `stage_kit`, carries ignored files
`tests/test-build-adapters.sh:17-19` tars the live kit (excluding only `.git`,
`.specify`, `*.worktrees`), so it copies `registry.yml`, `system-map.yml`,
`models.yml`, `build/`, `.cache/`, `briefs/*.md`; `write_policy_file` (`:24`)
then writes through whatever `models.yml` is in the copy. A relative
`models.yml` symlink to a valid policy (ignored, identity unchanged) fails 4/8
tests; an absolute one leaves the suite at 8/8 but overwrites the target file
OUTSIDE the repository (`35bf74af…` → `cd18f136…`). Decisions' "two whole-kit
copies" is wrong: there are three.

### A-B4 — blocking. Undeclared environment and files outside the repository decide both reuse-checked commands
ShellCheck reads `SHELLCHECK_OPTS`, `.shellcheckrc` in every ancestor, and
`~/.shellcheckrc`/`$XDG_CONFIG_HOME/shellcheckrc`. `SHELLCHECK_OPTS=
'--enable=check-unassigned-uppercase'` and a parent-directory `.shellcheckrc`
each turn the ShellCheck check rc=1 with the identity `5a129a64…` unchanged.
`env -u SHELLCHECK_OPTS shellcheck --norc …` is rc=0 with the parent rc present.

### Minor
- A-M1. AC-023 is narrowed (hashed view) without amending spec.md:509 or
  plan.md:544; the raw edited 002 fails the analyzer while the suite passes. On
  today's files raw and hashed analyzer output are byte-identical.
- A-M2. `copy_kit` carries bytes the identity does not hash (same as pass B m4).
- A-M3. The contract's closing sentence is false (same as pass B m6).
- A-M4. The body-line control's assertion is too loose (same as pass B m1);
  the control itself is a genuine negative.
- A-M5. `tests/test-usage-limits.sh:206` passes an unpinned
  `SDD_RESUME_JITTER_SECONDS` through: `=301` fails 25/26
  (`test_T013o1_clock_only_horizons_follow_configured_park_policy`).

### Decisions claims contradicted
"Two whole-kit copies" (three); "ShellCheck reads only … hashed verbatim"
(false); the unhashed classes omit directories, empty directories, out-of-repo
files and undeclared environment; "flips exactly those two" (a symlink-shaped
ignored path flips build-adapters); the one-enumeration rule was not applied to
the AC-023 loop's path set.

### Held
Identity records pre/post `cmp`-identical once `harness` records are removed;
every scan caller asserts its exit status; the body-line control is a genuine
negative; a global `core.hooksPath` does not flip `test-spec-run`; 002 cannot be
the verified spec today (`vf_snapshot` refuses its checkpoint stages).

### Not reached
Full unfiltered `tests/run.sh`; full `test-verification.sh`; Bash 3.2, GNU tar,
Linux; the mutation matrix; `BASH_ENV`/`SHELLOPTS`; global `excludesFile`.

### Invoker verification of pass A (2026-09-24)
Read in the code: `stage_kit`'s tar (`tests/test-build-adapters.sh:17-18`) and
`write_policy_file`'s `cat >` (`:24`); the tally globs (`:2766`, `:2780`); the
jitter pass-through (`tests/test-usage-limits.sh:206`); CI's unpinned
`shellcheck -S warning -x scripts/*.sh tests/*.sh`
(`.github/workflows/ci.yml:17`). A-B1 and A-B2(a) are pass B's B2/B3, already
reproduced here.

## Incident: the invoker's own dev run deleted the live `.specify/stack.yml` (2026-09-24)

Observed by pass A, confirmed and traced by the invoker. Timeline: dev run 3
started `tests/test-verification.sh` in the live worktree at 09:40:49; pass A's
copy was removed at 09:42:16; the live `.specify/` changed at 09:42:33 with
`stack.yml` gone (`git status`: `MD`); the suite ended 09:42:37 at 3/3. Dev run 3
was stopped at once. Reproduced in a standalone copy (the file vanished four
seconds before the suite ended, suite still 3/3), bisected to `kit_copy_cases`,
and traced with `set -x` to `rm -f '' .specify/stack.yml`: the EXIT trap of this
session's `copy_kit` (`rm -f "$list" "$present"`). Mechanism, confirmed with a
minimal script under `/bin/bash` 3.2.57: a subshell function run as the WHOLE of
a command substitution (as `run_rc` runs it) that leaves by `exit` fires its EXIT
trap after its locals are unwound, so the trap reads the CALLER's variables —
here `list` unset and `present` = the caller's last loop value,
`.specify/stack.yml`, relative to the working directory (the repository root).
`return` and falling off the end do not leak. No kernel function shares the
defect: its only `exit`s after an EXIT trap are inside awk programs. Dev runs 1
and 2 ran the same path harmlessly because the loop's last value was then
`docs/café.md`, which does not exist in the live tree; no tracked path is
missing. Recovery: the working-tree bytes were taken from the pre-repair
reproduction copy (built 05:56), hashed `4dc6c67e…`, equal to the `path` record
the 08:4x live manifest holds for `.specify/stack.yml` (the index version,
`5851cd0b…`, differs, so `git checkout` would have lost unstaged edits), and
restored at 09:47 (`MM` again). Fix: `copy_kit` and the O-010 scan no longer use
EXIT traps; each owns one private directory, removed on every path, and failure
paths return. A regression fixture runs a failing `copy_kit` exactly that way
with caller variables naming a sentinel; the trap-and-`exit` mutant removes the
sentinel and fails it, the fixed helper passes.
