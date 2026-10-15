## Round 10

**Round:** 10
**Timestamp:** 2026-09-24T03:07:16Z
**Source:** 6c6291c2b37d35fb82c67c42c173ae042bb116c742f1c84a5dfa9c1c77c04c2d
**Floor:** FLOOR-qQEv7w
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 0

### What I attacked

I checked identity and scope myself before relying on the brief. `notes/verification/rounds/opponent/ROUND-10/meta.nul` records round 10, FLOOR-qQEv7w, source `6c6291c2…` and reservation time 2026-09-24T02:31:44Z. A read-only `vf_snapshot` of the live worktree, with TMPDIR outside it and `GIT_OPTIONAL_LOCKS=0`, prints `6c6291c2…`. The worktree's `git status --porcelain -uall` digest was the same before and after that read, and again when I finished. Against that manifest, `vf_capture_check` accepts the floor's CAP-433-Yy72Iz, CAP-443-0KR1mR, CAP-449-yKKssl, CAP-453-gA0Lj4 and CAP-454-X5Tgos under `reuse` at rc=0, and the three checker captures under `current`. CAP-449's log shows 15 suites and 130 `ok` lines. The pre-repair files are git blobs f13e78b, 49da7ee, 27ca7ca and 4595bac, and their SHA-256 values equal FLOOR-k1reWt's four `path` records. Comparing the six-field records of FLOOR-k1reWt, FLOOR-oejTDu and FLOOR-qQEv7w reproduces the brief's scope exactly. There are twelve new `index`/`path` records for 001's and 002's `notes/{evidence,opponent,reality-check}.md`, no records disappeared, the changed paths are the four repaired files plus 003's plan, tasks and STATUS, and oejTDu and qQEv7w differ only in STATUS.md. On a copy, `spec-gate.sh waiver … opponent 10` prints `authorized: opponent round 10`, and round 11 exits 4 listing eight candidates, the last at STATUS.md:367.

All execution ran in two copies under `/private/tmp/opp10`, each with its own `.git` using the live index and the main repository's objects as a read-only alternate. Every copy's manifest records are equal to FLOOR-qQEv7w's, apart from the path-bearing `version`, `harness` and `document` records. In the first copy, `bash tests/test-verification.sh` passes 3/3 and `bash tests/test-gate-contracts.sh` passes 14/14, both at exit 0 with no `assert:` line, so T030o39's and T030o40's acceptance reproduces.

For T030o39 I read the production `vf_snapshot` actually applies, not only the predicate the repair named. There are two exclusion functions: `vf_bookkeeping_path` chooses paths (:1333), and `vf_semantic_file` chooses content (:1396). I attacked the path half as follows:
- the anchor: its regex, its `nocasematch` save and restore, a spec equal to the repository root, and a sibling spec whose name has the verified spec's as a prefix;
- the fold probe: a letterless spec name, a case-swapped symlink alias, and a climb that could cross onto another volume, which is bounded here because `specs` always carries a letter;
- physical resolution: a trailing `/.`, a trailing slash on a directory symlink, an absolute link spelled through `/tmp` rather than `/private/tmp`, a declared directory reached through a symlinked parent, and dangling and looping links;
- member skips under three spellings of the declared directory;
- snapshot cost, which is 9.5 s now against 9.0 s with the round-9 library on the same tree.

That half holds. The content half does not hold where the O-010 guard reads the tree, which is Finding O-015. I then re-swept O-013's two recorded readers of other specs' normalized bytes. With every open checkbox of 002's `tasks.md` set to `[x]` and three set to `[~]`, and separately with 002's STATUS `phase:` set to `plan` and then to `specify`, the manifest is unchanged and `bash tests/test-sdd-analyze.sh` still passes 18/18 at exit 0. The analyzer does not read spec `status:`. The 002 tally now reads only hashed bytes.

For T030o40, `spec-gate.sh tally` on 003 prints `severity-downgrades=5`. The emitted `downgrade` records are O-001 in round 1, O-002 in rounds 6, 7 and 8, and O-010 in round 7. 002 prints 0 with all its asserted counts, and 001 keeps its pre-existing exit 3 at `notes/opponent.md:59-61`. Every catalog consumer (`vf_round_history` :2374, the completion loop :2588, `vf_tally` :1221) switches on the record type, so a `downgrade` record is inert to all but the tally. The guard's predicate moved but kept the same inputs, so canonical clearance decisions are unchanged. I also mutated one guard outside the recorded matrix, and it survives; it is listed under Held up.

Known open, confirmed rather than rediscovered:
- the O-004 omission extent;
- the opponent-only totals, verdict and downgrade guards at :1101-1103;
- README's comment-only `Verification-Return` at :427;
- invoker documents without the completion marker, since only the two personas carry it;
- 001's exit 3.

Not reached, and therefore not cleared: umbrella and multi-repo roots, acceptance crash windows, a real reality-check carry, the `r`-suffix branch, per-negative branch coverage, and AC-014/017/018 prose. I did not run the full `tests/run.sh` or ShellCheck myself; for those I relied on CAP-449 and CAP-454. Nothing in the worktree was created, modified, moved or removed except this report.

### Finding O-015
- **Class:** verification-input-identity
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** FLOOR-qQEv7w is current at `6c6291c2…`, and its reuse-checked captures of `bash tests/test-gate-contracts.sh` (CAP-433) and `bash tests/run.sh` (CAP-449, CAP-453) are reusable. The next bookkeeping write is the one `skills/sdd-implement/SKILL.md:161-164` prescribes for a Gate task once this round completes, `spec-task.sh done <spec> T030 --evidence "<observed>"`. It ticks the box, rewrites `updated:` and appends a free-text Evidence line. Suppose the observed text is `hosted CI green; the macOS job includes PATH and TMPDIR shims for Bash 3.2 (2026-09-24)`. The same bite comes from any such sentence in the Evidence line of any spec's `tasks.md`, which legacy `spec-run.sh` fills from the checked command's own last output line (`scripts/spec-run.sh:193`), or in a `status:`/`updated:` frontmatter line of any spec's `spec.md`, `plan.md` or `tasks.md`. The next floor, or the reality-check reservation planned against this floor, then follows.
- **Where:** tests/test-gate-contracts.sh:47, tests/test-gate-contracts.sh:52, tests/test-gate-contracts.sh:97, tests/test-gate-contracts.sh:104, tests/test-gate-contracts.sh:17, scripts/verification-lib.sh:1404, scripts/verification-lib.sh:1405, scripts/verification-lib.sh:1424, scripts/verification-lib.sh:1455, scripts/verification-lib.sh:1447, scripts/verification-lib.sh:1719, .specify/stack.yml:14, .specify/specs/003-gate-round-reduction-and-token-discipline/tasks.md:597, skills/sdd-implement/SKILL.md:164, scripts/spec-run.sh:193
- **Reproduced:** In a copy holding the reviewed bytes I captured `bash tests/test-gate-contracts.sh` through `spec-run.sh <spec> T030o38 --from-task --no-tick --summary`. That gave CAP-455-FZ4Zok, exit 0, `14/14 passed`, input `dd1f4df7…`. I then ran exactly the `spec-task.sh done … T030 --evidence` command above, which printed `T030 -> [x] with evidence`. The manifest digest stayed `dd1f4df7…`, and `vf_capture_check` accepts CAP-455 under `reuse` at rc=0. Re-running the same command then exits 1 with `FAIL test_instruction_contracts` and `assert: AC-018: superseded fixed-environment membership survives in a current artifact`, actual `.specify/specs/003-gate-round-reduction-and-token-discipline/tasks.md :: includes PATH`, 13/14. In a second copy the same sentence tested three ways, as an Evidence line in 002's `tasks.md`, as one in 003's, and as a comment on 002's `plan.md` `updated:` line. Each leaves the manifest `cmp`-identical to the baseline, and the guard function, extracted verbatim, reports that file every time. On the live worktree, read-only, the same edit cannot move `6c6291c2…` for the same reason, while CAP-433, CAP-443, CAP-449, CAP-453 and CAP-454 pass `reuse` at rc=0 today. So the floor would stay current, and those PASS results reusable, over a suite that now fails. The opposite direction reproduces as well. An untracked `docs/café.md` stating the claim gets a manifest record `docs/café.md`, but git prints it as `"docs/caf\303\251.md"` without `-z`, `[[ -f ]]` at :52 skips it silently, and the guard reports only its plain-ASCII twin. No tracked path is quoted today, so that half is latent. Every edited file was restored and verified with `cmp`, and both copies return to their baseline digests.
- **Root cause:** plan-gap
- **Blocks:** REQ-009, AC-020
- **Wrong behavior:** AC-020 says the failing-test "sound evidence" scenario cannot obtain reusable or current-PASS status. REQ-009 says bookkeeping edits, checkbox state among them, do not invalidate unchanged code execution. Both hold only if a reuse-checked command's result does not depend on the bytes the identity treats as bookkeeping. `vf_snapshot` hashes content through `vf_semantic_file`, which drops every Evidence line (:1405) and the `status:`/`updated:` frontmatter (:1404) of every `.specify/specs/*` spec, plan and tasks file, and it does this in both the index pass (:1455) and the path pass (:1424). The O-010 guard claims its scope comes "from the enumeration the input manifest itself uses" (:17-31), and T030o30's acceptance binds it to "every artifact whose content the input manifest hashes as current source" (`tasks.md:597`). What it actually applies is only the path function (:50). It reads each file's raw bytes (:97) and enumerates without `-z` (:47). The guard's verdict is therefore a function of bytes outside the identity, and it runs inside `bash tests/test-gate-contracts.sh` and `bash tests/run.sh`, both opted into reuse (`.specify/stack.yml:14-16`). Capture currency and reuse are decided by the manifest digest alone (:1719). A floor therefore takes a cache hit on a PASS the tree no longer produces, and a reservation against FLOOR-qQEv7w would present it as current proof. Round 9's O-013 sweep named two readers of other specs' normalized content, the 002 tally and the AC-023 analyzer loop. This is a third reader, and unlike those two it also reads the verified spec's own normalized lines. The next write of exactly that kind is the T030 tick. T030o39's path anchoring is correct and is not the cause. The trigger needs text the guard flags, which narrows it, but the violated sentence is an AC's, so under REQ-011 it blocks as wrong-result. Hosted CI re-runs fresh, so it would catch this at the PR, but only after the gate has certified the floor.
- **Class-wide fix:** Make the guard read exactly what the identity hashes, through the same two functions. Enumerate with `git ls-files -z --cached --others --exclude-standard`, read NUL-delimited, and treat a git failure as a failure rather than an empty tree. Pass each file through `vf_semantic_file "$path"` before the awk scan, and keep the STATUS.md subtraction. I trialled this on a copy. Scanning the `vf_semantic_file` output in place of the raw file leaves all of `superseded_environment_cases` passing: the live tree stays clean, every escape shape is still reported, and every over-correction control stays silent. The Evidence-line claim is no longer reported, while the same sentence appended to the body of the same `tasks.md` still is. Fixtures, in both directions:
  - a claim on an Evidence line or a `status:`/`updated:` line of a fixture `.specify/specs/x/tasks.md` is not reported and leaves the manifest unchanged;
  - the same claim in the body is reported;
  - a claim in a file whose name git quotes is reported.

  The general rule: any reuse-checked command that reads repository files must read them through both `vf_bookkeeping_path` and `vf_semantic_file`, or the identity must hash what it reads. In this repository's `tests/`, the O-010 guard is the only reader that flips. The 002 tally now reads only hashed bytes, and the analyzer loop held under every checkbox, Evidence and phase edit I made.

### Finding O-013
- **Class:** verification-input-identity
- **Status:** resolved
- **Prior:** O-013
- **Severity:** wrong-result
- **Scenario:** Round 9's attack edits one line of 002's `notes/opponent.md`, adds a findings manifest or a floor record under 002's `notes/`, or declares another spec's report under `verification_inputs:`. On top of those I attacked the new mechanism itself. For the anchor and fold probe I tried a letterless spec name, a case-swapped symlink alias and a climb bounded by `specs`. For the physical refusal I tried `/.`, a trailing slash on a directory symlink, an absolute link via `/tmp`, a symlinked parent with `..`, and dangling and looping links. I also tried the member skip under three spellings.
- **Where:** scripts/verification-lib.sh:1333, scripts/verification-lib.sh:1354, scripts/verification-lib.sh:1368, scripts/verification-lib.sh:1379, scripts/verification-lib.sh:1438, scripts/verification-lib.sh:1451, scripts/verification-lib.sh:1458, scripts/verification-lib.sh:1469, scripts/verification-lib.sh:1471, scripts/verification-lib.sh:1482, tests/test-verification.sh:396, tests/test-gate-contracts.sh:48
- **Reproduced:** The reviewed floor carries the twelve 001/002 records the anchoring intends, and the fixtures reproduce the round-9 negatives in both directions through a real capture. In my copy, `test_capture_provenance` passes, and so do the declared-refusal, case-fold, `GIT_DIR` and newline-path cases. Each physical-resolution spelling I added either resolved to the same repository-relative record as its plain form or failed closed. The recorded matrix kills all 25 mutants, the two equivalents E1 and E2 are argued correctly, and the O-010 scan's per-path anchoring removes exactly every spec's generated records.
- **Root cause:** plan-gap
- **Blocks:** REQ-009, AC-020, AC-007
- **Wrong behavior:** Nothing remains wrong for the round-9 subject. Another spec's gate reports, manifests, captures and floor records are now inputs, a declared input is hashed or refused by name, and the verified spec's own records stay out whatever spelling or case reaches them. The class is still open through content normalization, recorded as O-015.
- **Class-wide fix:** Closed for this member. The content half of the same "same function" property is O-015's fix.

### Finding O-014
- **Class:** gate-report-schema-validation
- **Status:** resolved
- **Prior:** O-014
- **Severity:** degraded
- **Scenario:** A declared prior-review manifest records an ID at a blocking tier, and a later round records it, not resolved, at a minor tier. That is the real record's O-001, and I also checked the same ID observed on the other gate.
- **Where:** scripts/verification-lib.sh:1054, scripts/verification-lib.sh:1057, scripts/verification-lib.sh:1103, scripts/verification-lib.sh:1232, scripts/verification-lib.sh:1253, tests/test-gate-contracts.sh:560, tests/test-gate-contracts.sh:568, tests/test-gate-contracts.sh:1412
- **Reproduced:** `spec-gate.sh tally` on 003 prints `severity-downgrades=5`, and the five emitted `downgrade` records are exactly O-001 in round 1, O-002 in rounds 6-8 and O-010 in round 7. 002 prints 0. The manifest-then-round fixture, the cross-gate fixture and the two-clause dispatcher fixture all pass in my run. Their recorded kills M12-M16 isolate them.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** Nothing remains wrong. The metric is now the guard's own computation, one record per observation the guard judged lowered, per gate, and no second fold exists to drift.
- **Class-wide fix:** Closed. Keep the three fixtures.

### Escalation

Round 10 re-litigates nothing that is closed, and it credits both repairs as resolved. The one blocking defect is new. It sits in the test guard T030o39 re-scoped, but it comes from content normalization that predates that repair. My reading is that the SPEC is not wrong. REQ-009's bookkeeping exemption and AC-020's no-stale-PASS rule are consistent: together they require every reuse-checked command to depend only on bytes the identity hashes, and the kit's own guard is the one reader that does not. The implementation approach needs no rework. The fix is one normalization call plus NUL enumeration in the guard, with fixtures. The trigger is narrow, a flagged sentence in an Evidence or frontmatter line, and hosted CI re-runs fresh. The user may therefore choose between repairing it, which I recommend because the next write of that shape is the T030 tick and reality-check round 2 is planned to reuse this floor, and a signed waiver in STATUS Decisions. The user arbitrates.

### Held up / follow-up tasks

These surfaces held. T030o39's path anchoring held against every spelling, case, link and layout I built, as recorded under O-013. T030o40's single computation held: its count on the real record is 5 for 003 and 0 for 002, and its catalog records are inert to every non-tally consumer. The AC-023 analyzer loop held under checkbox, Evidence and phase edits to 002, with the manifest unchanged and 18/18 at exit 0. The round-10 authorization and the round-11 refusal reproduce. The floor's captures are current for the live source.

One isolation gap is non-blocking, because the rule is conservative and deleting it is arguably benign. Removing the layout restriction in `vf_bookkeeping_anchor`, the `[[ "$own" =~ ^\.specify/specs/[^/]+$ ]] || own=''` clause at `scripts/verification-lib.sh:1371`, survives all of `tests/test-verification.sh` at exit 0, 3/3. So the Decisions rule that an in-repository spec outside `.specify/specs/<name>` gets an empty anchor, which is the deny-side direction, is pinned by no fixture. The file was restored and matches the live worktree under `cmp`.

Proposed follow-up:
- T030o41, for O-015. Scan the semantic content in `superseded_environment_scan` at `tests/test-gate-contracts.sh:42-99`: NUL enumeration, `vf_semantic_file` per path, and failure on a git error. Add fixtures proving that an Evidence-line claim and a `status:`/`updated:`-line claim are neither reported nor identity-changing, while a body claim and a claim in a git-quoted filename are both reported. If the anchor rule is to stay, add a fixture for an in-repository spec outside `.specify/specs/<name>`.
<!-- gate-round-end: opponent:10 -->
