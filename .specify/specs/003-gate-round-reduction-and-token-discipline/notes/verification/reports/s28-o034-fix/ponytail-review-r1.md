What this change does: Anchors runner recognition at the start of the Verify command and keeps the existing warning text and exit-0 policy. It extends the existing authoring test with 23 weak-command cases, 20 runner controls, and the accepted T031a5o1 task entry.

Independent O034 repair review, round 1. Runtime selection confirmed as `codex_codex_gym/gpt-6.1-sol`, reasoning `max`, service tier `default`. Reviewed source snapshot `76977c6609cc7064d3fa73250b821c0f04c3375f6f632410a6c2ebc6ddaefffa` in the assigned worktree, assuming one operator running the local CLI.

Scope was limited to `scripts/sdd-analyze.sh`, `tests/test-sdd-analyze.sh`, and the task declaration/date/acceptance evidence. I compared their exact before-live-application copies with current bytes, rather than attributing the larger pre-existing diff against HEAD `2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9`. I read AC-004/REQ-005, the applicable constraints, plan grammar/FM-001/INV-005/authoring family, authoritative verification contract, connected callers, fixtures, assertion propagation, suite runner, and README.

**Must fix:**

1. **Redirected filenames still masquerade as test executables** ([scripts/sdd-analyze.sh:293](/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/scripts/sdd-analyze.sh:293), [tests/test-sdd-analyze.sh:667](/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/tests/test-sdd-analyze.sh:667)).
   - **What this is:** All three runner alternatives accept a directory prefix containing any non-whitespace characters. Shell redirection operators `<` and `>` end the executable word even without surrounding spaces.
   - **Problem:** For `npm<tests/test-typecheck.txt run typecheck`, the shell runs `npm run typecheck`, but the classifier consumes `npm<tests/` as a directory and exempts the command. Equivalent inputs also bypass the named-runner and package-runner alternatives on lines 294 and 295.
   - **Fix:** Constrain every executable/script path prefix so it cannot consume `<` or `>`, and add the spaced/unspaced pairs below to the existing negative loop. Retain the genuine runner controls; this needs no full shell parser or dependency.
   - **If we skip it:** Plain input/output redirection still hides build/typecheck/text-only verification, leaving the O034 warning failure under AC-004/REQ-005 unresolved.

Fresh scratch fixtures passed these exact untyped AC Verify strings to the public analyzer:

```text
npm<tests/test-typecheck.txt run typecheck
tsc>tests/test-typecheck.log --noEmit
grep<tools/pytest typecheck
grep<tools/npm test typecheck.txt
```

All four returned exit 0, omitted `untyped AC Verify`, and reported `consistent`. Adding one space immediately before each redirection operator made all four emit the required warning with exit 0. Isolated executable stubs also confirmed that Bash executes `npm` with arguments `run typecheck`, and `tsc` with `--noEmit`; no test executable runs. This is a remaining O034 runner-position failure on permitted redirection syntax; the documented bounded-classifier shortcut can remain.

Verification:

- Consumed the genuine live CAP-791-DfeS6O: 19/19 passed, exit 0. Independently checked its recorded file digests; both input manifests hash to `76977c6609cc7064d3fa73250b821c0f04c3375f6f632410a6c2ebc6ddaefffa`, and output hashes to `f9166fdc124954abb48f7c8ed789d96a1ce68c06a9da6df0d9d49a79a07aca5a`. The manifests contain the current analyzer/test hashes.
- Inspected the retained red result: 18/19, exit 1, with 38 failed assertions against the old classifier. Retained candidate Bash syntax/ShellCheck records and live changed-file ShellCheck are exit 0; the live tasks-phase analyzer records only the existing 101-task guideline warning.
- Fresh checks ran under Bash 3.2.57 using external scratch fixtures. Leading whitespace, multiple operand-free shell flags, direct test basenames, absolute Python/Bats/package/go/node runner paths, and genuine runners with output redirection remained correct. The new code uses POSIX AWK expressions and adds no runtime dependency.
- Confirmed current source/test/task hashes, file modes, STATUS hash, and index hash/mtime remain unchanged. Only this assigned report was written in the worktree; scratch fixtures were removed.

Not checked: current whole-project floor, hosted CI, or formal opponent25/RC4 clearance. Risk: the reproduced O034 gap remains; O032 is unchanged and open.
Verdict: fix 1 first.
