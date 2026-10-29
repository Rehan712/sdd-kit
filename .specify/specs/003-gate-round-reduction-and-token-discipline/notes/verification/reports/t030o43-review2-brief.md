# Focused review 2 brief — the T030o43 review repairs, 2026-09-27

Every operational rule of `t030o43-review-brief.md` (read it first, in the same
directory) applies unchanged: read-only, a private copy with `TMPDIR` inside
it, no suite or test function in the worktree, one copy and one suite at a
time, a progressive report at `REPORT_PATH` ending `REVIEW COMPLETE`, severity
per finding with an exact reproduction and the smallest class-wide fix.

## Scope

Only the repairs made for the first review. The first review's report is
`$R/t030o43-review.md`; the invoker's reproduction of every claim is
`$R/t030o43-review-verify.{sh,log,rc}` (in its F2 rows the `rc=` column is a
display slip reporting an inner `echo`; the verdict is the ✗/✓ line). The two
newest entries of the Decisions log in `$S/STATUS.md` record the outcome, the
members the invoker derived beyond the report (a manifest heading, a required
section's body, the identity's Decisions heading, `spec-evidence.sh`'s
contract routing) and the repairs. The candidate repairs were measured before
adoption: `$R/t030o43-review-measure.{sh,log,rc}` (the same F2 display slip).
The class-character members are the last section of
`$R/t030o43-parser-classes.md`.

The delta under review is `$R/t030o43-review-repair.diff` (8 files). The
files as the first review saw them are at `REVIEWED_DIR` (given in your
prompt), proven equal to the pre-delta files plus `t030o43-session.diff`.

## Attack surface

1. The restated premise: under `LC_ALL=C` a byte >= 0x80 is in no character
   class, and a record line or token the ASCII grammar cannot read must never
   read as an absence that passes. Is the member derivation (every class
   spelling in the eight harness files, classified) complete, and is any
   "fails closed" argument in the classification wrong? Test the arguments you
   doubt instead of reading them.
2. The strict manifest pass: does any shipped, real or plausible manifest now
   fail that should parse (prose mentioning a field marker, headings such as
   "## Findings", fenced or commented examples, a Class-only finding)? Can a
   finding still be dropped in silence by any other spelling?
3. `vf_blank`: is the White_Space set right and complete as UTF-8 byte
   sequences, and does any real report's required section now count as empty?
4. The identity's Decisions heading: does keeping the section from the first
   line beginning `## Decisions log` change any identity, or let a Decisions
   edit escape it by another spelling?
5. `spec-evidence.sh`'s three-way routing and `[^[:space:][:cntrl:]]`
   artifact names; `vf_return_parse`'s size read; the five new fixture
   assertions (each should fail with its exact diagnostic when its guard is
   removed); the corrected wording.
