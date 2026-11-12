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
   If `~/.sdd` already points at another live clone it stops instead of
   silently switching your install — pass `--relink` to move it here.
2. Bootstraps `registry.yml` from `registry.example.yml` — **edit it** to register
   your projects (absolute path + stack tags).
3. Bootstraps the **model policy** (`models.yml`) — on a terminal it runs the
   `configure-models.sh` wizard (Enter accepts the defaults; `--no-wizard` to
   skip prompts), then stamps each skill/agent with its tier's model + effort
   (see [Model tiering](#model-tiering-which-model-runs-each-phase)).
4. Symlinks each SDD skill and agent into every Claude home (`~/.claude`,
   `~/.claude_*`) — one link per item, your other skills are untouched.
5. Generates Codex (`~/.codex`, plus every `~/.codex_*` profile home — the
   `CODEX_HOME=~/.codex_gym codex` pattern) and Copilot (`~/.copilot`)
   adapters from the canonical skills, if those CLIs are installed
   (`--no-cli` to skip).
6. Runs `sdd-doctor.sh` to verify.

After install, `/sdd:onboard` researches every repo in `system-map.yml` and
writes its standing brief (`briefs/<repo>.md`) — setup prints a hint whenever
registered repos have no brief. Existing installs: add `onboard: implementation`,
`review: implementation`, and `go: reasoning` to your machine-local `models.yml`
roles (new installs get them from the example; `sdd-doctor.sh` lists every
unmapped role with the command that maps it).

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
| 2. Design approach | `/sdd:plan` | `plan.md` — stack experts consulted, codebase explored, then reviewed once by the opponent before tasking (`notes/plan-review.md`, STATUS `plan_review`) |
| 3. Break into tasks | `/sdd:tasks` | `tasks.md` — commit-sized tasks, each with files + acceptance check + refs; validated by `sdd-analyze.sh` |
| 4. Execute | `/sdd:implement` | Code changes in a `spec/NNN-slug` worktree, checkboxes ticked (`spec-task.sh` — tick + evidence atomically), gates run |
| 5. Drive the PR home | `/sdd:review` | CI watched via `spec-ci.sh`, red builds triaged into `T###c*` tasks, reviewer feedback into `T###r*`, re-gate rule applied, merge in contract order, worktree torn down |
| 6. Learn | `/sdd:retro` | `notes/retro.md` + generalizable lessons filed into `knowledge/` |

**In a hurry? `/sdd:go` — autopilot ("yolo mode").** Once a spec exists, one
command drives steps 2–4 end to end and opens the PR, without stopping for
human review of `plan.md` or `tasks.md` (each auto-acceptance is logged in the
STATUS Decisions log). What it *never* skips is the safety floor: the specify
interview (no spec → it runs `/sdd:specify` interactively first),
`[NEEDS CLARIFICATION]` markers (any unknown stops the chain instead of
guessing), the one-round plan review (an UNSOUND plan stops the chain),
`sdd-analyze.sh`, both adversarial gates at full strength (a gate
deadlock stops the chain — autopilot has no waiver authority), and the
`spec-pr.sh` gate check. The chain always ends at the open PR; `/sdd:review`
and the merge stay interactive. Umbrella specs autopilot too: implement
always runs locally there, and the chain ends once every declared repo's PR
is open.

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
subagents; on Codex the kit generates them as true subagents too
(`~/.codex/agents/sdd-opponent.toml` + `sdd-reality-check.toml`, built by
`build-adapters.sh` from the personas + models.yml); where no subagent is
available (Copilot today, or the TOMLs not installed) the adapter runs them
as distinct review passes. Each invocation requires a current floor and an atomic
round reservation. Rounds 1–3 are allowed per gate; round 4+ requires exact-gate,
exact-next-round authorization with an ordered UTC timestamp in STATUS Decisions.
A waiver permits one invocation and never softens a verdict. Check the entry
with `spec-gate.sh waiver <spec-dir> <gate> <round>` as soon as it is written:
it reports the exact clause that fails, reserves nothing and changes no state.

Two conventions keep the loop honest end-to-end:

- **Evidence lines.** A task checkbox is only ticked together with an
  `*Evidence:*` line (the acceptance command + its key output). Gates validate current
  proof and refresh stale checks; historical completion is preserved.
- **Clarification markers.** Unresolved decisions are written as
  `[NEEDS CLARIFICATION: <question>]`, never guessed; `sdd-analyze.sh` blocks
  tasking/implementation while any marker remains.

## Model tiering (which model runs each phase)

Not every phase deserves the same model. Design and adversarial judgment —
specify/plan/tasks, the opponent, the reality-check, the security review — get
the strongest reasoning models on high effort; rote implementation runs on a
mid-tier model that's faster and cheaper. The split follows what a mistake at
each tier can cost:

| Work | Who | Tier | Tools |
|---|---|---|---|
| **Read-only** — search, docs lookup, running a named command, log digests | `sdd-scout` | `recon` (cheap) | no Edit/Write, and a Bash guard (`scout-guard.sh`) that refuses git writes, kit state scripts, file mutation, installs and deploys |
| **Writing code** — one task at a time, smallest complete change | stack experts, `test-engineer` | `implementation` (mid) — `[hard]` tasks and retries escalate to `implement-hard` | full |
| **Judging it** — the two gates, the security pass | `opponent`, `reality-check`, `security-reviewer` | `reasoning` (strongest) | no Edit/Write — a reviewer never fixes what it grades |

The mapping is the **model policy**:

- **`models.yml`** (machine-local, gitignored — like the registry) defines
  **tiers** (a model + reasoning effort per CLI) and maps **roles** to tiers.
  Shipped defaults: `reasoning` = Claude `opus (xhigh)` / Codex `gpt-6.1-sol (xhigh)`
  / Copilot `claude-opus-4.8`; `implementation` = `sonnet (high)` / `gpt-6.1-terra (high)`
  / `claude-sonnet-4.5`; `recon` = `haiku (medium)` for the read-only scout.
  Provider model ids are retired over time — if a default no longer launches
  on your CLI, `model-policy.sh update <role> <model> --cli <cli>` swaps it. Roles: `specify` `plan` `tasks` `retro` `orchestrator`
  `opponent` `reality-check` `security-reviewer` `test-engineer`
  `implement-hard` → reasoning (test-engineer because tests are the AC binding
  every gate trusts; `implement-hard` is the escalation role — `[hard]`-tagged
  tasks, failed-acceptance retries, and gate follow-ups dispatch on it instead
  of repeating a failure at the tier that produced it; on Claude it is passed
  as the model's alias family, so a pinned `claude-opus-5-5` escalates as
  `opus`); `implement` `stack-expert` `onboard` `review` → implementation;
  `explore` (the `sdd-scout` agent) → recon. All
  of it is editable — add tiers, remap roles, or delete `models.yml` to run
  everything on the session model.
- **`scripts/configure-models.sh`** is the wizard (runs on first `setup.sh`;
  re-run anytime). `scripts/model-policy.sh show` prints the current mapping;
  `check` validates it.
- **One-off edits from the command line** — no wizard, no hand-editing:
  `scripts/model-policy.sh update plan claude-opus-5 xhigh` changes the model
  (+ effort) behind a role (it edits the tier the role points at and warns
  which sibling roles share it — add `--solo` to split the role onto its own
  cloned tier and leave the siblings untouched); `set tier <tier> <cli>
  model|effort <value>`, `set role <role> <tier>`, and `set dispatch <role>
  <cli>` (with matching `unset`s — `unset tier <tier>` with no field drops the
  whole tier, refused while a role still points at it) cover everything else
  in the file. Every edit is validated before
  it is saved — a bad model id or effort never lands — and then re-stamps the
  generated copies and CLI adapters automatically (`--no-apply` to skip).
  Running Claude sessions load agent models at startup, so agent-model edits
  apply from the next session.
- **How it's applied per CLI** — each the strongest way that CLI allows:
  - *Claude Code:* `scripts/apply-models.sh` generates copies of every skill and
    agent under `build/` with `model:` + `effort:` stamped into the frontmatter,
    and `sync.sh` points the home symlinks there. `/sdd:plan` runs on the
    reasoning tier even in a sonnet session; stack experts dispatched by the
    orchestrator run on the implementation tier.
  - *Codex CLI:* sessions pin models via one profile per tier
    (`~/.codex/sdd-<tier>.config.toml` → `codex --profile sdd-reasoning`);
    each adapter's preamble tells the agent to steer the session to its phase's
    tier via `/model` or a relaunch. The gates and `[hard]`-escalation ship as
    generated **subagents** (`~/.codex/agents/sdd-{opponent,reality-check,implement-hard}.toml`)
    the adapters delegate to by name — fresh-context review instead of
    persona passes. Their TOMLs carry the tier's model + effort; note current
    Codex (0.144.4) spawns them on the session model (see
    `knowledge/cli-subagent-delegation.md`), so the profile stays the model lever.
  - *Copilot CLI:* each generated `sdd-<phase>` agent (and the gate persona
    copies) gets `model:` pinned in its frontmatter; effort is session-level, so
    the preamble suggests `--effort` when the session is set lower. Copilot's
    custom-agent handoff is empirically proven (model pin included — same
    knowledge file), but the kit doesn't wire gate delegation through it yet;
    the adapters keep the persona-pass until that follow-up spec ships.

After editing `models.yml` by hand, re-run `scripts/setup.sh` (or
`apply-models.sh` + `sync.sh` + `build-adapters.sh`) — or skip the hand-edit
entirely and use `model-policy.sh update`/`set`, which does all of that for
you. `sdd-doctor.sh` flags a stale or missing build, and validates the policy
file.

Everything that writes code sends its read-only work down a tier: `/sdd:plan`,
`/sdd:onboard`, `/sdd:review` and `/sdd:implement` fan scouts out for
searches, docs lookups and log digests, and the stack experts do the same for
a sweep or a long log — one narrow question per scout, re-read first-hand
before it shapes a plan or an edit. The gates do not: an adversarial verdict
never rests on a recon-tier "nothing else calls this".

### Style guides

Rust and TypeScript code is written to Google's style guides. The kit ships a
digest of each under `templates/style-guides/` —
[`rust.md`](templates/style-guides/rust.md) (the
[Google Rust Style Guide](https://google.github.io/styleguide/rustguide.html))
and [`typescript.md`](templates/style-guides/typescript.md) (the
[Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html))
— short enough to read on every task, each ending with the lints that enforce
its rules so a project can hand them to a tool instead of a model's memory.

- Every Rust and TypeScript stack overlay names its guide, plus the one place
  its framework needs otherwise (Next.js and Expo Router default exports,
  LoopBack decorators, generated RTK Query code).
- Order of authority: the project's own lint/format config and constitution →
  the file being edited → the stack overlay → the guide. Untouched lines are
  never restyled; a style-only change is its own task.
- The digests carry a "read" date. When Google revises a guide, re-read the
  page and update the digest — the linked page stays the authority.

### Official skills first

Where a vendor ships its own agent skills, the kit uses them ahead of its own
overlays: they are maintained against the current API, which a model's memory
and a hand-written overlay are not. One table —
[`templates/official-skills.md`](templates/official-skills.md) — maps each
domain to the skill, who loads it, and the install command:

| Domain | Official source | Used by |
|---|---|---|
| Next.js | the version-matched docs bundled in `next` (`node_modules/next/dist/docs/`) + the workflow skills in [`vercel/next.js`](https://github.com/vercel/next.js/tree/canary/skills) — the old `vercel-labs/next-skills` repo is retired and points there | `/sdd:plan`, `nextjs-expert` |
| AWS | the `aws-core` plugin of the [Agent Toolkit for AWS](https://github.com/aws/agent-toolkit-for-aws) (skills + the AWS MCP server's documentation search) | `/sdd:plan`, the AWS/CDK/Rust-Lambda experts, the scaffolding skills, `security-reviewer` for IAM |
| Stripe | Stripe's own plugin ([`stripe/ai`](https://github.com/stripe/ai)): `stripe-best-practices`, `upgrade-stripe` | whichever expert writes the integration, `security-reviewer` |
| UI / UX | `ui-ux-pro-max` — the design system is generated once at plan time and persisted; implementers read the file, not the 700-line skill | `/sdd:plan`, the Next.js/React/Expo experts |
| Code review | Claude Code's built-in `code-review` (Codex: `codex review`) as the opponent's attack pass — findings are leads the gate must reproduce | `opponent` |
| Security review | Claude Code's built-in `security-review` as the security pass's first step (Codex has no counterpart; the checklist stands) | `security-reviewer` |
| Every change | ponytail v5 | every code-writing path |

Three rules keep this cheap. A skill is loaded only when the task touches its
domain — never because it is installed. Decisions are made once, at plan time,
and written into plan.md, so an implementer loads a skill for the API it is
about to call rather than to redesign. And a skill that is not installed is
not an error: the overlay stands on its own.

`scripts/companions.sh` reports, per CLI home, which of these are installed
and prints the exact install command for the rest (it only reads files — it
never installs). `sdd-doctor.sh` runs it: a home without ponytail v5 is a
warning, the stack-specific ones are information.

### Ponytail (companion — v5)

The kit's implementers already work to "the smallest change that satisfies
the task", and the opponent ends every review with a non-blocking **lean
pass** (unasked code, dead code, single-use abstractions, re-implemented
helpers — reported as `lean-*` minors, never a reason for another round).
The [ponytail](https://github.com/DietrichGebert/ponytail) plugin sharpens
both, and the kit uses it automatically when it is installed:

- Every code-writing path carries the rule — reuse before writing, nothing
  the task did not ask for, `shortcut:` comments for known limits — and loads
  `ponytail:ponytail` when it is listed: `/sdd:implement`, the orchestrator's
  briefs, `/sdd:review`'s post-PR fixes, the scaffolding skills, and every
  stack-expert persona plus `test-engineer` (their `## Working rules`), so it
  holds whichever way a task was dispatched. The task's bound tests and the
  plan's decisions outrank it.
- The opponent loads `ponytail:ponytail-review` for its lean pass.
- `/sdd:retro` collects the `shortcut:` comments a spec left into a debt
  ledger (`ponytail:ponytail-debt` gives the repo-wide one).

Install it per CLI (`/plugin marketplace add DietrichGebert/ponytail`, then
`/plugin install ponytail@ponytail` in Claude Code; Codex and Copilot have
the same two `plugin` commands). `sdd-doctor.sh` warns about any Claude or
Codex home without v5 and prints the command for that home. Nothing breaks
without it — the rules above are written into the skills. One thing to know: ponytail injects itself into every subagent and
asks for closing "skipped / not checked" lines; the gate personas keep those
inside the report, because `spec-gate.sh round --complete` rejects anything
after the round marker. The scout, the gates and the orchestrator never write
code, so the injection only costs them tokens — scope it to the implementers
by setting `PONYTAIL_SUBAGENT_MATCHER` (ponytail's own switch) in the `env`
block of `~/.claude/settings.json`:
`"PONYTAIL_SUBAGENT_MATCHER": "-expert$|^test-engineer$|^general-purpose$"`.

### Cross-CLI dispatch (different providers per phase)

Model tiering picks the model *within* whichever CLI you're typing in. The
optional **`dispatch:`** map in `models.yml` goes one step further: it names
the CLI that should *run* a phase, so one machine can plan on Claude Code
(opus), write tasks on Codex, and implement on Copilot:

```yaml
dispatch:
  tasks: codex
  implement: copilot
```

When a phase skill sees its role mapped to a different CLI, it offers
**`scripts/spec-dispatch.sh <role> <spec-dir>`** — the one dispatcher. It runs
the target CLI headlessly (`codex exec` inside its workspace-write sandbox /
`copilot -p --agent sdd-<phase>` / `claude -p`) with the phase's model from
the same policy, in the right working root (for implement it pre-cuts the
spec worktree and runs the guard first), captures the final message into the
spec's `notes/`, flips `active_tool:` in STATUS.md, and **verifies the
artifacts on return** with the kit's deterministic checkers (`sdd-analyze.sh`
for tasks, plus `spec-evidence.sh` for implement). Artifacts are the
interface — a foreign model's output passes the same gates as anyone else's.

Boundaries, on purpose: `specify` is never dispatchable (it's an interview),
`review` is never dispatchable (merge decisions are interactive), and umbrella
specs dispatch their hub phases (plan/tasks/retro, rooted at the hub) plus
one-repo implement slices (`--repo <name>`) — never the cross-repo
orchestrated `--all`, which stays interactive. A dispatched run is
non-interactive by contract — the prompt forbids asking questions; unknowns become
`[NEEDS CLARIFICATION]` markers and the run stops cleanly. **Single-provider
setups: omit `dispatch:` entirely — nothing changes.** Each mapped CLI must be
installed and authenticated; `sdd-doctor.sh` and `model-policy.sh check` flag
mappings this machine can't honor.

### Graph and loop (control flow lives in scripts)

The two decisions a long run gets wrong when a model makes them from memory
are scripted:

- **What may start now** — `spec-graph.sh next <spec-dir>` derives the
  dependency graph from `tasks.md` (stage order, written order, `[P]`,
  `Depends on:`, open follow-ups) and prints the one batch whose dependencies
  are all `[x]` and whose *Files:* cannot collide. The orchestrator dispatches
  exactly those rows; `sdd-analyze.sh` fails a dangling or circular
  dependency before implementation starts.
- **When to stop** — `spec-loop.sh <spec-dir>` runs implement as a loop of
  fresh sessions, one task each, instead of one session that carries every
  finished task in its context. State is on disk (`tasks.md`, STATUS, the
  spec branch), so a killed loop resumes by being run again. It stops at the
  first Ship task (the PR stays yours), after two sessions that tick nothing
  and open nothing (exit 1), at `--max-iterations` (exit 8), or when the
  dispatcher refuses or parks the run. It needs a CLI to dispatch to: the
  `dispatch:` map or `--to <cli>` (the CLI you are on works too). Gate rounds
  stay capped by `spec-gate.sh`; umbrella specs stay interactive.

### When a provider hits its usage limit

Usage-limit recovery applies only to **dispatched** runs. It is off by default:
when `models.yml` has no `on_limit:` block, the dispatcher reports the
classified limit and exits without scheduling, retrying, or switching
providers. Add an explicit policy only when those automatic actions are wanted:

```yaml
on_limit:
  short: park
  long: delegate
  fallback: [claude, copilot]
  backoff_minutes: 60
```

The parser accepts exactly the `short`, `long`, `fallback`, and
`backoff_minutes` keys. `short` and `long` accept `park`, `delegate`, or
`fail`; a present block defaults to `short: park`, `long: delegate`, an empty
`fallback`, and `backoff_minutes: 60`. A short limit is automatically parked
for resume. For a long limit with `delegate`, the dispatcher tries ready fallback
CLIs in `fallback` order (never the provider that just limited); if none is
ready, it parks instead. Remove `on_limit:` to stop future automatic actions.

For manual recovery, use the copy-pasteable park or `--to` command printed by
the limit report. Inspect existing parked work with
`scripts/spec-resume.sh list`, and cancel a unit you no longer want resumed
with `scripts/spec-resume.sh cancel <unit-id>`. Existing units remain until
they resume successfully or are cancelled. Interactive sessions cannot recover
automatically after their CLI turn ends; follow the manual recipe in
[`knowledge/usage-limit-handling.md`](knowledge/usage-limit-handling.md).

## Multi-repo features (umbrella specs)

A team's feature rarely lives in one repo — web + mobile + big-screen clients,
several backend services, a separate infra repo. The kit handles that with
three pieces:

- **`system-map.yml`** (team-shared in your fork — unlike the machine-local
  registry; see [Multi-machine](#multi-machine)): what each repo *is* — role (`app|service|infra|design|library|external`),
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
| `setup.sh` | install / repair everything on this machine (`--no-cli`, `--no-wizard`, `--relink`) |
| `configure-models.sh` | wizard for the model policy (`models.yml`) — which model + effort runs each SDD role, per CLI |
| `model-policy.sh` | query/validate/edit the policy: `get <role> <cli> <field>`, `dispatch [<role>]`, `show`, `check`; edits via `update <role> <model> [<effort>]`, `set`/`unset` `tier`\|`role`\|`dispatch` — validated first, then auto re-stamps copies + adapters |
| `apply-models.sh` | stamp the policy into generated skill/agent copies under `build/` (Claude homes link there) |
| `project-detect.sh` | cwd → registered project root (worktree-aware) |
| `system-map.sh <cmd>` | query/validate the team topology: `list`, `show`, `path`, `deps`, `consumers`, `contracts`, `check` |
| `brief-status.sh <cmd>` | deterministic repo-brief freshness: `list` (TSV per repo), `check` (exit 1 on missing/stale), `repo <name>`; `--threshold N` (default 20), `--fetch` to opt into network |
| `new-spec.sh "<title>"` | scaffold `.specify/specs/NNN-slug/` from templates; `--multi --repos a,b,c` scaffolds an umbrella spec in the hub `specs/` |
| `spec-worktree.sh <spec-dir>` | cut/reuse branch `spec/NNN-slug` + sibling worktree from the project's base branch; `--remove [--delete-branch]` tears it down post-merge; umbrella: `--repo <name>` / `--all-repos` |
| `spec-status.sh` | machine-side state mutations: `get`/`set`/`show` on STATUS.md frontmatter (enum-validated, bumps `updated:`); `--file spec.md` targets other artifacts |
| `spec-task.sh` | tick tasks deterministically: `list`, `show`, `start`, `done T### --evidence "…"` (tick + evidence one atomic edit — refuses evidence-less ticks), `undo` |
| `spec-graph.sh <cmd> <spec-dir>` | the task dependency graph, computed instead of recalled: `check` (dangling/circular `Depends on:`, duplicate ids), `next` (the batch that is safe to start now — stage order, `[P]` siblings, follow-ups first, file collisions kept apart, a gate alone), `waves` (every remaining batch) |
| `spec-loop.sh <spec-dir>` | the outer loop for implement: one fresh headless session per task in `spec-graph.sh` order via `spec-dispatch.sh`; stops at the first Ship task, on two sessions without progress, at `--max-iterations` (default 30), or when the dispatcher refuses/parks; `--to <cli>`, `--dry-run` |
| `spec-run.sh <spec-dir> T### -- <cmd>` | run an acceptance check FOR REAL: executes the command, captures stdout+exit+hash into `notes/evidence.md`, and ticks the box from that run only on exit 0 — evidence becomes a record, not a typed claim (`--key` to pick the quoted line, `--no-tick` to capture only) |
| `sdd-analyze.sh <spec-dir>` | deterministic spec↔plan↔tasks lint: AC coverage (implementation tasks only — gate refs don't count), ref integrity, acceptance checks, evidence on `[x]` tasks, gates present, no unresolved `[NEEDS CLARIFICATION]` markers; umbrella: `[repo:]` tag integrity + `[EXTERNAL:]` mirroring |
| `spec-ac-coverage.sh <spec-dir>` | AC coverage at the CODE layer (gate-time): greps the repo's test files for each `AC-###`, fails any AC no test names — the deterministic floor beneath the reality-check gate (`--root` per repo, `--tests` for extra globs) |
| `spec-evidence.sh <spec-dir>` | evidence integrity (gate-time): every `[x]` box's `*Evidence:*` must trace to a real `notes/evidence.md` capture block or an on-disk artifact — catches fabricated pointers, missing screenshots, and manual/post-deploy ACs with no owner + check-back date |
| `spec-pr.sh <spec-dir>` | push + open PR; **refuses unless both gates passed** (`--force` only with `--draft`); writes `pr:` + `phase: review` back into STATUS; umbrella: `--repo <name>`, once per repo |
| `spec-ci.sh <cmd>` | the CI watcher: `check`/`watch`/`logs` — PR checks + review + mergeability via `gh`, aggregate written to STATUS `ci:`, distinct exit codes (0 green / 10 pending / 20 red / 30 changes-requested / 40 conflicts); umbrella-aware |
| `spec-dispatch.sh <role> <spec-dir>` | run one phase on ANOTHER CLI/provider headlessly (models.yml `dispatch:` map or `--to`): right working root + model, output captured to `notes/`, artifacts verified on return; `--task T###`/`--all` for implement, umbrella implement takes `--repo <name>` (one slice per run), `--dry-run` prints the command |
| `sdd-status.sh` | dashboard of every spec in every project + hub umbrella specs (worktree-aware; `--open`, `--phase`, `--project`, `--tsv` for machines) |
| `companions.sh` | which official skills (ponytail v5, `aws-core`, Stripe, Next.js, `ui-ux-pro-max`) each Claude/Codex home has, with the install command for the missing ones; `--tsv`; exit 1 when ponytail v5 is absent |
| `scout-guard.sh` | the read-only scout's Bash backstop — a `PreToolUse` hook (wired in `agents/sdd-scout.md`) that refuses git writes, kit state scripts, file mutation, installs and deploys; a search for those words still runs |
| `sync.sh` | verify/repair the per-item symlinks into Claude homes (`--check`); prunes stale links; `--remove` uninstalls them |
| `build-adapters.sh` | regenerate Codex/Copilot adapters from the skills |
| `sdd-doctor.sh` | validate the kit, home wiring, adapters, system map, and any project's `.specify/` layout (`--all`, `--hub-only`) |

(`lib.sh` is the shared parsing library the others source — fence-bound
frontmatter reads/writes, YAML lists in inline or block form, registry
entries with `~` expansion. All scripts honor `NO_COLOR` / non-TTY output.)

Deterministic checks run as scripts; model judgment is reserved for design and
adversarial review. That split is a design principle (constitution §10).

### Testing the kit itself

The deterministic layer is only trustworthy if it's tested. `tests/` holds the
kit's own suite — same zero-dependency floor as the scripts (bash 3.2 + BSD
tools + git):

```bash
tests/run.sh              # every tests/test-*.sh suite (slow: ~30+ min for all of them)
tests/run.sh task         # only files whose name contains "task"
bash tests/shellcheck.sh  # ShellCheck over the enumerated scripts/*.sh and tests/*.sh, no rc files, SHELLCHECK_OPTS unset
```

Both commands are reuse-checked, so each reads only what the input identity
hashes: the suites and scripts git enumerates, never an ignored local file or
configuration outside the repository. They therefore need a Git worktree root,
such as a clone of the kit: they list what they run through the same git
enumeration the identity uses, and outside a worktree they stop with
"cannot enumerate the kit" rather than guess.

CI runs both on Linux and macOS, plus a run with `bash` shimmed to `/bin/bash`
3.2 so the compatibility claim is enforced, not assumed. Touching a script?
Add the failure mode you just fixed as a test.

## What's in the box

```
sdd-kit/
├── constitution.md           # Cross-project engineering principles — edit to taste
├── registry.example.yml      # → registry.yml (machine-local, gitignored)
├── models.example.yml        # → models.yml (machine-local): model policy — which
│                             # model+effort runs each role; build/ holds the
│                             # stamped copies (generated, gitignored)
├── system-map.yml            # Repo topology + contracts (from system-map.example.yml;
│                             # gitignored here — commit it in your team's fork)
├── specs/                    # Umbrella specs — one dir per multi-repo feature
├── briefs/                   # Standing per-repo context — seeded by /sdd:onboard,
│                             # written by plan, refreshed by retro (Source: sha tracked)
├── skills/                   # CANONICAL skills: sdd-specify/plan/tasks/implement/
│                             # review/retro/onboard/go (autopilot)
├── agents/                   # Gates (opponent, reality-check), security-reviewer,
│                             # test-engineer, sdd-orchestrator, sdd-scout (read-only
│                             # recon), and 12 stack experts
│                             # (rust, javascript, python, aws, react, nextjs,
│                             # loopback4, expo-rn, bun-monorepo, aws-cdk-lambda-ts,
│                             # rust-aws-lambda, firebase-rtk-codegen)
├── templates/                # spec/plan/tasks/STATUS/ADR/brief/retro templates,
│                             # stack-routing.md (THE routing table), umbrella-guide.md,
│                             # official-skills.md (vendor skills the kit prefers)
│   ├── stack-overlays/       # per-stack conventions — one per expert above,
│   │                         # plus monorepo + troposphere (overlay-only)
│   ├── style-guides/         # rust.md, typescript.md — digests of the Google
│   │                         # style guides the Rust/TS overlays point at
│   └── examples/             # the golden example (001-api-key-expiry): a complete
│                             # spec→plan→tasks set the phase skills calibrate
│                             # against — CI keeps it passing sdd-analyze
├── knowledge/                # Cross-project lessons — grows via /sdd:retro
├── scripts/                  # everything in the table above
└── tests/                    # the kit's own test suite (tests/run.sh)
```

## Customizing

- **Add a stack**: write `templates/stack-overlays/<tag>.md` (+ optionally
  `agents/<tag>-expert.md`), add the tag to your project's `stack.yml`, and add
  one row to `templates/stack-routing.md` — the single routing table every
  skill and the orchestrator read. Re-run `setup.sh`. A new language gets a
  digest under `templates/style-guides/` that the overlay names in a
  `## Style guide` section; a new expert copies the `## Working rules` block
  from an existing one (the test suite checks both).
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
`knowledge/`, overlays, constitution, umbrella `specs/`, and skill improvements
travel through git; the registry and the model policy never do. For a team,
that split is the whole model: fork the kit as the team's hub repo — topology,
umbrella specs, and lessons are shared; each member's `registry.yml` maps the
repo names to wherever they're checked out locally.

`system-map.yml` and `briefs/*.md` describe YOUR repos, so this public
template gitignores them (nobody publishes their topology by accident). In
your team's fork, delete those two entries from `.gitignore` and commit both —
that is what makes the map and the briefs team-shared.

## Credits

The workflow follows the spec-kit school of spec-driven development
([github/spec-kit](https://github.com/github/spec-kit)), extended with adversarial
pre-ship gates, cross-tool STATUS handoff, worktree isolation, and a retro loop.

### Versioned verification workflow

New specs opt in with `verification_contract: 1`. The
[verification contract](templates/verification-contract.md) defines typed tests,
shared FM/INV rows, command configuration, structured returns and report grammar.
Legacy captures remain readable; current gates still require proof freshness.
Required `gate_checks` cover the full suite and mandatory static checks. Optional
`checkpoints` add commands for exact task-stage names; completed-task coverage is
checked even when a stage has no commands. Integrity verifies stored artifacts;
freshness verifies that their inputs still describe the current source.

From the existing spec worktree, use the local scripts when developing the kit:

```bash
# Returns and reports are spec bookkeeping, never worktree files: a stray
# return.txt beside the code changes the input manifest, and acceptance then
# rejects the fresh capture as stale.
VERIFY="$SPEC/notes/verification"; mkdir -p "$VERIFY/returns" "$VERIFY/reports"
bash scripts/spec-run.sh "$SPEC" "$TASK" --from-task --no-tick --summary
# Save the authentic Verification-Return block as "$VERIFY/returns/$TASK.txt".
bash scripts/spec-gate.sh accept "$SPEC" "$TASK" "$VERIFY/returns/$TASK.txt"
bash scripts/spec-gate.sh checkpoint "$SPEC" "$STAGE"
bash scripts/spec-gate.sh floor "$SPEC"
bash scripts/spec-gate.sh round "$SPEC" opponent
# Delegate the independent review with the granted identities, then:
bash scripts/spec-gate.sh round "$SPEC" opponent --complete "$VERIFY/reports/opponent.md"
# Check what the NEXT round needs, and check a round-4+ authorization the
# moment you write it: same grammar and the same diagnostics as the
# reservation, reserving nothing and changing no state. A waiver validated only
# by attempting a reservation costs a floor to discover it never parsed.
bash scripts/spec-gate.sh waiver "$SPEC" opponent 2
bash scripts/spec-gate.sh tally "$SPEC"
```

Five public entrypoints expose `--help`: spec-run.sh, spec-task.sh,
spec-evidence.sh, spec-ac-coverage.sh and spec-gate.sh. Full logs and SHA-256
metadata remain under spec-local notes/captures; --summary bounds returned
success output to 2048 bytes and failure output to 8192 bytes/20 diagnostic
lines without changing the actual exit code.

Finish batch edits before capture/acceptance. Workers never tick; the invoker
rejects incomplete or forged returns without changing tasks. Checkpoint failure
stops the next stage even when only retained-coverage checks apply. A fresh floor
executes analyzer, coverage, evidence integrity and every required gate_checks
command. Only exact local checks explicitly opted into reuse may reuse complete
unchanged inputs; unknown/external/time-dependent checks execute again. Stale
proof refreshes verification while preserving historical completion.

The opponent retains every established blocker, stable Class, all known sites
and searched/unexamined scope. Root cause remains a separate process label.
Reality-check includes every AC and carries only validated unchanged prior PASS
rows; an executed suite does not decide semantic coverage. A reservation refusal
stops dispatch. Use --reconcile for interrupted reports; never reset history.
Models, separate gates and security-review authority retain their existing roles.
Measure actual usage or record unknown; compare cost alongside 14-day defects.
