---
name: sdd:plan
description: Spec-driven development phase 2. Read an existing spec.md and produce plan.md alongside it, pulling in the relevant stack overlays from ~/.sdd/templates/stack-overlays/ and consulting the matching tech-stack subagent(s). Use when the user types /sdd:plan, says "plan this", "how would we build this", or asks for an implementation plan for a spec that already exists.
---

# /sdd:plan — Produce an implementation plan

Phase 2 of the SDD workflow. Reads an accepted `spec.md`, designs the implementation, and writes `plan.md` next to it.

## Step-by-step

### 1. Locate the active spec

If the user named a spec (slug or NNN), find `<project>/.specify/specs/NNN-*/spec.md` — and if the project has no match, check the hub's umbrella specs at `~/.sdd/specs/NNN-*/spec.md`.

If not, find the most recently modified spec directory in the resolved project's `.specify/specs/`:

```
ls -t <project>/.specify/specs/ | head -1
```

Confirm with the user before proceeding if there's ambiguity.

Resolve the project root via `~/.sdd/scripts/project-detect.sh` if needed.

**Umbrella specs** (spec.md with `repos:` frontmatter, living in `~/.sdd/specs/`) span several repos; wherever a step below says "the project", read it as "each declared repo". The umbrella-specific behavior is called out inline.

### 2. Read the inputs

- `STATUS.md` — the spec's living memory: phase, prior decisions, open questions, who last touched it. Read it first so you don't relitigate settled calls.
- `spec.md` — the requirements you're planning against.
- `~/.sdd/constitution.md` — cross-project principles.
- `<project>/.specify/constitution.md` (if present) — project overrides.
- `<project>/.specify/stack.yml` if present, otherwise the `stacks` field for this project in `~/.sdd/registry.yml`. *Umbrella:* the stack set is the UNION of every declared repo's stacks (resolve each repo's path via `~/.sdd/scripts/system-map.sh path <name>`, then its stack.yml / registry entry).
- For each stack tag, `~/.sdd/templates/stack-overlays/<tag>.md` — load all relevant overlays.
- Cross-project lessons in `~/.sdd/knowledge/*.md` — skim for relevance (for umbrella specs, `cross-repo-contracts.md` is required reading, not optional).
- `~/.sdd/briefs/<repo>.md` for every repo in scope — single-repo specs included (the project repo's brief, when it exists), not just umbrella repos. **Check freshness first**: `~/.sdd/scripts/brief-status.sh repo <repo>` — on `stale` (or `unknown`), warn the user and suggest `/sdd:onboard --refresh <repo>` before planning against it. Never auto-refresh a brief from this skill; a brief is a starting map either way, and the grounding rules still require paths to be re-verified in-session.
- *Umbrella:* `~/.sdd/system-map.yml` (deps + contracts between the declared repos — `system-map.sh deps/consumers/contracts` answers ordering questions).

If `spec.md` carries `[NEEDS CLARIFICATION: …]` markers, resolve them with the user **before** designing — a plan built on an open question is a guess with extra steps. Remove each marker as it's answered (and log the answer in STATUS's Decisions log).

### 3. Pick stack expert(s)

For each stack tag, identify the matching global subagent (canonical files at `~/.sdd/agents/`, linked into every Claude home by `setup.sh`):

| Stack tag | Subagent |
|---|---|
| `rust` | `rust-expert` |
| `javascript` | `javascript-expert` |
| `python` | `python-expert` |
| `aws` | `aws-expert` |
| `react` | `react-expert` |
| `nextjs` | `nextjs-expert` |
| `loopback4` | `loopback4-expert` |
| `aws-cdk-lambda-ts` | `aws-cdk-lambda-ts-expert` |
| `rust-aws-lambda` | `rust-aws-lambda-expert` |
| `expo-rn` | `expo-rn-expert` |
| `bun-monorepo` | `bun-monorepo-expert` |
| `firebase-rtk-codegen` | `firebase-rtk-codegen-expert` |
| `troposphere` | `python-expert` + `aws-expert` (overlay carries the troposphere specifics) |
| `monorepo` | *(overlay only — no dedicated expert)* |

When you adopt a new stack, add an overlay in `~/.sdd/templates/stack-overlays/` and (optionally) a matching expert in `~/.sdd/agents/`, then extend this table.

If the work spans multiple stacks (typical), use the Agent tool to consult each relevant expert **in parallel** for their specific concerns. Each expert returns the considerations, file paths, and risks specific to its stack.

### 4. Explore the codebase

Use the Agent tool with `subagent_type: Explore` to find existing code that:

- Implements similar patterns (avoid reinventing).
- Will need to be modified by this change.
- Defines contracts the plan must respect.

If the hub has a model policy (`~/.sdd/models.yml`), run Explore agents on its
`explore` tier: `~/.sdd/scripts/model-policy.sh get explore claude model` — pass
the result as the Agent tool's `model` parameter when it's an alias
(opus/sonnet/haiku); if it's a full model id or the command prints nothing, omit
the parameter. (Named SDD agents don't need this — their stamped frontmatter
already carries the policy.)

Don't pre-decide — let exploration inform the design.

*Umbrella:* fan out **one Explore agent per declared repo, in parallel** (one message, multiple Agent calls — each gets its repo's path from `system-map.sh path <name>` and the spec's ACs for that repo). Ask each for a structured brief: what the repo owns, entry points (build/test/deploy), the contracts it provides/consumes, the files this feature will touch, conventions that bite. Then **persist what exploration verified**: for each repo with no `~/.sdd/briefs/<name>.md`, write one from `~/.sdd/templates/brief-template.md` — including its `**Updated:**` line and the `**Source:** <branch> @ <full-sha>` line (the explored checkout's branch + `git rev-parse HEAD` — provenance only; brief-status.sh counts drift against the repo's BASE branch, not this line's branch); if a brief exists but exploration contradicted it, fix the brief and update both lines. That's how the next umbrella spec starts warm instead of re-exploring every repo.

### 5. Draft the plan

Fill `plan.md` from the template. Mandatory sections (template already provides them):

1. **Approach** — one paragraph; reference REQ-### from spec.
2. **Architecture** — components, file paths, what changes where. *Umbrella:* organize this section **per repo** (one subsection per declared repo, each with its file paths), so `/sdd:tasks` can tag tasks mechanically.
3. **Data model** — schemas, migrations.
4. **API / contracts** — new/changed endpoints, event payloads. *Umbrella:* this section is the coordination spine — name each contract from `system-map.yml` that changes, its source repo, and the consuming repos; contract changes are the FIRST tasks and land before any consumer code (see `knowledge/cross-repo-contracts.md`). For `[EXTERNAL: …]` dependencies, state the agreed contract version to stub against.
5. **Dependencies** — packages, AWS resources, IAM.
6. **Stack overlay notes** — per-tag callouts pulled from overlays + expert agents.
7. **Risks** — ranked likelihood × impact, each with a mitigation. *Umbrella:* half-shipped states are a standing risk — say what users see when repo A is merged and repo B isn't, and how that's kept safe (flag, additive API, dark launch).
8. **Rollout** — flags, deploy order, observability, success-metric wiring (how each MET-### gets measured). *Umbrella:* deploy order across repos is mandatory here — providers before consumers, infra first; name the order repo by repo.
9. **Out of scope** — capture what came up but won't ship here.
10. **References** — ADRs, code paths, links.

Be specific: name the files, the IAM actions, the metric names. Vague plans produce vague code.

### 6. Reconcile with the spec

If the planning process revealed that the spec is wrong or ambiguous, **stop and edit the spec first**. Tell the user what you changed and why. Then resume the plan.

### 7. Update STATUS.md

- `phase: plan`, `active_tool: claude`, bump `updated:`.
- **Decisions log** — append the load-bearing architectural calls (library/pattern picks, the chosen approach) with one-line rationale. This is what stops a later session or a different tool from re-deciding them.
- **Open questions / blockers** — refresh: close any the plan resolved, add any the plan surfaced.
- **Where things stand** / **Next action** → plan done, `/sdd:tasks`.

### 8. Hand off

Tell the user:

- The path to `plan.md`.
- A 3-bullet summary: approach, biggest risk, deploy strategy.
- Suggested next command: `/sdd:tasks`.

## Grounding rules — non-negotiable

1. **Never write a path, ID, or verdict from memory.** Every file path, spec/task/AC/REQ id, and status value you use must come from a file you read or a command you ran *in this session*. If you can't point at its source, resolve it before using it.
2. **Quote before you act.** Before acting on an artifact, re-read the relevant lines and satisfy exactly what they say — not your recollection of them.
3. **Unknown → ask or mark, never invent.** If the user or the artifacts don't answer a question, ask — or write `[NEEDS CLARIFICATION: <question>]` into the artifact. A silent guess is the failure mode this workflow exists to prevent.
4. **Paste outputs, don't paraphrase.** Report any script/command result as the actual output lines, trimmed — never a summary like "it worked".
5. **On contradiction, stop.** If artifacts disagree with each other or with what the user said, don't silently pick one: surface it, reconcile (spec wins over plan, plan over tasks), and say what you changed.

## Rules

- **No code in this phase.** Plan only.
- **Always consult the relevant stack expert(s).** Don't bypass even if you "already know" — the agents encode lessons that aren't in the overlay.
- **Umbrella plans are contract-first.** A consumer repo's plan section may not depend on a contract change that no provider-repo section ships. If planning reveals the spec scoped the wrong repos (one more repo must change, or one declared repo doesn't), stop and fix the spec's `repos:` + Repos-in-scope table first — same rule as any spec error.
- **Reference REQ-### and AC-### from the spec.** Every architectural choice should trace back to a requirement.
- **Honor the constitution.** If you're about to plan something that violates it, surface that explicitly to the user.
- **Don't expand scope.** If a tempting refactor surfaces, list it in "Out of scope" — never silently add it.

## Done when

- `plan.md` exists, with all template sections completed (or marked "n/a").
- The user has been told the path, the summary, and the next step.
- Any spec edits made during planning are saved.
