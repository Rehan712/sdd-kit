# Official skills — the ONE table

Vendor-maintained skills are current where a model's memory and this kit's
overlays are not. When one is listed in your session, it is the first source
for its vendor's API and behaviour. `/sdd:plan` reads this file; the stack
overlays repeat the row for their stack, so an implementer never opens it.
`scripts/companions.sh` reports which are installed and prints the install
command for the rest.

## Rules

1. **Load on match, not on sight.** Load a skill only when the task touches
   its domain, and only the one that matches — every loaded skill costs
   context for the rest of the session. A skill that is not listed in the
   session is not an error: the overlay stands on its own.
2. **Who wins.** The project's constitution and config → the spec and the
   plan's decisions → the official skill, on its vendor's API and current
   behaviour → the stack overlay and style guide, on project conventions →
   memory. A skill never widens a task: ponytail bounds the change.
3. **Decide at plan time.** `/sdd:plan` loads the skills its stacks map to
   and writes what they settle into plan.md, so implementers transcribe a
   decision instead of re-deriving it. An implementer loads a skill for the
   API it is about to call, not to redesign.
4. **Names are as the session lists them.** A plugin skill is
   `<plugin>:<skill>` on Claude Code (`aws-core:aws-cdk`); a standalone skill
   is its bare name. Codex and Copilot list the same skills under their own
   prefixes.

## The table

| Domain (signal) | Load | Who loads it |
|---|---|---|
| **Every code change** | `ponytail:ponytail` (v5) — smallest complete change; loaded only when the plugin has not already injected its rules into the session or subagent. `ponytail:ponytail-review` for the opponent's lean pass, `ponytail:ponytail-debt` in `/sdd:retro`. | `/sdd:implement`, every stack expert, `test-engineer`, `/sdd:review` fixes, the scaffolding skill |
| **Next.js** (`nextjs` stack) | The version-matched docs first: `node_modules/next/dist/docs/` (Next.js 16.3+, also indexed by the `AGENTS.md` that `next dev` writes) or `.next-docs/` on older projects. Workflow skills, when the task is that workflow: `next-cache-components-adoption`, `next-cache-components-optimizer`, `next-partial-prefetching-adoption`, `next-partial-prefetching-optimizer`, `next-bundle-optimizer`, `next-dev-loop`. | `/sdd:plan`, `nextjs-expert` |
| **AWS** (`aws`, `aws-cdk-lambda-ts`, `rust-aws-lambda`, `troposphere`) | The `aws-core` skill for the service the task touches — `aws-cdk`, `aws-cloudformation`, `aws-serverless`, `aws-iam`, `aws-database`, `aws-storage`, `aws-messaging-and-streaming`, `aws-networking`, `aws-observability`, `aws-secrets-manager`, `aws-sdk-js-v3-usage`, `aws-sdk-python-usage`, `aws-deployment`. When the AWS MCP server is connected, its documentation search answers "what does the service do today" before memory does. | `/sdd:plan`, `aws-expert`, `aws-cdk-lambda-ts-expert`, `rust-aws-lambda-expert`, `python-expert` on troposphere |
| **AWS security review** (IAM, security groups, KMS in the diff) | `aws-core:aws-iam`, `aws-core:aws-security` | `security-reviewer` |
| **Stripe** (a `stripe` dependency, Checkout, webhooks, Connect, billing) | `stripe-best-practices`; `upgrade-stripe` for an API-version or SDK upgrade | `/sdd:plan`, the stack expert writing the integration, `security-reviewer` on keys and webhooks |
| **UI / UX** (a new screen, page or component; a visual or interaction decision) | `ui-ux-pro-max`: at plan time generate the design system once and persist it (`design-system/<project>/MASTER.md` + `pages/`); implementers read the persisted file and query the skill only for a decision it does not cover. Its pre-delivery checklist closes every UI task. | `/sdd:plan`, `nextjs-expert`, `react-expert`, `expo-rn-expert` |
| **Code review** (the opponent gate's attack) | Claude Code: the built-in `code-review` skill, once, in round 1 — args `high <base>...<spec branch>` (without a target it compares against the branch's upstream, or `main`), every command run in the worktree. Never `max` or `ultra`, which need the user, and never `--fix` or `--comment`. Codex: the built-in `codex review --base <base>`. Findings are leads: only what the gate reproduces enters its report. | `opponent` |
| **Security review** | Claude Code: the built-in `security-review` skill, once per spec — the `Scope: branch` pass before the first opponent round (it reviews the checked-out branch against origin's default branch, so per task it would re-review the same code). Per-task passes are the persona's checklist. Codex ships no built-in security review — the checklist is the pass. | `security-reviewer` |

Retired: `vercel-labs/next-skills`. Its skills moved into the Next.js repo
(`vercel/next.js/skills`); `next-best-practices` and `next-upgrade` are no
longer skills — that knowledge ships as the bundled docs above, and an
upgrade is `npx @next/codemod@latest upgrade`.

## Install

| Skill set | Claude Code | Codex |
|---|---|---|
| ponytail | `claude plugin marketplace add DietrichGebert/ponytail` · `claude plugin install ponytail@ponytail` | `codex plugin marketplace add DietrichGebert/ponytail` · `codex plugin add ponytail@ponytail` |
| AWS (`aws-core`) | `claude plugin install aws-core@claude-plugins-official` | `codex plugin marketplace add aws/agent-toolkit-for-aws` · `codex plugin add aws-core@agent-toolkit-for-aws` |
| Stripe | `claude plugin install stripe@claude-plugins-official` | `codex plugin add stripe@openai-curated` |
| Next.js workflow skills | `npx skills add vercel/next.js -g -a claude-code -s "*" -y` | `npx skills add vercel/next.js -g -a codex -s "*" -y` |
| Next.js docs, before 16.3 | in the project: `npx @next/codemod@canary agents-md` (a plan decision — it writes `.next-docs/` and `AGENTS.md`) | same |
| ui-ux-pro-max | `claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill` · `claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill` | `npm install -g uipro-cli` · `uipro init --ai codex` |
| `code-review`, `security-review` | built into Claude Code | `codex review` is built in |

`-g` matters: without it `npx skills add` installs into the current project.
It also clones the whole Next.js repository to read six small skills — on a
machine short of disk, sparse-clone `skills/` and pass that path instead:
`git clone --depth 1 --filter=blob:none --sparse --branch canary https://github.com/vercel/next.js nextjs-src && git -C nextjs-src sparse-checkout set skills`,
then `npx skills add ./nextjs-src/skills -g -a claude-code codex -s "*" -y`.
On a machine with several CLI homes, run `scripts/companions.sh`: it prints
each command addressed to the home it is for.

The AWS plugin also configures the AWS MCP server (needs `uv`; AWS
credentials only for API calls, not for documentation search). Sources:
[aws/agent-toolkit-for-aws](https://github.com/aws/agent-toolkit-for-aws),
[vercel/next.js/skills](https://github.com/vercel/next.js/tree/canary/skills),
[stripe/ai](https://github.com/stripe/ai),
[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail),
[nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill).
Read 2026-11-12.
