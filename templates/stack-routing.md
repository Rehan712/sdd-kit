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

## Planning consultation (stack tag → expert to consult)

For `/sdd:plan`: consult the expert(s) matching the project's stack tags —
`<tag>-expert` when it exists (e.g. `nextjs` → `nextjs-expert`). Tags with an
overlay but no expert (`monorepo`, `troposphere`) are covered by the overlay
plus the nearest general expert (`javascript-expert` / `python-expert` +
`aws-expert`).
