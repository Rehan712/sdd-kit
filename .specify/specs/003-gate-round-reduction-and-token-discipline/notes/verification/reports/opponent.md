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
