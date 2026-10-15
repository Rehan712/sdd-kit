# Spec 003 review dossier — opponent round 5

Worktree: /Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline.
Branch: spec/003-gate-round-reduction-and-token-discipline; base: main.
Spec directory: .specify/specs/003-gate-round-reduction-and-token-discipline.

Read spec.md, plan.md, tasks.md and the worktree constitution. The hub
constitution is /Users/babar/.sdd/constitution.md; no local AGENTS.md or
stack overlay applies. .specify/stack.yml declares the actual shell checks.
Use branch-local agents/opponent.agent.md and agents/reality-check.agent.md
for the current report contracts, with independent adversarial verdicts.

## Reviewed inputs and evidence

The invoker supplies the script-granted round, source, floor and reservation
timestamp. Read notes/verification/floor-latest and the corresponding immutable
floor/round records; never infer currency or a reservation from this document.
The pre-gate helper refreshes stage checkpoints, the typed AC-016 control,
the floor and the three diff files in this directory before reservation.

Run `git diff main -- . ':!.specify/specs/003-gate-round-reduction-and-token-discipline/notes'`
from this worktree. This includes committed, staged and unstaged changes.
`git diff main...HEAD` alone omits the unfinished implementation. Discover
untracked inputs with `git ls-files --others --exclude-standard` and read
relevant source directly. source.diff/source-stat.txt/untracked.txt are generated
copies; compare them against the live tree if necessary.

Historical task acceptance and current verification are distinct. The floor's
commands.nul maps current proof to complete notes/captures/CAP-* directories.
Use validated floor suite results and inspect actual assertions. Additional
attacks use isolated temporary fixtures. Do not edit source, STATUS Decisions,
tasks, canonical reports or gate reservations during review.

The active executor is macOS, using worktree-local scripts. Earlier actual
Linux/macOS evidence is retained under notes/verification/platforms and in
historical captures; normal GitHub-hosted CI remains a later requirement.
Do not present earlier platform evidence as a run of newly changed code.

## Prior findings and the round-4 sweep

Four opponent rounds are consumed and sealed in notes/opponent.md. Rounds 1, 2
and 4 were CHALLENGED; round 3's reviewer returned CHALLENGED but its
invocation could not complete, so it is reconciled BLOCKED with all findings
preserved (untouched report: notes/verification/reports/opponent-round3.md).
Round 4's report is notes/verification/reports/opponent-round4.md, digest
d044652e..., 3 blocking. STATUS Decisions records the user's authorization for
round 5 only.

Preserve O-001 through O-010 and their Class identities. Round 4 held up
T030o21, T030o22 and T030o18's indentation guard under attack, and confirmed
T030o20's closed-set decision by re-deriving the sealed floor source
byte-identically from an independent session. It reopened O-002 (fourth time),
O-004 (fourth) and O-010 (second).

The follow-ups under review this round:

- T030o23 / O-002: the suppressed set is now DERIVED from the CommonMark
  HTML-block start conditions -- 1, 3, 4 and 5 suppress; 6 and 7, `<details>`
  included, do not -- applied at the single `vf_quoted` site so every consumer
  and the three raw tasks.md passes in sdd-analyze.sh inherit it. This also
  closes the `<!DOCTYPE`/`<?`/`<![CDATA[` residual carried in Open questions.
- T030o24 / O-004: the different-ID `Prior` branch is REMOVED, not narrowed. A
  resolved claim requires the finding's own ID in an earlier round of the gate
  or in a declared prior-review manifest.
- T030o25 / O-010: environment-record membership is EXACTLY
  `verification_environment:`; PATH, SHELL, LANG, TMPDIR and the LC_* family
  are no longer hashed, with the reasoning recorded against the existing
  tool/harness records.

Round 4's central claim was that the implementation APPROACH was failing: each
criterion had been written as the previous report's list of examples, so it was
satisfiable while the class stayed open. Each criterion above therefore cites a
derivation and its source. Assess whether that actually closes the classes, and
whether the derivations are the right ones -- round 3 and round 4 both found a
criterion that was itself the wrong rule, implemented faithfully.

Three things the sweep found that round 4 did not name, all recorded in STATUS
Decisions: a THIRD shipped fixture certifying the O-004 attack, which ran it
over BOTH gates; a wrong acceptance criterion of the implementer's own for
T030o25, corrected before capture; and a negative that passed for the wrong
reason through a broken `awk -v`. Treat all three as attack surface, not as
reassurance.

Every guard is isolated by its own mutation, including an over-correction
control that suppresses all raw HTML and is killed by the `<details>`
positives. The mutation matrix is in STATUS Decisions; verify it rather than
trusting it.

Known gap, stated rather than defended: the reality-check gate has NEVER run on
this spec (zero rounds). Its report path has only ever been exercised by
fixtures, and one of those was asserting the O-004 attack as correct until this
sweep. Nothing has driven a real reality-check report through the corrected code.

Evidence currency: the three sweep accepts (CAP-202/203/204) were sealed against
input 584419df..., then plan.md and spec.md were aligned with the repairs, so
that Evidence is HISTORICAL. The pre-gate refresh re-establishes currency; the
floor and round identities the invoker supplies are authoritative.

## Reality-check

After opponent clearance, the invoker refreshes the floor and reserves the
independent reality-check. During that reservation run:

`bash tests/probe-gate-contract.sh .specify/specs/003-gate-round-reduction-and-token-discipline`

The real rejected-copy/intact-acceptance control is in accept-events/accepted;
its typed rejection must be binding-mismatch with unchanged task digests.
Return the complete canonical report starting exactly at `## Round n` and
ending at the matching gate-round-end marker. The invoker persists it with
spec-gate round --complete. No reviewer edits canonical gate state.
