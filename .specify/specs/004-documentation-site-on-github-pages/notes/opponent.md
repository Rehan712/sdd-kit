
## Round 1
**Round:** 1
**Timestamp:** 2026-11-16T10:32:48Z
**Source:** 14d52c7ba4138c57cd0a8456ce26bc8dea0f1020675260e318fd6bd54b5f6203
**Floor:** FLOOR-HrZL7B
**Verdict:** CLEARED
**Blocking:** 0 · **Minor:** 8

### What I attacked

I read the spec, the plan and the changed code in the worktree. The official `code-review` pass ran at level `high` on `main...spec/004-documentation-site-on-github-pages`. The `ponytail-review` Lean lens was loaded for the lean pass. The review returned 10 leads, and I triaged each one. I report only those that tie to an AC/REQ or to a concrete input. The repo-hygiene leads are bookkeeping and are listed under minor or left out below.

**1. Move fidelity (checked by hand).**
- I took the exact source ranges from plan §3 out of `git show main:README.md`.
- I diffed each of the eleven pages against its range.
- The only differences are the heading demotions, the new titles on `skills-and-routing.md` and `dispatch.md`, and the eight rule-3 link rewrites.
- The three rule-4 edits (README line 644 and the lines 662–665 cross-references) and the rule-5 indent also match.
- The rule-5 indent covers exactly the 30 lines 223–252, now `docs/model-tiering.md` lines 52–81.
- The only extra bytes are one blank line joining `install.md`'s two source ranges and the new `## Start here` list.
- The credits and pitch on `docs/index.md` are identical to old lines 3–11 and 697–705.
- `readme-coverage.sh` also runs clean: 658 lines, 5 exceptions, 0 missing.

**2. Dead links and anchors.**
- The only two `#anchor` links in the old README (lines 31 and 510) were rewritten to `model-tiering.md` and `install.md#multi-machine`.
- The built `site/install/index.html` carries `id="multi-machine"`, and `multi-repo` links to `../install/#multi-machine`.
- No `above`, `below` or `see *…*` cross-reference is left in `docs/`.
- I grepped `docs/` for other forward references, including `earlier`, `section`, `the table`, `following` and `preceding`. None are cross-page.
- All six `blob/main/...` targets exist in the tree.
- I ran a real strict build with `install.md#nope-anchor` appended. It aborts, so cross-page anchors are enforced.
- A missing-page probe prints `index.md:36:20` plus the link, so REQ-007's "names the file and the link" holds.
- Zensical uses Python-Markdown, which is stricter than GitHub's renderer. I checked the built HTML for these three problems and found none:
  - a list or table swallowed into a `<p>`
  - an unknown tag from stray `<word>` text
  - a nested-list collapse

**3. Retargeted tests (`git diff main -- tests/`).**
- Every changed `assert_*` or `gate_documentation_check` line keeps its string. Only the file read, and "README" in a message, changed. This matches plan §4.5 line for line.
- No assertion was removed.
- The two-file concatenation at `test-gate-contracts.sh:3101` keeps all nine topics and both `Required`/`Optional` markers.
- The `awk` heading anchor is changed to `^# Versioned…`, and the extracted bash block is non-empty and still runs.
- `test-docs.sh` passes 15/15 under both bash 5 and macOS `/bin/bash` 3.2.57.

**4. `docs-check.sh` against the failure-mode and invariant rows.**
- I ran the real check: `uv run … zensical==0.1.1 -- bash tests/docs-check.sh` prints `docs-check: ok`. `git status` stays clean, so it writes only ignored paths.
- FM-001 to FM-004 and FM-007 are exercised by `test-docs.sh` with stubs and fixtures.
- INV-004 holds: neither build call passes `--clean` or `-c`.
- `trap … EXIT` on a `local tmp` still sees `$tmp` under `set -u` on bash 3.2 and 5.
- The built site passes the asset scan. 404 pages use absolute `/sdd-kit/assets/...` paths, so the stylesheet loads at `/sdd-kit/no-such-page/` on Pages.
- The palette, search component and viewport meta are present in the built HTML.

**5. Workflow.**
- `docs.yml` is byte-identical to plan §4.2.
- Deploy is gated on `push` and `refs/heads/main`, and `needs: build`.
- Permissions are workflow-level `contents: read` and job-level Pages-write plus `id-token: write` on the last job only.
- The four action majors match the latest releases I read with `gh api` today.
- `ci.yml` is untouched.
- Pages is not yet enabled (`gh api …/pages` returns 404). That is CON-006, expected before the merge.

**6. README.**
- It has 47 lines, the site URL, `## Install` and `## Quick start`, and line 1 starts `# SDD Kit`.
- All ten page links map to real `docs/*.md` files.

**Unexamined.**
- AC-004's 375px layout and network log, AC-001 and AC-007. They are `[DEPLOY]` criteria and need the live site.
- The theme JavaScript's third-party URLs (plan R4), which no static scan can see.
- I did not run the full `tests/run.sh`. I ran only `test-docs.sh`, and the three retargeted suites were not re-run beyond the floor's run.
- I did not run the asset scan under GNU grep and sed. I reasoned it through, and CI will be the first Linux run.
- The `ponytail:ponytail-review` skill ran once for the lean pass.

### Finding O-001
- **Class:** doc-claim-inaccurate
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** A reader follows the README bullet "Model tiering (which model runs each phase) — style guides, skills, routing, usage limits" to look up usage limits.
- **Where:** README.md:42
- **Reproduced:** The `docs/model-tiering.md` headings are only its H1 and bold paragraphs. Style guides and skills sit in `skills-and-routing.md`, and usage limits in `dispatch.md`.
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The one-clause description lists topics that are on other pages. It is new prose that plan §4.4 left to the implementer.
- **Class-wide fix:** Reword the bullet to what the page covers (tiers, roles, per-CLI application, per-project overrides). The other nine bullets are correct.

### Finding O-002
- **Class:** lean-stale-claim-in-moved-text
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** A reader opens "What's in the box" to see what each directory is for.
- **Where:** docs/layout.md:1-40
- **Reproduced:** The tree has no `docs/`, `zensical.toml`, `.github/workflows/docs.yml` or `tests/docs-check.sh`. Plan rule 1 forbids new prose, so this is a spec gap.
- **Root cause:** spec-gap
- **Blocks:** none
- **Wrong behavior:** The layout page is incomplete for the repo it now ships with.
- **Class-wide fix:** Ask the planner whether to add four tree lines. This is not a gate matter.

### Finding O-003
- **Class:** test-assertion-weaker-than-ac
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** `## Credits` is deleted or demoted to plain text, but some line reads exactly `Credits`, or a shell comment inside a code fence reads `# Install`.
- **Where:** tests/test-docs.sh:209-211
- **Reproduced:** By reading the code, not run. `sed -E 's/^#{1,6} //'` runs on every line, so any line equal to the heading text passes, as does a fenced `# Install`. AC-002 says "appears as a heading". This is the plan's own prescription, which the plan reviewer did not flag.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** The test is weaker than the AC wording. The real pages are fine today.
- **Class-wide fix:** Match `^#{1,6} <heading>$` as a fixed string after removing the fences. No other test shares this shape.

### Finding O-004
- **Class:** silent-skip-in-test-input
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** `kit_files docs '*.md'` fails, for example when enumeration breaks. Its exit status is lost in the pipeline and the command substitution is empty.
- **Where:** tests/test-build-adapters.sh:135
- **Reproduced:** By reading the code, not run. `kit_files … | tr` inside an unquoted `$(…)` in a `for` list means no pages are read. `README.md` stays in the list, so the stale-claim check passes without ever reading `docs/`.
- **Root cause:** implementation-error
- **Blocks:** AC-011 (loosely)
- **Wrong behavior:** The check can go silent over exactly the files it was retargeted to. This is the knowledge-lesson class "a check must prove it cannot go silent".
- **Class-wide fix:** Build the list in a `while IFS= read -r -d ''` loop and fail if it is empty, as `test-docs.sh:208` does. No other site in the diff has this shape.

### Finding O-005
- **Class:** hardcoded-host-duplicate
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** A fork edits `site_url` in `zensical.toml` but not `SITE_HOST`.
- **Where:** tests/docs-check.sh:17, zensical.toml:3
- **Reproduced:** By reading the code, not run. The scan reports the fork's own canonical link as a third-party asset. Plan §4.3 prescribes the constant, and the failure is loud rather than silent.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** Two copies of one value.
- **Class-wide fix:** Derive the host from `site_url`, or leave as is and note it.

### Finding O-006
- **Class:** lean-oneoff-script-committed
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** After the merge someone re-runs `readme-coverage.sh`. `git merge-base HEAD origin/main` is then `HEAD`, so the baseline is the new 47-line README and almost every line is reported missing.
- **Where:** .specify/specs/004-documentation-site-on-github-pages/notes/readme-coverage.sh:28, .specify/specs/004-documentation-site-on-github-pages/notes/readme-coverage-exceptions.txt
- **Reproduced:** By reading the code. The exceptions file is keyed by old README line numbers.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** A one-off proof is kept as if it were reusable. Plan §2 lists it as "new, one-off", and `notes/evidence.md` already holds its result.
- **Class-wide fix:** Keep as provenance, or delete after the merge. The smallest change is a one-line header comment saying it is valid only against the pre-merge base.

### Finding O-007
- **Class:** lean-gitignore-pattern-unanchored
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** `site/` also ignores any future directory named `site` anywhere in the repo.
- **Where:** .gitignore:23
- **Reproduced:** No tracked path contains `/site/` today (`git ls-files | grep -i /site/` is empty).
- **Root cause:** implementation-error
- **Blocks:** none
- **Wrong behavior:** The pattern is broader than the single root build output.
- **Class-wide fix:** Anchor it as `/site/`.

### Finding O-008
- **Class:** pointer-vague
- **Status:** new
- **Prior:** none
- **Severity:** minor
- **Scenario:** A user gets the `sdd-doctor.sh` ponytail warning and looks for `(docs: "Ponytail")`.
- **Where:** scripts/sdd-doctor.sh:347
- **Reproduced:** By reading the code. The warning names no page or URL. The section is "Ponytail (companion — v5)" on `docs/skills-and-routing.md`. Plan §2 prescribed this exact wording.
- **Root cause:** plan-gap
- **Blocks:** none
- **Wrong behavior:** The pointer is ambiguous.
- **Class-wide fix:** Name `https://rehan712.github.io/sdd-kit/skills-and-routing/`. `registry.example.yml:31` has the same vagueness: "the docs, Install → Multi-machine".

### Held up / follow-up tasks

I could not break the change as an adversary. Here is what I attacked and why each held.

- **Misread requirement.** AC-002 to AC-012 each map to code or a test that asserts the literal text. The only gap in that mapping is O-003, a test looser than its AC wording, which does not change any outcome on the real pages.
- **Moved text.** A hand diff of all eleven pages against the plan's source ranges, plus the coverage script, show no dropped, reflowed or reordered line.
- **Dead links and anchors.** Strict mode was shown to reject a missing page and a missing anchor. The only two README anchors were rewritten and resolve in the built HTML.
- **Retargeted tests.** No assertion was weakened. Only the file read changed, per §4.5.
- **Workflow and invariants.** INV-001 to INV-004 hold by reading the workflow and the scripts, and `test-docs.sh` passes.
- **Real build.** The real check passes, and its negative probe fails correctly on a broken link.
- **Security leads.** The branch's security pass already covers the scan-host, multi-line-tag and `persist-credentials` leads. I do not re-report them.
- **Committed verification bookkeeping.** About 200 captures, floors and accept-events are tracked, and `STATUS.md` has stale `branch: none`. I treated both as bookkeeping and did not re-litigate them.
- **Other review leads left out.** The review's complaints about `gate_documentation_check` taking one page and about the absolute `blob/main` URLs both follow plan §4.5 and §3 rule 3. The `srcset`, `content` and `poster` gap in the scan is covered by the `shortcut:` comment and the plan's R4 and known-limit text, so it is not new.

**Suggested follow-ups.** None blocking. Optionally one task bundling O-001, O-004, O-007 and O-008. Each is a one-line edit.

**Not checked.** The `[DEPLOY]` ACs, the theme JavaScript's network behavior, and the GNU grep/sed runs of the scan on Ubuntu. If the first CI run on Linux fails there, that is a floor issue and not a round-1 finding.

<!-- gate-round-end: opponent:1 -->
