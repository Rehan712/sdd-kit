What this change does: Recognizes runners at executable and runner positions after removing simple unquoted input/output redirects. It preserves warning-only exits and explicit verification kinds, expands the authoring regression cases, and records accepted T031a5o1 evidence.

Independent quality review, round 2. Live orchestration confirms provider `codex_codex_gym`, model `gpt-6.1-sol`, reasoning `max`, service tier `default`. I assumed one operator running the local CLI, including the current 101-task spec.

I reviewed the complete three-file repair against the exact C7 `before-live-application` copies and read the correction's before/after files, patch, full handoff and prior findings. The comparison is 89 insertions and 13 deletions; broader pre-existing changes against HEAD `2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9` are outside this repair. Connected review covered AC-004/REQ-005, FM-001/INV-005, the authoring registry and normative verification contract, command extraction, the sole classifier caller, warning aggregation, invokers, fixtures, assertion propagation, suite runner and README.

**Must fix:**

1. **Text checks written with executable paths still miss the warning** ([scripts/sdd-analyze.sh:298](/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/scripts/sdd-analyze.sh:298), [tests/test-sdd-analyze.sh:668](/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/tests/test-sdd-analyze.sh:668)).
   - **What this is:** The shared weak-command predicate recognizes `grep`, `rg` and `diff` only at the start of the string or after whitespace. An executable written with a directory has `/` immediately before its name.
   - **Problem:** Untyped AC Verify commands `/usr/bin/grep AC-001 tests/check.sh` and `/usr/bin/diff fixtures/test.txt actual.txt` both exit 0 and report `consistent` without the required warning. Their bare-command equivalents warn; absolute `rg` and redirected executable-path cases reproduce the same omission.
   - **Fix:** Recognize these weak text tools at the executable position with an optional directory prefix, and extend the existing negative loop with executable-path and redirected controls. Keep the genuine-runner and explicit-kind controls; this needs no shell parser or dependency.
   - **If we skip it:** Plain text-only checks still pass authoring validation without the AC-004/REQ-005 warning, leaving this O-034 sibling unresolved.

Fresh public-analyzer fixtures reproduced all four commands below with exit 0, no `untyped AC Verify`, and `consistent`:

```text
/usr/bin/grep AC-001 tests/check.sh
/usr/bin/grep<input.txt AC-001 tests/check.sh
/usr/bin/diff fixtures/test.txt actual.txt
/usr/bin/diff>output.txt fixtures/test.txt actual.txt
```

These are direct commands with simple unquoted redirection, within the correction's stated boundary. C7 reproduction also fails: this is a remaining class-wide sibling, rather than a newly introduced regression. Exact fixture declarations, argv, outputs and C7/current comparisons are retained in [the review receipt](/Users/babar/projects/sdd-kit-public.worktrees/003-gate-round-reduction-and-token-discipline/.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports/s28-o034-fix/ponytail-review-r2-checks.json).

The previous quality finding is fixed. Fresh probes of its four exact inputs and four spaced counterparts all emit the warning with exit 0. Sixteen further boundary/control probes passed, including leading redirects, append redirects, multiple standalone file descriptors, neutral filenames, genuine interleaved runners, and executable names ending in digits. All three runner alternatives exclude redirect operators from executable/script paths. The correction stays small and adds no dependency or execution of task-supplied command strings.

Verification consumed and checked:

- The retained RED suite is 18/19, exit 1, with 90 assertion failures: 21 missing weak warnings and 24 wrongly warned genuine runners, each detected by two assertions. The GREEN declarations match the final source exactly: all 69 weak cases warn with exit 0 and all 50 runner controls stay clean. Assertions update `_t_fail` in the test process; `t_run_all` and `tests/run.sh` propagate failures. These cases invoke the public analyzer, rather than duplicating its regex.
- CAP-792-l5lK98 contains the current analyzer/test hashes and genuine 19/19 output. I rehashed every sealed capture file; both input manifests are byte-identical and hash to `dfa8f89669e39310c4b0a342c28091dbd01abb0cbdfbca8e34369977c9533a63`. Output hashes to `f9166fdc124954abb48f7c8ed789d96a1ce68c06a9da6df0d9d49a79a07aca5a`; metadata records exit 0, no-tick, and the assigned worktree/cwd.
- Acceptance receipt ACC-imWUNv seals correctly. Its accepted task bytes equal current tasks.md, and its return matches SHA-256 `89f9dca7497de37fdb29ba97009fe2cd212fd1da35ec0ef3ff1d9637688c9f7a`. This establishes the actual chronology despite the older pending wording in Notes. The stopped scout supplies no passing evidence; the parent's actual capture/acceptance receipts do.
- Fresh checks used Bash 3.2.57 and `/usr/bin/awk`. Each changed shell file separately passes `bash -n`; all three exact C7/current file pairs have no whitespace diagnostics. The new expressions use POSIX AWK operations. Consumed warning-level ShellCheck has `--norc` and cleared `SHELLCHECK_OPTS`, exit 0; the actual tasks analyzer has only the existing 101-task advisory. Existing test/assertion/static/manual family controls pass in the captured suite. The 16 retained shell-stub demonstrations were inspected, not rerun.

The bounded shortcut remains appropriate for complex shell forms. Additional exploratory inputs with namespaced package scripts, operand-taking shell flags or descriptor duplication need explicit Verify kind; no general shell grammar was certified. No additional lean finding was established. O-032 and the previously recorded minor follow-ups remain outside this repair.

Integrity: analyzer/test/tasks retain the supplied hashes, modes 755/644/600 and mtimes; STATUS, HEAD and index hash/mode/mtime are unchanged. Of 16,891 existing files checked, 16,890 were unchanged. During review, `notes/verification/reports/s26-next-session-prompt.md` changed concurrently and `ponytail-review-r2-invocation.json` appeared; both were preserved, with hashes and times recorded in the receipt. My worktree writes are only this report and its prefixed checks receipt; scratch probes stayed in my external mkdtemp directory.

Not checked: current whole-project floor, full-suite reruns, hosted CI, opponent25 or RC4. This supplies no formal gate/readiness verdict; historical CAP-791, C7 floor and hosted CI are not current repair proof. Risk: the executable-path warning gap remains, and O-032 is still open.
Verdict: fix 1 first.
