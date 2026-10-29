## Round 12

**Round:** 12
**Timestamp:** 2026-09-27T14:36:02Z
**Source:** bb996df97887231e1fd50ebce39b2d3b7f918e3896917ea0031a59b227198254
**Floor:** FLOOR-0334B2
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 0

### What I attacked

I checked identity and scope myself before using the brief. `notes/verification/rounds/opponent/ROUND-12/meta.nul` records round 12, FLOOR-0334B2, source `bb996df9…` and reservation time 2026-09-27T13:44:57Z. All execution ran in private copies under `/private/tmp/opp12`, with `TMPDIR` inside that directory. Each copy is the worktree's own `git ls-files -z --cached --others --exclude-standard` enumeration, read with `GIT_OPTIONAL_LOCKS=0`, plus its own `.git` holding the live index and the main repository's objects as a read-only alternate. In the first copy `vf_snapshot` produces 370 records; with the copy's path written in place of the worktree's, all 370 are byte-equal to FLOOR-0334B2's `inputs.nul`, so the copy holds the reviewed source. In that copy:
- `spec-gate.sh waiver … opponent 12` prints `authorized: opponent round 12` at exit 0, and round 13 exits 4 with ten refused candidates;
- `spec-gate.sh tally` gives opponent rounds=11, reality-check rounds=1, blocking=25, minor=10, severity-downgrades=5, byte-identical under `LANG=C` and `LANG=en_US.UTF-8`; 002 exits 0 at blocking=6 and 001 keeps its recorded exit 3;
- T030o42's receipts hold: the return file hashes to `7b457257…`, and CAP-499-rKuH6Z is `bash tests/run.sh && bash tests/shellcheck.sh` at exit 0, policy local, no_tick 1, input `bb996df9…` before and after, 147/147.

The repair itself (T030o42, O-016):
- **Placement.** `tests/run.sh:24`, `tests/shellcheck.sh:24` and `tests/helpers.sh:27` each export `LC_ALL=C` directly after `unset CDPATH BASH_ENV ENV`. Only builtins run before the first two. Every suite runs only `dirname` before loading `tests/helpers.sh`; `test-usage-limits.sh` also runs `set -u`, `cd` and `pwd`.
- **The fixture, both directions.** `reuse_command_locale_cases`, run alone in a copy, exits 0 unmutated. With `tests/helpers.sh:27` replaced by a no-op it fails with `AC-020: a suite did not export LC_ALL=C to the programs it runs (O-016)` (expected `C LC_ALL=C`, actual `unset not-exported`), with `AC-020: a usage-limits case followed LANG=en_GB.UTF-8 (O-016) unexpectedly contains: FAIL test_`, and with its de_DE twin. Restored and checked with `cmp`.
- **Round 11's case.** `bash tests/test-usage-limits.sh` passes 27/27 under `LANG=en_GB.UTF-8` and under `LANG=de_DE.UTF-8`, with every `LC_*` name removed.
- **The acceptance command.** In the first copy, `bash tests/run.sh && bash tests/shellcheck.sh`, run with every `LC_*` name removed and `LANG=de_DE.UTF-8`, exits 0: 15 suites, 147/147, then ShellCheck clean (14:17:02Z to 14:35:29Z). The copy's status digest is unchanged, and its `TMPDIR` is left empty.
- **The other shared verdicts (F2).** FLOOR-0334B2's `commands.nul` holds 75 records (21 executed, 54 reused) over 22 distinct command strings. Every task and gate command is `tests/run.sh`, `tests/shellcheck.sh` or a chain of `bash tests/test-*.sh`, all pinned; the rest are the three harness checkers. So F2 is latent, as recorded.

Then I attacked the claim this repair wrote down. T030o42's acceptance requires the contract and the kernel comment to say that the harness "fails closed in a locale that cannot decode the kit's bytes". The 2026-09-27 Decisions entry chose to repair review F1 in wording only, on the premise "Everything found fails closed; none is a wrong PASS". I derived the class from what the parsers do, not from the reproductions reported. On this host:
- macOS `awk version 20200816` aborts with `towc: multibyte conversion failure` at exit 2, at the first regular-expression operation on a record it cannot decode;
- macOS grep sees nothing after the first undecodable byte of a line, and still exits 0. For the line `AC-001 before`, byte 0x92, `AC-002 after`, under `LANG=en_US.UTF-8` `grep -oE 'AC-[0-9]{3}'` prints only `AC-001` at exit 0, and `grep -cF AC-002` prints 0.

So "fails closed" holds exactly where a caller reads the parser's exit status, and fails open where it does not. I walked the harness readers by the files they read:
- **spec, plan, tasks and STATUS of every spec.** `vf_semantic_file`'s awk tests every line with a regex, so `vf_snapshot` itself exits 3: one 0x92 byte added to 003's `spec.md` gives rc=3 under en_US.UTF-8 and a digest under C. Every floor, capture, acceptance and round snapshots before it writes a record, so inside the gate path these files fail closed.
- **Checked parsers.** `vf_return_parse`, `vf_report_block`, `vf_matrix_parse`, `vf_ac_catalog`, `vf_config` and the main `vf_reports` awk all have their exit read, so they fail closed.
- **`vf_round_authorized`** (`scripts/verification-lib.sh:2465`) discards its awk's status inside `line="$(…)"`. A truncated parse there can only lose authorizations, which denies.
- **The prior-review manifest pass in `vf_reports`** (`:955`) discards its status. A truncated parse there loses the history three guards read. That is Finding O-017.
- **The standalone analyzer.** Outside a floor, `sdd-analyze.sh` reads `spec.md` with grep alone. That sibling is recorded under O-017.

Known open, left as recorded:
- the harness-level startup and option environment;
- `TZ`;
- `PATH` choosing an undeclared tool;
- 002's classifier. Under the pin, the suite judges it under C only;
- review 7's F1, F2 and F4 and K74;
- the kernel's ambient fixture reads;
- the analyzer field grammar;
- the umbrella-only readers;
- the O-004 omission extent;
- the opponent-only guards at `:1101-1103`;
- README and the completion marker;
- 001's exit 3.

Not reached, and therefore not cleared:
- Linux, GNU tools, and Bash 4 or 5. GNU grep treats an undecodable byte differently, so the grep half of O-017 is a macOS measurement;
- a floor sealed for this kit under a second locale;
- EUC-JP, GB18030 and Big5, where I tested only Shift-JIS;
- the mutation matrix beyond the one row I re-ran;
- umbrella and multi-repo roots, acceptance crash windows, a real reality-check carry, the `r`-suffix branch, and AC-014/017/018 prose.

Nothing in the worktree was created, modified, moved or removed except this report.

### Finding O-017
- **Class:** harness-locale-decoding
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** A prior-review manifest records a finding at a blocking tier, and one of its lines carries a byte the caller's locale cannot decode; the first opponent round re-records that ID, still open, at `minor`, returns CLEARED, and is completed from the macOS default `LANG=en_US.UTF-8`.
  1. The manifest is `notes/verification/reports/opponent-findings-<label>.md`, the mechanism this gate's round 1 used to resolve O-006. The byte can be a cp1252 apostrophe (0x92) pasted into a Scenario, a raw byte quoted from a tool's error output, or, under Shift-JIS, ordinary UTF-8 punctuation.
  2. `spec-gate.sh round <spec> opponent --complete <report>` runs `vf_reports` over the combined file (`scripts/verification-lib.sh:2644`). The manifest pass at `:955` is `priorids="$priorids$(awk … "$manifest" | sort -u | tr '\n' ' ')"`, so its status is read by nobody.
  3. awk records a manifest finding only when it reaches the next Finding heading or END. When it dies, the finding in progress and every later one are gone, and `firstclass`, `firsttier` and `manifestseen` (`:984-:992`) are seeded without them.
- **Where:** scripts/verification-lib.sh:955, scripts/verification-lib.sh:984, scripts/verification-lib.sh:990, scripts/verification-lib.sh:1006, scripts/verification-lib.sh:1054, scripts/verification-lib.sh:1103, scripts/verification-lib.sh:2644, scripts/verification-lib.sh:1219, scripts/verification-lib.sh:2431, scripts/verification-lib.sh:2465, scripts/verification-lib.sh:1576, templates/verification-contract.md:356, scripts/sdd-analyze.sh:147
- **Reproduced:** End to end through the shipped entrypoint, with fixtures from the kit's own `tests/helpers.sh` and `tests/test-spec-gate.sh` (`make_verification_git_dir`, `floor_fixture`) in a private copy; one fresh fixture per locale, floor sealed and round 1 reserved under C each time.
  - **The inputs.** The manifest has six lines: `# Prior review`, a blank, `### Finding G-042`, `- **Class:** tier-binding`, `- **Severity:** data-loss`, and `- **Scenario:** the operator` + byte 0x92 + `s key vanished`. The returned report carries the reservation's identities, `**Verdict:** CLEARED`, totals of 0 blocking and 1 minor, and G-042 with `Class: tier-binding`, `Status: open`, `Prior: none` and `Severity: minor`, with every other required field and section.
  - **Under `LANG=C`, `LC_*` removed.** `round --complete` exits 3 with `report recovery: …/combined.md:25: clearing verdict rests on 1 lowered severity tier(s) of known findings; reconcile canonical records`, and ROUND-1 stays pending.
  - **Under `LANG=en_US.UTF-8`, `LC_*` removed.** The identical bytes exit 0 with `round completed gate=opponent round=1 verdict=CLEARED report=ae014dfd…`, after awk printed `towc: multibyte conversion failure … input record number 6, file …/opponent-findings-review.md` to stderr. `ROUND-1/report.sha256` is sealed. `tally` in that shell exits 0 with `blocking=0 minor=1 … severity-downgrades=0`.
  - **Afterwards.** Under C, `tally` exits 3 with the same lowered-tier refusal at `notes/opponent.md:25`, and reserving round 2 exits 3. Under en_US.UTF-8, round 2 reserves at exit 0.
  - **Direct `vf_reports`.** It returns rc=3 under C and rc=0 under en_US.UTF-8, de_DE.UTF-8 and C.UTF-8, and also in this review's own shell (`LANG=C.UTF-8` with `LC_CTYPE=UTF-8`). As a control, the same manifest with the apostrophe written as UTF-8 U+2019 gives rc=3 with the refusal under all four.
  - **Class binding.** A manifest recording G-042 as `tier-binding`, and a CHALLENGED round reusing G-042 as `silent-data-loss`, gives rc=3 under C with `finding G-042 changes Class from tier-binding to silent-data-loss`, and rc=0 under the three UTF-8 locales.
  - **Shift-JIS, which the contract names.** A valid UTF-8 manifest whose only non-ASCII is one em dash gives rc=3 under C and under en_US.UTF-8, and rc=0 under `ja_JP.SJIS`.
  - **Sibling, outside the gate path.** In a copy, one line was added to 003's `spec.md`, with 0x92 before `[NEEDS CLARIFICATION: …]`. `sdd-analyze.sh` exits 1 with `unresolved [NEEDS CLARIFICATION] marker(s)` under C, and 0 with `no unresolved [NEEDS CLARIFICATION] markers` and `1 warning(s), 0 errors` under en_US.UTF-8. The file was restored and is `cmp`-equal to the worktree's.
  - **Candidate fix, measured.** Prefixing the `:955` awk with `LC_ALL=C` turns every case above into the C result, with the same diagnostics. Against the recorded history, `spec-gate.sh tally` for 001, 002 and 003 is byte-identical to the unpatched kit's under both C and en_US.UTF-8.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, REQ-009, AC-012, AC-020
- **Wrong behavior:** The gate seals a CLEARED opponent round that the C reading of the same bytes refuses, so a still-open blocking finding is tallied as a minor to buy clearance under the default macOS locale.
  - REQ-011 says severity never changes merely to meet a round or cost target. AC-012's manifest fixture (`tests/test-gate-contracts.sh:781`, "round observation weakened the strictest manifest tier") and round 9's resolution of O-004 ("can no longer be tallied as a minor to buy CLEARED, whatever order its tiers were recorded in") both rest on the manifest seeding at `:984-:992`. That seed is exactly what the locale removes. The Class binding at `:1006` goes with it.
  - The same validator runs `tally` (`:1219`) and every later reservation (`:2431`). The sealed history is then accepted or refused according to the reader's locale. Under C it is refused with "reconcile canonical records", and clearing that means rewriting the sealed round or deleting the prior-review record the guard exists to honour.
  - T030o42 wrote into `templates/verification-contract.md:354-358` that the locale categories "change no record the harness writes". It also wrote that the harness "fails closed in a locale that cannot decode the kit's bytes, such as Shift-JIS, or a UTF-8 locale over an invalid byte", and it put the same sentence into the kernel comment at `scripts/verification-lib.sh:1573-1577`. Here the locale decided whether the harness wrote the round record, and it did so under exactly the two locale shapes that sentence names.
  - The decision to leave the kernel's locale reads as they are rests on "Everything found fails closed; none is a wrong PASS", which this reproduction contradicts.
  - Unlike O-016, this needs no second shell, and the identity does not move, because the manifest is this spec's own bookkeeping. The standalone analyzer sibling is the same mechanism through grep: a marker the gate exists to block reads as absent.
- **Class-wide fix:** Run the kernel's own text parsing under `LC_ALL=C`, and never discard a parser's exit status.
  - **Scope of the pin.** It covers every awk, grep, sed, tr and sort the harness runs over repository or bookkeeping bytes, in the kernel, the analyzer and the checkers. The command `vf_capture` executes keeps the caller's environment.
  - **Why it is safe.** Every grammar the kernel parses is ASCII, so the pin changes no identity byte (the snapshot is already `cmp`-equal under C, C.UTF-8 and ISO8859-1). Measured at `:955`, it changes no recorded tally.
  - **Exit statuses.** `:955` and `:2465` write to a file and `|| return 3`.
  - **Fixtures.** Run the manifest cases above with `LC_ALL` removed under `LANG=en_US.UTF-8` and `ja_JP.SJIS`; each must refuse exactly as under C. Add one mutant per pinned site, and the standalone analyzer marker case.
  - **Wording.** Then correct the contract and the kernel comment to describe what is true. Narrowing the sentence alone would leave a CLEARED verdict decided by `LC_CTYPE`.

### Finding O-016
- **Class:** verification-input-identity
- **Status:** resolved
- **Prior:** O-016
- **Severity:** wrong-result
- **Scenario:** Round 11's case: a PASS of `bash tests/run.sh` (or T030o42's Verify) captured in one shell and reused by a floor sealed from a UK- or German-region shell, where a fresh run failed 144/147 on the three usage-limits cases. I also ran the suites with every `LC_*` removed under `LANG=de_DE.UTF-8`, removed the helpers pin, and enumerated every command a floor honours across shells.
- **Where:** tests/helpers.sh:27, tests/run.sh:24, tests/shellcheck.sh:24, tests/test-verification.sh:548, tests/test-usage-limits.sh:392, scripts/usage-limit.sh:32
- **Reproduced:** `bash tests/test-usage-limits.sh` passes 27/27 under en_GB.UTF-8 and under de_DE.UTF-8; the acceptance command's result is in What I attacked. Removing the helpers pin fails `reuse_command_locale_cases` with the three exact diagnostics quoted there, and the restore is `cmp`-identical.
- **Root cause:** implementation-error
- **Blocks:** REQ-009, AC-020
- **Wrong behavior:** Nothing remains wrong for round 11's subject. Every reuse-checked command the kit ships, and every suite a task's Verify runs, now reaches its programs under `LC_ALL=C`, so the default locale variation between shells cannot decide a reused verdict. The harness's own locale reads are a different subject, recorded as O-017.
- **Class-wide fix:** Closed for this member. Keep the fixture, and extend its probe set as F2 records.

### Held up / follow-up tasks

These surfaces held:
- O-016's subject, as recorded above.
- The copy's manifest equals FLOOR-0334B2's, and the waiver, the refusal, the tally and T030o42's receipts reproduce.
- Every gate-path reader of spec, plan, tasks and STATUS fails closed through the snapshot.
- Every parser whose exit is read fails closed.
- The waiver parse's discarded status can only deny.

Proposed follow-up:
- **T030o43, for O-017.** Pin `LC_ALL=C` for the kernel's own text parsing (kernel, analyzer and checkers, not the captured command), read every parser's exit status (`scripts/verification-lib.sh:955` and `:2465` first), add the manifest locale fixtures with their mutants and the analyzer marker case, and then correct `templates/verification-contract.md:354-358` and `scripts/verification-lib.sh:1573-1577` to what is true.
<!-- gate-round-end: opponent:12 -->
