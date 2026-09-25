# Provisional opponent review — 003-gate-round-reduction-and-token-discipline

**Status:** CHALLENGED (provisional; formal floor and round unassigned)
**Source:** diagnostic snapshot only: `bdd06daea502bdeb3f59a796028700725ef499df6c9b42fde2fc14867736bb11`
**Floor:** unassigned
**Round:** unassigned
**Blocking:** 6 · **Minor:** 0

This is an incremental correctness report, not a canonical completed gate round.
It deliberately has no `## Round` header or gate completion marker.

## Finding O-001

- **Class:** return-envelope-parsing
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** A worker returns the complete valid `Verification-Return: 1` block, followed by ordinary explanatory prose (`All requested verification is complete.`). Plan §4.2 explicitly permits surrounding narrative, but the parser treats every post-block narrative line as malformed.
- **Where:** `scripts/verification-lib.sh:1300`, `scripts/verification-lib.sh:1312`
- **Reproduced:** In `/tmp/opponent003.return.wVgh7b`, a real T001 no-tick capture and otherwise valid FM mapping were followed by that one narrative line. `scripts/spec-gate.sh accept <fixture-spec> T001 return-with-narrative.txt` returned 3 with `accept rejected: T001 return: unexpected field or malformed mapping`.
- **Root cause:** implementation-error
- **Blocks:** REQ-006, AC-022
- **Wrong behavior:** A contract-valid worker response cannot be accepted or ticked, despite current successful proof and exact mappings.
- **Class-wide fix:** Delimit the structured block or explicitly ignore prose outside it while remaining strict inside it; add leading- and trailing-narrative fixtures. Reviewed parser call sites: `vf_return_check` is the sole runtime consumer. No other return-envelope parser was found.

## Finding O-002

- **Class:** round-authorization-grammar
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** STATUS contains `- 2026-01-02T00:00:00Z THIS-IS-NOT-THE-GRAMMAR — waiver: gate=opponent; round=4; after=3; by=fixture-user; reason=malformed prefix`. The timestamp and fields are valid, but the line is not the exact authorization grammar because extra text appears between timestamp and separator.
- **Where:** `scripts/verification-lib.sh:1857`, `scripts/verification-lib.sh:1860`, `scripts/verification-lib.sh:1867`
- **Reproduced:** In `/tmp/opponent003.round.hGY6gI`, `vf_round_authorized <fixture-spec> opponent 4 2026-01-01T23:59:59Z` returned 0. The AWK matcher accepts any prefix before ` —`, then blindly extracts the first 20 characters as the timestamp.
- **Root cause:** implementation-error
- **Blocks:** REQ-012, AC-009
- **Wrong behavior:** A malformed Decisions entry authorizes round 4 although the requirement says malformed or unscoped authorization must fail closed and the documented line grammar is exact.
- **Class-wide fix:** Parse and validate the whole line from `^- <UTC> — ...$`, not a permissive prefix plus substring; add extra-prefix/suffix and separator-variation negative cases. Sibling sweep covered waiver and spec-revision branches because both share this parser.

## Finding O-003

- **Class:** live-control-semantic-validation
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** Before valid acceptance, submit a forged-summary return rather than the deliberately incomplete FM/INV copy required by AC-016. It is rejected without changing task state, then the intact return is accepted and both gate identities are present.
- **Where:** `tests/probe-gate-contract.sh:31`, `tests/probe-gate-contract.sh:34`, `tests/probe-gate-contract.sh:39`, `tests/probe-gate-contract.sh:45`
- **Reproduced:** In `/tmp/opponent003.probe.3iX0H8`, the rejected control failed only with `summary is not the authentic capture summary`; it did not omit a required mapping. After intact acceptance, floor, completed opponent, and reserved reality-check, `tests/probe-gate-contract.sh <fixture-spec> --task T001` returned 0 and printed `live wiring PASS ...`. The probe checks only different return digest, rejection outcome, unchanged task digest and ordering; it never establishes that the rejected copy was incomplete.
- **Root cause:** implementation-error
- **Blocks:** AC-016, REQ-006
- **Wrong behavior:** The live checker certifies the required incomplete-return control when a different negative case ran, so the promised real wiring observation can be a false positive.
- **Class-wide fix:** Persist enough typed rejection data to distinguish missing-required-row rejection, then require that reason/class in the probe; add forged-summary, wrong-task and stale-capture controls that must not satisfy AC-016. Sibling sweep covered all probe acceptance/rejection predicates; the missing semantic discriminator is shared by every arbitrary rejection type.

## Finding O-004

- **Class:** gate-report-schema-validation
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** Submit a canonical-looking CLEARED opponent report with identities, totals and completion marker, but omit `### What I attacked` and all attacked/searched/unexamined scope.
- **Where:** `scripts/verification-lib.sh:760`, `scripts/verification-lib.sh:771`, `scripts/verification-lib.sh:778`, `scripts/verification-lib.sh:841`
- **Reproduced:** `/tmp/opponent003.probe.3iX0H8/opponent-report-no-scope` contains only the canonical identities, CLEARED/zero totals and completion marker. Direct `vf_reports ... opponent ...` returned 0 and emitted a round catalog (`bytes=140`). This parser is the schema validator used by `round --complete` at `scripts/verification-lib.sh:1953`.
- **Root cause:** implementation-error
- **Blocks:** REQ-010, REQ-012, AC-012
- **Wrong behavior:** The deterministic completion path can canonize a clearance that supplies none of the required attack/sibling/unexamined-scope record, defeating the retained-scope review contract.
- **Class-wide fix:** Validate the required top-level attack and follow-up sections and, for findings, all canonical fields including Wrong behavior and Class-wide fix. Add omission negatives for each required report section/field. The sibling sweep found the same validator also does not require those two finding fields.

## Finding O-005

- **Class:** config-interpolation-validation
- **Status:** new
- **Prior:** none
- **Severity:** wrong-result
- **Scenario:** Configure `gate_checks` with a single-quoted scalar containing the shell positional interpolation `$1`.
- **Where:** `scripts/verification-lib.sh:71`, `scripts/verification-lib.sh:87`
- **Reproduced:** In `/tmp/opponent003.config.Qf1m38`, `vf_config stack.yml '' catalog` returned 0 and retained the command containing `$1`. The rejection regex covers `$NAME`, `${...}` and `$(...)`, but not numeric or special shell parameters.
- **Root cause:** implementation-error
- **Blocks:** AC-011, REQ-007, REQ-008
- **Wrong behavior:** An interpolation form explicitly disallowed by the authoritative configuration grammar passes validation and is later expanded by Bash at execution, so command behavior can depend on invocation context.
- **Class-wide fix:** Reject all unescaped shell parameter/command/arithmetic expansion forms covered by the contract, or narrow the documented prohibition precisely; add `$1`, `$?`, `$$`, `$!`, `$-`, `$*`, `$@` and arithmetic-expansion negatives. I examined the one shared scalar parser used by gate, checkpoint, reuse, tool and input lists; execution strings are the directly affected consumers.

## Finding O-006

- **Class:** post-pr-followup-binding-schema
- **Status:** new
- **Prior:** none
- **Severity:** regression
- **Scenario:** `/sdd:review` receives a red CI check or actionable review comment and follows its instructions literally, appending `T###c1` or `T###r1` under Ship with only `Files`, `Acceptance`, and `Refs`, then attempts the instructed no-tick capture and deterministic acceptance.
- **Where:** `skills/sdd-review/SKILL.md:29`, `skills/sdd-review/SKILL.md:31`, `skills/sdd-review/SKILL.md:33`, `skills/sdd-review/SKILL.md:41`, `skills/sdd-review/SKILL.md:45`, `skills/sdd-review/SKILL.md:101`, `scripts/verification-lib.sh:631`, `scripts/verification-lib.sh:632`, `scripts/verification-lib.sh:635`, `scripts/verification-lib.sh:636`, `scripts/verification-lib.sh:637`
- **Reproduced:** Source-proof trace: review lines 29–32 and 41–42 prescribe exactly the three-field shape and lines 33–35/45–46 immediately require `spec-gate accept`. The shared validator classifies IDs matching `T[0-9]{3}[oascr][0-9]+` as follow-ups, expressly disables the Ship exemption for them, and emits hard errors for the omitted `Verify kind`, `Tests`, and `Verify` fields. Plan §4.3 explicitly says Gate/Ship exceptions do not exempt behavior-changing follow-ups.
- **Root cause:** implementation-error
- **Blocks:** REQ-005, REQ-006, AC-015
- **Wrong behavior:** The documented post-PR workflow creates an invalid new-contract task that cannot produce a `--from-task` capture or pass deterministic acceptance, so CI/review fixes stall before re-gating. Under the earlier workflow these tasks used legacy evidence ticking, making the mismatch a regression introduced by switching the invoker to `spec-gate accept` without updating its task grammar.
- **Class-wide fix:** Require the full typed task binding (`Verify kind`, plan-registered `Tests`, executable `Verify`, plus existing fields) when creating `c` and `r` follow-ups, and update the plan registry when a genuinely new test family is needed. Add executable red-CI and review-comment fixtures that construct the instructed task block and take it through capture and acceptance. Known sibling sites are both `c` and `r` creation branches in `sdd-review`; other gate follow-up instructions were searched but do not prescribe this same three-field-only shape.

## Follow-up tasks proposed

- **T030o1** — Make `Verification-Return: 1` parsing accept permitted surrounding narrative while remaining strict inside the envelope; cover both sides of the block. (O-001)
- **T030o2** — Validate round waiver/revision authorizations against the exact whole-line grammar and add malformed-prefix/suffix/separator negatives. (O-002)
- **T030o3** — Persist and require the typed deliberately-incomplete rejection reason in the live probe; prove arbitrary rejection classes do not satisfy AC-016. (O-003)
- **T030o4** — Enforce every required opponent/reality report section and finding field during `round --complete`; add field/section omission fixtures. (O-004)
- **T030o5** — Close the shell expansion grammar across all configuration scalars and test numeric/special/arithmetic expansion forms. (O-005)
- **T030o6** — Give `sdd-review` CI/review follow-ups full typed bindings accepted by the new contract, with end-to-end capture/accept fixtures for both suffixes. (O-006)

## Final provisional assessment and scope

**Verdict: CHALLENGED.** Six substantive correctness classes are established. This is not a formally completed T030 gate: no current floor or script-reserved opponent round was supplied, so no canonical completion marker is claimed.

Examined: the accepted spec, plan, tasks and STATUS; project and hub constitutions; the full branch-local opponent contract; the exact tracked `git diff main -- .` inventory plus relevant untracked/generated verification artifacts; all functions in `verification-lib.sh`, `spec-gate.sh`, `spec-run.sh`, `spec-task.sh`, `spec-evidence.sh`, and `spec-ac-coverage.sh`; changed analyzer/doctor paths; principal executable assertions in `test-verification.sh`, `test-spec-gate.sh`, `test-gate-contracts.sh`, and `probe-gate-contract.sh`; and the changed deterministic protocol/follow-up surfaces in orchestrator, implement, go, and review invokers. Targeted reproductions are retained at `/tmp/opponent003.return.wVgh7b`, `/tmp/opponent003.round.hGY6gI`, `/tmp/opponent003.probe.3iX0H8`, and `/tmp/opponent003.config.Qf1m38`.

Searched at bounded depth: all changed authoring templates, stack overlays, expert/test-engineer personas, generated adapter inputs, golden-example contract changes, README/constitution/retro guidance, executable-bit inventory and stack configuration. No additional blocking class was established from those surfaces before the requested graceful stop.

Explicitly unexamined or not independently rerun: generated adapter outputs line-by-line, every negative branch in the large shell fixtures, remote Linux/Bash-3.2 matrix behavior, and the concurrently running full acceptance pipeline. I did not rerun full suites, mutate source/tasks/acceptance state, or assign formal floor/source/round identities. These scope limits do not weaken or merge away the six established blockers.
