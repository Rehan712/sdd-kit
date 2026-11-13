# Stack routing — the ONE table

The single source of truth for which agent handles which work. `/sdd:plan`,
`/sdd:implement`, and the `sdd-orchestrator` all read THIS file — when you add
a stack (overlay + expert), extend this table only. Agent names are the
kebab-case `name:` in each agent's frontmatter (= its filename), used verbatim
as the Agent tool's `subagent_type`.

A project may bring its own skills and agents: its `.specify/routing.md` is
asked **first** — §Project routing, below.

## Implementation routing (file/tech signal → agent)

| Signal | Agent |
|---|---|
| `app/`, `pages/`, `components/`, `next.config.*` (Next.js) | `nextjs-expert` |
| LoopBack 4 controllers/repositories/models | `loopback4-expert` |
| `infrastructure/`, `cdk/`, `lib/*-stack.ts`, `cdk.json` | `aws-cdk-lambda-ts-expert` |
| `app/_layout.tsx`, `app.config.*`, RN screens, `eas.json` | `expo-rn-expert` |
| `turbo.json`, root `package.json`, Bun workspace plumbing (`bun.lockb`) | `bun-monorepo-expert` |
| pnpm/yarn workspace plumbing (`pnpm-workspace.yaml`, non-Bun monorepo) | `javascript-expert` + the `monorepo` overlay |
| Firebase Auth wiring, RTK Query codegen config, `generated.ts` consumers | `firebase-rtk-codegen-expert` |
| `*.rs`, `Cargo.toml`, `crates/*` | `rust-aws-lambda-expert` if the project's stacks include `rust-aws-lambda`, else `rust-expert` |
| `*.ts`/`*.js`, `package.json`, Node/Bun/Deno services | `javascript-expert` |
| `*.py`, `pyproject.toml` | `python-expert` |
| Troposphere CloudFormation (`*.py` generating templates) | `python-expert` + the `troposphere` overlay (consult `aws-expert` for resource semantics) |
| IaC (`*.tf`), IAM policies, cloud resource config (non-CDK) | `aws-expert` |
| React components, hooks, UI routes (non-Next.js) | `react-expert` |
| Stage = Tests, OR subject starts with "Test"/"Add test"/"Cover" | `test-engineer` (pulls fixtures from the matching stack expert) |
| Stage = Docs, OR subject starts with "Document"/"Update README" | the stack expert whose code the docs describe; acceptance = the documented command/example actually runs |

**Tie-breakers:** when two rows could both apply, prefer the expert named by the
project's stack tags (`.specify/stack.yml`); among those, the row with the more
specific signal (an exact filename beats a glob beats a language) wins.

## Gates and cross-cuts (never self-run — always via the Agent tool)

| Task | Agent |
|---|---|
| Opponent gate (under `## Reality Check`, `Agent:` → `opponent.agent.md`) | `opponent` |
| Reality-check gate (under `## Reality Check`, `Agent:` → a reality-check persona) | `reality-check` for the hub default; project-local personas run as `general-purpose` with the persona text leading the dossier |
| Security pass — triggers listed in `agents/security-reviewer.md` ("When you're invoked" is THE list) | `security-reviewer` (read-only; CRITICAL/HIGH block, MEDIUM/LOW log). Per task: `Scope: task`, the checklist. Once before the first opponent round: `Scope: branch`, which adds the built-in `security-review` |
| Stripe integration code (a `stripe` dependency, Checkout, webhooks, Connect, billing) — no overlay of its own | the stack expert whose files the task names, with the `stripe-best-practices` skill loaded; webhook and key handling trip the security pass |
| A new screen, page or component, or a visual/interaction decision | the UI stack expert (`nextjs-expert` / `react-expert` / `expo-rn-expert`) with `ui-ux-pro-max` and the persisted `design-system/` |

## Read-only recon (never the session model's job when a scout exists)

| Work | Agent |
|---|---|
| Codebase search, docs lookup, running a named test/lint/build command, digesting a log (`notes/ci.md`, a long suite output) | `sdd-scout` — no Edit/Write tools, a Bash guard (`scripts/scout-guard.sh`) that refuses the common writes (a backstop, not a sandbox), pinned to the `explore` role's tier; one narrow question per scout, parallel in one message. Its findings are leads: re-read first-hand before they enter a plan or a fix. |

Who sends scouts: `/sdd:plan`, `/sdd:onboard`, `/sdd:review`, `/sdd:implement`
(single-task recon and failed-acceptance log digests), the orchestrator (log
digests) and the stack experts themselves for a sweep, a docs lookup or a long
log. Not the gates: an adversarial verdict does not rest on a recon-tier
"nothing else calls this". A lookup one command answers is not worth a spawn.

The three tiers, by what the work can cost you: **read-only → `sdd-scout`
(recon tier)**, **writing code → stack experts (implementation tier)**,
**judging it → the gates and `security-reviewer` (reasoning tier, no
Edit/Write tools)**. `[hard]` tasks and retries escalate the writer to
`implement-hard`.

## What every implementer carries

Four rules sit in every stack-expert persona and in `test-engineer`
(`## Working rules`), so they hold on any dispatch path — single-task,
orchestrated, the loop, a post-PR fix:

1. **Ponytail** — the smallest *complete* change; the rules the plugin
   already injected, else the `ponytail:ponytail` skill when the session
   lists it — never both.
2. **Style** — project lint/format config and the file being edited win;
   untouched lines are never restyled. The guide the stack overlay names
   under `~/.sdd/templates/style-guides/` (`rust.md`, `typescript.md` —
   digests of the Google Rust and TypeScript style guides) is read for a new
   file, or when the project has no linter or formatter config.
3. **Recon on the cheap tier** — sweeps, docs lookups and long logs go to
   `sdd-scout`.
4. **Official skills first** — the vendor skill the overlay's
   `## Official skills` section names (and `stripe-best-practices` for any
   Stripe code) outranks overlay and memory on that vendor's API. The one
   table: `~/.sdd/templates/official-skills.md`.

A project-local agent has no kit persona: put the four in its brief.

What a task needs beyond the rules — the task block, the REQ/AC text, the
plan's anchors and seams — is copied, not retyped:
`~/.sdd/scripts/spec-brief.sh <spec-dir> T###` writes it to
`notes/verification/briefs/T###.md`, and the dispatch names that path.

## Project routing — a project's own skills and agents

A project that has its own planners, implementers or reviewers — one pair per
platform, say: Android, iOS, big screen — declares them per file signal in
`<project>/.specify/routing.md` (start from
`~/.sdd/templates/routing-template.md`). Its rows come before this file's.

**Never read that table yourself.** Ask `~/.sdd/scripts/project-routing.sh`:
it matches the signals against paths and resolves every name to a file. Each
output line is `<agent|skill>  <name>  <file to read, or - for a plugin
skill>  <signal>`, in table order. No table prints nothing — most projects.
A non-zero exit is a broken table: stop and report it, never dispatch around
it — that is how a project's conventions get skipped without a word.

| When | Ask | Do |
|---|---|---|
| `/sdd:plan`, reading its inputs | `project-routing.sh match <project> plan` | Every Plan row with its signal. Load the skills, and consult the agents, whose signal covers what the spec touches — alongside the official skills. What they settle goes into plan.md as a decision. |
| Routing a task | `project-routing.sh match "$WT" implement --task <spec-dir> T###` | An `agent` line: that agent is the writer in place of the kit expert (the first one, when several match — a task spanning two platforms should have been two tasks). `skill` lines: the writer stays the expert this file routes to, `general-purpose` when no row above fits, and reads those files first. `spec-brief.sh` already lists the same lines, by path, in the brief — do not retype them. |
| Before opponent round 1 | `project-routing.sh match "$WT" review --diff <base>` | One read-only review per line — §Project review. |

**Who wins.** On the project's own conventions, what a project skill or agent
says outranks the official skills, the stack overlay and the style guide. The
task, the plan and both constitutions outrank it. The artifact formats, the
deterministic checks and the two gates are not its to change, and ponytail
still bounds the change. A project agent has no kit persona: its dispatch
carries the four rules of §What every implementer carries.

**Models.** The stamped model of a kit agent is machine-wide, so a project's
choices arrive as Agent-tool params:

- Once per session: `~/.sdd/scripts/model-policy.sh --project "$WT" overrides`.
  Each line is a role this project remaps — `role  tier  alias  effort`
  (`<project>/.specify/models.yml`). Pass that alias and effort as `model` and
  `effort` on every spawn of the role's agent: `stack-expert` is any
  `*-expert`, `explore` is `sdd-scout`, the rest go by name. `-` → omit that
  param. Prints nothing → nothing to pass. A phase role (`plan`, `tasks`,
  `implement`, …) cannot change the session already running it; it applies
  when the phase is dispatched.
- `general-purpose` hosting a project skill has no stamp at all: pass
  `model-policy.sh --project "$WT" get stack-expert claude alias` and
  `… claude effort`, or it runs on the session's own, costlier model.
- A project agent runs on the `model:` its own frontmatter pins.
- `[hard]` tasks, retries and gate follow-ups still escalate to
  `implement-hard` — looked up with `--project "$WT"` too.

### Project review (the Review column)

Once per spec, after the branch-wide security pass and before the first
opponent round — the gate should attack code that already meets the project's
own bar. For each line `match "$WT" review --diff <base>` prints:

- `agent` → dispatch it (`subagent_type` = its name).
- `skill` → `general-purpose`, told to read that file first and to edit
  nothing, with `model`/`effort` from
  `model-policy.sh --project "$WT" get security-reviewer claude alias` and
  `… claude effort`.

The prompt: the worktree path, the diff command (`git -C "$WT" diff
<base>...HEAD`), the spec dir, the signal that matched, and "review only the
files under your signal; return each finding as BLOCKING or NOTE with
file:line and the project rule it breaks; edit nothing". BLOCKING findings
become `T###p<n>` follow-ups (`###` = the opponent gate task) under Reality
Check — normal implementation tasks, routed like any other; when they pass,
the opponent runs. NOTEs go in the hand-off. Later rounds re-run a reviewer
only when a follow-up touched its signal. No Agent tool: read the reviewer's
file and do the pass yourself, before the opponent.

## Planning consultation (stack tag → expert to consult)

For `/sdd:plan`: consult the expert(s) matching the project's stack tags —
`<tag>-expert` when it exists (e.g. `nextjs` → `nextjs-expert`). Tags with an
overlay but no expert (`monorepo`, `troposphere`) are covered by the overlay
plus the nearest general expert (`javascript-expert` / `python-expert` +
`aws-expert`).
