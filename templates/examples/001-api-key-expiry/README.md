# Golden example — the calibration bar for `/sdd:plan` and `/sdd:tasks`

One complete, small, realistic spec → plan → tasks set. The phase skills point
here when drafting: **this density is the bar** — pattern anchors and
pre-decided seams in `plan.md`, exact *Verify:* commands and `[hard]` judgment
in `tasks.md`, and no more prose than that.

What to imitate:

- **plan.md** — every touched file has a pattern anchor (the existing file to
  mimic) or an explicit "no precedent"; every task boundary has its signature
  written down under *Internal seams*; concrete FM/INV rows name shared failure
  cases and enforcement sites, with exclusions and typed test families. No
  future task numbers are needed when defining those families.
- **tasks.md** — every task carries the exact *Verify:* command with its
  expected key output (or `manual: …`); `[hard]` marks the one task with real
  reasoning risk; refs bind the plan's FM/INV rows to concrete Tests locators.
  Behavior tasks add or extend their tests in the same commit; T005 composes
  integration after those local checks. The docs task uses a custom executable
  `assertion`; a failed automated check cannot become a manual observation.
- **spec.md** — every AC names the command that proves it; the deploy-only AC
  is tagged `[DEPLOY]` with a committed-artifact evidence plan.

Not a real repo: `acme-api` and its paths are illustrative. The set stays
internally consistent — `tests/test-golden-example.sh` copies it into a sandbox
project and runs `sdd-analyze.sh --phase tasks` with zero authoring warnings.
It supplies illustrative `gate_checks` (`bun test`, `bun run typecheck`) and
an optional Backend checkpoint there. This validates authoring only; it does
not execute the fictional API tests, create test stubs as acceptance proof, or
claim AC-004's CloudWatch screenshot exists. Those tests and the separate manual
deploy observation must exist when their actual implementation is accepted.

The [version 1 verification contract](../../verification-contract.md) owns the
grammar. Shipped spec artifacts 001/002 remain unchanged; only this teaching
example opts in to `verification_contract: 1`.
