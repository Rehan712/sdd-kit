# Skills, style and routing

## Style guides

Rust and TypeScript code is written to Google's style guides. The kit ships a
digest of each under `templates/style-guides/` —
[`rust.md`](https://github.com/Rehan712/sdd-kit/blob/main/templates/style-guides/rust.md) (the
[Google Rust Style Guide](https://google.github.io/styleguide/rustguide.html))
and [`typescript.md`](https://github.com/Rehan712/sdd-kit/blob/main/templates/style-guides/typescript.md) (the
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

## Official skills first

Where a vendor ships its own agent skills, the kit uses them ahead of its own
overlays: they are maintained against the current API, which a model's memory
and a hand-written overlay are not. One table —
[`templates/official-skills.md`](https://github.com/Rehan712/sdd-kit/blob/main/templates/official-skills.md) — maps each
domain to the skill, who loads it, and the install command:

| Domain | Official source | Used by |
|---|---|---|
| Next.js | the version-matched docs bundled in `next` (`node_modules/next/dist/docs/`) + the workflow skills in [`vercel/next.js`](https://github.com/vercel/next.js/tree/canary/skills) — the old `vercel-labs/next-skills` repo is retired and points there | `/sdd:plan`, `nextjs-expert` |
| AWS | the `aws-core` plugin of the [Agent Toolkit for AWS](https://github.com/aws/agent-toolkit-for-aws) (skills + the AWS MCP server's documentation search) | `/sdd:plan`, the AWS/CDK/Rust-Lambda experts, the scaffolding skill, `security-reviewer` for IAM |
| Stripe | Stripe's own plugin ([`stripe/ai`](https://github.com/stripe/ai)): `stripe-best-practices`, `upgrade-stripe` | whichever expert writes the integration, `security-reviewer` |
| UI / UX | `ui-ux-pro-max` — the design system is generated once at plan time and persisted; implementers read the file, not the 700-line skill | `/sdd:plan`, the Next.js/React/Expo experts |
| Code review | Claude Code's built-in `code-review` (Codex: `codex review`), once, in the opponent's first round, over the range `<base>...<spec branch>` — findings are leads the gate must reproduce | `opponent` |
| Security review | Claude Code's built-in `security-review`, once per spec: the branch-wide pass before the first opponent round. Per-task passes run the checklist (Codex has no counterpart; the checklist stands) | `security-reviewer` |
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

## Project skills and agents (per-project routing)

A project often has its own way of planning, writing and reviewing its code —
and in a multi-platform repo, one per platform. Declare them in
`<project>/.specify/routing.md` (start from
[`templates/routing-template.md`](https://github.com/Rehan712/sdd-kit/blob/main/templates/routing-template.md)), one row per
file signal:

| Signal | Plan | Implement | Review |
|---|---|---|---|
| `apps/android/**`, `*.kt` | | `android-implementer` | `android-reviewer` |
| `apps/ios/**`, `*.swift` | | `ios-implementer` | `ios-reviewer` |
| `apps/tv/**` | | `bigscreen-implementer` | `bigscreen-reviewer` |
| `*` | `acme-architecture` | | |

A name is a project agent (`.claude/agents/<name>.md`), a project skill
(`.claude/skills/<name>/SKILL.md`), a kit agent or skill, or `plugin:skill`.
The kit asks this table before its own:

- **Plan** — `/sdd:plan` loads the rows whose signal covers what the spec
  touches, next to the official skills.
- **Implement** — per task, by its `*Files:*`. An agent *is* the writer; a
  skill is read by the writer the kit routes to. The brief (`spec-brief.sh`)
  lists them by file path, so it works the same on Claude Code, Codex and
  Copilot, and nobody has to remember to name them.
- **Review** — each reviewer whose signal matches the branch diff runs once
  per spec, read-only, before the opponent gate; its blocking findings become
  `T###p<n>` follow-up tasks.

They add to a phase; they never replace one. On the project's conventions a
project skill outranks the official skills and overlays, but the artifact
formats, the deterministic checks and the two gates stay the kit's — that is
what keeps a spec verifiable whoever wrote the code.

`scripts/project-routing.sh` is the one reader: `check <project>` validates
the table (every name must resolve — a name nobody can load is an error, not
a silent skip), `match <project> <phase> …` answers a dispatcher.
`sdd-doctor.sh` runs the check for every registered project. Umbrella specs
use each repo's own table for its slice.

## Ponytail (companion — v5)

The kit's implementers already work to "the smallest change that satisfies
the task", and the opponent ends every review with a non-blocking **lean
pass** (unasked code, dead code, single-use abstractions, re-implemented
helpers — reported as `lean-*` minors, never a reason for another round).
The [ponytail](https://github.com/DietrichGebert/ponytail) plugin sharpens
both, and the kit uses it automatically when it is installed:

- Every code-writing path carries the rule — reuse before writing, nothing
  the task did not ask for, `shortcut:` comments for known limits:
  `/sdd:implement`, `/sdd:review`'s post-PR fixes, the scaffolding skill, and
  every stack-expert persona plus `test-engineer` (their `## Working rules`),
  so it holds whichever way a task was dispatched. The plugin injects its
  rules into the session and into every subagent; a writer loads the
  `ponytail:ponytail` skill only when they are not already in its context. The task's bound tests and the
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
