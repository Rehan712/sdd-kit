# Opponent round 12 — reviewer brief

Written 2026-09-27 by the invoker. Everything here is a claim to attack, not
authority. The receipts named below outrank this text. Paths are relative to
the spec directory `.specify/specs/003-gate-round-reduction-and-token-discipline/`
unless they start with `scripts/`, `tests/`, `templates/`, `agents/`, `README.md`,
`.specify/stack.yml` or `.github/` (worktree root:
`/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline`).

## Authorization and identity

- Round 12 is AUTHORIZED by the Decisions line `2026-09-26T19:06:23Z — waiver:
  gate=opponent; round=12; after=11; by=Rehan712; …`. Find it by its timestamp
  (STATUS.md:443 when this brief was written; neutral text above the Decisions
  log moves line numbers, and only `## Decisions log` is hashed).
  `bash scripts/spec-gate.sh waiver <spec-dir> opponent 12` exited 0 and round
  13 is refused at exit 4 with ten candidates (`notes/verification/reports/t030o42-freeze.txt`,
  and `r12-entry-audit.log`, `.rc` = 0, which also re-derived the eleven sealed
  round digests, the tally, HEAD and the task boxes at session entry).
- Reservation (copy exactly into the report): **Round** 12 · **Source**
  bb996df97887231e1fd50ebce39b2d3b7f918e3896917ea0031a59b227198254 · **Floor** FLOOR-0334B2 · **reserved** 2026-09-27T13:44:57Z.
  Read them yourself from `notes/verification/rounds/opponent/ROUND-12/meta.nul`.

## Scope: what changed since round 11

Derived mechanically (`notes/verification/reports/r12-scope.sh`; `r12-scope.log`,
exit 0): round 11's FLOOR-QeBcq3 `inputs.nul` against FLOOR-0334B2's.

- One accepted repair, NOT yet gated independently: **T030o42** (round-11 O-016,
  blocking): task block in `tasks.md` (search `**T030o42**`). Changed:
  `tests/helpers.sh`, `tests/run.sh`, `tests/shellcheck.sh` (each exports
  `LC_ALL=C` right after its `unset CDPATH BASH_ENV ENV`),
  `tests/test-verification.sh` (`locale_pm` and `reuse_command_locale_cases`,
  called from `test_capture_provenance`), `templates/verification-contract.md`
  (the two paragraphs round 11 named), a comment in
  `scripts/verification-lib.sh` (the environment-record comment near :1573),
  plus 003's `tasks.md` and the Decisions log. The delta against the pre-repair
  tree is `notes/verification/reports/t030o42-final.diff`; `t030o42-session.diff`
  is the state the independent review saw, before its wording repairs.
- FLOOR-QeBcq3 to FLOOR-0334B2 differ in exactly those paths (the six source files, 003's `tasks.md` and `STATUS.md`) plus the `harness` and `document` records that follow them, 370 records on each side (`r12-scope.log`).


Consumers of the changed files and every surface the spec declares are in
scope too, and you may expand into unchanged code.

## Evidence for the repair (claims, not authority)

- The rule and its derivation, in Decisions order (the three entries after the round-12 waiver): the
  session-6 entry audit and the reproduction; the rule, derived from what the
  programs a reuse-checked command runs consult and measured before adoption;
  the independent review's outcome, the wording repairs and the freeze. The
  two entries before the waiver hold round 11's record and the user's decision.
- Reproduction before repair: `o016-repro.{sh,log,rc,note}` (rc 1 on the
  script's own live tripwire only; `o016-live-check-repro.{log,rc}` exit 0).
  End to end: a capture taken under the ambient locale, reused under en_GB,
  while a fresh en_GB run fails 144/147.
- Measurement of the rule before adoption: `o016-measure.{sh,log,rc}` (same
  tripwire; `o016-live-check-measure.{log,rc}` exit 0), the program census
  `o016-census-counts.txt`, the manual pages' ENVIRONMENT sections
  `o016-census-env.txt` with its correction `o016-census-env.note`, and the
  option-variable probe `o016-option-vars.txt`.
- Dev runs: `t030o42-dev.sh` with `t030o42-dev1-{quick,full}.{log,rc}` (the full
  suite 147/147 plainly, under de_DE and under en_GB), and `t030o42-dev2.{sh,log,rc}`
  after the wording repairs.
- Mutation matrix: `t030o42-mutations.sh`, with `-dry`, the run of record and
  `-final` (on the final tree) receipts: 10 kill rows with exact diagnostics,
  one argued equivalent, byte-identical restores.
- Independent review: `t030o42-review-brief.md`, `t030o42-review.md` (no
  blocking finding; three minor), and the invoker's verification
  `t030o42-review-verify.{sh,log,rc}`.
- Acceptance: CAP-499-rKuH6Z (`bash tests/run.sh && bash tests/shellcheck.sh`, 147/147, input `bb996df9…`; `t030o42-capture.{log,rc,start,end}`), `notes/verification/returns/T030o42.txt` (`t030o42-return-validate.{log,rc}`), `T030o42-accept.{log,rc}` (return `7b457257…`), and `t030o42-postaccept.txt` (the tick moved neither the source nor Decisions). No hosted CI has run on the reviewed source.
- The floor: FLOOR-0334B2 sealed at exit 0, 21 executed and 54 reused, 09:22:28Z to 13:17:35Z (`r12-floor-1.{pre,log,rc,samples.log}`; on AC throughout, minimum free disk 8.35 GiB), and validates current for the reserved source (`r12-floor-validate.{out,err,rc,time}`).

## Invoker observation — recorded, not repaired

The review's F2 (Decisions, 2026-09-27): the fixture takes its probe set from
`reuse_checks` alone, while a sealed floor and task evidence are honoured
across shells for gate checks, checkpoints and every automated task Verify.
Every such command the kit ships is pinned today, so it is latent; the user
chose to record it. The review's F1 was repaired in wording only: the harness
itself runs under the caller's locale and fails closed where it cannot decode
the kit's bytes (Shift-JIS, or a UTF-8 locale over an invalid byte).

## Known open — recorded, you may challenge it

- The harness-level environment: every captured command runs as
  `bash -o pipefail -c`, which reads `BASH_ENV`, `ENV`, `SHELLOPTS`, `BASHOPTS`
  and exported functions; and, measured this session, option variables a
  program reads only when someone sets them (`UNAME_SYSNAME=Linux` fails the
  usage-limits suite 20/27 with the locale pinned, `GREP_OPTIONS=-v` breaks the
  runner, `TAR_*_OPTIONS`, `POSIXLY_CORRECT`, `GNUSORT_*`, `COLUMNS`,
  `PERL5OPT`). Pending the user's plan-level decision (hash the startup inputs,
  or pin a closed harness environment). The invoker's line: default
  cross-shell variation (the locale family) must not decide a verdict and is
  pinned; a deliberately set option variable is this recorded item.
- `TZ`: measured inert under three offsets with the locale pinned, not proven.
- `PATH` choosing an undeclared tool (`verification_tools:` closes tools).
- Shipped 002's own locale-dependent reset parsing in `scripts/usage-limit.sh`
  (outside spec 003; the pin removes only the reuse half, and the suite now
  judges the classifier under C).
- The harness's own locale reads (fail closed, see above).
- Review 7's F1, F2, F4 and the unjudged K74 site; the kernel's ambient
  fixture reads; the analyzer field grammar with AC-023's narrowed reading; the
  umbrella-only in-place readers.
- Older: the O-004 omission extent; the opponent-only totals, verdict and
  downgrade guards at `scripts/verification-lib.sh:1101-1103`; README omits the
  Verification-Return grammar and the invoker documents omit the completion
  marker; 001's legacy report fails `tally` at exit 3; the retained unexamined
  surfaces (umbrella and multi-repo roots, acceptance crash windows, real
  reality-check carry, the `r`-suffix branch, per-negative branch coverage,
  AC-014/017/018 prose).

## Method this spec requires

1. Derive each criterion from the grammar or production the code reads, with
   its source. An enumeration of reported spellings is satisfiable while the
   class stays open.
2. Test a proposed rule against the real recorded history (`notes/opponent.md`,
   and 001's and 002's reports) before proposing it.
3. Mutation-isolate guards in both directions, and restore byte-identically (`cmp`).
4. Assert exact diagnostics, never exit codes alone.
5. Hunt for shipped POSITIVES that assert an attack at rc=0.

## Operational rules

- Work in a copy outside the worktree (for example `/private/tmp/opp12/work`,
  with `TMPDIR` inside it). Create, modify, move or remove NOTHING in the
  worktree except your report file. Run no floor, round, checkpoint, capture or
  accept, and no suite or test function in the worktree itself. The source must
  not move between reservation and completion, and the invoker checks that the
  worktree is byte-identical before and after your run.
- Free disk: about 8.5GiB free at reservation; swap shares the volume. Check
  `df -h /` before large copies (a copy is about 190 MB), and remove your own
  directory when you finish.
- Never pipe a suite through `tail`. `tests/run.sh` prints no total, so its exit
  code is the signal. Capture exit codes and read them back.
- Write the report to `notes/verification/reports/opponent-round12.md` (exempt
  from the source identity), AND return it verbatim as your final message.

## Report grammar the gate will parse

The returned file is the round-12 block ALONE. `--complete` appends it to
`notes/opponent.md`, validates it with `vf_reports`, re-validates the floor to
the reserved source, and re-verifies rounds 1-11 against their sealed digests.

```
## Round 12

**Round:** 12
**Timestamp:** <UTC YYYY-MM-DDTHH:MM:SSZ, not before the reserved time, not in the future>
**Source:** <exactly the reservation's source>
**Floor:** <exactly the reservation's floor>
**Verdict:** CLEARED | CHALLENGED
**Blocking:** <n> · **Minor:** <m>

### What I attacked
...

### Finding O-0XX
- **Class:** …
- **Status:** new | open | reopened | resolved
- **Prior:** O-0XX | none
- **Severity:** data-loss | wrong-result | regression | crash | minor | degraded
- **Scenario:** …
- **Where:** file:line, …
- **Reproduced:** …
- **Root cause:** plan-gap | spec-gap | implementation-error
- **Blocks:** REQ-…, AC-… | none
- **Wrong behavior:** …
- **Class-wide fix:** …

### Held up / follow-up tasks
...
<!-- gate-round-end: opponent:12 -->
```

The last line must be exactly `<!-- gate-round-end: opponent:12 -->`
(`scripts/verification-lib.sh:1144-1145`), and nothing non-blank may follow it.
These are the constraints `vf_reports` enforces (:1095-1109), stated so that a
correct report of either verdict can be canonized. The verdict itself is yours
alone.

- `Blocking`/`Minor` must equal the counted findings (:1101). CLEARED requires
  zero blocking, and CHALLENGED requires at least one (:1102).
- A CLEARED report may not carry a known ID at a tier below its strictest
  recorded tier (:1103). Nor may it carry a `resolved` finding that an earlier
  round of this gate counted open (:1109). O-016 was counted open (new,
  wrong-result) in round 11. So under CLEARED it may not appear as a
  `### Finding` block, and your assessment of its repair belongs in the two
  prose sections.
- A CHALLENGED report may re-list findings with any status, at their true tier.
