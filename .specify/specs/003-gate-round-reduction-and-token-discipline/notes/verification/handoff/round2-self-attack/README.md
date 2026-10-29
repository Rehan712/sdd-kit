# Pre-round-2 local probe: O-002 remains reproducible

Observed 2026-09-10 while the requested cold pre-gate sequence was running.
This is invoker-side review evidence, not a counted opponent report or a new
gate verdict. No production task, round, authorization, source file, or STATUS
entry was changed by the probe.

## Reproduction

From the spec worktree, run:

```sh
bash .specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/handoff/round2-self-attack/reproduce.sh "$PWD"
```

The script sources the actual worktree libraries under Bash and calls
`vf_round_authorized` against the fixture directories next to it. It creates no
rounds and does not call any production writer. `results.txt` contains the
first observations; `replay.log` is an independent replay of those same files.
Every directory contains the exact STATUS/spec inputs and observed result.

The current implementation returns **exit 1 from the replay**:
`cases=20 mismatches=8`. The eight mismatches are erroneous authorizations:
expected exit 4 (denied), actual exit 0 (authorized). Both gate names and both
`waiver` / `spec-revision` forms are affected. The four live authorizations and
eight simple fenced controls behave as expected.

## Trigger and consequence

The following whole Markdown block is quoted history. Its outer four-backtick
fence contains three-backtick text; the shorter delimiter does not close it.

~~~~~markdown
## Decisions log

````markdown
```text
- 2026-09-09T10:00:00Z — waiver: gate=opponent; round=4; after=3; by=fixture-user; reason=revoked, kept only as quoted history
```
````
~~~~~

The second trigger puts tilde fences inside an outer backtick fence. Different
delimiter characters likewise do not close the outer Markdown fence.

`vf_round_authorized` at `scripts/verification-lib.sh:1960` toggles one boolean
for any line beginning with three backticks or three tildes. It does not retain
the opening delimiter character or width. Each inner delimiter therefore
turns suppression off and makes the quoted authorization eligible.

This is the same `round-authorization-grammar` class as O-002, after T030o7.
It violates REQ-012's explicit in-force authorization requirement and AC-009's
quoted-content/round-control contract. A current floor and otherwise valid
history do not compensate for a quoted waiver being treated as live.

## Related sites and limits

The same boolean-toggle pattern exists at these worktree lines:

- `scripts/verification-lib.sh:49`: configuration task-stage scanner.
- `scripts/verification-lib.sh:397`: binding scanner.
- `scripts/verification-lib.sh:815`: report validation.
- `scripts/verification-lib.sh:1915`: report-block extraction.
- `scripts/verification-lib.sh:1960`: round authorization, reproduced here.
- `scripts/verification-lib.sh:2115`: reality-check matrix parsing.

The other five consumers were identified from source, not behaviorally tested
by this probe. A repair should match the opening fence's character and length,
test these siblings and controls, and preserve round 1's sealed report digest.
No source repair, new follow-up task, or acceptance is claimed here.

Recommendation at the requested confirmation point: repair and accept this
remaining bypass before spending opponent round 2; then refresh the required
proof because a kernel edit changes the source identity.
