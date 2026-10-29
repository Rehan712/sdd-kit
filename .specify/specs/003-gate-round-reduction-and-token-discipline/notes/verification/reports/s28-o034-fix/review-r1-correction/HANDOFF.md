Implementation correction handoff — editing batch closed. Independent quality r2 remains pending; this handoff supplies no formal gate or model verdict.

Scope: exactly scripts/sdd-analyze.sh, tests/test-sdd-analyze.sh and the existing T031a5o1 block in tasks.md. No other task, metadata, kernel, plan, spec or STATUS bytes changed. No dependency, parser or refactor was added.

The shared classifier removes simple unquoted input/output redirections before recognizing direct runners. Separate file-descriptor tokens are removed without truncating executable names ending in digits. Every executable/script path prefix and direct script token excludes < and >. The existing warning text, warning-only exit policy and explicit verification-kind controls are unchanged.

T031a5o1 is [ ] and has no current Evidence line. Its acceptance and notes now cover quality r1’s redirection boundary. Prior CAP-791-DfeS6O/source 76977c6609cc7064d3fa73250b821c0f04c3375f6f632410a6c2ebc6ddaefffa/accepted return 1db01df45ea2f2071a5c5f057f9e8ff8c1eca4f54c21423056becc6e34331d2f are retained in the originals and copied under prior-proof/. They are historical partial proof, not proof of this correction.

Checks and actual results:

- Red: expanded public /bin/bash tests/test-sdd-analyze.sh against the unchanged baseline classifier exited 1, 18/19 passed, with 90 assertion failures. The 119-command public probe found 21 missing weak-command warnings and 24 wrongly warned runners; all individual analyzer invocations exited 0. The four exact reported negatives each missed their warning while their spaced pair warned.
- Green: final public /bin/bash tests/test-sdd-analyze.sh exited 0, 19/19 passed. All 69 weak cases warn with exit 0 and all 50 runner controls report consistent with exit 0. Counts retain the prior 23 weak cases/20 runner controls and add 46/30 respectively. Existing explicit test/assertion/static/manual controls pass in the same suite.
- Neutral redirect targets exercise typecheck/build/tsc/grep/rg/diff/file-existence siblings, input and output operators, attached/spaced forms, redirected fake shell/script/named/package runners, and genuine direct/script runners with interleaved redirects. No result relies only on a typecheck word in a redirect filename.
- Sixteen isolated Bash 3.2.57 stub demonstrations retain executable names and arguments for the four exact cases, spaced counterparts and neutral-target siblings. Only owned stubs executed; no real npm, installation or network command ran.
- Bash 3.2 syntax, changed-file warning-level ShellCheck with SHELLCHECK_OPTS cleared and --norc, and git diff --check all exited 0.
- Actual tasks-phase analyzer exited 0, confirmed typed bindings, parsed 101 tasks and emitted only the existing 101-task guideline advisory: 1 warning, 0 errors.

Proof files:

- baseline-proof.json and before/: exact baseline inventory, modes/mtimes and recoverable copies saved before live edits.
- after/, repair.patch and closed-batch-proof.json: exact final copies, baseline-relative three-file diff, actual before/after hashes/modes, and closed-batch scope audit.
- red-suite.{json,stdout,stderr}, green-suite.{json,stdout,stderr}: exact argv/environment/cwd/exit and full suite output.
- cases.{json,tsv}, red-probe/, final-green-probe/, red-summary.json, green-summary.json: all 119 declarations, command argv, exits and complete public analyzer outputs. Probe launcher records and complete case summaries are also retained. green-probe/ retains the earlier passing intermediate check.
- shell-semantics/results.json and numbered output/argv files: actual isolated shell behavior.
- bash32-syntax.*, shellcheck.*, tasks-analyzer.*, diff-whitespace.*: requested checks with exact argv, exits and output.
- prior-proof/: original CAP-791 capture files and manifest, accepted return, receipt, acceptance result, original quality report and actual model provenance.

Final integrity: all 14,902 unowned existing files retain identical bytes, modes and mtimes; no new file exists outside this authorized report directory. HEAD remains 2049f65960cc91e9e30bbd5ff1e11fc0fdf7cbd9. Index remains c492d7ea95abf8e8c335001f20c62ff50bc6f1e2179d7a07d30811181b3dd700 with mtime 1792957592613445716 ns. STATUS remains 28919a358c30407ccb0fff041f436768353b2f002c54e1db351ea57efe5e7d88, mode 600, original mtime.

Owned file SHA-256 and preserved modes:

- scripts/sdd-analyze.sh (mode 0o755):
  before 6ab2130ba40e2f96a097c2ca132160535aa8d70d053bd525c2ce5fc7f465966b
  after  1a175221eaa2aca3198a6d93c11618ead124f2c69e1c4351313281d2affd500b
- tests/test-sdd-analyze.sh (mode 0o644):
  before 0ee700041f225bc21e7ca43307d9493fa6ffed98abf145eec0c1f9f874a8f763
  after  c90afc20667bef1269e7d90dd37b807bec0393e27b9948da37d0f3c15dc315a8
- .specify/specs/003-gate-round-reduction-and-token-discipline/tasks.md (mode 0o600):
  before 1f8b6ab712c3a9c2eb8a8011bff5e9148750466efe7e2644341ddae0abe27c07
  after  7530d61107dbcafc2c28b11b9f588fcf2565fbc82e263d50675d6d157bdf6296

Skipped: fresh capture/return/acceptance/tick, floor, formal gate/opponent25, CI, PR, commit and push; these remain parent-owned. O-032 was untouched.
Limit: this remains a bounded classifier for direct runners and simple unquoted redirections. Complex shell quoting/wrappers require explicit Verify kind; arbitrary shell grammar was not certified. Fresh parent capture/acceptance and independent MAX quality r2 are still required.
