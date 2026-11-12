# Stack routing — the ONE table

The single source of truth for which agent handles which work. `/sdd:plan`,
`/sdd:implement`, and the `sdd-orchestrator` all read THIS file — when you add
a stack (overlay + expert), extend this table only. Agent names are the
kebab-case `name:` in each agent's frontmatter (= its filename), used verbatim
as the Agent tool's `subagent_type`.

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
| Security pass — triggers listed in `agents/security-reviewer.md` ("When you're invoked" is THE list) | `security-reviewer` (read-only; CRITICAL/HIGH block, MEDIUM/LOW log) |
| Stripe integration code (a `stripe` dependency, Checkout, webhooks, Connect, billing) — no overlay of its own | the stack expert whose files the task names, with the `stripe-best-practices` skill loaded; webhook and key handling trip the security pass |
| A new screen, page or component, or a visual/interaction decision | the UI stack expert (`nextjs-expert` / `react-expert` / `expo-rn-expert`) with `ui-ux-pro-max` and the persisted `design-system/` |

## Read-only recon (never the session model's job when a scout exists)

| Work | Agent |
|---|---|
| Codebase search, docs lookup, running a named test/lint/build command, digesting a log (`notes/ci.md`, a long suite output) | `sdd-scout` — no Edit/Write tools, a Bash guard (`scripts/scout-guard.sh`) that refuses writes, pinned to the `explore` role's tier; one narrow question per scout, parallel in one message. Its findings are leads: re-read first-hand before they enter a plan or a fix. |

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

1. **Ponytail** — the smallest *complete* change; the `ponytail:ponytail`
   skill when the session lists it.
2. **Style** — the guide the stack overlay names under
   `~/.sdd/templates/style-guides/` (`rust.md`, `typescript.md` — digests of
   the Google Rust and TypeScript style guides). Project lint/format config
   and the file being edited win; untouched lines are never restyled.
3. **Recon on the cheap tier** — sweeps, docs lookups and long logs go to
   `sdd-scout`.
4. **Official skills first** — the vendor skill the overlay's
   `## Official skills` section names (and `stripe-best-practices` for any
   Stripe code) outranks overlay and memory on that vendor's API. The one
   table: `~/.sdd/templates/official-skills.md`.

A project-local agent has no kit persona: put the four in its brief.

## Planning consultation (stack tag → expert to consult)

For `/sdd:plan`: consult the expert(s) matching the project's stack tags —
`<tag>-expert` when it exists (e.g. `nextjs` → `nextjs-expert`). Tags with an
overlay but no expert (`monorepo`, `troposphere`) are covered by the overlay
plus the nearest general expert (`javascript-expert` / `python-expert` +
`aws-expert`).
