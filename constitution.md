# Constitution

Cross-project principles that govern all work across the projects in `~/.sdd/registry.yml`. Per-project constitutions extend this one with overrides; they do not replace it.

> Read this whenever starting a new spec, plan, or implementation pass. When two principles conflict for a specific case, prefer correctness > security > clarity > velocity.

## 1. Workflow

1. **Spec before code.** Every non-trivial change starts with a `spec.md`. Trivial = typos, single-line bug fixes with obvious scope, dependency bumps.
2. **One spec per feature.** If a spec grows past ~400 lines or covers multiple user stories that ship separately, split it.
3. **Plan after spec.** `plan.md` answers *how*, not *what*. If the plan reveals the spec is wrong, edit the spec first.
4. **Tasks before commits.** `tasks.md` is the source of truth for in-progress work. Each task has a file path and an acceptance check.
5. **Specs are versioned with code.** Specs live in the project repo, not the hub. They travel with the feature. *Exception:* a feature spanning multiple repos gets ONE **umbrella spec** in the hub's `specs/` (the hub is the team-shared repo, so the spec still travels through git) — never N disconnected per-repo specs for one feature. Each declared repo still carries its own `spec/NNN-slug` branch, worktree, and PR.
6. **Ship closes with a retro.** `/sdd:retro` harvests what the gates caught into the hub `knowledge/` and stack overlays. A lesson that stays in one spec's notes is a lesson the next spec pays for again.
7. **Specs declare success metrics.** Every spec names MET-### outcomes with a measurement source (or an explicit "n/a because ..."). If we can't say how we'd know it worked, we don't know why we're building it.
8. **Cross-repo features are contract-first.** The topology of repos and the contracts between them live in the hub's `system-map.yml`. In an umbrella spec, contract changes land in the contract's source repo before any consumer builds against them; merge/deploy order is providers before consumers, infra first. Consumers regenerate from the contract artifact — never import another repo's source or hand-copy its shapes.
9. **Other teams' repos are dependencies, not workspaces.** A repo with role `external` in the system map never receives tasks. The spec records the need as `[EXTERNAL: <team/repo> — <what> — needed-by <date>]`, mirrored in STATUS blockers; implementation stubs at the agreed contract version, and the reality-check gate accepts only real integration evidence or an explicit recorded "blocked on external" — never a stub shipping silently as if integrated.

## 2. Code quality

1. **Edit before creating.** Prefer editing existing files to creating new ones. Search for existing utilities before writing a new one.
2. **No premature abstraction.** Three similar lines is better than one abstract helper. Wait for the fourth.
3. **No defensive code for impossible cases.** Trust internal callers; validate at system boundaries only.
4. **Comments explain WHY, not WHAT.** Well-named identifiers handle the *what*. Comments earn their place by explaining hidden constraints, non-obvious invariants, or specific workarounds.
5. **No dead code paths.** Remove unused exports, parameters, and branches. `_var` is a smell, not a fix.

## 3. Security baseline

1. **Least privilege for AWS IAM.** No `*` actions or resources in production policies. Scope to specific ARNs and actions.
2. **No secrets in code, ever.** Use AWS Secrets Manager, SSM Parameter Store, or `.env.local` (gitignored). Pre-commit hooks should reject anything matching common secret patterns.
3. **All inputs at boundaries are validated.** API handlers, Lambda events, webhook payloads, user-supplied form data — all must be schema-validated (zod, pydantic, serde) before reaching business logic.
4. **PII at rest is encrypted.** RDS/Dynamo at-rest encryption is non-negotiable. S3 buckets default to SSE-S3 minimum; SSE-KMS for anything sensitive.
5. **CORS is allow-listed.** No `Access-Control-Allow-Origin: *` in production.
6. **Authentication is centralized.** One auth path per app (Cognito, Firebase Auth, NextAuth). Don't reimplement.

## 4. AWS conventions *(for projects that deploy to AWS)*

1. **Resources are tagged — THE canonical set** (every other file defers here):
   `Project`, `Environment` (`dev`/`staging`/`prod`), `Owner`, `CostCenter`
   (where applicable), `ManagedBy` (`cdk`/`terraform`/`manual` — `manual` never
   in production).
2. **Environment isolation.** `dev`, `staging`, `prod` live in separate AWS accounts or at minimum separate VPCs. No shared resources except read-only artifact buckets.
3. **CDK over raw CloudFormation.** Infrastructure is TypeScript or Python CDK. SAM and Terraform are case-by-case. Exception: a repo already standardized on troposphere (see that overlay) stays internally consistent — don't mix generators within a repo.
4. **Lambdas are small and single-purpose.** Cold start matters. Bundle with esbuild (TS) or cargo-lambda (Rust). Avoid `aws-sdk` v2 in new code — use v3 modular clients.
5. **Logs go to CloudWatch with structured JSON.** No `console.log("user " + id)`. Use a logger that emits `{level, msg, requestId, ...}`.

## 5. Frontend

1. **Accessibility is not a stretch goal.** Semantic HTML, alt text, focus management, keyboard navigation. WCAG 2.1 AA as the baseline.
2. **i18n from day 1.** Wrap user-facing strings in the project's i18n function even if there's only one locale today. Hard-coded English is a defect.
3. **Mobile-first.** Design and test at 375px wide first, scale up.
4. **No unbounded re-renders.** Memoize where the dep graph is non-trivial. Profile when in doubt.
5. **Server state ≠ client state.** RTK Query, React Query, or SWR for server state. Component state for component state. Don't put server data in Redux directly.

## 6. Mobile (React Native / Expo)

1. **Expo SDK over bare workflow** unless a specific native module forces the migration.
2. **EAS Build for releases.** Local Xcode/Android Studio builds are for development only.
3. **Test on real devices before submitting.** Simulator-only validation has produced enough incidents.
4. **Deep-link schemes are owned end-to-end.** Document the scheme, register universal links, test cold/warm starts.

## 7. Git / PR discipline

1. **Conventional commits.** `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`. Scope when useful: `feat(auth): ...`.
2. **One concern per commit.** A commit that fixes a bug and renames a function is two commits.
3. **PR descriptions reference the spec.** Link to `.specify/specs/NNN-slug/spec.md` in the PR body.
4. **No `--no-verify`, no force-push to main**, no rewriting published history without explicit team consensus.
5. **One worktree per spec.** Implementation runs on branch `spec/NNN-slug`, cut from the project's **base branch** (`.specify/stack.yml` `base_branch:`, default `dev`) into a sibling worktree via `scripts/spec-worktree.sh`. The base checkout stays clean; the PR (via `scripts/spec-pr.sh`) merges the branch back. Spec docs are authored/committed on the base branch before the branch is cut. After the PR opens, `/sdd:review` (driven by `scripts/spec-ci.sh`) owns the review phase — CI triage, reviewer feedback, the re-gate rule for post-PR commits, contract-order merge, and worktree teardown (`spec-worktree.sh --remove`). A gate verdict is stale the moment a behavioral commit lands after it.
6. **One task, one commit.** In orchestrated (`--all`) runs, each passing task is committed individually on the spec branch (never pushed) — per-task provenance is what makes gate review and rollback cheap. Single-task runs propose the commit and wait for the user.

## 8. Testing

1. **Tests cover behavior, not implementation.** A passing test should survive a refactor that doesn't change behavior.
2. **Integration > unit** for code that crosses a network or process boundary. Don't mock the database in tests that exist to catch migration drift.
3. **One assertion per concept.** A test with 14 assertions is six tests in a trench coat.
4. **Tests for bug fixes are non-optional.** If a bug shipped, a test should exist that would have caught it.
5. **Tests name the AC they prove.** The test that verifies `AC-###` carries that id in its name/description, so coverage is checkable at the code layer, not just on paper — `scripts/spec-ac-coverage.sh` fails any AC no test names. A green suite that never names an AC doesn't cover it.

## 9. Documentation

1. **Code is the source of truth for behavior; docs are the source of truth for intent.**
2. **READMEs answer: what is this, how do I run it, how do I deploy it.** Three sections, in that order.
3. **ADRs for decisions that are hard to reverse.** Database choice, auth provider, multi-region strategy. Use `templates/adr-template.md`.
4. **Keep docs near the code they describe.** Cross-project lessons go in this hub's `knowledge/`; project-specific docs go in the project repo.

## 10. AI assistance

1. **Prefer skills + subagents over inline prompting** for repeatable workflows.
2. **Specs are the durable artifact across sessions.** Conversations end; spec.md persists. **`STATUS.md` is the spec's living memory** — every tool (Claude, Codex, Copilot) reads it on entry and updates it on exit, so a spec can be handed between tools and sessions without losing state.
3. **Plan mode before implementation** for any change touching more than one file.
4. **Stack-specific subagents** handle stack-specific implementation. The generalist Claude routes; the specialist executes.
5. **Two adversarial gates before ship, both blocking.** The **opponent** steelmans why the implementation is wrong; the **reality-check** verifies every AC-### has evidence. Each defaults to its adversarial verdict and must argue itself open. On Claude they are separate subagents; on single-agent CLIs they run as distinct review passes against the same persona file. Neither grades its own work leniently.
6. **Deterministic checks and state changes run as scripts, not model judgment.** AC coverage, ref integrity, gate presence, drift between skill copies — `sdd-analyze.sh`, `sync.sh --check`, `sdd-doctor.sh` decide these; CI/PR state is `spec-ci.sh`; STATUS/task mutations go through `spec-status.sh` and `spec-task.sh` (enum-validated, and a task tick is atomic with its evidence line) rather than a model hand-editing frontmatter. Cheaply, reproducibly. Model judgment is reserved for what actually needs it (design, adversarial review).
7. **The hub is canonical for skills and agents.** every SDD skill and agent is symlinked from each Claude home into `~/.sdd` — directly, or via the `build/` copies that `apply-models.sh` generates from the canonical files when a model policy (`models.yml`) is configured; editing the kit is publishing (re-run `apply-models.sh` when a policy is active). Never replace one of those symlinks with a real copy, and never edit `build/` by hand — `~/.sdd/scripts/sync.sh --check` and `sdd-doctor.sh` catch it, `sync.sh`/`apply-models.sh` repair it.
8. **Evidence, not claims.** A task checkbox is ticked only together with an `*Evidence:*` line quoting the acceptance command and its key output. For any check the tooling can run, that line is produced by `scripts/spec-run.sh` executing the command and capturing its real output (+exit +hash) into `notes/evidence.md` — a record of a run, not a string a model typed. `scripts/spec-evidence.sh` checks the tie at gate time — every ticked box's evidence must resolve to a real capture block or an on-disk artifact, so a fabricated pointer or an imaginary screenshot can't pass. Gates re-run evidence rather than trust it; a `[x]` with no evidence is treated as not done.
9. **Unknowns are marked, never guessed.** An unresolved decision is written as `[NEEDS CLARIFICATION: <question>]` in the artifact where the answer belongs. `sdd-analyze.sh` blocks tasking/implementation while any marker remains — inventing an answer to get past the gate defeats the workflow.

---

*Last updated: 2026-07-04.*
