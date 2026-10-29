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
