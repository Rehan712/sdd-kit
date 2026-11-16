## Plan review
**Verdict:** SOUND
**Findings:** 8

### What I attacked
- **REQ and AC coverage.** I walked REQ-001 to REQ-009 and AC-001 to AC-012 against plan §1 to §8. I checked the page map (§3) line by line against `git show origin/main:README.md` (b9814e6, the same tree as HEAD). All 20 heading lines match spec §9, and the eight link rewrites in rule 3 are every `](` link that needs one. The only "above" references that cross a page are 644 and 662–665. The ones at 402 and 633 stay on the same page.
- **Real build, measured.** I split the README per §3 and built it with the cached Zensical 0.1.1 (`uv run --offline`), using the §4.1 config verbatim. Results:
  - The strict build exits 0 and writes `site/404.html` plus all 11 pages. `search.json` is present, so search is on by default (`zensical/config.py:2437`).
  - The 404 page uses absolute `/sdd-kit/` asset paths and shows the full nav.
  - The only absolute asset tags are the own-host canonical links.
  - The §4.3 step-5 probe exits 1, and the ANSI-stripped output names `docs-check-no-such-page.md`. A missing anchor also exits 1.
- **R4 is now settled.** The bundle's third-party URLs each come from an optional feature: the ResizeObserver polyfill (only on old browsers), ace, glightbox, mermaid, pyodide, and `api.github.com` (only with `repo_url`). The moved content uses none of them.
- **Test retargets (§4.5).** I read every site against the live tests: `test-usage-limits.sh:1067-1081`, `test-build-adapters.sh:135-145,340`, `test-gate-contracts.sh:3029-3170`. I placed each pinned string by README line:
  - `sdd-reality-check` at 153 and "covers only the turn" at 228 → `workflow.md` and `model-tiering.md`
  - the limit keys at 475–497 → `dispatch.md`
  - `Rounds 1–3` at 157, all other topics and all six `spec-gate.sh` verbs at 709–760 → as §4.5 states

  The two-file `cat` and the `kit_files … | tr` loop pass `shellcheck --norc -S warning`.
- **Workflow (§4.2).** Every action major tag exists (`gh api …/git/ref/tags`). The latest releases match §5.
- **Analyzer.** `sdd-analyze.sh` on the spec dir reports consistent.
- **Not examined:** a live Pages deploy, the AC-004 viewport checks, the real `deploy-pages` permission needs beyond its documented pair, and Linux runner behaviour.

### Finding P-001
- **Kind:** seam
- **Trigger:** §4.4 item 5 is followed literally: "one bullet per site page, `https://rehan712.github.io/sdd-kit/<file without .md>/`". For `index.md` that gives `https://rehan712.github.io/sdd-kit/index/`.
- **Where:** plan §4.4 item 5; §7 `test_AC_005…`; REQ-005, REQ-007
- **Consequence:** The measured build puts the landing page at `site/index.html`, and there is no `index/` directory, so the README's own entry-point link returns 404. Nothing catches this or any later page rename:
  - the strict build only reads `docs_dir`;
  - `test_AC_005` only checks that the base URL appears somewhere in the README.
- **Amend:** Pin the index bullet to the site root, or list only the ten other pages. Add an FM row and a `test_AC_005` assertion that every README `https://rehan712.github.io/sdd-kit/<x>/` maps to an existing `docs/<x>.md` (and the bare root to `index.md`).

### Finding P-002
- **Kind:** failure-mode
- **Trigger:** The §5 local command (`uv run … -- bash tests/docs-check.sh`) runs in a kit clone that `setup.sh` has made `~/.sdd`. Step 2 then runs `zensical build --clean --strict` there.
- **Where:** plan §4.3 steps 2 and 5; §5 "Local run"; `scripts/brief-status.sh:32`; `skills/sdd-onboard/SKILL.md:49`; `.gitignore` (`.cache/`)
- **Consequence:** `--clean` means "Clean cache" (`zensical build --help`), and the cache is `<root>/.cache/`. That is the same directory as the hub's onboarding clone cache. Measured: a planted `.cache/repos/myrepo/file` was gone after one build. Every cached GitHub-only repo clone is deleted, and `/sdd:onboard` and `brief-status.sh` have to re-clone. The briefs themselves survive. The flag also buys nothing for `site/`: a build without it still removed a planted stale `site/stale.html`.
- **Amend:** Drop `--clean` from steps 2 and 5. CI starts clean, and the probe's temp dir keeps its own cache. Add an FM row: "the local check never deletes `<root>/.cache/repos`".

### Finding P-003
- **Kind:** failure-mode
- **Trigger:** In step 5, the probe build exits non-zero without printing `docs-check-no-such-page.md`. For example, the copy fails for an unrelated config reason, or the name check was never written.
- **Where:** FM-002 (second half); §7 docs-check family; `test_AC_008…` stub description; §4.3 step 5
- **Consequence:** FM-002 promises `strict build failed without naming the broken link`, but no test locator exercises it. The only FM-002 stub "always exits 0". That stub also has to write `site/404.html` and a clean `*.html` in its working directory, or the check stops at step 3 or 4 and never reaches step 5. Separately, "output captured" is not pinned to a stream. Measured: the link name appears only on stderr (0 matches on stdout, 1 on stderr). A capture of stdout alone therefore fails every correct PR build.
- **Amend:**
  - Pin the step-5 capture as `2>&1`.
  - Pin the FM-002 stub: it writes `site/index.html` and `site/404.html` in the cwd.
  - Add a second stub that exits 1 silently when `docs/index.md` contains the probe link, expecting the "without naming" message.

### Finding P-004
- **Kind:** code-mismatch
- **Trigger:** Rule 1 (verbatim) is applied to README lines 223, 238 and 247. These are the sub-bullets `*Claude Code:*`, `*Codex CLI:*` and `*Copilot CLI:*`, indented two spaces under "How it's applied per CLI".
- **Where:** plan §3 rule 1; `docs/model-tiering.md` (source lines 172–286)
- **Consequence:** Zensical's Markdown needs four-space nesting. In the probe build, `model-tiering/index.html` renders the three sub-bullets as siblings of their parent bullet, so the per-CLI breakdown loses its structure on the site. The text survives, so no check fires. REQ-003's "user guide" reads wrong.
- **Amend:** Add a named move rule: nested list markers indented two or three spaces are re-indented to four. `readme-coverage.sh` already trims whitespace, so it still passes.

### Finding P-005
- **Kind:** guess
- **Trigger:** Rule 2 ("every other moved heading is written `##`") is applied mechanically, for example with `sed 's/^#\{1,\} /## /'`, to the `verification.md` source range. README lines 721–736 hold `# …` comment lines inside the ```bash block.
- **Where:** plan §3 rule 2; §4.6 normalisation ("leading `#` characters" deleted); `tests/test-gate-contracts.sh` `documented_example_cases` (skips `'#'*` lines)
- **Consequence:** The bash comments become `## Returns and reports…` and so on. Every guard is blind to it:
  - `readme-coverage` strips leading `#` before comparing;
  - the documented-example fixture skips any line starting with `#`;
  - AC-002 only looks for the 20 headings.

  A change that rule 1 forbids ships undetected.
- **Amend:** Rule 2 should say "outside fenced code blocks". The §4.6 normalisation should strip leading `#` only on lines outside a fence.

### Finding P-006
- **Kind:** seam
- **Trigger:** `test_AC_002…` matches each heading as `^#{1,6} <text>$` with the literal heading text inside an ERE. Seven of the 20 headings contain parentheses, for example `Model tiering (which model runs each phase)`.
- **Where:** plan §7, "What each new test asserts", `test_AC_002…`
- **Consequence:** In an ERE, `(which model runs each phase)` is a group, so it does not match the literal parentheses. The test fails on correct pages. The apostrophe in `What's in the box` also complicates quoting.
- **Amend:** Compare as fixed strings. Strip the `#{1,6} ` prefix from each candidate line, then compare for equality.

### Finding P-007
- **Kind:** code-mismatch
- **Trigger:** The README is trimmed per §4.4, so it has no "Multi-machine" section any more.
- **Where:** `registry.example.yml:31` (`see README "Multi-machine"`); plan §2 (only `scripts/sdd-doctor.sh:347` is retargeted)
- **Consequence:** This is a sibling of the pointer the plan already fixes in `sdd-doctor.sh`, and it is missed. `setup.sh` bootstraps every new `registry.yml` from this example, so new installs get a comment that points at a section that no longer exists. That contradicts REQ-005's "docs own the detail".
- **Amend:** Add a §2 row that retargets it to the Install page, for example `see docs "Multi-machine"` or the site URL `…/install/#multi-machine`.

### Finding P-008
- **Kind:** seam
- **Trigger:** A later page is added under a subdirectory, for example `docs/guides/x.md`, and not added to `nav`.
- **Where:** plan §7 `test_AC_003…` (uses `kit_files docs '*.md'`); `tests/helpers.sh:558` (direct children only); AC-003 ("every markdown page under `docs/`")
- **Consequence:** The planner measured that the strict build exits 0 for a page that is not in `nav`. `kit_files` never lists subdirectory files, so the page stays out of the navigation and every check passes. AC-003 is literally broken.
- **Amend:** `test_AC_003` should also fail when any `docs/*/` path exists, or should enumerate `docs/` recursively and expect nav entries with subpaths.

Not checked: the live deploy, the 375px rendering and the network log (all `[DEPLOY]`), and the first deploy's behaviour with Pages not yet enabled. These depend on the owner enabling Pages before merge (§8 step 3).
