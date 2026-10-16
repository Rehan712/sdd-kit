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
