# Deterministic gates & acceptance evidence

How to build, test, and prove the deterministic scripts that gate SDD (staleness
detectors, doctors, validators) — and how to accept the behavioral criteria that
depend on them. Lessons harvested from shipped specs; each is dated and cited.

## Test the input surface, not just the happy path

A deterministic script that becomes a "single source of truth" (consumed by
doctor/status/setup/skills) fails on its *inputs*, not its logic. A happy-path
scenario test goes green immediately and stays green while every real defect
hides in the input surface. Before shipping such a script, enumerate and test:

- **Malformed / partial input** — a field present but unparseable is a distinct
  verdict (`unknown`), not a measured result. Don't let a missing separator fall
  through to a real-looking answer.
- **Boundary values** — N-1 / N / N+1 around every threshold.
- **Numeric flags** — leading zeros (bash `(( ))` reads `08` as octal → error →
  wrong branch; normalize `$((10#$N))` after the digit-shape guard), empty value,
  huge value. A `^[0-9]+$` guard is not a base-10 guard.
- **Every flag with a missing value** — `--flag` as the last arg: guard
  `shift 2 || { echo "…requires a value" >&2; exit 2; }`, or it can spin (a
  failed `shift 2` doesn't shift, and without `set -e` the parse loop re-reads).
- **Unknown subcommand / usage errors** — must exit non-zero. Keep the help path
  (exit 0, stdout) separate from the error path (exit 2, stderr); don't reuse a
  `usage()` that ends in `exit 0` for the error arm.

*(learned: sdd-kit/001-onboarding-repo-briefs — opponent found o2/o3/o7/o8/o9 all
on the CLI/input surface of one bash detector after the happy-path test was green
from round 1.)*

## Re-run the FULL matrix after any value-selection fix

When a fix changes *which* value the logic selects (which git ref to count
against, which branch is the base), the regression usually isn't in the new case
— it's in the interaction with an old one. Re-run the entire scenario matrix
against the fix, not just the case you were closing. Two consecutive fixes to a
ref-selection resolver each broke the previous round's passing case (a frozen
local head out-voting a fetched remote ref; then an unconditional `--depth`
shallowing a full checkout). *(learned: sdd-kit/001 — o4 and o5 were both
fix-induced regressions caught only because each round re-ran the prior fixtures.)*

## "Make-X-visible" features: enumerate every path X can go silent

If a feature exists to make something *visible* (drift, staleness, a failure),
the adversarial focus is every code path where that signal can silently read
"fine." List them explicitly and test each. A drift-detector reintroduced silent
`fresh` three separate times — counting the wrong branch, a frozen ref
out-voting a moved one, and a triage step that skipped the network fetch the only
drifting repo class needed. The metric "non-zero count **iff** it actually moved"
is a two-way test: also prove it does NOT go silent. *(learned: sdd-kit/001 —
o1/o4/o6, all silent-staleness, in a visible-drift feature.)*

## Behavioral ACs need a live run, not a grep

An acceptance criterion whose verb is behavioral — *checks*, *emits*, *warns*,
*refuses*, *skips* — is met by a live run that makes the behavior fire, not by
grepping that the instruction exists in a skill/spec. Grep proves the text is
present; it does not prove the gate fires on the triggering input. If the AC
itself prescribes a run ("verified by … one run against <condition>"), the task's
acceptance and evidence must record that run (the triggering input, the captured
output, and — for a "never does Y" clause — proof Y didn't happen, e.g. an
unchanged checksum). *(learned: sdd-kit/001 — reality-check gap T020a: AC-009 was
"verified" by skill-text grep; the prescribed plan-run against a stale brief was
missing until the gate demanded it.)*
