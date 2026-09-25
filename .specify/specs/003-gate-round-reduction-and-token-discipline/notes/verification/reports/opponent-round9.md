## Round 9

**Round:** 9
**Timestamp:** 2026-09-23T00:11:31Z
**Source:** aa18111b6dbe36a6d75e923129802ffa7c688dddedc9a7ec811c350dd7bc66c4
**Floor:** FLOOR-k1reWt
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 1

### What I attacked

I derived the scope myself instead of taking it from the brief. I compared the six-field records of round 8's FLOOR-bvsiKa `inputs.nul` against a read-only snapshot of the live worktree. Exactly four path records differ: `scripts/verification-lib.sh`, `tests/test-gate-contracts.sh`, and the hashed parts of `STATUS.md` and `tasks.md`, plus the matching harness and document records. So the brief's scope claim holds. The same read-only snapshot reproduces source `aa18111b…` exactly, so the source had not moved when I finished. Against it, `vf_capture_check` accepts the floor's suite captures CAP-409-Z8jCNl (`bash tests/run.sh`) and CAP-389-mHlDcf (`bash tests/test-gate-contracts.sh`) under the `reuse` predicate at rc=0. On a copy, `spec-gate.sh waiver <spec> opponent 9` prints `authorized: opponent round 9`, and round 10 is refused at exit 4 listing seven candidates, the last one STATUS.md:329.

For T030o37 I read the production that decides the clearance check. `blockers` is computed over `Status` and `Severity` at `scripts/verification-lib.sh:1018`. The downgrade counter at :1028 reads `firsttier`, which has two writers: the manifest pass at :990 and the round pass at :1053. Both now apply the same strictest-tier rule. I attacked:
- tier order: minor→blocking→minor, blocking→minor→minor, upgrade-only, and changes within the blocking tier;
- every lifecycle status on a known ID;
- manifest-then-round interplay;
- the same ID observed on the other gate.

The guard held on every one. Its consumer `vf_tally` (:1241-1247) now folds the same way, keyed by gate and ID. On a cross-gate fixture (opponent `G-042` at `wrong-result`, reality-check `G-042` open at `degraded`) the live code correctly prints `severity-downgrades=0`. The manifest seed the guard uses is not part of that fold, however; that is Finding O-014. Against the real history: `spec-gate.sh tally` on 002 exits 0 with its asserted counts. On 003 it prints `opponent rounds=8`, `blocking=22 minor=9 locations=255 unclassified=0`, `reopened=25` and `severity-downgrades=4`, matching the Decisions entry. 001 keeps its pre-existing exit 3.

For T030o38 I walked `gate_dispatch_verbs` (`tests/test-gate-contracts.sh:1281-1324`) against the `help case` production and tried each spelling bash accepts:
- an optional leading `(`, `|` alternatives, digits and `_`, and tab indentation;
- quoted, glob, bracket, tilde and `$` patterns;
- two clauses on one line, a trailing `esac` or comment on a clause line, backslash continuation and a heredoc body;
- `;&` and `;;&` terminators, a clause after the catch-all, and a changed catch-all body;
- a second `case "$command_name" in`, and an unquoted or brace-quoted anchor.

Every one either classifies or fails closed with `AC-018: unclassifiable spec-gate.sh dispatcher clause`. In particular, bash executes `  probe) :;; probe3) echo probe3; exit 0;;` as two verbs, and the guard refuses that line by name. The one surface outside the static subset is dispatch placed outside the `case` statement, such as an `if` on `$command_name` before it. T030o38's recorded design puts that out of scope, so I mark it unexamined rather than raise it.

I ran the baseline in a git copy under `/private/tmp/opp9/work`: `bash tests/test-gate-contracts.sh` passed 14/14 at exit 0 with no `assert:` line. I then re-ran the recorded `repair-mutations.sh` from a second copy. The only changes were its temp root and two mutants appended at the end. All 19 recorded mutants are killed with their stated diagnostics, the baseline passes, and every restore is `cmp`-identical to the pre-mutation copy and to the live worktree files. Both of my additions SURVIVE their whole test functions at rc=0 with no `assert:` line:
- reverting the tally key at :1243 from `$5 SUBSEP $2` to `$2`, run against all of `test_reports_and_tally`;
- deleting the multi-clause refusal at `tests/test-gate-contracts.sh:1305`, run against all of `test_instruction_contracts`.

The code under both is correct today, so I record them under Held up as isolation gaps, not as findings.

The invoker's observation holds, and it is Finding O-013. I swept for siblings starting from the two exclusion mechanisms, not from the one example: path exclusion in `vf_bookkeeping_path`, and content normalization in `vf_semantic_file`. Every read of `$KIT_DIR/.specify/specs/*` in `tests/` lands in one of two places. One is the 002 tally at `tests/test-gate-contracts.sh:702`. The other is the AC-023 analyzer loop at `tests/test-sdd-analyze.sh:512`, which copies shipped `tasks.md` and `STATUS.md`; the identity drops their Evidence lines, checkbox state and non-Decisions sections. The analyzer sibling held. With every Evidence line removed and every checkbox cleared in 002's `tasks.md`, the manifest stays byte-identical and `bash tests/test-sdd-analyze.sh` still passes 18/18 at exit 0, because those inputs only drive warnings. The `phase:` field it reads selects the same analysis mode for review, shipped and every later lifecycle value.

For the hosted CI, the `pull_request` jobs tested merge commit 55d1325, and `notes/verification/platforms/ci-20260922/collect.sh:49` proves its tree equals snapshot tree 13b18cd7, so the Linux and Bash-5 evidence is for the reviewed bytes; that held. Its mapping step deliberately admits every bookkeeping entry unchecked, which is the same unbound dependency O-013 names.

Known-open items, confirmed rather than rediscovered:
- A round can still reach CLEARED by omitting a known open finding: unlisted IDs are never counted, and `firsttier` is consulted only for IDs the round records.
- The totals, verdict-agreement and downgrade checks at :1093-1095 are still `gate=="opponent"` only.
- README names `Verification-Return` only in a comment at :427 and shows no grammar.
- None of the four invoker documents contains the `gate-round-end` completion marker; only the two gate personas do.
- 001 still exits 3 with `duplicate identity field` at its `notes/opponent.md:59-61`.

Not reached, and therefore not cleared:
- umbrella and multi-repo `vf_gate_roots` and `vf_gate_task_repo`;
- `vf_accept_transaction` crash windows;
- `vf_matrix_prior` with a real carried reality-check round;
- the `r`-suffix follow-up branch;
- per-negative branch coverage inside the large fixtures;
- AC-014, AC-017 and AC-018 prose beyond targeted greps.

I did not run the full `tests/run.sh` or ShellCheck myself; for those I relied on the logs of CAP-409 and CAP-410 (15 suites, all passed) and on the hosted jobs. All work ran under `/private/tmp/opp9`, with TMPDIR inside it. Nothing in the worktree was created, modified, moved or removed except this report. The live worktree's `git status` digest was identical before and after my one read-only snapshot and capture check.

### Finding O-013
- **Class:** verification-input-identity
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** FLOOR-k1reWt is current at `aa18111b…`, and the floor's `bash tests/run.sh` capture CAP-409-Z8jCNl is reusable. One line of another spec's gate report then changes: `.specify/specs/002-usage-limit-handling-for-dispatched-runs/notes/opponent.md:238` goes from `*severity:* wrong-result` to `*severity:* degraded`. Adding a findings manifest under 002's `notes/verification/reports/`, or writing any floor, checkpoint or capture under 002's `notes/`, triggers the same thing. The next `spec-gate.sh floor` then runs, or the reality-check reservation that reuses this floor.
- **Where:** scripts/verification-lib.sh:1324, scripts/verification-lib.sh:1345, scripts/verification-lib.sh:1378, scripts/verification-lib.sh:1401, scripts/verification-lib.sh:1631, scripts/verification-lib.sh:2004, scripts/verification-lib.sh:2116, tests/test-gate-contracts.sh:702, tests/test-gate-contracts.sh:703, tests/test-gate-contracts.sh:704, tests/test-gate-contracts.sh:705, tests/test-gate-contracts.sh:706, tests/test-gate-contracts.sh:707, tests/test-gate-contracts.sh:711, .specify/stack.yml:15, templates/verification-contract.md:132, templates/verification-contract.md:158
- **Reproduced:** In a git copy of the worktree, `vf_snapshot` gives the same digest (`a537889f…`) before and after that one-line edit, and the two manifests are `cmp`-identical. As a control, the unedited `test_reports_and_tally`, run as one function through the harness's own eval, exits 0 with no `assert:` line. After the edit it exits 1 with `assert: output missing substring: blocking=6 minor=0`, over the output `blocking=5 minor=1 locations=8 unclassified=6`. I then restored the 002 file and verified it with `cmp`. Declaring the file under `verification_inputs:` does not help. With it declared, the edit still leaves the manifests `cmp`-identical and the path appears in no record, because `vf_path_record` returns at :1345 for any bookkeeping-patterned path, and it prints no diagnostic. On the live worktree, read-only, the current snapshot is `aa18111b…`, and `vf_capture_check` accepts CAP-409-Z8jCNl and CAP-389-mHlDcf under `reuse` at rc=0. Capture reuse (:1631) and floor currency (:2116) are both decided by that digest alone. The same edit in the live tree would therefore leave both captures reusable and the floor current, while the commands they stand for fail.
- **Root cause:** plan-gap
- **Blocks:** REQ-009, AC-020, AC-007
- **Wrong behavior:** REQ-009 requires the input identity to include "tests and fixtures", uses a conservative whole-source default, and says that unknown impact invalidates all potentially affected results. AC-020 requires that a changed input can never reuse the old success, and it names the failing-test "sound evidence" scenario. The shipped contract (`templates/verification-contract.md:132` and :158) tells a project to declare otherwise-ignored input paths, and says only narrowly documented generated bookkeeping is excluded. `vf_bookkeeping_path` at :1324 does something broader. Its `.specify/specs/*/` wildcard excludes the gate reports, captures and verification records of every spec in the repository, not only the spec being verified. `bash tests/run.sh` is a reuse check (`.specify/stack.yml:15`), and AC-010 requires it to read shipped 002's reports; `tests/test-gate-contracts.sh:702-711` asserts round, finding, class and execution counts computed from exactly those excluded files. A result that depends on those bytes is therefore certified current and reusable after they change. The one escape hatch the contract offers, declaring the input, is dropped without a word. Plan §3 step 3 lists "explicitly generated capture/report/ledger paths" without anchoring them to the spec under verification, and it does not reconcile that list with AC-010's shipped-report fixture; the code follows the plan. No current evidence is false: 002's files match HEAD, so FLOOR-k1reWt and the hosted jobs are true for today's bytes. The defect is that nothing would notice once those bytes change. Open question for the spec: REQ-009's "Bookkeeping-only edits (gate reports, …)" does not say whose reports. Read broadly, as the code reads it, it contradicts the same requirement's inclusion of fixtures, and AC-010's use of a shipped report as one.
- **Class-wide fix:** Anchor the exclusion to the spec whose floor or capture is being computed. `vf_bookkeeping_path` should take the verified spec's repo-relative directory and exclude only that spec's `.tasks.accept.*`, `notes/captures/`, `notes/verification/`, `notes/evidence.md`, `notes/opponent.md` and `notes/reality-check.md`; another spec's copies become ordinary source, which errs on the deny side. Separately, `vf_path_record` must hash a path declared in `verification_inputs:` even when it matches the bookkeeping predicate, or refuse it with a named diagnostic, but never skip it silently. Give the same anchored predicate to the manifest-complement scan at `tests/test-gate-contracts.sh:42`, so the O-010 guard's scope stays equal to the manifest's by construction. Negatives, in both directions: an edit to another spec's report, findings manifest or floor directory must change the identity and make capture reuse refuse with `capture stale: current inputs changed`; an edit to the verified spec's own report must not. The sweep here is complete for this repository: the only readers of other specs' excluded or normalized content in `tests/` are the 002 tally (affected) and the AC-023 analyzer loop (held). Project checks outside this repository that read sibling specs' notes remain unexamined.

### Finding O-014
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** degraded
- **Scenario:** A declared prior-review manifest records a finding at a blocking tier, and a later round records the same ID, not resolved, at `minor` or `degraded`. This spec's real record has that shape. `notes/verification/reports/opponent-findings-2026-09-09.md:12` and :17 record O-001 at `wrong-result`, and round 1 re-records O-001 as `reopened` at `minor`.
- **Where:** scripts/verification-lib.sh:1223, scripts/verification-lib.sh:1241, scripts/verification-lib.sh:1243, scripts/verification-lib.sh:1245, scripts/verification-lib.sh:990, scripts/verification-lib.sh:1028
- **Reproduced:** I built a minimal fixture against the live library. The manifest records `G-042` at `wrong-result`, and round 1 records `G-042` as `reopened` at `minor`. With the round CLEARED, `vf_reports` exits 3 with `clearing verdict rests on 1 lowered severity tier(s) of known findings`, so the guard counts the observation as a downgrade. When the same round is made legal as CHALLENGED, with one other blocking finding, it exits 0, and `spec-gate.sh tally` on it prints `severity-downgrades=0`. On the real record, `spec-gate.sh tally` on 003 prints `severity-downgrades=4`: O-002 in rounds 6, 7 and 8, and O-010 in round 7. Replaying the guard's own manifest-seeded fold over the same observations gives 5; the fifth is O-001 in round 1.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** Round 8's O-004 asked for `vf_tally` to use the guard's rule "so the metric and the guard cannot disagree". T030o37's acceptance narrowed that to "canonical round observations". The rows at :1223 carry only round findings, so the fold at :1243-1245 never sees the manifest tier that :990 seeds into `firsttier` for the guard at :1028. The two measures of "a lowered tier of a known finding" therefore still disagree, and on this spec's real history the metric under-reports by one. It is degraded rather than blocking because the count decides no gate, and no AC or template names it.
- **Class-wide fix:** Seed the tally's fold, per gate, from the same manifest records `vf_reports` reads, so that the guard and the metric are one computation. Add two fixtures. In the first, a manifest tier followed by a lower round tier must yield `severity-downgrades=1`. The second is a cross-gate same-ID fixture pinning the gate key at :1243, which no current fixture does (see Held up).

### Finding O-004
- **Class:** gate-report-schema-validation
- **Status:** resolved
- **Prior:** O-004
- **Severity:** wrong-result
- **Scenario:** The round-8 attack is one ID recorded `degraded`, then `wrong-result` (an honest escalation), then `degraded` again, under CLEARED with zero blockers. I also built every other order, status and manifest combination I could, including repeated downgrades, a blocking manifest tier followed by minor rounds, and resolved-then-reopened sequences.
- **Where:** scripts/verification-lib.sh:1053, scripts/verification-lib.sh:990, scripts/verification-lib.sh:1028, scripts/verification-lib.sh:1095, scripts/verification-lib.sh:1245, tests/test-gate-contracts.sh:478, tests/test-gate-contracts.sh:493
- **Reproduced:** The round-8 attack now exits 3 with `clearing verdict rests on 1 lowered severity tier(s) of known findings`. My re-run kills `round-first`, `round-last`, `round-all-blocking`, `manifest-first`, `tally-first`, `tally-last`, `tally-all-blocking` and `forbid-recharacterisation`, each with its stated assertion; the last one proves that an honest re-characterisation in a non-clearing round stays legal. History is unchanged: 002's tally exits 0 with its asserted counts, and 003's reports `opponent rounds=8 blocking=22 minor=9 severity-downgrades=4`.
- **Root cause:** implementation-error
- **Blocks:** REQ-011, REQ-010, AC-012
- **Wrong behavior:** Nothing remains wrong for the round-8 subject. Both writers of `firsttier` now keep the strictest recorded tier, so a still-open defect the gate recorded at a blocking tier can no longer be tallied as a minor to buy CLEARED, whatever order its tiers were recorded in. The rest of the class is recorded elsewhere: omission remains known open at the spec level, and the metric seed is O-014.
- **Class-wide fix:** Closed for this member; keep the order-varying fixtures. The residual metric divergence is carried by O-014, and the gate key's missing fixture is listed under Held up.

### Finding O-002
- **Class:** round-authorization-grammar
- **Status:** resolved
- **Prior:** O-002
- **Severity:** degraded
- **Scenario:** The round-8 attack adds an undocumented subcommand whose clause is written `  (probe)`, `  probe2)` or, tab-indented, `(probe_2 | probe-alias)`. On top of those I tried two clauses on one line, quoted, glob, tilde and expansion patterns, a trailing `esac` or comment on a clause line, a clause after the catch-all, and a second dispatcher `case`.
- **Where:** tests/test-gate-contracts.sh:1281, tests/test-gate-contracts.sh:1305, tests/test-gate-contracts.sh:1326, tests/test-gate-contracts.sh:1351, tests/test-gate-contracts.sh:1369, scripts/spec-gate.sh:19
- **Reproduced:** My re-run kills `cli-old-reader`, `cli-no-open-paren`, `cli-narrow-verbs`, `cli-silent-clause`, `cli-no-pattern-check`, `cli-no-catchall-check`, `cli-no-synopsis`, `cli-no-detail` and `cli-no-readme`, each with its named AC-018 diagnostic. The two-clause line, which bash executes as two verbs, is refused with `AC-018: unclassifiable spec-gate.sh dispatcher clause at line 26` of the mutated copy. The live dispatcher derives `round checkpoint floor accept tally waiver`, and all six verbs are documented.
- **Root cause:** implementation-error
- **Blocks:** AC-018, REQ-016
- **Wrong behavior:** Nothing remains wrong for the round-8 subject. Every line inside the dispatcher either classifies or fails closed, so an undocumented verb can no longer vanish silently from the documentation obligation.
- **Class-wide fix:** Closed within the declared static subset. Dispatch written outside the `case` statement is outside that subset by design and stays unexamined. The multi-clause refusal has no killing fixture (see Held up).

### Escalation

Round 9 re-litigates nothing closed, and it credits both round-8 repairs as resolved. The one blocking defect is new. It lies on the surface the invoker flagged, and it sits on code unchanged since round 8: the bookkeeping predicate is not in the round-8→9 diff. My reading is that the SPEC is ambiguous in one clause but not wrong. REQ-009 lists "gate reports" as bookkeeping without saying whose. Yet the same requirement, together with AC-020 and AC-010, makes a shipped spec's gate report a test fixture, and a changed fixture must invalidate reuse. The implementation took the broad reading. The fix is an anchoring decision the plan can make without a spec revision, since the contract template already speaks of "the spec's own bookkeeping". The user can record that reading in Decisions instead of revising REQ-009. I do not recommend a waiver on O-013. A reused PASS made false by a byte change is exactly what REQ-009 and AC-020 exist to prevent, and reality-check round 2 is planned to reuse this very floor. Closing it costs one predicate parameter, one declared-input rule and their negatives. The user arbitrates.

### Held up / follow-up tasks

These surfaces were attacked and held; the reason for each is given. The T030o37 guard holds in every order, status and manifest combination I built, and all eight of its recorded mutants are killed. Its tally fold is correctly keyed by gate and ID on live code. The D1 repair is isolated in both directions: `d1-no-collapse` and `d1-no-negation` are both killed, so the round-8 D1 isolation gap is closed. The T030o38 static reader holds across the whole `help case` production I could spell, all nine of its recorded mutants are killed, and the unquoted-anchor and second-dispatcher cases fail closed. The hosted CI evidence tested the reviewed tree. The round-9 authorization and the round-10 refusal reproduce. The shipped-spec analyzer sibling of O-013 does not flip under the edits the identity normalizes away.

There are two isolation gaps, both non-blocking because the code under them is correct today. First, the gate key at `scripts/verification-lib.sh:1243`, which T030o37's acceptance names, is asserted by no fixture: the only `severity-downgrades` assertions, at `tests/test-gate-contracts.sh:511` and :522, run over opponent-only reports, and reverting the key to the ID alone survives all of `test_reports_and_tally`. Second, the multi-clause refusal at `tests/test-gate-contracts.sh:1305`, a dimension T030o38's acceptance says to mutate, is exercised by no fixture: deleting it survives all of `test_instruction_contracts`, and it would then silently drop the second verb of `  probe) :;; probe3) …;;`.

Proposed follow-ups:
- T030o39, for O-013: anchor `vf_bookkeeping_path` to the verified spec's directory at `scripts/verification-lib.sh:1324`, and make `vf_path_record` at :1345 hash a declared `verification_inputs:` path or refuse it by name instead of skipping it. Move the O-010 scan's scope at `tests/test-gate-contracts.sh:42` to the same predicate. Add both-direction negatives: another spec's report, findings manifest or floor directory changes the identity and refuses reuse, while the verified spec's own report does not. Re-derive the 002 tally assertions at :702-711 against the new identity.
- T030o40, for O-014 and the two isolation gaps: seed `vf_tally`'s fold at :1241-1247 from the per-gate manifest records `vf_reports` reads. Add a manifest-then-round downgrade fixture, a cross-gate same-ID fixture that kills the ID-only key, and a two-clauses-on-one-line dispatcher fixture that kills deletion of :1305.

<!-- gate-round-end: opponent:9 -->
