---
spec_id: 004-documentation-site-on-github-pages
title: Documentation site on GitHub Pages
status: implementing  # draft | accepted | implementing | shipped | rejected
verification_contract: 1
created: 2026-11-16
updated: 2026-11-16
owners: [Rehan712]
project: sdd-kit-public
---

# Documentation site on GitHub Pages

> The kit's whole manual is one 761-line `README.md`. This spec splits it into a
> navigable, searchable documentation site published free on GitHub Pages, and
> shrinks the README to an entry point — for people evaluating or using the kit.

This spec uses the [version 1 verification contract](verification-contract.md):
the plan defines failure modes, invariants and test families; tasks bind them
when decomposed. The project's nonempty `gate_checks:` list supplies required
suite/static verification independently of optional stage checkpoints.

## 1. Problem

Everything a user needs — install, the workflow, the two gates, model tiering,
umbrella specs, the script reference, customizing — lives in a single
`README.md` of 761 lines (9 `##` sections, 11 `###` subsections). On GitHub that
is one long scroll with no sidebar and no search of its own.

Concrete example: someone whose run stopped on a provider limit wants "When a
provider hits its usage limit". That subsection starts at README line 472, under
"Model tiering", a heading that does not suggest it. They cannot link a
colleague to a page about it, only to an anchor inside the scroll.

**REQ-001:** A reader looking for one topic of the kit has to find it inside a
single 761-line page; there is no per-topic page, navigation, or search.

## 2. Goals

- **REQ-002:** A public documentation site for the kit is served by GitHub Pages
  at the repository's default project URL, `https://rehan712.github.io/sdd-kit/`.
- **REQ-003:** The site is a user guide built from the README's existing
  content: a landing page plus one page per topic. Every one of the README's 20
  current headings (listed in §9) has a home on the site or in the trimmed
  README — nothing is dropped.
- **REQ-004:** The site has sidebar navigation covering every page, full-text
  search, a layout that works at 375px width, and light/dark colour schemes.
- **REQ-005:** `README.md` shrinks to an entry point — what the kit is, how to
  install it, a quick start, and a link to the site. The docs pages are the only
  copy of the detail, so the two cannot drift.
- **REQ-006:** Publishing is automatic. A merge to `main` updates the live site
  with no manual step; a pull request builds the site without deploying it.
- **REQ-007:** A broken internal link or anchor fails the pull-request build and
  names the file and the link.
- **REQ-008:** The site costs nothing to build, host, or run: no paid plan,
  service, domain, or third-party account.
- **REQ-009:** Every existing test that pins README text to script behaviour
  keeps its assertion, pointed at whichever file now carries that text.

## 3. Non-goals

- Reference pages for skills, agents, templates, knowledge lessons, or the
  constitution. The guide links to those files on GitHub.
- New prose, tutorials, or a blog. The only new writing is the landing page and
  the glue a split needs (page intros, cross-links).
- Versioned docs (per-release sites). One site, tracking `main`.
- A custom domain — it costs money and REQ-008 forbids it.
- Analytics or any visitor tracking.
- Translations. One locale, English (see CON-007).
- Preview deployments for pull requests; the PR build is the check.
- Generated reference from the scripts' `--help` output.
- Any change to what the kit's scripts, skills, or agents do.

## 4. Success metrics

No analytics (owner decision), so these are structural proxies, checked 14 days
after the first deploy.

- **MET-001:** The site is up — `curl -s -o /dev/null -w '%{http_code}'
  https://rehan712.github.io/sdd-kit/` prints `200`.
- **MET-002:** The docs stay deployable — the latest docs workflow run on `main`
  is green: `gh run list --workflow docs.yml --branch main --limit 1`.
- **MET-003:** The README stayed an entry point — `wc -l README.md` ≤ 150
  (from 761).
- **MET-004:** Cost is $0 — the account's GitHub billing page shows no charge
  for Pages or Actions on this repository.
- Reader traffic: n/a, because measuring it needs a tracker, which is a non-goal.

## 5. User stories

### As someone evaluating the kit

- I can open one URL and see what the kit is and how to install it, so I can
  decide whether to try it without reading 761 lines.
- I can read it on a phone, in light or dark mode.
- If I follow a stale link, I get a 404 page that still has the site navigation.

### As a kit user

- I can search for a term ("usage limit", "umbrella") and land on the page that
  covers it.
- I can send a colleague a link to one topic.

### As a contributor

- I can edit a markdown file under `docs/` and see it live after merge, with
  nothing to run by hand.
- If my change breaks a link, the pull request fails and tells me which file and
  which link, before anyone reviews it.
- I can still run `bash tests/run.sh` with only bash installed.

### As the maintainer

- A failed docs build on `main` does not take the site down: the last deployed
  version keeps serving (GitHub Pages behaviour, not separately tested).
- If Pages has not been enabled on the repository, the deploy job fails visibly
  rather than passing with nothing published.

## 6. Acceptance criteria

- [ ] **AC-001** `[DEPLOY]` (REQ-002): `curl -sI https://rehan712.github.io/sdd-kit/`
  returns `200`, the page body contains `SDD Kit`, and
  `curl -sI https://rehan712.github.io/sdd-kit/no-such-page/` returns `404`.
  Evidence: the three outputs committed to `notes/deploy-evidence.md`.
- [ ] **AC-002** (REQ-003): each of the 20 headings in §9 appears as a heading in
  `docs/**/*.md` or in the trimmed `README.md`. Verified by a test in `tests/`
  named `AC-002`, run by `bash tests/run.sh`.
- [ ] **AC-003** (REQ-004): every markdown page under `docs/` is listed in the
  site navigation, and search is enabled in the site config. Verified by a test
  named `AC-003` that compares the files under `docs/` with the nav entries.
- [ ] **AC-004** `[DEPLOY]` (REQ-004, REQ-008): at a 375px-wide viewport the
  landing page and one guide page show no horizontal scrollbar and the
  navigation opens; both render in light and dark; and the browser's network log
  for the landing page lists requests to the site's own host only. Evidence:
  four screenshots and the network log committed under `notes/`.
- [ ] **AC-005** (REQ-005): `wc -l README.md` ≤ 150; the README contains the
  site URL and sections covering what the kit is, install, and quick start.
  Verified by a test named `AC-005`.
- [ ] **AC-006** (REQ-006): the docs workflow builds on `pull_request` and
  deploys only on a push to `main`. Verified by a test named `AC-006` that reads
  the workflow file for both triggers and for the deploy job's `main`-only
  condition.
- [ ] **AC-007** `[DEPLOY]` (REQ-006): after the merge, the docs workflow run on
  `main` succeeds with a Pages deployment. Evidence: the output of
  `gh run list --workflow docs.yml --branch main --limit 1` committed to
  `notes/deploy-evidence.md`.
- [ ] **AC-008** (REQ-007): the docs check — the one command the pull-request
  build runs — exits non-zero when a page links to a page that does not exist,
  and its output names the file and the link. Verified by tests named `AC-008`
  (the check's logic, against a stub generator) and by one captured run of the
  real check, which builds the real docs and then a copy carrying one broken
  link.
- [ ] **AC-009** (REQ-008): the workflow uses only GitHub-hosted standard
  runners and no secret other than the default `GITHUB_TOKEN`; no `CNAME` file
  exists; the built pages reference no asset on a third-party host. Verified by
  a test named `AC-009` over the workflow file and the site config, and by the
  docs check's scan of the built HTML and CSS, which the pull-request build runs.
  (Requests made by the theme's JavaScript are covered by AC-004's network log.)
- [ ] **AC-010** (CON-005): the workflow's default permission is
  `contents: read`; `pages: write` and `id-token: write` are granted to the
  deploy job only. Verified by a test named `AC-010`.
- [ ] **AC-011** (REQ-009): `bash tests/run.sh` and `bash tests/shellcheck.sh`
  exit 0, and no `assert_contains`, `assert_not_contains`, or
  `gate_documentation_check` line that reads `README.md` today (CON-004) is
  removed without a matching line asserting the same text on the file that now
  carries it. Verified by the two commands and by
  `git diff main -- tests/` in the gate review.
- [ ] **AC-012** (CON-003): `.github/workflows/ci.yml` is unchanged, and
  `bash tests/run.sh` passes on a machine with no Python docs tooling installed.
  Verified by `git diff --exit-code main -- .github/workflows/ci.yml` and the
  existing `tests` and `tests-bash32` CI jobs.

## 7. Constraints

- **CON-001:** $0. The repository is public on a GitHub Free account, where
  Pages hosting and Actions minutes on standard runners are free. Nothing in
  this spec may require a paid plan, a purchased domain, or an outside account.
- **CON-002:** GitHub Pages' published limits apply: a site of at most 1 GB and
  a soft 100 GB/month bandwidth limit. A markdown guide is far below both.
- **CON-003:** The generator is Zensical, pinned to exactly 0.1.1 (owner
  decision, 2026-11-16). It replaces the first choice, Material for MkDocs,
  which reaches end of life on May 5, 2027; Zensical is its authors' successor.
  Python exists only inside the docs workflow and in a contributor's optional
  local run of the docs check. The kit itself stays bash + markdown: installing
  it and running `tests/run.sh` need no Python, and the bash 3.2 floor is
  untouched.
- **CON-004:** Tests read README text today and must follow it (REQ-009):
  `tests/test-usage-limits.sh` (policy keys), `tests/test-build-adapters.sh`
  (stale-claim checks, the generated gate names, the skill-stamp sentence), and
  `tests/test-gate-contracts.sh` (`gate_documentation_check` against the README,
  the `gate_checks`/`checkpoints` wording, `spec-gate.sh accept`, and the bash
  block extracted from "Versioned verification workflow").
- **CON-005:** Constitution §3.1 (least privilege) applies to the workflow's
  token permissions.
- **CON-006:** Enabling Pages (Settings → Pages → Source: GitHub Actions) is a
  one-time action by the repository owner. A merge cannot do it, and the first
  deploy fails until it is done.
- **CON-007:** Constitution §5.2 asks for i18n from day one. It is written for
  app UI strings wrapped in an i18n function; prose docs have none. This spec
  ships one locale and sets the site language explicitly, so a second locale
  later is configuration, not a rewrite.
- **CON-008:** The site's sources are plain markdown under `docs/` in this
  repository (constitution §9.4). The kit's install surface — `setup.sh`,
  `sync.sh`, the plugin installer, the generated adapters — must not link, copy,
  or read `docs/` or the site config.

## 8. Open questions

None open.

- [x] Generator support status — resolved 2026-11-16: Material for MkDocs ends
  May 5, 2027, so the owner chose Zensical (CON-003).
- [x] (@Rehan712) Defaults accepted 2026-11-16: the default `github.io` URL;
  deploy on every merge to `main`; a 150-line README ceiling; English only; no
  pull-request previews; no third-party fonts.

## 9. References

- GitHub Pages limits and availability:
  <https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits>
- Material for MkDocs end of life (release 9.8.1 notes):
  <https://github.com/squidfunk/mkdocs-material/releases>
- Zensical documentation: <https://zensical.org/docs/>
- Constitution §3.1, §5.1–5.3, §9.2, §9.4.
- Existing CI: `.github/workflows/ci.yml`.

The 20 README headings that REQ-003 and AC-002 account for:

| `##` section | `###` subsections |
|---|---|
| Install | Install as a plugin |
| The workflow | The two gates (both blocking, in order) |
| Model tiering (which model runs each phase) | Style guides · Official skills first · Project skills and agents (per-project routing) · Ponytail (companion — v5) · Cross-CLI dispatch (different providers per phase) · Graph and loop (control flow lives in scripts) · When a provider hits its usage limit |
| Multi-repo features (umbrella specs) | — |
| Scripts | Testing the kit itself |
| What's in the box | — |
| Customizing | — |
| Multi-machine | — |
| Credits | Versioned verification workflow |

---

*Workflow:* Once this spec is accepted, run `/sdd:plan` to produce `plan.md` in this same directory.
