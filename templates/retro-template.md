# Retro — <spec slug>

**Date:** <YYYY-MM-DD>
**Shipped:** <PR URL / deploy date>
**Rounds:** opponent <n>, reality-check <n>
**Tasks:** <n> planned → <n> final (<n> gate follow-ups, <n> security follow-ups, <n> CI/review follow-ups)

## What the gates caught (defect classes)

| # | Defect | Class (stable family) | Root cause (process) | Raw locations | Prior / reopened IDs | Caught by | Prevention |
|---|--------|-------|------------|-----------|------------|-----------|------------|

**Root-cause split:** plan-gap <n> · spec-gap <n> · implementation-error <n> — <one line: which upstream phase to tune, per the split>


## Lessons filed

- **<lesson>** → `knowledge/<file>.md` (applied)
- **<lesson>** → `stack-overlays/<tag>.md` (applied)
- **<lesson>** → project constitution (PROPOSED — awaiting owner)

## Success metrics check

- MET-001: <measured value / "not yet measurable, check <date>">

## What went well

- <keep-doing items — process, not praise>

## Cost and quality observations

Run `spec-gate.sh tally <spec-dir>`; preserve round totals, raw locations,
finding observations, distinct finding IDs, reopened IDs and class recurrences.
Class is the stable defect family; Root cause is plan-gap, spec-gap or
implementation-error. Legacy findings remain unclassified unless an explicitly
annotated copy establishes the mapping; never rewrite shipped raw reports.

| Measurement | Before / baseline | After / observed | Source / limitation |
|---|---|---|---|
| Actual usage / credits (same unit) | unknown | unknown | User's usage view before/after; no token estimate substituted |
| Opponent / reality-check rounds | 5 / 1 for spec 002 | measured | 002 has six wrong-result findings; class mapping unclassified |
| Check executions / cache hits | unknown | measured | Sealed floor/checkpoint command records |
| Full log bytes / returned summary bytes | unknown | measured | Capture files, not estimated tokens |
| Blocking defects / raw sites / reopened findings | measured or unknown | measured | Canonical reports with IDs |

Two rounds and 30% savings are hypotheses, not claimed outcomes. Unknown
baselines stay unknown; report incomparable/missing usage observations explicitly.
Do not change model policy or lower gate severity to meet a measurement target.

**14-day defect observation owner:** <named person, not an agent>.
**Observation starts / check-back date:** <YYYY-MM-DD> / <YYYY-MM-DD, +14 days>.
**Escaped defects / reopened findings at check-back:** <observed count or pending>.
**Next three measurement specs:** <named slugs when available; unknown otherwise>.
Pair every cost comparison with defect observations over that window.
