# Golden example — the calibration bar for `/sdd:plan` and `/sdd:tasks`

One complete, small, realistic spec → plan → tasks set. The phase skills point
here when drafting: **this density is the bar** — pattern anchors and
pre-decided seams in `plan.md`, exact *Verify:* commands and `[hard]` judgment
in `tasks.md`, and no more prose than that.

What to imitate:

- **plan.md** — every touched file has a pattern anchor (the existing file to
  mimic) or an explicit "no precedent"; every task boundary has its signature
  written down under *Internal seams*; risks each carry a mitigation that
  names the test or flag that covers it.
- **tasks.md** — every task carries the exact *Verify:* command with its
  expected key output (or `manual: …`); `[hard]` marks the one task with real
  reasoning risk; refs point at REQ/AC **and** the plan section.
- **spec.md** — every AC names the command that proves it; the deploy-only AC
  is tagged `[DEPLOY]` with a committed-artifact evidence plan.

Not a real repo: `acme-api` and its paths are illustrative. The set stays
internally consistent — `tests/test-golden-example.sh` runs `sdd-analyze.sh`
over this directory in CI, so it can never drift into a bad example.
