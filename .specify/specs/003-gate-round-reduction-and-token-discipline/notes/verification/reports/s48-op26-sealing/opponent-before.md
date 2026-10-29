
## Round 1
**Round:** 1
**Timestamp:** 2026-09-10T16:07:07Z
**Source:** 0591655f55ed9eae4284dead0435b1c1ce8de1e2f545b97ab554962d9f377e93
**Floor:** FLOOR-JKSuM0
**Verdict:** CHALLENGED
**Blocking:** 5 · **Minor:** 1

### What I attacked

I treated the six T030o1-T030o6 repairs and their new fixtures as the primary
attack surface, on the theory that a fix written to close one reported site
usually leaves its siblings open. For each prior class I re-derived the guard
from source and then built an isolated fixture under TMPDIR that satisfies the
new check while defeating its purpose. Reproduced by direct function calls in
throwaway sandboxes (never inside the worktree, no gate/accept/floor/round
mutation): vf_config on six candidate expansion spellings; vf_reports on a
CLEARED report with bare required headings, with those headings placed after
the completion marker, and with a data-loss finding neutralised by
Status: resolved; vf_round_authorized against a STATUS Decisions log whose only
authorization text sits inside a code fence and is explicitly described as
revoked; vf_return_parse on five envelope shapes (clean, trailing narrative,
leading narrative, narrative starting with an FM- token, narrative inside the
Failure modes section); vf_report_block plus vf_reports on a two-round file to
model what round 2 completion does to round 1's sealed digest.

Read in full and traced for consumers: scripts/verification-lib.sh (every
function; vf_bindings, vf_snapshot, vf_capture, vf_capture_check,
vf_return_check, vf_accept_transaction, vf_gate_execute, vf_gate_floor,
vf_gate_checkpoint, vf_completed_coverage, vf_gate_round, vf_reality_matrix,
vf_matrix_prior read line by line), scripts/spec-gate.sh, the changed
--summary/--no-tick/--from-task path in scripts/spec-run.sh, the accept seam in
scripts/spec-task.sh, tests/probe-gate-contract.sh, tests/helpers.sh, spec.md,
plan section 4.2 and the round-authorization grammar, tasks.md, the dossier and
the 2026-09-09 provisional report. Cross-checked the assertion text (not just
the presence) of the new negatives in tests/test-verification.sh,
tests/test-gate-contracts.sh, tests/test-spec-gate.sh and tests/test-spec-task.sh
for each prior class, which is how the O-004 and O-005 gaps surfaced: those
suites delete a heading or enumerate dollar-forms and assert nothing beyond
that. Confirmed against production state that ACCEPT-KsToLg really does record
reason "return: missing, extra, duplicate or unknown FM/INV test binding", so
the live AC-016 observation itself is the correct control even though its
checker cannot tell that class apart from a formatting slip. Read
FLOOR-JKSuM0/commands.nul in full to confirm which checks executed (3 checkers
plus shellcheck) versus reused, and .specify/stack.yml to see which commands
opt into reuse.

Attacked and held (below, under Held up). Searched at bounded depth without
establishing a blocker: vf_snapshot input coverage including the bookkeeping
exclusion list, vf_semantic_file normalisation, the superseded-failed-run scan,
vf_lock/vf_seal/vf_publish crash windows, the accept transaction's
prepared/committed reconciliation, vf_matrix_prior carrying rules, and
vf_summary output bounds.

Not examined, and therefore not cleared: I did not re-execute tests/run.sh,
tests/test-verification.sh, tests/test-gate-contracts.sh or
tests/test-spec-gate.sh in this round; I reused FLOOR-JKSuM0's sealed captures
for suite status, as the dossier permits. I did not read the roughly 3,000 diff
lines of authoring templates, stack overlays, expert personas, README and
constitution prose beyond targeted greps for the documented command grammar and
the waiver grammar, so AC-002, AC-014, AC-017 and AC-018 text surfaces are
largely unexamined by me. I did not exercise the umbrella/multi-repo branches of
vf_gate_roots or vf_gate_task_repo, Linux or GitHub-hosted CI behaviour, the
checkpoint lost-binding delta against a real prior CHECKPOINT, or per-negative
branch coverage inside the large fixtures. No claim of an exhaustive sweep.

### Finding O-001
- **Class:** return-envelope-parsing
- **Status:** reopened
- **Prior:** O-001
- **Severity:** minor
- **Scenario:** A worker appends a permitted narrative line that happens to begin with an FM or INV token after a complete envelope, e.g. the single trailing line "FM-002 was excluded for this task; see plan 4.2." following a valid Task/Captures/Summary/Failure modes block with two correct mapping rows.
- **Where:** scripts/verification-lib.sh:1330, scripts/verification-lib.sh:1331
- **Reproduced:** In the sandbox, vf_return_parse on that file exited 3 with "return: unexpected field or malformed mapping", while the same file with the narrative reworded ("All requested verification is complete.") parsed with mappings=2. The end-of-block rule only ends the section on a line that does not start with FM- or INV-, so trailing prose starting with either token falls through to the catch-all error.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Plan section 4.2 permits surrounding narrative unconditionally, and the accepted T030o1 fix promised to cover both sides of the block; a narrative sentence that opens with an FM or INV identifier is still refused, so the worker's return must be reworded before it can be accepted. It fails closed and never mis-ticks, which is why this is minor rather than blocking.
- **Class-wide fix:** Terminate the envelope on an explicit end marker or on the first line that is neither a well-formed mapping nor a recognised field, and treat a malformed FM/INV row as an error only while the section is still open; add trailing-narrative fixtures whose first token is FM- and INV-. The only runtime consumer of this parser is vf_return_check at scripts/verification-lib.sh:1347; no other envelope parser exists in the tree.

### Finding O-002
- **Class:** round-authorization-grammar
- **Status:** reopened
- **Prior:** O-002
- **Severity:** wrong-result
- **Scenario:** STATUS.md records, under its Decisions section, a prose bullet saying an authorization was revoked and then reproduces the revoked text verbatim inside a fenced block: a line reading "- 2026-09-09T10:00:00Z — waiver: gate=opponent; round=4; after=3; by=some-user; reason=revoked, kept for the record". No live authorization exists.
- **Reproduced:** In the sandbox, vf_round_authorized on that STATUS.md for gate opponent, round 4, previous 2026-09-08T00:00:00Z returned 0, so vf_gate_round would reserve round 4. The authorization matcher has no fence or blockquote state at all, unlike its three sibling parsers in the same file (scripts/verification-lib.sh:798, :1866, :2047) which all skip fenced and quoted content.
- **Where:** scripts/verification-lib.sh:1904, scripts/verification-lib.sh:1905
- **Root cause:** implementation-error
- **Blocks:** REQ-012, AC-009
- **Wrong behavior:** REQ-012 requires an explicit in-force user authorization naming the gate and exact round, and AC-009 already establishes for the same requirement that quoted content must not affect round bookkeeping ("Quoted headings do not add rounds"). Here illustrative, superseded or explicitly revoked text lifts the round cap that REQ-012 exists to enforce, and the whole-line anchoring added by T030o2 does not help because the quoted line is byte-identical to a real one.
- **Class-wide fix:** Give the authorization scanner the same fence and blockquote suppression the report and config parsers use, so only unquoted Decisions bullets are authorizations, and add fenced, tilde-fenced, indented-code and blockquoted negatives for both the waiver and spec-revision branches. Both branches share this one parser; vf_semantic_file at scripts/verification-lib.sh:987 selects the same Decisions section for the input manifest and should use the same suppression so the two views cannot disagree.

### Finding O-003
- **Class:** live-control-semantic-validation
- **Status:** reopened
- **Prior:** O-003
- **Severity:** wrong-result
- **Scenario:** A worker return carries a complete and correct mapping but puts one explanatory sentence between the "Failure modes:" line and the rows, e.g. "The rows below map every required row." followed by the two correct FM-001 and INV-001 rows.
- **Reproduced:** In the sandbox, vf_return_parse accepted that file with mappings=0 - both complete rows were silently discarded - and the parsed record set contained only task, captures and summary. vf_return_check then fails at scripts/verification-lib.sh:1372 with "return: required Failure modes are missing", which vf_reject_class maps to binding-mismatch, which is exactly the class tests/probe-gate-contract.sh:41 requires as proof that the AC-016 deliberately-incomplete-copy control ran.
- **Where:** scripts/verification-lib.sh:1330, scripts/verification-lib.sh:1372, scripts/verification-lib.sh:1449, scripts/verification-lib.sh:1450, tests/probe-gate-contract.sh:41
- **Root cause:** implementation-error
- **Blocks:** AC-016, REQ-006
- **Wrong behavior:** T030o3 typed the rejection so the live checker could require the specific control AC-016 names, but binding-mismatch still covers three different message groups including one produced by a return whose FM/INV mapping is complete. A formatting slip therefore satisfies the live wiring assertion, so the promised real observation can again be a false positive. The rejection message is also wrong on its own terms: it reports required rows as missing when they were present in the return and dropped by the parser. I verified that this spec's actual control, ACCEPT-KsToLg, records "missing, extra, duplicate or unknown FM/INV test binding", so the current live evidence is the right control; the defect is that the checker cannot establish that.
- **Class-wide fix:** Split the binding-mismatch arm into distinct classes for a missing or extra required row versus a truncated or malformed envelope, require the row-level class in the probe, and stop discarding rows after the section opens (see O-001). Sibling sweep: the same coarse mapping affects the stale-capture arm, which folds capture-integrity forgery in with staleness at scripts/verification-lib.sh:1453 to :1455; I did not build a fixture for that arm, so its extent is unexamined.

### Finding O-004
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-004
- **Severity:** wrong-result
- **Scenario:** Two independent shapes. First, a canonical CLEARED opponent report that carries the headings "### What I attacked" and "### Held up / follow-up tasks" with no body under either, or with both headings placed after the gate-round-end marker. Second, a CLEARED report whose one finding is a brand-new data-loss defect recorded as Status: resolved with Prior: none.
- **Reproduced:** In the sandbox, vf_reports exited 0 on the bare-heading report (catalog bytes=140), exited 0 on the variant whose two required headings appear after the completion marker, and exited 0 on the CLEARED report containing the unreferenced data-loss finding marked resolved. The section predicate at scripts/verification-lib.sh:778 only asks whether a heading with that lowercased text was seen anywhere in the round, the heading rule at :833 records it with no ended guard, and the counting rule at :770 skips any finding whose Status is resolved without checking that Prior names an earlier finding.
- **Where:** scripts/verification-lib.sh:770, scripts/verification-lib.sh:778, scripts/verification-lib.sh:788, scripts/verification-lib.sh:789, scripts/verification-lib.sh:833, tests/test-gate-contracts.sh:229, tests/test-gate-contracts.sh:231, tests/test-gate-contracts.sh:250
- **Root cause:** implementation-error
- **Blocks:** REQ-010, REQ-011, REQ-012, AC-012
- **Wrong behavior:** The wrong behavior O-004 named is unchanged: round --complete still canonises a clearance that supplies no attack, sibling or unexamined-scope record, now needing only a heading token. The T030o4 fixtures at tests/test-gate-contracts.sh:229 and :231 delete the heading line and assert the resulting message, so they pass while the empty-section and after-marker shapes go untested. The resolved-status path additionally lets a report keep a blocking finding's full text and still report zero blockers, which REQ-011 requires the counts to reflect.
- **Class-wide fix:** Require each named section to contain at least one non-blank, non-heading line, require it to appear before the completion marker, and reject Status: resolved when Prior is none or names no finding recorded in an earlier round of that gate; add omission negatives for empty body, after-marker placement and unreferenced resolved status for both gates' section sets. The four reality-check sections at :789 share the same predicate and are affected identically; I did not build reality-check fixtures for them.

### Finding O-005
- **Class:** config-interpolation-validation
- **Status:** reopened
- **Prior:** O-005
- **Severity:** wrong-result
- **Scenario:** A project declares a gate_checks or checkpoints scalar containing backtick command substitution rather than a dollar form, for example 'test `date -u +%Y` = 2026' or 'echo `id -un`', and opts the same string into reuse_checks.
- **Reproduced:** In the sandbox, vf_config accepted the backtick scalar (rc=0, command retained verbatim in commands.nul) and also accepted 'ls ~/private' and 'echo {a,b}', while rejecting 'awk "{print $1}" f' as expected. Running the accepted string the way vf_gate_execute does, bash -o pipefail -c 'test `date -u +%Y` = 2026', exits 0 today and nonzero in any other year, so the declared check is not executed literally. The recorded check identity hashes argv, shell, repo, cwd and policy only, so it is identical whatever the substitution yields.
- **Where:** scripts/verification-lib.sh:91, scripts/verification-lib.sh:1662, scripts/verification-lib.sh:1828, tests/test-verification.sh:78, tests/test-verification.sh:94
- **Root cause:** implementation-error
- **Blocks:** AC-011, REQ-007, REQ-008, REQ-009
- **Wrong behavior:** templates/verification-contract.md:92 says interpolation is rejected with file:line diagnostics, and the guard's own comment at scripts/verification-lib.sh:87 claims it covers "every unescaped expansion Bash would perform at execution time, not just the named ones". It covers only dollar forms. Backticks are the other spelling of command substitution, so an invocation-context-dependent or time-dependent command passes configuration validation, executes at floor and checkpoint time, and can then be reused under a local policy whose identity does not record what actually ran - which is precisely what REQ-009 forbids for time-dependent checks. The T030o5 negative list at tests/test-verification.sh:78 to :94 enumerates exactly the dollar forms the prior finding named and nothing else, so the class sweep it promised did not happen.
- **Class-wide fix:** Reject unescaped backtick command substitution across every configuration scalar, decide explicitly whether tilde and brace expansion are permitted and enforce that decision, and state the enforced set in templates/verification-contract.md; add backtick, nested-backtick, tilde and brace negatives plus a positive case proving a literal regex end anchor such as 'grep -c "^ok$" f' still parses. One shared scalar function serves gate_checks, checkpoints, reuse_checks, verification_tools and verification_inputs; the executed consumers are the three vf_gate_execute call sites listed above. verification_inputs and verification_tools are affected only as literal path or tool names, which fail later with a missing-input or missing-tool error.

### Finding O-006
- **Class:** post-pr-followup-binding-schema
- **Status:** resolved
- **Prior:** O-006
- **Severity:** regression
- **Scenario:** /sdd:review turns a red CI check or an actionable review comment into a Ship-stage T###c1 or T###r1 follow-up and then runs the instructed no-tick capture and deterministic acceptance.
- **Reproduced:** skills/sdd-review/SKILL.md:29 to :37 now prescribes the full typed shape for c-tasks (Files, Acceptance, Verify kind, Tests registered in plan section 7, Verify, Refs) and :46 to :48 requires the same shape for r-tasks, explicitly noting that a three-field task cannot produce a --from-task capture. tests/test-spec-gate.sh:92 to :107 builds a real T011c1 with that shape and drives it through spec-run.sh --from-task --no-tick --summary and spec-gate.sh accept to a ticked checkbox. The follow-up suffix class at scripts/verification-lib.sh:635 still covers both c and r.
- **Where:** skills/sdd-review/SKILL.md:30, skills/sdd-review/SKILL.md:46, tests/test-spec-gate.sh:100, tests/test-spec-gate.sh:105
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Previously the documented post-PR workflow produced an untyped task that could neither be captured nor accepted, stalling CI and review fixes before re-gating. Both creation branches now carry the typed binding and an end-to-end fixture proves capture plus acceptance, so the observed behavior now matches REQ-005 and REQ-006.
- **Class-wide fix:** Already applied at both known sites. Remaining unexamined extent: I checked only the c-suffix end-to-end fixture; there is no equivalent executable r-suffix capture/accept fixture, so the r branch is proven by instruction text plus the shared validator rather than by execution.

### Finding O-007
- **Class:** round-block-attribution
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** Round 1 is completed and sealed. The round 2 report handed to spec-gate.sh round --complete begins with one benign prose line before its "## Round 2" heading, for example "Here is my report for round 2." - anything other than the heading itself.
- **Reproduced:** In the sandbox, vf_reports accepted the combined two-round file (rc=0), so completion would seal round 2 and replace notes/opponent.md. But vf_report_block for round 1 changed from ccc2ca4a46e88ecc155899a37d811ef0872c2d4cdc2647cf9c14eea3607a6a52 to 6fafa30336e76fea31d13fb6df94603c7a1f321e2e9168434af1c1a2a0c61ad3, because the accumulator at scripts/verification-lib.sh:1865 keeps every line until the next round heading and so absorbs the preamble into round 1. From then on vf_round_history fails at scripts/verification-lib.sh:1882 with "round recovery: completed report digest changed; reconcile report/ledger".
- **Where:** scripts/verification-lib.sh:1865, scripts/verification-lib.sh:1882, scripts/verification-lib.sh:1997, scripts/verification-lib.sh:2015, scripts/verification-lib.sh:2016
- **Root cause:** implementation-error
- **Blocks:** REQ-012, AC-009, AC-016
- **Wrong behavior:** vf_reports and vf_report_block disagree about what belongs to a round: vf_reports ignores unrecognised prose, vf_report_block attributes it to the preceding round. Completion therefore succeeds silently and corrupts an already-sealed identity. Because vf_round_history runs first in every mode of vf_gate_round (scripts/verification-lib.sh:1945) and in the probe (tests/probe-gate-contract.sh:53), every later reserve, complete and reconcile call and the AC-016 probe exit 3, and the --reconcile branch cannot help because it only handles legacy date-only history. REQ-012 demands that malformed records fail closed with a named recovery action; the named action here has no scripted path, so the operator must hand-edit sealed gate state. Round 1 in this file is unaffected; the defect fires the first time a round 2 report carries anything ahead of its heading.
- **Class-wide fix:** Stop accumulation at the gate-round-end marker in vf_report_block, or reject any non-blank line that falls outside every round in vf_reports; and in vf_gate_round re-verify every previously sealed round digest against the combined file before the mv at scripts/verification-lib.sh:2015, so an attribution shift fails the completion instead of wedging the next invocation. Provide a scripted reconciliation for a digest mismatch that does not require editing sealed ledgers. Sibling sites reading the same accumulator: vf_matrix_prior at scripts/verification-lib.sh:2116 compares a prior reality-check block against the same sealed digest and inherits the same failure, and tests/test-gate-contracts.sh:336 seals a block the same way; I did not build a reality-check carry fixture for it.

### Held up / follow-up tasks

Attacked and held, with the reason each held:

- Acceptance transaction and idempotence (scripts/verification-lib.sh:1472). I traced every crash window between vf_publish, the tasks.md rename and the COMMITTED write. Both interrupted states are distinguishable by comparing the current tasks.md digest against the prepared before and after digests, the pending transaction is revalidated rather than replayed, and a concurrent edit is caught by the second before-comparison before sealing. The whole path is under one non-nestable lock.
- Capture freshness and the failing-test scenario from the spec's section 1. vf_capture_check requires exit 0, before equal to after, before equal to a freshly computed manifest, an argv/shell/repo/cwd identity rehash, and a scan for any later failed run with the same check and inputs. I could not construct a way to make a stale or failed capture read as current without breaking a sealed COMPLETE.
- Bookkeeping exclusion. vf_bookkeeping_path excludes only generated paths, and vf_semantic_file normalises the checkbox column and Evidence lines rather than whole files, so ticking a task does not invalidate unchanged code while a real task-text or Verify change does.
- Reality-check carrying. vf_matrix_prior requires the prior round's sealed report digest, an identical criterion digest, identical evidence and impact cells, an identical whole-source identity, and a local capture policy, which is strictly conservative.
- Report identity binding at completion. Source, floor and a not-before-reservation timestamp are all compared against the sealed reservation, and the floor is revalidated, so a report cannot be attached to a different source or floor.

Proposed follow-ups, one per class, with all known locations:

- T030o7 — Give the round-authorization scanner fence and blockquote suppression and add quoted-authorization negatives for both branches. Locations: scripts/verification-lib.sh:1904, :1905, and :987 for the matching manifest view. (O-002)
- T030o8 — Split the rejection classes so a row-level binding mismatch is distinguishable from a truncated envelope, require the row-level class in the probe, and stop discarding mapping rows once the section opens. Locations: scripts/verification-lib.sh:1330, :1372, :1449, :1450, :1453 to :1455, tests/probe-gate-contract.sh:41. (O-003, and the fix also closes O-001)
- T030o9 — Require non-empty, pre-marker content for every named report section and reject an unreferenced resolved status; add empty-body, after-marker and resolved/none negatives for both gates. Locations: scripts/verification-lib.sh:770, :778, :788, :789, :833, tests/test-gate-contracts.sh:229, :231, :250. (O-004)
- T030o10 — Close the configuration expansion grammar on backtick command substitution, decide and enforce the tilde and brace cases, restate the enforced set in templates/verification-contract.md, and add the negatives plus a literal-end-anchor positive. Locations: scripts/verification-lib.sh:91, tests/test-verification.sh:78 to :94, templates/verification-contract.md:92. (O-005)
- T030o11 — Make round-block attribution and report validation agree, re-verify sealed prior digests before publishing a completion, and provide a scripted recovery for a digest mismatch. Locations: scripts/verification-lib.sh:1865, :1882, :1997, :2015, :2016, :2116, tests/test-gate-contracts.sh:336. (O-007)
- T030o12 — Accept permitted trailing narrative whose first token is FM- or INV-. Locations: scripts/verification-lib.sh:1330, :1331. Folded into T030o8 if that fix delimits the envelope explicitly. (O-001)

O-006 is resolved and needs no follow-up; its only remaining gap is the absent
executable r-suffix capture and acceptance fixture, which is not blocking.
<!-- gate-round-end: opponent:1 -->

## Round 2
**Round:** 2
**Timestamp:** 2026-09-11T13:29:00Z
**Source:** a01fdd9e8000833c5fc225ef7f659c4cdc53e6716eb6ab61bebf2b808609ccff
**Floor:** FLOOR-pODF4T
**Verdict:** CHALLENGED
**Blocking:** 3 · **Minor:** 2

### What I attacked

I confirmed the dossier is current before grading: the live `git diff main -- . ':!…/notes'` hashes to `c475764a…`, byte-identical to `notes/verification/dossier/source.diff`. I then took the five round-1 classes and the repairs T030o7–T030o12 as the primary surface, on the theory that a class-wide claim is only as wide as the enumeration it was written against. For each prior class I re-derived the guard from source, ran the invoker's preserved probe (`cases=20 mismatches=0`, all twelve controls unchanged), and then built inputs the enumeration does not name, in throwaway sandboxes under TMPDIR by direct library calls — no gate, floor, round, accept, ledger, capture or tasks mutation anywhere, and no tracked file touched. Reproduced this round: `vf_round_authorized` on HTML-commented, `<details>`-wrapped and `## Decisions we rejected` authorizations; `sdd-analyze.sh` on an HTML-commented task block against the shipped fenced-task-block control; `vf_matrix_parse` on plain/fenced/HTML-commented AC rows; `vf_config` on process substitution in both directions beside the backtick, dollar and tilde controls; `vf_reports` and `spec-gate.sh tally` on a `Status: resolved` finding with a fabricated `Prior`; `vf_reports`/`vf_report_block` on three round-2 preamble shapes against the sealed `1ac95178…`; `vf_return_parse` on trailing `FM-` narrative and on prose between `Failure modes:` and the rows; `spec-run.sh --summary --no-tick` on four verbose success/failure shapes in a throwaway git repo.

Read line by line and traced for consumers: the new `_VF_AWK_FENCE`/`vf_fence`/`vf_indented` tracker and all six of its call sites (`vf_config` :91, plan tables :436–:444, `vf_bindings` inventory :527 and field pass :720, `vf_reports` :861, `vf_report_block` :1956, `vf_round_authorized` :2002, `vf_matrix_parse` :2155 — seven call sites, one more than the preamble's six), the whole of `vf_reports` including the new `secbody`/`need()`/resolved-status rules, `vf_round_history`, the `--complete` branch and its new belt-and-braces prior-digest loop, `vf_return_parse`/`vf_return_check`/`vf_reject_class`, `vf_summary`, `vf_capture`, `vf_semantic_file`, `vf_ac_catalog`, `vf_reality_matrix`, `vf_completed_coverage`, `vf_gate_roots`, `vf_gate_execute`, `tests/probe-gate-contract.sh`. I inspected the actual assertions (not the presence) of `tests/test-gate-contracts.sh:229`–`:289`, `tests/test-sdd-analyze.sh:250`–`:294`, `tests/test-verification.sh:60`–`:120` for every prior class; that is how O-004 and O-005 surfaced again — `tests/test-gate-contracts.sh:286`–`:289` certifies the fabricated-`Prior` shape as legitimate, and `tests/test-verification.sh:95`–`:101` enumerates exactly the spellings the prior finding named. I also checked the asymmetry the dossier asks about: `vf_ac_catalog` and `vf_semantic_file` not suppressing is deny-side in both directions I could construct (a quoted AC adds an obligation or trips `duplicate AC definition`; a fenced Decisions edit still changes the manifest), so I do not challenge it.

Previously unexamined surfaces I did examine and did not break: AC-002's overlay set — all fourteen shipped overlays carry a `## Failure-mode and checkpoint defaults` section with exactly three categorized scenarios and the stage-vs-`gate_checks` distinction, and `tests/test-gate-contracts.sh:102` enumerates the directory rather than a hard-coded list; AC-021's bounds, measured rather than asserted (success 531 and 870 bytes, 1 line; failure 2439 and 7023 bytes, 21 lines = summary + 20 diagnostics; real exits 7, 9, 0 preserved; checkbox unchanged); the checkpoint lost-prior-binding delta, which re-verifies each prior CHECKPOINT's integrity before differencing.

Not examined, and therefore not cleared: I did not re-execute `tests/run.sh`, ShellCheck or any suite this round — I reused FLOOR-pODF4T's sealed captures for suite status, as the dossier permits. I did not read the authoring templates, expert personas, README or constitution prose behind AC-014, AC-017 and AC-018 beyond targeted greps, so those text surfaces remain unexamined by me for a second round. I did not exercise the umbrella/multi-repo branches of `vf_gate_roots`/`vf_gate_task_repo` (no multi-repo fixture built), Linux or GitHub-hosted CI behaviour, the checkpoint lost-binding delta against a real prior CHECKPOINT directory, `vf_accept_transaction`'s crash windows (round 1 held them), or per-negative branch coverage inside the large fixtures. No claim of an exhaustive sweep.

### Finding O-002
- **Class:** round-authorization-grammar
- **Status:** reopened
- **Prior:** O-002
- **Severity:** wrong-result
- **Scenario:** STATUS.md records under `## Decisions log` a prose bullet saying an authorization was revoked, then reproduces the byte-identical revoked line inside an HTML comment — the ordinary markdown idiom for disabling a line — as `<!--` / `- 2026-09-10T10:00:00Z — waiver: gate=opponent; round=4; after=3; by=some-user; reason=revoked, kept for the record` / `-->`. No live authorization exists. The same quoting form defeats two sibling parsers: a whole task block wrapped in `<!-- … -->` in tasks.md becomes a real task that claims ownership of an applicable FM row, and an AC matrix row wrapped the same way parses as a live row.
- **Where:** scripts/verification-lib.sh:48, scripts/verification-lib.sh:2002, scripts/verification-lib.sh:2003, scripts/verification-lib.sh:527, scripts/verification-lib.sh:528, scripts/verification-lib.sh:720, scripts/verification-lib.sh:721, scripts/verification-lib.sh:2155, scripts/verification-lib.sh:2156, scripts/verification-lib.sh:861, scripts/verification-lib.sh:862, scripts/verification-lib.sh:91, scripts/verification-lib.sh:92, scripts/verification-lib.sh:440, templates/verification-contract.md:220
- **Reproduced:** In the sandbox, `vf_round_authorized <fixture> opponent 4 2026-09-08T00:00:00Z` returned 0 on the HTML-commented STATUS.md, so `vf_gate_round` would reserve round 4; the same fixture wrapped in any fence form returns 4 (the preserved probe's 20 cases all still pass). Sibling sites: running `sdd-analyze.sh` on the same fixture pair the shipped test uses at tests/test-sdd-analyze.sh:265, the fenced task block correctly leaves `FM-002 has no non-gate task owner` (1 occurrence) while the identical block inside `<!-- … -->` silences it (0 occurrences, analyzer exit 0). `vf_matrix_parse` on one AC row emits 5 fields plain, 5 fields HTML-commented, 0 fields fenced.
- **Root cause:** implementation-error
- **Blocks:** REQ-012, AC-009, REQ-002, REQ-004, AC-003
- **Wrong behavior:** REQ-012 requires an in-force user authorization naming the gate and exact round; an explicitly revoked, commented-out line lifts the round cap — and unlike the fence case, the text is invisible in every rendered view of STATUS.md, so the reviewer who reads the log sees nothing at all. The repair's own stated rule at templates/verification-contract.md:220 is "Quoted text is a record, never an instruction", but the enforced set enumerates only fenced blocks, blockquotes and four-column indentation. An HTML comment is the one quoting form this repository actually uses for machine-read markers (`<!-- gate-round-end: … -->`), so the grammar gives comments semantic weight in one parser and no suppression in the other seven. The task-scanner site is the exact vector the 2026-09-11 Decisions entry says T030o12 closed class-wide ("a task block quoted inside a fence became a real task and could claim ownership of an applicable FM/INV row, silencing the warning that INV-005 exists to keep honest"); the sweep closed the fence spelling of it and left the comment spelling live.
- **Class-wide fix:** Extend the shared tracker with HTML-comment state — a line opening `<!--` suppresses until the matching `-->`, with the same deny-on-unprovable-close rule the fence tracker already uses — so all seven `is this in force` parsers inherit it from one place, and exempt only the anchored `<!-- gate-round-end: …` marker `vf_reports` consumes deliberately. Restate the enforced set at templates/verification-contract.md:220 as fence, blockquote, indentation and HTML comment. Add negatives per parser: commented waiver and spec-revision, commented `## Round` heading, commented matrix row, commented task block and commented plan definition row. Sibling extent I checked: the plan-table parser is incidentally immune because a `<!--` line breaks table continuity at scripts/verification-lib.sh:441 before the row rule runs — that is luck, not a guard, so it needs its own case. Remaining unexamined: `<details>`/raw-HTML blocks also authorize (rc=0 in the sandbox); I did not decide whether collapsed-but-rendered content should count as quoted, and flag it as an open question rather than gating on it.

### Finding O-004
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-004
- **Severity:** wrong-result
- **Scenario:** A canonical opponent report declares `**Verdict:** CLEARED` and `**Blocking:** 0 · **Minor:** 0`, carries both required sections with real bodies, and records one brand-new finding `O-042` with `Severity: data-loss`, a concrete `Where: scripts/run.sh:9`, and every other required field — but writes `Status: resolved` with `Prior: O-041`, an ID that appears in no round of that gate and in no earlier review.
- **Where:** scripts/verification-lib.sh:829, scripts/verification-lib.sh:830, scripts/verification-lib.sh:834, tests/test-gate-contracts.sh:286, tests/test-gate-contracts.sh:289
- **Reproduced:** In the sandbox, `spec-gate.sh tally` on that report returned 0 and printed `opponent rounds=1` and `blocking=0 minor=0 locations=1 unclassified=0`, with `class=silent-data-loss findings=1`. The guard at scripts/verification-lib.sh:829 tests `prior !~ /^[A-Z][A-Z0-9]*-[0-9]+/`, which is a shape test, not an existence test, so one fabricated token satisfies it. `vf_reports` is the same validator `round --complete` calls before sealing, and the counts it computes are what the verdict consistency rule at scripts/verification-lib.sh:855 is checked against, so the clearance is canonizable. The repository's own fixture enshrines it: tests/test-gate-contracts.sh:286 rewrites `Prior: none` to `Prior: O-041` on the data-loss report and tests/test-gate-contracts.sh:289 asserts `blocking=0 minor=0`.
- **Root cause:** implementation-error
- **Blocks:** REQ-011, REQ-010, REQ-012, AC-012
- **Wrong behavior:** The wrong behavior O-004 named is unchanged in substance: a report keeps a blocking finding's full text and still reports zero blockers, which REQ-011 requires the counts to reflect. The 2026-09-10 Decisions entry states the enforced rule "blocks the actual attack (a brand-new data-loss finding neutralized as resolved with `Prior: none`)"; it blocks only the literal token `none`. The stated reason for not implementing the round-1 rule — that it would reject round 1's own `O-006`, whose `Prior: O-006` refers to the uncounted 2026-09-09 provisional review — is a real constraint, but it argues against one specific rule, not against any existence check, and the weaker rule that shipped raises the cost of the attack by a single character.
- **Class-wide fix:** Make `Status: resolved` require that `Prior` name an ID the gate's own report history contains, accepting `prior == fid` so round 1's `O-006` (whose ID is present in the round that records it) still validates, and accept an ID recorded in a declared prior-review manifest under `notes/verification/reports/` for genuinely renumbered provisional findings; alternatively stop `resolved` from suppressing the count at scripts/verification-lib.sh:832 and reconcile the totals line instead. Replace the tests/test-gate-contracts.sh:286 positive with a fabricated-ID negative plus a real cross-round positive (`O-001` resolved in round 2 of the existing four-round fixture, which already exercises the `lastseen` branch). Sibling extent: the same `finding()` counting rule serves the reality-check gate, whose findings are tallied by the identical code path at scripts/verification-lib.sh:832 — I built no reality-check fixture for it, so that side is unexamined.

### Finding O-005
- **Class:** config-interpolation-validation
- **Status:** reopened
- **Prior:** O-005
- **Severity:** wrong-result
- **Scenario:** A project declares a gate check using process substitution rather than a dollar form or a backtick — `gate_checks:` with the scalar `'diff <(date -u +%Y) baseline.txt'`, or the output form `'bash tests/run.sh > >(tee log)'` — and opts the same string into `reuse_checks`.
- **Where:** scripts/verification-lib.sh:136, scripts/verification-lib.sh:137, scripts/verification-lib.sh:138, scripts/verification-lib.sh:129, templates/verification-contract.md:100, tests/test-verification.sh:95, tests/test-verification.sh:101
- **Reproduced:** In the sandbox, `vf_config` on a stack.yml declaring `'diff <(date -u +%Y) baseline.txt'` returned 0 with the command retained verbatim in commands.nul, and likewise for `'bash tests/run.sh > >(tee log)'`, while the controls behaved as the fix intends — backtick ``echo `id -un` `` rejected with "command substitution is unsupported", `echo $(id -un)` with "interpolation is unsupported", `ls ~/private` with "tilde expansion is unsupported". Running the accepted string the way `vf_gate_execute` does, `bash -o pipefail -c 'cat <(date -u +%Y)'`, printed `2026`, so the substituted process really executes.
- **Root cause:** implementation-error
- **Blocks:** REQ-009, REQ-007, REQ-008, AC-011
- **Wrong behavior:** templates/verification-contract.md:96 states the enforced rule as "every form whose value depends on the invocation context or the clock, because a reused check identity records the command string and not what the shell substituted into it", and the source comment at scripts/verification-lib.sh:129 still claims the guard covers "Every unescaped expansion Bash would perform at execution time … command substitution in BOTH spellings". Bash has three spellings that run a command and splice its result at execution time; process substitution is the third, and it is exactly as invocation- and clock-dependent as the two that are rejected. The recorded check identity hashes argv, shell, repo, cwd and policy, so it is identical whatever the substituted process yielded — a check declared this way passes configuration validation, executes at floor and checkpoint time, and is then reusable under a local policy that does not record what actually ran, which REQ-009 forbids for time-dependent checks. This is the same overclaimed-coverage defect the round-1 report quoted back, one enumeration wider. I accept that no lexical rule can exclude all semantic time-dependence (`'date -u +%Y | grep -q 2026'` is accepted and always will be); the defect is that a *syntactic* command substitution the stated set claims to reject is accepted.
- **Class-wide fix:** Reject unescaped `<(` and `>(` in every configuration scalar at the one shared `scalar()` guard, correct the comment at scripts/verification-lib.sh:129 to enumerate what is actually enforced rather than claim completeness, and restate the set at templates/verification-contract.md:100 as "command substitution in all three spellings". Add `<(`/`>(` negatives beside the existing backtick rows in the tests/test-verification.sh:95–:101 block for `gate_checks`, `reuse_checks` and `checkpoints`, plus a positive proving a literal redirection such as `'bash tests/run.sh > out.log'` still parses. One shared scalar parser serves all five lists; the executed consumers are the three `vf_gate_execute` call sites. Remaining unexamined: I did not audit whether any other Bash construct the guard admits (here-strings, `${…}`-free brace groups, `$'…'`) reaches an executor, so the enumeration should be derived from the Bash expansion list rather than extended case by case again.

### Finding O-001
- **Class:** return-envelope-parsing
- **Status:** resolved
- **Prior:** O-001
- **Severity:** minor
- **Scenario:** A worker appends a permitted narrative line whose first token is an FM or INV identifier after a complete envelope, e.g. `FM-002 was excluded for this task; see plan 4.2.` following a valid Task/Captures/Summary/Failure modes block with two correct mapping rows.
- **Where:** scripts/verification-lib.sh:1400, scripts/verification-lib.sh:1410, scripts/verification-lib.sh:1391
- **Reproduced:** In the sandbox, `vf_return_parse` on that file exited 0 with `mappings=2` and one `truncated` record; previously it exited 3 with "return: unexpected field or malformed mapping". `vf_return_check` only turns `truncated` into a message when the row set does not match at scripts/verification-lib.sh:1493, so a complete mapping followed by such narrative is accepted.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Previously a permitted narrative sentence opening with an FM or INV identifier forced the worker to reword a correct return. The envelope now ends at the first non-blank line that is not a well-formed mapping row and everything after it is narrative, which is what plan §4.2 permits.
- **Class-wide fix:** Already applied at the single runtime consumer; T030o8 delimited the block explicitly as the round-1 follow-up proposed. Remaining unexamined extent: narrative placed *between* `Summary:` and `Failure modes:` still reaches the catch-all error rather than being treated as narrative — deny-side, and I did not establish whether the contract intends to permit it.

### Finding O-003
- **Class:** live-control-semantic-validation
- **Status:** resolved
- **Prior:** O-003
- **Severity:** wrong-result
- **Scenario:** A worker return carries a complete and correct mapping but puts one explanatory sentence between the `Failure modes:` line and the rows, so the AC-016 probe's required rejection class could be produced by a formatting slip rather than by the deliberately incomplete copy.
- **Where:** scripts/verification-lib.sh:1410, scripts/verification-lib.sh:1455, scripts/verification-lib.sh:1493, scripts/verification-lib.sh:1541, tests/probe-gate-contract.sh:41
- **Reproduced:** In the sandbox, `vf_return_parse` on that file now emits `mappings=0` plus a `truncated` record, and `vf_return_check` reports "return: Failure modes section ended at narrative before any mapping row; keep the rows contiguous", which `vf_reject_class` types `truncated-envelope` at scripts/verification-lib.sh:1541 — a class the probe explicitly refuses at tests/probe-gate-contract.sh:41, which requires `binding-mismatch`. The `binding-mismatch` arm now covers only genuine required-row problems, and the capture arm separates `capture-integrity` from the stale group at scripts/verification-lib.sh:1548–:1550.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Previously a formatting slip satisfied the live-wiring assertion AC-016 names, so the promised real observation could be a false positive. The rejection classes are now disjoint and the probe requires the row-level one, so the recorded ACCEPT event can no longer be substituted for by a truncated envelope.
- **Class-wide fix:** Applied at both the parser and the class map; the capture-arm sibling the round-1 report left unexamined is now split. Remaining unexamined extent: I read `vf_reject_class` for arm ordering but built no fixture where one validation log carries two matchable messages, so first-match precedence is unproven by execution.

### Finding O-006
- **Class:** post-pr-followup-binding-schema
- **Status:** resolved
- **Prior:** O-006
- **Severity:** regression
- **Scenario:** /sdd:review turns a red CI check or an actionable review comment into a Ship-stage `T###c1` or `T###r1` follow-up and then runs the instructed no-tick capture and deterministic acceptance.
- **Where:** skills/sdd-review/SKILL.md:30, skills/sdd-review/SKILL.md:46, tests/test-spec-gate.sh:100, tests/test-spec-gate.sh:105
- **Reproduced:** Unchanged since round 1, which verified the typed shape at both creation branches and the end-to-end `--from-task --no-tick --summary` plus accept fixture; nothing in the T030o7–T030o12 diff touches those files or the follow-up suffix class at scripts/verification-lib.sh:635.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Previously the documented post-PR workflow produced an untyped task that could neither be captured nor accepted. Both branches now carry the typed binding and an executable fixture proves capture plus acceptance.
- **Class-wide fix:** Already applied at both known sites; no new evidence in this round. Remaining unexamined extent: still no executable `r`-suffix capture/accept fixture, so that branch is proven by instruction text plus the shared validator rather than by execution.

### Finding O-007
- **Class:** round-block-attribution
- **Status:** resolved
- **Prior:** O-007
- **Severity:** wrong-result
- **Scenario:** Round 1 is sealed at digest `1ac95178…`; the round-2 report handed to `round --complete` carries a preamble before its `## Round 2` heading — plain prose, or a fenced block, which round 1 showed `vf_reports` skips but `vf_report_block` absorbs.
- **Where:** scripts/verification-lib.sh:930, scripts/verification-lib.sh:2115, scripts/verification-lib.sh:2121, scripts/verification-lib.sh:1865
- **Reproduced:** In the sandbox, against a copy of the real `notes/opponent.md`: the plain-prose preamble is refused by `vf_reports` with "content after the round completion marker" at the exact line; the fenced preamble is refused too (its shifted round-2 identity fails the sequence check), and in both cases `vf_report_block` for round 1 does move — to `4c5aab3f…` and `f4cc7aa3…` — which the new belt-and-braces loop at scripts/verification-lib.sh:2115 catches before publication with "report would change already sealed round 1; correct the returned report". Recovery is correcting the report and re-running `--complete`, with no ledger edit and no wedged later invocation. The clean case recomputes `1ac95178f408b2ae807005a0e349816477e90b4dab5afd70a536cfe798f0c9e7`, matching the sealed ledger byte for byte.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Previously completion succeeded silently and corrupted an already-sealed identity, after which every reserve, complete, reconcile and probe call exited 3 with no scripted recovery. Both halves of the repair are now load-bearing and each is killed by its own mutation, per the 2026-09-10 record.
- **Class-wide fix:** Applied; `vf_report_block` accumulation is deliberately unchanged so sealed digests cannot move. Two line shapes still slip past the first guard (see O-008) and are caught only by the second. Remaining unexamined extent: `vf_matrix_prior` at scripts/verification-lib.sh:2116 reads the same accumulator for reality-check carrying and I built no reality-check carry fixture for it.

### Finding O-008
- **Class:** round-block-attribution
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** The round-2 report handed to `round --complete` carries, between round 1's `<!-- gate-round-end: opponent:1 -->` and its own `## Round 2` heading, a line that the parser consumes with `next` before reaching the after-marker guard — either `**Blocking:** 5 · **Minor:** 1` (matching round 1's real totals, so the totals cross-check still passes) or a bare `# Opponent review` heading.
- **Where:** scripts/verification-lib.sh:888, scripts/verification-lib.sh:866, scripts/verification-lib.sh:930
- **Reproduced:** In the sandbox, a copy of the real `notes/opponent.md` plus that one line plus a complete valid round-2 block parsed with `vf_reports` rc=0 and no diagnostic, while `vf_report_block … 1` moved from `1ac95178…` to `4b8c69b6…`. The identical file with no preamble stays at `1ac95178…`. The rule at scripts/verification-lib.sh:888 sets the totals and calls `next` without testing `ended`, and the legacy-heading rule at :866 does the same, so both reach `next` before the guard at :930.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** T030o11's acceptance states that "a report carrying any non-blank line after a round completion marker and before the next `## Round n` heading is refused"; two shapes are not refused. It is minor and not blocking because the belt-and-braces loop added by the same task refuses the completion a few lines later, so nothing is published and nothing is wedged — but the operator gets "report would change already sealed round 1" instead of the guard's file:line diagnostic, and the stated acceptance is not met.
- **Class-wide fix:** Move the `ended` test ahead of the field rules, or add `if (ended) {err("content after the round completion marker"); next}` to the `**Blocking:**` rule at scripts/verification-lib.sh:888 and the legacy-heading rule at :866; add both shapes as negatives beside the existing after-marker case in `tests/test-spec-gate.sh::test_rounds`. I enumerated every `next`-bearing rule ahead of :930 and these two are the only ones that neither err nor open a new round; the `/^#+[ ]/` section rule has no `next` and correctly falls through to the guard.

### Finding O-009
- **Class:** round-authorization-grammar
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** STATUS.md carries a second heading beginning with the word Decisions — e.g. `## Decisions we rejected` — recording a waiver that was asked for and refused: `- 2026-09-10T10:00:00Z — waiver: gate=opponent; round=4; after=3; by=some-user; reason=rejected proposal, never granted`.
- **Where:** scripts/verification-lib.sh:2004, scripts/verification-lib.sh:1062
- **Reproduced:** In the sandbox, `vf_round_authorized <fixture> opponent 4 2026-09-08T00:00:00Z` returned 0 on that STATUS.md. The section test at scripts/verification-lib.sh:2004 is the prefix `/^## Decisions/`, so every heading starting with that word opens the authorization log.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** REQ-012 requires the authorization to be a real in-force user decision; a section whose whole purpose is to record refused decisions grants one. It is minor rather than blocking because the trigger requires someone to write a syntactically perfect live waiver under a non-template heading, and the shipped `templates/status-template.md:35` declares exactly one `## Decisions log` heading, so no shipped artifact is affected. `vf_semantic_file` at scripts/verification-lib.sh:1062 uses the identical prefix, so the manifest and the authorization view agree and no freshness gap follows.
- **Class-wide fix:** Anchor both parsers on the template's exact heading (`/^## Decisions log[[:space:]]*$/`), keeping them in step so the manifest still hashes exactly what the authorization scanner reads; add a negative for a second `## Decisions…` heading. Remaining unexamined: I did not check whether any governed project outside this repository already uses a variant Decisions heading that this anchoring would silently stop hashing.

### Held up / follow-up tasks

Attacked and held, with the reason each held. The nested-fence grammar itself: I could not defeat `vf_fence` with an inner shorter run, the other fence character, a longer closer, a closer carrying an info string, a four-space-indented run, a tab-indented run, a CRLF closer or an unclosed opener — the last three all fail in the deny direction, and the preserved probe's twenty cases still report zero mismatches. `vf_report_block` and `vf_reports` now agree about which lines are fenced: both call `vf_fence` on every line, and the only rule that differs (the legacy `# Opponent review` heading) cannot change attribution once a `## Round` heading has been seen. The `vf_ac_catalog`/`vf_semantic_file` asymmetry: every divergence I constructed was deny-side — a fenced AC adds an obligation or trips `duplicate AC definition` and exits 3, and a fenced Decisions edit still changes the input manifest, so no capture survives an edit hidden in a fence. AC-021's bounds and exit fidelity, measured on four verbose shapes. AC-002's overlay set, enumerated from the directory rather than a list, all fourteen carrying three categorized scenarios plus the stage-vs-`gate_checks` distinction. The return envelope's in-block strictness, which still rejects malformed, duplicate and unknown rows while accepting narrative on both sides. The checkpoint lost-prior-binding delta, which validates each prior CHECKPOINT's integrity before differencing.

Proposed follow-ups, one per class, with all known locations:

- T030o13 — Give the shared quoted-content tracker HTML-comment state and inherit it in all seven `is this in force` parsers, exempting only the anchored `gate-round-end` marker; add commented-waiver, commented-round-heading, commented-matrix-row, commented-task-block and commented-plan-row negatives, and a plan-table case that does not depend on the incidental table-continuity break. Locations: scripts/verification-lib.sh:48, :91, :92, :440, :527, :528, :720, :721, :861, :862, :2002, :2003, :2155, :2156, templates/verification-contract.md:220. (O-002)
- T030o14 — Require a resolved finding's `Prior` to name an ID the gate's history contains, accepting `prior == fid` so round 1's O-006 still validates; replace the fabricated-ID positive with a negative plus a real cross-round positive, and cover the reality-check side. Locations: scripts/verification-lib.sh:829, :830, :832, :834, tests/test-gate-contracts.sh:286, :289. (O-004)
- T030o15 — Reject unescaped process substitution in configuration scalars, correct the coverage claim in the comment, restate the enforced set in the contract, and add `<(`/`>(` negatives for gate/reuse/checkpoint lists plus a plain-redirection positive. Locations: scripts/verification-lib.sh:129, :136, :137, :138, templates/verification-contract.md:100, tests/test-verification.sh:95, :101. (O-005)
- T030o16 — Close the two after-marker bypasses so the first guard matches its stated acceptance. Locations: scripts/verification-lib.sh:866, :888, :930. (O-008, minor, non-blocking)
- T030o17 — Anchor the Decisions section on the template's exact heading in both the authorization scanner and the input manifest. Locations: scripts/verification-lib.sh:1062, :2004. (O-009, minor, non-blocking)

O-001, O-003, O-006 and O-007 are resolved and need no follow-up; their remaining unexamined extents are recorded in their Class-wide fix fields and are not blocking.
<!-- gate-round-end: opponent:2 -->

## Round 3
**Round:** 3
**Timestamp:** 2026-09-11T23:03:58Z
**Source:** 173fc57bca09014a4e94d497cc1802128b50c99c1548e76d713ef9fb7662aefb
**Floor:** FLOOR-QjKfE7
**Verdict:** BLOCKED
**Blocking:** 3 · **Minor:** 1

### What I attacked

**Invoker reconciliation note — not the reviewer's words.** The independent reviewer returned **CHALLENGED**, 3 blocking and 1 minor, and its report is preserved verbatim at `notes/verification/reports/opponent-round3.md`. This block records the same review under `BLOCKED` because the INVOCATION could not be canonized, not because the verdict was softened: `round --complete` refused the report through a defect in T030o14, which located the prior-review manifest relative to the report file and therefore lost it for the temporary `combined.md` that completion validates, rejecting round 1's legitimate resolved `O-006`. Repairing that defect changes the source identity, so the reservation's floor can no longer revalidate and the round cannot be completed as CHALLENGED by any route; `BLOCKED` is the only verdict `--reconcile` accepts for this gate. Every finding below is the reviewer's, unaltered, and all three blocking findings remain blocking. The consumed round number is preserved rather than reset.

I confirmed the dossier is current before grading: the live `git diff main -- . ':!…/notes'` hashes to `42e2a262…`, byte-identical to `notes/verification/dossier/source.diff`, and the floor meta names source `173fc57b…`. I then took the standing question literally — do T030o13–T030o17 generalize, or do they add the next named spelling — and attacked each repair with inputs the enumeration does not name, in throwaway sandboxes under TMPDIR by direct library calls and by `spec-gate.sh tally` on copies. No gate, floor, round, accept, ledger, capture, task or report state was mutated, and nothing was written inside the worktree. Reproduced this round: `vf_reports`/`tally` on a brand-new `data-loss` finding neutralized as `Status: resolved` with a real earlier `Prior`; `vf_reports` on a canonical round whose blocking finding is hidden by a four-space-indented comment opener; `vf_reports` plus `vf_report_block` on fenced, HTML-commented and blockquoted preambles placed between round 1's marker and `## Round 2`, against the sealed `1ac95178…`; `vf_round_authorized` on HTML-commented, `<details>`, `<!DOCTYPE`-wrapped and stray-backtick STATUS fixtures and on the round-2 `## Decisions we rejected` control; `vf_config` on seven scalar spellings including both process-substitution directions, a plain redirection, a here-string and a pipeline; the shared quoted tracker against the `vf_bindings` task inventory; and `tests/probe-gate-contract.sh`, `vf_snapshot`, `vf_capture_check` and the `vf_floor_validate` loop body against the sealed floor and the real T029 accept receipts.

Read line by line and traced for consumers: the whole `_VF_AWK_FENCE` tracker including the new `vf_uncoded`/`vf_comment` functions and all nine `vf_quoted`/`vf_fence` call sites (scripts/verification-lib.sh:129, :483, :570, :762, :926, :2022, :2068, :2220 plus the plan-table `vf_indented` pair at :484/:487), the whole of `vf_reports` with its new `known_prior`/`priorids` manifest rule, `vf_report_block`, `vf_round_history`, `vf_round_authorized`, the `--complete` branch and its belt-and-braces prior-digest loop, `vf_config`'s shared `scalar()` guard serving all five lists, `vf_snapshot`, `vf_capture`, `vf_capture_check`, `vf_floor_validate`, `vf_accept_transaction`, `vf_manual_current`, `vf_matrix_parse`, `vf_reality_matrix`, `scripts/spec-gate.sh`, the changed argument handling in `scripts/spec-evidence.sh` and `scripts/spec-ac-coverage.sh`, the three raw tasks.md awk passes in `scripts/sdd-analyze.sh`, and `tests/probe-gate-contract.sh`. I inspected the actual assertions, not the presence, of tests/test-gate-contracts.sh:290–:345 and tests/test-verification.sh's config-grammar block for every prior class; that is how O-004 surfaced again — tests/test-gate-contracts.sh:324–:327 now certifies the exact attack as a passing positive.

Previously unexamined surfaces I did examine: the live AC-016 checker, which I executed rather than read (it exits 3 today); `vf_snapshot`'s environment and tool records; `vf_floor_validate`'s per-capture currency loop; `vf_accept_transaction`'s idempotence ordering; the `vf_bindings` task inventory under the new comment state; and the analyzer's own tasks.md parsers.

Not examined, and therefore not cleared. I did not re-execute `tests/run.sh`, ShellCheck or any suite this round — I reused FLOOR-QjKfE7's sealed captures for suite status as the dossier permits, noting that the same captures no longer revalidate as current from this session (Finding O-010). For the third round the authoring templates, expert personas, README and constitution prose behind AC-014, AC-017 and AC-018 remain unread beyond targeted greps. Still unexercised by me: the umbrella/multi-repo branches of `vf_gate_roots`/`vf_gate_task_repo`, `vf_accept_transaction`'s crash windows, `vf_matrix_prior` with a real reality-check carry fixture, the `r`-suffix follow-up capture/accept branch, Linux and GitHub-hosted CI behaviour (AC-019 is not claimed), and per-negative branch coverage inside the large fixtures. The end-to-end direction of the analyzer sibling in Finding O-002 is established by reading, not by execution. No claim of an exhaustive sweep.

### Finding O-002
- **Class:** round-authorization-grammar
- **Status:** reopened
- **Prior:** O-002
- **Severity:** wrong-result
- **Scenario:** A canonical opponent report declares `**Verdict:** CLEARED` with zero totals, carries both required sections with real bodies, and records a brand-new `Severity: data-loss` finding `O-042` with every required field — but four lines above it, after a blank line, an example block indented by four spaces begins with a comment opener that has no closer on that line, and a matching closer sits in a second indented line after the finding. In rendered markdown those two lines are an indented code block, so the opener is literal visible text and the whole finding renders as a live heading with its data-loss severity; in the tracker the opener enters comment state and swallows the finding.
- **Where:** scripts/verification-lib.sh:85, scripts/verification-lib.sh:92, scripts/verification-lib.sh:96, scripts/verification-lib.sh:98, scripts/verification-lib.sh:99, scripts/verification-lib.sh:101, scripts/verification-lib.sh:106, scripts/verification-lib.sh:997, scripts/sdd-analyze.sh:199, scripts/sdd-analyze.sh:235, scripts/sdd-analyze.sh:274, templates/verification-contract.md:226, templates/verification-contract.md:231
- **Reproduced:** In the sandbox, a copy of the real `notes/opponent.md` plus that round-3 block parsed with `vf_reports … opponent` at rc=0 and no diagnostic; the emitted catalog contains the `round|3|…|CLEARED` record and **no** `finding|3` record at all, so the data-loss finding is absent from the count that the verdict-consistency rule at scripts/verification-lib.sh:918 is checked against. The same opener applied to a tasks.md fixture removes a real `- [x] **T002**` from the shared task inventory (output `T001 stage=Backend`, `T003 stage=Tests`, T002 gone) while T002 renders normally. `vf_fence` guards indentation at scripts/verification-lib.sh:51 (`ind > 4` returns 0); `vf_comment` has no indentation test anywhere. The END rule at scripts/verification-lib.sh:997 reports `unclosed code fence` but has no counterpart for an unclosed comment, so the swallow is silent.
- **Root cause:** implementation-error
- **Blocks:** REQ-010, REQ-011, REQ-015, AC-012, REQ-002, REQ-004
- **Wrong behavior:** T030o13's enforced set is now a spelling list rather than a derivation, and the divergence has flipped to the granting direction. The contract states its own rule at templates/verification-contract.md:226 — "treats an indented line as content: table rows and fence markers at four or more columns" — and the principle the 2026-09-11 Decisions entry uses to exclude `<details>`: content "visible to a reader" is a record, hidden content is an instruction. A four-space-indented opener is visible to every reader and is still read as a marker, so a report a human reads as carrying a data-loss finding tallies zero blockers and canonizes CLEARED, which REQ-011 requires the counts to reflect and REQ-015 forbids ("grouping sites cannot hide location counts or unresolved findings"). The identical divergence exists for a closer written inside an inline code span, which scripts/verification-lib.sh:88 strips but no HTML renderer does, so the parser stays commented past the point every reader sees the comment end.
- **Class-wide fix:** Derive comment extent from the markdown the parser is reading rather than from a token scan: give `vf_comment` the same `ind > 4` content guard `vf_fence` already has at scripts/verification-lib.sh:51 so an indented opener is content, and treat a closer as closing wherever a renderer would — either stop stripping code spans on the closer side at scripts/verification-lib.sh:88 or record that the two sides deliberately differ and prove the difference cannot grant. Add an END diagnostic for an unclosed comment beside the fence one at scripts/verification-lib.sh:997 so the silent swallow becomes a named failure. Add negatives per parser: indented-opener report, indented-opener task block, code-span-closer report, and a positive proving a genuinely commented finding is still uncounted. Sibling extent I established by reading and did not execute end to end: scripts/sdd-analyze.sh runs three independent awk passes over tasks.md at :199 (AC coverage), :235 (repo tags) and :274 (per-task structure) with no quoted-content suppression at all, so a fenced or commented example task still supplies `Refs:` to the "every AC is covered by an implementation task" check; that file sources verification-lib.sh already, so the tracker is available to it. Remaining unexamined and flagged rather than gated: `<!DOCTYPE …>`, `<?…>` and `<![CDATA[…]]>` are CommonMark HTML blocks whose content no browser renders, and a `<!DOCTYPE`-wrapped waiver returned rc=0 from `vf_round_authorized` in the sandbox; I did not render any of them on GitHub, and the trigger is exotic enough that I record it as extent for the same fix rather than as a separate blocking spelling.

### Finding O-004
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-004
- **Severity:** wrong-result
- **Scenario:** A canonical opponent report declares `**Verdict:** CLEARED` and `**Blocking:** 0 · **Minor:** 0`, carries both required sections with real bodies, and records one brand-new finding `O-042` with `Severity: data-loss`, `Where: scripts/run.sh:9` and every other required field — but writes `Status: resolved` with `Prior: O-001`, a real ID from rounds 1 and 2 of this gate belonging to an unrelated class (`return-envelope-parsing`).
- **Where:** scripts/verification-lib.sh:884, scripts/verification-lib.sh:895, scripts/verification-lib.sh:899, scripts/verification-lib.sh:901, scripts/verification-lib.sh:862, tests/test-gate-contracts.sh:324, tests/test-gate-contracts.sh:326, tests/test-gate-contracts.sh:327
- **Reproduced:** In the sandbox, `vf_reports <fixture> opponent` returned 0 with the finding recorded as `finding|3|O-042|silent-data-loss|resolved|O-001|data-loss|scripts/run.sh:9|…` and no diagnostic, while the byte-identical fixture with `Prior: O-041` was refused at the exact line with "resolved finding O-042 names no recorded prior finding and has no earlier round". `spec-gate.sh tally` on the accepted fixture printed `opponent rounds=3` and `class=silent-data-loss findings=1 recurrences=0` while round 3 itself contributed zero blockers, so the CLEARED verdict passes the consistency rule at scripts/verification-lib.sh:918. The repository's own fixture now enshrines the same shape: tests/test-gate-contracts.sh:324 declares a manifest containing only `O-041`, :326 asserts `tally` exits 0, and :327 asserts `blocking=0 minor=0` for a report whose sole finding is a brand-new `O-042` data-loss defect.
- **Root cause:** plan-gap
- **Blocks:** REQ-010, REQ-011, REQ-012, REQ-015, AC-012
- **Wrong behavior:** The wrong behavior O-004 has named three times is unchanged in substance: a report keeps a blocking finding's full text and still reports zero blockers. T030o14's acceptance — "accepted only when the finding ID appeared in an earlier round of that gate, or `Prior` names an ID that did" — is implemented exactly and faithfully, and it is the rule that is wrong: it tests that *some* prior finding exists, never that the resolved claim is about *that* finding. `resolved` means "a defect already reported is now fixed", so the check has to bind the claim to the prior record it resolves, not to the gate's history in general. The attack's cost went from inventing a token to copying one that is printed in the same file, and the shipped test certifies the result as correct, so no fixture can catch a regression here.
- **Class-wide fix:** Bind the claim to its subject: accept `Status: resolved` only when the finding ID itself appeared in an earlier round of that gate (the documented new/open/resolved/reopened lifecycle keeps one ID), or when `Prior` names an ID whose recorded `Class` matches this finding's `Class` — a manifest entry must then carry a class too, which the current `grep -oE '^#+ Finding …'` at scripts/verification-lib.sh:862 does not read. The alternative the round-2 report offered is still open and is strictly simpler: stop `resolved` from suppressing the count at scripts/verification-lib.sh:884 and reconcile the totals line against all recorded findings instead. Replace the tests/test-gate-contracts.sh:324–:327 positive with a class-mismatch negative plus a real same-ID cross-round positive. Sibling extent: the identical `finding()` rule serves the reality-check gate through the same code path; I built no reality-check fixture, so that side is unexamined for a second round.

### Finding O-010
- **Class:** verification-input-identity
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** Any reviewer, gate subagent or later session validates the sealed floor, a capture or a completed acceptance from a shell whose exported environment differs from the capturing shell by a single variable — here the harness's own `CLAUDE_EFFORT`, whose value the CLI changes per invocation — against a byte-identical worktree.
- **Where:** scripts/verification-lib.sh:1201, scripts/verification-lib.sh:1205, scripts/verification-lib.sh:1385, scripts/verification-lib.sh:1863, scripts/verification-lib.sh:1866, scripts/verification-lib.sh:1658, scripts/verification-lib.sh:1668, scripts/verification-lib.sh:2124, scripts/verification-lib.sh:2175, tests/probe-gate-contract.sh:30, tests/probe-gate-contract.sh:62
- **Reproduced:** `bash tests/probe-gate-contract.sh .specify/specs/003-gate-round-reduction-and-token-discipline` exits 3 right now on the unmodified tree, printing `capture stale: current inputs changed; refresh verification` four times followed by `probe gap: authentic rejected-copy/intact-acceptance control missing or stale`. I then recomputed the whole-source identity: `vf_gate_snapshot` returns `29e9aad713d3…` against the floor's sealed `173fc57bca09…`, and a record-level diff of the two manifests shows **exactly one** differing line out of 2116 — the hashed value of `environment|CLAUDE_EFFORT`. Every index, untracked, declared-input, tool, harness and document record is byte-identical. `vf_capture_check "$spec" CAP-153-FAla8S <fresh snapshot> current` returns 3 while `… integrity` returns 0 on the same capture, and CAP-153-FAla8S is the first entry in FLOOR-QjKfE7's `commands.nul`, so the loop body at scripts/verification-lib.sh:1866 fails on its first iteration. Exporting one unrelated variable (`SDD_OPPONENT_PROBE=1`) changed the manifest digest from `29e9aad7…` to `046e8a1c…`, so the sensitivity is to any exported name, not to this one.
- **Root cause:** plan-gap
- **Blocks:** AC-016, AC-022, REQ-006, REQ-012
- **Wrong behavior:** `vf_snapshot` hashes every exported variable except `PWD`, `OLDPWD`, `SHLVL` and `_` at scripts/verification-lib.sh:1201–:1205, so "reviewed source identity" is a source-plus-ambient-environment identity and is not re-derivable by anyone but the originating shell. Three consequences are not covered by the 2026-09-09 Decisions entry, which recorded only the cost effect ("reuse savings are within-session"). First, AC-016 requires the live rejected-copy/intact-acceptance observation to be "checked at reality-check", and the reality-check gate is by design a separate invocation: its shipped checker cannot pass, and the remedy the Decisions entry gives — re-execute — is unavailable, because re-observing the control means performing a new accept, which the review gates must not do. Second, AC-022 requires repeated acceptance to be idempotent, but `vf_accept_transaction` validates currency at scripts/verification-lib.sh:1658 *before* the already-accepted receipt check at :1668, so re-accepting T029's own accepted return is rejected today and writes a rejection audit event into the very ledger the AC-016 probe scans. Third, REQ-012's round machinery runs through `vf_floor_validate` at scripts/verification-lib.sh:2124 and :2175, and a CHALLENGED report cannot be completed when the floor will not revalidate — only a BLOCKED/FAILED verdict skips that check — so from any session whose environment has drifted, a reserved round can neither be completed nor re-reserved against the same floor. I established that the floor does not revalidate from this reviewing session; whether the invoker's own session still matches FLOOR-QjKfE7 I did not establish.
- **Class-wide fix:** Make the environment record a declared, closed set rather than everything `compgen -e` happens to emit: hash only variables the project declares (a `verification_environment:` list beside `verification_tools:`/`verification_inputs:`) plus the ones the harness demonstrably uses (`PATH`, `SHELL`, `LANG`/`LC_*`, `TMPDIR`), and drop the rest at scripts/verification-lib.sh:1201 with the same named-diagnostic discipline the tool records use. Independently of that decision, move the already-accepted receipt check at scripts/verification-lib.sh:1668 ahead of the currency validation at :1658 so idempotence is decided by the receipt, not by re-proving a tick that was already proven, and add a fixture that accepts the same return twice across a changed environment. If snapshotting the whole environment is kept deliberately, AC-016's "checked at reality-check" is unsatisfiable as written and the spec must say what the reviewer runs instead — I flag that as the open question rather than deciding it. Sibling extent: the same `current` predicate gates `vf_manual_current` at scripts/verification-lib.sh:1881 and `vf_matrix_evidence`'s capture check at :2275, and `vf_gate_floor`'s reuse path at :1751 degrades to full re-execution; I reproduced the floor and accept paths and read but did not execute the matrix and manual paths.

### Finding O-008
- **Class:** round-block-attribution
- **Status:** reopened
- **Prior:** O-008
- **Severity:** minor
- **Scenario:** The report handed to `round --complete` carries, before its own `## Round n` heading, a preamble that is itself quoted — a fenced block, an HTML comment, or a blockquote line — rather than the plain prose, `**Blocking:**` line or legacy heading that T030o16 closed.
- **Where:** scripts/verification-lib.sh:926, scripts/verification-lib.sh:996, scripts/verification-lib.sh:2022, scripts/verification-lib.sh:2025
- **Reproduced:** In the sandbox, against a copy of the real `notes/opponent.md` with one preamble inserted after round 1's completion marker and before `## Round 2`: `vf_reports` returned 0 with no diagnostic for all three quoted shapes, while `vf_report_block … 1` moved round 1's digest from the sealed `1ac95178f408…` to `4ab85ff403a7…` (fence), `92a1e3c82ebe…` (comment) and `ca12c9a2c3cb…` (blockquote). The plain-prose control is correctly refused at its exact line. The cause is ordering: `vf_quoted($0) {next}` at scripts/verification-lib.sh:926 consumes the line before the after-marker guard at :996 ever runs, while `vf_report_block` accumulates every line regardless of quoting at :2025 and uses `quoted` only to avoid opening a round.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** T030o16's acceptance is that any non-blank line after a round completion marker is refused "like every other non-blank line there, instead of reaching the later sealed-digest guard". Three shapes still reach it. This stays minor and non-blocking for the same reason O-008 did: the belt-and-braces loop at scripts/verification-lib.sh:2170 refuses the completion, nothing is published and nothing is wedged — the operator merely gets "report would change already sealed round 1" instead of the file:line diagnostic, and the stated acceptance is still not met. It is reopened rather than closed because the repair again covered exactly the two shapes the previous report listed.
- **Class-wide fix:** Test `ended` before the quoted-content skip, or make the after-marker guard a rule that runs ahead of `vf_quoted` at scripts/verification-lib.sh:926 for lines following a completion marker; add fenced, commented and blockquoted preamble negatives beside the two existing ones in `tests/test-spec-gate.sh::test_rounds`. I enumerated every rule ahead of :996 and these three quoting forms are what remains after T030o16; the alternative is to make `vf_report_block` skip quoted lines the way `vf_reports` does, but that would move both sealed digests and must not be done.

### Finding O-001
- **Class:** return-envelope-parsing
- **Status:** resolved
- **Prior:** O-001
- **Severity:** minor
- **Scenario:** A worker appends a permitted narrative line whose first token is an FM or INV identifier after a complete envelope.
- **Where:** scripts/verification-lib.sh:1400, scripts/verification-lib.sh:1410, scripts/verification-lib.sh:1391
- **Reproduced:** No new evidence this round. Round 2 reproduced the fix by direct `vf_return_parse` calls, and nothing in the T030o13–T030o17 diff touches the envelope parser; I read the block-delimiting rules again and found no new way in.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Previously a permitted narrative sentence opening with an identifier forced the worker to reword a correct return; the envelope now ends at the first non-mapping line and everything after is narrative.
- **Class-wide fix:** Already applied at the single runtime consumer. Remaining unexamined extent, carried from round 2 and still unexamined: narrative placed between `Summary:` and `Failure modes:` reaches the catch-all error rather than being treated as narrative, which is deny-side.

### Finding O-003
- **Class:** live-control-semantic-validation
- **Status:** resolved
- **Prior:** O-003
- **Severity:** wrong-result
- **Scenario:** A worker return with a correct mapping but one explanatory sentence between the `Failure modes:` line and the rows produces the probe's required rejection class by formatting slip rather than by the deliberately incomplete copy.
- **Where:** scripts/verification-lib.sh:1541, scripts/verification-lib.sh:1548, tests/probe-gate-contract.sh:41
- **Reproduced:** No new fixture this round. I re-read `vf_reject_class` and the probe's class requirement, and confirmed from the live ledger that the current T029 control pair carries `class=binding-mismatch` with `before == after == 4e87a753…` (ACCEPT-BQGLTl at 20:32:01Z) followed by the intact acceptance ACCEPT-gtJF9K at 20:32:20Z — a later pair than the one the dossier README describes, and still the typed class the probe demands.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The rejection classes are disjoint and the probe requires the row-level one, so a truncated envelope can no longer stand in for the real control.
- **Class-wide fix:** Applied at both the parser and the class map. Remaining unexamined extent: first-match arm precedence in `vf_reject_class` is still unproven by execution on a log carrying two matchable messages. Note that the control's usability at review time is now gated by Finding O-010, not by this class.

### Finding O-005
- **Class:** config-interpolation-validation
- **Status:** resolved
- **Prior:** O-005
- **Severity:** wrong-result
- **Scenario:** A project declares a gate check using process substitution in either direction and opts the same string into `reuse_checks`.
- **Where:** scripts/verification-lib.sh:180, scripts/verification-lib.sh:170, scripts/verification-lib.sh:179, templates/verification-contract.md:100
- **Reproduced:** In the sandbox, `vf_config` on `'diff <(date -u +%Y) baseline.txt'` and on `'bash tests/run.sh > >(tee log)'` both returned 1 with "command substitution is unsupported" at the exact line, while `'bash tests/run.sh > out.log'`, `'bash tests/run.sh <<< hello'`, `'cat < in.txt'` and `'bash tests/run.sh 2>&1 | tee out'` all returned 0 and parsed unchanged. One shared `scalar()` serves all five lists, so the guard is inherited rather than repeated.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** All three syntactic Bash spellings that run a command and splice its result are now rejected, and the source comment states the enforced set instead of claiming completeness, so the overclaim the round-1 report quoted back is gone.
- **Class-wide fix:** Applied at the one shared scalar guard. I looked for a fourth spelling and found none that reaches an executor: `${ …; }` value substitution is caught by the dollar rule, and here-strings, brace expansion and plain redirection are deterministic. Remaining unexamined extent: no lexical rule excludes semantic time-dependence, which the contract now says explicitly rather than implying otherwise.

### Finding O-006
- **Class:** post-pr-followup-binding-schema
- **Status:** resolved
- **Prior:** O-006
- **Severity:** regression
- **Scenario:** /sdd:review turns a red CI check or an actionable review comment into a Ship-stage `T###c1` or `T###r1` follow-up and then runs the instructed no-tick capture and deterministic acceptance.
- **Where:** skills/sdd-review/SKILL.md:30, skills/sdd-review/SKILL.md:46, tests/test-spec-gate.sh:100
- **Reproduced:** Unchanged since round 1. Nothing in the T030o13–T030o17 diff touches those files or the follow-up suffix class.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Both creation branches now carry the typed binding and an executable fixture proves capture plus acceptance.
- **Class-wide fix:** Already applied at both known sites. Remaining unexamined extent: still no executable `r`-suffix capture/accept fixture, and the accept half of this workflow is now subject to Finding O-010 across sessions.

### Finding O-007
- **Class:** round-block-attribution
- **Status:** resolved
- **Prior:** O-007
- **Severity:** wrong-result
- **Scenario:** A returned report carries a preamble before its `## Round n` heading, which would move an already sealed round's digest at completion.
- **Where:** scripts/verification-lib.sh:2170, scripts/verification-lib.sh:2174, scripts/verification-lib.sh:2025
- **Reproduced:** In the sandbox, the unmodified `notes/opponent.md` recomputes round 1 as `1ac95178f408b2ae807005a0e349816477e90b4dab5afd70a536cfe798f0c9e7`, byte-identical to the sealed `ROUND-1/report.sha256`, and round 2 is sealed at `5170b082…`. Every preamble shape I injected moved that digest and is caught by the belt-and-braces loop before publication.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Completion can no longer silently corrupt a sealed identity; both halves of the repair remain load-bearing.
- **Class-wide fix:** Applied; `vf_report_block` accumulation is deliberately unchanged so sealed digests cannot move. Three line shapes still slip past the first guard and are caught only by the second (Finding O-008). Remaining unexamined extent: `vf_matrix_prior` reads the same accumulator for reality-check carrying and I built no carry fixture.

### Finding O-009
- **Class:** round-authorization-grammar
- **Status:** resolved
- **Prior:** O-009
- **Severity:** minor
- **Scenario:** STATUS.md carries a second heading beginning with the word Decisions, such as `## Decisions we rejected`, recording a waiver that was asked for and refused.
- **Where:** scripts/verification-lib.sh:2074, scripts/verification-lib.sh:1062
- **Reproduced:** In the sandbox, `vf_round_authorized <fixture> opponent 4 2026-09-08T00:00:00Z` on exactly the round-2 fixture now returns 4 with "round authorization denied", where it previously returned 0. Both the authorization scanner and the input manifest are anchored on `/^## Decisions log[[:space:]]*$/`, so the two views stay in step.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** A section whose purpose is to record refused decisions no longer grants one, and the manifest hashes exactly what the authorization scanner reads.
- **Class-wide fix:** Applied at both parsers in one change. Remaining unexamined: whether a governed project outside this repository already uses a variant Decisions heading that this anchoring silently stops hashing.

### Held up / follow-up tasks

Attacked and held, with the reason each held. The HTML-comment repair itself against the spellings round 2 named: a commented waiver, a commented spec-revision, a commented task block and a commented matrix row are all suppressed now, the anchored `gate-round-end` marker is still read as data, and both sealed round digests are unchanged — the defect that remains (O-002) is the indented-code-block opener, which is a different direction, not the same spelling again. The `<details>` decision: its content renders, so a reviewer reading STATUS sees it, and I accept the recorded argument rather than gating on it. The `vf_ac_catalog`/`vf_semantic_file` asymmetry: every divergence I could construct is deny-side, and dropping an obligation is the unsafe direction, so the decision not to suppress there holds. The configuration scalar guard (O-005), tested against seven spellings including both process-substitution directions and four legal controls. The Decisions-heading anchoring (O-009). The two after-marker shapes T030o16 named, both now refused with the file:line diagnostic. The sealed-digest belt-and-braces loop, which caught every preamble shape I injected. The nested-fence grammar, which I could not defeat with an inner shorter run, the other fence character, an indented run or an unclosed opener.

Proposed follow-ups, one per class, with all known locations:

- T030o18 — Derive comment extent from the markdown instead of a token scan: add the `ind > 4` content guard to `vf_comment`, reconcile the code-span-stripping asymmetry on the closer side, add an END diagnostic for an unclosed comment, and give the three analyzer passes the shared tracker. Add indented-opener and code-span-closer negatives per parser plus a positive proving a genuinely commented finding stays uncounted. Locations: scripts/verification-lib.sh:85, :88, :92, :96, :98, :99, :101, :106, :997, scripts/sdd-analyze.sh:199, :235, :274, templates/verification-contract.md:226, :231. (O-002)
- T030o19 — Bind a resolved claim to the finding it resolves — same ID in an earlier round, or a `Prior` whose recorded class matches — or stop `resolved` from suppressing the count and reconcile the totals line instead. Replace the tests/test-gate-contracts.sh positive with a class-mismatch negative and a real same-ID cross-round positive, and cover the reality-check side. Locations: scripts/verification-lib.sh:862, :884, :895, :899, :901, tests/test-gate-contracts.sh:324, :326, :327. (O-004)
- T030o20 — Replace the whole-environment snapshot with a declared closed set, and move the already-accepted receipt check ahead of currency validation so idempotence is decided by the receipt. Locations: scripts/verification-lib.sh:1201, :1205, :1385, :1658, :1668, :1863, :1866, :1881, :2124, :2175, :2275, tests/probe-gate-contract.sh:30, :62. Open question for the user, not for the implementer: if the whole-environment snapshot is kept deliberately, AC-016's "checked at reality-check" needs restating, because the shipped checker cannot pass from a second session. (O-010)
- T030o21 — Refuse quoted content after a completed round marker as well, by testing `ended` ahead of the quoted-content skip; add fenced, commented and blockquoted preamble negatives. Locations: scripts/verification-lib.sh:926, :996, :2022, :2025. (O-008, minor, non-blocking)

O-001, O-003, O-005, O-006, O-007 and O-009 are resolved and need no follow-up; their remaining unexamined extents are recorded in their Class-wide fix fields and are not blocking.

### Escalation

Round 3 surfaced substantive new defects in two classes that were repaired twice before, and one new class the earlier rounds never reached. My reading is that the implementation approach — not the spec — is what keeps failing, with one exception. O-002 and O-004 are the same pattern the 2026-09-11 Decisions entry already diagnosed: each repair was written against the enumeration the previous report listed, and each time the next member of the set survived. Both are narrowly fixable (an indentation guard the sibling function already has; a class match on the prior record), so the decision in front of the user is whether to spend a fourth round on them or accept the residual risk with a signed waiver in STATUS Decisions — I do not author one and take no view on which. The exception is O-010, which I believe is partly a spec problem: AC-016 requires the live wiring observation to be "checked at reality-check", and with every exported environment variable in the input identity that check cannot pass from the separate invocation the gate model requires. Either the environment set narrows, or AC-016 must state what the reality-check reviewer runs instead. That half needs the user to revise the spec; the idempotence-ordering half at scripts/verification-lib.sh:1658/:1668 is an implementation fix that stands either way. I did not soften any severity to fit the round cap, and the three blocking findings remain blocking.
<!-- gate-round-end: opponent:3 -->

## Round 4
**Round:** 4
**Timestamp:** 2026-09-13T09:52:00Z
**Source:** d211df8cd94c05cd40600f1caa1b229781a6a2981892f85c2531ca91f45a2c2f
**Floor:** FLOOR-R5Mi3G
**Verdict:** CHALLENGED
**Blocking:** 3 · **Minor:** 0

### What I attacked

I took the standing question literally: do T030o18–T030o22 derive their extent from the grammar the parser reads, or do they add the spellings round 3 happened to name? I first re-derived the reviewed identity independently — `vf_gate_roots` + `vf_gate_snapshot` from this session returns exactly `d211df8c…`, byte-equal to the floor's sealed `source`, so O-010's core repair genuinely holds across invocations and the dossier is current. I then attacked each repair with inputs its enumeration does not name, in throwaway sandboxes under `$TMPDIR` by direct library calls and by `spec-gate.sh tally` on copies. Nothing was written inside the worktree; no gate, floor, round, accept, ledger, capture, task or report state was mutated, and I did not run `vf_floor_validate` or `round --complete` precisely because they `mktemp -d` inside `notes/verification/` while a reservation is live.

Reproduced this round: `vf_round_authorized` returning rc=0 on `<script>`-, `<style>`- and `<textarea>`-wrapped waivers against fence/blockquote/`<!--` controls that correctly return rc=4; the `scripts/sdd-analyze.sh:199` AC-coverage scan counting a `<script>`-hidden task and its `Refs:` while suppressing the fenced and commented twins; `vf_reports` accepting a brand-new `data-loss` finding as `Status: resolved` by copying a Class string printed in the same file, and `spec-gate.sh tally` then exiting 0 with that round contributing zero blockers under `**Verdict:** CLEARED`; and `vf_capture_check … current` returning 3 on the floor's own first capture `CAP-180-O3ksh6` after exporting one undeclared `LC_*` variable, with `integrity` still 0.

Credited as genuinely repaired after attack: T030o18's indentation guard on `vf_comment` (an indented opener now leaves the visible waiver line in force, rc=0, which is the correct reader-visible outcome) and its unclosed-comment END diagnostic at `scripts/verification-lib.sh:1050`; T030o21 — I inserted fenced, HTML-commented, blockquoted, plain-prose, `<!DOCTYPE`- and `<script>`-shaped preambles between round 1's completion marker and `## Round 2` in a copy of the real `notes/opponent.md`, and `vf_reports` refused all six at rc=3, so no shape I could find reaches `vf_report_block`'s accumulator; T030o22 — the real `notes/opponent.md` parses at rc=0 with the manifest resolved from the spec directory, and round 1's legitimate `O-006` (`Prior: O-006`, same ID and same class as `opponent-findings-2026-09-09.md`) is accepted; T030o20's closed-set decision, which now correctly ignores an arbitrary exported variable (`FOO=1` leaves the digest identical, where round 3 showed any name moved it).

Read line by line and traced for consumers: the whole `_VF_AWK_FENCE` tracker (`vf_fence`, `vf_indented`, `vf_code_close`, `vf_comment`, `vf_quoted` at `scripts/verification-lib.sh:48`–`:131`), `vf_reports` including the new `known_prior`/`priorids` manifest rule and the resolved-claim branch, `vf_report_block`, `vf_round_history`, `vf_round_authorized`, `vf_gate_round`'s completion branch and its belt-and-braces prior-digest loop, `vf_snapshot`'s environment/tool/harness/document records, `vf_floor_validate`'s per-capture loop, `vf_gate_snapshot`, `vf_gate_roots`, `vf_reject_class`, `vf_accept_audit`, the three `vf_quoted` call sites in `scripts/sdd-analyze.sh` (:201, :237, :310), and `templates/verification-contract.md:237`–`:274`. I inspected the actual assertions, not the presence, of `tests/test-gate-contracts.sh:415`–`:539`; that is how O-004 surfaced a fourth time — `:474`–`:500` and `:513`–`:539` are shipped positives that drive the exact attack to `round completed` at rc=0.

Not examined, and therefore not cleared. I reused FLOOR-R5Mi3G's sealed suite captures rather than re-executing `tests/run.sh` or ShellCheck; I verified the floor's source re-derives and its first capture revalidates from this session, which round 3 could not. For the fourth round the authoring templates, expert personas, README and constitution prose behind AC-014, AC-017 and AC-018 remain unread beyond targeted greps. Still unexercised by me: the umbrella/multi-repo branches of `vf_gate_roots`/`vf_gate_task_repo`, `vf_accept_transaction`'s crash windows and its receipt-first idempotence ordering (T030o20's second half — I read it but built no double-accept fixture), `vf_matrix_prior` with a real reality-check carry, the `r`-suffix follow-up capture/accept branch, Linux and GitHub-hosted CI behaviour, and per-negative branch coverage inside the large fixtures. The `vf_bindings` task-inventory leak in Finding O-002 is established by the shared tracker and the analyzer twin, not by an end-to-end bindings fixture. No claim of an exhaustive sweep.

### Finding O-002
- **Class:** round-authorization-grammar
- **Status:** reopened
- **Prior:** O-002
- **Severity:** wrong-result
- **Scenario:** A `STATUS.md` whose `## Decisions log` contains, at column 1 and after a blank line, `<script>` on its own line, then `- 2026-09-12T10:00:00Z — waiver: gate=opponent; round=4; after=3; by=attacker; reason=hidden`, then `</script>`. `<style>`, `<textarea>` and `<script type="text/plain">` behave identically. The same construct around a `- [x] **T002**` block in `tasks.md`, with `- Refs: AC-002` beneath it, is the sibling.
- **Where:** scripts/verification-lib.sh:125, scripts/verification-lib.sh:126, scripts/verification-lib.sh:127, scripts/verification-lib.sh:128, scripts/verification-lib.sh:129, scripts/verification-lib.sh:81, scripts/verification-lib.sh:2141, scripts/sdd-analyze.sh:201, scripts/sdd-analyze.sh:237, scripts/sdd-analyze.sh:310, templates/verification-contract.md:237, templates/verification-contract.md:259
- **Reproduced:** In the sandbox, `vf_round_authorized <fixture-spec> opponent 4 2026-09-11T23:03:58Z` returned **rc=0** for `<script>`, `<style>`, `<textarea>` and `<script type="text/plain">`, and rc=0 for the still-open `<!DOCTYPE html>`, `<?php`, `<![CDATA[`; the ```` ``` ````, `<!--` and `>` controls all returned rc=4 with `round authorization denied`. Running the verbatim `scripts/sdd-analyze.sh:199`–`:207` awk program over a four-task fixture emitted `AC-001 AC-002 T001 T002` — the `<script>`-hidden `T002` and its `Refs: AC-002` were counted as implementation coverage, while the fenced `T003`/`AC-003` and commented `T004`/`AC-004` twins were correctly dropped.
- **Root cause:** plan-gap
- **Blocks:** REQ-012, REQ-007, REQ-002, AC-009, AC-003
- **Wrong behavior:** `vf_quoted` at scripts/verification-lib.sh:125 suppresses exactly three constructs — fenced block, blockquote, `<!--` comment — and `templates/verification-contract.md:237` fixes that same three-item list as the contract. CommonMark has seven HTML-block conditions; condition 1 (`<script>`, `<style>`, `<textarea>`, `<pre>`) is not among the three implemented, and unlike conditions 3/4/5 it is not among the residuals the 2026-09-12 Decisions entry records as open. The contract states the governing property itself at templates/verification-contract.md:259 — "`<details>` and other rendered raw HTML are not suppressed: their content is **visible to a reader**, which is the property that separates a record from a hidden instruction." `<script>` and `<style>` content is rendered by no browser and is deleted outright by GitHub's HTML sanitizer, so by the contract's own stated property they must suppress, and they do not. The consequence is the granting direction twice over: REQ-012's script-enforced round cap — the control this spec exists to make "impossible, not discouraged" — is lifted by a line no reader of STATUS.md can see, and the analyzer's "every AC is covered by an implementation task" floor check, which AC-009 and REQ-007 rely on, goes green on a task that renders nowhere. This is the fourth consecutive round in which the enforced set is a spelling list rather than a derivation, and the third in which the next unnamed member of the same class survives the repair.
- **Class-wide fix:** Replace the three-item list with the CommonMark HTML-block conditions, splitting them once by the contract's own visibility property rather than adding four more token scans: conditions 1 (`<script|style|textarea|pre`), 2 (`<!--`), 3 (`<?`), 4 (`<!` + letter) and 5 (`<![CDATA[`) suppress, with condition 1 ending only on its matching close tag and conditions 6/7 (block and complete-tag HTML, `<details>` included) continuing not to, because their content is visible. `<pre>` and `<textarea>` render their content visibly, so if they are deliberately excluded, record that as a decision beside the `<details>` one rather than leaving it implicit. Apply at the single site `scripts/verification-lib.sh:125` so all nine `vf_quoted` call sites and the three `scripts/sdd-analyze.sh` passes inherit it, and update `templates/verification-contract.md:237` from an enumeration to the derivation so the two views cannot diverge again. Add per-parser negatives: `<script>`-wrapped waiver (STATUS), `<script>`-wrapped task block (analyzer AC coverage and `vf_bindings` inventory), `<style>`-wrapped stage heading (`vf_config`), plus a `<details>`-wrapped positive proving visible raw HTML is still a record. Closing this fix also closes the `<!DOCTYPE`/`<?`/`<![CDATA[` residual the Open questions line carries, which is the point of deriving instead of enumerating. Sibling extent I established by the shared tracker and the analyzer twin but did not drive end to end: the `vf_bindings` task inventory and task-field passes, and `vf_config`'s tasks.md stage scanner.

### Finding O-004
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-004
- **Severity:** wrong-result
- **Scenario:** A canonical opponent report declares `**Verdict:** CLEARED` and `**Blocking:** 0 · **Minor:** 0`, carries both required sections with real bodies, and records one brand-new finding `O-042` with `Severity: data-loss`, `Where: scripts/run.sh:9` and every other required field — but writes `Status: resolved`, `Prior: O-002`, and `Class: round-authorization-grammar`, the class string printed two lines above `O-002` in the same file.
- **Where:** scripts/verification-lib.sh:927, scripts/verification-lib.sh:941, scripts/verification-lib.sh:947, scripts/verification-lib.sh:948, scripts/verification-lib.sh:931, tests/test-gate-contracts.sh:477, tests/test-gate-contracts.sh:491, tests/test-gate-contracts.sh:494, tests/test-gate-contracts.sh:500, tests/test-gate-contracts.sh:523, tests/test-gate-contracts.sh:526, templates/verification-contract.md:266
- **Reproduced:** In the sandbox, a copy of the real `notes/opponent.md` with that round-4 block appended parsed with `vf_reports <copy> opponent <out> <real-spec-dir>` at **rc=0**, emitting `finding|4|O-042|round-authorization-grammar|resolved|O-002|data-loss|scripts/run.sh:9|…` and `round|4|…|CLEARED`, with no diagnostic. The byte-identical fixture with `Class: silent-data-loss` was refused at its exact line with `resolved finding O-042 names no prior finding of its own class and has no earlier round`, so the only thing the attack needed over round 3's refused attempt was to copy the Class as well as the ID. `spec-gate.sh tally` on the accepted fixture exited 0 and printed `opponent rounds=4`, `blocking=11 minor=4` (all eleven from rounds 1–3; round 4 contributed zero) and `class=round-authorization-grammar findings=6 recurrences=3`, so the fabricated data-loss defect is invisible both as a blocker and as a new class.
- **Root cause:** plan-gap
- **Blocks:** REQ-010, REQ-011, REQ-012, REQ-015, AC-012
- **Wrong behavior:** The wrong behavior O-004 has now named four times is unchanged in substance: a report keeps a blocking finding's full text and still reports zero blockers, and the verdict-consistency rule at scripts/verification-lib.sh:931 passes CLEARED against it. T030o19's acceptance — "`Prior` names an ID whose recorded `Class` matches this finding's `Class`" — is implemented exactly and faithfully at scripts/verification-lib.sh:947–:948, and, exactly as in round 3, it is the rule that is wrong. Class is a field the author of the finding chooses, so requiring it to match binds the claim to nothing the author does not already control; it raises the attack cost from copying one token printed in the file to copying two adjacent ones. Worse, the different-ID path it opens serves no real record in this repository: the only legitimate cross-manifest resolution in the canonical history is round 1's `O-006`, whose `Prior: O-006` is its *own* ID and which the same-ID branch already accepts through `index(priorids, " " id ":" want " ")`. The path that exists only for the attack is the one that was added. And the shipped fixtures now certify the attack twice — `tests/test-gate-contracts.sh:474`–`:500` and `:513`–`:539` construct a manifest containing only `O-041 / silent-data-loss`, inject a brand-new `O-042` `data-loss` finding with `Prior: O-041` and the copied class, and assert `round completed` at rc=0 for both `--complete` and `--reconcile` — so no fixture can catch a regression here, which is precisely what round 3 warned about.
- **Class-wide fix:** Bind the claim to its subject rather than to a class label. Require the resolved finding's own ID: accept `Status: resolved` only when `fid` appeared in an earlier round of this gate, or when `fid` itself appears in a declared prior-review manifest — drop the different-ID `Prior` branch at scripts/verification-lib.sh:947–:948 entirely, since the real `O-006` case passes without it, and verify that by re-parsing the canonical `notes/opponent.md` unchanged. The alternative the round-2 report offered is still open and strictly simpler: stop `resolved` from suppressing the count at scripts/verification-lib.sh:931 and reconcile the totals line against all recorded findings, which removes the incentive rather than the spelling. Convert `tests/test-gate-contracts.sh:474`–`:500` and `:513`–`:539` from positives into negatives asserting the refusal, and add a real same-ID cross-round positive (a round-2 report resolving a round-1 `O-00n`) plus a same-ID manifest positive modelled on the actual `O-006`. Sibling extent: the identical `finding()` path serves the reality-check gate; for a third round I built no reality-check fixture, so that side stays unexamined.

### Finding O-010
- **Class:** verification-input-identity
- **Status:** reopened
- **Prior:** O-010
- **Severity:** wrong-result
- **Scenario:** Any reviewer, gate subagent, later session or CI runner validates the sealed floor, a capture or a completed acceptance from a shell that exports one `LC_*` variable the capturing shell did not, or vice versa — `LC_CTYPE` and `LC_ALL` being the common ones (macOS Terminal's "set locale environment variables on startup", OpenSSH's default `SendEnv LANG LC_*`, and most CI base images) — against a byte-identical worktree. `PATH`, `SHELL`, `LANG` and `TMPDIR` differences have the same effect.
- **Where:** scripts/verification-lib.sh:1262, scripts/verification-lib.sh:1261, scripts/verification-lib.sh:1264, scripts/verification-lib.sh:1941, scripts/verification-lib.sh:1608, scripts/verification-lib.sh:1837, scripts/verification-lib.sh:2348, .specify/stack.yml:22
- **Reproduced:** From this session, `vf_gate_snapshot` returns `d211df8cd94c…` — byte-equal to FLOOR-R5Mi3G's sealed `source`, so the core repair holds and `FOO=1` exported changes nothing. But `LC_TELEPHONE=en_US.UTF-8 vf_gate_snapshot …` returns `18ffb99c8d4e…`, `LC_CTYPE=en_US.UTF-8` returns `c2cb76dddc53…`, `PATH="/usr/bin:$PATH"` returns `95669b2190cb…`, `SHELL=/bin/bash` returns `d6703f4d14e6…`, `LANG=C` returns `fd551dce6d40…` and stripping `TMPDIR`'s trailing slash returns `94c6980a5c02…` — six distinct identities for one unchanged tree. Driving the real predicate: `vf_capture_check <spec> CAP-180-O3ksh6 <fresh snapshot> current` returns **0** at baseline and **3** under `LC_CTYPE=en_US.UTF-8` or `LC_ALL=en_US.UTF-8`, while `… integrity` returns 0 in every case. `CAP-180-O3ksh6` is the first entry in FLOOR-R5Mi3G's `commands.nul`, so that is the first iteration of the `vf_floor_validate` loop at scripts/verification-lib.sh:1941. `.specify/stack.yml:22` declares `verification_environment: []`, so none of these names is declared by the project.
- **Root cause:** implementation-error
- **Blocks:** AC-016, AC-022, REQ-009, REQ-012
- **Wrong behavior:** The comment at scripts/verification-lib.sh:1255–:1260 states the decided contract — "The environment record is a DECLARED, CLOSED set: the variables the harness demonstrably uses, plus whatever the project declares" — and lines :1261 and :1263–:1264 implement it faithfully for the four fixed names and for `verification_environment:`. Line :1262, `compgen -e | LC_ALL=C sort | grep '^LC_'`, does not: it takes the *membership of the set itself* from the ambient environment, so an `LC_*` name nobody declared adds or removes a whole record and moves the manifest digest. That is the identical mechanism O-010 named in round 3 — an undeclared variable the surrounding process varies makes "reviewed source identity" a session fingerprint that only the originating shell can re-derive — and it carries the identical consequences: `vf_floor_validate` refuses at scripts/verification-lib.sh:1941, so a reserved round can neither be completed nor re-reserved against its floor; AC-016's live rejected-copy/intact-acceptance observation, which REQ-012 requires to be "checked at reality-check" from a *separate* invocation, fails whenever the two invocations differ by a locale variable; and the same `current` predicate degrades `vf_gate_floor`'s reuse path at :1837 and `vf_matrix_evidence` at :2348 to full re-execution, which is the MET-006 reuse claim. It happens not to bite this reservation only because this session's locale environment coincides with the invoker's; the repair closed the set for every name except the one family the harness never reads. Separately, `PATH` is hashed whole at :1261 even though the `tool` records at :1276–:1281 already pin each declared tool's resolved absolute path and content digest, so a reordered or extended `PATH` invalidates every capture while proving nothing extra.
- **Class-wide fix:** Make line :1262 read the declaration, not the environment: take `LC_*` names from `verification_environment:` like every other project-declared variable, or fix the family to a closed literal list (`LC_ALL LC_CTYPE LC_COLLATE LC_NUMERIC LC_TIME LC_MESSAGES`) recorded `present`/`unset` so a name's absence is itself a stable record rather than a missing one — the `unset` branch at :1268 already has the right shape for this and is simply never reached for undeclared names. Decide `PATH` explicitly: either drop it, since `tool` and `harness` records already establish binary identity, or record why hashing it is required, with the same named-diagnostic discipline. Add a fixture that seals a capture, re-validates it from a subshell with an extra `LC_*` variable exported and with a reordered `PATH`, and asserts `current` still returns 0 — the cross-invocation property AC-016 depends on and that no current fixture exercises. Sibling extent I read but did not execute: `vf_manual_current`, `vf_matrix_evidence`'s capture check at :2348, and T030o20's second half — the receipt-before-currency reordering in `vf_accept_transaction` — for which I built no double-accept fixture, so idempotence under a changed environment is unexamined for a second round.

### Escalation

Round 4 raises no new stylistic objection and re-litigates nothing closed: T030o18's indentation guard, T030o21 and T030o22 were attacked and held, and T030o20's closed-set decision holds for every name but one family. But three findings above are the fourth consecutive appearance of two classes, and the pattern is now the finding. In each round the repair encoded the previous report's *named rule* — "suppress fences, blockquotes and comments", "accept a `Prior` whose Class matches", "hash a declared closed set" — and in each round the next member the enumeration did not name survived: fences → comments → indented openers → `<script>`; `Prior: none` → fabricated `Prior` → unrelated real `Prior` → real `Prior` with copied Class; every exported variable → every undeclared `LC_*`. My reading is that the **implementation approach** is wrong, not the spec: REQ-010 already demands class-wide repair with established extent, and REQ-011/REQ-015 already demand that counts reflect recorded findings, so no spec revision is needed — what fails is that each follow-up's acceptance criterion is written as the set of examples the prior report listed, which guarantees the criterion is satisfiable without the class being closed, and O-004 additionally shows the criterion itself can be the defect while a shipped fixture certifies it. The user arbitrates from here. The decision I would put to them is whether a fifth round is spent, or whether T030o23–T030o25 are required to state their extent as a *derivation with its source cited* (the CommonMark HTML-block conditions; the finding's own ID; the declaration file) and to convert the certifying positives into negatives before any further round is reserved. I do not recommend accepting the risk with a waiver on O-002 or O-004: the first disarms the script-enforced round cap that this spec's own 2026-09-04 Decisions entry says "must be impossible, not discouraged", and the second lets a gate report carry a data-loss defect in full and canonize CLEARED.

### Held up / follow-up tasks

Held up under attack, and why: T030o21 — six preamble shapes (fenced, HTML-commented, blockquoted, plain prose, `<!DOCTYPE`-wrapped, `<script>`-wrapped) inserted between round 1's completion marker and `## Round 2` in a copy of the real canonical report were all refused at rc=3, because every `next`-rule above the catch-all now guards `ended` and the `vf_quoted` branch at scripts/verification-lib.sh:955 checks the marker before consuming the line, so no shape I found reaches `vf_report_block`'s accumulator. T030o22 — the real `notes/opponent.md` parses at rc=0 with the manifest resolved from the spec directory, and the same resolution is exercised on the temporary completion and reconciliation paths by `tests/test-gate-contracts.sh:474` and `:513`. T030o18's indentation guard — an indented `<!--` no longer swallows the visible line beneath it, and the unclosed-comment END diagnostic exists at scripts/verification-lib.sh:1050. T030o20's closed set — an arbitrary undeclared variable no longer moves the identity, and the floor's sealed source re-derived exactly from this independent session, which is the cross-invocation property round 3 could not obtain.

- T030o23 — O-002: derive `vf_quoted`'s suppressed set from the CommonMark HTML-block conditions at scripts/verification-lib.sh:125, splitting on the contract's own reader-visibility property (conditions 1–5 suppress, 6–7 do not), update templates/verification-contract.md:237 from enumeration to derivation, and sweep every consumer: scripts/verification-lib.sh:2141 (`vf_round_authorized`), scripts/sdd-analyze.sh:201/:237/:310, and the `vf_bindings` inventory, task-field and `vf_config` stage scanners. Negatives per parser plus a `<details>` positive. Closing this also closes the `<!DOCTYPE`/`<?`/`<![CDATA[` Open-questions residual.
- T030o24 — O-004: drop the different-ID `Prior` branch at scripts/verification-lib.sh:947–:948 so a resolved claim requires the finding's own ID in an earlier round or in a declared manifest (or, alternatively, stop `resolved` suppressing the count at :931), prove the real `O-006` still parses, and convert tests/test-gate-contracts.sh:474–:500 and :513–:539 from positives certifying the attack into negatives, adding a same-ID cross-round positive and a same-ID manifest positive.
- T030o25 — O-010: replace the ambient `compgen -e | grep '^LC_'` at scripts/verification-lib.sh:1262 with declared or closed-literal `LC_*` membership recorded `present`/`unset`, decide `PATH` explicitly against the existing `tool`/`harness` records, and add the cross-invocation fixture that re-validates a sealed capture from a subshell with an extra `LC_*` and a reordered `PATH` still returning `current` rc=0.
<!-- gate-round-end: opponent:4 -->
## Round 5
**Round:** 5
**Timestamp:** 2026-09-14T16:54:04Z
**Source:** cee79ffc77267c915a38f41ea7a5b1f0303a2074aa9f29b2600d6224b058fcbb
**Floor:** FLOOR-bVcJIO
**Verdict:** CHALLENGED
**Blocking:** 3 · **Minor:** 0

### What I attacked

I re-derived the current floor source independently and obtained `cee79ffc…` under the baseline environment, extra undeclared locale/session variables, and reordered `PATH`, so the supplied floor is current and T030o25's runtime identity repair genuinely survives a separate process. I inspected the actual assertions behind current captures CAP-205, CAP-207, CAP-212, CAP-218 and CAP-219, especially `test_rounds`, `test_reports_and_tally`, `test_verification_bindings`, `test_capture_provenance` and `test_instruction_contracts`, then attacked the rules those assertions omit with isolated fixtures under `/private/tmp`.

The three reopened classes still fail outside their happy-path examples: condition-1 raw HTML loses which tag opened the block; resolved-finding validation treats an old ID as sufficient even when its stable Class is replaced; and the authoritative verification contract simultaneously states the removed fixed-environment rule and its declaration-only replacement. I did not rerun the already-current full suite or ShellCheck, and I did not exercise the live reality-check path, umbrella roots, acceptance crash windows, Linux/CI, or a real carried matrix; reality-check remains at zero actual rounds and is not cleared by its fixtures.

### Finding O-002
- **Class:** round-authorization-grammar
- **Status:** reopened
- **Prior:** O-002
- **Severity:** wrong-result
- **Scenario:** In `STATUS.md`, start a CommonMark condition-1 block with `<script>`, place `</style>` on the next line, then a syntactically valid round-5 waiver, and finally `</script>`. The mismatched `</style>` is script content, so the HTML block remains open and no reader can act on the waiver, but the parser ends suppression there.
- **Where:** scripts/verification-lib.sh:150, scripts/verification-lib.sh:158, scripts/verification-lib.sh:167, scripts/verification-lib.sh:175, scripts/verification-lib.sh:201, scripts/verification-lib.sh:560, scripts/verification-lib.sh:647, scripts/verification-lib.sh:839, scripts/verification-lib.sh:947, scripts/verification-lib.sh:1021, scripts/verification-lib.sh:2173, scripts/verification-lib.sh:2219, scripts/verification-lib.sh:2371, scripts/sdd-analyze.sh:201, scripts/sdd-analyze.sh:237, scripts/sdd-analyze.sh:310, tests/test-spec-gate.sh:650, templates/verification-contract.md:243
- **Reproduced:** In `/private/tmp/sdd-opponent-r5-html.DrxibR`, direct `vf_round_authorized` calls returned `mismatched rc=0`, while the control with the waiver before the matching `</script>` returned `hidden rc=4`; an unquoted waiver after a matching close returned `visible rc=0`. Current tests cover each opener only with its matching closer, so CAP-212/CAP-218 remain green.
- **Root cause:** implementation-error
- **Blocks:** REQ-012, REQ-010, AC-009, AC-012
- **Wrong behavior:** `vf_raw_start` collapses all four condition-1 tags to integer kind `1`, and `vf_raw_end` ends that kind on any `</script|style|textarea|pre>`. This contradicts T030o23 and the authoritative contract's explicit “matching close tag” rule, letting an invisible waiver lift the script-enforced round cap. Every `vf_quoted` consumer inherits the same premature end, so hidden task, report, manifest, stage and matrix records can become live after a mismatched closer.
- **Class-wide fix:** Preserve the normalized condition-1 opener tag in raw-block state and end suppression only on its corresponding close tag. Add the pairwise mismatched-close matrix for all four tags at the shared tracker, plus authorization and task/report consumer fixtures; keep the existing matching-close and `<details>` controls. The other consumer paths listed above remain affected until that shared state is repaired.

### Finding O-004
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-004
- **Severity:** wrong-result
- **Scenario:** A new round reuses historical finding ID `O-001` but changes its Class from `return-envelope-parsing` to `silent-data-loss`, records a concrete `data-loss` defect as `Status: resolved`, and declares `Verdict: CLEARED` with zero blockers. The ID exists earlier, but the finding is not the same subject because its supposedly stable Class has changed.
- **Where:** scripts/verification-lib.sh:963, scripts/verification-lib.sh:965, scripts/verification-lib.sh:975, scripts/verification-lib.sh:977, scripts/verification-lib.sh:980, scripts/verification-lib.sh:996, scripts/verification-lib.sh:1128, tests/test-gate-contracts.sh:234, tests/test-gate-contracts.sh:470, tests/test-gate-contracts.sh:551, templates/verification-contract.md:271, .specify/specs/003-gate-round-reduction-and-token-discipline/spec.md:245, .specify/specs/003-gate-round-reduction-and-token-discipline/tasks.md:564
- **Reproduced:** In `/private/tmp/sdd-opponent-r5.hlW4EV`, `vf_reports` accepted the augmented real canonical history at `rc=0` and emitted `id=O-001|class=silent-data-loss|status=resolved|severity=data-loss`. Running `vf_tally` on that accepted fixture returned `rc=0`, kept `blocking=14` rather than adding the round-5 data-loss blocker, and printed `class=silent-data-loss findings=1 recurrences=0`; the round can therefore contribute zero blockers and claim CLEARED.
- **Root cause:** plan-gap
- **Blocks:** REQ-010, REQ-011, REQ-012, REQ-015, AC-010, AC-012
- **Wrong behavior:** T030o24 removed the different-ID `Prior` escape but equated “same ID” with “same finding” without enforcing the stable Class that REQ-015 requires. `lastseen` stores only the round number, and `known_prior` ignores the recorded manifest Class, so a report author can copy any historical ID, assign it to a different defect class, mark the new blocker resolved, and suppress both the blocker count and recurrence. The test's same-ID positive proves only unchanged-Class reuse and has no class-drift negative.
- **Class-wide fix:** Record the first Class associated with every finding ID from earlier rounds and prior-review manifests, reject any later reuse of that ID with a different Class for every status, and require the same ID/Class pair for resolution. Add class-drift negatives for opponent and reality-check parsing, `--complete`, `--reconcile` and tally, while retaining same-ID/same-Class positives including real O-006.

### Finding O-010
- **Class:** verification-input-identity
- **Status:** reopened
- **Prior:** O-010
- **Severity:** wrong-result
- **Scenario:** A project has a reusable check whose result depends on `LANG`. Its author follows the authoritative contract at lines 134–139, which says `LANG` is always included, so leaves `verification_environment: []`; the check is captured under one locale and later relied on under another. The implementation follows the contradictory lines 286–299 and ignores undeclared `LANG`, permitting reuse.
- **Where:** templates/verification-contract.md:134, templates/verification-contract.md:136, templates/verification-contract.md:138, templates/verification-contract.md:286, templates/verification-contract.md:287, templates/verification-contract.md:291, scripts/verification-lib.sh:1341, scripts/verification-lib.sh:1345, tests/test-gate-contracts.sh:40, tests/test-verification.sh:313, .specify/specs/003-gate-round-reduction-and-token-discipline/tasks.md:574
- **Reproduced:** `templates/verification-contract.md:136` says, verbatim, “The snapshot always includes PATH, SHELL, LANG, TMPDIR and exported LC_* variables,” while line 287 says membership is exactly the declaration and nothing beside it. Independently running `vf_gate_snapshot` under baseline, `LC_UNKNOWN_CATEGORY=fixture LANG=sv_SE.UTF-8 SHELL=/bin/zsh` with an alternate `TMPDIR`, and reordered `PATH` returned the identical current identity `cee79ffc…` in all three cases. CAP-205 still passes because `tests/test-gate-contracts.sh:40` asserts only that the new phrase exists and never rejects the contradictory old rule.
- **Root cause:** implementation-error
- **Blocks:** REQ-009, AC-018, AC-020
- **Wrong behavior:** T030o25's runtime rule is sound, but its named authoritative documentation remains false in the dangerous direction: it tells users fixed variables are already inputs, so a dependent check can omit the required declaration and receive an unsound reusable PASS after that variable changes. This also violates T030o25's explicit acceptance that no fixed name list exists beside `verification_environment:` and AC-018's requirement to explain freshness correctly.
- **Class-wide fix:** Replace lines 134–139 with the declaration-only rule and the requirement to declare every result-affecting variable; retain the explanatory rationale at lines 286–299. Strengthen `test_instruction_contracts` to reject the superseded fixed-name claim, not merely search for the replacement phrase, and sweep active documentation for equivalent claims. Historical task text may remain historical if clearly superseded.

### Escalation

Round 5 again finds substantive defects in the implementation approach, not a need to weaken the spec. O-002 diverges from the correctly stated matching-close criterion, O-004 shows that the new derivation still failed to bind ID to the spec-required stable Class, and O-010 is an incomplete propagation of the accepted declaration-only decision. The implementation should be reworked before reality-check; if the user accepts these risks instead, that requires an explicit signed waiver in STATUS Decisions and cannot substitute for the still-unrun independent reality-check.

### Held up / follow-up tasks

Held up under attack: FLOOR-bVcJIO's source re-derived exactly across three independent environment shapes; undeclared environment changes and reordered `PATH` no longer alter runtime identity; declared-only environment hashing and current provenance tests are real. T030o24's different-ID and copied-Class `Prior` attacks are now refused on both gates, the canonical O-006 manifest resolution still parses, and T030o23 correctly suppresses the tested matching-close condition-1 blocks plus conditions 3–5 while retaining the `<details>` and inline-code positives. O-001, O-003 and O-005 through O-009 had no new contrary evidence and were not re-litigated.

- T030o26 — O-002: preserve the condition-1 opener tag through `vf_quoted`, require its corresponding close, and add pairwise mismatched-close attacks across the shared consumers.
- T030o27 — O-004: enforce stable ID-to-Class identity across rounds/manifests and add class-drift negatives for both gates, completion/reconciliation and tally.
- T030o28 — O-010: remove the superseded fixed-environment paragraph and make the instruction test reject contradictory membership rules.
<!-- gate-round-end: opponent:5 -->

## Round 6

**Round:** 6
**Timestamp:** 2026-09-16T00:40:00Z
**Source:** 73202d83b57a0c05d1888f969a114d8ad9b15357704900179b815ce5d8cc8f1c
**Floor:** FLOOR-b0sLmN
**Verdict:** CHALLENGED
**Blocking:** 2 · **Minor:** 2

### What I attacked

I derived each of the three repaired classes from the grammar the parser actually executes rather than from the examples round 5 listed, then attacked the member adjacent to the one that was named. For O-004 I read the tally expression at `scripts/verification-lib.sh:1000` and observed that the repair bound `Class`, which the tally never reads, while leaving `Severity`, which decides blockers against minors, unbound across rounds; I reproduced the bypass end to end under `/private/tmp/opp6`. For O-010 I stopped treating `templates/verification-contract.md` as the class and grepped every current authoring and record artifact for the superseded fixed-environment membership, finding two live survivors the file-scoped `assert_not_contains` guards cannot see. For O-002 I traced the waiver split arithmetic myself against `STATUS.md:209`, confirmed the six-field skip, and then searched for an accept-side dual by walking every clause of the field grammar; I found none, so I judged it degraded rather than adopting the invoker's framing on trust. I also probed the report parser's per-round singleton handling and found the totals line unprotected by the duplicate guard its sibling identity fields carry. I re-ran nothing the floor already sealed; every execution below is a fresh attack under `/private/tmp`.

### Finding O-004
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-004
- **Severity:** wrong-result
- **Scenario:** Round 1 of an opponent report records finding O-011 with Class `tier-binding`, Status `new`, Severity `data-loss`, verdict CHALLENGED. Round 2 re-records the SAME id with the SAME Class, Status `reopened`, and Severity changed to `degraded`, declaring totals of zero blocking and one minor with verdict CLEARED. The defect is explicitly still open; only the author-controlled severity token moved one tier.
- **Where:** `scripts/verification-lib.sh:1000`, `scripts/verification-lib.sh:988`, `scripts/verification-lib.sh:1035`, `.specify/specs/003-gate-round-reduction-and-token-discipline/spec.md:199`
- **Reproduced:** Built that exact two-round report under `/private/tmp/opp6/spec/notes/opponent.md` and ran `vf_reports` against it directly; rc=0, no diagnostic. `spec-gate.sh tally /private/tmp/opp6/spec` then printed `blocking=1 minor=1 ... reopened=1`, confirming the tool itself records the finding as reopened in the same breath that it lets the round-2 CLEARED verdict validate. The round-5 Class guard at line 988 never fires because the Class is unchanged; line 1000 reads only `sev`.
- **Root cause:** plan-gap
- **Blocks:** AC-012, REQ-011
- **Wrong behavior:** REQ-011 states at `spec.md:199` that severity never changes merely to meet a round or cost target, and `spec.md:289` names lowering severity as the first way a gate could fake satisfaction. The repair hardened `Class`, which is inert in the tally, and left `Severity`, the sole input to the blocking count at line 1000, free to drift downward for a finding ID the validator already knows. A reopened data-loss defect is therefore tallied as a minor and `blockers==wantb==0` lets `**Verdict:** CLEARED` pass the check at line 1035. This is the same outcome round 5 blocked, reached through the sibling field in the same statement, and no executable negative covers it: AC-012's "Text tests check these rules" is satisfied by prose while the class stays open.
- **Class-wide fix:** Bind the tally tier the way Class is bound. Record each finding ID's first observed severity tier (data-loss/wrong-result/regression/crash versus minor/degraded) in the same `firstclass` pass at `scripts/verification-lib.sh:1003`, and reject any later observation of that ID that lowers the tier while its status is not `resolved`. Stated class-wide: every author-controlled token the tally or the verdict check reads must be history-bound across the gate, not only the token a prior round happened to name.

### Finding O-010
- **Class:** verification-input-identity
- **Status:** reopened
- **Prior:** O-010
- **Severity:** wrong-result
- **Scenario:** An implementer or reviewer opens the accepted task record for T030o25 in `tasks.md`, or the dossier README a reviewer is pointed at, to learn what the snapshot hashes. Both still state the superseded fixed-environment membership, so the reader omits PATH, SHELL, LANG, TMPDIR or an LC_ name from `verification_environment:` believing the snapshot covers them, and opts a check into reuse. The check then reuses a PASS across an environment change that did affect its result.
- **Where:** `.specify/specs/003-gate-round-reduction-and-token-discipline/tasks.md:531`, `.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/dossier/README.md:66`, `tests/test-gate-contracts.sh:42`, `scripts/verification-lib.sh:1354`
- **Reproduced:** A repo-wide grep for the superseded phrasing over current `.md` and `.sh` sources, excluding sealed capture copies, returns two live authoring artifacts. `tasks.md:531` reads, verbatim, that `vf_snapshot` hashes "a project `verification_environment:` list plus PATH, SHELL, LANG, LC_* and TMPDIR" — and that sentence is the *Acceptance* line of the very task that removed the rule. `notes/verification/dossier/README.md:66` reads "`verification_environment:`; PATH, SHELL, LANG, TMPDIR and the LC_* family". The round-5 guards at `tests/test-gate-contracts.sh:42-43` assert absence only within `$contract`, which is `templates/verification-contract.md`, so both survivors pass every test in the suite the floor sealed.
- **Root cause:** plan-gap
- **Blocks:** AC-012, REQ-009
- **Wrong behavior:** The class round 5 named is "an authoritative statement of the superseded fixed-environment rule stands beside its declaration-only replacement, so a user omits a required declaration and gets an unsound reusable PASS." The repair corrected one line and bound the regression guard to that one file handle, so the class was closed at exactly one member. `tasks.md:531` is worse than the line that was fixed: it is the recorded acceptance criterion of a `[x]` task, so the spec's own record now certifies behavior the code does not implement, and this spec's standing rule is that the record outranks warm proof.
- **Class-wide fix:** Make the absent-phrase assertion class-wide instead of file-scoped. Replace the two `assert_not_contains "$contract" ...` guards with a repo-wide scan asserting the superseded membership phrasing appears in no current authoring or record artifact — templates, plan, tasks, the dossier README, skills and agent files — excluding only sealed capture copies and the historical opponent reports that quote it as evidence. Generally: when a contract sentence is superseded, the guard binds to the phrase across the repository, not to the one file the report cited.

### Finding O-002
- **Class:** round-authorization-grammar
- **Status:** reopened
- **Prior:** O-002
- **Severity:** degraded
- **Scenario:** An operator writes a round-6 waiver whose reason text contains a semicolon followed by a space — ordinary English punctuation, and the form two other Decisions entries already use. `vf_round_authorized` splits the body on that separator, reads six fields where it requires five, and skips the entry with no output. At the next reservation the operator is told only that an exact-round waiver is needed, never that the entry they just wrote is the malformed one or which clause failed, and nothing in the repository lets them validate a waiver at authoring time.
- **Where:** `scripts/verification-lib.sh:2244`, `scripts/verification-lib.sh:2245`, `scripts/verification-lib.sh:2247`, `scripts/verification-lib.sh:2261`, `.specify/specs/003-gate-round-reduction-and-token-discipline/STATUS.md:209`
- **Reproduced:** Ran the library's own split arithmetic over `STATUS.md:209` in isolation. It yields six fields: `gate=opponent`, `round=6`, `after=5`, `by=user`, `reason=explicitly requested opponent round 6 with budgeted tokens without reducing intelligence or performance`, and a sixth field `review O-002 O-004 O-010 repairs and affected consumers with a 16000-token working target and full reasoning`. The guard at line 2245 takes `next`, and the independent clause at line 2247 would reject it anyway. I then walked every clause of the field grammar looking for the accept-side dual: any "; " inside gate, round, after or by shifts the count off five, a five-field parse still requires `f[1..4]` to match the gate, round and predecessor exactly with `by=[^;]+`, and omitting a field to restore the count of five leaves `f[4]` failing the `by=` pattern. I could not construct an entry that parses when it should not.
- **Root cause:** implementation-error
- **Blocks:** REQ-012
- **Wrong behavior:** No gate decision is wrong — the failure direction is fail-closed and the round cap held, which is why this is degraded and not a blocker. What is wrong is that a malformed authorization is discarded with no diagnostic at line 2261 naming the offending line or clause, so the operator's only feedback is indistinguishable from having written no waiver at all. The recorded cost of that silence on this spec was a false handoff claim that round 6 was already authorized and a cold floor re-execution.
- **Class-wide fix:** Stop making rejection silent in this grammar. Every `next` in the awk block at `scripts/verification-lib.sh:2241-2250` should record the line number and the clause that failed, and line 2261 should print those candidates alongside the denial. Add a `waiver --check` entry point so an authorization is validated against the grammar when it is written rather than at the next reservation. Class-wide: a fail-closed parser that names nothing converts an authoring error into an unexplained refusal, and this grammar has now produced that outcome on a real operator.

### Finding O-011
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** degraded
- **Scenario:** A canonical opponent round carries the totals line in its template position reading three blocking and two minor, and a second totals line further down the same round reading zero and zero. The parser keeps only the last assignment, so the enforced totals are zero and zero while every reader sees three blocking findings above a CLEARED verdict.
- **Where:** `scripts/verification-lib.sh:1076`, `scripts/verification-lib.sh:1035`, `scripts/verification-lib.sh:1061`
- **Reproduced:** Built that single-round report under `/private/tmp/opp6b/spec/notes/opponent.md` with the header totals set to three and two and a trailing totals line of zero and zero, and ran `vf_reports` against it; rc=0, no diagnostic. The identity fields one rule above, at line 1061, do carry a `seenfield` duplicate guard and would have rejected a repeated Round, Timestamp, Source, Floor, Date or Verdict line; the totals rule at 1076 has no equivalent.
- **Root cause:** implementation-error
- **Blocks:** AC-012
- **Wrong behavior:** AC-012 requires the report to carry the blocking and minor counts as part of its canonical record, and the validator at line 1035 exists to make the declared totals agree with the findings. Because the last occurrence silently wins, the required record is ambiguous: the machine-checked totals and the reader-visible totals can disagree within one sealed round, and the emitted round record carries neither. It cannot by itself change a gate decision, since the surviving totals must still equal the real counts and the verdict check reads the real counts, which is why this is degraded.
- **Class-wide fix:** Apply the `seenfield` uniqueness the identity fields already have at line 1061 to the totals rule at line 1076, and audit the remaining per-round singletons the validator reads for the same omission. Class-wide: any field the round validator reduces to one value must reject a second occurrence rather than let the last write win.

### Held up / follow-up tasks

The O-002 condition-1 repair held up under attack. Requiring the opener's own close tag makes the block end strictly later than CommonMark does, so it over-suppresses rather than under-suppresses, and I could not construct a report or STATUS entry where the extra suppression is accept-side: an unclosed raw block in a report leaves the completion marker unseen and `flush` rejects the round, and a suppressed line after a marker still trips the content-after-marker rule. The mismatched-close matrix at `tests/test-gate-contracts.sh:265-274` asserts the suppression flags rather than an exit code, so it is a genuine negative and not the positive-fixture trap round 4 recorded; I found no new positive fixture asserting an attack succeeds at rc=0 in the round-5 additions. The O-004 Class guard itself also held: I could not defeat it by reordering rounds, by same-round duplication, or through the prior-review manifest path, which is why my O-004 finding routes around it through severity instead. The kind 3, 4 and 5 raw-HTML branches are implemented and internally consistent despite being recorded as residual, and the string-versus-integer kind values do not collide in the awk comparisons. I did not re-examine the `<details>` decision, which is recorded as deliberate, and I did not reach the standing unexamined surfaces — `vf_bindings`, `vf_config`'s stage scanner, umbrella `vf_gate_roots`, `vf_accept_transaction` crash windows, `vf_matrix_prior` with a real carried reality-check, or Linux behaviour — so they remain unattacked, not cleared.

Proposed follow-ups: T030o29 — bind each finding ID's first severity tier across the gate and reject a non-resolved downgrade, mirroring the Class rule, with executable negatives per lifecycle status (Finding O-004). T030o30 — replace the file-scoped superseded-phrase assertions with a repo-wide absence scan and correct `tasks.md:531` and the dossier README, recording the tasks.md correction as a record repair rather than a criterion change (Finding O-010). T030o31 — emit a line-numbered, clause-named diagnostic for every rejected authorization candidate and add an authoring-time waiver check (Finding O-002). T030o32 — reject a duplicate totals line and audit the remaining per-round singletons (Finding O-011).

<!-- gate-round-end: opponent:6 -->

## Round 7

**Round:** 7
**Timestamp:** 2026-09-16T17:25:35Z
**Source:** 340518360ced516cd6201716bc8805c982956e80a11a8da497f1028164d8a14c
**Floor:** FLOOR-qstcrp
**Verdict:** CHALLENGED
**Blocking:** 2 · **Minor:** 2

### What I attacked

I read each of the four round-6 repairs out of the code that executes, wrote down the grammar that code actually reads, and then attacked the member of that grammar the repair did not name — never the spellings round 6 listed. For T030o29 I read the blocking count at `scripts/verification-lib.sh:1013` and observed that it is one predicate over two author-written tokens, `Status` and `Severity`; the repair bound `Severity` and wrote `status!="resolved"` into its own new guard at :1023 as an exemption, so I attacked `Status`. For T030o30 I ran the shipped scan expression verbatim, first against the worktree (clean) and then against a tree carrying the same superseded claim in the spellings this repository itself produces. For T030o31 I enumerated every clause of the waiver grammar and checked which ones call `note()`. For T030o32 I looked for the remaining per-round singletons the validator reduces to one value, which led me off `vf_reports` entirely and into the reality-check gate, where the round verdict is parsed a second time by a different grammar — the first defect this gate has recorded in `vf_reality_matrix`, and the gate that has never run.

Everything below was executed under `/private/tmp/opp7/work` with `TMPDIR` under `/private/tmp/opp7`. Nothing inside the worktree was created, modified, moved or removed; no floor, round, checkpoint, accept, capture, ledger or task state was touched, and I ran no `spec-gate.sh round`, `accept`, `floor` or `checkpoint`. The one heavy reproduction copies `notes/opponent.md`, `notes/verification/reports/` and `notes/verification/rounds/` out of the spec and mutates only the copy.

Attacked and held, and therefore credited: T030o29's severity-tier binding itself, which correctly refuses a CLEARED round resting on a lowered tier and correctly permits an honest re-characterisation inside a CHALLENGED round — I could not defeat it by manifest ordering, by reordering rounds, or by an upgrade-then-downgrade sequence, because `firsttier` is written once per ID and the manifest pass takes the strictest tier. T030o32's duplicate-totals guard, which I could not bypass with a second totals line, a split `**Blocking:**`/`**Minor:**` pair, a reversed pair, or a preamble totals line before the first round heading, and which does not collide with the identity-field `seenfield` keys. T030o30's correction of `tasks.md:531`, which now reads as a record repair naming T030o25 as superseding it, and `templates/verification-contract.md:134-139`, which now states the declaration-only rule — the repo-wide scan returns empty against the live tree. T030o31's six noted clauses, each of which names the STATUS.md line and the failing clause exactly as promised, including the round-6 semicolon case.

Not reached, and therefore not cleared: umbrella and multi-repo `vf_gate_roots`/`vf_gate_task_repo`; `vf_accept_transaction`'s crash windows (I read it and note that `COMMITTED` at `scripts/verification-lib.sh:1861` and :1906 is the one write in an otherwise atomic transaction that is not staged through a temp file and rename, so a crash mid-write leaves a receipt that fails closed with no scripted recovery — I built no crash fixture and do not raise it as a finding); `vf_matrix_prior` with a real carried reality-check round; the `r`-suffix follow-up branch; Linux and CI behaviour; per-negative branch coverage inside the large fixtures; AC-014, AC-017 and AC-018 prose beyond targeted greps; and no end-to-end fixture for `vf_bindings`' two task passes or `vf_config`'s stage scanner. I did not re-run `tests/run.sh` or ShellCheck; I read the assertions rather than the results.

Known-open items I confirmed rather than rediscovered, with what they now measure. A round can still reach CLEARED by omitting a known open finding entirely: unlisted IDs are not counted and `firsttier` is only consulted for IDs the round records, so omission costs nothing — Finding O-004 below is strictly worse than omission because the report keeps the defect's full text. The reality-check gate still enforces no totals: `scripts/verification-lib.sh:1059`, :1060 and :1061 are all `gate=="opponent"`, so a reality-check round's declared counts, its verdict-versus-blockers agreement and the new downgrade guard are unchecked; the partial compensation is `vf_reality_matrix`, whose READY rule is the only semantic check that side has — and Finding O-012 disables it. The O-002 residual `<!DOCTYPE`/`<?`/`<![CDATA[` suppressed extent is implemented and covered by negatives at `tests/test-spec-gate.sh:690-692`. The README still shows no return-block grammar, and I add to that: it now also shows no `waiver` subcommand, which is part of Finding O-002.

### Finding O-004
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-004
- **Severity:** wrong-result
- **Scenario:** Round 7 of this gate records O-002, O-004, O-010 and O-011 — the four findings round 6 left open — each with its bound Class, its bound severity tier unchanged, every required field present and a Scenario that says in plain words "reproduces exactly as recorded in round 6; nothing was repaired". The only token that moves is `Status`, set to `resolved`. The round declares `**Blocking:** 0 · **Minor:** 0` and `**Verdict:** CLEARED`.
- **Where:** scripts/verification-lib.sh:1013, scripts/verification-lib.sh:1023, scripts/verification-lib.sh:1012, scripts/verification-lib.sh:1060, tests/test-gate-contracts.sh:286, tests/test-gate-contracts.sh:288, tests/test-gate-contracts.sh:456, tests/test-gate-contracts.sh:458
- **Reproduced:** Copied the real `notes/opponent.md`, `notes/verification/reports/` and `notes/verification/rounds/` to `/private/tmp/opp7/work/wv3`, appended exactly that round-7 block to the copy, and ran `vf_reports <copy> opponent <out> <copy-spec>`: **rc=0, no diagnostic**, emitting `finding|7|O-002|round-authorization-grammar|resolved|O-002|wrong-result|…` for all four and `round|7|…|FLOOR-qstcrp|CLEARED|canonical`. `vf_tally` on the same copy returned rc=0 and printed `blocking=19 minor=6` — every one of those from rounds 1-6, round 7 contributing zero — `reopened=20` unchanged, and `severity-downgrades=1`, which is round 6's own honest O-002 re-characterisation and not my four suppressions: the measurement T030o29 added so that no downgrade is silent cannot see this bypass at all. A minimal two-round control at `/private/tmp/opp7/work/s1` (round 1 records O-002 `new`/`wrong-result` under CHALLENGED, round 2 re-records the same ID `resolved`/`wrong-result` under CLEARED with zero totals) gives the same rc=0 and `blocking=1 minor=0`.
- **Root cause:** plan-gap
- **Blocks:** REQ-010, REQ-011, REQ-015, AC-012
- **Wrong behavior:** REQ-011 requires the report's counts to reflect its recorded findings and says severity never moves to meet a round target; REQ-015 requires findings to keep their class accounting across rounds. The blocking count at `scripts/verification-lib.sh:1013` is a single predicate over exactly two author-written tokens — `status!="resolved"` selecting whether the finding counts at all, and `sev` selecting which bucket. Round 6 attacked and round 6's repair bound the second. The first was not merely left alone: T030o29 wrote `status!="resolved"` into its own new guard at :1023 as an explicit exemption, so the token that suppresses the count is the token the new guard declines to inspect, in the same statement, one line apart. The outcome is the one O-004 has now named six times and is quantitatively the worst instance yet — a gate report that reproduces four open defects in full, at their true severities, and validates at zero blockers under CLEARED. And the class is now certified by shipped positives in the same commit: `tests/test-gate-contracts.sh:286-289` asserts at rc=0 that round 2 re-recording `G-042` as `resolved` at the same `data-loss` tier under CLEARED must be accepted — byte-for-byte the shape of this attack, distinguished from it only by the comment calling it "a genuine fix" — and `:456-458` asserts rc=0 for a four-round lifecycle in which round 3 is `resolved`/CLEARED/zero-blockers and round 4 reopens the very same finding, which is a canonical example of a false resolution clearing a round, blessed as the expected lifecycle. This is the positive-fixture trap round 4 recorded twice, reappearing in the repair for the finding that recorded it.
- **Class-wide fix:** Derive the extent from the predicate the parser evaluates, not from the field a report named. The tokens the blocking count at :1013 and the verdict agreement at :1060 depend on are exactly `Status` and `Severity`, read off that one expression. `Severity` is bindable to history because the gate has seen the ID before; `Status: resolved` is not — it asserts a repair that no data available to `vf_reports` can corroborate, which is why binding it "the way Class is bound" is not available and why the round-2 alternative is the sound one: stop `resolved` from suppressing the count at :1013, count every recorded finding at its recorded tier, and reconcile the declared totals and the verdict against that. A report then states a resolution as a claim without being paid for it. If suppression is kept instead, the minimum is that a CLEARING verdict may not rest on a `resolved` observation of an ID an earlier round of this gate recorded `new`, `open` or `reopened` — the same "the guard binds where the attack lands" shape T030o29 chose for severity. Either way the two shipped positives at `tests/test-gate-contracts.sh:286-289` and `:456-458` must become negatives before any fixture can protect this class, and the same-ID manifest positive modelled on the real O-006 must be kept.

### Finding O-012
- **Class:** round-record-reparse-divergence
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** A reality-check report is returned in which the AC matrix marks unimplemented criteria `MISSING` (or `FAIL`) and the identity block writes the verdict as `**Verdict:**  READY` with two spaces after the field marker instead of one. `**Verdict:**READY` with no space behaves identically, and so does a correctly spaced `**Verdict:** READY` when the round body also contains a fenced quotation of an earlier draft line reading `**Verdict:** NEEDS WORK`.
- **Where:** scripts/verification-lib.sh:2504, scripts/verification-lib.sh:2520, scripts/verification-lib.sh:968
- **Reproduced:** Built a one-AC spec and a canonical reality-check round with a single `MISSING` row at `/private/tmp/opp7/work/rc1`. With the verdict written `**Verdict:** READY` (one space) the control behaves correctly: `vf_reports` rc=0 with catalog verdict `READY`, and `vf_reality_matrix <spec> <report> 1 <source>` returns **3** with `matrix: READY contains unsupported row`. With `**Verdict:**  READY` (two spaces) `vf_reports` still rc=0 and still emits catalog verdict `READY` — its `value()` at :968 strips `[ ]*` and trims — while `vf_reality_matrix` returns **0** and accepts the `MISSING` row. `**Verdict:**READY` gives the same rc=0. The fenced-duplicate shape gives the same rc=0: `vf_quoted` hides the fenced line from `vf_reports`, so no duplicate-identity error fires, but the `sed` at :2504 prints both lines.
- **Root cause:** implementation-error
- **Blocks:** REQ-013, AC-013, AC-012
- **Wrong behavior:** `vf_reports` has already parsed, validated and emitted the round's verdict as field 5 of the `round` record, under a grammar that tolerates surrounding whitespace, trims, rejects a duplicate identity field and skips quoted content; `vf_gate_round` holds that validated value in `$verdict` at the moment it calls `vf_reality_matrix`. Line :2504 throws it away and re-derives the verdict with `sed -n 's/^\*\*Verdict:\*\* //p'`, a second grammar that requires exactly one space, never trims, accumulates every match including quoted ones, and has no duplicate rule. The only place that value is used is :2520, the sole semantic guard on the reality-check side — the check that a READY verdict cannot stand over a row whose evidence is missing or failing, which is what REQ-013 means by "FAIL/MISSING, changed criteria, dependency-affected rows and unknown impact require renewed evaluation" and what AC-013 tests. Because the two parsers disagree, the round completes and is sealed with `verdict=READY` taken from the catalog while the guard that was supposed to defend READY silently saw a different string and stood down. The reality-check gate has run zero rounds on this spec, so this is live for the next invocation, and it needs no attacker: two spaces after a bold marker is a typing slip no reviewer of the rendered Markdown can see, and this gate is the one that decides whether the spec ships.
- **Class-wide fix:** State the rule as a property of the validator, not of this line: any field of a round record that `vf_reports` parses and emits is consumed from the emitted catalog by every downstream reader, and no second parser re-derives it. Concretely, pass `$verdict` from `vf_gate_round`'s catalog read into `vf_reality_matrix` and delete :2504. Then derive the sweep from the call graph rather than from this example — every place a round's own fields are recovered from report text after `vf_reports` has run: `vf_reality_matrix` (verdict, found here) and `vf_report_block`, whose divergence is deliberate because the digest must cover quoted lines, which is exactly why it must not be used as a field source. Add negatives per divergence class rather than per spelling: a whitespace-variant verdict, a quoted duplicate verdict and a verdict the catalog rejects, each asserting that a round carrying a `FAIL` or `MISSING` row is refused whatever the spacing; keep a one-space READY positive with all rows PASS.

### Finding O-002
- **Class:** round-authorization-grammar
- **Status:** reopened
- **Prior:** O-002
- **Severity:** degraded
- **Scenario:** An operator writes the round-7 authorization into the STATUS Decisions log and capitalizes one letter of the gate token: `- 2026-09-16T09:49:29Z — waiver: gate=Opponent; round=7; after=6; by=Rehan712; reason=…`. `gate = opponent`, `gate=opponent ` and `waiver:gate=opponent` (no space after the colon) are the same slip in three other spellings.
- **Where:** scripts/verification-lib.sh:2303, scripts/verification-lib.sh:2295, scripts/verification-lib.sh:2333, .specify/specs/003-gate-round-reduction-and-token-discipline/tasks.md:608, README.md:426
- **Reproduced:** In `/private/tmp/opp7/work/wv` I drove `vf_round_authorized <spec> opponent 7 2026-09-15T00:00:00Z` over one-line Decisions logs. Controls behave as promised: a wrong round prints `STATUS.md:7 authorizes round=8, not round=7`, and round 6's semicolon case prints the field-count clause. All four typo spellings return rc=4 with `no candidate authorization line for this gate was found in the Decisions log`. End to end through the entry point the repair added: I copied the spec's `STATUS.md`, `notes/opponent.md`, `notes/verification/reports/` and `notes/verification/rounds/` to `/private/tmp/opp7/work/wv2` (512 KB) and ran the shipped `spec-gate.sh waiver <copy> opponent 7`. With the real waiver it prints `authorized: opponent round 7`, rc=0. After changing `gate=opponent` to `gate=Opponent` on that one line it prints rc=4 and lists four refused candidates — STATUS.md:160, :198, :204 and :214, all historical entries for rounds 4, 5 and 6 — and never mentions STATUS.md:242, the line the operator just wrote.
- **Root cause:** implementation-error
- **Blocks:** REQ-012, AC-018
- **Wrong behavior:** No gate decision is wrong and the round cap holds, which is why this stays degraded. What is wrong is the same thing round 6 recorded, through the one clause the repair's enumeration did not reach. `scripts/verification-lib.sh:2303` is the only refusal in the block that takes a bare `next` with no `note()`; the six clauses below it all name their line and reason. Because it is silent, `:2333` then prints a message that does not merely fail to explain — it asserts the opposite of the truth, telling the operator that no candidate authorization line for this gate exists while one sits in the log one character away from valid, and in the end-to-end case it enumerates four other candidates and omits that one, which reads as positive evidence that the new line is not being seen at all. T030o31's accepted acceptance criterion at `tasks.md:608` states that "a log containing no candidate for the gate says so instead of listing none" and that "candidate detection is deliberately wider than the grammar, so an entry that fails before its gate field can be read is still named"; the recorded criterion therefore certifies behaviour the code does not implement for the gate clause itself. The second half of the repair is inert for a different reason: `spec-gate.sh waiver`, whose entire purpose is to let an operator validate an authorization when they write it, appears in no operator-facing document — not README's `spec-gate.sh` command list at :426-432, not `constitution.md`, not the four `skills/` invoker documents, not `agents/sdd-orchestrator.md` or `agents/opponent.agent.md`, not `templates/verification-contract.md`, which documents the waiver line grammar at :224 but not the checker. An operator cannot run a validator they cannot discover, so the authoring-time half of the class stays open by documentation rather than by code.
- **Class-wide fix:** Derive the diagnostic obligation from the grammar the parser enforces, which is the whole line `- <UTC> — <kind>: gate=<g>; round=<n>; after=<n-1>; by=<b>; reason=<r>[; revision=<v>]`: every clause of that production has exactly one refusal path, and every refusal path emits `note()` with its line and clause — there is no clause that may refuse silently. The gate clause is the one case that needs a distinction rather than a note added blindly, and the distinction is available from the grammar itself: a value that is a known gate name other than the requested one is another gate's record and is correctly skipped in silence, while a value that is not a known gate name at all is a malformed candidate and must be named. Make that the rule at :2303, so any future clause added to the production inherits the obligation instead of needing to be listed. Then close the authoring half where it is actually open: add `waiver` to README's `spec-gate.sh` list at :426-432 and to the round-cap paragraph the four invoker documents already share, so the operator meets the checker at the moment they write the entry. Negatives should cover a non-gate-name gate value, a legitimately other-gate entry that must stay silent, and a `<kind>:` written without its trailing space.

### Finding O-010
- **Class:** verification-input-identity
- **Status:** reopened
- **Prior:** O-010
- **Severity:** degraded
- **Scenario:** A later task, retro or brief restates the superseded fixed-environment membership in this repository's own prose conventions — with the variable names in backticks, the way `tasks.md:575` and `templates/verification-contract.md:291-296` write them, or hard-wrapped so that the phrase breaks across two lines, the way every Markdown artifact in this repo is wrapped, or in a different order, or naming only `TMPDIR` and the `LC_*` family. A reader follows it, omits the declaration, and opts a result-dependent check into reuse.
- **Where:** tests/test-gate-contracts.sh:56, tests/test-gate-contracts.sh:57, tests/test-gate-contracts.sh:58, tests/test-gate-contracts.sh:62
- **Reproduced:** Ran the guard's own expression verbatim, first with `KIT_DIR` set to the worktree — it returns empty, so the live tree is clean and T030o30's correction of `tasks.md:531` genuinely holds. Then against `/private/tmp/opp7/work/scan`, a tree of eight one-line artifacts each stating the superseded rule: the verbatim control `…list plus PATH, SHELL, LANG, LC_* and TMPDIR` is the **only** one the guard reports. It misses the same sentence hard-wrapped after `SHELL,` (the needle is a 17-character line-scoped literal and `grep` is line-based); the same sentence with the names in backticks; a reordering (`SHELL, PATH, LANG and TMPDIR`); a subset that states the rule completely without naming PATH or SHELL at all (`always includes TMPDIR and every exported LC_* variable, so you need not declare them`); the same text in a `.txt` or `.yaml` file; and the same text under any directory named `captures`, because `-name captures -prune` at :57 prunes that basename anywhere while `vf_bookkeeping_path` excludes only `.specify/specs/*/notes/captures/`.
- **Root cause:** plan-gap
- **Blocks:** REQ-009, AC-018, AC-012
- **Wrong behavior:** The class round 6 named is "an authoritative statement of the superseded fixed-environment rule stands beside its declaration-only replacement". T030o30's acceptance says the guard "binds to the PHRASE across every artifact whose content the input manifest hashes as current source — the complement of `vf_bookkeeping_path`". Neither half is what shipped. The scope is not the complement of `vf_bookkeeping_path`: the manifest hashes every tracked and untracked non-bookkeeping file whatever its extension, while `:58` scans only `*.md`, `*.sh` and `*.yml` (24 tracked files, among them `scripts/usage-limit-patterns.tsv` and every `tests/fixtures/`, are hashed as current source and invisible to the guard), and `:57` prunes by basename where the manifest excludes by anchored path. And the binding is not to the phrase but to one exact ASCII spelling of it, chosen because it is the substring common to the two artifacts round 6 happened to quote. That is the failure mode this spec has recorded in every class: an enumeration satisfied without the class being closed. It is sharper here than usual, because the two shapes most likely to occur are the two this repository's own conventions produce — backticked variable names, and a hard wrap inside the phrase. Round 6's own `Where` list was wrong for precisely that second reason: it named `notes/verification/dossier/README.md:66` as a survivor when that sentence is correct prose whose fragment merely breaks across a line. The guard reads lines; the claim is a sentence; this repository wraps sentences.
- **Class-wide fix:** Bind the guard to the proposition, not to a string, and derive its scope from the manifest rather than restating it. For scope, enumerate the files from the same source the manifest does — `git ls-files --cached --others --exclude-standard` filtered through `vf_bookkeeping_path`, minus `STATUS.md` — so the guard's set is the manifest's set by construction and cannot drift when a new extension or directory name appears. For the needle, match the claim rather than one rendering of it: normalize each candidate file to a single whitespace-collapsed stream with backticks, asterisks and underscores stripped before matching, so wraps, emphasis and code spans cannot hide it, and assert on a pattern over the claim's parts — a statement that the snapshot or manifest "includes", "always includes" or "hashes" any of PATH, SHELL, LANG, TMPDIR or LC_ as environment membership, in any order and in any subset — rather than on one fixed sequence. Keep a positive fixture proving that a sentence stating the names are no longer hashed is not flagged, since the dossier README is exactly that sentence and a normalizing guard would otherwise match it. Generally: a regression guard for a superseded claim is defeated by the formatting its own repository applies to prose, so it must normalize before matching and take its file set from the same enumeration the thing it protects uses.

### Escalation

Round 7 re-litigates nothing closed: T030o29's tier binding, T030o32's totals guard, T030o31's six noted clauses and T030o30's repair of `tasks.md:531` and the contract were each attacked directly and each held, and they are credited above. But O-004 is now on its sixth consecutive round and O-002 on its seventh, and in both the repair encoded the previous report's named rule faithfully while the adjacent member of the same production survived: `Severity` bound and `Status` exempted in the same statement; six waiver clauses noted and the seventh left silent; one file handle widened to one literal phrase. My reading is unchanged from round 4 and round 5 — the SPEC is not wrong. REQ-010 already demands class-wide repair with established extent, REQ-011 already demands counts that reflect recorded findings, and REQ-013 already demands that FAIL and MISSING rows force renewed evaluation; every defect above is the implementation falling short of a requirement that is correctly written. What keeps failing is that each follow-up's acceptance criterion is written as the list the prior report produced, which guarantees it can be satisfied while the class stays open, and O-004 shows the further step this spec has now hit twice: the repair ships a positive fixture asserting the next instance of the attack completes at rc=0, so the suite actively prevents the class from closing. The user arbitrates. The decision I would put to them is not whether to spend a round 8, but whether T030o33-onward are required to state their extent as a derivation from the production the parser evaluates, with that production cited, and to convert `tests/test-gate-contracts.sh:286-289` and `:456-458` into negatives before anything else is attempted. I do not recommend a waiver on O-004 or O-012: the first lets a gate report reproduce four open defects in full and canonize CLEARED at zero blockers, and the second disarms the only semantic guard on the reality-check side of a gate that has never run and is next.

### Held up / follow-up tasks

Held up under attack, with the reason each held. T030o29's severity-tier binding: a CLEARED round resting on a lowered tier is refused with the count in the message, an honest re-characterisation inside a CHALLENGED round is permitted, an upgrade is never treated as an attack, and I could not move `firsttier` by reordering rounds, by duplicating an ID within a round (`seenfinding` refuses it), or through the prior-review manifest, where the BEGIN pass takes the strictest tier rather than the lexically first — which is the deny-side error. T030o32's duplicate-totals guard: a second totals line inside a round is refused by name, the `seenfield` key does not collide with the identity-field keys, a split or reversed `Blocking`/`Minor` pair is refused as malformed or as missing totals, and a totals line before the first round heading is discarded when the round heading resets `counted`. T030o30's live tree: the scan returns empty against the worktree, `tasks.md:531` now names T030o25 as superseding it without restating the rule, and `templates/verification-contract.md:134-139` states the declaration-only membership. T030o31's six noted clauses, each naming the STATUS.md line and the failing clause, including round 6's own semicolon entry. The kind 3, 4 and 5 raw-HTML branches remain covered by negatives at `tests/test-spec-gate.sh:690-692`. I found no new positive fixture certifying an attack at rc=0 in the round-6 additions beyond the two named in Finding O-004.

Proposed follow-ups. T030o33 — O-004: bind the second token of the blocking predicate at `scripts/verification-lib.sh:1013`, preferring the round-2 option of not letting `resolved` suppress the count at all, since a resolution claim is not corroborable by the parser; convert the shipped positives at `tests/test-gate-contracts.sh:286-289` and `:456-458` into negatives and keep the real-O-006 manifest positive. T030o34 — O-012: delete the second verdict parse at `scripts/verification-lib.sh:2504` and pass `vf_gate_round`'s already-validated catalog verdict into `vf_reality_matrix`, then sweep every other recovery of a round field from report text; negatives per divergence class, not per spelling. T030o35 — O-002: give the gate clause at `scripts/verification-lib.sh:2303` the same `note()` obligation every other clause of the production has, distinguishing a known other gate from a malformed gate value, and document `spec-gate.sh waiver` in README's command list and in the shared round-cap paragraph of the four invoker documents so the authoring-time checker is discoverable. T030o36 — O-010: take the guard's file set from the manifest's own enumeration rather than a `find` filter, and match the claim over a whitespace- and emphasis-normalized stream instead of one line-scoped literal, keeping a positive for the correct "are no longer hashed" sentence.

<!-- gate-round-end: opponent:7 -->

## Round 8

**Round:** 8
**Timestamp:** 2026-09-19T12:25:09Z
**Source:** f6df3f6c71f5f6da43428771bc9ddba03342dc5ce525f62d1d164806fb85d1d2
**Floor:** FLOOR-bvsiKa
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 1

### What I attacked

I read each of the four repairs out of the code that executes, wrote down the production that code actually reads, and attacked the member of that production the repair did not name. For T030o34 the production is the two-token predicate at `scripts/verification-lib.sh:1024` that decides `blockers`, plus the two guards built over it: `Status` at :1046 and `Severity` at :1028. The `Status` half is closed and I could not defeat it. The `Severity` half reads `firsttier`, so I derived how `firsttier` is written and found two writers with opposite rules in the same function — the manifest pass at :990 keeps the STRICTEST recorded tier, the round pass at :1051 keeps the FIRST one — and attacked the round pass. For T030o35 I derived the subcommand set the documentation guard reads from its own awk at `tests/test-gate-contracts.sh:1253-1255`, which is a single spelling of a bash `case` pattern rather than the grammar bash accepts, and attacked the other legal spellings. For T030o33 I walked the call graph of every reader of report text after `vf_reports` and tried to turn `vf_report_block` into a field source. For T030o36 I re-ran the shipped scan expression verbatim against the live tree and then against a predicate set widened with the English membership verbs the shipped enumeration omits.

I re-ran the whole mutation matrix: A, B, B-prime, C, C-prime, C-double-prime, C-triple-prime, D1 through D7, E, F, G, plus two G variants of my own. Every mutation was applied by patch, exercised against its covering case, then restored and verified byte-identical with `cmp` against a pre-mutation copy. Three mutations survived their stated covering set. B-prime survived `report_severity_tier_cases` and `report_prior_binding_cases` but is correctly killed by `report_schema_omission_cases` on both the tally and the `round --complete` paths, so it is covered and I record it as held. D1 survived, and G-prime and G-double-prime survived every case in the suite; both are reported below or under Held up.

Baseline before any mutation: `tests/run.sh` exits 0 with no `assert:` line, 15 suites. Every attack below was measured by its exact diagnostic text, never by exit code alone, and every proposed rule was run against the real recorded history in `notes/opponent.md` before I proposed it.

All work ran under `/private/tmp/opp8/work` with `TMPDIR` under `/private/tmp/opp8`, on a copy of the worktree. Nothing inside the worktree was created, modified, moved or removed except this report file; no floor, round, checkpoint, accept, capture, ledger or task state was touched, and I ran no `spec-gate.sh round`, `accept`, `floor` or `checkpoint` against the worktree. The one read-only invocation I made against the real spec directory was `spec-gate.sh waiver` on the copy, which confirms opponent round 8 authorized and round 9 refused at exit 4.

### Finding O-004

- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-004
- **Severity:** wrong-result
- **Scenario:** One finding ID is observed three times by this gate. Round 1 records it at `degraded`. Round 2 re-records it at `wrong-result`, which is an honest escalation and correctly leaves round 2 CHALLENGED. Round 3 re-records the same still-open ID at `degraded` again and returns CLEARED with zero blockers. The report keeps the defect's full text, its `Where`, its `Reproduced` and `Status: reopened`; only the tier moves. No waiver, no omission and no resolved claim is involved. The escalating round is exactly the shape the shipped positive at `tests/test-gate-contracts.sh:474-479` certifies at rc=0 under the comment "Raising a tier is never the attack", so the state that defeats the guard is created by a step the suite blesses.
- **Where:** scripts/verification-lib.sh:1051, scripts/verification-lib.sh:1028, scripts/verification-lib.sh:1093, scripts/verification-lib.sh:990, scripts/verification-lib.sh:1242, tests/test-gate-contracts.sh:474
- **Reproduced:** Built with this repository's own fixture generator `tier_round_fixture`, which derives totals and verdict from the findings so the fixture cannot disagree with itself. ATTACK: rounds 1/2/3 as `G-042:tier-binding:new:degraded`, `G-042:tier-binding:reopened:wrong-result`, `G-042:tier-binding:reopened:degraded`. Round 3 is generated as `Verdict: CLEARED` with `Blocking: 0 · Minor: 1`. `vf_reports` returns rc=0 with NO diagnostic, and `bash scripts/spec-gate.sh tally` on the same file returns rc=0 printing `opponent rounds=3`, `blocking=1 minor=2 locations=3 unclassified=0` and `severity-downgrades=0`. MIRROR CONTROL, identical in every byte except the tier of the FIRST observation: `G-043:tier-binding:new:wrong-result`, `G-043:tier-binding:reopened:wrong-result`, `G-043:tier-binding:reopened:degraded` returns rc=3 with `report recovery: <file>:74: clearing verdict rests on 1 lowered severity tier(s) of known findings; reconcile canonical records`. The only difference between accepted and refused is whether the first observation was already blocking. A hand-built three-round file without the fixture generator reproduces both sides identically. CANDIDATE FIX MEASURED BEFORE PROPOSING: making the round writer sticky-blocking, `if (!(fid in firsttier) || sev !~ /^(minor|degraded)$/)`, turns the ATTACK into rc=3 with the same exact diagnostic, leaves the MIRROR unchanged, and keeps `bash tests/run.sh gate-contracts` and `bash tests/run.sh verification` at exit 0 with no `assert:` line. Run against the real sealed history it rejects nothing: `spec-gate.sh tally` on spec 003 stays rc=0 at `opponent rounds=7`, and on spec 002 stays rc=0 at `opponent rounds=5 reality-check rounds=1`; spec 001 keeps its pre-existing `duplicate identity field` refusal, unchanged by the patch. This is expected from the record — all seven rounds of this gate are non-clearing, so `downgraded` is never read — and I extracted status and severity per finding per round from `notes/opponent.md` to confirm it rather than assuming it. Restored byte-identically afterwards and verified with `cmp` against both my pre-mutation copy and the live worktree file.
- **Root cause:** implementation-error
- **Blocks:** REQ-011, REQ-010, AC-012
- **Wrong behavior:** The rule the code states for itself, in its own comment at :1023-1028 and in the test label at :434, is that a clearing verdict may not rest on a lowered severity tier of a KNOWN finding. What :1051 implements is narrower: the tier a finding is compared against is whatever tier it carried the first time this gate ever wrote it down, and it is never revised afterwards. Sixty lines above, the manifest reader at :990 solves the same problem the opposite way and explains why — sort order is not observation order, so the strictest recorded tier wins, because sticky blocking is the deny-side error. The round reader takes the allow-side error instead. The consequence is that a still-open defect the gate itself recorded at `wrong-result` or `data-loss` can be tallied as a minor and clear the gate at `blockers==0`, which is precisely the outcome REQ-011 forbids when it says severity never changes merely to meet a round or cost target, and precisely the outcome the T030o29 guard exists to prevent. The same first-wins rule is duplicated at :1242 in `vf_tally`, so the MET-002 `severity-downgrades` metric — the measurement REQ-011 asks for — reports 0 for a report in which a recorded tier demonstrably moved from `wrong-result` to `degraded`. Round 7 explicitly credited this surface as held, writing that it could not be defeated "by an upgrade-then-downgrade sequence, because `firsttier` is written once per ID and the manifest pass takes the strictest tier": the first clause is the mechanism that breaks the guard, read as the reason it holds, and the second clause is true only of the branch the attack does not use. That credit is withdrawn here.
- **Class-wide fix:** State the rule over the predicate rather than over one writer. The clearance check reads `blockers`, `blockers` is decided by exactly two author-written tokens, `Status` and `Severity`, and a token may suppress the count only where the validator can corroborate the claim from data it holds. `Status: resolved` is uncorroborable and is already refused for an ID this gate recorded open. `Severity` IS corroborable, because the gate holds every tier it ever recorded for that ID — so the comparison tier must be the strictest tier ever recorded, not the first, and both writers of `firsttier` must agree on that. Make :1051 sticky-blocking the way :990 already is, and give `vf_tally:1242` the same rule so the metric and the guard cannot disagree. Then isolate it in both directions with fixtures that vary the ORDER of observations rather than their spellings: minor-then-blocking-then-minor under a clearing verdict must refuse; blocking-then-minor under a non-clearing verdict must still pass, because honest re-characterisation stays legal; and the existing "raising a tier is never the attack" positive must be kept and extended with the third round that walks the tier back down, so the state it creates is not left uninspected. Sweep for the same first-wins-versus-strictest divergence anywhere else a per-ID history is reduced to one value.

### Finding O-002

- **Class:** round-authorization-grammar
- **Status:** reopened
- **Prior:** O-002
- **Severity:** degraded
- **Scenario:** A seventh `spec-gate.sh` subcommand is added to the dispatcher in `scripts/spec-gate.sh` and documented nowhere — not in the `--help` synopsis, not in the `--help` detail lines, not in README. If its `case` clause is written `  probe)` the AC-018 guard reports three separate failures. If the same clause is written `  (probe)`, which is the optional-open-paren form bash accepts for a `case` pattern, or `  probe2)`, whose verb contains a digit, the guard reports nothing at all and the whole suite stays green while the subcommand runs.
- **Where:** tests/test-gate-contracts.sh:1253, tests/test-gate-contracts.sh:1255, tests/test-gate-contracts.sh:1261, tests/test-gate-contracts.sh:1264, scripts/spec-gate.sh:19, scripts/spec-gate.sh:3
- **Reproduced:** Mutation G, `  probe) [[ $# == 0 ]] || exit 2; echo probe;;` inserted before the `tally)` clause, is killed as documented: `public_workflow_cases` fails with `AC-018: the --help synopsis and the dispatcher disagree on the subcommand set`, `AC-018: spec-gate.sh probe has no --help detail line` and `AC-018: spec-gate.sh probe appears in no operator-facing document`. Mutation G-prime, the identical clause written `  (probe)`, SURVIVES: `public_workflow_cases` reports `ok`, the derivation prints exactly `round checkpoint floor accept tally waiver`, README matches `spec-gate.sh probe` zero times, `--help` matches `probe` zero times, and `bash scripts/spec-gate.sh probe <spec-dir>` prints `probe` and exits 0. Mutation G-double-prime, `  probe2)`, SURVIVES identically with the same derived verb list and `bash scripts/spec-gate.sh probe2 <spec-dir>` exiting 0. Both restored and verified byte-identical with `cmp`. Mutations E and F, which delete the `waiver` mention from README and from `agents/sdd-orchestrator.md`, are both correctly killed, so the obligation is enforced for the verbs the derivation can see.
- **Root cause:** implementation-error
- **Blocks:** AC-018, REQ-016
- **Wrong behavior:** The stated repair is that the verb set is DERIVED from the dispatcher instead of restated, so a new subcommand inherits the documentation obligation rather than needing to be added to a list. What the guard derives it from is `/^  [a-z][a-z-]*\)/`, which is not the grammar bash reads for a `case` pattern — it is one spelling of it, fixed to exactly two spaces of indentation, a leading lowercase letter, an alphabet of lowercase-and-hyphen only, and no optional open paren. Three legal spellings of the same clause fall outside it. The guard is therefore the same construction the class has failed on seven times: an enumeration wearing the shape of a derivation. It fails silently rather than closed, because the `[[ -n "$verbs" ]]` fail-closed check at :1256 is satisfied by the six verbs that do match, and the synopsis comparison at :1261 passes precisely when the author who forgot the documentation also forgot the synopsis — which is the failure mode being guarded. This is the same mechanism that let `waiver` ship with a `--help` line and no reader and cost round 6 a cold floor. It is degraded rather than blocking because the live tree is currently correct: all six shipped verbs use the matching spelling and all six are documented.
- **Class-wide fix:** Derive the set from something that cannot disagree with what bash executes, not from a regex over one spelling of the source line. The cheapest sound source is the dispatcher's own refusal: enumerate candidate verbs by invoking `spec-gate.sh <verb> <spec-dir>` and treating `unknown or unavailable gate operation` on stderr with exit 2 as "not a subcommand", so the set is defined by the program rather than by a pattern over its text. If a static reader is kept, it must accept the whole `case`-pattern production bash accepts — optional leading `(`, any pattern word, any indentation, and multiple clauses per line — and it must fail closed rather than silently when it meets a clause it cannot classify, which is the property every other clause of the authorization production was given in T030o35. The same audit applies to the other place this spec derives a set from source text: the `/^case "\$command_name" in$/` anchor at :1253 also stops deriving anything if that line ever grows a trailing comment, and that case at least fails closed.

### Held up / follow-up tasks

Attacked and held, and therefore credited.

T030o33, O-012, holds under everything I could aim at it. Mutation A, restoring the second verdict parse as `sed -n 's/^\*\*Verdict:\*\* //p' | tail -1`, is killed in BOTH directions by `matrix_runtime_cases`: text `NEEDS WORK` with catalog `READY` must refuse and does, and text `READY` with catalog `NEEDS WORK` must permit and does. The fail-closed arm is real — an empty verdict gives `matrix: caller supplied no validated round verdict` at rc=3. I then walked the call graph myself rather than trusting the stated sweep: `grep` for every reader of `notes/<gate>.md` and for every recovery of `Verdict` outside `vf_reports` returns nothing in `scripts/`, so the verdict has exactly one parser. The two remaining readers of report text are `vf_report_block`, which is a digest input, and `vf_matrix_parse`, which reads the AC-row production and not a field `vf_reports` emits. `spec-evidence.sh:132-138` does read `notes/reality-check.md`, but only for AC ids under a "Deferred to post-deploy" heading, which is again not a field the catalog carries. I could not turn `vf_report_block` into a field source: the round number it selects is compared against the reservation and against every sealed digest before anything is consumed.

T030o34's `Status` half holds. Mutation B, deleting the refusal at :1099, is killed on both gates with the exact strings `clearing verdict rests on resolved findings this gate recorded open: G-042`. Mutation B-prime, the over-correction that refuses a clearing verdict on ANY resolved finding, survives the two tier and prior cases but is killed by `report_schema_omission_cases` on both the `tally` path and the `round --complete` path — so the real round-1 O-006 shape is genuinely protected and the extent is bounded on the correct side. I confirmed against the real record that the enforced rule matches it: round 1 resolves O-006 against a manifest and never against a round, so it clears; every other resolution in this gate's history sits in a non-clearing round.

T030o35's library half holds completely. C, C-prime, C-double-prime and C-triple-prime are all killed by `round_authorization_cases`, each with the diagnostic it is supposed to produce — `gate="Opponent" names no known gate`, `gate="opponent " names no known gate`, `first field must be gate=`, `must be followed by one space before gate=`, the other-gate silence control, and the prose control that keeps `waiver:` in a code span out of the candidate list. I enumerated every clause of the production independently and each one calls `note()`, including the four bash-side clauses after the awk. The gate clause's silence for another KNOWN gate is the one deliberate exception and it is the right one.

T030o36 holds on the live tree. D2 through D7 are each killed by `superseded_environment_cases` with a named shape — the manifest-derived scope by `other-extension.txt` and `other-extension.yaml`, the reverse direction by `names-first.md`, underscore preservation by `family-only.md`, and the negation window, the negation discrimination and the passive-verb-phrase requirement each by the live-tree assertion together with the over-correction control, so the brief's admission that D3 first survived and D6 first depended on live prose alone is now false in both cases. I then re-ran the scan with the predicate set widened by covers, contains, comprises, consists of, spans, fingerprints, captures, records, is exactly, made up of, composed of, gets/stay/belong/form hashed, and among the recorded. It returns four hits over the whole tree and all four are false positives of my widening: `plan.md` "records pin tool identity, so PATH", `spec.md` "covering the scheduler PATH", `tasks.md` "records LC_" inside T030o25's replacement text, and `templates/verification-contract.md` "records, SHELL" inside the sentence that states the current rule. No surviving claim exists, and the round-7 `Where` correction recorded in T030o36's notes is accurate.

One attack I expected to work and that held: downgrading a canonical round to legacy style. Inserting a `# Opponent review` line between `## Round 8` and `**Round:**` makes `vf_reports` classify the block as legacy, which skips the ENTIRE canonical arm of `flush()` — no totals reconciliation, no verdict-versus-blockers agreement, no downgrade guard, no suppression refusal and no required-section check — while still emitting the report's own `Source` and `Floor`. Measured: `vf_reports` returns rc=0 and emits `round|1||<source>|<floor>|CLEARED|legacy|2026-01-01`. It is refused at the only publication path, because a legacy block emits an empty timestamp and `vf_gate_round` requires the report timestamp to be at or after the reservation's `reserved`; evaluating that exact condition with an empty `report_time` gives `round completion: report identities/timestamp differ from reservation`. The residual is that `vf_tally`, `vf_round_history` and therefore the round counter and the authoring-time waiver checker would all accept such a block if one ever reached `notes/opponent.md` by any path other than `round --complete`. I raise it as an observation, not a finding, since publication is gated.

Non-blocking observations. Mutation D1, deleting the whitespace collapse at `tests/test-gate-contracts.sh:58`, SURVIVES `superseded_environment_cases`: the accumulator already joins lines with a single space, so no shipped fixture distinguishes the collapsed stream from the uncollapsed one. The collapse is still load-bearing for a claim carrying a tab or a doubled space inside a multi-word predicate, so this is an isolation gap in the guard's own fixtures rather than a defect in the guard, and it is the one member of D1-D7 that is not isolated in both directions as the method requires. Separately, the forward and reverse predicate sets in that scanner remain enumerations of English verbs even though the SCOPE is now derived; with no surviving claim in the tree I record that as an open question for the class rather than a finding.

Known open, confirmed rather than rediscovered. A round can still reach CLEARED by omitting a known open finding entirely; O-004 above is strictly worse than omission, because the report keeps the defect's full text and its `Where` while tallying it to zero. The opponent-only asymmetry stands: `scripts/verification-lib.sh:1091`, :1092 and :1093 are all `gate=="opponent"`, so a reality-check round's declared totals, its verdict-versus-blockers agreement and the downgrade guard are unchecked on that side, and the O-004 defect above therefore reaches READY without even needing the tier trick. `clearing()` at :1077-1079 and the suppression refusal at :1099 are gate-neutral. The O-002 residual from rounds 3 and 4 is implemented and covered. README still shows no return-block grammar. `spec-gate.sh tally` on spec 001 still exits 3 with `duplicate identity field`, pre-existing and untouched by anything measured here.

Not reached, and therefore not cleared. Umbrella and multi-repo `vf_gate_roots` and `vf_gate_task_repo`; `vf_accept_transaction` crash windows; `vf_matrix_prior` against a real carried reality-check round; the `r`-suffix follow-up branch; Linux and CI behaviour; per-negative branch coverage inside the large fixtures; and AC-014, AC-017 and AC-018 prose beyond the targeted assertions above. I did not run ShellCheck.

Follow-up tasks proposed.

- T030o37 — O-004: make the comparison tier the strictest tier this gate ever recorded for an ID, not the first. Change the round writer at `scripts/verification-lib.sh:1051` to be sticky-blocking the way the manifest writer at :990 already is, apply the same rule to `vf_tally:1242` so the MET-002 `severity-downgrades` metric and the :1093 guard cannot disagree, and isolate it with order-varying fixtures in both directions: minor-then-blocking-then-minor under CLEARED must refuse with the existing diagnostic; blocking-then-minor under CHALLENGED must still pass; and the "raising a tier is never the attack" positive at `tests/test-gate-contracts.sh:474` must gain the third round that walks the tier back down. Re-run `spec-gate.sh tally` on specs 002 and 003 as the history regression check.
- T030o38 — O-002: stop deriving the subcommand set from a regex over one spelling of a `case` clause. Define the set by what the dispatcher executes — probe each candidate verb and treat `unknown or unavailable gate operation` at exit 2 as "not a subcommand" — or, if a static reader is kept, accept the whole `case`-pattern production including an optional leading `(`, arbitrary indentation and non-`[a-z-]` verb characters, and make an unclassifiable clause fail closed instead of vanishing. Cover it with mutations that add a subcommand in each legal spelling and assert all three obligations fire for every one.

<!-- gate-round-end: opponent:8 -->

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

## Round 11

**Round:** 11
**Timestamp:** 2026-09-26T18:25:56Z
**Source:** 1fba08ed13e83cbca56ef731047f39c3668dfa47c4ff81873de63ee2eea3b0b0
**Floor:** FLOOR-QeBcq3
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 0

### What I attacked

I checked identity and scope myself before using the brief. `notes/verification/rounds/opponent/ROUND-11/meta.nul` records round 11, FLOOR-QeBcq3, source `1fba08ed…` and reservation time 2026-09-26T17:27:11Z, and `r11-reserve.log` says the same. All execution ran in four copies under `/private/tmp/opp11`, plus one scratch enclosing repository there, with `TMPDIR` inside that directory. Each copy is the worktree's own `git ls-files -z --cached --others --exclude-standard` enumeration, read with `GIT_OPTIONAL_LOCKS=0`, plus its own `.git` holding the live index and the main repository's objects as a read-only alternate. In the first copy, `vf_snapshot` produces 370 records. The `version`, `harness` and `document` records carry the copy's absolute paths. The other 357 records are byte-equal to FLOOR-QeBcq3's `inputs.nul`, and the `harness` and `document` digests are equal as well. So my copies hold the reviewed source. In a copy:
- `spec-gate.sh waiver … opponent 11` prints `authorized: opponent round 11` at exit 0;
- round 12 exits 4 and lists nine refused candidates;
- `spec-gate.sh tally` reproduces opponent=10, reality-check=1, blocking=24, minor=10, observations=49, distinct IDs=15, reopened=25 and severity-downgrades=5.

The repair itself (T030o41, O-015 plus the anchor-layout gap):
- **Round 10's exact scenario.** I ran `spec-task.sh done <spec> T030 --evidence "hosted CI green; the macOS job includes PATH and TMPDIR shims for Bash 3.2 (2026-09-24)"`. It printed `T030 -> [x] with evidence`. The manifest stayed `cmp`-identical at `1d395fb5…`, and the verbatim extracted `superseded_environment_scan` over the whole copy printed nothing, at exit 0.
- **The scan's content read.** Replacing the scan's `vf_path_content` call with a raw `cp` fails `superseded_environment_cases` with `AC-020: a claim on a line the identity drops was scanned, so a reusable PASS of this suite could fail (O-015)`.
- **The layout clause.** Deleting the `vf_bookkeeping_anchor` clause fails `outside_layout_anchor_cases` with both of its assertions.
- Both mutants were restored and checked with `cmp`.
- **The full suite.** `bash tests/run.sh` passes 15 suites, 147/147, at exit 0. The copy's `git status --porcelain --ignored -uall` digest was the same before and after.

I then derived the reader class again, this time from what a reuse-checked command consults rather than from the kit's own `${NAME}` reads. T030o41's member (5) was measured only as those reads (STATUS.md:409). The contract that T030o41 rewrote now states that such a check "reads no environment variable the project has not declared" (`templates/verification-contract.md:180-181`). So I varied undeclared environment one input at a time and ran the full suite, or the affected suite, in a copy each time:
- **Locale.** The identity is `cmp`-identical under `LC_ALL=en_GB.UTF-8` and under `LANG=de_DE.UTF-8`. The suite fails under both; that is Finding O-016.
- **Timezone.** `test-usage-limits.sh` passes 27/27 under `TZ=Pacific/Kiritimati` and under `TZ=Etc/GMT+12`.
- **ShellCheck.** `tests/shellcheck.sh` exits 0 with empty output under `LC_ALL=C`, `C.UTF-8`, `en_GB.UTF-8` and `POSIX`, and with every locale name unset. Its `-x` source-following reaches only the one tracked `# shellcheck source=scripts/lib.sh`.
- **`TMPDIR` inside an enclosing Git repository.** The full suite passes 147/147 at exit 0. The enclosing repository keeps one index entry and one commit, and the copy is unchanged.
- **Homebrew's `gawk` first on `PATH`.** The identity is `cmp`-identical, and the full suite passes 147/147 at exit 0.

Known open, confirmed rather than rediscovered:
- the O-004 omission extent;
- the opponent-only totals, verdict and downgrade guards at `scripts/verification-lib.sh:1101-1103`;
- README's comment-only `Verification-Return` at :434, and the completion marker carried only by the two personas;
- 001's exit 3;
- review 7's F1 to F4 and K74. I checked by grep that every `fixture_git -C` still names a repository below `$SANDBOX`, so F1 stays latent, as recorded;
- the harness-level bash startup environment, the kernel's ambient fixture reads, the analyzer field grammar with AC-023's narrowed reading, and the umbrella-only readers.

Not reached, and therefore not cleared:
- a whole floor sealed in a copy under a second locale. I ran the exact predicate that decides its cache hit instead;
- Linux, GNU tools, and Bash 4 or 5;
- the matrix rows beyond the two I re-ran;
- umbrella and multi-repo roots, acceptance crash windows, a real reality-check carry, the `r`-suffix branch, and AC-014/017/018 prose.

Nothing in the worktree was created, modified, moved or removed except this report.

### Finding O-016
- **Class:** verification-input-identity
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** A PASS captured in one shell is reused by a floor sealed in another shell whose locale differs, although a fresh run in that shell fails:
  1. The invoker captures `bash tests/run.sh`, or T030o41's Verify `bash tests/run.sh && bash tests/shellcheck.sh`, from a shell with `LANG=C.UTF-8`. That is what this review's own shell exports.
  2. A floor for the same source is later sealed from a shell whose locale's `LC_TIME` has no plain `AM`/`PM`. Examples are a UK-region macOS Terminal (`LANG=en_GB.UTF-8`, where `%p` prints `p.m.`) or a German one (`LANG=de_DE.UTF-8`, where `%p` prints nothing).
  3. Both reuse-checked commands are opted in (`.specify/stack.yml:14-16`), and `verification_environment: []` declares no locale name (`.specify/stack.yml:22`). The environment records hash declared names only (`scripts/verification-lib.sh:1586-1594`), so the manifest is byte-identical in both shells. Currency and reuse are decided by the manifest digest (`:1774`, and the floor's reuse at `:2147`).
  4. The floor therefore takes a cache hit on the C.UTF-8 PASS. A fresh run in its own shell fails, because the suite reads the locale through `tr` and `date`, both in the shipped classifier (`scripts/usage-limit.sh:29` `tr '[:lower:]' '[:upper:]'` and `:32` `date -j -f '… %I:%M:%S%p'`) and in the test's own clock fixture (`tests/test-usage-limits.sh:392-395` `date '+%I:%M %p'`).
  5. The suite pins `TZ=UTC` for the classifier (`tests/test-usage-limits.sh:14`) but no locale name. `tests/helpers.sh:42-45` clears only `SDD_*`, `XDG_STATE_HOME` and git's repository-local names.
- **Where:** scripts/usage-limit.sh:29, scripts/usage-limit.sh:32, tests/test-usage-limits.sh:14, tests/test-usage-limits.sh:23, tests/test-usage-limits.sh:392, tests/helpers.sh:43, tests/helpers.sh:45, .specify/stack.yml:14, .specify/stack.yml:22, scripts/verification-lib.sh:1591, scripts/verification-lib.sh:1774, scripts/verification-lib.sh:2147, templates/verification-contract.md:180, templates/verification-contract.md:345
- **Reproduced:** End to end, in a copy whose manifest equals FLOOR-QeBcq3's:
  - **Capture.** Under the ambient `LANG=C.UTF-8`, `spec-run.sh <spec> T030o41 --from-task --no-tick --summary` produced CAP-499-SAEWo5: `/bin/bash -o pipefail -c bash tests/run.sh && bash tests/shellcheck.sh`, exit 0, input `1d395fb5…` both before and after.
  - **Reuse under en_GB.** Then, with `LC_ALL=en_GB.UTF-8` (`locale` reports `LC_TIME="en_GB.UTF-8"`), `vf_snapshot` printed the same `1d395fb5…`. `vf_capture_check <spec> CAP-499-SAEWo5 <manifest> reuse` returned rc=0. `vf_binding_snapshot` is `cmp`-equal to the capture's `bindings.nul`, which is the floor's match condition at :2143. `vf_task_current <spec> T030o41 <catalog> <manifest> reuse` printed `CAP-499-SAEWo5` at rc=0.
  - **Fresh run under en_GB.** In a second copy, the same `bash tests/run.sh` under `LC_ALL=en_GB.UTF-8` exits 1 at 144/147. The failures are `test_AC_001_classifies_every_planned_provider_limit_fixture`, `test_AC_004_and_AC_005_park_policy_replays_original_dispatch_once_per_retry` and `test_T013o1_clock_only_horizons_follow_configured_park_policy`. The first reports `expected: limit<TAB>short<TAB>1704123900<TAB>claude-session-clock` against `actual:   limit<TAB>short<TAB><TAB>claude-session-clock`. The third reports `T013o1: both concrete clock resets create resume units`, expected 2, actual 0.
  - **Ambient baseline.** In a third copy, the ambient run passes 147/147 at exit 0.
  - **de_DE.** Under `LANG=de_DE.UTF-8` (with `LC_ALL` and `LC_CTYPE` unset), `bash tests/test-usage-limits.sh` exits 1 at 25/27. Here `resets 3:45pm` classifies as `limit<TAB>short<TAB>1704080700`, exactly 43200 s before the expected `1704123900`.
  - **Controls.** `LC_ALL=C` passes 27/27. `date -v+1H '+%I:%M %p'` prints `PM` under C, C.UTF-8 and en_US.UTF-8, `p.m.` under en_GB.UTF-8, and nothing under de_DE.UTF-8 and fr_FR.UTF-8.
  - Every copy's status digest was unchanged by each suite run.
- **Root cause:** implementation-error
- **Blocks:** REQ-009, AC-020
- **Wrong behavior:** REQ-009 makes "relevant toolchain and environment identity" an input. AC-020 says a changed relevant environment identity cannot reuse the old success. Plan §3.2 item 4 keeps the identity stable across shells by hashing only declared names, and puts the cost on the project: "Projects must declare additional variables their checks depend on." The kit's own project declares none, yet the verdict of its own reuse-checked suite is a function of `LANG`/`LC_ALL`/`LC_TIME`. So a floor or reservation run from a UK- or German-region shell certifies a PASS that its own tree does not produce there.
  - This is the cross-shell variation the 2026-09-13 decision measured and designed the identity to tolerate: locale names differ by default between Terminal, SSH and CI. The kit's reuse opt-in inherits that tolerance without the declaration or pin that makes it sound.
  - T030o41 took on "the environment and configuration the programs consult", and its contract sentence (`templates/verification-contract.md:180-181`) says a reuse-checked check reads no undeclared variable. Its measurement of that member counted only `${NAME}` reads in `scripts/*.sh` (STATUS.md:409), so it missed the environment the tools those scripts and suites run consult.
  - The contract's justification that "`LANG` and the locale categories are not read either" (:345-346) is true of the harness it describes, but not of the kit's own checks.
  - This is not the recorded harness-startup item. That item is bash reading `BASH_ENV`, `ENV`, `SHELLOPTS`, `BASHOPTS` and exported functions. This member is `date` reading `LC_TIME` inside the suite body, from a default login locale, with no hostile setup. Of the two options recorded for that item, hashing bash's startup inputs would not close this one, and pinning a closed harness environment would.
  - Under C.UTF-8 and en_US.UTF-8, `%p` prints `PM` (measured here), so a fresh CI run under either locale would pass too.
- **Class-wide fix:** Derive member (5) from what the invoked programs consult, not from the kit's own variable reads: `date` reads `LC_TIME` and `TZ`, and `tr`, `sort`, `awk` and `grep` read `LC_CTYPE` and `LC_COLLATE`. Then choose, per name, to pin or to declare.
  - **Pin (recommended).** `tests/helpers.sh` exports `LC_ALL=C` beside its existing clearing, and `tests/run.sh` does the same before it enumerates. A name whose value the verdict then cannot see needs no declaration, and the digest stays stable across shells, which the 2026-09-13 decision required.
  - **Fixture.** Add one in both directions. The classifier cases and `test_T013o1_…` pass under `LANG=en_GB.UTF-8` and `LANG=de_DE.UTF-8`, and removing the pin fails that fixture.
  - **Contract.** Correct the contract sentence so that it names what the kit's own suites pin.
  - **Rejected alternative.** Declaring `LANG`, `LC_ALL` and `LC_TIME` under `verification_environment` is the other route. It is correct, but it invalidates every floor across shells, which is what the 2026-09-13 decision rejected.
  - **Out of this spec.** The shipped classifier's own locale dependence (next section) is a separate defect in 002's product. Pinning the suite removes only the reuse half.

### Finding O-015
- **Class:** verification-input-identity
- **Status:** resolved
- **Prior:** O-015
- **Severity:** wrong-result
- **Scenario:** Round 10's case: the T030 tick with a guard-flagged sentence on its Evidence line, and the same sentence on a `status:`/`updated:` line, a body line, a git-quoted name and a link target. I also tried a tree git cannot enumerate. The derived siblings are the suite list, the ShellCheck file list and its rc files, live-kit globs, whole-kit and directory copies, 002's records read in place, and the AC-023 loop. I also attacked the in-repository spec outside `.specify/specs/<name>`.
- **Where:** tests/test-gate-contracts.sh:63, tests/test-gate-contracts.sh:86, scripts/verification-lib.sh:1371, scripts/verification-lib.sh:1417, scripts/verification-lib.sh:1451, tests/helpers.sh:405, tests/run.sh:33, tests/shellcheck.sh:41
- **Reproduced:** In copies whose manifest equals FLOOR-QeBcq3's:
  - The exact round-10 tick in a copy leaves the manifest `cmp`-identical and the scan silent at exit 0.
  - The raw-bytes mutant of the scan's content read fails `superseded_environment_cases` with the O-015 assertion.
  - Deleting the layout clause fails `outside_layout_anchor_cases` with `AC-020: an in-repository spec outside .specify/specs/<name> was given an anchor` and `… an empty anchor excludes nothing`.
  - Both mutants were restored and checked with `cmp`.
  - The full suite passes 147/147, both plainly and with `TMPDIR` inside an enclosing repository, and ShellCheck passes under four locales.
- **Root cause:** plan-gap
- **Blocks:** REQ-009, AC-020
- **Wrong behavior:** Nothing remains wrong for round 10's subject. Every repository byte a reuse-checked command in this kit reads now comes through `vf_source_paths` and `vf_path_content`, as the identity hashes it, and a tree that cannot be enumerated fails by name. The class stays open through the environment, as recorded in O-016.
- **Class-wide fix:** Closed for this member. Keep the fixtures.

### Held up / follow-up tasks

These surfaces held:
- O-015's subject and the round-10 isolation gap, as recorded above.
- The copy's manifest equals FLOOR-QeBcq3's, and the waiver, refusal and tally reproduce.
- `TZ` does not reach any verdict I ran.
- `tests/shellcheck.sh` is locale-proof, and `-x` follows only a tracked file.
- R6-1's ceiling holds for an absolute, colon-free `TMPDIR` inside an enclosing repository: the whole suite ran there and wrote nothing to it.
- An undeclared tool swapped through `PATH`, Homebrew's `gawk` as `awk`, left the identity and all 147 tests unchanged.

Proposed follow-ups:
- **T030o42, for O-016.** Pin `LC_ALL=C` at the start of the kit's own reuse-checked commands (`tests/helpers.sh` and `tests/run.sh`), re-derive the environment member from what the invoked programs consult, correct `templates/verification-contract.md:180-181` and :345-346, and add the two-locale fixture with its mutant.
- **Outside spec 003, recorded for the user.** Shipped 002's `scripts/usage-limit.sh` parses provider clock text under the ambient locale. Under `LANG=de_DE.UTF-8`, `resets 3:45pm` yields a reset 12 hours early (`1704080700` against `1704123900`), so a parked dispatch resumes while still limited. Under `LANG=en_GB.UTF-8` it yields no reset at all. The smallest fix is to run its `tr` and `date -j -f` (and `date -d` on Linux) under `LC_ALL=C`, because the provider's text is English whatever the user's locale. It needs its own follow-up and user decision.
<!-- gate-round-end: opponent:11 -->

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

## Round 13

**Round:** 13
**Timestamp:** 2026-10-01T00:35:30Z
**Source:** 24828d54ee3b743533467e880ce81eb33deec5f1429dea750f4380a899bba145
**Floor:** FLOOR-w6mznu
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 1

### What I attacked

I checked identity and scope myself before relying on the brief. `notes/verification/rounds/opponent/ROUND-13/meta.nul`, sealed by its COMPLETE file, records round 13, FLOOR-w6mznu, source `24828d54…` and a reservation time of 2026-09-30T23:30:26Z.

All execution ran in private copies under `/private/tmp/opp13`, with `TMPDIR` inside that directory.
- **The main copy.** It is the worktree's `git ls-files -z --cached --others --exclude-standard` enumeration (8,319 files) with its own `.git`, which holds the worktree's live index and uses the main repository's objects as a read-only alternate. Its `git status --short` matches the worktree's on all 1,384 lines. Its `vf_snapshot` produces 2,221 NUL fields, and with the copy's path written in place of the worktree's they equal FLOOR-w6mznu's `inputs.nul`. So the copy holds the reviewed source.
- **PRE.** This is the same set of scripts, templates and tests with `notes/verification/reports/t030o43-final.diff` reversed.

The receipts and acceptance:
- **The acceptance command.** I re-ran it in a second copy with every `LC_*` removed, `LANG=en_US.UTF-8`, a `TMPDIR` ending in `/`, and macOS `/bin/bash` 3.2. `bash tests/run.sh` exits 0 across 15 suites at 147/147, and `bash tests/shellcheck.sh` exits 0. The run took 23:38:28Z to 23:59:06Z, and the copy's status is unchanged afterwards.
- **CAP-522-PgNdFn.** Its meta records `bash tests/run.sh && bash tests/shellcheck.sh` at exit 0, policy local, no_tick 1, and input `24828d54…` both before and after. Its log shows 147/147.
- **Recorded history under the pin.** `spec-gate.sh tally` gives:
  - 001: exit 3, as recorded;
  - 002: exit 0;
  - 003: exit 0, with opponent rounds=12, blocking=26, minor=10 and locations=367, as round 12's Decisions entry records.
- **Catalogs.** For 001, 002 and 003, the AC catalog and the tasks-phase binding catalog, diagnostics included, are byte-identical between the current kit under C and PRE under en_US.UTF-8. The analyzer exits 0 on 001 and 002 (AC-023).

Linux, which nobody had run for this change:
- **The run.** I ran the whole suite in a throwaway Debian 13 container from the local `ghcr.io/cargo-lambda/cargo-lambda` image: mawk 1.3.4 20250131, bash 5.2.37, git 2.47.3 and GNU tools. The container used `--network none`, my copy was mounted read-only, and `TMPDIR` ended in `/`. The run took 23:46:31Z to 23:56:58Z. Thirteen suites passed in full, among them test-gate-contracts at 18/18, test-sdd-analyze at 19/19 and test-spec-gate at 8/8.
- **The two failures came from the setup.** Running as root on a bind mount failed two assertions. Re-run as an unprivileged user on tmpfs, test-usage-limits passes 27/27. test-verification then fails only `AC-016: undeclared LC_ALL=en_US.UTF-8 changed source identity across invocations`. The value it compared is bash's `setlocale: LC_ALL: cannot change locale (en_US.UTF-8)` warning, because the image has no en_US.UTF-8, and PRE fails the same assertion the same way. No Linux failure comes from T030o43.
- **An unrepresentative image.** A Debian 12 image (mawk 20200120) does not match the `{3}` interval in the task regexes that predate this change, so I did not use it.

How the repair held:
- **O-017's subject.** It held; the details are in its finding below.
- **Pin placement.** All seven scripts that load the kernel run only `set`, the `HUB_DIR` substitution and `lib.sh` before it.
- **Locale restore.** `vf_capture` and `spec-run.sh`'s legacy run start the command after `vf_caller_locale`.
- **Checkpoint contract.** `vf_gate_checkpoint` reads the ninth field of the catalog's meta record, which is the contract `vf_bindings` writes.
- **Quoting state.** The fence, comment and raw-HTML trackers test only literal spaces, tabs and markers. So `vf_report_block`, which has no whitespace step, and `vf_reports`, which has one, reach the same quoting state on every line.
- **The Decisions view.** It is a superset of what the authorization scanner reads.
- **Parser statuses.** Every text-program substitution in the kernel whose status is still unread is either display, fails closed, or is the umbrella-only `vf_gate_task_repo`, which is already recorded.

Then I applied the method this spec requires. T030o43's Acceptance and `templates/verification-contract.md:354-359` say three things about the manifest pass: it decides a field line by its label; it refuses by name any field line it cannot read; and so every finding is either read or refused.
- **How I derived the lines.** I took the lines that carry a finding's tier from what a reader of the rendered Markdown sees, not from the spellings the four reviews reported. Then I asked the pass's own classifier, `fieldname` (`:1216-1235`), about each of them.
- **Heading labels.** By that classifier, `#### Severity: data-loss` and `#### Severity` are Severity lines. The heading branch at `:1238-1247`, however, consumes every heading before the classifier runs.
- **HTML labels.** An HTML tag in front of the label (`- <b>Severity:</b>`, `<h4>Severity: …</h4>`) stops the prefix skip at `:1218-1221`, so the label is never seen at all.
- **Why the tier is lost silently.** A manifest's Severity is optional, and the shipped positive row `class-only` (`tests/test-gate-contracts.sh:1110`) asserts that a finding with a Class alone parses. So each of these tiers drops without a diagnostic.
- **The canonical report pass.** The same question asked of it found a twin. Only `/^### Finding /` (`:1479`) opens a finding, and a duplicate field's key keeps its indentation (`:1499`).

Together these are Finding O-018. Finding O-019 is a minor regression in the refusing direction that turned up along the way.

Known open items, confirmed rather than rediscovered:
- a frontmatter whose opener carries a byte-order mark, a CR or a trailing space reads as no frontmatter in every reader, so a v1 spec routes to the legacy path (the recorded "CRLF outside the manifest" and "invisible characters that are not White_Space");
- the omission extent;
- the remaining items in the brief's list.

Not reached:
- ubuntu-latest itself (mawk 1.3.4 20240123);
- ShellCheck on Linux;
- hosted CI;
- Linux locales other than C and C.UTF-8;
- EUC-JP, GB18030 and Big5;
- umbrella and multi-repo roots;
- the mutation matrix of record, beyond my own candidate edits.

Nothing in the worktree was created, modified, moved or removed except this report. A hash of every enumerated file taken before and after the run differs only by this file.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** The gate holds a record of a finding at a blocking tier. A CLEARED round re-lists that finding open at minor, or the round counts it as nothing, and the round seals. This happens because the line that carries the tier, or the line that opens the finding, is spelled in a form that neither reader of finding records reads or refuses.
  - **The manifest member.** `notes/verification/reports/opponent-findings-review.md` holds `### Finding G-042`, `- **Class:** tier-binding`, a blank line and `#### Severity: data-loss`. The first opponent round re-records G-042 open at minor, with totals 0 · 1, and returns CLEARED.
    - The heading branch at `:1238` runs `flushm()` and then `next` on every heading. So the tier is never classified, even though `fieldname` returns `severity` for that very line.
    - `flushm` (`:1210`) then records `G-042:tier-binding:` with no tier. `firsttier` is never seeded (`:1311`), so `lowered` (`:1375`) stays false.
    - The same happens with `#### Severity` and `data-loss` as its body, with `#### **Severity:** data-loss`, with `#### Severity — data-loss`, and with `### Severity` under `## Finding G-042`.
    - It also happens with a label behind an HTML tag, because the prefix skip at `:1218-1221` stops at the tag name: `- <b>Severity:</b> data-loss`, `- <strong>Severity:</strong> data-loss`, and `<h4>Severity: data-loss</h4>`.
  - **The canonical-report member.** Round 1 is CHALLENGED with G-042 open at data-loss. Round 2 is CLEARED with totals 0 · 0 and re-lists G-042 open at minor under any of these headings: `#### Finding G-042`, `### Finding` followed by a tab and `G-042`, `###  Finding G-042`, `### Finding` followed by U+00A0 and `G-042`, or `### finding G-042`.
    - Only `/^### Finding /` (`:1479`) opens a finding, so each of these lines falls to the section rule (`:1482`).
    - With no finding open, its field lines are ignored. The count (`:1339`), the verdict agreement (`:1423`) and the lowered-tier guard (`:1424`) never see the finding.
    - Separately, a finding field's duplicate key keeps its indentation (`:1499`). A new finding whose `- **Severity:** data-loss` line is followed by `  - **Severity:** minor` is therefore counted as minor, and a CLEARED round with totals 0 · 1 seals.
- **Where:** scripts/verification-lib.sh:1238, scripts/verification-lib.sh:1216, scripts/verification-lib.sh:1218, scripts/verification-lib.sh:1210, scripts/verification-lib.sh:1311, scripts/verification-lib.sh:1375, scripts/verification-lib.sh:1479, scripts/verification-lib.sh:1482, scripts/verification-lib.sh:1499, scripts/verification-lib.sh:1424, templates/verification-contract.md:356, tests/test-gate-contracts.sh:1110
- **Reproduced:** Every case below ran with every `LC_*` removed, under `LANG=C` and under `LANG=en_US.UTF-8`.
  - **Direct `vf_reports`, manifest member.** I used a CLEARED round 1 that re-records G-042 open at minor (the kit's `tier_round_fixture`), once per manifest spelling.
    - The control, a canonical `- **Severity:** data-loss`, exits 3 with `clearing verdict rests on 1 lowered severity tier(s) of known findings`.
    - Each of the nine spellings above exits 0 with empty stderr.
    - PRE behaves the same, so the defect predates T030o43. The setext spelling (`Severity: data-loss` over a `---` line) is now refused with `a Severity line this grammar cannot read`; PRE did not refuse it.
  - **End to end, manifest member.** I went through the shipped entrypoint using the kit's `make_verification_git_dir` and `floor_fixture`, with a fresh fixture for each case. The floor and the round-1 reservation exit 0.
    - With the `#### Severity: data-loss` manifest, `round --complete` exits 0 with `round completed gate=opponent round=1 verdict=CLEARED report=55b1cf0f…` under C and `report=99c7daab…` under en_US.UTF-8.
    - `ROUND-1/report.sha256` is sealed, and `tally` gives `blocking=0 minor=1 … severity-downgrades=0`.
    - The form with the value as the heading's body seals the same way (`e06b0842…`, `1b68260c…`). The canonical control exits 3 with the lowered-tier refusal.
  - **End to end, canonical-report member.**
    - Round 1 (CHALLENGED, G-042 at data-loss) completes at exit 0.
    - Round 2 completes at exit 0 with `verdict=CLEARED` under `#### Finding G-042` (`8e9c5ab9…`), the tab spelling (`bab2a944…`) and the U+00A0 spelling (`5f6dab6c…`). `tally` then reports `opponent rounds=2 blocking=1 minor=0 … severity-downgrades=0`, so round 2 recorded nothing.
    - The canonical `### Finding G-042` at minor, with totals 0 · 1, exits 3 with the lowered-tier refusal.
  - **The indentation-keyed duplicate.** Direct `vf_reports` exits 0 and records `minor`. The same duplicate without indentation exits 3 with `duplicate finding field`. PRE behaves the same for every member.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-012
- **Wrong behavior:** The gate seals a CLEARED round while the record it is meant to read holds an open blocking tier for the same ID. A still-open blocking finding is tallied as a minor, or as nothing. This is O-017's wrong behavior, reached through a spelling instead of a locale.
  - **REQ-011.** It says that severity never changes merely to meet a round or cost target, and that a violated claim an AC or REQ requires blocks as wrong-result.
  - **The claim that fails.** T030o43's Acceptance and `templates/verification-contract.md:356-357` say a field line the pass cannot read is refused by name. Yet the pass's own classifier calls `#### Severity: data-loss` a Severity line.
  - **The root cause.** T030o43's measured rule separates headings from field lines, enumerates the prefixes the label rule may skip, and keeps Severity optional (STATUS Decisions, the review-1 and review-4 repairs). The code follows that rule faithfully. The canonical pass was never given the read-or-refuse property at all.
  - **Why the class stays open.** Four focused reviews each found the next spelling of the manifest half (R2-F2, R3-F2, R4-F1, R4-F2). The class is still open because recognising a record is still an enumeration of spellings.
- **Class-wide fix:** In both readers, fail closed on whatever they cannot classify, instead of enumerating spellings.
  1. **Manifest.** Refuse a manifest finding by name unless exactly one canonical `- **Severity:**` line is read for it.
     - Measured: adding `if(id!="" && cls!="" && cls!="-" && sev=="") bad("finding " id " has no readable Severity")` to `flushm` refuses all eleven manifest spellings by name, for example `manifest line 6: finding G-042 has no readable Severity: #### Severity: data-loss`. The control's lowered-tier refusal is unchanged.
  2. **Canonical pass, headings.** Refuse by name any heading at any level whose first word is Finding, in any case, and whose second word is ID-shaped, whatever whitespace separates them, unless it is exactly `### Finding <ID>`.
     - Measured: the five spellings are refused with `a Finding heading this grammar cannot read`.
  3. **Canonical pass, duplicate fields.** Let a finding field's duplicate key ignore indentation.
     - Measured: both duplicates are refused with `duplicate finding field`.
  4. **Against the recorded history.** With all three edits, `spec-gate.sh tally` for 001 (exit 3, as recorded), 002 and 003 is byte-identical to the current kit's in both output and exit, under C and under en_US.UTF-8.
  5. **Effect on the suites.** With the edits, test-spec-gate passes 8/8 and test-gate-contracts passes 17/18. The one failure, `test_reports_and_tally`, comes from fixture manifests that carry a Class alone (the `class-only` positive row and the O-041 and O-042 manifest rows), and they need a Severity line. The real 2026-09-09 manifest already carries one per finding.
  6. **Fixtures.** Add a fixture for each member in both directions, and one mutant per guard.

### Finding O-019
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** A manifest finding carries a sub-heading before one of its canonical field lines. Two shapes:
  - `### Finding G-042`, then `- **Class:** tier-binding`, `#### Notes`, `Reproduced twice.` and `- **Severity:** data-loss`;
  - `#### Details` directly under the Finding heading, followed by both field lines.
- **Where:** scripts/verification-lib.sh:1238, scripts/verification-lib.sh:1256, templates/verification-contract.md:358
- **Reproduced:** Direct `vf_reports` with a CLEARED round re-recording G-042 at minor, under C and under en_US.UTF-8.
  - **Current kit.** The Notes shape exits 3 with `manifest line 9: a severity line outside any Finding: - **Severity:** data-loss`. The Details shape exits 3 with `finding G-042 has no readable Class: #### Details` and `a class line outside any Finding: - **Class:** tier-binding`.
  - **PRE.** Both shapes exit 3 with `clearing verdict rests on 1 lowered severity tier(s) of known findings`, so PRE read the fields.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** A canonical field line is refused as being outside any finding, although CommonMark keeps it inside that finding, because a deeper sub-heading does not end the section. A manifest that PRE read can no longer complete a round until it is restructured. The failure is closed, with a named diagnostic, so it is minor. It is the deeper-level sibling of the recorded same-level extent.
- **Class-wide fix:** Close a finding only at a heading as shallow as its Finding heading, which `flevel` already tracks. A deeper heading keeps the finding open, and any Class or Severity label it carries is then read or refused under O-018's rule.

### Finding O-017
- **Class:** harness-locale-decoding
- **Status:** resolved
- **Prior:** O-017
- **Severity:** wrong-result
- **Scenario:** Round 12's cases, run on the current kit and on PRE:
  - the manifest with a 0x92 byte in its Scenario, under a CLEARED round that re-records G-042 at minor;
  - the same manifest, under a round that rebinds G-042's Class;
  - a UTF-8 manifest whose only non-ASCII character is an em dash, under Shift-JIS;
  - the line `- 0x92 [NEEDS CLARIFICATION: …]` appended to a copy of 003's `spec.md`.
- **Where:** scripts/verification-lib.sh:470, scripts/verification-lib.sh:502, scripts/verification-lib.sh:1282, scripts/sdd-analyze.sh:149, tests/test-spec-gate.sh:753, tests/test-gate-contracts.sh:963
- **Reproduced:** Every `LC_*` was removed. I first checked that each non-C locale is one an unpinned awk dies under: en_US.UTF-8, de_DE.UTF-8 and ja_JP.SJIS all are.
  - **Direct `vf_reports` on the current kit.** It exits 3 under C, en_US.UTF-8, de_DE.UTF-8, C.UTF-8 and ja_JP.SJIS. The tier case refuses with `clearing verdict rests on 1 lowered severity tier(s) of known findings`, and the Class case with `finding G-042 changes Class from tier-binding to silent-data-loss`.
  - **PRE.** It exits 0 for both cases under the four non-C locales.
  - **The em-dash manifest.** It refuses under ja_JP.SJIS.
  - **The analyzer.** Under en_US.UTF-8 it reports the 0x92 marker with `unresolved [NEEDS CLARIFICATION] marker(s)`, where PRE prints `no unresolved [NEEDS CLARIFICATION] markers`.
  - **The suite's own cases.** The end-to-end `round_locale_cases` and `report_manifest_locale_cases` both passed in my full run.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, REQ-009, AC-012, AC-020
- **Wrong behavior:** Nothing remains wrong for round 12's subject. Every harness entry script parses under C, every member parser's status is read, and the locale no longer decides whether a round record is written. The manifest grammar's remaining gap works by a different mechanism and is recorded as O-018.
- **Class-wide fix:** Closed for this subject. Keep the locale fixtures and their preconditions.

### Escalation

Round 13 finds one new substantive defect, O-018.
- **The spec is right.** REQ-011 and AC-012 correctly say that a known blocking tier must not be lowered to buy CLEARED.
- **The approach is wrong for this class.** Both readers of finding records recognise a record by an enumerated set of source spellings and treat everything else as prose. So each repair closes the spellings that were reported, and the class stays open. The four focused reviews of T030o43 found R2-F2, R3-F2, R4-F1 and R4-F2 this way, and this round adds the heading, HTML and indentation forms.
- **The measured alternative.** Fail closed on whatever cannot be classified: require one readable canonical Severity in every manifest finding, and refuse any Finding-like heading that is not canonical. This leaves the recorded history's tallies byte-identical.
- **The decision is the user's:** rework the two readers that way under a new task, or accept the risk with a signed waiver in the Decisions log in STATUS.md.

### Held up / follow-up tasks

These surfaces held:
- O-017's subject, as recorded in its finding;
- the copy's identity, which equals FLOOR-w6mznu's inputs, together with CAP-522-PgNdFn's receipts and the acceptance command, re-run at 147/147 with ShellCheck clean;
- Linux, with no T030o43 failure under mawk 20250131 and bash 5.2.37;
- the pin's placement, the caller-locale restore, the status reads, the whitespace step's agreement with the sealed digest, the Decisions view, and the recorded history (tallies, AC catalogs and binding catalogs);
- the TMPDIR canonicalization. My macOS run and my Linux run both used a `TMPDIR` ending in `/`, and the fixture for a nested symlinked `TMPDIR` passed.

Proposed follow-up:
- **T030o44, for O-018.** Make both readers of finding records fail closed on what they cannot classify:
  - a manifest finding needs exactly one readable canonical Severity;
  - a heading that reads as Finding plus an ID but is not `### Finding <ID>` is refused by name;
  - a finding field's duplicate key ignores indentation.

  Also update the fixture manifests that carry a Class alone, add fixtures in both directions with one mutant per guard, and re-run the history tallies. Fold O-019 in by closing a manifest finding only at a heading as shallow as its Finding heading.
<!-- gate-round-end: opponent:13 -->

## Round 14

**Round:** 14
**Timestamp:** 2026-10-02T16:20:45Z
**Source:** 75a92e76ef6817868f99e8ca6f477de33f2d97d3d839488de1e9a6acf8701415
**Floor:** FLOOR-auyetN
**Verdict:** CHALLENGED
**Blocking:** 2 · **Minor:** 1

### What I attacked

Scope: T030o44, the repair of round 13's O-018 with O-019 folded in, including the review's repairs from session 13. I also covered the consumers of the four changed files and the unchanged code those rules depend on.

- **The copy.** My copy is the worktree's `git ls-files -z --cached --others --exclude-standard` enumeration (8,927 files) under `/private/tmp/opp14/work`, made its own git repository, with a `TMPDIR` inside it that ends in `/`.
  - Its kernel hashes to `bbec9615…`, the value in `t030o44-edits/post-apply-3.sha256` through `post-apply-6.sha256`.
  - PRE is that kernel with the kernel hunk of `t030o44-final.diff` reversed. It hashes to `cad3c2c3…`, the value in `pre-apply.sha256`.
  - I read the reservation from `ROUND-14/meta.nul`: round 14, `FLOOR-auyetN`, source `75a92e76…`, reserved 2026-10-02T15:43:54Z.
- **Receipts.** All of these exit 0: `t030o44-dev8-full` and `-full-locale`, the capture, both mutation shards, the return validation, the accept, the floor, the floor validation, the scope and the reservation. Both dev8 logs show 15 suites whose counts sum to 147.
- **Method.**
  - I derived the lines that carry a tier from the productions the label reader claims to follow: CommonMark 0.31.2 inline HTML (6.6), links and images (6.3, 6.4), paragraph continuation (4.8, 5.2) and the HTML-block conditions (4.6). I did not start from the spellings the review named.
  - I put each line to both readers twice: directly through `vf_reports`, and end to end through `make_verification_git_dir`, `floor_fixture`, `floor`, a reservation and `round --complete`. Each fixture function came from a suite copy in my copy with `t_run_all` stripped, and ran in a subshell with a fresh `SANDBOX`.
  - Every case ran with every `LC_*` removed, under `LANG=C` and under `LANG=en_US.UTF-8`, and each was compared with PRE.
  - For rendering I used `marked` 17.0.5 together with the spec text. No strict CommonMark renderer is on disk.
- **Where the rules are switched on.** The T030o44 rules hold for "canonical rounds", so I asked which line decides that a round is canonical. The parser decides it per line, from a variable that the round's own text sets and resets. That is Finding O-020.
- **The label reader.** I attacked its rendered reading with constructs that nest and with constructs that span lines. That is Finding O-018, reopened.
- **The item rule.** I asked which lines a renderer lets interrupt the field's paragraph. That is Finding O-021, a minor regression.
- **The mutation matrix of record.** I read the five argued equivalents.
  - Q08's argument rests on "style is set only by a round heading", which is false: the title line and the Timestamp line also set it (O-020).
  - For L05, L19, R03b and B12 I read the arguments and found no counterexample.
- **Candidate fixes, measured before I propose them.**
  - For O-020: a five-line patch in my copy, judged against the probes, and against tallies and catalogs for 001, 002 and 003 in both locales. I restored the kernel afterwards, and `cmp` shows it identical to the worktree's.
  - For O-018: a survey of the recorded history using the kernel's own label functions with the candidate readings added.

Not reached:
- Linux: the Docker CLI did not answer, so I left Docker alone and ran no container.
- ShellCheck and hosted CI.
- My own whole suite. I ran two shipped fixture functions and my own fixture functions only.
- The tracker's other consumers.
- Umbrella and multi-repo roots.

Nothing in the worktree was created, modified, moved or removed except this report, and no suite or test function ran there.

### Finding O-020
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** A returned round puts a report title (`# Opponent review` followed by any text) right under its `## Round <n>` heading, and moves its Timestamp identity line below its findings.
  - Every line in between is judged by the legacy rules, but the round is still validated and sealed as canonical.
  - So a CLEARED round seals while its own report records an open blocking finding that was never counted. Any O-018 member that T030o44 now refuses passes the same way.
  - **How the style moves.** The round heading sets the style to canonical. The title line sets it to legacy while neither the Round line nor the Timestamp line has been read (`:1632`). The Timestamp line sets it back to canonical (`:1642`). Nothing requires the Timestamp to come before the content.
  - **What reads the legacy value.** Every rule T030o44 added reads it: the Finding-heading refusals (`:1670`, `:1671`), the close at `###` (`:1675`), the outside-a-finding and in-finding label rules (`:1702`, `:1703`), the item rule (`:1715`) and the quoted-record refusal (`:1623`).
  - **The older guards read it too.** The whole canonical block of `finding()` (`:1480`) reads it. That block holds completeness, the severity grammar, the duplicate-ID check, the Class binding, both resolved-claim checks, and the count itself (`:1501`). A finding is judged as canonical only if it is still open when the Timestamp line arrives.
  - **What reads the final value.** `flush()` reads the final value. It checks identity, sections, totals and verdict (`:1584`, `:1585`, `:1592`) against counts that the legacy-judged findings never fed.
- **Where:** scripts/verification-lib.sh:1632, scripts/verification-lib.sh:1642, scripts/verification-lib.sh:1480, scripts/verification-lib.sh:1501, scripts/verification-lib.sh:1584, scripts/verification-lib.sh:1585, scripts/verification-lib.sh:1592, scripts/verification-lib.sh:1623, scripts/verification-lib.sh:1670, scripts/verification-lib.sh:1675, scripts/verification-lib.sh:1702, scripts/verification-lib.sh:1703, scripts/verification-lib.sh:1715, templates/verification-contract.md:385
- **Reproduced:** Every case ran in my copy with every `LC_*` removed, under `LANG=C` and under `LANG=en_US.UTF-8`.
  - **An uncounted blocking finding, end to end.** The round 1 report is CLEARED with totals 0 · 1. It carries a canonical `### Finding G-099` (new, data-loss), then `### Finding G-100` (new, minor).
    - Without the title, `round --complete` exits 3 with `finding totals disagree` and `verdict disagrees with blocking findings`.
    - With the title, and the Timestamp after the Held-up section, it prints `round completed gate=opponent round=1 verdict=CLEARED report=680c8d4c…` under C (`477d6240…` under en_US.UTF-8) and exits 0.
    - `ROUND-1` then holds `report.sha256`, and `tally` reports `blocking=1 minor=1` from that one CLEARED round.
  - **Round 13's canonical member, end to end.** Round 1 is CHALLENGED, with G-042 at data-loss, and completes.
    - A CLEARED round 2 at 0 · 0 re-lists G-042 under `#### Finding G-042`. Without the title it exits 3 with `a Finding heading this grammar cannot read` and eleven lines of `a finding field outside any Finding`.
    - With the title it seals (`report=6826cf47…` under C, `0ca41e63…` under en_US.UTF-8), and `tally` reports `opponent rounds=2` with `blocking=1 minor=0`. So round 2 recorded nothing.
    - A CLEARED round 3 at 0 · 1 then seals (`report=80a68629…`). Its new G-050 is at minor, yet the finding also holds three data-loss lines that the shipped rows refuse: one behind `<b>`, one as a `####` heading label, and one canonical line after an empty comment.
  - **Direct `vf_reports`, with the target finding closed before the Timestamp.** Each of the following exits 0 with empty stderr under the title, and exits 3 without it with the named diagnostic:
    - CLEARED 0 · 1 carrying a new data-loss finding: `finding totals disagree`.
    - CLEARED 0 · 1 marking G-042 resolved after round 1 recorded it open: `clearing verdict rests on resolved findings this gate recorded open: G-042`.
    - A brand-new finding claimed resolved: `resolved finding G-077 has no earlier round of this gate and no declared prior-review record`.
    - The tier `catastrophic`: `unknown severity`.

    Every T030o44 member I tried also exits 0 under the title: behind HTML, a heading label, a continued value, an empty comment, and a level-four Finding heading.
  - **PRE.** The counting cases behave the same on PRE. So the defect predates T030o44, and every rule T030o44 added inherits it.
  - **Recorded history.** Round 8 (`notes/opponent.md:854`) tried this downgrade and recorded it as held. The block it measured had no Timestamp, so it failed the reservation check. A late Timestamp passes that check. The matrix's Q08 argument (`notes/verification/reports/t030o44-mutations.sh:191`) rests on the false premise named above.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-012
- **Wrong behavior:** The gate seals a CLEARED round whose own report records an open data-loss finding, and the tally counts that finding as blocking.
  - A resolved claim on an open finding buys clearance, and so does an invented resolution.
  - Every O-018 member that T030o44 refuses is read as prose again.
  - The contract (`templates/verification-contract.md:385`) and the Acceptance ("The canonical rules apply to canonical rounds of either gate") say the opposite.
  - The root cause is that neither the plan nor the contract says how a round's style is decided. The code keys every rule on a running per-line value, and round 8's conclusion took that value as fixed.
- **Class-wide fix:** Decide a round's style once, from the whole round, before any of its lines are judged.
  1. **The measured rule.** A Timestamp line is refused by name when the title line made its round legacy and the round already has content. Content here means any non-blank line other than the round heading, the title and the identity fields.
     - I measured it as a five-line patch in my copy. All nine flipped probes above are refused.
     - Against the unpatched kernel, the tallies, catalogs and diagnostics for 001, 002 and 003 are byte-identical for both gates, under C and under en_US.UTF-8. 001 exits 3 as recorded, and 003 gives `opponent rounds=13 reality-check rounds=1 blocking=27 minor=11 locations=388`.
     - Every canonical round in the history has its Timestamp before any content, and 002's titled rounds carry none.
  2. **Fixtures.** Add the counting case and one T030o44 member end to end, in both directions and with exact diagnostics, plus a mutant that drops the new refusal.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-018
- **Severity:** wrong-result
- **Scenario:** A finding carries a canonical tier line at minor, and a second line whose rendered text a reader sees as a data-loss tier. Both readers of finding records read that line as prose, and a CLEARED round seals.
  - T030o44's label reader reads every line as written and as rendered. But each reading sees one line at a time, and its link reader does not follow nesting.
  - **Nested brackets.** `vf_label_links` matches `!?\[[^]]*\]` (`:357`), which stops at the first closing bracket. CommonMark 6.3 lets link text hold balanced brackets and inline content, images included.
    - So a linked image keeps its alt word as the line's first word. The common badge shape `- [![badge](y.png)](z)Severity: data-loss` is an example, and so are `[![](y)](z)`, `[[]](x)` and an alt holding an escaped bracket.
    - `marked` renders the badge line as `<a href="z"><img src="y.png" alt="badge"></a>Severity: data-loss`. The plain image `![logo](y)` before the same text is refused (row `second-tier-image`).
  - **A construct across lines.** CommonMark lets a line ending fall in several places:
    - inside an open tag's whitespace and attribute values (6.6, whose own example is a `b2` tag with its attribute on the next line);
    - inside link text;
    - between a destination and its title (6.3);
    - inside an image's alt text.

    The second line then starts in the middle of the construct, so neither reading sees its opening angle bracket or bracket.
    - Examples: an item `- <abbr title="the tier this` continued by `finding carries">Severity:</abbr> data-loss`, an item `- <b` continued by `title="x">Severity: data-loss</b>`, an item `- [` continued by `](x)Severity: data-loss`, and an item ending in `[](x` continued by `"t")Severity: data-loss`.
    - `marked` renders each as one list item whose visible text is the data-loss tier.
    - The same constructs written on one line are refused.
- **Where:** scripts/verification-lib.sh:357, scripts/verification-lib.sh:366, scripts/verification-lib.sh:378, scripts/verification-lib.sh:1414, scripts/verification-lib.sh:1703, templates/verification-contract.md:355, templates/verification-contract.md:360
- **Reproduced:** Every case ran in my copy with every `LC_*` removed, under `LANG=C` and under `LANG=en_US.UTF-8`.
  - **The manifest pass, direct.** The manifest holds `### Finding G-042`, its Class line and `- **Severity:** minor`, then the second line. The round is `tier_round_fixture 1 '' G-042:tier-binding:open:minor`, which re-records G-042 at minor in a CLEARED round.
    - Four bracket spellings and four multi-line spellings each exit 0 with empty stderr, and record G-042 at minor.
    - The controls are a canonical second line and the plain image. Both exit 3 with `manifest line 6: a second Severity line in finding G-042`.
  - **The canonical pass, direct.** `record_round 1 CLEARED 0 1 '### Finding G-050' dup-binding new` takes the minor line and then the second line.
    - Both linked images, the tag split across lines, the wrapped `abbr` title, the empty link across lines, the title across lines and the alt across lines each exit 0, recording G-050 at minor.
    - The one-line `abbr`, `b` and link-title forms and the plain image each exit 3 with `a Severity line this grammar cannot read in finding G-050`.
  - **End to end.** Both cases went through `round --complete`.
    - A CLEARED round 1 over the badge manifest seals (`report=33fb53a9…` under C, `214fea24…` under en_US.UTF-8). The plain-image manifest is refused at completion with `manifest line 6: a second Severity line in finding G-042`.
    - A CLEARED round 2 whose new G-050 carries the minor line and the wrapped `abbr` item seals (`report=ce20e98b…`, `3b8d4da6…`). `tally` then reports `blocking=0 minor=2` and `severity-downgrades=0`.
  - **PRE.** Every member behaves the same on PRE. So the members predate T030o44, which states this class closed.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-012
- **Wrong behavior:** A visible blocking tier is read as prose by both readers, and a CLEARED round seals over it. This is O-018's wrong behavior.
  - The Acceptance and the contract (`:355-361`) say the rendered reading takes out images and inline HTML by CommonMark's own productions, and that an approximation can only refuse. Both claims fail for a construct that nests or spans lines, because the Acceptance defines a record line by line.
  - Round 13's reported members and the review's members stay closed.
- **Class-wide fix:** Read the record the way a renderer does, by paragraph and with nesting, and keep the union of the readings, so that an error can only refuse.
  1. **Nesting.** Reduce bracket pairs innermost first, to a fixpoint.
     - An image with a destination or a reference becomes a non-letter.
     - A link becomes its text between non-letters.
     - Any other pair keeps its text.
  2. **Paragraphs.** Read the label from each paragraph as well as from each line, as written and as rendered. A paragraph is a non-blank line joined with the following lines that `vf_block_start` does not take as a block start.
  3. **Measured against history.** I ran both readings, built from the kernel's own label functions, over every line of 001's, 002's and 003's opponent and reality-check reports, the real `opponent-findings-2026-09-09.md` manifest and the twelve returned round reports.
     - No line and no paragraph gains a label, so the readings refuse nothing recorded.
     - On a test file, the survey finds the badge line and both wrapped items, and leaves an ordinary link and the line `Severity was re-read twice.` as prose.
  4. **Fixtures.** Add the members above as rows in both passes, and one end-to-end case per mechanism.

### Finding O-021
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** A Class, Severity or Status field line is followed directly, with no blank line, by a block that a renderer starts there, ending the field's list item. Both passes still refuse the round, as a field whose list item holds more than its line. Such a block can be:
  - an HTML block such as a `div` or `details` element on its own line;
  - a fence of four or more backticks.
- **Where:** scripts/verification-lib.sh:280, scripts/verification-lib.sh:398, scripts/verification-lib.sh:400, scripts/verification-lib.sh:1389, scripts/verification-lib.sh:1609, tests/test-gate-contracts.sh:1355
- **Reproduced:** The round is a canonical CHALLENGED round whose canonical data-loss tier line is followed directly by one of three blocks: a `div` element, a four-backtick `text` fence, or a `details` element.
  - CUR exits 3 with `opponent.md:15: a Severity field whose list item holds more than its line in finding G-050`. PRE exits 0.
  - `marked` closes the list before each block: a closing `ul`, then the `div`, the `pre` and `code` pair, or the `details` element.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The pass refuses a report whose field item a renderer has already closed, and that costs a re-dispatch. It fails closed with a named diagnostic, so it is minor.
  - The kernel comment (`:280-281`) names CommonMark 4.6 conditions 1, 3, 4 and 5 as the kinds that may interrupt a paragraph. Condition 6 may too, since in 4.6 only condition 7 cannot.
  - The fence test (`:400`) admits exactly three backticks, while a fence opens on three or more.
  - The shipped row `value-details` asserts this over-refusal as a member.
- **Class-wide fix:** Derive the set from CommonMark 4.5 and 4.6. Add condition-6 starts, and backtick fences of three or more with no backtick in the info string, and correct the comment. Make `value-details` a positive row, with a `span` row as its refusal twin, because condition 7 cannot interrupt a paragraph. Every recorded round parses today, so the history is unaffected.

### Finding O-019
- **Class:** gate-report-schema-validation
- **Status:** resolved
- **Prior:** O-019
- **Severity:** minor
- **Scenario:** Round 13's two shapes. In the first, a `#### Notes` sub-heading sits between a manifest finding's Class line and its Severity line. In the second, a `#### Details` sub-heading sits directly under the Finding heading.
- **Where:** scripts/verification-lib.sh:1404
- **Reproduced:** I ran direct `vf_reports` under C and under en_US.UTF-8, for both shapes.
  - A CLEARED round 1 that re-records G-042 at minor exits 3 with `clearing verdict rests on 1 lowered severity tier(s) of known findings`, and with no line saying outside any Finding.
  - The CHALLENGED round at data-loss exits 0.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** Nothing remains wrong for round 13's subject. A deeper heading keeps the manifest finding open, and the field lines under it are read.
- **Class-wide fix:** Closed for this subject. Keep the O-019 rows.

### Escalation

Round 14 finds two substantive defects, O-020 (new) and O-018 (reopened), and one minor regression, O-021.
- **The spec is right.** REQ-011 and AC-012 correctly say that a clearing verdict must not rest on a blocking finding that was dropped or lowered.
- **The approach is wrong in two places.**
  - O-020 is structural and predates this task: which rules apply is decided by a value that the round's own text sets, line by line, so a report can switch the canonical rules off. It is measured, small and history-neutral to fix.
  - O-018 shows that a line-scoped approximation of rendered text stays an enumeration. This round's members nest or span lines, and they are found the same way the review's members were.
- **The decision is the user's.** The options are to repair O-020 now and O-018 by paragraph and nesting under new tasks, or to accept the risk with a signed waiver in the Decisions log in STATUS.md.

### Held up / follow-up tasks

These surfaces held:
- **Round 13's reported members and the T030o44 review's members.** All are refused by name. In my copy the shipped `report_record_line_cases` and `round_record_line_cases` exited 0 with no assertion output (16:12:55Z to 16:15:23Z).
- **O-019.** It is resolved, as its finding says.
- **The union design where the stripper over-deletes.** An autolink, a non-tag, a named reference, an empty link and a footnote reference before the label are all refused. These are the shipped rows.
- **The style-agnostic duplicate key.** An indented second Severity is refused even inside O-020's legacy window: my first round-3 attempt failed on exactly that.
- **Recorded history.** For 001, 002 and 003, the tallies and the catalogs of both gates are byte-identical under the unchanged kernel and under my O-020 candidate, in both locales. 001 exits 3, as recorded. 002 and 003 exit 0, and 003 gives `opponent rounds=13 reality-check rounds=1 blocking=27 minor=11 locations=388`.
- **The receipts listed under What I attacked.** They reproduce as stated.

Proposed follow-up tasks:
- **T030o45, for O-020.** Decide a round's style once, for the whole round, and refuse by name a canonical identity line that follows content judged under the legacy rules. Fixtures go in both directions, end to end, with the counting case, one T030o44 member and one mutant. Re-run the history tallies.
- **T030o46, for O-018, with O-021 folded in.** Read Class and Severity labels by paragraph as well as by line, and reduce nested brackets to a fixpoint, in both passes. Derive `vf_block_start` from CommonMark 4.5 and 4.6. Turn the `value-details` row into a positive with a refusal twin. Add the members as rows in both directions.
<!-- gate-round-end: opponent:14 -->

## Round 15

**Round:** 15
**Timestamp:** 2026-10-07T18:36:32Z
**Source:** c9f2b61691a4447d28f4baaf640c3f43ec993040fda9febaf8eba82134e5b21e
**Floor:** FLOOR-dCwGgb
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 0

### What I attacked

I worked only in copies under `/private/tmp/opp15`, never in the worktree. I attacked the two accepted repairs and the consumers they feed.

- **T030o45 (O-020).** I attacked the style switch in `vf_reports` (`scripts/verification-lib.sh:1665`, `:1697-1716`). The cases were a title before the identity fields with a late Timestamp, a title after the body of a canonical round, a title after a body made only of quoted lines, a late Timestamp in a canonical round, and a title after the Round line. I also checked every other assignment of `style` and every rule that runs before the `body` flag is set.
- **T030o46 (O-018, O-021).** I attacked the label reader's rendered readings (`:325-401`), the paragraph reader `vf_para` and `vf_para_label` (`:426-442`), and `vf_block_start` (`:418-424`), in both readers (the manifest pass at `:1437-1466` and the canonical pass at `:1663-1680` and `:1771-1775`).
  - I derived each candidate from CommonMark 0.31.2: where a paragraph starts and ends (4.1, 4.3, 4.4, 4.8, 5.1, 5.2, 5.3), code-span precedence (6.1), and hard line breaks (6.7). I rendered every candidate with markdown-it 12.3.2, a CommonMark renderer, and with marked 17.0.5.
  - I ran each candidate through both readers directly, then end to end through `round --complete` and `tally` in a fixture repository, under `LANG=C` and `LANG=en_US.UTF-8`.
- **Method.** I tested the proposed rule against the recorded history, isolated the guard with a mutation in both directions, and hunted the shipped positive rows.
  - **History.** The history set was 001's, 002's and 003's opponent and reality-check reports, the real `opponent-findings-2026-09-09.md` manifest, and the thirteen returned round reports read as manifests.
  - **Mutation.** I mutated a copy of the kernel and ran the two changed suites against it.
  - **Positive rows.** I checked every new `SHAPES` and `ROWS` positive in `tests/test-gate-contracts.sh` against both renderers.
- **Evidence re-run.** I ran the full suite in a git-initialized copy of the frozen tree with `TMPDIR` ending in `/`. It exited 0 at 147/147 over 15 suites, which reproduces the capture's count. I did not run ShellCheck.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-018
- **Severity:** wrong-result
- **Scenario:** A finding records a minor tier on its own tier line, and below it the report or manifest carries a second line that both renderers show as a data-loss tier. Both readers of finding records accept it, so a CLEARED round seals and `tally` counts the finding as minor. T030o46 joins a line to the paragraph before it unless `vf_block_start` reads it as a block start, and then reads only the first word of the joined text. A paragraph boundary placed differently from CommonMark therefore hides the label in both directions. A boundary the reader misses puts the previous paragraph's first word in front of the label. A boundary the reader invents cuts the construct off from its opening tag. Joining is not the deny side that the kernel comment at `:291` claims. Six members, each reproduced:
  - **Missed boundary, an ordered sibling item.** A tight list holds the item `1. a` and then the item `2. <b`, continued by `title="x">Severity: data-loss</b>`. CommonMark starts a sibling item at `2.`, because only a list's first item must be numbered 1 to interrupt a paragraph. The same happens with `01. <b` after a paragraph line, since its number is 1. `vf_block_start` accepts only the spellings `1.` and `1)`, so the item joins the paragraph above it, and the joined text's first word is `a`.
  - **Missed boundary, a setext underline.** The line `A remark` and then the line `===` form a level-1 heading, and the same two-line tag follows it. The reader takes the underline as continuation text.
  - **Missed boundary, a block quote.** The line `Note` is followed by `> <b` and then `> title="x">Severity: data-loss</b>`. `vf_para` strips the quote markers before it asks `vf_block_start`, so that function's own block-quote test never fires. The quoted tag therefore joins the paragraph `Note`.
  - **Invented boundary, an indented continuation line.** The line `<b title="a` is followed by a line indented four spaces, `- b">Severity: data-loss</b>`. A list item cannot start at four spaces of indentation, so CommonMark continues both the paragraph and the attribute value. `vf_para` strips all indentation before it tests, reads a list item, and starts a new paragraph whose first word is `b`.
  - **Code-span precedence.** The line ``[`]`](u)Severity: data-loss`` holds a link whose text is a code span containing a closing bracket. The renderers show it as the bracket followed by the data-loss tier. A code span binds tighter than link brackets (6.1), but `vf_label_links` takes the bracket inside the code span as the link's closer, and every reading then starts at `u`.
  - **A rendered line break.** `Note<br>Severity: data-loss` renders the tier at the start of its own line. Inside a field line, such as a Where value written as `a.sh:1<br><b>Severity:</b> data-loss`, it renders as a second bold tier line inside the same list item. `<p>` and the other block-level tags inside a line behave the same way. The readers take the tag out and read `Note`, or the field's own label.
  - **Why the repair missed these.** The repair's fixtures are each a paragraph that starts on a line `vf_block_start` already accepts. That is why the shipped rows pass.
- **Where:** scripts/verification-lib.sh:426, scripts/verification-lib.sh:427, scripts/verification-lib.sh:429, scripts/verification-lib.sh:434, scripts/verification-lib.sh:418, scripts/verification-lib.sh:291, scripts/verification-lib.sh:371, scripts/verification-lib.sh:325, scripts/verification-lib.sh:399, scripts/verification-lib.sh:1439, scripts/verification-lib.sh:1463, scripts/verification-lib.sh:1677, scripts/verification-lib.sh:1771, scripts/verification-lib.sh:1772, templates/verification-contract.md:369, templates/verification-contract.md:378
- **Reproduced:** Every case below ran in my copy of the frozen tree.
  - **Rendering.** markdown-it 12.3.2 and marked 17.0.5 render every member with `Severity: data-loss` as the first visible text of a list item, a paragraph, a block quote or a rendered line. For the `01.` spelling, markdown-it renders a separate list item and marked renders the same paragraph. In both renderings, the tier follows a hidden tag.
  - **Direct runs.** I put each member after a blank line below a canonical wrong-result tier line in a CHALLENGED round, and below a minor tier in a manifest finding G-042. `vf_reports` exits 0 with empty stderr in both passes for every member. The Where-field spelling exits 0 in the manifest pass.
    - **Controls.** The same tag with no preceding line, and the same tag after a line `Text` followed by `1. <b`, both exit 3. The canonical pass prints `a Severity line this grammar cannot read in finding O-001`, and the manifest pass prints `a second Severity line in finding G-042`.
  - **End to end.** I built the fixture with the suite's own `make_verification_git_dir`, `floor_fixture` and `record_line_report`, then ran `floor`, reserved `round`, and completed `round --complete` for a CLEARED round 1 that re-records the manifest finding G-042 at minor.
    - It sealed (`round completed gate=opponent round=1 verdict=CLEARED`) for the ordered item, the setext underline, the block quote, the indented line, the code span and the line break, under both `LANG=C` and `LANG=en_US.UTF-8`.
    - A CLEARED round whose new finding G-050 carries the minor line and the same member sealed in the same way.
    - `tally` then reports `blocking=0 minor=1` every time.
    - The control was refused at completion under both locales, with the diagnostics above.
  - **Mutation, closing direction.** I replaced `vf_para` and `vf_para_label` with a suffix reading.
    - Every line of a paragraph is a candidate start, and the label is read from the joined text that starts at each candidate whose own line carries no label. A paragraph ends only at a blank line, at a fenced line, or at an ATX heading.
    - With that change, both passes refuse the ordered item, the `01.` spelling, the setext underline, the block quote and the indented line. The controls stay refused.
    - I then added two readings to `vf_label`: one in which characters inside a matched code span are inert, and one that reads the text after each `br` tag and each block-level tag outside code spans. With those, the code-span and line-break prose members are refused too.
    - The Where-field spelling stays accepted by the canonical pass, because `:1771` never label-checks a line written in field spelling.
  - **Mutation, history direction.** Under both mutants, the 21 history runs produce byte-identical output and exit codes to the unmutated kernel: 19 exit 0, and the same two exit 3, which are 001's recorded `tally` failure and the reality-check report read as an opponent manifest.
    - **Changed suites.** With the paragraph mutant in a git-initialized copy, `tests/test-gate-contracts.sh` passes 18/18 and `tests/test-spec-gate.sh` passes 8/8, both exiting 0. A first draft that joined a line across an ATX heading failed the shipped positive `heading-then-attribute-line`, which is why the heading rule is part of the fix.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A visible blocking tier is read as prose by both readers, and a CLEARED round seals over it. This is O-018's wrong behavior, and the end-to-end runs reproduce it.
  - T030o46's acceptance requires the members to be derived "from what a renderer shows as the first word of a line or of a paragraph". The contract says the label is read "from each paragraph, a line joined with the lines that continue it".
  - Both claims fail wherever the reader's paragraph boundary differs from CommonMark's, because a single joined text read only at its first word is not an approximation that can only refuse.
  - Round 14's reported spellings, and the repair's own rows, stay closed.
- **Class-wide fix:** Make every boundary error fall on the refusing side, rather than trying to place boundaries exactly.
  - **Paragraphs.** In `vf_para`, take every line of a run of non-blank, unfenced lines as a candidate paragraph start, and end the run only at a blank line, a fenced line or an ATX heading of at most three spaces. In `vf_para_label`, read the label from the joined text that starts at each candidate whose own line carries no label. Measured as described above, this is history-neutral and refuses all five boundary members.
  - **Code spans.** In `vf_label`, add a reading in which characters inside a matched code span are inert. Code spans bind tighter than link brackets and raw HTML (6.1).
  - **Rendered line starts.** Read the label after each `br` tag and each condition-6 tag found outside code spans, and apply this to field-line values in the canonical pass as well. No recorded report or manifest contains such a tag, so this refuses nothing recorded.
  - **Comment and contract.** Correct the comment at `:288-292` and the contract at `:369` and `:378`.
  - **Fixtures.** Add one row per member in both passes, and one end-to-end case per mechanism.

### Finding O-020
- **Class:** gate-report-schema-validation
- **Status:** resolved
- **Prior:** O-020
- **Severity:** wrong-result
- **Scenario:** Round 14's style switch, and its derived siblings.
  - A report title before the identity fields, and the Timestamp after the body.
  - A title after the body of a canonical round.
  - A title after a body made only of quoted lines.
  - A late Timestamp in a round that is already canonical.
- **Where:** scripts/verification-lib.sh:1665, scripts/verification-lib.sh:1699, scripts/verification-lib.sh:1709, scripts/verification-lib.sh:1716
- **Reproduced:** I ran direct `vf_reports` in my copy.
  - A CLEARED round with a title under its heading, a data-loss finding and a Timestamp after Held up exits 3 with `a Timestamp line after the body of a round its title made legacy`, and the count refusals follow.
  - With the Timestamp early, or with a Round line before the late title, the round stays canonical, and its uncounted blocker is refused with `finding totals disagree`.
  - Every assignment of `style` is guarded by `body`, and every rule ahead of the body flag either sets it, refuses, or consumes only identity fields. The shipped `titleearly` positive reads as canonical.
  - The end-to-end row passed in my full-suite run.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** Nothing remains wrong for round 14's subject. A round's style is decided before its body, and a switch after it is refused by name.
- **Class-wide fix:** Closed for this subject. Keep the O-020 rows.

### Finding O-021
- **Class:** gate-report-schema-validation
- **Status:** resolved
- **Prior:** O-021
- **Severity:** minor
- **Scenario:** A tier line followed directly by a block that a renderer starts there: a `div` element, a `details` element, an uppercase `DIV` with an attribute, or a four-backtick `text` fence.
- **Where:** scripts/verification-lib.sh:418, scripts/verification-lib.sh:422, scripts/verification-lib.sh:423
- **Reproduced:** In a CHALLENGED canonical round, each of the four shapes exits 0.
  - The refusal twins, a `span` element (condition 7) and a three-backtick line whose info string holds a backtick, each exit 3 with `a Severity field whose list item holds more than its line in finding O-001`.
  - The tag list matches CommonMark 0.31.2's condition 6, including `search` and excluding `source`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Nothing remains wrong. The over-refusal is gone, and condition 7 still continues the item.
- **Class-wide fix:** Closed. Keep `value-details` positive, with its `span` twin.

### Held up / follow-up tasks

**Held up:**
- **T030o45.** The style is decided before the body in both gates. No sequence of title, identity fields and body that I could build switches style after the body without a named refusal. All recorded history parses unchanged.
- **T030o46's other rules.** These held under attack: the bracket fixpoint for nested links, linked images, empty links, reference links, angle-bracket and parenthesized destinations, and titles across lines; the intraword `*` removal; and both hiding readings for named, numeric and non-ASCII invisible characters.
- **No positive asserts an attack.** None of the new positive rows asserts an attack at exit 0. I checked `heading-then-attribute-line` and `fenced-tag-example` against both renderers. Neither shows a tier as the first word.

**Non-blocking note:** A code span inside a word, as in the spelling ``S`everity`: data-loss``, renders the word in two typefaces, and neither reader reads it. Whether a reader sees it as one word is the user's call, as it was for intraword emphasis, so I do not count it.

**Follow-up tasks proposed:**
- T030o47: Make the paragraph reading refuse on both sides of a boundary error. Use candidate starts at every line, a code-span-inert reading, and reading after `br` and block-level tags, including in field-line values in the canonical pass. Add both-pass rows and end-to-end cases for the six members (→ O-018).
<!-- gate-round-end: opponent:15 -->

## Round 16

**Round:** 16
**Timestamp:** 2026-10-08T12:22:39Z
**Source:** eee97354a5aa4069a44c3791db4b576486502299450a7d3a89739677ec949c12
**Floor:** FLOOR-UW5FIE
**Verdict:** CHALLENGED
**Blocking:** 2 · **Minor:** 1

### What I attacked

I worked only in copies under `/private/tmp/opp16`, built from the worktree's own enumeration and git-initialized, with `TMPDIR` ending in `/`. I created nothing in the worktree except this report.

- **Scope.** T030o47 (round 15's O-018): the run reader `vf_para` and `vf_para_label` (`scripts/verification-lib.sh:486-505`), the code-span reading `vf_label_inert` (`:421-437`), the rendered line start reading `vf_label_breaks` (`:438-452`), the reading order in `vf_label` (`:453-463`), and the canonical field-value check (`:1848`). I attacked them in both readers, the manifest pass and the canonical pass.
- **Derivation.** I derived the candidates from the productions the code claims to read, not from the reported spellings.
  - CommonMark 0.31.2: the line ending and the blank line (2.1), backslash escapes (2.4), ATX headings (4.2, no more than six marks), HTML blocks (4.6, conditions 1 and 6), code spans and their precedence after raw HTML and autolinks (6.1), and links (6.3).
  - The HTML Living Standard for what a browser shows as a new block: the tree builder closes an open p for `pre`, `listing`, `xmp`, `plaintext` and `hgroup`, and the rendering section gives each of them display block. I checked this with parse5 7.3.0.
- **Rendering.** I rendered every candidate with markdown-it 12.3.2 and marked 17.0.5, the same renderers as round 15.
- **Runs.** I ran each candidate after a blank line below a minor tier in both passes, under `LANG=C` and `LANG=en_US.UTF-8` with every `LC_*` removed. I ran it on CUR (the frozen tree) and on PRE (CUR with `r16-session.diff` reversed). For each mechanism I also ran it end to end through `spec-gate.sh round --complete` and `tally`, using the suite's own fixture builders.
- **Method.** I measured two mutants against the recorded history: 001's, 002's and 003's opponent and reality-check reports, with the 2026-09-09 manifest read in 003's directory.
  - Both mutants were byte-identical to CUR there in exit code, stderr and catalog. 001's opponent report stays at exit 3, as recorded.
  - I ran `tests/test-gate-contracts.sh` and `tests/test-spec-gate.sh` against each mutant in its own git-initialized copy.
  - I hunted the new positive rows for an attack asserted at exit 0.
  - I timed the reader against the length of a run.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-018
- **Severity:** wrong-result
- **Scenario:** A finding records a minor tier, and below it, after a blank line, the report or manifest carries text that both renderers show as a data-loss tier at the start of a rendered line or block. Both readers accept it, so a CLEARED round seals. T030o47 claims that a boundary error can only refuse, but its three new readings each diverge from the production they cite, on the accepting side:
  - **Block-rendered tags outside condition 6.** Prose written as `Note<pre>Severity: data-loss</pre>`, and the same with `listing`, `xmp`, `plaintext` or `hgroup`. Every HTML parser closes the paragraph and opens a block whose first text is the tier. `pre` is condition 1 of the same 4.6 that the rule cites, and GitHub's sanitizer allows it. The tag list at `:440` holds only condition 6.
  - **The reading after a break, out of its context.** Prose written as `[Note<br>](u)Severity: data-loss`, and the same with a p tag. Both renderers put the br inside the link text, so the second rendered line starts with the tier. `:447` reads the raw suffix after the tag, where the link's destination is still visible text, so its first word is `u`.
  - **Code spans that 6.1 does not form, or forms where the reader does not.**
    - An escaped backslash before a backtick (written as bracket, two backslashes, backtick, bracket, backtick, then the destination and the tier). The escaped backslash is literal, so the backtick opens a code span holding the bracket.
    - An escaped first backtick of a two-backtick run. Only one backtick is escaped, so the next one opens a span.
    - A backtick inside an HTML tag's attribute or inside an autolink, paired by the reader with a later backtick across a br, as in `<i title="x"></i>Note<br>Severity: data-loss` with a backtick in the title and one more at the end of the line. Raw HTML and autolinks bind before code spans.
    - At `:425` the reader treats a run after any backslash as escaped whole, and it pairs backticks inside tags. Each divergence either keeps the bracket live, so every reading starts at `u`, or makes the br inert.
  - **Run ends the reader invents.** A run is ended at `:490` by a line that is blank to the POSIX class space. That class also holds form feed, vertical tab and carriage return, which are not blank in 2.1. So a form-feed-only line between the two lines of a split tag (an open tag with a title on one line, then the line `x">Severity: data-loss</b>`) ends the run, and no candidate joins across it.
  - **Line endings the reader misses.** A lone carriage return is a line ending in 2.1, and both renderers split on it. `Note` followed by two lone carriage returns and then the tier is a second paragraph for both renderers, but a single line to the awk reader. A manifest Where value of `a.sh:1`, then one lone carriage return, then a whole field line carrying the data-loss tier, renders as a second bold tier list item.
  - **A heading inside an HTML block.** A `div` line, then a tag split over a line that begins with one `#`, renders the tier first in the div. The manifest pass seals it on CUR and on PRE.
- **Where:** scripts/verification-lib.sh:440, scripts/verification-lib.sh:447, scripts/verification-lib.sh:448, scripts/verification-lib.sh:425, scripts/verification-lib.sh:428, scripts/verification-lib.sh:453, scripts/verification-lib.sh:490, scripts/verification-lib.sh:1848, scripts/verification-lib.sh:313, templates/verification-contract.md:369, templates/verification-contract.md:375
- **Reproduced:** Every case ran in my copies, and every refusal below was checked by its exact diagnostic.
  - **Direct runs on CUR.** `vf_reports` exits 0 with empty stderr in both passes and both locales for `pre`, `hgroup`, `listing`, `xmp`, `plaintext`, the link around br and the link around p, both escape spellings, the tag-held backtick, the autolink-held backtick, the form feed, the vertical tab and the lone carriage return. The canonical catalog records G-050 at minor.
    - The manifest Where value with the carriage return exits 0 in the manifest pass.
    - The HTML-block heading exits 0 in the manifest pass.
  - **Controls.** The plain br in prose is refused in both passes and locales, with `a second Severity line in finding G-042` in the manifest pass and `a Severity line this grammar cannot read in finding G-050` in the canonical pass.
  - **Rendering.** markdown-it 12.3.2 and marked 17.0.5 agree on every member. The tier follows a closed link, a hidden tag or a paragraph break, or it is the first text of a pre, xmp, plaintext, listing or hgroup element that parse5 places as a block after the closed paragraph.
  - **End to end.** These seal a CLEARED round under both locales, and `tally` then reports `blocking=0 minor=1`. The completion line is `round completed gate=opponent round=1 verdict=CLEARED`.
    - **Mechanisms.** The pre tag, the link around br, the escaped backslash, the tag-held backtick, the form feed and the lone carriage return.
    - **Both passes.** Each ran as a manifest member re-recorded at minor and as a canonical new G-050.
    - **Control.** The control is refused at completion with exit 3.
  - **PRE.** Every member above also seals on PRE, so none of them is a regression of T030o47. They are gaps in what its new readings claim to close.
  - **Mutation, closing direction.** Mutant M2 made five changes. With them, every member except the HTML-block heading is refused by name in both passes and both locales, while the controls, the real ATX heading and every shipped positive I re-ran stay as they were:
    - The run counts as blank only for spaces and tabs, with an optional final carriage return.
    - `pre listing xmp plaintext hgroup` join the tag list.
    - The break reading also marks each tag, renders the whole text, and reads after each mark.
    - `vf_label_inert` tokenizes left to right, with one-character escapes and with raw HTML and autolinks taking precedence.
    - `vf_label` also reads after each lone carriage return.
  - **Mutation, history direction.** The history runs under M2 are byte-identical to CUR. The two changed suites under M2 are reported in Held up.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A visible blocking tier is read as prose by both readers, and a CLEARED round seals over it. This is O-018's wrong behavior.
  - The rule claims the readings stay approximations that refuse wherever one of them sees a label, and the kernel comment at `:313` says a boundary error cannot hide a label.
  - Neither holds where the reading's own production is incomplete. That includes the block tags the rule derives from condition 6 alone, the code span without 2.4 and without 6.1's precedence, the break reading without the link context, and the blank line and line ending of 2.1.
- **Class-wide fix:** Derive each reading from the full production, and test each against history as M2 was.
  - Take the rendered line starts from the HTML rendering and tree-building rules rather than condition 6 alone. On the refusing side, read after every tag that is not a known phrasing element.
  - Read after a break inside the rendered text: mark the tag and render the whole line.
  - Tokenize code spans left to right with 2.4 escapes and with raw HTML and autolinks first.
  - Make a blank line spaces and tabs only, and treat a lone carriage return as a line ending, or refuse it.
  - Keep a run open across a heading-shaped line inside an HTML block.
  - Add one row per member in both passes, and one end-to-end case per mechanism.

### Finding O-022
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** regression
- **Scenario:** The run reader ends a run at any line of one or more `#` marks followed by a space, while an ATX heading has at most six (4.2). `vf_block_start` at `:481` already spells it that way, and the rule and the contract both say the run ends at an ATX heading.
  - **The case.** A tag is split so that its title continues on a line that begins with seven marks, for example the line `####### x">Severity: data-loss</b>` after an open tag with a title. Both renderers keep that line in the paragraph and show the tier as its first visible word.
  - **CUR.** The run ends there, so no candidate joins the two lines. The line read alone starts at `x`.
  - **PRE.** The paragraph reader joined the line, because `vf_block_start` correctly declines it, and refused.
  - **Block quote.** The same happens inside a block quote with eight marks.
- **Where:** scripts/verification-lib.sh:490, scripts/verification-lib.sh:481, templates/verification-contract.md:376
- **Reproduced:** These ran in both passes and both locales.
  - **PRE.** PRE refuses both cases. The manifest pass prints `a second Severity line in finding G-042`, or `quoted content carries a Severity line` in the quote. The canonical pass prints `a Severity line this grammar cannot read in finding G-050`.
  - **CUR.** CUR exits 0 with empty stderr and records G-050 at minor. End to end, the seven-mark case seals a CLEARED round under both locales in both passes, with `tally` at `blocking=0 minor=1`.
  - **Mutant M1.** M1 changes only the run terminator to one to six marks. It refuses both cases with PRE's exact diagnostics, and a real six-mark heading still parses.
  - **M1 against history.** Its history runs are byte-identical to CUR. `tests/test-gate-contracts.sh` passes 18/18 and `tests/test-spec-gate.sh` passes 8/8, each at exit 0.
- **Root cause:** implementation-error
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A tier that the reader before T030o47 refused by name now seals a CLEARED round, and the repair itself caused it. The code diverges from its own rule, which ends a run only at an ATX heading.
- **Class-wide fix:** In `vf_para`, end a run only at a real ATX heading, using the six-mark alternation that `vf_block_start` uses. Add a row for seven marks in both passes, plain and quoted.

### Finding O-023
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** degraded
- **Scenario:** A finding carries a long run of non-blank lines, such as a Reproduced field with many sub-bullets that hold code spans, links and tags, as reports here do.
  - `vf_para` appends every line to every open candidate.
  - `vf_para_label` then runs the full `vf_label` on every candidate's joined text for every line.
  - The work therefore grows faster than the cube of the run length. Every `vf_reports` read pays it, and completion and `tally` each read the whole report.
- **Where:** scripts/verification-lib.sh:492, scripts/verification-lib.sh:500
- **Reproduced:** I timed one canonical round whose Reproduced field has n sub-bullets of about 90 characters, each holding a code span, a link and a b tag.
  - **CUR.** It takes 6 s at 50 lines, 73 s at 100 and 390 s at 150, all at exit 0.
  - **PRE.** It takes under 1 s at 100 and 1 s at 1000.
  - **History.** The longest run in the recorded history is 47 lines, in 003's opponent report. Across 001, 002 and 003 it was 8, 32 and 47.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** It fails closed, but completion of a round becomes slower with each long finding. The measurement before adoption covered only the history set, whose longest run is 47 lines.
- **Class-wide fix:** Drop a candidate once its joined text has a fixed first word and no open construct. That leaves no unclosed tag, link bracket or code span. Alternatively, cap the join at the longest construct the readings honour.

### Held up / follow-up tasks

**Held up:**
- **The rest of T030o47.** These held under my attack:
  - The six reported round-15 members and the siblings shipped as rows.
  - The every-line candidate reading for list markers, setext underlines, quote markers and four-space indentation inside a run.
  - The code-span reading for plain spans holding brackets or tags, and the canonical Where value with br and p tags.
- **No positive asserts an attack.** None of the new positive rows asserts an attack at exit 0. I rendered `quoted-heading-then-attribute-line`, `blank-line-ends-run`, `span-in-prose` and `escaped-backtick-prose`, and none shows a tier as a first word.
  - The legacy br-carried Where row is a legacy round, where the canonical rules are recorded as not applying.
- **O-020 and O-021** were not reopened by this delta.
- **M2 suites.** Under M2, `tests/test-gate-contracts.sh` passes 18/18 and `tests/test-spec-gate.sh` passes 8/8, each at exit 0.

**Follow-up tasks proposed:**
- T030o48: derive the rendered line start, code-span and line-ending readings from their full productions, read after a break in rendered context, and keep runs open across heading-shaped lines inside HTML blocks; add rows in both passes and end-to-end cases (→ O-018).
- T030o49: end a run only at an ATX heading of one to six marks (→ O-022).
- T030o50: bound the run reader's cost, measured on a run of at least 200 lines (→ O-023).
<!-- gate-round-end: opponent:16 -->

## Round 17

**Round:** 17
**Timestamp:** 2026-10-09T07:39:13Z
**Source:** 54c64d8346fe2459204e68de298f193bb5ea0abe8de86c00de159f05eac07129
**Floor:** FLOOR-QCFkfi
**Verdict:** CHALLENGED
**Blocking:** 2 · **Minor:** 1

### What I attacked

I worked only in copies under `/private/tmp/opp17` with `TMPDIR` ending in `/`. Each copy was rsynced from the worktree with `.git` excluded and then git-initialized. In the worktree I created nothing except this report. I ran no floor, round, checkpoint, capture or accept there.

- **Scope.** I attacked T030o48, T030o49 and T030o50 in both readers of finding records: the manifest pass (`scripts/verification-lib.sh:1610`) and the canonical pass (`:1837`).
  - **T030o48.** The narrowed grammar: `vf_para` sets `vf_narrow` (`:584-601`). `vf_cm_scan` places code spans (`:454-467`), and `vf_label_inert` reads them (`:468-479`).
  - **T030o49.** The six-mark run terminator (`:598`).
  - **T030o50.** The settled-candidate rule: `vf_settled` and its helpers (`:480-535`), and `vf_para_label` (`:603-614`).
  - **Wider surfaces.** I also attacked the extent of a finding as both passes read it (`:1616-1631`, `:1917`, `:1944`), and the shared fence tracker (`:116`) as those readers consume it.
- **Derivation.** I derived each case from CommonMark 0.31.2, not from the spellings already reported:
  - 6.1: a code span binds tighter than everything except raw HTML and autolinks, and the parser reaches a link destination or title before any later backtick.
  - 6.5: an email autolink's local part may begin with a digit or a symbol, and may hold a backtick.
  - 4.7: a link reference definition renders nothing, and its title may span lines.
  - 5.2 and 4.5: a fence opened inside a list item ends with that item.
- **Rendering.** I rendered every member with markdown-it 12.3.2 (html enabled) and marked 17.0.5, the binaries the r17 repro used.
- **Runs.** I ran every member directly through `vf_reports`, in both passes and under `LANG=C` and `LANG=en_US.UTF-8` with every `LC_*` removed.
  - I ran each member on CUR (the frozen tree) and on PRE (CUR with `r17-session.diff` reversed).
  - I ran each mechanism end to end through `spec-gate.sh floor`, `round`, `round --complete` and `tally`. Those runs used the suite's own `make_verification_git_dir`, `floor_fixture` and `record_line_report`, in a file of my own inside my copy.
- **Mutants.** I built three mutants, M1, M2 and M3, one per finding.
  - **Closing direction.** Each mutant refuses or speeds up its own members with an exact diagnostic, and the controls stay as they were.
  - **History.** Each was measured against 001's, 002's and 003's opponent and reality-check reports, with 003's 2026-09-09 manifest, under both locales. Exit codes, stderr and catalogs are byte-identical to CUR, and 001's opponent report stays at exit 3.
  - **Suites.** I ran `tests/test-gate-contracts.sh` and `tests/test-spec-gate.sh` against each mutant in its own copy. The results are reported under Held up.
- **Positives.** I hunted the new positive rows in `tgc-2` and `tsg-1` for an attack asserted at exit 0.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-018
- **Severity:** wrong-result
- **Scenario:** Inside a finding, below a minor tier, a line carries live raw HTML that renders a data-loss tier at the start of a rendered line or block. A backtick sits inside a construct that binds before any later backtick, and the line ends with one more backtick. Three constructs do it:
  - an email autolink whose local part starts with a digit and holds a backtick, as in the line written `` Note <1`@a.b><pre>Severity: data-loss</pre>` ``;
  - a link destination holding a backtick, as in `` [x](u`v)<br>Severity: data-loss, tick: `. ``;
  - a link title holding a backtick, as in `` [x](u "`")<br>Severity: data-loss, tick: `. ``.
  - **The gate's reading.** `vf_cm_scan` flags a `<` only before a letter, `/`, `!` or `?`. It pairs the inner backtick with the last one into a code span, so the `<br>` or `<pre>` reads as inside a span. `vf_narrow` stays empty, and `vf_label_inert` makes the tag inert for the break reading too.
  - **The renderers' reading.** The autolink or link consumes the inner backtick first. The tag is live, and the final backtick is literal.
  - The T030o48 rule and the contract both say an autolink inside a finding is refused, and that a `<` is inside a code span only when every reading places it there. No reading of the code places a backtick inside an autolink or a link destination.
- **Where:** scripts/verification-lib.sh:460, scripts/verification-lib.sh:454, scripts/verification-lib.sh:468, scripts/verification-lib.sh:594, scripts/verification-lib.sh:1610, scripts/verification-lib.sh:1837, templates/verification-contract.md:382
- **Reproduced:** Every case ran in my copies, and every refusal was checked by its exact diagnostic.
  - **Direct runs.** On CUR, `vf_reports` exits 0 with empty stderr for all three members in both passes and both locales, with `pre`, `br` and `p` spellings. The catalog records G-050, or the manifest's G-042, at minor.
  - **Control.** The same line without the autolink is refused: `raw HTML outside a code span in finding G-050`.
  - **Rendering.** markdown-it and marked agree on every member: a mailto or plain link, then the live `<br>`, `<pre>` or `<p>` with the tier as its first text.
  - **End to end.** The autolink member seals a CLEARED round 1 in both passes under both locales, as a canonical new G-050 and as a manifest G-042 re-recorded at minor. The completion line is `round completed gate=opponent round=1 verdict=CLEARED`, and `tally` reports `blocking=0 minor=1`. The control is refused at completion with exit 3 and the diagnostic above.
  - **PRE.** All members also pass on PRE, so this is a gap in T030o48's claim, not a regression.
  - **M1.** M1 adds one reading that masks backticks inside an autolink-shaped or destination-shaped segment before the scan. It refuses every member in both passes and both locales with `raw HTML outside a code span in finding G-050` or `... G-042`. `Use` followed by a code span holding `<br>` still parses, and so does a code span inside link text. The M1 history runs are byte-identical to CUR.
- **Root cause:** implementation-error
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** Raw HTML inside a finding passes the narrowed grammar, and the round-16 members it was adopted to close come back.
  - A visible data-loss tier is read as prose by both readers, and a CLEARED round seals over it.
  - The rule's claim that a reading the reader invents cannot hide a `<` fails, because the code-span reading is not the only reading of where a backtick stands.
- **Class-wide fix:** Place code spans after the constructs that bind before them, or narrow further.
  - **Placing spans.** Take a backtick inside an autolink (6.5, both kinds), a link destination or a link title as literal in at least one reading, so that a `<` counts as inside a span only when that reading agrees.
  - **Narrowing further.** Alternatively, refuse inside a finding a backtick that stands inside such a construct.
  - **Rows.** Add one row per construct in both passes, and one end-to-end case.

### Finding O-024
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** The extent of a finding, and which of its lines a reader sees, are decided by readings a renderer does not share. Two mechanisms each seal a lowered tier, and together they leave data-loss as the only tier on the rendered page.
  - **A finding closed early.** After the finding's fields, a list item whose only text opens a three-backtick fence is followed by an indented line `  ### x`. A renderer shows that line as code inside the item. The tracker opens no fence after a list marker, though, so both passes read the line as a heading as shallow as the Finding heading and close the finding.
  - **A visible tier the gate does not read.** The next line is a sibling item written `- **Severity**: data-loss`. A renderer shows it as an item of the same list, in the same section. The canonical pass checks prose labels only while `fid` is set. The manifest pass refuses a stray tier only when `idseen` is set, and `### x` does not set it.
  - **A tier no reader sees.** Earlier in the same finding, after a blank line, a link reference definition `[a]: /u '` carries a title across three lines. Its second line is an indented `- **Severity:** minor`, and its third line, `    - x'`, closes the title. A renderer shows nothing of the definition. Both passes read the indented line as the finding's Severity field. The item check accepts the next line because `vf_block_start` reads it as a list item.
- **Where:** scripts/verification-lib.sh:1917, scripts/verification-lib.sh:1626, scripts/verification-lib.sh:1641, scripts/verification-lib.sh:1944, scripts/verification-lib.sh:116, scripts/verification-lib.sh:1609, templates/verification-contract.md:382
- **Reproduced:** Every case ran in my copies, under both locales.
  - **Rendering.** With both mechanisms, markdown-it and marked render the finding's h3 and its fields, then a list. The list holds a code block showing `### x` and then an item reading `Severity: data-loss`. No minor tier appears anywhere.
  - **Direct runs.** On CUR and on PRE, `vf_reports` exits 0 with empty stderr and records G-050 at minor. It does the same for the fence-only variant, where the visible minor field stays above the code block and a second, data-loss tier shows below it unrefused, and for the definition-only variant. The manifest pass on the same text exits 0 with G-042 at minor.
  - **End to end.** The combined case seals a CLEARED round 1 as a canonical G-050, and over a manifest G-042 re-recorded at minor, in both locales. The completion line is `round completed gate=opponent round=1 verdict=CLEARED`, and `tally` reports `blocking=0 minor=1`.
  - **M2.** M2 adds two narrowing clauses to `vf_para`. The first refuses a list marker followed by a fence run, printing `a code fence inside a list item in finding G-050`. The second refuses a line starting a link reference definition, printing `a link reference definition in finding G-050`. M2 refuses every variant in both passes and both locales. Its history runs are byte-identical to CUR.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A CLEARED round seals a finding whose only rendered tier is data-loss, at minor.
  - The narrowed grammar shields a finding against raw HTML only. The finding's extent still comes from a line reader that misses a fence a list item opens, and a construct that renders nothing still carries a field line.
  - The rule says a boundary error can only refuse. It does not hold for the boundary that closes a finding.
- **Class-wide fix:** Narrow the finding grammar to what both readers can follow. Inside a finding, refuse by name a fence opened after a list marker and a link reference definition, as M2 does, or end a finding only at a heading at least as shallow as its own, outside any construct a renderer opens.
  - **Rows.** Add rows for each mechanism in both passes, and one end-to-end case.

### Finding O-023
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-023
- **Severity:** degraded
- **Scenario:** A finding's Reproduced line quotes one opening bracket in a code span (as `` `[` ``, which the reports here do), and ordinary sub-bullets follow it.
  - `vf_settled_brackets` is applied to the text as written, where a bracket inside a code span still counts as open. That bracket comes after the line's first word, so it cannot change how any reading begins. Even so, the candidate is never settled.
  - That candidate is extended and re-read through `vf_label` on every following line of the run. The bracket reduction in `vf_label_links` restarts from the start of the text for each pair.
- **Where:** scripts/verification-lib.sh:531, scripts/verification-lib.sh:501, scripts/verification-lib.sh:600, scripts/verification-lib.sh:609, scripts/verification-lib.sh:409
- **Reproduced:** I timed one canonical round on CUR, with the bracket on the Reproduced line followed by n sub-bullets of about 100 characters, each holding two code spans, a link and emphasis.
  - **CUR.** It takes 42.7 s at 200 lines and 305 s at 400, both at exit 0. That misses T030o50's own bound of under 30 s at 400 lines, with at most four times the time when the run doubles.
  - **Every line.** With the bracket on every line, it takes 1.6 s at 50, 11.2 s at 100, 37 s at 150 and 89 s at 200.
  - **History.** 003's opponent report already has seven lines with an unbalanced bracket inside a code span.
  - **M3.** M3 checks brackets only up to the end of each reading's first word. It takes 0.30 s at 400 lines and 0.12 s for the every-line shape at 200. Its history runs are byte-identical to CUR.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** It fails slow, not open. Completing a round and running `tally` each re-read the whole report, so one quoted bracket above a long Reproduced field costs minutes on every read. That is the cost T030o50 was accepted to bound.
- **Class-wide fix:** Count as unsettling only the constructs that open at or before each reading's first word, for brackets as M3 does and likewise for destinations. Add the 400-line timing row with a quoted bracket.

### Held up / follow-up tasks

**Held up:**
- **T030o49.** It holds. A line of seven or eight marks, plain or behind block-quote markers, no longer ends a run, while a one-to-six-mark ATX heading does. A heading-shaped line indented four or more spaces, or behind a tab after a block-quote marker, keeps the run open, which refuses rather than accepts.
- **T030o48, outside O-018's members.** These held:
  - The form feed, vertical tab and lone carriage return checks on the line as written, including a final carriage return read as the line ending.
  - The blank-line reading of spaces and tabs only.
  - The multi-line span states (a span left open read as opener and as literal), escapes in pairs, and the escaped `<`.
  - The every-reading rule for spans the reader itself invents from plain backticks.
  - Character references that decode to `<`, which render as text.
- **T030o50's soundness.** I found no candidate dropped before a later line could change its first word. Joined text adds a space, every construct that can hide a leading word must close before settling, and a link reference definition ends at a line end, so the text after it starts a candidate of its own.
- **Positives.** No new positive row asserts an attack at exit 0. I rendered `a-image-split-by-blank-line`, `a-image-split-by-six-marks`, `a-span-tag-after-a-lone-backtick-paragraph`, `a-escaped-backtick-prose` and `a-nbsp-line`, and none shows a tier as a first word.
- **Mutant suites.** Under M1, `tests/test-gate-contracts.sh` passes 18/18 and `tests/test-spec-gate.sh` passes 8/8, each at exit 0. Under M2 and under M3, both suites pass at the same counts, each at exit 0.
- **Minor, non-blocking.** The narrowed check is judged on a line before that line's own heading opens or closes a finding, so it is off by one heading at both ends of a finding:
  - The first Finding heading of a round may carry raw HTML. `### Finding G-050` followed by a b tag parses.
  - A later Finding heading, or the section heading that closes a finding, is refused under the previous finding's ID.
  - I found no tier attack through it, because any tag that hides content needs a closer, and that closer is refused inside the finding.

**Follow-up tasks proposed:**
- T030o51: Place code spans after autolinks (both kinds) and link destinations and titles, or refuse a backtick inside them within a finding. Add rows in both passes and one end-to-end case (→ O-018).
- T030o52: Inside a finding, refuse by name a fence opened after a list marker and a link reference definition, or derive the finding's extent from the constructs a renderer opens. Add rows in both passes and one end-to-end case (→ O-024).
- T030o53: Settle a candidate on the constructs that open at or before each reading's first word, and add a 400-line timing row whose run holds a bracket quoted in a code span (→ O-023).
- Optionally, judge the narrowed check after the line's own heading has been read (minor, above).
<!-- gate-round-end: opponent:17 -->

## Round 18

**Round:** 18
**Timestamp:** 2026-10-14T13:22:23Z
**Source:** 567cb6e04411ca525cb059fc247ab7ac34b1c52718f969d3478734ee69a7228e
**Floor:** FLOOR-OgYGoP
**Verdict:** CHALLENGED
**Blocking:** 2 · **Minor:** 1

### What I attacked

I worked only in copies under `/private/tmp/opp18`, with `TMPDIR` ending in `/`. Each copy was rsynced from the worktree with `.git` excluded and then git-initialized. CUR (the frozen tree) hashes as `r18-edits/post-apply-3.sha256`. PRE is CUR with `r18-session.diff` reversed, and it hashes as `r18-edits/pre-apply.sha256`. In the worktree I created nothing except this report, and I ran no floor, round, checkpoint, capture or accept there. I hashed every worktree file before and after my run.

- **Scope.** I attacked T030o51, T030o52, T030o53 and the folded minor in both readers of finding records: the manifest pass (`scripts/verification-lib.sh:1711`) and the canonical pass (`:1942`, `:1976`, `:2011`, `:2024`).
  - **The changed code.** `vf_cm_dest`, `vf_cm_label` and `vf_cm_scan` (`:475-537`), `vf_para_refdef` and `vf_para` (`:665-700`), and `vf_settled_head` and `vf_settled_word` (`:557-568`).
  - **Unchanged code they feed.** `vf_label`, `vf_label_breaks` and `vf_para_label`.
- **Derivation.** I derived each case from the productions the reference renderers apply, not from round 17's spellings, and not from CommonMark 0.31.2 alone:
  - which constructs consume a backtick before a code span can open: CommonMark 6.1, 6.3 and 6.5, GFM's extended autolinks, and marked's reference-link tokenizer;
  - where a renderer starts a new line: GFM tables, and the gate's own block-level tag list;
  - what can still change a candidate's first word after it is settled.
- **Rendering.** I rendered every member with markdown-it 12.3.2 (html enabled) and marked 17.0.5, the binaries `r18-repro.sh` used. No cmark-gfm is on disk, so I did not run GitHub's renderer.
- **Runs.** I ran every member directly through `vf_reports` in both passes, under `LANG=C` and `LANG=en_US.UTF-8` with every `LC_*` removed, on CUR and on PRE.
  - I ran each mechanism end to end through `spec-gate.sh floor`, `round`, `round --complete` and `tally`.
  - Those runs used the suite's own `make_verification_git_dir`, `floor_fixture` and `record_line_report`, in a file of my own inside my copy.
- **Mutants.** I built one mutant per finding (M1, M2, M3) and one that combines all three (MALL).
  - Each mutant refuses its own members with an exact diagnostic, or ends the slow path, while the controls and positives stay as they were.
  - The history and both record-reader suites were run against MALL. The results are under Held up.
- **Positives.** I rendered the 34 new positive rows: the 18 manifest shapes in `tgc-1` and the 16 canonical `a-` rows. None shows a data-loss tier at the start of a block, a cell or a rendered line.

### Finding O-018
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-018
- **Severity:** wrong-result
- **Scenario:** Inside a finding, below a minor tier, a line carries a backtick inside a construct that marked binds before any code span, and the line ends with one more backtick. The reader pairs the two backticks into a code span that holds a br or pre tag. marked renders that tag live, with the data-loss tier as the first text of the new line.
  - **An extended autolink.** GFM's URL literal takes every character up to whitespace or an angle bracket, a backtick included. Examples are the line written `` Note http://a.b/`<br>Severity: data-loss, tick: `. `` and its `https://`, `www.` and `ftp://` spellings (the last with a pre tag).
  - **A shortcut, collapsed or image reference.** The member is written `` Note [a`b]<br>Severity: data-loss, tick: `. ``, or with `[]` or a leading `!`. It needs a definition of that label outside every finding, where definitions still parse. marked's reference tokenizer reads the label up to the first bracket without regard to code spans.
  - **The gate's reading.** `vf_cm_scan` stops only at a closing bracket, a backslash, an angle bracket and a backtick. It reads a destination or a label only after a closing bracket followed by a parenthesis or a bracket, so it sees neither construct.
    - The inner backtick pairs with the last one, so the tag reads as inside a span and `vf_narrow` stays empty.
    - `vf_label_inert` makes the tag inert, so the break reading sees nothing either.
  - **The renderers.** markdown-it agrees with the reader and renders a code span. marked renders a link whose target ends in `%60`, then the live tag, then the tier.
  - **The derivation.** T030o51's acceptance derives its constructs from CommonMark 0.31.2 only, while the renderers every repro of this gate uses include marked, which applies GFM.
- **Where:** scripts/verification-lib.sh:514, scripts/verification-lib.sh:509, scripts/verification-lib.sh:538, scripts/verification-lib.sh:690, scripts/verification-lib.sh:1711, scripts/verification-lib.sh:1942, templates/verification-contract.md:382
- **Reproduced:** Every case ran in my copies, and every refusal was checked by its exact diagnostic.
  - **Direct runs.** On CUR, `vf_reports` exits 0 with empty stderr for all seven spellings, in both passes and both locales. The catalog records G-050, or the manifest's G-042, at minor.
  - **Control.** The line `Note <br>Severity: data-loss.` is refused with `raw HTML outside a code span in finding G-050`.
  - **End to end.** The URL member and the reference member each seal a CLEARED round 1 in both passes under both locales, as a canonical new G-050 and as a manifest G-042 re-recorded at minor. The completion line is `round completed gate=opponent round=1 verdict=CLEARED`, and `tally` reports `blocking=0 minor=1`. The control is refused at completion with exit 3.
  - **PRE.** Every member also passes on PRE, so this is a gap in T030o51's claim, not a regression.
  - **M1.** M1 adds two checks to `vf_cm_scan`, each made only where a reading places the construct outside every code span.
    - A bracket pair closed on its line that holds a backtick run it does not close is refused with `a backtick inside a link destination, title or label in finding G-050`.
    - A URL literal after `http`, `https` or `ftp` and a colon, or after `www.`, whose run up to whitespace or an angle bracket holds a backtick, is refused with `an autolink outside a code span in finding G-050`.
    - M1 refuses every member in both passes and both locales (`... G-042` in the manifest pass). The positives still parse: `See https://x.example/a and` followed by a code span, link text holding a closed code span, full and collapsed reference prose, and pipes in prose and in code spans.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A data-loss tier visible on a reference renderer is prose to both readers, and a CLEARED round seals over it at minor. The rule's claim that a span the reader invents cannot hide a tag fails, because the reader's code spans are placed by CommonMark while marked places them after these two constructs.
- **Class-wide fix:** Derive the refused constructs from what each reference renderer binds before a code span, GFM's extended autolinks and marked's reference tokenizer included, or narrow further.
  - **Narrowing.** Inside a finding, refuse a backtick inside a bracket pair, or inside a URL literal, that some reading places outside every code span, as M1 does.
  - **Rows.** Add one row per spelling in both passes, and one end-to-end case per construct.

### Finding O-025
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** Inside a finding, below a minor tier, sits a GFM table whose second column carries a data-loss tier.
  - **The member.** The table's lines are a header line `| Step | Result |`, a delimiter line `| - | - |`, and a row `| ran | x |` whose `x` is the canonical bold Severity label followed by `data-loss`.
  - **The renderers.** markdown-it and marked both render a table whose second cell starts with a bold Severity label and data-loss. That is the rendering the gate refuses when it is written as a raw td tag, because td is in its own list of block-level tags after which a renderer starts a new line (`:619`).
  - **The gate's reading.** The label reader reads the first word of each line and of each run, and the text after each br or block-level tag. It never splits a line at a pipe, so the cell's tier is prose, and nothing in the narrowed grammar refuses a table.
  - **A list-item spelling.** The same table indented under a list item, with alignment colons in the delimiter line, behaves the same in both renderers and both passes.
- **Where:** scripts/verification-lib.sh:632, scripts/verification-lib.sh:617, scripts/verification-lib.sh:619, scripts/verification-lib.sh:364, scripts/verification-lib.sh:701, scripts/verification-lib.sh:676, scripts/verification-lib.sh:1711, scripts/verification-lib.sh:1942, templates/verification-contract.md:371
- **Reproduced:** Every case ran in my copies, under both locales.
  - **Direct runs.** On CUR, `vf_reports` exits 0 with empty stderr for both spellings in both passes. The catalog records G-050, or the manifest's G-042, at minor.
  - **Controls.** A one-column table whose only cell is the tier is refused with `a Severity line this grammar cannot read in finding G-050`. The same tier after a raw td tag is refused with `raw HTML outside a code span in finding G-050`.
  - **End to end.** The table seals a CLEARED round 1 in both passes under both locales, as a canonical new G-050 and as a manifest G-042 re-recorded at minor. The completion line is `round completed gate=opponent round=1 verdict=CLEARED`, and `tally` reports `blocking=0 minor=1`.
  - **PRE.** Every case also passes on PRE. The gap dates from the label reader itself, not from this repair.
  - **History.** No delimiter line stands inside any finding of 001's, 002's or 003's opponent and reality-check reports. Each reality-check report holds one table, outside every finding.
  - **M2.** M2 refuses, inside a finding, a line that may be a GFM delimiter line: hyphen cells with optional colons and at least one pipe. It prints `a table delimiter row in finding G-050`, or `... G-042` in the manifest pass. M2 refuses both spellings in both passes and both locales, and pipes in prose and in code spans still parse.
- **Root cause:** plan-gap
- **Blocks:** REQ-011, AC-009, AC-012
- **Wrong behavior:** A data-loss tier rendered as the first text of a table cell, which both reference renderers show, is prose to both readers. A CLEARED round seals over it at minor.
- **Class-wide fix:** Narrow the finding grammar to exclude tables, or read them.
  - **Narrowing.** Inside a finding, refuse by name a line that may be a table delimiter line, as M2 does.
  - **Reading.** Alternatively, read the label after every unescaped pipe in a run that holds a delimiter line. GFM splits cells inside code spans too, so that reading cannot skip spans.
  - **Rows.** Add rows in both passes and one end-to-end case.

### Finding O-023
- **Class:** gate-report-schema-validation
- **Status:** reopened
- **Prior:** O-023
- **Severity:** degraded
- **Scenario:** A finding's field holds a run of sub-bullets, each of which begins with a link, written as `  - [step 1](https://x.example/1) ran ...`. An image or a bracket other than a task checkbox at the start of each line does the same.
  - **The mechanism.** `vf_settled_word` checks brackets only in `vf_settled_head`, which stops at the end of the first word. A pair that opens before the first word and closes after it is therefore open in the head. The candidate is never settled, and every later line of the run re-reads it through `vf_label`.
  - **PRE.** PRE settled these candidates, because it checked bracket balance over the whole text.
  - **Direct calls.** `vf_settled` returns 0 on CUR and 1 on PRE for each of these texts: `- [the log](x) shows exit 0`, `  - ![badge](y.png) step 3`, `1. [step](u) ran`, and a line led by a code span holding a bracket that is not a checkbox. For round 17's shapes it returns 1 on CUR and 0 on PRE.
- **Where:** scripts/verification-lib.sh:557, scripts/verification-lib.sh:566, scripts/verification-lib.sh:583, scripts/verification-lib.sh:609, scripts/verification-lib.sh:709, templates/verification-contract.md:380
- **Reproduced:** I timed one canonical round whose Reproduced field holds n sub-bullets of the form `[step i](https://x.example/i) ran`, followed by a code span, emphasis and another code span, which is T030o53's own timing shape with its link moved to the front.
  - **CUR.** It takes 2.8 s at 50 lines, 29.4 s at 100, 145 s at 150 and 373 s at 200, each at exit 0. Doubling the run from 100 to 200 lines multiplies the time by 12.7.
  - **PRE.** It takes 0.10 s at 100 lines and 0.32 s at 400.
  - **The bound.** T030o53's acceptance requires that 400 sub-bullets with code spans, links and emphasis parse in under 30 s, and that doubling the run at most quadruples the time. Its timing row keeps each link after the first word.
  - **History.** The history is unaffected. 003's opponent report takes 1.47 s on CUR (1.52 s on PRE), and no line of 001's, 002's or 003's reports begins with link text.
  - **M3.** M3 settles a reading when its head's brackets balance or its whole text's brackets balance with complete destinations. That is the union of T030o53's rule and T030o50's, each argued sound alone. M3 takes 0.17 s at 200 lines and 0.32 s at 400, and round 17's shape stays at 0.31 s at 400 lines.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** It fails slow, not open, and it is slower than the round-17 tree on a shape that tree parsed at once. Completing a round and running `tally` each re-read the whole report, so one such run costs minutes on every later read.
- **Class-wide fix:** Count a bracket before the first word as unsettling only while that reading leaves it unclosed, or settle on either test, as M3 does. Add a 400-line timing row whose sub-bullets begin with a link, an image and a code span holding a bracket.

### Held up / follow-up tasks

**Held up:**
- **T030o51 under CommonMark 0.31.2.** It holds for every construct those productions bind before a code span. Each of these was refused by name in both passes and both locales:
  - a destination with nested parentheses holding a backtick;
  - a title holding a backtick in parentheses and in single quotes;
  - a title separated from the destination and the closing parenthesis by tabs;
  - email autolinks whose local part begins with a hash, a tilde or a single quote.
  - A character reference spelling the br tag renders as text and parses, which is right.
  - By reading `vf_cm_dest` and `vf_cm_label` against 6.3, an invalid pointy destination, a control character in a destination and an unescaped parenthesis in a parenthesized title can only over-refuse. Every character 6.5 lets an email local part begin with is in `vf_cm_ac` or the raw-HTML class.
  - marked 17.0.5's strikethrough respects code spans, and GFM's email literal takes no backtick.
- **T030o52.** It holds. Every list-marker form I tried is refused: an ordered marker with a parenthesis, a marker followed by a tab, nested markers, and an item whose first line is empty (the canonical pass refuses that one by its item rule first).
  - A fence behind a block-quote marker is not refused. Every line it holds needs the marker too, though, and neither pass reads a marker-led line as a heading, so the data-loss line after it is refused with `a Severity line this grammar cannot read in finding G-050`.
  - Both renderers agree that a column-zero fence after an item leaves the item.
  - Definitions are refused after list and quote markers in either order, and the shipped rows cover labels across lines and escaped labels. A footnote definition is refused as a definition.
- **T030o53's soundness.** I found no candidate the new rule settles whose first word a later line can change.
  - Joining adds a space, so emphasis and references never merge across lines.
  - An image that takes the first word needs its opening bracket in the head of some reading. The inert reading keeps a leading code span's letters, and a span with none leaves the bracket in the head.
  - A destination left open in the head unsettles the candidate.
  - A definition ends at its line end, so the next line is a candidate of its own.
- **The folded minor.** It holds. A tag on the first Finding heading of a round is refused under the finding it opens, a later Finding heading is refused under its own ID, and a section heading that closes a finding is outside it.
- **Positives.** No new positive row asserts an attack at exit 0.
- **Mutant suites.** Under MALL (M1, M2 and M3 together), `tests/test-gate-contracts.sh` passes 18/18 at exit 0 and `tests/test-spec-gate.sh` passes 8/8 at exit 0.
- **History under the mutants.** MALL and M3 each leave every output byte-identical to CUR, under both locales. That covers the catalogs, diagnostics and exits of 001's, 002's and 003's opponent and reality-check reports (001's opponent report stays at exit 3), their tallies, 003's 2026-09-09 manifest, and the 16 returned round reports read as manifests.

**Follow-up tasks proposed:**
- T030o54: Inside a finding, refuse a backtick inside a bracket pair, or inside a GFM URL literal, that some reading places outside every code span; or derive the constructs from what marked binds before a code span. Add rows in both passes and one end-to-end case per construct (→ O-018).
- T030o55: Inside a finding, refuse by name a line that may be a GFM table delimiter line, or read the label after every unescaped pipe of a table run. Add rows in both passes and one end-to-end case (→ O-025).
- T030o56: Settle a candidate when a bracket before the first word is closed in that reading, not only when the head balances. Add a 400-line timing row whose sub-bullets begin with a link, an image and a code span holding a bracket (→ O-023).
<!-- gate-round-end: opponent:18 -->

## Round 19

**Round:** 19
**Timestamp:** 2026-10-15T08:06:13Z
**Source:** 1f0774ddf738539f83236db08fa7f8847c3e9a276964fc5582730ed6bd5c8a66
**Floor:** FLOOR-GCDl2x
**Verdict:** CLEARED
**Blocking:** 0 · **Minor:** 3

### What I attacked

I worked only in a copy under `/private/tmp/opp19/work`, with `TMPDIR` ending in `/`. CUR is the frozen tree: its four repair files hash as `r19-edits/post-apply.sha256`. PRE is CUR with the kernel hunk of `r19-session.diff` reversed; its kernel hashes as `r18-edits/post-apply-3.sha256` (`62a17f93…`), round 18's tree. In the worktree I created nothing except this report, ran no floor, round, checkpoint, capture, accept, suite or test function there, and sourced nothing from its `tests/`. The only containers I ran were throwaway ones of `oven/bun:1` and `zricethezav/gitleaks:v8.24.3`, with `--rm`, `--network none` and my copy mounted read-only.

- **Scope.** The three repairs in both readers of finding records: the manifest pass (`scripts/verification-lib.sh:1733`) and the canonical pass (`:1964`).
  - **T030o54.** `vf_cm_open_tick`, `vf_cm_url`, and the new bracket, colon and `w` arms of `vf_cm_scan` (`:514-540`).
  - **T030o55.** `vf_para_delim` (`:683-686`) and its arm in `vf_para` (`:707`).
  - **T030o56.** `vf_settled_word` (`:584-586`).
  - **Also.** The contract text (`templates/verification-contract.md:383-406`), the new rows in both suites, the REQ-011 revision, and the consumers of `vf_cm_scan` (`vf_para` and `vf_settled`).
- **Derivation.** I worked from the sources the reference renderers ship, not from round 18's spellings.
  - **marked 17.0.5.** I read its inline lexer order (escape, tag, link, reflink, emStrong, codespan, br, del, autolink, url, text) and its GFM text rule.
  - **markdown-it 12.3.2.** I read `lib/helpers/parse_link_label.js` and `lib/rules_inline/backticks.js`.
  - **Tables.** I checked the delimiter-row grammar of both renderers.
- **Runs.** I ran every member directly through `vf_reports` in both passes, under `LANG=C` and `LANG=en_US.UTF-8` with every `LC_*` removed, on CUR and on PRE.
  - **End to end.** I ran `spec-gate.sh floor`, `round`, `round --complete` and `tally` with the suite's own `make_verification_git_dir`, `floor_fixture` and `record_line_report`, in a file of my own inside my copy.
  - **Rendering.** I rendered with the marked and markdown-it binaries that `r19-repro.sh` names.
- **Portability.** The shipped round-18 rows (the seven O-018 members and the table) and the shipped positives give the same exit codes and diagnostics under four awks:
  - macOS awk 20200816 and gawk 5.4.0, each in both locales;
  - mawk 1.3.4, in the `oven/bun:1` container;
  - BusyBox 1.36.1 awk, in the gitleaks container.
- **History.** These outputs are byte-identical between CUR and PRE under both locales: catalogs, stderr and exit codes for 001's, 002's and 003's opponent and reality-check reports, with 003's manifest (001's opponent report stays at exit 3). So are the outputs for all 41 report files carrying a Finding heading, each read as a prior-review manifest.
- **Differential fuzz of the settled rule.** I compared CUR against a mutant whose `vf_settled` never settles, over 84,000 generated runs. Of those, 60,000 were led by a bracket construct before the first word, which is the shape T030o56 newly settles.
- **Differential fuzz of the narrowed grammar.** I generated 220,000 finding bodies of one or two lines, each carrying a br tag followed by a data-loss tier. 1,334 of them pass the gate, and 57 of those show the tier after a live br in a renderer: 53 in marked and 4 in markdown-it. Every one of the 57 is a member of O-026 or O-028.
- **Mutants.** I disabled each new guard in turn and ran the shipped rows against it. Results are under Held up.
- **Suites.** In my copy, `tests/test-gate-contracts.sh` passes 18/18 at exit 0 and `tests/test-spec-gate.sh` passes 8/8 at exit 0.

### Finding O-026
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** Inside a finding, below a minor tier, a line puts a tilde directly before a backtick run that CommonMark pairs into a code span holding a br tag, written `` It took ~`<br>Severity: data-loss` here. ``.
  - **The gate's reading.** It places code spans by CommonMark 6.1, so the tag reads as inside a span. `vf_narrow` stays empty, and `vf_label_inert` makes the tag inert for the break reading.
  - **marked's reading.** The GFM text rule, written `` ^([`~]+|[^`~]) ``, takes a run of tildes and backticks as one piece of text once strikethrough fails at the tilde. The backtick never reaches the codespan rule, so the tag is live and the tier is the first text of the rendered line.
  - **The other renderer.** markdown-it renders a code span.
  - **Reach.** No definition is needed, and the member fits on one line. A tilde used for "about" before a code span is ordinary prose.
- **Where:** scripts/verification-lib.sh:529, scripts/verification-lib.sh:550, scripts/verification-lib.sh:556, scripts/verification-lib.sh:698, scripts/verification-lib.sh:1733, scripts/verification-lib.sh:1964, templates/verification-contract.md:369, templates/verification-contract.md:390
- **Reproduced:** Every case ran in my copy, and the control was checked by its exact diagnostic.
  - **Direct runs.** On CUR and PRE, `vf_reports` exits 0 with empty stderr in both passes and both locales. The catalog records G-050, or the manifest's G-042, at minor.
  - **Control.** `Note <br>Severity: data-loss.` is refused with `raw HTML outside a code span in finding G-050`.
  - **End to end.** The member seals a CLEARED round 1 in both locales as a canonical new G-050, and under `LANG=C` as a manifest G-042 re-recorded at minor. Each completion prints `round completed gate=opponent round=1 verdict=CLEARED`, and `tally` reports `blocking=0 minor=1`.
  - **Fuzz.** All 53 marked-only cases of the fuzz are this mechanism.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** A data-loss tier visible on marked is prose to both readers, and a CLEARED round seals over it at minor. T030o54's acceptance names the URL literal and the bracket pair as the constructs marked binds before any code span, but marked's text rule binds a third. Under REQ-011 as revised, this is a rendering divergence that the documented grammar neither reads nor refuses (it reads a code span), so it is minor.
- **Class-wide fix:** For the follow-up spec, inside a finding refuse a backtick run that directly follows a tilde outside every code span. More generally, derive code-span placement from each reference renderer's lexer, not from CommonMark alone. Add rows in both passes.

### Finding O-027
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** Inside a finding, below a minor tier, a shortcut reference label holds a backtick and wraps onto the next line. A definition of that label stands outside every finding.
  - **The member.** The first line is ``` Note [a``b ```, the second is ``` c`]<br>Severity: data-loss `` ` . ```, and the definition outside the finding is ``` [a``b c`]: https://x.example/ ```.
  - **The gate's reading.** T030o54 judges only a bracket pair closed on its line, so the open label goes unchecked. Both readings of the second line put the tag inside a code span:
    - in the reading where the first line's span is still open, the double-backtick run closes that span after the tag;
    - in the fresh reading, the label's own backtick opens a span that the final backtick closes.
  - **marked's reading.** Its label grammar allows a line ending and a backtick, so it binds the reference across the lines. The label's backticks open nothing, and marked renders the link, then the live tag, then the tier.
  - **markdown-it's reading.** markdown-it 12.3.2 shows the tag live even without the definition, through O-028's mechanism.
- **Where:** scripts/verification-lib.sh:537, scripts/verification-lib.sh:509, scripts/verification-lib.sh:529, scripts/verification-lib.sh:698, scripts/verification-lib.sh:1733, scripts/verification-lib.sh:1964, templates/verification-contract.md:386
- **Reproduced:** Every case ran in my copy.
  - **Direct runs.** On CUR and PRE, `vf_reports` exits 0 with empty stderr in both passes and both locales. The catalog records G-050, or the manifest's G-042, at minor.
  - **End to end.** The member seals a CLEARED round 1 in both locales as a canonical new G-050, and under `LANG=C` as a manifest G-042 re-recorded at minor. `tally` reports `blocking=0 minor=1`.
  - **Rendering.** I rendered the whole canonical report with the definition added. Both renderers show the minor field line, and then the data-loss tier right after a live tag.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** A data-loss tier visible on both renderers is prose to both readers, and a CLEARED round seals over it at minor. This is the O-018 mechanism with the label wrapped, which T030o54 left out by design. It is a rendering divergence outside the documented narrowing, so it is minor under REQ-011 as revised.
- **Class-wide fix:** Inside a finding, refuse a shortcut, collapsed or image reference label that holds a backtick and does not end on its line, as the arm at `:544` already does for a full reference's label. Add rows in both passes.

### Finding O-028
- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** Inside a finding, below a minor tier, one line carries a bracket that closes on no later character of the line, then a double-backtick pair holding a br tag, then a lone backtick: ``` Note [a``b c`<br>Severity: data-loss `` ` . ```.
  - **markdown-it's reading.** In markdown-it 12.3.2, the link-label scan calls `skipToken`, which skips the backtick pair silently without caching its closer (`parse_link_label.js:28`, `backticks.js:54`). The lone backtick then marks the line as scanned (`backticks.js:58`). When the main pass reaches the pair, it reads the pair as literal text (`backticks.js:23`), so the tag is live and the tier starts a rendered line.
  - **The other readings.** CommonMark, marked and the gate all read a code span.
  - **Reach.** No definition is needed, and the member fits on one line.
- **Where:** scripts/verification-lib.sh:537, scripts/verification-lib.sh:550, scripts/verification-lib.sh:698, scripts/verification-lib.sh:1733, scripts/verification-lib.sh:1964, templates/verification-contract.md:369
- **Reproduced:** Every case ran in my copy.
  - **Direct runs.** On CUR and PRE, `vf_reports` exits 0 with empty stderr in both passes and both locales.
  - **End to end.** The member seals a CLEARED round 1 in both locales as a canonical new G-050, and under `LANG=C` as a manifest G-042 re-recorded at minor. `tally` reports `blocking=0 minor=1`.
  - **Rendering.** markdown-it shows the tier after a live tag, and marked shows a code span.
  - **Fuzz.** The four markdown-it-only cases of the fuzz are all this mechanism, each with a bracket left open before a backtick pair.
- **Root cause:** spec-gap
- **Blocks:** none
- **Wrong behavior:** A data-loss tier visible on one reference renderer is prose to both readers, and a CLEARED round seals over it at minor. The cause is a renderer bug, but the spec names no renderer the grammar must agree with. It is minor under REQ-011 as revised.
- **Class-wide fix:** In the follow-up spec, name the renderers a report must agree with, or refuse inside a finding a bracket left open on its line that precedes a backtick run. Add rows in both passes.

### Held up / follow-up tasks

**Held up:**
- **O-018's repair (T030o54) on one line.** It holds. All seven round-18 members are refused by name in both passes and both locales, on all four awks. So are the following variants:
  - an upper-case scheme, an upper-case `WWW.`, and a scheme directly after a letter;
  - a label holding an escaped bracket;
  - a label nested in another bracket pair.
  - **marked's single-line binds.** The URL rule's text runs up to whitespace or an angle bracket, and the gate's scan stops only at a space, a tab or an angle bracket, so the gate scans at least as far. The label grammar admits no unescaped bracket, which `vf_cm_label` mirrors.
  - **The class.** It stays open for wrapped labels (O-027) and for constructs outside the enumeration (O-026, O-028), all minor under the revision.
- **O-025's repair (T030o55).** It holds.
  - **Refused.** Delimiter rows with alignment colons, in a list item, behind block-quote markers, and without outer pipes are all refused by name.
  - **Why the strip is safe.** markdown-it 12.3.2 accepts only pipes, hyphens, colons, spaces and tabs on a delimiter line, and marked only spaces as padding. Both are subsets of what `vf_para_delim` strips.
  - **Single-column tables.** marked accepts one with a colon and no pipe, but each of its cells is a whole line, which the line reader reads.
  - **Recorded, not graded.** A Markdown table quoted inside a fenced code example within a finding is now refused, where PRE parsed it. That matches the contract's rule that tables stay outside every finding.
- **O-023's repair (T030o56).** It holds.
  - **Timing.** The round-18 shape takes 0.35 s at 400 lines and 0.70 s at 800 on CUR, against 2.8 s at 50 and 28.4 s at 100 on PRE.
  - **Soundness.** Each half of the union was argued sound in rounds 17 and 18. The 84,000-run fuzz found no line where the never-settling mutant reads a label that the passes miss on CUR.
  - **No regression.** A 400-line run kept unsettled by a lone backtick takes 29.0 s on CUR and 28.7 s on PRE, so the new scan arms cost nothing measurable.
- **Mutants.** Disabling each of these guards turns its shipped rows to exit 0: the bracket arm (three reference rows), the colon arm (three URL rows), the `www.` arm (one row), the `ftp` alternative (one row) and the delimiter arm (the table row).
  - **One survivor.** Dropping `tolower` from the colon arm survives every shipped row. marked binds an upper-case scheme (`HTTP://`), so the guard is needed today but unpinned. Add one upper-case row.
- **The REQ-011 revision.** I do not challenge it. It sits inside REQ-011's own carve-out, and no AC, REQ, FM or INV row requires agreement with a renderer (I checked FM-016, FM-019, INV-004 and INV-006). I graded all three findings under it; without it, O-026 and O-027 would each block as wrong-result.
- **Positives.** No new positive row asserts an attack at exit 0. I rendered the nine new positive bodies and the timing row, and none shows a tier as a first word.
- **A documentation gap, not graded.** The report shape in `agents/opponent.agent.md` does not state the narrowed finding grammar, which lives only in the contract and in invoker briefs. A gate agent that follows the persona alone can write a table or a link inside a finding and be refused at completion by name. It fails closed.

**Follow-up tasks proposed** (for the follow-up spec that REQ-011 names):
- F1: Inside a finding, refuse a backtick run directly after a tilde outside every code span, or place code spans by marked's text rule in one more reading. Add rows in both passes (→ O-026).
- F2: Inside a finding, refuse a shortcut, collapsed or image reference label that holds a backtick and does not end on its line. Add rows in both passes (→ O-027).
- F3: Name the reference renderers in the spec, or refuse a bracket left open on its line before a backtick run. Add rows (→ O-028).
- F4: Add an upper-case scheme row for the URL-literal arm, and state the narrowed finding grammar in `agents/opponent.agent.md`.
<!-- gate-round-end: opponent:19 -->

## Round 20

**Round:** 20
**Timestamp:** 2026-10-16T02:09:54Z
**Source:** 9cf02d45d97952557c41180743b973563e854825d6d2d5e73b1db3b72be4dfa5
**Floor:** FLOOR-UeGEcf
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 3

### What I attacked

I worked only in a copy under `/private/tmp/opp20/work`, built from the live enumeration (`git ls-files --cached --others --exclude-standard`) and git-initialized, with `TMPDIR` ending in `/`. The four files that matter hash identically in the copy and the worktree: `scripts/verification-lib.sh` `015859de…`, `tests/test-spec-gate.sh` `a5c7a0d0…` (the hash the capture of record `r20-capture.log` names), `tests/test-verification.sh` `8b07ca66…` and `tests/test-gate-contracts.sh` `f927e872…`. In the worktree I created nothing: my file tool refused to write the report path, so the invoker persists this block. I ran no floor, round, checkpoint, capture, accept, suite or test function there, and sourced nothing from its `tests/`. I ran no container.

- **Scope.** The delta in `r20-session.diff`: T031a1 (`acceptance_named_cases`), T031a2 (the new tail of `reuse_floor_cases`, `gate_execute_fixture` and the new block of `capture_validity_cases`), T031a3 (`annotate_002` and `tally_class_cases`) and T031a4 (`round_legacy_reconcile_cases`). Also the kernel paths each case drives: `vf_return_parse`, `vf_return_check`, `vf_capture_check`, `vf_task_capture_matches`, `vf_gate_execute`, `vf_tally`, `vf_round_history`, `vf_round_authorized` and the `--reconcile` branch of `vf_gate_round`. I read the criteria from `spec.md` (AC-007, AC-009, AC-010, AC-020, AC-022, REQ-012), the matching plan text (the authorization grammar and the return grammar) and the four task blocks.
- **Method.** I ran each new case on its own through a runner that sources a rewritten copy of its suite: the helpers path made absolute, and the final `t_run_all` replaced by a loop over named functions with the same sandbox and failure handling. All five cases pass under `/bin/bash` 3.2.57 with the macOS awk, and again with gawk 5.4.0 as `awk`. Then I mutation-isolated each case against the kernel guard that implements the behaviour its comment names. Each mutant is one exact-anchor replacement in the copy's `scripts/verification-lib.sh`, applied by a script that refuses unless the anchor occurs once, run, and restored with `cmp`.
- **T031a1 mutants.** Killed: parse accepting a missing `Failure modes:` block (the diagnostic becomes `required Failure modes are missing`); removing the exit check (it becomes `capture stale: current inputs changed`); dropping the argv comparison from `vf_task_capture_matches` (the unrelated capture is accepted); skipping the manual check when the artifact is absent. Survived: dropping the explicit-none requirement for an empty required set (O-030).
- **T031a2 mutants.** Making `vf_gate_execute` argv-blind (dropping its `cmp` of argv) is killed by `capture_validity_cases` (`old:1 old:1` instead of `old:1 new:0`) and survives `reuse_floor_cases`, because the changed command lives in `.specify/stack.yml`, which the input identity hashes. The test's own comment hands argv isolation to the capture case, so I hold this (below).
- **T031a3 mutants.** Recurrence keyed by Class and file, and by file alone, are both killed by the synthetic fixture. A `vf_tally` that appends to the history it reads survives `tally_class_cases` and `shipped_002_tally_case` (O-031).
- **T031a4 mutants.** Removing the date-only refusal is killed by its exact diagnostic. Survived: the reconciled timestamp replaced by midnight of the history's date; the reconcile-time digest and round check removed; and all legacy binding removed at once, both in `vf_round_history` and in `--reconcile` (O-029).
- **Full suites under mutation.** On two further copies, `bash tests/run.sh` under the explicit-none mutant: exit 0, 147/147 over 15 suites. Under the combined legacy mutant: exit 0, 147/147.
- **Probes on the unmutated kernel.** These show the kernel is right where the fixtures are silent.
  - A waiver dated 2026-07-20T12:00:00Z after reconciling round 5 to 23:59:59Z is refused at exit 4 with `not after the previous round completion at 2026-07-20T23:59:59Z`.
  - A reconcile record naming a wrong digest, a wrong round, or a timestamp before the history's date exits 3 and writes no `legacy-time.nul`.
  - After a valid reconciliation, appending one line to the history makes `waiver` and `round` exit 3 with empty output (O-032).
  - A no-row task returning an empty `Failure modes:` header is refused with `return: empty required set must explicitly be none`.
- **Claims.** `r20-return-T031a{1,2,3,4}.rc`, `T031a{1,2,3,4}-accept.rc`, `r20-floor-2.rc`, `r20-floor-validate.rc`, `r20-reserve.rc` and `r20-scope.rc` all read 0. All four tasks are ticked. The reservation fields match `ROUND-20/meta.nul`.
- **Not examined.** Linux with GNU sed and mawk; hosted CI, which has not run on this source; O-026 to O-028, since no report-grammar code changed in this delta; and the known-open list in the brief, which I did not re-litigate.

### Finding O-029
- **Class:** named-case-fixture-strength
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** `round_legacy_reconcile_cases` reconciles a copy of shipped 002's date-only history to round 5 at 2026-07-20T23:59:59Z, then writes a waiver stamped with the current clock (2026-10-16) and asserts it authorizes round 6. That waiver is later than the reconciled timestamp and also later than any reading of the history's date, so the fixture cannot tell whether ordering uses the reconciled time at all.
  - **Ordering.** No case dates a waiver between the history's date and the reconciled time, where only the reconciled timestamp decides.
  - **Digest binding.** No case reconciles with a wrong digest or round, or edits the history after reconciling.
  - **What the texts promise.** The plan says a legacy round needs a reconciliation record identifying the old report digest before ordering an authorization. AC-009 says reconciliation is for authorization ordering. T031a4's acceptance says the record is bound to the history's digest.
- **Where:** tests/test-spec-gate.sh:1120, tests/test-spec-gate.sh:1121, tests/test-spec-gate.sh:1123, tests/test-spec-gate.sh:1124, tests/test-spec-gate.sh:1126, scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3406, scripts/verification-lib.sh:3581, scripts/verification-lib.sh:3583
- **Reproduced:** In my copy, each mutant applied and restored with `cmp`.
  - **Timestamp ignored.** `vf_round_history` takes `VF_ROUND_TIME` from the history's date at midnight instead of the record (`:3406`). `round_legacy_reconcile_cases` passes. My probe's early waiver (2026-07-20T12:00:00Z) then prints `authorized: opponent round 6` at exit 0. Unmutated, it is refused at exit 4 with `not after the previous round completion at 2026-07-20T23:59:59Z`.
  - **Reconcile checks removed.** Dropping the digest and round check at `:3581` passes the case.
  - **All binding removed.** Removing `:3405`, `:3581` and `:3583` together and ignoring the timestamp passes the case, and the full suite gives exit 0 at 147/147. Under that mutant any file holding the three keys unlocks round 6.
- **Root cause:** implementation-error
- **Blocks:** AC-009, REQ-012
- **Wrong behavior:** The suite now certifies AC-009's legacy clause, but the three checks that make a reconciliation an ordering record bound to one history can each be deleted with every suite green. A regression there would let a waiver written before a legacy history's real last completion authorize the next round. It would also let a reconciliation outlive an edit of the history it names. That bypasses the per-round cap REQ-012 requires, while the fixture added for AC-009 stays green.
- **Class-wide fix:** Test files only. In `round_legacy_reconcile_cases`, assert the refusals that only the reconciled record can decide.
  - **Before the valid reconcile.** A wrong digest, a wrong round and a timestamp before the history's date each exit 3, write no `legacy-time.nul`, and leave the next round refused with the date-only diagnostic. Assert that observable state, since the kernel names none of these refusals (O-032).
  - **After it.** A waiver dated 2026-07-20 before 23:59:59Z is refused with `not after the previous round completion at 2026-07-20T23:59:59Z`. The current waiver is authorized.
  - **After editing the history.** Neither `waiver` nor `round` authorizes or reserves anything.
  - **Check.** Each new assertion must be killed by one of the three mutants above.

### Finding O-030
- **Class:** named-case-fixture-strength
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** AC-022 names no assigned rows with explicit none, and the plan's return grammar says that if the required set is empty, a return must carry `Failure modes: none`. `acceptance_named_cases` asserts only that T006, which owes no rows, is accepted with an explicit none. Nothing returns an empty `Failure modes:` header, or a header followed by narrative, for a task that owes no rows.
- **Where:** tests/test-spec-gate.sh:171, tests/test-spec-gate.sh:172, tests/test-spec-gate.sh:173, scripts/verification-lib.sh:2861
- **Reproduced:** I replaced the guard at `:2861` with one that only refuses mappings, so a block without `none` is accepted. `acceptance_named_cases` and the whole `test_acceptance` still pass, and the full suite gives exit 0 at 147/147. Unmutated, my probe's empty header for T006 is refused with `return: empty required set must explicitly be none`. Under the mutant it prints `accept accepted task=T006`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The explicit part of the named case is unprotected: a regression could accept an empty block for a no-row task, and every suite would stay green. The task owes nothing, so no row is lost, which is why this is minor.
- **Class-wide fix:** In `acceptance_named_cases`, before the explicit-none acceptance, return T006 with an empty `Failure modes:` header and refuse it with `empty required set must explicitly be none`, with tasks.md byte-identical. Generally, pair each accepting case with the refusal that gives its qualifier meaning.

### Finding O-031
- **Class:** named-case-fixture-strength
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** `tally_class_cases` asserts that the 002 copy and the shipped 002 notes keep their hash, labelled as AC-010's clause that original shipped artifacts are not rewritten. Nothing in between can write either file: `annotate_002` reads the copy on standard input, and `tally` runs on a third file, `$SANDBOX/annotated`. `shipped_002_tally_case` runs `tally` on its copy without hashing it afterwards.
- **Where:** tests/test-gate-contracts.sh:2294, tests/test-gate-contracts.sh:2295, tests/test-gate-contracts.sh:2300, tests/test-gate-contracts.sh:2301, tests/test-gate-contracts.sh:558
- **Reproduced:** I made `vf_tally` append a comment line to the history it reads, after it reports. `tally_class_cases` and `shipped_002_tally_case` both still pass. Run on the live tree, this mutant would rewrite shipped 002's notes.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The two byte-identity assertions can never fail, so the no-rewrite clause is held by construction, not by test. Today's `vf_tally` writes nothing, which is why this is minor.
- **Class-wide fix:** Hash each file `tally` reads before and after the run: `$SANDBOX/annotated/notes/opponent.md` in `tally_class_cases`, and the copy in `shipped_002_tally_case`. Keep the copy check, which proves only that `copy_kit` is faithful, and label it that way.

### Finding O-032
- **Class:** round-recovery-diagnostics
- **Status:** new
- **Prior:** none
- **Severity:** degraded
- **Scenario:** An operator reconciles a legacy date-only history, then appends or corrects a line in it, or first writes a reconcile record with a wrong digest, a wrong round, or a timestamp before the history's date. These refusals all exit 3 and print nothing, from `round --reconcile`, from `waiver` and from `round` alike. REQ-012 requires malformed or incomplete existing records to fail closed with a named recovery action.
- **Where:** scripts/verification-lib.sh:3404, scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3406, scripts/verification-lib.sh:3580, scripts/verification-lib.sh:3581, scripts/verification-lib.sh:3582, scripts/verification-lib.sh:3583
- **Reproduced:** On the unmutated copy, through the fixture's own `floor_fixture` CLI on a copy of 002's history: wrong round, `rc=3 out=[]`; timestamp before the date, `rc=3 out=[]`; valid reconcile, then one appended line, gives `waiver` `rc=3 out=[]` and `round` `rc=3 out=[]`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The cap holds, since every case fails closed, which is why this is degraded. But the operator gets no cause and no recovery step. Every later `round` and `waiver` call for that gate stays silent at exit 3 until someone finds `legacy-time.nul` by reading the source. Fixtures can assert only exit codes and state here, never a diagnostic.
- **Class-wide fix:** For the follow-up spec, since no kernel change is authorized now: give every `return 3` in the legacy-record read and in `--reconcile` a `round recovery:` diagnostic. Name the field that disagrees and the recovery, which is to re-run `round --reconcile` with a record for the current history digest. Then assert those diagnostics in the O-029 cases.

### Escalation

Round 20 is past round 3, and it raises one substantive new defect, O-029, and three minor ones.
- **The spec is right.** AC-009, REQ-012 and the plan's authorization text all say a legacy reconciliation exists to order authorizations against a timestamp bound to the history's digest. T031a4's acceptance says so too.
- **The method left the gap.** The fixtures were written from the reviewer's probes, which showed each case only in the direction the probe ran. The two-direction judging and the mutation pass that would have caught the missing directions were dropped by the user's decisions of 2026-10-14 and 2026-10-15, and nothing else caught them. Every surviving mutant here is a missing refusal beside an accepted positive.
- **The decision is the user's.** The repair for O-029 is test-only and small: three groups of assertions in one function. But it moves the source, so it needs a new floor, an authorized round 21, hosted CI and reality-check round 3. The alternative is to accept O-029's risk with a signed waiver in the Decisions log in STATUS.md. O-030 to O-032 do not block either way.

### Held up / follow-up tasks

Held up under attack:

- **T031a1, the other named cases.** Each refusal is pinned by its exact diagnostic, and four mutants of the guards behind them are killed: missing block, exit code, argv binding, and missing manual artifact. The failed capture is also stale, because `tests/check.sh` is restored before acceptance, but the exit check runs first, and its removal changes the diagnostic, so the case still fails. The expected-file comparison of the valid acceptance reproduces `vf_tasks_rewrite`'s Evidence placement and catches any other line changed.
- **T031a2.** The capture-level case holds the inputs fixed, reads `vf_gate_execute`'s six-field records correctly, and kills the argv-blind mutant. The floor-level case cannot isolate argv on its own, since the command lives in the hashed `stack.yml`. Its observable claim, that a changed command executes again with `cache-hits=0`, is true, and the `sed` also rewrites the `reuse_checks` entry, so the new command is still opted in and `cache-hits=0` is not merely a policy effect.
- **T031a3, the recurrence semantics.** Both file-keyed mutants are killed. `annotate_002`'s table matches the 002 text: 1.1 and 4.3 are the minute-less clock findings, and 2.1, 3.1 and 4.2 are the stale-lock findings of the lock lifecycle. The output parses canonically under gawk too.
- **T031a4, the refusal half.** It asserts the exact date-only diagnostic and that ROUND-6 is absent, and it kills the mutant that removes the refusal.
- **Shipped positives.** None of the new cases asserts an attack at exit 0. Each accepted input (a valid return, an explicit none, a correctly bound reconcile, a later waiver) is honest.

Follow-up tasks proposed:

- T031a4o1, test files only (→ O-029). Add the before, after and edited-history cases above to `round_legacy_reconcile_cases`, each shown killed by the timestamp, digest and combined mutants.
- T031a1o1, test files only (→ O-030). Add the empty-header refusal for the no-row task to `acceptance_named_cases`.
- T031a3o1, test files only (→ O-031). Hash the files `tally` reads before and after the run in `tally_class_cases` and `shipped_002_tally_case`.
- O-032 goes to the follow-up spec, since it needs a kernel change, which the user's decision of 2026-10-15 does not authorize. It is non-blocking.
<!-- gate-round-end: opponent:20 -->

## Round 21

**Round:** 21
**Timestamp:** 2026-10-16T19:05:21Z
**Source:** fd20f46a37268b1cd8bb7874982e3a26a1ce713a04418168d3c6b898edf76305
**Floor:** FLOOR-5cLeox
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 1

### What I attacked

I worked only in a copy under `/private/tmp/opp21/work`, built from the live enumeration (`git ls-files --cached --others --exclude-standard`) and git-initialized, with `TMPDIR` ending in `/`. The files that matter hash the same in the copy and the worktree: `scripts/verification-lib.sh` `015859de…`, `scripts/spec-gate.sh` `79f20eee…`, `tests/test-spec-gate.sh` `b94c7dfa…` (the hash `r21-dev.log` prints), `tests/test-gate-contracts.sh` `97beb809…` and `tests/helpers.sh` `b7bc6ff9…`. In the worktree I created nothing: my file tool refuses report files, so the invoker persists this block. I ran no floor, round, checkpoint, capture, accept, suite or test function there, sourced nothing from its `tests/`, and ran no container.

- **Scope.** The delta in `r21-session.diff`: T031a4o1 (`round_legacy_reconcile_cases`), T031a1o1 (`acceptance_named_cases`) and T031a3o1 (`records_digest`, `shipped_002_tally_case`, `tally_class_cases`). Also the kernel paths those cases drive: `vf_round_history`, `vf_round_authorized`, `vf_gate_waiver_check`, the `--reconcile` branch of `vf_gate_round`, `vf_return_check` and `vf_tally`. I read AC-009, AC-010, AC-022, REQ-012 and REQ-015 in `spec.md`, the plan's authorization paragraph, and the three task blocks.
- **Method.** Each case ran on its own through a runner that copies its suite into the copy's `tests/` with the final `t_run_all` replaced by one focus test, as `r21-dev.sh` does. Each mutant is an exact-anchor edit of the copy's `scripts/verification-lib.sh` that refuses unless its anchor occurs once. After every run the kernel was restored and checked with `cmp`. All runs used `/bin/bash` 3.2.57 and the macOS awk. Unmutated, all four cases pass.
- **O-029 mutants (12).** Killed: the reconciled time replaced by midnight of the history's date (round 20's); the read-path round and digest check removed, and its digest half alone; the reconcile check removed, its digest half alone and its round half alone; the whole date guard of `--reconcile`, and its before-the-date half alone. Survived:
  - the reconciled time replaced by the end of the history's date, 23:59:59Z (O-029 below);
  - the reconciled time clamped to that end of day when it is later (O-029 below);
  - the future half of the `--reconcile` date guard removed (O-029 below);
  - the read-path round check alone removed. I hold that one equivalent: only `--reconcile` writes a record, and it checks the round; the read path checks the digest, which fixes the history and so its last round.
- **O-030 mutant.** Round 20's mutant, the guard at `:2861` reduced to refusing mappings, is now killed by the new assertions (O-030 below).
- **O-031 mutants (3).** All killed: appending a comment line to the history after the report (round 20's), creating a new empty file under `notes/`, and appending a newline to an existing `reality-check.md` (O-031 below).
- **Probes on the unmutated kernel.** These ran through the fixture's own `floor_fixture` CLI on a copy of shipped 002's history.
  - A record reconciled to 2026-07-21T09:00:00Z, a day after the history's date, is accepted. A waiver dated 2026-07-21T08:00:00Z is then refused at exit 4 with `not after the previous round completion at 2026-07-21T09:00:00Z`, and `round` reserves nothing.
  - A record at 2026-07-20T18:00:00Z, inside the date, lets a waiver dated 19:00 that day authorize round 6.
  - After a valid reconcile and one appended line, `round --reconcile` with a correct record for the edited history exits 3 with empty output, and so does `round`. Only after I deleted `legacy-time.nul` by hand did the same record reconcile (O-032 below).
  - A record stamped 2099-01-01T00:00:00Z is refused at exit 3 and nothing is written.
  - A hand-written `legacy-time.nul` stamped 2026-07-19, before the history's date, is read with no date check, and a waiver dated 2026-07-19T12:00:00Z then authorizes round 6. I hold this outside the model (below).
- **Full suite under a mutant.** I started `tests/run.sh` on a second copy under the end-of-day mutant. I stopped it after the first two suites (12 of 147 tests, no failure), because free disk on `/` fell from 6.9 GiB to under 2 GiB through activity outside my directories, which stayed under 700 MiB. Instead I checked that the mutated line runs only when `legacy-time.nul` exists. No shipped spec holds one, and in `tests/` only `round_legacy_reconcile_cases` writes one, so the focus run decides that mutant for the whole suite.
- **Claims.** `r21-return-T031a{1,3,4}o1.rc`, `T031a{1,3,4}o1-accept.rc`, `r21-capture.rc`, `r21-floor-1.rc`, `r21-floor-validate.rc`, `r21-reserve.rc`, `r21-scope.rc` and `r21-freeze.rc` all read 0. The capture of record CAP-700-lvBf95 carries input `fd20f46a…` before and after, and shows 15 suites passing 147 of 147. `r21-dev.log` shows each of the 9 new O-029 assertions killed by one of round 20's three mutants, as the task block says. The reservation fields match `ROUND-21/meta.nul`, and all three tasks are ticked (`r21-postaccept.txt`).
- **Not examined.** Linux with GNU tools and mawk; hosted CI, which has not run on this source; a completed full-suite run under any mutant; O-026 to O-028, since no report-grammar code changed; and the brief's known-open list, which I did not re-litigate.

### Finding O-029
- **Class:** named-case-fixture-strength
- **Status:** open
- **Prior:** O-029
- **Severity:** wrong-result
- **Scenario:** The repair reconciles round 5 to 2026-07-20T23:59:59Z, which is also the end of the history's own date. A kernel that orders legacy authorizations against the end of the history's date, and never reads the record's timestamp, prints the same diagnostic for the early waiver. So the fixture cannot tell the reconciled time from a reading of the date.
  - **The test's own claim.** Its comment says that between the history's date and the reconciled time only the record decides. With the record at the end of the date, the record and the end-of-day reading decide the same way.
  - **The kernel accepts later records.** The `--reconcile` guard refuses only a stamp dated before the history's date or in the future, so a record on any later day is valid input.
  - **The plan's rule.** A waiver's timestamp must be later than the preceding completed or reconciled invocation. AC-009 says the reconciliation is for authorization ordering.
  - **The future half.** No case reconciles with a timestamp in the future, so the second half of the same guard can be deleted with the case green.
- **Where:** tests/test-spec-gate.sh:1153, tests/test-spec-gate.sh:1156, tests/test-spec-gate.sh:1157, tests/test-spec-gate.sh:1159, scripts/verification-lib.sh:3406, scripts/verification-lib.sh:3583
- **Reproduced:** In my copy, each mutant applied and restored with `cmp`.
  - **End of day.** `VF_ROUND_TIME` at `:3406` set to the history's date at 23:59:59Z: `round_legacy_reconcile_cases` passes. My probe then reconciles round 5 to 2026-07-21T09:00:00Z, accepted at exit 0, and writes a waiver dated 2026-07-21T08:00:00Z. Under the mutant that waiver prints `authorized: opponent round 6`, and `round` reserves round 6 on a current floor. Unmutated, it is refused at exit 4 with `not after the previous round completion at 2026-07-21T09:00:00Z`, and nothing is reserved.
  - **Clamp.** The record's time kept, but clamped to 23:59:59Z of the date when later: the case passes, and the same probe authorizes and reserves round 6.
  - **Future half.** The `! "$stamp" > now` half of `:3583` removed: the case passes. My probe's record stamped 2099-01-01T00:00:00Z is then written at exit 0. Unmutated, it exits 3 and writes nothing.
- **Root cause:** plan-gap
- **Blocks:** AC-009, REQ-012
- **Wrong behavior:** O-029's ordering clause is still unprotected for any record not stamped at the end of the history's date. A regression that reads the date instead of the record lets a waiver written before the reconciled completion authorize the next round, with every suite green. That bypasses the per-round cap REQ-012 requires, the way round 20 described. The task block prescribed 23:59:59Z, and the code follows it faithfully, which is why the root cause is plan-gap. A regression in the future half fails closed instead: one future record refuses every waiver until it is overwritten. That half alone would be minor.
- **Class-wide fix:** Test files only. In `round_legacy_reconcile_cases`, reconcile to a time that no reading of the date produces, on a later day, so that one record separates the record from both readings of the date.
  - **Record.** Reconcile round 5 to 2026-07-21T06:00:00Z, with the right digest.
  - **Refusal.** A waiver dated 2026-07-21T05:00:00Z is refused with `not after the previous round completion at 2026-07-21T06:00:00Z`. That kills midnight, end of day and the clamp.
  - **Future.** Before the valid reconcile, a record stamped 2099-01-01T00:00:00Z exits 3, writes no `legacy-time.nul`, and leaves the next round refused as date-only.
  - **Check.** Show each new assertion killed by the end-of-day, clamp and future-half mutants above, as well as by round 20's three.

### Finding O-032
- **Class:** round-recovery-diagnostics
- **Status:** open
- **Prior:** O-032
- **Severity:** degraded
- **Scenario:** An operator reconciles a legacy date-only history, then corrects one line in it. Round 20 named the recovery for the follow-up spec: re-run `round --reconcile` with a record for the current history digest. That recovery is itself refused.
  - **Why.** `vf_gate_round` reads the history with `vf_round_history` at `:3552`, before the `--reconcile` branch at `:3578`. The stale `legacy-time.nul` fails that read at `:3405` with exit 3, so the new record is never examined.
  - **Effect.** No CLI command recovers that gate. Only deleting `legacy-time.nul` by hand does, and nothing names that file.
- **Where:** scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3552, scripts/verification-lib.sh:3578, scripts/verification-lib.sh:3584
- **Reproduced:** On the unmutated copy, through the fixture's own `floor_fixture` CLI on a copy of 002's history: a valid reconcile, then one appended line, then `round --reconcile` with a record naming round 5 and the edited history's digest gives `rc=3 out=[]`, and `round` gives `rc=3 out=[]`. After I deleted `legacy-time.nul` by hand, the same record reconciled at exit 0.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** REQ-012 requires a malformed or stale existing record to fail closed with a named recovery action. The cap holds, which is why this stays degraded. But the only recovery is a manual file deletion that no output names, and the recovery recorded for the follow-up spec would not work as written.
- **Class-wide fix:** For the follow-up spec, since no kernel change is authorized now. In `--reconcile`, read a stored record that no longer matches leniently, so that a record for the current digest can replace it. Give every `return 3` in the legacy read and in `--reconcile` a `round recovery:` diagnostic that names the disagreeing field and that recovery. Then assert those diagnostics in the O-029 cases, including a re-reconcile after an edit.

### Finding O-030
- **Class:** named-case-fixture-strength
- **Status:** resolved
- **Prior:** O-030
- **Severity:** minor
- **Scenario:** In round 20, a mutant replaced the guard that requires `Failure modes: none` for a task owing no rows with one that only refuses mappings, and every suite stayed green.
- **Where:** tests/test-spec-gate.sh:174, tests/test-spec-gate.sh:175, tests/test-spec-gate.sh:176, tests/test-spec-gate.sh:178, scripts/verification-lib.sh:2861
- **Reproduced:** In my copy, round 20's mutant applied and restored with `cmp`: `acceptance_named_cases` now fails. The accept of the empty-header return for T006 exits 0 instead of 3, the diagnostic `empty required set must explicitly be none` is missing, and tasks.md changes.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** None remains. A return for the no-row task T006 with an empty `Failure modes:` header is refused with the exact diagnostic, and tasks.md keeps its text. A header followed by narrative reaches the same guard through the parser's truncation record, so the same assertion protects it.
- **Class-wide fix:** Done by T031a1o1. No further task.

### Finding O-031
- **Class:** named-case-fixture-strength
- **Status:** resolved
- **Prior:** O-031
- **Severity:** minor
- **Scenario:** In round 20, a mutant made `vf_tally` append to the history it reads, and both 002 tally cases stayed green, because no case hashed what the tally read.
- **Where:** tests/test-gate-contracts.sh:559, tests/test-gate-contracts.sh:561, tests/test-gate-contracts.sh:2245, tests/test-gate-contracts.sh:2299, tests/test-gate-contracts.sh:2309, scripts/verification-lib.sh:2150
- **Reproduced:** In my copy, each mutant applied and restored with `cmp`. Round 20's mutant, `vf_tally` appending a comment line to the history it reads after it reports, now fails all three new digest assertions in `shipped_002_tally_case` and `tally_class_cases`. So does a mutant that creates a new empty file under `notes/`. A mutant that appends a newline to an existing `reality-check.md` fails the shipped 002 assertion, the only case whose history has one.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** None remains for file content. `records_digest` covers every regular file under each directory the tally reads, by name and bytes. It does not see a new empty directory or a mode change, and neither rewrites a shipped artifact.
- **Class-wide fix:** Done by T031a3o1. No further task.

### Escalation

Round 21 is past round 3. Its one blocking finding is O-029, still open; it is not a new defect.
- **The spec is right.** AC-009, REQ-012 and the plan say a reconciliation orders authorizations by its own timestamp, bound to the history's digest.
- **The prescription left the gap.** Round 20 prescribed a reconciled time of 23:59:59Z and a waiver earlier that day, and asked for each assertion to be killed by its three mutants. The repair does exactly that. But 23:59:59Z is also what an end-of-day reading of the date yields, so the timestamp half of the binding is proven against midnight only.
- **The decision is the user's.** The repair is test-only and small: one record time, one waiver and one future-record case in one function. It moves the source, so it needs a new floor and an authorized round 22. The alternative is to accept O-029's remaining risk with a signed waiver in the STATUS.md Decisions log. The kernel behaves correctly in every probe here; the risk is a later regression that would pass green. O-032 does not block either way.

### Held up / follow-up tasks

Held up under attack:

- **T031a4o1, the digest and round binding.** Every mutant of the reconcile-time check is killed: the whole check, its digest half and its round half. So is every mutant of the read-time binding: the whole check and its digest half. The edited-history assertions work for the right reason: the floor is re-run on the edited history, so it is current and only the binding refuses the round, and the absence of `authorized` is a sound check because no refusal text contains that word.
- **T031a4o1, the date guard and the early waiver.** The record stamped before the history's date kills both the whole guard and its before-the-date half. Midnight is killed by the early waiver's exact diagnostic.
- **T031a1o1.** The new refusal is pinned by its exact diagnostic and kills round 20's mutant. The byte check compares tasks.md as `$(cat)` text, which drops trailing newlines, like every other check in this function; a refused accept writes nothing, so this smells but does not break.
- **T031a3o1.** `records_digest` sorts names under `LC_ALL=C` and hashes each regular file, and every directory the tally reads in these cases is hashed before and after. The kit-level 002 check is honest as relabelled: nothing in the case writes there.
- **The hand-written early record.** `vf_round_history` checks the round and digest of `legacy-time.nul` but not its date bounds. Only `--reconcile` writes that file, and it checks them, and a digest-bound record cannot later fall outside its history's date. A hand-forged record is as forgeable as any ledger here, so I record this as a smell, not a finding.
- **Shipped positives.** None of the new cases asserts an attack at exit 0. Each accepted input is honest: the valid reconcile, the current waiver, the restored history, the explicit none, and the tally runs.

Follow-up tasks proposed:

- T031a4o2, test files only (→ O-029). In `round_legacy_reconcile_cases`, reconcile to 2026-07-21T06:00:00Z and refuse a waiver dated 2026-07-21T05:00:00Z with the exact diagnostic. Refuse a future-stamped reconcile record before the valid one. Show each new assertion killed by the end-of-day, clamp and future-half mutants.
- O-032 goes to the follow-up spec with the corrected recovery above. It needs a kernel change, which is not authorized, and it does not block.
<!-- gate-round-end: opponent:21 -->

## Round 22

**Round:** 22
**Timestamp:** 2026-10-17T15:15:47Z
**Source:** 809a9b69c4a360cc3e17c07a1f2126a872eb7c229768d4f36f948f228167a443
**Floor:** FLOOR-3Ge8eO
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 2

### What I attacked

I worked only in a copy under `/private/tmp/opp22/work`, built from the live enumeration (`git ls-files --cached --others --exclude-standard`) and git-initialized, with `TMPDIR=/private/tmp/opp22/tmp/`. The files that matter hash the same in the copy and the worktree: `scripts/verification-lib.sh` `015859de…` (unchanged since round 21), `scripts/spec-gate.sh` `79f20eee…`, `tests/test-spec-gate.sh` `bf297cb1…` (the hash `r22-dev.log` prints), `tests/test-gate-contracts.sh` `97beb809…` and `tests/helpers.sh` `b7bc6ff9…`. In the worktree I created, changed and removed nothing; my file tool refuses report files, so the invoker persists this block. I ran no floor, round, checkpoint, capture, accept, suite or test function there, sourced nothing from its `tests/`, and ran no container.

- **Scope.** The delta in `r22-session.diff`: T031a4o2 in `round_legacy_reconcile_cases`, its task block and the new Decisions entries. Also the kernel paths the case drives: the legacy read in `vf_round_history` (`:3403` to `:3407`), the ordering comparison in `vf_round_authorized` (`:3493`), `vf_gate_waiver_check`, and the `--reconcile` branch of `vf_gate_round` (`:3578` to `:3586`). I read REQ-011, REQ-012, AC-009, FM-016, the plan's authorization paragraph, the verification contract's legacy paragraph, and shipped 002's history and STATUS.
- **Method.** Each case ran alone through a runner that copies its suite with the final `t_run_all` replaced by one focus test, as `r22-dev.sh` does. Each mutant is an exact-anchor edit of the copy's kernel that refuses unless its anchor occurs once; after every run the kernel was restored and checked with `cmp`. All runs used `/bin/bash` 3.2.57 and the macOS awk. Unmutated, the case passes. During one stretch another process filled the disk to zero; I discarded every run from that window, re-ran them after the disk recovered behind a free-space guard, and checked every log for disk errors.
- **The dev run's mutants.** I re-ran the 13 O-029 mutants of `r22-edits/mutants-r22.py` against the current case. Twelve are killed by the assertions `r22-dev.log` names; `readround` survives, and I agree with round 21 that it is equivalent. I did not re-run the O-030 and O-031 mutants: neither their cases nor the kernel changed since round 21 killed them.
- **New mutants (11).** Read-path readings that ignore the record: noon of the history's date, the next day's midnight, and the record clamped to the next day's midnight. All three are killed. Survivors on the current case:
  - fail open: a record on the history's own date read as that date's midnight; the record truncated to its hour; the record truncated to its minute (O-029 below);
  - fail closed: the guard requiring a later day than the history's date; a read that never orders earlier than the end of the history's date; the record's validity check removed from `--reconcile`; the future half compared by date only, and by year only (O-033 below).
- **Round 21's case as a control.** I rebuilt round 21's suite by reversing the delta (`b94c7dfa…`, the hash round 21 recorded) and ran its case under the new survivors. It kills the same-day midnight reading, both truncations and the later-day guard; of the five I ran there, only the end-of-day floor survives.
- **Probes on the unmutated kernel.** Through the fixture's own `floor_fixture` CLI on a copy of 002's history: a record at 2026-07-20T18:00:00Z reconciles; a waiver at 12:00:00Z that day is refused at exit 4 with `not after the previous round completion at 2026-07-20T18:00:00Z`; a waiver at 19:00:00Z is authorized and round 6 reserves. A record at 2026-07-21T06:45:30Z refuses waivers at 06:30:00Z and 06:45:10Z the same way. Records stamped `2026-07-20T25:00:00Z` or `2026-07-20` exit 3, write nothing, and a correct record then reconciles. The kernel is correct in every probe.
- **A prototype of the repair.** In a copy of the suite I replaced the valid-record block with a same-day record and a later-day record at non-round times (O-029's Class-wide fix). Unmutated it passes, ShellCheck is clean, and it kills all 16 mutants I ran against it.
- **Claims.** `r22-capture.rc`, `r22-return-T031a4o2.rc`, `T031a4o2-accept.rc`, `r22-floor-1.rc`, `r22-floor-validate.rc` (stderr empty, the frozen source printed), `r22-scope.rc`, `r22-reserve.rc` and both batch logs read 0. CAP-722-hO9jDO carries input `809a9b69…` before and after and shows 15 suites passing 147 of 147, `test_rounds` among them. T031a4o2 is ticked with that capture and return digest `a28b333c…`. The reservation fields match `ROUND-22/meta.nul`, and the scope diff names only STATUS.md, tasks.md and `tests/test-spec-gate.sh`.
- **Not examined.** Linux with GNU tools and mawk; hosted CI, which has not run on this source; a full-suite run under any mutant (only `round_legacy_reconcile_cases` writes `legacy-time.nul` in `tests/`, so the focus run decides each read-path and reconcile mutant); O-026 to O-028, since no report-grammar code changed; and the rest of the brief's known-open list, which I did not re-litigate.

### Finding O-029
- **Class:** named-case-fixture-strength
- **Status:** open
- **Prior:** O-029
- **Severity:** wrong-result
- **Scenario:** T031a4o2 replaced the case's only valid record, on the history's own date at 2026-07-20T23:59:59Z, with one at 2026-07-21T06:00:00Z, and refuses a waiver one whole hour earlier. It moved the record instead of adding a second one, so the fixture now pins one point on a later day and nothing on the history's date.
  - **The same-day region.** The `--reconcile` guard admits a record dated on the history's date or on any later day up to now. Shipped 002 is a same-day history: its five rounds and its round 4 and round 5 authorizations are all dated 2026-07-20. An honest record for it names a time on that date, which is what REQ-012's same-day ordering and the contract's "before ordering same-day authorization" are about. A kernel that reads a same-day record as the date's midnight now passes, which is round 20's midnight reading again, for the records an operator would actually write.
  - **The round hour.** 06:00:00 has zero minutes and seconds, and the refused waiver sits an hour before it. A kernel that drops the record's minutes and seconds, or only its seconds, prints the same `2026-07-21T06:00:00Z` and passes the exact diagnostic.
  - **Not monotone.** Round 21's case killed all three of these mutants, because its record carried nonzero minutes and seconds on the history's date. The repair killed the end-of-day, clamp and future-half mutants and reopened these three.
- **Where:** tests/test-spec-gate.sh:1157, tests/test-spec-gate.sh:1158, tests/test-spec-gate.sh:1160, tests/test-spec-gate.sh:1162, tests/test-spec-gate.sh:1164, scripts/verification-lib.sh:3406, scripts/verification-lib.sh:3493, scripts/verification-lib.sh:3583
- **Reproduced:** In my copy, each mutant applied to `:3406` and restored with `cmp`.
  - **Current case.** Under the same-day midnight reading, the hour truncation and the minute truncation, `round_legacy_reconcile_cases` passes, `1/1 passed`.
  - **Round 21's case.** Each of the three is killed, by `AC-009: a waiver dated before the reconciled completion authorized the next round`.
  - **Hour, end to end.** A record at 2026-07-21T06:45:30Z reconciles, and a waiver dated 2026-07-21T06:30:00Z prints `authorized: opponent round 6`; after a floor, `round` reserves round 6. Unmutated, that waiver is refused at exit 4 with `not after the previous round completion at 2026-07-21T06:45:30Z` and nothing is reserved.
  - **Minute, end to end.** The same record and a waiver at 06:45:10Z: authorized, and round 6 reserved. Unmutated: refused at exit 4, nothing reserved.
  - **Same day, end to end.** A record at 2026-07-20T18:00:00Z and a waiver at 12:00:00Z that day: authorized, and round 6 reserved. Unmutated: refused at exit 4 with `not after the previous round completion at 2026-07-20T18:00:00Z`, nothing reserved.
- **Root cause:** plan-gap
- **Blocks:** AC-009, REQ-012
- **Wrong behavior:** Each of these regressions lets a waiver written before the reconciled completion authorize and reserve the next round with every suite green, which bypasses the per-round cap REQ-012 requires: the wrong behavior O-029 has named since round 20. They are less natural than round 21's end-of-day reading, but they are not new attacks on an old fixture: the case this repair replaced killed them, and the same-day region it dropped is where 002's real records fall. One record at one coarse point is an enumeration, and the class stays open. The root cause is plan-gap: round 21's recipe, which this gate wrote, and the task block prescribed one later-day record at 06:00:00Z, and the code follows them faithfully.
- **Class-wide fix:** Test files only, in `round_legacy_reconcile_cases`. Derive the records from the guard, which admits two regions: the history's date and the later days up to now.
  - **Same-day record.** Reconcile round 5 to 2026-07-20T15:17:43Z. A waiver at 15:17:42Z is refused with `not after the previous round completion at 2026-07-20T15:17:43Z`, and one at 15:17:44Z is authorized.
  - **Later-day record.** Then reconcile again, to 2026-07-21T06:17:43Z. A waiver at 06:17:42Z is refused with `not after the previous round completion at 2026-07-21T06:17:43Z`. Keep the bad-record loop, the current waiver, the edited-history steps and the reservation as they are.
  - **Check.** My prototype of exactly this passes unmutated and under ShellCheck, and kills 16 of 16 mutants: midnight, end of day, clamp, both read-check mutants, the reconcile check, the whole guard, its future half, the same-day midnight reading, both truncations, the end-of-day floor, the later-day guard, the next day's midnight, its clamp and noon.

### Finding O-033
- **Class:** named-case-fixture-strength
- **Status:** new
- **Prior:** none
- **Severity:** degraded
- **Scenario:** Three clauses of the `--reconcile` path are pinned nowhere, or at one far point, and a regression in each fails closed with every suite green.
  - **Same-day records refused.** Rewriting the guard's `! "${stamp:0:10}" < "$VF_ROUND_DATE"` as `"${stamp:0:10}" > "$VF_ROUND_DATE"`, a classic slip when a double negative is made positive, refuses every record on the history's own date. Round 21's case killed it; the current case does not. A read that never orders earlier than the end of the history's date also refuses a same-day waiver written after a same-day record; that one survived round 21's case too.
  - **Validity unchecked.** Removing `vf_utc_valid` from `:3582` lets a record with no real time through.
  - **Future by date or year.** Comparing the future half by date or by year only lets a record stamped later today, or later this year, through; the 2099 record does not tell them apart.
- **Where:** tests/test-spec-gate.sh:1142, tests/test-spec-gate.sh:1147, tests/test-spec-gate.sh:1158, scripts/verification-lib.sh:3406, scripts/verification-lib.sh:3582, scripts/verification-lib.sh:3583
- **Reproduced:** In my copy, each mutant applied and restored with `cmp`; the current case passes under each of the five, `1/1 passed`.
  - **Later-day guard.** Round 21's case fails under it: its same-day reconcile exits 3. Probe: a record at 2026-07-20T18:00:00Z exits 3 with empty output, and a waiver at 19:00:00Z that day is then refused with `date-only history needs timestamped digest reconciliation`. Unmutated, the record reconciles, the waiver is authorized and round 6 reserves.
  - **End-of-day floor.** The same record reconciles, but the 19:00:00Z waiver is refused with `not after the previous round completion at 2026-07-20T23:59:59Z`.
  - **Validity.** Records stamped `2026-07-20T25:00:00Z` and `2026-07-20` are each written at exit 0, the first printing `reconciled legacy gate=opponent round=5 timestamp=2026-07-20T25:00:00Z`. Then `waiver`, `round`, and `round --reconcile` with a correct record all give `rc=3 out=[]`. Unmutated, both records exit 3 and write nothing, the correct record reconciles, and round 6 reserves.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** Each regression refuses a valid same-day reconciliation or a valid same-day waiver, or, for a malformed record, wedges the gate with no diagnostic until `legacy-time.nul` is deleted by hand (the O-032 wedge, reached from a record the kernel itself accepted). A near-future record refuses every waiver until its time passes. The cap holds in every case, so this is degraded, as round 21 graded the future half alone. The task block's fixture design named neither the same-day region nor these clauses, hence plan-gap.
- **Class-wide fix:** Test files only. O-029's fix kills the later-day guard and the end-of-day floor. In the bad-record loop, add a record with an impossible time, such as 2026-07-20T25:00:00Z, refused at exit 3 with no `legacy-time.nul`. For the future half, add a record later today than now, computed without GNU or BSD date arithmetic (for example today's date at 23:59:59Z, skipped in the last second of the day), refused the same way. This can go with O-029's task or to the follow-up spec.

### Finding O-032
- **Class:** round-recovery-diagnostics
- **Status:** open
- **Prior:** O-032
- **Severity:** degraded
- **Scenario:** An operator reconciles a legacy date-only history, then corrects one line in it. The recovery round 20 named, re-running `round --reconcile` with a record for the current history digest, is itself refused, because `vf_gate_round` reads the history at `:3552`, before the `--reconcile` branch at `:3578`, and the stale `legacy-time.nul` fails that read at `:3405` with exit 3.
- **Where:** scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3552, scripts/verification-lib.sh:3578, scripts/verification-lib.sh:3584
- **Reproduced:** On the unmutated copy, whose kernel hashes as in round 21: a reconcile at 2026-07-21T06:17:43Z, one appended line, then `round --reconcile` with a record naming round 5 and the edited history's digest gives `rc=3 out=[]`. O-033's validity probe reaches the same wedge from a malformed record.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** REQ-012 requires a malformed or stale existing record to fail closed with a named recovery action. The cap holds, which is why this stays degraded, but the only recovery is a manual file deletion that no output names.
- **Class-wide fix:** Unchanged from round 21, for the follow-up spec, since no kernel change is authorized: in `--reconcile`, read a stored record that no longer matches leniently so that a record for the current digest can replace it, and give every `return 3` in the legacy read and in `--reconcile` a `round recovery:` diagnostic naming the disagreeing field and that recovery.

### Escalation

Round 22 is past round 3, and its one blocking finding is O-029, still open, not a new defect.
- **The spec is right.** REQ-012, AC-009 and the contract say a reconciliation orders authorizations by its own timestamp, bound to the history's digest, including same-day authorizations.
- **The prescription left the gap.** Round 21's recipe, written by this gate, moved the record to a later day at a round hour instead of adding a later-day record beside the same-day one. The repair followed it exactly. The fix is still test-only and small, and a prototype of it killed all 16 mutants I ran against it.
- **The decision is the user's.** Repair now (it moves the source, so it needs a new floor and an authorized round 23), or accept O-029's remaining risk with a signed waiver in the STATUS.md Decisions log. The kernel behaves correctly in every probe here; the risk is a later regression that would pass green. O-032 and O-033 do not block either way.

### Held up / follow-up tasks

Held up under attack:

- **Every history-only reading.** Midnight, noon, end of day and the next day's midnight, and the record clamped to the end of the day or to the next midnight, are all killed. The exact diagnostic pins the string `2026-07-21T06:00:00Z`, which no reading of 2026-07-20 can print. In that sense round 21's statement of O-029 is met; what stays open is the same-day region and the record's precision, above.
- **The future half.** The 2099 record kills the removal of the future half, and both halves of the guard together.
- **The binding.** Every reconcile-check mutant is killed (whole, digest half, round half), and so are the read-check whole and digest-half mutants. The read-path round check alone stays equivalent, as round 21 held.
- **The bad-record loop.** Each wrong record is judged alone (`rm -f` after each), each label names what is wrong with its record, and each mutant fails the labels of its own mechanism and no others, so the assertions fail for the right reason.
- **Shipped positives.** The later-day record accepted at exit 0 is honest input: the guard admits it, and a later time can only refuse more waivers. The current waiver, the restored history and the reservation are honest too.
- **Claims.** The receipts listed under What I attacked read exit 0 and match the files they describe.

Follow-up tasks proposed:

- T031a4o3, test files only (→ O-029, and O-033's same-day half). In `round_legacy_reconcile_cases`, reconcile first to 2026-07-20T15:17:43Z with waivers at 15:17:42Z (refused, exact diagnostic) and 15:17:44Z (authorized), then to 2026-07-21T06:17:43Z with a waiver at 06:17:42Z (refused, exact diagnostic). Show it kills the 16 mutants listed under O-029.
- O-033's validity and near-future records, with T031a4o3 or for the follow-up spec (minor).
- O-032 goes to the follow-up spec with the recovery above. It needs a kernel change, which is not authorized, and it does not block.
<!-- gate-round-end: opponent:22 -->

## Round 23

**Round:** 23
**Timestamp:** 2026-10-25T14:43:15Z
**Source:** a7e7dd326b27c7565c26349485c440af26f718a7f16e400ea42ed6961d03cd1a
**Floor:** FLOOR-il41Kn
**Verdict:** CLEARED
**Blocking:** 0 · **Minor:** 1

### What I attacked

This resumes the interrupted review of the existing reservation, reserved 2026-10-25T13:14:19Z; it is not another round. The live orchestration catalog reports provider `codex_codex_gym`, model `gpt-6.1-sol`, reasoningEffort `max`, serviceTier `default`. These match `s26-opponent-invocation-current-provider-retry3.json`, whose observed task ID is `node:delegated-task:command%3Amcp%3Acb5cda43-acc1-4ace-ba89-e4e25f5ce897%3Adelegate-task%3Asdd003-opponent-round23-current-provider-recovery-retry3`. The earlier failed attempt returned no verdict; its saved work is evidence, not a completed gate.

I checked the reservation, both saved state manifests, the round-22-to-23 scope and session diff, the relevant spec/plan/task contracts, prior findings and their responses, and the legacy reconciliation grammar. The changed executable surface is `tests/test-spec-gate.sh::round_legacy_reconcile_cases` at line 1133, called by `test_rounds` at line 1212. I traced its fixture copying, assertion propagation and normal suite enumeration, plus its unchanged consumers: `vf_round_history`, `vf_round_authorized`, `vf_gate_waiver_check` and the legacy `--reconcile` branch of `vf_gate_round`. FM-016, INV-004, AC-009 and REQ-012 determine the ordering and binding attacks.

Before reusing the interrupted work, I compared every copied scratch file with a live counterpart: 77 in `work` and 30 in `probes`, all byte-identical. The original library backup and both scratch libraries match the live library, SHA-256 `015859de8d68d5cbaffa3ea9078a74584f364312b09cd3c739731fd6716a6c36`; the scratch and live test match at `3dacde897001828698c0c8d0e2a40f077e8b29100937df92ce2a218ce184a41a`. The probe histories match shipped 002. The retained full function and shortened mutation prefix match the corresponding live function bytes; probe definitions differ only by omitting the final runner invocation. I also recomputed the live source snapshot: it is byte-identical to FLOOR-il41Kn's sealed `inputs.nul`, with the reserved source digest and HEAD `2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9`. The floor and reservation seals match their files.

Recovered evidence under `/private/tmp/opp23-codex-gym-3es8gbyb`, inspected rather than rerun:

- `logs/baseline.log` and `baseline.rc`: the complete unmodified focused case passed, 1/1, exit 0 under Bash 3.2. The shorter prefix also passed before mutation (`prefix-baseline.log`, exit 0). That prefix retains every changed assertion and bad-record check, stopping before the current waiver, edited-history steps and fixture floors.
- `logs/mutation-summary.json` agrees with the recovery record and the eight raw mutation logs. All eight exit 1 at relevant assertions: `samedaymid`, `hour` and `minute` wrongly authorize the one-second-early waiver; `maxeod` refuses the one-second-later waiver and prints the wrong completion time; `laterday` refuses the valid same-day record; `recvalid` writes the impossible-time record; `futureday` and `futureyear` write the later-today record. These are behavioral assertion failures, not setup failures. The restored library matches the original backup.
- `probes/boundary-probe.sh` and `logs/boundary.log` (exit 0) independently isolate each waiver. With records at 2026-07-20T15:17:43Z and 2026-07-21T06:17:43Z, one second before and equality both exit 4 with the exact reconciled completion time; one second after exits 0 with `authorized: opponent round 6`. The existing equality assertion at `tests/test-spec-gate.sh:1413` reaches the same shared comparison at `scripts/verification-lib.sh:3493`.
- `probes/reality-probe.sh` and `logs/reality.log` (exit 0) exercise the sibling gate with shipped 002's reality-check history: a wrong digest exits 3 without a record; a valid record reconciles and reads back round 1, the exact timestamp and legacy style. O-032 is independently reproduced in the boundary log below.

I inspected the saved developer receipts, not a new execution: the task is accepted with CAP-744-sgOYqc; floor, capture, acceptance and scope receipts read exit 0. The per-mutant lines in `r23-dev.log` show 27 kills and the explicitly equivalent `readround` survivor; its footer's `28/28` must not be read as 28 actual kills. Its 18 assertion mappings supplement the eight independently recovered mutation checks.

### Finding O-032

- **Class:** round-recovery-diagnostics
- **Status:** open
- **Prior:** O-032
- **Severity:** degraded
- **Scenario:** Reconcile shipped 002's date-only opponent history to 2026-07-21T06:17:43Z, append a line to that history, then submit a correct reconciliation record naming round 5 and the edited history's digest.
- **Where:** scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3552, scripts/verification-lib.sh:3578, scripts/verification-lib.sh:3584
- **Reproduced:** The recovered, source-matched boundary probe records the corrected reconciliation at exit 3 with empty output. Deleting only the stale legacy-time.nul makes that same record reconcile at exit 0 with the expected timestamp diagnostic. See logs/boundary.log under the recovery scratch directory.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The stale stored record is validated before the replacement reconciliation is examined. The gate fails closed, but the CLI neither replaces the stale record nor names the manual recovery. This remains the previously recorded minor defect, at four locations.
- **Class-wide fix:** Keep the existing follow-up: permit an explicit corrected reconciliation to replace a stale binding, and name the disagreeing field and recovery in each legacy-read and reconciliation refusal. Cover recovery after a history edit and the malformed-record refusals. No kernel repair is authorized in this round.

### Held up / follow-up tasks

T031a4o3 addresses O-029 and O-033. The valid regions come from the guard itself: the history's own date and later dates through the current time. Both now have non-round timestamps and precise early-waiver diagnostics; the same-day positive also rejects an end-of-day floor. Invalid-time and near-future records are refused without leaving reconciliation state. The bad-record loop isolates each input, and the original digest/round checks, edited-history refusal and restored-history reservation remain in the complete function. The changed positives are valid inputs, and assertion failures reach the suite's exit status. I established no remaining substantive defect in these repairs.

The read-path round-check-only mutant remains equivalent within the documented trusted workspace: the writer checks the round, and the retained digest check binds the stored record to the exact history. A manually forged record does not establish a new defect under that model. O-032 stays open for its existing follow-up; O-026, O-027 and O-028 remain recorded minor follow-ups and were not reassessed. Clearance here neither clears those items nor supplies the separate reality-check verdict.

Not rerun: the expensive floor, full suites, completed probes or mutation matrix. Linux/GNU execution, hosted CI and the brief's other unchanged unexamined surfaces were not freshly assessed; their previously recorded limits remain.
<!-- gate-round-end: opponent:23 -->

## Round 24

**Round:** 24
**Timestamp:** 2026-10-26T07:25:24Z
**Source:** c7a82b3ae3b900dcb02a4839decad74db1a13457c5bab9ff859625a5357f0be6
**Floor:** FLOOR-GMlmyY
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 1

### What I attacked

This completes the adversarial review of the same reservation, reserved 2026-10-26T06:56:06Z. The failed MAX r1 invocation produced no report or verdict; its planned attacks are not executed evidence. Actual recovery identity comes from `notes/verification/reports/s28-opponent24-max-retry2-invocation.json`: task suffix `sdd003-s28-opponent24-max-current-provider-retry2`, provider `codex_codex_gym`, model `gpt-6.1-sol`, reasoningEffort `max`, serviceTier `default`.

I read all 23 acceptance criteria, the applicable requirements, plan FM/INV rows and registry, T031a5/T031a6/T029 and gate task blocks, the exact round-24 and reality-check-4 waivers, reservation metadata, complete five-file source delta, opponent23 and RC3's gaps/responses. I inspected the classifier, capture/snapshot/currency and matrix/prior-PASS implementations, their connected callers, fixture helpers, assertion propagation, suite enumeration, verification grammar and invoker guidance. FM-001/005/010/020 and INV-001/005 frame these attacks. Seven inspected runtime/helper/runner files match the prior snapshot; the newly exposed classifier behavior justifies expanding into that unchanged affected implementation.

I consumed the existing reservation's successful floor-validation receipt without validating or executing the real floor again. FLOOR-GMlmyY records 21 executions and 79 reuses. Its current T031a5 proof is CAP-770-AgEMCd, 19/19; T031a6 and T029 use CAP-769-bZPhmg, 18/18. CAP-767/768 and source-A7 captures were not treated as current. The hosted audit and completed T029 rejection/acceptance receipts remain context, not a substitute for inspecting assertions or an RC4 verdict.

Fresh attacks ran only under `/private/tmp/opp24-retry2-dp2syp7l`, using Bash 3.2.57. Preserved scripts, command-specific tasks/output, result receipts and hashes are under `notes/verification/reports/s28-opponent24-max-retry2-probes/`:

- The exact changed classifier loop and existing shell-runner control pass. Removing only `typecheck` recognition or only `tsc --noEmit` recognition separately makes the corresponding new assertion fail, exit 1.
- Eighteen actual analyzer invocations exercise weak commands and runner controls. Nine weak variants wrongly omit the required warning; O-034 groups their shared cause. The input declarations and full analyzer output are retained, rather than inferred from the regex alone.
- The complete current `matrix_runtime_cases` passes in isolation. Its six independent revisions cover implementation, genuinely consumed transitive helper, fixture, lock, config and actual criterion text. I inspected current/reuse refusals, saved/carried PASS refusals, byte-identical old logs and restored positives, plus its retained omission, impact, verdict and corruption controls.
- Removing the current-manifest comparison makes that same test fail with 23 unexpected successes. Separately removing matrix capture validation makes it fail with 12 unexpected successes, including saved and carried PASS. Both exit 1 at behavioral assertions. These are deliberate scratch mutations, not defects attributed to the unmodified runtime. The restoration audit confirms all copied originals match live source again; all 62 preserved probe files match their manifest hashes.

### Finding O-034

- **Class:** verification-command-classification
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** Give an AC-referencing task an untyped Verify of `tsc --noEmit tests/unit.ts`, `npm run typecheck -- --project tests/tsconfig.json`, `grep AC-001 tests/check.sh` or `npm run build -- --outDir tests/build`. Siblings include `test -e README.md`, `test -f README.md`, `grep pytest README.md`, `rg bats README.md` and `diff fixtures/test.txt actual.txt`.
- **Where:** scripts/sdd-analyze.sh:291, scripts/sdd-analyze.sh:292, scripts/sdd-analyze.sh:307, tests/test-sdd-analyze.sh:669
- **Reproduced:** `classifier-edge.sh` and `classifier-siblings.sh` invoke the copied, source-matched public analyzer on actual task declarations. Every listed command returns 0 without `untyped AC Verify`, and reports `consistent`. Bare `npm run typecheck`, `tsc --noEmit` and `grep AC-001 README.md` warn; genuine shell/node/cargo/pytest/bats runners remain accepted. See `classifier-observations.json` and the numbered task/output receipts.
- **Root cause:** implementation-error
- **Blocks:** AC-004, REQ-005
- **Wrong behavior:** The runner exemption searches the entire command for test-looking words or paths before classifying weak verification. A filename or search pattern therefore suppresses the warning without executing a behavioral test. The leading `test` also exempts the file-existence checks the weak branch explicitly names. AC-004 expressly requires more than runner substring matching; the new four-command regression loop does not cover these argument-position cases.
- **Class-wide fix:** Repair the shared classifier so runner recognition uses the command's executable/runner position rather than unrelated argument substrings. Sweep both exemption alternatives and retain genuine shell runners and explicit test/assertion/static/manual controls. Extend the existing loop with the reproduced path, search-pattern and file-existence negatives. This is one shared classifier class, with four cited implementation/consumer/test locations; arbitrary shell syntax beyond these cases was not exhaustively explored.

### Finding O-032

- **Class:** round-recovery-diagnostics
- **Status:** open
- **Prior:** O-032
- **Severity:** degraded
- **Scenario:** Reconcile shipped 002's date-only opponent history, edit that history, then submit a corrected reconciliation naming round 5 and the edited history's digest.
- **Where:** scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3552, scripts/verification-lib.sh:3578, scripts/verification-lib.sh:3584
- **Reproduced:** Retained from opponent23's source-matched boundary probe: corrected reconciliation exits 3 with empty output; removing only stale legacy-time.nul permits the correction. Not rerun here. The current library is byte-identical to that reviewed implementation, SHA-256 `015859de8d68d5cbaffa3ea9078a74584f364312b09cd3c739731fd6716a6c36`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The stale stored reconciliation is rejected before its replacement is examined. It fails closed but supplies neither replacement nor the named manual recovery. The existing four-location minor remains unchanged.
- **Class-wide fix:** Preserve the existing follow-up to permit explicit corrected reconciliation and explain refusals across the legacy-read/reconciliation paths. No kernel repair was authorized in this round.

### Held up / follow-up tasks

Open one class-wide follow-up for O-034 covering the shared classifier, its warning consumer and all reproduced sibling forms. A fresh review must establish that weak commands warn while genuine runners and declared verification kinds remain valid. T031a5's new simple typecheck assertions work, but they do not establish this surrounding contract. T031a6 withstands the focused freshness attacks; no separate substantive freshness defect was established.

O-032 retains its existing minor follow-up. O-026/O-027/O-028 remain recorded minor follow-ups and were not reassessed; they are not new findings or newly cleared items. Prior O-029/O-033 repairs were not reopened without new evidence. No real source, tasks, STATUS, index, captures, floor, reservation or canonical gate history was changed; only the assigned report and excluded probe receipts were written.

Not rerun: the real floor, full suites, hosted CI, T029 control, O-032 probe or historical mutation matrices. Other unchanged and previously unexamined surfaces retain their recorded limits; no RC4 readiness is supplied.
Risk: weak untyped AC checks can silently pass authoring validation until O-034 is repaired; existing minor follow-ups remain open.
<!-- gate-round-end: opponent:24 -->

## Round 25
**Round:** 25
**Timestamp:** 2026-10-27T07:21:06Z
**Source:** 16ffcec3c2f0cffa21b8c35e7b90d768a27bdfdd37deba9147edd25489946494
**Floor:** FLOOR-qoRY6H
**Verdict:** CHALLENGED
**Blocking:** 1 · **Minor:** 1

### What I attacked

This is the independent opponent pass for the existing reservation of 2026-10-27T06:54:04Z. Live orchestration confirms `codex_codex_gym / gpt-6.1-sol / reasoningEffort=max / serviceTier=default`, matching `notes/verification/reports/s32-opponent25-max-invocation.json`. No nested delegation or additional round occurred.

I read the complete hash-matched ready brief, all 23 ACs and applicable requirements/constraints, the plan's FM-001–FM-020, INV-001–INV-006 and registry, relevant task blocks, STATUS Decisions including the exact-round authorization, both constitutions and stack configuration. I read opponent23/24, RC3, the three repair quality reports and correction handoffs/provenance. The exact C7 comparison changes four mapped files: analyzer, analyzer tests, tasks and STATUS; 173 mapped source paths remain unchanged. The larger pre-existing HEAD delta is not attributed to this repair.

The relevance sweep covered every AC, with focused source/assertion inspection rather than another RC evidence verdict:

- AC-001–AC-006, AC-011 and AC-023: phase-aware authoring/bindings, malformed/shared definitions, local test ownership, explicit verification kinds, golden-example assertions, all 14 overlay defaults, command grammar, legacy compatibility and the sole weak-warning consumer. I inspected the actual 108 weak/56 clean declarations and warning/exit assertions, plus propagation through `t_fail`, `t_run_all` and `tests/run.sh`.
- AC-007–AC-010, AC-012 and AC-017: floor/checkpoint execution and identity seams, lost-binding and next-stage counters, round authorization/history, report lifecycle/class/site assertions and actual-or-unknown metrics. Existing round-recovery limits remain; I did not reopen closed findings without new evidence.
- AC-013–AC-016, AC-018, AC-020 and AC-022: snapshot/capture currency, return validation and atomic acceptance, saved/carried PASS consumers, briefing/invoker contracts and executable fixture assertions. I inspected T031a6's six independently consumed input revisions, old-log comparisons, restored positives and matrix refusal assertions. The live AC-016 dual-gate observation remains RC4's responsibility.
- AC-019 and AC-021: fixture isolation, suite enumeration, portability receipts and real output/exit/byte-bound assertions. Fresh probes used Bash 3.2.57; no Linux or hosted suite was executed here.

I consumed the successful existing-floor reservation receipt. FLOOR-qoRY6H has 101 records: 21 executions, 80 reuses and 22 unique captures. Current CAP-795-FlRr7i records analyzer 19/19; CAP-794-aUZ5t0 records contracts/T029 18/18; both have matching before/after source16ff. I read the current T029 rejection/acceptance and hosted four-job receipts as context. Historical CAP-791/792/793 and FLOOR-GMlmyY were not treated as current proof. No floor validator or suite was rerun.

Fresh scratch work is preserved under `notes/verification/reports/s32-opponent25-max-probes/`, with scripts, exact task declarations, argv, outputs, results and hashes:

- `classifier-probe.py`: 48 public-analyzer cases pass, including all nine original O-034 inputs, further direct/redirected weak forms and genuine runners/custom-assertion operands. The original reported forms are repaired.
- `noclobber-probe.py` and `noclobber-corrected/results.json`: 48 public-analyzer cases isolate the remaining boundary below; 24 omit the required warning and 24 ordinary/spaced controls warn. Forty-eight owned-stub executions confirm Bash runs the intended tool with unchanged arguments. The configuration parser also accepts and preserves the three representative command strings. The initial `noclobber/` batch accidentally shadowed the analyzer's own grep with my stub and is explicitly discarded; only the corrected batch supplies these analyzer observations.
- `currency-probe.py`: all 20 focused checks pass. Changing only the copied analyzer invalidates current/reuse/matrix proof and rejects acceptance without changing task bytes or the old log. Restoration permits acceptance. An actual criterion edit then rejects current evidence while repeated acceptance reports only `freshness=historical`; restoring the criterion restores currency. These were owned fixture checks, not live T029 or AC-016 runs.

All 133 copied source files match their initial hashes and live counterparts after scratch mutations were restored. Supplied STATUS/tasks hashes, modes and mtimes still match. The parent owns the complete returned-worktree/HEAD/index comparison. Broader unchanged runtime, arbitrary shell syntax and platform behavior retain their prior review limits.

### Finding O-034

- **Class:** verification-command-classification
- **Status:** open
- **Prior:** O-034
- **Severity:** wrong-result
- **Scenario:** An AC-referencing task has an untyped Verify of `grep>|out.txt AC-001 README.md`, `/usr/bin/grep>|out.txt AC-001 README.md`, `./tools/rg>|out.txt AC-001 README.md` or `tests/diff>|out.txt old new`. The same omission occurs with a space after the operator, as in `grep>| out.txt AC-001 README.md`. These are direct known text tools with unquoted output redirection.
- **Where:** scripts/sdd-analyze.sh:292, scripts/sdd-analyze.sh:293, scripts/sdd-analyze.sh:295, scripts/sdd-analyze.sh:313, tests/test-sdd-analyze.sh:668
- **Reproduced:** `python3 -I /private/tmp/sdd-opponent25-8elh3grt/noclobber-probe.py` exits 0 after recording 24 missing warnings across grep/rg/diff and bare, absolute, ./tools/ and tests/ paths. Each affected public-analyzer call exits 0 and reports `consistent`. The 24 counterparts using ordinary attached `>` or whitespace before `>|` warn with exit 0. Owned Bash stubs record the same executable arguments and redirected output; see `noclobber-corrected/` and `noclobber-config.json` in the assigned receipts.
- **Root cause:** implementation-error
- **Blocks:** AC-004, REQ-005
- **Wrong behavior:** The redirect substitutions cannot consume `>|` because their target class excludes the pipe character. The following text-tool predicate requires whitespace or end-of-command after the basename, so an attached operator hides the recognized weak executable. A single space before that same redirection restores the warning. The 108 weak regression declarations contain no `>|` case. This remains O-034's warning-classification failure at five cited source/consumer/test sites, despite repairing its previously reported operands and paths.
- **Class-wide fix:** Retain anchored executable recognition and handle this direct output-redirection boundary for all three text tools. Extend the existing public-analyzer loop with attached/spaced operator and target-spacing pairs, including directory-qualified executables, while retaining genuine runner, operand and explicit-kind controls. Sweep the shared redirect handling and weak-tool boundary together; arbitrary quoting, wrappers and general shell parsing remain outside this finding.

### Finding O-032

- **Class:** round-recovery-diagnostics
- **Status:** open
- **Prior:** O-032
- **Severity:** degraded
- **Scenario:** Reconcile shipped 002's date-only opponent history, edit that history, then submit a corrected reconciliation naming round 5 and the edited history's digest.
- **Where:** scripts/verification-lib.sh:3405, scripts/verification-lib.sh:3552, scripts/verification-lib.sh:3578, scripts/verification-lib.sh:3584
- **Reproduced:** Retained from opponent23/24's source-matched probe: the corrected reconciliation exits 3 with empty output; removing only stale legacy-time.nul permits correction. Not rerun here. The current library remains SHA-256 `015859de8d68d5cbaffa3ea9078a74584f364312b09cd3c739731fd6716a6c36`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** Stale stored reconciliation is rejected before its replacement is examined. The command fails closed without naming replacement or manual recovery. The existing four-location minor is unchanged.
- **Class-wide fix:** Retain the existing follow-up for corrected reconciliation and named diagnostics across the legacy history/reconciliation paths. No kernel repair was authorized or performed.

### Held up / follow-up tasks

Keep one class-wide O-034 follow-up covering the five listed sites and all reproduced tool/path/spacing siblings. Its original cases now hold, but the confirmed direct-redirection omission prevents clearance under AC-004/REQ-005. O-032 retains its existing minor follow-up. O-026/O-027/O-028 remain recorded minor follow-ups, unassessed here and not newly cleared. No separate substantive currency, acceptance or invalidation defect was established.

Only this new report and the assigned excluded receipts were written in the worktree. No source, STATUS/tasks, real capture/acceptance/floor/reservation, canonical history, HEAD or index was mutated by this review. This is solely the formal OP25 verdict; it supplies no RC4, overall-readiness or merge verdict and authorizes no subsequent round.

Not checked again: whole floor/full suites, hosted CI, historical mutation matrices, O-032 reproduction or the live AC-016 probe; unchanged surfaces retain the stated limits.
Risk: direct text-only checks can still miss the required authoring warning; the recorded minor follow-ups remain open.
<!-- gate-round-end: opponent:25 -->
