---
tasks_for: 004-documentation-site-on-github-pages
status: in-progress  # draft | in-progress | complete
created: 2026-11-16
updated: 2026-11-16
---

# Tasks: Documentation site on GitHub Pages

> Dependency-ordered checklist. Each task is small enough to be a single commit
> and has an explicit acceptance check. Grammar: the
> [verification contract](../../../../../.sdd/templates/verification-contract.md).
> `plan §n` is `plan.md` in this directory; README line numbers are those of
> `origin/main` `b9814e6`.

## Setup

- [x] **T001** — Add the docs check's third-party asset scan
  - *Files:* `tests/docs-check.sh` (new), `tests/test-docs.sh` (new)
  - *Acceptance:* `docs-check.sh` exists with the plan §4.3 header, preamble, `SITE_HOST`, usage/exit contract, `--assets-only <dir>` and `scan_assets` (including its `shortcut:` comment); `check_docs` is not written yet. `test-docs.sh` adds the two asset-scan tests: one fixture site per FM-004 trigger exits 1 naming the file and match, a clean site holding the own-host canonical link and a `data:` CSS URL exits 0, and the FM-003 inputs exit 2. ShellCheck clean.
  - *Verify kind:* test
  - *Tests:* `tests/test-docs.sh::test_AC_009_asset_scan_reports_third_party_hosts`, `tests/test-docs.sh::test_AC_009_asset_scan_refuses_a_site_without_html`
  - *Verify:* `sh -c 'bash tests/run.sh docs && bash tests/shellcheck.sh'` → exit 0, "-- 2/2 passed"
  - *Reuse:* local
  - *Refs:* REQ-008, AC-009, FM-003, FM-004, plan §4.3, §7
  - *Evidence:* CAP-1-cEwLss verified by spec-gate accept; return sha256:1e1e610bca23a8ccf2efd9ce3de6f1c62d623345e69972e824509ecb010c3968

- [x] **T002** — Add the docs check's strict build, 404 and broken-link probe
  - *Files:* `tests/docs-check.sh`, `tests/test-docs.sh`
  - *Acceptance:* `check_docs` implements plan §4.3 steps 1–6 exactly: no `--clean`/`-c` anywhere, probe output captured with `2>&1` and ANSI-stripped before the name check, temp dir removed by `trap … EXIT`. `test-docs.sh` adds the `stub_zensical <mode>` helper and the six tests of plan §7 (`good`, `accepts-all`, `silent-fail`, `no-404`, no zensical on `PATH`, recorded args free of `--clean`/`-c`), each on the self-contained sandbox kit plan §7 describes. No test runs the real generator. ShellCheck clean.
  - *Verify kind:* test
  - *Tests:* `tests/test-docs.sh::test_AC_008_check_passes_when_strict_mode_names_the_broken_link`, `tests/test-docs.sh::test_AC_008_check_fails_when_strict_mode_accepts_a_broken_link`, `tests/test-docs.sh::test_AC_008_check_fails_when_the_failure_does_not_name_the_link`, `tests/test-docs.sh::test_AC_008_check_refuses_to_run_without_zensical`, `tests/test-docs.sh::test_AC_008_check_fails_without_a_404_page`, `tests/test-docs.sh::test_AC_008_check_never_cleans_the_kit_cache`
  - *Verify:* `sh -c 'bash tests/run.sh docs && bash tests/shellcheck.sh'` → exit 0, "-- 8/8 passed"
  - *Reuse:* local
  - *Refs:* REQ-007, AC-008, FM-001, FM-002, FM-007, INV-003, INV-004, plan §4.3, §7
  - *Evidence:* CAP-3-LlPFkp verified by spec-gate accept; return sha256:378a20ffc23001f30c6de07550c1a6c061e72330de76d3d01ec7a1f373bd132b

## Backend

- [x] **T003** — Move the README into eleven docs pages and add the site config
  - *Files:* `docs/index.md`, `docs/install.md`, `docs/workflow.md`, `docs/model-tiering.md`, `docs/skills-and-routing.md`, `docs/dispatch.md`, `docs/multi-repo.md`, `docs/scripts.md`, `docs/layout.md`, `docs/customizing.md`, `docs/verification.md` (all new), `zensical.toml` (new), `.gitignore`, `tests/test-docs.sh`
  - *Acceptance:* One move, kept in one commit because the nav needs every page. Each page holds exactly its plan §3 source range under move rules 1–5 plus the listed new prose; `README.md` is not touched yet. `zensical.toml` is plan §4.1 byte for byte. `.gitignore` gains a comment line and `site/`. `test-docs.sh` adds the nav test (nav ⇔ `docs/*.md` both ways, search not disabled, no `docs/*/*.md`).
  - *Verify kind:* test
  - *Tests:* `tests/test-docs.sh::test_AC_003_every_page_is_in_the_nav_and_search_stays_on`
  - *Verify:* `bash tests/run.sh docs` → exit 0, "-- 9/9 passed"
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-003, REQ-004, AC-003, FM-005, plan §3, §4.1, §7
  - *Evidence:* CAP-5-ya5f7a verified by spec-gate accept; return sha256:f9dbe19e2ebcdb7d2890208aff3c0fefa20372f2a22cb012f2c4b45d2231cf61

## API

> The workflow is the site's contract with GitHub — triggers, permissions,
> the deploy job (plan §4.2). The `API` checkpoint in `.specify/stack.yml`
> runs the full suite after this stage.

- [x] **T004** — Add the docs workflow and its permission tests
  - *Files:* `.github/workflows/docs.yml` (new), `tests/test-docs.sh`
  - *Acceptance:* `docs.yml` is plan §4.2 byte for byte, `deploy:` last. `test-docs.sh` adds the four tests of plan §7: both triggers and the deploy job's exact `if:`; standard runners, no `secrets.`, no `docs/CNAME`, `font = false` and no `repo_url`/`analytics`; write permissions only from `  deploy:` on, each exactly once; `ci.yml` free of `zensical`, `setup-python`, `pip`. `.github/workflows/ci.yml` unchanged. Least privilege per constitution §3.1 (spec CON-005).
  - *Verify kind:* test
  - *Tests:* `tests/test-docs.sh::test_AC_006_docs_build_on_pull_request_and_deploy_only_from_main`, `tests/test-docs.sh::test_AC_009_docs_need_no_secret_domain_or_tracker`, `tests/test-docs.sh::test_AC_010_only_the_deploy_job_can_write_pages`, `tests/test-docs.sh::test_AC_012_ci_suite_needs_no_docs_tooling`
  - *Verify:* `bash tests/run.sh docs` → exit 0, "-- 13/13 passed"
  - *Reuse:* local
  - *Refs:* REQ-002, REQ-006, REQ-008, AC-006, AC-009, AC-010, AC-012, INV-001, INV-003, plan §4.2, §5, §7
  - *Evidence:* CAP-10-EQoYxb verified by spec-gate accept; return sha256:eae12d016b9745322b7a7e530c9ac9b3cdc7a6d05dabc2edacbf4fd5662da94f

- [x] **T005** — Run the real docs check once against the moved pages
  - *Files:* `tests/docs-check.sh`
  - *Acceptance:* Runs `tests/docs-check.sh` without editing it; it writes only the ignored `site/` and `.cache/`. With Zensical 0.1.1 from `uv`, the strict build of the real pages passes, `site/404.html` exists, the asset scan is clean, and the broken-link probe is rejected and named. A failure here is fixed in the page or config it names (T003's files), never by weakening the check.
  - *Verify kind:* assertion
  - *Tests:* `tests/docs-check.sh::check_docs`
  - *Verify:* `uv run --python 3.13 --no-project --with zensical==0.1.1 -- bash tests/docs-check.sh` → exit 0, "docs-check: ok"
  - *Reuse:* never
  - *Refs:* REQ-007, REQ-008, AC-008, AC-009, plan §5, §7
  - *Evidence:* CAP-11-ffWxUu verified by spec-gate accept; return sha256:b1fd69a4b9ce73a4b82dbb77d6296b4763bdf602a0bf2ee94621e0a6d52e85b8

## Docs

- [x] **T006** [P] — Point the usage-limit docs test at the dispatch page
  - *Files:* `tests/test-usage-limits.sh`
  - *Acceptance:* Line 1067 reads `docs/dispatch.md` (plan §4.5); every assertion and expected string is unchanged; the suite passes while `README.md` still holds the full text, so the pass comes from the page.
  - *Verify kind:* test
  - *Tests:* `tests/test-usage-limits.sh::test_AC_010_documents_exact_limit_policy_keys_and_recovery_workflows`
  - *Verify:* `sh -c 'bash tests/run.sh usage-limits && bash tests/shellcheck.sh'` → exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-011, FM-008, plan §4.5
  - *Evidence:* CAP-16-1EVJUJ verified by spec-gate accept; return sha256:ce80c14a61592c9034278268ecbbe4724b3043a6b82efc408a143128922dfb8e

- [x] **T007** [P] — Point the adapter docs tests at the moved pages
  - *Files:* `tests/test-build-adapters.sh`
  - *Acceptance:* Lines 135, 143 and 340 changed exactly as plan §4.5 (the stale-claim loop also covers every `docs/*.md`; the gate-name check reads `docs/workflow.md`; the skill-stamp sentence reads `docs/model-tiering.md`); assertions and messages otherwise unchanged.
  - *Verify kind:* test
  - *Tests:* `tests/test-build-adapters.sh::test_stale_single_agent_claims_are_gone`, `tests/test-build-adapters.sh::test_stamped_skills_open_with_the_turn_note_and_nothing_else_does`
  - *Verify:* `sh -c 'bash tests/run.sh build-adapters && bash tests/shellcheck.sh'` → exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-011, FM-008, plan §4.5
  - *Evidence:* CAP-17-80tiOn verified by spec-gate accept; return sha256:843e52df6b27edaee2e1305dba46c560bdc5f25b84897cd50ffd71194708ad8b

- [x] **T008** [P] — Point the gate-contract docs tests at the verification page
  - *Files:* `tests/test-gate-contracts.sh`
  - *Acceptance:* Lines 3062, 3073, 3101–3102, 3127, 3136, 3155 and 3159 changed exactly as plan §4.5, including the `SC2086` disable comment on the two-file document; the documented bash block is still found and every line of it still runs; assertions otherwise unchanged.
  - *Verify kind:* test
  - *Tests:* `tests/test-gate-contracts.sh::test_instruction_contracts`
  - *Verify:* `sh -c 'bash tests/run.sh gate-contracts && bash tests/shellcheck.sh'` → exit 0
  - *Reuse:* local
  - *Refs:* REQ-009, AC-011, FM-008, plan §4.5
  - *Evidence:* CAP-18-etIv3G verified by spec-gate accept; return sha256:cc2966c370c1717a0c4940bc5eb2e7a85a16081e0b2b1fc93d42cae444f54ee9

- [x] **T009** — Rewrite the README as the entry point and retarget its pointers
  - *Files:* `README.md`, `scripts/sdd-doctor.sh`, `registry.example.yml`, `tests/test-docs.sh`
  - *Acceptance:* `README.md` is exactly the plan §4.4 template (ten page bullets, no `…/index/` URL). `sdd-doctor.sh:347` says `(docs: \"Ponytail\")` and `registry.example.yml:31` says `see the docs, Install → "Multi-machine"` (plan §2). `test-docs.sh` adds the heading test (20 headings, fixed-string compare) and the README test (≤ 150 lines, site URL, `## Install`, `## Quick start`, line 1, every site URL maps to a `docs/<x>.md`). The three retargeted suites still pass after the trim. Nothing under `setup.sh`, `sync.sh`, `plugin/` or the adapters reads `docs/` (spec CON-008).
  - *Verify kind:* test
  - *Tests:* `tests/test-docs.sh::test_AC_002_every_readme_heading_has_a_home`, `tests/test-docs.sh::test_AC_005_readme_is_a_short_entry_point`
  - *Verify:* `sh -c 'bash tests/run.sh docs && bash tests/run.sh usage-limits && bash tests/run.sh build-adapters && bash tests/run.sh gate-contracts && bash tests/shellcheck.sh'` → exit 0, "-- 15/15 passed" for `test-docs.sh`
  - *Reuse:* local
  - *Refs:* REQ-003, REQ-005, REQ-009, AC-002, AC-005, FM-009, INV-002, plan §2, §4.4, §7
  - *Evidence:* CAP-20-FkBxpI verified by spec-gate accept; return sha256:e4e5f2190b2172fc4ac0163285eb63d698a77c86773850ceabac8051d4ea27f1

- [x] **T010** — Prove no README line was dropped in the move
  - *Files:* `.specify/specs/004-documentation-site-on-github-pages/notes/readme-coverage.sh` (new), `.specify/specs/004-documentation-site-on-github-pages/notes/readme-coverage-exceptions.txt` (new)
  - *Acceptance:* The script implements plan §4.6 (fence-aware `#` stripping, merge-base baseline, exit 2 when the baseline cannot be read). The exceptions file lists exactly lines 644, 662, 663, 664 and 665, each with its rule-4 reason. Any other missing line is fixed in the page that should hold it, not added as an exception.
  - *Verify kind:* assertion
  - *Tests:* `.specify/specs/004-documentation-site-on-github-pages/notes/readme-coverage.sh::readme_coverage`
  - *Verify:* `bash .specify/specs/004-documentation-site-on-github-pages/notes/readme-coverage.sh` → exit 0, "5 exceptions, 0 missing"
  - *Reuse:* local
  - *Refs:* REQ-003, AC-002, FM-006, plan §3, §4.6
  - *Evidence:* CAP-22-oMd3Yz verified by spec-gate accept; return sha256:4f072b08afa574120f75e72da8771c5317617c2ed40cf827b0fe26ed6799fecd

## Reality Check (pre-ship gate)

> Two adversarial gates, both blocking, run in order. Neither grades its own
> work: on Claude each is delegated via the Agent tool; on Codex/Copilot the
> agent adopts the persona as a distinct review pass.

- [x] **T011** — Opponent review: steelman why this implementation is wrong
  - *Agent:* `~/.sdd/agents/opponent.agent.md`
  - *Inputs:* the diff on this branch, `spec.md`, `plan.md`, every `[x]` task
  - *Acceptance:* agent returns **CLEARED** (not CHALLENGED); findings written to `notes/opponent.md`
  - *Refs:* REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, REQ-007, REQ-008, REQ-009, AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008, AC-009, AC-010, AC-011, AC-012
  - *On CHALLENGED:* open follow-up tasks here (T011o1, T011o2, …) for each defect; fix and re-run before T012
  - *Evidence:* `spec-gate.sh round opponent round 1 → CLEARED, 0 blocking, 8 minor (notes/opponent.md)` (2026-11-16)

- [x] **T012** — Reality-check the implemented spec end-to-end
  - *Agent:* `~/.sdd/agents/reality-check.agent.md`
  - *Inputs:* every prior `[x]` task, `spec.md`, `plan.md`, `notes/opponent.md`
  - *Acceptance:* agent returns **READY** (not NEEDS WORK / FAILED); every AC-### mapped to concrete evidence in `notes/reality-check.md`; the three `[DEPLOY]` ACs (AC-001, AC-004, AC-007) recorded as deferred to T014 with owner and check-back date in STATUS
  - *Refs:* AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008, AC-009, AC-010, AC-011, AC-012
  - *On NEEDS WORK:* open follow-up tasks here (T012a1, T012a2, …); do not proceed to Ship until they're `[x]` and the gate is re-run
  - *Evidence:* `spec-gate.sh round reality-check round 1 → READY; AC-001/004/007 deferred to T014 (owner @Rehan712), notes/reality-check.md` (2026-11-16)

## Ship

> After T013, the PR lifecycle — CI triage (`T013c*`), review feedback
> (`T013r*`), rebases, the merge, worktree teardown — belongs to **/sdd:review**.

- [ ] **T013** — Open PR to `main` referencing spec.md and plan.md
  - *Files:* (none — branch + PR)
  - *Acceptance:* `~/.sdd/scripts/spec-pr.sh <spec-dir>` prints the PR URL; both gate verdicts in the PR body; the PR's own `docs` workflow run builds and checks green without deploying; the body asks the owner to enable Pages (Settings → Pages → Source: GitHub Actions) before merging

- [ ] **T014** — Roll out and collect the deploy evidence (after /sdd:review reports the PR merged)
  - *Files:* `.specify/specs/004-documentation-site-on-github-pages/notes/deploy-evidence.md` (new), four screenshots and the network log under `notes/`
  - *Acceptance:* the push run on `main` deploys; `notes/deploy-evidence.md` holds the three `curl` outputs (AC-001) and the `gh run list --workflow docs.yml --branch main --limit 1` output (AC-007); four 375px screenshots (landing and one guide page, light and dark) and the landing page's network log listing only the site's own host are committed (AC-004); a third-party request in that log stops here and goes to the owner; STATUS phase `shipped`, MET-001–004 owner and the 14-day check-back date in Next action
  - *Verify kind:* manual
  - *Tests:* deploy-evidence
  - *Verify:* `manual: deploy-evidence — record the live site's curl statuses, the deploy run, the four screenshots and the network log in notes/, with observer, UTC and artifact digest`
  - *Refs:* REQ-002, REQ-004, REQ-006, REQ-008, AC-001, AC-004, AC-007, plan §8

- [ ] **T015** — Retro: harvest lessons into the hub
  - *Acceptance:* `/sdd:retro` run; `notes/retro.md` written with the root-cause split; STATUS `retro:` set to `done`
  - *Refs:* `notes/opponent.md`, `notes/reality-check.md`, `notes/plan-review.md`, STATUS decisions log

---

*Workflow:* Once a task is done, tick its checkbox. Run `/sdd:implement` to execute the next pending task. When all tasks are `[x]`, set frontmatter `status: complete`.
