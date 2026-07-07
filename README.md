# SDD Kit — spec-driven development, multi-project, multi-CLI

A portable setup for **spec-driven development** (SDD): every non-trivial change is
captured as a spec, planned, decomposed into checkable tasks, implemented in an
isolated git worktree, and blocked from shipping until **two adversarial gates**
pass. Works across all your projects from one install, and drives Claude Code,
Codex CLI, and Copilot CLI from the same canonical skill files.

> Spec → Plan → Tasks → Implement → Retro. Specs are the durable artifact; code is
> what falls out.

## Install

```bash
git clone <this-repo> ~/sdd-kit        # anywhere you like
cd ~/sdd-kit
scripts/setup.sh
```

`setup.sh` is idempotent (re-run it after every `git pull`). It:

1. Symlinks `~/.sdd` → the clone (everything references this stable path).
2. Bootstraps `registry.yml` from `registry.example.yml` — **edit it** to register
   your projects (absolute path + stack tags).
3. Bootstraps the **model policy** (`models.yml`) — on a terminal it runs the
   `configure-models.sh` wizard (Enter accepts the defaults; `--no-wizard` to
   skip prompts), then stamps each skill/agent with its tier's model + effort
   (see [Model tiering](#model-tiering-which-model-runs-each-phase)).
4. Symlinks each SDD skill and agent into every Claude home (`~/.claude`,
   `~/.claude_*`) — one link per item, your other skills are untouched.
5. Generates Codex (`~/.codex`) and Copilot (`~/.copilot`) adapters from the
   canonical skills, if those CLIs are installed (`--no-cli` to skip).
6. Runs `sdd-doctor.sh` to verify.

After install, `/sdd:onboard` researches every repo in `system-map.yml` and
writes its standing brief (`briefs/<repo>.md`) — setup prints a hint whenever
registered repos have no brief. Existing installs: add `onboard: implementation`
and `review: implementation` to your machine-local `models.yml` roles (new
installs get them from the example; `apply-models.sh` prints "role … unmapped"
until you do).

Per project, one-time: create `.specify/stack.yml` (the skills do this for you on
first `/sdd:specify` if it's missing):

```yaml
stacks: [javascript, aws]     # tags matching templates/stack-overlays/
base_branch: main             # optional; default dev
```

## The workflow

From inside any registered project (including its `<repo>.worktrees/*` checkouts):

| Step | Command | Output |
|---|---|---|
| 1. Capture intent | `/sdd:specify "<feature>"` | `.specify/specs/NNN-slug/spec.md` (via interview: goals REQ-###, success metrics MET-###, acceptance criteria AC-###) |
| 2. Design approach | `/sdd:plan` | `plan.md` — stack experts consulted, codebase explored |
| 3. Break into tasks | `/sdd:tasks` | `tasks.md` — commit-sized tasks, each with files + acceptance check + refs; validated by `sdd-analyze.sh` |
| 4. Execute | `/sdd:implement` | Code changes in a `spec/NNN-slug` worktree, checkboxes ticked (`spec-task.sh` — tick + evidence atomically), gates run |
| 5. Drive the PR home | `/sdd:review` | CI watched via `spec-ci.sh`, red builds triaged into `T###c*` tasks, reviewer feedback into `T###r*`, re-gate rule applied, merge in contract order, worktree torn down |
| 6. Learn | `/sdd:retro` | `notes/retro.md` + generalizable lessons filed into `knowledge/` |

Every spec directory also carries **`STATUS.md`** — the living handoff record
(phase, branch, worktree, PR, gate verdicts). Every tool reads it on entry and
updates it on exit, so a spec can move between Claude, Codex, Copilot, and
between sessions, without losing state.

### The two gates (both blocking, in order)

Before any PR:

1. **Opponent** (`agents/opponent.agent.md`) — steelmans why the implementation is
   *wrong*: untested inputs, races, regressions, misread requirements. Default
   verdict **CHALLENGED**; findings become `T###o*` follow-up tasks.
2. **Reality-check** (`agents/reality-check.agent.md`, or a project-local override)
   — demands observable evidence for every AC-###. Default verdict **NEEDS WORK**;
   gaps become `T###a…` follow-up tasks.

`spec-pr.sh` refuses to open a PR (exit 4) unless STATUS shows CLEARED + READY
(`--force` works only together with `--draft` — a non-draft PR can never skip
the gates), and on success writes `pr:` + `phase: review` into STATUS.md
itself. Neither gate grades its own work: on Claude they run as separate
subagents; on single-agent CLIs the adapter runs them as distinct review
passes. The gate loop is bounded: from round 3 the user arbitrates (waivers
are explicit sign-offs in the STATUS Decisions log, never softened verdicts).

Two conventions keep the loop honest end-to-end:

- **Evidence lines.** A task checkbox is only ticked together with an
  `*Evidence:*` line (the acceptance command + its key output). Gates re-run
  evidence instead of trusting it; `[x]` with no evidence counts as not done.
- **Clarification markers.** Unresolved decisions are written as
  `[NEEDS CLARIFICATION: <question>]`, never guessed; `sdd-analyze.sh` blocks
  tasking/implementation while any marker remains.

## Model tiering (which model runs each phase)

Not every phase deserves the same model. Design and adversarial judgment —
specify/plan/tasks, the opponent, the reality-check, the security review — get
the strongest reasoning models on high effort; rote implementation runs on a
mid-tier model that's faster and cheaper. The mapping is the **model policy**:

- **`models.yml`** (machine-local, gitignored — like the registry) defines
  **tiers** (a model + reasoning effort per CLI) and maps **roles** to tiers.
  Shipped defaults: `reasoning` = Claude `opus (xhigh)` / Codex `gpt-5.5 (xhigh)`
  / Copilot `claude-opus-4.8`; `implementation` = `sonnet (high)` / `gpt-5.4 (high)`
  / `claude-sonnet-4.5`. Roles: `specify` `plan` `tasks` `retro` `orchestrator`
  `opponent` `reality-check` `security-reviewer` → reasoning; `implement`
  `stack-expert` `test-engineer` `explore` → implementation. All of it is
  editable — add tiers (e.g. a cheap `recon` tier for exploration), remap roles,
  or delete `models.yml` to run everything on the session model. (`review` —
  the PR-babysitting phase — maps to `implementation` by default.)
- **`scripts/configure-models.sh`** is the wizard (runs on first `setup.sh`;
  re-run anytime). `scripts/model-policy.sh show` prints the current mapping;
  `check` validates it.
- **How it's applied per CLI** — each the strongest way that CLI allows:
  - *Claude Code:* `scripts/apply-models.sh` generates copies of every skill and
    agent under `build/` with `model:` + `effort:` stamped into the frontmatter,
    and `sync.sh` points the home symlinks there. `/sdd:plan` runs on the
    reasoning tier even in a sonnet session; stack experts dispatched by the
    orchestrator run on the implementation tier.
  - *Codex CLI:* skills can't pin models, so the kit writes one profile per tier
    (`~/.codex/sdd-<tier>.config.toml` → `codex --profile sdd-reasoning`), and
    each adapter's preamble tells the agent to steer the session to its phase's
    tier via `/model` or a relaunch.
  - *Copilot CLI:* each generated `sdd-<phase>` agent (and the gate persona
    copies) gets `model:` pinned in its frontmatter; effort is session-level, so
    the preamble suggests `--effort` when the session is set lower.

After editing `models.yml` by hand, re-run `scripts/setup.sh` (or
`apply-models.sh` + `sync.sh` + `build-adapters.sh`). `sdd-doctor.sh` flags a
stale or missing build, and validates the policy file.

## Multi-repo features (umbrella specs)

A team's feature rarely lives in one repo — web + mobile + big-screen clients,
several backend services, a separate infra repo. The kit handles that with
three pieces:

- **`system-map.yml`** (committed, team-shared — unlike the machine-local
  registry): what each repo *is* — role (`app|service|infra|design|library|external`),
  owning team, `depends_on`, and the **contracts** between repos (OpenAPI,
  event schemas) with their source repo. Query/validate via
  `scripts/system-map.sh {list,show,path,deps,consumers,contracts,check}`.
- **Umbrella specs** in the hub's `specs/NNN-slug/`: ONE spec for the feature
  (`new-spec.sh --multi --repos a,b,c "<title>"`), with `repos:` frontmatter,
  ACs tagged `[repo:<name>]`, and a **Repo matrix** in STATUS.md tracking
  branch/worktree/PR per repo. Tasks carry `[repo:<name>]` tags
  (`sdd-analyze.sh` enforces them), each executing in its own repo's worktree
  (`spec-worktree.sh --repo <name>`), and each repo ships its own PR
  (`spec-pr.sh --repo <name>`) — but the **gates run once, spec-wide**, over
  every repo's diff together, and block all the PRs.
- **Repo briefs** in `briefs/<name>.md`: standing per-repo context (what it
  owns, entry points, contracts, gotchas) seeded in bulk by **`/sdd:onboard`**
  (local checkouts via the registry; GitHub-only repos via the map's `remote:`
  field and a cached shallow clone), written by `/sdd:plan`'s per-repo
  exploration, and refreshed by `/sdd:retro` — so specs stop re-exploring ten
  repos from scratch. Each brief records the commit it described
  (`**Source:** <branch> @ <sha>`); `scripts/brief-status.sh` flags briefs
  ≥ 20 commits (configurable) behind as stale, surfaced by `sdd-doctor.sh`,
  `sdd-status.sh`, `setup.sh`, and a `/sdd:plan` warning. Refresh is always
  explicit: `/sdd:onboard --refresh [repo…]`.

Ordering is **contract-first** (see `knowledge/cross-repo-contracts.md`):
contract changes → infra → provider services → consumer apps, and the same
order for merge/deploy. Dependencies on *other teams'* repos never become
tasks — the spec records `[EXTERNAL: <team/repo> — <what> — needed-by <date>]`,
mirrored in STATUS blockers, and implementation stubs at the agreed contract.

Single-repo features are untouched by all of this — their specs stay in the
project repo exactly as before.

## Scripts

All in `scripts/` (stable path: `~/.sdd/scripts/`):

| Script | What it does |
|---|---|
| `setup.sh` | install / repair everything on this machine |
| `configure-models.sh` | wizard for the model policy (`models.yml`) — which model + effort runs each SDD role, per CLI |
| `model-policy.sh` | query/validate the policy: `get <role> <cli> <field>`, `show`, `check` |
| `apply-models.sh` | stamp the policy into generated skill/agent copies under `build/` (Claude homes link there) |
| `project-detect.sh` | cwd → registered project root (worktree-aware) |
| `system-map.sh <cmd>` | query/validate the team topology: `list`, `show`, `path`, `deps`, `consumers`, `contracts`, `check` |
| `brief-status.sh <cmd>` | deterministic repo-brief freshness: `list` (TSV per repo), `check` (exit 1 on missing/stale), `repo <name>`; `--threshold N` (default 20), `--fetch` to opt into network |
| `new-spec.sh "<title>"` | scaffold `.specify/specs/NNN-slug/` from templates; `--multi --repos a,b,c` scaffolds an umbrella spec in the hub `specs/` |
| `spec-worktree.sh <spec-dir>` | cut/reuse branch `spec/NNN-slug` + sibling worktree from the project's base branch; `--remove [--delete-branch]` tears it down post-merge; umbrella: `--repo <name>` / `--all-repos` |
| `spec-status.sh` | machine-side state mutations: `get`/`set`/`show` on STATUS.md frontmatter (enum-validated, bumps `updated:`); `--file spec.md` targets other artifacts |
| `spec-task.sh` | tick tasks deterministically: `list`, `show`, `start`, `done T### --evidence "…"` (tick + evidence one atomic edit — refuses evidence-less ticks), `undo` |
| `spec-run.sh <spec-dir> T### -- <cmd>` | run an acceptance check FOR REAL: executes the command, captures stdout+exit+hash into `notes/evidence.md`, and ticks the box from that run only on exit 0 — evidence becomes a record, not a typed claim (`--key` to pick the quoted line, `--no-tick` to capture only) |
| `sdd-analyze.sh <spec-dir>` | deterministic spec↔plan↔tasks lint: AC coverage (implementation tasks only — gate refs don't count), ref integrity, acceptance checks, evidence on `[x]` tasks, gates present, no unresolved `[NEEDS CLARIFICATION]` markers; umbrella: `[repo:]` tag integrity + `[EXTERNAL:]` mirroring |
| `spec-ac-coverage.sh <spec-dir>` | AC coverage at the CODE layer (gate-time): greps the repo's test files for each `AC-###`, fails any AC no test names — the deterministic floor beneath the reality-check gate (`--root` per repo, `--tests` for extra globs) |
| `spec-evidence.sh <spec-dir>` | evidence integrity (gate-time): every `[x]` box's `*Evidence:*` must trace to a real `notes/evidence.md` capture block or an on-disk artifact — catches fabricated pointers, missing screenshots, and manual/post-deploy ACs with no owner + check-back date |
| `spec-pr.sh <spec-dir>` | push + open PR; **refuses unless both gates passed** (`--force` only with `--draft`); writes `pr:` + `phase: review` back into STATUS; umbrella: `--repo <name>`, once per repo |
| `spec-ci.sh <cmd>` | the CI watcher: `check`/`watch`/`logs` — PR checks + review + mergeability via `gh`, aggregate written to STATUS `ci:`, distinct exit codes (0 green / 10 pending / 20 red / 30 changes-requested / 40 conflicts); umbrella-aware |
| `sdd-status.sh` | dashboard of every spec in every project + hub umbrella specs (worktree-aware; `--open`, `--phase`, `--project`, `--tsv` for machines) |
| `sync.sh` | verify/repair the per-item symlinks into Claude homes (`--check`); prunes stale links; `--remove` uninstalls them |
| `build-adapters.sh` | regenerate Codex/Copilot adapters from the skills |
| `sdd-doctor.sh` | validate the kit, home wiring, adapters, system map, and any project's `.specify/` layout (`--all`, `--hub-only`) |

(`lib.sh` is the shared parsing library the others source — fence-bound
frontmatter reads/writes, YAML lists in inline or block form, registry
entries with `~` expansion. All scripts honor `NO_COLOR` / non-TTY output.)

Deterministic checks run as scripts; model judgment is reserved for design and
adversarial review. That split is a design principle (constitution §10).

## What's in the box

```
sdd-kit/
├── constitution.md           # Cross-project engineering principles — edit to taste
├── registry.example.yml      # → registry.yml (machine-local, gitignored)
├── models.example.yml        # → models.yml (machine-local): model policy — which
│                             # model+effort runs each role; build/ holds the
│                             # stamped copies (generated, gitignored)
├── system-map.yml            # Team-shared repo topology + contracts (committed)
├── specs/                    # Umbrella specs — one dir per multi-repo feature
├── briefs/                   # Standing per-repo context — seeded by /sdd:onboard,
│                             # written by plan, refreshed by retro (Source: sha tracked)
├── skills/                   # CANONICAL skills: sdd-specify/plan/tasks/implement/
│                             # review/retro/onboard
├── agents/                   # Gates (opponent, reality-check), security-reviewer,
│                             # test-engineer, sdd-orchestrator, and 12 stack experts
│                             # (rust, javascript, python, aws, react, nextjs,
│                             # loopback4, expo-rn, bun-monorepo, aws-cdk-lambda-ts,
│                             # rust-aws-lambda, firebase-rtk-codegen)
├── templates/                # spec/plan/tasks/STATUS/ADR/brief/retro templates,
│                             # stack-routing.md (THE routing table), umbrella-guide.md
│   └── stack-overlays/       # per-stack conventions — one per expert above,
│                             # plus monorepo + troposphere (overlay-only)
├── knowledge/                # Cross-project lessons — grows via /sdd:retro
└── scripts/                  # everything in the table above
```

## Customizing

- **Add a stack**: write `templates/stack-overlays/<tag>.md` (+ optionally
  `agents/<tag>-expert.md`), add the tag to your project's `stack.yml`, and add
  one row to `templates/stack-routing.md` — the single routing table every
  skill and the orchestrator read. Re-run `setup.sh`.
- **Project-specific rules**: `<project>/.specify/constitution.md` extends the kit
  constitution with overrides only. A project can pin its own reality-check agent
  there (`Reality-check agent: <path>` — resolution order: constitution pin →
  project-local `.claude/agents/reality-check*.md` → kit default).
- **Editing skills/agents**: edit them **in this repo only** — then re-run
  `setup.sh` (or `apply-models.sh` + `build-adapters.sh`) so the model-stamped
  `build/` copies and the Codex/Copilot adapters pick the change up. Without a
  `models.yml` the homes link the canonical files directly and see edits
  instantly. Never edit a copy in a home directory — `sdd-doctor.sh` catches
  both drift and a stale build.
- **The feedback loop**: `/sdd:retro` files lessons into `knowledge/` and proposes
  overlay amendments — which `/sdd:plan` reads on the next spec. Commit those; that
  is how the kit gets smarter with every feature you ship.

## Multi-machine

The repo is the source of truth. On each machine: clone, `scripts/setup.sh`, edit
`registry.yml` for that machine's project paths. Pull + re-run `setup.sh` to update.
`knowledge/`, overlays, constitution, `system-map.yml`, umbrella `specs/`, `briefs/`,
and skill improvements travel through git; the registry never does. For a team,
that split is the whole model: fork the kit as the team's hub repo — topology,
umbrella specs, and lessons are shared; each member's `registry.yml` maps the
repo names to wherever they're checked out locally.

## Credits

The workflow follows the spec-kit school of spec-driven development
([github/spec-kit](https://github.com/github/spec-kit)), extended with adversarial
pre-ship gates, cross-tool STATUS handoff, worktree isolation, and a retro loop.
