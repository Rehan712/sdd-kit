# T030o43 independent review (spec 003, O-017) — COMPLETE

Reviewer: independent read-only reviewer, 2026-09-27.
Environment at start: / 5.5 GiB free; swap 5145/6144 MB used; on battery 74% discharging.

Result: three blocking findings (F1, F2 and F3) and two minor (F4 and F5). Details follow.

## Findings

Base check: a private copy at /private/tmp/rev-t030o43/kit, built from the worktree's own
`git ls-files -z --cached --others --exclude-standard` (GIT_OPTIONAL_LOCKS=0) and made its own
git repository. `patch -p1` of `t030o43-session.diff` onto PRE_DIR reproduces every one of the 13
edited files `cmp`-equal to the copy. A scripts+templates-only pre-delta kit
(/private/tmp/rev-t030o43/prekit: the copy's scripts/ and templates/ with PRE_DIR's files laid
over them, each `cmp`-checked) gives the unrepaired behaviour for side-by-side runs. Every run
below used TMPDIR=/private/tmp/rev-t030o43/tmp, `LC_*` removed and `LANG` set as stated.

### F1 (blocking): the pin's premise is false for `[[:space:]]`, and the manifest pass it pins
still silently drops a finding it cannot read. For a UTF-8 caller, the delta turns O-017's refusal
into a seal.

The rule says "every grammar the kit parses is ASCII, so C reads every record a UTF-8 or
single-byte locale reads". The manifest grammar is `/^-[[:space:]]+\*\*Class:\*\*/` and
`/^-[[:space:]]+\*\*Severity:\*\*/` (`scripts/verification-lib.sh` vf_reports manifest pass). A
POSIX class is not ASCII-exact under a UTF-8 locale. On this host, macOS awk under en_US.UTF-8
matches U+00A0 (NBSP, which macOS types as Option+Space and rich-text pastes carry) as
`[[:space:]]`. grep under en_US.UTF-8 matches U+00A0 and U+3000. Under C, neither matches.
`flushm()` prints a manifest record only `if(id!="" && cls!="")`. So a Finding heading whose Class
line is not recognised is dropped without a word, which is the silent-omission failure T030o43's
second half exists to close.

Reproduction (`/private/tmp/rev-t030o43/work/nbsp.sh`; direct `vf_reports`, fixtures from
`tier_round_fixture` in tests/test-gate-contracts.sh). The manifest
`notes/verification/reports/opponent-findings-review.md` is `# Prior review`, a blank line,
`### Finding G-042`, then `-<U+00A0>**Class:** tier-binding` (bytes `2d c2 a0`),
`- **Severity:** data-loss` and `- **Scenario:** the operator key vanished`. The round is
`tier_round_fixture 1 '' G-042:tier-binding:open:minor`, a CLEARED round with 0 blocking and 1
minor.
- Pre-delta kit, LANG=C: rc=0 (sealable). Pre-delta kit, LANG=en_US.UTF-8: rc=3 with
  `clearing verdict rests on 1 lowered severity tier(s) of known findings; reconcile canonical records`.
- Post-delta kit: rc=0 with no diagnostic under both LANG=C and LANG=en_US.UTF-8.
- Class binding (round `G-042:silent-data-loss:open:wrong-result`): pre-delta en_US.UTF-8 gives
  rc=3 with `finding G-042 changes Class from tier-binding to silent-data-loss`. Post-delta gives rc=0
  in both locales.
- The same NBSP on the Severity line instead: pre-delta en_US.UTF-8 refuses the lowered tier
  (rc=3); post-delta accepts it in both locales (rc=0). The Class binding still holds there.
- Control: the ASCII manifest refuses with the exact diagnostics under both kits and both locales.
- End to end through the shipped entrypoint, post-delta. This is `round_locale_cases`'s
  construction (`make_verification_git_dir`, `floor_fixture`, floor, reserve, the same CLEARED
  report) with the manifest's Class line carrying U+00A0 (`nbsp-e2e-case.sh`, run from an ignored
  dot-file in the copy). `round <spec> opponent --complete` exits 0 with
  `round completed gate=opponent round=1 verdict=CLEARED report=…` under `LANG=C` and under
  `LANG=en_US.UTF-8`. `tally` then exits 0 with `blocking=0 minor=1`, although the manifest records
  G-042 at `data-loss`. The copy's status was unchanged afterwards.

So under the macOS default locale, the delta turns a refused CLEARED round, resting on a lowered
tier of a manifest-recorded data-loss finding, into rc=0. That is O-017's exact wrong result,
reached through a different byte, and now the same in every locale. The fixtures cannot see it,
because every manifest case uses byte 0x92, which C and UTF-8 both leave out of `[[:space:]]`. The
reading is not recorded history: M2's tally is unaffected, since no recorded manifest carries such a
line.

Smallest class-wide fix: make the manifest pass fail closed on a field it saw but could not read.
Severity cannot simply be made mandatory. The shipped positive in `test_reports_and_tally`
(`## Finding O-042` with `- **Class:** silent-data-loss` and no Severity, "the shape round 1 O-006
actually has, and it must keep working") must stay rc=0, and 003's real manifest carries both
fields. So the rule has two parts:
- Under a Finding heading, a line that carries `**Class:**` or `**Severity:**` but does not match the
  strict field grammar is an error.
- A Finding heading with no Class read before the next heading or END is an error.

In both cases the pass exits non-zero, which the status read this delta added already turns into
`prior-review manifest could not be parsed; reconcile canonical records`. The canonical round parser
does the same with `err("incomplete finding")`. The pin's rule also needs a second clause: a grammar
that applies a POSIX class to author text is not locale-free, so each parser that seeds records
from it must refuse a record it started and could not complete, not drop it. Add U+00A0 manifest
cases (on the Class line and on the Severity line) to `report_manifest_locale_cases`, each asserting
the refusal in every locale.

### F2 (blocking): the pin regresses `spec-evidence.sh`'s legacy artifact check for non-ASCII
file names, in both directions

`scripts/spec-evidence.sh` (legacy path, the M9 site this delta edited) extracts artifact names with
`grep -oiE '[[:graph:]]+\.(png|jpg|jpeg|gif|svg|pdf)'`. File names are user bytes, not an ASCII
grammar. Under the caller's en_US.UTF-8, `[[:graph:]]` covers `é`. Under the pinned C, no byte at or
above 0x80 is `[[:graph:]]`.

Reproduction: a legacy spec (no `verification_contract`), `spec.md` as in `floor_parse_fault_cases`,
and `tasks.md` holding `- [x] **T001** — Legacy task`, `  - *Acceptance:* legacy`, and
`  - *Evidence:* screenshot shots/café.png` (UTF-8 `c3 a9`). No such file exists.
- Pre-delta, en_US.UTF-8: rc=1 with `T001 names artifact 'shots/café.png' in its evidence, but no such file exists`.
- Post-delta, en_US.UTF-8 (and C): rc=0 with `sound — every ticked box traces to real evidence`.
  A ticked box naming a missing artifact passes.
- The other direction: the Evidence names `shots/écran.png`, and that file exists. Pre-delta
  en_US.UTF-8 gives rc=0. Post-delta en_US.UTF-8 gives rc=1 with
  `T001 names artifact 'cran.png' in its evidence, but no such file exists`, a false failure on
  correct evidence.

Pre-delta, the same miss existed only for a caller already in C. The delta makes it universal. The
checker is also a floor checker for any legacy spec.

Smallest class-wide fix: do not use positive POSIX classes over user bytes under the pin. For this
site use `[^[:space:][:cntrl:]]+\.(png|…)`, which under C takes every byte at or above 0x80. For the
class: add every positive POSIX class that meets author-supplied text (`[[:graph:]]`,
`[[:alpha:]]`, `[[:print:]]` and the like, as well as `[[:space:]]` in F1) to the member derivation,
and state them in the rule. A survey of the eight harness files finds one `[[:graph:]]`
(`spec-evidence.sh:115`) and four `[[:cntrl:]]` (vf_config `:276`, which only rejects; vf_escape and
vf_summary, which are display; spec-run.sh's legacy keyline, display). Add a non-ASCII artifact-name
case to `floor_parse_fault_cases`: a missing name must fail, and an existing one must pass.

### F3 (blocking for T030o43's acceptance; as a runtime defect it needs a failing `wc`): member
M7's second site is classified as repaired, but the code is unchanged

`t030o43-parser-classes.md` lists M7 as "counts over harness records: `vf_bindings :877-878`
(errors, warnings); `vf_return_parse :1843` (size bound)", marks it "an empty size passed the
64 KiB bound", and gives the repair as "status read". The delta changes only `:877-878`.
`vf_return_parse` still reads `[[ "$(wc -c < "$1")" -le 65536 ]] || { echo 'return exceeds 64 KiB' >&2; return 3; }`
(line 1975 now). A failed `wc` gives an empty string, `[[ "" -le 65536 ]]` is true, and the parse
goes on. No fixture and no mutation row covers it.

Reproduction (`/private/tmp/rev-t030o43/work/wc.sh`). The return is `Verification-Return: 1`,
`Task: T001`, `Captures: CAP-1-abcdef`, `Summary: x` and `Failure modes: none`, padded with
blank-space lines to 81088 bytes. It is fed to `bash -c '. scripts/verification-lib.sh; vf_return_parse <file> <out>'`.
- Unfaulted: rc=3 with `return exceeds 64 KiB`.
- With the delta's own device, `fault_bin <dir> wc -c` first on PATH: rc=0. The only output is
  `wc: injected fault`, and the out file carries the task, captures, summary and none records. The
  81 KiB return is parsed as valid.

The runtime trigger needs `wc` to fail on a file that awk then reads, so as a runtime defect this is
minor. The task's Acceptance, though, requires every such member to read its status and fail closed
with an exact diagnostic under an injected fault, and the receipt says this one does. It does not.

Smallest fix: `size="$(wc -c < "$1")" || { echo 'return: size could not be read' >&2; return 3; }`,
then `[[ "$size" =~ ^[[:space:]]*[0-9]+$ ]]` before the comparison. Add the fault row to
`acceptance_parse_fault_cases` (a `wc` fault must be refused by name), and add a mutation row.
Re-walk the classification table against the diff, so that no row is marked repaired without a
changed line.

### F4 (minor): five guards the delta added can be removed without failing any fixture, so the
Acceptance clause "removing … the caller-value record or any status read fails a fixture with
an exact diagnostic" is unmet

Each mutant below was applied as one literal replacement in the copy
(`/private/tmp/rev-t030o43/work/mut.sh`, `mutset1.sh`). Each was judged by its fixture function run
alone, as `t030o43-mutations.sh`'s `judge` does, and restored with `git checkout` and a clean
`git status --porcelain --ignored`. All seven unmutated fixtures pass in the copy (`base.rc`: all 0).
- **X1**, the inheritance rule: `if [[ -z "${SDD_HARNESS_CALLER_LC_ALL:-}" || "${LC_ALL-}" != C ]]` → `if [[ -z "${SDD_HARNESS_CALLER_LC_ALL:-}" ]]`
  ("never re-read once a record exists"). It SURVIVES `harness_locale_cases` and
  `acceptance_parse_fault_cases`, and survives again with `SDD_HARNESS_CALLER_LC_ALL=set:C` in the
  judge's environment. The reason: `tests/helpers.sh:51-53` unsets every `SDD_*` name when a suite
  starts, so no fixture ever starts a harness process with a record present and `LC_ALL` other than
  C. The mutant does have an effect. Run by hand, with the record `set:C` inherited and
  `LC_ALL=en_US.UTF-8`, `spec-run.sh --summary` records `key=seen=C`. The kernel comment's second
  disjunct is therefore unproven.
- **X2**, the unset branch of `vf_caller_env`: `unset) return 1;;` deleted, so an unset caller's
  declared `LC_ALL` is recorded as `present`, holding the pin's `C`. It SURVIVES both fixtures,
  because the declared-`LC_ALL` fixture compares only two set values. The live code is correct
  (M5 measured unset). With the mutant, though, an unset caller and a `LC_ALL=C` caller share one
  identity while their commands run under different locales, and no fixture would notice.
- **X3**, the manifest sort (`records="$(LC_ALL=C sort -u "$tmp")" || return 3` → `|| :`): SURVIVES
  `report_manifest_locale_cases`, which faults only the awk.
- **X4**, the tally sort (`LC_ALL=C sort "$tmp/class-lines" || { echo 'tally: the class table could not be sorted' …}` → no status read):
  SURVIVES.
- **X5**, `vf_ids`'s sort status (`… | LC_ALL=C sort -u` → `…; :`): SURVIVES
  `analyzer_locale_and_fault_cases`, whose faults are all in grep.

`t030o43-mutations.sh` has no row for any of these. Smallest fix: one fixture assertion each.
1. A harness process started with the record `set:C` and `LC_ALL=en_US.UTF-8` must give the
   captured command `en_US.UTF-8`. The fixture must set the record after `helpers.sh` has cleared
   `SDD_*`.
2. A declared `LC_ALL` with the caller's `LC_ALL` unset records `environment LC_ALL unset`, which
   differs from `LC_ALL=C`.
3. A `fault_bin sort` on the manifest's temp file (its path begins with the output path), and one on
   `class-lines`, each with the exact diagnostic.
4. A `fault_bin sort '-u'` confined to `vf_ids`'s stdin sort.

Add the matching matrix rows.

### F5 (minor, wording): three sentences state more than the code does

1. The kernel comment says: "Every grammar the kit parses is ASCII, so C reads every record a UTF-8
   or single-byte locale reads, and decodes every byte, where they do not". The Decisions rule and
   the task block say the same. F1 (U+00A0 as `[[:space:]]` under macOS UTF-8 awk; grep also takes
   U+3000) and F2 (`[[:graph:]]` over file names) are records that a UTF-8 locale reads and C does
   not. The contract's narrower wording ("reads every ASCII grammar the kit writes as any other
   locale would") holds for grammar the kit writes. It does not cover prior-review manifests or
   Evidence text, which are authored.
2. The contract (`templates/verification-contract.md`, the "change no record the harness writes"
   paragraph) says "a parse that fails never reads as a passing result". F1, where an unread field
   drops the manifest record, and F3, where the size bound passes when `wc` fails, are
   counter-examples on this tree.
3. The kernel comment says "lib.sh stays unpinned, so 002's dispatcher, which sources it but not
   this library, and the provider CLIs it starts keep the user's locale". That is true of
   `spec-dispatch.sh`. But `scripts/sdd-doctor.sh:26` also sources the kernel, and it is outside the
   harness file set the member is derived from. Since the delta, every program the doctor starts
   runs under `LC_ALL=C`. That includes the dispatcher's own readiness probe, `spec-dispatch-ready.sh`,
   which the doctor runs "through the same conservative probe used by spec-dispatch.sh":
   `claude auth status`, `codex login status` and `copilot -p '/user show'`. The resume listing and
   the scheduler listing run under C too. I found no verdict that changes: those parsers take hex
   IDs and the probe reads exit codes. Provider CLIs were not run. Still, the member statement ("the
   files vf_snapshot records as `harness`, and every process they start") leaves out a sourcer that
   the pin reaches.

Fix: after F1 and F2, restate sentence 1 as "every field grammar is ASCII, and a record whose field
positions hold a non-ASCII byte is refused, not dropped". Keep sentence 2 only once F1 and F3 hold.
Name `sdd-doctor.sh` in the member, or have it save and restore `LC_ALL` around the provider probes.

## Held

Every attack below was run in the private copy or the pre-delta kit, and none produced a wrong
result.
- **Base.** The copy equals PRE_DIR plus `t030o43-session.diff`, byte for byte, for all 13 files.
- **Where the pin sits (surface 1).** All six entry scripts (`spec-gate.sh:14`, `sdd-analyze.sh:35`,
  `spec-run.sh:40`, `spec-task.sh:30`, `spec-evidence.sh:37`, `spec-ac-coverage.sh:40`) load the
  kernel on the line after `lib.sh`. Before that line, only the `cd`, `dirname` and `pwd` that
  compute HUB_DIR run. `lib.sh` has no top-level command, and the kernel runs none of its own
  before `vf_locale_pin`. Moving the loads up causes no function-name or global-variable collision
  between the kernel or `lib.sh` and the four scripts whose load moved. Loading the kernel twice
  is idempotent. `spec-dispatch.sh` does not source the kernel. Harness children inherit the pin
  and the record: `accept` execs `spec-task.sh`, the floor and `vf_evidence_current` run
  `spec-task.sh list`, and `system-map.sh` inherits too.
- **Where a user command runs (surface 1).** I walked every execution site in the eight files. A
  configured or user command runs only in `vf_capture`'s `"$@"` and in `spec-run.sh`'s legacy run,
  and both call `vf_caller_locale`. Gate checks, checkpoints, task Verify commands and the three
  checkers all route through `vf_gate_execute` → `vf_capture`. Declared tools are hashed, never run.
- **What the captured command sees, and the hash (surface 2).** The captured command gets the
  caller's `LC_ALL` back when it is unset, empty or a value, and it never sees the record
  (`harness_locale_cases` passes). The hash and the run read the same record in the same process,
  whether it comes from the floor, a checkpoint, the accept exec chain or `spec-run.sh`. For record
  shapes `unset`, `set:`, `set:<v>`, a malformed record, and a hand-exported record beside
  `LC_ALL=C`, the hashed value is the command's `LC_ALL`. bash 3.2 prints nothing into the capture
  when an invalid `LC_ALL` is exported.
- **Recorded history, M2 (surface 1).** I ran `spec-gate.sh tally`, `sdd-analyze.sh` and
  `spec-ac-coverage.sh` on 001, 002 and 003 in four combinations: pre-delta and post-delta, each
  under `LANG=C` and `LANG=en_US.UTF-8` with `LC_*` removed. All 9 commands give output and exit
  byte-identical across the four runs (`repro/hist.out`: no DIFF lines). 001's tally keeps its
  recorded exit 3, and the others exit 0.
- **Identity, M3.** `vf_snapshot` of 003 gives the same records before and after the delta, apart
  from the `harness` records, under C, under C.UTF-8 with `LC_CTYPE=UTF-8`, and under en_US.UTF-8.
  After the delta the three locales give one digest (`ced64ca6…`); before it they also gave one
  (`a8e1d916…`).
- **bash behaviour.** `CAP-*` globs order the same under C and en_US.UTF-8 whenever the sequence
  numbers differ, and every real capture ID has a distinct sequence number. The harness has no bash
  string-ordering test (`[[ a < b ]]`). `nocasematch` sees only ASCII paths for the kit's specs. No
  `cut -c`, `wc -m` or `printf %q` in the harness reads author text.
- **The frontmatter readers (surface 3).** `vf_fm_value` and `vf_fm_count` match `fm_get` and
  `frontmatter_block | grep -c` on all 30 frontmatter shapes I tried (`repro/fmdiff.sh`, 0 diffs).
  The shapes were CRLF, tabs, both quote styles, inline and bare comments, duplicate and empty keys,
  a BOM, a key only in the body, an unterminated fence, a fence with trailing blanks, a key with a
  suffix, and bytes 0x92 and U+00A0.
- **The status reads (surface 3).** grep's no-match status of 1 counts as success at every new site
  (`vf_ids` tests `rc < 2`, the analyzer `nc_rc > 1`, spec-evidence `arts_rc < 2`). The manifest,
  waiver and tally awks contain no `exit`, so a status read cannot fire on a normal parse. The new
  sorts and `vf_ids` read their whole input, so there is no SIGPIPE. The early load and `|| exit 3`
  are safe under `spec-task.sh`'s `set -euo pipefail`. `pipefail` is set in every entry script and in
  `vf_hash`. The "closed" and "display" rows I checked hold: analyzer `:276` refuses when its summary
  is empty, `impl_refs` and the dangling-ref loop fail on a short read, `:1230` aborts the tally with
  rc 1 on an empty operand (measured), and the waiver's `fm_get … status` denies.
- **The fixtures (surface 4).** All seven new fixture functions pass unmutated in the copy
  (`repro/base.rc`), and so does `test_instruction_contracts`. That one failed in the recorded
  `t030o43-dev1-quick.log`, and passes on this tree in 71 s. Every `fault_bin` marker I read occurs
  only in its target invocation, and every fixture asserts the target site's own diagnostic, so a
  stray match can only fail a fixture, never pass it. `locale_hostile` is a real precondition on
  this macOS host. No new rc=0 positive asserts an attack: they are a genuine waiver below a 0x92
  line, unfaulted baselines, the tally of a new data-loss finding, and `accept` under the capture's
  own `LC_ALL`.
- **Wording (surface 5).** The O-010 rewording ("the record of a declared `LC_ALL` carries the
  caller's value") is true, and it passes the scan because it is no default-membership claim.
- **Regressions (surface 6).** The checkpoint's contract is field 9 of the catalog's first record.
  That record is written first for both v1 (`:1010`) and legacy (`_vf_catalog_meta`) specs, from
  the checked reader's value. `spec-ac-coverage.sh` loading the kernel on every path changes
  nothing but the locale. The glob order and ASCII-only `nocasematch` break no real use I could
  construct. The one regression I found is F2.

## Not reached

- **Linux, GNU tools, bash 4 or 5.** Every locale fixture skips its precondition off Darwin
  (`uname -s` guard), and GNU awk does not die at 0x92. On a Linux host, the manifest and round
  locale cases therefore pass with or without the pin, and prove nothing there. I did not measure
  GNU grep's binary-file handling of a UTF-8 file with a stray byte.
- **Runs I did not make.** I did not re-run the invoker's `t030o43-mutations.sh`; only my X1-X5
  mutants and the baselines. I ran no full suite and no ShellCheck: the invoker's suite was running,
  and the host was on battery (61%, 1:36 remaining at the last check). I did not run the provider
  CLIs from F5.3, or any floor, round or accept outside the copy's fixtures.
- **Surfaces not attacked.** EUC-JP, GB18030 and Big5 locales. Git-run user programs (clean
  filters, fsmonitor, hooks), which now run under the pin with the record in their environment.
  Umbrella and multi-repo roots, and `system-map.sh`'s own parsers.
- **The recorded dev run.** `t030o43-dev1-full.log` was still empty, still in progress, when I
  started.

Reproduction scripts are kept beside this report in `repro/`. They name paths inside the removed
private copy at /private/tmp/rev-t030o43. To re-run them, rebuild that copy from the worktree's
enumeration, and rebuild the prekit from PRE_DIR, as the Base check describes. Nothing in the
worktree was created, modified, moved or removed.

REVIEW COMPLETE
